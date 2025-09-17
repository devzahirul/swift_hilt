import Foundation

/// Inject dependency from an enclosing instance that conforms to `HasResolver`.
/// Usage:
///   final class VM: HasResolver {
///     let resolver: Resolver
///     @Inject var api: Api
///     init(resolver: Resolver) { self.resolver = resolver }
///   }
@propertyWrapper
public struct Inject<T> {
    private let qualifier: Qualifier?
    private var cached: T?

    public init(_ qualifier: Qualifier? = nil) {
        self.qualifier = qualifier
    }

    // Accessed if used without enclosing-instance support
    public var wrappedValue: T {
        get { fatalError("@Inject requires enclosing type to conform to HasResolver.") }
        mutating set { cached = newValue }
    }

    public static subscript<EnclosingSelf: HasResolver>(
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, T>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Inject<T>>
    ) -> T {
        get {
            var wrapper = instance[keyPath: storageKeyPath]
            if let v = wrapper.cached { return v }
            let v: T = instance.resolver.resolve(T.self, qualifier: wrapper.qualifier)
            wrapper.cached = v
            instance[keyPath: storageKeyPath] = wrapper
            return v
        }
        set {
            var wrapper = instance[keyPath: storageKeyPath]
            wrapper.cached = newValue
            instance[keyPath: storageKeyPath] = wrapper
        }
    }
}

