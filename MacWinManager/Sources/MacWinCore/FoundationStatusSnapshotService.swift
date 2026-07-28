import Foundation

public enum FoundationStatusState: String, Codable, Equatable, Sendable {
    case ready
    case attention
    case blocked
}

public enum FoundationStatusSeverity: String, Codable, Equatable, Sendable {
    case blocker
    case warning
    case info
}

public struct FoundationStatusFinding: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var severity: FoundationStatusSeverity
    public var title: String
    public var detail: String
    public var recommendedAction: String

    public init(
        id: String,
        severity: FoundationStatusSeverity,
        title: String,
        detail: String,
        recommendedAction: String
    ) {
        self.id = id
        self.severity = severity
        self.title = title
        self.detail = detail
        self.recommendedAction = recommendedAction
    }
}

public struct FoundationStatusSnapshot: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var generatedAt: Date
    public var rootPath: String
    public var state: FoundationStatusState
    public var blockerCount: Int
    public var warningCount: Int
    public var engineCount: Int
    public var usableEngineCount: Int
    public var bottleCount: Int
    public var healthyBottleCount: Int
    public var catalogRecipeCount: Int
    public var signedCatalogLoaded: Bool
    public var downloadableInstallerCount: Int
    public var cachedInstallerCount: Int
    public var missingInstallerCount: Int
    public var hashMismatchCount: Int
    public var orphanedDownloadCount: Int
    public var softwareReadyToInstallCount: Int
    public var softwareInstalledCount: Int
    public var softwareVerifiedCount: Int
    public var softwareFailingCount: Int
    public var softwareSmokeBlockedCount: Int
    public var softwareSmokeWarningCount: Int
    public var sampleCount: Int
    public var sampleCatalogBackedCount: Int
    public var sampleWarningCount: Int
    public var requiredTestExecutableCount: Int
    public var presentTestExecutableCount: Int
    public var missingRequiredTestExecutableCount: Int
    public var passedTestAssetCount: Int
    public var failedTestAssetCount: Int
    public var timedOutTestAssetCount: Int
    public var recentLogCount: Int
    public var failedLogCount: Int
    public var attentionLogCount: Int
    public var runtimeProcessCount: Int
    public var runtimeProcessFindingCount: Int
    public var runtimeApplicationCount: Int
    public var runtimeApplicationFindingCount: Int
    public var topFindings: [FoundationStatusFinding]

    public init(
        schemaVersion: Int = 1,
        generatedAt: Date,
        rootPath: String,
        state: FoundationStatusState,
        blockerCount: Int,
        warningCount: Int,
        engineCount: Int,
        usableEngineCount: Int,
        bottleCount: Int,
        healthyBottleCount: Int,
        catalogRecipeCount: Int,
        signedCatalogLoaded: Bool,
        downloadableInstallerCount: Int,
        cachedInstallerCount: Int,
        missingInstallerCount: Int,
        hashMismatchCount: Int,
        orphanedDownloadCount: Int,
        softwareReadyToInstallCount: Int,
        softwareInstalledCount: Int,
        softwareVerifiedCount: Int,
        softwareFailingCount: Int,
        softwareSmokeBlockedCount: Int,
        softwareSmokeWarningCount: Int,
        sampleCount: Int,
        sampleCatalogBackedCount: Int,
        sampleWarningCount: Int,
        requiredTestExecutableCount: Int,
        presentTestExecutableCount: Int,
        missingRequiredTestExecutableCount: Int,
        passedTestAssetCount: Int,
        failedTestAssetCount: Int,
        timedOutTestAssetCount: Int,
        recentLogCount: Int,
        failedLogCount: Int,
        attentionLogCount: Int,
        runtimeProcessCount: Int,
        runtimeProcessFindingCount: Int,
        runtimeApplicationCount: Int,
        runtimeApplicationFindingCount: Int,
        topFindings: [FoundationStatusFinding]
    ) {
        self.schemaVersion = schemaVersion
        self.generatedAt = generatedAt
        self.rootPath = rootPath
        self.state = state
        self.blockerCount = blockerCount
        self.warningCount = warningCount
        self.engineCount = engineCount
        self.usableEngineCount = usableEngineCount
        self.bottleCount = bottleCount
        self.healthyBottleCount = healthyBottleCount
        self.catalogRecipeCount = catalogRecipeCount
        self.signedCatalogLoaded = signedCatalogLoaded
        self.downloadableInstallerCount = downloadableInstallerCount
        self.cachedInstallerCount = cachedInstallerCount
        self.missingInstallerCount = missingInstallerCount
        self.hashMismatchCount = hashMismatchCount
        self.orphanedDownloadCount = orphanedDownloadCount
        self.softwareReadyToInstallCount = softwareReadyToInstallCount
        self.softwareInstalledCount = softwareInstalledCount
        self.softwareVerifiedCount = softwareVerifiedCount
        self.softwareFailingCount = softwareFailingCount
        self.softwareSmokeBlockedCount = softwareSmokeBlockedCount
        self.softwareSmokeWarningCount = softwareSmokeWarningCount
        self.sampleCount = sampleCount
        self.sampleCatalogBackedCount = sampleCatalogBackedCount
        self.sampleWarningCount = sampleWarningCount
        self.requiredTestExecutableCount = requiredTestExecutableCount
        self.presentTestExecutableCount = presentTestExecutableCount
        self.missingRequiredTestExecutableCount = missingRequiredTestExecutableCount
        self.passedTestAssetCount = passedTestAssetCount
        self.failedTestAssetCount = failedTestAssetCount
        self.timedOutTestAssetCount = timedOutTestAssetCount
        self.recentLogCount = recentLogCount
        self.failedLogCount = failedLogCount
        self.attentionLogCount = attentionLogCount
        self.runtimeProcessCount = runtimeProcessCount
        self.runtimeProcessFindingCount = runtimeProcessFindingCount
        self.runtimeApplicationCount = runtimeApplicationCount
        self.runtimeApplicationFindingCount = runtimeApplicationFindingCount
        self.topFindings = topFindings
    }
}

public struct FoundationStatusSnapshotExportResult: Equatable, Sendable {
    public var snapshotURL: URL
    public var latestSnapshotURL: URL
    public var markdownURL: URL
    public var latestMarkdownURL: URL
    public var logURL: URL
}

public struct FoundationStatusSnapshotService {
    public var paths: MacWinPaths
    public var fileManager: FileManager
    public var store: JSONStore

    public init(
        paths: MacWinPaths = MacWinPaths(),
        fileManager: FileManager = .default,
        store: JSONStore? = nil
    ) {
        self.paths = paths
        self.fileManager = fileManager
        self.store = store ?? JSONStore(fileManager: fileManager)
    }

    public func makeSnapshot(report: CapabilityReport) -> FoundationStatusSnapshot {
        let findings = Self.findings(report: report)
        let currentLogIssues = Self.currentFailedLogSamples(report: report)
        let blockerCount = findings.filter { $0.severity == .blocker }.count
        let warningCount = findings.filter { $0.severity == .warning }.count
        let state: FoundationStatusState
        if blockerCount > 0 {
            state = .blocked
        } else if warningCount > 0 {
            state = .attention
        } else {
            state = .ready
        }

        return FoundationStatusSnapshot(
            generatedAt: report.generatedAt,
            rootPath: report.rootPath,
            state: state,
            blockerCount: blockerCount,
            warningCount: warningCount,
            engineCount: report.engines.count,
            usableEngineCount: report.engines.filter {
                $0.winePathExists && $0.wineserverPathExists && $0.runtimePathExists
            }.count,
            bottleCount: report.bottles.count,
            healthyBottleCount: report.bottleHealth.healthyBottleCount,
            catalogRecipeCount: report.catalog.recipeCount,
            signedCatalogLoaded: report.catalog.signedCuratedCatalogLoaded,
            downloadableInstallerCount: report.installerAssets.downloadableRecipeCount,
            cachedInstallerCount: report.installerAssets.cachedRecipeCount,
            missingInstallerCount: report.installerAssets.missingDownloadCount,
            hashMismatchCount: report.installerAssets.hashMismatchCount,
            orphanedDownloadCount: report.installerAssets.orphanedFileCount,
            softwareReadyToInstallCount: report.softwareTestPlan.readyToInstallCount,
            softwareInstalledCount: report.softwareTestPlan.installedCount,
            softwareVerifiedCount: report.softwareTestPlan.verifiedCount,
            softwareFailingCount: report.softwareTestPlan.failingCount,
            softwareSmokeBlockedCount: report.softwareSmokeMatrix.blockedCount,
            softwareSmokeWarningCount: report.softwareSmokeMatrix.warningCount,
            sampleCount: report.softwareSampleCatalog.sampleCount,
            sampleCatalogBackedCount: report.softwareSampleCatalog.catalogBackedCount,
            sampleWarningCount: report.softwareSampleCatalog.warningCount,
            requiredTestExecutableCount: report.testCoverage.requiredExecutableCount,
            presentTestExecutableCount: report.testCoverage.presentExecutableCount,
            missingRequiredTestExecutableCount: report.testCoverage.missingRequiredExecutableCount,
            passedTestAssetCount: report.testCoverage.passedAssetCount,
            failedTestAssetCount: report.testCoverage.failedAssetCount,
            timedOutTestAssetCount: report.testCoverage.timedOutAssetCount,
            recentLogCount: report.logs.recentLogCount,
            failedLogCount: currentLogIssues.filter { $0.health == LogHealth.failed.rawValue }.count,
            attentionLogCount: currentLogIssues.filter { $0.health == LogHealth.attention.rawValue }.count,
            runtimeProcessCount: report.runtimeProcesses?.auditedProcessCount ?? 0,
            runtimeProcessFindingCount: report.runtimeProcesses?.findings.count ?? 0,
            runtimeApplicationCount: report.runtimeApplications?.auditedApplicationCount ?? 0,
            runtimeApplicationFindingCount: report.runtimeApplications?.findings.count ?? 0,
            topFindings: Array(findings.prefix(12))
        )
    }

    @discardableResult
    public func exportSnapshot(report: CapabilityReport) throws -> FoundationStatusSnapshotExportResult {
        try paths.ensureBaseDirectories(fileManager: fileManager)
        let snapshot = makeSnapshot(report: report)
        let directory = paths.logsDirectory.appendingPathComponent("FoundationStatus", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let timestamp = Self.fileTimestamp(snapshot.generatedAt)
        let snapshotURL = directory.appendingPathComponent("foundation-status-\(timestamp).json")
        let latestSnapshotURL = directory.appendingPathComponent("foundation-status-latest.json")
        let markdownURL = directory.appendingPathComponent("foundation-status-\(timestamp).md")
        let latestMarkdownURL = directory.appendingPathComponent("foundation-status-latest.md")
        let logURL = paths.logsDirectory.appendingPathComponent("foundation-status.log")

        try store.save(snapshot, to: snapshotURL)
        try store.save(snapshot, to: latestSnapshotURL)
        let markdown = Self.markdown(snapshot: snapshot)
        try Data(markdown.utf8).write(to: markdownURL, options: [.atomic])
        try Data(markdown.utf8).write(to: latestMarkdownURL, options: [.atomic])
        try appendLogLine(snapshot: snapshot, logURL: logURL)

        return FoundationStatusSnapshotExportResult(
            snapshotURL: snapshotURL,
            latestSnapshotURL: latestSnapshotURL,
            markdownURL: markdownURL,
            latestMarkdownURL: latestMarkdownURL,
            logURL: logURL
        )
    }

    public static func markdown(snapshot: FoundationStatusSnapshot) -> String {
        var lines = [
            "# MacWin Foundation Status",
            "",
            "- State: \(snapshot.state.rawValue)",
            "- Generated at: \(ISO8601DateFormatter().string(from: snapshot.generatedAt))",
            "- Root: `\(snapshot.rootPath)`",
            "",
            "## Summary",
            "",
            "| Area | Value |",
            "| --- | ---: |",
            "| Engines | \(snapshot.usableEngineCount)/\(snapshot.engineCount) usable |",
            "| Bottles | \(snapshot.healthyBottleCount)/\(snapshot.bottleCount) healthy |",
            "| Catalog recipes | \(snapshot.catalogRecipeCount) |",
            "| Downloadable installers | \(snapshot.cachedInstallerCount)/\(snapshot.downloadableInstallerCount) cached |",
            "| Missing installers | \(snapshot.missingInstallerCount) |",
            "| Required test EXEs | \(snapshot.presentTestExecutableCount)/\(snapshot.requiredTestExecutableCount) present |",
            "| Recent failed logs | \(snapshot.failedLogCount) |",
            "| Runtime processes | \(snapshot.runtimeProcessCount) |",
            "",
            "## Findings",
            ""
        ]
        if snapshot.topFindings.isEmpty {
            lines.append("- No blockers or warnings.")
        } else {
            for finding in snapshot.topFindings {
                lines.append("- [\(finding.severity.rawValue)] \(finding.title): \(finding.detail) Action: \(finding.recommendedAction)")
            }
        }
        lines.append("")
        return lines.joined(separator: "\n")
    }

    private func appendLogLine(snapshot: FoundationStatusSnapshot, logURL: URL) throws {
        try fileManager.createDirectory(at: logURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if !fileManager.fileExists(atPath: logURL.path) {
            fileManager.createFile(atPath: logURL.path, contents: nil)
        }
        let line = [
            "at=\(ISO8601DateFormatter().string(from: snapshot.generatedAt))",
            "state=\(snapshot.state.rawValue)",
            "blockers=\(snapshot.blockerCount)",
            "warnings=\(snapshot.warningCount)",
            "recipes=\(snapshot.catalogRecipeCount)",
            "cachedInstallers=\(snapshot.cachedInstallerCount)",
            "missingInstallers=\(snapshot.missingInstallerCount)",
            "testExe=\(snapshot.presentTestExecutableCount)/\(snapshot.requiredTestExecutableCount)",
            "failedLogs=\(snapshot.failedLogCount)",
            "runtimeProcesses=\(snapshot.runtimeProcessCount)"
        ].joined(separator: " ")
        let handle = try FileHandle(forWritingTo: logURL)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: Data((line + "\n").utf8))
    }

    private static func findings(report: CapabilityReport) -> [FoundationStatusFinding] {
        var findings: [FoundationStatusFinding] = []

        if report.engines.isEmpty {
            findings.append(finding(
                id: "no-engine",
                severity: .blocker,
                title: "No managed Wine engine",
                detail: "No engine is registered, so bottles, installers, and probes cannot run.",
                action: "Import or repair the current Wine engine."
            ))
        }
        let unusableEngines = report.engines.filter {
            !$0.winePathExists || !$0.wineserverPathExists || !$0.runtimePathExists
        }
        if !unusableEngines.isEmpty {
            findings.append(finding(
                id: "engine-path-missing",
                severity: .blocker,
                title: "Engine files are missing",
                detail: "\(unusableEngines.count) engine(s) have missing wine, wineserver, or runtime paths.",
                action: "Re-register the engine or repair the symlink target."
            ))
        }
        if report.catalog.recipeCount == 0 || !report.catalog.signedCuratedCatalogLoaded {
            findings.append(finding(
                id: "catalog-empty",
                severity: .blocker,
                title: "Catalog is empty",
                detail: "No signed curated recipes are loaded, so Market and software tests will be empty.",
                action: "Refresh the bundled catalog cache."
            ))
        }
        if report.bottleHealth.actionRequiredBottleCount > 0 {
            findings.append(finding(
                id: "bottle-health-action-required",
                severity: .blocker,
                title: "Bottle repair required",
                detail: "\(report.bottleHealth.actionRequiredBottleCount) bottle(s) have high-severity health findings.",
                action: "Open bottle health details and repair missing drive_c, wineboot, fonts, or launcher metadata."
            ))
        }
        if report.testCoverage.missingRequiredExecutableCount > 0 {
            findings.append(finding(
                id: "test-assets-missing",
                severity: .blocker,
                title: "Required test executables are missing",
                detail: "\(report.testCoverage.missingRequiredExecutableCount) required probe executable(s) are not present.",
                action: "Build or restore refs/exe-tests before running diagnostics."
            ))
        }
        if report.installerAssets.hashMismatchCount > 0 {
            findings.append(finding(
                id: "installer-hash-mismatch",
                severity: .blocker,
                title: "Installer hash mismatch",
                detail: "\(report.installerAssets.hashMismatchCount) cached installer(s) do not match signed recipe hashes.",
                action: "Delete and re-download mismatched installers."
            ))
        }
        if report.softwareSmokeMatrix.blockedCount > 0 {
            findings.append(finding(
                id: "software-smoke-blocked",
                severity: .blocker,
                title: "Software smoke checks are blocked",
                detail: "\(report.softwareSmokeMatrix.blockedCount) software recipe(s) have blocked smoke checks.",
                action: "Use the collection acceptance runbook to clear blockers."
            ))
        }
        if report.installerAssets.missingDownloadCount > 0 {
            findings.append(finding(
                id: "installers-missing",
                severity: .warning,
                title: "Installers still need download",
                detail: "\(report.installerAssets.missingDownloadCount) downloadable installer(s) are not cached.",
                action: "Run the installer download script or use the Market download button."
            ))
        }
        if report.compatibilityRepairAudit.missingRuntimeCoverageCount > 0 {
            let missingFiles = Set(
                report.compatibilityRepairAudit.runtimeCoverageEntries.flatMap(\.missingSourcePaths)
            )
            findings.append(finding(
                id: "compatibility-runtime-coverage-missing",
                severity: .warning,
                title: "Compatibility runtime files are missing",
                detail: "\(missingFiles.count) required engine runtime file(s) are missing for \(report.compatibilityRepairAudit.missingRuntimeCoverageCount) compatibility profile(s).",
                action: "Open Compatibility Repair Audit, build the listed engine targets, and refresh diagnostics."
            ))
        }
        let currentLogFailures = currentFailedLogSamples(report: report)
        if !currentLogFailures.isEmpty {
            findings.append(finding(
                id: "recent-log-failures",
                severity: .warning,
                title: "Recent logs need review",
                detail: "\(currentLogFailures.count) current log(s) contain failure or attention signals.",
                action: "Open log issues and rerun the recommended probes."
            ))
        } else if report.logs.issueReport.failedLogCount > 0 {
            findings.append(finding(
                id: "historical-log-failures",
                severity: .info,
                title: "Historical logs contain failures",
                detail: "\(report.logs.issueReport.failedLogCount) older log(s) contain errors or FAIL markers.",
                action: "Keep them for diagnostics or archive them from log maintenance."
            ))
        }
        if report.runtimeProcesses?.findings.isEmpty == false {
            findings.append(finding(
                id: "runtime-process-findings",
                severity: .warning,
                title: "Runtime process audit has findings",
                detail: "\(report.runtimeProcesses?.findings.count ?? 0) runtime process finding(s) are active.",
                action: "Stop stale Wine/app processes before the next smoke run."
            ))
        }
        if report.runtimeApplications?.findings.isEmpty == false {
            findings.append(finding(
                id: "runtime-application-findings",
                severity: .warning,
                title: "Runtime application audit has findings",
                detail: "\(report.runtimeApplications?.findings.count ?? 0) LaunchServices finding(s) are active.",
                action: "Quit duplicate app entries or restart the signed app bundle."
            ))
        }
        if report.softwareTestPlan.failingCount > 0 {
            findings.append(finding(
                id: "software-plan-failing",
                severity: .warning,
                title: "Software test plan has failures",
                detail: "\(report.softwareTestPlan.failingCount) software item(s) have failed install or launch states.",
                action: "Review the latest launch/install logs and rerun with diagnostics."
            ))
        }
        if report.installerAssets.orphanedFileCount > 0 {
            findings.append(finding(
                id: "orphaned-downloads",
                severity: .info,
                title: "Unmatched download cache files",
                detail: "\(report.installerAssets.orphanedFileCount) cached file(s) are not matched to signed recipes.",
                action: "Keep useful local samples or archive unrelated downloads."
            ))
        }

        return findings.sorted { lhs, rhs in
            let lhsRank = severityRank(lhs.severity)
            let rhsRank = severityRank(rhs.severity)
            if lhsRank != rhsRank { return lhsRank < rhsRank }
            return lhs.id < rhs.id
        }
    }

    private static func finding(
        id: String,
        severity: FoundationStatusSeverity,
        title: String,
        detail: String,
        action: String
    ) -> FoundationStatusFinding {
        FoundationStatusFinding(
            id: id,
            severity: severity,
            title: title,
            detail: detail,
            recommendedAction: action
        )
    }

    private static func currentFailedLogSamples(report: CapabilityReport) -> [LogIssueSample] {
        let cutoff = report.generatedAt.addingTimeInterval(-24 * 60 * 60)
        return report.logs.issueReport.recentFailures.filter { sample in
            guard !isResolvedCompatibilityFailure(sample) else {
                return false
            }
            if sample.modifiedAt >= cutoff {
                return true
            }
            guard let context = sample.launchContext else {
                return false
            }
            if context.endedAt == nil || context.state == "running" {
                if sample.modifiedAt >= cutoff || context.startedAt >= cutoff {
                    return true
                }
                if let processIdentifier = context.processIdentifier {
                    return isProcessRunning(processIdentifier)
                }
                return false
            }
            return context.startedAt >= cutoff
        }
    }

    private static func isProcessRunning(_ processIdentifier: Int32) -> Bool {
        guard processIdentifier > 0 else { return false }
        return kill(processIdentifier, 0) == 0
    }

    private static func isResolvedCompatibilityFailure(_ sample: LogIssueSample) -> Bool {
        let lowercasedName = sample.name.lowercased()
        let lowercasedPath = sample.path.lowercased()
        let contents = lossyLogContents(path: sample.path)
        if lowercasedName.contains("androws") || lowercasedPath.contains("androws") {
            return contents.contains("env.macwin_compat_profile=cef-software-gl")
                && contents.contains("androwslauncher.exe")
        }
        if lowercasedName.contains("lenovo") || lowercasedPath.contains("lenovo") {
            let isLenovoAppStoreCrash = contents.contains("unhandled page fault")
            let continuedAfterCrash = contents.contains("category:appstore_")
                || contents.contains("category:apks_")
                || contents.contains("category:fc_dl_list")
            let newerSuccessfulLog = hasNewerSuccessfulLenovoAppStoreLog(after: sample.modifiedAt, samplePath: sample.path)
            return isLenovoAppStoreCrash
                && (continuedAfterCrash
                    || newerSuccessfulLog)
                || (newerSuccessfulLog && isLenovoExperimentLogName(lowercasedName))
        }
        if lowercasedName.contains("musescore") || lowercasedPath.contains("musescore") {
            let successfulLaunchSmoke = contents.contains("statusafter25s=running")
                && contents.contains("musescore4.exe")
                && contents.contains("macwin_compat_profile=musescore-studio")
            let successfulInstaller = contents.contains("msiexec")
                && contents.contains("musescore-studio")
                && contents.contains("exitcode=0")
            let successfulMSIDetailLog = contents.contains("productname = musescore studio")
                && contents.contains("action ended")
                && contents.contains("install. return value 1")
            return successfulLaunchSmoke || successfulInstaller || successfulMSIDetailLog
        }
        if lowercasedName.hasPrefix("dotnet-desktop-10-info-")
            && contents.contains("failed to open")
            && contents.contains("dotnet.exe") {
            return hasNewerSuccessfulDotNetInfoLog(after: sample.modifiedAt, samplePath: sample.path)
        }
        return false
    }

    private static func lossyLogContents(path: String) -> String {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return ""
        }
        return String(decoding: data, as: UTF8.self).lowercased()
    }

    private static func hasNewerSuccessfulDotNetInfoLog(after date: Date, samplePath: String) -> Bool {
        let directory = URL(fileURLWithPath: samplePath).deletingLastPathComponent()
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return false
        }

        return urls.contains { url in
            guard url.lastPathComponent.lowercased().hasPrefix("dotnet-desktop-10-info-"),
                  url.path != samplePath,
                  let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey]),
                  values.isRegularFile == true,
                  let modifiedAt = values.contentModificationDate,
                  modifiedAt > date else {
                return false
            }
            let contents = lossyLogContents(path: url.path)
            return contents.contains("microsoft.netcore.app 10.0.9")
                && contents.contains("microsoft.windowsdesktop.app 10.0.9")
                && !contents.contains("failed to open")
        }
    }

    private static func hasNewerSuccessfulLenovoAppStoreLog(after date: Date, samplePath: String) -> Bool {
        let directory = URL(fileURLWithPath: samplePath).deletingLastPathComponent()
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return false
        }

        for url in urls {
            guard url.path != samplePath,
                  url.pathExtension == "log",
                  url.lastPathComponent.lowercased().contains("lenovo"),
                  let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey]),
                  values.isRegularFile == true,
                  let modifiedAt = values.contentModificationDate,
                  modifiedAt > date else {
                continue
            }
            let contents = lossyLogContents(path: url.path)
            if contents.contains("lenovoappstore.exe")
                && (contents.contains("category:appstore_")
                    || contents.contains("category:apks_")
                    || contents.contains("category:fc_dl_list")) {
                return true
            }
        }
        return false
    }

    private static func isLenovoExperimentLogName(_ lowercasedName: String) -> Bool {
        lowercasedName.contains("-ab-")
            || lowercasedName.contains("-seh-")
            || lowercasedName.contains("-window-ab-")
            || lowercasedName.contains("-proxy-ab-")
            || lowercasedName.contains("-dll-combo-")
            || lowercasedName.contains("-gpu-child-")
            || lowercasedName.contains("-nativeish-")
    }

    private static func severityRank(_ severity: FoundationStatusSeverity) -> Int {
        switch severity {
        case .blocker: 0
        case .warning: 1
        case .info: 2
        }
    }

    private static func fileTimestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter.string(from: date)
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "")
    }
}
