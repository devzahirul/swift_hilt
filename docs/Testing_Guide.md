Testing Guide (SwiftHilt)
=========================

This guide consolidates testing patterns for SwiftHilt across unit tests, integration tests, and UI tests.

Contents
- Building a test container
- Overriding bindings selectively
- Task and thread-local environments
- Prewarming singletons
- Concurrency stress testing
- UI testing patterns

Build a Test Container
----------------------
Create a fresh `Container()` and register fakes/mocks. Use `useContainer` (global facade) or `Injection.with`/`ResolverContext.with` to make it visible to code under test.

```swift
import SwiftHilt
import XCTest

final class RepoTests: XCTestCase {
  func makeTestContainer() -> Container {
    let c = Container()
    c.register(Api.self) { _ in FakeApi() }
    c.register(Repo.self) { r in Repo(api: r.resolve()) }
    return c
  }

  func testRepo() {
    let c = makeTestContainer(); useContainer(c)
    let repo: Repo = resolve()
    XCTAssertEqual(repo.get(), "ok")
  }
}
```

Override Bindings
-----------------
Set up your real composition, then override selected bindings before resolving entry points. Later calls resolve to overridden bindings for the lifetime of that container.

Task/Thread-Local Environments
------------------------------
- `Injection.with(container) { ... }` sets a Task-local resolver (falls back to thread-local) for the duration of `body`.
- `ResolverContext.with(container) { ... }` sets a thread-local resolver. Useful outside of async contexts.
- The resolution order is Task-local → Thread-local → Global default.

Prewarm Singletons
------------------
`container.prewarmSingletons()` instantiates all singleton bindings visible from a container. Use in setUp to catch configuration errors early.

Concurrency Stress Testing
--------------------------
Examples live in `Tests/SwiftHiltTests/ThreadingTests.swift` and `PrewarmConcurrencyTests.swift`:
- Concurrent singleton resolution results in a single build and identical instances.
- Scoped resolution caches per child under concurrency.
- `resolveMany` returns stable arrays while parent/child chains are read in parallel.
- Task-local isolation is preserved across concurrent tasks.

UI Testing Patterns
-------------------
In the iOS example (`SwiftHiltDemoiOS`), the DI wiring checks `UITEST_INMEMORY=1` to force the in-memory repository for predictable UI tests.

```swift
// In DI.swift (iOS demo)
if ProcessInfo.processInfo.environment["UITEST_INMEMORY"] == "1" {
  return InMemoryTaskRepository()
}
```

In UI tests, set the environment before `app.launch()`:

```swift
let app = XCUIApplication()
app.launchEnvironment["UITEST_INMEMORY"] = "1"
app.launch()
```

Tips
----
- Keep factories fast; avoid I/O during object construction.
- Use qualifiers (`Named("...")`) to register multiple variants and pick in tests.
- Use `@Injected`/`@EnvironmentInjected` in SwiftUI for straightforward resolution in views.

