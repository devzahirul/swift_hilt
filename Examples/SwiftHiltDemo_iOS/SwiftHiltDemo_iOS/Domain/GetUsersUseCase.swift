import Foundation

public struct GetUsersUseCase {
    private let repo: UserRepository
    public init(repo: UserRepository) { self.repo = repo }
    public func callAsFunction() async throws -> [User] {
        try await repo.getUsers()
    }
}

