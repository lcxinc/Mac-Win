import CoreGraphics
import Foundation

public enum HostGUISessionState: String, Codable, CaseIterable, Sendable {
    case unlocked
    case locked
    case unavailable
}

public struct HostGUISessionReport: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var state: HostGUISessionState
    public var isInteractive: Bool

    public init(generatedAt: Date = Date(), state: HostGUISessionState) {
        self.generatedAt = generatedAt
        self.state = state
        self.isInteractive = state == .unlocked
    }
}

public struct HostGUISessionService: Sendable {
    private let stateProvider: @Sendable () -> HostGUISessionState

    public init(
        stateProvider: @escaping @Sendable () -> HostGUISessionState = HostGUISessionService.currentState
    ) {
        self.stateProvider = stateProvider
    }

    public func report(generatedAt: Date = Date()) -> HostGUISessionReport {
        HostGUISessionReport(generatedAt: generatedAt, state: stateProvider())
    }

    public static func currentState() -> HostGUISessionState {
        guard let session = CGSessionCopyCurrentDictionary() as? [String: Any] else {
            return .unavailable
        }
        if boolValue(session["CGSSessionScreenIsLocked"]) == true {
            return .locked
        }
        return .unlocked
    }

    private static func boolValue(_ value: Any?) -> Bool? {
        if let value = value as? Bool { return value }
        if let value = value as? NSNumber { return value.boolValue }
        return nil
    }
}
