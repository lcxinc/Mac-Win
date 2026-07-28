import Foundation

public enum SoftwareCollectionAction: String, Codable, Equatable, Sendable {
    case exportCSV
    case exportDownloadScript
    case exportAcceptanceRunbook
    case exportBundle
    case downloadMissingInstallers
}

public enum SoftwareCollectionActionState: String, Codable, Equatable, Sendable {
    case succeeded
    case failed
}

public struct SoftwareCollectionActionRecord: Codable, Equatable, Identifiable, Sendable {
    public var schemaVersion: Int
    public var id: String
    public var action: SoftwareCollectionAction
    public var state: SoftwareCollectionActionState
    public var startedAt: Date
    public var endedAt: Date
    public var durationMilliseconds: Int
    public var collectionCount: Int
    public var recipeCount: Int
    public var missingRecipeCount: Int
    public var missingInstallerCount: Int
    public var actionRequiredCount: Int
    public var recipeIds: [String]
    public var completedRecipeIds: [String]
    public var outputPath: String?
    public var errorMessage: String?

    public init(
        schemaVersion: Int = 1,
        id: String = UUID().uuidString,
        action: SoftwareCollectionAction,
        state: SoftwareCollectionActionState,
        startedAt: Date,
        endedAt: Date,
        collectionCount: Int,
        recipeCount: Int,
        missingRecipeCount: Int,
        missingInstallerCount: Int,
        actionRequiredCount: Int,
        recipeIds: [String],
        completedRecipeIds: [String] = [],
        outputPath: String? = nil,
        errorMessage: String? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.action = action
        self.state = state
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationMilliseconds = max(0, Int(endedAt.timeIntervalSince(startedAt) * 1000))
        self.collectionCount = collectionCount
        self.recipeCount = recipeCount
        self.missingRecipeCount = missingRecipeCount
        self.missingInstallerCount = missingInstallerCount
        self.actionRequiredCount = actionRequiredCount
        self.recipeIds = recipeIds
        self.completedRecipeIds = completedRecipeIds
        self.outputPath = outputPath
        self.errorMessage = errorMessage
    }
}

public struct SoftwareCollectionHistoryReport: Codable, Equatable, Sendable {
    public var rootPath: String
    public var recordsPath: String
    public var totalRecordCount: Int
    public var succeededCount: Int
    public var failedCount: Int
    public var downloadActionCount: Int
    public var exportActionCount: Int
    public var stateCounts: [String: Int]
    public var actionCounts: [String: Int]
    public var latestStartedAt: Date?
    public var records: [SoftwareCollectionActionRecord]

    public init(rootPath: String, recordsPath: String, records: [SoftwareCollectionActionRecord]) {
        self.rootPath = rootPath
        self.recordsPath = recordsPath
        self.totalRecordCount = records.count
        self.succeededCount = records.filter { $0.state == .succeeded }.count
        self.failedCount = records.filter { $0.state == .failed }.count
        self.downloadActionCount = records.filter { $0.action == .downloadMissingInstallers }.count
        self.exportActionCount = records.filter {
            $0.action == .exportCSV || $0.action == .exportDownloadScript || $0.action == .exportBundle
        }.count
        self.stateCounts = Dictionary(grouping: records, by: { $0.state.rawValue }).mapValues(\.count)
        self.actionCounts = Dictionary(grouping: records, by: { $0.action.rawValue }).mapValues(\.count)
        self.latestStartedAt = records.first?.startedAt
        self.records = records
    }
}

public struct SoftwareCollectionHistoryService {
    public var paths: MacWinPaths
    public var fileManager: FileManager

    public init(paths: MacWinPaths = MacWinPaths(), fileManager: FileManager = .default) {
        self.paths = paths
        self.fileManager = fileManager
    }

    public func report(limit: Int = 100) -> SoftwareCollectionHistoryReport {
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
        return SoftwareCollectionHistoryReport(
            rootPath: paths.root.path,
            recordsPath: directory.path,
            records: records
        )
    }

    public func save(_ record: SoftwareCollectionActionRecord) throws {
        try fileManager.createDirectory(at: Self.recordsDirectory(in: paths.logsDirectory), withIntermediateDirectories: true)
        try JSONStore(fileManager: fileManager).save(record, to: recordURL(for: record))
    }

    public static func record(
        action: SoftwareCollectionAction,
        state: SoftwareCollectionActionState,
        collection: SoftwareCollectionReport,
        startedAt: Date,
        endedAt: Date,
        recipeIds: [String]? = nil,
        completedRecipeIds: [String] = [],
        outputPath: String? = nil,
        errorMessage: String? = nil
    ) -> SoftwareCollectionActionRecord {
        SoftwareCollectionActionRecord(
            action: action,
            state: state,
            startedAt: startedAt,
            endedAt: endedAt,
            collectionCount: collection.collectionCount,
            recipeCount: collection.recipeCount,
            missingRecipeCount: collection.missingRecipeCount,
            missingInstallerCount: collection.missingInstallerCount,
            actionRequiredCount: collection.actionRequiredCount,
            recipeIds: recipeIds ?? collection.entries.map(\.recipeId),
            completedRecipeIds: completedRecipeIds,
            outputPath: outputPath,
            errorMessage: errorMessage
        )
    }

    public static func csv(report: SoftwareCollectionHistoryReport) -> String {
        let formatter = ISO8601DateFormatter()
        var rows: [[String]] = [[
            "id",
            "action",
            "state",
            "started_at",
            "ended_at",
            "duration_ms",
            "collection_count",
            "recipe_count",
            "missing_recipe_count",
            "missing_installer_count",
            "action_required_count",
            "recipe_ids",
            "completed_recipe_ids",
            "output_path",
            "error_message"
        ]]

        for record in report.records {
            rows.append([
                record.id,
                record.action.rawValue,
                record.state.rawValue,
                formatter.string(from: record.startedAt),
                formatter.string(from: record.endedAt),
                String(record.durationMilliseconds),
                String(record.collectionCount),
                String(record.recipeCount),
                String(record.missingRecipeCount),
                String(record.missingInstallerCount),
                String(record.actionRequiredCount),
                record.recipeIds.joined(separator: ";"),
                record.completedRecipeIds.joined(separator: ";"),
                record.outputPath ?? "",
                record.errorMessage ?? ""
            ])
        }

        return rows.map { $0.map(csvEscaped).joined(separator: ",") }.joined(separator: "\n")
    }

    public func recordURL(for record: SoftwareCollectionActionRecord) -> URL {
        Self.recordURL(record: record, logsDirectory: paths.logsDirectory)
    }

    public static func recordsDirectory(in logsDirectory: URL) -> URL {
        logsDirectory.appendingPathComponent("SoftwareCollectionRecords", isDirectory: true)
    }

    public static func recordURL(record: SoftwareCollectionActionRecord, logsDirectory: URL) -> URL {
        let name = "\(fileTimestamp(record.startedAt))-\(safeFileName(record.action.rawValue))-\(safeFileName(record.id)).software-collection.json"
        return recordsDirectory(in: logsDirectory).appendingPathComponent(name)
    }

    private func readRecords(in directory: URL) -> [SoftwareCollectionActionRecord] {
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
            guard url.lastPathComponent.hasSuffix(".software-collection.json"),
                  (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else {
                return nil
            }
            return try? store.load(SoftwareCollectionActionRecord.self, from: url)
        }
    }

    private static func safeFileName(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        let mapped = value.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let name = String(mapped).split(separator: "-").joined(separator: "-")
        return name.isEmpty ? "software-collection" : name
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
