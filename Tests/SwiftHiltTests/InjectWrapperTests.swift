import XCTest
@testable import SwiftHilt

final class InjectWrapperTests: XCTestCase {
    protocol S {}
    final class SImpl: S {}

    final class Owner: HasResolver {
        let resolver: Resolver
        @Inject var s: S
        init(resolver: Resolver) { self.resolver = resolver }
    }

    func testInjectResolvesFromOwnerResolver() {
        let c = Container()
        c.register(S.self) { _ in SImpl() }
        let owner = Owner(resolver: c)
        let dep: S = owner.s
        XCTAssertTrue(dep is SImpl)
    }
}

