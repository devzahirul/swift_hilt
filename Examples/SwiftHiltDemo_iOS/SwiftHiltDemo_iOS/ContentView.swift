import SwiftUI
import SwiftHilt

struct ContentView: View {
    @EnvironmentInjected var api: ApiService
    @State private var message = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("SwiftHilt iOS Demo").font(.title.bold())
                Text(message).font(.body).multilineTextAlignment(.center)
                Divider()
                Button("Fetch Message") { fetch() }
                    .buttonStyle(.borderedProminent)
                Button("Show Middlewares") { showMiddlewares() }
                    .buttonStyle(.bordered)
            }
            .padding()
            .onAppear { fetch() }
            .navigationTitle("Demo")
        }
    }

    private func fetch() { message = api.fetchMessage() }

    private func showMiddlewares() {
        let middlewares: [Middleware] = DI.shared.resolveMany(Middleware.self)
        message = middlewares.reduce("base") { $1.process($0) }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let preview = Container()
        preview.install { provide(ApiService.self) { _ in PreviewApi() } }
        return ContentView().diContainer(preview)
    }

    struct PreviewApi: ApiService { func fetchMessage() -> String { "Hello from Preview (iOS)" } }
}

