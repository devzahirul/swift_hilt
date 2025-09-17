import Foundation

public struct User: Identifiable, Equatable, Codable {
    public let id: Int
    public let name: String
    public let email: String
}

