import Foundation

public enum SoftwareAcquisitionSource: String, Codable, Equatable, Sendable {
    case collectionRecipe
    case softwareSample
    case missingRecipe
}

public enum SoftwareAcquisitionState: String, Codable, Equatable, Sendable {
    case cached
    case downloadable
    case missingLocalInstaller
    case missingRecipe
    case hashMismatch
    case ready
    case manual
}

public struct SoftwareAcquisitionEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var source: SoftwareAcquisitionSource
    public var state: SoftwareAcquisitionState
    public var name: String
    public var recipeId: String?
    public var sampleId: String?
    public var fileNames: [String]
    public var sourceURL: String?
    public var expectedSha256: String?
    public var cachedPaths: [String]
    public var action: String
    public var recommendedProbeIds: [String]

    public init(
        id: String,
        source: SoftwareAcquisitionSource,
        state: SoftwareAcquisitionState,
        name: String,
        recipeId: String? = nil,
        sampleId: String? = nil,
        fileNames: [String] = [],
        sourceURL: String? = nil,
        expectedSha256: String? = nil,
        cachedPaths: [String] = [],
        action: String,
        recommendedProbeIds: [String] = []
    ) {
        self.id = id
        self.source = source
        self.state = state
        self.name = name
        self.recipeId = recipeId
        self.sampleId = sampleId
        self.fileNames = fileNames
        self.sourceURL = sourceURL
        self.expectedSha256 = expectedSha256
        self.cachedPaths = cachedPaths
        self.action = action
        self.recommendedProbeIds = recommendedProbeIds
    }
}

public struct SoftwareAcquisitionReport: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var rootPath: String
    public var downloadsPath: String
    public var entryCount: Int
    public var cachedCount: Int
    public var downloadableCount: Int
    public var missingLocalInstallerCount: Int
    public var missingRecipeCount: Int
    public var hashMismatchCount: Int
    public var manualCount: Int
    public var actionCount: Int
    public var entries: [SoftwareAcquisitionEntry]

    public init(generatedAt: Date, rootPath: String, downloadsPath: String, entries: [SoftwareAcquisitionEntry]) {
        self.generatedAt = generatedAt
        self.rootPath = rootPath
        self.downloadsPath = downloadsPath
        self.entryCount = entries.count
        self.cachedCount = entries.filter { $0.state == .cached }.count
        self.downloadableCount = entries.filter { $0.state == .downloadable }.count
        self.missingLocalInstallerCount = entries.filter { $0.state == .missingLocalInstaller }.count
        self.missingRecipeCount = entries.filter { $0.state == .missingRecipe }.count
        self.hashMismatchCount = entries.filter { $0.state == .hashMismatch }.count
        self.manualCount = entries.filter { $0.state == .manual }.count
        self.actionCount = entries.filter { $0.state != .cached && $0.state != .ready }.count
        self.entries = entries
    }

    public static func csv(report: SoftwareAcquisitionReport) -> String {
        var rows: [[String]] = [[
            "id",
            "source",
            "state",
            "name",
            "recipe_id",
            "sample_id",
            "file_names",
            "source_url",
            "expected_sha256",
            "cached_paths",
            "action",
            "recommended_probe_ids"
        ]]
        for entry in report.entries {
            rows.append([
                entry.id,
                entry.source.rawValue,
                entry.state.rawValue,
                entry.name,
                entry.recipeId ?? "",
                entry.sampleId ?? "",
                entry.fileNames.joined(separator: ";"),
                entry.sourceURL ?? "",
                entry.expectedSha256 ?? "",
                entry.cachedPaths.joined(separator: ";"),
                entry.action,
                entry.recommendedProbeIds.joined(separator: ";")
            ])
        }
        return rows.map { $0.map(csvEscaped).joined(separator: ",") }.joined(separator: "\n") + "\n"
    }

    public static func markdown(report: SoftwareAcquisitionReport) -> String {
        let formatter = ISO8601DateFormatter()
        var lines = [
            "# MacWin Software Acquisition",
            "",
            "- Generated: \(formatter.string(from: report.generatedAt))",
            "- Root: `\(markdownEscaped(report.rootPath))`",
            "- Downloads: `\(markdownEscaped(report.downloadsPath))`",
            "- Entries: \(report.entryCount)",
            "- Cached: \(report.cachedCount)",
            "- Downloadable: \(report.downloadableCount)",
            "- Missing local installers: \(report.missingLocalInstallerCount)",
            "- Missing recipes: \(report.missingRecipeCount)",
            "- Hash mismatches: \(report.hashMismatchCount)",
            "- Manual: \(report.manualCount)",
            "- Actions: \(report.actionCount)",
            "",
            "## Entries",
            ""
        ]
        if report.entries.isEmpty {
            lines.append("No software acquisition entries are required.")
        } else {
            for entry in report.entries {
                lines.append("### \(markdownEscaped(entry.name))")
                lines.append("")
                lines.append("- Id: `\(markdownEscaped(entry.id))`")
                lines.append("- Source: `\(entry.source.rawValue)`")
                lines.append("- State: `\(entry.state.rawValue)`")
                if let recipeId = entry.recipeId {
                    lines.append("- Recipe: `\(markdownEscaped(recipeId))`")
                }
                if let sampleId = entry.sampleId {
                    lines.append("- Sample: `\(markdownEscaped(sampleId))`")
                }
                if !entry.fileNames.isEmpty {
                    lines.append("- Files: \(entry.fileNames.map { "`\(markdownEscaped($0))`" }.joined(separator: ", "))")
                }
                if let sourceURL = entry.sourceURL {
                    lines.append("- URL: `\(markdownEscaped(sourceURL))`")
                }
                if !entry.cachedPaths.isEmpty {
                    lines.append("- Cached paths: \(entry.cachedPaths.map { "`\(markdownEscaped($0))`" }.joined(separator: ", "))")
                }
                lines.append("- Action: \(markdownEscaped(entry.action))")
                if !entry.recommendedProbeIds.isEmpty {
                    lines.append("- Probes: \(entry.recommendedProbeIds.map { "`\(markdownEscaped($0))`" }.joined(separator: ", "))")
                }
                lines.append("")
            }
        }
        return lines.joined(separator: "\n")
    }

    public static func shellScript(report: SoftwareAcquisitionReport) -> String {
        var lines = [
            "#!/usr/bin/env bash",
            "set -euo pipefail",
            "",
            "DOWNLOADS_DIR=\(shellQuoted(report.downloadsPath))",
            "mkdir -p \"$DOWNLOADS_DIR\"",
            "",
            "download_one() {",
            "  local id=\"$1\"",
            "  local url=\"$2\"",
            "  local file_name=\"$3\"",
            "  local expected_sha=\"${4:-}\"",
            "  local dest=\"$DOWNLOADS_DIR/$file_name\"",
            "  if [[ -f \"$dest\" ]]; then",
            "    echo \"READY $id: $dest\"",
            "    return 0",
            "  fi",
            "  echo \"DOWNLOAD $id: $url\"",
            "  curl -L --fail --retry 3 --output \"$dest.tmp\" \"$url\"",
            "  if [[ -n \"$expected_sha\" ]]; then",
            "    echo \"$expected_sha  $dest.tmp\" | shasum -a 256 -c -",
            "  fi",
            "  mv \"$dest.tmp\" \"$dest\"",
            "}",
            "",
            "echo \(shellQuoted("MacWin software acquisition plan"))",
            "echo \(shellQuoted("Entries: \(report.entryCount), downloads: \(report.downloadableCount), local installers: \(report.missingLocalInstallerCount), missing recipes: \(report.missingRecipeCount), hash mismatches: \(report.hashMismatchCount)"))"
        ]
        if report.entries.isEmpty {
            lines.append("echo 'No software acquisition entries are required.'")
        } else {
            for entry in report.entries {
                switch entry.state {
                case .downloadable:
                    lines.append("download_one \(shellQuoted(entry.id)) \(shellQuoted(entry.sourceURL ?? "")) \(shellQuoted(entry.fileNames.first ?? "")) \(shellQuoted(entry.expectedSha256 ?? ""))")
                case .hashMismatch:
                    lines.append("echo \(shellQuoted("HASH_MISMATCH \(entry.id): remove cached file and redownload \(entry.fileNames.first ?? entry.name)")) >&2")
                case .missingLocalInstaller:
                    let files = entry.fileNames.isEmpty ? "an installer" : entry.fileNames.joined(separator: ", ")
                    lines.append("echo \(shellQuoted("LOCAL_INSTALLER_REQUIRED \(entry.id): place \(files) in \(report.downloadsPath)"))")
                case .missingRecipe:
                    lines.append("echo \(shellQuoted("MISSING_RECIPE \(entry.id): add a signed recipe before installing")) >&2")
                case .manual:
                    lines.append("echo \(shellQuoted("MANUAL \(entry.id): \(entry.action)"))")
                case .cached, .ready:
                    lines.append("echo \(shellQuoted("READY \(entry.id): \(entry.action)"))")
                }
            }
        }
        lines.append("")
        return lines.joined(separator: "\n")
    }

    private static func csvEscaped(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    private static func markdownEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
    }

    private static func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}

public struct SoftwareAcquisitionService {
    public init() {}

    public func report(
        collection: SoftwareCollectionReport,
        samplePreparation: SoftwareSamplePreparationReport,
        generatedAt: Date = Date()
    ) -> SoftwareAcquisitionReport {
        Self.report(collection: collection, samplePreparation: samplePreparation, generatedAt: generatedAt)
    }

    public static func report(
        collection: SoftwareCollectionReport,
        samplePreparation: SoftwareSamplePreparationReport,
        generatedAt: Date = Date()
    ) -> SoftwareAcquisitionReport {
        let downloadsPath = samplePreparation.downloadsPath.isEmpty
            ? URL(fileURLWithPath: collection.rootPath).appendingPathComponent("Downloads", isDirectory: true).path
            : samplePreparation.downloadsPath
        var entries: [SoftwareAcquisitionEntry] = []

        for recipeId in collection.missingRecipeIds {
            entries.append(
                SoftwareAcquisitionEntry(
                    id: "missing-recipe-\(recipeId)",
                    source: .missingRecipe,
                    state: .missingRecipe,
                    name: recipeId,
                    recipeId: recipeId,
                    action: "Add a signed catalog recipe before this software can be acquired."
                )
            )
        }

        for entry in collection.entries {
            let state: SoftwareAcquisitionState
            let action: String
            switch entry.installerMode {
            case .download:
                if entry.installerHashStatus == .mismatch {
                    state = .hashMismatch
                    action = "Remove the cached installer and download it again with SHA-256 verification."
                } else if entry.cachedInstallerExists {
                    state = .cached
                    action = "Use the cached installer from Downloads."
                } else {
                    state = .downloadable
                    action = "Download the installer into the MacWin Downloads cache."
                }
            case .localFile:
                state = .missingLocalInstaller
                action = "Place the local installer in the MacWin Downloads cache or choose it during install."
            case .alreadyInstalled, .none:
                state = .ready
                action = "No installer download is required."
            }

            entries.append(
                SoftwareAcquisitionEntry(
                    id: "collection-\(entry.recipeId)",
                    source: .collectionRecipe,
                    state: state,
                    name: entry.name,
                    recipeId: entry.recipeId,
                    fileNames: entry.installerFileName.map { [$0] } ?? [],
                    sourceURL: entry.installerSourceURL,
                    expectedSha256: entry.expectedSha256,
                    cachedPaths: entry.cachedInstallerPath.map { [$0] } ?? [],
                    action: action,
                    recommendedProbeIds: entry.recommendedProbeIds
                )
            )
        }

        for sample in samplePreparation.entries {
            let state: SoftwareAcquisitionState
            switch sample.status {
            case .ready:
                state = sample.cachedInstallerPaths.isEmpty ? .ready : .cached
            case .missingInstaller:
                state = .missingLocalInstaller
            case .missingRecipe:
                state = .missingRecipe
            case .manual:
                state = .manual
            }
            entries.append(
                SoftwareAcquisitionEntry(
                    id: "sample-\(sample.sampleId)",
                    source: .softwareSample,
                    state: state,
                    name: sample.name,
                    recipeId: sample.catalogRecipeId,
                    sampleId: sample.sampleId,
                    fileNames: sample.installerFileNames,
                    cachedPaths: sample.cachedInstallerPaths,
                    action: sample.requiredAction,
                    recommendedProbeIds: sample.recommendedProbeIds
                )
            )
        }

        let sorted = entries.sorted { lhs, rhs in
            let lhsRank = stateRank(lhs.state)
            let rhsRank = stateRank(rhs.state)
            if lhsRank != rhsRank { return lhsRank < rhsRank }
            if lhs.source.rawValue != rhs.source.rawValue { return lhs.source.rawValue < rhs.source.rawValue }
            return lhs.id < rhs.id
        }
        return SoftwareAcquisitionReport(
            generatedAt: generatedAt,
            rootPath: collection.rootPath,
            downloadsPath: downloadsPath,
            entries: sorted
        )
    }

    private static func stateRank(_ state: SoftwareAcquisitionState) -> Int {
        switch state {
        case .hashMismatch: 0
        case .missingRecipe: 1
        case .missingLocalInstaller: 2
        case .downloadable: 3
        case .manual: 4
        case .cached: 5
        case .ready: 6
        }
    }
}
