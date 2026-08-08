import Darwin
import Foundation

public struct CompatForgeJSONDocument: Equatable, Sendable {
    public let data: Data
    public let schemaVersion: String

    public init(data: Data) throws {
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw CompatForgeClientError.invalidJSON(error.localizedDescription)
        }
        guard let dictionary = object as? [String: Any],
              let schemaVersion = dictionary["schemaVersion"] as? String,
              !schemaVersion.isEmpty else {
            throw CompatForgeClientError.invalidJSON("missing schemaVersion")
        }
        self.data = data
        self.schemaVersion = schemaVersion
    }

    public init(utf8: String) throws {
        try self.init(data: Data(utf8.utf8))
    }
}

public struct CompatForgeVersionInfo: Equatable, Sendable {
    public var apiVersion: String
    public var abiVersion: UInt32

    public init(apiVersion: String, abiVersion: UInt32) {
        self.apiVersion = apiVersion
        self.abiVersion = abiVersion
    }
}

public protocol RuntimeClient: Sendable {
    func versionInfo() throws -> CompatForgeVersionInfo
    func compileLaunch(
        config: CompatForgeJSONDocument,
        request: CompatForgeJSONDocument
    ) throws -> CompatForgeJSONDocument
}

public protocol BottleClient: Sendable {
    func listBottles() async throws -> [CompatForgeJSONDocument]
    func createBottle(_ manifest: CompatForgeJSONDocument) async throws -> CompatForgeJSONDocument
    func snapshotBottle(id: String) async throws -> CompatForgeJSONDocument
    func migrateBottle(id: String, targetSchemaVersion: String) async throws -> CompatForgeJSONDocument
    func restoreBottle(id: String, snapshot: CompatForgeJSONDocument) async throws
}

public protocol DiagnosticsClient: Sendable {
    func queryEvents(_ request: CompatForgeJSONDocument) async throws -> CompatForgeJSONDocument
    func runChecks(_ request: CompatForgeJSONDocument) async throws -> CompatForgeJSONDocument
    func exportRedactedBundle(_ request: CompatForgeJSONDocument) async throws -> URL
}

public enum CompatForgeClientError: Error, Equatable, LocalizedError, Sendable {
    case invalidJSON(String)
    case invalidUTF8
    case libraryLoadFailed(String)
    case missingSymbol(String)
    case unsupportedABIVersion(UInt32)
    case coreFailure(status: UInt32, detail: String)

    public var errorDescription: String? {
        switch self {
        case .invalidJSON(let detail):
            "Invalid CompatForge JSON: \(detail)"
        case .invalidUTF8:
            "CompatForge returned invalid UTF-8"
        case .libraryLoadFailed(let detail):
            "Unable to load CompatForge Core: \(detail)"
        case .missingSymbol(let symbol):
            "CompatForge Core is missing symbol \(symbol)"
        case .unsupportedABIVersion(let version):
            "Unsupported CompatForge ABI version \(version)"
        case .coreFailure(let status, let detail):
            "CompatForge Core failed with status \(status): \(detail)"
        }
    }
}

public final class CompatForgeRuntimeClient: RuntimeClient, @unchecked Sendable {
    private typealias APIVersionFunction = @convention(c) () -> UnsafePointer<CChar>?
    private typealias ABIVersionFunction = @convention(c) () -> UInt32
    private typealias ContextCreateFunction = @convention(c) (
        UnsafePointer<CChar>?,
        UnsafeMutablePointer<OpaquePointer?>?
    ) -> UInt32
    private typealias CompileLaunchFunction = @convention(c) (
        OpaquePointer?,
        UnsafePointer<CChar>?,
        UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
    ) -> UInt32
    private typealias LastErrorFunction = @convention(c) (
        UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
    ) -> UInt32
    private typealias StringFreeFunction = @convention(c) (UnsafeMutablePointer<CChar>?) -> Void
    private typealias ContextReleaseFunction = @convention(c) (OpaquePointer?) -> Void

    private let libraryHandle: UnsafeMutableRawPointer
    private let apiVersionFunction: APIVersionFunction
    private let abiVersionFunction: ABIVersionFunction
    private let contextCreateFunction: ContextCreateFunction
    private let compileLaunchFunction: CompileLaunchFunction
    private let lastErrorFunction: LastErrorFunction
    private let stringFreeFunction: StringFreeFunction
    private let contextReleaseFunction: ContextReleaseFunction

    public init(libraryURL: URL) throws {
        guard libraryURL.isFileURL else {
            throw CompatForgeClientError.libraryLoadFailed("library URL is not a file URL")
        }
        let handle = libraryURL.path.withCString { path in
            dlopen(path, RTLD_NOW | RTLD_LOCAL)
        }
        guard let handle else {
            let detail = dlerror().map { String(cString: $0) } ?? "unknown loader error"
            throw CompatForgeClientError.libraryLoadFailed(detail)
        }

        do {
            let apiVersion: APIVersionFunction = try Self.loadSymbol("cf_api_version", from: handle)
            let abiVersion: ABIVersionFunction = try Self.loadSymbol("cf_abi_version", from: handle)
            let contextCreate: ContextCreateFunction = try Self.loadSymbol("cf_context_create", from: handle)
            let compileLaunch: CompileLaunchFunction = try Self.loadSymbol("cf_compile_launch", from: handle)
            let lastError: LastErrorFunction = try Self.loadSymbol("cf_last_error_json", from: handle)
            let stringFree: StringFreeFunction = try Self.loadSymbol("cf_string_free", from: handle)
            let contextRelease: ContextReleaseFunction = try Self.loadSymbol("cf_context_release", from: handle)

            let abi = abiVersion()
            guard abi == 1 else {
                throw CompatForgeClientError.unsupportedABIVersion(abi)
            }

            libraryHandle = handle
            apiVersionFunction = apiVersion
            abiVersionFunction = abiVersion
            contextCreateFunction = contextCreate
            compileLaunchFunction = compileLaunch
            lastErrorFunction = lastError
            stringFreeFunction = stringFree
            contextReleaseFunction = contextRelease
        } catch {
            dlclose(handle)
            throw error
        }
    }

    deinit {
        dlclose(libraryHandle)
    }

    public func versionInfo() throws -> CompatForgeVersionInfo {
        guard let version = apiVersionFunction() else {
            throw CompatForgeClientError.invalidUTF8
        }
        return CompatForgeVersionInfo(
            apiVersion: String(cString: version),
            abiVersion: abiVersionFunction()
        )
    }

    public func compileLaunch(
        config: CompatForgeJSONDocument,
        request: CompatForgeJSONDocument
    ) throws -> CompatForgeJSONDocument {
        guard let configJSON = String(data: config.data, encoding: .utf8),
              let requestJSON = String(data: request.data, encoding: .utf8) else {
            throw CompatForgeClientError.invalidUTF8
        }

        var context: OpaquePointer?
        let createStatus = configJSON.withCString { pointer in
            contextCreateFunction(pointer, &context)
        }
        guard createStatus == 0, let context else {
            throw coreError(status: createStatus)
        }
        defer { contextReleaseFunction(context) }

        var planPointer: UnsafeMutablePointer<CChar>?
        let compileStatus = requestJSON.withCString { pointer in
            compileLaunchFunction(context, pointer, &planPointer)
        }
        guard compileStatus == 0, let planPointer else {
            throw coreError(status: compileStatus)
        }
        defer { stringFreeFunction(planPointer) }

        guard let planJSON = String(validatingUTF8: planPointer) else {
            throw CompatForgeClientError.invalidUTF8
        }
        return try CompatForgeJSONDocument(utf8: planJSON)
    }

    private func coreError(status: UInt32) -> CompatForgeClientError {
        var errorPointer: UnsafeMutablePointer<CChar>?
        let errorStatus = lastErrorFunction(&errorPointer)
        guard errorStatus == 0, let errorPointer else {
            return .coreFailure(status: status, detail: "structured error unavailable")
        }
        defer { stringFreeFunction(errorPointer) }
        let detail = String(validatingUTF8: errorPointer) ?? "invalid structured error UTF-8"
        return .coreFailure(status: status, detail: detail)
    }

    private static func loadSymbol<T>(
        _ name: String,
        from handle: UnsafeMutableRawPointer
    ) throws -> T {
        let symbol = name.withCString { symbolName in
            dlsym(handle, symbolName)
        }
        guard let symbol else {
            throw CompatForgeClientError.missingSymbol(name)
        }
        return unsafeBitCast(symbol, to: T.self)
    }
}
