import Foundation
import Testing
@testable import MacWinCore

@Suite("Software smoke matrix service")
struct SoftwareSmokeMatrixServiceTests {
    @Test("Smoke matrix turns test plan and repair audit into staged checklist rows")
    func smokeMatrixBuildsChecklistRows() {
        let root = "/tmp/MacWinSmokeMatrix"
        let launchLog = "\(root)/Logs/hoyoplay.log"
        let entries = [
            entry(
                recipeId: "notepad",
                name: "Notepad++",
                state: .verified,
                installerHashStatus: .match,
                cachedInstallerPath: "\(root)/Downloads/notepad.exe",
                latestInstallState: .succeeded,
                installedLauncherCount: 1,
                latestLaunchState: .completed,
                latestLaunchLogPath: "\(root)/Logs/notepad.log",
                latestLaunchExitCode: 0,
                latestLogHealth: .passed
            ),
            entry(
                recipeId: "hoyoplay-cn",
                name: "HoYoPlay",
                state: .needsReview,
                installerMode: .alreadyInstalled,
                installedLauncherCount: 1,
                latestLaunchState: .completed,
                latestLaunchLogPath: launchLog,
                latestLaunchExitCode: 0,
                latestLogHealth: .attention,
                probableIssueIds: ["text-rendering"]
            ),
            entry(
                recipeId: "steam",
                name: "Steam",
                state: .hashMismatch,
                installerHashStatus: .mismatch,
                cachedInstallerPath: "\(root)/Downloads/SteamSetup.exe"
            ),
            entry(
                recipeId: "local-tool",
                name: "Local Tool",
                state: .installerLaunched,
                installerMode: .localFile,
                latestInstallState: .launched
            )
        ]
        let testPlan = SoftwareTestPlanReport(rootPath: root, entries: entries)
        let repairAudit = CompatibilityRepairAuditReport(
            totalLaunchCount: 1,
            auditedLaunchCount: 1,
            readyLaunchCount: 0,
            missingRepairLaunchCount: 1,
            staleFlagLaunchCount: 0,
            entries: [
                CompatibilityRepairAuditEntry(
                    launchRecordId: "hoyoplay-launch",
                    logPath: launchLog,
                    startedAt: Date(timeIntervalSince1970: 100),
                    bottleId: "bottle",
                    bottleName: "Bottle",
                    exe: "C:\\Program Files\\miHoYo Launcher\\HYP.exe",
                    profile: ApplicationCompatibilityProfile.hoYoPlay.rawValue,
                    state: .missingRepairs,
                    requiredRepairKeys: ["MACWIN_TEXT_RENDERING_REPAIR"],
                    presentRepairKeys: [],
                    missingRepairKeys: ["MACWIN_TEXT_RENDERING_REPAIR"],
                    staleRenderingFlags: []
                )
            ],
            findings: []
        )

        let report = SoftwareSmokeMatrixService.report(
            rootPath: root,
            softwareTestPlan: testPlan,
            compatibilityRepairAudit: repairAudit,
            signedCatalogLoaded: true
        )

        #expect(report.recipeCount == 4)
        #expect(report.verifiedCount == 1)
        #expect(report.failedCount == 1)
        #expect(report.warningCount == 1)
        #expect(report.checkCounts["passed"] != nil)
        #expect(report.stageCounts["verified"] == 1)
        #expect(report.stageCounts["installer"] == 1)
        #expect(report.stageCounts["compatibilityRepair"] == 1)
        #expect(report.nextActions.first?.recipeId == "steam")

        let notepad = try! #require(report.rows.first { $0.recipeId == "notepad" })
        #expect(notepad.stage == .verified)
        #expect(notepad.highestSeverity == .passed)
        #expect(notepad.checklist.first { $0.id == "log" }?.state == .passed)

        let hoyoplay = try! #require(report.rows.first { $0.recipeId == "hoyoplay-cn" })
        #expect(hoyoplay.stage == .compatibilityRepair)
        #expect(hoyoplay.latestRepairState == .missingRepairs)
        #expect(hoyoplay.checklist.first { $0.id == "log" }?.state == .warning)
        #expect(hoyoplay.checklist.first { $0.id == "repair" }?.state == .warning)

        let steam = try! #require(report.rows.first { $0.recipeId == "steam" })
        #expect(steam.stage == .installer)
        #expect(steam.highestSeverity == .failed)
        #expect(steam.checklist.first { $0.id == "installer" }?.state == .failed)

        let localTool = try! #require(report.rows.first { $0.recipeId == "local-tool" })
        #expect(localTool.stage == .install)
        #expect(localTool.highestSeverity == .pending)
        #expect(localTool.checklist.first { $0.id == "install" }?.state == .pending)
        #expect(localTool.checklist.first { $0.id == "install" }?.detail.contains("Interactive installer was launched") == true)

        let csv = SoftwareSmokeMatrixService.csv(report: report)
        #expect(csv.contains("recipe_id,name,category,compatibility_rating,stage,state,highest_severity"))
        #expect(csv.contains("catalog_state,installer_state,install_state,launcher_state,launch_state,log_state,repair_state"))
        #expect(csv.contains("steam,Steam,Utilities,good,installer,hashMismatch,failed"))
        #expect(csv.contains("Latest log needs review: text-rendering."))
    }

    @Test("Smoke matrix treats managed SIGTERM launch as passed without requiring log triage")
    func smokeMatrixTreatsVerifiedManagedSIGTERMLaunchAsPassed() throws {
        let root = "/tmp/MacWinSmokeMatrixSIGTERM"
        let testPlan = SoftwareTestPlanReport(
            rootPath: root,
            entries: [
                entry(
                    recipeId: "portableapps-platform",
                    name: "PortableApps.com Platform",
                    state: .verified,
                    installerMode: .localFile,
                    latestInstallState: .succeeded,
                    installedLauncherCount: 1,
                    latestLaunchState: .completed,
                    latestLaunchLogPath: "\(root)/Logs/high-performance-win11-portableapps-platform-cli-smoke.log",
                    latestLaunchExitCode: 15,
                    latestLogHealth: nil
                )
            ]
        )

        let report = SoftwareSmokeMatrixService.report(
            rootPath: root,
            softwareTestPlan: testPlan,
            compatibilityRepairAudit: CompatibilityRepairAuditReport(
                totalLaunchCount: 0,
                auditedLaunchCount: 0,
                readyLaunchCount: 0,
                missingRepairLaunchCount: 0,
                staleFlagLaunchCount: 0,
                entries: [],
                findings: []
            ),
            signedCatalogLoaded: true
        )

        let row = try #require(report.rows.first)
        #expect(row.stage == .verified)
        #expect(row.highestSeverity == .pending)
        #expect(row.checklist.first { $0.id == "launch" }?.state == .passed)
        #expect(row.checklist.first { $0.id == "launch" }?.detail.contains("controlled exit code 15") == true)
    }

    private func entry(
        recipeId: String,
        name: String,
        state: SoftwareTestPlanState,
        installerMode: InstallerMode = .download,
        installerHashStatus: InstallerHashStatus? = nil,
        cachedInstallerPath: String? = nil,
        latestInstallState: InstallTaskState? = nil,
        installedLauncherCount: Int = 0,
        latestLaunchState: WineLaunchState? = nil,
        latestLaunchLogPath: String? = nil,
        latestLaunchExitCode: Int32? = nil,
        latestLogHealth: LogHealth? = nil,
        probableIssueIds: [String] = []
    ) -> SoftwareTestPlanEntry {
        SoftwareTestPlanEntry(
            recipeId: recipeId,
            name: name,
            publisher: "Publisher",
            category: "Utilities",
            compatibilityRating: .good,
            state: state,
            priority: 10,
            summary: "state=\(state.rawValue)",
            recommendedAction: "Run next action",
            readinessState: .ready,
            readinessIssues: [],
            installerMode: installerMode,
            installerHashStatus: installerHashStatus,
            cachedInstallerPath: cachedInstallerPath,
            requiresWin32: false,
            latestInstallState: latestInstallState,
            latestInstallAt: latestInstallState == nil ? nil : Date(timeIntervalSince1970: 10),
            latestInstallLogPath: latestInstallState == nil ? nil : "/tmp/install.log",
            installedLauncherCount: installedLauncherCount,
            installedLauncherIds: installedLauncherCount > 0 ? [recipeId] : [],
            latestLaunchState: latestLaunchState,
            latestLaunchAt: latestLaunchState == nil ? nil : Date(timeIntervalSince1970: 20),
            latestLaunchLogPath: latestLaunchLogPath,
            latestLaunchExitCode: latestLaunchExitCode,
            latestLogHealth: latestLogHealth,
            latestLogHints: [],
            probableIssueIds: probableIssueIds,
            blockers: []
        )
    }
}
