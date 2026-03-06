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

private enum LayoutMetrics {
    static let laneIconWidth: CGFloat = 26
    static let laneGap: CGFloat = 10
    static let trailingAccessoryLaneWidth: CGFloat = 28
    static let rowVerticalPadding: CGFloat = 4
}

struct ContentView: View {
    @EnvironmentObject var store: DeviceStore
    @State private var activeOnly = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredGroups) { group in
                    Section {
                        sectionRows(for: group)
                    } header: {
                        sectionHeader(for: group)
                    }
                }
            }
            .listStyle(.inset)
            .navigationTitle("Connnected")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("", selection: $activeOnly) {
                        Text("All").tag(false)
                        Text("Active").tag(true)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        store.refreshNow(forceHeavy: true)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Refresh now")

                    Menu {
                        Button("Open System Information") {
                            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/System Information.app"))
                        }
                        Divider()
                        Button("Quit") {
                            NSApplication.shared.terminate(nil)
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .help("More options")
                }
            }
        }
        .onAppear {
            store.start()
        }
    }

    private var filteredGroups: [DeviceGroupSection] {
        guard activeOnly else { return store.groups }
        return store.groups.map { group in
            DeviceGroupSection(type: group.type, rows: group.rows.filter(\.isActive))
        }
    }

    @ViewBuilder
    private func sectionRows(for group: DeviceGroupSection) -> some View {
        if group.rows.isEmpty {
            Text("No devices detected")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            ForEach(group.rows) { row in
                RowView(row: row)
            }
        }
    }

    private func sectionHeader(for group: DeviceGroupSection) -> some View {
        SectionHeader(group: group)
    }
}

struct SectionHeader: View {
    let group: DeviceGroupSection

    var body: some View {
        HStack(spacing: LayoutMetrics.laneGap) {
            Image(systemName: group.icon)
                .frame(width: LayoutMetrics.laneIconWidth, height: LayoutMetrics.laneIconWidth, alignment: .center)
                .foregroundStyle(.secondary)
            Text(group.title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
}

struct RowView: View {
    let row: DeviceRow

    var body: some View {
        HStack(alignment: .center, spacing: LayoutMetrics.laneGap) {
            ZStack {
                Circle()
                    .fill(row.statusColor.opacity(0.22))
                    .frame(width: LayoutMetrics.laneIconWidth, height: LayoutMetrics.laneIconWidth)
                Image(systemName: row.kind.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(row.statusColor)
            }
            .frame(width: LayoutMetrics.laneIconWidth, height: LayoutMetrics.laneIconWidth)

            VStack(alignment: .leading, spacing: 2) {
                Text(row.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(row.isActive ? "\(row.subtitle) • Active" : row.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                if row.group == .external {
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
            .frame(width: LayoutMetrics.trailingAccessoryLaneWidth, alignment: .trailing)
        }
        .padding(.vertical, LayoutMetrics.rowVerticalPadding)
        .help("Open settings")
    }
}
