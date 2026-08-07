import Foundation

public struct SupportBundleManifest: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var generatedAt: Date
    public var rootPath: String
    public var bundlePath: String
    public var fileManifestPath: String?
    public var fileManifestCSVPath: String?
    public var capabilityReportPath: String
    public var hostEnvironmentPath: String?
    public var hostEnvironmentCSVPath: String?
    public var bottleHealthReportPath: String
    public var recipeReadinessReportPath: String
    public var installerAssetReportPath: String
    public var installerAssetCSVPath: String
    public var installerPreparationReportPath: String
    public var installerPreparationCSVPath: String
    public var installerPreparationMarkdownPath: String?
    public var installerDownloadHistoryPath: String?
    public var installerDownloadHistoryCSVPath: String?
    public var installerDownloadScriptPath: String
    public var softwareTestPlanPath: String
    public var softwareTestPlanCSVPath: String
    public var softwareSmokeMatrixPath: String
    public var softwareSmokeMatrixCSVPath: String
    public var softwareSmokeRunsPath: String?
    public var softwareSmokeRunsCSVPath: String?
    public var softwareSmokeRunsMarkdownPath: String?
    public var softwareAdaptationRunbookPath: String
    public var softwareAdaptationQueuePath: String?
    public var softwareAdaptationQueueCSVPath: String?
    public var softwareAdaptationQueueMarkdownPath: String?
    public var softwareAdaptationQueueScriptPath: String?
    public var softwareSampleCatalogPath: String?
    public var softwareSampleCatalogCSVPath: String?
    public var softwareSampleCatalogRunbookPath: String?
    public var softwareSamplePreparationPath: String?
    public var softwareSamplePreparationCSVPath: String?
    public var softwareSamplePreparationMarkdownPath: String?
    public var softwareSamplePreparationScriptPath: String?
    public var softwareSampleLogCorrelationPath: String?
    public var softwareSampleLogCorrelationCSVPath: String?
    public var softwareSampleLogCorrelationMarkdownPath: String?
    public var softwareCollectionPath: String?
    public var softwareCollectionCSVPath: String?
    public var softwareCollectionLockfilePath: String?
    public var softwareCollectionLockfileCSVPath: String?
    public var softwareCollectionLockfileMarkdownPath: String?
    public var softwareCollectionDownloadScriptPath: String?
    public var softwareCollectionHistoryPath: String?
    public var softwareCollectionHistoryCSVPath: String?
    public var softwareCollectionAcceptancePath: String?
    public var softwareCollectionAcceptanceCSVPath: String?
    public var softwareCollectionAcceptanceMarkdownPath: String?
    public var softwareCollectionAcceptanceRunbookPath: String?
    public var softwareAcquisitionPath: String?
    public var softwareAcquisitionCSVPath: String?
    public var softwareAcquisitionMarkdownPath: String?
    public var softwareAcquisitionScriptPath: String?
    public var installHistoryPath: String?
    public var installHistoryCSVPath: String?
    public var testAssetReportPath: String
    public var testRunbookPath: String?
    public var testRunbookScriptPath: String?
    public var testRunHistoryPath: String?
    public var testRunHistoryCSVPath: String?
    public var testRunLogIndexPath: String
    public var testRunLogIndexCSVPath: String
    public var rawTestRunLogDirectoryPath: String
    public var redactedTestRunLogDirectoryPath: String
    public var testCoverageReportPath: String
    public var testCoverageCSVPath: String
    public var testExecutionPlanPath: String
    public var testExecutionPlanCSVPath: String
    public var testExecutionPlanScriptPath: String
    public var launchHistoryPath: String?
    public var launchHistoryCSVPath: String?
    public var launchReplayScriptPath: String
    public var launchHealthPath: String?
    public var launchHealthCSVPath: String?
    public var launchHealthMarkdownPath: String?
    public var compatibilityRepairAuditPath: String
    public var activityTimelinePath: String
    public var runtimeProcessReportPath: String
    public var runtimeProcessCSVPath: String
    public var runtimeApplicationReportPath: String?
    public var runtimeApplicationCSVPath: String?
    public var runtimeApplicationLogPath: String?
    public var externalOpenQueueReportPath: String?
    public var externalOpenQueueCSVPath: String?
    public var externalOpenQueueLogPath: String?
    public var supportTriagePath: String?
    public var supportTriageCSVPath: String?
    public var supportTriageMarkdownPath: String?
    public var logMaintenanceReportPath: String
    public var logMaintenanceScriptPath: String
    public var logIssueReportPath: String
    public var logIssueCSVPath: String
    public var logIssueMarkdownPath: String
    public var logRemediationPlanPath: String?
    public var logRemediationCSVPath: String?
    public var logRemediationMarkdownPath: String?
    public var logRemediationRunbookPath: String?
    public var recommendedProbeScriptPath: String
    public var logIndexPath: String
    public var logIndexCSVPath: String
    public var rawLogDirectoryPath: String
    public var redactedLogDirectoryPath: String
    public var includedLogCount: Int
    public var logIssueCount: Int
    public var logRemediationActionCount: Int?
    public var logRemediationProbeActionCount: Int?
    public var recommendedProbeCount: Int
    public var recentFailureLogCount: Int
    public var totalLogBytes: Int64
    public var staleLogCount: Int
    public var largeLogCount: Int
    public var cleanupCandidateLogCount: Int
    public var cleanupCandidateLogBytes: Int64
    public var healthyBottleCount: Int
    public var bottleHealthWarningCount: Int
    public var bottleHealthActionRequiredCount: Int
    public var bottleHealthFindingCount: Int
    public var staleLauncherCount: Int
    public var incompleteCompatibilityProfileCount: Int
    public var readyRecipeCount: Int
    public var actionRequiredRecipeCount: Int
    public var blockedRecipeCount: Int
    public var disabledRecipeCount: Int
    public var recipeReadinessIssueCount: Int
    public var installerAssetCount: Int
    public var installerPreparationActionCount: Int
    public var installerPreparationCriticalCount: Int
    public var installerPreparationWarningCount: Int
    public var installerDownloadRecordCount: Int
    public var installerDownloadFailedCount: Int
    public var installerHashMismatchCount: Int
    public var orphanedDownloadCount: Int
    public var softwareReadyToInstallCount: Int
    public var softwareInstalledCount: Int
    public var softwareVerifiedCount: Int
    public var softwareFailingCount: Int
    public var softwareReviewCount: Int
    public var softwareSmokeBlockedCount: Int
    public var softwareSmokeWarningCount: Int
    public var softwareSmokeFailedCount: Int
    public var softwareSmokeVerifiedCount: Int
    public var softwareSmokeRunReportCount: Int?
    public var softwareSmokeRunSupersededSkipCount: Int?
    public var softwareSmokeRunUncoveredSkippedCount: Int?
    public var softwareAdaptationTaskCount: Int?
    public var softwareAdaptationRunnableProbeCount: Int?
    public var softwareAdaptationUnavailableProbeCount: Int?
    public var softwareSampleCatalogCount: Int?
    public var softwareSampleCatalogLocalInstallerCount: Int?
    public var softwareSampleCatalogSignedRecipeCount: Int?
    public var softwareSampleCatalogWarningCount: Int?
    public var softwareSamplePreparationReadyCount: Int?
    public var softwareSamplePreparationMissingInstallerCount: Int?
    public var softwareSamplePreparationMissingRecipeCount: Int?
    public var softwareSamplePreparationManualCount: Int?
    public var softwareSampleMatchedCount: Int?
    public var softwareSampleFailedCount: Int?
    public var softwareSampleAttentionCount: Int?
    public var softwareCollectionRecipeCount: Int?
    public var softwareCollectionMissingRecipeCount: Int?
    public var softwareCollectionMissingInstallerCount: Int?
    public var softwareCollectionActionRequiredCount: Int?
    public var softwareCollectionHashProtectedCount: Int?
    public var softwareCollectionHashMismatchCount: Int?
    public var softwareCollectionUnprotectedDownloadCount: Int?
    public var softwareCollectionHistoryRecordCount: Int?
    public var softwareCollectionHistoryFailedCount: Int?
    public var softwareCollectionAcceptanceState: String?
    public var softwareCollectionAcceptanceActionCount: Int?
    public var softwareCollectionAcceptanceBlockerCount: Int?
    public var softwareCollectionAcceptanceHighPriorityCount: Int?
    public var softwareAcquisitionActionCount: Int?
    public var softwareAcquisitionDownloadableCount: Int?
    public var softwareAcquisitionMissingLocalInstallerCount: Int?
    public var softwareAcquisitionMissingRecipeCount: Int?
    public var softwareAcquisitionHashMismatchCount: Int?
    public var installTaskCount: Int
    public var failedInstallTaskCount: Int
    public var verifiedTestCategoryCount: Int
    public var missingRequiredTestAssetCount: Int
    public var failedTestAssetCount: Int
    public var timedOutTestAssetCount: Int
    public var unverifiedTestAssetCount: Int
    public var includedTestRunLogCount: Int
    public var testExecutionPlanItemCount: Int
    public var testExecutionPlanRequiredCount: Int
    public var testExecutionPlanHighPriorityCount: Int
    public var activityTimelineEventCount: Int
    public var activityTimelineErrorCount: Int
    public var activityTimelineWarningCount: Int
    public var engineCount: Int
    public var bottleCount: Int
    public var recipeCount: Int
    public var diagnosticLogPath: String?
    public var diagnosticsCSVPath: String?
    public var diagnosticHistoryPath: String
    public var diagnosticHistoryCSVPath: String
    public var diagnosticArtifactIndexPath: String?
    public var diagnosticArtifactIndexCSVPath: String?
    public var diagnosticArtifactIndexMarkdownPath: String?
    public var diagnosticArtifactCount: Int?
    public var diagnosticArtifactBytes: Int64?
    public var diagnosticRunCount: Int
    public var failedDiagnosticRunCount: Int
    public var timedOutDiagnosticRunCount: Int
    public var launchHistoryCount: Int
    public var launchHealthEntryCount: Int?
    public var failedLaunchHealthEntryCount: Int?
    public var attentionLaunchHealthEntryCount: Int?
    public var logMatchedLaunchHealthCount: Int?
    public var visualAcceptanceResultPath: String?
    public var visualAcceptanceArtifactPaths: [String]?
    public var compatibilityRepairAuditedLaunchCount: Int
    public var compatibilityRepairMissingLaunchCount: Int
    public var compatibilityRepairStaleFlagLaunchCount: Int
    public var compatibilityRepairFindingCount: Int
    public var runtimeProcessCount: Int
    public var runtimeProcessFindingCount: Int
    public var runtimeApplicationCount: Int?
    public var runtimeApplicationFindingCount: Int?
    public var runtimeMacWinApplicationCount: Int?
    public var runtimeWineApplicationCount: Int?
    public var externalOpenQueuePendingCount: Int?
    public var externalOpenQueueDuplicateCount: Int?
    public var externalOpenQueueInvalidLineCount: Int?
    public var supportTriageStatus: String?
    public var supportTriageItemCount: Int?
    public var supportTriageBlockerCount: Int?
    public var supportTriageHighCount: Int?
    public var supportTriageWarningCount: Int?

    public init(
        schemaVersion: Int = 1,
        generatedAt: Date,
        rootPath: String,
        bundlePath: String,
        fileManifestPath: String? = nil,
        fileManifestCSVPath: String? = nil,
        capabilityReportPath: String,
        hostEnvironmentPath: String? = nil,
        hostEnvironmentCSVPath: String? = nil,
        bottleHealthReportPath: String,
        recipeReadinessReportPath: String,
        installerAssetReportPath: String,
        installerAssetCSVPath: String,
        installerPreparationReportPath: String,
        installerPreparationCSVPath: String,
        installerPreparationMarkdownPath: String? = nil,
        installerDownloadHistoryPath: String? = nil,
        installerDownloadHistoryCSVPath: String? = nil,
        installerDownloadScriptPath: String,
        softwareTestPlanPath: String,
        softwareTestPlanCSVPath: String,
        softwareSmokeMatrixPath: String,
        softwareSmokeMatrixCSVPath: String,
        softwareSmokeRunsPath: String? = nil,
        softwareSmokeRunsCSVPath: String? = nil,
        softwareSmokeRunsMarkdownPath: String? = nil,
        softwareAdaptationRunbookPath: String,
        softwareAdaptationQueuePath: String? = nil,
        softwareAdaptationQueueCSVPath: String? = nil,
        softwareAdaptationQueueMarkdownPath: String? = nil,
        softwareAdaptationQueueScriptPath: String? = nil,
        softwareSampleCatalogPath: String? = nil,
        softwareSampleCatalogCSVPath: String? = nil,
        softwareSampleCatalogRunbookPath: String? = nil,
        softwareSamplePreparationPath: String? = nil,
        softwareSamplePreparationCSVPath: String? = nil,
        softwareSamplePreparationMarkdownPath: String? = nil,
        softwareSamplePreparationScriptPath: String? = nil,
        softwareSampleLogCorrelationPath: String? = nil,
        softwareSampleLogCorrelationCSVPath: String? = nil,
        softwareSampleLogCorrelationMarkdownPath: String? = nil,
        softwareCollectionPath: String? = nil,
        softwareCollectionCSVPath: String? = nil,
        softwareCollectionLockfilePath: String? = nil,
        softwareCollectionLockfileCSVPath: String? = nil,
        softwareCollectionLockfileMarkdownPath: String? = nil,
        softwareCollectionDownloadScriptPath: String? = nil,
        softwareCollectionHistoryPath: String? = nil,
        softwareCollectionHistoryCSVPath: String? = nil,
        softwareCollectionAcceptancePath: String? = nil,
        softwareCollectionAcceptanceCSVPath: String? = nil,
        softwareCollectionAcceptanceMarkdownPath: String? = nil,
        softwareCollectionAcceptanceRunbookPath: String? = nil,
        softwareAcquisitionPath: String? = nil,
        softwareAcquisitionCSVPath: String? = nil,
        softwareAcquisitionMarkdownPath: String? = nil,
        softwareAcquisitionScriptPath: String? = nil,
        installHistoryPath: String? = nil,
        installHistoryCSVPath: String? = nil,
        testAssetReportPath: String,
        testRunbookPath: String? = nil,
        testRunbookScriptPath: String? = nil,
        testRunHistoryPath: String? = nil,
        testRunHistoryCSVPath: String? = nil,
        testRunLogIndexPath: String,
        testRunLogIndexCSVPath: String,
        rawTestRunLogDirectoryPath: String,
        redactedTestRunLogDirectoryPath: String,
        testCoverageReportPath: String,
        testCoverageCSVPath: String,
        testExecutionPlanPath: String,
        testExecutionPlanCSVPath: String,
        testExecutionPlanScriptPath: String,
        launchHistoryPath: String? = nil,
        launchHistoryCSVPath: String? = nil,
        launchReplayScriptPath: String,
        launchHealthPath: String? = nil,
        launchHealthCSVPath: String? = nil,
        launchHealthMarkdownPath: String? = nil,
        compatibilityRepairAuditPath: String,
        activityTimelinePath: String,
        runtimeProcessReportPath: String,
        runtimeProcessCSVPath: String,
        runtimeApplicationReportPath: String? = nil,
        runtimeApplicationCSVPath: String? = nil,
        runtimeApplicationLogPath: String? = nil,
        externalOpenQueueReportPath: String? = nil,
        externalOpenQueueCSVPath: String? = nil,
        externalOpenQueueLogPath: String? = nil,
        supportTriagePath: String? = nil,
        supportTriageCSVPath: String? = nil,
        supportTriageMarkdownPath: String? = nil,
        logMaintenanceReportPath: String,
        logMaintenanceScriptPath: String,
        logIssueReportPath: String,
        logIssueCSVPath: String,
        logIssueMarkdownPath: String,
        logRemediationPlanPath: String? = nil,
        logRemediationCSVPath: String? = nil,
        logRemediationMarkdownPath: String? = nil,
        logRemediationRunbookPath: String? = nil,
        recommendedProbeScriptPath: String,
        logIndexPath: String,
        logIndexCSVPath: String,
        rawLogDirectoryPath: String,
        redactedLogDirectoryPath: String,
        includedLogCount: Int,
        logIssueCount: Int,
        logRemediationActionCount: Int? = nil,
        logRemediationProbeActionCount: Int? = nil,
        recommendedProbeCount: Int,
        recentFailureLogCount: Int,
        totalLogBytes: Int64,
        staleLogCount: Int,
        largeLogCount: Int,
        cleanupCandidateLogCount: Int,
        cleanupCandidateLogBytes: Int64,
        healthyBottleCount: Int,
        bottleHealthWarningCount: Int,
        bottleHealthActionRequiredCount: Int,
        bottleHealthFindingCount: Int,
        staleLauncherCount: Int,
        incompleteCompatibilityProfileCount: Int,
        readyRecipeCount: Int,
        actionRequiredRecipeCount: Int,
        blockedRecipeCount: Int,
        disabledRecipeCount: Int,
        recipeReadinessIssueCount: Int,
        installerAssetCount: Int,
        installerPreparationActionCount: Int,
        installerPreparationCriticalCount: Int,
        installerPreparationWarningCount: Int,
        installerDownloadRecordCount: Int,
        installerDownloadFailedCount: Int,
        installerHashMismatchCount: Int,
        orphanedDownloadCount: Int,
        softwareReadyToInstallCount: Int,
        softwareInstalledCount: Int,
        softwareVerifiedCount: Int,
        softwareFailingCount: Int,
        softwareReviewCount: Int,
        softwareSmokeBlockedCount: Int,
        softwareSmokeWarningCount: Int,
        softwareSmokeFailedCount: Int,
        softwareSmokeVerifiedCount: Int,
        softwareSmokeRunReportCount: Int? = nil,
        softwareSmokeRunSupersededSkipCount: Int? = nil,
        softwareSmokeRunUncoveredSkippedCount: Int? = nil,
        softwareAdaptationTaskCount: Int? = nil,
        softwareAdaptationRunnableProbeCount: Int? = nil,
        softwareAdaptationUnavailableProbeCount: Int? = nil,
        softwareSampleCatalogCount: Int? = nil,
        softwareSampleCatalogLocalInstallerCount: Int? = nil,
        softwareSampleCatalogSignedRecipeCount: Int? = nil,
        softwareSampleCatalogWarningCount: Int? = nil,
        softwareSamplePreparationReadyCount: Int? = nil,
        softwareSamplePreparationMissingInstallerCount: Int? = nil,
        softwareSamplePreparationMissingRecipeCount: Int? = nil,
        softwareSamplePreparationManualCount: Int? = nil,
        softwareSampleMatchedCount: Int? = nil,
        softwareSampleFailedCount: Int? = nil,
        softwareSampleAttentionCount: Int? = nil,
        softwareCollectionRecipeCount: Int? = nil,
        softwareCollectionMissingRecipeCount: Int? = nil,
        softwareCollectionMissingInstallerCount: Int? = nil,
        softwareCollectionActionRequiredCount: Int? = nil,
        softwareCollectionHashProtectedCount: Int? = nil,
        softwareCollectionHashMismatchCount: Int? = nil,
        softwareCollectionUnprotectedDownloadCount: Int? = nil,
        softwareCollectionHistoryRecordCount: Int? = nil,
        softwareCollectionHistoryFailedCount: Int? = nil,
        softwareCollectionAcceptanceState: String? = nil,
        softwareCollectionAcceptanceActionCount: Int? = nil,
        softwareCollectionAcceptanceBlockerCount: Int? = nil,
        softwareCollectionAcceptanceHighPriorityCount: Int? = nil,
        softwareAcquisitionActionCount: Int? = nil,
        softwareAcquisitionDownloadableCount: Int? = nil,
        softwareAcquisitionMissingLocalInstallerCount: Int? = nil,
        softwareAcquisitionMissingRecipeCount: Int? = nil,
        softwareAcquisitionHashMismatchCount: Int? = nil,
        installTaskCount: Int,
        failedInstallTaskCount: Int,
        verifiedTestCategoryCount: Int,
        missingRequiredTestAssetCount: Int,
        failedTestAssetCount: Int,
        timedOutTestAssetCount: Int,
        unverifiedTestAssetCount: Int,
        includedTestRunLogCount: Int,
        testExecutionPlanItemCount: Int,
        testExecutionPlanRequiredCount: Int,
        testExecutionPlanHighPriorityCount: Int,
        activityTimelineEventCount: Int,
        activityTimelineErrorCount: Int,
        activityTimelineWarningCount: Int,
        engineCount: Int,
        bottleCount: Int,
        recipeCount: Int,
        diagnosticLogPath: String?,
        diagnosticsCSVPath: String? = nil,
        diagnosticHistoryPath: String,
        diagnosticHistoryCSVPath: String,
        diagnosticArtifactIndexPath: String? = nil,
        diagnosticArtifactIndexCSVPath: String? = nil,
        diagnosticArtifactIndexMarkdownPath: String? = nil,
        diagnosticArtifactCount: Int? = nil,
        diagnosticArtifactBytes: Int64? = nil,
        diagnosticRunCount: Int,
        failedDiagnosticRunCount: Int,
        timedOutDiagnosticRunCount: Int,
        launchHistoryCount: Int,
        launchHealthEntryCount: Int? = nil,
        failedLaunchHealthEntryCount: Int? = nil,
        attentionLaunchHealthEntryCount: Int? = nil,
        logMatchedLaunchHealthCount: Int? = nil,
        visualAcceptanceResultPath: String? = nil,
        visualAcceptanceArtifactPaths: [String]? = nil,
        compatibilityRepairAuditedLaunchCount: Int,
        compatibilityRepairMissingLaunchCount: Int,
        compatibilityRepairStaleFlagLaunchCount: Int,
        compatibilityRepairFindingCount: Int,
        runtimeProcessCount: Int,
        runtimeProcessFindingCount: Int,
        runtimeApplicationCount: Int? = nil,
        runtimeApplicationFindingCount: Int? = nil,
        runtimeMacWinApplicationCount: Int? = nil,
        runtimeWineApplicationCount: Int? = nil,
        externalOpenQueuePendingCount: Int? = nil,
        externalOpenQueueDuplicateCount: Int? = nil,
        externalOpenQueueInvalidLineCount: Int? = nil,
        supportTriageStatus: String? = nil,
        supportTriageItemCount: Int? = nil,
        supportTriageBlockerCount: Int? = nil,
        supportTriageHighCount: Int? = nil,
        supportTriageWarningCount: Int? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.generatedAt = generatedAt
        self.rootPath = rootPath
        self.bundlePath = bundlePath
        self.fileManifestPath = fileManifestPath
        self.fileManifestCSVPath = fileManifestCSVPath
        self.capabilityReportPath = capabilityReportPath
        self.hostEnvironmentPath = hostEnvironmentPath
        self.hostEnvironmentCSVPath = hostEnvironmentCSVPath
        self.bottleHealthReportPath = bottleHealthReportPath
        self.recipeReadinessReportPath = recipeReadinessReportPath
        self.installerAssetReportPath = installerAssetReportPath
        self.installerAssetCSVPath = installerAssetCSVPath
        self.installerPreparationReportPath = installerPreparationReportPath
        self.installerPreparationCSVPath = installerPreparationCSVPath
        self.installerPreparationMarkdownPath = installerPreparationMarkdownPath
        self.installerDownloadHistoryPath = installerDownloadHistoryPath
        self.installerDownloadHistoryCSVPath = installerDownloadHistoryCSVPath
        self.installerDownloadScriptPath = installerDownloadScriptPath
        self.softwareTestPlanPath = softwareTestPlanPath
        self.softwareTestPlanCSVPath = softwareTestPlanCSVPath
        self.softwareSmokeMatrixPath = softwareSmokeMatrixPath
        self.softwareSmokeMatrixCSVPath = softwareSmokeMatrixCSVPath
        self.softwareSmokeRunsPath = softwareSmokeRunsPath
        self.softwareSmokeRunsCSVPath = softwareSmokeRunsCSVPath
        self.softwareSmokeRunsMarkdownPath = softwareSmokeRunsMarkdownPath
        self.softwareAdaptationRunbookPath = softwareAdaptationRunbookPath
        self.softwareAdaptationQueuePath = softwareAdaptationQueuePath
        self.softwareAdaptationQueueCSVPath = softwareAdaptationQueueCSVPath
        self.softwareAdaptationQueueMarkdownPath = softwareAdaptationQueueMarkdownPath
        self.softwareAdaptationQueueScriptPath = softwareAdaptationQueueScriptPath
        self.softwareSampleCatalogPath = softwareSampleCatalogPath
        self.softwareSampleCatalogCSVPath = softwareSampleCatalogCSVPath
        self.softwareSampleCatalogRunbookPath = softwareSampleCatalogRunbookPath
        self.softwareSamplePreparationPath = softwareSamplePreparationPath
        self.softwareSamplePreparationCSVPath = softwareSamplePreparationCSVPath
        self.softwareSamplePreparationMarkdownPath = softwareSamplePreparationMarkdownPath
        self.softwareSamplePreparationScriptPath = softwareSamplePreparationScriptPath
        self.softwareSampleLogCorrelationPath = softwareSampleLogCorrelationPath
        self.softwareSampleLogCorrelationCSVPath = softwareSampleLogCorrelationCSVPath
        self.softwareSampleLogCorrelationMarkdownPath = softwareSampleLogCorrelationMarkdownPath
        self.softwareCollectionPath = softwareCollectionPath
        self.softwareCollectionCSVPath = softwareCollectionCSVPath
        self.softwareCollectionLockfilePath = softwareCollectionLockfilePath
        self.softwareCollectionLockfileCSVPath = softwareCollectionLockfileCSVPath
        self.softwareCollectionLockfileMarkdownPath = softwareCollectionLockfileMarkdownPath
        self.softwareCollectionDownloadScriptPath = softwareCollectionDownloadScriptPath
        self.softwareCollectionHistoryPath = softwareCollectionHistoryPath
        self.softwareCollectionHistoryCSVPath = softwareCollectionHistoryCSVPath
        self.softwareCollectionAcceptancePath = softwareCollectionAcceptancePath
        self.softwareCollectionAcceptanceCSVPath = softwareCollectionAcceptanceCSVPath
        self.softwareCollectionAcceptanceMarkdownPath = softwareCollectionAcceptanceMarkdownPath
        self.softwareCollectionAcceptanceRunbookPath = softwareCollectionAcceptanceRunbookPath
        self.softwareAcquisitionPath = softwareAcquisitionPath
        self.softwareAcquisitionCSVPath = softwareAcquisitionCSVPath
        self.softwareAcquisitionMarkdownPath = softwareAcquisitionMarkdownPath
        self.softwareAcquisitionScriptPath = softwareAcquisitionScriptPath
        self.installHistoryPath = installHistoryPath
        self.installHistoryCSVPath = installHistoryCSVPath
        self.testAssetReportPath = testAssetReportPath
        self.testRunbookPath = testRunbookPath
        self.testRunbookScriptPath = testRunbookScriptPath
        self.testRunHistoryPath = testRunHistoryPath
        self.testRunHistoryCSVPath = testRunHistoryCSVPath
        self.testRunLogIndexPath = testRunLogIndexPath
        self.testRunLogIndexCSVPath = testRunLogIndexCSVPath
        self.rawTestRunLogDirectoryPath = rawTestRunLogDirectoryPath
        self.redactedTestRunLogDirectoryPath = redactedTestRunLogDirectoryPath
        self.testCoverageReportPath = testCoverageReportPath
        self.testCoverageCSVPath = testCoverageCSVPath
        self.testExecutionPlanPath = testExecutionPlanPath
        self.testExecutionPlanCSVPath = testExecutionPlanCSVPath
        self.testExecutionPlanScriptPath = testExecutionPlanScriptPath
        self.launchHistoryPath = launchHistoryPath
        self.launchHistoryCSVPath = launchHistoryCSVPath
        self.launchReplayScriptPath = launchReplayScriptPath
        self.launchHealthPath = launchHealthPath
        self.launchHealthCSVPath = launchHealthCSVPath
        self.launchHealthMarkdownPath = launchHealthMarkdownPath
        self.compatibilityRepairAuditPath = compatibilityRepairAuditPath
        self.activityTimelinePath = activityTimelinePath
        self.runtimeProcessReportPath = runtimeProcessReportPath
        self.runtimeProcessCSVPath = runtimeProcessCSVPath
        self.runtimeApplicationReportPath = runtimeApplicationReportPath
        self.runtimeApplicationCSVPath = runtimeApplicationCSVPath
        self.runtimeApplicationLogPath = runtimeApplicationLogPath
        self.externalOpenQueueReportPath = externalOpenQueueReportPath
        self.externalOpenQueueCSVPath = externalOpenQueueCSVPath
        self.externalOpenQueueLogPath = externalOpenQueueLogPath
        self.supportTriagePath = supportTriagePath
        self.supportTriageCSVPath = supportTriageCSVPath
        self.supportTriageMarkdownPath = supportTriageMarkdownPath
        self.logMaintenanceReportPath = logMaintenanceReportPath
        self.logMaintenanceScriptPath = logMaintenanceScriptPath
        self.logIssueReportPath = logIssueReportPath
        self.logIssueCSVPath = logIssueCSVPath
        self.logIssueMarkdownPath = logIssueMarkdownPath
        self.logRemediationPlanPath = logRemediationPlanPath
        self.logRemediationCSVPath = logRemediationCSVPath
        self.logRemediationMarkdownPath = logRemediationMarkdownPath
        self.logRemediationRunbookPath = logRemediationRunbookPath
        self.recommendedProbeScriptPath = recommendedProbeScriptPath
        self.logIndexPath = logIndexPath
        self.logIndexCSVPath = logIndexCSVPath
        self.rawLogDirectoryPath = rawLogDirectoryPath
        self.redactedLogDirectoryPath = redactedLogDirectoryPath
        self.includedLogCount = includedLogCount
        self.logIssueCount = logIssueCount
        self.logRemediationActionCount = logRemediationActionCount
        self.logRemediationProbeActionCount = logRemediationProbeActionCount
        self.recommendedProbeCount = recommendedProbeCount
        self.recentFailureLogCount = recentFailureLogCount
        self.totalLogBytes = totalLogBytes
        self.staleLogCount = staleLogCount
        self.largeLogCount = largeLogCount
        self.cleanupCandidateLogCount = cleanupCandidateLogCount
        self.cleanupCandidateLogBytes = cleanupCandidateLogBytes
        self.healthyBottleCount = healthyBottleCount
        self.bottleHealthWarningCount = bottleHealthWarningCount
        self.bottleHealthActionRequiredCount = bottleHealthActionRequiredCount
        self.bottleHealthFindingCount = bottleHealthFindingCount
        self.staleLauncherCount = staleLauncherCount
        self.incompleteCompatibilityProfileCount = incompleteCompatibilityProfileCount
        self.readyRecipeCount = readyRecipeCount
        self.actionRequiredRecipeCount = actionRequiredRecipeCount
        self.blockedRecipeCount = blockedRecipeCount
        self.disabledRecipeCount = disabledRecipeCount
        self.recipeReadinessIssueCount = recipeReadinessIssueCount
        self.installerAssetCount = installerAssetCount
        self.installerPreparationActionCount = installerPreparationActionCount
        self.installerPreparationCriticalCount = installerPreparationCriticalCount
        self.installerPreparationWarningCount = installerPreparationWarningCount
        self.installerDownloadRecordCount = installerDownloadRecordCount
        self.installerDownloadFailedCount = installerDownloadFailedCount
        self.installerHashMismatchCount = installerHashMismatchCount
        self.orphanedDownloadCount = orphanedDownloadCount
        self.softwareReadyToInstallCount = softwareReadyToInstallCount
        self.softwareInstalledCount = softwareInstalledCount
        self.softwareVerifiedCount = softwareVerifiedCount
        self.softwareFailingCount = softwareFailingCount
        self.softwareReviewCount = softwareReviewCount
        self.softwareSmokeBlockedCount = softwareSmokeBlockedCount
        self.softwareSmokeWarningCount = softwareSmokeWarningCount
        self.softwareSmokeFailedCount = softwareSmokeFailedCount
        self.softwareSmokeVerifiedCount = softwareSmokeVerifiedCount
        self.softwareSmokeRunReportCount = softwareSmokeRunReportCount
        self.softwareSmokeRunSupersededSkipCount = softwareSmokeRunSupersededSkipCount
        self.softwareSmokeRunUncoveredSkippedCount = softwareSmokeRunUncoveredSkippedCount
        self.softwareAdaptationTaskCount = softwareAdaptationTaskCount
        self.softwareAdaptationRunnableProbeCount = softwareAdaptationRunnableProbeCount
        self.softwareAdaptationUnavailableProbeCount = softwareAdaptationUnavailableProbeCount
        self.softwareSampleCatalogCount = softwareSampleCatalogCount
        self.softwareSampleCatalogLocalInstallerCount = softwareSampleCatalogLocalInstallerCount
        self.softwareSampleCatalogSignedRecipeCount = softwareSampleCatalogSignedRecipeCount
        self.softwareSampleCatalogWarningCount = softwareSampleCatalogWarningCount
        self.softwareSamplePreparationReadyCount = softwareSamplePreparationReadyCount
        self.softwareSamplePreparationMissingInstallerCount = softwareSamplePreparationMissingInstallerCount
        self.softwareSamplePreparationMissingRecipeCount = softwareSamplePreparationMissingRecipeCount
        self.softwareSamplePreparationManualCount = softwareSamplePreparationManualCount
        self.softwareSampleMatchedCount = softwareSampleMatchedCount
        self.softwareSampleFailedCount = softwareSampleFailedCount
        self.softwareSampleAttentionCount = softwareSampleAttentionCount
        self.softwareCollectionRecipeCount = softwareCollectionRecipeCount
        self.softwareCollectionMissingRecipeCount = softwareCollectionMissingRecipeCount
        self.softwareCollectionMissingInstallerCount = softwareCollectionMissingInstallerCount
        self.softwareCollectionActionRequiredCount = softwareCollectionActionRequiredCount
        self.softwareCollectionHashProtectedCount = softwareCollectionHashProtectedCount
        self.softwareCollectionHashMismatchCount = softwareCollectionHashMismatchCount
        self.softwareCollectionUnprotectedDownloadCount = softwareCollectionUnprotectedDownloadCount
        self.softwareCollectionHistoryRecordCount = softwareCollectionHistoryRecordCount
        self.softwareCollectionHistoryFailedCount = softwareCollectionHistoryFailedCount
        self.softwareCollectionAcceptanceState = softwareCollectionAcceptanceState
        self.softwareCollectionAcceptanceActionCount = softwareCollectionAcceptanceActionCount
        self.softwareCollectionAcceptanceBlockerCount = softwareCollectionAcceptanceBlockerCount
        self.softwareCollectionAcceptanceHighPriorityCount = softwareCollectionAcceptanceHighPriorityCount
        self.softwareAcquisitionActionCount = softwareAcquisitionActionCount
        self.softwareAcquisitionDownloadableCount = softwareAcquisitionDownloadableCount
        self.softwareAcquisitionMissingLocalInstallerCount = softwareAcquisitionMissingLocalInstallerCount
        self.softwareAcquisitionMissingRecipeCount = softwareAcquisitionMissingRecipeCount
        self.softwareAcquisitionHashMismatchCount = softwareAcquisitionHashMismatchCount
        self.installTaskCount = installTaskCount
        self.failedInstallTaskCount = failedInstallTaskCount
        self.verifiedTestCategoryCount = verifiedTestCategoryCount
        self.missingRequiredTestAssetCount = missingRequiredTestAssetCount
        self.failedTestAssetCount = failedTestAssetCount
        self.timedOutTestAssetCount = timedOutTestAssetCount
        self.unverifiedTestAssetCount = unverifiedTestAssetCount
        self.includedTestRunLogCount = includedTestRunLogCount
        self.testExecutionPlanItemCount = testExecutionPlanItemCount
        self.testExecutionPlanRequiredCount = testExecutionPlanRequiredCount
        self.testExecutionPlanHighPriorityCount = testExecutionPlanHighPriorityCount
        self.activityTimelineEventCount = activityTimelineEventCount
        self.activityTimelineErrorCount = activityTimelineErrorCount
        self.activityTimelineWarningCount = activityTimelineWarningCount
        self.engineCount = engineCount
        self.bottleCount = bottleCount
        self.recipeCount = recipeCount
        self.diagnosticLogPath = diagnosticLogPath
        self.diagnosticsCSVPath = diagnosticsCSVPath
        self.diagnosticHistoryPath = diagnosticHistoryPath
        self.diagnosticHistoryCSVPath = diagnosticHistoryCSVPath
        self.diagnosticArtifactIndexPath = diagnosticArtifactIndexPath
        self.diagnosticArtifactIndexCSVPath = diagnosticArtifactIndexCSVPath
        self.diagnosticArtifactIndexMarkdownPath = diagnosticArtifactIndexMarkdownPath
        self.diagnosticArtifactCount = diagnosticArtifactCount
        self.diagnosticArtifactBytes = diagnosticArtifactBytes
        self.diagnosticRunCount = diagnosticRunCount
        self.failedDiagnosticRunCount = failedDiagnosticRunCount
        self.timedOutDiagnosticRunCount = timedOutDiagnosticRunCount
        self.launchHistoryCount = launchHistoryCount
        self.launchHealthEntryCount = launchHealthEntryCount
        self.failedLaunchHealthEntryCount = failedLaunchHealthEntryCount
        self.attentionLaunchHealthEntryCount = attentionLaunchHealthEntryCount
        self.logMatchedLaunchHealthCount = logMatchedLaunchHealthCount
        self.visualAcceptanceResultPath = visualAcceptanceResultPath
        self.visualAcceptanceArtifactPaths = visualAcceptanceArtifactPaths
        self.compatibilityRepairAuditedLaunchCount = compatibilityRepairAuditedLaunchCount
        self.compatibilityRepairMissingLaunchCount = compatibilityRepairMissingLaunchCount
        self.compatibilityRepairStaleFlagLaunchCount = compatibilityRepairStaleFlagLaunchCount
        self.compatibilityRepairFindingCount = compatibilityRepairFindingCount
        self.runtimeProcessCount = runtimeProcessCount
        self.runtimeProcessFindingCount = runtimeProcessFindingCount
        self.runtimeApplicationCount = runtimeApplicationCount
        self.runtimeApplicationFindingCount = runtimeApplicationFindingCount
        self.runtimeMacWinApplicationCount = runtimeMacWinApplicationCount
        self.runtimeWineApplicationCount = runtimeWineApplicationCount
        self.externalOpenQueuePendingCount = externalOpenQueuePendingCount
        self.externalOpenQueueDuplicateCount = externalOpenQueueDuplicateCount
        self.externalOpenQueueInvalidLineCount = externalOpenQueueInvalidLineCount
        self.supportTriageStatus = supportTriageStatus
        self.supportTriageItemCount = supportTriageItemCount
        self.supportTriageBlockerCount = supportTriageBlockerCount
        self.supportTriageHighCount = supportTriageHighCount
        self.supportTriageWarningCount = supportTriageWarningCount
    }
}

public struct SupportBundleLogEntry: Codable, Equatable, Sendable {
    public var name: String
    public var sourcePath: String
    public var rawPath: String
    public var redactedPath: String
    public var rawSha256: String
    public var redactedSha256: String
    public var modifiedAt: Date
    public var byteCount: Int64
    public var health: String
    public var hints: [String]
    public var redactionCount: Int
    public var launchRecordId: String?
    public var bottleId: String?
    public var bottleName: String?
    public var engineId: String?
    public var exe: String?
    public var args: [String]
    public var exitCode: Int32?
}

public struct SupportBundleFileManifest: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var bundlePath: String
    public var fileCount: Int
    public var totalByteCount: Int64
    public var files: [SupportBundleFileEntry]

    public init(generatedAt: Date, bundlePath: String, files: [SupportBundleFileEntry]) {
        self.generatedAt = generatedAt
        self.bundlePath = bundlePath
        self.fileCount = files.count
        self.totalByteCount = files.map(\.byteCount).reduce(0, +)
        self.files = files
    }
}

public struct SupportBundleFileEntry: Codable, Equatable, Sendable {
    public var relativePath: String
    public var byteCount: Int64
    public var modifiedAt: Date
    public var sha256: String
}

public struct SupportBundleTestRunLogEntry: Codable, Equatable, Sendable {
    public var name: String
    public var assetId: String?
    public var outcome: TestRunOutcome
    public var sourcePath: String
    public var rawPath: String
    public var redactedPath: String
    public var rawSha256: String
    public var redactedSha256: String
    public var modifiedAt: Date
    public var byteCount: Int64
    public var redactionCount: Int
    public var passSignalCount: Int
    public var failSignalCount: Int
    public var exitCode: Int32?
}

public struct SupportBundleService {
    public var paths: MacWinPaths
    public var fileManager: FileManager
    public var capabilityReportService: CapabilityReportService
    public var logService: LogService
    public var diagnosticsHistoryService: DiagnosticsHistoryService

    public init(
        paths: MacWinPaths = MacWinPaths(),
        fileManager: FileManager = .default,
        capabilityReportService: CapabilityReportService? = nil,
        diagnosticsHistoryService: DiagnosticsHistoryService? = nil
    ) {
        self.paths = paths
        self.fileManager = fileManager
        self.capabilityReportService = capabilityReportService ?? CapabilityReportService(paths: paths, fileManager: fileManager)
        self.logService = LogService(paths: paths, fileManager: fileManager)
        self.diagnosticsHistoryService = diagnosticsHistoryService ?? DiagnosticsHistoryService(paths: paths, fileManager: fileManager)
    }

    @discardableResult
    public func exportBundle(
        generatedAt: Date = Date(),
        engines: [EngineManifest],
        bottles: [BottleManifest],
        recipes: [RecipeManifest],
        diagnosticReport: DiagnosticReport? = nil,
        logLimit: Int = 24,
        visualAcceptanceResultURL: URL? = nil
    ) throws -> URL {
        try paths.ensureBaseDirectories(fileManager: fileManager)
        let bundleURL = paths.logsDirectory
            .appendingPathComponent("SupportBundles", isDirectory: true)
            .appendingPathComponent("macwin-support-\(Self.fileTimestamp(generatedAt))-\(UUID().uuidString.prefix(8).lowercased())", isDirectory: true)
        try fileManager.createDirectory(at: bundleURL, withIntermediateDirectories: true)

        let store = JSONStore(fileManager: fileManager)
        let diagnosticArtifactIndex = DiagnosticArtifactIndexService(paths: paths, fileManager: fileManager)
            .report(limit: 500, generatedAt: generatedAt)
        let diagnosticArtifactIndexURL = bundleURL.appendingPathComponent("diagnostic-artifacts.json")
        try store.save(diagnosticArtifactIndex, to: diagnosticArtifactIndexURL)
        let diagnosticArtifactIndexCSVURL = bundleURL.appendingPathComponent("diagnostic-artifacts.csv")
        try Data(DiagnosticArtifactIndexReport.csv(report: diagnosticArtifactIndex).utf8).write(
            to: diagnosticArtifactIndexCSVURL,
            options: [.atomic]
        )
        let diagnosticArtifactIndexMarkdownURL = bundleURL.appendingPathComponent("diagnostic-artifacts.md")
        try Data(DiagnosticArtifactIndexReport.markdown(report: diagnosticArtifactIndex).utf8).write(
            to: diagnosticArtifactIndexMarkdownURL,
            options: [.atomic]
        )
        let report = capabilityReportService.makeReport(
            generatedAt: generatedAt,
            engines: engines,
            bottles: bottles,
            recipes: recipes,
            diagnosticReport: diagnosticReport,
            logLimit: logLimit
        )
        let capabilityURL = bundleURL.appendingPathComponent("capability-report.json")
        try store.save(report, to: capabilityURL)
        let diagnosticsCSVURL = bundleURL.appendingPathComponent("diagnostics.csv")
        if let diagnosticReport {
            try Data(Self.diagnosticsCSV(report: diagnosticReport).utf8).write(
                to: diagnosticsCSVURL,
                options: [.atomic]
            )
        }
        let diagnosticHistory = diagnosticsHistoryService.report(limit: logLimit)
        let diagnosticHistoryURL = bundleURL.appendingPathComponent("diagnostic-history.json")
        try store.save(diagnosticHistory, to: diagnosticHistoryURL)
        let diagnosticHistoryCSVURL = bundleURL.appendingPathComponent("diagnostic-history.csv")
        try Data(DiagnosticHistoryReport.csv(report: diagnosticHistory).utf8).write(
            to: diagnosticHistoryCSVURL,
            options: [.atomic]
        )
        let hostEnvironmentURL = bundleURL.appendingPathComponent("host-environment.json")
        let hostEnvironmentCSVURL = bundleURL.appendingPathComponent("host-environment.csv")
        if let hostEnvironment = report.hostEnvironment {
            try store.save(hostEnvironment, to: hostEnvironmentURL)
            try Data(HostEnvironmentReport.csv(report: hostEnvironment).utf8).write(
                to: hostEnvironmentCSVURL,
                options: [.atomic]
            )
        }
        let bottleHealthURL = bundleURL.appendingPathComponent("bottle-health.json")
        try store.save(report.bottleHealth, to: bottleHealthURL)
        let recipeReadinessURL = bundleURL.appendingPathComponent("recipe-readiness.json")
        try store.save(report.recipeReadiness, to: recipeReadinessURL)
        let installerAssetsURL = bundleURL.appendingPathComponent("installer-assets.json")
        try store.save(report.installerAssets, to: installerAssetsURL)
        let installerAssetsCSVURL = bundleURL.appendingPathComponent("installer-assets.csv")
        try Data(InstallerAssetService.csv(report: report.installerAssets).utf8).write(
            to: installerAssetsCSVURL,
            options: [.atomic]
        )
        let installerPreparation = InstallerAssetService.preparationReport(for: report.installerAssets)
        let installerPreparationURL = bundleURL.appendingPathComponent("installer-preparation.json")
        try store.save(installerPreparation, to: installerPreparationURL)
        let installerPreparationCSVURL = bundleURL.appendingPathComponent("installer-preparation.csv")
        try Data(InstallerAssetService.preparationCSV(report: installerPreparation).utf8).write(
            to: installerPreparationCSVURL,
            options: [.atomic]
        )
        let installerPreparationMarkdownURL = bundleURL.appendingPathComponent("installer-preparation.md")
        try Data(InstallerAssetService.preparationMarkdown(report: installerPreparation).utf8).write(
            to: installerPreparationMarkdownURL,
            options: [.atomic]
        )
        let installerDownloadHistoryURL = bundleURL.appendingPathComponent("installer-download-history.json")
        let installerDownloadHistoryCSVURL = bundleURL.appendingPathComponent("installer-download-history.csv")
        if let history = report.installerDownloadHistory {
            try store.save(history, to: installerDownloadHistoryURL)
            try Data(InstallerDownloadHistoryService.csv(report: history).utf8).write(
                to: installerDownloadHistoryCSVURL,
                options: [.atomic]
            )
        }
        let installerDownloadScriptURL = bundleURL.appendingPathComponent("download-installers.sh")
        try Data(InstallerAssetService.shellScript(for: report.installerAssets).utf8).write(
            to: installerDownloadScriptURL,
            options: [.atomic]
        )
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: installerDownloadScriptURL.path)
        let softwareTestPlanURL = bundleURL.appendingPathComponent("software-test-plan.json")
        try store.save(report.softwareTestPlan, to: softwareTestPlanURL)
        let softwareTestPlanCSVURL = bundleURL.appendingPathComponent("software-test-plan.csv")
        try Data(SoftwareTestPlanService.csv(report: report.softwareTestPlan).utf8).write(
            to: softwareTestPlanCSVURL,
            options: [.atomic]
        )
        let softwareSmokeMatrixURL = bundleURL.appendingPathComponent("software-smoke-matrix.json")
        try store.save(report.softwareSmokeMatrix, to: softwareSmokeMatrixURL)
        let softwareSmokeMatrixCSVURL = bundleURL.appendingPathComponent("software-smoke-matrix.csv")
        try Data(SoftwareSmokeMatrixService.csv(report: report.softwareSmokeMatrix).utf8).write(
            to: softwareSmokeMatrixCSVURL,
            options: [.atomic]
        )
        let softwareSmokeRunsURL = bundleURL.appendingPathComponent("software-smoke-runs.json")
        let softwareSmokeRunsCSVURL = bundleURL.appendingPathComponent("software-smoke-runs.csv")
        let softwareSmokeRunsMarkdownURL = bundleURL.appendingPathComponent("software-smoke-runs.md")
        if let softwareSmokeRuns = report.softwareSmokeRuns {
            try store.save(softwareSmokeRuns, to: softwareSmokeRunsURL)
            try Data(SoftwareSmokeRunReportService.csv(summary: softwareSmokeRuns).utf8).write(
                to: softwareSmokeRunsCSVURL,
                options: [.atomic]
            )
            try Data(SoftwareSmokeRunReportService.markdown(summary: softwareSmokeRuns).utf8).write(
                to: softwareSmokeRunsMarkdownURL,
                options: [.atomic]
            )
        }
        let softwareAdaptationRunbookURL = bundleURL.appendingPathComponent("software-adaptation-runbook.md")
        try Data(Self.softwareAdaptationRunbook(report: report, generatedAt: generatedAt).utf8).write(
            to: softwareAdaptationRunbookURL,
            options: [.atomic]
        )
        let softwareAdaptationQueue = SoftwareAdaptationQueueService(paths: paths).report(
            softwareTestPlan: report.softwareTestPlan,
            softwareSmokeMatrix: report.softwareSmokeMatrix,
            logIssues: report.logs.issueReport,
            testAssets: report.testAssets,
            generatedAt: generatedAt
        )
        let softwareAdaptationQueueURL = bundleURL.appendingPathComponent("software-adaptation-queue.json")
        try store.save(softwareAdaptationQueue, to: softwareAdaptationQueueURL)
        let softwareAdaptationQueueCSVURL = bundleURL.appendingPathComponent("software-adaptation-queue.csv")
        try Data(SoftwareAdaptationQueueService.csv(report: softwareAdaptationQueue).utf8).write(
            to: softwareAdaptationQueueCSVURL,
            options: [.atomic]
        )
        let softwareAdaptationQueueMarkdownURL = bundleURL.appendingPathComponent("software-adaptation-queue.md")
        try Data(SoftwareAdaptationQueueService.markdown(report: softwareAdaptationQueue).utf8).write(
            to: softwareAdaptationQueueMarkdownURL,
            options: [.atomic]
        )
        let softwareAdaptationQueueScriptURL = bundleURL.appendingPathComponent("software-adaptation-queue.sh")
        try Data(SoftwareAdaptationQueueService.shellScript(report: softwareAdaptationQueue).utf8).write(
            to: softwareAdaptationQueueScriptURL,
            options: [.atomic]
        )
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: softwareAdaptationQueueScriptURL.path)
        let softwareSampleCatalogURL = bundleURL.appendingPathComponent("software-sample-catalog.json")
        try store.save(report.softwareSampleCatalog, to: softwareSampleCatalogURL)
        let softwareSampleCatalogCSVURL = bundleURL.appendingPathComponent("software-sample-catalog.csv")
        try Data(SoftwareSampleCatalogService.csv(report: report.softwareSampleCatalog).utf8).write(
            to: softwareSampleCatalogCSVURL,
            options: [.atomic]
        )
        let softwareSampleCatalogRunbookURL = bundleURL.appendingPathComponent("software-sample-catalog-runbook.md")
        try Data(SoftwareSampleCatalogService.runbookMarkdown(report: report.softwareSampleCatalog).utf8).write(
            to: softwareSampleCatalogRunbookURL,
            options: [.atomic]
        )
        let softwareSamplePreparation = SoftwareSampleCatalogService(paths: paths).preparationReport(
            catalog: report.softwareSampleCatalog,
            generatedAt: generatedAt,
            fileManager: fileManager
        )
        let softwareSamplePreparationURL = bundleURL.appendingPathComponent("software-sample-preparation.json")
        try store.save(softwareSamplePreparation, to: softwareSamplePreparationURL)
        let softwareSamplePreparationCSVURL = bundleURL.appendingPathComponent("software-sample-preparation.csv")
        try Data(SoftwareSampleCatalogService.preparationCSV(report: softwareSamplePreparation).utf8).write(
            to: softwareSamplePreparationCSVURL,
            options: [.atomic]
        )
        let softwareSamplePreparationMarkdownURL = bundleURL.appendingPathComponent("software-sample-preparation.md")
        try Data(SoftwareSampleCatalogService.preparationMarkdown(report: softwareSamplePreparation).utf8).write(
            to: softwareSamplePreparationMarkdownURL,
            options: [.atomic]
        )
        let softwareSamplePreparationScriptURL = bundleURL.appendingPathComponent("software-sample-preparation.sh")
        try Data(SoftwareSampleCatalogService.preparationShellScript(report: softwareSamplePreparation).utf8).write(
            to: softwareSamplePreparationScriptURL,
            options: [.atomic]
        )
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: softwareSamplePreparationScriptURL.path)
        let softwareSampleLogCorrelationURL = bundleURL.appendingPathComponent("software-sample-log-correlation.json")
        try store.save(report.softwareSampleLogCorrelation, to: softwareSampleLogCorrelationURL)
        let softwareSampleLogCorrelationCSVURL = bundleURL.appendingPathComponent("software-sample-log-correlation.csv")
        try Data(SoftwareSampleLogCorrelationService.csv(report: report.softwareSampleLogCorrelation).utf8).write(
            to: softwareSampleLogCorrelationCSVURL,
            options: [.atomic]
        )
        let softwareSampleLogCorrelationMarkdownURL = bundleURL.appendingPathComponent("software-sample-log-correlation.md")
        try Data(SoftwareSampleLogCorrelationService.markdown(report: report.softwareSampleLogCorrelation).utf8).write(
            to: softwareSampleLogCorrelationMarkdownURL,
            options: [.atomic]
        )
        let softwareCollection = SoftwareCollectionService(paths: paths).report(
            recipes: recipes,
            readiness: report.recipeReadiness,
            installerAssets: report.installerAssets,
            softwareTestPlan: report.softwareTestPlan,
            softwareSmokeMatrix: report.softwareSmokeMatrix,
            adaptationQueue: softwareAdaptationQueue,
            generatedAt: generatedAt
        )
        let softwareCollectionURL = bundleURL.appendingPathComponent("software-collection.json")
        try store.save(softwareCollection, to: softwareCollectionURL)
        let softwareCollectionCSVURL = bundleURL.appendingPathComponent("software-collection.csv")
        try Data(SoftwareCollectionService.csv(report: softwareCollection).utf8).write(
            to: softwareCollectionCSVURL,
            options: [.atomic]
        )
        let softwareCollectionLockfile = SoftwareCollectionService.lockfile(report: softwareCollection)
        let softwareCollectionLockfileURL = bundleURL.appendingPathComponent("software-collection-lockfile.json")
        try store.save(softwareCollectionLockfile, to: softwareCollectionLockfileURL)
        let softwareCollectionLockfileCSVURL = bundleURL.appendingPathComponent("software-collection-lockfile.csv")
        try Data(SoftwareCollectionLockfile.csv(lockfile: softwareCollectionLockfile).utf8).write(
            to: softwareCollectionLockfileCSVURL,
            options: [.atomic]
        )
        let softwareCollectionLockfileMarkdownURL = bundleURL.appendingPathComponent("software-collection-lockfile.md")
        try Data(SoftwareCollectionLockfile.markdown(lockfile: softwareCollectionLockfile).utf8).write(
            to: softwareCollectionLockfileMarkdownURL,
            options: [.atomic]
        )
        let softwareCollectionDownloadScriptURL = bundleURL.appendingPathComponent("software-collection-downloads.sh")
        try Data(SoftwareCollectionService.downloadScript(report: softwareCollection).utf8).write(
            to: softwareCollectionDownloadScriptURL,
            options: [.atomic]
        )
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: softwareCollectionDownloadScriptURL.path)
        let softwareCollectionHistory = SoftwareCollectionHistoryService(paths: paths, fileManager: fileManager)
            .report(limit: logLimit)
        let softwareCollectionHistoryURL = bundleURL.appendingPathComponent("software-collection-history.json")
        try store.save(softwareCollectionHistory, to: softwareCollectionHistoryURL)
        let softwareCollectionHistoryCSVURL = bundleURL.appendingPathComponent("software-collection-history.csv")
        try Data(SoftwareCollectionHistoryService.csv(report: softwareCollectionHistory).utf8).write(
            to: softwareCollectionHistoryCSVURL,
            options: [.atomic]
        )
        let softwareCollectionAcceptance = SoftwareCollectionAcceptanceService().report(
            collection: softwareCollection,
            smokeMatrix: report.softwareSmokeMatrix,
            testExecutionPlan: report.testExecutionPlan,
            logIssues: report.logs.issueReport,
            generatedAt: generatedAt
        )
        let softwareCollectionAcceptanceURL = bundleURL.appendingPathComponent("software-collection-acceptance.json")
        try store.save(softwareCollectionAcceptance, to: softwareCollectionAcceptanceURL)
        let softwareCollectionAcceptanceCSVURL = bundleURL.appendingPathComponent("software-collection-acceptance.csv")
        try Data(SoftwareCollectionAcceptanceReport.csv(report: softwareCollectionAcceptance).utf8).write(
            to: softwareCollectionAcceptanceCSVURL,
            options: [.atomic]
        )
        let softwareCollectionAcceptanceMarkdownURL = bundleURL.appendingPathComponent("software-collection-acceptance.md")
        try Data(SoftwareCollectionAcceptanceReport.markdown(report: softwareCollectionAcceptance).utf8).write(
            to: softwareCollectionAcceptanceMarkdownURL,
            options: [.atomic]
        )
        let softwareCollectionAcceptanceRunbookURL = bundleURL.appendingPathComponent("software-collection-acceptance-runbook.sh")
        try Data(SoftwareCollectionAcceptanceReport.runbookScript(report: softwareCollectionAcceptance).utf8).write(
            to: softwareCollectionAcceptanceRunbookURL,
            options: [.atomic]
        )
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: softwareCollectionAcceptanceRunbookURL.path)
        let softwareAcquisition = SoftwareAcquisitionService().report(
            collection: softwareCollection,
            samplePreparation: softwareSamplePreparation,
            generatedAt: generatedAt
        )
        let softwareAcquisitionURL = bundleURL.appendingPathComponent("software-acquisition.json")
        try store.save(softwareAcquisition, to: softwareAcquisitionURL)
        let softwareAcquisitionCSVURL = bundleURL.appendingPathComponent("software-acquisition.csv")
        try Data(SoftwareAcquisitionReport.csv(report: softwareAcquisition).utf8).write(
            to: softwareAcquisitionCSVURL,
            options: [.atomic]
        )
        let softwareAcquisitionMarkdownURL = bundleURL.appendingPathComponent("software-acquisition.md")
        try Data(SoftwareAcquisitionReport.markdown(report: softwareAcquisition).utf8).write(
            to: softwareAcquisitionMarkdownURL,
            options: [.atomic]
        )
        let softwareAcquisitionScriptURL = bundleURL.appendingPathComponent("software-acquisition.sh")
        try Data(SoftwareAcquisitionReport.shellScript(report: softwareAcquisition).utf8).write(
            to: softwareAcquisitionScriptURL,
            options: [.atomic]
        )
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: softwareAcquisitionScriptURL.path)
        let installHistoryURL = bundleURL.appendingPathComponent("install-history.json")
        let installHistoryCSVURL = bundleURL.appendingPathComponent("install-history.csv")
        if let history = report.installHistory {
            try store.save(history, to: installHistoryURL)
            try Data(InstallHistoryReport.csv(report: history).utf8).write(
                to: installHistoryCSVURL,
                options: [.atomic]
            )
        }
        let testAssetsURL = bundleURL.appendingPathComponent("test-assets.json")
        try store.save(report.testAssets, to: testAssetsURL)
        let testRunbookURL = bundleURL.appendingPathComponent("test-runbook.json")
        let testRunbookScriptURL = bundleURL.appendingPathComponent("test-runbook.sh")
        if let runbook = report.testAssets.runbook {
            try store.save(runbook, to: testRunbookURL)
            try Data(TestAssetService.shellScript(for: runbook).utf8).write(to: testRunbookScriptURL, options: [.atomic])
            try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: testRunbookScriptURL.path)
        }
        let testRunHistoryURL = bundleURL.appendingPathComponent("test-run-history.json")
        let testRunHistoryCSVURL = bundleURL.appendingPathComponent("test-run-history.csv")
        if let history = report.testRunHistory {
            try store.save(history, to: testRunHistoryURL)
            try Data(TestRunHistoryReport.csv(report: history).utf8).write(
                to: testRunHistoryCSVURL,
                options: [.atomic]
            )
        }
        let testRunLogsDirectory = bundleURL.appendingPathComponent("test-runs", isDirectory: true)
        let rawTestRunLogsDirectory = testRunLogsDirectory.appendingPathComponent("raw", isDirectory: true)
        let redactedTestRunLogsDirectory = testRunLogsDirectory.appendingPathComponent("redacted", isDirectory: true)
        let testRunLogEntries = try copyTestRunLogs(
            report.testRunHistory?.runs ?? [],
            rawDirectory: rawTestRunLogsDirectory,
            redactedDirectory: redactedTestRunLogsDirectory
        )
        let testRunLogIndexURL = testRunLogsDirectory.appendingPathComponent("test-run-log-index.json")
        try store.save(testRunLogEntries, to: testRunLogIndexURL)
        let testRunLogIndexCSVURL = testRunLogsDirectory.appendingPathComponent("test-run-log-index.csv")
        try Data(Self.testRunLogIndexCSV(entries: testRunLogEntries).utf8).write(
            to: testRunLogIndexCSVURL,
            options: [.atomic]
        )
        let testCoverageURL = bundleURL.appendingPathComponent("test-coverage.json")
        try store.save(report.testCoverage, to: testCoverageURL)
        let testCoverageCSVURL = bundleURL.appendingPathComponent("test-coverage.csv")
        try Data(TestCoverageReport.csv(report: report.testCoverage).utf8).write(
            to: testCoverageCSVURL,
            options: [.atomic]
        )
        let testExecutionPlanURL = bundleURL.appendingPathComponent("test-execution-plan.json")
        try store.save(report.testExecutionPlan, to: testExecutionPlanURL)
        let testExecutionPlanCSVURL = bundleURL.appendingPathComponent("test-execution-plan.csv")
        try Data(TestExecutionPlan.csv(plan: report.testExecutionPlan).utf8).write(
            to: testExecutionPlanCSVURL,
            options: [.atomic]
        )
        let testExecutionPlanScriptURL = bundleURL.appendingPathComponent("test-execution-plan.sh")
        if let executionPlan = report.testExecutionPlan {
            try Data(TestAssetService.shellScript(forExecutionPlan: executionPlan).utf8).write(
                to: testExecutionPlanScriptURL,
                options: [.atomic]
            )
        } else {
            try Data(Self.emptyTestExecutionPlanScript().utf8).write(to: testExecutionPlanScriptURL, options: [.atomic])
        }
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: testExecutionPlanScriptURL.path)
        let launchHistoryURL = bundleURL.appendingPathComponent("launch-history.json")
        let launchHistoryCSVURL = bundleURL.appendingPathComponent("launch-history.csv")
        if let history = report.launchHistory {
            try store.save(history, to: launchHistoryURL)
            try Data(LaunchHistoryReport.csv(report: history).utf8).write(
                to: launchHistoryCSVURL,
                options: [.atomic]
            )
        }
        let launchReplayScriptURL = bundleURL.appendingPathComponent("launch-replay.sh")
        if let history = report.launchHistory {
            try Data(LaunchHistoryService.replayShellScript(for: history).utf8).write(
                to: launchReplayScriptURL,
                options: [.atomic]
            )
        } else {
            try Data(Self.emptyLaunchReplayScript().utf8).write(to: launchReplayScriptURL, options: [.atomic])
        }
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: launchReplayScriptURL.path)
        let launchHealth = LaunchHealthService(paths: paths).report(
            launchHistory: report.launchHistory,
            logs: report.logs,
            smokeReports: report.softwareSmokeRuns?.reports ?? [],
            generatedAt: generatedAt
        )
        let launchHealthURL = bundleURL.appendingPathComponent("launch-health.json")
        try store.save(launchHealth, to: launchHealthURL)
        let launchHealthCSVURL = bundleURL.appendingPathComponent("launch-health.csv")
        try Data(LaunchHealthReport.csv(report: launchHealth).utf8).write(
            to: launchHealthCSVURL,
            options: [.atomic]
        )
        let launchHealthMarkdownURL = bundleURL.appendingPathComponent("launch-health.md")
        try Data(LaunchHealthReport.markdown(report: launchHealth).utf8).write(
            to: launchHealthMarkdownURL,
            options: [.atomic]
        )
        let compatibilityRepairAuditURL = bundleURL.appendingPathComponent("compatibility-repair-audit.json")
        try store.save(report.compatibilityRepairAudit, to: compatibilityRepairAuditURL)
        let activityTimelineURL = bundleURL.appendingPathComponent("activity-timeline.json")
        try store.save(report.activityTimeline, to: activityTimelineURL)
        let runtimeProcessesURL = bundleURL.appendingPathComponent("runtime-processes.json")
        try store.save(report.runtimeProcesses, to: runtimeProcessesURL)
        let runtimeProcessesCSVURL = bundleURL.appendingPathComponent("runtime-processes.csv")
        try Data(RuntimeProcessAuditReport.csv(report: report.runtimeProcesses).utf8).write(
            to: runtimeProcessesCSVURL,
            options: [.atomic]
        )
        let runtimeApplicationsURL = bundleURL.appendingPathComponent("runtime-applications.json")
        try store.save(report.runtimeApplications, to: runtimeApplicationsURL)
        let runtimeApplicationsCSVURL = bundleURL.appendingPathComponent("runtime-applications.csv")
        try Data(RuntimeApplicationAuditReport.csv(report: report.runtimeApplications).utf8).write(
            to: runtimeApplicationsCSVURL,
            options: [.atomic]
        )
        let runtimeApplicationsLogURL = bundleURL.appendingPathComponent("runtime-applications.log")
        try Data(RuntimeApplicationAuditReport.diagnosticLogText(report: report.runtimeApplications).utf8).write(
            to: runtimeApplicationsLogURL,
            options: [.atomic]
        )
        let externalOpenQueue = ExternalExecutableOpenQueueService(paths: paths, fileManager: fileManager)
            .report(generatedAt: generatedAt)
        let externalOpenQueueURL = bundleURL.appendingPathComponent("external-open-queue.json")
        try store.save(externalOpenQueue, to: externalOpenQueueURL)
        let externalOpenQueueCSVURL = bundleURL.appendingPathComponent("external-open-queue.csv")
        try Data(ExternalExecutableOpenQueueService.csv(report: externalOpenQueue).utf8).write(
            to: externalOpenQueueCSVURL,
            options: [.atomic]
        )
        let externalOpenQueueLogURL = bundleURL.appendingPathComponent("external-open-queue.log")
        try Data(ExternalExecutableOpenQueueService.diagnosticLogText(report: externalOpenQueue).utf8).write(
            to: externalOpenQueueLogURL,
            options: [.atomic]
        )
        let logMaintenance = logService.maintenanceReport(generatedAt: generatedAt)
        let logMaintenanceURL = bundleURL.appendingPathComponent("log-maintenance.json")
        try store.save(logMaintenance, to: logMaintenanceURL)
        let logMaintenanceScriptURL = bundleURL.appendingPathComponent("log-maintenance.sh")
        try Data(LogService.maintenanceShellScript(for: logMaintenance).utf8).write(
            to: logMaintenanceScriptURL,
            options: [.atomic]
        )
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: logMaintenanceScriptURL.path)
        let logIssuesURL = bundleURL.appendingPathComponent("log-issues.json")
        try store.save(report.logs.issueReport, to: logIssuesURL)
        let logIssueCSVURL = bundleURL.appendingPathComponent("log-issues.csv")
        try Data(LogIssueReport.csv(report: report.logs.issueReport).utf8).write(
            to: logIssueCSVURL,
            options: [.atomic]
        )
        let logIssueMarkdownURL = bundleURL.appendingPathComponent("log-triage.md")
        try Data(LogService.triageMarkdown(report: report.logs.issueReport, generatedAt: generatedAt).utf8).write(
            to: logIssueMarkdownURL,
            options: [.atomic]
        )
        let logRemediationPlan = LogService.remediationPlan(report: report.logs.issueReport, generatedAt: generatedAt)
        let logRemediationPlanURL = bundleURL.appendingPathComponent("log-remediation-plan.json")
        try store.save(logRemediationPlan, to: logRemediationPlanURL)
        let logRemediationCSVURL = bundleURL.appendingPathComponent("log-remediation-plan.csv")
        try Data(LogRemediationPlan.csv(plan: logRemediationPlan).utf8).write(
            to: logRemediationCSVURL,
            options: [.atomic]
        )
        let logRemediationMarkdownURL = bundleURL.appendingPathComponent("log-remediation-plan.md")
        try Data(LogRemediationPlan.markdown(plan: logRemediationPlan).utf8).write(
            to: logRemediationMarkdownURL,
            options: [.atomic]
        )
        let logRemediationRunbookURL = bundleURL.appendingPathComponent("log-remediation-runbook.sh")
        try Data(LogRemediationPlan.runbookScript(plan: logRemediationPlan, runbook: report.testAssets.runbook).utf8).write(
            to: logRemediationRunbookURL,
            options: [.atomic]
        )
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: logRemediationRunbookURL.path)
        let recommendedProbeScriptURL = bundleURL.appendingPathComponent("log-issue-probes.sh")
        let recommendedProbeIds = TestAssetService.recommendedProbeIds(for: report.logs.issueReport)
        if let runbook = report.testAssets.runbook {
            try Data(TestAssetService.shellScript(forRecommendedProbes: report.logs.issueReport, runbook: runbook).utf8).write(
                to: recommendedProbeScriptURL,
                options: [.atomic]
            )
        } else {
            try Data(Self.emptyRecommendedProbeScript(recommendedProbeIds: recommendedProbeIds).utf8).write(
                to: recommendedProbeScriptURL,
                options: [.atomic]
            )
        }
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: recommendedProbeScriptURL.path)

        let supportTriage = SupportTriageService().report(
            generatedAt: generatedAt,
            capability: report,
            logRemediation: logRemediationPlan,
            softwareAcceptance: softwareCollectionAcceptance,
            softwareAcquisition: softwareAcquisition,
            launchHealth: launchHealth,
            externalOpenQueue: externalOpenQueue
        )
        let supportTriageURL = bundleURL.appendingPathComponent("support-triage.json")
        try store.save(supportTriage, to: supportTriageURL)
        let supportTriageCSVURL = bundleURL.appendingPathComponent("support-triage.csv")
        try Data(SupportTriageReport.csv(report: supportTriage).utf8).write(
            to: supportTriageCSVURL,
            options: [.atomic]
        )
        let supportTriageMarkdownURL = bundleURL.appendingPathComponent("support-triage.md")
        try Data(SupportTriageReport.markdown(report: supportTriage).utf8).write(
            to: supportTriageMarkdownURL,
            options: [.atomic]
        )

        try saveManifests(engines: engines, bottles: bottles, recipes: recipes, store: store, bundleURL: bundleURL)
        let logsDirectory = bundleURL.appendingPathComponent("logs", isDirectory: true)
        let rawLogsDirectory = logsDirectory.appendingPathComponent("raw", isDirectory: true)
        let redactedLogsDirectory = logsDirectory.appendingPathComponent("redacted", isDirectory: true)
        let logEntries = try copyRecentLogs(
            limit: logLimit,
            rawDirectory: rawLogsDirectory,
            redactedDirectory: redactedLogsDirectory
        )
        let logIndexURL = logsDirectory.appendingPathComponent("log-index.json")
        try store.save(logEntries, to: logIndexURL)
        let logIndexCSVURL = logsDirectory.appendingPathComponent("log-index.csv")
        try Data(Self.logIndexCSV(entries: logEntries).utf8).write(
            to: logIndexCSVURL,
            options: [.atomic]
        )
        let visualAcceptanceResultBundleURL = bundleURL.appendingPathComponent("visual-acceptance-result.json")
        let resolvedVisualAcceptanceResultURL = Self.visualAcceptanceResultURL(from: visualAcceptanceResultURL)
        let visualAcceptanceResultPath: String? = {
            guard let source = resolvedVisualAcceptanceResultURL else { return nil }
            do {
                return try copyArtifact(
                    source: source,
                    destination: visualAcceptanceResultBundleURL
                )
            } catch {
                return nil
            }
        }()
        let visualAcceptanceArtifactPaths: [String] = {
            guard let source = resolvedVisualAcceptanceResultURL else { return [] }
            return Self.copyVisualAcceptanceArtifacts(from: source, into: bundleURL)
        }()

        let fileManifestURL = bundleURL.appendingPathComponent("bundle-files.json")
        let fileManifestCSVURL = bundleURL.appendingPathComponent("bundle-files.csv")
        let manifest = SupportBundleManifest(
            generatedAt: generatedAt,
            rootPath: paths.root.path,
            bundlePath: bundleURL.path,
            fileManifestPath: fileManifestURL.path,
            fileManifestCSVPath: fileManifestCSVURL.path,
            capabilityReportPath: capabilityURL.path,
            hostEnvironmentPath: report.hostEnvironment == nil ? nil : hostEnvironmentURL.path,
            hostEnvironmentCSVPath: report.hostEnvironment == nil ? nil : hostEnvironmentCSVURL.path,
            bottleHealthReportPath: bottleHealthURL.path,
            recipeReadinessReportPath: recipeReadinessURL.path,
            installerAssetReportPath: installerAssetsURL.path,
            installerAssetCSVPath: installerAssetsCSVURL.path,
            installerPreparationReportPath: installerPreparationURL.path,
            installerPreparationCSVPath: installerPreparationCSVURL.path,
            installerPreparationMarkdownPath: installerPreparationMarkdownURL.path,
            installerDownloadHistoryPath: report.installerDownloadHistory == nil ? nil : installerDownloadHistoryURL.path,
            installerDownloadHistoryCSVPath: report.installerDownloadHistory == nil ? nil : installerDownloadHistoryCSVURL.path,
            installerDownloadScriptPath: installerDownloadScriptURL.path,
            softwareTestPlanPath: softwareTestPlanURL.path,
            softwareTestPlanCSVPath: softwareTestPlanCSVURL.path,
            softwareSmokeMatrixPath: softwareSmokeMatrixURL.path,
            softwareSmokeMatrixCSVPath: softwareSmokeMatrixCSVURL.path,
            softwareSmokeRunsPath: report.softwareSmokeRuns == nil ? nil : softwareSmokeRunsURL.path,
            softwareSmokeRunsCSVPath: report.softwareSmokeRuns == nil ? nil : softwareSmokeRunsCSVURL.path,
            softwareSmokeRunsMarkdownPath: report.softwareSmokeRuns == nil ? nil : softwareSmokeRunsMarkdownURL.path,
            softwareAdaptationRunbookPath: softwareAdaptationRunbookURL.path,
            softwareAdaptationQueuePath: softwareAdaptationQueueURL.path,
            softwareAdaptationQueueCSVPath: softwareAdaptationQueueCSVURL.path,
            softwareAdaptationQueueMarkdownPath: softwareAdaptationQueueMarkdownURL.path,
            softwareAdaptationQueueScriptPath: softwareAdaptationQueueScriptURL.path,
            softwareSampleCatalogPath: softwareSampleCatalogURL.path,
            softwareSampleCatalogCSVPath: softwareSampleCatalogCSVURL.path,
            softwareSampleCatalogRunbookPath: softwareSampleCatalogRunbookURL.path,
            softwareSamplePreparationPath: softwareSamplePreparationURL.path,
            softwareSamplePreparationCSVPath: softwareSamplePreparationCSVURL.path,
            softwareSamplePreparationMarkdownPath: softwareSamplePreparationMarkdownURL.path,
            softwareSamplePreparationScriptPath: softwareSamplePreparationScriptURL.path,
            softwareSampleLogCorrelationPath: softwareSampleLogCorrelationURL.path,
            softwareSampleLogCorrelationCSVPath: softwareSampleLogCorrelationCSVURL.path,
            softwareSampleLogCorrelationMarkdownPath: softwareSampleLogCorrelationMarkdownURL.path,
            softwareCollectionPath: softwareCollectionURL.path,
            softwareCollectionCSVPath: softwareCollectionCSVURL.path,
            softwareCollectionLockfilePath: softwareCollectionLockfileURL.path,
            softwareCollectionLockfileCSVPath: softwareCollectionLockfileCSVURL.path,
            softwareCollectionLockfileMarkdownPath: softwareCollectionLockfileMarkdownURL.path,
            softwareCollectionDownloadScriptPath: softwareCollectionDownloadScriptURL.path,
            softwareCollectionHistoryPath: softwareCollectionHistoryURL.path,
            softwareCollectionHistoryCSVPath: softwareCollectionHistoryCSVURL.path,
            softwareCollectionAcceptancePath: softwareCollectionAcceptanceURL.path,
            softwareCollectionAcceptanceCSVPath: softwareCollectionAcceptanceCSVURL.path,
            softwareCollectionAcceptanceMarkdownPath: softwareCollectionAcceptanceMarkdownURL.path,
            softwareCollectionAcceptanceRunbookPath: softwareCollectionAcceptanceRunbookURL.path,
            softwareAcquisitionPath: softwareAcquisitionURL.path,
            softwareAcquisitionCSVPath: softwareAcquisitionCSVURL.path,
            softwareAcquisitionMarkdownPath: softwareAcquisitionMarkdownURL.path,
            softwareAcquisitionScriptPath: softwareAcquisitionScriptURL.path,
            installHistoryPath: report.installHistory == nil ? nil : installHistoryURL.path,
            installHistoryCSVPath: report.installHistory == nil ? nil : installHistoryCSVURL.path,
            testAssetReportPath: testAssetsURL.path,
            testRunbookPath: report.testAssets.runbook == nil ? nil : testRunbookURL.path,
            testRunbookScriptPath: report.testAssets.runbook == nil ? nil : testRunbookScriptURL.path,
            testRunHistoryPath: report.testRunHistory == nil ? nil : testRunHistoryURL.path,
            testRunHistoryCSVPath: report.testRunHistory == nil ? nil : testRunHistoryCSVURL.path,
            testRunLogIndexPath: testRunLogIndexURL.path,
            testRunLogIndexCSVPath: testRunLogIndexCSVURL.path,
            rawTestRunLogDirectoryPath: rawTestRunLogsDirectory.path,
            redactedTestRunLogDirectoryPath: redactedTestRunLogsDirectory.path,
            testCoverageReportPath: testCoverageURL.path,
            testCoverageCSVPath: testCoverageCSVURL.path,
            testExecutionPlanPath: testExecutionPlanURL.path,
            testExecutionPlanCSVPath: testExecutionPlanCSVURL.path,
            testExecutionPlanScriptPath: testExecutionPlanScriptURL.path,
            launchHistoryPath: report.launchHistory == nil ? nil : launchHistoryURL.path,
            launchHistoryCSVPath: report.launchHistory == nil ? nil : launchHistoryCSVURL.path,
            launchReplayScriptPath: launchReplayScriptURL.path,
            launchHealthPath: launchHealthURL.path,
            launchHealthCSVPath: launchHealthCSVURL.path,
            launchHealthMarkdownPath: launchHealthMarkdownURL.path,
            compatibilityRepairAuditPath: compatibilityRepairAuditURL.path,
            activityTimelinePath: activityTimelineURL.path,
            runtimeProcessReportPath: runtimeProcessesURL.path,
            runtimeProcessCSVPath: runtimeProcessesCSVURL.path,
            runtimeApplicationReportPath: runtimeApplicationsURL.path,
            runtimeApplicationCSVPath: runtimeApplicationsCSVURL.path,
            runtimeApplicationLogPath: runtimeApplicationsLogURL.path,
            externalOpenQueueReportPath: externalOpenQueueURL.path,
            externalOpenQueueCSVPath: externalOpenQueueCSVURL.path,
            externalOpenQueueLogPath: externalOpenQueueLogURL.path,
            supportTriagePath: supportTriageURL.path,
            supportTriageCSVPath: supportTriageCSVURL.path,
            supportTriageMarkdownPath: supportTriageMarkdownURL.path,
            logMaintenanceReportPath: logMaintenanceURL.path,
            logMaintenanceScriptPath: logMaintenanceScriptURL.path,
            logIssueReportPath: logIssuesURL.path,
            logIssueCSVPath: logIssueCSVURL.path,
            logIssueMarkdownPath: logIssueMarkdownURL.path,
            logRemediationPlanPath: logRemediationPlanURL.path,
            logRemediationCSVPath: logRemediationCSVURL.path,
            logRemediationMarkdownPath: logRemediationMarkdownURL.path,
            logRemediationRunbookPath: logRemediationRunbookURL.path,
            recommendedProbeScriptPath: recommendedProbeScriptURL.path,
            logIndexPath: logIndexURL.path,
            logIndexCSVPath: logIndexCSVURL.path,
            rawLogDirectoryPath: rawLogsDirectory.path,
            redactedLogDirectoryPath: redactedLogsDirectory.path,
            includedLogCount: logEntries.count,
            logIssueCount: report.logs.issueReport.topIssues.count,
            logRemediationActionCount: logRemediationPlan.actionCount,
            logRemediationProbeActionCount: logRemediationPlan.probeActionCount,
            recommendedProbeCount: recommendedProbeIds.count,
            recentFailureLogCount: report.logs.issueReport.recentFailures.count,
            totalLogBytes: logMaintenance.totalLogBytes,
            staleLogCount: logMaintenance.staleLogCount,
            largeLogCount: logMaintenance.largeLogCount,
            cleanupCandidateLogCount: logMaintenance.cleanupCandidateCount,
            cleanupCandidateLogBytes: logMaintenance.cleanupCandidateBytes,
            healthyBottleCount: report.bottleHealth.healthyBottleCount,
            bottleHealthWarningCount: report.bottleHealth.warningBottleCount,
            bottleHealthActionRequiredCount: report.bottleHealth.actionRequiredBottleCount,
            bottleHealthFindingCount: report.bottleHealth.findingCount,
            staleLauncherCount: report.bottleHealth.staleLauncherCount,
            incompleteCompatibilityProfileCount: report.bottleHealth.incompleteCompatibilityProfileCount,
            readyRecipeCount: report.recipeReadiness.readyCount,
            actionRequiredRecipeCount: report.recipeReadiness.actionRequiredCount,
            blockedRecipeCount: report.recipeReadiness.blockedCount,
            disabledRecipeCount: report.recipeReadiness.disabledCount,
            recipeReadinessIssueCount: report.recipeReadiness.issueCounts.values.reduce(0, +),
            installerAssetCount: report.installerAssets.cachedRecipeCount,
            installerPreparationActionCount: installerPreparation.actionCount,
            installerPreparationCriticalCount: installerPreparation.criticalCount,
            installerPreparationWarningCount: installerPreparation.warningCount,
            installerDownloadRecordCount: report.installerDownloadHistory?.totalRecordCount ?? 0,
            installerDownloadFailedCount: report.installerDownloadHistory?.failedCount ?? 0,
            installerHashMismatchCount: report.installerAssets.hashMismatchCount,
            orphanedDownloadCount: report.installerAssets.orphanedFileCount,
            softwareReadyToInstallCount: report.softwareTestPlan.readyToInstallCount,
            softwareInstalledCount: report.softwareTestPlan.installedCount,
            softwareVerifiedCount: report.softwareTestPlan.verifiedCount,
            softwareFailingCount: report.softwareTestPlan.failingCount,
            softwareReviewCount: report.softwareTestPlan.reviewCount,
            softwareSmokeBlockedCount: report.softwareSmokeMatrix.blockedCount,
            softwareSmokeWarningCount: report.softwareSmokeMatrix.warningCount,
            softwareSmokeFailedCount: report.softwareSmokeMatrix.failedCount,
            softwareSmokeVerifiedCount: report.softwareSmokeMatrix.verifiedCount,
            softwareSmokeRunReportCount: report.softwareSmokeRuns?.reportCount,
            softwareSmokeRunSupersededSkipCount: report.softwareSmokeRuns?.supersededSkipCount,
            softwareSmokeRunUncoveredSkippedCount: report.softwareSmokeRuns?.uncoveredSkippedCount,
            softwareAdaptationTaskCount: softwareAdaptationQueue.taskCount,
            softwareAdaptationRunnableProbeCount: softwareAdaptationQueue.runnableProbeCount,
            softwareAdaptationUnavailableProbeCount: softwareAdaptationQueue.unavailableProbeCount,
            softwareSampleCatalogCount: report.softwareSampleCatalog.sampleCount,
            softwareSampleCatalogLocalInstallerCount: report.softwareSampleCatalog.localInstallerCount,
            softwareSampleCatalogSignedRecipeCount: report.softwareSampleCatalog.catalogBackedCount,
            softwareSampleCatalogWarningCount: report.softwareSampleCatalog.warningCount,
            softwareSamplePreparationReadyCount: softwareSamplePreparation.readyCount,
            softwareSamplePreparationMissingInstallerCount: softwareSamplePreparation.missingInstallerCount,
            softwareSamplePreparationMissingRecipeCount: softwareSamplePreparation.missingRecipeCount,
            softwareSamplePreparationManualCount: softwareSamplePreparation.manualCount,
            softwareSampleMatchedCount: report.softwareSampleLogCorrelation.matchedSampleCount,
            softwareSampleFailedCount: report.softwareSampleLogCorrelation.failedSampleCount,
            softwareSampleAttentionCount: report.softwareSampleLogCorrelation.attentionSampleCount,
            softwareCollectionRecipeCount: softwareCollection.recipeCount,
            softwareCollectionMissingRecipeCount: softwareCollection.missingRecipeCount,
            softwareCollectionMissingInstallerCount: softwareCollection.missingInstallerCount,
            softwareCollectionActionRequiredCount: softwareCollection.actionRequiredCount,
            softwareCollectionHashProtectedCount: softwareCollectionLockfile.hashProtectedCount,
            softwareCollectionHashMismatchCount: softwareCollectionLockfile.hashMismatchCount,
            softwareCollectionUnprotectedDownloadCount: softwareCollectionLockfile.unprotectedDownloadCount,
            softwareCollectionHistoryRecordCount: softwareCollectionHistory.totalRecordCount,
            softwareCollectionHistoryFailedCount: softwareCollectionHistory.failedCount,
            softwareCollectionAcceptanceState: softwareCollectionAcceptance.state.rawValue,
            softwareCollectionAcceptanceActionCount: softwareCollectionAcceptance.actionCount,
            softwareCollectionAcceptanceBlockerCount: softwareCollectionAcceptance.blockerCount,
            softwareCollectionAcceptanceHighPriorityCount: softwareCollectionAcceptance.highPriorityCount,
            softwareAcquisitionActionCount: softwareAcquisition.actionCount,
            softwareAcquisitionDownloadableCount: softwareAcquisition.downloadableCount,
            softwareAcquisitionMissingLocalInstallerCount: softwareAcquisition.missingLocalInstallerCount,
            softwareAcquisitionMissingRecipeCount: softwareAcquisition.missingRecipeCount,
            softwareAcquisitionHashMismatchCount: softwareAcquisition.hashMismatchCount,
            installTaskCount: report.installHistory?.totalTaskCount ?? 0,
            failedInstallTaskCount: report.installHistory?.failedCount ?? 0,
            verifiedTestCategoryCount: report.testCoverage.verifiedCategoryCount,
            missingRequiredTestAssetCount: report.testCoverage.missingRequiredExecutableCount,
            failedTestAssetCount: report.testCoverage.failedAssetCount,
            timedOutTestAssetCount: report.testCoverage.timedOutAssetCount,
            unverifiedTestAssetCount: report.testCoverage.unverifiedAssetCount,
            includedTestRunLogCount: testRunLogEntries.count,
            testExecutionPlanItemCount: report.testExecutionPlan?.itemCount ?? 0,
            testExecutionPlanRequiredCount: report.testExecutionPlan?.requiredCount ?? 0,
            testExecutionPlanHighPriorityCount: report.testExecutionPlan?.highPriorityCount ?? 0,
            activityTimelineEventCount: report.activityTimeline.eventCount,
            activityTimelineErrorCount: report.activityTimeline.errorEventCount,
            activityTimelineWarningCount: report.activityTimeline.warningEventCount,
            engineCount: engines.count,
            bottleCount: bottles.count,
            recipeCount: recipes.count,
            diagnosticLogPath: diagnosticReport?.logURL.path,
            diagnosticsCSVPath: diagnosticReport == nil ? nil : diagnosticsCSVURL.path,
            diagnosticHistoryPath: diagnosticHistoryURL.path,
            diagnosticHistoryCSVPath: diagnosticHistoryCSVURL.path,
            diagnosticArtifactIndexPath: diagnosticArtifactIndexURL.path,
            diagnosticArtifactIndexCSVPath: diagnosticArtifactIndexCSVURL.path,
            diagnosticArtifactIndexMarkdownPath: diagnosticArtifactIndexMarkdownURL.path,
            diagnosticArtifactCount: diagnosticArtifactIndex.artifactCount,
            diagnosticArtifactBytes: diagnosticArtifactIndex.totalBytes,
            diagnosticRunCount: diagnosticHistory.totalRunCount,
            failedDiagnosticRunCount: diagnosticHistory.failedRunCount,
            timedOutDiagnosticRunCount: diagnosticHistory.timedOutRunCount,
            launchHistoryCount: report.launchHistory?.totalLaunchCount ?? 0,
            launchHealthEntryCount: launchHealth.entryCount,
            failedLaunchHealthEntryCount: launchHealth.failedEntryCount,
            attentionLaunchHealthEntryCount: launchHealth.attentionEntryCount,
            logMatchedLaunchHealthCount: launchHealth.logMatchedLaunchCount,
            visualAcceptanceResultPath: visualAcceptanceResultPath,
            visualAcceptanceArtifactPaths: visualAcceptanceArtifactPaths,
            compatibilityRepairAuditedLaunchCount: report.compatibilityRepairAudit.auditedLaunchCount,
            compatibilityRepairMissingLaunchCount: report.compatibilityRepairAudit.missingRepairLaunchCount,
            compatibilityRepairStaleFlagLaunchCount: report.compatibilityRepairAudit.staleFlagLaunchCount,
            compatibilityRepairFindingCount: report.compatibilityRepairAudit.findings.count,
            runtimeProcessCount: report.runtimeProcesses?.auditedProcessCount ?? 0,
            runtimeProcessFindingCount: report.runtimeProcesses?.findings.count ?? 0,
            runtimeApplicationCount: report.runtimeApplications?.auditedApplicationCount ?? 0,
            runtimeApplicationFindingCount: report.runtimeApplications?.findings.count ?? 0,
            runtimeMacWinApplicationCount: report.runtimeApplications?.macWinApplicationCount ?? 0,
            runtimeWineApplicationCount: report.runtimeApplications?.wineRelatedApplicationCount ?? 0,
            externalOpenQueuePendingCount: externalOpenQueue.pendingCount,
            externalOpenQueueDuplicateCount: externalOpenQueue.duplicatePendingCount,
            externalOpenQueueInvalidLineCount: externalOpenQueue.invalidLineCount,
            supportTriageStatus: supportTriage.status.rawValue,
            supportTriageItemCount: supportTriage.itemCount,
            supportTriageBlockerCount: supportTriage.blockerCount,
            supportTriageHighCount: supportTriage.highCount,
            supportTriageWarningCount: supportTriage.warningCount
        )
        try store.save(manifest, to: bundleURL.appendingPathComponent("support-bundle.json"))
        try writeReadme(manifest: manifest, report: report, to: bundleURL.appendingPathComponent("README.txt"))
        let fileManifest = try bundleFileManifest(
            generatedAt: generatedAt,
            bundleURL: bundleURL,
            excluding: [fileManifestURL, fileManifestCSVURL]
        )
        try store.save(fileManifest, to: fileManifestURL)
        try Data(Self.fileManifestCSV(fileManifest).utf8).write(to: fileManifestCSVURL, options: [.atomic])
        return bundleURL
    }

    private func saveManifests(
        engines: [EngineManifest],
        bottles: [BottleManifest],
        recipes: [RecipeManifest],
        store: JSONStore,
        bundleURL: URL
    ) throws {
        let enginesDirectory = bundleURL.appendingPathComponent("engines", isDirectory: true)
        let bottlesDirectory = bundleURL.appendingPathComponent("bottles", isDirectory: true)
        let catalogDirectory = bundleURL.appendingPathComponent("catalog", isDirectory: true)

        for engine in engines {
            try store.save(engine, to: enginesDirectory.appendingPathComponent("\(Self.safeFileName(engine.id)).manifest.json"))
        }
        for bottle in bottles {
            try store.save(bottle, to: bottlesDirectory.appendingPathComponent("\(Self.safeFileName(bottle.id)).manifest.json"))
        }
        try store.save(recipes.sorted { $0.id < $1.id }, to: catalogDirectory.appendingPathComponent("recipes.json"))
    }

    private func bundleFileManifest(
        generatedAt: Date,
        bundleURL: URL,
        excluding excludedURLs: Set<URL>
    ) throws -> SupportBundleFileManifest {
        let excludedPaths = Set(excludedURLs.map { $0.standardizedFileURL.path })
        guard let enumerator = fileManager.enumerator(
            at: bundleURL,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return SupportBundleFileManifest(generatedAt: generatedAt, bundlePath: bundleURL.path, files: [])
        }

        var entries: [SupportBundleFileEntry] = []
        for case let fileURL as URL in enumerator {
            let standardized = fileURL.standardizedFileURL
            guard !excludedPaths.contains(standardized.path) else { continue }
            let values = try standardized.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey])
            guard values.isRegularFile == true else { continue }
            entries.append(SupportBundleFileEntry(
                relativePath: Self.relativePath(for: standardized, baseURL: bundleURL),
                byteCount: Int64(values.fileSize ?? 0),
                modifiedAt: values.contentModificationDate ?? .distantPast,
                sha256: try Hashing.sha256Hex(file: standardized)
            ))
        }

        entries.sort { lhs, rhs in
            lhs.relativePath.localizedStandardCompare(rhs.relativePath) == .orderedAscending
        }
        return SupportBundleFileManifest(generatedAt: generatedAt, bundlePath: bundleURL.path, files: entries)
    }

    private static func visualAcceptanceResultURL(from preferred: URL?) -> URL? {
        if let preferred {
            let preferredURL = preferred.standardizedFileURL
            if FileManager.default.fileExists(atPath: preferredURL.path) { return preferredURL }
            return nil
        }

        let env = ProcessInfo.processInfo.environment
        if let explicit = env["MACWIN_VISUAL_RESULT_JSON"], !explicit.isEmpty {
            let explicitURL = URL(fileURLWithPath: explicit).standardizedFileURL
            if FileManager.default.fileExists(atPath: explicitURL.path) { return explicitURL }
        }
        if let outputDir = env["MACWIN_VISUAL_OUTPUT_DIR"], !outputDir.isEmpty {
            let outputURL = URL(fileURLWithPath: outputDir)
                .appendingPathComponent("macwin-visual-acceptance-result.json")
                .standardizedFileURL
            if FileManager.default.fileExists(atPath: outputURL.path) { return outputURL }
        }

        let fallback = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop")
            .appendingPathComponent("MacWinVisualAcceptance")
            .appendingPathComponent("macwin-visual-acceptance-result.json")
            .standardizedFileURL
        if FileManager.default.fileExists(atPath: fallback.path) { return fallback }
        return nil
    }

    private static func copyVisualAcceptanceArtifacts(from resultURL: URL, into bundleURL: URL) -> [String] {
        guard let data = try? Data(contentsOf: resultURL),
              let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let artifacts = payload["artifacts"] as? [String: String] else {
            return []
        }

        let resultDirectory = resultURL.deletingLastPathComponent()
        var copiedPaths: [String] = []
        let knownArtifactMap: [(key: String, destination: URL)] = [
            ("analysisJson", bundleURL.appendingPathComponent("visual-acceptance-analysis.json")),
            ("screenshot", bundleURL.appendingPathComponent("visual-acceptance-screenshot.png"))
        ]

        for (key, destination) in knownArtifactMap {
            guard let path = artifacts[key], !path.isEmpty else { continue }
            let source = URL(fileURLWithPath: path, relativeTo: resultDirectory)
            do {
                let sourceURL = source.standardizedFileURL
                let destinationURL = destination.standardizedFileURL
                if sourceURL.path != destinationURL.path {
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    try FileManager.default.createDirectory(
                        at: destinationURL.deletingLastPathComponent(),
                        withIntermediateDirectories: true
                    )
                    try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                }
                let copied = destinationURL.path
                copiedPaths.append(copied)
            } catch {
                continue
            }
        }

        return copiedPaths
    }

    private func copyArtifact(source: URL, destination: URL) throws -> String {
        let sourceURL = source.standardizedFileURL
        let destinationURL = destination.standardizedFileURL
        if sourceURL.path == destinationURL.path {
            return destinationURL.path
        }
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        return destinationURL.path
    }

    public static func fileManifestCSV(_ manifest: SupportBundleFileManifest) -> String {
        var rows: [[String]] = [[
            "relative_path",
            "byte_count",
            "modified_at",
            "sha256"
        ]]
        let formatter = ISO8601DateFormatter()
        for entry in manifest.files {
            rows.append([
                entry.relativePath,
                String(entry.byteCount),
                formatter.string(from: entry.modifiedAt),
                entry.sha256
            ])
        }
        return rows
            .map { $0.map(csvEscaped).joined(separator: ",") }
            .joined(separator: "\n")
    }

    private static func relativePath(for fileURL: URL, baseURL: URL) -> String {
        let basePath = baseURL.standardizedFileURL.path
        let filePath = fileURL.standardizedFileURL.path
        guard filePath.hasPrefix(basePath + "/") else {
            return fileURL.lastPathComponent
        }
        return String(filePath.dropFirst(basePath.count + 1))
    }

    private func copyRecentLogs(
        limit: Int,
        rawDirectory: URL,
        redactedDirectory: URL
    ) throws -> [SupportBundleLogEntry] {
        let logs = logService.recentLogs(limit: limit)
        try fileManager.createDirectory(at: rawDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: redactedDirectory, withIntermediateDirectories: true)
        var entries: [SupportBundleLogEntry] = []
        for item in logs {
            let fileName = Self.safeFileName(item.name)
            let rawDestination = rawDirectory.appendingPathComponent(fileName)
            let redactedDestination = redactedDirectory.appendingPathComponent(fileName)
            if fileManager.fileExists(atPath: rawDestination.path) {
                try fileManager.removeItem(at: rawDestination)
            }
            if fileManager.fileExists(atPath: redactedDestination.path) {
                try fileManager.removeItem(at: redactedDestination)
            }
            try fileManager.copyItem(at: item.url, to: rawDestination)

            let redaction = try Self.redactedLogData(file: item.url, macWinRoot: paths.root.path)
            try redaction.data.write(to: redactedDestination, options: [.atomic])
            let rawSha256 = try Hashing.sha256Hex(file: rawDestination)
            let redactedSha256 = try Hashing.sha256Hex(file: redactedDestination)
            entries.append(
                SupportBundleLogEntry(
                    name: item.name,
                    sourcePath: item.url.path,
                    rawPath: rawDestination.path,
                    redactedPath: redactedDestination.path,
                    rawSha256: rawSha256,
                    redactedSha256: redactedSha256,
                    modifiedAt: item.modifiedAt,
                    byteCount: item.byteCount,
                    health: item.summary.health.rawValue,
                    hints: item.summary.hints.map(\.rawValue),
                    redactionCount: redaction.count,
                    launchRecordId: item.launchContext?.launchRecordId,
                    bottleId: item.launchContext?.bottleId,
                    bottleName: item.launchContext?.bottleName,
                    engineId: item.launchContext?.engineId,
                    exe: item.launchContext?.exe,
                    args: item.launchContext?.args ?? [],
                    exitCode: item.launchContext?.exitCode
                )
            )
        }
        return entries
    }

    private func copyTestRunLogs(
        _ runs: [TestRunRecord],
        rawDirectory: URL,
        redactedDirectory: URL
    ) throws -> [SupportBundleTestRunLogEntry] {
        try fileManager.createDirectory(at: rawDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: redactedDirectory, withIntermediateDirectories: true)
        var entries: [SupportBundleTestRunLogEntry] = []
        for run in runs {
            let source = URL(fileURLWithPath: run.logPath)
            guard fileManager.fileExists(atPath: source.path) else { continue }
            let fileName = Self.safeFileName(source.lastPathComponent)
            let rawDestination = rawDirectory.appendingPathComponent(fileName)
            let redactedDestination = redactedDirectory.appendingPathComponent(fileName)
            if fileManager.fileExists(atPath: rawDestination.path) {
                try fileManager.removeItem(at: rawDestination)
            }
            if fileManager.fileExists(atPath: redactedDestination.path) {
                try fileManager.removeItem(at: redactedDestination)
            }
            try fileManager.copyItem(at: source, to: rawDestination)

            let redaction = try Self.redactedLogData(file: source, macWinRoot: paths.root.path)
            try redaction.data.write(to: redactedDestination, options: [.atomic])
            let rawSha256 = try Hashing.sha256Hex(file: rawDestination)
            let redactedSha256 = try Hashing.sha256Hex(file: redactedDestination)
            entries.append(SupportBundleTestRunLogEntry(
                name: source.lastPathComponent,
                assetId: run.assetId,
                outcome: run.outcome,
                sourcePath: source.path,
                rawPath: rawDestination.path,
                redactedPath: redactedDestination.path,
                rawSha256: rawSha256,
                redactedSha256: redactedSha256,
                modifiedAt: run.modifiedAt,
                byteCount: run.byteCount,
                redactionCount: redaction.count,
                passSignalCount: run.passSignals.count,
                failSignalCount: run.failSignals.count,
                exitCode: run.exitCode
            ))
        }
        return entries.sorted { lhs, rhs in
            if lhs.modifiedAt != rhs.modifiedAt {
                return lhs.modifiedAt > rhs.modifiedAt
            }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    public static func logIndexCSV(entries: [SupportBundleLogEntry]) -> String {
        var rows: [[String]] = [[
            "name",
            "health",
            "modified_at",
            "byte_count",
            "redaction_count",
            "hints",
            "launch_record_id",
            "bottle_id",
            "bottle_name",
            "engine_id",
            "exe",
            "args",
            "exit_code",
            "source_path",
            "raw_path",
            "redacted_path",
            "raw_sha256",
            "redacted_sha256"
        ]]
        let formatter = ISO8601DateFormatter()
        for entry in entries {
            rows.append([
                entry.name,
                entry.health,
                formatter.string(from: entry.modifiedAt),
                String(entry.byteCount),
                String(entry.redactionCount),
                entry.hints.joined(separator: ";"),
                entry.launchRecordId ?? "",
                entry.bottleId ?? "",
                entry.bottleName ?? "",
                entry.engineId ?? "",
                entry.exe ?? "",
                entry.args.joined(separator: " "),
                entry.exitCode.map(String.init) ?? "",
                entry.sourcePath,
                entry.rawPath,
                entry.redactedPath,
                entry.rawSha256,
                entry.redactedSha256
            ])
        }
        return rows
            .map { $0.map(csvEscaped).joined(separator: ",") }
            .joined(separator: "\n")
    }

    public static func testRunLogIndexCSV(entries: [SupportBundleTestRunLogEntry]) -> String {
        var rows: [[String]] = [[
            "name",
            "asset_id",
            "outcome",
            "modified_at",
            "byte_count",
            "redaction_count",
            "pass_signal_count",
            "fail_signal_count",
            "exit_code",
            "source_path",
            "raw_path",
            "redacted_path",
            "raw_sha256",
            "redacted_sha256"
        ]]
        let formatter = ISO8601DateFormatter()
        for entry in entries {
            rows.append([
                entry.name,
                entry.assetId ?? "",
                entry.outcome.rawValue,
                formatter.string(from: entry.modifiedAt),
                String(entry.byteCount),
                String(entry.redactionCount),
                String(entry.passSignalCount),
                String(entry.failSignalCount),
                entry.exitCode.map(String.init) ?? "",
                entry.sourcePath,
                entry.rawPath,
                entry.redactedPath,
                entry.rawSha256,
                entry.redactedSha256
            ])
        }
        return rows
            .map { $0.map(csvEscaped).joined(separator: ",") }
            .joined(separator: "\n")
    }

    public static func diagnosticsCSV(report: DiagnosticReport) -> String {
        var rows: [[String]] = [[
            "record_type",
            "id",
            "name",
            "category",
            "status",
            "passed",
            "detail",
            "exit_code",
            "timed_out",
            "duration_seconds",
            "log_path"
        ]]
        rows.append([
            "summary",
            "diagnostics",
            "Probe Suite",
            "",
            report.timedOut ? "timedOut" : (report.exitCode == 0 ? "completed" : "failed"),
            report.items.allSatisfy(\.passed) ? "true" : "false",
            "\(report.items.filter(\.passed).count)/\(report.items.count) passed",
            String(report.exitCode),
            report.timedOut ? "true" : "false",
            String(format: "%.3f", report.durationSeconds),
            report.logURL.path
        ])
        for item in report.items {
            rows.append([
                "item",
                item.id,
                item.name,
                item.category.rawValue,
                item.status.rawValue,
                item.passed ? "true" : "false",
                item.detail,
                "",
                "",
                "",
                ""
            ])
        }
        return rows
            .map { $0.map(csvEscaped).joined(separator: ",") }
            .joined(separator: "\n")
    }

    private static func csvEscaped(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    private func writeReadme(manifest: SupportBundleManifest, report: CapabilityReport, to url: URL) throws {
        var lines = [
            "MacWin Manager Support Bundle",
            "Generated At: \(ISO8601DateFormatter().string(from: manifest.generatedAt))",
            "Root: \(manifest.rootPath)",
            "",
            "Engines: \(manifest.engineCount)",
            "Bottles: \(manifest.bottleCount)",
            "Healthy Bottles: \(manifest.healthyBottleCount)",
            "Bottle Health Warnings: \(manifest.bottleHealthWarningCount)",
            "Bottle Health Action Required: \(manifest.bottleHealthActionRequiredCount)",
            "Bottle Health Findings: \(manifest.bottleHealthFindingCount)",
            "Stale Launcher Profiles: \(manifest.staleLauncherCount)",
            "Incomplete Compatibility Profiles: \(manifest.incompleteCompatibilityProfileCount)",
            "Recipes: \(manifest.recipeCount)",
            "Recipes Ready: \(manifest.readyRecipeCount)",
            "Recipes Action Required: \(manifest.actionRequiredRecipeCount)",
            "Recipes Blocked: \(manifest.blockedRecipeCount)",
            "Recipes Disabled: \(manifest.disabledRecipeCount)",
            "Recipe Readiness Issues: \(manifest.recipeReadinessIssueCount)",
            "Recent Logs Included: \(manifest.includedLogCount)",
            "Host Architecture: \(report.hostEnvironment?.hostArchitecture ?? "unknown")",
            "Host Rosetta Path: \(report.hostEnvironment?.rosettaPathExists == true)",
            "Diagnostic Items: \(report.diagnostics?.total ?? 0)",
            "Diagnostic Runs: \(manifest.diagnosticRunCount)",
            "Failed Diagnostic Runs: \(manifest.failedDiagnosticRunCount)",
            "Timed Out Diagnostic Runs: \(manifest.timedOutDiagnosticRunCount)",
            "Diagnostic Artifacts: \(manifest.diagnosticArtifactCount ?? 0)",
            "Diagnostic Artifact Bytes: \(manifest.diagnosticArtifactBytes ?? 0)",
            "Log Issues: \(manifest.logIssueCount)",
            "Recommended Probe Commands: \(manifest.recommendedProbeCount)",
            "Recent Failure Logs: \(manifest.recentFailureLogCount)",
            "Log Recommendations: \(report.logs.recommendations.count)",
            "Total Log Bytes: \(manifest.totalLogBytes)",
            "Stale Logs: \(manifest.staleLogCount)",
            "Large Logs: \(manifest.largeLogCount)",
            "Cleanup Candidate Logs: \(manifest.cleanupCandidateLogCount)",
            "Cleanup Candidate Log Bytes: \(manifest.cleanupCandidateLogBytes)",
            "Installer Assets Cached: \(manifest.installerAssetCount)",
            "Installer Preparation Actions: \(manifest.installerPreparationActionCount)",
            "Installer Preparation Critical: \(manifest.installerPreparationCriticalCount)",
            "Installer Preparation Warnings: \(manifest.installerPreparationWarningCount)",
            "Installer Download Records: \(manifest.installerDownloadRecordCount)",
            "Installer Download Failures: \(manifest.installerDownloadFailedCount)",
            "Installer Hash Mismatches: \(manifest.installerHashMismatchCount)",
            "Orphaned Downloads: \(manifest.orphanedDownloadCount)",
            "Software Ready To Install: \(manifest.softwareReadyToInstallCount)",
            "Software Installed: \(manifest.softwareInstalledCount)",
            "Software Verified: \(manifest.softwareVerifiedCount)",
            "Software Failing: \(manifest.softwareFailingCount)",
            "Software Needs Review: \(manifest.softwareReviewCount)",
            "Software Smoke Blocked: \(manifest.softwareSmokeBlockedCount)",
            "Software Smoke Warnings: \(manifest.softwareSmokeWarningCount)",
            "Software Smoke Failures: \(manifest.softwareSmokeFailedCount)",
            "Software Smoke Verified: \(manifest.softwareSmokeVerifiedCount)",
            "Software Smoke Run Reports: \(manifest.softwareSmokeRunReportCount ?? 0)",
            "Software Smoke Superseded Skips: \(manifest.softwareSmokeRunSupersededSkipCount ?? 0)",
            "Software Smoke Uncovered Skips: \(manifest.softwareSmokeRunUncoveredSkippedCount ?? 0)",
            "Software Adaptation Tasks: \(manifest.softwareAdaptationTaskCount ?? 0)",
            "Software Adaptation Runnable Probes: \(manifest.softwareAdaptationRunnableProbeCount ?? 0)",
            "Software Adaptation Unavailable Probes: \(manifest.softwareAdaptationUnavailableProbeCount ?? 0)",
            "Software Sample Catalog: \(manifest.softwareSampleCatalogCount ?? 0)",
            "Software Sample Local Installers: \(manifest.softwareSampleCatalogLocalInstallerCount ?? 0)",
            "Software Sample Signed Recipes: \(manifest.softwareSampleCatalogSignedRecipeCount ?? 0)",
            "Software Sample Warnings: \(manifest.softwareSampleCatalogWarningCount ?? 0)",
            "Software Sample Preparation Ready: \(manifest.softwareSamplePreparationReadyCount ?? 0)",
            "Software Sample Preparation Missing Installers: \(manifest.softwareSamplePreparationMissingInstallerCount ?? 0)",
            "Software Sample Preparation Missing Recipes: \(manifest.softwareSamplePreparationMissingRecipeCount ?? 0)",
            "Software Sample Preparation Manual: \(manifest.softwareSamplePreparationManualCount ?? 0)",
            "Software Sample Matched: \(manifest.softwareSampleMatchedCount ?? 0)",
            "Software Sample Failed: \(manifest.softwareSampleFailedCount ?? 0)",
            "Software Sample Attention: \(manifest.softwareSampleAttentionCount ?? 0)",
            "Software Collection Recipes: \(manifest.softwareCollectionRecipeCount ?? 0)",
            "Software Collection Missing Recipes: \(manifest.softwareCollectionMissingRecipeCount ?? 0)",
            "Software Collection Missing Installers: \(manifest.softwareCollectionMissingInstallerCount ?? 0)",
            "Software Collection Action Required: \(manifest.softwareCollectionActionRequiredCount ?? 0)",
            "Software Collection Hash Protected: \(manifest.softwareCollectionHashProtectedCount ?? 0)",
            "Software Collection Hash Mismatches: \(manifest.softwareCollectionHashMismatchCount ?? 0)",
            "Software Collection Unprotected Downloads: \(manifest.softwareCollectionUnprotectedDownloadCount ?? 0)",
            "Software Collection History Records: \(manifest.softwareCollectionHistoryRecordCount ?? 0)",
            "Software Collection History Failures: \(manifest.softwareCollectionHistoryFailedCount ?? 0)",
            "Software Collection Acceptance: \(manifest.softwareCollectionAcceptanceState ?? "not-exported")",
            "Software Collection Acceptance Actions: \(manifest.softwareCollectionAcceptanceActionCount ?? 0)",
            "Software Collection Acceptance Blockers: \(manifest.softwareCollectionAcceptanceBlockerCount ?? 0)",
            "Software Collection Acceptance High Priority: \(manifest.softwareCollectionAcceptanceHighPriorityCount ?? 0)",
            "Software Acquisition Actions: \(manifest.softwareAcquisitionActionCount ?? 0)",
            "Software Acquisition Downloadable: \(manifest.softwareAcquisitionDownloadableCount ?? 0)",
            "Software Acquisition Missing Local Installers: \(manifest.softwareAcquisitionMissingLocalInstallerCount ?? 0)",
            "Software Acquisition Missing Recipes: \(manifest.softwareAcquisitionMissingRecipeCount ?? 0)",
            "Software Acquisition Hash Mismatches: \(manifest.softwareAcquisitionHashMismatchCount ?? 0)",
            "Install Tasks: \(manifest.installTaskCount)",
            "Failed Install Tasks: \(manifest.failedInstallTaskCount)",
            "Runtime Processes Audited: \(manifest.runtimeProcessCount)",
            "Runtime Process Findings: \(manifest.runtimeProcessFindingCount)",
            "Runtime Applications Audited: \(manifest.runtimeApplicationCount ?? 0)",
            "Runtime Application Findings: \(manifest.runtimeApplicationFindingCount ?? 0)",
            "Runtime MacWin Applications: \(manifest.runtimeMacWinApplicationCount ?? 0)",
            "Runtime Wine Applications: \(manifest.runtimeWineApplicationCount ?? 0)",
            "External EXE Opens Pending: \(manifest.externalOpenQueuePendingCount ?? 0)",
            "External EXE Opens Duplicate: \(manifest.externalOpenQueueDuplicateCount ?? 0)",
            "External EXE Queue Invalid Lines: \(manifest.externalOpenQueueInvalidLineCount ?? 0)",
            "Support Triage: \(manifest.supportTriageStatus ?? "not-exported")",
            "Support Triage Items: \(manifest.supportTriageItemCount ?? 0)",
            "Support Triage Blockers: \(manifest.supportTriageBlockerCount ?? 0)",
            "Support Triage High: \(manifest.supportTriageHighCount ?? 0)",
            "Support Triage Warnings: \(manifest.supportTriageWarningCount ?? 0)",
            "Test Assets: \(report.testAssets.presentCount)/\(report.testAssets.totalCount) present, \(report.testAssets.missingRequiredCount) missing required",
            "Test Suite Ready: \(report.testAssets.runbook?.canRunSuite == true)",
            "Test Run History: \(report.testRunHistory?.totalRunCount ?? 0) records",
            "Test Run Logs Included: \(manifest.includedTestRunLogCount)",
            "Test Coverage: \(report.testCoverage.verifiedCategoryCount)/\(report.testCoverage.categories.count) categories verified",
            "Test Coverage Missing Assets: \(report.testCoverage.missingRequiredExecutableCount)",
            "Test Coverage Failed Assets: \(report.testCoverage.failedAssetCount)",
            "Test Coverage Timed Out Assets: \(report.testCoverage.timedOutAssetCount)",
            "Test Coverage Unverified Assets: \(report.testCoverage.unverifiedAssetCount)",
            "Visual Acceptance Result: \(manifest.visualAcceptanceResultPath == nil ? "not-exported" : "exported")",
            "Visual Acceptance Artifacts: \(manifest.visualAcceptanceArtifactPaths?.count ?? 0)",
            "Launch History: \(report.launchHistory?.totalLaunchCount ?? 0) records",
            "Launch Health Entries: \(manifest.launchHealthEntryCount ?? 0)",
            "Launch Health Failed: \(manifest.failedLaunchHealthEntryCount ?? 0)",
            "Launch Health Attention: \(manifest.attentionLaunchHealthEntryCount ?? 0)",
            "Launch Health Matched Logs: \(manifest.logMatchedLaunchHealthCount ?? 0)",
            "Compatibility Repair Audited Launches: \(manifest.compatibilityRepairAuditedLaunchCount)",
            "Compatibility Repair Missing Environment: \(manifest.compatibilityRepairMissingLaunchCount)",
            "Compatibility Repair Stale Flags: \(manifest.compatibilityRepairStaleFlagLaunchCount)",
            "Compatibility Repair Findings: \(manifest.compatibilityRepairFindingCount)",
            "Test Execution Plan Items: \(manifest.testExecutionPlanItemCount)",
            "Test Execution Required Items: \(manifest.testExecutionPlanRequiredCount)",
            "Test Execution High Priority Items: \(manifest.testExecutionPlanHighPriorityCount)",
            "Activity Timeline Events: \(report.activityTimeline.eventCount)",
            "Activity Timeline Errors: \(report.activityTimeline.errorEventCount)",
            "Activity Timeline Warnings: \(report.activityTimeline.warningEventCount)",
            "",
            "Primary files:",
            "- support-bundle.json",
            "- bundle-files.json",
            "- bundle-files.csv",
            "- capability-report.json",
            "- diagnostics.csv",
            "- diagnostic-history.json",
            "- diagnostic-history.csv",
            "- diagnostic-artifacts.json",
            "- diagnostic-artifacts.csv",
            "- diagnostic-artifacts.md",
            "- host-environment.json",
            "- host-environment.csv",
            "- bottle-health.json",
            "- recipe-readiness.json",
            "- installer-assets.json",
            "- installer-assets.csv",
            "- installer-preparation.json",
            "- installer-preparation.csv",
            "- installer-preparation.md",
            "- installer-download-history.json",
            "- installer-download-history.csv",
            "- download-installers.sh",
            "- software-test-plan.json",
            "- software-test-plan.csv",
            "- software-smoke-matrix.json",
            "- software-smoke-matrix.csv",
            "- software-smoke-runs.json",
            "- software-smoke-runs.csv",
            "- software-smoke-runs.md",
            "- software-adaptation-runbook.md",
            "- software-adaptation-queue.json",
            "- software-adaptation-queue.csv",
            "- software-adaptation-queue.md",
            "- software-adaptation-queue.sh",
            "- software-sample-catalog.json",
            "- software-sample-catalog.csv",
            "- software-sample-catalog-runbook.md",
            "- software-sample-preparation.json",
            "- software-sample-preparation.csv",
            "- software-sample-preparation.md",
            "- software-sample-preparation.sh",
            "- software-sample-log-correlation.json",
            "- software-sample-log-correlation.csv",
            "- software-sample-log-correlation.md",
            "- software-collection.json",
            "- software-collection.csv",
            "- software-collection-lockfile.json",
            "- software-collection-lockfile.csv",
            "- software-collection-lockfile.md",
            "- software-collection-downloads.sh",
            "- software-collection-history.json",
            "- software-collection-history.csv",
            "- software-collection-acceptance.json",
            "- software-collection-acceptance.csv",
            "- software-collection-acceptance.md",
            "- software-collection-acceptance-runbook.sh",
            "- software-acquisition.json",
            "- software-acquisition.csv",
            "- software-acquisition.md",
            "- software-acquisition.sh",
            "- install-history.json",
            "- install-history.csv",
            "- test-assets.json",
            "- test-runbook.json",
            "- test-runbook.sh",
            "- test-run-history.json",
            "- test-run-history.csv",
            "- test-runs/test-run-log-index.json",
            "- test-runs/test-run-log-index.csv",
            "- test-runs/raw/",
            "- test-runs/redacted/",
            "- test-coverage.json",
            "- test-coverage.csv",
            "- test-execution-plan.json",
            "- test-execution-plan.csv",
            "- test-execution-plan.sh",
            "- launch-history.json",
            "- launch-history.csv",
            "- launch-replay.sh",
            "- launch-health.json",
            "- launch-health.csv",
            "- launch-health.md",
            "- compatibility-repair-audit.json",
            "- activity-timeline.json",
            "- runtime-processes.json",
            "- runtime-processes.csv",
            "- runtime-applications.json",
            "- runtime-applications.csv",
            "- runtime-applications.log",
            "- external-open-queue.json",
            "- external-open-queue.csv",
            "- external-open-queue.log",
            "- support-triage.json",
            "- support-triage.csv",
            "- support-triage.md",
            "- log-maintenance.json",
            "- log-maintenance.sh",
            "- log-issues.json",
            "- log-issues.csv",
            "- log-triage.md",
            "- log-remediation-plan.json",
            "- log-remediation-plan.csv",
            "- log-remediation-plan.md",
            "- log-remediation-runbook.sh",
            "- log-issue-probes.sh",
            "- logs/log-index.json",
            "- logs/log-index.csv",
            "- logs/raw/",
            "- logs/redacted/",
            "- engines/",
            "- bottles/",
            "- catalog/recipes.json"
        ]
        if manifest.visualAcceptanceResultPath != nil {
            lines.append("- visual-acceptance-result.json")
        }
        for artifactPath in manifest.visualAcceptanceArtifactPaths ?? [] {
            lines.append("- \(URL(fileURLWithPath: artifactPath).lastPathComponent)")
        }
        try Data(lines.joined(separator: "\n").utf8).write(to: url, options: [.atomic])
    }

    public static func softwareAdaptationRunbook(report: CapabilityReport, generatedAt: Date) -> String {
        let plan = report.softwareTestPlan
        let matrix = report.softwareSmokeMatrix
        var lines: [String] = [
            "# MacWin Software Adaptation Runbook",
            "",
            "Generated At: \(ISO8601DateFormatter().string(from: generatedAt))",
            "Root: \(plan.rootPath)",
            "",
            "## Summary",
            "",
            "- Recipes: \(plan.recipeCount)",
            "- Ready to install: \(plan.readyToInstallCount)",
            "- Installed: \(plan.installedCount)",
            "- Verified: \(plan.verifiedCount)",
            "- Failing: \(plan.failingCount)",
            "- Needs review: \(plan.reviewCount)",
            "- Smoke blocked: \(matrix.blockedCount)",
            "- Smoke warnings: \(matrix.warningCount)",
            "- Smoke failures: \(matrix.failedCount)",
            "",
            "Reference files: `software-test-plan.json`, `software-smoke-matrix.json`, `install-history.json`, `launch-history.json`, `logs/redacted/`.",
            ""
        ]

        if !matrix.nextActions.isEmpty {
            lines.append("## Next Actions")
            lines.append("")
            for action in matrix.nextActions {
                lines.append("- [\(action.severity.rawValue)] \(action.recipeId): \(action.title)")
                if !action.detail.isEmpty {
                    lines.append("  Detail: \(action.detail)")
                }
            }
            lines.append("")
        }

        let planByRecipe = Dictionary(uniqueKeysWithValues: plan.entries.map { ($0.recipeId, $0) })
        for row in matrix.rows.sorted(by: { $0.recipeId < $1.recipeId }) {
            let entry = planByRecipe[row.recipeId]
            lines.append("## \(row.name)")
            lines.append("")
            lines.append("- Recipe: \(row.recipeId)")
            lines.append("- Category: \(row.category)")
            lines.append("- Rating: \(row.compatibilityRating.rawValue)")
            lines.append("- Stage: \(row.stage.rawValue)")
            lines.append("- State: \(row.state.rawValue)")
            lines.append("- Highest severity: \(row.highestSeverity.rawValue)")
            lines.append("- Next action: \(row.nextAction)")
            if let path = row.latestLogPath {
                lines.append("- Latest log: \(path)")
            }
            if let path = row.latestLaunchLogPath {
                lines.append("- Latest launch log: \(path)")
            }
            if let repairState = row.latestRepairState {
                lines.append("- Compatibility repair: \(repairState.rawValue)")
            }
            if let entry {
                if let latestInstallState = entry.latestInstallState {
                    lines.append("- Latest install: \(latestInstallState.rawValue)")
                }
                if let latestLaunchState = entry.latestLaunchState {
                    lines.append("- Latest launch: \(latestLaunchState.rawValue)")
                }
                if let exitCode = entry.latestLaunchExitCode {
                    lines.append("- Latest launch exit code: \(exitCode)")
                }
                if !entry.blockers.isEmpty {
                    lines.append("- Blockers: \(entry.blockers.joined(separator: ", "))")
                }
                if !entry.probableIssueIds.isEmpty {
                    lines.append("- Probable issues: \(entry.probableIssueIds.joined(separator: ", "))")
                }
            }
            lines.append("")
            lines.append("| Check | State | Detail |")
            lines.append("| --- | --- | --- |")
            for item in row.checklist {
                lines.append("| \(escapeMarkdownCell(item.label)) | \(item.state.rawValue) | \(escapeMarkdownCell(item.detail)) |")
            }
            lines.append("")
        }

        return lines.joined(separator: "\n") + "\n"
    }

    private static func escapeMarkdownCell(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "|", with: "\\|")
            .replacingOccurrences(of: "\n", with: " ")
    }

    private static func emptyRecommendedProbeScript(recommendedProbeIds: [String]) -> String {
        let listed = recommendedProbeIds.isEmpty ? "none" : recommendedProbeIds.joined(separator: " ")
        return """
        #!/usr/bin/env bash
        set -euo pipefail
        echo "No MacWin test runbook is available in this support bundle."
        echo "Recommended probe ids: \(listed)"

        """
    }

    private static func emptyTestExecutionPlanScript() -> String {
        """
        #!/usr/bin/env bash
        set -euo pipefail
        echo "No MacWin test execution plan is available in this support bundle."

        """
    }

    private static func emptyLaunchReplayScript() -> String {
        """
        #!/usr/bin/env bash
        set -euo pipefail
        echo "No MacWin launch history is available in this support bundle."

        """
    }

    private static func safeFileName(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        let mapped = value.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let name = String(mapped).split(separator: "-").joined(separator: "-")
        return name.isEmpty ? "item" : name
    }

    private static func redactedLogData(file url: URL, macWinRoot: String) throws -> (data: Data, count: Int) {
        let data = try Data(contentsOf: url)
        let text = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1)
            ?? "<binary log omitted>\n"
        let redacted = redactLogText(text, macWinRoot: macWinRoot)
        return (Data(redacted.text.utf8), redacted.count)
    }

    public static func redactLogText(_ text: String, macWinRoot: String? = nil) -> (text: String, count: Int) {
        var output = text
        var count = 0

        func replace(pattern: String, with template: String, options: NSRegularExpression.Options = []) {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }
            let range = NSRange(output.startIndex..<output.endIndex, in: output)
            count += regex.numberOfMatches(in: output, range: range)
            output = regex.stringByReplacingMatches(in: output, range: range, withTemplate: template)
        }

        if let macWinRoot, !macWinRoot.isEmpty {
            while output.contains(macWinRoot) {
                output = output.replacingOccurrences(of: macWinRoot, with: "<MacWinRoot>")
                count += 1
            }
        }

        replace(pattern: #"/Users/[^/\s]+"#, with: #"/Users/<user>"#)
        replace(pattern: #"C:\\users\\[^\\\s]+"#, with: #"C:\\users\\<user>"#, options: [.caseInsensitive])
        replace(pattern: #"C:/users/[^/\s]+"#, with: #"C:/users/<user>"#, options: [.caseInsensitive])
        replace(pattern: #"(?im)^(\s*(?:Set-Cookie|Cookie|Authorization|Proxy-Authorization):\s*).*$"#, with: #"$1<redacted>"#)
        replace(
            pattern: #"(?i)\b(ALL_PROXY|HTTP_PROXY|HTTPS_PROXY|NO_PROXY|all_proxy|http_proxy|https_proxy|no_proxy)=\S+"#,
            with: #"$1=<redacted>"#
        )
        replace(
            pattern: #"(?i)\b(access_token|refresh_token|token|auth|ticket|session|cookie|device_fp|devicefp|sign|stoken|ltoken|mid)=([^&\s]+)"#,
            with: #"$1=<redacted>"#
        )
        replace(pattern: #"(?i)\bBearer\s+[A-Za-z0-9._~+/=-]+"#, with: #"Bearer <redacted>"#)
        return (output, count)
    }

    private static func fileTimestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter.string(from: date)
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "")
    }
}
