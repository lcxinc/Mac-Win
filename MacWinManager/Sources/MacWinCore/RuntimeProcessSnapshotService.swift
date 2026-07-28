import Foundation

public struct RuntimeProcessSnapshot: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var report: RuntimeProcessAuditReport

    public init(generatedAt: Date, report: RuntimeProcessAuditReport) {
        self.generatedAt = generatedAt
        self.report = report
    }
}

public struct RuntimeProcessSnapshotArtifact: Equatable, Sendable {
    public var jsonURL: URL
    public var logURL: URL
    public var snapshot: RuntimeProcessSnapshot

    public init(jsonURL: URL, logURL: URL, snapshot: RuntimeProcessSnapshot) {
        self.jsonURL = jsonURL
        self.logURL = logURL
        self.snapshot = snapshot
    }
}

public struct RuntimeProcessSnapshotService {
    public var paths: MacWinPaths
    public var fileManager: FileManager
    public var store: JSONStore

    public init(paths: MacWinPaths = MacWinPaths(), fileManager: FileManager = .default) {
        self.paths = paths
        self.fileManager = fileManager
        self.store = JSONStore(fileManager: fileManager)
    }

    @discardableResult
    public func writeSnapshot(
        report: RuntimeProcessAuditReport,
        generatedAt: Date = Date()
    ) throws -> RuntimeProcessSnapshotArtifact {
        try paths.ensureBaseDirectories(fileManager: fileManager)
        let baseName = "runtime-processes-\(Self.fileTimestamp(generatedAt))"
        let jsonURL = paths.logsDirectory.appendingPathComponent("\(baseName).json")
        let logURL = paths.logsDirectory.appendingPathComponent("\(baseName).log")
        let snapshot = RuntimeProcessSnapshot(generatedAt: generatedAt, report: report)
        try store.save(snapshot, to: jsonURL)
        try Self.logText(snapshot: snapshot, jsonURL: jsonURL).write(to: logURL, atomically: true, encoding: .utf8)
        return RuntimeProcessSnapshotArtifact(jsonURL: jsonURL, logURL: logURL, snapshot: snapshot)
    }

    public static func logText(snapshot: RuntimeProcessSnapshot, jsonURL: URL) -> String {
        let formatter = ISO8601DateFormatter()
        let report = snapshot.report
        var lines = [
            "----- MacWin runtime process snapshot -----",
            "generatedAt=\(formatter.string(from: snapshot.generatedAt))",
            "jsonPath=\(jsonURL.path)",
            "observedProcessCount=\(report.observedProcessCount)",
            "auditedProcessCount=\(report.auditedProcessCount)",
            "staleRenderingProcessCount=\(report.staleRenderingProcessCount)",
            "findingCount=\(report.findings.count)"
        ]

        if report.findings.isEmpty {
            lines.append("status=ok")
        } else {
            lines.append("status=attention")
            for finding in report.findings {
                lines.append("warn: runtime-process-finding id=\(finding.id) severity=\(finding.severity) pids=\(finding.affectedProcessIdentifiers.map(String.init).joined(separator: ","))")
                lines.append("detail=\(finding.detail)")
                if !finding.flags.isEmpty {
                    lines.append("flags=\(finding.flags.joined(separator: ","))")
                }
            }
        }

        for entry in report.entries {
            lines.append("process pid=\(entry.processIdentifier) kind=\(entry.kind.rawValue) executable=\(entry.executableName)")
            if !entry.staleRenderingFlags.isEmpty {
                lines.append("processStaleFlags=\(entry.staleRenderingFlags.joined(separator: ","))")
            }
            lines.append("command=\(entry.commandPreview)")
        }

        lines.append("-------------------------------------------")
        lines.append("")
        return lines.joined(separator: "\n")
    }

    private static func fileTimestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter.string(from: date).replacingOccurrences(of: ":", with: "")
    }
}
