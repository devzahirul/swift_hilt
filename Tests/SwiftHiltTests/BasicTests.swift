import XCTest
@testable import SwiftHilt

final class BasicTests: XCTestCase {
    func testResolveSingleton() {
        let c = Container()
        c.register(Int.self, lifetime: .singleton) { _ in 42 }
        XCTAssertEqual(c.resolve(Int.self), 42)
        XCTAssertEqual(c.resolve(Int.self), 42)
    }

    func testResolveScopedAcrossChildren() {
        let app = Container()
        app.register(UUID.self, lifetime: .scoped) { _ in UUID() }
        let a = app.resolve(UUID.self)
        let child = app.child()
        let b = child.resolve(UUID.self)
        let c = child.resolve(UUID.self)
        XCTAssertNotEqual(a, b) // different scopes
        XCTAssertEqual(b, c)    // same child scope caches
    }

    func testQualifiers() {
        let c = Container()
        c.register(String.self, qualifier: Named("a")) { _ in "A" }
        c.register(String.self, qualifier: Named("b")) { _ in "B" }
        XCTAssertEqual(c.resolve(String.self, qualifier: Named("a")), "A")
        XCTAssertEqual(c.resolve(String.self, qualifier: Named("b")), "B")
        XCTAssertNil(c.optional(String.self))
    }

    func testMany() {
        let c = Container()
        protocol M {}
        struct A: M {}
        struct B: M {}
        c.registerMany(M.self) { _ in A() }
        c.registerMany(M.self) { _ in B() }
        let arr = c.resolveMany(M.self)
        XCTAssertEqual(arr.count, 2)
    }

    func testProviderAndLazy() {
        let c = Container()
        var builds = 0
        c.register(Date.self, lifetime: .transient) { _ in builds += 1; return Date() }
        let p = Provider<Date>(resolver: c)
        _ = p()
        _ = p()
        XCTAssertEqual(builds, 2)

        builds = 0
        c.register(String.self, lifetime: .transient) { _ in builds += 1; return UUID().uuidString }
        let lazy = Lazy<String>(resolver: c)
        let a = lazy.value
        let b = lazy.value
        XCTAssertEqual(a, b)
        XCTAssertEqual(builds, 1)
    }
}

