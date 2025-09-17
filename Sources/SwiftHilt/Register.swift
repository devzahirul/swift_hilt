import Foundation

/// Property-wrapper used as metadata in a `@Module` to declare that a type should be registered.
/// This wrapper is only consumed by macros; accessing its wrapped value at runtime will trap.
@propertyWrapper
public struct Register<T> {
    public let lifetime: Lifetime
    public let qualifier: (any Qualifier)?

    public init(_ lifetime: Lifetime = .singleton, qualifier: (any Qualifier)? = nil) {
        self.lifetime = lifetime
        self.qualifier = qualifier
    }

    public var wrappedValue: T {
        get { fatalError("@Register is metadata-only and should not be accessed at runtime.") }
        set { /* ignore */ }
    }
}
