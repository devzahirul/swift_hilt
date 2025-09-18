import SwiftUI
import SwiftHilt

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: TaskDetailViewModel

    init(task: Todo? = nil) {
        _vm = StateObject(wrappedValue: TaskDetailViewModel(task: task))
    }

    var body: some View {
        Form {
            Section("Basics") {
                TextField("Title", text: $vm.title)
                    .accessibilityIdentifier("titleField")
                    .textInputAutocapitalization(.sentences)
                Toggle("Completed", isOn: $vm.isCompleted)
                Picker("Priority", selection: $vm.priority) {
                    Text("Low").tag(TaskPriority.low)
                    Text("Medium").tag(TaskPriority.normal)
                    Text("High").tag(TaskPriority.high)
                    Text("Urgent").tag(TaskPriority.urgent)
                }.pickerStyle(.segmented)
            }

            Section("Schedule") {
                Toggle("Has Due Date", isOn: $vm.hasDueDate.animation())
                    .accessibilityIdentifier("hasDueDateToggle")
                if vm.hasDueDate {
                    DatePicker("Due", selection: $vm.dueDate, displayedComponents: [.date, .hourAndMinute])
                }
            }

            Section("Details") {
                TextField("Project", text: $vm.project)
                TextField("Tags (comma separated)", text: $vm.tagsInput)
                TextEditor(text: $vm.notes)
                    .frame(minHeight: 120)
            }
        }
        .navigationTitle(vmTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { Task { try? await vm.save(); dismiss() } }
                    .accessibilityIdentifier("saveButton")
                    .disabled(!vm.canSave)
            }
            if vm.editingId != nil {
                ToolbarItem(placement: .bottomBar) {
                    Button(role: .destructive) { Task { try? await vm.delete(); dismiss() } } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    private var vmTitle: String { vm.editingId == nil ? "New Task" : "Edit Task" }
}

#Preview {
    NavigationStack { TaskDetailView() }
}
