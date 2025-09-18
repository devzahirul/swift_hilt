import Foundation
import SwiftHilt

// Simple infra
final class HttpClient { func get(_ url: URL) -> [String: Any] { ["msg": "ok", "url": url.absoluteString] } }

// Domain
protocol Greeter { func greet() -> String }

// Data sources and repository
final class RemoteGreeter: Greeter {
    let client: HttpClient
    let baseURL: URL
    init(client: HttpClient, baseURL: URL) { self.client = client; self.baseURL = baseURL }
    func greet() -> String { let j = client.get(baseURL); return "remote(\(j["msg"] as? String ?? ""))" }
}
final class LocalGreeter: Greeter { func greet() -> String { "local" } }

// Multibinding example
protocol Middleware { func process(_ s: String) -> String }
struct Log: Middleware { func process(_ s: String) -> String { "[log] " + s } }
struct Metrics: Middleware { func process(_ s: String) -> String { s + " [m]" } }

// Composition root
let app = Container()
app.install {
    provide(URL.self, qualifier: Named("base")) { _ in URL(string: "https://example.com/api")! }
    provide(HttpClient.self, lifetime: .singleton) { _ in HttpClient() }
}
app.register(Greeter.self) { r in
    RemoteGreeter(client: r.resolve(HttpClient.self), baseURL: r.resolve(URL.self, qualifier: Named("base")))
}
app.registerMany(Middleware.self) { _ in Log() }
app.registerMany(Middleware.self) { _ in Metrics() }

// Use — explicit container
let greeter: Greeter = app.resolve()
var out = greeter.greet()
for mw in app.resolveMany(Middleware.self) { out = mw.process(out) }
print(out)

// Use — global facade (optional)
useContainer(app)
let again: Greeter = resolve()
print("global:", again.greet())

// Record the graph (optional)
if CommandLine.arguments.contains("--dot") {
    app.startRecording(); _ = app.resolve(Greeter.self)
    if let dot = app.exportDOT() { print("\nDOT graph:\n\n\(dot)") }
}

// Task-local environment + @Inject demo
final class Runner: HasResolver {
    let resolver: Resolver
    @Inject var g: Greeter
    init(resolver: Resolver) { self.resolver = resolver }
    func run() { print("injected:", g.greet()) }
}

Injection.with(app) {
    Runner(resolver: app).run()
}

