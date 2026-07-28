import Foundation

public enum SupportTriageStatus: String, Codable, Equatable, Sendable {
    case ready
    case attention
    case blocked
}

public enum SupportTriageSeverity: String, Codable, Equatable, Sendable {
    case blocker
    case high
    case warning
    case info
}

public enum SupportTriageSource: String, Codable, Equatable, Sendable {
    case diagnostics
    case logs
    case launchHealth
    case runtimeProcesses
    case runtimeApplications
    case externalExecutableQueue
    case softwareCollection
    case softwareAcquisition
    case testCoverage
}

public struct SupportTriageItem: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var severity: SupportTriageSeverity
    public var source: SupportTriageSource
    public var title: String
    public var detail: String
    public var recommendedAction: String
    public var relatedIds: [String]
    public var relatedPaths: [String]

    public init(
        id: String,
        severity: SupportTriageSeverity,
        source: SupportTriageSource,
        title: String,
        detail: String,
        recommendedAction: String,
        relatedIds: [String] = [],
        relatedPaths: [String] = []
    ) {
        self.id = id
        self.severity = severity
        self.source = source
        self.title = title
        self.detail = detail
        self.recommendedAction = recommendedAction
        self.relatedIds = relatedIds
        self.relatedPaths = relatedPaths
    }
}

public struct SupportTriageReport: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var rootPath: String
    public var status: SupportTriageStatus
    public var itemCount: Int
    public var blockerCount: Int
    public var highCount: Int
    public var warningCount: Int
    public var infoCount: Int
    public var sourceCounts: [String: Int]
    public var items: [SupportTriageItem]

    public init(generatedAt: Date, rootPath: String, items: [SupportTriageItem]) {
        self.generatedAt = generatedAt
        self.rootPath = rootPath
        self.itemCount = items.count
        self.blockerCount = items.filter { $0.severity == .blocker }.count
        self.highCount = items.filter { $0.severity == .high }.count
        self.warningCount = items.filter { $0.severity == .warning }.count
        self.infoCount = items.filter { $0.severity == .info }.count
        self.sourceCounts = Dictionary(grouping: items, by: { $0.source.rawValue }).mapValues(\.count)
        self.status = blockerCount > 0 ? .blocked : ((highCount + warningCount) > 0 ? .attention : .ready)
        self.items = items
    }

    public static func csv(report: SupportTriageReport) -> String {
        var rows: [[String]] = [[
            "id",
            "severity",
            "source",
            "title",
            "detail",
            "recommended_action",
            "related_ids",
            "related_paths"
        ]]
        for item in report.items {
            rows.append([
                item.id,
                item.severity.rawValue,
                item.source.rawValue,
                item.title,
                item.detail,
                item.recommendedAction,
                item.relatedIds.joined(separator: ";"),
                item.relatedPaths.joined(separator: ";")
            ])
        }
        return rows.map { $0.map(csvEscaped).joined(separator: ",") }.joined(separator: "\n") + "\n"
    }

    public static func markdown(report: SupportTriageReport) -> String {
        let formatter = ISO8601DateFormatter()
        var lines = [
            "# MacWin Support Triage",
            "",
            "- Generated: \(formatter.string(from: report.generatedAt))",
            "- Root: `\(markdownEscaped(report.rootPath))`",
            "- Status: `\(report.status.rawValue)`",
            "- Items: \(report.itemCount)",
            "- Blockers: \(report.blockerCount)",
            "- High: \(report.highCount)",
            "- Warnings: \(report.warningCount)",
            "- Info: \(report.infoCount)",
            "",
            "## Priority Items",
            ""
        ]
        if report.items.isEmpty {
            lines.append("No triage items were found.")
        } else {
            for item in report.items {
                lines.append("### [\(item.severity.rawValue)] \(markdownEscaped(item.title))")
                lines.append("")
                lines.append("- Id: `\(markdownEscaped(item.id))`")
                lines.append("- Source: `\(item.source.rawValue)`")
                lines.append("- Detail: \(markdownEscaped(item.detail))")
                lines.append("- Action: \(markdownEscaped(item.recommendedAction))")
                if !item.relatedIds.isEmpty {
                    lines.append("- Related IDs: \(item.relatedIds.map { "`\(markdownEscaped($0))`" }.joined(separator: ", "))")
                }
                if !item.relatedPaths.isEmpty {
                    lines.append("- Related paths: \(item.relatedPaths.map { "`\(markdownEscaped($0))`" }.joined(separator: ", "))")
                }
                lines.append("")
            }
        }
        return lines.joined(separator: "\n")
    }

    private static func csvEscaped(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    private static func markdownEscaped(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "`", with: "\\`")
    }
}

public struct SupportTriageService {
    public init() {}

    public func report(
        generatedAt: Date,
        capability: CapabilityReport,
        logRemediation: LogRemediationPlan,
        softwareAcceptance: SoftwareCollectionAcceptanceReport,
        softwareAcquisition: SoftwareAcquisitionReport,
        launchHealth: LaunchHealthReport,
        externalOpenQueue: ExternalExecutableOpenQueueReport
    ) -> SupportTriageReport {
        Self.report(
            generatedAt: generatedAt,
            capability: capability,
            logRemediation: logRemediation,
            softwareAcceptance: softwareAcceptance,
            softwareAcquisition: softwareAcquisition,
            launchHealth: launchHealth,
            externalOpenQueue: externalOpenQueue
        )
    }

    public static func report(
        generatedAt: Date,
        capability: CapabilityReport,
        logRemediation: LogRemediationPlan,
        softwareAcceptance: SoftwareCollectionAcceptanceReport,
        softwareAcquisition: SoftwareAcquisitionReport,
        launchHealth: LaunchHealthReport,
        externalOpenQueue: ExternalExecutableOpenQueueReport
    ) -> SupportTriageReport {
        var items: [SupportTriageItem] = []

        if capability.diagnostics?.timedOut == true {
            appendUnique(&items, item: SupportTriageItem(
                id: "diagnostics-timeout",
                severity: .high,
                source: .diagnostics,
                title: "Diagnostics timed out",
                detail: "The latest probe suite did not complete within its timeout.",
                recommendedAction: "Open diagnostics.csv and rerun the failing or timed-out probes individually.",
                relatedPaths: [capability.diagnostics?.logPath].compactMap { $0 }
            ))
        }
        if let diagnostics = capability.diagnostics, diagnostics.exitCode != 0 {
            appendUnique(&items, item: SupportTriageItem(
                id: "diagnostics-failed",
                severity: .high,
                source: .diagnostics,
                title: "Diagnostics failed",
                detail: "The latest probe suite exited with code \(diagnostics.exitCode).",
                recommendedAction: "Review diagnostics.csv and the diagnostics log before running software samples.",
                relatedPaths: [diagnostics.logPath]
            ))
        }

        for finding in capability.runtimeProcesses?.findings ?? [] {
            appendUnique(&items, item: SupportTriageItem(
                id: "runtime-process-\(finding.id)",
                severity: severity(from: finding.severity),
                source: .runtimeProcesses,
                title: finding.title,
                detail: finding.detail,
                recommendedAction: "Use runtime-processes.json/csv to identify and stop stale Wine processes.",
                relatedIds: finding.affectedProcessIdentifiers.map(String.init)
            ))
        }

        for finding in capability.runtimeApplications?.findings ?? [] {
            appendUnique(&items, item: SupportTriageItem(
                id: "runtime-application-\(finding.id)",
                severity: severity(from: finding.severity),
                source: .runtimeApplications,
                title: finding.title,
                detail: finding.detail,
                recommendedAction: "Use runtime-applications.json/csv/log to compare macOS Dock state with actual processes.",
                relatedIds: finding.affectedProcessIdentifiers.map(String.init)
            ))
        }

        let smokeReports = capability.softwareSmokeRuns?.reports ?? []
        for item in logRemediation.items.prefix(12) where !isSupersededLogRemediation(
            item,
            logs: capability.logs.entries,
            smokeReports: smokeReports
        ) {
            appendUnique(&items, item: SupportTriageItem(
                id: "log-remediation-\(item.id)",
                severity: severity(from: item.severity),
                source: .logs,
                title: item.title,
                detail: item.action,
                recommendedAction: item.probeAssetIds.isEmpty ? "Review the affected log evidence." : "Run the recommended probe assets, then relaunch the app.",
                relatedIds: [item.issueId] + item.probeAssetIds,
                relatedPaths: item.affectedLogNames + item.samplePaths
            ))
        }

        let verifiedSmokeLogPaths = Set(capability.softwareSmokeMatrix.rows.compactMap { row -> [String]? in
            guard row.stage == .verified, row.highestSeverity == .passed else { return nil }
            return [row.latestLogPath, row.latestLaunchLogPath].compactMap { $0.map(canonicalPath) }
        }.flatMap { $0 })
        let verifiedRecipeIds = Set(capability.softwareSmokeMatrix.rows.compactMap { row -> String? in
            guard row.stage == .verified, row.highestSeverity == .passed else { return nil }
            return row.recipeId
        })
        let verifiedInstallerRecipeIds = Set(capability.softwareSmokeMatrix.rows.compactMap { row -> String? in
            guard row.checklist.contains(where: { $0.id == "install" && $0.state == .passed }) else {
                return nil
            }
            return row.recipeId
        })
        let passedDiagnosticLogPaths = Set(capability.logs.entries.compactMap { entry -> String? in
            guard isPassedDiagnosticLog(entry) else { return nil }
            return canonicalPath(entry.path)
        })

        for entry in launchHealth.entries where entry.status == .failed || entry.status == .attention {
            if isDiagnosticLaunchHealthLogEntry(entry) {
                continue
            }
            let entryLogPaths = Set(entry.logPaths.map(canonicalPath))
            if !verifiedSmokeLogPaths.isDisjoint(with: entryLogPaths) {
                continue
            }
            if !entryLogPaths.isEmpty && entryLogPaths.isSubset(of: passedDiagnosticLogPaths) {
                continue
            }
            if isVerifiedInstallerHistory(entry, verifiedRecipeIds: verifiedInstallerRecipeIds) {
                continue
            }
            if isVerifiedManualSmokeHistory(entry, verifiedRecipeIds: verifiedRecipeIds) {
                continue
            }
            appendUnique(&items, item: SupportTriageItem(
                id: "launch-health-\(entry.id)",
                severity: entry.status == .failed ? .high : .warning,
                source: .launchHealth,
                title: "Launch health needs attention: \(entry.displayName)",
                detail: "status=\(entry.status.rawValue), failedLogs=\(entry.failedLogCount), attentionLogs=\(entry.attentionLogCount), nonZeroExit=\(entry.nonZeroExitCount)",
                recommendedAction: "Open launch-health.md and inspect the matched launch record/log.",
                relatedIds: entry.probableIssueIds + entry.recommendedProbeIds,
                relatedPaths: entry.logPaths
            ))
        }

        for action in softwareAcceptance.actions.prefix(16) {
            appendUnique(&items, item: SupportTriageItem(
                id: "software-acceptance-\(action.id)",
                severity: severity(from: action.severity),
                source: .softwareCollection,
                title: action.title,
                detail: action.detail,
                recommendedAction: action.command.isEmpty ? "Review software-collection-acceptance.md for the required action." : "Run the generated command from software-collection-acceptance-runbook.sh.",
                relatedIds: [action.recipeId, action.assetId, action.logIssueId].compactMap { $0 },
                relatedPaths: [action.relatedPath].compactMap { $0 }
            ))
        }

        for entry in softwareAcquisition.entries where entry.state != .cached && entry.state != .ready {
            appendUnique(&items, item: SupportTriageItem(
                id: "software-acquisition-\(entry.id)",
                severity: acquisitionSeverity(entry.state),
                source: .softwareAcquisition,
                title: "Software acquisition required: \(entry.name)",
                detail: entry.action,
                recommendedAction: "Use software-acquisition.sh/md to download or place the required installer.",
                relatedIds: [entry.recipeId, entry.sampleId].compactMap { $0 } + entry.recommendedProbeIds,
                relatedPaths: entry.cachedPaths
            ))
        }

        if externalOpenQueue.pendingCount > 0 {
            appendUnique(&items, item: SupportTriageItem(
                id: "external-exe-open-queue-pending",
                severity: externalOpenQueue.duplicatePendingCount > 0 ? .warning : .info,
                source: .externalExecutableQueue,
                title: "External EXE open queue has pending files",
                detail: "pending=\(externalOpenQueue.pendingCount), unique=\(externalOpenQueue.uniquePendingCount), duplicates=\(externalOpenQueue.duplicatePendingCount)",
                recommendedAction: "Open external-open-queue.json/log and decide whether to drain or retry the queued installers.",
                relatedPaths: externalOpenQueue.items.map(\.path)
            ))
        }

        if capability.testCoverage.missingRequiredExecutableCount > 0 {
            appendUnique(&items, item: SupportTriageItem(
                id: "test-coverage-missing-required-assets",
                severity: .warning,
                source: .testCoverage,
                title: "Required probe assets are missing",
                detail: "\(capability.testCoverage.missingRequiredExecutableCount) required executable probe assets are unavailable.",
                recommendedAction: "Run test-runbook.sh or rebuild exe-tests before treating software compatibility as proven.",
                relatedIds: capability.testCoverage.categories.flatMap(\.missingRequiredAssetIds)
            ))
        }

        let sorted = items.sorted { lhs, rhs in
            let lhsRank = severityRank(lhs.severity)
            let rhsRank = severityRank(rhs.severity)
            if lhsRank != rhsRank { return lhsRank < rhsRank }
            if lhs.source.rawValue != rhs.source.rawValue { return lhs.source.rawValue < rhs.source.rawValue }
            return lhs.id < rhs.id
        }
        return SupportTriageReport(generatedAt: generatedAt, rootPath: capability.rootPath, items: sorted)
    }

    private static func appendUnique(_ items: inout [SupportTriageItem], item: SupportTriageItem) {
        guard !items.contains(where: { $0.id == item.id }) else { return }
        items.append(item)
    }

    private static func isPassedDiagnosticLog(_ entry: CapabilityLogEntry) -> Bool {
        let normalizedName = entry.name.lowercased()
        guard normalizedName.hasPrefix("diagnostics-") else { return false }
        return entry.passCount > 0
            && entry.failCount == 0
    }

    private static func isSupersededLogRemediation(
        _ item: LogRemediationItem,
        logs: [CapabilityLogEntry],
        smokeReports: [SoftwareSmokeRunReport]
    ) -> Bool {
        guard !smokeReports.isEmpty else { return false }
        let canonicalSamplePaths = Set(item.samplePaths.map(canonicalPath))
        let affectedNames = Set(item.affectedLogNames.map { $0.lowercased() })
        let matchedLogs = logs.filter { log in
            canonicalSamplePaths.contains(canonicalPath(log.path))
                || affectedNames.contains(log.name.lowercased())
        }
        guard !matchedLogs.isEmpty else { return false }
        return matchedLogs.allSatisfy { log in
            SoftwareSmokeEvidenceResolver.supersedes(
                logName: log.name,
                logPath: log.path,
                modifiedAt: log.modifiedAt,
                reports: smokeReports
            )
        }
    }

    private static func isDiagnosticLaunchHealthLogEntry(_ entry: LaunchHealthEntry) -> Bool {
        guard entry.launchCount == 0, !entry.logNames.isEmpty else { return false }
        return entry.logNames.allSatisfy { $0.lowercased().hasPrefix("diagnostics-") }
    }

    private static func isVerifiedInstallerHistory(_ entry: LaunchHealthEntry, verifiedRecipeIds: Set<String>) -> Bool {
        guard !verifiedRecipeIds.isEmpty else { return false }
        if !entry.logPaths.isEmpty {
            let normalizedPaths = entry.logPaths.map { canonicalPath($0) }
            if normalizedPaths.allSatisfy({ path in
                verifiedRecipeIds.contains { recipeId in
                    path.contains("-install-\(recipeId.lowercased())-")
                }
            }) {
                return true
            }
        }
        guard isMSIInstallerEntry(entry) else { return false }
        let identities = [entry.bottleId, entry.bottleName, entry.id].compactMap { $0 }
        return verifiedRecipeIds.contains { recipeId in
            identities.contains { containsDelimitedIdentifier(recipeId, in: $0) }
        }
    }

    private static func isMSIInstallerEntry(_ entry: LaunchHealthEntry) -> Bool {
        guard let executable = entry.exe else { return false }
        let normalizedExecutable = executable
            .replacingOccurrences(of: "\\", with: "/")
            .lowercased()
        let name = URL(fileURLWithPath: normalizedExecutable).lastPathComponent
        return name == "msiexec" || name == "msiexec.exe"
    }

    private static func containsDelimitedIdentifier(_ identifier: String, in value: String) -> Bool {
        func normalizedIdentifier(_ raw: String) -> String {
            raw.lowercased()
                .replacingOccurrences(of: #"[^a-z0-9]+"#, with: "-", options: .regularExpression)
                .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        }
        let needle = normalizedIdentifier(identifier)
        let haystack = normalizedIdentifier(value)
        guard !needle.isEmpty, !haystack.isEmpty else { return false }
        return "-\(haystack)-".contains("-\(needle)-")
    }

    private static func isVerifiedManualSmokeHistory(_ entry: LaunchHealthEntry, verifiedRecipeIds: Set<String>) -> Bool {
        guard !verifiedRecipeIds.isEmpty, entry.launchCount == 0, !entry.logNames.isEmpty else { return false }
        return entry.logNames.allSatisfy { name in
            let normalizedName = name.lowercased()
            guard normalizedName.contains("-manual-smoke-") else { return false }
            return verifiedRecipeIds.contains { recipeId in
                normalizedName.contains(recipeId.lowercased())
            }
        }
    }

    private static func canonicalPath(_ path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.path.lowercased()
    }

    private static func severity(from severity: String) -> SupportTriageSeverity {
        switch severity.lowercased() {
        case "critical", "blocker":
            return .blocker
        case "high", "failed", "error":
            return .high
        case "medium", "warning", "attention":
            return .warning
        default:
            return .info
        }
    }

    private static func severity(from severity: SoftwareCollectionAcceptanceSeverity) -> SupportTriageSeverity {
        switch severity {
        case .blocker:
            return .blocker
        case .high:
            return .high
        case .warning:
            return .warning
        case .info:
            return .info
        }
    }

    private static func acquisitionSeverity(_ state: SoftwareAcquisitionState) -> SupportTriageSeverity {
        switch state {
        case .hashMismatch, .missingRecipe:
            return .blocker
        case .missingLocalInstaller, .downloadable:
            return .high
        case .manual:
            return .warning
        case .cached, .ready:
            return .info
        }
    }

    private static func severityRank(_ severity: SupportTriageSeverity) -> Int {
        switch severity {
        case .blocker:
            return 0
        case .high:
            return 1
        case .warning:
            return 2
        case .info:
            return 3
        }
    }
}
