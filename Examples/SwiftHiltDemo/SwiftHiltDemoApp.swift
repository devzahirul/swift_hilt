import SwiftUI
import SwiftHilt

// Demo services
protocol ApiService {
    func fetchMessage() -> String
}

final class RealApiService: ApiService {
    func fetchMessage() -> String { "Hello from RealApiService" }
}

protocol Middleware { func process(_ input: String) -> String }
struct LogMiddleware: Middleware { func process(_ input: String) -> String { "[log] " + input } }
struct MetricsMiddleware: Middleware { func process(_ input: String) -> String { input + " [metrics]" } }

// Build the app container and register modules
func makeAppContainer() -> Container {
    let c = Container()
    c.install {
        provide(ApiService.self, lifetime: .singleton) { _ in RealApiService() }
        contribute(Middleware.self) { _ in LogMiddleware() }
        contribute(Middleware.self) { _ in MetricsMiddleware() }
    }
    return c
}

@main
struct SwiftHiltDemoApp: App {
    private let container: Container = {
        let c = makeAppContainer()
        DI.shared = c
        return c
    }()

    var body: some Scene {
        WindowGroup {
            ContentView().diContainer(container)
        }
    }
}

