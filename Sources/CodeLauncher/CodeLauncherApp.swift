import SwiftUI

@main
struct CodeLauncherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("CodeLauncher", systemImage: "chevron.left.forwardslash.chevron.right") {
            MenuBarContent()
        }

        Settings {
            SettingsView()
        }
    }
}

private struct MenuBarContent: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Open Panel") {
            QuickLaunchWindowController.shared.show()
        }
        .keyboardShortcut("s", modifiers: [.command, .shift])

        Divider()

        Button("Settings...") {
            NSApp.setActivationPolicy(.regular)
            openSettings()
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}

