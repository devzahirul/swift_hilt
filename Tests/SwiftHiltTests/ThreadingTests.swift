import XCTest
@testable import SwiftHilt

final class ThreadingTests: XCTestCase {
    func testConcurrentSingletonResolutionCreatesSingleInstance() async throws {
        final class Svc {}
        let c = Container()
        var builds = 0
        c.register(Svc.self, lifetime: .singleton) { _ in builds += 1; return Svc() }

        let count = 100
        let results: [Svc] = try await withThrowingTaskGroup(of: Svc.self) { group in
            for _ in 0..<count {
                group.addTask { c.resolve(Svc.self) }
            }
            var arr: [Svc] = []
            for try await r in group { arr.append(r) }
            return arr
        }

        XCTAssertEqual(builds, 1, "singleton factory should run once under heavy concurrency")
        let first = try XCTUnwrap(results.first)
        XCTAssertTrue(results.allSatisfy { $0 === first })
    }

    func testConcurrentScopedResolutionIsCachedPerScope() async throws {
        final class Svc {}
        let root = Container()
        root.register(Svc.self, lifetime: .scoped) { _ in Svc() }
        let a = root.child()
        let b = root.child()

        let count = 64
        async let arrA: [Svc] = withTaskGroup(of: Svc.self) { group in
            for _ in 0..<count { group.addTask { a.resolve(Svc.self) } }
            var list: [Svc] = []
            for await r in group { list.append(r) }
            return list
        }
        async let arrB: [Svc] = withTaskGroup(of: Svc.self) { group in
            for _ in 0..<count { group.addTask { b.resolve(Svc.self) } }
            var list: [Svc] = []
            for await r in group { list.append(r) }
            return list
        }

        let (la, lb) = await (arrA, arrB)
        let fa = try XCTUnwrap(la.first)
        let fb = try XCTUnwrap(lb.first)
        XCTAssertTrue(la.allSatisfy { $0 === fa })
        XCTAssertTrue(lb.allSatisfy { $0 === fb })
        XCTAssertFalse(fa === fb, "scoped instances must differ across child scopes")
    }

    func testResolveManyConcurrentIsStable() async throws {
        protocol M {}
        struct A: M {}
        struct B: M {}
        struct C: M {}
        struct D: M {}
        let app = Container()
        app.install {
            provide(M.self) { _ in A() }
            provide(M.self) { _ in B() }
        }
        app.install {
            provide(M.self) { _ in C() }
            provide(M.self) { _ in D() }
        }
        let child = app.child()

        let count = 50
        let lengths: [Int] = await withTaskGroup(of: Int.self) { group in
            for _ in 0..<count {
                group.addTask { child.resolveMany(M.self).count }
            }
            var arr: [Int] = []
            for await len in group { arr.append(len) }
            return arr
        }
        XCTAssertTrue(lengths.allSatisfy { $0 == 4 })
    }

    func testTaskLocalInjectionIsolationBetweenConcurrentTasks() async throws {
        let a = Container(); a.register(String.self) { _ in "A" }
        let b = Container(); b.register(String.self) { _ in "B" }

        let count = 40
        let results: [String] = await withTaskGroup(of: String.self) { group in
            for i in 0..<count {
                group.addTask {
                    if i % 2 == 0 {
                        return Injection.with(a) { resolve(String.self) }
                    } else {
                        return Injection.with(b) { resolve(String.self) }
                    }
                }
            }
            var list: [String] = []
            for await r in group { list.append(r) }
            return list
        }

        let aCount = results.filter { $0 == "A" }.count
        let bCount = results.filter { $0 == "B" }.count
        XCTAssertEqual(aCount + bCount, count)
        XCTAssertGreaterThan(aCount, 0)
        XCTAssertGreaterThan(bCount, 0)
        // Ensure isolation is respected roughly evenly
        XCTAssertEqual(aCount, bCount, accuracy: 2)
    }
}

