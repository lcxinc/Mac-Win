import Foundation
import Testing
@testable import MacWinCore

@Suite("Manifest models")
struct ManifestTests {
    @Test("Engine manifest round-trips through JSON")
    func engineRoundTrip() throws {
        let store = JSONStore()
        let manifest = EngineManifest(
            id: "wine-11.11-x86_64-game",
            name: "Wine 11.11 x86_64 Game",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/tmp/Engine With Spaces/loader/wine",
            wineserverPath: "/tmp/Engine With Spaces/server/wineserver",
            runtimePath: "/tmp/runtime",
            defaultEnv: ["WINE_D3D_CONFIG": "renderer=vulkan,csmt=0x0"],
            healthChecks: [HealthCheck(id: "version", name: "Version", command: ["--version"])]
        )

        let data = try store.encoder.encode(manifest)
        let decoded = try store.decoder.decode(EngineManifest.self, from: data)
        #expect(decoded == manifest)
    }

    @Test("Installer spec decodes missing arguments as empty")
    func installerArgumentsDefault() throws {
        let data = Data("""
        {
          "mode": "download",
          "url": "file:///tmp/setup.exe",
          "fileName": "setup.exe",
          "sha256": "abc",
          "hints": []
        }
        """.utf8)

        let installer = try JSONStore().decoder.decode(InstallerSpec.self, from: data)

        #expect(installer.arguments == [])
        #expect(installer.mode == .download)
    }

    @Test("Bottle manifest preserves launchers and dates")
    func bottleRoundTrip() throws {
        let store = JSONStore()
        let date = Date(timeIntervalSince1970: 1_786_176_000)
        let launcher = LauncherManifest(
            id: "米-launcher",
            appId: "hoyoplay-cn",
            bottleId: "米-bottle",
            displayName: "米哈游启动器",
            exePath: "/tmp/Program Files/HYP.exe",
            args: ["--flag"],
            envOverrides: ["A": "B"]
        )
        let manifest = BottleManifest(
            id: "米-bottle",
            name: "米",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine",
            envOverrides: ["WINEDEBUG": "-all"],
            installedApps: [launcher],
            createdAt: date,
            updatedAt: date
        )

        let data = try store.encoder.encode(manifest)
        let decoded = try store.decoder.decode(BottleManifest.self, from: data)
        #expect(decoded == manifest)
    }

    @Test("Engine requirement accepts supported arch")
    func engineRequirement() {
        let legacyEngine = EngineManifest(
            id: "e",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/wine",
            wineserverPath: "/wineserver",
            runtimePath: "/runtime",
            defaultEnv: [:],
            healthChecks: []
        )
        let wow64Engine = EngineManifest(
            id: "wow64",
            name: "Engine WoW64",
            wineVersion: "wine-11.11",
            arch: .win64,
            supportsWin32: true,
            winePath: "/wine",
            wineserverPath: "/wineserver",
            runtimePath: "/runtime",
            defaultEnv: [:],
            healthChecks: []
        )
        #expect(EngineRequirements(supportedArch: [.win64]).isSatisfied(by: legacyEngine))
        #expect(!EngineRequirements(supportedArch: [.win64], requiresWin32: true).isSatisfied(by: legacyEngine))
        #expect(EngineRequirements(supportedArch: [.win64], requiresWin32: true).isSatisfied(by: wow64Engine))
    }

    @Test("Legacy engine manifest decodes without Win32 support flag")
    func legacyEngineManifestDefaultsWin32Support() throws {
        let data = Data("""
        {
          "id": "legacy",
          "name": "Legacy",
          "wineVersion": "wine-11.11",
          "arch": "win64",
          "winePath": "/wine",
          "wineserverPath": "/wineserver",
          "runtimePath": "/runtime",
          "defaultEnv": {},
          "healthChecks": []
        }
        """.utf8)

        let decoded = try JSONStore().decoder.decode(EngineManifest.self, from: data)

        #expect(decoded.supportsWin32 == false)
    }

    @Test("PE header architecture is detected")
    func peHeaderArchitecture() {
        #expect(WindowsExecutableInspector.architecture(of: Self.fakePE(machine: 0x014c)) == .i386)
        #expect(WindowsExecutableInspector.architecture(of: Self.fakePE(machine: 0x8664)) == .x86_64)
        #expect(WindowsExecutableInspector.architecture(of: Data("not an exe".utf8)) == nil)
    }

    private static func fakePE(machine: UInt16) -> Data {
        var bytes = [UInt8](repeating: 0, count: 256)
        bytes[0] = 0x4d
        bytes[1] = 0x5a
        bytes[0x3c] = 0x80
        bytes[0x80] = 0x50
        bytes[0x81] = 0x45
        bytes[0x84] = UInt8(machine & 0x00ff)
        bytes[0x85] = UInt8(machine >> 8)
        return Data(bytes)
    }
}
