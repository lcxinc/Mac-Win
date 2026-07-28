import Foundation

public enum InstallerDownloadState: String, Codable, Equatable, Sendable {
    case cached
    case downloaded
    case hashMismatch
    case failed
}

public struct InstallerDownloadRecord: Codable, Equatable, Identifiable, Sendable {
    public var schemaVersion: Int
    public var id: String
    public var recipeId: String
    public var recipeName: String
    public var fileName: String
    public var sourceURL: String
    public var destinationPath: String
    public var startedAt: Date
    public var endedAt: Date
    public var durationMilliseconds: Int
    public var state: InstallerDownloadState
    public var expectedSha256: String?
    public var actualSha256: String?
    public var byteCount: Int64?
    public var usedCachedFile: Bool
    public var errorMessage: String?

    public init(
        schemaVersion: Int = 1,
        id: String = UUID().uuidString,
        recipeId: String,
        recipeName: String,
        fileName: String,
        sourceURL: String,
        destinationPath: String,
        startedAt: Date,
        endedAt: Date,
        state: InstallerDownloadState,
        expectedSha256: String? = nil,
        actualSha256: String? = nil,
        byteCount: Int64? = nil,
        usedCachedFile: Bool = false,
        errorMessage: String? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.recipeId = recipeId
        self.recipeName = recipeName
        self.fileName = fileName
        self.sourceURL = sourceURL
        self.destinationPath = destinationPath
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationMilliseconds = max(0, Int(endedAt.timeIntervalSince(startedAt) * 1000))
        self.state = state
        self.expectedSha256 = expectedSha256
        self.actualSha256 = actualSha256
        self.byteCount = byteCount
        self.usedCachedFile = usedCachedFile
        self.errorMessage = errorMessage
    }
}

public struct InstallerDownloadHistoryReport: Codable, Equatable, Sendable {
    public var rootPath: String
    public var recordsPath: String
    public var totalRecordCount: Int
    public var cachedCount: Int
    public var downloadedCount: Int
    public var hashMismatchCount: Int
    public var failedCount: Int
    public var stateCounts: [String: Int]
    public var latestStartedAt: Date?
    public var records: [InstallerDownloadRecord]

    public init(rootPath: String, recordsPath: String, records: [InstallerDownloadRecord]) {
        self.rootPath = rootPath
        self.recordsPath = recordsPath
        self.totalRecordCount = records.count
        self.cachedCount = records.filter { $0.state == .cached }.count
        self.downloadedCount = records.filter { $0.state == .downloaded }.count
        self.hashMismatchCount = records.filter { $0.state == .hashMismatch }.count
        self.failedCount = records.filter { $0.state == .failed }.count
        self.stateCounts = Dictionary(grouping: records, by: { $0.state.rawValue }).mapValues(\.count)
        self.latestStartedAt = records.first?.startedAt
        self.records = records
    }
}

public struct InstallerDownloadHistoryService {
    public var paths: MacWinPaths
    public var fileManager: FileManager

    public init(paths: MacWinPaths = MacWinPaths(), fileManager: FileManager = .default) {
        self.paths = paths
        self.fileManager = fileManager
    }

    public func report(limit: Int = 100) -> InstallerDownloadHistoryReport {
        let directory = Self.recordsDirectory(in: paths.logsDirectory)
        var records = readRecords(in: directory)
        records.sort { lhs, rhs in
            if lhs.startedAt == rhs.startedAt {
                return lhs.id > rhs.id
            }
            return lhs.startedAt > rhs.startedAt
        }
        if records.count > limit {
            records = Array(records.prefix(limit))
        }
        return InstallerDownloadHistoryReport(
            rootPath: paths.root.path,
            recordsPath: directory.path,
            records: records
        )
    }

    public func save(_ record: InstallerDownloadRecord) throws {
        try fileManager.createDirectory(at: Self.recordsDirectory(in: paths.logsDirectory), withIntermediateDirectories: true)
        try JSONStore(fileManager: fileManager).save(record, to: recordURL(for: record))
    }

    public static func csv(report: InstallerDownloadHistoryReport) -> String {
        let formatter = ISO8601DateFormatter()
        var rows: [[String]] = [[
            "id",
            "recipe_id",
            "recipe_name",
            "file_name",
            "state",
            "used_cached_file",
            "started_at",
            "ended_at",
            "duration_ms",
            "byte_count",
            "expected_sha256",
            "actual_sha256",
            "source_url",
            "destination_path",
            "error_message"
        ]]

        for record in report.records {
            rows.append([
                record.id,
                record.recipeId,
                record.recipeName,
                record.fileName,
                record.state.rawValue,
                record.usedCachedFile ? "true" : "false",
                formatter.string(from: record.startedAt),
                formatter.string(from: record.endedAt),
                String(record.durationMilliseconds),
                record.byteCount.map(String.init) ?? "",
                record.expectedSha256 ?? "",
                record.actualSha256 ?? "",
                record.sourceURL,
                record.destinationPath,
                record.errorMessage ?? ""
            ])
        }

        return rows
            .map { $0.map(csvEscaped).joined(separator: ",") }
            .joined(separator: "\n")
    }

    public func recordURL(for record: InstallerDownloadRecord) -> URL {
        Self.recordURL(record: record, logsDirectory: paths.logsDirectory)
    }

    public static func recordsDirectory(in logsDirectory: URL) -> URL {
        logsDirectory.appendingPathComponent("InstallerDownloadRecords", isDirectory: true)
    }

    public static func recordURL(record: InstallerDownloadRecord, logsDirectory: URL) -> URL {
        let name = "\(fileTimestamp(record.startedAt))-\(safeFileName(record.recipeId))-\(safeFileName(record.id)).installer-download.json"
        return recordsDirectory(in: logsDirectory).appendingPathComponent(name)
    }

    private func readRecords(in directory: URL) -> [InstallerDownloadRecord] {
        guard fileManager.fileExists(atPath: directory.path),
              let urls = try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
              ) else {
            return []
        }

        let store = JSONStore(fileManager: fileManager)
        return urls.compactMap { url in
            guard url.lastPathComponent.hasSuffix(".installer-download.json"),
                  (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else {
                return nil
            }
            return try? store.load(InstallerDownloadRecord.self, from: url)
        }
    }

    private static func safeFileName(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        let mapped = value.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let name = String(mapped).split(separator: "-").joined(separator: "-")
        return name.isEmpty ? "download" : name
    }

    private static func fileTimestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter.string(from: date).replacingOccurrences(of: ":", with: "")
    }

    private static func csvEscaped(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
