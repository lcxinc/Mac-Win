import Foundation

public enum TestSessionStatus: String, Codable, Equatable, Sendable {
    case passed
    case attention
    case failed
}

public struct TestSessionCategorySummary: Codable, Equatable, Identifiable, Sendable {
    public var id: String { category.rawValue }
    public var category: DiagnosticCategory
    public var requiredAssetCount: Int
    public var presentRequiredAssetCount: Int
    public var passedAssetCount: Int
    public var failedAssetCount: Int
    public var timedOutAssetCount: Int
    public var unverifiedAssetCount: Int
    public var missingRequiredAssetCount: Int
    public var latestRunAt: Date?
    public var status: TestSessionStatus
}

public struct TestSessionIssue: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var severity: String
    public var title: String
    public var detail: String
    public var relatedPath: String?
}

public struct TestSessionArchiveReport: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var rootPath: String
    public var archivePath: String
    public var status: TestSessionStatus
    public var assetRootPath: String
    public var totalAssetCount: Int
    public var requiredAssetCount: Int
    public var presentAssetCount: Int
    public var missingRequiredAssetCount: Int
    public var requiredExecutableCount: Int
    public var presentExecutableCount: Int
    public var passedAssetCount: Int
    public var failedAssetCount: Int
    public var timedOutAssetCount: Int
    public var unverifiedAssetCount: Int
    public var readyCategoryCount: Int
    public var verifiedCategoryCount: Int
    public var executionPlanItemCount: Int
    public var executionPlanRequiredCount: Int
    public var executionPlanHighPriorityCount: Int
    public var testRunCount: Int
    public var mappedTestRunCount: Int
    public var latestRunAt: Date?
    public var logsAnalyzed: Int
    public var failedLogCount: Int
    public var attentionLogCount: Int
    public var logIssueCount: Int
    public var recentFailureLogCount: Int
    public var diagnosticArtifactCount: Int
    public var diagnosticArtifactBytes: Int64
    public var softwareSampleCatalogPath: String?
    public var softwareSampleLogCorrelationPath: String?
    public var softwareSampleLogCorrelationCSVPath: String?
    public var softwareSampleLogCorrelationMarkdownPath: String?
    public var softwareSampleCount: Int
    public var softwareSampleLocalInstallerCount: Int
    public var softwareSampleSignedRecipeCount: Int
    public var softwareSampleWarningCount: Int
    public var softwareSampleMatchedCount: Int
    public var softwareSampleFailedCount: Int
    public var softwareSampleAttentionCount: Int
    public var softwareSampleLaunchCount: Int
    public var softwareSampleLogCount: Int
    public var softwareCollectionLockfilePath: String? = nil
    public var softwareCollectionLockfileCSVPath: String? = nil
    public var softwareCollectionLockfileMarkdownPath: String? = nil
    public var softwareCollectionAcceptancePath: String? = nil
    public var softwareCollectionAcceptanceCSVPath: String? = nil
    public var softwareCollectionAcceptanceMarkdownPath: String? = nil
    public var softwareCollectionAcceptanceRunbookPath: String? = nil
    public var softwareCollectionRecipeCount: Int? = nil
    public var softwareCollectionMissingInstallerCount: Int? = nil
    public var softwareCollectionHashProtectedCount: Int? = nil
    public var softwareCollectionHashMismatchCount: Int? = nil
    public var softwareCollectionUnprotectedDownloadCount: Int? = nil
    public var softwareCollectionAcceptanceState: String? = nil
    public var softwareCollectionAcceptanceActionCount: Int? = nil
    public var softwareCollectionAcceptanceBlockerCount: Int? = nil
    public var softwareCollectionAcceptanceHighPriorityCount: Int? = nil
    public var categorySummaries: [TestSessionCategorySummary]
    public var issues: [TestSessionIssue]

    public static func csv(report: TestSessionArchiveReport) -> String {
        var rows: [[String]] = [[
            "row_type",
            "id",
            "status",
            "severity",
            "title",
            "detail",
            "category",
            "value",
            "related_path"
        ]]

        rows += [
            ["summary", "status", report.status.rawValue, "", "Overall Status", "", "", report.status.rawValue, ""],
            ["summary", "assets", "", "", "Assets", "", "", "\(report.presentAssetCount)/\(report.totalAssetCount)", ""],
            ["summary", "coverage", "", "", "Coverage", "", "", "passed=\(report.passedAssetCount);failed=\(report.failedAssetCount);timedOut=\(report.timedOutAssetCount);unverified=\(report.unverifiedAssetCount)", ""],
            ["summary", "execution-plan", "", "", "Execution Plan", "", "", "items=\(report.executionPlanItemCount);required=\(report.executionPlanRequiredCount);high=\(report.executionPlanHighPriorityCount)", ""],
            ["summary", "logs", "", "", "Logs", "", "", "analyzed=\(report.logsAnalyzed);failed=\(report.failedLogCount);attention=\(report.attentionLogCount);issues=\(report.logIssueCount)", ""],
            ["summary", "artifacts", "", "", "Diagnostic Artifacts", "", "", "count=\(report.diagnosticArtifactCount);bytes=\(report.diagnosticArtifactBytes)", ""],
            ["summary", "software-samples", "", "", "Software Samples", "", "", "samples=\(report.softwareSampleCount);localInstallers=\(report.softwareSampleLocalInstallerCount);signedRecipes=\(report.softwareSampleSignedRecipeCount);warnings=\(report.softwareSampleWarningCount)", report.softwareSampleCatalogPath ?? ""],
            ["summary", "software-sample-log-correlation", "", "", "Software Sample Log Correlation", "", "", "matched=\(report.softwareSampleMatchedCount);failed=\(report.softwareSampleFailedCount);attention=\(report.softwareSampleAttentionCount);launches=\(report.softwareSampleLaunchCount);logs=\(report.softwareSampleLogCount)", report.softwareSampleLogCorrelationPath ?? ""]
        ]
        if let lockfilePath = report.softwareCollectionLockfilePath {
            rows.append([
                "summary",
                "software-collection-lockfile",
                "",
                "",
                "Software Collection Lockfile",
                "",
                "",
                "recipes=\(report.softwareCollectionRecipeCount ?? 0);missingInstallers=\(report.softwareCollectionMissingInstallerCount ?? 0);hashProtected=\(report.softwareCollectionHashProtectedCount ?? 0);hashMismatches=\(report.softwareCollectionHashMismatchCount ?? 0);unprotectedDownloads=\(report.softwareCollectionUnprotectedDownloadCount ?? 0)",
                lockfilePath
            ])
        }
        if let acceptancePath = report.softwareCollectionAcceptancePath {
            rows.append([
                "summary",
                "software-collection-acceptance",
                report.softwareCollectionAcceptanceState ?? "",
                "",
                "Software Collection Acceptance",
                "",
                "",
                "actions=\(report.softwareCollectionAcceptanceActionCount ?? 0);blockers=\(report.softwareCollectionAcceptanceBlockerCount ?? 0);high=\(report.softwareCollectionAcceptanceHighPriorityCount ?? 0)",
                acceptancePath
            ])
        }

        for category in report.categorySummaries {
            rows.append([
                "category",
                category.category.rawValue,
                category.status.rawValue,
                "",
                "\(category.category.rawValue) coverage",
                "",
                category.category.rawValue,
                "required=\(category.requiredAssetCount);present=\(category.presentRequiredAssetCount);passed=\(category.passedAssetCount);failed=\(category.failedAssetCount);timedOut=\(category.timedOutAssetCount);unverified=\(category.unverifiedAssetCount);missing=\(category.missingRequiredAssetCount)",
                ""
            ])
        }

        for issue in report.issues {
            rows.append([
                "issue",
                issue.id,
                "",
                issue.severity,
                issue.title,
                issue.detail,
                "",
                "",
                issue.relatedPath ?? ""
            ])
        }

        return rows.map { $0.map(csvEscaped).joined(separator: ",") }.joined(separator: "\n") + "\n"
    }

    public static func markdown(report: TestSessionArchiveReport) -> String {
        var lines = [
            "# MacWin Test Session",
            "",
            "- Generated: \(iso8601String(report.generatedAt))",
            "- Status: `\(report.status.rawValue)`",
            "- Archive: `\(report.archivePath)`",
            "- Assets: \(report.presentAssetCount)/\(report.totalAssetCount) present",
            "- Required assets missing: \(report.missingRequiredAssetCount)",
            "- Coverage: passed \(report.passedAssetCount), failed \(report.failedAssetCount), timed out \(report.timedOutAssetCount), unverified \(report.unverifiedAssetCount)",
            "- Execution plan: \(report.executionPlanItemCount) items, \(report.executionPlanRequiredCount) required, \(report.executionPlanHighPriorityCount) high priority",
            "- Test runs: \(report.testRunCount) total, \(report.mappedTestRunCount) mapped",
            "- Logs: \(report.logsAnalyzed) analyzed, \(report.failedLogCount) failed, \(report.attentionLogCount) attention",
            "- Diagnostic artifacts: \(report.diagnosticArtifactCount) files, \(report.diagnosticArtifactBytes) bytes",
            "- Software samples: \(report.softwareSampleCount) samples, \(report.softwareSampleLocalInstallerCount) local installers, \(report.softwareSampleSignedRecipeCount) signed recipes, \(report.softwareSampleWarningCount) warnings",
            "- Software sample log correlation: \(report.softwareSampleMatchedCount) matched samples, \(report.softwareSampleLaunchCount) launches, \(report.softwareSampleLogCount) logs",
            "- Software collection lockfile: \(report.softwareCollectionRecipeCount ?? 0) recipes, \(report.softwareCollectionMissingInstallerCount ?? 0) missing installers, \(report.softwareCollectionHashMismatchCount ?? 0) hash mismatches",
            "- Software collection acceptance: \(report.softwareCollectionAcceptanceState ?? "not-exported"), \(report.softwareCollectionAcceptanceActionCount ?? 0) actions, \(report.softwareCollectionAcceptanceBlockerCount ?? 0) blockers",
            "",
            "## Categories",
            ""
        ]

        for category in report.categorySummaries {
            lines.append("- `\(category.category.rawValue)`: \(category.status.rawValue), passed \(category.passedAssetCount)/\(category.requiredAssetCount), failed \(category.failedAssetCount), timed out \(category.timedOutAssetCount), unverified \(category.unverifiedAssetCount), missing \(category.missingRequiredAssetCount)")
        }

        lines.append("")
        lines.append("## Issues")
        lines.append("")
        if report.issues.isEmpty {
            lines.append("No blocking session issues were found.")
        } else {
            for issue in report.issues {
                lines.append("- `\(issue.severity)` \(issue.title): \(issue.detail)")
            }
        }
        lines.append("")
        return lines.joined(separator: "\n")
    }

    static func status(
        coverage: TestCoverageReport,
        executionPlan: TestExecutionPlan?,
        logIssues: LogIssueReport
    ) -> TestSessionStatus {
        if coverage.failedAssetCount > 0
            || coverage.timedOutAssetCount > 0
            || logIssues.failedLogCount > 0
            || logIssues.topIssues.contains(where: { $0.severity == "critical" || $0.severity == "high" }) {
            return .failed
        }
        if coverage.missingRequiredExecutableCount > 0
            || coverage.unverifiedAssetCount > 0
            || (executionPlan?.requiredCount ?? 0) > 0
            || (executionPlan?.highPriorityCount ?? 0) > 0
            || logIssues.attentionLogCount > 0 {
            return .attention
        }
        return .passed
    }

    private static func iso8601String(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private static func csvEscaped(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}

public struct TestSessionArchiveService {
    public var paths: MacWinPaths
    public var fileManager: FileManager

    public init(paths: MacWinPaths = MacWinPaths(), fileManager: FileManager = .default) {
        self.paths = paths
        self.fileManager = fileManager
    }

    @discardableResult
    public func exportArchive(
        generatedAt: Date = Date(),
        testAssets: TestAssetReport,
        coverage: TestCoverageReport,
        executionPlan: TestExecutionPlan?,
        runHistory: TestRunHistoryReport?,
        logIssues: LogIssueReport,
        diagnosticArtifacts: DiagnosticArtifactIndexReport,
        softwareSampleCatalog: SoftwareSampleCatalogReport? = nil,
        softwareSampleLogCorrelation: SoftwareSampleLogCorrelationReport? = nil,
        softwareCollection: SoftwareCollectionReport? = nil,
        softwareCollectionAcceptance: SoftwareCollectionAcceptanceReport? = nil
    ) throws -> URL {
        try paths.ensureBaseDirectories(fileManager: fileManager)
        let archiveURL = paths.logsDirectory
            .appendingPathComponent("TestSessionArchives", isDirectory: true)
            .appendingPathComponent("macwin-test-session-\(Self.fileTimestamp(generatedAt))-\(UUID().uuidString.prefix(8).lowercased())", isDirectory: true)
        try fileManager.createDirectory(at: archiveURL, withIntermediateDirectories: true)

        let report = Self.report(
            generatedAt: generatedAt,
            paths: paths,
            archiveURL: archiveURL,
            testAssets: testAssets,
            coverage: coverage,
            executionPlan: executionPlan,
            runHistory: runHistory,
            logIssues: logIssues,
            diagnosticArtifacts: diagnosticArtifacts,
            softwareSampleCatalog: softwareSampleCatalog,
            softwareSampleLogCorrelation: softwareSampleLogCorrelation,
            softwareCollection: softwareCollection,
            softwareCollectionAcceptance: softwareCollectionAcceptance
        )
        let store = JSONStore(fileManager: fileManager)
        try store.save(report, to: archiveURL.appendingPathComponent("test-session.json"))
        try Data(TestSessionArchiveReport.csv(report: report).utf8).write(
            to: archiveURL.appendingPathComponent("test-session.csv"),
            options: [.atomic]
        )
        try Data(TestSessionArchiveReport.markdown(report: report).utf8).write(
            to: archiveURL.appendingPathComponent("test-session.md"),
            options: [.atomic]
        )
        try store.save(testAssets, to: archiveURL.appendingPathComponent("test-assets.json"))
        try store.save(coverage, to: archiveURL.appendingPathComponent("test-coverage.json"))
        try Data(TestCoverageReport.csv(report: coverage).utf8).write(
            to: archiveURL.appendingPathComponent("test-coverage.csv"),
            options: [.atomic]
        )
        try store.save(logIssues, to: archiveURL.appendingPathComponent("log-issues.json"))
        try Data(LogIssueReport.csv(report: logIssues).utf8).write(
            to: archiveURL.appendingPathComponent("log-issues.csv"),
            options: [.atomic]
        )
        try store.save(diagnosticArtifacts, to: archiveURL.appendingPathComponent("diagnostic-artifacts.json"))
        try Data(DiagnosticArtifactIndexReport.csv(report: diagnosticArtifacts).utf8).write(
            to: archiveURL.appendingPathComponent("diagnostic-artifacts.csv"),
            options: [.atomic]
        )
        if let softwareSampleCatalog {
            try store.save(softwareSampleCatalog, to: archiveURL.appendingPathComponent("software-sample-catalog.json"))
            try Data(SoftwareSampleCatalogService.csv(report: softwareSampleCatalog).utf8).write(
                to: archiveURL.appendingPathComponent("software-sample-catalog.csv"),
                options: [.atomic]
            )
            try Data(SoftwareSampleCatalogService.runbookMarkdown(report: softwareSampleCatalog).utf8).write(
                to: archiveURL.appendingPathComponent("software-sample-catalog-runbook.md"),
                options: [.atomic]
            )
        }
        if let softwareSampleLogCorrelation {
            try store.save(softwareSampleLogCorrelation, to: archiveURL.appendingPathComponent("software-sample-log-correlation.json"))
            try Data(SoftwareSampleLogCorrelationService.csv(report: softwareSampleLogCorrelation).utf8).write(
                to: archiveURL.appendingPathComponent("software-sample-log-correlation.csv"),
                options: [.atomic]
            )
            try Data(SoftwareSampleLogCorrelationService.markdown(report: softwareSampleLogCorrelation).utf8).write(
                to: archiveURL.appendingPathComponent("software-sample-log-correlation.md"),
                options: [.atomic]
            )
        }
        if let softwareCollection {
            let lockfile = SoftwareCollectionService.lockfile(report: softwareCollection)
            try store.save(lockfile, to: archiveURL.appendingPathComponent("software-collection-lockfile.json"))
            try Data(SoftwareCollectionLockfile.csv(lockfile: lockfile).utf8).write(
                to: archiveURL.appendingPathComponent("software-collection-lockfile.csv"),
                options: [.atomic]
            )
            try Data(SoftwareCollectionLockfile.markdown(lockfile: lockfile).utf8).write(
                to: archiveURL.appendingPathComponent("software-collection-lockfile.md"),
                options: [.atomic]
            )
        }
        if let softwareCollectionAcceptance {
            try store.save(softwareCollectionAcceptance, to: archiveURL.appendingPathComponent("software-collection-acceptance.json"))
            try Data(SoftwareCollectionAcceptanceReport.csv(report: softwareCollectionAcceptance).utf8).write(
                to: archiveURL.appendingPathComponent("software-collection-acceptance.csv"),
                options: [.atomic]
            )
            try Data(SoftwareCollectionAcceptanceReport.markdown(report: softwareCollectionAcceptance).utf8).write(
                to: archiveURL.appendingPathComponent("software-collection-acceptance.md"),
                options: [.atomic]
            )
            let runbookURL = archiveURL.appendingPathComponent("software-collection-acceptance-runbook.sh")
            try Data(SoftwareCollectionAcceptanceReport.runbookScript(report: softwareCollectionAcceptance).utf8).write(
                to: runbookURL,
                options: [.atomic]
            )
            try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: runbookURL.path)
        }
        if let executionPlan {
            try store.save(executionPlan, to: archiveURL.appendingPathComponent("test-execution-plan.json"))
            try Data(TestExecutionPlan.csv(plan: executionPlan).utf8).write(
                to: archiveURL.appendingPathComponent("test-execution-plan.csv"),
                options: [.atomic]
            )
        }
        if let runHistory {
            try store.save(runHistory, to: archiveURL.appendingPathComponent("test-run-history.json"))
            try Data(TestRunHistoryReport.csv(report: runHistory).utf8).write(
                to: archiveURL.appendingPathComponent("test-run-history.csv"),
                options: [.atomic]
            )
        }
        return archiveURL
    }

    public static func report(
        generatedAt: Date,
        paths: MacWinPaths,
        archiveURL: URL,
        testAssets: TestAssetReport,
        coverage: TestCoverageReport,
        executionPlan: TestExecutionPlan?,
        runHistory: TestRunHistoryReport?,
        logIssues: LogIssueReport,
        diagnosticArtifacts: DiagnosticArtifactIndexReport,
        softwareSampleCatalog: SoftwareSampleCatalogReport? = nil,
        softwareSampleLogCorrelation: SoftwareSampleLogCorrelationReport? = nil,
        softwareCollection: SoftwareCollectionReport? = nil,
        softwareCollectionAcceptance: SoftwareCollectionAcceptanceReport? = nil
    ) -> TestSessionArchiveReport {
        let categorySummaries = coverage.categories.map { category in
            let status: TestSessionStatus
            if !category.failedAssetIds.isEmpty || !category.timedOutAssetIds.isEmpty {
                status = .failed
            } else if !category.missingRequiredAssetIds.isEmpty || !category.unverifiedAssetIds.isEmpty {
                status = .attention
            } else {
                status = .passed
            }
            return TestSessionCategorySummary(
                category: category.category,
                requiredAssetCount: category.requiredAssetCount,
                presentRequiredAssetCount: category.presentRequiredAssetCount,
                passedAssetCount: category.passedAssetIds.count,
                failedAssetCount: category.failedAssetIds.count,
                timedOutAssetCount: category.timedOutAssetIds.count,
                unverifiedAssetCount: category.unverifiedAssetIds.count,
                missingRequiredAssetCount: category.missingRequiredAssetIds.count,
                latestRunAt: category.latestRunAt,
                status: status
            )
        }

        let coverageIssues = coverage.categories.flatMap { category -> [TestSessionIssue] in
            var issues: [TestSessionIssue] = []
            if !category.missingRequiredAssetIds.isEmpty {
                issues.append(TestSessionIssue(
                    id: "\(category.category.rawValue)-missing-assets",
                    severity: "medium",
                    title: "Missing required test assets",
                    detail: category.missingRequiredAssetIds.joined(separator: ", "),
                    relatedPath: testAssets.rootPath
                ))
            }
            if !category.failedAssetIds.isEmpty || !category.timedOutAssetIds.isEmpty {
                issues.append(TestSessionIssue(
                    id: "\(category.category.rawValue)-failed-runs",
                    severity: "high",
                    title: "Test probes failed or timed out",
                    detail: (category.failedAssetIds + category.timedOutAssetIds).joined(separator: ", "),
                    relatedPath: category.latestRuns.first?.logPath
                ))
            }
            if !category.unverifiedAssetIds.isEmpty {
                issues.append(TestSessionIssue(
                    id: "\(category.category.rawValue)-unverified-runs",
                    severity: "low",
                    title: "Test probes have not been verified",
                    detail: category.unverifiedAssetIds.joined(separator: ", "),
                    relatedPath: testAssets.rootPath
                ))
            }
            return issues
        }
        let logIssueSummaries = logIssues.topIssues.map {
            TestSessionIssue(
                id: "log-\($0.id)",
                severity: $0.severity,
                title: $0.title,
                detail: $0.detail,
                relatedPath: $0.affectedLogNames.first
            )
        }
        let softwareCollectionLockfile = softwareCollection.map { SoftwareCollectionService.lockfile(report: $0) }

        return TestSessionArchiveReport(
            generatedAt: generatedAt,
            rootPath: paths.root.path,
            archivePath: archiveURL.path,
            status: TestSessionArchiveReport.status(coverage: coverage, executionPlan: executionPlan, logIssues: logIssues),
            assetRootPath: testAssets.rootPath,
            totalAssetCount: testAssets.totalCount,
            requiredAssetCount: testAssets.requiredCount,
            presentAssetCount: testAssets.presentCount,
            missingRequiredAssetCount: testAssets.missingRequiredCount,
            requiredExecutableCount: coverage.requiredExecutableCount,
            presentExecutableCount: coverage.presentExecutableCount,
            passedAssetCount: coverage.passedAssetCount,
            failedAssetCount: coverage.failedAssetCount,
            timedOutAssetCount: coverage.timedOutAssetCount,
            unverifiedAssetCount: coverage.unverifiedAssetCount,
            readyCategoryCount: coverage.readyCategoryCount,
            verifiedCategoryCount: coverage.verifiedCategoryCount,
            executionPlanItemCount: executionPlan?.itemCount ?? 0,
            executionPlanRequiredCount: executionPlan?.requiredCount ?? 0,
            executionPlanHighPriorityCount: executionPlan?.highPriorityCount ?? 0,
            testRunCount: runHistory?.totalRunCount ?? 0,
            mappedTestRunCount: runHistory?.mappedRunCount ?? 0,
            latestRunAt: runHistory?.latestRunAt,
            logsAnalyzed: logIssues.logsAnalyzed,
            failedLogCount: logIssues.failedLogCount,
            attentionLogCount: logIssues.attentionLogCount,
            logIssueCount: logIssues.topIssues.count,
            recentFailureLogCount: logIssues.recentFailures.count,
            diagnosticArtifactCount: diagnosticArtifacts.artifactCount,
            diagnosticArtifactBytes: diagnosticArtifacts.totalBytes,
            softwareSampleCatalogPath: softwareSampleCatalog.map { _ in archiveURL.appendingPathComponent("software-sample-catalog.json").path },
            softwareSampleLogCorrelationPath: softwareSampleLogCorrelation.map { _ in archiveURL.appendingPathComponent("software-sample-log-correlation.json").path },
            softwareSampleLogCorrelationCSVPath: softwareSampleLogCorrelation.map { _ in archiveURL.appendingPathComponent("software-sample-log-correlation.csv").path },
            softwareSampleLogCorrelationMarkdownPath: softwareSampleLogCorrelation.map { _ in archiveURL.appendingPathComponent("software-sample-log-correlation.md").path },
            softwareSampleCount: softwareSampleCatalog?.sampleCount ?? 0,
            softwareSampleLocalInstallerCount: softwareSampleCatalog?.localInstallerCount ?? 0,
            softwareSampleSignedRecipeCount: softwareSampleCatalog?.catalogBackedCount ?? 0,
            softwareSampleWarningCount: softwareSampleCatalog?.warningCount ?? 0,
            softwareSampleMatchedCount: softwareSampleLogCorrelation?.matchedSampleCount ?? 0,
            softwareSampleFailedCount: softwareSampleLogCorrelation?.failedSampleCount ?? 0,
            softwareSampleAttentionCount: softwareSampleLogCorrelation?.attentionSampleCount ?? 0,
            softwareSampleLaunchCount: softwareSampleLogCorrelation?.launchCount ?? 0,
            softwareSampleLogCount: softwareSampleLogCorrelation?.logCount ?? 0,
            softwareCollectionLockfilePath: softwareCollection.map { _ in archiveURL.appendingPathComponent("software-collection-lockfile.json").path },
            softwareCollectionLockfileCSVPath: softwareCollection.map { _ in archiveURL.appendingPathComponent("software-collection-lockfile.csv").path },
            softwareCollectionLockfileMarkdownPath: softwareCollection.map { _ in archiveURL.appendingPathComponent("software-collection-lockfile.md").path },
            softwareCollectionAcceptancePath: softwareCollectionAcceptance.map { _ in archiveURL.appendingPathComponent("software-collection-acceptance.json").path },
            softwareCollectionAcceptanceCSVPath: softwareCollectionAcceptance.map { _ in archiveURL.appendingPathComponent("software-collection-acceptance.csv").path },
            softwareCollectionAcceptanceMarkdownPath: softwareCollectionAcceptance.map { _ in archiveURL.appendingPathComponent("software-collection-acceptance.md").path },
            softwareCollectionAcceptanceRunbookPath: softwareCollectionAcceptance.map { _ in archiveURL.appendingPathComponent("software-collection-acceptance-runbook.sh").path },
            softwareCollectionRecipeCount: softwareCollectionLockfile?.recipeCount,
            softwareCollectionMissingInstallerCount: softwareCollectionLockfile?.missingInstallerCount,
            softwareCollectionHashProtectedCount: softwareCollectionLockfile?.hashProtectedCount,
            softwareCollectionHashMismatchCount: softwareCollectionLockfile?.hashMismatchCount,
            softwareCollectionUnprotectedDownloadCount: softwareCollectionLockfile?.unprotectedDownloadCount,
            softwareCollectionAcceptanceState: softwareCollectionAcceptance?.state.rawValue,
            softwareCollectionAcceptanceActionCount: softwareCollectionAcceptance?.actionCount,
            softwareCollectionAcceptanceBlockerCount: softwareCollectionAcceptance?.blockerCount,
            softwareCollectionAcceptanceHighPriorityCount: softwareCollectionAcceptance?.highPriorityCount,
            categorySummaries: categorySummaries,
            issues: (coverageIssues + logIssueSummaries).sorted {
                if severityRank($0.severity) != severityRank($1.severity) {
                    return severityRank($0.severity) < severityRank($1.severity)
                }
                return $0.id < $1.id
            }
        )
    }

    private static func severityRank(_ severity: String) -> Int {
        switch severity {
        case "critical": 0
        case "high": 1
        case "medium": 2
        case "low": 3
        default: 4
        }
    }

    private static func fileTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: date)
    }
}
