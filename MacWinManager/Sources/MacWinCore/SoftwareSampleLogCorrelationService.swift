import Foundation

public struct SoftwareSampleLogCorrelationEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: String { sampleId }
    public var sampleId: String
    public var name: String
    public var installSource: SoftwareSampleInstallSource
    public var catalogBacked: Bool
    public var launchCount: Int
    public var logCount: Int
    public var failedLogCount: Int
    public var attentionLogCount: Int
    public var latestLaunchAt: Date?
    public var latestLogModifiedAt: Date?
    public var launchRecordIds: [String]
    public var logNames: [String]
    public var logPaths: [String]
    public var probableIssueIds: [String]
    public var recommendedProbeIds: [String]

    public init(
        sampleId: String,
        name: String,
        installSource: SoftwareSampleInstallSource,
        catalogBacked: Bool,
        launchCount: Int,
        logCount: Int,
        failedLogCount: Int,
        attentionLogCount: Int,
        latestLaunchAt: Date?,
        latestLogModifiedAt: Date?,
        launchRecordIds: [String],
        logNames: [String],
        logPaths: [String],
        probableIssueIds: [String],
        recommendedProbeIds: [String]
    ) {
        self.sampleId = sampleId
        self.name = name
        self.installSource = installSource
        self.catalogBacked = catalogBacked
        self.launchCount = launchCount
        self.logCount = logCount
        self.failedLogCount = failedLogCount
        self.attentionLogCount = attentionLogCount
        self.latestLaunchAt = latestLaunchAt
        self.latestLogModifiedAt = latestLogModifiedAt
        self.launchRecordIds = launchRecordIds
        self.logNames = logNames
        self.logPaths = logPaths
        self.probableIssueIds = probableIssueIds
        self.recommendedProbeIds = recommendedProbeIds
    }
}

public struct SoftwareSampleLogCorrelationReport: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var rootPath: String
    public var sampleCount: Int
    public var matchedSampleCount: Int
    public var launchMatchedSampleCount: Int
    public var logMatchedSampleCount: Int
    public var failedSampleCount: Int
    public var attentionSampleCount: Int
    public var launchCount: Int
    public var logCount: Int
    public var entries: [SoftwareSampleLogCorrelationEntry]

    public init(generatedAt: Date, rootPath: String, entries: [SoftwareSampleLogCorrelationEntry]) {
        self.generatedAt = generatedAt
        self.rootPath = rootPath
        self.sampleCount = entries.count
        self.matchedSampleCount = entries.filter { $0.launchCount > 0 || $0.logCount > 0 }.count
        self.launchMatchedSampleCount = entries.filter { $0.launchCount > 0 }.count
        self.logMatchedSampleCount = entries.filter { $0.logCount > 0 }.count
        self.failedSampleCount = entries.filter { $0.failedLogCount > 0 }.count
        self.attentionSampleCount = entries.filter { $0.attentionLogCount > 0 }.count
        self.launchCount = entries.map(\.launchCount).reduce(0, +)
        self.logCount = entries.map(\.logCount).reduce(0, +)
        self.entries = entries
    }
}

public struct SoftwareSampleLogCorrelationService {
    public var paths: MacWinPaths

    public init(paths: MacWinPaths = MacWinPaths()) {
        self.paths = paths
    }

    public func report(
        sampleCatalog: SoftwareSampleCatalogReport,
        logs: CapabilityLogReport,
        launchHistory: LaunchHistoryReport?,
        generatedAt: Date = Date()
    ) -> SoftwareSampleLogCorrelationReport {
        Self.report(
            rootPath: paths.root.path,
            sampleCatalog: sampleCatalog,
            logs: logs,
            launchHistory: launchHistory,
            generatedAt: generatedAt
        )
    }

    public static func report(
        rootPath: String,
        sampleCatalog: SoftwareSampleCatalogReport,
        logs: CapabilityLogReport,
        launchHistory: LaunchHistoryReport?,
        generatedAt: Date = Date()
    ) -> SoftwareSampleLogCorrelationReport {
        var issueByPath: [String: LogIssueSample] = [:]
        for issue in logs.issueReport.recentFailures {
            issueByPath[canonicalPath(issue.path)] = issue
        }
        let entries = sampleCatalog.samples.map { sample in
            let aliases = matchingAliases(for: sample)
            let launches = (launchHistory?.records ?? []).filter { record in
                matches(record: record, aliases: aliases)
            }
            let matchedLogs = logs.entries.filter { entry in
                matches(log: entry, aliases: aliases)
            }
            let issueSamples = matchedLogs.compactMap { issueByPath[canonicalPath($0.path)] }
            let probableIssueIds = orderedUnique(issueSamples.flatMap(\.probableIssueIds))
            let logProbeIds = orderedUnique(issueSamples.flatMap(\.probeAssetIds))
            return SoftwareSampleLogCorrelationEntry(
                sampleId: sample.id,
                name: sample.name,
                installSource: sample.installSource,
                catalogBacked: sample.catalogBacked,
                launchCount: launches.count,
                logCount: matchedLogs.count,
                failedLogCount: matchedLogs.filter { $0.health == LogHealth.failed.rawValue }.count,
                attentionLogCount: matchedLogs.filter { $0.health == LogHealth.attention.rawValue }.count,
                latestLaunchAt: launches.map(\.startedAt).max(),
                latestLogModifiedAt: matchedLogs.map(\.modifiedAt).max(),
                launchRecordIds: launches.map(\.id).sorted(),
                logNames: matchedLogs.map(\.name).sorted(),
                logPaths: matchedLogs.map(\.path).sorted(),
                probableIssueIds: probableIssueIds,
                recommendedProbeIds: orderedUnique(sample.recommendedProbeIds + logProbeIds)
            )
        }
        .sorted { lhs, rhs in
            if lhs.failedLogCount != rhs.failedLogCount { return lhs.failedLogCount > rhs.failedLogCount }
            if lhs.attentionLogCount != rhs.attentionLogCount { return lhs.attentionLogCount > rhs.attentionLogCount }
            if lhs.launchCount + lhs.logCount != rhs.launchCount + rhs.logCount {
                return lhs.launchCount + lhs.logCount > rhs.launchCount + rhs.logCount
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        return SoftwareSampleLogCorrelationReport(generatedAt: generatedAt, rootPath: rootPath, entries: entries)
    }

    public static func csv(report: SoftwareSampleLogCorrelationReport) -> String {
        let formatter = ISO8601DateFormatter()
        var rows: [[String]] = [[
            "sample_id",
            "name",
            "install_source",
            "catalog_backed",
            "launch_count",
            "log_count",
            "failed_log_count",
            "attention_log_count",
            "latest_launch_at",
            "latest_log_modified_at",
            "launch_record_ids",
            "log_names",
            "log_paths",
            "probable_issue_ids",
            "recommended_probe_ids"
        ]]
        for entry in report.entries {
            rows.append([
                entry.sampleId,
                entry.name,
                entry.installSource.rawValue,
                entry.catalogBacked ? "true" : "false",
                String(entry.launchCount),
                String(entry.logCount),
                String(entry.failedLogCount),
                String(entry.attentionLogCount),
                entry.latestLaunchAt.map { formatter.string(from: $0) } ?? "",
                entry.latestLogModifiedAt.map { formatter.string(from: $0) } ?? "",
                entry.launchRecordIds.joined(separator: ";"),
                entry.logNames.joined(separator: ";"),
                entry.logPaths.joined(separator: ";"),
                entry.probableIssueIds.joined(separator: ";"),
                entry.recommendedProbeIds.joined(separator: ";")
            ])
        }
        return rows.map { $0.map(csvEscaped).joined(separator: ",") }.joined(separator: "\n") + "\n"
    }

    public static func markdown(report: SoftwareSampleLogCorrelationReport) -> String {
        let formatter = ISO8601DateFormatter()
        let matched = report.entries.filter { $0.launchCount > 0 || $0.logCount > 0 }
        let unmatched = report.entries.filter { $0.launchCount == 0 && $0.logCount == 0 }
        var lines = [
            "# MacWin Software Sample Log Correlation",
            "",
            "- Generated: \(formatter.string(from: report.generatedAt))",
            "- Root: `\(markdownEscaped(report.rootPath))`",
            "- Samples: \(report.sampleCount)",
            "- Matched samples: \(report.matchedSampleCount)",
            "- Launches: \(report.launchCount)",
            "- Logs: \(report.logCount)",
            "- Failed samples: \(report.failedSampleCount)",
            "- Attention samples: \(report.attentionSampleCount)",
            "",
            "## Matched Samples",
            ""
        ]

        if matched.isEmpty {
            lines.append("No software sample logs have been matched yet.")
        } else {
            for entry in matched {
                lines.append("### \(markdownEscaped(entry.name))")
                lines.append("")
                lines.append("- Sample id: `\(markdownEscaped(entry.sampleId))`")
                lines.append("- Install source: `\(entry.installSource.rawValue)`")
                lines.append("- Catalog backed: \(entry.catalogBacked ? "true" : "false")")
                lines.append("- Counts: launches=\(entry.launchCount), logs=\(entry.logCount), failedLogs=\(entry.failedLogCount), attentionLogs=\(entry.attentionLogCount)")
                if let latestLaunchAt = entry.latestLaunchAt {
                    lines.append("- Latest launch: \(formatter.string(from: latestLaunchAt))")
                }
                if let latestLogModifiedAt = entry.latestLogModifiedAt {
                    lines.append("- Latest log: \(formatter.string(from: latestLogModifiedAt))")
                }
                if !entry.launchRecordIds.isEmpty {
                    lines.append("- Launch records: \(entry.launchRecordIds.map { "`\(markdownEscaped($0))`" }.joined(separator: ", "))")
                }
                if !entry.logNames.isEmpty {
                    lines.append("- Logs: \(entry.logNames.map { "`\(markdownEscaped($0))`" }.joined(separator: ", "))")
                }
                if !entry.probableIssueIds.isEmpty {
                    lines.append("- Probable issues: \(entry.probableIssueIds.map { "`\(markdownEscaped($0))`" }.joined(separator: ", "))")
                }
                if !entry.recommendedProbeIds.isEmpty {
                    lines.append("- Recommended probes: \(entry.recommendedProbeIds.map { "`\(markdownEscaped($0))`" }.joined(separator: ", "))")
                }
                if !entry.logPaths.isEmpty {
                    lines.append("- Log paths:")
                    for path in entry.logPaths.prefix(8) {
                        lines.append("  - `\(markdownEscaped(path))`")
                    }
                    if entry.logPaths.count > 8 {
                        lines.append("  - ... \(entry.logPaths.count - 8) more")
                    }
                }
                lines.append("")
            }
        }

        lines.append("")
        lines.append("## Unmatched Samples")
        lines.append("")
        if unmatched.isEmpty {
            lines.append("All known software samples have at least one launch record or log.")
        } else {
            for entry in unmatched.prefix(16) {
                lines.append("- \(markdownEscaped(entry.name)) (`\(markdownEscaped(entry.sampleId))`): source `\(entry.installSource.rawValue)`")
            }
            if unmatched.count > 16 {
                lines.append("- ... \(unmatched.count - 16) more")
            }
        }

        lines.append("")
        return lines.joined(separator: "\n")
    }

    private static func matches(record: WineLaunchRecord, aliases: Set<String>) -> Bool {
        let text = normalized(([record.exe] + record.args + record.commandLine + record.environment.map { "\($0.key)=\($0.value)" }).joined(separator: " "))
        return aliases.contains { text.contains($0) }
    }

    private static func matches(log entry: CapabilityLogEntry, aliases: Set<String>) -> Bool {
        var parts = [entry.name, entry.path]
        if let context = entry.launchContext {
            parts.append(context.exe)
            parts.append(contentsOf: context.args)
            parts.append(contentsOf: context.commandLine)
            parts.append(context.bottleName)
        }
        let text = normalized(parts.joined(separator: " "))
        return aliases.contains { text.contains($0) }
    }

    private static func matchingAliases(for sample: SoftwareSampleProfile) -> Set<String> {
        var aliases = Set<String>()
        func insert(_ value: String?) {
            guard let value else { return }
            let normalizedValue = normalized(value)
            guard normalizedValue.count >= 3 else { return }
            aliases.insert(normalizedValue)
        }

        insert(sample.id)
        insert(sample.catalogRecipeId)
        insert(sample.compatibilityProfileId)
        for candidate in sample.launcherCandidates {
            insert(candidate)
            let fileName = URL(fileURLWithPath: candidate.replacingOccurrences(of: "\\", with: "/")).lastPathComponent
            insert(fileName)
            insert(fileName.replacingOccurrences(of: ".exe", with: ""))
        }

        switch sample.id {
        case "hoyoplay-cn":
            ["hoyoplay", "hyp.exe", "hyphelper", "mihoyo launcher", "米哈游"].forEach(insert)
        case "steam":
            ["steam.exe", "steamwebhelper", "/steam/", "\\steam\\"].forEach(insert)
        case "itch":
            ["itch.exe", "itchsetup", "butler.exe", "itch.io"].forEach(insert)
        case "lenovo-app-store":
            ["lenovo", "lenovo app store", "lenovoappstore.exe", "leaslane.exe", "leappstore", "联想应用商店"].forEach(insert)
        case "tencent-app-store":
            ["tencent", "tencent app store", "qqpcmgr.exe", "yingyongbao", "tencentappstore", "应用宝", "腾讯应用市场"].forEach(insert)
        default:
            break
        }

        return aliases
    }

    private static func normalized(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "/")
            .replacingOccurrences(of: "%USERNAME%", with: "")
            .lowercased()
    }

    private static func canonicalPath(_ value: String) -> String {
        URL(fileURLWithPath: value).standardizedFileURL.path.lowercased()
    }

    private static func orderedUnique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for value in values where !seen.contains(value) {
            seen.insert(value)
            result.append(value)
        }
        return result
    }

    private static func csvEscaped(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    private static func markdownEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
    }
}
