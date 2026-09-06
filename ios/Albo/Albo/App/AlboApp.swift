import SwiftUI

@main
struct AlboApp: App {
    @State private var app = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .preferredColorScheme(app.theme.colorScheme)
                .tint(AlboColor.ink)
                .onChange(of: scenePhase) { _, phase in
                    // Anything sent from another app's share sheet while we were away.
                    guard phase == .active, app.hasOnboarded else { return }
                    Task { await ShareInboxImporter.drain(into: app) }
                }
                .task(id: app.hasOnboarded) {
                    // Pull the user's library from Supabase once signed in. No-op until
                    // SUPABASE_URL and SUPABASE_ANON_KEY are set in Albo.xcconfig.
                    #if canImport(Supabase)
                    if app.hasOnboarded { SyncEngine.shared.start(app: app) }
                    #endif
                    if app.hasOnboarded { await ShareInboxImporter.drain(into: app) }
                }
        }
    }
}
