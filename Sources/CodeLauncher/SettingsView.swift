import SwiftUI
import ServiceManagement
import Carbon

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralTab()
                .tabItem { Label("General", systemImage: "gear") }
            ShortcutsTab()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
        }
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
        .scrollDisabled(true)
    }
}

// MARK: - General

private struct GeneralTab: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) {
                        if launchAtLogin {
                            try? SMAppService.mainApp.register()
                        } else {
                            try? SMAppService.mainApp.unregister()
                        }
                    }
                    .frame(minHeight: 22)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Shortcuts

private struct ShortcutsTab: View {
    @AppStorage("hotkeyKeyCode") private var keyCode = Int(DEFAULT_KEY_CODE)
    @AppStorage("hotkeyModifiers") private var modifiers = Int(DEFAULT_MODIFIERS)

    var body: some View {
        Form {
            Section("Shortcuts") {
                HStack {
                    Text("Open Panel")
                    Spacer()
                    if keyCode < 0 {
                        Text("None").foregroundStyle(.tertiary).font(.callout)
                    }
                    ShortcutRecorder(keyCode: $keyCode, modifiers: $modifiers, onChanged: apply)
                        .frame(width: 140, height: 22)
                    Button {
                        keyCode = -1; modifiers = -1
                        HotkeyManager.shared.update(keyCode: -1, modifiers: -1)
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .fixedSize()
                }
            }
        }
        .formStyle(.grouped)
    }

    private func apply() {
        HotkeyManager.shared.update(keyCode: keyCode, modifiers: modifiers)
    }
}
