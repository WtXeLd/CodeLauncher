import AppKit
import Observation

@Observable
@MainActor
final class LaunchViewModel {
    var searchText = "" {
        didSet { selectedIndex = 0 }
    }
    var selectedIndex = 0
    private(set) var allProjects: [Project] = []

    var filteredProjects: [Project] {
        guard !searchText.isEmpty else { return allProjects }
        return allProjects.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.path.localizedCaseInsensitiveContains(searchText)
        }
    }

    func load() {
        allProjects = VSCodeReader.readRecentProjects()
    }

    func moveSelection(by delta: Int) {
        let count = filteredProjects.count
        guard count > 0 else { return }
        selectedIndex = max(0, min(selectedIndex + delta, count - 1))
    }

    func openSelected() {
        guard selectedIndex < filteredProjects.count else { return }
        openProject(filteredProjects[selectedIndex])
    }

    func openProject(_ project: Project) {
        let url = URL(fileURLWithPath: project.path)
        let bundleIDs = ["com.microsoft.VSCode", "com.todesktop.230313mzl4w4u92"]
        for id in bundleIDs {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) {
                NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration())
                return
            }
        }
        NSWorkspace.shared.open(url)
    }

    func openInFinder(_ project: Project) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: project.path)
    }

    func openAtIndex(_ index: Int) {
        guard index < filteredProjects.count else { return }
        openProject(filteredProjects[index])
    }
}
