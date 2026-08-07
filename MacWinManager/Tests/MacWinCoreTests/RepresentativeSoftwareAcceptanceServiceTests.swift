import Foundation
import Testing
@testable import MacWinCore

@Suite("Representative software acceptance")
struct RepresentativeSoftwareAcceptanceServiceTests {
    @Test("Launch-only evidence remains pending functional proof")
    func launchOnlyEvidenceIsNotPassed() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRepresentativeAcceptance-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let matrix = NativeUIApplicationMatrixReport(
            generatedAt: Date(timeIntervalSince1970: 100),
            rootPath: root.path,
            entries: [
                entry(
                    sampleId: "hoyoplay-cn",
                    family: .hoyoPlay,
                    name: "HoYoPlay",
                    availability: .installed,
                    evidence: .observed
                ),
                entry(
                    sampleId: "steam",
                    family: .steam,
                    name: "Steam",
                    availability: .installed,
                    evidence: .notRun
                ),
                entry(
                    sampleId: "firefox-browser",
                    family: .browser,
                    name: "Firefox",
                    availability: .installed,
                    evidence: .passed
                ),
                entry(
                    sampleId: "libreoffice-suite",
                    family: .office,
                    name: "LibreOffice",
                    availability: .installed,
                    evidence: .failed
                ),
                entry(
                    sampleId: "unrelated",
                    family: .office,
                    name: "Unrelated",
                    availability: .installed,
                    evidence: .passed
                )
            ]
        )

        let report = RepresentativeSoftwareAcceptanceService(paths: MacWinPaths(root: root))
            .report(matrix: matrix, generatedAt: Date(timeIntervalSince1970: 200))

        #expect(report.targetCount == 4)
        #expect(report.passedCount == 1)
        #expect(report.failedCount == 1)
        #expect(report.pendingCount == 2)
        #expect(report.entries.first(where: { $0.sampleId == "hoyoplay-cn" })?.state == .needsFunctionalProof)
        #expect(report.entries.first(where: { $0.sampleId == "steam" })?.state == .needsLaunch)
        #expect(report.entries.first(where: { $0.sampleId == "firefox-browser" })?.state == .passed)
        #expect(report.entries.first(where: { $0.sampleId == "libreoffice-suite" })?.state == .failed)
        #expect(report.entries.contains(where: { $0.sampleId == "unrelated" }) == false)
    }

    @Test("Acceptance report is persisted in the software acceptance log directory")
    func reportIsPersisted() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinRepresentativeAcceptanceSave-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = MacWinPaths(root: root)
        let report = RepresentativeSoftwareAcceptanceReport(
            generatedAt: Date(timeIntervalSince1970: 300),
            rootPath: root.path,
            entries: []
        )

        let url = try RepresentativeSoftwareAcceptanceService(paths: paths).save(report)
        #expect(url.path == paths.logsDirectory
            .appendingPathComponent("SoftwareAcceptance", isDirectory: true)
            .appendingPathComponent("representative-latest.json")
            .path)
        let saved = try JSONStore().load(RepresentativeSoftwareAcceptanceReport.self, from: url)
        #expect(saved == report)
    }

    private func entry(
        sampleId: String,
        family: NativeUIApplicationMatrixFamily,
        name: String,
        availability: NativeUIApplicationAvailability,
        evidence: NativeUIApplicationLaunchEvidence
    ) -> NativeUIApplicationMatrixEntry {
        NativeUIApplicationMatrixEntry(
            id: sampleId,
            family: family,
            sampleId: sampleId,
            name: name,
            publisher: "Test",
            category: "Test",
            compatibilityProfileId: nil,
            availability: availability,
            availabilityDetail: "test",
            recipeId: sampleId,
            recipeAvailable: true,
            installerAvailable: false,
            installerPath: nil,
            bottleId: "bottle",
            bottleName: "Bottle",
            launcherId: sampleId,
            exePath: "C:\\Program Files\\Test\\app.exe",
            compatibilityProfileMatched: true,
            currentPreset: .automatic,
            presetOptions: [.automatic, .nativeDialogs, .disabled],
            launchEvidence: evidence,
            latestLaunchAt: Date(timeIntervalSince1970: 50),
            latestLaunchLogPath: "/tmp/test.log",
            latestLaunchExitCode: evidence == .failed ? 1 : 0,
            evidenceDetail: "test evidence",
            warnings: []
        )
    }
}
