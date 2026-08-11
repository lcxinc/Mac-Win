import Foundation

public struct LogFileItem: Identifiable, Equatable, Sendable {
    public var id: String { url.path }
    public var name: String
    public var url: URL
    public var modifiedAt: Date
    public var byteCount: Int64
    public var summary: LogSummary
    public var launchContext: LogLaunchContext?

    public init(
        name: String,
        url: URL,
        modifiedAt: Date,
        byteCount: Int64,
        summary: LogSummary = LogSummary(),
        launchContext: LogLaunchContext? = nil
    ) {
        self.name = name
        self.url = url
        self.modifiedAt = modifiedAt
        self.byteCount = byteCount
        self.summary = summary
        self.launchContext = launchContext
    }
}

public struct LogLaunchContext: Codable, Equatable, Sendable {
    public var launchRecordId: String
    public var mode: String
    public var state: String
    public var bottleId: String
    public var bottleName: String
    public var engineId: String
    public var exe: String
    public var args: [String]
    public var commandLine: [String]
    public var startedAt: Date
    public var endedAt: Date?
    public var processIdentifier: Int32?
    public var exitCode: Int32?
    public var errorMessage: String?

    public init(
        launchRecordId: String,
        mode: String,
        state: String,
        bottleId: String,
        bottleName: String,
        engineId: String,
        exe: String,
        args: [String],
        commandLine: [String],
        startedAt: Date,
        endedAt: Date? = nil,
        processIdentifier: Int32? = nil,
        exitCode: Int32? = nil,
        errorMessage: String? = nil
    ) {
        self.launchRecordId = launchRecordId
        self.mode = mode
        self.state = state
        self.bottleId = bottleId
        self.bottleName = bottleName
        self.engineId = engineId
        self.exe = exe
        self.args = args
        self.commandLine = commandLine
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.processIdentifier = processIdentifier
        self.exitCode = exitCode
        self.errorMessage = errorMessage
    }

    public init(record: WineLaunchRecord) {
        self.init(
            launchRecordId: record.id,
            mode: record.mode.rawValue,
            state: record.state.rawValue,
            bottleId: record.bottleId,
            bottleName: record.bottleName,
            engineId: record.engineId,
            exe: record.exe,
            args: record.args,
            commandLine: record.commandLine,
            startedAt: record.startedAt,
            endedAt: record.endedAt,
            processIdentifier: record.processIdentifier,
            exitCode: record.exitCode,
            errorMessage: record.errorMessage
        )
    }
}

public enum LogHealth: String, Codable, Equatable, Sendable {
    case passed
    case failed
    case attention
    case quiet
}

public enum LogHint: String, Codable, CaseIterable, Equatable, Sendable {
    case steamNetworkProbe
    case electronStdout
    case wineProgramError
    case wineCrash
    case vulkanIssue
    case networkTLSIssue
    case d3dMetalRuntime
    case cefRenderingIssue
    case fontRenderingIssue
    case blankWindowIssue
    case windowInputIssue
    case gpuRenderingIssue
    case win32CompatibilityIssue
    case jaspQrcQmlResourceIssue
    case jaspQmlInitializationHangIssue
    case jaspEngineIpcIssue
    case dotnetRuntimeIssue
    case missingDLLIssue
    case msiRuntimeIssue
    case chromeOmahaInstallerIssue
    case comProxyMarshallingIssue
    case mRemoteNGEarlyExitIssue
    case portableAppsSEHIssue
    case installerIssue
    case timeout
    case passObserved
}

public struct LogSummary: Equatable, Sendable {
    public var errorCount: Int
    public var warningCount: Int
    public var fixmeCount: Int
    public var passCount: Int
    public var failCount: Int
    public var hints: [LogHint]

    public init(
        errorCount: Int = 0,
        warningCount: Int = 0,
        fixmeCount: Int = 0,
        passCount: Int = 0,
        failCount: Int = 0,
        hints: [LogHint] = []
    ) {
        self.errorCount = errorCount
        self.warningCount = warningCount
        self.fixmeCount = fixmeCount
        self.passCount = passCount
        self.failCount = failCount
        self.hints = hints
    }

    public var health: LogHealth {
        if failCount > 0 || errorCount > 0 {
            return .failed
        }
        if hints.contains(.blankWindowIssue)
            || hints.contains(.fontRenderingIssue)
            || hints.contains(.windowInputIssue)
            || hints.contains(.mRemoteNGEarlyExitIssue)
            || hints.contains(.wineCrash) {
            return .attention
        }
        if warningCount > 0 || fixmeCount > 0 {
            return .attention
        }
        if passCount > 0 {
            return .passed
        }
        return .quiet
    }
}

public struct LogIssueReport: Codable, Equatable, Sendable {
    public var logsAnalyzed: Int
    public var failedLogCount: Int
    public var attentionLogCount: Int
    public var passedLogCount: Int
    public var quietLogCount: Int
    public var totalErrorCount: Int
    public var totalWarningCount: Int
    public var totalFixmeCount: Int
    public var totalPassCount: Int
    public var totalFailCount: Int
    public var healthCounts: [String: Int]
    public var hintCounts: [String: Int]
    public var topIssues: [LogIssueTrend]
    public var recentFailures: [LogIssueSample]

    public init(logs: [LogFileItem], topIssues: [LogIssueTrend], recentFailures: [LogIssueSample]) {
        self.logsAnalyzed = logs.count
        self.failedLogCount = logs.filter { $0.summary.health == .failed }.count
        self.attentionLogCount = logs.filter { $0.summary.health == .attention }.count
        self.passedLogCount = logs.filter { $0.summary.health == .passed }.count
        self.quietLogCount = logs.filter { $0.summary.health == .quiet }.count
        self.totalErrorCount = logs.map(\.summary.errorCount).reduce(0, +)
        self.totalWarningCount = logs.map(\.summary.warningCount).reduce(0, +)
        self.totalFixmeCount = logs.map(\.summary.fixmeCount).reduce(0, +)
        self.totalPassCount = logs.map(\.summary.passCount).reduce(0, +)
        self.totalFailCount = logs.map(\.summary.failCount).reduce(0, +)
        self.healthCounts = Self.counts(logs.map { $0.summary.health.rawValue })
        self.hintCounts = Self.counts(logs.flatMap { $0.summary.hints.map(\.rawValue) })
        self.topIssues = topIssues
        self.recentFailures = recentFailures
    }

    private static func counts(_ values: [String]) -> [String: Int] {
        var result: [String: Int] = [:]
        for value in values {
            result[value, default: 0] += 1
        }
        return result
    }

    public static func csv(report: LogIssueReport) -> String {
        let header: [String] = [
            "record_type",
            "id",
            "name",
            "severity_or_health",
            "count",
            "path",
            "modified_at",
            "errors",
            "warnings",
            "fixmes",
            "pass",
            "fail",
            "hints",
            "probable_issue_ids",
            "affected_logs",
            "recommended_actions",
            "probe_asset_ids",
            "evidence",
            "bottle_id",
            "bottle_name",
            "engine_id",
            "exe",
            "exit_code"
        ]
        let trendRows: [[String]] = report.topIssues.map { issue -> [String] in
            let relatedHints = joinedList(issue.relatedHints)
            let affectedLogNames = joinedList(issue.affectedLogNames)
            let recommendedActions = joinedList(issue.recommendedActions)
            let probeAssetIds = joinedList(issue.probeAssetIds)
            return [
                "trend",
                issue.id,
                issue.title,
                issue.severity,
                "\(issue.count)",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                relatedHints,
                "",
                affectedLogNames,
                recommendedActions,
                probeAssetIds,
                issue.detail,
                "",
                "",
                "",
                "",
                ""
            ]
        }
        let dateFormatter = ISO8601DateFormatter()
        let sampleRows: [[String]] = report.recentFailures.map { sample -> [String] in
            let modifiedAt = dateFormatter.string(from: sample.modifiedAt)
            let hints = joinedList(sample.hints)
            let probableIssueIds = joinedList(sample.probableIssueIds)
            let recommendedActions = joinedList(sample.recommendedActions)
            let probeAssetIds = joinedList(sample.probeAssetIds)
            let evidenceSnippets = joinedList(sample.evidenceSnippets)
            let bottleId = sample.launchContext?.bottleId ?? ""
            let bottleName = sample.launchContext?.bottleName ?? ""
            let engineId = sample.launchContext?.engineId ?? ""
            let executable = sample.launchContext?.exe ?? ""
            let exitCode = sample.launchContext?.exitCode.map(String.init) ?? ""
            return [
                "sample",
                sample.path,
                sample.name,
                sample.health,
                "",
                sample.path,
                modifiedAt,
                "\(sample.errorCount)",
                "\(sample.warningCount)",
                "\(sample.fixmeCount)",
                "\(sample.passCount)",
                "\(sample.failCount)",
                hints,
                probableIssueIds,
                "",
                recommendedActions,
                probeAssetIds,
                evidenceSnippets,
                bottleId,
                bottleName,
                engineId,
                executable,
                exitCode
            ]
        }
        let rows: [[String]] = [header] + trendRows + sampleRows
        return rows
            .map { $0.map(csvEscaped).joined(separator: ",") }
            .joined(separator: "\n") + "\n"
    }

    private static func joinedList(_ values: [String]) -> String {
        values.joined(separator: " | ")
    }

    private static func csvEscaped(_ value: String) -> String {
        let normalized = value
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        if normalized.contains(",") || normalized.contains("\"") || normalized.contains("\n") {
            return "\"\(normalized.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return normalized
    }
}

public struct LogIssueTrend: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var severity: String
    public var title: String
    public var detail: String
    public var count: Int
    public var relatedHints: [String]
    public var affectedLogNames: [String]
    public var recommendedActions: [String]
    public var probeAssetIds: [String]

    public init(
        id: String,
        severity: String,
        title: String,
        detail: String,
        count: Int,
        relatedHints: [String],
        affectedLogNames: [String],
        recommendedActions: [String] = [],
        probeAssetIds: [String] = []
    ) {
        self.id = id
        self.severity = severity
        self.title = title
        self.detail = detail
        self.count = count
        self.relatedHints = relatedHints
        self.affectedLogNames = affectedLogNames
        self.recommendedActions = recommendedActions
        self.probeAssetIds = probeAssetIds
    }
}

public struct LogIssueSample: Codable, Equatable, Identifiable, Sendable {
    public var id: String { path }
    public var name: String
    public var path: String
    public var modifiedAt: Date
    public var health: String
    public var errorCount: Int
    public var warningCount: Int
    public var fixmeCount: Int
    public var passCount: Int
    public var failCount: Int
    public var hints: [String]
    public var probableIssueIds: [String]
    public var evidenceSnippets: [String]
    public var recommendedActions: [String]
    public var probeAssetIds: [String]
    public var launchContext: LogLaunchContext?

    public init(
        name: String,
        path: String,
        modifiedAt: Date,
        health: String,
        errorCount: Int,
        warningCount: Int,
        fixmeCount: Int,
        passCount: Int,
        failCount: Int,
        hints: [String],
        probableIssueIds: [String],
        evidenceSnippets: [String] = [],
        recommendedActions: [String] = [],
        probeAssetIds: [String] = [],
        launchContext: LogLaunchContext? = nil
    ) {
        self.name = name
        self.path = path
        self.modifiedAt = modifiedAt
        self.health = health
        self.errorCount = errorCount
        self.warningCount = warningCount
        self.fixmeCount = fixmeCount
        self.passCount = passCount
        self.failCount = failCount
        self.hints = hints
        self.probableIssueIds = probableIssueIds
        self.evidenceSnippets = evidenceSnippets
        self.recommendedActions = recommendedActions
        self.probeAssetIds = probeAssetIds
        self.launchContext = launchContext
    }
}

public enum LogRemediationSource: String, Codable, Equatable, Sendable {
    case trend
    case sample
}

public struct LogRemediationItem: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var source: LogRemediationSource
    public var severity: String
    public var issueId: String
    public var title: String
    public var action: String
    public var probeAssetIds: [String]
    public var affectedLogNames: [String]
    public var samplePaths: [String]
    public var evidenceSnippets: [String]
    public var bottleId: String?
    public var bottleName: String?
    public var engineId: String?
    public var exe: String?

    public init(
        id: String,
        source: LogRemediationSource,
        severity: String,
        issueId: String,
        title: String,
        action: String,
        probeAssetIds: [String],
        affectedLogNames: [String] = [],
        samplePaths: [String] = [],
        evidenceSnippets: [String] = [],
        bottleId: String? = nil,
        bottleName: String? = nil,
        engineId: String? = nil,
        exe: String? = nil
    ) {
        self.id = id
        self.source = source
        self.severity = severity
        self.issueId = issueId
        self.title = title
        self.action = action
        self.probeAssetIds = probeAssetIds
        self.affectedLogNames = affectedLogNames
        self.samplePaths = samplePaths
        self.evidenceSnippets = evidenceSnippets
        self.bottleId = bottleId
        self.bottleName = bottleName
        self.engineId = engineId
        self.exe = exe
    }
}

public struct LogRemediationPlan: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var logsAnalyzed: Int
    public var failedLogCount: Int
    public var attentionLogCount: Int
    public var issueCount: Int
    public var sampleCount: Int
    public var actionCount: Int
    public var probeActionCount: Int
    public var affectedLogCount: Int
    public var items: [LogRemediationItem]

    public init(generatedAt: Date, report: LogIssueReport, items: [LogRemediationItem]) {
        self.generatedAt = generatedAt
        self.logsAnalyzed = report.logsAnalyzed
        self.failedLogCount = report.failedLogCount
        self.attentionLogCount = report.attentionLogCount
        self.issueCount = report.topIssues.count
        self.sampleCount = report.recentFailures.count
        self.actionCount = items.count
        self.probeActionCount = items.filter { !$0.probeAssetIds.isEmpty }.count
        self.affectedLogCount = Set(items.flatMap(\.affectedLogNames) + items.flatMap(\.samplePaths)).count
        self.items = items
    }

    public static func csv(plan: LogRemediationPlan) -> String {
        let formatter = ISO8601DateFormatter()
        var rows: [[String]] = [[
            "id",
            "source",
            "severity",
            "issue_id",
            "title",
            "action",
            "probe_asset_ids",
            "affected_logs",
            "sample_paths",
            "evidence",
            "bottle_id",
            "bottle_name",
            "engine_id",
            "exe",
            "generated_at"
        ]]
        for item in plan.items {
            rows.append([
                item.id,
                item.source.rawValue,
                item.severity,
                item.issueId,
                item.title,
                item.action,
                item.probeAssetIds.joined(separator: ";"),
                item.affectedLogNames.joined(separator: ";"),
                item.samplePaths.joined(separator: ";"),
                item.evidenceSnippets.joined(separator: " | "),
                item.bottleId ?? "",
                item.bottleName ?? "",
                item.engineId ?? "",
                item.exe ?? "",
                formatter.string(from: plan.generatedAt)
            ])
        }
        return rows.map { $0.map(csvEscaped).joined(separator: ",") }.joined(separator: "\n") + "\n"
    }

    public static func markdown(plan: LogRemediationPlan) -> String {
        let formatter = ISO8601DateFormatter()
        var lines = [
            "# MacWin Log Remediation Plan",
            "",
            "- Generated: \(formatter.string(from: plan.generatedAt))",
            "- Logs analyzed: \(plan.logsAnalyzed)",
            "- Failed logs: \(plan.failedLogCount)",
            "- Attention logs: \(plan.attentionLogCount)",
            "- Issues: \(plan.issueCount)",
            "- Recent failure samples: \(plan.sampleCount)",
            "- Actions: \(plan.actionCount)",
            "- Probe-backed actions: \(plan.probeActionCount)",
            "",
            "## Actions",
            ""
        ]
        if plan.items.isEmpty {
            lines.append("No log remediation actions are currently required.")
        } else {
            for item in plan.items {
                lines.append("### \(markdownEscaped(item.title))")
                lines.append("")
                lines.append("- Id: `\(item.id)`")
                lines.append("- Source: `\(item.source.rawValue)`")
                lines.append("- Severity: `\(item.severity)`")
                lines.append("- Issue: `\(item.issueId)`")
                lines.append("- Action: \(markdownEscaped(item.action))")
                if !item.probeAssetIds.isEmpty {
                    lines.append("- Probes: \(item.probeAssetIds.map { "`\($0)`" }.joined(separator: ", "))")
                }
                if !item.affectedLogNames.isEmpty {
                    lines.append("- Affected logs: \(item.affectedLogNames.map { "`\($0)`" }.joined(separator: ", "))")
                }
                if !item.samplePaths.isEmpty {
                    lines.append("- Samples: \(item.samplePaths.map { "`\($0)`" }.joined(separator: ", "))")
                }
                if let bottleName = item.bottleName, let bottleId = item.bottleId {
                    lines.append("- Bottle: `\(bottleName)` (`\(bottleId)`)")
                }
                if let exe = item.exe {
                    lines.append("- Executable: `\(exe)`")
                }
                if !item.evidenceSnippets.isEmpty {
                    lines.append("- Evidence:")
                    for snippet in item.evidenceSnippets.prefix(4) {
                        lines.append("  ```text")
                        lines.append("  \(snippet)")
                        lines.append("  ```")
                    }
                }
                lines.append("")
            }
        }
        return lines.joined(separator: "\n")
    }

    public static func runbookScript(plan: LogRemediationPlan, runbook: TestAssetRunbook? = nil) -> String {
        let commandsById = Dictionary(uniqueKeysWithValues: (runbook?.groups.flatMap(\.commands) ?? []).map { ($0.assetId, $0) })
        let probeIds = orderedUnique(plan.items.flatMap(\.probeAssetIds))
        var lines = [
            "#!/usr/bin/env bash",
            "set -euo pipefail",
            "",
            "MODE=\"${1:-run}\"",
            "",
            "note() {",
            "  printf '%s\\n' \"$1\"",
            "}",
            "",
            "run_probe() {",
            "  local asset_id=\"$1\"",
            "  shift",
            "  note \"== $asset_id ==\"",
            "  \"$@\"",
            "}",
            "",
            "case \"$MODE\" in",
            "  list)",
            "    note 'MacWin log remediation runbook'",
            "    note \(shellQuoted("Actions: \(plan.actionCount), probe-backed actions: \(plan.probeActionCount), affected logs: \(plan.affectedLogCount)"))"
        ]

        if plan.items.isEmpty {
            lines.append("    note 'No log remediation actions are currently required.'")
        } else {
            for item in plan.items {
                lines.append("    note \(shellQuoted("[\(item.severity)] \(item.title) (\(item.issueId))"))")
                lines.append("    note \(shellQuoted("  action: \(item.action)"))")
                if !item.probeAssetIds.isEmpty {
                    lines.append("    note \(shellQuoted("  probes: \(item.probeAssetIds.joined(separator: ", "))"))")
                }
                if !item.affectedLogNames.isEmpty {
                    lines.append("    note \(shellQuoted("  logs: \(item.affectedLogNames.joined(separator: ", "))"))")
                }
                if !item.samplePaths.isEmpty {
                    lines.append("    note \(shellQuoted("  samples: \(item.samplePaths.joined(separator: ", "))"))")
                }
            }
            for id in probeIds {
                if let command = commandsById[id] {
                    let state = command.exists && command.command != nil ? "runnable" : "unavailable"
                    let note = command.note.map { " \($0)" } ?? ""
                    lines.append("    note \(shellQuoted("probe \(id): \(state)\(note)"))")
                } else {
                    lines.append("    note \(shellQuoted("probe \(id): unavailable unknown probe id"))")
                }
            }
        }
        lines.append("    ;;")
        lines.append("  run)")
        if plan.items.isEmpty {
            lines.append("    note 'No log remediation actions are currently required.'")
            lines.append("    exit 0")
        } else {
            for item in plan.items {
                lines.append("    note \(shellQuoted("ACTION \(item.issueId): \(item.action)"))")
                if !item.samplePaths.isEmpty {
                    lines.append("    note \(shellQuoted("  samples: \(item.samplePaths.joined(separator: ", "))"))")
                }
            }
            lines.append("    failures=0")
            if probeIds.isEmpty {
                lines.append("    note 'No remediation probes are recommended by the current log issue report.'")
            } else {
                for id in probeIds {
                    guard let command = commandsById[id], command.exists, let commandLine = command.command else {
                        lines.append("    note \(shellQuoted("SKIP \(id): missing probe asset or single-probe runner"))")
                        continue
                    }
                    lines.append("    if ! run_probe \(shellQuoted(id)) \(commandLine.map(shellQuoted).joined(separator: " ")); then")
                    lines.append("      failures=$((failures + 1))")
                    lines.append("    fi")
                }
                lines.append("    if (( failures > 0 )); then")
                lines.append("      echo \"Log remediation probe failures: $failures\" >&2")
                lines.append("      exit 1")
                lines.append("    fi")
            }
        }
        lines.append("    ;;")
        lines.append("  *)")
        lines.append("    echo 'usage: $0 [run|list]' >&2")
        lines.append("    exit 2")
        lines.append("    ;;")
        lines.append("esac")
        lines.append("")
        return lines.joined(separator: "\n")
    }

    private static func csvEscaped(_ value: String) -> String {
        let normalized = value
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        if normalized.contains(",") || normalized.contains("\"") || normalized.contains("\n") {
            return "\"\(normalized.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return normalized
    }

    private static func markdownEscaped(_ value: String) -> String {
        value.replacingOccurrences(of: "\n", with: " ")
    }

    private static func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
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
}

public struct LogMaintenancePolicy: Codable, Equatable, Sendable {
    public var staleAgeDays: Int
    public var largeLogBytes: Int64

    public init(staleAgeDays: Int = 14, largeLogBytes: Int64 = 16 * 1024 * 1024) {
        self.staleAgeDays = staleAgeDays
        self.largeLogBytes = largeLogBytes
    }
}

public struct LogMaintenanceItem: Codable, Equatable, Identifiable, Sendable {
    public var id: String { path }
    public var name: String
    public var path: String
    public var modifiedAt: Date
    public var byteCount: Int64
    public var reasons: [String]

    public init(name: String, path: String, modifiedAt: Date, byteCount: Int64, reasons: [String]) {
        self.name = name
        self.path = path
        self.modifiedAt = modifiedAt
        self.byteCount = byteCount
        self.reasons = reasons
    }
}

public struct LogMaintenanceReport: Codable, Equatable, Sendable {
    public var logsPath: String
    public var generatedAt: Date
    public var policy: LogMaintenancePolicy
    public var totalLogCount: Int
    public var totalLogBytes: Int64
    public var staleLogCount: Int
    public var staleLogBytes: Int64
    public var largeLogCount: Int
    public var largeLogBytes: Int64
    public var cleanupCandidateCount: Int
    public var cleanupCandidateBytes: Int64
    public var newestLogModifiedAt: Date?
    public var oldestLogModifiedAt: Date?
    public var cleanupCandidates: [LogMaintenanceItem]
    public var recommendations: [String]

    public init(
        logsPath: String,
        generatedAt: Date,
        policy: LogMaintenancePolicy,
        totalLogCount: Int,
        totalLogBytes: Int64,
        staleLogCount: Int,
        staleLogBytes: Int64,
        largeLogCount: Int,
        largeLogBytes: Int64,
        cleanupCandidateCount: Int,
        cleanupCandidateBytes: Int64,
        newestLogModifiedAt: Date?,
        oldestLogModifiedAt: Date?,
        cleanupCandidates: [LogMaintenanceItem],
        recommendations: [String]
    ) {
        self.logsPath = logsPath
        self.generatedAt = generatedAt
        self.policy = policy
        self.totalLogCount = totalLogCount
        self.totalLogBytes = totalLogBytes
        self.staleLogCount = staleLogCount
        self.staleLogBytes = staleLogBytes
        self.largeLogCount = largeLogCount
        self.largeLogBytes = largeLogBytes
        self.cleanupCandidateCount = cleanupCandidateCount
        self.cleanupCandidateBytes = cleanupCandidateBytes
        self.newestLogModifiedAt = newestLogModifiedAt
        self.oldestLogModifiedAt = oldestLogModifiedAt
        self.cleanupCandidates = cleanupCandidates
        self.recommendations = recommendations
    }

    public static func csv(report: LogMaintenanceReport) -> String {
        var lines = [
            "row_type,name,path,modified_at,byte_count,reasons,total_log_count,total_log_bytes,cleanup_candidate_count,cleanup_candidate_bytes"
        ]
        let formatter = ISO8601DateFormatter()
        lines.append([
            "summary",
            "",
            report.logsPath,
            formatter.string(from: report.generatedAt),
            "",
            "",
            String(report.totalLogCount),
            String(report.totalLogBytes),
            String(report.cleanupCandidateCount),
            String(report.cleanupCandidateBytes)
        ].map(csvEscaped).joined(separator: ","))

        for item in report.cleanupCandidates {
            lines.append([
                "candidate",
                item.name,
                item.path,
                formatter.string(from: item.modifiedAt),
                String(item.byteCount),
                item.reasons.joined(separator: ";"),
                "",
                "",
                "",
                ""
            ].map(csvEscaped).joined(separator: ","))
        }

        return lines.joined(separator: "\n") + "\n"
    }

    private static func csvEscaped(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}

public struct LogMaintenanceArchivedItem: Codable, Equatable, Identifiable, Sendable {
    public var id: String { sourcePath }
    public var name: String
    public var sourcePath: String
    public var archivedPath: String
    public var byteCount: Int64
    public var reasons: [String]
}

public struct LogMaintenanceArchiveResult: Codable, Equatable, Sendable {
    public var archivePath: String
    public var archivedCount: Int
    public var archivedBytes: Int64
    public var archivedItems: [LogMaintenanceArchivedItem]
}

public struct LogService {
    public var paths: MacWinPaths
    public var fileManager: FileManager

    public init(paths: MacWinPaths = MacWinPaths(), fileManager: FileManager = .default) {
        self.paths = paths
        self.fileManager = fileManager
    }

    public func recentLogs(limit: Int = 24) -> [LogFileItem] {
        Self.recentLogs(in: paths.logsDirectory, limit: limit, fileManager: fileManager)
    }

    public func issueReport(limit: Int = 24) -> LogIssueReport {
        Self.issueReport(logs: recentLogs(limit: limit))
    }

    public func maintenanceReport(
        policy: LogMaintenancePolicy = LogMaintenancePolicy(),
        generatedAt: Date = Date()
    ) -> LogMaintenanceReport {
        Self.maintenanceReport(
            in: paths.logsDirectory,
            policy: policy,
            generatedAt: generatedAt,
            fileManager: fileManager
        )
    }

    public func archiveCleanupCandidates(
        report: LogMaintenanceReport,
        generatedAt: Date = Date()
    ) throws -> LogMaintenanceArchiveResult {
        try Self.archiveCleanupCandidates(report: report, generatedAt: generatedAt, fileManager: fileManager)
    }

    /// Archives completed failure/attention logs outside the active status window.
    /// The archive is recoverable and is excluded from live status reports.
    public func archiveHistoricalFailures(
        olderThan age: TimeInterval = 24 * 60 * 60,
        generatedAt: Date = Date()
    ) throws -> LogMaintenanceArchiveResult {
        let logs = Self.recentLogs(
            in: paths.logsDirectory,
            limit: Int.max,
            fileManager: fileManager
        )
        let cutoff = generatedAt.addingTimeInterval(-max(age, 0))
        let candidates = logs.compactMap { log -> LogMaintenanceItem? in
            guard log.modifiedAt < cutoff,
                  log.summary.health == .failed || log.summary.health == .attention else {
                return nil
            }
            if let context = log.launchContext, context.endedAt == nil || context.state == "running" {
                return nil
            }
            return LogMaintenanceItem(
                name: log.name,
                path: log.url.path,
                modifiedAt: log.modifiedAt,
                byteCount: log.byteCount,
                reasons: ["historical-failure"]
            )
        }
        guard !candidates.isEmpty else {
            return LogMaintenanceArchiveResult(
                archivePath: paths.logsDirectory.appendingPathComponent("Archive", isDirectory: true).path,
                archivedCount: 0,
                archivedBytes: 0,
                archivedItems: []
            )
        }

        let report = LogMaintenanceReport(
            logsPath: paths.logsDirectory.path,
            generatedAt: generatedAt,
            policy: LogMaintenancePolicy(staleAgeDays: max(Int(age / (24 * 60 * 60)), 0), largeLogBytes: Int64.max),
            totalLogCount: candidates.count,
            totalLogBytes: candidates.map(\.byteCount).reduce(0, +),
            staleLogCount: candidates.count,
            staleLogBytes: candidates.map(\.byteCount).reduce(0, +),
            largeLogCount: 0,
            largeLogBytes: 0,
            cleanupCandidateCount: candidates.count,
            cleanupCandidateBytes: candidates.map(\.byteCount).reduce(0, +),
            newestLogModifiedAt: candidates.map(\.modifiedAt).max(),
            oldestLogModifiedAt: candidates.map(\.modifiedAt).min(),
            cleanupCandidates: candidates,
            recommendations: []
        )
        return try archiveCleanupCandidates(report: report, generatedAt: generatedAt)
    }

    public static func recentLogs(
        in directory: URL,
        limit: Int = 24,
        fileManager: FileManager = .default
    ) -> [LogFileItem] {
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let launchContexts = launchContextsByLogPath(in: directory, fileManager: fileManager)
        let keys: Set<URLResourceKey> = [.contentModificationDateKey, .fileSizeKey, .isRegularFileKey]
        let urls = maintenanceLogFileURLs(in: directory, resourceKeys: keys, fileManager: fileManager)

        let candidates = urls.compactMap { url -> (url: URL, name: String, modifiedAt: Date, byteCount: Int64)? in
            guard url.pathExtension == "log",
                  !isOperationalLog(url),
                  let values = try? url.resourceValues(forKeys: keys),
                  values.isRegularFile == true else {
                return nil
            }
            return (
                url: url,
                name: url.lastPathComponent,
                modifiedAt: values.contentModificationDate ?? .distantPast,
                byteCount: Int64(values.fileSize ?? 0)
            )
        }
        .sorted { $0.modifiedAt > $1.modifiedAt }
        .prefix(limit)

        return candidates.map { candidate in
            return LogFileItem(
                name: candidate.name,
                url: candidate.url,
                modifiedAt: candidate.modifiedAt,
                byteCount: candidate.byteCount,
                summary: summarizeLog(file: candidate.url),
                launchContext: launchContexts[candidate.url.path] ?? launchContexts[canonicalPath(candidate.url.path)]
            )
        }
    }

    public static func maintenanceReport(
        in directory: URL,
        policy: LogMaintenancePolicy = LogMaintenancePolicy(),
        generatedAt: Date = Date(),
        fileManager: FileManager = .default
    ) -> LogMaintenanceReport {
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let keys: Set<URLResourceKey> = [.contentModificationDateKey, .fileSizeKey, .isRegularFileKey]
        let urls = maintenanceLogFileURLs(in: directory, resourceKeys: keys, fileManager: fileManager)

        let staleCutoff = generatedAt.addingTimeInterval(-Double(max(policy.staleAgeDays, 0)) * 24 * 60 * 60)
        let items = urls.compactMap { url -> LogMaintenanceItem? in
            guard url.pathExtension == "log",
                  !isOperationalLog(url),
                  let values = try? url.resourceValues(forKeys: keys),
                  values.isRegularFile == true else {
                return nil
            }
            let modifiedAt = values.contentModificationDate ?? .distantPast
            let byteCount = Int64(values.fileSize ?? 0)
            var reasons: [String] = []
            if modifiedAt < staleCutoff {
                reasons.append("stale")
            }
            if byteCount >= policy.largeLogBytes {
                reasons.append("large")
            }
            return LogMaintenanceItem(
                name: url.lastPathComponent,
                path: url.path,
                modifiedAt: modifiedAt,
                byteCount: byteCount,
                reasons: reasons
            )
        }
        .sorted {
            if $0.modifiedAt != $1.modifiedAt { return $0.modifiedAt < $1.modifiedAt }
            return $0.name < $1.name
        }

        let totalBytes = items.map(\.byteCount).reduce(0, +)
        let staleItems = items.filter { $0.reasons.contains("stale") }
        let largeItems = items.filter { $0.reasons.contains("large") }
        let cleanupCandidates = items.filter { !$0.reasons.isEmpty }
        let cleanupCandidateBytes = cleanupCandidates.map(\.byteCount).reduce(0, +)

        return LogMaintenanceReport(
            logsPath: directory.path,
            generatedAt: generatedAt,
            policy: policy,
            totalLogCount: items.count,
            totalLogBytes: totalBytes,
            staleLogCount: staleItems.count,
            staleLogBytes: staleItems.map(\.byteCount).reduce(0, +),
            largeLogCount: largeItems.count,
            largeLogBytes: largeItems.map(\.byteCount).reduce(0, +),
            cleanupCandidateCount: cleanupCandidates.count,
            cleanupCandidateBytes: cleanupCandidateBytes,
            newestLogModifiedAt: items.last?.modifiedAt,
            oldestLogModifiedAt: items.first?.modifiedAt,
            cleanupCandidates: cleanupCandidates,
            recommendations: maintenanceRecommendations(
                totalLogCount: items.count,
                totalLogBytes: totalBytes,
                staleLogCount: staleItems.count,
                largeLogCount: largeItems.count,
                cleanupCandidateBytes: cleanupCandidateBytes
            )
        )
    }

    private static func maintenanceLogFileURLs(
        in directory: URL,
        resourceKeys: Set<URLResourceKey>,
        fileManager: FileManager
    ) -> [URL] {
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var urls: [URL] = []
        for case let url as URL in enumerator {
            if url.hasDirectoryPath {
                let name = url.lastPathComponent.lowercased()
                if name == "archive" || name == "supportbundles" {
                    enumerator.skipDescendants()
                }
                continue
            }
            guard url.pathExtension == "log", !isOperationalLog(url) else { continue }
            urls.append(url)
        }
        return urls
    }

    public static func maintenanceShellScript(for report: LogMaintenanceReport) -> String {
        var lines = [
            "#!/usr/bin/env bash",
            "set -euo pipefail",
            "",
            "APPLY=0",
            "if [[ \"${1:-}\" == \"--apply\" ]]; then",
            "  APPLY=1",
            "fi",
            "",
            "LOGS_DIR=\(shellQuoted(report.logsPath))",
            "ARCHIVE_DIR=\"$LOGS_DIR/Archive/log-maintenance-\(scriptTimestamp(report.generatedAt))\"",
            "",
            "echo \(shellQuoted("MacWin log maintenance report"))",
            "echo \(shellQuoted("Logs: \(report.totalLogCount), cleanup candidates: \(report.cleanupCandidateCount), candidate bytes: \(report.cleanupCandidateBytes)"))",
            "if [[ \"$APPLY\" != \"1\" ]]; then",
            "  echo 'Dry run: pass --apply to archive cleanup candidates.'",
            "fi",
            "",
            "archive_log() {",
            "  local src=\"$1\"",
            "  local reason=\"$2\"",
            "  local name",
            "  name=\"$(basename \"$src\")\"",
            "  local dest=\"$ARCHIVE_DIR/$name\"",
            "  if [[ ! -f \"$src\" ]]; then",
            "    echo \"MISSING $src\"",
            "    return 0",
            "  fi",
            "  if [[ \"$APPLY\" == \"1\" ]]; then",
            "    mkdir -p \"$ARCHIVE_DIR\"",
            "    mv -n \"$src\" \"$dest\"",
            "    echo \"ARCHIVED $src -> $dest ($reason)\"",
            "  else",
            "    echo \"WOULD_ARCHIVE $src ($reason)\"",
            "  fi",
            "}",
            ""
        ]

        if report.cleanupCandidates.isEmpty {
            lines.append("echo 'No cleanup candidates.'")
        } else {
            for item in report.cleanupCandidates {
                lines.append("archive_log \(shellQuoted(item.path)) \(shellQuoted(item.reasons.joined(separator: ",")))")
            }
        }
        lines.append("")
        return lines.joined(separator: "\n")
    }

    public static func archiveCleanupCandidates(
        report: LogMaintenanceReport,
        generatedAt: Date = Date(),
        fileManager: FileManager = .default
    ) throws -> LogMaintenanceArchiveResult {
        let logsURL = URL(fileURLWithPath: report.logsPath, isDirectory: true)
            .resolvingSymlinksInPath()
            .standardizedFileURL
        let archiveURL = logsURL
            .appendingPathComponent("Archive", isDirectory: true)
            .appendingPathComponent("log-maintenance-\(scriptTimestamp(generatedAt))", isDirectory: true)
        var archivedItems: [LogMaintenanceArchivedItem] = []

        for item in report.cleanupCandidates {
            let sourceURL = URL(fileURLWithPath: item.path)
                .resolvingSymlinksInPath()
                .standardizedFileURL
            guard sourceURL.pathExtension == "log",
                  sourceURL.path.hasPrefix(logsURL.path + "/"),
                  sourceURL.path != archiveURL.path,
                  fileManager.fileExists(atPath: sourceURL.path) else {
                continue
            }

            let attributes = try fileManager.attributesOfItem(atPath: sourceURL.path)
            guard attributes[.type] as? FileAttributeType == .typeRegular else {
                continue
            }

            try fileManager.createDirectory(at: archiveURL, withIntermediateDirectories: true)
            let destinationURL = uniqueArchiveDestination(
                for: sourceURL.lastPathComponent,
                in: archiveURL,
                fileManager: fileManager
            )
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            archivedItems.append(
                LogMaintenanceArchivedItem(
                    name: item.name,
                    sourcePath: item.path,
                    archivedPath: destinationURL.path,
                    byteCount: item.byteCount,
                    reasons: item.reasons
                )
            )
        }

        return LogMaintenanceArchiveResult(
            archivePath: archiveURL.path,
            archivedCount: archivedItems.count,
            archivedBytes: archivedItems.map(\.byteCount).reduce(0, +),
            archivedItems: archivedItems
        )
    }

    public static func summarizeLog(file url: URL, maxBytes: UInt64 = 128 * 1024) -> LogSummary {
        guard let data = try? tailData(file: url, maxBytes: maxBytes),
              let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            return LogSummary()
        }
        return summarizeLog(text)
    }

    private static func isOperationalLog(_ url: URL) -> Bool {
        let name = url.lastPathComponent.lowercased()
        return name == "external-open-queue.log"
            || name == "foundation-status.log"
            || name.hasPrefix("runtime-processes-")
            || name.contains("-installer-help-")
            || name.contains("-manual-install-")
    }

    public static func summarizeLog(_ text: String) -> LogSummary {
        var summary = LogSummary()
        var hints = Set<LogHint>()
        let lowercasedText = text.lowercased()
        let hasKeptAliveManagedSmoke = lowercasedText.contains("smokeoutcome=keptalive")
            || lowercasedText.contains("cliwatchdog=timedout")
        let hasSuccessfulManagedSmoke = lowercasedText.contains("smokeoutcome=passed")
            && lowercasedText.contains("exitcode=0")
        let hasVerifiedPgAdminCompositor = hasKeptAliveManagedSmoke
            && lowercasedText.contains("visualprobe.id=pgadmin-db-admin")
            && lowercasedText.contains("visualprobe.status=verified-compositor")
        let hasVerifiedOpenPLCCompositor = hasKeptAliveManagedSmoke
            && lowercasedText.contains("visualprobe.id=openplc-editor")
            && lowercasedText.contains("visualprobe.status=verified-compositor")
            && lowercasedText.contains("visualprobe.classification=rendered")
        let hasVerifiedOpenPLCUpdateTimeout = hasVerifiedOpenPLCCompositor
            && lowercasedText.contains("checking for update")
            && lowercasedText.contains("net::err_timed_out")
        let hasVerifiedWiresharkOfflineDissection = hasKeptAliveManagedSmoke
            && lowercasedText.contains("id=wireshark-analyzer")
            && lowercasedText.contains("wiresharkofflinedissection=passed")
        let isMacWinCOMProxyRepair = lowercasedText.contains("id=macwin-com-proxy")
            && lowercasedText.contains("phase=repair")
        let hasCompletedJASPStartup = (hasKeptAliveManagedSmoke || hasSuccessfulManagedSmoke)
            && (
                lowercasedText.contains("jaspstartupmilestone=passed")
                    || (
                        (lowercasedText.contains("qml initialized!")
                            || lowercasedText.contains("jaspstartupqmlinitialized=yes"))
                            && (lowercasedText.contains("jasp desktop started and engines initalized")
                                || lowercasedText.contains("mainwindow::resultspageloaded")
                                || lowercasedText.contains("jaspstartupresultspageloaded=yes"))
                    )
                    || (
                        lowercasedText.contains("jaspengine started")
                            && lowercasedText.contains("resultstatus of analysis was complete")
                            && lowercasedText.contains("old result conversion:")
                            && lowercasedText.contains("new result conversion:")
                    )
            )
        let hasKeptAliveGeoGebraRenderer = hasKeptAliveManagedSmoke
            && lowercasedText.contains("geogebra.exe")
            && lowercasedText.contains("--type=renderer")
        let hasSuccessfulPassedProbe = lowercasedText.contains("pass ")
            && lowercasedText.contains("exitcode=0")
        let hasPassedVulkanProbe = lowercasedText.contains("probe=vulkan")
            && lowercasedText.contains("pass vulkan")
            && lowercasedText.contains("exitcode=0")
        let hasPassedIpcFileMappingProbe = lowercasedText.contains("probe=ipc_file_mapping")
            && lowercasedText.contains("pass ipc_file_mapping")
        let hasD3DMetalPreset = lowercasedText.contains("macwin_graphics_preset=gptk-d3dmetal")
            || lowercasedText.contains("macwin_graphics_preset=gptk-d3dmetal-dxr")
            || lowercasedText.contains("libd3dshared.dylib")
        let sawGeckoBrowserLaunch = lowercasedText.contains("macwin_compat_profile=browser-gecko")
            || lowercasedText.contains("\\mozilla firefox\\firefox.exe")
            || lowercasedText.contains("/mozilla firefox/firefox.exe")
        let sawPortableAppsKeptAliveThemeProfile = lowercasedText.contains("uxtheme=d")
            && (lowercasedText.contains("macwin_compat_profile=portableapps-platform")
                || lowercasedText.contains("portableappsplatform.exe"))
        var sawMSICommandOrPath = false
        var sawShellExecuteFileNotFound = false
        var sawMissingMSIExecutable = false
        var sawChromiumEnterpriseInstaller = false
        var sawChromiumUpdaterInstallFailure = false
        var sawCOMProxyMarshallingFailure = false
        var sawJASPEngineSync = false
        var sawJASPQrcQmlResourceFailure = false
        var sawJASPQtWebEngineInitialized = false
        var sawJASPQmlInitialized = false
        var sawJASPLoadingThemes = false
        var sawJASPLaunchTimeout = false
        var sawJASPConstructorBoundaryExit = false
        var sawJASPFailFastOrLockFailure = false
        var sawJASPDesktopStarted = false
        var sawMacWinSoftwareSmokeLaunch = false
        var sawMacWinRunnerSmokeKeptAlive = hasKeptAliveManagedSmoke
        var sawMRemoteNG1782Launch = false
        var sawMRemoteNGEarlyExitStatus = false
        var sawPortableAppsPlatformLaunch = lowercasedText.contains("portableappsplatform.exe")
            || lowercasedText.contains("portableapps.com platform")
        var sawQucsSQt6Launch = false
        var sawBenignLsfHelperFailure = false
        var sawLenovoAppStoreLaunch = lowercasedText.contains("macwin_compat_profile=lenovo-app-store")
            || lowercasedText.contains("\\lenovo\\leappstore\\lenovoappstore.exe")
            || lowercasedText.contains("/lenovo/leappstore/lenovoappstore.exe")
        var sawTencentAppStoreLaunch = lowercasedText.contains("macwin_compat_profile=tencent-app-store")
            || lowercasedText.contains("\\tencent\\androws\\")
            || lowercasedText.contains("/tencent/androws/")
            || lowercasedText.contains("androwsstore.exe")
        var sawWineCrashLine = false
        var sawLenovoBusinessMessageAfterCrash = false
        var isInJASPTimeoutSamplePreview = false

        for line in text.components(separatedBy: .newlines) {
            let lowercased = line.lowercased()
            if lowercased.hasPrefix("jasptimeout.samplepreview:") {
                isInJASPTimeoutSamplePreview = true
                continue
            }
            if isInJASPTimeoutSamplePreview {
                if lowercased.hasPrefix("jaspipcsnapshot.") {
                    isInJASPTimeoutSamplePreview = false
                } else {
                    continue
                }
            }
            if lowercased.contains("tencent-app-store")
                || lowercased.contains("\\tencent\\androws\\")
                || lowercased.contains("/tencent/androws/")
                || lowercased.contains("androwsstore.exe") {
                sawTencentAppStoreLaunch = true
            }
            if lowercased.contains("lenovo-app-store")
                || lowercased.contains("\\lenovo\\leappstore\\lenovoappstore.exe")
                || lowercased.contains("/lenovo/leappstore/lenovoappstore.exe") {
                sawLenovoAppStoreLaunch = true
            }
            if sawWineCrashLine
                && lowercased.contains("messageid:")
                && lowercased.contains("category:appstore_") {
                sawLenovoBusinessMessageAfterCrash = true
            }
            if lowercased.contains("smokeoutcome=keptalive") {
                sawMacWinRunnerSmokeKeptAlive = true
                summary.passCount += 1
            }
            if lowercased == "smokeoutcome=passed" {
                summary.passCount += 1
            }
            if lowercased == "cliwatchdog=timedout" {
                sawMacWinRunnerSmokeKeptAlive = true
                if !hasKeptAliveManagedSmoke || !lowercasedText.contains("smokeoutcome=keptalive") {
                    summary.passCount += 1
                }
            }
            if lowercased.contains("qucs-s-qt6")
                || lowercased.contains("\\qucs-s.exe")
                || lowercased.contains("/qucs-s.exe")
                || lowercased.contains("qucs-s-26.1.1-win64") {
                sawQucsSQt6Launch = true
            }
            if lowercased.contains("mremoteng-1782-x64")
                || lowercased.contains("\\mremoteng.exe")
                || lowercased.contains("/mremoteng.exe") {
                sawMRemoteNG1782Launch = true
            }
            if lowercased.contains("portableappsplatform.exe")
                || lowercased.contains("portableapps.com platform") {
                sawPortableAppsPlatformLaunch = true
            }
            if lowercased.contains("statusafter30s=0")
                || lowercased.contains("statusafter45s=0")
                || lowercased.contains("statusafter60s=0")
                || lowercased == "finalexit=0"
                || lowercased == "smokeoutcome=earlyexit" {
                sawMRemoteNGEarlyExitStatus = true
            }
            if lowercased.contains("== macwin software smoke ==") {
                sawMacWinSoftwareSmokeLaunch = false
            }
            if lowercased == "phase=launch" {
                sawMacWinSoftwareSmokeLaunch = true
            }
            if lowercased.contains("timeout after") && lowercased.contains("sending sigterm") {
                sawJASPLaunchTimeout = true
            }
            if isBenignMacWinDiagnosticsMetadataLine(lowercased) {
                continue
            }
            if lowercased == "exitcode=120"
                || lowercased.contains("mainwindow constructor-tail boundary")
                || lowercased.contains("exited after the initial datasetpackage::endloadingdata -> enginesync::enginesreceivenewdata") {
                sawJASPConstructorBoundaryExit = true
            }
            if isBenignChromiumRuntimeNoise(lowercased)
                || isBenignGeoGebraElectron32KeptAliveNoise(
                    lowercased,
                    hasKeptAliveRenderer: hasKeptAliveGeoGebraRenderer
                )
                || isBenignBeekeeperPluginUpdateNoise(lowercased)
                || isBenignConfigurationSuccessNoise(lowercased)
                || isBenignCOMProxyRepairNoise(
                    lowercased,
                    isCOMProxyRepair: isMacWinCOMProxyRepair
                )
                || isBenignSteamUpdaterNoise(lowercased)
                || isBenignMacDriverIconNoise(
                    lowercased,
                    hasKeptAliveManagedSmoke: hasKeptAliveManagedSmoke
                )
                || isBenignMacInputMethodNoise(
                    lowercased,
                    hasKeptAliveManagedSmoke: hasKeptAliveManagedSmoke
                )
                || isBenignSchannelHandshakeProgress(lowercased)
                || isBenignPassedVulkanOptionalExtensionWarning(
                    lowercased,
                    hasPassedProbe: hasPassedVulkanProbe
                )
                || isBenignCompletedJASPRuntimeNoise(
                    lowercased,
                    hasCompletedStartup: hasCompletedJASPStartup
                )
                || isBenignVerifiedPgAdminRuntimeNoise(
                    lowercased,
                    hasVerifiedCompositor: hasVerifiedPgAdminCompositor
                )
                || isBenignVerifiedOpenPLCRuntimeNoise(
                    lowercased,
                    hasVerifiedCompositor: hasVerifiedOpenPLCCompositor,
                    hasUpdateTimeout: hasVerifiedOpenPLCUpdateTimeout
                )
                || isBenignVerifiedWiresharkCaptureWarning(
                    lowercased,
                    hasVerifiedOfflineDissection: hasVerifiedWiresharkOfflineDissection
                )
                || isChromiumInfoConsoleLine(lowercased)
                || isBenignQucsSQt6StartupNoise(lowercased, sawQucsSQt6Launch: sawQucsSQt6Launch)
                || isBenignGeckoBrowserKeptAliveNoise(
                    lowercased,
                    hasKeptAliveManagedSmoke: hasKeptAliveManagedSmoke,
                    sawGeckoBrowserLaunch: sawGeckoBrowserLaunch
                )
                || isBenignPortableAppsPlatformKeptAliveThemeCrash(
                    lowercased,
                    hasKeptAliveManagedSmoke: hasKeptAliveManagedSmoke,
                    sawPortableAppsKeptAliveThemeProfile: sawPortableAppsKeptAliveThemeProfile
                )
                || isBenignMacWinSmokeLaunchTimeout(
                    lowercased,
                    sawLaunchHeader: sawMacWinSoftwareSmokeLaunch,
                    sawRunnerSmokeKeptAlive: sawMacWinRunnerSmokeKeptAlive
                )
                || isBenignKeptAliveLsfHelperCrash(
                    lowercased,
                    hasBenignMainProcessOutcome: hasKeptAliveManagedSmoke || hasSuccessfulPassedProbe,
                    sawLsfHelperFailure: &sawBenignLsfHelperFailure
                )
                || isBenignTencentAndrowsKeptAliveNoise(
                    lowercased,
                    sawTencentAppStoreLaunch: sawTencentAppStoreLaunch,
                    hasBenignMainProcessOutcome: hasKeptAliveManagedSmoke || hasSuccessfulPassedProbe
                ) {
                continue
            }
            let benignMSIDetailMetadataLine = isBenignMSIDetailMetadataLine(lowercased)
            let launchMetadataLine = isMacWinLaunchMetadataLine(lowercased)
            let benignPassedIpcFileMappingProbeLine = hasPassedIpcFileMappingProbe
                && (lowercased.hasPrefix("lock.second=blocked error=")
                    || lowercased.contains("\\macwinipcprobe\\jasp-ipc-")
                    || lowercased.hasPrefix("heartbeat.path="))
            if lowercased.contains("enginesync::enginespreparefordata")
                || lowercased.contains("enginesync::enginesreceivenewdata")
                || (!hasPassedIpcFileMappingProbe && lowercased.contains("jasp-ipc-"))
                || lowercased.contains("trace.jaspipc") {
                sawJASPEngineSync = true
            }
            if lowercased.contains("qtwebenginequick initialized") {
                sawJASPQtWebEngineInitialized = true
            }
            if lowercased.contains("qml initialized!")
                || lowercased.contains("qml loaded, url:")
                || lowercased == "jaspstartupmilestone=passed"
                || lowercased == "jaspstartupqmlinitialized=yes" {
                sawJASPQmlInitialized = true
            }
            if lowercased.contains("loading themes") {
                sawJASPLoadingThemes = true
            }
            if lowercased.contains("jasp desktop started and engines initalized") {
                sawJASPDesktopStarted = true
            }
            if lowercased == "jaspstartupmilestone=passed"
                || lowercased == "jaspstartupresultspageloaded=yes" {
                sawJASPDesktopStarted = true
            }
            if lowercased.contains("could not load qml: qrc:/components/jasp/")
                || lowercased.contains("could not load qml: qrc:///components/jasp/")
                || lowercased.contains("could not load qml: file:///c:/program files/jasp/components/jasp/") {
                sawJASPQrcQmlResourceFailure = true
            }
            if lowercased.contains("c0000409")
                || lowercased.contains("ntlockfile i/o completion on lock not implemented")
                || lowercased.contains("boost::interprocess")
                || lowercased.contains("interprocess_exception@interprocess@boost") {
                sawJASPFailFastOrLockFailure = true
            }
            if lowercased.contains("msiexec") || lowercased.contains(".msi") {
                sawMSICommandOrPath = true
            }
            if lowercased.contains("shellexecuteex failed: file not found") {
                sawShellExecuteFileNotFound = true
            }
            if lowercased.contains("failed to open") && lowercased.contains("msiexec.exe") {
                sawMissingMSIExecutable = true
            }
            if lowercased.contains("googlechromestandaloneenterprise")
                || lowercased.contains("google chrome")
                || lowercased.contains("appguid={8a69d345-d564-463c-aff1-a69d9e530f96}")
                || lowercased.contains("microsoftedgeenterprisex64")
                || lowercased.contains("microsoft edge")
                || lowercased.contains("edgeupdate")
                || lowercased.contains("appguid={56eb18f8-b008-4cbd-b6d2-8c97fe7e9062}")
                || lowercased.contains("bravebrowserstandalonesetup")
                || lowercased.contains("braveupdate")
                || lowercased.contains("brave-release")
                || lowercased.contains("appguid={afe6a462-c574-4b8a-af43-4cc60df4563b}")
                || lowercased.contains("enterprisemsi") {
                sawChromiumEnterpriseInstaller = true
            }
            if lowercased.contains("action ended")
                && lowercased.contains("doinstall")
                && lowercased.contains("return value 0") {
                sawChromiumUpdaterInstallFailure = true
                summary.failCount += 1
            }
            if lowercased.contains("action ended")
                && lowercased.contains("install.")
                && !lowercased.contains("doinstall")
                && lowercased.contains("return value 0") {
                sawChromiumUpdaterInstallFailure = true
                summary.failCount += 1
            }
            if lowercased.contains("no psfactorybuffer object is registered")
                || lowercased.contains("failed to create an irpcstubbuffer")
                || lowercased.contains("failed to marshal the interface")
                || lowercased.contains("apartment_get_local_server_stream failed")
                || (lowercased.contains("rpcrt4_conn_open_pipe") && lowercased.contains("irpcss"))
                || (lowercased.contains("cogetclassobject") && lowercased.contains("ipsfactorybuffer")) {
                sawCOMProxyMarshallingFailure = true
                summary.failCount += 1
            }
            if !benignMSIDetailMetadataLine
                && !benignPassedIpcFileMappingProbeLine
                && (lowercased.contains("err:") || lowercased.contains("error") || lowercased.contains("exception")) {
                summary.errorCount += 1
            }
            if !benignMSIDetailMetadataLine && (lowercased.contains("warn:") || lowercased.contains("warning")) {
                summary.warningCount += 1
            }
            if lowercased.contains("fixme:") {
                summary.fixmeCount += 1
            }
            if line.contains("PASS") {
                summary.passCount += 1
            }
            if !benignMSIDetailMetadataLine && (line.contains("FAIL") || lowercased.contains("failed")) {
                summary.failCount += 1
            }

            if line.contains("WSALookupServiceBegin failed") {
                hints.insert(.steamNetworkProbe)
            }
            if lowercased.contains("open ebadf") || lowercased.contains("bootstrap/switches/is_main_thread") {
                hints.insert(.electronStdout)
            }
            if lowercased.contains("program error") || lowercased.contains("encountered a serious problem") {
                hints.insert(.wineProgramError)
            }
            if lowercased.contains("native crash reporting")
                || lowercased.contains("fatal error in the mono runtime")
                || lowercased.contains("wine mono is not installed")
                || lowercased.contains("mscoree.dll not found")
                || lowercased.contains("hostfxr")
                || lowercased.contains("hostpolicy")
                || lowercased.contains("coreclr")
                || lowercased.contains("system.runtime.dll")
                || lowercased.contains("clrruntimeinfo_getruntimehost")
                || lowercased.contains("you must install .net to run this application")
                || lowercased.contains("download the .net runtime")
                || lowercased.contains("app host version") {
                hints.insert(.dotnetRuntimeIssue)
                summary.failCount += 1
            }
            if lowercased.contains("unhandled page fault")
                || lowercased.contains("access violation")
                || lowercased.contains("exception_access_violation")
                || lowercased.contains("starting debugger")
                || lowercased.contains("segmentation fault") {
                sawWineCrashLine = true
                hints.insert(.wineCrash)
            }
            if lowercased.contains("vulkan") && (lowercased.contains("fail") || lowercased.contains("error")) {
                hints.insert(.vulkanIssue)
            }
            if (lowercased.contains("gnutls")
                || lowercased.contains("certificate")
                || lowercased.contains("winhttp")
                || lowercased.contains("ssl connection could not be established")
                || lowercased.contains("error fetching latest version"))
                && (lowercased.contains("fail") || lowercased.contains("error")) {
                hints.insert(.networkTLSIssue)
            }
            if lowercased.contains("d3dmetal") && (lowercased.contains("missing") || lowercased.contains("error")) {
                hints.insert(.d3dMetalRuntime)
            }
            if hasD3DMetalPreset && (lowercased.contains("wineserver crashed")
                || lowercased.contains("unimplemented function ntdll.dll.__wine_unix_call")) {
                hints.insert(.d3dMetalRuntime)
                summary.failCount += 1
            }
            if !launchMetadataLine && (lowercased.contains("gpu_channel")
                || lowercased.contains("shared_image_stub")
                || lowercased.contains("vizdisplaycompositor")
                || lowercased.contains("directcomposition")
                || lowercased.contains("cefview")
                || lowercased.contains("failed to send gpucontrol.createcommandbuffer")
                || lowercased.contains("wgl_nv_dx_interop2 is required")
                || lowercased.contains("eglcreatewindowsurface failed")) {
                hints.insert(.cefRenderingIssue)
            }
            if !launchMetadataLine && ((lowercased.contains("gpu") && (lowercased.contains("fail") || lowercased.contains("error")))
                || lowercased.contains("failed to create gles")
                || lowercased.contains("passthrough is not supported")
                || lowercased.contains("failed to create shared context")
                || lowercased.contains("requested gles version")
                || lowercased.contains("egl_bad_surface")
                || lowercased.contains("wgl_nv_dx_interop2 is required")) {
                hints.insert(.gpuRenderingIssue)
            }
            if !launchMetadataLine && (lowercased.contains("disable-direct-write")
                || lowercased.contains("disable-remote-fonts")
                || lowercased.contains("disable-font-subpixel-positioning")
                || lowercased.contains("disable-lcd-text")
                || lowercased.contains("disable-prefer-compositing-to-lcd-text")
                || lowercased.contains("font-render-hinting=none")
                || lowercased.contains("dwritefontproxy")
                || lowercased.contains("fontsrclocalmatching")
                || lowercased.contains("fontationsfontbackend")
                || lowercased.contains("missing glyph")
                || lowercased.contains("font fallback")) {
                hints.insert(.fontRenderingIssue)
            }
            if lowercased.contains("black screen")
                || lowercased.contains("blank screen")
                || lowercased.contains("blank window")
                || lowercased.contains("empty window")
                || lowercased.contains("white screen")
                || lowercased.contains("renderer produced no frame")
                || lowercased.contains("swapchain produced no frame")
                || lowercased.contains("presented black frame")
                || lowercased.contains("gdi_missing_glyphs=")
                || lowercased.contains("missing glyphs detected") {
                hints.insert(.blankWindowIssue)
            }
            if lowercased.contains("window_input")
                || lowercased.contains("windowfrompoint mismatch")
                || lowercased.contains("hit-test transparent")
                || lowercased.contains("focus mismatch")
                || lowercased.contains("click messages not observed")
                || lowercased.contains("httransparent")
                || lowercased.contains("ws_ex_transparent") {
                hints.insert(.windowInputIssue)
            }
            if lowercased.contains("bad exe format")
                || lowercased.contains("could not load kernel32")
                || lowercased.contains("exception frame is not in stack limits")
                || lowercased.contains("unable to dispatch exception")
                || (lowercased.contains("32-bit") && (lowercased.contains("requires") || lowercased.contains("missing") || lowercased.contains("unsupported")))
                || (lowercased.contains("wow64") && (lowercased.contains("requires") || lowercased.contains("missing") || lowercased.contains("unsupported") || lowercased.contains("fail") || lowercased.contains("error"))) {
                hints.insert(.win32CompatibilityIssue)
            }
            if (lowercased.contains("import_dll library") && lowercased.contains("not found"))
                || (lowercased.contains("failed to load module") && lowercased.contains("status=c0000135"))
                || (lowercased.contains("loader_init importing dlls") && lowercased.contains("failed")) {
                hints.insert(.missingDLLIssue)
            }
            if !benignMSIDetailMetadataLine && (lowercased.contains("installer failed")
                || lowercased.contains("nsis error")
                || lowercased.contains("hash check failed")
                || lowercased.contains("catalog recipe hash mismatch")
                || (lowercased.contains("msiexec") && (lowercased.contains("fail") || lowercased.contains("error")))) {
                hints.insert(.installerIssue)
            }
            if lowercased.contains("timeout")
                || lowercased.contains("timed out")
                || lowercased.contains("operation timed out") {
                hints.insert(.timeout)
                summary.failCount += 1
                if sawChromiumEnterpriseInstaller {
                    sawChromiumUpdaterInstallFailure = true
                }
            }
        }

        if sawMissingMSIExecutable || (sawMSICommandOrPath && sawShellExecuteFileNotFound) {
            hints.insert(.msiRuntimeIssue)
            hints.insert(.installerIssue)
        }
        if sawChromiumEnterpriseInstaller && sawChromiumUpdaterInstallFailure {
            hints.insert(.chromeOmahaInstallerIssue)
            hints.insert(.installerIssue)
        }
        if sawCOMProxyMarshallingFailure {
            hints.insert(.comProxyMarshallingIssue)
        }
        if sawJASPEngineSync && sawJASPFailFastOrLockFailure {
            hints.insert(.jaspEngineIpcIssue)
            hints.insert(.wineCrash)
        }
        if sawJASPQtWebEngineInitialized && sawJASPEngineSync && sawJASPQrcQmlResourceFailure && hints.contains(.wineCrash) {
            hints.insert(.jaspQrcQmlResourceIssue)
            summary.failCount += 1
        }
        if sawJASPQtWebEngineInitialized && sawJASPEngineSync && (sawJASPLaunchTimeout || sawJASPConstructorBoundaryExit) && !sawJASPDesktopStarted && !sawJASPLoadingThemes && !sawJASPQmlInitialized {
            hints.insert(.jaspQmlInitializationHangIssue)
            summary.failCount += 1
        }
        if sawMRemoteNG1782Launch && sawMRemoteNGEarlyExitStatus {
            hints.insert(.mRemoteNGEarlyExitIssue)
        }
        let sawPortableAppsKnownSEHExit = lowercasedText.contains("exitcode=41")
            || lowercasedText.contains("exitcode=216")
        if sawPortableAppsPlatformLaunch,
           hints.contains(.wineCrash) || sawPortableAppsKnownSEHExit,
           hints.contains(.win32CompatibilityIssue) || sawPortableAppsKnownSEHExit {
            if sawPortableAppsKnownSEHExit {
                hints.insert(.wineCrash)
                summary.failCount += 1
            }
            hints.insert(.portableAppsSEHIssue)
            hints.insert(.win32CompatibilityIssue)
        }
        if sawLenovoAppStoreLaunch,
           sawLenovoBusinessMessageAfterCrash,
           hints.contains(.wineCrash),
           !hints.contains(.wineProgramError) {
            hints.remove(.wineCrash)
            summary.passCount = max(summary.passCount, 1)
        }
        if hasSuccessfulManagedSmoke && hints.isEmpty {
            summary.errorCount = 0
            summary.failCount = 0
        }
        if summary.passCount > 0 {
            hints.insert(.passObserved)
        }
        summary.hints = LogHint.allCases.filter { hints.contains($0) }
        return summary
    }

    private static func isBenignChromiumRuntimeNoise(_ lowercasedLine: String) -> Bool {
        (lowercasedLine.contains("proxy_config_service_win.cc")
            && lowercasedLine.contains("winhttpgetieproxyconfigforcurrentuser failed"))
            || (lowercasedLine.contains("dns_config_service_win.cc")
                && lowercasedLine.contains("failed to read dnsconfig"))
            || (lowercasedLine.contains("system_geolocation_source_win.cc")
                && lowercasedLine.contains("failed to get iappcapability statics"))
            || (lowercasedLine.contains("webauthn_api.cc")
                && lowercasedLine.contains("windows webauthn api failed to load"))
            || (lowercasedLine.contains("user_agent_utils.cc")
                && lowercasedLine.contains("uao file invalid; all fields are not present"))
            || (lowercasedLine.contains("chrome_command_line_pref_store.cc")
                && lowercasedLine.contains("additional command-line proxy switches specified"))
            || (lowercasedLine.contains("cert_verify_proc_builtin.cc")
                && lowercasedLine.contains("no net_fetcher for performing aia chasing"))
            || (lowercasedLine.contains("abtest_service.cc")
                && lowercasedLine.contains("data->data->code is not zero"))
            || (lowercasedLine.contains("address_sorter_win.cc")
                && lowercasedLine.contains("sio_address_list_sort failed"))
            || (lowercasedLine.contains("egl_util.cc")
                && lowercasedLine.contains("eglcreatecontext")
                && lowercasedLine.contains("requested version is not supported"))
            || (lowercasedLine.contains("gl_context_egl.cc")
                && lowercasedLine.contains("eglcreatecontext es 3.0 failed with error egl_bad_attribute"))
            || (lowercasedLine.contains("warning: disabling flag")
                && lowercasedLine.contains("due to conflicting flags"))
            || lowercasedLine.contains("this warning will not show up")
    }

    private static func isBenignCompletedJASPRuntimeNoise(
        _ lowercasedLine: String,
        hasCompletedStartup: Bool
    ) -> Bool {
        guard hasCompletedStartup else { return false }
        return (lowercasedLine.contains("gpu_channel_manager.cc")
            && (lowercasedLine.contains("failed to create gles3 context")
                || lowercasedLine.contains("failed to create shared context for virtualization")))
            || (lowercasedLine.contains("loading upgrades.qml had the following std:runtime_error")
                && lowercasedLine.contains("this will be ignored"))
            || (lowercasedLine.contains("qml webengineprofile")
                && lowercasedLine.contains("please use webengineprofileprototype")
                && lowercasedLine.contains("deprecated in the future releases"))
    }

    private static func isBenignVerifiedPgAdminRuntimeNoise(
        _ lowercasedLine: String,
        hasVerifiedCompositor: Bool
    ) -> Bool {
        guard hasVerifiedCompositor else { return false }
        return lowercasedLine.contains("net_errors_win.cc")
            && lowercasedLine.contains("unknown error 10042 mapped to net::err_failed")
    }

    private static func isBenignVerifiedOpenPLCRuntimeNoise(
        _ lowercasedLine: String,
        hasVerifiedCompositor: Bool,
        hasUpdateTimeout: Bool
    ) -> Bool {
        guard hasVerifiedCompositor else { return false }

        if lowercasedLine.contains("accelerator_util.cc")
            && lowercasedLine.contains("doesn't contain a valid key") {
            return true
        }
        if lowercasedLine.contains("viz_main_impl.cc")
            && lowercasedLine.contains("viznullhypothesis is disabled") {
            return true
        }
        if lowercasedLine.contains(":info:console(")
            && lowercasedLine.contains("uncaught referenceerror: global is not defined") {
            return true
        }
        guard hasUpdateTimeout else { return false }
        return lowercasedLine.contains("net::err_timed_out")
            || lowercasedLine.contains("unhandledpromiserejectionwarning")
            || lowercasedLine.contains("trace-warnings")
    }

    private static func isBenignVerifiedWiresharkCaptureWarning(
        _ lowercasedLine: String,
        hasVerifiedOfflineDissection: Bool
    ) -> Bool {
        guard hasVerifiedOfflineDissection else { return false }
        return lowercasedLine.contains("capture warning")
            && lowercasedLine.contains("unable to load npcap")
            && lowercasedLine.contains("wpcap.dll")
    }

    private static func isBenignGeoGebraElectron32KeptAliveNoise(
        _ lowercasedLine: String,
        hasKeptAliveRenderer: Bool
    ) -> Bool {
        guard hasKeptAliveRenderer else { return false }
        return lowercasedLine.contains("unrecognized option")
            || lowercasedLine.contains("attempt to load file --")
            || lowercasedLine.contains("cannot open file")
            || lowercasedLine.contains("error on tryspawn")
            || (lowercasedLine.contains("os_crypt_win.cc")
                && lowercasedLine.contains("failed to encrypt"))
            || (lowercasedLine.contains("core_audio_util_win.cc")
                && (lowercasedLine.contains("cocreateinstance")
                    || lowercasedLine.contains("failed to create core audio")))
            || (lowercasedLine.contains("gpu_process_host.cc")
                && lowercasedLine.contains("gpu process exited unexpectedly"))
            || (lowercasedLine.contains("viz_main_impl.cc")
                && lowercasedLine.contains("exiting gpu process due to errors during initialization"))
            || (lowercasedLine.contains("gpu_channel_manager.cc")
                && (lowercasedLine.contains("failed to create gles3 context")
                    || lowercasedLine.contains("failed to create shared context")))
            || lowercasedLine.contains("rosetta error: no code fragment associated with the given arm pc")
    }

    private static func isBenignBeekeeperPluginUpdateNoise(_ lowercasedLine: String) -> Bool {
        lowercasedLine.contains("(pluginmanager)")
            && lowercasedLine.contains("failed to check for updates for plugin")
    }

    private static func isBenignConfigurationSuccessNoise(_ lowercasedLine: String) -> Bool {
        lowercasedLine.contains("configs successfully loaded with 0 warnings")
    }

    private static func isBenignCOMProxyRepairNoise(
        _ lowercasedLine: String,
        isCOMProxyRepair: Bool
    ) -> Bool {
        guard isCOMProxyRepair,
              lowercasedLine.contains("regsvr32: failed to register dll") else {
            return false
        }
        return ["taskschd.dll", "mstask.dll", "msxml3.dll", "msxml6.dll"]
            .contains(where: { lowercasedLine.contains($0) })
    }

    private static func isBenignSteamUpdaterNoise(_ lowercasedLine: String) -> Bool {
        lowercasedLine.contains("failed to load cached hosts file")
            && lowercasedLine.contains("using defaults")
    }

    private static func isBenignMacDriverIconNoise(
        _ lowercasedLine: String,
        hasKeptAliveManagedSmoke: Bool
    ) -> Bool {
        hasKeptAliveManagedSmoke
            && lowercasedLine.contains("warn:macdrv:macdrv_app_icon")
            && lowercasedLine.contains("found no rt_group_icon resource")
    }

    private static func isBenignMacInputMethodNoise(
        _ lowercasedLine: String,
        hasKeptAliveManagedSmoke: Bool
    ) -> Bool {
        guard hasKeptAliveManagedSmoke else { return false }
        return lowercasedLine.contains("error messaging the mach port for imkcfrunloopwakeupreliable")
            || lowercasedLine.contains("tsm adjustcapslockledforkeytransitionhandling")
    }

    private static func isBenignSchannelHandshakeProgress(_ lowercasedLine: String) -> Bool {
        lowercasedLine.contains("* schannel:")
            && (lowercasedLine.contains("failed to receive handshake, need more data")
                || lowercasedLine.contains("received incomplete message, need more data"))
    }

    private static func isBenignPassedVulkanOptionalExtensionWarning(
        _ lowercasedLine: String,
        hasPassedProbe: Bool
    ) -> Bool {
        guard hasPassedProbe,
              lowercasedLine.contains("warn:vulkan:init_physical_device"),
              lowercasedLine.contains("extension"),
              lowercasedLine.contains("is not supported") else {
            return false
        }
        return lowercasedLine.contains("vk_ext_metal_objects")
            || lowercasedLine.contains("vk_google_display_timing")
    }

    private static func isChromiumInfoConsoleLine(_ lowercasedLine: String) -> Bool {
        lowercasedLine.contains(":info:console:")
    }

    private static func isBenignMacWinDiagnosticsMetadataLine(_ lowercasedLine: String) -> Bool {
        let trimmed = lowercasedLine.trimmingCharacters(in: .whitespacesAndNewlines)
        let diagnosticPrefixes = [
            "candidatefix.",
            "correlation.",
            "derived.",
            "jaspipcsnapshot.",
            "jasptimeout.",
            "jasptimeoutdiagnostics",
            "jaspmodelreset",
            "nextExperiment.".lowercased(),
            "patchedderived.",
            "patchedsource.",
            "seen=",
            "absent=",
            "source.",
            "sourceline.",
            "sourcepatch."
        ]
        return trimmed.hasPrefix("timeoutseconds=")
            || trimmed.hasPrefix("## timeout diagnostics")
            || trimmed.hasPrefix("liveprocesssnapshot=")
            || trimmed.hasPrefix("liveprocesssnapshotphase=")
            || diagnosticPrefixes.contains(where: { trimmed.hasPrefix($0) })
            || (trimmed.hasPrefix("trace.")
                && (trimmed.hasSuffix("=0") || trimmed.hasSuffix("=no")))
            || trimmed.contains("com.apple.rosetta.exceptionserver")
            || isMacWinProcessSnapshotRow(trimmed)
            || trimmed == "timedout=false"
            || trimmed == "exitcode=0"
    }

    private static func isMacWinProcessSnapshotRow(_ line: String) -> Bool {
        let fields = line.split(maxSplits: 5, whereSeparator: { $0.isWhitespace })
        guard fields.count == 6,
              Int(fields[0]) != nil,
              Int(fields[1]) != nil else {
            return false
        }
        return line.contains("c:\\")
            || line.contains("/wine")
            || line.contains("/rosettax87")
    }

    private static func isBenignQucsSQt6StartupNoise(
        _ lowercasedLine: String,
        sawQucsSQt6Launch: Bool
    ) -> Bool {
        guard sawQucsSQt6Launch else { return false }
        return (lowercasedLine.contains("warning: qfont::fromstring: invalid description")
            && (lowercasedLine.contains("'(empty)'")
                || lowercasedLine.contains("',-1,-1,5,400")))
            || (lowercasedLine.contains("warning: qfsfileengine::open: no file name specified"))
    }

    private static func isBenignGeckoBrowserKeptAliveNoise(
        _ lowercasedLine: String,
        hasKeptAliveManagedSmoke: Bool,
        sawGeckoBrowserLaunch: Bool
    ) -> Bool {
        guard hasKeptAliveManagedSmoke, sawGeckoBrowserLaunch else { return false }
        return lowercasedLine.contains("load_ratio() is irrelevant for this storage backend")
            || lowercasedLine.contains("[error neqo_glue] failed to initialize socket")
            || lowercasedLine.contains("exiting due to channel error")
            || (lowercasedLine.contains("remotemediamanager is not available")
                && lowercasedLine.contains("decode error"))
            || (lowercasedLine.contains("crash annotation graphicscriticalerror")
                && lowercasedLine.contains("rendercompositorswgl failed mapping default framebuffer"))
            || lowercasedLine.contains("rendercompositorswgl failed mapping default framebuffer")
    }

    private static func isBenignPortableAppsPlatformKeptAliveThemeCrash(
        _ lowercasedLine: String,
        hasKeptAliveManagedSmoke: Bool,
        sawPortableAppsKeptAliveThemeProfile: Bool
    ) -> Bool {
        guard hasKeptAliveManagedSmoke, sawPortableAppsKeptAliveThemeProfile else { return false }
        return (lowercasedLine.contains("unhandled page fault")
            && lowercasedLine.contains("starting debugger"))
            || (lowercasedLine.contains("err:winedbg:dbg_handle_debug_event")
                && lowercasedLine.contains("unknown process"))
            || lowercasedLine.contains("fixme:thread:get_thread_times")
    }

    private static func isBenignMacWinSmokeLaunchTimeout(
        _ lowercasedLine: String,
        sawLaunchHeader: Bool,
        sawRunnerSmokeKeptAlive: Bool
    ) -> Bool {
        guard sawLaunchHeader || sawRunnerSmokeKeptAlive else { return false }
        return (lowercasedLine.contains("timeout after")
            && lowercasedLine.contains("sending sigterm"))
            || lowercasedLine.contains("requesting wineserver -k for smoke timeout cleanup")
            || lowercasedLine == "cliwatchdog=timedout"
            || lowercasedLine.hasPrefix("cliwatchdogtimeoutseconds=")
            || lowercasedLine.hasPrefix("smoketimeoutseconds=")
            || lowercasedLine.hasPrefix("wineservercleanup=")
            || lowercasedLine.hasPrefix("runtimecleanuprequested=")
            || lowercasedLine.hasPrefix("runtimecleanupstopped=")
            || lowercasedLine.hasPrefix("runtimecleanupfailed=")
    }

    private static func isBenignKeptAliveLsfHelperCrash(
        _ lowercasedLine: String,
        hasBenignMainProcessOutcome: Bool,
        sawLsfHelperFailure: inout Bool
    ) -> Bool {
        guard hasBenignMainProcessOutcome else { return false }
        if lowercasedLine.contains("failed to start")
            && lowercasedLine.contains("lsf.exe")
            && lowercasedLine.contains("c0000135") {
            sawLsfHelperFailure = true
            return true
        }
        if sawLsfHelperFailure
            && lowercasedLine.contains("unhandled page fault")
            && lowercasedLine.contains("starting debugger") {
            return true
        }
        return false
    }

    private static func isBenignTencentAndrowsKeptAliveNoise(
        _ lowercasedLine: String,
        sawTencentAppStoreLaunch: Bool,
        hasBenignMainProcessOutcome: Bool
    ) -> Bool {
        guard sawTencentAppStoreLaunch, hasBenignMainProcessOutcome else { return false }

        return lowercasedLine.contains("crashpad_client_win.cc")
            || lowercasedLine.contains("xweb_crashpad_global_data.cc")
            || lowercasedLine.contains("registration_protocol_win.cc")
            || lowercasedLine.contains("mmcrashpad_client.cc")
            || (lowercasedLine.contains("flue_browser_global_storage.cc")
                && lowercasedLine.contains("getsafemmkv"))
            || (lowercasedLine.contains("mmkv")
                && lowercasedLine.contains("xweb_config_storage"))
    }

    private static func isBenignMSIDetailMetadataLine(_ lowercasedLine: String) -> Bool {
        let trimmed = lowercasedLine.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed.hasPrefix("property(") && trimmed.contains("):"))
            || (trimmed.hasPrefix("file:")
                && trimmed.contains("directory:")
                && trimmed.contains("size:"))
    }

    private static func isMacWinLaunchMetadataLine(_ lowercasedLine: String) -> Bool {
        let trimmed = lowercasedLine.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("env.")
            || trimmed.hasPrefix("command=")
            || trimmed.hasPrefix("cmd=")
            || trimmed.hasPrefix("args=")
            || trimmed.hasPrefix("workingdirectory=")
    }

    public static func issueReport(logs: [LogFileItem], failureLimit: Int = 12) -> LogIssueReport {
        let activeLogs = logsExcludingSupersededFailures(logs)
        let trends = logIssueDefinitions.compactMap { definition -> LogIssueTrend? in
            let hintNames = Set(definition.hints.map(\.rawValue))
            let affected = activeLogs.filter { item in
                guard item.summary.health == .failed || item.summary.health == .attention else { return false }
                let entryHints = Set(item.summary.hints.map(\.rawValue))
                return !entryHints.isDisjoint(with: hintNames)
            }
            guard !affected.isEmpty else { return nil }
            return LogIssueTrend(
                id: definition.id,
                severity: definition.severity,
                title: definition.title,
                detail: definition.detail,
                count: affected.count,
                relatedHints: definition.hints.map(\.rawValue),
                affectedLogNames: affected.map(\.name).sorted(),
                recommendedActions: definition.recommendedActions,
                probeAssetIds: definition.probeAssetIds
            )
        }

        let genericFailures = activeLogs.filter { item in
            item.summary.health == .failed && issueIds(for: item.summary.hints).isEmpty
        }
        var allTrends = trends
        if !genericFailures.isEmpty {
            allTrends.append(
                LogIssueTrend(
                    id: "unclassified-failure",
                    severity: "medium",
                    title: "Unclassified failures",
                    detail: "Logs have errors or FAIL markers but do not match a known MacWin hint yet. Inspect these raw logs and promote recurring signatures into LogService hints.",
                    count: genericFailures.count,
                    relatedHints: [],
                    affectedLogNames: genericFailures.map(\.name).sorted(),
                    recommendedActions: [
                        "Open the raw log and identify the first recurring error signature.",
                        "If the error repeats across apps, add a LogService hint and connect it to a probe."
                    ],
                    probeAssetIds: ["console"]
                )
            )
        }

        let sortedTrends = allTrends.sorted { lhs, rhs in
            let lhsRank = issueSeverityRank(lhs.severity)
            let rhsRank = issueSeverityRank(rhs.severity)
            if lhsRank != rhsRank { return lhsRank < rhsRank }
            if lhs.count != rhs.count { return lhs.count > rhs.count }
            return lhs.id < rhs.id
        }

        let recentFailures = activeLogs
            .filter { $0.summary.health == .failed || $0.summary.health == .attention }
            .prefix(failureLimit)
            .map { item in
                let issueIds = issueIds(for: item.summary.hints)
                let probableIssueIds = issueIds.isEmpty && item.summary.health == .failed ? ["unclassified-failure"] : issueIds
                return LogIssueSample(
                    name: item.name,
                    path: item.url.path,
                    modifiedAt: item.modifiedAt,
                    health: item.summary.health.rawValue,
                    errorCount: item.summary.errorCount,
                    warningCount: item.summary.warningCount,
                    fixmeCount: item.summary.fixmeCount,
                    passCount: item.summary.passCount,
                    failCount: item.summary.failCount,
                    hints: item.summary.hints.map(\.rawValue),
                    probableIssueIds: probableIssueIds,
                    evidenceSnippets: evidenceSnippets(for: item, issueIds: probableIssueIds),
                    recommendedActions: recommendedActions(for: probableIssueIds),
                    probeAssetIds: probeAssetIds(for: probableIssueIds),
                    launchContext: item.launchContext
                )
            }

        return LogIssueReport(
            logs: activeLogs,
            topIssues: sortedTrends,
            recentFailures: Array(recentFailures)
        )
    }

    private static func logsExcludingSupersededFailures(_ logs: [LogFileItem]) -> [LogFileItem] {
        var latestPassingByIdentity: [String: Date] = [:]
        for item in logs where item.summary.health == .passed {
            guard let identity = logSupersessionIdentity(for: item) else { continue }
            let eventDate = logSupersessionDate(for: item)
            if latestPassingByIdentity[identity].map({ eventDate > $0 }) ?? true {
                latestPassingByIdentity[identity] = eventDate
            }
        }
        guard !latestPassingByIdentity.isEmpty else { return logs }

        return logs.filter { item in
            guard item.summary.health == .failed || item.summary.health == .attention,
                  let identity = logSupersessionIdentity(for: item),
                  let passingDate = latestPassingByIdentity[identity] else {
                return true
            }
            return passingDate <= logSupersessionDate(for: item)
        }
    }

    private static func logSupersessionDate(for item: LogFileItem) -> Date {
        item.launchContext?.endedAt ?? item.launchContext?.startedAt ?? item.modifiedAt
    }

    private static func logSupersessionIdentity(for item: LogFileItem) -> String? {
        if let context = item.launchContext,
           let app = appIdentity(from: context.exe) {
            return "\(context.bottleId.lowercased())|\(app)"
        }

        if item.url.path.contains("/SoftwareSmokeRuns/"),
           item.name.lowercased().hasSuffix(".log") {
            return "software-smoke|\(item.name.lowercased())"
        }

        var bottleId: String?
        var executable: String?
        if let data = try? tailData(file: item.url, maxBytes: 16 * 1024),
           let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) {
            for line in text.components(separatedBy: .newlines) {
                if line.hasPrefix("bottleId=") {
                    let value = String(line.dropFirst("bottleId=".count))
                    bottleId = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                } else if line.hasPrefix("exe=") {
                    let value = String(line.dropFirst("exe=".count))
                    executable = value.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            if executable == nil {
                executable = text
            }
        }

        let app = executable.flatMap(appIdentity(from:)) ?? appIdentity(from: item.name)
        guard let app else { return nil }
        return "\((bottleId ?? inferredBottleId(from: item.name) ?? "unknown").lowercased())|\(app)"
    }

    private static func inferredBottleId(from logName: String) -> String? {
        logName.lowercased().hasPrefix("high-performance-win11-") ? "high-performance-win11" : nil
    }

    private static func appIdentity(from value: String) -> String? {
        let lowercased = value.lowercased()
        if lowercased.contains("mremoteng") {
            return "mremoteng"
        }
        if lowercased.contains("tencent-app-store")
            || lowercased.contains("androwsstore.exe")
            || lowercased.contains("\\tencent\\androws\\")
            || lowercased.contains("/tencent/androws/") {
            return "tencent-app-store"
        }
        if lowercased.contains("lenovoappstore")
            || lowercased.contains("leappstore")
            || lowercased.contains("androwslauncher")
            || lowercased.contains("lenovo-") {
            return "lenovo-app-store"
        }
        if lowercased.contains("musescore") {
            return "musescore"
        }
        if lowercased.contains("steam") {
            return "steam"
        }
        if lowercased.contains("sumatrapdf") {
            return "sumatrapdf"
        }
        if lowercased.contains("notepad++") || lowercased.contains("notepad-plus-plus") {
            return "notepad-plus-plus"
        }
        if lowercased.contains("7-zip")
            || lowercased.contains("7zip")
            || lowercased.contains("7zfm.exe")
            || lowercased.contains("7zg.exe")
            || lowercased.contains("7z.exe") {
            return "7zip"
        }
        if lowercased.contains("videolan")
            || lowercased.contains("vlc.exe")
            || lowercased.contains("vlc-") {
            return "vlc"
        }
        if lowercased.contains("libreoffice")
            || lowercased.contains("swriter.exe")
            || lowercased.contains("scalc.exe")
            || lowercased.contains("simpress.exe")
            || lowercased.contains("soffice.exe") {
            return "libreoffice"
        }
        if lowercased.contains("firefox")
            || lowercased.contains("mozilla firefox") {
            return "firefox"
        }
        if lowercased.contains("hoyoplay") || lowercased.contains("mihoyo") || lowercased.contains("hyp.exe") {
            return "hoyoplay"
        }
        if lowercased.contains("portableappsplatform.exe")
            || lowercased.contains("portableapps-platform")
            || lowercased.contains("portableapps.com platform")
            || lowercased.contains("\\portableapps\\portableapps.com\\") {
            return "portableapps-platform"
        }
        if lowercased.contains("jasp") {
            return "jasp"
        }
        if lowercased.contains("qmodmaster") {
            return "qmodmaster"
        }
        if lowercased.contains("zotero") {
            return "zotero"
        }
        if lowercased.contains("winscp") {
            return "winscp"
        }
        return nil
    }

    public static func triageMarkdown(report: LogIssueReport, generatedAt: Date = Date()) -> String {
        let formatter = ISO8601DateFormatter()
        var lines: [String] = [
            "# MacWin Log Triage",
            "",
            "- Generated: \(formatter.string(from: generatedAt))",
            "- Logs analyzed: \(report.logsAnalyzed)",
            "- Failed: \(report.failedLogCount)",
            "- Attention: \(report.attentionLogCount)",
            "- Passed: \(report.passedLogCount)",
            "- Quiet: \(report.quietLogCount)",
            "- Errors: \(report.totalErrorCount)",
            "- Warnings: \(report.totalWarningCount)",
            "- Fixmes: \(report.totalFixmeCount)",
            "- FAIL markers: \(report.totalFailCount)",
            ""
        ]

        lines.append("## Top Issues")
        if report.topIssues.isEmpty {
            lines.append("")
            lines.append("No known issue trends were detected in recent logs.")
        } else {
            for issue in report.topIssues {
                lines.append("")
                lines.append("### \(markdownEscaped(issue.title))")
                lines.append("")
                lines.append("- Id: `\(issue.id)`")
                lines.append("- Severity: `\(issue.severity)`")
                lines.append("- Count: \(issue.count)")
                lines.append("- Detail: \(markdownEscaped(issue.detail))")
                if !issue.relatedHints.isEmpty {
                    lines.append("- Hints: \(issue.relatedHints.map { "`\($0)`" }.joined(separator: ", "))")
                }
                if !issue.probeAssetIds.isEmpty {
                    lines.append("- Recommended probes: \(issue.probeAssetIds.map { "`\($0)`" }.joined(separator: ", "))")
                }
                if !issue.recommendedActions.isEmpty {
                    lines.append("- Recommended actions:")
                    for action in issue.recommendedActions {
                        lines.append("  - \(markdownEscaped(action))")
                    }
                }
                if !issue.affectedLogNames.isEmpty {
                    lines.append("- Affected logs:")
                    for name in issue.affectedLogNames.prefix(12) {
                        lines.append("  - `\(name)`")
                    }
                    if issue.affectedLogNames.count > 12 {
                        lines.append("  - ... \(issue.affectedLogNames.count - 12) more")
                    }
                }
            }
        }

        lines.append("")
        lines.append("## Recent Failures")
        if report.recentFailures.isEmpty {
            lines.append("")
            lines.append("No failed or attention logs were found in the recent log window.")
        } else {
            for sample in report.recentFailures {
                lines.append("")
                lines.append("### \(markdownEscaped(sample.name))")
                lines.append("")
                lines.append("- Path: `\(sample.path)`")
                lines.append("- Health: `\(sample.health)`")
                lines.append("- Modified: \(formatter.string(from: sample.modifiedAt))")
                lines.append("- Counts: errors=\(sample.errorCount) warnings=\(sample.warningCount) fixmes=\(sample.fixmeCount) fail=\(sample.failCount) pass=\(sample.passCount)")
                if !sample.probableIssueIds.isEmpty {
                    lines.append("- Probable issues: \(sample.probableIssueIds.map { "`\($0)`" }.joined(separator: ", "))")
                }
                if !sample.hints.isEmpty {
                    lines.append("- Hints: \(sample.hints.map { "`\($0)`" }.joined(separator: ", "))")
                }
                if !sample.probeAssetIds.isEmpty {
                    lines.append("- Recommended probes: \(sample.probeAssetIds.map { "`\($0)`" }.joined(separator: ", "))")
                }
                if let context = sample.launchContext {
                    lines.append("- Launch context:")
                    lines.append("  - Bottle: `\(context.bottleName)` (`\(context.bottleId)`)")
                    lines.append("  - Engine: `\(context.engineId)`")
                    lines.append("  - Executable: `\(context.exe)`")
                    if !context.args.isEmpty {
                        lines.append("  - Args: `\(context.args.joined(separator: " "))`")
                    }
                    if let pid = context.processIdentifier {
                        lines.append("  - PID: \(pid)")
                    }
                    if let exitCode = context.exitCode {
                        lines.append("  - Exit code: \(exitCode)")
                    }
                    if let errorMessage = context.errorMessage, !errorMessage.isEmpty {
                        lines.append("  - Error: \(markdownEscaped(errorMessage))")
                    }
                }
                if !sample.recommendedActions.isEmpty {
                    lines.append("- Recommended actions:")
                    for action in sample.recommendedActions {
                        lines.append("  - \(markdownEscaped(action))")
                    }
                }
                if !sample.evidenceSnippets.isEmpty {
                    lines.append("- Evidence:")
                    for snippet in sample.evidenceSnippets.prefix(6) {
                        lines.append("  ```text")
                        lines.append("  \(snippet)")
                        lines.append("  ```")
                    }
                }
            }
        }

        lines.append("")
        return lines.joined(separator: "\n")
    }

    public static func remediationPlan(report: LogIssueReport, generatedAt: Date = Date()) -> LogRemediationPlan {
        var items: [LogRemediationItem] = []
        var seen = Set<String>()

        for issue in report.topIssues {
            for (index, action) in issue.recommendedActions.enumerated() {
                let item = LogRemediationItem(
                    id: remediationId(parts: ["trend", issue.id, "\(index)", action]),
                    source: .trend,
                    severity: issue.severity,
                    issueId: issue.id,
                    title: issue.title,
                    action: action,
                    probeAssetIds: issue.probeAssetIds,
                    affectedLogNames: issue.affectedLogNames
                )
                appendUnique(item, seen: &seen, items: &items)
            }
        }

        for sample in report.recentFailures {
            let issueIds = sample.probableIssueIds.isEmpty ? ["unclassified-failure"] : sample.probableIssueIds
            let severity = sample.health == LogHealth.failed.rawValue ? "high" : "medium"
            for issueId in issueIds {
                for (index, action) in sample.recommendedActions.enumerated() {
                    let item = LogRemediationItem(
                        id: remediationId(parts: ["sample", sample.name, issueId, "\(index)", action]),
                        source: .sample,
                        severity: severity,
                        issueId: issueId,
                        title: "Review \(sample.name)",
                        action: action,
                        probeAssetIds: sample.probeAssetIds,
                        samplePaths: [sample.path],
                        evidenceSnippets: sample.evidenceSnippets,
                        bottleId: sample.launchContext?.bottleId,
                        bottleName: sample.launchContext?.bottleName,
                        engineId: sample.launchContext?.engineId,
                        exe: sample.launchContext?.exe
                    )
                    appendUnique(item, seen: &seen, items: &items)
                }
            }
        }

        let sorted = items.sorted { lhs, rhs in
            let lhsRank = issueSeverityRank(lhs.severity)
            let rhsRank = issueSeverityRank(rhs.severity)
            if lhsRank != rhsRank { return lhsRank < rhsRank }
            if lhs.issueId != rhs.issueId { return lhs.issueId < rhs.issueId }
            return lhs.id < rhs.id
        }
        return LogRemediationPlan(generatedAt: generatedAt, report: report, items: sorted)
    }

    private static func tailData(file url: URL, maxBytes: UInt64) throws -> Data {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let length = try handle.seekToEnd()
        let offset = length > maxBytes ? length - maxBytes : 0
        try handle.seek(toOffset: offset)
        return try handle.readToEnd() ?? Data()
    }

    private static func launchContextsByLogPath(
        in logsDirectory: URL,
        fileManager: FileManager
    ) -> [String: LogLaunchContext] {
        var contexts: [String: LogLaunchContext] = [:]
        var timestamps: [String: Date] = [:]
        for record in LaunchHistoryService.records(in: logsDirectory, fileManager: fileManager) {
            let canonicalLogPath = canonicalPath(record.logPath)
            if let previous = timestamps[canonicalLogPath], previous > record.startedAt {
                continue
            }
            timestamps[record.logPath] = record.startedAt
            timestamps[canonicalLogPath] = record.startedAt
            let context = LogLaunchContext(record: record)
            contexts[record.logPath] = context
            contexts[canonicalLogPath] = context
        }
        return contexts
    }

    private static func canonicalPath(_ path: String) -> String {
        URL(fileURLWithPath: path).resolvingSymlinksInPath().standardizedFileURL.path
    }

    private static func appendUnique(
        _ item: LogRemediationItem,
        seen: inout Set<String>,
        items: inout [LogRemediationItem]
    ) {
        let key = [
            item.issueId,
            item.action,
            item.probeAssetIds.joined(separator: "\u{1f}")
        ].joined(separator: "\u{1e}")
        guard !seen.contains(key) else { return }
        seen.insert(key)
        items.append(item)
    }

    private static func remediationId(parts: [String]) -> String {
        let raw = parts.joined(separator: "-").lowercased()
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        let collapsed = raw.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
            .reduce(into: "") { $0.append($1) }
        let trimmed = collapsed.trimmingCharacters(in: CharacterSet(charactersIn: "-_."))
        return String((trimmed.isEmpty ? "log-remediation" : trimmed).prefix(96))
    }

    private static func issueIds(for hints: [LogHint]) -> [String] {
        let hintNames = Set(hints.map(\.rawValue))
        return logIssueDefinitions.compactMap { definition in
            let definitionHints = Set(definition.hints.map(\.rawValue))
            return hintNames.isDisjoint(with: definitionHints) ? nil : definition.id
        }
    }

    private static func issueSeverityRank(_ severity: String) -> Int {
        switch severity {
        case "critical": 0
        case "high": 1
        case "medium": 2
        case "low": 3
        default: 4
        }
    }

    private static func evidenceSnippets(for item: LogFileItem, issueIds: [String], limit: Int = 4) -> [String] {
        guard !issueIds.isEmpty,
              let data = try? tailData(file: item.url, maxBytes: 96 * 1024),
              let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            return []
        }

        let patterns = evidencePatterns(for: issueIds)
        guard !patterns.isEmpty else { return [] }

        var snippets: [String] = []
        var seen = Set<String>()
        for rawLine in text.components(separatedBy: .newlines) {
            let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let lowercased = trimmed.lowercased()
            guard patterns.contains(where: { lowercased.contains($0) }) else { continue }
            let redacted = SupportBundleService.redactLogText(String(trimmed.prefix(260))).text
            guard !seen.contains(redacted) else { continue }
            seen.insert(redacted)
            snippets.append(redacted)
            if snippets.count >= limit { break }
        }
        return snippets
    }

    private static func evidencePatterns(for issueIds: [String]) -> [String] {
        var patterns: [String] = []
        for issueId in issueIds {
            switch issueId {
            case "wine-crash":
                patterns += ["unhandled page fault", "access violation", "program error", "encountered a serious problem", "starting debugger"]
            case "webview-rendering":
                patterns += ["gpu_channel", "shared_image_stub", "vizdisplaycompositor", "directcomposition", "cefview", "failed to create shared context", "open ebadf"]
            case "text-rendering":
                patterns += ["disable-direct-write", "disable-remote-fonts", "dwritefontproxy", "fontsrclocalmatching", "fontationsfontbackend", "missing glyph", "font fallback", "gdi_missing_glyphs"]
            case "blank-window":
                patterns += ["black screen", "blank screen", "blank window", "empty window", "white screen", "renderer produced no frame", "swapchain produced no frame", "presented black frame", "gdi_missing_glyphs"]
            case "window-input":
                patterns += ["window_input", "windowfrompoint mismatch", "hit-test transparent", "focus mismatch", "click messages not observed", "httransparent", "ws_ex_transparent"]
            case "graphics-runtime":
                patterns += ["vulkan", "d3dmetal", "failed to create gles", "passthrough is not supported", "wineserver crashed", "ntdll.dll.__wine_unix_call"]
            case "network-tls":
                patterns += ["winhttp", "certificate", "gnutls", "ssl connection could not be established", "error fetching latest version", "wsalookupservicebegin failed", "timeout", "timed out"]
            case "win32-wow64":
                patterns += ["wow64", "bad exe format", "could not load kernel32", "32-bit", "exception frame is not in stack limits", "unable to dispatch exception"]
            case "portableapps-seh":
                patterns += [
                    "portableappsplatform.exe",
                    "portableapps.com platform",
                    "wow64cpu",
                    "c0000029",
                    "ntraiseexception",
                    "exception frame is not in stack limits",
                    "unable to dispatch exception",
                    "unhandled page fault",
                    "access_violation",
                    "exitcode=216",
                    "exitcode=41",
                    "addr=00000000",
                    "eip=00000000"
                ]
            case "jasp-engine-ipc":
                patterns += ["enginesync::enginesreceivenewdata", "enginesync::enginespreparefordata", "jasp-ipc-", "trace.jaspipc", "trace.ntlockfilefixmecount", "trace.boostinterprocessexceptioncount", "c0000409", "ntlockfile i/o completion on lock not implemented", "boost::interprocess", "interprocess_exception@interprocess@boost", "heartbeat"]
            case "jasp-qrc-qml":
                patterns += ["qtwebenginequick initialized", "enginesync::enginesreceivenewdata", "could not load qml: qrc:/components/jasp/", "could not load qml: qrc:///components/jasp/", "could not load qml: file:///c:/program files/jasp/components/jasp/", "unhandled page fault", "winedbg attached"]
            case "jasp-qml-init-hang":
                patterns += ["qtwebenginequick initialized", "enginesync::enginesreceivenewdata", "timeout after", "sending sigterm", "qml initialized", "qml loaded"]
            case "dotnet-runtime":
                patterns += ["native crash reporting", "fatal error in the mono runtime", "wine mono is not installed", "mscoree.dll not found", "hostfxr", "hostpolicy", "coreclr", "system.runtime.dll", "clrruntimeinfo_getruntimehost", "you must install .net to run this application", "download the .net runtime", "microsoft.windowsdesktop.app", "microsoft.netcore.app", "app host version"]
            case "missing-builtin-dll":
                patterns += ["import_dll library", "not found", "failed to load module", "status=c0000135", "loader_init importing dlls"]
            case "msi-runtime":
                patterns += ["msiexec", ".msi", "shellexecuteex failed: file not found", "failed to open", "windows installer"]
            case "chrome-omaha-installer":
                patterns += [
                    "googlechromestandaloneenterprise",
                    "google chrome",
                    "microsoftedgeenterprisex64",
                    "microsoft edge",
                    "edgeupdate",
                    "bravebrowserstandalonesetup",
                    "braveupdate",
                    "brave-release",
                    "enterprisemsi",
                    "doinstall",
                    "installcommand",
                    "appguid={8a69d345-d564-463c-aff1-a69d9e530f96}",
                    "appguid={56eb18f8-b008-4cbd-b6d2-8c97fe7e9062}",
                    "appguid={afe6a462-c574-4b8a-af43-4cc60df4563b}"
                ]
            case "com-rpcss-marshalling":
                patterns += [
                    "no psfactorybuffer object is registered",
                    "failed to create an irpcstubbuffer",
                    "failed to marshal the interface",
                    "apartment_get_local_server_stream failed",
                    "rpcrt4_conn_open_pipe",
                    "irpcss",
                    "ipsfactorybuffer",
                    "iserviceprovider"
                ]
            case "mremoteng-early-exit":
                patterns += [
                    "mremoteng-1782-x64",
                    "mremoteng.exe",
                    "statusafter30s=0",
                    "statusafter45s=0",
                    "statusafter60s=0",
                    "finalexit=0"
                ]
            case "installer":
                patterns += ["installer failed", "nsis error", "hash check failed", "catalog recipe hash mismatch", "msiexec"]
            case "unclassified-failure":
                patterns += ["err:", "error", "exception", "fail"]
            default:
                break
            }
        }
        return orderedUnique(patterns)
    }

    private struct LogIssueDefinition {
        var id: String
        var severity: String
        var title: String
        var detail: String
        var hints: [LogHint]
        var recommendedActions: [String]
        var probeAssetIds: [String]
    }

    private static let logIssueDefinitions: [LogIssueDefinition] = [
        LogIssueDefinition(
            id: "wine-crash",
            severity: "critical",
            title: "Wine crash or program error",
            detail: "Wine reported a page fault, program error dialog, access violation, or debugger attach. Rerun the affected app with diagnostic launch logging.",
            hints: [.wineCrash, .wineProgramError],
            recommendedActions: [
                "Relaunch the affected app with diagnostic launch logging enabled.",
                "Export a support bundle before changing graphics or compatibility presets."
            ],
            probeAssetIds: ["console"]
        ),
        LogIssueDefinition(
            id: "webview-rendering",
            severity: "high",
            title: "CEF/WebView renderer failure",
            detail: "Logs contain Chromium, CEF, GPU context, compositor, or Electron stdout failures. Try the app-specific WebView repair preset and compare software WebView versus graphics presets.",
            hints: [.cefRenderingIssue, .gpuRenderingIssue, .electronStdout],
            recommendedActions: [
                "Apply the app-specific WebView repair profile and clear only that app's WebView cache.",
                "Compare software WebView, WineD3D Vulkan, and D3DMetal/GPTK presets with the same launcher."
            ],
            probeAssetIds: ["text-rendering", "vulkan", "d3d11"]
        ),
        LogIssueDefinition(
            id: "text-rendering",
            severity: "high",
            title: "Text rendering or font fallback issue",
            detail: "Logs contain DirectWrite, missing glyph, font fallback, or obsolete Chromium text-raster flags. Relaunch with the current compatibility profile after clearing WebView caches.",
            hints: [.fontRenderingIssue, .blankWindowIssue],
            recommendedActions: [
                "Relaunch with the current compatibility profile so obsolete DirectWrite and Chromium font flags are stripped.",
                "Run the text rendering probe and compare it with the affected app log."
            ],
            probeAssetIds: ["text-rendering"]
        ),
        LogIssueDefinition(
            id: "blank-window",
            severity: "high",
            title: "Blank, black, or empty app window",
            detail: "Logs contain blank-window, black-screen, empty-renderer, or missing-glyph signals. Compare App Mode against the managed desktop container, then test software WebView and current font repair presets.",
            hints: [.blankWindowIssue],
            recommendedActions: [
                "Compare App Mode against the managed desktop container to separate compositor issues from app rendering issues.",
                "Try the software WebView path before changing the whole bottle graphics preset."
            ],
            probeAssetIds: ["text-rendering", "window-input"]
        ),
        LogIssueDefinition(
            id: "window-input",
            severity: "high",
            title: "Window focus or click routing issue",
            detail: "Logs contain Win32 hit-test, foreground/focus, layered window, or click-message failures. Compare App Mode against the managed desktop container and rerun the window/input probe.",
            hints: [.windowInputIssue],
            recommendedActions: [
                "Rerun the window/input probe in App Mode and in the managed desktop container.",
                "Avoid forcing transparent layered windows until hit-testing is confirmed."
            ],
            probeAssetIds: ["window-input"]
        ),
        LogIssueDefinition(
            id: "graphics-runtime",
            severity: "high",
            title: "Vulkan or D3DMetal runtime issue",
            detail: "Logs contain Vulkan or D3DMetal errors. Verify the selected graphics preset, engine runtime paths, and probe results before tuning app-specific flags.",
            hints: [.vulkanIssue, .d3dMetalRuntime],
            recommendedActions: [
                "Verify the engine runtime paths and selected graphics preset before changing app arguments.",
                "Run Vulkan, D3D11, D3D12, D3D9, and shader-loop probes as a graphics baseline."
            ],
            probeAssetIds: ["vulkan", "d3d11", "d3d12-device", "d3d9-legacy", "game-shader"]
        ),
        LogIssueDefinition(
            id: "network-tls",
            severity: "medium",
            title: "Network, proxy, timeout, or TLS issue",
            detail: "Logs contain WinHTTP, certificate, Steam network probe, or timeout signals. Check proxy inheritance, DNS, certificates, and TLS probes.",
            hints: [.networkTLSIssue, .steamNetworkProbe, .timeout],
            recommendedActions: [
                "Verify proxy inheritance and certificate handling before treating the app as broken.",
                "Run both 64-bit and 32-bit WinHTTP TLS probes when the installer or launcher may spawn helper processes."
            ],
            probeAssetIds: ["tls-winhttp", "tls-winhttp-win32", "iphlpapi-adapters"]
        ),
        LogIssueDefinition(
            id: "win32-wow64",
            severity: "high",
            title: "32-bit or WoW64 compatibility issue",
            detail: "Logs contain 32-bit, bad executable format, kernel32, WoW64, or SEH dispatch signals. Verify the WoW64 baseline and managed rosettax87 runtime first; if both pass, treat the failure as an app-specific launcher or exception-handling gap.",
            hints: [.win32CompatibilityIssue],
            recommendedActions: [
                "Confirm the bottle uses a WoW64-capable engine and exposes an executable ROSETTA_X87_PATH, then rerun the 32-bit TLS and network adapter probes.",
                "If rosettax87 and the probes pass but the app exits with SEH stack-limit errors, keep graphics presets out of the loop and capture +seh,+loaddll diagnostics for the 32-bit launcher."
            ],
            probeAssetIds: ["tls-winhttp-win32", "iphlpapi-adapters-win32"]
        ),
        LogIssueDefinition(
            id: "portableapps-seh",
            severity: "high",
            title: "PortableApps 32-bit GUI SEH crash",
            detail: "PortableAppsPlatform.exe starts as a 32-bit GUI process and may fail inside Wine WoW64 exception dispatch, often around wow64cpu, c0000029 unwind, or a null-address page fault. The managed rosettax87 runtime now covers the same x87-sensitive 32-bit GUI boundary used by WinSCP and Pale Moon, so verify that runtime before treating this as an app-specific failure.",
            hints: [.portableAppsSEHIssue],
            recommendedActions: [
                "Confirm the active engine exposes an executable ROSETTA_X87_PATH before reproducing the platform main window.",
                "Keep the launcher in executable-dir mode and keep global graphics presets disabled for this recipe.",
                "Verify tls-winhttp-win32 and iphlpapi-adapters-win32; if they and rosettax87 pass, collect +seh,+loaddll logs for PortableAppsPlatform.exe instead of changing the bottle graphics preset.",
                "Use PortableAppsBackup.exe or PortableAppsUpdater.exe as control GUI helpers; if those stay alive while PortableAppsPlatform.exe exits 41, keep the issue scoped to the platform main window path.",
                "Reproduce once in a clean prefix before changing shared bottle services or registry state.",
                "Prefer testing individual portable applications directly when possible until the platform GUI SEH path is fixed."
            ],
            probeAssetIds: ["tls-winhttp-win32", "iphlpapi-adapters-win32", "window-input"]
        ),
        LogIssueDefinition(
            id: "jasp-qrc-qml",
            severity: "high",
            title: "JASP QML resource crash",
            detail: "JASP initialized QtWebEngine and reached EngineSync, then failed to load multiple JASP QML windows from qrc:/components/JASP or the file:/// components fallback before a Wine page fault. Qt DLLs, WebEngine paths, software OpenGL/RHI, QML disk-cache disabling, and the smoke qml-resource-probe have been exercised; current evidence points to JASP's Qt resource registration, resource readback, or QML context setup under Wine.",
            hints: [.jaspQrcQmlResourceIssue],
            recommendedActions: [
                "Keep the JASP Qt/WebEngine layout and software OpenGL/RHI repairs active; do not classify this as an incomplete install unless Qt DLLs are missing.",
                "Use the jasp-stats qml-resource-probe log to confirm fallback QML file hashes, Qt runtime payload, embedded qrc/import strings, and qmldir state before the launch crash.",
                "Stop tuning generic graphics flags for this signature; debug qRegisterResourceData, Qt resource lookup, file fallback context, QQml object creation, and qrc readback for JASPDesktop.exe."
            ],
            probeAssetIds: ["console", "window-input"]
        ),
        LogIssueDefinition(
            id: "jasp-qml-init-hang",
            severity: "high",
            title: "JASP initial dataset reset hang",
            detail: "JASP initialized QtWebEngine and reached the initial DataSetPackage::endLoadingData -> EngineSync::enginesReceiveNewData path, but the launch log never emitted the later JASP Desktop started marker, loadQML's first Initializing QML line, Loading Themes, QML loaded, or QML Initialized. Process liveness is not sufficient evidence of launch success; current evidence places the boundary in the initial DataSetPackage reset/endLoadingData and EngineSync reloadData handoff before any JASPEngine start marker.",
            hints: [.jaspQmlInitializationHangIssue],
            recommendedActions: [
                "Keep the JASP Qt/WebEngine layout, qml-resource-probe, and runtime-state-postlaunch-probe active so missing payloads and QML resource crashes are ruled out before classifying the hang.",
                "Capture live JASPDesktop/JASPEngine/QtWebEngineProcess state, host sample thread summaries, and the optional spawn-trace-probe before timeout cleanup; if there is no JASPEngine create evidence, do not debug this as a child loader failure.",
                "Compare MACWIN_JASP_CONSTRUCTOR_ISOLATION=1 and MACWIN_JASP_WEBENGINE_MODE=single-process runs before treating update checks, remote configuration, or WebEngine multiprocess mode as the root cause.",
                "Run the constructor-boundary-postlaunch-probe, then instrument DataSetPackage reset/endLoadingData, EngineSync reloadData receivers, Qt model warnings, and the MainWindow constructor tail after EngineSync::enginesReceiveNewData."
            ],
            probeAssetIds: ["console", "window-input"]
        ),
        LogIssueDefinition(
            id: "jasp-engine-ipc",
            severity: "high",
            title: "JASP EngineSync IPC fail-fast",
            detail: "JASP reached the initial DataSetPackage::endLoadingData -> EngineSync::enginesReceiveNewData path, created or referenced JASP-IPC Boost interprocess channels, then failed around managed_shared_memory, interprocess_mutex, NtLockFile, or heartbeat locking before any JASPEngine create marker. The standalone Win32 file-mapping probe and JASP-shaped Boost IPC probe both pass under the same Wine engine, so current evidence points to JASP's process-specific IPC initialization, stale cleanup, constructor timing, or channel lifecycle rather than missing payloads, Qt resource paths, generic graphics presets, or a broad Boost IPC primitive failure.",
            hints: [.jaspEngineIpcIssue],
            recommendedActions: [
                "Rerun jasp-stats with MACWIN_JASP_IPC_TRACE=1 so stale JASP-IPC-* files are removed and +file,+seh logging captures fresh channel creation, NtLockFile fixmes, and Boost interprocess exceptions.",
                "Run the ipc-file-mapping probe and jasp-boost-ipc probe to separate plain Win32 file mapping from JASP-shaped Boost managed_shared_memory, interprocess_mutex, shared string, heartbeat, and child-process open-only IPC.",
                "Keep the JASP Qt/WebEngine resource-path repair active, but stop changing graphics presets for this signature unless the IPC trace reaches later QML or JASPEngine milestones.",
                "If source instrumentation is available, add checkpoints around IPCChannel managed_shared_memory(open_or_create), find_or_construct<interprocess_mutex>, shared string creation, and heartbeat setup."
            ],
            probeAssetIds: ["jasp-boost-ipc", "ipc-file-mapping", "console", "window-input"]
        ),
        LogIssueDefinition(
            id: "dotnet-runtime",
            severity: "high",
            title: ".NET or Wine-Mono runtime failure",
            detail: "Logs show Wine-Mono native crashes, missing mscoree, hostfxr/hostpolicy, CoreCLR, or .NET runtime assembly failures. Confirm whether the app needs native .NET Framework, Wine-Mono, or a modern .NET Desktop Runtime before treating the application layer as broken.",
            hints: [.dotnetRuntimeIssue],
            recommendedActions: [
                "Rerun with Wine-Mono and .NET registry repairs enabled, then compare against the same app with a native .NET Framework or modern .NET Desktop Runtime when licensing allows.",
                "Prefer x64 or modern-runtime builds of the same app if the 32-bit .NET Framework build crashes inside Wine-Mono before managed exceptions are emitted."
            ],
            probeAssetIds: ["console", "window-input"]
        ),
        LogIssueDefinition(
            id: "msi-runtime",
            severity: "high",
            title: "MSI runtime missing or unusable",
            detail: "Logs show MSI installation routed through msiexec, but the Wine prefix or engine cannot start msiexec.exe. MSI-based installers need runtime repair before app-specific debugging is useful.",
            hints: [.msiRuntimeIssue],
            recommendedActions: [
                "Verify the engine ships msiexec.exe and MSI DLL support for both system32 and syswow64.",
                "Run a minimal MSI installer smoke after repairing the Wine runtime before retesting larger software."
            ],
            probeAssetIds: ["console", "tls-winhttp-win32"]
        ),
        LogIssueDefinition(
            id: "missing-builtin-dll",
            severity: "high",
            title: "Missing builtin DLL or runtime coverage",
            detail: "Logs show Wine could not load a required DLL with status c0000135. Build or package the missing builtin DLLs, then run wineboot -u for existing bottles before retesting the app.",
            hints: [.missingDLLIssue],
            recommendedActions: [
                "Extract the missing DLL names from the log and add both x86_64 and i386 targets to the engine coverage build.",
                "Run wineboot -u on existing bottles after rebuilding the engine so system32 and syswow64 are refreshed."
            ],
            probeAssetIds: ["console"]
        ),
        LogIssueDefinition(
            id: "chrome-omaha-installer",
            severity: "medium",
            title: "Chromium updater installer failure",
            detail: "A Chromium-derived installer reached its updater phase, but Google Update/Omaha, Microsoft EdgeUpdate, or BraveUpdate failed, rolled back, or timed out before the browser executable was installed.",
            hints: [.chromeOmahaInstallerIssue],
            recommendedActions: [
                "Retest with a full offline or unpacked portable Chromium-derived browser before treating MSI runtime as broken.",
                "Capture the installer log and compare Google Update/Omaha, Microsoft EdgeUpdate, or BraveUpdate behavior against a native Windows install."
            ],
            probeAssetIds: ["console", "tls-winhttp", "text-rendering"]
        ),
        LogIssueDefinition(
            id: "com-rpcss-marshalling",
            severity: "high",
            title: "COM / RpcSs marshalling failure",
            detail: "Logs show COM proxy/stub registration or RpcSs marshalling failed while an installer or updater tried to activate a local COM server. This points at Wine service/runtime coverage rather than an app-specific UI bug.",
            hints: [.comProxyMarshallingIssue],
            recommendedActions: [
                "Check that services.exe, rpcss.exe, svchost.exe, ole32/combase proxy registration, and RpcSs startup are present in the managed engine.",
                "Rerun the affected installer with +ole,+rpc,+service logging before changing WebView or graphics presets."
            ],
            probeAssetIds: ["console", "tls-winhttp", "tls-winhttp-win32"]
        ),
        LogIssueDefinition(
            id: "mremoteng-early-exit",
            severity: "medium",
            title: "mRemoteNG exits before GUI stays alive",
            detail: "mRemoteNG 1.78.2 loads through the managed .NET Desktop runtime, but the process exits with code 0 before the smoke timeout instead of keeping a WinForms window alive. Treat this as a startup/window lifecycle compatibility issue, not as missing .NET.",
            hints: [.mRemoteNGEarlyExitIssue],
            recommendedActions: [
                "Compare the default high-performance bottle registry and environment with the validated mRemoteNG smoke prefix.",
                "Capture WinForms startup, update-check, and main-window lifecycle traces before changing the .NET runtime again."
            ],
            probeAssetIds: ["console", "window-input"]
        ),
        LogIssueDefinition(
            id: "installer",
            severity: "medium",
            title: "Installer validation issue",
            detail: "Logs contain installer, MSI, NSIS, hash mismatch, or catalog mismatch failures. Recheck installer source, SHA-256, silent args, and architecture.",
            hints: [.installerIssue],
            recommendedActions: [
                "Revalidate the cached installer SHA-256 against the recipe before running it again.",
                "Check whether the installer needs 32-bit support, MSI service repair, or a local interactive run."
            ],
            probeAssetIds: ["console", "tls-winhttp-win32"]
        )
    ]

    private static func definitions(for issueIds: [String]) -> [LogIssueDefinition] {
        issueIds.compactMap { id in
            logIssueDefinitions.first { $0.id == id }
        }
    }

    private static func recommendedActions(for issueIds: [String]) -> [String] {
        let actions = definitions(for: issueIds).flatMap(\.recommendedActions)
        if !actions.isEmpty { return orderedUnique(actions) }
        guard issueIds.contains("unclassified-failure") else { return [] }
        return [
            "Open the raw log and identify the first recurring error signature.",
            "If the error repeats across apps, add a LogService hint and connect it to a probe."
        ]
    }

    private static func probeAssetIds(for issueIds: [String]) -> [String] {
        let probes = definitions(for: issueIds).flatMap(\.probeAssetIds)
        if !probes.isEmpty { return orderedUnique(probes) }
        return issueIds.contains("unclassified-failure") ? ["console"] : []
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

    private static func markdownEscaped(_ text: String) -> String {
        text.replacingOccurrences(of: "\n", with: " ")
    }

    private static func maintenanceRecommendations(
        totalLogCount: Int,
        totalLogBytes: Int64,
        staleLogCount: Int,
        largeLogCount: Int,
        cleanupCandidateBytes: Int64
    ) -> [String] {
        var recommendations: [String] = []
        if largeLogCount > 0 {
            recommendations.append("Review large logs before exporting support bundles; they can hide the useful tail behind noisy Wine output.")
        }
        if staleLogCount > 0 {
            recommendations.append("Archive or remove stale logs after exporting a support bundle for the current issue.")
        }
        if cleanupCandidateBytes > 64 * 1024 * 1024 {
            recommendations.append("Cleanup candidates exceed 64 MiB; trim old logs before running long game sessions.")
        }
        if totalLogCount > 100 || totalLogBytes > 256 * 1024 * 1024 {
            recommendations.append("The Logs directory is large enough to slow diagnosis; keep recent issue logs and archive older runs.")
        }
        if recommendations.isEmpty {
            recommendations.append("No log maintenance action is needed.")
        }
        return recommendations
    }

    private static func scriptTimestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter.string(from: date)
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "Z", with: "Z")
    }

    private static func uniqueArchiveDestination(
        for fileName: String,
        in directory: URL,
        fileManager: FileManager
    ) -> URL {
        let baseURL = directory.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: baseURL.path) else {
            return baseURL
        }

        let stem = baseURL.deletingPathExtension().lastPathComponent
        let ext = baseURL.pathExtension
        for index in 1...999 {
            let candidateName = ext.isEmpty ? "\(stem)-\(index)" : "\(stem)-\(index).\(ext)"
            let candidate = directory.appendingPathComponent(candidateName)
            if !fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        return directory.appendingPathComponent("\(UUID().uuidString)-\(fileName)")
    }

    private static func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
