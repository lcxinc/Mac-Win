import Foundation

public struct ExternalExecutableOpenQueueItem: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var path: String
    public var source: String
    public var enqueuedAt: Date

    public init(id: UUID = UUID(), path: String, source: String, enqueuedAt: Date = Date()) {
        self.id = id
        self.path = path
        self.source = source
        self.enqueuedAt = enqueuedAt
    }
}

public struct ExternalExecutableOpenQueueReport: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var queuePath: String
    public var logPath: String
    public var pendingCount: Int
    public var uniquePendingCount: Int
    public var duplicatePendingCount: Int
    public var invalidLineCount: Int
    public var sourceCounts: [String: Int]
    public var duplicatePaths: [String]
    public var items: [ExternalExecutableOpenQueueItem]

    public init(
        generatedAt: Date,
        queuePath: String,
        logPath: String,
        pendingCount: Int,
        uniquePendingCount: Int,
        duplicatePendingCount: Int,
        invalidLineCount: Int,
        sourceCounts: [String: Int],
        duplicatePaths: [String],
        items: [ExternalExecutableOpenQueueItem]
    ) {
        self.generatedAt = generatedAt
        self.queuePath = queuePath
        self.logPath = logPath
        self.pendingCount = pendingCount
        self.uniquePendingCount = uniquePendingCount
        self.duplicatePendingCount = duplicatePendingCount
        self.invalidLineCount = invalidLineCount
        self.sourceCounts = sourceCounts
        self.duplicatePaths = duplicatePaths
        self.items = items
    }
}

public struct ExternalExecutableOpenQueueService {
    public var paths: MacWinPaths
    public var fileManager: FileManager

    public init(paths: MacWinPaths = MacWinPaths(), fileManager: FileManager = .default) {
        self.paths = paths
        self.fileManager = fileManager
    }

    public var queueURL: URL {
        paths.externalOpenQueueDirectory.appendingPathComponent("requests.jsonl")
    }

    public var logURL: URL {
        paths.logsDirectory.appendingPathComponent("external-open-queue.log")
    }

    @discardableResult
    public func enqueue(
        urls: [URL],
        source: String,
        enqueuedAt: Date = Date()
    ) throws -> [ExternalExecutableOpenQueueItem] {
        let executableURLs = urls
            .map(\.standardizedFileURL)
            .filter { $0.pathExtension.lowercased() == "exe" }
        guard !executableURLs.isEmpty else { return [] }

        try paths.ensureBaseDirectories(fileManager: fileManager)
        if !fileManager.fileExists(atPath: queueURL.path) {
            fileManager.createFile(atPath: queueURL.path, contents: nil)
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let handle = try FileHandle(forWritingTo: queueURL)
        defer { try? handle.close() }
        try handle.seekToEnd()

        var seenPaths = Set(queuedItemsPreservingDuplicates().items.map(\.path))
        let items = executableURLs.compactMap { url -> ExternalExecutableOpenQueueItem? in
            guard seenPaths.insert(url.path).inserted else { return nil }
            return ExternalExecutableOpenQueueItem(
                path: url.path,
                source: source,
                enqueuedAt: enqueuedAt
            )
        }
        guard !items.isEmpty else { return [] }
        for item in items {
            var data = try encoder.encode(item)
            data.append(0x0A)
            try handle.write(contentsOf: data)
        }

        try appendLog(event: "enqueue", items: items, at: enqueuedAt)
        return items
    }

    @discardableResult
    public func drain(at drainedAt: Date = Date()) throws -> [ExternalExecutableOpenQueueItem] {
        guard let data = try? Data(contentsOf: queueURL), !data.isEmpty else { return [] }
        try? fileManager.removeItem(at: queueURL)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var seen = Set<String>()
        let items = String(decoding: data, as: UTF8.self)
            .split(whereSeparator: \.isNewline)
            .compactMap { line -> ExternalExecutableOpenQueueItem? in
                guard let lineData = String(line).data(using: .utf8),
                      var item = try? decoder.decode(ExternalExecutableOpenQueueItem.self, from: lineData) else {
                    return nil
                }
                item.path = URL(fileURLWithPath: item.path).standardizedFileURL.path
                guard item.path.lowercased().hasSuffix(".exe") else { return nil }
                guard seen.insert(item.path).inserted else { return nil }
                return item
            }

        if !items.isEmpty {
            try paths.ensureBaseDirectories(fileManager: fileManager)
            try appendLog(event: "drain", items: items, at: drainedAt)
        }
        return items
    }

    public func drainURLs(at drainedAt: Date = Date()) throws -> [URL] {
        try drain(at: drainedAt).map { URL(fileURLWithPath: $0.path) }
    }

    public func report(generatedAt: Date = Date()) -> ExternalExecutableOpenQueueReport {
        let parsed = queuedItemsPreservingDuplicates()
        let pathCounts = Dictionary(grouping: parsed.items, by: \.path).mapValues(\.count)
        let duplicatePaths = pathCounts
            .filter { $0.value > 1 }
            .map(\.key)
            .sorted()
        let duplicateCount = pathCounts.values.reduce(0) { result, count in
            result + max(0, count - 1)
        }
        return ExternalExecutableOpenQueueReport(
            generatedAt: generatedAt,
            queuePath: queueURL.path,
            logPath: logURL.path,
            pendingCount: parsed.items.count,
            uniquePendingCount: pathCounts.count,
            duplicatePendingCount: duplicateCount,
            invalidLineCount: parsed.invalidLineCount,
            sourceCounts: Dictionary(grouping: parsed.items, by: \.source).mapValues(\.count),
            duplicatePaths: duplicatePaths,
            items: parsed.items
        )
    }

    public static func executableURLs(fromCommandLineArguments arguments: [String]) -> [URL] {
        arguments.dropFirst().compactMap { argument -> URL? in
            let url: URL
            if argument.hasPrefix("file://"), let fileURL = URL(string: argument) {
                url = fileURL
            } else {
                url = URL(fileURLWithPath: argument)
            }
            guard url.pathExtension.lowercased() == "exe" else { return nil }
            return url
        }
    }

    public static func csv(report: ExternalExecutableOpenQueueReport) -> String {
        var rows: [[String]] = [[
            "row_type",
            "id",
            "source",
            "enqueued_at",
            "path",
            "pending_count",
            "unique_pending_count",
            "duplicate_pending_count",
            "invalid_line_count"
        ]]

        rows.append([
            "summary",
            "",
            "",
            iso8601String(report.generatedAt),
            "",
            String(report.pendingCount),
            String(report.uniquePendingCount),
            String(report.duplicatePendingCount),
            String(report.invalidLineCount)
        ])

        for item in report.items {
            rows.append([
                "item",
                item.id.uuidString,
                item.source,
                iso8601String(item.enqueuedAt),
                item.path,
                "",
                "",
                "",
                ""
            ])
        }

        for path in report.duplicatePaths {
            rows.append([
                "duplicate",
                "",
                "",
                "",
                path,
                "",
                "",
                "",
                ""
            ])
        }

        return rows.map { $0.map(csvEscaped).joined(separator: ",") }.joined(separator: "\n")
    }

    public static func diagnosticLogText(report: ExternalExecutableOpenQueueReport) -> String {
        var lines = [
            "----- MacWin external executable open queue -----",
            "generatedAt=\(iso8601String(report.generatedAt))",
            "queuePath=\(report.queuePath)",
            "logPath=\(report.logPath)",
            "pendingCount=\(report.pendingCount)",
            "uniquePendingCount=\(report.uniquePendingCount)",
            "duplicatePendingCount=\(report.duplicatePendingCount)",
            "invalidLineCount=\(report.invalidLineCount)"
        ]

        if report.pendingCount == 0, report.invalidLineCount == 0 {
            lines.append("status=ok")
        } else if report.duplicatePendingCount > 0 || report.invalidLineCount > 0 {
            lines.append("status=attention")
        } else {
            lines.append("status=pending")
        }

        for source in report.sourceCounts.keys.sorted() {
            lines.append("sourceCount source=\(source) count=\(report.sourceCounts[source] ?? 0)")
        }
        for path in report.duplicatePaths {
            lines.append("duplicatePath=\(path)")
        }
        for item in report.items {
            lines.append("item id=\(item.id.uuidString) at=\(iso8601String(item.enqueuedAt)) source=\(item.source) path=\(item.path)")
        }

        lines.append("-------------------------------------------------")
        lines.append("")
        return lines.joined(separator: "\n")
    }

    private func queuedItemsPreservingDuplicates() -> (items: [ExternalExecutableOpenQueueItem], invalidLineCount: Int) {
        guard let data = try? Data(contentsOf: queueURL), !data.isEmpty else {
            return ([], 0)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var invalidLineCount = 0
        let items = String(decoding: data, as: UTF8.self)
            .split(whereSeparator: \.isNewline)
            .compactMap { line -> ExternalExecutableOpenQueueItem? in
                guard let lineData = String(line).data(using: .utf8),
                      var item = try? decoder.decode(ExternalExecutableOpenQueueItem.self, from: lineData) else {
                    invalidLineCount += 1
                    return nil
                }
                item.path = URL(fileURLWithPath: item.path).standardizedFileURL.path
                guard item.path.lowercased().hasSuffix(".exe") else {
                    invalidLineCount += 1
                    return nil
                }
                return item
            }
        return (items, invalidLineCount)
    }

    private func appendLog(
        event: String,
        items: [ExternalExecutableOpenQueueItem],
        at date: Date
    ) throws {
        guard !items.isEmpty else { return }
        try fileManager.createDirectory(at: logURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if !fileManager.fileExists(atPath: logURL.path) {
            fileManager.createFile(atPath: logURL.path, contents: nil)
        }
        let formatter = ISO8601DateFormatter()
        let handle = try FileHandle(forWritingTo: logURL)
        defer { try? handle.close() }
        try handle.seekToEnd()
        for item in items {
            let line = [
                "event=\(event)",
                "at=\(formatter.string(from: date))",
                "source=\(item.source)",
                "path=\(item.path)"
            ].joined(separator: " ")
            try handle.write(contentsOf: Data((line + "\n").utf8))
        }
    }

    private static func iso8601String(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private static func csvEscaped(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
