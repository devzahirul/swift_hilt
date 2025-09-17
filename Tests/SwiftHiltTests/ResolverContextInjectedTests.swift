import XCTest
@testable import SwiftHilt

final class ResolverContextInjectedTests: XCTestCase {
    protocol S {}
    final class Impl: S {}

    final class Owner {
        @Injected var s: S
    }

    func testInjectedUsesResolverContext() {
        let c = Container()
        c.register(S.self) { _ in Impl() }
        var owner = Owner()
        ResolverContext.with(c) {
            let s: S = owner.s
            XCTAssertTrue(s is Impl)
        }
    }
}

