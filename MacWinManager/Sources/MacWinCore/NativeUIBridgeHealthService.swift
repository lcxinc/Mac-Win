import Foundation

public enum NativeUIBridgeComponent: String, Codable, CaseIterable, Identifiable, Sendable {
    case alerts
    case legacyFileDialogs = "legacy-file-dialogs"
    case modernFileDialogs = "modern-file-dialogs"
    case taskDialogs = "task-dialogs"
    case cocoaHost = "cocoa-host"

    public var id: String { rawValue }
}

public struct NativeUIBridgeComponentReport: Codable, Equatable, Identifiable, Sendable {
    public var component: NativeUIBridgeComponent
    public var path: String?
    public var requiredMarkers: [String]
    public var missingMarkers: [String]
    public var isReady: Bool

    public init(
        component: NativeUIBridgeComponent,
        path: String?,
        requiredMarkers: [String],
        missingMarkers: [String]
    ) {
        self.component = component
        self.path = path
        self.requiredMarkers = requiredMarkers
        self.missingMarkers = missingMarkers
        self.isReady = path != nil && missingMarkers.isEmpty
    }

    public var id: String { component.rawValue }
}

public struct NativeUIBridgeArchitectureReport: Codable, Equatable, Identifiable, Sendable {
    public var architecture: WindowsExecutableArchitecture
    public var components: [NativeUIBridgeComponentReport]
    public var isReady: Bool

    public init(
        architecture: WindowsExecutableArchitecture,
        components: [NativeUIBridgeComponentReport]
    ) {
        self.architecture = architecture
        self.components = components
        self.isReady = !components.isEmpty && components.allSatisfy(\.isReady)
    }

    public var id: String { architecture.rawValue }
}

public struct NativeUIBridgeEngineReport: Codable, Equatable, Identifiable, Sendable {
    public var engineId: String
    public var engineName: String
    public var buildRootPath: String?
    public var hostComponent: NativeUIBridgeComponentReport
    public var architectures: [NativeUIBridgeArchitectureReport]
    public var warnings: [String]
    public var isReady: Bool

    public init(
        engineId: String,
        engineName: String,
        buildRootPath: String?,
        hostComponent: NativeUIBridgeComponentReport,
        architectures: [NativeUIBridgeArchitectureReport],
        warnings: [String]
    ) {
        self.engineId = engineId
        self.engineName = engineName
        self.buildRootPath = buildRootPath
        self.hostComponent = hostComponent
        self.architectures = architectures
        self.warnings = warnings
        self.isReady = hostComponent.isReady
            && !architectures.isEmpty
            && architectures.allSatisfy(\.isReady)
    }

    public var id: String { engineId }

    public func architecture(_ architecture: WindowsExecutableArchitecture) -> NativeUIBridgeArchitectureReport? {
        architectures.first { $0.architecture == architecture }
    }
}

public struct NativeUIBridgeHealthReport: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var engines: [NativeUIBridgeEngineReport]
    public var readyEngineCount: Int

    public init(generatedAt: Date = Date(), engines: [NativeUIBridgeEngineReport]) {
        self.generatedAt = generatedAt
        self.engines = engines
        self.readyEngineCount = engines.filter(\.isReady).count
    }

    public static var empty: NativeUIBridgeHealthReport {
        NativeUIBridgeHealthReport(engines: [])
    }

}

public struct NativeUIBridgeHealthService {
    public var fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func report(
        engines: [EngineManifest],
        generatedAt: Date = Date()
    ) -> NativeUIBridgeHealthReport {
        NativeUIBridgeHealthReport(
            generatedAt: generatedAt,
            engines: engines.map(engineReport)
        )
    }

    private func engineReport(_ engine: EngineManifest) -> NativeUIBridgeEngineReport {
        let buildRoot = buildRoot(for: engine)
        let host = componentReport(
            component: .cocoaHost,
            candidates: hostCandidates(buildRoot: buildRoot),
            markers: ["MacWinFileTypeSelector", "NSSavePanel"]
        )
        var architectures = [architectureReport(.x86_64, buildRoot: buildRoot)]
        if engine.supportsWin32 {
            architectures.append(architectureReport(.i386, buildRoot: buildRoot))
        }

        var warnings: [String] = []
        if buildRoot == nil {
            warnings.append("engine-build-root-unavailable")
        }
        if !host.isReady {
            warnings.append("cocoa-host-bridge-missing")
        }
        for architecture in architectures where !architecture.isReady {
            warnings.append("\(architecture.architecture.rawValue)-bridge-incomplete")
        }

        return NativeUIBridgeEngineReport(
            engineId: engine.id,
            engineName: engine.name,
            buildRootPath: buildRoot?.path,
            hostComponent: host,
            architectures: architectures,
            warnings: warnings
        )
    }

    private func architectureReport(
        _ architecture: WindowsExecutableArchitecture,
        buildRoot: URL?
    ) -> NativeUIBridgeArchitectureReport {
        NativeUIBridgeArchitectureReport(
            architecture: architecture,
            components: [
                componentReport(
                    component: .alerts,
                    candidates: moduleCandidates(
                        buildRoot: buildRoot,
                        module: "user32",
                        fileName: "user32.dll",
                        architecture: architecture
                    ),
                    markers: ["MACWIN_NATIVE_UI", "alerts"]
                ),
                componentReport(
                    component: .legacyFileDialogs,
                    candidates: moduleCandidates(
                        buildRoot: buildRoot,
                        module: "comdlg32",
                        fileName: "comdlg32.dll",
                        architecture: architecture
                    ),
                    markers: ["MACWIN_NATIVE_UI", "file-dialogs"]
                ),
                componentReport(
                    component: .modernFileDialogs,
                    candidates: moduleCandidates(
                        buildRoot: buildRoot,
                        module: "comdlg32",
                        fileName: "comdlg32.dll",
                        architecture: architecture
                    ),
                    markers: ["MACWIN_NATIVE_UI", "modern-file-dialogs"]
                ),
                componentReport(
                    component: .taskDialogs,
                    candidates: moduleCandidates(
                        buildRoot: buildRoot,
                        module: "comctl32_v6",
                        fileName: "comctl32_v6.dll",
                        architecture: architecture
                    ),
                    markers: ["MACWIN_NATIVE_UI", "task-dialogs"]
                )
            ]
        )
    }

    private func componentReport(
        component: NativeUIBridgeComponent,
        candidates: [URL],
        markers: [String]
    ) -> NativeUIBridgeComponentReport {
        guard let url = candidates.first(where: { fileManager.fileExists(atPath: $0.path) }) else {
            return NativeUIBridgeComponentReport(
                component: component,
                path: nil,
                requiredMarkers: markers,
                missingMarkers: markers
            )
        }
        guard let data = try? Data(contentsOf: url, options: [.mappedIfSafe]) else {
            return NativeUIBridgeComponentReport(
                component: component,
                path: url.path,
                requiredMarkers: markers,
                missingMarkers: markers
            )
        }
        let missing = markers.filter { marker in
            data.range(of: Data(marker.utf8)) == nil
        }
        return NativeUIBridgeComponentReport(
            component: component,
            path: url.path,
            requiredMarkers: markers,
            missingMarkers: missing
        )
    }

    private func buildRoot(for engine: EngineManifest) -> URL? {
        let wineURL = URL(fileURLWithPath: engine.winePath).resolvingSymlinksInPath()
        guard fileManager.fileExists(atPath: wineURL.path) else { return nil }
        let parent = wineURL.deletingLastPathComponent()
        if parent.lastPathComponent == "loader" || parent.lastPathComponent == "bin" {
            return parent.deletingLastPathComponent()
        }
        return parent
    }

    private func moduleCandidates(
        buildRoot: URL?,
        module: String,
        fileName: String,
        architecture: WindowsExecutableArchitecture
    ) -> [URL] {
        guard let buildRoot else { return [] }
        let architectureDirectory = "\(architecture.rawValue)-windows"
        return [
            buildRoot
                .appendingPathComponent("dlls", isDirectory: true)
                .appendingPathComponent(module, isDirectory: true)
                .appendingPathComponent(architectureDirectory, isDirectory: true)
                .appendingPathComponent(fileName),
            buildRoot
                .appendingPathComponent("lib/wine", isDirectory: true)
                .appendingPathComponent(architectureDirectory, isDirectory: true)
                .appendingPathComponent(fileName),
            buildRoot
                .appendingPathComponent("lib64/wine", isDirectory: true)
                .appendingPathComponent(architectureDirectory, isDirectory: true)
                .appendingPathComponent(fileName)
        ]
    }

    private func hostCandidates(buildRoot: URL?) -> [URL] {
        guard let buildRoot else { return [] }
        return [
            buildRoot
                .appendingPathComponent("dlls/winemac.drv", isDirectory: true)
                .appendingPathComponent("winemac.so"),
            buildRoot
                .appendingPathComponent("lib/wine", isDirectory: true)
                .appendingPathComponent("x86_64-unix/winemac.so"),
            buildRoot
                .appendingPathComponent("lib64/wine", isDirectory: true)
                .appendingPathComponent("x86_64-unix/winemac.so")
        ]
    }
}
