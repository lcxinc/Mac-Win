import Testing
@testable import MacWinCore

@Suite("Runtime application audit service")
struct RuntimeApplicationAuditServiceTests {
    @Test("Application audit parses LaunchServices apps and detects duplicate MacWin entries")
    func applicationAuditParsesLaunchServicesAndDuplicates() {
        let report = RuntimeApplicationAuditService.report(from: """
         1) "Finder" ASN:0x0-0x1001:
            bundleID="com.apple.finder"
            bundle path="/System/Library/CoreServices/Finder.app"
            executable path="/System/Library/CoreServices/Finder.app/Contents/MacOS/Finder"
            pid = 101 type="Foreground" Arch=ARM64
         2) "MacWin 管理器" ASN:0x0-0x2002: (in front)
            bundleID="dev.local.macwin.manager"
            bundle path="/Users/alice/project/Mac-Win/MacWinManager/dist/MacWin Manager.app"
            executable path="/Users/alice/project/Mac-Win/MacWinManager/dist/MacWin Manager.app/Contents/MacOS/MacWinManagerApp"
            pid = 201 type="Foreground" Arch=ARM64
         3) "MacWin 管理器" ASN:0x0-0x3003:
            bundleID="dev.local.macwin.manager"
            bundle path="/Users/alice/project/Mac-Win/MacWinManager/dist/MacWin Manager.app"
            executable path="/Users/alice/project/Mac-Win/MacWinManager/dist/MacWin Manager.app/Contents/MacOS/MacWinManagerApp"
            pid = 202 type="Foreground" Arch=ARM64
        """)

        #expect(report.observedApplicationCount == 3)
        #expect(report.auditedApplicationCount == 2)
        #expect(report.macWinApplicationCount == 2)
        #expect(report.wineRelatedApplicationCount == 0)
        #expect(report.entries.map(\.processIdentifier) == [201, 202])
        #expect(report.entries.first?.kind == .macWinManager)
        #expect(report.entries.first?.isFrontmost == true)
        #expect(report.entries.first?.bundlePath?.contains("/Users/alice") == false)
        #expect(report.findings.first?.id == "macwin-manager-multiple-launchservices-apps")
        #expect(report.findings.first?.affectedProcessIdentifiers == [201, 202])

        let csv = RuntimeApplicationAuditReport.csv(report: report)
        #expect(csv.contains("row_type,id,severity,application_index,pid,kind,name,bundle_id,frontmost"))
        #expect(csv.contains("finding,macwin-manager-multiple-launchservices-apps,medium"))
        #expect(csv.contains("application,,warning,2,201,macWinManager,MacWin 管理器,dev.local.macwin.manager,true"))
        #expect(csv.contains("/Users/<user>/project/Mac-Win"))
        #expect(!csv.contains("/Users/alice"))

        let logText = RuntimeApplicationAuditReport.diagnosticLogText(report: report)
        #expect(logText.contains("runtime-applications"))
        #expect(logText.contains("macWinApplicationCount=2"))
        #expect(logText.contains("runtime-application-finding id=macwin-manager-multiple-launchservices-apps"))
    }

    @Test("Application audit detects Wine app-mode floods and keeps frontmost host app context")
    func applicationAuditDetectsWineAppModeFloods() {
        let report = RuntimeApplicationAuditService.report(from: """
         4) "Steam" ASN:0x0-0x4004:
            bundleID="org.winehq.wine.steam"
            bundle path="/Users/alice/Library/Application Support/MacWin/Bottles/game/drive_c/Program Files/Steam/Steam.exe"
            executable path="/Users/alice/project/Mac-Win/refs/build/loader/wine"
            pid = 301 type="Foreground" Arch=X86_64
         5) "HoYoPlay" ASN:0x0-0x5005:
            bundleID=[ NULL ]
            bundle path="/Users/alice/Library/Application Support/MacWin/Bottles/game/drive_c/Program Files/miHoYo Launcher/HYP.exe"
            executable path="/Users/alice/project/Mac-Win/refs/build/loader/wine"
            pid = 302 type="Foreground" Arch=X86_64
         6) "LenovoAppStore" ASN:0x0-0x6006:
            bundleID=[ NULL ]
            bundle path="/Users/alice/Downloads/LenovoAppStoreInstall.exe"
            executable path="/Users/alice/project/Mac-Win/refs/build/loader/wine"
            pid = 303 type="Foreground" Arch=X86_64
         7) "itch" ASN:0x0-0x7007:
            bundleID=[ NULL ]
            bundle path="/Users/alice/Downloads/itch-setup.exe"
            executable path="/Users/alice/project/Mac-Win/refs/build/loader/wine"
            pid = 304 type="Foreground" Arch=X86_64
         8) "Codex" ASN:0x0-0x8008: (in front)
            bundleID="com.openai.codex"
            bundle path="/Applications/Codex.app"
            executable path="/Applications/Codex.app/Contents/MacOS/Codex"
            pid = 401 type="Foreground" Arch=ARM64
        """)

        #expect(report.observedApplicationCount == 5)
        #expect(report.auditedApplicationCount == 5)
        #expect(report.macWinApplicationCount == 0)
        #expect(report.wineRelatedApplicationCount == 4)
        #expect(report.entries.filter { $0.kind == .wineRelated }.map(\.processIdentifier) == [301, 302, 303, 304])
        #expect(report.entries.first { $0.kind == .frontmostHostApp }?.name == "Codex")
        #expect(report.findings.first?.id == "wine-launchservices-application-flood")
        #expect(report.findings.first?.affectedProcessIdentifiers == [301, 302, 303, 304])
    }

    @Test("Application audit ignores duplicate LaunchServices shells for same MacWin process")
    func applicationAuditIgnoresDuplicateShellsForSameMacWinProcess() {
        let report = RuntimeApplicationAuditService.report(from: """
         11) "MacWin 管理器" ASN:0x0-0xb00b:
            bundleID="dev.local.macwin.manager"
            bundle path="/Users/alice/project/Mac-Win/MacWinManager/dist/MacWin Manager.app"
            executable path="/Users/alice/project/Mac-Win/MacWinManager/dist/MacWin Manager.app/Contents/MacOS/MacWinManagerApp"
            pid = 601 type="Foreground" Arch=ARM64
         12) "MacWin 管理器" ASN:0x0-0xc00c:
            bundleID="dev.local.macwin.manager"
            bundle path="/Users/alice/project/Mac-Win/MacWinManager/dist/MacWin Manager.app"
            executable path="/Users/alice/project/Mac-Win/MacWinManager/dist/MacWin Manager.app/Contents/MacOS/MacWinManagerApp"
            pid = 601 type="Foreground" Arch=ARM64
        """)

        #expect(report.macWinApplicationCount == 2)
        #expect(report.entries.map(\.processIdentifier) == [601, 601])
        #expect(report.findings.isEmpty)
    }

    @Test("Host application audit filters findings for stale process identifiers")
    func hostApplicationAuditFiltersStaleProcessIdentifiers() {
        let text = """
         13) "MacWin 管理器" ASN:0x0-0xd00d:
            bundleID="dev.local.macwin.manager"
            bundle path="/Users/alice/project/Mac-Win/MacWinManager/dist/MacWin Manager.app"
            executable path="/Users/alice/project/Mac-Win/MacWinManager/dist/MacWin Manager.app/Contents/MacOS/MacWinManagerApp"
            pid = 701 type="Foreground" Arch=ARM64
         14) "MacWin 管理器" ASN:0x0-0xe00e:
            bundleID="dev.local.macwin.manager"
            bundle path="/Users/alice/project/Mac-Win/MacWinManager/dist/MacWin Manager.app"
            executable path="/Users/alice/project/Mac-Win/MacWinManager/dist/MacWin Manager.app/Contents/MacOS/MacWinManagerApp"
            pid = 702 type="Foreground" Arch=ARM64
        """
        #expect(RuntimeApplicationAuditService.report(from: text).findings.count == 1)

        let report = RuntimeApplicationAuditService(
            applicationListProvider: { text },
            processExists: { $0 == 702 }
        ).makeReport()

        #expect(report.findings.isEmpty)
    }

    @Test("Application audit does not mistake switcher names for itch")
    func applicationAuditDoesNotMistakeSwitcherNamesForItch() {
        let report = RuntimeApplicationAuditService.report(from: """
         15) "TextInputSwitcher" ASN:0x0-0xf00f:
            bundleID="com.apple.TextInputSwitcher"
            bundle path="/System/Library/CoreServices/TextInputSwitcher.app"
            executable path="/System/Library/CoreServices/TextInputSwitcher.app/Contents/MacOS/TextInputSwitcher"
            pid = 801 type="UIElement" Arch=ARM64
         16) "R-Switch" ASN:0x0-0x1010:
            bundleID="dev.rswitch.shell"
            bundle path="/Users/alice/project/R-Switch/build/R-Switch.app"
            executable path="/Users/alice/project/R-Switch/build/R-Switch.app/Contents/MacOS/R-Switch"
            pid = 802 type="Foreground" Arch=ARM64
         17) "itch" ASN:0x0-0x1111:
            bundleID=[ NULL ]
            bundle path="/Users/alice/Library/Application Support/MacWin/Bottles/game/drive_c/users/alice/AppData/Local/itch/app-26.13.0/itch.exe"
            executable path="/Users/alice/project/Mac-Win/refs/build/loader/wine"
            pid = 803 type="Foreground" Arch=X86_64
        """)

        #expect(report.wineRelatedApplicationCount == 1)
        #expect(report.entries.map(\.name) == ["itch"])
    }

    @Test("Application audit ignores unrelated background and host apps")
    func applicationAuditIgnoresUnrelatedApps() {
        let report = RuntimeApplicationAuditService.report(from: """
         9) "loginwindow" ASN:0x0-0x9009:
            bundleID="com.apple.loginwindow"
            bundle path="/System/Library/CoreServices/loginwindow.app"
            executable path="/System/Library/CoreServices/loginwindow.app/Contents/MacOS/loginwindow"
            pid = 501 type="UIElement" Arch=ARM64
         10) "Finder" ASN:0x0-0xa00a:
            bundleID="com.apple.finder"
            bundle path="/System/Library/CoreServices/Finder.app"
            executable path="/System/Library/CoreServices/Finder.app/Contents/MacOS/Finder"
            pid = 502 type="Foreground" Arch=ARM64
        """)

        #expect(report.observedApplicationCount == 2)
        #expect(report.auditedApplicationCount == 0)
        #expect(report.entries.isEmpty)
        #expect(report.findings.isEmpty)
    }
}
