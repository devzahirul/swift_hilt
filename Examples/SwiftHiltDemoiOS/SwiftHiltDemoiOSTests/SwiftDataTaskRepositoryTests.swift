#if canImport(SwiftData)
import XCTest
@testable import SwiftHiltDemoiOS

@available(iOS 17, *)
final class SwiftDataTaskRepositoryTests: XCTestCase {
    func testCRUD() async throws {
        let stack = SwiftDataStack(inMemory: true)
        let repo = SwiftDataTaskRepository(container: stack.container)
        let create = CreateTaskUseCase(repo: repo)
        let query = QueryTasksUseCase(repo: repo)
        let toggle = ToggleTaskCompletionUseCase(repo: repo)
        let remove = DeleteTaskUseCase(repo: repo)

        let t = try await create(NewTask(title: "SData Test", priority: .normal))
        var all = try await query(TaskQuery(includeCompleted: true))
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all[0].id, t.id)

        _ = try await toggle(t.id)
        all = try await query(TaskQuery(includeCompleted: true))
        XCTAssertTrue(all[0].isCompleted)

        try await remove(t.id)
        all = try await query(TaskQuery(includeCompleted: true))
        XCTAssertTrue(all.isEmpty)
    }
}
#endif

