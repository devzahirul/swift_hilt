import Foundation

public struct Provider<T> {
    private let resolver: Resolver
    private let qualifier: (any Qualifier)?

    public init(resolver: Resolver, qualifier: (any Qualifier)? = nil) {
        self.resolver = resolver
        self.qualifier = qualifier
    }

    public func callAsFunction() -> T {
        resolver.resolve(T.self, qualifier: qualifier)
    }
}

public final class Lazy<T> {
    private let provider: Provider<T>
    private var storage: T?

    public init(resolver: Resolver, qualifier: (any Qualifier)? = nil) {
        self.provider = Provider<T>(resolver: resolver, qualifier: qualifier)
    }

    public var value: T {
        if let v = storage { return v }
        let v = provider()
        storage = v
        return v
    }
}
