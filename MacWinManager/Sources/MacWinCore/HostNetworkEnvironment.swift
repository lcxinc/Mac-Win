import Foundation

public enum HostNetworkEnvironment {
    public static func current() -> [String: String] {
        var environment: [String: String] = [:]

        if let route = processOutput("/sbin/route", arguments: ["-n", "get", "default"]) {
            if let gateway = value(after: "gateway:", in: route), isIPv4(gateway) {
                environment["MACWIN_GATEWAY_IPV4"] = gateway
            }

            if let interface = value(after: "interface:", in: route),
               let ifconfig = processOutput("/sbin/ifconfig", arguments: [interface]),
               let host = firstInetIPv4(in: ifconfig) {
                environment["MACWIN_HOST_IPV4"] = host
            }
        }

        if let dns = processOutput("/usr/sbin/scutil", arguments: ["--dns"]).flatMap(firstNameserverIPv4(in:)) {
            environment["MACWIN_DNS_IPV4"] = dns
        }

        return environment
    }

    private static func processOutput(_ executable: String, arguments: [String], timeout: TimeInterval = 2.0) -> String? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return nil
        }

        let deadline = Date().addingTimeInterval(timeout)
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.02)
        }
        guard !process.isRunning else {
            process.terminate()
            return nil
        }

        guard process.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }

    private static func value(after marker: String, in output: String) -> String? {
        for line in output.split(whereSeparator: \.isNewline) {
            let trimmed = String(line).trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix(marker) else { continue }
            return String(trimmed.dropFirst(marker.count)).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    private static func firstInetIPv4(in output: String) -> String? {
        for line in output.split(whereSeparator: \.isNewline) {
            let parts = line.split(whereSeparator: \.isWhitespace).map(String.init)
            guard parts.count >= 2, parts[0] == "inet", isIPv4(parts[1]), !parts[1].hasPrefix("127.") else {
                continue
            }
            return parts[1]
        }
        return nil
    }

    private static func firstNameserverIPv4(in output: String) -> String? {
        for line in output.split(whereSeparator: \.isNewline) {
            let trimmed = String(line).trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("nameserver"), let value = trimmed.split(separator: ":").last else {
                continue
            }
            let ipv4 = String(value).trimmingCharacters(in: .whitespaces)
            if isIPv4(ipv4) { return ipv4 }
        }
        return nil
    }

    private static func isIPv4(_ value: String) -> Bool {
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard let octet = Int(part), (0...255).contains(octet) else { return false }
            return String(octet) == String(part)
        }
    }
}
