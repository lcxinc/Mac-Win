import Foundation

public struct CapabilityReport: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var generatedAt: Date
    public var rootPath: String
    public var hostEnvironment: HostEnvironmentReport?
    public var hostGUISession: HostGUISessionReport?
    public var engines: [CapabilityEngineReport]
    public var bottles: [CapabilityBottleReport]
    public var bottleHealth: BottleHealthAuditReport
    public var catalog: CapabilityCatalogReport
    public var recipeReadiness: RecipeReadinessReport
    public var installerAssets: InstallerAssetReport
    public var installerDownloadHistory: InstallerDownloadHistoryReport?
    public var softwareTestPlan: SoftwareTestPlanReport
    public var softwareSmokeMatrix: SoftwareSmokeMatrixReport
    public var softwareSmokeRuns: SoftwareSmokeRunReportSummary?
    public var softwareSampleCatalog: SoftwareSampleCatalogReport
    public var softwareSampleLogCorrelation: SoftwareSampleLogCorrelationReport
    public var installHistory: InstallHistoryReport?
    public var testAssets: TestAssetReport
    public var testRunHistory: TestRunHistoryReport?
    public var testCoverage: TestCoverageReport
    public var testExecutionPlan: TestExecutionPlan?
    public var launchHistory: LaunchHistoryReport?
    public var compatibilityRepairAudit: CompatibilityRepairAuditReport
    public var activityTimeline: ActivityTimelineReport
    public var logs: CapabilityLogReport
    public var runtimeProcesses: RuntimeProcessAuditReport?
    public var runtimeApplications: RuntimeApplicationAuditReport?
    public var diagnostics: CapabilityDiagnosticsReport?
    public var nativeUIBridgeHealth: NativeUIBridgeHealthReport?
    public var nativeUIProbeArtifacts: NativeUIProbeArtifactReport?
    public var nativeUIProbeHistory: NativeUIProbeHistoryReport?
    public var nativeUIApplicationMatrix: NativeUIApplicationMatrixReport?

    public init(
        schemaVersion: Int = 1,
        generatedAt: Date,
        rootPath: String,
        hostEnvironment: HostEnvironmentReport? = nil,
        hostGUISession: HostGUISessionReport? = nil,
        engines: [CapabilityEngineReport],
        bottles: [CapabilityBottleReport],
        bottleHealth: BottleHealthAuditReport,
        catalog: CapabilityCatalogReport,
        recipeReadiness: RecipeReadinessReport,
        installerAssets: InstallerAssetReport,
        installerDownloadHistory: InstallerDownloadHistoryReport? = nil,
        softwareTestPlan: SoftwareTestPlanReport,
        softwareSmokeMatrix: SoftwareSmokeMatrixReport,
        softwareSmokeRuns: SoftwareSmokeRunReportSummary? = nil,
        softwareSampleCatalog: SoftwareSampleCatalogReport,
        softwareSampleLogCorrelation: SoftwareSampleLogCorrelationReport,
        installHistory: InstallHistoryReport? = nil,
        testAssets: TestAssetReport,
        testRunHistory: TestRunHistoryReport? = nil,
        testCoverage: TestCoverageReport,
        testExecutionPlan: TestExecutionPlan? = nil,
        launchHistory: LaunchHistoryReport? = nil,
        compatibilityRepairAudit: CompatibilityRepairAuditReport,
        activityTimeline: ActivityTimelineReport,
        logs: CapabilityLogReport,
        runtimeProcesses: RuntimeProcessAuditReport? = nil,
        runtimeApplications: RuntimeApplicationAuditReport? = nil,
        diagnostics: CapabilityDiagnosticsReport?,
        nativeUIBridgeHealth: NativeUIBridgeHealthReport? = nil,
        nativeUIProbeArtifacts: NativeUIProbeArtifactReport? = nil,
        nativeUIProbeHistory: NativeUIProbeHistoryReport? = nil,
        nativeUIApplicationMatrix: NativeUIApplicationMatrixReport? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.generatedAt = generatedAt
        self.rootPath = rootPath
        self.hostEnvironment = hostEnvironment
        self.hostGUISession = hostGUISession
        self.engines = engines
        self.bottles = bottles
        self.bottleHealth = bottleHealth
        self.catalog = catalog
        self.recipeReadiness = recipeReadiness
        self.installerAssets = installerAssets
        self.installerDownloadHistory = installerDownloadHistory
        self.softwareTestPlan = softwareTestPlan
        self.softwareSmokeMatrix = softwareSmokeMatrix
        self.softwareSmokeRuns = softwareSmokeRuns
        self.softwareSampleCatalog = softwareSampleCatalog
        self.softwareSampleLogCorrelation = softwareSampleLogCorrelation
        self.installHistory = installHistory
        self.testAssets = testAssets
        self.testRunHistory = testRunHistory
        self.testCoverage = testCoverage
        self.testExecutionPlan = testExecutionPlan
        self.launchHistory = launchHistory
        self.compatibilityRepairAudit = compatibilityRepairAudit
        self.activityTimeline = activityTimeline
        self.logs = logs
        self.runtimeProcesses = runtimeProcesses
        self.runtimeApplications = runtimeApplications
        self.diagnostics = diagnostics
        self.nativeUIBridgeHealth = nativeUIBridgeHealth
        self.nativeUIProbeArtifacts = nativeUIProbeArtifacts
        self.nativeUIProbeHistory = nativeUIProbeHistory
        self.nativeUIApplicationMatrix = nativeUIApplicationMatrix
    }
}

public struct CapabilityEngineReport: Codable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var wineVersion: String
    public var arch: WineArch
    public var supportsWin32: Bool
    public var winePath: String
    public var winePathExists: Bool
    public var wineserverPath: String
    public var wineserverPathExists: Bool
    public var runtimePath: String
    public var runtimePathExists: Bool
    public var defaultGraphicsConfig: String?
    public var healthCheckCount: Int
}

public struct CapabilityBottleReport: Codable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var windowsVersion: String
    public var arch: WineArch
    public var engineId: String
    public var hasDriveC: Bool
    public var hasWinebootSentinel: Bool
    public var launcherCount: Int
    public var visibleLauncherCount: Int
    public var graphicsPreset: GraphicsPreset
    public var compatibilityProfiles: [String]
    public var createdAt: Date
    public var updatedAt: Date
}

public struct CapabilityCatalogReport: Codable, Equatable, Sendable {
    public var recipeCount: Int
    public var signedCuratedCatalogLoaded: Bool
    public var hasCoreCapabilityTests: Bool
    public var hasGameTests: Bool
    public var recipeIds: [String]
}

public struct CapabilityLogReport: Codable, Equatable, Sendable {
    public var directory: String
    public var recentLogCount: Int
    public var healthCounts: [String: Int]
    public var hintCounts: [String: Int]
    public var issueReport: LogIssueReport
    public var recommendations: [CapabilityLogRecommendation]
    public var entries: [CapabilityLogEntry]
}

public struct CapabilityLogRecommendation: Codable, Equatable, Sendable {
    public var id: String
    public var severity: String
    public var title: String
    public var detail: String
    public var relatedHints: [String]
    public var affectedLogNames: [String]
    public var recommendedActions: [String]
    public var probeAssetIds: [String]
}

public struct CapabilityLogEntry: Codable, Equatable, Sendable {
    public var name: String
    public var path: String
    public var modifiedAt: Date
    public var byteCount: Int64
    public var health: String
    public var errorCount: Int
    public var warningCount: Int
    public var fixmeCount: Int
    public var passCount: Int
    public var failCount: Int
    public var hints: [String]
    public var launchContext: LogLaunchContext? = nil
}

public struct CapabilityDiagnosticsReport: Codable, Equatable, Sendable {
    public var exitCode: Int32
    public var logPath: String
    public var timedOut: Bool
    public var durationSeconds: Double
    public var total: Int
    public var statusCounts: [String: Int]
    public var categories: [CapabilityDiagnosticCategoryReport]
}

public struct CapabilityDiagnosticCategoryReport: Codable, Equatable, Sendable {
    public var category: DiagnosticCategory
    public var total: Int
    public var statusCounts: [String: Int]
}

public struct CapabilityReportService {
    public var paths: MacWinPaths
    public var fileManager: FileManager
    public var logService: LogService
    public var recipeReadinessService: RecipeReadinessService
    public var installerAssetService: InstallerAssetService
    public var installerDownloadHistoryService: InstallerDownloadHistoryService
    public var installHistoryService: InstallHistoryService
    public var softwareTestPlanService: SoftwareTestPlanService
    public var softwareSmokeMatrixService: SoftwareSmokeMatrixService
    public var softwareSmokeRunReportService: SoftwareSmokeRunReportService
    public var softwareSampleCatalogService: SoftwareSampleCatalogService
    public var softwareSampleLogCorrelationService: SoftwareSampleLogCorrelationService
    public var testAssetService: TestAssetService
    public var testRunHistoryService: TestRunHistoryService
    public var testExecutionPlanService: TestExecutionPlanService
    public var launchHistoryService: LaunchHistoryService
    public var compatibilityRepairAuditService: CompatibilityRepairAuditService
    public var runtimeProcessAuditService: RuntimeProcessAuditService
    public var runtimeProcessSnapshotService: RuntimeProcessSnapshotService
    public var runtimeApplicationAuditService: RuntimeApplicationAuditService
    public var bottleHealthAuditService: BottleHealthAuditService
    public var hostEnvironmentService: HostEnvironmentService
    public var hostGUISessionService: HostGUISessionService
    public var nativeUIBridgeHealthService: NativeUIBridgeHealthService
    public var nativeUIProbeService: NativeUIProbeService
    public var nativeUIProbeHistoryService: NativeUIProbeHistoryService
    public var nativeUIApplicationMatrixService: NativeUIApplicationMatrixService

    public init(
        paths: MacWinPaths = MacWinPaths(),
        fileManager: FileManager = .default,
        recipeReadinessService: RecipeReadinessService? = nil,
        installerAssetService: InstallerAssetService? = nil,
        installerDownloadHistoryService: InstallerDownloadHistoryService? = nil,
        installHistoryService: InstallHistoryService? = nil,
        softwareTestPlanService: SoftwareTestPlanService? = nil,
        softwareSmokeMatrixService: SoftwareSmokeMatrixService? = nil,
        softwareSmokeRunReportService: SoftwareSmokeRunReportService? = nil,
        softwareSampleCatalogService: SoftwareSampleCatalogService? = nil,
        softwareSampleLogCorrelationService: SoftwareSampleLogCorrelationService? = nil,
        testAssetService: TestAssetService = TestAssetService(),
        testRunHistoryService: TestRunHistoryService? = nil,
        testExecutionPlanService: TestExecutionPlanService = TestExecutionPlanService(),
        launchHistoryService: LaunchHistoryService? = nil,
        compatibilityRepairAuditService: CompatibilityRepairAuditService = CompatibilityRepairAuditService(),
        runtimeProcessAuditService: RuntimeProcessAuditService = RuntimeProcessAuditService(),
        runtimeProcessSnapshotService: RuntimeProcessSnapshotService? = nil,
        runtimeApplicationAuditService: RuntimeApplicationAuditService = RuntimeApplicationAuditService(),
        bottleHealthAuditService: BottleHealthAuditService? = nil,
        hostEnvironmentService: HostEnvironmentService? = nil,
        hostGUISessionService: HostGUISessionService = HostGUISessionService(),
        nativeUIBridgeHealthService: NativeUIBridgeHealthService? = nil,
        nativeUIProbeService: NativeUIProbeService? = nil,
        nativeUIProbeHistoryService: NativeUIProbeHistoryService? = nil,
        nativeUIApplicationMatrixService: NativeUIApplicationMatrixService? = nil
    ) {
        self.paths = paths
        self.fileManager = fileManager
        self.logService = LogService(paths: paths, fileManager: fileManager)
        self.recipeReadinessService = recipeReadinessService ?? RecipeReadinessService(paths: paths, fileManager: fileManager)
        self.installerAssetService = installerAssetService ?? InstallerAssetService(paths: paths, fileManager: fileManager)
        self.installerDownloadHistoryService = installerDownloadHistoryService ?? InstallerDownloadHistoryService(paths: paths, fileManager: fileManager)
        self.installHistoryService = installHistoryService ?? InstallHistoryService(paths: paths, fileManager: fileManager)
        self.softwareTestPlanService = softwareTestPlanService ?? SoftwareTestPlanService(paths: paths)
        self.softwareSmokeMatrixService = softwareSmokeMatrixService ?? SoftwareSmokeMatrixService(paths: paths)
        self.softwareSmokeRunReportService = softwareSmokeRunReportService ?? SoftwareSmokeRunReportService(paths: paths, fileManager: fileManager)
        self.softwareSampleCatalogService = softwareSampleCatalogService ?? SoftwareSampleCatalogService(paths: paths)
        self.softwareSampleLogCorrelationService = softwareSampleLogCorrelationService ?? SoftwareSampleLogCorrelationService(paths: paths)
        self.testAssetService = testAssetService
        self.testRunHistoryService = testRunHistoryService ?? TestRunHistoryService(root: testAssetService.root, fileManager: fileManager)
        self.testExecutionPlanService = testExecutionPlanService
        self.launchHistoryService = launchHistoryService ?? LaunchHistoryService(paths: paths, fileManager: fileManager)
        self.compatibilityRepairAuditService = compatibilityRepairAuditService
        self.runtimeProcessAuditService = runtimeProcessAuditService
        self.runtimeProcessSnapshotService = runtimeProcessSnapshotService ?? RuntimeProcessSnapshotService(paths: paths, fileManager: fileManager)
        self.runtimeApplicationAuditService = runtimeApplicationAuditService
        self.bottleHealthAuditService = bottleHealthAuditService ?? BottleHealthAuditService(paths: paths, fileManager: fileManager)
        self.hostEnvironmentService = hostEnvironmentService ?? HostEnvironmentService(paths: paths, fileManager: fileManager)
        self.hostGUISessionService = hostGUISessionService
        self.nativeUIBridgeHealthService = nativeUIBridgeHealthService
            ?? NativeUIBridgeHealthService(fileManager: fileManager)
        self.nativeUIProbeService = nativeUIProbeService ?? NativeUIProbeService(paths: paths, fileManager: fileManager)
        self.nativeUIProbeHistoryService = nativeUIProbeHistoryService ?? NativeUIProbeHistoryService(paths: paths, fileManager: fileManager)
        self.nativeUIApplicationMatrixService = nativeUIApplicationMatrixService ?? NativeUIApplicationMatrixService(paths: paths, fileManager: fileManager)
    }

    public func makeReport(
        generatedAt: Date = Date(),
        engines: [EngineManifest],
        bottles: [BottleManifest],
        recipes: [RecipeManifest],
        diagnosticReport: DiagnosticReport? = nil,
        logLimit: Int = 24
    ) -> CapabilityReport {
        let recentLogs = logService.recentLogs(limit: logLimit)
        let testAssets = testAssetService.report()
        let testRunHistory = testRunHistoryService.report()
        let installHistory = installHistoryService.report(limit: logLimit)
        let launchHistory = launchHistoryService.report(limit: logLimit)
        let compatibilityRepairAudit = compatibilityRepairAuditService.makeReport(
            launchHistory: launchHistory,
            engines: engines,
            bottles: bottles
        )
        let softwareSmokeRuns = try? softwareSmokeRunReportService.summary(limit: logLimit)
        // The application matrix only needs the recent evidence already
        // loaded for the capability report. Re-reading every historical smoke
        // directory makes startup scale with the lifetime of the installation.
        let nativeUIApplicationSmokeReports = softwareSmokeRuns?.reports ?? []
        let logs = SoftwareSmokeEvidenceResolver.currentLogReport(
            logReport(recentLogs),
            smokeReports: softwareSmokeRuns?.reports ?? []
        )
        let recipeReadiness = recipeReadinessService.report(recipes: recipes, engines: engines)
        let installerAssets = installerAssetService.report(recipes: recipes)
        let installerDownloadHistory = installerDownloadHistoryService.report(limit: logLimit)
        let diagnostics = diagnosticReport.map(diagnosticsReport)
        let nativeUIBridgeHealth = nativeUIBridgeHealthService.report(
            engines: engines,
            generatedAt: generatedAt
        )
        let nativeUIProbeArtifacts = nativeUIProbeService.artifactReport(generatedAt: generatedAt)
        let nativeUIProbeHistory = nativeUIProbeHistoryService.report(limit: logLimit)
        let nativeUIApplicationMatrix = nativeUIApplicationMatrixService.report(
            bottles: bottles,
            recipes: recipes,
            launchHistory: launchHistory,
            smokeReports: nativeUIApplicationSmokeReports,
            generatedAt: generatedAt
        )
        let testCoverage = TestCoverageReport.make(assetReport: testAssets, runHistory: testRunHistory)
        let testExecutionPlan = testExecutionPlanService.makePlan(
            assetReport: testAssets,
            runHistory: testRunHistory,
            generatedAt: generatedAt
        )
        let softwareTestPlan = softwareTestPlanService.report(
            recipes: recipes,
            bottles: bottles,
            readiness: recipeReadiness,
            installerAssets: installerAssets,
            installHistory: installHistory,
            launchHistory: launchHistory,
            logs: logs,
            generatedAt: generatedAt
        )
        let catalog = catalogReport(recipes: recipes)
        let softwareSmokeMatrix = softwareSmokeMatrixService.report(
            softwareTestPlan: softwareTestPlan,
            compatibilityRepairAudit: compatibilityRepairAudit,
            signedCatalogLoaded: catalog.signedCuratedCatalogLoaded
        )
        let softwareSampleCatalog = softwareSampleCatalogService.report(recipes: recipes, generatedAt: generatedAt)
        let softwareSampleLogCorrelation = softwareSampleLogCorrelationService.report(
            sampleCatalog: softwareSampleCatalog,
            logs: logs,
            launchHistory: launchHistory,
            generatedAt: generatedAt
        )
        return CapabilityReport(
            generatedAt: generatedAt,
            rootPath: paths.root.path,
            hostEnvironment: hostEnvironmentService.report(
                engines: engines,
                bottles: bottles,
                recipes: recipes,
                recentLogCount: recentLogs.count
            ),
            hostGUISession: hostGUISessionService.report(generatedAt: generatedAt),
            engines: engines.map(engineReport),
            bottles: bottles.map(bottleReport),
            bottleHealth: bottleHealthAuditService.report(bottles: bottles),
            catalog: catalog,
            recipeReadiness: recipeReadiness,
            installerAssets: installerAssets,
            installerDownloadHistory: installerDownloadHistory,
            softwareTestPlan: softwareTestPlan,
            softwareSmokeMatrix: softwareSmokeMatrix,
            softwareSmokeRuns: softwareSmokeRuns,
            softwareSampleCatalog: softwareSampleCatalog,
            softwareSampleLogCorrelation: softwareSampleLogCorrelation,
            installHistory: installHistory,
            testAssets: testAssets,
            testRunHistory: testRunHistory,
            testCoverage: testCoverage,
            testExecutionPlan: testExecutionPlan,
            launchHistory: launchHistory,
            compatibilityRepairAudit: compatibilityRepairAudit,
            activityTimeline: ActivityTimelineReport.make(
                generatedAt: generatedAt,
                installerDownloadHistory: installerDownloadHistory,
                installHistory: installHistory,
                testRunHistory: testRunHistory,
                launchHistory: launchHistory,
                logs: logs,
                diagnostics: diagnostics
            ),
            logs: logs,
            runtimeProcesses: runtimeProcessAuditService.makeReport(),
            runtimeApplications: runtimeApplicationAuditService.makeReport(),
            diagnostics: diagnostics,
            nativeUIBridgeHealth: nativeUIBridgeHealth,
            nativeUIProbeArtifacts: nativeUIProbeArtifacts,
            nativeUIProbeHistory: nativeUIProbeHistory,
            nativeUIApplicationMatrix: nativeUIApplicationMatrix
        )
    }

    public func makeSoftwareSmokeMatrixReport(
        generatedAt: Date = Date(),
        engines: [EngineManifest],
        bottles: [BottleManifest],
        recipes: [RecipeManifest],
        logLimit: Int = 80
    ) -> SoftwareSmokeMatrixReport {
        let recentLogs = logService.recentLogs(limit: logLimit)
        let softwareSmokeRuns = try? softwareSmokeRunReportService.summary(limit: logLimit)
        let logs = SoftwareSmokeEvidenceResolver.currentLogReport(
            logReport(recentLogs),
            smokeReports: softwareSmokeRuns?.reports ?? []
        )
        let installHistory = installHistoryService.report(limit: logLimit)
        let launchHistory = launchHistoryService.report(limit: logLimit)
        let compatibilityRepairAudit = compatibilityRepairAuditService.makeReport(
            launchHistory: launchHistory,
            engines: engines,
            bottles: bottles
        )
        let recipeReadiness = recipeReadinessService.report(recipes: recipes, engines: engines)
        let installerAssets = installerAssetService.report(recipes: recipes)
        let softwareTestPlan = softwareTestPlanService.report(
            recipes: recipes,
            bottles: bottles,
            readiness: recipeReadiness,
            installerAssets: installerAssets,
            installHistory: installHistory,
            launchHistory: launchHistory,
            logs: logs,
            generatedAt: generatedAt
        )
        return softwareSmokeMatrixService.report(
            softwareTestPlan: softwareTestPlan,
            compatibilityRepairAudit: compatibilityRepairAudit,
            signedCatalogLoaded: catalogReport(recipes: recipes).signedCuratedCatalogLoaded
        )
    }

    @discardableResult
    public func exportReport(
        generatedAt: Date = Date(),
        engines: [EngineManifest],
        bottles: [BottleManifest],
        recipes: [RecipeManifest],
        diagnosticReport: DiagnosticReport? = nil,
        logLimit: Int = 24
    ) throws -> URL {
        try paths.ensureBaseDirectories(fileManager: fileManager)
        let report = makeReport(
            generatedAt: generatedAt,
            engines: engines,
            bottles: bottles,
            recipes: recipes,
            diagnosticReport: diagnosticReport,
            logLimit: logLimit
        )
        let destination = paths.logsDirectory.appendingPathComponent("capability-report-\(Self.fileTimestamp(generatedAt)).json")
        try JSONStore(fileManager: fileManager).save(report, to: destination)
        if let runtimeProcesses = report.runtimeProcesses {
            try runtimeProcessSnapshotService.writeSnapshot(report: runtimeProcesses, generatedAt: generatedAt)
        }
        return destination
    }

    private func engineReport(_ engine: EngineManifest) -> CapabilityEngineReport {
        CapabilityEngineReport(
            id: engine.id,
            name: engine.name,
            wineVersion: engine.wineVersion,
            arch: engine.arch,
            supportsWin32: engine.supportsWin32,
            winePath: engine.winePath,
            winePathExists: fileManager.fileExists(atPath: engine.winePath),
            wineserverPath: engine.wineserverPath,
            wineserverPathExists: fileManager.fileExists(atPath: engine.wineserverPath),
            runtimePath: engine.runtimePath,
            runtimePathExists: fileManager.fileExists(atPath: engine.runtimePath),
            defaultGraphicsConfig: engine.defaultEnv["WINE_D3D_CONFIG"],
            healthCheckCount: engine.healthChecks.count
        )
    }

    private func bottleReport(_ bottle: BottleManifest) -> CapabilityBottleReport {
        let profiles = Set(bottle.installedApps.compactMap { launcher in
            let rawValue = launcher.envOverrides["MACWIN_COMPAT_PROFILE"]?.trimmingCharacters(in: .whitespacesAndNewlines)
            return rawValue?.isEmpty == false ? rawValue : nil
        })

        return CapabilityBottleReport(
            id: bottle.id,
            name: bottle.name,
            windowsVersion: bottle.windowsVersion,
            arch: bottle.arch,
            engineId: bottle.engineId,
            hasDriveC: fileManager.fileExists(atPath: paths.bottleDriveCURL(id: bottle.id).path),
            hasWinebootSentinel: fileManager.fileExists(
                atPath: paths.bottleDirectory(id: bottle.id)
                    .appendingPathComponent(BottleService.winebootSentinelName)
                    .path
            ),
            launcherCount: bottle.installedApps.count,
            visibleLauncherCount: bottle.installedApps.filter(\.showInHome).count,
            graphicsPreset: GraphicsPreset.current(in: bottle),
            compatibilityProfiles: profiles.sorted(),
            createdAt: bottle.createdAt,
            updatedAt: bottle.updatedAt
        )
    }

    private func catalogReport(recipes: [RecipeManifest]) -> CapabilityCatalogReport {
        let recipeIds = recipes.map(\.id).sorted()
        return CapabilityCatalogReport(
            recipeCount: recipes.count,
            signedCuratedCatalogLoaded: !recipes.isEmpty,
            hasCoreCapabilityTests: recipeIds.contains("macwin-core-capability-tests"),
            hasGameTests: recipeIds.contains("macwin-game-tests"),
            recipeIds: recipeIds
        )
    }

    private func logReport(_ logs: [LogFileItem]) -> CapabilityLogReport {
        var healthCounts: [String: Int] = [:]
        var hintCounts: [String: Int] = [:]
        let entries = logs.map { item in
            healthCounts[item.summary.health.rawValue, default: 0] += 1
            for hint in item.summary.hints {
                hintCounts[hint.rawValue, default: 0] += 1
            }
            return CapabilityLogEntry(
                name: item.name,
                path: item.url.path,
                modifiedAt: item.modifiedAt,
                byteCount: item.byteCount,
                health: item.summary.health.rawValue,
                errorCount: item.summary.errorCount,
                warningCount: item.summary.warningCount,
                fixmeCount: item.summary.fixmeCount,
                passCount: item.summary.passCount,
                failCount: item.summary.failCount,
                hints: item.summary.hints.map(\.rawValue),
                launchContext: item.launchContext
            )
        }

        let issueReport = LogService.issueReport(logs: logs)
        return CapabilityLogReport(
            directory: paths.logsDirectory.path,
            recentLogCount: entries.count,
            healthCounts: healthCounts,
            hintCounts: hintCounts,
            issueReport: issueReport,
            recommendations: logRecommendations(issueReport: issueReport),
            entries: entries
        )
    }

    private func logRecommendations(issueReport: LogIssueReport) -> [CapabilityLogRecommendation] {
        issueReport.topIssues.map { issue in
            return CapabilityLogRecommendation(
                id: issue.id,
                severity: issue.severity,
                title: issue.title,
                detail: issue.detail,
                relatedHints: issue.relatedHints,
                affectedLogNames: issue.affectedLogNames,
                recommendedActions: issue.recommendedActions,
                probeAssetIds: issue.probeAssetIds
            )
        }
    }

    private func diagnosticsReport(_ report: DiagnosticReport) -> CapabilityDiagnosticsReport {
        CapabilityDiagnosticsReport(
            exitCode: report.exitCode,
            logPath: report.logURL.path,
            timedOut: report.timedOut,
            durationSeconds: report.durationSeconds,
            total: report.items.count,
            statusCounts: statusCounts(report.items.map(\.status)),
            categories: DiagnosticCategory.allCases.compactMap { category in
                let items = report.items.filter { $0.category == category }
                guard !items.isEmpty else { return nil }
                return CapabilityDiagnosticCategoryReport(
                    category: category,
                    total: items.count,
                    statusCounts: statusCounts(items.map(\.status))
                )
            }
        )
    }

    private func statusCounts(_ statuses: [DiagnosticStatus]) -> [String: Int] {
        var counts: [String: Int] = [:]
        for status in statuses {
            counts[status.rawValue, default: 0] += 1
        }
        return counts
    }

    private static func fileTimestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter.string(from: date)
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "")
    }
}
