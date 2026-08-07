import Foundation

public enum InstallerSource: Sendable, Equatable {
    case localFile(URL)
    case existingInstallation
}

public struct InstallService {
    public var paths: MacWinPaths
    public var bottleService: BottleService
    public var runner: WineRunner
    public var installHistoryService: InstallHistoryService
    public var fileManager: FileManager

    public init(paths: MacWinPaths = MacWinPaths(), fileManager: FileManager = .default, runner: WineRunner? = nil) {
        self.paths = paths
        self.fileManager = fileManager
        let effectiveRunner = runner ?? WineRunner(paths: paths, fileManager: fileManager)
        self.runner = effectiveRunner
        self.installHistoryService = InstallHistoryService(paths: paths, fileManager: fileManager)
        self.bottleService = BottleService(paths: paths, fileManager: fileManager, runner: effectiveRunner)
    }

    @discardableResult
    public func install(
        recipe: RecipeManifest,
        bottle: BottleManifest,
        engine: EngineManifest,
        installerSource: InstallerSource?
    ) throws -> InstallTask {
        try paths.ensureBaseDirectories(fileManager: fileManager)
        let logPath = paths.logsDirectory.appendingPathComponent("\(bottle.id)-install-\(recipe.id)-\(UUID().uuidString.prefix(8)).log")
        var task = InstallTask(
            id: UUID().uuidString,
            recipeId: recipe.id,
            bottleId: bottle.id,
            state: .running,
            progressText: "Installing \(recipe.name)",
            logPath: logPath.path
        )
        try installHistoryService.save(task)
        let rollbackSnapshot = InstallRollbackSnapshot(
            bottle: bottle,
            driveCURL: paths.bottleDriveCURL(id: bottle.id),
            fileManager: fileManager
        )

        do {
            if let disabledReason = recipe.disabledReason {
                throw MacWinError.unsupportedInstallerMode("Recipe \(recipe.id) is disabled: \(disabledReason)")
            }

            if isAlreadyInstalled(recipe: recipe, bottle: bottle) {
                try appendInstallLog(
                    "duplicateInstall=skipped\nPASS \(recipe.name) is already registered in bottle \(bottle.id)\n",
                    to: logPath
                )
                task.state = .succeeded
                task.progressText = "Already installed \(recipe.name)"
                task.endedAt = Date()
                task.exitCode = 0
                try installHistoryService.save(task)
                return task
            }

            switch recipe.installer.mode {
            case .none:
                break
            case .alreadyInstalled:
                guard existingInstallPath(for: recipe) != nil else {
                    throw MacWinError.installerRequired(recipe.id)
                }
            case .localFile, .download:
                let installerURL = try resolveInstallerURL(recipe: recipe, installerSource: installerSource)
                try validateInstallerCompatibility(installerURL: installerURL, engine: engine)
                let command = recipe.installer.command ?? installerURL.path
                let isManagedInstaller = command.hasPrefix("macwin-")
                let arguments = installerArguments(
                    recipe.installer.arguments,
                    installerURL: installerURL,
                    bottle: bottle,
                    wineAccessiblePaths: !isManagedInstaller
                )
                let exitCode: Int32
                if command == "macwin-extract-archive" {
                    exitCode = try extractArchiveInstaller(
                        installerURL: installerURL,
                        arguments: arguments,
                        bottle: bottle,
                        logPath: logPath
                    )
                } else if command == "macwin-extract-msi-cab" {
                    exitCode = try extractMSICabInstaller(
                        installerURL: installerURL,
                        arguments: arguments,
                        bottle: bottle,
                        logPath: logPath
                    )
                } else {
                    let result = try runner.run(
                        WineRunRequest(
                            exe: command,
                            args: arguments,
                            bottle: bottle,
                            engine: engine,
                            envOverrides: recipe.env,
                            logName: logPath.lastPathComponent
                        ),
                        recipeEnv: recipe.env
                    )
                    exitCode = result.exitCode
                }
                task.exitCode = exitCode
                if exitCode != 0 {
                    if launcherTargetsExist(for: recipe, bottle: bottle) {
                        try appendInstallLog(
                            "installerOutcome=existingInstallAccepted\nPASS existing install accepted after installer exitCode=\(exitCode)\n",
                            to: logPath
                        )
                        break
                    }
                    task.state = .failed
                    task.endedAt = Date()
                    let rollback = rollbackAfterFailure(
                        snapshot: rollbackSnapshot,
                        bottle: bottle,
                        logPath: logPath
                    )
                    task.progressText = rollback > 0
                        ? "Installer failed; rolled back \(rollback) new file(s)"
                        : "Installer failed; rollback complete"
                    try installHistoryService.save(task)
                    return task
                }
            }

            let launchers = recipe.launchers.map {
                let profile = ApplicationCompatibilityProfile.matched(
                    recipeId: recipe.id,
                    launcherId: $0.id,
                    displayName: $0.displayName,
                    exePath: $0.exePath
                )
                let launcher = LauncherManifest(
                    id: $0.id,
                    appId: recipe.id,
                    bottleId: bottle.id,
                    displayName: $0.displayName,
                    exePath: resolvedLauncherPath($0.exePath, recipe: recipe),
                    args: $0.args,
                    iconPath: $0.iconPath,
                    envOverrides: merge(recipe.env, $0.envOverrides),
                    showInHome: $0.showInHome
                )
                return profile?.applied(to: launcher) ?? launcher
            }
            let updatedBottle = try bottleService.addLaunchers(launchers, to: bottle)
            _ = try bottleService.registerDetectedInstalledApps(in: updatedBottle)
            task.state = .succeeded
            task.progressText = "Installed \(recipe.name)"
            task.endedAt = Date()
            task.exitCode = task.exitCode ?? 0
            try installHistoryService.save(task)
            return task
        } catch {
            let rollback = rollbackAfterFailure(
                snapshot: rollbackSnapshot,
                bottle: bottle,
                logPath: logPath
            )
            task.state = .failed
            task.progressText = rollback > 0
                ? "Install failed; rolled back \(rollback) new file(s): \(error.localizedDescription)"
                : "Install failed; rollback complete: \(error.localizedDescription)"
            task.endedAt = Date()
            try? installHistoryService.save(task)
            throw error
        }
    }

    private func resolveInstallerURL(recipe: RecipeManifest, installerSource: InstallerSource?) throws -> URL {
        let installerURL: URL
        switch recipe.installer.mode {
        case .localFile:
            if case .localFile(let url)? = installerSource {
                installerURL = url
            } else if let cachedURL = cachedLocalInstallerURL(for: recipe),
                      fileManager.fileExists(atPath: cachedURL.path) {
                installerURL = cachedURL
            } else {
                throw MacWinError.installerRequired(recipe.id)
            }
        case .download:
            installerURL = try downloadInstaller(for: recipe)
        default:
            throw MacWinError.unsupportedInstallerMode(recipe.installer.mode.rawValue)
        }

        if let expectedHash = recipe.installer.sha256 {
            let actualHash = try Hashing.sha256Hex(file: installerURL)
            guard actualHash.caseInsensitiveCompare(expectedHash) == .orderedSame else {
                throw MacWinError.catalogHashMismatch(recipeId: recipe.id, expected: expectedHash, actual: actualHash)
            }
        }
        return installerURL
    }

    private func cachedLocalInstallerURL(for recipe: RecipeManifest) -> URL? {
        guard let fileName = installerFileName(for: recipe) else { return nil }
        return paths.downloadsDirectory.appendingPathComponent(fileName)
    }

    private func installerFileName(for recipe: RecipeManifest) -> String? {
        if let fileName = recipe.installer.fileName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !fileName.isEmpty {
            return fileName
        }
        guard let urlString = recipe.installer.url,
              let url = URL(string: urlString),
              !url.lastPathComponent.isEmpty else {
            return nil
        }
        return url.lastPathComponent
    }

    public func installerRequiresWin32(_ installerURL: URL) throws -> Bool {
        try WindowsExecutableInspector.architecture(of: installerURL)?.is32Bit == true
    }

    private func validateInstallerCompatibility(installerURL: URL, engine: EngineManifest) throws {
        guard try installerRequiresWin32(installerURL), !engine.supportsWin32 else { return }
        throw MacWinError.unsupportedEngine("32-bit Windows installer requires a WoW64-capable engine: \(installerURL.lastPathComponent)")
    }

    private func downloadInstaller(for recipe: RecipeManifest) throws -> URL {
        try InstallerAssetService(paths: paths, fileManager: fileManager)
            .cacheInstaller(for: recipe)
            .destinationURL
    }

    func installerArguments(
        _ arguments: [String],
        installerURL: URL,
        bottle: BottleManifest,
        wineAccessiblePaths: Bool
    ) -> [String] {
        func resolvedPath(_ url: URL) -> String {
            guard wineAccessiblePaths else { return url.path }
            return "Z:" + url.standardizedFileURL.path.replacingOccurrences(of: "/", with: "\\")
        }
        func resolvedPlaceholder(_ argument: String, token: String, root: URL) -> String? {
            if argument == token {
                return resolvedPath(root)
            }
            let prefix = token + "/"
            guard argument.hasPrefix(prefix) else { return nil }
            return resolvedPath(root.appendingPathComponent(String(argument.dropFirst(prefix.count))))
        }

        return arguments.map { argument in
            if argument == "$installer" { return resolvedPath(installerURL) }
            if let value = resolvedPlaceholder(
                argument,
                token: "$drive_c",
                root: paths.bottleDriveCURL(id: bottle.id)
            ) { return value }
            if let value = resolvedPlaceholder(
                argument,
                token: "$bottle",
                root: paths.bottleDirectory(id: bottle.id)
            ) { return value }
            if let value = resolvedPlaceholder(
                argument,
                token: "$downloads",
                root: paths.downloadsDirectory
            ) { return value }
            return argument
        }
    }

    private func extractMSICabInstaller(
        installerURL: URL,
        arguments: [String],
        bottle: BottleManifest,
        logPath: URL
    ) throws -> Int32 {
        let destination = archiveExtractionDestination(arguments: arguments, bottle: bottle)
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        guard let extractor = archiveExtractorURL() else {
            try appendInstallLog(
                "managedInstaller=extractMSICab\nextractor=missing\nFAIL 7zz extractor not found\n",
                to: logPath
            )
            throw MacWinError.unsupportedInstallerMode("macwin-extract-msi-cab requires 7zz")
        }

        let temporary = fileManager.temporaryDirectory
            .appendingPathComponent("macwin-msi-cab-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: temporary, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: temporary) }
        try appendInstallLog(
            "managedInstaller=extractMSICab\ninstaller=\(installerURL.path)\ndestination=\(destination.path)\nextractor=\(extractor.path)\n",
            to: logPath
        )

        let msiExitCode = try runExtractor(
            extractor,
            arguments: ["x", "-y", "-bd", "-o\(temporary.path)", installerURL.path],
            logPath: logPath
        )
        guard msiExitCode == 0 else {
            try appendInstallLog("FAIL MSI container extraction failed\n", to: logPath)
            return msiExitCode
        }
        let cabURL = try fileManager.contentsOfDirectory(
            at: temporary,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ).first { $0.pathExtension.caseInsensitiveCompare("cab") == .orderedSame }
        guard let cabURL else {
            try appendInstallLog("FAIL MSI package did not expose a CAB payload\n", to: logPath)
            return 1
        }

        let cabExitCode = try runExtractor(
            extractor,
            arguments: ["x", "-y", "-bd", "-o\(destination.path)", cabURL.path],
            logPath: logPath
        )
        try appendInstallLog(
            cabExitCode == 0 ? "PASS MSI CAB payload extracted\n" : "FAIL CAB payload extraction failed\n",
            to: logPath
        )
        return cabExitCode
    }

    private func runExtractor(_ executable: URL, arguments: [String], logPath: URL) throws -> Int32 {
        let extractorLogURL = paths.logsDirectory
            .appendingPathComponent("\(logPath.deletingPathExtension().lastPathComponent)-extractor-\(UUID().uuidString.prefix(8)).log")
        fileManager.createFile(atPath: extractorLogURL.path, contents: nil)
        let extractorLog = try FileHandle(forWritingTo: extractorLogURL)
        defer { try? extractorLog.close() }

        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.standardOutput = extractorLog
        process.standardError = extractorLog
        try process.run()
        process.waitUntilExit()
        try extractorLog.synchronize()
        let data = try Data(contentsOf: extractorLogURL)
        if !data.isEmpty, let text = String(data: data, encoding: .utf8) {
            try appendInstallLog(text + (text.hasSuffix("\n") ? "" : "\n"), to: logPath)
        }
        return process.terminationStatus
    }

    private func extractArchiveInstaller(
        installerURL: URL,
        arguments: [String],
        bottle: BottleManifest,
        logPath: URL
    ) throws -> Int32 {
        let destination = archiveExtractionDestination(arguments: arguments, bottle: bottle)
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        guard let extractor = archiveExtractorURL() else {
            try appendInstallLog(
                "managedInstaller=extractArchive\ninstaller=\(installerURL.path)\ndestination=\(destination.path)\nextractor=missing\nFAIL 7zz extractor not found\n",
                to: logPath
            )
            throw MacWinError.unsupportedInstallerMode("macwin-extract-archive requires 7zz")
        }

        try appendInstallLog(
            "managedInstaller=extractArchive\ninstaller=\(installerURL.path)\ndestination=\(destination.path)\nextractor=\(extractor.path)\n",
            to: logPath
        )

        let extractorLogURL = paths.logsDirectory
            .appendingPathComponent("\(logPath.deletingPathExtension().lastPathComponent)-extractor.log")
        fileManager.createFile(atPath: extractorLogURL.path, contents: nil)
        let extractorLog = try FileHandle(forWritingTo: extractorLogURL)
        defer { try? extractorLog.close() }

        let process = Process()
        process.executableURL = extractor
        process.arguments = ["x", "-y", "-bd", "-o\(destination.path)", installerURL.path]
        process.standardOutput = extractorLog
        process.standardError = extractorLog
        try process.run()
        process.waitUntilExit()

        try extractorLog.synchronize()
        let data = try Data(contentsOf: extractorLogURL)
        if !data.isEmpty, let text = String(data: data, encoding: .utf8) {
            try appendInstallLog(text + (text.hasSuffix("\n") ? "" : "\n"), to: logPath)
        }
        try appendInstallLog(
            "extractExitCode=\(process.terminationStatus)\n\(process.terminationStatus == 0 ? "PASS archive extracted\n" : "FAIL archive extraction failed\n")",
            to: logPath
        )
        return process.terminationStatus
    }

    private func archiveExtractionDestination(arguments: [String], bottle: BottleManifest) -> URL {
        guard let first = arguments.first, !first.isEmpty else {
            return paths.bottleDriveCURL(id: bottle.id)
        }
        return URL(fileURLWithPath: first)
    }

    private func archiveExtractorURL() -> URL? {
        let environmentPath = ProcessInfo.processInfo.environment["MACWIN_7ZZ_PATH"]
        let candidates = [
            environmentPath,
            "/opt/homebrew/bin/7zz",
            "/usr/local/bin/7zz",
            "/usr/bin/7zz"
        ].compactMap { $0 }
        return candidates
            .map(URL.init(fileURLWithPath:))
            .first { fileManager.isExecutableFile(atPath: $0.path) }
    }

    private func existingInstallPath(for recipe: RecipeManifest) -> String? {
        recipe.installer.hints.first { fileManager.fileExists(atPath: $0) }
    }

    private func isAlreadyInstalled(recipe: RecipeManifest, bottle: BottleManifest) -> Bool {
        bottle.installedApps.contains { launcher in
            launcher.appId == recipe.id
                || recipe.launchers.contains { $0.id == launcher.id }
        }
    }

    @discardableResult
    private func rollbackAfterFailure(
        snapshot: InstallRollbackSnapshot,
        bottle: BottleManifest,
        logPath: URL
    ) -> Int {
        let removed = snapshot.removeNewFiles()
        try? bottleService.saveBottle(snapshot.bottle)
        try? appendInstallLog(
            "rollback=best-effort\nrollbackRemovedNewFiles=\(removed)\nrollbackManifestRestored=\((try? bottleService.bottle(id: bottle.id)) != nil)\n",
            to: logPath
        )
        return removed
    }

    private func resolvedLauncherPath(_ path: String, recipe: RecipeManifest) -> String {
        if path == "$existing" {
            return existingInstallPath(for: recipe) ?? path
        }
        return path
    }

    private func launcherTargetsExist(for recipe: RecipeManifest, bottle: BottleManifest) -> Bool {
        !recipe.launchers.isEmpty && recipe.launchers.allSatisfy { launcher in
            let path = resolvedLauncherPath(launcher.exePath, recipe: recipe)
            return launcherFileExists(path, bottle: bottle)
        }
    }

    private func launcherFileExists(_ path: String, bottle: BottleManifest) -> Bool {
        if fileManager.fileExists(atPath: path) {
            return true
        }
        guard let url = winePathURL(path, bottle: bottle) else {
            return false
        }
        return fileManager.fileExists(atPath: url.path)
    }

    private func winePathURL(_ path: String, bottle: BottleManifest) -> URL? {
        let normalized = path.replacingOccurrences(of: "\\", with: "/")
        let lowercased = normalized.lowercased()
        guard lowercased.hasPrefix("c:/") else {
            return nil
        }
        let relative = String(normalized.dropFirst(3))
        return paths.bottleDriveCURL(id: bottle.id).appendingPathComponent(relative)
    }

    private func appendInstallLog(_ text: String, to url: URL) throws {
        let data = Data(text.utf8)
        if !fileManager.fileExists(atPath: url.path) {
            try data.write(to: url)
            return
        }
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: data)
    }

    private func merge(_ first: [String: String], _ second: [String: String]) -> [String: String] {
        var result = first
        for (key, value) in second {
            result[key] = value
        }
        return result
    }

    private func mergeArguments(_ first: [String], _ second: [String]) -> [String] {
        var result = first
        for argument in second where !result.contains(argument) {
            result.append(argument)
        }
        return result
    }
}

private struct InstallRollbackSnapshot {
    let bottle: BottleManifest
    let driveCURL: URL
    let existingPaths: Set<String>
    let fileManager: FileManager

    init(bottle: BottleManifest, driveCURL: URL, fileManager: FileManager) {
        self.bottle = bottle
        self.driveCURL = driveCURL.standardizedFileURL
        self.existingPaths = Self.paths(in: driveCURL, fileManager: fileManager)
        self.fileManager = fileManager
    }

    func removeNewFiles() -> Int {
        let currentPaths = Self.paths(in: driveCURL, fileManager: fileManager)
        let newPaths = currentPaths.subtracting(existingPaths).sorted { lhs, rhs in
            let leftDepth = lhs.split(separator: "/").count
            let rightDepth = rhs.split(separator: "/").count
            if leftDepth != rightDepth { return leftDepth > rightDepth }
            return lhs > rhs
        }
        var removed = 0
        let rootPath = driveCURL.path
        for relativePath in newPaths {
            let candidate = driveCURL.appendingPathComponent(relativePath).standardizedFileURL
            guard candidate.path.hasPrefix(rootPath + "/"),
                  fileManager.fileExists(atPath: candidate.path) else {
                continue
            }
            do {
                try fileManager.removeItem(at: candidate)
                removed += 1
            } catch {
                continue
            }
        }
        return removed
    }

    private static func paths(in root: URL, fileManager: FileManager) -> Set<String> {
        guard fileManager.fileExists(atPath: root.path),
              let enumerator = fileManager.enumerator(
                  at: root,
                  includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
                  options: [.skipsHiddenFiles]
              ) else {
            return []
        }

        let normalizedRoot = root.standardizedFileURL.path
        var result = Set<String>()
        for case let url as URL in enumerator {
            let path = url.standardizedFileURL.path
            guard path.hasPrefix(normalizedRoot + "/") else { continue }
            result.insert(String(path.dropFirst(normalizedRoot.count + 1)))
        }
        return result
    }
}
