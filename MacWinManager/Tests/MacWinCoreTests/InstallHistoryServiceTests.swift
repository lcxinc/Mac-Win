import Foundation
import Testing
@testable import MacWinCore

@Suite("Install history service")
struct InstallHistoryServiceTests {
    @Test("Install history report sorts and summarizes task records")
    func installHistoryReportSortsAndSummarizesTaskRecords() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinInstallHistoryTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()
        let service = InstallHistoryService(paths: paths)
        try service.save(InstallTask(
            id: "old-success",
            recipeId: "tool",
            bottleId: "bottle",
            state: .succeeded,
            progressText: "Installed Tool",
            logPath: paths.logsDirectory.appendingPathComponent("tool.log").path,
            startedAt: Date(timeIntervalSince1970: 100),
            endedAt: Date(timeIntervalSince1970: 101),
            exitCode: 0
        ))
        try service.save(InstallTask(
            id: "new-failure",
            recipeId: "game",
            bottleId: "bottle",
            state: .failed,
            progressText: "Installer failed",
            logPath: paths.logsDirectory.appendingPathComponent("game.log").path,
            startedAt: Date(timeIntervalSince1970: 300),
            endedAt: Date(timeIntervalSince1970: 301),
            exitCode: 1
        ))
        try service.save(InstallTask(
            id: "running",
            recipeId: "runtime",
            bottleId: "bottle",
            state: .running,
            progressText: "Installing Runtime",
            logPath: paths.logsDirectory.appendingPathComponent("runtime.log").path,
            startedAt: Date(timeIntervalSince1970: 200)
        ))
        try service.save(InstallTask(
            id: "local-launched",
            recipeId: "local-installer:setup.exe",
            bottleId: "bottle",
            state: .launched,
            progressText: "Launched interactive installer setup.exe pid 42",
            logPath: paths.logsDirectory.appendingPathComponent("setup.log").path,
            startedAt: Date(timeIntervalSince1970: 250)
        ))

        let report = service.report(limit: 3)

        #expect(report.rootPath == root.path)
        #expect(report.recordsPath.hasSuffix("Logs/InstallRecords"))
        #expect(report.totalTaskCount == 3)
        #expect(report.failedCount == 1)
        #expect(report.runningCount == 1)
        #expect(report.launchedCount == 1)
        #expect(report.succeededCount == 0)
        #expect(report.stateCounts["failed"] == 1)
        #expect(report.stateCounts["running"] == 1)
        #expect(report.stateCounts["launched"] == 1)
        #expect(report.latestStartedAt == Date(timeIntervalSince1970: 300))
        #expect(report.tasks.map(\.id) == ["new-failure", "local-launched", "running"])

        let csv = InstallHistoryReport.csv(report: report)
        #expect(csv.contains("id,recipe_id,bottle_id,state,progress_text,started_at,ended_at,duration_ms,exit_code,log_path"))
        #expect(csv.contains("new-failure,game,bottle,failed,Installer failed,1970-01-01T00:05:00Z,1970-01-01T00:05:01Z,1000,1"))
        #expect(csv.contains("local-launched,local-installer:setup.exe,bottle,launched,Launched interactive installer setup.exe pid 42,1970-01-01T00:04:10Z"))
        #expect(csv.contains("running,runtime,bottle,running,Installing Runtime,1970-01-01T00:03:20Z"))
    }

    @Test("Empty install history report is stable")
    func emptyInstallHistoryReportIsStable() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinEmptyInstallHistoryTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let report = InstallHistoryService(paths: paths).report()

        #expect(report.totalTaskCount == 0)
        #expect(report.succeededCount == 0)
        #expect(report.failedCount == 0)
        #expect(report.runningCount == 0)
        #expect(report.launchedCount == 0)
        #expect(report.latestStartedAt == nil)
        #expect(report.tasks.isEmpty)
    }
}
