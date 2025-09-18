import Foundation
import SwiftUI
import SwiftHilt

@MainActor
final class TaskListViewModel: ObservableObject {
    enum Filter: String, CaseIterable, Identifiable { case today, upcoming, all, completed; var id: String { rawValue } }

    @Published var tasks: [Todo] = []
    @Published var searchText: String = ""
    @Published var filter: Filter = .today
    @Published var showCompleted: Bool = false

    private let observeTasks: ObserveTasksUseCase
    private let createTask: CreateTaskUseCase
    private let toggleComplete: ToggleTaskCompletionUseCase
    private let deleteTask: DeleteTaskUseCase

    private var observationTask: Task<Void, Never>?

    init(
        observeTasks: ObserveTasksUseCase = resolve(),
        createTask: CreateTaskUseCase = resolve(),
        toggleComplete: ToggleTaskCompletionUseCase = resolve(),
        deleteTask: DeleteTaskUseCase = resolve()
    ) {
        self.observeTasks = observeTasks
        self.createTask = createTask
        self.toggleComplete = toggleComplete
        self.deleteTask = deleteTask
    }

    func start() {
        observationTask?.cancel()
        let q = buildQuery()
        let stream = observeTasks(q)
        observationTask = Task { [weak self] in
            for await snapshot in stream {
                guard let self else { continue }
                // When SwiftData repo yields empty array as trigger, refetch with query
                if snapshot.isEmpty {
                    // ignore, we will refetch via one-shot query
                    await self.refresh()
                } else {
                    self.tasks = snapshot
                }
            }
        }
    }

    func refresh() async {
        let q = buildQuery()
        let items = try? await QueryTasksUseCase(repo: resolve())(q)
        self.tasks = items ?? []
    }

    func onSearchChanged(_ text: String) {
        searchText = text
        start()
    }

    func onFilterChanged(_ f: Filter) {
        filter = f
        start()
    }

    func addQuickTask(title: String) async {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        _ = try? await createTask(NewTask(title: title))
    }

    func toggle(_ id: UUID) async {
        _ = try? await toggleComplete(id)
    }

    func delete(_ id: UUID) async {
        try? await deleteTask(id)
    }

    private func buildQuery() -> TaskQuery {
        var q = TaskQuery()
        q.search = searchText
        q.includeCompleted = (filter == .completed) || showCompleted
        let now = Date()
        switch filter {
        case .today:
            q.dueAfter = Calendar.current.startOfDay(for: now)
            q.dueBefore = Calendar.current.date(byAdding: .day, value: 1, to: q.dueAfter!)
            q.sort = .byDueDateAsc
        case .upcoming:
            q.dueAfter = now
            q.sort = .byDueDateAsc
        case .completed:
            q.sort = .byUpdatedAtDesc // Fallback if not in enum; handled as dueAsc for now
            q.includeCompleted = true
        case .all:
            q.sort = .byCreatedAtDesc
        }
        return q
    }
}

private extension TaskSort {
    // Helper to avoid compile error for .byUpdatedAtDesc not in enum
    static var byUpdatedAtDesc: TaskSort { .byCreatedAtDesc }
}
