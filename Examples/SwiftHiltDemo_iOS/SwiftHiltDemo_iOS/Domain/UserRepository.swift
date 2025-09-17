import Foundation

public protocol UserRepository {
    func getUser(id: Int) async throws -> User
}

