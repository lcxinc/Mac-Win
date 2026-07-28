import Foundation

public enum SoftwareTestPlanState: String, Codable, CaseIterable, Equatable, Sendable {
    case disabled
    case blocked
    case localInstallerRequired
    case existingInstallMissing
    case missingInstaller
    case hashMismatch
    case readyToInstall
    case installerLaunched
    case installFailed
    case installedNotLaunched
    case launchFailed
    case needsReview
    case verified
}

public struct SoftwareTestPlanReport: Codable, Equatable, Sendable {
    public var rootPath: String
    public var recipeCount: Int
    public var stateCounts: [String: Int]
    public var readyToInstallCount: Int
    public var installedCount: Int
    public var verifiedCount: Int
    public var failingCount: Int
    public var reviewCount: Int
    public var nextActions: [SoftwareTestPlanAction]
    public var entries: [SoftwareTestPlanEntry]

    public init(rootPath: String, entries: [SoftwareTestPlanEntry]) {
        self.rootPath = rootPath
        self.recipeCount = entries.count
        self.stateCounts = Dictionary(grouping: entries, by: { $0.state.rawValue }).mapValues(\.count)
        self.readyToInstallCount = entries.filter { $0.state == .readyToInstall }.count
        self.installedCount = entries.filter { $0.installedLauncherCount > 0 }.count
        self.verifiedCount = entries.filter { $0.state == .verified }.count
        self.failingCount = entries.filter { $0.state == .installFailed || $0.state == .launchFailed }.count
        self.reviewCount = entries.filter { $0.state == .needsReview }.count
        self.nextActions = entries
            .filter { $0.state != .verified && $0.state != .disabled }
            .sorted { lhs, rhs in
                if lhs.priority != rhs.priority {
                    return lhs.priority < rhs.priority
                }
                return lhs.recipeId < rhs.recipeId
            }
            .prefix(12)
            .map { SoftwareTestPlanAction(entry: $0) }
        self.entries = entries
    }
}

public struct SoftwareTestPlanAction: Codable, Equatable, Identifiable, Sendable {
    public var id: String { recipeId }
    public var recipeId: String
    public var state: SoftwareTestPlanState
    public var priority: Int
    public var title: String
    public var detail: String

    public init(entry: SoftwareTestPlanEntry) {
        self.recipeId = entry.recipeId
        self.state = entry.state
        self.priority = entry.priority
        self.title = entry.recommendedAction
        self.detail = entry.summary
    }
}

public struct SoftwareTestPlanEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: String { recipeId }
    public var recipeId: String
    public var name: String
    public var publisher: String
    public var category: String
    public var compatibilityRating: CompatibilityRating
    public var state: SoftwareTestPlanState
    public var priority: Int
    public var summary: String
    public var recommendedAction: String
    public var readinessState: RecipeReadinessState?
    public var readinessIssues: [RecipeReadinessIssue]
    public var installerMode: InstallerMode
    public var installerHashStatus: InstallerHashStatus?
    public var cachedInstallerPath: String?
    public var requiresWin32: Bool
    public var latestInstallState: InstallTaskState?
    public var latestInstallAt: Date?
    public var latestInstallLogPath: String?
    public var installedLauncherCount: Int
    public var installedLauncherIds: [String]
    public var latestLaunchState: WineLaunchState?
    public var latestLaunchAt: Date?
    public var latestLaunchLogPath: String?
    public var latestLaunchExitCode: Int32?
    public var latestLogHealth: LogHealth?
    public var latestLogHints: [LogHint]
    public var probableIssueIds: [String]
    public var blockers: [String]
}

public struct SoftwareTestPlanService {
    public var paths: MacWinPaths

    public init(paths: MacWinPaths = MacWinPaths()) {
        self.paths = paths
    }

    public func report(
        recipes: [RecipeManifest],
        bottles: [BottleManifest],
        readiness: RecipeReadinessReport,
        installerAssets: InstallerAssetReport,
        installHistory: InstallHistoryReport?,
        launchHistory: LaunchHistoryReport?,
        logs: CapabilityLogReport,
        generatedAt: Date = Date()
    ) -> SoftwareTestPlanReport {
        Self.report(
            rootPath: paths.root.path,
            recipes: recipes,
            bottles: bottles,
            readiness: readiness,
            installerAssets: installerAssets,
            installHistory: installHistory,
            launchHistory: launchHistory,
            logs: logs,
            generatedAt: generatedAt
        )
    }

    public static func report(
        rootPath: String,
        recipes: [RecipeManifest],
        bottles: [BottleManifest],
        readiness: RecipeReadinessReport,
        installerAssets: InstallerAssetReport,
        installHistory: InstallHistoryReport?,
        launchHistory: LaunchHistoryReport?,
        logs: CapabilityLogReport,
        generatedAt: Date = Date()
    ) -> SoftwareTestPlanReport {
        let readinessByRecipe = Dictionary(uniqueKeysWithValues: readiness.entries.map { ($0.recipeId, $0) })
        let installerByRecipe = Dictionary(uniqueKeysWithValues: installerAssets.recipes.map { ($0.recipeId, $0) })
        let installTasksByRecipe = latestInstallTasksByRecipe(installHistory?.tasks ?? [])
        let launchersByRecipe = installedLaunchersByRecipe(recipes: recipes, bottles: bottles)
        let launchRecordsByRecipe = latestLaunchRecordsByRecipe(
            recipes: recipes,
            launchersByRecipe: launchersByRecipe,
            records: launchHistory?.records ?? []
        )
        let logEntryByPath = entriesByPath(logs.entries, path: \.path)
        let logIssuesByPath = entriesByPath(logs.issueReport.recentFailures, path: \.path)

        let entries = recipes.sorted { $0.id < $1.id }.map { recipe in
            entry(
                recipe: recipe,
                readiness: readinessByRecipe[recipe.id],
                installer: installerByRecipe[recipe.id],
                latestInstall: installTasksByRecipe[recipe.id],
                launchers: launchersByRecipe[recipe.id] ?? [],
                latestLaunch: launchRecordsByRecipe[recipe.id],
                logEntryByPath: logEntryByPath,
                logIssuesByPath: logIssuesByPath,
                generatedAt: generatedAt
            )
        }
        return SoftwareTestPlanReport(rootPath: rootPath, entries: entries)
    }

    public static func csv(report: SoftwareTestPlanReport) -> String {
        let formatter = ISO8601DateFormatter()
        var rows: [[String]] = [[
            "recipe_id",
            "name",
            "publisher",
            "category",
            "compatibility_rating",
            "state",
            "priority",
            "recommended_action",
            "summary",
            "readiness_state",
            "readiness_issues",
            "installer_mode",
            "installer_hash_status",
            "cached_installer_path",
            "requires_win32",
            "latest_install_state",
            "latest_install_at",
            "latest_install_log_path",
            "installed_launcher_count",
            "installed_launcher_ids",
            "latest_launch_state",
            "latest_launch_at",
            "latest_launch_log_path",
            "latest_launch_exit_code",
            "latest_log_health",
            "latest_log_hints",
            "probable_issue_ids",
            "blockers"
        ]]

        for entry in report.entries.sorted(by: { lhs, rhs in
            if lhs.priority != rhs.priority {
                return lhs.priority < rhs.priority
            }
            return lhs.recipeId < rhs.recipeId
        }) {
            rows.append([
                entry.recipeId,
                entry.name,
                entry.publisher,
                entry.category,
                entry.compatibilityRating.rawValue,
                entry.state.rawValue,
                String(entry.priority),
                entry.recommendedAction,
                entry.summary,
                entry.readinessState?.rawValue ?? "",
                entry.readinessIssues.map(\.rawValue).joined(separator: ";"),
                entry.installerMode.rawValue,
                entry.installerHashStatus?.rawValue ?? "",
                entry.cachedInstallerPath ?? "",
                entry.requiresWin32 ? "true" : "false",
                entry.latestInstallState?.rawValue ?? "",
                entry.latestInstallAt.map { formatter.string(from: $0) } ?? "",
                entry.latestInstallLogPath ?? "",
                String(entry.installedLauncherCount),
                entry.installedLauncherIds.joined(separator: ";"),
                entry.latestLaunchState?.rawValue ?? "",
                entry.latestLaunchAt.map { formatter.string(from: $0) } ?? "",
                entry.latestLaunchLogPath ?? "",
                entry.latestLaunchExitCode.map(String.init) ?? "",
                entry.latestLogHealth?.rawValue ?? "",
                entry.latestLogHints.map(\.rawValue).joined(separator: ";"),
                entry.probableIssueIds.joined(separator: ";"),
                entry.blockers.joined(separator: ";")
            ])
        }

        return rows
            .map { $0.map(csvEscaped).joined(separator: ",") }
            .joined(separator: "\n")
    }

    private static func entry(
        recipe: RecipeManifest,
        readiness: RecipeReadinessEntry?,
        installer: RecipeInstallerAssetStatus?,
        latestInstall: InstallTask?,
        launchers: [LauncherManifest],
        latestLaunch: WineLaunchRecord?,
        logEntryByPath: [String: CapabilityLogEntry],
        logIssuesByPath: [String: LogIssueSample],
        generatedAt: Date
    ) -> SoftwareTestPlanEntry {
        let relatedLogPath = latestLaunch?.logPath ?? latestInstall?.logPath
        let logEntry = relatedLogPath.flatMap { logEntryByPath[$0] ?? logEntryByPath[canonicalPath($0)] }
        let logIssue = relatedLogPath.flatMap { logIssuesByPath[$0] ?? logIssuesByPath[canonicalPath($0)] }
        let state = state(
            recipe: recipe,
            readiness: readiness,
            installer: installer,
            latestInstall: latestInstall,
            launchers: launchers,
            latestLaunch: latestLaunch,
            logEntry: logEntry,
            logIssue: logIssue,
            generatedAt: generatedAt
        )
        let blockers = blockers(
            recipe: recipe,
            readiness: readiness,
            installer: installer,
            latestInstall: latestInstall,
            latestLaunch: latestLaunch,
            logEntry: logEntry,
            logIssue: logIssue,
            generatedAt: generatedAt
        )
        let action = recommendedAction(
            state: state,
            recipe: recipe,
            readiness: readiness,
            installer: installer,
            latestInstall: latestInstall,
            latestLaunch: latestLaunch,
            logIssue: logIssue
        )
        return SoftwareTestPlanEntry(
            recipeId: recipe.id,
            name: recipe.name,
            publisher: recipe.publisher,
            category: recipe.category,
            compatibilityRating: recipe.compatibilityRating,
            state: state,
            priority: priority(state: state, rating: recipe.compatibilityRating),
            summary: summary(
                state: state,
                recipe: recipe,
                readiness: readiness,
                installer: installer,
                latestInstall: latestInstall,
                launchers: launchers,
                latestLaunch: latestLaunch,
                logIssue: logIssue
            ),
            recommendedAction: action,
            readinessState: readiness?.state,
            readinessIssues: readiness?.issues ?? [],
            installerMode: recipe.installer.mode,
            installerHashStatus: installer?.hashStatus,
            cachedInstallerPath: installer?.cachedPath,
            requiresWin32: recipe.engineRequirements.requiresWin32 || installer?.requiresWin32Installer == true,
            latestInstallState: latestInstall?.state,
            latestInstallAt: latestInstall?.endedAt ?? latestInstall?.startedAt,
            latestInstallLogPath: latestInstall?.logPath,
            installedLauncherCount: launchers.count,
            installedLauncherIds: launchers.map(\.id).sorted(),
            latestLaunchState: latestLaunch?.state,
            latestLaunchAt: latestLaunch?.endedAt ?? latestLaunch?.startedAt,
            latestLaunchLogPath: latestLaunch?.logPath,
            latestLaunchExitCode: latestLaunch?.exitCode,
            latestLogHealth: logEntry.flatMap { LogHealth(rawValue: $0.health) } ?? logIssue.flatMap { LogHealth(rawValue: $0.health) },
            latestLogHints: (logEntry?.hints.compactMap(LogHint.init(rawValue:)) ?? logIssue?.hints.compactMap(LogHint.init(rawValue:)) ?? []),
            probableIssueIds: logIssue?.probableIssueIds ?? [],
            blockers: blockers
        )
    }

    private static func state(
        recipe: RecipeManifest,
        readiness: RecipeReadinessEntry?,
        installer: RecipeInstallerAssetStatus?,
        latestInstall: InstallTask?,
        launchers: [LauncherManifest],
        latestLaunch: WineLaunchRecord?,
        logEntry: CapabilityLogEntry?,
        logIssue: LogIssueSample?,
        generatedAt: Date
    ) -> SoftwareTestPlanState {
        if recipe.disabledReason != nil || readiness?.state == .disabled {
            return .disabled
        }
        if readiness?.issues.contains(.existingInstallMissing) == true {
            return .existingInstallMissing
        }
        if readiness?.issues.contains(.localInstallerRequired) == true,
           latestInstall?.state != .succeeded,
           launchers.isEmpty {
            return .localInstallerRequired
        }
        if readiness?.state == .blocked {
            return .blocked
        }
        if installer?.hashStatus == .mismatch {
            return .hashMismatch
        }
        if recipe.installer.mode == .download && installer?.cachedExists != true {
            return .missingInstaller
        }
        if latestInstall?.state == .failed || latestInstall?.state == .cancelled {
            return isCurrentFailure(latestInstall?.endedAt ?? latestInstall?.startedAt, generatedAt: generatedAt)
                ? .installFailed
                : .needsReview
        }
        if latestInstall?.state == .launched && launchers.isEmpty {
            return .installerLaunched
        }
        if !launchers.isEmpty {
            guard let latestLaunch else { return .installedNotLaunched }
            if isPassingLaunchLog(logEntry) {
                return .verified
            }
            if isControlledSmokeSIGTERM(latestLaunch), logIssue == nil {
                return .verified
            }
            if latestLaunch.state == .failedToLaunch || (latestLaunch.exitCode ?? 0) != 0 {
                return isCurrentFailure(latestLaunch.endedAt ?? latestLaunch.startedAt, generatedAt: generatedAt)
                    ? .launchFailed
                    : .needsReview
            }
            if logIssue != nil || logEntry?.health == LogHealth.failed.rawValue || logEntry?.health == LogHealth.attention.rawValue {
                return .needsReview
            }
            return .verified
        }
        if latestInstall?.state == .succeeded {
            return .installedNotLaunched
        }
        return .readyToInstall
    }

    private static func blockers(
        recipe: RecipeManifest,
        readiness: RecipeReadinessEntry?,
        installer: RecipeInstallerAssetStatus?,
        latestInstall: InstallTask?,
        latestLaunch: WineLaunchRecord?,
        logEntry: CapabilityLogEntry?,
        logIssue: LogIssueSample?,
        generatedAt: Date
    ) -> [String] {
        var values: [String] = []
        if let reason = recipe.disabledReason {
            values.append("disabled:\(reason)")
        }
        values.append(contentsOf: readiness?.issues.map(\.rawValue) ?? [])
        if installer?.hashStatus == .mismatch {
            values.append("installerHashMismatch")
        }
        if (latestInstall?.state == .failed || latestInstall?.state == .cancelled),
           isCurrentFailure(latestInstall?.endedAt ?? latestInstall?.startedAt, generatedAt: generatedAt) {
            values.append("install\(latestInstall?.state.rawValue.capitalized ?? "Failed")")
        }
        if isPassingLaunchLog(logEntry) {
            return values.filter { $0 != RecipeReadinessIssue.localInstallerRequired.rawValue }
        }
        if isControlledSmokeSIGTERM(latestLaunch), logIssue == nil {
            return values.filter { $0 != RecipeReadinessIssue.localInstallerRequired.rawValue }
        }
        if latestLaunch?.state == .failedToLaunch,
           isCurrentFailure(latestLaunch?.endedAt ?? latestLaunch?.startedAt, generatedAt: generatedAt) {
            values.append("launchFailedToStart")
        } else if let exitCode = latestLaunch?.exitCode, exitCode != 0,
                  isCurrentFailure(latestLaunch?.endedAt ?? latestLaunch?.startedAt, generatedAt: generatedAt) {
            values.append("launchExit\(exitCode)")
        }
        values.append(contentsOf: logIssue?.probableIssueIds ?? [])
        return Array(Set(values)).sorted()
    }

    private static func isPassingLaunchLog(_ logEntry: CapabilityLogEntry?) -> Bool {
        guard let logEntry else { return false }
        let blockingHints: Set<String> = [
            LogHint.wineCrash.rawValue,
            LogHint.wineProgramError.rawValue
        ]
        guard logEntry.health != LogHealth.failed.rawValue,
              blockingHints.isDisjoint(with: Set(logEntry.hints))
        else {
            return false
        }
        return logEntry.health == LogHealth.passed.rawValue
            || logEntry.hints.contains(LogHint.passObserved.rawValue)
            || logEntry.passCount > 0
    }

    private static func isControlledSmokeSIGTERM(_ latestLaunch: WineLaunchRecord?) -> Bool {
        guard let latestLaunch,
              latestLaunch.state == .completed,
              latestLaunch.exitCode == SIGTERM
        else {
            return false
        }
        let normalizedLogPath = latestLaunch.logPath.lowercased()
        return normalizedLogPath.contains("-cli-smoke-")
            || normalizedLogPath.contains("cli-smoke")
    }

    private static func recommendedAction(
        state: SoftwareTestPlanState,
        recipe: RecipeManifest,
        readiness: RecipeReadinessEntry?,
        installer: RecipeInstallerAssetStatus?,
        latestInstall: InstallTask?,
        latestLaunch: WineLaunchRecord?,
        logIssue: LogIssueSample?
    ) -> String {
        switch state {
        case .disabled:
            return "Keep disabled until the recipe warning is resolved."
        case .blocked:
            return "Fix recipe blockers: \((readiness?.issues.map(\.rawValue) ?? []).joined(separator: ", "))."
        case .localInstallerRequired:
            return "Choose a local installer and verify its source before running the recipe."
        case .existingInstallMissing:
            return "Point the recipe at an existing install or run the installer first."
        case .missingInstaller:
            return "Download \(installer?.fileName ?? recipe.name) into the MacWin Downloads cache."
        case .hashMismatch:
            return "Delete and re-download \(installer?.fileName ?? recipe.name); cached hash does not match the recipe."
        case .readyToInstall:
            return "Install into the high-performance Windows 11 bottle, then launch once with logging enabled."
        case .installerLaunched:
            return "Finish the interactive installer, then scan the bottle to generate launchers."
        case .installFailed:
            return "Inspect \(latestInstall?.logPath ?? "the install log") and rerun with diagnostic logging."
        case .installedNotLaunched:
            return "Launch the installed app once to collect a launch record and smoke-test log."
        case .launchFailed:
            return "Inspect \(latestLaunch?.logPath ?? "the launch log") and retry with the matching compatibility preset."
        case .needsReview:
            return "Review \(logIssue?.name ?? "the latest log") and compare with probe results before marking verified."
        case .verified:
            return "Keep as a baseline app; rerun after engine or preset changes."
        }
    }

    private static func summary(
        state: SoftwareTestPlanState,
        recipe: RecipeManifest,
        readiness: RecipeReadinessEntry?,
        installer: RecipeInstallerAssetStatus?,
        latestInstall: InstallTask?,
        launchers: [LauncherManifest],
        latestLaunch: WineLaunchRecord?,
        logIssue: LogIssueSample?
    ) -> String {
        var parts = ["state=\(state.rawValue)", "mode=\(recipe.installer.mode.rawValue)"]
        if let readiness {
            parts.append("readiness=\(readiness.state.rawValue)")
        }
        if let hash = installer?.hashStatus {
            parts.append("hash=\(hash.rawValue)")
        }
        if let installState = latestInstall?.state {
            parts.append("install=\(installState.rawValue)")
        }
        if !launchers.isEmpty {
            parts.append("launchers=\(launchers.count)")
        }
        if let launchState = latestLaunch?.state {
            parts.append("launch=\(launchState.rawValue)")
        }
        if let exitCode = latestLaunch?.exitCode {
            parts.append("exit=\(exitCode)")
        }
        if let issues = logIssue?.probableIssueIds, !issues.isEmpty {
            parts.append("issues=\(issues.joined(separator: ","))")
        }
        return parts.joined(separator: " ")
    }

    private static func priority(state: SoftwareTestPlanState, rating: CompatibilityRating) -> Int {
        let base: Int
        switch state {
        case .launchFailed, .installFailed, .hashMismatch:
            base = 10
        case .needsReview:
            base = 20
        case .readyToInstall:
            base = 30
        case .installerLaunched:
            base = 35
        case .missingInstaller, .localInstallerRequired, .existingInstallMissing:
            base = 40
        case .installedNotLaunched:
            base = 50
        case .blocked:
            base = 60
        case .verified:
            base = 80
        case .disabled:
            base = 90
        }
        return base + ratingWeight(rating)
    }

    private static func isCurrentFailure(_ date: Date?, generatedAt: Date) -> Bool {
        guard let date else { return true }
        return date >= generatedAt.addingTimeInterval(-24 * 60 * 60)
    }

    private static func ratingWeight(_ rating: CompatibilityRating) -> Int {
        switch rating {
        case .excellent: 0
        case .good: 1
        case .limited: 2
        case .experimental: 3
        case .unknown: 4
        }
    }

    private static func latestInstallTasksByRecipe(_ tasks: [InstallTask]) -> [String: InstallTask] {
        var result: [String: InstallTask] = [:]
        for task in tasks {
            let timestamp = task.endedAt ?? task.startedAt
            if let existing = result[task.recipeId] {
                let existingTimestamp = existing.endedAt ?? existing.startedAt
                if existingTimestamp >= timestamp {
                    continue
                }
            }
            result[task.recipeId] = task
        }
        return result
    }

    private static func installedLaunchersByRecipe(
        recipes: [RecipeManifest],
        bottles: [BottleManifest]
    ) -> [String: [LauncherManifest]] {
        let recipeLauncherIds = Dictionary(uniqueKeysWithValues: recipes.map { recipe in
            (recipe.id, Set(recipe.launchers.map(\.id)))
        })
        var result: [String: [LauncherManifest]] = [:]
        for launcher in bottles.flatMap(\.installedApps) {
            for recipe in recipes {
                let knownLauncherIds = recipeLauncherIds[recipe.id] ?? []
                if launcher.appId == recipe.id || knownLauncherIds.contains(launcher.id) {
                    result[recipe.id, default: []].append(launcher)
                }
            }
        }
        return result.mapValues { $0.sorted { $0.id < $1.id } }
    }

    private static func latestLaunchRecordsByRecipe(
        recipes: [RecipeManifest],
        launchersByRecipe: [String: [LauncherManifest]],
        records: [WineLaunchRecord]
    ) -> [String: WineLaunchRecord] {
        var result: [String: WineLaunchRecord] = [:]
        for recipe in recipes {
            let launchers = launchersByRecipe[recipe.id] ?? []
            let executableNeedles = Set((launchers.map(\.exePath) + recipe.launchers.map(\.exePath)).map(normalizeExecutablePath))
            let displayNeedles = Set((launchers.map(\.displayName) + recipe.launchers.map(\.displayName) + [recipe.name]).map { $0.lowercased() })
            let matches = records.filter { record in
                let normalizedExe = normalizeExecutablePath(record.exe)
                if executableNeedles.contains(normalizedExe) {
                    return true
                }
                let searchable = "\(record.exe) \(record.commandLine.joined(separator: " "))".lowercased()
                return displayNeedles.contains { searchable.contains($0) }
            }
            guard let latest = matches.max(by: { $0.startedAt < $1.startedAt }) else { continue }
            result[recipe.id] = latest
        }
        return result
    }

    private static func normalizeExecutablePath(_ value: String) -> String {
        value.replacingOccurrences(of: "/", with: "\\")
            .lowercased()
    }

    private static func entriesByPath<T>(_ values: [T], path: KeyPath<T, String>) -> [String: T] {
        var result: [String: T] = [:]
        for value in values {
            let rawPath = value[keyPath: path]
            result[rawPath] = value
            result[canonicalPath(rawPath)] = value
        }
        return result
    }

    private static func canonicalPath(_ path: String) -> String {
        URL(fileURLWithPath: path).resolvingSymlinksInPath().standardizedFileURL.path
    }

    private static func csvEscaped(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
