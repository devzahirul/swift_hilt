import SwiftUI
import SwiftHilt

struct TaskListView: View {
    @StateObject var vm = TaskListViewModel()
    @State private var quickTitle: String = ""
    @State private var isPresentingCreate: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Quick Add")) {
                    HStack {
                        TextField("New task title", text: $quickTitle)
                            .textInputAutocapitalization(.sentences)
                            .accessibilityIdentifier("quickAddField")
                        Button(action: addQuick) {
                            Image(systemName: "plus.circle.fill").foregroundStyle(.tint)
                        }
                        .accessibilityIdentifier("quickAddButton")
                        .disabled(quickTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Section(header: Text(sectionTitle)) {
                    if vm.tasks.isEmpty {
                        ContentUnavailableView("No tasks", systemImage: "checkmark.circle")
                    } else {
                        ForEach(vm.tasks) { task in
                            NavigationLink(destination: TaskDetailView(task: task)) {
                                TaskRow(task: task, toggle: { await vm.toggle(task.id) })
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) { Task { await vm.delete(task.id) } } label: { Label("Delete", systemImage: "trash") }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Picker("Filter", selection: $vm.filter) {
                        ForEach(TaskListViewModel.Filter.allCases) { f in
                            Text(f.rawValue.capitalized).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 280)
                    .onChange(of: vm.filter) { _, new in vm.onFilterChanged(new) }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { isPresentingCreate = true } label: { Image(systemName: "plus") }
                        .accessibilityIdentifier("createTaskButton")
                }
            }
            // Destination provided inline per row
        }
        .searchable(text: $vm.searchText, placement: .navigationBarDrawer(displayMode: .always))
        .onChange(of: vm.searchText) { _, new in vm.onSearchChanged(new) }
        .task { vm.start() }
        .sheet(isPresented: $isPresentingCreate) {
            NavigationStack { TaskDetailView() }
        }
    }

    private var sectionTitle: String {
        switch vm.filter {
        case .today: return "Today"
        case .upcoming: return "Upcoming"
        case .all: return "All"
        case .completed: return "Completed"
        }
    }

    private func addQuick() {
        let title = quickTitle
        quickTitle = ""
        Task { await vm.addQuickTask(title: title) }
    }
}

private struct TaskRow: View {
    let task: Todo
    let toggle: () async -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: { Task { await toggle() } }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
            .accessibilityLabel("toggle")
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                if let due = task.dueDate {
                    Label(due.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("dueLabel")
                }
            }
            Spacer()
            Text(badge)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(capsuleColor.opacity(0.15), in: Capsule())
                .foregroundStyle(capsuleColor)
        }
        .contentShape(Rectangle())
    }

    private var badge: String {
        switch task.priority {
        case .low: return "LOW"
        case .normal: return "MED"
        case .high: return "HIGH"
        case .urgent: return "URGENT"
        }
    }

    private var capsuleColor: Color {
        switch task.priority {
        case .low: return .blue
        case .normal: return .gray
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

#Preview {
    TaskListView()
}
