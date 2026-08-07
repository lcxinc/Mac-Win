import Foundation
import Testing
@testable import MacWinCore

@Suite("Mac native UI integration")
struct NativeUIIntegrationTests {
    @Test("Presets expose only their intended capabilities")
    func presetCapabilities() {
        #expect(NativeUIIntegrationPreset.disabled.capabilities.isEmpty)
        #expect(NativeUIIntegrationPreset.windowIntegration.capabilities == [.windowChrome])
        #expect(NativeUIIntegrationPreset.nativeDialogs.capabilities == [
            .windowChrome, .alerts, .fileDialogs, .modernFileDialogs, .taskDialogs
        ])
        #expect(NativeUIIntegrationPreset.nativeDialogs.environmentValue ==
                "alerts,file-dialogs,modern-file-dialogs,task-dialogs,window-chrome")
        #expect(NativeUIIntegrationPreset.automatic.environmentValue ==
                "automatic,alerts,file-dialogs,modern-file-dialogs,task-dialogs,window-chrome")
    }

    @Test("Unknown and legacy environment values fail closed")
    func environmentParsingFailsClosed() {
        #expect(NativeUIIntegrationPreset.from(environmentValue: nil) == .disabled)
        #expect(NativeUIIntegrationPreset.from(environmentValue: "off") == .disabled)
        #expect(NativeUIIntegrationPreset.from(environmentValue: "unexpected") == .disabled)
        #expect(NativeUIIntegrationPreset.from(environmentValue: "window-chrome") == .windowIntegration)
        #expect(NativeUIIntegrationPreset.from(environmentValue: "WINDOW-CHROME, ALERTS") == .nativeDialogs)
        #expect(NativeUIIntegrationPreset.from(environmentValue: "automatic,window-chrome") == .automatic)
    }

    @Test("Applying a preset persists it without changing unrelated bottle settings")
    func applyingPresetPersistsManagedEnvironment() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinNativeUITests-\(UUID().uuidString)", isDirectory: true)
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
            defaultEnv: [:]
        )
        let bottle = try service.createBottle(
            id: "productivity",
            name: "Productivity",
            template: BottleTemplate(windowsVersion: "win11", arch: .win64),
            engine: engine,
            envOverrides: ["CUSTOM": "keep"],
            runWineboot: false
        )

        let updated = try service.applyNativeUIIntegrationPreset(.nativeDialogs, to: bottle)
        let loaded = try service.bottle(id: bottle.id)
        let persisted = try #require(loaded)

        #expect(updated.envOverrides[NativeUIIntegrationPreset.environmentKey] ==
                "alerts,file-dialogs,modern-file-dialogs,task-dialogs,window-chrome")
        #expect(persisted.id == updated.id)
        #expect(persisted.engineId == updated.engineId)
        #expect(persisted.envOverrides == updated.envOverrides)
        #expect(persisted.installedApps == updated.installedApps)
        #expect(persisted.envOverrides["CUSTOM"] == "keep")
    }
}
