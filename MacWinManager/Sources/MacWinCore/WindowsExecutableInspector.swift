import Foundation

public enum WindowsExecutableInspector {
    public static func architecture(of url: URL, fileManager: FileManager = .default) throws -> WindowsExecutableArchitecture? {
        guard fileManager.fileExists(atPath: url.path) else {
            throw MacWinError.missingFile(url.path)
        }
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let data = try handle.read(upToCount: 4096) ?? Data()
        return architecture(of: data)
    }

    public static func architecture(of data: Data) -> WindowsExecutableArchitecture? {
        guard data.count >= 0x40,
              data[0] == 0x4d,
              data[1] == 0x5a,
              let peOffsetRaw = readUInt32(data, offset: 0x3c) else {
            return nil
        }

        let peOffset = Int(peOffsetRaw)
        guard peOffset >= 0,
              peOffset + 6 <= data.count,
              data[peOffset] == 0x50,
              data[peOffset + 1] == 0x45,
              data[peOffset + 2] == 0,
              data[peOffset + 3] == 0,
              let machine = readUInt16(data, offset: peOffset + 4) else {
            return nil
        }

        switch machine {
        case 0x014c:
            return .i386
        case 0x8664:
            return .x86_64
        case 0xaa64:
            return .arm64
        default:
            return .unknown
        }
    }

    private static func readUInt16(_ data: Data, offset: Int) -> UInt16? {
        guard offset >= 0, offset + 2 <= data.count else { return nil }
        return UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }

    private static func readUInt32(_ data: Data, offset: Int) -> UInt32? {
        guard offset >= 0, offset + 4 <= data.count else { return nil }
        return UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
    }
}
