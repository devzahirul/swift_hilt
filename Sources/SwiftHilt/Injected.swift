import Foundation

/// Injects a dependency from the current resolver context.
/// The current context is established via `ResolverContext.with(_:)` or by frameworks (SwiftUI Environment).
@propertyWrapper
public struct Injected<T> {
    private let qualifier: (any Qualifier)?
    private var value: T?

    public init(_ qualifier: (any Qualifier)? = nil) {
        self.qualifier = qualifier
    }

    public var wrappedValue: T {
        mutating get {
            if let v = value { return v }
            guard let resolver = ResolverContext.current else {
                fatalError("No resolver in context. Provide a container via ResolverContext.with(_:) or SwiftUI .diContainer(_:) environment.")
            }
            let v: T = resolver.resolve(T.self, qualifier: qualifier)
            value = v
            return v
        }
        mutating set { value = newValue }
    }
}
