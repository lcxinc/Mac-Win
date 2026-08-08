import XCTest
@testable import MacWinCore

final class CompatForgeClientTests: XCTestCase {
    func testVersionedJSONRequiresSchemaVersion() throws {
        let document = try CompatForgeJSONDocument(
            utf8: #"{"schemaVersion":"1","bottleId":"example"}"#
        )
        XCTAssertEqual(document.schemaVersion, "1")

        XCTAssertThrowsError(try CompatForgeJSONDocument(utf8: #"{"bottleId":"example"}"#))
    }

    func testRuntimeClientBoundaryPreservesVersionedJSON() throws {
        let client: any RuntimeClient = StubRuntimeClient()
        let config = try CompatForgeJSONDocument(utf8: #"{"schemaVersion":"1","kind":"config"}"#)
        let request = try CompatForgeJSONDocument(utf8: #"{"schemaVersion":"1","kind":"request"}"#)

        XCTAssertEqual(try client.versionInfo().abiVersion, 1)
        XCTAssertEqual(
            try client.compileLaunch(config: config, request: request),
            request
        )
    }
}

private struct StubRuntimeClient: RuntimeClient {
    func versionInfo() throws -> CompatForgeVersionInfo {
        CompatForgeVersionInfo(apiVersion: "test", abiVersion: 1)
    }

    func compileLaunch(
        config: CompatForgeJSONDocument,
        request: CompatForgeJSONDocument
    ) throws -> CompatForgeJSONDocument {
        request
    }
}
