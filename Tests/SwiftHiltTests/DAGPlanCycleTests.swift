import XCTest
@testable import SwiftHilt

final class DAGPlanCycleTests: XCTestCase {
    func testToposortDetectsCycle() {
        // Build a synthetic cyclic graph: A -> B -> C -> A
        let AKey = ServiceKey(String.self, qualifier: Named("A"))
        let BKey = ServiceKey(String.self, qualifier: Named("B"))
        let CKey = ServiceKey(String.self, qualifier: Named("C"))
        let nodes: Set<ServiceKey> = [AKey, BKey, CKey]
        let edges: [ServiceKey: Set<ServiceKey>] = [
            AKey: [BKey],
            BKey: [CKey],
            CKey: [AKey]
        ]
        do {
            _ = try buildTopologicalPlan(nodes: nodes, edges: edges)
            XCTFail("Expected cycle error")
        } catch {
            // ok
        }
    }

    func testAggregatorEdgesRecorded() {
        let c = Container()
        protocol M {}
        struct X: M {}
        struct Y: M {}
        c.registerMany(M.self) { _ in X() }
        c.registerMany(M.self) { _ in Y() }
        c.startRecording()
        _ = c.resolveMany(M.self) as [M]
        let snap = c.stopRecording()!
        // Check there is an aggregator node for [M]
        let aggKey = ServiceKey([M].self)
        XCTAssertTrue(snap.nodes.contains(aggKey))
        // And edges from aggregator to M key
        let mKey = ServiceKey(M.self)
        let tos = snap.edges[aggKey] ?? []
        XCTAssertTrue(tos.contains(mKey))
    }
}

