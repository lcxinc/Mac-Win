import Foundation
import Testing
@testable import MacWinCore

@Suite("Real application compatibility matrix")
struct NativeUIApplicationMatrixServiceTests {
    @Test("Matrix entries have stable unique identifiers")
    func matrixEntriesHaveStableUniqueIdentifiers() {
        let samples = [
            SoftwareSampleCatalogService.defaultSamples.first { $0.id == "steam" }!,
            SoftwareSampleCatalogService.defaultSamples.first { $0.id == "firefox-browser" }!
        ]
        let service = NativeUIApplicationMatrixService(samples: samples)

        let first = service.report(bottles: [], recipes: [], generatedAt: Date(timeIntervalSince1970: 1))
        let second = service.report(bottles: [], recipes: [], generatedAt: Date(timeIntervalSince1970: 2))

        #expect(first.entries.map(\.id) == ["browser:firefox-browser", "steam:steam"])
        #expect(Set(first.entries.map(\.id)).count == first.entries.count)
        #expect(first.entries.map(\.id) == second.entries.map(\.id))
    }

    @Test("Installed launcher needs a real successful launch record before it is passed")
    func installedLauncherUsesLaunchEvidence() {
        let sample = SoftwareSampleProfile(
            id: "steam",
            name: "Steam",
            publisher: "Valve",
            category: "Game Store",
            purpose: "Steam UI",
            installSource: .signedRecipe,
            catalogRecipeId: "steam",
            launcherCandidates: ["C:\\Program Files\\Steam\\Steam.exe"],
            compatibilityProfileId: ApplicationCompatibilityProfile.steamClient.rawValue
        )
        let bottle = BottleManifest(
            id: "b1",
            name: "Game Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine",
            envOverrides: [NativeUIIntegrationPreset.environmentKey: NativeUIIntegrationPreset.automatic.environmentValue],
            installedApps: [
                LauncherManifest(
                    id: "steam",
                    appId: "steam",
                    bottleId: "b1",
                    displayName: "Steam",
                    exePath: "C:\\Program Files\\Steam\\Steam.exe",
                    envOverrides: ["MACWIN_COMPAT_PROFILE": ApplicationCompatibilityProfile.steamClient.rawValue]
                )
            ],
            updatedAt: Date(timeIntervalSince1970: 20)
        )
        let launch = WineLaunchRecord(
            id: "steam-launch",
            mode: .foregroundRun,
            state: .completed,
            logPath: "/tmp/steam.log",
            startedAt: Date(timeIntervalSince1970: 30),
            endedAt: Date(timeIntervalSince1970: 35),
            exitCode: 0,
            bottleId: "b1",
            bottleName: "Game Bottle",
            engineId: "engine",
            winePath: "/tmp/wine",
            exe: "C:\\Program Files\\Steam\\Steam.exe",
            args: [],
            commandLine: ["/tmp/wine", "C:\\Program Files\\Steam\\Steam.exe"],
            workingDirectory: "/tmp/b1",
            environment: ["MACWIN_COMPAT_PROFILE": ApplicationCompatibilityProfile.steamClient.rawValue]
        )
        let history = LaunchHistoryReport(
            rootPath: "/tmp/MacWin",
            logsPath: "/tmp/MacWin/Logs",
            recordsPath: "/tmp/MacWin/Logs/LaunchRecords",
            totalLaunchCount: 1,
            completedCount: 1,
            detachedCount: 0,
            failedToLaunchCount: 0,
            stateCounts: [WineLaunchState.completed.rawValue: 1],
            latestStartedAt: launch.startedAt,
            records: [launch]
        )

        let entry = NativeUIApplicationMatrixService(
            paths: MacWinPaths(root: URL(fileURLWithPath: "/tmp/MacWin")),
            samples: [sample]
        ).report(bottles: [bottle], recipes: [], launchHistory: history).entries[0]

        #expect(entry.family == .steam)
        #expect(entry.availability == .installed)
        #expect(entry.launchEvidence == .passed)
        #expect(entry.currentPreset == .automatic)
        #expect(entry.compatibilityProfileMatched)
        #expect(entry.presetOptions == [.automatic, .nativeDialogs, .disabled])
        #expect(entry.latestLaunchLogPath == "/tmp/steam.log")
    }

    @Test("Compatibility profile matching can select a launch record with different executable path")
    func compatibilityProfileFallbackMatchesByRecordProfile() {
        let sample = SoftwareSampleProfile(
            id: "firefox-browser",
            name: "Firefox",
            publisher: "Mozilla",
            category: "Browser",
            purpose: "Browser UI",
            installSource: .alreadyInstalled,
            launcherCandidates: ["C:\\Program Files\\Mozilla Firefox\\firefox.exe"],
            compatibilityProfileId: ApplicationCompatibilityProfile.browserGecko.rawValue
        )
        let bottle = BottleManifest(
            id: "b2",
            name: "Profile Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine",
            envOverrides: [NativeUIIntegrationPreset.environmentKey: NativeUIIntegrationPreset.automatic.environmentValue],
            installedApps: [
                LauncherManifest(
                    id: "firefox-browser",
                    appId: "firefox-browser",
                    bottleId: "b2",
                    displayName: "Firefox",
                    exePath: sample.launcherCandidates[0],
                    envOverrides: ["MACWIN_COMPAT_PROFILE": ApplicationCompatibilityProfile.browserGecko.rawValue]
                )
            ]
        )
        let launch = WineLaunchRecord(
            id: "firefox-profile-launch",
            mode: .foregroundRun,
            state: .completed,
            logPath: "/tmp/firefox-profile.log",
            startedAt: Date(timeIntervalSince1970: 40),
            endedAt: Date(timeIntervalSince1970: 45),
            exitCode: 0,
            bottleId: "b2",
            bottleName: "Profile Bottle",
            engineId: "engine",
            winePath: "/tmp/wine",
            exe: "C:\\Windows\\Installer\\firefox_wrapper.exe",
            args: [],
            commandLine: ["C:\\Windows\\Installer\\firefox_wrapper.exe"],
            workingDirectory: "/tmp/b2",
            environment: ["MACWIN_COMPAT_PROFILE": ApplicationCompatibilityProfile.browserGecko.rawValue]
        )
        let history = LaunchHistoryReport(
            rootPath: "/tmp/MacWin",
            logsPath: "/tmp/MacWin/Logs",
            recordsPath: "/tmp/MacWin/Logs/LaunchRecords",
            totalLaunchCount: 1,
            completedCount: 1,
            detachedCount: 0,
            failedToLaunchCount: 0,
            stateCounts: [WineLaunchState.completed.rawValue: 1],
            latestStartedAt: launch.startedAt,
            records: [launch]
        )

        let entry = NativeUIApplicationMatrixService(
            paths: MacWinPaths(root: URL(fileURLWithPath: "/tmp/MacWin")),
            samples: [sample]
        ).report(bottles: [bottle], recipes: [], launchHistory: history).entries[0]

        #expect(entry.sampleId == sample.id)
        #expect(entry.launchEvidence == NativeUIApplicationLaunchEvidence.passed)
        #expect(entry.compatibilityProfileMatched)
        #expect(entry.evidenceDetail == "passed-foregroundRun")
    }

    @Test("A cached browser installer is available but remains unverified without a launcher")
    func cachedInstallerDoesNotBecomeFalsePass() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinNativeUIApplicationMatrix-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = MacWinPaths(root: root)
        try FileManager.default.createDirectory(at: paths.downloadsDirectory, withIntermediateDirectories: true)
        try Data("installer".utf8).write(to: paths.downloadsDirectory.appendingPathComponent("ChromeSetup.exe"))

        let sample = SoftwareSampleProfile(
            id: "chrome-enterprise",
            name: "Chrome",
            publisher: "Google",
            category: "Browser",
            purpose: "Browser UI",
            installSource: .localInstaller,
            installerFileNames: ["ChromeSetup.exe"],
            launcherCandidates: ["C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"],
            compatibilityProfileId: ApplicationCompatibilityProfile.chromiumBrowser.rawValue
        )
        let entry = NativeUIApplicationMatrixService(paths: paths, samples: [sample])
            .report(bottles: [], recipes: [])
            .entries[0]

        #expect(entry.family == .browser)
        #expect(entry.availability == .installerAvailable)
        #expect(entry.installerAvailable)
        #expect(entry.launchEvidence == .notRun)
        #expect(entry.launchEvidence != .passed)
        #expect(entry.bottleId == nil)
    }

    @Test("A signed recipe is reported separately from an installed launcher")
    func signedRecipeIsActionableWithoutInstallEvidence() {
        let sample = SoftwareSampleProfile(
            id: "lenovo-app-store",
            name: "Lenovo App Store",
            publisher: "Lenovo",
            category: "App Store",
            purpose: "Store UI",
            installSource: .signedRecipe,
            catalogRecipeId: "lenovo-app-store",
            launcherCandidates: ["C:\\Program Files (x86)\\Lenovo\\LeAppStore\\LenovoAppStore.exe"],
            compatibilityProfileId: ApplicationCompatibilityProfile.lenovoAppStore.rawValue
        )
        let recipe = RecipeManifest(
            id: "lenovo-app-store",
            name: "Lenovo App Store",
            publisher: "Lenovo",
            category: "App Store",
            compatibilityRating: .experimental,
            installer: InstallerSpec(mode: .download, url: "https://example.invalid/lenovo.exe", fileName: "lenovo.exe"),
            bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
            engineRequirements: EngineRequirements(),
            launchers: [LauncherRecipe(id: "lenovo", displayName: "Lenovo App Store", exePath: sample.launcherCandidates[0])]
        )
        let entry = NativeUIApplicationMatrixService(
            paths: MacWinPaths(root: URL(fileURLWithPath: "/tmp/MacWin")),
            samples: [sample]
        ).report(bottles: [], recipes: [recipe]).entries[0]

        #expect(entry.availability == .recipeAvailable)
        #expect(entry.recipeAvailable)
        #expect(entry.launchEvidence == .notRun)
        #expect(entry.bottleId == nil)
    }

    @Test("A kept-alive GUI launch is observed until a functional workload passes")
    func keptAliveLaunchNeedsFunctionalEvidence() {
        let sample = firefoxSample()
        let bottle = bottle(for: sample)
        let launchOnly = SoftwareSmokeRunReport(
            generatedAt: "2026-07-16T05:40:07Z",
            runId: "firefox-launch-only",
            suite: "browser",
            sample: sample.id,
            prefix: "/tmp/firefox",
            logDirectory: "/tmp/firefox-logs",
            recordCount: 1,
            stateCounts: ["launched": 1],
            records: [
                SoftwareSmokeRunRecord(
                    id: sample.id,
                    phase: "launch",
                    state: "launched",
                    exitCode: 124,
                    logPath: "/tmp/firefox-launch.log"
                )
            ]
        )

        let entry = NativeUIApplicationMatrixService(samples: [sample]).report(
            bottles: [bottle],
            recipes: [],
            smokeReports: [launchOnly]
        ).entries[0]

        #expect(entry.launchEvidence == .observed)
        #expect(entry.latestLaunchLogPath == "/tmp/firefox-launch.log")
        #expect(entry.warnings.contains { $0.contains("functional workload") })
    }

    @Test("Browser and office workloads promote observed launches to passed")
    func functionalWorkloadsPromoteLaunchEvidence() {
        let firefox = firefoxSample()
        let libreOffice = SoftwareSampleProfile(
            id: "libreoffice-suite",
            name: "LibreOffice",
            publisher: "The Document Foundation",
            category: "Office Suite",
            purpose: "Document UI",
            installSource: .alreadyInstalled,
            launcherCandidates: ["C:\\Program Files\\LibreOffice\\program\\swriter.exe"],
            compatibilityProfileId: ApplicationCompatibilityProfile.officeSuite.rawValue
        )
        let reports = [
            smokeReport(
                sampleId: firefox.id,
                suite: "browser",
                verificationPhase: "browser-workload",
                verificationLog: "/tmp/firefox-browser-workload.log"
            ),
            smokeReport(
                sampleId: libreOffice.id,
                suite: "office",
                verificationPhase: "core-workload",
                verificationLog: "/tmp/libreoffice-core-workload.log"
            )
        ]
        let matrix = NativeUIApplicationMatrixService(samples: [firefox, libreOffice]).report(
            bottles: [bottle(for: firefox), bottle(for: libreOffice, id: "office-bottle")],
            recipes: [],
            smokeReports: reports
        )

        #expect(matrix.passedCount == 2)
        #expect(matrix.entries.first { $0.sampleId == firefox.id }?.evidenceDetail == "passed-smoke-browser-workload")
        #expect(matrix.entries.first { $0.sampleId == libreOffice.id }?.latestLaunchLogPath == "/tmp/libreoffice-core-workload.log")
    }

    @Test("A newer launch failure supersedes older functional evidence")
    func newerFailureSupersedesOlderPass() {
        let sample = firefoxSample()
        let appBottle = bottle(for: sample)
        let failed = WineLaunchRecord(
            id: "firefox-current-failure",
            mode: .foregroundRun,
            state: .failedToLaunch,
            logPath: "/tmp/firefox-current-failure.log",
            startedAt: Date(timeIntervalSince1970: 2_000_000_000),
            endedAt: Date(timeIntervalSince1970: 2_000_000_001),
            exitCode: 1,
            bottleId: appBottle.id,
            bottleName: appBottle.name,
            engineId: appBottle.engineId,
            winePath: "/tmp/wine",
            exe: sample.launcherCandidates[0],
            args: [],
            commandLine: ["/tmp/wine", sample.launcherCandidates[0]],
            workingDirectory: "/tmp/app-bottle",
            environment: [:]
        )
        let history = LaunchHistoryReport(
            rootPath: "/tmp/MacWin",
            logsPath: "/tmp/MacWin/Logs",
            recordsPath: "/tmp/MacWin/Logs/LaunchRecords",
            totalLaunchCount: 1,
            completedCount: 0,
            detachedCount: 0,
            failedToLaunchCount: 1,
            stateCounts: [WineLaunchState.failedToLaunch.rawValue: 1],
            latestStartedAt: failed.startedAt,
            records: [failed]
        )
        let olderPass = smokeReport(
            sampleId: sample.id,
            suite: "browser",
            verificationPhase: "browser-workload",
            verificationLog: "/tmp/firefox-browser-workload.log"
        )

        let entry = NativeUIApplicationMatrixService(samples: [sample]).report(
            bottles: [appBottle],
            recipes: [],
            launchHistory: history,
            smokeReports: [olderPass]
        ).entries[0]

        #expect(entry.launchEvidence == .failed)
        #expect(entry.latestLaunchLogPath == failed.logPath)
    }

    @Test("A newer failed smoke launch supersedes an older workload pass")
    func newerSmokeFailureSupersedesOlderPass() {
        let sample = firefoxSample()
        let olderPass = smokeReport(
            sampleId: sample.id,
            suite: "browser",
            verificationPhase: "browser-workload",
            verificationLog: "/tmp/firefox-browser-workload.log"
        )
        let newerFailure = SoftwareSmokeRunReport(
            generatedAt: "2026-08-06T03:33:52Z",
            runId: "firefox-current-failure",
            suite: "browser",
            sample: sample.id,
            prefix: "/tmp/firefox",
            logDirectory: "/tmp/firefox-current",
            recordCount: 2,
            stateCounts: ["failed": 1, "passed": 1],
            records: [
                SoftwareSmokeRunRecord(
                    id: sample.id,
                    phase: "launch",
                    state: "failed",
                    exitCode: 5,
                    logPath: "/tmp/firefox-current-launch.log"
                ),
                SoftwareSmokeRunRecord(
                    id: sample.id,
                    phase: "browser-workload",
                    state: "passed",
                    exitCode: 0,
                    logPath: "/tmp/firefox-current-workload.log"
                )
            ]
        )

        let entry = NativeUIApplicationMatrixService(samples: [sample]).report(
            bottles: [bottle(for: sample)],
            recipes: [],
            smokeReports: [newerFailure, olderPass]
        ).entries[0]

        #expect(entry.launchEvidence == .failed)
        #expect(entry.evidenceDetail == "failed-smoke-launch")
        #expect(entry.latestLaunchExitCode == 5)
    }

    @Test("A newer locked-session skip makes GUI acceptance pending without preserving a false failure")
    func lockedSessionSkipIsPending() {
        let sample = firefoxSample()
        let failed = SoftwareSmokeRunReport(
            generatedAt: "2026-08-06T03:33:52Z",
            runId: "firefox-locked-false-failure",
            suite: "browser",
            sample: sample.id,
            prefix: "/tmp/firefox",
            logDirectory: "/tmp/firefox-failed",
            recordCount: 1,
            stateCounts: ["failed": 1],
            records: [SoftwareSmokeRunRecord(id: sample.id, phase: "launch", state: "failed", exitCode: 5)]
        )
        let locked = SoftwareSmokeRunReport(
            generatedAt: "2026-08-06T03:40:00Z",
            runId: "firefox-locked-recheck",
            suite: "browser",
            sample: sample.id,
            prefix: "/tmp/firefox",
            logDirectory: "/tmp/firefox-locked",
            recordCount: 1,
            stateCounts: ["skipped": 1],
            records: [
                SoftwareSmokeRunRecord(
                    id: sample.id,
                    phase: "launch",
                    state: "skipped",
                    exitCode: 122,
                    note: "macOS session is locked; GUI launch requires an unlocked session."
                )
            ]
        )

        let entry = NativeUIApplicationMatrixService(samples: [sample]).report(
            bottles: [bottle(for: sample)],
            recipes: [],
            smokeReports: [locked, failed]
        ).entries[0]

        #expect(entry.launchEvidence == .notRun)
        #expect(entry.evidenceDetail == "not-run-smoke-session-locked")
        #expect(entry.latestLaunchExitCode == 122)
    }

    @Test("Lenovo rendered-content proof requires structured checks and a substantial image")
    func lenovoRenderedContentProofIsVerified() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinLenovoVisualProof-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let imageURL = root.appendingPathComponent("lenovo-app-store-cdp.png")
        try Data(repeating: 1, count: 20_000).write(to: imageURL)
        let analysisURL = root.appendingPathComponent("lenovo-app-store-cdp-analysis.json")
        try JSONSerialization.data(withJSONObject: [
            "classification": "rendered",
            "width": 1060,
            "height": 680,
            "sampledPixels": 59_401,
            "path": imageURL.path
        ]).write(to: analysisURL)
        let proofURL = root.appendingPathComponent("lenovo-app-store-cdp-proof.json")
        try JSONSerialization.data(withJSONObject: [
            "status": "rendered",
            "failedChecks": [],
            "analysisPath": analysisURL.path,
            "checks": [
                "targetURL": true,
                "targetTitle": true,
                "documentComplete": true,
                "nativeCommandLineReady": true,
                "substantialDOM": true,
                "expectedText": true,
                "imagesLoaded": true,
                "compositorImage": true,
                "opaqueImage": true
            ]
        ]).write(to: proofURL)
        let sample = SoftwareSampleProfile(
            id: "lenovo-app-store",
            name: "Lenovo App Store",
            publisher: "Lenovo",
            category: "App Store",
            purpose: "Store UI",
            installSource: .alreadyInstalled,
            launcherCandidates: ["C:\\Program Files (x86)\\Lenovo\\LeAppStore\\LenovoAppStore.exe"],
            compatibilityProfileId: ApplicationCompatibilityProfile.lenovoAppStore.rawValue
        )
        let report = SoftwareSmokeRunReport(
            generatedAt: "2026-07-16T05:50:05Z",
            runId: "lenovo-rendered",
            suite: "market",
            sample: sample.id,
            prefix: "/tmp/lenovo",
            logDirectory: root.path,
            recordCount: 1,
            stateCounts: ["launched": 1],
            records: [SoftwareSmokeRunRecord(id: sample.id, phase: "launch", state: "launched", exitCode: 124)]
        )

        let entry = NativeUIApplicationMatrixService(samples: [sample]).report(
            bottles: [bottle(for: sample)],
            recipes: [],
            smokeReports: [report]
        ).entries[0]

        #expect(entry.launchEvidence == .passed)
        #expect(entry.evidenceDetail == "passed-smoke-rendered-content")
        #expect(entry.latestLaunchLogPath == proofURL.path)
    }

    private func firefoxSample() -> SoftwareSampleProfile {
        SoftwareSampleProfile(
            id: "firefox-browser",
            name: "Mozilla Firefox",
            publisher: "Mozilla",
            category: "Browser",
            purpose: "Browser UI",
            installSource: .alreadyInstalled,
            launcherCandidates: ["C:\\Program Files\\Mozilla Firefox\\firefox.exe"],
            compatibilityProfileId: ApplicationCompatibilityProfile.browserGecko.rawValue
        )
    }

    private func bottle(
        for sample: SoftwareSampleProfile,
        id: String = "app-bottle"
    ) -> BottleManifest {
        BottleManifest(
            id: id,
            name: "App Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine",
            envOverrides: [NativeUIIntegrationPreset.environmentKey: NativeUIIntegrationPreset.automatic.environmentValue],
            installedApps: [
                LauncherManifest(
                    id: sample.id,
                    appId: sample.id,
                    bottleId: id,
                    displayName: sample.name,
                    exePath: sample.launcherCandidates[0],
                    envOverrides: sample.compatibilityProfileId.map { ["MACWIN_COMPAT_PROFILE": $0] } ?? [:]
                )
            ]
        )
    }

    private func smokeReport(
        sampleId: String,
        suite: String,
        verificationPhase: String,
        verificationLog: String
    ) -> SoftwareSmokeRunReport {
        SoftwareSmokeRunReport(
            generatedAt: "2026-07-16T05:46:44Z",
            runId: "\(sampleId)-verified",
            suite: suite,
            sample: sampleId,
            prefix: "/tmp/\(sampleId)",
            logDirectory: "/tmp/\(sampleId)-logs",
            recordCount: 2,
            stateCounts: ["launched": 1, "passed": 1],
            records: [
                SoftwareSmokeRunRecord(id: sampleId, phase: "launch", state: "launched", exitCode: 124),
                SoftwareSmokeRunRecord(
                    id: sampleId,
                    phase: verificationPhase,
                    state: "passed",
                    exitCode: 0,
                    logPath: verificationLog
                )
            ]
        )
    }
}
