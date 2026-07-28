import Foundation
import Testing
@testable import MacWinCore

@Suite("Recipe readiness service")
struct RecipeReadinessServiceTests {
    @Test("Recipe readiness report classifies installability and catalog hygiene")
    func recipeReadinessReportClassifiesInstallabilityAndCatalogHygiene() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRecipeReadinessTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()
        let probe = root.appendingPathComponent("probe.exe")
        try Data("probe".utf8).write(to: probe)
        let cachedLocalInstaller = paths.downloadsDirectory.appendingPathComponent("cached-local.exe")
        try Data("cached local".utf8).write(to: cachedLocalInstaller)
        let existing = root.appendingPathComponent("Existing/App.exe")
        try FileManager.default.createDirectory(at: existing.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("existing".utf8).write(to: existing)

        let engine = EngineManifest(
            id: "wine64",
            name: "Wine64",
            wineVersion: "wine-11.11",
            arch: .win64,
            supportsWin32: false,
            winePath: "/wine",
            wineserverPath: "/wineserver",
            runtimePath: "/runtime",
            defaultEnv: [:]
        )

        let recipes = [
            RecipeManifest(
                id: "ready-download",
                name: "Ready Download",
                publisher: "Tools",
                category: "Utilities",
                compatibilityRating: .excellent,
                installer: InstallerSpec(
                    mode: .download,
                    url: "https://example.test/ready.exe",
                    fileName: "ready.exe",
                    sha256: String(repeating: "a", count: 64)
                ),
                bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
                engineRequirements: EngineRequirements(),
                launchers: [LauncherRecipe(id: "ready", displayName: "Ready", exePath: "C:\\Ready\\ready.exe")]
            ),
            RecipeManifest(
                id: "missing-hash",
                name: "Missing Hash",
                publisher: "Tools",
                category: "Utilities",
                compatibilityRating: .unknown,
                installer: InstallerSpec(mode: .download, url: "https://example.test/nohash.exe", fileName: "nohash.exe"),
                bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
                engineRequirements: EngineRequirements(),
                launchers: [LauncherRecipe(id: "nohash", displayName: "No Hash", exePath: "C:\\NoHash\\app.exe")]
            ),
            RecipeManifest(
                id: "steam32",
                name: "Steam",
                publisher: "Valve",
                category: "Game Store",
                compatibilityRating: .experimental,
                installer: InstallerSpec(
                    mode: .download,
                    url: "https://example.test/SteamSetup.exe",
                    fileName: "SteamSetup.exe",
                    sha256: String(repeating: "b", count: 64)
                ),
                bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
                engineRequirements: EngineRequirements(requiresWin32: true),
                launchers: [LauncherRecipe(id: "steam", displayName: "Steam", exePath: "C:\\Program Files\\Steam\\Steam.exe")]
            ),
            RecipeManifest(
                id: "local-installer",
                name: "Local Installer",
                publisher: "Tools",
                category: "Utilities",
                compatibilityRating: .unknown,
                installer: InstallerSpec(mode: .localFile),
                bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
                engineRequirements: EngineRequirements(),
                launchers: [LauncherRecipe(id: "local", displayName: "Local", exePath: "C:\\Local\\app.exe")]
            ),
            RecipeManifest(
                id: "cached-local-installer",
                name: "Cached Local Installer",
                publisher: "Tools",
                category: "Utilities",
                compatibilityRating: .unknown,
                installer: InstallerSpec(mode: .localFile, fileName: "cached-local.exe"),
                bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
                engineRequirements: EngineRequirements(),
                launchers: [LauncherRecipe(id: "cached-local", displayName: "Cached Local", exePath: "C:\\CachedLocal\\app.exe")]
            ),
            RecipeManifest(
                id: "already-installed",
                name: "Already Installed",
                publisher: "Tools",
                category: "Utilities",
                compatibilityRating: .good,
                installer: InstallerSpec(mode: .alreadyInstalled, hints: [existing.path]),
                bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
                engineRequirements: EngineRequirements(),
                launchers: [LauncherRecipe(id: "existing", displayName: "Existing", exePath: "$existing")]
            ),
            RecipeManifest(
                id: "missing-existing",
                name: "Missing Existing",
                publisher: "Tools",
                category: "Utilities",
                compatibilityRating: .limited,
                installer: InstallerSpec(mode: .alreadyInstalled, hints: [root.appendingPathComponent("missing.exe").path]),
                bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
                engineRequirements: EngineRequirements(),
                launchers: [LauncherRecipe(id: "missing-existing", displayName: "Missing Existing", exePath: "$existing")]
            ),
            RecipeManifest(
                id: "local-probe",
                name: "Local Probe",
                publisher: "MacWin",
                category: "Diagnostics",
                compatibilityRating: .excellent,
                installer: InstallerSpec(mode: .none),
                bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
                engineRequirements: EngineRequirements(),
                launchers: [LauncherRecipe(id: "probe", displayName: "Probe", exePath: probe.path)]
            ),
            RecipeManifest(
                id: "missing-probe",
                name: "Missing Probe",
                publisher: "MacWin",
                category: "Diagnostics",
                compatibilityRating: .experimental,
                installer: InstallerSpec(mode: .none),
                bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
                engineRequirements: EngineRequirements(),
                launchers: [LauncherRecipe(id: "missing-probe", displayName: "Missing Probe", exePath: root.appendingPathComponent("missing-probe.exe").path)]
            ),
            RecipeManifest(
                id: "stale-flags",
                name: "Stale Flags",
                publisher: "Tools",
                category: "Utilities",
                compatibilityRating: .experimental,
                installer: InstallerSpec(mode: .none),
                bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
                engineRequirements: EngineRequirements(),
                launchers: [
                    LauncherRecipe(
                        id: "stale",
                        displayName: "Stale",
                        exePath: "C:\\Stale\\app.exe",
                        args: ["--disable-direct-write"],
                        envOverrides: ["MACWIN_CHROMIUM_HELPER_ARGS": "--disable-features=DWriteFontProxy,UseDWriteCore"]
                    )
                ]
            ),
            RecipeManifest(
                id: "disabled",
                name: "Disabled",
                publisher: "Tools",
                category: "Utilities",
                compatibilityRating: .experimental,
                disabledReason: "Known installer hang",
                installer: InstallerSpec(
                    mode: .download,
                    url: "https://example.test/disabled.exe",
                    fileName: "disabled.exe",
                    sha256: String(repeating: "c", count: 64)
                ),
                bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
                engineRequirements: EngineRequirements(),
                launchers: [LauncherRecipe(id: "disabled", displayName: "Disabled", exePath: "C:\\Disabled\\app.exe")]
            )
        ]

        let report = RecipeReadinessService(paths: paths).report(recipes: recipes, engines: [engine])

        #expect(report.recipeCount == 11)
        #expect(report.readyCount == 4)
        #expect(report.actionRequiredCount == 3)
        #expect(report.blockedCount == 3)
        #expect(report.disabledCount == 1)
        #expect(report.downloadRecipeCount == 4)
        #expect(report.localInstallerRecipeCount == 2)
        #expect(report.alreadyInstalledRecipeCount == 2)
        #expect(report.requiresWin32Count == 1)
        #expect(report.noCompatibleEngineCount == 1)
        #expect(report.missingSha256Count == 1)
        #expect(report.missingLauncherAssetCount == 1)
        #expect(report.obsoleteRenderingFlagRecipeCount == 1)
        #expect(report.entries.first { $0.recipeId == "ready-download" }?.state == .ready)
        #expect(report.entries.first { $0.recipeId == "already-installed" }?.existingInstallFound == true)
        #expect(report.entries.first { $0.recipeId == "local-installer" }?.issues == [.localInstallerRequired])
        #expect(report.entries.first { $0.recipeId == "cached-local-installer" }?.state == .ready)
        #expect(report.entries.first { $0.recipeId == "cached-local-installer" }?.issues == [])
        #expect(report.entries.first { $0.recipeId == "missing-existing" }?.issues == [.existingInstallMissing])
        #expect(report.entries.first { $0.recipeId == "steam32" }?.issues == [.noCompatibleEngine])
        #expect(report.entries.first { $0.recipeId == "missing-hash" }?.issues == [.missingSha256])
        #expect(report.entries.first { $0.recipeId == "missing-probe" }?.missingLauncherAssetPaths.count == 1)
        #expect(report.entries.first { $0.recipeId == "stale-flags" }?.obsoleteRenderingFlags == ["--disable-direct-write", "DWriteFontProxy", "UseDWriteCore"])
        #expect(report.entries.first { $0.recipeId == "disabled" }?.state == .disabled)
        #expect(report.issueCounts["obsoleteRenderingFlag"] == 1)
    }
}
