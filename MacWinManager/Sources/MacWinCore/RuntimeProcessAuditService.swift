import Darwin
import Foundation

public struct RuntimeProcessAuditReport: Codable, Equatable, Sendable {
    public var observedProcessCount: Int
    public var auditedProcessCount: Int
    public var staleRenderingProcessCount: Int
    public var entries: [RuntimeProcessEntry]
    public var findings: [RuntimeProcessFinding]

    public var stoppableProcessIdentifiers: [Int32] {
        entries.filter { !$0.isUninterruptible }.map(\.processIdentifier).sorted()
    }

    public var uninterruptibleProcessIdentifiers: [Int32] {
        entries.filter(\.isUninterruptible).map(\.processIdentifier).sorted()
    }

    public var detachedWineSystemEntries: [RuntimeProcessEntry] {
        safelyDetachedWineSystemEntries(from: entries)
    }

    public var detachedWinePrefixPaths: [String] {
        Array(Set(detachedWineSystemEntries.compactMap(\.winePrefixPath))).sorted()
    }

    public func entries(inWinePrefix prefixPath: String) -> [RuntimeProcessEntry] {
        let normalizedPrefix = URL(fileURLWithPath: prefixPath).standardizedFileURL.path
        return entries.filter {
            guard let entryPrefix = $0.winePrefixPath else { return false }
            return URL(fileURLWithPath: entryPrefix).standardizedFileURL.path == normalizedPrefix
        }
    }

    public init(
        observedProcessCount: Int,
        auditedProcessCount: Int,
        staleRenderingProcessCount: Int,
        entries: [RuntimeProcessEntry],
        findings: [RuntimeProcessFinding]
    ) {
        self.observedProcessCount = observedProcessCount
        self.auditedProcessCount = auditedProcessCount
        self.staleRenderingProcessCount = staleRenderingProcessCount
        self.entries = entries
        self.findings = findings
    }

    public static func csv(report: RuntimeProcessAuditReport?) -> String {
        var rows: [[String]] = [[
            "row_type",
            "id",
            "severity",
            "pid",
            "parent_pid",
            "process_state",
            "kind",
            "executable_name",
            "wine_prefix",
            "stale_flags",
            "affected_pids",
            "title",
            "detail",
            "command_preview"
        ]]

        for finding in report?.findings ?? [] {
            rows.append([
                "finding",
                finding.id,
                finding.severity,
                "",
                "",
                "",
                "",
                "",
                "",
                finding.flags.joined(separator: ";"),
                finding.affectedProcessIdentifiers.map(String.init).joined(separator: ";"),
                finding.title,
                finding.detail,
                ""
            ])
        }

        for entry in report?.entries ?? [] {
            rows.append([
                "process",
                "",
                entry.staleRenderingFlags.isEmpty ? "info" : "warning",
                String(entry.processIdentifier),
                entry.parentProcessIdentifier.map(String.init) ?? "",
                entry.processState ?? "",
                entry.kind.rawValue,
                entry.executableName,
                entry.winePrefixPath.map(sanitizedPathPreview) ?? "",
                entry.staleRenderingFlags.joined(separator: ";"),
                "",
                "",
                "",
                entry.commandPreview
            ])
        }

        return rows
            .map { $0.map(csvEscaped).joined(separator: ",") }
            .joined(separator: "\n")
    }

    private static func csvEscaped(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    private static func sanitizedPathPreview(_ path: String) -> String {
        path.replacingOccurrences(
            of: #"/Users/[^/\s]+"#,
            with: #"/Users/<user>"#,
            options: .regularExpression
        )
    }
}

public struct RuntimeProcessEntry: Codable, Equatable, Sendable {
    public var processIdentifier: Int32
    public var parentProcessIdentifier: Int32?
    public var processState: String?
    public var kind: RuntimeProcessKind
    public var executableName: String
    public var workingDirectory: String?
    public var winePrefixPath: String?
    public var staleRenderingFlags: [String]
    public var commandPreview: String

    public init(
        processIdentifier: Int32,
        parentProcessIdentifier: Int32? = nil,
        processState: String? = nil,
        kind: RuntimeProcessKind,
        executableName: String,
        workingDirectory: String? = nil,
        winePrefixPath: String? = nil,
        staleRenderingFlags: [String],
        commandPreview: String
    ) {
        self.processIdentifier = processIdentifier
        self.parentProcessIdentifier = parentProcessIdentifier
        self.processState = processState
        self.kind = kind
        self.executableName = executableName
        self.workingDirectory = workingDirectory
        self.winePrefixPath = winePrefixPath
        self.staleRenderingFlags = staleRenderingFlags
        self.commandPreview = commandPreview
    }

    public var isUninterruptible: Bool {
        guard let first = processState?.uppercased().first else { return false }
        return first == "U" || first == "D"
    }

    public var isWineVirtualDesktop: Bool {
        let command = commandPreview.lowercased()
        return command.contains("explorer.exe") && command.contains("/desktop")
    }

    public var isWineDeviceService: Bool {
        commandPreview.lowercased().contains("winedevice.exe")
    }

    public var isDetachedWineSystemProcess: Bool {
        guard parentProcessIdentifier == 1, winePrefixPath != nil else { return false }
        return Self.detachedWineSystemExecutableNames.contains(executableName.lowercased())
    }

    public var winePrefixDisplayName: String? {
        guard let winePrefixPath else { return nil }
        return URL(fileURLWithPath: winePrefixPath).lastPathComponent
    }

    private static let detachedWineSystemExecutableNames: Set<String> = [
        "conhost.exe",
        "explorer.exe",
        "plugplay.exe",
        "rpcss.exe",
        "services.exe",
        "svchost.exe",
        "winedevice.exe"
    ]
}

public struct RuntimeProcessFinding: Codable, Equatable, Sendable {
    public var id: String
    public var severity: String
    public var title: String
    public var detail: String
    public var affectedProcessIdentifiers: [Int32]
    public var flags: [String]
}

public enum RuntimeProcessKind: String, Codable, Equatable, Sendable {
    case hoYoPlay
    case steam
    case lenovoAppStore
    case windowsExecutable
    case wineHost
}

public struct RuntimeProcessTerminationReport: Codable, Equatable, Sendable {
    public var requestedCount: Int
    public var stoppedProcessIdentifiers: [Int32]
    public var failedProcessIdentifiers: [Int32]

    public init(
        requestedCount: Int,
        stoppedProcessIdentifiers: [Int32],
        failedProcessIdentifiers: [Int32]
    ) {
        self.requestedCount = requestedCount
        self.stoppedProcessIdentifiers = stoppedProcessIdentifiers
        self.failedProcessIdentifiers = failedProcessIdentifiers
    }

    public var stoppedCount: Int { stoppedProcessIdentifiers.count }
    public var failedCount: Int { failedProcessIdentifiers.count }
}

public struct RuntimeProcessTerminator: Sendable {
    public var terminateProcess: @Sendable (Int32) -> Bool
    private var usesDefaultTermination: Bool

    public init(terminateProcess: (@Sendable (Int32) -> Bool)? = nil) {
        self.terminateProcess = terminateProcess ?? Self.defaultTerminateProcess
        self.usesDefaultTermination = terminateProcess == nil
    }

    public func terminate(entries: [RuntimeProcessEntry]) -> RuntimeProcessTerminationReport {
        let processIdentifiers = Array(Set(entries.map(\.processIdentifier))).sorted()
        if usesDefaultTermination, processIdentifiers.count > 1 {
            return Self.defaultTerminateProcesses(processIdentifiers)
        }

        var stopped: [Int32] = []
        var failed: [Int32] = []
        for pid in processIdentifiers {
            if terminateProcess(pid) {
                stopped.append(pid)
            } else {
                failed.append(pid)
            }
        }
        return RuntimeProcessTerminationReport(
            requestedCount: processIdentifiers.count,
            stoppedProcessIdentifiers: stopped,
            failedProcessIdentifiers: failed
        )
    }

    public func terminateWineVirtualDesktopProcesses(in report: RuntimeProcessAuditReport) -> RuntimeProcessTerminationReport {
        terminate(entries: report.entries.filter { $0.isWineVirtualDesktop || $0.isWineDeviceService })
    }

    public func terminateAllRuntimeProcesses(in report: RuntimeProcessAuditReport) -> RuntimeProcessTerminationReport {
        terminate(entries: report.entries.filter { !$0.isUninterruptible })
    }

    public func terminateDetachedWineSystemProcesses(in report: RuntimeProcessAuditReport) -> RuntimeProcessTerminationReport {
        terminate(entries: report.detachedWineSystemEntries.filter { !$0.isUninterruptible })
    }

    public func terminateDetachedWineSystemProcesses(
        in report: RuntimeProcessAuditReport,
        winePrefixPath: String
    ) -> RuntimeProcessTerminationReport {
        let normalizedPrefix = URL(fileURLWithPath: winePrefixPath).standardizedFileURL.path
        return terminate(entries: report.detachedWineSystemEntries.filter {
            guard let prefixPath = $0.winePrefixPath else { return false }
            return URL(fileURLWithPath: prefixPath).standardizedFileURL.path == normalizedPrefix
                && !$0.isUninterruptible
        })
    }

    private static func defaultTerminateProcess(_ pid: Int32) -> Bool {
        if kill(pid, SIGTERM) == 0 || errno == ESRCH {
            waitForProcessExit(pid, timeout: 1.5)
            if !isProcessAlive(pid) {
                return true
            }
            return kill(pid, SIGKILL) == 0 || errno == ESRCH
        }
        return false
    }

    private static func defaultTerminateProcesses(
        _ processIdentifiers: [Int32]
    ) -> RuntimeProcessTerminationReport {
        var pending: Set<Int32> = []
        var stopped: Set<Int32> = []
        var failed: Set<Int32> = []

        for pid in processIdentifiers {
            if kill(pid, SIGTERM) == 0 {
                pending.insert(pid)
            } else if errno == ESRCH {
                stopped.insert(pid)
            } else {
                failed.insert(pid)
            }
        }

        let deadline = Date().addingTimeInterval(1.5)
        while !pending.isEmpty, Date() < deadline {
            for pid in Array(pending) where !isProcessAlive(pid) {
                pending.remove(pid)
                stopped.insert(pid)
            }
            if !pending.isEmpty {
                Thread.sleep(forTimeInterval: 0.1)
            }
        }

        for pid in pending {
            if kill(pid, SIGKILL) == 0 || errno == ESRCH {
                stopped.insert(pid)
            } else {
                failed.insert(pid)
            }
        }

        return RuntimeProcessTerminationReport(
            requestedCount: processIdentifiers.count,
            stoppedProcessIdentifiers: stopped.sorted(),
            failedProcessIdentifiers: failed.sorted()
        )
    }

    private static func waitForProcessExit(_ pid: Int32, timeout: TimeInterval) {
        let deadline = Date().addingTimeInterval(timeout)
        while isProcessAlive(pid), Date() < deadline {
            Thread.sleep(forTimeInterval: 0.1)
        }
    }

    private static func isProcessAlive(_ pid: Int32) -> Bool {
        kill(pid, 0) == 0 || errno == EPERM
    }
}

public struct RuntimeProcessAuditService: Sendable {
    public var processListProvider: @Sendable () -> String
    public var processWorkingDirectoryProvider: @Sendable (Int32) -> String?

    public init(
        processListProvider: (@Sendable () -> String)? = nil,
        processWorkingDirectoryProvider: (@Sendable (Int32) -> String?)? = nil
    ) {
        self.processListProvider = processListProvider ?? RuntimeProcessAuditService.hostProcessList
        self.processWorkingDirectoryProvider = processWorkingDirectoryProvider
            ?? RuntimeProcessAuditService.hostProcessWorkingDirectory
    }

    public func makeReport() -> RuntimeProcessAuditReport {
        Self.report(
            from: processListProvider(),
            processWorkingDirectoryProvider: processWorkingDirectoryProvider
        )
    }

    public func firstRunningMatch(forExecutable executable: String, displayName: String? = nil) -> RuntimeProcessEntry? {
        Self.firstRunningMatch(
            in: processListProvider(),
            executable: executable,
            displayName: displayName,
            processWorkingDirectoryProvider: processWorkingDirectoryProvider
        )
    }

    public static func report(from processListText: String) -> RuntimeProcessAuditReport {
        report(from: processListText, processWorkingDirectoryProvider: { _ in nil })
    }

    public static func report(
        from processListText: String,
        processWorkingDirectoryProvider: @Sendable (Int32) -> String?
    ) -> RuntimeProcessAuditReport {
        let parsedProcesses = parseProcesses(processListText)
        let entries = parsedProcesses.compactMap {
            auditedEntry($0, processWorkingDirectoryProvider: processWorkingDirectoryProvider)
        }.sorted {
            if $0.kind.rawValue != $1.kind.rawValue {
                return $0.kind.rawValue < $1.kind.rawValue
            }
            return $0.processIdentifier < $1.processIdentifier
        }
        let staleEntries = entries.filter { !$0.staleRenderingFlags.isEmpty }
        var findings: [RuntimeProcessFinding] = []
        if let finding = staleRenderingFinding(entries: staleEntries) {
            findings.append(finding)
        }
        if let finding = detachedWineSystemProcessFinding(entries: entries) {
            findings.append(finding)
        }
        if let finding = lenovoCEFForcedGPUChildFinding(entries: entries) {
            findings.append(finding)
        }
        if let finding = processFloodFinding(entries: entries) {
            findings.append(finding)
        }
        if let finding = virtualDesktopFocusContentionFinding(entries: entries) {
            findings.append(finding)
        }
        if let finding = rosettaTranslationStallFinding(entries: entries) {
            findings.append(finding)
        }
        if let finding = managerDuplicateFinding(processes: parsedProcesses) {
            findings.append(finding)
        }
        return RuntimeProcessAuditReport(
            observedProcessCount: parsedProcesses.count,
            auditedProcessCount: entries.count,
            staleRenderingProcessCount: staleEntries.count,
            entries: entries,
            findings: findings
        )
    }

    public static func firstRunningMatch(in processListText: String, executable: String, displayName: String? = nil) -> RuntimeProcessEntry? {
        firstRunningMatch(
            in: processListText,
            executable: executable,
            displayName: displayName,
            processWorkingDirectoryProvider: { _ in nil }
        )
    }

    public static func firstRunningMatch(
        in processListText: String,
        executable: String,
        displayName: String? = nil,
        processWorkingDirectoryProvider: @Sendable (Int32) -> String?
    ) -> RuntimeProcessEntry? {
        let needles = executableNeedles(for: executable, displayName: displayName)
        guard !needles.isEmpty else { return nil }
        return parseProcesses(processListText)
            .compactMap { process -> RuntimeProcessEntry? in
                guard command(process.command, matchesAny: needles) else { return nil }
                let workingDirectory = processWorkingDirectoryProvider(process.processIdentifier)
                return RuntimeProcessEntry(
                    processIdentifier: process.processIdentifier,
                    parentProcessIdentifier: process.parentProcessIdentifier,
                    processState: process.state,
                    kind: kind(for: process.command) ?? .windowsExecutable,
                    executableName: executableName(in: process.command),
                    workingDirectory: workingDirectory,
                    winePrefixPath: winePrefixPath(from: workingDirectory),
                    staleRenderingFlags: staleRenderingFlags(in: process.command),
                    commandPreview: commandPreview(process.command)
                )
            }
            .sorted { $0.processIdentifier < $1.processIdentifier }
            .first
    }

    private static func processFloodFinding(entries: [RuntimeProcessEntry]) -> RuntimeProcessFinding? {
        guard entries.count >= 8 else { return nil }
        return RuntimeProcessFinding(
            id: "managed-runtime-process-flood",
            severity: "medium",
            title: "Many Wine-managed processes are still running",
            detail: "Several Windows/Wine processes are active at the same time. This often happens after repeated launcher clicks or crashed helper processes. Stop duplicate apps from MacWin Manager or quit stale Wine processes before testing a new launch.",
            affectedProcessIdentifiers: entries.map(\.processIdentifier).sorted(),
            flags: ["process-count-\(entries.count)"]
        )
    }

    private static func detachedWineSystemProcessFinding(entries: [RuntimeProcessEntry]) -> RuntimeProcessFinding? {
        let affectedEntries = safelyDetachedWineSystemEntries(from: entries)
        guard affectedEntries.count >= 3 else { return nil }
        let prefixes = Set(affectedEntries.compactMap(\.winePrefixPath))
        return RuntimeProcessFinding(
            id: "detached-wine-system-processes",
            severity: "high",
            title: "Detached Wine system process groups are still running",
            detail: "Wine system services were adopted by launchd after their server exited. They are grouped by Wine prefix so MacWin can stop only the affected container without terminating unrelated Windows apps.",
            affectedProcessIdentifiers: affectedEntries.map(\.processIdentifier).sorted(),
            flags: [
                "detached-system-process-count-\(affectedEntries.count)",
                "wine-prefix-count-\(prefixes.count)"
            ]
        )
    }

    private static func lenovoCEFForcedGPUChildFinding(entries: [RuntimeProcessEntry]) -> RuntimeProcessFinding? {
        let affectedEntries = entries.filter { entry in
            guard entry.kind == .lenovoAppStore else { return false }
            let command = entry.commandPreview.lowercased()
            return command.contains("--type=gpu-process")
                && (
                    command.contains("--use-angle=swiftshader-webgl")
                        || command.contains("--gpu-preferences=")
                )
        }
        guard !affectedEntries.isEmpty else { return nil }
        return RuntimeProcessFinding(
            id: "lenovo-cef-forced-gpu-child",
            severity: "high",
            title: "Lenovo CEF still starts a GPU child process",
            detail: "Lenovo App Store is still spawning a CEF GPU process with SwiftShader/WebGL preferences. Single-process and in-process-gpu probes crash earlier on this build, so keep the current app-mode launcher and continue isolating the CEF GPU child path rather than switching the whole app to single-process mode.",
            affectedProcessIdentifiers: affectedEntries.map(\.processIdentifier).sorted(),
            flags: ["cef-gpu-process", "swiftshader-webgl"]
        )
    }

    private static func virtualDesktopFocusContentionFinding(entries: [RuntimeProcessEntry]) -> RuntimeProcessFinding? {
        let desktopEntries = entries.filter { entry in
            let command = entry.commandPreview.lowercased()
            return command.contains("explorer.exe") && command.contains("/desktop")
        }
        guard !desktopEntries.isEmpty else { return nil }
        return RuntimeProcessFinding(
            id: "wine-virtual-desktop-focus-contention",
            severity: "high",
            title: "Wine virtual desktop may steal input focus",
            detail: "A Wine explorer /desktop container is still active. It can keep macOS focus, hit-testing, or mouse routing on a stale Wine window. Stop Wine desktops before judging click or keyboard fixes.",
            affectedProcessIdentifiers: desktopEntries.map(\.processIdentifier).sorted(),
            flags: ["virtual-desktop-count-\(desktopEntries.count)"]
        )
    }

    private static func managerDuplicateFinding(processes: [ParsedProcess]) -> RuntimeProcessFinding? {
        let managerProcesses = processes.filter { isMacWinManagerCommand($0.command) }
        guard managerProcesses.count > 1 else { return nil }
        return RuntimeProcessFinding(
            id: "macwin-manager-duplicate-instances",
            severity: "medium",
            title: "Multiple MacWin Manager instances were observed",
            detail: "Finder or Open With can briefly start extra MacWin Manager copies when several .exe files are opened. The current build forwards those requests to the primary window and hides duplicate instances; relaunch the rebuilt app if Dock icons remain.",
            affectedProcessIdentifiers: managerProcesses.map(\.processIdentifier).sorted(),
            flags: ["manager-instance-count-\(managerProcesses.count)"]
        )
    }

    private static func rosettaTranslationStallFinding(entries: [RuntimeProcessEntry]) -> RuntimeProcessFinding? {
        let affectedEntries = entries.filter { $0.isUninterruptible && $0.kind == .wineHost }
        guard !affectedEntries.isEmpty else { return nil }
        return RuntimeProcessFinding(
            id: "rosetta-wine-runtime-uninterruptible",
            severity: "high",
            title: "Rosetta cannot start Wine runtime processes",
            detail: "One or more Wine loader or server processes are stuck in an uninterruptible macOS state before Wine startup. SIGTERM and SIGKILL cannot recover this state. New engine probes are paused to avoid accumulating processes; restart macOS or recover the Rosetta translation service before resuming compatibility tests.",
            affectedProcessIdentifiers: affectedEntries.map(\.processIdentifier).sorted(),
            flags: ["uninterruptible-wine-runtime", "rosetta-translation-stall"]
        )
    }

    private static func executableNeedles(for executable: String, displayName: String?) -> [String] {
        let normalizedPath = executable
            .replacingOccurrences(of: "\\", with: "/")
            .lowercased()
        let fileName = URL(fileURLWithPath: normalizedPath).lastPathComponent
        let stem = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
        var needles = [normalizedPath, fileName].filter { !$0.isEmpty }
        if stem.count >= 4 {
            needles.append(stem)
        }
        if let displayName {
            let normalizedDisplayName = displayName
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            if normalizedDisplayName.count >= 4 {
                needles.append(normalizedDisplayName)
            }
        }
        needles.append(contentsOf: compatibilityAliasNeedles(forExecutablePath: normalizedPath, fileName: fileName, stem: stem))
        return Array(Set(needles)).sorted()
    }

    private static func compatibilityAliasNeedles(forExecutablePath path: String, fileName: String, stem: String) -> [String] {
        if fileName == "hyp.exe" || path.contains("mihoyo launcher") {
            return ["hyp.exe", "hyphelper", "mihoyo launcher"]
        }
        if fileName == "steam.exe" || path.contains("/steam/") {
            return ["steam.exe", "steamwebhelper.exe", "/steam/"]
        }
        if fileName == "lenovoappstore.exe" || fileName == "leaslane.exe" || path.contains("leappstore") {
            return [
                "lenovoappstore.exe",
                "leaslane.exe",
                "leappstore",
                "lenovoserviceas.exe",
                "lisfservice.exe",
                "lenovointernetsoftwareframework"
            ]
        }
        if stem == "launcher" {
            return ["launcher.exe"]
        }
        return []
    }

    private static func command(_ command: String, matchesAny needles: [String]) -> Bool {
        let normalizedCommand = command
            .replacingOccurrences(of: "\\", with: "/")
            .lowercased()
        return needles.contains { needle in
            let normalizedNeedle = needle.replacingOccurrences(of: "\\", with: "/").lowercased()
            return normalizedCommand.contains(normalizedNeedle)
        }
    }

    private static func parseProcesses(_ text: String) -> [ParsedProcess] {
        text.components(separatedBy: .newlines).compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            let parts = trimmed.split(maxSplits: 3, whereSeparator: { $0 == " " || $0 == "\t" })
            guard parts.count >= 2, let pid = Int32(parts[0]) else { return nil }
            var fieldIndex = 1
            var parentProcessIdentifier: Int32?
            if parts.count >= 3, let parentPID = Int32(parts[fieldIndex]) {
                parentProcessIdentifier = parentPID
                fieldIndex += 1
            }
            var state: String?
            if parts.indices.contains(fieldIndex), isProcessStateToken(parts[fieldIndex]) {
                state = String(parts[fieldIndex])
                fieldIndex += 1
            }
            guard parts.indices.contains(fieldIndex) else { return nil }
            return ParsedProcess(
                processIdentifier: pid,
                parentProcessIdentifier: parentProcessIdentifier,
                state: state,
                command: parts[fieldIndex...].map(String.init).joined(separator: " ")
            )
        }
    }

    private static func isProcessStateToken(_ token: Substring) -> Bool {
        guard token.count <= 8, let first = token.uppercased().first else { return false }
        let allowedCharacters = Set("RSDTZIUWX+<>NsEl")
        return "RSDTZIUWX".contains(first) && token.allSatisfy(allowedCharacters.contains)
    }

    private static func auditedEntry(
        _ process: ParsedProcess,
        processWorkingDirectoryProvider: @Sendable (Int32) -> String?
    ) -> RuntimeProcessEntry? {
        let command = process.command
        guard !isHostScannerCommand(command) else { return nil }
        guard let kind = kind(for: command) else { return nil }
        let workingDirectory = processWorkingDirectoryProvider(process.processIdentifier)
        return RuntimeProcessEntry(
            processIdentifier: process.processIdentifier,
            parentProcessIdentifier: process.parentProcessIdentifier,
            processState: process.state,
            kind: kind,
            executableName: executableName(in: command),
            workingDirectory: workingDirectory,
            winePrefixPath: winePrefixPath(from: workingDirectory),
            staleRenderingFlags: staleRenderingFlags(in: command),
            commandPreview: commandPreview(command)
        )
    }

    private static func winePrefixPath(from workingDirectory: String?) -> String? {
        guard let workingDirectory, !workingDirectory.isEmpty else { return nil }
        let standardizedPath = URL(fileURLWithPath: workingDirectory).standardizedFileURL.path
        let lowercasedPath = standardizedPath.lowercased()
        if lowercasedPath.hasSuffix("/drive_c") {
            return String(standardizedPath.dropLast("/drive_c".count))
        }
        guard let driveRange = lowercasedPath.range(of: "/drive_c/") else { return nil }
        return String(standardizedPath[..<driveRange.lowerBound])
    }

    private static func kind(for command: String) -> RuntimeProcessKind? {
        let lowercased = command.lowercased()
        if lowercased.contains("hyphelper")
            || lowercased.contains("hyp.exe")
            || lowercased.contains("mihoyo launcher") {
            return .hoYoPlay
        }
        if lowercased.contains("steamwebhelper.exe")
            || lowercased.contains("steam.exe")
            || lowercased.contains("\\steam\\") {
            return .steam
        }
        if lowercased.contains("lenovoappstore.exe")
            || lowercased.contains("leaslane.exe")
            || lowercased.contains("leappstore")
            || lowercased.contains("lenovoserviceas.exe")
            || lowercased.contains("lisfservice.exe")
            || lowercased.contains("lenovointernetsoftwareframework") {
            return .lenovoAppStore
        }
        if lowercased.contains("/wine")
            || lowercased.contains("wineserver")
            || lowercased.contains("winedevice.exe") {
            return .wineHost
        }
        if lowercased.contains(".exe") && (lowercased.contains("c:\\") || lowercased.contains("z:\\") || lowercased.contains("/drive_c/")) {
            return .windowsExecutable
        }
        return nil
    }

    private static func isHostScannerCommand(_ command: String) -> Bool {
        let name = executableName(in: command).lowercased()
        if hostScannerExecutableNames.contains(name) {
            return true
        }

        let lowercased = command.lowercased()
        return lowercased.contains("/xcode.app/")
            && (
                lowercased.contains("/usr/bin/git ")
                    || lowercased.contains("sourcecontrol")
                    || lowercased.contains("workingcopyscanner")
            )
    }

    private static func isMacWinManagerCommand(_ command: String) -> Bool {
        let lowercased = command.lowercased()
        if lowercased.contains(" --export-")
            || lowercased.contains(" --scan-installed-apps")
            || lowercased.contains(" --smoke-launcher")
            || lowercased.contains(" --help")
            || lowercased.contains(" -h") {
            return false
        }
        return lowercased.contains("macwin manager.app/contents/macos/macwinmanagerapp")
            || lowercased.hasSuffix("/macwinmanagerapp")
            || lowercased.contains("macwinmanagerapp ")
    }

    private static func staleRenderingFlags(in command: String) -> [String] {
        let lowercased = command.lowercased()
        var flags = staleRenderingFlagDefinitions.compactMap { definition in
            lowercased.contains(definition.token.lowercased()) ? definition.id : nil
        }
        let obsoleteFlags = Set(ApplicationCompatibilityProfile.obsoleteTextRenderingFlags(in: command).map { $0.lowercased() })
        for definition in staleRenderingDisabledFeatureDefinitions
            where obsoleteFlags.contains(definition.feature.lowercased()) {
            flags.append(definition.id)
        }
        return flags
    }

    private static func staleRenderingFinding(entries: [RuntimeProcessEntry]) -> RuntimeProcessFinding? {
        guard !entries.isEmpty else { return nil }
        let flags = Set(entries.flatMap(\.staleRenderingFlags)).sorted()
        return RuntimeProcessFinding(
            id: "stale-runtime-rendering-flags",
            severity: "high",
            title: "Running processes still use obsolete rendering flags",
            detail: "Some already-running Windows/WebView processes still carry old DirectWrite, remote-font, or Chromium text-raster flags. Quit those processes and relaunch through MacWin Manager before judging text-rendering fixes.",
            affectedProcessIdentifiers: entries.map(\.processIdentifier).sorted(),
            flags: flags
        )
    }

    private static func executableName(in command: String) -> String {
        let firstToken = command.split(whereSeparator: { $0 == " " || $0 == "\t" }).first.map(String.init) ?? command
        if firstToken.range(of: #"^"?[A-Za-z]:[\\/]"#, options: .regularExpression) != nil {
            let normalizedCommand = command.replacingOccurrences(of: "\\", with: "/")
            if let executableRange = normalizedCommand.range(
                of: #"(?i)[^/\s"]+\.exe"#,
                options: .regularExpression
            ) {
                return String(normalizedCommand[executableRange])
            }
        }
        let normalized = firstToken.replacingOccurrences(of: "\\", with: "/")
        return URL(fileURLWithPath: normalized).lastPathComponent
    }

    private static func commandPreview(_ command: String) -> String {
        var output = command
        output = output.replacingOccurrences(
            of: #"/Users/[^/\s]+"#,
            with: #"/Users/<user>"#,
            options: .regularExpression
        )
        output = output.replacingOccurrences(
            of: #"(?i)C:\\users\\[^\\\s]+"#,
            with: #"C:\\users\\<user>"#,
            options: .regularExpression
        )
        output = output.replacingOccurrences(
            of: #"(?i)C:/users/[^/\s]+"#,
            with: #"C:/users/<user>"#,
            options: .regularExpression
        )
        if output.count > 700 {
            let index = output.index(output.startIndex, offsetBy: 700)
            output = String(output[..<index]) + "..."
        }
        return output
    }

    private static let staleRenderingFlagDefinitions: [(id: String, token: String)] = [
        ("disable-direct-write", "--disable-direct-write"),
        ("disable-directwrite-for-ui", "--disable-directwrite-for-ui"),
        ("disable-remote-fonts", "--disable-remote-fonts"),
        ("disable-font-subpixel-positioning", "--disable-font-subpixel-positioning"),
        ("disable-lcd-text", "--disable-lcd-text"),
        ("disable-prefer-compositing-to-lcd-text", "--disable-prefer-compositing-to-lcd-text"),
        ("font-render-hinting-none", "--font-render-hinting=none"),
        ("disable-skia-runtime-opts", "--disable-skia-runtime-opts")
    ]

    private static let staleRenderingDisabledFeatureDefinitions: [(id: String, feature: String)] = [
        ("dwrite-font-proxy-disabled", "DWriteFontProxy"),
        ("font-src-local-matching-disabled", "FontSrcLocalMatching"),
        ("fontations-font-backend-disabled", "FontationsFontBackend"),
        ("use-dwrite-core-disabled", "UseDWriteCore")
    ]

    private static let hostScannerExecutableNames: Set<String> = [
        "awk",
        "bash",
        "egrep",
        "fgrep",
        "find",
        "git",
        "grep",
        "mdfind",
        "python",
        "python3",
        "rg",
        "sed",
        "sh",
        "swift",
        "xargs",
        "xcodebuild",
        "zsh"
    ]

    private struct ParsedProcess {
        var processIdentifier: Int32
        var parentProcessIdentifier: Int32?
        var state: String?
        var command: String
    }

    private static func hostProcessList() -> String {
        let process = Process()
        let pipe = Pipe()
        let exited = DispatchSemaphore(value: 0)
        let outputQueue = DispatchQueue(label: "dev.local.macwin.runtime-process-audit.ps-output")
        let outputRead = DispatchSemaphore(value: 0)
        let output = ProcessOutputBuffer()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["axww", "-o", "pid=,ppid=,state=,command="]
        process.standardOutput = pipe
        process.standardError = Pipe()
        process.terminationHandler = { _ in exited.signal() }
        do {
            try process.run()
            outputQueue.async {
                output.set(pipe.fileHandleForReading.readDataToEndOfFile())
                outputRead.signal()
            }
            guard exited.wait(timeout: .now() + 2.0) == .success else {
                process.terminate()
                _ = exited.wait(timeout: .now() + 1.0)
                _ = outputRead.wait(timeout: .now() + 1.0)
                return ""
            }
            guard process.terminationStatus == 0 else { return "" }
            _ = outputRead.wait(timeout: .now() + 1.0)
            return String(data: output.data(), encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }

    private static func hostProcessWorkingDirectory(_ processIdentifier: Int32) -> String? {
        var info = proc_vnodepathinfo()
        let size = proc_pidinfo(
            processIdentifier,
            PROC_PIDVNODEPATHINFO,
            0,
            &info,
            Int32(MemoryLayout<proc_vnodepathinfo>.size)
        )
        guard size == Int32(MemoryLayout<proc_vnodepathinfo>.size) else { return nil }

        return withUnsafePointer(to: &info.pvi_cdir.vip_path) { pathPointer in
            pathPointer.withMemoryRebound(to: CChar.self, capacity: Int(MAXPATHLEN)) { cString in
                let path = String(cString: cString)
                return path.isEmpty ? nil : path
            }
        }
    }
}

private func safelyDetachedWineSystemEntries(
    from entries: [RuntimeProcessEntry]
) -> [RuntimeProcessEntry] {
    let candidates = entries.filter(\.isDetachedWineSystemProcess)
    let groupedEntries = Dictionary(grouping: entries.compactMap { entry -> (String, RuntimeProcessEntry)? in
        guard let prefixPath = entry.winePrefixPath else { return nil }
        return (URL(fileURLWithPath: prefixPath).standardizedFileURL.path, entry)
    }, by: \.0)

    return candidates.filter { candidate in
        guard let prefixPath = candidate.winePrefixPath else { return false }
        let normalizedPrefix = URL(fileURLWithPath: prefixPath).standardizedFileURL.path
        let prefixEntries = groupedEntries[normalizedPrefix, default: []].map(\.1)
        return prefixEntries.allSatisfy(\.isDetachedWineSystemProcess)
    }
}

private final class ProcessOutputBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var storage = Data()

    func set(_ data: Data) {
        lock.lock()
        storage = data
        lock.unlock()
    }

    func data() -> Data {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }
}
