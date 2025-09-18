import XCTest
@testable import SwiftHilt

final class PrewarmConcurrencyTests: XCTestCase {
    final class A {}
    final class B {}
    final class C {}

    func testConcurrentPrewarmAndResolve() async {
        let app = Container()
        var aBuilds = 0, bBuilds = 0, cBuilds = 0
        app.register(A.self, lifetime: .singleton) { _ in aBuilds += 1; return A() }
        app.register(B.self, lifetime: .singleton) { _ in bBuilds += 1; return B() }
        app.register(C.self, lifetime: .singleton) { _ in cBuilds += 1; return C() }

        let child = app.child()

        await withTaskGroup(of: Void.self) { group in
            group.addTask { app.prewarmSingletons() }
            for _ in 0..<100 {
                group.addTask { _ = child.resolve(A.self) }
                group.addTask { _ = child.resolve(B.self) }
                group.addTask { _ = child.resolve(C.self) }
            }
        }

        XCTAssertEqual(aBuilds, 1)
        XCTAssertEqual(bBuilds, 1)
        XCTAssertEqual(cBuilds, 1)

        let a1 = app.resolve(A.self); let a2 = child.resolve(A.self)
        let b1 = app.resolve(B.self); let b2 = child.resolve(B.self)
        let c1 = app.resolve(C.self); let c2 = child.resolve(C.self)
        XCTAssertTrue(a1 === a2)
        XCTAssertTrue(b1 === b2)
        XCTAssertTrue(c1 === c2)
    }
}

