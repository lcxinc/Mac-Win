import Foundation
import Testing
@testable import MacWinCore

@Suite("Software collection service")
struct SoftwareCollectionServiceTests {
    @Test("Report groups curated recipes and preserves installer hashes")
    func reportGroupsRecipesAndPreservesHashes() throws {
        let rootPath = "/tmp/MacWin Collections"
        let hash = String(repeating: "a", count: 64)
        let recipes = [
            Self.recipe(
                id: "7zip",
                name: "7-Zip",
                mode: .download,
                fileName: "7z.exe",
                sha256: hash
            ),
            Self.recipe(
                id: "steam",
                name: "Steam",
                mode: .download,
                fileName: "SteamSetup.exe",
                sha256: hash
            ),
            Self.recipe(
                id: "macwin-game-tests",
                name: "MacWin Game Tests",
                mode: .none
            )
        ]
        let collections = [
            SoftwareCollectionDefinition(
                id: "baseline",
                name: "Baseline",
                purpose: "Baseline utilities",
                requiredRecipeIds: ["7zip", "missing-recipe"]
            ),
            SoftwareCollectionDefinition(
                id: "launchers",
                name: "Launchers",
                purpose: "Launcher apps",
                requiredRecipeIds: ["steam"]
            ),
            SoftwareCollectionDefinition(
                id: "diagnostics",
                name: "Diagnostics",
                purpose: "Probe apps",
                requiredRecipeIds: ["macwin-game-tests"]
            )
        ]

        let report = SoftwareCollectionService.report(
            rootPath: rootPath,
            collections: collections,
            recipes: recipes,
            readiness: Self.readinessReport(rootPath: rootPath, recipes: recipes),
            installerAssets: Self.installerReport(rootPath: rootPath, hash: hash),
            softwareTestPlan: Self.testPlan(rootPath: rootPath),
            softwareSmokeMatrix: Self.smokeMatrix(rootPath: rootPath),
            adaptationQueue: Self.adaptationQueue(rootPath: rootPath),
            generatedAt: Date(timeIntervalSince1970: 100)
        )

        #expect(report.collectionCount == 3)
        #expect(report.recipeCount == 3)
        #expect(report.missingRecipeIds == ["missing-recipe"])
        #expect(report.downloadableRecipeCount == 2)
        #expect(report.cachedInstallerCount == 1)
        #expect(report.missingInstallerCount == 1)
        #expect(report.verifiedRecipeCount == 1)
        #expect(report.actionRequiredCount == 3)

        let steam = try #require(report.entries.first { $0.recipeId == "steam" })
        #expect(steam.collectionIds == ["launchers"])
        #expect(steam.expectedSha256 == hash)
        #expect(steam.installerHashStatus == InstallerHashStatus.missing)
        #expect(steam.cachedInstallerExists == false)
        #expect(steam.softwareState == SoftwareTestPlanState.missingInstaller)
        #expect(steam.smokeStage == SoftwareSmokeStage.installer)
        #expect(steam.recommendedProbeIds == ["text-rendering", "window-input"])

        let csv = SoftwareCollectionService.csv(report: report)
        #expect(csv.contains("recipe_id,name,publisher,category,collections,compatibility_rating,installer_mode,installer_file_name,expected_sha256"))
        #expect(csv.contains("steam,Steam,Test Publisher,Utilities,launchers,good,download,SteamSetup.exe,\(hash),missing"))
        #expect(csv.contains("missing-recipe,,,,,,,"))

        let script = SoftwareCollectionService.downloadScript(report: report)
        #expect(script.contains("download_one 'steam' 'https://example.test/SteamSetup.exe' 'SteamSetup.exe' '\(hash)'"))
        #expect(script.contains("shasum -a 256 -c -"))
        #expect(!script.contains("download_one '7zip'"))

        let lockfile = SoftwareCollectionService.lockfile(report: report)
        #expect(lockfile.downloadsPath == "\(rootPath)/Downloads")
        #expect(lockfile.recipeCount == 3)
        #expect(lockfile.downloadableRecipeCount == 2)
        #expect(lockfile.cachedInstallerCount == 1)
        #expect(lockfile.missingInstallerCount == 1)
        #expect(lockfile.hashProtectedCount == 2)
        #expect(lockfile.hashMismatchCount == 0)
        #expect(lockfile.unprotectedDownloadCount == 0)
        #expect(lockfile.missingRecipeIds == ["missing-recipe"])
        #expect(lockfile.items.first { $0.recipeId == "steam" }?.recommendedProbeIds == ["text-rendering", "window-input"])

        let lockfileCSV = SoftwareCollectionLockfile.csv(lockfile: lockfile)
        #expect(lockfileCSV.contains("recipe_id,name,publisher,category,collections,installer_mode"))
        #expect(lockfileCSV.contains("steam,Steam,Test Publisher,Utilities,launchers,download,SteamSetup.exe,https://example.test/SteamSetup.exe,\(hash),true,missing,false"))

        let lockfileMarkdown = SoftwareCollectionLockfile.markdown(lockfile: lockfile)
        #expect(lockfileMarkdown.contains("# MacWin Software Collection Lockfile"))
        #expect(lockfileMarkdown.contains("### Steam"))
        #expect(lockfileMarkdown.contains("Recommended probes: `text-rendering`, `window-input`"))
        #expect(lockfileMarkdown.contains("## Missing Recipes"))
        #expect(lockfileMarkdown.contains("`missing-recipe`"))
    }

    @Test("Download script explains when collection has no missing downloads")
    func downloadScriptHandlesCompleteCollection() {
        let report = SoftwareCollectionReport(
            generatedAt: Date(timeIntervalSince1970: 100),
            rootPath: "/tmp/MacWin",
            collections: [],
            missingRecipeIds: [],
            entries: []
        )

        let script = SoftwareCollectionService.downloadScript(report: report)
        #expect(script.contains("No missing downloadable installers"))
    }

    private static func recipe(
        id: String,
        name: String,
        mode: InstallerMode,
        fileName: String? = nil,
        sha256: String? = nil
    ) -> RecipeManifest {
        RecipeManifest(
            id: id,
            name: name,
            publisher: "Test Publisher",
            category: "Utilities",
            compatibilityRating: .good,
            installer: InstallerSpec(
                mode: mode,
                url: fileName.map { "https://example.test/\($0)" },
                fileName: fileName,
                sha256: sha256
            ),
            bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
            engineRequirements: EngineRequirements(),
            launchers: [
                LauncherRecipe(
                    id: "\(id)-launcher",
                    displayName: name,
                    exePath: "C:\\Program Files\\\(name)\\\(name).exe"
                )
            ]
        )
    }

    private static func readinessReport(rootPath: String, recipes: [RecipeManifest]) -> RecipeReadinessReport {
        RecipeReadinessReport(
            rootPath: rootPath,
            entries: recipes.map { recipe in
                RecipeReadinessEntry(
                    recipeId: recipe.id,
                    recipeName: recipe.name,
                    publisher: recipe.publisher,
                    category: recipe.category,
                    compatibilityRating: recipe.compatibilityRating,
                    installerMode: recipe.installer.mode,
                    state: recipe.id == "steam" ? .actionRequired : .ready,
                    issues: recipe.id == "steam" ? [.missingLauncherAsset] : [],
                    warningCount: 0,
                    requiresWin32: false,
                    compatibleEngineIds: ["engine"],
                    launcherCount: recipe.launchers.count,
                    downloadURL: recipe.installer.url,
                    fileName: recipe.installer.fileName,
                    sha256Present: recipe.installer.sha256 != nil
                )
            }
        )
    }

    private static func installerReport(rootPath: String, hash: String) -> InstallerAssetReport {
        InstallerAssetReport(
            rootPath: rootPath,
            downloadsPath: "\(rootPath)/Downloads",
            recipes: [
                RecipeInstallerAssetStatus(
                    recipeId: "7zip",
                    recipeName: "7-Zip",
                    publisher: "Test Publisher",
                    category: "Utilities",
                    compatibilityRating: .good,
                    disabled: false,
                    disabledReason: nil,
                    installerMode: .download,
                    fileName: "7z.exe",
                    sourceURL: "https://example.test/7z.exe",
                    expectedSha256: hash,
                    cachedPath: "\(rootPath)/Downloads/7z.exe",
                    cachedExists: true,
                    actualSha256: hash,
                    hashStatus: .match
                ),
                RecipeInstallerAssetStatus(
                    recipeId: "steam",
                    recipeName: "Steam",
                    publisher: "Test Publisher",
                    category: "Utilities",
                    compatibilityRating: .good,
                    disabled: false,
                    disabledReason: nil,
                    installerMode: .download,
                    fileName: "SteamSetup.exe",
                    sourceURL: "https://example.test/SteamSetup.exe",
                    expectedSha256: hash,
                    cachedPath: "\(rootPath)/Downloads/SteamSetup.exe",
                    cachedExists: false,
                    hashStatus: .missing
                )
            ],
            orphanedDownloads: []
        )
    }

    private static func testPlan(rootPath: String) -> SoftwareTestPlanReport {
        SoftwareTestPlanReport(
            rootPath: rootPath,
            entries: [
                testEntry(recipeId: "7zip", name: "7-Zip", state: .readyToInstall),
                testEntry(recipeId: "steam", name: "Steam", state: .missingInstaller),
                testEntry(recipeId: "macwin-game-tests", name: "MacWin Game Tests", state: .verified, installedLauncherCount: 1, latestLaunchState: .completed)
            ]
        )
    }

    private static func testEntry(
        recipeId: String,
        name: String,
        state: SoftwareTestPlanState,
        installedLauncherCount: Int = 0,
        latestLaunchState: WineLaunchState? = nil
    ) -> SoftwareTestPlanEntry {
        SoftwareTestPlanEntry(
            recipeId: recipeId,
            name: name,
            publisher: "Test Publisher",
            category: "Utilities",
            compatibilityRating: .good,
            state: state,
            priority: 10,
            summary: state.rawValue,
            recommendedAction: "Run \(name)",
            readinessState: .ready,
            readinessIssues: [],
            installerMode: recipeId == "macwin-game-tests" ? .none : .download,
            installerHashStatus: recipeId == "7zip" ? .match : .missing,
            cachedInstallerPath: recipeId == "7zip" ? "/tmp/MacWin/Downloads/7z.exe" : nil,
            requiresWin32: false,
            latestInstallState: nil,
            latestInstallAt: nil,
            latestInstallLogPath: nil,
            installedLauncherCount: installedLauncherCount,
            installedLauncherIds: installedLauncherCount > 0 ? ["\(recipeId)-launcher"] : [],
            latestLaunchState: latestLaunchState,
            latestLaunchAt: nil,
            latestLaunchLogPath: latestLaunchState == nil ? nil : "/tmp/MacWin/Logs/\(recipeId).log",
            latestLaunchExitCode: latestLaunchState == nil ? nil : 0,
            latestLogHealth: latestLaunchState == nil ? nil : .passed,
            latestLogHints: [],
            probableIssueIds: [],
            blockers: state == .missingInstaller ? ["missingInstaller"] : []
        )
    }

    private static func smokeMatrix(rootPath: String) -> SoftwareSmokeMatrixReport {
        SoftwareSmokeMatrixReport(
            rootPath: rootPath,
            rows: [
                smokeRow(recipeId: "7zip", name: "7-Zip", stage: .installer, state: .readyToInstall, severity: .pending),
                smokeRow(recipeId: "steam", name: "Steam", stage: .installer, state: .missingInstaller, severity: .blocked),
                smokeRow(recipeId: "macwin-game-tests", name: "MacWin Game Tests", stage: .verified, state: .verified, severity: .passed)
            ]
        )
    }

    private static func smokeRow(
        recipeId: String,
        name: String,
        stage: SoftwareSmokeStage,
        state: SoftwareTestPlanState,
        severity: SoftwareSmokeCheckState
    ) -> SoftwareSmokeMatrixRow {
        SoftwareSmokeMatrixRow(
            recipeId: recipeId,
            name: name,
            category: "Utilities",
            compatibilityRating: .good,
            stage: stage,
            state: state,
            highestSeverity: severity,
            checklist: [
                SoftwareSmokeChecklistItem(id: "installer", label: "Installer", state: severity, detail: state.rawValue)
            ],
            blockerCount: severity == .blocked ? 1 : 0,
            warningCount: severity == .warning ? 1 : 0,
            nextAction: "Run \(name)",
            latestLogPath: nil,
            latestLaunchLogPath: nil,
            latestRepairState: nil
        )
    }

    private static func adaptationQueue(rootPath: String) -> SoftwareAdaptationQueueReport {
        SoftwareAdaptationQueueReport(
            generatedAt: Date(timeIntervalSince1970: 100),
            rootPath: rootPath,
            tasks: [
                SoftwareAdaptationTask(
                    recipeId: "steam",
                    name: "Steam",
                    category: "Utilities",
                    compatibilityRating: .good,
                    state: .missingInstaller,
                    stage: .installer,
                    severity: .blocked,
                    priority: 10,
                    nextAction: "Download Steam",
                    latestLogPath: nil,
                    latestLaunchLogPath: nil,
                    probableIssueIds: ["text-rendering"],
                    blockers: ["missingInstaller"],
                    recommendedProbeIds: ["text-rendering", "window-input"],
                    probes: [
                        SoftwareAdaptationProbe(assetId: "text-rendering", state: .runnable, command: ["/bin/echo", "text"]),
                        SoftwareAdaptationProbe(assetId: "window-input", state: .unavailable, command: [])
                    ]
                )
            ]
        )
    }
}
