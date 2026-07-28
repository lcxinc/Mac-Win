import Foundation
import Testing
@testable import MacWinCore

@Suite("Software collection history service")
struct SoftwareCollectionHistoryServiceTests {
    @Test("History records collection exports and downloads as JSON and CSV")
    func historyRecordsCollectionActions() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinSoftwareCollectionHistoryTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let service = SoftwareCollectionHistoryService(paths: paths)
        let collection = SoftwareCollectionReport(
            generatedAt: Date(timeIntervalSince1970: 10),
            rootPath: root.path,
            collections: [
                SoftwareCollectionDefinition(
                    id: "baseline",
                    name: "Baseline",
                    purpose: "Baseline apps",
                    requiredRecipeIds: ["7zip", "steam"]
                )
            ],
            missingRecipeIds: ["steam"],
            entries: [
                SoftwareCollectionEntry(
                    recipeId: "7zip",
                    name: "7-Zip",
                    publisher: "7-Zip",
                    category: "Utilities",
                    collectionIds: ["baseline"],
                    compatibilityRating: .good,
                    installerMode: .download,
                    installerFileName: "7z.exe",
                    installerSourceURL: "https://example.test/7z.exe",
                    expectedSha256: String(repeating: "a", count: 64),
                    installerHashStatus: .match,
                    cachedInstallerPath: root.appendingPathComponent("Downloads/7z.exe").path,
                    cachedInstallerExists: true,
                    softwareState: .verified,
                    smokeStage: .verified,
                    smokeSeverity: .passed,
                    installedLauncherCount: 1,
                    latestLaunchState: .completed,
                    latestLaunchLogPath: root.appendingPathComponent("Logs/7zip.log").path,
                    latestLogHealth: .passed,
                    readinessIssues: [],
                    recommendedProbeIds: []
                )
            ]
        )

        let exportRecord = SoftwareCollectionHistoryService.record(
            action: .exportCSV,
            state: .succeeded,
            collection: collection,
            startedAt: Date(timeIntervalSince1970: 100),
            endedAt: Date(timeIntervalSince1970: 101),
            outputPath: root.appendingPathComponent("Logs/software-collection.csv").path
        )
        let downloadRecord = SoftwareCollectionHistoryService.record(
            action: .downloadMissingInstallers,
            state: .failed,
            collection: collection,
            startedAt: Date(timeIntervalSince1970: 200),
            endedAt: Date(timeIntervalSince1970: 202),
            recipeIds: ["steam"],
            completedRecipeIds: [],
            errorMessage: "network unavailable"
        )
        try service.save(exportRecord)
        try service.save(downloadRecord)

        let report = service.report()
        #expect(report.totalRecordCount == 2)
        #expect(report.succeededCount == 1)
        #expect(report.failedCount == 1)
        #expect(report.downloadActionCount == 1)
        #expect(report.exportActionCount == 1)
        #expect(report.records.map(\.action) == [.downloadMissingInstallers, .exportCSV])
        #expect(FileManager.default.fileExists(atPath: service.recordURL(for: exportRecord).path))

        let csv = SoftwareCollectionHistoryService.csv(report: report)
        #expect(csv.contains("id,action,state,started_at,ended_at,duration_ms,collection_count,recipe_count"))
        #expect(csv.contains("downloadMissingInstallers,failed"))
        #expect(csv.contains("network unavailable"))
        #expect(csv.contains("exportCSV,succeeded"))
    }
}
