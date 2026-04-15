import Foundation
import Combine

@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []

    private let storageURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(storageURL: URL? = nil) {
        self.storageURL = storageURL ?? Self.defaultStorageURL()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        load()
    }

    func addTask(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        tasks.append(TaskItem(title: trimmed))
        sortAndSave()
    }

    func toggleCompletion(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isCompleted.toggle()
        tasks[index].completedAt = tasks[index].isCompleted ? Date() : nil
        tasks[index].updatedAt = Date()
        sortAndSave()
    }

    func editTask(id: UUID, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].title = trimmed
        tasks[index].updatedAt = Date()
        sortAndSave()
    }

    func deleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL) else {
            tasks = []
            return
        }
        tasks = (try? decoder.decode([TaskItem].self, from: data)) ?? []
        sortInPlace()
    }

    private func sortAndSave() {
        sortInPlace()
        save()
    }

    private func sortInPlace() {
        tasks.sort {
            if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
            if $0.isCompleted {
                return ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast)
            }
            return $0.createdAt < $1.createdAt
        }
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: storageURL.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: nil
            )
            let data = try encoder.encode(tasks)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("macIsland: Failed to save tasks: \(error)")
        }
    }

    private static func defaultStorageURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base
            .appendingPathComponent("macIsland", isDirectory: true)
            .appendingPathComponent("tasks.json")
    }
}
