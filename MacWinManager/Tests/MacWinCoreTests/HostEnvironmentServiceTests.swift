import Foundation
import Testing
@testable import MacWinCore

@Suite("Host environment service")
struct HostEnvironmentServiceTests {
    @Test("Host environment report captures safe system paths and inventory")
    func hostEnvironmentReportCapturesSafeSystemPathsAndInventory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinHostEnvironmentTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()
        let service = HostEnvironmentService(
            paths: paths,
            systemInfoProvider: {
                HostSystemInfo(
                    operatingSystemVersion: "macOS 15.5 test",
                    hostArchitecture: "arm64",
                    processorCount: 12,
                    activeProcessorCount: 10,
                    physicalMemoryBytes: 36_000_000_000,
                    systemUptimeSeconds: 1234.4,
                    rosettaPathExists: true
                )
            },
            volumeInfoProvider: { _ in
                HostVolumeInfo(totalCapacityBytes: 8_000_000_000_000, availableCapacityBytes: 6_000_000_000_000)
            }
        )

        let report = service.report(
            engines: [EngineManifest(
                id: "wine-test",
                name: "Wine Test",
                wineVersion: "wine-11.11",
                arch: .win64,
                winePath: "/tmp/wine",
                wineserverPath: "/tmp/wineserver",
                runtimePath: "/tmp/runtime",
                defaultEnv: [:]
            )],
            bottles: [BottleManifest(id: "bottle", name: "Bottle", windowsVersion: "win11", arch: .win64, engineId: "wine-test")],
            recipes: [],
            recentLogCount: 2
        )

        #expect(report.operatingSystemVersion == "macOS 15.5 test")
        #expect(report.hostArchitecture == "arm64")
        #expect(report.rosettaPathExists == true)
        #expect(report.rootPath == root.path)
        #expect(report.pathStates.first { $0.id == "logs" }?.exists == true)
        #expect(report.pathStates.first { $0.id == "logs" }?.isDirectory == true)
        #expect(report.volumeAvailableCapacityBytes == 6_000_000_000_000)
        #expect(report.engineCount == 1)
        #expect(report.bottleCount == 1)
        #expect(report.recipeCount == 0)
        #expect(report.recentLogCount == 2)

        let csv = HostEnvironmentReport.csv(report: report)
        #expect(csv.contains("section,key,value"))
        #expect(csv.contains("system,architecture,arm64"))
        #expect(csv.contains("system,rosetta_path_exists,true"))
        #expect(csv.contains("inventory,engine_count,1"))
        #expect(csv.contains("path,logs,\(paths.logsDirectory.path)"))
    }
}
