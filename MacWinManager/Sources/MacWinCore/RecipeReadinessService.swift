import Foundation

public enum RecipeReadinessState: String, Codable, Equatable, Sendable {
    case ready
    case actionRequired
    case blocked
    case disabled
}

public enum RecipeReadinessIssue: String, Codable, CaseIterable, Equatable, Sendable {
    case disabled
    case noCompatibleEngine
    case missingDownloadURL
    case missingDownloadFileName
    case missingSha256
    case localInstallerRequired
    case existingInstallMissing
    case missingLauncher
    case missingLauncherAsset
    case obsoleteRenderingFlag
}

public struct RecipeReadinessEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: String { recipeId }
    public var recipeId: String
    public var recipeName: String
    public var publisher: String
    public var category: String
    public var compatibilityRating: CompatibilityRating
    public var installerMode: InstallerMode
    public var state: RecipeReadinessState
    public var issues: [RecipeReadinessIssue]
    public var warningCount: Int
    public var requiresWin32: Bool
    public var compatibleEngineIds: [String]
    public var launcherCount: Int
    public var missingLauncherAssetPaths: [String]
    public var existingInstallHintPaths: [String]
    public var existingInstallFound: Bool
    public var downloadURL: String?
    public var fileName: String?
    public var sha256Present: Bool
    public var obsoleteRenderingFlags: [String]

    public init(
        recipeId: String,
        recipeName: String,
        publisher: String,
        category: String,
        compatibilityRating: CompatibilityRating,
        installerMode: InstallerMode,
        state: RecipeReadinessState,
        issues: [RecipeReadinessIssue],
        warningCount: Int,
        requiresWin32: Bool,
        compatibleEngineIds: [String],
        launcherCount: Int,
        missingLauncherAssetPaths: [String] = [],
        existingInstallHintPaths: [String] = [],
        existingInstallFound: Bool = false,
        downloadURL: String? = nil,
        fileName: String? = nil,
        sha256Present: Bool = false,
        obsoleteRenderingFlags: [String] = []
    ) {
        self.recipeId = recipeId
        self.recipeName = recipeName
        self.publisher = publisher
        self.category = category
        self.compatibilityRating = compatibilityRating
        self.installerMode = installerMode
        self.state = state
        self.issues = issues
        self.warningCount = warningCount
        self.requiresWin32 = requiresWin32
        self.compatibleEngineIds = compatibleEngineIds
        self.launcherCount = launcherCount
        self.missingLauncherAssetPaths = missingLauncherAssetPaths
        self.existingInstallHintPaths = existingInstallHintPaths
        self.existingInstallFound = existingInstallFound
        self.downloadURL = downloadURL
        self.fileName = fileName
        self.sha256Present = sha256Present
        self.obsoleteRenderingFlags = obsoleteRenderingFlags
    }
}

public struct RecipeReadinessReport: Codable, Equatable, Sendable {
    public var rootPath: String
    public var recipeCount: Int
    public var readyCount: Int
    public var actionRequiredCount: Int
    public var blockedCount: Int
    public var disabledCount: Int
    public var downloadRecipeCount: Int
    public var localInstallerRecipeCount: Int
    public var alreadyInstalledRecipeCount: Int
    public var requiresWin32Count: Int
    public var noCompatibleEngineCount: Int
    public var missingSha256Count: Int
    public var missingLauncherAssetCount: Int
    public var obsoleteRenderingFlagRecipeCount: Int
    public var stateCounts: [String: Int]
    public var issueCounts: [String: Int]
    public var entries: [RecipeReadinessEntry]

    public init(rootPath: String, entries: [RecipeReadinessEntry]) {
        self.rootPath = rootPath
        self.recipeCount = entries.count
        self.readyCount = entries.filter { $0.state == .ready }.count
        self.actionRequiredCount = entries.filter { $0.state == .actionRequired }.count
        self.blockedCount = entries.filter { $0.state == .blocked }.count
        self.disabledCount = entries.filter { $0.state == .disabled }.count
        self.downloadRecipeCount = entries.filter { $0.installerMode == .download }.count
        self.localInstallerRecipeCount = entries.filter { $0.installerMode == .localFile }.count
        self.alreadyInstalledRecipeCount = entries.filter { $0.installerMode == .alreadyInstalled }.count
        self.requiresWin32Count = entries.filter(\.requiresWin32).count
        self.noCompatibleEngineCount = entries.filter { $0.issues.contains(.noCompatibleEngine) }.count
        self.missingSha256Count = entries.filter { $0.issues.contains(.missingSha256) }.count
        self.missingLauncherAssetCount = entries.filter { !$0.missingLauncherAssetPaths.isEmpty }.count
        self.obsoleteRenderingFlagRecipeCount = entries.filter { !$0.obsoleteRenderingFlags.isEmpty }.count
        self.stateCounts = Dictionary(grouping: entries, by: { $0.state.rawValue }).mapValues(\.count)
        self.issueCounts = Dictionary(grouping: entries.flatMap(\.issues), by: { $0.rawValue }).mapValues(\.count)
        self.entries = entries
    }
}

public struct RecipeReadinessService {
    public var paths: MacWinPaths
    public var fileManager: FileManager

    public init(paths: MacWinPaths = MacWinPaths(), fileManager: FileManager = .default) {
        self.paths = paths
        self.fileManager = fileManager
    }

    public func report(recipes: [RecipeManifest], engines: [EngineManifest]) -> RecipeReadinessReport {
        let entries = recipes
            .sorted { $0.id < $1.id }
            .map { readinessEntry(recipe: $0, engines: engines) }
        return RecipeReadinessReport(rootPath: paths.root.path, entries: entries)
    }

    private func readinessEntry(recipe: RecipeManifest, engines: [EngineManifest]) -> RecipeReadinessEntry {
        var issues: Set<RecipeReadinessIssue> = []
        if recipe.disabledReason != nil {
            issues.insert(.disabled)
        }
        if recipe.launchers.isEmpty {
            issues.insert(.missingLauncher)
        }

        let compatibleEngineIds = engines
            .filter { recipe.engineRequirements.isSatisfied(by: $0) }
            .map(\.id)
            .sorted()
        if compatibleEngineIds.isEmpty, !engines.isEmpty {
            issues.insert(.noCompatibleEngine)
        }

        let fileName = installerFileName(for: recipe)
        switch recipe.installer.mode {
        case .download:
            if recipe.installer.url?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
                issues.insert(.missingDownloadURL)
            }
            if fileName == nil {
                issues.insert(.missingDownloadFileName)
            }
            if recipe.installer.sha256?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
                issues.insert(.missingSha256)
            }
        case .localFile:
            if !cachedInstallerFound(fileName: fileName) {
                issues.insert(.localInstallerRequired)
            }
        case .alreadyInstalled:
            if !existingInstallFound(recipe: recipe) {
                issues.insert(.existingInstallMissing)
            }
        case .none:
            break
        }

        let missingLauncherAssets = missingLocalLauncherAssets(recipe: recipe)
        if !missingLauncherAssets.isEmpty {
            issues.insert(.missingLauncherAsset)
        }

        let obsoleteFlags = obsoleteRenderingFlags(in: recipe)
        if !obsoleteFlags.isEmpty {
            issues.insert(.obsoleteRenderingFlag)
        }

        let state: RecipeReadinessState
        if recipe.disabledReason != nil {
            state = .disabled
        } else if issues.contains(where: Self.blockingIssues.contains) {
            state = .blocked
        } else if issues.contains(where: Self.actionRequiredIssues.contains) {
            state = .actionRequired
        } else {
            state = .ready
        }

        return RecipeReadinessEntry(
            recipeId: recipe.id,
            recipeName: recipe.name,
            publisher: recipe.publisher,
            category: recipe.category,
            compatibilityRating: recipe.compatibilityRating,
            installerMode: recipe.installer.mode,
            state: state,
            issues: issues.sorted { $0.rawValue < $1.rawValue },
            warningCount: recipe.warnings.count,
            requiresWin32: recipe.engineRequirements.requiresWin32,
            compatibleEngineIds: compatibleEngineIds,
            launcherCount: recipe.launchers.count,
            missingLauncherAssetPaths: missingLauncherAssets,
            existingInstallHintPaths: recipe.installer.hints,
            existingInstallFound: existingInstallFound(recipe: recipe),
            downloadURL: recipe.installer.url,
            fileName: fileName,
            sha256Present: recipe.installer.sha256?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
            obsoleteRenderingFlags: obsoleteFlags
        )
    }

    private func installerFileName(for recipe: RecipeManifest) -> String? {
        if let fileName = recipe.installer.fileName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !fileName.isEmpty {
            return fileName
        }
        guard let urlString = recipe.installer.url,
              let url = URL(string: urlString),
              !url.lastPathComponent.isEmpty else {
            return nil
        }
        return url.lastPathComponent
    }

    private func cachedInstallerFound(fileName: String?) -> Bool {
        guard let fileName else { return false }
        return fileManager.fileExists(atPath: paths.downloadsDirectory.appendingPathComponent(fileName).path)
    }

    private func existingInstallFound(recipe: RecipeManifest) -> Bool {
        recipe.installer.hints.contains { fileManager.fileExists(atPath: $0) }
    }

    private func missingLocalLauncherAssets(recipe: RecipeManifest) -> [String] {
        recipe.launchers.compactMap { launcher in
            guard launcher.exePath.hasPrefix("/") else { return nil }
            return fileManager.fileExists(atPath: launcher.exePath) ? nil : launcher.exePath
        }
        .sorted()
    }

    private func obsoleteRenderingFlags(in recipe: RecipeManifest) -> [String] {
        var flags: Set<String> = []
        func scan(_ value: String) {
            for flag in ApplicationCompatibilityProfile.obsoleteTextRenderingFlags(in: value) {
                flags.insert(flag)
            }
        }

        for argument in recipe.installer.arguments {
            scan(argument)
        }
        for value in recipe.env.values {
            scan(value)
        }
        for launcher in recipe.launchers {
            for argument in launcher.args {
                scan(argument)
            }
            for value in launcher.envOverrides.values {
                scan(value)
            }
        }
        return flags.sorted()
    }

    private static let blockingIssues: Set<RecipeReadinessIssue> = [
        .missingDownloadURL,
        .missingDownloadFileName,
        .missingSha256,
        .missingLauncher,
        .missingLauncherAsset,
        .noCompatibleEngine
    ]

    private static let actionRequiredIssues: Set<RecipeReadinessIssue> = [
        .localInstallerRequired,
        .existingInstallMissing,
        .obsoleteRenderingFlag
    ]
}
