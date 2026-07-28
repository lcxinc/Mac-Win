import Foundation
import Testing
@testable import MacWinCore

@Suite("Test execution plan service")
struct TestExecutionPlanServiceTests {
    @Test("Execution plan prioritizes missing, failed, timed-out and unverified probes")
    func executionPlanPrioritizesActionableProbeWork() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinTestExecutionPlanTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root.appendingPathComponent("bin", isDirectory: true), withIntermediateDirectories: true)
        try Data("#!/usr/bin/env bash\n".utf8).write(to: root.appendingPathComponent("run-one.sh"))
        try Data("probe".utf8).write(to: root.appendingPathComponent("bin/00_console_probe.exe"))
        try Data("probe".utf8).write(to: root.appendingPathComponent("bin/30_d3d11_probe.exe"))
        try Data("probe".utf8).write(to: root.appendingPathComponent("bin/40_xaudio2_probe.exe"))
        try Data("probe".utf8).write(to: root.appendingPathComponent("bin/70_text_rendering_probe.exe"))

        let logs = root.appendingPathComponent("logs", isDirectory: true)
        try FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)
        try Data("PASS console\n".utf8).write(to: logs.appendingPathComponent("00_console_probe.log"))
        try Data("0\n".utf8).write(to: logs.appendingPathComponent("00_console_probe.exit"))
        try Data("FAIL d3d11\n".utf8).write(to: logs.appendingPathComponent("30_d3d11_probe.log"))
        try Data("1\n".utf8).write(to: logs.appendingPathComponent("30_d3d11_probe.exit"))
        try Data("timeout waiting for audio device\n".utf8).write(to: logs.appendingPathComponent("40_xaudio2_probe.log"))
        try Data("124\n".utf8).write(to: logs.appendingPathComponent("40_xaudio2_probe.exit"))

        let assets = TestAssetService(root: root).report()
        let history = TestRunHistoryService(root: root).report()
        let plan = TestExecutionPlanService(staleAfter: 60 * 60).makePlan(
            assetReport: assets,
            runHistory: history,
            generatedAt: Date()
        )

        let d3d11 = try #require(plan.items.first { $0.assetId == "d3d11" })
        let xaudio2 = try #require(plan.items.first { $0.assetId == "xaudio2" })
        let textRendering = try #require(plan.items.first { $0.assetId == "text-rendering" })
        let tls = try #require(plan.items.first { $0.assetId == "tls-winhttp" })

        #expect(plan.itemCount == 15)
        #expect(plan.requiredCount == 12)
        #expect(plan.highPriorityCount == 3)
        #expect(plan.failedCount == 1)
        #expect(plan.timedOutCount == 1)
        #expect(plan.unverifiedCount == 1)
        #expect(plan.missingRequiredAssetCount == 12)
        #expect(d3d11.priority == .high)
        #expect(d3d11.reasons == [.failed])
        #expect(d3d11.command.last == "30_d3d11_probe")
        #expect(xaudio2.priority == .high)
        #expect(xaudio2.reasons == [.timedOut])
        #expect(textRendering.priority == .high)
        #expect(textRendering.reasons == [.neverRun])
        #expect(textRendering.command.last == "70_text_rendering_probe")
        #expect(tls.priority == .required)
        #expect(tls.reasons.contains(.missingRequiredAsset))
        #expect(tls.command.last == "10_tls_winhttp_probe")

        let script = TestAssetService.shellScript(forExecutionPlan: plan)
        #expect(script.contains("MODE=\"${1:-run}\""))
        #expect(script.contains("SKIP tls-winhttp: missingRequiredAsset"))
        #expect(script.contains("== d3d11 (high: failed) =="))
        #expect(script.contains("== xaudio2 (high: timedOut) =="))
        #expect(script.contains("== text-rendering (high: neverRun) =="))
        #expect(script.contains("30_d3d11_probe"))
        #expect(script.contains("70_text_rendering_probe"))
        #expect(script.contains("usage: $0 [run|list|"))

        let csv = TestExecutionPlan.csv(plan: plan)
        #expect(csv.contains("asset_id,name,category,architecture,priority,reasons,exists,executable_path,command,note,latest_run_outcome"))
        #expect(csv.contains("d3d11,D3D11 Device Probe,graphics,x86_64,high,failed,true"))
        #expect(csv.contains("xaudio2,XAudio2 Probe,audio,x86_64,high,timedOut,true"))
        #expect(csv.contains("text-rendering,GDI / DirectWrite Text Rendering Probe,core,x86_64,high,neverRun,true"))
        #expect(csv.contains("tls-winhttp,WinHTTP TLS Probe,network,x86_64,required,missingRequiredAsset,false"))
        #expect(csv.contains("30_d3d11_probe"))
        #expect(csv.contains("70_text_rendering_probe"))
    }
}
