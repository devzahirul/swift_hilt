import Foundation

public struct CreateTaskUseCase {
    let repo: TaskRepository
    public init(repo: TaskRepository) { self.repo = repo }
    public func callAsFunction(_ newTask: NewTask) async throws -> Todo { try await repo.create(newTask) }
}

public struct UpdateTaskUseCase {
    let repo: TaskRepository
    public init(repo: TaskRepository) { self.repo = repo }
    public func callAsFunction(_ task: Todo) async throws -> Todo { try await repo.update(task) }
}

public struct DeleteTaskUseCase {
    let repo: TaskRepository
    public init(repo: TaskRepository) { self.repo = repo }
    public func callAsFunction(_ id: UUID) async throws { try await repo.delete(id: id) }
}

public struct ToggleTaskCompletionUseCase {
    let repo: TaskRepository
    public init(repo: TaskRepository) { self.repo = repo }
    public func callAsFunction(_ id: UUID) async throws -> Todo { try await repo.toggleCompleted(id: id) }
}

public struct QueryTasksUseCase {
    let repo: TaskRepository
    public init(repo: TaskRepository) { self.repo = repo }
    public func callAsFunction(_ query: TaskQuery) async throws -> [Todo] { try await repo.query(query) }
}

public struct ObserveTasksUseCase {
    let repo: TaskRepository
    public init(repo: TaskRepository) { self.repo = repo }
    public func callAsFunction(_ query: TaskQuery) -> AsyncStream<[Todo]> { repo.observe(query) }
}
