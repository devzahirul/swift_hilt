SwiftHiltDemo_iOS (iOS SwiftUI Example)
======================================

This is a minimal iOS SwiftUI app demonstrating how to use the SwiftHilt package in an iOS project.

Open and Run
- Open `Examples/SwiftHiltDemo_iOS/SwiftHiltDemo_iOS.xcodeproj` in Xcode.
- Add the local SwiftHilt package dependency:
  - File > Add Package Dependencies…
  - Click "Add Local…"
  - Select the repository root folder (the one containing `Package.swift`).
  - Choose the `SwiftHilt` product for the `SwiftHiltDemo_iOS` target.
- Select an iOS Simulator and run.

Files
- `SwiftHiltDemo_iOS/SwiftHiltDemo_iOSApp.swift:1`: sets up a DI `Container`, installs modules, and injects via `.diContainer(...)`.
- `SwiftHiltDemo_iOS/ContentView.swift:1`: uses `@EnvironmentInjected` and shows multibindings with `resolveMany`.
- `SwiftHiltDemo_iOS/Info.plist:1`, `Assets.xcassets`: standard app resources.

Notes
- The project does not pre-wire the package dependency to avoid brittle Xcode project metadata. Following the steps above links the local package cleanly.
- iOS deployment target is set to 13.0 to allow SwiftUI + property wrappers.

