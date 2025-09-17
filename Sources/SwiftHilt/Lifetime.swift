import Foundation

public enum Lifetime: Sendable {
    case transient
    case singleton
    case scoped
}

