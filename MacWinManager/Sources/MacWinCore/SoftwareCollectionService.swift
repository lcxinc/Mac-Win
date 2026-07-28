import Foundation

public struct SoftwareCollectionDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var purpose: String
    public var requiredRecipeIds: [String]

    public init(id: String, name: String, purpose: String, requiredRecipeIds: [String]) {
        self.id = id
        self.name = name
        self.purpose = purpose
        self.requiredRecipeIds = requiredRecipeIds
    }
}

public struct SoftwareCollectionEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: String { recipeId }
    public var recipeId: String
    public var name: String
    public var publisher: String
    public var category: String
    public var collectionIds: [String]
    public var compatibilityRating: CompatibilityRating
    public var installerMode: InstallerMode
    public var installerFileName: String?
    public var installerSourceURL: String?
    public var expectedSha256: String?
    public var installerHashStatus: InstallerHashStatus?
    public var cachedInstallerPath: String?
    public var cachedInstallerExists: Bool
    public var softwareState: SoftwareTestPlanState?
    public var smokeStage: SoftwareSmokeStage?
    public var smokeSeverity: SoftwareSmokeCheckState?
    public var installedLauncherCount: Int
    public var latestLaunchState: WineLaunchState?
    public var latestLaunchLogPath: String?
    public var latestLogHealth: LogHealth?
    public var readinessIssues: [RecipeReadinessIssue]
    public var recommendedProbeIds: [String]

    public init(
        recipeId: String,
        name: String,
        publisher: String,
        category: String,
        collectionIds: [String],
        compatibilityRating: CompatibilityRating,
        installerMode: InstallerMode,
        installerFileName: String?,
        installerSourceURL: String?,
        expectedSha256: String?,
        installerHashStatus: InstallerHashStatus?,
        cachedInstallerPath: String?,
        cachedInstallerExists: Bool,
        softwareState: SoftwareTestPlanState?,
        smokeStage: SoftwareSmokeStage?,
        smokeSeverity: SoftwareSmokeCheckState?,
        installedLauncherCount: Int,
        latestLaunchState: WineLaunchState?,
        latestLaunchLogPath: String?,
        latestLogHealth: LogHealth?,
        readinessIssues: [RecipeReadinessIssue],
        recommendedProbeIds: [String]
    ) {
        self.recipeId = recipeId
        self.name = name
        self.publisher = publisher
        self.category = category
        self.collectionIds = collectionIds
        self.compatibilityRating = compatibilityRating
        self.installerMode = installerMode
        self.installerFileName = installerFileName
        self.installerSourceURL = installerSourceURL
        self.expectedSha256 = expectedSha256
        self.installerHashStatus = installerHashStatus
        self.cachedInstallerPath = cachedInstallerPath
        self.cachedInstallerExists = cachedInstallerExists
        self.softwareState = softwareState
        self.smokeStage = smokeStage
        self.smokeSeverity = smokeSeverity
        self.installedLauncherCount = installedLauncherCount
        self.latestLaunchState = latestLaunchState
        self.latestLaunchLogPath = latestLaunchLogPath
        self.latestLogHealth = latestLogHealth
        self.readinessIssues = readinessIssues
        self.recommendedProbeIds = recommendedProbeIds
    }
}

public struct SoftwareCollectionReport: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var rootPath: String
    public var collectionCount: Int
    public var recipeCount: Int
    public var missingRecipeCount: Int
    public var downloadableRecipeCount: Int
    public var cachedInstallerCount: Int
    public var missingInstallerCount: Int
    public var installedRecipeCount: Int
    public var verifiedRecipeCount: Int
    public var actionRequiredCount: Int
    public var collections: [SoftwareCollectionDefinition]
    public var missingRecipeIds: [String]
    public var entries: [SoftwareCollectionEntry]

    public init(
        generatedAt: Date,
        rootPath: String,
        collections: [SoftwareCollectionDefinition],
        missingRecipeIds: [String],
        entries: [SoftwareCollectionEntry]
    ) {
        self.generatedAt = generatedAt
        self.rootPath = rootPath
        self.collectionCount = collections.count
        self.recipeCount = entries.count
        self.missingRecipeCount = missingRecipeIds.count
        self.downloadableRecipeCount = entries.filter { $0.installerMode == .download }.count
        self.cachedInstallerCount = entries.filter(\.cachedInstallerExists).count
        self.missingInstallerCount = entries.filter { $0.installerMode == .download && !$0.cachedInstallerExists }.count
        self.installedRecipeCount = entries.filter { $0.installedLauncherCount > 0 }.count
        self.verifiedRecipeCount = entries.filter { $0.softwareState == .verified }.count
        self.actionRequiredCount = entries.filter { entry in
            entry.softwareState != .verified && entry.softwareState != .disabled
        }.count + missingRecipeIds.count
        self.collections = collections
        self.missingRecipeIds = missingRecipeIds
        self.entries = entries
    }
}

public struct SoftwareCollectionLockfileItem: Codable, Equatable, Identifiable, Sendable {
    public var id: String { recipeId }
    public var recipeId: String
    public var name: String
    public var publisher: String
    public var category: String
    public var collectionIds: [String]
    public var installerMode: InstallerMode
    public var installerFileName: String?
    public var installerSourceURL: String?
    public var expectedSha256: String?
    public var hashProtected: Bool
    public var installerHashStatus: InstallerHashStatus?
    public var cachedInstallerPath: String?
    public var cachedInstallerExists: Bool
    public var softwareState: SoftwareTestPlanState?
    public var smokeStage: SoftwareSmokeStage?
    public var installedLauncherCount: Int
    public var recommendedProbeIds: [String]

    public init(entry: SoftwareCollectionEntry) {
        self.recipeId = entry.recipeId
        self.name = entry.name
        self.publisher = entry.publisher
        self.category = entry.category
        self.collectionIds = entry.collectionIds
        self.installerMode = entry.installerMode
        self.installerFileName = entry.installerFileName
        self.installerSourceURL = entry.installerSourceURL
        self.expectedSha256 = entry.expectedSha256
        self.hashProtected = entry.expectedSha256?.isEmpty == false
        self.installerHashStatus = entry.installerHashStatus
        self.cachedInstallerPath = entry.cachedInstallerPath
        self.cachedInstallerExists = entry.cachedInstallerExists
        self.softwareState = entry.softwareState
        self.smokeStage = entry.smokeStage
        self.installedLauncherCount = entry.installedLauncherCount
        self.recommendedProbeIds = entry.recommendedProbeIds
    }
}

public struct SoftwareCollectionLockfile: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var rootPath: String
    public var downloadsPath: String
    public var collectionCount: Int
    public var recipeCount: Int
    public var downloadableRecipeCount: Int
    public var cachedInstallerCount: Int
    public var missingInstallerCount: Int
    public var hashProtectedCount: Int
    public var hashMismatchCount: Int
    public var unprotectedDownloadCount: Int
    public var missingRecipeIds: [String]
    public var items: [SoftwareCollectionLockfileItem]

    public init(report: SoftwareCollectionReport) {
        self.generatedAt = report.generatedAt
        self.rootPath = report.rootPath
        self.downloadsPath = URL(fileURLWithPath: report.rootPath).appendingPathComponent("Downloads", isDirectory: true).path
        self.collectionCount = report.collectionCount
        self.recipeCount = report.recipeCount
        self.downloadableRecipeCount = report.downloadableRecipeCount
        self.cachedInstallerCount = report.cachedInstallerCount
        self.missingInstallerCount = report.missingInstallerCount
        self.hashProtectedCount = report.entries.filter { $0.expectedSha256?.isEmpty == false }.count
        self.hashMismatchCount = report.entries.filter { $0.installerHashStatus == .mismatch }.count
        self.unprotectedDownloadCount = report.entries.filter {
            $0.installerMode == .download && ($0.expectedSha256?.isEmpty != false)
        }.count
        self.missingRecipeIds = report.missingRecipeIds
        self.items = report.entries.map(SoftwareCollectionLockfileItem.init(entry:))
    }

    public static func csv(lockfile: SoftwareCollectionLockfile) -> String {
        var rows: [[String]] = [[
            "recipe_id",
            "name",
            "publisher",
            "category",
            "collections",
            "installer_mode",
            "installer_file_name",
            "installer_source_url",
            "expected_sha256",
            "hash_protected",
            "installer_hash_status",
            "cached_installer_exists",
            "cached_installer_path",
            "software_state",
            "smoke_stage",
            "installed_launcher_count",
            "recommended_probe_ids"
        ]]
        for item in lockfile.items {
            rows.append([
                item.recipeId,
                item.name,
                item.publisher,
                item.category,
                item.collectionIds.joined(separator: ";"),
                item.installerMode.rawValue,
                item.installerFileName ?? "",
                item.installerSourceURL ?? "",
                item.expectedSha256 ?? "",
                item.hashProtected ? "true" : "false",
                item.installerHashStatus?.rawValue ?? "",
                item.cachedInstallerExists ? "true" : "false",
                item.cachedInstallerPath ?? "",
                item.softwareState?.rawValue ?? "",
                item.smokeStage?.rawValue ?? "",
                String(item.installedLauncherCount),
                item.recommendedProbeIds.joined(separator: ";")
            ])
        }
        for recipeId in lockfile.missingRecipeIds {
            rows.append([
                recipeId,
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "missingRecipe",
                "false",
                "",
                "missingRecipe",
                "",
                "0",
                ""
            ])
        }
        return rows.map { $0.map(csvEscaped).joined(separator: ",") }.joined(separator: "\n") + "\n"
    }

    public static func markdown(lockfile: SoftwareCollectionLockfile) -> String {
        let formatter = ISO8601DateFormatter()
        var lines = [
            "# MacWin Software Collection Lockfile",
            "",
            "- Generated: \(formatter.string(from: lockfile.generatedAt))",
            "- Root: `\(markdownEscaped(lockfile.rootPath))`",
            "- Downloads: `\(markdownEscaped(lockfile.downloadsPath))`",
            "- Collections: \(lockfile.collectionCount)",
            "- Recipes: \(lockfile.recipeCount)",
            "- Downloadable recipes: \(lockfile.downloadableRecipeCount)",
            "- Cached installers: \(lockfile.cachedInstallerCount)",
            "- Missing installers: \(lockfile.missingInstallerCount)",
            "- Hash protected: \(lockfile.hashProtectedCount)",
            "- Hash mismatches: \(lockfile.hashMismatchCount)",
            "- Unprotected downloads: \(lockfile.unprotectedDownloadCount)",
            "",
            "## Items",
            ""
        ]
        if lockfile.items.isEmpty {
            lines.append("No software collection recipes are present.")
        } else {
            for item in lockfile.items {
                lines.append("### \(markdownEscaped(item.name))")
                lines.append("")
                lines.append("- Recipe: `\(markdownEscaped(item.recipeId))`")
                lines.append("- Collections: \(item.collectionIds.map { "`\(markdownEscaped($0))`" }.joined(separator: ", "))")
                lines.append("- Installer: `\(item.installerMode.rawValue)`")
                if let fileName = item.installerFileName {
                    lines.append("- File: `\(markdownEscaped(fileName))`")
                }
                if let sourceURL = item.installerSourceURL {
                    lines.append("- Source: `\(markdownEscaped(sourceURL))`")
                }
                if let expectedSha256 = item.expectedSha256 {
                    lines.append("- SHA-256: `\(expectedSha256)`")
                }
                lines.append("- Cached: \(item.cachedInstallerExists ? "true" : "false")")
                if let status = item.installerHashStatus {
                    lines.append("- Hash status: `\(status.rawValue)`")
                }
                if !item.recommendedProbeIds.isEmpty {
                    lines.append("- Recommended probes: \(item.recommendedProbeIds.map { "`\(markdownEscaped($0))`" }.joined(separator: ", "))")
                }
                lines.append("")
            }
        }

        if !lockfile.missingRecipeIds.isEmpty {
            lines.append("")
            lines.append("## Missing Recipes")
            lines.append("")
            for recipeId in lockfile.missingRecipeIds {
                lines.append("- `\(markdownEscaped(recipeId))`")
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
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
    }
}

public struct SoftwareCollectionService {
    public var paths: MacWinPaths
    public var collections: [SoftwareCollectionDefinition]

    public init(
        paths: MacWinPaths = MacWinPaths(),
        collections: [SoftwareCollectionDefinition] = SoftwareCollectionService.defaultCollections
    ) {
        self.paths = paths
        self.collections = collections
    }

    public func report(
        recipes: [RecipeManifest],
        readiness: RecipeReadinessReport,
        installerAssets: InstallerAssetReport,
        softwareTestPlan: SoftwareTestPlanReport,
        softwareSmokeMatrix: SoftwareSmokeMatrixReport,
        adaptationQueue: SoftwareAdaptationQueueReport,
        generatedAt: Date = Date()
    ) -> SoftwareCollectionReport {
        Self.report(
            rootPath: paths.root.path,
            collections: collections,
            recipes: recipes,
            readiness: readiness,
            installerAssets: installerAssets,
            softwareTestPlan: softwareTestPlan,
            softwareSmokeMatrix: softwareSmokeMatrix,
            adaptationQueue: adaptationQueue,
            generatedAt: generatedAt
        )
    }

    public static func report(
        rootPath: String,
        collections: [SoftwareCollectionDefinition] = defaultCollections,
        recipes: [RecipeManifest],
        readiness: RecipeReadinessReport,
        installerAssets: InstallerAssetReport,
        softwareTestPlan: SoftwareTestPlanReport,
        softwareSmokeMatrix: SoftwareSmokeMatrixReport,
        adaptationQueue: SoftwareAdaptationQueueReport,
        generatedAt: Date = Date()
    ) -> SoftwareCollectionReport {
        let recipeIds = orderedUnique(collections.flatMap(\.requiredRecipeIds))
        let collectionIdsByRecipe = Dictionary(grouping: collections.flatMap { collection in
            collection.requiredRecipeIds.map { (recipeId: $0, collectionId: collection.id) }
        }, by: \.recipeId).mapValues { $0.map(\.collectionId).sorted() }
        let recipesById = Dictionary(uniqueKeysWithValues: recipes.map { ($0.id, $0) })
        let readinessById = Dictionary(uniqueKeysWithValues: readiness.entries.map { ($0.recipeId, $0) })
        let installerById = Dictionary(uniqueKeysWithValues: installerAssets.recipes.map { ($0.recipeId, $0) })
        let planById = Dictionary(uniqueKeysWithValues: softwareTestPlan.entries.map { ($0.recipeId, $0) })
        let smokeById = Dictionary(uniqueKeysWithValues: softwareSmokeMatrix.rows.map { ($0.recipeId, $0) })
        let adaptationById = Dictionary(uniqueKeysWithValues: adaptationQueue.tasks.map { ($0.recipeId, $0) })

        var missingRecipeIds: [String] = []
        var entries: [SoftwareCollectionEntry] = []
        for recipeId in recipeIds {
            guard let recipe = recipesById[recipeId] else {
                missingRecipeIds.append(recipeId)
                continue
            }
            let installer = installerById[recipe.id]
            let plan = planById[recipe.id]
            let smoke = smokeById[recipe.id]
            let readinessEntry = readinessById[recipe.id]
            let adaptation = adaptationById[recipe.id]
            entries.append(SoftwareCollectionEntry(
                recipeId: recipe.id,
                name: recipe.name,
                publisher: recipe.publisher,
                category: recipe.category,
                collectionIds: collectionIdsByRecipe[recipe.id] ?? [],
                compatibilityRating: recipe.compatibilityRating,
                installerMode: recipe.installer.mode,
                installerFileName: installer?.fileName ?? recipe.installer.fileName,
                installerSourceURL: installer?.sourceURL ?? recipe.installer.url,
                expectedSha256: installer?.expectedSha256 ?? recipe.installer.sha256,
                installerHashStatus: installer?.hashStatus,
                cachedInstallerPath: installer?.cachedPath,
                cachedInstallerExists: installer?.cachedExists == true,
                softwareState: plan?.state,
                smokeStage: smoke?.stage,
                smokeSeverity: smoke?.highestSeverity,
                installedLauncherCount: plan?.installedLauncherCount ?? 0,
                latestLaunchState: plan?.latestLaunchState,
                latestLaunchLogPath: plan?.latestLaunchLogPath,
                latestLogHealth: plan?.latestLogHealth,
                readinessIssues: readinessEntry?.issues ?? [],
                recommendedProbeIds: adaptation?.recommendedProbeIds ?? []
            ))
        }

        return SoftwareCollectionReport(
            generatedAt: generatedAt,
            rootPath: rootPath,
            collections: collections,
            missingRecipeIds: missingRecipeIds.sorted(),
            entries: entries.sorted { $0.recipeId < $1.recipeId }
        )
    }

    public static func csv(report: SoftwareCollectionReport) -> String {
        var rows: [[String]] = [[
            "recipe_id",
            "name",
            "publisher",
            "category",
            "collections",
            "compatibility_rating",
            "installer_mode",
            "installer_file_name",
            "expected_sha256",
            "installer_hash_status",
            "cached_installer_exists",
            "software_state",
            "smoke_stage",
            "smoke_severity",
            "installed_launcher_count",
            "latest_log_health",
            "readiness_issues",
            "recommended_probe_ids",
            "installer_source_url",
            "cached_installer_path"
        ]]
        for entry in report.entries {
            rows.append([
                entry.recipeId,
                entry.name,
                entry.publisher,
                entry.category,
                entry.collectionIds.joined(separator: ";"),
                entry.compatibilityRating.rawValue,
                entry.installerMode.rawValue,
                entry.installerFileName ?? "",
                entry.expectedSha256 ?? "",
                entry.installerHashStatus?.rawValue ?? "",
                entry.cachedInstallerExists ? "true" : "false",
                entry.softwareState?.rawValue ?? "",
                entry.smokeStage?.rawValue ?? "",
                entry.smokeSeverity?.rawValue ?? "",
                String(entry.installedLauncherCount),
                entry.latestLogHealth?.rawValue ?? "",
                entry.readinessIssues.map(\.rawValue).joined(separator: ";"),
                entry.recommendedProbeIds.joined(separator: ";"),
                entry.installerSourceURL ?? "",
                entry.cachedInstallerPath ?? ""
            ])
        }
        for recipeId in report.missingRecipeIds {
            rows.append([
                recipeId,
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "missingRecipe",
                "",
                "blocked",
                "0",
                "",
                "missingCatalogRecipe",
                "",
                "",
                ""
            ])
        }
        return rows.map { $0.map(csvEscaped).joined(separator: ",") }.joined(separator: "\n") + "\n"
    }

    public static func downloadScript(report: SoftwareCollectionReport) -> String {
        let downloadable = report.entries
            .filter { entry in
                entry.installerMode == .download
                    && entry.cachedInstallerExists == false
                    && entry.installerSourceURL?.isEmpty == false
                    && entry.installerFileName?.isEmpty == false
            }
            .sorted { $0.recipeId < $1.recipeId }

        var lines = [
            "#!/usr/bin/env bash",
            "set -euo pipefail",
            "",
            "DOWNLOADS_DIR=\(shellQuoted(URL(fileURLWithPath: report.rootPath).appendingPathComponent("Downloads", isDirectory: true).path))",
            "mkdir -p \"$DOWNLOADS_DIR\"",
            "",
            "download_one() {",
            "  local recipe_id=\"$1\"",
            "  local url=\"$2\"",
            "  local file_name=\"$3\"",
            "  local expected_sha=\"$4\"",
            "  local dest=\"$DOWNLOADS_DIR/$file_name\"",
            "  if [[ -f \"$dest\" ]]; then",
            "    echo \"READY $recipe_id: $dest\"",
            "    return 0",
            "  fi",
            "  echo \"DOWNLOAD $recipe_id: $url\"",
            "  curl -L --fail --output \"$dest.tmp\" \"$url\"",
            "  if [[ -n \"$expected_sha\" ]]; then",
            "    echo \"$expected_sha  $dest.tmp\" | shasum -a 256 -c -",
            "  fi",
            "  mv \"$dest.tmp\" \"$dest\"",
            "}",
            ""
        ]

        if downloadable.isEmpty {
            lines.append("echo 'No missing downloadable installers in the current software collection.'")
        } else {
            for entry in downloadable {
                lines.append("download_one \(shellQuoted(entry.recipeId)) \(shellQuoted(entry.installerSourceURL ?? "")) \(shellQuoted(entry.installerFileName ?? "")) \(shellQuoted(expectedHash(entry)))")
            }
        }
        lines.append("")
        return lines.joined(separator: "\n")
    }

    public static func lockfile(report: SoftwareCollectionReport) -> SoftwareCollectionLockfile {
        SoftwareCollectionLockfile(report: report)
    }

    private static func expectedHash(_ entry: SoftwareCollectionEntry) -> String {
        guard entry.installerHashStatus != .notExpected else { return "" }
        return entry.expectedSha256 ?? ""
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

    public static let defaultCollections: [SoftwareCollectionDefinition] = [
        SoftwareCollectionDefinition(
            id: "baseline-utilities",
            name: "Baseline Utilities",
            purpose: "Small installers for file dialogs, shell integration, menus, and ordinary Win32 windows.",
            requiredRecipeIds: ["7zip", "notepad-plus-plus", "sumatrapdf"]
        ),
        SoftwareCollectionDefinition(
            id: "launcher-webview",
            name: "Launcher and WebView Apps",
            purpose: "CEF, Chromium, Qt WebEngine, login, focus, and text rendering coverage.",
            requiredRecipeIds: ["hoyoplay-cn", "steam"]
        ),
        SoftwareCollectionDefinition(
            id: "media-graphics",
            name: "Media and Graphics",
            purpose: "GStreamer, GPU compositing, Vulkan, D3D, and media playback smoke coverage.",
            requiredRecipeIds: ["vlc", "macwin-game-tests"]
        ),
        SoftwareCollectionDefinition(
            id: "diagnostics",
            name: "MacWin Diagnostics",
            purpose: "Built-in probes and core capability suites for regression checks.",
            requiredRecipeIds: ["macwin-core-capability-tests", "macwin-probes"]
        )
    ]
}
