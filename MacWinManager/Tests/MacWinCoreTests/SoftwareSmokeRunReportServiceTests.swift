import Foundation
import Testing
@testable import MacWinCore

@Suite("Software smoke run report service")
struct SoftwareSmokeRunReportServiceTests {
    @Test("Newer successful app smoke supersedes matching legacy debug logs")
    func newerSuccessfulSmokeSupersedesMatchingLegacyDebugLogs() {
        let report = SoftwareSmokeRunReport(
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
        let oldLogDate = Date(timeIntervalSince1970: 1_784_897_862)

        #expect(SoftwareSmokeEvidenceResolver.supersedes(
            logName: "qgroundcontrol-map-winedebug.log",
            logPath: "/tmp/logs/qgroundcontrol-map-winedebug.log",
            modifiedAt: oldLogDate,
            reports: [report]
        ))
        #expect(!SoftwareSmokeEvidenceResolver.supersedes(
            logName: "steam-winedebug.log",
            logPath: "/tmp/logs/steam-winedebug.log",
            modifiedAt: oldLogDate,
            reports: [report]
        ))
        #expect(!SoftwareSmokeEvidenceResolver.supersedes(
            logName: "qgroundcontrol-map-winedebug.log",
            logPath: "/tmp/logs/qgroundcontrol-map-winedebug.log",
            modifiedAt: Date(timeIntervalSince1970: 1_784_910_000),
            reports: [report]
        ))
    }

    @Test("Smoke run report decodes effective counts and superseded skips")
    func decodesEffectiveCountsAndSupersededSkips() throws {
        let json = """
        {
          "generatedAt": "2026-06-26T08:00:00Z",
          "runId": "winscp-all",
          "suite": "all",
          "sample": null,
          "prefix": "/tmp/prefix",
          "logDirectory": "/tmp/logs",
          "recordCount": 3,
          "stateCounts": {
            "launched": 1,
            "passed": 1,
            "skipped": 1
          },
          "effectiveStateCounts": {
            "launched": 1,
            "passed": 1,
            "superseded": 1
          },
          "supersededSkipCount": 1,
          "supersededSkips": [
            {
              "id": "winscp-client",
              "state": "skipped",
              "exitCode": 108,
              "logPath": "/tmp/winscp-client.log",
              "note": "legacy skipped",
              "reason": "Use the x64 portable sample.",
              "supersededBy": ["winscp-x64-portable", "winscp-x64-cli-help"],
              "coveredBy": [
                {
                  "id": "winscp-x64-portable",
                  "state": "launched",
                  "logPath": "/tmp/winscp-x64.log",
                  "note": "GUI stayed alive"
                },
                {
                  "id": "winscp-x64-cli-help",
                  "state": "passed",
                  "logPath": "/tmp/winscp-cli.log",
                  "note": ""
                }
              ],
              "missingAlternatesInRun": []
            }
          ],
          "records": [
            {
              "id": "winscp-client",
              "phase": "launch",
              "state": "skipped",
              "exitCode": 108,
              "durationSeconds": 30,
              "logPath": "/tmp/winscp-client.log",
              "note": "legacy skipped"
            }
          ]
        }
        """

        let report = try JSONDecoder().decode(SoftwareSmokeRunReport.self, from: Data(json.utf8))

        #expect(report.runId == "winscp-all")
        #expect(report.stateCounts["skipped"] == 1)
        #expect(report.effectiveStateCounts["superseded"] == 1)
        #expect(report.supersededSkipCount == 1)
        #expect(report.supersededSkips.first?.id == "winscp-client")
        #expect(report.supersededSkips.first?.coveredBy.map(\.id) == ["winscp-x64-portable", "winscp-x64-cli-help"])
    }

    @Test("Smoke run report remains compatible with old reports")
    func decodesOldReportWithoutEffectiveFields() throws {
        let json = """
        {
          "generatedAt": "2026-06-26T08:00:00Z",
          "runId": "old-run",
          "suite": "all",
          "sample": "geogebra-classic",
          "prefix": "/tmp/prefix",
          "logDirectory": "/tmp/logs",
          "recordCount": 1,
          "stateCounts": {
            "skipped": 1
          },
          "records": [
            {
              "id": "geogebra-classic",
              "phase": "launch",
              "state": "skipped",
              "exitCode": 106
            }
          ]
        }
        """

        let report = try JSONDecoder().decode(SoftwareSmokeRunReport.self, from: Data(json.utf8))

        #expect(report.effectiveStateCounts == report.stateCounts)
        #expect(report.supersededSkipCount == 0)
        #expect(report.supersededSkips.isEmpty)
    }

    @Test("Smoke run service loads latest reports and summarizes effective skips")
    func serviceLoadsLatestReportsAndSummarizesEffectiveSkips() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("MacWinSmokeRunReportServiceTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()

        try writeReport(
            root: paths.logsDirectory,
            runId: "old",
            modifiedAt: Date(timeIntervalSince1970: 100),
            stateCounts: ["skipped": 1],
            effectiveStateCounts: nil,
            supersededSkips: []
        )
        try writeReport(
            root: paths.logsDirectory,
            runId: "new",
            modifiedAt: Date(timeIntervalSince1970: 200),
            stateCounts: ["passed": 2, "skipped": 1],
            effectiveStateCounts: ["passed": 2, "superseded": 1],
            supersededSkips: [
                SoftwareSmokeRunSupersededSkip(
                    id: "geogebra-classic",
                    reason: "Use Classic 5.",
                    supersededBy: ["geogebra-classic5"],
                    coveredBy: [SoftwareSmokeRunCoveredAlternate(id: "geogebra-classic5", state: "passed")]
                )
            ]
        )

        let service = SoftwareSmokeRunReportService(paths: paths)
        let reports = try service.reports(limit: 2)
        let summary = try service.summary(limit: 2)

        #expect(reports.map(\.runId) == ["new", "old"])
        #expect(summary.latestRunId == "new")
        #expect(summary.rawStateCounts["skipped"] == 2)
        #expect(summary.effectiveStateCounts["superseded"] == 1)
        #expect(summary.supersededSkipCount == 1)
        #expect(summary.uncoveredSkippedCount == 1)
    }

    @Test("Smoke run summary resolves legacy failed launches covered by newer validated sample")
    func summaryResolvesLegacyFailedLaunchesCoveredByNewerValidatedSample() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("MacWinSmokeRunReportResolvedLegacyTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()

        try writeReport(
            root: paths.logsDirectory,
            runId: "qownnotes-portable-pass",
            modifiedAt: Date(timeIntervalSince1970: 300),
            stateCounts: ["launched": 1],
            effectiveStateCounts: nil,
            supersededSkips: [],
            records: [
                SoftwareSmokeRunRecord(
                    id: "qownnotes-portable",
                    phase: "launch",
                    state: "launched",
                    exitCode: 124,
                    logPath: "/tmp/qownnotes-portable-launch.log",
                    note: "GUI stayed alive"
                )
            ]
        )
        try writeReport(
            root: paths.logsDirectory,
            runId: "qownnotes-editor-failed",
            modifiedAt: Date(timeIntervalSince1970: 200),
            stateCounts: ["failed": 1],
            effectiveStateCounts: nil,
            supersededSkips: [],
            records: [
                SoftwareSmokeRunRecord(
                    id: "qownnotes-editor",
                    phase: "launch",
                    state: "failed",
                    exitCode: 53,
                    logPath: "/tmp/qownnotes-editor-launch.log"
                )
            ]
        )

        let summary = try SoftwareSmokeRunReportService(paths: paths).summary(limit: 2)

        #expect(summary.rawStateCounts["failed"] == 1)
        #expect(summary.effectiveStateCounts["failed"] == nil)
        #expect(summary.effectiveStateCounts["superseded"] == 1)
        #expect(summary.resolvedLegacyFailureCount == 1)
        #expect(summary.resolvedLegacyFailures.first?.id == "qownnotes-editor")
        #expect(summary.resolvedLegacyFailures.first?.coveredBy.map(\.id) == ["qownnotes-portable"])
        let markdown = SoftwareSmokeRunReportService.markdown(summary: summary)
        #expect(markdown.contains("Resolved Legacy Failures"))
        #expect(markdown.contains("qownnotes-editor"))
    }

    @Test("Smoke run summary resolves older same-sample failures covered by newer pass")
    func summaryResolvesOlderSameSampleFailuresCoveredByNewerPass() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("MacWinSmokeRunReportResolvedSameSampleTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()

        try writeReport(
            root: paths.logsDirectory,
            runId: "mullvad-profile-retry",
            modifiedAt: Date(timeIntervalSince1970: 300),
            stateCounts: ["passed": 1],
            effectiveStateCounts: nil,
            supersededSkips: [],
            records: [
                SoftwareSmokeRunRecord(
                    id: "mullvad-browser",
                    phase: "launch",
                    state: "passed",
                    exitCode: 0,
                    logPath: "/tmp/mullvad-pass.log",
                    note: "GUI launch passed after one first-run retry."
                )
            ]
        )
        try writeReport(
            root: paths.logsDirectory,
            runId: "mullvad-app-arg-failed",
            modifiedAt: Date(timeIntervalSince1970: 200),
            stateCounts: ["failed": 1],
            effectiveStateCounts: nil,
            supersededSkips: [],
            records: [
                SoftwareSmokeRunRecord(
                    id: "mullvad-browser",
                    phase: "launch",
                    state: "failed",
                    exitCode: 88,
                    logPath: "/tmp/mullvad-failed.log",
                    note: "GUI process exited before 5s minimum launch window."
                )
            ]
        )

        let summary = try SoftwareSmokeRunReportService(paths: paths).summary(limit: 2)

        #expect(summary.rawStateCounts["failed"] == 1)
        #expect(summary.effectiveStateCounts["failed"] == nil)
        #expect(summary.effectiveStateCounts["superseded"] == 1)
        #expect(summary.resolvedLegacyFailureCount == 1)
        #expect(summary.resolvedLegacyFailures.first?.id == "mullvad-browser")
        #expect(summary.resolvedLegacyFailures.first?.supersededBy == ["mullvad-browser"])
        #expect(summary.resolvedLegacyFailures.first?.coveredBy.first?.state == "passed")
    }

    @Test("Smoke run summary resolves older repair failures covered by newer repair pass")
    func summaryResolvesOlderRepairFailuresCoveredByNewerPass() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("MacWinSmokeRunReportResolvedRepairTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()

        try writeReport(
            root: paths.logsDirectory,
            runId: "com-proxy-repair-pass",
            modifiedAt: Date(timeIntervalSince1970: 300),
            stateCounts: ["passed": 1],
            effectiveStateCounts: nil,
            supersededSkips: [],
            records: [
                SoftwareSmokeRunRecord(
                    id: "macwin-com-proxy",
                    phase: "repair",
                    state: "passed",
                    exitCode: 0,
                    logPath: "/tmp/com-proxy-pass.log"
                )
            ]
        )
        try writeReport(
            root: paths.logsDirectory,
            runId: "com-proxy-repair-timeout",
            modifiedAt: Date(timeIntervalSince1970: 200),
            stateCounts: ["failed": 1],
            effectiveStateCounts: nil,
            supersededSkips: [],
            records: [
                SoftwareSmokeRunRecord(
                    id: "macwin-com-proxy",
                    phase: "repair",
                    state: "failed",
                    exitCode: 124,
                    logPath: "/tmp/com-proxy-timeout.log",
                    note: "Repair did not exit before watchdog timeout."
                )
            ]
        )

        let summary = try SoftwareSmokeRunReportService(paths: paths).summary(limit: 2)

        #expect(summary.rawStateCounts["failed"] == 1)
        #expect(summary.effectiveStateCounts["failed"] == nil)
        #expect(summary.effectiveStateCounts["superseded"] == 1)
        #expect(summary.resolvedLegacyFailureCount == 1)
        #expect(summary.resolvedLegacyFailures.first?.id == "macwin-com-proxy")
        #expect(summary.resolvedLegacyFailures.first?.coveredBy.first?.state == "passed")
    }

    @Test("Smoke run summary resolves older install path failures covered by newer installed file or launch")
    func summaryResolvesOlderInstallPathFailuresCoveredByNewerEvidence() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("MacWinSmokeRunReportResolvedInstallPathTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()

        try writeReport(
            root: paths.logsDirectory,
            runId: "brave-current-pass",
            modifiedAt: Date(timeIntervalSince1970: 300),
            stateCounts: ["passed": 2],
            effectiveStateCounts: nil,
            supersededSkips: [],
            records: [
                SoftwareSmokeRunRecord(
                    id: "brave-standalone",
                    phase: "installed-file",
                    state: "passed",
                    exitCode: 0,
                    logPath: "/tmp/current/AppData/Local/BraveSoftware/Brave-Browser/Application/brave.exe",
                    note: "Installed executable found at current user-local path."
                ),
                SoftwareSmokeRunRecord(
                    id: "brave-standalone",
                    phase: "launch",
                    state: "passed",
                    exitCode: 0,
                    logPath: "/tmp/brave-current-launch.log"
                )
            ]
        )
        try writeReport(
            root: paths.logsDirectory,
            runId: "brave-old-program-files-failed",
            modifiedAt: Date(timeIntervalSince1970: 200),
            stateCounts: ["failed": 2],
            effectiveStateCounts: nil,
            supersededSkips: [],
            records: [
                SoftwareSmokeRunRecord(
                    id: "brave-standalone",
                    phase: "install",
                    state: "failed",
                    exitCode: 124,
                    logPath: "/tmp/brave-old-install.log",
                    note: "Installer timed out while old sample expected Program Files path."
                ),
                SoftwareSmokeRunRecord(
                    id: "brave-standalone",
                    phase: "installed-file",
                    state: "failed",
                    exitCode: 1,
                    logPath: "/tmp/old/Program Files/BraveSoftware/Brave-Browser/Application/brave.exe",
                    note: "Old expected installed executable was not found."
                )
            ]
        )

        let summary = try SoftwareSmokeRunReportService(paths: paths).summary(limit: 2)

        #expect(summary.rawStateCounts["failed"] == 2)
        #expect(summary.effectiveStateCounts["failed"] == nil)
        #expect(summary.effectiveStateCounts["superseded"] == 2)
        #expect(summary.resolvedLegacyFailureCount == 2)
        #expect(summary.resolvedLegacyFailures.map(\.id) == ["brave-standalone", "brave-standalone"])
        #expect(summary.resolvedLegacyFailures.allSatisfy { $0.supersededBy == ["brave-standalone"] })
    }

    private func writeReport(
        root: URL,
        runId: String,
        modifiedAt: Date,
        stateCounts: [String: Int],
        effectiveStateCounts: [String: Int]?,
        supersededSkips: [SoftwareSmokeRunSupersededSkip],
        records: [SoftwareSmokeRunRecord]? = nil
    ) throws {
        let report = SoftwareSmokeRunReport(
            generatedAt: "2026-06-26T08:00:00Z",
            runId: runId,
            suite: "all",
            prefix: "/tmp/\(runId)",
            logDirectory: "/tmp/logs/\(runId)",
            recordCount: 1,
            stateCounts: stateCounts,
            effectiveStateCounts: effectiveStateCounts,
            supersededSkips: supersededSkips,
            records: records ?? [
                SoftwareSmokeRunRecord(id: runId, phase: "launch", state: stateCounts.keys.sorted().first ?? "passed")
            ]
        )
        let directory = root.appendingPathComponent("SoftwareSmokeRuns/\(runId)", isDirectory: true)
        let url = directory.appendingPathComponent("software-smoke-report.json")
        try JSONStore().save(report, to: url)
        try FileManager.default.setAttributes([.modificationDate: modifiedAt], ofItemAtPath: url.path)
        try FileManager.default.setAttributes([.modificationDate: modifiedAt], ofItemAtPath: directory.path)
    }
}
