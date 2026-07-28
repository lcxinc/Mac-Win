import Foundation
import Testing
@testable import MacWinCore

@Suite("Diagnostic artifact index service")
struct DiagnosticArtifactIndexServiceTests {
    @Test("Artifact index scans logs reports tables scripts bundles and records")
    func artifactIndexScansDiagnosticOutputs() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinDiagnosticArtifacts-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()
        let logs = paths.logsDirectory
        let reportDate = Date(timeIntervalSince1970: 1_800_000_000)

        let logURL = logs.appendingPathComponent("hoyoplay.log")
        let csvURL = logs.appendingPathComponent("software-collection.csv")
        let markdownURL = logs.appendingPathComponent("log-triage.md")
        let scriptURL = logs.appendingPathComponent("acceptance-runbook.sh")
        let bundleManifestURL = logs
            .appendingPathComponent("SoftwareCollectionBundles/demo", isDirectory: true)
            .appendingPathComponent("manifest.json")
        let launchRecordURL = logs
            .appendingPathComponent("LaunchRecords", isDirectory: true)
            .appendingPathComponent("launch.json")

        for url in [logURL, csvURL, markdownURL, scriptURL, bundleManifestURL, launchRecordURL] {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(url.lastPathComponent.utf8).write(to: url)
        }
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

        let report = DiagnosticArtifactIndexService(paths: paths).report(limit: 20, generatedAt: reportDate)

        #expect(report.rootPath == root.path)
        #expect(report.logsPath == logs.path)
        #expect(report.artifactCount == 6)
        #expect(report.totalBytes > 0)
        #expect(report.kindCounts[.log] == 1)
        #expect(report.kindCounts[.table] == 1)
        #expect(report.kindCounts[.report] == 1)
        #expect(report.kindCounts[.script] == 1)
        #expect(report.kindCounts[.bundle] == 1)
        #expect(report.kindCounts[.record] == 1)
        #expect(report.artifacts.contains { $0.relativePath == "hoyoplay.log" && $0.kind == .log })
        #expect(report.artifacts.contains { $0.relativePath == "software-collection.csv" && $0.kind == .table })
        #expect(report.artifacts.contains { $0.relativePath == "log-triage.md" && $0.kind == .report })
        #expect(report.artifacts.contains { $0.relativePath == "acceptance-runbook.sh" && $0.kind == .script && $0.isExecutable })
        #expect(report.artifacts.contains { $0.relativePath == "SoftwareCollectionBundles/demo/manifest.json" && $0.kind == .bundle })
        #expect(report.artifacts.contains { $0.relativePath == "LaunchRecords/launch.json" && $0.kind == .record })

        let csv = DiagnosticArtifactIndexReport.csv(report: report)
        #expect(csv.contains("row_type,kind,name,relative_path,path,parent_directory,modified_at,byte_count,is_executable,artifact_count,total_bytes"))
        #expect(csv.contains("artifact,script,acceptance-runbook.sh,acceptance-runbook.sh"))
        #expect(csv.contains("kind,bundle"))

        let markdown = DiagnosticArtifactIndexReport.markdown(report: report)
        #expect(markdown.contains("# MacWin Diagnostic Artifacts"))
        #expect(markdown.contains("acceptance-runbook.sh"))
        #expect(markdown.contains("- bundle: 1"))
    }

    @Test("Artifact index is stable when logs directory is missing")
    func artifactIndexHandlesMissingLogsDirectory() {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinDiagnosticArtifactsMissing-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = MacWinPaths(root: root)

        let report = DiagnosticArtifactIndexService(paths: paths).report()

        #expect(report.artifactCount == 0)
        #expect(report.totalBytes == 0)
        #expect(report.artifacts.isEmpty)
        #expect(report.kindCounts.isEmpty)
    }
}
