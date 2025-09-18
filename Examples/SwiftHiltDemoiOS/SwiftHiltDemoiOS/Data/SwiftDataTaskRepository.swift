#if canImport(SwiftData)
import Foundation
import SwiftData

@available(iOS 17, *)
@Model
final class SDTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String?
    var isCompleted: Bool
    var dueDate: Date?
    var priorityRaw: Int
    var project: String?
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        priorityRaw: Int = TaskPriority.normal.rawValue,
        project: String? = nil,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.priorityRaw = priorityRaw
        self.project = project
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@available(iOS 17, *)
extension SDTask {
    convenience init(from t: Todo) {
        self.init(
            id: t.id,
            title: t.title,
            notes: t.notes,
            isCompleted: t.isCompleted,
            dueDate: t.dueDate,
            priorityRaw: t.priority.rawValue,
            project: t.project,
            tags: t.tags,
            createdAt: t.createdAt,
            updatedAt: t.updatedAt
        )
    }

    var asDomain: Todo {
        Todo(
            id: id,
            title: title,
            notes: notes,
            isCompleted: isCompleted,
            dueDate: dueDate,
            priority: TaskPriority(rawValue: priorityRaw) ?? .normal,
            project: project,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

@available(iOS 17, *)
    final class SwiftDataTaskRepository: TaskRepository {
        private let container: ModelContainer
        private let context: ModelContext
        private var listeners: [UUID: AsyncStream<[Todo]>.Continuation] = [:]

    init(container: ModelContainer) {
        self.container = container
        self.context = ModelContext(container)
    }

    func create(_ newTask: NewTask) async throws -> Todo {
        let model = SDTask(
            title: newTask.title,
            notes: newTask.notes,
            isCompleted: false,
            dueDate: newTask.dueDate,
            priorityRaw: newTask.priority.rawValue,
            project: newTask.project,
            tags: newTask.tags,
            createdAt: Date(),
            updatedAt: Date()
        )
        context.insert(model)
        try context.save()
        notify()
        return model.asDomain
    }

    func update(_ task: Todo) async throws -> Todo {
        let fetch = FetchDescriptor<SDTask>(predicate: #Predicate { $0.id == task.id })
        if let model = try context.fetch(fetch).first {
            model.title = task.title
            model.notes = task.notes
            model.isCompleted = task.isCompleted
            model.dueDate = task.dueDate
            model.priorityRaw = task.priority.rawValue
            model.project = task.project
            model.tags = task.tags
            model.updatedAt = Date()
            try context.save()
            notify()
            return model.asDomain
        } else {
            // Upsert
            return try await create(NewTask(
                title: task.title,
                notes: task.notes,
                dueDate: task.dueDate,
                priority: task.priority,
                project: task.project,
                tags: task.tags
            ))
        }
    }

    func delete(id: UUID) async throws {
        let fetch = FetchDescriptor<SDTask>(predicate: #Predicate { $0.id == id })
        if let model = try context.fetch(fetch).first {
            context.delete(model)
            try context.save()
            notify()
        }
    }

    func toggleCompleted(id: UUID) async throws -> Todo {
        let fetch = FetchDescriptor<SDTask>(predicate: #Predicate { $0.id == id })
        guard let model = try context.fetch(fetch).first else { throw NSError(domain: "Task", code: 404) }
        model.isCompleted.toggle()
        model.updatedAt = Date()
        try context.save()
        notify()
        return model.asDomain
    }

    func query(_ query: TaskQuery) async throws -> [Todo] {
        var predicate: Predicate<SDTask> = #Predicate { _ in true }
        if !query.includeCompleted {
            predicate = #Predicate { !$0.isCompleted }
        }
        if let search = query.search, !search.isEmpty {
            predicate = #Predicate { t in
                (!t.isCompleted || query.includeCompleted) &&
                (t.title.localizedStandardContains(search) || (t.notes?.localizedStandardContains(search) ?? false))
            }
        }
        if let project = query.project {
            predicate = #Predicate { t in (t.project == project) && (query.includeCompleted || !t.isCompleted) }
        }
        // For tags/dates we post-filter due to SwiftData predicate limitations for arrays
        var fetch = FetchDescriptor<SDTask>(predicate: predicate)
        switch query.sort {
        case .byDueDateAsc:
            fetch.sortBy = [SortDescriptor(\.dueDate, order: .forward)]
        case .byDueDateDesc:
            fetch.sortBy = [SortDescriptor(\.dueDate, order: .reverse)]
        case .byPriorityDesc:
            fetch.sortBy = [SortDescriptor(\.priorityRaw, order: .reverse)]
        case .byCreatedAtDesc:
            fetch.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
        }
        var items = try context.fetch(fetch).map { $0.asDomain }
        if let tags = query.tags, !tags.isEmpty {
            items = items.filter { !Set(tags).isDisjoint(with: Set($0.tags)) }
        }
        if let after = query.dueAfter { items = items.filter { ($0.dueDate ?? .distantFuture) >= after } }
        if let before = query.dueBefore { items = items.filter { ($0.dueDate ?? .distantPast) <= before } }
        return items
    }

    func observe(_ query: TaskQuery) -> AsyncStream<[Todo]> {
        let id = UUID()
        return AsyncStream { continuation in
            Task { [weak self] in
                guard let self else { return }
                let initial = try? await self.query(query)
                continuation.yield(initial ?? [])
                self.listeners[id] = continuation
            }
            continuation.onTermination = { [weak self] _ in self?.listeners[id] = nil }
        }
    }

    private func notify() {
        // Observers fetch with their own query on next tick
        for (_, cont) in listeners {
            cont.yield([]) // trigger consumers to refetch (pattern for demo)
        }
    }
}

@available(iOS 17, *)
struct SwiftDataStack {
    let container: ModelContainer
    init(inMemory: Bool = false) {
        let schema = Schema([SDTask.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        self.container = try! ModelContainer(for: schema, configurations: config)
    }
}
#endif
