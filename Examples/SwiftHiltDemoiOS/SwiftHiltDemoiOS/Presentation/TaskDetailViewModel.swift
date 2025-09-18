import Foundation
import SwiftUI
import SwiftHilt

@MainActor
final class TaskDetailViewModel: ObservableObject {
    // Form fields
    @Published var title: String = ""
    @Published var notes: String = ""
    @Published var isCompleted: Bool = false
    @Published var hasDueDate: Bool = false
    @Published var dueDate: Date = Date()
    @Published var priority: TaskPriority = .normal
    @Published var project: String = ""
    @Published var tagsInput: String = ""

    private(set) var editingId: UUID?

    private let createTask: CreateTaskUseCase
    private let updateTask: UpdateTaskUseCase
    private let deleteTask: DeleteTaskUseCase

    init(
        task: Todo? = nil,
        createTask: CreateTaskUseCase = resolve(),
        updateTask: UpdateTaskUseCase = resolve(),
        deleteTask: DeleteTaskUseCase = resolve()
    ) {
        self.createTask = createTask
        self.updateTask = updateTask
        self.deleteTask = deleteTask
        if let t = task {
            self.editingId = t.id
            self.title = t.title
            self.notes = t.notes ?? ""
            self.isCompleted = t.isCompleted
            if let d = t.dueDate { self.hasDueDate = true; self.dueDate = d }
            self.priority = t.priority
            self.project = t.project ?? ""
            self.tagsInput = t.tags.joined(separator: ", ")
        }
    }

    var canSave: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    func save() async throws {
        if let id = editingId {
            var t = Todo(
                id: id,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes.isEmpty ? nil : notes,
                isCompleted: isCompleted,
                dueDate: hasDueDate ? dueDate : nil,
                priority: priority,
                project: project.isEmpty ? nil : project,
                tags: parseTags(),
                createdAt: Date(),
                updatedAt: Date()
            )
            _ = try await updateTask(t)
        } else {
            let new = NewTask(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes.isEmpty ? nil : notes,
                dueDate: hasDueDate ? dueDate : nil,
                priority: priority,
                project: project.isEmpty ? nil : project,
                tags: parseTags()
            )
            _ = try await createTask(new)
        }
    }

    func delete() async throws {
        guard let id = editingId else { return }
        try await deleteTask(id)
    }

    private func parseTags() -> [String] {
        tagsInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
