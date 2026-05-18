import Foundation
import SQLite3

enum VSCodeReader {
    static func readRecentProjects() -> [Project] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let candidates = [
            "Library/Application Support/Code/User/globalStorage",
            "Library/Application Support/Cursor/User/globalStorage",
        ]

        var seen = Set<String>()
        var projects: [Project] = []

        for relative in candidates {
            let url = home.appendingPathComponent(relative)
            append(readStorageJSON(at: url.appendingPathComponent("storage.json")), seen: &seen, projects: &projects)
            append(readDatabase(at: url.appendingPathComponent("state.vscdb")), seen: &seen, projects: &projects)
            append(readDatabase(at: url.appendingPathComponent("state.vscdb.backup")), seen: &seen, projects: &projects)
        }

        return projects
    }

    private static func readStorageJSON(at url: URL) -> [Project]? {
        guard
            let data = try? Data(contentsOf: url),
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        var seen = Set<String>()
        var projects: [Project] = []

        if let menubarData = root["lastKnownMenubarData"] as? [String: Any] {
            collectMenubarProjects(from: menubarData, seen: &seen, projects: &projects)
        }

        if let backupWorkspaces = root["backupWorkspaces"] as? [String: Any] {
            collectBackupWorkspaceProjects(from: backupWorkspaces, seen: &seen, projects: &projects)
        }

        if let profileAssociations = root["profileAssociations"] as? [String: Any] {
            collectProfileAssociationProjects(from: profileAssociations, seen: &seen, projects: &projects)
        }

        return projects
    }

    private static func readDatabase(at url: URL) -> [Project]? {
        var db: OpaquePointer?
        guard sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_close(db) }

        var stmt: OpaquePointer?
        let sql = "SELECT value FROM ItemTable WHERE key = 'history.recentlyOpenedPathsList'"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_step(stmt) == SQLITE_ROW, let cStr = sqlite3_column_text(stmt, 0) else { return nil }
        return parseEntries(from: String(cString: cStr))
    }

    private static func parseEntries(from json: String) -> [Project] {
        guard
            let data = json.data(using: .utf8),
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let entries = root["entries"] as? [[String: Any]]
        else { return [] }

        var seen = Set<String>()
        var projects: [Project] = []

        for entry in entries {
            let rawURI: String?
            if let folderUri = entry["folderUri"] as? String {
                rawURI = folderUri
            } else if let ws = entry["workspace"] as? [String: Any],
                      let configPath = ws["configPath"] as? String {
                rawURI = configPath
            } else {
                rawURI = nil
            }

            appendProject(fromURI: rawURI, seen: &seen, projects: &projects)
        }
        return projects
    }

    private static func collectMenubarProjects(from value: [String: Any], seen: inout Set<String>, projects: inout [Project]) {
        guard
            let menus = value["menus"] as? [String: Any],
            let fileMenu = menus["File"] as? [String: Any],
            let items = fileMenu["items"] as? [[String: Any]]
        else { return }

        collectMenubarProjects(from: items, seen: &seen, projects: &projects)
    }

    private static func collectMenubarProjects(from items: [[String: Any]], seen: inout Set<String>, projects: inout [Project]) {
        for item in items {
            if let id = item["id"] as? String, id == "openRecentFolder" || id == "openRecentWorkspace" {
                appendProject(fromURIValue: item["uri"], seen: &seen, projects: &projects)
            }

            if let submenu = item["submenu"] as? [String: Any],
               let children = submenu["items"] as? [[String: Any]] {
                collectMenubarProjects(from: children, seen: &seen, projects: &projects)
            }
        }
    }

    private static func collectBackupWorkspaceProjects(from value: [String: Any], seen: inout Set<String>, projects: inout [Project]) {
        if let folders = value["folders"] as? [[String: Any]] {
            for folder in folders {
                appendProject(fromURI: folder["folderUri"] as? String, seen: &seen, projects: &projects)
            }
        }

        if let workspaces = value["workspaces"] as? [[String: Any]] {
            for workspace in workspaces {
                appendProject(fromURIValue: workspace["configPath"], seen: &seen, projects: &projects)
            }
        }
    }

    private static func collectProfileAssociationProjects(from value: [String: Any], seen: inout Set<String>, projects: inout [Project]) {
        guard let workspaces = value["workspaces"] as? [String: Any] else { return }

        for uri in workspaces.keys {
            appendProject(fromURI: uri, seen: &seen, projects: &projects)
        }
    }

    private static func append(_ newProjects: [Project]?, seen: inout Set<String>, projects: inout [Project]) {
        guard let newProjects else { return }

        for project in newProjects where seen.insert(project.path).inserted {
            projects.append(project)
        }
    }

    private static func appendProject(fromURIValue value: Any?, seen: inout Set<String>, projects: inout [Project]) {
        if let uri = value as? String {
            appendProject(fromURI: uri, seen: &seen, projects: &projects)
        } else if let uri = value as? [String: Any], uri["scheme"] as? String == "file", let path = uri["path"] as? String {
            appendProject(fromPath: path, seen: &seen, projects: &projects)
        }
    }

    private static func appendProject(fromURI uri: String?, seen: inout Set<String>, projects: inout [Project]) {
        guard let uri,
              let fileURL = URL(string: uri),
              fileURL.scheme == "file" else { return }

        appendProject(fromPath: fileURL.path, seen: &seen, projects: &projects)
    }

    private static func appendProject(fromPath path: String, seen: inout Set<String>, projects: inout [Project]) {
        guard seen.insert(path).inserted else { return }
        projects.append(Project(path: path))
    }
}
