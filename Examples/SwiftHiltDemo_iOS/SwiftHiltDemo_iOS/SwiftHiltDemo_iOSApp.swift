import SwiftUI
import SwiftHilt

@main
struct SwiftHiltDemo_iOSApp: App {
    init() {
        configureDI()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
