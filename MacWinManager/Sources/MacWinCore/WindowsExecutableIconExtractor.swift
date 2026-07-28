import Foundation

public enum WindowsExecutableIconExtractor {
    public static func extractBestIcon(from url: URL, fileManager: FileManager = .default) throws -> Data? {
        guard fileManager.fileExists(atPath: url.path) else {
            throw MacWinError.missingFile(url.path)
        }
        let data = try Data(contentsOf: url)
        return extractBestIcon(from: data)
    }

    public static func extractBestIcon(from data: Data) -> Data? {
        guard let pe = PEImage(data: data),
              let resourceRoot = pe.resourceDirectoryFileOffset else {
            return nil
        }

        let iconImages = resourceDataEntries(typeID: 3, pe: pe, resourceRoot: resourceRoot)
            .compactMap { entry -> (UInt16, Data)? in
                guard let id = entry.nameID,
                      let data = pe.data(forResourceRVA: entry.dataRVA, size: entry.size) else {
                    return nil
                }
                return (id, data)
            }
            .reduce(into: [UInt16: Data]()) { result, item in
                result[item.0] = item.1
            }

        let groups = resourceDataEntries(typeID: 14, pe: pe, resourceRoot: resourceRoot)
            .compactMap { entry -> Data? in
                pe.data(forResourceRVA: entry.dataRVA, size: entry.size)
            }

        for group in groups {
            if let ico = icoData(groupIconData: group, iconImagesByID: iconImages) {
                return ico
            }
        }
        return nil
    }

    public static func icoData(groupIconData: Data, iconImagesByID: [UInt16: Data]) -> Data? {
        guard groupIconData.count >= 6,
              groupIconData.readUInt16LE(at: 0) == 0,
              groupIconData.readUInt16LE(at: 2) == 1,
              let count = groupIconData.readUInt16LE(at: 4),
              count > 0 else {
            return nil
        }

        var entries: [GroupIconEntry] = []
        for index in 0..<Int(count) {
            let offset = 6 + index * 14
            guard offset + 14 <= groupIconData.count,
                  let bytesInRes = groupIconData.readUInt32LE(at: offset + 8),
                  let id = groupIconData.readUInt16LE(at: offset + 12),
                  let image = iconImagesByID[id] else {
                continue
            }
            entries.append(
                GroupIconEntry(
                    width: groupIconData[offset],
                    height: groupIconData[offset + 1],
                    colorCount: groupIconData[offset + 2],
                    reserved: groupIconData[offset + 3],
                    planes: groupIconData.readUInt16LE(at: offset + 4) ?? 0,
                    bitCount: groupIconData.readUInt16LE(at: offset + 6) ?? 0,
                    bytesInRes: UInt32(image.count == Int(bytesInRes) ? bytesInRes : UInt32(image.count)),
                    image: image
                )
            )
        }

        guard !entries.isEmpty else { return nil }
        entries.sort {
            if $0.pixelCount != $1.pixelCount {
                return $0.pixelCount > $1.pixelCount
            }
            return $0.image.count > $1.image.count
        }

        let selected = Array(entries.prefix(1))
        var output = Data()
        output.appendUInt16LE(0)
        output.appendUInt16LE(1)
        output.appendUInt16LE(UInt16(selected.count))

        var imageOffset = UInt32(6 + selected.count * 16)
        var imageData = Data()
        for entry in selected {
            output.append(entry.width)
            output.append(entry.height)
            output.append(entry.colorCount)
            output.append(entry.reserved)
            output.appendUInt16LE(entry.planes)
            output.appendUInt16LE(entry.bitCount)
            output.appendUInt32LE(UInt32(entry.image.count))
            output.appendUInt32LE(imageOffset)
            imageData.append(entry.image)
            imageOffset += UInt32(entry.image.count)
        }
        output.append(imageData)
        return output
    }

    private static func resourceDataEntries(typeID: UInt16, pe: PEImage, resourceRoot: Int) -> [ResourceDataEntry] {
        guard let typeDirectory = findResourceDirectoryEntry(id: typeID, directoryOffset: resourceRoot, pe: pe, resourceRoot: resourceRoot),
              typeDirectory.isDirectory else {
            return []
        }
        var entries: [ResourceDataEntry] = []
        for nameEntry in directoryEntries(directoryOffset: typeDirectory.targetOffset, pe: pe) {
            guard nameEntry.isDirectory else { continue }
            for languageEntry in directoryEntries(directoryOffset: nameEntry.targetOffset, pe: pe) {
                if languageEntry.isDirectory {
                    continue
                }
                guard let dataEntry = readResourceDataEntry(offset: languageEntry.targetOffset, pe: pe) else {
                    continue
                }
                entries.append(
                    ResourceDataEntry(
                        nameID: nameEntry.id,
                        dataRVA: dataEntry.dataRVA,
                        size: dataEntry.size
                    )
                )
            }
        }
        return entries
    }

    private static func findResourceDirectoryEntry(id: UInt16, directoryOffset: Int, pe: PEImage, resourceRoot: Int) -> ResourceDirectoryEntry? {
        directoryEntries(directoryOffset: directoryOffset, pe: pe).first { $0.id == id }
    }

    private static func directoryEntries(directoryOffset: Int, pe: PEImage) -> [ResourceDirectoryEntry] {
        let data = pe.data
        guard directoryOffset + 16 <= data.count,
              let namedCount = data.readUInt16LE(at: directoryOffset + 12),
              let idCount = data.readUInt16LE(at: directoryOffset + 14) else {
            return []
        }

        let count = Int(namedCount) + Int(idCount)
        var entries: [ResourceDirectoryEntry] = []
        for index in 0..<count {
            let offset = directoryOffset + 16 + index * 8
            guard offset + 8 <= data.count,
                  let nameRaw = data.readUInt32LE(at: offset),
                  let targetRaw = data.readUInt32LE(at: offset + 4) else {
                continue
            }
            let isNamed = (nameRaw & 0x8000_0000) != 0
            let isDirectory = (targetRaw & 0x8000_0000) != 0
            let targetRelativeOffset = Int(targetRaw & 0x7fff_ffff)
            entries.append(
                ResourceDirectoryEntry(
                    id: isNamed ? nil : UInt16(nameRaw & 0xffff),
                    isDirectory: isDirectory,
                    targetOffset: pe.resourceDirectoryFileOffset! + targetRelativeOffset
                )
            )
        }
        return entries
    }

    private static func readResourceDataEntry(offset: Int, pe: PEImage) -> (dataRVA: UInt32, size: UInt32)? {
        guard offset + 16 <= pe.data.count,
              let dataRVA = pe.data.readUInt32LE(at: offset),
              let size = pe.data.readUInt32LE(at: offset + 4) else {
            return nil
        }
        return (dataRVA, size)
    }
}

private struct GroupIconEntry {
    var width: UInt8
    var height: UInt8
    var colorCount: UInt8
    var reserved: UInt8
    var planes: UInt16
    var bitCount: UInt16
    var bytesInRes: UInt32
    var image: Data

    var pixelCount: Int {
        let w = width == 0 ? 256 : Int(width)
        let h = height == 0 ? 256 : Int(height)
        return w * h
    }
}

private struct ResourceDirectoryEntry {
    var id: UInt16?
    var isDirectory: Bool
    var targetOffset: Int
}

private struct ResourceDataEntry {
    var nameID: UInt16?
    var dataRVA: UInt32
    var size: UInt32
}

private struct PEImage {
    struct Section {
        var virtualAddress: UInt32
        var virtualSize: UInt32
        var rawDataPointer: UInt32
        var rawDataSize: UInt32
    }

    var data: Data
    var sections: [Section]
    var resourceDirectoryRVA: UInt32

    var resourceDirectoryFileOffset: Int? {
        fileOffset(forRVA: resourceDirectoryRVA)
    }

    init?(data: Data) {
        guard data.count >= 0x40,
              data[0] == 0x4d,
              data[1] == 0x5a,
              let peOffsetRaw = data.readUInt32LE(at: 0x3c) else {
            return nil
        }
        let peOffset = Int(peOffsetRaw)
        guard peOffset + 24 <= data.count,
              data[peOffset] == 0x50,
              data[peOffset + 1] == 0x45,
              data[peOffset + 2] == 0,
              data[peOffset + 3] == 0,
              let sectionCount = data.readUInt16LE(at: peOffset + 6),
              let optionalHeaderSize = data.readUInt16LE(at: peOffset + 20),
              let magic = data.readUInt16LE(at: peOffset + 24) else {
            return nil
        }

        let optionalOffset = peOffset + 24
        let dataDirectoryOffset: Int
        switch magic {
        case 0x10b:
            dataDirectoryOffset = optionalOffset + 96
        case 0x20b:
            dataDirectoryOffset = optionalOffset + 112
        default:
            return nil
        }
        let resourceDirectoryOffset = dataDirectoryOffset + 8 * 2
        guard resourceDirectoryOffset + 8 <= data.count,
              let resourceRVA = data.readUInt32LE(at: resourceDirectoryOffset),
              resourceRVA != 0 else {
            return nil
        }

        let sectionTableOffset = optionalOffset + Int(optionalHeaderSize)
        var sections: [Section] = []
        for index in 0..<Int(sectionCount) {
            let offset = sectionTableOffset + index * 40
            guard offset + 40 <= data.count,
                  let virtualSize = data.readUInt32LE(at: offset + 8),
                  let virtualAddress = data.readUInt32LE(at: offset + 12),
                  let rawDataSize = data.readUInt32LE(at: offset + 16),
                  let rawDataPointer = data.readUInt32LE(at: offset + 20) else {
                continue
            }
            sections.append(
                Section(
                    virtualAddress: virtualAddress,
                    virtualSize: virtualSize,
                    rawDataPointer: rawDataPointer,
                    rawDataSize: rawDataSize
                )
            )
        }

        self.data = data
        self.sections = sections
        self.resourceDirectoryRVA = resourceRVA
    }

    func data(forResourceRVA rva: UInt32, size: UInt32) -> Data? {
        guard let offset = fileOffset(forRVA: rva),
              offset >= 0,
              offset + Int(size) <= data.count else {
            return nil
        }
        return data.subdata(in: offset..<(offset + Int(size)))
    }

    private func fileOffset(forRVA rva: UInt32) -> Int? {
        for section in sections {
            let span = max(section.virtualSize, section.rawDataSize)
            if rva >= section.virtualAddress && rva < section.virtualAddress + span {
                return Int(section.rawDataPointer + (rva - section.virtualAddress))
            }
        }
        return nil
    }
}

private extension Data {
    func readUInt16LE(at offset: Int) -> UInt16? {
        guard offset >= 0, offset + 2 <= count else { return nil }
        return UInt16(self[offset]) | (UInt16(self[offset + 1]) << 8)
    }

    func readUInt32LE(at offset: Int) -> UInt32? {
        guard offset >= 0, offset + 4 <= count else { return nil }
        return UInt32(self[offset])
            | (UInt32(self[offset + 1]) << 8)
            | (UInt32(self[offset + 2]) << 16)
            | (UInt32(self[offset + 3]) << 24)
    }

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
