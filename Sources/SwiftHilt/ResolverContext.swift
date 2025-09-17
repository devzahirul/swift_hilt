import Foundation

/// Thread-local resolver context used for non-SwiftUI code paths.
/// You can set a resolver for the duration of a call using `ResolverContext.with(_:)`.
public enum ResolverContext {
    private static let key = "SwiftHilt.CurrentResolver"

    public static var current: Resolver? {
        get { Thread.current.threadDictionary[key] as? Resolver }
        set { Thread.current.threadDictionary[key] = newValue }
    }

    @discardableResult
    public static func with<T>(_ resolver: Resolver, _ body: () throws -> T) rethrows -> T {
        let prev = current
        current = resolver
        defer { current = prev }
        return try body()
    }
}

