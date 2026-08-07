import Foundation

public enum MacWinError: Error, LocalizedError, Equatable, Sendable {
    case missingFile(String)
    case invalidPath(String)
    case invalidManifest(String)
    case unsupportedEngine(String)
    case processFailed(command: String, exitCode: Int32, logPath: String)
    case processLaunchFailed(String)
    case guiSessionLocked
    case runtimeUnavailable(processIdentifiers: [Int32])
    case catalogSignatureInvalid
    case catalogHashMismatch(recipeId: String, expected: String, actual: String)
    case installerRequired(String)
    case unsupportedInstallerMode(String)

    public var errorDescription: String? {
        switch self {
        case .missingFile(let path):
            "Missing file: \(path)"
        case .invalidPath(let path):
            "Invalid path: \(path)"
        case .invalidManifest(let reason):
            "Invalid manifest: \(reason)"
        case .unsupportedEngine(let reason):
            "Unsupported engine: \(reason)"
        case .processFailed(let command, let exitCode, let logPath):
            "Process failed (\(exitCode)): \(command). Log: \(logPath)"
        case .processLaunchFailed(let reason):
            "Unable to launch process: \(reason)"
        case .guiSessionLocked:
            "The macOS session is locked. Unlock the Mac before running a visual Windows UI probe."
        case .runtimeUnavailable(let processIdentifiers):
            "Wine runtime is unavailable because Rosetta has uninterruptible Wine processes (PIDs: \(processIdentifiers.map(String.init).joined(separator: ", "))). Restart macOS or recover Rosetta before launching another Windows application."
        case .catalogSignatureInvalid:
            "Catalog signature is invalid"
        case .catalogHashMismatch(let recipeId, let expected, let actual):
            "Catalog recipe hash mismatch for \(recipeId). Expected \(expected), got \(actual)"
        case .installerRequired(let recipe):
            "Installer is required for \(recipe)"
        case .unsupportedInstallerMode(let mode):
            "Unsupported installer mode: \(mode)"
        }
    }
}
