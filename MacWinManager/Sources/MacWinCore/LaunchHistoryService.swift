import Foundation

public enum WineLaunchMode: String, Codable, Equatable, Sendable {
    case foregroundRun
    case detached
}

public enum WineLaunchState: String, Codable, Equatable, Sendable {
    case started
    case completed
    case failedToLaunch
}

public struct WineLaunchRecord: Codable, Equatable, Identifiable, Sendable {
    public var schemaVersion: Int
    public var id: String
    public var mode: WineLaunchMode
    public var state: WineLaunchState
    public var logPath: String
    public var startedAt: Date
    public var endedAt: Date?
    public var durationMilliseconds: Int?
    public var processIdentifier: Int32?
    public var exitCode: Int32?
    public var bottleId: String
    public var bottleName: String
    public var engineId: String
    public var winePath: String
    public var exe: String
    public var args: [String]
    public var commandLine: [String]
    public var workingDirectory: String
    public var environment: [String: String]
    public var errorMessage: String?

    public init(
        schemaVersion: Int = 1,
        id: String,
        mode: WineLaunchMode,
        state: WineLaunchState,
        logPath: String,
        startedAt: Date,
        endedAt: Date? = nil,
        durationMilliseconds: Int? = nil,
        processIdentifier: Int32? = nil,
        exitCode: Int32? = nil,
        bottleId: String,
        bottleName: String,
        engineId: String,
        winePath: String,
        exe: String,
        args: [String],
        commandLine: [String],
        workingDirectory: String,
        environment: [String: String],
        errorMessage: String? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.mode = mode
        self.state = state
        self.logPath = logPath
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationMilliseconds = durationMilliseconds
        self.processIdentifier = processIdentifier
        self.exitCode = exitCode
        self.bottleId = bottleId
        self.bottleName = bottleName
        self.engineId = engineId
        self.winePath = winePath
        self.exe = exe
        self.args = args
        self.commandLine = commandLine
        self.workingDirectory = workingDirectory
        self.environment = environment
        self.errorMessage = errorMessage
    }
}

public struct LaunchHistoryReport: Codable, Equatable, Sendable {
    public var rootPath: String
    public var logsPath: String
    public var recordsPath: String
    public var totalLaunchCount: Int
    public var completedCount: Int
    public var detachedCount: Int
    public var failedToLaunchCount: Int
    public var stateCounts: [String: Int]
    public var latestStartedAt: Date?
    public var records: [WineLaunchRecord]

    public init(
        rootPath: String,
        logsPath: String,
        recordsPath: String,
        totalLaunchCount: Int,
        completedCount: Int,
        detachedCount: Int,
        failedToLaunchCount: Int,
        stateCounts: [String: Int],
        latestStartedAt: Date?,
        records: [WineLaunchRecord]
    ) {
        self.rootPath = rootPath
        self.logsPath = logsPath
        self.recordsPath = recordsPath
        self.totalLaunchCount = totalLaunchCount
        self.completedCount = completedCount
        self.detachedCount = detachedCount
        self.failedToLaunchCount = failedToLaunchCount
        self.stateCounts = stateCounts
        self.latestStartedAt = latestStartedAt
        self.records = records
    }

    public static func csv(report: LaunchHistoryReport?) -> String {
        let formatter = ISO8601DateFormatter()
        var rows: [[String]] = [[
            "id",
            "mode",
            "state",
            "started_at",
            "ended_at",
            "duration_ms",
            "pid",
            "exit_code",
            "bottle_id",
            "bottle_name",
            "engine_id",
            "exe",
            "args",
            "log_path",
            "working_directory",
            "wine_path",
            "command_line",
            "compat_profile",
            "graphics_config",
            "dll_overrides",
            "error_message"
        ]]

        for record in report?.records ?? [] {
            rows.append([
                record.id,
                record.mode.rawValue,
                record.state.rawValue,
                formatter.string(from: record.startedAt),
                record.endedAt.map { formatter.string(from: $0) } ?? "",
                record.durationMilliseconds.map(String.init) ?? "",
                record.processIdentifier.map(String.init) ?? "",
                record.exitCode.map(String.init) ?? "",
                record.bottleId,
                record.bottleName,
                record.engineId,
                record.exe,
                record.args.joined(separator: " "),
                record.logPath,
                record.workingDirectory,
                record.winePath,
                record.commandLine.joined(separator: " "),
                record.environment["MACWIN_COMPAT_PROFILE"] ?? "",
                record.environment["WINE_D3D_CONFIG"] ?? "",
                record.environment["WINEDLLOVERRIDES"] ?? "",
                record.errorMessage ?? ""
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

public struct LaunchHistoryService {
    public var paths: MacWinPaths
    public var fileManager: FileManager

    public init(paths: MacWinPaths = MacWinPaths(), fileManager: FileManager = .default) {
        self.paths = paths
        self.fileManager = fileManager
    }

    public func report(limit: Int = 100) -> LaunchHistoryReport {
        let directory = Self.recordsDirectory(in: paths.logsDirectory)
        var records = Self.records(in: paths.logsDirectory, fileManager: fileManager)
        records.sort { lhs, rhs in
            if lhs.startedAt == rhs.startedAt {
                return lhs.id > rhs.id
            }
            return lhs.startedAt > rhs.startedAt
        }
        if records.count > limit {
            records = Array(records.prefix(limit))
        }

        var stateCounts: [String: Int] = [:]
        for record in records {
            stateCounts[record.state.rawValue, default: 0] += 1
        }

        return LaunchHistoryReport(
            rootPath: paths.root.path,
            logsPath: paths.logsDirectory.path,
            recordsPath: directory.path,
            totalLaunchCount: records.count,
            completedCount: records.filter { $0.state == .completed }.count,
            detachedCount: records.filter { $0.mode == .detached }.count,
            failedToLaunchCount: records.filter { $0.state == .failedToLaunch }.count,
            stateCounts: stateCounts,
            latestStartedAt: records.first?.startedAt,
            records: records
        )
    }

    public static func recordsDirectory(in logsDirectory: URL) -> URL {
        logsDirectory.appendingPathComponent("LaunchRecords", isDirectory: true)
    }

    public static func records(in logsDirectory: URL, fileManager: FileManager = .default) -> [WineLaunchRecord] {
        readRecords(in: recordsDirectory(in: logsDirectory), fileManager: fileManager)
    }

    public static func replayShellScript(for report: LaunchHistoryReport, limit: Int = 24) -> String {
        let records = Array(report.records.prefix(max(0, limit)))
        var lines = [
            "#!/usr/bin/env bash",
            "set -euo pipefail",
            "",
            "MODE=\"${1:-list}\"",
            "TARGET=\"${2:-}\"",
            "",
            "if [[ \"$MODE\" == \"list\" ]]; then"
        ]
        if records.isEmpty {
            lines.append("  echo 'No launch records are available in this support bundle.'")
        } else {
            for record in records {
                let exitCode = record.exitCode.map(String.init) ?? "-"
                let summary = "\(record.id) state=\(record.state.rawValue) exit=\(exitCode) bottle=\(record.bottleName) exe=\(record.exe)"
                lines.append("  printf '%s\\n' \(shellQuoted(summary))")
            }
        }
        lines.append("  exit 0")
        lines.append("fi")
        lines.append("")
        lines.append("if [[ \"$MODE\" != \"run\" ]]; then")
        lines.append("  echo 'usage: $0 [list|run <launch-id>]' >&2")
        lines.append("  exit 2")
        lines.append("fi")
        lines.append("")
        lines.append("if [[ -z \"$TARGET\" ]]; then")
        lines.append("  echo 'usage: $0 run <launch-id>' >&2")
        lines.append("  exit 2")
        lines.append("fi")
        lines.append("")
        for record in records {
            lines.append("if [[ \"$TARGET\" == \(shellQuoted(record.id)) ]]; then")
            lines.append("  cd \(shellQuoted(record.workingDirectory))")
            for key in record.environment.keys.sorted() where isSafeEnvironmentKey(key) {
                guard let value = record.environment[key] else { continue }
                lines.append("  export \(key)=\(shellQuoted(value))")
            }
            if record.commandLine.isEmpty {
                lines.append("  echo \(shellQuoted("Launch record \(record.id) does not contain a command line.")) >&2")
                lines.append("  exit 2")
            } else {
                lines.append("  exec \(record.commandLine.map(shellQuoted).joined(separator: " "))")
            }
            lines.append("fi")
            lines.append("")
        }
        lines.append("echo \"Unknown launch id: $TARGET\" >&2")
        lines.append("echo 'Available launch ids:' >&2")
        for record in records {
            lines.append("echo \(shellQuoted("  \(record.id)")) >&2")
        }
        lines.append("exit 2")
        lines.append("")
        return lines.joined(separator: "\n")
    }

    private static func readRecords(in directory: URL, fileManager: FileManager) -> [WineLaunchRecord] {
        guard fileManager.fileExists(atPath: directory.path),
              let urls = try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
              ) else {
            return []
        }

        let store = JSONStore(fileManager: fileManager)
        return urls.compactMap { url in
            guard url.lastPathComponent.hasSuffix(".launch.json"),
                  (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else {
                return nil
            }
            return try? store.load(WineLaunchRecord.self, from: url)
        }
    }

    private static func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private static func isSafeEnvironmentKey(_ key: String) -> Bool {
        guard let first = key.unicodeScalars.first,
              CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_").contains(first) else {
            return false
        }
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_")
        return key.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
}
