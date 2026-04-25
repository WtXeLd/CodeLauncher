import SwiftUI

@main
struct CodeLauncherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("CodeLauncher", systemImage: "chevron.left.forwardslash.chevron.right") {
            Button("Open Panel  ⌘⇧S") {
                QuickLaunchWindowController.shared.show()
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
