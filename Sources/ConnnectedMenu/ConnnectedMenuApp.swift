import SwiftUI

@main
struct ConnnectedMenuApp: App {
    @StateObject private var store = DeviceStore()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 420, maxWidth: 520, minHeight: 520, maxHeight: 720)
        } label: {
            Label("Connnected", systemImage: "cable.connector")
        }
        .menuBarExtraStyle(.window)
    }
}

struct ContentView: View {
    @EnvironmentObject var store: DeviceStore
    @State private var activeOnly = false
    @State private var selectedRowID: UUID?
    @State private var keyMonitor: Any?
    @State private var isRefreshHovered = false
    private let headerSideWidth: CGFloat = 120

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack {
                    Text("Connnected")
                        .font(.headline)
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
                .frame(width: 130)

                Spacer(minLength: 0)

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
                .frame(width: headerSideWidth, alignment: .trailing)
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(filteredGroups.enumerated()), id: \.element.id) { index, group in
                        GroupCard(group: group)
                        if index < filteredGroups.count - 1 {
                            Divider()
                                .padding(.vertical, 4)
                        }
                    }
                }
                .padding(.bottom, 4)
            }

            HStack {
                Button("Open System Information") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/System Information.app"))
                }
                .buttonStyle(.borderless)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 6)
        }
        .padding(14)
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
        guard let url = row.settingsURL else { return }
        NSWorkspace.shared.open(url)
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

struct GroupCard: View {
    let group: DeviceGroupSection
    private let rowHorizontalInset: CGFloat = 6
    private let iconLaneWidth: CGFloat = 26
    private let laneSpacing: CGFloat = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: laneSpacing) {
                Image(systemName: group.icon)
                    .frame(width: iconLaneWidth, height: iconLaneWidth, alignment: .center)
                    .foregroundStyle(.secondary)
                Text(group.title)
                    .font(.title3.weight(.semibold))
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
        .padding(.vertical, 4)
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
                    .font(.title3)
                    .foregroundStyle(.primary)
                Text(row.isActive ? "\(row.subtitle) • Active" : row.subtitle)
                    .font(.body)
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
        .padding(.vertical, 5)
        .padding(.horizontal, 6)
        .background {
            if isHovered {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.quinary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let url = row.settingsURL {
                NSWorkspace.shared.open(url)
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .help("Open settings")
    }
}
