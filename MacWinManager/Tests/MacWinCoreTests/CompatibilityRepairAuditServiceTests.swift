import Foundation
import Testing
@testable import MacWinCore

@Suite("Compatibility repair audit service")
struct CompatibilityRepairAuditServiceTests {
    @Test("Audit reports ready missing and stale profile launches")
    func auditReportsReadyMissingAndStaleProfileLaunches() {
        let ready = WineLaunchRecord(
            id: "ready-hoyoplay",
            mode: .detached,
            state: .started,
            logPath: "/logs/ready.log",
            startedAt: Date(timeIntervalSince1970: 300),
            bottleId: "bottle",
            bottleName: "Bottle",
            engineId: "engine",
            winePath: "/wine",
            exe: "C:\\Program Files\\miHoYo Launcher\\1.16.1.364\\HYP.exe",
            args: ApplicationCompatibilityProfile.hoYoPlay.launchArguments,
            commandLine: ["/usr/bin/arch", "-x86_64", "/wine", "C:\\Program Files\\miHoYo Launcher\\1.16.1.364\\HYP.exe"] + ApplicationCompatibilityProfile.hoYoPlay.launchArguments,
            workingDirectory: "/prefix/drive_c",
            environment: ApplicationCompatibilityProfile.hoYoPlay.environment
        )
        let missing = WineLaunchRecord(
            id: "missing-steam",
            mode: .detached,
            state: .started,
            logPath: "/logs/missing.log",
            startedAt: Date(timeIntervalSince1970: 200),
            bottleId: "bottle",
            bottleName: "Bottle",
            engineId: "engine",
            winePath: "/wine",
            exe: "C:\\Program Files\\Steam\\Steam.exe",
            args: ["-no-cef-sandbox"],
            commandLine: ["/usr/bin/arch", "-x86_64", "/wine", "C:\\Program Files\\Steam\\Steam.exe", "-no-cef-sandbox"],
            workingDirectory: "/prefix/drive_c",
            environment: ["MACWIN_COMPAT_PROFILE": "steam-client"]
        )
        let stale = WineLaunchRecord(
            id: "stale-hoyoplay",
            mode: .detached,
            state: .started,
            logPath: "/logs/stale.log",
            startedAt: Date(timeIntervalSince1970: 100),
            bottleId: "bottle",
            bottleName: "Bottle",
            engineId: "engine",
            winePath: "/wine",
            exe: "C:\\Program Files\\miHoYo Launcher\\1.16.1.364\\HYP.exe",
            args: ["--disable-direct-write", "--disable-features=DWriteFontProxy,UseDWriteCore"],
            commandLine: ["/usr/bin/arch", "-x86_64", "/wine", "C:\\Program Files\\miHoYo Launcher\\1.16.1.364\\HYP.exe", "--disable-direct-write"],
            workingDirectory: "/prefix/drive_c",
            environment: ApplicationCompatibilityProfile.hoYoPlay.environment.merging(
                ["WINEDLLOVERRIDES": "qone,wbemprox=d;dwrite,usp10=b"],
                uniquingKeysWith: { _, new in new }
            )
        )
        let ignored = WineLaunchRecord(
            id: "console",
            mode: .foregroundRun,
            state: .completed,
            logPath: "/logs/console.log",
            startedAt: Date(timeIntervalSince1970: 50),
            bottleId: "bottle",
            bottleName: "Bottle",
            engineId: "engine",
            winePath: "/wine",
            exe: "C:\\windows\\system32\\cmd.exe",
            args: [],
            commandLine: ["/usr/bin/arch", "-x86_64", "/wine", "cmd.exe"],
            workingDirectory: "/prefix/drive_c",
            environment: [:]
        )

        let report = CompatibilityRepairAuditService.report(records: [ignored, stale, missing, ready])

        #expect(report.totalLaunchCount == 4)
        #expect(report.auditedLaunchCount == 3)
        #expect(report.readyLaunchCount == 1)
        #expect(report.missingRepairLaunchCount == 1)
        #expect(report.staleFlagLaunchCount == 1)
        #expect(report.entries.map(\.launchRecordId) == ["ready-hoyoplay", "missing-steam", "stale-hoyoplay"])
        #expect(report.entries.first { $0.launchRecordId == "ready-hoyoplay" }?.state == .ready)
        #expect(report.entries.first { $0.launchRecordId == "missing-steam" }?.missingRepairKeys.contains("MACWIN_TEXT_RENDERING_REPAIR") == true)
        #expect(report.entries.first { $0.launchRecordId == "stale-hoyoplay" }?.state == .staleFlags)
        #expect(report.entries.first { $0.launchRecordId == "stale-hoyoplay" }?.staleRenderingFlags.contains("--disable-direct-write") == true)
        #expect(report.entries.first { $0.launchRecordId == "stale-hoyoplay" }?.staleRenderingFlags.contains("DWriteFontProxy") == true)
        #expect(report.entries.first { $0.launchRecordId == "stale-hoyoplay" }?.staleRenderingFlags.contains("UseDWriteCore") == true)
        #expect(report.entries.first { $0.launchRecordId == "stale-hoyoplay" }?.staleRenderingFlags.contains("builtin-dwrite-or-usp10-override") == true)
        #expect(report.findings.map(\.id) == ["stale-launch-rendering-flags", "missing-launch-repair-environment"])
    }

    @Test("Audit does not require intentionally cleared profile environment values")
    func auditDoesNotRequireIntentionallyClearedProfileEnvironmentValues() {
        var environment = ApplicationCompatibilityProfile.portableAppsPlatform.environment
        environment.removeValue(forKey: "WINE_D3D_CONFIG")
        let record = WineLaunchRecord(
            id: "portableapps-platform",
            mode: .detached,
            state: .completed,
            logPath: "/logs/portableapps.log",
            startedAt: Date(timeIntervalSince1970: 400),
            bottleId: "bottle",
            bottleName: "Bottle",
            engineId: "engine",
            winePath: "/wine",
            exe: "C:\\PortableApps\\PortableApps.com\\PortableAppsPlatform.exe",
            args: [],
            commandLine: ["/usr/bin/arch", "-x86_64", "/wine", "C:\\PortableApps\\PortableApps.com\\PortableAppsPlatform.exe"],
            workingDirectory: "/prefix/drive_c",
            environment: environment
        )

        let report = CompatibilityRepairAuditService.report(records: [record])
        let entry = report.entries.first { $0.launchRecordId == "portableapps-platform" }

        #expect(entry?.state == .ready)
        #expect(entry?.requiredRepairKeys.contains("MACWIN_DISABLE_WINE_D3D_CONFIG") == true)
        #expect(entry?.requiredRepairKeys.contains("WINE_D3D_CONFIG") == false)
        #expect(entry?.missingRepairKeys.isEmpty == true)
    }

    @Test("LibreCAD audit requires the managed first-run profile repair")
    func libreCADAuditRequiresFirstRunProfileRepair() {
        var environment = ApplicationCompatibilityProfile.libreCADQt.environment
        environment.removeValue(forKey: "MACWIN_LIBRECAD_PROFILE_REPAIR")
        let record = WineLaunchRecord(
            id: "librecad-missing-first-run-repair",
            mode: .detached,
            state: .started,
            logPath: "/logs/librecad.log",
            startedAt: Date(timeIntervalSince1970: 450),
            bottleId: "bottle",
            bottleName: "Bottle",
            engineId: "engine",
            winePath: "/wine",
            exe: "C:\\Program Files\\LibreCAD\\LibreCAD.exe",
            args: [],
            commandLine: ["/usr/bin/arch", "-x86_64", "/wine", "C:\\Program Files\\LibreCAD\\LibreCAD.exe"],
            workingDirectory: "/prefix/drive_c/Program Files/LibreCAD",
            environment: environment
        )

        let report = CompatibilityRepairAuditService.report(records: [record])
        let entry = report.entries.first

        #expect(entry?.profile == ApplicationCompatibilityProfile.libreCADQt.rawValue)
        #expect(entry?.state == .missingRepairs)
        #expect(entry?.requiredRepairKeys.contains("MACWIN_LIBRECAD_PROFILE_REPAIR") == true)
        #expect(entry?.missingRepairKeys == ["MACWIN_LIBRECAD_PROFILE_REPAIR"])
    }

    @Test("WoW64 WPS coverage is ready when both fltlib architectures exist")
    func wow64WPSCoverageIsReadyWithBothArchitectures() throws {
        let fixture = try makeWPSCoverageFixture(supportsWin32: true, includeX64: true, includeX86: true)
        defer { try? FileManager.default.removeItem(at: fixture.root) }

        let report = CompatibilityRepairAuditService().makeReport(
            launchHistory: nil,
            engines: [fixture.engine],
            bottles: [fixture.bottle]
        )

        let entry = try #require(report.runtimeCoverageEntries.first)
        #expect(entry.state == .ready)
        #expect(entry.requiredSourcePaths.count == 2)
        #expect(entry.presentSourcePaths.count == 2)
        #expect(entry.missingSourcePaths.isEmpty)
        #expect(entry.affectedBottleIds == [fixture.bottle.id])
        #expect(report.missingRuntimeCoverageCount == 0)
        #expect(report.findings.contains { $0.id == "missing-wps-office-fltlib-engine-coverage" } == false)
    }

    @Test("WoW64 WPS coverage warns when 32-bit fltlib is missing")
    func wow64WPSCoverageWarnsWhenX86FltlibIsMissing() throws {
        let fixture = try makeWPSCoverageFixture(supportsWin32: true, includeX64: true, includeX86: false)
        defer { try? FileManager.default.removeItem(at: fixture.root) }

        let report = CompatibilityRepairAuditService().makeReport(
            launchHistory: nil,
            engines: [fixture.engine],
            bottles: [fixture.bottle]
        )

        let entry = try #require(report.runtimeCoverageEntries.first)
        #expect(entry.state == .missingRepairs)
        #expect(entry.missingSourcePaths.count == 1)
        #expect(entry.missingSourcePaths[0].hasSuffix("dlls/fltlib/i386-windows/fltlib.dll"))
        #expect(report.missingRuntimeCoverageCount == 1)
        let finding = try #require(
            report.findings.first { $0.id == "missing-wps-office-fltlib-engine-coverage" }
        )
        #expect(finding.severity == "high")
        #expect(finding.missingRepairKeys == entry.missingSourcePaths)
    }

    @Test("64-bit-only WPS coverage does not require an i386 fltlib")
    func x64OnlyWPSCoverageRequiresOnlyX64Fltlib() throws {
        let fixture = try makeWPSCoverageFixture(supportsWin32: false, includeX64: true, includeX86: false)
        defer { try? FileManager.default.removeItem(at: fixture.root) }

        let entries = CompatibilityRepairAuditService().runtimeCoverageEntries(
            engines: [fixture.engine],
            bottles: [fixture.bottle]
        )

        let entry = try #require(entries.first)
        #expect(entry.state == .ready)
        #expect(entry.requiredSourcePaths.count == 1)
        #expect(entry.requiredSourcePaths[0].hasSuffix("dlls/fltlib/x86_64-windows/fltlib.dll"))
        #expect(entry.missingSourcePaths.isEmpty)
    }

    @Test("Runtime coverage fields decode from legacy audit reports")
    func runtimeCoverageFieldsDecodeFromLegacyAuditReports() throws {
        let data = Data(
            """
            {
              "totalLaunchCount": 0,
              "auditedLaunchCount": 0,
              "readyLaunchCount": 0,
              "missingRepairLaunchCount": 0,
              "staleFlagLaunchCount": 0,
              "entries": [],
              "findings": []
            }
            """.utf8
        )

        let report = try JSONDecoder().decode(CompatibilityRepairAuditReport.self, from: data)

        #expect(report.runtimeCoverageEntries.isEmpty)
        #expect(report.missingRuntimeCoverageCount == 0)
    }

    private func makeWPSCoverageFixture(
        supportsWin32: Bool,
        includeX64: Bool,
        includeX86: Bool
    ) throws -> (root: URL, engine: EngineManifest, bottle: BottleManifest) {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinWPSCoverageAudit-\(UUID().uuidString)", isDirectory: true)
        let build = root.appendingPathComponent("engine-build", isDirectory: true)
        let loader = build.appendingPathComponent("loader", isDirectory: true)
        try FileManager.default.createDirectory(at: loader, withIntermediateDirectories: true)

        for (include, path) in [
            (includeX64, "dlls/fltlib/x86_64-windows/fltlib.dll"),
            (includeX86, "dlls/fltlib/i386-windows/fltlib.dll"),
        ] where include {
            let url = build.appendingPathComponent(path)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data(path.utf8).write(to: url)
        }

        let engine = EngineManifest(
            id: supportsWin32 ? "wow64-engine" : "x64-engine",
            name: supportsWin32 ? "WoW64 Engine" : "x64 Engine",
            wineVersion: "wine-11.11",
            arch: .win64,
            supportsWin32: supportsWin32,
            winePath: loader.appendingPathComponent("wine").path,
            wineserverPath: loader.appendingPathComponent("wineserver").path,
            runtimePath: root.appendingPathComponent("runtime").path,
            defaultEnv: [:]
        )
        let bottleId = "wps-bottle"
        let launcher = LauncherManifest(
            id: "wps-writer",
            appId: "wps-office",
            bottleId: bottleId,
            displayName: "WPS Writer",
            exePath: "C:\\Program Files\\Kingsoft\\WPS Office\\office6\\wps.exe",
            envOverrides: ["MACWIN_COMPAT_PROFILE": ApplicationCompatibilityProfile.wpsOffice.rawValue]
        )
        let bottle = BottleManifest(
            id: bottleId,
            name: "WPS Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: engine.id,
            installedApps: [launcher]
        )
        return (root, engine, bottle)
    }
}
