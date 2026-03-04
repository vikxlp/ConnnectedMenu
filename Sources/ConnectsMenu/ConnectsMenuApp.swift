import SwiftUI

@main
struct ConnectsMenuApp: App {
    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .leading, spacing: 8) {
                Text("Connects")
                    .font(.headline)
                Text("Menu bar app is running")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(12)
            .frame(width: 260)
        } label: {
            Label("Connects", systemImage: "cable.connector")
        }
        .menuBarExtraStyle(.window)
    }
}
