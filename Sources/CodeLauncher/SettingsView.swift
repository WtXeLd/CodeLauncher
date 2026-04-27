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
            AboutTab()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
        .scrollDisabled(true)
    }
}

// MARK: - General

private struct GeneralTab: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("hideDockIcon") private var hideDockIcon = false
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
                Toggle("Hide Dock icon", isOn: $hideDockIcon)
                    .onChange(of: hideDockIcon) {
                        if hideDockIcon {
                            NSApp.setActivationPolicy(.accessory)
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

// MARK: - About

private struct AboutTab: View {
    var updateChecker = UpdateChecker.shared

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(nsImage: NSApp.applicationIconImage)
                            .resizable()
                            .frame(width: 64, height: 64)
                        Text("CodeLauncher")
                            .font(.headline)
                        Text("Version \(UpdateChecker.currentVersion)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }

            Section {
                HStack {
                    statusView
                    Spacer()
                    Button("Check for Updates") {
                        Task { await updateChecker.checkManually() }
                    }
                    .disabled(updateChecker.checkState == .checking)
                }
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var statusView: some View {
        switch updateChecker.checkState {
        case .idle:
            EmptyView()
        case .checking:
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("Checking…").foregroundStyle(.secondary)
            }
        case .upToDate:
            Label("Up to date", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .updateAvailable(let version):
            Label("v\(version) available", systemImage: "arrow.down.circle.fill")
                .foregroundStyle(.blue)
        case .error(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .lineLimit(2)
                .font(.caption)
        }
    }
}
