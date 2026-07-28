import Foundation
import Testing
@testable import MacWinCore

@Suite("Software test plan service")
struct SoftwareTestPlanServiceTests {
    @Test("Software test plan combines recipes installers launches and logs")
    func softwareTestPlanCombinesCurrentState() {
        let root = "/tmp/MacWinSoftwareTestPlan"
        let recipes = [
            recipe(id: "seven", name: "7-Zip", category: "Utilities", rating: .excellent, mode: .download),
            recipe(id: "steam", name: "Steam", category: "Game Store", rating: .experimental, mode: .download),
            recipe(id: "hoyoplay-cn", name: "HoYoPlay", category: "Game Launcher", rating: .experimental, mode: .alreadyInstalled),
            recipe(id: "notepad", name: "Notepad++", category: "Developer Tools", rating: .good, mode: .download),
            recipe(id: "vlc", name: "VLC", category: "Media", rating: .limited, mode: .download),
            recipe(id: "local-tool", name: "Local Tool", category: "Utilities", rating: .unknown, mode: .localFile),
            recipe(id: "disabled", name: "Disabled", category: "Utilities", rating: .unknown, mode: .download, disabledReason: "known hang")
        ]
        let readiness = RecipeReadinessReport(rootPath: root, entries: recipes.map { recipe in
            RecipeReadinessEntry(
                recipeId: recipe.id,
                recipeName: recipe.name,
                publisher: recipe.publisher,
                category: recipe.category,
                compatibilityRating: recipe.compatibilityRating,
                installerMode: recipe.installer.mode,
                state: recipe.disabledReason == nil ? .ready : .disabled,
                issues: recipe.disabledReason == nil ? [] : [.disabled],
                warningCount: 0,
                requiresWin32: recipe.engineRequirements.requiresWin32,
                compatibleEngineIds: ["engine"],
                launcherCount: recipe.launchers.count,
                fileName: recipe.installer.fileName,
                sha256Present: recipe.installer.sha256 != nil
            )
        })
        let installerAssets = InstallerAssetReport(
            rootPath: root,
            downloadsPath: "\(root)/Downloads",
            recipes: [
                installer(recipe: recipes[0], hash: .match, cached: true),
                installer(recipe: recipes[1], hash: .mismatch, cached: true),
                installer(recipe: recipes[2], hash: .notApplicable, cached: false),
                installer(recipe: recipes[3], hash: .match, cached: true),
                installer(recipe: recipes[4], hash: .match, cached: true),
                installer(recipe: recipes[5], hash: .notExpected, cached: false),
                installer(recipe: recipes[6], hash: .missing, cached: false)
            ],
            orphanedDownloads: []
        )
        let installHistory = InstallHistoryReport(
            rootPath: root,
            logsPath: "\(root)/Logs",
            recordsPath: "\(root)/Logs/InstallRecords",
            totalTaskCount: 3,
            succeededCount: 1,
            failedCount: 1,
            runningCount: 0,
            launchedCount: 1,
            stateCounts: ["succeeded": 1, "failed": 1, "launched": 1],
            latestStartedAt: Date(timeIntervalSince1970: 220),
            tasks: [
                InstallTask(
                    id: "vlc-install",
                    recipeId: "vlc",
                    bottleId: "bottle",
                    state: .failed,
                    progressText: "MSI hung",
                    logPath: "\(root)/Logs/vlc-install.log",
                    startedAt: Date(timeIntervalSince1970: 220),
                    endedAt: Date(timeIntervalSince1970: 221),
                    exitCode: 1603
                ),
                InstallTask(
                    id: "local-tool-install",
                    recipeId: "local-tool",
                    bottleId: "bottle",
                    state: .launched,
                    progressText: "Launched interactive installer",
                    logPath: "\(root)/Logs/local-tool-install.log",
                    startedAt: Date(timeIntervalSince1970: 180)
                ),
                InstallTask(
                    id: "notepad-install",
                    recipeId: "notepad",
                    bottleId: "bottle",
                    state: .succeeded,
                    progressText: "Installed",
                    logPath: "\(root)/Logs/notepad-install.log",
                    startedAt: Date(timeIntervalSince1970: 100),
                    endedAt: Date(timeIntervalSince1970: 101),
                    exitCode: 0
                )
            ]
        )
        let hoyoLog = "\(root)/Logs/hoyoplay.log"
        let notepadLog = "\(root)/Logs/notepad.log"
        let logs = CapabilityLogReport(
            directory: "\(root)/Logs",
            recentLogCount: 2,
            healthCounts: ["attention": 1, "passed": 1],
            hintCounts: ["blankWindowIssue": 1, "passObserved": 1],
            issueReport: LogIssueReport(
                logs: [],
                topIssues: [],
                recentFailures: [
                    LogIssueSample(
                        name: "hoyoplay.log",
                        path: hoyoLog,
                        modifiedAt: Date(timeIntervalSince1970: 305),
                        health: "attention",
                        errorCount: 0,
                        warningCount: 1,
                        fixmeCount: 0,
                        passCount: 0,
                        failCount: 0,
                        hints: ["blankWindowIssue"],
                        probableIssueIds: ["blank-window"]
                    )
                ]
            ),
            recommendations: [],
            entries: [
                CapabilityLogEntry(
                    name: "hoyoplay.log",
                    path: hoyoLog,
                    modifiedAt: Date(timeIntervalSince1970: 305),
                    byteCount: 20,
                    health: "attention",
                    errorCount: 0,
                    warningCount: 1,
                    fixmeCount: 0,
                    passCount: 0,
                    failCount: 0,
                    hints: ["blankWindowIssue"]
                ),
                CapabilityLogEntry(
                    name: "notepad.log",
                    path: notepadLog,
                    modifiedAt: Date(timeIntervalSince1970: 300),
                    byteCount: 20,
                    health: "passed",
                    errorCount: 0,
                    warningCount: 0,
                    fixmeCount: 0,
                    passCount: 1,
                    failCount: 0,
                    hints: ["passObserved"]
                )
            ]
        )
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine",
            installedApps: [
                launcher(recipeId: "hoyoplay-cn", id: "hoyoplay", name: "HoYoPlay", exe: "C:\\Program Files\\miHoYo Launcher\\HYP.exe"),
                launcher(recipeId: "notepad", id: "notepad", name: "Notepad++", exe: "C:\\Program Files\\Notepad++\\notepad++.exe")
            ]
        )
        let launchHistory = LaunchHistoryReport(
            rootPath: root,
            logsPath: "\(root)/Logs",
            recordsPath: "\(root)/Logs/LaunchRecords",
            totalLaunchCount: 2,
            completedCount: 2,
            detachedCount: 2,
            failedToLaunchCount: 0,
            stateCounts: ["completed": 2],
            latestStartedAt: Date(timeIntervalSince1970: 300),
            records: [
                launch(recipeId: "hoyoplay-cn", exe: "C:\\Program Files\\miHoYo Launcher\\HYP.exe", log: hoyoLog, startedAt: 305, exitCode: 0),
                launch(recipeId: "notepad", exe: "C:\\Program Files\\Notepad++\\notepad++.exe", log: notepadLog, startedAt: 300, exitCode: 0)
            ]
        )

        let report = SoftwareTestPlanService.report(
            rootPath: root,
            recipes: recipes,
            bottles: [bottle],
            readiness: readiness,
            installerAssets: installerAssets,
            installHistory: installHistory,
            launchHistory: launchHistory,
            logs: logs,
            generatedAt: Date(timeIntervalSince1970: 400)
        )

        #expect(report.recipeCount == 7)
        #expect(report.readyToInstallCount == 1)
        #expect(report.installedCount == 2)
        #expect(report.verifiedCount == 1)
        #expect(report.failingCount == 1)
        #expect(report.reviewCount == 1)
        #expect(report.stateCounts["readyToInstall"] == 1)
        #expect(report.stateCounts["hashMismatch"] == 1)
        #expect(report.stateCounts["needsReview"] == 1)
        #expect(report.stateCounts["verified"] == 1)
        #expect(report.stateCounts["installFailed"] == 1)
        #expect(report.stateCounts["installerLaunched"] == 1)
        #expect(report.stateCounts["disabled"] == 1)
        #expect(report.entries.first { $0.recipeId == "seven" }?.state == .readyToInstall)
        #expect(report.entries.first { $0.recipeId == "steam" }?.state == .hashMismatch)
        #expect(report.entries.first { $0.recipeId == "hoyoplay-cn" }?.state == .needsReview)
        #expect(report.entries.first { $0.recipeId == "hoyoplay-cn" }?.probableIssueIds == ["blank-window"])
        #expect(report.entries.first { $0.recipeId == "notepad" }?.state == .verified)
        #expect(report.entries.first { $0.recipeId == "vlc" }?.state == .installFailed)
        #expect(report.entries.first { $0.recipeId == "local-tool" }?.state == .installerLaunched)
        #expect(report.nextActions.first?.recipeId == "vlc")
        #expect(report.nextActions.map(\.recipeId).contains("steam"))

        let csv = SoftwareTestPlanService.csv(report: report)
        #expect(csv.contains("recipe_id,name,publisher,category,compatibility_rating,state,priority,recommended_action"))
        #expect(csv.contains("vlc,VLC,Publisher,Media,limited,installFailed,12"))
        #expect(csv.contains("steam,Steam,Publisher,Game Store,experimental,hashMismatch,13"))
        #expect(csv.contains("hoyoplay-cn,HoYoPlay,Publisher,Game Launcher,experimental,needsReview,23"))
        #expect(csv.contains("blank-window"))
        #expect(csv.contains("notepad,Notepad++,Publisher,Developer Tools,good,verified,81"))
    }

    @Test("Software test plan matches launch logs across canonical path aliases")
    func softwareTestPlanMatchesLaunchLogsAcrossCanonicalPathAliases() {
        let rawRoot = "/var/tmp/MacWinSoftwareTestPlanAlias"
        let canonicalRoot = URL(fileURLWithPath: rawRoot).resolvingSymlinksInPath().standardizedFileURL.path
        let recipe = recipe(id: "steam", name: "Steam", category: "Game Store", rating: .experimental, mode: .alreadyInstalled)
        let logPathFromLaunch = "\(rawRoot)/Logs/steam.log"
        let logPathFromLogReport = "\(canonicalRoot)/Logs/steam.log"
        let readiness = RecipeReadinessReport(
            rootPath: rawRoot,
            entries: [
                RecipeReadinessEntry(
                    recipeId: recipe.id,
                    recipeName: recipe.name,
                    publisher: recipe.publisher,
                    category: recipe.category,
                    compatibilityRating: recipe.compatibilityRating,
                    installerMode: recipe.installer.mode,
                    state: .ready,
                    issues: [],
                    warningCount: 0,
                    requiresWin32: false,
                    compatibleEngineIds: ["engine"],
                    launcherCount: recipe.launchers.count,
                    fileName: nil,
                    sha256Present: false
                )
            ]
        )
        let installerAssets = InstallerAssetReport(
            rootPath: rawRoot,
            downloadsPath: "\(rawRoot)/Downloads",
            recipes: [installer(recipe: recipe, hash: .notApplicable, cached: false)],
            orphanedDownloads: []
        )
        let logs = CapabilityLogReport(
            directory: "\(canonicalRoot)/Logs",
            recentLogCount: 1,
            healthCounts: ["attention": 1],
            hintCounts: ["steamNetworkProbe": 1],
            issueReport: LogIssueReport(
                logs: [],
                topIssues: [],
                recentFailures: [
                    LogIssueSample(
                        name: "steam.log",
                        path: logPathFromLogReport,
                        modifiedAt: Date(timeIntervalSince1970: 300),
                        health: "attention",
                        errorCount: 0,
                        warningCount: 1,
                        fixmeCount: 0,
                        passCount: 0,
                        failCount: 0,
                        hints: ["steamNetworkProbe"],
                        probableIssueIds: ["network-tls"]
                    )
                ]
            ),
            recommendations: [],
            entries: [
                CapabilityLogEntry(
                    name: "steam.log",
                    path: logPathFromLogReport,
                    modifiedAt: Date(timeIntervalSince1970: 300),
                    byteCount: 20,
                    health: "attention",
                    errorCount: 0,
                    warningCount: 1,
                    fixmeCount: 0,
                    passCount: 0,
                    failCount: 0,
                    hints: ["steamNetworkProbe"]
                )
            ]
        )
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine",
            installedApps: [
                launcher(recipeId: "steam", id: "steam", name: "Steam", exe: "C:\\Program Files\\Steam\\steam.exe")
            ]
        )
        let launchHistory = LaunchHistoryReport(
            rootPath: rawRoot,
            logsPath: "\(rawRoot)/Logs",
            recordsPath: "\(rawRoot)/Logs/LaunchRecords",
            totalLaunchCount: 1,
            completedCount: 1,
            detachedCount: 1,
            failedToLaunchCount: 0,
            stateCounts: ["completed": 1],
            latestStartedAt: Date(timeIntervalSince1970: 301),
            records: [
                launch(recipeId: "steam", exe: "C:\\Program Files\\Steam\\steam.exe", log: logPathFromLaunch, startedAt: 301, exitCode: 0)
            ]
        )

        let report = SoftwareTestPlanService.report(
            rootPath: rawRoot,
            recipes: [recipe],
            bottles: [bottle],
            readiness: readiness,
            installerAssets: installerAssets,
            installHistory: nil,
            launchHistory: launchHistory,
            logs: logs,
            generatedAt: Date(timeIntervalSince1970: 400)
        )

        let entry = report.entries.first
        #expect(entry?.state == .needsReview)
        #expect(entry?.probableIssueIds == ["network-tls"])
        #expect(entry?.latestLogHealth == .attention)
    }

    @Test("Software test plan treats old launch failures as review instead of current failures")
    func softwareTestPlanTreatsOldLaunchFailuresAsReview() {
        let root = "/tmp/MacWinSoftwareTestPlanOldLaunch"
        let recipe = recipe(id: "hoyoplay-cn", name: "HoYoPlay", category: "Game Launcher", rating: .experimental, mode: .alreadyInstalled)
        let logPath = "\(root)/Logs/hoyoplay.log"
        let readiness = RecipeReadinessReport(
            rootPath: root,
            entries: [
                RecipeReadinessEntry(
                    recipeId: recipe.id,
                    recipeName: recipe.name,
                    publisher: recipe.publisher,
                    category: recipe.category,
                    compatibilityRating: recipe.compatibilityRating,
                    installerMode: recipe.installer.mode,
                    state: .ready,
                    issues: [],
                    warningCount: 0,
                    requiresWin32: false,
                    compatibleEngineIds: ["engine"],
                    launcherCount: recipe.launchers.count,
                    fileName: nil,
                    sha256Present: false
                )
            ]
        )
        let installerAssets = InstallerAssetReport(
            rootPath: root,
            downloadsPath: "\(root)/Downloads",
            recipes: [installer(recipe: recipe, hash: .notApplicable, cached: false)],
            orphanedDownloads: []
        )
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine",
            installedApps: [
                launcher(recipeId: "hoyoplay-cn", id: "hoyoplay", name: "HoYoPlay", exe: "C:\\Program Files\\miHoYo Launcher\\HYP.exe")
            ]
        )
        let launchHistory = LaunchHistoryReport(
            rootPath: root,
            logsPath: "\(root)/Logs",
            recordsPath: "\(root)/Logs/LaunchRecords",
            totalLaunchCount: 1,
            completedCount: 1,
            detachedCount: 1,
            failedToLaunchCount: 0,
            stateCounts: ["completed": 1],
            latestStartedAt: Date(timeIntervalSince1970: 100),
            records: [
                launch(recipeId: "hoyoplay-cn", exe: "C:\\Program Files\\miHoYo Launcher\\HYP.exe", log: logPath, startedAt: 100, exitCode: 1)
            ]
        )
        let logs = CapabilityLogReport(
            directory: "\(root)/Logs",
            recentLogCount: 0,
            healthCounts: [:],
            hintCounts: [:],
            issueReport: LogIssueReport(logs: [], topIssues: [], recentFailures: []),
            recommendations: [],
            entries: []
        )

        let report = SoftwareTestPlanService.report(
            rootPath: root,
            recipes: [recipe],
            bottles: [bottle],
            readiness: readiness,
            installerAssets: installerAssets,
            installHistory: nil,
            launchHistory: launchHistory,
            logs: logs,
            generatedAt: Date(timeIntervalSince1970: 200_000)
        )

        #expect(report.failingCount == 0)
        #expect(report.reviewCount == 1)
        #expect(report.entries.first?.state == .needsReview)
        #expect(report.entries.first?.blockers.isEmpty == true)
    }

    @Test("Software test plan ignores stale failed launch when newer matching launch passed")
    func softwareTestPlanUsesNewestMatchingLaunchRecord() {
        let root = "/tmp/MacWinSoftwareTestPlanNewestLaunch"
        let recipe = recipe(id: "qownnotes-portable", name: "QOwnNotes", category: "Office", rating: .good, mode: .download)
        let oldLogPath = "\(root)/Logs/qownnotes-editor-launch.log"
        let newLogPath = "\(root)/Logs/qownnotes-portable-launch.log"
        let readiness = RecipeReadinessReport(
            rootPath: root,
            entries: [
                RecipeReadinessEntry(
                    recipeId: recipe.id,
                    recipeName: recipe.name,
                    publisher: recipe.publisher,
                    category: recipe.category,
                    compatibilityRating: recipe.compatibilityRating,
                    installerMode: recipe.installer.mode,
                    state: .ready,
                    issues: [],
                    warningCount: 0,
                    requiresWin32: false,
                    compatibleEngineIds: ["engine"],
                    launcherCount: recipe.launchers.count,
                    fileName: recipe.installer.fileName,
                    sha256Present: recipe.installer.sha256 != nil
                )
            ]
        )
        let installerAssets = InstallerAssetReport(
            rootPath: root,
            downloadsPath: "\(root)/Downloads",
            recipes: [
                RecipeInstallerAssetStatus(
                    recipeId: recipe.id,
                    recipeName: recipe.name,
                    publisher: recipe.publisher,
                    category: recipe.category,
                    compatibilityRating: recipe.compatibilityRating,
                    disabled: false,
                    disabledReason: nil,
                    installerMode: recipe.installer.mode,
                    fileName: recipe.installer.fileName,
                    sourceURL: recipe.installer.url,
                    expectedSha256: recipe.installer.sha256,
                    cachedPath: "\(root)/Downloads/\(recipe.installer.fileName ?? "")",
                    cachedExists: true,
                    hashStatus: .match
                )
            ],
            orphanedDownloads: []
        )
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine",
            installedApps: [
                launcher(
                    recipeId: "qownnotes-portable",
                    id: "qownnotes-portable",
                    name: "QOwnNotes",
                    exe: "C:\\macwin-portable\\qownnotes-portable\\QOwnNotes.exe"
                )
            ]
        )
        let launchHistory = LaunchHistoryReport(
            rootPath: root,
            logsPath: "\(root)/Logs",
            recordsPath: "\(root)/Logs/LaunchRecords",
            totalLaunchCount: 2,
            completedCount: 2,
            detachedCount: 2,
            failedToLaunchCount: 0,
            stateCounts: ["completed": 2],
            latestStartedAt: Date(timeIntervalSince1970: 1_000),
            records: [
                launch(
                    recipeId: "qownnotes-editor",
                    exe: "C:\\macwin-portable\\qownnotes-portable\\QOwnNotes.exe",
                    log: oldLogPath,
                    startedAt: 100,
                    exitCode: 53
                ),
                launch(
                    recipeId: "qownnotes-portable",
                    exe: "C:\\macwin-portable\\qownnotes-portable\\QOwnNotes.exe",
                    log: newLogPath,
                    startedAt: 1_000,
                    exitCode: 0
                )
            ]
        )
        let logs = CapabilityLogReport(
            directory: "\(root)/Logs",
            recentLogCount: 1,
            healthCounts: ["passed": 1],
            hintCounts: ["passObserved": 1],
            issueReport: LogIssueReport(logs: [], topIssues: [], recentFailures: []),
            recommendations: [],
            entries: [
                CapabilityLogEntry(
                    name: "qownnotes-portable-launch.log",
                    path: newLogPath,
                    modifiedAt: Date(timeIntervalSince1970: 1_002),
                    byteCount: 20,
                    health: "passed",
                    errorCount: 0,
                    warningCount: 0,
                    fixmeCount: 0,
                    passCount: 1,
                    failCount: 0,
                    hints: ["passObserved"]
                )
            ]
        )

        let report = SoftwareTestPlanService.report(
            rootPath: root,
            recipes: [recipe],
            bottles: [bottle],
            readiness: readiness,
            installerAssets: installerAssets,
            installHistory: nil,
            launchHistory: launchHistory,
            logs: logs,
            generatedAt: Date(timeIntervalSince1970: 1_100)
        )

        let entry = report.entries.first
        #expect(report.failingCount == 0)
        #expect(report.verifiedCount == 1)
        #expect(entry?.state == .verified)
        #expect(entry?.latestLaunchLogPath == newLogPath)
        #expect(entry?.latestLaunchExitCode == 0)
        #expect(entry?.blockers.isEmpty == true)
    }

    @Test("Software test plan treats kept-alive smoke SIGTERM as verified")
    func softwareTestPlanTreatsKeptAliveSmokeSIGTERMAsVerified() {
        let root = "/tmp/MacWinSoftwareTestPlanSteamSmoke"
        let recipe = recipe(id: "steam", name: "Steam", category: "Game Store", rating: .experimental, mode: .download)
        let logPath = "\(root)/Logs/high-performance-win11-steam-cli-smoke.log"
        let readiness = RecipeReadinessReport(
            rootPath: root,
            entries: [
                RecipeReadinessEntry(
                    recipeId: recipe.id,
                    recipeName: recipe.name,
                    publisher: recipe.publisher,
                    category: recipe.category,
                    compatibilityRating: recipe.compatibilityRating,
                    installerMode: recipe.installer.mode,
                    state: .ready,
                    issues: [],
                    warningCount: 0,
                    requiresWin32: false,
                    compatibleEngineIds: ["engine"],
                    launcherCount: recipe.launchers.count,
                    fileName: recipe.installer.fileName,
                    sha256Present: recipe.installer.sha256 != nil
                )
            ]
        )
        let installerAssets = InstallerAssetReport(
            rootPath: root,
            downloadsPath: "\(root)/Downloads",
            recipes: [
                RecipeInstallerAssetStatus(
                    recipeId: recipe.id,
                    recipeName: recipe.name,
                    publisher: recipe.publisher,
                    category: recipe.category,
                    compatibilityRating: recipe.compatibilityRating,
                    disabled: false,
                    disabledReason: nil,
                    installerMode: recipe.installer.mode,
                    fileName: recipe.installer.fileName,
                    sourceURL: recipe.installer.url,
                    expectedSha256: recipe.installer.sha256,
                    cachedPath: "\(root)/Downloads/\(recipe.installer.fileName ?? "")",
                    cachedExists: true,
                    hashStatus: .match
                )
            ],
            orphanedDownloads: []
        )
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine",
            installedApps: [
                launcher(
                    recipeId: "steam",
                    id: "steam",
                    name: "Steam",
                    exe: "C:\\Program Files\\Steam\\Steam.exe"
                )
            ]
        )
        let launchHistory = LaunchHistoryReport(
            rootPath: root,
            logsPath: "\(root)/Logs",
            recordsPath: "\(root)/Logs/LaunchRecords",
            totalLaunchCount: 1,
            completedCount: 1,
            detachedCount: 0,
            failedToLaunchCount: 0,
            stateCounts: ["completed": 1],
            latestStartedAt: Date(timeIntervalSince1970: 300),
            records: [
                launch(recipeId: "steam", exe: "C:\\Program Files\\Steam\\Steam.exe", log: logPath, startedAt: 300, exitCode: 15)
            ]
        )
        let logs = CapabilityLogReport(
            directory: "\(root)/Logs",
            recentLogCount: 1,
            healthCounts: ["passed": 1],
            hintCounts: ["passObserved": 1],
            issueReport: LogIssueReport(logs: [], topIssues: [], recentFailures: []),
            recommendations: [],
            entries: [
                CapabilityLogEntry(
                    name: "high-performance-win11-steam-cli-smoke.log",
                    path: logPath,
                    modifiedAt: Date(timeIntervalSince1970: 302),
                    byteCount: 20,
                    health: "passed",
                    errorCount: 0,
                    warningCount: 0,
                    fixmeCount: 0,
                    passCount: 1,
                    failCount: 0,
                    hints: ["passObserved"]
                )
            ]
        )

        let report = SoftwareTestPlanService.report(
            rootPath: root,
            recipes: [recipe],
            bottles: [bottle],
            readiness: readiness,
            installerAssets: installerAssets,
            installHistory: nil,
            launchHistory: launchHistory,
            logs: logs,
            generatedAt: Date(timeIntervalSince1970: 400)
        )

        let entry = report.entries.first
        #expect(report.failingCount == 0)
        #expect(report.verifiedCount == 1)
        #expect(entry?.state == .verified)
        #expect(entry?.latestLaunchExitCode == 15)
        #expect(entry?.blockers.isEmpty == true)
    }

    @Test("Software test plan does not let PortableApps helpers verify platform GUI")
    func softwareTestPlanDoesNotLetPortableAppsHelpersVerifyPlatformGUI() {
        let root = "/tmp/MacWinSoftwareTestPlanPortableAppsHelpers"
        let recipe = RecipeManifest(
            id: "portableapps-platform",
            name: "PortableApps.com Platform",
            publisher: "PortableApps.com",
            category: "App Store",
            compatibilityRating: .experimental,
            installer: InstallerSpec(
                mode: .localFile,
                fileName: "PortableApps.com_Platform_Setup.exe",
                sha256: String(repeating: "b", count: 64)
            ),
            bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
            engineRequirements: EngineRequirements(requiresWin32: true),
            launchers: [
                LauncherRecipe(
                    id: "portableapps-platform",
                    displayName: "PortableApps.com Platform",
                    exePath: "C:\\PortableApps\\PortableApps.com\\PortableAppsPlatform.exe"
                )
            ]
        )
        let readiness = RecipeReadinessReport(
            rootPath: root,
            entries: [
                RecipeReadinessEntry(
                    recipeId: recipe.id,
                    recipeName: recipe.name,
                    publisher: recipe.publisher,
                    category: recipe.category,
                    compatibilityRating: recipe.compatibilityRating,
                    installerMode: recipe.installer.mode,
                    state: .ready,
                    issues: [],
                    warningCount: 0,
                    requiresWin32: true,
                    compatibleEngineIds: ["engine"],
                    launcherCount: recipe.launchers.count,
                    fileName: recipe.installer.fileName,
                    sha256Present: true
                )
            ]
        )
        let installerAssets = InstallerAssetReport(
            rootPath: root,
            downloadsPath: "\(root)/Downloads",
            recipes: [
                RecipeInstallerAssetStatus(
                    recipeId: recipe.id,
                    recipeName: recipe.name,
                    publisher: recipe.publisher,
                    category: recipe.category,
                    compatibilityRating: recipe.compatibilityRating,
                    disabled: false,
                    disabledReason: nil,
                    installerMode: recipe.installer.mode,
                    fileName: recipe.installer.fileName,
                    sourceURL: nil,
                    expectedSha256: recipe.installer.sha256,
                    cachedPath: "\(root)/Downloads/\(recipe.installer.fileName ?? "")",
                    cachedExists: true,
                    hashStatus: .match
                )
            ],
            orphanedDownloads: []
        )
        let mainLauncher = LauncherManifest(
            id: "portableapps-platform",
            appId: "portableapps-platform",
            bottleId: "bottle",
            displayName: "PortableApps.com Platform",
            exePath: "C:\\PortableApps\\PortableApps.com\\PortableAppsPlatform.exe"
        )
        let helperLauncher = LauncherManifest(
            id: "portableapps-updater",
            appId: "portableapps-utilities",
            bottleId: "bottle",
            displayName: "PortableApps Updater",
            exePath: "C:\\PortableApps\\PortableApps.com\\PortableAppsUpdater.exe"
        )
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine",
            installedApps: [mainLauncher, helperLauncher]
        )
        let helperLogPath = "\(root)/Logs/high-performance-win11-portableapps-updater-cli-smoke.log"
        let launchHistory = LaunchHistoryReport(
            rootPath: root,
            logsPath: "\(root)/Logs",
            recordsPath: "\(root)/Logs/LaunchRecords",
            totalLaunchCount: 1,
            completedCount: 1,
            detachedCount: 0,
            failedToLaunchCount: 0,
            stateCounts: ["completed": 1],
            latestStartedAt: Date(timeIntervalSince1970: 300),
            records: [
                launch(recipeId: "portableapps-updater", exe: helperLauncher.exePath, log: helperLogPath, startedAt: 300, exitCode: 15)
            ]
        )
        let logs = CapabilityLogReport(
            directory: "\(root)/Logs",
            recentLogCount: 1,
            healthCounts: ["passed": 1],
            hintCounts: ["passObserved": 1],
            issueReport: LogIssueReport(logs: [], topIssues: [], recentFailures: []),
            recommendations: [],
            entries: [
                CapabilityLogEntry(
                    name: "high-performance-win11-portableapps-updater-cli-smoke.log",
                    path: helperLogPath,
                    modifiedAt: Date(timeIntervalSince1970: 302),
                    byteCount: 20,
                    health: "passed",
                    errorCount: 0,
                    warningCount: 0,
                    fixmeCount: 0,
                    passCount: 1,
                    failCount: 0,
                    hints: ["passObserved"]
                )
            ]
        )

        let report = SoftwareTestPlanService.report(
            rootPath: root,
            recipes: [recipe],
            bottles: [bottle],
            readiness: readiness,
            installerAssets: installerAssets,
            installHistory: nil,
            launchHistory: launchHistory,
            logs: logs,
            generatedAt: Date(timeIntervalSince1970: 400)
        )

        let entry = report.entries.first
        #expect(report.verifiedCount == 0)
        #expect(entry?.state == .installedNotLaunched)
        #expect(entry?.installedLauncherIds == ["portableapps-platform"])
        #expect(entry?.latestLaunchExitCode == nil)
    }

    @Test("Software test plan treats installed local-file smoke as verified")
    func softwareTestPlanTreatsInstalledLocalFileSmokeAsVerified() {
        let root = "/tmp/MacWinSoftwareTestPlanLenovoSmoke"
        let recipe = recipe(id: "lenovo-app-store", name: "联想应用商店", category: "App Store", rating: .experimental, mode: .localFile)
        let logPath = "\(root)/Logs/high-performance-win11-lenovo-app-store-cli-smoke.log"
        let readiness = RecipeReadinessReport(
            rootPath: root,
            entries: [
                RecipeReadinessEntry(
                    recipeId: recipe.id,
                    recipeName: recipe.name,
                    publisher: recipe.publisher,
                    category: recipe.category,
                    compatibilityRating: recipe.compatibilityRating,
                    installerMode: recipe.installer.mode,
                    state: .actionRequired,
                    issues: [.localInstallerRequired],
                    warningCount: 0,
                    requiresWin32: false,
                    compatibleEngineIds: ["engine"],
                    launcherCount: recipe.launchers.count,
                    fileName: recipe.installer.fileName,
                    sha256Present: recipe.installer.sha256 != nil
                )
            ]
        )
        let installerAssets = InstallerAssetReport(
            rootPath: root,
            downloadsPath: "\(root)/Downloads",
            recipes: [installer(recipe: recipe, hash: .notApplicable, cached: false)],
            orphanedDownloads: []
        )
        let bottle = BottleManifest(
            id: "bottle",
            name: "Bottle",
            windowsVersion: "win11",
            arch: .win64,
            engineId: "engine",
            installedApps: [
                launcher(
                    recipeId: recipe.id,
                    id: recipe.id,
                    name: recipe.name,
                    exe: "C:\\Program Files (x86)\\Lenovo\\LeAppStore\\LenovoAppStore.exe"
                )
            ]
        )
        let installHistory = InstallHistoryReport(
            rootPath: root,
            logsPath: "\(root)/Logs",
            recordsPath: "\(root)/Logs/InstallRecords",
            totalTaskCount: 1,
            succeededCount: 1,
            failedCount: 0,
            runningCount: 0,
            stateCounts: ["succeeded": 1],
            latestStartedAt: Date(timeIntervalSince1970: 200),
            tasks: [
                InstallTask(
                    id: "lenovo-install",
                    recipeId: recipe.id,
                    bottleId: "bottle",
                    state: .succeeded,
                    progressText: "Installed",
                    logPath: "\(root)/Logs/install-lenovo.log",
                    startedAt: Date(timeIntervalSince1970: 200),
                    endedAt: Date(timeIntervalSince1970: 220),
                    exitCode: 0
                )
            ]
        )
        let launchHistory = LaunchHistoryReport(
            rootPath: root,
            logsPath: "\(root)/Logs",
            recordsPath: "\(root)/Logs/LaunchRecords",
            totalLaunchCount: 1,
            completedCount: 1,
            detachedCount: 0,
            failedToLaunchCount: 0,
            stateCounts: ["completed": 1],
            latestStartedAt: Date(timeIntervalSince1970: 300),
            records: [
                launch(
                    recipeId: recipe.id,
                    exe: "C:\\Program Files (x86)\\Lenovo\\LeAppStore\\LenovoAppStore.exe",
                    log: logPath,
                    startedAt: 300,
                    exitCode: 15
                )
            ]
        )
        let logs = CapabilityLogReport(
            directory: "\(root)/Logs",
            recentLogCount: 0,
            healthCounts: [:],
            hintCounts: [:],
            issueReport: LogIssueReport(logs: [], topIssues: [], recentFailures: []),
            recommendations: [],
            entries: []
        )

        let report = SoftwareTestPlanService.report(
            rootPath: root,
            recipes: [recipe],
            bottles: [bottle],
            readiness: readiness,
            installerAssets: installerAssets,
            installHistory: installHistory,
            launchHistory: launchHistory,
            logs: logs,
            generatedAt: Date(timeIntervalSince1970: 400)
        )

        let entry = report.entries.first
        #expect(report.failingCount == 0)
        #expect(report.verifiedCount == 1)
        #expect(entry?.state == .verified)
        #expect(entry?.readinessIssues == [RecipeReadinessIssue.localInstallerRequired])
        #expect(entry?.blockers.isEmpty == true)
    }

    @Test("Software test plan surfaces current cached local installer failure")
    func softwareTestPlanSurfacesCurrentCachedLocalInstallerFailure() {
        let root = "/tmp/MacWinSoftwareTestPlanCachedLocalFailure"
        let recipe = RecipeManifest(
            id: "portableapps-platform",
            name: "PortableApps.com Platform",
            publisher: "PortableApps.com",
            category: "App Store",
            compatibilityRating: .experimental,
            installer: InstallerSpec(
                mode: .localFile,
                fileName: "PortableApps.com_Platform_Setup.exe",
                sha256: String(repeating: "b", count: 64)
            ),
            bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
            engineRequirements: EngineRequirements(requiresWin32: true),
            launchers: [
                LauncherRecipe(
                    id: "portableapps-platform",
                    displayName: "PortableApps.com Platform",
                    exePath: "C:\\PortableApps\\PortableApps.com\\PortableAppsPlatform.exe"
                )
            ]
        )
        let installLog = "\(root)/Logs/high-performance-win11-install-portableapps-platform.log"
        let readiness = RecipeReadinessReport(
            rootPath: root,
            entries: [
                RecipeReadinessEntry(
                    recipeId: recipe.id,
                    recipeName: recipe.name,
                    publisher: recipe.publisher,
                    category: recipe.category,
                    compatibilityRating: recipe.compatibilityRating,
                    installerMode: recipe.installer.mode,
                    state: .ready,
                    issues: [],
                    warningCount: 0,
                    requiresWin32: true,
                    compatibleEngineIds: ["engine"],
                    launcherCount: recipe.launchers.count,
                    fileName: "PortableApps.com_Platform_Setup.exe",
                    sha256Present: true
                )
            ]
        )
        let installerAssets = InstallerAssetReport(
            rootPath: root,
            downloadsPath: "\(root)/Downloads",
            recipes: [
                RecipeInstallerAssetStatus(
                    recipeId: recipe.id,
                    recipeName: recipe.name,
                    publisher: recipe.publisher,
                    category: recipe.category,
                    compatibilityRating: recipe.compatibilityRating,
                    disabled: false,
                    disabledReason: nil,
                    installerMode: recipe.installer.mode,
                    fileName: recipe.installer.fileName,
                    sourceURL: recipe.installer.url,
                    expectedSha256: recipe.installer.sha256,
                    cachedPath: "\(root)/Downloads/\(recipe.installer.fileName ?? "")",
                    cachedExists: true,
                    hashStatus: .match
                )
            ],
            orphanedDownloads: []
        )
        let installHistory = InstallHistoryReport(
            rootPath: root,
            logsPath: "\(root)/Logs",
            recordsPath: "\(root)/Logs/InstallRecords",
            totalTaskCount: 1,
            succeededCount: 0,
            failedCount: 1,
            runningCount: 0,
            launchedCount: 0,
            stateCounts: ["failed": 1],
            latestStartedAt: Date(timeIntervalSince1970: 300),
            tasks: [
                InstallTask(
                    id: "portable-install",
                    recipeId: recipe.id,
                    bottleId: "bottle",
                    state: .failed,
                    progressText: "Installer failed",
                    logPath: installLog,
                    startedAt: Date(timeIntervalSince1970: 300),
                    endedAt: Date(timeIntervalSince1970: 305),
                    exitCode: 15
                )
            ]
        )
        let report = SoftwareTestPlanService.report(
            rootPath: root,
            recipes: [recipe],
            bottles: [],
            readiness: readiness,
            installerAssets: installerAssets,
            installHistory: installHistory,
            launchHistory: nil,
            logs: CapabilityLogReport(
                directory: "\(root)/Logs",
                recentLogCount: 0,
                healthCounts: [:],
                hintCounts: [:],
                issueReport: LogIssueReport(logs: [], topIssues: [], recentFailures: []),
                recommendations: [],
                entries: []
            ),
            generatedAt: Date(timeIntervalSince1970: 310)
        )

        let entry = report.entries.first
        #expect(report.failingCount == 1)
        #expect(entry?.state == .installFailed)
        #expect(entry?.cachedInstallerPath == "\(root)/Downloads/\(recipe.installer.fileName ?? "")")
        #expect(entry?.blockers == ["installFailed"])
    }

    private func recipe(
        id: String,
        name: String,
        category: String,
        rating: CompatibilityRating,
        mode: InstallerMode,
        disabledReason: String? = nil
    ) -> RecipeManifest {
        RecipeManifest(
            id: id,
            name: name,
            publisher: "Publisher",
            category: category,
            compatibilityRating: rating,
            disabledReason: disabledReason,
            installer: InstallerSpec(
                mode: mode,
                url: mode == .download ? "https://example.test/\(id).exe" : nil,
                fileName: mode == .download ? "\(id).exe" : nil,
                sha256: mode == .download ? String(repeating: "a", count: 64) : nil
            ),
            bottleTemplate: BottleTemplate(windowsVersion: "win11", arch: .win64),
            engineRequirements: EngineRequirements(),
            launchers: [
                LauncherRecipe(
                    id: id,
                    displayName: name,
                    exePath: "C:\\Program Files\\\(name)\\\(id).exe"
                )
            ]
        )
    }

    private func installer(
        recipe: RecipeManifest,
        hash: InstallerHashStatus,
        cached: Bool
    ) -> RecipeInstallerAssetStatus {
        RecipeInstallerAssetStatus(
            recipeId: recipe.id,
            recipeName: recipe.name,
            publisher: recipe.publisher,
            category: recipe.category,
            compatibilityRating: recipe.compatibilityRating,
            disabled: recipe.disabledReason != nil,
            disabledReason: recipe.disabledReason,
            installerMode: recipe.installer.mode,
            fileName: recipe.installer.fileName,
            sourceURL: recipe.installer.url,
            expectedSha256: recipe.installer.sha256,
            cachedPath: recipe.installer.fileName.map { "/tmp/MacWinSoftwareTestPlan/Downloads/\($0)" },
            cachedExists: cached,
            hashStatus: hash
        )
    }

    private func launcher(recipeId: String, id: String, name: String, exe: String) -> LauncherManifest {
        LauncherManifest(
            id: id,
            appId: recipeId,
            bottleId: "bottle",
            displayName: name,
            exePath: exe
        )
    }

    private func launch(recipeId: String, exe: String, log: String, startedAt: TimeInterval, exitCode: Int32) -> WineLaunchRecord {
        WineLaunchRecord(
            id: "\(recipeId)-launch",
            mode: .detached,
            state: .completed,
            logPath: log,
            startedAt: Date(timeIntervalSince1970: startedAt),
            endedAt: Date(timeIntervalSince1970: startedAt + 2),
            durationMilliseconds: 2_000,
            processIdentifier: 100,
            exitCode: exitCode,
            bottleId: "bottle",
            bottleName: "Bottle",
            engineId: "engine",
            winePath: "/tmp/wine",
            exe: exe,
            args: [],
            commandLine: ["/tmp/wine", exe],
            workingDirectory: "/tmp",
            environment: [:]
        )
    }
}
