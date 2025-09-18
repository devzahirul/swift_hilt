//
//  DI.swift
//  SwiftHiltDemoiOS
//
//  Created by lynkto_1 on 9/18/25.
//

import Foundation
import SwiftHilt
#if canImport(SwiftData)
import SwiftData
#endif


func loadDependency() {
    install {
        provide(UserDataSource.self, lifetime: .singleton) { _ in
            InMemoryUserDataSource()
        }
    }
    
    register(UserRepository.self, lifetime: .singleton) {r in
        UserRepositoryImp(source: r.resolve())
    }
    
    
    register(UserListViewModel.self, lifetime: .scoped) {r in
        UserListViewModel(userreposiotry: r.resolve())
    }
    
    // Task manager bindings
    install {
        provide(TaskRepository.self, lifetime: .singleton) { _ in
            #if canImport(SwiftData)
            if #available(iOS 17, *) {
                // Allow UI tests to force in-memory repository
                if ProcessInfo.processInfo.environment["UITEST_INMEMORY"] == "1" {
                    return InMemoryTaskRepository() as TaskRepository
                }
                let stack = SwiftDataStack(inMemory: false)
                return SwiftDataTaskRepository(container: stack.container) as TaskRepository
            }
            #endif
            return InMemoryTaskRepository() as TaskRepository
        }
        // Use cases
        provide(CreateTaskUseCase.self) { r in CreateTaskUseCase(repo: r.resolve()) }
        provide(UpdateTaskUseCase.self) { r in UpdateTaskUseCase(repo: r.resolve()) }
        provide(DeleteTaskUseCase.self) { r in DeleteTaskUseCase(repo: r.resolve()) }
        provide(ToggleTaskCompletionUseCase.self) { r in ToggleTaskCompletionUseCase(repo: r.resolve()) }
        provide(QueryTasksUseCase.self) { r in QueryTasksUseCase(repo: r.resolve()) }
        provide(ObserveTasksUseCase.self) { r in ObserveTasksUseCase(repo: r.resolve()) }
    }
    // No explicit registration for TaskListViewModel to avoid MainActor init from nonisolated context.
    
}
