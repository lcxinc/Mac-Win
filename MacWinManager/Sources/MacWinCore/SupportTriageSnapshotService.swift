import Foundation

public struct SupportTriageSnapshotResult: Equatable, Sendable {
    public var jsonURL: URL
    public var csvURL: URL
    public var markdownURL: URL
    public var latestJSONURL: URL
    public var latestCSVURL: URL
    public var latestMarkdownURL: URL

    public init(
        jsonURL: URL,
        csvURL: URL,
        markdownURL: URL,
        latestJSONURL: URL,
        latestCSVURL: URL,
        latestMarkdownURL: URL
    ) {
        self.jsonURL = jsonURL
        self.csvURL = csvURL
        self.markdownURL = markdownURL
        self.latestJSONURL = latestJSONURL
        self.latestCSVURL = latestCSVURL
        self.latestMarkdownURL = latestMarkdownURL
    }
}

public struct SupportTriageSnapshotService {
    public var paths: MacWinPaths
    public var fileManager: FileManager

    public init(paths: MacWinPaths = MacWinPaths(), fileManager: FileManager = .default) {
        self.paths = paths
        self.fileManager = fileManager
    }

    public func export(report: SupportTriageReport, generatedAt: Date = Date()) throws -> SupportTriageSnapshotResult {
        try paths.ensureBaseDirectories(fileManager: fileManager)
        let timestamp = Self.fileTimestamp(generatedAt)
        let jsonURL = paths.logsDirectory.appendingPathComponent("support-triage-\(timestamp).json")
        let csvURL = paths.logsDirectory.appendingPathComponent("support-triage-\(timestamp).csv")
        let markdownURL = paths.logsDirectory.appendingPathComponent("support-triage-\(timestamp).md")
        let latestJSONURL = paths.logsDirectory.appendingPathComponent("support-triage-latest.json")
        let latestCSVURL = paths.logsDirectory.appendingPathComponent("support-triage-latest.csv")
        let latestMarkdownURL = paths.logsDirectory.appendingPathComponent("support-triage-latest.md")

        let jsonData = try Self.encodeJSON(report)
        let csvData = Data(SupportTriageReport.csv(report: report).utf8)
        let markdownData = Data(SupportTriageReport.markdown(report: report).utf8)

        try jsonData.write(to: jsonURL, options: [.atomic])
        try jsonData.write(to: latestJSONURL, options: [.atomic])
        try csvData.write(to: csvURL, options: [.atomic])
        try csvData.write(to: latestCSVURL, options: [.atomic])
        try markdownData.write(to: markdownURL, options: [.atomic])
        try markdownData.write(to: latestMarkdownURL, options: [.atomic])

        return SupportTriageSnapshotResult(
            jsonURL: jsonURL,
            csvURL: csvURL,
            markdownURL: markdownURL,
            latestJSONURL: latestJSONURL,
            latestCSVURL: latestCSVURL,
            latestMarkdownURL: latestMarkdownURL
        )
    }

    private static func encodeJSON<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(value)
    }

    private static func fileTimestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter.string(from: date).replacingOccurrences(of: ":", with: "")
    }
}
