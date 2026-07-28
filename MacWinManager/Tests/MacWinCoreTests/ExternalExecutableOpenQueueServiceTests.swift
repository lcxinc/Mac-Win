import Foundation
import Testing
@testable import MacWinCore

@Suite("External executable open queue service")
struct ExternalExecutableOpenQueueServiceTests {
    @Test("Queue stores only EXE requests, deduplicates pending paths, and writes an audit log")
    func queueStoresOnlyExecutablesAndDrainsUniquePaths() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinExternalOpenQueueTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = ExternalExecutableOpenQueueService(paths: paths)
        let first = root.appendingPathComponent("Downloads/Setup One.exe")
        let duplicate = root.appendingPathComponent("Downloads/Setup One.exe")
        let second = root.appendingPathComponent("Downloads/工具.EXE")
        let ignored = root.appendingPathComponent("Downloads/readme.txt")

        let enqueuedAt = Date(timeIntervalSince1970: 1_780_000_000)
        let items = try service.enqueue(
            urls: [first, ignored, duplicate, second],
            source: "test-batch",
            enqueuedAt: enqueuedAt
        )

        #expect(items.map(\.path) == [
            first.standardizedFileURL.path,
            second.standardizedFileURL.path
        ])
        let duplicateItems = try service.enqueue(
            urls: [first, second],
            source: "duplicate-instance",
            enqueuedAt: enqueuedAt
        )
        #expect(duplicateItems.isEmpty)
        #expect(FileManager.default.fileExists(atPath: service.queueURL.path))

        let drained = try service.drain(at: Date(timeIntervalSince1970: 1_780_000_100))
        #expect(drained.map(\.path) == [
            first.standardizedFileURL.path,
            second.standardizedFileURL.path
        ])
        #expect(try service.drain().isEmpty)

        let log = try String(contentsOf: service.logURL, encoding: .utf8)
        #expect(log.contains("event=enqueue"))
        #expect(log.contains("event=drain"))
        #expect(log.contains("source=test-batch"))
        #expect(!log.contains("source=duplicate-instance"))
        #expect(log.contains("Setup One.exe"))
        #expect(log.contains("工具.EXE"))
        #expect(!log.contains("readme.txt"))
    }

    @Test("Command line URL parsing accepts file URLs and local paths")
    func commandLineURLParsingAcceptsFileURLsAndPaths() {
        let urls = ExternalExecutableOpenQueueService.executableURLs(fromCommandLineArguments: [
            "/Applications/MacWin Manager.app/Contents/MacOS/MacWinManagerApp",
            "/Users/test/Downloads/Game Setup.exe",
            "file:///Users/test/Downloads/Tool.EXE",
            "/Users/test/Downloads/readme.txt"
        ])

        #expect(urls.map(\.path) == [
            "/Users/test/Downloads/Game Setup.exe",
            "/Users/test/Downloads/Tool.EXE"
        ])
    }

    @Test("Queue report preserves duplicate pending opens and exports diagnostics")
    func queueReportPreservesDuplicatePendingOpens() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinExternalOpenQueueReportTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = ExternalExecutableOpenQueueService(paths: paths)
        let first = root.appendingPathComponent("Downloads/Setup One.exe")
        let duplicate = root.appendingPathComponent("Downloads/Setup One.exe")
        let second = root.appendingPathComponent("Downloads/工具.EXE")
        try service.enqueue(
            urls: [first],
            source: "duplicate-instance",
            enqueuedAt: Date(timeIntervalSince1970: 1_780_000_000)
        )
        let duplicateItem = ExternalExecutableOpenQueueItem(
            path: duplicate.standardizedFileURL.path,
            source: "duplicate-instance",
            enqueuedAt: Date(timeIntervalSince1970: 1_780_000_005)
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let duplicateData = try encoder.encode(duplicateItem) + Data("\n".utf8)
        let duplicateHandle = try FileHandle(forWritingTo: service.queueURL)
        try duplicateHandle.seekToEnd()
        try duplicateHandle.write(contentsOf: duplicateData)
        try duplicateHandle.close()
        try service.enqueue(
            urls: [second],
            source: "open-url",
            enqueuedAt: Date(timeIntervalSince1970: 1_780_000_010)
        )
        let handle = try FileHandle(forWritingTo: service.queueURL)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: Data("not-json\n".utf8))

        let report = service.report(generatedAt: Date(timeIntervalSince1970: 1_780_000_100))
        #expect(report.pendingCount == 3)
        #expect(report.uniquePendingCount == 2)
        #expect(report.duplicatePendingCount == 1)
        #expect(report.invalidLineCount == 1)
        #expect(report.sourceCounts["duplicate-instance"] == 2)
        #expect(report.sourceCounts["open-url"] == 1)
        #expect(report.duplicatePaths == [first.standardizedFileURL.path])
        #expect(report.items.map(\.path) == [
            first.standardizedFileURL.path,
            duplicate.standardizedFileURL.path,
            second.standardizedFileURL.path
        ])

        let csv = ExternalExecutableOpenQueueService.csv(report: report)
        #expect(csv.contains("row_type,id,source,enqueued_at,path,pending_count,unique_pending_count,duplicate_pending_count,invalid_line_count"))
        #expect(csv.contains("summary,,,2026-05-28T20:28:20Z,,3,2,1,1"))
        #expect(csv.contains("duplicate-instance"))
        #expect(csv.contains("duplicate,,"))
        #expect(csv.contains("工具.EXE"))

        let log = ExternalExecutableOpenQueueService.diagnosticLogText(report: report)
        #expect(log.contains("status=attention"))
        #expect(log.contains("pendingCount=3"))
        #expect(log.contains("duplicatePendingCount=1"))
        #expect(log.contains("invalidLineCount=1"))
        #expect(log.contains("sourceCount source=duplicate-instance count=2"))
    }
}
