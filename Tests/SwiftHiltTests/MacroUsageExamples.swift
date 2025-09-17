import XCTest
@testable import SwiftHilt

// This test file hosts code that should compile if macros expand correctly.

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

