import Foundation

public enum BottleHealthSeverity: String, Codable, CaseIterable, Equatable, Sendable {
    case info
    case warning
    case high
}

public struct BottleHealthFinding: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var severity: BottleHealthSeverity
    public var bottleId: String
    public var launcherId: String?
    public var title: String
    public var detail: String
    public var recommendedAction: String
}

public struct BottleHealthLauncherReport: Codable, Equatable, Identifiable, Sendable {
    public var id: String { launcherId }
    public var launcherId: String
    public var appId: String
    public var displayName: String
    public var exePath: String
    public var matchedCompatibilityProfile: ApplicationCompatibilityProfile?
    public var appliedCompatibilityProfile: String?
    public var staleRenderingFlags: [String]
    public var missingCompatibilityEnvironmentKeys: [String]
    public var hasIconPath: Bool
    public var showInHome: Bool
}

public struct BottleHealthBottleReport: Codable, Equatable, Identifiable, Sendable {
    public var id: String { bottleId }
    public var bottleId: String
    public var name: String
    public var engineId: String
    public var arch: WineArch
    public var hasBottleDirectory: Bool
    public var hasDriveC: Bool
    public var hasWinebootSentinel: Bool
    public var hasFontConfig: Bool
    public var launcherCount: Int
    public var visibleLauncherCount: Int
    public var staleLauncherCount: Int
    public var incompleteCompatibilityProfileCount: Int
    public var findings: [BottleHealthFinding]
    public var launchers: [BottleHealthLauncherReport]
}

public struct BottleHealthAuditReport: Codable, Equatable, Sendable {
    public var rootPath: String
    public var bottleCount: Int
    public var healthyBottleCount: Int
    public var warningBottleCount: Int
    public var actionRequiredBottleCount: Int
    public var missingDriveCCount: Int
    public var missingWinebootSentinelCount: Int
    public var missingFontConfigCount: Int
    public var staleLauncherCount: Int
    public var incompleteCompatibilityProfileCount: Int
    public var findingCount: Int
    public var highFindingCount: Int
    public var warningFindingCount: Int
    public var findings: [BottleHealthFinding]
    public var bottles: [BottleHealthBottleReport]

    public init(rootPath: String, bottles: [BottleHealthBottleReport]) {
        self.rootPath = rootPath
        self.bottleCount = bottles.count
        self.healthyBottleCount = bottles.filter(\.findings.isEmpty).count
        self.warningBottleCount = bottles.filter { bottle in
            bottle.findings.contains { $0.severity == .warning }
                && !bottle.findings.contains { $0.severity == .high }
        }.count
        self.actionRequiredBottleCount = bottles.filter { bottle in
            bottle.findings.contains { $0.severity == .high }
        }.count
        self.missingDriveCCount = bottles.filter { !$0.hasDriveC }.count
        self.missingWinebootSentinelCount = bottles.filter { !$0.hasWinebootSentinel }.count
        self.missingFontConfigCount = bottles.filter { !$0.hasFontConfig }.count
        self.staleLauncherCount = bottles.map(\.staleLauncherCount).reduce(0, +)
        self.incompleteCompatibilityProfileCount = bottles.map(\.incompleteCompatibilityProfileCount).reduce(0, +)
        self.findings = bottles.flatMap(\.findings).sorted { lhs, rhs in
            let lhsRank = Self.severityRank(lhs.severity)
            let rhsRank = Self.severityRank(rhs.severity)
            if lhsRank != rhsRank {
                return lhsRank < rhsRank
            }
            if lhs.bottleId != rhs.bottleId {
                return lhs.bottleId < rhs.bottleId
            }
            return (lhs.launcherId ?? "") < (rhs.launcherId ?? "")
        }
        self.findingCount = findings.count
        self.highFindingCount = findings.filter { $0.severity == .high }.count
        self.warningFindingCount = findings.filter { $0.severity == .warning }.count
        self.bottles = bottles.sorted { $0.bottleId < $1.bottleId }
    }

    private static func severityRank(_ severity: BottleHealthSeverity) -> Int {
        switch severity {
        case .high: 0
        case .warning: 1
        case .info: 2
        }
    }
}

public struct BottleHealthAuditService {
    public var paths: MacWinPaths
    public var fileManager: FileManager

    public init(paths: MacWinPaths = MacWinPaths(), fileManager: FileManager = .default) {
        self.paths = paths
        self.fileManager = fileManager
    }

    public func report(bottles: [BottleManifest]) -> BottleHealthAuditReport {
        BottleHealthAuditReport(
            rootPath: paths.root.path,
            bottles: bottles.map(bottleReport)
        )
    }

    private func bottleReport(_ bottle: BottleManifest) -> BottleHealthBottleReport {
        let bottleDirectory = paths.bottleDirectory(id: bottle.id)
        let driveC = paths.bottleDriveCURL(id: bottle.id)
        let hasBottleDirectory = fileManager.fileExists(atPath: bottleDirectory.path)
        let hasDriveC = fileManager.fileExists(atPath: driveC.path)
        let hasWinebootSentinel = fileManager.fileExists(
            atPath: bottleDirectory
                .appendingPathComponent(BottleService.winebootSentinelName)
                .path
        )
        let hasFontConfig = fileManager.fileExists(atPath: BottleService.fontConfigURL(for: bottle.id, paths: paths).path)
        let launchers = bottle.installedApps.map { launcherReport(launcher: $0) }
        var findings: [BottleHealthFinding] = []

        if !hasDriveC && bottle.installedApps.isEmpty {
            findings.append(
                BottleHealthFinding(
                    id: "\(bottle.id):empty-placeholder",
                    severity: .warning,
                    bottleId: bottle.id,
                    launcherId: nil,
                    title: "Bottle placeholder is incomplete",
                    detail: "The bottle only has metadata and no drive_c or launchers. It is likely an unfinished install attempt rather than an active Windows environment.",
                    recommendedAction: "Remove the placeholder or recreate the app from the Market when needed."
                )
            )
        } else if !hasDriveC {
            findings.append(
                BottleHealthFinding(
                    id: "\(bottle.id):missing-drive-c",
                    severity: .high,
                    bottleId: bottle.id,
                    launcherId: nil,
                    title: "Bottle drive_c is missing",
                    detail: "The bottle does not have a drive_c directory, so launchers and Windows tools cannot start reliably.",
                    recommendedAction: "Recreate the bottle or run wineboot before launching apps."
                )
            )
        }
        if hasDriveC && !hasWinebootSentinel {
            findings.append(
                BottleHealthFinding(
                    id: "\(bottle.id):missing-wineboot-sentinel",
                    severity: .warning,
                    bottleId: bottle.id,
                    launcherId: nil,
                    title: "Wineboot completion marker is missing",
                    detail: "The bottle has drive_c but MacWin has not recorded a completed wineboot bootstrap.",
                    recommendedAction: "Run bottle repair or wineboot -u once before installing more software."
                )
            )
        }
        if hasDriveC && !hasFontConfig {
            findings.append(
                BottleHealthFinding(
                    id: "\(bottle.id):missing-fontconfig",
                    severity: .warning,
                    bottleId: bottle.id,
                    launcherId: nil,
                    title: "Font fallback configuration is missing",
                    detail: "The bottle is missing MacWin's per-bottle fonts.conf, which can cause blank or incomplete text in WebView apps.",
                    recommendedAction: "Run bottle repair to regenerate font fallback and relaunch affected apps."
                )
            )
        }

        for launcher in launchers {
            if !launcher.staleRenderingFlags.isEmpty {
                findings.append(
                    BottleHealthFinding(
                        id: "\(bottle.id):\(launcher.launcherId):stale-rendering-flags",
                        severity: .high,
                        bottleId: bottle.id,
                        launcherId: launcher.launcherId,
                        title: "Launcher still carries obsolete text-rendering flags",
                        detail: "Obsolete flags remain: \(launcher.staleRenderingFlags.joined(separator: ", ")).",
                        recommendedAction: "Reapply the app compatibility profile, quit existing helper processes, and relaunch through MacWin Manager."
                    )
                )
            }
            if !launcher.missingCompatibilityEnvironmentKeys.isEmpty {
                findings.append(
                    BottleHealthFinding(
                        id: "\(bottle.id):\(launcher.launcherId):incomplete-compat-profile",
                        severity: .warning,
                        bottleId: bottle.id,
                        launcherId: launcher.launcherId,
                        title: "Compatibility profile is not fully applied",
                        detail: "Missing managed environment keys: \(launcher.missingCompatibilityEnvironmentKeys.joined(separator: ", ")).",
                        recommendedAction: "Apply the detected compatibility profile again before judging rendering or input behavior."
                    )
                )
            }
        }

        return BottleHealthBottleReport(
            bottleId: bottle.id,
            name: bottle.name,
            engineId: bottle.engineId,
            arch: bottle.arch,
            hasBottleDirectory: hasBottleDirectory,
            hasDriveC: hasDriveC,
            hasWinebootSentinel: hasWinebootSentinel,
            hasFontConfig: hasFontConfig,
            launcherCount: bottle.installedApps.count,
            visibleLauncherCount: bottle.installedApps.filter(\.showInHome).count,
            staleLauncherCount: launchers.filter { !$0.staleRenderingFlags.isEmpty }.count,
            incompleteCompatibilityProfileCount: launchers.filter { !$0.missingCompatibilityEnvironmentKeys.isEmpty }.count,
            findings: findings,
            launchers: launchers
        )
    }

    private func launcherReport(launcher: LauncherManifest) -> BottleHealthLauncherReport {
        let matchedProfile = ApplicationCompatibilityProfile.current(in: launcher)
        let launchText = ([launcher.exePath] + launcher.args + launcher.envOverrides.map { "\($0.key)=\($0.value)" }).joined(separator: " ")
        let staleFlags = ApplicationCompatibilityProfile.obsoleteTextRenderingFlags(in: launchText)
        let missingKeys = matchedProfile.map { missingCompatibilityEnvironmentKeys(profile: $0, launcher: launcher) } ?? []

        return BottleHealthLauncherReport(
            launcherId: launcher.id,
            appId: launcher.appId,
            displayName: launcher.displayName,
            exePath: launcher.exePath,
            matchedCompatibilityProfile: matchedProfile,
            appliedCompatibilityProfile: launcher.envOverrides["MACWIN_COMPAT_PROFILE"],
            staleRenderingFlags: staleFlags,
            missingCompatibilityEnvironmentKeys: missingKeys,
            hasIconPath: launcher.iconPath?.isEmpty == false,
            showInHome: launcher.showInHome
        )
    }

    private func missingCompatibilityEnvironmentKeys(
        profile: ApplicationCompatibilityProfile,
        launcher: LauncherManifest
    ) -> [String] {
        Self.requiredCompatibilityEnvironmentKeys(for: profile).filter { key in
            guard let expected = profile.environment[key] else { return false }
            return launcher.envOverrides[key] != expected
        }.sorted()
    }

    private static func requiredCompatibilityEnvironmentKeys(for profile: ApplicationCompatibilityProfile) -> Set<String> {
        var keys = Set([
            "MACWIN_COMPAT_PROFILE",
            "MACWIN_FONTCONFIG_REPAIR",
            "MACWIN_TEXT_RENDERING_REPAIR",
            "FREETYPE_PROPERTIES"
        ].filter { profile.environment.keys.contains($0) })
        switch profile {
        case .bambuStudioSoftwareOpenGL:
            keys.formUnion([
                "GALLIUM_DRIVER",
                "LIBGL_ALWAYS_SOFTWARE",
                "MACWIN_APP_MODE_INPUT_REPAIR",
                "MACWIN_BAMBU_STUDIO_RUNTIME_REPAIR",
                "MACWIN_FORCE_MOUSE_FOCUS",
                "MACWIN_LAUNCH_CWD",
                "MACWIN_OPENGL_VIEWPORT_REPAIR",
                "MESA_GLSL_VERSION_OVERRIDE",
                "MESA_GL_VERSION_OVERRIDE",
                "WINE_D3D_CONFIG",
                "WINEDLLOVERRIDES"
            ])
        case .blenderSoftwareOpenGL:
            keys.formUnion([
                "GALLIUM_DRIVER",
                "LIBGL_ALWAYS_SOFTWARE",
                "MACWIN_APP_MODE_INPUT_REPAIR",
                "MACWIN_BLENDER_SOFTWARE_OPENGL_REPAIR",
                "MACWIN_FORCE_MOUSE_FOCUS",
                "MACWIN_LAUNCH_CWD",
                "MACWIN_OPENGL_VIEWPORT_REPAIR",
                "MESA_LOADER_DRIVER_OVERRIDE",
                "WINE_D3D_CONFIG",
                "WINEDLLOVERRIDES"
            ])
        case .browserGecko:
            keys.formUnion(["MACWIN_DISABLE_WINE_D3D_CONFIG", "MACWIN_GECKO_BROWSER_REPAIR", "MACWIN_GECKO_PROFILE_REPAIR", "MACWIN_LAUNCH_CWD", "MOZ_WEBRENDER"])
        case .cefSoftwareRenderer:
            keys.formUnion(["MACWIN_CHROMIUM_HELPER_ARGS", "QTWEBENGINE_CHROMIUM_FLAGS", "QTWEBENGINE_DISABLE_SANDBOX"])
        case .chromiumBrowser:
            keys.formUnion(["MACWIN_CHROMIUM_BROWSER_REPAIR", "MACWIN_CHROMIUM_HELPER_ARGS", "MACWIN_LAUNCH_CWD"])
        case .curaSlicer:
            keys.formUnion(["MACWIN_APP_MODE_INPUT_REPAIR", "MACWIN_CURA_PROFILE_REPAIR", "MACWIN_FORCE_MOUSE_FOCUS", "MACWIN_LAUNCH_CWD", "QT_OPENGL", "WINE_D3D_CONFIG"])
        case .kritaOpenGL:
            keys.formUnion(["MACWIN_APP_MODE_INPUT_REPAIR", "MACWIN_FORCE_MOUSE_FOCUS", "MACWIN_KRITA_OPENGL_REPAIR", "MACWIN_LAUNCH_CWD", "PYTHONHASHSEED", "QT_OPENGL", "ROSETTA_X87_PATH", "WINE_D3D_CONFIG"])
        case .geogebraLegacyElectron32:
            keys.formUnion(["MACWIN_CHROMIUM_HELPER_ARGS", "MACWIN_DISABLE_WINE_D3D_CONFIG", "MACWIN_GEOGEBRA_ELECTRON32_REPAIR", "MACWIN_LAUNCH_CWD", "MACWIN_WOW64_BROWSER_REPAIR"])
        case .gmshOpenGL:
            keys.formUnion(["MACWIN_ACTIVATE_WINE_APP", "MACWIN_APP_MODE_INPUT_REPAIR", "MACWIN_FORCE_MOUSE_FOCUS", "MACWIN_LAUNCH_CWD", "MACWIN_OPENGL_VIEWPORT_REPAIR", "WINE_D3D_CONFIG"])
        case .freeCADOpenGL:
            keys.formUnion(["MACWIN_APP_MODE_INPUT_REPAIR", "MACWIN_FONTCONFIG_REPAIR", "MACWIN_FORCE_MOUSE_FOCUS", "MACWIN_FREECAD_PYTHON_REPAIR", "MACWIN_LAUNCH_CWD", "MACWIN_OPENGL_VIEWPORT_REPAIR", "MACWIN_TEXT_RENDERING_REPAIR", "QT_OPENGL", "WINE_D3D_CONFIG"])
        case .kiCadEDA:
            keys.formUnion(["MACWIN_APP_MODE_INPUT_REPAIR", "MACWIN_FONTCONFIG_REPAIR", "MACWIN_FONT_FALLBACK_REPAIR", "MACWIN_FORCE_MOUSE_FOCUS", "MACWIN_LAUNCH_CWD", "MACWIN_OPENGL_VIEWPORT_REPAIR", "MACWIN_TEXT_RENDERING_REPAIR", "ROSETTA_X87_PATH", "WINE_D3D_CONFIG"])
        case .libreCADQt:
            keys.formUnion(["MACWIN_APP_MODE_INPUT_REPAIR", "MACWIN_FONTCONFIG_REPAIR", "MACWIN_FONT_FALLBACK_REPAIR", "MACWIN_FORCE_MOUSE_FOCUS", "MACWIN_LAUNCH_CWD", "MACWIN_LIBRECAD_PROFILE_REPAIR", "MACWIN_OPENGL_VIEWPORT_REPAIR", "MACWIN_TEXT_RENDERING_REPAIR", "QT_OPENGL", "WINE_D3D_CONFIG"])
        case .meshLabSoftwareOpenGL:
            keys.formUnion(["LIBGL_ALWAYS_SOFTWARE", "MACWIN_APP_MODE_INPUT_REPAIR", "MACWIN_FORCE_MOUSE_FOCUS", "MACWIN_LAUNCH_CWD", "MACWIN_MESHLAB_SOFTWARE_OPENGL_REPAIR", "MACWIN_OPENGL_VIEWPORT_REPAIR", "QT_OPENGL", "WINEDLLOVERRIDES"])
        case .openSCADSoftwareOpenGL:
            keys.formUnion(["LIBGL_ALWAYS_SOFTWARE", "MACWIN_APP_MODE_INPUT_REPAIR", "MACWIN_FORCE_MOUSE_FOCUS", "MACWIN_LAUNCH_CWD", "MACWIN_OPENGL_VIEWPORT_REPAIR", "MACWIN_OPENSCAD_SOFTWARE_OPENGL_REPAIR", "QT_OPENGL", "WINE_D3D_CONFIG", "WINEDLLOVERRIDES"])
        case .openPLCEditor:
            keys.formUnion(["MACWIN_APP_MODE_INPUT_REPAIR", "MACWIN_CHROMIUM_HELPER_ARGS", "MACWIN_FORCE_MOUSE_FOCUS", "MACWIN_LAUNCH_CWD", "MACWIN_OPENPLC_ELECTRON_REPAIR", "TZ", "WINE_D3D_CONFIG"])
        case .sweetHome3DOpenGL:
            keys.formUnion(["_JAVA_OPTIONS", "MACWIN_APP_MODE_INPUT_REPAIR", "MACWIN_FORCE_MOUSE_FOCUS", "MACWIN_LAUNCH_CWD", "MACWIN_OPENGL_VIEWPORT_REPAIR", "MACWIN_SWEETHOME3D_OPENGL_REPAIR", "WINE_D3D_CONFIG"])
        case .supermium32Browser:
            keys.formUnion(["MACWIN_CHROMIUM_BROWSER_REPAIR", "MACWIN_CHROMIUM_HELPER_ARGS", "MACWIN_DISABLE_WINE_D3D_CONFIG", "MACWIN_LAUNCH_CWD", "MACWIN_WOW64_BROWSER_REPAIR"])
        case .hoYoPlay:
            keys.formUnion(["MACWIN_CHROMIUM_HELPER_ARGS", "MACWIN_HOYOPLAY_TEXT_REPAIR", "QTWEBENGINE_CHROMIUM_FLAGS", "QTWEBENGINE_DISABLE_SANDBOX"])
        case .jabRefJavaFXD3D:
            keys.formUnion(["JAVA_TOOL_OPTIONS", "MACWIN_APP_MODE_INPUT_REPAIR", "MACWIN_FORCE_MOUSE_FOCUS", "MACWIN_JABREF_JAVAFX_REPAIR", "MACWIN_LAUNCH_CWD", "WINE_D3D_CONFIG", "WINEDLLOVERRIDES"])
        case .jaspQtWebEngineQrc:
            keys.formUnion(["MACWIN_FORCE_MOUSE_FOCUS", "MACWIN_JASP_QRC_REPAIR", "MACWIN_JASP_STARTUP_REPAIR", "MACWIN_LAUNCH_CWD", "MACWIN_QTWEBENGINE_REPAIR", "PATH", "QML2_IMPORT_PATH", "QT_OPENGL", "QT_PLUGIN_PATH", "QT_QPA_PLATFORM_PLUGIN_PATH", "QTWEBENGINE_CHROMIUM_FLAGS", "QTWEBENGINE_DISABLE_SANDBOX", "QTWEBENGINEPROCESS_PATH", "QTWEBENGINE_RESOURCES_PATH"])
        case .lenovoAppStore:
            keys.formUnion(["MACWIN_CHROMIUM_HELPER_ARGS", "MACWIN_LENOVO_BLACK_SCREEN_REPAIR", "QTWEBENGINE_CHROMIUM_FLAGS", "QTWEBENGINE_DISABLE_SANDBOX"])
        case .tencentAppStore:
            keys.formUnion(["MACWIN_CHROMIUM_HELPER_ARGS", "MACWIN_TENCENT_APP_STORE_REPAIR", "MACWIN_WEBVIEW_SOFTWARE_RENDERER", "QTWEBENGINE_CHROMIUM_FLAGS", "QTWEBENGINE_DISABLE_SANDBOX"])
        case .mRemoteNG1782:
            keys.formUnion(["DOTNET_ROOT", "DOTNET_ROOT_X64", "MACWIN_DOTNET_DESKTOP10_RUNTIME_REPAIR", "MACWIN_LAUNCH_CWD", "MACWIN_MREMOTENG_REPAIR", "PATH"])
        case .museScoreStudio:
            keys.formUnion(["MACWIN_APP_MODE_INPUT_REPAIR", "MACWIN_FORCE_MOUSE_FOCUS", "MACWIN_MUSESCORE_WELCOME_REPAIR", "MACWIN_QT_RHI_SOFTWARE_REPAIR", "QT_OPENGL", "QT_QUICK_BACKEND", "QT_QUICK_CONTROLS_STYLE", "QT_RHI_BACKEND", "QSG_RENDER_LOOP", "QSG_RHI_BACKEND"])
        case .qtRhiSoftware:
            keys.formUnion(["MACWIN_APP_MODE_INPUT_REPAIR", "MACWIN_FORCE_MOUSE_FOCUS", "MACWIN_LAUNCH_CWD", "MACWIN_QT_RHI_SOFTWARE_REPAIR", "QT_OPENGL", "QSG_RENDER_LOOP", "QSG_RHI_BACKEND", "WINE_D3D_CONFIG"])
        case .notepadPlusPlusGDI:
            keys.formUnion(["MACWIN_ACTIVATE_WINE_APP", "MACWIN_APP_MODE_INPUT_REPAIR", "MACWIN_DISABLE_WINE_APP_ACTIVATION", "MACWIN_DISABLE_WINE_D3D_CONFIG"])
        case .portableAppsPlatform:
            keys.formUnion(["MACWIN_ACTIVATE_WINE_APP", "MACWIN_APP_MODE_INPUT_REPAIR", "MACWIN_DISABLE_WINE_APP_ACTIVATION", "MACWIN_DISABLE_WINE_D3D_CONFIG", "MACWIN_LAUNCH_CWD", "MACWIN_PORTABLEAPPS_PLATFORM_REPAIR", "WINEDLLOVERRIDES"])
        case .portableAppsUtility:
            keys.formUnion(["MACWIN_ACTIVATE_WINE_APP", "MACWIN_APP_MODE_INPUT_REPAIR", "MACWIN_DISABLE_WINE_APP_ACTIVATION", "MACWIN_DISABLE_WINE_D3D_CONFIG", "MACWIN_LAUNCH_CWD", "MACWIN_PORTABLEAPPS_HELPER_REPAIR"])
        case .officeSuite:
            keys.formUnion(["MACWIN_APP_MODE_INPUT_REPAIR", "MACWIN_FORCE_MOUSE_FOCUS", "MACWIN_LAUNCH_CWD", "MACWIN_OFFICE_SUITE_REPAIR", "WINE_D3D_CONFIG"])
        case .orcaSlicerNativeOpenGL:
            keys.formUnion(["MACWIN_APP_MODE_INPUT_REPAIR", "MACWIN_FORCE_MOUSE_FOCUS", "MACWIN_LAUNCH_CWD", "MACWIN_OPENGL_VIEWPORT_REPAIR", "MACWIN_ORCASLICER_RUNTIME_REPAIR", "WINE_D3D_CONFIG", "WINEDLLOVERRIDES"])
        case .wpsOffice:
            keys.formUnion(["MACWIN_APP_MODE_INPUT_REPAIR", "MACWIN_FORCE_MOUSE_FOCUS", "MACWIN_LAUNCH_CWD", "MACWIN_WPS_OFFICE_REPAIR", "QT_FONT_DPI", "WINE_D3D_CONFIG"])
        case .qtBrowserSoftware:
            keys.formUnion(["MACWIN_APP_MODE_INPUT_REPAIR", "MACWIN_FORCE_MOUSE_FOCUS", "MACWIN_LAUNCH_CWD", "MACWIN_QT_BROWSER_REPAIR", "QT_OPENGL", "QT_QUICK_BACKEND", "QT_STYLE_OVERRIDE"])
        case .qtWidgetsSoftware:
            keys.formUnion(["MACWIN_QT_WIDGETS_REPAIR"])
        case .qucsSQt6:
            keys.formUnion(["MACWIN_APP_MODE_INPUT_REPAIR", "MACWIN_FORCE_MOUSE_FOCUS", "MACWIN_LAUNCH_CWD", "MACWIN_QT_WIDGETS_REPAIR", "PATH", "QT_OPENGL", "QT_PLUGIN_PATH", "QT_QPA_PLATFORM_PLUGIN_PATH", "QT_STYLE_OVERRIDE"])
        case .softMakerOffice:
            keys.formUnion(["MACWIN_COM_PROXY_REPAIR", "MACWIN_FORCE_MOUSE_FOCUS", "MACWIN_SOFTMAKER_OFFICE_REPAIR"])
        case .steamClient:
            keys.formUnion(["MACWIN_CHROMIUM_HELPER_ARGS", "MACWIN_STEAMWEBHELPER_ARGS", "MACWIN_STEAMWEBHELPER_FORCE_OPAQUE"])
        case .texStudioQt6:
            keys.formUnion(["MACWIN_FORCE_MOUSE_FOCUS", "MACWIN_TEXSTUDIO_QT6_REPAIR", "QT_OPENGL", "QT_QUICK_BACKEND", "QT_STYLE_OVERRIDE", "QT_FONT_DPI"])
        case .sevenZipGDI:
            keys.formUnion(["MACWIN_ACTIVATE_WINE_APP", "MACWIN_APP_MODE_INPUT_REPAIR", "MACWIN_DISABLE_WINE_APP_ACTIVATION", "MACWIN_DISABLE_WINE_D3D_CONFIG"])
        case .zoteroGecko32:
            keys.formUnion(["MACWIN_DISABLE_WINE_D3D_CONFIG", "MACWIN_GECKO_PROFILE_REPAIR", "MACWIN_WOW64_BROWSER_REPAIR", "MACWIN_ZOTERO_GECKO32_REPAIR", "MOZ_WEBRENDER"])
        }
        return keys
    }
}
