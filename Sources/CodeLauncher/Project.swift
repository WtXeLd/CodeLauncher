import Foundation

struct Project: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let path: String

    init(path: String) {
        self.id = UUID()
        self.path = path
        self.name = URL(fileURLWithPath: path).lastPathComponent
    }
}
