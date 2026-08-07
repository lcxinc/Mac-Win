import Foundation
import Testing
@testable import MacWinCore

@Suite("Host GUI session service")
struct HostGUISessionServiceTests {
    @Test("Session reports preserve locked and unlocked interaction state")
    func reportsInteractionState() {
        let generatedAt = Date(timeIntervalSince1970: 123)
        let locked = HostGUISessionService(stateProvider: { .locked }).report(generatedAt: generatedAt)
        let unlocked = HostGUISessionService(stateProvider: { .unlocked }).report(generatedAt: generatedAt)
        let unavailable = HostGUISessionService(stateProvider: { .unavailable }).report(generatedAt: generatedAt)

        #expect(locked.generatedAt == generatedAt)
        #expect(locked.state == .locked)
        #expect(!locked.isInteractive)
        #expect(unlocked.isInteractive)
        #expect(!unavailable.isInteractive)
    }

    @Test("Native UI probe refuses to launch while the host session is locked")
    func lockedSessionStopsProbeBeforeWineLaunch() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinLockedNativeUIProbe-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let probeDirectory = root.appendingPathComponent("probe", isDirectory: true)
        try FileManager.default.createDirectory(at: probeDirectory, withIntermediateDirectories: true)
        try Data("probe".utf8).write(to: probeDirectory.appendingPathComponent("native-ui-probe-x86_64.exe"))
        let paths = MacWinPaths(root: root.appendingPathComponent("app-support", isDirectory: true))
        let service = DiagnosticsService(
            paths: paths,
            hostGUISessionService: HostGUISessionService(stateProvider: { .locked })
        )
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-test",
            arch: .win64,
            winePath: root.appendingPathComponent("missing-wine").path,
            wineserverPath: root.appendingPathComponent("missing-wineserver").path,
            runtimePath: root.appendingPathComponent("runtime").path,
            defaultEnv: [:]
        )
        let bottle = BottleManifest(
            id: "probe",
            name: "Probe",
            windowsVersion: "win11",
            arch: .win64,
            engineId: engine.id
        )

        #expect(throws: MacWinError.guiSessionLocked) {
            try service.runNativeUIProbe(
                mode: .message,
                engine: engine,
                bottle: bottle,
                probeService: NativeUIProbeService(probeDirectory: probeDirectory, paths: paths)
            )
        }
        #expect(!FileManager.default.fileExists(atPath: paths.logsDirectory.path))
    }
}
