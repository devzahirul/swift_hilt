import XCTest
@testable import SwiftHilt

final class ModuleDslTests: XCTestCase {
    protocol MW {}
    struct A: MW {}
    struct B: MW {}

    func testProvideAndContributeWithQualifiers() {
        let c = Container()
        c.install {
            provide(String.self, qualifier: Named("a"), lifetime: .singleton) { _ in "A" }
            provide(String.self, qualifier: Named("b"), lifetime: .singleton) { _ in "B" }
            contribute(MW.self) { _ in A() }
            contribute(MW.self) { _ in B() }
        }

        XCTAssertEqual(c.resolve(String.self, qualifier: Named("a")), "A")
        XCTAssertEqual(c.resolve(String.self, qualifier: Named("b")), "B")
        let arr: [MW] = c.resolveMany(MW.self)
        XCTAssertEqual(arr.count, 2)
        XCTAssertTrue(arr.contains { $0 is A })
        XCTAssertTrue(arr.contains { $0 is B })
    }
}

