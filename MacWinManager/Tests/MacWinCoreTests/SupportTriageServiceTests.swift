import Foundation
import Testing
@testable import MacWinCore

@Suite("Support triage service")
struct SupportTriageServiceTests {
    @Test("Support triage prioritizes foundational blockers and exports reports")
    func supportTriagePrioritizesFoundationalBlockers() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinSupportTriageTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        try paths.ensureBaseDirectories()
        let testAssetRoot = root.appendingPathComponent("test-assets", isDirectory: true)
        try FileManager.default.createDirectory(at: testAssetRoot, withIntermediateDirectories: true)
        let generatedAt = Date(timeIntervalSince1970: 1_800)

        let steamLogPath = paths.logsDirectory.appendingPathComponent("steam.log").path
        var capability = CapabilityReportService(
            paths: paths,
            testAssetService: TestAssetService(root: testAssetRoot),
            runtimeProcessAuditService: RuntimeProcessAuditService(processListProvider: {
                """
                  401 C:\\Program Files\\miHoYo Launcher\\1.16.1.364\\HYP.exe --disable-direct-write --disable-features=DWriteFontProxy,UseDWriteCore
                  402 /Users/alice/project/Mac-Win/refs/build/bin/wine C:\\Apps\\Game.exe
                """
            }),
            runtimeApplicationAuditService: RuntimeApplicationAuditService(applicationListProvider: {
                """
                 1) "MacWin 管理器" ASN:0x0-0x2002: (in front)
                    bundleID="dev.local.macwin.manager"
                    bundle path="/Users/alice/project/Mac-Win/MacWinManager/dist/MacWin Manager.app"
                    executable path="/Users/alice/project/Mac-Win/MacWinManager/dist/MacWin Manager.app/Contents/MacOS/MacWinManagerApp"
                    pid = 201 type="Foreground" Arch=ARM64
                 2) "MacWin 管理器" ASN:0x0-0x3003:
                    bundleID="dev.local.macwin.manager"
                    bundle path="/Users/alice/project/Mac-Win/MacWinManager/dist/MacWin Manager.app"
                    executable path="/Users/alice/project/Mac-Win/MacWinManager/dist/MacWin Manager.app/Contents/MacOS/MacWinManagerApp"
                    pid = 202 type="Foreground" Arch=ARM64
                """
            }, processExists: { _ in true })
        ).makeReport(
            generatedAt: generatedAt,
            engines: [],
            bottles: [],
            recipes: [],
            diagnosticReport: DiagnosticReport(
                exitCode: 1,
                logURL: paths.logsDirectory.appendingPathComponent("diagnostics.log"),
                items: [],
                rawOutput: "FAIL graphics",
                timedOut: true,
                durationSeconds: 30
            )
        )
        let passedDiagnosticsLogPath = paths.logsDirectory
            .appendingPathComponent("diagnostics-high-performance-win11-tls-winhttp-win32-1234ABCD.log")
            .path
        capability.softwareSmokeMatrix = SoftwareSmokeMatrixReport(
            rootPath: root.path,
            rows: [
                SoftwareSmokeMatrixRow(
                    recipeId: "steam",
                    name: "Steam",
                    category: "Game Store",
                    compatibilityRating: .good,
                    stage: .verified,
                    state: .verified,
                    highestSeverity: .passed,
                    checklist: [
                        SoftwareSmokeChecklistItem(
                            id: "launch",
                            label: "Launch smoke",
                            state: .passed,
                            detail: "Latest launch was verified by the managed smoke log."
                        )
                    ],
                    blockerCount: 0,
                    warningCount: 0,
                    nextAction: "Verified.",
                    latestLogPath: steamLogPath,
                    latestLaunchLogPath: steamLogPath,
                    latestRepairState: nil
                ),
                SoftwareSmokeMatrixRow(
                    recipeId: "portableapps-platform",
                    name: "PortableApps.com Platform",
                    category: "App Store",
                    compatibilityRating: .experimental,
                    stage: .verified,
                    state: .verified,
                    highestSeverity: .passed,
                    checklist: [
                        SoftwareSmokeChecklistItem(
                            id: "install",
                            label: "Install task",
                            state: .passed,
                            detail: "Latest install completed successfully."
                        ),
                        SoftwareSmokeChecklistItem(
                            id: "launch",
                            label: "Launch smoke",
                            state: .passed,
                            detail: "Latest launch was verified by the managed smoke log."
                        )
                    ],
                    blockerCount: 0,
                    warningCount: 0,
                    nextAction: "Verified.",
                    latestLogPath: paths.logsDirectory.appendingPathComponent("high-performance-win11-portableapps-platform.log").path,
                    latestLaunchLogPath: paths.logsDirectory.appendingPathComponent("high-performance-win11-portableapps-platform.log").path,
                    latestRepairState: nil
                ),
                SoftwareSmokeMatrixRow(
                    recipeId: "firefox",
                    name: "Mozilla Firefox",
                    category: "Browser",
                    compatibilityRating: .experimental,
                    stage: .verified,
                    state: .verified,
                    highestSeverity: .passed,
                    checklist: [
                        SoftwareSmokeChecklistItem(
                            id: "launch",
                            label: "Launch smoke",
                            state: .passed,
                            detail: "Latest Firefox launch was verified."
                        )
                    ],
                    blockerCount: 0,
                    warningCount: 0,
                    nextAction: "Verified.",
                    latestLogPath: paths.logsDirectory.appendingPathComponent("high-performance-win11-firefox-cli-smoke.log").path,
                    latestLaunchLogPath: paths.logsDirectory.appendingPathComponent("high-performance-win11-firefox-cli-smoke.log").path,
                    latestRepairState: nil
                ),
                SoftwareSmokeMatrixRow(
                    recipeId: "ltspice",
                    name: "LTspice",
                    category: "Engineering",
                    compatibilityRating: .good,
                    stage: .verified,
                    state: .verified,
                    highestSeverity: .pending,
                    checklist: [
                        SoftwareSmokeChecklistItem(
                            id: "install",
                            label: "Install task",
                            state: .passed,
                            detail: "Latest install completed successfully."
                        ),
                        SoftwareSmokeChecklistItem(
                            id: "log",
                            label: "Log health",
                            state: .pending,
                            detail: "The old installer log is outside the recent log window."
                        )
                    ],
                    blockerCount: 0,
                    warningCount: 0,
                    nextAction: "Verified.",
                    latestLogPath: paths.logsDirectory.appendingPathComponent("ltspice-circuit-simulation-workload.log").path,
                    latestLaunchLogPath: paths.logsDirectory.appendingPathComponent("ltspice-circuit-launch.log").path,
                    latestRepairState: nil
                )
            ]
        )
        capability.logs = CapabilityLogReport(
            directory: paths.logsDirectory.path,
            recentLogCount: 1,
            healthCounts: ["failed": 1],
            hintCounts: [LogHint.passObserved.rawValue: 1],
            issueReport: capability.logs.issueReport,
            recommendations: [],
            entries: [
                CapabilityLogEntry(
                    name: "diagnostics-high-performance-win11-tls-winhttp-win32-1234ABCD.log",
                    path: passedDiagnosticsLogPath,
                    modifiedAt: generatedAt,
                    byteCount: 1024,
                    health: LogHealth.failed.rawValue,
                    errorCount: 2,
                    warningCount: 0,
                    fixmeCount: 0,
                    passCount: 2,
                    failCount: 0,
                    hints: [LogHint.passObserved.rawValue],
                    launchContext: nil
                )
            ]
        )

        let collection = SoftwareCollectionReport(
            generatedAt: generatedAt,
            rootPath: root.path,
            collections: [
                SoftwareCollectionDefinition(
                    id: "baseline",
                    name: "Baseline",
                    purpose: "Core samples",
                    requiredRecipeIds: ["steam"]
                )
            ],
            missingRecipeIds: ["steam"],
            entries: []
        )
        let acceptance = SoftwareCollectionAcceptanceReport(
            generatedAt: generatedAt,
            rootPath: root.path,
            collection: collection,
            smokeMatrix: nil,
            testExecutionPlan: nil,
            logIssues: LogIssueReport(logs: [], topIssues: [], recentFailures: []),
            actions: [
                SoftwareCollectionAcceptanceAction(
                    id: "missing-recipe-steam",
                    severity: .blocker,
                    kind: .addMissingRecipe,
                    title: "Add Steam recipe",
                    detail: "Steam is required by the baseline collection.",
                    recipeId: "steam"
                )
            ]
        )
        let acquisition = SoftwareAcquisitionReport(
            generatedAt: generatedAt,
            rootPath: root.path,
            downloadsPath: paths.downloadsDirectory.path,
            entries: [
                SoftwareAcquisitionEntry(
                    id: "missing-recipe-steam",
                    source: .missingRecipe,
                    state: .missingRecipe,
                    name: "Steam",
                    recipeId: "steam",
                    action: "Add a signed Steam recipe before installing.",
                    recommendedProbeIds: ["80_window_input_probe"]
                )
            ]
        )
        let launchHealth = LaunchHealthReport(
            generatedAt: generatedAt,
            rootPath: root.path,
            logMatchedLaunchCount: 2,
            entries: [
                LaunchHealthEntry(
                    id: "steam",
                    status: .failed,
                    displayName: "Steam",
                    launchCount: 1,
                    completedLaunchCount: 1,
                    failedToLaunchCount: 0,
                    runningLaunchCount: 0,
                    nonZeroExitCount: 1,
                    logCount: 1,
                    failedLogCount: 1,
                    attentionLogCount: 0,
                    passedLogCount: 0,
                    hints: ["blank-window"],
                    probableIssueIds: ["blank-window"],
                    recommendedProbeIds: ["80_window_input_probe"],
                    logNames: ["steam.log"],
                    logPaths: [steamLogPath]
                ),
                LaunchHealthEntry(
                    id: "broken-tool",
                    status: .failed,
                    displayName: "BrokenTool.exe",
                    launchCount: 1,
                    completedLaunchCount: 1,
                    failedToLaunchCount: 0,
                    runningLaunchCount: 0,
                    nonZeroExitCount: 1,
                    logCount: 1,
                    failedLogCount: 1,
                    attentionLogCount: 0,
                    passedLogCount: 0,
                    hints: ["blank-window"],
                    probableIssueIds: ["blank-window"],
                    recommendedProbeIds: ["80_window_input_probe"],
                    logNames: ["broken-tool.log"],
                    logPaths: [paths.logsDirectory.appendingPathComponent("broken-tool.log").path]
                ),
                LaunchHealthEntry(
                    id: "log:diagnostics-high-performance-win11-tls-winhttp-win32-1234abcd.log",
                    status: .failed,
                    displayName: "diagnostics-high-performance-win11-tls-winhttp-win32-1234ABCD.log",
                    launchCount: 0,
                    completedLaunchCount: 0,
                    failedToLaunchCount: 0,
                    runningLaunchCount: 0,
                    nonZeroExitCount: 0,
                    logCount: 1,
                    failedLogCount: 1,
                    attentionLogCount: 0,
                    passedLogCount: 0,
                    hints: [LogHint.passObserved.rawValue],
                    probableIssueIds: [],
                    recommendedProbeIds: [],
                    logNames: ["diagnostics-high-performance-win11-tls-winhttp-win32-1234ABCD.log"],
                    logPaths: [passedDiagnosticsLogPath]
                ),
                LaunchHealthEntry(
                    id: "high-performance-win11|/users/alice/downloads/portableapps.com_platform_setup_30.4.1.paf.exe",
                    status: .failed,
                    displayName: "PortableApps.com_Platform_Setup_30.4.1.paf.exe",
                    launchCount: 1,
                    completedLaunchCount: 1,
                    failedToLaunchCount: 0,
                    runningLaunchCount: 0,
                    nonZeroExitCount: 1,
                    logCount: 1,
                    failedLogCount: 0,
                    attentionLogCount: 0,
                    passedLogCount: 0,
                    hints: [],
                    probableIssueIds: [],
                    recommendedProbeIds: [],
                    logNames: ["high-performance-win11-install-portableapps-platform-ABCD1234.log"],
                    logPaths: [paths.logsDirectory.appendingPathComponent("high-performance-win11-install-portableapps-platform-ABCD1234.log").path]
                ),
                LaunchHealthEntry(
                    id: "log:high-performance-win11-firefox-manual-smoke-20260702t064117z.log",
                    status: .failed,
                    displayName: "high-performance-win11-firefox-manual-smoke-20260702T064117Z.log",
                    launchCount: 0,
                    completedLaunchCount: 0,
                    failedToLaunchCount: 0,
                    runningLaunchCount: 0,
                    nonZeroExitCount: 0,
                    logCount: 1,
                    failedLogCount: 1,
                    attentionLogCount: 0,
                    passedLogCount: 0,
                    hints: ["gpu-rendering"],
                    probableIssueIds: ["gpu-rendering"],
                    recommendedProbeIds: ["80_window_input_probe"],
                    logNames: ["high-performance-win11-firefox-manual-smoke-20260702T064117Z.log"],
                    logPaths: [paths.logsDirectory.appendingPathComponent("high-performance-win11-firefox-manual-smoke-20260702T064117Z.log").path]
                ),
                LaunchHealthEntry(
                    id: "ltspice-market-test|msiexec",
                    status: .failed,
                    displayName: "msiexec",
                    bottleId: "ltspice-market-test",
                    bottleName: "ltspice-market-test",
                    engineId: "wine-11.11",
                    exe: "msiexec",
                    launchCount: 2,
                    completedLaunchCount: 2,
                    failedToLaunchCount: 0,
                    runningLaunchCount: 0,
                    nonZeroExitCount: 2,
                    logCount: 0,
                    failedLogCount: 0,
                    attentionLogCount: 0,
                    passedLogCount: 0,
                    hints: [],
                    probableIssueIds: [],
                    recommendedProbeIds: [],
                    logNames: [],
                    logPaths: []
                )
            ]
        )
        let externalOpenQueue = ExternalExecutableOpenQueueReport(
            generatedAt: generatedAt,
            queuePath: paths.externalOpenQueueDirectory.appendingPathComponent("requests.jsonl").path,
            logPath: paths.logsDirectory.appendingPathComponent("external-open-queue.log").path,
            pendingCount: 2,
            uniquePendingCount: 1,
            duplicatePendingCount: 1,
            invalidLineCount: 0,
            sourceCounts: ["open-file": 2],
            duplicatePaths: ["/Users/alice/Downloads/SteamSetup.exe"],
            items: [
                ExternalExecutableOpenQueueItem(
                    path: "/Users/alice/Downloads/SteamSetup.exe",
                    source: "open-file",
                    enqueuedAt: generatedAt
                )
            ]
        )

        let report = SupportTriageService.report(
            generatedAt: generatedAt,
            capability: capability,
            logRemediation: LogService.remediationPlan(report: capability.logs.issueReport, generatedAt: generatedAt),
            softwareAcceptance: acceptance,
            softwareAcquisition: acquisition,
            launchHealth: launchHealth,
            externalOpenQueue: externalOpenQueue
        )

        #expect(report.status == .blocked)
        #expect(report.blockerCount >= 2)
        #expect(report.highCount >= 3)
        #expect(report.items.first?.severity == .blocker)
        #expect(report.items.contains { $0.id == "diagnostics-timeout" })
        #expect(report.items.contains { $0.id == "diagnostics-failed" })
        #expect(report.items.contains { $0.id == "runtime-process-stale-runtime-rendering-flags" })
        #expect(report.items.contains { $0.id == "runtime-application-macwin-manager-multiple-launchservices-apps" })
        #expect(report.items.contains { $0.id == "software-acceptance-missing-recipe-steam" })
        #expect(report.items.contains { $0.id == "software-acquisition-missing-recipe-steam" })
        #expect(!report.items.contains { $0.id == "launch-health-steam" })
        #expect(!report.items.contains { $0.id == "launch-health-log:diagnostics-high-performance-win11-tls-winhttp-win32-1234abcd.log" })
        #expect(!report.items.contains { $0.id == "launch-health-high-performance-win11|/users/alice/downloads/portableapps.com_platform_setup_30.4.1.paf.exe" })
        #expect(!report.items.contains { $0.id == "launch-health-log:high-performance-win11-firefox-manual-smoke-20260702t064117z.log" })
        #expect(!report.items.contains { $0.id == "launch-health-ltspice-market-test|msiexec" })
        #expect(report.items.contains { $0.id == "launch-health-broken-tool" })
        #expect(report.items.contains { $0.id == "external-exe-open-queue-pending" })
        #expect(report.items.contains { $0.id == "test-coverage-missing-required-assets" })

        let csv = SupportTriageReport.csv(report: report)
        #expect(csv.contains("id,severity,source,title,detail,recommended_action"))
        #expect(csv.contains("software-acquisition-missing-recipe-steam"))
        #expect(csv.contains("external-exe-open-queue-pending"))

        let markdown = SupportTriageReport.markdown(report: report)
        #expect(markdown.contains("# MacWin Support Triage"))
        #expect(markdown.contains("Status: `blocked`"))
        #expect(markdown.contains("Add Steam recipe"))
    }

    @Test("Support triage snapshot exports timestamped and latest artifacts")
    func supportTriageSnapshotExportsTimestampedAndLatestArtifacts() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinSupportTriageSnapshotTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = MacWinPaths(root: root)
        let generatedAt = Date(timeIntervalSince1970: 2_000)
        let report = SupportTriageReport(
            generatedAt: generatedAt,
            rootPath: root.path,
            items: [
                SupportTriageItem(
                    id: "software-acquisition-tencent-app-store",
                    severity: .high,
                    source: .softwareAcquisition,
                    title: "Software acquisition required: 应用宝 / 腾讯应用市场",
                    detail: "Place one matching local installer in the MacWin Downloads directory.",
                    recommendedAction: "Use software-acquisition.sh/md to place the required installer.",
                    relatedIds: ["tencent-app-store"],
                    relatedPaths: [paths.downloadsDirectory.path]
                )
            ]
        )

        let result = try SupportTriageSnapshotService(paths: paths).export(
            report: report,
            generatedAt: generatedAt
        )

        for url in [
            result.jsonURL,
            result.csvURL,
            result.markdownURL,
            result.latestJSONURL,
            result.latestCSVURL,
            result.latestMarkdownURL
        ] {
            #expect(FileManager.default.fileExists(atPath: url.path))
        }

        #expect(result.jsonURL.lastPathComponent.hasPrefix("support-triage-1970-01-01T003320Z"))
        let decoded = try JSONStore().load(SupportTriageReport.self, from: result.latestJSONURL)
        #expect(decoded.status == .attention)
        #expect(decoded.items.first?.id == "software-acquisition-tencent-app-store")

        let csv = try String(contentsOf: result.latestCSVURL, encoding: .utf8)
        #expect(csv.contains("software-acquisition-tencent-app-store"))
        #expect(csv.contains("tencent-app-store"))

        let markdown = try String(contentsOf: result.latestMarkdownURL, encoding: .utf8)
        #expect(markdown.contains("# MacWin Support Triage"))
        #expect(markdown.contains("应用宝 / 腾讯应用市场"))
    }
}
