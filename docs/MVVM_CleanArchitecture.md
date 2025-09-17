MVVM + Clean Architecture (iOS) with SwiftHilt
==============================================

This guide shows a complete iOS setup using MVVM and Clean Architecture with the global SwiftHilt API. It focuses on constructor injection, clear lifetimes, and minimal boilerplate.

1) Domain
---------

- Entities
  - `struct User { let id: String; let name: String }`
- Repository contract
  - `protocol UserRepository { func get(id: String) -> User }`
- Use case
  - ```swift
    struct GetUserUseCase {
      let repo: UserRepository
      init(repo: UserRepository) { self.repo = repo }
      func callAsFunction(_ id: String) -> User { repo.get(id: id) }
    }
    ```

2) Data Layer
-------------

- Infra
  - ```swift
    final class HttpClient {
      func get(_ url: URL) -> [String: Any] { ["id": url.lastPathComponent, "name": "Alice"] }
    }
    ```
- Data sources
  - ```swift
    final class RemoteUserDataSource {
      let client: HttpClient
      let baseURL: URL
      init(client: HttpClient, baseURL: URL) { self.client = client; self.baseURL = baseURL }
      func get(id: String) -> User {
        let j = client.get(baseURL.appendingPathComponent(id))
        return User(id: j["id"] as! String, name: j["name"] as! String)
      }
    }
    ```
  - ```swift
    final class CacheUserDataSource {
      private var store: [String: User] = [:]
      func save(_ u: User) { store[u.id] = u }
      func get(id: String) -> User? { store[id] }
    }
    ```
- Repository impl
  - ```swift
    final class UserRepositoryImpl: UserRepository {
      let remote: RemoteUserDataSource
      let cache: CacheUserDataSource
      init(remote: RemoteUserDataSource, cache: CacheUserDataSource) { self.remote = remote; self.cache = cache }
      func get(id: String) -> User {
        if let u = cache.get(id: id) { return u }
        let u = remote.get(id: id)
        cache.save(u)
        return u
      }
    }
    ```

3) Dependency Graph (App Startup)
---------------------------------

Use the global SwiftHilt API to assemble your graph once during app startup.

```swift
import SwiftHilt

install {
  provide(URL.self, qualifier: Named("prodBase"), lifetime: .singleton) { _ in
    URL(string: "https://api.example.com/user/")!
  }
  provide(HttpClient.self, lifetime: .singleton) { _ in HttpClient() }
}

register(RemoteUserDataSource.self, lifetime: .scoped) { r in
  RemoteUserDataSource(client: r.resolve(HttpClient.self),
                       baseURL: r.resolve(URL.self, qualifier: Named("prodBase")))
}
register(CacheUserDataSource.self, lifetime: .singleton) { _ in CacheUserDataSource() }
register(UserRepository.self, lifetime: .scoped) { r in
  UserRepositoryImpl(remote: r.resolve(RemoteUserDataSource.self),
                     cache: r.resolve(CacheUserDataSource.self))
}
register(GetUserUseCase.self, lifetime: .transient) { r in
  GetUserUseCase(repo: r.resolve(UserRepository.self))
}
```

Lifetimes
- `.singleton` for app‑wide singletons (clients, configs, caches).
- `.scoped` for feature/screen lifetime (each container scope gets its own instance).
- `.transient` when no caching is desired.

4) ViewModel
------------

```swift
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
  @Published var user: User?
  @Published var error: String?

  private let getUser: GetUserUseCase
  init(getUser: GetUserUseCase) { self.getUser = getUser }

  func load(id: String) {
    let u = getUser(id)
    self.user = u
  }
}
```

5) SwiftUI View
---------------

```swift
import SwiftUI
import SwiftHilt

struct HomeView: View {
  @StateObject private var vm = HomeViewModel(getUser: resolve())
  var body: some View {
    VStack(spacing: 12) {
      if let u = vm.user { Text("Hello, \(u.name)") } else { Text("No user loaded").foregroundColor(.secondary) }
      Button("Load User 123") { vm.load(id: "123") }
    }.padding()
  }
}
```

6) App Entry
------------

```swift
import SwiftUI

@main
struct AppMain: App {
  init() {
    // Register dependencies as in step 3 (or call a shared configureDI())
  }
  var body: some Scene { WindowGroup { HomeView() } }
}
```

7) Testing
----------

- Unit: inject fakes into `HomeViewModel` directly (no container).
- Integration: create a test `Container`, register fakes, and `useContainer(testContainer)` to make `resolve()` pick them up.

8) Optional: Observability & Validation
--------------------------------------

- Eagerly validate singletons: `prewarmSingletons()`
- Visualize runtime graph:
  ```swift
  startRecording()
  _ = resolve(GetUserUseCase.self)
  print(exportDOT() ?? "")
  ```

