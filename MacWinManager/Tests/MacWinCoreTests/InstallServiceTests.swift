import Foundation
import Testing
@testable import MacWinCore

@Suite("Install service")
struct InstallServiceTests {
    @Test("Wine installer placeholders use Z drive paths while managed extractors keep host paths")
    func installerPlaceholderPathsMatchExecutionEnvironment() {
        let root = URL(fileURLWithPath: "/tmp/MacWin Installer Tests", isDirectory: true)
        let paths = MacWinPaths(root: root)
        let service = InstallService(paths: paths)
        let bottle = BottleManifest(
            id: "engineering",
            name: "Engineering",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "wine"
        )
        let installer = URL(fileURLWithPath: "/tmp/Installers/LTspice64.msi")
        let placeholders = [
            "$installer",
            "$drive_c/Program Files/ADI/LTspice",
            "$bottle",
            "$downloads"
        ]

        let wineArguments = service.installerArguments(
            placeholders,
            installerURL: installer,
            bottle: bottle,
            wineAccessiblePaths: true
        )
        let hostArguments = service.installerArguments(
            placeholders,
            installerURL: installer,
            bottle: bottle,
            wineAccessiblePaths: false
        )

        #expect(wineArguments[0] == "Z:\\tmp\\Installers\\LTspice64.msi")
        #expect(wineArguments[1].hasPrefix(
            "Z:\\tmp\\MacWin Installer Tests\\Bottles\\engineering\\drive_c\\Program Files\\ADI\\LTspice"
        ))
        #expect(wineArguments[2].hasPrefix("Z:\\tmp\\MacWin Installer Tests\\Bottles\\engineering"))
        #expect(wineArguments[3].hasPrefix("Z:\\tmp\\MacWin Installer Tests\\Downloads"))
        #expect(hostArguments == [
            "/tmp/Installers/LTspice64.msi",
            "/tmp/MacWin Installer Tests/Bottles/engineering/drive_c/Program Files/ADI/LTspice",
            "/tmp/MacWin Installer Tests/Bottles/engineering",
            "/tmp/MacWin Installer Tests/Downloads"
        ])
    }

    @Test("Already installed recipe creates launcher")
    func alreadyInstalledCreatesLauncher() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinInstallTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()

        let existingExe = root.appendingPathComponent("Program Files/米/HYP.exe")
        try FileManager.default.createDirectory(at: existingExe.deletingLastPathComponent(), withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: existingExe.path, contents: Data())

        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/wine",
            wineserverPath: "/wineserver",
            runtimePath: "/runtime",
            defaultEnv: [:]
        )
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        try JSONStore().save(bottle, to: paths.bottleManifestURL(id: bottle.id))
        let recipe = RecipeManifest(
            id: "hoyoplay",
            name: "HoYoPlay",
            publisher: "miHoYo",
            category: "Game Launcher",
            compatibilityRating: .experimental,
            installer: InstallerSpec(mode: .alreadyInstalled, hints: [existingExe.path]),
            bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
            engineRequirements: EngineRequirements(),
            env: ["WINE_D3D_CONFIG": "renderer=vulkan,csmt=0x0"],
            launchers: [LauncherRecipe(id: "hoyoplay", displayName: "HoYoPlay", exePath: "$existing")]
        )

        let task = try InstallService(paths: paths).install(
            recipe: recipe,
            bottle: bottle,
            engine: engine,
            installerSource: .existingInstallation
        )
        let updated = try BottleService(paths: paths).bottle(id: bottle.id)

        #expect(task.state == .succeeded)
        #expect(updated?.installedApps.first?.exePath == existingExe.path)
        #expect(updated?.installedApps.first?.envOverrides["WINE_D3D_CONFIG"] == "renderer=gl,csmt=0x0")
        #expect(updated?.installedApps.first?.envOverrides["MACWIN_COMPAT_PROFILE"] == "hoyoplay-webview")
        #expect(updated?.installedApps.first?.envOverrides["MACWIN_HOYOPLAY_TEXT_REPAIR"] == "1")
        #expect(updated?.installedApps.first?.envOverrides["MACWIN_TEXT_RENDERING_REPAIR"] == "1")
        #expect(updated?.installedApps.first?.envOverrides["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--use-gl=angle") == true)
        #expect(updated?.installedApps.first?.envOverrides["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--use-angle=swiftshader") == true)
        #expect(updated?.installedApps.first?.envOverrides["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--disable-direct-write") == false)
        #expect(updated?.installedApps.first?.envOverrides["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--disable-remote-fonts") == false)
        #expect(updated?.installedApps.first?.envOverrides["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("--enable-features=FontSrcLocalMatching") == true)
        #expect(updated?.installedApps.first?.envOverrides["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("DWriteFontProxy") == false)
        #expect(updated?.installedApps.first?.envOverrides["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("UseDWriteCore") == false)
        #expect(updated?.installedApps.first?.envOverrides["QTWEBENGINE_CHROMIUM_FLAGS"]?.contains("UseSkiaRenderer") == false)

        let history = InstallHistoryService(paths: paths).report()
        let record = try #require(history.tasks.first)
        #expect(history.succeededCount == 1)
        #expect(record.recipeId == "hoyoplay")
        #expect(record.bottleId == bottle.id)
        #expect(record.state == .succeeded)
        #expect(record.exitCode == 0)
        #expect(record.endedAt != nil)
        #expect(record.logPath == task.logPath)
    }

    @Test("Known launcher profiles are applied during install")
    func knownLauncherProfilesAreAppliedDuringInstall() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinProfileInstallTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()

        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/wine",
            wineserverPath: "/wineserver",
            runtimePath: "/runtime",
            defaultEnv: [:]
        )
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        try JSONStore().save(bottle, to: paths.bottleManifestURL(id: bottle.id))
        let recipe = RecipeManifest(
            id: "steam",
            name: "Steam",
            publisher: "Valve",
            category: "Game Store",
            compatibilityRating: .experimental,
            installer: InstallerSpec(mode: .none),
            bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
            engineRequirements: EngineRequirements(),
            env: [
                "CUSTOM_RECIPE_ENV": "1",
                "MACWIN_STEAMWEBHELPER_ARGS": "--old-helper-args"
            ],
            launchers: [
                LauncherRecipe(
                    id: "steam",
                    displayName: "Steam",
                    exePath: "C:\\Program Files\\Steam\\Steam.exe",
                    args: ["-no-cef-sandbox"],
                    envOverrides: ["MACWIN_CHROMIUM_HELPER_ARGS": "--old-chromium-helper-args"]
                )
            ]
        )

        _ = try InstallService(paths: paths).install(
            recipe: recipe,
            bottle: bottle,
            engine: engine,
            installerSource: nil
        )
        let updatedBottle = try BottleService(paths: paths).bottle(id: bottle.id)
        let updated = try #require(updatedBottle)
        let launcher = try #require(updated.installedApps.first)

        #expect(launcher.args == BottleService.steamLauncherArguments)
        #expect(launcher.envOverrides["MACWIN_COMPAT_PROFILE"] == "steam-client")
        #expect(launcher.envOverrides["MACWIN_FORCE_MOUSE_FOCUS"] == "1")
        #expect(launcher.envOverrides["MACWIN_STEAMWEBHELPER_ARGS"] == BottleService.steamWebHelperArguments)
        #expect(launcher.envOverrides["MACWIN_CHROMIUM_HELPER_ARGS"] == ApplicationCompatibilityProfile.chromiumHelperArguments)
        #expect(launcher.envOverrides["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("DWriteFontProxy") == false)
        #expect(launcher.envOverrides["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("UseDWriteCore") == false)
        #expect(launcher.envOverrides["MACWIN_CHROMIUM_HELPER_ARGS"]?.contains("UseSkiaRenderer") == false)
        #expect(launcher.envOverrides["CUSTOM_RECIPE_ENV"] == "1")
    }

    @Test("Duplicate recipe installation is recorded but does not rerun the installer")
    func duplicateInstallIsSkipped() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinDuplicateInstallTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()

        let launcher = LauncherManifest(
            id: "steam",
            appId: "steam",
            bottleId: "bottle",
            displayName: "Steam",
            exePath: "C:\\Program Files\\Steam\\Steam.exe"
        )
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine",
            installedApps: [launcher]
        )
        try JSONStore().save(bottle, to: paths.bottleManifestURL(id: bottle.id))
        let recipe = RecipeManifest(
            id: "steam",
            name: "Steam",
            publisher: "Valve",
            category: "Game Store",
            compatibilityRating: .experimental,
            installer: InstallerSpec(mode: .download, command: "/bin/false"),
            bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
            engineRequirements: EngineRequirements(),
            launchers: [LauncherRecipe(id: "steam", displayName: "Steam", exePath: launcher.exePath)]
        )
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/bin/false",
            wineserverPath: "/bin/false",
            runtimePath: "/runtime",
            defaultEnv: [:]
        )

        let task = try InstallService(paths: paths).install(
            recipe: recipe,
            bottle: bottle,
            engine: engine,
            installerSource: nil
        )
        #expect(task.state == .succeeded)
        #expect(task.progressText == "Already installed Steam")
        #expect(task.exitCode == 0)
        let updatedBottle = try BottleService(paths: paths).bottle(id: bottle.id)
        let updated = try #require(updatedBottle)
        #expect(updated.installedApps == [launcher])
        let log = try String(contentsOfFile: task.logPath, encoding: .utf8)
        #expect(log.contains("duplicateInstall=skipped"))
    }

    @Test("Installer failure restores bottle manifest and records rollback")
    func failedInstallRestoresManifest() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRollbackInstallTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()
        let installer = root.appendingPathComponent("failed-installer.exe")
        try Data("installer".utf8).write(to: installer)

        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )
        try JSONStore().save(bottle, to: paths.bottleManifestURL(id: bottle.id))
        let recipe = RecipeManifest(
            id: "failed",
            name: "Failed",
            publisher: "MacWin",
            category: "Test",
            compatibilityRating: .limited,
            installer: InstallerSpec(
                mode: .localFile,
                fileName: installer.lastPathComponent,
                command: "/bin/false"
            ),
            bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
            engineRequirements: EngineRequirements(),
            launchers: [LauncherRecipe(id: "failed", displayName: "Failed", exePath: "C:\\Failed\\failed.exe")]
        )
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/bin/false",
            wineserverPath: "/bin/false",
            runtimePath: "/runtime",
            defaultEnv: [:]
        )

        let task = try InstallService(paths: paths).install(
            recipe: recipe,
            bottle: bottle,
            engine: engine,
            installerSource: .localFile(installer)
        )
        #expect(task.state == .failed)
        #expect(task.progressText.contains("rollback"))
        let updatedBottle = try BottleService(paths: paths).bottle(id: bottle.id)
        let updated = try #require(updatedBottle)
        #expect(updated.id == bottle.id)
        #expect(updated.engineId == bottle.engineId)
        #expect(updated.installedApps.isEmpty)
        let log = try String(contentsOfFile: task.logPath, encoding: .utf8)
        #expect(log.contains("rollback=best-effort"))
        #expect(log.contains("rollbackManifestRestored=true"))
    }

    @Test("Nonzero installer exit is accepted when launcher targets already exist")
    func nonzeroInstallerExitIsAcceptedWhenLauncherTargetsAlreadyExist() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinInstallExistingTargetsTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()

        let installer = root.appendingPathComponent("fake-installer.msi")
        try Data("fake installer".utf8).write(to: installer)
        let hash = try Hashing.sha256Hex(file: installer)

        let bottle = BottleManifest(id: "bottle", name: "Bottle", windowsVersion: "win11", arch: .win64, engineId: "engine")
        try JSONStore().save(bottle, to: paths.bottleManifestURL(id: bottle.id))
        let launcherURL = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("Program Files/Fake/fake.exe")
        try FileManager.default.createDirectory(at: launcherURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("already installed".utf8).write(to: launcherURL)

        let recipe = RecipeManifest(
            id: "fake-existing",
            name: "Fake Existing",
            publisher: "MacWin",
            category: "Test",
            compatibilityRating: .good,
            installer: InstallerSpec(
                mode: .download,
                url: installer.absoluteString,
                fileName: "fake-installer.msi",
                sha256: hash,
                command: "/bin/false",
                arguments: []
            ),
            bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
            engineRequirements: EngineRequirements(),
            launchers: [LauncherRecipe(id: "fake", displayName: "Fake", exePath: "C:\\Program Files\\Fake\\fake.exe")]
        )
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/bin/false",
            wineserverPath: "/bin/false",
            runtimePath: "/runtime",
            defaultEnv: [:]
        )

        let task = try InstallService(paths: paths).install(recipe: recipe, bottle: bottle, engine: engine, installerSource: nil)
        let updatedBottle = try BottleService(paths: paths).bottle(id: bottle.id)
        let updated = try #require(updatedBottle)
        let log = try String(contentsOfFile: task.logPath, encoding: .utf8)

        #expect(task.state == .succeeded)
        #expect(task.exitCode == 1)
        #expect(task.progressText == "Installed Fake Existing")
        #expect(updated.installedApps.contains { $0.exePath == "C:\\Program Files\\Fake\\fake.exe" })
        #expect(log.contains("installerOutcome=existingInstallAccepted"))
        #expect(log.contains("PASS existing install accepted after installer exitCode=1"))
    }

    @Test("Download installer is cached and hash checked")
    func downloadInstallerIsCached() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinDownloadInstallTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()

        let source = root.appendingPathComponent("source-installer.exe")
        try Data("fake installer".utf8).write(to: source)
        let hash = try Hashing.sha256Hex(file: source)

        let recipe = RecipeManifest(
            id: "fake",
            name: "Fake",
            publisher: "MacWin",
            category: "Test",
            compatibilityRating: .excellent,
            installer: InstallerSpec(
                mode: .download,
                url: source.absoluteString,
                fileName: "fake-installer.exe",
                sha256: hash,
                arguments: ["/S"]
            ),
            bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
            engineRequirements: EngineRequirements(),
            launchers: [LauncherRecipe(id: "fake", displayName: "Fake", exePath: "C:\\Fake\\fake.exe")]
        )
        let bottle = BottleManifest(id: "bottle", name: "Bottle", windowsVersion: "win11", arch: .win64, engineId: "engine")
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/bin/false",
            wineserverPath: "/bin/false",
            runtimePath: "/runtime",
            defaultEnv: [:]
        )
        try JSONStore().save(bottle, to: paths.bottleManifestURL(id: bottle.id))
        try FileManager.default.createDirectory(at: paths.bottleDriveCURL(id: bottle.id), withIntermediateDirectories: true)

        let task = try InstallService(paths: paths).install(recipe: recipe, bottle: bottle, engine: engine, installerSource: nil)

        #expect(task.state == .failed)
        #expect(task.exitCode == 1)
        #expect(FileManager.default.fileExists(atPath: paths.downloadsDirectory.appendingPathComponent("fake-installer.exe").path))
        #expect(try Hashing.sha256Hex(file: paths.downloadsDirectory.appendingPathComponent("fake-installer.exe")) == hash)
        let history = InstallHistoryService(paths: paths).report()
        #expect(history.failedCount == 1)
        #expect(history.tasks.first?.recipeId == "fake")
        #expect(history.tasks.first?.exitCode == 1)
    }

    @Test("Local installer can be resolved from Downloads cache")
    func localInstallerCanBeResolvedFromDownloadsCache() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinLocalCacheInstallTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()

        let installer = paths.downloadsDirectory.appendingPathComponent("cached-local.exe")
        try Data("cached local installer".utf8).write(to: installer)
        let hash = try Hashing.sha256Hex(file: installer)

        let recipe = RecipeManifest(
            id: "cached-local",
            name: "Cached Local",
            publisher: "MacWin",
            category: "Test",
            compatibilityRating: .experimental,
            installer: InstallerSpec(
                mode: .localFile,
                fileName: "cached-local.exe",
                sha256: hash,
                arguments: ["/S"]
            ),
            bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
            engineRequirements: EngineRequirements(),
            launchers: [LauncherRecipe(id: "cached-local", displayName: "Cached Local", exePath: "C:\\CachedLocal\\app.exe")]
        )
        let bottle = BottleManifest(id: "bottle", name: "Bottle", windowsVersion: "win11", arch: .win64, engineId: "engine")
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/bin/false",
            wineserverPath: "/bin/false",
            runtimePath: "/runtime",
            defaultEnv: [:]
        )
        try JSONStore().save(bottle, to: paths.bottleManifestURL(id: bottle.id))
        try FileManager.default.createDirectory(at: paths.bottleDriveCURL(id: bottle.id), withIntermediateDirectories: true)

        let task = try InstallService(paths: paths).install(
            recipe: recipe,
            bottle: bottle,
            engine: engine,
            installerSource: nil
        )

        #expect(task.state == .failed)
        #expect(task.exitCode == 1)
        let log = try String(contentsOfFile: task.logPath, encoding: .utf8)
        #expect(log.contains("exe=\(installer.path)"))
        #expect(log.contains("/S"))
    }

    @Test("Managed archive installer extracts into bottle drive")
    func managedArchiveInstallerExtractsIntoBottleDrive() throws {
        let fileManager = FileManager.default
        guard fileManager.isExecutableFile(atPath: "/opt/homebrew/bin/7zz"),
              fileManager.isExecutableFile(atPath: "/usr/bin/zip") else {
            return
        }

        let root = fileManager.temporaryDirectory
            .appendingPathComponent("MacWinArchiveInstallTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: root) }
        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()

        let sourceRoot = root.appendingPathComponent("ArchiveSource", isDirectory: true)
        let sourceExe = sourceRoot
            .appendingPathComponent("PortableApps/PortableApps.com/PortableAppsPlatform.exe")
        try fileManager.createDirectory(at: sourceExe.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("portable platform".utf8).write(to: sourceExe)

        let archive = paths.downloadsDirectory.appendingPathComponent("portableapps.zip")
        let zip = Process()
        zip.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        zip.currentDirectoryURL = sourceRoot
        zip.arguments = ["-qr", archive.path, "PortableApps"]
        try zip.run()
        zip.waitUntilExit()
        #expect(zip.terminationStatus == 0)

        let hash = try Hashing.sha256Hex(file: archive)
        let recipe = RecipeManifest(
            id: "portableapps-platform",
            name: "PortableApps.com Platform",
            publisher: "PortableApps.com",
            category: "App Store",
            compatibilityRating: .experimental,
            installer: InstallerSpec(
                mode: .localFile,
                fileName: archive.lastPathComponent,
                sha256: hash,
                command: "macwin-extract-archive",
                arguments: ["$drive_c"]
            ),
            bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
            engineRequirements: EngineRequirements(),
            launchers: [
                LauncherRecipe(
                    id: "portableapps-platform",
                    displayName: "PortableApps.com Platform",
                    exePath: "C:\\PortableApps\\PortableApps.com\\PortableAppsPlatform.exe"
                )
            ]
        )
        let bottle = BottleManifest(id: "bottle", name: "Bottle", windowsVersion: "win11", arch: .win64, engineId: "engine")
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/bin/false",
            wineserverPath: "/bin/false",
            runtimePath: "/runtime",
            defaultEnv: [:]
        )
        try JSONStore().save(bottle, to: paths.bottleManifestURL(id: bottle.id))
        try fileManager.createDirectory(at: paths.bottleDriveCURL(id: bottle.id), withIntermediateDirectories: true)

        let task = try InstallService(paths: paths).install(recipe: recipe, bottle: bottle, engine: engine, installerSource: nil)
        let target = paths.bottleDriveCURL(id: bottle.id)
            .appendingPathComponent("PortableApps/PortableApps.com/PortableAppsPlatform.exe")
        let savedBottle = try BottleService(paths: paths).bottle(id: bottle.id)
        let updatedBottle = try #require(savedBottle)
        let log = try String(contentsOfFile: task.logPath, encoding: .utf8)

        #expect(task.state == .succeeded)
        #expect(task.exitCode == 0)
        #expect(fileManager.fileExists(atPath: target.path))
        #expect(updatedBottle.installedApps.contains { $0.id == "portableapps-platform" })
        let launcher = try #require(updatedBottle.installedApps.first { $0.id == "portableapps-platform" })
        #expect(launcher.envOverrides["MACWIN_COMPAT_PROFILE"] == "portableapps-platform")
        #expect(launcher.envOverrides["MACWIN_PORTABLEAPPS_PLATFORM_REPAIR"] == "1")
        #expect(launcher.envOverrides["WINEDLLOVERRIDES"] == "winemenubuilder.exe=d;uxtheme=d")
        #expect(log.contains("managedInstaller=extractArchive"))
        #expect(log.contains("PASS archive extracted"))
    }

    @Test("32-bit installers require WoW64 engine support")
    func win32InstallerRequiresWow64Engine() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinWin32InstallTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()

        let installer = root.appendingPathComponent("setup32.exe")
        try Self.fakePE(machine: 0x014c).write(to: installer)

        let recipe = RecipeManifest(
            id: "win32",
            name: "Win32",
            publisher: "MacWin",
            category: "Test",
            compatibilityRating: .experimental,
            installer: InstallerSpec(mode: .localFile),
            bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
            engineRequirements: EngineRequirements(requiresWin32: true),
            launchers: [LauncherRecipe(id: "win32", displayName: "Win32", exePath: "C:\\Win32\\app.exe")]
        )
        let bottle = BottleManifest(id: "bottle", name: "Bottle", windowsVersion: "win11", arch: .win64, engineId: "engine")
        let engine = EngineManifest(
            id: "engine",
            name: "Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            winePath: "/bin/false",
            wineserverPath: "/bin/false",
            runtimePath: "/runtime",
            defaultEnv: [:]
        )
        try JSONStore().save(bottle, to: paths.bottleManifestURL(id: bottle.id))

        #expect(throws: MacWinError.unsupportedEngine("32-bit Windows installer requires a WoW64-capable engine: setup32.exe")) {
            _ = try InstallService(paths: paths).install(
                recipe: recipe,
                bottle: bottle,
                engine: engine,
                installerSource: .localFile(installer)
            )
        }

        let history = InstallHistoryService(paths: paths).report()
        #expect(history.failedCount == 1)
        #expect(history.tasks.first?.recipeId == "win32")
        #expect(history.tasks.first?.progressText.contains("32-bit Windows installer requires a WoW64-capable engine") == true)
    }

    private static func fakePE(machine: UInt16) -> Data {
        var bytes = [UInt8](repeating: 0, count: 256)
        bytes[0] = 0x4d
        bytes[1] = 0x5a
        bytes[0x3c] = 0x80
        bytes[0x80] = 0x50
        bytes[0x81] = 0x45
        bytes[0x84] = UInt8(machine & 0x00ff)
        bytes[0x85] = UInt8(machine >> 8)
        return Data(bytes)
    }
}
