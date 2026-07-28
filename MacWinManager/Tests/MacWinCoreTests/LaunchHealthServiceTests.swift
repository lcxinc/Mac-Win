import Foundation
import Testing
@testable import MacWinCore

@Suite("Launch health service")
struct LaunchHealthServiceTests {
    @Test("Newer successful smoke removes orphaned legacy debug log")
    func newerSuccessfulSmokeRemovesOrphanedLegacyDebugLog() {
        let logPath = "/tmp/MacWin/Logs/qgroundcontrol-map-winedebug.log"
        let logs = CapabilityLogReport(
            directory: "/tmp/MacWin/Logs",
            recentLogCount: 1,
            healthCounts: [LogHealth.failed.rawValue: 1],
            hintCounts: [:],
            issueReport: LogIssueReport(
                logs: [],
                topIssues: [],
                recentFailures: [
                    LogIssueSample(
                        name: "qgroundcontrol-map-winedebug.log",
                        path: logPath,
                        modifiedAt: Date(timeIntervalSince1970: 1_784_897_862),
                        health: LogHealth.failed.rawValue,
                        errorCount: 1,
                        warningCount: 0,
                        fixmeCount: 0,
                        passCount: 0,
                        failCount: 1,
                        hints: [],
                        probableIssueIds: ["unclassified-failure"],
                        probeAssetIds: ["console"]
                    )
                ]
            ),
            recommendations: [],
            entries: [
                CapabilityLogEntry(
                    name: "qgroundcontrol-map-winedebug.log",
                    path: logPath,
                    modifiedAt: Date(timeIntervalSince1970: 1_784_897_862),
                    byteCount: 100,
                    health: LogHealth.failed.rawValue,
                    errorCount: 1,
                    warningCount: 0,
                    fixmeCount: 0,
                    passCount: 0,
                    failCount: 1,
                    hints: []
                )
            ]
        )
        let smokeReport = SoftwareSmokeRunReport(
            generatedAt: "2026-07-24T13:33:35.469851Z",
            runId: "qgc-network-auto-repair",
            suite: "single",
            sample: "qgroundcontrol-drone",
            prefix: "/tmp/prefix",
            logDirectory: "/tmp/logs/qgc-network-auto-repair",
            recordCount: 1,
            stateCounts: ["launched": 1],
            records: [
                SoftwareSmokeRunRecord(
                    id: "qgroundcontrol-drone",
                    phase: "launch",
                    state: "launched",
                    exitCode: 124
                )
            ]
        )

        let report = LaunchHealthService.report(
            rootPath: "/tmp/MacWin",
            launchHistory: nil,
            logs: logs,
            smokeReports: [smokeReport]
        )

        #expect(report.entries.isEmpty)
        #expect(report.failedEntryCount == 0)
    }

    @Test("Stale detached launch remains accepted after manager restart")
    func staleDetachedLaunchRemainsAcceptedAfterManagerRestart() throws {
        let generatedAt = Date(timeIntervalSince1970: 2_000_000)
        let record = WineLaunchRecord(
            id: "ltspice-detached",
            mode: .detached,
            state: .started,
            logPath: "/tmp/MacWin/Logs/ltspice.log",
            startedAt: generatedAt.addingTimeInterval(-7 * 24 * 60 * 60),
            endedAt: nil,
            durationMilliseconds: nil,
            processIdentifier: 123,
            exitCode: nil,
            bottleId: "ltspice-market-test",
            bottleName: "LTspice",
            engineId: "wine-11.11",
            winePath: "/tmp/wine",
            exe: "C:\\Program Files\\ADI\\LTspice\\LTspice.exe",
            args: [],
            commandLine: ["/tmp/wine", "C:\\Program Files\\ADI\\LTspice\\LTspice.exe"],
            workingDirectory: "/tmp/MacWin",
            environment: [:]
        )
        let launchHistory = LaunchHistoryReport(
            rootPath: "/tmp/MacWin",
            logsPath: "/tmp/MacWin/Logs",
            recordsPath: "/tmp/MacWin/Logs/LaunchRecords",
            totalLaunchCount: 1,
            completedCount: 0,
            detachedCount: 1,
            failedToLaunchCount: 0,
            stateCounts: [WineLaunchState.started.rawValue: 1],
            latestStartedAt: record.startedAt,
            records: [record]
        )
        let logs = CapabilityLogReport(
            directory: "/tmp/MacWin/Logs",
            recentLogCount: 0,
            healthCounts: [:],
            hintCounts: [:],
            issueReport: LogIssueReport(logs: [], topIssues: [], recentFailures: []),
            recommendations: [],
            entries: []
        )

        let report = LaunchHealthService.report(
            rootPath: "/tmp/MacWin",
            launchHistory: launchHistory,
            logs: logs,
            generatedAt: generatedAt
        )

        let entry = try #require(report.entries.first)
        #expect(entry.status == .passed)
        #expect(entry.runningLaunchCount == 0)
        #expect(entry.latestLaunchState == WineLaunchState.started.rawValue)
    }

    @Test("Newer successful launch supersedes older nonzero exits")
    func newerSuccessfulLaunchSupersedesOlderNonzeroExits() throws {
        func record(id: String, startedAt: TimeInterval, exitCode: Int32, logName: String) -> WineLaunchRecord {
            WineLaunchRecord(
                id: id,
                mode: .foregroundRun,
                state: .completed,
                logPath: "/tmp/MacWin/Logs/\(logName)",
                startedAt: Date(timeIntervalSince1970: startedAt),
                endedAt: Date(timeIntervalSince1970: startedAt + 10),
                durationMilliseconds: 10_000,
                processIdentifier: Int32(startedAt),
                exitCode: exitCode,
                bottleId: "high-performance-win11",
                bottleName: "High Performance Windows 11",
                engineId: "wine-11.11",
                winePath: "/tmp/wine",
                exe: "C:\\Program Files\\Example\\example.exe",
                args: [],
                commandLine: ["/tmp/wine", "C:\\Program Files\\Example\\example.exe"],
                workingDirectory: "/tmp/MacWin",
                environment: [:]
            )
        }

        let launchHistory = LaunchHistoryReport(
            rootPath: "/tmp/MacWin",
            logsPath: "/tmp/MacWin/Logs",
            recordsPath: "/tmp/MacWin/Logs/LaunchRecords",
            totalLaunchCount: 3,
            completedCount: 3,
            detachedCount: 0,
            failedToLaunchCount: 0,
            stateCounts: [WineLaunchState.completed.rawValue: 3],
            latestStartedAt: Date(timeIntervalSince1970: 300),
            records: [
                record(id: "old-failure", startedAt: 100, exitCode: 42, logName: "example-old.log"),
                record(id: "new-success", startedAt: 200, exitCode: 0, logName: "example-success.log"),
                record(id: "latest-smoke", startedAt: 300, exitCode: 15, logName: "example-cli-smoke-latest.log")
            ]
        )
        let logs = CapabilityLogReport(
            directory: "/tmp/MacWin/Logs",
            recentLogCount: 0,
            healthCounts: [:],
            hintCounts: [:],
            issueReport: LogIssueReport(logs: [], topIssues: [], recentFailures: []),
            recommendations: [],
            entries: []
        )

        let report = LaunchHealthService.report(
            rootPath: "/tmp/MacWin",
            launchHistory: launchHistory,
            logs: logs
        )

        let entry = try #require(report.entries.first)
        #expect(entry.status == .passed)
        #expect(entry.launchCount == 3)
        #expect(entry.nonZeroExitCount == 0)
    }

    @Test("Completed installer watchdog exit is controlled")
    func completedInstallerWatchdogExitIsControlled() throws {
        let record = WineLaunchRecord(
            id: "install-portableapps",
            mode: .foregroundRun,
            state: .completed,
            logPath: "/tmp/MacWin/Logs/high-performance-win11-install-portableapps-platform-1234.log",
            startedAt: Date(timeIntervalSince1970: 100),
            endedAt: Date(timeIntervalSince1970: 110),
            durationMilliseconds: 10_000,
            processIdentifier: 100,
            exitCode: 15,
            bottleId: "high-performance-win11",
            bottleName: "High Performance Windows 11",
            engineId: "wine-11.11",
            winePath: "/tmp/wine",
            exe: "/tmp/PortableApps.com_Platform_Setup.paf.exe",
            args: [],
            commandLine: ["/tmp/wine", "/tmp/PortableApps.com_Platform_Setup.paf.exe"],
            workingDirectory: "/tmp/MacWin",
            environment: [:]
        )
        let launchHistory = LaunchHistoryReport(
            rootPath: "/tmp/MacWin",
            logsPath: "/tmp/MacWin/Logs",
            recordsPath: "/tmp/MacWin/Logs/LaunchRecords",
            totalLaunchCount: 1,
            completedCount: 1,
            detachedCount: 0,
            failedToLaunchCount: 0,
            stateCounts: [WineLaunchState.completed.rawValue: 1],
            latestStartedAt: record.startedAt,
            records: [record]
        )
        let logs = CapabilityLogReport(
            directory: "/tmp/MacWin/Logs",
            recentLogCount: 0,
            healthCounts: [:],
            hintCounts: [:],
            issueReport: LogIssueReport(logs: [], topIssues: [], recentFailures: []),
            recommendations: [],
            entries: []
        )

        let report = LaunchHealthService.report(
            rootPath: "/tmp/MacWin",
            launchHistory: launchHistory,
            logs: logs
        )

        let entry = try #require(report.entries.first)
        #expect(entry.status == .passed)
        #expect(entry.nonZeroExitCount == 0)
    }

    @Test("Launch health combines launch records logs issues and probes")
    func combinesLaunchRecordsLogsIssuesAndProbes() {
        let generatedAt = Date(timeIntervalSince1970: 1_800)
        let hoyoLogPath = "/tmp/MacWin/Logs/high-performance-win11-hoyoplay.log"
        let steamLogPath = "/tmp/MacWin/Logs/high-performance-win11-steam.log"
        let portableUpdaterLogPath = "/tmp/MacWin/Logs/high-performance-win11-portableapps-updater.log"
        let sevenZipGuiLogPath = "/tmp/MacWin/Logs/high-performance-win11-7zip-gui-cli-smoke-2026-07-02T035959Z.log"
        let launchHistory = LaunchHistoryReport(
            rootPath: "/tmp/MacWin",
            logsPath: "/tmp/MacWin/Logs",
            recordsPath: "/tmp/MacWin/Logs/LaunchRecords",
            totalLaunchCount: 4,
            completedCount: 4,
            detachedCount: 2,
            failedToLaunchCount: 0,
            stateCounts: [WineLaunchState.completed.rawValue: 4],
            latestStartedAt: Date(timeIntervalSince1970: 1_700),
            records: [
                WineLaunchRecord(
                    id: "hoyoplay-launch",
                    mode: .detached,
                    state: .completed,
                    logPath: hoyoLogPath,
                    startedAt: Date(timeIntervalSince1970: 1_700),
                    endedAt: Date(timeIntervalSince1970: 1_710),
                    durationMilliseconds: 10_000,
                    processIdentifier: 101,
                    exitCode: 0,
                    bottleId: "high-performance-win11",
                    bottleName: "High Performance Windows 11",
                    engineId: "wine-11.11",
                    winePath: "/tmp/wine",
                    exe: "C:\\Program Files\\miHoYo Launcher\\HYP.exe",
                    args: ["--lang=zh-CN"],
                    commandLine: ["/usr/bin/arch", "-x86_64", "/tmp/wine", "C:\\Program Files\\miHoYo Launcher\\HYP.exe"],
                    workingDirectory: "/tmp/MacWin/Bottles/high-performance-win11/drive_c",
                    environment: ["MACWIN_COMPAT_PROFILE": "hoyoplay-webview"]
                ),
                WineLaunchRecord(
                    id: "steam-launch",
                    mode: .detached,
                    state: .completed,
                    logPath: steamLogPath,
                    startedAt: Date(timeIntervalSince1970: 1_600),
                    endedAt: Date(timeIntervalSince1970: 1_601),
                    durationMilliseconds: 1_000,
                    processIdentifier: 102,
                    exitCode: 1,
                    bottleId: "high-performance-win11",
                    bottleName: "High Performance Windows 11",
                    engineId: "wine-11.11",
                    winePath: "/tmp/wine",
                    exe: "C:\\Program Files (x86)\\Steam\\steam.exe",
                    args: [],
                    commandLine: ["/usr/bin/arch", "-x86_64", "/tmp/wine", "C:\\Program Files (x86)\\Steam\\steam.exe"],
                    workingDirectory: "/tmp/MacWin/Bottles/high-performance-win11/drive_c",
                    environment: ["MACWIN_COMPAT_PROFILE": "steam-client"]
                ),
                WineLaunchRecord(
                    id: "portable-updater-launch",
                    mode: .foregroundRun,
                    state: .completed,
                    logPath: portableUpdaterLogPath,
                    startedAt: Date(timeIntervalSince1970: 1_650),
                    endedAt: Date(timeIntervalSince1970: 1_660),
                    durationMilliseconds: 10_000,
                    processIdentifier: 103,
                    exitCode: 15,
                    bottleId: "high-performance-win11",
                    bottleName: "High Performance Windows 11",
                    engineId: "wine-11.11",
                    winePath: "/tmp/wine",
                    exe: "C:\\PortableApps\\PortableApps.com\\PortableAppsUpdater.exe",
                    args: [],
                    commandLine: ["/usr/bin/arch", "-x86_64", "/tmp/wine", "C:\\PortableApps\\PortableApps.com\\PortableAppsUpdater.exe"],
                    workingDirectory: "/tmp/MacWin/Bottles/high-performance-win11/drive_c/PortableApps/PortableApps.com",
                    environment: ["MACWIN_COMPAT_PROFILE": "portableapps-utility"]
                ),
                WineLaunchRecord(
                    id: "2026-07-02T035959Z-high-performance-win11-7zip-gui-cli-smoke-2026-07-02T035959Z-7b1d90e8",
                    mode: .foregroundRun,
                    state: .completed,
                    logPath: sevenZipGuiLogPath,
                    startedAt: Date(timeIntervalSince1970: 1_640),
                    endedAt: Date(timeIntervalSince1970: 1_655),
                    durationMilliseconds: 15_000,
                    processIdentifier: 104,
                    exitCode: 15,
                    bottleId: "high-performance-win11",
                    bottleName: "High Performance Windows 11",
                    engineId: "wine-11.11",
                    winePath: "/tmp/wine",
                    exe: "C:\\Program Files\\7-Zip\\7zG.exe",
                    args: [],
                    commandLine: ["/usr/bin/arch", "-x86_64", "/tmp/wine", "C:\\Program Files\\7-Zip\\7zG.exe"],
                    workingDirectory: "/tmp/MacWin/Bottles/high-performance-win11/drive_c",
                    environment: ["MACWIN_COMPAT_PROFILE": "7zip-gdi"]
                )
            ]
        )
        let logReport = CapabilityLogReport(
            directory: "/tmp/MacWin/Logs",
            recentLogCount: 3,
            healthCounts: [
                LogHealth.failed.rawValue: 1,
                LogHealth.passed.rawValue: 2
            ],
            hintCounts: [
                LogHint.fontRenderingIssue.rawValue: 1,
                LogHint.networkTLSIssue.rawValue: 1,
                LogHint.passObserved.rawValue: 1
            ],
            issueReport: LogIssueReport(
                logs: [],
                topIssues: [
                    LogIssueTrend(
                        id: "text-rendering",
                        severity: "high",
                        title: "Text rendering issue",
                        detail: "CEF text was hidden.",
                        count: 1,
                        relatedHints: [LogHint.fontRenderingIssue.rawValue],
                        affectedLogNames: ["high-performance-win11-hoyoplay.log"],
                        recommendedActions: ["Run text probe."],
                        probeAssetIds: ["text-rendering"]
                    )
                ],
                recentFailures: [
                    LogIssueSample(
                        name: "high-performance-win11-steam.log",
                        path: steamLogPath,
                        modifiedAt: Date(timeIntervalSince1970: 1_612),
                        health: LogHealth.failed.rawValue,
                        errorCount: 1,
                        warningCount: 0,
                        fixmeCount: 0,
                        passCount: 0,
                        failCount: 1,
                        hints: [LogHint.networkTLSIssue.rawValue],
                        probableIssueIds: ["network-tls"],
                        probeAssetIds: ["tls-winhttp"]
                    )
                ]
            ),
            recommendations: [],
            entries: [
                CapabilityLogEntry(
                    name: "high-performance-win11-hoyoplay.log",
                    path: hoyoLogPath,
                    modifiedAt: Date(timeIntervalSince1970: 1_711),
                    byteCount: 100,
                    health: LogHealth.passed.rawValue,
                    errorCount: 0,
                    warningCount: 0,
                    fixmeCount: 0,
                    passCount: 1,
                    failCount: 0,
                    hints: [LogHint.fontRenderingIssue.rawValue]
                ),
                CapabilityLogEntry(
                    name: "high-performance-win11-steam.log",
                    path: steamLogPath,
                    modifiedAt: Date(timeIntervalSince1970: 1_612),
                    byteCount: 200,
                    health: LogHealth.failed.rawValue,
                    errorCount: 1,
                    warningCount: 0,
                    fixmeCount: 0,
                    passCount: 0,
                    failCount: 1,
                    hints: [LogHint.networkTLSIssue.rawValue]
                ),
                CapabilityLogEntry(
                    name: "high-performance-win11-portableapps-updater.log",
                    path: portableUpdaterLogPath,
                    modifiedAt: Date(timeIntervalSince1970: 1_661),
                    byteCount: 300,
                    health: LogHealth.passed.rawValue,
                    errorCount: 0,
                    warningCount: 0,
                    fixmeCount: 0,
                    passCount: 1,
                    failCount: 0,
                    hints: [LogHint.passObserved.rawValue]
                )
            ]
        )

        let report = LaunchHealthService.report(
            rootPath: "/tmp/MacWin",
            launchHistory: launchHistory,
            logs: logReport,
            generatedAt: generatedAt
        )

        #expect(report.entryCount == 4)
        #expect(report.failedEntryCount == 1)
        #expect(report.attentionEntryCount == 1)
        #expect(report.passedEntryCount == 2)
        #expect(report.logMatchedLaunchCount == 3)
        #expect(report.entries.first?.displayName == "steam.exe")
        #expect(report.entries.first?.status == .failed)
        #expect(report.entries.first?.nonZeroExitCount == 1)
        #expect(report.entries.first?.probableIssueIds == ["network-tls"])
        #expect(report.entries.first?.recommendedProbeIds == ["tls-winhttp"])
        let hoyo = report.entries.first { $0.displayName == "HYP.exe" }
        #expect(hoyo?.status == .attention)
        #expect(hoyo?.latestLaunchRecordId == "hoyoplay-launch")
        #expect(hoyo?.latestLogHealth == LogHealth.passed.rawValue)
        #expect(hoyo?.probableIssueIds == ["text-rendering"])
        #expect(hoyo?.recommendedProbeIds == ["text-rendering"])
        let updater = report.entries.first { $0.displayName == "PortableAppsUpdater.exe" }
        #expect(updater?.status == .passed)
        #expect(updater?.nonZeroExitCount == 0)
        #expect(updater?.latestExitCode == 15)
        let sevenZipGui = report.entries.first { $0.displayName == "7zG.exe" }
        #expect(sevenZipGui?.status == .passed)
        #expect(sevenZipGui?.nonZeroExitCount == 0)
        #expect(sevenZipGui?.latestExitCode == 15)

        let csv = LaunchHealthReport.csv(report: report)
        #expect(csv.contains("id,status,display_name,bottle_id"))
        #expect(csv.contains("steam.exe"))
        #expect(csv.contains("network-tls"))

        let markdown = LaunchHealthReport.markdown(report: report)
        #expect(markdown.contains("# MacWin Launch Health"))
        #expect(markdown.contains("- Failed: 1"))
        #expect(markdown.contains("### HYP.exe"))
        #expect(markdown.contains("Probable issues: `text-rendering`"))
        #expect(markdown.contains("Recommended probes: `text-rendering`"))
    }

    @Test("Launch health suppresses superseded Tencent Androws failed logs")
    func suppressesSupersededTencentAndrowsFailedLogs() throws {
        let oldVulkanLogPath = "/tmp/MacWin/Logs/high-performance-win11-tencent-app-store-androws-cli-smoke-2026-07-03T003747Z.log"
        let oldGLLogPath = "/tmp/MacWin/Logs/high-performance-win11-tencent-app-store-androws-cli-smoke-2026-07-03T004151Z.log"
        let newLogPath = "/tmp/MacWin/Logs/high-performance-win11-tencent-app-store-androws-cli-smoke-2026-07-03T004740Z.log"
        let exe = "C:\\Program Files\\Tencent\\Androws\\Application\\5.10.6400.6084\\AndrowsStore.exe"
        let context = LogLaunchContext(
            launchRecordId: "tencent-latest",
            mode: WineLaunchMode.foregroundRun.rawValue,
            state: WineLaunchState.completed.rawValue,
            bottleId: "high-performance-win11",
            bottleName: "High Performance Windows 11",
            engineId: "wine-11.11",
            exe: exe,
            args: [],
            commandLine: ["/usr/bin/arch", "-x86_64", "/tmp/wine", exe],
            startedAt: Date(timeIntervalSince1970: 3_000),
            endedAt: Date(timeIntervalSince1970: 3_015),
            processIdentifier: 200,
            exitCode: 15
        )
        let logReport = CapabilityLogReport(
            directory: "/tmp/MacWin/Logs",
            recentLogCount: 3,
            healthCounts: [
                LogHealth.failed.rawValue: 2,
                LogHealth.passed.rawValue: 1
            ],
            hintCounts: [
                LogHint.wineCrash.rawValue: 1,
                LogHint.vulkanIssue.rawValue: 1,
                LogHint.gpuRenderingIssue.rawValue: 1,
                LogHint.passObserved.rawValue: 1
            ],
            issueReport: LogIssueReport(
                logs: [],
                topIssues: [
                    LogIssueTrend(
                        id: "wine-crash",
                        severity: "high",
                        title: "Wine crash",
                        detail: "Old Androws run crashed before GPU repair.",
                        count: 1,
                        relatedHints: [LogHint.wineCrash.rawValue],
                        affectedLogNames: [URL(fileURLWithPath: oldVulkanLogPath).lastPathComponent],
                        recommendedActions: ["Repair bundled GPU DLLs."],
                        probeAssetIds: ["vulkan"]
                    )
                ],
                recentFailures: [
                    LogIssueSample(
                        name: URL(fileURLWithPath: oldVulkanLogPath).lastPathComponent,
                        path: oldVulkanLogPath,
                        modifiedAt: Date(timeIntervalSince1970: 2_000),
                        health: LogHealth.failed.rawValue,
                        errorCount: 2,
                        warningCount: 0,
                        fixmeCount: 0,
                        passCount: 1,
                        failCount: 1,
                        hints: [LogHint.wineCrash.rawValue, LogHint.vulkanIssue.rawValue],
                        probableIssueIds: ["wine-crash", "graphics-runtime"],
                        probeAssetIds: ["vulkan"]
                    )
                ]
            ),
            recommendations: [],
            entries: [
                CapabilityLogEntry(
                    name: URL(fileURLWithPath: oldVulkanLogPath).lastPathComponent,
                    path: oldVulkanLogPath,
                    modifiedAt: Date(timeIntervalSince1970: 2_000),
                    byteCount: 1_000,
                    health: LogHealth.failed.rawValue,
                    errorCount: 2,
                    warningCount: 0,
                    fixmeCount: 0,
                    passCount: 1,
                    failCount: 1,
                    hints: [LogHint.wineCrash.rawValue, LogHint.vulkanIssue.rawValue],
                    launchContext: context
                ),
                CapabilityLogEntry(
                    name: URL(fileURLWithPath: oldGLLogPath).lastPathComponent,
                    path: oldGLLogPath,
                    modifiedAt: Date(timeIntervalSince1970: 2_100),
                    byteCount: 1_000,
                    health: LogHealth.failed.rawValue,
                    errorCount: 1,
                    warningCount: 0,
                    fixmeCount: 0,
                    passCount: 1,
                    failCount: 1,
                    hints: [LogHint.gpuRenderingIssue.rawValue],
                    launchContext: context
                ),
                CapabilityLogEntry(
                    name: URL(fileURLWithPath: newLogPath).lastPathComponent,
                    path: newLogPath,
                    modifiedAt: Date(timeIntervalSince1970: 2_200),
                    byteCount: 1_000,
                    health: LogHealth.passed.rawValue,
                    errorCount: 0,
                    warningCount: 0,
                    fixmeCount: 0,
                    passCount: 1,
                    failCount: 0,
                    hints: [LogHint.passObserved.rawValue],
                    launchContext: context
                )
            ]
        )

        let report = LaunchHealthService.report(
            rootPath: "/tmp/MacWin",
            launchHistory: nil,
            logs: logReport,
            generatedAt: Date(timeIntervalSince1970: 3_100)
        )

        #expect(report.entryCount == 1)
        let entry = try #require(report.entries.first)
        #expect(entry.status == .passed)
        #expect(entry.failedLogCount == 0)
        #expect(entry.attentionLogCount == 0)
        #expect(entry.passedLogCount == 1)
        #expect(entry.logCount == 1)
        #expect(entry.probableIssueIds.isEmpty)
        #expect(entry.recommendedProbeIds.isEmpty)
        #expect(entry.logPaths == [newLogPath])
    }
}
