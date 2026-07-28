import Foundation
import Testing
@testable import MacWinCore

@Suite("Software sample catalog service")
struct SoftwareSampleCatalogServiceTests {
    @Test("Default sample catalog covers real launchers without mutating signed recipes")
    func defaultCatalogCoversRealLaunchers() throws {
        let report = SoftwareSampleCatalogService.report(
            rootPath: "/tmp/MacWin",
            recipes: [
                recipe(id: "hoyoplay-cn", name: "HoYoPlay"),
                recipe(id: "steam", name: "Steam"),
                recipe(id: "7zip", name: "7-Zip"),
                recipe(id: "lenovo-app-store", name: "联想应用商店"),
                recipe(id: "portableapps-platform", name: "PortableApps.com Platform")
            ],
            generatedAt: Date(timeIntervalSince1970: 100)
        )

        #expect(report.sampleCount >= 29)
        #expect(report.localInstallerCount >= 25)
        #expect(report.catalogBackedCount == 5)
        #expect(report.warningCount > 0)

        let itch = try #require(report.samples.first { $0.id == "itch" })
        #expect(itch.installSource == .localInstaller)
        #expect(itch.catalogBacked == false)
        #expect(itch.recommendedProbeIds.contains("70_text_rendering_probe"))
        #expect(itch.environment["MACWIN_WEBVIEW_SOFTWARE_RENDERER"] == "1")
        #expect(itch.environment["ROSETTA_X87_PATH"] == "")

        let lenovo = try #require(report.samples.first { $0.id == "lenovo-app-store" })
        #expect(lenovo.installSource == .signedRecipe)
        #expect(lenovo.catalogRecipeId == "lenovo-app-store")
        #expect(lenovo.catalogBacked)
        #expect(lenovo.expectedIssueIds.contains("lenovo-black-screen"))
        #expect(lenovo.launcherCandidates.contains { $0.localizedCaseInsensitiveContains("LeASLane.exe") })

        let tencent = try #require(report.samples.first { $0.id == "tencent-app-store" })
        #expect(tencent.recommendedProbeIds.contains("10_tls_winhttp_probe_32"))
        #expect(tencent.installerFileNames.contains("pcyyb.exe"))
        #expect(tencent.installerFileNames.contains("Tencent_PCManager_Setup.exe"))
        #expect(tencent.installerFileNames.contains("应用宝安装器.exe"))
        #expect(tencent.installerFileNames.contains("QQPhoneManager.exe"))
        #expect(tencent.launcherCandidates.contains("C:\\Program Files\\Tencent\\Androws\\Application\\5.10.6400.6084\\AndrowsStore.exe"))
        #expect(!tencent.installerFileNames.contains("Store-ind-10002.exe"))
        #expect(tencent.warnings.contains { $0.localizedCaseInsensitiveContains("local installers") })

        let portableApps = try #require(report.samples.first { $0.id == "portableapps-platform" })
        #expect(portableApps.installSource == .signedRecipe)
        #expect(portableApps.catalogRecipeId == "portableapps-platform")
        #expect(portableApps.catalogBacked)
        #expect(portableApps.installerFileNames.contains("PortableApps.com_Platform_Setup.paf.exe"))
        #expect(portableApps.recommendedProbeIds.contains("10_tls_winhttp_probe"))
        #expect(portableApps.compatibilityProfileId == "portableapps-platform")
        #expect(!portableApps.expectedIssueIds.contains("portableapps-seh"))
        #expect(portableApps.expectedIssueIds.contains("wow64-theme"))
        #expect(portableApps.environment["MACWIN_PORTABLEAPPS_PLATFORM_REPAIR"] == "1")
        #expect(portableApps.environment["WINEDLLOVERRIDES"] == "winemenubuilder.exe=d;uxtheme=d")
        #expect(portableApps.warnings.contains { $0.localizedCaseInsensitiveContains("PortableAppsPlatform.exe") && $0.localizedCaseInsensitiveContains("verifies") })
        #expect(!portableApps.warnings.contains { $0.localizedCaseInsensitiveContains("exits 41") })

        let npackd = try #require(report.samples.first { $0.id == "npackd" })
        #expect(npackd.installerFileNames.contains("Npackd64-1.26.9.zip"))
        #expect(npackd.expectedIssueIds.contains("archive-installer"))
        #expect(npackd.launcherCandidates.contains("C:\\macwin-portable\\npackd\\npackdg.exe"))
        #expect(npackd.compatibilityProfileId == "qt-widgets-software")
        #expect(npackd.environment["ROSETTA_X87_PATH"] == "")

        let chrome = try #require(report.samples.first { $0.id == "chrome-enterprise" })
        #expect(chrome.category == "Browser")
        #expect(chrome.installerFileNames.contains("GoogleChromeStandaloneEnterprise64.msi"))
        #expect(chrome.expectedIssueIds.contains("chromium-gpu"))

        let privacyBrowsers = try #require(report.samples.first { $0.id == "privacy-browser-pack" })
        #expect(privacyBrowsers.installerFileNames.contains("Vivaldi.7.9.3970.47.x64.exe"))
        #expect(privacyBrowsers.installerFileNames.contains("librewolf-152.0.1-2-windows-x86_64-setup.exe"))
        #expect(privacyBrowsers.installerFileNames.contains("floorp-windows-x86_64.installer.exe"))
        #expect(privacyBrowsers.expectedIssueIds.contains("gecko-rendering"))

        let libreOffice = try #require(report.samples.first { $0.id == "libreoffice-suite" })
        #expect(libreOffice.category == "Office Suite")
        #expect(libreOffice.installerFileNames.contains("LibreOffice_26.2.4_Win_x86-64.msi"))
        #expect(libreOffice.expectedIssueIds.contains("printing"))

        let publishingPack = try #require(report.samples.first { $0.id == "office-publishing-pack" })
        #expect(publishingPack.installerFileNames.contains("Scribus-1.4.8-windows-x64.exe"))
        #expect(publishingPack.installerFileNames.contains("Thunderbird-latest-win64-zhCN.exe"))
        #expect(publishingPack.installerFileNames.contains("install-tl-windows.exe"))
        #expect(publishingPack.expectedIssueIds.contains("certificate-dialog"))

        let productivityPack = try #require(report.samples.first { $0.id == "productivity-document-pack" })
        #expect(productivityPack.installerFileNames.contains("draw.io-30.2.4.msi"))
        #expect(productivityPack.installerFileNames.contains("Joplin-Setup-3.6.15.exe"))
        #expect(productivityPack.installerFileNames.contains("Obsidian-1.12.7.exe"))
        #expect(productivityPack.installerFileNames.contains("calibre-64bit-9.9.0.msi"))
        #expect(productivityPack.installerFileNames.contains("SumatraPDF-3.6.1-64-install.exe"))
        #expect(productivityPack.installerFileNames.contains("Zotero-Windows-latest.exe"))
        #expect(productivityPack.expectedIssueIds.contains("java-runtime"))

        let developerToolchain = try #require(report.samples.first { $0.id == "developer-toolchain" })
        #expect(developerToolchain.installerFileNames.contains("Git-2.54.0-64-bit.exe"))
        #expect(developerToolchain.installerFileNames.contains("VSCodeUserSetup-x64-1.125.1.exe"))
        #expect(developerToolchain.installerFileNames.contains("VSCode-win32-x64-1.125.1.zip"))
        #expect(developerToolchain.installerFileNames.contains("Postman-win64-latest.exe"))
        #expect(developerToolchain.installerFileNames.contains("npp.8.9.6.4.Installer.x64.exe"))
        #expect(developerToolchain.installerFileNames.contains("WinSCP-6.5.6-Setup.exe"))
        #expect(developerToolchain.installerFileNames.contains("WinSCP-6.6.2.RC-Portable-x64-Experimental.zip"))
        #expect(developerToolchain.installerFileNames.contains("KeePass-2.59-Setup.exe"))
        #expect(developerToolchain.launcherCandidates.contains("C:\\macwin-portable\\winscp-x64-portable\\WinSCP.exe"))
        #expect(developerToolchain.expectedIssueIds.contains("dotnet-winforms"))

        let databasePack = try #require(report.samples.first { $0.id == "database-developer-pack" })
        #expect(databasePack.installerFileNames.contains("dbeaver-ce-latest-x86_64-setup.exe"))
        #expect(databasePack.installerFileNames.contains("DB.Browser.for.SQLite-v3.13.1-win64.msi"))
        #expect(databasePack.installerFileNames.contains("mRemoteNG-20260222-v1.78.2-NB-3405-x64.rar"))
        #expect(databasePack.installerFileNames.contains("dotnet-runtime-10.0.9-win-x64.zip"))
        #expect(databasePack.installerFileNames.contains("windowsdesktop-runtime-10.0.9-win-x64.zip"))
        #expect(databasePack.launcherCandidates.contains("C:\\macwin-portable\\mremoteng-1782-x64\\mRemoteNG.exe"))
        #expect(databasePack.expectedIssueIds.contains("dotnet-winforms"))
        #expect(databasePack.expectedIssueIds.contains("dotnet-runtime"))
        #expect(databasePack.warnings.contains { $0.contains("mRemoteNG") && $0.contains("Wine-Mono") })
        #expect(databasePack.warnings.contains { $0.contains("mRemoteNG 1.78.2") && $0.contains("DOTNET_ROOT_X64") })

        let freeCAD = try #require(report.samples.first { $0.id == "freecad-workbench" })
        #expect(freeCAD.category == "Industrial CAD")
        #expect(freeCAD.installerFileNames.contains("FreeCAD_1.1.1-Windows-x86_64-py311-installer.exe"))
        #expect(freeCAD.recommendedProbeIds.contains("60_game_shader_probe"))

        let openPLC = try #require(report.samples.first { $0.id == "openplc-editor" })
        #expect(openPLC.category == "Industrial Automation")
        #expect(openPLC.installerFileNames.contains("OpenPLC.Editor_4.2.7.exe"))
        #expect(openPLC.launcherCandidates.contains("C:\\macwin-portable\\openplc-editor\\OpenPLC Editor.exe"))
        #expect(openPLC.compatibilityProfileId == "openplc-electron")
        #expect(openPLC.environment["TZ"] == "Asia/Shanghai")
        #expect(openPLC.expectedIssueIds.contains("chromium-compositor"))
        #expect(openPLC.expectedIssueIds.contains("plc-compiler-toolchain"))

        let energyPlus = try #require(report.samples.first { $0.id == "energyplus-building" })
        #expect(energyPlus.category == "Industrial Simulation")
        #expect(energyPlus.installerFileNames.contains("EnergyPlus-26.1.0-6f2e40d102-Windows-x86_64.exe"))
        #expect(energyPlus.launcherCandidates.contains("C:\\EnergyPlusV26-1-0\\energyplus.exe"))
        #expect(energyPlus.expectedIssueIds.contains("legacy-activex"))
        #expect(energyPlus.warnings.contains { $0.contains("annual simulation is validated") })

        let electricalPack = try #require(report.samples.first { $0.id == "electrical-parametric-cad-pack" })
        #expect(electricalPack.installerFileNames.contains("SolveSpace-3.2-x64.exe"))
        #expect(electricalPack.installerFileNames.contains("Installer_QElectroTech-0.100.0_x86_64-win64.exe"))
        #expect(electricalPack.expectedIssueIds.contains("single-exe-launch"))

        let creativeExtended = try #require(report.samples.first { $0.id == "creative-extended-pack" })
        #expect(creativeExtended.installerFileNames.contains("krita-x64-5.2.9-setup.exe"))
        #expect(creativeExtended.installerFileNames.contains("MoonlightSetup-6.1.0.exe"))
        #expect(creativeExtended.expectedIssueIds.contains("controller-input"))

        let creativeWorkstation = try #require(report.samples.first { $0.id == "creative-workstation-pack" })
        #expect(creativeWorkstation.installerFileNames.contains("GIMP-2.10.38-win64-setup.exe"))
        #expect(creativeWorkstation.installerFileNames.contains("gimp-2.10.38-setup-1.exe"))
        #expect(creativeWorkstation.installerFileNames.contains("audacity-win-3.7.8-64bit.exe"))

        let makerPack = try #require(report.samples.first { $0.id == "maker-streaming-pack" })
        #expect(makerPack.installerFileNames.contains("PrusaSlicer-2.9.5-setup.exe"))
        #expect(makerPack.installerFileNames.contains("UltiMaker-Cura-5.13.0-win64-X64.exe"))
        #expect(makerPack.installerFileNames.contains("OrcaSlicer_Windows_Installer_V2.4.0.exe"))
        #expect(makerPack.installerFileNames.contains("LaserGRBL-install-7.14.1.exe"))
        #expect(makerPack.installerFileNames.contains("OBS-Studio-32.1.2-Windows-x64-Installer.exe"))
        #expect(makerPack.expectedIssueIds.contains("media-device"))
        #expect(makerPack.expectedIssueIds.contains("serial-port"))

        let scientificPack = try #require(report.samples.first { $0.id == "scientific-industrial-pack" })
        #expect(scientificPack.installerFileNames.contains("QGIS-OSGeo4W-3.44.11-1.msi"))
        #expect(scientificPack.installerFileNames.contains("Octave-11.3.0-w64-installer.exe"))
        #expect(scientificPack.installerFileNames.contains("OpenDSSInstaller_1100_1.exe"))
        #expect(scientificPack.installerFileNames.contains("stellarium-26.1-qt6-win64.exe"))
        #expect(scientificPack.installerFileNames.contains("JASP-0.97.1-Windows-Community.msi"))
        #expect(scientificPack.installerFileNames.contains("RStudio-2025.09.0-387.exe"))
        #expect(scientificPack.installerFileNames.contains("Julia-1.12.2-win64.exe"))
        #expect(scientificPack.launcherCandidates.contains("C:\\macwin-portable\\opendss-svn-x64\\OpenDSScmd.exe"))
        #expect(scientificPack.expectedIssueIds.contains("large-installer"))
        #expect(scientificPack.expectedIssueIds.contains("numerical-output"))
        #expect(scientificPack.warnings.contains { $0.contains("voltage CSV values") })

        let engineeringPack = try #require(report.samples.first { $0.id == "engineering-workstation-pack" })
        #expect(engineeringPack.installerFileNames.contains("librepcb-installer-2.1.1-windows-x86_64.exe"))
        #expect(engineeringPack.installerFileNames.contains("GeoGebraClassic5-Windows-Installer.exe"))
        #expect(engineeringPack.launcherCandidates.contains("C:\\Program Files (x86)\\GeoGebra 5.4\\GeoGebra.exe"))
        #expect(engineeringPack.warnings.contains { $0.contains("Classic 5") })

        let meshPack = try #require(report.samples.first { $0.id == "mesh-inspection-pack" })
        #expect(meshPack.installerFileNames.contains("MeshLab2025.07-windows_x86_64.exe"))
        #expect(meshPack.recommendedProbeIds.contains("60_game_shader_probe"))

        let utilityPack = try #require(report.samples.first { $0.id == "utility-network-pack" })
        #expect(utilityPack.installerFileNames.contains("7z2601-x64.exe"))
        #expect(utilityPack.installerFileNames.contains("qbittorrent_5.2.2_x64_setup.exe"))
        #expect(utilityPack.installerFileNames.contains("Everything-1.4.1.1028.x64-Setup.exe"))
        #expect(utilityPack.installerFileNames.contains("SumatraPDF-3.6.1-64-install.exe"))
        #expect(utilityPack.warnings.contains { $0.contains("offline Ethernet/IPv4/UDP") })

        let powerToys = try #require(report.samples.first { $0.id == "windows-utility-stress-pack" })
        #expect(powerToys.installerFileNames.contains("PowerToysUserSetup-0.100.0-x64.exe"))
        #expect(powerToys.expectedIssueIds.contains("windows-version-api"))
    }

    @Test("Exports CSV and runbook for adaptation handoff")
    func exportsCSVAndRunbook() {
        let report = SoftwareSampleCatalogService.report(
            rootPath: "/tmp/MacWin",
            samples: [
                SoftwareSampleProfile(
                    id: "sample",
                    name: "Sample App",
                    publisher: "Example",
                    category: "Utilities",
                    purpose: "Exercise text and input.",
                    installSource: .localInstaller,
                    installerFileNames: ["SampleSetup.exe"],
                    launcherCandidates: ["C:\\Program Files\\Sample\\Sample.exe"],
                    expectedIssueIds: ["text"],
                    recommendedProbeIds: ["70_text_rendering_probe"],
                    environment: ["MACWIN_TEXT_RENDERING_REPAIR": "1"],
                    warnings: ["Use local installers only."]
                )
            ],
            recipes: [],
            generatedAt: Date(timeIntervalSince1970: 100)
        )

        let csv = SoftwareSampleCatalogService.csv(report: report)
        #expect(csv.contains("sample_id,name,publisher,category,purpose"))
        #expect(csv.contains("sample,Sample App,Example,Utilities"))
        #expect(csv.contains("MACWIN_TEXT_RENDERING_REPAIR=1"))

        let runbook = SoftwareSampleCatalogService.runbookMarkdown(report: report)
        #expect(runbook.contains("# MacWin Software Sample Catalog"))
        #expect(runbook.contains("## Sample App"))
        #expect(runbook.contains("`70_text_rendering_probe`"))
        #expect(runbook.contains("Use local installers only."))
    }

    @Test("Preparation report matches cached local installers and missing signed recipes")
    func preparationReportMatchesCachedLocalInstallersAndMissingSignedRecipes() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinSamplePreparationTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let downloads = root.appendingPathComponent("Downloads", isDirectory: true)
        try FileManager.default.createDirectory(at: downloads, withIntermediateDirectories: true)
        let itchInstaller = downloads.appendingPathComponent("itch-setup-windows-amd64.exe")
        try Data("installer".utf8).write(to: itchInstaller)

        let catalog = SoftwareSampleCatalogService.report(
            rootPath: root.path,
            samples: [
                SoftwareSampleProfile(
                    id: "itch",
                    name: "itch.io",
                    publisher: "itch",
                    category: "Game Store",
                    purpose: "Electron coverage.",
                    installSource: .localInstaller,
                    installerFileNames: ["itch-setup.exe"],
                    recommendedProbeIds: ["70_text_rendering_probe"],
                    warnings: ["Use local installers only."]
                ),
                SoftwareSampleProfile(
                    id: "missing-game",
                    name: "Missing Game",
                    publisher: "Example",
                    category: "Game",
                    purpose: "Signed recipe coverage.",
                    installSource: .signedRecipe,
                    catalogRecipeId: "missing-game"
                ),
                SoftwareSampleProfile(
                    id: "manual-tool",
                    name: "Manual Tool",
                    publisher: "Example",
                    category: "Utilities",
                    purpose: "Already installed coverage.",
                    installSource: .alreadyInstalled
                )
            ],
            recipes: [],
            generatedAt: Date(timeIntervalSince1970: 200)
        )

        let preparation = SoftwareSampleCatalogService.preparationReport(
            catalog: catalog,
            downloadsDirectory: downloads,
            generatedAt: Date(timeIntervalSince1970: 201)
        )

        #expect(preparation.sampleCount == 3)
        #expect(preparation.readyCount == 1)
        #expect(preparation.missingRecipeCount == 1)
        #expect(preparation.manualCount == 1)
        #expect(preparation.cachedInstallerCount == 1)
        let itch = try #require(preparation.entries.first { $0.sampleId == "itch" })
        #expect(itch.status == .ready)
        #expect(itch.cachedInstallerPaths.count == 1)
        #expect(itch.cachedInstallerPaths.first?.hasSuffix("/Downloads/itch-setup-windows-amd64.exe") == true)
        #expect(itch.requiredAction == "Use the cached local installer from Downloads.")

        let missing = try #require(preparation.entries.first { $0.sampleId == "missing-game" })
        #expect(missing.status == .missingRecipe)
        #expect(missing.requiredAction.contains("signed recipe"))

        let csv = SoftwareSampleCatalogService.preparationCSV(report: preparation)
        #expect(csv.contains("sample_id,name,publisher,category,install_source,catalog_recipe_id,catalog_backed,status,compatibility_profile_id"))
        #expect(csv.contains("itch,itch.io,itch,Game Store,localInstaller,,false,ready"))
        #expect(csv.contains("itch-setup-windows-amd64.exe"))

        let markdown = SoftwareSampleCatalogService.preparationMarkdown(report: preparation)
        #expect(markdown.contains("# MacWin Software Sample Preparation"))
        #expect(markdown.contains("- Ready: 1"))
        #expect(markdown.contains("### itch.io"))
        #expect(markdown.contains("- Category: Game Store"))
        #expect(markdown.contains("Cached installers:"))
        #expect(markdown.contains("### Missing Game"))
        #expect(markdown.contains("Status: `missingRecipe`"))

        let script = SoftwareSampleCatalogService.preparationShellScript(report: preparation)
        #expect(script.contains("#!/usr/bin/env bash"))
        #expect(script.contains("MacWin Software Sample Preparation"))
        #expect(script.contains("[READY] itch.io"))
        #expect(script.contains("[MISSING_RECIPE] Missing Game"))
        #expect(script.contains("itch-setup.exe"))
        #expect(script.contains("itch-setup-windows-amd64.exe"))
        #expect(script.contains("exit 1"))
    }

    @Test("Preparation snapshot exports manifest report runbook and handoff files")
    func preparationSnapshotExportsManifestReportRunbookAndHandoffFiles() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinSamplePreparationSnapshotTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let downloads = root.appendingPathComponent("Downloads", isDirectory: true)
        try FileManager.default.createDirectory(at: downloads, withIntermediateDirectories: true)
        try Data("installer".utf8).write(to: downloads.appendingPathComponent("SampleSetup-1.0.exe"))

        let service = SoftwareSampleCatalogService(
            paths: MacWinPaths(root: root),
            samples: [
                SoftwareSampleProfile(
                    id: "sample",
                    name: "Sample App",
                    publisher: "Example",
                    category: "Utilities",
                    purpose: "Exercise ordinary Win32 UI.",
                    installSource: .localInstaller,
                    installerFileNames: ["SampleSetup.exe"],
                    recommendedProbeIds: ["70_text_rendering_probe"]
                ),
                SoftwareSampleProfile(
                    id: "missing-local",
                    name: "Missing Local",
                    publisher: "Example",
                    category: "Utilities",
                    purpose: "Exercise missing installer handoff.",
                    installSource: .localInstaller,
                    installerFileNames: ["MissingSetup.exe"]
                ),
                SoftwareSampleProfile(
                    id: "manual",
                    name: "Manual App",
                    publisher: "Example",
                    category: "Utilities",
                    purpose: "Exercise manual state.",
                    installSource: .alreadyInstalled
                )
            ]
        )
        let catalog = service.report(recipes: [], generatedAt: Date(timeIntervalSince1970: 400))
        let snapshot = try service.exportPreparationSnapshot(
            catalog: catalog,
            generatedAt: Date(timeIntervalSince1970: 401)
        )

        #expect(snapshot.directoryURL.lastPathComponent == "software-sample-preparation-19700101T000641Z")
        #expect(FileManager.default.fileExists(atPath: snapshot.manifestURL.path))
        #expect(FileManager.default.fileExists(atPath: snapshot.reportURL.path))
        #expect(FileManager.default.fileExists(atPath: snapshot.csvURL.path))
        #expect(FileManager.default.fileExists(atPath: snapshot.markdownURL.path))
        #expect(FileManager.default.fileExists(atPath: snapshot.runbookURL.path))

        let manifest = try JSONStore().load(SoftwareSamplePreparationSnapshotManifest.self, from: snapshot.manifestURL)
        #expect(manifest.sampleCount == 3)
        #expect(manifest.readyCount == 1)
        #expect(manifest.missingInstallerCount == 1)
        #expect(manifest.manualCount == 1)
        #expect(manifest.readySampleIds == ["sample"])
        #expect(manifest.blockedSampleIds == ["missing-local"])
        #expect(manifest.manualSampleIds == ["manual"])
        #expect(manifest.reportPath == snapshot.reportURL.path)

        let report = try JSONStore().load(SoftwareSamplePreparationReport.self, from: snapshot.reportURL)
        #expect(report.cachedInstallerCount == 1)
        #expect(report.entries.contains { $0.sampleId == "sample" && $0.status == .ready })

        let csv = try String(contentsOf: snapshot.csvURL, encoding: .utf8)
        #expect(csv.contains("sample,Sample App,Example,Utilities,localInstaller,,false,ready"))
        #expect(csv.contains("missing-local,Missing Local,Example,Utilities,localInstaller,,false,missingInstaller"))

        let markdown = try String(contentsOf: snapshot.markdownURL, encoding: .utf8)
        #expect(markdown.contains("# MacWin Software Sample Preparation"))
        #expect(markdown.contains("### Missing Local"))

        let runbook = try String(contentsOf: snapshot.runbookURL, encoding: .utf8)
        #expect(runbook.contains("[READY] Sample App"))
        #expect(runbook.contains("[MISSING_INSTALLER] Missing Local"))
        let attributes = try FileManager.default.attributesOfItem(atPath: snapshot.runbookURL.path)
        #expect((attributes[.posixPermissions] as? NSNumber)?.intValue == 0o755)
    }

    @Test("Smoke coverage report prioritizes ready samples missing from matrix")
    func smokeCoverageReportPrioritizesReadySamplesMissingFromMatrix() throws {
        let preparation = SoftwareSamplePreparationReport(
            generatedAt: Date(timeIntervalSince1970: 500),
            rootPath: "/tmp/MacWin",
            downloadsPath: "/tmp/MacWin/Downloads",
            entries: [
                SoftwareSamplePreparationEntry(
                    sampleId: "hoyoplay-cn",
                    name: "HoYoPlay",
                    publisher: "miHoYo",
                    category: "Game Launcher",
                    installSource: .signedRecipe,
                    catalogRecipeId: "hoyoplay-cn",
                    catalogBacked: true,
                    status: .ready,
                    compatibilityProfileId: "hoyoplay",
                    installerFileNames: [],
                    cachedInstallerPaths: [],
                    requiredAction: "Install from signed MacWin recipe hoyoplay-cn.",
                    expectedIssueIds: ["text-rendering"],
                    recommendedProbeIds: ["70_text_rendering_probe"],
                    warnings: []
                ),
                SoftwareSamplePreparationEntry(
                    sampleId: "scientific-industrial-pack",
                    name: "QGIS / Octave / Scilab / OpenModelica / Stellarium / JASP",
                    publisher: "QGIS / JASP",
                    category: "Scientific / Industrial",
                    installSource: .localInstaller,
                    catalogBacked: false,
                    status: .ready,
                    compatibilityProfileId: "qt-opengl-cad",
                    installerFileNames: ["JASP-0.97.1-Windows-Community.msi"],
                    cachedInstallerPaths: ["/tmp/MacWin/Downloads/JASP-0.97.1-Windows-Community.msi"],
                    requiredAction: "Use the cached local installer from Downloads.",
                    expectedIssueIds: ["large-installer", "qt-text", "opengl-viewport", "plot-rendering"],
                    recommendedProbeIds: ["20_vulkan_probe", "60_game_shader_probe", "70_text_rendering_probe"],
                    warnings: []
                ),
                SoftwareSamplePreparationEntry(
                    sampleId: "tencent-app-store",
                    name: "应用宝 / 腾讯应用市场",
                    publisher: "Tencent",
                    category: "App Store",
                    installSource: .localInstaller,
                    catalogBacked: false,
                    status: .ready,
                    compatibilityProfileId: "cef-software-renderer",
                    installerFileNames: ["QQPhoneManager.exe"],
                    cachedInstallerPaths: ["/tmp/MacWin/Downloads/QQPhoneManager.exe"],
                    requiredAction: "Use the cached local installer from Downloads.",
                    expectedIssueIds: ["webview-text", "wow64-helper", "network-tls"],
                    recommendedProbeIds: ["10_tls_winhttp_probe", "10_tls_winhttp_probe_32", "70_text_rendering_probe"],
                    warnings: []
                ),
                SoftwareSamplePreparationEntry(
                    sampleId: "missing-local",
                    name: "Missing Local",
                    publisher: "Example",
                    category: "Utilities",
                    installSource: .localInstaller,
                    catalogBacked: false,
                    status: .missingInstaller,
                    installerFileNames: ["MissingSetup.exe"],
                    cachedInstallerPaths: [],
                    requiredAction: "Place one matching local installer in Downloads.",
                    recommendedProbeIds: [],
                    warnings: []
                )
            ]
        )
        let matrix = SoftwareSmokeMatrixReport(
            rootPath: "/tmp/MacWin",
            rows: [
                smokeRow(recipeId: "hoyoplay-cn", name: "HoYoPlay", stage: .verified)
            ]
        )

        let report = SoftwareSampleCatalogService.smokeCoverageReport(
            preparation: preparation,
            smokeMatrix: matrix,
            generatedAt: Date(timeIntervalSince1970: 501)
        )

        #expect(report.sampleCount == 4)
        #expect(report.readySampleCount == 3)
        #expect(report.smokeMatrixRecipeCount == 1)
        #expect(report.coveredReadySampleCount == 1)
        #expect(report.coveredSampleIds == ["hoyoplay-cn"])
        #expect(report.uncoveredReadySampleCount == 2)
        #expect(report.blockedSampleCount == 1)
        #expect(report.uncoveredReadySamples.map(\.sampleId) == ["scientific-industrial-pack", "tencent-app-store"])
        #expect(report.nextActions.first?.recommendedAction.contains("extended smoke recipe") == true)
        #expect(report.nextActions.first?.recommendedProbeIds.contains("60_game_shader_probe") == true)
        #expect(report.readyCoveragePercent > 33)
        #expect(report.readyCoveragePercent < 34)

        let csv = SoftwareSampleCatalogService.smokeCoverageCSV(report: report)
        #expect(csv.contains("sample_id,name,category,install_source,status,catalog_recipe_id,smoke_stage"))
        #expect(csv.contains("scientific-industrial-pack,QGIS / Octave / Scilab / OpenModelica / Stellarium / JASP"))
        #expect(!csv.contains("hoyoplay-cn,HoYoPlay"))

        let markdown = SoftwareSampleCatalogService.smokeCoverageMarkdown(report: report)
        #expect(markdown.contains("# MacWin Software Sample Smoke Coverage"))
        #expect(markdown.contains("- Covered ready samples: 1"))
        #expect(markdown.contains("### QGIS / Octave / Scilab / OpenModelica / Stellarium / JASP"))
        #expect(markdown.contains("`60_game_shader_probe`"))
        #expect(markdown.contains("## Blocked Samples"))
        #expect(markdown.contains("missing-local"))
    }

    @Test("Smoke coverage report can use local launch history as ready coverage")
    func smokeCoverageReportUsesLocalLaunchHistoryAsCoverage() throws {
        let preparation = SoftwareSamplePreparationReport(
            generatedAt: Date(timeIntervalSince1970: 500),
            rootPath: "/tmp/MacWin",
            downloadsPath: "/tmp/MacWin/Downloads",
            entries: [
                SoftwareSamplePreparationEntry(
                    sampleId: "hoyoplay-cn",
                    name: "HoYoPlay",
                    publisher: "miHoYo",
                    category: "Game Launcher",
                    installSource: .signedRecipe,
                    catalogRecipeId: "hoyoplay-cn",
                    catalogBacked: true,
                    status: .ready,
                    compatibilityProfileId: "hoyoplay",
                    installerFileNames: [],
                    cachedInstallerPaths: [],
                    requiredAction: "Install from signed MacWin recipe hoyoplay-cn.",
                    expectedIssueIds: ["text-rendering"],
                    recommendedProbeIds: ["70_text_rendering_probe"],
                    warnings: []
                ),
                SoftwareSamplePreparationEntry(
                    sampleId: "missing-local",
                    name: "Missing Local",
                    publisher: "Example",
                    category: "Utilities",
                    installSource: .localInstaller,
                    catalogBacked: false,
                    status: .missingInstaller,
                    installerFileNames: ["MissingSetup.exe"],
                    cachedInstallerPaths: [],
                    requiredAction: "Place one matching local installer in Downloads.",
                    recommendedProbeIds: [],
                    warnings: []
                )
                ]
        )
        let matrix = SoftwareSmokeMatrixReport(
            rootPath: "/tmp/MacWin",
            rows: []
        )
        let launchRecords = [
            WineLaunchRecord(
                id: "launch-hoyoplay-1",
                mode: .foregroundRun,
                state: .completed,
                logPath: "/tmp/MacWin/Logs/hoyoplay.log",
                startedAt: Date(timeIntervalSince1970: 501),
                endedAt: Date(timeIntervalSince1970: 506),
                durationMilliseconds: 5_000,
                processIdentifier: 12_345,
                exitCode: 0,
                bottleId: "b1",
                bottleName: "Default",
                engineId: "wine-11.11-x86_64-game",
                winePath: "/Users/a1-6/project/Mac-Win/refs/Whisky-x86_64-game-build/Wine.app/Contents/Resources/wine/bin/wine64",
                exe: "C:\\Program Files\\miHoYo Launcher\\HYP.exe",
                args: [],
                commandLine: ["/c", "start"],
                workingDirectory: "C:\\",
                environment: [:]
            )
        ]

        let report = SoftwareSampleCatalogService.smokeCoverageReport(
            preparation: preparation,
            smokeMatrix: matrix,
            launchRecords: launchRecords,
            generatedAt: Date(timeIntervalSince1970: 502)
        )

        #expect(report.readySampleCount == 1)
        #expect(report.coveredReadySampleCount == 1)
        #expect(report.coveredSampleIds == ["hoyoplay-cn"])
        #expect(report.uncoveredReadySampleCount == 0)
        #expect(report.nextActions.isEmpty)
    }

    @Test("Smoke coverage report uses successful real software smoke evidence")
    func smokeCoverageReportUsesSoftwareSmokeEvidence() throws {
        let preparation = SoftwareSamplePreparationReport(
            generatedAt: Date(timeIntervalSince1970: 500),
            rootPath: "/tmp/MacWin",
            downloadsPath: "/tmp/MacWin/Downloads",
            entries: [
                SoftwareSamplePreparationEntry(
                    sampleId: "freecad-workbench",
                    name: "FreeCAD",
                    publisher: "FreeCAD",
                    category: "Industrial CAD",
                    installSource: .localInstaller,
                    catalogBacked: false,
                    status: .ready,
                    compatibilityProfileId: "qt-opengl-cad",
                    installerFileNames: ["FreeCAD.exe"],
                    cachedInstallerPaths: ["/tmp/MacWin/Downloads/FreeCAD.exe"],
                    requiredAction: "Use cached installer.",
                    expectedIssueIds: ["opengl-viewport"],
                    recommendedProbeIds: ["20_vulkan_probe"],
                    warnings: []
                ),
                SoftwareSamplePreparationEntry(
                    sampleId: "scientific-industrial-pack",
                    name: "Scientific tools",
                    publisher: "JASP",
                    category: "Scientific / Industrial",
                    installSource: .localInstaller,
                    catalogBacked: false,
                    status: .ready,
                    installerFileNames: ["JASP.msi"],
                    cachedInstallerPaths: ["/tmp/MacWin/Downloads/JASP.msi"],
                    requiredAction: "Use cached installer.",
                    recommendedProbeIds: [],
                    warnings: []
                ),
                SoftwareSamplePreparationEntry(
                    sampleId: "creative-extended-pack",
                    name: "Creative tools",
                    publisher: "Krita",
                    category: "Creative / Media",
                    installSource: .localInstaller,
                    catalogBacked: false,
                    status: .ready,
                    compatibilityProfileId: "qt-opengl-media",
                    installerFileNames: ["krita.exe"],
                    cachedInstallerPaths: ["/tmp/MacWin/Downloads/krita.exe"],
                    requiredAction: "Use cached installer.",
                    expectedIssueIds: ["opengl-viewport"],
                    recommendedProbeIds: ["20_vulkan_probe"],
                    warnings: []
                ),
                SoftwareSamplePreparationEntry(
                    sampleId: "windows-utility-stress-pack",
                    name: "PowerToys",
                    publisher: "Microsoft",
                    category: "Utilities / Windows Integration",
                    installSource: .localInstaller,
                    catalogBacked: false,
                    status: .ready,
                    compatibilityProfileId: "win32-utilities",
                    installerFileNames: ["PowerToysUserSetup.exe"],
                    cachedInstallerPaths: ["/tmp/MacWin/Downloads/PowerToysUserSetup.exe"],
                    requiredAction: "Use cached installer.",
                    expectedIssueIds: ["windows-version-api"],
                    recommendedProbeIds: ["00_console_probe"],
                    warnings: []
                )
            ]
        )
        let reports = [
            SoftwareSmokeRunReport(
                generatedAt: "2026-07-13T04:47:28Z",
                runId: "freecad-run",
                suite: "cad",
                sample: "freecad-workbench",
                prefix: "/tmp/prefix",
                logDirectory: "/tmp/logs/freecad-run",
                recordCount: 1,
                stateCounts: ["launched": 1],
                records: [
                    SoftwareSmokeRunRecord(
                        id: "freecad-workbench",
                        phase: "launch",
                        state: "launched",
                        exitCode: 124,
                        logPath: "/tmp/logs/freecad-launch.log"
                    )
                ]
            ),
            SoftwareSmokeRunReport(
                generatedAt: "2026-07-13T04:48:28Z",
                runId: "jasp-run",
                suite: "industrial",
                sample: "jasp-stats",
                prefix: "/tmp/prefix",
                logDirectory: "/tmp/logs/jasp-run",
                recordCount: 1,
                stateCounts: ["passed": 1],
                records: [
                    SoftwareSmokeRunRecord(
                        id: "jasp-stats",
                        phase: "launch",
                        state: "passed",
                        exitCode: 0,
                        logPath: "/tmp/logs/jasp-launch.log"
                    )
                ]
            ),
            SoftwareSmokeRunReport(
                generatedAt: "2026-07-13T04:49:28Z",
                runId: "krita-run",
                suite: "graphics",
                sample: "krita-paint",
                prefix: "/tmp/prefix",
                logDirectory: "/tmp/logs/krita-run",
                recordCount: 2,
                stateCounts: ["launched": 1, "passed": 1],
                records: [
                    SoftwareSmokeRunRecord(
                        id: "krita-paint",
                        phase: "launch",
                        state: "launched",
                        exitCode: 124,
                        logPath: "/tmp/logs/krita-launch.log"
                    ),
                    SoftwareSmokeRunRecord(
                        id: "krita-paint",
                        phase: "image-workload",
                        state: "passed",
                        exitCode: 0,
                        logPath: "/tmp/logs/krita-image-workload.log"
                    )
                ]
            ),
            SoftwareSmokeRunReport(
                generatedAt: "2026-07-13T04:50:28Z",
                runId: "powertoys-run",
                suite: "utility",
                sample: "powertoys-fancyzones",
                prefix: "/tmp/prefix",
                logDirectory: "/tmp/logs/powertoys-run",
                recordCount: 3,
                stateCounts: ["passed": 2, "skipped": 1],
                records: [
                    SoftwareSmokeRunRecord(
                        id: "powertoys-fancyzones",
                        phase: "launch",
                        state: "passed",
                        exitCode: 0,
                        logPath: "/tmp/logs/powertoys-launch.log"
                    ),
                    SoftwareSmokeRunRecord(
                        id: "powertoys-fancyzones",
                        phase: "fancyzones-workload",
                        state: "passed",
                        exitCode: 0,
                        logPath: "/tmp/logs/powertoys-fancyzones.log"
                    ),
                    SoftwareSmokeRunRecord(
                        id: "powertoys-fancyzones",
                        phase: "image-resizer-workload",
                        state: "skipped",
                        exitCode: 121,
                        logPath: "/tmp/logs/powertoys-image-resizer.log"
                    )
                ]
            )
        ]

        let report = SoftwareSampleCatalogService.smokeCoverageReport(
            preparation: preparation,
            smokeMatrix: SoftwareSmokeMatrixReport(rootPath: "/tmp/MacWin", rows: []),
            smokeReports: reports,
            generatedAt: Date(timeIntervalSince1970: 501)
        )

        #expect(report.coveredSampleIds == ["creative-extended-pack", "freecad-workbench", "scientific-industrial-pack", "windows-utility-stress-pack"])
        #expect(report.uncoveredReadySampleCount == 0)
    }

    @Test("Default sample preparation recognizes downloaded third-party market installers")
    func defaultPreparationRecognizesDownloadedThirdPartyMarketInstallers() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinDefaultSampleDownloadsTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let downloads = root.appendingPathComponent("Downloads", isDirectory: true)
        try FileManager.default.createDirectory(at: downloads, withIntermediateDirectories: true)
        let genericExtracted = downloads.appendingPathComponent("ndp48-extracted", isDirectory: true)
        try FileManager.default.createDirectory(at: genericExtracted, withIntermediateDirectories: true)
        try Data("generic setup".utf8).write(
            to: genericExtracted.appendingPathComponent("Setup.exe")
        )
        try Data("portable".utf8).write(
            to: downloads.appendingPathComponent("PortableApps.com_Platform_Setup_30.4.1.paf.exe")
        )
        try Data("npackd".utf8).write(
            to: downloads.appendingPathComponent("Npackd64-1.26.9.zip")
        )
        try Data("tencent".utf8).write(
            to: downloads.appendingPathComponent("pcyyb.exe")
        )
        try Data("vivaldi".utf8).write(
            to: downloads.appendingPathComponent("Vivaldi.7.9.3970.47.x64.exe")
        )
        try Data("qgis".utf8).write(
            to: downloads.appendingPathComponent("QGIS-OSGeo4W-3.44.11-1.msi")
        )
        try Data("drawio".utf8).write(
            to: downloads.appendingPathComponent("draw.io-30.2.4.msi")
        )
        try Data("vscode".utf8).write(
            to: downloads.appendingPathComponent("VSCodeUserSetup-x64-1.125.1.exe")
        )
        try Data("dbeaver".utf8).write(
            to: downloads.appendingPathComponent("dbeaver-ce-latest-x86_64-setup.exe")
        )
        try Data("solvespace".utf8).write(
            to: downloads.appendingPathComponent("SolveSpace-3.2-x64.exe")
        )
        try Data("moonlight".utf8).write(
            to: downloads.appendingPathComponent("MoonlightSetup-6.1.0.exe")
        )
        try Data("qbittorrent".utf8).write(
            to: downloads.appendingPathComponent("qbittorrent_5.2.2_x64_setup.exe")
        )
        try Data("powertoys".utf8).write(
            to: downloads.appendingPathComponent("PowerToysUserSetup-0.100.0-x64.exe")
        )

        let catalog = SoftwareSampleCatalogService.report(
            rootPath: root.path,
            recipes: [recipe(id: "portableapps-platform", name: "PortableApps.com Platform")],
            generatedAt: Date(timeIntervalSince1970: 300)
        )
        let preparation = SoftwareSampleCatalogService.preparationReport(
            catalog: catalog,
            downloadsDirectory: downloads,
            generatedAt: Date(timeIntervalSince1970: 301)
        )

        let portableApps = try #require(preparation.entries.first { $0.sampleId == "portableapps-platform" })
        #expect(portableApps.status == .ready)
        #expect(portableApps.cachedInstallerPaths.first?.hasSuffix("PortableApps.com_Platform_Setup_30.4.1.paf.exe") == true)
        #expect(!portableApps.cachedInstallerPaths.contains { $0.hasSuffix("ndp48-extracted/Setup.exe") })

        let npackd = try #require(preparation.entries.first { $0.sampleId == "npackd" })
        #expect(npackd.status == .ready)
        #expect(npackd.cachedInstallerPaths.first?.hasSuffix("Npackd64-1.26.9.zip") == true)

        let tencent = try #require(preparation.entries.first { $0.sampleId == "tencent-app-store" })
        #expect(tencent.status == .ready)
        #expect(tencent.cachedInstallerPaths.first?.hasSuffix("pcyyb.exe") == true)

        let privacyBrowsers = try #require(preparation.entries.first { $0.sampleId == "privacy-browser-pack" })
        #expect(privacyBrowsers.status == .ready)
        #expect(privacyBrowsers.cachedInstallerPaths.first?.hasSuffix("Vivaldi.7.9.3970.47.x64.exe") == true)

        let scientificPack = try #require(preparation.entries.first { $0.sampleId == "scientific-industrial-pack" })
        #expect(scientificPack.status == .ready)
        #expect(scientificPack.cachedInstallerPaths.first?.hasSuffix("QGIS-OSGeo4W-3.44.11-1.msi") == true)

        let productivityPack = try #require(preparation.entries.first { $0.sampleId == "productivity-document-pack" })
        #expect(productivityPack.status == .ready)
        #expect(productivityPack.cachedInstallerPaths.first?.hasSuffix("draw.io-30.2.4.msi") == true)

        let developerToolchain = try #require(preparation.entries.first { $0.sampleId == "developer-toolchain" })
        #expect(developerToolchain.status == .ready)
        #expect(developerToolchain.cachedInstallerPaths.first?.hasSuffix("VSCodeUserSetup-x64-1.125.1.exe") == true)

        let databasePack = try #require(preparation.entries.first { $0.sampleId == "database-developer-pack" })
        #expect(databasePack.status == .ready)
        #expect(databasePack.cachedInstallerPaths.first?.hasSuffix("dbeaver-ce-latest-x86_64-setup.exe") == true)

        let electricalPack = try #require(preparation.entries.first { $0.sampleId == "electrical-parametric-cad-pack" })
        #expect(electricalPack.status == .ready)
        #expect(electricalPack.cachedInstallerPaths.first?.hasSuffix("SolveSpace-3.2-x64.exe") == true)

        let creativeExtended = try #require(preparation.entries.first { $0.sampleId == "creative-extended-pack" })
        #expect(creativeExtended.status == .ready)
        #expect(creativeExtended.cachedInstallerPaths.first?.hasSuffix("MoonlightSetup-6.1.0.exe") == true)

        let utilityPack = try #require(preparation.entries.first { $0.sampleId == "utility-network-pack" })
        #expect(utilityPack.status == .ready)
        #expect(utilityPack.cachedInstallerPaths.first?.hasSuffix("qbittorrent_5.2.2_x64_setup.exe") == true)

        let powerToys = try #require(preparation.entries.first { $0.sampleId == "windows-utility-stress-pack" })
        #expect(powerToys.status == .ready)
        #expect(powerToys.cachedInstallerPaths.first?.hasSuffix("PowerToysUserSetup-0.100.0-x64.exe") == true)

        let csv = SoftwareSampleCatalogService.preparationCSV(report: preparation)
        #expect(csv.contains("portableapps-platform,PortableApps.com Platform,PortableApps.com,App Store,signedRecipe,portableapps-platform,true,ready"))
        #expect(csv.contains("npackd,Npackd,Npackd,Package Manager,localInstaller,,false,ready"))
        #expect(csv.contains("tencent-app-store,应用宝 / 腾讯应用市场,Tencent,App Store,localInstaller,,false,ready"))
        #expect(csv.contains("privacy-browser-pack,Vivaldi / LibreWolf,Vivaldi Technologies / LibreWolf,Browser,localInstaller,,false,ready"))
        #expect(csv.contains("scientific-industrial-pack,QGIS / Octave / Scilab / OpenModelica / OpenDSS / Stellarium / JASP,QGIS / GNU Octave / Dassault Systèmes / Open Source Modelica Consortium / EPRI / Stellarium / JASP,Scientific / Industrial,localInstaller,,false,ready"))
        #expect(csv.contains("productivity-document-pack,draw.io / Joplin / Obsidian / calibre / PDF Tools,JGraph / Joplin / Obsidian / calibre / SumatraPDF / PDFsam,Office / Productivity,localInstaller,,false,ready"))
        #expect(csv.contains("developer-toolchain,Developer Toolchain Pack,Microsoft / Git / Notepad++ / PuTTY / KeePass,Developer Tools,localInstaller,,false,ready"))
        #expect(csv.contains("database-developer-pack,DBeaver / Beekeeper Studio / SQLite Browser / GitExtensions / x64dbg / mRemoteNG,DBeaver / Beekeeper Studio / SQLite Browser / GitExtensions / x64dbg / mRemoteNG,Developer / Industrial Tools,localInstaller,,false,ready"))
        #expect(csv.contains("electrical-parametric-cad-pack,SolveSpace / QElectroTech,SolveSpace / QElectroTech,Industrial CAD,localInstaller,,false,ready"))
        #expect(csv.contains("creative-extended-pack,Krita / MuseScore / Flameshot / Moonlight,Krita / MuseScore / Flameshot / Moonlight,Creative / Media,localInstaller,,false,ready"))
        #expect(csv.contains("utility-network-pack,Utilities / Network Pack,7-Zip / SumatraPDF / qBittorrent / Everything,Utilities / Network,localInstaller,,false,ready"))
        #expect(csv.contains("windows-utility-stress-pack,PowerToys,Microsoft,Utilities / Windows Integration,localInstaller,,false,ready"))

        let markdown = SoftwareSampleCatalogService.preparationMarkdown(report: preparation)
        #expect(markdown.contains("### PortableApps.com Platform"))
        #expect(markdown.contains("### Npackd"))
        #expect(markdown.contains("### 应用宝 / 腾讯应用市场"))
        #expect(markdown.contains("### Vivaldi / LibreWolf"))
        #expect(markdown.contains("### QGIS / Octave / Scilab / OpenModelica / OpenDSS / Stellarium / JASP"))
        #expect(markdown.contains("### draw.io / Joplin / Obsidian / calibre / PDF Tools"))
        #expect(markdown.contains("### Developer Toolchain Pack"))
        #expect(markdown.contains("### DBeaver / Beekeeper Studio / SQLite Browser / GitExtensions / x64dbg / mRemoteNG"))
        #expect(markdown.contains("### SolveSpace / QElectroTech"))
        #expect(markdown.contains("### Krita / MuseScore / Flameshot / Moonlight"))
        #expect(markdown.contains("### Utilities / Network Pack"))
        #expect(markdown.contains("### PowerToys"))
        #expect(markdown.contains("pcyyb.exe"))
    }

    @Test("Default sample preparation recognizes Tencent App Store aliases without generic setup false positives")
    func defaultPreparationRecognizesTencentAliasesWithoutGenericSetupFalsePositives() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinTencentAliasInstallerTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let downloads = root.appendingPathComponent("Downloads", isDirectory: true)
        try FileManager.default.createDirectory(at: downloads, withIntermediateDirectories: true)
        try Data("generic setup".utf8).write(
            to: downloads.appendingPathComponent("Setup.exe")
        )
        try Data("tencent setup".utf8).write(
            to: downloads.appendingPathComponent("Tencent_PCManager_Setup_17.0.exe")
        )
        try Data("yingyongbao cn".utf8).write(
            to: downloads.appendingPathComponent("应用宝安装器.exe")
        )
        try Data("official tencent winget installer".utf8).write(
            to: downloads.appendingPathComponent("QQPhoneManager-5.8.3_990420.5400.n.exe")
        )

        let catalog = SoftwareSampleCatalogService.report(
            rootPath: root.path,
            recipes: [],
            generatedAt: Date(timeIntervalSince1970: 312)
        )
        let preparation = SoftwareSampleCatalogService.preparationReport(
            catalog: catalog,
            downloadsDirectory: downloads,
            generatedAt: Date(timeIntervalSince1970: 313)
        )

        let tencent = try #require(preparation.entries.first { $0.sampleId == "tencent-app-store" })
        #expect(tencent.status == .ready)
        #expect(tencent.cachedInstallerPaths.contains { $0.hasSuffix("Tencent_PCManager_Setup_17.0.exe") })
        #expect(tencent.cachedInstallerPaths.contains { $0.hasSuffix("应用宝安装器.exe") })
        #expect(tencent.cachedInstallerPaths.contains { $0.hasSuffix("QQPhoneManager-5.8.3_990420.5400.n.exe") })
        #expect(!tencent.cachedInstallerPaths.contains { $0.hasSuffix("Setup.exe") })
    }

    @Test("Default sample preparation does not match every Studio app as RStudio")
    func defaultPreparationDoesNotMatchEveryStudioAppAsRStudio() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinStudioFalsePositiveTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let downloads = root.appendingPathComponent("Downloads", isDirectory: true)
        try FileManager.default.createDirectory(at: downloads, withIntermediateDirectories: true)
        try Data("bambu".utf8).write(
            to: downloads.appendingPathComponent("Bambu_Studio_win-v02.07.01.62-20260616174358.exe")
        )
        try Data("obs".utf8).write(
            to: downloads.appendingPathComponent("OBS-Studio-32.1.2-Windows-x64-Installer.exe")
        )
        try Data("rstudio".utf8).write(
            to: downloads.appendingPathComponent("RStudio-2025.09.0-387.exe")
        )

        let catalog = SoftwareSampleCatalogService.report(
            rootPath: root.path,
            recipes: [],
            generatedAt: Date(timeIntervalSince1970: 314)
        )
        let preparation = SoftwareSampleCatalogService.preparationReport(
            catalog: catalog,
            downloadsDirectory: downloads,
            generatedAt: Date(timeIntervalSince1970: 315)
        )

        let scientificPack = try #require(preparation.entries.first { $0.sampleId == "scientific-industrial-pack" })
        #expect(scientificPack.status == .ready)
        #expect(scientificPack.cachedInstallerPaths.contains { $0.hasSuffix("RStudio-2025.09.0-387.exe") })
        #expect(!scientificPack.cachedInstallerPaths.contains { $0.hasSuffix("Bambu_Studio_win-v02.07.01.62-20260616174358.exe") })
        #expect(!scientificPack.cachedInstallerPaths.contains { $0.hasSuffix("OBS-Studio-32.1.2-Windows-x64-Installer.exe") })
    }

    @Test("Default sample preparation does not treat Lenovo store installers as Tencent App Store")
    func defaultPreparationRejectsAmbiguousLenovoStoreInstallerForTencent() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinAmbiguousTencentInstallerTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let downloads = root.appendingPathComponent("Downloads", isDirectory: true)
        try FileManager.default.createDirectory(at: downloads, withIntermediateDirectories: true)
        try Data("lenovo store package".utf8).write(
            to: downloads.appendingPathComponent("dropped-77DF71B9-Store-ind-10002.exe")
        )

        let catalog = SoftwareSampleCatalogService.report(
            rootPath: root.path,
            recipes: [],
            generatedAt: Date(timeIntervalSince1970: 310)
        )
        let preparation = SoftwareSampleCatalogService.preparationReport(
            catalog: catalog,
            downloadsDirectory: downloads,
            generatedAt: Date(timeIntervalSince1970: 311)
        )

        let tencent = try #require(preparation.entries.first { $0.sampleId == "tencent-app-store" })
        #expect(tencent.status == .missingInstaller)
        #expect(tencent.cachedInstallerPaths.isEmpty)
        #expect(tencent.requiredAction.contains("pcyyb.exe"))
        #expect(!tencent.requiredAction.contains("Store-ind-10002.exe"))
    }

    private func recipe(id: String, name: String) -> RecipeManifest {
        RecipeManifest(
            id: id,
            name: name,
            publisher: "Publisher",
            category: "Utilities",
            compatibilityRating: .good,
            installer: InstallerSpec(mode: .none),
            bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
            engineRequirements: EngineRequirements(),
            launchers: []
        )
    }

    private func smokeRow(recipeId: String, name: String, stage: SoftwareSmokeStage) -> SoftwareSmokeMatrixRow {
        SoftwareSmokeMatrixRow(
            recipeId: recipeId,
            name: name,
            category: "Utilities",
            compatibilityRating: .good,
            stage: stage,
            state: .verified,
            highestSeverity: .passed,
            checklist: [
                SoftwareSmokeChecklistItem(
                    id: "launch",
                    label: "Launch",
                    state: .passed,
                    detail: "Verified."
                )
            ],
            blockerCount: 0,
            warningCount: 0,
            nextAction: "No action.",
            latestLogPath: nil,
            latestLaunchLogPath: nil,
            latestRepairState: nil
        )
    }
}
