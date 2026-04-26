import AppKit
import Observation

private struct GitHubRelease: Decodable, Sendable {
    let tagName: String
    let body: String?
    let htmlUrl: String
    let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case body
        case htmlUrl = "html_url"
        case assets
    }
}

private struct GitHubAsset: Decodable, Sendable {
    let name: String
    let browserDownloadUrl: URL

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadUrl = "browser_download_url"
    }
}

private let kLastCheckDate = "lastUpdateCheckDate"
private let kCheckCooldown: TimeInterval = 86400
private let kAPIURL = URL(string: "https://api.github.com/repos/WtXeLd/CodeLauncher/releases/latest")!

@Observable
@MainActor
final class UpdateChecker {
    static let shared = UpdateChecker()

    enum CheckState: Equatable {
        case idle, checking, upToDate
        case updateAvailable(String)
        case error(String)
    }

    private(set) var checkState: CheckState = .idle

    private init() {}

    // MARK: - Version & Arch

    static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }

    static var currentArch: String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [UInt8](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(decoding: machine.prefix(while: { $0 != 0 }), as: UTF8.self)
    }

    // MARK: - Public API

    func checkOnLaunch() async {
        guard Self.currentVersion != "dev" else { return }
        if let last = UserDefaults.standard.object(forKey: kLastCheckDate) as? Date,
           Date().timeIntervalSince(last) < kCheckCooldown { return }
        await performCheck(silent: true)
    }

    func checkManually() async {
        await performCheck(silent: false)
    }

    // MARK: - Core

    private func performCheck(silent: Bool) async {
        checkState = .checking
        var request = URLRequest(url: kAPIURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("CodeLauncher/\(Self.currentVersion)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            UserDefaults.standard.set(Date(), forKey: kLastCheckDate)

            let remote = release.tagName.hasPrefix("v")
                ? String(release.tagName.dropFirst())
                : release.tagName

            if Self.isNewer(remote, than: Self.currentVersion) {
                checkState = .updateAvailable(remote)
                showUpdateAlert(release: release, version: remote)
            } else {
                checkState = .upToDate
                if !silent { showUpToDateAlert() }
            }
        } catch {
            checkState = silent ? .idle : .error(error.localizedDescription)
        }
    }

    private static func isNewer(_ remote: String, than local: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let l = local.split(separator: ".").compactMap { Int($0) }
        let count = max(r.count, l.count)
        for i in 0..<count {
            let rv = i < r.count ? r[i] : 0
            let lv = i < l.count ? l[i] : 0
            if rv != lv { return rv > lv }
        }
        return false
    }

    // MARK: - Alerts

    private func showUpdateAlert(release: GitHubRelease, version: String) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "New Version Available"
        alert.informativeText = "v\(version) is available (current: v\(Self.currentVersion))"
        if let notes = release.body, !notes.isEmpty {
            alert.informativeText += "\n\n\(Self.cleanMarkdown(notes))"
        }
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            Task { await downloadAndOpen(release: release, version: version) }
        }
    }

    private func showUpToDateAlert() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "You're Up to Date"
        alert.informativeText = "CodeLauncher v\(Self.currentVersion) is the latest version."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private static func cleanMarkdown(_ text: String) -> String {
        var result = text
        // **bold** → bold
        result = result.replacingOccurrences(
            of: #"\*\*(.+?)\*\*"#, with: "$1", options: .regularExpression)
        // [text](url) → text (url)
        result = result.replacingOccurrences(
            of: #"\[(.+?)\]\((.+?)\)"#, with: "$1 ($2)", options: .regularExpression)
        // `code` → code
        result = result.replacingOccurrences(of: "`", with: "")
        // ### heading → heading
        result = result.replacingOccurrences(
            of: #"(?m)^#{1,6}\s+"#, with: "", options: .regularExpression)
        // - list item → • list item
        result = result.replacingOccurrences(
            of: #"(?m)^[-*]\s+"#, with: "• ", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Download

    private func downloadAndOpen(release: GitHubRelease, version: String) async {
        let expectedName = "CodeLauncher-\(version)-\(Self.currentArch).dmg"
        guard let asset = release.assets.first(where: { $0.name == expectedName }) else {
            if let url = URL(string: release.htmlUrl) {
                NSWorkspace.shared.open(url)
            }
            return
        }

        do {
            let (tempURL, _) = try await URLSession.shared.download(from: asset.browserDownloadUrl)
            let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
            let dest = downloads.appendingPathComponent(asset.name)
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.moveItem(at: tempURL, to: dest)
            NSWorkspace.shared.open(dest)
        } catch {
            if let url = URL(string: release.htmlUrl) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
