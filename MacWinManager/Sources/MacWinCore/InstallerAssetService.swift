import Foundation

public enum InstallerHashStatus: String, Codable, Equatable, Sendable {
    case notApplicable
    case missing
    case notExpected
    case match
    case mismatch
}

public struct RecipeInstallerAssetStatus: Codable, Equatable, Identifiable, Sendable {
    public var id: String { recipeId }
    public var recipeId: String
    public var recipeName: String
    public var publisher: String
    public var category: String
    public var compatibilityRating: CompatibilityRating
    public var disabled: Bool
    public var disabledReason: String?
    public var installerMode: InstallerMode
    public var fileName: String?
    public var sourceURL: String?
    public var expectedSha256: String?
    public var cachedPath: String?
    public var cachedExists: Bool
    public var byteCount: Int64?
    public var modifiedAt: Date?
    public var actualSha256: String?
    public var hashStatus: InstallerHashStatus
    public var architecture: WindowsExecutableArchitecture?
    public var requiresWin32Installer: Bool

    public init(
        recipeId: String,
        recipeName: String,
        publisher: String,
        category: String,
        compatibilityRating: CompatibilityRating,
        disabled: Bool,
        disabledReason: String?,
        installerMode: InstallerMode,
        fileName: String?,
        sourceURL: String?,
        expectedSha256: String?,
        cachedPath: String?,
        cachedExists: Bool,
        byteCount: Int64? = nil,
        modifiedAt: Date? = nil,
        actualSha256: String? = nil,
        hashStatus: InstallerHashStatus,
        architecture: WindowsExecutableArchitecture? = nil,
        requiresWin32Installer: Bool = false
    ) {
        self.recipeId = recipeId
        self.recipeName = recipeName
        self.publisher = publisher
        self.category = category
        self.compatibilityRating = compatibilityRating
        self.disabled = disabled
        self.disabledReason = disabledReason
        self.installerMode = installerMode
        self.fileName = fileName
        self.sourceURL = sourceURL
        self.expectedSha256 = expectedSha256
        self.cachedPath = cachedPath
        self.cachedExists = cachedExists
        self.byteCount = byteCount
        self.modifiedAt = modifiedAt
        self.actualSha256 = actualSha256
        self.hashStatus = hashStatus
        self.architecture = architecture
        self.requiresWin32Installer = requiresWin32Installer
    }
}

public struct DownloadCacheFileStatus: Codable, Equatable, Identifiable, Sendable {
    public var id: String { path }
    public var name: String
    public var path: String
    public var byteCount: Int64
    public var modifiedAt: Date
    public var pathExtension: String
    public var sha256: String?
    public var architecture: WindowsExecutableArchitecture?
    public var matchedRecipeIds: [String]

    public init(
        name: String,
        path: String,
        byteCount: Int64,
        modifiedAt: Date,
        pathExtension: String,
        sha256: String? = nil,
        architecture: WindowsExecutableArchitecture? = nil,
        matchedRecipeIds: [String] = []
    ) {
        self.name = name
        self.path = path
        self.byteCount = byteCount
        self.modifiedAt = modifiedAt
        self.pathExtension = pathExtension
        self.sha256 = sha256
        self.architecture = architecture
        self.matchedRecipeIds = matchedRecipeIds
    }
}

public struct InstallerAssetReport: Codable, Equatable, Sendable {
    public var rootPath: String
    public var downloadsPath: String
    public var recipeCount: Int
    public var downloadableRecipeCount: Int
    public var cachedRecipeCount: Int
    public var missingDownloadCount: Int
    public var hashMatchCount: Int
    public var hashMismatchCount: Int
    public var win32InstallerCount: Int
    public var orphanedFileCount: Int
    public var recipes: [RecipeInstallerAssetStatus]
    public var orphanedDownloads: [DownloadCacheFileStatus]

    public init(
        rootPath: String,
        downloadsPath: String,
        recipes: [RecipeInstallerAssetStatus],
        orphanedDownloads: [DownloadCacheFileStatus]
    ) {
        self.rootPath = rootPath
        self.downloadsPath = downloadsPath
        self.recipeCount = recipes.count
        self.downloadableRecipeCount = recipes.filter { $0.installerMode == .download }.count
        self.cachedRecipeCount = recipes.filter(\.cachedExists).count
        self.missingDownloadCount = recipes.filter { $0.installerMode == .download && !$0.cachedExists }.count
        self.hashMatchCount = recipes.filter { $0.hashStatus == .match }.count
        self.hashMismatchCount = recipes.filter { $0.hashStatus == .mismatch }.count
        self.win32InstallerCount = recipes.filter(\.requiresWin32Installer).count
        self.orphanedFileCount = orphanedDownloads.count
        self.recipes = recipes
        self.orphanedDownloads = orphanedDownloads
    }
}

public enum InstallerPreparationSeverity: String, Codable, Equatable, Sendable {
    case critical
    case warning
    case info
}

public enum InstallerPreparationActionKind: String, Codable, Equatable, Sendable {
    case redownloadHashMismatch
    case downloadMissing
    case addExpectedHash
    case useWoW64Engine
    case reviewOrphanedDownload
}

public struct InstallerPreparationAction: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var severity: InstallerPreparationSeverity
    public var kind: InstallerPreparationActionKind
    public var recipeId: String?
    public var recipeName: String?
    public var fileName: String
    public var detail: String
    public var sourceURL: String?
    public var cachedPath: String?

    public init(
        id: String,
        severity: InstallerPreparationSeverity,
        kind: InstallerPreparationActionKind,
        recipeId: String? = nil,
        recipeName: String? = nil,
        fileName: String,
        detail: String,
        sourceURL: String? = nil,
        cachedPath: String? = nil
    ) {
        self.id = id
        self.severity = severity
        self.kind = kind
        self.recipeId = recipeId
        self.recipeName = recipeName
        self.fileName = fileName
        self.detail = detail
        self.sourceURL = sourceURL
        self.cachedPath = cachedPath
    }
}

public struct InstallerPreparationReport: Codable, Equatable, Sendable {
    public var rootPath: String
    public var downloadsPath: String
    public var actionCount: Int
    public var criticalCount: Int
    public var warningCount: Int
    public var infoCount: Int
    public var missingDownloadCount: Int
    public var hashMismatchCount: Int
    public var missingExpectedHashCount: Int
    public var win32InstallerCount: Int
    public var orphanedDownloadCount: Int
    public var actions: [InstallerPreparationAction]

    public init(rootPath: String, downloadsPath: String, actions: [InstallerPreparationAction]) {
        self.rootPath = rootPath
        self.downloadsPath = downloadsPath
        self.actionCount = actions.count
        self.criticalCount = actions.filter { $0.severity == .critical }.count
        self.warningCount = actions.filter { $0.severity == .warning }.count
        self.infoCount = actions.filter { $0.severity == .info }.count
        self.missingDownloadCount = actions.filter { $0.kind == .downloadMissing }.count
        self.hashMismatchCount = actions.filter { $0.kind == .redownloadHashMismatch }.count
        self.missingExpectedHashCount = actions.filter { $0.kind == .addExpectedHash }.count
        self.win32InstallerCount = actions.filter { $0.kind == .useWoW64Engine }.count
        self.orphanedDownloadCount = actions.filter { $0.kind == .reviewOrphanedDownload }.count
        self.actions = actions
    }
}

public struct InstallerDownloadResult: Codable, Equatable, Sendable {
    public var recipeId: String
    public var fileName: String
    public var sourceURL: String
    public var destinationPath: String
    public var byteCount: Int64
    public var actualSha256: String
    public var hashStatus: InstallerHashStatus
    public var usedCachedFile: Bool

    public init(
        recipeId: String,
        fileName: String,
        sourceURL: String,
        destinationPath: String,
        byteCount: Int64,
        actualSha256: String,
        hashStatus: InstallerHashStatus,
        usedCachedFile: Bool
    ) {
        self.recipeId = recipeId
        self.fileName = fileName
        self.sourceURL = sourceURL
        self.destinationPath = destinationPath
        self.byteCount = byteCount
        self.actualSha256 = actualSha256
        self.hashStatus = hashStatus
        self.usedCachedFile = usedCachedFile
    }

    public var destinationURL: URL {
        URL(fileURLWithPath: destinationPath)
    }
}

public struct InstallerAssetService {
    public var paths: MacWinPaths
    public var fileManager: FileManager

    public init(paths: MacWinPaths = MacWinPaths(), fileManager: FileManager = .default) {
        self.paths = paths
        self.fileManager = fileManager
    }

    public func report(
        recipes: [RecipeManifest],
        includeHashes: Bool = false,
        orphanLimit: Int = 100
    ) -> InstallerAssetReport {
        let topLevelFiles = downloadCacheFiles(includeHashes: includeHashes)
        let recipeStatuses = recipes
            .sorted { $0.id < $1.id }
            .map { recipeStatus(recipe: $0, includeHashes: includeHashes) }
        let referencedNames = Set(recipeStatuses.compactMap { status in
            status.fileName?.lowercased()
        })
        let recipeIdsByFileName = Dictionary(grouping: recipeStatuses.compactMap { status -> (String, String)? in
            guard let fileName = status.fileName?.lowercased() else { return nil }
            return (fileName, status.recipeId)
        }, by: { $0.0 }).mapValues { $0.map(\.1).sorted() }
        let orphaned = topLevelFiles
            .filter { !referencedNames.contains($0.name.lowercased()) }
            .prefix(orphanLimit)
            .map { file -> DownloadCacheFileStatus in
                var updated = file
                updated.matchedRecipeIds = recipeIdsByFileName[file.name.lowercased()] ?? []
                return updated
            }

        return InstallerAssetReport(
            rootPath: paths.root.path,
            downloadsPath: paths.downloadsDirectory.path,
            recipes: recipeStatuses,
            orphanedDownloads: Array(orphaned)
        )
    }

    public static func shellScript(for report: InstallerAssetReport) -> String {
        var lines = [
            "#!/usr/bin/env bash",
            "set -euo pipefail",
            "",
            "DOWNLOADS_DIR=\(shellQuoted(report.downloadsPath))",
            "mkdir -p \"$DOWNLOADS_DIR\"",
            ""
        ]

        let downloadable = report.recipes
            .filter { $0.installerMode == .download }
            .sorted { $0.recipeId < $1.recipeId }
        if downloadable.isEmpty {
            lines.append("echo 'No downloadable installer recipes in this report.'")
            lines.append("")
            return lines.joined(separator: "\n")
        }

        for status in downloadable {
            lines.append("echo \(shellQuoted("== \(status.recipeName) (\(status.recipeId)) =="))")
            guard let url = status.sourceURL,
                  let cachedPath = status.cachedPath else {
                lines.append("echo \(shellQuoted("SKIP \(status.recipeId): missing URL or destination filename"))")
                lines.append("")
                continue
            }

            let shouldDownload = !status.cachedExists || status.hashStatus == .mismatch
            if shouldDownload {
                lines.append("curl -L --fail --retry 3 --output \(shellQuoted(cachedPath)) \(shellQuoted(url))")
            } else {
                lines.append("echo \(shellQuoted("READY \(status.fileName ?? status.recipeId): cached file present"))")
            }

            if let expected = status.expectedSha256 {
                lines.append("printf '%s  %s\\n' \(shellQuoted(expected)) \(shellQuoted(cachedPath)) | shasum -a 256 -c -")
            } else {
                lines.append("echo \(shellQuoted("WARN \(status.recipeId): no expected SHA-256 in recipe"))")
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func csv(report: InstallerAssetReport) -> String {
        let formatter = ISO8601DateFormatter()
        var rows: [[String]] = [[
            "record_type",
            "recipe_id",
            "recipe_name",
            "publisher",
            "category",
            "compatibility_rating",
            "disabled",
            "disabled_reason",
            "installer_mode",
            "file_name",
            "cache_state",
            "hash_status",
            "requires_win32_installer",
            "architecture",
            "byte_count",
            "modified_at",
            "expected_sha256",
            "actual_sha256",
            "source_url",
            "cached_path",
            "orphaned_matched_recipe_ids"
        ]]

        for status in report.recipes.sorted(by: { $0.recipeId < $1.recipeId }) {
            rows.append([
                "recipe",
                status.recipeId,
                status.recipeName,
                status.publisher,
                status.category,
                status.compatibilityRating.rawValue,
                status.disabled ? "true" : "false",
                status.disabledReason ?? "",
                status.installerMode.rawValue,
                status.fileName ?? "",
                cacheState(for: status),
                status.hashStatus.rawValue,
                status.requiresWin32Installer ? "true" : "false",
                status.architecture?.rawValue ?? "",
                status.byteCount.map(String.init) ?? "",
                status.modifiedAt.map { formatter.string(from: $0) } ?? "",
                status.expectedSha256 ?? "",
                status.actualSha256 ?? "",
                status.sourceURL ?? "",
                status.cachedPath ?? "",
                ""
            ])
        }

        for file in report.orphanedDownloads.sorted(by: { lhs, rhs in
            if lhs.modifiedAt != rhs.modifiedAt {
                return lhs.modifiedAt > rhs.modifiedAt
            }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }) {
            rows.append([
                "orphaned_download",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                file.name,
                "orphaned",
                file.sha256 == nil ? "notExpected" : "notApplicable",
                file.architecture?.is32Bit == true ? "true" : "false",
                file.architecture?.rawValue ?? "",
                String(file.byteCount),
                formatter.string(from: file.modifiedAt),
                "",
                file.sha256 ?? "",
                "",
                file.path,
                file.matchedRecipeIds.joined(separator: ";")
            ])
        }

        return rows
            .map { $0.map(csvEscaped).joined(separator: ",") }
            .joined(separator: "\n")
    }

    public static func preparationReport(for report: InstallerAssetReport) -> InstallerPreparationReport {
        var actions: [InstallerPreparationAction] = []

        for status in report.recipes where status.installerMode == .download {
            let label = status.fileName ?? status.recipeName
            switch status.hashStatus {
            case .mismatch:
                actions.append(InstallerPreparationAction(
                    id: "hash-mismatch:\(status.recipeId)",
                    severity: .critical,
                    kind: .redownloadHashMismatch,
                    recipeId: status.recipeId,
                    recipeName: status.recipeName,
                    fileName: label,
                    detail: "Cached installer hash does not match the signed recipe. Redownload before installing.",
                    sourceURL: status.sourceURL,
                    cachedPath: status.cachedPath
                ))
            case .missing:
                actions.append(InstallerPreparationAction(
                    id: "missing-download:\(status.recipeId)",
                    severity: .warning,
                    kind: .downloadMissing,
                    recipeId: status.recipeId,
                    recipeName: status.recipeName,
                    fileName: label,
                    detail: "Installer is not cached yet. Download and verify it before running this recipe.",
                    sourceURL: status.sourceURL,
                    cachedPath: status.cachedPath
                ))
            case .notExpected:
                actions.append(InstallerPreparationAction(
                    id: "missing-expected-hash:\(status.recipeId)",
                    severity: .warning,
                    kind: .addExpectedHash,
                    recipeId: status.recipeId,
                    recipeName: status.recipeName,
                    fileName: label,
                    detail: "Recipe downloads an installer without an expected SHA-256. Add a trusted hash before promoting it.",
                    sourceURL: status.sourceURL,
                    cachedPath: status.cachedPath
                ))
            case .match, .notApplicable:
                break
            }

            if status.requiresWin32Installer {
                actions.append(InstallerPreparationAction(
                    id: "requires-wow64:\(status.recipeId)",
                    severity: .info,
                    kind: .useWoW64Engine,
                    recipeId: status.recipeId,
                    recipeName: status.recipeName,
                    fileName: label,
                    detail: "Installer is 32-bit. Use a WoW64-capable engine or run it in a WoW64 bottle.",
                    sourceURL: status.sourceURL,
                    cachedPath: status.cachedPath
                ))
            }
        }

        for file in report.orphanedDownloads {
            actions.append(InstallerPreparationAction(
                id: "orphaned-download:\(file.path)",
                severity: file.architecture?.is32Bit == true ? .warning : .info,
                kind: .reviewOrphanedDownload,
                fileName: file.name,
                detail: file.architecture?.is32Bit == true
                    ? "Cached installer is not referenced by a recipe and appears to be 32-bit. Import it manually with a WoW64-capable engine or remove it from the cache."
                    : "Cached installer is not referenced by any recipe. Import it manually or remove it from the cache.",
                cachedPath: file.path
            ))
        }

        actions.sort { lhs, rhs in
            let lhsRank = severityRank(lhs.severity)
            let rhsRank = severityRank(rhs.severity)
            if lhsRank != rhsRank {
                return lhsRank < rhsRank
            }
            if lhs.kind.rawValue != rhs.kind.rawValue {
                return lhs.kind.rawValue < rhs.kind.rawValue
            }
            return lhs.fileName.localizedStandardCompare(rhs.fileName) == .orderedAscending
        }

        return InstallerPreparationReport(
            rootPath: report.rootPath,
            downloadsPath: report.downloadsPath,
            actions: actions
        )
    }

    public static func preparationCSV(report: InstallerPreparationReport) -> String {
        var rows: [[String]] = [[
            "severity",
            "kind",
            "recipe_id",
            "recipe_name",
            "file_name",
            "detail",
            "source_url",
            "cached_path"
        ]]

        for action in report.actions {
            rows.append([
                action.severity.rawValue,
                action.kind.rawValue,
                action.recipeId ?? "",
                action.recipeName ?? "",
                action.fileName,
                action.detail,
                action.sourceURL ?? "",
                action.cachedPath ?? ""
            ])
        }

        return rows
            .map { $0.map(csvEscaped).joined(separator: ",") }
            .joined(separator: "\n")
    }

    public static func preparationMarkdown(report: InstallerPreparationReport) -> String {
        var lines = [
            "# MacWin Installer Preparation",
            "",
            "- Root: `\(markdownEscaped(report.rootPath))`",
            "- Downloads: `\(markdownEscaped(report.downloadsPath))`",
            "- Actions: \(report.actionCount)",
            "- Critical: \(report.criticalCount)",
            "- Warnings: \(report.warningCount)",
            "- Info: \(report.infoCount)",
            "- Missing downloads: \(report.missingDownloadCount)",
            "- Hash mismatches: \(report.hashMismatchCount)",
            "- 32-bit installers: \(report.win32InstallerCount)",
            "- Orphaned downloads: \(report.orphanedDownloadCount)",
            "",
            "## Actions",
            ""
        ]

        if report.actions.isEmpty {
            lines.append("No installer preparation actions are required.")
        } else {
            for action in report.actions {
                lines.append("### \(markdownEscaped(action.fileName))")
                lines.append("")
                lines.append("- Severity: `\(action.severity.rawValue)`")
                lines.append("- Kind: `\(action.kind.rawValue)`")
                if let recipeId = action.recipeId {
                    lines.append("- Recipe: `\(markdownEscaped(recipeId))`")
                }
                if let recipeName = action.recipeName {
                    lines.append("- Recipe name: \(markdownEscaped(recipeName))")
                }
                lines.append("- Detail: \(markdownEscaped(action.detail))")
                if let sourceURL = action.sourceURL {
                    lines.append("- Source: `\(markdownEscaped(sourceURL))`")
                }
                if let cachedPath = action.cachedPath {
                    lines.append("- Cache: `\(markdownEscaped(cachedPath))`")
                }
                lines.append("")
            }
        }

        return lines.joined(separator: "\n")
    }

    @discardableResult
    public func cacheInstaller(for recipe: RecipeManifest) throws -> InstallerDownloadResult {
        guard recipe.installer.mode == .download else {
            throw MacWinError.unsupportedInstallerMode(recipe.installer.mode.rawValue)
        }
        guard let urlString = recipe.installer.url, let sourceURL = URL(string: urlString) else {
            throw MacWinError.invalidManifest("Recipe \(recipe.id) is missing a valid installer URL")
        }
        guard let fileName = installerFileName(for: recipe), !fileName.isEmpty else {
            throw MacWinError.invalidManifest("Recipe \(recipe.id) is missing installer file name")
        }

        try fileManager.createDirectory(at: paths.downloadsDirectory, withIntermediateDirectories: true)
        let destination = paths.downloadsDirectory.appendingPathComponent(fileName)
        let startedAt = Date()
        let history = InstallerDownloadHistoryService(paths: paths, fileManager: fileManager)
        if fileManager.fileExists(atPath: destination.path) {
            let actualHash = try Hashing.sha256Hex(file: destination)
            if recipe.installer.sha256 == nil || actualHash.caseInsensitiveCompare(recipe.installer.sha256 ?? "") == .orderedSame {
                let result = try downloadResult(
                    recipe: recipe,
                    fileName: fileName,
                    sourceURL: urlString,
                    destination: destination,
                    actualHash: actualHash,
                    usedCachedFile: true
                )
                try? history.save(downloadRecord(
                    recipe: recipe,
                    result: result,
                    startedAt: startedAt,
                    endedAt: Date(),
                    state: .cached
                ))
                return result
            }
        }

        let temporaryURL = paths.downloadsDirectory
            .appendingPathComponent(".\(fileName).\(UUID().uuidString).download")
        do {
            let data = try Data(contentsOf: sourceURL)
            try data.write(to: temporaryURL, options: [.atomic])
            let actualHash = try Hashing.sha256Hex(file: temporaryURL)
            if let expectedHash = recipe.installer.sha256,
               actualHash.caseInsensitiveCompare(expectedHash) != .orderedSame {
                let values = try? temporaryURL.resourceValues(forKeys: [.fileSizeKey])
                try? history.save(InstallerDownloadRecord(
                    recipeId: recipe.id,
                    recipeName: recipe.name,
                    fileName: fileName,
                    sourceURL: urlString,
                    destinationPath: destination.path,
                    startedAt: startedAt,
                    endedAt: Date(),
                    state: .hashMismatch,
                    expectedSha256: expectedHash,
                    actualSha256: actualHash,
                    byteCount: values?.fileSize.map(Int64.init),
                    errorMessage: "Downloaded installer SHA-256 does not match recipe"
                ))
                try? fileManager.removeItem(at: temporaryURL)
                throw MacWinError.catalogHashMismatch(recipeId: recipe.id, expected: expectedHash, actual: actualHash)
            }
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.moveItem(at: temporaryURL, to: destination)
            let result = try downloadResult(
                recipe: recipe,
                fileName: fileName,
                sourceURL: urlString,
                destination: destination,
                actualHash: actualHash,
                usedCachedFile: false
            )
            try? history.save(downloadRecord(
                recipe: recipe,
                result: result,
                startedAt: startedAt,
                endedAt: Date(),
                state: .downloaded
            ))
            return result
        } catch {
            try? fileManager.removeItem(at: temporaryURL)
            if !isHashMismatch(error) {
                try? history.save(InstallerDownloadRecord(
                    recipeId: recipe.id,
                    recipeName: recipe.name,
                    fileName: fileName,
                    sourceURL: urlString,
                    destinationPath: destination.path,
                    startedAt: startedAt,
                    endedAt: Date(),
                    state: .failed,
                    expectedSha256: recipe.installer.sha256,
                    errorMessage: error.localizedDescription
                ))
            }
            throw error
        }
    }

    private func recipeStatus(recipe: RecipeManifest, includeHashes: Bool) -> RecipeInstallerAssetStatus {
        let fileName = installerFileName(for: recipe)
        let cachedURL = fileName.map { paths.downloadsDirectory.appendingPathComponent($0) }
        let exists = cachedURL.map { fileManager.fileExists(atPath: $0.path) } ?? false
        let values = cachedURL.flatMap { try? $0.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]) }
        let actualHash: String?
        if exists, recipe.installer.sha256 != nil || includeHashes, let cachedURL {
            actualHash = try? Hashing.sha256Hex(file: cachedURL)
        } else {
            actualHash = nil
        }
        let architecture = cachedURL.flatMap { architectureIfExecutable($0) }
        let hashStatus: InstallerHashStatus
        if recipe.installer.mode == .none || recipe.installer.mode == .alreadyInstalled {
            hashStatus = .notApplicable
        } else if !exists {
            hashStatus = .missing
        } else if let expected = recipe.installer.sha256 {
            hashStatus = actualHash?.caseInsensitiveCompare(expected) == .orderedSame ? .match : .mismatch
        } else {
            hashStatus = .notExpected
        }

        return RecipeInstallerAssetStatus(
            recipeId: recipe.id,
            recipeName: recipe.name,
            publisher: recipe.publisher,
            category: recipe.category,
            compatibilityRating: recipe.compatibilityRating,
            disabled: recipe.disabledReason != nil,
            disabledReason: recipe.disabledReason,
            installerMode: recipe.installer.mode,
            fileName: fileName,
            sourceURL: recipe.installer.url,
            expectedSha256: recipe.installer.sha256,
            cachedPath: cachedURL?.path,
            cachedExists: exists,
            byteCount: exists ? values?.fileSize.map(Int64.init) : nil,
            modifiedAt: exists ? values?.contentModificationDate : nil,
            actualSha256: actualHash,
            hashStatus: hashStatus,
            architecture: architecture,
            requiresWin32Installer: architecture?.is32Bit == true
        )
    }

    private static func severityRank(_ severity: InstallerPreparationSeverity) -> Int {
        switch severity {
        case .critical:
            0
        case .warning:
            1
        case .info:
            2
        }
    }

    private func downloadCacheFiles(includeHashes: Bool) -> [DownloadCacheFileStatus] {
        guard let urls = try? fileManager.contentsOfDirectory(
            at: paths.downloadsDirectory,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return urls.compactMap { url in
            guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey]),
                  values.isRegularFile == true else {
                return nil
            }
            return DownloadCacheFileStatus(
                name: url.lastPathComponent,
                path: url.path,
                byteCount: Int64(values.fileSize ?? 0),
                modifiedAt: values.contentModificationDate ?? .distantPast,
                pathExtension: url.pathExtension.lowercased(),
                sha256: includeHashes ? (try? Hashing.sha256Hex(file: url)) : nil,
                architecture: architectureIfExecutable(url)
            )
        }
        .sorted { lhs, rhs in
            if lhs.modifiedAt == rhs.modifiedAt {
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            return lhs.modifiedAt > rhs.modifiedAt
        }
    }

    private func installerFileName(for recipe: RecipeManifest) -> String? {
        if let fileName = recipe.installer.fileName, !fileName.isEmpty {
            return fileName
        }
        guard let urlString = recipe.installer.url,
              let url = URL(string: urlString),
              !url.lastPathComponent.isEmpty else {
            return nil
        }
        return url.lastPathComponent
    }

    private func architectureIfExecutable(_ url: URL) -> WindowsExecutableArchitecture? {
        guard url.pathExtension.lowercased() == "exe" else { return nil }
        return try? WindowsExecutableInspector.architecture(of: url, fileManager: fileManager)
    }

    private static func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private static func cacheState(for status: RecipeInstallerAssetStatus) -> String {
        guard status.installerMode == .download || (status.installerMode == .localFile && status.fileName != nil) else {
            return "notApplicable"
        }
        if !status.cachedExists { return "missing" }
        if status.hashStatus == .mismatch { return "mismatch" }
        return "cached"
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
            .replacingOccurrences(of: "\n", with: " ")
    }

    private func downloadResult(
        recipe: RecipeManifest,
        fileName: String,
        sourceURL: String,
        destination: URL,
        actualHash: String,
        usedCachedFile: Bool
    ) throws -> InstallerDownloadResult {
        let values = try destination.resourceValues(forKeys: [.fileSizeKey])
        let hashStatus: InstallerHashStatus
        if let expected = recipe.installer.sha256 {
            hashStatus = actualHash.caseInsensitiveCompare(expected) == .orderedSame ? .match : .mismatch
        } else {
            hashStatus = .notExpected
        }
        return InstallerDownloadResult(
            recipeId: recipe.id,
            fileName: fileName,
            sourceURL: sourceURL,
            destinationPath: destination.path,
            byteCount: Int64(values.fileSize ?? 0),
            actualSha256: actualHash,
            hashStatus: hashStatus,
            usedCachedFile: usedCachedFile
        )
    }

    private func downloadRecord(
        recipe: RecipeManifest,
        result: InstallerDownloadResult,
        startedAt: Date,
        endedAt: Date,
        state: InstallerDownloadState
    ) -> InstallerDownloadRecord {
        InstallerDownloadRecord(
            recipeId: recipe.id,
            recipeName: recipe.name,
            fileName: result.fileName,
            sourceURL: result.sourceURL,
            destinationPath: result.destinationPath,
            startedAt: startedAt,
            endedAt: endedAt,
            state: state,
            expectedSha256: recipe.installer.sha256,
            actualSha256: result.actualSha256,
            byteCount: result.byteCount,
            usedCachedFile: result.usedCachedFile
        )
    }

    private func isHashMismatch(_ error: Error) -> Bool {
        guard let error = error as? MacWinError else { return false }
        if case .catalogHashMismatch = error {
            return true
        }
        return false
    }
}
