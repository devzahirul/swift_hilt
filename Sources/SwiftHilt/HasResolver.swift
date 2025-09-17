import Foundation

/// Types that expose a resolver, enabling `@Inject` property wrapper without macros.
public protocol HasResolver {
    var resolver: Resolver { get }
}

