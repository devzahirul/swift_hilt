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


public func resolve<T>(_ type: T.Type = T.self, qualifier: (any Qualifier)? = nil) -> T {
    SwiftHiltRuntime.currentResolver.resolve(type, qualifier: qualifier)
}

public func optional<T>(_ type: T.Type = T.self, qualifier: (any Qualifier)? = nil) -> T? {
    SwiftHiltRuntime.currentResolver.optional(type, qualifier: qualifier)
}

public func resolveMany<T>(_ type: T.Type = T.self, qualifier: (any Qualifier)? = nil) -> [T] {
    SwiftHiltRuntime.currentResolver.resolveMany(type, qualifier: qualifier)
}

// MARK: - Global registration shortcuts (default container)

public func install(@ModuleBuilder _ builder: () -> [Registration]) {
    SwiftHiltRuntime.defaultContainer.install(builder)
}

@discardableResult
public func register<T>(
    _ type: T.Type = T.self,
    qualifier: (any Qualifier)? = nil,
    lifetime: Lifetime = .singleton,
    _ factory: @escaping (Resolver) -> T
) -> Container {
    SwiftHiltRuntime.defaultContainer.register(type, qualifier: qualifier, lifetime: lifetime, factory: factory)
}

@discardableResult
public func registerMany<T>(
    _ type: T.Type = T.self,
    qualifier: (any Qualifier)? = nil,
    _ factory: @escaping (Resolver) -> T
) -> Container {
    SwiftHiltRuntime.defaultContainer.registerMany(type, qualifier: qualifier, factory)
}

// MARK: - Global utilities (default container)

public func useContainer(_ container: Container) { SwiftHiltRuntime.useContainer(container) }

public func prewarmSingletons() { SwiftHiltRuntime.defaultContainer.prewarmSingletons() }

public func startRecording() { SwiftHiltRuntime.defaultContainer.startRecording() }

@discardableResult
public func exportDOT() -> String? { SwiftHiltRuntime.defaultContainer.exportDOT() }

