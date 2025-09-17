import Foundation

#if compiler(>=5.7)
import _Concurrency
#endif

/// Task- and thread-local resolver environment used by `@Inject` and friends.
public enum Injection {
    #if compiler(>=5.7)
    @TaskLocal public static var currentTaskResolver: Resolver?
    #endif

    /// Optional global default resolver. Avoid in production; useful in scripts/tools.
    public static var globalDefault: Resolver?

    /// Returns the current resolver in priority order (task → thread → global).
    public static var current: Resolver? {
        #if compiler(>=5.7)
        if let t = currentTaskResolver { return t }
        #endif
        if let r = ResolverContext.current { return r }
        if let g = globalDefault { return g }
        return nil
    }

    /// Run a closure with the given resolver set as task-local (if available) falling back to thread-local.
    @discardableResult
    public static func with<T>(_ resolver: Resolver, _ body: () throws -> T) rethrows -> T {
        #if compiler(>=5.7)
        return try currentTaskResolver.withValue(resolver) {
            try ResolverContext.with(resolver, body)
        }
        #else
        return try ResolverContext.with(resolver, body)
        #endif
    }
}

