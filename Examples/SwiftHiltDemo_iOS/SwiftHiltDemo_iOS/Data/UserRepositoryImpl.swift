import Foundation

final class UserRepositoryImpl: UserRepository {
    private let source: UserDataSource
    init(source: UserDataSource) { self.source = source }
    func getUser(id: Int) async throws -> User { try await source.getUser(id: id) }
    func getUsers() async throws -> [User] { try await source.getUsers() }
}
