import SwiftUI

@main
struct ConnectsMenuApp: App {
    @StateObject private var store = DeviceStore()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(store)
                .frame(width: 340)
        } label: {
            Label("Connects", systemImage: "cable.connector")
        }
        .menuBarExtraStyle(.window)
    }
}

struct ContentView: View {
    @EnvironmentObject var store: DeviceStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Connects")
                    .font(.headline)
                Spacer()
                Button {
                    store.refreshNow(forceHeavy: true)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
            }

            ForEach(store.groups) { group in
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.title)
                        .font(.subheadline.bold())
                    Text("\(group.rows.count) devices")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(12)
        .onAppear {
            store.start()
        }
    }
}
