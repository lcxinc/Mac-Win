import Foundation

public enum DiagnosticRunScope: String, Codable, Equatable, Sendable {
    case suite
    case probe
    case batch
}

public struct DiagnosticRunItemSummary: Codable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var category: DiagnosticCategory
    public var status: DiagnosticStatus
    public var detail: String
}

public struct DiagnosticRunRecord: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var scope: DiagnosticRunScope
    public var assetId: String?
    public var assetIds: [String]
    public var engineId: String
    public var bottleId: String
    public var logPath: String
    public var startedAt: Date
    public var endedAt: Date
    public var durationSeconds: Double
    public var exitCode: Int32
    public var timedOut: Bool
    public var totalItemCount: Int
    public var passedItemCount: Int
    public var failedItemCount: Int
    public var skippedItemCount: Int
    public var notObservedItemCount: Int
    public var items: [DiagnosticRunItemSummary]
}

public struct DiagnosticHistoryReport: Codable, Equatable, Sendable {
    public var rootPath: String
    public var recordsPath: String
    public var totalRunCount: Int
    public var passedRunCount: Int
    public var failedRunCount: Int
    public var timedOutRunCount: Int
    public var latestRunAt: Date?
    public var records: [DiagnosticRunRecord]

    public init(rootPath: String, recordsPath: String, records: [DiagnosticRunRecord]) {
        self.rootPath = rootPath
        self.recordsPath = recordsPath
        self.totalRunCount = records.count
        self.passedRunCount = records.filter { $0.exitCode == 0 && !$0.timedOut }.count
        self.failedRunCount = records.filter { $0.exitCode != 0 && !$0.timedOut }.count
        self.timedOutRunCount = records.filter(\.timedOut).count
        self.latestRunAt = records.map(\.endedAt).max()
        self.records = records
    }

    public static func csv(report: DiagnosticHistoryReport?) -> String {
        let formatter = ISO8601DateFormatter()
        var rows: [[String]] = [[
            "record_type",
            "run_id",
            "scope",
            "asset_id",
            "asset_ids",
            "engine_id",
            "bottle_id",
            "exit_code",
            "timed_out",
            "started_at",
            "ended_at",
            "duration_seconds",
            "item_id",
            "item_name",
            "category",
            "status",
            "detail",
            "passed_count",
            "failed_count",
            "skipped_count",
            "not_observed_count",
            "log_path"
        ]]
        for record in report?.records ?? [] {
            rows.append([
                "run",
                record.id,
                record.scope.rawValue,
                record.assetId ?? "",
                record.assetIds.joined(separator: ";"),
                record.engineId,
                record.bottleId,
                String(record.exitCode),
                record.timedOut ? "true" : "false",
                formatter.string(from: record.startedAt),
                formatter.string(from: record.endedAt),
                String(format: "%.3f", record.durationSeconds),
                "",
                "",
                "",
                "",
                "",
                String(record.passedItemCount),
                String(record.failedItemCount),
                String(record.skippedItemCount),
                String(record.notObservedItemCount),
                record.logPath
            ])
            for item in record.items {
                rows.append([
                    "item",
                    record.id,
                    record.scope.rawValue,
                    record.assetId ?? "",
                    record.assetIds.joined(separator: ";"),
                    record.engineId,
                    record.bottleId,
                    "",
                    "",
                    "",
                    "",
                    "",
                    item.id,
                    item.name,
                    item.category.rawValue,
                    item.status.rawValue,
                    item.detail,
                    "",
                    "",
                    "",
                    "",
                    record.logPath
                ])
            }
        }
        return rows
            .map { $0.map(csvEscaped).joined(separator: ",") }
            .joined(separator: "\n")
    }

    private static func csvEscaped(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}

public struct DiagnosticsHistoryService {
    public var paths: MacWinPaths
    public var fileManager: FileManager

    public init(paths: MacWinPaths = MacWinPaths(), fileManager: FileManager = .default) {
        self.paths = paths
        self.fileManager = fileManager
    }

    public var recordsDirectory: URL {
        paths.logsDirectory.appendingPathComponent("DiagnosticRecords", isDirectory: true)
    }

    @discardableResult
    public func save(
        report: DiagnosticReport,
        scope: DiagnosticRunScope,
        engine: EngineManifest,
        bottle: BottleManifest,
        assetId: String? = nil,
        assetIds: [String] = [],
        endedAt: Date = Date()
    ) throws -> DiagnosticRunRecord {
        try paths.ensureBaseDirectories(fileManager: fileManager)
        try fileManager.createDirectory(at: recordsDirectory, withIntermediateDirectories: true)
        let duration = max(report.durationSeconds, 0)
        let startedAt = endedAt.addingTimeInterval(-duration)
        let record = Self.record(
            report: report,
            scope: scope,
            engine: engine,
            bottle: bottle,
            assetId: assetId,
            assetIds: assetIds,
            startedAt: startedAt,
            endedAt: endedAt
        )
        try JSONStore(fileManager: fileManager).save(
            record,
            to: recordsDirectory.appendingPathComponent("\(Self.safeFileName(record.id)).diagnostic.json")
        )
        return record
    }

    public func report(limit: Int = 100) -> DiagnosticHistoryReport {
        guard fileManager.fileExists(atPath: recordsDirectory.path),
              let contents = try? fileManager.contentsOfDirectory(
                at: recordsDirectory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
              ) else {
            return DiagnosticHistoryReport(rootPath: paths.root.path, recordsPath: recordsDirectory.path, records: [])
        }
        let store = JSONStore(fileManager: fileManager)
        let records = contents
            .filter { $0.pathExtension == "json" && $0.lastPathComponent.hasSuffix(".diagnostic.json") }
            .compactMap { try? store.load(DiagnosticRunRecord.self, from: $0) }
            .sorted { lhs, rhs in
                if lhs.endedAt != rhs.endedAt {
                    return lhs.endedAt > rhs.endedAt
                }
                return lhs.id < rhs.id
            }
        return DiagnosticHistoryReport(
            rootPath: paths.root.path,
            recordsPath: recordsDirectory.path,
            records: Array(records.prefix(limit))
        )
    }

    private static func record(
        report: DiagnosticReport,
        scope: DiagnosticRunScope,
        engine: EngineManifest,
        bottle: BottleManifest,
        assetId: String?,
        assetIds: [String],
        startedAt: Date,
        endedAt: Date
    ) -> DiagnosticRunRecord {
        let statusCounts = Dictionary(grouping: report.items, by: \.status).mapValues(\.count)
        let effectiveAssetIds = assetId.map { [$0] } ?? assetIds
        return DiagnosticRunRecord(
            id: "\(fileTimestamp(endedAt))-\(scope.rawValue)-\(UUID().uuidString.prefix(8).lowercased())",
            scope: scope,
            assetId: assetId,
            assetIds: effectiveAssetIds,
            engineId: engine.id,
            bottleId: bottle.id,
            logPath: report.logURL.path,
            startedAt: startedAt,
            endedAt: endedAt,
            durationSeconds: max(report.durationSeconds, 0),
            exitCode: report.exitCode,
            timedOut: report.timedOut,
            totalItemCount: report.items.count,
            passedItemCount: statusCounts[.passed, default: 0],
            failedItemCount: statusCounts[.failed, default: 0],
            skippedItemCount: statusCounts[.skipped, default: 0],
            notObservedItemCount: statusCounts[.notObserved, default: 0],
            items: report.items.map {
                DiagnosticRunItemSummary(
                    id: $0.id,
                    name: $0.name,
                    category: $0.category,
                    status: $0.status,
                    detail: $0.detail
                )
            }
        )
    }

    private static func safeFileName(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        let scalars = value.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let safe = scalars.reduce(into: "") { $0.append($1) }
        return safe.isEmpty ? "diagnostic" : safe
    }

    private static func fileTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: date)
    }
}
