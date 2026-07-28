import Foundation

public struct EngineRegistry {
    public static let wineVersionDetectionTimeout: TimeInterval = 3
    public static let currentGameEngineId = "wine-11.11-x86_64-game"
    public static let currentWoW64GameEngineId = "wine-11.11-wow64-game"
    public static let currentBuildPath = "/Users/a1-6/project/Mac-Win/refs/Whisky-x86_64-game-build"
    public static let currentWoW64BuildPath = "/Users/a1-6/project/Mac-Win/refs/Whisky-wow64-game-build"
    public static let currentRuntimePath = "/Users/a1-6/project/Mac-Win/refs/crossover-runtime-x86_64"
    public static let currentRosettaX87Path = "/Users/a1-6/project/Mac-Win/refs/rosettax87/build/rosettax87"

    public var paths: MacWinPaths
    public var store: JSONStore
    public var fileManager: FileManager
    public var wineVersionDetector: (String) -> String?
    public var runtimeProbeAllowed: () -> Bool

    public init(
        paths: MacWinPaths = MacWinPaths(),
        fileManager: FileManager = .default,
        wineVersionDetector: @escaping (String) -> String? = Self.detectWineVersion,
        runtimeProbeAllowed: @escaping () -> Bool = {
            RuntimeProcessAuditService().makeReport().uninterruptibleProcessIdentifiers.isEmpty
        }
    ) {
        self.paths = paths
        self.store = JSONStore(fileManager: fileManager)
        self.fileManager = fileManager
        self.wineVersionDetector = wineVersionDetector
        self.runtimeProbeAllowed = runtimeProbeAllowed
    }

    public func listEngines() throws -> [EngineManifest] {
        try paths.ensureBaseDirectories(fileManager: fileManager)
        return try store.loadMany(EngineManifest.self, in: paths.enginesDirectory, fileName: "manifest.json")
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    public func engine(id: String) throws -> EngineManifest? {
        let url = paths.engineManifestURL(id: id)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        return try store.load(EngineManifest.self, from: url)
    }

    @discardableResult
    public func importCurrentGameEngine(
        buildURL: URL = URL(fileURLWithPath: currentBuildPath, isDirectory: true),
        runtimeURL: URL = URL(fileURLWithPath: currentRuntimePath, isDirectory: true)
    ) throws -> EngineManifest {
        let legacyEngine = try importGameEngine(
            id: Self.currentGameEngineId,
            name: "Wine 11.11 x86_64 Game",
            buildURL: buildURL,
            runtimeURL: runtimeURL,
            supportsWin32: false
        )

        let wow64URL = URL(fileURLWithPath: Self.currentWoW64BuildPath, isDirectory: true)
        if let wow64Engine = try importGameEngineIfAvailable(
            id: Self.currentWoW64GameEngineId,
            name: "Wine 11.11 WoW64 Game",
            buildURL: wow64URL,
            runtimeURL: runtimeURL,
            supportsWin32: true
        ) {
            return wow64Engine
        }

        return legacyEngine
    }

    @discardableResult
    public func importCurrentWoW64GameEngine(
        buildURL: URL = URL(fileURLWithPath: currentWoW64BuildPath, isDirectory: true),
        runtimeURL: URL = URL(fileURLWithPath: currentRuntimePath, isDirectory: true)
    ) throws -> EngineManifest {
        try importGameEngine(
            id: Self.currentWoW64GameEngineId,
            name: "Wine 11.11 WoW64 Game",
            buildURL: buildURL,
            runtimeURL: runtimeURL,
            supportsWin32: true
        )
    }

    private func importGameEngineIfAvailable(
        id: String,
        name: String,
        buildURL: URL,
        runtimeURL: URL,
        supportsWin32: Bool
    ) throws -> EngineManifest? {
        let wineURL = buildURL.appendingPathComponent("loader/wine")
        let wineserverURL = buildURL.appendingPathComponent("server/wineserver")
        guard fileManager.fileExists(atPath: wineURL.path),
              fileManager.fileExists(atPath: wineserverURL.path),
              fileManager.fileExists(atPath: runtimeURL.path) else {
            return nil
        }
        if supportsWin32, !hasWin32SystemDLLs(buildURL: buildURL) {
            return nil
        }
        return try importGameEngine(
            id: id,
            name: name,
            buildURL: buildURL,
            runtimeURL: runtimeURL,
            supportsWin32: supportsWin32
        )
    }

    private func importGameEngine(
        id: String,
        name: String,
        buildURL: URL,
        runtimeURL: URL,
        supportsWin32: Bool
    ) throws -> EngineManifest {
        let wineURL = buildURL.appendingPathComponent("loader/wine")
        let wineserverURL = buildURL.appendingPathComponent("server/wineserver")
        guard fileManager.fileExists(atPath: wineURL.path) else {
            throw MacWinError.missingFile(wineURL.path)
        }
        guard fileManager.fileExists(atPath: wineserverURL.path) else {
            throw MacWinError.missingFile(wineserverURL.path)
        }
        guard fileManager.fileExists(atPath: runtimeURL.path) else {
            throw MacWinError.missingFile(runtimeURL.path)
        }
        if supportsWin32, let missing = missingWin32SystemFile(buildURL: buildURL) {
            throw MacWinError.missingFile(missing.path)
        }

        try paths.ensureBaseDirectories(fileManager: fileManager)
        let engineDirectory = paths.engineDirectory(id: id)
        try fileManager.createDirectory(at: engineDirectory, withIntermediateDirectories: true)

        let buildLink = engineDirectory.appendingPathComponent("build")
        let runtimeLink = engineDirectory.appendingPathComponent("runtime")
        try replaceSymlink(at: buildLink, destination: buildURL)
        try replaceSymlink(at: runtimeLink, destination: runtimeURL)

        let linkedWine = buildLink.appendingPathComponent("loader/wine")
        let linkedWineserver = buildLink.appendingPathComponent("server/wineserver")
        let linkedRuntime = runtimeLink
        let gstreamerPath = linkedRuntime.appendingPathComponent("lib64/gstreamer-1.0").path

        var defaultEnv = [
            "WINEARCH": "win64",
            "WINE_D3D_CONFIG": "renderer=vulkan,csmt=0x0",
            "GST_PLUGIN_SYSTEM_PATH_1_0": gstreamerPath,
            "GST_PLUGIN_PATH_1_0": gstreamerPath
        ]
        if supportsWin32 {
            defaultEnv["MACWIN_WINHTTP_IGNORE_UNKNOWN_CA"] = "1"
        }

        let existingVersion = (try? engine(id: id))?.wineVersion
        let wineVersion = runtimeProbeAllowed()
            ? wineVersionDetector(linkedWine.path)
            : existingVersion
        let manifest = EngineManifest(
            id: id,
            name: name,
            wineVersion: wineVersion ?? "wine-11.11",
            arch: .win64,
            supportsWin32: supportsWin32,
            winePath: linkedWine.path,
            wineserverPath: linkedWineserver.path,
            runtimePath: linkedRuntime.path,
            defaultEnv: defaultEnv,
            healthChecks: [
                HealthCheck(id: "wine-version", name: "Wine Version", command: ["--version"]),
                HealthCheck(id: "vulkan-probe", name: "Vulkan Probe", command: ["/Users/a1-6/project/Mac-Win/refs/exe-tests/bin/20_vulkan_probe.exe"]),
                HealthCheck(id: "game-shader", name: "D3D11 Shader Probe", command: ["/Users/a1-6/project/Mac-Win/refs/exe-tests/bin/60_game_shader_probe.exe"])
            ]
        )

        try store.save(manifest, to: paths.engineManifestURL(id: manifest.id))
        return manifest
    }

    private func hasWin32SystemDLLs(buildURL: URL) -> Bool {
        missingWin32SystemFile(buildURL: buildURL) == nil
    }

    private func missingWin32SystemFile(buildURL: URL) -> URL? {
        Self.requiredWin32EngineFiles
            .map { buildURL.appendingPathComponent($0) }
            .first { !fileManager.fileExists(atPath: $0.path) }
    }

    private static let requiredWin32EngineFiles = [
        "dlls/ntdll/i386-windows/ntdll.dll",
        "dlls/kernel32/i386-windows/kernel32.dll",
        "dlls/wow64/x86_64-windows/wow64.dll",
        "dlls/wow64cpu/x86_64-windows/wow64cpu.dll",
        "dlls/wow64win/x86_64-windows/wow64win.dll",
        "programs/winedevice/i386-windows/winedevice.exe",
        "programs/winedevice/x86_64-windows/winedevice.exe",
        "dlls/vulkan-1/i386-windows/vulkan-1.dll",
        "dlls/vulkan-1/x86_64-windows/vulkan-1.dll",
        "dlls/winevulkan/i386-windows/winevulkan.dll",
        "dlls/winevulkan/x86_64-windows/winevulkan.dll",
        "dlls/winevulkan/winevulkan.so",
        "dlls/dwrite/dwrite.so",
        "dlls/opengl32/i386-windows/opengl32.dll",
        "dlls/opengl32/x86_64-windows/opengl32.dll",
        "dlls/wined3d/i386-windows/wined3d.dll",
        "dlls/wined3d/x86_64-windows/wined3d.dll",
        "dlls/d3d9/i386-windows/d3d9.dll",
        "dlls/d3d9/x86_64-windows/d3d9.dll",
        "dlls/d3d11/i386-windows/d3d11.dll",
        "dlls/d3d11/x86_64-windows/d3d11.dll",
        "dlls/d3d12/i386-windows/d3d12.dll",
        "dlls/d3d12/x86_64-windows/d3d12.dll",
        "dlls/dxgi/i386-windows/dxgi.dll",
        "dlls/dxgi/x86_64-windows/dxgi.dll",
        "dlls/d3dcompiler_47/i386-windows/d3dcompiler_47.dll",
        "dlls/d3dcompiler_47/x86_64-windows/d3dcompiler_47.dll",
        "dlls/comctl32_v6/i386-windows/comctl32_v6.dll",
        "dlls/comctl32_v6/x86_64-windows/comctl32_v6.dll",
        "dlls/mfplat/i386-windows/mfplat.dll",
        "dlls/mfplat/x86_64-windows/mfplat.dll",
        "dlls/mfreadwrite/i386-windows/mfreadwrite.dll",
        "dlls/mfreadwrite/x86_64-windows/mfreadwrite.dll",
        "dlls/mmdevapi/i386-windows/mmdevapi.dll",
        "dlls/mmdevapi/x86_64-windows/mmdevapi.dll",
        "dlls/msctf/i386-windows/msctf.dll",
        "dlls/msctf/x86_64-windows/msctf.dll",
        "dlls/rsaenh/i386-windows/rsaenh.dll",
        "dlls/rsaenh/x86_64-windows/rsaenh.dll",
        "dlls/uiautomationcore/i386-windows/uiautomationcore.dll",
        "dlls/uiautomationcore/x86_64-windows/uiautomationcore.dll",
        "dlls/oleacc/i386-windows/oleacc.dll",
        "dlls/oleacc/x86_64-windows/oleacc.dll",
        "dlls/wevtapi/i386-windows/wevtapi.dll",
        "dlls/wevtapi/x86_64-windows/wevtapi.dll",
        "dlls/wevtsvc/i386-windows/wevtsvc.dll",
        "dlls/wevtsvc/x86_64-windows/wevtsvc.dll",
        "dlls/cryptui/i386-windows/cryptui.dll",
        "dlls/cryptui/x86_64-windows/cryptui.dll",
        "dlls/credui/i386-windows/credui.dll",
        "dlls/credui/x86_64-windows/credui.dll",
        "dlls/esent/i386-windows/esent.dll",
        "dlls/esent/x86_64-windows/esent.dll",
        "dlls/iphlpapi/i386-windows/iphlpapi.dll",
        "dlls/iphlpapi/x86_64-windows/iphlpapi.dll",
        "dlls/powrprof/i386-windows/powrprof.dll",
        "dlls/powrprof/x86_64-windows/powrprof.dll",
        "dlls/netapi32/i386-windows/netapi32.dll",
        "dlls/netapi32/x86_64-windows/netapi32.dll",
        "dlls/netapi32/netapi32.so",
        "dlls/qmgr/i386-windows/qmgr.dll",
        "dlls/qmgr/x86_64-windows/qmgr.dll",
        "dlls/rstrtmgr/i386-windows/rstrtmgr.dll",
        "dlls/rstrtmgr/x86_64-windows/rstrtmgr.dll",
        "dlls/concrt140/i386-windows/concrt140.dll",
        "dlls/concrt140/x86_64-windows/concrt140.dll",
        "dlls/vcomp/i386-windows/vcomp.dll",
        "dlls/vcomp/x86_64-windows/vcomp.dll",
        "dlls/vcomp90/i386-windows/vcomp90.dll",
        "dlls/vcomp90/x86_64-windows/vcomp90.dll",
        "dlls/vcomp100/i386-windows/vcomp100.dll",
        "dlls/vcomp100/x86_64-windows/vcomp100.dll",
        "dlls/vcomp110/i386-windows/vcomp110.dll",
        "dlls/vcomp110/x86_64-windows/vcomp110.dll",
        "dlls/vcomp120/i386-windows/vcomp120.dll",
        "dlls/vcomp120/x86_64-windows/vcomp120.dll",
        "dlls/vcomp140/i386-windows/vcomp140.dll",
        "dlls/vcomp140/x86_64-windows/vcomp140.dll",
        "dlls/wintab32/i386-windows/wintab32.dll",
        "dlls/wintab32/x86_64-windows/wintab32.dll",
        "dlls/wlanapi/i386-windows/wlanapi.dll",
        "dlls/wlanapi/x86_64-windows/wlanapi.dll",
        "dlls/webservices/i386-windows/webservices.dll",
        "dlls/webservices/x86_64-windows/webservices.dll",
        "dlls/windows.ui/i386-windows/windows.ui.dll",
        "dlls/windows.ui/x86_64-windows/windows.ui.dll",
        "dlls/taskschd/i386-windows/taskschd.dll",
        "dlls/taskschd/x86_64-windows/taskschd.dll",
        "dlls/mstask/i386-windows/mstask.dll",
        "dlls/mstask/x86_64-windows/mstask.dll",
        "dlls/schedsvc/i386-windows/schedsvc.dll",
        "dlls/schedsvc/x86_64-windows/schedsvc.dll",
        "dlls/kerberos/i386-windows/kerberos.dll",
        "dlls/kerberos/x86_64-windows/kerberos.dll",
        "dlls/kerberos/kerberos.so",
        "dlls/msv1_0/i386-windows/msv1_0.dll",
        "dlls/msv1_0/x86_64-windows/msv1_0.dll",
        "dlls/msv1_0/msv1_0.so",
        "dlls/rtworkq/i386-windows/rtworkq.dll",
        "dlls/rtworkq/x86_64-windows/rtworkq.dll",
        "dlls/xaudio2_7/i386-windows/xaudio2_7.dll",
        "dlls/xaudio2_7/x86_64-windows/xaudio2_7.dll",
        "dlls/xaudio2_8/i386-windows/xaudio2_8.dll",
        "dlls/xaudio2_8/x86_64-windows/xaudio2_8.dll",
        "dlls/xaudio2_9/i386-windows/xaudio2_9.dll",
        "dlls/xaudio2_9/x86_64-windows/xaudio2_9.dll",
        "dlls/winemac.drv/i386-windows/winemac.drv",
        "dlls/winemac.drv/x86_64-windows/winemac.drv",
        "dlls/winecoreaudio.drv/winecoreaudio.so",
        "dlls/hidparse.sys/i386-windows/hidparse.sys",
        "dlls/hidparse.sys/x86_64-windows/hidparse.sys",
        "dlls/mountmgr.sys/i386-windows/mountmgr.sys",
        "dlls/mountmgr.sys/x86_64-windows/mountmgr.sys",
        "dlls/mountmgr.sys/mountmgr.so",
        "dlls/ndis.sys/i386-windows/ndis.sys",
        "dlls/ndis.sys/x86_64-windows/ndis.sys",
        "dlls/nsiproxy.sys/i386-windows/nsiproxy.sys",
        "dlls/nsiproxy.sys/x86_64-windows/nsiproxy.sys",
        "dlls/nsiproxy.sys/nsiproxy.so",
        "dlls/winebus.sys/i386-windows/winebus.sys",
        "dlls/winebus.sys/x86_64-windows/winebus.sys",
        "dlls/winebus.sys/winebus.so"
    ]

    public static func detectWineVersion(winePath: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/arch")
        process.arguments = ["-x86_64", winePath, "--version"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        let semaphore = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in
            semaphore.signal()
        }
        do {
            try process.run()
            guard semaphore.wait(timeout: .now() + Self.wineVersionDetectionTimeout) == .success else {
                process.interrupt()
                process.terminate()
                return nil
            }
            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    private func replaceSymlink(at linkURL: URL, destination: URL) throws {
        if fileManager.fileExists(atPath: linkURL.path) {
            try fileManager.removeItem(at: linkURL)
        }
        try fileManager.createSymbolicLink(at: linkURL, withDestinationURL: destination)
    }
}
