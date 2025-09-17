SwiftHilt — A pragmatic, DAG‑aware DI for Swift (inspired by Hilt)
=================================================================

SwiftHilt is a lightweight, type‑safe dependency injection toolkit for Swift. It focuses on pure Swift constructor injection (Clean Architecture), offers scopes and qualifiers, supports multibindings, and includes a DAG recorder so you can visualize dependency graphs. SwiftUI/UIKit integrations are optional and kept separate from core DI.

Table of Contents
- What You Get
- Installation
- Quick Start (Pure Swift)
- Core Concepts
- API Reference
- Clean Architecture Example
- DAG Recording and Visualization
- Scopes and Lifetimes
- Qualifiers
- Multibindings (Set/Map)
- Threading and Safety
- Testing Guidance
- SwiftUI and UIKit (Optional)
- Roadmap (Macros and More)

What You Get
- Type‑safe resolution using concrete types and optional qualifiers.
- Scopes: `singleton`, `scoped` (per container), `transient`.
- Hierarchical containers for lifecycle scoping (parent → child).
- Simple DSL to register providers and multibindings.
- Property wrappers for convenience where appropriate (`@Injected`, SwiftUI `@EnvironmentInjected`).
- DAG recorder: observe actual runtime edges, compute a topological order, and export to Graphviz DOT.

Installation
- Swift Package Manager: open the folder with `Package.swift` in Xcode or add the repo URL as a dependency in your project.
- Minimum platforms: iOS 13, macOS 11, tvOS 13, watchOS 6.
- Minimum Swift: 5.7 for the core library. Swift 5.9 will be required once macros are added (see Roadmap).

Quick Start (Pure Swift, No Globals)
1) Define and register services
```swift
protocol Api {}
final class RealApi: Api {}

let container = Container()
container.install {
  provide(Api.self, lifetime: .singleton) { _ in RealApi() }
}
```

2) Resolve where needed
```swift
let api = container.resolve(Api.self)
// optionally optional or many
let maybe = container.optional(Api.self)
```

3) Constructor injection (Clean Architecture)
```swift
final class Repository {
  let api: Api
  init(api: Api) { self.api = api }
}

container.register(Repository.self, lifetime: .scoped) { r in
  Repository(api: r.resolve(Api.self))
}

let repo = container.resolve(Repository.self)
```

Core Concepts
- Container: The DI registry and resolver. Supports parent/child hierarchies.
- Resolver: Minimal protocol used by providers to resolve dependencies.
- Lifetime: Caching strategy per binding: `.singleton`, `.scoped`, `.transient`.
- Qualifier: Disambiguates multiple bindings for the same type (e.g., `Named("prod")`).
- Multibindings: Register multiple providers under the same type, resolved as `[T]`.
- Modules DSL: `install { provide(...) { ... }; contribute(...) { ... } }`.
- ResolverContext: Thread‑local resolver for `@Injected` in non‑SwiftUI code.
- DAG Recorder: Captures observed edges during resolution to visualize and validate.

API Reference
- Container
  - `init(parent: Container? = nil)`
  - `func child() -> Container` — creates a child scope (inherits parent bindings, separate scoped cache).
  - `func clearCache()` — clears this container’s local caches (scoped and resident singletons owned by it).
  - `@discardableResult func register<T>(_ type: T.Type = T.self, qualifier: Qualifier? = nil, lifetime: Lifetime = .singleton, factory: @escaping (Resolver) -> T) -> Self`
  - `@discardableResult func registerMany<T>(_ type: T.Type = T.self, qualifier: Qualifier? = nil, _ factory: @escaping (Resolver) -> T) -> Self`
  - `func resolve<T>(_ type: T.Type = T.self, qualifier: Qualifier? = nil) -> T`
  - `func optional<T>(_ type: T.Type = T.self, qualifier: Qualifier? = nil) -> T?`
  - `func resolveMany<T>(_ type: T.Type = T.self, qualifier: Qualifier? = nil) -> [T]`
  - DAG utilities:
    - `func startRecording()` — observe provider→dependency edges during resolution.
    - `func exportDOT() -> String?` — Graphviz DOT for the observed graph.
    - `func prewarmSingletons()` — eagerly instantiate singletons to validate wiring and warm caches.

- Lifetime
  - `.singleton` — one instance per container that owns registration; visible to children.
  - `.scoped` — one instance per resolving container; distinct in each scope.
  - `.transient` — a new instance every resolve.

- Qualifiers
  - `protocol Qualifier: Hashable`
  - `struct Named: Qualifier, ExpressibleByStringLiteral` — `Named("prod")`, `"prod"`
  - Custom qualifiers can be simple structs conforming to `Qualifier`.

- Modules DSL
  - `func install(@ModuleBuilder _ builder: () -> [Registration])`
  - `func provide<T>(_ type: T.Type = T.self, qualifier: Qualifier? = nil, lifetime: Lifetime = .singleton, _ factory: @escaping (Resolver) -> T) -> Registration`
  - `func contribute<T>(_ type: T.Type = T.self, qualifier: Qualifier? = nil, _ factory: @escaping (Resolver) -> T) -> Registration` (multibindings)

- ResolverContext (pure Swift convenience)
  - `ResolverContext.with(_ resolver: Resolver, _ body: () throws -> T) rethrows -> T`
  - `ResolverContext.current` (thread‑local)
  - Works with `@Injected` to resolve without plumbing the container through every function signature.

- Property Wrappers
  - `@Injected var dep: T` — resolves from `ResolverContext.current`.
  - `@EnvironmentInjected var dep: T` — SwiftUI only, resolves from environment (optional; see later).

Clean Architecture Example
```swift
// Domain
protocol UserRepository { func get(id: String) -> User }
struct GetUserUseCase {
  let repo: UserRepository
  init(repo: UserRepository) { self.repo = repo }
  func callAsFunction(_ id: String) -> User { repo.get(id: id) }
}

// Data
final class HttpClient { /* ... */ }
final class RemoteDataSource { init(client: HttpClient, baseURL: URL) { /* ... */ } /* ... */ }
final class CacheDataSource { /* ... */ }
final class UserRepositoryImpl: UserRepository { init(remote: RemoteDataSource, cache: CacheDataSource) { /* ... */ } /* ... */ }

// Composition
let c = Container()
c.install {
  provide(URL.self, qualifier: Named("prodBase"), lifetime: .singleton) { _ in URL(string: "https://api.example.com/user/")! }
  provide(HttpClient.self, lifetime: .singleton) { _ in HttpClient() }
}
c.register(RemoteDataSource.self) { r in RemoteDataSource(client: r.resolve(HttpClient.self), baseURL: r.resolve(URL.self, qualifier: Named("prodBase"))) }
c.register(CacheDataSource.self, lifetime: .singleton) { _ in CacheDataSource() }
c.register(UserRepository.self) { r in UserRepositoryImpl(remote: r.resolve(RemoteDataSource.self), cache: r.resolve(CacheDataSource.self)) }
c.register(GetUserUseCase.self, lifetime: .transient) { r in GetUserUseCase(repo: r.resolve(UserRepository.self)) }

// Use
let getUser = c.resolve(GetUserUseCase.self)
let user = getUser("123")
```

DAG Recording and Visualization
- Why: See the graph you actually use at runtime; catch cycles; explain wiring to teammates.
- How:
  ```swift
  c.startRecording()
  _ = c.resolve(GetUserUseCase.self)
  if let dot = c.exportDOT() { print(dot) }
  ```
- DOT can be rendered with Graphviz (`dot -Tpng graph.dot > graph.png`) or online viewers.
- Notes:
  - Edges are recorded when providers resolve dependencies.
  - `resolveMany` creates a pseudo aggregator node `[T]` with edges `[T] -> T`.
  - For deep graphs, record a representative startup path (e.g., composition root resolves) to capture meaningful edges.

Scopes and Lifetimes
- `.singleton`
  - Cached where the provider is registered; shared with children.
  - Good for clients (HTTP, DB), configs, caches.
- `.scoped`
  - Cached in the currently resolving container (per scope).
  - Good for request/feature/session‑scoped state.
- `.transient`
  - No caching; a new instance every resolve.
  - Good for lightweight value objects or stateless helpers when lifetime control isn’t needed.

Qualifiers
- Use `Named("prod")`, `Named("mock")` or define custom qualifier types for stronger typing.
- Registration and resolution must specify the same qualifier to match.
  ```swift
  c.register(URL.self, qualifier: Named("prod")) { _ in URL(string: "...")! }
  let url = c.resolve(URL.self, qualifier: Named("prod"))
  ```

Multibindings (Set/Array)
- Register multiple providers for the same type and resolve as `[T]`.
  ```swift
  protocol Middleware {}
  struct Log: Middleware {}
  struct Metrics: Middleware {}

  c.install {
    contribute(Middleware.self) { _ in Log() }
    contribute(Middleware.self) { _ in Metrics() }
  }

  let middlewares: [Middleware] = c.resolveMany(Middleware.self)
  ```
- Map multibindings are a planned enhancement (see Roadmap).

Threading and Safety
- The container uses a recursive lock; factories can resolve further dependencies safely.
- Singletons are created under lock to ensure uniqueness per provider’s container.
- `resolveMany` iterates parent → child to honor overrides and accumulate contributions.

Testing Guidance
- Build a dedicated test container and register test doubles; pass it where needed or set it in `ResolverContext` while executing the unit under test.
  ```swift
  let test = Container()
  test.register(Api.self) { _ in FakeApi() }
  ResolverContext.with(test) {
    // code that uses @Injected or explicit resolution
  }
  ```
- You can also keep the main composition and override specific bindings before resolving entry points in tests.
- Use `prewarmSingletons()` to detect misconfigurations early during test startup.

SwiftUI and UIKit (Optional)
- SwiftUI
  - `.diContainer(container)` injects a resolver into the environment.
  - `@EnvironmentInjected var dep: T` resolves from the environment’s resolver.
- UIKit
  - `UIViewController.diContainer`: associated container per view controller; inherits from parent if not set.
  - `UIViewController.makeScopedContainer()`: create a child container scoped to the view controller.
- These are convenience layers; core DI is pure Swift and does not depend on UI frameworks.

Roadmap (Macros and More)
- Swift 5.9 Macros (planned)
  - `@Injectable`: generate `init(resolver:)` for constructor injection.
  - `@Provides` and `@Binds`: generate registration glue from functions and conformances.
  - `@Module`/`@Component`: assemble modules into a typed component and emit `build()`.
  - `@EntryPoint`: typed facades into the graph for composition roots.
  - `@AssistedInject`/`@AssistedFactory`: factories that take runtime parameters + injected deps.
- Validation
  - Optional SwiftPM plugin to lint graphs and export DOT in CI.
- Performance
  - Freeze provider tables post‑build; eager singletons; microbenchmarks.

Examples
- macOS SwiftUI demo: `SwiftHiltDemo` (run the scheme in Xcode).
- iOS SwiftUI demo: `Examples/SwiftHiltDemo_iOS/SwiftHiltDemo_iOS.xcodeproj`.
- Pure Swift DAG sample: `DAGSample` (prints Graphviz DOT).

Micro Macros (MVP)
- A minimal macro target `SwiftHiltMacros` is included. It provides:
  - `@Injectable` on types with a designated `init(...)` to synthesize `init(resolver:)` using `resolver.resolve(...)` for each parameter.
  - `@Provides(lifetime:, qualifier:)` on zero‑parameter `static func` inside a `@Module` type.
  - `@Module` generates `static func __register(into:)` that registers all `@Provides` functions with lifetime/qualifier.
  - `@Binds(ProtocolType.self, lifetime:, qualifier:)` on a concrete type (requires `@Injectable`) to bind a protocol to an impl; generates `__register(into:)`.
  - `@Component(modules: [Type.self, ...])` generates `static func build() -> Container` that calls `Type.__register(into:)` for each listed type (modules or bind types).
- Limitations (by design for MVP):
  - `@Provides` supports zero‑parameter static functions only; parameters will be supported later.
  - Qualifiers and lifetimes are supported in macros; multibindings via macros not yet.
  - `@EntryPoint`, `@Assisted*` not implemented yet.
- Usage (see `Examples/DAGSample/MicroMacrosExample.swift`)
  ```swift
  @Module
  struct NetworkModule {
    @Provides static func httpClient() -> HttpClient { HttpClient() }
    @Provides static func baseURL() -> URL { URL(string: "https://api.example.com")! }
  }

  @Component(modules: [NetworkModule.self])
  struct AppComponent {}

  @Injectable
  final class RemoteDataSource2 {
    init(client: HttpClient, baseURL: URL) { /* ... */ }
  }

  // Build container and use synthesized init(resolver:)
  let c = AppComponent.build()
  c.register(RemoteDataSource2.self) { r in RemoteDataSource2(resolver: r) }
  UserRepositoryImpl2.__register(into: c) // or include in @Component(modules: [..., UserRepositoryImpl2.self])
  let ds = c.resolve(RemoteDataSource2.self)
  let repo: UserRepository = c.resolve(UserRepository.self)
  ```

Using Macros End‑to‑End (Clean Architecture Example)
```swift
import SwiftHilt

// Domain
protocol UserRepository { func get(id: String) -> User }
struct GetUserUseCase { let repo: UserRepository; init(repo: UserRepository) { self.repo = repo } }
struct User { let id: String; let name: String }

// Infrastructure providers via module
@Module
struct InfraModule {
  @Provides(lifetime: .singleton)
  static func httpClient() -> HttpClient { HttpClient() }

  @Provides(lifetime: .singleton, qualifier: Named("base"))
  static func baseURL() -> URL { URL(string: "https://api.example.com/user/")! }
}

// Injectable types (constructor injection)
@Injectable
final class RemoteDataSource { init(client: HttpClient, base: URL) { /* ... */ } }

@Injectable
final class CacheDataSource { init() {} }

@Injectable
@Binds(UserRepository.self, lifetime: .scoped)
final class UserRepositoryImpl: UserRepository {
  let remote: RemoteDataSource
  let cache: CacheDataSource
  init(remote: RemoteDataSource, cache: CacheDataSource) { self.remote = remote; self.cache = cache }
  func get(id: String) -> User { /* ... */ User(id: id, name: "Alice") }
}

@Component(modules: [InfraModule.self, UserRepositoryImpl.self])
struct AppComponent {}

// Register remaining injectables via @Register in a bindings module
@Module
struct AppBindings {
  @Register(.scoped) static var remoteDataSource: RemoteDataSource
  @Register(.singleton) static var cacheDataSource: CacheDataSource
  @Register(.transient) static var getUserUseCase: GetUserUseCase
}

@Component(modules: [InfraModule.self, UserRepositoryImpl.self, AppBindings.self])
struct Root {}

// Build container
let c = Root.build()

// Use
let useCase = c.resolve(GetUserUseCase.self)
```

Macro Requirements and Setup
- Use Xcode 15 or Swift 5.9+.
- When importing `SwiftHilt`, macros are re‑exported, so `import SwiftHilt` is enough.
- If building from the command line, ensure the swift toolchain has macro support.

Macro Pitfalls and Current Limits
- `@Provides` supports zero‑parameter static functions in MVP. For functions with parameters, register via runtime or wait for parameter support.
- Qualifiers in macros are supported for `@Provides` and `@Binds`. Parameter‑level qualifiers in `@Injectable` initializers are not parsed yet; use separate qualified providers and request them by type+qualifier when constructing.
- `@Binds` requires `@Injectable` on the implementation so the synthesized `init(resolver:)` exists.
- `@Component(modules:)` accepts modules and any types that provide a `__register(into:)` (e.g., from `@Module` or `@Binds`).

Runtime‑Only Path (no macros)
- You can do everything via `register`/`install`/`contribute` without macros. Macros simply generate registration glue to reduce boilerplate.

Overriding and Testing with Macros
- Build a test container and re‑register bindings before resolving entry points.
- If a production type is bound via `@Binds` and included in a `@Component`, you can either:
  - Build the component and override with `register` calls (later registrations win), or
  - Create a test module with providers and use a test‑specific component that installs that module.

Cheat Sheet
- Register a concrete type constructed from DI:
  ```swift
  @Injectable final class Foo { init(bar: Bar) {} }
  c.register(Foo.self) { r in Foo(resolver: r) }
  ```
- Bind a protocol to an implementation:
  ```swift
  @Injectable
  @Binds(Service.self, lifetime: .scoped)
  final class RealService: Service { init(dep: Dep) {} }
  RealService.__register(into: c)
  ```
- Provide primitives and singletons via modules:
  ```swift
  @Module struct M { @Provides(lifetime: .singleton) static func cfg() -> Config { Config() } }
  M.__register(into: c)
  ```
- Register injectables without manual factory closures using property wrapper:
  ```swift
  @Injectable final class Foo { init(bar: Bar) {} }
  @Module struct Binds { @Register(.scoped) static var foo: Foo }
  Binds.__register(into: c) // registers Foo using synthesized init(resolver:)
  ```
- Compose a component from modules:
  ```swift
  @Component(modules: [M.self, RealService.self]) struct C {}
  let c = C.build()
  ```
