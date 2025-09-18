import XCTest
@testable import SwiftHiltDemoiOS
import SwiftHilt

final class InMemoryTaskRepositoryTests: XCTestCase {
    func makeContainer() -> Container {
        let c = Container()
        c.install {
            provide(TaskRepository.self, lifetime: .singleton) { _ in InMemoryTaskRepository() }
            provide(CreateTaskUseCase.self) { r in CreateTaskUseCase(repo: r.resolve()) }
            provide(UpdateTaskUseCase.self) { r in UpdateTaskUseCase(repo: r.resolve()) }
            provide(DeleteTaskUseCase.self) { r in DeleteTaskUseCase(repo: r.resolve()) }
            provide(ToggleTaskCompletionUseCase.self) { r in ToggleTaskCompletionUseCase(repo: r.resolve()) }
            provide(QueryTasksUseCase.self) { r in QueryTasksUseCase(repo: r.resolve()) }
            provide(ObserveTasksUseCase.self) { r in ObserveTasksUseCase(repo: r.resolve()) }
        }
        return c
    }

    func testCreateQueryToggleDelete() async throws {
        let c = makeContainer(); useContainer(c)
        let create = resolve(CreateTaskUseCase.self)
        let query = resolve(QueryTasksUseCase.self)
        let toggle = resolve(ToggleTaskCompletionUseCase.self)
        let remove = resolve(DeleteTaskUseCase.self)

        let t1 = try await create(NewTask(title: "A", dueDate: Date().addingTimeInterval(3600), priority: .normal))
        let t2 = try await create(NewTask(title: "B urgent", dueDate: Date().addingTimeInterval(7200), priority: .urgent))
        _ = try await create(NewTask(title: "C done", priority: .low))

        var all = try await query(TaskQuery(includeCompleted: true, sort: .byCreatedAtDesc))
        XCTAssertEqual(all.count, 3)

        var dueAsc = try await query(TaskQuery(includeCompleted: true, sort: .byDueDateAsc))
        XCTAssertEqual(dueAsc.first?.id, t1.id)

        _ = try await toggle(t2.id)
        var completedOnly = try await query(TaskQuery(search: "urgent", includeCompleted: true))
        XCTAssertTrue(completedOnly.contains { $0.id == t2.id })

        try await remove(t1.id)
        all = try await query(TaskQuery(includeCompleted: true))
        XCTAssertEqual(all.count, 2)
    }
}

