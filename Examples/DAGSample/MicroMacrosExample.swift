import Foundation
import SwiftHilt

// Demonstrates micro macros usage (requires Swift 5.9 toolchain)

// MARK: - Providers via @Module/@Provides

@Module
struct NetworkModule {
    @Provides
    static func httpClient() -> HttpClient { HttpClient() }

    @Provides
    static func baseURL() -> URL { URL(string: "https://api.example.com/user/")! }
}

@Component(modules: [NetworkModule.self])
struct AppComponent {}

// MARK: - Injectable constructors

@Injectable
final class RemoteDataSource2 {
    let client: HttpClient
    let baseURL: URL
    init(client: HttpClient, baseURL: URL) {
        self.client = client
        self.baseURL = baseURL
    }
}

// Usage (commented to avoid duplicate symbol conflicts with main sample):
// let container2 = AppComponent.build()
// container2.register(RemoteDataSource2.self) { r in RemoteDataSource2(resolver: r) }
// let rds = container2.resolve(RemoteDataSource2.self)

