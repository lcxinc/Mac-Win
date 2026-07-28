import Foundation

public struct SoftwareCollectionBundleManifest: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var generatedAt: Date
    public var bundlePath: String
    public var rootPath: String
    public var collectionPath: String
    public var collectionCSVPath: String
    public var lockfilePath: String
    public var lockfileCSVPath: String
    public var lockfileMarkdownPath: String
    public var downloadScriptPath: String
    public var historyPath: String
    public var historyCSVPath: String
    public var acceptancePath: String
    public var acceptanceCSVPath: String
    public var acceptanceMarkdownPath: String
    public var acceptanceRunbookPath: String?
    public var softwareAcquisitionPath: String?
    public var softwareAcquisitionCSVPath: String?
    public var softwareAcquisitionMarkdownPath: String?
    public var softwareAcquisitionScriptPath: String?
    public var softwareSamplePreparationPath: String?
    public var softwareSamplePreparationCSVPath: String?
    public var softwareSamplePreparationMarkdownPath: String?
    public var softwareSamplePreparationScriptPath: String?
    public var launchHealthPath: String?
    public var launchHealthCSVPath: String?
    public var launchHealthMarkdownPath: String?
    public var externalOpenQueueReportPath: String?
    public var externalOpenQueueCSVPath: String?
    public var externalOpenQueueLogPath: String?
    public var supportTriagePath: String?
    public var supportTriageCSVPath: String?
    public var supportTriageMarkdownPath: String?
    public var logIssueCSVPath: String
    public var logTriageMarkdownPath: String
    public var readmePath: String
    public var acceptanceState: String
    public var acceptanceActionCount: Int
    public var acceptanceBlockerCount: Int
    public var acceptanceHighPriorityCount: Int
    public var collectionCount: Int
    public var recipeCount: Int
    public var missingRecipeCount: Int
    public var downloadableRecipeCount: Int
    public var cachedInstallerCount: Int
    public var missingInstallerCount: Int
    public var hashProtectedCount: Int
    public var hashMismatchCount: Int
    public var unprotectedDownloadCount: Int
    public var verifiedRecipeCount: Int
    public var actionRequiredCount: Int
    public var historyRecordCount: Int
    public var historyFailureCount: Int
    public var logsAnalyzed: Int
    public var failedLogCount: Int
    public var attentionLogCount: Int
    public var topIssueCount: Int
    public var softwareAcquisitionActionCount: Int?
    public var softwareAcquisitionDownloadableCount: Int?
    public var softwareAcquisitionMissingLocalInstallerCount: Int?
    public var softwareAcquisitionMissingRecipeCount: Int?
    public var softwareAcquisitionHashMismatchCount: Int?
    public var softwareSamplePreparationReadyCount: Int?
    public var softwareSamplePreparationMissingInstallerCount: Int?
    public var softwareSamplePreparationMissingRecipeCount: Int?
    public var softwareSamplePreparationManualCount: Int?
    public var softwareSamplePreparationCachedInstallerCount: Int?
    public var launchHealthEntryCount: Int?
    public var failedLaunchHealthEntryCount: Int?
    public var attentionLaunchHealthEntryCount: Int?
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
        bundlePath: String,
        rootPath: String,
        collectionPath: String,
        collectionCSVPath: String,
        lockfilePath: String,
        lockfileCSVPath: String,
        lockfileMarkdownPath: String,
        downloadScriptPath: String,
        historyPath: String,
        historyCSVPath: String,
        acceptancePath: String,
        acceptanceCSVPath: String,
        acceptanceMarkdownPath: String,
        acceptanceRunbookPath: String,
        softwareAcquisitionPath: String? = nil,
        softwareAcquisitionCSVPath: String? = nil,
        softwareAcquisitionMarkdownPath: String? = nil,
        softwareAcquisitionScriptPath: String? = nil,
        softwareSamplePreparationPath: String? = nil,
        softwareSamplePreparationCSVPath: String? = nil,
        softwareSamplePreparationMarkdownPath: String? = nil,
        softwareSamplePreparationScriptPath: String? = nil,
        launchHealthPath: String? = nil,
        launchHealthCSVPath: String? = nil,
        launchHealthMarkdownPath: String? = nil,
        externalOpenQueueReportPath: String? = nil,
        externalOpenQueueCSVPath: String? = nil,
        externalOpenQueueLogPath: String? = nil,
        supportTriagePath: String? = nil,
        supportTriageCSVPath: String? = nil,
        supportTriageMarkdownPath: String? = nil,
        logIssueCSVPath: String,
        logTriageMarkdownPath: String,
        readmePath: String,
        collection: SoftwareCollectionReport,
        history: SoftwareCollectionHistoryReport,
        acceptance: SoftwareCollectionAcceptanceReport,
        lockfile: SoftwareCollectionLockfile,
        logIssues: LogIssueReport,
        softwareAcquisition: SoftwareAcquisitionReport? = nil,
        softwareSamplePreparation: SoftwareSamplePreparationReport? = nil,
        launchHealth: LaunchHealthReport? = nil,
        externalOpenQueue: ExternalExecutableOpenQueueReport? = nil,
        supportTriage: SupportTriageReport? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.generatedAt = generatedAt
        self.bundlePath = bundlePath
        self.rootPath = rootPath
        self.collectionPath = collectionPath
        self.collectionCSVPath = collectionCSVPath
        self.lockfilePath = lockfilePath
        self.lockfileCSVPath = lockfileCSVPath
        self.lockfileMarkdownPath = lockfileMarkdownPath
        self.downloadScriptPath = downloadScriptPath
        self.historyPath = historyPath
        self.historyCSVPath = historyCSVPath
        self.acceptancePath = acceptancePath
        self.acceptanceCSVPath = acceptanceCSVPath
        self.acceptanceMarkdownPath = acceptanceMarkdownPath
        self.acceptanceRunbookPath = acceptanceRunbookPath
        self.softwareAcquisitionPath = softwareAcquisitionPath
        self.softwareAcquisitionCSVPath = softwareAcquisitionCSVPath
        self.softwareAcquisitionMarkdownPath = softwareAcquisitionMarkdownPath
        self.softwareAcquisitionScriptPath = softwareAcquisitionScriptPath
        self.softwareSamplePreparationPath = softwareSamplePreparationPath
        self.softwareSamplePreparationCSVPath = softwareSamplePreparationCSVPath
        self.softwareSamplePreparationMarkdownPath = softwareSamplePreparationMarkdownPath
        self.softwareSamplePreparationScriptPath = softwareSamplePreparationScriptPath
        self.launchHealthPath = launchHealthPath
        self.launchHealthCSVPath = launchHealthCSVPath
        self.launchHealthMarkdownPath = launchHealthMarkdownPath
        self.externalOpenQueueReportPath = externalOpenQueueReportPath
        self.externalOpenQueueCSVPath = externalOpenQueueCSVPath
        self.externalOpenQueueLogPath = externalOpenQueueLogPath
        self.supportTriagePath = supportTriagePath
        self.supportTriageCSVPath = supportTriageCSVPath
        self.supportTriageMarkdownPath = supportTriageMarkdownPath
        self.logIssueCSVPath = logIssueCSVPath
        self.logTriageMarkdownPath = logTriageMarkdownPath
        self.readmePath = readmePath
        self.acceptanceState = acceptance.state.rawValue
        self.acceptanceActionCount = acceptance.actionCount
        self.acceptanceBlockerCount = acceptance.blockerCount
        self.acceptanceHighPriorityCount = acceptance.highPriorityCount
        self.collectionCount = collection.collectionCount
        self.recipeCount = collection.recipeCount
        self.missingRecipeCount = collection.missingRecipeCount
        self.downloadableRecipeCount = collection.downloadableRecipeCount
        self.cachedInstallerCount = collection.cachedInstallerCount
        self.missingInstallerCount = collection.missingInstallerCount
        self.hashProtectedCount = lockfile.hashProtectedCount
        self.hashMismatchCount = lockfile.hashMismatchCount
        self.unprotectedDownloadCount = lockfile.unprotectedDownloadCount
        self.verifiedRecipeCount = collection.verifiedRecipeCount
        self.actionRequiredCount = collection.actionRequiredCount
        self.historyRecordCount = history.totalRecordCount
        self.historyFailureCount = history.failedCount
        self.logsAnalyzed = logIssues.logsAnalyzed
        self.failedLogCount = logIssues.failedLogCount
        self.attentionLogCount = logIssues.attentionLogCount
        self.topIssueCount = logIssues.topIssues.count
        self.softwareAcquisitionActionCount = softwareAcquisition?.actionCount
        self.softwareAcquisitionDownloadableCount = softwareAcquisition?.downloadableCount
        self.softwareAcquisitionMissingLocalInstallerCount = softwareAcquisition?.missingLocalInstallerCount
        self.softwareAcquisitionMissingRecipeCount = softwareAcquisition?.missingRecipeCount
        self.softwareAcquisitionHashMismatchCount = softwareAcquisition?.hashMismatchCount
        self.softwareSamplePreparationReadyCount = softwareSamplePreparation?.readyCount
        self.softwareSamplePreparationMissingInstallerCount = softwareSamplePreparation?.missingInstallerCount
        self.softwareSamplePreparationMissingRecipeCount = softwareSamplePreparation?.missingRecipeCount
        self.softwareSamplePreparationManualCount = softwareSamplePreparation?.manualCount
        self.softwareSamplePreparationCachedInstallerCount = softwareSamplePreparation?.cachedInstallerCount
        self.launchHealthEntryCount = launchHealth?.entryCount
        self.failedLaunchHealthEntryCount = launchHealth?.failedEntryCount
        self.attentionLaunchHealthEntryCount = launchHealth?.attentionEntryCount
        self.externalOpenQueuePendingCount = externalOpenQueue?.pendingCount
        self.externalOpenQueueDuplicateCount = externalOpenQueue?.duplicatePendingCount
        self.externalOpenQueueInvalidLineCount = externalOpenQueue?.invalidLineCount
        self.supportTriageStatus = supportTriage?.status.rawValue
        self.supportTriageItemCount = supportTriage?.itemCount
        self.supportTriageBlockerCount = supportTriage?.blockerCount
        self.supportTriageHighCount = supportTriage?.highCount
        self.supportTriageWarningCount = supportTriage?.warningCount
    }
}

public struct SoftwareCollectionBundleResult: Codable, Equatable, Sendable {
    public var bundleURL: URL
    public var manifest: SoftwareCollectionBundleManifest
}

public struct SoftwareCollectionBundleService {
    public var paths: MacWinPaths
    public var fileManager: FileManager

    public init(paths: MacWinPaths = MacWinPaths(), fileManager: FileManager = .default) {
        self.paths = paths
        self.fileManager = fileManager
    }

    public func exportBundle(
        collection: SoftwareCollectionReport,
        history: SoftwareCollectionHistoryReport,
        logIssues: LogIssueReport,
        smokeMatrix: SoftwareSmokeMatrixReport? = nil,
        testExecutionPlan: TestExecutionPlan? = nil,
        softwareAcquisition: SoftwareAcquisitionReport? = nil,
        softwareSamplePreparation: SoftwareSamplePreparationReport? = nil,
        launchHealth: LaunchHealthReport? = nil,
        externalOpenQueue: ExternalExecutableOpenQueueReport? = nil,
        supportTriage: SupportTriageReport? = nil,
        generatedAt: Date = Date()
    ) throws -> SoftwareCollectionBundleResult {
        try paths.ensureBaseDirectories(fileManager: fileManager)
        let bundleURL = paths.logsDirectory
            .appendingPathComponent("SoftwareCollectionBundles", isDirectory: true)
            .appendingPathComponent("software-collection-\(Self.fileTimestamp(generatedAt))", isDirectory: true)
        if fileManager.fileExists(atPath: bundleURL.path) {
            try fileManager.removeItem(at: bundleURL)
        }
        try fileManager.createDirectory(at: bundleURL, withIntermediateDirectories: true)

        let store = JSONStore(fileManager: fileManager)
        let collectionURL = bundleURL.appendingPathComponent("software-collection.json")
        try store.save(collection, to: collectionURL)
        let collectionCSVURL = bundleURL.appendingPathComponent("software-collection.csv")
        try Data(SoftwareCollectionService.csv(report: collection).utf8).write(to: collectionCSVURL, options: [.atomic])
        let lockfile = SoftwareCollectionService.lockfile(report: collection)
        let lockfileURL = bundleURL.appendingPathComponent("software-collection-lockfile.json")
        try store.save(lockfile, to: lockfileURL)
        let lockfileCSVURL = bundleURL.appendingPathComponent("software-collection-lockfile.csv")
        try Data(SoftwareCollectionLockfile.csv(lockfile: lockfile).utf8).write(to: lockfileCSVURL, options: [.atomic])
        let lockfileMarkdownURL = bundleURL.appendingPathComponent("software-collection-lockfile.md")
        try Data(SoftwareCollectionLockfile.markdown(lockfile: lockfile).utf8).write(to: lockfileMarkdownURL, options: [.atomic])

        let downloadScriptURL = bundleURL.appendingPathComponent("software-collection-downloads.sh")
        try Data(SoftwareCollectionService.downloadScript(report: collection).utf8).write(to: downloadScriptURL, options: [.atomic])
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: downloadScriptURL.path)

        let historyURL = bundleURL.appendingPathComponent("software-collection-history.json")
        try store.save(history, to: historyURL)
        let historyCSVURL = bundleURL.appendingPathComponent("software-collection-history.csv")
        try Data(SoftwareCollectionHistoryService.csv(report: history).utf8).write(to: historyCSVURL, options: [.atomic])

        let acceptance = SoftwareCollectionAcceptanceService().report(
            collection: collection,
            smokeMatrix: smokeMatrix,
            testExecutionPlan: testExecutionPlan,
            logIssues: logIssues,
            generatedAt: generatedAt
        )
        let acceptanceURL = bundleURL.appendingPathComponent("acceptance.json")
        try store.save(acceptance, to: acceptanceURL)
        let acceptanceCSVURL = bundleURL.appendingPathComponent("acceptance.csv")
        try Data(SoftwareCollectionAcceptanceReport.csv(report: acceptance).utf8).write(to: acceptanceCSVURL, options: [.atomic])
        let acceptanceMarkdownURL = bundleURL.appendingPathComponent("acceptance.md")
        try Data(SoftwareCollectionAcceptanceReport.markdown(report: acceptance).utf8).write(to: acceptanceMarkdownURL, options: [.atomic])
        let acceptanceRunbookURL = bundleURL.appendingPathComponent("acceptance-runbook.sh")
        try Data(SoftwareCollectionAcceptanceReport.runbookScript(report: acceptance).utf8).write(to: acceptanceRunbookURL, options: [.atomic])
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: acceptanceRunbookURL.path)

        let softwareAcquisitionURLs = try exportSoftwareAcquisitionIfPresent(softwareAcquisition, to: bundleURL, store: store)
        let softwareSamplePreparationURLs = try exportSoftwareSamplePreparationIfPresent(
            softwareSamplePreparation,
            to: bundleURL,
            store: store
        )
        let launchHealthURLs = try exportLaunchHealthIfPresent(launchHealth, to: bundleURL, store: store)
        let externalOpenQueueURLs = try exportExternalOpenQueueIfPresent(externalOpenQueue, to: bundleURL, store: store)
        let supportTriageURLs = try exportSupportTriageIfPresent(supportTriage, to: bundleURL, store: store)

        let logIssueCSVURL = bundleURL.appendingPathComponent("log-issues.csv")
        try Data(LogIssueReport.csv(report: logIssues).utf8).write(to: logIssueCSVURL, options: [.atomic])
        let logTriageURL = bundleURL.appendingPathComponent("log-triage.md")
        try Data(LogService.triageMarkdown(report: logIssues, generatedAt: generatedAt).utf8).write(to: logTriageURL, options: [.atomic])

        let readmeURL = bundleURL.appendingPathComponent("README.md")
        try Data(Self.readme(
            collection: collection,
            history: history,
            acceptance: acceptance,
            logIssues: logIssues,
            softwareAcquisition: softwareAcquisition,
            softwareSamplePreparation: softwareSamplePreparation,
            launchHealth: launchHealth,
            externalOpenQueue: externalOpenQueue,
            supportTriage: supportTriage,
            generatedAt: generatedAt
        ).utf8).write(to: readmeURL, options: [.atomic])

        let manifest = SoftwareCollectionBundleManifest(
            generatedAt: generatedAt,
            bundlePath: bundleURL.path,
            rootPath: paths.root.path,
            collectionPath: collectionURL.path,
            collectionCSVPath: collectionCSVURL.path,
            lockfilePath: lockfileURL.path,
            lockfileCSVPath: lockfileCSVURL.path,
            lockfileMarkdownPath: lockfileMarkdownURL.path,
            downloadScriptPath: downloadScriptURL.path,
            historyPath: historyURL.path,
            historyCSVPath: historyCSVURL.path,
            acceptancePath: acceptanceURL.path,
            acceptanceCSVPath: acceptanceCSVURL.path,
            acceptanceMarkdownPath: acceptanceMarkdownURL.path,
            acceptanceRunbookPath: acceptanceRunbookURL.path,
            softwareAcquisitionPath: softwareAcquisitionURLs?.json.path,
            softwareAcquisitionCSVPath: softwareAcquisitionURLs?.csv.path,
            softwareAcquisitionMarkdownPath: softwareAcquisitionURLs?.markdown.path,
            softwareAcquisitionScriptPath: softwareAcquisitionURLs?.script.path,
            softwareSamplePreparationPath: softwareSamplePreparationURLs?.json.path,
            softwareSamplePreparationCSVPath: softwareSamplePreparationURLs?.csv.path,
            softwareSamplePreparationMarkdownPath: softwareSamplePreparationURLs?.markdown.path,
            softwareSamplePreparationScriptPath: softwareSamplePreparationURLs?.script.path,
            launchHealthPath: launchHealthURLs?.json.path,
            launchHealthCSVPath: launchHealthURLs?.csv.path,
            launchHealthMarkdownPath: launchHealthURLs?.markdown.path,
            externalOpenQueueReportPath: externalOpenQueueURLs?.json.path,
            externalOpenQueueCSVPath: externalOpenQueueURLs?.csv.path,
            externalOpenQueueLogPath: externalOpenQueueURLs?.log.path,
            supportTriagePath: supportTriageURLs?.json.path,
            supportTriageCSVPath: supportTriageURLs?.csv.path,
            supportTriageMarkdownPath: supportTriageURLs?.markdown.path,
            logIssueCSVPath: logIssueCSVURL.path,
            logTriageMarkdownPath: logTriageURL.path,
            readmePath: readmeURL.path,
            collection: collection,
            history: history,
            acceptance: acceptance,
            lockfile: lockfile,
            logIssues: logIssues,
            softwareAcquisition: softwareAcquisition,
            softwareSamplePreparation: softwareSamplePreparation,
            launchHealth: launchHealth,
            externalOpenQueue: externalOpenQueue,
            supportTriage: supportTriage
        )
        try store.save(manifest, to: bundleURL.appendingPathComponent("manifest.json"))
        return SoftwareCollectionBundleResult(bundleURL: bundleURL, manifest: manifest)
    }

    private func exportSoftwareSamplePreparationIfPresent(
        _ report: SoftwareSamplePreparationReport?,
        to bundleURL: URL,
        store: JSONStore
    ) throws -> (json: URL, csv: URL, markdown: URL, script: URL)? {
        guard let report else { return nil }
        let jsonURL = bundleURL.appendingPathComponent("software-sample-preparation.json")
        try store.save(report, to: jsonURL)
        let csvURL = bundleURL.appendingPathComponent("software-sample-preparation.csv")
        try Data(SoftwareSampleCatalogService.preparationCSV(report: report).utf8).write(to: csvURL, options: [.atomic])
        let markdownURL = bundleURL.appendingPathComponent("software-sample-preparation.md")
        try Data(SoftwareSampleCatalogService.preparationMarkdown(report: report).utf8).write(to: markdownURL, options: [.atomic])
        let scriptURL = bundleURL.appendingPathComponent("software-sample-preparation.sh")
        try Data(SoftwareSampleCatalogService.preparationShellScript(report: report).utf8).write(to: scriptURL, options: [.atomic])
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
        return (jsonURL, csvURL, markdownURL, scriptURL)
    }

    private func exportSoftwareAcquisitionIfPresent(
        _ report: SoftwareAcquisitionReport?,
        to bundleURL: URL,
        store: JSONStore
    ) throws -> (json: URL, csv: URL, markdown: URL, script: URL)? {
        guard let report else { return nil }
        let jsonURL = bundleURL.appendingPathComponent("software-acquisition.json")
        try store.save(report, to: jsonURL)
        let csvURL = bundleURL.appendingPathComponent("software-acquisition.csv")
        try Data(SoftwareAcquisitionReport.csv(report: report).utf8).write(to: csvURL, options: [.atomic])
        let markdownURL = bundleURL.appendingPathComponent("software-acquisition.md")
        try Data(SoftwareAcquisitionReport.markdown(report: report).utf8).write(to: markdownURL, options: [.atomic])
        let scriptURL = bundleURL.appendingPathComponent("software-acquisition.sh")
        try Data(SoftwareAcquisitionReport.shellScript(report: report).utf8).write(to: scriptURL, options: [.atomic])
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
        return (jsonURL, csvURL, markdownURL, scriptURL)
    }

    private func exportLaunchHealthIfPresent(
        _ report: LaunchHealthReport?,
        to bundleURL: URL,
        store: JSONStore
    ) throws -> (json: URL, csv: URL, markdown: URL)? {
        guard let report else { return nil }
        let jsonURL = bundleURL.appendingPathComponent("launch-health.json")
        try store.save(report, to: jsonURL)
        let csvURL = bundleURL.appendingPathComponent("launch-health.csv")
        try Data(LaunchHealthReport.csv(report: report).utf8).write(to: csvURL, options: [.atomic])
        let markdownURL = bundleURL.appendingPathComponent("launch-health.md")
        try Data(LaunchHealthReport.markdown(report: report).utf8).write(to: markdownURL, options: [.atomic])
        return (jsonURL, csvURL, markdownURL)
    }

    private func exportExternalOpenQueueIfPresent(
        _ report: ExternalExecutableOpenQueueReport?,
        to bundleURL: URL,
        store: JSONStore
    ) throws -> (json: URL, csv: URL, log: URL)? {
        guard let report else { return nil }
        let jsonURL = bundleURL.appendingPathComponent("external-open-queue.json")
        try store.save(report, to: jsonURL)
        let csvURL = bundleURL.appendingPathComponent("external-open-queue.csv")
        try Data(ExternalExecutableOpenQueueService.csv(report: report).utf8).write(to: csvURL, options: [.atomic])
        let logURL = bundleURL.appendingPathComponent("external-open-queue.log")
        try Data(ExternalExecutableOpenQueueService.diagnosticLogText(report: report).utf8).write(to: logURL, options: [.atomic])
        return (jsonURL, csvURL, logURL)
    }

    private func exportSupportTriageIfPresent(
        _ report: SupportTriageReport?,
        to bundleURL: URL,
        store: JSONStore
    ) throws -> (json: URL, csv: URL, markdown: URL)? {
        guard let report else { return nil }
        let jsonURL = bundleURL.appendingPathComponent("support-triage.json")
        try store.save(report, to: jsonURL)
        let csvURL = bundleURL.appendingPathComponent("support-triage.csv")
        try Data(SupportTriageReport.csv(report: report).utf8).write(to: csvURL, options: [.atomic])
        let markdownURL = bundleURL.appendingPathComponent("support-triage.md")
        try Data(SupportTriageReport.markdown(report: report).utf8).write(to: markdownURL, options: [.atomic])
        return (jsonURL, csvURL, markdownURL)
    }

    public static func readme(
        collection: SoftwareCollectionReport,
        history: SoftwareCollectionHistoryReport,
        acceptance: SoftwareCollectionAcceptanceReport,
        logIssues: LogIssueReport,
        softwareAcquisition: SoftwareAcquisitionReport? = nil,
        softwareSamplePreparation: SoftwareSamplePreparationReport? = nil,
        launchHealth: LaunchHealthReport? = nil,
        externalOpenQueue: ExternalExecutableOpenQueueReport? = nil,
        supportTriage: SupportTriageReport? = nil,
        generatedAt: Date
    ) -> String {
        let formatter = ISO8601DateFormatter()
        var lines = [
            "# MacWin Test Software Collection",
            "",
            "- Generated: \(formatter.string(from: generatedAt))",
            "- Collections: \(collection.collectionCount)",
            "- Recipes: \(collection.recipeCount)",
            "- Missing recipes: \(collection.missingRecipeCount)",
            "- Downloadable recipes: \(collection.downloadableRecipeCount)",
            "- Cached installers: \(collection.cachedInstallerCount)",
            "- Missing installers: \(collection.missingInstallerCount)",
            "- Verified recipes: \(collection.verifiedRecipeCount)",
            "- Action required: \(collection.actionRequiredCount)",
            "- Collection history records: \(history.totalRecordCount)",
            "- Collection history failures: \(history.failedCount)",
            "- Acceptance state: \(acceptance.state.rawValue)",
            "- Acceptance actions: \(acceptance.actionCount)",
            "- Acceptance blockers: \(acceptance.blockerCount)",
            "- Logs analyzed: \(logIssues.logsAnalyzed)",
            "- Failed logs: \(logIssues.failedLogCount)",
            "- Attention logs: \(logIssues.attentionLogCount)",
            "- Top log issues: \(logIssues.topIssues.count)",
            "- Software acquisition actions: \(softwareAcquisition?.actionCount ?? 0)",
            "- Software samples ready: \(softwareSamplePreparation?.readyCount ?? 0)",
            "- Software samples missing installers: \(softwareSamplePreparation?.missingInstallerCount ?? 0)",
            "- Software samples missing recipes: \(softwareSamplePreparation?.missingRecipeCount ?? 0)",
            "- Launch health entries: \(launchHealth?.entryCount ?? 0)",
            "- External EXE opens pending: \(externalOpenQueue?.pendingCount ?? 0)",
            "- Support triage: \(supportTriage?.status.rawValue ?? "not-exported")",
            "- Support triage items: \(supportTriage?.itemCount ?? 0)",
            "",
            "## Files",
            "",
            "- manifest.json",
            "- software-collection.json",
            "- software-collection.csv",
            "- software-collection-lockfile.json",
            "- software-collection-lockfile.csv",
            "- software-collection-lockfile.md",
            "- software-collection-downloads.sh",
            "- software-collection-history.json",
            "- software-collection-history.csv",
            "- acceptance.json",
            "- acceptance.csv",
            "- acceptance.md",
            "- acceptance-runbook.sh",
            "- software-acquisition.json",
            "- software-acquisition.csv",
            "- software-acquisition.md",
            "- software-acquisition.sh",
            "- software-sample-preparation.json",
            "- software-sample-preparation.csv",
            "- software-sample-preparation.md",
            "- software-sample-preparation.sh",
            "- launch-health.json",
            "- launch-health.csv",
            "- launch-health.md",
            "- external-open-queue.json",
            "- external-open-queue.csv",
            "- external-open-queue.log",
            "- support-triage.json",
            "- support-triage.csv",
            "- support-triage.md",
            "- log-issues.csv",
            "- log-triage.md",
            "",
            "## Download Flow",
            "",
            "Run `software-collection-downloads.sh` to cache missing downloadable installers into the MacWin Downloads directory. The script verifies SHA-256 when the recipe provides a trusted hash.",
            "",
            "## Acceptance Runbook",
            "",
            "Run `acceptance-runbook.sh` to execute the exported acceptance actions in priority order. It automatically downloads/verifies missing installers and runs probe commands; interactive install and log-review actions are printed as notes.",
            "",
            "## Next Actions",
            ""
        ]

        if acceptance.actions.isEmpty {
            lines.append("- No collection blockers were detected in this export.")
        } else {
            for action in acceptance.actions.prefix(12) {
                lines.append("- [\(action.severity.rawValue)] \(action.title)")
            }
        }

        lines.append("")
        return lines.joined(separator: "\n")
    }

    private static func fileTimestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter.string(from: date).replacingOccurrences(of: ":", with: "")
    }
}
