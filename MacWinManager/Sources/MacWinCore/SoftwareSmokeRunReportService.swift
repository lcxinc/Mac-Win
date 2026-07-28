import Foundation

public struct SoftwareSmokeRunCoveredAlternate: Codable, Equatable, Sendable {
    public var id: String
    public var state: String
    public var logPath: String?
    public var note: String

    public init(id: String, state: String, logPath: String? = nil, note: String = "") {
        self.id = id
        self.state = state
        self.logPath = logPath
        self.note = note
    }
}

public struct SoftwareSmokeRunSupersededSkip: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var state: String
    public var exitCode: Int?
    public var logPath: String?
    public var note: String
    public var reason: String
    public var supersededBy: [String]
    public var coveredBy: [SoftwareSmokeRunCoveredAlternate]
    public var missingAlternatesInRun: [String]

    public init(
        id: String,
        state: String = "skipped",
        exitCode: Int? = nil,
        logPath: String? = nil,
        note: String = "",
        reason: String,
        supersededBy: [String],
        coveredBy: [SoftwareSmokeRunCoveredAlternate],
        missingAlternatesInRun: [String] = []
    ) {
        self.id = id
        self.state = state
        self.exitCode = exitCode
        self.logPath = logPath
        self.note = note
        self.reason = reason
        self.supersededBy = supersededBy
        self.coveredBy = coveredBy
        self.missingAlternatesInRun = missingAlternatesInRun
    }
}

public struct SoftwareSmokeRunResolvedLegacyFailure: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var runId: String
    public var state: String
    public var exitCode: Int?
    public var logPath: String?
    public var note: String
    public var reason: String
    public var supersededBy: [String]
    public var coveredBy: [SoftwareSmokeRunCoveredAlternate]

    public init(
        id: String,
        runId: String,
        state: String,
        exitCode: Int? = nil,
        logPath: String? = nil,
        note: String = "",
        reason: String,
        supersededBy: [String],
        coveredBy: [SoftwareSmokeRunCoveredAlternate]
    ) {
        self.id = id
        self.runId = runId
        self.state = state
        self.exitCode = exitCode
        self.logPath = logPath
        self.note = note
        self.reason = reason
        self.supersededBy = supersededBy
        self.coveredBy = coveredBy
    }
}

public struct SoftwareSmokeRunRecord: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var phase: String
    public var state: String
    public var exitCode: Int?
    public var durationSeconds: Int?
    public var logPath: String?
    public var note: String?

    public init(
        id: String,
        phase: String,
        state: String,
        exitCode: Int? = nil,
        durationSeconds: Int? = nil,
        logPath: String? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.phase = phase
        self.state = state
        self.exitCode = exitCode
        self.durationSeconds = durationSeconds
        self.logPath = logPath
        self.note = note
    }
}

public struct SoftwareSmokeRunReport: Codable, Equatable, Sendable {
    public var generatedAt: String
    public var runId: String
    public var suite: String
    public var sample: String?
    public var prefix: String
    public var logDirectory: String
    public var recordCount: Int
    public var stateCounts: [String: Int]
    public var effectiveStateCounts: [String: Int]
    public var supersededSkipCount: Int
    public var supersededSkips: [SoftwareSmokeRunSupersededSkip]
    public var records: [SoftwareSmokeRunRecord]

    public init(
        generatedAt: String,
        runId: String,
        suite: String,
        sample: String? = nil,
        prefix: String,
        logDirectory: String,
        recordCount: Int,
        stateCounts: [String: Int],
        effectiveStateCounts: [String: Int]? = nil,
        supersededSkipCount: Int? = nil,
        supersededSkips: [SoftwareSmokeRunSupersededSkip] = [],
        records: [SoftwareSmokeRunRecord]
    ) {
        self.generatedAt = generatedAt
        self.runId = runId
        self.suite = suite
        self.sample = sample
        self.prefix = prefix
        self.logDirectory = logDirectory
        self.recordCount = recordCount
        self.stateCounts = stateCounts
        self.effectiveStateCounts = effectiveStateCounts ?? stateCounts
        self.supersededSkipCount = supersededSkipCount ?? supersededSkips.count
        self.supersededSkips = supersededSkips
        self.records = records
    }

    private enum CodingKeys: String, CodingKey {
        case generatedAt
        case runId
        case suite
        case sample
        case prefix
        case logDirectory
        case recordCount
        case stateCounts
        case effectiveStateCounts
        case supersededSkipCount
        case supersededSkips
        case records
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let stateCounts = try container.decode([String: Int].self, forKey: .stateCounts)
        let supersededSkips = try container.decodeIfPresent([SoftwareSmokeRunSupersededSkip].self, forKey: .supersededSkips) ?? []
        self.init(
            generatedAt: try container.decode(String.self, forKey: .generatedAt),
            runId: try container.decode(String.self, forKey: .runId),
            suite: try container.decode(String.self, forKey: .suite),
            sample: try container.decodeIfPresent(String.self, forKey: .sample),
            prefix: try container.decode(String.self, forKey: .prefix),
            logDirectory: try container.decode(String.self, forKey: .logDirectory),
            recordCount: try container.decode(Int.self, forKey: .recordCount),
            stateCounts: stateCounts,
            effectiveStateCounts: try container.decodeIfPresent([String: Int].self, forKey: .effectiveStateCounts),
            supersededSkipCount: try container.decodeIfPresent(Int.self, forKey: .supersededSkipCount),
            supersededSkips: supersededSkips,
            records: try container.decode([SoftwareSmokeRunRecord].self, forKey: .records)
        )
    }
}

public enum SoftwareSmokeEvidenceResolver {
    public static func currentLogReport(
        _ report: CapabilityLogReport,
        smokeReports: [SoftwareSmokeRunReport]
    ) -> CapabilityLogReport {
        guard !smokeReports.isEmpty else { return report }
        let entries = report.entries.filter { log in
            !supersedes(
                logName: log.name,
                logPath: log.path,
                modifiedAt: log.modifiedAt,
                reports: smokeReports
            )
        }
        let activePaths = Set(entries.map { canonicalPath($0.path) })
        let activeNames = Set(entries.map { $0.name.lowercased() })
        var issueReport = report.issueReport
        issueReport.recentFailures = issueReport.recentFailures.filter {
            activePaths.contains(canonicalPath($0.path))
        }
        issueReport.topIssues = issueReport.topIssues.compactMap { trend in
            let names = trend.affectedLogNames.filter { activeNames.contains($0.lowercased()) }
            guard trend.affectedLogNames.isEmpty || !names.isEmpty else { return nil }
            var current = trend
            current.affectedLogNames = names
            current.count = trend.affectedLogNames.isEmpty ? trend.count : names.count
            return current
        }
        issueReport.logsAnalyzed = entries.count
        issueReport.failedLogCount = entries.filter { $0.health == LogHealth.failed.rawValue }.count
        issueReport.attentionLogCount = entries.filter { $0.health == LogHealth.attention.rawValue }.count
        issueReport.passedLogCount = entries.filter { $0.health == LogHealth.passed.rawValue }.count
        issueReport.quietLogCount = entries.filter { $0.health == LogHealth.quiet.rawValue }.count
        issueReport.totalErrorCount = entries.map(\.errorCount).reduce(0, +)
        issueReport.totalWarningCount = entries.map(\.warningCount).reduce(0, +)
        issueReport.totalFixmeCount = entries.map(\.fixmeCount).reduce(0, +)
        issueReport.totalPassCount = entries.map(\.passCount).reduce(0, +)
        issueReport.totalFailCount = entries.map(\.failCount).reduce(0, +)
        issueReport.healthCounts = counts(entries.map(\.health))
        issueReport.hintCounts = counts(entries.flatMap(\.hints))

        return CapabilityLogReport(
            directory: report.directory,
            recentLogCount: entries.count,
            healthCounts: counts(entries.map(\.health)),
            hintCounts: counts(entries.flatMap(\.hints)),
            issueReport: issueReport,
            recommendations: report.recommendations.filter { recommendation in
                recommendation.affectedLogNames.isEmpty
                    || recommendation.affectedLogNames.contains { activeNames.contains($0.lowercased()) }
            },
            entries: entries
        )
    }

    public static func supersedes(
        logName: String,
        logPath: String,
        modifiedAt: Date,
        reports: [SoftwareSmokeRunReport]
    ) -> Bool {
        let logIdentity = normalizedIdentity(
            [logName, URL(fileURLWithPath: logPath).lastPathComponent]
                .joined(separator: " ")
        )
        guard !logIdentity.isEmpty else { return false }

        return reports.contains { report in
            guard let completedAt = reportDate(report.generatedAt),
                  completedAt > modifiedAt else {
                return false
            }
            let successfulLaunchIds = report.records.compactMap { record -> String? in
                guard record.phase == "launch", isSuccessfulRecordState(record.state) else {
                    return nil
                }
                return record.id
            }
            guard !successfulLaunchIds.isEmpty else { return false }
            let samples = report.sample?
                .split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) } ?? []
            return (samples + successfulLaunchIds).contains {
                identitiesMatch(logIdentity, normalizedIdentity($0))
            }
        }
    }

    private static func identitiesMatch(_ logIdentity: String, _ smokeIdentity: String) -> Bool {
        guard !smokeIdentity.isEmpty else { return false }
        if "-\(logIdentity)-".contains("-\(smokeIdentity)-") {
            return true
        }
        let logTokens = significantTokens(logIdentity)
        let smokeTokens = significantTokens(smokeIdentity)
        return !logTokens.isDisjoint(with: smokeTokens)
    }

    private static func significantTokens(_ value: String) -> Set<String> {
        let ignored: Set<String> = [
            "application", "browser", "client", "debug", "desktop", "editor",
            "installer", "launch", "manager", "portable", "setup", "smoke",
            "software", "store", "test", "windows", "wine", "winedebug"
        ]
        return Set(value.split(separator: "-").map(String.init).filter {
            $0.count >= 5 && !ignored.contains($0)
        })
    }

    private static func normalizedIdentity(_ value: String) -> String {
        value.lowercased()
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private static func canonicalPath(_ path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.path.lowercased()
    }

    private static func counts(_ values: [String]) -> [String: Int] {
        Dictionary(grouping: values, by: { $0 }).mapValues(\.count)
    }

    private static func reportDate(_ value: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: value) {
            return date
        }
        return ISO8601DateFormatter().date(from: value)
    }

    private static func isSuccessfulRecordState(_ state: String) -> Bool {
        state == "passed" || state == "launched"
    }
}

public struct SoftwareSmokeRunReportSummary: Codable, Equatable, Sendable {
    public var rootPath: String
    public var runsDirectory: String
    public var reportCount: Int
    public var latestRunId: String?
    public var rawStateCounts: [String: Int]
    public var effectiveStateCounts: [String: Int]
    public var supersededSkipCount: Int
    public var uncoveredSkippedCount: Int
    public var resolvedLegacyFailureCount: Int
    public var resolvedLegacyFailures: [SoftwareSmokeRunResolvedLegacyFailure]
    public var reports: [SoftwareSmokeRunReport]

    public init(rootPath: String, runsDirectory: String, reports: [SoftwareSmokeRunReport]) {
        self.rootPath = rootPath
        self.runsDirectory = runsDirectory
        self.reportCount = reports.count
        self.latestRunId = reports.first?.runId
        self.rawStateCounts = Self.mergeCounts(reports.map(\.stateCounts))
        var effectiveStateCounts = Self.mergeCounts(reports.map(\.effectiveStateCounts))
        self.supersededSkipCount = reports.reduce(0) { $0 + $1.supersededSkipCount }
        let rawSkipped = rawStateCounts["skipped", default: 0]
        self.uncoveredSkippedCount = max(0, rawSkipped - supersededSkipCount)
        let resolvedLegacyFailures = Self.resolvedLegacyFailures(in: reports)
        for item in resolvedLegacyFailures {
            effectiveStateCounts[item.state, default: 0] -= 1
            if effectiveStateCounts[item.state, default: 0] <= 0 {
                effectiveStateCounts.removeValue(forKey: item.state)
            }
            effectiveStateCounts["superseded", default: 0] += 1
        }
        self.effectiveStateCounts = effectiveStateCounts
        self.resolvedLegacyFailureCount = resolvedLegacyFailures.count
        self.resolvedLegacyFailures = resolvedLegacyFailures
        self.reports = reports
    }

    private static func mergeCounts(_ values: [[String: Int]]) -> [String: Int] {
        var result: [String: Int] = [:]
        for value in values {
            for (key, count) in value {
                result[key, default: 0] += count
            }
        }
        return result
    }

    private static func resolvedLegacyFailures(in reports: [SoftwareSmokeRunReport]) -> [SoftwareSmokeRunResolvedLegacyFailure] {
        let metadataById = legacySupersededMetadata
        var launchRecordsById: [String: [(reportIndex: Int, runId: String, record: SoftwareSmokeRunRecord)]] = [:]
        var recordsById: [String: [(reportIndex: Int, runId: String, record: SoftwareSmokeRunRecord)]] = [:]
        var recordsByIdentity: [String: [(reportIndex: Int, runId: String, record: SoftwareSmokeRunRecord)]] = [:]
        for (reportIndex, report) in reports.enumerated() {
            for record in report.records {
                recordsById[record.id, default: []].append((reportIndex, report.runId, record))
                recordsByIdentity["\(record.id)|\(record.phase)", default: []].append((reportIndex, report.runId, record))
            }
            for record in report.records where record.phase == "launch" {
                launchRecordsById[record.id, default: []].append((reportIndex, report.runId, record))
            }
        }

        var resolved: [SoftwareSmokeRunResolvedLegacyFailure] = []
        for (legacyId, metadata) in metadataById {
            for item in launchRecordsById[legacyId, default: []] where item.record.state == "failed" {
                var coveredBy: [SoftwareSmokeRunCoveredAlternate] = []
                for alternateId in metadata.supersededBy {
                    let candidates = launchRecordsById[alternateId, default: []]
                        .filter { candidate in
                            candidate.reportIndex <= item.reportIndex
                                && (candidate.record.state == "passed" || candidate.record.state == "launched")
                        }
                    if let candidate = candidates.first {
                        coveredBy.append(SoftwareSmokeRunCoveredAlternate(
                            id: alternateId,
                            state: candidate.record.state,
                            logPath: candidate.record.logPath,
                            note: candidate.record.note ?? ""
                        ))
                    }
                }
                guard !coveredBy.isEmpty else { continue }
                resolved.append(SoftwareSmokeRunResolvedLegacyFailure(
                    id: legacyId,
                    runId: item.runId,
                    state: item.record.state,
                    exitCode: item.record.exitCode,
                    logPath: item.record.logPath,
                    note: item.record.note ?? "",
                    reason: metadata.reason,
                    supersededBy: metadata.supersededBy,
                    coveredBy: coveredBy
                ))
            }
        }
        for (identity, records) in recordsByIdentity {
            let identityParts = identity.split(separator: "|", maxSplits: 1).map(String.init)
            let sampleId = identityParts.first ?? identity
            let phase = identityParts.dropFirst().first ?? "unknown"
            for item in records where Self.isResolvableFailureState(item.record.state) {
                let candidates = records
                    .filter { candidate in
                        candidate.reportIndex < item.reportIndex
                            && Self.isSuccessfulRecordState(candidate.record.state)
                    }
                guard let candidate = candidates.first else { continue }
                guard !resolved.contains(where: {
                    $0.id == sampleId
                        && $0.runId == item.runId
                        && $0.state == item.record.state
                        && $0.logPath == item.record.logPath
                }) else { continue }
                resolved.append(SoftwareSmokeRunResolvedLegacyFailure(
                    id: sampleId,
                    runId: item.runId,
                    state: item.record.state,
                    exitCode: item.record.exitCode,
                    logPath: item.record.logPath,
                    note: item.record.note ?? "",
                    reason: "A newer smoke run for the same \(sampleId) \(phase) phase reached \(candidate.record.state), so this older \(item.record.state) record is treated as resolved history.",
                    supersededBy: [sampleId],
                    coveredBy: [
                        SoftwareSmokeRunCoveredAlternate(
                            id: sampleId,
                            state: candidate.record.state,
                            logPath: candidate.record.logPath,
                            note: candidate.record.note ?? ""
                        )
                    ]
                ))
            }
        }
        for (sampleId, records) in recordsById {
            for item in records where Self.isResolvableFailureState(item.record.state)
                && Self.isInstallPathPhase(item.record.phase) {
                let candidates = records
                    .filter { candidate in
                        candidate.reportIndex < item.reportIndex
                            && Self.isInstallPathCoverageRecord(candidate.record)
                    }
                guard let candidate = candidates.first else { continue }
                guard !resolved.contains(where: {
                    $0.id == sampleId
                        && $0.runId == item.runId
                        && $0.state == item.record.state
                        && $0.logPath == item.record.logPath
                }) else { continue }
                resolved.append(SoftwareSmokeRunResolvedLegacyFailure(
                    id: sampleId,
                    runId: item.runId,
                    state: item.record.state,
                    exitCode: item.record.exitCode,
                    logPath: item.record.logPath,
                    note: item.record.note ?? "",
                    reason: "A newer smoke run for the same \(sampleId) proved the installed executable or launch path during \(candidate.record.phase), so this older \(item.record.phase) \(item.record.state) record is treated as resolved history.",
                    supersededBy: [sampleId],
                    coveredBy: [
                        SoftwareSmokeRunCoveredAlternate(
                            id: sampleId,
                            state: candidate.record.state,
                            logPath: candidate.record.logPath,
                            note: candidate.record.note ?? ""
                        )
                    ]
                ))
            }
        }
        return resolved.sorted { lhs, rhs in
            if lhs.id != rhs.id { return lhs.id < rhs.id }
            return lhs.runId < rhs.runId
        }
    }

    private static func isResolvableFailureState(_ state: String) -> Bool {
        ["failed", "missingInstaller", "timeout", "crashed", "blocked"].contains(state)
    }

    private static func isSuccessfulRecordState(_ state: String) -> Bool {
        state == "passed" || state == "launched"
    }

    private static func isInstallPathPhase(_ phase: String) -> Bool {
        phase == "install" || phase == "installed-file"
    }

    private static func isInstallPathCoverageRecord(_ record: SoftwareSmokeRunRecord) -> Bool {
        switch record.phase {
        case "installed-file":
            return record.state == "passed"
        case "launch":
            return isSuccessfulRecordState(record.state)
        default:
            return false
        }
    }

    private static let legacySupersededMetadata: [String: (supersededBy: [String], reason: String)] = [
        "geogebra-classic": (
            supersededBy: ["geogebra-classic5"],
            reason: "GeoGebra Classic 6 is a legacy 32-bit Electron/WOW64 regression path; GeoGebra Classic 5 is the validated geometry UI target."
        ),
        "mremoteng-manager": (
            supersededBy: ["mremoteng-1782-x64"],
            reason: "mRemoteNG 1.76.x is a legacy 32-bit .NET/Wine-Mono path; mRemoteNG 1.78.2 x64 is the validated WinForms target."
        ),
        "winscp-client": (
            supersededBy: ["winscp-x64-portable", "winscp-x64-cli-help"],
            reason: "WinSCP stable GUI installer is a legacy 32-bit Delphi/VCL path; WinSCP x64 portable GUI and CLI are the validated targets."
        ),
        "qownnotes-editor": (
            supersededBy: ["qownnotes-portable"],
            reason: "The older QOwnNotes editor sample was replaced by the portable build, which preserves the Qt notes UI target and has a validated GUI launch path."
        )
    ]
}

public struct SoftwareSmokeRunReportService {
    public var paths: MacWinPaths
    public var fileManager: FileManager
    public var store: JSONStore

    public init(paths: MacWinPaths = MacWinPaths(), fileManager: FileManager = .default, store: JSONStore = JSONStore()) {
        self.paths = paths
        self.fileManager = fileManager
        self.store = store
    }

    public var runsDirectory: URL {
        paths.logsDirectory.appendingPathComponent("SoftwareSmokeRuns", isDirectory: true)
    }

    public func reports(limit: Int = 50) throws -> [SoftwareSmokeRunReport] {
        let urls = try reportURLs(limit: limit)
        return try urls.map { try store.load(SoftwareSmokeRunReport.self, from: $0) }
    }

    public func summary(limit: Int = 50) throws -> SoftwareSmokeRunReportSummary {
        try SoftwareSmokeRunReportSummary(rootPath: paths.root.path, runsDirectory: runsDirectory.path, reports: reports(limit: limit))
    }

    public static func csv(summary: SoftwareSmokeRunReportSummary) -> String {
        var rows: [[String]] = [[
            "run_id",
            "generated_at",
            "suite",
            "sample",
            "record_count",
            "state_counts",
            "effective_state_counts",
            "superseded_skip_count",
            "uncovered_skipped_count",
            "log_directory"
        ]]
        for report in summary.reports {
            let rawSkipped = report.stateCounts["skipped", default: 0]
            let uncoveredSkipped = max(0, rawSkipped - report.supersededSkipCount)
            rows.append([
                report.runId,
                report.generatedAt,
                report.suite,
                report.sample ?? "",
                String(report.recordCount),
                countsString(report.stateCounts),
                countsString(report.effectiveStateCounts),
                String(report.supersededSkipCount),
                String(uncoveredSkipped),
                report.logDirectory
            ])
        }
        return rows.map { $0.map(csvEscaped).joined(separator: ",") }.joined(separator: "\n") + "\n"
    }

    public static func markdown(summary: SoftwareSmokeRunReportSummary) -> String {
        var lines: [String] = [
            "# MacWin Software Smoke Runs",
            "",
            "- Reports: \(summary.reportCount)",
            "- Latest run: `\(summary.latestRunId ?? "none")`",
            "- Raw state counts: \(countsString(summary.rawStateCounts))",
            "- Effective state counts: \(countsString(summary.effectiveStateCounts))",
            "- Superseded skips: \(summary.supersededSkipCount)",
            "- Uncovered skipped: \(summary.uncoveredSkippedCount)",
            "- Resolved legacy failures: \(summary.resolvedLegacyFailureCount)",
            ""
        ]
        if !summary.resolvedLegacyFailures.isEmpty {
            lines.append("## Resolved Legacy Failures")
            lines.append("")
            for item in summary.resolvedLegacyFailures {
                let covered = item.coveredBy.map { "\($0.id) (\($0.state))" }.joined(separator: ", ")
                lines.append("### \(item.id)")
                lines.append("")
                lines.append("- Run: `\(item.runId)`")
                lines.append("- Original state: `\(item.state)`")
                lines.append("- Superseded by: `\(item.supersededBy.joined(separator: ", "))`")
                lines.append("- Covered by: \(covered.isEmpty ? "not covered" : covered)")
                lines.append("- Reason: \(item.reason)")
                if let logPath = item.logPath {
                    lines.append("- Log: `\(logPath)`")
                }
                if !item.note.isEmpty {
                    lines.append("- Note: \(item.note)")
                }
                lines.append("")
            }
        }
        if !summary.reports.flatMap(\.supersededSkips).isEmpty {
            lines.append("## Superseded Legacy Skips")
            lines.append("")
            for item in summary.reports.flatMap(\.supersededSkips) {
                let covered = item.coveredBy.map { "\($0.id) (\($0.state))" }.joined(separator: ", ")
                lines.append("### \(item.id)")
                lines.append("")
                lines.append("- Superseded by: `\(item.supersededBy.joined(separator: ", "))`")
                lines.append("- Covered by: \(covered.isEmpty ? "not covered in report" : covered)")
                lines.append("- Missing alternates: \(item.missingAlternatesInRun.isEmpty ? "none" : item.missingAlternatesInRun.joined(separator: ", "))")
                lines.append("- Reason: \(item.reason)")
                if !item.note.isEmpty {
                    lines.append("- Note: \(item.note)")
                }
                lines.append("")
            }
        }
        if !summary.reports.isEmpty {
            lines.append("## Runs")
            lines.append("")
            for report in summary.reports {
                lines.append("### \(report.runId)")
                lines.append("")
                lines.append("- Generated: \(report.generatedAt)")
                lines.append("- Suite: `\(report.suite)`")
                if let sample = report.sample {
                    lines.append("- Sample: `\(sample)`")
                }
                lines.append("- Records: \(report.recordCount)")
                lines.append("- State counts: \(countsString(report.stateCounts))")
                lines.append("- Effective state counts: \(countsString(report.effectiveStateCounts))")
                lines.append("- Superseded skips: \(report.supersededSkipCount)")
                lines.append("- Logs: `\(report.logDirectory)`")
                lines.append("")
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }

    private func reportURLs(limit: Int) throws -> [URL] {
        guard fileManager.fileExists(atPath: runsDirectory.path) else { return [] }
        let runDirectories = try fileManager.contentsOfDirectory(at: runsDirectory, includingPropertiesForKeys: [.contentModificationDateKey, .isDirectoryKey])
        let reportURLs = runDirectories
            .filter { url in
                (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            }
            .map { $0.appendingPathComponent("software-smoke-report.json") }
            .filter { fileManager.fileExists(atPath: $0.path) }
            .sorted { lhs, rhs in
                modificationDate(for: lhs) > modificationDate(for: rhs)
            }
        guard limit > 0 else { return reportURLs }
        return Array(reportURLs.prefix(limit))
    }

    private func modificationDate(for url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
    }

    private static func countsString(_ counts: [String: Int]) -> String {
        counts
            .sorted { lhs, rhs in lhs.key < rhs.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ";")
    }

    private static func csvEscaped(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
