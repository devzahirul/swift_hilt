Task Manager Example (iOS, SwiftUI + SwiftData)
==============================================

This guide documents the iOS demo at `Examples/SwiftHiltDemoiOS/SwiftHiltDemoiOS.xcodeproj`, explaining structure, flows, and design decisions, with usage examples, limitations, and common issues.

Overview
- Clean Architecture layers: Domain → Use Cases → Data (SwiftData/InMemory) → Presentation (SwiftUI)
- DI: SwiftHilt registers TaskRepository + use cases and resolves them in VMs via resolve().
- Tests: Unit + UI with deterministic in-memory option.

Domain
------
- Models
  - `Todo` (entity): id, title, notes, isCompleted, dueDate, priority, project, tags, createdAt, updatedAt
    - File: Examples/SwiftHiltDemoiOS/SwiftHiltDemoiOS/Domain/TaskModels.swift:1
  - `TaskQuery`, `TaskSort`, `TaskPriority`, `NewTask`

- Protocols
  - `TaskRepository`: async CRUD, query, observe
    - File: Examples/SwiftHiltDemoiOS/SwiftHiltDemoiOS/Domain/TaskRepository.swift:1

- Use Cases (stateless)
  - `CreateTaskUseCase`, `UpdateTaskUseCase`, `DeleteTaskUseCase`, `ToggleTaskCompletionUseCase`, `QueryTasksUseCase`, `ObserveTasksUseCase`
    - File: Examples/SwiftHiltDemoiOS/SwiftHiltDemoiOS/UseCases/TaskUseCases.swift:1

Data
----
- InMemoryTaskRepository (reference implementation)
  - Thread-safe via serial queue; supports `observe` via AsyncStream broadcasting snapshots.
  - File: Examples/SwiftHiltDemoiOS/SwiftHiltDemoiOS/Data/InMemoryTaskRepository.swift:1
  - Best use: unit tests, previews, UI tests.
  - Limitation: not persisted across runs.

- SwiftDataTaskRepository (iOS 17+)
  - `@Model SDTask` and `ModelContext(container)` for persistence.
  - Guards via `#if canImport(SwiftData)` and `@available(iOS 17, *)`.
  - File: Examples/SwiftHiltDemoiOS/SwiftHiltDemoiOS/Data/SwiftDataTaskRepository.swift:1
  - Best use: real iOS 17+ devices/simulators.
  - Limitation: SwiftData is iOS 17+; falls back to in-memory on earlier OS.
  - Common error: main actor isolation when using `container.mainContext` – fixed by creating a dedicated `ModelContext(container)`.

DI Wiring
---------
- File: Examples/SwiftHiltDemoiOS/SwiftHiltDemoiOS/DI.swift:1
- Registers:
  - `TaskRepository` – chooses SwiftData or in-memory (UITEST_INMEMORY=1 forces in-memory).
  - Use cases – all provided as transient helpers.
- Entry point: `SwiftHiltDemoiOSApp` calls `loadDependency()`.

Presentation (SwiftUI)
----------------------
- TaskListViewModel (@MainActor)
  - State: tasks, searchText, filter, showCompleted
  - Behavior: start observation, refresh, quick add, toggle, delete, build query by filter.
  - File: Examples/SwiftHiltDemoiOS/SwiftHiltDemoiOS/Presentation/TaskListViewModel.swift:1
  - Limitation: Observe stream uses a simple re-fetch pattern on mutation.

- TaskDetailViewModel (@MainActor)
  - State: form fields (title, notes, dueDate, priority, project, tags)
  - Behavior: create or update; delete if editing.
  - File: Examples/SwiftHiltDemoiOS/SwiftHiltDemoiOS/Presentation/TaskDetailViewModel.swift:1
  - Limitation: No validation beyond non-empty title.

- TaskListView
  - Features: quick add, search, filter (via toolbar Menu), swipe delete, tap to edit.
  - File: Examples/SwiftHiltDemoiOS/SwiftHiltDemoiOS/Presentation/TaskListView.swift:1
  - Accessibility IDs: quickAddField, quickAddButton, createTaskButton, filterMenuButton, dueLabel

- TaskDetailView
  - Features: title, completed toggle, priority segmented, due date toggle+picker, project, tags, notes; Save/Cancel/Delete.
  - File: Examples/SwiftHiltDemoiOS/SwiftHiltDemoiOS/Presentation/TaskDetailView.swift:1

Running
-------
- Open `Examples/SwiftHiltDemoiOS/SwiftHiltDemoiOS.xcodeproj`.
- Select iOS 17+ destination; run scheme `SwiftHiltDemoiOS`.
- For devices, configure Signing and a unique bundle id if needed.

Testing
-------
- Unit Tests – `SwiftHiltDemoiOSTests`
  - InMemoryTaskRepositoryTests: CRUD, toggle, query – `.../InMemoryTaskRepositoryTests.swift:1`
  - TaskListViewModelTests: refresh, search – `.../TaskListViewModelTests.swift:1`
  - TaskDetailViewModelTests: create, edit, delete – `.../TaskDetailViewModelTests.swift:1`
  - SwiftDataTaskRepositoryTests (iOS 17+): CRUD – `.../SwiftDataTaskRepositoryTests.swift:1`
- UI Tests – `SwiftHiltDemoiOSUITests`
  - TaskListUITests: quick add, toggle, filter, delete; create/edit; search; due date+priority; filter Completed/All; Save disabled – `.../TaskListUITests.swift:1`
  - Uses `UITEST_INMEMORY=1` env var to force in-memory repository for predictable state.

Common Errors & Warnings
------------------------
- “missing bundleID for main bundle” – project Info.plist miswired. Fixed by providing `App-Info.plist` and referencing it in build settings.
- “Multiple commands produce ... Info.plist” – occurs if Info.plist is both generated and copied. Fixed by renaming to `App-Info.plist` and disabling `GENERATE_INFOPLIST_FILE`.
- “Cannot specialize non-generic type 'Task'” – name collision with Swift concurrency `Task`. Resolved by renaming domain model to `Todo`.
- “Main actor-isolated property 'mainContext' ...” – using SwiftData `mainContext` off main actor; fix by creating `ModelContext(container)`.

Extending the Example
---------------------
- Projects and tags management (entities + filters UI)
- Recurring tasks, notifications (UserNotifications)
- Import/export JSON; cloud sync
- Snapshot tests and accessibility audit

