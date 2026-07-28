import Foundation
import Testing
@testable import MacWinCore

@Suite("Foundation status snapshot service")
struct FoundationStatusSnapshotServiceTests {
    @Test("Snapshot summarizes foundation blockers warnings and exports artifacts")
    func snapshotSummarizesFoundationStateAndExportsArtifacts() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinFoundationStatusTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()
        let engineRoot = root.appendingPathComponent("engine", isDirectory: true)
        let runtimeRoot = root.appendingPathComponent("runtime", isDirectory: true)
        try FileManager.default.createDirectory(at: engineRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: runtimeRoot, withIntermediateDirectories: true)
        let wineURL = engineRoot.appendingPathComponent("wine")
        let wineserverURL = engineRoot.appendingPathComponent("wineserver")
        try Data("wine".utf8).write(to: wineURL)
        try Data("wineserver".utf8).write(to: wineserverURL)
        try Data("err: failed window\n".utf8).write(to: paths.logsDirectory.appendingPathComponent("broken.log"))

        let engine = EngineManifest(
            id: "wine-test",
            name: "Wine Test",
            wineVersion: "wine-11.11",
            arch: .win64,
            supportsWin32: true,
            winePath: wineURL.path,
            wineserverPath: wineserverURL.path,
            runtimePath: runtimeRoot.path,
            defaultEnv: [:],
            healthChecks: []
        )
        let recipes = [
            RecipeManifest(
                id: "macwin-core-capability-tests",
                name: "MacWin Core Capability Tests",
                publisher: "MacWin",
                category: "Diagnostics",
                compatibilityRating: .excellent,
                installer: InstallerSpec(mode: .none),
                bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
                engineRequirements: EngineRequirements(),
                launchers: []
            ),
            RecipeManifest(
                id: "sample-tool",
                name: "Sample Tool",
                publisher: "Example",
                category: "Utilities",
                compatibilityRating: .good,
                installer: InstallerSpec(
                    mode: .download,
                    url: "https://example.test/sample.exe",
                    fileName: "sample.exe",
                    sha256: "abc"
                ),
                bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
                engineRequirements: EngineRequirements(),
                launchers: []
            )
        ]
        let capability = CapabilityReportService(
            paths: paths,
            testAssetService: TestAssetService(root: root.appendingPathComponent("test-assets", isDirectory: true)),
            runtimeProcessAuditService: RuntimeProcessAuditService(processListProvider: { "" }),
            runtimeApplicationAuditService: RuntimeApplicationAuditService(applicationListProvider: { "" })
        ).makeReport(
            generatedAt: Date(timeIntervalSince1970: 1_780_000_000),
            engines: [engine],
            bottles: [],
            recipes: recipes,
            logLimit: 24
        )

        let service = FoundationStatusSnapshotService(paths: paths)
        let snapshot = service.makeSnapshot(report: capability)

        #expect(snapshot.state == FoundationStatusState.blocked)
        #expect(snapshot.catalogRecipeCount == 2)
        #expect(snapshot.usableEngineCount == 1)
        #expect(snapshot.missingInstallerCount == 1)
        #expect(snapshot.failedLogCount == 1)
        #expect(snapshot.missingRequiredTestExecutableCount > 0)
        #expect(snapshot.topFindings.contains { $0.id == "test-assets-missing" && $0.severity == FoundationStatusSeverity.blocker })
        #expect(snapshot.topFindings.contains { $0.id == "installers-missing" && $0.severity == FoundationStatusSeverity.warning })
        #expect(snapshot.topFindings.contains { $0.id == "recent-log-failures" && $0.severity == FoundationStatusSeverity.warning })

        let result = try service.exportSnapshot(report: capability)
        #expect(FileManager.default.fileExists(atPath: result.snapshotURL.path))
        #expect(FileManager.default.fileExists(atPath: result.latestSnapshotURL.path))
        #expect(FileManager.default.fileExists(atPath: result.markdownURL.path))
        #expect(FileManager.default.fileExists(atPath: result.latestMarkdownURL.path))
        #expect(FileManager.default.fileExists(atPath: result.logURL.path))

        let exported = try JSONStore().load(FoundationStatusSnapshot.self, from: result.latestSnapshotURL)
        #expect(exported == snapshot)
        let markdown = try String(contentsOf: result.latestMarkdownURL, encoding: .utf8)
        #expect(markdown.contains("# MacWin Foundation Status"))
        #expect(markdown.contains("test executables"))
        let log = try String(contentsOf: result.logURL, encoding: .utf8)
        #expect(log.contains("state=blocked"))
        #expect(log.contains("recipes=2"))

        let recentLogs = LogService(paths: paths).recentLogs(limit: 10)
        #expect(recentLogs.map(\.name).contains("broken.log"))
        #expect(!recentLogs.map(\.name).contains("foundation-status.log"))
    }

    @Test("Snapshot treats older failed logs as historical diagnostics")
    func snapshotTreatsOlderFailedLogsAsHistoricalDiagnostics() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinFoundationStatusHistoricalLogTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()
        let generatedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let oldLog = paths.logsDirectory.appendingPathComponent("old-failure.log")
        try Data("err: historical experiment failed\n".utf8).write(to: oldLog)
        try FileManager.default.setAttributes(
            [.modificationDate: generatedAt.addingTimeInterval(-3 * 24 * 60 * 60)],
            ofItemAtPath: oldLog.path
        )

        let capability = CapabilityReportService(
            paths: paths,
            testAssetService: TestAssetService(root: root.appendingPathComponent("test-assets", isDirectory: true)),
            runtimeProcessAuditService: RuntimeProcessAuditService(processListProvider: { "" }),
            runtimeApplicationAuditService: RuntimeApplicationAuditService(applicationListProvider: { "" })
        ).makeReport(
            generatedAt: generatedAt,
            engines: [],
            bottles: [],
            recipes: [],
            logLimit: 24
        )

        let snapshot = FoundationStatusSnapshotService(paths: paths).makeSnapshot(report: capability)

        #expect(snapshot.failedLogCount == 0)
        #expect(snapshot.topFindings.contains { $0.id == "historical-log-failures" && $0.severity == .info })
        #expect(!snapshot.topFindings.contains { $0.id == "recent-log-failures" })
    }

    @Test("Snapshot treats stale Androws CEF profile crash as resolved compatibility history")
    func snapshotTreatsStaleAndrowsProfileCrashAsResolvedCompatibilityHistory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinFoundationStatusResolvedAndrowsTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()
        let generatedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let staleCrash = paths.logsDirectory
            .appendingPathComponent("high-performance-win11-local-c-program-files-tencent-androws-application-androwslauncher-exe.log")
        try Data("""
        exe=C:\\Program Files\\Tencent\\Androws\\Application\\AndrowsLauncher.exe
        env.MACWIN_COMPAT_PROFILE=cef-software-gl
        wine: Unhandled page fault on read access to 0000000000000000 at address 000000014018B485
        wineserver crashed, please enable coredumps and restart.
        """.utf8).write(to: staleCrash)
        try FileManager.default.setAttributes(
            [.modificationDate: generatedAt.addingTimeInterval(-60)],
            ofItemAtPath: staleCrash.path
        )

        let capability = CapabilityReportService(
            paths: paths,
            testAssetService: TestAssetService(root: root.appendingPathComponent("test-assets", isDirectory: true)),
            runtimeProcessAuditService: RuntimeProcessAuditService(processListProvider: { "" }),
            runtimeApplicationAuditService: RuntimeApplicationAuditService(applicationListProvider: { "" })
        ).makeReport(
            generatedAt: generatedAt,
            engines: [],
            bottles: [],
            recipes: [],
            logLimit: 24
        )

        let snapshot = FoundationStatusSnapshotService(paths: paths).makeSnapshot(report: capability)

        #expect(snapshot.failedLogCount == 0)
        #expect(!snapshot.topFindings.contains { $0.id == "recent-log-failures" })
    }

    @Test("Snapshot treats Lenovo App Store page fault followed by app messages as non-fatal")
    func snapshotTreatsLenovoAppStoreContinuedMessagesAsNonFatal() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinFoundationStatusResolvedLenovoTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()
        let generatedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let lenovoLog = paths.logsDirectory
            .appendingPathComponent("high-performance-win11-lenovo-current-manifest-smoke.log")
        try Data("""
        cmd=/usr/bin/arch -x86_64 /engine/wine C:\\Program Files (x86)\\Lenovo\\LeAppStore\\LenovoAppStore.exe --no-sandbox
        wine: Unhandled page fault on read access to 0000000000000000 at address 000000014018B485 (thread 02b4), starting debugger...
        Warning: disabling flag --expose_wasm due to conflicting flags
         messageid: 1 category:APPSTORE_GET_LOCALMACHINEINFOtype:1
         messageid: 2 category:FC_DL_LISTtype:1
        """.utf8).write(to: lenovoLog)
        try FileManager.default.setAttributes(
            [.modificationDate: generatedAt.addingTimeInterval(-60)],
            ofItemAtPath: lenovoLog.path
        )

        let capability = CapabilityReportService(
            paths: paths,
            testAssetService: TestAssetService(root: root.appendingPathComponent("test-assets", isDirectory: true)),
            runtimeProcessAuditService: RuntimeProcessAuditService(processListProvider: { "" }),
            runtimeApplicationAuditService: RuntimeApplicationAuditService(applicationListProvider: { "" })
        ).makeReport(
            generatedAt: generatedAt,
            engines: [],
            bottles: [],
            recipes: [],
            logLimit: 24
        )

        let snapshot = FoundationStatusSnapshotService(paths: paths).makeSnapshot(report: capability)

        #expect(snapshot.failedLogCount == 0)
        #expect(snapshot.attentionLogCount == 0)
        #expect(!snapshot.topFindings.contains { $0.id == "recent-log-failures" })
    }

    @Test("Snapshot treats Lenovo light argument logs with continued messages as non-fatal")
    func snapshotTreatsLenovoLightArgumentLogsWithContinuedMessagesAsNonFatal() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinFoundationStatusResolvedLenovoLightTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()
        let generatedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let lenovoLog = paths.logsDirectory
            .appendingPathComponent("high-performance-win11-lenovo-light-top-level.log")
        try Data("""
        # light top-level args=['--no-sandbox']
        Warning: disabling flag --expose_wasm due to conflicting flags
        wine: Unhandled page fault on read access to 0000000000000000 at address 000000014018B485 (thread 04a4), starting debugger...
         messageid: 1 category:APPSTORE_GET_LOCALMACHINEINFOtype:1
         messageid: 2 category:FC_DL_LISTtype:1
        """.utf8).write(to: lenovoLog)
        try FileManager.default.setAttributes(
            [.modificationDate: generatedAt.addingTimeInterval(-60)],
            ofItemAtPath: lenovoLog.path
        )

        let capability = CapabilityReportService(
            paths: paths,
            testAssetService: TestAssetService(root: root.appendingPathComponent("test-assets", isDirectory: true)),
            runtimeProcessAuditService: RuntimeProcessAuditService(processListProvider: { "" }),
            runtimeApplicationAuditService: RuntimeApplicationAuditService(applicationListProvider: { "" })
        ).makeReport(
            generatedAt: generatedAt,
            engines: [],
            bottles: [],
            recipes: [],
            logLimit: 24
        )

        let snapshot = FoundationStatusSnapshotService(paths: paths).makeSnapshot(report: capability)

        #expect(snapshot.failedLogCount == 0)
        #expect(snapshot.attentionLogCount == 0)
        #expect(!snapshot.topFindings.contains { $0.id == "recent-log-failures" })
    }

    @Test("Snapshot treats older Lenovo crash experiments as resolved by newer successful smoke")
    func snapshotTreatsOlderLenovoCrashExperimentsAsResolvedByNewerSmoke() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinFoundationStatusResolvedLenovoHistoryTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()
        let generatedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let oldCrash = paths.logsDirectory
            .appendingPathComponent("high-performance-win11-lenovo-light-top-level.log")
        let newerSmoke = paths.logsDirectory
            .appendingPathComponent("high-performance-win11-lenovo-current-manifest-smoke.log")
        try Data("""
        cmd=/usr/bin/arch -x86_64 /engine/wine C:\\Program Files (x86)\\Lenovo\\LeAppStore\\LenovoAppStore.exe --no-sandbox
        wine: Unhandled page fault on read access to 0000000000000000 at address 000000014018B485 (thread 02b4), starting debugger...
        """.utf8).write(to: oldCrash)
        try Data("""
        cmd=/usr/bin/arch -x86_64 /engine/wine C:\\Program Files (x86)\\Lenovo\\LeAppStore\\LenovoAppStore.exe --no-sandbox
         messageid: 1 category:APPSTORE_GET_LOCALMACHINEINFOtype:1
         messageid: 2 category:FC_DL_LISTtype:1
        """.utf8).write(to: newerSmoke)
        try FileManager.default.setAttributes(
            [.modificationDate: generatedAt.addingTimeInterval(-120)],
            ofItemAtPath: oldCrash.path
        )
        try FileManager.default.setAttributes(
            [.modificationDate: generatedAt.addingTimeInterval(-60)],
            ofItemAtPath: newerSmoke.path
        )

        let capability = CapabilityReportService(
            paths: paths,
            testAssetService: TestAssetService(root: root.appendingPathComponent("test-assets", isDirectory: true)),
            runtimeProcessAuditService: RuntimeProcessAuditService(processListProvider: { "" }),
            runtimeApplicationAuditService: RuntimeApplicationAuditService(applicationListProvider: { "" })
        ).makeReport(
            generatedAt: generatedAt,
            engines: [],
            bottles: [],
            recipes: [],
            logLimit: 24
        )

        let snapshot = FoundationStatusSnapshotService(paths: paths).makeSnapshot(report: capability)

        #expect(snapshot.failedLogCount == 0)
        #expect(snapshot.attentionLogCount == 0)
        #expect(!snapshot.topFindings.contains { $0.id == "recent-log-failures" })
    }

    @Test("Snapshot treats Lenovo AB trace experiments as resolved by newer successful smoke")
    func snapshotTreatsLenovoABTraceExperimentsAsResolvedByNewerSmoke() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinFoundationStatusResolvedLenovoABTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()
        let generatedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let experiment = paths.logsDirectory
            .appendingPathComponent("high-performance-win11-lenovo-ab-qone-only-disabled.log")
        let newerSmoke = paths.logsDirectory
            .appendingPathComponent("high-performance-win11-lenovo-current-manifest-smoke.log")
        try Data("""
        008c:trace:seh:dispatch_exception code=6ba (RPC_S_SERVER_UNAVAILABLE)
        00c0:err:kerberos:kerberos_LsaApInitializePackage no Kerberos support, expect problems
        """.utf8).write(to: experiment)
        try Data("""
        cmd=/usr/bin/arch -x86_64 /engine/wine C:\\Program Files (x86)\\Lenovo\\LeAppStore\\LenovoAppStore.exe --no-sandbox
         messageid: 1 category:APPSTORE_GET_LOCALMACHINEINFOtype:1
         messageid: 2 category:FC_DL_LISTtype:1
        """.utf8).write(to: newerSmoke)
        try FileManager.default.setAttributes(
            [.modificationDate: generatedAt.addingTimeInterval(-120)],
            ofItemAtPath: experiment.path
        )
        try FileManager.default.setAttributes(
            [.modificationDate: generatedAt.addingTimeInterval(-60)],
            ofItemAtPath: newerSmoke.path
        )

        let capability = CapabilityReportService(
            paths: paths,
            testAssetService: TestAssetService(root: root.appendingPathComponent("test-assets", isDirectory: true)),
            runtimeProcessAuditService: RuntimeProcessAuditService(processListProvider: { "" }),
            runtimeApplicationAuditService: RuntimeApplicationAuditService(applicationListProvider: { "" })
        ).makeReport(
            generatedAt: generatedAt,
            engines: [],
            bottles: [],
            recipes: [],
            logLimit: 24
        )

        let snapshot = FoundationStatusSnapshotService(paths: paths).makeSnapshot(report: capability)

        #expect(snapshot.failedLogCount == 0)
        #expect(snapshot.attentionLogCount == 0)
        #expect(!snapshot.topFindings.contains { $0.id == "recent-log-failures" })
    }

    @Test("Snapshot treats older dotnet info failure as resolved when newer runtime inventory passes")
    func snapshotTreatsOlderDotNetInfoFailureAsResolvedByNewerInventory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinFoundationStatusResolvedDotNetTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()
        let generatedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let failedInfo = paths.logsDirectory.appendingPathComponent("dotnet-desktop-10-info-older.log")
        let passedInfo = paths.logsDirectory.appendingPathComponent("dotnet-desktop-10-info-newer.log")
        try Data(#"wine: failed to open "C:\\macwin-runtimes\\dotnet-desktop-10-x64\\dotnet.exe""#.utf8)
            .write(to: failedInfo)
        try Data("""
        Host:
          Version:      10.0.9
        .NET runtimes installed:
          Microsoft.NETCore.App 10.0.9 [C:\\macwin-runtimes\\dotnet-desktop-10-x64\\shared\\Microsoft.NETCore.App]
          Microsoft.WindowsDesktop.App 10.0.9 [C:\\macwin-runtimes\\dotnet-desktop-10-x64\\shared\\Microsoft.WindowsDesktop.App]
        """.utf8).write(to: passedInfo)
        try FileManager.default.setAttributes(
            [.modificationDate: generatedAt.addingTimeInterval(-120)],
            ofItemAtPath: failedInfo.path
        )
        try FileManager.default.setAttributes(
            [.modificationDate: generatedAt.addingTimeInterval(-60)],
            ofItemAtPath: passedInfo.path
        )

        let capability = CapabilityReportService(
            paths: paths,
            testAssetService: TestAssetService(root: root.appendingPathComponent("test-assets", isDirectory: true)),
            runtimeProcessAuditService: RuntimeProcessAuditService(processListProvider: { "" }),
            runtimeApplicationAuditService: RuntimeApplicationAuditService(applicationListProvider: { "" })
        ).makeReport(
            generatedAt: generatedAt,
            engines: [],
            bottles: [],
            recipes: [],
            logLimit: 24
        )

        let snapshot = FoundationStatusSnapshotService(paths: paths).makeSnapshot(report: capability)

        #expect(snapshot.failedLogCount == 0)
        #expect(!snapshot.topFindings.contains { $0.id == "recent-log-failures" })
    }

    @Test("Snapshot treats running MuseScore smoke with crashpad helper as non-fatal")
    func snapshotTreatsRunningMuseScoreSmokeWithCrashpadHelperAsNonFatal() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinFoundationStatusMuseScoreSmokeTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()
        let generatedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let log = paths.logsDirectory.appendingPathComponent("high-performance-win11-musescore-smoke.log")
        try Data("""
        cmd=/usr/bin/arch -x86_64 /engine/wine C:\\Program Files\\MuseScore 4\\bin\\MuseScore4.exe --session-type start-empty
        env.MACWIN_COMPAT_PROFILE=musescore-studio
        env.MACWIN_APP_MODE_INPUT_REPAIR=1
        native crash reporting handled by crashpad_handler.exe
        statusAfter25s=running
        processes:
        2970 C:\\Program Files\\MuseScore 4\\bin\\MuseScore4.exe --session-type start-empty
        2977 C:/Program Files/MuseScore 4/bin/crashpad_handler.exe --database=C:/users/test/AppData/Local/MuseScore/MuseScore4/logs/dumps
        """.utf8).write(to: log)
        try FileManager.default.setAttributes([.modificationDate: generatedAt], ofItemAtPath: log.path)

        let capability = CapabilityReportService(
            paths: paths,
            testAssetService: TestAssetService(root: root.appendingPathComponent("test-assets", isDirectory: true)),
            runtimeProcessAuditService: RuntimeProcessAuditService(processListProvider: { "" }),
            runtimeApplicationAuditService: RuntimeApplicationAuditService(applicationListProvider: { "" })
        ).makeReport(
            generatedAt: generatedAt,
            engines: [],
            bottles: [],
            recipes: [],
            logLimit: 24
        )

        let snapshot = FoundationStatusSnapshotService(paths: paths).makeSnapshot(report: capability)

        #expect(snapshot.failedLogCount == 0)
        #expect(!snapshot.topFindings.contains { $0.id == "recent-log-failures" })
    }

    @Test("Snapshot treats successful MuseScore MSI install page fault as non-fatal")
    func snapshotTreatsSuccessfulMuseScoreMSIInstallPageFaultAsNonFatal() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinFoundationStatusMuseScoreInstallTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()
        let generatedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let log = paths.logsDirectory.appendingPathComponent("high-performance-win11-musescore-install.log")
        try Data("""
        cmd=/usr/bin/arch -x86_64 /engine/wine msiexec /i /Downloads/MuseScore-Studio-4.7.3.260608135-x86_64.msi /qn /norestart
        WINEPREFIX=/prefix/high-performance-win11
        exitCode=0
        wine: Unhandled page fault on read access to 0000000000000000 at address 000000014018B485 (thread 0398), starting debugger...
        wineserver crashed, please enable coredumps (ulimit -c unlimited) and restart.
        """.utf8).write(to: log)
        try FileManager.default.setAttributes([.modificationDate: generatedAt], ofItemAtPath: log.path)

        let capability = CapabilityReportService(
            paths: paths,
            testAssetService: TestAssetService(root: root.appendingPathComponent("test-assets", isDirectory: true)),
            runtimeProcessAuditService: RuntimeProcessAuditService(processListProvider: { "" }),
            runtimeApplicationAuditService: RuntimeApplicationAuditService(applicationListProvider: { "" })
        ).makeReport(
            generatedAt: generatedAt,
            engines: [],
            bottles: [],
            recipes: [],
            logLimit: 24
        )

        let snapshot = FoundationStatusSnapshotService(paths: paths).makeSnapshot(report: capability)

        #expect(snapshot.failedLogCount == 0)
        #expect(!snapshot.topFindings.contains { $0.id == "recent-log-failures" })
    }

    @Test("Snapshot treats successful MuseScore MSI detail log with crashpad file as non-fatal")
    func snapshotTreatsSuccessfulMuseScoreMSIDetailLogWithCrashpadFileAsNonFatal() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinFoundationStatusMuseScoreMSIDetailTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()
        let generatedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let log = paths.logsDirectory.appendingPathComponent("high-performance-win11-musescore-msiexec.log")
        try Data("""
        Property(S): ProductName = MuseScore Studio 4
        1: {5C7C1282-D3E7-4DFE-AE3D-309C492348D2} 2: {E6C726BD-B53E-5F4C-A8B3-3AF01FA7CAFB} 3: C:\\Program Files\\MuseScore 4\\bin\\crashpad_handler.exe
        Action ended 11:48:10: INSTALL. Return value 1.
        """.utf8).write(to: log)
        try FileManager.default.setAttributes([.modificationDate: generatedAt], ofItemAtPath: log.path)

        let capability = CapabilityReportService(
            paths: paths,
            testAssetService: TestAssetService(root: root.appendingPathComponent("test-assets", isDirectory: true)),
            runtimeProcessAuditService: RuntimeProcessAuditService(processListProvider: { "" }),
            runtimeApplicationAuditService: RuntimeApplicationAuditService(applicationListProvider: { "" })
        ).makeReport(
            generatedAt: generatedAt,
            engines: [],
            bottles: [],
            recipes: [],
            logLimit: 24
        )

        let snapshot = FoundationStatusSnapshotService(paths: paths).makeSnapshot(report: capability)

        #expect(snapshot.failedLogCount == 0)
        #expect(!snapshot.topFindings.contains { $0.id == "recent-log-failures" })
    }

    @Test("Snapshot does not treat stale unfinished launch record as current")
    func snapshotDoesNotTreatStaleUnfinishedLaunchRecordAsCurrent() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinFoundationStatusStaleLaunchRecordTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()
        let generatedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let log = paths.logsDirectory.appendingPathComponent("steam-old-started.log")
        try Data("wine: Unhandled page fault on read access to 0000000000000000\n".utf8).write(to: log)
        try FileManager.default.setAttributes(
            [.modificationDate: generatedAt.addingTimeInterval(-7 * 24 * 60 * 60)],
            ofItemAtPath: log.path
        )
        let records = LaunchHistoryService.recordsDirectory(in: paths.logsDirectory)
        try FileManager.default.createDirectory(at: records, withIntermediateDirectories: true)
        let record = WineLaunchRecord(
            id: "steam-old-started",
            mode: .detached,
            state: .started,
            logPath: log.path,
            startedAt: generatedAt.addingTimeInterval(-7 * 24 * 60 * 60),
            endedAt: nil,
            durationMilliseconds: nil,
            processIdentifier: nil,
            exitCode: nil,
            bottleId: "high-performance-win11",
            bottleName: "High Performance",
            engineId: "wine-11.11",
            winePath: "/engine/wine",
            exe: "C:\\Program Files\\Steam\\Steam.exe",
            args: [],
            commandLine: ["/usr/bin/arch", "-x86_64", "/engine/wine", "Steam.exe"],
            workingDirectory: "/prefix/drive_c",
            environment: [:]
        )
        try JSONStore().save(record, to: records.appendingPathComponent("steam-old-started.launch.json"))

        let capability = CapabilityReportService(
            paths: paths,
            testAssetService: TestAssetService(root: root.appendingPathComponent("test-assets", isDirectory: true)),
            runtimeProcessAuditService: RuntimeProcessAuditService(processListProvider: { "" }),
            runtimeApplicationAuditService: RuntimeApplicationAuditService(applicationListProvider: { "" })
        ).makeReport(
            generatedAt: generatedAt,
            engines: [],
            bottles: [],
            recipes: [],
            logLimit: 24
        )

        let snapshot = FoundationStatusSnapshotService(paths: paths).makeSnapshot(report: capability)

        #expect(snapshot.failedLogCount == 0)
        #expect(!snapshot.topFindings.contains { $0.id == "recent-log-failures" })
    }
}
