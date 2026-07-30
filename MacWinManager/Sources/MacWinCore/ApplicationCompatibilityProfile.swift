import Foundation

public enum ApplicationCompatibilityProfile: String, Codable, CaseIterable, Sendable {
    case bambuStudioSoftwareOpenGL = "bambu-studio-software-opengl"
    case blenderSoftwareOpenGL = "blender-software-opengl"
    case browserGecko = "browser-gecko"
    case cefSoftwareRenderer = "cef-software-renderer"
    case chromiumBrowser = "chromium-browser"
    case curaSlicer = "cura-slicer"
    case dbeaverSWT = "dbeaver-swt"
    case freeCADOpenGL = "freecad-opengl"
    case kiCadEDA = "kicad-eda"
    case libreCADQt = "librecad-qt"
    case kritaOpenGL = "krita-opengl"
    case geogebraLegacyElectron32 = "geogebra-electron32"
    case gmshOpenGL = "gmsh-opengl"
    case hoYoPlay = "hoyoplay-webview"
    case jabRefJavaFXD3D = "jabref-javafx-d3d"
    case jaspQtWebEngineQrc = "jasp-qtwebengine-qrc"
    case lenovoAppStore = "lenovo-app-store"
    case meshLabSoftwareOpenGL = "meshlab-software-opengl"
    case mRemoteNG1782 = "mremoteng-1782-x64"
    case museScoreStudio = "musescore-studio"
    case notepadPlusPlusGDI = "notepad-plus-plus-gdi"
    case officeSuite = "office-suite"
    case openPLCEditor = "openplc-electron"
    case openSCADSoftwareOpenGL = "openscad-software-opengl"
    case sweetHome3DOpenGL = "sweethome3d-opengl"
    case orcaSlicerNativeOpenGL = "orcaslicer-native-opengl"
    case wpsOffice = "wps-office"
    case portableAppsPlatform = "portableapps-platform"
    case portableAppsUtility = "portableapps-utility"
    case qtBrowserSoftware = "qt-browser-software"
    case qucsSQt6 = "qucs-s-qt6"
    case qtRhiSoftware = "qt-rhi-software"
    case qtWidgetsSoftware = "qt-widgets-software"
    case softMakerOffice = "softmaker-office"
    case steamClient = "steam-client"
    case supermium32Browser = "supermium-32-browser"
    case tencentAppStore = "tencent-app-store"
    case texStudioQt6 = "texstudio-qt6"
    case sevenZipGDI = "7zip-gdi"
    case zoteroGecko32 = "zotero-gecko32"

    public static let disabledProfileValue = "none"

    public static let chromiumTextRenderingArguments = [
        "--no-sandbox",
        "--no-proxy-server",
        "--proxy-server=direct://",
        "--proxy-bypass-list=*",
        "--lang=zh-CN",
        "--accept-lang=zh-CN,zh,en-US,en",
        "--force-color-profile=srgb",
        "--disable-gpu",
        "--disable-gpu-compositing",
        "--disable-gpu-rasterization",
        "--disable-gpu-sandbox",
        "--disable-direct-composition",
        "--disable-backgrounding-occluded-windows",
        "--disable-zero-copy",
        "--disable-native-gpu-memory-buffers",
        "--disable-vulkan",
        "--disable-webgpu",
        "--disable-accelerated-2d-canvas",
        "--disable-accelerated-video-decode",
        "--disable-accelerated-video-encode",
        "--disable-oop-rasterization",
        "--disable-oop-rasterization-ddl",
        "--disable-gpu-memory-buffer-compositor-resources",
        "--disable-partial-raster",
        "--in-process-gpu",
        "--use-angle=swiftshader",
        "--use-gl=angle",
        "--enable-unsafe-swiftshader",
        "--enable-features=FontSrcLocalMatching",
        "--disable-features=CalculateNativeWinOcclusion,VizDisplayCompositor,Vulkan,WebGPU,DirectCompositionUseDCompVisualTree,UseDCompVisualTree,CanvasOopRasterization,UseChromeOSDirectVideoDecoder"
    ]

    public static let chromiumHelperArguments = chromiumTextRenderingArguments.joined(separator: " ")

    public static let chromiumBrowserArguments = [
        "--no-sandbox",
        "--no-proxy-server",
        "--proxy-server=direct://",
        "--proxy-bypass-list=*",
        "--lang=zh-CN",
        "--accept-lang=zh-CN,zh,en-US,en",
        "--force-color-profile=srgb",
        "--disable-gpu-sandbox",
        "--disable-direct-composition",
        "--disable-backgrounding-occluded-windows",
        "--disable-zero-copy",
        "--disable-native-gpu-memory-buffers",
        "--disable-vulkan",
        "--disable-webgpu",
        "--disable-accelerated-video-decode",
        "--disable-accelerated-video-encode",
        "--enable-features=FontSrcLocalMatching",
        "--disable-features=RendererCodeIntegrity,CalculateNativeWinOcclusion,VizDisplayCompositor,DirectCompositionUseDCompVisualTree,UseDCompVisualTree,DawnGraphite,SkiaGraphite,RawDraw,DrDc"
    ]

    public static let chromiumBrowserHelperArguments = chromiumBrowserArguments.joined(separator: " ")

    public static let geogebraLegacyElectron32Arguments = chromiumTextRenderingArguments + [
        "--js-flags=--jitless"
    ]

    public static let hoYoPlayWebViewArguments = [
        "--no-sandbox",
        "--no-proxy-server",
        "--proxy-server=direct://",
        "--proxy-bypass-list=*",
        "--lang=zh-CN",
        "--accept-lang=zh-CN,zh,en-US,en",
        "--force-color-profile=srgb",
        "--disable-gpu-sandbox",
        "--disable-direct-composition",
        "--disable-backgrounding-occluded-windows",
        "--disable-zero-copy",
        "--disable-native-gpu-memory-buffers",
        "--disable-vulkan",
        "--disable-webgpu",
        "--disable-accelerated-video-decode",
        "--disable-accelerated-video-encode",
        "--disable-gpu-memory-buffer-compositor-resources",
        "--disable-partial-raster",
        "--disable-gpu-vsync",
        "--in-process-gpu",
        "--force-device-scale-factor=1",
        "--use-angle=swiftshader",
        "--use-gl=angle",
        "--enable-unsafe-swiftshader",
        "--enable-features=FontSrcLocalMatching",
        "--disable-features=CalculateNativeWinOcclusion,VizDisplayCompositor,Vulkan,WebGPU,DirectCompositionUseDCompVisualTree,UseDCompVisualTree,CanvasOopRasterization,UseChromeOSDirectVideoDecoder,DawnGraphite,SkiaGraphite,RawDraw,DrDc"
    ]

    public static let hoYoPlayWebViewHelperArguments = hoYoPlayWebViewArguments.joined(separator: " ")

    public static let lenovoAppStoreArguments = [
        "--in-process-gpu",
        "--no-sandbox",
        "--no-proxy-server",
        "--proxy-server=direct://",
        "--proxy-bypass-list=*",
        "--lang=zh-CN",
        "--accept-lang=zh-CN,zh,en-US,en",
        "--force-color-profile=srgb",
        "--disable-gpu-sandbox",
        "--disable-direct-composition",
        "--disable-backgrounding-occluded-windows",
        "--disable-zero-copy",
        "--disable-vulkan",
        "--disable-webgpu",
        "--disable-accelerated-video-decode",
        "--disable-accelerated-video-encode",
        "--disable-oop-rasterization",
        "--disable-oop-rasterization-ddl",
        "--disable-partial-raster",
        "--use-gl=angle",
        "--use-angle=d3d11",
        "--remote-debugging-port=9231",
        "--remote-allow-origins=*",
        "--enable-features=FontSrcLocalMatching",
        "--disable-features=RendererCodeIntegrity,CalculateNativeWinOcclusion,VizDisplayCompositor,Vulkan,WebGPU,DirectCompositionUseDCompVisualTree,UseDCompVisualTree,CanvasOopRasterization,UseChromeOSDirectVideoDecoder,DawnGraphite,SkiaGraphite,RawDraw,DrDc"
    ]

    public static let lenovoAppStoreCEFHelperArguments = lenovoAppStoreArguments

    public static let lenovoAppStoreHelperArguments = lenovoAppStoreCEFHelperArguments.joined(separator: " ")

    public static let tencentAppStoreArguments = [
        "--no-sandbox",
        "--no-proxy-server",
        "--proxy-server=direct://",
        "--proxy-bypass-list=*",
        "--lang=zh-CN",
        "--accept-lang=zh-CN,zh,en-US,en",
        "--force-color-profile=srgb",
        "--disable-gpu",
        "--disable-gpu-compositing",
        "--disable-gpu-rasterization",
        "--disable-gpu-sandbox",
        "--disable-direct-composition",
        "--disable-vulkan",
        "--disable-webgpu",
        "--use-gl=disabled",
        "--enable-features=FontSrcLocalMatching",
        "--disable-3d-apis",
        "--disable-webgl",
        "--disable-webgl2",
        "--disable-accelerated-compositing"
    ]

    public static let tencentAppStoreHelperArguments = tencentAppStoreArguments.joined(separator: " ")

    public static let steamWebHelperArguments = [
        "--lang=zh-CN",
        "--accept-lang=zh-CN,zh,en-US,en",
        "--force-color-profile=srgb",
        "--disable-direct-composition",
        "--disable-gpu",
        "--disable-gpu-compositing",
        "--disable-gpu-rasterization",
        "--disable-gpu-sandbox",
        "--disable-backgrounding-occluded-windows",
        "--disable-zero-copy",
        "--disable-native-gpu-memory-buffers",
        "--disable-vulkan",
        "--disable-webgpu",
        "--disable-accelerated-2d-canvas",
        "--disable-accelerated-video-decode",
        "--disable-accelerated-video-encode",
        "--disable-oop-rasterization",
        "--disable-oop-rasterization-ddl",
        "--disable-gpu-memory-buffer-compositor-resources",
        "--disable-partial-raster",
        "--in-process-gpu",
        "--use-gl=disabled",
        "--enable-features=FontSrcLocalMatching",
        "--disable-features=CalculateNativeWinOcclusion,VizDisplayCompositor,Vulkan,WebGPU,DirectCompositionUseDCompVisualTree,UseDCompVisualTree,CanvasOopRasterization,UseChromeOSDirectVideoDecoder"
    ].joined(separator: " ")

    public static let webViewTextFallbackEnvironment: [String: String] = [
        "CHROME_HEADLESS": "0",
        "CHROMIUM_USER_FLAGS": "--lang=zh-CN --accept-lang=zh-CN,zh,en-US,en",
        "ELECTRON_ENABLE_LOGGING": "1",
        "ELECTRON_FORCE_IS_PACKAGED": "1",
        "FC_LANG": "zh-cn",
        "FREETYPE_PROPERTIES": "truetype:interpreter-version=35 cff:no-stem-darkening=0 autofitter:warping=1",
        "LANGUAGE": "zh_CN:zh:en_US:en",
        "MACWIN_FONT_FALLBACK_REPAIR": "1",
        "MACWIN_IPHLPAPI_FORCE_FALLBACK": "1",
        "PANGOCAIRO_BACKEND": "fontconfig",
        "QT_ACCESSIBILITY": "0",
        "QT_FONT_FAMILY": "PingFang SC",
        "QT_LOGGING_RULES": "qt.webenginecontext.debug=false;qt.qpa.fonts=false",
        "QT_STYLE_OVERRIDE": "Fusion",
        "QTWEBENGINE_DISABLE_SANDBOX": "1"
    ]

    public static let obsoleteManagedLaunchArguments: Set<String> = [
        "--disable-direct-write",
        "--disable-directwrite-for-ui",
        "--disable-remote-fonts",
        "--disable-font-subpixel-positioning",
        "--disable-lcd-text",
        "--disable-prefer-compositing-to-lcd-text",
        "--font-render-hinting=none",
        "--disable-skia-runtime-opts",
        "--use-angle=swiftshader-webgl"
    ]

    public static let obsoleteDisabledFeatures: Set<String> = [
        "DWriteFontProxy",
        "FontSrcLocalMatching",
        "FontationsFontBackend",
        "UseDWriteCore",
        "UseSkiaRenderer"
    ]

    private static let obsoleteDisabledFeatureNamesLowercased = Set(
        obsoleteDisabledFeatures.map { $0.lowercased() }
    )

    public static let qtQuickStartupArguments = [
        "--session-type",
        "start-empty"
    ]

    public static let texStudioQt6Arguments = [
        "--no-session",
        "-platform",
        "windows:fontengine=freetype"
    ]

    public static let supermium32BrowserArguments = [
        "--disable-encryption",
        "--disable-machine-id",
        "--user-data-dir=portable_data32-macwin",
        "--no-first-run",
        "--no-default-browser-check",
        "--disable-background-mode",
        "--disable-background-networking",
        "--new-window",
        "--no-sandbox",
        "--no-proxy-server",
        "--proxy-server=direct://",
        "--proxy-bypass-list=*",
        "--disable-gpu",
        "--in-process-gpu",
        "--use-angle=swiftshader",
        "--use-gl=angle",
        "--enable-unsafe-swiftshader",
        "about:blank"
    ]

    public static let mRemoteNG1782Arguments = [
        "/reset",
        "/noreconnect"
    ]

    public static let browserGeckoArguments = [
        "-no-remote",
        "-profile",
        "C:\\macwin-portable\\firefox-profile",
        "about:blank"
    ]

    public static let jaspQtWebEngineArguments = [
        "--safeGraphics",
        "--noSandbox"
    ]

    public static let zoteroGecko32Arguments = [
        "-no-remote",
        "-profile",
        "C:\\macwin-portable\\zotero-profile"
    ]

    public static func lightweightGDIStableEnvironment(profile rawValue: String) -> [String: String] {
        [
            "MACWIN_ACTIVATE_WINE_APP": "0",
            "MACWIN_APP_MODE_INPUT_REPAIR": "0",
            "MACWIN_COMPAT_PROFILE": rawValue,
            "MACWIN_DISABLE_WINE_APP_ACTIVATION": "1",
            "MACWIN_DISABLE_WINE_D3D_CONFIG": "1",
            "WINE_D3D_CONFIG": "",
            "WINEDEBUG": "-all"
        ]
    }

    public var launchArguments: [String] {
        switch self {
        case .bambuStudioSoftwareOpenGL:
            []
        case .blenderSoftwareOpenGL:
            []
        case .browserGecko:
            Self.browserGeckoArguments
        case .cefSoftwareRenderer:
            Self.chromiumTextRenderingArguments
        case .chromiumBrowser:
            Self.chromiumBrowserArguments
        case .curaSlicer:
            []
        case .dbeaverSWT:
            []
        case .freeCADOpenGL:
            []
        case .kiCadEDA:
            []
        case .libreCADQt:
            []
        case .openPLCEditor:
            Self.chromiumTextRenderingArguments
        case .openSCADSoftwareOpenGL:
            []
        case .sweetHome3DOpenGL:
            []
        case .kritaOpenGL:
            []
        case .geogebraLegacyElectron32:
            Self.geogebraLegacyElectron32Arguments
        case .gmshOpenGL:
            []
        case .hoYoPlay:
            []
        case .jabRefJavaFXD3D:
            []
        case .jaspQtWebEngineQrc:
            Self.jaspQtWebEngineArguments
        case .lenovoAppStore:
            Self.lenovoAppStoreArguments
        case .meshLabSoftwareOpenGL:
            []
        case .mRemoteNG1782:
            Self.mRemoteNG1782Arguments
        case .museScoreStudio:
            Self.qtQuickStartupArguments
        case .qtRhiSoftware:
            []
        case .notepadPlusPlusGDI, .portableAppsPlatform, .portableAppsUtility:
            []
        case .officeSuite:
            [
                "--norestore",
                "--nodefault",
                "--nolockcheck"
            ]
        case .orcaSlicerNativeOpenGL:
            []
        case .wpsOffice:
            []
        case .qtBrowserSoftware, .qtWidgetsSoftware:
            []
        case .qucsSQt6:
            []
        case .softMakerOffice:
            []
        case .steamClient:
            [
                "-no-cef-sandbox",
                "-cef-disable-gpu",
                "-cef-disable-gpu-compositing"
            ]
        case .supermium32Browser:
            Self.supermium32BrowserArguments
        case .tencentAppStore:
            Self.tencentAppStoreArguments
        case .texStudioQt6:
            Self.texStudioQt6Arguments
        case .sevenZipGDI:
            []
        case .zoteroGecko32:
            Self.zoteroGecko32Arguments
        }
    }

    public var environment: [String: String] {
        switch self {
        case .bambuStudioSoftwareOpenGL:
            [
                "GALLIUM_DRIVER": "llvmpipe",
                "LANG": "zh_CN.UTF-8",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "LIBGL_ALWAYS_SOFTWARE": "1",
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_APP_MODE_INPUT_REPAIR": "1",
                "MACWIN_BAMBU_STUDIO_RUNTIME_REPAIR": "1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_OPENGL_VIEWPORT_REPAIR": "1",
                "MESA_GLSL_VERSION_OVERRIDE": "450",
                "MESA_GL_VERSION_OVERRIDE": "4.5COMPAT",
                "ROSETTA_X87_PATH": "",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0",
                "WINEDLLOVERRIDES": "opengl32,msvcp140,msvcp140_1,msvcp140_2,msvcp140_codecvt_ids,vcruntime140,vcruntime140_1,concrt140=n;winemenubuilder.exe=d"
            ]
        case .blenderSoftwareOpenGL:
            [
                "GALLIUM_DRIVER": "llvmpipe",
                "LANG": "zh_CN.UTF-8",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "LIBGL_ALWAYS_SOFTWARE": "1",
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_APP_MODE_INPUT_REPAIR": "1",
                "MACWIN_BLENDER_SOFTWARE_OPENGL_REPAIR": "1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_OPENGL_VIEWPORT_REPAIR": "1",
                "MESA_LOADER_DRIVER_OVERRIDE": "llvmpipe",
                "ROSETTA_X87_PATH": "",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0",
                "WINEDLLOVERRIDES": "opengl32=n,b;winemenubuilder.exe=d"
            ]
        case .orcaSlicerNativeOpenGL:
            [
                "LANG": "zh_CN.UTF-8",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_APP_MODE_INPUT_REPAIR": "1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_OPENGL_VIEWPORT_REPAIR": "1",
                "MACWIN_ORCASLICER_RUNTIME_REPAIR": "1",
                "ROSETTA_X87_PATH": "",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0",
                "WINEDLLOVERRIDES": "winemenubuilder.exe=d"
            ]
        case .browserGecko:
            [
                "LANG": "zh_CN.UTF-8",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "FREETYPE_PROPERTIES": "truetype:interpreter-version=35 cff:no-stem-darkening=0 autofitter:warping=1",
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_DISABLE_DWM_COMPOSITION": "1",
                "MACWIN_DISABLE_WINE_D3D_CONFIG": "1",
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FONT_FALLBACK_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_GECKO_BROWSER_REPAIR": "1",
                "MACWIN_GECKO_PROFILE_REPAIR": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "MOZ_ACCELERATED": "0",
                "MOZ_CRASHREPORTER": "0",
                "MOZ_CRASHREPORTER_DISABLE": "1",
                "MOZ_CRASHREPORTER_NO_REPORT": "1",
                "MOZ_DISABLE_CONTENT_SANDBOX": "1",
                "MOZ_DISABLE_GPU_SANDBOX": "1",
                "MOZ_DISABLE_GMP_SANDBOX": "1",
                "MOZ_DISABLE_RDD_SANDBOX": "1",
                "MOZ_DISABLE_SOCKET_PROCESS_SANDBOX": "1",
                "MOZ_WEBRENDER": "0",
                "WINEDEBUG": "-all",
                "WINEDLLOVERRIDES": "wbemprox=d"
            ]
        case .cefSoftwareRenderer:
            Self.webViewTextFallbackEnvironment.merging([
                "LANG": "zh_CN.UTF-8",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "MACWIN_COMPAT_PROFILE": "cef-software-gl",
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_DISABLE_WINE_D3D_CONFIG": "1",
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FORCE_OPAQUE_LAYERED_WINDOWS": "1",
                "MACWIN_CHROMIUM_HELPER_ARGS": Self.chromiumHelperArguments,
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "QTWEBENGINE_CHROMIUM_FLAGS": Self.chromiumTextRenderingArguments.joined(separator: " "),
                "QT_OPENGL": "software",
                "QT_QUICK_BACKEND": "software",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0",
                "WINEDLLOVERRIDES": "qone,wbemprox=d"
            ], uniquingKeysWith: { _, new in new })
        case .chromiumBrowser:
            Self.webViewTextFallbackEnvironment.merging([
                "LANG": "zh_CN.UTF-8",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "MACWIN_CHROMIUM_BROWSER_REPAIR": "1",
                "MACWIN_CHROMIUM_HELPER_ARGS": Self.chromiumBrowserHelperArguments,
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_LAUNCH_CWD": "versioned-chromium-dir",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "ROSETTA_X87_PATH": "",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=vulkan,csmt=0x0",
                "WINEDLLOVERRIDES": "wbemprox=d"
            ], uniquingKeysWith: { _, new in new })
        case .curaSlicer:
            [
                "LANG": "zh_CN.UTF-8",
                "LANGUAGE": "zh_CN:zh:en_US:en",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "FREETYPE_PROPERTIES": "truetype:interpreter-version=35 cff:no-stem-darkening=0 autofitter:warping=1",
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_APP_MODE_INPUT_REPAIR": "1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_CURA_PROFILE_REPAIR": "1",
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FONT_FALLBACK_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "QT_ACCESSIBILITY": "0",
                "QT_AUTO_SCREEN_SCALE_FACTOR": "0",
                "QT_ENABLE_HIGHDPI_SCALING": "0",
                "QT_FONT_DPI": "96",
                "QT_OPENGL": "desktop",
                "QT_SCALE_FACTOR": "1",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0"
            ]
        case .dbeaverSWT:
            [
                "FREETYPE_PROPERTIES": "truetype:interpreter-version=40 cff:no-stem-darkening=0",
                "LANG": "zh_CN.UTF-8",
                "LANGUAGE": "zh_CN:zh:en_US:en",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_APP_MODE_INPUT_REPAIR": "1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_DBEAVER_SWT_REPAIR": "1",
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FONT_FALLBACK_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "ROSETTA_X87_PATH": "",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0",
                "WINEDLLOVERRIDES": "winemenubuilder.exe=d"
            ]
        case .freeCADOpenGL:
            [
                "FREETYPE_PROPERTIES": "truetype:interpreter-version=35 cff:no-stem-darkening=0 autofitter:warping=1",
                "LANG": "zh_CN.UTF-8",
                "LANGUAGE": "zh_CN:zh:en_US:en",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_APP_MODE_INPUT_REPAIR": "1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FONT_FALLBACK_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_FREECAD_PYTHON_REPAIR": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_OPENGL_VIEWPORT_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "QT_ACCESSIBILITY": "0",
                "QT_AUTO_SCREEN_SCALE_FACTOR": "0",
                "QT_ENABLE_HIGHDPI_SCALING": "0",
                "QT_FONT_DPI": "96",
                "QT_OPENGL": "desktop",
                "QT_SCALE_FACTOR": "1",
                "ROSETTA_X87_PATH": "",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0",
                "WINEDLLOVERRIDES": "winemenubuilder.exe=d"
            ]
        case .kiCadEDA:
            [
                "FREETYPE_PROPERTIES": "truetype:interpreter-version=35 cff:no-stem-darkening=0 autofitter:warping=1",
                "LANG": "zh_CN.UTF-8",
                "LANGUAGE": "zh_CN:zh:en_US:en",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_APP_MODE_INPUT_REPAIR": "1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FONT_FALLBACK_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_OPENGL_VIEWPORT_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "ROSETTA_X87_PATH": "",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0",
                "WINEDLLOVERRIDES": "winemenubuilder.exe=d"
            ]
        case .libreCADQt:
            [
                "FREETYPE_PROPERTIES": "truetype:interpreter-version=35 cff:no-stem-darkening=0 autofitter:warping=1",
                "LANG": "zh_CN.UTF-8",
                "LANGUAGE": "zh_CN:zh:en_US:en",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_APP_MODE_INPUT_REPAIR": "1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FONT_FALLBACK_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_LIBRECAD_PROFILE_REPAIR": "1",
                "MACWIN_OPENGL_VIEWPORT_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "QT_ACCESSIBILITY": "0",
                "QT_AUTO_SCREEN_SCALE_FACTOR": "0",
                "QT_ENABLE_HIGHDPI_SCALING": "0",
                "QT_FONT_DPI": "96",
                "QT_OPENGL": "desktop",
                "QT_SCALE_FACTOR": "1",
                "ROSETTA_X87_PATH": "",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0",
                "WINEDLLOVERRIDES": "winemenubuilder.exe=d"
            ]
        case .kritaOpenGL:
            [
                "LANG": "zh_CN.UTF-8",
                "LANGUAGE": "zh_CN:zh:en_US:en",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "FREETYPE_PROPERTIES": "truetype:interpreter-version=35 cff:no-stem-darkening=0 autofitter:warping=1",
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_APP_MODE_INPUT_REPAIR": "1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FONT_FALLBACK_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_KRITA_OPENGL_REPAIR": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "PYTHONHASHSEED": "0",
                "QT_ACCESSIBILITY": "0",
                "QT_AUTO_SCREEN_SCALE_FACTOR": "0",
                "QT_ENABLE_HIGHDPI_SCALING": "0",
                "QT_FONT_DPI": "96",
                "QT_OPENGL": "desktop",
                "QT_SCALE_FACTOR": "1",
                "ROSETTA_X87_PATH": "",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0"
            ]
        case .geogebraLegacyElectron32:
            Self.webViewTextFallbackEnvironment.merging([
                "LANG": "zh_CN.UTF-8",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_CHROMIUM_HELPER_ARGS": Self.geogebraLegacyElectron32Arguments.joined(separator: " "),
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_DISABLE_WINE_D3D_CONFIG": "1",
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_GEOGEBRA_ELECTRON32_REPAIR": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "MACWIN_WOW64_BROWSER_REPAIR": "1",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0",
                "WINEDLLOVERRIDES": "wbemprox=d"
            ], uniquingKeysWith: { _, new in new })
        case .gmshOpenGL:
            [
                "LANG": "C.UTF-8",
                "LC_ALL": "C.UTF-8",
                "LC_CTYPE": "C.UTF-8",
                "FREETYPE_PROPERTIES": "truetype:interpreter-version=35 cff:no-stem-darkening=0 autofitter:warping=1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_APP_MODE_INPUT_REPAIR": "1",
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_OPENGL_VIEWPORT_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=vulkan,csmt=0x0"
            ]
        case .meshLabSoftwareOpenGL:
            [
                "LANG": "C.UTF-8",
                "LC_ALL": "C.UTF-8",
                "LC_CTYPE": "C.UTF-8",
                "LIBGL_ALWAYS_SOFTWARE": "1",
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_APP_MODE_INPUT_REPAIR": "1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_MESHLAB_SOFTWARE_OPENGL_REPAIR": "1",
                "MACWIN_OPENGL_VIEWPORT_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "QT_OPENGL": "software",
                "QT_QUICK_BACKEND": "software",
                "ROSETTA_X87_PATH": "",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0",
                "WINEDLLOVERRIDES": "opengl32=n;winemenubuilder.exe=d"
            ]
        case .openSCADSoftwareOpenGL:
            [
                "LANG": "zh_CN.UTF-8",
                "LANGUAGE": "zh_CN:zh:en_US:en",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "LIBGL_ALWAYS_SOFTWARE": "1",
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_APP_MODE_INPUT_REPAIR": "1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_OPENGL_VIEWPORT_REPAIR": "1",
                "MACWIN_OPENSCAD_SOFTWARE_OPENGL_REPAIR": "1",
                "QT_ACCESSIBILITY": "0",
                "QT_AUTO_SCREEN_SCALE_FACTOR": "0",
                "QT_ENABLE_HIGHDPI_SCALING": "0",
                "QT_FONT_DPI": "96",
                "QT_OPENGL": "software",
                "QT_SCALE_FACTOR": "1",
                "ROSETTA_X87_PATH": "",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0",
                "WINEDLLOVERRIDES": "opengl32=n;winemenubuilder.exe=d"
            ]
        case .openPLCEditor:
            Self.webViewTextFallbackEnvironment.merging([
                "LANG": "zh_CN.UTF-8",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_APP_MODE_INPUT_REPAIR": "1",
                "MACWIN_CHROMIUM_HELPER_ARGS": Self.chromiumHelperArguments,
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_DISABLE_DWM_COMPOSITION": "1",
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_FORCE_OPAQUE_LAYERED_WINDOWS": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_OPENPLC_ELECTRON_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "TZ": "Asia/Shanghai",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=vulkan,csmt=0x0",
                "WINEDLLOVERRIDES": "wbemprox=d;winemenubuilder.exe=d"
            ], uniquingKeysWith: { _, new in new })
        case .sweetHome3DOpenGL:
            [
                "_JAVA_OPTIONS": "-Dj3d.rend=ogl -Dsun.java2d.d3d=false -Dsun.java2d.opengl=true",
                "LANG": "zh_CN.UTF-8",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_APP_MODE_INPUT_REPAIR": "1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_OPENGL_VIEWPORT_REPAIR": "1",
                "MACWIN_SWEETHOME3D_OPENGL_REPAIR": "1",
                "ROSETTA_X87_PATH": "",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0",
                "WINEDLLOVERRIDES": "winemenubuilder.exe=d"
            ]
        case .hoYoPlay:
            Self.webViewTextFallbackEnvironment.merging([
                "LANG": "zh_CN.UTF-8",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_DISABLE_DWM_COMPOSITION": "1",
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FORCE_OPAQUE_LAYERED_WINDOWS": "1",
                "MACWIN_HOYOPLAY_TEXT_REPAIR": "1",
                "MACWIN_CHROMIUM_HELPER_ARGS": Self.hoYoPlayWebViewHelperArguments,
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "QT_AUTO_SCREEN_SCALE_FACTOR": "0",
                "QT_ENABLE_HIGHDPI_SCALING": "0",
                "QT_FONT_DPI": "96",
                "QT_SCALE_FACTOR": "1",
                "QTWEBENGINE_CHROMIUM_FLAGS": Self.hoYoPlayWebViewHelperArguments,
                "QT_OPENGL": "software",
                "QT_QUICK_BACKEND": "software",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0",
                "WINEDLLOVERRIDES": "qone,wbemprox=d"
            ], uniquingKeysWith: { _, new in new })
        case .jabRefJavaFXD3D:
            [
                "FREETYPE_PROPERTIES": "truetype:interpreter-version=35 cff:no-stem-darkening=0 autofitter:warping=1",
                "JAVA_TOOL_OPTIONS": "-Dsun.java2d.d3d=false -Dsun.java2d.opengl=false -Dprism.order=d3d -Dprism.forceGPU=true -Dprism.text=t2k -Dprism.fontdir=C:\\windows\\Fonts -Djava.awt.headless=false -Dglass.win.uiScale=100%",
                "LANG": "zh_CN.UTF-8",
                "LANGUAGE": "zh_CN:zh:en_US:en",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_APP_MODE_INPUT_REPAIR": "1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FONT_FALLBACK_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_JABREF_JAVAFX_REPAIR": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "ROSETTA_X87_PATH": "",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=vulkan,csmt=0x0",
                "WINEDLLOVERRIDES": "winemenubuilder.exe=d"
            ]
        case .jaspQtWebEngineQrc:
            Self.webViewTextFallbackEnvironment.merging([
                "LANG": "zh_CN.UTF-8",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FONT_FALLBACK_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_JASP_QRC_REPAIR": "1",
                "MACWIN_JASP_STARTUP_REPAIR": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_QTWEBENGINE_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "PATH": "C:\\Program Files\\JASP\\bin;C:\\Program Files\\JASP;C:\\windows\\system32;C:\\windows;C:\\windows\\system32\\wbem;C:\\windows\\system32\\WindowsPowershell\\v1.0",
                "QML2_IMPORT_PATH": "C:\\Program Files\\JASP\\qml",
                "QML_DISABLE_DISK_CACHE": "1",
                "QMLSCENE_DEVICE": "softwarecontext",
                "QSG_RENDER_LOOP": "basic",
                "QSG_RHI_BACKEND": "opengl",
                "QT_ACCESSIBILITY": "0",
                "QT_AUTO_SCREEN_SCALE_FACTOR": "0",
                "QT_ENABLE_HIGHDPI_SCALING": "0",
                "QT_FONT_DPI": "96",
                "QT_OPENGL": "software",
                "QT_PLUGIN_PATH": "C:\\Program Files\\JASP",
                "QT_QPA_PLATFORM_PLUGIN_PATH": "C:\\Program Files\\JASP\\platforms",
                "QT_QUICK_BACKEND": "software",
                "QT_QUICK_CONTROLS_STYLE": "Basic",
                "QT_RHI_BACKEND": "software",
                "QT_SCALE_FACTOR": "1",
                "QTWEBENGINE_CHROMIUM_FLAGS": Self.chromiumTextRenderingArguments.joined(separator: " "),
                "QTWEBENGINE_DISABLE_SANDBOX": "1",
                "QTWEBENGINE_LOCALES_PATH": "C:\\Program Files\\JASP\\translations\\qtwebengine_locales",
                "QTWEBENGINEPROCESS_PATH": "C:\\Program Files\\JASP\\QtWebEngineProcess.exe",
                "QTWEBENGINE_RESOURCES_PATH": "C:\\Program Files\\JASP\\resources",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0"
            ], uniquingKeysWith: { _, new in new })
        case .lenovoAppStore:
            Self.webViewTextFallbackEnvironment.merging([
                "LANG": "zh_CN.UTF-8",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_DXVK_MACOS_REPAIR": "1",
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_LENOVO_BLACK_SCREEN_REPAIR": "1",
                "MACWIN_LENOVO_DEBUG_PORT": "9231",
                "MACWIN_LENOVO_PAGE_REPAIR": "1",
                "MACWIN_CHROMIUM_HELPER_ARGS": Self.lenovoAppStoreHelperArguments,
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "QTWEBENGINE_CHROMIUM_FLAGS": Self.lenovoAppStoreHelperArguments,
                "QT_OPENGL": "software",
                "QT_QUICK_BACKEND": "software",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=vulkan,csmt=0x0",
                "WINEDLLOVERRIDES": "dxgi,d3d11,d3d10core=n,b;qone,wbemprox=d"
            ], uniquingKeysWith: { _, new in new })
        case .tencentAppStore:
            Self.webViewTextFallbackEnvironment.merging([
                "LANG": "zh_CN.UTF-8",
                "LANGUAGE": "zh_CN:zh:en_US:en",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_APP_MODE_INPUT_REPAIR": "1",
                "MACWIN_DISABLE_DWM_COMPOSITION": "1",
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FONT_FALLBACK_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_FORCE_OPAQUE_LAYERED_WINDOWS": "1",
                "MACWIN_CHROMIUM_HELPER_ARGS": Self.tencentAppStoreHelperArguments,
                "MACWIN_TENCENT_APP_STORE_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "MACWIN_WEBVIEW_SOFTWARE_RENDERER": "1",
                "QTWEBENGINE_CHROMIUM_FLAGS": Self.tencentAppStoreHelperArguments,
                "QT_OPENGL": "software",
                "QT_QUICK_BACKEND": "software",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0",
                "WINEDLLOVERRIDES": "qone,wbemprox=d"
            ], uniquingKeysWith: { _, new in new })
        case .mRemoteNG1782:
            [
                "DOTNET_ROOT": "C:\\macwin-runtimes\\dotnet-desktop-10-x64",
                "DOTNET_ROOT_X64": "C:\\macwin-runtimes\\dotnet-desktop-10-x64",
                "LANG": "zh_CN.UTF-8",
                "LC_ALL": "C.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_DISABLE_WINE_APP_ACTIVATION": "1",
                "MACWIN_DOTNET_DESKTOP10_RUNTIME_REPAIR": "1",
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FONT_FALLBACK_REPAIR": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_MREMOTENG_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "PATH": "C:\\macwin-runtimes\\dotnet-desktop-10-x64;C:\\windows\\system32;C:\\windows;C:\\windows\\system32\\wbem;C:\\windows\\system32\\WindowsPowershell\\v1.0",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0"
            ]
        case .museScoreStudio:
            [
                "LANG": "zh_CN.UTF-8",
                "LANGUAGE": "zh_CN:zh:en_US:en",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "FREETYPE_PROPERTIES": "truetype:interpreter-version=35 cff:no-stem-darkening=0 autofitter:warping=1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_AUTOMATED_UI_CLICK_REPAIR": "1",
                "MACWIN_APP_MODE_INPUT_REPAIR": "1",
                "MACWIN_BORDERLESS_APP_MODE": "0",
                "MACWIN_CLICK_THROUGH_REPAIR": "1",
                "MACWIN_DISABLE_DWM_COMPOSITION": "1",
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FONT_FALLBACK_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_MOUSE_FOCUS_CLICK_AUTOMATION": "1",
                "MACWIN_MUSESCORE_WELCOME_CLICK_AUTOMATION": "1",
                "MACWIN_MUSESCORE_WELCOME_REPAIR": "1",
                "MACWIN_QT_RHI_SOFTWARE_REPAIR": "1",
                "MACWIN_RETINA_INPUT_REPAIR": "0",
                "MACWIN_SYNC_MUSESCORE_REGISTRY": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "QT_ACCESSIBILITY": "0",
                "QT_AUTO_SCREEN_SCALE_FACTOR": "0",
                "QT_DEVICE_PIXEL_RATIO": "1",
                "QT_ENABLE_HIGHDPI_SCALING": "0",
                "QT_FONT_DPI": "96",
                "QT_OPENGL": "software",
                "QT_QUICK_CONTROLS_STYLE": "Basic",
                "QT_QUICK_BACKEND": "software",
                "QT_RHI_BACKEND": "software",
                "QT_SCALE_FACTOR": "1",
                "QT_SCALE_FACTOR_ROUNDING_POLICY": "Round",
                "QT_SCREEN_SCALE_FACTORS": "1",
                "QT_USE_PHYSICAL_DPI": "0",
                "QT_LOGGING_RULES": "qt.accessibility.*=false;qt.pointer.dispatch=false",
                "QML_DISABLE_DISK_CACHE": "1",
                "QMLSCENE_DEVICE": "softwarecontext",
                "QSG_RENDER_LOOP": "basic",
                "QSG_RHI_BACKEND": "opengl",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0"
            ]
        case .qtRhiSoftware:
            [
                "LANG": "zh_CN.UTF-8",
                "LANGUAGE": "zh_CN:zh:en_US:en",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "FREETYPE_PROPERTIES": "truetype:interpreter-version=35 cff:no-stem-darkening=0 autofitter:warping=1",
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_APP_MODE_INPUT_REPAIR": "1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FONT_FALLBACK_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_QT_RHI_SOFTWARE_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "QML_DISABLE_DISK_CACHE": "1",
                "QSG_RENDER_LOOP": "basic",
                "QSG_RHI_BACKEND": "opengl",
                "QT_ACCESSIBILITY": "0",
                "QT_AUTO_SCREEN_SCALE_FACTOR": "0",
                "QT_ENABLE_HIGHDPI_SCALING": "0",
                "QT_FONT_DPI": "96",
                "QT_OPENGL": "software",
                "QT_SCALE_FACTOR": "1",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0"
            ]
        case .notepadPlusPlusGDI:
            Self.lightweightGDIStableEnvironment(profile: rawValue)
        case .portableAppsPlatform:
            Self.lightweightGDIStableEnvironment(profile: rawValue).merging([
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_PORTABLEAPPS_PLATFORM_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "WINEDLLOVERRIDES": "winemenubuilder.exe=d;uxtheme=d"
            ], uniquingKeysWith: { _, new in new })
        case .portableAppsUtility:
            Self.lightweightGDIStableEnvironment(profile: rawValue).merging([
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_PORTABLEAPPS_HELPER_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1"
            ], uniquingKeysWith: { _, new in new })
        case .officeSuite:
            [
                "LANG": "zh_CN.UTF-8",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "FREETYPE_PROPERTIES": "truetype:interpreter-version=35 cff:no-stem-darkening=0 autofitter:warping=1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_APP_MODE_INPUT_REPAIR": "1",
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FONT_FALLBACK_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_OFFICE_SUITE_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "SAL_USE_VCLPLUGIN": "win",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0"
            ]
        case .wpsOffice:
            [
                "LANG": "zh_CN.UTF-8",
                "LANGUAGE": "zh_CN:zh:en_US:en",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "FREETYPE_PROPERTIES": "truetype:interpreter-version=35 cff:no-stem-darkening=0 autofitter:warping=1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_APP_MODE_INPUT_REPAIR": "1",
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FONT_FALLBACK_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "MACWIN_WPS_OFFICE_REPAIR": "1",
                "QT_ACCESSIBILITY": "0",
                "QT_FONT_DPI": "96",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0"
            ]
        case .qtBrowserSoftware:
            Self.webViewTextFallbackEnvironment.merging([
                "LANG": "zh_CN.UTF-8",
                "LANGUAGE": "zh_CN:zh:en_US:en",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_APP_MODE_INPUT_REPAIR": "1",
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FONT_FALLBACK_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_QT_BROWSER_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "QT_ACCESSIBILITY": "0",
                "QT_AUTO_SCREEN_SCALE_FACTOR": "0",
                "QT_ENABLE_HIGHDPI_SCALING": "0",
                "QT_FONT_DPI": "96",
                "QT_OPENGL": "software",
                "QT_QUICK_BACKEND": "software",
                "QT_SCALE_FACTOR": "1",
                "QT_STYLE_OVERRIDE": "Fusion",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0"
            ], uniquingKeysWith: { _, new in new })
        case .qtWidgetsSoftware:
            [
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_QT_WIDGETS_REPAIR": "1",
                "WINEDEBUG": "-all"
            ]
        case .qucsSQt6:
            [
                "LANG": "zh_CN.UTF-8",
                "LANGUAGE": "zh_CN:zh:en_US:en",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "FREETYPE_PROPERTIES": "truetype:interpreter-version=35 cff:no-stem-darkening=0 autofitter:warping=1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_APP_MODE_INPUT_REPAIR": "1",
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FONT_FALLBACK_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_QT_WIDGETS_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "PATH": "C:\\Program Files\\Qucs-S-26.1.1-win64\\bin;C:\\windows\\system32;C:\\windows;C:\\windows\\system32\\wbem;C:\\windows\\system32\\WindowsPowershell\\v1.0",
                "QT_ACCESSIBILITY": "0",
                "QT_AUTO_SCREEN_SCALE_FACTOR": "0",
                "QT_DEVICE_PIXEL_RATIO": "1",
                "QT_ENABLE_HIGHDPI_SCALING": "0",
                "QT_FONT_DPI": "96",
                "QT_OPENGL": "software",
                "QT_PLUGIN_PATH": "C:\\Program Files\\Qucs-S-26.1.1-win64\\bin",
                "QT_QPA_PLATFORM_PLUGIN_PATH": "C:\\Program Files\\Qucs-S-26.1.1-win64\\bin\\platforms",
                "QT_QUICK_BACKEND": "software",
                "QT_SCALE_FACTOR": "1",
                "QT_STYLE_OVERRIDE": "Fusion",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0"
            ]
        case .softMakerOffice:
            [
                "LANG": "zh_CN.UTF-8",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "FREETYPE_PROPERTIES": "truetype:interpreter-version=35 cff:no-stem-darkening=0 autofitter:warping=1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_COM_PROXY_REPAIR": "1",
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FONT_FALLBACK_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_SOFTMAKER_OFFICE_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=vulkan,csmt=0x0"
            ]
        case .steamClient:
            Self.webViewTextFallbackEnvironment.merging([
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_WINHTTP_IGNORE_UNKNOWN_CA": "1",
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_DISABLE_DWM_COMPOSITION": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_FORCE_OPAQUE_LAYERED_WINDOWS": "1",
                "MACWIN_RECENTER_OFFSCREEN_WINDOWS": "1",
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_CHROMIUM_HELPER_ARGS": Self.chromiumHelperArguments,
                "MACWIN_STEAMWEBHELPER_ARGS": Self.steamWebHelperArguments,
                "MACWIN_STEAMWEBHELPER_FORCE_OPAQUE": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "LANG": "zh_CN.UTF-8",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=vulkan,csmt=0x0",
                "WINEDLLOVERRIDES": "wbemprox=d"
            ], uniquingKeysWith: { _, new in new })
        case .supermium32Browser:
            Self.webViewTextFallbackEnvironment.merging([
                "LANG": "zh_CN.UTF-8",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_CHROMIUM_BROWSER_REPAIR": "1",
                "MACWIN_CHROMIUM_HELPER_ARGS": Self.supermium32BrowserArguments.joined(separator: " "),
                "MACWIN_DISABLE_WINE_D3D_CONFIG": "1",
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_LAUNCH_CWD": "executable-dir",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "MACWIN_WOW64_BROWSER_REPAIR": "1",
                "WINEDEBUG": "-all",
                "WINEDLLOVERRIDES": "wbemprox=d"
            ], uniquingKeysWith: { _, new in new })
        case .texStudioQt6:
            [
                "LANG": "zh_CN.UTF-8",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "FREETYPE_PROPERTIES": "truetype:interpreter-version=35 cff:no-stem-darkening=0 autofitter:warping=1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FONT_FALLBACK_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_TEXSTUDIO_QT6_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "QT_AUTO_SCREEN_SCALE_FACTOR": "0",
                "QT_ENABLE_HIGHDPI_SCALING": "0",
                "QT_FONT_DPI": "96",
                "QT_OPENGL": "software",
                "QT_QUICK_BACKEND": "software",
                "QT_SCALE_FACTOR": "1",
                "QT_STYLE_OVERRIDE": "windows",
                "WINEDEBUG": "-all",
                "WINE_D3D_CONFIG": "renderer=gl,csmt=0x0"
            ]
        case .sevenZipGDI:
            Self.lightweightGDIStableEnvironment(profile: rawValue)
        case .zoteroGecko32:
            [
                "LANG": "zh_CN.UTF-8",
                "LC_ALL": "zh_CN.UTF-8",
                "LC_CTYPE": "zh_CN.UTF-8",
                "MACWIN_ACTIVATE_WINE_APP": "1",
                "MACWIN_COMPAT_PROFILE": rawValue,
                "MACWIN_DISABLE_WINE_D3D_CONFIG": "1",
                "MACWIN_FONTCONFIG_REPAIR": "1",
                "MACWIN_FONT_FALLBACK_REPAIR": "1",
                "MACWIN_FORCE_MOUSE_FOCUS": "1",
                "MACWIN_GECKO_PROFILE_REPAIR": "1",
                "MACWIN_TEXT_RENDERING_REPAIR": "1",
                "MACWIN_WOW64_BROWSER_REPAIR": "1",
                "MACWIN_ZOTERO_GECKO32_REPAIR": "1",
                "MOZ_ACCELERATED": "0",
                "MOZ_CRASHREPORTER": "0",
                "MOZ_CRASHREPORTER_DISABLE": "1",
                "MOZ_CRASHREPORTER_NO_REPORT": "1",
                "MOZ_DISABLE_CONTENT_SANDBOX": "1",
                "MOZ_DISABLE_GPU_SANDBOX": "1",
                "MOZ_DISABLE_GMP_SANDBOX": "1",
                "MOZ_DISABLE_RDD_SANDBOX": "1",
                "MOZ_DISABLE_SOCKET_PROCESS_SANDBOX": "1",
                "MOZ_WEBRENDER": "0",
                "WINEDEBUG": "-all",
                "WINEDLLOVERRIDES": "wbemprox=d"
            ]
        }
    }

    public static var managedEnvironmentKeys: Set<String> {
        Set(Self.allCases.flatMap { $0.environment.keys })
    }

    public static var managedLaunchArguments: Set<String> {
        Set(Self.allCases.flatMap(\.launchArguments) + Self.lenovoAppStoreCEFHelperArguments)
    }

    public func applied(to launcher: LauncherManifest) -> LauncherManifest {
        var updated = launcher
        let unmanagedArguments = Self.sanitizedLaunchArguments(launcher.args)
            .filter { !Self.managedLaunchArguments.contains($0) }
        updated.args = Self.mergeArguments(launchArguments, unmanagedArguments)
        for key in Self.managedEnvironmentKeys {
            updated.envOverrides.removeValue(forKey: key)
        }
        for (key, value) in environment {
            updated.envOverrides[key] = value
        }
        if self == .cefSoftwareRenderer, Self.isNativeX64ItchLauncher(updated) {
            updated.envOverrides["ELECTRON_ENABLE_LOGGING"] = "1"
            updated.envOverrides["ELECTRON_FORCE_IS_PACKAGED"] = "1"
            updated.envOverrides["ROSETTA_X87_PATH"] = ""
        }
        if self == .qtWidgetsSoftware, Self.isNativeX64NpackdLauncher(updated) {
            updated.envOverrides["LANG"] = "zh_CN.UTF-8"
            updated.envOverrides["LC_ALL"] = "zh_CN.UTF-8"
            updated.envOverrides["MACWIN_NPACKD_CATALOG_REPAIR"] = "1"
            updated.envOverrides["ROSETTA_X87_PATH"] = ""
            updated.envOverrides["WINE_D3D_CONFIG"] = "renderer=gl,csmt=0x0"
        }
        return updated
    }

    private static func isNativeX64ItchLauncher(_ launcher: LauncherManifest) -> Bool {
        let tokens = [launcher.appId, launcher.id, launcher.displayName, launcher.exePath]
            .map { $0.lowercased() }
        return tokens.contains { token in
            token == "itch" || token.contains("itch.io") || token.contains("\\itch\\app-")
                || token.contains("/itch/app-")
        }
    }

    private static func isNativeX64NpackdLauncher(_ launcher: LauncherManifest) -> Bool {
        let tokens = [launcher.appId, launcher.id, launcher.displayName, launcher.exePath]
            .map { $0.lowercased() }
        return tokens.contains { token in
            token == "npackd" || token.contains("npackdg.exe") || token.contains("npackd-market")
        }
    }

    public static func cleared(from launcher: LauncherManifest) -> LauncherManifest {
        var updated = launcher
        updated.args = sanitizedLaunchArguments(launcher.args)
            .filter { !managedLaunchArguments.contains($0) }
        for key in managedEnvironmentKeys {
            updated.envOverrides.removeValue(forKey: key)
        }
        updated.envOverrides["MACWIN_COMPAT_PROFILE"] = disabledProfileValue
        return updated
    }

    public static func matched(
        recipeId: String? = nil,
        launcherId: String? = nil,
        displayName: String? = nil,
        exePath: String? = nil
    ) -> ApplicationCompatibilityProfile? {
        let tokens = [recipeId, launcherId, displayName, exePath]
            .compactMap { $0?.lowercased() }

        if tokens.contains(where: { token in
            token.contains("bambu-studio")
                || token.contains("bambu studio")
                || token.contains("bambu-studio.exe")
        }) {
            return .bambuStudioSoftwareOpenGL
        }

        if tokens.contains(where: { token in
            token == "blender"
                || token.contains("blender-3d")
                || token.contains("blender foundation")
                || token.hasSuffix("\\blender.exe")
                || token.hasSuffix("/blender.exe")
        }) {
            return .blenderSoftwareOpenGL
        }

        if tokens.contains(where: { token in
            token.contains("orcaslicer")
                || token.contains("orca-slicer")
                || token.contains("orca slicer")
                || token.contains("orca-slicer.exe")
        }) {
            return .orcaSlicerNativeOpenGL
        }

        if tokens.contains(where: { token in
            token == "steam" || token.contains("\\steam\\steam.exe") || token.contains("/steam/steam.exe")
        }) {
            return .steamClient
        }

        if tokens.contains(where: { token in
            token.contains("cura-slicer")
                || token.contains("ultimaker-cura.exe")
                || token.contains("ultimaker cura")
        }) {
            return .curaSlicer
        }

        if tokens.contains(where: { token in
            token.contains("dbeaver-database")
                || token.contains("\\dbeaver\\dbeaver.exe")
                || token.contains("/dbeaver/dbeaver.exe")
                || token.hasSuffix("\\dbeaver.exe")
                || token.hasSuffix("/dbeaver.exe")
        }) {
            return .dbeaverSWT
        }

        if tokens.contains(where: { token in
            token.contains("krita-paint")
                || token.contains("krita-opengl")
                || token.contains("krita.exe")
                || token == "krita"
        }) {
            return .kritaOpenGL
        }

        if tokens.contains(where: { token in
            token.contains("librecad-qt")
                || token.contains("\\librecad\\")
                || token.contains("/librecad/")
                || token.hasSuffix("librecad.exe")
        }) {
            return .libreCADQt
        }

        if tokens.contains(where: { token in
            token.contains("openscad-software-opengl")
                || token.contains("\\openscad\\")
                || token.contains("/openscad/")
                || token.hasSuffix("openscad.exe")
        }) {
            return .openSCADSoftwareOpenGL
        }

        if tokens.contains(where: { token in
            token.contains("sweethome3d-opengl")
                || token.contains("\\sweet home 3d\\")
                || token.contains("/sweet home 3d/")
                || token.hasSuffix("sweethome3d.exe")
        }) {
            return .sweetHome3DOpenGL
        }

        if tokens.contains(where: { token in
            token.contains("freecad-workbench")
                || token.contains("freecad-opengl")
                || token.contains("\\freecad")
                || token.contains("/freecad")
                || token.hasSuffix("freecad.exe")
                || token.hasSuffix("freecadcmd.exe")
        }) {
            return .freeCADOpenGL
        }

        if tokens.contains(where: { token in
            token.contains("kicad-eda")
                || token.contains("\\kicad\\")
                || token.contains("/kicad/")
                || token.hasSuffix("kicad.exe")
                || token.hasSuffix("pcbnew.exe")
                || token.hasSuffix("eeschema.exe")
        }) {
            return .kiCadEDA
        }

        if tokens.contains(where: { token in
            token.contains("lenovo-app-store")
                || token.contains("lenovo")
                || token.contains("leappstore")
                || token.contains("联想应用商店")
        }) {
            return .lenovoAppStore
        }

        if tokens.contains(where: { token in
            token.contains("tencent-app-store")
                || token.contains("qqpcmgr")
                || token.contains("pcmgr.exe")
                || token.contains("qqphonemanager")
                || token.contains("pcyyb")
                || token.contains("tencentappstore")
                || token.contains("\\tencent\\appstore\\")
                || token.contains("/tencent/appstore/")
                || token.contains("androwslauncher.exe")
                || token.contains("\\tencent\\androws\\")
                || token.contains("/tencent/androws/")
                || token.contains("tencent-androws")
                || token.contains("腾讯应用市场")
                || token.contains("应用宝")
        }) {
            return .tencentAppStore
        }

        if tokens.contains(where: { token in
            token.contains("hoyoplay")
                || token.contains("hoyoverse")
                || token.contains("mihoyo")
                || token.contains("hyp.exe")
                || token.contains("米哈游")
        }) {
            return .hoYoPlay
        }

        if tokens.contains(where: { token in
            token.contains("jabref-portable")
                || token.contains("\\jabref\\jabref.exe")
                || token.contains("/jabref/jabref.exe")
                || token.hasSuffix("\\jabref.exe")
                || token.hasSuffix("/jabref.exe")
        }) {
            return .jabRefJavaFXD3D
        }

        if tokens.contains(where: { token in
            token.contains("jasp")
                || token.contains("jaspdesktop.exe")
        }) {
            return .jaspQtWebEngineQrc
        }

        if tokens.contains(where: { token in
            token.contains("meshlab")
                || token.contains("\\meshlab.exe")
                || token.contains("/meshlab.exe")
        }) {
            return .meshLabSoftwareOpenGL
        }

        if tokens.contains(where: { token in
            token.contains("geogebra-classic")
                || token.contains("geogebra calculator suite")
                || token.contains("\\macwin-portable\\geogebra-classic\\geogebra.exe")
                || token.contains("/macwin-portable/geogebra-classic/geogebra.exe")
        }) {
            return .geogebraLegacyElectron32
        }

        if tokens.contains(where: { token in
            token.contains("musescore")
        }) {
            return .museScoreStudio
        }

        if tokens.contains(where: { token in
            token.contains("gmsh")
                || token.contains("\\gmsh.exe")
                || token.contains("/gmsh.exe")
        }) {
            return .gmshOpenGL
        }

        if tokens.contains(where: { token in
            token.contains("qucs-s")
                || token.contains("qucs_s")
                || token.contains("\\qucs-s.exe")
                || token.contains("/qucs-s.exe")
        }) {
            return .qucsSQt6
        }

        if tokens.contains(where: { token in
            token.contains("otter-browser")
                || token.contains("otterbrowser")
                || token.contains("\\otter-browser.exe")
                || token.contains("/otter-browser.exe")
        }) {
            return .qtBrowserSoftware
        }

        if tokens.contains(where: { token in
            token.contains("qmodmaster")
                || token.contains("npackd")
                || token.contains("sqlitestudio")
                || token.contains("sqlite studio")
                || token.contains("\\sqlitestudio\\sqlitestudio.exe")
                || token.contains("/sqlitestudio/sqlitestudio.exe")
                || token.contains("\\qmodmaster.exe")
                || token.contains("/qmodmaster.exe")
        }) {
            return .qtWidgetsSoftware
        }

        if tokens.contains(where: { token in
            token.contains("wps-office")
                || token.contains("kingsoft")
                || token.contains("\\office6\\wps.exe")
                || token.contains("\\office6\\et.exe")
                || token.contains("\\office6\\wpp.exe")
                || token.contains("\\office6\\wpspdf.exe")
                || token.contains("/office6/wps.exe")
                || token.contains("/office6/et.exe")
                || token.contains("/office6/wpp.exe")
                || token.contains("/office6/wpspdf.exe")
        }) {
            return .wpsOffice
        }

        if tokens.contains(where: { token in
            token.contains("libreoffice")
                || token.contains("openoffice")
                || token.contains("\\program\\soffice.exe")
                || token.contains("\\program\\swriter.exe")
                || token.contains("\\program\\scalc.exe")
                || token.contains("\\program\\simpress.exe")
                || token.contains("/program/soffice.exe")
                || token.contains("/program/swriter.exe")
                || token.contains("/program/scalc.exe")
                || token.contains("/program/simpress.exe")
        }) {
            return .officeSuite
        }

        if tokens.contains(where: { token in
            token.contains("qelectrotech")
                || token.contains("qgroundcontrol")
                || token.contains("qt-rhi")
        }) {
            return .qtRhiSoftware
        }

        if tokens.contains(where: { token in
            token.contains("freeoffice")
                || token.contains("softmaker")
                || token.contains("textmaker.exe")
                || token.contains("planmaker.exe")
                || token.contains("presentations.exe")
        }) {
            return .softMakerOffice
        }

        if tokens.contains(where: { token in
            token.contains("texstudio")
                || token.contains("texstudio.exe")
        }) {
            return .texStudioQt6
        }

        if tokens.contains(where: { token in
            token.contains("notepad-plus-plus")
                || token.contains("notepad++")
                || token.contains("\\notepad++\\notepad++.exe")
                || token.contains("/notepad++/notepad++.exe")
        }) {
            return .notepadPlusPlusGDI
        }

        if tokens.contains(where: { token in
            token.contains("\\portableapps\\portableapps.com\\portableappsplatform.exe")
                || token.contains("/portableapps/portableapps.com/portableappsplatform.exe")
        }) {
            return .portableAppsPlatform
        }

        if tokens.contains(where: { token in
            token.contains("\\portableapps\\portableapps.com\\portableappsbackup.exe")
                || token.contains("/portableapps/portableapps.com/portableappsbackup.exe")
                || token.contains("\\portableapps\\portableapps.com\\portableappsbackuprestore.exe")
                || token.contains("/portableapps/portableapps.com/portableappsbackuprestore.exe")
                || token.contains("\\portableapps\\portableapps.com\\portableappsupdater.exe")
                || token.contains("/portableapps/portableapps.com/portableappsupdater.exe")
        }) {
            return .portableAppsUtility
        }

        if tokens.contains(where: { token in
            token == "7zip"
                || token.contains("7zip")
                || token.contains("7-zip")
                || token.contains("\\7-zip\\7zfm.exe")
                || token.contains("/7-zip/7zfm.exe")
                || token.contains("\\7-zip\\7zg.exe")
                || token.contains("/7-zip/7zg.exe")
        }) {
            return .sevenZipGDI
        }

        if tokens.contains(where: { token in
            token.contains("zotero-research")
                || token.contains("zotero.exe")
                || token.contains("\\zotero\\zotero.exe")
                || token.contains("/zotero/zotero.exe")
        }) {
            return .zoteroGecko32
        }

        if tokens.contains(where: { token in
            token.contains("firefox-browser")
                || token.contains("mozilla firefox")
                || token.contains("\\mozilla firefox\\firefox.exe")
                || token.contains("/mozilla firefox/firefox.exe")
                || token.hasSuffix("\\firefox.exe")
                || token.hasSuffix("/firefox.exe")
                || token.contains("thunderbird")
                || token.contains("\\mozilla thunderbird\\thunderbird.exe")
                || token.contains("/mozilla thunderbird/thunderbird.exe")
                || token.contains("waterfox")
        }) {
            return .browserGecko
        }

        if tokens.contains(where: { token in
            token.contains("mremoteng-1782-x64")
                || token.contains("mremoteng 1.78")
                || token.contains("mremoteng 1782")
                || token.contains("\\macwin-portable\\mremoteng-1782-x64\\mremoteng.exe")
                || token.contains("/macwin-portable/mremoteng-1782-x64/mremoteng.exe")
        }) {
            return .mRemoteNG1782
        }

        if tokens.contains(where: { token in
            token.contains("supermium-32-browser")
                || token.contains("supermium_144_32")
                || token.contains("supermium 32")
                || token.contains("supermium 32-bit")
                || token.contains("\\macwin-portable\\supermium-32-browser\\")
                || token.contains("/macwin-portable/supermium-32-browser/")
        }) {
            return .supermium32Browser
        }

        if tokens.contains(where: { token in
            token.contains("brave-browser")
                || token.contains("bravesoftware")
                || token.contains("opera-browser")
                || token.contains("opera software")
                || token.contains("google\\chrome")
                || token.contains("google/chrome")
                || token.contains("microsoft\\edge")
                || token.contains("microsoft/edge")
                || token.contains("vivaldi")
                || token.hasSuffix("\\application\\brave.exe")
                || token.hasSuffix("/application/brave.exe")
                || token.hasSuffix("\\application\\chrome.exe")
                || token.hasSuffix("/application/chrome.exe")
                || token.hasSuffix("\\application\\msedge.exe")
                || token.hasSuffix("/application/msedge.exe")
                || token.hasSuffix("\\application\\vivaldi.exe")
                || token.hasSuffix("/application/vivaldi.exe")
                || token.hasSuffix("\\opera\\opera.exe")
                || token.hasSuffix("/opera/opera.exe")
                || token.hasSuffix("\\opera-browser\\opera.exe")
                || token.hasSuffix("/opera-browser/opera.exe")
        }) {
            return .chromiumBrowser
        }

        if tokens.contains(where: { token in
            token.contains("openplc-editor")
                || token.contains("openplc editor")
                || token.hasSuffix("\\openplc editor.exe")
                || token.hasSuffix("/openplc editor.exe")
        }) {
            return .openPLCEditor
        }

        if tokens.contains(where: { token in
            token.contains("itch")
                || token.contains("electron")
                || token.contains("onlyoffice")
                || token.contains("desktopeditors")
        }) {
            return .cefSoftwareRenderer
        }

        return nil
    }

    public static func current(in launcher: LauncherManifest) -> ApplicationCompatibilityProfile? {
        let matchedProfile = matched(
            recipeId: launcher.appId,
            launcherId: launcher.id,
            displayName: launcher.displayName,
            exePath: launcher.exePath
        )

        if let rawValue = launcher.envOverrides["MACWIN_COMPAT_PROFILE"]?.lowercased() {
            if rawValue == disabledProfileValue {
                return nil
            }
            switch rawValue {
            case bambuStudioSoftwareOpenGL.rawValue:
                return .bambuStudioSoftwareOpenGL
            case blenderSoftwareOpenGL.rawValue:
                return .blenderSoftwareOpenGL
            case browserGecko.rawValue:
                return .browserGecko
            case steamClient.rawValue:
                return .steamClient
            case chromiumBrowser.rawValue:
                return .chromiumBrowser
            case curaSlicer.rawValue:
                return .curaSlicer
            case dbeaverSWT.rawValue:
                return .dbeaverSWT
            case freeCADOpenGL.rawValue:
                return .freeCADOpenGL
            case kiCadEDA.rawValue:
                return .kiCadEDA
            case libreCADQt.rawValue:
                return .libreCADQt
            case openPLCEditor.rawValue:
                return .openPLCEditor
            case openSCADSoftwareOpenGL.rawValue:
                return .openSCADSoftwareOpenGL
            case sweetHome3DOpenGL.rawValue:
                return .sweetHome3DOpenGL
            case kritaOpenGL.rawValue:
                return .kritaOpenGL
            case geogebraLegacyElectron32.rawValue:
                return .geogebraLegacyElectron32
            case gmshOpenGL.rawValue:
                return .gmshOpenGL
            case lenovoAppStore.rawValue:
                return .lenovoAppStore
            case meshLabSoftwareOpenGL.rawValue:
                return .meshLabSoftwareOpenGL
            case hoYoPlay.rawValue:
                return .hoYoPlay
            case jabRefJavaFXD3D.rawValue:
                return .jabRefJavaFXD3D
            case jaspQtWebEngineQrc.rawValue:
                return .jaspQtWebEngineQrc
            case mRemoteNG1782.rawValue:
                return .mRemoteNG1782
            case museScoreStudio.rawValue:
                return .museScoreStudio
            case notepadPlusPlusGDI.rawValue:
                return .notepadPlusPlusGDI
            case orcaSlicerNativeOpenGL.rawValue:
                return .orcaSlicerNativeOpenGL
            case portableAppsPlatform.rawValue:
                return .portableAppsPlatform
            case portableAppsUtility.rawValue:
                return .portableAppsUtility
            case qtBrowserSoftware.rawValue:
                return .qtBrowserSoftware
            case qucsSQt6.rawValue:
                return .qucsSQt6
            case qtRhiSoftware.rawValue:
                return .qtRhiSoftware
            case qtWidgetsSoftware.rawValue:
                return .qtWidgetsSoftware
            case softMakerOffice.rawValue:
                return .softMakerOffice
            case supermium32Browser.rawValue:
                return .supermium32Browser
            case tencentAppStore.rawValue:
                return .tencentAppStore
            case texStudioQt6.rawValue:
                return .texStudioQt6
            case sevenZipGDI.rawValue:
                return .sevenZipGDI
            case zoteroGecko32.rawValue:
                return .zoteroGecko32
            case cefSoftwareRenderer.rawValue, "cef-software-gl":
                if let matchedProfile, matchedProfile != .cefSoftwareRenderer {
                    return matchedProfile
                }
                return .cefSoftwareRenderer
            default:
                break
            }
        }

        return matchedProfile
    }

    private static func mergeArguments(_ first: [String], _ second: [String]) -> [String] {
        var result = first
        for argument in second where !result.contains(argument) {
            result.append(argument)
        }
        return sanitizedLaunchArguments(result)
    }

    public static func sanitizedLaunchArguments(_ arguments: [String]) -> [String] {
        var result: [String] = []
        var seenArguments: Set<String> = []
        var disabledFeatures: [String] = []
        var seenDisabledFeatures: Set<String> = []
        var disabledFeaturesIndex: Int?

        for argument in arguments {
            guard let sanitized = sanitizedLaunchArgument(argument),
                  !sanitized.isEmpty else {
                continue
            }

            if let features = disabledFeatureList(in: sanitized) {
                for feature in features {
                    let key = feature.lowercased()
                    guard !seenDisabledFeatures.contains(key) else { continue }
                    seenDisabledFeatures.insert(key)
                    disabledFeatures.append(feature)
                }

                guard !disabledFeatures.isEmpty else { continue }
                let merged = "--disable-features=\(disabledFeatures.joined(separator: ","))"
                if let disabledFeaturesIndex {
                    result[disabledFeaturesIndex] = merged
                } else {
                    disabledFeaturesIndex = result.count
                    result.append(merged)
                }
                continue
            }

            guard !seenArguments.contains(sanitized) else {
                continue
            }
            seenArguments.insert(sanitized)
            result.append(sanitized)
        }
        return result
    }

    public static func obsoleteTextRenderingFlags(in text: String) -> [String] {
        let lowercased = text.lowercased()
        var result: Set<String> = []
        for argument in obsoleteManagedLaunchArguments where lowercased.contains(argument.lowercased()) {
            result.insert(argument)
        }

        let disabledFeatures = disabledFeatureNames(in: text)
        for feature in obsoleteDisabledFeatures where disabledFeatures.contains(feature.lowercased()) {
            result.insert(feature)
        }
        return result.sorted()
    }

    private static func sanitizedLaunchArgument(_ argument: String) -> String? {
        guard !obsoleteManagedLaunchArguments.contains(argument) else { return nil }
        let prefix = "--disable-features="
        guard argument.hasPrefix(prefix) else { return argument }

        let features = (disabledFeatureList(in: argument) ?? [])
            .filter { !$0.isEmpty }
            .filter { !obsoleteDisabledFeatureNamesLowercased.contains($0.lowercased()) }

        guard !features.isEmpty else { return nil }
        return "\(prefix)\(features.joined(separator: ","))"
    }

    private static func disabledFeatureList(in argument: String) -> [String]? {
        let prefix = "--disable-features="
        guard argument.hasPrefix(prefix) else { return nil }
        return argument.dropFirst(prefix.count)
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func disabledFeatureNames(in text: String) -> Set<String> {
        let prefix = "--disable-features="
        var trimSet = CharacterSet.whitespacesAndNewlines
        trimSet.insert(charactersIn: "\"'")
        return Set(
            text.split(whereSeparator: { $0.isWhitespace })
                .map { String($0).trimmingCharacters(in: trimSet) }
                .filter { $0.lowercased().hasPrefix(prefix) }
                .flatMap { argument -> [String] in
                    let features = argument.dropFirst(prefix.count)
                    return features
                        .split(separator: ",")
                        .map { String($0).trimmingCharacters(in: trimSet).lowercased() }
                        .filter { !$0.isEmpty }
                }
        )
    }
}
