import Foundation

/// Caching semantics for a binding in the container.
public enum Lifetime: Sendable {
    /// No caching. Factory runs every time.
    case transient
    /// Cached at the container where the provider is registered. Shared with children.
    case singleton
    /// Cached in the currently resolving container (per-scope).
    case scoped
}
