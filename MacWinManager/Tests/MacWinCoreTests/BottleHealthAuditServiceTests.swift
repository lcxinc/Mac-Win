import Foundation
import Testing
@testable import MacWinCore

@Suite("Bottle health audit service")
struct BottleHealthAuditServiceTests {
    @Test("Bottle health audit finds missing bootstrap font config stale launchers and incomplete profiles")
    func bottleHealthAuditFindsRepairGaps() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinBottleHealthTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()

        let healthy = BottleManifest(
            id: "healthy",
            name: "Healthy",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine",
            installedApps: [
                ApplicationCompatibilityProfile.hoYoPlay.applied(to: LauncherManifest(
                    id: "hoyoplay",
                    appId: "hoyoplay-cn",
                    bottleId: "healthy",
                    displayName: "HoYoPlay",
                    exePath: "C:\\Program Files\\miHoYo Launcher\\1.16.1.364\\HYP.exe"
                ))
            ]
        )
        try FileManager.default.createDirectory(at: paths.bottleDriveCURL(id: healthy.id), withIntermediateDirectories: true)
        try Data("ok\n".utf8).write(
            to: paths.bottleDirectory(id: healthy.id).appendingPathComponent(BottleService.winebootSentinelName)
        )
        try Data("<fontconfig />\n".utf8).write(to: BottleService.fontConfigURL(for: healthy.id, paths: paths))

        let broken = BottleManifest(
            id: "broken",
            name: "Broken",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine",
            installedApps: [
                LauncherManifest(
                    id: "steam",
                    appId: "steam",
                    bottleId: "broken",
                    displayName: "Steam",
                    exePath: "C:\\Program Files\\Steam\\Steam.exe",
                    args: [
                        "-no-cef-sandbox",
                        "--disable-font-subpixel-positioning",
                        "--disable-features=DWriteFontProxy,UseDWriteCore"
                    ],
                    envOverrides: ["MACWIN_COMPAT_PROFILE": "steam-client"]
                )
            ]
        )
        try FileManager.default.createDirectory(at: paths.bottleDriveCURL(id: broken.id), withIntermediateDirectories: true)

        let placeholder = BottleManifest(
            id: "placeholder",
            name: "Placeholder",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine"
        )

        let activeMissingDrive = BottleManifest(
            id: "missing-drive",
            name: "Missing Drive",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine",
            installedApps: [
                LauncherManifest(
                    id: "app",
                    appId: "local",
                    bottleId: "missing-drive",
                    displayName: "App",
                    exePath: "C:\\Program Files\\App\\App.exe"
                )
            ]
        )

        let report = BottleHealthAuditService(paths: paths).report(bottles: [healthy, broken, placeholder, activeMissingDrive])

        #expect(report.bottleCount == 4)
        #expect(report.healthyBottleCount == 1)
        #expect(report.warningBottleCount == 1)
        #expect(report.actionRequiredBottleCount == 2)
        #expect(report.missingDriveCCount == 2)
        #expect(report.missingWinebootSentinelCount == 3)
        #expect(report.missingFontConfigCount == 3)
        #expect(report.staleLauncherCount == 1)
        #expect(report.incompleteCompatibilityProfileCount == 1)
        #expect(report.highFindingCount == 2)
        #expect(report.warningFindingCount == 4)

        let healthyBottle = try #require(report.bottles.first { $0.bottleId == "healthy" })
        #expect(healthyBottle.findings.isEmpty)
        #expect(healthyBottle.launchers.first?.missingCompatibilityEnvironmentKeys.isEmpty == true)

        let brokenBottle = try #require(report.bottles.first { $0.bottleId == "broken" })
        #expect(brokenBottle.hasDriveC == true)
        #expect(brokenBottle.hasWinebootSentinel == false)
        #expect(brokenBottle.hasFontConfig == false)
        #expect(brokenBottle.staleLauncherCount == 1)
        #expect(brokenBottle.incompleteCompatibilityProfileCount == 1)
        #expect(brokenBottle.findings.map(\.id).contains("broken:steam:stale-rendering-flags"))
        #expect(brokenBottle.findings.map(\.id).contains("broken:steam:incomplete-compat-profile"))
        #expect(brokenBottle.launchers.first?.staleRenderingFlags.contains("--disable-font-subpixel-positioning") == true)
        #expect(brokenBottle.launchers.first?.staleRenderingFlags.contains("UseDWriteCore") == true)
        #expect(brokenBottle.launchers.first?.missingCompatibilityEnvironmentKeys.contains("MACWIN_STEAMWEBHELPER_ARGS") == true)

        let placeholderBottle = try #require(report.bottles.first { $0.bottleId == "placeholder" })
        #expect(placeholderBottle.hasDriveC == false)
        #expect(placeholderBottle.findings.first?.id == "placeholder:empty-placeholder")
        #expect(placeholderBottle.findings.first?.severity == .warning)

        let missingDriveBottle = try #require(report.bottles.first { $0.bottleId == "missing-drive" })
        #expect(missingDriveBottle.hasDriveC == false)
        #expect(missingDriveBottle.findings.first?.id == "missing-drive:missing-drive-c")
        #expect(missingDriveBottle.findings.first?.severity == .high)
    }
}
