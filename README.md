SwiftHilt — A pragmatic DI container for Swift inspired by Hilt
===============================================================

SwiftHilt is a lightweight, type-safe dependency injection toolkit for Swift. It borrows the best ideas from Android Hilt (components, scopes, modules, and qualifiers) and adapts them for Swift and SwiftUI without code generation.

Highlights
- Type-safe resolution with qualifiers (e.g., `Named("api")`).
- Scopes: `singleton`, `scoped` (per-container), and `transient` lifetimes.
- Hierarchical containers for lifecycle-bound scoping (app -> scene -> view controller -> view).
- Property wrappers: `@Injected` (global) and `@EnvironmentInjected` (SwiftUI).
- Multibindings via `resolveMany` and `contribute` DSL.
- Simple module DSL with `provide {}` and `contribute {}`.

Quick Start
1) Define and register services
```
protocol Api: Sendable {}
final class RealApi: Api {}

let app = Container()
DI.shared = app

app.install {
  provide(Api.self, lifetime: .singleton) { _ in RealApi() }
}
```

2) Inject via property wrappers
```
final class VM {
  @Injected var api: Api
}
```

3) SwiftUI integration
```
import SwiftUI

struct ContentView: View {
  @EnvironmentInjected var api: Api
  var body: some View { Text(String(describing: api)) }
}

@main
struct AppMain: App {
  var body: some Scene {
    WindowGroup {
      ContentView().diContainer(DI.shared)
    }
  }
}
```

4) Scopes and children
```
let app = Container()
let screen = app.child()

app.register(Int.self, lifetime: .singleton) { _ in 1 }
app.register(String.self, lifetime: .scoped) { _ in UUID().uuidString }

let a1 = app.resolve(Int.self)        // same across app
let s1 = screen.resolve(String.self)   // cached per screen container
```

5) Multibindings
```
protocol Middleware {}
struct Log: Middleware {}
struct Metrics: Middleware {}

app.install {
  contribute(Middleware.self) { _ in Log() }
  contribute(Middleware.self) { _ in Metrics() }
}

let all = app.resolveMany(Middleware.self) // [Log(), Metrics()]
```

Design Notes
- Container hierarchy mirrors Hilt’s components; use `child()` to enter a scope and `clearCache()` to release scoped instances.
- `singleton` caches at the provider’s container; `scoped` caches at the resolving container; `transient` never caches.
- Cycle detection triggers a fatal error in debug builds with a human-readable path.
- No build-time code generation; future direction includes Swift 5.9 macros for `@Module`, `@Provides`, and `@Component` ergonomics.

Testing
- Override registrations in a test container and set `DI.shared = testContainer`.
- For SwiftUI, inject the container via `.diContainer(...)` and use `@EnvironmentInjected`.

Roadmap
- Assisted injection/factories with typed arguments.
- Named multibindings with Set semantics.
- Eject/freeze phases for performance and misconfiguration checks.
- Optional macro-based sugar and compile-time graph validation.

Example App
- A macOS SwiftUI demo is included as an executable target: `SwiftHiltDemo`.
- Open the root folder (`Package.swift`) in Xcode, select the `SwiftHiltDemo` scheme, and run on "My Mac".
- See example sources in `Examples/SwiftHiltDemo/`.
- An iOS SwiftUI Xcode project is included: `Examples/SwiftHiltDemo_iOS/SwiftHiltDemo_iOS.xcodeproj`.
- Open it, then File > Add Package Dependencies… > Add Local… and choose the repo root (with `Package.swift`), selecting the `SwiftHilt` product for the app target.
