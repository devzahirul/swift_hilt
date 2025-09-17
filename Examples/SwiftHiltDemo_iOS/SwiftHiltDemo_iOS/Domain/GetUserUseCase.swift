import Foundation

public struct GetUserUseCase {
    private let repo: UserRepository
    public init(repo: UserRepository) { self.repo = repo }
    public func callAsFunction(_ id: Int) async throws -> User {
        try await repo.getUser(id: id)
    }
}

