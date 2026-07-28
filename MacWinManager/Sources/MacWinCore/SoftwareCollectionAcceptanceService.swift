import Foundation

public enum SoftwareCollectionAcceptanceState: String, Codable, Equatable, Sendable {
    case verified
    case readyToRun
    case needsAction
    case blocked
}

public enum SoftwareCollectionAcceptanceSeverity: String, Codable, Equatable, Sendable {
    case blocker
    case high
    case warning
    case info
}

public enum SoftwareCollectionAcceptanceActionKind: String, Codable, Equatable, Sendable {
    case addMissingRecipe
    case downloadInstaller
    case redownloadHashMismatch
    case runSoftwareAction
    case runProbe
    case reviewLogIssue
}

public struct SoftwareCollectionAcceptanceAction: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var severity: SoftwareCollectionAcceptanceSeverity
    public var kind: SoftwareCollectionAcceptanceActionKind
    public var title: String
    public var detail: String
    public var recipeId: String?
    public var assetId: String?
    public var logIssueId: String?
    public var command: [String]
    public var relatedPath: String?
    public var sourceURL: String?
    public var fileName: String?
    public var expectedSha256: String?

    public init(
        id: String,
        severity: SoftwareCollectionAcceptanceSeverity,
        kind: SoftwareCollectionAcceptanceActionKind,
        title: String,
        detail: String,
        recipeId: String? = nil,
        assetId: String? = nil,
        logIssueId: String? = nil,
        command: [String] = [],
        relatedPath: String? = nil,
        sourceURL: String? = nil,
        fileName: String? = nil,
        expectedSha256: String? = nil
    ) {
        self.id = id
        self.severity = severity
        self.kind = kind
        self.title = title
        self.detail = detail
        self.recipeId = recipeId
        self.assetId = assetId
        self.logIssueId = logIssueId
        self.command = command
        self.relatedPath = relatedPath
        self.sourceURL = sourceURL
        self.fileName = fileName
        self.expectedSha256 = expectedSha256
    }
}

public struct SoftwareCollectionAcceptanceReport: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var rootPath: String
    public var state: SoftwareCollectionAcceptanceState
    public var collectionCount: Int
    public var recipeCount: Int
    public var verifiedRecipeCount: Int
    public var missingRecipeCount: Int
    public var missingInstallerCount: Int
    public var hashMismatchCount: Int
    public var smokeBlockedCount: Int
    public var smokeFailedCount: Int
    public var probeActionCount: Int
    public var failedLogCount: Int
    public var attentionLogCount: Int
    public var actionCount: Int
    public var blockerCount: Int
    public var highPriorityCount: Int
    public var warningCount: Int
    public var infoCount: Int
    public var actions: [SoftwareCollectionAcceptanceAction]

    public init(
        generatedAt: Date,
        rootPath: String,
        collection: SoftwareCollectionReport,
        smokeMatrix: SoftwareSmokeMatrixReport?,
        testExecutionPlan: TestExecutionPlan?,
        logIssues: LogIssueReport,
        actions: [SoftwareCollectionAcceptanceAction]
    ) {
        self.generatedAt = generatedAt
        self.rootPath = rootPath
        self.collectionCount = collection.collectionCount
        self.recipeCount = collection.recipeCount
        self.verifiedRecipeCount = collection.verifiedRecipeCount
        self.missingRecipeCount = collection.missingRecipeCount
        self.missingInstallerCount = collection.missingInstallerCount
        self.hashMismatchCount = collection.entries.filter { $0.installerHashStatus == .mismatch }.count
        self.smokeBlockedCount = smokeMatrix?.blockedCount ?? 0
        self.smokeFailedCount = smokeMatrix?.failedCount ?? 0
        self.probeActionCount = testExecutionPlan?.items.count ?? 0
        self.failedLogCount = logIssues.failedLogCount
        self.attentionLogCount = logIssues.attentionLogCount
        self.actionCount = actions.count
        self.blockerCount = actions.filter { $0.severity == .blocker }.count
        self.highPriorityCount = actions.filter { $0.severity == .high }.count
        self.warningCount = actions.filter { $0.severity == .warning }.count
        self.infoCount = actions.filter { $0.severity == .info }.count
        self.actions = actions

        if blockerCount > 0 || missingRecipeCount > 0 || hashMismatchCount > 0 || smokeFailedCount > 0 {
            self.state = .blocked
        } else if highPriorityCount > 0 || warningCount > 0 || missingInstallerCount > 0 || failedLogCount > 0 || attentionLogCount > 0 {
            self.state = .needsAction
        } else if verifiedRecipeCount == recipeCount && recipeCount > 0 && probeActionCount == 0 {
            self.state = .verified
        } else {
            self.state = .readyToRun
        }
    }

    public static func csv(report: SoftwareCollectionAcceptanceReport) -> String {
        var rows: [[String]] = [[
            "severity",
            "kind",
            "title",
            "detail",
            "recipe_id",
            "asset_id",
            "log_issue_id",
            "command",
            "related_path",
            "source_url",
            "file_name",
            "expected_sha256"
        ]]

        for action in report.actions {
            rows.append([
                action.severity.rawValue,
                action.kind.rawValue,
                action.title,
                action.detail,
                action.recipeId ?? "",
                action.assetId ?? "",
                action.logIssueId ?? "",
                action.command.joined(separator: " "),
                action.relatedPath ?? "",
                action.sourceURL ?? "",
                action.fileName ?? "",
                action.expectedSha256 ?? ""
            ])
        }

        return rows.map { $0.map(csvEscaped).joined(separator: ",") }.joined(separator: "\n") + "\n"
    }

    public static func markdown(report: SoftwareCollectionAcceptanceReport) -> String {
        let formatter = ISO8601DateFormatter()
        var lines = [
            "# MacWin Collection Acceptance",
            "",
            "- Generated: \(formatter.string(from: report.generatedAt))",
            "- State: `\(report.state.rawValue)`",
            "- Collections: \(report.collectionCount)",
            "- Recipes: \(report.recipeCount)",
            "- Verified recipes: \(report.verifiedRecipeCount)",
            "- Missing recipes: \(report.missingRecipeCount)",
            "- Missing installers: \(report.missingInstallerCount)",
            "- Hash mismatches: \(report.hashMismatchCount)",
            "- Smoke blocked: \(report.smokeBlockedCount)",
            "- Smoke failed: \(report.smokeFailedCount)",
            "- Probe actions: \(report.probeActionCount)",
            "- Failed logs: \(report.failedLogCount)",
            "- Attention logs: \(report.attentionLogCount)",
            "- Actions: \(report.actionCount)",
            "",
            "## Actions",
            ""
        ]

        if report.actions.isEmpty {
            lines.append("No acceptance actions are required.")
        } else {
            for action in report.actions {
                lines.append("### \(markdownEscaped(action.title))")
                lines.append("")
                lines.append("- Severity: `\(action.severity.rawValue)`")
                lines.append("- Kind: `\(action.kind.rawValue)`")
                if let recipeId = action.recipeId {
                    lines.append("- Recipe: `\(recipeId)`")
                }
                if let assetId = action.assetId {
                    lines.append("- Asset: `\(assetId)`")
                }
                if let logIssueId = action.logIssueId {
                    lines.append("- Log issue: `\(logIssueId)`")
                }
                if !action.command.isEmpty {
                    lines.append("- Command: `\(action.command.joined(separator: " "))`")
                }
                if let relatedPath = action.relatedPath {
                    lines.append("- Path: `\(relatedPath)`")
                }
                if let sourceURL = action.sourceURL {
                    lines.append("- Source: `\(sourceURL)`")
                }
                if let expectedSha256 = action.expectedSha256 {
                    lines.append("- SHA-256: `\(expectedSha256)`")
                }
                lines.append("- Detail: \(markdownEscaped(action.detail))")
                lines.append("")
            }
        }

        return lines.joined(separator: "\n")
    }

    public static func runbookScript(report: SoftwareCollectionAcceptanceReport) -> String {
        let formatter = ISO8601DateFormatter()
        var lines: [String] = [
            "#!/usr/bin/env bash",
            "set -euo pipefail",
            "",
            "# Generated by MacWin Manager at \(formatter.string(from: report.generatedAt))",
            "# State: \(report.state.rawValue), actions: \(report.actionCount), blockers: \(report.blockerCount)",
            "",
            "ROOT_DIR=\(shellQuoted(report.rootPath))",
            "DOWNLOADS_DIR=\"$ROOT_DIR/Downloads\"",
            "",
            "download_one() {",
            "  local recipe_id=\"$1\"",
            "  local source_url=\"$2\"",
            "  local file_name=\"$3\"",
            "  local expected_sha256=\"${4:-}\"",
            "  local destination=\"$DOWNLOADS_DIR/$file_name\"",
            "  mkdir -p \"$DOWNLOADS_DIR\"",
            "  if [[ -z \"$source_url\" || -z \"$file_name\" ]]; then",
            "    echo \"SKIP $recipe_id: missing download URL or filename\" >&2",
            "    return 1",
            "  fi",
            "  if [[ ! -f \"$destination\" ]]; then",
            "    echo \"DOWNLOAD $recipe_id -> $destination\"",
            "    curl -L --fail --retry 3 --output \"$destination\" \"$source_url\"",
            "  else",
            "    echo \"READY $recipe_id: $destination\"",
            "  fi",
            "  if [[ -n \"$expected_sha256\" ]]; then",
            "    printf '%s  %s\\n' \"$expected_sha256\" \"$destination\" | shasum -a 256 -c -",
            "  else",
            "    echo \"WARN $recipe_id: no expected SHA-256\" >&2",
            "  fi",
            "}",
            "",
            "run_probe() {",
            "  echo \"RUN $*\"",
            "  \"$@\"",
            "}",
            "",
            "note() {",
            "  printf '\\n# %s\\n' \"$1\"",
            "  printf '%s\\n' \"$2\"",
            "}",
            ""
        ]

        if report.actions.isEmpty {
            lines.append("echo 'No collection acceptance actions are required.'")
        } else {
            for action in report.actions {
                lines.append("")
                lines.append("echo \(shellQuoted("== \(action.severity.rawValue.uppercased()) \(action.kind.rawValue): \(action.title) =="))")
                switch action.kind {
                case .downloadInstaller, .redownloadHashMismatch:
                    lines.append("download_one \(shellQuoted(action.recipeId ?? action.id)) \(shellQuoted(action.sourceURL ?? "")) \(shellQuoted(action.fileName ?? "")) \(shellQuoted(action.expectedSha256 ?? ""))")
                case .runProbe:
                    if action.command.isEmpty {
                        lines.append("note \(shellQuoted(action.title)) \(shellQuoted("No runnable command was available for \(action.assetId ?? action.id)."))")
                    } else {
                        lines.append("run_probe \(action.command.map(shellQuoted).joined(separator: " "))")
                    }
                case .addMissingRecipe, .runSoftwareAction, .reviewLogIssue:
                    var detail = action.detail
                    if let relatedPath = action.relatedPath {
                        detail += " Path: \(relatedPath)"
                    }
                    lines.append("note \(shellQuoted(action.title)) \(shellQuoted(detail))")
                }
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
        value.replacingOccurrences(of: "\n", with: " ")
    }

    private static func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}

public struct SoftwareCollectionAcceptanceService {
    public init() {}

    public func report(
        collection: SoftwareCollectionReport,
        smokeMatrix: SoftwareSmokeMatrixReport?,
        testExecutionPlan: TestExecutionPlan?,
        logIssues: LogIssueReport,
        generatedAt: Date = Date()
    ) -> SoftwareCollectionAcceptanceReport {
        var actions: [SoftwareCollectionAcceptanceAction] = []

        for recipeId in collection.missingRecipeIds.sorted() {
            actions.append(SoftwareCollectionAcceptanceAction(
                id: "missing-recipe:\(recipeId)",
                severity: .blocker,
                kind: .addMissingRecipe,
                title: "Add missing recipe \(recipeId)",
                detail: "The collection references a recipe that is not present in the signed catalog.",
                recipeId: recipeId
            ))
        }

        for entry in collection.entries.sorted(by: { $0.recipeId < $1.recipeId }) {
            if entry.installerHashStatus == .mismatch {
                actions.append(SoftwareCollectionAcceptanceAction(
                    id: "hash-mismatch:\(entry.recipeId)",
                    severity: .blocker,
                    kind: .redownloadHashMismatch,
                    title: "Redownload \(entry.name)",
                    detail: "Cached installer hash does not match the trusted recipe hash.",
                    recipeId: entry.recipeId,
                    relatedPath: entry.cachedInstallerPath,
                    sourceURL: entry.installerSourceURL,
                    fileName: entry.installerFileName,
                    expectedSha256: entry.expectedSha256
                ))
                continue
            }
            if entry.installerMode == .download && !entry.cachedInstallerExists {
                actions.append(SoftwareCollectionAcceptanceAction(
                    id: "missing-installer:\(entry.recipeId)",
                    severity: .high,
                    kind: .downloadInstaller,
                    title: "Cache installer for \(entry.name)",
                    detail: "Download and verify \(entry.installerFileName ?? entry.name) before running this recipe.",
                    recipeId: entry.recipeId,
                    relatedPath: entry.cachedInstallerPath,
                    sourceURL: entry.installerSourceURL,
                    fileName: entry.installerFileName,
                    expectedSha256: entry.expectedSha256
                ))
            }
        }

        for row in (smokeMatrix?.rows ?? []).sorted(by: { $0.recipeId < $1.recipeId }) {
            guard row.stage != .verified && row.stage != .disabled else { continue }
            let severity: SoftwareCollectionAcceptanceSeverity
            switch row.highestSeverity {
            case .failed:
                severity = .blocker
            case .blocked:
                severity = .high
            case .warning:
                severity = .warning
            case .pending:
                severity = .info
            case .passed, .notApplicable:
                continue
            }
            actions.append(SoftwareCollectionAcceptanceAction(
                id: "software-action:\(row.recipeId):\(row.stage.rawValue)",
                severity: severity,
                kind: .runSoftwareAction,
                title: row.nextAction,
                detail: row.checklist
                    .filter { $0.state == row.highestSeverity || $0.state == .failed || $0.state == .blocked }
                    .map { "\($0.label): \($0.detail)" }
                    .joined(separator: " | "),
                recipeId: row.recipeId,
                relatedPath: row.latestLogPath
            ))
        }

        for item in (testExecutionPlan?.items ?? []).sorted(by: Self.sortTestItems) {
            let severity: SoftwareCollectionAcceptanceSeverity = item.priority == .required ? .blocker : (item.priority == .high ? .high : .warning)
            actions.append(SoftwareCollectionAcceptanceAction(
                id: "probe:\(item.assetId)",
                severity: severity,
                kind: .runProbe,
                title: "Run probe \(item.name)",
                detail: "Probe requires attention: \(item.reasons.map(\.rawValue).joined(separator: ", ")).",
                assetId: item.assetId,
                command: item.command,
                relatedPath: item.latestLogPath ?? item.executablePath
            ))
        }

        for issue in logIssues.topIssues.sorted(by: Self.sortLogIssues).prefix(8) {
            let severity: SoftwareCollectionAcceptanceSeverity = issue.severity == "critical" || issue.severity == "high" ? .high : .warning
            actions.append(SoftwareCollectionAcceptanceAction(
                id: "log-issue:\(issue.id)",
                severity: severity,
                kind: .reviewLogIssue,
                title: "Review log issue \(issue.title)",
                detail: issue.detail,
                logIssueId: issue.id
            ))
        }

        actions = Self.deduplicated(actions).sorted(by: Self.sortActions)
        return SoftwareCollectionAcceptanceReport(
            generatedAt: generatedAt,
            rootPath: collection.rootPath,
            collection: collection,
            smokeMatrix: smokeMatrix,
            testExecutionPlan: testExecutionPlan,
            logIssues: logIssues,
            actions: actions
        )
    }

    private static func deduplicated(_ actions: [SoftwareCollectionAcceptanceAction]) -> [SoftwareCollectionAcceptanceAction] {
        var seen = Set<String>()
        var result: [SoftwareCollectionAcceptanceAction] = []
        for action in actions where seen.insert(action.id).inserted {
            result.append(action)
        }
        return result
    }

    private static func sortActions(_ lhs: SoftwareCollectionAcceptanceAction, _ rhs: SoftwareCollectionAcceptanceAction) -> Bool {
        let lhsRank = severityRank(lhs.severity)
        let rhsRank = severityRank(rhs.severity)
        if lhsRank != rhsRank {
            return lhsRank < rhsRank
        }
        if lhs.kind.rawValue != rhs.kind.rawValue {
            return lhs.kind.rawValue < rhs.kind.rawValue
        }
        return lhs.id < rhs.id
    }

    private static func sortTestItems(_ lhs: TestExecutionPlanItem, _ rhs: TestExecutionPlanItem) -> Bool {
        let lhsRank = priorityRank(lhs.priority)
        let rhsRank = priorityRank(rhs.priority)
        if lhsRank != rhsRank {
            return lhsRank < rhsRank
        }
        return lhs.assetId < rhs.assetId
    }

    private static func sortLogIssues(_ lhs: LogIssueTrend, _ rhs: LogIssueTrend) -> Bool {
        let lhsRank = logSeverityRank(lhs.severity)
        let rhsRank = logSeverityRank(rhs.severity)
        if lhsRank != rhsRank {
            return lhsRank < rhsRank
        }
        if lhs.count != rhs.count {
            return lhs.count > rhs.count
        }
        return lhs.id < rhs.id
    }

    private static func severityRank(_ severity: SoftwareCollectionAcceptanceSeverity) -> Int {
        switch severity {
        case .blocker: 0
        case .high: 1
        case .warning: 2
        case .info: 3
        }
    }

    private static func priorityRank(_ priority: TestExecutionPriority) -> Int {
        switch priority {
        case .required: 0
        case .high: 1
        case .normal: 2
        case .optional: 3
        }
    }

    private static func logSeverityRank(_ severity: String) -> Int {
        switch severity {
        case "critical": 0
        case "high": 1
        case "medium": 2
        case "low": 3
        default: 4
        }
    }
}
