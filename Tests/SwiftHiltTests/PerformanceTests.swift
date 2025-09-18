import XCTest
@testable import SwiftHilt

final class PerformanceTests: XCTestCase {
    func testResolveSingletonPerformance() {
        final class S {}
        let c = Container()
        c.register(S.self, lifetime: .singleton) { _ in S() }

        measure {
            for _ in 0..<20_000 { _ = c.resolve(S.self) }
        }
    }

    func testResolveTransientPerformance() {
        struct V {}
        let c = Container()
        c.register(V.self, lifetime: .transient) { _ in V() }

        measure {
            for _ in 0..<15_000 { _ = c.resolve(V.self) }
        }
    }

    func testResolveManyPerformance() {
        protocol M {}
        struct A: M {}; struct B: M {}; struct C: M {}; struct D: M {}; struct E: M {}
        let c = Container()
        c.install {
            provide(M.self) { _ in A() }
            provide(M.self) { _ in B() }
            provide(M.self) { _ in C() }
            provide(M.self) { _ in D() }
            provide(M.self) { _ in E() }
        }

        measure {
            for _ in 0..<5_000 { _ = c.resolveMany(M.self) }
        }
    }

    func testPrewarmSingletonsPerformance() {
        let c = Container()
        var builds = 0
        // Register many singleton bindings under different qualifiers
        for i in 0..<200 {
            c.register(Int.self, qualifier: Named("q_\(i)"), lifetime: .singleton) { _ in builds += 1; return i }
        }

        measure {
            c.prewarmSingletons()
        }
        XCTAssertEqual(builds, 200)
    }
}

