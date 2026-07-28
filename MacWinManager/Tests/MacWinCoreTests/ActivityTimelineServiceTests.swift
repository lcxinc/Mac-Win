import Foundation
import Testing
@testable import MacWinCore

@Suite("Activity timeline service")
struct ActivityTimelineServiceTests {
    @Test("Timeline merges installs tests launches log issues and diagnostics")
    func timelineMergesOperationalEvents() {
        let installerDownloadHistory = InstallerDownloadHistoryReport(
            rootPath: "/tmp/MacWin",
            recordsPath: "/tmp/MacWin/Logs/InstallerDownloadRecords",
            records: [
                InstallerDownloadRecord(
                    id: "tool-download",
                    recipeId: "tool",
                    recipeName: "Tool",
                    fileName: "tool.msi",
                    sourceURL: "https://example.test/tool.msi",
                    destinationPath: "/tmp/MacWin/Downloads/tool.msi",
                    startedAt: Date(timeIntervalSince1970: 90),
                    endedAt: Date(timeIntervalSince1970: 95),
                    state: .downloaded,
                    expectedSha256: "abc",
                    actualSha256: "abc",
                    byteCount: 128
                ),
                InstallerDownloadRecord(
                    id: "steam-mismatch",
                    recipeId: "steam",
                    recipeName: "Steam",
                    fileName: "SteamSetup.exe",
                    sourceURL: "https://example.test/SteamSetup.exe",
                    destinationPath: "/tmp/MacWin/Downloads/SteamSetup.exe",
                    startedAt: Date(timeIntervalSince1970: 96),
                    endedAt: Date(timeIntervalSince1970: 99),
                    state: .hashMismatch,
                    expectedSha256: "expected",
                    actualSha256: "actual",
                    byteCount: 256,
                    errorMessage: "Downloaded installer SHA-256 does not match recipe"
                )
            ]
        )
        let installHistory = InstallHistoryReport(
            rootPath: "/tmp/MacWin",
            logsPath: "/tmp/MacWin/Logs",
            recordsPath: "/tmp/MacWin/Logs/InstallRecords",
            totalTaskCount: 1,
            succeededCount: 0,
            failedCount: 1,
            runningCount: 0,
            stateCounts: ["failed": 1],
            latestStartedAt: Date(timeIntervalSince1970: 100),
            tasks: [
                InstallTask(
                    id: "installer",
                    recipeId: "hoyoplay-cn",
                    bottleId: "high-performance-win11",
                    state: .failed,
                    progressText: "Installer exited 1",
                    logPath: "/tmp/MacWin/Logs/install.log",
                    startedAt: Date(timeIntervalSince1970: 100),
                    endedAt: Date(timeIntervalSince1970: 110),
                    exitCode: 1
                )
            ]
        )
        let testRunHistory = TestRunHistoryReport(
            rootPath: "/tmp/MacWin/exe-tests",
            logsPath: "/tmp/MacWin/exe-tests/logs",
            runs: [
                TestRunRecord(
                    id: "console-pass",
                    assetId: "console",
                    name: "Win32 Console Probe",
                    category: .core,
                    architecture: .x86_64,
                    logPath: "/tmp/MacWin/exe-tests/logs/00_console_probe.log",
                    exitPath: "/tmp/MacWin/exe-tests/logs/00_console_probe.exit",
                    exitCode: 0,
                    outcome: .passed,
                    modifiedAt: Date(timeIntervalSince1970: 120),
                    byteCount: 20,
                    passSignals: ["PASS console"],
                    failSignals: [],
                    timeoutObserved: false,
                    summary: "outcome=passed exit=0 passSignals=1"
                ),
                TestRunRecord(
                    id: "d3d11-timeout",
                    assetId: "d3d11",
                    name: "D3D11 Device Probe",
                    category: .graphics,
                    architecture: .x86_64,
                    logPath: "/tmp/MacWin/exe-tests/logs/30_d3d11_probe.log",
                    exitPath: "/tmp/MacWin/exe-tests/logs/30_d3d11_probe.exit",
                    exitCode: 124,
                    outcome: .timedOut,
                    modifiedAt: Date(timeIntervalSince1970: 130),
                    byteCount: 42,
                    passSignals: [],
                    failSignals: [],
                    timeoutObserved: true,
                    summary: "outcome=timedOut exit=124 timeout=true"
                )
            ]
        )
        let launchHistory = LaunchHistoryReport(
            rootPath: "/tmp/MacWin",
            logsPath: "/tmp/MacWin/Logs",
            recordsPath: "/tmp/MacWin/Logs/LaunchRecords",
            totalLaunchCount: 1,
            completedCount: 0,
            detachedCount: 1,
            failedToLaunchCount: 1,
            stateCounts: ["failedToLaunch": 1],
            latestStartedAt: Date(timeIntervalSince1970: 140),
            records: [
                WineLaunchRecord(
                    id: "steam-launch",
                    mode: .detached,
                    state: .failedToLaunch,
                    logPath: "/tmp/MacWin/Logs/steam.log",
                    startedAt: Date(timeIntervalSince1970: 140),
                    endedAt: Date(timeIntervalSince1970: 145),
                    durationMilliseconds: 5_000,
                    bottleId: "high-performance-win11",
                    bottleName: "High Performance Windows 11",
                    engineId: "wine",
                    winePath: "/tmp/wine",
                    exe: "C:\\Program Files\\Steam\\Steam.exe",
                    args: ["-no-cef-sandbox"],
                    commandLine: ["/usr/bin/arch", "-x86_64", "/tmp/wine", "C:\\Program Files\\Steam\\Steam.exe"],
                    workingDirectory: "/tmp/MacWin/Bottles/high-performance-win11/drive_c",
                    environment: ["MACWIN_COMPAT_PROFILE": "steam-client"],
                    errorMessage: "launch failed"
                )
            ]
        )
        let failedLog = LogFileItem(
            name: "failed.log",
            url: URL(fileURLWithPath: "/tmp/MacWin/Logs/failed.log"),
            modifiedAt: Date(timeIntervalSince1970: 150),
            byteCount: 64,
            summary: LogSummary(errorCount: 1, failCount: 1, hints: [.vulkanIssue])
        )
        let logs = CapabilityLogReport(
            directory: "/tmp/MacWin/Logs",
            recentLogCount: 1,
            healthCounts: ["failed": 1],
            hintCounts: ["vulkanIssue": 1],
            issueReport: LogIssueReport(
                logs: [failedLog],
                topIssues: [],
                recentFailures: [
                    LogIssueSample(
                        name: "failed.log",
                        path: "/tmp/MacWin/Logs/failed.log",
                        modifiedAt: Date(timeIntervalSince1970: 150),
                        health: "failed",
                        errorCount: 1,
                        warningCount: 0,
                        fixmeCount: 0,
                        passCount: 0,
                        failCount: 1,
                        hints: ["vulkanIssue"],
                        probableIssueIds: ["graphics-runtime"]
                    )
                ]
            ),
            recommendations: [],
            entries: []
        )
        let diagnostics = CapabilityDiagnosticsReport(
            exitCode: 1,
            logPath: "/tmp/MacWin/Logs/diagnostics.log",
            timedOut: false,
            durationSeconds: 2.5,
            total: 2,
            statusCounts: ["passed": 1, "failed": 1],
            categories: []
        )

        let report = ActivityTimelineReport.make(
            generatedAt: Date(timeIntervalSince1970: 160),
            installerDownloadHistory: installerDownloadHistory,
            installHistory: installHistory,
            testRunHistory: testRunHistory,
            launchHistory: launchHistory,
            logs: logs,
            diagnostics: diagnostics
        )

        #expect(report.eventCount == 8)
        #expect(report.errorEventCount == 6)
        #expect(report.warningEventCount == 0)
        #expect(report.infoEventCount == 2)
        #expect(report.latestEventAt == Date(timeIntervalSince1970: 160))
        #expect(report.events.map(\.timestamp) == report.events.map(\.timestamp).sorted(by: >))
        #expect(report.events.first?.kind == .diagnostics)
        #expect(report.events.contains { $0.id == "installer-download:tool-download" && $0.severity == .info && $0.appId == "tool" })
        #expect(report.events.contains { $0.id == "installer-download:steam-mismatch" && $0.severity == .error && $0.detail.contains("actual=actual") })
        #expect(report.events.contains { $0.id == "install:installer" && $0.severity == .error })
        #expect(report.events.contains { $0.id == "test:console-pass" && $0.severity == .info })
        #expect(report.events.contains { $0.id == "test:d3d11-timeout" && $0.severity == .error })
        #expect(report.events.contains { $0.id == "launch:steam-launch" && $0.title == "Launch Steam.exe" })
        #expect(report.events.contains { $0.id == "log:/tmp/MacWin/Logs/failed.log" && $0.relatedLogPath == "/tmp/MacWin/Logs/failed.log" })
    }

    @Test("Timeline applies event limit after sorting")
    func timelineAppliesLimitAfterSorting() {
        let events = (0..<5).map { index in
            ActivityTimelineEvent(
                id: "event-\(index)",
                kind: .testRun,
                severity: index.isMultiple(of: 2) ? .info : .warning,
                timestamp: Date(timeIntervalSince1970: TimeInterval(index)),
                title: "Event \(index)",
                detail: "detail"
            )
        }

        let report = ActivityTimelineReport(
            generatedAt: Date(timeIntervalSince1970: 10),
            events: events,
            limit: 3
        )

        #expect(report.eventCount == 3)
        #expect(report.events.map(\.id) == ["event-4", "event-3", "event-2"])
        #expect(report.infoEventCount == 2)
        #expect(report.warningEventCount == 1)
        #expect(report.errorEventCount == 0)
        #expect(report.latestEventAt == Date(timeIntervalSince1970: 4))
    }
}
