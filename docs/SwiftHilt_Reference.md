SwiftHilt Reference (API + Patterns)
===================================

This reference documents the SwiftHilt core library (Sources/SwiftHilt), with usage examples, best use cases, limitations, and common errors/warnings.

Contents
- Container, Resolver, Registration
- Lifetimes and Scopes
- Qualifiers and Multibindings
- Global API and Environments
- Property Wrappers (@Inject, @Injected, @EnvironmentInjected)
- SwiftUI / UIKit Integration
- DAG Recording and Diagnostics
- Testing Patterns

Container, Resolver, Registration
---------------------------------
- Core types
  - `Container` – registry + resolver. Thread-safe via recursive lock.
    - File: Sources/SwiftHilt/Container.swift:1
  - `Resolver` – minimal protocol used by factories to resolve other services.
    - File: Sources/SwiftHilt/Container.swift:1

- Register services
  - Single binding:
    - `register(T.Type, qualifier:, lifetime:, factory:)` – installs a single provider.
    - Example:
      ```swift
      let app = Container()
      app.register(URL.self, lifetime: .singleton) { _ in URL(string: "https://api")! }
      app.register(HttpClient.self, lifetime: .singleton) { _ in HttpClient() }
      app.register(Api.self, lifetime: .scoped) { r in RealApi(base: r.resolve(URL.self), client: r.resolve(HttpClient.self)) }
      ```
  - Many bindings (multibindings):
    - `registerMany(T.Type, qualifier:, factory:)` – contributes to a list.
    - Resolve via `resolveMany(T.self)`.
      ```swift
      protocol Middleware {}; struct Log: Middleware {}; struct Metrics: Middleware {}
      app.registerMany(Middleware.self) { _ in Log() }
      app.registerMany(Middleware.self) { _ in Metrics() }
      let all: [Middleware] = app.resolveMany()
      ```

- Resolve services
  - `resolve(T.self, qualifier:)` – returns T or traps in DEBUG if missing.
  - `optional(T.self, qualifier:)` – returns T? (nil if missing).
  - `resolveMany(T.self, qualifier:)` – returns `[T]` (empty if none). Records DAG edges from pseudo `[T]` to `T`.

- Scope hierarchy
  - `child()` – creates a child container that inherits providers and singletons from its ancestors but maintains its own `.scoped` cache.
  - `clearCache()` – clears scoped cache for the current container only.

- Best use cases
  - Composition root in apps; per-feature child containers for isolation; test containers for overriding bindings.

- Limitations
  - No type erasure for lifetimes at compile time; misuse shows up at runtime.
  - No typed qualifier keys yet (string-based `Named` provided; custom types are supported though).

- Common errors/warnings
  - “Resolved instance type mismatch” – factory returned the wrong type; check registration site.
  - “ResolutionError.notFound” – missing binding; ensure you registered before resolving.

Lifetimes and Scopes
--------------------
- `Lifetime` – `.singleton`, `.scoped`, `.transient`.
  - File: Sources/SwiftHilt/Lifetime.swift:1
- Semantics
  - Singleton – cached at the container where it is registered, visible to children.
  - Scoped – cached in the resolving container (per child scope).
  - Transient – no caching; factory executes every time.
- Best use
  - Singleton: clients (HTTP, DB), heavy caches, configuration.
  - Scoped: per-scene/session state.
  - Transient: lightweight value objects, factories.
- Pitfalls
  - Unexpected sharing: `.singleton` defined in parent is shared with all children.
  - Use child containers to scope mutable state or choose `.scoped`.

Qualifiers and Multibindings
----------------------------
- Qualifiers
  - `protocol Qualifier: Hashable`; `struct Named: Qualifier, ExpressibleByStringLiteral`
  - File: Sources/SwiftHilt/Qualifiers.swift:1
  - Example:
    ```swift
    app.register(URL.self, qualifier: Named("prod")) { _ in URL(string: "https://api")! }
    let base: URL = app.resolve(URL.self, qualifier: Named("prod"))
    ```
- Multibindings
  - File: Sources/SwiftHilt/Multibindings.swift:1
  - Best use: plugins/hooks/pipelines where ordered list of contributions is desired.
  - Limitation: map-based multibindings aren’t implemented yet.

Global API and Environments
---------------------------
- Global facade (optional)
  - File: Sources/SwiftHilt/GlobalAPI.swift:1
  - `install { ... }`, `register`, `registerMany`
  - `resolve`, `optional`, `resolveMany`
  - `useContainer(_)` swaps the default container.
  - Use sparingly in production; prefer explicit containers passed at the composition root.
- Resolver context (thread-local)
  - File: Sources/SwiftHilt/ResolverContext.swift:1
  - `ResolverContext.with(container) { /* resolves via thread-local */ }`
- Task-local / global environment
  - File: Sources/SwiftHilt/InjectionEnvironment.swift:1
  - `Injection.with(container) { ... }` (Task-local > thread-local > globalDefault).
  - Best use: enable `@Inject` without passing containers around.

Property Wrappers
-----------------
- `@Inject`
  - File: Sources/SwiftHilt/Inject.swift:1
  - Looks up resolver in enclosing `HasResolver` or current environment (Task/thread/global). Caches result.
  - Best use: class-level injection with `HasResolver`.
  - Limitation: requires enclosing instance conform to `HasResolver` unless an environment is set.
  - Common error: “@Inject could not find a resolver” – set environment via `Injection.with` or conform to `HasResolver`.
- `@Injected` / `@EnvironmentInjected` (SwiftUI)
  - File: Sources/SwiftHilt/Injected.swift:1, Sources/SwiftHilt/SwiftUIIntegration.swift:1
  - `@EnvironmentInjected` resolves from SwiftUI environment set by `.diContainer(container)`.

SwiftUI / UIKit Integration
---------------------------
- SwiftUI
  - File: Sources/SwiftHilt/SwiftUIIntegration.swift:1
  - `View.diContainer(_:)` – injects resolver into environment.
  - `@EnvironmentInjected` – resolves from environment.
- UIKit
  - File: Sources/SwiftHilt/UIKitIntegration.swift:1
  - `UIViewController.diContainer` and `makeScopedContainer()` for VC-scoped graphs.

DAG Recording and Diagnostics
-----------------------------
- File: Sources/SwiftHilt/Diagnostics.swift:1, Sources/SwiftHilt/DAG/Introspection.swift:1
- `startRecording()` then resolve your entry points; export with `exportDOT()`.
- Detects cycles (throws), visualizes dependency graph (Graphviz).
- Best use: CI validation and architectural reviews.

Testing Patterns
----------------
- Build a test container and swap it into the environment or use directly.
  ```swift
  let test = Container()
  test.register(Api.self) { _ in FakeApi() }
  Injection.with(test) { /* code with @Inject */ }
  ```
- Prewarm singletons for validation: `container.prewarmSingletons()`.
- Concurrency
  - The container uses a recursive lock; see `ThreadingTests.swift` for heavy concurrent scenarios.
  - Avoid long-running code in factories; keep constructions fast.

