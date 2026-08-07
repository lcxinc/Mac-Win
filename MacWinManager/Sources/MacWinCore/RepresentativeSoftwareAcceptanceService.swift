import Foundation

public enum RepresentativeAcceptanceState: String, Codable, CaseIterable, Equatable, Sendable {
    case unavailable
    case needsInstall = "needs-install"
    case needsLaunch = "needs-launch"
    case needsFunctionalProof = "needs-functional-proof"
    case passed
    case failed
}

public struct RepresentativeAcceptanceEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: String { sampleId }
    public var sampleId: String
    public var family: NativeUIApplicationMatrixFamily
    public var name: String
    public var state: RepresentativeAcceptanceState
    public var availability: NativeUIApplicationAvailability
    public var launchEvidence: NativeUIApplicationLaunchEvidence
    public var latestLogPath: String?
    public var nextAction: String

    public init(
        sampleId: String,
        family: NativeUIApplicationMatrixFamily,
        name: String,
        state: RepresentativeAcceptanceState,
        availability: NativeUIApplicationAvailability,
        launchEvidence: NativeUIApplicationLaunchEvidence,
        latestLogPath: String? = nil,
        nextAction: String
    ) {
        self.sampleId = sampleId
        self.family = family
        self.name = name
        self.state = state
        self.availability = availability
        self.launchEvidence = launchEvidence
        self.latestLogPath = latestLogPath
        self.nextAction = nextAction
    }
}

public struct RepresentativeSoftwareAcceptanceReport: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var rootPath: String
    public var targetCount: Int
    public var passedCount: Int
    public var failedCount: Int
    public var pendingCount: Int
    public var entries: [RepresentativeAcceptanceEntry]

    public init(generatedAt: Date = Date(), rootPath: String, entries: [RepresentativeAcceptanceEntry]) {
        self.generatedAt = generatedAt
        self.rootPath = rootPath
        self.targetCount = entries.count
        self.passedCount = entries.filter { $0.state == .passed }.count
        self.failedCount = entries.filter { $0.state == .failed }.count
        self.pendingCount = entries.filter { $0.state != .passed && $0.state != .failed }.count
        self.entries = entries.sorted { $0.sampleId < $1.sampleId }
    }

    public static func empty(rootPath: String) -> RepresentativeSoftwareAcceptanceReport {
        RepresentativeSoftwareAcceptanceReport(rootPath: rootPath, entries: [])
    }
}

public struct RepresentativeSoftwareAcceptanceService {
    public static let targetSampleIds = [
        "hoyoplay-cn",
        "steam",
        "firefox-browser",
        "libreoffice-suite"
    ]

    public var paths: MacWinPaths

    public init(paths: MacWinPaths = MacWinPaths()) {
        self.paths = paths
    }

    public func report(
        matrix: NativeUIApplicationMatrixReport,
        generatedAt: Date = Date()
    ) -> RepresentativeSoftwareAcceptanceReport {
        let entries: [RepresentativeAcceptanceEntry] = Self.targetSampleIds.compactMap { sampleId -> RepresentativeAcceptanceEntry? in
            guard let matrixEntry = matrix.entries.first(where: { $0.sampleId == sampleId }) else {
                return nil
            }
            return RepresentativeAcceptanceEntry(
                sampleId: sampleId,
                family: matrixEntry.family,
                name: matrixEntry.name,
                state: state(for: matrixEntry),
                availability: matrixEntry.availability,
                launchEvidence: matrixEntry.launchEvidence,
                latestLogPath: matrixEntry.latestLaunchLogPath,
                nextAction: nextAction(for: matrixEntry)
            )
        }
        return RepresentativeSoftwareAcceptanceReport(
            generatedAt: generatedAt,
            rootPath: paths.root.path,
            entries: entries
        )
    }

    public func save(_ report: RepresentativeSoftwareAcceptanceReport) throws -> URL {
        let directory = paths.logsDirectory.appendingPathComponent("SoftwareAcceptance", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("representative-latest.json")
        try JSONStore().save(report, to: url)
        return url
    }

    private func state(for entry: NativeUIApplicationMatrixEntry) -> RepresentativeAcceptanceState {
        switch entry.launchEvidence {
        case .passed:
            return .passed
        case .failed:
            return .failed
        case .observed:
            return .needsFunctionalProof
        case .notRun:
            switch entry.availability {
            case .installed:
                return .needsLaunch
            case .recipeAvailable, .installerAvailable:
                return .needsInstall
            case .unavailable:
                return .unavailable
            }
        }
    }

    private func nextAction(for entry: NativeUIApplicationMatrixEntry) -> String {
        switch state(for: entry) {
        case .passed:
            return "Functional or rendered-content evidence is current."
        case .failed:
            return "Review the latest launch log and rerun with diagnostics."
        case .needsFunctionalProof:
            return "Run the family workload or rendered-content probe; launch-only evidence is insufficient."
        case .needsLaunch:
            return "Launch the installed application with diagnostics."
        case .needsInstall:
            return "Install from the signed recipe, then launch with diagnostics."
        case .unavailable:
            return "Add a signed recipe or a local installer before testing."
        }
    }
}
