import Foundation
import SwiftHilt

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

    // Data sources (Debug: InMemory, Release: Network)
    #if DEBUG
        register(UserDataSource.self, lifetime: .singleton) { _ in InMemoryUserDataSource() }
    #else
        register(UserDataSource.self, lifetime: .singleton) { _ in InMemoryUserDataSource() }
        // To use network in AdHoc/Release, swap the above for Remote:
        // register(UserDataSource.self, lifetime: .singleton) { r in RemoteUserDataSource(api: r.resolve(UserAPI.self)) }
    #endif

    // Repository
    register(UserRepository.self, lifetime: .scoped) { r in
        UserRepositoryImpl(source: r.resolve(UserDataSource.self))
    }

    // Use cases
    register(GetUserUseCase.self, lifetime: .transient) { r in
        GetUserUseCase(repo: r.resolve(UserRepository.self))
    }
    register(GetUsersUseCase.self, lifetime: .transient) { r in
        GetUsersUseCase(repo: r.resolve(UserRepository.self))
    }
}
