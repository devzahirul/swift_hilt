import Foundation

/// Marker protocol for qualifiers used to disambiguate multiple bindings for the same type.
public protocol Qualifier: Hashable {}

/// Simple string-based qualifier. Use like `Named("prod")` or string literal "prod".
public struct Named: Qualifier, ExpressibleByStringLiteral, CustomStringConvertible {
    public let value: String
    public init(_ value: String) { self.value = value }
    public init(stringLiteral value: StringLiteralType) { self.value = value }
    public var description: String { "@Named(\(value))" }
}
