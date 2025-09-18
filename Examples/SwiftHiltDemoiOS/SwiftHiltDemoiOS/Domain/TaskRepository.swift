import Foundation

public protocol TaskRepository {
    func create(_ newTask: NewTask) async throws -> Todo
    func update(_ task: Todo) async throws -> Todo
    func delete(id: UUID) async throws
    func toggleCompleted(id: UUID) async throws -> Todo
    func query(_ query: TaskQuery) async throws -> [Todo]
    func observe(_ query: TaskQuery) -> AsyncStream<[Todo]>
}
