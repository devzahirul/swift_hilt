import XCTest
@testable import SwiftHilt

final class DAGTests: XCTestCase {
    protocol A {}
    final class AImpl: A { }
    protocol B {}
    final class BImpl: B {
        let a: A
        init(a: A) { self.a = a }
    }
    final class C {
        let b: B
        init(b: B) { self.b = b }
    }

    func testRecordsEdgesAndToposorts() throws {
        let c = Container()
        c.register(A.self, lifetime: .singleton) { _ in AImpl() }
        c.register(B.self, lifetime: .scoped) { r in BImpl(a: r.resolve(A.self)) }
        c.register(C.self, lifetime: .transient) { r in C(b: r.resolve(B.self)) }

        c.startRecording()
        _ = c.resolve(C.self) // trigger graph recording

        let plan = try c.buildPlan()
        let types = plan.order.map { $0.description }
        // A should come before B, and B before C in some order
        let idxA = types.firstIndex(where: { $0.contains("A") })!
        let idxB = types.firstIndex(where: { $0.contains("B") })!
        let idxC = types.firstIndex(where: { $0.contains("C") })!
        XCTAssertLessThan(idxA, idxB)
        XCTAssertLessThan(idxB, idxC)

        // DOT should be non-empty
        XCTAssertNotNil(c.exportDOT())
    }
}

