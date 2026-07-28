import Foundation

public enum EngineRuntimeCoverage {
    public static func buildDirectory(for engine: EngineManifest) -> URL {
        URL(fileURLWithPath: engine.winePath)
            .standardizedFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    public static func wpsOfficeFltlibSources(for engine: EngineManifest) -> [URL] {
        let buildDirectory = buildDirectory(for: engine)
        var sources = [
            buildDirectory.appendingPathComponent("dlls/fltlib/x86_64-windows/fltlib.dll"),
        ]
        if engine.supportsWin32 {
            sources.append(
                buildDirectory.appendingPathComponent("dlls/fltlib/i386-windows/fltlib.dll")
            )
        }
        return sources
    }
}
