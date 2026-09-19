import SwiftUI

@main
struct SonderApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                // The app defines all of its own colour, so the system tint is
                // set here rather than through an asset catalog accent colour.
                .tint(.accent)
        }
    }
}
