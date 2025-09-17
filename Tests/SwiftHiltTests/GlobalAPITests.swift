import XCTest
@testable import SwiftHilt

final class GlobalAPITests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Ensure a fresh default container for each test
        useContainer(Container())
    }

    func testGlobalInstallAndResolve() {
        install { provide(Int.self, lifetime: .singleton) { _ in 42 } }
        let v: Int = resolve()
        XCTAssertEqual(v, 42)
        XCTAssertEqual(optional(Int.self), 42)
    }

    func testUseContainerOverridesDefault() {
        // Default container returns A
        install { provide(String.self) { _ in "A" } }
        XCTAssertEqual(resolve(String.self), "A")

        // Swap default container
        let other = Container()
        other.register(String.self) { _ in "B" }
        useContainer(other)
        XCTAssertEqual(resolve(String.self), "B")
    }

    func testEnvironmentPrecedenceOverDefault() {
        install { provide(Bool.self) { _ in false } }
        XCTAssertEqual(resolve(Bool.self), false)

        let env = Container()
        env.register(Bool.self) { _ in true }
        Injection.with(env) {
            XCTAssertEqual(resolve(Bool.self), true)
        }
    }

    func testResolveManyGlobal() {
        protocol MW {}
        struct A: MW {}; struct B: MW {}
        registerMany(MW.self) { _ in A() }
        registerMany(MW.self) { _ in B() }
        let arr: [MW] = resolveMany()
        XCTAssertEqual(arr.count, 2)
    }

    func testPrewarmAndDAGWrappers() {
        var builds = 0
        install { provide(Date.self, lifetime: .singleton) { _ in builds += 1; return Date() } }
        prewarmSingletons()
        _ = resolve(Date.self)
        XCTAssertEqual(builds, 1)

        startRecording()
        _ = resolve(Date.self)
        XCTAssertNotNil(exportDOT())
    }
}

