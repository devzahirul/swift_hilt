import Foundation

/// A registration operation that applies to a container.
public struct Registration {
    let apply: (Container) -> Void
}

@resultBuilder
public enum ModuleBuilder {
    public static func buildBlock(_ components: Registration...) -> [Registration] {
        components
    }
}

/// Declare a single binding for `T` inside a module builder.
public func provide<T>(
    _ type: T.Type = T.self,
    qualifier: (any Qualifier)? = nil,
    lifetime: Lifetime = .singleton,
    _ factory: @escaping (Resolver) -> T
) -> Registration {
    Registration { c in c.register(type, qualifier: qualifier, lifetime: lifetime, factory: factory) }
}

/// Contribute a multibinding for `T` inside a module builder (resolved via `resolveMany`).
public func contribute<T>(
    _ type: T.Type = T.self,
    qualifier: (any Qualifier)? = nil,
    _ factory: @escaping (Resolver) -> T
) -> Registration {
    Registration { c in c.registerMany(type, qualifier: qualifier, factory) }
}

public extension Container {
    /// Apply a list of registrations into this container.
    func install(@ModuleBuilder _ builder: () -> [Registration]) {
        let regs = builder()
        regs.forEach { $0.apply(self) }
    }
}
