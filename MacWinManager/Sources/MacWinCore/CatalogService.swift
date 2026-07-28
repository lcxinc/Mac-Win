import CryptoKit
import Foundation

public struct CatalogSource {
    public var root: URL
    public var indexFileName: String
    public var signatureFileName: String

    public init(root: URL, indexFileName: String = "catalog.index.json", signatureFileName: String = "catalog.signature.json") {
        self.root = root
        self.indexFileName = indexFileName
        self.signatureFileName = signatureFileName
    }

    public var indexURL: URL { root.appendingPathComponent(indexFileName) }
    public var signatureURL: URL { root.appendingPathComponent(signatureFileName) }
    public func recipeURL(file: String) -> URL { root.appendingPathComponent(file) }
}

public struct CatalogService {
    public var source: CatalogSource
    public var trustedPublicKeys: [String: P256.Signing.PublicKey]
    public var store: JSONStore

    public init(source: CatalogSource, trustedPublicKeys: [String: P256.Signing.PublicKey], store: JSONStore = JSONStore()) {
        self.source = source
        self.trustedPublicKeys = trustedPublicKeys
        self.store = store
    }

    public func refresh(now: Date = Date()) throws -> CatalogSnapshot {
        let indexData = try Data(contentsOf: source.indexURL)
        let signature = try store.decoder.decode(CatalogSignature.self, from: Data(contentsOf: source.signatureURL))
        try verify(indexData: indexData, signature: signature)

        let index = try store.decoder.decode(CatalogIndex.self, from: indexData)
        var recipes: [RecipeManifest] = []
        for item in index.recipes {
            let recipeURL = source.recipeURL(file: item.file)
            let recipeData = try Data(contentsOf: recipeURL)
            let actualHash = Hashing.sha256Hex(data: recipeData)
            guard actualHash.caseInsensitiveCompare(item.sha256) == .orderedSame else {
                throw MacWinError.catalogHashMismatch(recipeId: item.id, expected: item.sha256, actual: actualHash)
            }
            recipes.append(try store.decoder.decode(RecipeManifest.self, from: recipeData))
        }

        return CatalogSnapshot(index: index, recipes: recipes, isExpired: index.expiresAt < now)
    }

    private func verify(indexData: Data, signature: CatalogSignature) throws {
        guard signature.algorithm == "p256-sha256-der",
              let publicKey = trustedPublicKeys[signature.keyId],
              let signatureData = Data(base64Encoded: signature.signatureBase64),
              let ecdsaSignature = try? P256.Signing.ECDSASignature(derRepresentation: signatureData),
              publicKey.isValidSignature(ecdsaSignature, for: indexData)
        else {
            throw MacWinError.catalogSignatureInvalid
        }
    }
}

public struct CatalogCacheManifest: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var cachedAt: Date
    public var sourcePath: String
    public var cachePath: String
    public var indexPath: String
    public var signaturePath: String
    public var recipeCount: Int
    public var recipeIds: [String]
    public var recipePaths: [String]
    public var indexSha256: String
    public var signatureSha256: String
    public var recipeSha256ById: [String: String]

    public init(
        schemaVersion: Int = 1,
        cachedAt: Date,
        sourcePath: String,
        cachePath: String,
        indexPath: String,
        signaturePath: String,
        recipeCount: Int,
        recipeIds: [String],
        recipePaths: [String],
        indexSha256: String,
        signatureSha256: String,
        recipeSha256ById: [String: String]
    ) {
        self.schemaVersion = schemaVersion
        self.cachedAt = cachedAt
        self.sourcePath = sourcePath
        self.cachePath = cachePath
        self.indexPath = indexPath
        self.signaturePath = signaturePath
        self.recipeCount = recipeCount
        self.recipeIds = recipeIds
        self.recipePaths = recipePaths
        self.indexSha256 = indexSha256
        self.signatureSha256 = signatureSha256
        self.recipeSha256ById = recipeSha256ById
    }
}

public struct CatalogCacheService {
    public var paths: MacWinPaths
    public var fileManager: FileManager
    public var store: JSONStore

    public init(
        paths: MacWinPaths = MacWinPaths(),
        fileManager: FileManager = .default,
        store: JSONStore = JSONStore()
    ) {
        self.paths = paths
        self.fileManager = fileManager
        self.store = store
    }

    @discardableResult
    public func syncVerifiedCatalog(
        from source: CatalogSource,
        snapshot: CatalogSnapshot,
        cachedAt: Date = Date()
    ) throws -> CatalogCacheManifest {
        try paths.ensureBaseDirectories(fileManager: fileManager)
        let cacheURL = paths.catalogDirectory
        if source.root.standardizedFileURL.path == cacheURL.standardizedFileURL.path {
            return try writeManifest(
                source: source,
                snapshot: snapshot,
                cacheURL: cacheURL,
                cachedAt: cachedAt
            )
        }

        let parent = cacheURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
        let tempURL = parent.appendingPathComponent(".Catalog.tmp-\(UUID().uuidString)", isDirectory: true)
        if fileManager.fileExists(atPath: tempURL.path) {
            try fileManager.removeItem(at: tempURL)
        }
        try fileManager.createDirectory(at: tempURL, withIntermediateDirectories: true)

        try copy(source.indexURL, to: tempURL.appendingPathComponent(source.indexFileName))
        try copy(source.signatureURL, to: tempURL.appendingPathComponent(source.signatureFileName))
        for item in snapshot.index.recipes {
            let destination = tempURL.appendingPathComponent(item.file)
            try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            try copy(source.recipeURL(file: item.file), to: destination)
        }

        if fileManager.fileExists(atPath: cacheURL.path) {
            try fileManager.removeItem(at: cacheURL)
        }
        try fileManager.moveItem(at: tempURL, to: cacheURL)

        return try writeManifest(
            source: source,
            snapshot: snapshot,
            cacheURL: cacheURL,
            cachedAt: cachedAt
        )
    }

    private func writeManifest(
        source: CatalogSource,
        snapshot: CatalogSnapshot,
        cacheURL: URL,
        cachedAt: Date
    ) throws -> CatalogCacheManifest {
        let cachedSource = CatalogSource(
            root: cacheURL,
            indexFileName: source.indexFileName,
            signatureFileName: source.signatureFileName
        )
        let recipePaths = snapshot.index.recipes.map { cachedSource.recipeURL(file: $0.file).path }
        let recipeSha256ById = Dictionary(uniqueKeysWithValues: snapshot.index.recipes.map { ($0.id, $0.sha256) })
        let manifest = CatalogCacheManifest(
            cachedAt: cachedAt,
            sourcePath: source.root.path,
            cachePath: cacheURL.path,
            indexPath: cachedSource.indexURL.path,
            signaturePath: cachedSource.signatureURL.path,
            recipeCount: snapshot.index.recipes.count,
            recipeIds: snapshot.index.recipes.map(\.id),
            recipePaths: recipePaths,
            indexSha256: try Hashing.sha256Hex(file: cachedSource.indexURL),
            signatureSha256: try Hashing.sha256Hex(file: cachedSource.signatureURL),
            recipeSha256ById: recipeSha256ById
        )
        try store.save(manifest, to: cacheURL.appendingPathComponent("catalog-cache.json"))
        return manifest
    }

    private func copy(_ sourceURL: URL, to destinationURL: URL) throws {
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
    }
}
