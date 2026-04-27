import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        HotkeyManager.shared.register()
        Task { await UpdateChecker.shared.checkOnLaunch() }

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { notification in
            let closingWindow = notification.object as? NSWindow
            DispatchQueue.main.async {
                let visible = NSApp.windows.filter {
                    $0.isVisible && !($0 is NSPanel) && $0 !== closingWindow
                }
                if visible.isEmpty {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
        }
    }
}
