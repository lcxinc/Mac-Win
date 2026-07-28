import Foundation

public enum LaunchHealthStatus: String, Codable, Equatable, Sendable {
    case failed
    case attention
    case passed
    case unknown
}

public struct LaunchHealthEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var status: LaunchHealthStatus
    public var displayName: String
    public var bottleId: String?
    public var bottleName: String?
    public var engineId: String?
    public var exe: String?
    public var launchCount: Int
    public var completedLaunchCount: Int
    public var failedToLaunchCount: Int
    public var runningLaunchCount: Int
    public var nonZeroExitCount: Int
    public var logCount: Int
    public var failedLogCount: Int
    public var attentionLogCount: Int
    public var passedLogCount: Int
    public var latestStartedAt: Date?
    public var latestEndedAt: Date?
    public var latestLogModifiedAt: Date?
    public var latestLogPath: String?
    public var latestLaunchRecordId: String?
    public var latestLaunchState: String?
    public var latestExitCode: Int32?
    public var latestLogHealth: String?
    public var hints: [String]
    public var probableIssueIds: [String]
    public var recommendedProbeIds: [String]
    public var logNames: [String]
    public var logPaths: [String]

    public init(
        id: String,
        status: LaunchHealthStatus,
        displayName: String,
        bottleId: String? = nil,
        bottleName: String? = nil,
        engineId: String? = nil,
        exe: String? = nil,
        launchCount: Int,
        completedLaunchCount: Int,
        failedToLaunchCount: Int,
        runningLaunchCount: Int,
        nonZeroExitCount: Int,
        logCount: Int,
        failedLogCount: Int,
        attentionLogCount: Int,
        passedLogCount: Int,
        latestStartedAt: Date? = nil,
        latestEndedAt: Date? = nil,
        latestLogModifiedAt: Date? = nil,
        latestLogPath: String? = nil,
        latestLaunchRecordId: String? = nil,
        latestLaunchState: String? = nil,
        latestExitCode: Int32? = nil,
        latestLogHealth: String? = nil,
        hints: [String],
        probableIssueIds: [String],
        recommendedProbeIds: [String],
        logNames: [String],
        logPaths: [String]
    ) {
        self.id = id
        self.status = status
        self.displayName = displayName
        self.bottleId = bottleId
        self.bottleName = bottleName
        self.engineId = engineId
        self.exe = exe
        self.launchCount = launchCount
        self.completedLaunchCount = completedLaunchCount
        self.failedToLaunchCount = failedToLaunchCount
        self.runningLaunchCount = runningLaunchCount
        self.nonZeroExitCount = nonZeroExitCount
        self.logCount = logCount
        self.failedLogCount = failedLogCount
        self.attentionLogCount = attentionLogCount
        self.passedLogCount = passedLogCount
        self.latestStartedAt = latestStartedAt
        self.latestEndedAt = latestEndedAt
        self.latestLogModifiedAt = latestLogModifiedAt
        self.latestLogPath = latestLogPath
        self.latestLaunchRecordId = latestLaunchRecordId
        self.latestLaunchState = latestLaunchState
        self.latestExitCode = latestExitCode
        self.latestLogHealth = latestLogHealth
        self.hints = hints
        self.probableIssueIds = probableIssueIds
        self.recommendedProbeIds = recommendedProbeIds
        self.logNames = logNames
        self.logPaths = logPaths
    }
}

public struct LaunchHealthReport: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var rootPath: String
    public var entryCount: Int
    public var failedEntryCount: Int
    public var attentionEntryCount: Int
    public var passedEntryCount: Int
    public var unknownEntryCount: Int
    public var launchCount: Int
    public var logCount: Int
    public var logMatchedLaunchCount: Int
    public var entries: [LaunchHealthEntry]

    public init(generatedAt: Date, rootPath: String, logMatchedLaunchCount: Int, entries: [LaunchHealthEntry]) {
        self.generatedAt = generatedAt
        self.rootPath = rootPath
        self.entryCount = entries.count
        self.failedEntryCount = entries.filter { $0.status == .failed }.count
        self.attentionEntryCount = entries.filter { $0.status == .attention }.count
        self.passedEntryCount = entries.filter { $0.status == .passed }.count
        self.unknownEntryCount = entries.filter { $0.status == .unknown }.count
        self.launchCount = entries.map(\.launchCount).reduce(0, +)
        self.logCount = entries.map(\.logCount).reduce(0, +)
        self.logMatchedLaunchCount = logMatchedLaunchCount
        self.entries = entries
    }

    public static func csv(report: LaunchHealthReport) -> String {
        let formatter = ISO8601DateFormatter()
        var rows: [[String]] = [[
            "id",
            "status",
            "display_name",
            "bottle_id",
            "bottle_name",
            "engine_id",
            "exe",
            "launch_count",
            "completed_launch_count",
            "failed_to_launch_count",
            "running_launch_count",
            "non_zero_exit_count",
            "log_count",
            "failed_log_count",
            "attention_log_count",
            "passed_log_count",
            "latest_started_at",
            "latest_ended_at",
            "latest_log_modified_at",
            "latest_log_path",
            "latest_launch_record_id",
            "latest_launch_state",
            "latest_exit_code",
            "latest_log_health",
            "hints",
            "probable_issue_ids",
            "recommended_probe_ids",
            "log_names",
            "log_paths"
        ]]
        for entry in report.entries {
            rows.append([
                entry.id,
                entry.status.rawValue,
                entry.displayName,
                entry.bottleId ?? "",
                entry.bottleName ?? "",
                entry.engineId ?? "",
                entry.exe ?? "",
                String(entry.launchCount),
                String(entry.completedLaunchCount),
                String(entry.failedToLaunchCount),
                String(entry.runningLaunchCount),
                String(entry.nonZeroExitCount),
                String(entry.logCount),
                String(entry.failedLogCount),
                String(entry.attentionLogCount),
                String(entry.passedLogCount),
                entry.latestStartedAt.map { formatter.string(from: $0) } ?? "",
                entry.latestEndedAt.map { formatter.string(from: $0) } ?? "",
                entry.latestLogModifiedAt.map { formatter.string(from: $0) } ?? "",
                entry.latestLogPath ?? "",
                entry.latestLaunchRecordId ?? "",
                entry.latestLaunchState ?? "",
                entry.latestExitCode.map(String.init) ?? "",
                entry.latestLogHealth ?? "",
                entry.hints.joined(separator: ";"),
                entry.probableIssueIds.joined(separator: ";"),
                entry.recommendedProbeIds.joined(separator: ";"),
                entry.logNames.joined(separator: ";"),
                entry.logPaths.joined(separator: ";")
            ])
        }
        return rows.map { $0.map(csvEscaped).joined(separator: ",") }.joined(separator: "\n") + "\n"
    }

    public static func markdown(report: LaunchHealthReport) -> String {
        let formatter = ISO8601DateFormatter()
        var lines = [
            "# MacWin Launch Health",
            "",
            "- Generated: \(formatter.string(from: report.generatedAt))",
            "- Root: `\(markdownEscaped(report.rootPath))`",
            "- Entries: \(report.entryCount)",
            "- Failed: \(report.failedEntryCount)",
            "- Attention: \(report.attentionEntryCount)",
            "- Passed: \(report.passedEntryCount)",
            "- Unknown: \(report.unknownEntryCount)",
            "- Launches: \(report.launchCount)",
            "- Logs: \(report.logCount)",
            "- Launches with matched logs: \(report.logMatchedLaunchCount)",
            "",
            "## Entries",
            ""
        ]
        if report.entries.isEmpty {
            lines.append("No launch records or launch-attributed logs are available.")
        } else {
            for entry in report.entries {
                lines.append("### \(markdownEscaped(entry.displayName))")
                lines.append("")
                lines.append("- Status: `\(entry.status.rawValue)`")
                if let bottleName = entry.bottleName {
                    lines.append("- Bottle: \(markdownEscaped(bottleName)) (`\(markdownEscaped(entry.bottleId ?? ""))`)")
                }
                if let engineId = entry.engineId {
                    lines.append("- Engine: `\(markdownEscaped(engineId))`")
                }
                if let exe = entry.exe {
                    lines.append("- Executable: `\(markdownEscaped(exe))`")
                }
                lines.append("- Launches: \(entry.launchCount) total, \(entry.completedLaunchCount) completed, \(entry.failedToLaunchCount) failed to launch, \(entry.runningLaunchCount) still running, \(entry.nonZeroExitCount) non-zero exits")
                lines.append("- Logs: \(entry.logCount) total, \(entry.failedLogCount) failed, \(entry.attentionLogCount) attention, \(entry.passedLogCount) passed")
                if let latestStartedAt = entry.latestStartedAt {
                    lines.append("- Latest launch: \(formatter.string(from: latestStartedAt))")
                }
                if let latestLogModifiedAt = entry.latestLogModifiedAt {
                    lines.append("- Latest log: \(formatter.string(from: latestLogModifiedAt))")
                }
                if let latestExitCode = entry.latestExitCode {
                    lines.append("- Latest exit code: \(latestExitCode)")
                }
                if let latestLogHealth = entry.latestLogHealth {
                    lines.append("- Latest log health: `\(markdownEscaped(latestLogHealth))`")
                }
                if !entry.hints.isEmpty {
                    lines.append("- Hints: \(entry.hints.map { "`\(markdownEscaped($0))`" }.joined(separator: ", "))")
                }
                if !entry.probableIssueIds.isEmpty {
                    lines.append("- Probable issues: \(entry.probableIssueIds.map { "`\(markdownEscaped($0))`" }.joined(separator: ", "))")
                }
                if !entry.recommendedProbeIds.isEmpty {
                    lines.append("- Recommended probes: \(entry.recommendedProbeIds.map { "`\(markdownEscaped($0))`" }.joined(separator: ", "))")
                }
                if !entry.logNames.isEmpty {
                    lines.append("- Logs: \(entry.logNames.map { "`\(markdownEscaped($0))`" }.joined(separator: ", "))")
                }
                if let latestLogPath = entry.latestLogPath {
                    lines.append("- Latest log path: `\(markdownEscaped(latestLogPath))`")
                }
                lines.append("")
            }
        }
        lines.append("")
        return lines.joined(separator: "\n")
    }

    private static func csvEscaped(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    private static func markdownEscaped(_ value: String) -> String {
        value.replacingOccurrences(of: "`", with: "\\`")
    }
}

public struct LaunchHealthService {
    public var paths: MacWinPaths

    public init(paths: MacWinPaths = MacWinPaths()) {
        self.paths = paths
    }

    public func report(
        launchHistory: LaunchHistoryReport?,
        logs: CapabilityLogReport,
        smokeReports: [SoftwareSmokeRunReport] = [],
        generatedAt: Date = Date()
    ) -> LaunchHealthReport {
        Self.report(
            rootPath: paths.root.path,
            launchHistory: launchHistory,
            logs: logs,
            smokeReports: smokeReports,
            generatedAt: generatedAt
        )
    }

    public static func report(
        rootPath: String,
        launchHistory: LaunchHistoryReport?,
        logs: CapabilityLogReport,
        smokeReports: [SoftwareSmokeRunReport] = [],
        generatedAt: Date = Date()
    ) -> LaunchHealthReport {
        var aggregates: [String: LaunchHealthAggregate] = [:]
        let activeLogs = logs.entries.filter { log in
            !SoftwareSmokeEvidenceResolver.supersedes(
                logName: log.name,
                logPath: log.path,
                modifiedAt: log.modifiedAt,
                reports: smokeReports
            )
        }
        let logsByPath = Dictionary(grouping: activeLogs, by: { canonicalPath($0.path) })
        var consumedLogPaths: Set<String> = []
        var logMatchedLaunchCount = 0

        for record in launchHistory?.records ?? [] {
            let key = groupKey(bottleId: record.bottleId, exe: record.exe)
            var aggregate = aggregates[key] ?? LaunchHealthAggregate(
                id: key,
                displayName: displayName(for: record.exe),
                bottleId: record.bottleId,
                bottleName: record.bottleName,
                engineId: record.engineId,
                exe: record.exe
            )
            aggregate.add(record)
            let matchedLogs = logsByPath[canonicalPath(record.logPath)] ?? []
            if !matchedLogs.isEmpty {
                logMatchedLaunchCount += 1
            }
            for log in matchedLogs {
                aggregate.add(log, issueContext: issueContext(for: log, in: logs.issueReport))
                consumedLogPaths.insert(canonicalPath(log.path))
            }
            aggregates[key] = aggregate
        }

        for log in activeLogs {
            let path = canonicalPath(log.path)
            guard !consumedLogPaths.contains(path) else { continue }
            let context = log.launchContext
            let key: String
            let aggregateTemplate: LaunchHealthAggregate
            if let context {
                key = groupKey(bottleId: context.bottleId, exe: context.exe)
                aggregateTemplate = LaunchHealthAggregate(
                    id: key,
                    displayName: displayName(for: context.exe),
                    bottleId: context.bottleId,
                    bottleName: context.bottleName,
                    engineId: context.engineId,
                    exe: context.exe
                )
            } else {
                key = "log:\(normalized(log.name))"
                aggregateTemplate = LaunchHealthAggregate(
                    id: key,
                    displayName: log.name,
                    bottleId: nil,
                    bottleName: nil,
                    engineId: nil,
                    exe: nil
                )
            }
            var aggregate = aggregates[key] ?? aggregateTemplate
            aggregate.add(log, issueContext: issueContext(for: log, in: logs.issueReport))
            aggregates[key] = aggregate
        }

        let entries = aggregates.values
            .map { $0.entry(generatedAt: generatedAt) }
            .sorted { lhs, rhs in
                if statusRank(lhs.status) != statusRank(rhs.status) {
                    return statusRank(lhs.status) < statusRank(rhs.status)
                }
                let lhsDate = lhs.latestStartedAt ?? lhs.latestLogModifiedAt ?? .distantPast
                let rhsDate = rhs.latestStartedAt ?? rhs.latestLogModifiedAt ?? .distantPast
                if lhsDate != rhsDate {
                    return lhsDate > rhsDate
                }
                return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
            }
        return LaunchHealthReport(
            generatedAt: generatedAt,
            rootPath: rootPath,
            logMatchedLaunchCount: logMatchedLaunchCount,
            entries: entries
        )
    }

    private static func issueContext(for log: CapabilityLogEntry, in report: LogIssueReport) -> LaunchHealthIssueContext {
        let canonical = canonicalPath(log.path)
        let sampleIssues = report.recentFailures.filter { canonicalPath($0.path) == canonical }
        let trendIssues = report.topIssues.filter { $0.affectedLogNames.contains(log.name) }
        return LaunchHealthIssueContext(
            issueIds: orderedUnique(sampleIssues.flatMap(\.probableIssueIds) + trendIssues.map(\.id)),
            probeIds: orderedUnique(sampleIssues.flatMap(\.probeAssetIds) + trendIssues.flatMap(\.probeAssetIds))
        )
    }

    private static func groupKey(bottleId: String, exe: String) -> String {
        "\(normalized(bottleId))|\(normalized(exe))"
    }

    private static func displayName(for exe: String) -> String {
        let path = exe.replacingOccurrences(of: "\\", with: "/")
        let name = URL(fileURLWithPath: path).lastPathComponent
        return name.isEmpty ? exe : name
    }

    private static func canonicalPath(_ path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.path.lowercased()
    }

    private static func normalized(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "\\", with: "/")
            .replacingOccurrences(of: #"[^a-z0-9._/-]+"#, with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private static func orderedUnique(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for value in values where !value.isEmpty && !seen.contains(value) {
            seen.insert(value)
            result.append(value)
        }
        return result.sorted()
    }

    private static func statusRank(_ status: LaunchHealthStatus) -> Int {
        switch status {
        case .failed: 0
        case .attention: 1
        case .passed: 2
        case .unknown: 3
        }
    }
}

private struct LaunchHealthIssueContext {
    var issueIds: [String]
    var probeIds: [String]
}

private struct LaunchHealthAggregate {
    var id: String
    var displayName: String
    var bottleId: String?
    var bottleName: String?
    var engineId: String?
    var exe: String?
    var records: [WineLaunchRecord] = []
    var logs: [CapabilityLogEntry] = []
    var issueContextsByLogPath: [String: LaunchHealthIssueContext] = [:]
    var issueIds: [String] = []
    var probeIds: [String] = []

    mutating func add(_ record: WineLaunchRecord) {
        records.append(record)
        bottleId = bottleId ?? record.bottleId
        bottleName = bottleName ?? record.bottleName
        engineId = engineId ?? record.engineId
        exe = exe ?? record.exe
    }

    mutating func add(_ log: CapabilityLogEntry, issueContext: LaunchHealthIssueContext) {
        logs.append(log)
        issueContextsByLogPath[Self.canonicalPath(log.path)] = issueContext
        if let context = log.launchContext {
            bottleId = bottleId ?? context.bottleId
            bottleName = bottleName ?? context.bottleName
            engineId = engineId ?? context.engineId
            exe = exe ?? context.exe
        }
        issueIds = Self.orderedUnique(issueIds + issueContext.issueIds)
        probeIds = Self.orderedUnique(probeIds + issueContext.probeIds)
    }

    func entry(generatedAt: Date) -> LaunchHealthEntry {
        let latestRecord = records.sorted { lhs, rhs in lhs.startedAt > rhs.startedAt }.first
        let activeLogs = Self.logsExcludingSupersededFailures(logs)
        let latestLog = activeLogs.sorted { lhs, rhs in lhs.modifiedAt > rhs.modifiedAt }.first
        let failedLogs = activeLogs.filter { $0.health == LogHealth.failed.rawValue }.count
        let attentionLogs = activeLogs.filter { $0.health == LogHealth.attention.rawValue }.count
        let passedLogs = activeLogs.filter { $0.health == LogHealth.passed.rawValue }.count
        let activeIssueContexts = activeLogs.compactMap { issueContextsByLogPath[Self.canonicalPath($0.path)] }
        let activeIssueIds = Self.orderedUnique(activeIssueContexts.flatMap(\.issueIds))
        let activeProbeIds = Self.orderedUnique(activeIssueContexts.flatMap(\.probeIds))
        let successfulSmokeLogPaths = Set(activeLogs.filter(Self.isSuccessfulSmokeLog).map { Self.canonicalPath($0.path) })
        let activeRecords = Self.recordsExcludingFailuresSupersededBySuccess(
            records,
            successfulSmokeLogPaths: successfulSmokeLogPaths
        )
        let nonZeroExitCount = activeRecords.filter { record in
            guard (record.exitCode ?? 0) != 0 else { return false }
            return !Self.isControlledSmokeExit(record, successfulSmokeLogPaths: successfulSmokeLogPaths)
        }.count
        let failedLaunches = activeRecords.filter { $0.state == .failedToLaunch }.count
        let runningLaunches = activeRecords.filter {
            Self.isCurrentlyRunning($0, generatedAt: generatedAt)
        }.count
        let hasAcceptedDetachedLaunch = activeRecords.contains {
            $0.mode == .detached && $0.state == .started
        }
        let hasRunningForegroundLaunch = activeRecords.contains {
            $0.mode != .detached
                && Self.isCurrentlyRunning($0, generatedAt: generatedAt)
        }
        let status: LaunchHealthStatus
        if failedLaunches > 0 || nonZeroExitCount > 0 || failedLogs > 0 {
            status = .failed
        } else if hasRunningForegroundLaunch || attentionLogs > 0 || !activeIssueIds.isEmpty {
            status = .attention
        } else if activeRecords.contains(where: { $0.state == .completed })
            || hasAcceptedDetachedLaunch
            || passedLogs > 0 {
            status = .passed
        } else {
            status = .unknown
        }

        return LaunchHealthEntry(
            id: id,
            status: status,
            displayName: displayName,
            bottleId: bottleId,
            bottleName: bottleName,
            engineId: engineId,
            exe: exe,
            launchCount: records.count,
            completedLaunchCount: records.filter { $0.state == .completed }.count,
            failedToLaunchCount: failedLaunches,
            runningLaunchCount: runningLaunches,
            nonZeroExitCount: nonZeroExitCount,
            logCount: activeLogs.count,
            failedLogCount: failedLogs,
            attentionLogCount: attentionLogs,
            passedLogCount: passedLogs,
            latestStartedAt: latestRecord?.startedAt,
            latestEndedAt: latestRecord?.endedAt,
            latestLogModifiedAt: latestLog?.modifiedAt,
            latestLogPath: latestLog?.path,
            latestLaunchRecordId: latestRecord?.id,
            latestLaunchState: latestRecord?.state.rawValue,
            latestExitCode: latestRecord?.exitCode,
            latestLogHealth: latestLog?.health,
            hints: Self.orderedUnique(activeLogs.flatMap(\.hints)),
            probableIssueIds: activeIssueIds,
            recommendedProbeIds: activeProbeIds,
            logNames: Self.orderedUnique(activeLogs.map(\.name)),
            logPaths: Self.orderedUnique(activeLogs.map(\.path))
        )
    }

    private static func logsExcludingSupersededFailures(_ logs: [CapabilityLogEntry]) -> [CapabilityLogEntry] {
        guard let latestPassingDate = logs
            .filter(isSuccessfulSmokeLog)
            .map(\.modifiedAt)
            .max() else {
            return logs
        }
        return logs.filter { log in
            guard log.modifiedAt < latestPassingDate,
                  log.health == LogHealth.failed.rawValue || log.health == LogHealth.attention.rawValue else {
                return true
            }
            return false
        }
    }

    private static func orderedUnique(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for value in values where !value.isEmpty && !seen.contains(value) {
            seen.insert(value)
            result.append(value)
        }
        return result.sorted()
    }

    private static func isSuccessfulSmokeLog(_ log: CapabilityLogEntry) -> Bool {
        log.health == LogHealth.passed.rawValue
            || log.passCount > 0
            || log.hints.contains(LogHint.passObserved.rawValue)
    }

    private static func isControlledSmokeExit(_ record: WineLaunchRecord, successfulSmokeLogPaths: Set<String>) -> Bool {
        guard record.exitCode == 15 else { return false }
        if successfulSmokeLogPaths.contains(canonicalPath(record.logPath)) {
            return true
        }
        let marker = "\(record.id) \(record.logPath)".lowercased()
        return marker.contains("-cli-smoke-")
            || (record.state == .completed && marker.contains("-install-"))
    }

    private static func isCurrentlyRunning(_ record: WineLaunchRecord, generatedAt: Date) -> Bool {
        guard record.state == .started else { return false }
        let freshnessCutoff = generatedAt.addingTimeInterval(-24 * 60 * 60)
        guard record.startedAt >= freshnessCutoff else { return false }
        guard let processIdentifier = record.processIdentifier, processIdentifier > 0 else {
            return true
        }
        return kill(processIdentifier, 0) == 0
    }

    private static func recordsExcludingFailuresSupersededBySuccess(
        _ records: [WineLaunchRecord],
        successfulSmokeLogPaths: Set<String>
    ) -> [WineLaunchRecord] {
        let latestSuccessfulDate = records.compactMap { record -> Date? in
            guard record.state == .completed else { return nil }
            if record.exitCode == 0
                || isControlledSmokeExit(record, successfulSmokeLogPaths: successfulSmokeLogPaths) {
                return record.endedAt ?? record.startedAt
            }
            return nil
        }.max()
        guard let latestSuccessfulDate else { return records }

        return records.filter { record in
            let eventDate = record.endedAt ?? record.startedAt
            guard eventDate < latestSuccessfulDate else { return true }
            if record.state == .failedToLaunch {
                return false
            }
            guard (record.exitCode ?? 0) != 0 else { return true }
            return isControlledSmokeExit(record, successfulSmokeLogPaths: successfulSmokeLogPaths)
        }
    }

    private static func canonicalPath(_ path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.path.lowercased()
    }
}
