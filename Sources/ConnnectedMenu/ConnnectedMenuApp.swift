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
}

private enum ListMetrics {
    static let listContentLeadingInset: CGFloat = 12
    static let listContentTrailingInset: CGFloat = 12
    static let sectionHeaderTopBottomPadding: CGFloat = 6
    static let rowVerticalPadding: CGFloat = 4
    static let headerTopPadding: CGFloat = 10
    static let headerBottomPadding: CGFloat = 2
    static let headerActionGap: CGFloat = 8
}

private struct LaneAlignedListRowModifier: ViewModifier {
    let top: CGFloat
    let bottom: CGFloat

    func body(content: Content) -> some View {
        content
            .listRowInsets(
                EdgeInsets(
                    top: top,
                    leading: ListMetrics.listContentLeadingInset,
                    bottom: bottom,
                    trailing: ListMetrics.listContentTrailingInset
                )
            )
            .alignmentGuide(.listRowSeparatorLeading) { _ in
                ListMetrics.listContentLeadingInset
            }
            .alignmentGuide(.listRowSeparatorTrailing) { dimensions in
                dimensions.width - ListMetrics.listContentTrailingInset
            }
    }
}

private extension View {
    func laneAlignedRow(top: CGFloat = 0, bottom: CGFloat = 0) -> some View {
        modifier(LaneAlignedListRowModifier(top: top, bottom: bottom))
    }

    func laneHorizontalInsets() -> some View {
        padding(.leading, ListMetrics.listContentLeadingInset)
            .padding(.trailing, ListMetrics.listContentTrailingInset)
    }
}

struct ContentView: View {
    @EnvironmentObject var store: DeviceStore
    @State private var activeOnly = false

    var body: some View {
        VStack(spacing: 0) {
            headerRow

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
                .laneAlignedRow()
                .listRowSeparator(.hidden)
        } else {
            ForEach(group.rows) { row in
                Button {
                    openSettingsURL(row.settingsURL)
                } label: {
                    RowView(row: row)
                }
                .buttonStyle(.plain)
                .laneAlignedRow()
                .listRowSeparator(.hidden)
            }
        }
    }

    private func sectionHeader(for group: DeviceGroupSection) -> some View {
        SectionHeader(group: group)
            .textCase(nil)
            .laneAlignedRow(
                top: ListMetrics.sectionHeaderTopBottomPadding,
                bottom: ListMetrics.sectionHeaderTopBottomPadding
            )
            .listRowSeparator(.hidden)
    }

    private var headerRow: some View {
        HStack(spacing: ListMetrics.headerActionGap) {
            Text("Connnected")
                .font(.headline.weight(.medium))

            Spacer(minLength: 0)

            Button {
                store.refreshNow(forceHeavy: true)
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .help("Refresh now")

            Menu {
                Section("Filter") {
                    Button {
                        activeOnly = false
                    } label: {
                        Label("All", systemImage: activeOnly ? "checkmark" : "circle")
                    }

                    Button {
                        activeOnly = true
                    } label: {
                        Label("Active", systemImage: activeOnly ? "checkmark" : "circle")
                    }
                }
                Divider()
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
            .menuIndicator(.hidden)
            .menuStyle(.borderlessButton)
            .help("More options")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, ListMetrics.headerTopPadding)
        .padding(.bottom, ListMetrics.headerBottomPadding)
        .laneHorizontalInsets()
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
        .padding(.vertical, ListMetrics.rowVerticalPadding)
        .help("Open settings")
    }
}
