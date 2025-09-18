import Foundation

final class InMemoryTaskRepository: TaskRepository {
    private let queue = DispatchQueue(label: "InMemoryTaskRepository.serial")
    private var tasks: [UUID: Todo] = [:]
    private var listeners: [UUID: AsyncStream<[Todo]>.Continuation] = [:]

    func create(_ newTask: NewTask) async throws -> Todo {
        var task = Todo(
            title: newTask.title,
            notes: newTask.notes,
            isCompleted: false,
            dueDate: newTask.dueDate,
            priority: newTask.priority,
            project: newTask.project,
            tags: newTask.tags,
            createdAt: Date(),
            updatedAt: Date()
        )
        queue.sync {
            tasks[task.id] = task
            notifyLocked()
        }
        return task
    }

    func update(_ task: Todo) async throws -> Todo {
        var updated = task
        updated.updatedAt = Date()
        queue.sync {
            tasks[updated.id] = updated
            notifyLocked()
        }
        return updated
    }

    func delete(id: UUID) async throws {
        queue.sync {
            tasks[id] = nil
            notifyLocked()
        }
    }

    func toggleCompleted(id: UUID) async throws -> Todo {
        var result: Todo = Todo(title: "")
        queue.sync {
            guard var t = tasks[id] else { return }
            t.isCompleted.toggle()
            t.updatedAt = Date()
            tasks[id] = t
            result = t
            notifyLocked()
        }
        if result.title.isEmpty { throw NSError(domain: "Task", code: 404) }
        return result
    }

    func query(_ query: TaskQuery) async throws -> [Todo] {
        return queue.sync { applyQuery(Array(tasks.values), query: query) }
    }

    func observe(_ query: TaskQuery) -> AsyncStream<[Todo]> {
        let id = UUID()
        return AsyncStream { continuation in
            self.queue.sync {
                let snap = self.applyQuery(Array(self.tasks.values), query: query)
                continuation.yield(snap)
                self.listeners[id] = continuation
            }
            continuation.onTermination = { [weak self] _ in
                self?.queue.sync { self?.listeners[id] = nil }
            }
        }
    }

    private func notify() {
        queue.sync { notifyLocked() }
    }

    private func notifyLocked() {
        let snapshot = Array(tasks.values)
        for (_, cont) in listeners {
            cont.yield(snapshot)
        }
    }

    private func applyQuery(_ items: [Todo], query: TaskQuery) -> [Todo] {
        var filtered = items
        if !query.includeCompleted { filtered = filtered.filter { !$0.isCompleted } }
        if let q = query.search, !q.isEmpty {
            filtered = filtered.filter { $0.title.localizedCaseInsensitiveContains(q) || ($0.notes?.localizedCaseInsensitiveContains(q) ?? false) }
        }
        if let project = query.project { filtered = filtered.filter { $0.project == project } }
        if let tags = query.tags, !tags.isEmpty { filtered = filtered.filter { !Set(tags).isDisjoint(with: Set($0.tags)) } }
        if let after = query.dueAfter { filtered = filtered.filter { ($0.dueDate ?? .distantFuture) >= after } }
        if let before = query.dueBefore { filtered = filtered.filter { ($0.dueDate ?? .distantPast) <= before } }
        switch query.sort {
        case .byDueDateAsc:
            filtered.sort { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        case .byDueDateDesc:
            filtered.sort { ($0.dueDate ?? .distantPast) > ($1.dueDate ?? .distantPast) }
        case .byPriorityDesc:
            filtered.sort { $0.priority.rawValue > $1.priority.rawValue }
        case .byCreatedAtDesc:
            filtered.sort { $0.createdAt > $1.createdAt }
        }
        return filtered
    }
}
