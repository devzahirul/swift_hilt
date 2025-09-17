import Foundation

public protocol Qualifier: Hashable {}

public struct Named: Qualifier, ExpressibleByStringLiteral, CustomStringConvertible {
    public let value: String
    public init(_ value: String) { self.value = value }
    public init(stringLiteral value: StringLiteralType) { self.value = value }
    public var description: String { "@Named(\(value))" }
}
