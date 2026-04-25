import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        HotkeyManager.shared.register()

        // When all windows close, return to .accessory so the Dock icon disappears
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                let visible = NSApp.windows.filter { $0.isVisible && !($0 is NSPanel) }
                if visible.isEmpty {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
        }
    }
}
