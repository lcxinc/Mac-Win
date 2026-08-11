import Foundation

public enum SoftwareSmokeCheckState: String, Codable, CaseIterable, Equatable, Sendable {
    case passed
    case pending
    case warning
    case failed
    case blocked
    case notApplicable
}

public enum SoftwareSmokeStage: String, Codable, CaseIterable, Equatable, Sendable {
    case catalog
    case installer
    case install
    case launcher
    case launch
    case logReview
    case compatibilityRepair
    case verified
    case disabled
}

public struct SoftwareSmokeChecklistItem: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var label: String
    public var state: SoftwareSmokeCheckState
    public var detail: String
}

public struct SoftwareSmokeMatrixRow: Codable, Equatable, Identifiable, Sendable {
    public var id: String { recipeId }
    public var recipeId: String
    public var name: String
    public var category: String
    public var compatibilityRating: CompatibilityRating
    public var stage: SoftwareSmokeStage
    public var state: SoftwareTestPlanState
    public var highestSeverity: SoftwareSmokeCheckState
    public var checklist: [SoftwareSmokeChecklistItem]
    public var blockerCount: Int
    public var warningCount: Int
    public var nextAction: String
    public var latestLogPath: String?
    public var latestLaunchLogPath: String?
    public var latestRepairState: CompatibilityRepairAuditState?
}

public struct SoftwareSmokeMatrixReport: Codable, Equatable, Sendable {
    public var rootPath: String
    public var recipeCount: Int
    public var stageCounts: [String: Int]
    public var checkCounts: [String: Int]
    public var blockedCount: Int
    public var warningCount: Int
    public var failedCount: Int
    public var verifiedCount: Int
    public var nextActions: [SoftwareSmokeMatrixAction]
    public var rows: [SoftwareSmokeMatrixRow]

    public init(rootPath: String, rows: [SoftwareSmokeMatrixRow]) {
        self.rootPath = rootPath
        self.recipeCount = rows.count
        self.stageCounts = Dictionary(grouping: rows, by: { $0.stage.rawValue }).mapValues(\.count)
        let checks = rows.flatMap(\.checklist)
        self.checkCounts = Dictionary(grouping: checks, by: { $0.state.rawValue }).mapValues(\.count)
        self.blockedCount = rows.filter { $0.highestSeverity == .blocked }.count
        self.warningCount = rows.filter { $0.highestSeverity == .warning }.count
        self.failedCount = rows.filter { $0.highestSeverity == .failed }.count
        self.verifiedCount = rows.filter { $0.stage == .verified }.count
        self.nextActions = rows
            .filter { $0.stage != .verified && $0.stage != .disabled }
            .sorted { lhs, rhs in
                let lhsRank = Self.severityRank(lhs.highestSeverity)
                let rhsRank = Self.severityRank(rhs.highestSeverity)
                if lhsRank != rhsRank {
                    return lhsRank < rhsRank
                }
                return lhs.recipeId < rhs.recipeId
            }
            .prefix(12)
            .map(SoftwareSmokeMatrixAction.init(row:))
        self.rows = rows
    }

    private static func severityRank(_ state: SoftwareSmokeCheckState) -> Int {
        switch state {
        case .failed: 0
        case .blocked: 1
        case .warning: 2
        case .pending: 3
        case .passed: 4
        case .notApplicable: 5
        }
    }
}

public struct SoftwareSmokeMatrixAction: Codable, Equatable, Identifiable, Sendable {
    public var id: String { recipeId }
    public var recipeId: String
    public var stage: SoftwareSmokeStage
    public var severity: SoftwareSmokeCheckState
    public var title: String
    public var detail: String

    public init(row: SoftwareSmokeMatrixRow) {
        self.recipeId = row.recipeId
        self.stage = row.stage
        self.severity = row.highestSeverity
        self.title = row.nextAction
        self.detail = row.checklist
            .filter { item in item.state == row.highestSeverity || item.state == .failed || item.state == .blocked }
            .map { "\($0.label): \($0.detail)" }
            .joined(separator: " | ")
    }
}

public struct SoftwareSmokeMatrixService {
    public var paths: MacWinPaths

    public init(paths: MacWinPaths = MacWinPaths()) {
        self.paths = paths
    }

    public func report(
        softwareTestPlan: SoftwareTestPlanReport,
        compatibilityRepairAudit: CompatibilityRepairAuditReport,
        signedCatalogLoaded: Bool
    ) -> SoftwareSmokeMatrixReport {
        Self.report(
            rootPath: paths.root.path,
            softwareTestPlan: softwareTestPlan,
            compatibilityRepairAudit: compatibilityRepairAudit,
            signedCatalogLoaded: signedCatalogLoaded
        )
    }

    public static func report(
        rootPath: String,
        softwareTestPlan: SoftwareTestPlanReport,
        compatibilityRepairAudit: CompatibilityRepairAuditReport,
        signedCatalogLoaded: Bool
    ) -> SoftwareSmokeMatrixReport {
        let repairByLogPath = repairEntriesByLogPath(compatibilityRepairAudit.entries)
        let rows = softwareTestPlan.entries.map { entry in
            row(entry: entry, repairEntry: entry.latestLaunchLogPath.flatMap { repairByLogPath[canonicalPath($0)] }, signedCatalogLoaded: signedCatalogLoaded)
        }
        return SoftwareSmokeMatrixReport(rootPath: rootPath, rows: rows.sorted { $0.recipeId < $1.recipeId })
    }

    public static func csv(report: SoftwareSmokeMatrixReport) -> String {
        let checkIds = orderedUnique(report.rows.flatMap { row in row.checklist.map(\.id) })
        var header = [
            "recipe_id",
            "name",
            "category",
            "compatibility_rating",
            "stage",
            "state",
            "highest_severity",
            "blocker_count",
            "warning_count",
            "next_action",
            "latest_log_path",
            "latest_launch_log_path",
            "latest_repair_state"
        ]
        header.append(contentsOf: checkIds.map { "\($0)_state" })
        header.append(contentsOf: checkIds.map { "\($0)_detail" })

        let rows: [[String]] = report.rows.map { row in
            let checklistPairs: [(String, SoftwareSmokeChecklistItem)] = row.checklist.map { item in
                (item.id, item)
            }
            let checklistById: [String: SoftwareSmokeChecklistItem] = Dictionary(
                uniqueKeysWithValues: checklistPairs
            )
            var columns = [
                row.recipeId,
                row.name,
                row.category,
                row.compatibilityRating.rawValue,
                row.stage.rawValue,
                row.state.rawValue,
                row.highestSeverity.rawValue,
                "\(row.blockerCount)",
                "\(row.warningCount)",
                row.nextAction,
                row.latestLogPath ?? "",
                row.latestLaunchLogPath ?? "",
                row.latestRepairState?.rawValue ?? ""
            ]
            let states: [String] = checkIds.map { checklistById[$0]?.state.rawValue ?? "" }
            let details: [String] = checkIds.map { checklistById[$0]?.detail ?? "" }
            columns.append(contentsOf: states)
            columns.append(contentsOf: details)
            return columns
        }

        var csvRows = [header]
        csvRows.append(contentsOf: rows)
        return csvRows
            .map { $0.map(csvEscaped).joined(separator: ",") }
            .joined(separator: "\n") + "\n"
    }

    private static func row(
        entry: SoftwareTestPlanEntry,
        repairEntry: CompatibilityRepairAuditEntry?,
        signedCatalogLoaded: Bool
    ) -> SoftwareSmokeMatrixRow {
        let checklist = checklist(entry: entry, repairEntry: repairEntry, signedCatalogLoaded: signedCatalogLoaded)
        let highestSeverity = highestSeverity(checklist)
        return SoftwareSmokeMatrixRow(
            recipeId: entry.recipeId,
            name: entry.name,
            category: entry.category,
            compatibilityRating: entry.compatibilityRating,
            stage: stage(entry: entry, repairEntry: repairEntry),
            state: entry.state,
            highestSeverity: highestSeverity,
            checklist: checklist,
            blockerCount: checklist.filter { $0.state == .blocked || $0.state == .failed }.count,
            warningCount: checklist.filter { $0.state == .warning }.count,
            nextAction: entry.recommendedAction,
            latestLogPath: entry.latestLaunchLogPath ?? entry.latestInstallLogPath,
            latestLaunchLogPath: entry.latestLaunchLogPath,
            latestRepairState: repairEntry?.state
        )
    }

    private static func checklist(
        entry: SoftwareTestPlanEntry,
        repairEntry: CompatibilityRepairAuditEntry?,
        signedCatalogLoaded: Bool
    ) -> [SoftwareSmokeChecklistItem] {
        [
            catalogCheck(entry: entry, signedCatalogLoaded: signedCatalogLoaded),
            installerCheck(entry: entry),
            installCheck(entry: entry),
            launcherCheck(entry: entry),
            launchCheck(entry: entry),
            logCheck(entry: entry),
            repairCheck(entry: entry, repairEntry: repairEntry)
        ]
    }

    private static func catalogCheck(entry: SoftwareTestPlanEntry, signedCatalogLoaded: Bool) -> SoftwareSmokeChecklistItem {
        SoftwareSmokeChecklistItem(
            id: "catalog",
            label: "Signed catalog recipe",
            state: signedCatalogLoaded ? .passed : .failed,
            detail: signedCatalogLoaded ? "Recipe \(entry.recipeId) is loaded from the curated catalog." : "Curated catalog was not loaded or trusted."
        )
    }

    private static func installerCheck(entry: SoftwareTestPlanEntry) -> SoftwareSmokeChecklistItem {
        switch entry.installerMode {
        case .none:
            return SoftwareSmokeChecklistItem(id: "installer", label: "Installer source", state: .notApplicable, detail: "No installer is required.")
        case .alreadyInstalled:
            let state: SoftwareSmokeCheckState = entry.state == .existingInstallMissing ? .failed : .passed
            return SoftwareSmokeChecklistItem(id: "installer", label: "Existing install", state: state, detail: state == .passed ? "Recipe can use an existing install path." : "Expected installed executable was not found.")
        case .localFile:
            let state: SoftwareSmokeCheckState = entry.state == .localInstallerRequired ? .pending : .passed
            return SoftwareSmokeChecklistItem(id: "installer", label: "Local installer", state: state, detail: state == .passed ? "Local installer was selected or is not blocking." : "A local installer must be selected.")
        case .download:
            if entry.installerHashStatus == .mismatch {
                return SoftwareSmokeChecklistItem(id: "installer", label: "Installer cache", state: .failed, detail: "Cached installer hash does not match the recipe.")
            }
            if entry.cachedInstallerPath != nil && entry.installerHashStatus == .match {
                return SoftwareSmokeChecklistItem(id: "installer", label: "Installer cache", state: .passed, detail: "Installer is cached and hash verified.")
            }
            return SoftwareSmokeChecklistItem(id: "installer", label: "Installer cache", state: .pending, detail: "Installer still needs to be downloaded or verified.")
        }
    }

    private static func installCheck(entry: SoftwareTestPlanEntry) -> SoftwareSmokeChecklistItem {
        if entry.installerMode == .none {
            return SoftwareSmokeChecklistItem(id: "install", label: "Install task", state: .notApplicable, detail: "Synthetic or built-in recipe does not require install.")
        }
        switch entry.latestInstallState {
        case .succeeded:
            return SoftwareSmokeChecklistItem(id: "install", label: "Install task", state: .passed, detail: "Latest install completed successfully.")
        case .failed, .cancelled:
            return SoftwareSmokeChecklistItem(id: "install", label: "Install task", state: .failed, detail: "Latest install did not complete successfully.")
        case .queued, .running:
            return SoftwareSmokeChecklistItem(id: "install", label: "Install task", state: .pending, detail: "Install task is still running.")
        case .launched:
            return SoftwareSmokeChecklistItem(id: "install", label: "Install task", state: .pending, detail: "Interactive installer was launched; completion still needs confirmation.")
        case nil:
            if entry.installedLauncherCount > 0 || entry.installerMode == .alreadyInstalled {
                return SoftwareSmokeChecklistItem(id: "install", label: "Install task", state: .passed, detail: "Installed launcher exists without a recorded install task.")
            }
            return SoftwareSmokeChecklistItem(id: "install", label: "Install task", state: .pending, detail: "No install task has been recorded.")
        }
    }

    private static func launcherCheck(entry: SoftwareTestPlanEntry) -> SoftwareSmokeChecklistItem {
        if entry.installedLauncherCount > 0 {
            return SoftwareSmokeChecklistItem(
                id: "launcher",
                label: "Launcher",
                state: .passed,
                detail: "\(entry.installedLauncherCount) launcher(s): \(entry.installedLauncherIds.joined(separator: ", "))"
            )
        }
        return SoftwareSmokeChecklistItem(id: "launcher", label: "Launcher", state: .pending, detail: "No launcher has been generated yet.")
    }

    private static func launchCheck(entry: SoftwareTestPlanEntry) -> SoftwareSmokeChecklistItem {
        guard entry.installedLauncherCount > 0 else {
            return SoftwareSmokeChecklistItem(id: "launch", label: "Launch smoke", state: .pending, detail: "Launcher must be generated before launch smoke testing.")
        }
        guard let state = entry.latestLaunchState else {
            return SoftwareSmokeChecklistItem(id: "launch", label: "Launch smoke", state: .pending, detail: "No launch record has been captured.")
        }
        if state == .failedToLaunch {
            return SoftwareSmokeChecklistItem(id: "launch", label: "Launch smoke", state: .failed, detail: "Wine process failed to start.")
        }
        if let exitCode = entry.latestLaunchExitCode, exitCode != 0 {
            if isControlledSmokeSIGTERM(entry)
                || (entry.state == .verified && entry.latestLogHealth == .passed && entry.blockers.isEmpty) {
                return SoftwareSmokeChecklistItem(
                    id: "launch",
                    label: "Launch smoke",
                    state: .passed,
                    detail: "Latest launch was verified by the managed smoke log after controlled exit code \(exitCode)."
                )
            }
            return SoftwareSmokeChecklistItem(id: "launch", label: "Launch smoke", state: .failed, detail: "Latest launch exited with code \(exitCode).")
        }
        return SoftwareSmokeChecklistItem(id: "launch", label: "Launch smoke", state: .passed, detail: "Latest launch reached a completed record.")
    }

    private static func isControlledSmokeSIGTERM(_ entry: SoftwareTestPlanEntry) -> Bool {
        guard entry.latestLaunchState == .completed,
              entry.latestLaunchExitCode == SIGTERM,
              let logPath = entry.latestLaunchLogPath?.lowercased()
        else {
            return false
        }
        return logPath.contains("-cli-smoke-") || logPath.contains("cli-smoke")
    }

    private static func logCheck(entry: SoftwareTestPlanEntry) -> SoftwareSmokeChecklistItem {
        guard let health = entry.latestLogHealth else {
            return SoftwareSmokeChecklistItem(id: "log", label: "Log health", state: .pending, detail: "No related launch or install log has been summarized.")
        }
        switch health {
        case .passed:
            return SoftwareSmokeChecklistItem(id: "log", label: "Log health", state: .passed, detail: "Latest log contains a passing signal.")
        case .attention:
            return SoftwareSmokeChecklistItem(id: "log", label: "Log health", state: .warning, detail: "Latest log needs review: \(entry.probableIssueIds.joined(separator: ", ")).")
        case .failed:
            return SoftwareSmokeChecklistItem(id: "log", label: "Log health", state: .failed, detail: "Latest log contains failure signals: \(entry.probableIssueIds.joined(separator: ", ")).")
        case .quiet:
            return SoftwareSmokeChecklistItem(id: "log", label: "Log health", state: .warning, detail: "Latest log has no clear pass/fail signal.")
        }
    }

    private static func repairCheck(entry: SoftwareTestPlanEntry, repairEntry: CompatibilityRepairAuditEntry?) -> SoftwareSmokeChecklistItem {
        guard entry.installedLauncherCount > 0 else {
            return SoftwareSmokeChecklistItem(id: "repair", label: "Compatibility repair", state: .pending, detail: "Launcher must be generated before compatibility repair can be audited.")
        }
        guard let repairEntry else {
            if entry.state == .verified {
                return SoftwareSmokeChecklistItem(id: "repair", label: "Compatibility repair", state: .notApplicable, detail: "No app-specific compatibility repair audit was required for the verified launch.")
            }
            return SoftwareSmokeChecklistItem(id: "repair", label: "Compatibility repair", state: .pending, detail: "No matching launch record has been audited for repair environment.")
        }
        switch repairEntry.state {
        case .ready:
            return SoftwareSmokeChecklistItem(id: "repair", label: "Compatibility repair", state: .passed, detail: "Required repair environment was present.")
        case .missingRepairs:
            return SoftwareSmokeChecklistItem(id: "repair", label: "Compatibility repair", state: .warning, detail: "Missing repair keys: \(repairEntry.missingRepairKeys.joined(separator: ", ")).")
        case .staleFlags:
            return SoftwareSmokeChecklistItem(id: "repair", label: "Compatibility repair", state: .failed, detail: "Stale text flags remain: \(repairEntry.staleRenderingFlags.joined(separator: ", ")).")
        }
    }

    private static func stage(entry: SoftwareTestPlanEntry, repairEntry: CompatibilityRepairAuditEntry?) -> SoftwareSmokeStage {
        switch entry.state {
        case .disabled:
            return .disabled
        case .blocked, .localInstallerRequired, .existingInstallMissing, .missingInstaller, .hashMismatch:
            return .installer
        case .readyToInstall, .installerLaunched, .installFailed:
            return .install
        case .installedNotLaunched:
            return .launcher
        case .launchFailed:
            return .launch
        case .needsReview:
            if repairEntry?.state == .staleFlags || repairEntry?.state == .missingRepairs {
                return .compatibilityRepair
            }
            return .logReview
        case .verified:
            return repairEntry?.state == .ready || repairEntry == nil ? .verified : .compatibilityRepair
        }
    }

    private static func highestSeverity(_ checklist: [SoftwareSmokeChecklistItem]) -> SoftwareSmokeCheckState {
        for state in [SoftwareSmokeCheckState.failed, .blocked, .warning, .pending] where checklist.contains(where: { $0.state == state }) {
            return state
        }
        return .passed
    }

    private static func repairEntriesByLogPath(_ entries: [CompatibilityRepairAuditEntry]) -> [String: CompatibilityRepairAuditEntry] {
        var result: [String: CompatibilityRepairAuditEntry] = [:]
        for entry in entries {
            let path = canonicalPath(entry.logPath)
            if let existing = result[path], existing.startedAt >= entry.startedAt {
                continue
            }
            result[path] = entry
        }
        return result
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

    private static func orderedUnique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for value in values where !seen.contains(value) {
            seen.insert(value)
            result.append(value)
        }
        return result
    }

    private static func canonicalPath(_ path: String) -> String {
        URL(fileURLWithPath: path).resolvingSymlinksInPath().standardizedFileURL.path
    }
}
