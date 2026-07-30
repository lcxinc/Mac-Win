import Foundation
import Testing
@testable import MacWinCore

@Suite("Engine registry")
struct EngineRegistryTests {
    @Test("Current game engine imports as symlinked managed engine")
    func importsCurrentGameEngine() throws {
        let buildURL = URL(fileURLWithPath: EngineRegistry.currentBuildPath, isDirectory: true)
        let runtimeURL = URL(fileURLWithPath: EngineRegistry.currentRuntimePath, isDirectory: true)
        guard FileManager.default.fileExists(atPath: buildURL.appendingPathComponent("loader/wine").path),
              FileManager.default.fileExists(atPath: runtimeURL.path)
        else {
            return
        }

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinEngineTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        var detectedWinePaths: [String] = []
        let registry = EngineRegistry(
            paths: MacWinPaths(root: root),
            wineVersionDetector: { path in
                detectedWinePaths.append(path)
                return "wine-test-11.11"
            },
            runtimeProbeAllowed: { true }
        )
        let engine = try registry.importCurrentGameEngine(buildURL: buildURL, runtimeURL: runtimeURL)

        let wow64URL = URL(fileURLWithPath: EngineRegistry.currentWoW64BuildPath, isDirectory: true)
        let wow64Available = Self.requiredWin32EngineFiles.allSatisfy {
            FileManager.default.fileExists(atPath: wow64URL.appendingPathComponent($0).path)
        }

        #expect(engine.id == (wow64Available ? EngineRegistry.currentWoW64GameEngineId : EngineRegistry.currentGameEngineId))
        #expect(engine.supportsWin32 == wow64Available)
        #expect(engine.defaultEnv["WINE_D3D_CONFIG"] == "renderer=vulkan,csmt=0x0")
        #expect(engine.defaultEnv["MACWIN_WINHTTP_IGNORE_UNKNOWN_CA"] == (wow64Available ? "1" : nil))
        #expect(engine.defaultEnv["ROSETTA_X87_PATH"] == nil)
        #expect(engine.wineVersion == "wine-test-11.11")
        #expect(!detectedWinePaths.isEmpty)
        #expect(detectedWinePaths.allSatisfy { $0.hasSuffix("/build/loader/wine") })
        #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent("Engines/\(engine.id)/manifest.json").path))
        #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent("Engines/\(EngineRegistry.currentGameEngineId)/manifest.json").path))
    }

    @Test("Engine import skips Wine version probes while Rosetta is stalled")
    func engineImportSkipsVersionProbeDuringRosettaStall() throws {
        let buildURL = URL(fileURLWithPath: EngineRegistry.currentBuildPath, isDirectory: true)
        let runtimeURL = URL(fileURLWithPath: EngineRegistry.currentRuntimePath, isDirectory: true)
        guard FileManager.default.fileExists(atPath: buildURL.appendingPathComponent("loader/wine").path),
              FileManager.default.fileExists(atPath: runtimeURL.path)
        else {
            return
        }

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinBlockedEngineTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        var detectorCallCount = 0
        let registry = EngineRegistry(
            paths: MacWinPaths(root: root),
            wineVersionDetector: { _ in
                detectorCallCount += 1
                return "should-not-run"
            },
            runtimeProbeAllowed: { false }
        )

        let engine = try registry.importCurrentGameEngine(buildURL: buildURL, runtimeURL: runtimeURL)

        #expect(detectorCallCount == 0)
        #expect(engine.wineVersion == "wine-11.11")
        #expect(engine.defaultEnv["ROSETTA_X87_PATH"] == nil)
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
        "dlls/msctf/i386-windows/msctf.dll",
        "dlls/msctf/x86_64-windows/msctf.dll",
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
        "dlls/threadpoolwinrt/i386-windows/threadpoolwinrt.dll",
        "dlls/threadpoolwinrt/x86_64-windows/threadpoolwinrt.dll",
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
}
