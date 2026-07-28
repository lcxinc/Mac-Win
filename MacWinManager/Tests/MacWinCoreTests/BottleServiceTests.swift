import Foundation
import Testing
@testable import MacWinCore

@Suite("Bottle service")
struct BottleServiceTests {
    @Test("High performance bottle is stable and reusable")
    func highPerformanceBottleIsStableAndReusable() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinBottleTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = BottleService(paths: paths)
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

        let first = try service.ensureHighPerformanceBottle(
            name: "High Performance Windows 11",
            engine: engine,
            runWineboot: false
        )
        let second = try service.ensureHighPerformanceBottle(
            name: "High Performance Windows 11",
            engine: engine,
            runWineboot: false
        )
        let bottles = try service.listBottles()

        #expect(first.id == BottleService.highPerformanceBottleId)
        #expect(second.id == BottleService.highPerformanceBottleId)
        #expect(bottles.count == 1)
        #expect(second.windowsVersion == "win11")
        #expect(second.arch == .win64)
        #expect(second.envOverrides["WINE_D3D_CONFIG"] == "renderer=vulkan,csmt=0x0")
        #expect(second.envOverrides["WINEDEBUG"] == "-all")
    }

    @Test("Existing high performance bottle skips repeated registry repair when sentinel is current")
    func existingHighPerformanceBottleSkipsRepeatedRegistryRepairWhenSentinelIsCurrent() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinBottleRepairSkipTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = BottleService(paths: paths)
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
        let bottle = try service.ensureHighPerformanceBottle(
            name: "High Performance Windows 11",
            engine: engine,
            runWineboot: false
        )
        let userRegistry = paths.bottleDirectory(id: bottle.id).appendingPathComponent("user.reg")
        let registryText = """
        WINE REGISTRY Version 2

        [Software\\\\Wine\\\\WineDbg] 1781633413
        "ShowCrashDialog"=dword:00000001

        """
        try Data(registryText.utf8).write(to: userRegistry)
        try Data("ok\n".utf8).write(
            to: paths.bottleDirectory(id: bottle.id)
                .appendingPathComponent(BottleService.renderingRepairSentinelName)
        )

        _ = try service.ensureHighPerformanceBottle(
            name: "High Performance Windows 11",
            engine: engine,
            runWineboot: false
        )

        let after = try String(contentsOf: userRegistry, encoding: .utf8)
        #expect(after == registryText)
    }

    @Test("Wineboot bootstrap writes sentinel")
    func winebootBootstrapWritesSentinel() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinBottleBootstrapTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = BottleService(paths: paths)
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
            id: "desktop",
            name: "Desktop",
            template: BottleTemplate(windowsVersion: "win11", arch: .win64),
            engine: engine,
            runWineboot: false
        )
        let sentinel = paths.bottleDirectory(id: bottle.id)
            .appendingPathComponent(BottleService.winebootSentinelName)

        #expect(!FileManager.default.fileExists(atPath: sentinel.path))

        let bootstrapped = try service.bootstrapWinePrefixIfNeeded(bottle: bottle, engine: engine)
        let reused = try service.bootstrapWinePrefixIfNeeded(bottle: bootstrapped, engine: engine)

        #expect(FileManager.default.fileExists(atPath: sentinel.path))
        #expect(reused.updatedAt == bootstrapped.updatedAt)
    }

    @Test("Compatibility repair removes winebth service and device")
    func compatibilityRepairRemovesWinebthServiceAndDevice() throws {
        let registry = """
        WINE REGISTRY Version 2

        [System\\\\ControlSet001\\\\Enum\\\\ROOT\\\\WINE\\\\WINEBTH] 1781622933
        "ConfigFlags"=dword:00000000
        "Service"="winebth"

        [System\\\\ControlSet001\\\\Enum\\\\ROOT\\\\WINE\\\\WINEBTH\\\\Device Parameters] 1781622933

        [System\\\\ControlSet001\\\\Services\\\\winebth] 1781622933
        "DisplayName"="Wine Bluetooth bus"
        "Start"=dword:00000003
        "Type"=dword:00000001

        [System\\\\ControlSet001\\\\Services\\\\Dokan2t] 1781622933
        "DisplayName"="Dokan2t"
        "Start"=dword:00000002
        "Type"=dword:00000001

        [System\\\\ControlSet001\\\\Services\\\\winebus] 1781622933
        "DisplayName"="Wine HID bus"
        "Start"=dword:00000003
        "Type"=dword:00000001

        """

        let repaired = BottleService.registryText(
            registry,
            removingServices: BottleService.removedKernelServices
        )

        #expect(!repaired.contains("winebth"))
        #expect(!repaired.contains("WINEBTH"))
        #expect(!repaired.contains("Dokan2t"))
        #expect(repaired.contains(#"[System\\ControlSet001\\Services\\winebus]"#))
        #expect(repaired.contains(#""Start"=dword:00000003"#))
    }

    @Test("Registry repair disables noisy third-party background services")
    func registryRepairDisablesNoisyThirdPartyBackgroundServices() throws {
        let registry = """
        WINE REGISTRY Version 2

        [System\\\\ControlSet001\\\\Services\\\\LenovoServiceAS] 1781677780
        "DisplayName"="LenovoServiceAS"
        "Start"=dword:00000002
        "Type"=dword:00000010

        [System\\\\ControlSet001\\\\Services\\\\AndrowsSvr] 1781677780
        "DisplayName"="AndrowsSvr"
        "ImagePath"=str(2):"\\"C:\\\\Program Files\\\\Tencent\\\\Androws\\\\Application\\\\5.10.6400.6084\\\\AndrowsSvr.exe\\""
        "Start"=dword:00000002
        "Type"=dword:00000010

        [System\\\\ControlSet001\\\\Services\\\\LenovoServiceAS\\\\sv] 1781678150
        "show"=dword:00000000

        [System\\\\ControlSet001\\\\Services\\\\LISFService] 1781677833
        "DisplayName"="Lenovo Internet Software Framework Service"
        "Type"=dword:00000010

        [System\\\\ControlSet001\\\\Services\\\\winebus] 1781622933
        "DisplayName"="Wine HID bus"
        "Start"=dword:00000003
        "Type"=dword:00000001

        """

        let repaired = BottleService.registryText(
            registry,
            disablingServices: BottleService.disabledBackgroundServices
        )

        #expect(repaired.contains(#"[System\\ControlSet001\\Services\\LenovoServiceAS]"#))
        #expect(repaired.contains(#"[System\\ControlSet001\\Services\\AndrowsSvr]"#))
        #expect(repaired.contains(#"[System\\ControlSet001\\Services\\LISFService]"#))
        #expect(repaired.contains(#"[System\\ControlSet001\\Services\\winebus]"#))
        #expect(repaired.contains(#""DisplayName"="LenovoServiceAS""#))
        #expect(repaired.contains(#""DisplayName"="AndrowsSvr""#))
        #expect(repaired.contains(#"AndrowsSvr.exe"#))
        #expect(repaired.contains(#""Start"=dword:00000004"#))
        #expect(repaired.contains(#""Start"=dword:00000003"#))
        let subkeyStartValue = #"""
        [System\\ControlSet001\\Services\\LenovoServiceAS\\sv] 1781678150
        "Start"=dword:00000004
        """#
        #expect(!repaired.contains(subkeyStartValue))
    }

    @Test("Registry repair disables Wine crash dialog")
    func registryRepairDisablesWineCrashDialog() throws {
        let registry = """
        WINE REGISTRY Version 2

        [Software\\\\Wine\\\\WineDbg] 1781633413
        #time=1dcfdbb6077536a
        "ShowCrashDialog"=dword:00000001

        [Volatile Environment] 1781622934
        "APPDATA"="C:\\\\users\\\\tester\\\\AppData\\\\Roaming"

        [Software\\\\Microsoft\\\\Windows NT\\\\CurrentVersion\\\\FontSubstitutes]
        "PingFang SC"="Noto Sans SC"

        """

        let repaired = BottleService.registryText(
            registry,
            settingDWORD: BottleService.wineDbgShowCrashDialogValue,
            value: 0,
            inSection: BottleService.wineDbgRegistrySection
        )

        #expect(repaired.contains(#"[Software\\Wine\\WineDbg]"#))
        #expect(repaired.contains(#""ShowCrashDialog"=dword:00000000"#))
        #expect(!repaired.contains(#""ShowCrashDialog"=dword:00000001"#))
        #expect(repaired.contains(#"[Volatile Environment]"#))
    }

    @Test("Registry repair adds MMDeviceEnumerator COM registration")
    func registryRepairAddsMMDeviceEnumeratorCOMRegistration() throws {
        let registry = """
        WINE REGISTRY Version 2

        [Software\\\\Classes\\\\CLSID\\\\{00000000-0000-0000-0000-000000000000}] 1781633413
        @="Other class"

        """

        let repaired = BottleService.registryTextWithMMDeviceRepairs(registry)

        #expect(repaired.contains(#"[Software\\Classes\\CLSID\\{BCDE0395-E52F-467C-8E3D-C4579291692E}]"#))
        #expect(repaired.contains(#"@="MMDeviceEnumerator class""#))
        #expect(repaired.contains(#"[Software\\Classes\\CLSID\\{BCDE0395-E52F-467C-8E3D-C4579291692E}\\InprocServer32]"#))
        #expect(repaired.contains(#"@="C:\\windows\\system32\\mmdevapi.dll""#))
        #expect(repaired.contains(#"[Software\\Classes\\Wow6432Node\\CLSID\\{BCDE0395-E52F-467C-8E3D-C4579291692E}]"#))
        #expect(repaired.contains(#"[Software\\Classes\\Wow6432Node\\CLSID\\{BCDE0395-E52F-467C-8E3D-C4579291692E}\\InprocServer32]"#))
        #expect(repaired.contains(#"@="C:\\windows\\syswow64\\mmdevapi.dll""#))
        #expect(repaired.contains(#""ThreadingModel"="Both""#))
        #expect(repaired.contains(#"@="Other class""#))
    }

    @Test("Registry repair adds Network List Manager COM registration")
    func registryRepairAddsNetworkListManagerCOMRegistration() throws {
        let registry = """
        WINE REGISTRY Version 2

        [Software\\\\Classes\\\\CLSID\\\\{00000000-0000-0000-0000-000000000000}] 1781633413
        @="Other class"

        """

        let repaired = BottleService.registryTextWithNetworkListManagerRepairs(registry)

        #expect(repaired.contains(#"[Software\\Classes\\CLSID\\{DCB00C01-570F-4A9B-8D69-199FDBA5723B}]"#))
        #expect(repaired.contains(#"@="NetworkListManager""#))
        #expect(repaired.contains(#"[Software\\Classes\\CLSID\\{DCB00C01-570F-4A9B-8D69-199FDBA5723B}\\InprocServer32]"#))
        #expect(repaired.contains(#"@="C:\\windows\\system32\\netprofm.dll""#))
        #expect(repaired.contains(#"[Software\\Classes\\Wow6432Node\\CLSID\\{DCB00C01-570F-4A9B-8D69-199FDBA5723B}\\InprocServer32]"#))
        #expect(repaired.contains(#"@="C:\\windows\\syswow64\\netprofm.dll""#))
        #expect(repaired.contains(#""ThreadingModel"="Both""#))
        #expect(repaired.contains(#"@="Other class""#))
    }

    @Test("Registry repair adds Task Scheduler COM and service registration")
    func registryRepairAddsTaskSchedulerCOMAndServiceRegistration() throws {
        let registry = """
        WINE REGISTRY Version 2

        [Software\\\\Classes\\\\CLSID\\\\{00000000-0000-0000-0000-000000000000}] 1781633413
        @="Other class"

        """

        let repaired = BottleService.registryTextWithTaskSchedulerRepairs(registry)

        #expect(repaired.contains(#"[Software\\Classes\\CLSID\\{0F87369F-A4E5-4CFC-BD3E-73E6154572DD}]"#))
        #expect(repaired.contains(#"@="TaskScheduler class""#))
        #expect(repaired.contains(#"[Software\\Classes\\CLSID\\{0F87369F-A4E5-4CFC-BD3E-73E6154572DD}\\InprocServer32]"#))
        #expect(repaired.contains(#"@="C:\\windows\\system32\\taskschd.dll""#))
        #expect(repaired.contains(#"[Software\\Classes\\Wow6432Node\\CLSID\\{0F87369F-A4E5-4CFC-BD3E-73E6154572DD}\\InprocServer32]"#))
        #expect(repaired.contains(#"@="C:\\windows\\syswow64\\taskschd.dll""#))
        #expect(repaired.contains(#"[Software\\Classes\\CLSID\\{148BD52A-A2AB-11CE-B11F-00AA00530503}\\InprocServer32]"#))
        #expect(repaired.contains(#"@="C:\\windows\\system32\\mstask.dll""#))
        #expect(repaired.contains(#"[Software\\Classes\\Wow6432Node\\CLSID\\{148BD52A-A2AB-11CE-B11F-00AA00530503}\\InprocServer32]"#))
        #expect(repaired.contains(#"@="C:\\windows\\syswow64\\mstask.dll""#))
        #expect(repaired.contains(#"[System\\CurrentControlSet\\Services\\Schedule]"#))
        #expect(repaired.contains(#""Type"=dword:00000020"#))
        #expect(repaired.contains(#""Start"=dword:00000002"#))
        #expect(repaired.contains(#""ImagePath"="C:\\windows\\system32\\svchost.exe -k netsvcs""#))
        #expect(repaired.contains(#"[System\\CurrentControlSet\\Services\\Schedule\\Parameters]"#))
        #expect(repaired.contains(#""ServiceDll"="C:\\windows\\system32\\schedsvc.dll""#))
    }

    @Test("Registry repair adds RSA cryptographic providers")
    func registryRepairAddsRSACryptographicProviders() throws {
        let registry = """
        WINE REGISTRY Version 2

        [Software\\\\Microsoft\\\\Cryptography\\\\Defaults\\\\Provider\\\\Microsoft Enhanced Cryptographic Provider v1.0] 1781633413
        "Image Path"="broken.dll"
        "Type"=dword:00000002

        """

        let repaired = BottleService.registryTextWithCryptoProviderRepairs(registry)

        #expect(repaired.contains(#"[Software\\Microsoft\\Cryptography\\Defaults\\Provider\\Microsoft Enhanced Cryptographic Provider v1.0]"#))
        #expect(repaired.contains(#""Image Path"="rsaenh.dll""#))
        #expect(repaired.contains(#""Type"=dword:00000001"#))
        #expect(repaired.contains(#"[Software\\Microsoft\\Cryptography\\Defaults\\Provider Types\\Type 001]"#))
        #expect(repaired.contains(#""Name"="Microsoft Enhanced Cryptographic Provider v1.0""#))
        #expect(repaired.contains(#""TypeName"="RSA Full (Signature and Key Exchange)""#))
        #expect(repaired.contains(#"[Software\\Microsoft\\Cryptography\\Defaults\\Provider\\Microsoft Enhanced RSA and AES Cryptographic Provider]"#))
        #expect(repaired.contains(#"[Software\\Microsoft\\Cryptography\\Defaults\\Provider Types\\Type 024]"#))
        #expect(repaired.contains(#""Type"=dword:00000018"#))
        #expect(!repaired.contains("broken.dll"))
        #expect(!repaired.contains(#""Type"=dword:00000002"#))
    }

    @Test("Registry repair adds user shell folders")
    func registryRepairAddsUserShellFolders() throws {
        let registry = """
        WINE REGISTRY Version 2

        [Software\\\\Microsoft\\\\Windows\\\\CurrentVersion\\\\Explorer\\\\Shell Folders] 1781633413
        "Personal"="Z:\\\\broken"

        """

        let repaired = BottleService.registryTextWithShellFolderRepairs(registry, windowsUserName: "tester")

        #expect(repaired.contains(#"[Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders]"#))
        #expect(repaired.contains(#""Personal"="C:\\users\\tester\\Documents""#))
        #expect(repaired.contains(#""Desktop"="C:\\users\\tester\\Desktop""#))
        #expect(repaired.contains(#""Local AppData"="C:\\users\\tester\\AppData\\Local""#))
        #expect(repaired.contains(#""{374DE290-123F-4565-9164-39C4925E467B}"="C:\\users\\tester\\Downloads""#))
        #expect(repaired.contains(#"[Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders]"#))
        #expect(!repaired.contains("Z:\\\\broken"))
    }

    @Test("Registry repair adds common shell folders for Boost IPC")
    func registryRepairAddsCommonShellFolders() throws {
        let registry = """
        WINE REGISTRY Version 2

        [Software\\\\Microsoft\\\\Windows\\\\CurrentVersion\\\\Explorer\\\\Shell Folders] 1781633413

        """

        let repaired = BottleService.registryTextWithCommonShellFolderRepairs(registry)

        #expect(repaired.contains(#""Common AppData"="C:\\ProgramData""#))
        #expect(repaired.contains(#""Common Documents"="C:\\users\\Public\\Documents""#))
        #expect(repaired.contains(#""Common Startup"="C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\Startup""#))
    }

    @Test("Compatibility repair writes FreeCAD Python uname shim")
    func compatibilityRepairWritesFreeCADPythonUnameShim() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinFreeCADShimTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = BottleService(paths: paths)
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
            id: "freecad",
            name: "FreeCAD",
            template: BottleTemplate(windowsVersion: "win11", arch: .win64),
            engine: engine,
            runWineboot: false
        )
        let libDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files", isDirectory: true)
            .appendingPathComponent("FreeCAD 1.1", isDirectory: true)
            .appendingPathComponent("bin", isDirectory: true)
            .appendingPathComponent("Lib", isDirectory: true)
        try FileManager.default.createDirectory(at: libDirectory, withIntermediateDirectories: true)
        try Data("def mac_ver(): pass\n".utf8).write(to: libDirectory.appendingPathComponent("platform.py"))

        try service.repairBottleCompatibility(bottle)

        let shim = try String(contentsOf: libDirectory.appendingPathComponent("sitecustomize.py"), encoding: .utf8)
        #expect(shim == BottleService.freeCADPythonUnameShimText)
        #expect(shim.contains("os.uname = _macwin_uname"))
    }

    @Test("Registry repair adds IServiceProvider proxy registration")
    func registryRepairAddsIServiceProviderProxyRegistration() throws {
        let registry = """
        WINE REGISTRY Version 2

        [Software\\\\Classes\\\\Interface\\\\{6D5140C1-7436-11CE-8034-00AA006009FA}] 1781633413
        @="Broken IServiceProvider"
        "ProxyStubClsid32"="{00000000-0000-0000-0000-000000000000}"

        """

        let repaired = BottleService.registryTextWithCOMProxyRepairs(registry)

        #expect(repaired.contains(#"[Software\\Classes\\Interface\\{6D5140C1-7436-11CE-8034-00AA006009FA}]"#))
        #expect(repaired.contains(#"@="IServiceProvider""#))
        #expect(repaired.contains(#""ProxyStubClsid32"="{B8DA6310-E19B-11D0-933C-00A0C90DCAA9}""#))
        #expect(repaired.contains(#""NumMethods"="4""#))
        #expect(repaired.contains(#"[Software\\Classes\\Interface\\{6D5140C1-7436-11CE-8034-00AA006009FA}\\ProxyStubClsid32]"#))
        #expect(repaired.contains(#"@="{B8DA6310-E19B-11D0-933C-00A0C90DCAA9}""#))
        #expect(repaired.contains(#"[Software\\Classes\\Interface\\{6D5140C1-7436-11CE-8034-00AA006009FA}\\NumMethods]"#))
        #expect(repaired.contains(#"@="4""#))
        #expect(repaired.contains(#"[Software\\Classes\\CLSID\\{B8DA6310-E19B-11D0-933C-00A0C90DCAA9}]"#))
        #expect(repaired.contains(#"[Software\\Classes\\CLSID\\{B8DA6310-E19B-11D0-933C-00A0C90DCAA9}\\InprocServer32]"#))
        #expect(repaired.contains(#"@="C:\\windows\\system32\\actxprxy.dll""#))
        #expect(repaired.contains(#"[Software\\Classes\\Wow6432Node\\Interface\\{6D5140C1-7436-11CE-8034-00AA006009FA}]"#))
        #expect(repaired.contains(#"[Software\\Classes\\Wow6432Node\\Interface\\{6D5140C1-7436-11CE-8034-00AA006009FA}\\ProxyStubClsid32]"#))
        #expect(repaired.contains(#"[Software\\Classes\\Wow6432Node\\Interface\\{6D5140C1-7436-11CE-8034-00AA006009FA}\\NumMethods]"#))
        #expect(repaired.contains(#"[Software\\Classes\\Wow6432Node\\CLSID\\{B8DA6310-E19B-11D0-933C-00A0C90DCAA9}\\InprocServer32]"#))
        #expect(repaired.contains(#"@="C:\\windows\\syswow64\\actxprxy.dll""#))
        #expect(!repaired.contains("Broken IServiceProvider"))
        #expect(!repaired.contains("{00000000-0000-0000-0000-000000000000}"))
    }

    @Test("Registry repair adds common Windows font aliases")
    func registryRepairAddsCommonWindowsFontAliases() throws {
        let registry = """
        WINE REGISTRY Version 2

        [Volatile Environment] 1781622934
        "APPDATA"="C:\\\\users\\\\tester\\\\AppData\\\\Roaming"

        """

        let repaired = BottleService.registryTextWithFontRepairs(registry)

        #expect(repaired.contains(#"[Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts]"#))
        #expect(repaired.contains(#""Segoe UI (TrueType)"="segoeui.ttf""#))
        #expect(repaired.contains(#""PingFang SC (TrueType)"="pingfang.ttc""#))
        #expect(repaired.contains(#""Hiragino Sans GB (TrueType)"="simhei.ttf""#))
        #expect(repaired.contains(#""Microsoft YaHei & Microsoft YaHei UI (TrueType)"="msyh.ttc""#))
        #expect(repaired.contains(#""Noto Sans SC (TrueType)"="Noto Sans SC (TrueType).otf""#))
        #expect(repaired.contains(#""MiSans (TrueType)"="msyh.ttc""#))
        #expect(repaired.contains(#""HYWenHei-85W (TrueType)"="msyhbd.ttc""#))
        #expect(repaired.contains(#"[Software\\Microsoft\\Windows NT\\CurrentVersion\\FontSubstitutes]"#))
        #expect(!repaired.contains(#""Arial"="#))
        #expect(!repaired.contains(#""Arial Bold"="#))
        #expect(repaired.contains(#""Inter"="PingFang SC""#))
        #expect(repaired.contains(#""MS Shell Dlg"="Tahoma""#))
        #expect(repaired.contains(#""Segoe UI"="Tahoma""#))
        #expect(repaired.contains(#""Segoe UI Bold"="Tahoma""#))
        #expect(repaired.contains(#""Segoe UI Variable"="Tahoma""#))
        #expect(repaired.contains(#""sans-serif"="PingFang SC""#))
        #expect(repaired.contains(#""Microsoft YaHei UI"="PingFang SC""#))
        #expect(repaired.contains(#""Microsoft YaHei UI Bold"="PingFang SC""#))
        #expect(repaired.contains(#""Noto Sans SC"="PingFang SC""#))
        #expect(repaired.contains(#""MS Shell Dlg 2"="Tahoma""#))
        #expect(repaired.contains(#"[Software\\Wine\\Fonts\\Replacements]"#))
        #expect(repaired.contains(#""HYWenHei"="PingFang SC""#))
        #expect(repaired.contains(#""Hiragino Sans GB"="PingFang SC""#))
        #expect(repaired.contains(#""miHoYo"="PingFang SC""#))
        #expect(!repaired.contains(#""PingFang SC"="Noto Sans SC""#))
    }

    @Test("Registry repair assigns stable native UI metrics with CJK fallback")
    func registryRepairAssignsStableSystemUIFont() {
        let registry = """
        WINE REGISTRY Version 2

        [Control Panel\\\\Desktop\\\\WindowMetrics] 1781622934
        "MessageFont"=hex:00,01,02

        """

        let repaired = BottleService.registryTextWithWindowMetricsFontRepairs(registry)
        let tahomaUTF16 = "54,00,61,00,68,00,6f,00,6d,00,61,00,00,00"

        #expect(repaired.contains(#"[Control Panel\\Desktop\\WindowMetrics]"#))
        for valueName in ["CaptionFont", "IconFont", "MenuFont", "MessageFont", "SmCaptionFont", "StatusFont"] {
            #expect(repaired.contains("\"\(valueName)\"=hex:"))
        }
        #expect(repaired.contains(tahomaUTF16))
        #expect(!repaired.contains(#""MessageFont"=hex:00,01,02"#))
        #expect(BottleService.registryTextWithWindowMetricsFontRepairs(repaired) == repaired)
    }

    @Test("Registry repair enables Wine Mac driver input focus")
    func registryRepairEnablesWineMacDriverInputFocus() throws {
        let registry = """
        WINE REGISTRY Version 2

        [Software\\\\Wine\\\\Mac Driver] 1781633413
        "Managed"="N"
        "MouseWarpOverride"="force"

        """

        let repaired = BottleService.registryTextWithMacDriverInputRepairs(registry)

        #expect(repaired.contains(#""Managed"="Y""#))
        #expect(repaired.contains(#""Decorated"="Y""#))
        #expect(repaired.contains(#""UseTakeFocus"="Y""#))
        #expect(repaired.contains(#""GrabFullscreen"="N""#))
        #expect(repaired.contains(#""RetinaMode"="N""#))
        #expect(repaired.contains(#"[Software\\Wine\\Fonts]"#))
        #expect(repaired.contains(#""LogPixels"=dword:00000060"#))
        #expect(repaired.contains(#"[Software\\Wine\\DirectInput]"#))
        #expect(repaired.contains(#""MouseWarpOverride"="disable""#))
        #expect(repaired.contains(#"[Software\\Wine\\X11 Driver]"#))
        #expect(!repaired.contains(#""Managed"="N""#))
        #expect(!repaired.contains(#""MouseWarpOverride"="force""#))
    }

    @Test("Registry repair pairs Retina Mac driver mode with high Windows DPI")
    func registryRepairPairsRetinaModeWithHighWindowsDPI() throws {
        let registry = """
        WINE REGISTRY Version 2

        [Software\\\\Wine\\\\Mac Driver] 1781633413
        "RetinaMode"="N"

        [Software\\\\Wine\\\\Fonts] 1781633413
        "LogPixels"=dword:00000060

        """

        let repaired = BottleService.registryTextWithMacDriverInputRepairs(registry, retinaMode: true)

        #expect(repaired.contains(#""RetinaMode"="Y""#))
        #expect(repaired.contains(#""LogPixels"=dword:000000c0"#))
    }

    @Test("Compatibility repair writes per bottle fontconfig fallback")
    func compatibilityRepairWritesPerBottleFontConfigFallback() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinBottleFontConfigTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = BottleService(paths: paths)
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        try service.saveBottle(bottle)

        try service.repairBottleCompatibility(bottle)

        let fontConfigURL = BottleService.fontConfigURL(for: bottle.id, paths: paths)
        let fontConfig = try String(contentsOf: fontConfigURL, encoding: .utf8)
        #expect(fontConfig.contains(#"<fontconfig>"#))
        #expect(fontConfig.contains(#"<dir>"#))
        #expect(fontConfig.contains("PingFang SC"))
        #expect(fontConfig.contains("Hiragino Sans GB"))
        #expect(fontConfig.contains("Microsoft YaHei UI"))
        #expect(fontConfig.contains("Noto Sans SC"))
        #expect(fontConfig.contains("HYWenHei"))
        #expect(fontConfig.contains("HYWenHei-85W"))
        #expect(fontConfig.contains("OPPOSans"))
        #expect(fontConfig.contains("miHoYo"))
        #expect(fontConfig.contains(#"<string>Arial</string>"#))
        #expect(fontConfig.contains(#"<rejectfont>"#))
        #expect(fontConfig.contains(#"<patelt name="family"><string>Arial</string></patelt>"#))
        #expect(fontConfig.contains(#"<edit name="family" mode="prepend" binding="strong">"#))
        #expect(fontConfig.contains("<string>zh-cn</string>"))
    }

    @Test("Font repair upgrades legacy Latin-only UI font links")
    func fontRepairUpgradesLegacyLatinOnlyUIFontLinks() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinBottleFontLinkTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = BottleService(paths: paths)
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        try service.saveBottle(bottle)
        let fontsDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("windows", isDirectory: true)
            .appendingPathComponent("Fonts", isDirectory: true)
        try FileManager.default.createDirectory(at: fontsDirectory, withIntermediateDirectories: true)
        let oldSegoeTarget = "/System/Library/Fonts/Helvetica.ttc"
        try FileManager.default.createSymbolicLink(
            atPath: fontsDirectory.appendingPathComponent("segoeui.ttf").path,
            withDestinationPath: oldSegoeTarget
        )
        let oldArialURL = fontsDirectory.appendingPathComponent("arialbd.ttf")
        try Data("latin-only".utf8).write(to: oldArialURL)

        try service.repairBottleCompatibility(bottle)

        let repairedTarget = try FileManager.default.destinationOfSymbolicLink(
            atPath: fontsDirectory.appendingPathComponent("segoeui.ttf").path
        )
        #expect(repairedTarget != oldSegoeTarget)
        #expect(
            repairedTarget.hasSuffix("/PingFang.ttc")
                || repairedTarget == "/System/Library/Fonts/STHeiti Medium.ttc"
                || repairedTarget == "/System/Library/Fonts/Hiragino Sans GB.ttc"
        )
        let repairedArialTarget = try FileManager.default.destinationOfSymbolicLink(atPath: oldArialURL.path)
        #expect(
            repairedArialTarget.hasSuffix("/PingFang.ttc")
                || repairedArialTarget == "/System/Library/Fonts/STHeiti Medium.ttc"
                || repairedArialTarget == "/System/Library/Fonts/Hiragino Sans GB.ttc"
        )
    }

    @Test("Compatibility repair registers detected app launchers")
    func compatibilityRepairRegistersDetectedAppLaunchers() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinBottleDetectedAppsTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = BottleService(paths: paths)
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
            id: "high-performance-win11",
            name: "High Performance Windows 11",
            template: BottleTemplate(windowsVersion: "win11", arch: .win64),
            engine: engine,
            runWineboot: false
        )
        _ = try service.addLaunchers([
            LauncherManifest(
                id: "local-c-program-files-x86-softmaker-freeoffice-2024-usbstick-exe",
                appId: "local-\(bottle.id)",
                bottleId: bottle.id,
                displayName: "usbstick",
                exePath: "C:\\Program Files (x86)\\SoftMaker FreeOffice 2024\\usbstick.exe"
            ),
            LauncherManifest(
                id: "ltspice",
                appId: "ltspice",
                bottleId: bottle.id,
                displayName: "LTspice",
                exePath: "C:\\\\Program Files\\\\ADI\\\\LTspice\\\\LTspice.exe"
            )
        ], to: bottle)
        let appDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files (x86)", isDirectory: true)
            .appendingPathComponent("Lenovo", isDirectory: true)
            .appendingPathComponent("LeAppStore", isDirectory: true)
        try FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        try Data("stub".utf8).write(to: appDirectory.appendingPathComponent("LenovoAppStore.exe"))
        let tencentAppStoreDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files", isDirectory: true)
            .appendingPathComponent("Tencent", isDirectory: true)
            .appendingPathComponent("Androws", isDirectory: true)
            .appendingPathComponent("Application", isDirectory: true)
            .appendingPathComponent("5.10.6400.6084", isDirectory: true)
        try FileManager.default.createDirectory(at: tencentAppStoreDirectory, withIntermediateDirectories: true)
        try Data("stub".utf8).write(to: tencentAppStoreDirectory.appendingPathComponent("AndrowsStore.exe"))
        try Data("stub".utf8).write(to: tencentAppStoreDirectory.appendingPathComponent("AndrowsSvr.exe"))
        let steamDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files", isDirectory: true)
            .appendingPathComponent("Steam", isDirectory: true)
        try FileManager.default.createDirectory(at: steamDirectory, withIntermediateDirectories: true)
        try Data("stub".utf8).write(to: steamDirectory.appendingPathComponent("Steam.exe"))
        let hoYoPlayRootDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files", isDirectory: true)
            .appendingPathComponent("miHoYo Launcher", isDirectory: true)
        try FileManager.default.createDirectory(at: hoYoPlayRootDirectory, withIntermediateDirectories: true)
        try Data("stub".utf8).write(to: hoYoPlayRootDirectory.appendingPathComponent("launcher.exe"))
        let hoYoPlayDirectory = hoYoPlayRootDirectory
            .appendingPathComponent("1.16.1.364", isDirectory: true)
        try FileManager.default.createDirectory(at: hoYoPlayDirectory, withIntermediateDirectories: true)
        try Data("stub".utf8).write(to: hoYoPlayDirectory.appendingPathComponent("HYP.exe"))
        let localToolDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files", isDirectory: true)
            .appendingPathComponent("Example Tool", isDirectory: true)
        try FileManager.default.createDirectory(at: localToolDirectory, withIntermediateDirectories: true)
        try Data("stub".utf8).write(to: localToolDirectory.appendingPathComponent("ExampleTool.exe"))
        try Data("stub".utf8).write(to: localToolDirectory.appendingPathComponent("uninstall.exe"))
        try Data("stub".utf8).write(to: localToolDirectory.appendingPathComponent("ExampleToolHelper.exe"))
        try Data("stub".utf8).write(to: localToolDirectory.appendingPathComponent("Remove.exe"))
        let ltspiceDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files/ADI/LTspice", isDirectory: true)
        try FileManager.default.createDirectory(at: ltspiceDirectory, withIntermediateDirectories: true)
        try Data("stub".utf8).write(to: ltspiceDirectory.appendingPathComponent("LTspice.exe"))
        let genericLauncherDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files (x86)", isDirectory: true)
            .appendingPathComponent("Generic Launcher", isDirectory: true)
        try FileManager.default.createDirectory(at: genericLauncherDirectory, withIntermediateDirectories: true)
        try Data("stub".utf8).write(to: genericLauncherDirectory.appendingPathComponent("launcher.exe"))
        let softMakerDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files (x86)", isDirectory: true)
            .appendingPathComponent("SoftMaker FreeOffice 2024", isDirectory: true)
        try FileManager.default.createDirectory(at: softMakerDirectory, withIntermediateDirectories: true)
        try Data("stub".utf8).write(to: softMakerDirectory.appendingPathComponent("TextMaker.exe"))
        try Data("stub".utf8).write(to: softMakerDirectory.appendingPathComponent("PlanMaker.exe"))
        try Data("stub".utf8).write(to: softMakerDirectory.appendingPathComponent("Presentations.exe"))
        try Data("stub".utf8).write(to: softMakerDirectory.appendingPathComponent("SoftMakerUpdaterTool.exe"))
        try Data("stub".utf8).write(to: softMakerDirectory.appendingPathComponent("syspin.exe"))
        try Data("stub".utf8).write(to: softMakerDirectory.appendingPathComponent("usbstick.exe"))
        let softMakerTemplateToolsDirectory = softMakerDirectory.appendingPathComponent("tb", isDirectory: true)
        try FileManager.default.createDirectory(at: softMakerTemplateToolsDirectory, withIntermediateDirectories: true)
        try Data("stub".utf8).write(to: softMakerTemplateToolsDirectory.appendingPathComponent("7z.exe"))
        try Data("stub".utf8).write(to: softMakerTemplateToolsDirectory.appendingPathComponent("downloader.exe"))
        try Data("stub".utf8).write(to: softMakerTemplateToolsDirectory.appendingPathComponent("tbinst.exe"))
        let otterDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("macwin-portable", isDirectory: true)
            .appendingPathComponent("otter-browser-portable", isDirectory: true)
            .appendingPathComponent("otter-browser-win64-weekly120", isDirectory: true)
        try FileManager.default.createDirectory(at: otterDirectory, withIntermediateDirectories: true)
        try Data("stub".utf8).write(to: otterDirectory.appendingPathComponent("otter-browser.exe"))
        try Data("stub".utf8).write(to: otterDirectory.appendingPathComponent("updater.exe"))
        let portableMRemoteNGDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("macwin-portable", isDirectory: true)
            .appendingPathComponent("mremoteng-1782-x64", isDirectory: true)
        try FileManager.default.createDirectory(at: portableMRemoteNGDirectory, withIntermediateDirectories: true)
        try Data("stub".utf8).write(to: portableMRemoteNGDirectory.appendingPathComponent("PuTTYNG.exe"))
        let qModMasterDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("macwin-portable", isDirectory: true)
            .appendingPathComponent("qmodmaster-32", isDirectory: true)
            .appendingPathComponent("qModMaster", isDirectory: true)
        try FileManager.default.createDirectory(at: qModMasterDirectory, withIntermediateDirectories: true)
        try Data("stub".utf8).write(to: qModMasterDirectory.appendingPathComponent("qModMaster.exe"))
        let portableAppsDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("PortableApps", isDirectory: true)
            .appendingPathComponent("PortableApps.com", isDirectory: true)
        try FileManager.default.createDirectory(at: portableAppsDirectory, withIntermediateDirectories: true)
        try Data("stub".utf8).write(to: portableAppsDirectory.appendingPathComponent("PortableAppsPlatform.exe"))
        try Data("stub".utf8).write(to: portableAppsDirectory.appendingPathComponent("PortableAppsBackup.exe"))
        try Data("stub".utf8).write(to: portableAppsDirectory.appendingPathComponent("PortableAppsBackupRestore.exe"))
        try Data("stub".utf8).write(to: portableAppsDirectory.appendingPathComponent("PortableAppsUpdater.exe"))

        try service.repairBottleCompatibility(bottle)
        try service.repairBottleCompatibility(bottle)

        let loadedBottle = try service.bottle(id: bottle.id)
        let repaired = try #require(loadedBottle)
        let launcher = try #require(repaired.installedApps.first { $0.id == BottleService.lenovoAppStoreLauncherId })
        #expect(launcher.displayName == "联想应用商店 / 应用宝")
        #expect(launcher.exePath == "C:\\Program Files (x86)\\Lenovo\\LeAppStore\\LenovoAppStore.exe")
        #expect(launcher.args == ApplicationCompatibilityProfile.lenovoAppStoreArguments)
        #expect(launcher.args.contains("--disable-direct-composition"))
        #expect(!launcher.args.contains("--disable-gpu"))
        #expect(!launcher.args.contains("--use-gl=disabled"))
        #expect(launcher.args.contains("--use-gl=angle"))
        #expect(launcher.args.contains("--use-angle=d3d11"))
        #expect(launcher.args.contains("--remote-debugging-port=9231"))
        #expect(!launcher.args.contains("--disable-remote-fonts"))
        #expect(launcher.envOverrides["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("--enable-features=FontSrcLocalMatching") == true)
        #expect(launcher.envOverrides["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains(",FontSrcLocalMatching") == false)
        #expect(launcher.envOverrides["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("FontationsFontBackend") == false)
        #expect(launcher.envOverrides["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("DWriteFontProxy") == false)
        #expect(launcher.envOverrides["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("UseDWriteCore") == false)
        #expect(launcher.envOverrides["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("UseSkiaRenderer") == false)
        #expect(launcher.envOverrides["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("--disable-skia-runtime-opts") == false)
        #expect(launcher.envOverrides["MACWIN_DXVK_MACOS_REPAIR"] == "1")
        #expect(launcher.envOverrides["MACWIN_LENOVO_PAGE_REPAIR"] == "1")
        #expect(launcher.envOverrides["MACWIN_DISABLE_WINE_D3D_CONFIG"] == nil)
        #expect(launcher.envOverrides["WINE_D3D_CONFIG"] == "renderer=vulkan,csmt=0x0")
        #expect(launcher.envOverrides["MACWIN_DISABLE_DWM_COMPOSITION"] == nil)
        #expect(launcher.envOverrides["MACWIN_FORCE_OPAQUE_LAYERED_WINDOWS"] == nil)
        #expect(launcher.envOverrides["WINEDLLOVERRIDES"] == "dxgi,d3d11,d3d10core=n,b;qone,wbemprox=d")
        #expect(launcher.envOverrides["MACWIN_COMPAT_PROFILE"] == "lenovo-app-store")
        #expect(launcher.envOverrides["MACWIN_LENOVO_BLACK_SCREEN_REPAIR"] == "1")
        #expect(launcher.envOverrides["MACWIN_TEXT_RENDERING_REPAIR"] == "1")
        #expect(launcher.envOverrides["MACWIN_FONT_FALLBACK_REPAIR"] == "1")
        #expect(launcher.envOverrides["QTWEBENGINE_DISABLE_SANDBOX"] == "1")

        let tencentLauncher = try #require(repaired.installedApps.first { $0.id == BottleService.tencentAppStoreLauncherId })
        #expect(tencentLauncher.displayName == "应用宝 / 腾讯应用市场")
        #expect(tencentLauncher.appId == "tencent-app-store")
        #expect(tencentLauncher.exePath == "C:\\Program Files\\Tencent\\Androws\\Application\\5.10.6400.6084\\AndrowsStore.exe")
        #expect(tencentLauncher.args == ApplicationCompatibilityProfile.tencentAppStore.launchArguments)
        #expect(tencentLauncher.envOverrides["MACWIN_COMPAT_PROFILE"] == "tencent-app-store")
        #expect(tencentLauncher.envOverrides["MACWIN_TENCENT_APP_STORE_REPAIR"] == "1")
        #expect(tencentLauncher.envOverrides["MACWIN_LENOVO_BLACK_SCREEN_REPAIR"] == nil)

        let hoYoPlayLauncher = try #require(repaired.installedApps.first { $0.id == BottleService.hoYoPlayLauncherId })
        #expect(hoYoPlayLauncher.displayName == "HoYoPlay / 米哈游启动器")
        #expect(hoYoPlayLauncher.exePath == "C:\\Program Files\\miHoYo Launcher\\launcher.exe")
        #expect(hoYoPlayLauncher.args.isEmpty)
        #expect(hoYoPlayLauncher.envOverrides["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--use-gl=angle") == true)
        #expect(hoYoPlayLauncher.envOverrides["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--use-angle=swiftshader") == true)
        #expect(hoYoPlayLauncher.envOverrides["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--disable-direct-write") == false)
        #expect(hoYoPlayLauncher.envOverrides["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--disable-remote-fonts") == false)
        #expect(hoYoPlayLauncher.envOverrides["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--enable-features=FontSrcLocalMatching") == true)
        #expect(hoYoPlayLauncher.envOverrides["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains(",FontSrcLocalMatching") == false)
        #expect(hoYoPlayLauncher.envOverrides["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("FontationsFontBackend") == false)
        #expect(hoYoPlayLauncher.envOverrides["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("DWriteFontProxy") == false)
        #expect(hoYoPlayLauncher.envOverrides["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("UseDWriteCore") == false)
        #expect(hoYoPlayLauncher.envOverrides["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("UseSkiaRenderer") == false)
        #expect(hoYoPlayLauncher.envOverrides["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--disable-skia-runtime-opts") == false)
        #expect(hoYoPlayLauncher.envOverrides["MACWIN_COMPAT_PROFILE"] == "hoyoplay-webview")
        #expect(hoYoPlayLauncher.envOverrides["MACWIN_HOYOPLAY_TEXT_REPAIR"] == "1")
        #expect(hoYoPlayLauncher.envOverrides["MACWIN_FONT_FALLBACK_REPAIR"] == "1")
        #expect(hoYoPlayLauncher.envOverrides["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(hoYoPlayLauncher.envOverrides["QTWEBENGINE_DISABLE_SANDBOX"] == "1")
        #expect(hoYoPlayLauncher.envOverrides["QT_FONT_DPI"] == "96")
        #expect(hoYoPlayLauncher.envOverrides["QT_FONT_FAMILY"] == "PingFang SC")
        #expect(hoYoPlayLauncher.envOverrides["CHROMIUM_USER_FLAGS"]?.contains("--lang=zh-CN") == true)

        let steamLauncher = try #require(repaired.installedApps.first { $0.id == BottleService.steamLauncherId })
        #expect(steamLauncher.displayName == "Steam")
        #expect(steamLauncher.exePath == "C:\\Program Files\\Steam\\Steam.exe")
        #expect(steamLauncher.args == BottleService.steamLauncherArguments)
        #expect(steamLauncher.envOverrides["WINE_D3D_CONFIG"] == "renderer=vulkan,csmt=0x0")
        #expect(steamLauncher.envOverrides["WINEDEBUG"] == "-all")
        #expect(steamLauncher.envOverrides["MACWIN_COMPAT_PROFILE"] == "steam-client")
        #expect(steamLauncher.envOverrides["MACWIN_WINHTTP_IGNORE_UNKNOWN_CA"] == "1")
        #expect(steamLauncher.envOverrides["MACWIN_DISABLE_DWM_COMPOSITION"] == "1")
        #expect(steamLauncher.envOverrides["MACWIN_FORCE_MOUSE_FOCUS"] == "1")
        #expect(steamLauncher.envOverrides["MACWIN_STEAMWEBHELPER_FORCE_OPAQUE"] == "1")
        #expect(steamLauncher.envOverrides["MACWIN_RECENTER_OFFSCREEN_WINDOWS"] == "1")
        #expect(steamLauncher.envOverrides["MACWIN_FORCE_OPAQUE_LAYERED_WINDOWS"] == "1")
        #expect(steamLauncher.envOverrides["MACWIN_FONT_FALLBACK_REPAIR"] == "1")
        #expect(steamLauncher.envOverrides["QTWEBENGINE_DISABLE_SANDBOX"] == "1")
        #expect(steamLauncher.envOverrides["MACWIN_STEAMWEBHELPER_ARGS"] == BottleService.steamWebHelperArguments)
        #expect(steamLauncher.envOverrides["WINEDLLOVERRIDES"] == "wbemprox=d")
        #expect(BottleService.steamWebHelperArguments.contains("--use-gl=disabled"))
        #expect(BottleService.steamWebHelperArguments.contains("--disable-accelerated-2d-canvas"))
        #expect(!BottleService.steamWebHelperArguments.contains("--disable-direct-write"))
        #expect(!BottleService.steamWebHelperArguments.contains("--disable-font-subpixel-positioning"))
        #expect(!BottleService.steamWebHelperArguments.contains("--disable-lcd-text"))
        #expect(!BottleService.steamWebHelperArguments.contains("--disable-prefer-compositing-to-lcd-text"))
        #expect(!BottleService.steamWebHelperArguments.contains("--font-render-hinting=none"))
        #expect(!BottleService.steamWebHelperArguments.contains("--disable-remote-fonts"))
        #expect(BottleService.steamWebHelperArguments.contains("--enable-features=FontSrcLocalMatching"))
        #expect(!BottleService.steamWebHelperArguments.contains(",FontSrcLocalMatching"))
        #expect(!BottleService.steamWebHelperArguments.contains("FontationsFontBackend"))
        #expect(!BottleService.steamWebHelperArguments.contains("DWriteFontProxy"))
        #expect(!BottleService.steamWebHelperArguments.contains("UseDWriteCore"))
        #expect(!BottleService.steamWebHelperArguments.contains("UseSkiaRenderer"))
        #expect(!BottleService.steamWebHelperArguments.contains("--disable-skia-runtime-opts"))

        let localTool = try #require(repaired.installedApps.first { $0.exePath == "C:\\Program Files\\Example Tool\\ExampleTool.exe" })
        #expect(localTool.displayName == "ExampleTool")
        #expect(localTool.appId == "local-\(bottle.id)")
        #expect(localTool.showInHome == true)
        #expect(repaired.installedApps.contains { $0.exePath.lowercased().contains("uninstall.exe") } == false)
        #expect(repaired.installedApps.contains { $0.exePath.lowercased().contains("helper.exe") } == false)
        #expect(repaired.installedApps.contains { $0.exePath.lowercased().hasSuffix("\\remove.exe") } == false)

        let genericLauncher = try #require(repaired.installedApps.first { $0.exePath == "C:\\Program Files (x86)\\Generic Launcher\\launcher.exe" })
        #expect(genericLauncher.displayName == "Generic Launcher")
        #expect(repaired.installedApps.filter { $0.exePath == "C:\\Program Files\\Example Tool\\ExampleTool.exe" }.count == 1)
        #expect(repaired.installedApps.filter { $0.displayName == "LTspice" }.count == 1)
        #expect(repaired.installedApps.first { $0.displayName == "LTspice" }?.appId == "ltspice")

        let portableAppsHelpers = repaired.installedApps.filter {
            $0.exePath.hasPrefix("C:\\PortableApps\\PortableApps.com\\")
        }
        #expect(portableAppsHelpers.map(\.id).sorted() == [
            BottleService.portableAppsBackupLauncherId,
            BottleService.portableAppsBackupRestoreLauncherId,
            BottleService.portableAppsUpdaterLauncherId
        ].sorted())
        #expect(portableAppsHelpers.allSatisfy { $0.appId == "portableapps-utilities" })
        #expect(portableAppsHelpers.allSatisfy { $0.envOverrides["MACWIN_COMPAT_PROFILE"] == "portableapps-utility" })
        #expect(portableAppsHelpers.allSatisfy { $0.envOverrides["MACWIN_DISABLE_WINE_D3D_CONFIG"] == "1" })
        #expect(portableAppsHelpers.allSatisfy { $0.envOverrides["MACWIN_LAUNCH_CWD"] == "executable-dir" })
        #expect(portableAppsHelpers.allSatisfy { $0.envOverrides["MACWIN_PORTABLEAPPS_HELPER_REPAIR"] == "1" })
        #expect(repaired.installedApps.contains {
            $0.exePath == "C:\\PortableApps\\PortableApps.com\\PortableAppsPlatform.exe"
        } == false)

        let softMakerLaunchers = repaired.installedApps.filter {
            $0.exePath.contains("SoftMaker FreeOffice 2024")
        }
        #expect(softMakerLaunchers.map(\.displayName).sorted() == ["PlanMaker", "Presentations", "TextMaker"])
        #expect(softMakerLaunchers.allSatisfy { $0.envOverrides["MACWIN_COMPAT_PROFILE"] == "softmaker-office" })
        #expect(softMakerLaunchers.allSatisfy { $0.envOverrides["MACWIN_COM_PROXY_REPAIR"] == "1" })
        #expect(softMakerLaunchers.contains { $0.exePath == "C:\\Program Files (x86)\\SoftMaker FreeOffice 2024\\TextMaker.exe" })
        #expect(softMakerLaunchers.contains { $0.exePath == "C:\\Program Files (x86)\\SoftMaker FreeOffice 2024\\PlanMaker.exe" })
        #expect(softMakerLaunchers.contains { $0.exePath == "C:\\Program Files (x86)\\SoftMaker FreeOffice 2024\\Presentations.exe" })
        #expect(repaired.installedApps.contains { $0.exePath == "C:\\Program Files (x86)\\SoftMaker FreeOffice 2024\\SoftMakerUpdaterTool.exe" } == false)
        #expect(repaired.installedApps.contains { $0.exePath == "C:\\Program Files (x86)\\SoftMaker FreeOffice 2024\\syspin.exe" } == false)
        #expect(repaired.installedApps.contains { $0.exePath == "C:\\Program Files (x86)\\SoftMaker FreeOffice 2024\\usbstick.exe" } == false)
        #expect(repaired.installedApps.contains { $0.exePath == "C:\\Program Files (x86)\\SoftMaker FreeOffice 2024\\tb\\7z.exe" } == false)
        #expect(repaired.installedApps.contains { $0.exePath == "C:\\Program Files (x86)\\SoftMaker FreeOffice 2024\\tb\\downloader.exe" } == false)
        #expect(repaired.installedApps.contains { $0.exePath == "C:\\Program Files (x86)\\SoftMaker FreeOffice 2024\\tb\\tbinst.exe" } == false)

        let otterLauncher = try #require(repaired.installedApps.first {
            $0.exePath == "C:\\macwin-portable\\otter-browser-portable\\otter-browser-win64-weekly120\\otter-browser.exe"
        })
        #expect(otterLauncher.displayName == "otter-browser")
        #expect(otterLauncher.envOverrides["MACWIN_COMPAT_PROFILE"] == "qt-browser-software")
        #expect(otterLauncher.envOverrides["MACWIN_QT_BROWSER_REPAIR"] == "1")
        #expect(otterLauncher.envOverrides["QT_OPENGL"] == "software")
        #expect(otterLauncher.envOverrides["QT_QUICK_BACKEND"] == "software")
        #expect(otterLauncher.envOverrides["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(repaired.installedApps.contains {
            $0.exePath == "C:\\macwin-portable\\otter-browser-portable\\otter-browser-win64-weekly120\\updater.exe"
        } == false)
        #expect(repaired.installedApps.contains {
            $0.exePath == "C:\\macwin-portable\\mremoteng-1782-x64\\PuTTYNG.exe"
        } == false)

        let qModMasterLauncher = try #require(repaired.installedApps.first {
            $0.exePath == "C:\\macwin-portable\\qmodmaster-32\\qModMaster\\qModMaster.exe"
        })
        #expect(qModMasterLauncher.displayName == "qModMaster")
        #expect(qModMasterLauncher.envOverrides["MACWIN_COMPAT_PROFILE"] == "qt-widgets-software")
        #expect(qModMasterLauncher.envOverrides["MACWIN_QT_WIDGETS_REPAIR"] == "1")
        #expect(qModMasterLauncher.envOverrides["QT_OPENGL"] == nil)
        #expect(qModMasterLauncher.envOverrides["QT_QUICK_BACKEND"] == nil)
        #expect(qModMasterLauncher.envOverrides["WINE_D3D_CONFIG"] == nil)
        #expect(qModMasterLauncher.envOverrides["MACWIN_LAUNCH_CWD"] == nil)
        #expect(qModMasterLauncher.envOverrides["QT_STYLE_OVERRIDE"] == nil)
    }

    @Test("Compatibility repair migrates persisted obsolete text rendering flags")
    func compatibilityRepairMigratesPersistedObsoleteTextRenderingFlags() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinBottleLauncherMigrationTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = BottleService(paths: paths)
        let staleLenovo = LauncherManifest(
            id: BottleService.lenovoAppStoreLauncherId,
            appId: "lenovo-app-store-pcyyb",
            bottleId: "high-performance-win11",
            displayName: "联想应用商店 / 应用宝",
            exePath: "C:\\Program Files (x86)\\Lenovo\\LeAppStore\\LenovoAppStore.exe",
            args: [
                "--no-sandbox",
                "--no-proxy-server",
                "--proxy-server=direct://",
                "--proxy-bypass-list=*",
                "--lang=zh-CN",
                "--accept-lang=zh-CN,zh,en-US,en",
                "--force-color-profile=srgb",
                "--disable-gpu",
                "--disable-gpu-compositing",
                "--disable-direct-composition",
                "--use-gl=disabled",
                "--user-flag"
            ],
            envOverrides: [
                "MACWIN_COMPAT_PROFILE": ApplicationCompatibilityProfile.lenovoAppStore.rawValue,
                "MACWIN_CHROMIUM_HELPER_ARGS": "--disable-gpu --use-gl=disabled",
                "WINEDLLOVERRIDES": "qone,wbemprox=d;dwrite,usp10=b",
                "CUSTOM": "1"
            ]
        )
        let staleHoYoPlay = LauncherManifest(
            id: BottleService.hoYoPlayLauncherId,
            appId: "hoyoplay-cn",
            bottleId: "high-performance-win11",
            displayName: "HoYoPlay / 米哈游启动器",
            exePath: "C:\\Program Files\\miHoYo Launcher\\1.16.1.364\\HYP.exe",
            args: [
                "--disable-direct-write",
                "--disable-font-subpixel-positioning",
                "--disable-lcd-text",
                "--font-render-hinting=none",
                "--use-angle=swiftshader-webgl",
                "--disable-features=CalculateNativeWinOcclusion,DWriteFontProxy,UseDWriteCore,UserFeature",
                "--user-flag"
            ],
            envOverrides: [
                "MACWIN_COMPAT_PROFILE": ApplicationCompatibilityProfile.hoYoPlay.rawValue,
                "MACWIN_CHROMIUM_HELPER_ARGS": "--disable-font-subpixel-positioning --disable-lcd-text --disable-features=DWriteFontProxy,UseDWriteCore",
                "QTWEBENGINE_CHROMIUM_FLAGS": "--disable-direct-write --font-render-hinting=none",
                "WINEDLLOVERRIDES": "qone,wbemprox=d;dwrite,usp10=b",
                "CUSTOM": "1"
            ]
        )
        let staleSteam = LauncherManifest(
            id: BottleService.steamLauncherId,
            appId: "steam",
            bottleId: "high-performance-win11",
            displayName: "Steam",
            exePath: "C:\\Program Files\\Steam\\Steam.exe",
            args: [
                "-no-cef-sandbox",
                "--disable-font-subpixel-positioning",
                "-user"
            ],
            envOverrides: [
                "MACWIN_COMPAT_PROFILE": ApplicationCompatibilityProfile.steamClient.rawValue,
                "MACWIN_STEAMWEBHELPER_ARGS": "--disable-lcd-text --font-render-hinting=none --disable-features=DWriteFontProxy,UseDWriteCore",
                "CUSTOM": "1"
            ]
        )
        let bottle = BottleManifest(
            id: "high-performance-win11",
            name: "High Performance Windows 11",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine",
            installedApps: [staleLenovo, staleHoYoPlay, staleSteam]
        )
        try service.saveBottle(bottle)

        let repaired = try service.migrateLauncherCompatibility(in: bottle)
        let lenovo = try #require(repaired.installedApps.first { $0.id == BottleService.lenovoAppStoreLauncherId })
        let hoYoPlay = try #require(repaired.installedApps.first { $0.id == BottleService.hoYoPlayLauncherId })
        let steam = try #require(repaired.installedApps.first { $0.id == BottleService.steamLauncherId })

        #expect(lenovo.args == ApplicationCompatibilityProfile.lenovoAppStoreArguments + ["--user-flag"])
        #expect(!lenovo.args.contains("--disable-gpu"))
        #expect(!lenovo.args.contains("--disable-gpu-compositing"))
        #expect(lenovo.args.contains("--disable-direct-composition"))
        #expect(!lenovo.args.contains("--use-gl=disabled"))
        #expect(lenovo.args.contains("--use-angle=d3d11"))
        #expect(lenovo.envOverrides["MACWIN_CHROMIUM_HELPER_ARGS"] == ApplicationCompatibilityProfile.lenovoAppStoreHelperArguments)
        #expect(lenovo.envOverrides["WINEDLLOVERRIDES"] == "dxgi,d3d11,d3d10core=n,b;qone,wbemprox=d")
        #expect(lenovo.envOverrides["CUSTOM"] == "1")
        #expect(!hoYoPlay.args.contains("--disable-direct-write"))
        #expect(!hoYoPlay.args.contains("--disable-font-subpixel-positioning"))
        #expect(!hoYoPlay.args.contains("--disable-lcd-text"))
        #expect(!hoYoPlay.args.contains("--font-render-hinting=none"))
        #expect(!hoYoPlay.args.contains("--use-angle=swiftshader-webgl"))
        #expect(hoYoPlay.args.contains("--disable-features=CalculateNativeWinOcclusion,UserFeature"))
        #expect(hoYoPlay.args.contains("--user-flag"))
        #expect(hoYoPlay.envOverrides["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("--disable-font-subpixel-positioning") == false)
        #expect(hoYoPlay.envOverrides["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("DWriteFontProxy") == false)
        #expect(hoYoPlay.envOverrides["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--font-render-hinting=none") == false)
        #expect(hoYoPlay.envOverrides["WINEDLLOVERRIDES"] == "qone,wbemprox=d")
        #expect(hoYoPlay.envOverrides["CUSTOM"] == "1")
        #expect(steam.args.contains("-no-cef-sandbox"))
        #expect(!steam.args.contains("--disable-font-subpixel-positioning"))
        #expect(steam.args.contains("-user"))
        #expect(steam.envOverrides["MACWIN_STEAMWEBHELPER_ARGS"]?.contains("--disable-lcd-text") == false)
        #expect(steam.envOverrides["MACWIN_STEAMWEBHELPER_ARGS"]?.contains("UseDWriteCore") == false)
        #expect(steam.envOverrides["CUSTOM"] == "1")
    }

    @Test("Compatibility repair resets only WebView rendering caches")
    func compatibilityRepairResetsOnlyWebViewRenderingCaches() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinBottleWebViewCacheTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = BottleService(paths: paths)
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        try service.saveBottle(bottle)
        let htmlCache = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("users", isDirectory: true)
            .appendingPathComponent("tester", isDirectory: true)
            .appendingPathComponent("AppData", isDirectory: true)
            .appendingPathComponent("Local", isDirectory: true)
            .appendingPathComponent("Steam", isDirectory: true)
            .appendingPathComponent("htmlcache", isDirectory: true)
            .appendingPathComponent("Default", isDirectory: true)
        let gpuCache = htmlCache.appendingPathComponent("GPUCache", isDirectory: true)
        let codeCache = htmlCache.appendingPathComponent("Code Cache", isDirectory: true)
        let regularCache = htmlCache.appendingPathComponent("Cache", isDirectory: true)
        for directory in [gpuCache, codeCache, regularCache] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try Data("stub".utf8).write(to: directory.appendingPathComponent("entry"))
        }
        let lenovoStoreCache = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("users", isDirectory: true)
            .appendingPathComponent("tester", isDirectory: true)
            .appendingPathComponent("AppData", isDirectory: true)
            .appendingPathComponent("Local", isDirectory: true)
            .appendingPathComponent("lenovo", isDirectory: true)
            .appendingPathComponent("LeAppStore", isDirectory: true)
            .appendingPathComponent("storecache", isDirectory: true)
        try FileManager.default.createDirectory(at: lenovoStoreCache, withIntermediateDirectories: true)
        try Data("stub".utf8).write(to: lenovoStoreCache.appendingPathComponent("LocalPrefs.json"))
        let lenovoApplication = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files (x86)", isDirectory: true)
            .appendingPathComponent("Lenovo", isDirectory: true)
            .appendingPathComponent("LeAppStore", isDirectory: true)
        let lenovoSwiftShader = lenovoApplication.appendingPathComponent("swiftshader", isDirectory: true)
        try FileManager.default.createDirectory(at: lenovoSwiftShader, withIntermediateDirectories: true)
        try Data("exe".utf8).write(to: lenovoApplication.appendingPathComponent("LenovoAppStore.exe"))
        for fileName in BottleService.bundledGPUDLLNames {
            try Data("gpu".utf8).write(to: lenovoApplication.appendingPathComponent(fileName))
        }
        try Data("gpu".utf8).write(to: lenovoSwiftShader.appendingPathComponent("libEGL.dll"))
        try Data("gpu".utf8).write(to: lenovoSwiftShader.appendingPathComponent("libGLESv2.dll"))
        let hoYoPlayRootCache = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("users", isDirectory: true)
            .appendingPathComponent("tester", isDirectory: true)
            .appendingPathComponent("AppData", isDirectory: true)
            .appendingPathComponent("Roaming", isDirectory: true)
            .appendingPathComponent("miHoYo", isDirectory: true)
            .appendingPathComponent("HYP", isDirectory: true)
            .appendingPathComponent("1_1", isDirectory: true)
            .appendingPathComponent("cache", isDirectory: true)
        try FileManager.default.createDirectory(at: hoYoPlayRootCache, withIntermediateDirectories: true)
        try Data("stub".utf8).write(to: hoYoPlayRootCache.appendingPathComponent("entry"))
        let hoYoPlayFedataCache = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("users", isDirectory: true)
            .appendingPathComponent("tester", isDirectory: true)
            .appendingPathComponent("AppData", isDirectory: true)
            .appendingPathComponent("Roaming", isDirectory: true)
            .appendingPathComponent("miHoYo", isDirectory: true)
            .appendingPathComponent("HYP", isDirectory: true)
            .appendingPathComponent("1_1", isDirectory: true)
            .appendingPathComponent("fedata", isDirectory: true)
            .appendingPathComponent("Cache", isDirectory: true)
        let hoYoPlayServiceWorkerCache = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("users", isDirectory: true)
            .appendingPathComponent("tester", isDirectory: true)
            .appendingPathComponent("AppData", isDirectory: true)
            .appendingPathComponent("Roaming", isDirectory: true)
            .appendingPathComponent("miHoYo", isDirectory: true)
            .appendingPathComponent("HYP", isDirectory: true)
            .appendingPathComponent("1_1", isDirectory: true)
            .appendingPathComponent("fedata", isDirectory: true)
            .appendingPathComponent("Service Worker", isDirectory: true)
            .appendingPathComponent("CacheStorage", isDirectory: true)
        for directory in [hoYoPlayFedataCache, hoYoPlayServiceWorkerCache] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try Data("stub".utf8).write(to: directory.appendingPathComponent("entry"))
        }
        let tencentAndrowsVersion = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files", isDirectory: true)
            .appendingPathComponent("Tencent", isDirectory: true)
            .appendingPathComponent("Androws", isDirectory: true)
            .appendingPathComponent("Application", isDirectory: true)
            .appendingPathComponent("5.10.6400.6084", isDirectory: true)
        let tencentAndrowsRenderer = tencentAndrowsVersion.appendingPathComponent("renderer", isDirectory: true)
        try FileManager.default.createDirectory(at: tencentAndrowsRenderer, withIntermediateDirectories: true)
        try Data("exe".utf8).write(to: tencentAndrowsVersion.appendingPathComponent("AndrowsStore.exe"))
        try Data("gpu".utf8).write(to: tencentAndrowsVersion.appendingPathComponent("vulkan-1.dll"))
        try Data("gpu".utf8).write(to: tencentAndrowsVersion.appendingPathComponent("vk_swiftshader.dll"))
        try Data("gpu".utf8).write(to: tencentAndrowsRenderer.appendingPathComponent("libEGL.dll"))
        try Data("gpu".utf8).write(to: tencentAndrowsRenderer.appendingPathComponent("libGLESv2.dll"))
        let tencentAndrowsCEFCache = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("users", isDirectory: true)
            .appendingPathComponent("tester", isDirectory: true)
            .appendingPathComponent("AppData", isDirectory: true)
            .appendingPathComponent("Roaming", isDirectory: true)
            .appendingPathComponent("Tencent", isDirectory: true)
            .appendingPathComponent("Androws", isDirectory: true)
            .appendingPathComponent("cef", isDirectory: true)
            .appendingPathComponent("CEF_AndrowsStore", isDirectory: true)
        try FileManager.default.createDirectory(at: tencentAndrowsCEFCache, withIntermediateDirectories: true)
        try Data("stub".utf8).write(to: tencentAndrowsCEFCache.appendingPathComponent("entry"))
        let chromiumApplication = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("users", isDirectory: true)
            .appendingPathComponent("tester", isDirectory: true)
            .appendingPathComponent("AppData", isDirectory: true)
            .appendingPathComponent("Local", isDirectory: true)
            .appendingPathComponent("BraveSoftware", isDirectory: true)
            .appendingPathComponent("Brave-Browser", isDirectory: true)
            .appendingPathComponent("Application", isDirectory: true)
        let chromiumVersion = chromiumApplication.appendingPathComponent("149.1.91.175", isDirectory: true)
        try FileManager.default.createDirectory(at: chromiumVersion, withIntermediateDirectories: true)
        try Data("exe".utf8).write(to: chromiumApplication.appendingPathComponent("brave.exe"))
        try Data("elf".utf8).write(to: chromiumVersion.appendingPathComponent("chrome_elf.dll"))
        try Data("wer".utf8).write(to: chromiumVersion.appendingPathComponent("chrome_wer.dll"))
        let vivaldiApplication = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files", isDirectory: true)
            .appendingPathComponent("Vivaldi", isDirectory: true)
            .appendingPathComponent("Application", isDirectory: true)
        let vivaldiVersion = vivaldiApplication.appendingPathComponent("7.9.3970.47", isDirectory: true)
        try FileManager.default.createDirectory(at: vivaldiVersion, withIntermediateDirectories: true)
        try Data("exe".utf8).write(to: vivaldiApplication.appendingPathComponent("vivaldi.exe"))
        try Data("elf".utf8).write(to: vivaldiVersion.appendingPathComponent("vivaldi_elf.dll"))
        let edgeApplication = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files (x86)", isDirectory: true)
            .appendingPathComponent("Microsoft", isDirectory: true)
            .appendingPathComponent("Edge", isDirectory: true)
            .appendingPathComponent("Application", isDirectory: true)
        let edgeVersion = edgeApplication.appendingPathComponent("149.0.4022.80", isDirectory: true)
        try FileManager.default.createDirectory(at: edgeVersion, withIntermediateDirectories: true)
        try Data("exe".utf8).write(to: edgeApplication.appendingPathComponent("msedge.exe"))
        try Data("elf".utf8).write(to: edgeVersion.appendingPathComponent("msedge_elf.dll"))
        try Data("wer".utf8).write(to: edgeVersion.appendingPathComponent("msedge_wer.dll"))

        try service.repairBottleCompatibility(bottle)

        #expect(!FileManager.default.fileExists(atPath: gpuCache.path))
        #expect(!FileManager.default.fileExists(atPath: codeCache.path))
        #expect(FileManager.default.fileExists(atPath: regularCache.path))
        #expect(!FileManager.default.fileExists(atPath: lenovoStoreCache.path))
        let lenovoDisabledGPU = lenovoApplication.appendingPathComponent(BottleService.disabledBundledGPUDLLDirectoryName, isDirectory: true)
        for fileName in BottleService.bundledGPUDLLNames {
            #expect(!FileManager.default.fileExists(atPath: lenovoApplication.appendingPathComponent(fileName).path))
            #expect(FileManager.default.fileExists(atPath: lenovoDisabledGPU.appendingPathComponent(fileName).path))
        }
        #expect(!FileManager.default.fileExists(atPath: lenovoSwiftShader.appendingPathComponent("libEGL.dll").path))
        #expect(!FileManager.default.fileExists(atPath: lenovoSwiftShader.appendingPathComponent("libGLESv2.dll").path))
        #expect(FileManager.default.fileExists(atPath: lenovoDisabledGPU.appendingPathComponent("swiftshader/libEGL.dll").path))
        #expect(FileManager.default.fileExists(atPath: lenovoDisabledGPU.appendingPathComponent("swiftshader/libGLESv2.dll").path))
        #expect(!FileManager.default.fileExists(atPath: hoYoPlayRootCache.path))
        #expect(!FileManager.default.fileExists(atPath: hoYoPlayFedataCache.path))
        #expect(!FileManager.default.fileExists(atPath: hoYoPlayServiceWorkerCache.path))
        let tencentDisabledGPU = tencentAndrowsVersion.appendingPathComponent(BottleService.disabledBundledGPUDLLDirectoryName, isDirectory: true)
        let tencentRendererDisabledGPU = tencentAndrowsRenderer.appendingPathComponent(BottleService.disabledBundledGPUDLLDirectoryName, isDirectory: true)
        #expect(!FileManager.default.fileExists(atPath: tencentAndrowsVersion.appendingPathComponent("vulkan-1.dll").path))
        #expect(!FileManager.default.fileExists(atPath: tencentAndrowsVersion.appendingPathComponent("vk_swiftshader.dll").path))
        #expect(FileManager.default.fileExists(atPath: tencentDisabledGPU.appendingPathComponent("vulkan-1.dll").path))
        #expect(FileManager.default.fileExists(atPath: tencentDisabledGPU.appendingPathComponent("vk_swiftshader.dll").path))
        #expect(!FileManager.default.fileExists(atPath: tencentAndrowsRenderer.appendingPathComponent("libEGL.dll").path))
        #expect(!FileManager.default.fileExists(atPath: tencentAndrowsRenderer.appendingPathComponent("libGLESv2.dll").path))
        #expect(FileManager.default.fileExists(atPath: tencentRendererDisabledGPU.appendingPathComponent("libEGL.dll").path))
        #expect(FileManager.default.fileExists(atPath: tencentRendererDisabledGPU.appendingPathComponent("libGLESv2.dll").path))
        #expect(!FileManager.default.fileExists(atPath: tencentAndrowsCEFCache.path))
        #expect(FileManager.default.fileExists(atPath: chromiumApplication.appendingPathComponent("chrome_elf.dll").path))
        #expect(FileManager.default.fileExists(atPath: chromiumApplication.appendingPathComponent("chrome_wer.dll").path))
        #expect(FileManager.default.fileExists(atPath: vivaldiApplication.appendingPathComponent("vivaldi_elf.dll").path))
        #expect(FileManager.default.fileExists(atPath: edgeApplication.appendingPathComponent("msedge_elf.dll").path))
        #expect(FileManager.default.fileExists(atPath: edgeApplication.appendingPathComponent("msedge_wer.dll").path))
        #expect(FileManager.default.fileExists(atPath: paths.bottleDirectory(id: bottle.id).appendingPathComponent(BottleService.renderingRepairSentinelName).path))
    }

    @Test("Compatibility repair copies engine CEF coverage DLLs")
    func compatibilityRepairCopiesEngineCEFCoverageDLLs() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinBottleCEFDLLTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let engineId = "engine"
        let build = paths.engineDirectory(id: engineId).appendingPathComponent("build", isDirectory: true)
        for item in BottleService.engineCoverageSystemDLLs {
            let x64 = build
                .appendingPathComponent("dlls", isDirectory: true)
                .appendingPathComponent(item.module, isDirectory: true)
                .appendingPathComponent("x86_64-windows", isDirectory: true)
            let x86 = build
                .appendingPathComponent("dlls", isDirectory: true)
                .appendingPathComponent(item.module, isDirectory: true)
                .appendingPathComponent("i386-windows", isDirectory: true)
            try FileManager.default.createDirectory(at: x64, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: x86, withIntermediateDirectories: true)
            try Data("x64-\(item.dll)".utf8).write(to: x64.appendingPathComponent(item.dll))
            try Data("x86-\(item.dll)".utf8).write(to: x86.appendingPathComponent(item.dll))
        }

        let service = BottleService(paths: paths)
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: engineId
        )
        try service.saveBottle(bottle)
        let engine = EngineManifest(
            id: engineId,
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: build.appendingPathComponent("loader/wine").path,
            wineserverPath: build.appendingPathComponent("server/wineserver").path,
            runtimePath: root.path,
            defaultEnv: [:]
        )

        try service.repairBottleCompatibility(bottle, engine: engine)

        for item in BottleService.engineCoverageSystemDLLs {
            #expect(FileManager.default.fileExists(atPath: paths.bottleDriveCURL(id: bottle.id)
                .appendingPathComponent("windows/system32/\(item.dll)").path))
            #expect(FileManager.default.fileExists(atPath: paths.bottleDriveCURL(id: bottle.id)
                .appendingPathComponent("windows/syswow64/\(item.dll)").path))
        }
    }

    @Test("Detected ONLYOFFICE launcher carries converter PATH")
    func detectedOnlyOfficeLauncherCarriesConverterPATH() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinBottleOnlyOfficeTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = BottleService(paths: paths)
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        try service.saveBottle(bottle)
        let app = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files", isDirectory: true)
            .appendingPathComponent("ONLYOFFICE", isDirectory: true)
            .appendingPathComponent("DesktopEditors", isDirectory: true)
        try FileManager.default.createDirectory(at: app.appendingPathComponent("converter", isDirectory: true), withIntermediateDirectories: true)
        try Data("exe".utf8).write(to: app.appendingPathComponent("DesktopEditors.exe"))

        let launchers = service.detectedInstalledLaunchers(in: bottle)
        let onlyOffice = try #require(launchers.first { $0.id == BottleService.onlyOfficeLauncherId })
        #expect(onlyOffice.exePath == "C:\\Program Files\\ONLYOFFICE\\DesktopEditors\\DesktopEditors.exe")
        #expect(onlyOffice.envOverrides["PATH"]?.contains("ONLYOFFICE\\DesktopEditors\\converter") == true)
        #expect(onlyOffice.envOverrides["MACWIN_COMPAT_PROFILE"] == "cef-software-gl")
        #expect(onlyOffice.envOverrides["MACWIN_ONLYOFFICE_RENDERER_FONT_REPAIR"] == "1")
    }

    @Test("Detected MuseScore launcher carries input repair profile")
    func detectedMuseScoreLauncherCarriesInputRepairProfile() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinBottleMuseScoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = BottleService(paths: paths)
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        try service.saveBottle(bottle)
        let app = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files", isDirectory: true)
            .appendingPathComponent("MuseScore 4", isDirectory: true)
            .appendingPathComponent("bin", isDirectory: true)
        try FileManager.default.createDirectory(at: app, withIntermediateDirectories: true)
        try Data("exe".utf8).write(to: app.appendingPathComponent("MuseScore4.exe"))

        let launchers = service.detectedInstalledLaunchers(in: bottle)
        let museScore = try #require(launchers.first { $0.id == BottleService.museScoreLauncherId })
        #expect(museScore.displayName == "MuseScore Studio")
        #expect(museScore.exePath == "C:\\Program Files\\MuseScore 4\\bin\\MuseScore4.exe")
        #expect(museScore.args == ApplicationCompatibilityProfile.museScoreStudio.launchArguments)
        #expect(museScore.envOverrides["MACWIN_COMPAT_PROFILE"] == "musescore-studio")
        #expect(museScore.envOverrides["MACWIN_APP_MODE_INPUT_REPAIR"] == "1")
        #expect(museScore.envOverrides["MACWIN_MUSESCORE_WELCOME_REPAIR"] == "1")
        #expect(launchers.filter { $0.exePath == museScore.exePath }.count == 1)
    }

    @Test("Detected mRemoteNG 1.78.2 launcher carries dotnet runtime repair profile")
    func detectedMRemoteNG1782LauncherCarriesDotNetRuntimeRepairProfile() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinBottleMRemoteNG1782Tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = BottleService(paths: paths)
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        try service.saveBottle(bottle)
        let app = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("macwin-portable", isDirectory: true)
            .appendingPathComponent("mremoteng-1782-x64", isDirectory: true)
        try FileManager.default.createDirectory(at: app, withIntermediateDirectories: true)
        try Data("exe".utf8).write(to: app.appendingPathComponent("mRemoteNG.exe"))

        let launchers = service.detectedInstalledLaunchers(in: bottle)
        let mRemoteNG = try #require(launchers.first { $0.id == BottleService.mRemoteNG1782LauncherId })
        #expect(mRemoteNG.displayName == "mRemoteNG 1.78.2")
        #expect(mRemoteNG.exePath == "C:\\macwin-portable\\mremoteng-1782-x64\\mRemoteNG.exe")
        #expect(mRemoteNG.args == ApplicationCompatibilityProfile.mRemoteNG1782.launchArguments)
        #expect(mRemoteNG.envOverrides["MACWIN_COMPAT_PROFILE"] == "mremoteng-1782-x64")
        #expect(mRemoteNG.envOverrides["MACWIN_DOTNET_DESKTOP10_RUNTIME_REPAIR"] == "1")
        #expect(mRemoteNG.envOverrides["MACWIN_MREMOTENG_REPAIR"] == "1")
        #expect(mRemoteNG.envOverrides["DOTNET_ROOT_X64"] == "C:\\macwin-runtimes\\dotnet-desktop-10-x64")
        #expect(launchers.filter { $0.exePath == mRemoteNG.exePath }.count == 1)
    }

    @Test("Detected 7-Zip launchers carry GDI stable profile")
    func detectedSevenZipLaunchersCarryGDIStableProfile() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinSevenZipDetectionTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = BottleService(paths: paths)
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        try service.saveBottle(bottle)
        let sevenZipDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files", isDirectory: true)
            .appendingPathComponent("7-Zip", isDirectory: true)
        try FileManager.default.createDirectory(at: sevenZipDirectory, withIntermediateDirectories: true)
        for fileName in ["7zFM.exe", "7zG.exe", "7z.exe"] {
            FileManager.default.createFile(
                atPath: sevenZipDirectory.appendingPathComponent(fileName).path,
                contents: Data("MZ".utf8)
            )
        }

        let launchers = service.detectedInstalledLaunchers(in: bottle)
        let launcherIds = Set(launchers.map(\.id))

        #expect(launcherIds.contains(BottleService.sevenZipFileManagerLauncherId))
        #expect(launcherIds.contains(BottleService.sevenZipGUILauncherId))
        #expect(launcherIds.contains(BottleService.sevenZipConsoleLauncherId))
        for launcher in launchers.filter({ $0.appId == "7zip" }) {
            #expect(launcher.envOverrides["MACWIN_COMPAT_PROFILE"] == "7zip-gdi")
            #expect(launcher.envOverrides["MACWIN_ACTIVATE_WINE_APP"] == "0")
            #expect(launcher.envOverrides["MACWIN_APP_MODE_INPUT_REPAIR"] == "0")
            #expect(launcher.envOverrides["MACWIN_DISABLE_WINE_APP_ACTIVATION"] == "1")
            #expect(launcher.envOverrides["MACWIN_DISABLE_WINE_D3D_CONFIG"] == "1")
        }
    }

    @Test("Detected SumatraPDF launcher prefers user local install path")
    func detectedSumatraPDFLauncherPrefersUserLocalInstallPath() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinBottleSumatraTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = BottleService(paths: paths)
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        try service.saveBottle(bottle)
        let sumatraDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("users", isDirectory: true)
            .appendingPathComponent("tester", isDirectory: true)
            .appendingPathComponent("AppData", isDirectory: true)
            .appendingPathComponent("Local", isDirectory: true)
            .appendingPathComponent("SumatraPDF", isDirectory: true)
        try FileManager.default.createDirectory(at: sumatraDirectory, withIntermediateDirectories: true)
        FileManager.default.createFile(
            atPath: sumatraDirectory.appendingPathComponent("SumatraPDF.exe").path,
            contents: Data("MZ".utf8)
        )

        let launchers = service.detectedInstalledLaunchers(in: bottle)
        let sumatra = try #require(launchers.first { $0.id == BottleService.sumatraPDFLauncherId })

        #expect(sumatra.appId == "sumatrapdf")
        #expect(sumatra.exePath == "C:\\users\\tester\\AppData\\Local\\SumatraPDF\\SumatraPDF.exe")
        #expect(sumatra.envOverrides["MACWIN_FONTCONFIG_REPAIR"] == "1")
        #expect(sumatra.envOverrides["MACWIN_TEXT_RENDERING_REPAIR"] == "1")
    }

    @Test("Detected VLC launcher carries media rendering profile")
    func detectedVLCLauncherCarriesMediaRenderingProfile() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinBottleVLCTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = BottleService(paths: paths)
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        try service.saveBottle(bottle)
        let vlcDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files", isDirectory: true)
            .appendingPathComponent("VideoLAN", isDirectory: true)
            .appendingPathComponent("VLC", isDirectory: true)
        try FileManager.default.createDirectory(at: vlcDirectory, withIntermediateDirectories: true)
        FileManager.default.createFile(
            atPath: vlcDirectory.appendingPathComponent("vlc.exe").path,
            contents: Data("MZ".utf8)
        )

        let launchers = service.detectedInstalledLaunchers(in: bottle)
        let vlc = try #require(launchers.first { $0.id == BottleService.vlcLauncherId })

        #expect(vlc.appId == "vlc")
        #expect(vlc.exePath == "C:\\Program Files\\VideoLAN\\VLC\\vlc.exe")
        #expect(vlc.envOverrides["WINE_D3D_CONFIG"] == "renderer=vulkan,csmt=0x0")
        #expect(vlc.envOverrides["MACWIN_FONTCONFIG_REPAIR"] == "1")
        #expect(vlc.envOverrides["MACWIN_TEXT_RENDERING_REPAIR"] == "1")
    }

    @Test("Compatibility profile can be applied to an installed launcher")
    func compatibilityProfileCanBeAppliedToInstalledLauncher() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinBottleProfileTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = BottleService(paths: paths)
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine",
            installedApps: [
                LauncherManifest(
                    id: "app",
                    appId: "app",
                    bottleId: "bottle",
                    displayName: "App",
                    exePath: "C:\\App\\app.exe",
                    args: ["--user"],
                    envOverrides: ["CUSTOM": "1"]
                )
            ]
        )
        try service.saveBottle(bottle)

        let launcher = try #require(bottle.installedApps.first)
        let updated = try service.applyCompatibilityProfile(.cefSoftwareRenderer, to: launcher, in: bottle)
        let updatedLauncher = try #require(updated.installedApps.first)

        #expect(updatedLauncher.args == ApplicationCompatibilityProfile.cefSoftwareRenderer.launchArguments + ["--user"])
        #expect(updatedLauncher.envOverrides["MACWIN_COMPAT_PROFILE"] == "cef-software-gl")
        #expect(updatedLauncher.envOverrides["CUSTOM"] == "1")
    }

    @Test("Compatibility profile can be cleared from an installed launcher")
    func compatibilityProfileCanBeClearedFromInstalledLauncher() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinBottleClearProfileTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = BottleService(paths: paths)
        let launcher = ApplicationCompatibilityProfile.steamClient.applied(to: LauncherManifest(
            id: "steam",
            appId: "steam",
            bottleId: "bottle",
            displayName: "Steam",
            exePath: "C:\\Program Files\\Steam\\Steam.exe",
            envOverrides: ["CUSTOM": "1"]
        ))
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine",
            installedApps: [launcher]
        )
        try service.saveBottle(bottle)

        let updated = try service.clearCompatibilityProfile(from: launcher, in: bottle)
        let updatedLauncher = try #require(updated.installedApps.first)

        #expect(updatedLauncher.envOverrides["MACWIN_COMPAT_PROFILE"] == ApplicationCompatibilityProfile.disabledProfileValue)
        #expect(updatedLauncher.envOverrides["MACWIN_FORCE_MOUSE_FOCUS"] == nil)
        #expect(updatedLauncher.envOverrides["CUSTOM"] == "1")
        #expect(ApplicationCompatibilityProfile.current(in: updatedLauncher) == nil)
    }
}
