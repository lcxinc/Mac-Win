import Foundation

public enum NativeUIIntegrationCapability: String, CaseIterable, Codable, Sendable {
    case windowChrome = "window-chrome"
    case alerts
    case fileDialogs = "file-dialogs"
    case modernFileDialogs = "modern-file-dialogs"
    case taskDialogs = "task-dialogs"
}

public enum NativeUIIntegrationPreset: String, CaseIterable, Codable, Sendable {
    case disabled
    case automatic
    case windowIntegration = "window-integration"
    case nativeDialogs = "native-dialogs"

    public static let environmentKey = "MACWIN_NATIVE_UI"

    public var capabilities: Set<NativeUIIntegrationCapability> {
        switch self {
        case .disabled:
            []
        case .automatic, .nativeDialogs:
            [.windowChrome, .alerts, .fileDialogs, .modernFileDialogs, .taskDialogs]
        case .windowIntegration:
            [.windowChrome]
        }
    }

    public var environmentValue: String {
        if self == .disabled {
            return "off"
        }
        let value = capabilities
            .map(\.rawValue)
            .sorted()
            .joined(separator: ",")
        return self == .automatic ? "automatic,\(value)" : value
    }

    public static func current(in bottle: BottleManifest) -> NativeUIIntegrationPreset {
        from(environmentValue: bottle.envOverrides[environmentKey])
    }

    public static func from(environmentValue: String?) -> NativeUIIntegrationPreset {
        guard let environmentValue else { return .disabled }
        let normalized = Set(environmentValue
            .lowercased()
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
        guard !normalized.isEmpty, !normalized.contains("off") else { return .disabled }
        if normalized.contains(NativeUIIntegrationPreset.automatic.rawValue) {
            return .automatic
        }
        if normalized.contains(NativeUIIntegrationCapability.alerts.rawValue)
            || normalized.contains(NativeUIIntegrationCapability.fileDialogs.rawValue)
            || normalized.contains(NativeUIIntegrationCapability.modernFileDialogs.rawValue)
            || normalized.contains(NativeUIIntegrationCapability.taskDialogs.rawValue) {
            return .nativeDialogs
        }
        if normalized.contains(NativeUIIntegrationCapability.windowChrome.rawValue) {
            return .windowIntegration
        }
        return .disabled
    }
}
