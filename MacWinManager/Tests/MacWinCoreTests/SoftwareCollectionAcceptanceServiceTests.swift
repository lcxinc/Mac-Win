import Foundation
import Testing
@testable import MacWinCore

@Suite("Software collection acceptance service")
struct SoftwareCollectionAcceptanceServiceTests {
    @Test("Acceptance report combines missing installers probes smoke and logs")
    func acceptanceReportCombinesSignals() {
        let root = "/tmp/MacWinAcceptance"
        let collection = SoftwareCollectionReport(
            generatedAt: Date(timeIntervalSince1970: 100),
            rootPath: root,
            collections: [
                SoftwareCollectionDefinition(id: "baseline", name: "Baseline", purpose: "Smoke", requiredRecipeIds: ["steam"])
            ],
            missingRecipeIds: ["missing-tool"],
            entries: [
                SoftwareCollectionEntry(
                    recipeId: "steam",
                    name: "Steam",
                    publisher: "Valve",
                    category: "Game Launcher",
                    collectionIds: ["baseline"],
                    compatibilityRating: .limited,
                    installerMode: .download,
                    installerFileName: "SteamSetup.exe",
                    installerSourceURL: "https://example.test/SteamSetup.exe",
                    expectedSha256: String(repeating: "b", count: 64),
                    installerHashStatus: .missing,
                    cachedInstallerPath: "\(root)/Downloads/SteamSetup.exe",
                    cachedInstallerExists: false,
                    softwareState: .missingInstaller,
                    smokeStage: .installer,
                    smokeSeverity: .blocked,
                    installedLauncherCount: 0,
                    latestLaunchState: nil,
                    latestLaunchLogPath: nil,
                    latestLogHealth: nil,
                    readinessIssues: [],
                    recommendedProbeIds: ["window-input"]
                )
            ]
        )
        let smoke = SoftwareSmokeMatrixReport(
            rootPath: root,
            rows: [
                SoftwareSmokeMatrixRow(
                    recipeId: "steam",
                    name: "Steam",
                    category: "Game Launcher",
                    compatibilityRating: .limited,
                    stage: .installer,
                    state: .missingInstaller,
                    highestSeverity: .blocked,
                    checklist: [
                        SoftwareSmokeChecklistItem(
                            id: "installer",
                            label: "Installer cache",
                            state: .blocked,
                            detail: "Installer still needs to be downloaded."
                        )
                    ],
                    blockerCount: 1,
                    warningCount: 0,
                    nextAction: "Download Steam installer",
                    latestLogPath: nil,
                    latestLaunchLogPath: nil,
                    latestRepairState: nil
                )
            ]
        )
        let testPlan = TestExecutionPlan(
            generatedAt: Date(timeIntervalSince1970: 100),
            rootPath: root,
            items: [
                TestExecutionPlanItem(
                    id: "probe-1",
                    assetId: "20_vulkan_probe",
                    name: "Vulkan Probe",
                    category: .graphics,
                    architecture: .x86_64,
                    priority: .high,
                    reasons: [.neverRun],
                    executablePath: "\(root)/exe-tests/20_vulkan_probe.exe",
                    exists: true,
                    command: ["refs/exe-tests/run-one.sh", "20_vulkan_probe"]
                )
            ]
        )
        let logIssues = LogIssueReport(
            logs: [
                LogFileItem(
                    name: "steam.log",
                    url: URL(fileURLWithPath: "\(root)/Logs/steam.log"),
                    modifiedAt: Date(timeIntervalSince1970: 100),
                    byteCount: 12,
                    summary: LogSummary(errorCount: 1, hints: [.cefRenderingIssue])
                )
            ],
            topIssues: [
                LogIssueTrend(
                    id: "cef-rendering",
                    severity: "high",
                    title: "CEF rendering issue",
                    detail: "WebView was blank.",
                    count: 1,
                    relatedHints: ["cefRenderingIssue"],
                    affectedLogNames: ["steam.log"]
                )
            ],
            recentFailures: []
        )

        let report = SoftwareCollectionAcceptanceService().report(
            collection: collection,
            smokeMatrix: smoke,
            testExecutionPlan: testPlan,
            logIssues: logIssues,
            generatedAt: Date(timeIntervalSince1970: 200)
        )

        #expect(report.state == .blocked)
        #expect(report.missingRecipeCount == 1)
        #expect(report.missingInstallerCount == 1)
        #expect(report.smokeBlockedCount == 1)
        #expect(report.probeActionCount == 1)
        #expect(report.failedLogCount == 1)
        #expect(report.actionCount == 5)
        #expect(report.actions.first?.kind == .addMissingRecipe)
        #expect(report.actions.contains { $0.kind == .downloadInstaller && $0.recipeId == "steam" })
        #expect(report.actions.contains { $0.kind == .runProbe && $0.assetId == "20_vulkan_probe" })
        #expect(report.actions.contains { $0.kind == .reviewLogIssue && $0.logIssueId == "cef-rendering" })

        let csv = SoftwareCollectionAcceptanceReport.csv(report: report)
        #expect(csv.contains("severity,kind,title,detail,recipe_id,asset_id,log_issue_id,command,related_path,source_url,file_name,expected_sha256"))
        #expect(csv.contains("downloadInstaller"))
        #expect(csv.contains("20_vulkan_probe"))
        #expect(csv.contains("https://example.test/SteamSetup.exe"))

        let markdown = SoftwareCollectionAcceptanceReport.markdown(report: report)
        #expect(markdown.contains("# MacWin Collection Acceptance"))
        #expect(markdown.contains("State: `blocked`"))
        #expect(markdown.contains("Run probe Vulkan Probe"))
        #expect(markdown.contains("Source: `https://example.test/SteamSetup.exe`"))

        let runbook = SoftwareCollectionAcceptanceReport.runbookScript(report: report)
        #expect(runbook.contains("#!/usr/bin/env bash"))
        #expect(runbook.contains("download_one 'steam' 'https://example.test/SteamSetup.exe' 'SteamSetup.exe'"))
        #expect(runbook.contains("run_probe 'refs/exe-tests/run-one.sh' '20_vulkan_probe'"))
        #expect(runbook.contains("note 'Review log issue CEF rendering issue'"))
    }
}
