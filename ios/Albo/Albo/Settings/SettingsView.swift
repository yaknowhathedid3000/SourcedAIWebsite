import SwiftUI
import StoreKit

/// Settings tree (Albo #191 to #206).
struct SettingsView: View {
    @Environment(AppState.self) private var app
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL
    @State private var showSubscription = false
    @State private var showDelete = false
    @State private var confirmSignOut = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionLabel("General")
                NavigationLink { NotificationPrefsView() } label: { SettingsRow(systemImage: "bell", title: "Notifications") }
                NavigationLink { AccountSettingsView() } label: { SettingsRow(systemImage: "person", title: "Account Settings") }
                NavigationLink { LeaderboardView() } label: { SettingsRow(systemImage: "trophy", title: "Leaderboards") }
                Button { showSubscription = true } label: { SettingsRow(systemImage: "crown", title: "Manage Subscription") }
                NavigationLink { AppearanceView() } label: { SettingsRow(systemImage: "paintpalette", title: "Appearance") }
                NavigationLink { LanguageView() } label: { SettingsRow(systemImage: "character.book.closed", title: "Language") }
                NavigationLink { PreferencesView() } label: { SettingsRow(systemImage: "slider.horizontal.3", title: "Preferences") }

                sectionLabel("Resources").padding(.top, 20)
                NavigationLink { AmbassadorView() } label: { SettingsRow(systemImage: "paperplane.fill", title: "Ambassador Program", tint: AlboColor.ink) }
                Button { openURL(URL(string: "https://albo.inc/guides")!) } label: { SettingsRow(systemImage: "square.and.arrow.down", title: "Step by Step Guides", showsChevron: false) }
                Button { showPin = true } label: { SettingsRow(systemImage: "paperplane", title: "Set up Albo shortcut", showsChevron: false) }
                Button { openURL(URL(string: "https://albo.inc")!) } label: { SettingsRow(systemImage: "globe", title: "Albo Web", showsChevron: false) }
                Button { showReferral = true } label: { SettingsRow(systemImage: "ticket", title: "Redeem Referral Code") }
                Button { app.showToast("QR scanning needs the camera on a device") } label: { SettingsRow(systemImage: "qrcode", title: "QR Code Scanner") }

                Group {
                    Button { requestReview() } label: { SettingsRow(systemImage: "star", title: "Give us a rating") }
                    Button { openURL(URL(string: "https://albo.inc")!) } label: { SettingsRow(systemImage: "globe", title: "Our website") }
                    Button { openURL(URL(string: "https://albo.inc/faq")!) } label: { SettingsRow(systemImage: "questionmark", title: "FAQs") }
                    Button { openURL(URL(string: "https://albo.inc/feedback")!) } label: { SettingsRow(systemImage: "wand.and.stars", title: "Request Features") }
                    Button { openURL(URL(string: "mailto:hello@albo.inc")!) } label: { SettingsRow(systemImage: "envelope", title: "Email us any feedback") }
                    Button { openURL(URL(string: "mailto:bugs@albo.inc")!) } label: { SettingsRow(systemImage: "ladybug", title: "Report a bug") }
                    Button { showDelete = true } label: { SettingsRow(systemImage: "person.crop.circle.badge.xmark", title: "Delete Account") }
                    Button { openURL(URL(string: "https://albo.inc/terms")!) } label: { SettingsRow(systemImage: "doc.text", title: "Terms of Service") }
                    Button { openURL(URL(string: "https://albo.inc/privacy")!) } label: { SettingsRow(systemImage: "shield", title: "Privacy Policy") }
                }
                .padding(.top, 20)

                PrimaryButton(title: "Sign Out", style: .danger) { confirmSignOut = true }.padding(.top, 24)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text("User ID:").foregroundStyle(AlboColor.muted)
                        Text(userID).foregroundStyle(AlboColor.ink).lineLimit(1).truncationMode(.middle)
                        Button { UIPasteboard.general.string = userID; app.showToast("Copied") } label: { Image(systemName: "doc.on.doc").foregroundStyle(AlboColor.inkSecondary) }
                    }
                    Text("Version \(version) - Release").foregroundStyle(AlboColor.ink)
                    Text("Made with ❤️ by Isaac, Karolina & Jake - from the feel good project").foregroundStyle(AlboColor.ink)
                }
                .font(.alboSans(16))
                .padding(.top, 20)

                HStack(spacing: 22) {
                    ForEach([("camera", "https://instagram.com/albo"), ("at", "https://threads.net/@albo"), ("music.note", "https://tiktok.com/@albo"), ("xmark", "https://x.com/albo")], id: \.0) { s in
                        Button { openURL(URL(string: s.1)!) } label: {
                            Image(systemName: s.0).font(.system(size: 20)).foregroundStyle(AlboColor.ink).frame(width: 56, height: 56).background(AlboColor.optionFill, in: Circle())
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            }
            .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
        .background(AlboColor.ground)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSubscription) { ManageSubscriptionSheet() }
        .sheet(isPresented: $showDelete) { DeleteAccountSheet() }
        .sheet(isPresented: $showPin) { PinShortcutTutorial() }
        .alert("Redeem Referral Code", isPresented: $showReferral) {
            TextField("Code", text: $referral)
            Button("Redeem") { app.gamification.credits += 100; app.showToast("+100 credits") }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Are you sure you want to sign out?", isPresented: $confirmSignOut) {
            Button("Sign Out", role: .destructive) { app.signOut() }
            Button("Cancel", role: .cancel) {}
        }
    }

    @State private var showPin = false
    @State private var showReferral = false
    @State private var referral = ""

    private var userID: String { (UIDevice.current.identifierForVendor ?? UUID()).uuidString.lowercased() }
    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    private func sectionLabel(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(text).font(.alboSans(20)).foregroundStyle(AlboColor.ink).padding(.top, 20)
            Rectangle().fill(AlboColor.hairline).frame(height: 1)
        }
    }
}

// MARK: - Notification Preferences (Albo #192)

struct NotificationPrefsView: View {
    @Environment(AppState.self) private var app
    var body: some View {
        @Bindable var app = app
        ScrollView {
            VStack(spacing: 0) {
                prefRow("bell.fill", "Enable Notifications", "Enable or disable all notification preferences", $app.notificationPrefs.enabled)
                NavigationLink { LocationNotificationsView() } label: {
                    HStack(spacing: 18) {
                        Image(systemName: "mappin.and.ellipse").font(.system(size: 24)).foregroundStyle(AlboColor.ink).frame(width: 30)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Location Notifications").font(.alboSans(19)).foregroundStyle(AlboColor.ink)
                            Text("Get notified when you're near saved places").font(.alboSans(15)).foregroundStyle(AlboColor.inkSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 15, weight: .semibold)).foregroundStyle(AlboColor.ink)
                    }
                    .padding(.vertical, 22)
                }
                .buttonStyle(.plain)
                Divider()
                prefRow("bell", "Reminders & To-dos", "Get notified about your reminders and to-do items", $app.notificationPrefs.reminders)
                prefRow("person.2", "Friends & Social", "Updates about friends, shares, and social activity", $app.notificationPrefs.social)
                prefRow("megaphone", "Marketing", "Marketing and promotional messages", $app.notificationPrefs.marketing)
            }
            .padding(.horizontal, 20)
        }
        .background(AlboColor.ground)
        .navigationTitle("Notification Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func prefRow(_ symbol: String, _ title: String, _ subtitle: String, _ isOn: Binding<Bool>) -> some View {
        VStack(spacing: 0) {
            Toggle(isOn: isOn) {
                HStack(spacing: 18) {
                    Image(systemName: symbol).font(.system(size: 24)).foregroundStyle(AlboColor.ink).frame(width: 30)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title).font(.alboSans(19)).foregroundStyle(AlboColor.ink)
                        Text(subtitle).font(.alboSans(15)).foregroundStyle(AlboColor.inkSecondary)
                    }
                }
            }
            .tint(AlboColor.rewardGreen)
            .padding(.vertical, 22)
            Divider()
        }
    }
}

// MARK: - Location Notifications (Albo #193, #194)

struct LocationNotificationsView: View {
    @Environment(AppState.self) private var app
    var body: some View {
        @Bindable var app = app
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header("Notifications")
                Toggle(isOn: $app.notificationPrefs.location) {
                    HStack(spacing: 18) {
                        Image(systemName: "mappin.and.ellipse").font(.system(size: 24)).foregroundStyle(AlboColor.ink).frame(width: 30)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enable Notifications").font(.alboSans(19)).foregroundStyle(AlboColor.ink)
                            Text("Get notified near saved places").font(.alboSans(15)).foregroundStyle(AlboColor.inkSecondary)
                        }
                    }
                }
                .tint(AlboColor.rewardGreen)
                .padding(.vertical, 24)
                .onChange(of: app.notificationPrefs.location) { _, on in if on { app.showToast("Location notifications enabled!") } }
                header("How it Works")
                explainer("bell", "Background Notifications", "Get alerted when you're near cafes, restaurants, and other places you've saved - even when the app isn't open.")
                explainer("battery.25percent", "Battery Efficient", "Uses smart location monitoring that only checks when you move significantly, minimizing battery usage.")
                explainer("shield.lefthalf.filled", "Privacy Focused", "Only monitors the 20 closest saved places. No continuous tracking or data sent to servers.")
                header("Permissions")
                HStack(spacing: 18) {
                    Image(systemName: "location").font(.system(size: 24)).foregroundStyle(AlboColor.ink).frame(width: 30)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Location Permission").font(.alboSans(19)).foregroundStyle(AlboColor.ink)
                        Text(app.notificationPrefs.location ? "Always (Required for background notifications)" : "When In Use (Upgrade to \"Always\" for background)").font(.alboSans(15)).foregroundStyle(AlboColor.brandOrange)
                    }
                }
                .padding(.vertical, 24)
                if !app.notificationPrefs.location {
                    PrimaryButton(title: "Upgrade to \"Always\"") { app.notificationPrefs.location = true }.padding(.top, 10)
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 30)
        }
        .background(AlboColor.ground)
        .navigationTitle("Location Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func header(_ t: String) -> some View {
        VStack(alignment: .leading, spacing: 10) { Text(t).font(.alboSans(20)).foregroundStyle(AlboColor.ink).padding(.top, 20); Rectangle().fill(AlboColor.hairline).frame(height: 1) }
    }

    private func explainer(_ symbol: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 18) {
            Image(systemName: symbol).font(.system(size: 24)).foregroundStyle(AlboColor.ink).frame(width: 30).padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.alboSans(19)).foregroundStyle(AlboColor.ink)
                Text(text).font(.alboSans(15)).foregroundStyle(AlboColor.inkSecondary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 18)
    }
}

// MARK: - Account Settings (Albo #176, #177)

struct AccountSettingsView: View {
    @Environment(AppState.self) private var app
    @State private var confirm = false
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 18) {
                Image(systemName: "lock").font(.system(size: 24)).foregroundStyle(AlboColor.ink).frame(width: 30).padding(.top, 2)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Make Account Private").font(.alboSans(19)).foregroundStyle(AlboColor.ink)
                    Text(app.profile.isPrivate ? "Your account is private. Only people you approve can see your profile, collections, and imports." : "Your account is currently public. Anyone can see your posts and others can follow you freely.")
                        .font(.alboSans(15)).foregroundStyle(AlboColor.inkSecondary)
                }
                Spacer()
                Toggle("", isOn: Binding(get: { app.profile.isPrivate }, set: { on in if on { confirm = true } else { var p = app.profile; p.isPrivate = false; app.profile = p } })).labelsHidden().tint(AlboColor.rewardGreen)
            }
            .padding(.vertical, 24)
            Spacer()
        }
        .padding(.horizontal, 20)
        .background(AlboColor.ground)
        .navigationTitle("Account Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Make Account Private?", isPresented: $confirm) {
            Button("Yes, Make Private") { var p = app.profile; p.isPrivate = true; app.profile = p }
            Button("No, Keep Public", role: .cancel) {}
        } message: {
            Text("When your account is private, only people you approve can see your profile, collections, and imports. You can change this at any time.")
        }
    }
}

// MARK: - Appearance (Albo #199 to #201)

struct AppearanceView: View {
    @Environment(AppState.self) private var app
    @State private var iconAlert: String? = nil
    private let icons: [(String, MascotVariant, String?)] = [("Default", .plain, nil), ("Browse", .explorer, "Browse"), ("King", .king, "King"), ("Reads", .reader, "Reads"), ("Cooks", .chef, "Cooks"), ("News", .news, "News")]
    @State private var selectedIcon = "Default"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                label("Theme")
                ForEach(AppTheme.allCases) { t in
                    Button { app.theme = t } label: {
                        HStack(spacing: 18) {
                            Image(systemName: t.systemImage).font(.system(size: 24)).foregroundStyle(AlboColor.ink).frame(width: 30)
                            Text(t.title).font(.alboSans(19)).foregroundStyle(AlboColor.ink)
                            Spacer()
                            if app.theme == t { Image(systemName: "checkmark.circle").font(.system(size: 26)).foregroundStyle(AlboColor.ink) }
                        }
                        .padding(.vertical, 22)
                    }
                    .buttonStyle(.plain)
                }
                label("App Icon").padding(.top, 10)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 22), count: 3), spacing: 22) {
                    ForEach(icons, id: \.0) { icon in
                        Button { select(icon.0, icon.2) } label: {
                            VStack(spacing: 10) {
                                MascotView(variant: icon.1).padding(20).frame(height: 120)
                                    .frame(maxWidth: .infinity)
                                    .background(AlboColor.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(selectedIcon == icon.0 ? AlboColor.ink : AlboColor.hairline, lineWidth: selectedIcon == icon.0 ? 2.5 : 1))
                                Text(icon.0).font(.alboSans(17, weight: selectedIcon == icon.0 ? .bold : .regular)).foregroundStyle(AlboColor.ink)
                            }
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 20).padding(.bottom, 30)
        }
        .background(AlboColor.ground)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { selectedIcon = icons.first { $0.2 == UIApplication.shared.alternateIconName }?.0 ?? "Default" }
        .alert("You have changed the icon for \"Albo\".", isPresented: Binding(get: { iconAlert != nil }, set: { if !$0 { iconAlert = nil } })) {
            Button("OK") {}
        } message: { Text(iconAlert ?? "") }
    }

    private func label(_ t: String) -> some View {
        VStack(alignment: .leading, spacing: 10) { Text(t).font(.alboSans(20)).foregroundStyle(AlboColor.ink).padding(.top, 20); Rectangle().fill(AlboColor.hairline).frame(height: 1) }
    }

    private func select(_ name: String, _ iconName: String?) {
        guard UIApplication.shared.supportsAlternateIcons else { selectedIcon = name; iconAlert = "Alternate icons need the icon assets in the app bundle."; return }
        UIApplication.shared.setAlternateIconName(iconName) { error in
            Task { @MainActor in
                if let error { iconAlert = error.localizedDescription } else { selectedIcon = name; iconAlert = "" }
            }
        }
    }
}

// MARK: - Language (Albo #202)

struct LanguageView: View {
    @Environment(AppState.self) private var app
    @Environment(\.openURL) private var openURL
    private let languages: [(String, String, String)] = [("system", "🌐", "System default"), ("en", "🇬🇧", "English"), ("es", "🇪🇸", "Español"), ("zh-Hans", "🇨🇳", "中文 (简体)"), ("ja", "🇯🇵", "日本語"), ("ko", "🇰🇷", "한국어"), ("de", "🇩🇪", "Deutsch"), ("fr", "🇫🇷", "Français"), ("id", "🇮🇩", "Bahasa Indonesia")]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Change app language").font(.alboSans(20)).foregroundStyle(AlboColor.ink).padding(.top, 20).padding(.bottom, 10)
                Rectangle().fill(AlboColor.hairline).frame(height: 1)
                ForEach(languages, id: \.0) { l in
                    Button { app.languageCode = l.0 } label: {
                        HStack(spacing: 18) {
                            Text(l.1).font(.system(size: 22)).frame(width: 30)
                            Text(l.2).font(.alboSans(19)).foregroundStyle(AlboColor.ink)
                            Spacer()
                            if app.languageCode == l.0 { Image(systemName: "checkmark.circle").font(.system(size: 26)).foregroundStyle(AlboColor.ink) }
                        }
                        .padding(.vertical, 20)
                    }
                    .buttonStyle(.plain)
                }
                Text("Choose your preferred language").font(.alboSans(15)).foregroundStyle(AlboColor.muted).padding(.top, 20)
                SecondaryButton(title: "Want another language?") { openURL(URL(string: "https://albo.inc/feedback")!) }.padding(.top, 12)
            }
            .padding(.horizontal, 20).padding(.bottom, 30)
        }
        .background(AlboColor.ground)
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preferences (Albo #203)

struct PreferencesView: View {
    @Environment(AppState.self) private var app
    @State private var placesEnabled = true
    @State private var placesOnProfile = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header("Default Map for Directions")
                ForEach(MapApp.allCases) { m in
                    Button { app.defaultMap = m } label: {
                        HStack(spacing: 18) {
                            Image(systemName: m == .apple ? "apple.logo" : "g.circle").font(.system(size: 24)).foregroundStyle(AlboColor.ink).frame(width: 30)
                            Text(m.title).font(.alboSans(19)).foregroundStyle(AlboColor.ink)
                            Spacer()
                            if app.defaultMap == m { Image(systemName: "checkmark.circle.fill").font(.system(size: 26)).foregroundStyle(AlboColor.ink) }
                        }
                        .padding(.vertical, 26)
                    }
                    .buttonStyle(.plain)
                }
                header("Default Reminder Time")
                ForEach(ReminderSlot.allCases) { s in
                    Button { app.defaultReminderSlot = s } label: {
                        HStack(spacing: 18) {
                            Image(systemName: slotSymbol(s)).font(.system(size: 24)).foregroundStyle(AlboColor.ink).frame(width: 30)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(s.title).font(.alboSans(19)).foregroundStyle(AlboColor.ink)
                                Text(s.timeLabel).font(.alboSans(15)).foregroundStyle(AlboColor.inkSecondary)
                            }
                            Spacer()
                            if app.defaultReminderSlot == s { Image(systemName: "checkmark.circle.fill").font(.system(size: 26)).foregroundStyle(AlboColor.ink) }
                        }
                        .padding(.vertical, 22)
                    }
                    .buttonStyle(.plain)
                }
                header("Places")
                toggleRow("checkmark.circle.fill", "Enabled", "Enabled in filters and profile", $placesEnabled)
                toggleRow("eye", "Show in profile", "Visible on your profile", $placesOnProfile)
            }
            .padding(.horizontal, 20).padding(.bottom, 30)
        }
        .background(AlboColor.ground)
        .navigationTitle("Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func slotSymbol(_ s: ReminderSlot) -> String {
        switch s {
        case .morning: return "sunrise"
        case .afternoon: return "sun.max"
        case .evening: return "sunset"
        case .beforeBed: return "moon"
        }
    }

    private func header(_ t: String) -> some View {
        VStack(alignment: .leading, spacing: 10) { Text(t).font(.alboSans(20)).foregroundStyle(AlboColor.ink).padding(.top, 20); Rectangle().fill(AlboColor.hairline).frame(height: 1) }
    }

    private func toggleRow(_ symbol: String, _ title: String, _ subtitle: String, _ isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 18) {
                Image(systemName: symbol).font(.system(size: 24)).foregroundStyle(AlboColor.ink).frame(width: 30)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.alboSans(19)).foregroundStyle(AlboColor.ink)
                    Text(subtitle).font(.alboSans(15)).foregroundStyle(AlboColor.inkSecondary)
                }
            }
        }
        .tint(AlboColor.rewardGreen)
        .padding(.vertical, 22)
    }
}

// MARK: - Delete Account (Albo #205)

struct DeleteAccountSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var reason: String? = nil
    @State private var details = ""
    private let reasons = ["I don't use it enough", "Too expensive", "Missing a feature I need", "Privacy concerns", "Found a better app", "Other"]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule().fill(AlboColor.hairline).frame(width: 40, height: 5).frame(maxWidth: .infinity).padding(.top, 8)
            Text("Delete Account").font(.alboSans(30, weight: .bold)).foregroundStyle(AlboColor.ink).padding(.top, 10)
            Text("We're sorry to see you go. Please let us know why you're leaving.").font(.alboSans(17)).foregroundStyle(AlboColor.inkSecondary)
            Text("After you confirm, your account will be deleted within the next 14 days.").font(.alboSans(17)).foregroundStyle(AlboColor.inkSecondary)
            Text("Reason for leaving").font(.alboSans(17, weight: .medium)).foregroundStyle(AlboColor.ink).padding(.top, 6)
            Menu {
                ForEach(reasons, id: \.self) { r in Button(r) { reason = r } }
            } label: {
                HStack {
                    Text(reason ?? "Select a reason").font(.alboSans(18)).foregroundStyle(reason == nil ? AlboColor.muted : AlboColor.ink)
                    Spacer()
                    Image(systemName: "chevron.down").font(.system(size: 16, weight: .semibold)).foregroundStyle(AlboColor.ink)
                }
                .padding(.horizontal, 20).frame(height: 62).background(AlboColor.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            Text("Additional details (optional)").font(.alboSans(17, weight: .medium)).foregroundStyle(AlboColor.ink)
            CountedTextArea(placeholder: "Please provide any additional context that might help us improve...", text: $details, limit: 500)
            Spacer(minLength: 0)
            PrimaryButton(title: "Confirm Deletion", style: .danger, isEnabled: reason != nil) {
                app.resetForDeletion()
                dismiss()
            }
            SecondaryButton(title: "Cancel") { dismiss() }
        }
        .padding(.horizontal, 24).padding(.bottom, 12)
        .background(AlboColor.card)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
}
