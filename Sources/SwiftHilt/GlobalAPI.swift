import Foundation

/// Lightweight global facade for ergonomic usage.
///
/// - Resolution functions (`resolve`, `optional`, `resolveMany`) use the current resolver environment if set
///   (see `Injection.with` or `ResolverContext.with`), otherwise fall back to an internal default container.
/// - Registration helpers (`install`, `register`, `registerMany`) operate on the internal default container.
///   You can replace it with `useContainer(_:)` to point to your app's composition root.
public enum SwiftHiltRuntime {
    private static var _defaultContainer: Container = Container()

    public static var defaultContainer: Container { _defaultContainer }

    public static func useContainer(_ container: Container) {
        _defaultContainer = container
    }

    static var currentResolver: Resolver { Injection.current ?? _defaultContainer }
}

// MARK: - Global resolution shortcuts


/// Resolve `T` using the current resolver environment (Task/thread/global) or the default container.
public func resolve<T>(_ type: T.Type = T.self, qualifier: (any Qualifier)? = nil) -> T {
    SwiftHiltRuntime.currentResolver.resolve(type, qualifier: qualifier)
}

/// Optionally resolve `T`; returns nil if missing.
public func optional<T>(_ type: T.Type = T.self, qualifier: (any Qualifier)? = nil) -> T? {
    SwiftHiltRuntime.currentResolver.optional(type, qualifier: qualifier)
}

/// Resolve all contributions of `T` as an array.
public func resolveMany<T>(_ type: T.Type = T.self, qualifier: (any Qualifier)? = nil) -> [T] {
    SwiftHiltRuntime.currentResolver.resolveMany(type, qualifier: qualifier)
}

// MARK: - Global registration shortcuts (default container)

/// Install a module (list of registrations) into the default container.
public func install(@ModuleBuilder _ builder: () -> [Registration]) {
    SwiftHiltRuntime.defaultContainer.install(builder)
}

@discardableResult
/// Register a provider in the default container.
public func register<T>(
    _ type: T.Type = T.self,
    qualifier: (any Qualifier)? = nil,
    lifetime: Lifetime = .singleton,
    _ factory: @escaping (Resolver) -> T
) -> Container {
    SwiftHiltRuntime.defaultContainer.register(type, qualifier: qualifier, lifetime: lifetime, factory: factory)
}

@discardableResult
/// Contribute a multibinding in the default container.
public func registerMany<T>(
    _ type: T.Type = T.self,
    qualifier: (any Qualifier)? = nil,
    _ factory: @escaping (Resolver) -> T
) -> Container {
    SwiftHiltRuntime.defaultContainer.registerMany(type, qualifier: qualifier, factory)
}

// MARK: - Global utilities (default container)

/// Replace the global default container used by the facade.
public func useContainer(_ container: Container) { SwiftHiltRuntime.useContainer(container) }

/// Eagerly instantiate singletons in the default container.
public func prewarmSingletons() { SwiftHiltRuntime.defaultContainer.prewarmSingletons() }

/// Begin recording dependency edges in the default container.
public func startRecording() { SwiftHiltRuntime.defaultContainer.startRecording() }

@discardableResult
/// Export the recorded graph in DOT from the default container.
public func exportDOT() -> String? { SwiftHiltRuntime.defaultContainer.exportDOT() }
