import Foundation

public struct Registration {
    let apply: (Container) -> Void
}

@resultBuilder
public enum ModuleBuilder {
    public static func buildBlock(_ components: Registration...) -> [Registration] {
        components
    }
}

public func provide<T>(
    _ type: T.Type = T.self,
    qualifier: Qualifier? = nil,
    lifetime: Lifetime = .singleton,
    _ factory: @escaping (Resolver) -> T
) -> Registration {
    Registration { c in c.register(type, qualifier: qualifier, lifetime: lifetime, factory: factory) }
}

public func contribute<T>(
    _ type: T.Type = T.self,
    qualifier: Qualifier? = nil,
    _ factory: @escaping (Resolver) -> T
) -> Registration {
    Registration { c in c.registerMany(type, qualifier: qualifier, factory) }
}

public extension Container {
    func install(@ModuleBuilder _ builder: () -> [Registration]) {
        let regs = builder()
        regs.forEach { $0.apply(self) }
    }
}

