import Foundation
import MacWinCore

enum AppLanguage: String, CaseIterable, Identifiable {
    case zhHans
    case en

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .zhHans: "简体中文"
        case .en: "English"
        }
    }

    static func load() -> AppLanguage {
        if let raw = UserDefaults.standard.string(forKey: "MacWinLanguage"),
           let language = AppLanguage(rawValue: raw) {
            return language
        }
        return .zhHans
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: "MacWinLanguage")
    }
}

enum TextKey {
    case appTitle
    case applications
    case appLauncherSubtitle
    case appMode
    case desktopMode
    case workspaceMode
    case toggleFullScreen
    case allApps
    case games
    case utilities
    case other
    case desktop
    case desktopSubtitle
    case desktopApps
    case pinned
    case quickAccess
    case startMenu
    case searchApps
    case noDesktopApps
    case runningApps
    case noRunningApps
    case pid
    case probeArchitectureX86_64
    case probeArchitectureI686Wow64
    case runtimeProcessContext
    case stop
    case openLogFile
    case terminatedPid
    case terminatedBottleProcesses
    case stopBottleProcesses
    case stoppingBottleProcesses
    case stoppedBottleProcesses
    case stoppedBottleProcessesPartial
    case restartBottle
    case restartingBottle
    case restartedBottle
    case restartBottleIncomplete
    case cleanedOrphanedProcesses
    case refreshDesktop
    case dropInstallerTitle
    case dropInstallerHelp
    case installingDroppedInstaller
    case droppedInstallerStarted
    case unsupportedInstallerFile
    case commandPrompt
    case thisPC
    case recycleBin
    case wineConfiguration
    case registryEditor
    case currentBottle
    case engineStatus
    case installApps
    case openCDrive
    case openBottleFolder
    case openRealWineDesktop
    case home
    case market
    case bottles
    case diagnostics
    case settings
    case launcherCount
    case foundationStatus
    case foundationStatusReady
    case foundationStatusAttention
    case foundationStatusBlocked
    case foundationStatusSummary
    case foundationStatusCatalog
    case foundationStatusInstallers
    case foundationStatusTests
    case foundationStatusRuntime
    case foundationStatusLogs
    case foundationStatusNoSnapshot
    case bottleCount
    case noLaunchersYet
    case openMarket
    case run
    case runWithDiagnostics
    case keepSystemAwake
    case preventScreenLockHint
    case openWindowsExecutable
    case chooseBottleToOpenExecutable
    case externalExecutable
    case sourceFile
    case runInBottle
    case signedRecipes
    case choose
    case install
    case cancel
    case staged
    case create
    case defaultBottleName
    case highPerformanceBottleName
    case defaultInstallTarget
    case bottleNamePlaceholder
    case launchers
    case noLaunchers
    case compatibilityProfile
    case noCompatibilityProfile
    case applyCompatibilityProfile
    case clearCompatibilityProfile
    case repairBottle
    case scanInstalledApps
    case scanningInstalledApps
    case scannedInstalledApps
    case runCommand
    case executablePlaceholder
    case arguments
    case tools
    case windows11Desktop
    case driveC
    case bottle
    case logs
    case delete
    case graphicsPreset
    case nativeUIIntegration
    case applyingNativeUIIntegration
    case appliedNativeUIIntegration
    case defaultGameBottle
    case gptkStatus
    case gptkAvailable
    case gptkMissing
    case noBottleSelected
    case createBottle
    case diagnosticSubtitle
    case runProbeSuite
    case nativeUIProbe
    case nativeUIProbeSubtitle
    case nativeUIProbeSessionUnlocked
    case nativeUIProbeSessionLocked
    case nativeUIProbeSessionUnavailable
    case nativeUIBridgeStatus
    case nativeUIBridgeReady
    case nativeUIBridgeIncomplete
    case nativeUIBridgeUnavailable
    case nativeUIProbeAssets
    case nativeUIProbeArchitecture
    case nativeUIProbeAvailable
    case nativeUIProbeMissingShort
    case nativeUIProbeMissing
    case nativeUIProbeCurrentBottle
    case runningNativeUIProbe
    case nativeUIProbePassed
    case nativeUIProbeCancelled
    case nativeUIProbeLastRun
    case noNativeUIProbeRun
    case nativeUIApplicationMatrix
    case nativeUIApplicationMatrixSubtitle
    case nativeUIApplicationMatrixSummary
    case nativeUIApplicationInstalled
    case nativeUIApplicationRecipeAvailable
    case nativeUIApplicationInstallerAvailable
    case nativeUIApplicationUnavailable
    case nativeUIApplicationNotRun
    case nativeUIApplicationObserved
    case nativeUIApplicationPassed
    case nativeUIApplicationFailed
    case nativeUIApplicationRun
    case nativeUIApplicationRunDiagnostics
    case nativeUIApplicationInstall
    case nativeUIApplicationSelectInstaller
    case nativeUIApplicationPreset
    case nativeUIApplicationNeedsInstall
    case noNativeUIApplicationMatrix
    case runRepresentativeAcceptance
    case runningRepresentativeAcceptance
    case representativeAcceptanceSummary
    case representativeAcceptanceFinished
    case result
    case exitCode
    case log
    case recentLogs
    case diagnosticArtifacts
    case diagnosticArtifactsSummary
    case noDiagnosticArtifacts
    case exportDiagnosticArtifactIndexCSV
    case exportingDiagnosticArtifactIndexCSV
    case diagnosticArtifactIndexCSVExported
    case artifactLogs
    case artifactReports
    case artifactTables
    case artifactScripts
    case artifactBundles
    case artifactRecords
    case artifactOthers
    case noRecentLogs
    case logIssues
    case logIssuesSummary
    case noLogIssues
    case recentLogFailures
    case evidence
    case affectedLogs
    case logsAnalyzed
    case logMaintenance
    case logMaintenanceSummary
    case logMaintenanceHealthy
    case supportTriage
    case supportTriageSummary
    case supportTriageReady
    case supportTriageBlocked
    case supportTriageAttention
    case supportTriageBlockers
    case supportTriageHighPriority
    case supportTriageWarnings
    case supportTriageInfo
    case supportTriageActions
    case noSupportTriageItems
    case refreshSupportTriage
    case staleLogs
    case largeLogs
    case cleanupCandidates
    case totalLogSize
    case oldestLog
    case newestLog
    case recommendations
    case exportLogIssueReport
    case exportRecommendedProbeScript
    case exportLogMaintenanceScript
    case archiveCleanupLogs
    case cleanHistoricalLogs
    case exportSoftwareAdaptationRunbook
    case exportSoftwareAdaptationQueueCSV
    case exportSoftwareAdaptationProbeScript
    case exportSoftwareSampleCatalogCSV
    case exportSoftwareSampleCatalogRunbook
    case exportSoftwareSamplePreparationSnapshot
    case softwareSampleLogCorrelation
    case softwareSampleLogCorrelationSummary
    case softwareSampleMatched
    case softwareSampleFailed
    case softwareSampleAttention
    case noSoftwareSampleLogCorrelation
    case exportHostEnvironmentCSV
    case exportingLogMaintenanceScript
    case archivingCleanupLogs
    case cleaningHistoricalLogs
    case exportingLogIssueReport
    case exportingRecommendedProbeScript
    case exportingSoftwareAdaptationRunbook
    case exportingSoftwareAdaptationQueueCSV
    case exportingSoftwareAdaptationProbeScript
    case exportingSoftwareSampleCatalogCSV
    case exportingSoftwareSampleCatalogRunbook
    case exportingSoftwareSamplePreparationSnapshot
    case exportingHostEnvironmentCSV
    case logIssueReportExported
    case recommendedProbeScriptExported
    case logMaintenanceScriptExported
    case cleanupLogsArchived
    case noCleanupLogsToArchive
    case historicalLogsCleaned
    case softwareAdaptationRunbookExported
    case softwareAdaptationQueueCSVExported
    case softwareAdaptationProbeScriptExported
    case softwareSampleCatalogCSVExported
    case softwareSampleCatalogRunbookExported
    case hostEnvironmentCSVExported
    case activityTimeline
    case activityTimelineSummary
    case activityTimelineEvents
    case activityTimelineErrors
    case activityTimelineWarnings
    case exportInstallHistoryCSV
    case exportLaunchHistoryCSV
    case exportDiagnosticHistoryCSV
    case exportingInstallHistoryCSV
    case installHistoryCSVExported
    case noActivityTimeline
    case compatibilityRepairAudit
    case compatibilityRepairAuditSummary
    case compatibilityRepairReady
    case compatibilityRepairMissing
    case compatibilityRepairStale
    case compatibilityRuntimeCoverageMissing
    case compatibilityRuntimeCoverage
    case compatibilityAffectedBottles
    case noCompatibilityRepairAudit
    case latestRepairFindings
    case severityCritical
    case severityHigh
    case severityMedium
    case severityLow
    case refreshLogs
    case revealInFinder
    case checks
    case noDiagnosticRun
    case diagnosticHistory
    case diagnosticHistorySummary
    case noDiagnosticHistory
    case diagnosticRuns
    case passedRuns
    case failedRuns
    case timedOutRuns
    case durationSeconds
    case bottleHealth
    case bottleHealthSummary
    case healthyBottles
    case bottlesNeedAttention
    case bottleHealthWarnings
    case staleLaunchers
    case incompleteProfiles
    case noBottleHealthIssues
    case latestBottleHealthFindings
    case runtimeProcesses
    case runtimeProcessesSummary
    case runningWindowsProcesses
    case detachedWineSystemProcesses
    case staleRuntimeProcesses
    case runtimeFindings
    case noRuntimeProcesses
    case latestRuntimeFindings
    case refreshRuntimeProcesses
    case exportRuntimeProcessesCSV
    case exportRuntimeSnapshot
    case stopRuntimeProcess
    case stopAllRuntimeProcesses
    case stopWineVirtualDesktops
    case stopDetachedWineSystemProcesses
    case noRuntimeProcessesToStop
    case terminatedRuntimeProcesses
    case terminatedWineVirtualDesktops
    case terminatedDetachedWineSystemProcesses
    case terminatedRuntimeProcessesPartial
    case testAssets
    case testAssetsReady
    case testAssetsMissing
    case testCoverage
    case testCoverageSummary
    case testExecutionPlan
    case testExecutionPlanSummary
    case noTestExecutionPlan
    case exportTestRunHistoryCSV
    case exportTestExecutionPlanCSV
    case exportTestSessionArchive
    case runRecommendedProbes
    case requiredTests
    case highPriorityTests
    case coveragePassed
    case coverageFailed
    case coverageTimedOut
    case coverageUnverified
    case coverageMissing
    case verifiedCategories
    case latestRuns
    case noTestCoverage
    case recommendedActions
    case recommendedProbes
    case installerAssets
    case installerAssetsSummary
    case installerPreparation
    case installerPreparationSummary
    case installerPreparationCritical
    case installerPreparationWarning
    case installerPreparationInfo
    case installerPreparationHashMismatch
    case installerPreparationDownloadMissing
    case installerPreparationAddExpectedHash
    case installerPreparationUseWoW64
    case installerPreparationReviewOrphaned
    case installerCached
    case installerMissing
    case installerHashMismatchCount
    case downloadableInstallers
    case noInstallerActions
    case installerDownloadHistory
    case installerDownloadHistorySummary
    case installerDownloadRecords
    case installerDownloadFailures
    case installerDownloadHashMismatches
    case noInstallerDownloadHistory
    case openDownloads
    case exportInstallerDownloadScript
    case exportInstallerAssetCSV
    case exportInstallerPreparationCSV
    case exportInstallerDownloadHistoryCSV
    case exportSoftwareTestPlanCSV
    case downloadInstaller
    case downloadInstallerBatch
    case localInstallerCandidates
    case localInstallerCandidatesSummary
    case noLocalInstallerCandidates
    case installLocalCandidate
    case unknownArchitecture
    case softwareTestPlan
    case softwareTestPlanSummary
    case softwareVerified
    case softwareInstalled
    case softwareReadyToInstall
    case softwareNeedsReview
    case softwareFailing
    case softwareNextActions
    case noSoftwareActions
    case softwareNoCatalog
    case softwareSampleCatalog
    case softwareSampleCatalogSummary
    case softwareSampleCatalogLocalInstallers
    case softwareSampleCatalogSignedRecipes
    case softwareSampleCatalogWarnings
    case noSoftwareSampleCatalog
    case softwareCollection
    case softwareCollectionSummary
    case softwareCollectionCoverage
    case softwareCollectionMissingRecipes
    case softwareCollectionMissingInstallers
    case softwareCollectionActionRequired
    case softwareCollectionAcceptance
    case softwareCollectionAcceptanceSummary
    case softwareCollectionAcceptanceState
    case softwareCollectionAcceptanceBlockers
    case softwareCollectionAcceptanceHighPriority
    case softwareCollectionAcceptanceWarnings
    case softwareCollectionAcceptanceActions
    case noSoftwareCollectionAcceptanceActions
    case softwareCollectionDownloadMissing
    case exportSoftwareCollectionCSV
    case exportSoftwareCollectionDownloadScript
    case exportSoftwareCollectionAcceptanceRunbook
    case exportSoftwareCollectionBundle
    case noSoftwareCollection
    case softwareSmokeMatrix
    case softwareSmokeMatrixSummary
    case smokeBlocked
    case smokeWarnings
    case smokeFailures
    case smokeVerified
    case smokeStage
    case smokeChecklist
    case noSoftwareSmokeMatrix
    case blockers
    case latestLog
    case runNextAction
    case exportCapabilityReport
    case exportSupportBundle
    case engineAndCatalog
    case engine
    case name
    case version
    case architecture
    case runtime
    case win32Compatibility
    case win32Supported
    case win32Unsupported
    case requiresWin32
    case refreshEngine
    case catalog
    case recipes
    case trust
    case signedCuratedSource
    case refreshCatalog
    case data
    case root
    case openLogs
    case language
    case ready
    case importingEngine
    case preparingDefaultBottle
    case preparingDesktop
    case creatingBottle
    case repairingBottle
    case applyingCompatibilityProfile
    case applyingGraphicsPreset
    case installing
    case launching
    case launchingWithDiagnostics
    case runningCommand
    case deleting
    case runningDiagnostics
    case exportingCapabilityReport
    case exportingSupportBundle
    case exportingInstallerDownloadScript
    case exportingInstallerAssetCSV
    case exportingInstallerPreparationCSV
    case exportingInstallerDownloadHistoryCSV
    case exportingSoftwareTestPlanCSV
    case exportingSoftwareCollectionCSV
    case exportingSoftwareCollectionDownloadScript
    case exportingSoftwareCollectionAcceptanceRunbook
    case exportingSoftwareCollectionBundle
    case exportingTestExecutionPlanCSV
    case exportingTestRunHistoryCSV
    case exportingTestSessionArchive
    case exportingLaunchHistoryCSV
    case exportingDiagnosticHistoryCSV
    case downloadingInstaller
    case downloadingInstallerBatch
    case installerDownloaded
    case installerDownloadBatchFinished
    case runningProbe
    case probeFinished
    case runningProbeBatch
    case probeBatchFinished
    case rerunProbe
    case runCoverageProbes
    case diagnosticsPassed
    case diagnosticsFinishedWithFailures
    case capabilityReportExported
    case supportBundleExported
    case supportTriageRefreshed
    case runtimeProcessesRefreshed
    case exportingRuntimeProcessesCSV
    case exportingRuntimeSnapshot
    case runtimeProcessesCSVExported
    case runtimeSnapshotExported
    case terminatedRuntimeProcess
    case installerDownloadScriptExported
    case installerAssetCSVExported
    case installerPreparationCSVExported
    case installerDownloadHistoryCSVExported
    case softwareSamplePreparationSnapshotExported
    case softwareTestPlanCSVExported
    case softwareCollectionCSVExported
    case softwareCollectionDownloadScriptExported
    case softwareCollectionAcceptanceRunbookExported
    case softwareCollectionBundleExported
    case testExecutionPlanCSVExported
    case testRunHistoryCSVExported
    case testSessionArchiveExported
    case launchHistoryCSVExported
    case diagnosticHistoryCSVExported
    case catalogExpired
    case catalogError
    case noEngineRegistered
    case noEngineForBottle
    case windowsDesktopOnlyWin11
    case diagnosticLaunchTitle
    case launchedPid
    case startedPid
    case alreadyRunningPid
    case actionAlreadyInProgress
    case created
    case repairedBottle
    case appliedCompatibilityProfile
    case clearedCompatibilityProfile
    case appliedGraphicsPreset
    case installedIntoDefaultBottle
    case deleted
    case unableToLaunchProcess
    case wineRuntimeUnavailable
    case missingFile
    case processFailed
    case unsupported
    case invalidManifest
    case signatureInvalid
    case hashMismatch
    case installerRequired
    case excellent
    case good
    case limited
    case experimental
    case unknown
    case wineD3DVulkanPreset
    case wineD3DVulkanPresetHelp
    case gptkD3DMetalPreset
    case gptkD3DMetalPresetHelp
    case gptkD3DMetalDXRPreset
    case gptkD3DMetalDXRPresetHelp
    case bambuStudioSoftwareOpenGLProfile
    case blenderSoftwareOpenGLProfile
    case orcaSlicerNativeOpenGLProfile
    case browserGeckoProfile
    case hoYoPlayProfile
    case lenovoAppStoreProfile
    case tencentAppStoreProfile
    case steamClientProfile
    case cefSoftwareRendererProfile
    case chromiumBrowserProfile
    case curaSlicerProfile
    case dbeaverSWTProfile
    case kritaOpenGLProfile
    case geogebraLegacyElectron32Profile
    case gmshOpenGLProfile
    case freeCADOpenGLProfile
    case kiCadEDAProfile
    case libreCADQtProfile
    case jabRefJavaFXD3DProfile
    case jaspQtWebEngineQrcProfile
    case meshLabSoftwareOpenGLProfile
    case openPLCEditorProfile
    case openSCADSoftwareOpenGLProfile
    case sweetHome3DOpenGLProfile
    case mRemoteNG1782Profile
    case museScoreStudioProfile
    case notepadPlusPlusGDIProfile
    case portableAppsPlatformProfile
    case portableAppsUtilityProfile
    case officeSuiteProfile
    case wpsOfficeProfile
    case qtBrowserSoftwareProfile
    case qucsSQt6Profile
    case qtRhiSoftwareProfile
    case qtWidgetsSoftwareProfile
    case softMakerOfficeProfile
    case supermium32BrowserProfile
    case texStudioQt6Profile
    case sevenZipGDIProfile
    case zoteroGecko32Profile
}

enum AppText {
    static func text(_ key: TextKey, language: AppLanguage) -> String {
        switch language {
        case .zhHans:
            return zhHans(key)
        case .en:
            return en(key)
        }
    }

    static func rating(_ rating: CompatibilityRating, language: AppLanguage) -> String {
        switch rating {
        case .excellent: text(.excellent, language: language)
        case .good: text(.good, language: language)
        case .limited: text(.limited, language: language)
        case .experimental: text(.experimental, language: language)
        case .unknown: text(.unknown, language: language)
        }
    }

    static func category(_ value: String, language: AppLanguage) -> String {
        guard language == .zhHans else { return value }
        switch value {
        case "Game Launcher":
            return "游戏启动器"
        case "Diagnostics":
            return "诊断"
        case "Game Tests":
            return "游戏测试"
        case "Utilities":
            return "工具"
        case "Developer Tools":
            return "开发工具"
        case "Media":
            return "媒体"
        default:
            return value
        }
    }

    static func graphicsPresetName(_ preset: GraphicsPreset, language: AppLanguage) -> String {
        switch preset {
        case .wineD3DVulkan:
            return text(.wineD3DVulkanPreset, language: language)
        case .gptkD3DMetal:
            return text(.gptkD3DMetalPreset, language: language)
        case .gptkD3DMetalDXR:
            return text(.gptkD3DMetalDXRPreset, language: language)
        }
    }

    static func graphicsPresetHelp(_ preset: GraphicsPreset, language: AppLanguage) -> String {
        switch preset {
        case .wineD3DVulkan:
            return text(.wineD3DVulkanPresetHelp, language: language)
        case .gptkD3DMetal:
            return text(.gptkD3DMetalPresetHelp, language: language)
        case .gptkD3DMetalDXR:
            return text(.gptkD3DMetalDXRPresetHelp, language: language)
        }
    }

    static func nativeUIIntegrationPresetName(_ preset: NativeUIIntegrationPreset, language: AppLanguage) -> String {
        switch (preset, language) {
        case (.disabled, .zhHans): "关闭"
        case (.automatic, .zhHans): "自动 Mac 界面路由"
        case (.windowIntegration, .zhHans): "Mac 窗口集成"
        case (.nativeDialogs, .zhHans): "Mac 原生对话框"
        case (.disabled, .en): "Disabled"
        case (.automatic, .en): "Automatic Mac UI Routing"
        case (.windowIntegration, .en): "Mac Window Integration"
        case (.nativeDialogs, .en): "Mac Native Dialogs"
        }
    }

    static func nativeUIIntegrationPresetHelp(_ preset: NativeUIIntegrationPreset, language: AppLanguage) -> String {
        switch (preset, language) {
        case (.disabled, .zhHans): "保留完整 Windows 界面行为，适合游戏、自绘界面和兼容性敏感应用。"
        case (.automatic, .zhHans): "按 API 类型自动选择 macOS 原生窗口、消息框、现代文件对话框和简单任务对话框；复杂或不兼容功能自动回退到 Wine。"
        case (.windowIntegration, .zhHans): "使用 macOS 窗口、全屏和 Dock 行为，不替换应用内部控件。"
        case (.nativeDialogs, .zhHans): "将兼容的消息框、现代文件对话框和简单任务对话框交给 macOS。"
        case (.disabled, .en): "Preserves Windows UI behavior for games, custom rendering, and compatibility-sensitive apps."
        case (.automatic, .en): "Routes supported windows, alerts, modern file dialogs, and simple task dialogs to macOS, with strict Wine fallback for complex features."
        case (.windowIntegration, .en): "Uses macOS window, full-screen, and Dock behavior without replacing app controls."
        case (.nativeDialogs, .en): "Routes compatible alerts, modern file dialogs, and simple task dialogs through macOS."
        }
    }

    static func nativeUIProbeModeName(_ mode: NativeUIProbeMode, language: AppLanguage) -> String {
        switch (mode, language) {
        case (.message, .zhHans): "消息框"
        case (.legacyOpen, .zhHans): "传统打开"
        case (.legacySave, .zhHans): "传统保存"
        case (.filteredOpen, .zhHans): "带过滤器打开"
        case (.filteredSave, .zhHans): "带过滤器保存"
        case (.legacyFallback, .zhHans): "传统回退"
        case (.modernOpen, .zhHans): "现代打开"
        case (.modernSave, .zhHans): "现代保存"
        case (.modernOpenMulti, .zhHans): "现代多选"
        case (.modernFolder, .zhHans): "现代文件夹"
        case (.task, .zhHans): "任务对话框"
        case (.taskFallback, .zhHans): "任务回退"
        case (.message, .en): "Message Box"
        case (.legacyOpen, .en): "Legacy Open"
        case (.legacySave, .en): "Legacy Save"
        case (.filteredOpen, .en): "Filtered Open"
        case (.filteredSave, .en): "Filtered Save"
        case (.legacyFallback, .en): "Legacy Fallback"
        case (.modernOpen, .en): "Modern Open"
        case (.modernSave, .en): "Modern Save"
        case (.modernOpenMulti, .en): "Modern Multi-select"
        case (.modernFolder, .en): "Modern Folder"
        case (.task, .en): "Task Dialog"
        case (.taskFallback, .en): "Task Fallback"
        }
    }

    static func nativeUIApplicationFamilyName(_ family: NativeUIApplicationMatrixFamily, language: AppLanguage) -> String {
        switch (family, language) {
        case (.hoyoPlay, .zhHans): "HoYoPlay"
        case (.steam, .zhHans): "Steam"
        case (.browser, .zhHans): "浏览器"
        case (.office, .zhHans): "办公软件"
        case (.lenovoAppStore, .zhHans): "联想应用商店"
        case (.hoyoPlay, .en): "HoYoPlay"
        case (.steam, .en): "Steam"
        case (.browser, .en): "Browsers"
        case (.office, .en): "Office"
        case (.lenovoAppStore, .en): "Lenovo App Store"
        }
    }

    static func nativeUIApplicationAvailabilityName(_ availability: NativeUIApplicationAvailability, language: AppLanguage) -> String {
        switch (availability, language) {
        case (.installed, .zhHans): "已安装"
        case (.recipeAvailable, .zhHans): "配方可用"
        case (.installerAvailable, .zhHans): "安装器可用"
        case (.unavailable, .zhHans): "待准备"
        case (.installed, .en): "Installed"
        case (.recipeAvailable, .en): "Recipe available"
        case (.installerAvailable, .en): "Installer available"
        case (.unavailable, .en): "Needs preparation"
        }
    }

    static func nativeUIApplicationEvidenceName(_ evidence: NativeUIApplicationLaunchEvidence, language: AppLanguage) -> String {
        switch (evidence, language) {
        case (.notRun, .zhHans): "未运行"
        case (.observed, .zhHans): "已观察到启动"
        case (.passed, .zhHans): "启动通过"
        case (.failed, .zhHans): "启动失败"
        case (.notRun, .en): "Not run"
        case (.observed, .en): "Launch observed"
        case (.passed, .en): "Launch passed"
        case (.failed, .en): "Launch failed"
        }
    }

    static func nativeUIApplicationEvidenceDetail(_ detail: String, language: AppLanguage) -> String {
        switch (detail, language) {
        case ("passed-smoke-browser-workload", .zhHans):
            "浏览器页面、TLS、UTF-8、Canvas 与 CSS Grid 工作负载通过"
        case ("passed-smoke-core-workload", .zhHans):
            "文档核心工作负载与导出结果通过"
        case ("passed-smoke-rendered-content", .zhHans):
            "页面结构、资源加载与窗口像素渲染通过"
        case ("observed-smoke-launch", .zhHans):
            "窗口进程保持运行，尚缺功能或渲染证明"
        case ("not-run-smoke-session-locked", .zhHans):
            "macOS 已锁屏，等待解锁后进行窗口与交互验收"
        case (_, .zhHans) where detail.hasPrefix("observed-"):
            "应用保持运行，尚缺功能或渲染证明"
        case (_, .zhHans) where detail.hasPrefix("failed-"):
            "最近一次启动失败，请查看日志"
        case (_, .zhHans) where detail.hasPrefix("passed-"):
            "最近一次受管启动正常完成"
        case ("passed-smoke-browser-workload", .en):
            "Browser page, TLS, UTF-8, Canvas, and CSS Grid workload passed"
        case ("passed-smoke-core-workload", .en):
            "Document core workload and exported result passed"
        case ("passed-smoke-rendered-content", .en):
            "Page structure, resources, and rendered window pixels passed"
        case ("observed-smoke-launch", .en):
            "The process stayed alive; functional or rendered-content proof is still missing"
        case ("not-run-smoke-session-locked", .en):
            "macOS is locked; window and interaction acceptance is waiting for an unlocked session"
        case (_, .en) where detail.hasPrefix("observed-"):
            "The application stayed alive; functional or rendered-content proof is still missing"
        case (_, .en) where detail.hasPrefix("failed-"):
            "The latest launch failed; inspect its log"
        case (_, .en) where detail.hasPrefix("passed-"):
            "The latest managed launch completed successfully"
        default:
            detail
        }
    }

    static func compatibilityProfileName(_ profile: ApplicationCompatibilityProfile, language: AppLanguage) -> String {
        switch profile {
        case .bambuStudioSoftwareOpenGL:
            return text(.bambuStudioSoftwareOpenGLProfile, language: language)
        case .blenderSoftwareOpenGL:
            return text(.blenderSoftwareOpenGLProfile, language: language)
        case .orcaSlicerNativeOpenGL:
            return text(.orcaSlicerNativeOpenGLProfile, language: language)
        case .hoYoPlay:
            return text(.hoYoPlayProfile, language: language)
        case .lenovoAppStore:
            return text(.lenovoAppStoreProfile, language: language)
        case .tencentAppStore:
            return text(.tencentAppStoreProfile, language: language)
        case .mRemoteNG1782:
            return text(.mRemoteNG1782Profile, language: language)
        case .museScoreStudio:
            return text(.museScoreStudioProfile, language: language)
        case .notepadPlusPlusGDI:
            return text(.notepadPlusPlusGDIProfile, language: language)
        case .portableAppsPlatform:
            return text(.portableAppsPlatformProfile, language: language)
        case .portableAppsUtility:
            return text(.portableAppsUtilityProfile, language: language)
        case .officeSuite:
            return text(.officeSuiteProfile, language: language)
        case .wpsOffice:
            return text(.wpsOfficeProfile, language: language)
        case .qtBrowserSoftware:
            return text(.qtBrowserSoftwareProfile, language: language)
        case .qucsSQt6:
            return text(.qucsSQt6Profile, language: language)
        case .steamClient:
            return text(.steamClientProfile, language: language)
        case .chromiumBrowser:
            return text(.chromiumBrowserProfile, language: language)
        case .curaSlicer:
            return text(.curaSlicerProfile, language: language)
        case .dbeaverSWT:
            return text(.dbeaverSWTProfile, language: language)
        case .kritaOpenGL:
            return text(.kritaOpenGLProfile, language: language)
        case .geogebraLegacyElectron32:
            return text(.geogebraLegacyElectron32Profile, language: language)
        case .gmshOpenGL:
            return text(.gmshOpenGLProfile, language: language)
        case .freeCADOpenGL:
            return text(.freeCADOpenGLProfile, language: language)
        case .kiCadEDA:
            return text(.kiCadEDAProfile, language: language)
        case .libreCADQt:
            return text(.libreCADQtProfile, language: language)
        case .jabRefJavaFXD3D:
            return text(.jabRefJavaFXD3DProfile, language: language)
        case .jaspQtWebEngineQrc:
            return text(.jaspQtWebEngineQrcProfile, language: language)
        case .meshLabSoftwareOpenGL:
            return text(.meshLabSoftwareOpenGLProfile, language: language)
        case .openPLCEditor:
            return text(.openPLCEditorProfile, language: language)
        case .openSCADSoftwareOpenGL:
            return text(.openSCADSoftwareOpenGLProfile, language: language)
        case .sweetHome3DOpenGL:
            return text(.sweetHome3DOpenGLProfile, language: language)
        case .cefSoftwareRenderer:
            return text(.cefSoftwareRendererProfile, language: language)
        case .qtRhiSoftware:
            return text(.qtRhiSoftwareProfile, language: language)
        case .qtWidgetsSoftware:
            return text(.qtWidgetsSoftwareProfile, language: language)
        case .softMakerOffice:
            return text(.softMakerOfficeProfile, language: language)
        case .supermium32Browser:
            return text(.supermium32BrowserProfile, language: language)
        case .texStudioQt6:
            return text(.texStudioQt6Profile, language: language)
        case .sevenZipGDI:
            return text(.sevenZipGDIProfile, language: language)
        case .zoteroGecko32:
            return text(.zoteroGecko32Profile, language: language)
        case .browserGecko:
            return text(.browserGeckoProfile, language: language)
        }
    }

    static func softwareTestPlanState(_ state: SoftwareTestPlanState, language: AppLanguage) -> String {
        switch (state, language) {
        case (.disabled, .zhHans): "已停用"
        case (.blocked, .zhHans): "阻塞"
        case (.localInstallerRequired, .zhHans): "需要本地安装器"
        case (.existingInstallMissing, .zhHans): "缺少现有安装"
        case (.missingInstaller, .zhHans): "缺少安装器"
        case (.hashMismatch, .zhHans): "哈希不匹配"
        case (.readyToInstall, .zhHans): "可安装"
        case (.installerLaunched, .zhHans): "安装器已启动"
        case (.installFailed, .zhHans): "安装失败"
        case (.installedNotLaunched, .zhHans): "待启动验证"
        case (.launchFailed, .zhHans): "启动失败"
        case (.needsReview, .zhHans): "需要复查"
        case (.verified, .zhHans): "已验证"
        case (.disabled, .en): "Disabled"
        case (.blocked, .en): "Blocked"
        case (.localInstallerRequired, .en): "Needs Local Installer"
        case (.existingInstallMissing, .en): "Missing Existing Install"
        case (.missingInstaller, .en): "Missing Installer"
        case (.hashMismatch, .en): "Hash Mismatch"
        case (.readyToInstall, .en): "Ready to Install"
        case (.installerLaunched, .en): "Installer Launched"
        case (.installFailed, .en): "Install Failed"
        case (.installedNotLaunched, .en): "Needs Launch Check"
        case (.launchFailed, .en): "Launch Failed"
        case (.needsReview, .en): "Needs Review"
        case (.verified, .en): "Verified"
        }
    }

    static func softwareSmokeStage(_ stage: SoftwareSmokeStage, language: AppLanguage) -> String {
        switch (stage, language) {
        case (.catalog, .zhHans): "市场配方"
        case (.installer, .zhHans): "安装器"
        case (.install, .zhHans): "安装"
        case (.launcher, .zhHans): "启动项"
        case (.launch, .zhHans): "启动验证"
        case (.logReview, .zhHans): "日志复查"
        case (.compatibilityRepair, .zhHans): "兼容修复"
        case (.verified, .zhHans): "已验证"
        case (.disabled, .zhHans): "已停用"
        case (.catalog, .en): "Catalog"
        case (.installer, .en): "Installer"
        case (.install, .en): "Install"
        case (.launcher, .en): "Launcher"
        case (.launch, .en): "Launch Smoke"
        case (.logReview, .en): "Log Review"
        case (.compatibilityRepair, .en): "Compatibility Repair"
        case (.verified, .en): "Verified"
        case (.disabled, .en): "Disabled"
        }
    }

    static func softwareSmokeCheckState(_ state: SoftwareSmokeCheckState, language: AppLanguage) -> String {
        switch (state, language) {
        case (.passed, .zhHans): "通过"
        case (.pending, .zhHans): "待处理"
        case (.warning, .zhHans): "警告"
        case (.failed, .zhHans): "失败"
        case (.blocked, .zhHans): "阻塞"
        case (.notApplicable, .zhHans): "不适用"
        case (.passed, .en): "Passed"
        case (.pending, .en): "Pending"
        case (.warning, .en): "Warning"
        case (.failed, .en): "Failed"
        case (.blocked, .en): "Blocked"
        case (.notApplicable, .en): "N/A"
        }
    }

    static func softwareTestPlanAction(_ entry: SoftwareTestPlanEntry, language: AppLanguage) -> String {
        switch (entry.state, language) {
        case (.disabled, .zhHans):
            return "配方已停用，等待配方警告处理后再测试。"
        case (.blocked, .zhHans):
            return "先处理配方阻塞项，再进入安装测试。"
        case (.localInstallerRequired, .zhHans):
            return "选择本地安装器，并确认来源后运行配方。"
        case (.existingInstallMissing, .zhHans):
            return "先定位已有安装目录，或重新安装一次。"
        case (.missingInstaller, .zhHans):
            return "把安装器下载到 MacWin 的 Downloads 缓存后再安装。"
        case (.hashMismatch, .zhHans):
            return "删除缓存安装器并重新下载，当前文件哈希与配方不一致。"
        case (.readyToInstall, .zhHans):
            return "安装到高性能 Windows 11 容器，然后启动一次收集日志。"
        case (.installerLaunched, .zhHans):
            return "完成安装器窗口中的安装，然后扫描容器生成启动项。"
        case (.installFailed, .zhHans):
            return "打开安装日志，按日志线索修复后重新安装。"
        case (.installedNotLaunched, .zhHans):
            return "启动一次应用，收集启动记录和 smoke-test 日志。"
        case (.launchFailed, .zhHans):
            return "用诊断启动重跑，并尝试对应兼容预设。"
        case (.needsReview, .zhHans):
            return "检查最近日志中的渲染、字体、窗口或崩溃线索。"
        case (.verified, .zhHans):
            return "作为基线应用保留；引擎或预设变更后再回归。"
        case (.disabled, .en):
            return "Keep disabled until the recipe warning is resolved."
        case (.blocked, .en):
            return "Fix recipe blockers before installation testing."
        case (.localInstallerRequired, .en):
            return "Choose a local installer and verify its source before running the recipe."
        case (.existingInstallMissing, .en):
            return "Point the recipe at an existing install or install it once."
        case (.missingInstaller, .en):
            return "Download the installer into the MacWin Downloads cache."
        case (.hashMismatch, .en):
            return "Delete and re-download the cached installer; the hash does not match."
        case (.readyToInstall, .en):
            return "Install into the high-performance Windows 11 bottle, then launch once with logging."
        case (.installerLaunched, .en):
            return "Finish the installer window, then scan the bottle to generate launchers."
        case (.installFailed, .en):
            return "Inspect the install log, fix the issue, and rerun installation."
        case (.installedNotLaunched, .en):
            return "Launch the app once to collect a launch record and smoke-test log."
        case (.launchFailed, .en):
            return "Rerun with diagnostic launch and try the matching compatibility preset."
        case (.needsReview, .en):
            return "Review recent rendering, font, window, or crash signals in the log."
        case (.verified, .en):
            return "Keep as a baseline app; rerun after engine or preset changes."
        }
    }

    static func logHealth(_ health: LogHealth, language: AppLanguage) -> String {
        switch (health, language) {
        case (.passed, .zhHans): "通过"
        case (.failed, .zhHans): "需处理"
        case (.attention, .zhHans): "注意"
        case (.quiet, .zhHans): "安静"
        case (.passed, .en): "Passed"
        case (.failed, .en): "Needs Attention"
        case (.attention, .en): "Attention"
        case (.quiet, .en): "Quiet"
        }
    }

    static func logMaintenanceRecommendation(_ recommendation: String, language: AppLanguage) -> String {
        guard language == .zhHans else { return recommendation }
        switch recommendation {
        case "Review large logs before exporting support bundles; they can hide the useful tail behind noisy Wine output.":
            return "导出诊断包前先检查大日志；大量 Wine 输出可能会淹没真正有用的尾部线索。"
        case "Archive or remove stale logs after exporting a support bundle for the current issue.":
            return "为当前问题导出诊断包后，可以归档或移除过期日志。"
        case "Cleanup candidates exceed 64 MiB; trim old logs before running long game sessions.":
            return "可清理日志超过 64 MiB；长时间游戏测试前建议先整理旧日志。"
        case "The Logs directory is large enough to slow diagnosis; keep recent issue logs and archive older runs.":
            return "日志目录已经偏大，可能拖慢排查；保留最近问题日志，把更早的运行记录归档。"
        case "No log maintenance action is needed.":
            return "暂不需要维护日志。"
        default:
            return recommendation
        }
    }

    static func logIssueTitle(_ trend: LogIssueTrend, language: AppLanguage) -> String {
        logIssueTitle(id: trend.id, fallback: trend.title, language: language)
    }

    static func logIssueTitle(id: String, fallback: String? = nil, language: AppLanguage) -> String {
        switch (id, language) {
        case ("wine-crash", .zhHans): "Wine 崩溃或程序错误"
        case ("webview-rendering", .zhHans): "CEF/WebView 渲染失败"
        case ("text-rendering", .zhHans): "文字渲染或字体回退问题"
        case ("blank-window", .zhHans): "黑屏、白屏或空窗口"
        case ("window-input", .zhHans): "窗口焦点或点击路由问题"
        case ("graphics-runtime", .zhHans): "Vulkan 或 D3DMetal 运行库问题"
        case ("network-tls", .zhHans): "网络、代理、超时或 TLS 问题"
        case ("win32-wow64", .zhHans): "32 位或 WoW64 兼容问题"
        case ("portableapps-seh", .zhHans): "PortableApps 32 位 GUI SEH 崩溃"
        case ("jasp-engine-ipc", .zhHans): "JASP EngineSync IPC 快速失败"
        case ("dotnet-runtime", .zhHans): ".NET 或 Wine-Mono 运行时失败"
        case ("mremoteng-early-exit", .zhHans): "mRemoteNG 启动后过早退出"
        case ("installer", .zhHans): "安装器校验或执行问题"
        case ("unclassified-failure", .zhHans): "未归类失败"
        default:
            fallback ?? id
        }
    }

    static func logIssueDetail(_ trend: LogIssueTrend, language: AppLanguage) -> String {
        switch (trend.id, language) {
        case ("wine-crash", .zhHans):
            "日志中出现 page fault、程序错误、访问违规或 debugger attach。建议用诊断启动重跑，并导出诊断包。"
        case ("webview-rendering", .zhHans):
            "日志中出现 Chromium、CEF、GPU context、compositor 或 Electron stdout 问题。优先尝试应用专用 WebView 修复预设，并对比软件 WebView 与图形预设。"
        case ("text-rendering", .zhHans):
            "日志中出现 DirectWrite、缺字、字体回退或旧 Chromium 文字光栅参数。应使用当前兼容预设重新启动，并清理 WebView 缓存。"
        case ("blank-window", .zhHans):
            "日志中出现黑屏、白屏、空窗口、空渲染器或缺字线索。对比 App 模式和沉浸式容器，再测试 WebView 软件路径与当前字体修复。"
        case ("window-input", .zhHans):
            "日志中出现命中测试、前台/焦点、透明层窗口或点击消息问题。对比 App 模式和沉浸式容器，并重跑窗口/输入探针。"
        case ("graphics-runtime", .zhHans):
            "日志中出现 Vulkan 或 D3DMetal 错误。先确认图形预设、引擎运行库路径和探针结果，再调应用参数。"
        case ("network-tls", .zhHans):
            "日志中出现 WinHTTP、证书、Steam 网络探测或超时线索。检查代理继承、DNS、证书和 TLS 探针。"
        case ("win32-wow64", .zhHans):
            "日志中出现 32 位、bad exe format、kernel32、WoW64 或 SEH 分发线索。先验证 WoW64 基线和托管的 rosettax87 运行时；两者都通过后，再按应用自身启动器或异常处理兼容缺口继续排查。"
        case ("portableapps-seh", .zhHans):
            "PortableAppsPlatform.exe 作为 32 位 GUI 进程启动后，可能在 Wine WoW64 异常分发、wow64cpu、c0000029 unwind 或空地址 page fault 附近失败。托管的 rosettax87 已覆盖 WinSCP 和 Pale Moon 使用的同类 x87 敏感边界，应先确认该运行时已启用，再判断是否为 PortableApps 自身缺口。"
        case ("jasp-engine-ipc", .zhHans):
            "JASP 已完成 Qt/QML 初始化并进入 EngineSync 数据交接，随后在 Boost interprocess 共享内存、文件锁或 heartbeat 路径附近快速失败。这不是早期 Qt 资源路径问题。"
        case ("dotnet-runtime", .zhHans):
            "日志中出现 Wine-Mono native crash、mscoree、hostfxr/hostpolicy、CoreCLR 或 .NET 运行时程序集失败。先确认应用需要 Wine-Mono、原生 .NET Framework 还是现代 .NET Desktop Runtime。"
        case ("mremoteng-early-exit", .zhHans):
            "mRemoteNG 1.78.2 已经通过托管的 .NET Desktop Runtime 启动，但进程在 smoke 超时前以 0 退出，没有保持 WinForms 窗口。这里应按启动/窗口生命周期兼容问题继续排查，而不是继续判断为缺少 .NET。"
        case ("installer", .zhHans):
            "日志中出现安装器、MSI、NSIS、哈希或 catalog mismatch 问题。检查安装器来源、SHA-256、静默参数和架构。"
        case ("unclassified-failure", .zhHans):
            "日志里有错误或 FAIL 标记，但还没有命中已知 MacWin 规则。需要打开原始日志，并把反复出现的签名提升为新规则。"
        default:
            trend.detail
        }
    }

    static func logIssueActions(_ trend: LogIssueTrend, language: AppLanguage) -> [String] {
        switch (trend.id, language) {
        case ("wine-crash", .zhHans):
            [
                "用“诊断启动”重新运行受影响应用。",
                "在切换图形或兼容预设前先导出诊断包。"
            ]
        case ("webview-rendering", .zhHans):
            [
                "应用专用 WebView 修复预设，并只清理该应用的 WebView 缓存。",
                "用同一个启动器对比软件 WebView、WineD3D Vulkan 和 D3DMetal/GPTK。"
            ]
        case ("text-rendering", .zhHans):
            [
                "用当前兼容预设重启，确保旧 DirectWrite/Chromium 字体参数被剥离。",
                "运行文字渲染探针，并和受影响应用日志对照。"
            ]
        case ("blank-window", .zhHans):
            [
                "对比 App 模式和沉浸式容器，区分 compositor 问题和应用自身渲染问题。",
                "先尝试软件 WebView 路径，再改整瓶图形预设。"
            ]
        case ("window-input", .zhHans):
            [
                "在 App 模式和沉浸式容器分别重跑窗口/输入探针。",
                "命中测试确认前避免强制透明 layered window。"
            ]
        case ("graphics-runtime", .zhHans):
            [
                "先确认引擎运行库路径和当前图形预设。",
                "跑 Vulkan、D3D11、D3D12、D3D9 和 shader-loop 探针建立基线。"
            ]
        case ("network-tls", .zhHans):
            [
                "先确认代理继承和证书处理，再判断应用兼容性。",
                "如果安装器或启动器会拉起 helper，同时跑 64 位和 32 位 WinHTTP TLS 探针。"
            ]
        case ("win32-wow64", .zhHans):
            [
                "确认容器使用支持 WoW64 的引擎，并且 ROSETTA_X87_PATH 指向可执行文件，然后重跑 32 位 TLS 和网络适配器探针。",
                "如果 rosettax87 和探针都通过但应用仍出现 SEH stack-limit 错误，停止调整图形预设，改用 +seh,+loaddll 诊断 32 位启动器。"
            ]
        case ("portableapps-seh", .zhHans):
            [
                "复现平台主窗口前，先确认当前引擎的 ROSETTA_X87_PATH 指向可执行的 rosettax87。",
                "保持 executable-dir 启动，并继续禁用该 recipe 的全局图形预设注入。",
                "确认 tls-winhttp-win32、iphlpapi-adapters-win32 和 rosettax87 都通过；通过后不要继续调图形预设，改抓 PortableAppsPlatform.exe 的 +seh,+loaddll 日志。",
                "用 PortableAppsBackup.exe 或 PortableAppsUpdater.exe 做 GUI helper 对照；如果 helper 能保持运行而 Platform 主程序 exit 41，应把问题限定在主窗口路径。",
                "修改共享容器服务或注册表前，先用干净 prefix 复现一次。",
                "在平台 GUI 修好前，优先直接测试单个 portable app 的 EXE。"
            ]
        case ("jasp-engine-ipc", .zhHans):
            [
                "保留 JASP 的 Qt/WebEngine 资源路径修复，只对该样本启用 SEH/module 诊断日志。",
                "优先对比 NtLockFile、共享内存映射和 heartbeat 行为，再考虑图形预设。"
            ]
        case ("dotnet-runtime", .zhHans):
            [
                "先启用 Wine-Mono 和 .NET registry 修复后重跑，再判断是否需要原生 .NET Framework。",
                "如果 32 位 .NET Framework 版在 Mono native 层崩溃，优先寻找 x64 或现代 .NET Runtime 构建。"
            ]
        case ("mremoteng-early-exit", .zhHans):
            [
                "对比默认高性能容器和已验证 mRemoteNG smoke prefix 的注册表与环境变量。",
                "在继续更换 .NET runtime 前，抓取 WinForms 启动、更新检查和主窗口生命周期日志。"
            ]
        case ("installer", .zhHans):
            [
                "重新校验缓存安装器 SHA-256 与 recipe 是否一致。",
                "确认安装器是否需要 32 位支持、MSI 服务修复或本地交互运行。"
            ]
        case ("unclassified-failure", .zhHans):
            [
                "打开原始日志，定位第一个反复出现的错误签名。",
                "如果跨应用重复出现，把签名升级为 LogService 规则并绑定探针。"
            ]
        default:
            trend.recommendedActions
        }
    }

    static func logIssueSeverity(_ severity: String, language: AppLanguage) -> String {
        switch (severity, language) {
        case ("critical", .zhHans): text(.severityCritical, language: language)
        case ("high", .zhHans): text(.severityHigh, language: language)
        case ("medium", .zhHans): text(.severityMedium, language: language)
        case ("low", .zhHans): text(.severityLow, language: language)
        case ("critical", .en): text(.severityCritical, language: language)
        case ("high", .en): text(.severityHigh, language: language)
        case ("medium", .en): text(.severityMedium, language: language)
        case ("low", .en): text(.severityLow, language: language)
        default: severity
        }
    }

    static func logHint(_ hint: LogHint, language: AppLanguage) -> String {
        switch (hint, language) {
        case (.steamNetworkProbe, .zhHans):
            "Steam 网络状态探测失败，通常不阻塞登录。"
        case (.electronStdout, .zhHans):
            "Electron/CEF 标准输出句柄异常，建议使用 CEF 软件渲染预设。"
        case (.wineProgramError, .zhHans):
            "Wine 捕获到程序崩溃，可用诊断启动重新生成详细日志。"
        case (.wineCrash, .zhHans):
            "检测到 Wine 崩溃或 page fault，建议切换兼容预设后诊断启动。"
        case (.vulkanIssue, .zhHans):
            "检测到 Vulkan 相关错误，检查图形预设或运行库。"
        case (.networkTLSIssue, .zhHans):
            "检测到 TLS/WinHTTP 相关错误，可能影响登录或下载。"
        case (.d3dMetalRuntime, .zhHans):
            "检测到 D3DMetal 运行库问题，确认 GPTK runtime 是否完整。"
        case (.cefRenderingIssue, .zhHans):
            "检测到 CEF/WebView 渲染问题，优先尝试应用专用文字或黑屏修复预设。"
        case (.fontRenderingIssue, .zhHans):
            "检测到字体/DirectWrite 相关线索，建议保留 DirectWrite 并清理 WebView 字体缓存。"
        case (.blankWindowIssue, .zhHans):
            "检测到黑屏、白屏、空白窗口或缺字线索，建议对比 App 模式和沉浸式容器并切换 WebView 修复预设。"
        case (.windowInputIssue, .zhHans):
            "检测到窗口命中、焦点或点击消息问题，建议运行窗口/输入探针并对比 App 模式与沉浸式容器。"
        case (.gpuRenderingIssue, .zhHans):
            "检测到 GPU/ANGLE 上下文问题，可尝试 Vulkan、D3DMetal 或软件 WebView 路径。"
        case (.win32CompatibilityIssue, .zhHans):
            "检测到 32 位或 WoW64 相关问题，请确认当前引擎支持 32 位应用。"
        case (.jaspQrcQmlResourceIssue, .zhHans):
            "检测到 JASP 内置 qrc/QML 资源加载崩溃；软件 OpenGL/RHI 与 QML cache 路径已覆盖，下一步检查 Qt resource 注册和 qrc 读取。"
        case (.jaspQmlInitializationHangIssue, .zhHans):
            "检测到 JASP 已到初始 DataSetPackage::endLoadingData -> EngineSync::enginesReceiveNewData，但没有进入 Desktop started 或 loadQML；不能只按进程存活判定为启动成功，下一步结合 sample 线程摘要检查 DataSetPackage reset、EngineSync reloadData 和构造函数尾段。"
        case (.jaspEngineIpcIssue, .zhHans):
            "检测到 JASP EngineSync/IPC 快速失败，优先检查共享内存、文件锁和 heartbeat 兼容性。"
        case (.dotnetRuntimeIssue, .zhHans):
            "检测到 .NET 或 Wine-Mono 运行时失败，请区分 Wine-Mono、原生 .NET Framework 和现代 .NET Desktop Runtime。"
        case (.missingDLLIssue, .zhHans):
            "检测到缺失 DLL 或运行库覆盖，请补齐对应 builtin DLL 并对现有容器运行 wineboot -u。"
        case (.msiRuntimeIssue, .zhHans):
            "检测到 MSI 运行时缺失或不可用，请先修复 msiexec/Windows Installer 支持。"
        case (.chromeOmahaInstallerIssue, .zhHans):
            "检测到 Chromium 系安装器的 Google Update/Omaha、EdgeUpdate 或 BraveUpdate 阶段失败，建议换离线包或单独诊断更新器安装动作。"
        case (.comProxyMarshallingIssue, .zhHans):
            "检测到 COM/RpcSs 代理或 marshalling 失败，优先检查 Wine 服务程序、ole32/combase 代理注册和 RpcSs 启动。"
        case (.mRemoteNGEarlyExitIssue, .zhHans):
            "检测到 mRemoteNG 1.78.2 在 .NET Runtime 可用的情况下过早退出；下一步排查 WinForms 启动和窗口生命周期。"
        case (.portableAppsSEHIssue, .zhHans):
            "检测到 PortableAppsPlatform.exe 的 32 位 GUI/WoW64 SEH 崩溃；如果 32 位探针通过，应优先诊断该启动器而不是继续调整图形预设。"
        case (.installerIssue, .zhHans):
            "检测到安装器失败，检查安装器哈希、静默参数和是否需要 32 位支持。"
        case (.timeout, .zhHans):
            "检测到超时，可能是网络、安装器卡住或图形初始化阻塞。"
        case (.passObserved, .zhHans):
            "日志中观察到 PASS。"
        case (.steamNetworkProbe, .en):
            "Steam network probe failed; this usually does not block login."
        case (.electronStdout, .en):
            "Electron/CEF stdout handle issue detected; try the CEF software renderer preset."
        case (.wineProgramError, .en):
            "Wine captured a program crash; run a diagnostic launch for a fuller log."
        case (.wineCrash, .en):
            "Wine crash or page fault detected; try a compatibility preset and run a diagnostic launch."
        case (.vulkanIssue, .en):
            "Vulkan errors detected; check graphics preset or runtime."
        case (.networkTLSIssue, .en):
            "TLS/WinHTTP errors detected; login or downloads may be affected."
        case (.d3dMetalRuntime, .en):
            "D3DMetal runtime issue detected; verify the GPTK runtime."
        case (.cefRenderingIssue, .en):
            "CEF/WebView rendering issue detected; try an app-specific text or black-screen repair preset."
        case (.fontRenderingIssue, .en):
            "Font/DirectWrite signals detected; keep DirectWrite enabled and clear WebView font caches."
        case (.blankWindowIssue, .en):
            "Blank, black, empty-window, or missing-text signals detected; compare App Mode with the immersive container and try a WebView repair preset."
        case (.windowInputIssue, .en):
            "Window hit-test, focus, or click-message issue detected; run the window/input probe and compare App Mode with the immersive container."
        case (.gpuRenderingIssue, .en):
            "GPU/ANGLE context issue detected; try Vulkan, D3DMetal, or a software WebView path."
        case (.win32CompatibilityIssue, .en):
            "32-bit or WoW64 issue detected; verify that the current engine supports 32-bit apps."
        case (.jaspQrcQmlResourceIssue, .en):
            "JASP embedded qrc/QML resource crash detected; software OpenGL/RHI and QML cache paths are covered, so check Qt resource registration and qrc readback next."
        case (.jaspQmlInitializationHangIssue, .en):
            "JASP reached the initial DataSetPackage::endLoadingData -> EngineSync::enginesReceiveNewData path but did not reach Desktop started or loadQML; do not count process liveness as launch success, and use sample thread summaries while checking DataSetPackage reset, EngineSync reloadData, and the constructor tail next."
        case (.jaspEngineIpcIssue, .en):
            "JASP EngineSync/IPC fail-fast detected; check shared-memory, file-lock, and heartbeat compatibility first."
        case (.dotnetRuntimeIssue, .en):
            ".NET or Wine-Mono runtime failure detected; distinguish Wine-Mono, native .NET Framework, and modern .NET Desktop Runtime requirements."
        case (.missingDLLIssue, .en):
            "Missing DLL or runtime coverage detected; add the builtin DLL and run wineboot -u for existing bottles."
        case (.msiRuntimeIssue, .en):
            "MSI runtime is missing or unusable; repair msiexec/Windows Installer support first."
        case (.chromeOmahaInstallerIssue, .en):
            "Chromium installer Google Update/Omaha, EdgeUpdate, or BraveUpdate phase failed; try a full offline package or diagnose the updater action separately."
        case (.comProxyMarshallingIssue, .en):
            "COM/RpcSs proxy or marshalling failure detected; check Wine service programs, ole32/combase proxy registration, and RpcSs startup first."
        case (.mRemoteNGEarlyExitIssue, .en):
            "mRemoteNG 1.78.2 exits early while the .NET runtime is available; inspect WinForms startup and window lifecycle next."
        case (.portableAppsSEHIssue, .en):
            "PortableAppsPlatform.exe 32-bit GUI/WoW64 SEH crash detected; if 32-bit probes pass, diagnose that launcher instead of tuning graphics presets."
        case (.installerIssue, .en):
            "Installer failure detected; check hash, silent arguments, and 32-bit requirements."
        case (.timeout, .en):
            "Timeout detected; network, installer, or graphics initialization may be blocked."
        case (.passObserved, .en):
            "PASS observed in the log."
        }
    }

    static func diagnosticCategory(_ category: DiagnosticCategory, language: AppLanguage) -> String {
        switch (category, language) {
        case (.core, .zhHans): "核心"
        case (.network, .zhHans): "网络与 TLS"
        case (.graphics, .zhHans): "图形"
        case (.audio, .zhHans): "音频"
        case (.game, .zhHans): "游戏循环"
        case (.windowing, .zhHans): "窗口与输入"
        case (.win32, .zhHans): "32 位 / WoW64"
        case (.core, .en): "Core"
        case (.network, .en): "Network and TLS"
        case (.graphics, .en): "Graphics"
        case (.audio, .en): "Audio"
        case (.game, .en): "Game Loop"
        case (.windowing, .en): "Windowing and Input"
        case (.win32, .en): "32-bit / WoW64"
        }
    }

    static func diagnosticStatus(_ status: DiagnosticStatus, language: AppLanguage) -> String {
        switch (status, language) {
        case (.passed, .zhHans): "通过"
        case (.failed, .zhHans): "失败"
        case (.skipped, .zhHans): "跳过"
        case (.notObserved, .zhHans): "未观察到"
        case (.passed, .en): "Passed"
        case (.failed, .en): "Failed"
        case (.skipped, .en): "Skipped"
        case (.notObserved, .en): "Not observed"
        }
    }

    static func diagnosticRunScope(_ scope: DiagnosticRunScope, language: AppLanguage) -> String {
        switch (scope, language) {
        case (.suite, .zhHans): "测试套件"
        case (.probe, .zhHans): "单项探针"
        case (.batch, .zhHans): "批量探针"
        case (.suite, .en): "Probe Suite"
        case (.probe, .en): "Single Probe"
        case (.batch, .en): "Probe Batch"
        }
    }

    static func testRunOutcome(_ outcome: TestRunOutcome, language: AppLanguage) -> String {
        switch (outcome, language) {
        case (.passed, .zhHans): "通过"
        case (.failed, .zhHans): "失败"
        case (.timedOut, .zhHans): "超时"
        case (.missingExit, .zhHans): "缺少退出码"
        case (.unknown, .zhHans): "未知"
        case (.passed, .en): "Passed"
        case (.failed, .en): "Failed"
        case (.timedOut, .en): "Timed Out"
        case (.missingExit, .en): "Missing Exit"
        case (.unknown, .en): "Unknown"
        }
    }

    static func testExecutionPriority(_ priority: TestExecutionPriority, language: AppLanguage) -> String {
        switch (priority, language) {
        case (.required, .zhHans): "必须处理"
        case (.high, .zhHans): "高优先级"
        case (.normal, .zhHans): "普通"
        case (.optional, .zhHans): "可选"
        case (.required, .en): "Required"
        case (.high, .en): "High"
        case (.normal, .en): "Normal"
        case (.optional, .en): "Optional"
        }
    }

    static func testExecutionReason(_ reason: TestExecutionReason, language: AppLanguage) -> String {
        switch (reason, language) {
        case (.missingRequiredAsset, .zhHans): "缺少测试文件"
        case (.missingRunner, .zhHans): "缺少单项运行器"
        case (.neverRun, .zhHans): "尚未运行"
        case (.failed, .zhHans): "最近失败"
        case (.timedOut, .zhHans): "最近超时"
        case (.missingExit, .zhHans): "缺少退出码"
        case (.stale, .zhHans): "结果已过期"
        case (.missingRequiredAsset, .en): "Missing test file"
        case (.missingRunner, .en): "Missing single-test runner"
        case (.neverRun, .en): "Never run"
        case (.failed, .en): "Last run failed"
        case (.timedOut, .en): "Last run timed out"
        case (.missingExit, .en): "Missing exit code"
        case (.stale, .en): "Result is stale"
        }
    }

    static func diagnosticRecommendation(_ item: DiagnosticItem, language: AppLanguage) -> String {
        guard item.status != .passed else {
            return language == .zhHans ? "能力可用。" : "Capability available."
        }
        switch (item.category, item.status, language) {
        case (.win32, .skipped, .zhHans):
            return "当前引擎或测试文件缺少 WoW64/32 位组件。"
        case (.win32, _, .zhHans):
            return "确认正在使用支持 32 位的 WoW64 引擎，并重新修复容器。"
        case (.network, _, .zhHans):
            return "检查代理、DNS、证书和 WinHTTP/TLS 兼容修复。"
        case (.graphics, _, .zhHans):
            return "切换 WineD3D Vulkan、GPTK/D3DMetal 或应用专用图形预设后重试。"
        case (.audio, _, .zhHans):
            return "检查 XAudio2、mmdevapi 注册和音频运行库。"
        case (.game, _, .zhHans):
            return "基础图形通过后再排查 shader、xinput 和游戏循环稳定性。"
        case (.windowing, _, .zhHans):
            return "检查窗口焦点、点击命中测试、透明层窗口和托管窗口模式。"
        case (.core, _, .zhHans):
            return "先确认 Wine 引擎、容器、wineboot 和基础 Win32 API 正常。"
        case (.win32, .skipped, .en):
            return "The engine or probe files are missing WoW64/32-bit components."
        case (.win32, _, .en):
            return "Use a WoW64-capable engine and repair the bottle."
        case (.network, _, .en):
            return "Check proxy, DNS, certificates, and WinHTTP/TLS compatibility."
        case (.graphics, _, .en):
            return "Try WineD3D Vulkan, GPTK/D3DMetal, or an app-specific graphics preset."
        case (.audio, _, .en):
            return "Check XAudio2, mmdevapi registration, and audio runtime files."
        case (.game, _, .en):
            return "After basic graphics passes, inspect shader, xinput, and game loop stability."
        case (.windowing, _, .en):
            return "Check window focus, hit testing, layered windows, and managed window mode."
        case (.core, _, .en):
            return "Verify the Wine engine, bottle, wineboot, and basic Win32 APIs first."
        }
    }

    private static func zhHans(_ key: TextKey) -> String {
        switch key {
        case .appTitle: "MacWin 管理器"
        case .applications: "应用程序"
        case .appLauncherSubtitle: "从当前容器直接启动应用"
        case .appMode: "App 模式"
        case .desktopMode: "沉浸模式"
        case .workspaceMode: "工作模式"
        case .toggleFullScreen: "切换全屏"
        case .allApps: "全部"
        case .games: "游戏"
        case .utilities: "工具"
        case .other: "其他"
        case .desktop: "桌面"
        case .desktopSubtitle: "高效窗口管理容器"
        case .desktopApps: "容器应用"
        case .pinned: "已固定"
        case .quickAccess: "快速访问"
        case .startMenu: "开始"
        case .searchApps: "搜索应用、工具或命令"
        case .noDesktopApps: "暂无容器应用"
        case .runningApps: "运行中"
        case .noRunningApps: "暂无运行中的进程"
        case .pid: "PID"
        case .probeArchitectureX86_64: "x86_64"
        case .probeArchitectureI686Wow64: "i686 / WoW64"
        case .runtimeProcessContext: "容器 %@ · PPID %@"
        case .stop: "停止"
        case .openLogFile: "打开日志文件"
        case .terminatedPid: "已停止 %@，PID %@"
        case .terminatedBottleProcesses: "已停止 %@ 容器中的 Wine 进程"
        case .stopBottleProcesses: "停止容器全部进程"
        case .stoppingBottleProcesses: "正在停止 %@ 容器中的全部进程"
        case .stoppedBottleProcesses: "已停止 %@ 容器中的 %d 个进程"
        case .stoppedBottleProcessesPartial: "%@ 容器已停止 %d 个进程，仍有 %d 个进程未退出"
        case .restartBottle: "重启容器"
        case .restartingBottle: "正在重启 %@ 容器"
        case .restartedBottle: "已重启 %@ 容器"
        case .restartBottleIncomplete: "%@ 容器未能完全重启，仍有 %d 个进程"
        case .cleanedOrphanedProcesses: "已自动清理 %d 个孤立 Wine 进程"
        case .refreshDesktop: "刷新窗口"
        case .dropInstallerTitle: "释放以安装"
        case .dropInstallerHelp: "支持 .exe 和 .msi；32 位安装器会自动切换到 WoW64 引擎"
        case .installingDroppedInstaller: "正在安装 %@"
        case .droppedInstallerStarted: "已接收安装器 %@，PID %@"
        case .unsupportedInstallerFile: "不支持的安装器文件：%@"
        case .commandPrompt: "命令提示符"
        case .thisPC: "此电脑"
        case .recycleBin: "回收站"
        case .wineConfiguration: "Wine 配置"
        case .registryEditor: "注册表编辑器"
        case .currentBottle: "当前容器"
        case .engineStatus: "引擎状态"
        case .installApps: "安装应用"
        case .openCDrive: "打开 C: 盘"
        case .openBottleFolder: "打开容器目录"
        case .openRealWineDesktop: "打开 Wine 桌面"
        case .home: "首页"
        case .market: "软件市场"
        case .bottles: "容器"
        case .diagnostics: "诊断"
        case .settings: "设置"
        case .launcherCount: "%d 个启动项"
        case .foundationStatus: "基础状态"
        case .foundationStatusReady: "就绪"
        case .foundationStatusAttention: "需关注"
        case .foundationStatusBlocked: "有阻塞"
        case .foundationStatusSummary: "状态 %@ · 阻塞 %d · 警告 %d"
        case .foundationStatusCatalog: "市场配方"
        case .foundationStatusInstallers: "安装器缓存"
        case .foundationStatusTests: "测试 EXE"
        case .foundationStatusRuntime: "运行进程"
        case .foundationStatusLogs: "问题日志"
        case .foundationStatusNoSnapshot: "基础状态快照生成中"
        case .bottleCount: "%d 个容器"
        case .noLaunchersYet: "暂无启动项"
        case .openMarket: "打开软件市场"
        case .run: "运行"
        case .runWithDiagnostics: "诊断启动"
        case .openWindowsExecutable: "打开 Windows 程序"
        case .chooseBottleToOpenExecutable: "选择用于运行该 .exe 的容器"
        case .externalExecutable: "外部 EXE"
        case .sourceFile: "来源文件"
        case .runInBottle: "在容器中运行"
        case .signedRecipes: "签名精选配方"
        case .choose: "选择"
        case .install: "安装"
        case .cancel: "取消"
        case .staged: "暂存"
        case .create: "新建"
        case .defaultBottleName: "Windows 11 容器"
        case .highPerformanceBottleName: "高性能 Windows 11"
        case .defaultInstallTarget: "默认安装到支持 32 位应用的高性能 Windows 11 容器"
        case .bottleNamePlaceholder: "容器名称"
        case .launchers: "启动项"
        case .noLaunchers: "暂无启动项"
        case .compatibilityProfile: "兼容预设"
        case .noCompatibilityProfile: "无预设"
        case .applyCompatibilityProfile: "应用兼容预设"
        case .clearCompatibilityProfile: "关闭兼容预设"
        case .repairBottle: "修复容器"
        case .scanInstalledApps: "扫描应用"
        case .scanningInstalledApps: "正在扫描 %@ 中的应用"
        case .scannedInstalledApps: "已扫描 %@，启动项 %d 个"
        case .runCommand: "运行命令"
        case .executablePlaceholder: "可执行文件路径或 Wine 内置命令"
        case .arguments: "参数"
        case .tools: "工具"
        case .windows11Desktop: "Wine 桌面"
        case .driveC: "C: 盘"
        case .bottle: "容器"
        case .logs: "日志"
        case .delete: "删除"
        case .graphicsPreset: "图形预设"
        case .nativeUIIntegration: "Mac 原生集成"
        case .applyingNativeUIIntegration: "正在应用 Mac 原生集成"
        case .appliedNativeUIIntegration: "已应用 Mac 原生集成：%@"
        case .defaultGameBottle: "默认游戏容器"
        case .gptkStatus: "GPTK/D3DMetal"
        case .gptkAvailable: "可用"
        case .gptkMissing: "缺少兼容引擎"
        case .noBottleSelected: "未选择容器"
        case .createBottle: "新建容器"
        case .diagnosticSubtitle: "Vulkan、TLS、32 位 WoW64、D3D、XAudio2"
        case .runProbeSuite: "运行测试套件"
        case .nativeUIProbe: "Mac 原生 UI 探针"
        case .nativeUIProbeSubtitle: "验证消息框、文件对话框和任务对话框是否按当前容器预设路由到 macOS。"
        case .nativeUIProbeSessionUnlocked: "macOS 会话已解锁，可以进行窗口验收"
        case .nativeUIProbeSessionLocked: "macOS 会话已锁定，解锁后才能运行窗口验收"
        case .nativeUIProbeSessionUnavailable: "无法读取 macOS 图形会话状态"
        case .nativeUIBridgeStatus: "桥接模块：Cocoa %@ · x86_64 %@ · i686 %@"
        case .nativeUIBridgeReady: "就绪"
        case .nativeUIBridgeIncomplete: "不完整"
        case .nativeUIBridgeUnavailable: "不适用"
        case .nativeUIProbeAssets: "探针资产：x86_64 %@ · i686 %@"
        case .nativeUIProbeArchitecture: "探针架构"
        case .nativeUIProbeAvailable: "可用"
        case .nativeUIProbeMissingShort: "缺失"
        case .nativeUIProbeMissing: "缺少原生 UI 探针；请先构建 Tools/build-native-ui-probe.sh。"
        case .nativeUIProbeCurrentBottle: "测试容器"
        case .runningNativeUIProbe: "正在运行原生 UI 探针：%@"
        case .nativeUIProbePassed: "原生 UI 探针通过：%@"
        case .nativeUIProbeCancelled: "原生 UI 探针已取消：%@"
        case .nativeUIProbeLastRun: "最近一次原生 UI 运行"
        case .noNativeUIProbeRun: "暂无原生 UI 探针结果"
        case .nativeUIApplicationMatrix: "真实应用兼容矩阵"
        case .nativeUIApplicationMatrixSubtitle: "汇总当前容器与隔离测试会话中的 Steam、浏览器、办公软件和联想应用商店证据。进程保持运行只算已观察，功能或渲染验证后才算通过。"
        case .nativeUIApplicationMatrixSummary: "%d 个应用 · %d 当前容器已安装 · %d 验收通过 · %d 未验证"
        case .nativeUIApplicationInstalled: "已安装"
        case .nativeUIApplicationRecipeAvailable: "配方可用"
        case .nativeUIApplicationInstallerAvailable: "安装器可用"
        case .nativeUIApplicationUnavailable: "待准备"
        case .nativeUIApplicationNotRun: "未运行"
        case .nativeUIApplicationObserved: "仅观察到启动"
        case .nativeUIApplicationPassed: "验收通过"
        case .nativeUIApplicationFailed: "启动失败"
        case .nativeUIApplicationRun: "启动"
        case .nativeUIApplicationRunDiagnostics: "诊断启动"
        case .nativeUIApplicationInstall: "安装"
        case .nativeUIApplicationSelectInstaller: "选择安装器"
        case .nativeUIApplicationPreset: "原生 UI 预设"
        case .nativeUIApplicationNeedsInstall: "%@ 尚未安装或未生成 launcher"
        case .noNativeUIApplicationMatrix: "暂无可审计的真实应用矩阵"
        case .runRepresentativeAcceptance: "执行代表性验收"
        case .runningRepresentativeAcceptance: "正在验收 Steam、HoYoPlay、浏览器和办公软件"
        case .representativeAcceptanceSummary: "代表性验收：通过 %d/%d · 待处理 %d"
        case .representativeAcceptanceFinished: "代表性验收完成：通过 %d/%d"
        case .result: "结果"
        case .exitCode: "退出码"
        case .log: "日志"
        case .recentLogs: "最近日志"
        case .diagnosticArtifacts: "诊断产物"
        case .diagnosticArtifactsSummary: "共 %d 个产物 · %.1f MB"
        case .noDiagnosticArtifacts: "暂无诊断产物；运行测试、导出报告或启动应用后会自动生成。"
        case .exportDiagnosticArtifactIndexCSV: "导出产物索引"
        case .exportingDiagnosticArtifactIndexCSV: "正在导出诊断产物索引"
        case .diagnosticArtifactIndexCSVExported: "诊断产物索引已导出：%@"
        case .artifactLogs: "日志"
        case .artifactReports: "报告"
        case .artifactTables: "表格"
        case .artifactScripts: "脚本"
        case .artifactBundles: "包"
        case .artifactRecords: "记录"
        case .artifactOthers: "其他"
        case .noRecentLogs: "暂无日志"
        case .logIssues: "日志问题归因"
        case .logIssuesSummary: "分析 %d 个日志 · 失败 %d · 注意 %d · 通过 %d"
        case .noLogIssues: "最近日志中没有发现已知问题"
        case .recentLogFailures: "最近异常日志"
        case .evidence: "证据"
        case .affectedLogs: "影响日志"
        case .logsAnalyzed: "已分析日志"
        case .logMaintenance: "日志维护"
        case .logMaintenanceSummary: "日志 %d 个 · 总量 %@ · 可清理 %@"
        case .logMaintenanceHealthy: "日志目录状态良好"
        case .supportTriage: "支持总览"
        case .supportTriageSummary: "状态 %@ · %d 项 · 阻塞 %d · 高优先级 %d · 警告 %d"
        case .supportTriageReady: "基础状态良好"
        case .supportTriageBlocked: "存在阻塞项"
        case .supportTriageAttention: "需要关注"
        case .supportTriageBlockers: "阻塞"
        case .supportTriageHighPriority: "高优先级"
        case .supportTriageWarnings: "警告"
        case .supportTriageInfo: "信息"
        case .supportTriageActions: "优先处理"
        case .noSupportTriageItems: "当前没有需要处理的基础问题"
        case .refreshSupportTriage: "刷新总览"
        case .staleLogs: "过期日志"
        case .largeLogs: "大日志"
        case .cleanupCandidates: "可清理候选"
        case .totalLogSize: "日志总量"
        case .oldestLog: "最早日志"
        case .newestLog: "最新日志"
        case .recommendations: "建议"
        case .exportLogIssueReport: "导出归因报告"
        case .exportRecommendedProbeScript: "导出建议探针脚本"
        case .exportLogMaintenanceScript: "导出维护脚本"
        case .archiveCleanupLogs: "归档候选日志"
        case .cleanHistoricalLogs: "清理历史失败日志"
        case .exportSoftwareAdaptationRunbook: "导出适配手册"
        case .exportSoftwareAdaptationQueueCSV: "导出适配队列"
        case .exportSoftwareAdaptationProbeScript: "导出探针脚本"
        case .exportSoftwareSampleCatalogCSV: "导出样本"
        case .exportSoftwareSampleCatalogRunbook: "导出样本手册"
        case .exportSoftwareSamplePreparationSnapshot: "导出就绪快照"
        case .softwareSampleLogCorrelation: "样本日志关联"
        case .softwareSampleLogCorrelationSummary: "匹配 %d 个样本 · %d 次启动 · %d 个日志"
        case .softwareSampleMatched: "已匹配样本"
        case .softwareSampleFailed: "失败样本"
        case .softwareSampleAttention: "注意样本"
        case .noSoftwareSampleLogCorrelation: "暂无样本日志关联；启动真实软件或刷新日志后会自动汇总。"
        case .exportHostEnvironmentCSV: "导出环境"
        case .exportingLogMaintenanceScript: "正在导出日志维护脚本"
        case .archivingCleanupLogs: "正在归档候选日志"
        case .cleaningHistoricalLogs: "正在清理历史失败日志"
        case .exportingLogIssueReport: "正在导出日志归因报告"
        case .exportingRecommendedProbeScript: "正在导出建议探针脚本"
        case .exportingSoftwareAdaptationRunbook: "正在导出软件适配手册"
        case .exportingSoftwareAdaptationQueueCSV: "正在导出软件适配队列"
        case .exportingSoftwareAdaptationProbeScript: "正在导出适配探针脚本"
        case .exportingSoftwareSampleCatalogCSV: "正在导出真实软件样本"
        case .exportingSoftwareSampleCatalogRunbook: "正在导出真实软件样本手册"
        case .exportingSoftwareSamplePreparationSnapshot: "正在导出样本就绪快照"
        case .exportingHostEnvironmentCSV: "正在导出宿主环境"
        case .logIssueReportExported: "已导出日志归因报告：%@"
        case .recommendedProbeScriptExported: "已导出建议探针脚本：%@"
        case .logMaintenanceScriptExported: "已导出日志维护脚本：%@"
        case .cleanupLogsArchived: "已归档 %d 个日志到 %@"
        case .noCleanupLogsToArchive: "没有需要归档的日志"
        case .historicalLogsCleaned: "已清理 %d 个历史失败日志（可在 Archive 中恢复）"
        case .softwareAdaptationRunbookExported: "已导出软件适配手册：%@"
        case .softwareAdaptationQueueCSVExported: "已导出软件适配队列：%@"
        case .softwareAdaptationProbeScriptExported: "已导出适配探针脚本：%@"
        case .softwareSampleCatalogCSVExported: "已导出真实软件样本：%@"
        case .softwareSampleCatalogRunbookExported: "已导出真实软件样本手册：%@"
        case .hostEnvironmentCSVExported: "已导出宿主环境：%@"
        case .activityTimeline: "活动时间线"
        case .activityTimelineSummary: "事件 %d · 错误 %d · 警告 %d"
        case .activityTimelineEvents: "事件"
        case .activityTimelineErrors: "错误"
        case .activityTimelineWarnings: "警告"
        case .exportInstallHistoryCSV: "导出安装历史"
        case .exportLaunchHistoryCSV: "导出启动历史"
        case .exportDiagnosticHistoryCSV: "导出诊断历史"
        case .exportingInstallHistoryCSV: "正在导出安装历史"
        case .installHistoryCSVExported: "已导出安装历史：%@"
        case .noActivityTimeline: "暂无活动记录"
        case .compatibilityRepairAudit: "兼容修复审计"
        case .compatibilityRepairAuditSummary: "审计 %d 次启动 · 就绪 %d · 缺失环境 %d · 旧参数 %d"
        case .compatibilityRepairReady: "就绪"
        case .compatibilityRepairMissing: "缺失环境"
        case .compatibilityRepairStale: "旧参数"
        case .compatibilityRuntimeCoverageMissing: "缺失运行库"
        case .compatibilityRuntimeCoverage: "引擎运行库覆盖"
        case .compatibilityAffectedBottles: "受影响容器：%@"
        case .noCompatibilityRepairAudit: "暂无需要审计的兼容启动"
        case .latestRepairFindings: "最近修复异常"
        case .severityCritical: "严重"
        case .severityHigh: "高"
        case .severityMedium: "中"
        case .severityLow: "低"
        case .refreshLogs: "刷新日志"
        case .revealInFinder: "在 Finder 中显示"
        case .checks: "检查项"
        case .noDiagnosticRun: "暂无诊断结果"
        case .diagnosticHistory: "最近诊断运行"
        case .diagnosticHistorySummary: "共 %d 次 · 失败 %d · 超时 %d"
        case .noDiagnosticHistory: "暂无诊断历史；运行测试套件或单项探针后会自动记录。"
        case .diagnosticRuns: "运行次数"
        case .passedRuns: "通过"
        case .failedRuns: "失败"
        case .timedOutRuns: "超时"
        case .durationSeconds: "耗时"
        case .bottleHealth: "容器健康"
        case .bottleHealthSummary: "容器 %d 个 · 健康 %d · 需处理 %d · 警告 %d"
        case .healthyBottles: "健康"
        case .bottlesNeedAttention: "需处理"
        case .bottleHealthWarnings: "警告"
        case .staleLaunchers: "旧启动参数"
        case .incompleteProfiles: "配置未完整应用"
        case .noBottleHealthIssues: "容器状态正常"
        case .latestBottleHealthFindings: "最近容器问题"
        case .runtimeProcesses: "运行中进程"
        case .runtimeProcessesSummary: "观察 %d 个进程 · 已审计 %d · 旧参数 %d"
        case .runningWindowsProcesses: "Windows/Wine 进程"
        case .detachedWineSystemProcesses: "孤立系统进程"
        case .staleRuntimeProcesses: "旧参数进程"
        case .runtimeFindings: "运行时发现"
        case .noRuntimeProcesses: "暂无运行中的 Windows/Wine 进程"
        case .latestRuntimeFindings: "最近运行时问题"
        case .refreshRuntimeProcesses: "刷新进程"
        case .exportRuntimeProcessesCSV: "导出表格"
        case .exportRuntimeSnapshot: "导出快照"
        case .stopRuntimeProcess: "停止进程"
        case .stopAllRuntimeProcesses: "全部停止"
        case .stopWineVirtualDesktops: "停止桌面残留"
        case .stopDetachedWineSystemProcesses: "清理容器残留"
        case .noRuntimeProcessesToStop: "暂无需要停止的 Windows/Wine 进程"
        case .terminatedRuntimeProcesses: "已停止 %d 个运行时进程"
        case .terminatedWineVirtualDesktops: "已停止 %d 个 Wine 桌面残留"
        case .terminatedDetachedWineSystemProcesses: "已清理 %d 个孤立 Wine 系统进程"
        case .terminatedRuntimeProcessesPartial: "已停止 %d 个运行时进程，%d 个停止失败"
        case .testAssets: "测试资产"
        case .testAssetsReady: "测试集合完整：%d/%d"
        case .testAssetsMissing: "缺少测试资产：%d 项"
        case .testCoverage: "测试覆盖"
        case .testCoverageSummary: "可运行 %d/%d · 已通过 %d · 未验证 %d"
        case .testExecutionPlan: "建议测试"
        case .testExecutionPlanSummary: "待处理 %d 项 · 必须处理 %d · 高优先级 %d"
        case .noTestExecutionPlan: "暂无建议测试"
        case .exportTestRunHistoryCSV: "导出运行历史"
        case .exportTestExecutionPlanCSV: "导出计划"
        case .exportTestSessionArchive: "归档测试会话"
        case .runRecommendedProbes: "运行可执行建议"
        case .requiredTests: "必须处理"
        case .highPriorityTests: "高优先级"
        case .coveragePassed: "通过"
        case .coverageFailed: "失败"
        case .coverageTimedOut: "超时"
        case .coverageUnverified: "未验证"
        case .coverageMissing: "缺失"
        case .verifiedCategories: "已验证分类"
        case .latestRuns: "最近运行"
        case .noTestCoverage: "暂无测试覆盖数据"
        case .recommendedActions: "建议动作"
        case .recommendedProbes: "建议探针"
        case .installerAssets: "安装器缓存"
        case .installerAssetsSummary: "可下载 %d · 已缓存 %d · 缺失 %d · 哈希异常 %d"
        case .installerPreparation: "安装准备清单"
        case .installerPreparationSummary: "动作 %d · 严重 %d · 警告 %d"
        case .installerPreparationCritical: "严重"
        case .installerPreparationWarning: "警告"
        case .installerPreparationInfo: "信息"
        case .installerPreparationHashMismatch: "重新下载哈希异常"
        case .installerPreparationDownloadMissing: "下载安装器"
        case .installerPreparationAddExpectedHash: "补 SHA-256"
        case .installerPreparationUseWoW64: "使用 WoW64"
        case .installerPreparationReviewOrphaned: "检查孤立安装器"
        case .installerCached: "已缓存"
        case .installerMissing: "缺失"
        case .installerHashMismatchCount: "哈希异常"
        case .downloadableInstallers: "可下载安装器"
        case .noInstallerActions: "当前没有需要下载或重新校验的安装器"
        case .installerDownloadHistory: "安装器下载历史"
        case .installerDownloadHistorySummary: "记录 %d · 下载 %d · 缓存命中 %d · 失败 %d"
        case .installerDownloadRecords: "下载记录"
        case .installerDownloadFailures: "下载失败"
        case .installerDownloadHashMismatches: "哈希异常"
        case .noInstallerDownloadHistory: "暂无安装器下载记录"
        case .openDownloads: "打开下载目录"
        case .exportInstallerDownloadScript: "导出下载脚本"
        case .exportInstallerAssetCSV: "导出清单"
        case .exportInstallerPreparationCSV: "导出准备清单"
        case .exportInstallerDownloadHistoryCSV: "导出历史"
        case .exportSoftwareTestPlanCSV: "导出计划"
        case .downloadInstaller: "下载"
        case .downloadInstallerBatch: "下载缺失/异常"
        case .localInstallerCandidates: "本地测试候选"
        case .localInstallerCandidatesSummary: "未匹配安装器 %d 个，可作为第三方软件适配样本"
        case .noLocalInstallerCandidates: "暂无未匹配的本地安装器"
        case .installLocalCandidate: "安装到高性能容器"
        case .unknownArchitecture: "未知架构"
        case .softwareTestPlan: "软件测试计划"
        case .softwareTestPlanSummary: "配方 %d 个 · 已验证 %d · 需复查 %d · 失败 %d"
        case .softwareVerified: "已验证"
        case .softwareInstalled: "已安装"
        case .softwareReadyToInstall: "可安装"
        case .softwareNeedsReview: "需复查"
        case .softwareFailing: "失败"
        case .softwareNextActions: "下一步"
        case .noSoftwareActions: "当前没有待处理软件项"
        case .softwareNoCatalog: "市场配方尚未加载"
        case .softwareSampleCatalog: "真实软件适配样本"
        case .softwareSampleCatalogSummary: "样本 %d 个 · 签名配方 %d · 本地安装器 %d · 警告 %d"
        case .softwareSampleCatalogLocalInstallers: "本地安装器"
        case .softwareSampleCatalogSignedRecipes: "签名配方"
        case .softwareSampleCatalogWarnings: "警告"
        case .noSoftwareSampleCatalog: "暂无真实软件适配样本"
        case .softwareCollection: "测试软件集合"
        case .softwareCollectionSummary: "集合 %d 个 · 配方 %d 个 · 已缓存 %d · 缺安装器 %d · 已验证 %d"
        case .softwareCollectionCoverage: "集合覆盖"
        case .softwareCollectionMissingRecipes: "缺失配方"
        case .softwareCollectionMissingInstallers: "缺安装器"
        case .softwareCollectionActionRequired: "待处理"
        case .softwareCollectionAcceptance: "集合验收"
        case .softwareCollectionAcceptanceSummary: "状态 %@ · 动作 %d · 阻塞 %d · 高优先级 %d"
        case .softwareCollectionAcceptanceState: "验收状态"
        case .softwareCollectionAcceptanceBlockers: "阻塞"
        case .softwareCollectionAcceptanceHighPriority: "高优先级"
        case .softwareCollectionAcceptanceWarnings: "警告"
        case .softwareCollectionAcceptanceActions: "验收动作"
        case .noSoftwareCollectionAcceptanceActions: "当前没有集合验收动作"
        case .softwareCollectionDownloadMissing: "下载缺失安装器"
        case .exportSoftwareCollectionCSV: "导出集合"
        case .exportSoftwareCollectionDownloadScript: "导出下载脚本"
        case .exportSoftwareCollectionAcceptanceRunbook: "导出验收脚本"
        case .exportSoftwareCollectionBundle: "导出集合包"
        case .noSoftwareCollection: "暂无测试软件集合"
        case .softwareSmokeMatrix: "软件适配矩阵"
        case .softwareSmokeMatrixSummary: "配方 %d 个 · 阻塞 %d · 警告 %d · 失败 %d · 已验证 %d"
        case .smokeBlocked: "阻塞"
        case .smokeWarnings: "警告"
        case .smokeFailures: "失败"
        case .smokeVerified: "已验证"
        case .smokeStage: "阶段"
        case .smokeChecklist: "检查清单"
        case .noSoftwareSmokeMatrix: "暂无软件适配矩阵"
        case .blockers: "阻塞项"
        case .latestLog: "最近日志"
        case .runNextAction: "执行下一步"
        case .exportCapabilityReport: "导出能力报告"
        case .exportSupportBundle: "导出诊断包"
        case .engineAndCatalog: "引擎与市场"
        case .engine: "引擎"
        case .name: "名称"
        case .version: "版本"
        case .architecture: "架构"
        case .runtime: "运行库"
        case .win32Compatibility: "32 位兼容"
        case .win32Supported: "支持 32 位应用（WoW64）"
        case .win32Unsupported: "不支持 32 位应用"
        case .requiresWin32: "需要 32 位"
        case .refreshEngine: "刷新引擎"
        case .catalog: "市场"
        case .recipes: "配方数量"
        case .trust: "信任"
        case .signedCuratedSource: "签名精选源"
        case .refreshCatalog: "刷新市场"
        case .data: "数据"
        case .root: "根目录"
        case .openLogs: "打开日志"
        case .language: "语言"
        case .ready: "就绪"
        case .importingEngine: "正在导入引擎"
        case .preparingDefaultBottle: "正在准备高性能容器"
        case .preparingDesktop: "正在准备 Wine 桌面"
        case .creatingBottle: "正在创建容器"
        case .repairingBottle: "正在修复容器 %@"
        case .applyingCompatibilityProfile: "正在应用兼容预设"
        case .applyingGraphicsPreset: "正在应用图形预设"
        case .installing: "正在安装 %@"
        case .launching: "正在启动 %@"
        case .launchingWithDiagnostics: "正在诊断启动 %@"
        case .runningCommand: "正在运行命令"
        case .keepSystemAwake: "保持系统清醒"
        case .preventScreenLockHint: "运行时防止休眠与熄屏，完成后自动恢复。"
        case .deleting: "正在删除 %@"
        case .runningDiagnostics: "正在运行诊断"
        case .exportingCapabilityReport: "正在导出能力报告"
        case .exportingSupportBundle: "正在导出诊断包"
        case .exportingInstallerDownloadScript: "正在导出下载脚本"
        case .exportingInstallerAssetCSV: "正在导出安装器清单"
        case .exportingInstallerPreparationCSV: "正在导出安装准备清单"
        case .exportingInstallerDownloadHistoryCSV: "正在导出下载历史"
        case .exportingSoftwareTestPlanCSV: "正在导出软件测试计划"
        case .exportingSoftwareCollectionCSV: "正在导出测试软件集合"
        case .exportingSoftwareCollectionDownloadScript: "正在导出集合下载脚本"
        case .exportingSoftwareCollectionAcceptanceRunbook: "正在导出集合验收脚本"
        case .exportingSoftwareCollectionBundle: "正在导出测试集合包"
        case .exportingTestExecutionPlanCSV: "正在导出建议测试计划"
        case .exportingTestRunHistoryCSV: "正在导出测试运行历史"
        case .exportingTestSessionArchive: "正在归档测试会话"
        case .exportingLaunchHistoryCSV: "正在导出启动历史"
        case .exportingDiagnosticHistoryCSV: "正在导出诊断历史"
        case .downloadingInstaller: "正在下载 %@"
        case .downloadingInstallerBatch: "正在下载 %d 个安装器"
        case .installerDownloaded: "已缓存安装器：%@"
        case .installerDownloadBatchFinished: "已缓存 %d 个安装器"
        case .runningProbe: "正在运行探针 %@"
        case .probeFinished: "探针 %@ 已完成"
        case .runningProbeBatch: "正在运行 %d 个探针"
        case .probeBatchFinished: "已完成 %d 个探针"
        case .rerunProbe: "重新运行探针"
        case .runCoverageProbes: "运行待验证探针"
        case .diagnosticsPassed: "诊断通过"
        case .diagnosticsFinishedWithFailures: "诊断完成，但存在失败项"
        case .capabilityReportExported: "已导出能力报告：%@"
        case .supportBundleExported: "已导出诊断包：%@"
        case .supportTriageRefreshed: "已刷新支持总览：%d 项"
        case .runtimeProcessesRefreshed: "已刷新运行时进程：%d 个"
        case .exportingRuntimeProcessesCSV: "正在导出运行时进程表格"
        case .exportingRuntimeSnapshot: "正在导出运行时进程快照"
        case .runtimeProcessesCSVExported: "已导出运行时进程表格：%@"
        case .runtimeSnapshotExported: "已导出运行时快照：%@"
        case .terminatedRuntimeProcess: "已停止 %@，PID %@"
        case .installerDownloadScriptExported: "已导出下载脚本：%@"
        case .installerAssetCSVExported: "已导出安装器清单：%@"
        case .installerPreparationCSVExported: "已导出安装准备清单：%@"
        case .installerDownloadHistoryCSVExported: "已导出下载历史：%@"
        case .softwareSamplePreparationSnapshotExported: "已导出样本就绪快照：%@"
        case .softwareTestPlanCSVExported: "已导出软件测试计划：%@"
        case .softwareCollectionCSVExported: "已导出测试软件集合：%@"
        case .softwareCollectionDownloadScriptExported: "已导出集合下载脚本：%@"
        case .softwareCollectionAcceptanceRunbookExported: "已导出集合验收脚本：%@"
        case .softwareCollectionBundleExported: "已导出测试集合包：%@"
        case .testExecutionPlanCSVExported: "已导出建议测试计划：%@"
        case .testRunHistoryCSVExported: "已导出测试运行历史：%@"
        case .testSessionArchiveExported: "已归档测试会话：%@"
        case .launchHistoryCSVExported: "已导出启动历史：%@"
        case .diagnosticHistoryCSVExported: "已导出诊断历史：%@"
        case .catalogExpired: "市场配方已过期"
        case .catalogError: "市场错误"
        case .noEngineRegistered: "未注册引擎"
        case .noEngineForBottle: "容器 %@ 没有关联引擎"
        case .windowsDesktopOnlyWin11: "桌面模式仅支持 Windows 11 容器"
        case .diagnosticLaunchTitle: "%@（诊断）"
        case .launchedPid: "已启动 %@，PID %@"
        case .startedPid: "已启动，PID %@"
        case .alreadyRunningPid: "%@ 已在运行，PID %@，已阻止重复启动"
        case .actionAlreadyInProgress: "%@ 正在处理中，已忽略重复操作"
        case .created: "已创建 %@"
        case .repairedBottle: "已修复 %@"
        case .appliedCompatibilityProfile: "已为 %@ 应用兼容预设：%@"
        case .clearedCompatibilityProfile: "已关闭 %@ 的兼容预设"
        case .appliedGraphicsPreset: "已应用图形预设：%@"
        case .installedIntoDefaultBottle: "已安装 %@ 到高性能容器"
        case .deleted: "已删除 %@"
        case .unableToLaunchProcess: "无法启动进程：%@"
        case .wineRuntimeUnavailable: "Wine 运行时暂不可用：Rosetta 中有不可中断的 Wine 进程（PID：%@）。请重启 macOS 或恢复 Rosetta 后再启动 Windows 应用。"
        case .missingFile: "缺少文件：%@"
        case .processFailed: "进程失败（%@）：%@"
        case .unsupported: "不支持：%@"
        case .invalidManifest: "清单无效：%@"
        case .signatureInvalid: "市场签名无效"
        case .hashMismatch: "哈希校验失败：%@"
        case .installerRequired: "需要安装器：%@"
        case .excellent: "优秀"
        case .good: "良好"
        case .limited: "有限"
        case .experimental: "实验"
        case .unknown: "未知"
        case .wineD3DVulkanPreset: "WineD3D Vulkan（稳定）"
        case .wineD3DVulkanPresetHelp: "当前验证通过的默认游戏路径，适合 D3D9/D3D11/vkd3d 基础兼容。"
        case .gptkD3DMetalPreset: "GPTK D3DMetal（DX12）"
        case .gptkD3DMetalPresetHelp: "使用 GPTK 的 dxgi/d3d12 与 D3DMetal.framework，面向 Cyberpunk 2077 类 DX12 游戏；D3D11 继续走稳定 Vulkan。"
        case .gptkD3DMetalDXRPreset: "GPTK D3DMetal + DXR（实验）"
        case .gptkD3DMetalDXRPresetHelp: "在 D3DMetal 基础上启用 DXR 标记，适合光追实验；稳定性取决于游戏与硬件。"
        case .bambuStudioSoftwareOpenGLProfile: "Bambu Studio 软件 OpenGL 与运行库修复"
        case .blenderSoftwareOpenGLProfile: "Blender 软件 OpenGL 4.3 视口修复"
        case .orcaSlicerNativeOpenGLProfile: "OrcaSlicer 原生 OpenGL 与启动修复"
        case .browserGeckoProfile: "Gecko 浏览器兼容模式"
        case .hoYoPlayProfile: "HoYoPlay WebView 文字修复"
        case .lenovoAppStoreProfile: "联想应用商店黑屏修复"
        case .tencentAppStoreProfile: "应用宝 WebView 修复"
        case .steamClientProfile: "Steam 客户端"
        case .cefSoftwareRendererProfile: "WebView 文字修复"
        case .chromiumBrowserProfile: "Chromium 浏览器"
        case .curaSlicerProfile: "Cura 切片与 OpenGL 修复"
        case .kritaOpenGLProfile: "Krita 画布与 OpenGL 修复"
        case .geogebraLegacyElectron32Profile: "GeoGebra 32 位兼容模式"
        case .gmshOpenGLProfile: "Gmsh OpenGL 视口"
        case .freeCADOpenGLProfile: "FreeCAD Qt 与 OpenGL 视口修复"
        case .kiCadEDAProfile: "KiCad 中文界面与 OpenGL 修复"
        case .libreCADQtProfile: "LibreCAD 中文界面与 CAD 画布修复"
        case .jabRefJavaFXD3DProfile: "JabRef JavaFX D3D 文字与窗口修复"
        case .dbeaverSWTProfile: "DBeaver Java/SWT 字体与窗口修复"
        case .jaspQtWebEngineQrcProfile: "JASP QtWebEngine/qrc 修复"
        case .meshLabSoftwareOpenGLProfile: "MeshLab 软件 OpenGL 视口"
        case .openPLCEditorProfile: "OpenPLC Electron 画面与时区修复"
        case .openSCADSoftwareOpenGLProfile: "OpenSCAD 软件 OpenGL 视口修复"
        case .sweetHome3DOpenGLProfile: "Sweet Home 3D 64 位 OpenGL 修复"
        case .mRemoteNG1782Profile: "mRemoteNG 1.78.2 .NET 修复"
        case .museScoreStudioProfile: "MuseScore Studio 输入修复"
        case .notepadPlusPlusGDIProfile: "Notepad++ GDI 稳定模式"
        case .portableAppsPlatformProfile: "PortableApps 主界面主题修复"
        case .portableAppsUtilityProfile: "PortableApps 辅助工具兼容"
        case .officeSuiteProfile: "Office 套件兼容模式"
        case .wpsOfficeProfile: "WPS Office 中文文档模式"
        case .qtBrowserSoftwareProfile: "Qt 浏览器软件渲染"
        case .qucsSQt6Profile: "Qucs-S Qt6 工程软件"
        case .qtRhiSoftwareProfile: "Qt RHI 软件渲染"
        case .qtWidgetsSoftwareProfile: "Qt Widgets 软件渲染"
        case .softMakerOfficeProfile: "SoftMaker Office COM 修复"
        case .supermium32BrowserProfile: "Supermium 32 位浏览器"
        case .texStudioQt6Profile: "TeXstudio Qt6 修复"
        case .sevenZipGDIProfile: "7-Zip GDI 稳定模式"
        case .zoteroGecko32Profile: "Zotero 32 位 Gecko 修复"
        }
    }

    private static func en(_ key: TextKey) -> String {
        switch key {
        case .appTitle: "MacWin Manager"
        case .applications: "Applications"
        case .appLauncherSubtitle: "Launch apps directly from the current bottle"
        case .appMode: "App Mode"
        case .desktopMode: "Immersive Mode"
        case .workspaceMode: "Workspace Mode"
        case .toggleFullScreen: "Toggle Full Screen"
        case .allApps: "All"
        case .games: "Games"
        case .utilities: "Tools"
        case .other: "Other"
        case .desktop: "Desktop"
        case .desktopSubtitle: "High-efficiency window container"
        case .desktopApps: "Container Apps"
        case .pinned: "Pinned"
        case .quickAccess: "Quick Access"
        case .startMenu: "Start"
        case .searchApps: "Search apps, tools, or commands"
        case .noDesktopApps: "No container apps"
        case .runningApps: "Running"
        case .noRunningApps: "No running processes"
        case .pid: "PID"
        case .stop: "Stop"
        case .openLogFile: "Open Log File"
        case .terminatedPid: "Stopped %@, PID %@"
        case .terminatedBottleProcesses: "Stopped Wine processes in %@"
        case .stopBottleProcesses: "Stop Container Processes"
        case .stoppingBottleProcesses: "Stopping all processes in %@"
        case .stoppedBottleProcesses: "Stopped %@: %d processes"
        case .stoppedBottleProcessesPartial: "Stopped %@: %d processes; %d remain"
        case .restartBottle: "Restart Container"
        case .restartingBottle: "Restarting %@"
        case .restartedBottle: "Restarted %@"
        case .restartBottleIncomplete: "%@ could not restart completely; %d processes remain"
        case .cleanedOrphanedProcesses: "Automatically cleaned %d orphaned Wine processes"
        case .refreshDesktop: "Refresh Windows"
        case .dropInstallerTitle: "Release to Install"
        case .dropInstallerHelp: "Supports .exe and .msi; 32-bit installers automatically use the WoW64 engine"
        case .installingDroppedInstaller: "Installing %@"
        case .droppedInstallerStarted: "Accepted installer %@, PID %@"
        case .unsupportedInstallerFile: "Unsupported installer file: %@"
        case .commandPrompt: "Command Prompt"
        case .thisPC: "This PC"
        case .recycleBin: "Recycle Bin"
        case .wineConfiguration: "Wine Configuration"
        case .registryEditor: "Registry Editor"
        case .currentBottle: "Current Bottle"
        case .engineStatus: "Engine Status"
        case .installApps: "Install Apps"
        case .openCDrive: "Open C: Drive"
        case .openBottleFolder: "Open Bottle Folder"
        case .openRealWineDesktop: "Open Wine Desktop"
        case .home: "Home"
        case .market: "Market"
        case .bottles: "Bottles"
        case .diagnostics: "Diagnostics"
        case .settings: "Settings"
        case .launcherCount: "%d launchers"
        case .foundationStatus: "Foundation Status"
        case .foundationStatusReady: "Ready"
        case .foundationStatusAttention: "Needs Attention"
        case .foundationStatusBlocked: "Blocked"
        case .foundationStatusSummary: "State %@ · %d blockers · %d warnings"
        case .foundationStatusCatalog: "Market Recipes"
        case .foundationStatusInstallers: "Installer Cache"
        case .foundationStatusTests: "Test EXEs"
        case .foundationStatusRuntime: "Runtime Processes"
        case .foundationStatusLogs: "Problem Logs"
        case .foundationStatusNoSnapshot: "Foundation status snapshot is being generated"
        case .bottleCount: "%d bottles"
        case .noLaunchersYet: "No launchers yet"
        case .openMarket: "Open Market"
        case .run: "Run"
        case .runWithDiagnostics: "Diagnostic Launch"
        case .openWindowsExecutable: "Open Windows Executable"
        case .chooseBottleToOpenExecutable: "Choose the bottle for this .exe"
        case .externalExecutable: "External EXE"
        case .sourceFile: "Source File"
        case .runInBottle: "Run in Bottle"
        case .signedRecipes: "Signed curated recipes"
        case .choose: "Choose"
        case .install: "Install"
        case .cancel: "Cancel"
        case .staged: "Staged"
        case .create: "Create"
        case .defaultBottleName: "Windows 11 Bottle"
        case .highPerformanceBottleName: "High Performance Windows 11"
        case .defaultInstallTarget: "Default installs go to the high performance Windows 11 bottle with 32-bit app support"
        case .bottleNamePlaceholder: "Bottle name"
        case .launchers: "Launchers"
        case .noLaunchers: "No launchers"
        case .compatibilityProfile: "Compatibility Preset"
        case .noCompatibilityProfile: "No Preset"
        case .applyCompatibilityProfile: "Apply Compatibility Preset"
        case .clearCompatibilityProfile: "Disable Compatibility Preset"
        case .repairBottle: "Repair Bottle"
        case .scanInstalledApps: "Scan Apps"
        case .scanningInstalledApps: "Scanning apps in %@"
        case .scannedInstalledApps: "Scanned %@, %d launchers"
        case .runCommand: "Run Command"
        case .executablePlaceholder: "Executable path or Wine builtin"
        case .arguments: "Arguments"
        case .tools: "Tools"
        case .windows11Desktop: "Wine Desktop"
        case .driveC: "C: Drive"
        case .bottle: "Bottle"
        case .logs: "Logs"
        case .delete: "Delete"
        case .graphicsPreset: "Graphics Preset"
        case .nativeUIIntegration: "Mac Native Integration"
        case .applyingNativeUIIntegration: "Applying Mac native integration"
        case .appliedNativeUIIntegration: "Applied Mac native integration: %@"
        case .defaultGameBottle: "Default Game Bottle"
        case .gptkStatus: "GPTK/D3DMetal"
        case .gptkAvailable: "Available"
        case .gptkMissing: "Compatible engine missing"
        case .noBottleSelected: "No bottle selected"
        case .createBottle: "Create Bottle"
        case .diagnosticSubtitle: "Vulkan, TLS, 32-bit WoW64, D3D, XAudio2"
        case .runProbeSuite: "Run Probe Suite"
        case .nativeUIProbe: "Mac Native UI Probes"
        case .nativeUIProbeSubtitle: "Verify that message boxes, file dialogs, and task dialogs route to macOS under the current bottle preset."
        case .nativeUIProbeSessionUnlocked: "The macOS session is unlocked and ready for window acceptance"
        case .nativeUIProbeSessionLocked: "The macOS session is locked; unlock it before running window acceptance"
        case .nativeUIProbeSessionUnavailable: "The macOS GUI session state is unavailable"
        case .nativeUIBridgeStatus: "Bridge modules: Cocoa %@ · x86_64 %@ · i686 %@"
        case .nativeUIBridgeReady: "Ready"
        case .nativeUIBridgeIncomplete: "Incomplete"
        case .nativeUIBridgeUnavailable: "N/A"
        case .nativeUIProbeAssets: "Probe assets: x86_64 %@ · i686 %@"
        case .nativeUIProbeArchitecture: "Probe Architecture"
        case .nativeUIProbeAvailable: "Available"
        case .nativeUIProbeMissingShort: "Missing"
        case .nativeUIProbeMissing: "Native UI probe binaries are missing; build Tools/build-native-ui-probe.sh first."
        case .nativeUIProbeCurrentBottle: "Test Bottle"
        case .runningNativeUIProbe: "Running native UI probe: %@"
        case .nativeUIProbePassed: "Native UI probe passed: %@"
        case .nativeUIProbeCancelled: "Native UI probe cancelled: %@"
        case .nativeUIProbeLastRun: "Latest Native UI Run"
        case .noNativeUIProbeRun: "No native UI probe result yet"
        case .nativeUIApplicationMatrix: "Real Application Compatibility Matrix"
        case .nativeUIApplicationMatrixSubtitle: "Combines evidence from the current bottle and isolated smoke sessions for Steam, browsers, office apps, and Lenovo App Store. Staying alive is observed; functional or rendered-content proof is required to pass."
        case .nativeUIApplicationMatrixSummary: "%d apps · %d installed here · %d accepted · %d unverified"
        case .nativeUIApplicationInstalled: "Installed"
        case .nativeUIApplicationRecipeAvailable: "Recipe available"
        case .nativeUIApplicationInstallerAvailable: "Installer available"
        case .nativeUIApplicationUnavailable: "Needs preparation"
        case .nativeUIApplicationNotRun: "Not run"
        case .nativeUIApplicationObserved: "Launch only observed"
        case .nativeUIApplicationPassed: "Accepted"
        case .nativeUIApplicationFailed: "Launch failed"
        case .nativeUIApplicationRun: "Run"
        case .nativeUIApplicationRunDiagnostics: "Diagnostic launch"
        case .nativeUIApplicationInstall: "Install"
        case .nativeUIApplicationSelectInstaller: "Choose installer"
        case .nativeUIApplicationPreset: "Native UI preset"
        case .nativeUIApplicationNeedsInstall: "%@ is not installed or has no generated launcher"
        case .noNativeUIApplicationMatrix: "No auditable real-application matrix yet"
        case .runRepresentativeAcceptance: "Run Representative Acceptance"
        case .runningRepresentativeAcceptance: "Running Steam, HoYoPlay, browser, and office acceptance"
        case .representativeAcceptanceSummary: "Representative acceptance: %d/%d passed · %d pending"
        case .representativeAcceptanceFinished: "Representative acceptance finished: %d/%d passed"
        case .result: "Result"
        case .exitCode: "Exit Code"
        case .log: "Log"
        case .recentLogs: "Recent Logs"
        case .diagnosticArtifacts: "Diagnostic Artifacts"
        case .diagnosticArtifactsSummary: "%d artifacts · %.1f MB"
        case .noDiagnosticArtifacts: "No diagnostic artifacts yet; tests, exports, and app launches will create them automatically."
        case .exportDiagnosticArtifactIndexCSV: "Export Artifact Index"
        case .exportingDiagnosticArtifactIndexCSV: "Exporting diagnostic artifact index"
        case .diagnosticArtifactIndexCSVExported: "Diagnostic artifact index exported: %@"
        case .artifactLogs: "Logs"
        case .artifactReports: "Reports"
        case .artifactTables: "Tables"
        case .artifactScripts: "Scripts"
        case .artifactBundles: "Bundles"
        case .artifactRecords: "Records"
        case .artifactOthers: "Other"
        case .noRecentLogs: "No logs yet"
        case .logIssues: "Log Issue Triage"
        case .logIssuesSummary: "%d logs analyzed · %d failed · %d attention · %d passed"
        case .noLogIssues: "No known issues in recent logs"
        case .recentLogFailures: "Recent Problem Logs"
        case .evidence: "Evidence"
        case .affectedLogs: "Affected Logs"
        case .logsAnalyzed: "Logs Analyzed"
        case .logMaintenance: "Log Maintenance"
        case .logMaintenanceSummary: "%d logs · %@ total · %@ cleanup candidates"
        case .logMaintenanceHealthy: "Logs directory looks healthy"
        case .supportTriage: "Support Triage"
        case .supportTriageSummary: "State %@ · %d items · %d blockers · %d high · %d warnings"
        case .supportTriageReady: "Ready"
        case .supportTriageBlocked: "Blocked"
        case .supportTriageAttention: "Needs Attention"
        case .supportTriageBlockers: "Blockers"
        case .supportTriageHighPriority: "High Priority"
        case .supportTriageWarnings: "Warnings"
        case .supportTriageInfo: "Info"
        case .supportTriageActions: "Priority Actions"
        case .noSupportTriageItems: "No foundational issues need attention"
        case .refreshSupportTriage: "Refresh Triage"
        case .staleLogs: "Stale Logs"
        case .largeLogs: "Large Logs"
        case .cleanupCandidates: "Cleanup Candidates"
        case .totalLogSize: "Total Log Size"
        case .oldestLog: "Oldest Log"
        case .newestLog: "Newest Log"
        case .recommendations: "Recommendations"
        case .exportLogIssueReport: "Export Triage Report"
        case .exportRecommendedProbeScript: "Export Probe Script"
        case .exportLogMaintenanceScript: "Export Maintenance Script"
        case .archiveCleanupLogs: "Archive Cleanup Logs"
        case .cleanHistoricalLogs: "Clean Historical Failures"
        case .exportSoftwareAdaptationRunbook: "Export Runbook"
        case .exportSoftwareAdaptationQueueCSV: "Export Queue"
        case .exportSoftwareAdaptationProbeScript: "Export Probe Script"
        case .exportSoftwareSampleCatalogCSV: "Export Samples"
        case .exportSoftwareSampleCatalogRunbook: "Export Sample Runbook"
        case .exportSoftwareSamplePreparationSnapshot: "Export Readiness Snapshot"
        case .softwareSampleLogCorrelation: "Sample Log Correlation"
        case .softwareSampleLogCorrelationSummary: "%d samples matched · %d launches · %d logs"
        case .softwareSampleMatched: "Matched Samples"
        case .softwareSampleFailed: "Failed Samples"
        case .softwareSampleAttention: "Attention Samples"
        case .noSoftwareSampleLogCorrelation: "No sample log correlation yet; launch real software or refresh logs to summarize it."
        case .exportHostEnvironmentCSV: "Export Environment"
        case .exportingLogMaintenanceScript: "Exporting log maintenance script"
        case .archivingCleanupLogs: "Archiving cleanup logs"
        case .cleaningHistoricalLogs: "Cleaning historical failure logs"
        case .exportingLogIssueReport: "Exporting log triage report"
        case .exportingRecommendedProbeScript: "Exporting recommended probe script"
        case .exportingSoftwareAdaptationRunbook: "Exporting software adaptation runbook"
        case .exportingSoftwareAdaptationQueueCSV: "Exporting software adaptation queue"
        case .exportingSoftwareAdaptationProbeScript: "Exporting adaptation probe script"
        case .exportingSoftwareSampleCatalogCSV: "Exporting software samples"
        case .exportingSoftwareSampleCatalogRunbook: "Exporting software sample runbook"
        case .exportingSoftwareSamplePreparationSnapshot: "Exporting sample readiness snapshot"
        case .exportingHostEnvironmentCSV: "Exporting host environment"
        case .logIssueReportExported: "Exported log triage report: %@"
        case .recommendedProbeScriptExported: "Exported recommended probe script: %@"
        case .logMaintenanceScriptExported: "Exported log maintenance script: %@"
        case .cleanupLogsArchived: "Archived %d logs to %@"
        case .noCleanupLogsToArchive: "No logs need archiving"
        case .historicalLogsCleaned: "Cleaned %d historical failure logs; recoverable from Archive"
        case .softwareAdaptationRunbookExported: "Exported software adaptation runbook: %@"
        case .softwareAdaptationQueueCSVExported: "Exported software adaptation queue: %@"
        case .softwareAdaptationProbeScriptExported: "Exported adaptation probe script: %@"
        case .softwareSampleCatalogCSVExported: "Exported software samples: %@"
        case .softwareSampleCatalogRunbookExported: "Exported software sample runbook: %@"
        case .hostEnvironmentCSVExported: "Exported host environment: %@"
        case .activityTimeline: "Activity Timeline"
        case .activityTimelineSummary: "%d events · %d errors · %d warnings"
        case .activityTimelineEvents: "Events"
        case .activityTimelineErrors: "Errors"
        case .activityTimelineWarnings: "Warnings"
        case .exportInstallHistoryCSV: "Export Install History"
        case .exportLaunchHistoryCSV: "Export Launch History"
        case .exportDiagnosticHistoryCSV: "Export Diagnostic History"
        case .exportingInstallHistoryCSV: "Exporting install history"
        case .installHistoryCSVExported: "Exported install history: %@"
        case .noActivityTimeline: "No activity yet"
        case .compatibilityRepairAudit: "Compatibility Repair Audit"
        case .compatibilityRepairAuditSummary: "%d launches audited · %d ready · %d missing env · %d stale flags"
        case .compatibilityRepairReady: "Ready"
        case .compatibilityRepairMissing: "Missing Env"
        case .compatibilityRepairStale: "Stale Flags"
        case .compatibilityRuntimeCoverageMissing: "Missing Runtime"
        case .compatibilityRuntimeCoverage: "Engine Runtime Coverage"
        case .compatibilityAffectedBottles: "Affected bottles: %@"
        case .noCompatibilityRepairAudit: "No compatibility launches to audit yet"
        case .latestRepairFindings: "Latest Repair Findings"
        case .severityCritical: "Critical"
        case .severityHigh: "High"
        case .severityMedium: "Medium"
        case .severityLow: "Low"
        case .refreshLogs: "Refresh Logs"
        case .revealInFinder: "Reveal in Finder"
        case .checks: "Checks"
        case .noDiagnosticRun: "No diagnostic run"
        case .diagnosticHistory: "Recent Diagnostic Runs"
        case .diagnosticHistorySummary: "%d runs · %d failed · %d timed out"
        case .noDiagnosticHistory: "No diagnostic history yet; probe suites and individual probes are recorded automatically."
        case .diagnosticRuns: "Runs"
        case .passedRuns: "Passed"
        case .failedRuns: "Failed"
        case .timedOutRuns: "Timed Out"
        case .durationSeconds: "Duration"
        case .bottleHealth: "Bottle Health"
        case .bottleHealthSummary: "%d bottles · %d healthy · %d action required · %d warnings"
        case .healthyBottles: "Healthy"
        case .bottlesNeedAttention: "Action Required"
        case .bottleHealthWarnings: "Warnings"
        case .staleLaunchers: "Stale Launch Flags"
        case .incompleteProfiles: "Incomplete Profiles"
        case .noBottleHealthIssues: "Bottle state looks healthy"
        case .latestBottleHealthFindings: "Latest Bottle Findings"
        case .runtimeProcesses: "Runtime Processes"
        case .runtimeProcessesSummary: "%d observed · %d audited · %d stale flags"
        case .runningWindowsProcesses: "Windows/Wine Processes"
        case .detachedWineSystemProcesses: "Detached System Processes"
        case .staleRuntimeProcesses: "Stale Flag Processes"
        case .runtimeFindings: "Runtime Findings"
        case .noRuntimeProcesses: "No running Windows/Wine processes observed"
        case .latestRuntimeFindings: "Latest Runtime Findings"
        case .refreshRuntimeProcesses: "Refresh Processes"
        case .exportRuntimeProcessesCSV: "Export Table"
        case .exportRuntimeSnapshot: "Export Snapshot"
        case .stopRuntimeProcess: "Stop Process"
        case .stopAllRuntimeProcesses: "Stop All"
        case .stopWineVirtualDesktops: "Stop Desktop Leftovers"
        case .stopDetachedWineSystemProcesses: "Clean Container Leftovers"
        case .noRuntimeProcessesToStop: "No Windows/Wine processes need stopping"
        case .terminatedRuntimeProcesses: "Stopped %d runtime processes"
        case .terminatedWineVirtualDesktops: "Stopped %d Wine desktop leftovers"
        case .terminatedDetachedWineSystemProcesses: "Cleaned %d detached Wine system processes"
        case .terminatedRuntimeProcessesPartial: "Stopped %d runtime processes; %d failed"
        case .testAssets: "Test Assets"
        case .testAssetsReady: "Test suite ready: %d/%d"
        case .testAssetsMissing: "Missing test assets: %d"
        case .testCoverage: "Test Coverage"
        case .testCoverageSummary: "%d/%d runnable · %d passed · %d unverified"
        case .testExecutionPlan: "Recommended Tests"
        case .testExecutionPlanSummary: "%d pending · %d required · %d high priority"
        case .noTestExecutionPlan: "No recommended tests"
        case .exportTestRunHistoryCSV: "Export Run History"
        case .exportTestExecutionPlanCSV: "Export Plan"
        case .exportTestSessionArchive: "Archive Session"
        case .runRecommendedProbes: "Run Runnable Recommendations"
        case .requiredTests: "Required"
        case .highPriorityTests: "High Priority"
        case .coveragePassed: "Passed"
        case .coverageFailed: "Failed"
        case .coverageTimedOut: "Timed Out"
        case .coverageUnverified: "Unverified"
        case .coverageMissing: "Missing"
        case .verifiedCategories: "Verified Categories"
        case .latestRuns: "Latest Runs"
        case .noTestCoverage: "No test coverage data yet"
        case .recommendedActions: "Recommended Actions"
        case .recommendedProbes: "Recommended Probes"
        case .installerAssets: "Installer Cache"
        case .installerAssetsSummary: "%d downloadable · %d cached · %d missing · %d hash issues"
        case .installerPreparation: "Installer Preparation"
        case .installerPreparationSummary: "%d actions · %d critical · %d warnings"
        case .installerPreparationCritical: "Critical"
        case .installerPreparationWarning: "Warning"
        case .installerPreparationInfo: "Info"
        case .installerPreparationHashMismatch: "Redownload hash mismatch"
        case .installerPreparationDownloadMissing: "Download installer"
        case .installerPreparationAddExpectedHash: "Add SHA-256"
        case .installerPreparationUseWoW64: "Use WoW64"
        case .installerPreparationReviewOrphaned: "Review orphaned installer"
        case .installerCached: "Cached"
        case .installerMissing: "Missing"
        case .installerHashMismatchCount: "Hash Issues"
        case .downloadableInstallers: "Downloadable Installers"
        case .noInstallerActions: "No installer downloads or rechecks needed"
        case .installerDownloadHistory: "Installer Download History"
        case .installerDownloadHistorySummary: "%d records · %d downloaded · %d cached · %d failed"
        case .installerDownloadRecords: "Download Records"
        case .installerDownloadFailures: "Download Failures"
        case .installerDownloadHashMismatches: "Hash Mismatches"
        case .noInstallerDownloadHistory: "No installer download records yet"
        case .openDownloads: "Open Downloads"
        case .exportInstallerDownloadScript: "Export Download Script"
        case .exportInstallerAssetCSV: "Export List"
        case .exportInstallerPreparationCSV: "Export Prep"
        case .exportInstallerDownloadHistoryCSV: "Export History"
        case .exportSoftwareTestPlanCSV: "Export Plan"
        case .downloadInstaller: "Download"
        case .downloadInstallerBatch: "Download Missing"
        case .localInstallerCandidates: "Local Test Candidates"
        case .localInstallerCandidatesSummary: "%d unmatched installers can be used as third-party app samples"
        case .noLocalInstallerCandidates: "No unmatched local installers"
        case .installLocalCandidate: "Install into High Performance Bottle"
        case .unknownArchitecture: "Unknown architecture"
        case .softwareTestPlan: "Software Test Plan"
        case .softwareTestPlanSummary: "%d recipes · %d verified · %d review · %d failing"
        case .softwareVerified: "Verified"
        case .softwareInstalled: "Installed"
        case .softwareReadyToInstall: "Ready"
        case .softwareNeedsReview: "Review"
        case .softwareFailing: "Failing"
        case .softwareNextActions: "Next Actions"
        case .noSoftwareActions: "No pending software actions"
        case .softwareNoCatalog: "Catalog recipes are not loaded yet"
        case .softwareSampleCatalog: "Real Software Samples"
        case .softwareSampleCatalogSummary: "%d samples · %d signed recipes · %d local installers · %d warnings"
        case .softwareSampleCatalogLocalInstallers: "Local Installers"
        case .softwareSampleCatalogSignedRecipes: "Signed Recipes"
        case .softwareSampleCatalogWarnings: "Warnings"
        case .noSoftwareSampleCatalog: "No real software samples yet"
        case .softwareCollection: "Test Software Collection"
        case .softwareCollectionSummary: "%d collections · %d recipes · %d cached · %d missing installers · %d verified"
        case .softwareCollectionCoverage: "Collection Coverage"
        case .softwareCollectionMissingRecipes: "Missing Recipes"
        case .softwareCollectionMissingInstallers: "Missing Installers"
        case .softwareCollectionActionRequired: "Action Required"
        case .softwareCollectionAcceptance: "Collection Acceptance"
        case .softwareCollectionAcceptanceSummary: "State %@ · %d actions · %d blockers · %d high priority"
        case .softwareCollectionAcceptanceState: "Acceptance State"
        case .softwareCollectionAcceptanceBlockers: "Blockers"
        case .softwareCollectionAcceptanceHighPriority: "High Priority"
        case .softwareCollectionAcceptanceWarnings: "Warnings"
        case .softwareCollectionAcceptanceActions: "Acceptance Actions"
        case .noSoftwareCollectionAcceptanceActions: "No collection acceptance actions"
        case .softwareCollectionDownloadMissing: "Download Missing Installers"
        case .exportSoftwareCollectionCSV: "Export Collection"
        case .exportSoftwareCollectionDownloadScript: "Export Download Script"
        case .exportSoftwareCollectionAcceptanceRunbook: "Export Runbook"
        case .exportSoftwareCollectionBundle: "Export Bundle"
        case .noSoftwareCollection: "No test software collection yet"
        case .softwareSmokeMatrix: "Software Smoke Matrix"
        case .softwareSmokeMatrixSummary: "%d recipes · %d blocked · %d warnings · %d failed · %d verified"
        case .smokeBlocked: "Blocked"
        case .smokeWarnings: "Warnings"
        case .smokeFailures: "Failures"
        case .smokeVerified: "Verified"
        case .smokeStage: "Stage"
        case .smokeChecklist: "Checklist"
        case .noSoftwareSmokeMatrix: "No software smoke matrix yet"
        case .blockers: "Blockers"
        case .latestLog: "Latest Log"
        case .runNextAction: "Run Next Action"
        case .exportCapabilityReport: "Export Capability Report"
        case .exportSupportBundle: "Export Support Bundle"
        case .engineAndCatalog: "Engine and catalog"
        case .engine: "Engine"
        case .name: "Name"
        case .version: "Version"
        case .architecture: "Architecture"
        case .probeArchitectureX86_64: "x86_64"
        case .probeArchitectureI686Wow64: "i686 / WoW64"
        case .runtimeProcessContext: "Bottle %@ · PPID %@"
        case .runtime: "Runtime"
        case .win32Compatibility: "32-bit compatibility"
        case .win32Supported: "Supports 32-bit apps (WoW64)"
        case .win32Unsupported: "Does not support 32-bit apps"
        case .requiresWin32: "Requires 32-bit"
        case .refreshEngine: "Refresh Engine"
        case .catalog: "Catalog"
        case .recipes: "Recipes"
        case .trust: "Trust"
        case .signedCuratedSource: "Signed curated source"
        case .refreshCatalog: "Refresh Catalog"
        case .data: "Data"
        case .root: "Root"
        case .openLogs: "Open Logs"
        case .language: "Language"
        case .ready: "Ready"
        case .importingEngine: "Importing engine"
        case .preparingDefaultBottle: "Preparing high performance bottle"
        case .preparingDesktop: "Preparing Wine desktop"
        case .creatingBottle: "Creating bottle"
        case .repairingBottle: "Repairing bottle %@"
        case .applyingCompatibilityProfile: "Applying compatibility preset"
        case .applyingGraphicsPreset: "Applying graphics preset"
        case .installing: "Installing %@"
        case .launching: "Launching %@"
        case .launchingWithDiagnostics: "Launching %@ with diagnostics"
        case .runningCommand: "Running command"
        case .keepSystemAwake: "Keep system awake"
        case .preventScreenLockHint: "Keeps display and system awake while the process starts."
        case .deleting: "Deleting %@"
        case .runningDiagnostics: "Running diagnostics"
        case .exportingCapabilityReport: "Exporting capability report"
        case .exportingSupportBundle: "Exporting support bundle"
        case .exportingInstallerDownloadScript: "Exporting download script"
        case .exportingInstallerAssetCSV: "Exporting installer list"
        case .exportingInstallerPreparationCSV: "Exporting installer preparation"
        case .exportingInstallerDownloadHistoryCSV: "Exporting download history"
        case .exportingSoftwareTestPlanCSV: "Exporting software test plan"
        case .exportingSoftwareCollectionCSV: "Exporting test software collection"
        case .exportingSoftwareCollectionDownloadScript: "Exporting collection download script"
        case .exportingSoftwareCollectionAcceptanceRunbook: "Exporting collection acceptance runbook"
        case .exportingSoftwareCollectionBundle: "Exporting test collection bundle"
        case .exportingTestExecutionPlanCSV: "Exporting recommended test plan"
        case .exportingTestRunHistoryCSV: "Exporting test run history"
        case .exportingTestSessionArchive: "Archiving test session"
        case .exportingLaunchHistoryCSV: "Exporting launch history"
        case .exportingDiagnosticHistoryCSV: "Exporting diagnostic history"
        case .downloadingInstaller: "Downloading %@"
        case .downloadingInstallerBatch: "Downloading %d installers"
        case .installerDownloaded: "Cached installer: %@"
        case .installerDownloadBatchFinished: "Cached %d installers"
        case .runningProbe: "Running probe %@"
        case .probeFinished: "Probe %@ finished"
        case .runningProbeBatch: "Running %d probes"
        case .probeBatchFinished: "Finished %d probes"
        case .rerunProbe: "Rerun Probe"
        case .runCoverageProbes: "Run Coverage Probes"
        case .diagnosticsPassed: "Diagnostics passed"
        case .diagnosticsFinishedWithFailures: "Diagnostics finished with failures"
        case .capabilityReportExported: "Exported capability report: %@"
        case .supportBundleExported: "Exported support bundle: %@"
        case .supportTriageRefreshed: "Refreshed support triage: %d items"
        case .runtimeProcessesRefreshed: "Refreshed runtime processes: %d"
        case .exportingRuntimeProcessesCSV: "Exporting runtime process table"
        case .exportingRuntimeSnapshot: "Exporting runtime process snapshot"
        case .runtimeProcessesCSVExported: "Exported runtime process table: %@"
        case .runtimeSnapshotExported: "Exported runtime snapshot: %@"
        case .terminatedRuntimeProcess: "Stopped %@, PID %@"
        case .installerDownloadScriptExported: "Exported download script: %@"
        case .installerAssetCSVExported: "Exported installer list: %@"
        case .installerPreparationCSVExported: "Exported installer preparation: %@"
        case .installerDownloadHistoryCSVExported: "Exported download history: %@"
        case .softwareSamplePreparationSnapshotExported: "Exported sample readiness snapshot: %@"
        case .softwareTestPlanCSVExported: "Exported software test plan: %@"
        case .softwareCollectionCSVExported: "Exported test software collection: %@"
        case .softwareCollectionDownloadScriptExported: "Exported collection download script: %@"
        case .softwareCollectionAcceptanceRunbookExported: "Exported collection acceptance runbook: %@"
        case .softwareCollectionBundleExported: "Exported test collection bundle: %@"
        case .testExecutionPlanCSVExported: "Exported recommended test plan: %@"
        case .testRunHistoryCSVExported: "Exported test run history: %@"
        case .testSessionArchiveExported: "Archived test session: %@"
        case .launchHistoryCSVExported: "Exported launch history: %@"
        case .diagnosticHistoryCSVExported: "Exported diagnostic history: %@"
        case .catalogExpired: "Catalog expired"
        case .catalogError: "Catalog error"
        case .noEngineRegistered: "No engine registered"
        case .noEngineForBottle: "No engine for bottle %@"
        case .windowsDesktopOnlyWin11: "Windows desktop mode only supports Windows 11 bottles"
        case .diagnosticLaunchTitle: "%@ (Diagnostics)"
        case .launchedPid: "Launched %@ pid %@"
        case .startedPid: "Started pid %@"
        case .alreadyRunningPid: "%@ is already running, pid %@; duplicate launch skipped"
        case .actionAlreadyInProgress: "%@ is already being handled; duplicate action skipped"
        case .created: "Created %@"
        case .repairedBottle: "Repaired %@"
        case .appliedCompatibilityProfile: "Applied compatibility preset to %@: %@"
        case .clearedCompatibilityProfile: "Disabled compatibility preset for %@"
        case .appliedGraphicsPreset: "Applied graphics preset: %@"
        case .installedIntoDefaultBottle: "Installed %@ into the high performance bottle"
        case .deleted: "Deleted %@"
        case .unableToLaunchProcess: "Unable to launch process: %@"
        case .wineRuntimeUnavailable: "Wine runtime is unavailable because Rosetta has uninterruptible Wine processes (PIDs: %@). Restart macOS or recover Rosetta before launching another Windows application."
        case .missingFile: "Missing file: %@"
        case .processFailed: "Process failed (%@): %@"
        case .unsupported: "Unsupported: %@"
        case .invalidManifest: "Invalid manifest: %@"
        case .signatureInvalid: "Catalog signature is invalid"
        case .hashMismatch: "Hash check failed: %@"
        case .installerRequired: "Installer required: %@"
        case .excellent: "Excellent"
        case .good: "Good"
        case .limited: "Limited"
        case .experimental: "Experimental"
        case .unknown: "Unknown"
        case .wineD3DVulkanPreset: "WineD3D Vulkan (Stable)"
        case .wineD3DVulkanPresetHelp: "Validated default game path for D3D9, D3D11, and baseline vkd3d compatibility."
        case .gptkD3DMetalPreset: "GPTK D3DMetal (DX12)"
        case .gptkD3DMetalPresetHelp: "Uses GPTK dxgi/d3d12 with D3DMetal.framework for Cyberpunk 2077-style DX12 games; D3D11 stays on stable Vulkan."
        case .gptkD3DMetalDXRPreset: "GPTK D3DMetal + DXR (Experimental)"
        case .gptkD3DMetalDXRPresetHelp: "Enables the D3DMetal DXR flag for ray tracing experiments; stability depends on game and hardware."
        case .bambuStudioSoftwareOpenGLProfile: "Bambu Studio Software OpenGL and Runtime Repair"
        case .blenderSoftwareOpenGLProfile: "Blender Software OpenGL 4.3 Viewport Repair"
        case .orcaSlicerNativeOpenGLProfile: "OrcaSlicer Native OpenGL and Startup Repair"
        case .browserGeckoProfile: "Gecko Browser Compatibility"
        case .hoYoPlayProfile: "HoYoPlay WebView Text Repair"
        case .lenovoAppStoreProfile: "Lenovo App Store Black Screen Repair"
        case .tencentAppStoreProfile: "Tencent App Store WebView Repair"
        case .steamClientProfile: "Steam Client"
        case .cefSoftwareRendererProfile: "WebView Text Repair"
        case .chromiumBrowserProfile: "Chromium Browser"
        case .curaSlicerProfile: "Cura Slicing and OpenGL Repair"
        case .kritaOpenGLProfile: "Krita Canvas and OpenGL Repair"
        case .geogebraLegacyElectron32Profile: "GeoGebra 32-bit Compatibility"
        case .gmshOpenGLProfile: "Gmsh OpenGL Viewport"
        case .freeCADOpenGLProfile: "FreeCAD Qt and OpenGL Viewport Repair"
        case .kiCadEDAProfile: "KiCad CJK UI and OpenGL Repair"
        case .libreCADQtProfile: "LibreCAD CJK UI and CAD Canvas Repair"
        case .jabRefJavaFXD3DProfile: "JabRef JavaFX D3D Text and Window Repair"
        case .dbeaverSWTProfile: "DBeaver Java/SWT Font and Window Repair"
        case .jaspQtWebEngineQrcProfile: "JASP QtWebEngine/qrc Repair"
        case .meshLabSoftwareOpenGLProfile: "MeshLab Software OpenGL Viewport"
        case .openPLCEditorProfile: "OpenPLC Electron Compositor and Timezone Repair"
        case .openSCADSoftwareOpenGLProfile: "OpenSCAD Software OpenGL Viewport Repair"
        case .sweetHome3DOpenGLProfile: "Sweet Home 3D 64-bit OpenGL Repair"
        case .mRemoteNG1782Profile: "mRemoteNG 1.78.2 .NET Repair"
        case .museScoreStudioProfile: "MuseScore Studio Input Repair"
        case .notepadPlusPlusGDIProfile: "Notepad++ GDI Stable Mode"
        case .portableAppsPlatformProfile: "PortableApps Platform Theme Repair"
        case .portableAppsUtilityProfile: "PortableApps Utility Compatibility"
        case .officeSuiteProfile: "Office Suite Compatibility"
        case .wpsOfficeProfile: "WPS Office CJK Document Mode"
        case .qtBrowserSoftwareProfile: "Qt Browser Software Rendering"
        case .qucsSQt6Profile: "Qucs-S Qt6 Engineering App"
        case .qtRhiSoftwareProfile: "Qt RHI Software Rendering"
        case .qtWidgetsSoftwareProfile: "Qt Widgets Software Rendering"
        case .softMakerOfficeProfile: "SoftMaker Office COM Repair"
        case .supermium32BrowserProfile: "Supermium 32-bit Browser"
        case .texStudioQt6Profile: "TeXstudio Qt6 Repair"
        case .sevenZipGDIProfile: "7-Zip GDI Stable Mode"
        case .zoteroGecko32Profile: "Zotero 32-bit Gecko Repair"
        }
    }
}
