import Foundation
import Testing
@testable import MacWinCore

@Suite("Log service")
struct LogServiceTests {
    @Test("Successful managed smoke ignores incidental error words in application output")
    func successfulManagedSmokeIgnoresIncidentalErrorWords() {
        let summary = LogService.summarizeLog("""
        == MacWin software smoke ==
        id=7zip
        phase=launch
        -bs{o|e|p}{0|1|2} : set output stream for output/error/progress line
        smokeOutcome=passed
        exitCode=0
        """)

        #expect(summary.health == .passed)
        #expect(summary.errorCount == 0)
        #expect(summary.failCount == 0)
        #expect(summary.hints == [.passObserved])
    }

    @Test("COM proxy repair ignores known DLL registration fallbacks")
    func comProxyRepairIgnoresKnownDLLRegistrationFallbacks() {
        let summary = LogService.summarizeLog("""
        == MacWin software smoke ==
        id=macwin-com-proxy
        phase=repair
        regsvr32: Failed to register DLL 'taskschd.dll'
        regsvr32: Failed to register DLL 'mstask.dll'
        regsvr32: Failed to register DLL 'msxml3.dll'
        regsvr32: Failed to register DLL 'msxml6.dll'
        exitCode=0
        """)

        #expect(summary.health == .quiet)
        #expect(summary.errorCount == 0)
        #expect(summary.failCount == 0)
        #expect(summary.hints.isEmpty)
    }

    @Test("Recent logs are sorted and ignore non-log files")
    func recentLogsAreSortedAndIgnoreNonLogFiles() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinLogTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let oldLog = root.appendingPathComponent("old.log")
        let newLog = root.appendingPathComponent("new.log")
        let operationalLog = root.appendingPathComponent("external-open-queue.log")
        let runtimeProcessLog = root.appendingPathComponent("runtime-processes-2026-07-01T151116Z.log")
        let installerHelpLog = root.appendingPathComponent("high-performance-win11-sqlitestudio-installer-help-20260702T054820Z.log")
        let manualInstallLog = root.appendingPathComponent("high-performance-win11-sqlitestudio-manual-install-20260702T054756Z.log")
        let ignored = root.appendingPathComponent("ignored.txt")
        try Data("old".utf8).write(to: oldLog)
        try Data("newer".utf8).write(to: newLog)
        try Data("event=enqueue path=/tmp/tool.exe".utf8).write(to: operationalLog)
        try Data("status=attention\nwarn: runtime-process-finding\n".utf8).write(to: runtimeProcessLog)
        try Data("There has been an error.\n--install_for was not specified\n".utf8).write(to: installerHelpLog)
        try Data("There has been an error.\nThe following options were not specified\n".utf8).write(to: manualInstallLog)
        try Data("ignored".utf8).write(to: ignored)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 10)], ofItemAtPath: oldLog.path)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 20)], ofItemAtPath: newLog.path)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 30)], ofItemAtPath: operationalLog.path)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 40)], ofItemAtPath: runtimeProcessLog.path)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 50)], ofItemAtPath: installerHelpLog.path)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 60)], ofItemAtPath: manualInstallLog.path)

        let logs = LogService.recentLogs(in: root)

        #expect(logs.map(\.name) == ["new.log", "old.log"])
        #expect(logs.first?.byteCount == 5)
    }

    @Test("Recent logs include nested software smoke evidence")
    func recentLogsIncludeNestedSoftwareSmokeEvidence() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinNestedSmokeLogTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let runDirectory = root
            .appendingPathComponent("SoftwareSmokeRuns", isDirectory: true)
            .appendingPathComponent("winscp-current", isDirectory: true)
        let archiveDirectory = root.appendingPathComponent("Archive", isDirectory: true)
        try FileManager.default.createDirectory(at: runDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: archiveDirectory, withIntermediateDirectories: true)

        let rootLog = root.appendingPathComponent("older-failure.log")
        let smokeLog = runDirectory.appendingPathComponent("winscp-client-launch.log")
        let archivedLog = archiveDirectory.appendingPathComponent("archived.log")
        try Data("wine: Unhandled page fault\n".utf8).write(to: rootLog)
        try Data("exe=C:\\Program Files (x86)\\WinSCP\\WinSCP.exe\nTIMEOUT after 25s; sending SIGTERM\nliveProcessSnapshotPhase=launch-timeout-before-cleanup\nsmokeOutcome=keptAlive\n".utf8).write(to: smokeLog)
        try Data("wine: Unhandled page fault\n".utf8).write(to: archivedLog)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 10)], ofItemAtPath: rootLog.path)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 20)], ofItemAtPath: smokeLog.path)

        let logs = LogService.recentLogs(in: root)

        #expect(logs.map(\.name) == ["winscp-client-launch.log", "older-failure.log"])
        #expect(logs.first?.url.standardizedFileURL == smokeLog.standardizedFileURL)
        #expect(logs.first?.summary.health == .passed)
    }

    @Test("Recent logs include launch context from launch records")
    func recentLogsIncludeLaunchContextFromLaunchRecords() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinLogContextTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        try FileManager.default.createDirectory(at: paths.logsDirectory, withIntermediateDirectories: true)
        let log = paths.logsDirectory.appendingPathComponent("steam.log")
        try Data("err:steamwebhelper failed\n".utf8).write(to: log)
        let records = LaunchHistoryService.recordsDirectory(in: paths.logsDirectory)
        try FileManager.default.createDirectory(at: records, withIntermediateDirectories: true)
        let record = WineLaunchRecord(
            id: "launch-1",
            mode: .detached,
            state: .completed,
            logPath: log.path,
            startedAt: Date(timeIntervalSince1970: 100),
            endedAt: Date(timeIntervalSince1970: 120),
            durationMilliseconds: 20_000,
            processIdentifier: 42,
            exitCode: 0,
            bottleId: "game",
            bottleName: "High Performance",
            engineId: "wine-11.11",
            winePath: "/engine/wine",
            exe: "C:\\Program Files\\Steam\\steam.exe",
            args: ["-silent"],
            commandLine: ["/usr/bin/arch", "-x86_64", "/engine/wine", "steam.exe", "-silent"],
            workingDirectory: "/prefix/drive_c",
            environment: ["WINE_D3D_CONFIG": "renderer=vulkan,csmt=0x0"]
        )
        try JSONStore().save(record, to: records.appendingPathComponent("launch-1.launch.json"))

        let item = try #require(LogService(paths: paths).recentLogs().first)

        #expect(item.name == "steam.log")
        #expect(item.launchContext?.launchRecordId == "launch-1")
        #expect(item.launchContext?.bottleId == "game")
        #expect(item.launchContext?.bottleName == "High Performance")
        #expect(item.launchContext?.engineId == "wine-11.11")
        #expect(item.launchContext?.exe == "C:\\Program Files\\Steam\\steam.exe")
        #expect(item.launchContext?.args == ["-silent"])
        #expect(item.launchContext?.exitCode == 0)

        let report = LogService.issueReport(logs: [item])
        #expect(report.recentFailures.first?.launchContext?.launchRecordId == "launch-1")
    }

    @Test("Log maintenance report finds stale and large cleanup candidates")
    func logMaintenanceReportFindsCleanupCandidates() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinLogMaintenanceTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let generatedAt = Date(timeIntervalSince1970: 20 * 24 * 60 * 60)
        let fresh = root.appendingPathComponent("fresh.log")
        let old = root.appendingPathComponent("old.log")
        let large = root.appendingPathComponent("large.log")
        let operational = root.appendingPathComponent("external-open-queue.log")
        let ignored = root.appendingPathComponent("ignored.txt")
        try Data("fresh".utf8).write(to: fresh)
        try Data("old!".utf8).write(to: old)
        try Data("large-log!!!".utf8).write(to: large)
        try Data("event=enqueue path=/tmp/tool.exe".utf8).write(to: operational)
        try Data("ignored".utf8).write(to: ignored)
        try FileManager.default.setAttributes(
            [.modificationDate: generatedAt.addingTimeInterval(-24 * 60 * 60)],
            ofItemAtPath: fresh.path
        )
        try FileManager.default.setAttributes(
            [.modificationDate: generatedAt.addingTimeInterval(-10 * 24 * 60 * 60)],
            ofItemAtPath: old.path
        )
        try FileManager.default.setAttributes(
            [.modificationDate: generatedAt.addingTimeInterval(-2 * 24 * 60 * 60)],
            ofItemAtPath: large.path
        )
        try FileManager.default.setAttributes(
            [.modificationDate: generatedAt.addingTimeInterval(-12 * 24 * 60 * 60)],
            ofItemAtPath: operational.path
        )

        let report = LogService.maintenanceReport(
            in: root,
            policy: LogMaintenancePolicy(staleAgeDays: 7, largeLogBytes: 10),
            generatedAt: generatedAt
        )

        #expect(report.logsPath == root.path)
        #expect(report.totalLogCount == 3)
        #expect(report.totalLogBytes == 21)
        #expect(report.staleLogCount == 1)
        #expect(report.staleLogBytes == 4)
        #expect(report.largeLogCount == 1)
        #expect(report.largeLogBytes == 12)
        #expect(report.cleanupCandidateCount == 2)
        #expect(report.cleanupCandidateBytes == 16)
        #expect(report.cleanupCandidates.map(\.name) == ["old.log", "large.log"])
        #expect(report.cleanupCandidates.first { $0.name == "old.log" }?.reasons == ["stale"])
        #expect(report.cleanupCandidates.first { $0.name == "large.log" }?.reasons == ["large"])
        #expect(report.oldestLogModifiedAt == generatedAt.addingTimeInterval(-10 * 24 * 60 * 60))
        #expect(report.newestLogModifiedAt == generatedAt.addingTimeInterval(-24 * 60 * 60))
        #expect(report.recommendations.contains { $0.contains("large logs") })
        #expect(report.recommendations.contains { $0.contains("stale logs") })

        let script = LogService.maintenanceShellScript(for: report)
        let oldCandidatePath = try #require(report.cleanupCandidates.first { $0.name == "old.log" }?.path)
        let largeCandidatePath = try #require(report.cleanupCandidates.first { $0.name == "large.log" }?.path)
        #expect(script.contains("Dry run: pass --apply to archive cleanup candidates."))
        #expect(script.contains("ARCHIVE_DIR=\"$LOGS_DIR/Archive/log-maintenance-"))
        #expect(script.contains("archive_log '\(oldCandidatePath)' 'stale'"))
        #expect(script.contains("archive_log '\(largeCandidatePath)' 'large'"))
        #expect(!script.contains(ignored.path))
    }

    @Test("Log maintenance archives cleanup candidates without deleting fresh logs")
    func logMaintenanceArchivesCleanupCandidates() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinLogArchiveTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let generatedAt = Date(timeIntervalSince1970: 30 * 24 * 60 * 60)
        let fresh = root.appendingPathComponent("fresh.log")
        let old = root.appendingPathComponent("old.log")
        let large = root.appendingPathComponent("large.log")
        let ignored = root.appendingPathComponent("ignored.txt")
        try Data("fresh".utf8).write(to: fresh)
        try Data("old!".utf8).write(to: old)
        try Data("large-log!!!".utf8).write(to: large)
        try Data("ignored".utf8).write(to: ignored)
        try FileManager.default.setAttributes(
            [.modificationDate: generatedAt.addingTimeInterval(-24 * 60 * 60)],
            ofItemAtPath: fresh.path
        )
        try FileManager.default.setAttributes(
            [.modificationDate: generatedAt.addingTimeInterval(-20 * 24 * 60 * 60)],
            ofItemAtPath: old.path
        )

        let report = LogService.maintenanceReport(
            in: root,
            policy: LogMaintenancePolicy(staleAgeDays: 7, largeLogBytes: 10),
            generatedAt: generatedAt
        )
        let result = try LogService.archiveCleanupCandidates(
            report: report,
            generatedAt: generatedAt
        )

        #expect(result.archivedCount == 2)
        #expect(result.archivedBytes == 16)
        #expect(result.archivePath.contains("Archive/log-maintenance-"))
        #expect(FileManager.default.fileExists(atPath: fresh.path))
        #expect(FileManager.default.fileExists(atPath: ignored.path))
        #expect(!FileManager.default.fileExists(atPath: old.path))
        #expect(!FileManager.default.fileExists(atPath: large.path))
        #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent("Archive").path))
        #expect(result.archivedItems.map(\.name).sorted() == ["large.log", "old.log"])
        for item in result.archivedItems {
            #expect(FileManager.default.fileExists(atPath: item.archivedPath))
            #expect(item.archivedPath.hasPrefix(result.archivePath))
        }

        let updated = LogService.maintenanceReport(
            in: root,
            policy: LogMaintenancePolicy(staleAgeDays: 7, largeLogBytes: 10),
            generatedAt: generatedAt
        )
        #expect(updated.totalLogCount == 1)
        #expect(updated.cleanupCandidateCount == 0)
    }

    @Test("Log maintenance scans nested smoke logs but skips archives")
    func logMaintenanceScansNestedSmokeLogsButSkipsArchives() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinLogNestedMaintenanceTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let smokeRun = root.appendingPathComponent("SoftwareSmokeRuns/browser-20260703T010000Z", isDirectory: true)
        let archive = root.appendingPathComponent("Archive/log-maintenance-old", isDirectory: true)
        let supportBundleLogs = root.appendingPathComponent("SupportBundles/support-20260703T010000Z/logs", isDirectory: true)
        try FileManager.default.createDirectory(at: smokeRun, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: archive, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: supportBundleLogs, withIntermediateDirectories: true)

        let generatedAt = Date(timeIntervalSince1970: 40 * 24 * 60 * 60)
        let nestedLarge = smokeRun.appendingPathComponent("edge-enterprise-install.log")
        let archivedLarge = archive.appendingPathComponent("old-large.log")
        let bundledCopy = supportBundleLogs.appendingPathComponent("copied-failure.log")
        let operationalNested = smokeRun.appendingPathComponent("runtime-processes-2026-07-03T010000Z.log")
        try Data(repeating: 1, count: 32).write(to: nestedLarge)
        try Data(repeating: 2, count: 64).write(to: archivedLarge)
        try Data(repeating: 3, count: 64).write(to: bundledCopy)
        try Data("status=attention".utf8).write(to: operationalNested)
        try FileManager.default.setAttributes(
            [.modificationDate: generatedAt.addingTimeInterval(-2 * 24 * 60 * 60)],
            ofItemAtPath: nestedLarge.path
        )
        try FileManager.default.setAttributes(
            [.modificationDate: generatedAt.addingTimeInterval(-30 * 24 * 60 * 60)],
            ofItemAtPath: archivedLarge.path
        )

        let report = LogService.maintenanceReport(
            in: root,
            policy: LogMaintenancePolicy(staleAgeDays: 14, largeLogBytes: 16),
            generatedAt: generatedAt
        )

        #expect(report.totalLogCount == 1)
        #expect(report.largeLogCount == 1)
        #expect(report.staleLogCount == 0)
        #expect(report.cleanupCandidateCount == 1)
        #expect(report.cleanupCandidates.first?.name == "edge-enterprise-install.log")
        #expect(report.cleanupCandidates.first?.path.hasSuffix("/SoftwareSmokeRuns/browser-20260703T010000Z/edge-enterprise-install.log") == true)
        #expect(!report.cleanupCandidates.contains { $0.path == archivedLarge.path })
        #expect(!report.cleanupCandidates.contains { $0.path == bundledCopy.path })
        #expect(!report.cleanupCandidates.contains { $0.path == operationalNested.path })

        let csv = LogMaintenanceReport.csv(report: report)
        #expect(csv.contains("row_type,name,path,modified_at,byte_count,reasons"))
        #expect(csv.contains("candidate,edge-enterprise-install.log"))
        #expect(csv.contains(",large,"))
    }

    @Test("Log summary counts signals and emits hints")
    func logSummaryCountsSignalsAndEmitsHints() {
        let summary = LogService.summarizeLog("""
        00:00:00.000 err:winhttp certificate validation failed
        [900:968:0616/205816.009:ERROR:network_change_notifier_win.cc(268)] WSALookupServiceBegin failed with: 8
        fixme:vulkan something is not implemented
        20_vulkan_probe.exe FAIL
        40_xaudio2_probe.exe PASS
        Uncaught Exception: Error: open EBADF
        """)

        #expect(summary.errorCount == 3)
        #expect(summary.fixmeCount == 1)
        #expect(summary.passCount == 1)
        #expect(summary.failCount == 3)
        #expect(summary.health == .failed)
        #expect(summary.hints.contains(.steamNetworkProbe))
        #expect(summary.hints.contains(.electronStdout))
        #expect(summary.hints.contains(.networkTLSIssue))
        #expect(summary.hints.contains(.vulkanIssue))
        #expect(summary.hints.contains(.passObserved))
    }

    @Test("Log summary ignores benign Chromium direct proxy and controlled GUI timeout noise")
    func logSummaryIgnoresBenignChromiumDirectProxyAndControlledGUITimeoutNoise() {
        let summary = LogService.summarizeLog("""
        == MacWin software smoke ==
        id=brave-standalone
        phase=launch
        command=wine brave.exe --no-proxy-server --proxy-server=direct:// --proxy-bypass-list=*
        [1060:1160:0626/075330.287:ERROR:net\\proxy_resolution\\win\\proxy_config_service_win.cc:160] WinHttpGetIEProxyConfigForCurrentUser failed: 18
        [1060:1160:0626/075330.387:WARNING:net\\dns\\dns_config_service_win.cc:606] Failed to read DnsConfig.
        [1060:1268:0626/075336.082:ERROR:services\\device\\public\\cpp\\geolocation\\system_geolocation_source_win.cc:111] Failed to get IAppCapability statics: Error (0x13D) while retrieving error. (0x80040150)
        TIMEOUT after 30s; sending SIGTERM to 39925
        """)

        #expect(summary.health == .quiet)
        #expect(summary.errorCount == 0)
        #expect(summary.failCount == 0)
        #expect(!summary.hints.contains(.networkTLSIssue))
        #expect(!summary.hints.contains(.timeout))
    }

    @Test("Log summary ignores Wine network enumeration noise after verified pgAdmin rendering")
    func logSummaryIgnoresVerifiedPgAdminNetworkEnumerationNoise() {
        let summary = LogService.summarizeLog("""
        == MacWin software smoke ==
        id=pgadmin-db-admin
        phase=launch
        [344:0718/215356.922:WARNING:net\\base\\net_errors_win.cc:121] Unknown error 10042 mapped to net::ERR_FAILED
        [32:0718/215357.831:INFO:CONSOLE:2] "%cElectron Security Warning (Insecure Content-Security-Policy)
        This exposes users of this app to unnecessary security risks.
        This warning will not show up
        once the app is packaged.", source: node:electron/js2c/sandbox_bundle (2)
        TIMEOUT after 75s; sending SIGTERM to 14781
        visualProbe.id=pgadmin-db-admin
        visualProbe.status=verified-compositor
        visualProbe.classification=rendered
        visualProbe.status=unavailable
        visualProbe.reason=session-locked
        smokeOutcome=keptAlive
        """)

        #expect(summary.health == .passed)
        #expect(summary.errorCount == 0)
        #expect(summary.failCount == 0)
        #expect(summary.hints.contains(.passObserved))
    }

    @Test("Log summary ignores OpenPLC Electron noise after verified rendering")
    func logSummaryIgnoresVerifiedOpenPLCElectronNoise() {
        let summary = LogService.summarizeLog("""
        == MacWin software smoke ==
        id=openplc-editor
        phase=launch
        [32:0724/163953.946:WARNING:accelerator_util.cc(64)]  doesn't contain a valid key
        [32:0724/163954.991:INFO:CONSOLE(2)] "Uncaught ReferenceError: global is not defined", source: file:///C:/macwin-portable/openplc-editor/resources/app.asar/dist/main/main.js (2)
        [32:0724/163955.129:WARNING:viz_main_impl.cc(85)] VizNullHypothesis is disabled (not a warning)
        Checking for update
        Error: Error: net::ERR_TIMED_OUT
        (node:32) UnhandledPromiseRejectionWarning: Error: net::ERR_TIMED_OUT
        (Use `OpenPLC Editor --trace-warnings ...` to show where the warning was created)
        (node:32) UnhandledPromiseRejectionWarning: Unhandled promise rejection.
        TIMEOUT after 35s; sending SIGTERM to 90498
        visualProbe.id=openplc-editor
        visualProbe.status=verified-compositor
        visualProbe.classification=rendered
        smokeOutcome=keptAlive
        """)

        #expect(summary.health == .passed)
        #expect(summary.errorCount == 0)
        #expect(summary.warningCount == 0)
        #expect(summary.failCount == 0)
        #expect(summary.passCount == 1)
        #expect(summary.hints == [.passObserved])
    }

    @Test("Log summary keeps OpenPLC Electron errors when rendering is not verified")
    func logSummaryKeepsOpenPLCElectronErrorsWithoutVerifiedRendering() {
        let summary = LogService.summarizeLog("""
        == MacWin software smoke ==
        id=openplc-editor
        phase=launch
        Checking for update
        Error: Error: net::ERR_TIMED_OUT
        (node:32) UnhandledPromiseRejectionWarning: Error: net::ERR_TIMED_OUT
        visualProbe.id=openplc-editor
        visualProbe.status=verified-compositor
        visualProbe.classification=white-window
        smokeOutcome=keptAlive
        """)

        #expect(summary.health == .failed)
        #expect(summary.errorCount > 0)
        #expect(summary.hints.contains(.passObserved))
    }

    @Test("Log summary accepts Wireshark Npcap warning after offline dissection passes")
    func logSummaryAcceptsWiresharkNpcapWarningAfterOfflineDissectionPasses() {
        let summary = LogService.summarizeLog("""
        == MacWin software smoke ==
        id=wireshark-analyzer
        phase=launch
        ** (wireshark:32) [Capture WARNING] capture_interface_stat_start(): Unable to load Npcap (wpcap.dll); you will not be able to capture packets.
        TIMEOUT after 35s; sending SIGTERM to 8523
        smokeOutcome=keptAlive
        wiresharkOfflineDissection=passed
        wiresharkLiveCapture=unsupported-npcap-driver
        """)

        #expect(summary.health == .passed)
        #expect(summary.warningCount == 0)
        #expect(summary.failCount == 0)
        #expect(summary.hints == [.passObserved])
    }

    @Test("Log summary keeps Wireshark Npcap warning before offline dissection is verified")
    func logSummaryKeepsWiresharkNpcapWarningWithoutOfflineDissectionProof() {
        let summary = LogService.summarizeLog("""
        == MacWin software smoke ==
        id=wireshark-analyzer
        phase=launch
        ** (wireshark:32) [Capture WARNING] capture_interface_stat_start(): Unable to load Npcap (wpcap.dll); you will not be able to capture packets.
        smokeOutcome=keptAlive
        """)

        #expect(summary.health == .attention)
        #expect(summary.warningCount == 1)
        #expect(summary.hints.contains(.passObserved))
    }

    @Test("Log summary ignores Beekeeper plugin update noise during kept-alive launch")
    func logSummaryIgnoresBeekeeperPluginUpdateNoiseDuringKeptAliveLaunch() {
        let summary = LogService.summarizeLog("""
        == MacWin software smoke ==
        id=beekeeper-studio
        phase=launch
        07:50:35.556 [info]  [MAIN] (BksConfig)        › Configs successfully loaded with 0 warnings.
        [32:0707/155035.732:WARNING:net\\dns\\dns_config_service_win.cc:606] Failed to read DnsConfig.
        [32:0707/155036.015:ERROR:net\\proxy_resolution\\win\\proxy_config_service_win.cc:160] WinHttpGetIEProxyConfigForCurrentUser failed: 18
        07:50:40.747 [error] [UTILITY] (PluginManager)            › Failed to check for updates for plugin "bks-ai-shell" {}
        07:50:40.756 [error] [UTILITY] (PluginManager)            › Failed to check for updates for plugin "bks-er-diagram" {}
        smokeOutcome=keptAlive
        TIMEOUT after 35s; sending SIGTERM to 69652
        """)

        #expect(summary.health == .passed)
        #expect(summary.errorCount == 0)
        #expect(summary.warningCount == 0)
        #expect(summary.failCount == 0)
        #expect(summary.passCount == 1)
        #expect(summary.hints == [.passObserved])
    }

    @Test("Log summary ignores Steam helper icon warning after kept-alive login")
    func logSummaryIgnoresSteamHelperIconWarningAfterKeptAliveLogin() {
        let summary = LogService.summarizeLog("""
        ----- MacWin launch -----
        exe=C:\\Program Files (x86)\\Steam\\Steam.exe
        env.MACWIN_COMPAT_PROFILE=steam-client
        00cc:warn:macdrv:macdrv_app_icon found no RT_GROUP_ICON resource
        smokeOutcome=keptAlive
        ----- MacWin result -----
        exitCode=15
        """)

        #expect(summary.health == .passed)
        #expect(summary.errorCount == 0)
        #expect(summary.warningCount == 0)
        #expect(summary.failCount == 0)
        #expect(summary.passCount == 1)
        #expect(summary.hints == [.passObserved])
    }

    @Test("Log summary keeps Mac driver icon warning without a successful launch")
    func logSummaryKeepsMacDriverIconWarningWithoutSuccessfulLaunch() {
        let summary = LogService.summarizeLog("""
        00cc:warn:macdrv:macdrv_app_icon found no RT_GROUP_ICON resource
        """)

        #expect(summary.health == .attention)
        #expect(summary.warningCount == 1)
        #expect(summary.passCount == 0)
    }

    @Test("Log summary ignores benign Qucs-S Qt6 startup warnings")
    func logSummaryIgnoresBenignQucsSQt6StartupWarnings() {
        let summary = LogService.summarizeLog("""
        ----- MacWin launch -----
        exe=C:\\Program Files\\Qucs-S-26.1.1-win64\\bin\\qucs-s.exe
        env.MACWIN_COMPAT_PROFILE=qucs-s-qt6
        env.QT_PLUGIN_PATH=C:\\Program Files\\Qucs-S-26.1.1-win64\\bin
        -------------------------
        Warning: QFont::fromString: Invalid description ',-1,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0' (:0, )
        Warning: QFont::fromString: Invalid description '(empty)' (:0, )
        Warning: QFSFileEngine::open: No file name specified (:0, )
        smokeOutcome=keptAlive
        TIMEOUT after 45s; sending SIGTERM to 93244
        """)

        #expect(summary.health == .passed)
        #expect(summary.warningCount == 0)
        #expect(summary.errorCount == 0)
        #expect(summary.failCount == 0)
        #expect(summary.passCount == 1)
        #expect(summary.hints.contains(.passObserved))
        #expect(!summary.hints.contains(.timeout))
    }

    @Test("Log summary ignores successful MSI detail metadata")
    func logSummaryIgnoresSuccessfulMSIDetailMetadata() {
        let summary = LogService.summarizeLog("""
        Action ended 11:48:10: InstallFinalize. Return value 1.
        File: hu-exceptionwords.cti,  Directory: CM_DP_Unspecified.tables,  Size: 139056
        Property(S): ProductName = MuseScore Studio 4
        Property(S): ErrorDialog = ErrorDlg
        Property(S): OriginalDatabase = Z:\\Users\\a1-6\\Library\\Application Support\\MacWin\\Downloads\\MuseScore-Studio-4.7.3.260608135-x86_64.msi
        Action ended 11:48:10: INSTALL. Return value 1.
        """)

        #expect(summary.health == .quiet)
        #expect(summary.errorCount == 0)
        #expect(summary.failCount == 0)
        #expect(!summary.hints.contains(.installerIssue))
    }

    @Test("Log summary ignores benign Supermium WOW64 browser runtime noise")
    func logSummaryIgnoresBenignSupermiumWOW64BrowserRuntimeNoise() {
        let summary = LogService.summarizeLog("""
        == MacWin software smoke ==
        id=supermium-32-browser
        phase=launch
        command=wine chrome.exe --disable-encryption --disable-machine-id --user-data-dir=portable_data32 --no-proxy-server --proxy-server=direct:// --proxy-bypass-list=*
        [1060:1192:0626/082409.795:ERROR:net\\proxy_resolution\\win\\proxy_config_service_win.cc:160] WinHttpGetIEProxyConfigForCurrentUser failed: 0
        [1060:1188:0626/082409.879:ERROR:services\\device\\public\\cpp\\geolocation\\system_geolocation_source_win.cc:83] Failed to get IAppCapability statics: 尚未实现。 (0x80004001)
        [1060:1064:0626/082410.090:ERROR:components\\device_event_log\\device_event_log_impl.cc:198] [15:24:10.076] FIDO: webauthn_api.cc:121 Windows WebAuthn API failed to load
        [1060:1064:0626/082147.745:ERROR:components\\embedder_support\\user_agent_utils.cc:118] UAO file invalid; all fields are not present
        ended=2026-06-26T15:24:21Z
        exitCode=0
        note=GUI launch passed after one first-run retry.
        """)

        #expect(summary.health == .quiet)
        #expect(summary.errorCount == 0)
        #expect(summary.failCount == 0)
        #expect(!summary.hints.contains(.networkTLSIssue))
        #expect(!summary.hints.contains(.cefRenderingIssue))
    }

    @Test("Log summary treats kept-alive Gecko browser child noise as pass")
    func logSummaryTreatsKeptAliveGeckoBrowserChildNoiseAsPass() {
        let summary = LogService.summarizeLog("""
        ----- MacWin launch -----
        exe=C:\\Program Files\\Mozilla Firefox\\firefox.exe
        env.MACWIN_COMPAT_PROFILE=browser-gecko
        [WARN  rkv::backend::impl_safe::environment] `load_ratio()` is irrelevant for this storage backend.
        [ERROR neqo_glue] failed to initialize socket 720: 无效的参数。 (os error 10022)
        Crash Annotation GraphicsCriticalError: |[0][GFX1-]: RenderCompositorSWGL failed mapping default framebuffer, no dt
        smokeOutcome=keptAlive
        Exiting due to channel error.
        ----- MacWin result -----
        exitCode=15
        """)

        #expect(summary.health == .passed)
        #expect(summary.errorCount == 0)
        #expect(summary.warningCount == 0)
        #expect(summary.failCount == 0)
        #expect(summary.hints == [.passObserved])
    }

    @Test("Log summary detects rendering installer crash and WoW64 hints")
    func logSummaryDetectsRenderingInstallerCrashAndWoW64Hints() {
        let summary = LogService.summarizeLog("""
        wine: Unhandled page fault on read access to 0000000000000000 at address 000000014018B485, starting debugger...
        [0617/025442.730:ERROR:gpu_channel_manager.cc(895)] ContextResult::kFatalFailure: Failed to create shared context for virtualization.
        [0617/025442.731:ERROR:shared_image_stub.cc(439)] SharedImageStub: unable to create context
        HYPHelper --disable-direct-write --disable-remote-fonts --disable-features=DWriteFontProxy,FontSrcLocalMatching
        Renderer produced no frame and the user reports a black screen / blank window.
        WARN text_rendering missing glyphs detected in selected GDI font
        WARN window_input focus mismatch and click messages not observed
        msiexec installer failed with code 1603
        command=wine msiexec.exe /i C:\\putty.msi /qn
        ShellExecuteEx failed: File not found.
        32-bit Windows installer requires a WoW64-capable engine
        Operation timed out after 5000 milliseconds with 0 bytes received
        """)

        #expect(summary.health == .failed)
        #expect(summary.hints.contains(.wineCrash))
        #expect(summary.hints.contains(.cefRenderingIssue))
        #expect(summary.hints.contains(.gpuRenderingIssue))
        #expect(summary.hints.contains(.fontRenderingIssue))
        #expect(summary.hints.contains(.blankWindowIssue))
        #expect(summary.hints.contains(.windowInputIssue))
        #expect(summary.hints.contains(.installerIssue))
        #expect(summary.hints.contains(.msiRuntimeIssue))
        #expect(summary.hints.contains(.win32CompatibilityIssue))
        #expect(summary.hints.contains(.timeout))
    }

    @Test("Log summary keeps explicit font rendering issues visible even when a pass marker exists")
    func logSummaryKeepsExplicitFontRenderingIssuesVisibleWithPassMarker() {
        let summary = LogService.summarizeLog("""
        PASS console
        HYPHelper --disable-direct-write --disable-features=DWriteFontProxy
        missing glyphs detected in selected GDI font
        """)

        #expect(summary.health == .attention)
        #expect(summary.hints.contains(.fontRenderingIssue))
        #expect(summary.hints.contains(.blankWindowIssue))
        #expect(summary.hints.contains(.passObserved))
    }

    @Test("Log summary treats ordinary DirectWrite probe output as passed")
    func logSummaryTreatsOrdinaryDirectWriteProbeOutputAsPassed() {
        let summary = LogService.summarizeLog("""
        PASS text_rendering
        MacWin DirectWrite Chinese text metrics width=475.66 height=24.14
        """)

        #expect(summary.health == .passed)
        #expect(summary.hints == [.passObserved])
    }

    @Test("Passed Vulkan probe ignores unsupported optional extension warnings")
    func passedVulkanProbeIgnoresUnsupportedOptionalExtensionWarnings() {
        let summary = LogService.summarizeLog("""
        probeAssetId=vulkan
        probe=vulkan
        0024:warn:vulkan:init_physical_device Extension "VK_EXT_metal_objects" is not supported.
        0024:warn:vulkan:init_physical_device Extension "VK_GOOGLE_display_timing" is not supported.
        device[0]=Apple M3 Max api=1.2.290
        PASS vulkan
        exitCode=0
        """)

        #expect(summary.warningCount == 0)
        #expect(summary.passCount == 1)
        #expect(summary.health == .passed)
    }

    @Test("Failed Vulkan probe keeps unsupported extension warnings visible")
    func failedVulkanProbeKeepsUnsupportedExtensionWarningsVisible() {
        let summary = LogService.summarizeLog("""
        probeAssetId=vulkan
        probe=vulkan
        0024:warn:vulkan:init_physical_device Extension "VK_EXT_metal_objects" is not supported.
        vkCreateInstance=-8
        FAIL vulkan
        exitCode=1
        """)

        #expect(summary.warningCount == 1)
        #expect(summary.failCount > 0)
        #expect(summary.health == .failed)
    }

    @Test("Log summary detects WOW64 SEH dispatch failures")
    func logSummaryDetectsWOW64SEHDispatchFailures() throws {
        let text = """
        command=wine C:\\Program Files (x86)\\WinSCP\\WinSCP.exe
        01e4:trace:seh:dispatch_exception code=c0000005 (EXCEPTION_ACCESS_VIOLATION) flags=0 addr=7BC51139
        01e4:err:seh:NtRaiseException Exception frame is not in stack limits => unable to dispatch exception.
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .failed)
        #expect(summary.hints.contains(.wineCrash))
        #expect(summary.hints.contains(.win32CompatibilityIssue))

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinWOW64SEH-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let logURL = root.appendingPathComponent("winscp-client-launch.log")
        try Data(text.utf8).write(to: logURL)
        let item = LogFileItem(
            name: logURL.lastPathComponent,
            url: logURL,
            modifiedAt: Date(timeIntervalSince1970: 525),
            byteCount: Int64(text.utf8.count),
            summary: summary
        )
        let report = LogService.issueReport(logs: [item])

        #expect(report.topIssues.contains { $0.id == "win32-wow64" })
        #expect(report.recentFailures.first?.probableIssueIds.contains("win32-wow64") == true)
        #expect(report.recentFailures.first?.evidenceSnippets.contains { $0.localizedCaseInsensitiveContains("unable to dispatch exception") } == true)
    }

    @Test("Newer WinSCP smoke suppresses older WOW64 crash experiments")
    func newerWinSCPSmokeSuppressesOlderWOW64CrashExperiments() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinWinSCPSupersession-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let oldText = """
        startedAt=2026-07-13T13:48:09Z
        exe=C:\\Program Files (x86)\\WinSCP\\WinSCP.exe
        0024:err:seh:NtRaiseException Exception frame is not in stack limits => unable to dispatch exception.
        endedAt=2026-07-13T13:48:14Z
        exitCode=1
        """
        let newText = """
        startedAt=2026-07-13T19:55:00Z
        exe=C:\\Program Files (x86)\\WinSCP\\WinSCP.exe
        RosettaRuntimex87 built Jul 13 2026 22:44:53
        smokeOutcome=keptAlive
        TIMEOUT after 25s; sending SIGTERM
        endedAt=2026-07-13T19:55:25Z
        exitCode=15
        """
        let oldURL = root.appendingPathComponent("winscp656-gui-live-seh.log")
        let newURL = root.appendingPathComponent("winscp-client-launch.log")
        try Data(oldText.utf8).write(to: oldURL)
        try Data(newText.utf8).write(to: newURL)

        let old = LogFileItem(
            name: oldURL.lastPathComponent,
            url: oldURL,
            modifiedAt: Date(timeIntervalSince1970: 100),
            byteCount: Int64(oldText.utf8.count),
            summary: LogService.summarizeLog(oldText)
        )
        let newer = LogFileItem(
            name: newURL.lastPathComponent,
            url: newURL,
            modifiedAt: Date(timeIntervalSince1970: 200),
            byteCount: Int64(newText.utf8.count),
            summary: LogService.summarizeLog(newText)
        )

        #expect(old.summary.health == .failed)
        #expect(newer.summary.health == .passed)

        let report = LogService.issueReport(logs: [newer, old])

        #expect(report.logsAnalyzed == 1)
        #expect(report.failedLogCount == 0)
        #expect(report.passedLogCount == 1)
        #expect(report.recentFailures.isEmpty)
        #expect(report.topIssues.isEmpty)
    }

    @Test("Log issue report detects PortableApps platform SEH failures")
    func logIssueReportDetectsPortableAppsPlatformSEHFailures() throws {
        let text = """
        exe=C:\\PortableApps\\PortableApps.com\\PortableAppsPlatform.exe
        command=wine C:\\PortableApps\\PortableApps.com\\PortableAppsPlatform.exe
        0024:trace:seh:dispatch_exception code=c0000029 (unknown) flags=1 addr=7BCF0898
        0024:trace:loaddll:build_module Loaded L"C:\\\\windows\\\\system32\\\\wow64.dll" at 00006FFFFC240000: builtin
        0024:trace:loaddll:build_module Loaded L"C:\\\\windows\\\\system32\\\\wow64cpu.dll" at 000000007BC50000: builtin
        wine: Unhandled page fault on read access to 01508350 at address 00409BFE (thread 0024), starting debugger...
        0024:trace:seh:dispatch_exception code=c0000005 (EXCEPTION_ACCESS_VIOLATION) flags=0 addr=00000000
        0024:trace:seh:dispatch_exception eip=00000000 esp=0022f144 ebp=0022fef0 eflags=00200206
        0024:err:seh:NtRaiseException Exception frame is not in stack limits => unable to dispatch exception.
        smokeOutcome=earlyExit
        exitCode=41
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .failed)
        #expect(summary.hints.contains(.wineCrash))
        #expect(summary.hints.contains(.win32CompatibilityIssue))
        #expect(summary.hints.contains(.portableAppsSEHIssue))

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinPortableAppsSEH-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let logURL = root.appendingPathComponent("portableapps-platform-launch.log")
        try Data(text.utf8).write(to: logURL)
        let item = LogFileItem(
            name: logURL.lastPathComponent,
            url: logURL,
            modifiedAt: Date(timeIntervalSince1970: 545),
            byteCount: Int64(text.utf8.count),
            summary: summary
        )
        let report = LogService.issueReport(logs: [item])

        #expect(report.topIssues.contains { $0.id == "portableapps-seh" })
        let issue = try #require(report.topIssues.first { $0.id == "portableapps-seh" })
        #expect(issue.recommendedActions.contains { $0.contains("ROSETTA_X87_PATH") })
        #expect(issue.recommendedActions.contains { $0.localizedCaseInsensitiveContains("PortableAppsBackup.exe") })
        #expect(issue.recommendedActions.contains { $0.localizedCaseInsensitiveContains("clean prefix") })
        #expect(report.recentFailures.first?.probableIssueIds.contains("portableapps-seh") == true)
        #expect(report.recentFailures.first?.probeAssetIds.contains("tls-winhttp-win32") == true)
        #expect(report.recentFailures.first?.evidenceSnippets.contains { $0.localizedCaseInsensitiveContains("PortableAppsPlatform.exe") } == true)
        #expect(report.recentFailures.first?.evidenceSnippets.contains { $0.localizedCaseInsensitiveContains("c0000029") } == true)
    }

    @Test("Log summary detects terse PortableApps platform exit 41")
    func logSummaryDetectsTersePortableAppsPlatformExit41() throws {
        let text = """
        exe=C:\\PortableApps\\PortableApps.com\\PortableAppsPlatform.exe
        command=wine C:\\PortableApps\\PortableApps.com\\PortableAppsPlatform.exe
        smokeOutcome=earlyExit
        exitCode=41
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .failed)
        #expect(summary.hints.contains(.wineCrash))
        #expect(summary.hints.contains(.win32CompatibilityIssue))
        #expect(summary.hints.contains(.portableAppsSEHIssue))
    }

    @Test("Log summary detects JASP EngineSync IPC fail-fast")
    func logSummaryDetectsJASPEngineSyncIPCFailFast() throws {
        let text = """
        Desktop:\tEngineSync::enginesPrepareForData!
        Desktop:\tEngineSync::enginesReceiveNewData!
        0024:fixme:file:NtLockFile I/O completion on lock not implemented yet
        0024:err:seh:NtRaiseException Unhandled exception code c0000409 flags 1 addr 0x6ffffc06be08
        JASP-IPC-32_heartbeat
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .failed)
        #expect(summary.hints.contains(.jaspEngineIpcIssue))
        #expect(summary.hints.contains(.wineCrash))

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinJASPEngineIPC-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let logURL = root.appendingPathComponent("jasp-stats-launch.log")
        try Data(text.utf8).write(to: logURL)
        let item = LogFileItem(
            name: logURL.lastPathComponent,
            url: logURL,
            modifiedAt: Date(timeIntervalSince1970: 535),
            byteCount: Int64(text.utf8.count),
            summary: summary
        )
        let report = LogService.issueReport(logs: [item])

        #expect(report.topIssues.contains { $0.id == "jasp-engine-ipc" })
        #expect(report.recentFailures.first?.probableIssueIds.contains("jasp-engine-ipc") == true)
        #expect(report.recentFailures.first?.probeAssetIds.contains("jasp-boost-ipc") == true)
        #expect(report.recentFailures.first?.probeAssetIds.contains("ipc-file-mapping") == true)
        #expect(report.recentFailures.first?.probeAssetIds.contains("window-input") == true)
        #expect(report.recentFailures.first?.evidenceSnippets.contains { $0.localizedCaseInsensitiveContains("enginesync::enginesreceivenewdata") } == true)
        #expect(report.recentFailures.first?.evidenceSnippets.contains { $0.localizedCaseInsensitiveContains("c0000409") } == true)
    }

    @Test("Log summary treats passed IPC file mapping probe as healthy")
    func logSummaryTreatsPassedIPCFileMappingProbeAsHealthy() {
        let summary = LogService.summarizeLog("""
        probe=ipc_file_mapping
        ipc.dir=C:\\users\\tester\\AppData\\Local\\Temp\\MacWinIpcProbe
        mapping.path=C:\\users\\tester\\AppData\\Local\\Temp\\MacWinIpcProbe\\JASP-IPC-32_0 size=4096 marker=0x4d574950 observed=0x4d574950
        mapping.path=C:\\users\\tester\\AppData\\Local\\Temp\\MacWinIpcProbe\\JASP-IPC-32_MasterToSlave size=8388608 marker=0x4d575331 observed=0x4d575331
        lock.first=acquired
        lock.second=blocked error=33
        lock.first=released
        lock.second_after_release=acquired
        heartbeat.path=C:\\users\\tester\\AppData\\Local\\Temp\\MacWinIpcProbe\\JASP-IPC-32_heartbeat written=5
        mutex.wait=0
        PASS ipc_file_mapping
        smokeOutcome=earlyExit
        exitCode=0
        """)

        #expect(summary.health == .passed)
        #expect(summary.hints == [.passObserved])
        #expect(!summary.hints.contains(.jaspEngineIpcIssue))
        #expect(!summary.hints.contains(.wineCrash))
    }

    @Test("Log summary treats completed JASP startup and zero-count diagnostics as healthy")
    func logSummaryTreatsCompletedJASPStartupAndZeroCountDiagnosticsAsHealthy() {
        let summary = LogService.summarizeLog("""
        == MacWin software smoke ==
        id=jasp-stats
        phase=launch
        Desktop:\tEngineSync::enginesReceiveNewData!
        Desktop:\tCreating JASP-IPC-32_0
        Desktop:\tJASP Desktop started and Engines initalized.
        Desktop:\tQML Initialized!
        Desktop:\tMainWindow::resultsPageLoaded()
        [32:296:ERROR:gpu_channel_manager.cc(966)] Failed to create GLES3 context, fallback to GLES2.
        [32:296:ERROR:gpu_channel_manager.cc(977)] ContextResult::kFatalFailure: Failed to create shared context for virtualization.
        Desktop:\tLoading Upgrades.qml had the following std:runtime_error: 'Upgrades.qml is missing' this will be ignored!
        trace.failFastC0000409Count=0
        trace.ntLockFileFixmeCount=0
        trace.boostInterprocessExceptionCount=0
        trace.hasSehOrExceptionEvidence=no
        seen=TIMEOUT after
        jaspTimeout.hasDesktopStartedMarker=yes
        jaspTimeout.hasQmlMilestone=yes
        jaspTimeout.samplePreview:
          Exception Type: EXC_BAD_ACCESS
          305 Thread_2475909: com.apple.rosetta.exceptionserver
        jaspIpcSnapshot.phase=launch-timeout-before-cleanup
        ## timeout diagnostics
        source.boundary=The launch log reaches JASP Desktop started and initializes the QML application UI.
        smokeOutcome=keptAlive
        exitCode=124
        """)

        #expect(summary.health == .passed)
        #expect(summary.hints == [.passObserved])
        #expect(!summary.hints.contains(.jaspEngineIpcIssue))
        #expect(!summary.hints.contains(.wineCrash))
        #expect(!summary.hints.contains(.timeout))
    }

    @Test("Log summary detects JASP Boost interprocess boundary before engine create")
    func logSummaryDetectsJASPBoostInterprocessBoundaryBeforeEngineCreate() throws {
        let text = """
        == MacWin software smoke ==
        id=jasp-stats
        phase=launch
        QtWebEngineQuick initialized
        Desktop:\tDataSetPackage::endLoadingData
        Desktop:\tEngineSync::enginesReceiveNewData!
        0024:trace:seh:cxx_frame_handler4     0: flags 0 type 00000001419CAD20 {vtable=0000000141851878 name=.?AVinterprocess_exception@interprocess@boost@@ ()}
        trace.ipcTracePreset=1
        trace.jaspIpcMentionCount=4
        trace.ntLockFileFixmeCount=1
        trace.boostInterprocessExceptionCount=3
        trace.hasJASPEngineCreateEvidence=no
        trace.hasLaterQmlOrDesktopMilestone=no
        ended=2026-06-29T05:08:17Z
        exitCode=121
        note=JASP reached DataSetPackage::endLoadingData -> EngineSync::enginesReceiveNewData, then emitted Boost interprocess exception evidence before any Engine # or JASPEngine create marker.
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .failed)
        #expect(summary.hints.contains(.jaspEngineIpcIssue))
        #expect(!summary.hints.contains(.jaspQrcQmlResourceIssue))

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinJASPBoostBoundary-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let logURL = root.appendingPathComponent("jasp-stats-launch.log")
        try Data(text.utf8).write(to: logURL)
        let item = LogFileItem(
            name: logURL.lastPathComponent,
            url: logURL,
            modifiedAt: Date(timeIntervalSince1970: 367),
            byteCount: Int64(text.utf8.count),
            summary: summary
        )
        let report = LogService.issueReport(logs: [item])

        #expect(report.topIssues.contains { $0.id == "jasp-engine-ipc" })
        let issue = try #require(report.topIssues.first { $0.id == "jasp-engine-ipc" })
        #expect(issue.detail.localizedCaseInsensitiveContains("managed_shared_memory"))
        #expect(issue.detail.localizedCaseInsensitiveContains("before any JASPEngine create marker"))
        #expect(issue.recommendedActions.contains { $0.localizedCaseInsensitiveContains("MACWIN_JASP_IPC_TRACE=1") })
        #expect(issue.recommendedActions.contains { $0.localizedCaseInsensitiveContains("ipc-file-mapping") })
        #expect(issue.recommendedActions.contains { $0.localizedCaseInsensitiveContains("jasp-boost-ipc") })
        #expect(issue.recommendedActions.contains { $0.localizedCaseInsensitiveContains("interprocess_mutex") })
        #expect(report.recentFailures.first?.probableIssueIds.contains("jasp-engine-ipc") == true)
        #expect(report.recentFailures.first?.probeAssetIds.contains("jasp-boost-ipc") == true)
        #expect(report.recentFailures.first?.probeAssetIds.contains("ipc-file-mapping") == true)
        #expect(report.recentFailures.first?.evidenceSnippets.contains { $0.localizedCaseInsensitiveContains("interprocess_exception") } == true)
        #expect(report.recentFailures.first?.evidenceSnippets.contains { $0.localizedCaseInsensitiveContains("trace.jaspipcmentioncount") } == true)
    }

    @Test("Log summary detects JASP qrc QML resource crashes")
    func logSummaryDetectsJASPQrcQMLResourceCrashes() throws {
        let text = """
        QtWebEngineQuick initialized
        Desktop:\tEngineSync::enginesPrepareForData!
        Desktop:\tEngineSync::enginesReceiveNewData!
        Could not load QML: qrc:/components/JASP/Theme/Theme.qml
        Could not load QML: qrc:/components/JASP/Widgets/MainWindow.qml
        wine: Unhandled page fault on read access to 0000000000000014 at address 00000001402C766A (thread 0440), starting debugger...
        WineDbg attached to pid 043c
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .failed)
        #expect(summary.hints.contains(.jaspQrcQmlResourceIssue))
        #expect(summary.hints.contains(.wineCrash))
        #expect(!summary.hints.contains(.jaspEngineIpcIssue))

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinJASPQrcQML-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let logURL = root.appendingPathComponent("jasp-stats-launch.log")
        try Data(text.utf8).write(to: logURL)
        let item = LogFileItem(
            name: logURL.lastPathComponent,
            url: logURL,
            modifiedAt: Date(timeIntervalSince1970: 536),
            byteCount: Int64(text.utf8.count),
            summary: summary
        )
        let report = LogService.issueReport(logs: [item])

        #expect(report.topIssues.contains { $0.id == "jasp-qrc-qml" })
        let issue = try #require(report.topIssues.first { $0.id == "jasp-qrc-qml" })
        #expect(issue.detail.localizedCaseInsensitiveContains("software OpenGL/RHI"))
        #expect(issue.detail.localizedCaseInsensitiveContains("resource readback"))
        #expect(issue.detail.localizedCaseInsensitiveContains("qml-resource-probe"))
        #expect(issue.recommendedActions.contains { $0.localizedCaseInsensitiveContains("qml-resource-probe") })
        #expect(issue.recommendedActions.contains { $0.localizedCaseInsensitiveContains("Stop tuning generic graphics flags") })
        #expect(report.recentFailures.first?.probableIssueIds.contains("jasp-qrc-qml") == true)
        #expect(report.recentFailures.first?.probeAssetIds.contains("window-input") == true)
        #expect(report.recentFailures.first?.evidenceSnippets.contains { $0.localizedCaseInsensitiveContains("qrc:/components/jasp/") } == true)
    }

    @Test("Log summary detects JASP file fallback QML resource crashes")
    func logSummaryDetectsJASPFileFallbackQMLResourceCrashes() throws {
        let text = """
        QtWebEngineQuick initialized
        Desktop:\tEngineSync::enginesPrepareForData!
        Desktop:\tEngineSync::enginesReceiveNewData!
        Could not load QML: file:///C:/Program Files/JASP/components/JASP/Theme/Theme.qml
        Could not load QML: file:///C:/Program Files/JASP/components/JASP/Widgets/MainWindow.qml
        wine: Unhandled page fault on read access to 0000000000000014 at address 00000001402C766A (thread 0024), starting debugger...
        WineDbg attached to pid 0020
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .failed)
        #expect(summary.hints.contains(.jaspQrcQmlResourceIssue))
        #expect(summary.hints.contains(.wineCrash))
        #expect(!summary.hints.contains(.jaspEngineIpcIssue))

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinJASPFileQML-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let logURL = root.appendingPathComponent("jasp-stats-launch.log")
        try Data(text.utf8).write(to: logURL)
        let item = LogFileItem(
            name: logURL.lastPathComponent,
            url: logURL,
            modifiedAt: Date(timeIntervalSince1970: 537),
            byteCount: Int64(text.utf8.count),
            summary: summary
        )
        let report = LogService.issueReport(logs: [item])

        #expect(report.topIssues.contains { $0.id == "jasp-qrc-qml" })
        let issue = try #require(report.topIssues.first { $0.id == "jasp-qrc-qml" })
        #expect(issue.detail.localizedCaseInsensitiveContains("file:/// components fallback"))
        #expect(issue.detail.localizedCaseInsensitiveContains("qml-resource-probe"))
        #expect(report.recentFailures.first?.probableIssueIds.contains("jasp-qrc-qml") == true)
        #expect(report.recentFailures.first?.evidenceSnippets.contains { $0.localizedCaseInsensitiveContains("file:///C:/Program Files/JASP/components/JASP/") } == true)
    }

    @Test("Log summary detects JASP pre-QML load hangs")
    func logSummaryDetectsJASPPreQMLLoadHangs() throws {
        let text = """
        == MacWin software smoke ==
        id=jasp-stats
        phase=launch
        QtWebEngineQuick initialized
        Desktop:\tEngineSync::enginesPrepareForData!
        Desktop:\tEngineSync::enginesReceiveNewData!
        TIMEOUT after 45s; sending SIGTERM to 65645
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .failed)
        #expect(summary.hints.contains(.jaspQmlInitializationHangIssue))
        #expect(!summary.hints.contains(.jaspQrcQmlResourceIssue))

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinJASPQmlHang-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let logURL = root.appendingPathComponent("jasp-stats-launch.log")
        try Data(text.utf8).write(to: logURL)
        let item = LogFileItem(
            name: logURL.lastPathComponent,
            url: logURL,
            modifiedAt: Date(timeIntervalSince1970: 538),
            byteCount: Int64(text.utf8.count),
            summary: summary
        )
        let report = LogService.issueReport(logs: [item])

        #expect(report.topIssues.contains { $0.id == "jasp-qml-init-hang" })
        let issue = try #require(report.topIssues.first { $0.id == "jasp-qml-init-hang" })
        #expect(issue.detail.localizedCaseInsensitiveContains("process liveness is not sufficient"))
        #expect(issue.detail.localizedCaseInsensitiveContains("DataSetPackage::endLoadingData"))
        #expect(issue.detail.localizedCaseInsensitiveContains("before any JASPEngine start marker"))
        #expect(issue.recommendedActions.contains { $0.localizedCaseInsensitiveContains("runtime-state-postlaunch-probe") })
        #expect(issue.recommendedActions.contains { $0.localizedCaseInsensitiveContains("sample thread summaries") })
        #expect(issue.recommendedActions.contains { $0.localizedCaseInsensitiveContains("spawn-trace-probe") })
        #expect(issue.recommendedActions.contains { $0.localizedCaseInsensitiveContains("MACWIN_JASP_CONSTRUCTOR_ISOLATION=1") })
        #expect(issue.recommendedActions.contains { $0.localizedCaseInsensitiveContains("MACWIN_JASP_WEBENGINE_MODE=single-process") })
        #expect(issue.recommendedActions.contains { $0.localizedCaseInsensitiveContains("constructor-boundary-postlaunch-probe") })
        #expect(issue.recommendedActions.contains { $0.localizedCaseInsensitiveContains("EngineSync::enginesReceiveNewData") })
        #expect(report.recentFailures.first?.probableIssueIds.contains("jasp-qml-init-hang") == true)
    }

    @Test("Log summary detects JASP constructor-tail early exits")
    func logSummaryDetectsJASPConstructorTailEarlyExits() throws {
        let text = """
        == MacWin software smoke ==
        id=jasp-stats
        phase=launch
        QtWebEngineQuick initialized
        Desktop:\tDataSetPackage::endLoadingData
        Desktop:\tEngineSync::enginesReceiveNewData!
        ended=2026-06-29T04:48:56Z
        exitCode=120
        note=JASP exited after the initial DataSetPackage::endLoadingData -> EngineSync::enginesReceiveNewData handoff, before Desktop started, loadQML, or any Engine # marker. Treat this as a MainWindow constructor-tail boundary rather than an engine-child IPC failure.
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .failed)
        #expect(summary.hints.contains(.jaspQmlInitializationHangIssue))
        #expect(!summary.hints.contains(.jaspEngineIpcIssue))

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinJASPConstructorTail-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let logURL = root.appendingPathComponent("jasp-stats-launch.log")
        try Data(text.utf8).write(to: logURL)
        let item = LogFileItem(
            name: logURL.lastPathComponent,
            url: logURL,
            modifiedAt: Date(timeIntervalSince1970: 539),
            byteCount: Int64(text.utf8.count),
            summary: summary
        )
        let report = LogService.issueReport(logs: [item])

        #expect(report.topIssues.contains { $0.id == "jasp-qml-init-hang" })
        #expect(report.recentFailures.first?.probableIssueIds.contains("jasp-qml-init-hang") == true)
        #expect(report.recentFailures.first?.probableIssueIds.contains("jasp-engine-ipc") != true)
    }

    @Test("Log summary does not call post-theme JASP timeouts pre-QML load hangs")
    func logSummaryDoesNotCallPostThemeJASPTimeoutsPreQMLLoadHangs() {
        let text = """
        == MacWin software smoke ==
        id=jasp-stats
        phase=launch
        QtWebEngineQuick initialized
        Desktop:\tEngineSync::enginesReceiveNewData!
        Loading Themes
        TIMEOUT after 45s; sending SIGTERM to 65645
        """
        let summary = LogService.summarizeLog(text)

        #expect(!summary.hints.contains(.jaspQmlInitializationHangIssue))
    }

    @Test("Log summary does not call post-EngineSync-return JASP timeouts EngineSync startup hangs")
    func logSummaryDoesNotCallPostEngineSyncReturnJASPTimeoutsStartupHangs() {
        let text = """
        == MacWin software smoke ==
        id=jasp-stats
        phase=launch
        QtWebEngineQuick initialized
        Desktop:\tEngineSync::enginesReceiveNewData!
        JASP Desktop started and Engines initalized.
        TIMEOUT after 45s; sending SIGTERM to 65645
        """
        let summary = LogService.summarizeLog(text)

        #expect(!summary.hints.contains(.jaspQmlInitializationHangIssue))
    }

    @Test("Log summary detects Wine-Mono native runtime crashes")
    func logSummaryDetectsWineMonoNativeRuntimeCrashes() throws {
        let text = """
        command=wine C:\\macwin-portable\\mremoteng-admin\\mRemoteNG\\mRemoteNG.exe
        Native Crash Reporting
        a fatal error in the mono runtime or one of the native libraries
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .failed)
        #expect(summary.hints.contains(.dotnetRuntimeIssue))

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinDotNetRuntime-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let logURL = root.appendingPathComponent("mremoteng-manager-launch.log")
        try Data(text.utf8).write(to: logURL)
        let item = LogFileItem(
            name: logURL.lastPathComponent,
            url: logURL,
            modifiedAt: Date(timeIntervalSince1970: 545),
            byteCount: Int64(text.utf8.count),
            summary: summary
        )
        let report = LogService.issueReport(logs: [item])

        #expect(report.topIssues.contains { $0.id == "dotnet-runtime" })
        #expect(report.recentFailures.first?.probableIssueIds.contains("dotnet-runtime") == true)
        #expect(report.recentFailures.first?.evidenceSnippets.contains { $0.localizedCaseInsensitiveContains("fatal error in the mono runtime") } == true)
    }

    @Test("Log summary detects modern .NET desktop runtime host failures")
    func logSummaryDetectsModernDotNetDesktopRuntimeHostFailures() throws {
        let text = """
        command=wine C:\\macwin-portable\\mremoteng-1782-x64\\mRemoteNG.exe
        You must install .NET to run this application.
        App: C:\\macwin-portable\\mremoteng-1782-x64\\mRemoteNG.exe
        Architecture: x64
        App host version: 10.0.3
        Download the .NET runtime:
        https://aka.ms/dotnet-core-applaunch?missing_runtime=true&arch=x64&rid=win-x64&os=win10&apphost_version=10.0.3
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .failed)
        #expect(summary.hints.contains(.dotnetRuntimeIssue))

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinModernDotNetRuntime-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let logURL = root.appendingPathComponent("mremoteng-1782-x64-launch.log")
        try Data(text.utf8).write(to: logURL)
        let item = LogFileItem(
            name: logURL.lastPathComponent,
            url: logURL,
            modifiedAt: Date(timeIntervalSince1970: 546),
            byteCount: Int64(text.utf8.count),
            summary: summary
        )
        let report = LogService.issueReport(logs: [item])

        #expect(report.topIssues.contains { $0.id == "dotnet-runtime" })
        #expect(report.recentFailures.first?.probableIssueIds.contains("dotnet-runtime") == true)
        #expect(report.recentFailures.first?.evidenceSnippets.contains { $0.localizedCaseInsensitiveContains("download the .net runtime") } == true)
    }

    @Test("Log summary treats dotnet info runtime inventory as success")
    func logSummaryTreatsDotNetInfoRuntimeInventoryAsSuccess() {
        let text = """
        Host:
          Version:      10.0.9
          Architecture: x64

        .NET SDKs installed:
          No SDKs were found.

        .NET runtimes installed:
          Microsoft.NETCore.App 10.0.9 [C:\\macwin-runtimes\\dotnet-desktop-10-x64\\shared\\Microsoft.NETCore.App]
          Microsoft.WindowsDesktop.App 10.0.9 [C:\\macwin-runtimes\\dotnet-desktop-10-x64\\shared\\Microsoft.WindowsDesktop.App]

        global.json file:
          Not found

        Download .NET:
          https://aka.ms/dotnet/download
        """

        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .quiet)
        #expect(!summary.hints.contains(.dotnetRuntimeIssue))
        #expect(summary.failCount == 0)
    }

    @Test("Log summary classifies mRemoteNG update check SSL failures as network TLS")
    func logSummaryClassifiesMRemoteNGUpdateCheckSSLFailures() throws {
        let text = """
        command=wine C:\\macwin-portable\\mremoteng-1782-x64\\mRemoteNG.exe /reset /noreconnect
        Error fetching latest version: The SSL connection could not be established, see inner exception.
        TIMEOUT after 30s; sending SIGTERM to 50730
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .failed)
        #expect(summary.hints.contains(.networkTLSIssue))
        #expect(!summary.hints.contains(.dotnetRuntimeIssue))

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinMRemoteNGUpdateTLS-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let logURL = root.appendingPathComponent("mremoteng-1782-x64-launch.log")
        try Data(text.utf8).write(to: logURL)
        let item = LogFileItem(
            name: logURL.lastPathComponent,
            url: logURL,
            modifiedAt: Date(timeIntervalSince1970: 547),
            byteCount: Int64(text.utf8.count),
            summary: summary
        )
        let report = LogService.issueReport(logs: [item])

        #expect(report.topIssues.contains { $0.id == "network-tls" })
        #expect(report.recentFailures.first?.probableIssueIds.contains("network-tls") == true)
        #expect(report.recentFailures.first?.evidenceSnippets.contains { $0.localizedCaseInsensitiveContains("latest version") } == true)
    }

    @Test("Log summary ignores successful diagnostics timeout metadata")
    func logSummaryIgnoresSuccessfulDiagnosticsTimeoutMetadata() throws {
        let text = """
        ----- MacWin diagnostics -----
        startedAt=2026-07-02T14:36:25Z
        endedAt=2026-07-02T14:36:29Z
        durationSeconds=4.071
        timeoutSeconds=120.000
        timedOut=false
        exitCode=0
        probeAssetId=tls-winhttp-win32
        env.MACWIN_WINHTTP_IGNORE_UNKNOWN_CA=1
        ------------------------------

        exit=0 log=/Users/a1-6/project/Mac-Win/refs/exe-tests/logs/10_tls_winhttp_probe_win32.single.log
        0024:trace:winhttp:get_header_index returning -1
        probe=tls_winhttp
        http_status=200
        read_bytes=421
        PASS tls_winhttp
        PASS tls_winhttp_win32

        ----- MacWin diagnostics result -----
        timedOut=false
        exitCode=0
        ------------------------------------
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .passed)
        #expect(summary.failCount == 0)
        #expect(summary.errorCount == 0)
        #expect(!summary.hints.contains(.timeout))
        #expect(!summary.hints.contains(.networkTLSIssue))

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinPassedDiagnosticsMetadata-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let logURL = root.appendingPathComponent("diagnostics-high-performance-win11-tls-winhttp-win32-1234ABCD.log")
        try Data(text.utf8).write(to: logURL)
        let item = LogFileItem(
            name: logURL.lastPathComponent,
            url: logURL,
            modifiedAt: Date(timeIntervalSince1970: 551),
            byteCount: Int64(text.utf8.count),
            summary: summary
        )
        let report = LogService.issueReport(logs: [item])

        #expect(report.failedLogCount == 0)
        #expect(report.attentionLogCount == 0)
        #expect(report.passedLogCount == 1)
        #expect(report.topIssues.isEmpty)
        #expect(report.recentFailures.isEmpty)
    }

    @Test("Log summary classifies mRemoteNG early GUI exit as attention")
    func logSummaryClassifiesMRemoteNGEarlyGUIExitAsAttention() throws {
        let text = """
        command=wine C:\\macwin-portable\\mremoteng-1782-x64\\mRemoteNG.exe /reset /noreconnect
        env.MACWIN_COMPAT_PROFILE=mremoteng-1782-x64
        env.DOTNET_ROOT=C:\\macwin-runtimes\\dotnet-desktop-10-x64
        statusAfter45s=0
        processes:
        finalExit=0
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .attention)
        #expect(summary.hints.contains(.mRemoteNGEarlyExitIssue))
        #expect(!summary.hints.contains(.dotnetRuntimeIssue))

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinMRemoteNGEarlyExit-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let logURL = root.appendingPathComponent("mremoteng-1782-x64-smoke.log")
        try Data(text.utf8).write(to: logURL)
        let item = LogFileItem(
            name: logURL.lastPathComponent,
            url: logURL,
            modifiedAt: Date(timeIntervalSince1970: 548),
            byteCount: Int64(text.utf8.count),
            summary: summary
        )
        let report = LogService.issueReport(logs: [item])

        #expect(report.topIssues.contains { $0.id == "mremoteng-early-exit" })
        #expect(report.recentFailures.first?.health == LogHealth.attention.rawValue)
        #expect(report.recentFailures.first?.probableIssueIds.contains("mremoteng-early-exit") == true)
        #expect(report.recentFailures.first?.evidenceSnippets.contains { $0.localizedCaseInsensitiveContains("statusAfter45s=0") } == true)
    }

    @Test("Log summary ignores WoW64 engine path when classifying mRemoteNG early exit")
    func logSummaryIgnoresWOW64EnginePathForMRemoteNGEarlyExit() {
        let text = """
        cmd=/usr/bin/arch -x86_64 /Users/a1-6/Library/Application Support/MacWin/Engines/wine-11.11-wow64-game/build/loader/wine C:\\macwin-portable\\mremoteng-1782-x64\\mRemoteNG.exe /reset /noreconnect
        env.MACWIN_COMPAT_PROFILE=mremoteng-1782-x64
        statusAfter45s=0
        finalExit=0
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .attention)
        #expect(summary.hints.contains(.mRemoteNGEarlyExitIssue))
        #expect(!summary.hints.contains(.win32CompatibilityIssue))
    }

    @Test("Log summary treats managed smoke timeout as kept alive")
    func logSummaryTreatsManagedSmokeTimeoutAsKeptAlive() {
        let text = """
        ----- MacWin launch -----
        exe=C:\\macwin-portable\\mremoteng-1782-x64\\mRemoteNG.exe
        smokeOutcome=keptAlive

        TIMEOUT after 30s; sending SIGTERM to 71671
        ----- MacWin result -----
        exitCode=-15
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .passed)
        #expect(summary.passCount == 1)
        #expect(summary.hints.contains(.passObserved))
        #expect(!summary.hints.contains(.timeout))
        #expect(!summary.hints.contains(.mRemoteNGEarlyExitIssue))
    }

    @Test("Log summary ignores managed smoke cleanup timeout after kept-alive outcome")
    func logSummaryIgnoresManagedSmokeCleanupTimeoutAfterKeptAliveOutcome() {
        let text = """
        ----- MacWin launch -----
        exe=C:\\Program Files\\Steam\\Steam.exe
        env.MACWIN_COMPAT_PROFILE=steam-client
        2026-07-24 22:10:54.204 wine[70389:3912653] TSM AdjustCapsLockLEDForKeyTransitionHandling - _ISSetPhysicalKeyboardCapsLockLED Inhibit
        2026-07-24 22:10:54.217 wine[70389:3912653] error messaging the mach port for IMKCFRunLoopWakeUpReliable
        smokeOutcome=keptAlive

        TIMEOUT after 90s; sending SIGTERM to 70354
        wineserver crashed, please enable coredumps (ulimit -c unlimited) and restart.
        Requesting wineserver -k for smoke timeout cleanup
        wineserverCleanup=timedOut
        runtimeCleanupRequested=3
        runtimeCleanupStopped=70364,70366,70368
        ----- MacWin result -----
        exitCode=15
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .passed)
        #expect(summary.passCount == 1)
        #expect(summary.errorCount == 0)
        #expect(summary.failCount == 0)
        #expect(summary.hints == [.passObserved])
    }

    @Test("Log summary keeps kept-alive Wine crashes visible as attention")
    func logSummaryKeepsKeptAliveWineCrashesVisibleAsAttention() {
        let text = """
        ----- MacWin launch -----
        exe=C:\\Program Files\\MuseScore 4\\bin\\MuseScore4.exe
        env.MACWIN_COMPAT_PROFILE=musescore-studio
        wine: Unhandled page fault on read access to 0000000000000000 at address 000000014018B485 (thread 034c), starting debugger...
        smokeOutcome=keptAlive

        TIMEOUT after 45s; sending SIGTERM to 29260
        ----- MacWin result -----
        exitCode=15
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .attention)
        #expect(summary.passCount == 1)
        #expect(summary.hints.contains(.wineCrash))
        #expect(summary.hints.contains(.passObserved))
        #expect(!summary.hints.contains(.timeout))
    }

    @Test("Log summary treats PortableApps uxtheme kept-alive page fault as pass")
    func logSummaryTreatsPortableAppsUxthemeKeptAlivePageFaultAsPass() {
        let text = """
        ----- MacWin launch -----
        exe=C:\\PortableApps\\PortableApps.com\\PortableAppsPlatform.exe
        env.WINEDLLOVERRIDES=winemenubuilder.exe=d;uxtheme=d
        env.MACWIN_COMPAT_PROFILE=portableapps-platform
        wine: Unhandled page fault on read access to 014C8418 at address 00409BFE (thread 0024), starting debugger...
        smokeOutcome=keptAlive

        TIMEOUT after 12s; sending SIGTERM to 55017
        0138:fixme:thread:get_thread_times not implemented on this platform
        0138:err:winedbg:dbg_handle_debug_event Unknown process
        Requesting wineserver -k for smoke timeout cleanup
        wineserverCleanup=completed
        ----- MacWin result -----
        exitCode=15
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .passed)
        #expect(summary.passCount == 1)
        #expect(summary.failCount == 0)
        #expect(summary.errorCount == 0)
        #expect(summary.hints.contains(.passObserved))
        #expect(!summary.hints.contains(.wineCrash))
    }

    @Test("Log summary accepts verified JASP results page without Desktop started line")
    func logSummaryAcceptsVerifiedJASPResultsPageMilestone() {
        let summary = LogService.summarizeLog("""
        == MacWin software smoke ==
        id=jasp-stats
        phase=launch
        Desktop:\tEngineSync::enginesReceiveNewData!
        Desktop:\tMsg from Qt Warning: <Unknown File>: QML WebEngineProfile: Please use WebEngineProfilePrototype for profile creation from 6.9, as this function will be deprecated in the future releases
        [32:296:ERROR:gpu_channel_manager.cc(966)] Failed to create GLES3 context, fallback to GLES2.
        [32:296:ERROR:gpu_channel_manager.cc(977)] ContextResult::kFatalFailure: Failed to create shared context for virtualization.
        Desktop:\tMainWindow::resultsPageLoaded()
        smokeOutcome=keptAlive
        jaspStartupMilestone=passed
        jaspStartupQMLInitialized=yes
        jaspStartupResultsPageLoaded=yes
        exitCode=124
        """)

        #expect(summary.health == .passed)
        #expect(summary.hints == [.passObserved])
        #expect(!summary.hints.contains(.jaspQmlInitializationHangIssue))
        #expect(!summary.hints.contains(.cefRenderingIssue))
        #expect(!summary.hints.contains(.gpuRenderingIssue))
    }

    @Test("Log summary accepts completed JASP statistical unit workload")
    func logSummaryAcceptsCompletedJASPStatisticalWorkload() {
        let summary = LogService.summarizeLog("""
        == MacWin software smoke ==
        id=jasp-stats
        phase=launch
        Desktop:\tQML Initialized!
        Engine#0:\tjaspEngine started and is #0
        Desktop:\tResultstatus of analysis was complete and it will now be processed.
        Old result conversion:
        New result conversion:
        The results are different...
        [32:296:ERROR:gpu_channel_manager.cc(966)] Failed to create GLES3 context, fallback to GLES2.
        [32:296:ERROR:gpu_channel_manager.cc(977)] ContextResult::kFatalFailure: Failed to create shared context for virtualization.
        smokeOutcome=passed
        exitCode=0
        """)

        #expect(summary.health == .passed)
        #expect(summary.hints == [.passObserved])
        #expect(!summary.hints.contains(.jaspEngineIpcIssue))
        #expect(!summary.hints.contains(.gpuRenderingIssue))
    }

    @Test("Log summary ignores managed smoke wineserver cleanup timeout line")
    func logSummaryIgnoresManagedSmokeWineserverCleanupTimeoutLine() {
        let text = """
        ----- MacWin launch -----
        exe=C:\\Program Files (x86)\\SoftMaker FreeOffice 2024\\TextMaker.exe
        env.MACWIN_COMPAT_PROFILE=softmaker-office
        env.MACWIN_DISABLE_WINE_APP_ACTIVATION=1
        smokeOutcome=keptAlive

        TIMEOUT after 20s; sending SIGTERM to 96060
        Requesting wineserver -k for smoke timeout cleanup

        ----- MacWin result -----
        exitCode=15
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .passed)
        #expect(summary.passCount == 1)
        #expect(summary.errorCount == 0)
        #expect(summary.failCount == 0)
        #expect(summary.hints == [.passObserved])
    }

    @Test("Log summary ignores managed CLI watchdog timeout footer")
    func logSummaryIgnoresManagedCLIWatchdogTimeoutFooter() {
        let text = """
        smokeOutcome=keptAlive
        cliWatchdog=timedOut
        cliWatchdogTimeoutSeconds=33.00
        smokeTimeoutSeconds=25.00
        runtimeCleanupRequested=12
        runtimeCleanupStopped=42391,42468
        runtimeCleanupFailed=
        ----- MacWin result -----
        exitCode=15
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .passed)
        #expect(summary.passCount == 1)
        #expect(summary.errorCount == 0)
        #expect(summary.failCount == 0)
        #expect(summary.hints == [.passObserved])
    }

    @Test("Log summary treats kept-alive Qt browser Lsf helper crash as non-blocking")
    func logSummaryTreatsKeptAliveQtBrowserLsfHelperCrashAsNonBlocking() {
        let text = """
        ----- MacWin launch -----
        exe=C:\\macwin-portable\\otter-browser-portable\\otter-browser-win64-weekly120\\otter-browser.exe
        env.MACWIN_COMPAT_PROFILE=qt-browser-software
        env.QT_OPENGL=software
        env.QT_QUICK_BACKEND=software
        wine: failed to start L"C:\\\\windows\\\\syswow64\\\\Lsf.exe": c0000135
        wine: Unhandled page fault on read access to 0000000000000000 at address 000000014018B485 (thread 0348), starting debugger...
        smokeOutcome=keptAlive

        TIMEOUT after 20s; sending SIGTERM to 58629
        Requesting wineserver -k for smoke timeout cleanup
        ----- MacWin result -----
        exitCode=15
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .passed)
        #expect(summary.errorCount == 0)
        #expect(summary.failCount == 0)
        #expect(summary.hints == [.passObserved])
    }

    @Test("Log summary treats kept-alive Lsf helper crash as non-blocking outside browser profiles")
    func logSummaryTreatsKeptAliveLsfHelperCrashAsNonBlockingOutsideBrowserProfiles() {
        let text = """
        ----- MacWin launch -----
        engineId=wine-11.11-wow64-game
        exe=C:\\Program Files\\MuseScore 4\\bin\\MuseScore4.exe
        env.MACWIN_COMPAT_PROFILE=musescore-studio
        wine: failed to start L"C:\\\\windows\\\\syswow64\\\\Lsf.exe": c0000135
        wine: Unhandled page fault on read access to 0000000000000000 at address 000000014018B485 (thread 038c), starting debugger...
        smokeOutcome=keptAlive

        TIMEOUT after 20s; sending SIGTERM to 90937
        Requesting wineserver -k for smoke timeout cleanup
        ----- MacWin result -----
        exitCode=15
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .passed)
        #expect(summary.errorCount == 0)
        #expect(summary.failCount == 0)
        #expect(summary.hints == [.passObserved])
    }

    @Test("Log summary treats passed probe Lsf helper crash as non-blocking")
    func logSummaryTreatsPassedProbeLsfHelperCrashAsNonBlocking() {
        let text = """
        ----- MacWin launch -----
        engineId=wine-11.11-wow64-game
        exe=/Users/a1-6/project/Mac-Win/refs/exe-tests/bin/45_d3d9_legacy_probe.exe
        wine: failed to start L"C:\\\\windows\\\\syswow64\\\\Lsf.exe": c0000135
        wine: Unhandled page fault on read access to 0000000000000000 at address 000000014018B485 (thread 030c), starting debugger...
        probe=d3d9_legacy duration_ms=3500
        frames=2222 presents=2222
        PASS d3d9_legacy
        smokeOutcome=earlyExit
        ----- MacWin result -----
        exitCode=0
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .passed)
        #expect(summary.errorCount == 0)
        #expect(summary.failCount == 0)
        #expect(summary.hints == [.passObserved])
    }

    @Test("Log summary ignores WebView repair flags in launch metadata")
    func logSummaryIgnoresWebViewRepairFlagsInLaunchMetadata() {
        let text = """
        ----- MacWin launch -----
        command=/usr/bin/arch -x86_64 /engine/wine C:\\Program Files (x86)\\Lenovo\\LeAppStore\\LenovoAppStore.exe --force-color-profile=srgb
        env.MACWIN_COMPAT_PROFILE=lenovo-app-store
        env.MACWIN_CHROMIUM_HELPER_ARGS=--disable-gpu --disable-gpu-compositing --disable-direct-composition --disable-features=VizDisplayCompositor,DirectCompositionUseDCompVisualTree --enable-features=FontSrcLocalMatching
        env.QTWEBENGINE_CHROMIUM_FLAGS=--disable-gpu --disable-gpu-rasterization --disable-webgpu --disable-features=UseDCompVisualTree
        Warning: disabling flag --expose_wasm due to conflicting flags
        smokeOutcome=keptAlive
        TIMEOUT after 30s; sending SIGTERM to 43063
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .passed)
        #expect(summary.hints == [.passObserved])
        #expect(summary.errorCount == 0)
        #expect(summary.failCount == 0)
    }

    @Test("Log summary accepts kept-alive GeoGebra renderer software fallback")
    func logSummaryAcceptsKeptAliveGeoGebraRendererSoftwareFallback() {
        let text = """
        == MacWin software smoke ==
        id=geogebra-classic
        phase=launch
        command=/engine/wine C:\\macwin-portable\\geogebra-classic\\GeoGebra.exe --enable-features=FontSrcLocalMatching --js-flags=--jitless
        Unrecognized option
        Attempt to load file --js-flags=--jitless
        Cannot open file
        [32:ERROR:components\\os_crypt\\sync\\os_crypt_win.cc:77] Failed to encrypt: Error
        [32:ERROR:media\\audio\\win\\core_audio_util_win.cc:322] CoCreateInstance failed
        Error on trySpawn
        [32:ERROR:content\\browser\\gpu\\gpu_process_host.cc:964] GPU process exited unexpectedly
        [504:ERROR:components\\viz\\service\\main\\viz_main_impl.cc:189] Exiting GPU process due to errors during initialization
        [552:ERROR:gpu\\ipc\\service\\gpu_channel_manager.cc:920] Failed to create GLES3 context
        [552:ERROR:gpu\\ipc\\service\\gpu_channel_manager.cc:931] Failed to create shared context for virtualization
        rosetta error: no code fragment associated with the given arm pc
        liveProcessSnapshotPhase=launch-timeout-before-cleanup
        64525 1 Ss 9520 /engine/wine C:\\macwin-portable\\geogebra-classic\\GeoGebra.exe --type=renderer --enable-features=FontSrcLocalMatching
        smokeOutcome=keptAlive
        """

        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .passed)
        #expect(summary.errorCount == 0)
        #expect(summary.failCount == 0)
        #expect(summary.hints == [.passObserved])
    }

    @Test("Log summary treats Lenovo App Store page fault followed by app messages as alive")
    func logSummaryTreatsLenovoPageFaultFollowedByMessagesAsAlive() {
        let text = """
        wine: Unhandled page fault on read access to 0000000000000228 at address 00006FFFFB984C15 (thread 0324), starting debugger...
        messageid: 1 category:APPSTORE_GET_LOCALMACHINEINFOtype:1
        messageid: 2 category:APPSTORE_GET_TOKEN_INFOtype:1
        ----- MacWin launch -----
        exe=C:\\Program Files (x86)\\Lenovo\\LeAppStore\\LenovoAppStore.exe
        env.MACWIN_COMPAT_PROFILE=lenovo-app-store
        env.MACWIN_LENOVO_BLACK_SCREEN_REPAIR=1
        ----- MacWin result -----
        exitCode=15
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .passed)
        #expect(summary.passCount == 1)
        #expect(summary.hints == [.passObserved])
        #expect(summary.errorCount == 0)
        #expect(summary.failCount == 0)
    }

    @Test("Log summary treats Steam updater kept-alive smoke as pass")
    func logSummaryTreatsSteamUpdaterKeptAliveSmokeAsPass() {
        let text = """
        ----- MacWin launch -----
        exe=C:\\Program Files\\Steam\\Steam.exe
        [2026-06-30 22:06:47] Failed to load cached hosts file (File 'update_hosts_cached.vdf' not found), using defaults
        [2026-06-30 22:06:49] Package file bins_cef_win64.zip.vz.abc_105994102 missing or incorrect size
        [2026-06-30 22:07:02] Downloading update (3,852 of smokeOutcome=keptAlive
        TIMEOUT after 30s; sending SIGTERM to 90071
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .passed)
        #expect(summary.passCount == 1)
        #expect(summary.failCount == 0)
        #expect(!summary.hints.contains(.timeout))
        #expect(!summary.hints.contains(.networkTLSIssue))
    }

    @Test("Log summary treats HoYoPlay kept-alive network noise as pass")
    func logSummaryTreatsHoYoPlayKeptAliveNetworkNoiseAsPass() {
        let text = """
        ----- MacWin launch -----
        exe=C:\\Program Files\\miHoYo Launcher\\1.16.1.364\\HYP.exe
        [0630/221703.585:WARNING:chrome_command_line_pref_store.cc(124)] Additional command-line proxy switches specified when --no-proxy-server was also specified.
        [sophon:1444:0630/221704.053:ERROR:cert_verify_proc_builtin.cc(599)] No net_fetcher for performing AIA chasing.
        [sophon:1436:0630/221704.149:ERROR:abtest_service.cc(267)] data->data->code is not zero
        * schannel: failed to receive handshake, need more data
        * schannel: received incomplete message, need more data
        < HTTP/1.1 200 OK
        url fetch responce: {"code":0,"message":"OK"}
        smokeOutcome=keptAlive
        TIMEOUT after 30s; sending SIGTERM to 43018
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .passed)
        #expect(summary.passCount == 1)
        #expect(summary.errorCount == 0)
        #expect(summary.warningCount == 0)
        #expect(summary.failCount == 0)
        #expect(summary.hints == [.passObserved])
    }

    @Test("Log summary treats itch SwiftShader EGL fallback as pass")
    func logSummaryTreatsItchSwiftShaderEGLFallbackAsPass() {
        let text = """
        ----- MacWin launch -----
        exe=C:\\users\\a1-6\\AppData\\Local\\itch\\app-26.13.0\\itch.exe
        env.MACWIN_COMPAT_PROFILE=cef-software-gl
        [32:0630/222059.664:ERROR:ui\\gl\\egl_util.cc:92] EGL Driver message (Error) eglCreateContext: Requested version is not supported
        [32:0630/222059.666:ERROR:ui\\gl\\gl_context_egl.cc:337] eglCreateContext ES 3.0 failed with error EGL_BAD_ATTRIBUTE
        [32:0630/222101.116:INFO:CONSOLE:394] "preload main state {"setup":{"errors":[]},"i18n":{"strings":{"zh":{"status.downloads.download_error":"下载错误","i18n.failed_downloading_locales":"{lang} 的翻译更新下载失败"}}}}", source: C:\\users\\a1-6\\AppData\\Local\\itch\\app-26.13.0\\resources\\app\\dist\\main\\inject-preload.bundle.cjs (394)
        05:21:02.929 INFO setup got endpoint 127.0.0.1:60446
        05:21:17.857 DEBUG Got HTTP 200, content-length: 0 B
        smokeOutcome=keptAlive
        TIMEOUT after 30s; sending SIGTERM to 56909
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .passed)
        #expect(summary.passCount == 1)
        #expect(summary.errorCount == 0)
        #expect(summary.warningCount == 0)
        #expect(summary.failCount == 0)
        #expect(summary.hints == [.passObserved])
    }

    @Test("Log summary detects Lenovo CEF backend exhaustion")
    func logSummaryDetectsLenovoCEFBackendExhaustion() {
        let text = """
        ----- MacWin launch -----
        exe=C:\\Program Files (x86)\\Lenovo\\LeAppStore\\LenovoAppStore.exe
        env.MACWIN_COMPAT_PROFILE=lenovo-app-store
        EGL Driver message (Error) eglCreateContext: Requested GLES version (3.0) is greater than max supported (2, 0).
        Display::initialize error 12289: WGL_NV_DX_interop2 is required but not present.
        eglCreateWindowSurface: Internal Vulkan error (-9); eglCreateWindowSurface failed with error EGL_BAD_SURFACE
        ContextResult::kTransientFailure: Failed to send GpuControl.CreateCommandBuffer.
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .failed)
        #expect(summary.hints.contains(.cefRenderingIssue))
        #expect(summary.hints.contains(.gpuRenderingIssue))
        #expect(summary.hints.contains(.vulkanIssue))
    }

    @Test("Log summary detects a mismatched D3DMetal Wine engine")
    func logSummaryDetectsMismatchedD3DMetalEngine() {
        let summary = LogService.summarizeLog("""
        env.MACWIN_GRAPHICS_PRESET=gptk-d3dmetal
        Mach-O libd3dshared.dylib
        wine: Unhandled page fault on write access to 00000000000008E8, starting debugger...
        wineserver crashed, please enable coredumps and restart.
        """)

        #expect(summary.health == .failed)
        #expect(summary.hints.contains(.d3dMetalRuntime))
        #expect(summary.hints.contains(.wineCrash))
    }

    @Test("Log summary treats kept-alive itch setup and proxy noise as pass")
    func logSummaryTreatsKeptAliveItchSetupAndProxyNoiseAsPass() {
        let text = """
        ----- MacWin launch -----
        exe=C:\\users\\a1-6\\AppData\\Local\\itch\\app-26.13.0\\itch.exe
        env.MACWIN_COMPAT_PROFILE=cef-software-gl
        14:21:47.739 INFO itch@26.13.0 on electron@42.1.0 in production
        [32:0701/072148.211:ERROR:net\\proxy_resolution\\win\\proxy_config_service_win.cc:160] WinHttpGetIEProxyConfigForCurrentUser failed: 0
        wine: failed to start L"C:\\\\windows\\\\syswow64\\\\Lsf.exe": c0000135
        wine: Unhandled page fault on read access to 0000000000000000 at address 000000014018B485 (thread 041c), starting debugger...
        [32:0701/072150.627:ERROR:ui\\gl\\egl_util.cc:92] EGL Driver message (Error) eglCreateContext: Requested version is not supported
        [32:0701/072150.651:ERROR:ui\\gl\\gl_context_egl.cc:337] eglCreateContext ES 3.0 failed with error EGL_BAD_ATTRIBUTE
        [32:0701/072150.769:INFO:CONSOLE:407] "preload done", source: C:\\users\\a1-6\\AppData\\Local\\itch\\app-26.13.0\\resources\\app\\dist\\main\\inject-preload.bundle.cjs (407)
        [760:0701/072208.733:ERROR:net\\dns\\address_sorter_win.cc:157] SIO_ADDRESS_LIST_SORT failed 10045
        14:22:09.646 INFO (📦 butler) Latest is (15.27.0)
        14:22:09.647 INFO (📦 butler) Already the active version, nothing to do
        14:22:09.890 INFO (📦 itch-setup) Latest is (1.29.0)
        14:22:09.890 INFO (📦 itch-setup) Already the active version, nothing to do
        smokeOutcome=keptAlive
        TIMEOUT after 35s; sending SIGTERM to 93498
        Requesting wineserver -k for smoke timeout cleanup
        ----- MacWin result -----
        exitCode=15
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .passed)
        #expect(summary.passCount == 1)
        #expect(summary.errorCount == 0)
        #expect(summary.warningCount == 0)
        #expect(summary.failCount == 0)
        #expect(summary.hints == [.passObserved])
    }

    @Test("Log issue report suppresses older failures after newer kept-alive smoke")
    func logIssueReportSuppressesOlderFailuresAfterNewerKeptAliveSmoke() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinSupersededLogTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let oldText = """
        ----- MacWin launch -----
        bottleId=high-performance-win11
        exe=C:\\macwin-portable\\mremoteng-1782-x64\\mRemoteNG.exe
        smokeOutcome=earlyExit
        ----- MacWin result -----
        exitCode=0
        """
        let newText = """
        ----- MacWin launch -----
        bottleId=high-performance-win11
        exe=C:\\macwin-portable\\mremoteng-1782-x64\\mRemoteNG.exe
        smokeOutcome=keptAlive
        TIMEOUT after 30s; sending SIGTERM to 43063
        """
        let oldURL = root.appendingPathComponent("high-performance-win11-mremoteng-old.log")
        let newURL = root.appendingPathComponent("high-performance-win11-mremoteng-new.log")
        try Data(oldText.utf8).write(to: oldURL)
        try Data(newText.utf8).write(to: newURL)

        let old = LogFileItem(
            name: oldURL.lastPathComponent,
            url: oldURL,
            modifiedAt: Date(timeIntervalSince1970: 100),
            byteCount: Int64(oldText.utf8.count),
            summary: LogService.summarizeLog(oldText)
        )
        let newer = LogFileItem(
            name: newURL.lastPathComponent,
            url: newURL,
            modifiedAt: Date(timeIntervalSince1970: 200),
            byteCount: Int64(newText.utf8.count),
            summary: LogService.summarizeLog(newText)
        )

        let report = LogService.issueReport(logs: [newer, old])

        #expect(report.logsAnalyzed == 1)
        #expect(report.failedLogCount == 0)
        #expect(report.attentionLogCount == 0)
        #expect(report.passedLogCount == 1)
        #expect(report.recentFailures.isEmpty)
        #expect(report.topIssues.isEmpty)
    }

    @Test("Log issue report suppresses an older smoke workload after the same phase passes")
    func logIssueReportSuppressesOlderSmokeWorkloadAfterSamePhasePasses() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinSmokeWorkloadSupersession-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let oldRun = root.appendingPathComponent("SoftwareSmokeRuns/r-base-old", isDirectory: true)
        let newRun = root.appendingPathComponent("SoftwareSmokeRuns/r-base-new", isDirectory: true)
        try FileManager.default.createDirectory(at: oldRun, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: newRun, withIntermediateDirectories: true)

        let oldText = "Error: cannot open C:/users/test/Temp/macwin-r-statistics.csv"
        let newText = "MACWIN_R_UTF8=passed\nsmokeOutcome=passed\nexitCode=0"
        let name = "r-base-gui-core-workload.log"
        let oldURL = oldRun.appendingPathComponent(name)
        let newURL = newRun.appendingPathComponent(name)
        try Data(oldText.utf8).write(to: oldURL)
        try Data(newText.utf8).write(to: newURL)

        let old = LogFileItem(
            name: name,
            url: oldURL,
            modifiedAt: Date(timeIntervalSince1970: 100),
            byteCount: Int64(oldText.utf8.count),
            summary: LogService.summarizeLog(oldText)
        )
        let newer = LogFileItem(
            name: name,
            url: newURL,
            modifiedAt: Date(timeIntervalSince1970: 200),
            byteCount: Int64(newText.utf8.count),
            summary: LogService.summarizeLog(newText)
        )

        let report = LogService.issueReport(logs: [newer, old])

        #expect(newer.summary.health == .passed)
        #expect(report.logsAnalyzed == 1)
        #expect(report.failedLogCount == 0)
        #expect(report.passedLogCount == 1)
        #expect(report.recentFailures.isEmpty)
        #expect(report.topIssues.isEmpty)
    }

    @Test("Log issue report suppresses older PortableApps SEH failures after newer uxtheme smoke")
    func logIssueReportSuppressesOlderPortableAppsSEHFailuresAfterNewerUxthemeSmoke() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinPortableAppsSuperseded-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let oldText = """
        ----- MacWin launch -----
        startedAt=2026-07-02T15:54:46Z
        bottleId=high-performance-win11
        exe=C:\\PortableApps\\PortableApps.com\\PortableAppsPlatform.exe
        env.WINEDLLOVERRIDES=winemenubuilder.exe=d;msctf=d
        smokeOutcome=earlyExit
        ----- MacWin result -----
        endedAt=2026-07-02T15:54:53Z
        exitCode=41
        """
        let newText = """
        ----- MacWin launch -----
        startedAt=2026-07-02T16:06:40Z
        bottleId=high-performance-win11
        exe=C:\\PortableApps\\PortableApps.com\\PortableAppsPlatform.exe
        env.WINEDLLOVERRIDES=winemenubuilder.exe=d;uxtheme=d
        env.MACWIN_COMPAT_PROFILE=portableapps-platform
        wine: Unhandled page fault on read access to 014C8418 at address 00409BFE (thread 0024), starting debugger...
        smokeOutcome=keptAlive
        TIMEOUT after 12s; sending SIGTERM to 64480
        0138:err:winedbg:dbg_handle_debug_event Unknown process
        ----- MacWin result -----
        endedAt=2026-07-02T16:06:54Z
        exitCode=15
        """
        let oldURL = root.appendingPathComponent("high-performance-win11-portableapps-platform-old.log")
        let newURL = root.appendingPathComponent("high-performance-win11-portableapps-platform-new.log")
        try Data(oldText.utf8).write(to: oldURL)
        try Data(newText.utf8).write(to: newURL)

        let old = LogFileItem(
            name: oldURL.lastPathComponent,
            url: oldURL,
            modifiedAt: Date(timeIntervalSince1970: 100),
            byteCount: Int64(oldText.utf8.count),
            summary: LogService.summarizeLog(oldText)
        )
        let newer = LogFileItem(
            name: newURL.lastPathComponent,
            url: newURL,
            modifiedAt: Date(timeIntervalSince1970: 200),
            byteCount: Int64(newText.utf8.count),
            summary: LogService.summarizeLog(newText)
        )

        let report = LogService.issueReport(logs: [newer, old])

        #expect(report.logsAnalyzed == 1)
        #expect(report.failedLogCount == 0)
        #expect(report.passedLogCount == 1)
        #expect(report.recentFailures.isEmpty)
        #expect(report.topIssues.isEmpty)
    }

    @Test("Log summary treats Tencent Androws kept-alive crashpad noise as pass")
    func logSummaryTreatsTencentAndrowsKeptAliveCrashpadNoiseAsPass() {
        let text = """
        ----- MacWin launch -----
        bottleId=high-performance-win11
        exe=C:\\Program Files\\Tencent\\Androws\\Application\\5.10.6400.6084\\AndrowsStore.exe
        env.MACWIN_COMPAT_PROFILE=tencent-app-store
        [1025/004745.100:ERROR:flue_browser_global_storage.cc(68)] GetSafeMMKV, fail to get keys from db xweb_config_storage
        [1025/004745.101:ERROR:crashpad_client_win.cc(868)] CreateProcess: 找不到文件。
        [1025/004745.102:ERROR:registration_protocol_win.cc(56)] CreateFile: 找不到文件。
        [1025/004745.103:ERROR:mmcrashpad_client.cc(204)] Fail to SendDataToHandle
        smokeOutcome=keptAlive
        cliWatchdog=timedOut
        ----- MacWin result -----
        exitCode=15
        """

        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .passed)
        #expect(summary.errorCount == 0)
        #expect(summary.failCount == 0)
        #expect(summary.passCount > 0)
        #expect(summary.hints == [.passObserved])
    }

    @Test("Log issue report suppresses older Tencent Androws GPU failures after newer kept-alive smoke")
    func logIssueReportSuppressesOlderTencentAndrowsGPUFailuresAfterNewerKeptAliveSmoke() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinTencentAndrowsSuperseded-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let oldText = """
        ----- MacWin launch -----
        startedAt=2026-07-03T00:37:47Z
        bottleId=high-performance-win11
        exe=C:\\Program Files\\Tencent\\Androws\\Application\\5.10.6400.6084\\AndrowsStore.exe
        env.MACWIN_COMPAT_PROFILE=tencent-app-store
        wine: Unhandled page fault on read access to 0000000000000000 at address 0000000140001234 (thread 0024), starting debugger...
        0124:err:vulkan:__wine_create_vk_instance_with_callback Internal Vulkan error (-8)
        smokeOutcome=keptAlive
        ----- MacWin result -----
        endedAt=2026-07-03T00:38:00Z
        exitCode=15
        """
        let newText = """
        ----- MacWin launch -----
        startedAt=2026-07-03T00:47:40Z
        bottleId=high-performance-win11
        exe=C:\\Program Files\\Tencent\\Androws\\Application\\5.10.6400.6084\\AndrowsStore.exe
        env.MACWIN_COMPAT_PROFILE=tencent-app-store
        [1025/004745.100:ERROR:flue_browser_global_storage.cc(68)] GetSafeMMKV, fail to get keys from db xweb_config_storage
        [1025/004745.101:ERROR:crashpad_client_win.cc(868)] CreateProcess: 找不到文件。
        [1025/004745.102:ERROR:registration_protocol_win.cc(56)] CreateFile: 找不到文件。
        [1025/004745.103:ERROR:mmcrashpad_client.cc(204)] Fail to SendDataToHandle
        smokeOutcome=keptAlive
        cliWatchdog=timedOut
        ----- MacWin result -----
        endedAt=2026-07-03T00:47:55Z
        exitCode=15
        """
        let oldURL = root.appendingPathComponent("high-performance-win11-tencent-app-store-androws-old.log")
        let newURL = root.appendingPathComponent("high-performance-win11-tencent-app-store-androws-new.log")
        try Data(oldText.utf8).write(to: oldURL)
        try Data(newText.utf8).write(to: newURL)

        let old = LogFileItem(
            name: oldURL.lastPathComponent,
            url: oldURL,
            modifiedAt: Date(timeIntervalSince1970: 100),
            byteCount: Int64(oldText.utf8.count),
            summary: LogService.summarizeLog(oldText)
        )
        let newer = LogFileItem(
            name: newURL.lastPathComponent,
            url: newURL,
            modifiedAt: Date(timeIntervalSince1970: 200),
            byteCount: Int64(newText.utf8.count),
            summary: LogService.summarizeLog(newText)
        )

        #expect(old.summary.health == .failed)
        #expect(newer.summary.health == .passed)

        let report = LogService.issueReport(logs: [newer, old])

        #expect(report.logsAnalyzed == 1)
        #expect(report.failedLogCount == 0)
        #expect(report.passedLogCount == 1)
        #expect(report.recentFailures.isEmpty)
        #expect(report.topIssues.isEmpty)
    }

    @Test("Log issue report suppresses old SumatraPDF install path failures after user-local launch")
    func logIssueReportSuppressesOldSumatraPDFInstallPathFailuresAfterUserLocalLaunch() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinSumatraSupersededLogTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let oldText = """
        ----- MacWin launch -----
        bottleId=high-performance-win11
        exe=C:\\Program Files\\SumatraPDF\\SumatraPDF.exe
        wine: failed to open "C:\\\\Program Files\\\\SumatraPDF\\\\SumatraPDF.exe"
        ----- MacWin result -----
        exitCode=53
        """
        let newText = """
        ----- MacWin launch -----
        bottleId=high-performance-win11
        exe=C:\\users\\tester\\AppData\\Local\\SumatraPDF\\SumatraPDF.exe
        smokeOutcome=keptAlive
        TIMEOUT after 20s; sending SIGTERM to 43063
        """
        let oldURL = root.appendingPathComponent("high-performance-win11-sumatrapdf-old.log")
        let newURL = root.appendingPathComponent("high-performance-win11-sumatrapdf-new.log")
        try Data(oldText.utf8).write(to: oldURL)
        try Data(newText.utf8).write(to: newURL)

        let old = LogFileItem(
            name: oldURL.lastPathComponent,
            url: oldURL,
            modifiedAt: Date(timeIntervalSince1970: 100),
            byteCount: Int64(oldText.utf8.count),
            summary: LogService.summarizeLog(oldText)
        )
        let newer = LogFileItem(
            name: newURL.lastPathComponent,
            url: newURL,
            modifiedAt: Date(timeIntervalSince1970: 200),
            byteCount: Int64(newText.utf8.count),
            summary: LogService.summarizeLog(newText)
        )

        let report = LogService.issueReport(logs: [newer, old])

        #expect(report.logsAnalyzed == 1)
        #expect(report.failedLogCount == 0)
        #expect(report.passedLogCount == 1)
        #expect(report.recentFailures.isEmpty)
        #expect(report.topIssues.isEmpty)
    }

    @Test("Log issue report suppresses LibreOffice reinstall crash after newer Writer smoke")
    func logIssueReportSuppressesLibreOfficeReinstallCrashAfterNewerWriterSmoke() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinLibreOfficeSupersededLogTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let installText = """
        ----- MacWin launch -----
        bottleId=high-performance-win11
        exe=msiexec
        command=/usr/bin/arch -x86_64 /engine/wine msiexec /i LibreOffice_26.2.4_Win_x86-64.msi /qn
        wine: Unhandled page fault on read access to 0000000000000008 at address 00006FFFFA77C8C0 (thread 0120), starting debugger...
        ----- MacWin result -----
        exitCode=5
        -------------------------
        installerOutcome=existingInstallAccepted
        PASS existing install accepted after installer exitCode=5
        """
        let writerText = """
        ----- MacWin launch -----
        bottleId=high-performance-win11
        exe=C:\\Program Files\\LibreOffice\\program\\swriter.exe
        smokeOutcome=keptAlive
        TIMEOUT after 45s; sending SIGTERM to 71534
        """
        let installURL = root.appendingPathComponent("high-performance-win11-install-libreoffice-old.log")
        let writerURL = root.appendingPathComponent("high-performance-win11-libreoffice-writer-new.log")
        try Data(installText.utf8).write(to: installURL)
        try Data(writerText.utf8).write(to: writerURL)

        let install = LogFileItem(
            name: installURL.lastPathComponent,
            url: installURL,
            modifiedAt: Date(timeIntervalSince1970: 100),
            byteCount: Int64(installText.utf8.count),
            summary: LogService.summarizeLog(installText)
        )
        let writer = LogFileItem(
            name: writerURL.lastPathComponent,
            url: writerURL,
            modifiedAt: Date(timeIntervalSince1970: 200),
            byteCount: Int64(writerText.utf8.count),
            summary: LogService.summarizeLog(writerText)
        )

        let report = LogService.issueReport(logs: [writer, install])

        #expect(report.logsAnalyzed == 1)
        #expect(report.failedLogCount == 0)
        #expect(report.attentionLogCount == 0)
        #expect(report.passedLogCount == 1)
        #expect(report.recentFailures.isEmpty)
        #expect(report.topIssues.isEmpty)
    }

    @Test("Log issue report uses launch time when suppressing older failures")
    func logIssueReportUsesLaunchTimeWhenSuppressingOlderFailures() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinSupersededLaunchTimeTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let failedText = """
        ----- MacWin launch -----
        bottleId=high-performance-win11
        exe=C:\\macwin-portable\\qmodmaster-32\\qModMaster\\qModMaster.exe
        wine: Unhandled page fault on read access to 00005DC9 at address 7BC5123D, starting debugger...
        0388:fixme:thread:get_thread_times not implemented on this platform
        smokeOutcome=earlyExit
        ----- MacWin result -----
        exitCode=5
        """
        let passedText = """
        ----- MacWin launch -----
        bottleId=high-performance-win11
        exe=C:\\macwin-portable\\qmodmaster-32\\qModMaster\\qModMaster.exe
        smokeOutcome=keptAlive
        TIMEOUT after 15s; sending SIGTERM to 44598
        Requesting wineserver -k for smoke timeout cleanup
        """
        let failedURL = root.appendingPathComponent("qmod-failed.log")
        let passedURL = root.appendingPathComponent("qmod-passed.log")
        try Data(failedText.utf8).write(to: failedURL)
        try Data(passedText.utf8).write(to: passedURL)

        let failed = LogFileItem(
            name: failedURL.lastPathComponent,
            url: failedURL,
            modifiedAt: Date(timeIntervalSince1970: 300),
            byteCount: Int64(failedText.utf8.count),
            summary: LogService.summarizeLog(failedText),
            launchContext: LogLaunchContext(
                launchRecordId: "failed",
                mode: "foregroundRun",
                state: "completed",
                bottleId: "high-performance-win11",
                bottleName: "High Performance",
                engineId: "engine",
                exe: "C:\\macwin-portable\\qmodmaster-32\\qModMaster\\qModMaster.exe",
                args: [],
                commandLine: [],
                startedAt: Date(timeIntervalSince1970: 100),
                endedAt: Date(timeIntervalSince1970: 110),
                exitCode: 5
            )
        )
        let passed = LogFileItem(
            name: passedURL.lastPathComponent,
            url: passedURL,
            modifiedAt: Date(timeIntervalSince1970: 200),
            byteCount: Int64(passedText.utf8.count),
            summary: LogService.summarizeLog(passedText),
            launchContext: LogLaunchContext(
                launchRecordId: "passed",
                mode: "foregroundRun",
                state: "completed",
                bottleId: "high-performance-win11",
                bottleName: "High Performance",
                engineId: "engine",
                exe: "C:\\macwin-portable\\qmodmaster-32\\qModMaster\\qModMaster.exe",
                args: [],
                commandLine: [],
                startedAt: Date(timeIntervalSince1970: 400),
                endedAt: Date(timeIntervalSince1970: 415),
                exitCode: 15
            )
        )

        let report = LogService.issueReport(logs: [failed, passed])

        #expect(report.logsAnalyzed == 1)
        #expect(report.failedLogCount == 0)
        #expect(report.attentionLogCount == 0)
        #expect(report.passedLogCount == 1)
        #expect(report.recentFailures.isEmpty)
        #expect(report.topIssues.isEmpty)
    }

    @Test("Log summary classifies managed mRemoteNG smoke early exit")
    func logSummaryClassifiesManagedMRemoteNGSmokeEarlyExit() {
        let text = """
        ----- MacWin launch -----
        exe=C:\\macwin-portable\\mremoteng-1782-x64\\mRemoteNG.exe
        smokeOutcome=earlyExit
        ----- MacWin result -----
        exitCode=0
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .attention)
        #expect(summary.hints.contains(.mRemoteNGEarlyExitIssue))
        #expect(!summary.hints.contains(.timeout))
    }

    @Test("Log summary detects missing MSI runtime")
    func logSummaryDetectsMissingMSIRuntime() throws {
        let text = """
        command=/usr/bin/arch -x86_64 wine msiexec /i Z:\\Users\\a1-6\\Library\\Application Support\\MacWin\\Downloads\\putty-64bit-installer.msi /qn /norestart
        Application could not be started, or no application associated with the specified file.
        ShellExecuteEx failed: File not found.
        wine: failed to open "C:\\windows\\system32\\msiexec.exe"
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .failed)
        #expect(summary.hints.contains(.msiRuntimeIssue))
        #expect(summary.hints.contains(.installerIssue))

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinMissingMSIRuntime-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let logURL = root.appendingPathComponent("putty-install.log")
        try Data(text.utf8).write(to: logURL)
        let item = LogFileItem(
            name: logURL.lastPathComponent,
            url: logURL,
            modifiedAt: Date(timeIntervalSince1970: 500),
            byteCount: Int64(text.utf8.count),
            summary: summary
        )
        let report = LogService.issueReport(logs: [item])

        #expect(report.topIssues.first?.id == "msi-runtime")
        #expect(report.recentFailures.first?.probableIssueIds.contains("msi-runtime") == true)
        #expect(report.recentFailures.first?.probeAssetIds.contains("console") == true)
        #expect(report.recentFailures.first?.evidenceSnippets.contains { $0.localizedCaseInsensitiveContains("msiexec") } == true)
    }

    @Test("Log summary detects missing builtin DLL coverage")
    func logSummaryDetectsMissingBuiltinDLLCoverage() throws {
        let text = """
        0090:warn:module:load_dll Failed to load module L"d3d10_1.dll"; status=c0000135
        0090:err:module:import_dll Library d3d10_1.dll (which is needed by L"C:\\windows\\system32\\d2d1.dll") not found
        0090:err:module:loader_init Importing dlls for L"C:\\Program Files\\LibreOffice\\program\\soffice.bin" failed, status c0000135
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .failed)
        #expect(summary.hints.contains(.missingDLLIssue))
        #expect(!summary.hints.contains(.msiRuntimeIssue))

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinMissingBuiltinDLL-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let logURL = root.appendingPathComponent("libreoffice-launch.log")
        try Data(text.utf8).write(to: logURL)
        let item = LogFileItem(
            name: logURL.lastPathComponent,
            url: logURL,
            modifiedAt: Date(timeIntervalSince1970: 550),
            byteCount: Int64(text.utf8.count),
            summary: summary
        )
        let report = LogService.issueReport(logs: [item])

        #expect(report.topIssues.first?.id == "missing-builtin-dll")
        #expect(report.recentFailures.first?.probableIssueIds.contains("missing-builtin-dll") == true)
        #expect(report.recentFailures.first?.probeAssetIds.contains("console") == true)
        #expect(report.recentFailures.first?.evidenceSnippets.contains { $0.localizedCaseInsensitiveContains("d3d10_1.dll") } == true)
    }

    @Test("Log summary detects Chrome Enterprise MSI custom installer failure")
    func logSummaryDetectsChromeEnterpriseMSICustomInstallerFailure() throws {
        let text = """
        command=wine msiexec /i C:\\macwin-installers\\GoogleChromeStandaloneEnterprise64.msi /qn /norestart /l*v C:\\macwin-installers\\chrome-enterprise-msi-detail.log
        Property(S): ProductName = Google Chrome
        Property(S): InstallCommand = --silent --install="appguid={8A69D345-D564-463c-AFF1-A69D9E530F96}&appname=Google Chrome&needsAdmin=True&brand=GCEA&ap=x64-stable" --installsource=enterprisemsi
        Action start 12:22:40: DoInstall.
        Action ended 12:22:41: DoInstall. Return value 0.
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .failed)
        #expect(summary.hints.contains(.chromeOmahaInstallerIssue))
        #expect(summary.hints.contains(.installerIssue))
        #expect(!summary.hints.contains(.msiRuntimeIssue))

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinChromeEnterpriseMSI-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let logURL = root.appendingPathComponent("chrome-enterprise-msi-detail.log")
        try Data(text.utf8).write(to: logURL)
        let item = LogFileItem(
            name: logURL.lastPathComponent,
            url: logURL,
            modifiedAt: Date(timeIntervalSince1970: 600),
            byteCount: Int64(text.utf8.count),
            summary: summary
        )
        let report = LogService.issueReport(logs: [item])

        #expect(report.topIssues.first?.id == "chrome-omaha-installer")
        #expect(report.recentFailures.first?.probableIssueIds.contains("chrome-omaha-installer") == true)
        #expect(report.recentFailures.first?.probeAssetIds.contains("tls-winhttp") == true)
        #expect(report.recentFailures.first?.evidenceSnippets.contains { $0.localizedCaseInsensitiveContains("enterprisemsi") } == true)
    }

    @Test("Log summary detects Edge Enterprise MSI EdgeUpdate installer failure")
    func logSummaryDetectsEdgeEnterpriseMSIEdgeUpdateInstallerFailure() throws {
        let text = """
        command=wine msiexec /i C:\\macwin-installers\\MicrosoftEdgeEnterpriseX64.msi /qn /norestart /l*v C:\\macwin-installers\\edge-enterprise-msi-detail.log
        Property(S): ProductName = Microsoft Edge
        Property(S): InstallCommand = /silent /install "appguid={56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}&appname=Microsoft Edge&needsAdmin=True&ap=stable-arch_x64" /installsource enterprisemsi
        Key: HKEY_LOCAL_MACHINE\\Software\\Microsoft\\EdgeUpdate\\ClientState\\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}, Name: LastInstallerResultUIString
        Action ended 12:56:57: DoInstall. Return value 0.
        Action ended 12:56:57: INSTALL. Return value 0.
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .failed)
        #expect(summary.hints.contains(.chromeOmahaInstallerIssue))
        #expect(summary.hints.contains(.installerIssue))
        #expect(!summary.hints.contains(.msiRuntimeIssue))

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinEdgeEnterpriseMSI-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let logURL = root.appendingPathComponent("edge-enterprise-msi-detail.log")
        try Data(text.utf8).write(to: logURL)
        let item = LogFileItem(
            name: logURL.lastPathComponent,
            url: logURL,
            modifiedAt: Date(timeIntervalSince1970: 650),
            byteCount: Int64(text.utf8.count),
            summary: summary
        )
        let report = LogService.issueReport(logs: [item])

        #expect(report.topIssues.first?.id == "chrome-omaha-installer")
        #expect(report.recentFailures.first?.probableIssueIds.contains("chrome-omaha-installer") == true)
        #expect(report.recentFailures.first?.probeAssetIds.contains("tls-winhttp") == true)
        #expect(report.recentFailures.first?.evidenceSnippets.contains { $0.localizedCaseInsensitiveContains("edgeupdate") } == true)
    }

    @Test("Log summary detects Brave updater installer timeout")
    func logSummaryDetectsBraveUpdaterInstallerTimeout() throws {
        let text = """
        command=wine C:\\macwin-installers\\BraveBrowserStandaloneSetup.exe --silent --install
        C:\\Program Files (x86)\\BraveSoftware\\Temp\\GUMc43d.tmp\\BraveUpdate.exe --silent --install appguid={AFE6A462-C574-4B8A-AF43-4CC60DF4563B}&appname=Brave-Release
        TIMEOUT after 420s; sending SIGTERM to 8085
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .failed)
        #expect(summary.hints.contains(.chromeOmahaInstallerIssue))
        #expect(summary.hints.contains(.timeout))
        #expect(summary.hints.contains(.installerIssue))
    }

    @Test("Log summary detects COM RpcSs marshalling failures")
    func logSummaryDetectsCOMRpcSsMarshallingFailures() throws {
        let text = """
        warn:ole:CoGetPSClsid No PSFactoryBuffer object is registered for IID {6d5140c1-7436-11ce-8034-00aa006009fa}
        err:ole:marshal_object Failed to create an IRpcStubBuffer from IPSFactory for {6d5140c1-7436-11ce-8034-00aa006009fa} with error 0x80004002
        err:ole:CoMarshalInterface Failed to marshal the interface {6d5140c1-7436-11ce-8034-00aa006009fa}, hr 0x80004002
        err:ole:apartment_get_local_server_stream Failed: 0x80004002
        trace:rpc:rpcrt4_conn_open_pipe connecting to \\\\.\\pipe\\lrpc\\irpcss
        """
        let summary = LogService.summarizeLog(text)

        #expect(summary.health == .failed)
        #expect(summary.hints.contains(.comProxyMarshallingIssue))
        #expect(!summary.hints.contains(.chromeOmahaInstallerIssue))

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinCOMRpcSsMarshalling-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let logURL = root.appendingPathComponent("brave-update-com.log")
        try Data(text.utf8).write(to: logURL)
        let item = LogFileItem(
            name: logURL.lastPathComponent,
            url: logURL,
            modifiedAt: Date(timeIntervalSince1970: 700),
            byteCount: Int64(text.utf8.count),
            summary: summary
        )
        let report = LogService.issueReport(logs: [item])

        #expect(report.topIssues.first?.id == "com-rpcss-marshalling")
        #expect(report.recentFailures.first?.probableIssueIds.contains("com-rpcss-marshalling") == true)
        #expect(report.recentFailures.first?.probeAssetIds.contains("tls-winhttp-win32") == true)
        #expect(report.recentFailures.first?.evidenceSnippets.contains { $0.localizedCaseInsensitiveContains("ipsfactory") } == true)
    }

    @Test("Log issue report groups recent failures by likely cause")
    func logIssueReportGroupsRecentFailuresByLikelyCause() {
        let root = URL(fileURLWithPath: "/tmp/MacWinLogIssueTests")
        let crash = LogFileItem(
            name: "hoyoplay.log",
            url: root.appendingPathComponent("hoyoplay.log"),
            modifiedAt: Date(timeIntervalSince1970: 300),
            byteCount: 10,
            summary: LogService.summarizeLog("""
            wine: Unhandled page fault on read access to 0000000000000000, starting debugger...
            [0617:ERROR:gpu_channel_manager.cc] Failed to create shared context
            HYPHelper --disable-font-subpixel-positioning --disable-features=DWriteFontProxy
            """)
        )
        let network = LogFileItem(
            name: "steam.log",
            url: root.appendingPathComponent("steam.log"),
            modifiedAt: Date(timeIntervalSince1970: 200),
            byteCount: 20,
            summary: LogService.summarizeLog("""
            err:winhttp certificate validation failed
            Operation timed out after 5000 milliseconds
            """)
        )
        let blankWindow = LogFileItem(
            name: "lenovo-store.log",
            url: root.appendingPathComponent("lenovo-store.log"),
            modifiedAt: Date(timeIntervalSince1970: 150),
            byteCount: 25,
            summary: LogService.summarizeLog("""
            warn:app window rendered black screen
            gdi_missing_glyphs=4
            WARN window_input layered hit-test transparent or nowhere
            """)
        )
        let passing = LogFileItem(
            name: "probe.log",
            url: root.appendingPathComponent("probe.log"),
            modifiedAt: Date(timeIntervalSince1970: 100),
            byteCount: 30,
            summary: LogService.summarizeLog("40_xaudio2_probe.exe PASS xaudio2")
        )

        let report = LogService.issueReport(logs: [crash, network, blankWindow, passing])

        #expect(report.logsAnalyzed == 4)
        #expect(report.failedLogCount == 2)
        #expect(report.attentionLogCount == 1)
        #expect(report.passedLogCount == 1)
        #expect(report.totalErrorCount == 2)
        #expect(report.totalWarningCount == 1)
        #expect(report.totalPassCount == 1)
        #expect(report.healthCounts["failed"] == 2)
        #expect(report.healthCounts["attention"] == 1)
        #expect(report.hintCounts["wineCrash"] == 1)
        #expect(report.hintCounts["blankWindowIssue"] == 1)
        #expect(report.hintCounts["windowInputIssue"] == 1)
        #expect(report.hintCounts["networkTLSIssue"] == 1)
        #expect(report.topIssues.first?.id == "wine-crash")
        #expect(report.topIssues.first { $0.id == "webview-rendering" }?.affectedLogNames == ["hoyoplay.log"])
        #expect(report.topIssues.first { $0.id == "text-rendering" }?.affectedLogNames == ["hoyoplay.log", "lenovo-store.log"])
        #expect(report.topIssues.first { $0.id == "text-rendering" }?.probeAssetIds == ["text-rendering"])
        #expect(report.topIssues.first { $0.id == "text-rendering" }?.recommendedActions.isEmpty == false)
        #expect(report.topIssues.first { $0.id == "blank-window" }?.affectedLogNames == ["lenovo-store.log"])
        #expect(report.topIssues.first { $0.id == "blank-window" }?.probeAssetIds == ["text-rendering", "window-input"])
        #expect(report.topIssues.first { $0.id == "window-input" }?.affectedLogNames == ["lenovo-store.log"])
        #expect(report.topIssues.first { $0.id == "network-tls" }?.affectedLogNames == ["steam.log"])
        #expect(report.topIssues.first { $0.id == "network-tls" }?.probeAssetIds.contains("tls-winhttp") == true)
        #expect(report.topIssues.first { $0.id == "network-tls" }?.probeAssetIds.contains("tls-winhttp-win32") == true)
        #expect(report.recentFailures.map(\.name) == ["hoyoplay.log", "steam.log", "lenovo-store.log"])
        #expect(report.recentFailures.first?.probableIssueIds.contains("wine-crash") == true)
        #expect(report.recentFailures.first?.recommendedActions.isEmpty == false)
        #expect(report.recentFailures.first?.probeAssetIds.contains("console") == true)
        #expect(report.recentFailures.first { $0.name == "steam.log" }?.probableIssueIds == ["network-tls"])
        #expect(report.recentFailures.first { $0.name == "steam.log" }?.probeAssetIds.contains("tls-winhttp-win32") == true)
        #expect(report.recentFailures.first { $0.name == "lenovo-store.log" }?.probableIssueIds == ["text-rendering", "blank-window", "window-input"])
        #expect(report.recentFailures.first { $0.name == "lenovo-store.log" }?.probeAssetIds == ["text-rendering", "window-input"])
    }

    @Test("Log issue samples include redacted evidence snippets")
    func logIssueSamplesIncludeRedactedEvidenceSnippets() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinLogEvidenceTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let log = root.appendingPathComponent("hoyoplay.log")
        try Data("""
        Authorization: Bearer super-secret-token
        wine: Unhandled page fault on read access to 0000000000000000, starting debugger...
        [0617:ERROR:gpu_channel_manager.cc] Failed to create shared context
        HYPHelper --disable-direct-write --disable-features=DWriteFontProxy token=abc123
        Renderer produced no frame and black screen observed under /Users/alice/Downloads/HoYoPlay.exe
        """.utf8).write(to: log)

        let item = try #require(LogService.recentLogs(in: root).first)
        let report = LogService.issueReport(logs: [item])
        let sample = try #require(report.recentFailures.first)

        #expect(sample.evidenceSnippets.contains { $0.contains("Unhandled page fault") })
        #expect(sample.evidenceSnippets.contains { $0.contains("gpu_channel_manager") })
        #expect(sample.evidenceSnippets.contains { $0.contains("DWriteFontProxy") && $0.contains("token=<redacted>") })
        #expect(sample.evidenceSnippets.contains { $0.contains("/Users/<user>") })
        #expect(sample.evidenceSnippets.allSatisfy { !$0.contains("super-secret-token") })
        #expect(sample.evidenceSnippets.count <= 4)
    }

    @Test("Log triage markdown exports issues evidence probes and launch context")
    func logTriageMarkdownExportsIssuesEvidenceProbesAndLaunchContext() {
        let report = LogIssueReport(
            logs: [],
            topIssues: [
                LogIssueTrend(
                    id: "text-rendering",
                    severity: "high",
                    title: "Text rendering or font fallback issue",
                    detail: "DirectWrite and missing glyph signals were observed.",
                    count: 1,
                    relatedHints: ["fontRenderingIssue"],
                    affectedLogNames: ["hoyoplay.log"],
                    recommendedActions: ["Run the text rendering probe."],
                    probeAssetIds: ["text-rendering"]
                )
            ],
            recentFailures: [
                LogIssueSample(
                    name: "hoyoplay.log",
                    path: "/tmp/MacWin/Logs/hoyoplay.log",
                    modifiedAt: Date(timeIntervalSince1970: 1_700_000_000),
                    health: LogHealth.failed.rawValue,
                    errorCount: 1,
                    warningCount: 0,
                    fixmeCount: 0,
                    passCount: 0,
                    failCount: 1,
                    hints: ["fontRenderingIssue"],
                    probableIssueIds: ["text-rendering"],
                    evidenceSnippets: ["HYPHelper --disable-direct-write token=<redacted>"],
                    recommendedActions: ["Relaunch with the current compatibility profile."],
                    probeAssetIds: ["text-rendering"],
                    launchContext: LogLaunchContext(
                        launchRecordId: "launch-1",
                        mode: "detached",
                        state: "completed",
                        bottleId: "high-performance-win11",
                        bottleName: "高性能 Windows 11",
                        engineId: "wine-11.11-wow64-game",
                        exe: "C:\\Program Files\\miHoYo Launcher\\HYP.exe",
                        args: ["--some-flag"],
                        commandLine: ["wine", "HYP.exe"],
                        startedAt: Date(timeIntervalSince1970: 1_700_000_000),
                        processIdentifier: 1234,
                        exitCode: 1
                    )
                )
            ]
        )

        let markdown = LogService.triageMarkdown(report: report, generatedAt: Date(timeIntervalSince1970: 1_700_000_100))

        #expect(markdown.contains("# MacWin Log Triage"))
        #expect(markdown.contains("### Text rendering or font fallback issue"))
        #expect(markdown.contains("`text-rendering`"))
        #expect(markdown.contains("Run the text rendering probe."))
        #expect(markdown.contains("HYPHelper --disable-direct-write token=<redacted>"))
        #expect(markdown.contains("Bottle: `高性能 Windows 11` (`high-performance-win11`)"))
        #expect(markdown.contains("Executable: `C:\\Program Files\\miHoYo Launcher\\HYP.exe`"))
        #expect(markdown.contains("PID: 1234"))
        #expect(markdown.contains("Exit code: 1"))

        let csv = LogIssueReport.csv(report: report)
        #expect(csv.contains("record_type,id,name,severity_or_health,count,path,modified_at"))
        #expect(csv.contains("trend,text-rendering,Text rendering or font fallback issue,high,1"))
        #expect(csv.contains("sample,/tmp/MacWin/Logs/hoyoplay.log,hoyoplay.log,failed"))
        #expect(csv.contains("high-performance-win11,高性能 Windows 11"))
        #expect(csv.contains(#"C:\Program Files\miHoYo Launcher\HYP.exe"#))
        #expect(csv.contains("text-rendering"))

        let plan = LogService.remediationPlan(report: report, generatedAt: Date(timeIntervalSince1970: 1_700_000_101))
        #expect(plan.actionCount == 2)
        #expect(plan.probeActionCount == 2)
        #expect(plan.affectedLogCount == 2)
        #expect(plan.items.contains { $0.source == .trend && $0.issueId == "text-rendering" && $0.affectedLogNames == ["hoyoplay.log"] })
        #expect(plan.items.contains { $0.source == .sample && $0.samplePaths == ["/tmp/MacWin/Logs/hoyoplay.log"] && $0.bottleId == "high-performance-win11" })
        let planCSV = LogRemediationPlan.csv(plan: plan)
        #expect(planCSV.contains("id,source,severity,issue_id,title,action,probe_asset_ids"))
        #expect(planCSV.contains("trend,high,text-rendering,Text rendering or font fallback issue"))
        #expect(planCSV.contains("high-performance-win11,高性能 Windows 11"))
        let planMarkdown = LogRemediationPlan.markdown(plan: plan)
        #expect(planMarkdown.contains("# MacWin Log Remediation Plan"))
        #expect(planMarkdown.contains("- Actions: 2"))
        #expect(planMarkdown.contains("Bottle: `高性能 Windows 11` (`high-performance-win11`)"))
        #expect(planMarkdown.contains("Executable: `C:\\Program Files\\miHoYo Launcher\\HYP.exe`"))
        #expect(planMarkdown.contains("HYPHelper --disable-direct-write token=<redacted>"))
        let runbook = TestAssetRunbook(
            rootPath: "/tmp/MacWin",
            canRunSuite: true,
            missingRequiredAssetIds: [],
            buildCommand: nil,
            suiteCommand: nil,
            groups: [
                TestAssetRunGroup(
                    category: .graphics,
                    assetIds: ["text-rendering"],
                    commands: [
                        TestAssetRunCommand(
                            assetId: "text-rendering",
                            name: "Text Rendering Probe",
                            architecture: .x86_64,
                            executablePath: "/tmp/MacWin/exe-tests/bin/70_text_rendering_probe.exe",
                            exists: true,
                            command: ["refs/exe-tests/run-one.sh", "text-rendering"],
                            note: nil
                        )
                    ]
                )
            ]
        )
        let runbookScript = LogRemediationPlan.runbookScript(plan: plan, runbook: runbook)
        #expect(runbookScript.contains("#!/usr/bin/env bash"))
        #expect(runbookScript.contains("MacWin log remediation runbook"))
        #expect(runbookScript.contains("ACTION text-rendering: Run the text rendering probe."))
        #expect(runbookScript.contains("samples: /tmp/MacWin/Logs/hoyoplay.log"))
        #expect(runbookScript.contains("run_probe 'text-rendering' 'refs/exe-tests/run-one.sh' 'text-rendering'"))
    }

    @Test("Log remediation plan deduplicates trend and sample actions")
    func logRemediationPlanDeduplicatesTrendAndSampleActions() {
        let action = "Run the text rendering probe and compare it with the affected app log."
        let report = LogIssueReport(
            logs: [],
            topIssues: [
                LogIssueTrend(
                    id: "text-rendering",
                    severity: "high",
                    title: "Text rendering or font fallback issue",
                    detail: "DirectWrite flags were observed.",
                    count: 1,
                    relatedHints: ["fontRenderingIssue"],
                    affectedLogNames: ["hoyoplay.log"],
                    recommendedActions: [action],
                    probeAssetIds: ["text-rendering"]
                )
            ],
            recentFailures: [
                LogIssueSample(
                    name: "hoyoplay.log",
                    path: "/tmp/hoyoplay.log",
                    modifiedAt: Date(timeIntervalSince1970: 1),
                    health: LogHealth.attention.rawValue,
                    errorCount: 0,
                    warningCount: 0,
                    fixmeCount: 0,
                    passCount: 1,
                    failCount: 0,
                    hints: ["fontRenderingIssue"],
                    probableIssueIds: ["text-rendering"],
                    evidenceSnippets: ["HYPHelper --disable-direct-write"],
                    recommendedActions: [action],
                    probeAssetIds: ["text-rendering"]
                )
            ]
        )

        let plan = LogService.remediationPlan(report: report)

        #expect(plan.actionCount == 1)
        #expect(plan.items.first?.source == .trend)
        #expect(plan.items.first?.issueId == "text-rendering")
    }

    @Test("Log triage markdown handles empty reports")
    func logTriageMarkdownHandlesEmptyReports() {
        let markdown = LogService.triageMarkdown(
            report: LogIssueReport(logs: [], topIssues: [], recentFailures: []),
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        #expect(markdown.contains("No known issue trends were detected"))
        #expect(markdown.contains("No failed or attention logs were found"))
    }
}
