import Foundation

public enum SoftwareSampleInstallSource: String, Codable, Equatable, Sendable {
    case signedRecipe
    case localInstaller
    case alreadyInstalled
    case externalExecutable
}

public struct SoftwareSampleProfile: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var publisher: String
    public var category: String
    public var purpose: String
    public var installSource: SoftwareSampleInstallSource
    public var catalogRecipeId: String?
    public var installerFileNames: [String]
    public var launcherCandidates: [String]
    public var compatibilityProfileId: String?
    public var expectedIssueIds: [String]
    public var recommendedProbeIds: [String]
    public var environment: [String: String]
    public var warnings: [String]
    public var catalogBacked: Bool

    public init(
        id: String,
        name: String,
        publisher: String,
        category: String,
        purpose: String,
        installSource: SoftwareSampleInstallSource,
        catalogRecipeId: String? = nil,
        installerFileNames: [String] = [],
        launcherCandidates: [String] = [],
        compatibilityProfileId: String? = nil,
        expectedIssueIds: [String] = [],
        recommendedProbeIds: [String] = [],
        environment: [String: String] = [:],
        warnings: [String] = [],
        catalogBacked: Bool = false
    ) {
        self.id = id
        self.name = name
        self.publisher = publisher
        self.category = category
        self.purpose = purpose
        self.installSource = installSource
        self.catalogRecipeId = catalogRecipeId
        self.installerFileNames = installerFileNames
        self.launcherCandidates = launcherCandidates
        self.compatibilityProfileId = compatibilityProfileId
        self.expectedIssueIds = expectedIssueIds
        self.recommendedProbeIds = recommendedProbeIds
        self.environment = environment
        self.warnings = warnings
        self.catalogBacked = catalogBacked
    }
}

public struct SoftwareSampleCatalogReport: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var rootPath: String
    public var sampleCount: Int
    public var signedRecipeCount: Int
    public var localInstallerCount: Int
    public var alreadyInstalledCount: Int
    public var externalExecutableCount: Int
    public var catalogBackedCount: Int
    public var warningCount: Int
    public var samples: [SoftwareSampleProfile]

    public init(generatedAt: Date, rootPath: String, samples: [SoftwareSampleProfile]) {
        self.generatedAt = generatedAt
        self.rootPath = rootPath
        self.sampleCount = samples.count
        self.signedRecipeCount = samples.filter { $0.installSource == .signedRecipe }.count
        self.localInstallerCount = samples.filter { $0.installSource == .localInstaller }.count
        self.alreadyInstalledCount = samples.filter { $0.installSource == .alreadyInstalled }.count
        self.externalExecutableCount = samples.filter { $0.installSource == .externalExecutable }.count
        self.catalogBackedCount = samples.filter(\.catalogBacked).count
        self.warningCount = samples.map(\.warnings.count).reduce(0, +)
        self.samples = samples
    }
}

public enum SoftwareSamplePreparationStatus: String, Codable, Equatable, Sendable {
    case ready
    case missingInstaller
    case missingRecipe
    case manual
}

public struct SoftwareSamplePreparationEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: String { sampleId }
    public var sampleId: String
    public var name: String
    public var publisher: String
    public var category: String
    public var installSource: SoftwareSampleInstallSource
    public var catalogRecipeId: String?
    public var catalogBacked: Bool
    public var status: SoftwareSamplePreparationStatus
    public var compatibilityProfileId: String?
    public var installerFileNames: [String]
    public var cachedInstallerPaths: [String]
    public var launcherCandidates: [String]
    public var requiredAction: String
    public var expectedIssueIds: [String]
    public var recommendedProbeIds: [String]
    public var environment: [String: String]
    public var warnings: [String]

    public init(
        sampleId: String,
        name: String,
        publisher: String = "",
        category: String = "",
        installSource: SoftwareSampleInstallSource,
        catalogRecipeId: String? = nil,
        catalogBacked: Bool,
        status: SoftwareSamplePreparationStatus,
        compatibilityProfileId: String? = nil,
        installerFileNames: [String],
        cachedInstallerPaths: [String],
        requiredAction: String,
        expectedIssueIds: [String] = [],
        recommendedProbeIds: [String],
        environment: [String: String] = [:],
        warnings: [String],
        launcherCandidates: [String] = []
    ) {
        self.sampleId = sampleId
        self.name = name
        self.publisher = publisher
        self.category = category
        self.installSource = installSource
        self.catalogRecipeId = catalogRecipeId
        self.catalogBacked = catalogBacked
        self.status = status
        self.compatibilityProfileId = compatibilityProfileId
        self.installerFileNames = installerFileNames
        self.cachedInstallerPaths = cachedInstallerPaths
        self.launcherCandidates = launcherCandidates
        self.requiredAction = requiredAction
        self.expectedIssueIds = expectedIssueIds
        self.recommendedProbeIds = recommendedProbeIds
        self.environment = environment
        self.warnings = warnings
    }
}

public struct SoftwareSamplePreparationReport: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var rootPath: String
    public var downloadsPath: String
    public var sampleCount: Int
    public var readyCount: Int
    public var missingInstallerCount: Int
    public var missingRecipeCount: Int
    public var manualCount: Int
    public var cachedInstallerCount: Int
    public var warningCount: Int
    public var entries: [SoftwareSamplePreparationEntry]

    public init(
        generatedAt: Date,
        rootPath: String,
        downloadsPath: String,
        entries: [SoftwareSamplePreparationEntry]
    ) {
        self.generatedAt = generatedAt
        self.rootPath = rootPath
        self.downloadsPath = downloadsPath
        self.sampleCount = entries.count
        self.readyCount = entries.filter { $0.status == .ready }.count
        self.missingInstallerCount = entries.filter { $0.status == .missingInstaller }.count
        self.missingRecipeCount = entries.filter { $0.status == .missingRecipe }.count
        self.manualCount = entries.filter { $0.status == .manual }.count
        self.cachedInstallerCount = entries.map(\.cachedInstallerPaths.count).reduce(0, +)
        self.warningCount = entries.map(\.warnings.count).reduce(0, +)
        self.entries = entries
    }
}

public struct SoftwareSampleSmokeCoverageCandidate: Codable, Equatable, Identifiable, Sendable {
    public var id: String { sampleId }
    public var sampleId: String
    public var name: String
    public var category: String
    public var installSource: SoftwareSampleInstallSource
    public var status: SoftwareSamplePreparationStatus
    public var catalogRecipeId: String?
    public var smokeStage: SoftwareSmokeStage?
    public var cachedInstallerCount: Int
    public var cachedInstallerPaths: [String]
    public var expectedIssueIds: [String]
    public var recommendedProbeIds: [String]
    public var compatibilityProfileId: String?
    public var launchCovered: Bool = false
    public var latestLaunchState: WineLaunchState? = nil
    public var latestLaunchLogPath: String? = nil
    public var latestLaunchExitCode: Int32? = nil
    public var latestLaunchStartedAt: Date? = nil
    public var priorityScore: Int
    public var recommendedAction: String
}

public struct SoftwareSampleSmokeCoverageReport: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var rootPath: String
    public var sampleCount: Int
    public var readySampleCount: Int
    public var smokeMatrixRecipeCount: Int
    public var coveredReadySampleCount: Int
    public var uncoveredReadySampleCount: Int
    public var blockedSampleCount: Int
    public var readyCoveragePercent: Double
    public var coveredSampleIds: [String]
    public var uncoveredReadySamples: [SoftwareSampleSmokeCoverageCandidate]
    public var blockedSamples: [SoftwareSampleSmokeCoverageCandidate]
    public var nextActions: [SoftwareSampleSmokeCoverageCandidate]

    public init(
        generatedAt: Date,
        rootPath: String,
        preparation: SoftwareSamplePreparationReport,
        smokeMatrix: SoftwareSmokeMatrixReport,
        candidates: [SoftwareSampleSmokeCoverageCandidate]
    ) {
        self.generatedAt = generatedAt
        self.rootPath = rootPath
        self.sampleCount = preparation.sampleCount
        self.readySampleCount = preparation.readyCount
        self.smokeMatrixRecipeCount = smokeMatrix.recipeCount
        self.coveredSampleIds = candidates
            .filter { $0.status == .ready && ($0.smokeStage != nil || $0.launchCovered) }
            .map(\.sampleId)
            .sorted()
        self.uncoveredReadySamples = candidates
            .filter { $0.status == .ready && $0.smokeStage == nil && !$0.launchCovered }
            .sorted(by: Self.candidateSort)
        self.blockedSamples = candidates
            .filter { $0.status == .missingInstaller || $0.status == .missingRecipe || $0.status == .manual }
            .sorted(by: Self.candidateSort)
        self.coveredReadySampleCount = coveredSampleIds.count
        self.uncoveredReadySampleCount = uncoveredReadySamples.count
        self.blockedSampleCount = blockedSamples.count
        self.readyCoveragePercent = preparation.readyCount > 0
            ? (Double(coveredReadySampleCount) / Double(preparation.readyCount)) * 100
            : 100
        self.nextActions = Array(uncoveredReadySamples.prefix(12))
    }

    private static func candidateSort(
        lhs: SoftwareSampleSmokeCoverageCandidate,
        rhs: SoftwareSampleSmokeCoverageCandidate
    ) -> Bool {
        if lhs.priorityScore != rhs.priorityScore {
            return lhs.priorityScore > rhs.priorityScore
        }
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
}

public struct SoftwareSamplePreparationSnapshotManifest: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var generatedAt: Date
    public var snapshotPath: String
    public var reportPath: String
    public var csvPath: String
    public var markdownPath: String
    public var runbookPath: String
    public var rootPath: String
    public var downloadsPath: String
    public var sampleCount: Int
    public var readyCount: Int
    public var missingInstallerCount: Int
    public var missingRecipeCount: Int
    public var manualCount: Int
    public var cachedInstallerCount: Int
    public var warningCount: Int
    public var readySampleIds: [String]
    public var blockedSampleIds: [String]
    public var manualSampleIds: [String]

    public init(
        schemaVersion: Int = 1,
        generatedAt: Date,
        snapshotPath: String,
        reportPath: String,
        csvPath: String,
        markdownPath: String,
        runbookPath: String,
        report: SoftwareSamplePreparationReport
    ) {
        self.schemaVersion = schemaVersion
        self.generatedAt = generatedAt
        self.snapshotPath = snapshotPath
        self.reportPath = reportPath
        self.csvPath = csvPath
        self.markdownPath = markdownPath
        self.runbookPath = runbookPath
        self.rootPath = report.rootPath
        self.downloadsPath = report.downloadsPath
        self.sampleCount = report.sampleCount
        self.readyCount = report.readyCount
        self.missingInstallerCount = report.missingInstallerCount
        self.missingRecipeCount = report.missingRecipeCount
        self.manualCount = report.manualCount
        self.cachedInstallerCount = report.cachedInstallerCount
        self.warningCount = report.warningCount
        self.readySampleIds = report.entries.filter { $0.status == .ready }.map(\.sampleId)
        self.blockedSampleIds = report.entries
            .filter { $0.status == .missingInstaller || $0.status == .missingRecipe }
            .map(\.sampleId)
        self.manualSampleIds = report.entries.filter { $0.status == .manual }.map(\.sampleId)
    }
}

public struct SoftwareSamplePreparationSnapshotResult: Equatable, Sendable {
    public var directoryURL: URL
    public var manifestURL: URL
    public var reportURL: URL
    public var csvURL: URL
    public var markdownURL: URL
    public var runbookURL: URL
    public var manifest: SoftwareSamplePreparationSnapshotManifest
    public var report: SoftwareSamplePreparationReport
}

public struct SoftwareSampleCatalogService {
    public var paths: MacWinPaths
    public var samples: [SoftwareSampleProfile]
    public var fileManager: FileManager

    public init(
        paths: MacWinPaths = MacWinPaths(),
        samples: [SoftwareSampleProfile] = SoftwareSampleCatalogService.defaultSamples,
        fileManager: FileManager = .default
    ) {
        self.paths = paths
        self.samples = samples
        self.fileManager = fileManager
    }

    public func report(recipes: [RecipeManifest], generatedAt: Date = Date()) -> SoftwareSampleCatalogReport {
        Self.report(
            rootPath: paths.root.path,
            samples: samples,
            recipes: recipes,
            generatedAt: generatedAt
        )
    }

    public func preparationReport(
        catalog: SoftwareSampleCatalogReport,
        generatedAt: Date = Date(),
        fileManager: FileManager = .default
    ) -> SoftwareSamplePreparationReport {
        Self.preparationReport(
            catalog: catalog,
            downloadsDirectory: paths.downloadsDirectory,
            generatedAt: generatedAt,
            fileManager: fileManager
        )
    }

    public func exportPreparationSnapshot(
        catalog: SoftwareSampleCatalogReport,
        generatedAt: Date = Date()
    ) throws -> SoftwareSamplePreparationSnapshotResult {
        let report = preparationReport(catalog: catalog, generatedAt: generatedAt, fileManager: fileManager)
        return try exportPreparationSnapshot(report: report, generatedAt: generatedAt)
    }

    public func exportPreparationSnapshot(
        report: SoftwareSamplePreparationReport,
        generatedAt: Date = Date()
    ) throws -> SoftwareSamplePreparationSnapshotResult {
        try paths.ensureBaseDirectories(fileManager: fileManager)
        let directoryURL = paths.logsDirectory
            .appendingPathComponent("SoftwareSamplePreparationSnapshots", isDirectory: true)
            .appendingPathComponent("software-sample-preparation-\(Self.fileTimestamp(generatedAt))", isDirectory: true)
        if fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.removeItem(at: directoryURL)
        }
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let store = JSONStore(fileManager: fileManager)
        let reportURL = directoryURL.appendingPathComponent("software-sample-preparation.json")
        try store.save(report, to: reportURL)

        let csvURL = directoryURL.appendingPathComponent("software-sample-preparation.csv")
        try Data(Self.preparationCSV(report: report).utf8).write(to: csvURL, options: [.atomic])

        let markdownURL = directoryURL.appendingPathComponent("software-sample-preparation.md")
        try Data(Self.preparationMarkdown(report: report).utf8).write(to: markdownURL, options: [.atomic])

        let runbookURL = directoryURL.appendingPathComponent("software-sample-preparation-runbook.sh")
        try Data(Self.preparationShellScript(report: report).utf8).write(to: runbookURL, options: [.atomic])
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: runbookURL.path)

        let manifest = SoftwareSamplePreparationSnapshotManifest(
            generatedAt: generatedAt,
            snapshotPath: directoryURL.path,
            reportPath: reportURL.path,
            csvPath: csvURL.path,
            markdownPath: markdownURL.path,
            runbookPath: runbookURL.path,
            report: report
        )
        let manifestURL = directoryURL.appendingPathComponent("manifest.json")
        try store.save(manifest, to: manifestURL)

        return SoftwareSamplePreparationSnapshotResult(
            directoryURL: directoryURL,
            manifestURL: manifestURL,
            reportURL: reportURL,
            csvURL: csvURL,
            markdownURL: markdownURL,
            runbookURL: runbookURL,
            manifest: manifest,
            report: report
        )
    }

    public func smokeCoverageReport(
        preparation: SoftwareSamplePreparationReport,
        smokeMatrix: SoftwareSmokeMatrixReport,
        launchRecords: [WineLaunchRecord] = [],
        smokeReports: [SoftwareSmokeRunReport] = [],
        generatedAt: Date = Date()
    ) -> SoftwareSampleSmokeCoverageReport {
        Self.smokeCoverageReport(
            preparation: preparation,
            smokeMatrix: smokeMatrix,
            launchRecords: launchRecords,
            smokeReports: smokeReports,
            generatedAt: generatedAt
        )
    }

    public static func report(
        rootPath: String,
        samples: [SoftwareSampleProfile] = defaultSamples,
        recipes: [RecipeManifest],
        generatedAt: Date = Date()
    ) -> SoftwareSampleCatalogReport {
        let recipeIds = Set(recipes.map(\.id))
        let resolved = samples.map { sample in
            var resolvedSample = sample
            if let recipeId = sample.catalogRecipeId {
                resolvedSample.catalogBacked = recipeIds.contains(recipeId)
            }
            return resolvedSample
        }
        return SoftwareSampleCatalogReport(
            generatedAt: generatedAt,
            rootPath: rootPath,
            samples: resolved.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        )
    }

    public static func preparationReport(
        catalog: SoftwareSampleCatalogReport,
        downloadsDirectory: URL,
        generatedAt: Date = Date(),
        fileManager: FileManager = .default
    ) -> SoftwareSamplePreparationReport {
        let files = downloadedFiles(in: downloadsDirectory, fileManager: fileManager)
        let entries = catalog.samples.map { sample in
            let cachedPaths = matchingInstallerPaths(for: sample, files: files)
            let status: SoftwareSamplePreparationStatus
            let requiredAction: String
            switch sample.installSource {
            case .signedRecipe:
                if sample.catalogBacked {
                    status = .ready
                    requiredAction = "Install from signed MacWin recipe \(sample.catalogRecipeId ?? sample.id)."
                } else {
                    status = .missingRecipe
                    requiredAction = "Add or refresh the signed recipe before this sample can be installed from the curated catalog."
                }
            case .localInstaller:
                if cachedPaths.isEmpty {
                    status = .missingInstaller
                    requiredAction = sample.installerFileNames.isEmpty
                        ? "Provide a local installer in the MacWin Downloads directory."
                        : "Place one matching local installer in the MacWin Downloads directory: \(sample.installerFileNames.joined(separator: ", "))."
                } else {
                    status = .ready
                    requiredAction = "Use the cached local installer from Downloads."
                }
            case .alreadyInstalled:
                status = .manual
                requiredAction = "Scan the bottle for installed launcher candidates and verify the app manually."
            case .externalExecutable:
                status = cachedPaths.isEmpty ? .manual : .ready
                requiredAction = cachedPaths.isEmpty
                    ? "Drop or open a local executable with MacWin Manager."
                    : "Run the cached executable through MacWin Manager."
            }
            return SoftwareSamplePreparationEntry(
                sampleId: sample.id,
                name: sample.name,
                publisher: sample.publisher,
                category: sample.category,
                installSource: sample.installSource,
                catalogRecipeId: sample.catalogRecipeId,
                catalogBacked: sample.catalogBacked,
                status: status,
                compatibilityProfileId: sample.compatibilityProfileId,
                installerFileNames: sample.installerFileNames,
                cachedInstallerPaths: cachedPaths,
                requiredAction: requiredAction,
                expectedIssueIds: sample.expectedIssueIds,
                recommendedProbeIds: sample.recommendedProbeIds,
                environment: sample.environment,
                warnings: sample.warnings,
                launcherCandidates: sample.launcherCandidates
            )
        }
        .sorted { lhs, rhs in
            if preparationRank(lhs.status) != preparationRank(rhs.status) {
                return preparationRank(lhs.status) < preparationRank(rhs.status)
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        return SoftwareSamplePreparationReport(
            generatedAt: generatedAt,
            rootPath: catalog.rootPath,
            downloadsPath: downloadsDirectory.path,
            entries: entries
        )
    }

    public static func smokeCoverageReport(
        preparation: SoftwareSamplePreparationReport,
        smokeMatrix: SoftwareSmokeMatrixReport,
        launchRecords: [WineLaunchRecord] = [],
        smokeReports: [SoftwareSmokeRunReport] = [],
        generatedAt: Date = Date()
    ) -> SoftwareSampleSmokeCoverageReport {
        let stageByRecipeId = Dictionary(uniqueKeysWithValues: smokeMatrix.rows.map { ($0.recipeId, $0.stage) })
        let candidates = preparation.entries.map { entry in
            let smokeStage = entry.catalogRecipeId.flatMap { stageByRecipeId[$0] }
            let launchRecord = latestSuccessfulLaunchEvidence(
                for: entry,
                launchRecords: launchRecords,
                smokeReports: smokeReports
            )
            return SoftwareSampleSmokeCoverageCandidate(
                sampleId: entry.sampleId,
                name: entry.name,
                category: entry.category,
                installSource: entry.installSource,
                status: entry.status,
                catalogRecipeId: entry.catalogRecipeId,
                smokeStage: smokeStage,
                cachedInstallerCount: entry.cachedInstallerPaths.count,
                cachedInstallerPaths: entry.cachedInstallerPaths,
                expectedIssueIds: entry.expectedIssueIds,
                recommendedProbeIds: entry.recommendedProbeIds,
                compatibilityProfileId: entry.compatibilityProfileId,
                launchCovered: launchRecord != nil,
                latestLaunchState: launchRecord?.state,
                latestLaunchLogPath: launchRecord?.logPath,
                latestLaunchExitCode: launchRecord?.exitCode,
                latestLaunchStartedAt: launchRecord?.startedAt,
                priorityScore: smokeCoveragePriority(entry),
                recommendedAction: smokeCoverageAction(
                    entry: entry,
                    smokeStage: smokeStage,
                    launchCovered: launchRecord != nil
                )
            )
        }
        return SoftwareSampleSmokeCoverageReport(
            generatedAt: generatedAt,
            rootPath: preparation.rootPath,
            preparation: preparation,
            smokeMatrix: smokeMatrix,
            candidates: candidates
        )
    }

    public static func csv(report: SoftwareSampleCatalogReport) -> String {
        var rows: [[String]] = [[
            "sample_id",
            "name",
            "publisher",
            "category",
            "purpose",
            "install_source",
            "catalog_recipe_id",
            "catalog_backed",
            "compatibility_profile_id",
            "installer_file_names",
            "launcher_candidates",
            "expected_issue_ids",
            "recommended_probe_ids",
            "environment",
            "warnings"
        ]]

        for sample in report.samples {
            rows.append([
                sample.id,
                sample.name,
                sample.publisher,
                sample.category,
                sample.purpose,
                sample.installSource.rawValue,
                sample.catalogRecipeId ?? "",
                sample.catalogBacked ? "true" : "false",
                sample.compatibilityProfileId ?? "",
                sample.installerFileNames.joined(separator: ";"),
                sample.launcherCandidates.joined(separator: ";"),
                sample.expectedIssueIds.joined(separator: ";"),
                sample.recommendedProbeIds.joined(separator: ";"),
                sample.environment.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ";"),
                sample.warnings.joined(separator: ";")
            ])
        }
        return rows.map { $0.map(csvEscaped).joined(separator: ",") }.joined(separator: "\n") + "\n"
    }

    public static func runbookMarkdown(report: SoftwareSampleCatalogReport) -> String {
        let formatter = ISO8601DateFormatter()
        var lines = [
            "# MacWin Software Sample Catalog",
            "",
            "- Generated: \(formatter.string(from: report.generatedAt))",
            "- Root: `\(report.rootPath)`",
            "- Samples: \(report.sampleCount)",
            "- Catalog backed: \(report.catalogBackedCount)",
            "- Local installers: \(report.localInstallerCount)",
            "- Already installed: \(report.alreadyInstalledCount)",
            "- Warnings: \(report.warningCount)",
            ""
        ]

        for sample in report.samples {
            lines.append("## \(sample.name)")
            lines.append("")
            lines.append("- ID: `\(sample.id)`")
            lines.append("- Publisher: \(sample.publisher)")
            lines.append("- Category: \(sample.category)")
            lines.append("- Source: \(sample.installSource.rawValue)")
            if let recipeId = sample.catalogRecipeId {
                lines.append("- Signed recipe: `\(recipeId)` \(sample.catalogBacked ? "(available)" : "(missing)")")
            }
            if let profile = sample.compatibilityProfileId {
                lines.append("- Compatibility profile: `\(profile)`")
            }
            lines.append("- Purpose: \(sample.purpose)")
            if !sample.installerFileNames.isEmpty {
                lines.append("- Installer candidates: \(sample.installerFileNames.map { "`\($0)`" }.joined(separator: ", "))")
            }
            if !sample.launcherCandidates.isEmpty {
                lines.append("- Launcher candidates: \(sample.launcherCandidates.map { "`\($0)`" }.joined(separator: ", "))")
            }
            if !sample.recommendedProbeIds.isEmpty {
                lines.append("- Recommended probes: \(sample.recommendedProbeIds.map { "`\($0)`" }.joined(separator: ", "))")
            }
            if !sample.expectedIssueIds.isEmpty {
                lines.append("- Expected issue watchlist: \(sample.expectedIssueIds.map { "`\($0)`" }.joined(separator: ", "))")
            }
            if !sample.environment.isEmpty {
                lines.append("- Environment:")
                for (key, value) in sample.environment.sorted(by: { $0.key < $1.key }) {
                    lines.append("  - `\(key)=\(value)`")
                }
            }
            if !sample.warnings.isEmpty {
                lines.append("- Warnings:")
                for warning in sample.warnings {
                    lines.append("  - \(warning)")
                }
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func preparationCSV(report: SoftwareSamplePreparationReport) -> String {
        var rows: [[String]] = [[
            "sample_id",
            "name",
            "publisher",
            "category",
            "install_source",
            "catalog_recipe_id",
            "catalog_backed",
            "status",
            "compatibility_profile_id",
            "installer_file_names",
            "cached_installer_paths",
            "required_action",
            "expected_issue_ids",
            "recommended_probe_ids",
            "environment",
            "warnings"
        ]]
        for entry in report.entries {
            rows.append([
                entry.sampleId,
                entry.name,
                entry.publisher,
                entry.category,
                entry.installSource.rawValue,
                entry.catalogRecipeId ?? "",
                entry.catalogBacked ? "true" : "false",
                entry.status.rawValue,
                entry.compatibilityProfileId ?? "",
                entry.installerFileNames.joined(separator: ";"),
                entry.cachedInstallerPaths.joined(separator: ";"),
                entry.requiredAction,
                entry.expectedIssueIds.joined(separator: ";"),
                entry.recommendedProbeIds.joined(separator: ";"),
                joinedEnvironment(entry.environment),
                entry.warnings.joined(separator: ";")
            ])
        }
        return rows.map { $0.map(csvEscaped).joined(separator: ",") }.joined(separator: "\n") + "\n"
    }

    public static func smokeCoverageCSV(report: SoftwareSampleSmokeCoverageReport) -> String {
        var rows: [[String]] = [[
            "sample_id",
            "name",
            "category",
            "install_source",
            "status",
            "catalog_recipe_id",
            "smoke_stage",
            "priority_score",
            "cached_installer_count",
            "expected_issue_ids",
            "recommended_probe_ids",
            "compatibility_profile_id",
            "launch_covered",
            "latest_launch_state",
            "latest_launch_exit_code",
            "latest_launch_started_at",
            "latest_launch_log_path",
            "recommended_action"
        ]]

        for candidate in report.uncoveredReadySamples + report.blockedSamples {
            rows.append([
                candidate.sampleId,
                candidate.name,
                candidate.category,
                candidate.installSource.rawValue,
                candidate.status.rawValue,
                candidate.catalogRecipeId ?? "",
                candidate.smokeStage?.rawValue ?? "",
                String(candidate.priorityScore),
                String(candidate.cachedInstallerCount),
                candidate.expectedIssueIds.joined(separator: ";"),
                candidate.recommendedProbeIds.joined(separator: ";"),
                candidate.compatibilityProfileId ?? "",
                candidate.launchCovered ? "true" : "false",
                candidate.latestLaunchState?.rawValue ?? "",
                candidate.latestLaunchExitCode.map(String.init) ?? "",
                candidate.latestLaunchStartedAt.map { ISO8601DateFormatter().string(from: $0) } ?? "",
                candidate.latestLaunchLogPath ?? "",
                candidate.recommendedAction
            ])
        }

        return rows.map { $0.map(csvEscaped).joined(separator: ",") }.joined(separator: "\n") + "\n"
    }

    public static func smokeCoverageMarkdown(report: SoftwareSampleSmokeCoverageReport) -> String {
        let formatter = ISO8601DateFormatter()
        var lines = [
            "# MacWin Software Sample Smoke Coverage",
            "",
            "- Generated: \(formatter.string(from: report.generatedAt))",
            "- Root: `\(markdownEscaped(report.rootPath))`",
            "- Samples: \(report.sampleCount)",
            "- Ready samples: \(report.readySampleCount)",
            "- Smoke matrix recipes: \(report.smokeMatrixRecipeCount)",
            "- Covered ready samples: \(report.coveredReadySampleCount)",
            "- Uncovered ready samples: \(report.uncoveredReadySampleCount)",
            "- Ready coverage: \(String(format: "%.1f", report.readyCoveragePercent))%",
            ""
        ]

        if report.nextActions.isEmpty {
            lines.append("All ready samples are represented in the smoke matrix.")
        } else {
            lines.append("## Next Smoke Candidates")
            lines.append("")
            for candidate in report.nextActions {
                lines.append("### \(markdownEscaped(candidate.name))")
                lines.append("")
                lines.append("- Sample: `\(markdownEscaped(candidate.sampleId))`")
                lines.append("- Category: \(markdownEscaped(candidate.category))")
                lines.append("- Source: `\(candidate.installSource.rawValue)`")
                lines.append("- Priority: \(candidate.priorityScore)")
                if let profile = candidate.compatibilityProfileId {
                    lines.append("- Compatibility profile: `\(markdownEscaped(profile))`")
                }
                if !candidate.expectedIssueIds.isEmpty {
                    lines.append("- Watchlist: \(candidate.expectedIssueIds.map { "`\(markdownEscaped($0))`" }.joined(separator: ", "))")
                }
                if !candidate.recommendedProbeIds.isEmpty {
                    lines.append("- Probes: \(candidate.recommendedProbeIds.map { "`\(markdownEscaped($0))`" }.joined(separator: ", "))")
                }
                lines.append("- Action: \(markdownEscaped(candidate.recommendedAction))")
                lines.append("")
            }
        }

        if !report.blockedSamples.isEmpty {
            lines.append("## Blocked Samples")
            lines.append("")
            for candidate in report.blockedSamples {
                lines.append("- `\(markdownEscaped(candidate.sampleId))`: \(markdownEscaped(candidate.recommendedAction))")
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func preparationMarkdown(report: SoftwareSamplePreparationReport) -> String {
        let formatter = ISO8601DateFormatter()
        var lines = [
            "# MacWin Software Sample Preparation",
            "",
            "- Generated: \(formatter.string(from: report.generatedAt))",
            "- Root: `\(markdownEscaped(report.rootPath))`",
            "- Downloads: `\(markdownEscaped(report.downloadsPath))`",
            "- Samples: \(report.sampleCount)",
            "- Ready: \(report.readyCount)",
            "- Missing installers: \(report.missingInstallerCount)",
            "- Missing recipes: \(report.missingRecipeCount)",
            "- Manual: \(report.manualCount)",
            "- Cached installers: \(report.cachedInstallerCount)",
            "- Warnings: \(report.warningCount)",
            "",
            "## Samples",
            ""
        ]
        if report.entries.isEmpty {
            lines.append("No software samples are defined.")
        } else {
            for entry in report.entries {
                lines.append("### \(markdownEscaped(entry.name))")
                lines.append("")
                lines.append("- Sample: `\(markdownEscaped(entry.sampleId))`")
                lines.append("- Publisher: \(markdownEscaped(entry.publisher))")
                lines.append("- Category: \(markdownEscaped(entry.category))")
                lines.append("- Status: `\(entry.status.rawValue)`")
                lines.append("- Source: `\(entry.installSource.rawValue)`")
                if let profileId = entry.compatibilityProfileId {
                    lines.append("- Compatibility profile: `\(markdownEscaped(profileId))`")
                }
                if let recipeId = entry.catalogRecipeId {
                    lines.append("- Recipe: `\(markdownEscaped(recipeId))` \(entry.catalogBacked ? "(available)" : "(missing)")")
                }
                lines.append("- Action: \(markdownEscaped(entry.requiredAction))")
                if !entry.expectedIssueIds.isEmpty {
                    lines.append("- Expected issues: \(entry.expectedIssueIds.map { "`\(markdownEscaped($0))`" }.joined(separator: ", "))")
                }
                if !entry.installerFileNames.isEmpty {
                    lines.append("- Installer candidates: \(entry.installerFileNames.map { "`\(markdownEscaped($0))`" }.joined(separator: ", "))")
                }
                if !entry.cachedInstallerPaths.isEmpty {
                    lines.append("- Cached installers:")
                    for path in entry.cachedInstallerPaths {
                        lines.append("  - `\(markdownEscaped(path))`")
                    }
                }
                if !entry.recommendedProbeIds.isEmpty {
                    lines.append("- Recommended probes: \(entry.recommendedProbeIds.map { "`\(markdownEscaped($0))`" }.joined(separator: ", "))")
                }
                if !entry.warnings.isEmpty {
                    lines.append("- Warnings:")
                    for warning in entry.warnings {
                        lines.append("  - \(markdownEscaped(warning))")
                    }
                }
                lines.append("")
            }
        }
        lines.append("")
        return lines.joined(separator: "\n")
    }

    public static func preparationShellScript(report: SoftwareSamplePreparationReport) -> String {
        let formatter = ISO8601DateFormatter()
        var lines = [
            "#!/usr/bin/env bash",
            "set -euo pipefail",
            "",
            "echo 'MacWin Software Sample Preparation'",
            "echo 'Generated: \(formatter.string(from: report.generatedAt))'",
            "echo 'Root: \(shellQuoted(report.rootPath))'",
            "echo 'Downloads: \(shellQuoted(report.downloadsPath))'",
            "echo 'Samples: \(report.sampleCount)'",
            "echo 'Ready: \(report.readyCount)'",
            "echo 'Missing installers: \(report.missingInstallerCount)'",
            "echo 'Missing recipes: \(report.missingRecipeCount)'",
            "echo 'Manual: \(report.manualCount)'",
            "echo 'Cached installers: \(report.cachedInstallerCount)'",
            "echo ''"
        ]

        if report.entries.isEmpty {
            lines.append("echo 'No software samples are defined.'")
        } else {
            for entry in report.entries {
                lines.append("echo \(shellQuoted("[\(preparationStatusLabel(entry.status))] \(entry.name) (\(entry.sampleId))"))")
                lines.append("echo \(shellQuoted("  category: \(entry.category)"))")
                if let profileId = entry.compatibilityProfileId {
                    lines.append("echo \(shellQuoted("  compatibility profile: \(profileId)"))")
                }
                lines.append("echo \(shellQuoted("  action: \(entry.requiredAction)"))")
                if let recipeId = entry.catalogRecipeId {
                    lines.append("echo \(shellQuoted("  recipe: \(recipeId) \(entry.catalogBacked ? "available" : "missing")"))")
                }
                if !entry.installerFileNames.isEmpty {
                    lines.append("echo \(shellQuoted("  installer candidates: \(entry.installerFileNames.joined(separator: ", "))"))")
                    for fileName in entry.installerFileNames {
                        lines.append("echo \(shellQuoted("  expected in Downloads: \(report.downloadsPath)/\(fileName)"))")
                    }
                }
                if !entry.cachedInstallerPaths.isEmpty {
                    lines.append("echo '  cached installers:'")
                    for path in entry.cachedInstallerPaths {
                        lines.append("echo \(shellQuoted("    \(path)"))")
                    }
                }
                if !entry.recommendedProbeIds.isEmpty {
                    lines.append("echo \(shellQuoted("  probes: \(entry.recommendedProbeIds.joined(separator: ", "))"))")
                }
                if !entry.warnings.isEmpty {
                    lines.append("echo '  warnings:'")
                    for warning in entry.warnings {
                        lines.append("echo \(shellQuoted("    \(warning)"))")
                    }
                }
                lines.append("echo ''")
            }
        }

        lines.append("if [ \(report.missingInstallerCount) -gt 0 ] || [ \(report.missingRecipeCount) -gt 0 ]; then")
        lines.append("  echo 'Action required: add missing local installers or signed recipes before running this sample set.' >&2")
        lines.append("  exit 1")
        lines.append("fi")
        lines.append("echo 'All software samples are ready or intentionally manual.'")
        lines.append("exit 0")
        lines.append("")
        return lines.joined(separator: "\n")
    }

    public static let defaultSamples: [SoftwareSampleProfile] = [
        SoftwareSampleProfile(
            id: "hoyoplay-cn",
            name: "HoYoPlay / 米哈游启动器",
            publisher: "miHoYo",
            category: "Game Launcher",
            purpose: "CEF launcher, Chinese text rendering, login, patcher, and GPU compositing coverage.",
            installSource: .signedRecipe,
            catalogRecipeId: "hoyoplay-cn",
            launcherCandidates: [
                "C:\\Program Files\\miHoYo Launcher\\HYP.exe",
                "C:\\Program Files\\miHoYo Launcher\\launcher.exe"
            ],
            compatibilityProfileId: "hoyoplay",
            expectedIssueIds: ["text-rendering", "cef-white-window", "launcher-cache"],
            recommendedProbeIds: ["70_text_rendering_probe", "80_window_input_probe", "20_vulkan_probe", "30_d3d11_probe"],
            environment: [
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "MACWIN_HOYOPLAY_TEXT_REPAIR": "1"
            ],
            warnings: ["Only install and launch; do not bypass login, anti-cheat, DRM, or game service restrictions."]
        ),
        SoftwareSampleProfile(
            id: "steam",
            name: "Steam",
            publisher: "Valve",
            category: "Game Store",
            purpose: "32-bit installer, CEF web helper, focus, game launcher, and store rendering coverage.",
            installSource: .signedRecipe,
            catalogRecipeId: "steam",
            installerFileNames: ["SteamSetup.exe"],
            launcherCandidates: [
                "C:\\Program Files\\Steam\\Steam.exe",
                "C:\\Program Files (x86)\\Steam\\Steam.exe"
            ],
            compatibilityProfileId: "steam",
            expectedIssueIds: ["steamwebhelper", "window-focus", "wow64"],
            recommendedProbeIds: ["80_window_input_probe", "70_text_rendering_probe", "10_tls_winhttp_probe", "10_tls_winhttp_probe_32"],
            environment: [
                "MACWIN_STEAMWEBHELPER_FORCE_OPAQUE": "1"
            ],
            warnings: ["Game compatibility depends on DRM, anti-cheat, GPU translation path, and per-game launchers."]
        ),
        SoftwareSampleProfile(
            id: "jasp-stats",
            name: "JASP 统计分析",
            publisher: "JASP Services B.V.",
            category: "Scientific / Industrial",
            purpose: "QtWebEngine statistics workstation coverage for QML startup, tables, plots, results pages, engine IPC, and large MSI installation.",
            installSource: .signedRecipe,
            catalogRecipeId: "jasp-stats",
            installerFileNames: ["JASP-0.97.1-Windows-Community.msi"],
            launcherCandidates: [
                "C:\\Program Files\\JASP\\JASPDesktop.exe",
                "C:\\Program Files\\JASP\\JASPEngine.exe"
            ],
            compatibilityProfileId: "jasp-qtwebengine-qrc",
            expectedIssueIds: ["qtwebengine-startup", "qml-resource", "engine-ipc", "large-installer", "qt-text"],
            recommendedProbeIds: ["00_console_probe", "10_tls_winhttp_probe", "70_text_rendering_probe", "80_window_input_probe", "90_ipc_file_mapping_probe"],
            environment: [
                "MACWIN_JASP_WEBENGINE_MODE": "multiprocess",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0"
            ],
            warnings: [
                "The current verified smoke path reaches JASP Desktop started, QML Initialized, Results page loaded, and JASP IPC heartbeat milestones.",
                "R modules, network downloads, and every statistical analysis require separate validation."
            ]
        ),
        SoftwareSampleProfile(
            id: "itch",
            name: "itch.io 游戏市场",
            publisher: "itch.io",
            category: "Game Store",
            purpose: "Electron shell, web login, embedded downloads, and blank-window regression coverage.",
            installSource: .localInstaller,
            installerFileNames: ["itch-setup-windows-amd64.exe", "itch-setup.exe", "itchSetup.exe"],
            launcherCandidates: [
                "C:\\Users\\%USERNAME%\\AppData\\Local\\itch\\app-26.13.0\\itch.exe",
                "C:\\Users\\%USERNAME%\\AppData\\Local\\itch\\itch.exe",
                "C:\\Program Files\\itch\\itch.exe"
            ],
            compatibilityProfileId: "cef-software-renderer",
            expectedIssueIds: ["electron-blank-window", "stdout-ebadf", "webview-text"],
            recommendedProbeIds: ["70_text_rendering_probe", "80_window_input_probe", "10_tls_winhttp_probe"],
            environment: [
                "ELECTRON_ENABLE_LOGGING": "1",
                "ELECTRON_FORCE_IS_PACKAGED": "1",
                "MACWIN_WEBVIEW_SOFTWARE_RENDERER": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "ROSETTA_X87_PATH": ""
            ],
            warnings: ["Use a local installer supplied by the user; MacWin should not redistribute itch binaries."]
        ),
        SoftwareSampleProfile(
            id: "lenovo-app-store",
            name: "联想应用商店",
            publisher: "Lenovo",
            category: "App Store",
            purpose: "Chromium app-store shell, helper crash, black-screen, and Chinese UI coverage.",
            installSource: .signedRecipe,
            catalogRecipeId: "lenovo-app-store",
            installerFileNames: ["LenovoAppStoreInstall.exe", "LeAppStoreInstall.exe"],
            launcherCandidates: [
                "C:\\Program Files (x86)\\Lenovo\\LeAppStore\\LenovoAppStore.exe",
                "C:\\Program Files (x86)\\Lenovo\\LeAppStore\\LeASLane.exe"
            ],
            compatibilityProfileId: "lenovo-app-store",
            expectedIssueIds: ["lenovo-black-screen", "leaslane-crash", "webview-text"],
            recommendedProbeIds: ["70_text_rendering_probe", "80_window_input_probe", "20_vulkan_probe"],
            environment: [
                "MACWIN_LENOVO_BLACK_SCREEN_REPAIR": "1",
                "MACWIN_DISABLE_WINE_D3D_CONFIG": "1",
                "MACWIN_WEBVIEW_SOFTWARE_RENDERER": "1"
            ],
            warnings: ["Uses a local installer selected by the user and validated by SHA-256; MacWin does not redistribute Lenovo binaries."]
        ),
        SoftwareSampleProfile(
            id: "tencent-app-store",
            name: "应用宝 / 腾讯应用市场",
            publisher: "Tencent",
            category: "App Store",
            purpose: "Chinese app-store installer, WebView login, download manager, and legacy 32-bit helper coverage.",
            installSource: .localInstaller,
            installerFileNames: [
                "pcmgr.exe",
                "pcyyb.exe",
                "yingyongbao.exe",
                "TencentAppStore.exe",
                "Tencent_PCManager_Setup.exe",
                "QQPCMgr_Setup.exe",
                "QQPhoneManager.exe",
                "应用宝.exe",
                "应用宝安装器.exe",
                "腾讯应用宝.exe"
            ],
            launcherCandidates: [
                "C:\\Program Files (x86)\\Tencent\\QQPCMgr\\QQPCMgr.exe",
                "C:\\Program Files (x86)\\Tencent\\AppStore\\AppStore.exe",
                "C:\\Program Files\\Tencent\\Androws\\Application\\AndrowsLauncher.exe",
                "C:\\Program Files\\Tencent\\Androws\\Application\\5.10.6400.6084\\AndrowsStore.exe",
                "C:\\Program Files\\Tencent\\Androws\\Application\\5.10.6400.6084\\AndrowsLauncher.exe"
            ],
            compatibilityProfileId: "cef-software-renderer",
            expectedIssueIds: ["webview-text", "wow64-helper", "network-tls"],
            recommendedProbeIds: ["10_tls_winhttp_probe", "10_tls_winhttp_probe_32", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "MACWIN_WEBVIEW_SOFTWARE_RENDERER": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["Use local installers only; do not bypass Tencent account, download, DRM, or security flows."]
        ),
        SoftwareSampleProfile(
            id: "portableapps-platform",
            name: "PortableApps.com Platform",
            publisher: "PortableApps.com",
            category: "App Store",
            purpose: "Portable app catalog, updater, download manager, file dialogs, and ordinary Win32 UI coverage.",
            installSource: .signedRecipe,
            catalogRecipeId: "portableapps-platform",
            installerFileNames: [
                "PortableApps.com_Platform_Setup.exe",
                "PortableApps.com_Platform_Setup.paf.exe"
            ],
            launcherCandidates: [
                "C:\\PortableApps\\PortableApps.com\\PortableAppsPlatform.exe",
                "C:\\Program Files\\PortableApps.com\\PortableAppsPlatform.exe"
            ],
            compatibilityProfileId: "portableapps-platform",
            expectedIssueIds: ["download-manager", "file-dialog", "network-tls", "wow64-theme"],
            recommendedProbeIds: ["10_tls_winhttp_probe", "10_tls_winhttp_probe_32", "15_iphlpapi_probe_32", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "MACWIN_PORTABLEAPPS_PLATFORM_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "WINEDLLOVERRIDES": "winemenubuilder.exe=d;uxtheme=d"
            ],
            warnings: [
                "Uses a local installer selected by the user and validated by SHA-256; MacWin does not redistribute PortableApps binaries.",
                "Current Wine 11.11 WoW64 testing verifies PortableAppsPlatform.exe with the portableapps-platform profile; keep Backup/Updater helper results separate from the main Platform GUI signal."
            ]
        ),
        SoftwareSampleProfile(
            id: "npackd",
            name: "Npackd",
            publisher: "Npackd",
            category: "Package Manager",
            purpose: "Open package manager sample for download flows, large lists, TLS, archives, and installer orchestration.",
            installSource: .localInstaller,
            installerFileNames: [
                "Npackd64.zip",
                "Npackd64-1.26.9.zip",
                "NpackdSetup.exe"
            ],
            launcherCandidates: [
                "C:\\macwin-portable\\npackd\\npackdg.exe",
                "C:\\Program Files\\Npackd\\Npackd.exe",
                "C:\\Program Files\\NpackdCL\\NpackdCL.exe"
            ],
            compatibilityProfileId: "qt-widgets-software",
            expectedIssueIds: ["archive-installer", "network-tls", "list-rendering"],
            recommendedProbeIds: ["10_tls_winhttp_probe", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "LANG": "zh_CN.UTF-8",
                "LC_ALL": "zh_CN.UTF-8",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "ROSETTA_X87_PATH": "",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0"
            ],
            warnings: ["The curated ZIP is extracted into the bottle before launcher scanning; package installation results still depend on each upstream package recipe."]
        ),
        SoftwareSampleProfile(
            id: "chrome-enterprise",
            name: "Google Chrome Enterprise",
            publisher: "Google",
            category: "Browser",
            purpose: "Modern Chromium browser coverage for GPU compositing, sandbox startup, TLS, fonts, IME, and web video paths.",
            installSource: .localInstaller,
            installerFileNames: ["GoogleChromeStandaloneEnterprise64.msi"],
            launcherCandidates: [
                "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
                "C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe"
            ],
            compatibilityProfileId: "chromium-browser",
            expectedIssueIds: ["chromium-gpu", "webview-text", "network-tls", "sandbox-helper"],
            recommendedProbeIds: ["10_tls_winhttp_probe", "20_vulkan_probe", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "MACWIN_CHROMIUM_BROWSER_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["Use local enterprise/offline installers only; browser sign-in, DRM, Widevine, and updater behavior may remain host-dependent."]
        ),
        SoftwareSampleProfile(
            id: "firefox-browser",
            name: "Mozilla Firefox",
            publisher: "Mozilla",
            category: "Browser",
            purpose: "Gecko browser coverage for non-Chromium rendering, TLS, fonts, IME, file picker, and updater behavior.",
            installSource: .localInstaller,
            catalogRecipeId: "firefox",
            installerFileNames: [
                "Firefox_Setup_152.0.1.exe",
                "Firefox_Setup_152.0.1.msi",
                "Firefox_ESR_Setup.exe"
            ],
            launcherCandidates: [
                "C:\\Program Files\\Mozilla Firefox\\firefox.exe",
                "C:\\Program Files (x86)\\Mozilla Firefox\\firefox.exe"
            ],
            compatibilityProfileId: "browser-gecko",
            expectedIssueIds: ["gecko-rendering", "font-fallback", "network-tls", "file-dialog"],
            recommendedProbeIds: ["10_tls_winhttp_probe", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["Use local offline/MSI installers; media DRM and browser updater flows are compatibility targets, not guaranteed pass criteria."]
        ),
        SoftwareSampleProfile(
            id: "brave-browser",
            name: "Brave Browser",
            publisher: "Brave Software",
            category: "Browser",
            purpose: "Chromium-derived browser sample for web UI, GPU blacklist behavior, updater bootstrap, and browser profile creation.",
            installSource: .localInstaller,
            installerFileNames: [
                "BraveBrowserSetup_1.58.137.exe",
                "BraveBrowserStandaloneSetup.exe",
                "BraveBrowserStandaloneSetup32.exe"
            ],
            launcherCandidates: [
                "C:\\Program Files\\BraveSoftware\\Brave-Browser\\Application\\brave.exe",
                "C:\\Program Files (x86)\\BraveSoftware\\Brave-Browser\\Application\\brave.exe"
            ],
            compatibilityProfileId: "chromium-browser",
            expectedIssueIds: ["chromium-gpu", "webview-text", "network-tls", "updater-bootstrap"],
            recommendedProbeIds: ["10_tls_winhttp_probe", "20_vulkan_probe", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "MACWIN_CHROMIUM_BROWSER_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["Network installer behavior can change; prefer cached installers when reproducing compatibility results."]
        ),
        SoftwareSampleProfile(
            id: "edge-enterprise",
            name: "Microsoft Edge Enterprise",
            publisher: "Microsoft",
            category: "Browser",
            purpose: "Chromium enterprise MSI coverage for updater services, WebView-style rendering, certificate stores, fonts, and GPU fallback.",
            installSource: .localInstaller,
            installerFileNames: ["MicrosoftEdgeEnterpriseX64.msi"],
            launcherCandidates: [
                "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
                "C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe"
            ],
            compatibilityProfileId: "chromium-browser",
            expectedIssueIds: ["chromium-gpu", "webview-text", "network-tls", "updater-bootstrap"],
            recommendedProbeIds: ["10_tls_winhttp_probe", "20_vulkan_probe", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "MACWIN_CHROMIUM_BROWSER_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["Enterprise MSI tests installer services and updater behavior; account sync, DRM, and Windows-integrated policies are out of automated scope."]
        ),
        SoftwareSampleProfile(
            id: "opera-browser",
            name: "Opera Browser",
            publisher: "Opera",
            category: "Browser",
            purpose: "Chromium online installer coverage for TLS, updater bootstrap, web UI text, GPU fallback, profile creation, and windowing.",
            installSource: .localInstaller,
            installerFileNames: ["Opera_132.0.5905.73_Setup_x64.exe", "OperaSetup.exe"],
            launcherCandidates: [
                "C:\\macwin-portable\\opera-browser\\opera.exe",
                "C:\\Program Files\\Opera\\opera.exe",
                "C:\\Users\\%USERNAME%\\AppData\\Local\\Programs\\Opera\\opera.exe"
            ],
            compatibilityProfileId: "chromium-browser",
            expectedIssueIds: ["chromium-gpu", "webview-text", "network-tls", "updater-bootstrap"],
            recommendedProbeIds: ["10_tls_winhttp_probe", "20_vulkan_probe", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "MACWIN_CHROMIUM_BROWSER_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["This is an online installer sample; keep logs because failures may be network, certificate, or subprocess related."]
        ),
        SoftwareSampleProfile(
            id: "privacy-browser-pack",
            name: "Vivaldi / LibreWolf",
            publisher: "Vivaldi Technologies / LibreWolf",
            category: "Browser",
            purpose: "Additional browser coverage for dense Chromium UI, Gecko rendering, portable archives, updater differences, fonts, TLS, and profile creation.",
            installSource: .localInstaller,
            installerFileNames: [
                "Vivaldi.7.9.3970.47.x64.exe",
                "librewolf-152.0.1-2-windows-x86_64-setup.exe",
                "librewolf-152.0.1-2-windows-x86_64-portable.zip",
                "floorp-windows-x86_64.installer.exe"
            ],
            launcherCandidates: [
                "C:\\Program Files\\Vivaldi\\Application\\vivaldi.exe",
                "C:\\Users\\%USERNAME%\\AppData\\Local\\Vivaldi\\Application\\vivaldi.exe",
                "C:\\Program Files\\LibreWolf\\librewolf.exe",
                "C:\\Program Files\\LibreWolf\\LibreWolf.exe",
                "C:\\Program Files\\Floorp\\floorp.exe",
                "C:\\Program Files\\Ablaze Floorp\\floorp.exe"
            ],
            compatibilityProfileId: "browser-gecko",
            expectedIssueIds: ["chromium-gpu", "gecko-rendering", "font-fallback", "network-tls", "archive-installer"],
            recommendedProbeIds: ["10_tls_winhttp_probe", "20_vulkan_probe", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "MACWIN_WEBVIEW_SOFTWARE_RENDERER": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["Portable archive samples may need extraction before launcher scanning; browser account sync, DRM, and updater tasks are not pass criteria."]
        ),
        SoftwareSampleProfile(
            id: "thunderbird-mail",
            name: "Mozilla Thunderbird",
            publisher: "Mozilla",
            category: "Office / Mail",
            purpose: "Mail client sample for Gecko UI, profile storage, TLS, certificate dialogs, IME, fonts, and attachment file pickers.",
            installSource: .localInstaller,
            installerFileNames: ["Thunderbird-latest-win64-zhCN.exe"],
            launcherCandidates: [
                "C:\\Program Files\\Mozilla Thunderbird\\thunderbird.exe",
                "C:\\Program Files (x86)\\Mozilla Thunderbird\\thunderbird.exe"
            ],
            compatibilityProfileId: "browser-gecko",
            expectedIssueIds: ["gecko-rendering", "certificate-dialog", "font-fallback", "file-dialog"],
            recommendedProbeIds: ["10_tls_winhttp_probe", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["Do not use real mail accounts during automated smoke runs; manual account login remains out of scope for unattended tests."]
        ),
        SoftwareSampleProfile(
            id: "libreoffice-suite",
            name: "LibreOffice",
            publisher: "The Document Foundation",
            category: "Office Suite",
            purpose: "Large MSI office suite coverage for document windows, fonts, CJK text, file dialogs, OLE-style integration, and printing code paths.",
            installSource: .localInstaller,
            catalogRecipeId: "libreoffice",
            installerFileNames: [
                "LibreOffice_26.2.4_Win_x86-64.msi",
                "LibreOffice_26.2.4_Win_x86-64_helppack_zh-CN.msi"
            ],
            launcherCandidates: [
                "C:\\Program Files\\LibreOffice\\program\\soffice.exe",
                "C:\\Program Files\\LibreOffice\\program\\swriter.exe",
                "C:\\Program Files\\LibreOffice\\program\\scalc.exe"
            ],
            compatibilityProfileId: "office-suite",
            expectedIssueIds: ["msi-large-install", "font-fallback", "file-dialog", "printing"],
            recommendedProbeIds: ["70_text_rendering_probe", "80_window_input_probe", "10_tls_winhttp_probe"],
            environment: [
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["Treat help pack installation as optional; first smoke pass should validate Writer/Calc launch and CJK text display."]
        ),
        SoftwareSampleProfile(
            id: "onlyoffice-suite",
            name: "ONLYOFFICE Desktop Editors",
            publisher: "ONLYOFFICE",
            category: "Office Suite",
            purpose: "Electron/Chromium office suite coverage for large installer startup, document canvas rendering, GPU fallback, fonts, and file dialogs.",
            installSource: .localInstaller,
            installerFileNames: ["OnlyOfficeDesktopEditors-x64.exe"],
            launcherCandidates: [
                "C:\\Program Files\\ONLYOFFICE\\DesktopEditors\\DesktopEditors.exe",
                "C:\\Program Files\\ONLYOFFICE\\DesktopEditors\\editors.exe",
                "C:\\Program Files (x86)\\ONLYOFFICE\\DesktopEditors\\DesktopEditors.exe",
                "C:\\Program Files (x86)\\ONLYOFFICE\\DesktopEditors\\editors.exe"
            ],
            compatibilityProfileId: "cef-software-renderer",
            expectedIssueIds: ["electron-blank-window", "webview-text", "font-fallback", "file-dialog"],
            recommendedProbeIds: ["70_text_rendering_probe", "80_window_input_probe", "20_vulkan_probe"],
            environment: [
                "MACWIN_WEBVIEW_SOFTWARE_RENDERER": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "PATH": "C:\\Program Files\\ONLYOFFICE\\DesktopEditors\\converter;C:\\Program Files\\ONLYOFFICE\\DesktopEditors;C:\\windows\\system32;C:\\windows;C:\\windows\\system32\\wbem;C:\\windows\\system32\\WindowsPowershell\\v1.0"
            ],
            warnings: ["First pass should validate local document creation/opening, not cloud login or collaborative services."]
        ),
        SoftwareSampleProfile(
            id: "wps-office",
            name: "WPS Office",
            publisher: "Kingsoft",
            category: "Office Suite",
            purpose: "Chinese office coverage for document canvas rendering, CJK fonts, IME, printing, file dialogs, and the proprietary Qt runtime.",
            installSource: .localInstaller,
            installerFileNames: [
                "WPSOffice-offline.exe"
            ],
            launcherCandidates: [
                "C:\\Program Files\\Kingsoft\\WPS Office\\12.1.0.27458\\office6\\wps.exe",
                "C:\\Program Files\\Kingsoft\\WPS Office\\12.1.0.27458\\office6\\et.exe",
                "C:\\Program Files\\Kingsoft\\WPS Office\\12.1.0.27458\\office6\\wpp.exe",
                "C:\\Program Files\\Kingsoft\\WPS Office\\12.1.0.27458\\office6\\wpspdf.exe"
            ],
            compatibilityProfileId: "wps-office",
            expectedIssueIds: ["qt-installer-stall", "font-fallback", "ime-input", "file-dialog", "printing"],
            recommendedProbeIds: ["70_text_rendering_probe", "80_window_input_probe", "10_tls_winhttp_probe"],
            environment: [
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "MACWIN_WPS_OFFICE_REPAIR": "1",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0"
            ],
            warnings: ["The current WPS Qt installer stalls under Wine; MacWin verifies the official offline package and deploys its signed packet payloads directly."]
        ),
        SoftwareSampleProfile(
            id: "office-publishing-pack",
            name: "Thunderbird / Scribus",
            publisher: "Mozilla / Scribus",
            category: "Office / Publishing",
            purpose: "Mail, page layout, PDF/prepress, font fallback, CJK text, TLS/certificate dialogs, file pickers, and print-oriented UI coverage.",
            installSource: .localInstaller,
            installerFileNames: [
                "Thunderbird-latest-win64-zhCN.exe",
                "Scribus-1.4.8-windows-x64.exe",
                "install-tl-windows.exe"
            ],
            launcherCandidates: [
                "C:\\Program Files\\Mozilla Thunderbird\\thunderbird.exe",
                "C:\\Program Files\\Scribus 1.4.8\\Scribus.exe",
                "C:\\Program Files\\Scribus 1.4.8\\scribus.exe",
                "C:\\texlive\\2026\\bin\\windows\\tlmgr-gui.exe",
                "C:\\texlive\\2026\\bin\\windows\\texworks.exe"
            ],
            compatibilityProfileId: "office-suite",
            expectedIssueIds: ["gecko-rendering", "font-fallback", "certificate-dialog", "file-dialog", "printing"],
            recommendedProbeIds: ["10_tls_winhttp_probe", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["Do not use real mail accounts in automated tests; validate launch, text, file dialogs, and document/page rendering first."]
        ),
        SoftwareSampleProfile(
            id: "productivity-document-pack",
            name: "draw.io / Joplin / Obsidian / calibre / PDF Tools",
            publisher: "JGraph / Joplin / Obsidian / calibre / SumatraPDF / PDFsam",
            category: "Office / Productivity",
            purpose: "Knowledge-work coverage for Electron canvases, Markdown editors, ebook/PDF viewers, Java UI, PDF annotation, file dialogs, clipboard, fonts, and local profile storage.",
            installSource: .localInstaller,
            installerFileNames: [
                "draw.io-30.2.4.msi",
                "Joplin-Setup-3.6.15.exe",
                "Freeplane-Setup-1.13.2.exe",
                "xournalpp-1.3.5-windows-setup-AMD64.exe",
                "pdfsam-basic-6.0.1-windows-x64.msi",
                "Obsidian-1.12.7.exe",
                "calibre-64bit-9.9.0.msi",
                "SumatraPDF-3.6.1-64-install.exe",
                "Zotero-Windows-latest.exe"
            ],
            launcherCandidates: [
                "C:\\Program Files\\draw.io\\draw.io.exe",
                "C:\\Users\\%USERNAME%\\AppData\\Local\\Programs\\Joplin\\Joplin.exe",
                "C:\\Program Files\\Freeplane\\freeplane.exe",
                "C:\\Program Files\\Xournal++\\bin\\xournalpp.exe",
                "C:\\Program Files\\PDFsam Basic\\pdfsam.exe",
                "C:\\Users\\%USERNAME%\\AppData\\Local\\Obsidian\\Obsidian.exe",
                "C:\\Program Files\\Calibre2\\calibre.exe",
                "C:\\Program Files\\SumatraPDF\\SumatraPDF.exe",
                "C:\\Program Files\\Zotero\\zotero.exe"
            ],
            compatibilityProfileId: "office-suite",
            expectedIssueIds: ["electron-blank-window", "java-runtime", "gtk-text", "font-fallback", "file-dialog", "clipboard", "printing"],
            recommendedProbeIds: ["10_tls_winhttp_probe", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "MACWIN_WEBVIEW_SOFTWARE_RENDERER": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["Electron and Java apps should be tested with local files first; cloud sync/login is manual scope."]
        ),
        SoftwareSampleProfile(
            id: "developer-toolchain",
            name: "Developer Toolchain Pack",
            publisher: "Microsoft / Git / Notepad++ / PuTTY / KeePass",
            category: "Developer Tools",
            purpose: "Representative developer tools for installers, terminal/console behavior, SSH dialogs, file associations, secure text controls, and editor rendering.",
            installSource: .localInstaller,
            installerFileNames: [
                "Git-2.54.0-64-bit.exe",
                "VSCodeUserSetup-x64-1.125.1.exe",
                "VSCode-win32-x64-1.125.1.zip",
                "Postman-win64-latest.exe",
                "npp.8.9.6.4.Installer.x64.exe",
                "putty-64bit-installer.msi",
                "KeePass-2.59-Setup.exe",
                "WinSCP-6.5.6-Setup.exe",
                "WinSCP-6.6.2.RC-Portable-x64-Experimental.zip",
                "wix-cli-x64.msi"
            ],
            launcherCandidates: [
                "C:\\Program Files\\Git\\git-bash.exe",
                "C:\\Users\\%USERNAME%\\AppData\\Local\\Programs\\Microsoft VS Code\\Code.exe",
                "C:\\macwin-portable\\vscode\\Code.exe",
                "C:\\Users\\%USERNAME%\\AppData\\Local\\Postman\\Postman.exe",
                "C:\\Program Files\\Notepad++\\notepad++.exe",
                "C:\\Program Files\\PuTTY\\putty.exe",
                "C:\\Program Files\\KeePass Password Safe 2\\KeePass.exe",
                "C:\\Program Files (x86)\\WinSCP\\WinSCP.exe",
                "C:\\macwin-portable\\winscp-x64-portable\\WinSCP.exe",
                "C:\\Program Files\\WiX Toolset v7\\bin\\wix.exe"
            ],
            compatibilityProfileId: "developer-tools",
            expectedIssueIds: ["console-pseudo-terminal", "electron-blank-window", "network-tls", "file-dialog", "dotnet-winforms"],
            recommendedProbeIds: ["00_console_probe", "10_tls_winhttp_probe", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "MACWIN_WEBVIEW_SOFTWARE_RENDERER": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["Do not use real SSH credentials in automated runs; validate UI launch and local console behavior first.", "WinSCP stable 32-bit VCL GUI is validated with the managed rosettax87 runtime; keep the x64 portable build as the preferred CLI and fallback GUI target."]
        ),
        SoftwareSampleProfile(
            id: "database-developer-pack",
            name: "DBeaver / Beekeeper Studio / SQLite Browser / GitExtensions / x64dbg / mRemoteNG",
            publisher: "DBeaver / Beekeeper Studio / SQLite Browser / GitExtensions / x64dbg / mRemoteNG",
            category: "Developer / Industrial Tools",
            purpose: "Database, debugger, remote-manager, and .NET/WinForms coverage for large tables, process launching, credential dialogs, tree views, TLS drivers, and portable zip flows.",
            installSource: .localInstaller,
            installerFileNames: [
                "dbeaver-ce-latest-x86_64-setup.exe",
                "Beekeeper-Studio-Setup-5.8.1.exe",
                "DB.Browser.for.SQLite-v3.13.1-win64.msi",
                "pgadmin4-9.16-x64.exe",
                "GitExtensions-x64-7.0.1.86-c119a52.msi",
                "snapshot_2026-05-27_12-11.zip",
                "mRemoteNG-Installer-1.76.20.24615.msi",
                "mRemoteNG-20260222-v1.78.2-NB-3405-x64.rar",
                "dotnet-runtime-10.0.9-win-x64.zip",
                "windowsdesktop-runtime-10.0.9-win-x64.zip"
            ],
            launcherCandidates: [
                "C:\\Program Files\\DBeaver\\dbeaver.exe",
                "C:\\Users\\%USERNAME%\\AppData\\Local\\Programs\\beekeeper-studio\\Beekeeper Studio.exe",
                "C:\\Program Files\\DB Browser for SQLite\\DB Browser for SQLite.exe",
                "C:\\Users\\%USERNAME%\\AppData\\Local\\Programs\\pgAdmin 4\\runtime\\pgAdmin4.exe",
                "C:\\Program Files\\pgAdmin 4\\runtime\\pgAdmin4.exe",
                "C:\\Program Files\\GitExtensions\\GitExtensions.exe",
                "C:\\macwin-portable\\x64dbg\\release\\x64\\x64dbg.exe",
                "C:\\Program Files (x86)\\mRemoteNG\\mRemoteNG.exe",
                "C:\\macwin-portable\\mremoteng-1782-x64\\mRemoteNG.exe"
            ],
            compatibilityProfileId: "developer-tools",
            expectedIssueIds: ["java-runtime", "electron-blank-window", "dotnet-winforms", "dotnet-runtime", "debug-api", "network-tls", "archive-installer"],
            recommendedProbeIds: ["00_console_probe", "10_tls_winhttp_probe", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "MACWIN_WEBVIEW_SOFTWARE_RENDERER": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["Do not store real database, SSH, RDP, or debugger credentials in automated bottles.", "mRemoteNG 1.76.x is a 32-bit .NET Framework sample that currently crashes inside Wine-Mono before managed exceptions are emitted; mRemoteNG 1.78.2 x64 avoids that Wine-Mono crash and launches when dotnet-runtime-10.0.9-win-x64.zip plus windowsdesktop-runtime-10.0.9-win-x64.zip are deployed through DOTNET_ROOT_X64."]
        ),
        SoftwareSampleProfile(
            id: "freecad-workbench",
            name: "FreeCAD",
            publisher: "FreeCAD",
            category: "Industrial CAD",
            purpose: "CAD workbench coverage for Qt, OpenGL/Vulkan translation, Python runtime, large installer paths, menus, and 3D viewport interaction.",
            installSource: .localInstaller,
            installerFileNames: ["FreeCAD_1.1.1-Windows-x86_64-py311-installer.exe"],
            launcherCandidates: [
                "C:\\Program Files\\FreeCAD 1.1\\bin\\FreeCAD.exe",
                "C:\\Program Files\\FreeCAD\\bin\\FreeCAD.exe"
            ],
            compatibilityProfileId: "qt-opengl-cad",
            expectedIssueIds: ["opengl-viewport", "qt-text", "python-runtime", "large-installer"],
            recommendedProbeIds: ["20_vulkan_probe", "30_d3d11_probe", "60_game_shader_probe", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "MACWIN_GRAPHICS_PRESET": "vulkan",
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["Viewport correctness is the key signal; installer success alone is not enough for CAD compatibility."]
        ),
        SoftwareSampleProfile(
            id: "openplc-editor",
            name: "OpenPLC Editor",
            publisher: "Autonomy Logic",
            category: "Industrial Automation",
            purpose: "IEC 61131-3 editor coverage for Electron rendering, PLCopen XML conversion, Structured Text compilation, generated C++ semantics, and Arduino CLI integration.",
            installSource: .localInstaller,
            installerFileNames: ["OpenPLC.Editor_4.2.7.exe"],
            launcherCandidates: [
                "C:\\macwin-portable\\openplc-editor\\OpenPLC Editor.exe",
                "C:\\Program Files\\OpenPLC Editor\\OpenPLC Editor.exe"
            ],
            compatibilityProfileId: "openplc-electron",
            expectedIssueIds: ["electron-blank-window", "invalid-timezone", "chromium-compositor", "plc-compiler-toolchain"],
            recommendedProbeIds: ["00_console_probe", "10_tls_winhttp_probe", "30_d3d11_probe", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "MACWIN_OPENPLC_ELECTRON_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "TZ": "Asia/Shanghai"
            ],
            warnings: [
                "The verified renderer keeps Chromium's GPU work in-process and uses ANGLE SwiftShader because the default Electron GPU subprocess does not present its front buffer through the current Wine macOS driver.",
                "Compiler acceptance requires the PLCopen XML to Structured Text to STruC++ to native semantic-probe pipeline; a visible home page alone is not sufficient."
            ]
        ),
        SoftwareSampleProfile(
            id: "energyplus-building",
            name: "EnergyPlus 26.1",
            publisher: "U.S. Department of Energy / NLR",
            category: "Industrial Simulation",
            purpose: "Building-energy simulation coverage for QtIFW installation, large scientific payloads, weather and IDF file paths, native numerical runtimes, and deterministic annual calculation output.",
            installSource: .localInstaller,
            installerFileNames: ["EnergyPlus-26.1.0-6f2e40d102-Windows-x86_64.exe"],
            launcherCandidates: [
                "C:\\EnergyPlusV26-1-0\\energyplus.exe",
                "C:\\EnergyPlusV26-1-0\\windows_gui_launcher.exe"
            ],
            compatibilityProfileId: "scientific-cli",
            expectedIssueIds: ["qtifw-installer", "legacy-activex", "scientific-runtime", "windows-paths"],
            recommendedProbeIds: ["00_console_probe", "10_tls_winhttp_probe", "70_text_rendering_probe"],
            environment: [
                "PATH": "C:\\EnergyPlusV26-1-0;C:\\EnergyPlusV26-1-0\\PostProcess;C:\\windows\\system32;C:\\windows"
            ],
            warnings: [
                "The core energyplus.exe annual simulation is validated. QtIFW may skip optional legacy Graph32 ActiveX registration and Windows shortcut creation because they are not required by the simulation engine."
            ]
        ),
        SoftwareSampleProfile(
            id: "cad-lightweight-pack",
            name: "LibreCAD / OpenSCAD / QCad",
            publisher: "LibreCAD / OpenSCAD / QCad",
            category: "Industrial CAD",
            purpose: "Lightweight CAD coverage for Qt widgets, script editors, font rendering, 2D drawing surfaces, and OpenGL preview paths.",
            installSource: .localInstaller,
            installerFileNames: [
                "LibreCAD-v2.2.1.5-win64-msvc.exe",
                "OpenSCAD-2021.01-x86-64-Installer.exe",
                "QCad-2.0.5.0-Installer.exe",
                "SweetHome3D-7.5-windows.exe"
            ],
            launcherCandidates: [
                "C:\\Program Files\\LibreCAD\\LibreCAD.exe",
                "C:\\Program Files\\OpenSCAD\\openscad.exe",
                "C:\\Program Files (x86)\\QCad\\qcad.exe",
                "C:\\Program Files\\Sweet Home 3D\\SweetHome3D.exe"
            ],
            compatibilityProfileId: "qt-opengl-cad",
            expectedIssueIds: ["qt-text", "opengl-viewport", "file-dialog"],
            recommendedProbeIds: ["20_vulkan_probe", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "MACWIN_GRAPHICS_PRESET": "vulkan",
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["Run both 2D drawing and 3D preview smoke checks; they exercise different rendering paths."]
        ),
        SoftwareSampleProfile(
            id: "electrical-parametric-cad-pack",
            name: "SolveSpace / QElectroTech",
            publisher: "SolveSpace / QElectroTech",
            category: "Industrial CAD",
            purpose: "Small industrial CAD extension pack for parametric constraints, electrical schematic libraries, Qt widgets, OpenGL viewports, project trees, and file dialogs.",
            installSource: .localInstaller,
            installerFileNames: [
                "SolveSpace-3.2-x64.exe",
                "Installer_QElectroTech-0.100.0_x86_64-win64.exe"
            ],
            launcherCandidates: [
                "C:\\Program Files\\SolveSpace\\solvespace.exe",
                "C:\\macwin-portable\\solvespace\\SolveSpace-3.2-x64.exe",
                "C:\\Program Files\\QElectroTech\\qelectrotech.exe"
            ],
            compatibilityProfileId: "qt-opengl-cad",
            expectedIssueIds: ["opengl-viewport", "qt-text", "file-dialog", "single-exe-launch"],
            recommendedProbeIds: ["20_vulkan_probe", "60_game_shader_probe", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "MACWIN_GRAPHICS_PRESET": "vulkan",
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["SolveSpace can run as a no-installer executable; launcher creation should support direct EXE registration."]
        ),
        SoftwareSampleProfile(
            id: "creative-workstation-pack",
            name: "Blender / GIMP / Inkscape / Audacity",
            publisher: "Blender Foundation / GIMP / Inkscape / Audacity",
            category: "Creative Workstation",
            purpose: "Creative suite coverage for OpenGL viewport, GTK UI, audio device enumeration, font rendering, plug-ins, and large asset dialogs.",
            installSource: .localInstaller,
            installerFileNames: [
                "blender-4.1.0-windows-x64.msi",
                "GIMP-2.10.38-win64-setup.exe",
                "gimp-2.10.38-setup-1.exe",
                "audacity-win-3.7.8-64bit.exe",
                "Inkscape-1.4.2-x64.msi"
            ],
            launcherCandidates: [
                "C:\\Program Files\\Blender Foundation\\Blender 4.1\\blender.exe",
                "C:\\Program Files\\GIMP 2\\bin\\gimp-2.10.exe",
                "C:\\Program Files\\Audacity\\Audacity.exe",
                "C:\\Program Files\\Inkscape\\bin\\inkscape.exe"
            ],
            compatibilityProfileId: "creative-opengl-audio",
            expectedIssueIds: ["opengl-viewport", "gtk-text", "xaudio-device", "file-dialog"],
            recommendedProbeIds: ["20_vulkan_probe", "50_xaudio2_probe", "60_game_shader_probe", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "MACWIN_GRAPHICS_PRESET": "vulkan",
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["Validate launch and a simple viewport/audio-device action before deeper plug-in testing."]
        ),
        SoftwareSampleProfile(
            id: "creative-extended-pack",
            name: "Krita / MuseScore / Flameshot / Moonlight",
            publisher: "Krita / MuseScore / Flameshot / Moonlight",
            category: "Creative / Media",
            purpose: "Extended creative and media coverage for Qt canvas rendering, audio/MIDI-adjacent paths, tray/global-shortcut behavior, video streaming UI, controller input, and OpenGL/GPU fallback.",
            installSource: .localInstaller,
            installerFileNames: [
                "krita-x64-5.2.9-setup.exe",
                "MuseScore-Studio-4.7.3.260608135-x86_64.msi",
                "Flameshot-14.0.0-win64.msi",
                "MoonlightSetup-6.1.0.exe"
            ],
            launcherCandidates: [
                "C:\\Program Files\\Krita (x64)\\bin\\krita.exe",
                "C:\\Program Files\\MuseScore 4\\bin\\MuseScore4.exe",
                "C:\\Program Files\\Flameshot\\bin\\flameshot.exe",
                "C:\\Program Files\\Moonlight Game Streaming\\Moonlight.exe"
            ],
            compatibilityProfileId: "qt-opengl-media",
            expectedIssueIds: ["opengl-viewport", "qt-text", "xaudio-device", "media-device", "tray-integration", "controller-input"],
            recommendedProbeIds: ["20_vulkan_probe", "50_xaudio2_probe", "60_game_shader_probe", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "MACWIN_GRAPHICS_PRESET": "vulkan",
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["Global shortcuts, tray capture, host video decode, and controller passthrough are manual compatibility checks."]
        ),
        SoftwareSampleProfile(
            id: "maker-streaming-pack",
            name: "PrusaSlicer / Cura / OrcaSlicer / LaserGRBL / OBS Studio",
            publisher: "Prusa Research / UltiMaker / OrcaSlicer / LaserGRBL / OBS Project",
            category: "Maker / Streaming",
            purpose: "3D-print slicing, CNC control, and streaming samples for OpenGL preview, serial-port UI, media device enumeration, GPU capture fallbacks, and complex Qt/WinForms UI.",
            installSource: .localInstaller,
            installerFileNames: [
                "PrusaSlicer-2.9.5-setup.exe",
                "UltiMaker-Cura-5.13.0-win64-X64.msi",
                "UltiMaker-Cura-5.13.0-win64-X64.exe",
                "OrcaSlicer_Windows_Installer_V2.4.0.exe",
                "LaserGRBL-install-7.14.1.exe",
                "OBS-Studio-32.1.2-Windows-x64-Installer.exe"
            ],
            launcherCandidates: [
                "C:\\Program Files\\Prusa3D\\PrusaSlicer\\prusa-slicer.exe",
                "C:\\Program Files\\UltiMaker Cura 5.13.0\\UltiMaker-Cura.exe",
                "C:\\Program Files\\OrcaSlicer\\orca-slicer.exe",
                "C:\\Program Files (x86)\\LaserGRBL\\LaserGRBL.exe",
                "C:\\Program Files\\obs-studio\\bin\\64bit\\obs64.exe"
            ],
            compatibilityProfileId: "qt-opengl-media",
            expectedIssueIds: ["opengl-viewport", "media-device", "qt-text", "gpu-capture", "serial-port", "dotnet-winforms"],
            recommendedProbeIds: ["20_vulkan_probe", "50_xaudio2_probe", "60_game_shader_probe", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "MACWIN_GRAPHICS_PRESET": "vulkan",
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["OBS capture/device tests are manual; automated smoke should only validate startup and settings UI rendering."]
        ),
        SoftwareSampleProfile(
            id: "engineering-workstation-pack",
            name: "KiCad / Arduino IDE / TeXstudio",
            publisher: "KiCad / Arduino / TeXstudio",
            category: "Engineering Workstation",
            purpose: "Engineering workstation coverage for EDA project UI, embedded IDE Electron windows, Qt6 editor rendering, file dialogs, and large installers.",
            installSource: .localInstaller,
            installerFileNames: [
                "Kicad-10.0.3-x86_64.exe",
                "arduino-ide_2.3.10_Windows_64bit.exe",
                "Texstudio-4.9.5-win-qt6-signed.exe",
                "LTspice64.msi",
                "GeoGebra-Windows-Installer.exe",
                "GeoGebraClassic5-Windows-Installer.exe",
                "librepcb-installer-2.1.1-windows-x86_64.exe"
            ],
            launcherCandidates: [
                "C:\\Program Files\\KiCad\\10.0\\bin\\kicad.exe",
                "C:\\Program Files\\Arduino IDE\\Arduino IDE.exe",
                "C:\\Program Files\\TeXstudio\\texstudio.exe",
                "C:\\Program Files\\ADI\\LTspice\\LTspice.exe",
                "C:\\Program Files\\GeoGebra Calculator Suite\\GeoGebra.exe",
                "C:\\Program Files (x86)\\GeoGebra 5.4\\GeoGebra.exe",
                "C:\\Program Files\\LibrePCB\\bin\\librepcb.exe",
                "C:\\Program Files\\LibrePCB\\librepcb.exe"
            ],
            compatibilityProfileId: "qt-opengl-cad",
            expectedIssueIds: ["qt-text", "electron-blank-window", "file-dialog", "large-installer", "opengl-viewport", "plot-rendering"],
            recommendedProbeIds: ["20_vulkan_probe", "70_text_rendering_probe", "80_window_input_probe", "10_tls_winhttp_probe"],
            environment: [
                "MACWIN_GRAPHICS_PRESET": "vulkan",
                "MACWIN_WEBVIEW_SOFTWARE_RENDERER": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["KiCad is a large installer; run it in an extended smoke suite, not the default quick pass.", "GeoGebra Calculator Suite / Classic 6 is currently a 32-bit Electron WOW64 regression sample; use GeoGebra Classic 5 for the verified geometry UI path."]
        ),
        SoftwareSampleProfile(
            id: "scientific-industrial-pack",
            name: "QGIS / Octave / Scilab / OpenModelica / OpenDSS / Stellarium / JASP",
            publisher: "QGIS / GNU Octave / Dassault Systèmes / Open Source Modelica Consortium / EPRI / Stellarium / JASP",
            category: "Scientific / Industrial",
            purpose: "Heavy engineering workload coverage for GIS, numerical computing, power-flow simulation, plotting, scientific visualization, statistics, Qt/Java/Python runtimes, large installers, and plugin-heavy UIs.",
            installSource: .localInstaller,
            installerFileNames: [
                "QGIS-OSGeo4W-3.44.11-1.msi",
                "Octave-11.3.0-w64-installer.exe",
                "Scilab-2026.1.0-x64.exe",
                "OpenModelica-v1.26.9-64bit.exe",
                "OpenDSSInstaller_1100_1.exe",
                "stellarium-26.1-qt6-win64.exe",
                "JASP-0.97.1-Windows-Community.msi",
                "RStudio-2025.09.0-387.exe",
                "Julia-1.12.2-win64.exe"
            ],
            launcherCandidates: [
                "C:\\Program Files\\QGIS 3.44.11\\bin\\qgis-bin.exe",
                "C:\\Program Files\\GNU Octave\\Octave-11.3.0\\mingw64\\bin\\octave-gui.exe",
                "C:\\Program Files\\scilab-2026.1.0\\bin\\WScilex.exe",
                "C:\\Program Files\\OpenModelica1.26.9-64bit\\bin\\OMEdit.exe",
                "C:\\Program Files\\OpenDSS\\OpenDSS.exe",
                "C:\\macwin-portable\\opendss-svn-x64\\OpenDSS.exe",
                "C:\\macwin-portable\\opendss-svn-x64\\OpenDSScmd.exe",
                "C:\\Program Files\\Stellarium\\stellarium.exe",
                "C:\\Program Files\\JASP\\JASP.exe",
                "C:\\Program Files\\RStudio\\rstudio.exe",
                "C:\\Users\\%USERNAME%\\AppData\\Local\\Programs\\RStudio\\rstudio.exe",
                "C:\\Program Files\\Julia-1.12.2\\bin\\julia.exe",
                "C:\\Users\\%USERNAME%\\AppData\\Local\\Programs\\Julia-1.12.2\\bin\\julia.exe"
            ],
            compatibilityProfileId: "qt-opengl-cad",
            expectedIssueIds: ["large-installer", "qt-text", "opengl-viewport", "python-runtime", "java-runtime", "file-dialog", "plot-rendering", "legacy-com", "numerical-output"],
            recommendedProbeIds: ["00_console_probe", "20_vulkan_probe", "60_game_shader_probe", "70_text_rendering_probe", "80_window_input_probe", "90_ipc_file_mapping_probe", "10_tls_winhttp_probe"],
            environment: [
                "MACWIN_GRAPHICS_PRESET": "vulkan",
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["QGIS and OpenModelica are huge installers; keep them in extended/manual industrial suites unless explicitly stress-testing the installer path.", "OpenDSS x64 command-line power flow is validated by voltage CSV values; COM automation and the interactive GUI remain separate compatibility checks."]
        ),
        SoftwareSampleProfile(
            id: "mesh-inspection-pack",
            name: "MeshLab",
            publisher: "CNR ISTI Visual Computing Lab",
            category: "Industrial 3D",
            purpose: "3D mesh inspection coverage for Qt, OpenGL viewport startup, model loading dialogs, shader paths, and large geometry rendering.",
            installSource: .localInstaller,
            installerFileNames: [
                "MeshLab2025.07-windows_x86_64.exe"
            ],
            launcherCandidates: [
                "C:\\Program Files\\VCG\\MeshLab\\meshlab.exe",
                "C:\\Program Files\\MeshLab\\meshlab.exe"
            ],
            compatibilityProfileId: "qt-opengl-cad",
            expectedIssueIds: ["opengl-viewport", "qt-text", "file-dialog", "shader-compile"],
            recommendedProbeIds: ["20_vulkan_probe", "60_game_shader_probe", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "MACWIN_GRAPHICS_PRESET": "vulkan",
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["Use a small known mesh first; viewport correctness matters more than installer success."]
        ),
        SoftwareSampleProfile(
            id: "utility-network-pack",
            name: "Utilities / Network Pack",
            publisher: "7-Zip / SumatraPDF / qBittorrent / Everything",
            category: "Utilities / Network",
            purpose: "Small-to-medium utility set for shell integration, file indexing, PDF rendering, network UI, list rendering, and ordinary Win32 controls.",
            installSource: .localInstaller,
            installerFileNames: [
                "7z2601-x64.exe",
                "SumatraPDF-3.6.1-64-install.exe",
                "qbittorrent_5.2.2_x64_setup.exe",
                "Everything-1.4.1.1028.x64-Setup.exe",
                "Wireshark-latest-x64.exe"
            ],
            launcherCandidates: [
                "C:\\Program Files\\7-Zip\\7zFM.exe",
                "C:\\Program Files\\SumatraPDF\\SumatraPDF.exe",
                "C:\\Users\\%USERNAME%\\AppData\\Local\\SumatraPDF\\SumatraPDF.exe",
                "C:\\Program Files\\qBittorrent\\qbittorrent.exe",
                "C:\\Program Files\\Everything\\Everything.exe",
                "C:\\Program Files\\Wireshark\\Wireshark.exe"
            ],
            compatibilityProfileId: "win32-utilities",
            expectedIssueIds: ["file-dialog", "shell-integration", "network-tls", "list-rendering", "driver-service"],
            recommendedProbeIds: ["00_console_probe", "10_tls_winhttp_probe", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["Everything file-indexing behavior may require Windows service APIs that should be treated as a compatibility signal, not a smoke failure.", "Wireshark offline Ethernet/IPv4/UDP dissection is validated with tshark; live capture still requires an Npcap-compatible driver path."]
        ),
        SoftwareSampleProfile(
            id: "windows-utility-stress-pack",
            name: "PowerToys",
            publisher: "Microsoft",
            category: "Utilities / Windows Integration",
            purpose: "High-friction Windows utility sample for Windows-version checks, services, shell hooks, global shortcuts, tray behavior, .NET dependencies, and API gap diagnostics.",
            installSource: .localInstaller,
            installerFileNames: [
                "PowerToysUserSetup-0.100.0-x64.exe"
            ],
            launcherCandidates: [
                "C:\\Users\\%USERNAME%\\AppData\\Local\\PowerToys\\PowerToys.exe",
                "C:\\Program Files\\PowerToys\\PowerToys.exe"
            ],
            compatibilityProfileId: "win32-utilities",
            expectedIssueIds: ["windows-version-api", "dotnet-winforms", "service-control", "shell-integration", "global-shortcuts"],
            recommendedProbeIds: ["00_console_probe", "10_tls_winhttp_probe", "70_text_rendering_probe", "80_window_input_probe"],
            environment: [
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ],
            warnings: ["This is a stress sample, not an expected quick pass; failures should feed API-gap diagnostics."]
        ),
        SoftwareSampleProfile(
            id: "baseline-win32-tools",
            name: "基础 Win32 工具",
            publisher: "MacWin",
            category: "Utilities",
            purpose: "Small utility apps for menus, file dialogs, registry, fonts, and ordinary Win32 controls.",
            installSource: .signedRecipe,
            catalogRecipeId: "7zip",
            installerFileNames: ["7z2601-x64.exe"],
            launcherCandidates: [
                "C:\\Program Files\\7-Zip\\7zFM.exe",
                "C:\\Program Files\\Notepad++\\notepad++.exe",
                "C:\\Program Files\\SumatraPDF\\SumatraPDF.exe"
            ],
            expectedIssueIds: ["file-dialog", "shell-integration", "font-fallback"],
            recommendedProbeIds: ["00_console_probe", "70_text_rendering_probe", "80_window_input_probe"],
            warnings: ["Keep this sample small; it is meant to catch basic Win32 regressions before large game launchers."]
        )
    ]

    private static func csvEscaped(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    private static func downloadedFiles(in directory: URL, fileManager: FileManager) -> [URL] {
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        var urls: [URL] = []
        for case let url as URL in enumerator {
            let isRegular = (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) ?? false
            if isRegular {
                urls.append(url)
            }
        }
        return urls.sorted { $0.path.localizedCaseInsensitiveCompare($1.path) == .orderedAscending }
    }

    private static func matchingInstallerPaths(for sample: SoftwareSampleProfile, files: [URL]) -> [String] {
        guard !sample.installerFileNames.isEmpty else { return [] }
        let candidates = sample.installerFileNames.map { fileName in
            InstallerNameCandidate(original: fileName, normalized: normalizedFileStem(fileName))
        }
        return files.compactMap { file in
            let normalized = normalizedFileStem(file.lastPathComponent)
            let exact = sample.installerFileNames.contains { $0.caseInsensitiveCompare(file.lastPathComponent) == .orderedSame }
            let partial = candidates.contains { installerNameMatches(candidate: $0, downloadedStem: normalized) }
            return exact || partial ? file.path : nil
        }
    }

    private struct InstallerNameCandidate {
        var original: String
        var normalized: String
    }

    private static let genericInstallerTokens: Set<String> = [
        "setup",
        "install",
        "installer",
        "standalone",
        "enterprise",
        "latest",
        "windows",
        "win",
        "win32",
        "win64",
        "x86",
        "x64",
        "64",
        "32",
        "exe",
        "msi",
        "zip",
        "paf"
    ]

    private static func installerNameMatches(candidate: InstallerNameCandidate, downloadedStem: String) -> Bool {
        guard !candidate.normalized.isEmpty, !downloadedStem.isEmpty else { return false }
        if downloadedStem == candidate.normalized || downloadedStem.contains(candidate.normalized) {
            return true
        }

        let candidateTokens = distinctiveTokens(from: candidate.normalized)
        guard !candidateTokens.isEmpty else { return false }
        let downloadedTokens = normalizedTokens(from: downloadedStem)
        guard !downloadedTokens.isEmpty else { return false }

        return candidateTokens.allSatisfy { candidateToken in
            downloadedTokens.contains { downloadedToken in
                downloadedToken == candidateToken
                    || downloadedToken.contains(candidateToken)
            }
        }
    }

    private static func distinctiveTokens(from normalizedStem: String) -> [String] {
        normalizedTokens(from: normalizedStem).filter { token in
            token.count >= 2
                && !token.allSatisfy(\.isNumber)
                && !genericInstallerTokens.contains(token)
        }
    }

    private static func normalizedTokens(from normalizedStem: String) -> [String] {
        normalizedStem
            .split(separator: "-")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private static func normalizedFileStem(_ name: String) -> String {
        URL(fileURLWithPath: name)
            .deletingPathExtension()
            .lastPathComponent
            .lowercased()
            .replacingOccurrences(of: #"[^\p{L}\p{N}]+"#, with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private static func preparationRank(_ status: SoftwareSamplePreparationStatus) -> Int {
        switch status {
        case .missingInstaller: 0
        case .missingRecipe: 1
        case .manual: 2
        case .ready: 3
        }
    }

    private static func preparationStatusLabel(_ status: SoftwareSamplePreparationStatus) -> String {
        switch status {
        case .ready: return "READY"
        case .missingInstaller: return "MISSING_INSTALLER"
        case .missingRecipe: return "MISSING_RECIPE"
        case .manual: return "MANUAL"
        }
    }

    private static func smokeCoveragePriority(_ entry: SoftwareSamplePreparationEntry) -> Int {
        guard entry.status == .ready else { return 0 }
        var score = 10
        if entry.installSource == .localInstaller || entry.installSource == .externalExecutable {
            score += 20
        }
        let category = entry.category.lowercased()
        if category.contains("scientific") || category.contains("industrial") || category.contains("engineering") {
            score += 18
        }
        if category.contains("browser") || category.contains("office") || category.contains("app store") {
            score += 10
        }
        let highValueIssues: Set<String> = [
            "opengl-viewport",
            "qt-text",
            "electron-blank-window",
            "webview-text",
            "dotnet-winforms",
            "dotnet-runtime",
            "wow64-helper",
            "network-tls",
            "large-installer",
            "plot-rendering"
        ]
        score += min(24, entry.expectedIssueIds.filter { highValueIssues.contains($0) }.count * 4)
        score += min(8, entry.cachedInstallerPaths.count)
        return score
    }

    private static func smokeCoverageAction(
        entry: SoftwareSamplePreparationEntry,
        smokeStage: SoftwareSmokeStage?,
        launchCovered: Bool
    ) -> String {
        if let smokeStage {
            return "Already represented in smoke matrix at stage \(smokeStage.rawValue)."
        }
        if launchCovered {
            return "Already covered by successful local launch evidence. Add a dedicated smoke matrix row when you want this treated as officially verified."
        }
        switch entry.status {
        case .ready:
            if entry.installSource == .localInstaller {
                return "Promote this ready local-installer sample into an extended smoke recipe or run a manual smoke using \(cachedInstallerSummary(entry))."
            }
            return "Add this ready sample to the smoke matrix or verify its launcher manually."
        case .missingInstaller:
            return entry.requiredAction
        case .missingRecipe:
            return entry.requiredAction
        case .manual:
            return entry.requiredAction
        }
    }

    private struct CoverageLaunchEvidence {
        var state: WineLaunchState
        var logPath: String?
        var exitCode: Int32?
        var startedAt: Date
    }

    private static func latestSuccessfulLaunchEvidence(
        for entry: SoftwareSamplePreparationEntry,
        launchRecords: [WineLaunchRecord],
        smokeReports: [SoftwareSmokeRunReport]
    ) -> CoverageLaunchEvidence? {
        guard entry.status == .ready else { return nil }
        let aliases = launchAliases(for: entry)
        let managerEvidence = launchRecords.filter { record in
            isSuccessfulLaunchEvidence(record) && matches(record: record, aliases: aliases)
        }
        .map {
            CoverageLaunchEvidence(
                state: $0.state,
                logPath: $0.logPath,
                exitCode: $0.exitCode,
                startedAt: $0.startedAt
            )
        }
        let smokeSampleIds = smokeSampleIds(for: entry)
        let smokeEvidence = smokeReports.compactMap { report -> CoverageLaunchEvidence? in
            guard let record = report.records.first(where: {
                $0.phase == "launch"
                    && smokeSampleIds.contains($0.id)
                    && ($0.state == "passed" || $0.state == "launched")
            }) else {
                return nil
            }
            let date = ISO8601DateFormatter().date(from: report.generatedAt) ?? .distantPast
            return CoverageLaunchEvidence(
                state: .completed,
                logPath: record.logPath,
                exitCode: record.exitCode.flatMap(Int32.init(exactly:)),
                startedAt: date
            )
        }
        return (managerEvidence + smokeEvidence).max { $0.startedAt < $1.startedAt }
    }

    private static func smokeSampleIds(for entry: SoftwareSamplePreparationEntry) -> Set<String> {
        var ids: Set<String> = [entry.sampleId]
        let groupedIds: [String: [String]] = [
            "brave-browser": ["brave-portable", "brave-standalone"],
            "cad-lightweight-pack": ["librecad", "openscad", "qcad-legacy", "sweethome3d-design"],
            "creative-extended-pack": ["flameshot", "flameshot-capture", "krita-editor", "krita-paint", "moonlight-client", "musescore-studio"],
            "creative-workstation-pack": ["audacity-editor", "blender-3d", "gimp-image-editor", "inkscape-vector"],
            "electrical-parametric-cad-pack": ["qelectrotech-cad", "solvespace-direct"],
            "maker-streaming-pack": ["cura-slicer", "lasergrbl-cnc", "obs-studio", "orcaslicer-print", "prusaslicer-print"],
            "mesh-inspection-pack": ["meshlab-3d"],
            "windows-utility-stress-pack": ["powertoys-fancyzones"],
            "scientific-industrial-pack": [
                "jasp-stats", "julia-cli", "octave-workbench", "openmodelica-omedit",
                "qgis-ltr", "rstudio-ide", "scilab-workbench", "stellarium-planetarium"
            ]
        ]
        ids.formUnion(groupedIds[entry.sampleId] ?? [])
        return ids
    }

    private static func isSuccessfulLaunchEvidence(_ record: WineLaunchRecord) -> Bool {
        guard record.state == .completed else { return false }
        guard let exitCode = record.exitCode else {
            return record.endedAt != nil
        }
        if exitCode == 0 || exitCode == 15 || exitCode == -15 {
            return true
        }
        if let duration = record.durationMilliseconds, duration >= 3_000 {
            return true
        }
        return false
    }

    private static func launchAliases(for entry: SoftwareSamplePreparationEntry) -> Set<String> {
        var aliases = Set<String>()
        func insert(_ value: String?) {
            guard let value else { return }
            let normalizedValue = launchAliasNormalized(value)
            guard normalizedValue.count >= 3 else { return }
            aliases.insert(normalizedValue)
        }

        insert(entry.sampleId)
        insert(entry.catalogRecipeId)
        insert(entry.compatibilityProfileId)
        insert(entry.name)
        for candidate in entry.launcherCandidates {
            insert(candidate)
            let fileName = URL(fileURLWithPath: candidate.replacingOccurrences(of: "\\", with: "/")).lastPathComponent
            insert(fileName)
            insert(fileName.replacingOccurrences(of: ".exe", with: ""))
        }

        switch entry.sampleId {
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

    private static func matches(record: WineLaunchRecord, aliases: Set<String>) -> Bool {
        let text = launchAliasNormalized(
            ([record.exe] + record.args + record.commandLine + record.environment.map { "\($0.key)=\($0.value)" }).joined(separator: " ")
        )
        return aliases.contains { text.contains($0) }
    }

    private static func launchAliasNormalized(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "/")
            .replacingOccurrences(of: "%USERNAME%", with: "")
            .lowercased()
    }

    private static func cachedInstallerSummary(_ entry: SoftwareSamplePreparationEntry) -> String {
        if entry.cachedInstallerPaths.isEmpty {
            return "installer candidate \(entry.installerFileNames.first ?? entry.sampleId)"
        }
        if entry.cachedInstallerPaths.count == 1 {
            return "cached installer \(entry.cachedInstallerPaths[0])"
        }
        let names = entry.cachedInstallerPaths
            .prefix(3)
            .map { URL(fileURLWithPath: $0).lastPathComponent }
            .joined(separator: ", ")
        return "\(entry.cachedInstallerPaths.count) cached installers; choose one target first (\(names))"
    }

    private static func joinedEnvironment(_ environment: [String: String]) -> String {
        environment
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ";")
    }

    private static func fileTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return formatter.string(from: date)
    }

    private static func markdownEscaped(_ value: String) -> String {
        value.replacingOccurrences(of: "`", with: "\\`")
    }

    private static func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
