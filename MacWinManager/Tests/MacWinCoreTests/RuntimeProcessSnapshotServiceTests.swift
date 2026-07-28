import Foundation
import Testing
@testable import MacWinCore

@Suite("Runtime process snapshot service")
struct RuntimeProcessSnapshotServiceTests {
    @Test("Snapshot writes JSON and operational log for stale runtime processes")
    func snapshotWritesJSONAndRecentLogEntry() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRuntimeProcessSnapshotTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = RuntimeProcessSnapshotService(paths: paths)
        let report = RuntimeProcessAuditService.report(from: """
          301 C:\\Program Files\\miHoYo Launcher\\1.16.1.364\\HYP.exe --disable-direct-write --disable-features=DWriteFontProxy,UseDWriteCore
          302 C:\\Program Files\\Steam\\Steam.exe -no-cef-sandbox
        """)
        let generatedAt = Date(timeIntervalSince1970: 1_700_000_000)

        let artifact = try service.writeSnapshot(report: report, generatedAt: generatedAt)

        #expect(artifact.jsonURL.lastPathComponent.hasPrefix("runtime-processes-"))
        #expect(artifact.jsonURL.pathExtension == "json")
        #expect(artifact.logURL.pathExtension == "log")
        #expect(FileManager.default.fileExists(atPath: artifact.jsonURL.path))
        #expect(FileManager.default.fileExists(atPath: artifact.logURL.path))

        let snapshot = try JSONStore().load(RuntimeProcessSnapshot.self, from: artifact.jsonURL)
        #expect(snapshot.generatedAt == generatedAt)
        #expect(snapshot.report.auditedProcessCount == 2)
        #expect(snapshot.report.staleRenderingProcessCount == 1)

        let logText = try String(contentsOf: artifact.logURL, encoding: .utf8)
        #expect(logText.contains("warn: runtime-process-finding"))
        #expect(logText.contains("staleRenderingProcessCount=1"))
        #expect(logText.contains("use-dwrite-core-disabled"))

        let recentLogs = LogService(paths: paths).recentLogs()
        #expect(!recentLogs.contains { $0.url.resolvingSymlinksInPath().path == artifact.logURL.resolvingSymlinksInPath().path })
    }
}
