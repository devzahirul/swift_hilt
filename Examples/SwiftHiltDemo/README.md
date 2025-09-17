SwiftHiltDemo (SwiftUI Example)
==============================

This is a minimal SwiftUI example that demonstrates using SwiftHilt in an app.

Run on macOS (recommended for quick try-out)
- Open the package root in Xcode (File > Open > select the folder containing Package.swift).
- Select the scheme `SwiftHiltDemo` and a "My Mac" destination.
- Run. You should see a simple window with two buttons using injected dependencies.

Files
- `SwiftHiltDemoApp.swift:1` – sets up a `Container`, installs modules, and injects it into the SwiftUI environment.
- `ContentView.swift:1` – uses `@EnvironmentInjected` to get `ApiService` and demonstrates multibindings (`Middleware`).

Notes
- This example is configured as an SPM executable target, so it targets macOS with SwiftUI (`macOS 11+`).
- For iOS, create a new iOS SwiftUI app project and add the `SwiftHilt` package (File > Add Package Dependencies), then copy `SwiftHiltDemoApp.swift` and `ContentView.swift` patterns.

