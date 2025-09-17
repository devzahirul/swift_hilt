import XCTest
@testable import SwiftHilt

final class ContainerLifetimeTests: XCTestCase {
    func testSingletonAcrossHierarchy() {
        let app = Container()
        var builds = 0
        app.register(Int.self, lifetime: .singleton) { _ in builds += 1; return 7 }
        let c1 = app.child()
        let c2 = app.child()
        XCTAssertEqual(app.resolve(Int.self), 7)
        XCTAssertEqual(c1.resolve(Int.self), 7)
        XCTAssertEqual(c2.resolve(Int.self), 7)
        XCTAssertEqual(builds, 1, "singleton should build once at owner container")
    }

    func testScopedCachesPerResolvingContainer() {
        let parent = Container()
        parent.register(UUID.self, lifetime: .scoped) { _ in UUID() }
        let c1 = parent.child()
        let c2 = parent.child()
        let a = c1.resolve(UUID.self)
        let b = c1.resolve(UUID.self)
        let x = c2.resolve(UUID.self)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, x)
        let p = parent.resolve(UUID.self)
        XCTAssertNotEqual(p, a)
    }

    func testTransientBuildsEveryTime() {
        let c = Container()
        var builds = 0
        c.register(Date.self, lifetime: .transient) { _ in builds += 1; return Date() }
        _ = c.resolve(Date.self)
        _ = c.resolve(Date.self)
        XCTAssertEqual(builds, 2)
    }

    func testClearCache() {
        let c = Container()
        c.register(String.self, lifetime: .scoped) { _ in UUID().uuidString }
        let a = c.resolve(String.self)
        c.clearCache()
        let b = c.resolve(String.self)
        XCTAssertNotEqual(a, b)
    }

    func testOptionalAndMissing() {
        let c = Container()
        XCTAssertNil(c.optional(Bool.self))
        c.register(Bool.self) { _ in true }
        XCTAssertEqual(c.optional(Bool.self), true)
    }
}

