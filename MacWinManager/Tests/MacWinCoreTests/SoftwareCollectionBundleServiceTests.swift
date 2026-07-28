import Foundation
import Testing
@testable import MacWinCore

@Suite("Software collection bundle service")
struct SoftwareCollectionBundleServiceTests {
    @Test("Bundle export writes collection downloads history logs and manifest")
    func bundleExportWritesCollectionDownloadsHistoryLogsAndManifest() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinCollectionBundleTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = MacWinPaths(root: root)
        let generatedAt = Date(timeIntervalSince1970: 1_000)
        let collection = Self.collection(root: root.path)
        let history = SoftwareCollectionHistoryReport(
            rootPath: root.path,
            recordsPath: root.appendingPathComponent("Logs/SoftwareCollectionRecords").path,
            records: [
                SoftwareCollectionActionRecord(
                    id: "record-1",
                    action: .exportCSV,
                    state: .succeeded,
                    startedAt: Date(timeIntervalSince1970: 900),
                    endedAt: Date(timeIntervalSince1970: 901),
                    collectionCount: collection.collectionCount,
                    recipeCount: collection.recipeCount,
                    missingRecipeCount: collection.missingRecipeCount,
                    missingInstallerCount: collection.missingInstallerCount,
                    actionRequiredCount: collection.actionRequiredCount,
                    recipeIds: ["steam"],
                    outputPath: root.appendingPathComponent("Logs/software-collection.csv").path
                )
            ]
        )
        let logIssues = LogIssueReport(
            logs: [
                LogFileItem(
                    name: "steam.log",
                    url: root.appendingPathComponent("Logs/steam.log"),
                    modifiedAt: Date(timeIntervalSince1970: 950),
                    byteCount: 128,
                    summary: LogSummary(errorCount: 1, hints: [.cefRenderingIssue])
                )
            ],
            topIssues: [
                LogIssueTrend(
                    id: "cef-rendering",
                    severity: "high",
                    title: "CEF rendering issue",
                    detail: "Steam WebView rendered blank.",
                    count: 1,
                    relatedHints: ["cefRenderingIssue"],
                    affectedLogNames: ["steam.log"],
                    recommendedActions: ["Relaunch with software WebView preset."],
                    probeAssetIds: ["window-input"]
                )
            ],
            recentFailures: []
        )
        let softwareAcquisition = SoftwareAcquisitionReport(
            generatedAt: generatedAt,
            rootPath: root.path,
            downloadsPath: paths.downloadsDirectory.path,
            entries: [
                SoftwareAcquisitionEntry(
                    id: "collection-steam",
                    source: .collectionRecipe,
                    state: .downloadable,
                    name: "Steam",
                    recipeId: "steam",
                    fileNames: ["SteamSetup.exe"],
                    sourceURL: "https://example.test/SteamSetup.exe",
                    expectedSha256: String(repeating: "b", count: 64),
                    action: "Download the installer into the MacWin Downloads cache.",
                    recommendedProbeIds: ["window-input"]
                )
            ]
        )
        let samplePreparation = SoftwareSamplePreparationReport(
            generatedAt: generatedAt,
            rootPath: root.path,
            downloadsPath: paths.downloadsDirectory.path,
            entries: [
                SoftwareSamplePreparationEntry(
                    sampleId: "steam",
                    name: "Steam",
                    installSource: .signedRecipe,
                    catalogRecipeId: "steam",
                    catalogBacked: true,
                    status: .ready,
                    installerFileNames: ["SteamSetup.exe"],
                    cachedInstallerPaths: [root.appendingPathComponent("Downloads/SteamSetup.exe").path],
                    requiredAction: "Use the cached local installer from Downloads.",
                    recommendedProbeIds: ["window-input"],
                    warnings: []
                ),
                SoftwareSamplePreparationEntry(
                    sampleId: "itch",
                    name: "itch.io",
                    installSource: .localInstaller,
                    catalogRecipeId: nil,
                    catalogBacked: false,
                    status: .missingInstaller,
                    installerFileNames: ["itch-setup.exe"],
                    cachedInstallerPaths: [],
                    requiredAction: "Place one matching local installer in the MacWin Downloads directory.",
                    recommendedProbeIds: ["text-rendering"],
                    warnings: ["Use local installers only."]
                )
            ]
        )
        let launchHealth = LaunchHealthReport(
            generatedAt: generatedAt,
            rootPath: root.path,
            logMatchedLaunchCount: 1,
            entries: [
                LaunchHealthEntry(
                    id: "steam",
                    status: .failed,
                    displayName: "Steam",
                    launchCount: 1,
                    completedLaunchCount: 1,
                    failedToLaunchCount: 0,
                    runningLaunchCount: 0,
                    nonZeroExitCount: 1,
                    logCount: 1,
                    failedLogCount: 1,
                    attentionLogCount: 0,
                    passedLogCount: 0,
                    hints: ["cef-rendering"],
                    probableIssueIds: ["cef-rendering"],
                    recommendedProbeIds: ["window-input"],
                    logNames: ["steam.log"],
                    logPaths: [root.appendingPathComponent("Logs/steam.log").path]
                )
            ]
        )
        let externalOpenQueue = ExternalExecutableOpenQueueReport(
            generatedAt: generatedAt,
            queuePath: paths.externalOpenQueueDirectory.appendingPathComponent("requests.jsonl").path,
            logPath: paths.logsDirectory.appendingPathComponent("external-open-queue.log").path,
            pendingCount: 2,
            uniquePendingCount: 1,
            duplicatePendingCount: 1,
            invalidLineCount: 0,
            sourceCounts: ["finder-open": 2],
            duplicatePaths: ["/Users/alice/Downloads/SteamSetup.exe"],
            items: [
                ExternalExecutableOpenQueueItem(
                    path: "/Users/alice/Downloads/SteamSetup.exe",
                    source: "finder-open",
                    enqueuedAt: generatedAt
                )
            ]
        )
        let supportTriage = SupportTriageReport(
            generatedAt: generatedAt,
            rootPath: root.path,
            items: [
                SupportTriageItem(
                    id: "software-acquisition-collection-steam",
                    severity: .high,
                    source: .softwareAcquisition,
                    title: "Software acquisition required: Steam",
                    detail: "Download SteamSetup.exe",
                    recommendedAction: "Use software-acquisition.sh to cache the installer.",
                    relatedIds: ["steam"]
                ),
                SupportTriageItem(
                    id: "launch-health-steam",
                    severity: .high,
                    source: .launchHealth,
                    title: "Launch health needs attention: Steam",
                    detail: "Steam launch failed",
                    recommendedAction: "Open launch-health.md.",
                    relatedPaths: [root.appendingPathComponent("Logs/steam.log").path]
                ),
                SupportTriageItem(
                    id: "external-exe-open-queue-pending",
                    severity: .warning,
                    source: .externalExecutableQueue,
                    title: "External EXE open queue has pending files",
                    detail: "pending=2",
                    recommendedAction: "Drain or retry queued installers."
                )
            ]
        )

        let result = try SoftwareCollectionBundleService(paths: paths).exportBundle(
            collection: collection,
            history: history,
            logIssues: logIssues,
            softwareAcquisition: softwareAcquisition,
            softwareSamplePreparation: samplePreparation,
            launchHealth: launchHealth,
            externalOpenQueue: externalOpenQueue,
            supportTriage: supportTriage,
            generatedAt: generatedAt
        )

        let bundleURL = result.bundleURL
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("manifest.json").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("software-collection.json").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("software-collection.csv").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("software-collection-lockfile.json").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("software-collection-lockfile.csv").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("software-collection-lockfile.md").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("software-collection-downloads.sh").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("software-collection-history.json").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("software-collection-history.csv").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("acceptance.json").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("acceptance.csv").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("acceptance.md").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("acceptance-runbook.sh").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("software-acquisition.json").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("software-acquisition.csv").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("software-acquisition.md").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("software-acquisition.sh").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("software-sample-preparation.json").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("software-sample-preparation.csv").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("software-sample-preparation.md").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("software-sample-preparation.sh").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("launch-health.json").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("launch-health.csv").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("launch-health.md").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("external-open-queue.json").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("external-open-queue.csv").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("external-open-queue.log").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("support-triage.json").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("support-triage.csv").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("support-triage.md").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("log-issues.csv").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("log-triage.md").path))
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("README.md").path))

        let scriptAttributes = try FileManager.default.attributesOfItem(
            atPath: bundleURL.appendingPathComponent("software-collection-downloads.sh").path
        )
        let permissions = try #require(scriptAttributes[.posixPermissions] as? NSNumber)
        #expect(permissions.intValue & 0o111 != 0)
        let runbookAttributes = try FileManager.default.attributesOfItem(
            atPath: bundleURL.appendingPathComponent("acceptance-runbook.sh").path
        )
        let runbookPermissions = try #require(runbookAttributes[.posixPermissions] as? NSNumber)
        #expect(runbookPermissions.intValue & 0o111 != 0)
        let samplePreparationScriptAttributes = try FileManager.default.attributesOfItem(
            atPath: bundleURL.appendingPathComponent("software-sample-preparation.sh").path
        )
        let samplePreparationScriptPermissions = try #require(samplePreparationScriptAttributes[.posixPermissions] as? NSNumber)
        #expect(samplePreparationScriptPermissions.intValue & 0o111 != 0)

        let manifest = try JSONStore().load(
            SoftwareCollectionBundleManifest.self,
            from: bundleURL.appendingPathComponent("manifest.json")
        )
        #expect(manifest.collectionCount == 1)
        #expect(manifest.recipeCount == 2)
        #expect(manifest.missingInstallerCount == 1)
        #expect(manifest.historyRecordCount == 1)
        #expect(manifest.logsAnalyzed == 1)
        #expect(manifest.topIssueCount == 1)
        #expect(manifest.acceptanceState == SoftwareCollectionAcceptanceState.needsAction.rawValue)
        #expect(manifest.acceptanceActionCount >= 2)
        #expect(manifest.lockfilePath.hasSuffix("software-collection-lockfile.json"))
        #expect(manifest.lockfileCSVPath.hasSuffix("software-collection-lockfile.csv"))
        #expect(manifest.lockfileMarkdownPath.hasSuffix("software-collection-lockfile.md"))
        #expect(manifest.hashProtectedCount == 2)
        #expect(manifest.hashMismatchCount == 0)
        #expect(manifest.unprotectedDownloadCount == 0)
        #expect(manifest.downloadScriptPath.hasSuffix("software-collection-downloads.sh"))
        #expect(manifest.acceptancePath.hasSuffix("acceptance.json"))
        #expect(manifest.acceptanceRunbookPath?.hasSuffix("acceptance-runbook.sh") == true)
        #expect(manifest.softwareAcquisitionPath?.hasSuffix("software-acquisition.json") == true)
        #expect(manifest.softwareAcquisitionScriptPath?.hasSuffix("software-acquisition.sh") == true)
        #expect(manifest.softwareAcquisitionActionCount == 1)
        #expect(manifest.softwareAcquisitionDownloadableCount == 1)
        #expect(manifest.softwareSamplePreparationPath?.hasSuffix("software-sample-preparation.json") == true)
        #expect(manifest.softwareSamplePreparationCSVPath?.hasSuffix("software-sample-preparation.csv") == true)
        #expect(manifest.softwareSamplePreparationMarkdownPath?.hasSuffix("software-sample-preparation.md") == true)
        #expect(manifest.softwareSamplePreparationScriptPath?.hasSuffix("software-sample-preparation.sh") == true)
        #expect(manifest.softwareSamplePreparationReadyCount == 1)
        #expect(manifest.softwareSamplePreparationMissingInstallerCount == 1)
        #expect(manifest.softwareSamplePreparationMissingRecipeCount == 0)
        #expect(manifest.softwareSamplePreparationManualCount == 0)
        #expect(manifest.softwareSamplePreparationCachedInstallerCount == 1)
        #expect(manifest.launchHealthPath?.hasSuffix("launch-health.json") == true)
        #expect(manifest.launchHealthEntryCount == 1)
        #expect(manifest.failedLaunchHealthEntryCount == 1)
        #expect(manifest.externalOpenQueueReportPath?.hasSuffix("external-open-queue.json") == true)
        #expect(manifest.externalOpenQueuePendingCount == 2)
        #expect(manifest.externalOpenQueueDuplicateCount == 1)
        #expect(manifest.supportTriagePath?.hasSuffix("support-triage.json") == true)
        #expect(manifest.supportTriageStatus == "attention")
        #expect(manifest.supportTriageItemCount == 3)
        #expect(manifest.supportTriageHighCount == 2)

        let script = try String(
            contentsOf: bundleURL.appendingPathComponent("software-collection-downloads.sh"),
            encoding: .utf8
        )
        #expect(script.contains("download_one 'steam' 'https://example.test/SteamSetup.exe' 'SteamSetup.exe'"))
        #expect(!script.contains("download_one '7zip'"))

        let lockfile = try JSONStore().load(
            SoftwareCollectionLockfile.self,
            from: bundleURL.appendingPathComponent("software-collection-lockfile.json")
        )
        #expect(lockfile.missingInstallerCount == 1)
        #expect(lockfile.items.first { $0.recipeId == "steam" }?.cachedInstallerExists == false)
        let lockfileCSV = try String(contentsOf: bundleURL.appendingPathComponent("software-collection-lockfile.csv"), encoding: .utf8)
        #expect(lockfileCSV.contains("steam,Steam,Valve,Game Launcher,launchers,download,SteamSetup.exe"))
        let lockfileMarkdown = try String(contentsOf: bundleURL.appendingPathComponent("software-collection-lockfile.md"), encoding: .utf8)
        #expect(lockfileMarkdown.contains("# MacWin Software Collection Lockfile"))
        #expect(lockfileMarkdown.contains("### Steam"))

        let runbook = try String(
            contentsOf: bundleURL.appendingPathComponent("acceptance-runbook.sh"),
            encoding: .utf8
        )
        #expect(runbook.contains("download_one 'steam' 'https://example.test/SteamSetup.exe' 'SteamSetup.exe'"))
        #expect(runbook.contains("note 'Review log issue CEF rendering issue'"))

        let readme = try String(contentsOf: bundleURL.appendingPathComponent("README.md"), encoding: .utf8)
        #expect(readme.contains("# MacWin Test Software Collection"))
        #expect(readme.contains("Missing installers: 1"))
        #expect(readme.contains("Acceptance state: needsAction"))
        #expect(readme.contains("Software acquisition actions: 1"))
        #expect(readme.contains("Software samples ready: 1"))
        #expect(readme.contains("Software samples missing installers: 1"))
        #expect(readme.contains("Launch health entries: 1"))
        #expect(readme.contains("External EXE opens pending: 2"))
        #expect(readme.contains("Support triage: attention"))
        #expect(readme.contains("software-acquisition.sh"))
        #expect(readme.contains("software-sample-preparation.md"))
        #expect(readme.contains("software-sample-preparation.sh"))
        #expect(readme.contains("launch-health.md"))
        #expect(readme.contains("support-triage.md"))
        #expect(readme.contains("software-collection-lockfile.json"))
        #expect(readme.contains("acceptance-runbook.sh"))
        #expect(readme.contains("Cache installer for Steam"))
        #expect(readme.contains("Review log issue CEF rendering issue"))

        let acceptance = try JSONStore().load(
            SoftwareCollectionAcceptanceReport.self,
            from: bundleURL.appendingPathComponent("acceptance.json")
        )
        #expect(acceptance.actions.contains { $0.kind == .downloadInstaller && $0.recipeId == "steam" })
        #expect(acceptance.actions.contains { $0.kind == .reviewLogIssue && $0.logIssueId == "cef-rendering" })

        let acceptanceMarkdown = try String(contentsOf: bundleURL.appendingPathComponent("acceptance.md"), encoding: .utf8)
        #expect(acceptanceMarkdown.contains("# MacWin Collection Acceptance"))

        let logTriage = try String(contentsOf: bundleURL.appendingPathComponent("log-triage.md"), encoding: .utf8)
        #expect(logTriage.contains("# MacWin Log Triage"))
        #expect(logTriage.contains("CEF rendering issue"))

        let exportedAcquisition = try JSONStore().load(
            SoftwareAcquisitionReport.self,
            from: bundleURL.appendingPathComponent("software-acquisition.json")
        )
        #expect(exportedAcquisition.actionCount == 1)
        let acquisitionScript = try String(contentsOf: bundleURL.appendingPathComponent("software-acquisition.sh"), encoding: .utf8)
        #expect(acquisitionScript.contains("download_one 'collection-steam' 'https://example.test/SteamSetup.exe' 'SteamSetup.exe'"))
        let exportedSamplePreparation = try JSONStore().load(
            SoftwareSamplePreparationReport.self,
            from: bundleURL.appendingPathComponent("software-sample-preparation.json")
        )
        #expect(exportedSamplePreparation.readyCount == 1)
        #expect(exportedSamplePreparation.missingInstallerCount == 1)
        let samplePreparationMarkdown = try String(
            contentsOf: bundleURL.appendingPathComponent("software-sample-preparation.md"),
            encoding: .utf8
        )
        #expect(samplePreparationMarkdown.contains("# MacWin Software Sample Preparation"))
        #expect(samplePreparationMarkdown.contains("### itch.io"))
        let samplePreparationScript = try String(
            contentsOf: bundleURL.appendingPathComponent("software-sample-preparation.sh"),
            encoding: .utf8
        )
        #expect(samplePreparationScript.contains("[READY] Steam"))
        #expect(samplePreparationScript.contains("[MISSING_INSTALLER] itch.io"))
        let exportedLaunchHealth = try JSONStore().load(
            LaunchHealthReport.self,
            from: bundleURL.appendingPathComponent("launch-health.json")
        )
        #expect(exportedLaunchHealth.failedEntryCount == 1)
        let exportedQueue = try JSONStore().load(
            ExternalExecutableOpenQueueReport.self,
            from: bundleURL.appendingPathComponent("external-open-queue.json")
        )
        #expect(exportedQueue.duplicatePendingCount == 1)
        let exportedTriage = try JSONStore().load(
            SupportTriageReport.self,
            from: bundleURL.appendingPathComponent("support-triage.json")
        )
        #expect(exportedTriage.items.contains { $0.source == .softwareAcquisition })
    }

    private static func collection(root: String) -> SoftwareCollectionReport {
        SoftwareCollectionReport(
            generatedAt: Date(timeIntervalSince1970: 1_000),
            rootPath: root,
            collections: [
                SoftwareCollectionDefinition(
                    id: "launchers",
                    name: "Launchers",
                    purpose: "Launcher coverage",
                    requiredRecipeIds: ["steam", "7zip"]
                )
            ],
            missingRecipeIds: [],
            entries: [
                SoftwareCollectionEntry(
                    recipeId: "7zip",
                    name: "7-Zip",
                    publisher: "Igor Pavlov",
                    category: "Utilities",
                    collectionIds: ["launchers"],
                    compatibilityRating: .good,
                    installerMode: .download,
                    installerFileName: "7z.exe",
                    installerSourceURL: "https://example.test/7z.exe",
                    expectedSha256: String(repeating: "a", count: 64),
                    installerHashStatus: .match,
                    cachedInstallerPath: "\(root)/Downloads/7z.exe",
                    cachedInstallerExists: true,
                    softwareState: .readyToInstall,
                    smokeStage: .installer,
                    smokeSeverity: .pending,
                    installedLauncherCount: 0,
                    latestLaunchState: nil,
                    latestLaunchLogPath: nil,
                    latestLogHealth: nil,
                    readinessIssues: [],
                    recommendedProbeIds: []
                ),
                SoftwareCollectionEntry(
                    recipeId: "steam",
                    name: "Steam",
                    publisher: "Valve",
                    category: "Game Launcher",
                    collectionIds: ["launchers"],
                    compatibilityRating: .limited,
                    installerMode: .download,
                    installerFileName: "SteamSetup.exe",
                    installerSourceURL: "https://example.test/SteamSetup.exe",
                    expectedSha256: String(repeating: "b", count: 64),
                    installerHashStatus: .missing,
                    cachedInstallerPath: "\(root)/Downloads/SteamSetup.exe",
                    cachedInstallerExists: false,
                    softwareState: .missingInstaller,
                    smokeStage: .installer,
                    smokeSeverity: .blocked,
                    installedLauncherCount: 0,
                    latestLaunchState: nil,
                    latestLaunchLogPath: nil,
                    latestLogHealth: nil,
                    readinessIssues: [.missingLauncherAsset],
                    recommendedProbeIds: ["window-input"]
                )
            ]
        )
    }
}
