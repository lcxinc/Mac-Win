import Foundation
import Testing
@testable import MacWinCore

@Suite("Diagnostics history service")
struct DiagnosticsHistoryServiceTests {
    @Test("Diagnostic reports are persisted sorted and exported as CSV")
    func diagnosticReportsPersistSortAndExport() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinDiagnosticHistoryTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = DiagnosticsHistoryService(paths: paths)
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/tmp/wine",
            wineserverPath: "/tmp/wineserver",
            runtimePath: "/tmp/runtime",
            defaultEnv: [:]
        )
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: engine.id
        )
        let firstLog = paths.logsDirectory.appendingPathComponent("diagnostics-first.log")
        let secondLog = paths.logsDirectory.appendingPathComponent("diagnostics-second.log")
        let first = DiagnosticReport(
            exitCode: 0,
            logURL: firstLog,
            items: [
                DiagnosticItem(id: "console", name: "Console", passed: true, detail: "PASS", category: .core)
            ],
            rawOutput: "PASS console",
            durationSeconds: 2.5
        )
        let second = DiagnosticReport(
            exitCode: 124,
            logURL: secondLog,
            items: [
                DiagnosticItem(id: "vulkan", name: "Vulkan", passed: false, detail: "FAIL", category: .graphics),
                DiagnosticItem(id: "tls_win32", name: "TLS, 32-bit", passed: false, detail: "SKIP", category: .win32, status: .skipped)
            ],
            rawOutput: "FAIL vulkan\nSKIP tls_win32",
            timedOut: true,
            durationSeconds: 7
        )

        let firstRecord = try service.save(
            report: first,
            scope: .suite,
            engine: engine,
            bottle: bottle,
            endedAt: Date(timeIntervalSince1970: 100)
        )
        let secondRecord = try service.save(
            report: second,
            scope: .probe,
            engine: engine,
            bottle: bottle,
            assetId: "vulkan",
            endedAt: Date(timeIntervalSince1970: 200)
        )

        #expect(FileManager.default.fileExists(atPath: service.recordsDirectory.appendingPathComponent("\(firstRecord.id).diagnostic.json").path))
        #expect(FileManager.default.fileExists(atPath: service.recordsDirectory.appendingPathComponent("\(secondRecord.id).diagnostic.json").path))

        let report = service.report()
        #expect(report.totalRunCount == 2)
        #expect(report.passedRunCount == 1)
        #expect(report.failedRunCount == 0)
        #expect(report.timedOutRunCount == 1)
        #expect(report.records.map(\.id) == [secondRecord.id, firstRecord.id])
        #expect(report.records.first?.assetId == "vulkan")
        #expect(report.records.first?.failedItemCount == 1)
        #expect(report.records.first?.skippedItemCount == 1)

        let csv = DiagnosticHistoryReport.csv(report: report)
        #expect(csv.contains("record_type,run_id,scope,asset_id,asset_ids,engine_id,bottle_id,exit_code,timed_out"))
        #expect(csv.contains("run,\(secondRecord.id),probe,vulkan,vulkan,engine,bottle,124,true"))
        #expect(csv.contains("item,\(secondRecord.id),probe,vulkan,vulkan,engine,bottle,,,,,,tls_win32,\"TLS, 32-bit\",win32,skipped,SKIP"))
        #expect(csv.contains("run,\(firstRecord.id),suite,,,engine,bottle,0,false"))
        #expect(csv.contains("item,\(firstRecord.id),suite,,,engine,bottle,,,,,,console,Console,core,passed,PASS"))
    }
}
