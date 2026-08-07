import Foundation
import Testing
@testable import MacWinCore

@Suite("Log history cleanup")
struct LogHistoryCleanupServiceTests {
    @Test("Historical failed logs are archived while current and passed logs remain live")
    func archiveHistoricalFailures() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinLogHistory-(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let oldDate = now.addingTimeInterval(-3 * 24 * 60 * 60)
        let currentDate = now.addingTimeInterval(-2 * 60 * 60)
        try write("err: old failure\n", to: paths.logsDirectory.appendingPathComponent("old-failure.log"), date: oldDate)
        try write("err: current failure\n", to: paths.logsDirectory.appendingPathComponent("current-failure.log"), date: currentDate)
        try write("exitCode=0\nPASS\n", to: paths.logsDirectory.appendingPathComponent("old-pass.log"), date: oldDate)

        let result = try LogService(paths: paths).archiveHistoricalFailures(generatedAt: now)
        #expect(result.archivedCount == 1)
        #expect(!FileManager.default.fileExists(atPath: paths.logsDirectory.appendingPathComponent("old-failure.log").path))
        #expect(FileManager.default.fileExists(atPath: paths.logsDirectory.appendingPathComponent("current-failure.log").path))
        #expect(FileManager.default.fileExists(atPath: paths.logsDirectory.appendingPathComponent("old-pass.log").path))
        #expect(LogService(paths: paths).recentLogs(limit: Int.max).map(\.name) == ["current-failure.log", "old-pass.log"])
    }

    private func write(_ text: String, to url: URL, date: Date) throws {
        try Data(text.utf8).write(to: url)
        try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: url.path)
    }
}
