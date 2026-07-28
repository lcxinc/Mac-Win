import Foundation
import Testing
@testable import MacWinCore

@Suite("Test run history service")
struct TestRunHistoryServiceTests {
    @Test("Run history parses probe logs exit codes and manual records")
    func runHistoryParsesProbeLogsExitCodesAndManualRecords() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinTestRunHistoryTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let logs = root.appendingPathComponent("logs", isDirectory: true)
        try FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)

        let consoleLog = logs.appendingPathComponent("00_console_probe.log")
        try Data("PASS console\n".utf8).write(to: consoleLog)
        try Data("0\n".utf8).write(to: logs.appendingPathComponent("00_console_probe.exit"))
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 100)], ofItemAtPath: consoleLog.path)

        let textLog = logs.appendingPathComponent("70_text_rendering_probe.log")
        try Data("PASS text_rendering\n".utf8).write(to: textLog)
        try Data("0\n".utf8).write(to: logs.appendingPathComponent("70_text_rendering_probe.exit"))
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 150)], ofItemAtPath: textLog.path)

        let windowLog = logs.appendingPathComponent("80_window_input_probe.log")
        try Data("PASS window_input\n".utf8).write(to: windowLog)
        try Data("0\n".utf8).write(to: logs.appendingPathComponent("80_window_input_probe.exit"))
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 175)], ofItemAtPath: windowLog.path)

        let ipcLog = logs.appendingPathComponent("90_ipc_file_mapping_probe.log")
        try Data("PASS ipc_file_mapping\n".utf8).write(to: ipcLog)
        try Data("0\n".utf8).write(to: logs.appendingPathComponent("90_ipc_file_mapping_probe.exit"))
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 180)], ofItemAtPath: ipcLog.path)

        let boostIpcLog = logs.appendingPathComponent("95_jasp_boost_ipc_probe.log")
        try Data("PASS jasp_boost_ipc\n".utf8).write(to: boostIpcLog)
        try Data("0\n".utf8).write(to: logs.appendingPathComponent("95_jasp_boost_ipc_probe.exit"))
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 185)], ofItemAtPath: boostIpcLog.path)

        let specialFloatLog = logs.appendingPathComponent("96_jasp_special_float_eh_probe.log")
        try Data("PASS jasp_special_float_eh\n".utf8).write(to: specialFloatLog)
        try Data("0\n".utf8).write(to: logs.appendingPathComponent("96_jasp_special_float_eh_probe.exit"))
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 188)], ofItemAtPath: specialFloatLog.path)

        let createProcessLog = logs.appendingPathComponent("97_jasp_createprocess_probe.log")
        try Data("PASS jasp_createprocess\n".utf8).write(to: createProcessLog)
        try Data("0\n".utf8).write(to: logs.appendingPathComponent("97_jasp_createprocess_probe.exit"))
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 190)], ofItemAtPath: createProcessLog.path)

        let d3dLog = logs.appendingPathComponent("30_d3d11_vulkan.log")
        try Data("FAIL d3d11\n".utf8).write(to: d3dLog)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 200)], ofItemAtPath: d3dLog.path)

        let timeoutLog = logs.appendingPathComponent("60_game_shader_probe.log")
        try Data("TIMEOUT after 60s\n".utf8).write(to: timeoutLog)
        try Data("124\n".utf8).write(to: logs.appendingPathComponent("60_game_shader_probe.exit"))
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 300)], ofItemAtPath: timeoutLog.path)

        let appLog = logs.appendingPathComponent("hoyoplay_wined3d_vulkan.log")
        try Data("controlled launcher smoke\n".utf8).write(to: appLog)
        try Data("1\n".utf8).write(to: logs.appendingPathComponent("hoyoplay_wined3d_vulkan.log.exit"))
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 400)], ofItemAtPath: appLog.path)

        let report = TestRunHistoryService(root: root).report()

        #expect(report.totalRunCount == 10)
        #expect(report.mappedRunCount == 9)
        #expect(report.latestRunAt == Date(timeIntervalSince1970: 400))
        #expect(report.allStatusCounts["passed"] == 7)
        #expect(report.allStatusCounts["failed"] == 2)
        #expect(report.allStatusCounts["timedOut"] == 1)
        #expect(report.statusCounts["passed"] == 7)
        #expect(report.statusCounts["failed"] == 1)
        #expect(report.statusCounts["timedOut"] == 1)
        #expect(report.runs.first?.id == "hoyoplay_wined3d_vulkan")
        #expect(report.runs.first { $0.id == "00_console_probe" }?.assetId == "console")
        #expect(report.runs.first { $0.id == "00_console_probe" }?.outcome == .passed)
        #expect(report.runs.first { $0.id == "70_text_rendering_probe" }?.assetId == "text-rendering")
        #expect(report.runs.first { $0.id == "70_text_rendering_probe" }?.category == .core)
        #expect(report.runs.first { $0.id == "80_window_input_probe" }?.assetId == "window-input")
        #expect(report.runs.first { $0.id == "80_window_input_probe" }?.category == .windowing)
        #expect(report.runs.first { $0.id == "90_ipc_file_mapping_probe" }?.assetId == "ipc-file-mapping")
        #expect(report.runs.first { $0.id == "90_ipc_file_mapping_probe" }?.category == .core)
        #expect(report.runs.first { $0.id == "95_jasp_boost_ipc_probe" }?.assetId == "jasp-boost-ipc")
        #expect(report.runs.first { $0.id == "95_jasp_boost_ipc_probe" }?.category == .core)
        #expect(report.runs.first { $0.id == "96_jasp_special_float_eh_probe" }?.assetId == "jasp-special-float-eh")
        #expect(report.runs.first { $0.id == "96_jasp_special_float_eh_probe" }?.category == .core)
        #expect(report.runs.first { $0.id == "97_jasp_createprocess_probe" }?.assetId == "jasp-createprocess")
        #expect(report.runs.first { $0.id == "97_jasp_createprocess_probe" }?.category == .core)
        #expect(report.runs.first { $0.id == "30_d3d11_vulkan" }?.assetId == "d3d11")
        #expect(report.runs.first { $0.id == "30_d3d11_vulkan" }?.outcome == .failed)
        #expect(report.runs.first { $0.id == "60_game_shader_probe" }?.outcome == .timedOut)
        #expect(report.runs.first { $0.id == "hoyoplay_wined3d_vulkan" }?.assetId == nil)
        #expect(report.runs.first { $0.id == "hoyoplay_wined3d_vulkan" }?.exitCode == 1)

        let csv = TestRunHistoryReport.csv(report: report)
        #expect(csv.contains("id,asset_id,name,category,architecture,outcome,exit_code,modified_at,byte_count"))
        #expect(csv.contains("80_window_input_probe,window-input,Win32 Window / Input Probe,windowing,x86_64,passed,0"))
        #expect(csv.contains("90_ipc_file_mapping_probe,ipc-file-mapping,Win32 IPC / File Mapping Probe,core,x86_64,passed,0"))
        #expect(csv.contains("95_jasp_boost_ipc_probe,jasp-boost-ipc,JASP Boost IPC Probe,core,x86_64,passed,0"))
        #expect(csv.contains("96_jasp_special_float_eh_probe,jasp-special-float-eh,JASP Special Float / C++ EH Probe,core,x86_64,passed,0"))
        #expect(csv.contains("97_jasp_createprocess_probe,jasp-createprocess,JASP CreateProcess Probe,core,x86_64,passed,0"))
        #expect(csv.contains("60_game_shader_probe,game-shader,D3D11 Shader Game Loop Probe,game,x86_64,timedOut,124"))
        #expect(csv.contains("30_d3d11_vulkan,d3d11,D3D11 Device Probe,graphics,x86_64,failed,"))
        #expect(csv.contains("hoyoplay_wined3d_vulkan,,hoyoplay_wined3d_vulkan,,unknown,failed,1"))
    }

    @Test("Run history returns empty report when logs directory is absent")
    func runHistoryReturnsEmptyReportWhenLogsDirectoryIsAbsent() {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinEmptyTestRunHistoryTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let report = TestRunHistoryService(root: root).report()

        #expect(report.totalRunCount == 0)
        #expect(report.statusCounts.isEmpty)
        #expect(report.runs.isEmpty)
    }

    @Test("Run history status counts use latest mapped asset runs")
    func runHistoryStatusCountsUseLatestMappedAssetRuns() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinLatestMappedHistoryTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let logs = root.appendingPathComponent("logs", isDirectory: true)
        try FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)

        let oldVariantLog = logs.appendingPathComponent("30_d3d11_opengl.log")
        try Data("FAIL d3d11\n".utf8).write(to: oldVariantLog)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 100)], ofItemAtPath: oldVariantLog.path)

        let currentLog = logs.appendingPathComponent("30_d3d11_probe.log")
        try Data("PASS d3d11\n".utf8).write(to: currentLog)
        try Data("0\n".utf8).write(to: logs.appendingPathComponent("30_d3d11_probe.exit"))
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 200)], ofItemAtPath: currentLog.path)

        let appLog = logs.appendingPathComponent("hoyoplay_wined3d_vulkan.log")
        try Data("legacy app smoke\n".utf8).write(to: appLog)
        try Data("1\n".utf8).write(to: logs.appendingPathComponent("hoyoplay_wined3d_vulkan.log.exit"))
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 300)], ofItemAtPath: appLog.path)

        let report = TestRunHistoryService(root: root).report()

        #expect(report.allStatusCounts["passed"] == 1)
        #expect(report.allStatusCounts["failed"] == 2)
        #expect(report.statusCounts["passed"] == 1)
        #expect(report.statusCounts["failed"] == nil)
        #expect(report.mappedRunCount == 2)
        #expect(report.totalRunCount == 3)
    }

    @Test("Run history applies limit before parsing old logs")
    func runHistoryAppliesLimitBeforeParsingOldLogs() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinLimitedTestRunHistoryTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let logs = root.appendingPathComponent("logs", isDirectory: true)
        try FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)

        let oldLog = logs.appendingPathComponent("00_console_probe.log")
        try Data("FAIL old\n".utf8).write(to: oldLog)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 100)], ofItemAtPath: oldLog.path)

        let newLog = logs.appendingPathComponent("40_xaudio2_probe.log")
        try Data("PASS new\n".utf8).write(to: newLog)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 200)], ofItemAtPath: newLog.path)

        let report = TestRunHistoryService(root: root).report(limit: 1)

        #expect(report.totalRunCount == 1)
        #expect(report.runs.map(\.id) == ["40_xaudio2_probe"])
        #expect(report.statusCounts["passed"] == 1)
        #expect(report.statusCounts["failed"] == nil)
    }

    @Test("Run history does not treat Wine timeout trace arguments as harness timeouts")
    func runHistoryIgnoresWineTimeoutTraceArguments() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinTimeoutTraceHistoryTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let logs = root.appendingPathComponent("logs", isDirectory: true)
        try FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)

        let tlsLog = logs.appendingPathComponent("10_tls_winhttp_probe.log")
        try Data("""
        0094:trace:winhttp:WinHttpSetTimeouts 0000000000000001, 5000, 5000, 10000, 10000
        http_status=200
        PASS tls_winhttp
        """.utf8).write(to: tlsLog)
        try Data("0\n".utf8).write(to: logs.appendingPathComponent("10_tls_winhttp_probe.exit"))

        let ipcLog = logs.appendingPathComponent("90_ipc_file_mapping_probe.single.log")
        try Data("""
        003c:trace:sync:NtWaitForSingleObject handle 0xa4, alertable 0, timeout (infinite)
        0078:trace:sync:RtlWaitOnAddress addr 0000000000038D90 cmp 00006FFFFFC423F0 size 0x4 timeout fffffffffd050f80
        PASS ipc_file_mapping
        """.utf8).write(to: ipcLog)
        try Data("0\n".utf8).write(to: logs.appendingPathComponent("90_ipc_file_mapping_probe.single.exit"))

        let harnessTimeoutLog = logs.appendingPathComponent("60_game_shader_probe.log")
        try Data("TIMEOUT after 60s\n".utf8).write(to: harnessTimeoutLog)
        try Data("124\n".utf8).write(to: logs.appendingPathComponent("60_game_shader_probe.exit"))

        let report = TestRunHistoryService(root: root).report()

        #expect(report.runs.first { $0.id == "10_tls_winhttp_probe" }?.outcome == .passed)
        #expect(report.runs.first { $0.id == "10_tls_winhttp_probe" }?.timeoutObserved == false)
        #expect(report.runs.first { $0.id == "90_ipc_file_mapping_probe.single" }?.outcome == .passed)
        #expect(report.runs.first { $0.id == "90_ipc_file_mapping_probe.single" }?.timeoutObserved == false)
        #expect(report.runs.first { $0.id == "60_game_shader_probe" }?.outcome == .timedOut)
        #expect(report.runs.first { $0.id == "60_game_shader_probe" }?.timeoutObserved == true)
    }
}
