import Foundation

public enum DiagnosticArtifactKind: String, Codable, CaseIterable, Equatable, Sendable {
    case log
    case report
    case table
    case script
    case bundle
    case record
    case other
}

public struct DiagnosticArtifactItem: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var kind: DiagnosticArtifactKind
    public var name: String
    public var path: String
    public var relativePath: String
    public var parentDirectory: String
    public var modifiedAt: Date
    public var byteCount: Int64
    public var isExecutable: Bool

    public init(
        id: String,
        kind: DiagnosticArtifactKind,
        name: String,
        path: String,
        relativePath: String,
        parentDirectory: String,
        modifiedAt: Date,
        byteCount: Int64,
        isExecutable: Bool
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.path = path
        self.relativePath = relativePath
        self.parentDirectory = parentDirectory
        self.modifiedAt = modifiedAt
        self.byteCount = byteCount
        self.isExecutable = isExecutable
    }
}

public struct DiagnosticArtifactIndexReport: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var rootPath: String
    public var logsPath: String
    public var artifactCount: Int
    public var totalBytes: Int64
    public var kindCounts: [DiagnosticArtifactKind: Int]
    public var artifacts: [DiagnosticArtifactItem]

    public init(
        generatedAt: Date,
        rootPath: String,
        logsPath: String,
        artifactCount: Int,
        totalBytes: Int64,
        kindCounts: [DiagnosticArtifactKind: Int],
        artifacts: [DiagnosticArtifactItem]
    ) {
        self.generatedAt = generatedAt
        self.rootPath = rootPath
        self.logsPath = logsPath
        self.artifactCount = artifactCount
        self.totalBytes = totalBytes
        self.kindCounts = kindCounts
        self.artifacts = artifacts
    }

    public static func empty(paths: MacWinPaths = MacWinPaths()) -> DiagnosticArtifactIndexReport {
        DiagnosticArtifactIndexReport(
            generatedAt: Date(),
            rootPath: paths.root.path,
            logsPath: paths.logsDirectory.path,
            artifactCount: 0,
            totalBytes: 0,
            kindCounts: [:],
            artifacts: []
        )
    }

    public static func csv(report: DiagnosticArtifactIndexReport) -> String {
        var rows: [[String]] = [[
            "row_type",
            "kind",
            "name",
            "relative_path",
            "path",
            "parent_directory",
            "modified_at",
            "byte_count",
            "is_executable",
            "artifact_count",
            "total_bytes"
        ]]

        rows.append([
            "summary",
            "",
            "",
            "",
            report.logsPath,
            "",
            iso8601String(report.generatedAt),
            "",
            "",
            String(report.artifactCount),
            String(report.totalBytes)
        ])

        for kind in DiagnosticArtifactKind.allCases {
            let count = report.kindCounts[kind] ?? 0
            guard count > 0 else { continue }
            rows.append([
                "kind",
                kind.rawValue,
                "",
                "",
                "",
                "",
                iso8601String(report.generatedAt),
                "",
                "",
                String(count),
                ""
            ])
        }

        for artifact in report.artifacts {
            rows.append([
                "artifact",
                artifact.kind.rawValue,
                artifact.name,
                artifact.relativePath,
                artifact.path,
                artifact.parentDirectory,
                iso8601String(artifact.modifiedAt),
                String(artifact.byteCount),
                artifact.isExecutable ? "true" : "false",
                "",
                ""
            ])
        }

        return rows.map { $0.map(csvEscaped).joined(separator: ",") }.joined(separator: "\n")
    }

    public static func markdown(report: DiagnosticArtifactIndexReport) -> String {
        var lines = [
            "# MacWin Diagnostic Artifacts",
            "",
            "- Generated: \(iso8601String(report.generatedAt))",
            "- Logs: `\(report.logsPath)`",
            "- Artifacts: \(report.artifactCount)",
            "- Total bytes: \(report.totalBytes)",
            "",
            "## Counts",
            ""
        ]

        for kind in DiagnosticArtifactKind.allCases {
            lines.append("- \(kind.rawValue): \(report.kindCounts[kind] ?? 0)")
        }

        lines.append("")
        lines.append("## Latest")
        lines.append("")
        if report.artifacts.isEmpty {
            lines.append("No diagnostic artifacts found.")
        } else {
            for artifact in report.artifacts {
                lines.append("- `\(artifact.relativePath)` (\(artifact.kind.rawValue), \(artifact.byteCount) bytes, \(iso8601String(artifact.modifiedAt)))")
            }
        }

        lines.append("")
        return lines.joined(separator: "\n")
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

public struct DiagnosticArtifactIndexService {
    public var paths: MacWinPaths
    public var fileManager: FileManager

    public init(paths: MacWinPaths = MacWinPaths(), fileManager: FileManager = .default) {
        self.paths = paths
        self.fileManager = fileManager
    }

    public func report(limit: Int = 250, generatedAt: Date = Date()) -> DiagnosticArtifactIndexReport {
        guard fileManager.fileExists(atPath: paths.logsDirectory.path) else {
            return DiagnosticArtifactIndexReport(
                generatedAt: generatedAt,
                rootPath: paths.root.path,
                logsPath: paths.logsDirectory.path,
                artifactCount: 0,
                totalBytes: 0,
                kindCounts: [:],
                artifacts: []
            )
        }

        let keys: [URLResourceKey] = [
            .isRegularFileKey,
            .fileSizeKey,
            .contentModificationDateKey,
            .isExecutableKey
        ]
        guard let enumerator = fileManager.enumerator(
            at: paths.logsDirectory,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else {
            return DiagnosticArtifactIndexReport.empty(paths: paths)
        }

        var artifacts: [DiagnosticArtifactItem] = []
        for case let url as URL in enumerator {
            guard let values = try? url.resourceValues(forKeys: Set(keys)),
                  values.isRegularFile == true else {
                continue
            }

            let relativePath = self.relativePath(for: url)
            let byteCount = Int64(values.fileSize ?? 0)
            artifacts.append(DiagnosticArtifactItem(
                id: relativePath,
                kind: Self.kind(for: url, relativePath: relativePath),
                name: url.lastPathComponent,
                path: url.path,
                relativePath: relativePath,
                parentDirectory: url.deletingLastPathComponent().lastPathComponent,
                modifiedAt: values.contentModificationDate ?? .distantPast,
                byteCount: byteCount,
                isExecutable: values.isExecutable ?? false
            ))
        }

        let sortedArtifacts = artifacts.sorted {
            if $0.modifiedAt != $1.modifiedAt {
                return $0.modifiedAt > $1.modifiedAt
            }
            return $0.relativePath.localizedStandardCompare($1.relativePath) == .orderedAscending
        }
        let limitedArtifacts = Array(sortedArtifacts.prefix(max(0, limit)))
        return DiagnosticArtifactIndexReport(
            generatedAt: generatedAt,
            rootPath: paths.root.path,
            logsPath: paths.logsDirectory.path,
            artifactCount: artifacts.count,
            totalBytes: artifacts.reduce(0) { $0 + $1.byteCount },
            kindCounts: Dictionary(grouping: artifacts, by: \.kind).mapValues(\.count),
            artifacts: limitedArtifacts
        )
    }

    private func relativePath(for url: URL) -> String {
        let rootPath = paths.logsDirectory.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        guard path.hasPrefix(rootPath + "/") else { return url.lastPathComponent }
        return String(path.dropFirst(rootPath.count + 1))
    }

    private static func kind(for url: URL, relativePath: String) -> DiagnosticArtifactKind {
        let name = url.lastPathComponent.lowercased()
        let ext = url.pathExtension.lowercased()
        let normalizedPath = relativePath.replacingOccurrences(of: "\\", with: "/").lowercased()

        if ext == "zip" || normalizedPath.contains("supportbundles/") || normalizedPath.contains("softwarecollectionbundles/") {
            return .bundle
        }
        if ["log", "out", "err"].contains(ext) {
            return .log
        }
        if ["csv", "tsv"].contains(ext) {
            return .table
        }
        if ["sh", "command"].contains(ext) {
            return .script
        }
        if ["md", "markdown", "html", "txt"].contains(ext) {
            return .report
        }
        if ext == "json" {
            if normalizedPath.contains("records/") || name.contains("history") || name.contains("record") {
                return .record
            }
            if name.contains("report") || name.contains("manifest") || name.contains("capability") {
                return .report
            }
            return .record
        }
        return .other
    }
}
