import Darwin
import Foundation

public enum DiagnosticStatus: String, Codable, Equatable, Sendable {
    case passed
    case failed
    case skipped
    case notObserved

    public var isPassed: Bool {
        self == .passed
    }
}

public enum DiagnosticCategory: String, Codable, CaseIterable, Equatable, Sendable {
    case core
    case network
    case graphics
    case audio
    case game
    case windowing
    case win32
}

public struct DiagnosticItem: Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var category: DiagnosticCategory
    public var status: DiagnosticStatus
    public var passed: Bool
    public var detail: String

    public init(
        id: String,
        name: String,
        passed: Bool,
        detail: String,
        category: DiagnosticCategory = .core,
        status: DiagnosticStatus? = nil
    ) {
        let effectiveStatus = status ?? Self.status(passed: passed, detail: detail)
        self.id = id
        self.name = name
        self.category = category
        self.status = effectiveStatus
        self.passed = effectiveStatus.isPassed
        self.detail = detail
    }

    private static func status(passed: Bool, detail: String) -> DiagnosticStatus {
        if passed { return .passed }
        switch detail.lowercased() {
        case "fail":
            return .failed
        case "skip", "skipped":
            return .skipped
        default:
            return .notObserved
        }
    }
}

public struct DiagnosticReport: Equatable, Sendable {
    public var exitCode: Int32
    public var logURL: URL
    public var items: [DiagnosticItem]
    public var rawOutput: String
    public var timedOut: Bool
    public var durationSeconds: Double

    public init(
        exitCode: Int32,
        logURL: URL,
        items: [DiagnosticItem],
        rawOutput: String,
        timedOut: Bool = false,
        durationSeconds: Double = 0
    ) {
        self.exitCode = exitCode
        self.logURL = logURL
        self.items = items
        self.rawOutput = rawOutput
        self.timedOut = timedOut
        self.durationSeconds = durationSeconds
    }
}

public struct DiagnosticsService {
    public static let defaultProbeSuitePath = "/Users/a1-6/project/Mac-Win/refs/exe-tests/run-suite.sh"

    public var paths: MacWinPaths
    public var fileManager: FileManager
    public var wineRunner: WineRunner
    public var hostGUISessionService: HostGUISessionService

    public init(
        paths: MacWinPaths = MacWinPaths(),
        fileManager: FileManager = .default,
        wineRunner: WineRunner? = nil,
        hostGUISessionService: HostGUISessionService = HostGUISessionService()
    ) {
        self.paths = paths
        self.fileManager = fileManager
        self.wineRunner = wineRunner ?? WineRunner(paths: paths, fileManager: fileManager)
        self.hostGUISessionService = hostGUISessionService
    }

    public func runNativeUIProbe(
        mode: NativeUIProbeMode,
        architecture: WindowsExecutableArchitecture = .x86_64,
        engine: EngineManifest,
        bottle: BottleManifest,
        probeService: NativeUIProbeService? = nil
    ) throws -> NativeUIProbeRunReport {
        guard hostGUISessionService.report().isInteractive else {
            throw MacWinError.guiSessionLocked
        }
        let probeService = probeService ?? NativeUIProbeService(paths: paths)
        guard architecture != .i386 || engine.supportsWin32 else {
            throw MacWinError.unsupportedEngine("Native UI 32-bit probe requires a WoW64-capable engine.")
        }
        guard let executable = probeService.executable(for: architecture) else {
            throw MacWinError.missingFile(
                "native-ui-probe-\(architecture == .i386 ? "i686" : "x86_64").exe"
            )
        }

        let startedAt = Date()
        let result = try wineRunner.run(
            WineRunRequest(
                exe: executable.path,
                args: [mode.argument],
                bottle: bottle,
                engine: engine,
                logName: "native-ui-\(bottle.id)-\(mode.rawValue)-\(architecture.rawValue)-\(UUID().uuidString.prefix(8)).log"
            )
        )
        let endedAt = Date()
        let status: NativeUIProbeRunStatus
        switch result.exitCode {
        case 0:
            status = .passed
        case 2:
            status = .cancelled
        default:
            status = .failed
        }
        return NativeUIProbeRunReport(
            mode: mode,
            architecture: architecture,
            executablePath: executable.path,
            bottleId: bottle.id,
            bottleName: bottle.name,
            engineId: engine.id,
            nativeUIPreset: NativeUIIntegrationPreset.current(in: bottle),
            status: status,
            exitCode: result.exitCode,
            logPath: result.logURL.path,
            output: result.output,
            startedAt: startedAt,
            endedAt: endedAt
        )
    }

    public func runProbeSuite(
        engine: EngineManifest,
        bottle: BottleManifest,
        probeSuitePath: String = Self.defaultProbeSuitePath,
        timeoutSeconds: TimeInterval = 900
    ) throws -> DiagnosticReport {
        guard fileManager.fileExists(atPath: probeSuitePath) else {
            throw MacWinError.missingFile(probeSuitePath)
        }
        return try runProbeCommand(
            commandLine: [probeSuitePath],
            logName: "diagnostics-\(bottle.id)-\(UUID().uuidString.prefix(8)).log",
            probeSuitePath: probeSuitePath,
            probeAssetId: nil,
            engine: engine,
            bottle: bottle,
            timeoutSeconds: timeoutSeconds
        )
    }

    public func runProbe(
        assetId: String,
        engine: EngineManifest,
        bottle: BottleManifest,
        testAssetService: TestAssetService = TestAssetService(),
        timeoutSeconds: TimeInterval = 180
    ) throws -> DiagnosticReport {
        guard let probe = testAssetService.runCommand(forAssetId: assetId) else {
            throw MacWinError.invalidManifest("Unknown probe asset id: \(assetId)")
        }
        guard probe.exists else {
            throw MacWinError.missingFile(probe.executablePath)
        }
        guard let command = probe.command else {
            throw MacWinError.unsupportedEngine(probe.note ?? "Probe \(assetId) cannot be run individually.")
        }
        return try runProbeCommand(
            commandLine: command,
            logName: "diagnostics-\(bottle.id)-\(assetId)-\(UUID().uuidString.prefix(8)).log",
            probeSuitePath: command.first ?? assetId,
            probeAssetId: assetId,
            engine: engine,
            bottle: bottle,
            timeoutSeconds: timeoutSeconds
        )
    }

    public static func parseProbeOutput(_ output: String) -> [DiagnosticItem] {
        let known = [
            ProbeDefinition(id: "console", name: "Win32 Console", category: .core),
            ProbeDefinition(id: "tls_winhttp", name: "WinHTTP TLS", category: .network),
            ProbeDefinition(id: "tls_winhttp_win32", name: "WinHTTP TLS (32-bit)", category: .win32),
            ProbeDefinition(id: "iphlpapi_adapters", name: "Windows Network Adapters", category: .network),
            ProbeDefinition(id: "iphlpapi_adapters_win32", name: "Windows Network Adapters (32-bit)", category: .win32),
            ProbeDefinition(id: "vulkan", name: "Vulkan", category: .graphics),
            ProbeDefinition(id: "d3d11", name: "D3D11", category: .graphics),
            ProbeDefinition(id: "d3d12_device", name: "D3D12/vkd3d", category: .graphics),
            ProbeDefinition(id: "xaudio2", name: "XAudio2", category: .audio),
            ProbeDefinition(id: "d3d9_legacy", name: "D3D9 Legacy", category: .graphics),
            ProbeDefinition(id: "game_loop", name: "D3D11 Game Loop", category: .game),
            ProbeDefinition(id: "game_shader", name: "D3D11 Shader Game Loop", category: .game),
            ProbeDefinition(id: "text_rendering", name: "GDI / DirectWrite Text Rendering", category: .core),
            ProbeDefinition(id: "window_input", name: "Win32 Window / Input", category: .windowing)
        ]
        return known.map { probe in
            let status = probeStatus(id: probe.id, output: output)
            return DiagnosticItem(
                id: probe.id,
                name: probe.name,
                passed: status == .passed,
                detail: detail(for: status),
                category: probe.category,
                status: status
            )
        }
    }

    private static func probeStatus(id: String, output: String) -> DiagnosticStatus {
        if output.contains("PASS \(id)") {
            return .passed
        }
        if output.contains("FAIL \(id)") {
            return .failed
        }
        if output.contains("SKIP \(id)") || (id.hasSuffix("_win32") && output.contains("SKIP win32_probes")) {
            return .skipped
        }
        return .notObserved
    }

    private static func detail(for status: DiagnosticStatus) -> String {
        switch status {
        case .passed:
            "PASS"
        case .failed:
            "FAIL"
        case .skipped:
            "SKIP"
        case .notObserved:
            "Not observed"
        }
    }

    private func probeEnvironment(engine: EngineManifest, bottle: BottleManifest) -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        for (key, value) in HostNetworkEnvironment.current() where environment[key] == nil {
            environment[key] = value
        }
        environment["WINE_BUILD"] = buildRootURL(for: engine).path
        environment["WINE_RUNTIME"] = engine.runtimePath
        environment["WINEPREFIX"] = paths.bottleDirectory(id: bottle.id).path
        environment["WINEARCH"] = bottle.arch.rawValue

        for (key, value) in engine.defaultEnv {
            environment[key] = value
        }
        if engine.supportsWin32 && environment["MACWIN_WINHTTP_IGNORE_UNKNOWN_CA"] == nil {
            environment["MACWIN_WINHTTP_IGNORE_UNKNOWN_CA"] = "1"
        }
        for (key, value) in bottle.envOverrides {
            environment[key] = value
        }
        return environment
    }

    private func buildRootURL(for engine: EngineManifest) -> URL {
        let wineURL = URL(fileURLWithPath: engine.winePath)
        guard wineURL.lastPathComponent == "wine" else {
            return wineURL.deletingLastPathComponent()
        }
        let loaderURL = wineURL.deletingLastPathComponent()
        return loaderURL.deletingLastPathComponent()
    }

    private func runProbeCommand(
        commandLine: [String],
        logName: String,
        probeSuitePath: String,
        probeAssetId: String?,
        engine: EngineManifest,
        bottle: BottleManifest,
        timeoutSeconds: TimeInterval
    ) throws -> DiagnosticReport {
        try paths.ensureBaseDirectories(fileManager: fileManager)
        try prepareCommonAppData(for: bottle)
        let logURL = paths.logsDirectory.appendingPathComponent(logName)
        let environment = probeEnvironment(engine: engine, bottle: bottle)
        let startedAt = Date()
        let command = try probeCommand(commandLine)
        let process = Process()
        process.executableURL = command.executable
        process.arguments = command.arguments
        process.environment = environment
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        let processExited = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in
            processExited.signal()
        }

        let outputBuffer = DiagnosticOutputBuffer()
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            outputBuffer.append(data)
        }

        try process.run()
        var timedOut = false
        if processExited.wait(timeout: .now() + max(timeoutSeconds, 0.05)) == .timedOut {
            timedOut = true
            process.terminate()
            if processExited.wait(timeout: .now() + 5) == .timedOut {
                kill(process.processIdentifier, SIGKILL)
                _ = processExited.wait(timeout: .now() + 5)
            }
        }

        pipe.fileHandleForReading.readabilityHandler = nil
        if !timedOut {
            outputBuffer.append(pipe.fileHandleForReading.readDataToEndOfFile())
        }
        try? pipe.fileHandleForReading.close()
        let data = outputBuffer.snapshot()

        let endedAt = Date()
        let duration = endedAt.timeIntervalSince(startedAt)
        let output = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
        let exitCode: Int32 = timedOut ? 124 : process.terminationStatus
        let processCommandLine = [command.executable.path] + command.arguments
        let logData = Self.logData(
            output: output,
            probeSuitePath: probeSuitePath,
            probeAssetId: probeAssetId,
            commandLine: processCommandLine,
            engine: engine,
            bottle: bottle,
            environment: environment,
            startedAt: startedAt,
            endedAt: endedAt,
            timeoutSeconds: timeoutSeconds,
            timedOut: timedOut,
            exitCode: exitCode
        )
        try logData.write(to: logURL, options: [.atomic])

        return DiagnosticReport(
            exitCode: exitCode,
            logURL: logURL,
            items: Self.parseProbeOutput(output),
            rawOutput: output,
            timedOut: timedOut,
            durationSeconds: duration
        )
    }

    private func prepareCommonAppData(for bottle: BottleManifest) throws {
        let programDataURL = paths.bottleDirectory(id: bottle.id)
            .appendingPathComponent("drive_c/ProgramData", isDirectory: true)
        try fileManager.createDirectory(
            at: programDataURL,
            withIntermediateDirectories: true
        )
    }

    private func probeCommand(_ commandLine: [String]) throws -> (executable: URL, arguments: [String]) {
        guard let executable = commandLine.first else {
            throw MacWinError.invalidPath("Empty probe command")
        }
        let arguments = Array(commandLine.dropFirst())
        if executable.hasSuffix(".sh") {
            return (URL(fileURLWithPath: "/bin/bash"), [executable] + arguments)
        }
        return (URL(fileURLWithPath: executable), arguments)
    }

    private static func logData(
        output: String,
        probeSuitePath: String,
        probeAssetId: String?,
        commandLine: [String],
        engine: EngineManifest,
        bottle: BottleManifest,
        environment: [String: String],
        startedAt: Date,
        endedAt: Date,
        timeoutSeconds: TimeInterval,
        timedOut: Bool,
        exitCode: Int32
    ) -> Data {
        let formatter = ISO8601DateFormatter()
        var lines = [
            "----- MacWin diagnostics -----",
            "startedAt=\(formatter.string(from: startedAt))",
            "endedAt=\(formatter.string(from: endedAt))",
            "durationSeconds=\(String(format: "%.3f", endedAt.timeIntervalSince(startedAt)))",
            "timeoutSeconds=\(String(format: "%.3f", timeoutSeconds))",
            "timedOut=\(timedOut)",
            "exitCode=\(exitCode)",
            "bottleId=\(bottle.id)",
            "bottleName=\(bottle.name)",
            "engineId=\(engine.id)",
            "probeSuite=\(probeSuitePath)",
            "command=\(commandLine.joined(separator: " "))"
        ]
        if let probeAssetId {
            lines.append("probeAssetId=\(probeAssetId)")
        }
        for key in loggedEnvironmentKeys {
            guard let value = environment[key] else { continue }
            lines.append("env.\(key)=\(value)")
        }
        lines.append("------------------------------")
        lines.append("")
        lines.append(output)
        if !output.hasSuffix("\n") {
            lines.append("")
        }
        lines.append("----- MacWin diagnostics result -----")
        lines.append("timedOut=\(timedOut)")
        lines.append("exitCode=\(exitCode)")
        lines.append("------------------------------------")
        lines.append("")
        return Data(lines.joined(separator: "\n").utf8)
    }

    private static let loggedEnvironmentKeys = [
        "WINE_BUILD",
        "WINE_RUNTIME",
        "WINEPREFIX",
        "WINEARCH",
        "WINE_D3D_CONFIG",
        "WINEDLLOVERRIDES",
        "WINEDLLPATH",
        "MACWIN_GRAPHICS_PRESET",
        "MACWIN_WINHTTP_IGNORE_UNKNOWN_CA",
        "MACWIN_HOST_IPV4",
        "MACWIN_GATEWAY_IPV4",
        "MACWIN_DNS_IPV4"
    ]

    private struct ProbeDefinition {
        var id: String
        var name: String
        var category: DiagnosticCategory
    }
}

private final class DiagnosticOutputBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()

    func append(_ newData: Data) {
        guard !newData.isEmpty else { return }
        lock.lock()
        data.append(newData)
        lock.unlock()
    }

    func snapshot() -> Data {
        lock.lock()
        let result = data
        lock.unlock()
        return result
    }
}
