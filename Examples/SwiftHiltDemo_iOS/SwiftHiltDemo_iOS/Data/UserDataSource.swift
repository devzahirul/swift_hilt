import Foundation

protocol UserDataSource {
    func getUser(id: Int) async throws -> User
    func getUsers() async throws -> [User]
}

final class RemoteUserDataSource: UserDataSource {
    private let api: UserAPI
    init(api: UserAPI) { self.api = api }
    func getUser(id: Int) async throws -> User { try await api.fetchUser(id: id).toDomain() }
    func getUsers() async throws -> [User] { try await api.fetchUsers().map { $0.toDomain() } }
}

final class InMemoryUserDataSource: UserDataSource {
    func getUser(id: Int) async throws -> User { User(id: id, name: "InMemory User", email: "mem@example.com") }
    func getUsers() async throws -> [User] {
        [1,2,3].map { User(id: $0, name: "User \($0)", email: "u\($0)@example.com") }
    }
}
