import Foundation
import SwiftHilt

// Toggle between in-memory and network backed implementations
private let USE_IN_MEMORY = false

func configureDI() {
    // Base URL for a simple public API (JSONPlaceholder)
    install {
        provide(URL.self, qualifier: Named("base"), lifetime: .singleton) { _ in
            URL(string: "https://jsonplaceholder.typicode.com/")!
        }
        provide(URLSession.self, lifetime: .singleton) { _ in URLSession.shared }
        provide(UserAPI.self, lifetime: .singleton) { r in
            UserAPI(session: r.resolve(URLSession.self), baseURL: r.resolve(URL.self, qualifier: Named("base")))
        }
    }

    // Data sources
    if USE_IN_MEMORY {
        register(UserDataSource.self, lifetime: .singleton) { _ in InMemoryUserDataSource() }
    } else {
        register(UserDataSource.self, lifetime: .singleton) { r in RemoteUserDataSource(api: r.resolve(UserAPI.self)) }
    }

    // Repository
    register(UserRepository.self, lifetime: .scoped) { r in
        UserRepositoryImpl(source: r.resolve(UserDataSource.self))
    }

    // Use cases
    register(GetUserUseCase.self, lifetime: .transient) { r in
        GetUserUseCase(repo: r.resolve(UserRepository.self))
    }
}

