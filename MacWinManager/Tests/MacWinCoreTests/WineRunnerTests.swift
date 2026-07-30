import Foundation
import Testing
@testable import MacWinCore

@Suite("Wine runner")
struct WineRunnerTests {
    @Test("Detached activation helpers are terminated after their deadline")
    func detachedActivationHelpersAreTerminatedAfterTheirDeadline() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sleep")
        process.arguments = ["30"]
        try process.run()

        WineRunner.scheduleTermination(of: process, after: 0.05)
        let deadline = Date().addingTimeInterval(2)
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.02)
        }

        #expect(!process.isRunning)
    }

    @Test("QGroundControl fallback keeps Qt Quick RHI and removes MuseScore behavior")
    func qGroundControlFallbackUsesCleanQtQuickRHIProfile() {
        let runner = WineRunner(paths: MacWinPaths(root: URL(fileURLWithPath: "/tmp/MacWin QGC Tests")))
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/tmp/Engine/loader/wine",
            wineserverPath: "/tmp/Engine/server/wineserver",
            runtimePath: "/tmp/runtime",
            defaultEnv: [:]
        )
        let bottle = BottleManifest(
            id: "qgroundcontrol",
            name: "QGroundControl",
            windowsVersion: "win11",
            arch: .win64,
            engineId: engine.id
        )

        let request = runner.sanitizedRuntimeRequest(WineRunRequest(
            exe: "C:\\Program Files\\QGroundControl\\bin\\QGroundControl.exe",
            bottle: bottle,
            engine: engine
        ))

        #expect(request.args.isEmpty)
        #expect(request.envOverrides["MACWIN_COMPAT_PROFILE"] == "qt-rhi-software")
        #expect(request.envOverrides["QT_OPENGL"] == "software")
        #expect(request.envOverrides["QSG_RHI_BACKEND"] == "opengl")
        #expect(request.envOverrides["QT_QUICK_BACKEND"] == nil)
        #expect(request.envOverrides["QT_RHI_BACKEND"] == nil)
        #expect(request.envOverrides["MACWIN_MUSESCORE_WELCOME_REPAIR"] == nil)
        #expect(request.envOverrides["MACWIN_SYNC_MUSESCORE_REGISTRY"] == nil)
    }

    @Test("Wine launch entry points fail fast while Rosetta is stalled")
    func wineLaunchEntryPointsFailFastDuringRosettaStall() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerRuntimeGuardTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(
            paths: paths,
            uninterruptibleRuntimeProcessProvider: { [80564, 70066, 80564] }
        )
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: paths.enginesDirectory.appendingPathComponent("engine/build/loader/wine").path,
            wineserverPath: paths.enginesDirectory.appendingPathComponent("engine/build/server/wineserver").path,
            runtimePath: "/runtime",
            defaultEnv: [:]
        )
        let bottle = BottleManifest(
            id: "runtime-guard",
            name: "Runtime Guard",
            windowsVersion: "win11",
            arch: .win64,
            engineId: engine.id
        )
        let request = WineRunRequest(exe: "probe.exe", bottle: bottle, engine: engine)
        let expected = MacWinError.runtimeUnavailable(processIdentifiers: [70066, 80564])

        #expect(throws: expected) { try runner.run(request) }
        #expect(throws: expected) { try runner.smokeLaunch(request, timeoutSeconds: 1) }
        #expect(throws: expected) { try runner.launchDetached(request) }
        #expect(throws: expected) { try runner.terminateBottle(bottle: bottle, engine: engine) }
        #expect(!FileManager.default.fileExists(atPath: paths.root.path))
    }

    @Test("Environment precedence is engine, bottle, recipe, launch")
    func environmentPrecedence() {
        let runner = WineRunner(
            paths: MacWinPaths(root: URL(fileURLWithPath: "/tmp/MacWin Tests")),
            hostNetworkEnvironmentProvider: { ["MACWIN_HOST_IPV4": "192.168.10.101"] }
        )
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/tmp/Engine/loader/wine",
            wineserverPath: "/tmp/Engine/server/wineserver",
            runtimePath: "/tmp/runtime",
            defaultEnv: ["A": "engine", "B": "engine", "WINEARCH": "win64"]
        )
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine",
            envOverrides: ["B": "bottle", "C": "bottle"]
        )

        let env = runner.mergedEnvironment(
            engine: engine,
            bottle: bottle,
            recipeEnv: ["C": "recipe", "D": "recipe"],
            launchEnv: ["D": "launch", "E": "launch"]
        )

        #expect(env["A"] == "engine")
        #expect(env["B"] == "bottle")
        #expect(env["C"] == "recipe")
        #expect(env["D"] == "launch")
        #expect(env["E"] == "launch")
        #expect(env["WINEPREFIX"] == "/tmp/MacWin Tests/Bottles/bottle")
        #expect(env["MACWIN_HOST_IPV4"] == "192.168.10.101")
        #expect(env["MACWIN_MANAGED_LAUNCH"] == "1")
        #expect(env["MACWIN_DOCK_POLICY"] == "managed-app-mode")
        #expect(env["WINEDLLOVERRIDES"] == "winemenubuilder.exe=d")
    }

    @Test("Rosetta x87 is enabled only for known sensitive 32-bit launchers")
    func rosettaX87IsSelective() {
        let runner = WineRunner(
            paths: MacWinPaths(root: URL(fileURLWithPath: "/tmp/MacWin Tests")),
            rosettaX87Path: "/bin/echo"
        )
        let engine = EngineManifest(
            id: "wow64-engine",
            name: "WoW64 Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            supportsWin32: true,
            winePath: "/tmp/Engine/loader/wine",
            wineserverPath: "/tmp/Engine/server/wineserver",
            runtimePath: "/tmp/runtime",
            defaultEnv: [:]
        )
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: engine.id
        )
        let sensitiveExecutables = [
            "C:\\Program Files (x86)\\Pale Moon\\core\\palemoon.exe",
            "C:\\Program Files (x86)\\WinSCP\\WinSCP.exe",
            "C:\\Program Files (x86)\\WinSCP\\WinSCP.com",
            "C:\\PortableApps\\PortableApps.com\\PortableAppsPlatform.exe"
        ]

        for executable in sensitiveExecutables {
            let request = runner.sanitizedRuntimeRequest(WineRunRequest(
                exe: executable,
                bottle: bottle,
                engine: engine
            ))
            #expect(request.envOverrides["ROSETTA_X87_PATH"] == "/bin/echo")
        }

        for executable in ["wineboot", "C:\\Program Files\\PowerToys\\PowerToys.exe"] {
            let request = runner.sanitizedRuntimeRequest(WineRunRequest(
                exe: executable,
                bottle: bottle,
                engine: engine
            ))
            #expect(request.envOverrides["ROSETTA_X87_PATH"] == nil)
        }

        let explicitlyDisabled = runner.sanitizedRuntimeRequest(WineRunRequest(
            exe: "C:\\Program Files (x86)\\WinSCP\\WinSCP.exe",
            bottle: bottle,
            engine: engine,
            envOverrides: ["ROSETTA_X87_PATH": ""]
        ))
        #expect(explicitlyDisabled.envOverrides["ROSETTA_X87_PATH"] == "")
    }

    @Test("Rosetta x87 is unavailable on x64-only engines")
    func rosettaX87RequiresWoW64Engine() {
        let runner = WineRunner(
            paths: MacWinPaths(root: URL(fileURLWithPath: "/tmp/MacWin Tests")),
            rosettaX87Path: "/bin/echo"
        )
        let engine = EngineManifest(
            id: "x64-engine",
            name: "x64 Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            supportsWin32: false,
            winePath: "/tmp/Engine/loader/wine",
            wineserverPath: "/tmp/Engine/server/wineserver",
            runtimePath: "/tmp/runtime",
            defaultEnv: [:]
        )
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: engine.id
        )

        let request = runner.sanitizedRuntimeRequest(WineRunRequest(
            exe: "C:\\Program Files (x86)\\WinSCP\\WinSCP.exe",
            bottle: bottle,
            engine: engine
        ))
        #expect(request.envOverrides["ROSETTA_X87_PATH"] == nil)
    }

    @Test("Managed and host environment stays below explicit launch overrides")
    func hostNetworkEnvironmentPrecedence() {
        let runner = WineRunner(
            paths: MacWinPaths(root: URL(fileURLWithPath: "/tmp/MacWin Tests")),
            hostNetworkEnvironmentProvider: {
                [
                    "MACWIN_HOST_IPV4": "192.168.10.101",
                    "MACWIN_GATEWAY_IPV4": "192.168.10.2",
                    "MACWIN_DNS_IPV4": "192.168.1.1"
                ]
            }
        )
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/tmp/Engine/loader/wine",
            wineserverPath: "/tmp/Engine/server/wineserver",
            runtimePath: "/tmp/runtime",
            defaultEnv: ["MACWIN_DNS_IPV4": "1.1.1.1"]
        )
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine",
            envOverrides: ["MACWIN_GATEWAY_IPV4": "10.0.0.1"]
        )

        let env = runner.mergedEnvironment(
            engine: engine,
            bottle: bottle,
            launchEnv: [
                "MACWIN_HOST_IPV4": "10.0.0.2",
                "MACWIN_DOCK_POLICY": "custom"
            ]
        )

        #expect(env["MACWIN_HOST_IPV4"] == "10.0.0.2")
        #expect(env["MACWIN_GATEWAY_IPV4"] == "10.0.0.1")
        #expect(env["MACWIN_DNS_IPV4"] == "1.1.1.1")
        #expect(env["MACWIN_MANAGED_LAUNCH"] == "1")
        #expect(env["MACWIN_DOCK_POLICY"] == "custom")
        #expect(env["WINEDLLOVERRIDES"] == "winemenubuilder.exe=d")
    }

    @Test("Host proxy variables are neutralized unless explicitly provided")
    func hostProxyVariablesAreNeutralizedUnlessExplicitlyProvided() {
        let runner = WineRunner(
            paths: MacWinPaths(root: URL(fileURLWithPath: "/tmp/MacWin Tests")),
            processEnvironmentProvider: {
                [
                    "HOME": "/Users/tester",
                    "PATH": "/usr/bin:/bin",
                    "ALL_PROXY": "socks5://127.0.0.1:7897",
                    "HTTP_PROXY": "http://127.0.0.1:7897",
                    "HTTPS_PROXY": "http://127.0.0.1:7897",
                    "NO_PROXY": "localhost,127.0.0.1",
                    "all_proxy": "socks5://127.0.0.1:7897",
                    "http_proxy": "http://127.0.0.1:7897",
                    "https_proxy": "http://127.0.0.1:7897",
                    "no_proxy": "localhost,127.0.0.1"
                ]
            },
            hostNetworkEnvironmentProvider: { [:] }
        )
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/tmp/Engine/loader/wine",
            wineserverPath: "/tmp/Engine/server/wineserver",
            runtimePath: "/tmp/runtime",
            defaultEnv: [:]
        )
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )

        let env = runner.mergedEnvironment(engine: engine, bottle: bottle)

        #expect(env["HOME"] == "/Users/tester")
        #expect(env["PATH"] == "/usr/bin:/bin")
        #expect(env["ALL_PROXY"] == "")
        #expect(env["HTTP_PROXY"] == "")
        #expect(env["HTTPS_PROXY"] == "")
        #expect(env["NO_PROXY"] == "")
        #expect(env["all_proxy"] == "")
        #expect(env["http_proxy"] == "")
        #expect(env["https_proxy"] == "")
        #expect(env["no_proxy"] == "")

        let explicit = runner.mergedEnvironment(
            engine: engine,
            bottle: bottle,
            launchEnv: [
                "ALL_PROXY": "socks5://10.0.0.2:9000",
                "NO_PROXY": "*"
            ]
        )

        #expect(explicit["ALL_PROXY"] == "socks5://10.0.0.2:9000")
        #expect(explicit["NO_PROXY"] == "*")
        #expect(explicit["HTTP_PROXY"] == "")
    }

    @Test("Managed app mode disables Wine menu builder without clobbering app overrides")
    func managedAppModeDisablesWineMenuBuilder() {
        let runner = WineRunner(paths: MacWinPaths(root: URL(fileURLWithPath: "/tmp/MacWin Tests")))
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/tmp/Engine/loader/wine",
            wineserverPath: "/tmp/Engine/server/wineserver",
            runtimePath: "/tmp/runtime",
            defaultEnv: ["WINEDLLOVERRIDES": "wbemprox=d"]
        )
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine",
            envOverrides: ["WINEDLLOVERRIDES": "qone,wbemprox=d"]
        )

        let env = runner.mergedEnvironment(
            engine: engine,
            bottle: bottle,
            recipeEnv: ["WINEDLLOVERRIDES": "qone,wbemprox=d;dxgi,d3d12=n,b"]
        )

        #expect(env["WINEDLLOVERRIDES"] == "qone,wbemprox=d;dxgi,d3d12=n,b;winemenubuilder.exe=d")
    }

    @Test("Wine menu builder can be explicitly allowed for compatibility experiments")
    func wineMenuBuilderCanBeExplicitlyAllowed() {
        let runner = WineRunner(paths: MacWinPaths(root: URL(fileURLWithPath: "/tmp/MacWin Tests")))
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/tmp/Engine/loader/wine",
            wineserverPath: "/tmp/Engine/server/wineserver",
            runtimePath: "/tmp/runtime",
            defaultEnv: ["WINEDLLOVERRIDES": "wbemprox=d"]
        )
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )

        let env = runner.mergedEnvironment(
            engine: engine,
            bottle: bottle,
            launchEnv: ["MACWIN_ALLOW_WINE_MENU_BUILDER": "1"]
        )

        #expect(env["WINEDLLOVERRIDES"] == "wbemprox=d")
        #expect(env["MACWIN_ALLOW_WINE_MENU_BUILDER"] == "1")
    }

    @Test("Managed app mode applies Mac driver input repair by default")
    func managedAppModeAppliesMacDriverInputRepairByDefault() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerInputRepairTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "input-repair",
            name: "Input Repair",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )

        let result = try runner.run(WineRunRequest(
            exe: "C:\\Program Files\\Sample App\\SampleApp.exe",
            bottle: bottle,
            engine: engine
        ))

        #expect(result.exitCode == 0)
        let userRegistry = try String(
            contentsOf: paths.bottleDirectory(id: bottle.id).appendingPathComponent("user.reg"),
            encoding: .utf8
        )
        #expect(userRegistry.contains(#""Managed"="Y""#))
        #expect(userRegistry.contains(#""UseTakeFocus"="Y""#))
        #expect(userRegistry.contains(#"[Software\\Wine\\DirectInput]"#))
        #expect(userRegistry.contains(#""MouseWarpOverride"="disable""#))
        #expect(userRegistry.contains(#"[Software\\Wine\\X11 Driver]"#))
        #expect(userRegistry.contains(#""Decorated"="Y""#))
        #expect(userRegistry.contains(#"[Software\\Wine\\Fonts]"#))
        #expect(userRegistry.contains(#""LogPixels"=dword:00000060"#))
    }

    @Test("Bottle fontconfig is injected into launch environment")
    func bottleFontConfigIsInjectedIntoLaunchEnvironment() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerFontConfigTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/tmp/Engine/loader/wine",
            wineserverPath: "/tmp/Engine/server/wineserver",
            runtimePath: "/tmp/runtime",
            defaultEnv: [:]
        )
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        let fontConfigURL = BottleService.fontConfigURL(for: bottle.id, paths: paths)
        try FileManager.default.createDirectory(at: fontConfigURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("<fontconfig />".utf8).write(to: fontConfigURL)

        let env = runner.mergedEnvironment(engine: engine, bottle: bottle)

        #expect(env["FONTCONFIG_FILE"] == fontConfigURL.path)
        #expect(env["FONTCONFIG_PATH"] == paths.bottleDirectory(id: bottle.id).path)
        #expect(env["FC_LANG"] == "zh-cn")
        let expectedLocale = env["LC_ALL"] ?? env["LANG"] ?? "zh_CN.UTF-8"
        #expect(env["LC_CTYPE"] == expectedLocale)
    }

    @Test("Command line uses argument array and preserves spaces")
    func commandLinePreservesSpaces() {
        let runner = WineRunner()
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/tmp/Engine With Spaces/loader/wine",
            wineserverPath: "/tmp/Engine With Spaces/server/wineserver",
            runtimePath: "/tmp/runtime",
            defaultEnv: [:],
            healthChecks: []
        )
        let bottle = BottleManifest(
            id: "米-bottle",
            name: "米",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        let request = WineRunRequest(
            exe: "/tmp/Program Files/米/HYP.exe",
            args: ["--user", "hello world"],
            bottle: bottle,
            engine: engine
        )

        #expect(runner.commandLine(for: request) == [
            "/usr/bin/arch",
            "-x86_64",
            "/tmp/Engine With Spaces/loader/wine",
            "/tmp/Program Files/米/HYP.exe",
            "--user",
            "hello world"
        ])
    }

    @Test("Runtime launch strips obsolete DirectWrite and Chromium font flags")
    func runtimeLaunchStripsObsoleteTextRenderingFlags() {
        let runner = WineRunner(paths: MacWinPaths(root: URL(fileURLWithPath: "/tmp/MacWin Tests")))
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/tmp/Engine/loader/wine",
            wineserverPath: "/tmp/Engine/server/wineserver",
            runtimePath: "/tmp/runtime",
            defaultEnv: [:]
        )
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        let request = WineRunRequest(
            exe: "C:\\Program Files\\miHoYo Launcher\\HYP.exe",
            args: [
                "--disable-direct-write",
                "--disable-directwrite-for-ui",
                "--disable-remote-fonts",
                "--disable-font-subpixel-positioning",
                "--disable-lcd-text",
                "--disable-prefer-compositing-to-lcd-text",
                "--font-render-hinting=none",
                "--disable-features=DWriteFontProxy,UseDWriteCore,UseSkiaRenderer,CustomFeature",
                "--keep"
            ],
            bottle: bottle,
            engine: engine,
            envOverrides: [
                "MACWIN_CHROMIUM_HELPER_ARGS": "--disable-direct-write --disable-font-subpixel-positioning --disable-features=DWriteFontProxy,UseDWriteCore,HelperFeature",
                "MACWIN_STEAMWEBHELPER_ARGS": "--disable-remote-fonts --disable-lcd-text --disable-features=FontSrcLocalMatching,SteamFeature",
                "QTWEBENGINE_CHROMIUM_FLAGS": "--disable-directwrite-for-ui --font-render-hinting=none --disable-features=FontationsFontBackend,QtFeature",
                "MACWIN_FONT_FALLBACK_REPAIR": "1",
                "FREETYPE_PROPERTIES": "truetype:interpreter-version=35",
                "QTWEBENGINE_DISABLE_SANDBOX": "1",
                "WINEDLLOVERRIDES": "qone,wbemprox=d;dwrite,usp10=b;dxgi,d3d12=n,b"
            ]
        )

        let commandLine = runner.commandLine(for: request)
        #expect(!commandLine.contains("--disable-direct-write"))
        #expect(!commandLine.contains("--disable-directwrite-for-ui"))
        #expect(!commandLine.contains("--disable-remote-fonts"))
        #expect(!commandLine.contains("--disable-font-subpixel-positioning"))
        #expect(!commandLine.contains("--disable-lcd-text"))
        #expect(!commandLine.contains("--disable-prefer-compositing-to-lcd-text"))
        #expect(!commandLine.contains("--font-render-hinting=none"))
        #expect(commandLine.contains("--disable-features=CustomFeature"))
        #expect(commandLine.contains("--keep"))

        let env = runner.mergedEnvironment(
            engine: engine,
            bottle: bottle,
            launchEnv: request.envOverrides
        )
        #expect(env["MACWIN_CHROMIUM_HELPER_ARGS"] == "--disable-features=HelperFeature")
        #expect(env["MACWIN_STEAMWEBHELPER_ARGS"] == "--disable-features=SteamFeature")
        #expect(env["QTWEBENGINE_CHROMIUM_FLAGS"] == "--disable-features=QtFeature")
        #expect(env["MACWIN_FONT_FALLBACK_REPAIR"] == "1")
        #expect(env["FREETYPE_PROPERTIES"] == "truetype:interpreter-version=35")
        #expect(env["QTWEBENGINE_DISABLE_SANDBOX"] == "1")
        #expect(env["WINEDLLOVERRIDES"] == "qone,wbemprox=d;dxgi,d3d12=n,b;winemenubuilder.exe=d")
    }

    @Test("Windows 11 desktop request uses Wine explorer virtual desktop")
    func windows11DesktopRequest() {
        let runner = WineRunner()
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/tmp/Engine/loader/wine",
            wineserverPath: "/tmp/Engine/server/wineserver",
            runtimePath: "/tmp/runtime",
            defaultEnv: ["WINE_D3D_CONFIG": "renderer=vulkan,csmt=0x0"]
        )
        let bottle = BottleManifest(
            id: "win11-bottle",
            name: "Windows 11",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )

        let request = runner.windows11DesktopRequest(bottle: bottle, engine: engine, width: 640, height: 480)

        #expect(request.exe == "C:\\windows\\system32\\explorer.exe")
        #expect(request.args == ["/desktop=MacWin-Windows-11,800x600", "C:\\windows\\system32\\winefile.exe"])
        #expect(request.envOverrides["WINE_D3D_CONFIG"] == "renderer=vulkan,csmt=0x0")
        #expect(request.logName == "win11-bottle-windows11-desktop.log")
    }

    @Test("Launch can start before drive_c exists")
    func launchFallsBackWhenDriveCMissing() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let runner = WineRunner(paths: MacWinPaths(root: root))
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
        let bottle = BottleManifest(
            id: "missing-drive-c",
            name: "Missing Drive C",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        try JSONStore().save(bottle, to: MacWinPaths(root: root).bottleManifestURL(id: bottle.id))

        let result = try runner.run(WineRunRequest(exe: "hello", bottle: bottle, engine: engine))

        #expect(result.exitCode == 0)
        #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent("Bottles/missing-drive-c").path))
    }

    @Test("Managed launch applies input and MuseScore first-run repairs")
    func managedLaunchAppliesInputAndMuseScoreFirstRunRepairs() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerMuseScoreRepairTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "musescore",
            name: "MuseScore",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        let userDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("users/tester", isDirectory: true)
        try FileManager.default.createDirectory(at: userDirectory, withIntermediateDirectories: true)
        let staleRegistry = paths.bottleDirectory(id: bottle.id).appendingPathComponent("user.reg")
        try FileManager.default.createDirectory(at: staleRegistry.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("""
        WINE REGISTRY Version 2

        [Software\\\\MuseScore\\\\MuseScore Studio]
        "applicationhasCompletedFirstLaunchSetup"=dword:00000000
        "ui\\applicationstartupshowSplashScreen"=dword:00000001
        "ui\\theme\\fontFamily"="Broken"

        """.utf8).write(to: staleRegistry)

        let result = try runner.run(WineRunRequest(
            exe: "C:\\Program Files\\MuseScore 4\\bin\\MuseScore4.exe",
            bottle: bottle,
            engine: engine,
            envOverrides: [
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_QT_RHI_SOFTWARE_REPAIR": "1",
                "MACWIN_RETINA_INPUT_REPAIR": "1"
            ]
        ))

        #expect(result.exitCode == 0)
        let userRegistry = try String(
            contentsOf: paths.bottleDirectory(id: bottle.id).appendingPathComponent("user.reg"),
            encoding: .utf8
        )
        #expect(userRegistry.contains(#""UseTakeFocus"="Y""#))
        #expect(userRegistry.contains(#""Decorated"="Y""#))
        #expect(userRegistry.contains(#"[Software\\Wine\\DirectInput]"#))
        #expect(userRegistry.contains(#""MouseWarpOverride"="disable""#))
        #expect(userRegistry.contains(#""RetinaMode"="Y""#))
        #expect(userRegistry.contains(#""LogPixels"=dword:000000c0"#))
        #expect(userRegistry.contains(#"[Software\\MuseScore\\MuseScore Studio\\application]"#))
        #expect(userRegistry.contains(#"[Software\\MuseScore\\MuseScore4\\appshell\\application]"#))
        #expect(userRegistry.contains(#"[Software\\MuseScore\\MuseScore Studio\\appshell\\application]"#))
        #expect(!userRegistry.contains(#""applicationhasCompletedFirstLaunchSetup"=dword:00000001"#))
        #expect(!userRegistry.contains(#""applicationwelcomeDialogShowOnStartup"=dword:00000000"#))
        #expect(!userRegistry.contains(#""applicationstartupmodeStart"=dword:00000000"#))
        #expect(!userRegistry.contains(#""uiapplicationstartupshowSplashScreen"=dword:00000000"#))
        #expect(!userRegistry.contains(#""ui\applicationstartupshowSplashScreen"=dword:00000001"#))
        #expect(!userRegistry.contains(#""ui\theme\fontFamily"="Broken""#))
        #expect(userRegistry.contains(#""hasCompletedFirstLaunchSetup"=dword:00000001"#))
        #expect(userRegistry.contains(#""welcomeDialogShowOnStartup"=dword:00000000"#))
        #expect(userRegistry.contains(#""welcomeDialogLastShownVersion"="999.999.999""#))
        #expect(userRegistry.contains(#"[Software\\MuseScore\\MuseScore Studio\\application\\startup]"#))
        #expect(userRegistry.contains(#""modeStart"=dword:00000000"#))
        #expect(userRegistry.contains(#"[Software\\MuseScore\\MuseScore Studio\\ui\\application]"#))
        #expect(userRegistry.contains(#""currentThemeCode"="light""#))
        #expect(userRegistry.contains(#"[Software\\MuseScore\\MuseScore Studio\\ui\\application\\startup]"#))
        #expect(userRegistry.contains(#""showSplashScreen"=dword:00000000"#))
        #expect(userRegistry.contains(#"[Software\\MuseScore\\MuseScore Studio\\gettingstarted]"#))
        #expect(userRegistry.contains(#"[Software\\MuseScore\\MuseScore Studio\\gettingStarted]"#))
        #expect(userRegistry.contains(#"[Software\\MuseScore\\MuseScore Studio\\onboarding]"#))
        #expect(userRegistry.contains(#""finished"=dword:00000001"#))
        #expect(userRegistry.contains(#""currentPageIndex"=dword:000003e7"#))

        let museScoreConfig = try String(
            contentsOf: userDirectory.appendingPathComponent("AppData/Roaming/MuseScore/MuseScore4.ini"),
            encoding: .utf8
        )
        let museScoreStudioConfig = try String(
            contentsOf: userDirectory.appendingPathComponent("AppData/Roaming/MuseScore/MuseScore Studio.ini"),
            encoding: .utf8
        )
        let museScoreStudioOrgConfig = try String(
            contentsOf: userDirectory.appendingPathComponent("AppData/Roaming/MuseScore Studio/MuseScore Studio.ini"),
            encoding: .utf8
        )
        let museScoreStudio4Config = try String(
            contentsOf: userDirectory.appendingPathComponent("AppData/Roaming/MuseScore/MuseScore Studio 4.ini"),
            encoding: .utf8
        )
        let museScoreLocalConfig = try String(
            contentsOf: userDirectory.appendingPathComponent("AppData/Local/MuseScore/MuseScore4.ini"),
            encoding: .utf8
        )
        let museScoreRuntimeProfileConfig = try String(
            contentsOf: userDirectory.appendingPathComponent("AppData/Local/MuseScore/MuseScore4/MuseScore4.ini"),
            encoding: .utf8
        )
        let museScoreStableLocalConfig = try String(
            contentsOf: userDirectory.appendingPathComponent("AppData/Local/MuseScore Studio 4 stable/MuseScore Studio 4 stable.ini"),
            encoding: .utf8
        )
        let museScoreLocalLowRuntimeProfileConfig = try String(
            contentsOf: userDirectory.appendingPathComponent("AppData/LocalLow/MuseScore/MuseScore4/MuseScore Studio 4.ini"),
            encoding: .utf8
        )
        let museScore4OrgConfig = try String(
            contentsOf: userDirectory.appendingPathComponent("AppData/Roaming/MuseScore 4/MuseScore Studio 4.ini"),
            encoding: .utf8
        )
        let museScoreStudio4LocalLowConfig = try String(
            contentsOf: userDirectory.appendingPathComponent("AppData/LocalLow/MuseScoreStudio4/MuseScore4.ini"),
            encoding: .utf8
        )
        #expect(museScoreConfig.contains("hasCompletedFirstLaunchSetup=true"))
        #expect(museScoreConfig.contains("welcomeDialogShowOnStartup=false"))
        #expect(museScoreConfig.contains("welcomeDialogLastShownVersion=999.999.999"))
        #expect(museScoreConfig.contains("welcomeDialogLastShownIndex=999"))
        #expect(museScoreConfig.contains("currentStartupMode=0"))
        #expect(museScoreConfig.contains("showWelcomeDialog=false"))
        #expect(museScoreConfig.contains(#"startup\modeStart=0"#))
        #expect(museScoreConfig.contains("[application/startup]"))
        #expect(museScoreConfig.contains("modeStart=0"))
        #expect(museScoreConfig.contains("[appshell/application]"))
        #expect(museScoreConfig.contains("[appshell/application/startup]"))
        #expect(museScoreConfig.contains("[ui/application]"))
        #expect(museScoreConfig.contains("currentThemeCode=light"))
        #expect(museScoreConfig.contains("[appshell/ui/application]"))
        #expect(museScoreConfig.contains("[appshell]"))
        #expect(museScoreConfig.contains(#"application\hasCompletedFirstLaunchSetup=true"#))
        #expect(museScoreConfig.contains(#"application\welcomeDialogShowOnStartup=false"#))
        #expect(museScoreConfig.contains(#"application\startup\modeStart=0"#))
        #expect(museScoreConfig.contains(#"ui\application\startup\showSplashScreen=false"#))
        #expect(museScoreConfig.contains("[General]"))
        #expect(museScoreConfig.contains("application/hasCompletedFirstLaunchSetup=true"))
        #expect(museScoreConfig.contains("application/welcomeDialogShowOnStartup=false"))
        #expect(museScoreConfig.contains("[appshell/gettingstarted]"))
        #expect(museScoreConfig.contains("finished=true"))
        #expect(museScoreConfig.contains("[appshell/onboarding]"))
        #expect(museScoreConfig.contains("[gettingstarted]"))
        #expect(museScoreConfig.contains("[onboarding]"))
        #expect(museScoreConfig.contains("onboarding/finished=true"))
        #expect(museScoreConfig.contains("gettingstarted/finished=true"))
        #expect(museScoreConfig.contains(#"application\highContrastEnabled=false"#))
        #expect(museScoreConfig.contains(#"application\currentAccentColorIndex=4"#))
        #expect(museScoreConfig.contains(#"application\startup\showSplashScreen=false"#))
        #expect(museScoreStudioConfig.contains("hasCompletedFirstLaunchSetup=true"))
        #expect(museScoreStudioOrgConfig.contains("hasCompletedFirstLaunchSetup=true"))
        #expect(museScoreStudio4Config.contains("hasCompletedFirstLaunchSetup=true"))
        #expect(museScoreLocalConfig.contains("hasCompletedFirstLaunchSetup=true"))
        #expect(museScoreRuntimeProfileConfig.contains("hasCompletedFirstLaunchSetup=true"))
        #expect(museScoreRuntimeProfileConfig.contains("onboarding/finished=true"))
        #expect(museScoreStableLocalConfig.contains("hasCompletedFirstLaunchSetup=true"))
        #expect(museScoreLocalLowRuntimeProfileConfig.contains("hasCompletedFirstLaunchSetup=true"))
        #expect(museScore4OrgConfig.contains("hasCompletedFirstLaunchSetup=true"))
        #expect(museScoreStudio4LocalLowConfig.contains("hasCompletedFirstLaunchSetup=true"))
    }

    @Test("MuseScore first-run repair is applied by executable name fallback")
    func museScoreFirstRunRepairAppliesByExecutableNameFallback() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerMuseScoreFallbackTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "musescore-fallback",
            name: "MuseScore",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        let userDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("users/tester", isDirectory: true)
        try FileManager.default.createDirectory(at: userDirectory, withIntermediateDirectories: true)

        let result = try runner.run(WineRunRequest(
            exe: "C:\\Program Files\\MuseScore 4\\bin\\MuseScore4.exe",
            bottle: bottle,
            engine: engine
        ))

        #expect(result.exitCode == 0)
        #expect(result.commandLine.contains("--session-type"))
        #expect(result.commandLine.contains("start-empty"))
        let launchLog = try String(contentsOf: result.logURL, encoding: .utf8)
        #expect(launchLog.contains("env.MACWIN_COMPAT_PROFILE=musescore-studio"))
        #expect(launchLog.contains("env.MACWIN_APP_MODE_INPUT_REPAIR=1"))
        #expect(launchLog.contains("env.MACWIN_RETINA_INPUT_REPAIR=0"))
        let userRegistry = try String(
            contentsOf: paths.bottleDirectory(id: bottle.id).appendingPathComponent("user.reg"),
            encoding: .utf8
        )
        #expect(userRegistry.contains(#""UseTakeFocus"="Y""#))
        #expect(userRegistry.contains(#""MouseWarpOverride"="disable""#))
        #expect(userRegistry.contains(#""RetinaMode"="N""#))
        #expect(userRegistry.contains(#""LogPixels"=dword:00000060"#))
        #expect(userRegistry.contains(#""Decorated"="Y""#))
        #expect(userRegistry.contains(#"[Software\\MuseScore\\MuseScore Studio\\application]"#))
        #expect(userRegistry.contains(#""hasCompletedFirstLaunchSetup"=dword:00000001"#))
        #expect(userRegistry.contains(#""welcomeDialogShowOnStartup"=dword:00000000"#))
        #expect(userRegistry.contains(#""welcomeDialogLastShownVersion"="999.999.999""#))
        #expect(userRegistry.contains(#"[Software\\MuseScore\\MuseScore Studio\\appshell\\application]"#))
        #expect(!userRegistry.contains(#""applicationhasCompletedFirstLaunchSetup"=dword:00000001"#))
        #expect(!userRegistry.contains(#""applicationwelcomeDialogShowOnStartup"=dword:00000000"#))
        let museScoreConfig = try String(
            contentsOf: userDirectory.appendingPathComponent("AppData/Roaming/MuseScore/MuseScore4.ini"),
            encoding: .utf8
        )
        #expect(museScoreConfig.contains("hasCompletedFirstLaunchSetup=true"))
        #expect(museScoreConfig.contains("welcomeDialogShowOnStartup=false"))
        #expect(museScoreConfig.contains("welcomeDialogLastShownVersion=999.999.999"))
        #expect(museScoreConfig.contains("welcomeDialogLastShownIndex=999"))
    }

    @Test("LTspice launch disables analytics prompt and preserves UTF-16 settings")
    func ltspiceFirstLaunchRepairDisablesAnalyticsPrompt() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerLTspiceRepairTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "ltspice",
            name: "LTspice",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        let configURL = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("users/tester/AppData/Roaming/LTspice.ini")
        try FileManager.default.createDirectory(at: configURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let originalText = """
        [Options]
        CaptureAnalytics=true
        EngUnits=true

        [Colors]
        Background=0
        """
        var originalData = Data([0xFF, 0xFE])
        originalData.append(try #require(originalText.data(using: .utf16LittleEndian)))
        try originalData.write(to: configURL)

        let result = try runner.run(WineRunRequest(
            exe: "C:\\Program Files\\ADI\\LTspice\\LTspice.exe",
            bottle: bottle,
            engine: engine
        ))

        #expect(result.exitCode == 0)
        let repairedData = try Data(contentsOf: configURL)
        #expect(repairedData.starts(with: [0xFF, 0xFE]))
        let repairedText = try #require(String(
            data: Data(repairedData.dropFirst(2)),
            encoding: .utf16LittleEndian
        ))
        #expect(repairedText.contains("CaptureAnalytics=false"))
        #expect(!repairedText.contains("CaptureAnalytics=true"))
        #expect(repairedText.contains("EngUnits=true"))
        #expect(repairedText.contains("[Colors]"))
        #expect(repairedText.contains("Background=0"))
        #expect(FileManager.default.fileExists(
            atPath: paths.bottleDirectory(id: bottle.id)
                .appendingPathComponent(".macwin/repair-state/ltspice-first-launch-v1.done")
                .path
        ))
    }

    @Test("Executable fallback can be disabled for profile environment")
    func executableFallbackProfileCanBeDisabled() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerDisabledProfileTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "musescore-disabled-profile",
            name: "MuseScore Disabled Profile",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )

        let result = try runner.run(WineRunRequest(
            exe: "C:\\Program Files\\MuseScore 4\\bin\\MuseScore4.exe",
            bottle: bottle,
            engine: engine,
            envOverrides: ["MACWIN_COMPAT_PROFILE": ApplicationCompatibilityProfile.disabledProfileValue]
        ))

        #expect(result.exitCode == 0)
        #expect(!result.commandLine.contains("--session-type"))
        #expect(!result.commandLine.contains("start-empty"))
        let userRegistry = try String(
            contentsOf: paths.bottleDirectory(id: bottle.id).appendingPathComponent("user.reg"),
            encoding: .utf8
        )
        #expect(userRegistry.contains(#""UseTakeFocus"="Y""#))
        #expect(userRegistry.contains(#""RetinaMode"="N""#))
        #expect(userRegistry.contains(#""LogPixels"=dword:00000060"#))
        #expect(userRegistry.contains(#"[Software\\MuseScore\\MuseScore Studio\\application]"#))
    }

    @Test("SoftMaker executable fallback enables COM proxy repair")
    func softMakerExecutableFallbackEnablesCOMProxyRepair() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerSoftMakerProfileTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "softmaker",
            name: "SoftMaker",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )

        let result = try runner.run(WineRunRequest(
            exe: "C:\\Program Files (x86)\\SoftMaker FreeOffice 2024\\TextMaker.exe",
            bottle: bottle,
            engine: engine
        ))

        #expect(result.exitCode == 0)
        #expect(!result.commandLine.contains("--session-type"))
        let log = try String(contentsOf: result.logURL, encoding: .utf8)
        #expect(log.contains("env.MACWIN_COMPAT_PROFILE=softmaker-office"))
        #expect(log.contains("env.MACWIN_COM_PROXY_REPAIR=1"))
        #expect(log.contains("env.MACWIN_SOFTMAKER_OFFICE_REPAIR=1"))
    }

    @Test("TeXstudio executable fallback enables Qt6 repair")
    func texStudioExecutableFallbackEnablesQt6Repair() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerTeXstudioProfileTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "texstudio",
            name: "TeXstudio",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )

        let result = try runner.run(WineRunRequest(
            exe: "C:\\Program Files\\TeXstudio\\texstudio.exe",
            bottle: bottle,
            engine: engine
        ))

        #expect(result.exitCode == 0)
        #expect(result.commandLine.contains("--no-session"))
        #expect(result.commandLine.contains("-platform"))
        #expect(result.commandLine.contains("windows:fontengine=freetype"))
        let log = try String(contentsOf: result.logURL, encoding: .utf8)
        #expect(log.contains("env.MACWIN_COMPAT_PROFILE=texstudio-qt6"))
        #expect(log.contains("env.MACWIN_TEXSTUDIO_QT6_REPAIR=1"))
        #expect(log.contains("env.QT_OPENGL=software"))
        #expect(log.contains("env.QT_STYLE_OVERRIDE=windows"))
    }

    @Test("JASP executable fallback enables QtWebEngine qrc repair")
    func jaspExecutableFallbackEnablesQtWebEngineQrcRepair() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerJASPProfileTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "jasp",
            name: "JASP",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        let appDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files/JASP", isDirectory: true)
        try FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        let userDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("users/tester", isDirectory: true)
        let roamingDirectory = userDirectory
            .appendingPathComponent("AppData/Roaming/JASP", isDirectory: true)
        let ipcDirectory = userDirectory
            .appendingPathComponent("AppData/Local/JASP/JASP/temp", isDirectory: true)
        let boostIPCDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("ProgramData/boost_interprocess/01000000", isDirectory: true)
        try FileManager.default.createDirectory(at: roamingDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: ipcDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: boostIPCDirectory, withIntermediateDirectories: true)
        try Data("[General]\ncheckUpdates=true\n".utf8)
            .write(to: roamingDirectory.appendingPathComponent("JASP.ini"))
        try Data("stale".utf8).write(to: ipcDirectory.appendingPathComponent("JASP-IPC-32_0"))
        try Data("keep".utf8).write(to: ipcDirectory.appendingPathComponent("keep.txt"))
        try Data("stale".utf8).write(to: boostIPCDirectory.appendingPathComponent("JASP-IPC-32_heartbeat"))

        let result = try runner.run(WineRunRequest(
            exe: "C:\\Program Files\\JASP\\JASPDesktop.exe",
            bottle: bottle,
            engine: engine
        ))

        #expect(result.exitCode == 0)
        #expect(result.commandLine.contains("--safeGraphics"))
        #expect(result.commandLine.contains("--noSandbox"))
        let log = try String(contentsOf: result.logURL, encoding: .utf8)
        #expect(log.contains("workingDirectory=\(appDirectory.path)"))
        #expect(log.contains("env.MACWIN_COMPAT_PROFILE=jasp-qtwebengine-qrc"))
        #expect(log.contains("env.MACWIN_JASP_QRC_REPAIR=1"))
        #expect(log.contains("env.MACWIN_JASP_STARTUP_REPAIR=1"))
        #expect(log.contains("env.MACWIN_QTWEBENGINE_REPAIR=1"))
        #expect(log.contains("env.QTWEBENGINEPROCESS_PATH=C:\\Program Files\\JASP\\QtWebEngineProcess.exe"))
        #expect(log.contains("env.QTWEBENGINE_RESOURCES_PATH=C:\\Program Files\\JASP\\resources"))
        #expect(log.contains("env.QT_PLUGIN_PATH=C:\\Program Files\\JASP"))
        #expect(log.contains("env.QML2_IMPORT_PATH=C:\\Program Files\\JASP\\qml"))
        let userRegistry = try String(
            contentsOf: paths.bottleDirectory(id: bottle.id).appendingPathComponent("user.reg"),
            encoding: .utf8
        )
        #expect(userRegistry.contains(#""RetinaMode"="N""#))
        #expect(userRegistry.contains(#""LogPixels"=dword:00000060"#))
        let jaspSettings = try String(
            contentsOf: roamingDirectory.appendingPathComponent("JASP.ini"),
            encoding: .utf8
        )
        #expect(jaspSettings.contains("safeGraphicsMode=true"))
        #expect(jaspSettings.contains("engineSandbox=false"))
        #expect(jaspSettings.contains("checkUpdates=false"))
        #expect(jaspSettings.contains("remoteConfigurationURL=about:blank"))
        #expect(!FileManager.default.fileExists(atPath: ipcDirectory.appendingPathComponent("JASP-IPC-32_0").path))
        #expect(FileManager.default.fileExists(atPath: ipcDirectory.appendingPathComponent("keep.txt").path))
        #expect(!FileManager.default.fileExists(atPath: boostIPCDirectory.appendingPathComponent("JASP-IPC-32_heartbeat").path))
    }

    @Test("JabRef executable fallback selects D3D and repairs bundled JavaFX fonts")
    func jabRefExecutableFallbackSelectsD3DAndRepairsBundledFonts() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerJabRefProfileTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/bin/echo",
            wineserverPath: "/bin/echo",
            runtimePath: "/runtime",
            defaultEnv: ["WINE_D3D_CONFIG": "renderer=gl,csmt=0x0"]
        )
        let bottle = BottleManifest(
            id: "jabref",
            name: "JabRef",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        let applicationDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("macwin-portable/jabref-portable/JabRef", isDirectory: true)
        let runtimeLibrary = applicationDirectory.appendingPathComponent("runtime/lib", isDirectory: true)
        let windowsFonts = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("windows/Fonts", isDirectory: true)
        try FileManager.default.createDirectory(at: runtimeLibrary, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: windowsFonts, withIntermediateDirectories: true)
        try Data("fontconfig-source".utf8)
            .write(to: runtimeLibrary.appendingPathComponent("fontconfig.properties.src"))
        try Data("stale-cache".utf8)
            .write(to: runtimeLibrary.appendingPathComponent("fontconfig.bfc"))
        let regularFont = Data("arial-regular".utf8)
        let boldFont = Data("arial-bold".utf8)
        let italicFont = Data("arial-italic".utf8)
        try regularFont.write(to: windowsFonts.appendingPathComponent("ARIAL.TTF"))
        try boldFont.write(to: windowsFonts.appendingPathComponent("ARIALBD.TTF"))
        try italicFont.write(to: windowsFonts.appendingPathComponent("ARIALI.TTF"))

        let result = try runner.run(WineRunRequest(
            exe: "C:\\macwin-portable\\jabref-portable\\JabRef\\JabRef.exe",
            bottle: bottle,
            engine: engine
        ))

        #expect(result.exitCode == 0)
        let log = try String(contentsOf: result.logURL, encoding: .utf8)
        #expect(log.contains("workingDirectory=\(applicationDirectory.path)"))
        #expect(log.contains("env.MACWIN_COMPAT_PROFILE=jabref-javafx-d3d"))
        #expect(log.contains("env.MACWIN_JABREF_JAVAFX_REPAIR=1"))
        #expect(log.contains("env.WINE_D3D_CONFIG=renderer=vulkan,csmt=0x0"))
        #expect(log.contains("env.JAVA_TOOL_OPTIONS="))
        #expect(log.contains("-Dprism.order=d3d"))
        #expect(!log.contains("-Dprism.order=sw"))
        #expect(try Data(contentsOf: runtimeLibrary.appendingPathComponent("fontconfig.properties"))
            == Data("fontconfig-source".utf8))
        #expect(try Data(contentsOf: runtimeLibrary.appendingPathComponent("fontsLucidaSansRegular.ttf"))
            == regularFont)
        #expect(try Data(contentsOf: runtimeLibrary.appendingPathComponent("fontsLucidaSansDemiBold.ttf"))
            == boldFont)
        #expect(try Data(contentsOf: runtimeLibrary.appendingPathComponent("fontsLucidaSansRegularItalic.ttf"))
            == italicFont)
        #expect(!FileManager.default.fileExists(atPath: runtimeLibrary.appendingPathComponent("fontconfig.bfc").path))
    }

    @Test("ONLYOFFICE launch repairs the renderer font cache path")
    func onlyOfficeLaunchRepairsRendererFontCachePath() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerOnlyOfficeTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "onlyoffice",
            name: "ONLYOFFICE",
            windowsVersion: "win11",
            arch: .win64,
            engineId: engine.id
        )
        let source = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent(
                "users/tester/AppData/Local/ONLYOFFICE/DesktopEditors/data/fonts/AllFonts.js"
            )
        let target = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent(
                "Program Files/ONLYOFFICE/DesktopEditors/editors/sdkjs/common/AllFonts.js"
            )
        let fontCache = Data("window[\"__fonts_files\"] = [\"macwin-font\"];\n".utf8)
        try FileManager.default.createDirectory(
            at: source.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: target.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try fontCache.write(to: source)
        try Data("stale".utf8).write(to: target)

        let result = try runner.run(WineRunRequest(
            exe: "C:\\Program Files\\ONLYOFFICE\\DesktopEditors\\DesktopEditors.exe",
            bottle: bottle,
            engine: engine,
            envOverrides: ["MACWIN_ONLYOFFICE_RENDERER_FONT_REPAIR": "1"]
        ))

        #expect(result.exitCode == 0)
        #expect(try Data(contentsOf: target) == fontCache)
        let log = try String(contentsOf: result.logURL, encoding: .utf8)
        #expect(log.contains("env.MACWIN_ONLYOFFICE_RENDERER_FONT_REPAIR=1"))
    }

    @Test("ONLYOFFICE launch waits briefly for its first-run font cache")
    func onlyOfficeLaunchWaitsForFirstRunFontCache() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerOnlyOfficeRaceTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "onlyoffice-race",
            name: "ONLYOFFICE",
            windowsVersion: "win11",
            arch: .win64,
            engineId: engine.id
        )
        let source = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent(
                "users/tester/AppData/Local/ONLYOFFICE/DesktopEditors/data/fonts/AllFonts.js"
            )
        let target = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent(
                "Program Files/ONLYOFFICE/DesktopEditors/editors/sdkjs/common/AllFonts.js"
            )
        let fontCache = Data("window[\"__fonts_files\"] = [\"first-run-font\"];\n".utf8)
        try FileManager.default.createDirectory(
            at: target.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let sourceWritten = DispatchSemaphore(value: 0)
        let writer = Thread {
            defer { sourceWritten.signal() }
            Thread.sleep(forTimeInterval: 0.25)
            try? FileManager.default.createDirectory(
                at: source.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? fontCache.write(to: source, options: .atomic)
        }
        writer.start()

        let result = try runner.run(WineRunRequest(
            exe: "C:\\Program Files\\ONLYOFFICE\\DesktopEditors\\DesktopEditors.exe",
            bottle: bottle,
            engine: engine,
            envOverrides: ["MACWIN_ONLYOFFICE_RENDERER_FONT_REPAIR": "1"]
        ))

        #expect(sourceWritten.wait(timeout: .now() + 1) == .success)
        #expect(result.exitCode == 0)
        #expect(try Data(contentsOf: target) == fontCache)
    }

    @Test("FreeCAD executable fallback selects OpenGL and repairs embedded Python")
    func freeCADExecutableFallbackSelectsOpenGLAndRepairsEmbeddedPython() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerFreeCADProfileTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "freecad",
            name: "FreeCAD",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        let applicationDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files/FreeCAD 1.1", isDirectory: true)
        let pythonLibrary = applicationDirectory.appendingPathComponent("bin/Lib", isDirectory: true)
        try FileManager.default.createDirectory(at: pythonLibrary, withIntermediateDirectories: true)
        try Data("platform".utf8).write(to: pythonLibrary.appendingPathComponent("platform.py"))

        let result = try runner.run(WineRunRequest(
            exe: "C:\\\\Program Files\\\\FreeCAD 1.1\\\\bin\\\\FreeCAD.exe",
            bottle: bottle,
            engine: engine
        ))

        #expect(result.exitCode == 0)
        let log = try String(contentsOf: result.logURL, encoding: .utf8)
        #expect(log.contains("workingDirectory=\(applicationDirectory.appendingPathComponent("bin").path)"))
        #expect(log.contains("env.MACWIN_COMPAT_PROFILE=freecad-opengl"))
        #expect(log.contains("env.MACWIN_FREECAD_PYTHON_REPAIR=1"))
        #expect(log.contains("env.QT_OPENGL=desktop"))
        #expect(log.contains("env.WINE_D3D_CONFIG=renderer=gl,csmt=0x0"))
        #expect(
            try String(contentsOf: pythonLibrary.appendingPathComponent("sitecustomize.py"), encoding: .utf8)
                == BottleService.freeCADPythonUnameShimText
        )
    }

    @Test("KiCad executable fallback selects CJK and OpenGL profile")
    func kiCadExecutableFallbackSelectsCJKAndOpenGLProfile() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerKiCadProfileTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "kicad",
            name: "KiCad",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        let binDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files/KiCad/10.0/bin", isDirectory: true)
        try FileManager.default.createDirectory(at: binDirectory, withIntermediateDirectories: true)
        try Data().write(to: binDirectory.appendingPathComponent("kicad.exe"))

        let result = try runner.run(WineRunRequest(
            exe: "C:\\\\Program Files\\\\KiCad\\\\10.0\\\\bin\\\\kicad.exe",
            bottle: bottle,
            engine: engine
        ))

        #expect(result.exitCode == 0)
        let log = try String(contentsOf: result.logURL, encoding: .utf8)
        #expect(log.contains("workingDirectory=\(binDirectory.path)"))
        #expect(log.contains("env.MACWIN_COMPAT_PROFILE=kicad-eda"))
        #expect(log.contains("env.MACWIN_FONTCONFIG_REPAIR=1"))
        #expect(log.contains("env.MACWIN_FONT_FALLBACK_REPAIR=1"))
        #expect(log.contains("env.MACWIN_TEXT_RENDERING_REPAIR=1"))
        #expect(log.contains("env.WINE_D3D_CONFIG=renderer=gl,csmt=0x0"))
    }

    @Test("LibreCAD executable fallback applies CJK Qt profile and first-run repair")
    func libreCADExecutableFallbackAppliesCJKQtProfileAndFirstRunRepair() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerLibreCADProfileTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "librecad",
            name: "LibreCAD",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        let applicationDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files/LibreCAD", isDirectory: true)
        try FileManager.default.createDirectory(at: applicationDirectory, withIntermediateDirectories: true)
        try Data().write(to: applicationDirectory.appendingPathComponent("LibreCAD.exe"))

        let result = try runner.run(WineRunRequest(
            exe: "C:\\\\Program Files\\\\LibreCAD\\\\LibreCAD.exe",
            bottle: bottle,
            engine: engine
        ))

        #expect(result.exitCode == 0)
        let log = try String(contentsOf: result.logURL, encoding: .utf8)
        #expect(log.contains("workingDirectory=\(applicationDirectory.path)"))
        #expect(log.contains("env.MACWIN_COMPAT_PROFILE=librecad-qt"))
        #expect(log.contains("env.MACWIN_LIBRECAD_PROFILE_REPAIR=1"))
        #expect(log.contains("env.MACWIN_FONTCONFIG_REPAIR=1"))
        #expect(log.contains("env.MACWIN_TEXT_RENDERING_REPAIR=1"))
        #expect(log.contains("env.QT_OPENGL=desktop"))
        #expect(log.contains("env.WINE_D3D_CONFIG=renderer=gl,csmt=0x0"))
    }

    @Test("OpenSCAD executable fallback deploys cached software OpenGL")
    func openSCADExecutableFallbackDeploysCachedSoftwareOpenGL() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerOpenSCADProfileTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "openscad",
            name: "OpenSCAD",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        let applicationDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files/OpenSCAD", isDirectory: true)
        try FileManager.default.createDirectory(at: applicationDirectory, withIntermediateDirectories: true)
        try Data().write(to: applicationDirectory.appendingPathComponent("openscad.exe"))
        let cachedMesa = paths.downloadsDirectory
            .appendingPathComponent(".bambu-studio-runtime/mesa/opengl32.dll")
        try FileManager.default.createDirectory(
            at: cachedMesa.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let mesaData = Data("mesa-software-opengl".utf8)
        try mesaData.write(to: cachedMesa)

        let result = try runner.run(WineRunRequest(
            exe: "C:\\\\Program Files\\\\OpenSCAD\\\\openscad.exe",
            bottle: bottle,
            engine: engine
        ))

        #expect(result.exitCode == 0)
        #expect(try Data(contentsOf: applicationDirectory.appendingPathComponent("opengl32.dll")) == mesaData)
        let log = try String(contentsOf: result.logURL, encoding: .utf8)
        #expect(log.contains("workingDirectory=\(applicationDirectory.path)"))
        #expect(log.contains("env.MACWIN_COMPAT_PROFILE=openscad-software-opengl"))
        #expect(log.contains("env.MACWIN_OPENSCAD_SOFTWARE_OPENGL_REPAIR=1"))
        #expect(log.contains("env.LIBGL_ALWAYS_SOFTWARE=1"))
        #expect(log.contains("env.QT_OPENGL=software"))
        #expect(log.contains("env.WINE_D3D_CONFIG=renderer=gl,csmt=0x0"))
    }

    @Test("Blender executable fallback deploys the complete Mesa WGL runtime")
    func blenderExecutableFallbackDeploysMesaWGLRuntime() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerBlenderProfileTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "blender",
            name: "Blender",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        let applicationDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent(
                "Program Files/Blender Foundation/Blender 4.1",
                isDirectory: true
            )
        try FileManager.default.createDirectory(at: applicationDirectory, withIntermediateDirectories: true)
        try Data().write(to: applicationDirectory.appendingPathComponent("blender.exe"))

        let mesaDirectory = paths.downloadsDirectory
            .appendingPathComponent(".mesa3d-26.1.2-msvc/x64", isDirectory: true)
        try FileManager.default.createDirectory(at: mesaDirectory, withIntermediateDirectories: true)
        let runtimeNames = ["opengl32.dll", "libgallium_wgl.dll", "dxil.dll"]
        for runtimeName in runtimeNames {
            try Data("blender-\(runtimeName)".utf8)
                .write(to: mesaDirectory.appendingPathComponent(runtimeName))
        }

        let result = try runner.run(WineRunRequest(
            exe: "C:\\\\Program Files\\\\Blender Foundation\\\\Blender 4.1\\\\blender.exe",
            bottle: bottle,
            engine: engine
        ))

        #expect(result.exitCode == 0)
        for runtimeName in runtimeNames {
            #expect(
                try Data(contentsOf: applicationDirectory.appendingPathComponent(runtimeName))
                    == Data("blender-\(runtimeName)".utf8)
            )
        }
        let log = try String(contentsOf: result.logURL, encoding: .utf8)
        #expect(log.contains("workingDirectory=\(applicationDirectory.path)"))
        #expect(log.contains("env.MACWIN_COMPAT_PROFILE=blender-software-opengl"))
        #expect(log.contains("env.MACWIN_BLENDER_SOFTWARE_OPENGL_REPAIR=1"))
        #expect(log.contains("env.GALLIUM_DRIVER=llvmpipe"))
        #expect(log.contains("env.MESA_LOADER_DRIVER_OVERRIDE=llvmpipe"))
        #expect(log.contains("env.LIBGL_ALWAYS_SOFTWARE=1"))
        #expect(log.contains("env.WINE_D3D_CONFIG=renderer=gl,csmt=0x0"))
        #expect(log.contains("env.WINEDLLOVERRIDES=opengl32=n,b;winemenubuilder.exe=d"))
    }

    @Test("Sweet Home 3D executable fallback disables 32-bit Java3D extensions and selects OpenGL")
    func sweetHome3DExecutableFallbackUses64BitOpenGL() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerSweetHome3DProfileTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "sweethome3d",
            name: "Sweet Home 3D",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        let applicationDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files/Sweet Home 3D", isDirectory: true)
        let extensionDirectory = applicationDirectory
            .appendingPathComponent("runtime/lib/ext", isDirectory: true)
        let runtimeLibrary = applicationDirectory
            .appendingPathComponent("runtime/lib", isDirectory: true)
        let windowsFonts = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("windows/Fonts", isDirectory: true)
        try FileManager.default.createDirectory(at: extensionDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: windowsFonts, withIntermediateDirectories: true)
        try Data().write(to: applicationDirectory.appendingPathComponent("SweetHome3D.exe"))
        try Data("x86-java3d".utf8).write(
            to: extensionDirectory.appendingPathComponent("j3dcore-d3d.dll")
        )
        let fontConfiguration = """
        version=1
        allfonts.chinese-ms936=SimSun
        allfonts.chinese-ms936-extb=SimSun-ExtB
        allfonts.chinese-gb18030=SimSun-18030
        allfonts.chinese-gb18030-extb=SimSun-ExtB
        sequence.allfonts=alphabetic/default,dingbats,symbol
        dialog.plain.alphabetic=Arial
        dialog.bold.alphabetic=Arial Bold
        dialog.italic.alphabetic=Arial Italic
        dialog.bolditalic.alphabetic=Arial Bold Italic
        dialoginput.plain.alphabetic=Arial
        dialoginput.bold.alphabetic=Arial Bold
        dialoginput.italic.alphabetic=Arial Italic
        dialoginput.bolditalic.alphabetic=Arial Bold Italic
        sansserif.plain.alphabetic=Arial
        sansserif.bold.alphabetic=Arial Bold
        sansserif.italic.alphabetic=Arial Italic
        sansserif.bolditalic.alphabetic=Arial Bold Italic
        filename.SimSun=SIMSUN.TTC
        """
        try fontConfiguration.write(
            to: runtimeLibrary.appendingPathComponent("fontconfig.properties.src"),
            atomically: true,
            encoding: .utf8
        )
        try Data("stale-java-font-cache".utf8).write(
            to: runtimeLibrary.appendingPathComponent("fontconfig.bfc")
        )
        try FileManager.default.createSymbolicLink(
            at: windowsFonts.appendingPathComponent("SIMSUN.TTC"),
            withDestinationURL: URL(fileURLWithPath: "/System/Library/Fonts/Hiragino Sans GB.ttc")
        )

        let result = try runner.run(WineRunRequest(
            exe: "C:\\\\Program Files\\\\Sweet Home 3D\\\\SweetHome3D.exe",
            bottle: bottle,
            engine: engine
        ))

        #expect(result.exitCode == 0)
        #expect(!FileManager.default.fileExists(atPath: extensionDirectory.path))
        #expect(FileManager.default.fileExists(
            atPath: applicationDirectory
                .appendingPathComponent("runtime/lib/ext.macwin-disabled/j3dcore-d3d.dll")
                .path
        ))
        let repairedFontConfiguration = try String(
            contentsOf: runtimeLibrary.appendingPathComponent("fontconfig.properties"),
            encoding: .utf8
        )
        #expect(repairedFontConfiguration.contains(
            "allfonts.chinese-ms936=Hiragino Sans GB W3"
        ))
        #expect(repairedFontConfiguration.contains(
            "dialog.plain.alphabetic=Hiragino Sans GB W3"
        ))
        #expect(repairedFontConfiguration.contains(
            "dialog.bold.alphabetic=Hiragino Sans GB W6"
        ))
        #expect(repairedFontConfiguration.contains(
            "sequence.allfonts=alphabetic/default,chinese-ms936,dingbats,symbol,chinese-ms936-extb"
        ))
        #expect(repairedFontConfiguration.contains(
            "filename.Hiragino_Sans_GB_W3=SIMSUN.TTC"
        ))
        #expect(repairedFontConfiguration.contains(
            "filename.Hiragino_Sans_GB_W6=SIMSUN.TTC"
        ))
        #expect(!FileManager.default.fileExists(
            atPath: runtimeLibrary.appendingPathComponent("fontconfig.bfc").path
        ))
        let log = try String(contentsOf: result.logURL, encoding: .utf8)
        #expect(log.contains("workingDirectory=\(applicationDirectory.path)"))
        #expect(log.contains("env.MACWIN_COMPAT_PROFILE=sweethome3d-opengl"))
        #expect(log.contains("env.MACWIN_SWEETHOME3D_OPENGL_REPAIR=1"))
        #expect(log.contains("env._JAVA_OPTIONS=-Dj3d.rend=ogl -Dsun.java2d.d3d=false -Dsun.java2d.opengl=true"))
        #expect(log.contains("env.WINE_D3D_CONFIG=renderer=gl,csmt=0x0"))
    }

    @Test("Java CJK font configuration repair is complete and idempotent")
    func javaCJKFontConfigurationRepairIsIdempotent() {
        let source = """
        version=1
        allfonts.chinese-ms936=SimSun
        allfonts.chinese-ms936-extb=SimSun-ExtB
        allfonts.chinese-gb18030=SimSun-18030
        allfonts.chinese-gb18030-extb=SimSun-ExtB
        sequence.allfonts=alphabetic/default,dingbats,symbol
        dialog.plain.alphabetic=Arial
        dialog.bold.alphabetic=Arial Bold
        dialog.italic.alphabetic=Arial Italic
        dialog.bolditalic.alphabetic=Arial Bold Italic
        dialoginput.plain.alphabetic=Arial
        dialoginput.bold.alphabetic=Arial Bold
        dialoginput.italic.alphabetic=Arial Italic
        dialoginput.bolditalic.alphabetic=Arial Bold Italic
        sansserif.plain.alphabetic=Arial
        sansserif.bold.alphabetic=Arial Bold
        sansserif.italic.alphabetic=Arial Italic
        sansserif.bolditalic.alphabetic=Arial Bold Italic
        filename.SimSun=SIMSUN.TTC
        """
        let repaired = WineRunner.javaCJKFontConfigurationText(
            source,
            regularFontName: "Hiragino Sans GB W3",
            boldFontName: "Hiragino Sans GB W6",
            fontFileName: "SIMSUN.TTC"
        )

        #expect(repaired.contains("allfonts.chinese-ms936-extb=Hiragino Sans GB W3"))
        #expect(repaired.contains("allfonts.chinese-gb18030-extb=Hiragino Sans GB W3"))
        #expect(repaired.contains("dialog.italic.alphabetic=Hiragino Sans GB W3"))
        #expect(repaired.contains("sansserif.bolditalic.alphabetic=Hiragino Sans GB W6"))
        #expect(repaired.contains(
            "sequence.allfonts=alphabetic/default,chinese-ms936,dingbats,symbol,chinese-ms936-extb"
        ))
        #expect(repaired.components(separatedBy: "filename.Hiragino_Sans_GB_W3").count == 2)
        #expect(repaired.components(separatedBy: "filename.Hiragino_Sans_GB_W6").count == 2)
        #expect(WineRunner.javaCJKFontConfigurationText(
            repaired,
            regularFontName: "Hiragino Sans GB W3",
            boldFontName: "Hiragino Sans GB W6",
            fontFileName: "SIMSUN.TTC"
        ) == repaired)
    }

    @Test("Supermium 32-bit executable fallback keeps portable WOW64 launch shape")
    func supermium32ExecutableFallbackKeepsPortableWOW64LaunchShape() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerSupermium32ProfileTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "supermium32",
            name: "Supermium 32",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        let appDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("macwin-portable/supermium-32-browser/Supermium", isDirectory: true)
        try FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)

        let result = try runner.run(WineRunRequest(
            exe: "C:\\macwin-portable\\supermium-32-browser\\Supermium\\chrome.exe",
            bottle: bottle,
            engine: engine
        ))

        #expect(result.exitCode == 0)
        #expect(result.commandLine.contains("--user-data-dir=portable_data32-macwin"))
        #expect(result.commandLine.contains("--new-window"))
        #expect(result.commandLine.contains("--use-angle=swiftshader"))
        #expect(result.commandLine.contains("about:blank"))
        let log = try String(contentsOf: result.logURL, encoding: .utf8)
        #expect(log.contains("workingDirectory=\(appDirectory.path)"))
        #expect(log.contains("env.MACWIN_COMPAT_PROFILE=supermium-32-browser"))
        #expect(log.contains("env.MACWIN_DISABLE_WINE_D3D_CONFIG=1"))
        #expect(log.contains("env.MACWIN_WOW64_BROWSER_REPAIR=1"))
        #expect(!log.contains("env.WINE_D3D_CONFIG="))
    }

    @Test("MeshLab executable fallback deploys bundled software OpenGL")
    func meshLabExecutableFallbackDeploysBundledSoftwareOpenGL() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerMeshLabProfileTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/bin/echo",
            wineserverPath: "/bin/echo",
            runtimePath: "/runtime",
            defaultEnv: ["ROSETTA_X87_PATH": "/tmp/rosettax87"]
        )
        let bottle = BottleManifest(
            id: "meshlab",
            name: "MeshLab",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        let appDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files/MeshLab", isDirectory: true)
        try FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        try Data("exe".utf8).write(to: appDirectory.appendingPathComponent("meshlab.exe"))
        let softwareOpenGL = Data("meshlab-software-opengl".utf8)
        try softwareOpenGL.write(to: appDirectory.appendingPathComponent("opengl32sw.dll"))

        let result = try runner.run(WineRunRequest(
            exe: "C:\\Program Files\\MeshLab\\meshlab.exe",
            bottle: bottle,
            engine: engine
        ))

        #expect(result.exitCode == 0)
        #expect(try Data(contentsOf: appDirectory.appendingPathComponent("opengl32.dll")) == softwareOpenGL)
        let log = try String(contentsOf: result.logURL, encoding: .utf8)
        #expect(log.contains("workingDirectory=\(appDirectory.path)"))
        #expect(log.contains("env.MACWIN_COMPAT_PROFILE=meshlab-software-opengl"))
        #expect(log.contains("env.MACWIN_MESHLAB_SOFTWARE_OPENGL_REPAIR=1"))
        #expect(log.contains("env.LIBGL_ALWAYS_SOFTWARE=1"))
        #expect(log.contains("env.QT_OPENGL=software"))
        #expect(log.contains("env.WINEDLLOVERRIDES=opengl32=n;winemenubuilder.exe=d"))
        #expect(log.contains("env.ROSETTA_X87_PATH="))
    }

    @Test("Bambu Studio executable fallback deploys Mesa and VS runtime locally")
    func bambuStudioExecutableFallbackDeploysRuntime() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerBambuStudioProfileTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "bambu",
            name: "Bambu Studio",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        let appDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("macwin-portable/bambu-studio-portable", isDirectory: true)
        try FileManager.default.createDirectory(
            at: appDirectory.appendingPathComponent("mesa", isDirectory: true),
            withIntermediateDirectories: true
        )
        try Data("exe".utf8).write(to: appDirectory.appendingPathComponent("bambu-studio.exe"))
        let mesa = Data("bambu-mesa-opengl".utf8)
        try mesa.write(to: appDirectory.appendingPathComponent("mesa/opengl32.dll"))

        let runtimeDirectory = paths.downloadsDirectory
            .appendingPathComponent("vc_redist.x64.vs17.runtime-amd64", isDirectory: true)
        try FileManager.default.createDirectory(at: runtimeDirectory, withIntermediateDirectories: true)
        let runtimeNames = [
            "concrt140.dll",
            "msvcp140.dll",
            "msvcp140_1.dll",
            "msvcp140_2.dll",
            "msvcp140_atomic_wait.dll",
            "msvcp140_codecvt_ids.dll",
            "vcruntime140.dll",
            "vcruntime140_1.dll"
        ]
        for runtimeName in runtimeNames {
            try Data(runtimeName.utf8).write(
                to: runtimeDirectory.appendingPathComponent("\(runtimeName)_amd64")
            )
        }

        let result = try runner.run(WineRunRequest(
            exe: "C:\\macwin-portable\\bambu-studio-portable\\bambu-studio.exe",
            bottle: bottle,
            engine: engine
        ))

        #expect(result.exitCode == 0)
        #expect(try Data(contentsOf: appDirectory.appendingPathComponent("opengl32.dll")) == mesa)
        for runtimeName in runtimeNames {
            #expect(FileManager.default.fileExists(
                atPath: appDirectory.appendingPathComponent(runtimeName).path
            ))
        }
        let log = try String(contentsOf: result.logURL, encoding: .utf8)
        #expect(log.contains("env.MACWIN_COMPAT_PROFILE=bambu-studio-software-opengl"))
        #expect(log.contains("env.MACWIN_BAMBU_STUDIO_RUNTIME_REPAIR=1"))
        #expect(log.contains("env.GALLIUM_DRIVER=llvmpipe"))
        #expect(log.contains("env.MESA_GL_VERSION_OVERRIDE=4.5COMPAT"))
        #expect(log.contains("env.WINEDLLOVERRIDES=opengl32,msvcp140"))
    }

    @Test("Bambu Studio 3MF patch is byte guarded and idempotent")
    func bambuStudioExport3MFPatchIsByteGuarded() {
        let offset = WineRunner.bambuStudioExport3MFPatchOffset
        var original = Data(repeating: 0x7a, count: offset)
        original.append(contentsOf: WineRunner.bambuStudioExport3MFOriginalBytes)
        original.append(contentsOf: [0x11, 0x22, 0x33])

        var patched = original
        #expect(WineRunner.applyBambuStudioExport3MFPatch(to: &patched))
        #expect(Array(
            patched[offset..<(offset + WineRunner.bambuStudioExport3MFPatchBytes.count)]
        ) == WineRunner.bambuStudioExport3MFPatchBytes)
        #expect(!WineRunner.applyBambuStudioExport3MFPatch(to: &patched))

        var mismatched = original
        mismatched[offset] = 0xff
        #expect(!WineRunner.applyBambuStudioExport3MFPatch(to: &mismatched))
        #expect(mismatched[offset] == 0xff)
    }

    @Test("OrcaSlicer startup patch is byte guarded and idempotent")
    func orcaSlicerStartupPatchIsByteGuarded() {
        let size = WineRunner.orcaSlicerStartupPatches
            .map { $0.offset + $0.original.count }
            .max() ?? 0
        var original = Data(repeating: 0x7a, count: size + 3)
        for patch in WineRunner.orcaSlicerStartupPatches {
            original.replaceSubrange(
                patch.offset..<(patch.offset + patch.original.count),
                with: patch.original
            )
        }

        var patched = original
        #expect(WineRunner.applyOrcaSlicerStartupPatch(to: &patched))
        for patch in WineRunner.orcaSlicerStartupPatches {
            #expect(Array(
                patched[patch.offset..<(patch.offset + patch.replacement.count)]
            ) == patch.replacement)
        }
        #expect(!WineRunner.applyOrcaSlicerStartupPatch(to: &patched))

        var mismatched = original
        let firstOffset = WineRunner.orcaSlicerStartupPatches[0].offset
        mismatched[firstOffset] = 0xff
        #expect(!WineRunner.applyOrcaSlicerStartupPatch(to: &mismatched))
        #expect(mismatched[firstOffset] == 0xff)
    }

    @Test("Zotero executable fallback creates Gecko profile and disables Vulkan renderer")
    func zoteroExecutableFallbackCreatesGeckoProfileAndDisablesVulkanRenderer() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerZoteroGecko32ProfileTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "zotero",
            name: "Zotero",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )

        let result = try runner.run(WineRunRequest(
            exe: "C:\\Program Files (x86)\\Zotero\\zotero.exe",
            bottle: bottle,
            engine: engine
        ))

        #expect(result.exitCode == 0)
        #expect(result.commandLine.contains("-no-remote"))
        #expect(result.commandLine.contains("-profile"))
        #expect(result.commandLine.contains("C:\\macwin-portable\\zotero-profile"))
        let log = try String(contentsOf: result.logURL, encoding: .utf8)
        #expect(log.contains("env.MACWIN_COMPAT_PROFILE=zotero-gecko32"))
        #expect(log.contains("env.MACWIN_ZOTERO_GECKO32_REPAIR=1"))
        #expect(log.contains("env.MACWIN_GECKO_PROFILE_REPAIR=1"))
        #expect(log.contains("env.MOZ_WEBRENDER=0"))
        #expect(log.contains("env.MOZ_DISABLE_CONTENT_SANDBOX=1"))
        #expect(!log.contains("env.WINE_D3D_CONFIG="))

        let userJS = try String(
            contentsOf: paths.bottleDriveCURL(id: bottle.id)
                .appendingPathComponent("macwin-portable/zotero-profile/user.js"),
            encoding: .utf8
        )
        #expect(userJS.contains(#"user_pref("browser.tabs.remote.autostart", false);"#))
        #expect(userJS.contains(#"user_pref("gfx.webrender.force-disabled", true);"#))
        #expect(userJS.contains(#"user_pref("security.sandbox.content.level", 0);"#))
    }

    @Test("mRemoteNG executable fallback deploys cached .NET runtime and removes generated settings")
    func mRemoteNGExecutableFallbackDeploysCachedDotNetRuntimeAndRemovesGeneratedSettings() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerMRemoteNGProfileTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "mremoteng",
            name: "mRemoteNG",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        let appDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("macwin-portable/mremoteng-1782-x64", isDirectory: true)
        try FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        try """
        <?xml version="1.0" encoding="utf-8"?>
        <settings>
          <localSettings>
            <setting name="CheckForUpdatesLastCheck">2099-01-01</setting>
            <setting name="UpdateProxyAddress"></setting>
          </localSettings>
          <globalSettings />
        </settings>
        """.write(
            to: appDirectory.appendingPathComponent("mRemoteNG.settings"),
            atomically: true,
            encoding: .utf8
        )
        let runtimeDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("macwin-runtimes/dotnet-desktop-10-x64", isDirectory: true)
        try FileManager.default.createDirectory(
            at: runtimeDirectory.appendingPathComponent("shared/Microsoft.NETCore.App/10.0.9", isDirectory: true),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: runtimeDirectory.appendingPathComponent("shared/Microsoft.WindowsDesktop.App/10.0.9", isDirectory: true),
            withIntermediateDirectories: true
        )
        try Data().write(to: runtimeDirectory.appendingPathComponent("dotnet.exe"))
        try Data().write(to: runtimeDirectory.appendingPathComponent("shared/Microsoft.NETCore.App/10.0.9/Microsoft.NETCore.App.deps.json"))
        try Data().write(to: runtimeDirectory.appendingPathComponent("shared/Microsoft.WindowsDesktop.App/10.0.9/Microsoft.WindowsDesktop.App.deps.json"))

        let result = try runner.run(WineRunRequest(
            exe: "C:\\macwin-portable\\mremoteng-1782-x64\\mRemoteNG.exe",
            bottle: bottle,
            engine: engine
        ))

        #expect(result.exitCode == 0)
        #expect(result.commandLine.contains("/reset"))
        #expect(result.commandLine.contains("/noreconnect"))
        let log = try String(contentsOf: result.logURL, encoding: .utf8)
        #expect(log.contains("workingDirectory=\(appDirectory.path)"))
        #expect(log.contains("env.MACWIN_COMPAT_PROFILE=mremoteng-1782-x64"))
        #expect(log.contains("env.MACWIN_DOTNET_DESKTOP10_RUNTIME_REPAIR=1"))
        #expect(log.contains("env.MACWIN_MREMOTENG_REPAIR=1"))
        #expect(log.contains("env.MACWIN_DISABLE_WINE_APP_ACTIVATION=1"))
        #expect(log.contains("env.DOTNET_ROOT=C:\\macwin-runtimes\\dotnet-desktop-10-x64"))
        #expect(log.contains("env.DOTNET_ROOT_X64=C:\\macwin-runtimes\\dotnet-desktop-10-x64"))
        #expect(log.contains("env.PATH=C:\\macwin-runtimes\\dotnet-desktop-10-x64;"))
        #expect(!FileManager.default.fileExists(atPath: appDirectory.appendingPathComponent("mRemoteNG.settings").path))
    }

    @Test("MuseScore first-run config updates existing values")
    func museScoreFirstRunConfigUpdatesExistingValues() {
        let original = """
        [application]
        hasCompletedFirstLaunchSetup=false

        [ui/application]
        currentThemeCode=dark
        """

        let repaired = WineRunner.museScoreFirstLaunchConfigText(original)

        #expect(repaired.contains("hasCompletedFirstLaunchSetup=true"))
        #expect(repaired.contains("welcomeDialogShowOnStartup=false"))
        #expect(repaired.contains("welcomeDialogLastShownVersion=999.999.999"))
        #expect(repaired.contains("welcomeDialogLastShownIndex=999"))
        #expect(repaired.contains("currentStartupMode=0"))
        #expect(repaired.contains("showWelcomeDialog=false"))
        #expect(repaired.contains(#"startup\modeStart=0"#))
        #expect(repaired.contains("[application/startup]"))
        #expect(repaired.contains("modeStart=0"))
        #expect(repaired.contains(#"application\currentThemeCode=light"#))
        #expect(repaired.contains("[ui/application]"))
        #expect(repaired.contains("currentThemeCode=light"))
        #expect(repaired.contains("[General]"))
        #expect(repaired.contains("application/hasCompletedFirstLaunchSetup=true"))
        #expect(repaired.contains("application/welcomeDialogShowOnStartup=false"))
        #expect(repaired.contains("[appshell/gettingstarted]"))
        #expect(repaired.contains("finished=true"))
        #expect(repaired.contains("[appshell/onboarding]"))
        #expect(repaired.contains("[gettingstarted]"))
        #expect(repaired.contains("[onboarding]"))
        #expect(repaired.contains("onboarding/finished=true"))
        #expect(repaired.contains("gettingstarted/finished=true"))
        #expect(repaired.contains(#"application\highContrastEnabled=false"#))
        #expect(repaired.contains(#"theme\fontFamily=Arial"#))
        #expect(!repaired.contains("hasCompletedFirstLaunchSetup=false"))
        #expect(!repaired.contains("currentThemeCode=dark"))
    }

    @Test("LTspice first-run config updates only analytics consent")
    func ltspiceFirstRunConfigUpdatesExistingValues() {
        let original = """
        [Options]
        CaptureAnalytics=true
        EngUnits=true

        [Colors]
        Background=0
        """

        let repaired = WineRunner.ltspiceFirstLaunchConfigText(original)

        #expect(repaired.contains("CaptureAnalytics=false"))
        #expect(!repaired.contains("CaptureAnalytics=true"))
        #expect(repaired.contains("EngUnits=true"))
        #expect(repaired.contains("[Colors]"))
        #expect(repaired.contains("Background=0"))
    }

    @Test("JASP startup config is stable and preserves unrelated settings")
    func jaspStartupConfigIsStableAndPreservesUnrelatedSettings() {
        let original = """
        [General]
        checkUpdates=true
        customSetting=keep
        """

        let repaired = WineRunner.jaspStartupConfigText(original)

        #expect(repaired.contains("safeGraphicsMode=true"))
        #expect(repaired.contains("engineSandbox=false"))
        #expect(repaired.contains("checkUpdates=false"))
        #expect(repaired.contains("checkUpdatesAskUser=false"))
        #expect(repaired.contains("remoteConfigurationURL=about:blank"))
        #expect(repaired.contains("instructionsShown=true"))
        #expect(repaired.contains("customSetting=keep"))
        #expect(WineRunner.jaspStartupConfigText(repaired) == repaired)
    }

    @Test("Cached executable patch requires matching source and patch hashes")
    func cachedExecutablePatchRequiresMatchingHashes() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerPatchTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let targetURL = root.appendingPathComponent("JASPDesktop.exe")
        let cacheURL = root.appendingPathComponent("patched.exe")
        let originalData = Data("known-original".utf8)
        let patchData = Data("verified-patch".utf8)
        try originalData.write(to: targetURL)
        try patchData.write(to: cacheURL)
        let originalHash = Hashing.sha256Hex(data: originalData)
        let patchHash = Hashing.sha256Hex(data: patchData)

        let applied = try WineRunner.deployCachedExecutablePatch(
            fileManager: .default,
            cacheURL: cacheURL,
            targetURL: targetURL,
            expectedPatchHash: patchHash,
            allowedTargetHashes: [originalHash]
        )

        #expect(applied)
        #expect(try Data(contentsOf: targetURL) == patchData)
        #expect(FileManager.default.fileExists(
            atPath: root.appendingPathComponent("JASPDesktop.exe.macwin-original-\(originalHash.prefix(8))").path
        ))
        #expect(try !WineRunner.deployCachedExecutablePatch(
            fileManager: .default,
            cacheURL: cacheURL,
            targetURL: targetURL,
            expectedPatchHash: patchHash,
            allowedTargetHashes: [originalHash]
        ))

        try Data("unknown-target".utf8).write(to: targetURL)
        #expect(try !WineRunner.deployCachedExecutablePatch(
            fileManager: .default,
            cacheURL: cacheURL,
            targetURL: targetURL,
            expectedPatchHash: patchHash,
            allowedTargetHashes: [originalHash]
        ))
        #expect(try Data(contentsOf: targetURL) == Data("unknown-target".utf8))
    }

    @Test("JASP managed patch accepts the original and prior managed build")
    func jaspManagedPatchSupportsUpgrade() {
        #expect(
            WineRunner.jaspManagedPatchHash
                == "be5aa4c652729a61b3205e19ce90e7ae12a7b4c16511ab54b8e417a7165d380e"
        )
        #expect(WineRunner.jaspManagedPatchSourceHashes == [
            "48ff096ac93c0cc10bbf5bd95ea9b809609b3609796777fe2c75c433eca700e4",
            "db5c6bf993cbe17abb8de5c35825caf8220bacbf9c411f7a2e702eaf0c8af136"
        ])
        #expect(!WineRunner.jaspManagedPatchSourceHashes.contains(WineRunner.jaspManagedPatchHash))
    }

    @Test("Chromium browser profile launches from version directory")
    func chromiumBrowserProfileLaunchesFromVersionDirectory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerChromiumCwdTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "browser-bottle",
            name: "Browser Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        let appDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("users/a/AppData/Local/BraveSoftware/Brave-Browser/Application", isDirectory: true)
        let versionDirectory = appDirectory.appendingPathComponent("149.1.91.175", isDirectory: true)
        try FileManager.default.createDirectory(at: versionDirectory, withIntermediateDirectories: true)
        try Data("exe".utf8).write(to: appDirectory.appendingPathComponent("brave.exe"))
        try Data("dll".utf8).write(to: versionDirectory.appendingPathComponent("chrome_elf.dll"))

        let result = try runner.run(WineRunRequest(
            exe: "C:\\users\\a\\AppData\\Local\\BraveSoftware\\Brave-Browser\\Application\\brave.exe",
            bottle: bottle,
            engine: engine,
            envOverrides: ApplicationCompatibilityProfile.chromiumBrowser.environment,
            logName: "chromium-cwd.log"
        ))
        let text = try String(contentsOf: result.logURL, encoding: .utf8)

        #expect(result.exitCode == 0)
        #expect(text.contains("workingDirectory="))
        #expect(text.contains("/Bottles/browser-bottle/drive_c/users/a/AppData/Local/BraveSoftware/Brave-Browser/Application/149.1.91.175"))
    }

    @Test("Vivaldi browser launches from version directory")
    func vivaldiBrowserLaunchesFromVersionDirectory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerVivaldiCwdTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "vivaldi-bottle",
            name: "Vivaldi Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        let appDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files/Vivaldi/Application", isDirectory: true)
        let versionDirectory = appDirectory.appendingPathComponent("7.9.3970.47", isDirectory: true)
        try FileManager.default.createDirectory(at: versionDirectory, withIntermediateDirectories: true)
        try Data("exe".utf8).write(to: appDirectory.appendingPathComponent("vivaldi.exe"))
        try Data("dll".utf8).write(to: versionDirectory.appendingPathComponent("vivaldi_elf.dll"))

        let result = try runner.run(WineRunRequest(
            exe: "C:\\Program Files\\Vivaldi\\Application\\vivaldi.exe",
            bottle: bottle,
            engine: engine,
            envOverrides: ApplicationCompatibilityProfile.chromiumBrowser.environment,
            logName: "vivaldi-cwd.log"
        ))
        let text = try String(contentsOf: result.logURL, encoding: .utf8)

        #expect(result.exitCode == 0)
        #expect(text.contains("workingDirectory="))
        #expect(text.contains("/Bottles/vivaldi-bottle/drive_c/Program Files/Vivaldi/Application/7.9.3970.47"))
    }

    @Test("Microsoft Edge launches from version directory")
    func edgeBrowserLaunchesFromVersionDirectory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerEdgeCwdTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "edge-bottle",
            name: "Edge Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        let appDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files (x86)/Microsoft/Edge/Application", isDirectory: true)
        let versionDirectory = appDirectory.appendingPathComponent("149.0.4022.80", isDirectory: true)
        try FileManager.default.createDirectory(at: versionDirectory, withIntermediateDirectories: true)
        try Data("exe".utf8).write(to: appDirectory.appendingPathComponent("msedge.exe"))
        try Data("dll".utf8).write(to: versionDirectory.appendingPathComponent("msedge_elf.dll"))

        let result = try runner.run(WineRunRequest(
            exe: "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
            bottle: bottle,
            engine: engine,
            envOverrides: ApplicationCompatibilityProfile.chromiumBrowser.environment,
            logName: "edge-cwd.log"
        ))
        let text = try String(contentsOf: result.logURL, encoding: .utf8)

        #expect(result.exitCode == 0)
        #expect(text.contains("workingDirectory="))
        #expect(text.contains("/Bottles/edge-bottle/drive_c/Program Files (x86)/Microsoft/Edge/Application/149.0.4022.80"))
    }

    @Test("Run log includes launch context and result footer")
    func runLogIncludesLaunchContextAndResultFooter() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerLogTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "log-bottle",
            name: "Log Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )

        let result = try runner.run(WineRunRequest(
            exe: "hello.exe",
            args: ["--flag"],
            bottle: bottle,
            engine: engine,
            envOverrides: ["MACWIN_COMPAT_PROFILE": "test-profile"],
            logName: "context.log"
        ))
        let text = try String(contentsOf: result.logURL, encoding: .utf8)

        #expect(text.contains("----- MacWin launch -----"))
        #expect(text.contains("bottleId=log-bottle"))
        #expect(text.contains("engineId=engine"))
        #expect(text.contains("command=/usr/bin/arch -x86_64 /bin/echo hello.exe --flag"))
        #expect(text.contains("env.WINE_D3D_CONFIG=renderer=vulkan,csmt=0x0"))
        #expect(text.contains("env.MACWIN_COMPAT_PROFILE=test-profile"))
        #expect(text.contains("----- MacWin result -----"))
        #expect(text.contains("exitCode=0"))

        let launchHistory = LaunchHistoryService(paths: paths).report()
        let record = try #require(launchHistory.records.first)
        #expect(record.mode == .foregroundRun)
        #expect(record.state == .completed)
        #expect(record.logPath == result.logURL.path)
        #expect(record.bottleId == "log-bottle")
        #expect(record.engineId == "engine")
        #expect(record.exe == "hello.exe")
        #expect(record.args == ["--flag"])
        #expect(record.exitCode == 0)
        #expect(record.environment["WINE_D3D_CONFIG"] == "renderer=vulkan,csmt=0x0")
        #expect(record.environment["MACWIN_COMPAT_PROFILE"] == "test-profile")
        #expect(record.durationMilliseconds != nil)
    }

    @Test("Smoke launch records early process exit")
    func smokeLaunchRecordsEarlyProcessExit() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerSmokeExitTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(id: "smoke-exit", name: "Smoke Exit", windowsVersion: "win11", arch: .win64, engineId: "engine")
        let result = try runner.smokeLaunch(WineRunRequest(
            exe: "hello",
            bottle: bottle,
            engine: engine,
            logName: "smoke-exit.log"
        ), timeoutSeconds: 1)

        #expect(!result.timedOut)
        #expect(result.exitCode == 0)
        let log = try String(contentsOf: result.logURL, encoding: .utf8)
        #expect(log.contains("exe=hello"))
        #expect(log.contains("runtimePreflightCleanupRequested=0"))
        #expect(log.contains("exitCode=0"))
    }

    @Test("Smoke launch treats timeout as kept alive")
    func smokeLaunchTreatsTimeoutAsKeptAlive() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerSmokeTimeoutTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/bin/sleep",
            wineserverPath: "/bin/echo",
            runtimePath: "/runtime",
            defaultEnv: [:]
        )
        let bottle = BottleManifest(id: "smoke-timeout", name: "Smoke Timeout", windowsVersion: "win11", arch: .win64, engineId: "engine")
        let result = try runner.smokeLaunch(WineRunRequest(
            exe: "2",
            bottle: bottle,
            engine: engine,
            logName: "smoke-timeout.log"
        ), timeoutSeconds: 1)

        #expect(result.timedOut)
        let log = try String(contentsOf: result.logURL, encoding: .utf8)
        #expect(log.contains("smokeOutcome=keptAlive"))
        #expect(log.contains("TIMEOUT after 1s"))
        #expect(log.contains("Requesting wineserver -k for smoke timeout cleanup"))
        #expect(log.contains("env.MACWIN_DISABLE_WINE_APP_ACTIVATION=1"))
    }

    @Test("Delegated HoYoPlay helper processes are recognized as kept alive")
    func delegatedHoYoPlayHelperProcessesAreRecognizedAsKeptAlive() throws {
        let bottle = BottleManifest(id: "game", name: "Game", windowsVersion: "win11", arch: .win64, engineId: "engine")
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/wine",
            wineserverPath: "/wineserver",
            runtimePath: "/runtime",
            defaultEnv: [:]
        )
        let request = WineRunRequest(
            exe: "C:\\Program Files\\miHoYo Launcher\\launcher.exe",
            bottle: bottle,
            engine: engine,
            envOverrides: ["MACWIN_COMPAT_PROFILE": "hoyoplay-webview"],
            logName: "high-performance-win11-hoyoplay.log"
        )
        let processLines = WineRunner.hostProcessLines(from: """
          100 C:\\windows\\system32\\winedevice.exe
          200 C:\\Program Files\\miHoYo Launcher\\1.16.1.364\\HYPHelper --type=renderer
          201 /Users/a1-6/project/Mac-Win/refs/Whisky-wow64-game-build/server/wineserver
          202 C:\\Program Files\\Other\\App.exe
        """)

        let delegated = WineRunner.delegatedWineProcessLines(in: processLines, for: request)

        #expect(delegated.map(\.pid) == [200])
    }

    @Test("Delegated Androws service processes are recognized without crashpad noise")
    func delegatedAndrowsServiceProcessesAreRecognizedWithoutCrashpadNoise() throws {
        let bottle = BottleManifest(id: "game", name: "Game", windowsVersion: "win11", arch: .win64, engineId: "engine")
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/wine",
            wineserverPath: "/wineserver",
            runtimePath: "/runtime",
            defaultEnv: [:]
        )
        let request = WineRunRequest(
            exe: "C:\\Program Files\\Tencent\\Androws\\Application\\AndrowsLauncher.exe",
            bottle: bottle,
            engine: engine,
            envOverrides: ["MACWIN_COMPAT_PROFILE": "lenovo-app-store"],
            logName: "high-performance-win11-androws.log"
        )
        let processLines = WineRunner.hostProcessLines(from: """
          300 C:\\Program Files\\Tencent\\Androws\\Application\\5.10.6400.6084\\AndrowsSvr.exe
          301 C:\\Program Files\\Tencent\\Androws\\Application\\5.10.6400.6084\\crashpad_handler.exe --annotation=process_name=AndrowsSvr
          302 C:\\Program Files (x86)\\Lenovo\\LenovoInternetSoftwareFramework\\LISFService.exe
          303 C:\\windows\\system32\\winedevice.exe
        """)

        let delegated = WineRunner.delegatedWineProcessLines(in: processLines, for: request)

        #expect(delegated.map(\.pid) == [300, 302])
        #expect(WineRunner.allowsAssumedDelegationSuccess(for: request))
    }

    @Test("Delegated Steam web helper processes are recognized after bootstrap exits")
    func delegatedSteamWebHelperProcessesAreRecognizedAfterBootstrapExits() throws {
        let bottle = BottleManifest(id: "game", name: "Game", windowsVersion: "win11", arch: .win64, engineId: "engine")
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/wine",
            wineserverPath: "/wineserver",
            runtimePath: "/runtime",
            defaultEnv: [:]
        )
        let request = WineRunRequest(
            exe: "C:\\Program Files\\Steam\\Steam.exe",
            bottle: bottle,
            engine: engine,
            envOverrides: ["MACWIN_COMPAT_PROFILE": "steam-client"],
            logName: "high-performance-win11-steam.log"
        )
        let processLines = WineRunner.hostProcessLines(from: """
          400 C:\\Program Files\\Steam\\Steam.exe
          401 C:\\Program Files\\Steam\\bin\\cef\\cef.win64\\steamwebhelper.exe --type=renderer
          402 C:\\Program Files\\Steam\\bin\\cef\\cef.win64\\steamwebhelper.exe --type=utility
          403 C:\\Program Files\\Steam\\bin\\cef\\cef.win64\\crashpad_handler.exe
          404 /Users/a1-6/project/Mac-Win/refs/Whisky-wow64-game-build/server/wineserver
        """)

        let delegated = WineRunner.delegatedWineProcessLines(in: processLines, for: request)

        #expect(delegated.map(\.pid) == [401, 402])
    }

    @Test("Smoke launch normalizes successful delegated updater handoff")
    func smokeLaunchNormalizesSuccessfulDelegatedUpdaterHandoff() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerDelegatedUpdaterTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let helper = root.appendingPathComponent("steamwebhelper.exe")
        try FileManager.default.createSymbolicLink(at: helper, withDestinationURL: URL(fileURLWithPath: "/bin/sleep"))
        let launcher = root.appendingPathComponent("updater-handoff.sh")
        let script = """
        #!/bin/sh
        "\(helper.path)" 3 &
        exit 42
        """
        try Data(script.utf8).write(to: launcher)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: launcher.path)

        let paths = MacWinPaths(root: root.appendingPathComponent("MacWin", isDirectory: true))
        let runner = WineRunner(paths: paths)
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/bin/sh",
            wineserverPath: "/bin/echo",
            runtimePath: "/runtime",
            defaultEnv: [:]
        )
        let bottle = BottleManifest(
            id: "steam",
            name: "Steam",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )

        let result = try runner.smokeLaunch(WineRunRequest(
            exe: launcher.path,
            bottle: bottle,
            engine: engine,
            logName: "steam-client-updater-handoff.log"
        ), timeoutSeconds: 5)

        #expect(!result.timedOut)
        #expect(result.exitCode == 0)
        let log = try String(contentsOf: result.logURL, encoding: .utf8)
        #expect(log.contains("smokeOutcome=keptAlive"))
        #expect(log.contains("smokeDelegatedProcess=true"))
        #expect(log.contains("smokeParentExitCode=42"))
        #expect(log.contains("exitCode=0"))
    }

    @Test("Detached launch writes structured launch history")
    func detachedLaunchWritesStructuredLaunchHistory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerDetachedLaunchHistoryTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "detached-bottle",
            name: "Detached Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )

        let result = try runner.launchDetached(WineRunRequest(
            exe: "hello.exe",
            args: ["--detached"],
            bottle: bottle,
            engine: engine,
            logName: "detached.log"
        ))

        var record: WineLaunchRecord?
        for _ in 0..<50 {
            record = LaunchHistoryService(paths: paths).report().records.first
            if record?.state == .completed {
                break
            }
            Thread.sleep(forTimeInterval: 0.02)
        }

        let launchRecord = try #require(record)
        #expect(launchRecord.mode == .detached)
        #expect(launchRecord.state == .completed)
        #expect(launchRecord.processIdentifier == result.processIdentifier)
        #expect(launchRecord.logPath == result.logURL.path)
        #expect(launchRecord.exitCode == 0)
    }

    @Test("Lenovo DXVK repair deploys all D3D11 DLLs and preserves WineD3D originals")
    func lenovoDXVKRepairDeploysDLLsAndPreservesOriginals() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerDXVKRepairTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let source = root.appendingPathComponent("dxvk-source", isDirectory: true)
        let system32 = paths.bottleDriveCURL(id: "dxvk-bottle")
            .appendingPathComponent("windows/system32", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: system32, withIntermediateDirectories: true)
        for fileName in ["dxgi.dll", "d3d11.dll", "d3d10core.dll"] {
            try Data("dxvk-\(fileName)".utf8).write(to: source.appendingPathComponent(fileName))
            try Data("wine-\(fileName)".utf8).write(to: system32.appendingPathComponent(fileName))
        }

        let bottle = BottleManifest(
            id: "dxvk-bottle",
            name: "DXVK Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
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

        _ = try WineRunner(paths: paths).run(WineRunRequest(
            exe: "probe.exe",
            bottle: bottle,
            engine: engine,
            envOverrides: [
                "MACWIN_DXVK_MACOS_REPAIR": "1",
                "MACWIN_DXVK_MACOS_DIR": source.path,
            ]
        ))

        for fileName in ["dxgi.dll", "d3d11.dll", "d3d10core.dll"] {
            #expect(try Data(contentsOf: system32.appendingPathComponent(fileName)) == Data("dxvk-\(fileName)".utf8))
            #expect(try Data(contentsOf: system32.appendingPathComponent(".macwin-wined3d-backup/\(fileName)")) == Data("wine-\(fileName)".utf8))
        }
        let marker = paths.bottleDirectory(id: bottle.id).appendingPathComponent(".macwin-dxvk-macos-source")
        #expect(try String(contentsOf: marker, encoding: .utf8) == source.path)
    }

    @Test("WPS Office repair deploys matching 64-bit and 32-bit fltlib runtime coverage")
    func wpsOfficeRepairDeploysWoW64FltlibCoverage() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerWPSRepairTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root.appendingPathComponent("app-support", isDirectory: true))
        let build = root.appendingPathComponent("engine-build", isDirectory: true)
        let loader = build.appendingPathComponent("loader", isDirectory: true)
        let x64Source = build.appendingPathComponent("dlls/fltlib/x86_64-windows/fltlib.dll")
        let x86Source = build.appendingPathComponent("dlls/fltlib/i386-windows/fltlib.dll")
        try FileManager.default.createDirectory(at: loader, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: x64Source.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: x86Source.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.createSymbolicLink(
            at: loader.appendingPathComponent("wine"),
            withDestinationURL: URL(fileURLWithPath: "/bin/echo")
        )
        let x64Data = Data("fltlib-x64".utf8)
        let x86Data = Data("fltlib-x86".utf8)
        try x64Data.write(to: x64Source)
        try x86Data.write(to: x86Source)

        let bottle = BottleManifest(
            id: "wps-bottle",
            name: "WPS Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        let engine = EngineManifest(
            id: "engine",
            name: "WoW64 Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            supportsWin32: true,
            winePath: loader.appendingPathComponent("wine").path,
            wineserverPath: "/bin/echo",
            runtimePath: "/runtime",
            defaultEnv: [:]
        )

        _ = try WineRunner(paths: paths).run(WineRunRequest(
            exe: "wps.exe",
            bottle: bottle,
            engine: engine,
            envOverrides: ["MACWIN_WPS_OFFICE_REPAIR": "1"]
        ))

        let driveC = paths.bottleDriveCURL(id: bottle.id)
        #expect(try Data(contentsOf: driveC.appendingPathComponent("windows/system32/fltlib.dll")) == x64Data)
        #expect(try Data(contentsOf: driveC.appendingPathComponent("windows/syswow64/fltlib.dll")) == x86Data)
    }

    @Test("Npackd catalog repair deploys a verified seed without replacing a populated database")
    func npackdCatalogRepairDeploysVerifiedSeedOnce() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerNpackdRepairTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let cache = paths.downloadsDirectory.appendingPathComponent("NpackdRepository", isDirectory: true)
        try FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
        let seedData = Data(repeating: 0x4e, count: 10 * 1_024 * 1_024)
        let seed = cache.appendingPathComponent("Data.db")
        try seedData.write(to: seed)
        try Hashing.sha256Hex(data: seedData).write(
            to: cache.appendingPathComponent("Data.db.sha256"),
            atomically: true,
            encoding: .utf8
        )
        try Data("stable".utf8).write(to: cache.appendingPathComponent("stable.zip"))
        try Data("stable64".utf8).write(to: cache.appendingPathComponent("stable64.zip"))

        let bottle = BottleManifest(
            id: "npackd-bottle",
            name: "Npackd Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
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
        let request = WineRunRequest(
            exe: "C:\\macwin-portable\\npackd\\npackdg.exe",
            bottle: bottle,
            engine: engine
        )

        _ = try WineRunner(paths: paths).run(request)
        let destination = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("ProgramData/Npackd/Data.db")
        #expect(try Data(contentsOf: destination) == seedData)
        #expect(FileManager.default.fileExists(atPath: paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("macwin-runtime/npackd/stable.zip").path))

        let populatedData = Data(repeating: 0x50, count: 10 * 1_024 * 1_024 + 1)
        try populatedData.write(to: destination)
        let repositoryCache = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("macwin-runtime/npackd", isDirectory: true)
        try Data("stale".utf8).write(
            to: repositoryCache.appendingPathComponent("stable.zip")
        )
        try FileManager.default.removeItem(
            at: repositoryCache.appendingPathComponent("stable64.zip")
        )
        _ = try WineRunner(paths: paths).run(request)
        #expect(try Data(contentsOf: destination) == populatedData)
        #expect(try Data(contentsOf: repositoryCache.appendingPathComponent("stable.zip"))
            == Data("stable".utf8))
        #expect(try Data(contentsOf: repositoryCache.appendingPathComponent("stable64.zip"))
            == Data("stable64".utf8))
    }

    @Test("Cura repair writes a stable plugin profile and clears stale startup cache")
    func curaRepairWritesStablePluginProfile() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerCuraRepairTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let bottle = BottleManifest(
            id: "cura-bottle",
            name: "Cura Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
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
        let userDirectory = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("users/tester", isDirectory: true)
        let staleCache = userDirectory
            .appendingPathComponent("AppData/Roaming/cura/5.13/startupCache", isDirectory: true)
        try FileManager.default.createDirectory(at: staleCache, withIntermediateDirectories: true)

        _ = try WineRunner(paths: paths).run(WineRunRequest(
            exe: "C:\\Program Files\\UltiMaker Cura 5.13.0\\UltiMaker-Cura.exe",
            bottle: bottle,
            engine: engine
        ))

        let pluginsURL = userDirectory.appendingPathComponent("AppData/Roaming/cura/5.13/plugins.json")
        let object = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: pluginsURL)) as? [String: Any])
        let disabled = try #require(object["disabled"] as? [String])
        #expect(disabled.contains("Marketplace"))
        #expect(disabled.contains("USBPrinting"))
        #expect(!FileManager.default.fileExists(atPath: staleCache.path))
    }

    @Test("Terminate bottle uses wineserver kill for the Wine prefix")
    func terminateBottleUsesWineServerKill() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRunnerTerminateBottleTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let runner = WineRunner(paths: paths)
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
        let bottle = BottleManifest(
            id: "terminate-bottle",
            name: "Terminate Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )

        let result = try runner.terminateBottle(bottle: bottle, engine: engine, logName: "terminate.log")

        #expect(result.exitCode == 0)
        #expect(result.commandLine == ["/usr/bin/arch", "-x86_64", "/bin/echo", "-k"])
        let text = try String(contentsOf: result.logURL, encoding: .utf8)
        #expect(text.contains("exe=/bin/echo"))
        #expect(text.contains("command=/usr/bin/arch -x86_64 /bin/echo -k"))
        #expect(text.contains("env.WINEPREFIX=\(paths.bottleDirectory(id: bottle.id).path)"))

        let record = try #require(LaunchHistoryService(paths: paths).report().records.first)
        #expect(record.mode == .foregroundRun)
        #expect(record.state == .completed)
        #expect(record.exe == "/bin/echo")
        #expect(record.args == ["-k"])
        #expect(record.commandLine == result.commandLine)
        #expect(record.exitCode == 0)
    }
}
