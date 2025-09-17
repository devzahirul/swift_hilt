import XCTest
@testable import SwiftHilt

final class IOSDemoDomainTests: XCTestCase {
    struct User: Equatable { let id: Int; let name: String; let email: String }
    protocol UserRepository { func getUser(id: Int) async throws -> User; func getUsers() async throws -> [User] }
    struct GetUserUseCase { let repo: UserRepository; func callAsFunction(_ id: Int) async throws -> User { try await repo.getUser(id: id) } }
    struct GetUsersUseCase { let repo: UserRepository; func callAsFunction() async throws -> [User] { try await repo.getUsers() } }

    final class InMemoryRepo: UserRepository {
        func getUser(id: Int) async throws -> User { User(id: id, name: "U\(id)", email: "u\(id)@example.com") }
        func getUsers() async throws -> [User] { [1,2].map { User(id: $0, name: "U\($0)", email: "u\($0)@example.com") } }
    }

    func testGetUserUseCase_InMemory() async throws {
        let c = Container()
        c.register(UserRepository.self, lifetime: .singleton) { _ in InMemoryRepo() }
        c.register(GetUserUseCase.self, lifetime: .transient) { r in GetUserUseCase(repo: r.resolve()) }
        let uc: GetUserUseCase = c.resolve()
        let u = try await uc(7)
        XCTAssertEqual(u.name, "U7")
        XCTAssertEqual(u.email, "u7@example.com")
    }

    func testGetUsersUseCase_InMemory() async throws {
        let c = Container()
        c.register(UserRepository.self, lifetime: .singleton) { _ in InMemoryRepo() }
        c.register(GetUsersUseCase.self, lifetime: .transient) { r in GetUsersUseCase(repo: r.resolve()) }
        let uc: GetUsersUseCase = c.resolve()
        let list = try await uc()
        XCTAssertEqual(list.count, 2)
        XCTAssertEqual(list.first?.name, "U1")
    }
}

