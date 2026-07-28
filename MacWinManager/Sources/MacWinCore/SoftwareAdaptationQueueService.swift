import Foundation

public enum SoftwareAdaptationProbeState: String, Codable, Equatable, Sendable {
    case runnable
    case unavailable
}

public struct SoftwareAdaptationProbe: Codable, Equatable, Identifiable, Sendable {
    public var id: String { assetId }
    public var assetId: String
    public var state: SoftwareAdaptationProbeState
    public var command: [String]
    public var note: String?

    public init(assetId: String, state: SoftwareAdaptationProbeState, command: [String], note: String? = nil) {
        self.assetId = assetId
        self.state = state
        self.command = command
        self.note = note
    }
}

public struct SoftwareAdaptationTask: Codable, Equatable, Identifiable, Sendable {
    public var id: String { recipeId }
    public var recipeId: String
    public var name: String
    public var category: String
    public var compatibilityRating: CompatibilityRating
    public var state: SoftwareTestPlanState
    public var stage: SoftwareSmokeStage
    public var severity: SoftwareSmokeCheckState
    public var priority: Int
    public var nextAction: String
    public var latestLogPath: String?
    public var latestLaunchLogPath: String?
    public var probableIssueIds: [String]
    public var blockers: [String]
    public var recommendedProbeIds: [String]
    public var runnableProbeCount: Int
    public var unavailableProbeCount: Int
    public var probes: [SoftwareAdaptationProbe]

    public init(
        recipeId: String,
        name: String,
        category: String,
        compatibilityRating: CompatibilityRating,
        state: SoftwareTestPlanState,
        stage: SoftwareSmokeStage,
        severity: SoftwareSmokeCheckState,
        priority: Int,
        nextAction: String,
        latestLogPath: String?,
        latestLaunchLogPath: String?,
        probableIssueIds: [String],
        blockers: [String],
        recommendedProbeIds: [String],
        probes: [SoftwareAdaptationProbe]
    ) {
        self.recipeId = recipeId
        self.name = name
        self.category = category
        self.compatibilityRating = compatibilityRating
        self.state = state
        self.stage = stage
        self.severity = severity
        self.priority = priority
        self.nextAction = nextAction
        self.latestLogPath = latestLogPath
        self.latestLaunchLogPath = latestLaunchLogPath
        self.probableIssueIds = probableIssueIds
        self.blockers = blockers
        self.recommendedProbeIds = recommendedProbeIds
        self.runnableProbeCount = probes.filter { $0.state == .runnable }.count
        self.unavailableProbeCount = probes.filter { $0.state == .unavailable }.count
        self.probes = probes
    }
}

public struct SoftwareAdaptationQueueReport: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var rootPath: String
    public var taskCount: Int
    public var runnableTaskCount: Int
    public var blockedTaskCount: Int
    public var runnableProbeCount: Int
    public var unavailableProbeCount: Int
    public var tasks: [SoftwareAdaptationTask]

    public init(generatedAt: Date, rootPath: String, tasks: [SoftwareAdaptationTask]) {
        self.generatedAt = generatedAt
        self.rootPath = rootPath
        self.taskCount = tasks.count
        self.runnableTaskCount = tasks.filter { $0.runnableProbeCount > 0 }.count
        self.blockedTaskCount = tasks.filter { $0.severity == .blocked || $0.severity == .failed }.count
        self.runnableProbeCount = tasks.map(\.runnableProbeCount).reduce(0, +)
        self.unavailableProbeCount = tasks.map(\.unavailableProbeCount).reduce(0, +)
        self.tasks = tasks
    }
}

public struct SoftwareAdaptationQueueService {
    public var paths: MacWinPaths

    public init(paths: MacWinPaths = MacWinPaths()) {
        self.paths = paths
    }

    public func report(
        softwareTestPlan: SoftwareTestPlanReport,
        softwareSmokeMatrix: SoftwareSmokeMatrixReport,
        logIssues: LogIssueReport,
        testAssets: TestAssetReport,
        generatedAt: Date = Date()
    ) -> SoftwareAdaptationQueueReport {
        Self.report(
            rootPath: paths.root.path,
            softwareTestPlan: softwareTestPlan,
            softwareSmokeMatrix: softwareSmokeMatrix,
            logIssues: logIssues,
            testAssets: testAssets,
            generatedAt: generatedAt
        )
    }

    public static func report(
        rootPath: String,
        softwareTestPlan: SoftwareTestPlanReport,
        softwareSmokeMatrix: SoftwareSmokeMatrixReport,
        logIssues: LogIssueReport,
        testAssets: TestAssetReport,
        generatedAt: Date = Date()
    ) -> SoftwareAdaptationQueueReport {
        let rowsByRecipe = Dictionary(uniqueKeysWithValues: softwareSmokeMatrix.rows.map { ($0.recipeId, $0) })
        let commandsById = Dictionary(uniqueKeysWithValues: (testAssets.runbook?.groups.flatMap(\.commands) ?? []).map { ($0.assetId, $0) })
        let samplesByPath = Dictionary(uniqueKeysWithValues: logIssues.recentFailures.map { (canonicalPath($0.path), $0) })
        let issueProbeIds = probeIdsByIssue(logIssues: logIssues)
        let tasks = softwareTestPlan.entries
            .filter { $0.state != .verified && $0.state != .disabled }
            .compactMap { entry -> SoftwareAdaptationTask? in
                guard let row = rowsByRecipe[entry.recipeId] else { return nil }
                let probeIds = recommendedProbeIds(
                    entry: entry,
                    row: row,
                    samplesByPath: samplesByPath,
                    issueProbeIds: issueProbeIds
                )
                let probes = probeIds.map { probe(assetId: $0, commandsById: commandsById) }
                return SoftwareAdaptationTask(
                    recipeId: entry.recipeId,
                    name: entry.name,
                    category: entry.category,
                    compatibilityRating: entry.compatibilityRating,
                    state: entry.state,
                    stage: row.stage,
                    severity: row.highestSeverity,
                    priority: entry.priority,
                    nextAction: row.nextAction,
                    latestLogPath: row.latestLogPath,
                    latestLaunchLogPath: row.latestLaunchLogPath,
                    probableIssueIds: entry.probableIssueIds,
                    blockers: entry.blockers,
                    recommendedProbeIds: probeIds,
                    probes: probes
                )
            }
            .sorted { lhs, rhs in
                let lhsRank = severityRank(lhs.severity)
                let rhsRank = severityRank(rhs.severity)
                if lhsRank != rhsRank { return lhsRank < rhsRank }
                if lhs.priority != rhs.priority { return lhs.priority < rhs.priority }
                return lhs.recipeId < rhs.recipeId
            }
        return SoftwareAdaptationQueueReport(generatedAt: generatedAt, rootPath: rootPath, tasks: tasks)
    }

    public static func csv(report: SoftwareAdaptationQueueReport) -> String {
        let formatter = ISO8601DateFormatter()
        var rows: [[String]] = [[
            "recipe_id",
            "name",
            "category",
            "compatibility_rating",
            "state",
            "stage",
            "severity",
            "priority",
            "next_action",
            "latest_log_path",
            "latest_launch_log_path",
            "probable_issue_ids",
            "blockers",
            "recommended_probe_ids",
            "runnable_probe_count",
            "unavailable_probe_count",
            "generated_at"
        ]]
        for task in report.tasks {
            rows.append([
                task.recipeId,
                task.name,
                task.category,
                task.compatibilityRating.rawValue,
                task.state.rawValue,
                task.stage.rawValue,
                task.severity.rawValue,
                String(task.priority),
                task.nextAction,
                task.latestLogPath ?? "",
                task.latestLaunchLogPath ?? "",
                task.probableIssueIds.joined(separator: ";"),
                task.blockers.joined(separator: ";"),
                task.recommendedProbeIds.joined(separator: ";"),
                String(task.runnableProbeCount),
                String(task.unavailableProbeCount),
                formatter.string(from: report.generatedAt)
            ])
        }
        return rows.map { $0.map(csvEscaped).joined(separator: ",") }.joined(separator: "\n") + "\n"
    }

    public static func markdown(report: SoftwareAdaptationQueueReport) -> String {
        let formatter = ISO8601DateFormatter()
        var lines = [
            "# MacWin Software Adaptation Queue",
            "",
            "- Generated: \(formatter.string(from: report.generatedAt))",
            "- Root: `\(report.rootPath)`",
            "- Tasks: \(report.taskCount)",
            "- Runnable tasks: \(report.runnableTaskCount)",
            "- Blocked or failing tasks: \(report.blockedTaskCount)",
            "- Runnable probes: \(report.runnableProbeCount)",
            "- Unavailable probes: \(report.unavailableProbeCount)",
            "",
            "## Tasks",
            ""
        ]

        if report.tasks.isEmpty {
            lines.append("No software adaptation tasks are currently pending.")
        } else {
            for task in report.tasks {
                lines.append("### \(markdownEscaped(task.name))")
                lines.append("")
                lines.append("- Recipe: `\(task.recipeId)`")
                lines.append("- Category: \(markdownEscaped(task.category))")
                lines.append("- Compatibility: `\(task.compatibilityRating.rawValue)`")
                lines.append("- State: `\(task.state.rawValue)`")
                lines.append("- Stage: `\(task.stage.rawValue)`")
                lines.append("- Severity: `\(task.severity.rawValue)`")
                lines.append("- Priority: \(task.priority)")
                lines.append("- Next action: \(markdownEscaped(task.nextAction))")
                if let latestLogPath = task.latestLogPath {
                    lines.append("- Latest log: `\(latestLogPath)`")
                }
                if let latestLaunchLogPath = task.latestLaunchLogPath, latestLaunchLogPath != task.latestLogPath {
                    lines.append("- Latest launch log: `\(latestLaunchLogPath)`")
                }
                if !task.probableIssueIds.isEmpty {
                    lines.append("- Probable issues: \(task.probableIssueIds.map { "`\($0)`" }.joined(separator: ", "))")
                }
                if !task.blockers.isEmpty {
                    lines.append("- Blockers: \(task.blockers.map { "`\($0)`" }.joined(separator: ", "))")
                }
                if !task.recommendedProbeIds.isEmpty {
                    lines.append("- Recommended probes: \(task.recommendedProbeIds.map { "`\($0)`" }.joined(separator: ", "))")
                }
                if task.probes.isEmpty {
                    lines.append("- Probe commands: none")
                } else {
                    lines.append("- Probe commands:")
                    for probe in task.probes {
                        let state = probe.state.rawValue
                        if probe.command.isEmpty {
                            let note = probe.note.map { " - \(markdownEscaped($0))" } ?? ""
                            lines.append("  - `\(probe.assetId)` \(state)\(note)")
                        } else {
                            lines.append("  - `\(probe.assetId)` \(state): `\(probe.command.joined(separator: " "))`")
                        }
                    }
                }
                lines.append("")
            }
        }

        return lines.joined(separator: "\n")
    }

    public static func shellScript(report: SoftwareAdaptationQueueReport) -> String {
        var lines = [
            "#!/usr/bin/env bash",
            "set -euo pipefail",
            "",
            "MODE=\"${1:-list}\"",
            "",
            "case \"$MODE\" in",
            "  list)"
        ]
        if report.tasks.isEmpty {
            lines.append("    echo 'No software adaptation tasks are currently pending.'")
        } else {
            for task in report.tasks {
                let probes = task.recommendedProbeIds.isEmpty ? "none" : task.recommendedProbeIds.joined(separator: ",")
                lines.append("    printf '%s\\n' \(shellQuoted("\(task.recipeId) \(task.severity.rawValue) \(task.stage.rawValue) probes=\(probes)"))")
            }
        }
        lines.append("    ;;")
        lines.append("  run)")
        lines.append("    failures=0")
        if report.tasks.isEmpty {
            lines.append("    echo 'No adaptation probes to run.'")
        } else {
            for task in report.tasks {
                if task.probes.isEmpty {
                    lines.append("    echo \(shellQuoted("SKIP \(task.recipeId): no recommended probes"))")
                }
                for probe in task.probes where probe.state == .unavailable {
                    let note = probe.note.map { ": \($0)" } ?? ""
                    lines.append("    echo \(shellQuoted("SKIP \(task.recipeId)/\(probe.assetId)\(note)"))")
                }
                for probe in task.probes where probe.state == .runnable {
                    let commandLine = probe.command.map(shellQuoted).joined(separator: " ")
                    lines.append("    echo \(shellQuoted("== \(task.recipeId): \(probe.assetId) =="))")
                    lines.append("    if ! \(commandLine); then")
                    lines.append("      failures=$((failures + 1))")
                    lines.append("    fi")
                }
            }
        }
        lines.append("    if (( failures > 0 )); then")
        lines.append("      echo \"Adaptation probe failures: $failures\" >&2")
        lines.append("      exit 1")
        lines.append("    fi")
        lines.append("    ;;")
        for task in report.tasks {
            lines.append("  \(shellCaseLabel(task.recipeId)))")
            let runnable = task.probes.filter { $0.state == .runnable }
            if runnable.isEmpty {
                lines.append("    echo \(shellQuoted("No runnable probes for \(task.recipeId)."))")
                lines.append("    exit 0")
            } else {
                lines.append("    failures=0")
                for probe in runnable {
                    let commandLine = probe.command.map(shellQuoted).joined(separator: " ")
                    lines.append("    echo \(shellQuoted("== \(task.recipeId): \(probe.assetId) =="))")
                    lines.append("    if ! \(commandLine); then")
                    lines.append("      failures=$((failures + 1))")
                    lines.append("    fi")
                }
                lines.append("    exit \"$failures\"")
            }
            lines.append("    ;;")
        }
        lines.append("  *)")
        let taskLabels = report.tasks.map(\.recipeId).map(shellCaseLabel).joined(separator: "|")
        let modes = taskLabels.isEmpty ? "list|run" : "list|run|\(taskLabels)"
        lines.append("    echo \(shellQuoted("usage: $0 [\(modes)]")) >&2")
        lines.append("    exit 2")
        lines.append("    ;;")
        lines.append("esac")
        lines.append("")
        return lines.joined(separator: "\n")
    }

    private static func recommendedProbeIds(
        entry: SoftwareTestPlanEntry,
        row: SoftwareSmokeMatrixRow,
        samplesByPath: [String: LogIssueSample],
        issueProbeIds: [String: [String]]
    ) -> [String] {
        var ids: [String] = []
        let paths = [entry.latestInstallLogPath, entry.latestLaunchLogPath, row.latestLogPath, row.latestLaunchLogPath]
            .compactMap { $0 }
            .map(canonicalPath)
        let samples = paths.compactMap { samplesByPath[$0] }
        ids.append(contentsOf: samples.flatMap { $0.probeAssetIds })
        let issueIds = orderedUnique(entry.probableIssueIds + samples.flatMap { $0.probableIssueIds } + entry.blockers)
        for issueId in issueIds {
            ids.append(contentsOf: issueProbeIds[issueId] ?? defaultProbeIds(forIssue: issueId))
        }
        switch entry.state {
        case .launchFailed:
            ids.append(contentsOf: ["console", "window-input"])
        case .needsReview:
            ids.append("console")
        case .installFailed:
            ids.append("console")
        case .installedNotLaunched:
            ids.append("console")
        default:
            break
        }
        if entry.requiresWin32 {
            ids.append(contentsOf: win32ProbeIds(forIssues: issueIds))
        }
        return orderedUnique(ids)
    }

    private static func probe(assetId: String, commandsById: [String: TestAssetRunCommand]) -> SoftwareAdaptationProbe {
        guard let command = commandsById[assetId] else {
            return SoftwareAdaptationProbe(assetId: assetId, state: .unavailable, command: [], note: "Probe is not present in the current test runbook.")
        }
        guard command.exists, let commandLine = command.command, !commandLine.isEmpty else {
            return SoftwareAdaptationProbe(assetId: assetId, state: .unavailable, command: [], note: command.note ?? "Probe asset or runner is missing.")
        }
        return SoftwareAdaptationProbe(assetId: assetId, state: .runnable, command: commandLine, note: command.note)
    }

    private static func probeIdsByIssue(logIssues: LogIssueReport) -> [String: [String]] {
        var result: [String: [String]] = [:]
        for trend in logIssues.topIssues {
            result[trend.id, default: []].append(contentsOf: trend.probeAssetIds)
        }
        for sample in logIssues.recentFailures {
            for issueId in sample.probableIssueIds {
                result[issueId, default: []].append(contentsOf: sample.probeAssetIds)
            }
        }
        return result.mapValues(orderedUnique)
    }

    private static func defaultProbeIds(forIssue issueId: String) -> [String] {
        switch issueId {
        case "network-tls":
            return ["tls-winhttp", "iphlpapi-adapters"]
        case "graphics-runtime", "blank-window":
            return ["vulkan", "d3d11", "d3d12-device", "game-shader"]
        case "text-rendering":
            return ["text-rendering"]
        case "window-input":
            return ["window-input"]
        case "audio":
            return ["xaudio2"]
        case "msi-runtime", "missing-builtin-dll", "wine-crash", "unclassified-failure":
            return ["console"]
        case "chrome-omaha-installer":
            return ["console", "tls-winhttp", "text-rendering"]
        default:
            return []
        }
    }

    private static func win32ProbeIds(forIssues issueIds: [String]) -> [String] {
        guard issueIds.contains("network-tls") else { return [] }
        return ["tls-winhttp-win32", "iphlpapi-adapters-win32"]
    }

    private static func severityRank(_ state: SoftwareSmokeCheckState) -> Int {
        switch state {
        case .failed: 0
        case .blocked: 1
        case .warning: 2
        case .pending: 3
        case .passed: 4
        case .notApplicable: 5
        }
    }

    private static func canonicalPath(_ path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath().path
    }

    private static func csvEscaped(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    private static func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private static func markdownEscaped(_ value: String) -> String {
        value.replacingOccurrences(of: "\n", with: " ")
    }

    private static func shellCaseLabel(_ value: String) -> String {
        value
            .replacingOccurrences(of: ")", with: "")
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
}
