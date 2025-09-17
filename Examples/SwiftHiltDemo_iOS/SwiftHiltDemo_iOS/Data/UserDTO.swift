import Foundation

struct UserDTO: Decodable {
    let id: Int
    let name: String
    let email: String

    func toDomain() -> User { User(id: id, name: name, email: email) }
}

