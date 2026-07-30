import Foundation

public enum CompatibilityRepairAuditState: String, Codable, Equatable, Sendable {
    case ready
    case missingRepairs
    case staleFlags
}

public struct CompatibilityRepairAuditEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: String { launchRecordId }
    public var launchRecordId: String
    public var logPath: String
    public var startedAt: Date
    public var bottleId: String
    public var bottleName: String
    public var exe: String
    public var profile: String
    public var state: CompatibilityRepairAuditState
    public var requiredRepairKeys: [String]
    public var presentRepairKeys: [String]
    public var missingRepairKeys: [String]
    public var staleRenderingFlags: [String]

    public init(
        launchRecordId: String,
        logPath: String,
        startedAt: Date,
        bottleId: String,
        bottleName: String,
        exe: String,
        profile: String,
        state: CompatibilityRepairAuditState,
        requiredRepairKeys: [String],
        presentRepairKeys: [String],
        missingRepairKeys: [String],
        staleRenderingFlags: [String]
    ) {
        self.launchRecordId = launchRecordId
        self.logPath = logPath
        self.startedAt = startedAt
        self.bottleId = bottleId
        self.bottleName = bottleName
        self.exe = exe
        self.profile = profile
        self.state = state
        self.requiredRepairKeys = requiredRepairKeys
        self.presentRepairKeys = presentRepairKeys
        self.missingRepairKeys = missingRepairKeys
        self.staleRenderingFlags = staleRenderingFlags
    }
}

public struct CompatibilityRepairFinding: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var severity: String
    public var title: String
    public var detail: String
    public var affectedLaunchRecordIds: [String]
    public var affectedLogPaths: [String]
    public var missingRepairKeys: [String]
    public var staleRenderingFlags: [String]
    public var recommendedActions: [String]
}

public struct CompatibilityRuntimeCoverageEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var engineId: String
    public var engineName: String
    public var profile: String
    public var state: CompatibilityRepairAuditState
    public var affectedBottleIds: [String]
    public var affectedBottleNames: [String]
    public var affectedLauncherIds: [String]
    public var requiredSourcePaths: [String]
    public var presentSourcePaths: [String]
    public var missingSourcePaths: [String]

    public init(
        id: String,
        engineId: String,
        engineName: String,
        profile: String,
        state: CompatibilityRepairAuditState,
        affectedBottleIds: [String],
        affectedBottleNames: [String],
        affectedLauncherIds: [String],
        requiredSourcePaths: [String],
        presentSourcePaths: [String],
        missingSourcePaths: [String]
    ) {
        self.id = id
        self.engineId = engineId
        self.engineName = engineName
        self.profile = profile
        self.state = state
        self.affectedBottleIds = affectedBottleIds
        self.affectedBottleNames = affectedBottleNames
        self.affectedLauncherIds = affectedLauncherIds
        self.requiredSourcePaths = requiredSourcePaths
        self.presentSourcePaths = presentSourcePaths
        self.missingSourcePaths = missingSourcePaths
    }
}

public struct CompatibilityRepairAuditReport: Codable, Equatable, Sendable {
    public var totalLaunchCount: Int
    public var auditedLaunchCount: Int
    public var readyLaunchCount: Int
    public var missingRepairLaunchCount: Int
    public var staleFlagLaunchCount: Int
    public var entries: [CompatibilityRepairAuditEntry]
    public var runtimeCoverageEntries: [CompatibilityRuntimeCoverageEntry]
    public var missingRuntimeCoverageCount: Int
    public var findings: [CompatibilityRepairFinding]

    public init(
        totalLaunchCount: Int,
        auditedLaunchCount: Int,
        readyLaunchCount: Int,
        missingRepairLaunchCount: Int,
        staleFlagLaunchCount: Int,
        entries: [CompatibilityRepairAuditEntry],
        runtimeCoverageEntries: [CompatibilityRuntimeCoverageEntry] = [],
        missingRuntimeCoverageCount: Int = 0,
        findings: [CompatibilityRepairFinding]
    ) {
        self.totalLaunchCount = totalLaunchCount
        self.auditedLaunchCount = auditedLaunchCount
        self.readyLaunchCount = readyLaunchCount
        self.missingRepairLaunchCount = missingRepairLaunchCount
        self.staleFlagLaunchCount = staleFlagLaunchCount
        self.entries = entries
        self.runtimeCoverageEntries = runtimeCoverageEntries
        self.missingRuntimeCoverageCount = missingRuntimeCoverageCount
        self.findings = findings
    }

    private enum CodingKeys: String, CodingKey {
        case totalLaunchCount
        case auditedLaunchCount
        case readyLaunchCount
        case missingRepairLaunchCount
        case staleFlagLaunchCount
        case entries
        case runtimeCoverageEntries
        case missingRuntimeCoverageCount
        case findings
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalLaunchCount = try container.decode(Int.self, forKey: .totalLaunchCount)
        auditedLaunchCount = try container.decode(Int.self, forKey: .auditedLaunchCount)
        readyLaunchCount = try container.decode(Int.self, forKey: .readyLaunchCount)
        missingRepairLaunchCount = try container.decode(Int.self, forKey: .missingRepairLaunchCount)
        staleFlagLaunchCount = try container.decode(Int.self, forKey: .staleFlagLaunchCount)
        entries = try container.decode([CompatibilityRepairAuditEntry].self, forKey: .entries)
        runtimeCoverageEntries = try container.decodeIfPresent(
            [CompatibilityRuntimeCoverageEntry].self,
            forKey: .runtimeCoverageEntries
        ) ?? []
        missingRuntimeCoverageCount = try container.decodeIfPresent(
            Int.self,
            forKey: .missingRuntimeCoverageCount
        ) ?? runtimeCoverageEntries.filter { !$0.missingSourcePaths.isEmpty }.count
        findings = try container.decode([CompatibilityRepairFinding].self, forKey: .findings)
    }
}

public struct CompatibilityRepairAuditService: @unchecked Sendable {
    public var fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func makeReport(
        launchHistory: LaunchHistoryReport?,
        engines: [EngineManifest] = [],
        bottles: [BottleManifest] = []
    ) -> CompatibilityRepairAuditReport {
        Self.report(
            records: launchHistory?.records ?? [],
            totalLaunchCount: launchHistory?.totalLaunchCount ?? 0,
            runtimeCoverageEntries: runtimeCoverageEntries(engines: engines, bottles: bottles)
        )
    }

    public static func report(
        records: [WineLaunchRecord],
        totalLaunchCount: Int? = nil,
        runtimeCoverageEntries: [CompatibilityRuntimeCoverageEntry] = []
    ) -> CompatibilityRepairAuditReport {
        let entries = records.compactMap(auditEntry).sorted {
            if $0.startedAt == $1.startedAt {
                return $0.launchRecordId > $1.launchRecordId
            }
            return $0.startedAt > $1.startedAt
        }
        let missingEntries = entries.filter { !$0.missingRepairKeys.isEmpty }
        let staleEntries = entries.filter { !$0.staleRenderingFlags.isEmpty }
        let missingRuntimeCoverage = runtimeCoverageEntries.filter { !$0.missingSourcePaths.isEmpty }
        return CompatibilityRepairAuditReport(
            totalLaunchCount: totalLaunchCount ?? records.count,
            auditedLaunchCount: entries.count,
            readyLaunchCount: entries.filter { $0.state == .ready }.count,
            missingRepairLaunchCount: missingEntries.count,
            staleFlagLaunchCount: staleEntries.count,
            entries: entries,
            runtimeCoverageEntries: runtimeCoverageEntries,
            missingRuntimeCoverageCount: missingRuntimeCoverage.count,
            findings: findings(
                missingEntries: missingEntries,
                staleEntries: staleEntries,
                missingRuntimeCoverage: missingRuntimeCoverage
            )
        )
    }

    public func runtimeCoverageEntries(
        engines: [EngineManifest],
        bottles: [BottleManifest]
    ) -> [CompatibilityRuntimeCoverageEntry] {
        let enginesById = Dictionary(uniqueKeysWithValues: engines.map { ($0.id, $0) })
        let wpsBottles = bottles.compactMap { bottle -> (BottleManifest, [LauncherManifest])? in
            let launchers = bottle.installedApps.filter { launcher in
                if launcher.envOverrides["MACWIN_COMPAT_PROFILE"] == ApplicationCompatibilityProfile.wpsOffice.rawValue {
                    return true
                }
                return ApplicationCompatibilityProfile.matched(
                    launcherId: launcher.id,
                    exePath: launcher.exePath
                ) == .wpsOffice
            }
            return launchers.isEmpty ? nil : (bottle, launchers)
        }
        let grouped = Dictionary(grouping: wpsBottles, by: { $0.0.engineId })
        return grouped.compactMap { engineId, matches in
            guard let engine = enginesById[engineId] else { return nil }
            let sources = EngineRuntimeCoverage.wpsOfficeFltlibSources(for: engine)
            let present = sources.filter { fileManager.fileExists(atPath: $0.path) }
            let missing = sources.filter { !fileManager.fileExists(atPath: $0.path) }
            return CompatibilityRuntimeCoverageEntry(
                id: "\(engine.id)-\(ApplicationCompatibilityProfile.wpsOffice.rawValue)-fltlib",
                engineId: engine.id,
                engineName: engine.name,
                profile: ApplicationCompatibilityProfile.wpsOffice.rawValue,
                state: missing.isEmpty ? .ready : .missingRepairs,
                affectedBottleIds: matches.map { $0.0.id }.sorted(),
                affectedBottleNames: matches.map { $0.0.name }.sorted(),
                affectedLauncherIds: matches.flatMap { $0.1 }.map(\.id).sorted(),
                requiredSourcePaths: sources.map(\.path),
                presentSourcePaths: present.map(\.path),
                missingSourcePaths: missing.map(\.path)
            )
        }
        .sorted { $0.id < $1.id }
    }

    private static func auditEntry(record: WineLaunchRecord) -> CompatibilityRepairAuditEntry? {
        let profile = profile(for: record)
        let staleFlags = staleRenderingFlags(in: record)
        guard let profile = profile ?? (staleFlags.isEmpty ? nil : .cefSoftwareRenderer) else {
            return nil
        }

        let requiredKeys = requiredRepairKeys(for: profile)
        let presentKeys = requiredKeys.filter { key in
            let value = record.environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines)
            return value?.isEmpty == false
        }
        let missingKeys = requiredKeys.filter { !presentKeys.contains($0) }
        let state: CompatibilityRepairAuditState
        if !staleFlags.isEmpty {
            state = .staleFlags
        } else if !missingKeys.isEmpty {
            state = .missingRepairs
        } else {
            state = .ready
        }

        return CompatibilityRepairAuditEntry(
            launchRecordId: record.id,
            logPath: record.logPath,
            startedAt: record.startedAt,
            bottleId: record.bottleId,
            bottleName: record.bottleName,
            exe: record.exe,
            profile: profile.rawValue,
            state: state,
            requiredRepairKeys: requiredKeys,
            presentRepairKeys: presentKeys,
            missingRepairKeys: missingKeys,
            staleRenderingFlags: staleFlags
        )
    }

    private static func profile(for record: WineLaunchRecord) -> ApplicationCompatibilityProfile? {
        if let rawValue = record.environment["MACWIN_COMPAT_PROFILE"]?.lowercased() {
            if rawValue == ApplicationCompatibilityProfile.disabledProfileValue {
                return nil
            }
            switch rawValue {
            case ApplicationCompatibilityProfile.bambuStudioSoftwareOpenGL.rawValue:
                return .bambuStudioSoftwareOpenGL
            case ApplicationCompatibilityProfile.blenderSoftwareOpenGL.rawValue:
                return .blenderSoftwareOpenGL
            case ApplicationCompatibilityProfile.dbeaverSWT.rawValue:
                return .dbeaverSWT
            case ApplicationCompatibilityProfile.browserGecko.rawValue:
                return .browserGecko
            case ApplicationCompatibilityProfile.steamClient.rawValue:
                return .steamClient
            case ApplicationCompatibilityProfile.lenovoAppStore.rawValue:
                return .lenovoAppStore
            case ApplicationCompatibilityProfile.tencentAppStore.rawValue:
                return .tencentAppStore
            case ApplicationCompatibilityProfile.hoYoPlay.rawValue:
                return .hoYoPlay
            case ApplicationCompatibilityProfile.freeCADOpenGL.rawValue:
                return .freeCADOpenGL
            case ApplicationCompatibilityProfile.kiCadEDA.rawValue:
                return .kiCadEDA
            case ApplicationCompatibilityProfile.libreCADQt.rawValue:
                return .libreCADQt
            case ApplicationCompatibilityProfile.openSCADSoftwareOpenGL.rawValue:
                return .openSCADSoftwareOpenGL
            case ApplicationCompatibilityProfile.sweetHome3DOpenGL.rawValue:
                return .sweetHome3DOpenGL
            case ApplicationCompatibilityProfile.jabRefJavaFXD3D.rawValue:
                return .jabRefJavaFXD3D
            case ApplicationCompatibilityProfile.jaspQtWebEngineQrc.rawValue:
                return .jaspQtWebEngineQrc
            case ApplicationCompatibilityProfile.mRemoteNG1782.rawValue:
                return .mRemoteNG1782
            case ApplicationCompatibilityProfile.museScoreStudio.rawValue:
                return .museScoreStudio
            case ApplicationCompatibilityProfile.officeSuite.rawValue:
                return .officeSuite
            case ApplicationCompatibilityProfile.wpsOffice.rawValue:
                return .wpsOffice
            case ApplicationCompatibilityProfile.qtBrowserSoftware.rawValue:
                return .qtBrowserSoftware
            case ApplicationCompatibilityProfile.qtRhiSoftware.rawValue:
                return .qtRhiSoftware
            case ApplicationCompatibilityProfile.qtWidgetsSoftware.rawValue:
                return .qtWidgetsSoftware
            case ApplicationCompatibilityProfile.supermium32Browser.rawValue:
                return .supermium32Browser
            case ApplicationCompatibilityProfile.zoteroGecko32.rawValue:
                return .zoteroGecko32
            case ApplicationCompatibilityProfile.cefSoftwareRenderer.rawValue, "cef-software-gl":
                return .cefSoftwareRenderer
            default:
                break
            }
        }

        return ApplicationCompatibilityProfile.matched(
            launcherId: URL(fileURLWithPath: record.exe.replacingOccurrences(of: "\\", with: "/")).lastPathComponent,
            exePath: record.exe
        )
    }

    private static func requiredRepairKeys(for profile: ApplicationCompatibilityProfile) -> [String] {
        let preferredOrder = [
            "MACWIN_COMPAT_PROFILE",
            "MACWIN_TEXT_RENDERING_REPAIR",
            "MACWIN_FONTCONFIG_REPAIR",
            "MACWIN_FONT_FALLBACK_REPAIR",
            "MACWIN_DISABLE_DWM_COMPOSITION",
            "MACWIN_FORCE_OPAQUE_LAYERED_WINDOWS",
            "MACWIN_APP_MODE_INPUT_REPAIR",
            "MACWIN_BAMBU_STUDIO_RUNTIME_REPAIR",
            "MACWIN_BLENDER_SOFTWARE_OPENGL_REPAIR",
            "MACWIN_FORCE_MOUSE_FOCUS",
            "MACWIN_JASP_QRC_REPAIR",
            "MACWIN_JASP_STARTUP_REPAIR",
            "MACWIN_LIBRECAD_PROFILE_REPAIR",
            "MACWIN_OPENSCAD_SOFTWARE_OPENGL_REPAIR",
            "MACWIN_MUSESCORE_WELCOME_REPAIR",
            "MACWIN_QTWEBENGINE_REPAIR",
            "MACWIN_QT_RHI_SOFTWARE_REPAIR",
            "MACWIN_CHROMIUM_HELPER_ARGS",
            "MACWIN_CHROMIUM_BROWSER_REPAIR",
            "MACWIN_TENCENT_APP_STORE_REPAIR",
            "MACWIN_WEBVIEW_SOFTWARE_RENDERER",
            "MACWIN_DISABLE_WINE_D3D_CONFIG",
            "MACWIN_DOTNET_DESKTOP10_RUNTIME_REPAIR",
            "MACWIN_LAUNCH_CWD",
            "MACWIN_MREMOTENG_REPAIR",
            "MACWIN_WOW64_BROWSER_REPAIR",
            "MACWIN_GECKO_PROFILE_REPAIR",
            "MACWIN_ZOTERO_GECKO32_REPAIR",
            "MACWIN_STEAMWEBHELPER_ARGS",
            "DOTNET_ROOT",
            "DOTNET_ROOT_X64",
            "PATH",
            "QML2_IMPORT_PATH",
            "MOZ_WEBRENDER",
            "MOZ_DISABLE_CONTENT_SANDBOX",
            "QTWEBENGINE_CHROMIUM_FLAGS",
            "QTWEBENGINE_DISABLE_SANDBOX",
            "QTWEBENGINEPROCESS_PATH",
            "QTWEBENGINE_RESOURCES_PATH",
            "QT_QUICK_BACKEND",
            "QT_OPENGL",
            "QT_PLUGIN_PATH",
            "QT_QPA_PLATFORM_PLUGIN_PATH",
            "QT_QUICK_CONTROLS_STYLE",
            "QT_RHI_BACKEND",
            "QSG_RENDER_LOOP",
            "QSG_RHI_BACKEND",
            "FREETYPE_PROPERTIES",
            "GALLIUM_DRIVER",
            "LIBGL_ALWAYS_SOFTWARE",
            "LC_CTYPE",
            "MESA_LOADER_DRIVER_OVERRIDE",
            "MESA_GLSL_VERSION_OVERRIDE",
            "MESA_GL_VERSION_OVERRIDE",
            "WINEDLLOVERRIDES",
            "WINE_D3D_CONFIG"
        ]
        let keys = Set(
            profile.environment.compactMap { key, value in
                value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : key
            }
        )
        .intersection(preferredOrder)
        return preferredOrder.filter { keys.contains($0) }
    }

    private static func staleRenderingFlags(in record: WineLaunchRecord) -> [String] {
        let text = ([record.exe] + record.args + record.commandLine + record.environment.map { "\($0.key)=\($0.value)" })
            .joined(separator: " ")
        var flags = ApplicationCompatibilityProfile.obsoleteTextRenderingFlags(in: text)
        if let overrides = record.environment["WINEDLLOVERRIDES"]?.lowercased(),
           overrides.contains("dwrite") || overrides.contains("usp10") {
            flags.append("builtin-dwrite-or-usp10-override")
        }
        return Array(Set(flags)).sorted()
    }

    private static func findings(
        missingEntries: [CompatibilityRepairAuditEntry],
        staleEntries: [CompatibilityRepairAuditEntry],
        missingRuntimeCoverage: [CompatibilityRuntimeCoverageEntry]
    ) -> [CompatibilityRepairFinding] {
        var result: [CompatibilityRepairFinding] = []
        if !staleEntries.isEmpty {
            result.append(
                CompatibilityRepairFinding(
                    id: "stale-launch-rendering-flags",
                    severity: "high",
                    title: "Launch records still contain obsolete text-rendering flags",
                    detail: "Some recent launches still carried old DirectWrite, remote-font, or Chromium text-raster flags. Quit already-running Windows helper processes and relaunch through the current MacWin Manager build before judging text rendering.",
                    affectedLaunchRecordIds: staleEntries.map(\.launchRecordId).sorted(),
                    affectedLogPaths: staleEntries.map(\.logPath).sorted(),
                    missingRepairKeys: [],
                    staleRenderingFlags: Array(Set(staleEntries.flatMap(\.staleRenderingFlags))).sorted(),
                    recommendedActions: [
                        "Quit the affected Windows app and helper processes.",
                        "Relaunch from MacWin Manager so sanitized arguments and current profile environment are written into the new launch record.",
                        "Compare the new launch record against this audit before changing graphics presets."
                    ]
                )
            )
        }
        if !missingEntries.isEmpty {
            result.append(
                CompatibilityRepairFinding(
                    id: "missing-launch-repair-environment",
                    severity: "medium",
                    title: "Launch records are missing expected repair environment",
                    detail: "Some recognized app launches do not show the expected compatibility repair keys in structured launch history. This may indicate an old app build, a stale launcher manifest, or a launch path outside MacWin Manager.",
                    affectedLaunchRecordIds: missingEntries.map(\.launchRecordId).sorted(),
                    affectedLogPaths: missingEntries.map(\.logPath).sorted(),
                    missingRepairKeys: Array(Set(missingEntries.flatMap(\.missingRepairKeys))).sorted(),
                    staleRenderingFlags: [],
                    recommendedActions: [
                        "Open the bottle once in the current MacWin Manager build to migrate launcher metadata.",
                        "Relaunch the app from its MacWin launcher instead of a manually started Wine command.",
                        "Export a support bundle if the next launch still misses these keys."
                    ]
                )
            )
        }
        if !missingRuntimeCoverage.isEmpty {
            result.append(
                CompatibilityRepairFinding(
                    id: "missing-wps-office-fltlib-engine-coverage",
                    severity: "high",
                    title: "WPS Office runtime coverage is incomplete",
                    detail: "One or more managed engines are missing the fltlib PE DLLs required by the WPS Office compatibility profile. WPS registration or 32-bit helper processes can fail before the document window opens.",
                    affectedLaunchRecordIds: [],
                    affectedLogPaths: [],
                    missingRepairKeys: Array(Set(missingRuntimeCoverage.flatMap(\.missingSourcePaths))).sorted(),
                    staleRenderingFlags: [],
                    recommendedActions: [
                        "Build the missing Wine fltlib x86_64-windows target.",
                        "For a WoW64 engine, also build the i386-windows fltlib target.",
                        "Refresh compatibility diagnostics before launching WPS Office again."
                    ]
                )
            )
        }
        return result
    }
}
