import Foundation
import Testing

@Suite("Software smoke script")
struct SoftwareSmokeScriptTests {
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
}
