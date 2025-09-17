import XCTest
@testable import SwiftHilt

final class InjectionEnvironmentTests: XCTestCase {
    protocol P {}
    final class PImpl: P {}

    final class UsesEnv {
        @Inject var p: P
    }

    func testInjectionWithEnvironment() {
        let c = Container()
        c.register(P.self) { _ in PImpl() }
        Injection.with(c) {
            let u = UsesEnv()
            let p: P = u.p
            XCTAssertTrue(p is PImpl)
        }
    }

    func testGlobalDefaultFallback() {
        let c = Container()
        c.register(Int.self) { _ in 101 }
        Injection.globalDefault = c
        final class G { @Inject var v: Int }
        let g = G()
        XCTAssertEqual(g.v, 101)
        Injection.globalDefault = nil
    }
}

