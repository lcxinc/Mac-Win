import Foundation
import Testing
@testable import MacWinCore

@Suite("Software acquisition service")
struct SoftwareAcquisitionServiceTests {
    @Test("Report combines collection downloads cached installers local samples and missing recipes")
    func reportCombinesAcquisitionSources() throws {
        let root = "/tmp/MacWinAcquire"
        let generatedAt = Date(timeIntervalSince1970: 700)
        let collection = SoftwareCollectionReport(
            generatedAt: generatedAt,
            rootPath: root,
            collections: [
                SoftwareCollectionDefinition(
                    id: "baseline",
                    name: "Baseline",
                    purpose: "Download and smoke test common launchers.",
                    requiredRecipeIds: ["steam", "7zip", "local-tool", "missing-tool"]
                )
            ],
            missingRecipeIds: ["missing-tool"],
            entries: [
                SoftwareCollectionEntry(
                    recipeId: "steam",
                    name: "Steam",
                    publisher: "Valve",
                    category: "Game Launcher",
                    collectionIds: ["baseline"],
                    compatibilityRating: .limited,
                    installerMode: .download,
                    installerFileName: "SteamSetup.exe",
                    installerSourceURL: "https://example.test/SteamSetup.exe",
                    expectedSha256: String(repeating: "a", count: 64),
                    installerHashStatus: .missing,
                    cachedInstallerPath: "\(root)/Downloads/SteamSetup.exe",
                    cachedInstallerExists: false,
                    softwareState: .missingInstaller,
                    smokeStage: .installer,
                    smokeSeverity: .blocked,
                    installedLauncherCount: 0,
                    latestLaunchState: nil,
                    latestLaunchLogPath: nil,
                    latestLogHealth: nil,
                    readinessIssues: [],
                    recommendedProbeIds: ["text-rendering"]
                ),
                SoftwareCollectionEntry(
                    recipeId: "7zip",
                    name: "7-Zip",
                    publisher: "Igor Pavlov",
                    category: "Utility",
                    collectionIds: ["baseline"],
                    compatibilityRating: .good,
                    installerMode: .download,
                    installerFileName: "7z.exe",
                    installerSourceURL: "https://example.test/7z.exe",
                    expectedSha256: String(repeating: "b", count: 64),
                    installerHashStatus: .match,
                    cachedInstallerPath: "\(root)/Downloads/7z.exe",
                    cachedInstallerExists: true,
                    softwareState: .verified,
                    smokeStage: .verified,
                    smokeSeverity: .passed,
                    installedLauncherCount: 1,
                    latestLaunchState: .completed,
                    latestLaunchLogPath: "\(root)/Logs/7zip.log",
                    latestLogHealth: .passed,
                    readinessIssues: [],
                    recommendedProbeIds: []
                ),
                SoftwareCollectionEntry(
                    recipeId: "local-tool",
                    name: "Local Tool",
                    publisher: "Local",
                    category: "Utility",
                    collectionIds: ["baseline"],
                    compatibilityRating: .unknown,
                    installerMode: .localFile,
                    installerFileName: "LocalTool.exe",
                    installerSourceURL: nil,
                    expectedSha256: nil,
                    installerHashStatus: .missing,
                    cachedInstallerPath: nil,
                    cachedInstallerExists: false,
                    softwareState: .localInstallerRequired,
                    smokeStage: .installer,
                    smokeSeverity: .blocked,
                    installedLauncherCount: 0,
                    latestLaunchState: nil,
                    latestLaunchLogPath: nil,
                    latestLogHealth: nil,
                    readinessIssues: [],
                    recommendedProbeIds: ["window-input"]
                )
            ]
        )
        let samplePreparation = SoftwareSamplePreparationReport(
            generatedAt: generatedAt,
            rootPath: root,
            downloadsPath: "\(root)/Downloads",
            entries: [
                SoftwareSamplePreparationEntry(
                    sampleId: "itch",
                    name: "itch.io",
                    installSource: .localInstaller,
                    catalogBacked: false,
                    status: .missingInstaller,
                    installerFileNames: ["itch-setup.exe"],
                    cachedInstallerPaths: [],
                    requiredAction: "Place one matching local installer in the MacWin Downloads directory: itch-setup.exe.",
                    recommendedProbeIds: ["text-rendering"],
                    warnings: []
                ),
                SoftwareSamplePreparationEntry(
                    sampleId: "hoyoplay-cn",
                    name: "HoYoPlay",
                    installSource: .signedRecipe,
                    catalogRecipeId: "hoyoplay-cn",
                    catalogBacked: false,
                    status: .missingRecipe,
                    installerFileNames: [],
                    cachedInstallerPaths: [],
                    requiredAction: "Add a signed HoYoPlay recipe.",
                    recommendedProbeIds: ["vulkan"],
                    warnings: []
                )
            ]
        )

        let report = SoftwareAcquisitionService.report(
            collection: collection,
            samplePreparation: samplePreparation,
            generatedAt: generatedAt
        )

        #expect(report.entryCount == 6)
        #expect(report.downloadableCount == 1)
        #expect(report.cachedCount == 1)
        #expect(report.missingLocalInstallerCount == 2)
        #expect(report.missingRecipeCount == 2)
        #expect(report.hashMismatchCount == 0)
        #expect(report.actionCount == 5)
        #expect(report.entries.first?.state == .missingRecipe)
        #expect(report.entries.contains { $0.id == "collection-steam" && $0.state == SoftwareAcquisitionState.downloadable })
        #expect(report.entries.contains { $0.id == "collection-7zip" && $0.state == SoftwareAcquisitionState.cached })
        #expect(report.entries.contains { $0.id == "collection-local-tool" && $0.state == SoftwareAcquisitionState.missingLocalInstaller })
        #expect(report.entries.contains { $0.id == "sample-itch" && $0.state == SoftwareAcquisitionState.missingLocalInstaller })
        #expect(report.entries.contains { $0.id == "sample-hoyoplay-cn" && $0.state == SoftwareAcquisitionState.missingRecipe })

        let csv = SoftwareAcquisitionReport.csv(report: report)
        #expect(csv.contains("id,source,state,name,recipe_id,sample_id"))
        #expect(csv.contains("collection-steam,collectionRecipe,downloadable,Steam"))
        #expect(csv.contains("sample-itch,softwareSample,missingLocalInstaller,itch.io"))

        let markdown = SoftwareAcquisitionReport.markdown(report: report)
        #expect(markdown.contains("# MacWin Software Acquisition"))
        #expect(markdown.contains("- Downloadable: 1"))
        #expect(markdown.contains("### HoYoPlay"))
        #expect(markdown.contains("- State: `missingRecipe`"))

        let script = SoftwareAcquisitionReport.shellScript(report: report)
        #expect(script.contains("#!/usr/bin/env bash"))
        #expect(script.contains("MacWin software acquisition plan"))
        #expect(script.contains("download_one 'collection-steam' 'https://example.test/SteamSetup.exe' 'SteamSetup.exe'"))
        #expect(script.contains("LOCAL_INSTALLER_REQUIRED sample-itch"))
        #expect(script.contains("MISSING_RECIPE missing-recipe-missing-tool"))
        #expect(script.contains("READY collection-7zip"))
    }
}
