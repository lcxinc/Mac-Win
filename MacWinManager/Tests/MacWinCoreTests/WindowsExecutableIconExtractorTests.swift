import Foundation
import Testing
@testable import MacWinCore

@Suite("Windows executable icon extractor")
struct WindowsExecutableIconExtractorTests {
    @Test("Group icon data is converted to ICO data")
    func groupIconDataIsConvertedToICOData() throws {
        var group = Data()
        group.appendUInt16LE(0)
        group.appendUInt16LE(1)
        group.appendUInt16LE(1)
        group.append(32)
        group.append(32)
        group.append(0)
        group.append(0)
        group.appendUInt16LE(1)
        group.appendUInt16LE(32)
        group.appendUInt32LE(4)
        group.appendUInt16LE(7)

        let ico = try #require(WindowsExecutableIconExtractor.icoData(
            groupIconData: group,
            iconImagesByID: [7: Data([1, 2, 3, 4])]
        ))

        #expect(ico.count == 26)
        #expect(ico[0] == 0)
        #expect(ico[2] == 1)
        #expect(ico[4] == 1)
        #expect(ico[6] == 32)
        #expect(ico[7] == 32)
        #expect(ico.suffix(4) == Data([1, 2, 3, 4]))
    }
}

private extension Data {
    mutating func appendUInt16LE(_ value: UInt16) {
        append(UInt8(value & 0x00ff))
        append(UInt8(value >> 8))
    }

    mutating func appendUInt32LE(_ value: UInt32) {
        append(UInt8(value & 0x000000ff))
        append(UInt8((value >> 8) & 0x000000ff))
        append(UInt8((value >> 16) & 0x000000ff))
        append(UInt8((value >> 24) & 0x000000ff))
    }
}
