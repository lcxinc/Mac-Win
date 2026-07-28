import Foundation

public enum ActivityTimelineEventKind: String, Codable, Equatable, Sendable {
    case installerDownload
    case installTask
    case launch
    case testRun
    case logIssue
    case diagnostics
}

public enum ActivityTimelineSeverity: String, Codable, Equatable, Sendable {
    case info
    case warning
    case error
}

public struct ActivityTimelineReport: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var eventCount: Int
    public var infoEventCount: Int
    public var warningEventCount: Int
    public var errorEventCount: Int
    public var latestEventAt: Date?
    public var events: [ActivityTimelineEvent]

    public init(generatedAt: Date, events: [ActivityTimelineEvent], limit: Int = 100) {
        let sorted = events.sorted { lhs, rhs in
            if lhs.timestamp == rhs.timestamp {
                return lhs.id < rhs.id
            }
            return lhs.timestamp > rhs.timestamp
        }
        let limited = Array(sorted.prefix(limit))
        self.generatedAt = generatedAt
        self.eventCount = limited.count
        self.infoEventCount = limited.filter { $0.severity == .info }.count
        self.warningEventCount = limited.filter { $0.severity == .warning }.count
        self.errorEventCount = limited.filter { $0.severity == .error }.count
        self.latestEventAt = limited.first?.timestamp
        self.events = limited
    }

    public static func make(
        generatedAt: Date,
        installerDownloadHistory: InstallerDownloadHistoryReport? = nil,
        installHistory: InstallHistoryReport?,
        testRunHistory: TestRunHistoryReport?,
        launchHistory: LaunchHistoryReport?,
        logs: CapabilityLogReport,
        diagnostics: CapabilityDiagnosticsReport?,
        limit: Int = 100
    ) -> ActivityTimelineReport {
        var events: [ActivityTimelineEvent] = []
        events.append(contentsOf: installerDownloadEvents(installerDownloadHistory))
        events.append(contentsOf: installEvents(installHistory))
        events.append(contentsOf: testRunEvents(testRunHistory))
        events.append(contentsOf: launchEvents(launchHistory))
        events.append(contentsOf: logIssueEvents(logs.issueReport))
        if let diagnostics {
            events.append(diagnosticsEvent(diagnostics, generatedAt: generatedAt))
        }
        return ActivityTimelineReport(generatedAt: generatedAt, events: events, limit: limit)
    }

    private static func installerDownloadEvents(_ report: InstallerDownloadHistoryReport?) -> [ActivityTimelineEvent] {
        (report?.records ?? []).map { record in
            let severity: ActivityTimelineSeverity
            switch record.state {
            case .cached, .downloaded:
                severity = .info
            case .hashMismatch, .failed:
                severity = .error
            }
            let detailParts = [
                "state=\(record.state.rawValue)",
                "file=\(record.fileName)",
                record.byteCount.map { "bytes=\($0)" },
                record.expectedSha256.map { "expected=\($0)" },
                record.actualSha256.map { "actual=\($0)" },
                record.errorMessage.map { "error=\($0)" }
            ].compactMap { $0 }
            return ActivityTimelineEvent(
                id: "installer-download:\(record.id)",
                kind: .installerDownload,
                severity: severity,
                timestamp: record.endedAt,
                title: "Download \(record.recipeName)",
                detail: detailParts.joined(separator: " "),
                sourcePath: record.destinationPath,
                appId: record.recipeId
            )
        }
    }

    private static func installEvents(_ report: InstallHistoryReport?) -> [ActivityTimelineEvent] {
        (report?.tasks ?? []).map { task in
            let severity: ActivityTimelineSeverity
            switch task.state {
            case .succeeded:
                severity = .info
            case .failed, .cancelled:
                severity = .error
            case .queued, .running, .launched:
                severity = .warning
            }
            let timestamp = task.endedAt ?? task.startedAt
            return ActivityTimelineEvent(
                id: "install:\(task.id)",
                kind: .installTask,
                severity: severity,
                timestamp: timestamp,
                title: "Install \(task.recipeId)",
                detail: "state=\(task.state.rawValue) \(task.progressText)",
                sourcePath: task.logPath,
                bottleId: task.bottleId,
                appId: task.recipeId,
                relatedLogPath: task.logPath
            )
        }
    }

    private static func testRunEvents(_ report: TestRunHistoryReport?) -> [ActivityTimelineEvent] {
        (report?.runs ?? []).map { run in
            ActivityTimelineEvent(
                id: "test:\(run.id)",
                kind: .testRun,
                severity: severity(outcome: run.outcome),
                timestamp: run.modifiedAt,
                title: "Test \(run.name)",
                detail: run.summary,
                sourcePath: run.logPath,
                appId: run.assetId,
                relatedLogPath: run.logPath
            )
        }
    }

    private static func launchEvents(_ report: LaunchHistoryReport?) -> [ActivityTimelineEvent] {
        (report?.records ?? []).map { record in
            let severity: ActivityTimelineSeverity
            switch record.state {
            case .completed:
                severity = (record.exitCode ?? 0) == 0 ? .info : .warning
            case .started:
                severity = .warning
            case .failedToLaunch:
                severity = .error
            }
            let executable = record.exe.split(separator: "\\").last.map(String.init) ?? record.exe
            let exitText = record.exitCode.map { " exit=\($0)" } ?? ""
            return ActivityTimelineEvent(
                id: "launch:\(record.id)",
                kind: .launch,
                severity: severity,
                timestamp: record.endedAt ?? record.startedAt,
                title: "Launch \(executable)",
                detail: "state=\(record.state.rawValue) mode=\(record.mode.rawValue)\(exitText)",
                sourcePath: record.logPath,
                bottleId: record.bottleId,
                relatedLogPath: record.logPath
            )
        }
    }

    private static func logIssueEvents(_ report: LogIssueReport) -> [ActivityTimelineEvent] {
        report.recentFailures.map { sample in
            let severity: ActivityTimelineSeverity = sample.health == LogHealth.failed.rawValue ? .error : .warning
            let issueText = sample.probableIssueIds.isEmpty
                ? "unclassified"
                : sample.probableIssueIds.joined(separator: ",")
            return ActivityTimelineEvent(
                id: "log:\(sample.path)",
                kind: .logIssue,
                severity: severity,
                timestamp: sample.modifiedAt,
                title: "Log issue \(sample.name)",
                detail: "health=\(sample.health) issues=\(issueText) errors=\(sample.errorCount) warnings=\(sample.warningCount) fails=\(sample.failCount)",
                sourcePath: sample.path,
                relatedLogPath: sample.path
            )
        }
    }

    private static func diagnosticsEvent(
        _ diagnostics: CapabilityDiagnosticsReport,
        generatedAt: Date
    ) -> ActivityTimelineEvent {
        let failed = diagnostics.statusCounts[DiagnosticStatus.failed.rawValue] ?? 0
        let skipped = diagnostics.statusCounts[DiagnosticStatus.skipped.rawValue] ?? 0
        let severity: ActivityTimelineSeverity
        if diagnostics.timedOut || diagnostics.exitCode != 0 || failed > 0 {
            severity = .error
        } else if skipped > 0 {
            severity = .warning
        } else {
            severity = .info
        }
        return ActivityTimelineEvent(
            id: "diagnostics:\(diagnostics.logPath)",
            kind: .diagnostics,
            severity: severity,
            timestamp: generatedAt,
            title: "Probe suite diagnostics",
            detail: "exit=\(diagnostics.exitCode) timedOut=\(diagnostics.timedOut) total=\(diagnostics.total)",
            sourcePath: diagnostics.logPath,
            relatedLogPath: diagnostics.logPath
        )
    }

    private static func severity(outcome: TestRunOutcome) -> ActivityTimelineSeverity {
        switch outcome {
        case .passed:
            .info
        case .failed, .timedOut:
            .error
        case .missingExit, .unknown:
            .warning
        }
    }
}

public struct ActivityTimelineEvent: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var kind: ActivityTimelineEventKind
    public var severity: ActivityTimelineSeverity
    public var timestamp: Date
    public var title: String
    public var detail: String
    public var sourcePath: String?
    public var bottleId: String?
    public var appId: String?
    public var relatedLogPath: String?

    public init(
        id: String,
        kind: ActivityTimelineEventKind,
        severity: ActivityTimelineSeverity,
        timestamp: Date,
        title: String,
        detail: String,
        sourcePath: String? = nil,
        bottleId: String? = nil,
        appId: String? = nil,
        relatedLogPath: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.severity = severity
        self.timestamp = timestamp
        self.title = title
        self.detail = detail
        self.sourcePath = sourcePath
        self.bottleId = bottleId
        self.appId = appId
        self.relatedLogPath = relatedLogPath
    }
}
