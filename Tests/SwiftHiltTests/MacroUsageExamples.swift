import XCTest
@testable import SwiftHilt

#if canImport(SwiftHiltMacros)
@Module
struct TestModule {
    @Provides(lifetime: .singleton)
    static func number() -> Int { 42 }

    @Provides(lifetime: .scoped)
    static func string(int: Int) -> String { "num_\(int)" }
}

@Component(modules: [TestModule.self])
struct TestComponent {}

@Injectable
final class NeedsString { let s: String; init(s: String) { self.s = s } }

final class MacroUsageExamples: XCTestCase {
    func testBuildsAndResolves() {
        let c = TestComponent.build()
        TestModule.__register(into: c) // idempotent
        c.register(NeedsString.self) { r in NeedsString(resolver: r) }
        let v: String = c.resolve()
        XCTAssertEqual(v, "num_42")
        _ = c.resolve(NeedsString.self)
    }
}
#else
final class MacroUsageExamples: XCTestCase {
    func testMacrosSkippedWhenUnavailable() {
        // No-op to keep tests green when macros aren't available in the toolchain.
        XCTAssertTrue(true)
    }
}
#endif
