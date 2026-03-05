import SwiftUI
import AppKit

private func openSettingsURL(_ url: URL?) {
    guard let url else { return }
    NSWorkspace.shared.open(url)
}

@main
struct ConnnectedMenuApp: App {
    @StateObject private var store = DeviceStore()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 300, maxWidth: 300, minHeight: 300, maxHeight: 560)
        } label: {
            Label("Connnected", systemImage: "cable.connector")
        }
        .menuBarExtraStyle(.window)
    }
}

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct ContentView: View {
    @EnvironmentObject var store: DeviceStore
    @State private var activeOnly = false
    @State private var selectedRowID: String?
    @State private var keyMonitor: Any?
    @State private var isRefreshHovered = false
    @State private var isMenuHovered = false
    @State private var isMenuOpen = false
    @State private var contentHeight: CGFloat = 0
    @State private var headerHeight: CGFloat = 0
    private let headerSideWidth: CGFloat = 90
    private let minMenuHeight: CGFloat = 300
    private let maxMenuHeight: CGFloat = 560

    var body: some View {
        let listContent = LazyVStack(alignment: .leading, spacing: 6) {
            ForEach(Array(filteredGroups.enumerated()), id: \.element.id) { index, group in
                GroupCard(group: group)
                if index < filteredGroups.count - 1 {
                    Divider()
                        .padding(.vertical, 4)
                }
            }
        }

        let totalHeight = headerHeight + contentHeight + 12 + 12 + 8
        let clampedHeight = min(max(totalHeight, minMenuHeight), maxMenuHeight)

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack {
                    Text("Connnected")
                        .font(.callout.weight(.semibold))
                    Spacer(minLength: 0)
                }
                .frame(width: headerSideWidth, alignment: .leading)

                Spacer(minLength: 0)

                Picker("", selection: $activeOnly) {
                    Text("All").tag(false)
                    Text("Active").tag(true)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 110)

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    Button {
                        store.refreshNow(forceHeavy: true)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .frame(width: 24, height: 24)
                            .background {
                                if isRefreshHovered {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(.quinary)
                                }
                            }
                    }
                    .help("Refresh now")
                    .buttonStyle(.borderless)
                    .onHover { hovering in
                        isRefreshHovered = hovering
                    }

                    DotMenuButton(
                        isHovered: $isMenuHovered,
                        isOpen: $isMenuOpen,
                        openSystemInfo: {
                            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/System Information.app"))
                        },
                        quit: {
                            NSApplication.shared.terminate(nil)
                        }
                    )
                    .frame(width: 24, height: 24)
                    .background {
                        if isMenuHovered || isMenuOpen {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(.quinary)
                        }
                    }
                }
                .frame(width: headerSideWidth, alignment: .trailing)
            }
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: ContentHeightKey.self, value: proxy.size.height)
                }
            )

            ViewThatFits(in: .vertical) {
                listContent
                    .padding(.bottom, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ScrollView {
                    listContent
                        .padding(.bottom, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }

        }
        .padding(12)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: ContentHeightKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(ContentHeightKey.self) { newValue in
            if newValue > headerHeight + 1 {
                contentHeight = newValue - headerHeight - 12 - 12 - 8
            } else {
                headerHeight = newValue
            }
        }
        .frame(height: clampedHeight)
        .onAppear {
            store.start()
            ensureSelection()
            installKeyboardMonitor()
        }
        .onReceive(store.$groups) { _ in
            ensureSelection()
        }
        .onChange(of: activeOnly) {
            ensureSelection()
        }
        .onDisappear {
            if let keyMonitor {
                NSEvent.removeMonitor(keyMonitor)
                self.keyMonitor = nil
            }
        }
    }

    private var filteredGroups: [DeviceGroupSection] {
        guard activeOnly else { return store.groups }
        return store.groups.map { group in
            DeviceGroupSection(type: group.type, rows: group.rows.filter(\.isActive))
        }
    }

    private var visibleRows: [DeviceRow] {
        filteredGroups.flatMap(\.rows)
    }

    private func ensureSelection() {
        let rows = visibleRows
        if rows.isEmpty {
            selectedRowID = nil
            return
        }
        if let selectedRowID, rows.contains(where: { $0.id == selectedRowID }) {
            return
        }
        selectedRowID = rows.first?.id
    }

    private func moveSelection(by delta: Int) {
        let rows = visibleRows
        guard !rows.isEmpty else { return }
        guard let selectedRowID, let currentIndex = rows.firstIndex(where: { $0.id == selectedRowID }) else {
            self.selectedRowID = rows.first?.id
            return
        }
        let next = max(0, min(rows.count - 1, currentIndex + delta))
        self.selectedRowID = rows[next].id
    }

    private func openSelectedRow() {
        guard let selectedRowID else { return }
        guard let row = visibleRows.first(where: { $0.id == selectedRowID }) else { return }
        openSettingsURL(row.settingsURL)
    }

    private func installKeyboardMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch event.keyCode {
            case 125:
                moveSelection(by: 1)
                return nil
            case 126:
                moveSelection(by: -1)
                return nil
            case 36, 76:
                openSelectedRow()
                return nil
            default:
                return event
            }
        }
    }
}

private final class HoverButton: NSButton {
    var onHoverChanged: ((Bool) -> Void)?

    private var trackingAreaRef: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }
        let tracking = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(tracking)
        trackingAreaRef = tracking
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        onHoverChanged?(true)
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        onHoverChanged?(false)
    }
}

private struct DotMenuButton: NSViewRepresentable {
    @Binding var isHovered: Bool
    @Binding var isOpen: Bool
    let openSystemInfo: () -> Void
    let quit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> HoverButton {
        let button = HoverButton()
        button.isBordered = false
        button.bezelStyle = .regularSquare
        button.imagePosition = .imageOnly
        button.onHoverChanged = { hovering in
            context.coordinator.parent.isHovered = hovering
        }
        let image = NSImage(systemSymbolName: "ellipsis", accessibilityDescription: "More options")
        image?.isTemplate = true
        button.image = image
        button.contentTintColor = NSColor.labelColor
        button.target = context.coordinator
        button.action = #selector(Coordinator.showMenu(_:))
        return button
    }

    func updateNSView(_ nsView: HoverButton, context: Context) {
        nsView.onHoverChanged = { hovering in
            context.coordinator.parent.isHovered = hovering
        }
    }

    final class Coordinator: NSObject, NSMenuDelegate {
        var parent: DotMenuButton

        init(parent: DotMenuButton) {
            self.parent = parent
        }

        @objc func showMenu(_ sender: NSButton) {
            let menu = NSMenu()
            menu.delegate = self

            let openItem = NSMenuItem(
                title: "Open System Information",
                action: #selector(openSystemInfoAction),
                keyEquivalent: ""
            )
            openItem.target = self
            menu.addItem(openItem)

            menu.addItem(.separator())

            let quitItem = NSMenuItem(
                title: "Quit",
                action: #selector(quitAction),
                keyEquivalent: ""
            )
            quitItem.target = self
            menu.addItem(quitItem)

            parent.isOpen = true
            if let window = sender.window {
                let rectInWindow = sender.convert(sender.bounds, to: nil)
                let rectOnScreen = window.convertToScreen(rectInWindow)
                let point = NSPoint(x: rectOnScreen.minX, y: rectOnScreen.minY - 6)
                menu.popUp(positioning: nil, at: point, in: nil)
            } else {
                let point = NSPoint(x: 0, y: -sender.bounds.height - 6)
                menu.popUp(positioning: nil, at: point, in: sender)
            }
        }

        func menuDidClose(_ menu: NSMenu) {
            parent.isOpen = false
        }

        @objc private func openSystemInfoAction() {
            parent.openSystemInfo()
            parent.isOpen = false
        }

        @objc private func quitAction() {
            parent.quit()
            parent.isOpen = false
        }
    }
}

struct GroupCard: View {
    let group: DeviceGroupSection
    private let rowHorizontalInset: CGFloat = 8
    private let iconLaneWidth: CGFloat = 26
    private let laneSpacing: CGFloat = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: laneSpacing) {
                Image(systemName: group.icon)
                    .frame(width: iconLaneWidth, height: iconLaneWidth, alignment: .center)
                    .foregroundStyle(.secondary)
                Text(group.title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, rowHorizontalInset)

            if group.rows.isEmpty {
                Text("No devices detected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 2)
                    .padding(.leading, rowHorizontalInset + iconLaneWidth + laneSpacing)
            } else {
                ForEach(group.rows) { row in
                    RowView(row: row)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct RowView: View {
    let row: DeviceRow
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle()
                    .fill(row.statusColor.opacity(0.22))
                    .frame(width: 26, height: 26)
                Image(systemName: row.kind.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(row.statusColor)
            }
            .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(row.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(row.isActive ? "\(row.subtitle) • Active" : row.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if row.group == .external {
                HStack(spacing: 6) {
                    Image(systemName: row.transport.icon)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .help(row.transportTooltip)
                    if row.detailConfidence == .inferred {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .help("Inferred mapping: \(row.detail)")
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background {
            if isHovered {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.quinary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            openSettingsURL(row.settingsURL)
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .help("Open settings")
    }
}
