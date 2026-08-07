import Foundation
import Testing
@testable import MacWinCore

@Suite("Mac native UI probe service")
struct NativeUIProbeServiceTests {
    @Test("Probe modes expose stable Wine arguments")
    func probeModesExposeArguments() {
        #expect(NativeUIProbeMode.message.argument == "--message")
        #expect(NativeUIProbeMode.modernOpenMulti.argument == "--modern-open-multi")
        #expect(NativeUIProbeMode.legacyFallback.argument == "--legacy-fallback")
        #expect(NativeUIProbeMode.taskFallback.argument == "--task-fallback")
        #expect(NativeUIProbeMode.modernFolder.isModern)
        #expect(NativeUIProbeMode.taskFallback.isModern)
        #expect(!NativeUIProbeMode.filteredSave.isModern)
        #expect(!NativeUIProbeMode.legacyFallback.isModern)
    }

    @Test("Probe artifacts discover both x86_64 and i686 binaries")
    func probeArtifactsDiscoverArchitectures() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinNativeUIProbe-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("x64".utf8).write(to: directory.appendingPathComponent("native-ui-probe-x86_64.exe"))
        try Data("i686".utf8).write(to: directory.appendingPathComponent("native-ui-probe-i686.exe"))

        let service = NativeUIProbeService(probeDirectory: directory)
        let report = service.artifactReport()

        #expect(report.isReady)
        #expect(report.supportsWoW64)
        #expect(service.command(mode: .task, architecture: .x86_64) == [
            directory.appendingPathComponent("native-ui-probe-x86_64.exe").path,
            "--task"
        ])
        #expect(service.command(mode: .modernFolder, architecture: .i386) == [
            directory.appendingPathComponent("native-ui-probe-i686.exe").path,
            "--modern-folder"
        ])
    }

    @Test("Bottle native UI probe history round-trips")
    func historyRoundTrips() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinNativeUIProbeHistory-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = NativeUIProbeHistoryService(paths: paths)
        let startedAt = Date(timeIntervalSince1970: 1_000)
        let record = NativeUIProbeRunReport(
            mode: .modernOpen,
            architecture: .x86_64,
            executablePath: "/tmp/native-ui-probe-x86_64.exe",
            bottleId: "high-performance-win11",
            bottleName: "High Performance Windows 11",
            engineId: "wine-game",
            nativeUIPreset: .automatic,
            status: .passed,
            exitCode: 0,
            logPath: "/tmp/native-ui.log",
            output: "modern-dialog-show-hr=0x00000000",
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(2)
        )

        _ = try service.save(record)
        let report = service.report()

        #expect(report.totalRunCount == 1)
        #expect(report.latestRunAt == record.endedAt)
        #expect(report.records.first == record)
    }

    @Test("Capability reports include native UI artifacts and bottle history")
    func capabilityReportIncludesNativeUIState() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinNativeUICapability-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let probeDirectory = root.appendingPathComponent("probe", isDirectory: true)
        try FileManager.default.createDirectory(at: probeDirectory, withIntermediateDirectories: true)
        try Data("probe".utf8).write(to: probeDirectory.appendingPathComponent("native-ui-probe-x86_64.exe"))
        let service = CapabilityReportService(
            paths: paths,
            testAssetService: TestAssetService(root: root.appendingPathComponent("assets")),
            nativeUIProbeService: NativeUIProbeService(probeDirectory: probeDirectory, paths: paths),
            nativeUIProbeHistoryService: NativeUIProbeHistoryService(paths: paths)
        )

        let report = service.makeReport(engines: [], bottles: [], recipes: [])

        #expect(report.nativeUIProbeArtifacts?.isReady == true)
        #expect(report.nativeUIProbeArtifacts?.supportsWoW64 == false)
        #expect(report.nativeUIProbeHistory?.totalRunCount == 0)
    }
}
