import Foundation

public enum TestAssetKind: String, Codable, CaseIterable, Sendable {
    case source
    case executable
    case runner
}

public struct TestAssetDefinition: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var kind: TestAssetKind
    public var category: DiagnosticCategory
    public var architecture: WindowsExecutableArchitecture
    public var relativePath: String
    public var required: Bool

    public init(
        id: String,
        name: String,
        kind: TestAssetKind,
        category: DiagnosticCategory,
        architecture: WindowsExecutableArchitecture = .unknown,
        relativePath: String,
        required: Bool = true
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.category = category
        self.architecture = architecture
        self.relativePath = relativePath
        self.required = required
    }
}

public struct TestAssetStatus: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var kind: TestAssetKind
    public var category: DiagnosticCategory
    public var architecture: WindowsExecutableArchitecture
    public var path: String
    public var required: Bool
    public var exists: Bool
    public var byteCount: Int64?
    public var sha256: String?

    public init(
        id: String,
        name: String,
        kind: TestAssetKind,
        category: DiagnosticCategory,
        architecture: WindowsExecutableArchitecture,
        path: String,
        required: Bool,
        exists: Bool,
        byteCount: Int64? = nil,
        sha256: String? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.category = category
        self.architecture = architecture
        self.path = path
        self.required = required
        self.exists = exists
        self.byteCount = byteCount
        self.sha256 = sha256
    }
}

public struct TestAssetRunbook: Codable, Equatable, Sendable {
    public var rootPath: String
    public var canRunSuite: Bool
    public var missingRequiredAssetIds: [String]
    public var buildCommand: [String]?
    public var suiteCommand: [String]?
    public var groups: [TestAssetRunGroup]

    public init(
        rootPath: String,
        canRunSuite: Bool,
        missingRequiredAssetIds: [String],
        buildCommand: [String]?,
        suiteCommand: [String]?,
        groups: [TestAssetRunGroup]
    ) {
        self.rootPath = rootPath
        self.canRunSuite = canRunSuite
        self.missingRequiredAssetIds = missingRequiredAssetIds
        self.buildCommand = buildCommand
        self.suiteCommand = suiteCommand
        self.groups = groups
    }
}

public struct TestAssetRunGroup: Codable, Equatable, Sendable {
    public var category: DiagnosticCategory
    public var assetIds: [String]
    public var commands: [TestAssetRunCommand]
}

public struct TestAssetRunCommand: Codable, Equatable, Sendable {
    public var assetId: String
    public var name: String
    public var architecture: WindowsExecutableArchitecture
    public var executablePath: String
    public var exists: Bool
    public var command: [String]?
    public var note: String?
}

public struct TestAssetReport: Codable, Equatable, Sendable {
    public var rootPath: String
    public var totalCount: Int
    public var requiredCount: Int
    public var presentCount: Int
    public var missingRequiredCount: Int
    public var statuses: [TestAssetStatus]
    public var runbook: TestAssetRunbook?

    public init(rootPath: String, statuses: [TestAssetStatus], runbook: TestAssetRunbook? = nil) {
        self.rootPath = rootPath
        self.totalCount = statuses.count
        self.requiredCount = statuses.filter(\.required).count
        self.presentCount = statuses.filter(\.exists).count
        self.missingRequiredCount = statuses.filter { $0.required && !$0.exists }.count
        self.statuses = statuses
        self.runbook = runbook
    }

    public var isReady: Bool {
        missingRequiredCount == 0
    }
}

public struct TestCoverageReport: Codable, Equatable, Sendable {
    public var requiredExecutableCount: Int
    public var presentExecutableCount: Int
    public var missingRequiredExecutableCount: Int
    public var passedAssetCount: Int
    public var failedAssetCount: Int
    public var timedOutAssetCount: Int
    public var unverifiedAssetCount: Int
    public var readyCategoryCount: Int
    public var verifiedCategoryCount: Int
    public var categories: [TestCoverageCategoryReport]

    public init(categories: [TestCoverageCategoryReport]) {
        self.categories = categories
        self.requiredExecutableCount = categories.reduce(0) { $0 + $1.requiredAssetCount }
        self.presentExecutableCount = categories.reduce(0) { $0 + $1.presentRequiredAssetCount }
        self.missingRequiredExecutableCount = categories.reduce(0) { $0 + $1.missingRequiredAssetIds.count }
        self.passedAssetCount = categories.reduce(0) { $0 + $1.passedAssetIds.count }
        self.failedAssetCount = categories.reduce(0) { $0 + $1.failedAssetIds.count }
        self.timedOutAssetCount = categories.reduce(0) { $0 + $1.timedOutAssetIds.count }
        self.unverifiedAssetCount = categories.reduce(0) { $0 + $1.unverifiedAssetIds.count }
        self.readyCategoryCount = categories.filter { $0.isReady }.count
        self.verifiedCategoryCount = categories.filter { $0.isVerified }.count
    }

    public static func make(assetReport: TestAssetReport, runHistory: TestRunHistoryReport?) -> TestCoverageReport {
        let requiredExecutables = assetReport.statuses.filter { $0.required && $0.kind == .executable }
        let latestRunsByAssetId = latestRunsByAssetId(runHistory?.runs ?? [])
        let categories = DiagnosticCategory.allCases.compactMap { category -> TestCoverageCategoryReport? in
            let assets = requiredExecutables.filter { $0.category == category }
            guard !assets.isEmpty else { return nil }
            return TestCoverageCategoryReport(
                category: category,
                assets: assets,
                latestRunsByAssetId: latestRunsByAssetId
            )
        }
        return TestCoverageReport(categories: categories)
    }

    private static func latestRunsByAssetId(_ runs: [TestRunRecord]) -> [String: TestRunRecord] {
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

    public static func csv(report: TestCoverageReport) -> String {
        let header = [
            "category",
            "asset_id",
            "asset_name",
            "asset_status",
            "category_ready",
            "category_verified",
            "required_asset_count",
            "present_required_asset_count",
            "latest_outcome",
            "latest_run_at",
            "log_path",
            "summary"
        ]
        let rows = report.categories.flatMap { category -> [[String]] in
            let latestRunsByAssetId = Dictionary(uniqueKeysWithValues: category.latestRuns.map { ($0.assetId, $0) })
            let assetIds = orderedUnique(
                category.missingRequiredAssetIds
                    + category.passedAssetIds
                    + category.failedAssetIds
                    + category.timedOutAssetIds
                    + category.unverifiedAssetIds
            ).sorted()
            return assetIds.map { assetId in
                let latest = latestRunsByAssetId[assetId]
                return [
                    category.category.rawValue,
                    assetId,
                    latest?.name ?? assetId,
                    coverageStatus(assetId: assetId, category: category),
                    "\(category.isReady)",
                    "\(category.isVerified)",
                    "\(category.requiredAssetCount)",
                    "\(category.presentRequiredAssetCount)",
                    latest?.outcome.rawValue ?? "",
                    latest.map { ISO8601DateFormatter().string(from: $0.modifiedAt) } ?? "",
                    latest?.logPath ?? "",
                    latest?.summary ?? ""
                ]
            }
        }
        return ([header] + rows)
            .map { $0.map(csvEscaped).joined(separator: ",") }
            .joined(separator: "\n") + "\n"
    }

    private static func coverageStatus(assetId: String, category: TestCoverageCategoryReport) -> String {
        if category.missingRequiredAssetIds.contains(assetId) { return "missingRequired" }
        if category.passedAssetIds.contains(assetId) { return "passed" }
        if category.failedAssetIds.contains(assetId) { return "failed" }
        if category.timedOutAssetIds.contains(assetId) { return "timedOut" }
        if category.unverifiedAssetIds.contains(assetId) { return "unverified" }
        return "unknown"
    }

    private static func csvEscaped(_ value: String) -> String {
        let normalized = value
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        if normalized.contains(",") || normalized.contains("\"") || normalized.contains("\n") {
            return "\"\(normalized.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return normalized
    }

    private static func orderedUnique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for value in values where !seen.contains(value) {
            seen.insert(value)
            result.append(value)
        }
        return result
    }
}

public struct TestCoverageCategoryReport: Codable, Equatable, Sendable {
    public var category: DiagnosticCategory
    public var requiredAssetCount: Int
    public var presentRequiredAssetCount: Int
    public var missingRequiredAssetIds: [String]
    public var passedAssetIds: [String]
    public var failedAssetIds: [String]
    public var timedOutAssetIds: [String]
    public var unverifiedAssetIds: [String]
    public var latestRunAt: Date?
    public var latestRuns: [TestCoverageRunSummary]

    public init(
        category: DiagnosticCategory,
        assets: [TestAssetStatus],
        latestRunsByAssetId: [String: TestRunRecord]
    ) {
        self.category = category
        self.requiredAssetCount = assets.count
        self.presentRequiredAssetCount = assets.filter(\.exists).count
        self.missingRequiredAssetIds = assets.filter { !$0.exists }.map(\.id).sorted()

        var passed: [String] = []
        var failed: [String] = []
        var timedOut: [String] = []
        var unverified: [String] = []
        var runSummaries: [TestCoverageRunSummary] = []

        for asset in assets.sorted(by: { $0.id < $1.id }) {
            guard asset.exists else { continue }
            guard let run = latestRunsByAssetId[asset.id] else {
                unverified.append(asset.id)
                continue
            }
            runSummaries.append(TestCoverageRunSummary(record: run))
            switch run.outcome {
            case .passed:
                passed.append(asset.id)
            case .failed:
                failed.append(asset.id)
            case .timedOut:
                timedOut.append(asset.id)
            case .missingExit, .unknown:
                unverified.append(asset.id)
            }
        }

        self.passedAssetIds = passed.sorted()
        self.failedAssetIds = failed.sorted()
        self.timedOutAssetIds = timedOut.sorted()
        self.unverifiedAssetIds = unverified.sorted()
        self.latestRuns = runSummaries.sorted { $0.modifiedAt > $1.modifiedAt }
        self.latestRunAt = latestRuns.map(\.modifiedAt).max()
    }

    public var isReady: Bool {
        missingRequiredAssetIds.isEmpty
    }

    public var isVerified: Bool {
        requiredAssetCount > 0
            && missingRequiredAssetIds.isEmpty
            && failedAssetIds.isEmpty
            && timedOutAssetIds.isEmpty
            && unverifiedAssetIds.isEmpty
            && passedAssetIds.count == requiredAssetCount
    }
}

public struct TestCoverageRunSummary: Codable, Equatable, Sendable {
    public var assetId: String
    public var name: String
    public var outcome: TestRunOutcome
    public var modifiedAt: Date
    public var logPath: String
    public var summary: String

    public init(record: TestRunRecord) {
        self.assetId = record.assetId ?? record.id
        self.name = record.name
        self.outcome = record.outcome
        self.modifiedAt = record.modifiedAt
        self.logPath = record.logPath
        self.summary = record.summary
    }
}

public struct TestAssetService {
    public static let defaultRootPath = "/Users/a1-6/project/Mac-Win/refs/exe-tests"

    public var root: URL
    public var fileManager: FileManager

    public init(root: URL = URL(fileURLWithPath: Self.defaultRootPath), fileManager: FileManager = .default) {
        self.root = root
        self.fileManager = fileManager
    }

    public func report(includeHashes: Bool = false) -> TestAssetReport {
        let statuses = Self.defaultDefinitions.map { status(for: $0, includeHash: includeHashes) }
        return TestAssetReport(
            rootPath: root.path,
            statuses: statuses,
            runbook: runbook(statuses: statuses)
        )
    }

    public func runbook() -> TestAssetRunbook {
        let statuses = Self.defaultDefinitions.map { status(for: $0, includeHash: false) }
        return runbook(statuses: statuses)
    }

    public func runCommand(forAssetId assetId: String) -> TestAssetRunCommand? {
        runbook().groups
            .flatMap(\.commands)
            .first { $0.assetId == assetId }
    }

    public static func shellScript(for runbook: TestAssetRunbook) -> String {
        let buildCommand = runbook.buildCommand?.map(shellQuoted).joined(separator: " ")
        let suiteCommand = runbook.suiteCommand?.map(shellQuoted).joined(separator: " ")
        let groups = runbook.groups.flatMap(\.commands).filter { $0.command != nil }
        var lines = [
            "#!/usr/bin/env bash",
            "set -euo pipefail",
            "",
            "MODE=\"${1:-suite}\"",
            "",
            "case \"$MODE\" in"
        ]
        if let buildCommand {
            lines.append("  build)")
            lines.append("    exec \(buildCommand)")
            lines.append("    ;;")
        }
        if let suiteCommand {
            lines.append("  suite)")
            lines.append("    exec \(suiteCommand)")
            lines.append("    ;;")
        }
        lines.append("  list)")
        for group in runbook.groups {
            lines.append("    printf '%s\\n' \(shellQuoted("[\(group.category.rawValue)]"))")
            for command in group.commands {
                let runnable = command.command == nil ? "suite-only" : "single"
                let status = command.exists ? "present" : "missing"
                lines.append("    printf '%s\\n' \(shellQuoted("  \(command.assetId) \(status) \(runnable)"))")
            }
        }
        lines.append("    ;;")
        for command in groups {
            let commandLine = command.command?.map(shellQuoted).joined(separator: " ") ?? ""
            lines.append("  \(shellCaseLabel(command.assetId)))")
            lines.append("    exec \(commandLine)")
            lines.append("    ;;")
        }
        lines.append("  *)")
        lines.append("    echo \"usage: $0 [suite|build|list|\(groups.map(\.assetId).joined(separator: "|"))]\" >&2")
        lines.append("    exit 2")
        lines.append("    ;;")
        lines.append("esac")
        lines.append("")
        return lines.joined(separator: "\n")
    }

    public static func recommendedProbeIds(for issueReport: LogIssueReport) -> [String] {
        orderedUnique(
            issueReport.topIssues.flatMap(\.probeAssetIds)
                + issueReport.recentFailures.flatMap(\.probeAssetIds)
        )
    }

    public static func shellScript(forRecommendedProbes issueReport: LogIssueReport, runbook: TestAssetRunbook) -> String {
        let recommendedIds = recommendedProbeIds(for: issueReport)
        let commandsById = Dictionary(uniqueKeysWithValues: runbook.groups.flatMap(\.commands).map { ($0.assetId, $0) })
        let runnable = recommendedIds.compactMap { id -> TestAssetRunCommand? in
            guard let command = commandsById[id], command.exists, command.command != nil else { return nil }
            return command
        }
        let missing = recommendedIds.filter { id in
            guard let command = commandsById[id] else { return true }
            return !command.exists || command.command == nil
        }

        var lines = [
            "#!/usr/bin/env bash",
            "set -euo pipefail",
            "",
            "MODE=\"${1:-run}\"",
            "",
            "case \"$MODE\" in",
            "  list)"
        ]
        if recommendedIds.isEmpty {
            lines.append("    echo 'No recommended probes in the current log issue report.'")
        } else {
            for id in recommendedIds {
                if let command = commandsById[id] {
                    let state = command.exists && command.command != nil ? "runnable" : "unavailable"
                    let note = command.note.map { " \($0)" } ?? ""
                    lines.append("    printf '%s\\n' \(shellQuoted("\(id) \(state)\(note)"))")
                } else {
                    lines.append("    printf '%s\\n' \(shellQuoted("\(id) unavailable unknown probe id"))")
                }
            }
        }
        lines.append("    ;;")
        lines.append("  run)")
        if recommendedIds.isEmpty {
            lines.append("    echo 'No recommended probes to run.'")
            lines.append("    exit 0")
        } else {
            lines.append("    failures=0")
            for id in missing {
                lines.append("    echo \(shellQuoted("SKIP \(id): missing probe asset or single-probe runner"))")
            }
            for command in runnable {
                let commandLine = command.command?.map(shellQuoted).joined(separator: " ") ?? ""
                lines.append("    echo \(shellQuoted("== \(command.assetId) =="))")
                lines.append("    if ! \(commandLine); then")
                lines.append("      failures=$((failures + 1))")
                lines.append("    fi")
            }
            lines.append("    if (( failures > 0 )); then")
            lines.append("      echo \"Recommended probe failures: $failures\" >&2")
            lines.append("      exit 1")
            lines.append("    fi")
        }
        lines.append("    ;;")
        lines.append("  *)")
        lines.append("    echo 'usage: $0 [run|list]' >&2")
        lines.append("    exit 2")
        lines.append("    ;;")
        lines.append("esac")
        lines.append("")
        return lines.joined(separator: "\n")
    }

    public static func shellScript(forExecutionPlan plan: TestExecutionPlan) -> String {
        let runnable = plan.items.filter { $0.exists && !$0.command.isEmpty }
        let skipped = plan.items.filter { !$0.exists || $0.command.isEmpty }
        var lines = [
            "#!/usr/bin/env bash",
            "set -euo pipefail",
            "",
            "MODE=\"${1:-run}\"",
            "",
            "case \"$MODE\" in",
            "  list)"
        ]
        if plan.items.isEmpty {
            lines.append("    echo 'No test execution work is currently planned.'")
        } else {
            for item in plan.items {
                let state = item.exists && !item.command.isEmpty ? "runnable" : "unavailable"
                let reasons = item.reasons.map(\.rawValue).joined(separator: ",")
                lines.append("    printf '%s\\n' \(shellQuoted("\(item.assetId) \(item.priority.rawValue) \(state) \(reasons)"))")
            }
        }
        lines.append("    ;;")
        lines.append("  run)")
        if plan.items.isEmpty {
            lines.append("    echo 'No planned probes to run.'")
            lines.append("    exit 0")
        } else {
            lines.append("    failures=0")
            for item in skipped {
                let reasons = item.reasons.map(\.rawValue).joined(separator: ",")
                lines.append("    echo \(shellQuoted("SKIP \(item.assetId): \(reasons)"))")
            }
            for item in runnable {
                let commandLine = item.command.map(shellQuoted).joined(separator: " ")
                let reasons = item.reasons.map(\.rawValue).joined(separator: ",")
                lines.append("    echo \(shellQuoted("== \(item.assetId) (\(item.priority.rawValue): \(reasons)) =="))")
                lines.append("    if ! \(commandLine); then")
                lines.append("      failures=$((failures + 1))")
                lines.append("    fi")
            }
            lines.append("    if (( failures > 0 )); then")
            lines.append("      echo \"Planned probe failures: $failures\" >&2")
            lines.append("      exit 1")
            lines.append("    fi")
        }
        lines.append("    ;;")
        for item in runnable {
            let commandLine = item.command.map(shellQuoted).joined(separator: " ")
            lines.append("  \(shellCaseLabel(item.assetId)))")
            lines.append("    exec \(commandLine)")
            lines.append("    ;;")
        }
        lines.append("  *)")
        let runnableLabels = runnable.map(\.assetId).joined(separator: "|")
        let modes = runnableLabels.isEmpty ? "run|list" : "run|list|\(runnableLabels)"
        lines.append("    echo \(shellQuoted("usage: $0 [\(modes)]")) >&2")
        lines.append("    exit 2")
        lines.append("    ;;")
        lines.append("esac")
        lines.append("")
        return lines.joined(separator: "\n")
    }

    private func status(for definition: TestAssetDefinition, includeHash: Bool) -> TestAssetStatus {
        let url = root.appendingPathComponent(definition.relativePath)
        let exists = fileManager.fileExists(atPath: url.path)
        let byteCount = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init)
        let sha256: String?
        if includeHash, exists {
            sha256 = try? Hashing.sha256Hex(file: url)
        } else {
            sha256 = nil
        }

        return TestAssetStatus(
            id: definition.id,
            name: definition.name,
            kind: definition.kind,
            category: definition.category,
            architecture: definition.architecture,
            path: url.path,
            required: definition.required,
            exists: exists,
            byteCount: byteCount,
            sha256: sha256
        )
    }

    private func runbook(statuses: [TestAssetStatus]) -> TestAssetRunbook {
        let statusById = Dictionary(uniqueKeysWithValues: statuses.map { ($0.id, $0) })
        let missingRequiredIds = statuses.filter { $0.required && !$0.exists }.map(\.id).sorted()
        let buildURL = root.appendingPathComponent("build.sh")
        let suite = statusById["run-suite"]
        let single = statusById["run-one"]
        let buildCommand = fileManager.fileExists(atPath: buildURL.path) ? [buildURL.path] : nil
        let suiteCommand = suite?.exists == true ? [suite?.path ?? root.appendingPathComponent("run-suite.sh").path] : nil

        let executableStatuses = statuses.filter { $0.kind == .executable }
        let groups = DiagnosticCategory.allCases.compactMap { category -> TestAssetRunGroup? in
            let categoryStatuses = executableStatuses.filter { $0.category == category }
            guard !categoryStatuses.isEmpty else { return nil }
            let commands = categoryStatuses.map { status in
                runCommand(status: status, singleRunnerPath: single?.path, singleRunnerExists: single?.exists == true)
            }
            return TestAssetRunGroup(
                category: category,
                assetIds: categoryStatuses.map(\.id),
                commands: commands
            )
        }

        return TestAssetRunbook(
            rootPath: root.path,
            canRunSuite: suite?.exists == true && missingRequiredIds.isEmpty,
            missingRequiredAssetIds: missingRequiredIds,
            buildCommand: buildCommand,
            suiteCommand: suiteCommand,
            groups: groups
        )
    }

    private func runCommand(
        status: TestAssetStatus,
        singleRunnerPath: String?,
        singleRunnerExists: Bool
    ) -> TestAssetRunCommand {
        let probeName = URL(fileURLWithPath: status.path).deletingPathExtension().lastPathComponent
        let command: [String]?
        let note: String?
        if status.architecture == .i386 {
            if singleRunnerExists, let singleRunnerPath {
                command = [singleRunnerPath, "\(probeName)_win32"]
                note = "Requires a WoW64-capable engine and bin32 probe assets."
            } else {
                command = nil
                note = "run-one.sh is missing; run the full suite after restoring the runner."
            }
        } else if singleRunnerExists, let singleRunnerPath {
            command = [singleRunnerPath, probeName]
            note = nil
        } else {
            command = nil
            note = "run-one.sh is missing; run the full suite after restoring the runner."
        }
        return TestAssetRunCommand(
            assetId: status.id,
            name: status.name,
            architecture: status.architecture,
            executablePath: status.path,
            exists: status.exists,
            command: command,
            note: note
        )
    }

    private static func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private static func shellCaseLabel(_ value: String) -> String {
        value.replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "|", with: "")
            .replacingOccurrences(of: "\n", with: "")
    }

    private static func orderedUnique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for value in values where !seen.contains(value) {
            seen.insert(value)
            result.append(value)
        }
        return result
    }

    public static let defaultDefinitions: [TestAssetDefinition] = [
        TestAssetDefinition(
            id: "run-suite",
            name: "Probe Suite Runner",
            kind: .runner,
            category: .core,
            relativePath: "run-suite.sh"
        ),
        TestAssetDefinition(
            id: "run-one",
            name: "Single Probe Runner",
            kind: .runner,
            category: .core,
            relativePath: "run-one.sh"
        ),
        TestAssetDefinition(
            id: "console",
            name: "Win32 Console Probe",
            kind: .executable,
            category: .core,
            architecture: .x86_64,
            relativePath: "bin/00_console_probe.exe"
        ),
        TestAssetDefinition(
            id: "tls-winhttp",
            name: "WinHTTP TLS Probe",
            kind: .executable,
            category: .network,
            architecture: .x86_64,
            relativePath: "bin/10_tls_winhttp_probe.exe"
        ),
        TestAssetDefinition(
            id: "iphlpapi-adapters",
            name: "Network Adapter Probe",
            kind: .executable,
            category: .network,
            architecture: .x86_64,
            relativePath: "bin/15_iphlpapi_probe.exe"
        ),
        TestAssetDefinition(
            id: "tls-winhttp-win32",
            name: "WinHTTP TLS Probe (32-bit)",
            kind: .executable,
            category: .win32,
            architecture: .i386,
            relativePath: "bin32/10_tls_winhttp_probe.exe"
        ),
        TestAssetDefinition(
            id: "iphlpapi-adapters-win32",
            name: "Network Adapter Probe (32-bit)",
            kind: .executable,
            category: .win32,
            architecture: .i386,
            relativePath: "bin32/15_iphlpapi_probe.exe"
        ),
        TestAssetDefinition(
            id: "network-list-manager",
            name: "Network List Manager Probe",
            kind: .executable,
            category: .network,
            architecture: .x86_64,
            relativePath: "bin/92_network_list_probe.exe"
        ),
        TestAssetDefinition(
            id: "network-list-manager-win32",
            name: "Network List Manager Probe (32-bit)",
            kind: .executable,
            category: .win32,
            architecture: .i386,
            relativePath: "bin32/92_network_list_probe.exe"
        ),
        TestAssetDefinition(
            id: "vulkan",
            name: "Vulkan Device Probe",
            kind: .executable,
            category: .graphics,
            architecture: .x86_64,
            relativePath: "bin/20_vulkan_probe.exe"
        ),
        TestAssetDefinition(
            id: "d3d11",
            name: "D3D11 Device Probe",
            kind: .executable,
            category: .graphics,
            architecture: .x86_64,
            relativePath: "bin/30_d3d11_probe.exe"
        ),
        TestAssetDefinition(
            id: "d3d12-device",
            name: "D3D12 Device Probe",
            kind: .executable,
            category: .graphics,
            architecture: .x86_64,
            relativePath: "bin/35_d3d12_device_probe.exe"
        ),
        TestAssetDefinition(
            id: "xaudio2",
            name: "XAudio2 Probe",
            kind: .executable,
            category: .audio,
            architecture: .x86_64,
            relativePath: "bin/40_xaudio2_probe.exe"
        ),
        TestAssetDefinition(
            id: "d3d9-legacy",
            name: "D3D9 Legacy Probe",
            kind: .executable,
            category: .graphics,
            architecture: .x86_64,
            relativePath: "bin/45_d3d9_legacy_probe.exe"
        ),
        TestAssetDefinition(
            id: "game-loop",
            name: "D3D11 Game Loop Probe",
            kind: .executable,
            category: .game,
            architecture: .x86_64,
            relativePath: "bin/50_game_loop_probe.exe"
        ),
        TestAssetDefinition(
            id: "game-shader",
            name: "D3D11 Shader Game Loop Probe",
            kind: .executable,
            category: .game,
            architecture: .x86_64,
            relativePath: "bin/60_game_shader_probe.exe"
        ),
        TestAssetDefinition(
            id: "text-rendering",
            name: "GDI / DirectWrite Text Rendering Probe",
            kind: .executable,
            category: .core,
            architecture: .x86_64,
            relativePath: "bin/70_text_rendering_probe.exe"
        ),
        TestAssetDefinition(
            id: "window-input",
            name: "Win32 Window / Input Probe",
            kind: .executable,
            category: .windowing,
            architecture: .x86_64,
            relativePath: "bin/80_window_input_probe.exe"
        ),
        TestAssetDefinition(
            id: "ipc-file-mapping",
            name: "Win32 IPC / File Mapping Probe",
            kind: .executable,
            category: .core,
            architecture: .x86_64,
            relativePath: "bin/90_ipc_file_mapping_probe.exe",
            required: false
        ),
        TestAssetDefinition(
            id: "jasp-boost-ipc",
            name: "JASP Boost IPC Probe",
            kind: .executable,
            category: .core,
            architecture: .x86_64,
            relativePath: "bin/95_jasp_boost_ipc_probe.exe",
            required: false
        ),
        TestAssetDefinition(
            id: "jasp-special-float-eh",
            name: "JASP Special Float / C++ EH Probe",
            kind: .executable,
            category: .core,
            architecture: .x86_64,
            relativePath: "bin/96_jasp_special_float_eh_probe.exe",
            required: false
        ),
        TestAssetDefinition(
            id: "jasp-createprocess",
            name: "JASP CreateProcess Probe",
            kind: .executable,
            category: .core,
            architecture: .x86_64,
            relativePath: "bin/97_jasp_createprocess_probe.exe",
            required: false
        ),
        TestAssetDefinition(
            id: "console-source",
            name: "Win32 Console Probe Source",
            kind: .source,
            category: .core,
            relativePath: "src/00_console_probe.c"
        ),
        TestAssetDefinition(
            id: "vulkan-source",
            name: "Vulkan Probe Source",
            kind: .source,
            category: .graphics,
            relativePath: "src/20_vulkan_probe.c"
        ),
        TestAssetDefinition(
            id: "game-shader-source",
            name: "Shader Game Loop Source",
            kind: .source,
            category: .game,
            relativePath: "src/60_game_shader_probe.cpp"
        ),
        TestAssetDefinition(
            id: "text-rendering-source",
            name: "GDI / DirectWrite Text Rendering Probe Source",
            kind: .source,
            category: .core,
            relativePath: "src/70_text_rendering_probe.cpp"
        ),
        TestAssetDefinition(
            id: "window-input-source",
            name: "Win32 Window / Input Probe Source",
            kind: .source,
            category: .windowing,
            relativePath: "src/80_window_input_probe.cpp"
        ),
        TestAssetDefinition(
            id: "ipc-file-mapping-source",
            name: "Win32 IPC / File Mapping Probe Source",
            kind: .source,
            category: .core,
            relativePath: "src/90_ipc_file_mapping_probe.c",
            required: false
        ),
        TestAssetDefinition(
            id: "network-list-manager-source",
            name: "Network List Manager Probe Source",
            kind: .source,
            category: .network,
            relativePath: "src/92_network_list_probe.c",
            required: false
        ),
        TestAssetDefinition(
            id: "jasp-boost-ipc-source",
            name: "JASP Boost IPC Probe Source",
            kind: .source,
            category: .core,
            relativePath: "src/95_jasp_boost_ipc_probe.cpp",
            required: false
        ),
        TestAssetDefinition(
            id: "jasp-special-float-eh-source",
            name: "JASP Special Float / C++ EH Probe Source",
            kind: .source,
            category: .core,
            relativePath: "src/96_jasp_special_float_eh_probe.cpp",
            required: false
        ),
        TestAssetDefinition(
            id: "jasp-createprocess-source",
            name: "JASP CreateProcess Probe Source",
            kind: .source,
            category: .core,
            relativePath: "src/97_jasp_createprocess_probe.cpp",
            required: false
        )
    ]
}
