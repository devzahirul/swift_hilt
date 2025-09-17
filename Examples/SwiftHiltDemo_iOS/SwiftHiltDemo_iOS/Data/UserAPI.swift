import Foundation

struct UserAPI {
    let session: URLSession
    let baseURL: URL

    init(session: URLSession = .shared, baseURL: URL) {
        self.session = session
        self.baseURL = baseURL
    }

    func fetchUser(id: Int) async throws -> UserDTO {
        let url = baseURL.appendingPathComponent("users/\(id)")
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(UserDTO.self, from: data)
    }

    func fetchUsers() async throws -> [UserDTO] {
        let url = baseURL.appendingPathComponent("users")
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([UserDTO].self, from: data)
    }
}
