import CryptoKit
import Foundation

public enum Hashing {
    public static func sha256Hex(data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    public static func sha256Hex(file url: URL) throws -> String {
        try sha256Hex(data: Data(contentsOf: url))
    }
}
