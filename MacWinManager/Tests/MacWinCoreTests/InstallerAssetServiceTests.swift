import Foundation
import Testing
@testable import MacWinCore

@Suite("Installer asset service")
struct InstallerAssetServiceTests {
    @Test("Installer asset report matches cached downloads hashes and architecture")
    func installerAssetReportMatchesCachedDownloadsHashesAndArchitecture() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinInstallerAssetTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()

        let x64Installer = paths.downloadsDirectory.appendingPathComponent("seven.exe")
        let x86Installer = paths.downloadsDirectory.appendingPathComponent("steam32.exe")
        let cachedLocalInstaller = paths.downloadsDirectory.appendingPathComponent("local-cache.exe")
        let orphan = paths.downloadsDirectory.appendingPathComponent("orphan.exe")
        try fakePE(machine: 0x8664).write(to: x64Installer)
        try fakePE(machine: 0x014c).write(to: x86Installer)
        try fakePE(machine: 0x8664).write(to: cachedLocalInstaller)
        try fakePE(machine: 0x014c).write(to: orphan)
        let x64Hash = try Hashing.sha256Hex(file: x64Installer)
        let cachedLocalHash = try Hashing.sha256Hex(file: cachedLocalInstaller)

        let recipes = [
            RecipeManifest(
                id: "seven",
                name: "Seven",
                publisher: "Tools",
                category: "Utilities",
                compatibilityRating: .excellent,
                installer: InstallerSpec(
                    mode: .download,
                    url: "https://example.test/seven.exe",
                    fileName: "seven.exe",
                    sha256: x64Hash
                ),
                bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
                engineRequirements: EngineRequirements(),
                launchers: []
            ),
            RecipeManifest(
                id: "steam",
                name: "Steam",
                publisher: "Valve",
                category: "Game Store",
                compatibilityRating: .experimental,
                installer: InstallerSpec(
                    mode: .download,
                    url: "https://example.test/steam32.exe",
                    fileName: "steam32.exe",
                    sha256: String(repeating: "0", count: 64)
                ),
                bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
                engineRequirements: EngineRequirements(requiresWin32: true),
                launchers: []
            ),
            RecipeManifest(
                id: "missing",
                name: "Missing",
                publisher: "Tools",
                category: "Utilities",
                compatibilityRating: .unknown,
                installer: InstallerSpec(
                    mode: .download,
                    url: "https://example.test/missing.exe",
                    fileName: "missing.exe",
                    sha256: String(repeating: "f", count: 64)
                ),
                bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
                engineRequirements: EngineRequirements(),
                launchers: []
            ),
            RecipeManifest(
                id: "local",
                name: "Local Only",
                publisher: "Tools",
                category: "Utilities",
                compatibilityRating: .unknown,
                installer: InstallerSpec(mode: .localFile),
                bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
                engineRequirements: EngineRequirements(),
                launchers: []
            ),
            RecipeManifest(
                id: "local-cached",
                name: "Local Cached",
                publisher: "Tools",
                category: "Utilities",
                compatibilityRating: .unknown,
                installer: InstallerSpec(mode: .localFile, fileName: "local-cache.exe", sha256: cachedLocalHash),
                bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
                engineRequirements: EngineRequirements(),
                launchers: []
            )
        ]

        let report = InstallerAssetService(paths: paths).report(recipes: recipes, includeHashes: true)

        #expect(report.recipeCount == 5)
        #expect(report.downloadableRecipeCount == 3)
        #expect(report.cachedRecipeCount == 3)
        #expect(report.missingDownloadCount == 1)
        #expect(report.hashMatchCount == 2)
        #expect(report.hashMismatchCount == 1)
        #expect(report.win32InstallerCount == 1)
        #expect(report.orphanedFileCount == 1)
        #expect(report.recipes.first { $0.recipeId == "seven" }?.hashStatus == .match)
        #expect(report.recipes.first { $0.recipeId == "seven" }?.architecture == .x86_64)
        #expect(report.recipes.first { $0.recipeId == "steam" }?.hashStatus == .mismatch)
        #expect(report.recipes.first { $0.recipeId == "steam" }?.architecture == .i386)
        #expect(report.recipes.first { $0.recipeId == "steam" }?.requiresWin32Installer == true)
        #expect(report.recipes.first { $0.recipeId == "missing" }?.hashStatus == .missing)
        #expect(report.recipes.first { $0.recipeId == "local" }?.hashStatus == .missing)
        #expect(report.recipes.first { $0.recipeId == "local-cached" }?.hashStatus == .match)
        #expect(report.recipes.first { $0.recipeId == "local-cached" }?.architecture == .x86_64)
        #expect(report.orphanedDownloads.first?.name == "orphan.exe")
        #expect(report.orphanedDownloads.first?.architecture == .i386)
        #expect(report.orphanedDownloads.first?.sha256 != nil)

        let csv = InstallerAssetService.csv(report: report)
        #expect(csv.contains("record_type,recipe_id,recipe_name,publisher,category,compatibility_rating,disabled,disabled_reason,installer_mode,file_name,cache_state,hash_status"))
        #expect(csv.contains("recipe,seven,Seven,Tools,Utilities,excellent,false,,download,seven.exe,cached,match,false,x86_64"))
        #expect(csv.contains("recipe,steam,Steam,Valve,Game Store,experimental,false,,download,steam32.exe,mismatch,mismatch,true,i386"))
        #expect(csv.contains("recipe,missing,Missing,Tools,Utilities,unknown,false,,download,missing.exe,missing,missing,false,"))
        #expect(csv.contains("recipe,local,Local Only,Tools,Utilities,unknown,false,,localFile,,notApplicable,missing,false,"))
        #expect(csv.contains("recipe,local-cached,Local Cached,Tools,Utilities,unknown,false,,localFile,local-cache.exe,cached,match,false,x86_64"))
        #expect(csv.contains("orphaned_download,,,,,,,,,orphan.exe,orphaned,"))
        #expect(csv.contains(",true,i386,"))

        let script = InstallerAssetService.shellScript(for: report)
        #expect(script.contains("READY seven.exe: cached file present"))
        #expect(script.contains("curl -L --fail --retry 3 --output"))
        #expect(script.contains("https://example.test/missing.exe"))
        #expect(script.contains("https://example.test/steam32.exe"))
        #expect(script.contains("shasum -a 256 -c -"))
        #expect(!script.contains("https://example.test/seven.exe"))

        let preparation = InstallerAssetService.preparationReport(for: report)
        #expect(preparation.actionCount == 4)
        #expect(preparation.criticalCount == 1)
        #expect(preparation.warningCount == 2)
        #expect(preparation.infoCount == 1)
        #expect(preparation.hashMismatchCount == 1)
        #expect(preparation.missingDownloadCount == 1)
        #expect(preparation.win32InstallerCount == 1)
        #expect(preparation.orphanedDownloadCount == 1)
        #expect(preparation.actions.map(\.kind) == [
            .redownloadHashMismatch,
            .downloadMissing,
            .reviewOrphanedDownload,
            .useWoW64Engine
        ])
        #expect(preparation.actions.first?.recipeId == "steam")
        #expect(preparation.actions.first?.severity == .critical)

        let preparationCSV = InstallerAssetService.preparationCSV(report: preparation)
        #expect(preparationCSV.contains("severity,kind,recipe_id,recipe_name,file_name,detail,source_url,cached_path"))
        #expect(preparationCSV.contains("critical,redownloadHashMismatch,steam,Steam,steam32.exe"))
        #expect(preparationCSV.contains("warning,downloadMissing,missing,Missing,missing.exe"))
        #expect(preparationCSV.contains("warning,reviewOrphanedDownload,,,orphan.exe"))
        #expect(preparationCSV.contains("info,useWoW64Engine,steam,Steam,steam32.exe"))
        let preparationMarkdown = InstallerAssetService.preparationMarkdown(report: preparation)
        #expect(preparationMarkdown.contains("# MacWin Installer Preparation"))
        #expect(preparationMarkdown.contains("- Actions: 4"))
        #expect(preparationMarkdown.contains("- Hash mismatches: 1"))
        #expect(preparationMarkdown.contains("### steam32.exe"))
        #expect(preparationMarkdown.contains("- Kind: `redownloadHashMismatch`"))
        #expect(preparationMarkdown.contains("- Recipe: `steam`"))
        #expect(preparationMarkdown.contains("Cached installer hash does not match the signed recipe"))
        #expect(preparationMarkdown.contains("### missing.exe"))
        #expect(preparationMarkdown.contains("- Kind: `downloadMissing`"))
        #expect(preparationMarkdown.contains("### orphan.exe"))
    }

    @Test("Installer asset report is empty when downloads directory is absent")
    func installerAssetReportIsEmptyWhenDownloadsDirectoryIsAbsent() {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinInstallerAssetEmptyTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let report = InstallerAssetService(paths: MacWinPaths(root: root)).report(recipes: [])

        #expect(report.recipeCount == 0)
        #expect(report.cachedRecipeCount == 0)
        #expect(report.orphanedDownloads.isEmpty)
    }

    @Test("Download cache writes verified installer and keeps old file on hash mismatch")
    func downloadCacheWritesVerifiedInstallerAndKeepsOldFileOnHashMismatch() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinInstallerDownloadTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root.appendingPathComponent("app-support", isDirectory: true))
        try paths.ensureBaseDirectories()
        let source = root.appendingPathComponent("source.exe")
        try Data("verified installer".utf8).write(to: source)
        let hash = try Hashing.sha256Hex(file: source)
        let recipe = RecipeManifest(
            id: "verified",
            name: "Verified",
            publisher: "Tools",
            category: "Utilities",
            compatibilityRating: .good,
            installer: InstallerSpec(
                mode: .download,
                url: source.absoluteString,
                fileName: "verified.exe",
                sha256: hash
            ),
            bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
            engineRequirements: EngineRequirements(),
            launchers: []
        )

        let service = InstallerAssetService(paths: paths)
        let result = try service.cacheInstaller(for: recipe)
        let cached = paths.downloadsDirectory.appendingPathComponent("verified.exe")

        #expect(result.recipeId == "verified")
        #expect(result.usedCachedFile == false)
        #expect(result.hashStatus == .match)
        #expect(result.destinationPath == cached.path)
        #expect(try String(contentsOf: cached, encoding: .utf8) == "verified installer")

        let cachedResult = try service.cacheInstaller(for: recipe)
        #expect(cachedResult.usedCachedFile == true)
        #expect(cachedResult.actualSha256 == hash)

        try Data("old cached file".utf8).write(to: cached)
        try Data("bad replacement".utf8).write(to: source)
        let badRecipe = RecipeManifest(
            id: "verified",
            name: "Verified",
            publisher: "Tools",
            category: "Utilities",
            compatibilityRating: .good,
            installer: InstallerSpec(
                mode: .download,
                url: source.absoluteString,
                fileName: "verified.exe",
                sha256: hash
            ),
            bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
            engineRequirements: EngineRequirements(),
            launchers: []
        )

        do {
            _ = try service.cacheInstaller(for: badRecipe)
            Issue.record("Expected hash mismatch")
        } catch let error as MacWinError {
            guard case .catalogHashMismatch(let recipeId, let expected, _) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
            #expect(recipeId == "verified")
            #expect(expected == hash)
        }
        #expect(try String(contentsOf: cached, encoding: .utf8) == "old cached file")

        let history = InstallerDownloadHistoryService(paths: paths).report()
        #expect(history.totalRecordCount == 3)
        #expect(history.downloadedCount == 1)
        #expect(history.cachedCount == 1)
        #expect(history.hashMismatchCount == 1)
        #expect(history.failedCount == 0)
        #expect(history.records.contains { $0.recipeId == "verified" && $0.state == .downloaded && $0.usedCachedFile == false })
        #expect(history.records.contains { $0.recipeId == "verified" && $0.state == .cached && $0.usedCachedFile == true })
        let mismatch = try #require(history.records.first { $0.state == .hashMismatch })
        #expect(mismatch.expectedSha256 == hash)
        #expect(mismatch.actualSha256 != hash)
        #expect(mismatch.destinationPath == cached.path)

        let csv = InstallerDownloadHistoryService.csv(report: history)
        #expect(csv.contains("id,recipe_id,recipe_name,file_name,state,used_cached_file,started_at,ended_at,duration_ms,byte_count"))
        #expect(csv.contains(",verified,Verified,verified.exe,downloaded,false,"))
        #expect(csv.contains(",verified,Verified,verified.exe,cached,true,"))
        #expect(csv.contains(",verified,Verified,verified.exe,hashMismatch,false,"))
        #expect(csv.contains(hash))
        #expect(csv.contains("Downloaded installer SHA-256 does not match recipe"))
    }

    private func fakePE(machine: UInt16) -> Data {
        var data = Data(repeating: 0, count: 160)
        data[0] = 0x4d
        data[1] = 0x5a
        data[0x3c] = 0x80
        data[0x80] = 0x50
        data[0x81] = 0x45
        data[0x82] = 0
        data[0x83] = 0
        data[0x84] = UInt8(machine & 0x00ff)
        data[0x85] = UInt8(machine >> 8)
        return data
    }
}
