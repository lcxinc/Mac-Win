import Foundation

public enum NativeUIProbeMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case message
    case legacyOpen = "open"
    case legacySave = "save"
    case filteredOpen = "filtered-open"
    case filteredSave = "filtered-save"
    case legacyFallback = "legacy-fallback"
    case modernOpen = "modern-open"
    case modernSave = "modern-save"
    case modernOpenMulti = "modern-open-multi"
    case modernFolder = "modern-folder"
    case task
    case taskFallback = "task-fallback"

    public var id: String { rawValue }
    public var argument: String { "--\(rawValue)" }
    public var isModern: Bool {
        switch self {
        case .modernOpen, .modernSave, .modernOpenMulti, .modernFolder, .task, .taskFallback:
            true
        case .message, .legacyOpen, .legacySave, .filteredOpen, .filteredSave, .legacyFallback:
            false
        }
    }
}

public struct NativeUIProbeArtifactReport: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var searchDirectories: [String]
    public var x86_64Path: String?
    public var i386Path: String?

    public init(
        generatedAt: Date = Date(),
        searchDirectories: [String],
        x86_64Path: String?,
        i386Path: String?
    ) {
        self.generatedAt = generatedAt
        self.searchDirectories = searchDirectories
        self.x86_64Path = x86_64Path
        self.i386Path = i386Path
    }

    public var isReady: Bool { x86_64Path != nil }
    public var supportsWoW64: Bool { i386Path != nil }
}

public enum NativeUIProbeRunStatus: String, Codable, CaseIterable, Sendable {
    case passed
    case cancelled
    case failed
}

public struct NativeUIProbeRunReport: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var mode: NativeUIProbeMode
    public var architecture: WindowsExecutableArchitecture
    public var executablePath: String
    public var bottleId: String
    public var bottleName: String
    public var engineId: String
    public var nativeUIPreset: NativeUIIntegrationPreset
    public var status: NativeUIProbeRunStatus
    public var exitCode: Int32
    public var logPath: String
    public var output: String
    public var startedAt: Date
    public var endedAt: Date

    public init(
        id: String = UUID().uuidString,
        mode: NativeUIProbeMode,
        architecture: WindowsExecutableArchitecture,
        executablePath: String,
        bottleId: String,
        bottleName: String,
        engineId: String,
        nativeUIPreset: NativeUIIntegrationPreset,
        status: NativeUIProbeRunStatus,
        exitCode: Int32,
        logPath: String,
        output: String,
        startedAt: Date,
        endedAt: Date
    ) {
        self.id = id
        self.mode = mode
        self.architecture = architecture
        self.executablePath = executablePath
        self.bottleId = bottleId
        self.bottleName = bottleName
        self.engineId = engineId
        self.nativeUIPreset = nativeUIPreset
        self.status = status
        self.exitCode = exitCode
        self.logPath = logPath
        self.output = output
        self.startedAt = startedAt
        self.endedAt = endedAt
    }

    public var passed: Bool { status == .passed }
}

public struct NativeUIProbeHistoryReport: Codable, Equatable, Sendable {
    public var rootPath: String
    public var recordsPath: String
    public var totalRunCount: Int
    public var latestRunAt: Date?
    public var records: [NativeUIProbeRunReport]

    public init(rootPath: String, recordsPath: String, records: [NativeUIProbeRunReport]) {
        self.rootPath = rootPath
        self.recordsPath = recordsPath
        self.totalRunCount = records.count
        self.latestRunAt = records.map(\.endedAt).max()
        self.records = records
    }
}

public struct NativeUIProbeService {
    public var probeDirectories: [URL]
    public var fileManager: FileManager

    public init(
        probeDirectory: URL? = nil,
        paths: MacWinPaths = MacWinPaths(),
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        if let probeDirectory {
            self.probeDirectories = [probeDirectory]
        } else {
            self.probeDirectories = Self.defaultProbeDirectories(paths: paths, fileManager: fileManager)
        }
    }

    public func artifactReport(generatedAt: Date = Date()) -> NativeUIProbeArtifactReport {
        NativeUIProbeArtifactReport(
            generatedAt: generatedAt,
            searchDirectories: probeDirectories.map(\.path),
            x86_64Path: executable(for: .x86_64)?.path,
            i386Path: executable(for: .i386)?.path
        )
    }

    public func executable(for architecture: WindowsExecutableArchitecture) -> URL? {
        let fileName: String
        switch architecture {
        case .x86_64:
            fileName = "native-ui-probe-x86_64.exe"
        case .i386:
            fileName = "native-ui-probe-i686.exe"
        case .arm64, .unknown:
            return nil
        }
        for directory in probeDirectories {
            let candidate = directory.appendingPathComponent(fileName)
            if fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }

    public func command(mode: NativeUIProbeMode, architecture: WindowsExecutableArchitecture) -> [String]? {
        guard let executable = executable(for: architecture) else { return nil }
        return [executable.path, mode.argument]
    }

    private static func defaultProbeDirectories(paths: MacWinPaths, fileManager: FileManager) -> [URL] {
        var candidates: [URL] = [paths.nativeUIProbeDirectory]
        if let configured = ProcessInfo.processInfo.environment["MACWIN_NATIVE_UI_PROBE_DIR"], !configured.isEmpty {
            candidates.insert(URL(fileURLWithPath: configured), at: 0)
        }
        if let resourceURL = Bundle.main.resourceURL {
            candidates.append(resourceURL.appendingPathComponent("NativeUIProbe", isDirectory: true))
        }

        let sourceFile = URL(fileURLWithPath: #filePath)
        let projectRoot = sourceFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let tmpDirectory = projectRoot.appendingPathComponent("tmp", isDirectory: true)
        candidates.append(contentsOf: [
            tmpDirectory.appendingPathComponent("native-ui-probe-modern-final", isDirectory: true),
            tmpDirectory.appendingPathComponent("native-ui-probe-modern", isDirectory: true),
            tmpDirectory.appendingPathComponent("native-ui-probe", isDirectory: true)
        ])
        if let entries = try? fileManager.contentsOfDirectory(
            at: tmpDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) {
            candidates.append(contentsOf: entries.filter { $0.lastPathComponent.hasPrefix("native-ui-probe") })
        }

        var seen = Set<String>()
        return candidates.filter { candidate in
            let path = candidate.standardizedFileURL.path
            return seen.insert(path).inserted
        }
    }
}

public struct NativeUIProbeHistoryService {
    public var paths: MacWinPaths
    public var fileManager: FileManager

    public init(paths: MacWinPaths = MacWinPaths(), fileManager: FileManager = .default) {
        self.paths = paths
        self.fileManager = fileManager
    }

    public var recordsDirectory: URL {
        paths.logsDirectory.appendingPathComponent("NativeUIProbe", isDirectory: true)
    }

    @discardableResult
    public func save(_ record: NativeUIProbeRunReport) throws -> NativeUIProbeRunReport {
        try paths.ensureBaseDirectories(fileManager: fileManager)
        try fileManager.createDirectory(at: recordsDirectory, withIntermediateDirectories: true)
        let fileName = record.id.replacingOccurrences(of: "/", with: "-")
        try JSONStore(fileManager: fileManager).save(
            record,
            to: recordsDirectory.appendingPathComponent("\(fileName).native-ui.json")
        )
        return record
    }

    public func report(limit: Int = 100) -> NativeUIProbeHistoryReport {
        guard fileManager.fileExists(atPath: recordsDirectory.path),
              let contents = try? fileManager.contentsOfDirectory(
                at: recordsDirectory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
              ) else {
            return NativeUIProbeHistoryReport(
                rootPath: paths.root.path,
                recordsPath: recordsDirectory.path,
                records: []
            )
        }
        let store = JSONStore(fileManager: fileManager)
        let records = contents
            .filter { $0.pathExtension == "json" && $0.lastPathComponent.hasSuffix(".native-ui.json") }
            .compactMap { try? store.load(NativeUIProbeRunReport.self, from: $0) }
            .sorted { lhs, rhs in
                if lhs.endedAt != rhs.endedAt { return lhs.endedAt > rhs.endedAt }
                return lhs.id < rhs.id
            }
        return NativeUIProbeHistoryReport(
            rootPath: paths.root.path,
            recordsPath: recordsDirectory.path,
            records: Array(records.prefix(max(limit, 0)))
        )
    }
}
