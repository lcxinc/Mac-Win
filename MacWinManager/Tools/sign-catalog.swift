#!/usr/bin/env swift

import CryptoKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("usage: sign-catalog.swift <catalog-directory> <private-key-file>\n", stderr)
    exit(2)
}

let fileManager = FileManager.default
let catalogURL = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let keyURL = URL(fileURLWithPath: CommandLine.arguments[2])
let indexURL = catalogURL.appendingPathComponent("catalog.index.json")
let signatureURL = catalogURL.appendingPathComponent("catalog.signature.json")
let recipesURL = catalogURL.appendingPathComponent("recipes", isDirectory: true)

let keyText = try String(contentsOf: keyURL, encoding: .utf8)
    .trimmingCharacters(in: .whitespacesAndNewlines)
guard let keyData = Data(base64Encoded: keyText) else {
    throw NSError(domain: "MacWinCatalogSigner", code: 1, userInfo: [
        NSLocalizedDescriptionKey: "Private key is not valid Base64."
    ])
}
let privateKey = try P256.Signing.PrivateKey(rawRepresentation: keyData)

var generatedAt = "2026-06-18T00:00:00Z"
var expiresAt = "2027-06-18T00:00:00Z"
if let existingData = try? Data(contentsOf: indexURL),
   let existing = try? JSONSerialization.jsonObject(with: existingData) as? [String: Any] {
    generatedAt = existing["generatedAt"] as? String ?? generatedAt
    expiresAt = existing["expiresAt"] as? String ?? expiresAt
}

let recipeURLs = try fileManager.contentsOfDirectory(
    at: recipesURL,
    includingPropertiesForKeys: nil,
    options: [.skipsHiddenFiles]
).filter { $0.pathExtension.lowercased() == "json" }

let entries: [[String: String]] = try recipeURLs.map { recipeURL in
    let data = try Data(contentsOf: recipeURL)
    guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let id = object["id"] as? String,
          let name = object["name"] as? String else {
        throw NSError(domain: "MacWinCatalogSigner", code: 2, userInfo: [
            NSLocalizedDescriptionKey: "Recipe is missing id or name: \(recipeURL.path)"
        ])
    }
    return [
        "file": "recipes/\(recipeURL.lastPathComponent)",
        "id": id,
        "name": name,
        "sha256": SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    ]
}.sorted { lhs, rhs in
    (lhs["name"] ?? "").localizedCaseInsensitiveCompare(rhs["name"] ?? "") == .orderedAscending
}

let indexObject: [String: Any] = [
    "expiresAt": expiresAt,
    "generatedAt": generatedAt,
    "recipes": entries
]
let indexData = try JSONSerialization.data(
    withJSONObject: indexObject,
    options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
)
try (indexData + Data([0x0a])).write(to: indexURL, options: [.atomic])

let signedIndexData = try Data(contentsOf: indexURL)
let signature = try privateKey.signature(for: signedIndexData)
let signatureObject: [String: String] = [
    "algorithm": "p256-sha256-der",
    "keyId": "macwin-dev-2026-07",
    "signatureBase64": signature.derRepresentation.base64EncodedString()
]
let signatureData = try JSONSerialization.data(
    withJSONObject: signatureObject,
    options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
)
try (signatureData + Data([0x0a])).write(to: signatureURL, options: [.atomic])

print("recipes=\(entries.count)")
print("publicKey=\(privateKey.publicKey.rawRepresentation.base64EncodedString())")
print(indexURL.path)
print(signatureURL.path)
