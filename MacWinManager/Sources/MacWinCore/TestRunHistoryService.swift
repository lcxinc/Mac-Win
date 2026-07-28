import Foundation

public enum TestRunOutcome: String, Codable, Equatable, Sendable {
    case passed
    case failed
    case timedOut
    case missingExit
    case unknown
}

public struct TestRunHistoryReport: Codable, Equatable, Sendable {
    public var rootPath: String
    public var logsPath: String
    public var totalRunCount: Int
    public var mappedRunCount: Int
    public var allStatusCounts: [String: Int]
    public var statusCounts: [String: Int]
    public var latestRunAt: Date?
    public var runs: [TestRunRecord]

    public init(rootPath: String, logsPath: String, runs: [TestRunRecord]) {
        self.rootPath = rootPath
        self.logsPath = logsPath
        self.totalRunCount = runs.count
        self.mappedRunCount = runs.filter { $0.assetId != nil }.count
        var allCounts: [String: Int] = [:]
        for run in runs {
            allCounts[run.outcome.rawValue, default: 0] += 1
        }
        self.allStatusCounts = allCounts
        self.statusCounts = Self.latestMappedStatusCounts(runs)
        self.latestRunAt = runs.map(\.modifiedAt).max()
        self.runs = runs
    }

    private static func latestMappedStatusCounts(_ runs: [TestRunRecord]) -> [String: Int] {
        var latestByAssetId: [String: TestRunRecord] = [:]
        for run in runs {
            guard let assetId = run.assetId else { continue }
            if let existing = latestByAssetId[assetId], existing.modifiedAt >= run.modifiedAt {
                continue
            }
            latestByAssetId[assetId] = run
        }

        var counts: [String: Int] = [:]
        for run in latestByAssetId.values {
            counts[run.outcome.rawValue, default: 0] += 1
        }
        return counts
    }

    public static func csv(report: TestRunHistoryReport?) -> String {
        let formatter = ISO8601DateFormatter()
        var rows: [[String]] = [[
            "id",
            "asset_id",
            "name",
            "category",
            "architecture",
            "outcome",
            "exit_code",
            "modified_at",
            "byte_count",
            "pass_signal_count",
            "fail_signal_count",
            "timeout_observed",
            "summary",
            "log_path",
            "exit_path",
            "pass_signals",
            "fail_signals"
        ]]

        for run in report?.runs ?? [] {
            rows.append([
                run.id,
                run.assetId ?? "",
                run.name,
                run.category?.rawValue ?? "",
                run.architecture.rawValue,
                run.outcome.rawValue,
                run.exitCode.map(String.init) ?? "",
                formatter.string(from: run.modifiedAt),
                String(run.byteCount),
                String(run.passSignals.count),
                String(run.failSignals.count),
                run.timeoutObserved ? "true" : "false",
                run.summary,
                run.logPath,
                run.exitPath ?? "",
                run.passSignals.joined(separator: ";"),
                run.failSignals.joined(separator: ";")
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

public struct TestRunRecord: Codable, Equatable, Sendable {
    public var id: String
    public var assetId: String?
    public var name: String
    public var category: DiagnosticCategory?
    public var architecture: WindowsExecutableArchitecture
    public var logPath: String
    public var exitPath: String?
    public var exitCode: Int32?
    public var outcome: TestRunOutcome
    public var modifiedAt: Date
    public var byteCount: Int64
    public var passSignals: [String]
    public var failSignals: [String]
    public var timeoutObserved: Bool
    public var summary: String
}

public struct TestRunHistoryService {
    public var root: URL
    public var fileManager: FileManager

    public init(root: URL = URL(fileURLWithPath: TestAssetService.defaultRootPath), fileManager: FileManager = .default) {
        self.root = root
        self.fileManager = fileManager
    }

    public func report(limit: Int = 60) -> TestRunHistoryReport {
        let logsDirectory = root.appendingPathComponent("logs", isDirectory: true)
        guard fileManager.fileExists(atPath: logsDirectory.path),
              let contents = try? fileManager.contentsOfDirectory(
                at: logsDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
              ) else {
            return TestRunHistoryReport(rootPath: root.path, logsPath: logsDirectory.path, runs: [])
        }

        let candidates = contents.compactMap { url -> (url: URL, modifiedAt: Date)? in
            guard url.pathExtension.lowercased() == "log",
                  let values = try? url.resourceValues(forKeys: [.contentModificationDateKey]) else {
                return nil
            }
            return (url: url, modifiedAt: values.contentModificationDate ?? Date(timeIntervalSince1970: 0))
        }
        .sorted { $0.modifiedAt > $1.modifiedAt }
        .prefix(limit)

        let records = candidates
            .compactMap { record(for: $0.url, logsDirectory: logsDirectory) }
            .sorted { $0.modifiedAt > $1.modifiedAt }
        return TestRunHistoryReport(rootPath: root.path, logsPath: logsDirectory.path, runs: records)
    }

    private func record(for logURL: URL, logsDirectory: URL) -> TestRunRecord? {
        guard let values = try? logURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]) else {
            return nil
        }
        let logName = logURL.deletingPathExtension().lastPathComponent
        let mapping = Self.mapping(forLogName: logName)
        let text = logText(logURL)
        let exitURL = matchingExitURL(for: logURL)
        let exitCode = exitURL.flatMap(exitCode)
        let signals = Self.signals(in: text)
        let timeoutObserved = Self.timeoutObserved(in: text) || exitCode == 124
        let outcome = Self.outcome(exitCode: exitCode, signals: signals, timeoutObserved: timeoutObserved, hasExit: exitURL != nil)
        return TestRunRecord(
            id: logName,
            assetId: mapping?.assetId,
            name: mapping?.name ?? logName,
            category: mapping?.category,
            architecture: mapping?.architecture ?? .unknown,
            logPath: logURL.path,
            exitPath: exitURL?.path,
            exitCode: exitCode,
            outcome: outcome,
            modifiedAt: values.contentModificationDate ?? Date(timeIntervalSince1970: 0),
            byteCount: Int64(values.fileSize ?? 0),
            passSignals: signals.pass,
            failSignals: signals.fail,
            timeoutObserved: timeoutObserved,
            summary: Self.summary(outcome: outcome, exitCode: exitCode, signals: signals, timeoutObserved: timeoutObserved)
        )
    }

    private func matchingExitURL(for logURL: URL) -> URL? {
        let direct = URL(fileURLWithPath: logURL.path + ".exit")
        if fileManager.fileExists(atPath: direct.path) {
            return direct
        }
        let sibling = logURL.deletingPathExtension().appendingPathExtension("exit")
        if fileManager.fileExists(atPath: sibling.path) {
            return sibling
        }
        return nil
    }

    private func exitCode(_ url: URL) -> Int32? {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        return Int32(text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func logText(_ url: URL, maxBytes: UInt64 = 128 * 1024) -> String {
        guard let data = try? tailData(file: url, maxBytes: maxBytes) else { return "" }
        return String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1)
            ?? ""
    }

    private func tailData(file url: URL, maxBytes: UInt64) throws -> Data {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let size = try handle.seekToEnd()
        if size > maxBytes {
            try handle.seek(toOffset: size - maxBytes)
        } else {
            try handle.seek(toOffset: 0)
        }
        return try handle.readToEnd() ?? Data()
    }

    private static func outcome(
        exitCode: Int32?,
        signals: (pass: [String], fail: [String]),
        timeoutObserved: Bool,
        hasExit: Bool
    ) -> TestRunOutcome {
        if timeoutObserved { return .timedOut }
        if !signals.fail.isEmpty { return .failed }
        if let exitCode {
            return exitCode == 0 ? .passed : .failed
        }
        if !signals.pass.isEmpty { return .passed }
        return hasExit ? .unknown : .missingExit
    }

    private static func signals(in text: String) -> (pass: [String], fail: [String]) {
        var pass: [String] = []
        var fail: [String] = []
        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.hasPrefix("PASS ") {
                pass.append(line)
            } else if line.hasPrefix("FAIL ") {
                fail.append(line)
            }
        }
        return (pass, fail)
    }

    private static func timeoutObserved(in text: String) -> Bool {
        text.components(separatedBy: .newlines).contains { rawLine in
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            let lowercased = line.lowercased()
            return line.hasPrefix("TIMEOUT")
                || lowercased.hasPrefix("timed out")
                || lowercased.contains(" timed out")
        }
    }

    private static func summary(
        outcome: TestRunOutcome,
        exitCode: Int32?,
        signals: (pass: [String], fail: [String]),
        timeoutObserved: Bool
    ) -> String {
        var parts = ["outcome=\(outcome.rawValue)"]
        if let exitCode {
            parts.append("exit=\(exitCode)")
        }
        if !signals.pass.isEmpty {
            parts.append("passSignals=\(signals.pass.count)")
        }
        if !signals.fail.isEmpty {
            parts.append("failSignals=\(signals.fail.count)")
        }
        if timeoutObserved {
            parts.append("timeout=true")
        }
        return parts.joined(separator: " ")
    }

    private static func mapping(forLogName name: String) -> TestRunMapping? {
        let normalized = name.lowercased()
        let candidates = runMappings.sorted { lhs, rhs in
            lhs.logPrefixes.count > rhs.logPrefixes.count
        }
        return candidates.first { mapping in
            mapping.logPrefixes.contains { normalized.hasPrefix($0) }
        }
    }

    private struct TestRunMapping {
        var assetId: String
        var name: String
        var category: DiagnosticCategory
        var architecture: WindowsExecutableArchitecture
        var logPrefixes: [String]
    }

    private static let runMappings: [TestRunMapping] = [
        TestRunMapping(assetId: "console", name: "Win32 Console Probe", category: .core, architecture: .x86_64, logPrefixes: ["00_console_probe"]),
        TestRunMapping(assetId: "tls-winhttp-win32", name: "WinHTTP TLS Probe (32-bit)", category: .win32, architecture: .i386, logPrefixes: ["10_tls_winhttp_probe_win32"]),
        TestRunMapping(assetId: "tls-winhttp", name: "WinHTTP TLS Probe", category: .network, architecture: .x86_64, logPrefixes: ["10_tls_winhttp_probe"]),
        TestRunMapping(assetId: "iphlpapi-adapters-win32", name: "Network Adapter Probe (32-bit)", category: .win32, architecture: .i386, logPrefixes: ["15_iphlpapi_probe_win32"]),
        TestRunMapping(assetId: "iphlpapi-adapters", name: "Network Adapter Probe", category: .network, architecture: .x86_64, logPrefixes: ["15_iphlpapi_probe"]),
        TestRunMapping(assetId: "network-list-manager-win32", name: "Network List Manager Probe (32-bit)", category: .win32, architecture: .i386, logPrefixes: ["92_network_list_probe_win32"]),
        TestRunMapping(assetId: "network-list-manager", name: "Network List Manager Probe", category: .network, architecture: .x86_64, logPrefixes: ["92_network_list_probe"]),
        TestRunMapping(assetId: "vulkan", name: "Vulkan Device Probe", category: .graphics, architecture: .x86_64, logPrefixes: ["20_vulkan_probe"]),
        TestRunMapping(assetId: "d3d11", name: "D3D11 Device Probe", category: .graphics, architecture: .x86_64, logPrefixes: ["30_d3d11_probe", "30_d3d11_vulkan", "30_d3d11_csmt", "30_d3d11_opengl"]),
        TestRunMapping(assetId: "d3d12-device", name: "D3D12 Device Probe", category: .graphics, architecture: .x86_64, logPrefixes: ["35_d3d12_device_probe"]),
        TestRunMapping(assetId: "xaudio2", name: "XAudio2 Probe", category: .audio, architecture: .x86_64, logPrefixes: ["40_xaudio2_probe"]),
        TestRunMapping(assetId: "d3d9-legacy", name: "D3D9 Legacy Probe", category: .graphics, architecture: .x86_64, logPrefixes: ["45_d3d9_legacy_probe"]),
        TestRunMapping(assetId: "game-loop", name: "D3D11 Game Loop Probe", category: .game, architecture: .x86_64, logPrefixes: ["50_game_loop_probe"]),
        TestRunMapping(assetId: "game-shader", name: "D3D11 Shader Game Loop Probe", category: .game, architecture: .x86_64, logPrefixes: ["60_game_shader_probe"]),
        TestRunMapping(assetId: "text-rendering", name: "GDI / DirectWrite Text Rendering Probe", category: .core, architecture: .x86_64, logPrefixes: ["70_text_rendering_probe"]),
        TestRunMapping(assetId: "window-input", name: "Win32 Window / Input Probe", category: .windowing, architecture: .x86_64, logPrefixes: ["80_window_input_probe"]),
        TestRunMapping(assetId: "ipc-file-mapping", name: "Win32 IPC / File Mapping Probe", category: .core, architecture: .x86_64, logPrefixes: ["90_ipc_file_mapping_probe"]),
        TestRunMapping(assetId: "jasp-boost-ipc", name: "JASP Boost IPC Probe", category: .core, architecture: .x86_64, logPrefixes: ["95_jasp_boost_ipc_probe"]),
        TestRunMapping(assetId: "jasp-special-float-eh", name: "JASP Special Float / C++ EH Probe", category: .core, architecture: .x86_64, logPrefixes: ["96_jasp_special_float_eh_probe"]),
        TestRunMapping(assetId: "jasp-createprocess", name: "JASP CreateProcess Probe", category: .core, architecture: .x86_64, logPrefixes: ["97_jasp_createprocess_probe"])
    ]
}
