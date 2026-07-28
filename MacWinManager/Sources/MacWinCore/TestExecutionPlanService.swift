import Foundation

public enum TestExecutionPriority: String, Codable, Equatable, Sendable {
    case required
    case high
    case normal
    case optional
}

public enum TestExecutionReason: String, Codable, Equatable, Sendable {
    case missingRequiredAsset
    case missingRunner
    case neverRun
    case failed
    case timedOut
    case missingExit
    case stale
}

public struct TestExecutionPlanItem: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var assetId: String
    public var name: String
    public var category: DiagnosticCategory
    public var architecture: WindowsExecutableArchitecture
    public var priority: TestExecutionPriority
    public var reasons: [TestExecutionReason]
    public var executablePath: String
    public var exists: Bool
    public var command: [String]
    public var note: String?
    public var latestRunOutcome: TestRunOutcome?
    public var latestRunExitCode: Int32?
    public var latestRunAt: Date?
    public var latestLogPath: String?

    public init(
        id: String,
        assetId: String,
        name: String,
        category: DiagnosticCategory,
        architecture: WindowsExecutableArchitecture,
        priority: TestExecutionPriority,
        reasons: [TestExecutionReason],
        executablePath: String,
        exists: Bool,
        command: [String],
        note: String? = nil,
        latestRunOutcome: TestRunOutcome? = nil,
        latestRunExitCode: Int32? = nil,
        latestRunAt: Date? = nil,
        latestLogPath: String? = nil
    ) {
        self.id = id
        self.assetId = assetId
        self.name = name
        self.category = category
        self.architecture = architecture
        self.priority = priority
        self.reasons = reasons
        self.executablePath = executablePath
        self.exists = exists
        self.command = command
        self.note = note
        self.latestRunOutcome = latestRunOutcome
        self.latestRunExitCode = latestRunExitCode
        self.latestRunAt = latestRunAt
        self.latestLogPath = latestLogPath
    }
}

public struct TestExecutionPlan: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var rootPath: String
    public var itemCount: Int
    public var requiredCount: Int
    public var highPriorityCount: Int
    public var normalPriorityCount: Int
    public var optionalPriorityCount: Int
    public var missingRequiredAssetCount: Int
    public var missingRunnerCount: Int
    public var failedCount: Int
    public var timedOutCount: Int
    public var unverifiedCount: Int
    public var staleCount: Int
    public var items: [TestExecutionPlanItem]

    public init(generatedAt: Date, rootPath: String, items: [TestExecutionPlanItem]) {
        self.generatedAt = generatedAt
        self.rootPath = rootPath
        self.items = items
        self.itemCount = items.count
        self.requiredCount = items.filter { $0.priority == .required }.count
        self.highPriorityCount = items.filter { $0.priority == .high }.count
        self.normalPriorityCount = items.filter { $0.priority == .normal }.count
        self.optionalPriorityCount = items.filter { $0.priority == .optional }.count
        self.missingRequiredAssetCount = items.filter { $0.reasons.contains(.missingRequiredAsset) }.count
        self.missingRunnerCount = items.filter { $0.reasons.contains(.missingRunner) }.count
        self.failedCount = items.filter { $0.reasons.contains(.failed) }.count
        self.timedOutCount = items.filter { $0.reasons.contains(.timedOut) }.count
        self.unverifiedCount = items.filter { $0.reasons.contains(.neverRun) || $0.reasons.contains(.missingExit) }.count
        self.staleCount = items.filter { $0.reasons.contains(.stale) }.count
    }

    public static func csv(plan: TestExecutionPlan?) -> String {
        let formatter = ISO8601DateFormatter()
        var rows: [[String]] = [[
            "asset_id",
            "name",
            "category",
            "architecture",
            "priority",
            "reasons",
            "exists",
            "executable_path",
            "command",
            "note",
            "latest_run_outcome",
            "latest_run_exit_code",
            "latest_run_at",
            "latest_log_path"
        ]]

        for item in plan?.items ?? [] {
            rows.append([
                item.assetId,
                item.name,
                item.category.rawValue,
                item.architecture.rawValue,
                item.priority.rawValue,
                item.reasons.map(\.rawValue).joined(separator: ";"),
                item.exists ? "true" : "false",
                item.executablePath,
                item.command.joined(separator: " "),
                item.note ?? "",
                item.latestRunOutcome?.rawValue ?? "",
                item.latestRunExitCode.map(String.init) ?? "",
                item.latestRunAt.map { formatter.string(from: $0) } ?? "",
                item.latestLogPath ?? ""
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
}

public struct TestExecutionPlanService {
    public var staleAfter: TimeInterval

    public init(staleAfter: TimeInterval = 7 * 24 * 60 * 60) {
        self.staleAfter = staleAfter
    }

    public func makePlan(
        assetReport: TestAssetReport,
        runHistory: TestRunHistoryReport?,
        generatedAt: Date = Date()
    ) -> TestExecutionPlan {
        let commandsByAssetId = Dictionary(
            uniqueKeysWithValues: (assetReport.runbook?.groups.flatMap(\.commands) ?? []).map { ($0.assetId, $0) }
        )
        let latestRunsByAssetId = latestRunsByAssetId(runHistory?.runs ?? [])
        let executableStatuses = assetReport.statuses
            .filter { $0.kind == .executable && $0.required }

        let items = executableStatuses.compactMap { status -> TestExecutionPlanItem? in
            let command = commandsByAssetId[status.id]
            let latestRun = latestRunsByAssetId[status.id]
            let reasons = reasons(
                for: status,
                command: command,
                latestRun: latestRun,
                generatedAt: generatedAt
            )
            guard !reasons.isEmpty else { return nil }
            let priority = priority(for: reasons, required: status.required)
            return TestExecutionPlanItem(
                id: status.id,
                assetId: status.id,
                name: status.name,
                category: status.category,
                architecture: status.architecture,
                priority: priority,
                reasons: reasons,
                executablePath: status.path,
                exists: status.exists,
                command: command?.command ?? [],
                note: command?.note,
                latestRunOutcome: latestRun?.outcome,
                latestRunExitCode: latestRun?.exitCode,
                latestRunAt: latestRun?.modifiedAt,
                latestLogPath: latestRun?.logPath
            )
        }
        .sorted(by: sortItems)

        return TestExecutionPlan(
            generatedAt: generatedAt,
            rootPath: assetReport.rootPath,
            items: items
        )
    }

    private func latestRunsByAssetId(_ runs: [TestRunRecord]) -> [String: TestRunRecord] {
        var result: [String: TestRunRecord] = [:]
        for run in runs {
            guard let assetId = run.assetId else { continue }
            if let existing = result[assetId], existing.modifiedAt >= run.modifiedAt {
                continue
            }
            result[assetId] = run
        }
        return result
    }

    private func reasons(
        for status: TestAssetStatus,
        command: TestAssetRunCommand?,
        latestRun: TestRunRecord?,
        generatedAt: Date
    ) -> [TestExecutionReason] {
        var reasons: [TestExecutionReason] = []
        if !status.exists {
            reasons.append(.missingRequiredAsset)
        }
        if command?.command == nil {
            reasons.append(.missingRunner)
        }
        guard status.exists else {
            return reasons
        }
        guard let latestRun else {
            reasons.append(.neverRun)
            return reasons
        }
        switch latestRun.outcome {
        case .passed:
            if generatedAt.timeIntervalSince(latestRun.modifiedAt) > staleAfter {
                reasons.append(.stale)
            }
        case .failed:
            reasons.append(.failed)
        case .timedOut:
            reasons.append(.timedOut)
        case .missingExit:
            reasons.append(.missingExit)
        case .unknown:
            reasons.append(.neverRun)
        }
        return reasons
    }

    private func priority(for reasons: [TestExecutionReason], required: Bool) -> TestExecutionPriority {
        if reasons.contains(.missingRequiredAsset) || reasons.contains(.missingRunner) {
            return .required
        }
        if reasons.contains(.failed) || reasons.contains(.timedOut) || reasons.contains(.missingExit) {
            return .high
        }
        if reasons.contains(.neverRun) {
            return required ? .high : .normal
        }
        return .optional
    }

    private func sortItems(_ lhs: TestExecutionPlanItem, _ rhs: TestExecutionPlanItem) -> Bool {
        let priorityOrder: [TestExecutionPriority: Int] = [
            .required: 0,
            .high: 1,
            .normal: 2,
            .optional: 3
        ]
        let lhsPriority = priorityOrder[lhs.priority] ?? Int.max
        let rhsPriority = priorityOrder[rhs.priority] ?? Int.max
        if lhsPriority != rhsPriority {
            return lhsPriority < rhsPriority
        }
        if lhs.category.rawValue != rhs.category.rawValue {
            return lhs.category.rawValue < rhs.category.rawValue
        }
        return lhs.assetId < rhs.assetId
    }
}
