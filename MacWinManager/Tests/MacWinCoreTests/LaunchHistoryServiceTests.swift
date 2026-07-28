import Foundation
import Testing
@testable import MacWinCore

@Suite("Launch history service")
struct LaunchHistoryServiceTests {
    @Test("Launch history loads records sorted by newest start")
    func launchHistoryLoadsRecordsSortedByNewestStart() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinLaunchHistoryTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let recordsDirectory = LaunchHistoryService.recordsDirectory(in: paths.logsDirectory)
        try FileManager.default.createDirectory(at: recordsDirectory, withIntermediateDirectories: true)
        let store = JSONStore()

        let older = WineLaunchRecord(
            id: "older",
            mode: .foregroundRun,
            state: .completed,
            logPath: paths.logsDirectory.appendingPathComponent("older.log").path,
            startedAt: Date(timeIntervalSince1970: 100),
            endedAt: Date(timeIntervalSince1970: 101),
            durationMilliseconds: 1_000,
            exitCode: 0,
            bottleId: "bottle-a",
            bottleName: "Bottle A",
            engineId: "engine",
            winePath: "/wine",
            exe: "older.exe",
            args: [],
            commandLine: ["/usr/bin/arch", "-x86_64", "/wine", "older.exe"],
            workingDirectory: root.path,
            environment: ["WINE_D3D_CONFIG": "renderer=vulkan,csmt=0x0"]
        )
        let newer = WineLaunchRecord(
            id: "newer",
            mode: .detached,
            state: .started,
            logPath: paths.logsDirectory.appendingPathComponent("newer.log").path,
            startedAt: Date(timeIntervalSince1970: 200),
            processIdentifier: 42,
            bottleId: "bottle-b",
            bottleName: "Bottle B",
            engineId: "engine",
            winePath: "/wine",
            exe: "newer.exe",
            args: ["--flag"],
            commandLine: ["/usr/bin/arch", "-x86_64", "/wine", "newer.exe", "--flag"],
            workingDirectory: root.path,
            environment: [:]
        )
        let failed = WineLaunchRecord(
            id: "failed",
            mode: .detached,
            state: .failedToLaunch,
            logPath: paths.logsDirectory.appendingPathComponent("failed.log").path,
            startedAt: Date(timeIntervalSince1970: 150),
            endedAt: Date(timeIntervalSince1970: 151),
            durationMilliseconds: 1_000,
            bottleId: "bottle-c",
            bottleName: "Bottle C",
            engineId: "engine",
            winePath: "/missing-wine",
            exe: "failed.exe",
            args: [],
            commandLine: ["/usr/bin/arch", "-x86_64", "/missing-wine", "failed.exe"],
            workingDirectory: root.path,
            environment: [:],
            errorMessage: "missing wine"
        )

        try store.save(older, to: recordsDirectory.appendingPathComponent("older.launch.json"))
        try store.save(newer, to: recordsDirectory.appendingPathComponent("newer.launch.json"))
        try store.save(failed, to: recordsDirectory.appendingPathComponent("failed.launch.json"))
        try Data("not a launch record".utf8).write(to: recordsDirectory.appendingPathComponent("ignored.txt"))

        let report = LaunchHistoryService(paths: paths).report(limit: 2)

        #expect(report.rootPath == root.path)
        #expect(report.logsPath == paths.logsDirectory.path)
        #expect(report.recordsPath == recordsDirectory.path)
        #expect(report.totalLaunchCount == 2)
        #expect(report.completedCount == 0)
        #expect(report.detachedCount == 2)
        #expect(report.failedToLaunchCount == 1)
        #expect(report.latestStartedAt == Date(timeIntervalSince1970: 200))
        #expect(report.records.map(\.id) == ["newer", "failed"])
        #expect(report.stateCounts["started"] == 1)
        #expect(report.stateCounts["failedToLaunch"] == 1)

        let script = LaunchHistoryService.replayShellScript(for: report)
        #expect(script.contains("MODE=\"${1:-list}\""))
        #expect(script.contains("newer state=started exit=- bottle=Bottle B exe=newer.exe"))
        #expect(script.contains("failed state=failedToLaunch exit=- bottle=Bottle C exe=failed.exe"))
        #expect(script.contains("if [[ \"$TARGET\" == 'newer' ]]; then"))
        #expect(script.contains("cd '\(root.path)'"))
        #expect(script.contains("export WINE_D3D_CONFIG='renderer=vulkan,csmt=0x0'") == false)
        #expect(script.contains("exec '/usr/bin/arch' '-x86_64' '/wine' 'newer.exe' '--flag'"))
        #expect(script.contains("usage: $0 [list|run <launch-id>]"))

        let csv = LaunchHistoryReport.csv(report: report)
        #expect(csv.contains("id,mode,state,started_at,ended_at,duration_ms,pid,exit_code,bottle_id,bottle_name,engine_id,exe,args,log_path"))
        #expect(csv.contains("newer,detached,started,1970-01-01T00:03:20Z,,,42,,bottle-b,Bottle B,engine,newer.exe,--flag"))
        #expect(csv.contains("failed,detached,failedToLaunch,1970-01-01T00:02:30Z,1970-01-01T00:02:31Z,1000,,,bottle-c,Bottle C,engine,failed.exe"))
        #expect(csv.contains("missing wine"))
    }

    @Test("Launch history returns empty report when records directory is absent")
    func launchHistoryReturnsEmptyReportWhenRecordsDirectoryIsAbsent() {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinLaunchHistoryEmptyTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let report = LaunchHistoryService(paths: paths).report()

        #expect(report.totalLaunchCount == 0)
        #expect(report.records.isEmpty)
        #expect(report.stateCounts.isEmpty)
        #expect(report.latestStartedAt == nil)
    }
}
