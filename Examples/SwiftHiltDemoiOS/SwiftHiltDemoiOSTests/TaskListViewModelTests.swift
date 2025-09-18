import XCTest
@testable import SwiftHiltDemoiOS
import SwiftHilt

@MainActor
final class TaskListViewModelTests: XCTestCase {
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

    func testRefreshAndSearch() async throws {
        let c = makeContainer(); useContainer(c)
        let create = resolve(CreateTaskUseCase.self)

        _ = try await create(NewTask(title: "Buy milk", priority: .normal))
        _ = try await create(NewTask(title: "Email Alice", priority: .high))
        _ = try await create(NewTask(title: "Write report", priority: .urgent))

        let vm = TaskListViewModel()
        await vm.refresh()
        XCTAssertEqual(vm.tasks.count, 3)

        vm.onSearchChanged("Email")
        // start() uses observe; we can force refresh for determinism
        await vm.refresh()
        XCTAssertEqual(vm.tasks.count, 1)
        XCTAssertEqual(vm.tasks.first?.title, "Email Alice")
    }
}

