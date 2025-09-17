import Foundation

public protocol UserRepository {
    func getUser(id: Int) async throws -> User
    func getUsers() async throws -> [User]
}
