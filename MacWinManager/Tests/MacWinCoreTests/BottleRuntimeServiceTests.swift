import Foundation
import Testing
@testable import MacWinCore

@Suite("Bottle runtime service")
struct BottleRuntimeServiceTests {
    @Test("Bottle runtime report and orphan cleanup stay inside one prefix")
    func orphanCleanupTargetsOnlyIdleBottle() {
        let root = temporaryRoot()
        let paths = MacWinPaths(root: root)
        let bottle = BottleManifest(
            id: "first",
            name: "First",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        let prefix = paths.bottleDirectory(id: bottle.id).path
        let otherPrefix = paths.bottleDirectory(id: "second").path
        let processList = """
          701 1 Ss C:\\windows\\system32\\services.exe
          702 1 Ss C:\\windows\\system32\\winedevice.exe
          703 44 Ss C:\\Program Files\\Example\\Example.exe
          704 1 Ss C:\\windows\\system32\\rpcss.exe
        """
        let workingDirectories: [Int32: String] = [
            701: "\(prefix)/drive_c/windows/system32",
            702: "\(prefix)/drive_c/windows/system32",
            703: "\(prefix)/drive_c/Program Files/Example",
            704: "\(otherPrefix)/drive_c/windows/system32"
        ]
        let audit = RuntimeProcessAuditService(
            processListProvider: { processList },
            processWorkingDirectoryProvider: { workingDirectories[$0] }
        )
        let stopped = RuntimeTerminatorRecorder()
        let service = BottleRuntimeService(
            paths: paths,
            auditService: audit,
            terminator: RuntimeProcessTerminator { pid in
                stopped.append(pid)
                return true
            },
            bootstrapBottle: { _, _ in bottle }
        )

        let report = service.report(for: bottle)
        #expect(report.entries.map(\.processIdentifier).sorted() == [701, 702, 703])
        #expect(report.activeApplicationEntries.map(\.processIdentifier) == [703])

        let result = service.cleanupOrphans(in: bottle)
        #expect(stopped.values.isEmpty)
        #expect(result.requestedProcessCount == 0)

        let idleProcessList = """
          701 1 Ss C:\\windows\\system32\\services.exe
          702 1 Ss C:\\windows\\system32\\winedevice.exe
        """
        let idleAudit = RuntimeProcessAuditService(
            processListProvider: { idleProcessList },
            processWorkingDirectoryProvider: { workingDirectories[$0] }
        )
        let idleService = BottleRuntimeService(
            paths: paths,
            auditService: idleAudit,
            terminator: RuntimeProcessTerminator { pid in
                stopped.append(pid)
                return true
            },
            bootstrapBottle: { _, _ in bottle }
        )
        let idleResult = idleService.cleanupOrphans(in: bottle)
        #expect(stopped.values == [701, 702])
        #expect(idleResult.stoppedProcessIdentifiers == [701, 702])
    }

    @Test("Stop all terminates target applications and requests wineserver shutdown")
    func stopAllStopsOnlyBottleProcesses() throws {
        let root = temporaryRoot()
        let paths = MacWinPaths(root: root)
        let bottle = BottleManifest(id: "first", name: "First", windowsVersion: "win11", arch: .win64, engineId: "engine")
        let prefix = paths.bottleDirectory(id: bottle.id).path
        let audit = RuntimeProcessAuditService(
            processListProvider: {
                "801 44 Ss C:\\Program Files\\Example\\Example.exe\n802 1 Ss C:\\windows\\system32\\services.exe\n"
            },
            processWorkingDirectoryProvider: { pid in
                pid == 801 ? "\(prefix)/drive_c/Program Files/Example" : "\(prefix)/drive_c/windows/system32"
            }
        )
        let stopped = RuntimeTerminatorRecorder()
        let runner = WineRunner(
            paths: paths,
            processEnvironmentProvider: { [:] },
            hostNetworkEnvironmentProvider: { [:] },
            uninterruptibleRuntimeProcessProvider: { [] }
        )
        let service = BottleRuntimeService(
            paths: paths,
            auditService: audit,
            terminator: RuntimeProcessTerminator { pid in
                stopped.append(pid)
                return true
            },
            runner: runner
        )
        let engine = EngineManifest(
            id: "engine",
            name: "Test",
            wineVersion: "test",
            arch: .win64,
            winePath: "/bin/echo",
            wineserverPath: "/bin/echo",
            runtimePath: root.path,
            defaultEnv: [:]
        )

        let result = try service.stopAll(in: bottle, engine: engine)
        #expect(stopped.values == [801, 802])
        #expect(result.requestedProcessCount == 2)
        #expect(result.wineServerExitCode == 0)
    }

    @Test("Restart bootstraps only after the Bottle has stopped cleanly")
    func restartCallsBootstrapAfterStop() throws {
        let root = temporaryRoot()
        let paths = MacWinPaths(root: root)
        let bottle = BottleManifest(id: "first", name: "First", windowsVersion: "win11", arch: .win64, engineId: "engine")
        let bootstrapRecorder = RuntimeBootstrapRecorder()
        let audit = RuntimeProcessAuditService(processListProvider: { "" })
        let engine = EngineManifest(
            id: "engine",
            name: "Test",
            wineVersion: "test",
            arch: .win64,
            winePath: "/bin/echo",
            wineserverPath: "/bin/echo",
            runtimePath: root.path,
            defaultEnv: [:]
        )
        let service = BottleRuntimeService(
            paths: paths,
            auditService: audit,
            bootstrapBottle: { incoming, incomingEngine in
                #expect(incoming.id == bottle.id)
                #expect(incomingEngine.id == engine.id)
                bootstrapRecorder.append()
                return incoming
            }
        )

        let result = try service.restart(bottle: bottle, engine: engine)
        #expect(bootstrapRecorder.count == 1)
        #expect(result.restarted)
        #expect(result.succeeded)
    }

    private func temporaryRoot() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinBottleRuntime-(UUID().uuidString)", isDirectory: true)
    }
}

private final class RuntimeTerminatorRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [Int32] = []

    var values: [Int32] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func append(_ value: Int32) {
        lock.lock()
        storage.append(value)
        lock.unlock()
    }
}

private final class RuntimeBootstrapRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storage = 0

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func append() {
        lock.lock()
        storage += 1
        lock.unlock()
    }
}
