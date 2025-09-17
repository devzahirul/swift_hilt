import Foundation

// Internal DAG types used for dependency graph recording and planning.

final class DAGRecorder {
    private let lock = NSLock()
    private(set) var nodes: Set<ServiceKey> = []
    private(set) var edges: [ServiceKey: Set<ServiceKey>] = [:] // from -> {to}

    // Thread-local stack of currently building provider keys
    private static let stackKey = "SwiftHilt.DAGRecorder.BuildStack"

    func pushBuilding(_ key: ServiceKey) {
        var stack = Self.currentStack
        stack.append(key)
        Self.setStack(stack)
    }

    func popBuilding() {
        var stack = Self.currentStack
        _ = stack.popLast()
        Self.setStack(stack)
    }

    var currentBuilding: ServiceKey? { Self.currentStack.last }

    func recordNode(_ key: ServiceKey) {
        lock.lock(); defer { lock.unlock() }
        nodes.insert(key)
    }

    func recordEdge(from: ServiceKey, to: ServiceKey) {
        lock.lock(); defer { lock.unlock() }
        var set = edges[from] ?? []
        set.insert(to)
        edges[from] = set
        nodes.insert(from)
        nodes.insert(to)
    }

    func snapshot() -> (nodes: Set<ServiceKey>, edges: [ServiceKey: Set<ServiceKey>]) {
        lock.lock(); defer { lock.unlock() }
        return (nodes, edges)
    }

    // MARK: Thread dictionary helpers
    private static var currentStack: [ServiceKey] {
        Thread.current.threadDictionary[stackKey] as? [ServiceKey] ?? []
    }
    private static func setStack(_ s: [ServiceKey]) {
        Thread.current.threadDictionary[stackKey] = s
    }
}

struct DAGPlanError: Error, CustomStringConvertible {
    let description: String
}

struct DAGPlan {
    let order: [ServiceKey] // topological order (dependency-first)
    let edges: [ServiceKey: Set<ServiceKey>]

    func dot() -> String {
        var out = "digraph Dependencies {\n"
        out += "  rankdir=LR;\n"
        // nodes
        var printed: Set<ServiceKey> = []
        for key in order { if !printed.contains(key) { out += "  \(label(key));\n"; printed.insert(key) } }
        // edges
        for (from, tos) in edges {
            for to in tos { out += "  \(label(from)) -> \(label(to));\n" }
        }
        out += "}\n"
        return out
    }

    private func label(_ key: ServiceKey) -> String {
        // sanitize for DOT
        let name = key.description.replacingOccurrences(of: "\"", with: "\'")
        return "\"\(name)\""
    }
}

/// Build a topological order from the recorded graph. Throws on cycles.
func buildTopologicalPlan(nodes: Set<ServiceKey>, edges: [ServiceKey: Set<ServiceKey>]) throws -> DAGPlan {
    // Kahn's algorithm
    var incomingCount: [ServiceKey: Int] = [:]
    var adj: [ServiceKey: Set<ServiceKey>] = [:]

    for n in nodes { incomingCount[n] = 0; adj[n] = [] }
    for (u, vs) in edges {
        for v in vs {
            incomingCount[v, default: 0] += 1
            adj[u, default: []].insert(v)
        }
    }

    var queue: [ServiceKey] = incomingCount.filter { $0.value == 0 }.map { $0.key }
    var order: [ServiceKey] = []

    while let n = queue.first {
        queue.removeFirst()
        order.append(n)
        if let vs = adj[n] {
            for v in vs {
                incomingCount[v]! -= 1
                if incomingCount[v] == 0 { queue.append(v) }
            }
        }
    }

    if order.count != nodes.count {
        // find a cycle for reporting
        throw DAGPlanError(description: "Cycle detected; graph is not a DAG")
    }

    return DAGPlan(order: order, edges: edges)
}

