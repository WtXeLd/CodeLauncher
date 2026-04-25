import AppKit
import SwiftUI

private let PANEL_WIDTH: CGFloat = 600
private let PANEL_HEIGHT: CGFloat = 420

private final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class QuickLaunchWindowController: NSObject, NSWindowDelegate {
    static let shared = QuickLaunchWindowController()

    private var panel: NSPanel?
    private let viewModel = LaunchViewModel()
    private var clickMonitor: Any?
    private var keyMonitor: Any?

    private override init() {}

    var isVisible: Bool { panel?.isVisible ?? false }

    func toggle() {
        if isVisible { hide() } else { show() }
    }

    func show() {
        let p = panel ?? buildPanel()
        panel = p

        viewModel.load()
        viewModel.searchText = ""
        viewModel.selectedIndex = 0

        positionPanel(p)
        p.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        installMonitors()
    }

    func hide() {
        removeMonitors()
        panel?.orderOut(nil)
    }

    // MARK: - NSWindowDelegate

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }

    // MARK: - Build

    private func buildPanel() -> NSPanel {
        let content = QuickLaunchView(viewModel: viewModel) { [weak self] in
            self?.hide()
        }
        // ignoresSafeArea so SwiftUI doesn't add any inset — the container clips to rounded corners
        let hosting = NSHostingController(rootView: content.ignoresSafeArea())

        // .borderless removes the titlebar safe-area inset that .titled adds to SwiftUI content
        let p = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: PANEL_WIDTH, height: PANEL_HEIGHT),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        p.level = .floating
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = true
        p.isMovableByWindowBackground = true
        p.isReleasedWhenClosed = false
        p.delegate = self

        let container = NSView(frame: NSRect(x: 0, y: 0, width: PANEL_WIDTH, height: PANEL_HEIGHT))
        container.wantsLayer = true
        container.layer?.cornerRadius = 16
        container.layer?.masksToBounds = true

        // Frosted glass — same pattern as PasteMemo
        let blur = NSVisualEffectView(frame: container.bounds)
        blur.material = .headerView
        blur.blendingMode = .behindWindow
        blur.state = .active
        blur.autoresizingMask = [.width, .height]
        container.addSubview(blur)

        // SwiftUI content on top; must be transparent so the blur shows through
        let hv = hosting.view
        hv.translatesAutoresizingMaskIntoConstraints = false
        hv.wantsLayer = true
        hv.layer?.backgroundColor = NSColor.clear.cgColor
        container.addSubview(hv)
        NSLayoutConstraint.activate([
            hv.topAnchor.constraint(equalTo: container.topAnchor),
            hv.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            hv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])

        p.contentView = container
        return p
    }

    private func positionPanel(_ p: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let sf = screen.visibleFrame
        let x = sf.midX - PANEL_WIDTH / 2
        let y = sf.midY - PANEL_HEIGHT / 2 + sf.height * 0.1
        p.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: - Monitors

    private func installMonitors() {
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in self?.hide() }
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            // Shift+Return — reveal in Finder
            if event.keyCode == 36 && mods.contains(.shift) {
                if self.viewModel.selectedIndex < self.viewModel.filteredProjects.count {
                    self.viewModel.openInFinder(self.viewModel.filteredProjects[self.viewModel.selectedIndex])
                    self.hide()
                }
                return nil
            }

            // Cmd+1…5 — open nth project directly
            if mods == .command, let num = [18:0, 19:1, 20:2, 21:3, 23:4][Int(event.keyCode)] {
                self.viewModel.openAtIndex(num)
                self.hide()
                return nil
            }

            switch event.keyCode {
            case 125: self.viewModel.moveSelection(by: 1);  return nil  // ↓
            case 126: self.viewModel.moveSelection(by: -1); return nil  // ↑
            case 36:  self.viewModel.openSelected(); self.hide(); return nil  // Return
            case 53:  self.hide(); return nil  // Escape
            default:  return event
            }
        }
    }

    private func removeMonitors() {
        if let m = clickMonitor { NSEvent.removeMonitor(m); clickMonitor = nil }
        if let m = keyMonitor   { NSEvent.removeMonitor(m); keyMonitor = nil }
    }
}
