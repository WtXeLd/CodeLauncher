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
    @State private var installedEditors: [EditorApp] = []
    @State private var selectedBundleID: String = ""
    @State private var customAppName: String = ""

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

            Section("Editor") {
                HStack {
                    Text("Open projects with")
                    Spacer()
                    editorPicker
                }
                .frame(minHeight: 22)
            }
        }
        .formStyle(.grouped)
        .onAppear { loadEditors() }
    }

    @ViewBuilder
    private var editorPicker: some View {
        Menu {
            ForEach(installedEditors) { editor in
                Button {
                    selectedBundleID = editor.id
                    customAppName = ""
                    EditorPreference.save(bundleID: editor.id)
                } label: {
                    Text(editor.name)
                }
            }
            if !installedEditors.isEmpty { Divider() }
            Button("Other...") { pickCustomApp() }
        } label: {
            HStack(spacing: 4) {
                if !customAppName.isEmpty {
                    Text(customAppName)
                } else if let editor = installedEditors.first(where: { $0.id == selectedBundleID }) {
                    Text(editor.name)
                } else {
                    Text("Select...").foregroundStyle(.secondary)
                }
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private func loadEditors() {
        installedEditors = EditorApp.installed
        if let id = EditorPreference.savedBundleID {
            selectedBundleID = id
        } else if let path = EditorPreference.savedAppPath {
            customAppName = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        } else if let first = installedEditors.first {
            selectedBundleID = first.id
        }
    }

    private func pickCustomApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        if panel.runModal() == .OK, let url = panel.url {
            let name = url.deletingPathExtension().lastPathComponent
            customAppName = name
            selectedBundleID = ""
            EditorPreference.save(customPath: url.path)
        }
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
