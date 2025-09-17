import Foundation

public protocol Resolver: AnyObject {
    func resolve<T>(_ type: T.Type, qualifier: Qualifier?) -> T
    func optional<T>(_ type: T.Type, qualifier: Qualifier?) -> T?
    func resolveMany<T>(_ type: T.Type, qualifier: Qualifier?) -> [T]
}

final class ProviderEntry {
    let lifetime: Lifetime
    let factory: (Resolver) -> Any

    init(lifetime: Lifetime, factory: @escaping (Resolver) -> Any) {
        self.lifetime = lifetime
        self.factory = factory
    }
}

public final class Container: Resolver {
    public private(set) weak var parent: Container?

    private var providers: [ServiceKey: ProviderEntry] = [:]
    private var cache: [ServiceKey: Any] = [:]
    private var manyProviders: [ServiceKey: [ManyEntry]] = [:]

    private let lock = NSRecursiveLock()

    public init(parent: Container? = nil) {
        self.parent = parent
    }

    public func child() -> Container {
        Container(parent: self)
    }

    public func clearCache() {
        lock.lock(); defer { lock.unlock() }
        cache.removeAll()
    }

    // MARK: Registration

    @discardableResult
    public func register<T>(
        _ type: T.Type = T.self,
        qualifier: Qualifier? = nil,
        lifetime: Lifetime = .singleton,
        factory: @escaping (Resolver) -> T
    ) -> Self {
        let key = ServiceKey(type, qualifier: qualifier)
        lock.lock(); defer { lock.unlock() }
        providers[key] = ProviderEntry(lifetime: lifetime, factory: { r in factory(r) })
        // clear any stale cache entries for this key in this container
        cache.removeValue(forKey: key)
        return self
    }

    @discardableResult
    public func registerMany<T>(
        _ type: T.Type = T.self,
        qualifier: Qualifier? = nil,
        _ factory: @escaping (Resolver) -> T
    ) -> Self {
        let key = ServiceKey(type, qualifier: qualifier)
        lock.lock(); defer { lock.unlock() }
        var list = manyProviders[key] ?? []
        list.append(ManyEntry(factory: { r in factory(r) }))
        manyProviders[key] = list
        return self
    }

    // MARK: Resolve

    public func resolve<T>(_ type: T.Type = T.self, qualifier: Qualifier? = nil) -> T {
        let key = ServiceKey(type, qualifier: qualifier)
        do {
            let any = try _resolve(key: key)
            guard let typed = any as? T else {
                #if DEBUG
                fatalError("Resolved instance type mismatch for \(key)")
                #else
                return any as! T // will crash similarly in release
                #endif
            }
            return typed
        } catch {
            #if DEBUG
            fatalError(String(describing: error))
            #else
            preconditionFailure(String(describing: error))
            #endif
        }
    }

    public func optional<T>(_ type: T.Type = T.self, qualifier: Qualifier? = nil) -> T? {
        let key = ServiceKey(type, qualifier: qualifier)
        do {
            let any = try _resolve(key: key, throwIfMissing: false)
            return any as? T
        } catch {
            return nil
        }
    }

    public func resolveMany<T>(_ type: T.Type = T.self, qualifier: Qualifier? = nil) -> [T] {
        let key = ServiceKey(type, qualifier: qualifier)
        var chain: [Container] = []
        var cursor: Container? = self
        while let c = cursor { chain.append(c); cursor = c.parent }
        var result: [T] = []
        for c in chain.reversed() { // parent-first
            c.lock.lock()
            let list = c.manyProviders[key] ?? []
            c.lock.unlock()
            for entry in list {
                if let val = entry.factory(self) as? T { result.append(val) }
            }
        }
        return result
    }

    private func _resolve(key: ServiceKey, throwIfMissing: Bool = true) throws -> Any {
        try ResolutionTrace.withPushed(key) {
            // Fast path: local cache
            lock.lock()
            if let cached = cache[key] {
                lock.unlock()
                return cached
            }
            // Find provider in chain (self -> parent ...)
            var owner: Container? = self
            var entry: ProviderEntry?
            var containerWithProvider: Container?
            while let c = owner {
                if let p = c.providers[key] {
                    entry = p
                    containerWithProvider = c
                    break
                }
                owner = c.parent
            }
            // Missing
            if entry == nil {
                lock.unlock()
                if throwIfMissing { throw ResolutionError.notFound(key: key) }
                return Optional<Any>.none as Any
            }
            // If provider is in this container and cached here (singleton), return it
            if let c = containerWithProvider, c === self, let cached = cache[key] {
                lock.unlock()
                return cached
            }
            // Create instance (hold lock to ensure singletons are unique and factories are reentrant via recursive lock)
            let provider = entry!
            let instance = provider.factory(self)

            switch provider.lifetime {
            case .transient:
                lock.unlock()
                return instance
            case .singleton:
                // cache in container that owns the provider
                if let owner = containerWithProvider {
                    owner.lock.lock(); owner.cache[key] = instance; owner.lock.unlock()
                } else {
                    cache[key] = instance
                }
                lock.unlock()
                return instance
            case .scoped:
                // cache in current (resolving) container (scope)
                cache[key] = instance
                lock.unlock()
                return instance
            }
        }
    }
}

// No global container singleton. Supply a resolver via ResolverContext.with(_) or SwiftUI environment.
