import Foundation
import Testing
@testable import MacWinCore

@Suite("Runtime process audit service")
struct RuntimeProcessAuditServiceTests {
    @Test("Process audit detects stale rendering flags in running Windows apps")
    func processAuditDetectsStaleRenderingFlags() {
        let report = RuntimeProcessAuditService.report(from: """
          101 C:\\Program Files\\miHoYo Launcher\\1.16.1.364\\HYP.exe --disable-direct-write --disable-font-subpixel-positioning --disable-features=DWriteFontProxy,UseDWriteCore
          102 C:\\Program Files\\miHoYo Launcher\\1.16.1.364\\HYPHelper --type=renderer --disable-skia-runtime-opts --disable-lcd-text --font-render-hinting=none C:\\users\\alice\\AppData\\Roaming\\miHoYo
          103 C:\\Program Files\\Steam\\Steam.exe -no-cef-sandbox
          104 /Users/alice/project/Mac-Win/refs/build/bin/wine C:\\Tools\\tool.exe
          105 C:\\Program Files\\miHoYo Launcher\\1.16.1.364\\HYPHelper --type=renderer --enable-features=FontSrcLocalMatching --disable-features=CalculateNativeWinOcclusion
          106 /usr/bin/zsh
        """)

        #expect(report.observedProcessCount == 6)
        #expect(report.auditedProcessCount == 5)
        #expect(report.staleRenderingProcessCount == 2)
        #expect(report.entries.first { $0.processIdentifier == 101 }?.kind == .hoYoPlay)
        #expect(report.entries.first { $0.processIdentifier == 103 }?.kind == .steam)
        #expect(report.entries.first { $0.processIdentifier == 104 }?.kind == .wineHost)
        #expect(report.entries.first { $0.processIdentifier == 101 }?.staleRenderingFlags == [
            "disable-direct-write",
            "disable-font-subpixel-positioning",
            "dwrite-font-proxy-disabled",
            "use-dwrite-core-disabled"
        ])
        #expect(report.findings.first?.id == "stale-runtime-rendering-flags")
        #expect(report.findings.first?.affectedProcessIdentifiers == [101, 102])
        #expect(report.findings.first?.flags.contains("disable-lcd-text") == true)
        #expect(report.findings.first?.flags.contains("font-render-hinting-none") == true)
        #expect(report.findings.first?.flags.contains("disable-skia-runtime-opts") == true)
        #expect(report.entries.first { $0.processIdentifier == 105 }?.staleRenderingFlags.isEmpty == true)
        #expect(report.entries.first { $0.processIdentifier == 102 }?.commandPreview.contains(#"C:\users\alice"#) == false)
        #expect(report.entries.first { $0.processIdentifier == 104 }?.commandPreview.contains("/Users/alice") == false)

        let csv = RuntimeProcessAuditReport.csv(report: report)
        #expect(csv.contains("row_type,id,severity,pid,parent_pid,process_state,kind,executable_name,wine_prefix,stale_flags,affected_pids,title,detail,command_preview"))
        #expect(csv.contains("finding,stale-runtime-rendering-flags,high"))
        #expect(csv.contains("101;102"))
        #expect(csv.contains("process,,warning,101,,,hoYoPlay,HYP.exe"))
        #expect(csv.contains("process,,info,103,,,steam,Steam.exe"))
        #expect(csv.contains("/Users/<user>"))
        #expect(!csv.contains("/Users/alice"))
        #expect(!csv.contains(#"C:\users\alice"#))
    }

    @Test("Process audit groups detached Wine system processes by prefix")
    func processAuditGroupsDetachedWineSystemProcessesByPrefix() {
        let prefix = "/Users/alice/Library/Application Support/MacWin/Bottles/game"
        let workingDirectories: [Int32: String] = [
            701: "\(prefix)/drive_c/windows/system32",
            702: "\(prefix)/drive_c/windows/system32",
            703: "\(prefix)/drive_c/windows/system32",
            705: "\(prefix)/drive_c/windows/system32",
            704: "/Users/alice/Library/Application Support/MacWin/Bottles/other/drive_c/Program Files/Example"
        ]
        let report = RuntimeProcessAuditService.report(
            from: """
              701 1 Ss C:\\windows\\system32\\services.exe
              702 1 Ss C:\\windows\\system32\\svchost.exe -k netsvcs
              703 1 Ss C:\\windows\\system32\\explorer.exe /desktop
              704 55 Ss C:\\Program Files\\Example\\Example.exe
              705 1 Ss C:\\windows\\system32\\conhost.exe --unix
            """,
            processWorkingDirectoryProvider: { workingDirectories[$0] }
        )

        #expect(report.detachedWineSystemEntries.map(\.processIdentifier) == [701, 702, 703, 705])
        #expect(report.detachedWinePrefixPaths == [prefix])
        #expect(report.entries(inWinePrefix: prefix).map(\.processIdentifier) == [701, 702, 703, 705])
        #expect(report.entries.first { $0.processIdentifier == 701 }?.parentProcessIdentifier == 1)
        #expect(report.entries.first { $0.processIdentifier == 701 }?.winePrefixDisplayName == "game")
        #expect(report.entries.first { $0.processIdentifier == 704 }?.isDetachedWineSystemProcess == false)

        let finding = report.findings.first { $0.id == "detached-wine-system-processes" }
        #expect(finding?.severity == "high")
        #expect(finding?.affectedProcessIdentifiers == [701, 702, 703, 705])
        #expect(finding?.flags == ["detached-system-process-count-4", "wine-prefix-count-1"])

        let csv = RuntimeProcessAuditReport.csv(report: report)
        #expect(csv.contains("/Users/<user>/Library/Application Support/MacWin/Bottles/game"))
        #expect(!csv.contains("/Users/alice"))
    }

    @Test("Detached Wine process detection requires launchd parent and a drive C working directory")
    func detachedWineProcessDetectionAvoidsFalsePositives() {
        let report = RuntimeProcessAuditService.report(
            from: """
              711 44 Ss C:\\windows\\system32\\services.exe
              712 1 Ss C:\\windows\\system32\\svchost.exe
              713 1 Ss C:\\Program Files\\Example\\Example.exe
              714 1 Ss C:\\windows\\system32\\rpcss.exe
            """,
            processWorkingDirectoryProvider: { pid in
                switch pid {
                case 711:
                    "/Users/alice/Library/Application Support/MacWin/Bottles/game/drive_c/windows/system32"
                case 712:
                    "/private/tmp/not-a-wine-prefix"
                case 713, 714:
                    "/Users/alice/Library/Application Support/MacWin/Bottles/game/drive_c/Program Files/Example"
                default:
                    nil
                }
            }
        )

        #expect(report.detachedWineSystemEntries.isEmpty)
        #expect(report.findings.allSatisfy { $0.id != "detached-wine-system-processes" })
    }

    @Test("Runtime terminator targets detached system processes in one exact Wine prefix")
    func runtimeTerminatorTargetsOneDetachedWinePrefix() {
        let firstPrefix = "/Users/alice/Library/Application Support/MacWin/Bottles/first"
        let secondPrefix = "/Users/alice/Library/Application Support/MacWin/Bottles/second"
        let workingDirectories: [Int32: String] = [
            721: "\(firstPrefix)/drive_c/windows/system32",
            722: "\(firstPrefix)/drive_c/windows/system32",
            723: "\(secondPrefix)/drive_c/Program Files/Example",
            724: "\(secondPrefix)/drive_c/windows/system32"
        ]
        let report = RuntimeProcessAuditService.report(
            from: """
              721 1 Ss C:\\windows\\system32\\services.exe
              722 1 Ss C:\\windows\\system32\\winedevice.exe
              723 1 Ss C:\\Program Files\\Example\\Example.exe
              724 1 Ss C:\\windows\\system32\\rpcss.exe
            """,
            processWorkingDirectoryProvider: { workingDirectories[$0] }
        )
        let recorder = RuntimeTerminatorTestRecorder()
        let terminator = RuntimeProcessTerminator { pid in
            recorder.append(pid)
            return true
        }

        let result = terminator.terminateDetachedWineSystemProcesses(
            in: report,
            winePrefixPath: firstPrefix + "/"
        )

        #expect(recorder.values == [721, 722])
        #expect(result.requestedCount == 2)
        #expect(result.stoppedProcessIdentifiers == [721, 722])
        #expect(result.failedProcessIdentifiers.isEmpty)
    }

    @Test("Process audit ignores unrelated host processes")
    func processAuditIgnoresUnrelatedProcesses() {
        let report = RuntimeProcessAuditService.report(from: """
          201 /usr/bin/login
          202 /Applications/Codex.app/Contents/MacOS/Codex
        """)

        #expect(report.observedProcessCount == 2)
        #expect(report.auditedProcessCount == 0)
        #expect(report.entries.isEmpty)
        #expect(report.findings.isEmpty)
    }

    @Test("Process audit reports uninterruptible Rosetta wineservers")
    func processAuditReportsUninterruptibleRosettaWineservers() {
        let report = RuntimeProcessAuditService.report(from: """
          70066 U /Users/alice/project/Mac-Win/refs/Whisky-x86_64-game-build/server/wineserver -k
          72150 U /Users/alice/project/Mac-Win/refs/Whisky-wow64-game-build/server/wineserver -k
          72151 S /Users/alice/project/Mac-Win/refs/Whisky-wow64-game-build/server/wineserver
          72152 R /usr/bin/login
        """)

        let finding = report.findings.first { $0.id == "rosetta-wine-runtime-uninterruptible" }
        #expect(finding?.severity == "high")
        #expect(finding?.affectedProcessIdentifiers == [70066, 72150])
        #expect(finding?.flags == ["uninterruptible-wine-runtime", "rosetta-translation-stall"])
        #expect(report.uninterruptibleProcessIdentifiers == [70066, 72150])
        #expect(report.stoppableProcessIdentifiers == [72151])
        #expect(report.entries.first { $0.processIdentifier == 70066 }?.processState == "U")

        let recorder = RuntimeTerminatorTestRecorder()
        let termination = RuntimeProcessTerminator { pid in
            recorder.append(pid)
            return true
        }.terminateAllRuntimeProcesses(in: report)
        #expect(recorder.values == [72151])
        #expect(termination.requestedCount == 1)

        let csv = RuntimeProcessAuditReport.csv(report: report)
        #expect(csv.contains("process,,info,70066,,U,wineHost,wineserver"))
    }

    @Test("Process audit ignores source control scanners that mention Windows files")
    func processAuditIgnoresSourceControlScannersThatMentionWindowsFiles() {
        let report = RuntimeProcessAuditService.report(from: """
          211 /Applications/Xcode.app/Contents/Developer/usr/bin/git -c core.fsmonitor= add -- refs/prefixes/game/drive_c/windows/system32/services.exe tmp/wow64-smoke-prefix/drive_c/windows/system32/wineboot.exe
          212 /opt/homebrew/bin/rg -i wine tmp/win32-prefix/drive_c/windows/system32/explorer.exe
          213 /usr/bin/find tmp -name *.exe
          214 /Users/alice/project/Mac-Win/refs/build/bin/wine C:\\Tools\\real.exe
        """)

        #expect(report.observedProcessCount == 4)
        #expect(report.auditedProcessCount == 1)
        #expect(report.entries.first?.processIdentifier == 214)
        #expect(report.entries.first?.kind == .wineHost)
    }

    @Test("Process audit ignores shell probes that mention Windows apps")
    func processAuditIgnoresShellProbesThatMentionWindowsApps() {
        let report = RuntimeProcessAuditService.report(from: """
          221 /bin/zsh -c ps axeww -o pid,command | rg -i 'LenovoAppStore|LeAppStore|Androws|CefRendererProcess'
          222 rg -i LenovoAppStore|LeAppStore|Androws|CefRendererProcess ALL_PROXY=socks5://127.0.0.1:7897
          223 awk /LenovoAppStore/ {print}
          224 C:\\Program Files (x86)\\Lenovo\\LeAppStore\\LenovoServiceAS.exe
        """)

        #expect(report.observedProcessCount == 4)
        #expect(report.auditedProcessCount == 1)
        #expect(report.entries.first?.processIdentifier == 224)
        #expect(report.entries.first?.kind == .lenovoAppStore)
    }

    @Test("Process audit reports repeated Wine-managed process floods")
    func processAuditReportsProcessFloods() {
        let report = RuntimeProcessAuditService.report(from: """
          301 /Users/alice/project/Mac-Win/refs/build/bin/wine C:\\Apps\\App1.exe
          302 /Users/alice/project/Mac-Win/refs/build/bin/wine C:\\Apps\\App2.exe
          303 /Users/alice/project/Mac-Win/refs/build/bin/wine C:\\Apps\\App3.exe
          304 /Users/alice/project/Mac-Win/refs/build/bin/wine C:\\Apps\\App4.exe
          305 /Users/alice/project/Mac-Win/refs/build/bin/wine C:\\Apps\\App5.exe
          306 /Users/alice/project/Mac-Win/refs/build/bin/wine C:\\Apps\\App6.exe
          307 /Users/alice/project/Mac-Win/refs/build/bin/wine C:\\Apps\\App7.exe
          308 /Users/alice/project/Mac-Win/refs/build/bin/wine C:\\Apps\\App8.exe
        """)

        #expect(report.auditedProcessCount == 8)
        #expect(report.findings.first { $0.id == "managed-runtime-process-flood" }?.severity == "medium")
        #expect(report.findings.first { $0.id == "managed-runtime-process-flood" }?.affectedProcessIdentifiers == [
            301, 302, 303, 304, 305, 306, 307, 308
        ])
        #expect(report.findings.first { $0.id == "managed-runtime-process-flood" }?.flags == ["process-count-8"])
        #expect(report.stoppableProcessIdentifiers == [301, 302, 303, 304, 305, 306, 307, 308])
    }

    @Test("Process audit reports Wine virtual desktop focus contention")
    func processAuditReportsWineVirtualDesktopFocusContention() {
        let report = RuntimeProcessAuditService.report(from: """
          331 C:\\windows\\system32\\explorer.exe /desktop
          332 C:\\windows\\system32\\explorer.exe /desktop=MacWin-Windows-11,1280x720
          333 C:\\windows\\system32\\winedevice.exe
          334 /usr/bin/login
        """)

        let finding = report.findings.first { $0.id == "wine-virtual-desktop-focus-contention" }
        #expect(finding?.severity == "high")
        #expect(finding?.affectedProcessIdentifiers == [331, 332])
        #expect(finding?.flags == ["virtual-desktop-count-2"])
        #expect(report.entries.filter(\.isWineVirtualDesktop).map(\.processIdentifier) == [331, 332])
        #expect(report.entries.first { $0.processIdentifier == 333 }?.kind == .wineHost)
        #expect(report.entries.first { $0.processIdentifier == 333 }?.isWineDeviceService == true)
    }

    @Test("Runtime terminator targets only Wine desktops and device services")
    func runtimeTerminatorTargetsOnlyWineDesktopsAndDeviceServices() {
        let report = RuntimeProcessAuditService.report(from: """
          331 C:\\windows\\system32\\explorer.exe /desktop
          332 C:\\windows\\system32\\explorer.exe /desktop=MacWin-Windows-11,1280x720
          333 C:\\windows\\system32\\winedevice.exe
          334 C:\\Program Files\\Example\\Example.exe
          335 /usr/bin/login
        """)
        let recorder = RuntimeTerminatorTestRecorder()
        let terminator = RuntimeProcessTerminator { pid in
            recorder.append(pid)
            return pid != 332
        }

        let result = terminator.terminateWineVirtualDesktopProcesses(in: report)

        #expect(recorder.values == [331, 332, 333])
        #expect(result.requestedCount == 3)
        #expect(result.stoppedProcessIdentifiers == [331, 333])
        #expect(result.failedProcessIdentifiers == [332])
    }

    @Test("Process audit reports one Wine virtual desktop as focus contention")
    func processAuditReportsSingleWineVirtualDesktopFocusContention() {
        let report = RuntimeProcessAuditService.report(from: """
          341 C:\\windows\\system32\\explorer.exe /desktop=MacWin-Windows-11,1280x720
          342 /usr/bin/login
        """)

        let finding = report.findings.first { $0.id == "wine-virtual-desktop-focus-contention" }
        #expect(finding?.severity == "high")
        #expect(finding?.affectedProcessIdentifiers == [341])
        #expect(finding?.flags == ["virtual-desktop-count-1"])
        #expect(report.entries.filter(\.isWineVirtualDesktop).map(\.processIdentifier) == [341])
    }

    @Test("Process audit reports Lenovo CEF forced GPU child")
    func processAuditReportsLenovoCEFForcedGPUChild() {
        let report = RuntimeProcessAuditService.report(from: """
          361 C:\\Program Files (x86)\\Lenovo\\LeAppStore\\LenovoAppStore.exe --no-sandbox
          362 C:\\Program Files (x86)\\Lenovo\\LeAppStore\\LenovoAppStore.exe --type=gpu-process --disable-gpu-rasterization --user-data-dir=C:\\users\\alice\\AppData\\Local\\lenovo\\LeAppStore\\storecache --gpu-preferences=WAAAA --use-gl=angle --use-angle=swiftshader-webgl
          363 C:\\Program Files (x86)\\Lenovo\\LeAppStore\\LenovoAppStore.exe --type=renderer --user-data-dir=C:\\users\\alice\\AppData\\Local\\lenovo\\LeAppStore\\storecache
          364 /usr/bin/login
        """)

        let finding = report.findings.first { $0.id == "lenovo-cef-forced-gpu-child" }
        #expect(finding?.severity == "high")
        #expect(finding?.affectedProcessIdentifiers == [362])
        #expect(finding?.flags == ["cef-gpu-process", "swiftshader-webgl"])
        #expect(finding?.detail.contains("Single-process and in-process-gpu probes crash earlier") == true)
        #expect(report.entries.first { $0.processIdentifier == 362 }?.kind == .lenovoAppStore)
        #expect(report.entries.first { $0.processIdentifier == 362 }?.commandPreview.contains(#"C:\users\alice"#) == false)
    }

    @Test("Process audit reports duplicate manager instances separately from Wine apps")
    func processAuditReportsDuplicateManagerInstances() {
        let report = RuntimeProcessAuditService.report(from: """
          351 /Users/alice/project/Mac-Win/MacWinManager/dist/MacWin Manager.app/Contents/MacOS/MacWinManagerApp
          352 /Users/alice/project/Mac-Win/MacWinManager/dist/MacWin Manager.app/Contents/MacOS/MacWinManagerApp /Users/alice/Downloads/Tool.exe
          353 /Users/alice/project/Mac-Win/refs/build/bin/wine C:\\Apps\\Game.exe
        """)

        #expect(report.auditedProcessCount == 1)
        #expect(report.entries.first?.processIdentifier == 353)
        let finding = report.findings.first { $0.id == "macwin-manager-duplicate-instances" }
        #expect(finding?.severity == "medium")
        #expect(finding?.affectedProcessIdentifiers == [351, 352])
        #expect(finding?.flags == ["manager-instance-count-2"])
    }

    @Test("Process audit ignores MacWin command line tool invocations when checking duplicate managers")
    func processAuditIgnoresCommandLineToolInvocationsForDuplicateManagers() {
        let report = RuntimeProcessAuditService.report(from: """
          356 /Users/alice/project/Mac-Win/MacWinManager/dist/MacWin Manager.app/Contents/MacOS/MacWinManagerApp
          357 /Users/alice/project/Mac-Win/MacWinManager/.build/arm64-apple-macosx/debug/MacWinManagerApp --export-runtime-processes
          358 /Users/alice/project/Mac-Win/MacWinManager/.build/arm64-apple-macosx/debug/MacWinManagerApp --export-foundation-status
          361 /Users/alice/project/Mac-Win/MacWinManager/.build/arm64-apple-macosx/debug/MacWinManagerApp --export-foundation-readiness
          359 /Users/alice/project/Mac-Win/MacWinManager/.build/arm64-apple-macosx/debug/MacWinManagerApp --smoke-launcher high-performance-win11 steam 10
          360 /Users/alice/project/Mac-Win/MacWinManager/.build/arm64-apple-macosx/debug/MacWinManagerApp --help
        """)

        #expect(report.entries.isEmpty)
        #expect(!report.findings.contains { $0.id == "macwin-manager-duplicate-instances" })
    }

    @Test("Process audit includes orphaned Lenovo app store services")
    func processAuditIncludesOrphanedLenovoServices() {
        let report = RuntimeProcessAuditService.report(from: """
          371 C:\\Program Files (x86)\\Lenovo\\LeAppStore\\LenovoServiceAS.exe
          372 C:\\Program Files (x86)\\Lenovo\\LenovoInternetSoftwareFramework\\LISFService.exe
          373 /usr/bin/login
        """)

        #expect(report.observedProcessCount == 3)
        #expect(report.auditedProcessCount == 2)
        #expect(report.entries.map(\.processIdentifier) == [371, 372])
        #expect(report.entries.allSatisfy { $0.kind == .lenovoAppStore })
        #expect(report.stoppableProcessIdentifiers == [371, 372])
    }

    @Test("Running executable match recognizes helper processes after launcher parent exits")
    func runningExecutableMatchRecognizesHelpers() {
        let steamMatch = RuntimeProcessAuditService.firstRunningMatch(
            in: """
              401 C:\\Program Files\\Steam\\bin\\cef\\steamwebhelper.exe --type=renderer
              402 /usr/bin/zsh
            """,
            executable: "C:\\Program Files\\Steam\\Steam.exe",
            displayName: "Steam"
        )
        #expect(steamMatch?.processIdentifier == 401)
        #expect(steamMatch?.kind == .steam)

        let hoyoMatch = RuntimeProcessAuditService.firstRunningMatch(
            in: """
              501 C:\\Program Files\\miHoYo Launcher\\1.16.1.364\\HYPHelper.exe --type=gpu-process
              502 /Applications/Finder.app/Contents/MacOS/Finder
            """,
            executable: "C:\\Program Files\\miHoYo Launcher\\1.16.1.364\\HYP.exe",
            displayName: "HoYoPlay"
        )
        #expect(hoyoMatch?.processIdentifier == 501)
        #expect(hoyoMatch?.kind == .hoYoPlay)

        let lenovoMatch = RuntimeProcessAuditService.firstRunningMatch(
            in: """
              521 C:\\Program Files (x86)\\Lenovo\\LenovoInternetSoftwareFramework\\LISFService.exe
              522 /Applications/Finder.app/Contents/MacOS/Finder
            """,
            executable: "C:\\Program Files (x86)\\Lenovo\\LeAppStore\\LenovoAppStore.exe",
            displayName: "联想应用商店"
        )
        #expect(lenovoMatch?.processIdentifier == 521)
        #expect(lenovoMatch?.kind == .lenovoAppStore)
    }

    @Test("Running executable match recognizes generic Windows executables")
    func runningExecutableMatchRecognizesGenericExecutables() {
        let match = RuntimeProcessAuditService.firstRunningMatch(
            in: """
              601 /Users/alice/project/Mac-Win/refs/build/bin/wine C:\\Program Files\\Example Tool\\ExampleTool.exe
              602 /usr/bin/login
            """,
            executable: "C:\\Program Files\\Example Tool\\ExampleTool.exe",
            displayName: "ExampleTool"
        )

        #expect(match?.processIdentifier == 601)
        #expect(match?.kind == .wineHost)
        #expect(match?.commandPreview.contains("/Users/alice") == false)
    }
}

private final class RuntimeTerminatorTestRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [Int32] = []

    var values: [Int32] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func append(_ value: Int32) {
        lock.lock()
        storage.append(value)
        lock.unlock()
    }
}
