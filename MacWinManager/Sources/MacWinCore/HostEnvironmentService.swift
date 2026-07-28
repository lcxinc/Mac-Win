import Foundation
#if canImport(Darwin)
import Darwin
#endif

public struct HostEnvironmentReport: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var operatingSystemVersion: String
    public var hostArchitecture: String
    public var processorCount: Int
    public var activeProcessorCount: Int
    public var physicalMemoryBytes: UInt64
    public var systemUptimeSeconds: TimeInterval
    public var rosettaPathExists: Bool
    public var rootPath: String
    public var enginesPath: String
    public var bottlesPath: String
    public var catalogPath: String
    public var logsPath: String
    public var downloadsPath: String
    public var iconCachePath: String
    public var pathStates: [HostPathState]
    public var volumeTotalCapacityBytes: Int64?
    public var volumeAvailableCapacityBytes: Int64?
    public var engineCount: Int
    public var bottleCount: Int
    public var recipeCount: Int
    public var recentLogCount: Int

    public init(
        schemaVersion: Int = 1,
        operatingSystemVersion: String,
        hostArchitecture: String,
        processorCount: Int,
        activeProcessorCount: Int,
        physicalMemoryBytes: UInt64,
        systemUptimeSeconds: TimeInterval,
        rosettaPathExists: Bool,
        rootPath: String,
        enginesPath: String,
        bottlesPath: String,
        catalogPath: String,
        logsPath: String,
        downloadsPath: String,
        iconCachePath: String,
        pathStates: [HostPathState],
        volumeTotalCapacityBytes: Int64?,
        volumeAvailableCapacityBytes: Int64?,
        engineCount: Int,
        bottleCount: Int,
        recipeCount: Int,
        recentLogCount: Int
    ) {
        self.schemaVersion = schemaVersion
        self.operatingSystemVersion = operatingSystemVersion
        self.hostArchitecture = hostArchitecture
        self.processorCount = processorCount
        self.activeProcessorCount = activeProcessorCount
        self.physicalMemoryBytes = physicalMemoryBytes
        self.systemUptimeSeconds = systemUptimeSeconds
        self.rosettaPathExists = rosettaPathExists
        self.rootPath = rootPath
        self.enginesPath = enginesPath
        self.bottlesPath = bottlesPath
        self.catalogPath = catalogPath
        self.logsPath = logsPath
        self.downloadsPath = downloadsPath
        self.iconCachePath = iconCachePath
        self.pathStates = pathStates
        self.volumeTotalCapacityBytes = volumeTotalCapacityBytes
        self.volumeAvailableCapacityBytes = volumeAvailableCapacityBytes
        self.engineCount = engineCount
        self.bottleCount = bottleCount
        self.recipeCount = recipeCount
        self.recentLogCount = recentLogCount
    }

    public static func csv(report: HostEnvironmentReport?) -> String {
        var rows: [[String]] = [["section", "key", "value"]]
        guard let report else {
            return rows.map { $0.joined(separator: ",") }.joined(separator: "\n")
        }

        rows.append(["system", "operating_system", report.operatingSystemVersion])
        rows.append(["system", "architecture", report.hostArchitecture])
        rows.append(["system", "processor_count", String(report.processorCount)])
        rows.append(["system", "active_processor_count", String(report.activeProcessorCount)])
        rows.append(["system", "physical_memory_bytes", String(report.physicalMemoryBytes)])
        rows.append(["system", "system_uptime_seconds", String(Int(report.systemUptimeSeconds.rounded()))])
        rows.append(["system", "rosetta_path_exists", report.rosettaPathExists ? "true" : "false"])
        rows.append(["volume", "total_capacity_bytes", report.volumeTotalCapacityBytes.map(String.init) ?? ""])
        rows.append(["volume", "available_capacity_bytes", report.volumeAvailableCapacityBytes.map(String.init) ?? ""])
        rows.append(["inventory", "engine_count", String(report.engineCount)])
        rows.append(["inventory", "bottle_count", String(report.bottleCount)])
        rows.append(["inventory", "recipe_count", String(report.recipeCount)])
        rows.append(["inventory", "recent_log_count", String(report.recentLogCount)])

        for state in report.pathStates {
            rows.append(["path", state.id, state.path])
            rows.append(["path_exists", state.id, state.exists ? "true" : "false"])
            rows.append(["path_directory", state.id, state.isDirectory ? "true" : "false"])
        }

        return rows
            .map { $0.map(csvEscaped).joined(separator: ",") }
            .joined(separator: "\n")
    }

    private static func csvEscaped(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}

public struct HostPathState: Codable, Equatable, Sendable {
    public var id: String
    public var path: String
    public var exists: Bool
    public var isDirectory: Bool

    public init(id: String, path: String, exists: Bool, isDirectory: Bool) {
        self.id = id
        self.path = path
        self.exists = exists
        self.isDirectory = isDirectory
    }
}

public struct HostSystemInfo: Equatable, Sendable {
    public var operatingSystemVersion: String
    public var hostArchitecture: String
    public var processorCount: Int
    public var activeProcessorCount: Int
    public var physicalMemoryBytes: UInt64
    public var systemUptimeSeconds: TimeInterval
    public var rosettaPathExists: Bool

    public init(
        operatingSystemVersion: String,
        hostArchitecture: String,
        processorCount: Int,
        activeProcessorCount: Int,
        physicalMemoryBytes: UInt64,
        systemUptimeSeconds: TimeInterval,
        rosettaPathExists: Bool
    ) {
        self.operatingSystemVersion = operatingSystemVersion
        self.hostArchitecture = hostArchitecture
        self.processorCount = processorCount
        self.activeProcessorCount = activeProcessorCount
        self.physicalMemoryBytes = physicalMemoryBytes
        self.systemUptimeSeconds = systemUptimeSeconds
        self.rosettaPathExists = rosettaPathExists
    }
}

public struct HostVolumeInfo: Equatable, Sendable {
    public var totalCapacityBytes: Int64?
    public var availableCapacityBytes: Int64?

    public init(totalCapacityBytes: Int64?, availableCapacityBytes: Int64?) {
        self.totalCapacityBytes = totalCapacityBytes
        self.availableCapacityBytes = availableCapacityBytes
    }
}

public struct HostEnvironmentService {
    public var paths: MacWinPaths
    public var fileManager: FileManager
    public var systemInfoProvider: @Sendable () -> HostSystemInfo
    public var volumeInfoProvider: @Sendable (URL) -> HostVolumeInfo?

    public init(
        paths: MacWinPaths = MacWinPaths(),
        fileManager: FileManager = .default,
        systemInfoProvider: (@Sendable () -> HostSystemInfo)? = nil,
        volumeInfoProvider: (@Sendable (URL) -> HostVolumeInfo?)? = nil
    ) {
        self.paths = paths
        self.fileManager = fileManager
        self.systemInfoProvider = systemInfoProvider ?? Self.currentSystemInfo
        self.volumeInfoProvider = volumeInfoProvider ?? { Self.volumeInfo(for: $0) }
    }

    public func report(
        engines: [EngineManifest],
        bottles: [BottleManifest],
        recipes: [RecipeManifest],
        recentLogCount: Int
    ) -> HostEnvironmentReport {
        let system = systemInfoProvider()
        let volume = volumeInfoProvider(paths.root)
        return HostEnvironmentReport(
            operatingSystemVersion: system.operatingSystemVersion,
            hostArchitecture: system.hostArchitecture,
            processorCount: system.processorCount,
            activeProcessorCount: system.activeProcessorCount,
            physicalMemoryBytes: system.physicalMemoryBytes,
            systemUptimeSeconds: system.systemUptimeSeconds,
            rosettaPathExists: system.rosettaPathExists,
            rootPath: paths.root.path,
            enginesPath: paths.enginesDirectory.path,
            bottlesPath: paths.bottlesDirectory.path,
            catalogPath: paths.catalogDirectory.path,
            logsPath: paths.logsDirectory.path,
            downloadsPath: paths.downloadsDirectory.path,
            iconCachePath: paths.iconCacheDirectory.path,
            pathStates: pathStates(),
            volumeTotalCapacityBytes: volume?.totalCapacityBytes,
            volumeAvailableCapacityBytes: volume?.availableCapacityBytes,
            engineCount: engines.count,
            bottleCount: bottles.count,
            recipeCount: recipes.count,
            recentLogCount: recentLogCount
        )
    }

    private func pathStates() -> [HostPathState] {
        [
            ("root", paths.root),
            ("engines", paths.enginesDirectory),
            ("bottles", paths.bottlesDirectory),
            ("catalog", paths.catalogDirectory),
            ("logs", paths.logsDirectory),
            ("downloads", paths.downloadsDirectory),
            ("icon_cache", paths.iconCacheDirectory)
        ].map { id, url in
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
            return HostPathState(
                id: id,
                path: url.path,
                exists: fileManager.fileExists(atPath: url.path),
                isDirectory: values?.isDirectory == true
            )
        }
    }

    private static func currentSystemInfo() -> HostSystemInfo {
        let processInfo = ProcessInfo.processInfo
        return HostSystemInfo(
            operatingSystemVersion: processInfo.operatingSystemVersionString,
            hostArchitecture: currentArchitecture(),
            processorCount: processInfo.processorCount,
            activeProcessorCount: processInfo.activeProcessorCount,
            physicalMemoryBytes: processInfo.physicalMemory,
            systemUptimeSeconds: processInfo.systemUptime,
            rosettaPathExists: FileManager.default.fileExists(atPath: "/Library/Apple/usr/libexec/oah")
        )
    }

    private static func volumeInfo(for url: URL) -> HostVolumeInfo? {
        let values = try? url.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey
        ])
        guard values?.volumeTotalCapacity != nil || values?.volumeAvailableCapacityForImportantUsage != nil else {
            return nil
        }
        return HostVolumeInfo(
            totalCapacityBytes: values?.volumeTotalCapacity.map(Int64.init),
            availableCapacityBytes: values?.volumeAvailableCapacityForImportantUsage
        )
    }

    private static func currentArchitecture() -> String {
        #if canImport(Darwin)
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        return mirror.children.reduce(into: "") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            identifier.append(Character(UnicodeScalar(UInt8(value))))
        }
        #else
        return "unknown"
        #endif
    }
}
