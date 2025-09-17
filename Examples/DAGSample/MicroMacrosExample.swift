import Foundation
import SwiftHilt

// Demonstrates micro macros usage (requires Swift 5.9 toolchain)

// MARK: - Providers via @Module/@Provides

@Module
struct NetworkModule {
    @Provides(lifetime: .singleton)
    static func httpClient() -> HttpClient { HttpClient() }

    @Provides(lifetime: .singleton, qualifier: Named("prodBase"))
    static func baseURL() -> URL { URL(string: "https://api.example.com/user/")! }
}

@Component(modules: [NetworkModule.self])
struct AppComponent {}

// MARK: - Injectable constructors

@Injectable
final class RemoteDataSource2 {
    let client: HttpClient
    let baseURL: URL
    init(client: HttpClient, baseURL: URL) {
        self.client = client
        self.baseURL = baseURL
    }
}

@Injectable
@Binds(UserRepository.self, lifetime: .scoped)
final class UserRepositoryImpl2: UserRepository {
    let remote: RemoteDataSource2
    init(remote: RemoteDataSource2) { self.remote = remote }
    func getUser(id: String) -> User { remote.getUser(id: id) }
}

// MARK: - Register injectables via property wrapper inside a module

@Module
struct AppBindingsModule {
    @Register(.scoped) static var remoteDataSource: RemoteDataSource2
    @Register(.singleton) static var cacheDataSource: CacheDataSource
    @Register(.transient) static var getUserUseCase: GetUserUseCase
}

// MARK: - EntryPoint for composition roots

@EntryPoint
protocol UseCaseEntryPoint {
    var getUserUseCase: GetUserUseCase { get }
}

// Usage example (commented out to avoid side-effects in sample main):
// let c = AppComponent.build()
// NetworkModule.__register(into: c)
// AppBindingsModule.__register(into: c)
// let ep = c.entryPoint(UseCaseEntryPoint.self)
// let useCase = ep.getUserUseCase

// Usage (commented to avoid duplicate symbol conflicts with main sample):
// let container2 = AppComponent.build()
// container2.register(RemoteDataSource2.self) { r in RemoteDataSource2(resolver: r) }
// UserRepositoryImpl2.__register(into: container2) // or list in @Component modules
// let repo2 = container2.resolve(UserRepository.self)
