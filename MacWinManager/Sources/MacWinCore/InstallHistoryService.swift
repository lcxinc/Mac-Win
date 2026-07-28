import Foundation

public struct InstallHistoryReport: Codable, Equatable, Sendable {
    public var rootPath: String
    public var logsPath: String
    public var recordsPath: String
    public var totalTaskCount: Int
    public var succeededCount: Int
    public var failedCount: Int
    public var runningCount: Int
    public var launchedCount: Int
    public var stateCounts: [String: Int]
    public var latestStartedAt: Date?
    public var tasks: [InstallTask]

    public init(
        rootPath: String,
        logsPath: String,
        recordsPath: String,
        totalTaskCount: Int,
        succeededCount: Int,
        failedCount: Int,
        runningCount: Int,
        launchedCount: Int = 0,
        stateCounts: [String: Int],
        latestStartedAt: Date?,
        tasks: [InstallTask]
    ) {
        self.rootPath = rootPath
        self.logsPath = logsPath
        self.recordsPath = recordsPath
        self.totalTaskCount = totalTaskCount
        self.succeededCount = succeededCount
        self.failedCount = failedCount
        self.runningCount = runningCount
        self.launchedCount = launchedCount
        self.stateCounts = stateCounts
        self.latestStartedAt = latestStartedAt
        self.tasks = tasks
    }

    public static func csv(report: InstallHistoryReport?) -> String {
        let formatter = ISO8601DateFormatter()
        var rows: [[String]] = [[
            "id",
            "recipe_id",
            "bottle_id",
            "state",
            "progress_text",
            "started_at",
            "ended_at",
            "duration_ms",
            "exit_code",
            "log_path"
        ]]

        for task in report?.tasks ?? [] {
            let durationMilliseconds = task.endedAt.map {
                Int(($0.timeIntervalSince(task.startedAt) * 1000).rounded())
            }
            rows.append([
                task.id,
                task.recipeId,
                task.bottleId,
                task.state.rawValue,
                task.progressText,
                formatter.string(from: task.startedAt),
                task.endedAt.map { formatter.string(from: $0) } ?? "",
                durationMilliseconds.map(String.init) ?? "",
                task.exitCode.map(String.init) ?? "",
                task.logPath
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

public struct InstallHistoryService {
    public var paths: MacWinPaths
    public var fileManager: FileManager

    public init(paths: MacWinPaths = MacWinPaths(), fileManager: FileManager = .default) {
        self.paths = paths
        self.fileManager = fileManager
    }

    public func report(limit: Int = 100) -> InstallHistoryReport {
        let directory = Self.recordsDirectory(in: paths.logsDirectory)
        var tasks = readTasks(in: directory)
        tasks.sort { lhs, rhs in
            if lhs.startedAt == rhs.startedAt {
                return lhs.id > rhs.id
            }
            return lhs.startedAt > rhs.startedAt
        }
        if tasks.count > limit {
            tasks = Array(tasks.prefix(limit))
        }

        var stateCounts: [String: Int] = [:]
        for task in tasks {
            stateCounts[task.state.rawValue, default: 0] += 1
        }

        return InstallHistoryReport(
            rootPath: paths.root.path,
            logsPath: paths.logsDirectory.path,
            recordsPath: directory.path,
            totalTaskCount: tasks.count,
            succeededCount: tasks.filter { $0.state == .succeeded }.count,
            failedCount: tasks.filter { $0.state == .failed }.count,
            runningCount: tasks.filter { $0.state == .running }.count,
            launchedCount: tasks.filter { $0.state == .launched }.count,
            stateCounts: stateCounts,
            latestStartedAt: tasks.first?.startedAt,
            tasks: tasks
        )
    }

    public func save(_ task: InstallTask) throws {
        try fileManager.createDirectory(at: Self.recordsDirectory(in: paths.logsDirectory), withIntermediateDirectories: true)
        try JSONStore(fileManager: fileManager).save(task, to: recordURL(for: task))
    }

    public func recordURL(for task: InstallTask) -> URL {
        Self.recordURL(task: task, logsDirectory: paths.logsDirectory)
    }

    public static func recordsDirectory(in logsDirectory: URL) -> URL {
        logsDirectory.appendingPathComponent("InstallRecords", isDirectory: true)
    }

    public static func recordURL(task: InstallTask, logsDirectory: URL) -> URL {
        let name = "\(fileTimestamp(task.startedAt))-\(safeFileName(task.recipeId))-\(safeFileName(task.id)).install-task.json"
        return recordsDirectory(in: logsDirectory).appendingPathComponent(name)
    }

    private func readTasks(in directory: URL) -> [InstallTask] {
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
            guard url.lastPathComponent.hasSuffix(".install-task.json"),
                  (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else {
                return nil
            }
            return try? store.load(InstallTask.self, from: url)
        }
    }

    private static func safeFileName(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        let mapped = value.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let name = String(mapped).split(separator: "-").joined(separator: "-")
        return name.isEmpty ? "install" : name
    }

    private static func fileTimestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter.string(from: date).replacingOccurrences(of: ":", with: "")
    }
}
