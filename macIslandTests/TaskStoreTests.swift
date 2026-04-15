import XCTest
@testable import macIsland

@MainActor
final class TaskStoreTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    func testAddTask_createsIncompleteTaskAtTopGroup() throws {
        let store = TaskStore(storageURL: tempDirectory.appendingPathComponent("tasks.json"))

        store.addTask(title: "Write plan")

        XCTAssertEqual(store.tasks.map(\.title), ["Write plan"])
        XCTAssertEqual(store.tasks.first?.isCompleted, false)
    }

    func testToggleCompletion_movesTaskBelowIncompleteTasks() throws {
        let store = TaskStore(storageURL: tempDirectory.appendingPathComponent("tasks.json"))
        store.addTask(title: "First")
        store.addTask(title: "Second")

        let firstID = try XCTUnwrap(store.tasks.first?.id)
        store.toggleCompletion(id: firstID)

        XCTAssertEqual(store.tasks.map(\.title), ["Second", "First"])
        XCTAssertEqual(store.tasks.last?.isCompleted, true)
    }

    func testEditTask_updatesTitleWithoutChangingOrdering() throws {
        let store = TaskStore(storageURL: tempDirectory.appendingPathComponent("tasks.json"))
        store.addTask(title: "Draft")

        let id = try XCTUnwrap(store.tasks.first?.id)
        store.editTask(id: id, title: "Final")

        XCTAssertEqual(store.tasks.map(\.title), ["Final"])
    }

    func testDeleteTask_removesTask() throws {
        let store = TaskStore(storageURL: tempDirectory.appendingPathComponent("tasks.json"))
        store.addTask(title: "Remove me")

        let id = try XCTUnwrap(store.tasks.first?.id)
        store.deleteTask(id: id)

        XCTAssertTrue(store.tasks.isEmpty)
    }

    func testPersistenceRoundTrip_restoresSortedTasks() throws {
        let url = tempDirectory.appendingPathComponent("tasks.json")
        let writer = TaskStore(storageURL: url)
        writer.addTask(title: "Active")
        writer.addTask(title: "Done")

        let doneID = try XCTUnwrap(writer.tasks.last?.id)
        writer.toggleCompletion(id: doneID)

        let reader = TaskStore(storageURL: url)
        XCTAssertEqual(reader.tasks.map(\.title), ["Active", "Done"])
        XCTAssertEqual(reader.tasks.last?.isCompleted, true)
    }
}
