import Foundation

public enum GraphicsPreset: String, Codable, CaseIterable, Sendable {
    case wineD3DVulkan = "wined3d-vulkan"
    case gptkD3DMetal = "gptk-d3dmetal"
    case gptkD3DMetalDXR = "gptk-d3dmetal-dxr"

    public static let environmentKey = "MACWIN_GRAPHICS_PRESET"

    public static let managedEnvironmentKeys: Set<String> = [
        environmentKey,
        "WINE_D3D_CONFIG",
        "WINEDLLPATH",
        "MACWIN_PREFER_WINEDLLPATH",
        "WINEDLLOVERRIDES",
        "DYLD_LIBRARY_PATH",
        "DYLD_FALLBACK_LIBRARY_PATH",
        "DYLD_FRAMEWORK_PATH",
        "D3DM_SUPPORT_DXR"
    ]

    public static func current(in bottle: BottleManifest) -> GraphicsPreset {
        if let rawValue = bottle.envOverrides[environmentKey],
           let preset = GraphicsPreset(rawValue: rawValue) {
            return preset
        }
        if bottle.envOverrides["WINEDLLOVERRIDES"]?.contains("d3d12") == true {
            return .gptkD3DMetal
        }
        return .wineD3DVulkan
    }

    public func environment(engine: EngineManifest) -> [String: String] {
        switch self {
        case .wineD3DVulkan:
            return [
                Self.environmentKey: rawValue,
                "WINE_D3D_CONFIG": engine.defaultEnv["WINE_D3D_CONFIG"] ?? "renderer=vulkan,csmt=0x0"
            ]
        case .gptkD3DMetal, .gptkD3DMetalDXR:
            let gptk = Self.gptkPaths(engine: engine)
            var env = [
                Self.environmentKey: rawValue,
                "WINEDLLPATH": gptk.winePath,
                "MACWIN_PREFER_WINEDLLPATH": "1",
                "WINEDLLOVERRIDES": "dxgi,d3d12,nvapi64,nvngx=n,b",
                "DYLD_LIBRARY_PATH": gptk.externalPath,
                "DYLD_FALLBACK_LIBRARY_PATH": gptk.externalPath,
                "DYLD_FRAMEWORK_PATH": gptk.externalPath
            ]
            if self == .gptkD3DMetalDXR {
                env["D3DM_SUPPORT_DXR"] = "1"
            }
            return env
        }
    }

    public func isAvailable(engine: EngineManifest, fileManager: FileManager = .default) -> Bool {
        switch self {
        case .wineD3DVulkan:
            return true
        case .gptkD3DMetal, .gptkD3DMetalDXR:
            let gptk = Self.gptkPaths(engine: engine)
            return fileManager.fileExists(atPath: gptk.d3dMetalFrameworkPath)
                && fileManager.fileExists(atPath: gptk.d3d12UnixPath)
                && fileManager.fileExists(atPath: gptk.dxgiUnixPath)
                && fileManager.fileExists(atPath: gptk.compatibilityMarkerPath)
        }
    }

    public static func gptkPaths(engine: EngineManifest) -> GPTKPaths {
        let root = URL(fileURLWithPath: engine.runtimePath)
            .appendingPathComponent("lib64/apple_gptk", isDirectory: true)
        let wine = root.appendingPathComponent("wine", isDirectory: true)
        let external = root.appendingPathComponent("external", isDirectory: true)
        let unix = wine.appendingPathComponent("x86_64-unix", isDirectory: true)
        let windows = wine.appendingPathComponent("x86_64-windows", isDirectory: true)
        return GPTKPaths(
            rootPath: root.path,
            winePath: wine.path,
            unixWinePath: unix.path,
            windowsWinePath: windows.path,
            externalPath: external.path,
            d3dMetalFrameworkPath: external.appendingPathComponent("D3DMetal.framework").path,
            d3d12UnixPath: unix.appendingPathComponent("d3d12.so").path,
            dxgiUnixPath: unix.appendingPathComponent("dxgi.so").path,
            compatibilityMarkerPath: root.appendingPathComponent(".macwin-d3dmetal-compatible").path
        )
    }
}

public struct GPTKPaths: Equatable, Sendable {
    public var rootPath: String
    public var winePath: String
    public var unixWinePath: String
    public var windowsWinePath: String
    public var externalPath: String
    public var d3dMetalFrameworkPath: String
    public var d3d12UnixPath: String
    public var dxgiUnixPath: String
    public var compatibilityMarkerPath: String
}
