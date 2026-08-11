import CryptoKit
import Foundation
import Testing
@testable import MacWinCore

@Suite("Catalog service")
struct CatalogServiceTests {
    @Test("Signed catalog loads recipes")
    func signedCatalogLoads() throws {
        let fixture = try CatalogFixture()
        let service = CatalogService(
            source: CatalogSource(root: fixture.root),
            trustedPublicKeys: ["test": fixture.publicKey]
        )

        let snapshot = try service.refresh(now: fixture.now)

        #expect(snapshot.recipes.count == 1)
        #expect(snapshot.recipes[0].id == "probe")
        #expect(snapshot.isExpired == false)
    }

    @Test("Hash mismatch rejects recipe")
    func hashMismatchRejects() throws {
        let fixture = try CatalogFixture()
        try Data("tampered".utf8).write(to: fixture.recipeURL)
        let service = CatalogService(
            source: CatalogSource(root: fixture.root),
            trustedPublicKeys: ["test": fixture.publicKey]
        )

        #expect(throws: MacWinError.catalogHashMismatch(recipeId: "probe", expected: fixture.recipeHash, actual: Hashing.sha256Hex(data: Data("tampered".utf8)))) {
            _ = try service.refresh(now: fixture.now)
        }
    }

    @Test("Bundled signed catalog exposes local capability tests")
    func bundledSignedCatalogExposesLocalCapabilityTests() throws {
        let testFile = URL(fileURLWithPath: #filePath)
        let packageRoot = testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let catalogRoot = packageRoot
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("MacWinManagerApp", isDirectory: true)
            .appendingPathComponent("Resources", isDirectory: true)
            .appendingPathComponent("Catalog", isDirectory: true)
        let keyData = try #require(Data(base64Encoded: CatalogTrust.developmentPublicKeyBase64))
        let publicKey = try P256.Signing.PublicKey(rawRepresentation: keyData)
        let indexData = try Data(contentsOf: catalogRoot.appendingPathComponent("catalog.index.json"))
        let signatureData = try Data(contentsOf: catalogRoot.appendingPathComponent("catalog.signature.json"))
        let signature = try JSONStore().decoder.decode(CatalogSignature.self, from: signatureData)
        let derSignatureData = try #require(Data(base64Encoded: signature.signatureBase64))
        let ecdsaSignature = try P256.Signing.ECDSASignature(derRepresentation: derSignatureData)
        #expect(publicKey.isValidSignature(ecdsaSignature, for: indexData))
        let service = CatalogService(
            source: CatalogSource(root: catalogRoot),
            trustedPublicKeys: [CatalogTrust.developmentKeyId: publicKey]
        )

        let snapshot = try service.refresh(now: Date(timeIntervalSince1970: 1_786_176_000))
        let coreTests = try #require(snapshot.recipes.first { $0.id == "macwin-core-capability-tests" })
        let sumatraPDF = try #require(snapshot.recipes.first { $0.id == "sumatrapdf" })
        let texstudio = try #require(snapshot.recipes.first { $0.id == "texstudio" })
        let sqliteStudio = try #require(snapshot.recipes.first { $0.id == "sqlitestudio" })
        let libreOffice = try #require(snapshot.recipes.first { $0.id == "libreoffice" })
        let firefox = try #require(snapshot.recipes.first { $0.id == "firefox" })
        let lenovo = try #require(snapshot.recipes.first { $0.id == "lenovo-app-store" })
        let jasp = try #require(snapshot.recipes.first { $0.id == "jasp-stats" })
        let portableApps = try #require(snapshot.recipes.first { $0.id == "portableapps-platform" })

        #expect(snapshot.recipes.count >= 16)
        #expect(coreTests.engineRequirements.requiresWin32)
        #expect(coreTests.launchers.count == 12)
        #expect(coreTests.launchers.contains { $0.id == "tls-winhttp-probe-win32" })
        #expect(coreTests.launchers.contains { $0.id == "d3d11-shader-loop-probe" })
        #expect(sumatraPDF.category == "Documents")
        #expect(sumatraPDF.compatibilityRating == .good)
        #expect(sumatraPDF.installer.fileName == "SumatraPDF-3.6.1-64-install.exe")
        #expect(sumatraPDF.installer.sha256 == "1eee71cccd2ea6e94d5bcea54ee2f759844da3e1a0ee2f6045035b1d17b94381")
        #expect(sumatraPDF.launchers.first?.exePath == "C:\\Program Files\\SumatraPDF\\SumatraPDF.exe")
        #expect(texstudio.category == "Developer Tools")
        #expect(texstudio.compatibilityRating == .experimental)
        #expect(texstudio.installer.fileName == "Texstudio-4.9.5-win-qt6-signed.exe")
        #expect(texstudio.installer.arguments == ["/S"])
        #expect(texstudio.installer.sha256 == "618c633e1ad6d9aba90ff8c4498d265b2cbfb6d02173d4577ca8ba3c989cc1e4")
        #expect(texstudio.launchers.first?.exePath == "C:\\Program Files\\TeXstudio\\texstudio.exe")
        #expect(sqliteStudio.category == "Developer Tools")
        #expect(sqliteStudio.compatibilityRating == .good)
        #expect(sqliteStudio.installer.fileName == "SQLiteStudio-3.4.17-windows-x64-installer.exe")
        #expect(sqliteStudio.installer.arguments == ["--mode", "unattended", "--unattendedmodeui", "none", "--installer-language", "zh_CN", "--install_for", "all"])
        #expect(sqliteStudio.installer.sha256 == "5018ea571c2a3416944267d387cb75eea99d46ebd010f6aa5c35df1f7690c894")
        #expect(sqliteStudio.launchers.first?.exePath == "C:\\Program Files\\SQLiteStudio\\SQLiteStudio.exe")
        #expect(libreOffice.category == "Office Suite")
        #expect(libreOffice.compatibilityRating == .experimental)
        #expect(libreOffice.installer.command == "msiexec")
        #expect(libreOffice.installer.fileName == "LibreOffice_26.2.4_Win_x86-64.msi")
        #expect(libreOffice.installer.arguments == ["/i", "$installer", "/qn", "/norestart", "REGISTER_ALL_MSO_TYPES=0", "CREATEDESKTOPLINK=0"])
        #expect(libreOffice.installer.sha256 == "202f26cda071c5aa4996a5a28412fddceb3891dceb0366982c62650456c0730f")
        #expect(libreOffice.launchers.map(\.id) == ["libreoffice-writer", "libreoffice-calc", "libreoffice-impress"])
        #expect(firefox.category == "Browser")
        #expect(firefox.compatibilityRating == .experimental)
        #expect(firefox.installer.command == "msiexec")
        #expect(firefox.installer.fileName == "Firefox_Setup_152.0.1.msi")
        #expect(firefox.installer.arguments == ["/i", "$installer", "/qn", "/norestart"])
        #expect(firefox.installer.sha256 == "58a6d4a491fd9b9e54205c7f684ff808741a4ac9c4a866e5a562e7ad8e89a5b0")
        #expect(firefox.launchers.first?.exePath == "C:\\Program Files\\Mozilla Firefox\\firefox.exe")
        #expect(lenovo.category == "App Store")
        #expect(lenovo.compatibilityRating == .experimental)
        #expect(lenovo.installer.mode == .localFile)
        #expect(lenovo.installer.fileName == "LenovoAppStoreInstall.exe")
        #expect(lenovo.installer.arguments == ["/S"])
        #expect(lenovo.installer.sha256 == "4fd4b101cd0a52083b55f0d58dd8406a40331c1d7196d3f13e9f350cce5b87e9")
        #expect(lenovo.launchers.first?.exePath == "C:\\Program Files (x86)\\Lenovo\\LeAppStore\\LenovoAppStore.exe")
        #expect(jasp.category == "Scientific / Industrial")
        #expect(jasp.compatibilityRating == .good)
        #expect(jasp.installer.mode == .localFile)
        #expect(jasp.installer.command == "msiexec")
        #expect(jasp.installer.fileName == "JASP-0.97.1-Windows-Community.msi")
        #expect(jasp.installer.arguments == ["/i", "$installer", "/qn", "/norestart"])
        #expect(jasp.installer.sha256 == "360410ff1cbf63dea1821f6df5c6b883c65e3a9ccc9aed3324fbb2aa4cf71e93")
        #expect(jasp.env["MACWIN_JASP_WEBENGINE_MODE"] == "multiprocess")
        #expect(jasp.launchers.first?.exePath == "C:\\Program Files\\JASP\\JASPDesktop.exe")
        #expect(portableApps.category == "App Store")
        #expect(portableApps.compatibilityRating == .experimental)
        #expect(portableApps.installer.mode == .localFile)
        #expect(portableApps.installer.fileName == "PortableApps.com_Platform_Setup_30.4.1.paf.exe")
        #expect(portableApps.installer.command == "macwin-extract-archive")
        #expect(portableApps.installer.arguments == ["$drive_c"])
        #expect(portableApps.installer.sha256 == "f7ad3bb79472222a807b054cb7092c1cefcd3bdcd86d35a51244723c8df54562")
        #expect(portableApps.engineRequirements.requiresWin32)
        #expect(portableApps.launchers.first?.exePath == "C:\\PortableApps\\PortableApps.com\\PortableAppsPlatform.exe")
        let localProbeRootExists = FileManager.default.fileExists(atPath: TestAssetService.defaultRootPath)
        for launcher in coreTests.launchers {
            #expect(launcher.exePath.hasPrefix(TestAssetService.defaultRootPath + "/"))
            if localProbeRootExists {
                #expect(FileManager.default.fileExists(atPath: launcher.exePath))
            }
        }
    }

    @Test("Verified catalog syncs into app support cache for offline diagnostics")
    func verifiedCatalogSyncsIntoAppSupportCacheForOfflineDiagnostics() throws {
        let fixture = try CatalogFixture()
        let appSupport = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinCatalogCacheTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: appSupport) }
        let paths = MacWinPaths(root: appSupport)
        let source = CatalogSource(root: fixture.root)
        let service = CatalogService(source: source, trustedPublicKeys: ["test": fixture.publicKey])
        let snapshot = try service.refresh(now: fixture.now)

        let manifest = try CatalogCacheService(paths: paths).syncVerifiedCatalog(
            from: source,
            snapshot: snapshot,
            cachedAt: Date(timeIntervalSince1970: 123)
        )

        #expect(manifest.cachePath == paths.catalogDirectory.path)
        #expect(manifest.recipeCount == 1)
        #expect(manifest.recipeIds == ["probe"])
        #expect(manifest.recipeSha256ById["probe"] == fixture.recipeHash)
        #expect(FileManager.default.fileExists(atPath: paths.catalogDirectory.appendingPathComponent("catalog.index.json").path))
        #expect(FileManager.default.fileExists(atPath: paths.catalogDirectory.appendingPathComponent("catalog.signature.json").path))
        #expect(FileManager.default.fileExists(atPath: paths.catalogDirectory.appendingPathComponent("recipes/probe.json").path))
        #expect(FileManager.default.fileExists(atPath: paths.catalogDirectory.appendingPathComponent("catalog-cache.json").path))

        let cachedManifest = try JSONStore().load(
            CatalogCacheManifest.self,
            from: paths.catalogDirectory.appendingPathComponent("catalog-cache.json")
        )
        #expect(cachedManifest == manifest)

        let cachedSnapshot = try CatalogService(
            source: CatalogSource(root: paths.catalogDirectory),
            trustedPublicKeys: ["test": fixture.publicKey]
        ).refresh(now: fixture.now)
        #expect(cachedSnapshot.recipes.map(\.id) == ["probe"])
        #expect(cachedSnapshot.isExpired == false)
    }
}

private struct CatalogFixture {
    let root: URL
    let recipeURL: URL
    let recipeHash: String
    let publicKey: P256.Signing.PublicKey
    let now = Date(timeIntervalSince1970: 1_786_176_000)

    init() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinCatalogTests-\(UUID().uuidString)", isDirectory: true)
        let recipes = root.appendingPathComponent("recipes", isDirectory: true)
        try FileManager.default.createDirectory(at: recipes, withIntermediateDirectories: true)
        recipeURL = recipes.appendingPathComponent("probe.json")

        let store = JSONStore()
        let recipe = RecipeManifest(
            id: "probe",
            name: "Probe",
            publisher: "MacWin",
            category: "Diagnostics",
            compatibilityRating: .excellent,
            installer: InstallerSpec(mode: .none),
            bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
            engineRequirements: EngineRequirements(),
            launchers: [
                LauncherRecipe(id: "probe", displayName: "Probe", exePath: "/tmp/probe.exe")
            ]
        )
        try store.encoder.encode(recipe).write(to: recipeURL)
        recipeHash = try Hashing.sha256Hex(file: recipeURL)

        let index = CatalogIndex(
            generatedAt: now,
            expiresAt: now.addingTimeInterval(86400),
            recipes: [CatalogRecipeRef(id: "probe", name: "Probe", file: "recipes/probe.json", sha256: recipeHash)]
        )
        let indexData = try store.encoder.encode(index)
        try indexData.write(to: root.appendingPathComponent("catalog.index.json"))

        let privateKey = P256.Signing.PrivateKey()
        publicKey = privateKey.publicKey
        let signature = try privateKey.signature(for: indexData)
        let signatureManifest = CatalogSignature(
            algorithm: "p256-sha256-der",
            keyId: "test",
            signatureBase64: signature.derRepresentation.base64EncodedString()
        )
        try store.encoder.encode(signatureManifest).write(to: root.appendingPathComponent("catalog.signature.json"))
    }
}
