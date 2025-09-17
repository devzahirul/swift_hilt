import SwiftUI
import SwiftHilt

struct ContentView: View {
    @EnvironmentInjected var api: ApiService
    @Environment(\.diResolver) private var resolver
    @State private var message: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("SwiftHilt Demo").font(.title.bold())
            Text(message).font(.body)
            Divider()
            Button("Fetch Message") { fetch() }
            Button("Show Middlewares") { showMiddlewares() }
                .tint(.secondary)
        }
        .padding(24)
        .onAppear { fetch() }
    }

    private func fetch() {
        message = api.fetchMessage()
    }

    private func showMiddlewares() {
        // Resolve an array via multibindings from the environment resolver
        let middlewares: [Middleware] = resolver.resolveMany(Middleware.self)
        let base = "base"
        let processed = middlewares.reduce(base) { acc, mw in mw.process(acc) }
        message = processed
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // A preview-scoped container with mock bindings
        let preview = Container()
        preview.install {
            provide(ApiService.self) { _ in PreviewApiService() }
        }
        return ContentView().diContainer(preview)
            .previewDisplayName("Preview")
    }

    struct PreviewApiService: ApiService { func fetchMessage() -> String { "Hello from Preview" } }
}
