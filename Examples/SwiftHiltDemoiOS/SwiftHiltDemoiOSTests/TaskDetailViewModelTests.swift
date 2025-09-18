import XCTest
@testable import SwiftHiltDemoiOS
import SwiftHilt

@MainActor
final class TaskDetailViewModelTests: XCTestCase {
    func makeContainer() -> Container {
        let c = Container()
        c.install {
            provide(TaskRepository.self, lifetime: .singleton) { _ in InMemoryTaskRepository() }
            provide(CreateTaskUseCase.self) { r in CreateTaskUseCase(repo: r.resolve()) }
            provide(UpdateTaskUseCase.self) { r in UpdateTaskUseCase(repo: r.resolve()) }
            provide(DeleteTaskUseCase.self) { r in DeleteTaskUseCase(repo: r.resolve()) }
            provide(QueryTasksUseCase.self) { r in QueryTasksUseCase(repo: r.resolve()) }
        }
        return c
    }

    func testCreateAndEditAndDelete() async throws {
        let c = makeContainer(); useContainer(c)
        let query = resolve(QueryTasksUseCase.self)

        // Create new
        let createVM = TaskDetailViewModel()
        createVM.title = "New Task"
        createVM.notes = "Notes"
        createVM.hasDueDate = true
        createVM.dueDate = Date().addingTimeInterval(600)
        createVM.priority = .high
        createVM.project = "Home"
        createVM.tagsInput = "chores, urgent"
        try await createVM.save()

        var all = try await query(TaskQuery(includeCompleted: true))
        XCTAssertEqual(all.count, 1)
        var task = all[0]
        XCTAssertEqual(task.title, "New Task")
        XCTAssertEqual(task.priority, .high)
        XCTAssertEqual(Set(task.tags), Set(["chores", "urgent"]))

        // Edit
        var editVM = TaskDetailViewModel(task: task)
        editVM.title = "Updated Task"
        editVM.isCompleted = true
        try await editVM.save()

        all = try await query(TaskQuery(includeCompleted: true))
        task = all[0]
        XCTAssertEqual(task.title, "Updated Task")
        XCTAssertTrue(task.isCompleted)

        // Delete
        editVM = TaskDetailViewModel(task: task)
        try await editVM.delete()
        all = try await query(TaskQuery(includeCompleted: true))
        XCTAssertTrue(all.isEmpty)
    }
}

