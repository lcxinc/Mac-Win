import Foundation
import Testing
@testable import MacWinCore

@Suite("Test asset service")
struct TestAssetServiceTests {
    @Test("Default test asset report covers runners 64-bit and 32-bit probes")
    func defaultTestAssetReportCoversProbeSuite() {
        let report = TestAssetService().report()

        #expect(report.statuses.contains { $0.id == "run-suite" && $0.kind == .runner })
        #expect(report.statuses.contains { $0.id == "console" && $0.architecture == .x86_64 })
        #expect(report.statuses.contains { $0.id == "tls-winhttp-win32" && $0.architecture == .i386 })
        #expect(report.statuses.contains { $0.id == "d3d12-device" && $0.category == .graphics })
        #expect(report.statuses.contains { $0.id == "xaudio2" && $0.category == .audio })
        #expect(report.statuses.contains { $0.id == "game-shader" && $0.category == .game })
        #expect(report.statuses.contains { $0.id == "text-rendering" && $0.category == .core })
        #expect(report.statuses.contains { $0.id == "text-rendering-source" && $0.kind == .source })
        #expect(report.statuses.contains { $0.id == "window-input" && $0.category == .windowing })
        #expect(report.statuses.contains { $0.id == "window-input-source" && $0.kind == .source })
        #expect(report.statuses.contains { $0.id == "ipc-file-mapping" && $0.required == false })
        #expect(report.statuses.contains { $0.id == "ipc-file-mapping-source" && $0.kind == .source && $0.required == false })
        #expect(report.statuses.contains { $0.id == "network-list-manager" && $0.category == .network })
        #expect(report.statuses.contains { $0.id == "network-list-manager-win32" && $0.architecture == .i386 })
        #expect(report.statuses.contains { $0.id == "network-list-manager-source" && $0.kind == .source })
        #expect(report.statuses.contains { $0.id == "jasp-boost-ipc" && $0.required == false })
        #expect(report.statuses.contains { $0.id == "jasp-boost-ipc-source" && $0.kind == .source && $0.required == false })
        #expect(report.statuses.contains { $0.id == "jasp-special-float-eh" && $0.required == false })
        #expect(report.statuses.contains { $0.id == "jasp-special-float-eh-source" && $0.kind == .source && $0.required == false })
        #expect(report.statuses.contains { $0.id == "jasp-createprocess" && $0.required == false })
        #expect(report.statuses.contains { $0.id == "jasp-createprocess-source" && $0.kind == .source && $0.required == false })
        #expect(report.requiredCount == TestAssetService.defaultDefinitions.filter(\.required).count)
        #expect(report.runbook?.groups.contains { $0.category == .graphics && $0.assetIds.contains("vulkan") } == true)
        let hasLocalProbeSuite = FileManager.default.fileExists(
            atPath: URL(fileURLWithPath: TestAssetService.defaultRootPath)
                .appendingPathComponent("run-suite.sh").path
        )
        if hasLocalProbeSuite {
            #expect(report.runbook?.suiteCommand?.last?.hasSuffix("run-suite.sh") == true)
            #expect(report.runbook?.groups.flatMap(\.commands).first { $0.assetId == "console" }?.command?.last == "00_console_probe")
            #expect(report.runbook?.groups.flatMap(\.commands).first { $0.assetId == "iphlpapi-adapters" }?.command?.last == "15_iphlpapi_probe")
            #expect(report.runbook?.groups.flatMap(\.commands).first { $0.assetId == "tls-winhttp-win32" }?.command?.last == "10_tls_winhttp_probe_win32")
            #expect(report.runbook?.groups.flatMap(\.commands).first { $0.assetId == "tls-winhttp-win32" }?.note?.contains("WoW64") == true)
            #expect(TestAssetService().runCommand(forAssetId: "window-input")?.command?.last == "80_window_input_probe")
            #expect(TestAssetService().runCommand(forAssetId: "ipc-file-mapping")?.command?.last == "90_ipc_file_mapping_probe")
            #expect(TestAssetService().runCommand(forAssetId: "network-list-manager")?.command?.last == "92_network_list_probe")
            #expect(TestAssetService().runCommand(forAssetId: "network-list-manager-win32")?.command?.last == "92_network_list_probe_win32")
            #expect(TestAssetService().runCommand(forAssetId: "jasp-boost-ipc")?.command?.last == "95_jasp_boost_ipc_probe")
            #expect(TestAssetService().runCommand(forAssetId: "jasp-special-float-eh")?.command?.last == "96_jasp_special_float_eh_probe")
            #expect(TestAssetService().runCommand(forAssetId: "jasp-createprocess")?.command?.last == "97_jasp_createprocess_probe")
        } else {
            #expect(report.runbook?.suiteCommand == nil)
            #expect(report.missingRequiredCount > 0)
        }
    }

    @Test("Missing required assets are counted")
    func missingRequiredAssetsAreCounted() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinTestAssetMissingTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root.appendingPathComponent("bin", isDirectory: true), withIntermediateDirectories: true)
        try Data("probe".utf8).write(to: root.appendingPathComponent("bin/00_console_probe.exe"))

        let report = TestAssetService(root: root).report()

        #expect(report.presentCount == 1)
        #expect(report.missingRequiredCount == report.requiredCount - 1)
        #expect(report.statuses.first { $0.id == "console" }?.exists == true)
        #expect(report.statuses.first { $0.id == "run-suite" }?.exists == false)
        #expect(report.isReady == false)
        #expect(report.runbook?.canRunSuite == false)
        #expect(report.runbook?.missingRequiredAssetIds.contains("run-suite") == true)
    }

    @Test("Asset hashes are included when requested")
    func assetHashesAreIncludedWhenRequested() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinTestAssetHashTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root.appendingPathComponent("bin", isDirectory: true), withIntermediateDirectories: true)
        let probe = root.appendingPathComponent("bin/00_console_probe.exe")
        try Data("probe".utf8).write(to: probe)

        let report = TestAssetService(root: root).report(includeHashes: true)
        let console = try #require(report.statuses.first { $0.id == "console" })

        #expect(console.exists == true)
        #expect(console.byteCount == 5)
        #expect(console.sha256 == Hashing.sha256Hex(data: Data("probe".utf8)))
        #expect(report.statuses.first { $0.id == "run-suite" }?.sha256 == nil)
    }

    @Test("Runbook shell script exposes suite build list and single-probe modes")
    func runbookShellScriptExposesRunnableModes() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinTestAssetRunbookTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root.appendingPathComponent("bin", isDirectory: true), withIntermediateDirectories: true)
        try Data("#!/usr/bin/env bash\n".utf8).write(to: root.appendingPathComponent("build.sh"))
        try Data("#!/usr/bin/env bash\n".utf8).write(to: root.appendingPathComponent("run-suite.sh"))
        try Data("#!/usr/bin/env bash\n".utf8).write(to: root.appendingPathComponent("run-one.sh"))
        try Data("probe".utf8).write(to: root.appendingPathComponent("bin/00_console_probe.exe"))

        let runbook = TestAssetService(root: root).runbook()
        let script = TestAssetService.shellScript(for: runbook)

        #expect(runbook.buildCommand == [root.appendingPathComponent("build.sh").path])
        #expect(runbook.suiteCommand == [root.appendingPathComponent("run-suite.sh").path])
        #expect(script.contains("suite)"))
        #expect(script.contains("build)"))
        #expect(script.contains("list)"))
        #expect(script.contains("console)"))
        #expect(script.contains("00_console_probe"))
    }

    @Test("Log issue recommended probe script runs only related runnable probes")
    func logIssueRecommendedProbeScriptRunsOnlyRelatedRunnableProbes() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRecommendedProbeScriptTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root.appendingPathComponent("bin", isDirectory: true), withIntermediateDirectories: true)
        try Data("#!/usr/bin/env bash\n".utf8).write(to: root.appendingPathComponent("run-one.sh"))
        try Data("probe".utf8).write(to: root.appendingPathComponent("bin/70_text_rendering_probe.exe"))
        try Data("probe".utf8).write(to: root.appendingPathComponent("bin/80_window_input_probe.exe"))

        let report = LogIssueReport(
            logs: [],
            topIssues: [
                LogIssueTrend(
                    id: "text-rendering",
                    severity: "high",
                    title: "Text rendering",
                    detail: "Text issue",
                    count: 1,
                    relatedHints: ["fontRenderingIssue"],
                    affectedLogNames: ["app.log"],
                    probeAssetIds: ["text-rendering", "window-input"]
                )
            ],
            recentFailures: [
                LogIssueSample(
                    name: "app.log",
                    path: "/tmp/app.log",
                    modifiedAt: Date(timeIntervalSince1970: 1_700_000_000),
                    health: LogHealth.failed.rawValue,
                    errorCount: 1,
                    warningCount: 0,
                    fixmeCount: 0,
                    passCount: 0,
                    failCount: 1,
                    hints: ["fontRenderingIssue"],
                    probableIssueIds: ["text-rendering"],
                    probeAssetIds: ["text-rendering", "d3d11"]
                )
            ]
        )

        let runbook = TestAssetService(root: root).runbook()
        let ids = TestAssetService.recommendedProbeIds(for: report)
        let script = TestAssetService.shellScript(forRecommendedProbes: report, runbook: runbook)

        #expect(ids == ["text-rendering", "window-input", "d3d11"])
        #expect(script.contains("MODE=\"${1:-run}\""))
        #expect(script.contains("text-rendering runnable"))
        #expect(script.contains("window-input runnable"))
        #expect(script.contains("SKIP d3d11: missing probe asset or single-probe runner"))
        #expect(script.contains("70_text_rendering_probe"))
        #expect(script.contains("80_window_input_probe"))
    }

    @Test("Coverage report combines assets and latest run history")
    func coverageReportCombinesAssetsAndLatestRunHistory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinTestCoverageTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root.appendingPathComponent("bin", isDirectory: true), withIntermediateDirectories: true)
        try Data("probe".utf8).write(to: root.appendingPathComponent("bin/00_console_probe.exe"))
        try Data("probe".utf8).write(to: root.appendingPathComponent("bin/70_text_rendering_probe.exe"))
        try Data("probe".utf8).write(to: root.appendingPathComponent("bin/30_d3d11_probe.exe"))
        try Data("probe".utf8).write(to: root.appendingPathComponent("bin/40_xaudio2_probe.exe"))
        let logs = root.appendingPathComponent("logs", isDirectory: true)
        try FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)
        let consoleLog = logs.appendingPathComponent("00_console_probe.log")
        let textLog = logs.appendingPathComponent("70_text_rendering_probe.log")
        let d3d11Log = logs.appendingPathComponent("30_d3d11_probe.log")
        try Data("PASS console\n".utf8).write(to: consoleLog)
        try Data("0\n".utf8).write(to: logs.appendingPathComponent("00_console_probe.exit"))
        try Data("PASS text_rendering\n".utf8).write(to: textLog)
        try Data("0\n".utf8).write(to: logs.appendingPathComponent("70_text_rendering_probe.exit"))
        try Data("FAIL d3d11\n".utf8).write(to: d3d11Log)
        try Data("1\n".utf8).write(to: logs.appendingPathComponent("30_d3d11_probe.exit"))

        let assets = TestAssetService(root: root).report()
        let history = TestRunHistoryService(root: root).report()
        let coverage = TestCoverageReport.make(assetReport: assets, runHistory: history)

        #expect(coverage.requiredExecutableCount == 16)
        #expect(coverage.presentExecutableCount == 4)
        #expect(coverage.missingRequiredExecutableCount == 12)
        #expect(coverage.passedAssetCount == 2)
        #expect(coverage.failedAssetCount == 1)
        #expect(coverage.unverifiedAssetCount == 1)
        #expect(coverage.verifiedCategoryCount == 1)
        #expect(coverage.categories.first { $0.category == .core }?.isVerified == true)
        #expect(coverage.categories.first { $0.category == .core }?.passedAssetIds == ["console", "text-rendering"])
        #expect(coverage.categories.first { $0.category == .graphics }?.failedAssetIds == ["d3d11"])
        #expect(coverage.categories.first { $0.category == .audio }?.unverifiedAssetIds == ["xaudio2"])
        #expect(coverage.categories.first { $0.category == .network }?.missingRequiredAssetIds == ["iphlpapi-adapters", "network-list-manager", "tls-winhttp"])
        #expect(coverage.categories.first { $0.category == .windowing }?.missingRequiredAssetIds == ["window-input"])

        let csv = TestCoverageReport.csv(report: coverage)
        #expect(csv.contains("category,asset_id,asset_name,asset_status,category_ready,category_verified"))
        #expect(csv.contains("core,console,Win32 Console Probe,passed,true,true"))
        #expect(csv.contains("graphics,d3d11,D3D11 Device Probe,failed,false,false"))
        #expect(csv.contains("audio,xaudio2,xaudio2,unverified,true,false"))
        #expect(csv.contains("network,tls-winhttp,tls-winhttp,missingRequired,false,false"))
    }
}
