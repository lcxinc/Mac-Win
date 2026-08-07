import AppKit
import MacWinCore
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

private extension Color {
    static let macWinSecondaryText = Color(nsColor: .secondaryLabelColor)
}

struct WindowsDesktopView: View {
    @EnvironmentObject private var store: MacWinStore
    var showsHeader = true
    @State private var isStartMenuOpen = false
    @State private var isInstallerDropTargeted = false
    @State private var command = ""
    @State private var arguments = ""
    @State private var searchText = ""

    private let iconColumns = [
        GridItem(.adaptive(minimum: 92, maximum: 112), spacing: 18, alignment: .top)
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            WindowsDesktopWallpaper()

            if let bottle = desktopBottle {
                desktopContent(for: bottle)
            } else {
                EmptyState(systemImage: "display", title: store.text(.noBottleSelected), actionTitle: store.text(.createBottle)) {
                    Task { await store.createBottle(named: store.text(.defaultBottleName)) }
                }
                .padding(.bottom, 64)
            }

            if isInstallerDropTargeted {
                InstallerDropOverlay()
                    .environmentObject(store)
                    .padding(34)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .onDrop(
            of: [UTType.fileURL.identifier],
            isTargeted: $isInstallerDropTargeted
        ) { providers in
            guard let bottle = desktopBottle else { return false }
            return receiveDroppedInstallers(providers, in: bottle)
        }
    }

    @ViewBuilder
    private func desktopContent(for bottle: BottleManifest) -> some View {
        let launchers = bottle.installedApps.filter(\.showInHome)
        let shortcuts = desktopShortcuts(for: bottle, launchers: launchers)

        VStack(spacing: 0) {
            if showsHeader {
                desktopHeader(for: bottle)
            } else {
                Spacer()
                    .frame(height: 12)
            }

            ScrollView {
                LazyVGrid(columns: iconColumns, alignment: .leading, spacing: 18) {
                    ForEach(shortcuts) { shortcut in
                        DesktopShortcutButton(shortcut: shortcut) {
                            perform(shortcut.action)
                        }
                    }
                }
                .padding(.horizontal, 26)
                .padding(.top, 18)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }

            Spacer(minLength: 0)

            if isStartMenuOpen {
                StartMenuPanel(
                    bottle: bottle,
                    launchers: launchers,
                    runningItems: store.runningItems,
                    searchText: $searchText,
                    command: $command,
                    arguments: $arguments,
                    runLauncher: { launcher in
                        isStartMenuOpen = false
                        Task { await store.runLauncher(launcher, in: bottle) }
                    },
                    runCommand: {
                        let trimmedCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedCommand.isEmpty else { return }
                        isStartMenuOpen = false
                        Task { await store.runCommand(trimmedCommand, args: splitArguments(arguments), in: bottle) }
                    },
                    perform: { action in
                        isStartMenuOpen = false
                        perform(action)
                    },
                    openRunningLog: { item in store.openLog(for: item) },
                    terminateRunningItem: { item in store.terminateRunningItem(item) }
                )
                .environmentObject(store)
                .padding(.bottom, 72)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            WindowsTaskbar(
                bottle: bottle,
                launchers: Array(launchers.prefix(6)),
                runningItems: store.runningItems,
                isStartMenuOpen: isStartMenuOpen,
                toggleStart: { withAnimation(.spring(response: 0.24, dampingFraction: 0.88)) { isStartMenuOpen.toggle() } },
                openSearch: { withAnimation(.spring(response: 0.24, dampingFraction: 0.88)) { isStartMenuOpen = true } },
                runLauncher: { launcher in
                    Task { await store.runLauncher(launcher, in: bottle) }
                },
                refreshRunningItems: { store.refreshRunningItems() },
                openRunningLog: { item in store.openLog(for: item) },
                terminateRunningItem: { item in store.terminateRunningItem(item) },
                openLogs: { store.openLogs() },
                openSettings: { store.selection = .settings }
            )
            .environmentObject(store)
            .padding(.horizontal, 18)
            .padding(.bottom, 12)
        }
        .contextMenu {
            Button(store.text(.refreshDesktop)) {
                refreshDesktop()
            }
            Divider()
            Button(store.text(.openCDrive)) {
                store.openDriveC(for: bottle)
            }
            Button(store.text(.openBottleFolder)) {
                store.openBottleDirectory(bottle)
            }
            Button(store.text(.openLogs)) {
                store.openLogs()
            }
            Divider()
            Button(store.text(.market)) {
                store.selection = .market
            }
            Button(store.text(.settings)) {
                store.selection = .settings
            }
        }
        .onAppear {
            store.refreshRunningItems()
        }
    }

    private func desktopHeader(for bottle: BottleManifest) -> some View {
        HStack(spacing: 10) {
            Label(store.text(.desktopSubtitle), systemImage: "display")
                .font(.headline)
                .lineLimit(1)

            Spacer()

            Menu {
                ForEach(store.bottles) { item in
                    Button(item.name) {
                        store.selectedBottleId = item.id
                    }
                }
            } label: {
                Label(bottle.name, systemImage: "shippingbox")
                    .lineLimit(1)
            }

            if let engine = engine(for: bottle) {
                Label(engine.wineVersion, systemImage: "cpu")
                    .lineLimit(1)
            }
        }
        .font(.subheadline)
        .foregroundStyle(.primary)
        .padding(.horizontal, 26)
        .padding(.top, 22)
        .padding(.bottom, 8)
    }

    private var desktopBottle: BottleManifest? {
        store.selectedBottle ?? store.defaultPerformanceBottle ?? store.bottles.first
    }

    private func engine(for bottle: BottleManifest) -> EngineManifest? {
        store.engines.first { $0.id == bottle.engineId } ?? store.engines.first
    }

    private func desktopShortcuts(for bottle: BottleManifest, launchers: [LauncherManifest]) -> [DesktopShortcut] {
        var items = launchers.map {
            DesktopShortcut(
                id: "launcher-\($0.id)",
                title: $0.displayName,
                subtitle: bottle.name,
                systemImage: "play.square.fill",
                action: .launcher(bottle, $0),
                tint: .blue
            )
        }

        items.append(contentsOf: [
            DesktopShortcut(
                id: "this-pc",
                title: store.text(.thisPC),
                subtitle: store.text(.openCDrive),
                systemImage: "desktopcomputer",
                action: .openDriveC(bottle),
                tint: .cyan
            ),
            DesktopShortcut(
                id: "bottle-folder",
                title: store.text(.bottle),
                subtitle: store.text(.openBottleFolder),
                systemImage: "folder.fill",
                action: .openBottle(bottle),
                tint: .yellow
            ),
            DesktopShortcut(
                id: "wine-desktop",
                title: store.text(.windows11Desktop),
                subtitle: store.text(.openRealWineDesktop),
                systemImage: "macwindow",
                action: .wineDesktop(bottle),
                tint: .indigo
            ),
            DesktopShortcut(
                id: "logs",
                title: store.text(.logs),
                subtitle: store.text(.openLogs),
                systemImage: "doc.text.fill",
                action: .openLogs,
                tint: .mint
            ),
            DesktopShortcut(
                id: "market",
                title: store.text(.market),
                subtitle: store.text(.installApps),
                systemImage: "shippingbox.fill",
                action: .openMarket,
                tint: .green
            ),
            DesktopShortcut(
                id: "recycle-bin",
                title: store.text(.recycleBin),
                subtitle: store.text(.bottle),
                systemImage: "trash",
                action: .openBottle(bottle),
                tint: .gray
            )
        ])

        return filtered(items)
    }

    private func filtered(_ items: [DesktopShortcut]) -> [DesktopShortcut] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return items }
        return items.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.subtitle.localizedCaseInsensitiveContains(query)
        }
    }

    private func perform(_ action: DesktopShortcutAction) {
        switch action {
        case .launcher(let bottle, let launcher):
            Task { await store.runLauncher(launcher, in: bottle) }
        case .openDriveC(let bottle):
            store.openDriveC(for: bottle)
        case .openBottle(let bottle):
            store.openBottleDirectory(bottle)
        case .openLogs:
            store.openLogs()
        case .openMarket:
            store.selection = .market
        case .openSettings:
            store.selection = .settings
        case .openDiagnostics:
            store.selection = .diagnostics
        case .runBuiltin(let bottle, let command, let args):
            Task { await store.runCommand(command, args: args, in: bottle) }
        case .wineDesktop(let bottle):
            Task { await store.launchWindows11Desktop(for: bottle) }
        }
    }

    private func splitArguments(_ value: String) -> [String] {
        value.split(separator: " ").map(String.init)
    }

    private func receiveDroppedInstallers(_ providers: [NSItemProvider], in bottle: BottleManifest) -> Bool {
        let fileProviders = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }
        guard !fileProviders.isEmpty else { return false }

        for provider in fileProviders {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                if let error {
                    DispatchQueue.main.async {
                        store.lastError = error.localizedDescription
                    }
                    return
                }

                guard let url = Self.fileURL(from: item) else {
                    DispatchQueue.main.async {
                        store.lastError = store.text(.unsupportedInstallerFile, "drop")
                    }
                    return
                }

                DispatchQueue.main.async {
                    Task {
                        await store.installDroppedInstaller(url, in: bottle)
                    }
                }
            }
        }
        return true
    }

    nonisolated private static func fileURL(from item: NSSecureCoding?) -> URL? {
        if let url = item as? URL {
            return url
        }
        if let data = item as? Data,
           let value = String(data: data, encoding: .utf8) {
            return URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        if let value = item as? String {
            return URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    private func refreshDesktop() {
        do {
            try store.reloadLocalState()
            store.refreshRunningItems()
            store.statusMessage = store.text(.ready)
            store.lastError = nil
        } catch {
            store.lastError = error.localizedDescription
        }
    }
}

struct ImmersiveWorkspaceView: View {
    @EnvironmentObject private var store: MacWinStore
    @State private var isInstallerDropTargeted = false

    private let columns = [
        GridItem(.adaptive(minimum: 118, maximum: 142), spacing: 18, alignment: .top)
    ]

    var body: some View {
        ZStack {
            MacWorkspaceBackground()

            if let bottle = activeBottle {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        immersiveHeader(for: bottle)

                        HStack(alignment: .top, spacing: 18) {
                            VStack(alignment: .leading, spacing: 18) {
                                NativePanel {
                                    VStack(alignment: .leading, spacing: 14) {
                                        HStack {
                                            Label(store.text(.runningApps), systemImage: "rectangle.3.group")
                                                .font(.headline)
                                            Spacer()
                                            Button {
                                                store.refreshRunningItems()
                                            } label: {
                                                Image(systemName: "arrow.clockwise")
                                                    .frame(width: 28, height: 26)
                                            }
                                            .buttonStyle(.plain)
                                            .help(store.text(.refreshDesktop))
                                        }

                                        if store.runningItems.isEmpty {
                                            Text(store.text(.noRunningApps))
                                                .font(.callout)
                                                .foregroundStyle(Color.macWinSecondaryText)
                                                .frame(maxWidth: .infinity, minHeight: 86)
                                        } else {
                                            VStack(spacing: 8) {
                                                ForEach(store.runningItems) { item in
                                                    RunningProcessRow(
                                                        item: item,
                                                        openLog: { store.openLog(for: item) },
                                                        terminate: { store.terminateRunningItem(item) }
                                                    )
                                                    .environmentObject(store)
                                                }
                                            }
                                        }
                                    }
                                }

                                NativePanel {
                                    VStack(alignment: .leading, spacing: 18) {
                                        HStack {
                                            Label(store.text(.applications), systemImage: "square.grid.2x2")
                                                .font(.headline)
                                            Spacer()
                                            Button {
                                                store.selection = .market
                                            } label: {
                                                Label(store.text(.installApps), systemImage: "plus")
                                            }
                                            .buttonStyle(.bordered)
                                        }

                                        let launchers = bottle.installedApps.filter(\.showInHome)
                                        if launchers.isEmpty {
                                            Text(store.text(.noLaunchersYet))
                                                .font(.callout)
                                                .foregroundStyle(Color.macWinSecondaryText)
                                                .frame(maxWidth: .infinity, minHeight: 112)
                                        } else {
                                            LazyVGrid(columns: columns, alignment: .leading, spacing: 22) {
                                                ForEach(launchers) { launcher in
                                                    ImmersiveAppTile(
                                                        launcher: launcher,
                                                        iconPath: launcher.iconPath,
                                                        systemImage: launcherSystemImage(for: launcher),
                                                        tint: launcherTint(for: launcher)
                                                    ) {
                                                        Task { await store.runLauncher(launcher, in: bottle) }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 18) {
                                NativePanel {
                                    VStack(alignment: .leading, spacing: 14) {
                                        Label(store.text(.currentBottle), systemImage: "shippingbox")
                                            .font(.headline)
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(bottle.name)
                                                .font(.title3.weight(.semibold))
                                                .lineLimit(2)
                                            Text("\(bottle.windowsVersion) · \(bottle.arch.rawValue)")
                                                .foregroundStyle(Color.macWinSecondaryText)
                                        }

                                        Divider()

                                        if let engine = engine(for: bottle) {
                                            Label(engine.wineVersion, systemImage: "cpu")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(Color.macWinSecondaryText)
                                                .lineLimit(1)
                                        }

                                        Button {
                                            Task { await store.launchWindows11Desktop(for: bottle) }
                                        } label: {
                                            Label(store.text(.openRealWineDesktop), systemImage: "macwindow")
                                                .frame(maxWidth: .infinity)
                                        }
                                        .buttonStyle(.bordered)
                                        .disabled(bottle.windowsVersion != "win11")
                                    }
                                }

                                NativePanel {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Label(store.text(.quickAccess), systemImage: "bolt")
                                            .font(.headline)
                                        ImmersiveToolButton(title: store.text(.openCDrive), systemImage: "externaldrive") {
                                            store.openDriveC(for: bottle)
                                        }
                                        ImmersiveToolButton(title: store.text(.openBottleFolder), systemImage: "folder") {
                                            store.openBottleDirectory(bottle)
                                        }
                                        ImmersiveToolButton(title: store.text(.wineConfiguration), systemImage: "slider.horizontal.3") {
                                            Task { await store.runCommand("winecfg", args: [], in: bottle) }
                                        }
                                        ImmersiveToolButton(title: store.text(.openLogs), systemImage: "doc.text.magnifyingglass") {
                                            store.openLogs()
                                        }
                                        ImmersiveToolButton(title: store.text(.diagnostics), systemImage: "stethoscope") {
                                            store.selection = .diagnostics
                                        }
                                    }
                                }
                            }
                            .frame(width: 310)
                        }
                    }
                    .padding(24)
                }
            } else {
                EmptyState(systemImage: "rectangle.3.group", title: store.text(.noBottleSelected), actionTitle: store.text(.createBottle)) {
                    Task { await store.createBottle(named: store.text(.defaultBottleName)) }
                }
            }

            if isInstallerDropTargeted {
                InstallerDropOverlay()
                    .environmentObject(store)
                    .padding(34)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isInstallerDropTargeted) { providers in
            guard let bottle = activeBottle else { return false }
            return receiveDroppedInstallers(providers, in: bottle)
        }
        .onAppear {
            store.refreshRunningItems()
        }
    }

    private func immersiveHeader(for bottle: BottleManifest) -> some View {
        HStack(spacing: 12) {
            Label(store.text(.desktopMode), systemImage: "rectangle.3.group")
                .font(.system(size: 30, weight: .bold))
            Text(store.text(.desktopSubtitle))
                .font(.title3)
                .foregroundStyle(Color.macWinSecondaryText)
                .lineLimit(1)
            Spacer()
            Label(bottle.name, systemImage: "shippingbox")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.macWinSecondaryText)
                .lineLimit(1)
        }
        .padding(.top, 4)
    }

    private var activeBottle: BottleManifest? {
        store.selectedBottle ?? store.defaultPerformanceBottle ?? store.bottles.first
    }

    private func engine(for bottle: BottleManifest) -> EngineManifest? {
        store.engines.first { $0.id == bottle.engineId } ?? store.engines.first
    }

    private func receiveDroppedInstallers(_ providers: [NSItemProvider], in bottle: BottleManifest) -> Bool {
        let fileProviders = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }
        guard !fileProviders.isEmpty else { return false }

        for provider in fileProviders {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                if let error {
                    DispatchQueue.main.async {
                        store.lastError = error.localizedDescription
                    }
                    return
                }

                guard let url = Self.fileURL(from: item) else {
                    DispatchQueue.main.async {
                        store.lastError = store.text(.unsupportedInstallerFile, "drop")
                    }
                    return
                }

                DispatchQueue.main.async {
                    Task { await store.installDroppedInstaller(url, in: bottle) }
                }
            }
        }
        return true
    }

    nonisolated private static func fileURL(from item: NSSecureCoding?) -> URL? {
        if let url = item as? URL {
            return url
        }
        if let data = item as? Data,
           let value = String(data: data, encoding: .utf8) {
            return URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        if let value = item as? String {
            return URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}

struct AppLauncherView: View {
    @EnvironmentObject private var store: MacWinStore
    @State private var selectedCategory: AppLauncherCategory = .all
    @State private var isInstallerDropTargeted = false

    private let iconColumns = [
        GridItem(.adaptive(minimum: 118, maximum: 142), spacing: 22, alignment: .top)
    ]

    var body: some View {
        ZStack {
            MacWorkspaceBackground()

            if store.isBusy && store.bottles.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)
                    Text(store.statusMessage)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let bottle = activeBottle {
                VStack(alignment: .leading, spacing: 0) {
                    appHeader(for: bottle)
                    categoryBar.padding(.bottom, 12)

                    ScrollView {
                        LazyVGrid(columns: iconColumns, alignment: .leading, spacing: 28) {
                            ForEach(filteredItems(for: bottle)) { item in
                                AppLauncherButton(item: item) {
                                    perform(item.action)
                                }
                            }
                        }
                        .padding(.horizontal, 36)
                        .padding(.top, 20)
                        .padding(.bottom, 34)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
            } else {
                EmptyState(systemImage: "square.grid.2x2", title: store.text(.noBottleSelected), actionTitle: store.text(.createBottle)) {
                    Task { await store.createBottle(named: store.text(.defaultBottleName)) }
                }
            }

            if isInstallerDropTargeted {
                InstallerDropOverlay()
                    .environmentObject(store)
                    .padding(34)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isInstallerDropTargeted) { providers in
            guard let bottle = activeBottle else { return false }
            return receiveDroppedInstallers(providers, in: bottle)
        }
        .onAppear {
            store.refreshRunningItems()
        }
    }

    private func appHeader(for bottle: BottleManifest) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Text(store.text(.applications))
                .font(.system(size: 28, weight: .semibold))
            Text(store.text(.appLauncherSubtitle))
                .font(.callout)
                .foregroundStyle(Color.macWinSecondaryText)
                .lineLimit(1)
            Spacer()
            Label(bottle.name, systemImage: "shippingbox")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.macWinSecondaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, 28)
        .padding(.top, 22)
        .padding(.bottom, 16)
    }

    private var categoryBar: some View {
        Picker("", selection: $selectedCategory) {
            ForEach(AppLauncherCategory.allCases) { category in
                Text(category.title(in: store))
                    .tag(category)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .controlSize(.large)
        .padding(.horizontal, 28)
        .padding(.bottom, 18)
    }

    private var activeBottle: BottleManifest? {
        store.selectedBottle ?? store.defaultPerformanceBottle ?? store.bottles.first
    }

    private func items(for bottle: BottleManifest) -> [AppLauncherItem] {
        var items = bottle.installedApps.filter(\.showInHome).map { launcher in
            AppLauncherItem(
                id: "launcher-\(launcher.id)",
                title: launcher.displayName,
                subtitle: bottle.name,
                iconPath: launcher.iconPath,
                systemImage: launcherSystemImage(for: launcher),
                category: launcherCategory(for: launcher),
                action: .launcher(bottle, launcher),
                tint: launcherTint(for: launcher)
            )
        }

        items.append(contentsOf: [
            AppLauncherItem(
                id: "this-pc",
                title: store.text(.thisPC),
                subtitle: store.text(.openCDrive),
                iconPath: nil,
                systemImage: "desktopcomputer",
                category: .utilities,
                action: .openDriveC(bottle),
                tint: .cyan
            ),
            AppLauncherItem(
                id: "bottle-folder",
                title: store.text(.bottle),
                subtitle: store.text(.openBottleFolder),
                iconPath: nil,
                systemImage: "folder.fill",
                category: .utilities,
                action: .openBottle(bottle),
                tint: .yellow
            ),
            AppLauncherItem(
                id: "wine-desktop",
                title: store.text(.openRealWineDesktop),
                subtitle: store.text(.desktopMode),
                iconPath: nil,
                systemImage: "macwindow",
                category: .utilities,
                action: .wineDesktop(bottle),
                tint: .indigo
            ),
            AppLauncherItem(
                id: "winecfg",
                title: store.text(.wineConfiguration),
                subtitle: store.text(.tools),
                iconPath: nil,
                systemImage: "slider.horizontal.3",
                category: .utilities,
                action: .runBuiltin(bottle, "winecfg", []),
                tint: .indigo
            ),
            AppLauncherItem(
                id: "regedit",
                title: store.text(.registryEditor),
                subtitle: store.text(.tools),
                iconPath: nil,
                systemImage: "list.bullet.rectangle",
                category: .utilities,
                action: .runBuiltin(bottle, "regedit", []),
                tint: .teal
            ),
            AppLauncherItem(
                id: "cmd",
                title: store.text(.commandPrompt),
                subtitle: store.text(.tools),
                iconPath: nil,
                systemImage: "terminal",
                category: .utilities,
                action: .runBuiltin(bottle, "cmd", []),
                tint: .blue
            ),
            AppLauncherItem(
                id: "logs",
                title: store.text(.logs),
                subtitle: store.text(.openLogs),
                iconPath: nil,
                systemImage: "doc.text.fill",
                category: .utilities,
                action: .openLogs,
                tint: .mint
            ),
            AppLauncherItem(
                id: "market",
                title: store.text(.market),
                subtitle: store.text(.installApps),
                iconPath: nil,
                systemImage: "bag.fill",
                category: .market,
                action: .openMarket,
                tint: .green
            ),
            AppLauncherItem(
                id: "diagnostics",
                title: store.text(.diagnostics),
                subtitle: store.text(.runProbeSuite),
                iconPath: nil,
                systemImage: "stethoscope",
                category: .diagnostics,
                action: .openDiagnostics,
                tint: .orange
            )
        ])

        return items
    }

    private func filteredItems(for bottle: BottleManifest) -> [AppLauncherItem] {
        let items = items(for: bottle)
        guard selectedCategory != .all else { return items }
        return items.filter { $0.category == selectedCategory }
    }

    private func perform(_ action: DesktopShortcutAction) {
        switch action {
        case .launcher(let bottle, let launcher):
            Task { await store.runLauncher(launcher, in: bottle) }
        case .openDriveC(let bottle):
            store.openDriveC(for: bottle)
        case .openBottle(let bottle):
            store.openBottleDirectory(bottle)
        case .openLogs:
            store.openLogs()
        case .openMarket:
            store.selection = .market
        case .openSettings:
            store.selection = .settings
        case .openDiagnostics:
            store.selection = .diagnostics
        case .runBuiltin(let bottle, let command, let args):
            Task { await store.runCommand(command, args: args, in: bottle) }
        case .wineDesktop(let bottle):
            Task { await store.launchWindows11Desktop(for: bottle) }
        }
    }

    private func receiveDroppedInstallers(_ providers: [NSItemProvider], in bottle: BottleManifest) -> Bool {
        let fileProviders = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }
        guard !fileProviders.isEmpty else { return false }

        for provider in fileProviders {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                if let error {
                    DispatchQueue.main.async {
                        store.lastError = error.localizedDescription
                    }
                    return
                }

                guard let url = Self.fileURL(from: item) else {
                    DispatchQueue.main.async {
                        store.lastError = store.text(.unsupportedInstallerFile, "drop")
                    }
                    return
                }

                DispatchQueue.main.async {
                    Task { await store.installDroppedInstaller(url, in: bottle) }
                }
            }
        }
        return true
    }

    nonisolated private static func fileURL(from item: NSSecureCoding?) -> URL? {
        if let url = item as? URL {
            return url
        }
        if let data = item as? Data,
           let value = String(data: data, encoding: .utf8) {
            return URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        if let value = item as? String {
            return URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

}

private enum AppLauncherCategory: String, CaseIterable, Identifiable {
    case all
    case apps
    case games
    case utilities
    case market
    case diagnostics
    case other

    var id: String { rawValue }

    @MainActor
    func title(in store: MacWinStore) -> String {
        switch self {
        case .all: store.text(.allApps)
        case .apps: store.text(.applications)
        case .games: store.text(.games)
        case .utilities: store.text(.utilities)
        case .market: store.text(.market)
        case .diagnostics: store.text(.diagnostics)
        case .other: store.text(.other)
        }
    }
}

private struct AppLauncherItem: Identifiable {
    var id: String
    var title: String
    var subtitle: String
    var iconPath: String?
    var systemImage: String
    var category: AppLauncherCategory
    var action: DesktopShortcutAction
    var tint: Color
}

private struct AppLauncherButton: View {
    var item: AppLauncherItem
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                LauncherIconView(
                    title: item.title,
                    iconPath: item.iconPath,
                    systemImage: item.systemImage,
                    tint: item.tint,
                    size: 78
                )

                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .frame(width: 118, height: 38, alignment: .top)
            }
            .frame(width: 124, height: 126, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("\(item.title) - \(item.subtitle)")
    }
}

private struct ImmersiveAppTile: View {
    var launcher: LauncherManifest
    var iconPath: String?
    var systemImage: String
    var tint: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                LauncherIconView(
                    title: launcher.displayName,
                    iconPath: iconPath,
                    systemImage: systemImage,
                    tint: tint,
                    size: 70
                )
                Text(launcher.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .frame(width: 108, height: 34, alignment: .top)
            }
            .frame(width: 118, height: 116)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(launcher.displayName)
    }
}

private struct ImmersiveToolButton: View {
    var title: String
    var systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 10)
            .frame(height: 36)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

private struct NativePanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.72), lineWidth: 1)
            }
    }
}

struct LauncherIconView: View {
    var title: String
    var iconPath: String?
    var systemImage: String
    var tint: Color
    var size: CGFloat

    @ViewBuilder
    var body: some View {
        Group {
            if let nsImage = extractedIcon {
                Image(nsImage: nsImage)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .padding(size * 0.04)
            } else if let builtInIcon {
                Image(nsImage: builtInIcon)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .padding(size * 0.03)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: min(size * 0.23, 18), style: .continuous)
                        .fill(iconShellBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: min(size * 0.23, 18), style: .continuous)
                                .stroke(Color(nsColor: .separatorColor).opacity(0.72), lineWidth: 0.8)
                        }

                    MacWinFallbackIcon(systemImage: systemImage, tint: tint, size: size)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(Text(title))
    }

    private var extractedIcon: NSImage? {
        guard let iconPath else { return nil }
        return Self.imageFromIconPath(iconPath)
    }

    private static func imageFromIconPath(_ iconPath: String) -> NSImage? {
        let url = URL(fileURLWithPath: iconPath)

        if let iconImage = NSImage(contentsOf: url) {
            return iconImage
        }

        guard let data = try? Data(contentsOf: url),
              let iconImage = imageFromICOData(data) else {
            return nil
        }
        return iconImage
    }

    private static func imageFromICOData(_ data: Data) -> NSImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return nil }

        var selectedImage: CGImage?
        var selectedArea = 0

        for index in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else {
                continue
            }

            let area = Int(cgImage.width) * Int(cgImage.height)
            if area > selectedArea {
                selectedArea = area
                selectedImage = cgImage
            }
        }

        guard let cgImage = selectedImage ?? CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }

        return NSImage(
            cgImage: cgImage,
            size: CGSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
        )
    }

    private var builtInIcon: NSImage? {
        guard let assetName = MacWinBuiltInIconAssets.assetName(for: systemImage, title: title),
              let url = Bundle.module.url(
                forResource: assetName,
                withExtension: "png",
                subdirectory: "Icons/BuiltIn"
              ) else {
            return nil
        }
        return NSImage(contentsOf: url)
    }

    private var iconShellBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(nsColor: .windowBackgroundColor).opacity(0.95),
                Color(nsColor: .controlBackgroundColor).opacity(0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private enum MacWinBuiltInIconAssets {
    static func assetName(for systemImage: String, title: String) -> String? {
        let normalizedTitle = title.lowercased()
        if normalizedTitle.contains("pdf") {
            return "MacWinPDF"
        }
        if normalizedTitle.contains("visual studio")
            || normalizedTitle.contains("developer")
            || normalizedTitle.contains("开发") {
            return "MacWinDeveloper"
        }
        if normalizedTitle.contains("wechat")
            || normalizedTitle.contains("微信")
            || normalizedTitle.contains("qq") {
            return "MacWinChat"
        }
        if normalizedTitle.contains("cad")
            || normalizedTitle.contains("solidworks")
            || normalizedTitle.contains("kicad")
            || normalizedTitle.contains("altium")
            || normalizedTitle.contains("工程制图") {
            return "MacWinCAD"
        }
        if normalizedTitle.contains("database")
            || normalizedTitle.contains("sqlite")
            || normalizedTitle.contains("mysql")
            || normalizedTitle.contains("数据库") {
            return "MacWinDatabase"
        }
        if normalizedTitle.contains("security")
            || normalizedTitle.contains("antivirus")
            || normalizedTitle.contains("安全") {
            return "MacWinSecurity"
        }

        return switch systemImage {
        case "app", "app.fill", "play.square", "play.square.fill":
            "MacWinApp"
        case "safari", "safari.fill", "globe", "network":
            "MacWinBrowser"
        case "doc", "doc.fill", "doc.richtext", "doc.richtext.fill", "tablecells", "calendar":
            "MacWinOffice"
        case "wrench.and.screwdriver", "wrench.and.screwdriver.fill", "hammer", "gearshape.2":
            "MacWinIndustrial"
        case "shippingbox.and.arrow.backward", "shippingbox.and.arrow.backward.fill", "arrow.down.app", "arrow.down.app.fill":
            "MacWinInstaller"
        case "play.rectangle", "play.rectangle.fill", "music.note", "photo":
            "MacWinMedia"
        case "desktopcomputer", "externaldrive", "internaldrive":
            "MacWinDrive"
        case "folder", "folder.fill", "shippingbox", "shippingbox.fill":
            "MacWinBottle"
        case "macwindow", "display":
            "MacWinDesktop"
        case "slider.horizontal.3", "gearshape", "gearshape.fill":
            "MacWinSettings"
        case "list.bullet.rectangle", "list.bullet.rectangle.fill":
            "MacWinRegistry"
        case "doc.text.fill", "doc.text.magnifyingglass":
            "MacWinLogs"
        case "waveform.path.ecg.rectangle", "waveform.path.ecg.rectangle.fill", "stethoscope":
            "MacWinDiagnostics"
        case "square.stack.3d.up.fill", "bag", "bag.fill":
            "MacWinMarket"
        case "gamecontroller", "gamecontroller.fill":
            "MacWinGame"
        case "sparkles":
            "MacWinGame"
        case "terminal", "terminal.fill":
            "MacWinTerminal"
        case "ruler", "ruler.fill":
            "MacWinCAD"
        case "cylinder", "cylinder.fill", "cylinder.split.1x2", "cylinder.split.1x2.fill":
            "MacWinDatabase"
        case "lock.shield", "lock.shield.fill", "checkmark.shield", "checkmark.shield.fill":
            "MacWinSecurity"
        case "arrow.down.circle", "arrow.down.circle.fill", "tray.and.arrow.down", "tray.and.arrow.down.fill":
            "MacWinDownload"
        case "checkmark.circle", "checkmark.circle.fill", "checklist":
            "MacWinProductivity"
        default:
            "MacWinApp"
        }
    }
}

private struct MacWinFallbackIcon: View {
    var systemImage: String
    var tint: Color
    var size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: min(size * 0.21, 17), style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(nsColor: .controlBackgroundColor).opacity(0.92),
                            tint.opacity(0.18),
                            Color(nsColor: .underPageBackgroundColor)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: systemImage)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(tint)
        }
        .padding(size * 0.08)
    }
}

private struct MacWorkspaceBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(nsColor: .windowBackgroundColor),
                Color(nsColor: .controlBackgroundColor),
                Color(nsColor: .underPageBackgroundColor)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private func launcherSystemImage(for launcher: LauncherManifest) -> String {
    let token = "\(launcher.id) \(launcher.displayName) \(launcher.exePath)".lowercased()
    if token.contains("steam") { return "gamecontroller.fill" }
    if token.contains("hoyo") || token.contains("mihoyo") || token.contains("米哈游") { return "sparkles" }
    if token.contains("itch") { return "shippingbox.fill" }
    if token.contains("probe") || token.contains("shader") || token.contains("xaudio") { return "waveform.path.ecg.rectangle.fill" }
    if token.contains("应用宝") || token.contains("appstore") { return "square.stack.3d.up.fill" }
    return "play.square.fill"
}

private func launcherCategory(for launcher: LauncherManifest) -> AppLauncherCategory {
    let token = "\(launcher.id) \(launcher.displayName) \(launcher.appId)".lowercased()
    if token.contains("steam") || token.contains("hoyo") || token.contains("mihoyo") || token.contains("game") || token.contains("shader") || token.contains("xaudio") {
        return .games
    }
    if token.contains("market") || token.contains("store") || token.contains("应用宝") || token.contains("itch") {
        return .market
    }
    return .apps
}

private func launcherTint(for launcher: LauncherManifest) -> Color {
    switch launcherCategory(for: launcher) {
    case .games: return .blue
    case .market: return .green
    case .diagnostics: return .orange
    case .utilities: return .cyan
    case .apps, .all, .other: return .indigo
    }
}

private struct InstallerDropOverlay: View {
    @EnvironmentObject private var store: MacWinStore

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray.and.arrow.down.fill")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 72, height: 72)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.2), in: RoundedRectangle(cornerRadius: 8))

            Text(store.text(.dropInstallerTitle))
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.primary)

            Text(store.text(.dropInstallerHelp))
                .font(.headline)
                .foregroundStyle(Color.macWinSecondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.58), style: StrokeStyle(lineWidth: 1.2, dash: [10, 7]))
        }
    }
}

private struct WindowsDesktopWallpaper: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            ZStack {
                if colorScheme == .dark {
                    LinearGradient(
                        colors: [
                            Color(nsColor: .windowBackgroundColor),
                            Color(nsColor: .controlBackgroundColor).opacity(0.72),
                            Color(nsColor: .textBackgroundColor)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    LinearGradient(
                        colors: [
                            Color(nsColor: .controlBackgroundColor),
                            Color(nsColor: .underPageBackgroundColor).opacity(0.84),
                            Color(nsColor: .windowBackgroundColor)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }

                RadialGradient(
                    colors: [
                        Color(nsColor: .controlAccentColor).opacity(0.18),
                        Color.clear
                    ],
                    center: .topLeading,
                    startRadius: 12,
                    endRadius: 520
                )
            }

            Rectangle()
                .fill(.ultraThinMaterial)
                .blendMode(.softLight)
                .allowsHitTesting(false)

            VStack {
                HStack {
                    Group {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(.tertiary)
                            .frame(width: 320, height: 36)
                            .overlay(
                                HStack {
                                    Capsule()
                                        .frame(width: 8, height: 8)
                                    Capsule()
                                        .frame(width: 8, height: 8)
                                    Capsule()
                                        .frame(width: 8, height: 8)
                                    Spacer()
                                }
                                .foregroundStyle(Color.macWinSecondaryText.opacity(0.9))
                                .padding(.horizontal, 10)
                            )
                            .opacity(0.35)
                            .blur(radius: 1)
                        Spacer()
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 14)
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

private struct DesktopShortcut: Identifiable {
    var id: String
    var title: String
    var subtitle: String
    var systemImage: String
    var action: DesktopShortcutAction
    var tint: Color
}

private enum DesktopShortcutAction {
    case launcher(BottleManifest, LauncherManifest)
    case openDriveC(BottleManifest)
    case openBottle(BottleManifest)
    case openLogs
    case openMarket
    case openSettings
    case openDiagnostics
    case runBuiltin(BottleManifest, String, [String])
    case wineDesktop(BottleManifest)
}

private struct DesktopShortcutButton: View {
    var shortcut: DesktopShortcut
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.92))
                    Image(systemName: shortcut.systemImage)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(shortcut.tint)
                }
                .frame(width: 50, height: 50)

                Text(shortcut.title)
                    .font(.system(size: 12, weight: .semibold))
                    .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
                .foregroundStyle(Color(nsColor: .labelColor))
                .frame(width: 100, height: 30, alignment: .top)
            }
            .frame(width: 106, height: 92, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("\(shortcut.title) - \(shortcut.subtitle)")
    }
}

private struct StartMenuPanel: View {
    @EnvironmentObject private var store: MacWinStore
    var bottle: BottleManifest
    var launchers: [LauncherManifest]
    var runningItems: [RunningDesktopItem]
    @Binding var searchText: String
    @Binding var command: String
    @Binding var arguments: String
    var runLauncher: (LauncherManifest) -> Void
    var runCommand: () -> Void
    var perform: (DesktopShortcutAction) -> Void
    var openRunningLog: (RunningDesktopItem) -> Void
    var terminateRunningItem: (RunningDesktopItem) -> Void

    private let gridColumns = [
        GridItem(.adaptive(minimum: 104, maximum: 128), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(store.text(.startMenu), systemImage: "square.grid.2x2.fill")
                    .font(.title3.weight(.semibold))
                Spacer()
                Text(bottle.name)
                    .font(.caption)
                    .foregroundStyle(Color.macWinSecondaryText)
                    .lineLimit(1)
            }

            TextField(store.text(.searchApps), text: $searchText)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .leading, spacing: 8) {
                Text(store.text(.pinned))
                    .font(.headline)
                    .foregroundStyle(Color.macWinSecondaryText)

                if filteredLaunchers.isEmpty {
                    Text(store.text(.noDesktopApps))
                        .foregroundStyle(Color.macWinSecondaryText)
                        .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
                } else {
                    LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 10) {
                        ForEach(filteredLaunchers) { launcher in
                            StartMenuAppButton(title: launcher.displayName, systemImage: "play.square.fill") {
                                runLauncher(launcher)
                            }
                        }
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(store.text(.runningApps))
                        .font(.headline)
                        .foregroundStyle(Color.macWinSecondaryText)
                    Spacer()
                    Button {
                        store.refreshRunningItems()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .help(store.text(.refreshDesktop))
                }

                if runningItems.isEmpty {
                    Text(store.text(.noRunningApps))
                        .font(.caption)
                        .foregroundStyle(Color.macWinSecondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                } else {
                    VStack(spacing: 6) {
                        ForEach(runningItems.prefix(4)) { item in
                            RunningProcessRow(
                                item: item,
                                openLog: { openRunningLog(item) },
                                terminate: { terminateRunningItem(item) }
                            )
                            .environmentObject(store)
                        }
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(store.text(.quickAccess))
                    .font(.headline)
                    .foregroundStyle(Color.macWinSecondaryText)

                LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 10) {
                    StartMenuAppButton(title: store.text(.thisPC), systemImage: "desktopcomputer") {
                        perform(.openDriveC(bottle))
                    }
                    StartMenuAppButton(title: store.text(.wineConfiguration), systemImage: "slider.horizontal.3") {
                        perform(.runBuiltin(bottle, "winecfg", []))
                    }
                    StartMenuAppButton(title: store.text(.registryEditor), systemImage: "list.bullet.rectangle") {
                        perform(.runBuiltin(bottle, "regedit", []))
                    }
                    StartMenuAppButton(title: store.text(.commandPrompt), systemImage: "terminal") {
                        perform(.runBuiltin(bottle, "cmd", []))
                    }
                    StartMenuAppButton(title: store.text(.diagnostics), systemImage: "stethoscope") {
                        perform(.openDiagnostics)
                    }
                    StartMenuAppButton(title: store.text(.settings), systemImage: "gearshape") {
                        perform(.openSettings)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(store.text(.runCommand))
                    .font(.headline)
                    .foregroundStyle(Color.macWinSecondaryText)
                HStack(spacing: 8) {
                    TextField(store.text(.executablePlaceholder), text: $command)
                        .textFieldStyle(.roundedBorder)
                    TextField(store.text(.arguments), text: $arguments)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 180)
                    Button {
                        runCommand()
                    } label: {
                        Label(store.text(.run), systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding(18)
        .frame(width: 620)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.24), lineWidth: 1)
        }
    }

    private var filteredLaunchers: [LauncherManifest] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return launchers }
        return launchers.filter { $0.displayName.localizedCaseInsensitiveContains(query) }
    }
}

private struct RunningProcessRow: View {
    @EnvironmentObject private var store: MacWinStore
    var item: RunningDesktopItem
    var openLog: () -> Void
    var terminate: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "app.badge.checkmark")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.green)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("\(store.text(.pid)) \(item.processIdentifier) · \(item.bottleName)")
                    .font(.caption)
                    .foregroundStyle(Color.macWinSecondaryText)
                    .lineLimit(1)
            }
            Spacer()
            Button(action: openLog) {
                Image(systemName: "doc.text")
            }
            .buttonStyle(.borderless)
            .help(store.text(.openLogFile))
            Button(role: .destructive, action: terminate) {
                Image(systemName: "stop.fill")
            }
            .buttonStyle(.borderless)
            .help(store.text(.stop))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct StartMenuAppButton: View {
    var title: String
    var systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .foregroundStyle(.tint)
                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.76)
                    .frame(width: 106, height: 30, alignment: .top)
            }
            .frame(width: 112, height: 80)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct WindowsTaskbar: View {
    @EnvironmentObject private var store: MacWinStore
    var bottle: BottleManifest
    var launchers: [LauncherManifest]
    var runningItems: [RunningDesktopItem]
    var isStartMenuOpen: Bool
    var toggleStart: () -> Void
    var openSearch: () -> Void
    var runLauncher: (LauncherManifest) -> Void
    var refreshRunningItems: () -> Void
    var openRunningLog: (RunningDesktopItem) -> Void
    var terminateRunningItem: (RunningDesktopItem) -> Void
    var openLogs: () -> Void
    var openSettings: () -> Void

    var body: some View {
        HStack(spacing: 9) {
            Button(action: toggleStart) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 36, height: 34)
            }
            .buttonStyle(.plain)
            .background(isStartMenuOpen ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            .help(store.text(.startMenu))

            Button(action: openSearch) {
                Label(store.text(.searchApps), systemImage: "magnifyingglass")
                    .font(.subheadline)
                    .lineLimit(1)
                    .frame(width: 210, height: 34, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 10)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))

            ForEach(launchers) { launcher in
                Button {
                    runLauncher(launcher)
                } label: {
                    Image(systemName: "play.square.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 36, height: 34)
                }
                .buttonStyle(.plain)
                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                .help(launcher.displayName)
            }

            ForEach(runningItems.prefix(5)) { item in
                let helpLabel = "\(item.title) · \(store.text(.pid)) \(item.processIdentifier)"

                Button {
                    openRunningLog(item)
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        Image(systemName: "app.badge.checkmark")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 36, height: 34)
                        Circle()
                            .fill(Color.green)
                            .frame(width: 7, height: 7)
                            .offset(x: -5, y: -4)
                    }
                }
                .buttonStyle(.plain)
                .background(Color.green.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
                .help(helpLabel)
                .contextMenu {
                    Button(store.text(.openLogFile)) {
                        openRunningLog(item)
                    }
                    Button(role: .destructive) {
                        terminateRunningItem(item)
                    } label: {
                        Text(store.text(.stop))
                    }
                }
            }

            Spacer(minLength: 12)

            Button(action: refreshRunningItems) {
                Image(systemName: "arrow.clockwise")
                    .frame(width: 28, height: 32)
            }
            .buttonStyle(.plain)
            .help(store.text(.refreshDesktop))

            Label(bottle.windowsVersion.uppercased(), systemImage: "shippingbox")
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(Color.macWinSecondaryText)

            Button(action: openLogs) {
                Image(systemName: "doc.text")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .help(store.text(.logs))

            Button(action: openSettings) {
                Image(systemName: "gearshape")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .help(store.text(.settings))

            Text(Self.timeString)
                .font(.caption.monospacedDigit())
                .multilineTextAlignment(.trailing)
                .frame(width: 76, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.2), lineWidth: 0.6)
        }
    }

    private static var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
}
