import Foundation

#if canImport(SwiftUI)
import SwiftUI

private final class UnconfiguredResolver: Resolver {
    func resolve<T>(_ type: T.Type, qualifier: (any Qualifier)?) -> T {
        fatalError("No DI container provided in SwiftUI environment. Use .diContainer(_:) at the root view.")
    }
    func optional<T>(_ type: T.Type, qualifier: (any Qualifier)?) -> T? { nil }
    func resolveMany<T>(_ type: T.Type, qualifier: (any Qualifier)?) -> [T] { [] }
}

/// Environment key that stores a Resolver for SwiftUI views.
public struct DIResolverKey: EnvironmentKey {
    public static let defaultValue: Resolver = UnconfiguredResolver()
}

public extension EnvironmentValues {
    /// The Resolver available to SwiftUI views via `.diContainer(_:)`.
    var diResolver: Resolver {
        get { self[DIResolverKey.self] }
        set { self[DIResolverKey.self] = newValue }
    }
}

public extension View {
    /// Injects the given container as the resolver into the SwiftUI environment.
    func diContainer(_ container: Container) -> some View {
        environment(\.diResolver, container)
    }
}

/// Resolves `T` from the SwiftUI `diResolver` environment.
@propertyWrapper
public struct EnvironmentInjected<T>: DynamicProperty {
    @Environment(\.diResolver) private var resolver: Resolver
    private let qualifier: (any Qualifier)?

    public init(_ qualifier: (any Qualifier)? = nil) { self.qualifier = qualifier }

    public var wrappedValue: T {
        resolver.resolve(T.self, qualifier: qualifier)
    }
}

#endif
