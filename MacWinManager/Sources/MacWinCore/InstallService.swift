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

        do {
            if let disabledReason = recipe.disabledReason {
                throw MacWinError.unsupportedInstallerMode("Recipe \(recipe.id) is disabled: \(disabledReason)")
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
                    task.progressText = "Installer failed"
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
            task.state = .failed
            task.progressText = "Install failed: \(error.localizedDescription)"
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
