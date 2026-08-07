import Foundation
import Testing
@testable import MacWinCore

@Suite("Mac native UI bridge health")
struct NativeUIBridgeHealthServiceTests {
    @Test("Complete WoW64 engine reports both bridge architectures ready")
    func completeWoW64EngineIsReady() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinNativeUIBridge-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let engine = try makeEngine(root: root, supportsWin32: true)
        try writeCompleteBridge(buildRoot: root, architectures: [.x86_64, .i386])

        let report = NativeUIBridgeHealthService().report(
            engines: [engine],
            generatedAt: Date(timeIntervalSince1970: 100)
        )
        let engineReport = try #require(report.engines.first)

        #expect(report.readyEngineCount == 1)
        #expect(engineReport.isReady)
        #expect(engineReport.hostComponent.isReady)
        #expect(engineReport.architecture(.x86_64)?.isReady == true)
        #expect(engineReport.architecture(.i386)?.isReady == true)
        #expect(engineReport.warnings.isEmpty)

        let encoded = try JSONEncoder().encode(report)
        let json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        let encodedEngines = try #require(json["engines"] as? [[String: Any]])
        let encodedArchitectures = try #require(encodedEngines.first?["architectures"] as? [[String: Any]])
        #expect(json["readyEngineCount"] as? Int == 1)
        #expect(encodedEngines.first?["isReady"] as? Bool == true)
        #expect(encodedArchitectures.allSatisfy { $0["isReady"] as? Bool == true })
    }

    @Test("Missing marker identifies the incomplete component")
    func missingMarkerIsReported() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinNativeUIBridgeMissing-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let engine = try makeEngine(root: root, supportsWin32: false)
        try writeCompleteBridge(buildRoot: root, architectures: [.x86_64])
        let taskDialog = root
            .appendingPathComponent("dlls/comctl32_v6/x86_64-windows", isDirectory: true)
            .appendingPathComponent("comctl32_v6.dll")
        try Data("MACWIN_NATIVE_UI".utf8).write(to: taskDialog)

        let engineReport = try #require(
            NativeUIBridgeHealthService().report(engines: [engine]).engines.first
        )
        let architecture = try #require(engineReport.architecture(.x86_64))
        let component = try #require(
            architecture.components.first { $0.component == .taskDialogs }
        )

        #expect(!engineReport.isReady)
        #expect(!component.isReady)
        #expect(component.missingMarkers == ["task-dialogs"])
        #expect(engineReport.architecture(.i386) == nil)
        #expect(engineReport.warnings == ["x86_64-bridge-incomplete"])
    }

    @Test("Capability report includes bridge health for its engines")
    func capabilityReportIncludesBridgeHealth() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacWinNativeUIBridgeCapability-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let engine = try makeEngine(root: root, supportsWin32: false)
        try writeCompleteBridge(buildRoot: root, architectures: [.x86_64])
        let paths = MacWinPaths(root: root.appendingPathComponent("app-support", isDirectory: true))
        let report = CapabilityReportService(
            paths: paths,
            testAssetService: TestAssetService(root: root.appendingPathComponent("assets", isDirectory: true))
        ).makeReport(
            generatedAt: Date(timeIntervalSince1970: 200),
            engines: [engine],
            bottles: [],
            recipes: []
        )

        #expect(report.nativeUIBridgeHealth?.generatedAt == Date(timeIntervalSince1970: 200))
        #expect(report.nativeUIBridgeHealth?.readyEngineCount == 1)
        #expect(report.nativeUIBridgeHealth?.engines.first?.engineId == engine.id)
    }

    private func makeEngine(root: URL, supportsWin32: Bool) throws -> EngineManifest {
        let loader = root.appendingPathComponent("loader", isDirectory: true)
        try FileManager.default.createDirectory(at: loader, withIntermediateDirectories: true)
        let wine = loader.appendingPathComponent("wine")
        try Data("wine".utf8).write(to: wine)
        return EngineManifest(
            id: supportsWin32 ? "wow64" : "x64",
            name: supportsWin32 ? "WoW64 Engine" : "x64 Engine",
            wineVersion: "wine-test",
            arch: .win64,
            supportsWin32: supportsWin32,
            winePath: wine.path,
            wineserverPath: loader.appendingPathComponent("wineserver").path,
            runtimePath: root.appendingPathComponent("runtime").path,
            defaultEnv: [:]
        )
    }

    private func writeCompleteBridge(
        buildRoot: URL,
        architectures: [WindowsExecutableArchitecture]
    ) throws {
        try write(
            "MacWinFileTypeSelector NSSavePanel",
            to: buildRoot.appendingPathComponent("dlls/winemac.drv/winemac.so")
        )
        for architecture in architectures {
            let architectureDirectory = "\(architecture.rawValue)-windows"
            try write(
                "MACWIN_NATIVE_UI alerts",
                to: buildRoot.appendingPathComponent("dlls/user32/\(architectureDirectory)/user32.dll")
            )
            try write(
                "MACWIN_NATIVE_UI file-dialogs modern-file-dialogs",
                to: buildRoot.appendingPathComponent("dlls/comdlg32/\(architectureDirectory)/comdlg32.dll")
            )
            try write(
                "MACWIN_NATIVE_UI task-dialogs",
                to: buildRoot.appendingPathComponent("dlls/comctl32_v6/\(architectureDirectory)/comctl32_v6.dll")
            )
        }
    }

    private func write(_ value: String, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(value.utf8).write(to: url)
    }
}
