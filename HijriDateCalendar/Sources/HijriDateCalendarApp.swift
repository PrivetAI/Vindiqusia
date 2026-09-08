import SwiftUI

@main
struct HijriDateCalendarApp: App {

    @StateObject private var store = HJStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            HJRootView()
                .environmentObject(store)
                // The palette is literal throughout, and the scheme is pinned, so the app
                // renders identically whatever the device's light/dark setting is.
                .preferredColorScheme(.light)
        }
    }
}
