import Foundation
import Testing

@Suite("Software smoke script")
struct SoftwareSmokeScriptTests {
    @Test("DBeaver smoke preserves Latin UI fonts and uses CJK glyph fallback")
    func dbeaverSmokePreservesLatinUIFontFiles() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let scriptURL = repositoryRoot.appendingPathComponent("scripts/run-software-smoke.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        #expect(script.contains("replace_windows_font_alias ARIAL.TTF"))
        #expect(script.contains("replace_windows_font_alias ARIALBD.TTF"))
        #expect(!script.contains("for target in ARIAL.TTF ARIALBD.TTF"))
        #expect(!script.contains("<rejectfont>"))
        #expect(!script.contains(#"<patelt name="family"><string>Arial</string></patelt>"#))
        #expect(script.contains("MACWIN_COMPAT_PROFILE=dbeaver-swt"))
        #expect(script.contains(#"FREETYPE_PROPERTIES="truetype:interpreter-version=40 cff:no-stem-darkening=0""#))
        #expect(script.contains("run_dbeaver_jdbc_workload"))
    }

    @Test("Window metrics repair removes multiline registry continuations")
    func windowMetricsRepairRemovesMultilineRegistryContinuations() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let scriptURL = repositoryRoot.appendingPathComponent("scripts/run-software-smoke.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        #expect(script.contains("skip_replaced_value_continuation = False"))
        #expect(script.contains(#"skip_replaced_value_continuation = line.endswith("\\")"#))
    }

    @Test("Window metrics repair matches sections by bracket boundary, not first space")
    func windowMetricsRepairMatchesSectionsByBracketBoundary() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let scriptURL = repositoryRoot.appendingPathComponent("scripts/run-software-smoke.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        // The WindowMetrics section path contains a space ("Control Panel").
        // Matching it by splitting the header on the first space captures only
        // "[Control" and never matches, silently skipping the repair and then
        // appending a duplicate section at the end of user.reg. The header must
        // instead be extracted from the bracket boundary.
        #expect(script.contains(#"bracket_end = line.find("]")"#))
        #expect(script.contains(#"current = line[:bracket_end + 1]"#))
        // The fragile first-space section split must be gone everywhere the
        // script walks registry headers.
        #expect(!script.contains(#"line.split(" ", 1)[0]"#))
    }

    @Test("Timezone repair matches bracketed sections and drops multiline hex continuations")
    func timezoneRepairMatchesBracketedSectionsAndDropsMultilineHex() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let scriptURL = repositoryRoot.appendingPathComponent("scripts/run-software-smoke.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        // The timezone section paths contain spaces ("Windows NT", "Time
        // Zones"). The header must be matched by bracket boundary, not first
        // space, or the repair is skipped and a duplicate section appended.
        let tzFunction = try #require(script.range(of: "repair_windows_timezone_registry()"))
        let tzRegion = script[tzFunction.lowerBound...]
        #expect(tzRegion.contains(#"bracket_end = line.find("]")"#))
        #expect(tzRegion.contains(#"header = line[:bracket_end + 1]"#))
        #expect(tzRegion.contains(#"header if header in sections"#))
        // TZI is a multiline hex value; replaced values must drop their
        // trailing-backslash continuation lines just like the metrics repair.
        #expect(tzRegion.contains("skip_replaced_value_continuation = False"))
        #expect(tzRegion.contains(#"skip_replaced_value_continuation = line.endswith("\\")"#))
    }

    @Test("All registry section walkers match by bracket boundary, never first space")
    func registrySectionWalkersNeverSplitOnFirstSpace() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let scriptURL = repositoryRoot.appendingPathComponent("scripts/run-software-smoke.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        // Wine registry key paths contain spaces (Control Panel, Windows NT,
        // Time Zones, MuseScore Studio, Mac Driver). Any section walker that
        // strips the trailing timestamp by splitting on the first space
        // captures only the first token and never matches, silently no-op'ing
        // the repair and appending a duplicate section. This regression guard
        // forbids that pattern anywhere in the script.
        #expect(!script.contains(#"line.split(" ", 1)[0]"#))

        // Every walker that lowers a bracketed header to a section name must do
        // so by bracket boundary. The known registry walkers all use one of:
        //   index("]") / find("]") then slice [1:idx] or [:idx+1]
        let walkerAnchors: [String] = [
            #"stripped[1:stripped.index("]")]"#,
            "current = line[:bracket_end + 1]",
            "header = line[:bracket_end + 1]"
        ]
        #expect(walkerAnchors.contains { script.contains($0) })
    }

    @Test("ONLYOFFICE smoke uses a complete install and repairs renderer fonts before PDF export")
    func onlyOfficeSmokeRepairsRendererFontsBeforePDFExport() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let scriptURL = repositoryRoot.appendingPathComponent("scripts/run-software-smoke.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        #expect(script.contains(
            "onlyoffice-suite|$DOWNLOADS/OnlyOfficeDesktopEditors-x64.exe|EXE|"
        ))
        #expect(!script.contains(
            "onlyoffice-suite|$DOWNLOADS/OnlyOfficeDesktopEditors-x64.exe|EXE_UNTIL_FILE|"
        ))
        #expect(script.contains("repair_onlyoffice_renderer_fonts()"))
        #expect(script.contains("MACWIN_ONLYOFFICE_RENDERER_FONTS=PASS"))

        let repairCall = try #require(script.range(of: "renderer-font-repair 30 timeout"))
        let pdfCall = try #require(script.range(of: "pdf-export-capability 120 timeout"))
        #expect(repairCall.lowerBound < pdfCall.lowerBound)
        #expect(script.contains(
            "\"$input_windows\" \"$output_windows\" \"$font_dir_windows\""
        ))
        #expect(!script.contains("onlyoffice-docx-pdf-params"))
    }

    @Test("Blender smoke deploys Mesa and verifies a real Eevee window")
    func blenderSmokeVerifiesMesaEeveeWindow() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let scriptURL = repositoryRoot.appendingPathComponent("scripts/run-software-smoke.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        #expect(script.contains("configure_blender_software_opengl()"))
        #expect(script.contains("run_blender_eevee_windowed_workload()"))
        #expect(script.contains("MACWIN_BLENDER_SOFTWARE_OPENGL_REPAIR=1"))
        #expect(script.contains("MESA_LOADER_DRIVER_OVERRIDE=llvmpipe"))
        #expect(script.contains("WINEDLLOVERRIDES='opengl32=n,b;winemenubuilder.exe=d'"))
        #expect(!script.contains("'WINEDLLOVERRIDES=opengl32=n,b;winemenubuilder.exe=d'"))
        #expect(script.contains("bpy.app.timers.register(macwin_render, first_interval=3.0)"))
        #expect(script.contains("s.render.engine='BLENDER_EEVEE'"))
        #expect(script.contains("C:/users/$USER/Temp/macwin-blender-eevee-windowed.png"))
        #expect(script.contains("MACWIN_BLENDER_EEVEE_WINDOWED=PASS"))
        #expect(script.contains("MACWIN_BLENDER_WINDOW_CLASSIFICATION="))
        #expect(!script.contains("eevee-headless-capability"))
    }

    @Test("QGroundControl smoke verifies a clean Qt Quick front buffer")
    func qGroundControlSmokeVerifiesQtQuickFrontBuffer() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let scriptURL = repositoryRoot.appendingPathComponent("scripts/run-software-smoke.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        #expect(script.contains("qgroundcontrol-drone|sweethome3d-design"))
        #expect(script.contains("locked_window_token=\"QGroundControl\""))
        #expect(script.contains("visualProbe.domain=qgroundcontrol-qtquick-front-buffer"))
        #expect(script.contains("MACWIN_COMPAT_PROFILE=qt-rhi-software"))
        #expect(script.contains("QSG_RHI_BACKEND=opengl"))
        #expect(script.contains("QT_OPENGL=software"))
        #expect(script.contains("QGroundControl main window and structured Qt Quick front buffer verified"))
        #expect(script.contains("prepare_qgroundcontrol_first_run_probe"))
        #expect(script.contains("probe_qgroundcontrol_first_run_interaction"))
        #expect(script.contains("firstRunPromptIdsShown=absent"))
        #expect(script.contains("interactionProbe.reason=first-run-state-not-reset"))
        #expect(script.contains("clickp:56:27 wait:1200"))
        #expect(script.contains("clickp:56:37 wait:3000"))
        #expect(script.contains("interactionProbe.settingsConfirmed="))
        #expect(script.contains("interactionProbe.mapTileCount="))
        #expect(script.contains("interactionProbe.reason=map-tiles-not-cached"))
        #expect(script.contains("interactionProbe.status=verified"))
        #expect(script.contains("interactionProbe.steps=measurement-units,vehicle-information,map-tiles"))
        #expect(script.contains("accepted both first-run dialogs, and downloaded fresh map tiles"))
    }

    @Test("WIC codec registry defines every BMP decoder pixel format")
    func wicRegistryDefinesEveryBmpDecoderPixelFormat() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let regURL = repositoryRoot.appendingPathComponent("scripts/wic-codecs-minimal.reg")
        let reg = try String(contentsOf: regURL, encoding: .utf8)

        // Each BMP decoder Formats subkey is a section header whose path ends
        // in "\Formats\{GUID}". Each registered pixel format appears under a
        // Pixel Formats "\Instance\{GUID}" subkey. Extract the trailing GUID
        // from the last {...} group on every section header.
        func trailingGuids(inSectionHeaders containing: String, lines: [String]) -> Set<String> {
            var guids = Set<String>()
            for line in lines where line.hasPrefix("[") && line.contains(containing) {
                guard let openBrace = line.lastIndex(of: "{"),
                      let closeBrace = line.lastIndex(of: "}") else { continue }
                guids.insert(String(line[openBrace...closeBrace]).uppercased())
            }
            return guids
        }

        let lines = reg.split(separator: "\n").map(String.init)
        let bmpFormatGuids = trailingGuids(inSectionHeaders: "6B462062", lines: lines)
            .filter { $0.contains("6FDDC324") } // Formats subkeys point at pixel-format GUIDs
        let instanceGuids = trailingGuids(inSectionHeaders: "\\Instance\\", lines: lines)

        // Every pixel format the BMP decoder advertises in its Formats list
        // must be registered as a WIC pixel format instance, or Wine's
        // CreateComponentInfo fails for that GUID and indexed/16/24-bit BMP
        // decoding breaks.
        let unregistered = bmpFormatGuids.subtracting(instanceGuids)
        #expect(unregistered.isEmpty, "BMP decoder references unregistered pixel formats: \(unregistered.sorted())")

        // The BMP decoder must advertise the common indexed and low-bpp formats.
        let requiredSuffixes = ["901", "902", "903", "904", "909", "90A", "90C"]
        for suffix in requiredSuffixes {
            let guid = "{6FDDC324-4E03-4BFE-B185-3D77768DC\(suffix.uppercased())}"
            #expect(bmpFormatGuids.contains(guid), "BMP decoder missing expected format \(guid)")
            #expect(instanceGuids.contains(guid), "pixel format \(guid) not registered")
        }
    }

    @Test("CJK font aliases register YaHei against its own file family, not MingLiU")
    func cjkFontAliasesRegisterYaHeiAgainstOwnFileFamily() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let scriptURL = repositoryRoot.appendingPathComponent("scripts/run-software-smoke.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        // Microsoft YaHei (Simplified Chinese) and Microsoft YaHei UI must
        // resolve to the YaHei file family (MSYH*), matching BottleService and
        // real Windows. Earlier the smoke script registered them against the
        // Traditional-Chinese MingLiU container, which diverged from production
        // and from the YaHei UI line immediately below it.
        let yaHeiRegular = try #require(script.range(of: #"register_windows_font_file "Microsoft YaHei \(TrueType\)" MSYH"#, options: .regularExpression))
        let yaHeiUI = try #require(script.range(of: #"register_windows_font_file "Microsoft YaHei UI \(TrueType\)" MSYH"#, options: .regularExpression))
        let yaHeiBold = try #require(script.range(of: #"register_windows_font_file "Microsoft YaHei Bold \(TrueType\)" MSYHBD"#, options: .regularExpression))

        // The stale MingLiU mappings for YaHei must be gone.
        #expect(!script.contains(#"register_windows_font_file "Microsoft YaHei (TrueType)" MINGLIU"#))
        #expect(!script.contains(#"register_windows_font_file "Microsoft YaHei Bold (TrueType)" MINGLIUB"#))

        _ = yaHeiRegular; _ = yaHeiUI; _ = yaHeiBold

        // Every CJK file referenced by a register_windows_font_file call must
        // also appear in the CJK copy list, or the file would not exist on disk.
        let copyList = try #require(script.range(of: #"for target in [A-Za-z0-9. ]+; do"#, options: .regularExpression))
        let copyTargets = Set(script[copyList]
            .split(whereSeparator: { $0 == " " || $0 == ";" })
            .map { $0.uppercased() }
            .filter { $0.hasSuffix(".TTC") || $0.hasSuffix(".TTF") || $0.hasSuffix(".ttf") })
        let cjkPrefixes = ["MSYH", "MSJH", "MSMINCHO", "MSGOTHIC", "SIMSUN", "MINGLIU",
                           "GULIM", "BATANG", "MALGUN", "YUGOTH", "HKSCS"]
        for line in script.split(separator: "\n") where line.contains("register_windows_font_file") {
            guard let fileToken = line.split(separator: " ").last else { continue }
            let file = String(fileToken).uppercased()
            guard cjkPrefixes.contains(where: { file.hasPrefix($0) }) else { continue }
            #expect(copyTargets.contains(file), "CJK font \(file) registered but not in copy list")
        }
    }
}
