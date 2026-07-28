import Foundation
import Testing
@testable import MacWinCore

@Suite("Graphics presets")
struct GraphicsPresetTests {
    @Test("D3DMetal environment points at GPTK runtime")
    func d3dMetalEnvironmentUsesGPTKRuntime() throws {
        let runtime = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinGPTKRuntime-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: runtime) }
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/bin/echo",
            wineserverPath: "/bin/echo",
            runtimePath: runtime.path,
            defaultEnv: ["WINE_D3D_CONFIG": "renderer=vulkan,csmt=0x0"]
        )

        let env = GraphicsPreset.gptkD3DMetal.environment(engine: engine)
        let paths = GraphicsPreset.gptkPaths(engine: engine)

        #expect(env[GraphicsPreset.environmentKey] == GraphicsPreset.gptkD3DMetal.rawValue)
        #expect(env["WINEDLLPATH"] == paths.winePath)
        #expect(env["MACWIN_PREFER_WINEDLLPATH"] == "1")
        #expect(env["WINEDLLOVERRIDES"] == "dxgi,d3d12,nvapi64,nvngx=n,b")
        #expect(env["DYLD_LIBRARY_PATH"] == paths.externalPath)
        #expect(env["DYLD_FALLBACK_LIBRARY_PATH"] == paths.externalPath)
        #expect(env["DYLD_FRAMEWORK_PATH"] == paths.externalPath)
        #expect(env["WINE_D3D_CONFIG"] == nil)
    }

    @Test("D3DMetal availability requires framework and unix DLL shims")
    func d3dMetalAvailabilityChecksRuntimeFiles() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinGPTKAvailability-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/bin/echo",
            wineserverPath: "/bin/echo",
            runtimePath: root.path,
            defaultEnv: [:]
        )
        let paths = GraphicsPreset.gptkPaths(engine: engine)

        #expect(!GraphicsPreset.gptkD3DMetal.isAvailable(engine: engine))

        try FileManager.default.createDirectory(
            at: URL(fileURLWithPath: paths.d3dMetalFrameworkPath),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: URL(fileURLWithPath: paths.d3d12UnixPath).deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data().write(to: URL(fileURLWithPath: paths.d3d12UnixPath))
        try Data().write(to: URL(fileURLWithPath: paths.dxgiUnixPath))

        #expect(!GraphicsPreset.gptkD3DMetal.isAvailable(engine: engine))

        try Data().write(to: URL(fileURLWithPath: paths.compatibilityMarkerPath))

        #expect(GraphicsPreset.gptkD3DMetal.isAvailable(engine: engine))
        #expect(GraphicsPreset.gptkD3DMetalDXR.isAvailable(engine: engine))
    }

    @Test("Applying graphics presets swaps only managed graphics environment")
    func applyingPresetSwapsManagedEnvironment() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinGraphicsPresetTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let service = BottleService(paths: MacWinPaths(root: root))
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/bin/echo",
            wineserverPath: "/bin/echo",
            runtimePath: "/runtime",
            defaultEnv: ["WINE_D3D_CONFIG": "renderer=vulkan,csmt=0x0"]
        )
        let bottle = try service.createBottle(
            id: "game",
            name: "Game",
            template: BottleTemplate(windowsVersion: "win11", arch: .win64),
            engine: engine,
            envOverrides: [
                "WINE_D3D_CONFIG": "renderer=vulkan,csmt=0x0",
                "WINEDEBUG": "-all",
                "CUSTOM": "keep"
            ],
            runWineboot: false
        )

        let d3dMetal = try service.applyGraphicsPreset(.gptkD3DMetal, to: bottle, engine: engine)
        #expect(d3dMetal.envOverrides[GraphicsPreset.environmentKey] == GraphicsPreset.gptkD3DMetal.rawValue)
        #expect(d3dMetal.envOverrides["WINEDLLOVERRIDES"] == "dxgi,d3d12,nvapi64,nvngx=n,b")
        #expect(d3dMetal.envOverrides["WINE_D3D_CONFIG"] == nil)
        #expect(d3dMetal.envOverrides["WINEDEBUG"] == "-all")
        #expect(d3dMetal.envOverrides["CUSTOM"] == "keep")

        let stable = try service.applyGraphicsPreset(.wineD3DVulkan, to: d3dMetal, engine: engine)
        #expect(stable.envOverrides[GraphicsPreset.environmentKey] == GraphicsPreset.wineD3DVulkan.rawValue)
        #expect(stable.envOverrides["WINE_D3D_CONFIG"] == "renderer=vulkan,csmt=0x0")
        #expect(stable.envOverrides["WINEDLLOVERRIDES"] == nil)
        #expect(stable.envOverrides["DYLD_LIBRARY_PATH"] == nil)
        #expect(stable.envOverrides["WINEDEBUG"] == "-all")
        #expect(stable.envOverrides["CUSTOM"] == "keep")
    }
}
