import Foundation

protocol UserDataSource {
    func getUser(id: Int) async throws -> User
}

final class RemoteUserDataSource: UserDataSource {
    private let api: UserAPI
    init(api: UserAPI) { self.api = api }
    func getUser(id: Int) async throws -> User { try await api.fetchUser(id: id).toDomain() }
}

final class InMemoryUserDataSource: UserDataSource {
    func getUser(id: Int) async throws -> User { User(id: id, name: "InMemory User", email: "mem@example.com") }
}

