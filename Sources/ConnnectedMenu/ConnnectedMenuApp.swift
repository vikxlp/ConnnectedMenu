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
    static let listContentLeadingInset: CGFloat = 4
    static let listContentTrailingInset: CGFloat = 4
    static let headerContentInset: CGFloat = 12
    static let sectionTitleTopPadding: CGFloat = 4
    static let sectionTitleBottomPadding: CGFloat = 4
    static let rowVerticalPadding: CGFloat = 4
    static let sectionDividerTopPadding: CGFloat = 6
    static let sectionDividerBottomPadding: CGFloat = 6
    static let sectionDividerThickness: CGFloat = 1
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

    func headerHorizontalInsets() -> some View {
        padding(.leading, ListMetrics.headerContentInset)
            .padding(.trailing, ListMetrics.headerContentInset)
    }
}

struct ContentView: View {
    @EnvironmentObject var store: DeviceStore
    @State private var activeOnly = false

    var body: some View {
        VStack(spacing: 0) {
            headerRow

            List {
                let groups = filteredGroups
                ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                    sectionTitleRow(for: group)
                    sectionRows(for: group)
                    sectionDividerRow(for: index, total: groups.count)
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

    private func sectionTitleRow(for group: DeviceGroupSection) -> some View {
        SectionHeader(group: group)
            .textCase(nil)
            .laneAlignedRow(
                top: ListMetrics.sectionTitleTopPadding,
                bottom: ListMetrics.sectionTitleBottomPadding
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private func sectionDividerRow(for index: Int, total: Int) -> some View {
        if index < total - 1 {
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(maxWidth: .infinity)
                .frame(height: ListMetrics.sectionDividerThickness)
                .laneAlignedRow(
                    top: ListMetrics.sectionDividerTopPadding,
                    bottom: ListMetrics.sectionDividerBottomPadding
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
    }

    private var headerRow: some View {
        HStack {
            Text("Connnected")
                .font(.headline.weight(.medium))
                .layoutPriority(1)

            Spacer(minLength: 0)

            HStack(spacing: ListMetrics.headerActionGap) {
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, ListMetrics.headerTopPadding)
        .padding(.bottom, ListMetrics.headerBottomPadding)
        .headerHorizontalInsets()
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
