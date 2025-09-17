import XCTest
@testable import SwiftHilt

final class ServiceKeyAndQualifierTests: XCTestCase {
    func testNamedQualifierHashAndLiteral() {
        let a: Named = "prod"
        let b = Named("prod")
        let c = Named("dev")
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
        var set = Set<Named>()
        set.insert(a)
        set.insert(b)
        set.insert(c)
        XCTAssertEqual(set.count, 2)
    }

    func testServiceKeyDescriptionIncludesQualifier() {
        let key1 = ServiceKey(String.self)
        let key2 = ServiceKey(String.self, qualifier: Named("q"))
        XCTAssertTrue(key1.description.contains("String"))
        XCTAssertTrue(key2.description.contains("q"))
    }
}

