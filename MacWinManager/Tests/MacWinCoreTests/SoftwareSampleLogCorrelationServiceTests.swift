import Foundation
import Testing
@testable import MacWinCore

@Suite("Software sample log correlation service")
struct SoftwareSampleLogCorrelationServiceTests {
    @Test("Correlates real software samples with launch records and logs")
    func correlatesSamplesWithLaunchesAndLogs() {
        let generatedAt = Date(timeIntervalSince1970: 1_000)
        let catalog = SoftwareSampleCatalogReport(
            generatedAt: generatedAt,
            rootPath: "/tmp/MacWin",
            samples: [
                SoftwareSampleProfile(
                    id: "steam",
                    name: "Steam",
                    publisher: "Valve",
                    category: "Game Store",
                    purpose: "Game launcher",
                    installSource: .localInstaller,
                    launcherCandidates: ["C:\\Program Files\\Steam\\Steam.exe"],
                    recommendedProbeIds: ["d3d11", "xaudio2"]
                ),
                SoftwareSampleProfile(
                    id: "hoyoplay-cn",
                    name: "HoYoPlay",
                    publisher: "miHoYo",
                    category: "Game Launcher",
                    purpose: "Game launcher",
                    installSource: .localInstaller,
                    launcherCandidates: ["C:\\Program Files\\miHoYo Launcher\\HYP.exe"],
                    recommendedProbeIds: ["text-rendering"]
                ),
                SoftwareSampleProfile(
                    id: "lenovo-app-store",
                    name: "Lenovo App Store",
                    publisher: "Lenovo",
                    category: "Software Store",
                    purpose: "Software market",
                    installSource: .localInstaller,
                    launcherCandidates: ["C:\\Program Files\\Lenovo\\LeASLane.exe"],
                    recommendedProbeIds: ["window-input"]
                ),
                SoftwareSampleProfile(
                    id: "itch",
                    name: "itch.io",
                    publisher: "itch.io",
                    category: "Game Store",
                    purpose: "Game marketplace",
                    installSource: .signedRecipe,
                    catalogBacked: true
                )
            ]
        )

        let steamLog = CapabilityLogEntry(
            name: "steam.log",
            path: "/tmp/MacWin/Logs/steam.log",
            modifiedAt: Date(timeIntervalSince1970: 1_100),
            byteCount: 64,
            health: LogHealth.passed.rawValue,
            errorCount: 0,
            warningCount: 0,
            fixmeCount: 0,
            passCount: 1,
            failCount: 0,
            hints: ["passObserved"],
            launchContext: nil
        )
        let hoyoplayLog = CapabilityLogEntry(
            name: "hoyoplay-crash.log",
            path: "/tmp/MacWin/Logs/hoyoplay-crash.log",
            modifiedAt: Date(timeIntervalSince1970: 1_200),
            byteCount: 128,
            health: LogHealth.failed.rawValue,
            errorCount: 2,
            warningCount: 0,
            fixmeCount: 0,
            passCount: 0,
            failCount: 1,
            hints: ["textRenderingIssue"],
            launchContext: nil
        )
        let lenovoLog = CapabilityLogEntry(
            name: "lenovo-black-screen.log",
            path: "/tmp/MacWin/Logs/lenovo-black-screen.log",
            modifiedAt: Date(timeIntervalSince1970: 1_150),
            byteCount: 96,
            health: LogHealth.attention.rawValue,
            errorCount: 0,
            warningCount: 1,
            fixmeCount: 0,
            passCount: 0,
            failCount: 0,
            hints: ["blankWindowIssue"],
            launchContext: nil
        )
        let issueReport = LogIssueReport(
            logs: [],
            topIssues: [],
            recentFailures: [
                LogIssueSample(
                    name: hoyoplayLog.name,
                    path: hoyoplayLog.path,
                    modifiedAt: hoyoplayLog.modifiedAt,
                    health: hoyoplayLog.health,
                    errorCount: hoyoplayLog.errorCount,
                    warningCount: hoyoplayLog.warningCount,
                    fixmeCount: hoyoplayLog.fixmeCount,
                    passCount: hoyoplayLog.passCount,
                    failCount: hoyoplayLog.failCount,
                    hints: hoyoplayLog.hints,
                    probableIssueIds: ["text-rendering"],
                    probeAssetIds: ["text-rendering"]
                )
            ]
        )
        let logs = CapabilityLogReport(
            directory: "/tmp/MacWin/Logs",
            recentLogCount: 3,
            healthCounts: [
                LogHealth.passed.rawValue: 1,
                LogHealth.failed.rawValue: 1,
                LogHealth.attention.rawValue: 1
            ],
            hintCounts: [:],
            issueReport: issueReport,
            recommendations: [],
            entries: [steamLog, hoyoplayLog, lenovoLog]
        )
        let launchHistory = LaunchHistoryReport(
            rootPath: "/tmp/MacWin",
            logsPath: "/tmp/MacWin/Logs",
            recordsPath: "/tmp/MacWin/Logs/LaunchRecords",
            totalLaunchCount: 3,
            completedCount: 3,
            detachedCount: 3,
            failedToLaunchCount: 0,
            stateCounts: [WineLaunchState.completed.rawValue: 3],
            latestStartedAt: Date(timeIntervalSince1970: 1_300),
            records: [
                launchRecord(id: "steam-launch", exe: "C:\\Program Files\\Steam\\Steam.exe", logPath: steamLog.path),
                launchRecord(id: "hoyoplay-launch", exe: "C:\\Program Files\\miHoYo Launcher\\HYP.exe", logPath: hoyoplayLog.path),
                launchRecord(id: "lenovo-launch", exe: "C:\\Program Files\\Lenovo\\LeASLane.exe", logPath: lenovoLog.path)
            ]
        )

        let report = SoftwareSampleLogCorrelationService.report(
            rootPath: "/tmp/MacWin",
            sampleCatalog: catalog,
            logs: logs,
            launchHistory: launchHistory,
            generatedAt: generatedAt
        )

        #expect(report.sampleCount == 4)
        #expect(report.matchedSampleCount == 3)
        #expect(report.launchMatchedSampleCount == 3)
        #expect(report.logMatchedSampleCount == 3)
        #expect(report.failedSampleCount == 1)
        #expect(report.attentionSampleCount == 1)
        #expect(report.launchCount == 3)
        #expect(report.logCount == 3)
        let steam = report.entries.first { $0.sampleId == "steam" }
        #expect(steam?.launchRecordIds == ["steam-launch"])
        #expect(steam?.logNames == ["steam.log"])
        #expect(steam?.recommendedProbeIds == ["d3d11", "xaudio2"])
        let hoyoplay = report.entries.first { $0.sampleId == "hoyoplay-cn" }
        #expect(hoyoplay?.failedLogCount == 1)
        #expect(hoyoplay?.probableIssueIds == ["text-rendering"])
        #expect(hoyoplay?.recommendedProbeIds == ["text-rendering"])
        let lenovo = report.entries.first { $0.sampleId == "lenovo-app-store" }
        #expect(lenovo?.attentionLogCount == 1)
        #expect(report.entries.first { $0.sampleId == "itch" }?.launchCount == 0)

        let csv = SoftwareSampleLogCorrelationService.csv(report: report)
        #expect(csv.contains("sample_id,name,install_source,catalog_backed,launch_count,log_count"))
        #expect(csv.contains("hoyoplay-cn,HoYoPlay,localInstaller,false,1,1,1,0"))
        #expect(csv.contains("lenovo-app-store,Lenovo App Store,localInstaller,false,1,1,0,1"))

        let markdown = SoftwareSampleLogCorrelationService.markdown(report: report)
        #expect(markdown.contains("# MacWin Software Sample Log Correlation"))
        #expect(markdown.contains("### HoYoPlay"))
        #expect(markdown.contains("Launch records: `hoyoplay-launch`"))
        #expect(markdown.contains("Probable issues: `text-rendering`"))
        #expect(markdown.contains("Recommended probes: `text-rendering`"))
        #expect(markdown.contains("## Unmatched Samples"))
        #expect(markdown.contains("itch.io (`itch`)"))
    }

    private func launchRecord(id: String, exe: String, logPath: String) -> WineLaunchRecord {
        WineLaunchRecord(
            id: id,
            mode: .detached,
            state: .completed,
            logPath: logPath,
            startedAt: Date(timeIntervalSince1970: 1_050),
            endedAt: Date(timeIntervalSince1970: 1_055),
            durationMilliseconds: 5_000,
            processIdentifier: 100,
            exitCode: 0,
            bottleId: "game",
            bottleName: "Game",
            engineId: "wine",
            winePath: "/tmp/wine",
            exe: exe,
            args: [],
            commandLine: ["/usr/bin/arch", "-x86_64", "/tmp/wine", exe],
            workingDirectory: "/tmp/MacWin/Bottles/game/drive_c",
            environment: [:]
        )
    }
}
