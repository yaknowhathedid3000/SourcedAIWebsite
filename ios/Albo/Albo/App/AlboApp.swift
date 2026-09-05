import SwiftUI

@main
struct AlboApp: App {
    @State private var app = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .preferredColorScheme(app.theme.colorScheme)
                .tint(AlboColor.ink)
                .task(id: app.hasOnboarded) {
                    // Pull the user's library from Supabase once signed in. No-op until
                    // SUPABASE_URL and SUPABASE_ANON_KEY are set in Albo.xcconfig.
                    #if canImport(Supabase)
                    if app.hasOnboarded { SyncEngine.shared.start(app: app) }
                    #endif
                }
        }
    }
}
