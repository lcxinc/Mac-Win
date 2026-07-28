import Foundation
import Testing
@testable import MacWinCore

@Suite("Software adaptation queue service")
struct SoftwareAdaptationQueueServiceTests {
    @Test("Queue turns software plan issues into runnable probe tasks")
    func queueTurnsSoftwarePlanIssuesIntoRunnableProbeTasks() throws {
        let logPath = "/tmp/MacWin/HYP.log"
        let entry = SoftwareTestPlanEntry(
            recipeId: "hoyoplay-cn",
            name: "HoYoPlay",
            publisher: "miHoYo",
            category: "Game Launcher",
            compatibilityRating: .experimental,
            state: .needsReview,
            priority: 23,
            summary: "state=needsReview issues=text-rendering",
            recommendedAction: "Review HYP.log and compare with probe results.",
            readinessState: .ready,
            readinessIssues: [],
            installerMode: .alreadyInstalled,
            installerHashStatus: nil,
            cachedInstallerPath: nil,
            requiresWin32: false,
            latestInstallState: nil,
            latestInstallAt: nil,
            latestInstallLogPath: nil,
            installedLauncherCount: 1,
            installedLauncherIds: ["hoyoplay"],
            latestLaunchState: .completed,
            latestLaunchAt: Date(timeIntervalSince1970: 1_780_000_000),
            latestLaunchLogPath: logPath,
            latestLaunchExitCode: 0,
            latestLogHealth: .attention,
            latestLogHints: [.fontRenderingIssue],
            probableIssueIds: ["text-rendering"],
            blockers: ["text-rendering"]
        )
        let plan = SoftwareTestPlanReport(rootPath: "/tmp/MacWin", entries: [entry])
        let row = SoftwareSmokeMatrixRow(
            recipeId: "hoyoplay-cn",
            name: "HoYoPlay",
            category: "Game Launcher",
            compatibilityRating: .experimental,
            stage: .logReview,
            state: .needsReview,
            highestSeverity: .warning,
            checklist: [
                SoftwareSmokeChecklistItem(id: "log", label: "Log health", state: .warning, detail: "Latest log needs review: text-rendering.")
            ],
            blockerCount: 0,
            warningCount: 1,
            nextAction: "Review HYP.log and compare with probe results.",
            latestLogPath: logPath,
            latestLaunchLogPath: logPath,
            latestRepairState: nil
        )
        let matrix = SoftwareSmokeMatrixReport(rootPath: "/tmp/MacWin", rows: [row])
        let issueReport = LogIssueReport(
            logs: [],
            topIssues: [
                LogIssueTrend(
                    id: "text-rendering",
                    severity: "high",
                    title: "Text rendering",
                    detail: "Text is missing",
                    count: 1,
                    relatedHints: ["fontRenderingIssue"],
                    affectedLogNames: ["HYP.log"],
                    recommendedActions: ["Run text rendering probe"],
                    probeAssetIds: ["text-rendering"]
                )
            ],
            recentFailures: [
                LogIssueSample(
                    name: "HYP.log",
                    path: logPath,
                    modifiedAt: Date(timeIntervalSince1970: 1_780_000_010),
                    health: LogHealth.attention.rawValue,
                    errorCount: 0,
                    warningCount: 1,
                    fixmeCount: 0,
                    passCount: 0,
                    failCount: 0,
                    hints: ["fontRenderingIssue"],
                    probableIssueIds: ["text-rendering"],
                    probeAssetIds: ["text-rendering"]
                )
            ]
        )
        let runbook = TestAssetRunbook(
            rootPath: "/tmp/exe-tests",
            canRunSuite: false,
            missingRequiredAssetIds: [],
            buildCommand: nil,
            suiteCommand: nil,
            groups: [
                TestAssetRunGroup(category: .core, assetIds: ["console", "text-rendering"], commands: [
                    TestAssetRunCommand(
                        assetId: "console",
                        name: "Console",
                        architecture: .x86_64,
                        executablePath: "/tmp/exe-tests/bin/00_console_probe.exe",
                        exists: true,
                        command: ["/tmp/exe-tests/run-one.sh", "00_console_probe"],
                        note: nil
                    ),
                    TestAssetRunCommand(
                        assetId: "text-rendering",
                        name: "Text",
                        architecture: .x86_64,
                        executablePath: "/tmp/exe-tests/bin/70_text_rendering_probe.exe",
                        exists: true,
                        command: ["/tmp/exe-tests/run-one.sh", "70_text_rendering_probe"],
                        note: nil
                    )
                ])
            ]
        )
        let assets = TestAssetReport(rootPath: "/tmp/exe-tests", statuses: [], runbook: runbook)

        let report = SoftwareAdaptationQueueService.report(
            rootPath: "/tmp/MacWin",
            softwareTestPlan: plan,
            softwareSmokeMatrix: matrix,
            logIssues: issueReport,
            testAssets: assets,
            generatedAt: Date(timeIntervalSince1970: 1_780_000_020)
        )

        #expect(report.taskCount == 1)
        #expect(report.runnableTaskCount == 1)
        #expect(report.runnableProbeCount == 2)
        #expect(report.unavailableProbeCount == 0)
        let task = try #require(report.tasks.first)
        #expect(task.recipeId == "hoyoplay-cn")
        #expect(task.stage == .logReview)
        #expect(task.severity == .warning)
        #expect(task.probableIssueIds == ["text-rendering"])
        #expect(task.recommendedProbeIds == ["text-rendering", "console"])
        #expect(task.probes.map(\.assetId) == ["text-rendering", "console"])
        #expect(task.probes.allSatisfy { $0.state == .runnable })
        #expect(task.probes.first?.command == ["/tmp/exe-tests/run-one.sh", "70_text_rendering_probe"])

        let csv = SoftwareAdaptationQueueService.csv(report: report)
        #expect(csv.contains("recipe_id,name,category,compatibility_rating,state,stage,severity,priority,next_action"))
        #expect(csv.contains("hoyoplay-cn,HoYoPlay,Game Launcher,experimental,needsReview,logReview,warning,23"))
        #expect(csv.contains("text-rendering;console"))

        let markdown = SoftwareAdaptationQueueService.markdown(report: report)
        #expect(markdown.contains("# MacWin Software Adaptation Queue"))
        #expect(markdown.contains("- Tasks: 1"))
        #expect(markdown.contains("### HoYoPlay"))
        #expect(markdown.contains("- Recipe: `hoyoplay-cn`"))
        #expect(markdown.contains("- Probable issues: `text-rendering`"))
        #expect(markdown.contains("- Recommended probes: `text-rendering`, `console`"))
        #expect(markdown.contains("`text-rendering` runnable: `/tmp/exe-tests/run-one.sh 70_text_rendering_probe`"))

        let script = SoftwareAdaptationQueueService.shellScript(report: report)
        #expect(script.contains("usage: $0 [list|run|hoyoplay-cn]"))
        #expect(script.contains("== hoyoplay-cn: text-rendering =="))
        #expect(script.contains("'/tmp/exe-tests/run-one.sh' '70_text_rendering_probe'"))
        #expect(script.contains("== hoyoplay-cn: console =="))
    }
}
