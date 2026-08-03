import Foundation
import Testing
@testable import MacWinCore

@Suite("Diagnostics parser")
struct DiagnosticsServiceTests {
    @Test("Probe output maps known PASS lines")
    func parsesPassLines() {
        let items = DiagnosticsService.parseProbeOutput("""
        probe=vulkan
        PASS vulkan
        probe=iphlpapi_adapters
        PASS iphlpapi_adapters
        PASS tls_winhttp_win32
        PASS iphlpapi_adapters_win32
        probe=game_shader
        PASS game_shader
        probe=text_rendering
        PASS text_rendering
        probe=window_input
        PASS window_input
        """)

        #expect(items.first { $0.id == "vulkan" }?.passed == true)
        #expect(items.first { $0.id == "iphlpapi_adapters" }?.passed == true)
        #expect(items.first { $0.id == "tls_winhttp_win32" }?.passed == true)
        #expect(items.first { $0.id == "iphlpapi_adapters_win32" }?.passed == true)
        #expect(items.first { $0.id == "game_shader" }?.passed == true)
        #expect(items.first { $0.id == "text_rendering" }?.passed == true)
        #expect(items.first { $0.id == "window_input" }?.passed == true)
        #expect(items.first { $0.id == "d3d12_device" }?.passed == false)
        #expect(items.first { $0.id == "vulkan" }?.category == .graphics)
        #expect(items.first { $0.id == "tls_winhttp" }?.category == .network)
        #expect(items.first { $0.id == "xaudio2" }?.category == .audio)
        #expect(items.first { $0.id == "game_shader" }?.category == .game)
        #expect(items.first { $0.id == "text_rendering" }?.category == .core)
        #expect(items.first { $0.id == "window_input" }?.category == .windowing)
        #expect(items.first { $0.id == "d3d12_device" }?.status == .notObserved)
    }

    @Test("Probe output maps FAIL and SKIP states")
    func parsesFailAndSkipStates() {
        let items = DiagnosticsService.parseProbeOutput("""
        FAIL d3d11
        FAIL xaudio2
        SKIP win32_probes missing WoW64 engine files or bin32 probes
        """)

        #expect(items.first { $0.id == "d3d11" }?.status == .failed)
        #expect(items.first { $0.id == "d3d11" }?.detail == "FAIL")
        #expect(items.first { $0.id == "xaudio2" }?.status == .failed)
        #expect(items.first { $0.id == "tls_winhttp_win32" }?.status == .skipped)
        #expect(items.first { $0.id == "iphlpapi_adapters_win32" }?.status == .skipped)
        #expect(items.first { $0.id == "tls_winhttp_win32" }?.detail == "SKIP")
        #expect(items.first { $0.id == "tls_winhttp_win32" }?.passed == false)
    }

    @Test("Probe suite execution writes structured diagnostics log")
    func probeSuiteExecutionWritesStructuredDiagnosticsLog() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinDiagnosticsRunTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()
        let script = root.appendingPathComponent("run-suite.sh")
        try Data("""
        #!/usr/bin/env bash
        test -d "$WINEPREFIX/drive_c/ProgramData" || exit 31
        echo "PASS console"
        echo "PASS vulkan"
        """.utf8).write(to: script)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)

        let report = try DiagnosticsService(paths: paths).runProbeSuite(
            engine: testEngine(root: root),
            bottle: testBottle(),
            probeSuitePath: script.path,
            timeoutSeconds: 20
        )

        #expect(report.exitCode == 0)
        #expect(report.timedOut == false)
        #expect(report.durationSeconds >= 0)
        #expect(report.items.first { $0.id == "console" }?.status == .passed)
        #expect(report.items.first { $0.id == "vulkan" }?.status == .passed)
        #expect(FileManager.default.fileExists(
            atPath: paths.bottleDirectory(id: testBottle().id)
                .appendingPathComponent("drive_c/ProgramData", isDirectory: true)
                .path
        ))
        let log = try String(contentsOf: report.logURL, encoding: .utf8)
        #expect(log.contains("----- MacWin diagnostics -----"))
        #expect(log.contains("probeSuite=\(script.path)"))
        #expect(log.contains("env.WINEPREFIX="))
        #expect(log.contains("PASS console"))
        #expect(log.contains("----- MacWin diagnostics result -----"))
    }

    @Test("Probe suite execution times out and records timeout")
    func probeSuiteExecutionTimesOutAndRecordsTimeout() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinDiagnosticsTimeoutTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()
        let script = root.appendingPathComponent("run-suite.sh")
        try Data("""
        #!/usr/bin/env bash
        while true; do
          read -t 1 _ || true
        done
        """.utf8).write(to: script)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)

        let report = try DiagnosticsService(paths: paths).runProbeSuite(
            engine: testEngine(root: root),
            bottle: testBottle(),
            probeSuitePath: script.path,
            timeoutSeconds: 0.2
        )

        #expect(report.exitCode == 124)
        #expect(report.timedOut == true)
        #expect(report.items.first { $0.id == "console" }?.status == .notObserved)
        #expect(report.items.first { $0.id == "vulkan" }?.status == .notObserved)
        let log = try String(contentsOf: report.logURL, encoding: .utf8)
        #expect(log.contains("timedOut=true"))
        #expect(log.contains("exitCode=124"))
        #expect(!log.contains("PASS vulkan"))
    }

    @Test("Single probe execution uses runbook command and records asset id")
    func singleProbeExecutionUsesRunbookCommandAndRecordsAssetId() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinSingleProbeRunTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = MacWinPaths(root: root.appendingPathComponent("app-support", isDirectory: true))
        try paths.ensureBaseDirectories()

        let assets = root.appendingPathComponent("test-assets", isDirectory: true)
        try FileManager.default.createDirectory(at: assets.appendingPathComponent("bin", isDirectory: true), withIntermediateDirectories: true)
        let runner = assets.appendingPathComponent("run-one.sh")
        try Data("""
        #!/usr/bin/env bash
        printf 'runner=%s\\n' "$0"
        printf 'probe=%s\\n' "$1"
        echo "PASS text_rendering"
        """.utf8).write(to: runner)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: runner.path)
        try Data("probe".utf8).write(to: assets.appendingPathComponent("bin/70_text_rendering_probe.exe"))

        let report = try DiagnosticsService(paths: paths).runProbe(
            assetId: "text-rendering",
            engine: testEngine(root: root),
            bottle: testBottle(),
            testAssetService: TestAssetService(root: assets),
            timeoutSeconds: 5
        )

        #expect(report.exitCode == 0)
        #expect(report.items.first { $0.id == "text_rendering" }?.status == .passed)
        #expect(report.rawOutput.contains("probe=70_text_rendering_probe"))
        let log = try String(contentsOf: report.logURL, encoding: .utf8)
        #expect(log.contains("probeAssetId=text-rendering"))
        #expect(log.contains("probeSuite=\(runner.path)"))
        #expect(log.contains("PASS text_rendering"))
    }

    private func testEngine(root: URL) -> EngineManifest {
        EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-test",
            arch: .win64,
            supportsWin32: true,
            winePath: root.appendingPathComponent("engine/loader/wine").path,
            wineserverPath: root.appendingPathComponent("engine/loader/wineserver").path,
            runtimePath: root.appendingPathComponent("runtime").path,
            defaultEnv: ["WINE_D3D_CONFIG": "renderer=vulkan,csmt=0x0"]
        )
    }

    private func testBottle() -> BottleManifest {
        BottleManifest(
            id: "diagnostics",
            name: "Diagnostics",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
    }
}
