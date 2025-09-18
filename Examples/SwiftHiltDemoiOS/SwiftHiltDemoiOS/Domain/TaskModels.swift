import Foundation

public enum TaskPriority: Int, Codable, CaseIterable, Sendable {
    case low = 0
    case normal = 1
    case high = 2
    case urgent = 3
}

public struct Todo: Identifiable, Equatable, Sendable, Codable {
    public let id: UUID
    public var title: String
    public var notes: String?
    public var isCompleted: Bool
    public var dueDate: Date?
    public var priority: TaskPriority
    public var project: String?
    public var tags: [String]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        priority: TaskPriority = .normal,
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
        self.priority = priority
        self.project = project
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct NewTask: Sendable, Codable {
    public var title: String
    public var notes: String?
    public var dueDate: Date?
    public var priority: TaskPriority
    public var project: String?
    public var tags: [String]

    public init(
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        priority: TaskPriority = .normal,
        project: String? = nil,
        tags: [String] = []
    ) {
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.priority = priority
        self.project = project
        self.tags = tags
    }
}

public enum TaskSort: Sendable, Codable {
    case byDueDateAsc
    case byDueDateDesc
    case byPriorityDesc
    case byCreatedAtDesc
}

public struct TaskQuery: Sendable, Codable, Equatable {
    public var search: String?
    public var includeCompleted: Bool
    public var project: String?
    public var tags: [String]?
    public var dueAfter: Date?
    public var dueBefore: Date?
    public var sort: TaskSort

    public init(
        search: String? = nil,
        includeCompleted: Bool = false,
        project: String? = nil,
        tags: [String]? = nil,
        dueAfter: Date? = nil,
        dueBefore: Date? = nil,
        sort: TaskSort = .byDueDateAsc
    ) {
        self.search = search
        self.includeCompleted = includeCompleted
        self.project = project
        self.tags = tags
        self.dueAfter = dueAfter
        self.dueBefore = dueBefore
        self.sort = sort
    }
}
