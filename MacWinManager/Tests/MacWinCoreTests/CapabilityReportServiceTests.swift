import Foundation
import Testing
@testable import MacWinCore

@Suite("Capability report service")
struct CapabilityReportServiceTests {
    @Test("Capability report summarizes engines bottles catalog logs and diagnostics")
    func capabilityReportSummarizesCurrentState() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinCapabilityReportTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()
        try FileManager.default.createDirectory(at: root.appendingPathComponent("test-assets/bin", isDirectory: true), withIntermediateDirectories: true)
        try Data("#!/usr/bin/env bash\n".utf8).write(to: root.appendingPathComponent("test-assets/build.sh"))
        try Data("#!/usr/bin/env bash\n".utf8).write(to: root.appendingPathComponent("test-assets/run-suite.sh"))
        try Data("#!/usr/bin/env bash\n".utf8).write(to: root.appendingPathComponent("test-assets/run-one.sh"))
        try Data("probe".utf8).write(to: root.appendingPathComponent("test-assets/bin/00_console_probe.exe"))
        try Data("probe".utf8).write(to: root.appendingPathComponent("test-assets/bin/70_text_rendering_probe.exe"))
        try Data("probe".utf8).write(to: root.appendingPathComponent("test-assets/bin/80_window_input_probe.exe"))
        let testAssetLogs = root.appendingPathComponent("test-assets/logs", isDirectory: true)
        try FileManager.default.createDirectory(at: testAssetLogs, withIntermediateDirectories: true)
        let consoleProbeLog = testAssetLogs.appendingPathComponent("00_console_probe.log")
        let textProbeLog = testAssetLogs.appendingPathComponent("70_text_rendering_probe.log")
        let windowProbeLog = testAssetLogs.appendingPathComponent("80_window_input_probe.log")
        let d3d11ProbeLog = testAssetLogs.appendingPathComponent("30_d3d11_probe.log")
        try Data("PASS console\n".utf8).write(to: consoleProbeLog)
        try Data("0\n".utf8).write(to: testAssetLogs.appendingPathComponent("00_console_probe.exit"))
        try Data("PASS text_rendering\n".utf8).write(to: textProbeLog)
        try Data("0\n".utf8).write(to: testAssetLogs.appendingPathComponent("70_text_rendering_probe.exit"))
        try Data("PASS window_input\n".utf8).write(to: windowProbeLog)
        try Data("0\n".utf8).write(to: testAssetLogs.appendingPathComponent("80_window_input_probe.exit"))
        try Data("FAIL d3d11\n".utf8).write(to: d3d11ProbeLog)
        try Data("1\n".utf8).write(to: testAssetLogs.appendingPathComponent("30_d3d11_probe.exit"))
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 340)], ofItemAtPath: consoleProbeLog.path)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 350)], ofItemAtPath: textProbeLog.path)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 355)], ofItemAtPath: windowProbeLog.path)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 360)], ofItemAtPath: d3d11ProbeLog.path)

        let engineRuntime = root.appendingPathComponent("runtime", isDirectory: true)
        let engineLoader = root.appendingPathComponent("engine/loader", isDirectory: true)
        try FileManager.default.createDirectory(at: engineRuntime, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: engineLoader, withIntermediateDirectories: true)
        let winePath = engineLoader.appendingPathComponent("wine")
        let wineserverPath = engineLoader.appendingPathComponent("wineserver")
        try Data("wine".utf8).write(to: winePath)
        try Data("wineserver".utf8).write(to: wineserverPath)

        let engine = EngineManifest(
            id: "wine-test",
            name: "Wine Test",
            wineVersion: "wine-11.11",
            arch: .win64,
            supportsWin32: true,
            winePath: winePath.path,
            wineserverPath: wineserverPath.path,
            runtimePath: engineRuntime.path,
            defaultEnv: ["WINE_D3D_CONFIG": "renderer=vulkan,csmt=0x0"],
            healthChecks: [HealthCheck(id: "version", name: "Wine Version", command: ["wine", "--version"])]
        )

        let bottle = BottleManifest(
            id: BottleService.highPerformanceBottleId,
            name: "High Performance Windows 11",
            windowsVersion: "win11",
            arch: .win64,
            engineId: engine.id,
            envOverrides: [
                GraphicsPreset.environmentKey: GraphicsPreset.wineD3DVulkan.rawValue,
                "WINE_D3D_CONFIG": "renderer=vulkan,csmt=0x0"
            ],
            installedApps: [
                LauncherManifest(
                    id: "steam",
                    appId: "steam",
                    bottleId: BottleService.highPerformanceBottleId,
                    displayName: "Steam",
                    exePath: "C:\\Program Files\\Steam\\Steam.exe",
                    envOverrides: ["MACWIN_COMPAT_PROFILE": "steam-client"]
                ),
                LauncherManifest(
                    id: "hidden",
                    appId: "hidden",
                    bottleId: BottleService.highPerformanceBottleId,
                    displayName: "Hidden",
                    exePath: "C:\\Hidden\\hidden.exe",
                    showInHome: false
                )
            ],
            createdAt: Date(timeIntervalSince1970: 100),
            updatedAt: Date(timeIntervalSince1970: 200)
        )
        try FileManager.default.createDirectory(at: paths.bottleDriveCURL(id: bottle.id), withIntermediateDirectories: true)
        try Data("ok\n".utf8).write(
            to: paths.bottleDirectory(id: bottle.id).appendingPathComponent(BottleService.winebootSentinelName)
        )

        let failedLog = paths.logsDirectory.appendingPathComponent("failed.log")
        let passedLog = paths.logsDirectory.appendingPathComponent("passed.log")
        try Data("""
        err:winhttp certificate validation failed
        20_vulkan_probe.exe FAIL vulkan
        """.utf8).write(to: failedLog)
        try Data("40_xaudio2_probe.exe PASS xaudio2\n".utf8).write(to: passedLog)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 300)], ofItemAtPath: failedLog.path)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 400)], ofItemAtPath: passedLog.path)
        let installerURL = paths.downloadsDirectory.appendingPathComponent("tool.msi")
        try Data("installer".utf8).write(to: installerURL)
        let installerHash = try Hashing.sha256Hex(file: installerURL)
        try InstallerDownloadHistoryService(paths: paths).save(InstallerDownloadRecord(
            id: "tool-download",
            recipeId: "tool",
            recipeName: "Tool",
            fileName: "tool.msi",
            sourceURL: "https://example.test/tool.msi",
            destinationPath: installerURL.path,
            startedAt: Date(timeIntervalSince1970: 430),
            endedAt: Date(timeIntervalSince1970: 431),
            state: .downloaded,
            expectedSha256: installerHash,
            actualSha256: installerHash,
            byteCount: 9
        ))
        try InstallHistoryService(paths: paths).save(InstallTask(
            id: "tool-install",
            recipeId: "tool",
            bottleId: bottle.id,
            state: .succeeded,
            progressText: "Installed Tool",
            logPath: paths.logsDirectory.appendingPathComponent("tool-install.log").path,
            startedAt: Date(timeIntervalSince1970: 440),
            endedAt: Date(timeIntervalSince1970: 441),
            exitCode: 0
        ))
        let launchRecords = LaunchHistoryService.recordsDirectory(in: paths.logsDirectory)
        try FileManager.default.createDirectory(at: launchRecords, withIntermediateDirectories: true)
        try JSONStore().save(
            WineLaunchRecord(
                id: "steam-launch",
                mode: .detached,
                state: .completed,
                logPath: passedLog.path,
                startedAt: Date(timeIntervalSince1970: 450),
                endedAt: Date(timeIntervalSince1970: 455),
                durationMilliseconds: 5_000,
                processIdentifier: 900,
                exitCode: 0,
                bottleId: bottle.id,
                bottleName: bottle.name,
                engineId: engine.id,
                winePath: engine.winePath,
                exe: "C:\\Program Files\\Steam\\Steam.exe",
                args: ["-no-cef-sandbox"],
                commandLine: ["/usr/bin/arch", "-x86_64", engine.winePath, "C:\\Program Files\\Steam\\Steam.exe", "-no-cef-sandbox"],
                workingDirectory: paths.bottleDriveCURL(id: bottle.id).path,
                environment: ["MACWIN_COMPAT_PROFILE": "steam-client"]
            ),
            to: launchRecords.appendingPathComponent("steam-launch.launch.json")
        )
        try JSONStore().save(
            SoftwareSmokeRunReport(
                generatedAt: "2026-06-26T08:00:00Z",
                runId: "winscp-superseded",
                suite: "all",
                prefix: "/tmp/winscp",
                logDirectory: paths.logsDirectory.appendingPathComponent("SoftwareSmokeRuns/winscp-superseded").path,
                recordCount: 3,
                stateCounts: ["launched": 1, "passed": 1, "skipped": 1],
                effectiveStateCounts: ["launched": 1, "passed": 1, "superseded": 1],
                supersededSkips: [
                    SoftwareSmokeRunSupersededSkip(
                        id: "winscp-client",
                        exitCode: 108,
                        logPath: "/tmp/winscp-client.log",
                        note: "legacy skipped",
                        reason: "Use WinSCP x64 portable.",
                        supersededBy: ["winscp-x64-portable", "winscp-x64-cli-help"],
                        coveredBy: [
                            SoftwareSmokeRunCoveredAlternate(id: "winscp-x64-portable", state: "launched"),
                            SoftwareSmokeRunCoveredAlternate(id: "winscp-x64-cli-help", state: "passed")
                        ]
                    )
                ],
                records: [
                    SoftwareSmokeRunRecord(id: "winscp-client", phase: "launch", state: "skipped", exitCode: 108),
                    SoftwareSmokeRunRecord(id: "winscp-x64-portable", phase: "launch", state: "launched", exitCode: 124),
                    SoftwareSmokeRunRecord(id: "winscp-x64-cli-help", phase: "launch", state: "passed", exitCode: 0)
                ]
            ),
            to: paths.logsDirectory
                .appendingPathComponent("SoftwareSmokeRuns/winscp-superseded", isDirectory: true)
                .appendingPathComponent("software-smoke-report.json")
        )

        let recipes = [
            RecipeManifest(
                id: "macwin-core-capability-tests",
                name: "MacWin Core Capability Tests",
                publisher: "MacWin",
                category: "Diagnostics",
                compatibilityRating: .excellent,
                installer: InstallerSpec(mode: .none),
                bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
                engineRequirements: EngineRequirements(requiresWin32: true),
                launchers: []
            ),
            RecipeManifest(
                id: "macwin-game-tests",
                name: "MacWin Game Tests",
                publisher: "MacWin",
                category: "Diagnostics",
                compatibilityRating: .good,
                installer: InstallerSpec(mode: .none),
                bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
                engineRequirements: EngineRequirements(),
                launchers: []
            ),
            RecipeManifest(
                id: "tool",
                name: "Tool",
                publisher: "Tools",
                category: "Utilities",
                compatibilityRating: .good,
                installer: InstallerSpec(
                    mode: .download,
                    url: "https://example.test/tool.msi",
                    fileName: "tool.msi",
                    sha256: installerHash
                ),
                bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
                engineRequirements: EngineRequirements(),
                launchers: []
            )
        ]

        let diagnostics = DiagnosticReport(
            exitCode: 1,
            logURL: paths.logsDirectory.appendingPathComponent("diagnostics.log"),
            items: [
                DiagnosticItem(id: "console", name: "Console", passed: true, detail: "PASS", category: .core),
                DiagnosticItem(id: "vulkan", name: "Vulkan", passed: false, detail: "FAIL", category: .graphics),
                DiagnosticItem(id: "tls_winhttp_win32", name: "TLS 32-bit", passed: false, detail: "SKIP", category: .win32, status: .skipped)
            ],
            rawOutput: "",
            timedOut: true,
            durationSeconds: 12.5
        )

        let report = CapabilityReportService(
            paths: paths,
            testAssetService: TestAssetService(root: root.appendingPathComponent("test-assets", isDirectory: true)),
            runtimeProcessAuditService: RuntimeProcessAuditService(processListProvider: {
                """
                  301 C:\\Program Files\\miHoYo Launcher\\1.16.1.364\\HYP.exe --disable-direct-write --disable-features=DWriteFontProxy,UseDWriteCore
                  302 C:\\Program Files\\Steam\\Steam.exe -no-cef-sandbox
                """
            }),
            runtimeApplicationAuditService: RuntimeApplicationAuditService(applicationListProvider: {
                """
                 1) "MacWin 管理器" ASN:0x0-0x1001: (in front)
                    bundleID="dev.local.macwin.manager"
                    bundle path="/Users/alice/project/Mac-Win/MacWinManager/dist/MacWin Manager.app"
                    executable path="/Users/alice/project/Mac-Win/MacWinManager/dist/MacWin Manager.app/Contents/MacOS/MacWinManagerApp"
                    pid = 701 type="Foreground" Arch=ARM64
                 2) "Steam" ASN:0x0-0x2002:
                    bundleID="org.winehq.wine.steam"
                    bundle path="/Users/alice/Library/Application Support/MacWin/Bottles/game/drive_c/Program Files/Steam/Steam.exe"
                    executable path="/Users/alice/project/Mac-Win/refs/build/loader/wine"
                    pid = 702 type="Foreground" Arch=X86_64
                """
            }),
            hostGUISessionService: HostGUISessionService(stateProvider: { .locked })
        ).makeReport(
            generatedAt: Date(timeIntervalSince1970: 500),
            engines: [engine],
            bottles: [bottle],
            recipes: recipes,
            diagnosticReport: diagnostics
        )

        #expect(report.schemaVersion == 1)
        #expect(report.rootPath == root.path)
        #expect(report.hostEnvironment?.rootPath == root.path)
        #expect(report.hostEnvironment?.engineCount == 1)
        #expect(report.hostEnvironment?.bottleCount == 1)
        #expect(report.hostEnvironment?.recipeCount == recipes.count)
        #expect(report.hostEnvironment?.recentLogCount == 2)
        #expect(report.hostGUISession?.state == .locked)
        #expect(report.hostGUISession?.isInteractive == false)
        #expect(report.hostEnvironment?.pathStates.first { $0.id == "logs" }?.exists == true)
        #expect(report.engines.first?.supportsWin32 == true)
        #expect(report.engines.first?.winePathExists == true)
        #expect(report.engines.first?.runtimePathExists == true)
        #expect(report.engines.first?.defaultGraphicsConfig == "renderer=vulkan,csmt=0x0")
        #expect(report.bottles.first?.hasDriveC == true)
        #expect(report.bottles.first?.hasWinebootSentinel == true)
        #expect(report.bottles.first?.launcherCount == 2)
        #expect(report.bottles.first?.visibleLauncherCount == 1)
        #expect(report.bottles.first?.compatibilityProfiles == ["steam-client"])
        #expect(report.bottleHealth.bottleCount == 1)
        #expect(report.bottleHealth.warningBottleCount == 1)
        #expect(report.bottleHealth.actionRequiredBottleCount == 0)
        #expect(report.bottleHealth.missingFontConfigCount == 1)
        #expect(report.bottleHealth.incompleteCompatibilityProfileCount == 1)
        #expect(report.bottleHealth.bottles.first?.launchers.first { $0.launcherId == "steam" }?.missingCompatibilityEnvironmentKeys.contains("MACWIN_STEAMWEBHELPER_ARGS") == true)
        #expect(report.catalog.recipeCount == 3)
        #expect(report.catalog.hasCoreCapabilityTests == true)
        #expect(report.catalog.hasGameTests == true)
        #expect(report.recipeReadiness.recipeCount == 3)
        #expect(report.recipeReadiness.blockedCount == 3)
        #expect(report.recipeReadiness.issueCounts["missingLauncher"] == 3)
        #expect(report.recipeReadiness.entries.first { $0.recipeId == "tool" }?.sha256Present == true)
        #expect(report.installerAssets.recipeCount == 3)
        #expect(report.installerAssets.downloadableRecipeCount == 1)
        #expect(report.installerAssets.cachedRecipeCount == 1)
        #expect(report.installerAssets.hashMatchCount == 1)
        #expect(report.installerAssets.recipes.first { $0.recipeId == "tool" }?.hashStatus == .match)
        #expect(report.installerDownloadHistory?.totalRecordCount == 1)
        #expect(report.installerDownloadHistory?.downloadedCount == 1)
        #expect(report.installerDownloadHistory?.records.first?.recipeId == "tool")
        #expect(report.installerDownloadHistory?.records.first?.actualSha256 == installerHash)
        #expect(report.softwareTestPlan.recipeCount == 3)
        #expect(report.softwareTestPlan.stateCounts["blocked"] == 3)
        #expect(report.softwareTestPlan.readyToInstallCount == 0)
        #expect(report.softwareTestPlan.installedCount == 0)
        #expect(report.softwareTestPlan.nextActions.count == 3)
        #expect(report.softwareTestPlan.entries.first { $0.recipeId == "tool" }?.state == .blocked)
        #expect(report.softwareTestPlan.entries.first { $0.recipeId == "tool" }?.blockers.contains("missingLauncher") == true)
        #expect(report.softwareSmokeMatrix.recipeCount == 3)
        #expect(report.softwareSmokeMatrix.rows.first { $0.recipeId == "tool" }?.stage == .installer)
        #expect(report.softwareSmokeMatrix.rows.first { $0.recipeId == "tool" }?.checklist.first { $0.id == "installer" }?.state == .passed)
        #expect(report.softwareSmokeMatrix.rows.first { $0.recipeId == "tool" }?.checklist.first { $0.id == "launcher" }?.state == .pending)
        #expect(report.softwareSmokeMatrix.nextActions.count == 3)
        #expect(report.softwareSmokeRuns?.reportCount == 1)
        #expect(report.softwareSmokeRuns?.rawStateCounts["skipped"] == 1)
        #expect(report.softwareSmokeRuns?.effectiveStateCounts["superseded"] == 1)
        #expect(report.softwareSmokeRuns?.supersededSkipCount == 1)
        #expect(report.softwareSmokeRuns?.uncoveredSkippedCount == 0)
        #expect(report.softwareSampleCatalog.sampleCount >= 6)
        #expect(report.softwareSampleCatalog.catalogBackedCount == 0)
        #expect(report.softwareSampleCatalog.localInstallerCount >= 3)
        #expect(report.softwareSampleCatalog.samples.contains { $0.id == "itch" })
        #expect(report.softwareSampleCatalog.samples.contains { $0.id == "lenovo-app-store" })
        #expect(report.softwareSampleCatalog.samples.contains { $0.id == "tencent-app-store" })
        #expect(report.softwareSampleLogCorrelation.sampleCount == report.softwareSampleCatalog.sampleCount)
        #expect(report.softwareSampleLogCorrelation.matchedSampleCount == 1)
        #expect(report.softwareSampleLogCorrelation.launchMatchedSampleCount == 1)
        #expect(report.softwareSampleLogCorrelation.logMatchedSampleCount == 1)
        #expect(report.softwareSampleLogCorrelation.entries.first { $0.sampleId == "steam" }?.launchRecordIds == ["steam-launch"])
        #expect(report.softwareSampleLogCorrelation.entries.first { $0.sampleId == "steam" }?.logNames == ["passed.log"])
        #expect(report.softwareSampleLogCorrelation.entries.first { $0.sampleId == "steam" }?.recommendedProbeIds.contains("80_window_input_probe") == true)
        #expect(report.installHistory?.totalTaskCount == 1)
        #expect(report.installHistory?.succeededCount == 1)
        #expect(report.installHistory?.tasks.first?.recipeId == "tool")
        #expect(report.testAssets.totalCount == TestAssetService.defaultDefinitions.count)
        #expect(report.testAssets.presentCount == 5)
        #expect(report.testAssets.missingRequiredCount == report.testAssets.requiredCount - 5)
        #expect(report.testAssets.statuses.first { $0.id == "console" }?.exists == true)
        #expect(report.testAssets.statuses.first { $0.id == "text-rendering" }?.exists == true)
        #expect(report.testAssets.statuses.first { $0.id == "window-input" }?.exists == true)
        #expect(report.testAssets.runbook?.buildCommand?.last?.hasSuffix("build.sh") == true)
        #expect(report.testAssets.runbook?.suiteCommand?.last?.hasSuffix("run-suite.sh") == true)
        #expect(report.testAssets.runbook?.groups.flatMap(\.commands).first { $0.assetId == "console" }?.command?.last == "00_console_probe")
        #expect(report.testRunHistory?.totalRunCount == 4)
        #expect(report.testRunHistory?.mappedRunCount == 4)
        #expect(report.testRunHistory?.statusCounts["passed"] == 3)
        #expect(report.testRunHistory?.statusCounts["failed"] == 1)
        #expect(report.testRunHistory?.runs.first { $0.assetId == "text-rendering" }?.outcome == .passed)
        #expect(report.testRunHistory?.runs.first { $0.assetId == "window-input" }?.outcome == .passed)
        #expect(report.testRunHistory?.runs.first { $0.assetId == "d3d11" }?.outcome == .failed)
        #expect(report.testCoverage.requiredExecutableCount == 16)
        #expect(report.testCoverage.presentExecutableCount == 3)
        #expect(report.testCoverage.missingRequiredExecutableCount == 13)
        #expect(report.testCoverage.passedAssetCount == 3)
        #expect(report.testCoverage.failedAssetCount == 0)
        #expect(report.testCoverage.verifiedCategoryCount == 2)
        #expect(report.testCoverage.categories.first { $0.category == .core }?.isVerified == true)
        #expect(report.testCoverage.categories.first { $0.category == .core }?.passedAssetIds == ["console", "text-rendering"])
        #expect(report.testCoverage.categories.first { $0.category == .windowing }?.isVerified == true)
        #expect(report.testCoverage.categories.first { $0.category == .graphics }?.missingRequiredAssetIds.contains("d3d11") == true)
        #expect(report.testExecutionPlan?.itemCount == 13)
        #expect(report.testExecutionPlan?.requiredCount == 13)
        #expect(report.testExecutionPlan?.highPriorityCount == 0)
        #expect(report.testExecutionPlan?.items.first { $0.assetId == "d3d11" }?.reasons.contains(.missingRequiredAsset) == true)
        #expect(report.launchHistory?.totalLaunchCount == 1)
        #expect(report.launchHistory?.completedCount == 1)
        #expect(report.launchHistory?.detachedCount == 1)
        #expect(report.launchHistory?.records.first?.id == "steam-launch")
        #expect(report.launchHistory?.records.first?.environment["MACWIN_COMPAT_PROFILE"] == "steam-client")
        #expect(report.activityTimeline.eventCount == 9)
        #expect(report.activityTimeline.errorEventCount == 3)
        #expect(report.activityTimeline.warningEventCount == 0)
        #expect(report.activityTimeline.infoEventCount == 6)
        #expect(report.activityTimeline.events.first?.kind == .diagnostics)
        #expect(report.activityTimeline.events.first?.timestamp == Date(timeIntervalSince1970: 500))
        #expect(report.activityTimeline.events.contains { $0.kind == .installerDownload && $0.appId == "tool" })
        #expect(report.activityTimeline.events.contains { $0.kind == .launch && $0.title == "Launch Steam.exe" })
        #expect(report.activityTimeline.events.contains { $0.kind == .logIssue && $0.title == "Log issue failed.log" })
        #expect(report.activityTimeline.events.contains { $0.kind == .testRun && $0.severity == .error && $0.appId == "d3d11" })
        #expect(report.logs.recentLogCount == 2)
        #expect(report.logs.healthCounts["failed"] == 1)
        #expect(report.logs.healthCounts["passed"] == 1)
        #expect(report.logs.hintCounts["networkTLSIssue"] == 1)
        #expect(report.logs.hintCounts["vulkanIssue"] == 1)
        #expect(report.logs.hintCounts["passObserved"] == 1)
        #expect(report.logs.issueReport.logsAnalyzed == 2)
        #expect(report.logs.issueReport.failedLogCount == 1)
        #expect(report.logs.issueReport.passedLogCount == 1)
        #expect(report.logs.issueReport.topIssues.map(\.id).contains("graphics-runtime"))
        #expect(report.logs.issueReport.topIssues.map(\.id).contains("network-tls"))
        #expect(report.logs.issueReport.topIssues.first { $0.id == "graphics-runtime" }?.affectedLogNames == ["failed.log"])
        #expect(report.logs.issueReport.topIssues.first { $0.id == "graphics-runtime" }?.probeAssetIds.contains("d3d11") == true)
        #expect(report.logs.issueReport.topIssues.first { $0.id == "network-tls" }?.probeAssetIds.contains("tls-winhttp") == true)
        #expect(report.logs.issueReport.recentFailures.map(\.name) == ["failed.log"])
        #expect(report.logs.issueReport.recentFailures.first?.probableIssueIds.contains("graphics-runtime") == true)
        #expect(report.logs.issueReport.recentFailures.first?.probableIssueIds.contains("network-tls") == true)
        #expect(report.logs.issueReport.recentFailures.first?.recommendedActions.isEmpty == false)
        #expect(report.logs.issueReport.recentFailures.first?.probeAssetIds.contains("d3d11") == true)
        #expect(report.logs.entries.first { $0.name == "passed.log" }?.launchContext?.launchRecordId == "steam-launch")
        #expect(report.logs.entries.first { $0.name == "passed.log" }?.launchContext?.bottleId == bottle.id)
        #expect(report.logs.entries.first { $0.name == "passed.log" }?.launchContext?.engineId == engine.id)
        #expect(report.logs.entries.first { $0.name == "passed.log" }?.launchContext?.exe == "C:\\Program Files\\Steam\\Steam.exe")
        #expect(report.logs.entries.first { $0.name == "passed.log" }?.launchContext?.args == ["-no-cef-sandbox"])
        #expect(report.logs.entries.first { $0.name == "passed.log" }?.launchContext?.exitCode == 0)
        #expect(report.logs.entries.first { $0.name == "failed.log" }?.launchContext == nil)
        #expect(report.logs.recommendations.map(\.id).contains("graphics-runtime"))
        #expect(report.logs.recommendations.map(\.id).contains("network-tls"))
        #expect(report.logs.recommendations.first { $0.id == "graphics-runtime" }?.affectedLogNames == ["failed.log"])
        #expect(report.logs.recommendations.first { $0.id == "graphics-runtime" }?.probeAssetIds.contains("vulkan") == true)
        #expect(report.logs.recommendations.first { $0.id == "graphics-runtime" }?.recommendedActions.isEmpty == false)
        #expect(report.logs.recommendations.first { $0.id == "network-tls" }?.severity == "medium")
        #expect(report.runtimeProcesses?.auditedProcessCount == 2)
        #expect(report.runtimeProcesses?.staleRenderingProcessCount == 1)
        #expect(report.runtimeProcesses?.findings.first?.id == "stale-runtime-rendering-flags")
        #expect(report.runtimeProcesses?.entries.first { $0.kind == .hoYoPlay }?.staleRenderingFlags.contains("use-dwrite-core-disabled") == true)
        #expect(report.runtimeApplications?.auditedApplicationCount == 2)
        #expect(report.runtimeApplications?.macWinApplicationCount == 1)
        #expect(report.runtimeApplications?.wineRelatedApplicationCount == 1)
        #expect(report.runtimeApplications?.entries.first { $0.kind == .macWinManager }?.processIdentifier == 701)
        #expect(report.diagnostics?.exitCode == 1)
        #expect(report.diagnostics?.timedOut == true)
        #expect(report.diagnostics?.durationSeconds == 12.5)
        #expect(report.diagnostics?.statusCounts["passed"] == 1)
        #expect(report.diagnostics?.statusCounts["failed"] == 1)
        #expect(report.diagnostics?.statusCounts["skipped"] == 1)
    }

    @Test("Capability report export writes decodable JSON")
    func capabilityReportExportWritesDecodableJSON() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinCapabilityReportExportTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = CapabilityReportService(
            paths: paths,
            runtimeProcessAuditService: RuntimeProcessAuditService(processListProvider: {
                """
                  301 C:\\Program Files\\miHoYo Launcher\\1.16.1.364\\HYP.exe --disable-direct-write --disable-features=DWriteFontProxy,UseDWriteCore
                """
            }),
            runtimeApplicationAuditService: RuntimeApplicationAuditService(applicationListProvider: {
                """
                 1) "MacWin 管理器" ASN:0x0-0x1001: (in front)
                    bundleID="dev.local.macwin.manager"
                    bundle path="/Users/alice/project/Mac-Win/MacWinManager/dist/MacWin Manager.app"
                    executable path="/Users/alice/project/Mac-Win/MacWinManager/dist/MacWin Manager.app/Contents/MacOS/MacWinManagerApp"
                    pid = 701 type="Foreground" Arch=ARM64
                """
            })
        )
        let generatedAt = Date(timeIntervalSince1970: 1_600_000_000)
        let url = try service.exportReport(
            generatedAt: generatedAt,
            engines: [],
            bottles: [],
            recipes: [],
            diagnosticReport: nil
        )

        #expect(url.lastPathComponent.hasPrefix("capability-report-"))
        #expect(url.pathExtension == "json")
        #expect(FileManager.default.fileExists(atPath: url.path))

        let decoded = try JSONStore().load(CapabilityReport.self, from: url)
        #expect(decoded.generatedAt == generatedAt)
        #expect(decoded.hostEnvironment?.rootPath == root.path)
        #expect(decoded.hostEnvironment?.engineCount == 0)
        #expect(decoded.engines.isEmpty)
        #expect(decoded.catalog.signedCuratedCatalogLoaded == false)
        #expect(decoded.recipeReadiness.recipeCount == 0)
        #expect(decoded.bottleHealth.bottleCount == 0)
        #expect(decoded.installerAssets.recipeCount == 0)
        #expect(decoded.softwareTestPlan.recipeCount == 0)
        #expect(decoded.softwareSmokeMatrix.recipeCount == 0)
        #expect(decoded.softwareSampleCatalog.sampleCount >= 6)
        #expect(decoded.softwareSampleCatalog.localInstallerCount >= 3)
        #expect(decoded.installHistory?.totalTaskCount == 0)
        #expect(decoded.logs.issueReport.logsAnalyzed == 0)
        #expect(decoded.logs.recommendations.isEmpty)
        #expect(decoded.runtimeProcesses?.auditedProcessCount == 1)
        #expect(decoded.runtimeProcesses?.staleRenderingProcessCount == 1)
        #expect(decoded.runtimeApplications?.auditedApplicationCount == 1)
        #expect(decoded.runtimeApplications?.macWinApplicationCount == 1)
        #expect(decoded.testAssets.runbook != nil)
        #expect(decoded.testAssets.runbook?.suiteCommand?.last?.hasSuffix("run-suite.sh") == true)
        #expect(decoded.testRunHistory?.totalRunCount ?? 0 >= 0)
        #expect(decoded.testCoverage.categories.count == 7)
        #expect(decoded.testExecutionPlan?.itemCount ?? 0 >= 0)
        #expect(decoded.launchHistory?.totalLaunchCount ?? 0 >= 0)
        #expect(decoded.activityTimeline.eventCount >= 0)

        let snapshotURL = paths.logsDirectory.appendingPathComponent("runtime-processes-2020-09-13T122640Z.json")
        let snapshotLogURL = paths.logsDirectory.appendingPathComponent("runtime-processes-2020-09-13T122640Z.log")
        #expect(FileManager.default.fileExists(atPath: snapshotURL.path))
        #expect(FileManager.default.fileExists(atPath: snapshotLogURL.path))
        let snapshot = try JSONStore().load(RuntimeProcessSnapshot.self, from: snapshotURL)
        #expect(snapshot.report.auditedProcessCount == 1)
        #expect(snapshot.report.staleRenderingProcessCount == 1)
        let snapshotLog = try String(contentsOf: snapshotLogURL, encoding: .utf8)
        #expect(snapshotLog.contains("warn: runtime-process-finding"))
    }

    @Test("Software smoke matrix fast report skips runtime audits")
    func softwareSmokeMatrixFastReportSkipsRuntimeAudits() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinSoftwareSmokeMatrixFastReportTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()
        let service = CapabilityReportService(
            paths: paths,
            runtimeProcessAuditService: RuntimeProcessAuditService(processListProvider: {
                fatalError("Software smoke matrix export must not collect runtime process state.")
            }),
            runtimeApplicationAuditService: RuntimeApplicationAuditService(applicationListProvider: {
                fatalError("Software smoke matrix export must not collect host application state.")
            })
        )

        let report = service.makeSoftwareSmokeMatrixReport(
            generatedAt: Date(timeIntervalSince1970: 1_800_000_000),
            engines: [],
            bottles: [],
            recipes: [],
            logLimit: 1
        )

        #expect(report.recipeCount == 0)
        #expect(report.rows.isEmpty)
        #expect(report.stageCounts.isEmpty)
    }
}
