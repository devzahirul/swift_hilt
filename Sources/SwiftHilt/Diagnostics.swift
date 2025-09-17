import Foundation

enum ResolutionError: Error, CustomStringConvertible {
    case notFound(key: ServiceKey)
    case cyclicDependency(path: [ServiceKey])

    var description: String {
        switch self {
        case .notFound(let key):
            return "No provider found for \(key)"
        case .cyclicDependency(let path):
            let chain = path.map { $0.description }.joined(separator: " -> ")
            return "Cyclic dependency detected: \(chain)"
        }
    }
}

final class ResolutionTrace {
    private static let key = "SwiftHilt.TraceKey"

    static func withPushed<T>(_ key: ServiceKey, _ body: () throws -> T) rethrows -> T {
        var stack = current
        if let idx = stack.firstIndex(of: key) {
            let cycle = Array(stack[idx...]) + [key]
            #if DEBUG
            fatalError(ResolutionError.cyclicDependency(path: cycle).description)
            #else
            throw ResolutionError.cyclicDependency(path: cycle)
            #endif
        }
        stack.append(key)
        set(stack)
        defer { var s = current; _ = s.popLast(); set(s) }
        return try body()
    }

    static var current: [ServiceKey] {
        Thread.current.threadDictionary[Self.key] as? [ServiceKey] ?? []
    }

    private static func set(_ stack: [ServiceKey]) {
        Thread.current.threadDictionary[Self.key] = stack
    }
}

