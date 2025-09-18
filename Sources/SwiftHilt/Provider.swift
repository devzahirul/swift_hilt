import Foundation

/// Provider defers resolution of `T` until call-time; resolves anew on each call.
public struct Provider<T> {
    private let resolver: Resolver
    private let qualifier: (any Qualifier)?

    public init(resolver: Resolver, qualifier: (any Qualifier)? = nil) {
        self.resolver = resolver
        self.qualifier = qualifier
    }

    /// Resolves and returns a fresh instance each time.
    public func callAsFunction() -> T {
        resolver.resolve(T.self, qualifier: qualifier)
    }
}

/// Lazy resolves `T` on first access and caches it for subsequent reads.
public final class Lazy<T> {
    private let provider: Provider<T>
    private var storage: T?

    public init(resolver: Resolver, qualifier: (any Qualifier)? = nil) {
        self.provider = Provider<T>(resolver: resolver, qualifier: qualifier)
    }

    /// The lazily resolved value.
    public var value: T {
        if let v = storage { return v }
        let v = provider()
        storage = v
        return v
    }
}
