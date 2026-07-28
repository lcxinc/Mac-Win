import Darwin
import Foundation

public struct RuntimeApplicationAuditReport: Codable, Equatable, Sendable {
    public var observedApplicationCount: Int
    public var auditedApplicationCount: Int
    public var macWinApplicationCount: Int
    public var wineRelatedApplicationCount: Int
    public var entries: [RuntimeApplicationEntry]
    public var findings: [RuntimeApplicationFinding]

    public init(
        observedApplicationCount: Int,
        auditedApplicationCount: Int,
        macWinApplicationCount: Int,
        wineRelatedApplicationCount: Int,
        entries: [RuntimeApplicationEntry],
        findings: [RuntimeApplicationFinding]
    ) {
        self.observedApplicationCount = observedApplicationCount
        self.auditedApplicationCount = auditedApplicationCount
        self.macWinApplicationCount = macWinApplicationCount
        self.wineRelatedApplicationCount = wineRelatedApplicationCount
        self.entries = entries
        self.findings = findings
    }

    public static func csv(report: RuntimeApplicationAuditReport?) -> String {
        var rows: [[String]] = [[
            "row_type",
            "id",
            "severity",
            "application_index",
            "pid",
            "kind",
            "name",
            "bundle_id",
            "frontmost",
            "affected_pids",
            "title",
            "detail",
            "bundle_path",
            "executable_path"
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
                finding.affectedProcessIdentifiers.map(String.init).joined(separator: ";"),
                finding.title,
                finding.detail,
                "",
                ""
            ])
        }

        for entry in report?.entries ?? [] {
            rows.append([
                "application",
                "",
                entry.kind == .frontmostHostApp ? "info" : "warning",
                String(entry.applicationIndex),
                entry.processIdentifier.map(String.init) ?? "",
                entry.kind.rawValue,
                entry.name,
                entry.bundleIdentifier ?? "",
                entry.isFrontmost ? "true" : "false",
                "",
                "",
                "",
                entry.bundlePath ?? "",
                entry.executablePath ?? ""
            ])
        }

        return rows.map { $0.map(csvEscaped).joined(separator: ",") }.joined(separator: "\n")
    }

    public static func diagnosticLogText(report: RuntimeApplicationAuditReport?) -> String {
        guard let report else {
            return "runtime-applications: unavailable\n"
        }
        var lines = [
            "runtime-applications",
            "observedApplicationCount=\(report.observedApplicationCount)",
            "auditedApplicationCount=\(report.auditedApplicationCount)",
            "macWinApplicationCount=\(report.macWinApplicationCount)",
            "wineRelatedApplicationCount=\(report.wineRelatedApplicationCount)",
            "findingCount=\(report.findings.count)"
        ]
        for finding in report.findings {
            lines.append("warn: runtime-application-finding id=\(finding.id) severity=\(finding.severity) pids=\(finding.affectedProcessIdentifiers.map(String.init).joined(separator: ","))")
        }
        for entry in report.entries {
            lines.append("app index=\(entry.applicationIndex) pid=\(entry.processIdentifier.map(String.init) ?? "unknown") kind=\(entry.kind.rawValue) frontmost=\(entry.isFrontmost) name=\(entry.name)")
        }
        return lines.joined(separator: "\n") + "\n"
    }

    private static func csvEscaped(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}

public struct RuntimeApplicationEntry: Codable, Equatable, Sendable {
    public var applicationIndex: Int
    public var processIdentifier: Int32?
    public var kind: RuntimeApplicationKind
    public var name: String
    public var bundleIdentifier: String?
    public var bundlePath: String?
    public var executablePath: String?
    public var isFrontmost: Bool
    public var applicationType: String?
    public var architecture: String?
}

public struct RuntimeApplicationFinding: Codable, Equatable, Sendable {
    public var id: String
    public var severity: String
    public var title: String
    public var detail: String
    public var affectedProcessIdentifiers: [Int32]
}

public enum RuntimeApplicationKind: String, Codable, Equatable, Sendable {
    case macWinManager
    case wineRelated
    case frontmostHostApp
}

public struct RuntimeApplicationAuditService: Sendable {
    public var applicationListProvider: @Sendable () -> String
    public var processExists: @Sendable (Int32) -> Bool

    public init(
        applicationListProvider: (@Sendable () -> String)? = nil,
        processExists: (@Sendable (Int32) -> Bool)? = nil
    ) {
        self.applicationListProvider = applicationListProvider ?? RuntimeApplicationAuditService.hostApplicationList
        self.processExists = processExists ?? RuntimeApplicationAuditService.hostProcessExists
    }

    public func makeReport() -> RuntimeApplicationAuditReport {
        let report = Self.report(from: applicationListProvider())
        let liveFindings = report.findings.filter { finding in
            let livePids = finding.affectedProcessIdentifiers.filter(processExists)
            return livePids.count == finding.affectedProcessIdentifiers.count
        }
        guard liveFindings.count != report.findings.count else { return report }
        return RuntimeApplicationAuditReport(
            observedApplicationCount: report.observedApplicationCount,
            auditedApplicationCount: report.auditedApplicationCount,
            macWinApplicationCount: report.macWinApplicationCount,
            wineRelatedApplicationCount: report.wineRelatedApplicationCount,
            entries: report.entries,
            findings: liveFindings
        )
    }

    public static func report(from applicationListText: String) -> RuntimeApplicationAuditReport {
        let parsedApplications = parseApplications(applicationListText)
        let macWinApplications = parsedApplications.filter(isMacWinManager)
        let wineApplications = parsedApplications.filter(isWineRelated)
        let audited = parsedApplications.compactMap(auditedEntry).sorted {
            if $0.kind.rawValue != $1.kind.rawValue {
                return $0.kind.rawValue < $1.kind.rawValue
            }
            return $0.applicationIndex < $1.applicationIndex
        }

        var findings: [RuntimeApplicationFinding] = []
        if let finding = macWinDuplicateFinding(applications: macWinApplications) {
            findings.append(finding)
        }
        if let finding = wineApplicationFloodFinding(applications: wineApplications) {
            findings.append(finding)
        }

        return RuntimeApplicationAuditReport(
            observedApplicationCount: parsedApplications.count,
            auditedApplicationCount: audited.count,
            macWinApplicationCount: macWinApplications.count,
            wineRelatedApplicationCount: wineApplications.count,
            entries: audited,
            findings: findings
        )
    }

    private static func auditedEntry(_ application: ParsedApplication) -> RuntimeApplicationEntry? {
        let kind: RuntimeApplicationKind
        if isMacWinManager(application) {
            kind = .macWinManager
        } else if isWineRelated(application) {
            kind = .wineRelated
        } else if application.isFrontmost {
            kind = .frontmostHostApp
        } else {
            return nil
        }

        return RuntimeApplicationEntry(
            applicationIndex: application.applicationIndex,
            processIdentifier: application.processIdentifier,
            kind: kind,
            name: application.name,
            bundleIdentifier: sanitizedOptional(application.bundleIdentifier),
            bundlePath: application.bundlePath.map(sanitizedPath),
            executablePath: application.executablePath.map(sanitizedPath),
            isFrontmost: application.isFrontmost,
            applicationType: application.applicationType,
            architecture: application.architecture
        )
    }

    private static func macWinDuplicateFinding(applications: [ParsedApplication]) -> RuntimeApplicationFinding? {
        let liveProcessIdentifiers = Set(applications.compactMap(\.processIdentifier))
        guard liveProcessIdentifiers.count > 1 else { return nil }
        return RuntimeApplicationFinding(
            id: "macwin-manager-multiple-launchservices-apps",
            severity: "medium",
            title: "Multiple MacWin Manager applications are registered by LaunchServices",
            detail: "macOS currently reports more than one MacWin Manager foreground application. This can make the Dock look like several MacWin copies are running. Quit duplicate entries or relaunch the signed app bundle.",
            affectedProcessIdentifiers: liveProcessIdentifiers.sorted()
        )
    }

    private static func wineApplicationFloodFinding(applications: [ParsedApplication]) -> RuntimeApplicationFinding? {
        let liveProcessIdentifiers = Set(applications.compactMap(\.processIdentifier))
        guard liveProcessIdentifiers.count >= 4 else { return nil }
        return RuntimeApplicationFinding(
            id: "wine-launchservices-application-flood",
            severity: "medium",
            title: "Many Wine-related applications are registered by LaunchServices",
            detail: "Several Wine or Windows-app entries are visible to macOS at the same time. This usually follows repeated launcher clicks or helper processes presenting as separate app-mode windows.",
            affectedProcessIdentifiers: liveProcessIdentifiers.sorted()
        )
    }

    private static func parseApplications(_ text: String) -> [ParsedApplication] {
        var applications: [ParsedApplication] = []
        var current: ParsedApplication?

        func flushCurrent() {
            if let current {
                applications.append(current)
            }
        }

        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }

            if let header = parseHeader(line) {
                flushCurrent()
                current = header
                continue
            }

            guard var app = current else { continue }
            if let value = quotedValue(in: line, key: "bundleID") {
                app.bundleIdentifier = value
            } else if let value = quotedValue(in: line, key: "bundle path") {
                app.bundlePath = value
            } else if let value = quotedValue(in: line, key: "executable path") {
                app.executablePath = value
            }
            if let pid = firstCapture(in: line, pattern: #"pid\s*=\s*(\d+)"#).flatMap(Int32.init) {
                app.processIdentifier = pid
            }
            if let applicationType = quotedValue(in: line, key: "type") {
                app.applicationType = applicationType
            }
            if let arch = firstCapture(in: line, pattern: #"Arch=([A-Za-z0-9_]+)"#) {
                app.architecture = arch
            }
            if line.contains("front") || line.contains("in front") {
                app.isFrontmost = true
            }
            current = app
        }

        flushCurrent()
        return applications
    }

    private static func parseHeader(_ line: String) -> ParsedApplication? {
        guard let match = line.range(
            of: #"^\s*(\d+)\)\s+"([^"]*)"\s+ASN:"#,
            options: .regularExpression
        ) else {
            return nil
        }
        let matched = String(line[match])
        let index = firstCapture(in: matched, pattern: #"^\s*(\d+)\)"#).flatMap(Int.init) ?? 0
        let name = firstCapture(in: matched, pattern: #""([^"]*)""#) ?? ""
        return ParsedApplication(
            applicationIndex: index,
            name: name,
            bundleIdentifier: nil,
            bundlePath: nil,
            executablePath: nil,
            processIdentifier: nil,
            isFrontmost: line.contains("in front"),
            applicationType: nil,
            architecture: nil
        )
    }

    private static func quotedValue(in line: String, key: String) -> String? {
        if line.contains("\(key)=[ NULL ]") {
            return nil
        }
        return firstCapture(in: line, pattern: #"\#(NSRegularExpression.escapedPattern(for: key))=\"([^\"]*)\""#)
    }

    private static func firstCapture(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range), match.numberOfRanges > 1 else {
            return nil
        }
        guard let captureRange = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[captureRange])
    }

    private static func isMacWinManager(_ application: ParsedApplication) -> Bool {
        let bundleIdentifier = application.bundleIdentifier?.lowercased() ?? ""
        let executablePath = application.executablePath?.lowercased() ?? ""
        let bundlePath = application.bundlePath?.lowercased() ?? ""
        return bundleIdentifier == "dev.local.macwin.manager"
            || executablePath.contains("/macwinmanagerapp")
            || bundlePath.contains("macwin manager.app")
    }

    private static func isWineRelated(_ application: ParsedApplication) -> Bool {
        guard !isMacWinManager(application) else { return false }
        let name = application.name.lowercased()
        let bundlePath = application.bundlePath?.lowercased() ?? ""
        let executablePath = application.executablePath?.lowercased() ?? ""
        let haystack = [
            application.name,
            application.bundleIdentifier ?? "",
            application.bundlePath ?? "",
            application.executablePath ?? ""
        ]
            .joined(separator: " ")
            .lowercased()
        return haystack.contains("wine")
            || haystack.contains("wineserver")
            || haystack.contains(".exe")
            || haystack.contains("hoyoplay")
            || haystack.contains("mihoyo")
            || haystack.contains("steam")
            || haystack.contains("lenovo")
            || haystack.contains("leappstore")
            || name == "itch"
            || name.contains("itch.io")
            || bundlePath.contains("/itch/")
            || bundlePath.hasSuffix("/itch.app")
            || executablePath.contains("/itch/")
    }

    private static func sanitizedOptional(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        return value
    }

    private static func sanitizedPath(_ path: String) -> String {
        var output = path
        output = output.replacingOccurrences(
            of: #"/Users/[^/\s]+"#,
            with: #"/Users/<user>"#,
            options: .regularExpression
        )
        return output
    }

    private struct ParsedApplication {
        var applicationIndex: Int
        var name: String
        var bundleIdentifier: String?
        var bundlePath: String?
        var executablePath: String?
        var processIdentifier: Int32?
        var isFrontmost: Bool
        var applicationType: String?
        var architecture: String?
    }

    private static func hostApplicationList() -> String {
        let process = Process()
        let pipe = Pipe()
        let exited = DispatchSemaphore(value: 0)
        process.executableURL = URL(fileURLWithPath: "/usr/bin/lsappinfo")
        process.arguments = ["list"]
        process.standardOutput = pipe
        process.standardError = Pipe()
        process.terminationHandler = { _ in exited.signal() }
        do {
            try process.run()
            guard exited.wait(timeout: .now() + 2.0) == .success else {
                process.terminate()
                _ = exited.wait(timeout: .now() + 1.0)
                return ""
            }
            guard process.terminationStatus == 0 else { return "" }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }

    private static func hostProcessExists(pid: Int32) -> Bool {
        guard pid > 0 else { return false }
        return kill(pid, 0) == 0
    }
}
