import SwiftUI

/// Onboarding until finished, then the five-tab shell (teardown 2.1, Albo #56).
struct RootView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        Group {
            if app.hasOnboarded {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingFlow()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: app.hasOnboarded)
        .overlay(alignment: .top) {
            if let toast = app.toast {
                ToastView(message: toast)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

struct MainTabView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        @Bindable var app = app
        ZStack(alignment: .bottom) {
            Group {
                switch app.tab {
                case .library: LibraryView()
                case .map: MapTabView()
                case .add: LibraryView()
                case .community: CommunityView()
                case .profile: ProfileView(user: nil)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                AlboTabBar()
            }
        }
        .background(AlboColor.ground)
        .sheet(isPresented: $app.showAddSheet) {
            AddAnythingSheet()
        }
        .sheet(isPresented: $app.showAskAlbo) {
            AskAlboSheet(scope: nil)
        }
        .sheet(isPresented: $app.showGetStarted) {
            GetStartedSheet()
        }
        .fullScreenCover(isPresented: $app.showPaywall) {
            PaywallView(onDismiss: { app.showPaywall = false })
        }
        .overlay {
            if let streak = app.streakToShow {
                StreakModal(weeks: streak) { app.streakToShow = nil }
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: app.streakToShow)
    }
}

/// House, globe, plus, people, avatar. No labels (Albo #56).
struct AlboTabBar: View {
    @Environment(AppState.self) private var app

    var body: some View {
        HStack {
            tab(.library, "house.fill")
            Spacer()
            tab(.map, "globe.europe.africa.fill")
            Spacer()
            Button {
                app.showAddSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(AlboColor.ink)
                    .frame(width: 56, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add anything")
            Spacer()
            tab(.community, "person.2.fill")
            Spacer()
            Button {
                app.tab = .profile
            } label: {
                AvatarView(user: app.me, size: 34)
                    .overlay(Circle().stroke(AlboColor.ink, lineWidth: app.tab == .profile ? 2 : 0))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Profile")
        }
        .padding(.horizontal, 28)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .background(AlboColor.ground.opacity(0.98))
        .overlay(alignment: .top) { Rectangle().fill(AlboColor.hairline).frame(height: 0.5) }
    }

    private func tab(_ t: AppTab, _ symbol: String) -> some View {
        Button {
            app.tab = t
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 24))
                .foregroundStyle(app.tab == t ? AlboColor.ink : AlboColor.muted)
                .frame(width: 56, height: 44)
        }
        .buttonStyle(.plain)
    }
}

/// Floating Ask Albo button used on Library and detail screens (Albo #56, #69).
struct AskAlboFAB: View {
    let action: () -> Void
    var body: some View {
        FloatingButton(action: action) {
            MascotView().frame(width: 30, height: 30)
        }
        .accessibilityLabel("Ask Albo")
    }
}
