import Testing
@testable import MacWinCore

@Suite("Application compatibility profiles")
struct ApplicationCompatibilityProfileTests {
    @Test
    func geogebraLegacyElectron32DisablesJITForRosettaWoW64() {
        let profile = ApplicationCompatibilityProfile.geogebraLegacyElectron32

        #expect(profile.launchArguments.contains("--js-flags=--jitless"))
        #expect(!profile.launchArguments.contains("--noexpose_wasm"))
        #expect(profile.environment["MACWIN_GEOGEBRA_ELECTRON32_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_WOW64_BROWSER_REPAIR"] == "1")
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
        #expect(ApplicationCompatibilityProfile.matched(
            exePath: "C:\\macwin-portable\\geogebra-classic\\GeoGebra.exe"
        ) == .geogebraLegacyElectron32)
    }

    @Test("Steam profile carries CEF and focus repairs")
    func steamProfileCarriesCEFAndFocusRepairs() {
        let profile = ApplicationCompatibilityProfile.steamClient

        #expect(profile.launchArguments.contains("-no-cef-sandbox"))
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "steam-client")
        #expect(profile.environment["MACWIN_ACTIVATE_WINE_APP"] == "1")
        #expect(profile.environment["MACWIN_FORCE_MOUSE_FOCUS"] == "1")
        #expect(profile.environment["MACWIN_DISABLE_DWM_COMPOSITION"] == "1")
        #expect(profile.environment["MACWIN_STEAMWEBHELPER_FORCE_OPAQUE"] == "1")
        #expect(profile.environment["MACWIN_RECENTER_OFFSCREEN_WINDOWS"] == "1")
        #expect(profile.environment["MACWIN_FONTCONFIG_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FONT_FALLBACK_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_IPHLPAPI_FORCE_FALLBACK"] == "1")
        #expect(profile.environment["MACWIN_TEXT_RENDERING_REPAIR"] == "1")
        #expect(profile.environment["FREETYPE_PROPERTIES"]?.contains("interpreter-version=35") == true)
        #expect(profile.environment["QTWEBENGINE_DISABLE_SANDBOX"] == "1")
        #expect(profile.environment["LANG"] == "zh_CN.UTF-8")
        #expect(profile.environment["LC_CTYPE"] == "zh_CN.UTF-8")
        #expect(ApplicationCompatibilityProfile.steamWebHelperArguments.contains("--use-gl=disabled"))
        #expect(ApplicationCompatibilityProfile.steamWebHelperArguments.contains("--disable-accelerated-2d-canvas"))
        #expect(!ApplicationCompatibilityProfile.steamWebHelperArguments.contains("--disable-direct-write"))
        #expect(!ApplicationCompatibilityProfile.steamWebHelperArguments.contains("--disable-directwrite-for-ui"))
        #expect(!ApplicationCompatibilityProfile.steamWebHelperArguments.contains("--disable-font-subpixel-positioning"))
        #expect(!ApplicationCompatibilityProfile.steamWebHelperArguments.contains("--disable-lcd-text"))
        #expect(!ApplicationCompatibilityProfile.steamWebHelperArguments.contains("--disable-prefer-compositing-to-lcd-text"))
        #expect(!ApplicationCompatibilityProfile.steamWebHelperArguments.contains("--font-render-hinting=none"))
        #expect(!ApplicationCompatibilityProfile.steamWebHelperArguments.contains("--disable-remote-fonts"))
        #expect(ApplicationCompatibilityProfile.steamWebHelperArguments.contains("--enable-features=FontSrcLocalMatching"))
        #expect(!ApplicationCompatibilityProfile.steamWebHelperArguments.contains(",FontSrcLocalMatching"))
        #expect(!ApplicationCompatibilityProfile.steamWebHelperArguments.contains("FontationsFontBackend"))
        #expect(!ApplicationCompatibilityProfile.steamWebHelperArguments.contains("DWriteFontProxy"))
        #expect(!ApplicationCompatibilityProfile.steamWebHelperArguments.contains("UseDWriteCore"))
        #expect(!ApplicationCompatibilityProfile.steamWebHelperArguments.contains("UseSkiaRenderer"))
        #expect(!ApplicationCompatibilityProfile.steamWebHelperArguments.contains("--disable-skia-runtime-opts"))
        #expect(profile.environment["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("--disable-direct-write") == false)
        #expect(profile.environment["WINEDLLOVERRIDES"] == "wbemprox=d")
    }

    @Test("WebView software renderer profile repairs text layers")
    func webViewSoftwareRendererProfileRepairsTextLayers() {
        let profile = ApplicationCompatibilityProfile.cefSoftwareRenderer

        #expect(profile.launchArguments.contains("--disable-direct-composition"))
        #expect(profile.launchArguments.contains("--no-proxy-server"))
        #expect(profile.launchArguments.contains("--proxy-server=direct://"))
        #expect(profile.launchArguments.contains("--proxy-bypass-list=*"))
        #expect(!profile.launchArguments.contains("--disable-font-subpixel-positioning"))
        #expect(!profile.launchArguments.contains("--disable-lcd-text"))
        #expect(!profile.launchArguments.contains("--disable-prefer-compositing-to-lcd-text"))
        #expect(!profile.launchArguments.contains("--font-render-hinting=none"))
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "cef-software-gl")
        #expect(profile.environment["MACWIN_ACTIVATE_WINE_APP"] == "1")
        #expect(profile.environment["MACWIN_FONTCONFIG_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FONT_FALLBACK_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_IPHLPAPI_FORCE_FALLBACK"] == "1")
        #expect(profile.environment["MACWIN_TEXT_RENDERING_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FORCE_OPAQUE_LAYERED_WINDOWS"] == "1")
        #expect(profile.environment["FREETYPE_PROPERTIES"]?.contains("interpreter-version=35") == true)
        #expect(profile.environment["QTWEBENGINE_DISABLE_SANDBOX"] == "1")
        #expect(profile.environment["QT_STYLE_OVERRIDE"] == "Fusion")
        #expect(profile.environment["QT_OPENGL"] == "software")
        #expect(profile.environment["QT_QUICK_BACKEND"] == "software")
        #expect(profile.environment["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--font-render-hinting=none") == false)
        #expect(profile.environment["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--disable-font-subpixel-positioning") == false)
        #expect(profile.environment["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--disable-lcd-text") == false)
        #expect(profile.environment["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("--disable-direct-write") == false)
        #expect(profile.environment["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("--disable-remote-fonts") == false)
        #expect(profile.environment["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("--enable-features=FontSrcLocalMatching") == true)
        #expect(profile.environment["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains(",FontSrcLocalMatching") == false)
        #expect(profile.environment["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("FontationsFontBackend") == false)
        #expect(profile.environment["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("DWriteFontProxy") == false)
        #expect(profile.environment["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("UseDWriteCore") == false)
        #expect(profile.environment["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("UseSkiaRenderer") == false)
        #expect(profile.environment["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("--disable-skia-runtime-opts") == false)
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
        #expect(profile.environment["WINEDLLOVERRIDES"] == "qone,wbemprox=d")
    }

    @Test("OpenPLC profile keeps Electron rendering in-process and supplies a valid timezone")
    func openPLCProfileRepairsElectronCompositorAndTimezone() {
        let profile = ApplicationCompatibilityProfile.openPLCEditor

        #expect(profile.launchArguments.contains("--disable-gpu"))
        #expect(profile.launchArguments.contains("--in-process-gpu"))
        #expect(profile.launchArguments.contains("--use-angle=swiftshader"))
        #expect(profile.launchArguments.contains("--use-gl=angle"))
        #expect(profile.launchArguments.contains("--enable-unsafe-swiftshader"))
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "openplc-electron")
        #expect(profile.environment["MACWIN_OPENPLC_ELECTRON_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(profile.environment["TZ"] == "Asia/Shanghai")
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=vulkan,csmt=0x0")
        #expect(ApplicationCompatibilityProfile.matched(
            exePath: "C:\\macwin-portable\\openplc-editor\\OpenPLC Editor.exe"
        ) == .openPLCEditor)
        #expect(ApplicationCompatibilityProfile.current(in: LauncherManifest(
            id: "openplc-editor",
            appId: "industrial",
            bottleId: "bottle",
            displayName: "OpenPLC Editor",
            exePath: "C:\\macwin-portable\\openplc-editor\\OpenPLC Editor.exe",
            envOverrides: ["MACWIN_COMPAT_PROFILE": "openplc-electron"]
        )) == .openPLCEditor)
    }

    @Test("Chromium browser profile uses versioned app directory launch")
    func chromiumBrowserProfileUsesVersionedAppDirectoryLaunch() {
        let profile = ApplicationCompatibilityProfile.chromiumBrowser

        #expect(profile.launchArguments.contains("--disable-direct-composition"))
        #expect(profile.launchArguments.contains("--enable-features=FontSrcLocalMatching"))
        #expect(profile.launchArguments.contains("--no-proxy-server"))
        #expect(profile.launchArguments.contains("--proxy-server=direct://"))
        #expect(profile.launchArguments.contains("--proxy-bypass-list=*"))
        #expect(profile.launchArguments.contains { $0.contains("RendererCodeIntegrity") })
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "chromium-browser")
        #expect(profile.environment["MACWIN_ACTIVATE_WINE_APP"] == "1")
        #expect(profile.environment["MACWIN_CHROMIUM_BROWSER_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_IPHLPAPI_FORCE_FALLBACK"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "versioned-chromium-dir")
        #expect(profile.environment["ROSETTA_X87_PATH"] == "")
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=vulkan,csmt=0x0")
        #expect(profile.environment["MACWIN_CHROMIUM_HELPER_ARGS"] == ApplicationCompatibilityProfile.chromiumBrowserHelperArguments)
    }

    @Test("Supermium 32-bit profile preserves WOW64 portable launch conditions")
    func supermium32ProfilePreservesWOW64PortableLaunchConditions() {
        let profile = ApplicationCompatibilityProfile.supermium32Browser

        #expect(profile.launchArguments == ApplicationCompatibilityProfile.supermium32BrowserArguments)
        #expect(profile.launchArguments.contains("--user-data-dir=portable_data32-macwin"))
        #expect(profile.launchArguments.contains("--disable-background-mode"))
        #expect(profile.launchArguments.contains("--disable-background-networking"))
        #expect(profile.launchArguments.contains("--new-window"))
        #expect(profile.launchArguments.contains("--use-angle=swiftshader"))
        #expect(profile.launchArguments.contains("--use-gl=angle"))
        #expect(profile.launchArguments.contains("about:blank"))
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "supermium-32-browser")
        #expect(profile.environment["MACWIN_ACTIVATE_WINE_APP"] == "1")
        #expect(profile.environment["MACWIN_CHROMIUM_BROWSER_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_WOW64_BROWSER_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_DISABLE_WINE_D3D_CONFIG"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(profile.environment["MACWIN_FONTCONFIG_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FONT_FALLBACK_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_TEXT_RENDERING_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_CHROMIUM_HELPER_ARGS"] == ApplicationCompatibilityProfile.supermium32BrowserArguments.joined(separator: " "))
        #expect(profile.environment["WINE_D3D_CONFIG"] == nil)
        #expect(profile.environment["WINEDLLOVERRIDES"] == "wbemprox=d")
    }

    @Test("Zotero Gecko 32-bit profile uses isolated profile and disables GPU paths")
    func zoteroGecko32ProfileUsesIsolatedProfileAndDisablesGPUPaths() {
        let profile = ApplicationCompatibilityProfile.zoteroGecko32

        #expect(profile.launchArguments == ApplicationCompatibilityProfile.zoteroGecko32Arguments)
        #expect(profile.launchArguments.contains("-no-remote"))
        #expect(profile.launchArguments.contains("C:\\macwin-portable\\zotero-profile"))
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "zotero-gecko32")
        #expect(profile.environment["MACWIN_ZOTERO_GECKO32_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_GECKO_PROFILE_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_WOW64_BROWSER_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_DISABLE_WINE_D3D_CONFIG"] == "1")
        #expect(profile.environment["MOZ_WEBRENDER"] == "0")
        #expect(profile.environment["MOZ_DISABLE_CONTENT_SANDBOX"] == "1")
        #expect(profile.environment["WINEDEBUG"] == "-all")
        #expect(profile.environment["WINE_D3D_CONFIG"] == nil)
        #expect(ApplicationCompatibilityProfile.matched(
            recipeId: "zotero-research",
            exePath: "C:\\Program Files (x86)\\Zotero\\zotero.exe"
        ) == .zoteroGecko32)
    }

    @Test("Gecko browser profile uses isolated Firefox profile and disables GPU paths")
    func geckoBrowserProfileUsesIsolatedFirefoxProfileAndDisablesGPUPaths() {
        let profile = ApplicationCompatibilityProfile.browserGecko

        #expect(profile.launchArguments == ApplicationCompatibilityProfile.browserGeckoArguments)
        #expect(profile.launchArguments.contains("-no-remote"))
        #expect(profile.launchArguments.contains("C:\\macwin-portable\\firefox-profile"))
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "browser-gecko")
        #expect(profile.environment["MACWIN_GECKO_BROWSER_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_GECKO_PROFILE_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_DISABLE_WINE_D3D_CONFIG"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(profile.environment["MOZ_WEBRENDER"] == "0")
        #expect(profile.environment["MOZ_DISABLE_CONTENT_SANDBOX"] == "1")
        #expect(profile.environment["WINEDEBUG"] == "-all")
        #expect(ApplicationCompatibilityProfile.matched(
            recipeId: "firefox",
            exePath: "C:\\Program Files\\Mozilla Firefox\\firefox.exe"
        ) == .browserGecko)
    }

    @Test("JASP profile carries QtWebEngine and qrc resource repairs")
    func jaspProfileCarriesQtWebEngineAndQrcResourceRepairs() {
        let profile = ApplicationCompatibilityProfile.jaspQtWebEngineQrc

        #expect(profile.launchArguments == ApplicationCompatibilityProfile.jaspQtWebEngineArguments)
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "jasp-qtwebengine-qrc")
        #expect(profile.environment["MACWIN_JASP_QRC_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_JASP_STARTUP_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_QTWEBENGINE_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(profile.environment["QT_OPENGL"] == "software")
        #expect(profile.environment["QT_QUICK_BACKEND"] == "software")
        #expect(profile.environment["QML_DISABLE_DISK_CACHE"] == "1")
        #expect(profile.environment["QMLSCENE_DEVICE"] == "softwarecontext")
        #expect(profile.environment["QSG_RENDER_LOOP"] == "basic")
        #expect(profile.environment["QSG_RHI_BACKEND"] == "opengl")
        #expect(profile.environment["QT_ACCESSIBILITY"] == "0")
        #expect(profile.environment["QT_AUTO_SCREEN_SCALE_FACTOR"] == "0")
        #expect(profile.environment["QT_ENABLE_HIGHDPI_SCALING"] == "0")
        #expect(profile.environment["QT_FONT_DPI"] == "96")
        #expect(profile.environment["QT_QUICK_CONTROLS_STYLE"] == "Basic")
        #expect(profile.environment["QT_RHI_BACKEND"] == "software")
        #expect(profile.environment["QT_SCALE_FACTOR"] == "1")
        #expect(profile.environment["QTWEBENGINE_DISABLE_SANDBOX"] == "1")
        #expect(profile.environment["QTWEBENGINEPROCESS_PATH"] == "C:\\Program Files\\JASP\\QtWebEngineProcess.exe")
        #expect(profile.environment["QTWEBENGINE_RESOURCES_PATH"] == "C:\\Program Files\\JASP\\resources")
        #expect(profile.environment["QML2_IMPORT_PATH"] == "C:\\Program Files\\JASP\\qml")
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
    }

    @Test("JabRef profile uses JavaFX D3D and avoids the broken software glyph pipeline")
    func jabRefProfileUsesJavaFXD3DAndRepairsBundledFonts() {
        let profile = ApplicationCompatibilityProfile.jabRefJavaFXD3D
        let javaOptions = profile.environment["JAVA_TOOL_OPTIONS"] ?? ""

        #expect(profile.launchArguments.isEmpty)
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "jabref-javafx-d3d")
        #expect(profile.environment["MACWIN_JABREF_JAVAFX_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_APP_MODE_INPUT_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FONTCONFIG_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FONT_FALLBACK_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=vulkan,csmt=0x0")
        #expect(profile.environment["ROSETTA_X87_PATH"] == "")
        #expect(javaOptions.contains("-Dprism.order=d3d"))
        #expect(javaOptions.contains("-Dprism.forceGPU=true"))
        #expect(javaOptions.contains("-Dprism.text=t2k"))
        #expect(!javaOptions.contains("-Dprism.order=sw"))
        #expect(ApplicationCompatibilityProfile.matched(
            recipeId: "jabref-portable",
            exePath: "C:\\macwin-portable\\jabref-portable\\JabRef\\JabRef.exe"
        ) == .jabRefJavaFXD3D)
    }

    @Test("FreeCAD profile keeps Qt CAD viewport on native OpenGL and repairs embedded Python")
    func freeCADProfileUsesNativeOpenGLAndPythonRepair() {
        let profile = ApplicationCompatibilityProfile.freeCADOpenGL

        #expect(profile.launchArguments.isEmpty)
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "freecad-opengl")
        #expect(profile.environment["MACWIN_FREECAD_PYTHON_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_OPENGL_VIEWPORT_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(profile.environment["QT_OPENGL"] == "desktop")
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
        #expect(profile.environment["ROSETTA_X87_PATH"] == "")
        #expect(ApplicationCompatibilityProfile.matched(
            recipeId: "freecad-workbench",
            exePath: "C:\\\\Program Files\\\\FreeCAD 1.1\\\\bin\\\\FreeCAD.exe"
        ) == .freeCADOpenGL)
        #expect(ApplicationCompatibilityProfile.matched(
            exePath: "C:\\\\Program Files\\\\FreeCAD 1.1\\\\bin\\\\FreeCADCmd.exe"
        ) == .freeCADOpenGL)
    }

    @Test("KiCad profile keeps wxWidgets text and PCB OpenGL paths stable")
    func kiCadProfileUsesCJKAndNativeOpenGLRepairs() {
        let profile = ApplicationCompatibilityProfile.kiCadEDA

        #expect(profile.launchArguments.isEmpty)
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "kicad-eda")
        #expect(profile.environment["MACWIN_FONTCONFIG_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FONT_FALLBACK_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_TEXT_RENDERING_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_OPENGL_VIEWPORT_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
        #expect(profile.environment["ROSETTA_X87_PATH"] == "")
        #expect(ApplicationCompatibilityProfile.matched(
            recipeId: "kicad-eda",
            exePath: "C:\\\\Program Files\\\\KiCad\\\\10.0\\\\bin\\\\kicad.exe"
        ) == .kiCadEDA)
        #expect(ApplicationCompatibilityProfile.matched(
            exePath: "C:\\\\Program Files\\\\KiCad\\\\10.0\\\\bin\\\\pcbnew.exe"
        ) == .kiCadEDA)
    }

    @Test("LibreCAD profile skips first-run setup and keeps the Qt CAD canvas on OpenGL")
    func libreCADProfileUsesCJKAndNativeOpenGLRepairs() {
        let profile = ApplicationCompatibilityProfile.libreCADQt

        #expect(profile.launchArguments.isEmpty)
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "librecad-qt")
        #expect(profile.environment["MACWIN_LIBRECAD_PROFILE_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FONTCONFIG_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FONT_FALLBACK_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_TEXT_RENDERING_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_OPENGL_VIEWPORT_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(profile.environment["QT_OPENGL"] == "desktop")
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
        #expect(profile.environment["ROSETTA_X87_PATH"] == "")
        #expect(ApplicationCompatibilityProfile.matched(
            recipeId: "cad-lightweight-pack",
            exePath: "C:\\\\Program Files\\\\LibreCAD\\\\LibreCAD.exe"
        ) == .libreCADQt)
        #expect(ApplicationCompatibilityProfile.matched(
            exePath: "C:\\\\Program Files\\\\LibreCAD\\\\LibreCAD.exe"
        ) == .libreCADQt)
    }

    @Test("OpenSCAD profile deploys an app-local software OpenGL viewport")
    func openSCADProfileUsesAppLocalSoftwareOpenGL() {
        let profile = ApplicationCompatibilityProfile.openSCADSoftwareOpenGL

        #expect(profile.launchArguments.isEmpty)
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "openscad-software-opengl")
        #expect(profile.environment["MACWIN_OPENSCAD_SOFTWARE_OPENGL_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_OPENGL_VIEWPORT_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(profile.environment["LIBGL_ALWAYS_SOFTWARE"] == "1")
        #expect(profile.environment["QT_OPENGL"] == "software")
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
        #expect(profile.environment["WINEDLLOVERRIDES"]?.contains("opengl32=n") == true)
        #expect(ApplicationCompatibilityProfile.matched(
            recipeId: "cad-lightweight-pack",
            exePath: "C:\\\\Program Files\\\\OpenSCAD\\\\openscad.exe"
        ) == .openSCADSoftwareOpenGL)
        #expect(ApplicationCompatibilityProfile.matched(
            exePath: "C:\\\\Program Files\\\\LibreCAD\\\\LibreCAD.exe"
        ) == .libreCADQt)
    }

    @Test("Blender profile deploys Mesa for its OpenGL 4.3 viewport")
    func blenderProfileUsesMesaSoftwareOpenGL() {
        let profile = ApplicationCompatibilityProfile.blenderSoftwareOpenGL

        #expect(profile.launchArguments.isEmpty)
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "blender-software-opengl")
        #expect(profile.environment["MACWIN_BLENDER_SOFTWARE_OPENGL_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_OPENGL_VIEWPORT_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(profile.environment["GALLIUM_DRIVER"] == "llvmpipe")
        #expect(profile.environment["MESA_LOADER_DRIVER_OVERRIDE"] == "llvmpipe")
        #expect(profile.environment["LIBGL_ALWAYS_SOFTWARE"] == "1")
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
        #expect(profile.environment["WINEDLLOVERRIDES"]?.contains("opengl32=n,b") == true)
        #expect(ApplicationCompatibilityProfile.matched(
            recipeId: "blender-3d",
            exePath: "C:\\\\Program Files\\\\Blender Foundation\\\\Blender 4.1\\\\blender.exe"
        ) == .blenderSoftwareOpenGL)
        #expect(ApplicationCompatibilityProfile.matched(
            exePath: "C:\\\\Program Files\\\\Blender Foundation\\\\Blender 4.1\\\\blender.exe"
        ) == .blenderSoftwareOpenGL)
    }

    @Test("Sweet Home 3D profile replaces the bundled 32-bit Java3D renderer with 64-bit OpenGL")
    func sweetHome3DProfileUsesBundled64BitOpenGL() {
        let profile = ApplicationCompatibilityProfile.sweetHome3DOpenGL

        #expect(profile.launchArguments.isEmpty)
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "sweethome3d-opengl")
        #expect(profile.environment["MACWIN_SWEETHOME3D_OPENGL_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_OPENGL_VIEWPORT_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(profile.environment["_JAVA_OPTIONS"] == "-Dj3d.rend=ogl -Dsun.java2d.d3d=false -Dsun.java2d.opengl=true")
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
        #expect(ApplicationCompatibilityProfile.matched(
            recipeId: "sweethome3d-design",
            exePath: "C:\\\\Program Files\\\\Sweet Home 3D\\\\SweetHome3D.exe"
        ) == .sweetHome3DOpenGL)
        #expect(ApplicationCompatibilityProfile.matched(
            exePath: "C:\\\\Program Files\\\\Sweet Home 3D\\\\SweetHome3D.exe"
        ) == .sweetHome3DOpenGL)
    }

    @Test("mRemoteNG 1.78.2 profile carries .NET Desktop runtime repair")
    func mRemoteNG1782ProfileCarriesDotNetDesktopRuntimeRepair() {
        let profile = ApplicationCompatibilityProfile.mRemoteNG1782

        #expect(profile.launchArguments == ["/reset", "/noreconnect"])
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "mremoteng-1782-x64")
        #expect(profile.environment["MACWIN_ACTIVATE_WINE_APP"] == "1")
        #expect(profile.environment["MACWIN_DISABLE_WINE_APP_ACTIVATION"] == "1")
        #expect(profile.environment["MACWIN_DOTNET_DESKTOP10_RUNTIME_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_MREMOTENG_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(profile.environment["DOTNET_ROOT"] == "C:\\macwin-runtimes\\dotnet-desktop-10-x64")
        #expect(profile.environment["DOTNET_ROOT_X64"] == "C:\\macwin-runtimes\\dotnet-desktop-10-x64")
        #expect(profile.environment["LC_ALL"] == "C.UTF-8")
        #expect(profile.environment["LC_CTYPE"] == "zh_CN.UTF-8")
        #expect(profile.environment["PATH"]?.contains("C:\\macwin-runtimes\\dotnet-desktop-10-x64") == true)
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
    }

    @Test("HoYoPlay profile repairs CEF text rendering without blocking remote fonts")
    func hoYoPlayProfileRepairsCEFTextRenderingWithoutBlockingRemoteFonts() {
        let profile = ApplicationCompatibilityProfile.hoYoPlay

        #expect(profile.launchArguments.isEmpty)
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "hoyoplay-webview")
        #expect(profile.environment["MACWIN_ACTIVATE_WINE_APP"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(profile.environment["LC_CTYPE"] == "zh_CN.UTF-8")
        #expect(profile.environment["LANGUAGE"] == "zh_CN:zh:en_US:en")
        #expect(profile.environment["QT_FONT_FAMILY"] == "PingFang SC")
        #expect(profile.environment["CHROMIUM_USER_FLAGS"]?.contains("--accept-lang=zh-CN") == true)
        #expect(profile.environment["MACWIN_FONTCONFIG_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FONT_FALLBACK_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_HOYOPLAY_TEXT_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_TEXT_RENDERING_REPAIR"] == "1")
        #expect(profile.environment["FREETYPE_PROPERTIES"]?.contains("interpreter-version=35") == true)
        #expect(profile.environment["QTWEBENGINE_DISABLE_SANDBOX"] == "1")
        #expect(profile.environment["QT_STYLE_OVERRIDE"] == "Fusion")
        #expect(profile.environment["QT_FONT_DPI"] == "96")
        #expect(profile.environment["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--use-gl=angle") == true)
        #expect(profile.environment["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--use-angle=swiftshader") == true)
        #expect(profile.environment["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--disable-direct-write") == false)
        #expect(profile.environment["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--disable-remote-fonts") == false)
        #expect(profile.environment["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--enable-features=FontSrcLocalMatching") == true)
        #expect(profile.environment["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains(",FontSrcLocalMatching") == false)
        #expect(profile.environment["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("FontationsFontBackend") == false)
        #expect(profile.environment["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("DWriteFontProxy") == false)
        #expect(profile.environment["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("UseDWriteCore") == false)
        #expect(profile.environment["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("UseSkiaRenderer") == false)
        #expect(profile.environment["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--disable-skia-runtime-opts") == false)
        #expect(profile.environment["MACWIN_CHROMIUM_HELPER_ARGS"] == ApplicationCompatibilityProfile.hoYoPlayWebViewHelperArguments)
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
        #expect(profile.environment["WINEDLLOVERRIDES"] == "qone,wbemprox=d")
    }

    @Test("Lenovo App Store profile avoids Chromium black screens")
    func lenovoAppStoreProfileAvoidsChromiumBlackScreens() {
        let profile = ApplicationCompatibilityProfile.lenovoAppStore

        #expect(profile.launchArguments == ApplicationCompatibilityProfile.lenovoAppStoreArguments)
        #expect(!profile.launchArguments.contains("--use-gl=disabled"))
        #expect(!profile.launchArguments.contains("--disable-gpu"))
        #expect(profile.launchArguments.contains("--disable-direct-composition"))
        #expect(profile.launchArguments.contains("--no-proxy-server"))
        #expect(profile.launchArguments.contains("--proxy-server=direct://"))
        #expect(profile.launchArguments.contains("--proxy-bypass-list=*"))
        #expect(profile.launchArguments.contains("--in-process-gpu"))
        #expect(profile.launchArguments.contains("--use-gl=angle"))
        #expect(profile.launchArguments.contains("--use-angle=d3d11"))
        #expect(profile.launchArguments.contains("--remote-debugging-port=9231"))
        #expect(!profile.launchArguments.contains("--use-angle=swiftshader-webgl"))
        #expect(!profile.launchArguments.contains("--disable-font-subpixel-positioning"))
        #expect(!profile.launchArguments.contains("--disable-lcd-text"))
        #expect(!profile.launchArguments.contains("--disable-prefer-compositing-to-lcd-text"))
        #expect(!profile.launchArguments.contains("--font-render-hinting=none"))
        #expect(!profile.launchArguments.contains("--disable-remote-fonts"))
        #expect(ApplicationCompatibilityProfile.lenovoAppStoreCEFHelperArguments.contains("--use-angle=d3d11"))
        #expect(!ApplicationCompatibilityProfile.lenovoAppStoreCEFHelperArguments.contains("--disable-gpu"))
        #expect(ApplicationCompatibilityProfile.lenovoAppStoreCEFHelperArguments.contains("--disable-direct-composition"))
        #expect(profile.environment["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("--enable-features=FontSrcLocalMatching") == true)
        #expect(profile.environment["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains(",FontSrcLocalMatching") == false)
        #expect(profile.environment["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("FontationsFontBackend") == false)
        #expect(profile.environment["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("DWriteFontProxy") == false)
        #expect(profile.environment["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("UseDWriteCore") == false)
        #expect(profile.environment["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("UseSkiaRenderer") == false)
        #expect(profile.environment["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("--disable-skia-runtime-opts") == false)
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "lenovo-app-store")
        #expect(profile.environment["MACWIN_ACTIVATE_WINE_APP"] == "1")
        #expect(profile.environment["LC_CTYPE"] == "zh_CN.UTF-8")
        #expect(profile.environment["MACWIN_FONTCONFIG_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FONT_FALLBACK_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_LENOVO_BLACK_SCREEN_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FORCE_MOUSE_FOCUS"] == "1")
        #expect(profile.environment["FREETYPE_PROPERTIES"]?.contains("interpreter-version=35") == true)
        #expect(profile.environment["QTWEBENGINE_DISABLE_SANDBOX"] == "1")
        #expect(profile.environment["MACWIN_CHROMIUM_HELPER_ARGS"] == ApplicationCompatibilityProfile.lenovoAppStoreHelperArguments)
        #expect(profile.environment["MACWIN_DXVK_MACOS_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_LENOVO_PAGE_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_LENOVO_DEBUG_PORT"] == "9231")
        #expect(profile.environment["MACWIN_DISABLE_WINE_D3D_CONFIG"] == nil)
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=vulkan,csmt=0x0")
        #expect(profile.environment["MACWIN_DISABLE_DWM_COMPOSITION"] == nil)
        #expect(profile.environment["MACWIN_FORCE_OPAQUE_LAYERED_WINDOWS"] == nil)
        #expect(profile.environment["WINEDLLOVERRIDES"] == "dxgi,d3d11,d3d10core=n,b;qone,wbemprox=d")
    }

    @Test("Lenovo page repair restores the missing native-ready event before guarded banner repair")
    func lenovoPageRepairIsNarrowlyGuarded() {
        let expression = LenovoAppStorePageRepairService.repairExpression

        #expect(expression.contains("state && state.native"))
        #expect(expression.contains("native.commandLineReady !== true"))
        #expect(expression.contains("SET_COMMAND_LINE_READY"))
        #expect(expression.contains("ready: true"))
        #expect(expression.contains("patched-command-line-ready"))
        #expect(expression.contains("exploreEntry.initialized !== true"))
        #expect(expression.contains("EXPLORE_ENTRY_INIT"))
        #expect(expression.contains("commandLineMode: \"none\""))
        #expect(expression.contains("not-ready:special-command-line"))
        #expect(expression.contains("patched-explore-entry"))
        #expect(expression.contains("recoBannerDataIsResponse"))
        #expect(expression.contains("pageCardList"))
        #expect(expression.contains("RECO_TOP_CONTENTS_SUCCESS"))
        #expect(expression.contains("data: [cards[0]]"))
        #expect(expression.contains("already-renderable"))
    }

    @Test("Tencent App Store profile is separate from Lenovo repairs")
    func tencentAppStoreProfileUsesWebViewSoftwareFallbacks() {
        let profile = ApplicationCompatibilityProfile.tencentAppStore

        #expect(profile.launchArguments == ApplicationCompatibilityProfile.tencentAppStoreArguments)
        #expect(profile.launchArguments.contains("--use-gl=disabled"))
        #expect(profile.launchArguments.contains("--disable-webgl"))
        #expect(profile.launchArguments.contains("--disable-webgl2"))
        #expect(!profile.launchArguments.contains("--use-gl=angle"))
        #expect(!profile.launchArguments.contains("--use-angle=swiftshader"))
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "tencent-app-store")
        #expect(profile.environment["MACWIN_TENCENT_APP_STORE_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_WEBVIEW_SOFTWARE_RENDERER"] == "1")
        #expect(profile.environment["MACWIN_TEXT_RENDERING_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FONT_FALLBACK_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_LENOVO_BLACK_SCREEN_REPAIR"] == nil)
        #expect(profile.environment["MACWIN_CHROMIUM_HELPER_ARGS"] == ApplicationCompatibilityProfile.tencentAppStoreHelperArguments)
        #expect(profile.environment["QTWEBENGINE_CHROMIUM_FLAGS"] == ApplicationCompatibilityProfile.tencentAppStoreHelperArguments)
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
    }

    @Test("Qt RHI software profile keeps non-MuseScore Qt Quick launchers clean")
    func qtRhiSoftwareProfileRepairsQtQuickLaunchers() {
        let profile = ApplicationCompatibilityProfile.qtRhiSoftware

        #expect(profile.launchArguments.isEmpty)
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "qt-rhi-software")
        #expect(profile.environment["MACWIN_APP_MODE_INPUT_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_QT_RHI_SOFTWARE_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_ACTIVATE_WINE_APP"] == "1")
        #expect(profile.environment["MACWIN_FORCE_MOUSE_FOCUS"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(profile.environment["MACWIN_FONTCONFIG_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FONT_FALLBACK_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_TEXT_RENDERING_REPAIR"] == "1")
        #expect(profile.environment["FREETYPE_PROPERTIES"]?.contains("interpreter-version=35") == true)
        #expect(profile.environment["QT_OPENGL"] == "software")
        #expect(profile.environment["QT_QUICK_BACKEND"] == nil)
        #expect(profile.environment["QT_RHI_BACKEND"] == nil)
        #expect(profile.environment["QSG_RENDER_LOOP"] == "basic")
        #expect(profile.environment["QSG_RHI_BACKEND"] == "opengl")
        #expect(profile.environment["QT_ENABLE_HIGHDPI_SCALING"] == "0")
        #expect(profile.environment["QT_FONT_DPI"] == "96")
        #expect(profile.environment["MACWIN_AUTOMATED_UI_CLICK_REPAIR"] == nil)
        #expect(profile.environment["MACWIN_MUSESCORE_WELCOME_REPAIR"] == nil)
        #expect(profile.environment["MACWIN_SYNC_MUSESCORE_REGISTRY"] == nil)
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
        #expect(ApplicationCompatibilityProfile.matched(
            recipeId: "qgroundcontrol-drone",
            exePath: "C:\\Program Files\\QGroundControl\\bin\\QGroundControl.exe"
        ) == .qtRhiSoftware)
    }

    @Test("MuseScore profile carries app mode input repair")
    func museScoreProfileCarriesAppModeInputRepair() {
        let profile = ApplicationCompatibilityProfile.museScoreStudio

        #expect(profile.launchArguments == ["--session-type", "start-empty"])
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "musescore-studio")
        #expect(profile.environment["MACWIN_APP_MODE_INPUT_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_CLICK_THROUGH_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_AUTOMATED_UI_CLICK_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FORCE_MOUSE_FOCUS"] == "1")
        #expect(profile.environment["MACWIN_MOUSE_FOCUS_CLICK_AUTOMATION"] == "1")
        #expect(profile.environment["MACWIN_MUSESCORE_WELCOME_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_MUSESCORE_WELCOME_CLICK_AUTOMATION"] == "1")
        #expect(profile.environment["MACWIN_QT_RHI_SOFTWARE_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_RETINA_INPUT_REPAIR"] == "0")
        #expect(profile.environment["QT_ENABLE_HIGHDPI_SCALING"] == "0")
        #expect(profile.environment["QT_FONT_DPI"] == "96")
        #expect(profile.environment["QT_SCALE_FACTOR"] == "1")
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
    }

    @Test("Gmsh profile keeps OpenGL viewport launch stable")
    func gmshProfileKeepsOpenGLViewportLaunchStable() {
        let profile = ApplicationCompatibilityProfile.gmshOpenGL

        #expect(profile.launchArguments.isEmpty)
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "gmsh-opengl")
        #expect(profile.environment["MACWIN_APP_MODE_INPUT_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_ACTIVATE_WINE_APP"] == "1")
        #expect(profile.environment["MACWIN_FORCE_MOUSE_FOCUS"] == "1")
        #expect(profile.environment["MACWIN_FONTCONFIG_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(profile.environment["MACWIN_OPENGL_VIEWPORT_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_TEXT_RENDERING_REPAIR"] == "1")
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=vulkan,csmt=0x0")
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\gmsh-4.14.1-Windows64\\gmsh.exe") == .gmshOpenGL)
    }

    @Test("MeshLab profile deploys the bundled software OpenGL viewport")
    func meshLabProfileDeploysBundledSoftwareOpenGLViewport() {
        let profile = ApplicationCompatibilityProfile.meshLabSoftwareOpenGL

        #expect(profile.launchArguments.isEmpty)
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "meshlab-software-opengl")
        #expect(profile.environment["MACWIN_MESHLAB_SOFTWARE_OPENGL_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_OPENGL_VIEWPORT_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(profile.environment["LIBGL_ALWAYS_SOFTWARE"] == "1")
        #expect(profile.environment["QT_OPENGL"] == "software")
        #expect(profile.environment["ROSETTA_X87_PATH"] == "")
        #expect(profile.environment["WINEDLLOVERRIDES"] == "opengl32=n;winemenubuilder.exe=d")
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\MeshLab\\meshlab.exe") == .meshLabSoftwareOpenGL)
    }

    @Test("Bambu Studio profile deploys Mesa and the VS runtime")
    func bambuStudioProfileDeploysSoftwareOpenGLRuntime() {
        let profile = ApplicationCompatibilityProfile.bambuStudioSoftwareOpenGL

        #expect(profile.launchArguments.isEmpty)
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "bambu-studio-software-opengl")
        #expect(profile.environment["MACWIN_BAMBU_STUDIO_RUNTIME_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_OPENGL_VIEWPORT_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(profile.environment["GALLIUM_DRIVER"] == "llvmpipe")
        #expect(profile.environment["LIBGL_ALWAYS_SOFTWARE"] == "1")
        #expect(profile.environment["MESA_GL_VERSION_OVERRIDE"] == "4.5COMPAT")
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
        #expect(profile.environment["WINEDLLOVERRIDES"]?.contains("msvcp140_codecvt_ids") == true)
        #expect(ApplicationCompatibilityProfile.matched(
            exePath: "C:\\macwin-portable\\bambu-studio-portable\\bambu-studio.exe"
        ) == .bambuStudioSoftwareOpenGL)
    }

    @Test("OrcaSlicer profile uses native OpenGL and repairs blocked startup")
    func orcaSlicerProfileUsesNativeOpenGLAndRepairsStartup() {
        let profile = ApplicationCompatibilityProfile.orcaSlicerNativeOpenGL

        #expect(profile.launchArguments.isEmpty)
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "orcaslicer-native-opengl")
        #expect(profile.environment["MACWIN_ORCASLICER_RUNTIME_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_OPENGL_VIEWPORT_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
        #expect(profile.environment["WINEDLLOVERRIDES"] == "winemenubuilder.exe=d")
        #expect(ApplicationCompatibilityProfile.matched(
            exePath: "C:\\Program Files\\OrcaSlicer\\orca-slicer.exe"
        ) == .orcaSlicerNativeOpenGL)
    }

    @Test("Qucs-S profile keeps Qt6 engineering apps in executable directory")
    func qucsSProfileKeepsQt6EngineeringAppsInExecutableDirectory() {
        let profile = ApplicationCompatibilityProfile.qucsSQt6

        #expect(profile.launchArguments.isEmpty)
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "qucs-s-qt6")
        #expect(profile.environment["MACWIN_APP_MODE_INPUT_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_ACTIVATE_WINE_APP"] == "1")
        #expect(profile.environment["MACWIN_FORCE_MOUSE_FOCUS"] == "1")
        #expect(profile.environment["MACWIN_FONTCONFIG_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FONT_FALLBACK_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(profile.environment["MACWIN_QT_WIDGETS_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_TEXT_RENDERING_REPAIR"] == "1")
        #expect(profile.environment["PATH"]?.contains("Qucs-S-26.1.1-win64\\bin") == true)
        #expect(profile.environment["QT_PLUGIN_PATH"] == "C:\\Program Files\\Qucs-S-26.1.1-win64\\bin")
        #expect(profile.environment["QT_QPA_PLATFORM_PLUGIN_PATH"] == "C:\\Program Files\\Qucs-S-26.1.1-win64\\bin\\platforms")
        #expect(profile.environment["QT_STYLE_OVERRIDE"] == "Fusion")
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\Qucs-S-26.1.1-win64\\bin\\qucs-s.exe") == .qucsSQt6)
    }

    @Test("Qt browser profile keeps portable browsers on software Qt rendering")
    func qtBrowserProfileKeepsPortableBrowsersOnSoftwareQtRendering() {
        let profile = ApplicationCompatibilityProfile.qtBrowserSoftware

        #expect(profile.launchArguments.isEmpty)
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "qt-browser-software")
        #expect(profile.environment["MACWIN_QT_BROWSER_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_APP_MODE_INPUT_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_ACTIVATE_WINE_APP"] == "1")
        #expect(profile.environment["MACWIN_FORCE_MOUSE_FOCUS"] == "1")
        #expect(profile.environment["MACWIN_FONTCONFIG_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FONT_FALLBACK_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(profile.environment["MACWIN_TEXT_RENDERING_REPAIR"] == "1")
        #expect(profile.environment["QT_OPENGL"] == "software")
        #expect(profile.environment["QT_QUICK_BACKEND"] == "software")
        #expect(profile.environment["QT_STYLE_OVERRIDE"] == "Fusion")
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
        #expect(profile.environment["MACWIN_MUSESCORE_WELCOME_REPAIR"] == nil)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\macwin-portable\\otter-browser-portable\\otter-browser-win64-weekly120\\otter-browser.exe") == .qtBrowserSoftware)
    }

    @Test("Qt widgets profile keeps small industrial tools on stable managed defaults")
    func qtWidgetsProfileKeepsSmallIndustrialToolsOnStableManagedDefaults() {
        let profile = ApplicationCompatibilityProfile.qtWidgetsSoftware

        #expect(profile.launchArguments.isEmpty)
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "qt-widgets-software")
        #expect(profile.environment["MACWIN_QT_WIDGETS_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_APP_MODE_INPUT_REPAIR"] == nil)
        #expect(profile.environment["MACWIN_ACTIVATE_WINE_APP"] == nil)
        #expect(profile.environment["MACWIN_FORCE_MOUSE_FOCUS"] == nil)
        #expect(profile.environment["MACWIN_FONTCONFIG_REPAIR"] == nil)
        #expect(profile.environment["MACWIN_FONT_FALLBACK_REPAIR"] == nil)
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == nil)
        #expect(profile.environment["MACWIN_TEXT_RENDERING_REPAIR"] == nil)
        #expect(profile.environment["QT_OPENGL"] == nil)
        #expect(profile.environment["QT_QUICK_BACKEND"] == nil)
        #expect(profile.environment["QT_STYLE_OVERRIDE"] == nil)
        #expect(profile.environment["WINE_D3D_CONFIG"] == nil)
        #expect(profile.environment["WINEDEBUG"] == "-all")
        #expect(profile.environment["MACWIN_MUSESCORE_WELCOME_REPAIR"] == nil)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\macwin-portable\\qmodmaster-32\\qModMaster\\qModMaster.exe") == .qtWidgetsSoftware)
        #expect(ApplicationCompatibilityProfile.matched(recipeId: "sqlitestudio", exePath: "C:\\Program Files\\SQLiteStudio\\SQLiteStudio.exe") == .qtWidgetsSoftware)
    }

    @Test("SoftMaker profile enables COM proxy repair")
    func softMakerProfileEnablesCOMProxyRepair() {
        let profile = ApplicationCompatibilityProfile.softMakerOffice

        #expect(profile.launchArguments.isEmpty)
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "softmaker-office")
        #expect(profile.environment["MACWIN_COM_PROXY_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_SOFTMAKER_OFFICE_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_ACTIVATE_WINE_APP"] == "1")
        #expect(profile.environment["MACWIN_FONTCONFIG_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FONT_FALLBACK_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FORCE_MOUSE_FOCUS"] == "1")
        #expect(profile.environment["MACWIN_TEXT_RENDERING_REPAIR"] == "1")
        #expect(profile.environment["FREETYPE_PROPERTIES"]?.contains("interpreter-version=35") == true)
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=vulkan,csmt=0x0")
    }

    @Test("Office suite profile keeps LibreOffice launchers on stable document UI settings")
    func officeSuiteProfileKeepsLibreOfficeLaunchersOnStableDocumentUISettings() {
        let profile = ApplicationCompatibilityProfile.officeSuite

        #expect(profile.launchArguments == ["--norestore", "--nodefault", "--nolockcheck"])
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "office-suite")
        #expect(profile.environment["MACWIN_OFFICE_SUITE_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_APP_MODE_INPUT_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FORCE_MOUSE_FOCUS"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(profile.environment["MACWIN_FONTCONFIG_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FONT_FALLBACK_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_TEXT_RENDERING_REPAIR"] == "1")
        #expect(profile.environment["SAL_USE_VCLPLUGIN"] == "win")
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
        #expect(ApplicationCompatibilityProfile.matched(recipeId: "libreoffice", exePath: "C:\\Program Files\\LibreOffice\\program\\swriter.exe") == .officeSuite)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\LibreOffice\\program\\scalc.exe") == .officeSuite)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\LibreOffice\\program\\simpress.exe") == .officeSuite)
    }

    @Test("WPS Office profile keeps Writer on its native Qt document path")
    func wpsOfficeProfileUsesNativeDocumentArgumentsAndCJKRepairs() {
        let profile = ApplicationCompatibilityProfile.wpsOffice

        #expect(profile.launchArguments.isEmpty)
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "wps-office")
        #expect(profile.environment["MACWIN_WPS_OFFICE_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FONTCONFIG_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FONT_FALLBACK_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_TEXT_RENDERING_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(profile.environment["QT_FONT_DPI"] == "96")
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
        #expect(ApplicationCompatibilityProfile.matched(recipeId: "wps-office") == .wpsOffice)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\Kingsoft\\WPS Office\\12.1.0.27458\\office6\\wps.exe") == .wpsOffice)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\Kingsoft\\WPS Office\\12.1.0.27458\\office6\\et.exe") == .wpsOffice)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\Kingsoft\\WPS Office\\12.1.0.27458\\office6\\wpp.exe") == .wpsOffice)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\Kingsoft\\WPS Office\\12.1.0.27458\\office6\\wpspdf.exe") == .wpsOffice)
    }

    @Test("TeXstudio profile carries Qt6 software rendering repair")
    func texStudioProfileCarriesQt6SoftwareRenderingRepair() {
        let profile = ApplicationCompatibilityProfile.texStudioQt6

        #expect(profile.launchArguments == ["--no-session", "-platform", "windows:fontengine=freetype"])
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "texstudio-qt6")
        #expect(profile.environment["MACWIN_TEXSTUDIO_QT6_REPAIR"] == "1")
        #expect(profile.environment["MACWIN_FORCE_MOUSE_FOCUS"] == "1")
        #expect(profile.environment["QT_OPENGL"] == "software")
        #expect(profile.environment["QT_QUICK_BACKEND"] == "software")
        #expect(profile.environment["QT_STYLE_OVERRIDE"] == "windows")
        #expect(profile.environment["QT_ENABLE_HIGHDPI_SCALING"] == "0")
        #expect(profile.environment["QT_FONT_DPI"] == "96")
        #expect(profile.environment["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
    }

    @Test("7-Zip profile disables global D3D preset for GDI tools")
    func sevenZipProfileDisablesGlobalD3DPresetForGDITools() {
        let profile = ApplicationCompatibilityProfile.sevenZipGDI

        #expect(profile.launchArguments.isEmpty)
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "7zip-gdi")
        #expect(profile.environment["MACWIN_ACTIVATE_WINE_APP"] == "0")
        #expect(profile.environment["MACWIN_APP_MODE_INPUT_REPAIR"] == "0")
        #expect(profile.environment["MACWIN_DISABLE_WINE_APP_ACTIVATION"] == "1")
        #expect(profile.environment["MACWIN_DISABLE_WINE_D3D_CONFIG"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == nil)
        #expect(profile.environment["WINE_D3D_CONFIG"] == "")
        #expect(ApplicationCompatibilityProfile.matched(recipeId: "7zip") == .sevenZipGDI)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\7-Zip\\7zFM.exe") == .sevenZipGDI)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\7-Zip\\7zG.exe") == .sevenZipGDI)
    }

    @Test("Notepad++ profile disables MacWin app activation crash path")
    func notepadPlusPlusProfileDisablesMacWinAppActivationCrashPath() {
        let profile = ApplicationCompatibilityProfile.notepadPlusPlusGDI

        #expect(profile.launchArguments.isEmpty)
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "notepad-plus-plus-gdi")
        #expect(profile.environment["MACWIN_ACTIVATE_WINE_APP"] == "0")
        #expect(profile.environment["MACWIN_APP_MODE_INPUT_REPAIR"] == "0")
        #expect(profile.environment["MACWIN_DISABLE_WINE_APP_ACTIVATION"] == "1")
        #expect(profile.environment["MACWIN_DISABLE_WINE_D3D_CONFIG"] == "1")
        #expect(profile.environment["WINE_D3D_CONFIG"] == "")
        #expect(ApplicationCompatibilityProfile.matched(recipeId: "notepad-plus-plus") == .notepadPlusPlusGDI)
        #expect(ApplicationCompatibilityProfile.matched(displayName: "Notepad++") == .notepadPlusPlusGDI)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\Notepad++\\notepad++.exe") == .notepadPlusPlusGDI)
    }

    @Test("PortableApps platform profile disables uxtheme SEH crash path")
    func portableAppsPlatformProfileDisablesUxthemeSEHCrashPath() {
        let profile = ApplicationCompatibilityProfile.portableAppsPlatform

        #expect(profile.launchArguments.isEmpty)
        #expect(profile.environment["MACWIN_COMPAT_PROFILE"] == "portableapps-platform")
        #expect(profile.environment["MACWIN_DISABLE_WINE_D3D_CONFIG"] == "1")
        #expect(profile.environment["MACWIN_LAUNCH_CWD"] == "executable-dir")
        #expect(profile.environment["MACWIN_PORTABLEAPPS_PLATFORM_REPAIR"] == "1")
        #expect(profile.environment["WINEDLLOVERRIDES"] == "winemenubuilder.exe=d;uxtheme=d")
        #expect(profile.environment["WINE_D3D_CONFIG"] == "")
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\PortableApps\\PortableApps.com\\PortableAppsPlatform.exe") == .portableAppsPlatform)
    }

    @Test("Profile matching recognizes known launchers")
    func profileMatchingRecognizesKnownLaunchers() {
        #expect(ApplicationCompatibilityProfile.matched(launcherId: "steam") == .steamClient)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\Steam\\Steam.exe") == .steamClient)
        #expect(ApplicationCompatibilityProfile.matched(launcherId: "lenovo-app-store-pcyyb") == .lenovoAppStore)
        #expect(ApplicationCompatibilityProfile.matched(displayName: "联想应用商店 / 应用宝") == .lenovoAppStore)
        #expect(ApplicationCompatibilityProfile.matched(recipeId: "tencent-app-store") == .tencentAppStore)
        #expect(ApplicationCompatibilityProfile.matched(displayName: "应用宝 / 腾讯应用市场") == .tencentAppStore)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files (x86)\\Tencent\\QQPCMgr\\QQPCMgr.exe") == .tencentAppStore)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Users\\a\\Downloads\\QQPhoneManager-5.8.3_990420.5400.n.exe") == .tencentAppStore)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\Tencent\\Androws\\Application\\AndrowsLauncher.exe") == .tencentAppStore)
        #expect(ApplicationCompatibilityProfile.matched(launcherId: "local-c-program-files-tencent-androws-application-androwslauncher-exe") == .tencentAppStore)
        #expect(ApplicationCompatibilityProfile.matched(recipeId: "hoyoplay-cn", exePath: "C:\\Program Files\\miHoYo Launcher\\1.16.1.364\\HYP.exe") == .hoYoPlay)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Users\\a\\AppData\\Local\\BraveSoftware\\Brave-Browser\\Application\\brave.exe") == .chromiumBrowser)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe") == .chromiumBrowser)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe") == .chromiumBrowser)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\macwin-portable\\opera-browser\\opera.exe") == .chromiumBrowser)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\Opera\\opera.exe") == .chromiumBrowser)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\Mozilla Firefox\\firefox.exe") == .browserGecko)
        #expect(ApplicationCompatibilityProfile.matched(recipeId: "jasp-stats", exePath: "C:\\Program Files\\JASP\\JASPDesktop.exe") == .jaspQtWebEngineQrc)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\MeshLab\\meshlab.exe") == .meshLabSoftwareOpenGL)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\MuseScore 4\\bin\\MuseScore4.exe") == .museScoreStudio)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\Qucs-S-26.1.1-win64\\bin\\qucs-s.exe") == .qucsSQt6)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\macwin-portable\\otter-browser-portable\\otter-browser-win64-weekly120\\otter-browser.exe") == .qtBrowserSoftware)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\macwin-portable\\qmodmaster-32\\qModMaster\\qModMaster.exe") == .qtWidgetsSoftware)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\SQLiteStudio\\SQLiteStudio.exe") == .qtWidgetsSoftware)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files (x86)\\SoftMaker FreeOffice 2024\\TextMaker.exe") == .softMakerOffice)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\SoftMaker Office 2024\\PlanMaker.exe") == .softMakerOffice)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\TeXstudio\\texstudio.exe") == .texStudioQt6)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\Notepad++\\notepad++.exe") == .notepadPlusPlusGDI)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\PortableApps\\PortableApps.com\\PortableAppsPlatform.exe") == .portableAppsPlatform)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\PortableApps\\PortableApps.com\\PortableAppsBackup.exe") == .portableAppsUtility)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\PortableApps\\PortableApps.com\\PortableAppsUpdater.exe") == .portableAppsUtility)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\7-Zip\\7zFM.exe") == .sevenZipGDI)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\Program Files\\LibreOffice\\program\\swriter.exe") == .officeSuite)
        #expect(ApplicationCompatibilityProfile.matched(launcherId: "supermium-32-browser") == .supermium32Browser)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\macwin-portable\\supermium-32-browser\\Supermium\\chrome.exe") == .supermium32Browser)
        #expect(ApplicationCompatibilityProfile.matched(launcherId: "mremoteng-1782-x64") == .mRemoteNG1782)
        #expect(ApplicationCompatibilityProfile.matched(exePath: "C:\\macwin-portable\\mremoteng-1782-x64\\mRemoteNG.exe") == .mRemoteNG1782)
        #expect(ApplicationCompatibilityProfile.matched(displayName: "itch.io 游戏市场") == .cefSoftwareRenderer)
    }

    @Test("Current profile prefers explicit launcher metadata")
    func currentProfilePrefersExplicitLauncherMetadata() {
        let steam = LauncherManifest(
            id: "custom",
            appId: "custom",
            bottleId: "bottle",
            displayName: "Custom Steam",
            exePath: "C:\\Tools\\Steam.exe",
            envOverrides: ["MACWIN_COMPAT_PROFILE": "steam-client"]
        )
        let cef = LauncherManifest(
            id: "custom",
            appId: "custom",
            bottleId: "bottle",
            displayName: "Custom",
            exePath: "C:\\Tools\\app.exe",
            envOverrides: ["MACWIN_COMPAT_PROFILE": "cef-software-gl"]
        )
        let hoYoPlay = LauncherManifest(
            id: "custom",
            appId: "custom",
            bottleId: "bottle",
            displayName: "HoYoPlay",
            exePath: "C:\\Tools\\HYP.exe",
            envOverrides: ["MACWIN_COMPAT_PROFILE": "hoyoplay-webview"]
        )
        let chromium = LauncherManifest(
            id: "custom",
            appId: "custom",
            bottleId: "bottle",
            displayName: "Brave",
            exePath: "C:\\Tools\\brave.exe",
            envOverrides: ["MACWIN_COMPAT_PROFILE": "chromium-browser"]
        )
        let qt = LauncherManifest(
            id: "custom",
            appId: "custom",
            bottleId: "bottle",
            displayName: "MuseScore",
            exePath: "C:\\Tools\\MuseScore4.exe",
            envOverrides: ["MACWIN_COMPAT_PROFILE": "qt-rhi-software"]
        )
        let softMaker = LauncherManifest(
            id: "custom",
            appId: "custom",
            bottleId: "bottle",
            displayName: "TextMaker",
            exePath: "C:\\Tools\\TextMaker.exe",
            envOverrides: ["MACWIN_COMPAT_PROFILE": "softmaker-office"]
        )
        let qucsS = LauncherManifest(
            id: "local-c-program-files-qucs-s-26-1-1-win64-bin-qucs-s-exe",
            appId: "local-high-performance-win11",
            bottleId: "bottle",
            displayName: "qucs-s",
            exePath: "C:\\Program Files\\Qucs-S-26.1.1-win64\\bin\\qucs-s.exe",
            envOverrides: ["MACWIN_COMPAT_PROFILE": "qucs-s-qt6"]
        )
        let texStudio = LauncherManifest(
            id: "custom",
            appId: "custom",
            bottleId: "bottle",
            displayName: "TeXstudio",
            exePath: "C:\\Tools\\texstudio.exe",
            envOverrides: ["MACWIN_COMPAT_PROFILE": "texstudio-qt6"]
        )
        let jasp = LauncherManifest(
            id: "jasp-stats",
            appId: "industrial",
            bottleId: "bottle",
            displayName: "JASP",
            exePath: "C:\\Program Files\\JASP\\JASPDesktop.exe",
            envOverrides: ["MACWIN_COMPAT_PROFILE": "jasp-qtwebengine-qrc"]
        )
        let supermium32 = LauncherManifest(
            id: "supermium-32-browser",
            appId: "browser",
            bottleId: "bottle",
            displayName: "Supermium 32-bit",
            exePath: "C:\\macwin-portable\\supermium-32-browser\\Supermium\\chrome.exe",
            envOverrides: ["MACWIN_COMPAT_PROFILE": "supermium-32-browser"]
        )
        let mRemoteNG = LauncherManifest(
            id: "mremoteng-1782-x64",
            appId: "industrial",
            bottleId: "bottle",
            displayName: "mRemoteNG 1.78.2",
            exePath: "C:\\macwin-portable\\mremoteng-1782-x64\\mRemoteNG.exe",
            envOverrides: ["MACWIN_COMPAT_PROFILE": "mremoteng-1782-x64"]
        )
        let sevenZip = LauncherManifest(
            id: "7zip-file-manager",
            appId: "7zip",
            bottleId: "bottle",
            displayName: "7-Zip File Manager",
            exePath: "C:\\Program Files\\7-Zip\\7zFM.exe",
            envOverrides: ["MACWIN_COMPAT_PROFILE": "7zip-gdi"]
        )
        let notepadPlusPlus = LauncherManifest(
            id: "notepad-plus-plus",
            appId: "notepad-plus-plus",
            bottleId: "bottle",
            displayName: "Notepad++",
            exePath: "C:\\Program Files\\Notepad++\\notepad++.exe",
            envOverrides: ["MACWIN_COMPAT_PROFILE": "notepad-plus-plus-gdi"]
        )
        let portableAppsUpdater = LauncherManifest(
            id: "portableapps-updater",
            appId: "portableapps-platform",
            bottleId: "bottle",
            displayName: "PortableApps Updater",
            exePath: "C:\\PortableApps\\PortableApps.com\\PortableAppsUpdater.exe",
            envOverrides: ["MACWIN_COMPAT_PROFILE": "portableapps-utility"]
        )
        let portableAppsPlatform = LauncherManifest(
            id: "portableapps-platform",
            appId: "portableapps-platform",
            bottleId: "bottle",
            displayName: "PortableApps.com Platform",
            exePath: "C:\\PortableApps\\PortableApps.com\\PortableAppsPlatform.exe",
            envOverrides: ["MACWIN_COMPAT_PROFILE": "portableapps-platform"]
        )
        let staleAndrows = LauncherManifest(
            id: "local-c-program-files-tencent-androws-application-androwslauncher-exe",
            appId: "local-high-performance-win11",
            bottleId: "bottle",
            displayName: "AndrowsLauncher",
            exePath: "C:\\Program Files\\Tencent\\Androws\\Application\\AndrowsLauncher.exe",
            envOverrides: ["MACWIN_COMPAT_PROFILE": "cef-software-gl"]
        )

        #expect(ApplicationCompatibilityProfile.current(in: steam) == .steamClient)
        #expect(ApplicationCompatibilityProfile.current(in: cef) == .cefSoftwareRenderer)
        #expect(ApplicationCompatibilityProfile.current(in: hoYoPlay) == .hoYoPlay)
        #expect(ApplicationCompatibilityProfile.current(in: chromium) == .chromiumBrowser)
        #expect(ApplicationCompatibilityProfile.current(in: qt) == .qtRhiSoftware)
        let otter = LauncherManifest(
            id: "local-c-macwin-portable-otter-browser-portable-otter-browser-win64-weekly120-otter-browser-exe",
            appId: "local-high-performance-win11",
            bottleId: "bottle",
            displayName: "otter-browser",
            exePath: "C:\\macwin-portable\\otter-browser-portable\\otter-browser-win64-weekly120\\otter-browser.exe",
            envOverrides: ["MACWIN_COMPAT_PROFILE": "qt-browser-software"]
        )
        #expect(ApplicationCompatibilityProfile.current(in: otter) == .qtBrowserSoftware)
        let qModMaster = LauncherManifest(
            id: "local-c-macwin-portable-qmodmaster-32-qmodmaster-qmodmaster-exe",
            appId: "local-high-performance-win11",
            bottleId: "bottle",
            displayName: "qModMaster",
            exePath: "C:\\macwin-portable\\qmodmaster-32\\qModMaster\\qModMaster.exe",
            envOverrides: ["MACWIN_COMPAT_PROFILE": "qt-widgets-software"]
        )
        #expect(ApplicationCompatibilityProfile.current(in: qModMaster) == .qtWidgetsSoftware)
        #expect(ApplicationCompatibilityProfile.current(in: qucsS) == .qucsSQt6)
        #expect(ApplicationCompatibilityProfile.current(in: softMaker) == .softMakerOffice)
        #expect(ApplicationCompatibilityProfile.current(in: texStudio) == .texStudioQt6)
        #expect(ApplicationCompatibilityProfile.current(in: jasp) == .jaspQtWebEngineQrc)
        #expect(ApplicationCompatibilityProfile.current(in: supermium32) == .supermium32Browser)
        #expect(ApplicationCompatibilityProfile.current(in: mRemoteNG) == .mRemoteNG1782)
        #expect(ApplicationCompatibilityProfile.current(in: sevenZip) == .sevenZipGDI)
        #expect(ApplicationCompatibilityProfile.current(in: notepadPlusPlus) == .notepadPlusPlusGDI)
        #expect(ApplicationCompatibilityProfile.current(in: portableAppsPlatform) == .portableAppsPlatform)
        #expect(ApplicationCompatibilityProfile.current(in: portableAppsUpdater) == .portableAppsUtility)
        #expect(ApplicationCompatibilityProfile.current(in: staleAndrows) == .tencentAppStore)
    }

    @Test("Applying a profile replaces earlier profile arguments and environment")
    func applyingProfileReplacesEarlierProfileArgumentsAndEnvironment() {
        let launcher = LauncherManifest(
            id: "app",
            appId: "app",
            bottleId: "bottle",
            displayName: "App",
            exePath: "C:\\App\\app.exe",
            args: ApplicationCompatibilityProfile.cefSoftwareRenderer.launchArguments + ["--user-flag"],
            envOverrides: ApplicationCompatibilityProfile.cefSoftwareRenderer.environment.merging(
                ["CUSTOM": "1"],
                uniquingKeysWith: { _, new in new }
            )
        )

        let updated = ApplicationCompatibilityProfile.steamClient.applied(to: launcher)

        #expect(updated.args == ApplicationCompatibilityProfile.steamClient.launchArguments + ["--user-flag"])
        #expect(updated.envOverrides["MACWIN_COMPAT_PROFILE"] == "steam-client")
        #expect(updated.envOverrides["MACWIN_FORCE_MOUSE_FOCUS"] == "1")
        #expect(updated.envOverrides["WINEDLLOVERRIDES"] == "wbemprox=d")
        #expect(updated.envOverrides["CUSTOM"] == "1")
    }

    @Test("Applying a profile strips obsolete text rendering arguments")
    func applyingProfileStripsObsoleteTextRenderingArguments() {
        let launcher = LauncherManifest(
            id: "hoyoplay",
            appId: "hoyoplay-cn",
            bottleId: "bottle",
            displayName: "HoYoPlay",
            exePath: "C:\\Program Files\\miHoYo Launcher\\1.16.1.364\\HYP.exe",
            args: [
                "--disable-direct-write",
                "--disable-directwrite-for-ui",
                "--disable-remote-fonts",
                "--disable-font-subpixel-positioning",
                "--disable-lcd-text",
                "--disable-prefer-compositing-to-lcd-text",
                "--font-render-hinting=none",
                "--use-angle=swiftshader-webgl",
                "--disable-skia-runtime-opts",
                "--disable-features=CalculateNativeWinOcclusion,DWriteFontProxy,UseDWriteCore,UseSkiaRenderer,UserFeature",
                "--user-flag"
            ],
            envOverrides: [
                "QTWEBENGINE_CHROMIUM_FLAGS": "--disable-direct-write --disable-lcd-text --font-render-hinting=none",
                "MACWIN_CHROMIUM_HELPER_ARGS": "--disable-font-subpixel-positioning --disable-features=DWriteFontProxy,UseDWriteCore",
                "WINEDLLOVERRIDES": "qone,wbemprox=d;dwrite,usp10=b",
                "CUSTOM": "1"
            ]
        )

        let updated = ApplicationCompatibilityProfile.hoYoPlay.applied(to: launcher)

        #expect(!updated.args.contains("--disable-direct-write"))
        #expect(!updated.args.contains("--disable-directwrite-for-ui"))
        #expect(!updated.args.contains("--disable-remote-fonts"))
        #expect(!updated.args.contains("--disable-font-subpixel-positioning"))
        #expect(!updated.args.contains("--disable-lcd-text"))
        #expect(!updated.args.contains("--disable-prefer-compositing-to-lcd-text"))
        #expect(!updated.args.contains("--font-render-hinting=none"))
        #expect(!updated.args.contains("--use-angle=swiftshader-webgl"))
        #expect(!updated.args.contains("--disable-skia-runtime-opts"))
        #expect(updated.args.contains("--disable-features=CalculateNativeWinOcclusion,UserFeature"))
        #expect(updated.args.contains("--user-flag"))
        #expect(!updated.args.contains("--use-gl=angle"))
        #expect(updated.envOverrides["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--disable-direct-write") == false)
        #expect(updated.envOverrides["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--disable-lcd-text") == false)
        #expect(updated.envOverrides["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--font-render-hinting=none") == false)
        #expect(updated.envOverrides["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("--disable-font-subpixel-positioning") == false)
        #expect(updated.envOverrides["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("DWriteFontProxy") == false)
        #expect(updated.envOverrides["WINEDLLOVERRIDES"] == "qone,wbemprox=d")
        #expect(updated.envOverrides["CUSTOM"] == "1")
    }

    @Test("Obsolete flag scan only reports disabled Chromium text features")
    func obsoleteFlagScanOnlyReportsDisabledChromiumTextFeatures() {
        let enabled = ApplicationCompatibilityProfile.obsoleteTextRenderingFlags(
            in: "--enable-features=FontSrcLocalMatching --disable-features=CalculateNativeWinOcclusion"
        )
        let disabled = ApplicationCompatibilityProfile.obsoleteTextRenderingFlags(
            in: "--enable-features=FontSrcLocalMatching --disable-features=DWriteFontProxy,FontSrcLocalMatching,UseDWriteCore"
        )

        #expect(enabled.isEmpty)
        #expect(disabled.contains("DWriteFontProxy"))
        #expect(disabled.contains("FontSrcLocalMatching"))
        #expect(disabled.contains("UseDWriteCore"))
    }

    @Test("Sanitizing launch arguments merges duplicate Chromium disabled feature flags")
    func sanitizingLaunchArgumentsMergesDuplicateChromiumDisabledFeatureFlags() {
        let sanitized = ApplicationCompatibilityProfile.sanitizedLaunchArguments([
            "--disable-gpu",
            "--disable-features=CalculateNativeWinOcclusion,DWriteFontProxy,Vulkan",
            "--disable-features=Vulkan,WebGPU,CustomFeature",
            "--disable-gpu",
            "--user-flag"
        ])

        #expect(sanitized == [
            "--disable-gpu",
            "--disable-features=CalculateNativeWinOcclusion,Vulkan,WebGPU,CustomFeature",
            "--user-flag"
        ])
    }

    @Test("Applying Chromium profile folds user disabled features into managed flag")
    func applyingChromiumProfileFoldsUserDisabledFeaturesIntoManagedFlag() {
        let launcher = LauncherManifest(
            id: "itch",
            appId: "itch-io-game-market",
            bottleId: "bottle",
            displayName: "itch.io",
            exePath: "C:\\users\\a1-6\\AppData\\Local\\itch\\app-26.13.0\\itch.exe",
            args: ["--disable-features=Vulkan,WebGPU,CustomFeature"]
        )

        let updated = ApplicationCompatibilityProfile.cefSoftwareRenderer.applied(to: launcher)
        let disabledFeatureFlags = updated.args.filter { $0.hasPrefix("--disable-features=") }

        #expect(disabledFeatureFlags.count == 1)
        #expect(disabledFeatureFlags[0].contains("CalculateNativeWinOcclusion"))
        #expect(disabledFeatureFlags[0].contains("Vulkan"))
        #expect(disabledFeatureFlags[0].contains("WebGPU"))
        #expect(disabledFeatureFlags[0].contains("CustomFeature"))
        #expect(!updated.args.contains("--disable-features=Vulkan,WebGPU,CustomFeature"))
        #expect(updated.envOverrides["ELECTRON_ENABLE_LOGGING"] == "1")
        #expect(updated.envOverrides["ELECTRON_FORCE_IS_PACKAGED"] == "1")
        #expect(updated.envOverrides["ROSETTA_X87_PATH"] == "")
    }

    @Test("Npackd portable launcher uses stable x64 Qt widgets environment")
    func npackdPortableLauncherUsesStableX64QtWidgetsEnvironment() {
        let launcher = LauncherManifest(
            id: "npackd",
            appId: "npackd",
            bottleId: "bottle",
            displayName: "Npackd",
            exePath: "C:\\macwin-portable\\npackd\\npackdg.exe"
        )

        let profile = ApplicationCompatibilityProfile.matched(
            recipeId: launcher.appId,
            launcherId: launcher.id,
            displayName: launcher.displayName,
            exePath: launcher.exePath
        )
        #expect(profile == .qtWidgetsSoftware)

        let updated = try! #require(profile).applied(to: launcher)
        #expect(updated.envOverrides["ROSETTA_X87_PATH"] == "")
        #expect(updated.envOverrides["LANG"] == "zh_CN.UTF-8")
        #expect(updated.envOverrides["MACWIN_NPACKD_CATALOG_REPAIR"] == "1")
        #expect(updated.envOverrides["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
    }

    @Test("Cura slicer keeps its native OpenGL viewport and disables unstable online plugins")
    func curaSlicerUsesDedicatedOpenGLProfile() {
        let launcher = LauncherManifest(
            id: "cura-slicer",
            appId: "maker-streaming-pack",
            bottleId: "bottle",
            displayName: "UltiMaker Cura 5.13",
            exePath: "C:\\Program Files\\UltiMaker Cura 5.13.0\\UltiMaker-Cura.exe"
        )

        let profile = ApplicationCompatibilityProfile.matched(
            recipeId: launcher.appId,
            launcherId: launcher.id,
            displayName: launcher.displayName,
            exePath: launcher.exePath
        )
        #expect(profile == .curaSlicer)
        let updated = try! #require(profile).applied(to: launcher)
        #expect(updated.envOverrides["MACWIN_CURA_PROFILE_REPAIR"] == "1")
        #expect(updated.envOverrides["QT_OPENGL"] == "desktop")
        #expect(updated.envOverrides["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
        #expect(updated.envOverrides["MACWIN_LAUNCH_CWD"] == "executable-dir")
    }

    @Test("Krita keeps native Qt OpenGL and avoids the 32-bit Rosetta x87 shim")
    func kritaUsesDedicatedOpenGLProfile() {
        let launcher = LauncherManifest(
            id: "krita-paint",
            appId: "creative-extended-pack",
            bottleId: "bottle",
            displayName: "Krita 5.2.9",
            exePath: "C:\\Program Files\\Krita (x64)\\bin\\krita.exe"
        )

        let profile = ApplicationCompatibilityProfile.matched(
            recipeId: launcher.appId,
            launcherId: launcher.id,
            displayName: launcher.displayName,
            exePath: launcher.exePath
        )
        #expect(profile == .kritaOpenGL)
        let updated = try! #require(profile).applied(to: launcher)
        #expect(updated.envOverrides["MACWIN_KRITA_OPENGL_REPAIR"] == "1")
        #expect(updated.envOverrides["QT_OPENGL"] == "desktop")
        #expect(updated.envOverrides["PYTHONHASHSEED"] == "0")
        #expect(updated.envOverrides["ROSETTA_X87_PATH"] == "")
        #expect(updated.envOverrides["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
        #expect(updated.envOverrides["MACWIN_LAUNCH_CWD"] == "executable-dir")
    }

    @Test("Clearing a profile removes managed values and disables automatic matching")
    func clearingProfileRemovesManagedValuesAndDisablesAutomaticMatching() {
        let launcher = LauncherManifest(
            id: "steam",
            appId: "steam",
            bottleId: "bottle",
            displayName: "Steam",
            exePath: "C:\\Program Files\\Steam\\Steam.exe",
            args: ApplicationCompatibilityProfile.steamClient.launchArguments + ["-user"],
            envOverrides: ApplicationCompatibilityProfile.steamClient.environment.merging(
                ["CUSTOM": "1"],
                uniquingKeysWith: { _, new in new }
            )
        )

        let cleared = ApplicationCompatibilityProfile.cleared(from: launcher)

        #expect(cleared.args == ["-user"])
        #expect(cleared.envOverrides["MACWIN_COMPAT_PROFILE"] == ApplicationCompatibilityProfile.disabledProfileValue)
        #expect(cleared.envOverrides["MACWIN_FORCE_MOUSE_FOCUS"] == nil)
        #expect(cleared.envOverrides["CUSTOM"] == "1")
        #expect(ApplicationCompatibilityProfile.current(in: cleared) == nil)
    }

    @Test("Clearing a profile also strips obsolete text rendering arguments")
    func clearingProfileAlsoStripsObsoleteTextRenderingArguments() {
        let launcher = LauncherManifest(
            id: "steam",
            appId: "steam",
            bottleId: "bottle",
            displayName: "Steam",
            exePath: "C:\\Program Files\\Steam\\Steam.exe",
            args: ApplicationCompatibilityProfile.steamClient.launchArguments + [
                "--disable-direct-write",
                "--disable-features=DWriteFontProxy,UseDWriteCore,CustomFeature",
                "-user"
            ],
            envOverrides: ApplicationCompatibilityProfile.steamClient.environment
        )

        let cleared = ApplicationCompatibilityProfile.cleared(from: launcher)

        #expect(cleared.args == ["--disable-features=CustomFeature", "-user"])
        #expect(cleared.envOverrides["MACWIN_COMPAT_PROFILE"] == ApplicationCompatibilityProfile.disabledProfileValue)
    }
}
