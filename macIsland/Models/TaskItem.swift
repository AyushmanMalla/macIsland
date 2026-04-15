import Foundation

struct TaskItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    let createdAt: Date
    var completedAt: Date?
    var updatedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.updatedAt = updatedAt
    }
}

enum ExpandedTab: String, CaseIterable, Identifiable {
    case music
    case tasks

    var id: Self { self }
}
