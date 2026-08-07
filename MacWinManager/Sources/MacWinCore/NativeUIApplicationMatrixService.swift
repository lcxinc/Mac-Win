import Foundation

/// The first real-app matrix is deliberately small and evidence-driven.  It
/// covers the applications that exercise the native UI bridge most directly,
/// while leaving the larger software sample catalog available for broader
/// smoke planning.
public enum NativeUIApplicationMatrixFamily: String, Codable, CaseIterable, Identifiable, Sendable {
    case hoyoPlay = "hoyoplay"
    case steam
    case browser
    case office
    case lenovoAppStore = "lenovo-app-store"

    public var id: String { rawValue }

    public static func forSample(_ sample: SoftwareSampleProfile) -> NativeUIApplicationMatrixFamily? {
        switch sample.id {
        case "hoyoplay-cn":
            return .hoyoPlay
        case "steam":
            return .steam
        case "lenovo-app-store":
            return .lenovoAppStore
        case "chrome-enterprise", "firefox-browser", "brave-browser", "edge-enterprise", "opera-browser", "privacy-browser-pack":
            return .browser
        case "libreoffice-suite", "onlyoffice-suite", "wps-office":
            return .office
        default:
            return nil
        }
    }
}

public enum NativeUIApplicationAvailability: String, Codable, CaseIterable, Sendable {
    case installed
    case recipeAvailable = "recipe-available"
    case installerAvailable = "installer-available"
    case unavailable
}

public enum NativeUIApplicationLaunchEvidence: String, Codable, CaseIterable, Sendable {
    case notRun = "not-run"
    case observed
    case passed
    case failed
}

public struct NativeUIApplicationMatrixEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var family: NativeUIApplicationMatrixFamily
    public var sampleId: String
    public var name: String
    public var publisher: String
    public var category: String
    public var compatibilityProfileId: String?
    public var availability: NativeUIApplicationAvailability
    public var availabilityDetail: String
    public var recipeId: String?
    public var recipeAvailable: Bool
    public var installerAvailable: Bool
    public var installerPath: String?
    public var bottleId: String?
    public var bottleName: String?
    public var launcherId: String?
    public var exePath: String?
    public var compatibilityProfileMatched: Bool
    public var currentPreset: NativeUIIntegrationPreset?
    public var presetOptions: [NativeUIIntegrationPreset]
    public var launchEvidence: NativeUIApplicationLaunchEvidence
    public var latestLaunchAt: Date?
    public var latestLaunchLogPath: String?
    public var latestLaunchExitCode: Int32?
    public var evidenceDetail: String
    public var warnings: [String]

    public init(
        id: String,
        family: NativeUIApplicationMatrixFamily,
        sampleId: String,
        name: String,
        publisher: String,
        category: String,
        compatibilityProfileId: String?,
        availability: NativeUIApplicationAvailability,
        availabilityDetail: String,
        recipeId: String?,
        recipeAvailable: Bool,
        installerAvailable: Bool,
        installerPath: String?,
        bottleId: String?,
        bottleName: String?,
        launcherId: String?,
        exePath: String?,
        compatibilityProfileMatched: Bool,
        currentPreset: NativeUIIntegrationPreset?,
        presetOptions: [NativeUIIntegrationPreset],
        launchEvidence: NativeUIApplicationLaunchEvidence,
        latestLaunchAt: Date?,
        latestLaunchLogPath: String?,
        latestLaunchExitCode: Int32?,
        evidenceDetail: String,
        warnings: [String]
    ) {
        self.id = id
        self.family = family
        self.sampleId = sampleId
        self.name = name
        self.publisher = publisher
        self.category = category
        self.compatibilityProfileId = compatibilityProfileId
        self.availability = availability
        self.availabilityDetail = availabilityDetail
        self.recipeId = recipeId
        self.recipeAvailable = recipeAvailable
        self.installerAvailable = installerAvailable
        self.installerPath = installerPath
        self.bottleId = bottleId
        self.bottleName = bottleName
        self.launcherId = launcherId
        self.exePath = exePath
        self.compatibilityProfileMatched = compatibilityProfileMatched
        self.currentPreset = currentPreset
        self.presetOptions = presetOptions
        self.launchEvidence = launchEvidence
        self.latestLaunchAt = latestLaunchAt
        self.latestLaunchLogPath = latestLaunchLogPath
        self.latestLaunchExitCode = latestLaunchExitCode
        self.evidenceDetail = evidenceDetail
        self.warnings = warnings
    }
}

public struct NativeUIApplicationMatrixReport: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var generatedAt: Date
    public var rootPath: String
    public var familyCount: Int
    public var entryCount: Int
    public var installedCount: Int
    public var recipeAvailableCount: Int
    public var installerAvailableCount: Int
    public var unavailableCount: Int
    public var launchObservedCount: Int
    public var passedCount: Int
    public var failedCount: Int
    public var unverifiedCount: Int
    public var entries: [NativeUIApplicationMatrixEntry]

    public init(
        schemaVersion: Int = 1,
        generatedAt: Date,
        rootPath: String,
        entries: [NativeUIApplicationMatrixEntry]
    ) {
        self.schemaVersion = schemaVersion
        self.generatedAt = generatedAt
        self.rootPath = rootPath
        self.familyCount = Set(entries.map(\.family)).count
        self.entryCount = entries.count
        self.installedCount = entries.filter { $0.availability == .installed }.count
        self.recipeAvailableCount = entries.filter { $0.availability == .recipeAvailable }.count
        self.installerAvailableCount = entries.filter { $0.availability == .installerAvailable }.count
        self.unavailableCount = entries.filter { $0.availability == .unavailable }.count
        self.launchObservedCount = entries.filter { $0.launchEvidence == .observed }.count
        self.passedCount = entries.filter { $0.launchEvidence == .passed }.count
        self.failedCount = entries.filter { $0.launchEvidence == .failed }.count
        self.unverifiedCount = entries.filter { $0.launchEvidence != .passed }.count
        self.entries = entries.sorted {
            if $0.family != $1.family {
                return $0.family.rawValue < $1.family.rawValue
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    public static func empty(rootPath: String) -> NativeUIApplicationMatrixReport {
        NativeUIApplicationMatrixReport(generatedAt: Date(), rootPath: rootPath, entries: [])
    }
}

public struct NativeUIApplicationMatrixService {
    public static let supportedPresets: [NativeUIIntegrationPreset] = [
        .automatic,
        .nativeDialogs,
        .disabled
    ]

    public var paths: MacWinPaths
    public var fileManager: FileManager
    public var samples: [SoftwareSampleProfile]

    public init(
        paths: MacWinPaths = MacWinPaths(),
        fileManager: FileManager = .default,
        samples: [SoftwareSampleProfile] = SoftwareSampleCatalogService.defaultSamples
    ) {
        self.paths = paths
        self.fileManager = fileManager
        self.samples = samples
    }

    public func report(
        bottles: [BottleManifest],
        recipes: [RecipeManifest],
        launchHistory: LaunchHistoryReport? = nil,
        smokeReports: [SoftwareSmokeRunReport] = [],
        generatedAt: Date = Date()
    ) -> NativeUIApplicationMatrixReport {
        let catalog = SoftwareSampleCatalogService.report(
            rootPath: paths.root.path,
            samples: samples,
            recipes: recipes,
            generatedAt: generatedAt
        )
        let preparation = SoftwareSampleCatalogService.preparationReport(
            catalog: catalog,
            downloadsDirectory: paths.downloadsDirectory,
            generatedAt: generatedAt,
            fileManager: fileManager
        )
        let preparationBySample = Dictionary(uniqueKeysWithValues: preparation.entries.map { ($0.sampleId, $0) })
        let launchRecords = launchHistory?.records ?? []

        let entries = catalog.samples.compactMap { sample -> NativeUIApplicationMatrixEntry? in
            guard let family = NativeUIApplicationMatrixFamily.forSample(sample) else { return nil }
            let recipe = sample.catalogRecipeId.flatMap { recipeId in
                recipes.first { $0.id == recipeId }
            }
            let recipeAvailable = recipe.map { $0.disabledReason == nil && $0.installer.mode != .none } ?? false
            let preparationEntry = preparationBySample[sample.id]
            let installerPath = preparationEntry?.cachedInstallerPaths.first
            let installerAvailable = !(preparationEntry?.cachedInstallerPaths.isEmpty ?? true)
            let launcher = matchingLauncher(
                for: sample,
                recipe: recipe,
                in: bottles
            )
            let availability: NativeUIApplicationAvailability
            let availabilityDetail: String
            if launcher != nil {
                availability = .installed
                availabilityDetail = "launcher-found"
            } else if recipeAvailable {
                availability = .recipeAvailable
                availabilityDetail = "signed-recipe-ready"
            } else if installerAvailable {
                availability = .installerAvailable
                availabilityDetail = "cached-installer-ready"
            } else {
                availability = .unavailable
                availabilityDetail = preparationEntry?.requiredAction ?? "no-launcher-recipe-or-cached-installer"
            }

            let latestLaunch = launcher.flatMap { matched in
                latestLaunchRecord(
                    for: sample,
                    launcher: matched.launcher,
                    bottle: matched.bottle,
                    records: launchRecords
                )
            }
            let evidenceCandidate = resolvedEvidence(
                managed: latestLaunch.map(managedEvidence),
                smoke: smokeEvidence(for: sample, reports: smokeReports)
            )
            let evidence = evidenceCandidate?.status ?? .notRun
            var warnings = sample.warnings
            let profileMatched = launcher.map {
                ApplicationCompatibilityProfile.current(in: $0.launcher)?.rawValue == sample.compatibilityProfileId
            } ?? false
            if launcher != nil, sample.compatibilityProfileId != nil, !profileMatched {
                warnings.append("The launcher was found, but its compatibility profile is not applied.")
            }
            if availability == .installed, evidence == .notRun {
                warnings.append("Installed launcher has no recorded launch result; run it before treating the app as verified.")
            } else if availability == .installed, evidence == .observed {
                warnings.append("The application stayed alive, but it still needs a functional workload or rendered-content proof before it is verified.")
            }

            return NativeUIApplicationMatrixEntry(
                id: "\(family.rawValue):\(sample.id)",
                family: family,
                sampleId: sample.id,
                name: sample.name,
                publisher: sample.publisher,
                category: sample.category,
                compatibilityProfileId: sample.compatibilityProfileId,
                availability: availability,
                availabilityDetail: availabilityDetail,
                recipeId: recipe?.id,
                recipeAvailable: recipeAvailable,
                installerAvailable: installerAvailable,
                installerPath: installerPath,
                bottleId: launcher?.bottle.id,
                bottleName: launcher?.bottle.name,
                launcherId: launcher?.launcher.id,
                exePath: launcher?.launcher.exePath,
                compatibilityProfileMatched: profileMatched,
                currentPreset: launcher.map { NativeUIIntegrationPreset.current(in: $0.bottle) },
                presetOptions: Self.supportedPresets,
                launchEvidence: evidence,
                latestLaunchAt: evidenceCandidate?.occurredAt,
                latestLaunchLogPath: evidenceCandidate?.logPath,
                latestLaunchExitCode: evidenceCandidate?.exitCode,
                evidenceDetail: evidenceCandidate?.detail ?? availability.rawValue,
                warnings: warnings
            )
        }

        return NativeUIApplicationMatrixReport(
            generatedAt: generatedAt,
            rootPath: paths.root.path,
            entries: entries
        )
    }

    public static func family(for sample: SoftwareSampleProfile) -> NativeUIApplicationMatrixFamily? {
        NativeUIApplicationMatrixFamily.forSample(sample)
    }

    private func matchingLauncher(
        for sample: SoftwareSampleProfile,
        recipe: RecipeManifest?,
        in bottles: [BottleManifest]
    ) -> (bottle: BottleManifest, launcher: LauncherManifest)? {
        let expectedPaths = sample.launcherCandidates + (recipe?.launchers.map(\.exePath) ?? [])
        let identifiers = [sample.id, sample.catalogRecipeId].compactMap { $0 }
        for bottle in bottles.sorted(by: { $0.updatedAt > $1.updatedAt }) {
            for launcher in bottle.installedApps {
                let identifierMatch = identifiers.contains { identifierMatches(launcher.appId, identifier: $0) }
                let pathMatch = expectedPaths.contains { windowsPathMatches($0, launcher.exePath) }
                guard identifierMatch || pathMatch else { continue }
                return (bottle, launcher)
            }
        }
        return nil
    }

    private func latestLaunchRecord(
        for sample: SoftwareSampleProfile,
        launcher: LauncherManifest,
        bottle: BottleManifest,
        records: [WineLaunchRecord]
    ) -> WineLaunchRecord? {
        records
            .filter { record in
                guard record.bottleId == bottle.id else { return false }
                if windowsPathMatches(record.exe, launcher.exePath) {
                    return true
                }
                guard let profileId = sample.compatibilityProfileId else { return false }
                return record.environment["MACWIN_COMPAT_PROFILE"]?.lowercased() == profileId.lowercased()
            }
            .max { lhs, rhs in
                if lhs.startedAt == rhs.startedAt { return lhs.id < rhs.id }
                return lhs.startedAt < rhs.startedAt
            }
    }

    private struct EvidenceCandidate {
        var status: NativeUIApplicationLaunchEvidence
        var occurredAt: Date
        var logPath: String?
        var exitCode: Int32?
        var detail: String
    }

    private func managedEvidence(for record: WineLaunchRecord) -> EvidenceCandidate {
        let status: NativeUIApplicationLaunchEvidence
        switch record.state {
        case .started:
            status = .observed
        case .completed:
            if record.exitCode == 0 {
                status = .passed
            } else if record.exitCode == 15
                        || record.exitCode == -15
                        || (record.durationMilliseconds ?? 0) >= 3_000 {
                status = .observed
            } else {
                status = .failed
            }
        case .failedToLaunch:
            status = .failed
        }
        return EvidenceCandidate(
            status: status,
            occurredAt: record.startedAt,
            logPath: record.logPath,
            exitCode: record.exitCode,
            detail: "\(status.rawValue)-\(record.mode.rawValue)"
        )
    }

    private func smokeEvidence(
        for sample: SoftwareSampleProfile,
        reports: [SoftwareSmokeRunReport]
    ) -> EvidenceCandidate? {
        reports.compactMap { report -> EvidenceCandidate? in
            guard reportContains(sampleId: sample.id, report: report),
                  let launch = report.records.last(where: { $0.id == sample.id && $0.phase == "launch" }),
                  let occurredAt = reportDate(report.generatedAt) else {
                return nil
            }

            if launch.state == "failed" {
                return EvidenceCandidate(
                    status: .failed,
                    occurredAt: occurredAt,
                    logPath: launch.logPath,
                    exitCode: launch.exitCode.flatMap(Int32.init(exactly:)),
                    detail: "failed-smoke-launch"
                )
            }
            if launch.state == "skipped",
               launch.note?.localizedCaseInsensitiveContains("session is locked") == true {
                return EvidenceCandidate(
                    status: .notRun,
                    occurredAt: occurredAt,
                    logPath: launch.logPath,
                    exitCode: launch.exitCode.flatMap(Int32.init(exactly:)),
                    detail: "not-run-smoke-session-locked"
                )
            }
            guard launch.state == "passed" || launch.state == "launched" else {
                return nil
            }

            if let workload = verifiedWorkload(for: sample, report: report) {
                return EvidenceCandidate(
                    status: .passed,
                    occurredAt: occurredAt,
                    logPath: workload.logPath ?? launch.logPath,
                    exitCode: workload.exitCode.flatMap(Int32.init(exactly:)),
                    detail: "passed-smoke-\(workload.phase)"
                )
            }
            if sample.id == "lenovo-app-store", let proofPath = verifiedLenovoVisualProof(in: report) {
                return EvidenceCandidate(
                    status: .passed,
                    occurredAt: occurredAt,
                    logPath: proofPath,
                    exitCode: 0,
                    detail: "passed-smoke-rendered-content"
                )
            }
            return EvidenceCandidate(
                status: .observed,
                occurredAt: occurredAt,
                logPath: launch.logPath,
                exitCode: launch.exitCode.flatMap(Int32.init(exactly:)),
                detail: "observed-smoke-launch"
            )
        }
        .max { $0.occurredAt < $1.occurredAt }
    }

    private func resolvedEvidence(
        managed: EvidenceCandidate?,
        smoke: EvidenceCandidate?
    ) -> EvidenceCandidate? {
        let candidates = [managed, smoke].compactMap { $0 }
        guard !candidates.isEmpty else { return nil }
        let latestPass = candidates
            .filter { $0.status == .passed }
            .max { $0.occurredAt < $1.occurredAt }
        let latestFailure = candidates
            .filter { $0.status == .failed }
            .max { $0.occurredAt < $1.occurredAt }
        if let latestFailure,
           latestPass == nil || latestFailure.occurredAt > latestPass!.occurredAt {
            return latestFailure
        }
        if let latestPass { return latestPass }
        return candidates.max { $0.occurredAt < $1.occurredAt }
    }

    private func verifiedWorkload(
        for sample: SoftwareSampleProfile,
        report: SoftwareSmokeRunReport
    ) -> SoftwareSmokeRunRecord? {
        let acceptedPhases: Set<String>
        switch NativeUIApplicationMatrixFamily.forSample(sample) {
        case .browser:
            acceptedPhases = ["browser-workload"]
        case .office:
            acceptedPhases = ["core-workload"]
        case .hoyoPlay, .steam, .lenovoAppStore, .none:
            acceptedPhases = []
        }
        return report.records.last {
            $0.id == sample.id && $0.state == "passed" && acceptedPhases.contains($0.phase)
        }
    }

    private func verifiedLenovoVisualProof(in report: SoftwareSmokeRunReport) -> String? {
        let proofURL = URL(fileURLWithPath: report.logDirectory)
            .appendingPathComponent("lenovo-app-store-cdp-proof.json")
        guard let proofData = try? Data(contentsOf: proofURL),
              let proof = try? JSONSerialization.jsonObject(with: proofData) as? [String: Any],
              proof["status"] as? String == "rendered",
              (proof["failedChecks"] as? [Any])?.isEmpty == true,
              let checks = proof["checks"] as? [String: Any] else {
            return nil
        }
        let requiredChecks = [
            "targetURL", "targetTitle", "documentComplete", "nativeCommandLineReady",
            "substantialDOM", "expectedText", "imagesLoaded", "compositorImage", "opaqueImage"
        ]
        guard requiredChecks.allSatisfy({ checks[$0] as? Bool == true }),
              let analysisPath = proof["analysisPath"] as? String,
              let analysisData = try? Data(contentsOf: URL(fileURLWithPath: analysisPath)),
              let analysis = try? JSONSerialization.jsonObject(with: analysisData) as? [String: Any],
              analysis["classification"] as? String == "rendered",
              (analysis["width"] as? Int ?? 0) >= 400,
              (analysis["height"] as? Int ?? 0) >= 300,
              (analysis["sampledPixels"] as? Int ?? 0) >= 1_000,
              let imagePath = analysis["path"] as? String,
              let imageSize = try? fileManager.attributesOfItem(atPath: imagePath)[.size] as? NSNumber,
              imageSize.intValue >= 16_384 else {
            return nil
        }
        return proofURL.path
    }

    private func reportContains(sampleId: String, report: SoftwareSmokeRunReport) -> Bool {
        let declaredSamples = report.sample?
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? []
        return declaredSamples.contains(sampleId) || report.records.contains { $0.id == sampleId }
    }

    private func reportDate(_ value: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractional.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }

    private func identifierMatches(_ value: String, identifier: String) -> Bool {
        let value = value.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let identifier = identifier.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return value == identifier
            || value.hasPrefix(identifier + "-")
            || value.hasPrefix(identifier + "_")
    }

    private func windowsPathMatches(_ lhs: String, _ rhs: String) -> Bool {
        let lhsParts = normalizedWindowsPath(lhs).split(separator: "\\", omittingEmptySubsequences: true)
        let rhsParts = normalizedWindowsPath(rhs).split(separator: "\\", omittingEmptySubsequences: true)
        guard lhsParts.count == rhsParts.count else { return false }
        return zip(lhsParts, rhsParts).allSatisfy { lhsPart, rhsPart in
            let left = String(lhsPart)
            let right = String(rhsPart)
            return left == right
                || (left.hasPrefix("%") && left.hasSuffix("%"))
                || (right.hasPrefix("%") && right.hasSuffix("%"))
        }
    }

    private func normalizedWindowsPath(_ path: String) -> String {
        path
            .replacingOccurrences(of: "/", with: "\\")
            .replacingOccurrences(of: "\\\\", with: "\\")
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
