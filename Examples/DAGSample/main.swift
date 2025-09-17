import Foundation
import SwiftHilt

// MARK: - Domain

struct User: CustomStringConvertible { let id: String; let name: String; var description: String { "User(id:\(id), name:\(name))" } }

protocol UserRepository {
    func getUser(id: String) -> User
}

struct GetUserUseCase {
    private let repo: UserRepository
    init(repo: UserRepository) { self.repo = repo }
    func callAsFunction(_ id: String) -> User { repo.getUser(id: id) }
}

// MARK: - Data

final class HttpClient {
    func get(_ url: URL) -> [String: Any] { ["id": url.lastPathComponent, "name": "Alice"] }
}

final class RemoteDataSource {
    private let client: HttpClient
    private let baseURL: URL
    init(client: HttpClient, baseURL: URL) { self.client = client; self.baseURL = baseURL }
    func getUser(id: String) -> User { let json = client.get(baseURL.appendingPathComponent(id)); return User(id: json["id"] as! String, name: json["name"] as! String) }
}

final class CacheDataSource {
    private var store: [String: User] = [:]
    func save(_ user: User) { store[user.id] = user }
    func get(id: String) -> User? { store[id] }
}

final class UserRepositoryImpl: UserRepository {
    private let remote: RemoteDataSource
    private let cache: CacheDataSource
    init(remote: RemoteDataSource, cache: CacheDataSource) { self.remote = remote; self.cache = cache }
    func getUser(id: String) -> User {
        if let u = cache.get(id: id) { return u }
        let u = remote.getUser(id: id)
        cache.save(u)
        return u
    }
}

// MARK: - Composition via global helpers

install {
    provide(URL.self, qualifier: Named("prodBase"), lifetime: .singleton) { _ in URL(string: "https://api.example.com/user/")! }
    provide(HttpClient.self, lifetime: .singleton) { _ in HttpClient() }
}

register(RemoteDataSource.self, lifetime: .scoped) { r in
    RemoteDataSource(client: r.resolve(HttpClient.self), baseURL: r.resolve(URL.self, qualifier: Named("prodBase")))
}
register(CacheDataSource.self, lifetime: .singleton) { _ in CacheDataSource() }
register(UserRepository.self, lifetime: .scoped) { r in
    UserRepositoryImpl(remote: r.resolve(RemoteDataSource.self), cache: r.resolve(CacheDataSource.self))
}
register(GetUserUseCase.self, lifetime: .transient) { r in GetUserUseCase(repo: r.resolve(UserRepository.self)) }

// MARK: - Run with DAG recording

startRecording()

// Execute a path
let useCase: GetUserUseCase = resolve()
let user = useCase("123")
print("Resolved:", user)

// Export Graphviz DOT of the observed dependency graph
if let dot = exportDOT() {
    print("\n--- DOT ---\n\(dot)")
} else {
    print("\nNo DOT available (recording not started or empty graph)")
}
