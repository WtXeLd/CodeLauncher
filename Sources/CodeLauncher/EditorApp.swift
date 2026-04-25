import AppKit
import Foundation

struct EditorApp: Identifiable, Equatable, Sendable {
    let id: String          // bundle ID
    let name: String

    static let known: [EditorApp] = [
        .init(id: "com.microsoft.VSCode",           name: "Visual Studio Code"),
        .init(id: "com.microsoft.VSCodeInsiders",   name: "VS Code Insiders"),
        .init(id: "com.todesktop.230313mzl4w4u92",  name: "Cursor"),
        .init(id: "dev.zed.Zed",                    name: "Zed"),
        .init(id: "com.sublimetext.4",              name: "Sublime Text"),
        .init(id: "com.sublimetext.3",              name: "Sublime Text 3"),
        .init(id: "com.panic.Nova",                 name: "Nova"),
        .init(id: "com.jetbrains.webstorm",         name: "WebStorm"),
        .init(id: "com.jetbrains.intellij",         name: "IntelliJ IDEA"),
        .init(id: "com.jetbrains.intellij.ce",      name: "IntelliJ IDEA CE"),
        .init(id: "com.jetbrains.pycharm",          name: "PyCharm"),
        .init(id: "com.jetbrains.pycharm.ce",       name: "PyCharm CE"),
        .init(id: "com.jetbrains.goland",           name: "GoLand"),
        .init(id: "com.jetbrains.clion",            name: "CLion"),
        .init(id: "com.jetbrains.rider",            name: "Rider"),
        .init(id: "com.jetbrains.rubymine",         name: "RubyMine"),
    ]

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    var isInstalled: Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) != nil
    }

    var appURL: URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: id)
    }

    static var installed: [EditorApp] {
        known.filter { $0.isInstalled }
    }
}

// MARK: - Persistence

private let EDITOR_BUNDLE_ID_KEY = "editorBundleID"
private let EDITOR_APP_PATH_KEY  = "editorAppPath"   // for custom "Other" picks

enum EditorPreference {
    /// Returns the app URL to use for opening projects.
    /// Priority: user-saved bundle ID → user-saved path → first installed known editor → nil
    static func resolvedAppURL() -> URL? {
        if let id = savedBundleID,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) {
            return url
        }
        if let path = savedAppPath {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: path) { return url }
        }
        return EditorApp.installed.first?.appURL
    }

    static var savedBundleID: String? {
        get { UserDefaults.standard.string(forKey: EDITOR_BUNDLE_ID_KEY) }
        set { UserDefaults.standard.set(newValue, forKey: EDITOR_BUNDLE_ID_KEY) }
    }

    static var savedAppPath: String? {
        get { UserDefaults.standard.string(forKey: EDITOR_APP_PATH_KEY) }
        set { UserDefaults.standard.set(newValue, forKey: EDITOR_APP_PATH_KEY) }
    }

    static func save(bundleID: String) {
        savedBundleID = bundleID
        savedAppPath = nil
    }

    static func save(customPath: String) {
        savedBundleID = nil
        savedAppPath = customPath
    }

    /// Display name for the currently saved preference (for UI).
    static var currentDisplayName: String {
        if let id = savedBundleID,
           let editor = EditorApp.known.first(where: { $0.id == id }) {
            return editor.name
        }
        if let path = savedAppPath {
            return URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        }
        return EditorApp.installed.first?.name ?? "None"
    }
}
