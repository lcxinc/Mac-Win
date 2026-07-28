import Foundation
import Testing
@testable import MacWinCore

@Suite("Test session archive service")
struct TestSessionArchiveServiceTests {
    @Test("Test session archive writes summary and source report snapshots")
    func archiveWritesSessionSummaryAndSnapshots() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinTestSessionArchive-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root.appendingPathComponent("AppSupport", isDirectory: true))
        try paths.ensureBaseDirectories()
        let assetRoot = root.appendingPathComponent("exe-tests", isDirectory: true)
        let logs = assetRoot.appendingPathComponent("logs", isDirectory: true)
        try FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)

        let consoleLog = logs.appendingPathComponent("00_console_probe.log")
        try Data("PASS console\n".utf8).write(to: consoleLog)
        try Data("0\n".utf8).write(to: logs.appendingPathComponent("00_console_probe.exit"))
        let d3dLog = logs.appendingPathComponent("30_d3d11_probe.log")
        try Data("FAIL d3d11 missing adapter\n".utf8).write(to: d3dLog)
        try Data("1\n".utf8).write(to: logs.appendingPathComponent("30_d3d11_probe.exit"))

        let assets = TestAssetReport(
            rootPath: assetRoot.path,
            statuses: [
                TestAssetStatus(
                    id: "console",
                    name: "Console Probe",
                    kind: .executable,
                    category: .core,
                    architecture: .x86_64,
                    path: assetRoot.appendingPathComponent("bin/00_console_probe.exe").path,
                    required: true,
                    exists: true,
                    byteCount: 10
                ),
                TestAssetStatus(
                    id: "d3d11",
                    name: "D3D11 Probe",
                    kind: .executable,
                    category: .graphics,
                    architecture: .x86_64,
                    path: assetRoot.appendingPathComponent("bin/30_d3d11_probe.exe").path,
                    required: true,
                    exists: true,
                    byteCount: 10
                ),
                TestAssetStatus(
                    id: "xaudio2",
                    name: "XAudio2 Probe",
                    kind: .executable,
                    category: .audio,
                    architecture: .x86_64,
                    path: assetRoot.appendingPathComponent("bin/40_xaudio2_probe.exe").path,
                    required: true,
                    exists: false
                )
            ]
        )
        let runHistory = TestRunHistoryService(root: assetRoot).report()
        let coverage = TestCoverageReport.make(assetReport: assets, runHistory: runHistory)
        let executionPlan = TestExecutionPlan(
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            rootPath: assetRoot.path,
            items: [
                TestExecutionPlanItem(
                    id: "xaudio2",
                    assetId: "xaudio2",
                    name: "XAudio2 Probe",
                    category: .audio,
                    architecture: .x86_64,
                    priority: .required,
                    reasons: [.missingRequiredAsset],
                    executablePath: assetRoot.appendingPathComponent("bin/40_xaudio2_probe.exe").path,
                    exists: false,
                    command: []
                )
            ]
        )
        let logIssues = LogIssueReport(
            logs: [],
            topIssues: [
                LogIssueTrend(
                    id: "d3d11-failed",
                    severity: "high",
                    title: "D3D11 probe failed",
                    detail: "D3D11 adapter did not initialize.",
                    count: 1,
                    relatedHints: ["d3d11"],
                    affectedLogNames: [d3dLog.path]
                )
            ],
            recentFailures: []
        )
        let artifacts = DiagnosticArtifactIndexReport(
            generatedAt: Date(timeIntervalSince1970: 1_700_000_001),
            rootPath: paths.root.path,
            logsPath: paths.logsDirectory.path,
            artifactCount: 2,
            totalBytes: 42,
            kindCounts: [.log: 1, .table: 1],
            artifacts: []
        )
        let softwareSamples = SoftwareSampleCatalogService.report(
            rootPath: paths.root.path,
            recipes: [
                RecipeManifest(
                    id: "steam",
                    name: "Steam",
                    publisher: "Valve",
                    category: "Game Store",
                    compatibilityRating: .good,
                    installer: InstallerSpec(mode: .none),
                    bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
                    engineRequirements: EngineRequirements(),
                    launchers: []
                )
            ],
            generatedAt: Date(timeIntervalSince1970: 1_700_000_001)
        )
        let steamSample = try #require(softwareSamples.samples.first { $0.id == "steam" })
        let softwareSampleCorrelation = SoftwareSampleLogCorrelationReport(
            generatedAt: Date(timeIntervalSince1970: 1_700_000_001),
            rootPath: paths.root.path,
            entries: [
                SoftwareSampleLogCorrelationEntry(
                    sampleId: steamSample.id,
                    name: steamSample.name,
                    installSource: steamSample.installSource,
                    catalogBacked: steamSample.catalogBacked,
                    launchCount: 1,
                    logCount: 1,
                    failedLogCount: 1,
                    attentionLogCount: 0,
                    latestLaunchAt: Date(timeIntervalSince1970: 1_700_000_000),
                    latestLogModifiedAt: Date(timeIntervalSince1970: 1_700_000_001),
                    launchRecordIds: ["steam-launch"],
                    logNames: [d3dLog.lastPathComponent],
                    logPaths: [d3dLog.path],
                    probableIssueIds: ["d3d11-failed"],
                    recommendedProbeIds: ["d3d11"]
                )
            ]
        )
        let softwareCollection = SoftwareCollectionReport(
            generatedAt: Date(timeIntervalSince1970: 1_700_000_001),
            rootPath: paths.root.path,
            collections: [
                SoftwareCollectionDefinition(
                    id: "game-launchers",
                    name: "Game Launchers",
                    purpose: "Real launcher smoke coverage",
                    requiredRecipeIds: ["steam"]
                )
            ],
            missingRecipeIds: [],
            entries: [
                SoftwareCollectionEntry(
                    recipeId: "steam",
                    name: "Steam",
                    publisher: "Valve",
                    category: "Game Store",
                    collectionIds: ["game-launchers"],
                    compatibilityRating: .good,
                    installerMode: .download,
                    installerFileName: "SteamSetup.exe",
                    installerSourceURL: "https://cdn.example.invalid/SteamSetup.exe",
                    expectedSha256: String(repeating: "a", count: 64),
                    installerHashStatus: .missing,
                    cachedInstallerPath: paths.downloadsDirectory.appendingPathComponent("SteamSetup.exe").path,
                    cachedInstallerExists: false,
                    softwareState: .missingInstaller,
                    smokeStage: .install,
                    smokeSeverity: .blocked,
                    installedLauncherCount: 0,
                    latestLaunchState: nil,
                    latestLaunchLogPath: nil,
                    latestLogHealth: nil,
                    readinessIssues: [],
                    recommendedProbeIds: ["30_d3d11_probe"]
                )
            ]
        )
        let softwareCollectionAcceptance = SoftwareCollectionAcceptanceService().report(
            collection: softwareCollection,
            smokeMatrix: nil,
            testExecutionPlan: executionPlan,
            logIssues: logIssues,
            generatedAt: Date(timeIntervalSince1970: 1_700_000_001)
        )

        let archiveURL = try TestSessionArchiveService(paths: paths).exportArchive(
            generatedAt: Date(timeIntervalSince1970: 1_700_000_002),
            testAssets: assets,
            coverage: coverage,
            executionPlan: executionPlan,
            runHistory: runHistory,
            logIssues: logIssues,
            diagnosticArtifacts: artifacts,
            softwareSampleCatalog: softwareSamples,
            softwareSampleLogCorrelation: softwareSampleCorrelation,
            softwareCollection: softwareCollection,
            softwareCollectionAcceptance: softwareCollectionAcceptance
        )

        #expect(FileManager.default.fileExists(atPath: archiveURL.appendingPathComponent("test-session.json").path))
        #expect(FileManager.default.fileExists(atPath: archiveURL.appendingPathComponent("test-session.csv").path))
        #expect(FileManager.default.fileExists(atPath: archiveURL.appendingPathComponent("test-session.md").path))
        #expect(FileManager.default.fileExists(atPath: archiveURL.appendingPathComponent("test-assets.json").path))
        #expect(FileManager.default.fileExists(atPath: archiveURL.appendingPathComponent("test-coverage.json").path))
        #expect(FileManager.default.fileExists(atPath: archiveURL.appendingPathComponent("test-coverage.csv").path))
        #expect(FileManager.default.fileExists(atPath: archiveURL.appendingPathComponent("test-execution-plan.json").path))
        #expect(FileManager.default.fileExists(atPath: archiveURL.appendingPathComponent("test-run-history.json").path))
        #expect(FileManager.default.fileExists(atPath: archiveURL.appendingPathComponent("log-issues.json").path))
        #expect(FileManager.default.fileExists(atPath: archiveURL.appendingPathComponent("diagnostic-artifacts.json").path))
        #expect(FileManager.default.fileExists(atPath: archiveURL.appendingPathComponent("software-sample-catalog.json").path))
        #expect(FileManager.default.fileExists(atPath: archiveURL.appendingPathComponent("software-sample-catalog.csv").path))
        #expect(FileManager.default.fileExists(atPath: archiveURL.appendingPathComponent("software-sample-catalog-runbook.md").path))
        #expect(FileManager.default.fileExists(atPath: archiveURL.appendingPathComponent("software-sample-log-correlation.json").path))
        #expect(FileManager.default.fileExists(atPath: archiveURL.appendingPathComponent("software-sample-log-correlation.csv").path))
        #expect(FileManager.default.fileExists(atPath: archiveURL.appendingPathComponent("software-sample-log-correlation.md").path))
        #expect(FileManager.default.fileExists(atPath: archiveURL.appendingPathComponent("software-collection-lockfile.json").path))
        #expect(FileManager.default.fileExists(atPath: archiveURL.appendingPathComponent("software-collection-lockfile.csv").path))
        #expect(FileManager.default.fileExists(atPath: archiveURL.appendingPathComponent("software-collection-lockfile.md").path))
        #expect(FileManager.default.fileExists(atPath: archiveURL.appendingPathComponent("software-collection-acceptance.json").path))
        #expect(FileManager.default.fileExists(atPath: archiveURL.appendingPathComponent("software-collection-acceptance.csv").path))
        #expect(FileManager.default.fileExists(atPath: archiveURL.appendingPathComponent("software-collection-acceptance.md").path))
        #expect(FileManager.default.fileExists(atPath: archiveURL.appendingPathComponent("software-collection-acceptance-runbook.sh").path))

        let report = try JSONStore().load(TestSessionArchiveReport.self, from: archiveURL.appendingPathComponent("test-session.json"))
        #expect(report.status == TestSessionStatus.failed)
        #expect(report.totalAssetCount == 3)
        #expect(report.passedAssetCount == 1)
        #expect(report.failedAssetCount == 1)
        #expect(report.missingRequiredAssetCount == 1)
        #expect(report.executionPlanRequiredCount == 1)
        #expect(report.testRunCount == 2)
        #expect(report.diagnosticArtifactCount == 2)
        #expect(report.softwareSampleCount == softwareSamples.sampleCount)
        #expect(report.softwareSampleSignedRecipeCount == 1)
        #expect(report.softwareSampleLocalInstallerCount >= 3)
        #expect(report.softwareSampleCatalogPath?.hasSuffix("software-sample-catalog.json") == true)
        #expect(report.softwareSampleLogCorrelationPath?.hasSuffix("software-sample-log-correlation.json") == true)
        #expect(report.softwareSampleLogCorrelationCSVPath?.hasSuffix("software-sample-log-correlation.csv") == true)
        #expect(report.softwareSampleLogCorrelationMarkdownPath?.hasSuffix("software-sample-log-correlation.md") == true)
        #expect(report.softwareSampleMatchedCount == 1)
        #expect(report.softwareSampleFailedCount == 1)
        #expect(report.softwareSampleAttentionCount == 0)
        #expect(report.softwareSampleLaunchCount == 1)
        #expect(report.softwareSampleLogCount == 1)
        #expect(report.softwareCollectionLockfilePath?.hasSuffix("software-collection-lockfile.json") == true)
        #expect(report.softwareCollectionLockfileCSVPath?.hasSuffix("software-collection-lockfile.csv") == true)
        #expect(report.softwareCollectionLockfileMarkdownPath?.hasSuffix("software-collection-lockfile.md") == true)
        #expect(report.softwareCollectionAcceptancePath?.hasSuffix("software-collection-acceptance.json") == true)
        #expect(report.softwareCollectionAcceptanceCSVPath?.hasSuffix("software-collection-acceptance.csv") == true)
        #expect(report.softwareCollectionAcceptanceMarkdownPath?.hasSuffix("software-collection-acceptance.md") == true)
        #expect(report.softwareCollectionAcceptanceRunbookPath?.hasSuffix("software-collection-acceptance-runbook.sh") == true)
        #expect(report.softwareCollectionRecipeCount == 1)
        #expect(report.softwareCollectionMissingInstallerCount == 1)
        #expect(report.softwareCollectionHashProtectedCount == 1)
        #expect(report.softwareCollectionHashMismatchCount == 0)
        #expect(report.softwareCollectionUnprotectedDownloadCount == 0)
        #expect(report.softwareCollectionAcceptanceState == SoftwareCollectionAcceptanceState.blocked.rawValue)
        #expect(report.softwareCollectionAcceptanceActionCount == softwareCollectionAcceptance.actionCount)
        #expect(report.softwareCollectionAcceptanceBlockerCount == softwareCollectionAcceptance.blockerCount)
        #expect(report.softwareCollectionAcceptanceHighPriorityCount == softwareCollectionAcceptance.highPriorityCount)
        let graphicsSummary = report.categorySummaries.first { $0.category == DiagnosticCategory.graphics }
        let audioSummary = report.categorySummaries.first { $0.category == DiagnosticCategory.audio }
        #expect(graphicsSummary?.status == TestSessionStatus.failed)
        #expect(audioSummary?.status == TestSessionStatus.attention)
        #expect(report.issues.contains { $0.id == "log-d3d11-failed" && $0.severity == "high" })

        let csv = try String(contentsOf: archiveURL.appendingPathComponent("test-session.csv"), encoding: .utf8)
        #expect(csv.contains("summary,status,failed"))
        #expect(csv.contains("summary,software-samples"))
        #expect(csv.contains("summary,software-sample-log-correlation"))
        #expect(csv.contains("matched=1;failed=1;attention=0;launches=1;logs=1"))
        #expect(csv.contains("summary,software-collection-lockfile"))
        #expect(csv.contains("recipes=1;missingInstallers=1;hashProtected=1;hashMismatches=0;unprotectedDownloads=0"))
        #expect(csv.contains("summary,software-collection-acceptance,blocked"))
        #expect(csv.contains("category,graphics,failed"))
        #expect(csv.contains("issue,log-d3d11-failed"))

        let markdown = try String(contentsOf: archiveURL.appendingPathComponent("test-session.md"), encoding: .utf8)
        #expect(markdown.contains("# MacWin Test Session"))
        #expect(markdown.contains("Status: `failed`"))
        #expect(markdown.contains("Software samples:"))
        #expect(markdown.contains("Software sample log correlation: 1 matched samples, 1 launches, 1 logs"))
        #expect(markdown.contains("Software collection lockfile: 1 recipes, 1 missing installers, 0 hash mismatches"))
        #expect(markdown.contains("Software collection acceptance: blocked"))
        #expect(markdown.contains("D3D11 probe failed"))

        let samplesMarkdown = try String(contentsOf: archiveURL.appendingPathComponent("software-sample-catalog-runbook.md"), encoding: .utf8)
        #expect(samplesMarkdown.contains("## Steam"))
        #expect(samplesMarkdown.contains("## itch.io"))
        let sampleCorrelation = try JSONStore().load(
            SoftwareSampleLogCorrelationReport.self,
            from: archiveURL.appendingPathComponent("software-sample-log-correlation.json")
        )
        #expect(sampleCorrelation.entries.first?.sampleId == "steam")
        #expect(sampleCorrelation.entries.first?.launchRecordIds == ["steam-launch"])
        let sampleCorrelationCSV = try String(contentsOf: archiveURL.appendingPathComponent("software-sample-log-correlation.csv"), encoding: .utf8)
        #expect(sampleCorrelationCSV.contains("sample_id,name,install_source,catalog_backed,launch_count,log_count"))
        #expect(sampleCorrelationCSV.contains("steam,Steam,signedRecipe,true,1,1,1,0"))
        let sampleCorrelationMarkdown = try String(contentsOf: archiveURL.appendingPathComponent("software-sample-log-correlation.md"), encoding: .utf8)
        #expect(sampleCorrelationMarkdown.contains("# MacWin Software Sample Log Correlation"))
        #expect(sampleCorrelationMarkdown.contains("### Steam"))
        #expect(sampleCorrelationMarkdown.contains("Launch records: `steam-launch`"))
        #expect(sampleCorrelationMarkdown.contains("Recommended probes: `d3d11`"))
        let lockfile = try JSONStore().load(
            SoftwareCollectionLockfile.self,
            from: archiveURL.appendingPathComponent("software-collection-lockfile.json")
        )
        #expect(lockfile.recipeCount == 1)
        #expect(lockfile.items.first?.recipeId == "steam")
        #expect(lockfile.items.first?.expectedSha256 == String(repeating: "a", count: 64))
        let lockfileCSV = try String(contentsOf: archiveURL.appendingPathComponent("software-collection-lockfile.csv"), encoding: .utf8)
        #expect(lockfileCSV.contains("steam,Steam,Valve,Game Store,game-launchers,download,SteamSetup.exe"))
        let lockfileMarkdown = try String(contentsOf: archiveURL.appendingPathComponent("software-collection-lockfile.md"), encoding: .utf8)
        #expect(lockfileMarkdown.contains("# MacWin Software Collection Lockfile"))
        #expect(lockfileMarkdown.contains("### Steam"))
        let acceptance = try JSONStore().load(
            SoftwareCollectionAcceptanceReport.self,
            from: archiveURL.appendingPathComponent("software-collection-acceptance.json")
        )
        #expect(acceptance.actionCount >= 2)
        #expect(acceptance.actions.contains { $0.kind == SoftwareCollectionAcceptanceActionKind.downloadInstaller && $0.recipeId == "steam" })
        let acceptanceCSV = try String(contentsOf: archiveURL.appendingPathComponent("software-collection-acceptance.csv"), encoding: .utf8)
        #expect(acceptanceCSV.contains("downloadInstaller"))
        let acceptanceMarkdown = try String(contentsOf: archiveURL.appendingPathComponent("software-collection-acceptance.md"), encoding: .utf8)
        #expect(acceptanceMarkdown.contains("# MacWin Collection Acceptance"))
        let acceptanceRunbook = try String(contentsOf: archiveURL.appendingPathComponent("software-collection-acceptance-runbook.sh"), encoding: .utf8)
        #expect(acceptanceRunbook.contains("download_one 'steam'"))
        let runbookAttributes = try FileManager.default.attributesOfItem(atPath: archiveURL.appendingPathComponent("software-collection-acceptance-runbook.sh").path)
        #expect((runbookAttributes[FileAttributeKey.posixPermissions] as? Int).map { $0 & 0o111 != 0 } == true)
    }

    @Test("Test session status is attention for unverified but non-failing coverage")
    func sessionStatusTracksAttentionState() {
        let coverage = TestCoverageReport(categories: [
            TestCoverageCategoryReport(
                category: .core,
                assets: [
                    TestAssetStatus(
                        id: "console",
                        name: "Console Probe",
                        kind: .executable,
                        category: .core,
                        architecture: .x86_64,
                        path: "/tmp/console.exe",
                        required: true,
                        exists: true
                    )
                ],
                latestRunsByAssetId: [:]
            )
        ])
        let logIssues = LogIssueReport(logs: [], topIssues: [], recentFailures: [])

        #expect(TestSessionArchiveReport.status(coverage: coverage, executionPlan: nil, logIssues: logIssues) == .attention)
    }
}
