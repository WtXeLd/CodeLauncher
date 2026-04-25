import Foundation
import SQLite3

enum VSCodeReader {
    static func readRecentProjects() -> [Project] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let candidates = [
            "Library/Application Support/Code/User/globalStorage/state.vscdb",
            "Library/Application Support/Cursor/User/globalStorage/state.vscdb",
        ]
        for relative in candidates {
            let url = home.appendingPathComponent(relative)
            if let projects = readDatabase(at: url), !projects.isEmpty {
                return projects
            }
        }
        return []
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

            guard let uri = rawURI,
                  let fileURL = URL(string: uri),
                  fileURL.scheme == "file" else { continue }

            let path = fileURL.path
            guard seen.insert(path).inserted else { continue }
            projects.append(Project(path: path))
        }
        return projects
    }
}
