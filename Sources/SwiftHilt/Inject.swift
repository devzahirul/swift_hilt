import Foundation

/// Inject dependency from the current environment or enclosing instance's resolver.
/// Resolution order:
/// 1) If the enclosing instance conforms to `HasResolver`, use its resolver
/// 2) If a task-local resolver is set via `Injection.with(...)`, use that
/// 3) If a thread-local resolver is set via `ResolverContext.with(...)`, use that
/// 4) If a global default is set via `Injection.globalDefault`, use that
/// Otherwise: fatalError with guidance.
@propertyWrapper
public struct Inject<T> {
    private let qualifier: (any Qualifier)?
    private var cached: T?

    public init(_ qualifier: (any Qualifier)? = nil) {
        self.qualifier = qualifier
    }

    // Convenience initializer to allow syntax: @Inject(T.self)
    public init(_ type: T.Type) { self.qualifier = nil }
    public init(_ type: T.Type, qualifier: (any Qualifier)?) { self.qualifier = qualifier }

    // Accessed if used without enclosing-instance support
    public var wrappedValue: T {
        get { fatalError("@Inject requires enclosing type to conform to HasResolver.") }
        mutating set { cached = newValue }
    }

    public static subscript<EnclosingSelf: AnyObject>(
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, T>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Inject<T>>
    ) -> T {
        get {
            var wrapper = instance[keyPath: storageKeyPath]
            if let v = wrapper.cached { return v }
            // 1) HasResolver on enclosing instance
            if let has = instance as? HasResolver {
                let v: T = has.resolver.resolve(T.self, qualifier: wrapper.qualifier)
                wrapper.cached = v
                instance[keyPath: storageKeyPath] = wrapper
                return v
            }
            // 2) TaskLocal / 3) ThreadLocal / 4) Global default
            if let env = Injection.current {
                let v: T = env.resolve(T.self, qualifier: wrapper.qualifier)
                wrapper.cached = v
                instance[keyPath: storageKeyPath] = wrapper
                return v
            }
            fatalError("@Inject could not find a resolver. Use Injection.with(container) { ... }, ResolverContext.with(container) { ... }, set Injection.globalDefault, or make the enclosing type conform to HasResolver.")
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
