import SwiftUI

enum ProfileRoute: Hashable {
    case settings, calendar, stamps, leaderboard, addFriends, editProfile, save(UUID), collection(UUID), user(UserSummary)
}

/// Own profile (Albo #171, #185 to #190) and public profile (Albo #158 to #160).
struct ProfileView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let user: UserSummary?
    @State private var path = NavigationPath()
    @State private var tab: Tab = .collections
    @State private var sort: JournalSort = .timeline
    @State private var showCard = false
    @State private var showLinks = false

    enum Tab: Hashable { case collections, category(SaveCategory) }
    enum JournalSort: String, CaseIterable, Identifiable { case timeline, rating; var id: String { rawValue }; var title: String { rawValue.capitalized } }

    private var isMe: Bool { user == nil }
    private var summary: UserSummary { user ?? app.me }
    private var saveCount: Int { isMe ? app.saves.count : 7 }
    private var tabs: [Tab] { [.collections] + SaveCategory.browsable.map { Tab.category($0) } }

    var body: some View {
        Group {
            if isMe {
                NavigationStack(path: $path) { content.navigationDestination(for: ProfileRoute.self, destination: destination) }
            } else {
                content
            }
        }
    }

    @ViewBuilder
    private func destination(_ r: ProfileRoute) -> some View {
        switch r {
        case .settings: SettingsView()
        case .calendar: CalendarView()
        case .stamps: StampsView()
        case .leaderboard: LeaderboardView()
        case .addFriends: AddFriendsView()
        case .editProfile: EditProfileView()
        case .save(let id): SaveDetailView(saveID: id)
        case .collection(let id): CollectionDetailView(collectionID: id)
        case .user(let u): ProfileView(user: u)
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                topRow
                header
                tabBar
                tabContent
            }
            .padding(.bottom, 100)
        }
        .background(AlboColor.ground)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showCard) { ProfileCardSheet(user: summary, collections: isMe ? app.collections.count : 0, saves: saveCount, country: isMe ? app.profile.country : "United States") }
        .sheet(isPresented: $showLinks) { AddLinksSheet() }
        .sheet(isPresented: $showNewCollection) { NewCollectionFlow(firstSave: nil) }
    }

    private var topRow: some View {
        HStack {
            if isMe {
                Button { path.append(ProfileRoute.calendar) } label: { Image(systemName: "calendar").font(.system(size: 26)).foregroundStyle(AlboColor.ink) }.accessibilityLabel("Calendar")
                Spacer()
                Button { path.append(ProfileRoute.settings) } label: { Image(systemName: "gearshape").font(.system(size: 26)).foregroundStyle(AlboColor.ink) }.accessibilityLabel("Settings")
            } else {
                Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 22, weight: .semibold)).foregroundStyle(AlboColor.ink) }
                Spacer()
                Button { showCard = true } label: { Image(systemName: "square.and.arrow.up").font(.system(size: 22)).foregroundStyle(AlboColor.ink) }.padding(.trailing, 20)
                Menu { Button("Block", role: .destructive) {}; Button("Report", role: .destructive) {} } label: { Image(systemName: "ellipsis").font(.system(size: 22, weight: .bold)).foregroundStyle(AlboColor.ink) }
            }
        }
        .padding(.horizontal, 20).padding(.top, 8)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.name).font(.alboDisplay(40)).foregroundStyle(AlboColor.ink)
                    Text(summary.handle).font(.alboSans(18)).foregroundStyle(AlboColor.inkSecondary)
                }
                Spacer()
                VStack(spacing: -12) {
                    AvatarView(user: summary, size: 84)
                    if isMe {
                        Text(joinedLabel).font(.alboSans(15, weight: .semibold)).foregroundStyle(AlboColor.ink).padding(.horizontal, 12).frame(height: 30).background(AlboColor.optionFill, in: Capsule())
                    }
                }
            }
            if isMe {
                if app.profile.instagram.isEmpty && app.profile.tiktok.isEmpty {
                    Button { showLinks = true } label: {
                        HStack(spacing: 8) { Image(systemName: "link"); Text("Add links") }.font(.alboSans(16, weight: .medium)).foregroundStyle(AlboColor.ink)
                            .padding(.horizontal, 16).frame(height: 44).background(Capsule().stroke(AlboColor.hairline, lineWidth: 1.5))
                    }
                    .buttonStyle(PressableButtonStyle())
                } else {
                    HStack(spacing: 14) {
                        if !app.profile.instagram.isEmpty { HStack(spacing: 6) { Image(systemName: "camera"); Text(app.profile.instagram) } }
                        if !app.profile.tiktok.isEmpty { HStack(spacing: 6) { Image(systemName: "music.note"); Text(app.profile.tiktok) } }
                    }
                    .font(.alboSans(16)).foregroundStyle(AlboColor.inkSecondary)
                    .onTapGesture { showLinks = true }
                }
            } else {
                Text("1 common save").font(.alboSans(17, weight: .medium)).foregroundStyle(Color(hex: 0x3B5BDB))
                    .padding(.horizontal, 20).frame(height: 44).background(Capsule().stroke(AlboColor.hairline, lineWidth: 1.5))
            }
            HStack(spacing: 8) {
                if isMe { AvatarView(user: SampleData.kimmy, size: 22) }
                Text("\(isMe ? app.profile.followers : 1) Followers · \(isMe ? app.following.count : 0) Following · \(saveCount) Saves").font(.alboSans(17)).foregroundStyle(AlboColor.inkSecondary)
            }
            if isMe {
                HStack(spacing: 12) {
                    OutlinePill(title: "Edit Profile", expands: true) { path.append(ProfileRoute.editProfile) }
                    OutlinePill(title: "Share", expands: true) { showCard = true }
                    OutlinePill(title: "", systemImage: "person.badge.plus") { path.append(ProfileRoute.addFriends) }
                        .accessibilityLabel("Add friends")
                }
            } else {
                FollowButton(isFollowing: app.isFollowing(summary), expands: true) { app.toggleFollow(summary) }
            }
        }
        .padding(.horizontal, 20)
    }

    private var joinedLabel: String {
        let weeks = max(1, Calendar.current.dateComponents([.weekOfYear], from: app.profile.joinedAt, to: Date()).weekOfYear ?? 1)
        return weeks < 5 ? "\(weeks) wk" : "\(weeks / 4) mo"
    }

    private var tabBar: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 28) {
                    ForEach(tabs, id: \.self) { t in
                        let title: String = {
                            switch t {
                            case .collections: return "Collections"
                            case .category(let c): return "\(c.pluralTitle) (\(isMe ? app.saves(in: c).count : (c == .recipe ? 1 : 0)))"
                            }
                        }()
                        Button { withAnimation(.easeInOut(duration: 0.2)) { tab = t } } label: {
                            VStack(spacing: 10) {
                                Text(title).font(tab == t ? .alboDisplay(20) : .alboDisplayItalic(20, weight: .semibold)).foregroundStyle(tab == t ? AlboColor.ink : AlboColor.muted)
                                Rectangle().fill(tab == t ? AlboColor.ink : .clear).frame(height: 4)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            Rectangle().fill(AlboColor.hairline).frame(height: 1)
        }
        .padding(.top, 6)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch tab {
        case .collections:
            VStack(alignment: .leading, spacing: 18) {
                if isMe {
                    Button { app.showAddSheet = false; showNewCollection = true } label: {
                        HStack(spacing: 10) { Image(systemName: "plus.circle").font(.system(size: 22)); Text("Create new collection").font(.alboSans(18, weight: .semibold)) }
                            .foregroundStyle(AlboColor.ink).frame(maxWidth: .infinity).frame(height: 62).background(AlboColor.optionFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(PressableButtonStyle())
                    ForEach(app.collections) { c in
                        Button { path.append(ProfileRoute.collection(c.id)) } label: { CollectionRow(collection: c) }.buttonStyle(PressableButtonStyle())
                    }
                } else {
                    EmptyStateView(systemImage: "folder.fill", title: "No public collections").padding(.top, 80)
                }
            }
            .padding(20)
        case .category(let c):
            categoryContent(c)
        }
    }

    @State private var showNewCollection = false

    @ViewBuilder
    private func categoryContent(_ c: SaveCategory) -> some View {
        let wants = isMe ? app.saves(in: c).filter { $0.status == .wantTo } : []
        let journal = isMe ? app.journal(for: c) : []
        let lists = isMe ? app.lists.filter { $0.category == c } : (c == .recipe ? [CuratedList(category: .recipe, title: "Recipes", owner: SampleData.kimmy, coverEmoji: "🍲")] : [])
        VStack(alignment: .leading, spacing: 22) {
            if isMe {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recommendations").font(.alboSans(20, weight: .bold)).foregroundStyle(AlboColor.ink)
                    Text("\(c.pluralTitle) rated 4 stars or above").font(.alboSans(15)).foregroundStyle(AlboColor.muted)
                    HStack(spacing: -30) {
                        ForEach(0..<2, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 8).fill(AlboColor.card).frame(width: 110, height: 140).overlay(Image(systemName: "photo").foregroundStyle(AlboColor.hairline)).shadow(color: .black.opacity(0.1), radius: 8, y: 4).rotationEffect(.degrees(i == 0 ? -8 : 6))
                        }
                    }
                    .padding(.top, 6)
                }
                .padding(18).frame(maxWidth: .infinity, alignment: .leading).background(AlboColor.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            if !wants.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) { Image(systemName: "megaphone.fill"); Text(c.wantsSectionTitle).font(.alboSans(20, weight: .bold)); Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)) }.foregroundStyle(AlboColor.ink)
                    ForEach(wants) { s in
                        Button { path.append(ProfileRoute.save(s.id)) } label: {
                            HStack(spacing: 14) {
                                SaveCover(save: s, cornerRadius: 8).frame(width: 56, height: 74)
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) { Text(s.title).font(.alboSans(18, weight: .bold)).foregroundStyle(AlboColor.ink).lineLimit(1); Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(AlboColor.ink) }
                                    Text(s.metaLine).font(.alboSans(15)).foregroundStyle(AlboColor.inkSecondary).lineLimit(1)
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
            }
            if !lists.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Lists").font(.alboSans(20, weight: .bold)).foregroundStyle(AlboColor.ink)
                    ForEach(lists) { l in
                        HStack(spacing: 14) {
                            RoundedRectangle(cornerRadius: 12).fill(AlboColor.optionFill).frame(width: 84, height: 84).overlay(Text(l.coverEmoji).font(.system(size: 36)))
                            VStack(alignment: .leading, spacing: 6) {
                                Text(l.title).font(.alboSans(20, weight: .bold)).foregroundStyle(AlboColor.ink)
                                HStack(spacing: 6) { Image(systemName: "list.number"); AvatarView(user: l.owner, size: 22) }.foregroundStyle(AlboColor.inkSecondary)
                            }
                            Spacer()
                            Image(systemName: "plus.circle").font(.system(size: 24)).foregroundStyle(AlboColor.ink)
                        }
                    }
                }
            }
            if isMe {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Journal").font(.alboSans(24, weight: .bold)).foregroundStyle(AlboColor.ink)
                        Spacer()
                        Menu {
                            ForEach(JournalSort.allCases) { s in Button(s.title) { sort = s } }
                        } label: {
                            HStack(spacing: 8) { Image(systemName: "arrow.up.arrow.down"); Text(sort.title); Image(systemName: "chevron.down").font(.system(size: 12, weight: .semibold)) }
                                .font(.alboSans(17, weight: .semibold)).foregroundStyle(AlboColor.ink).padding(.horizontal, 16).frame(height: 44).background(AlboColor.optionFill, in: Capsule())
                        }
                    }
                    let sorted = sort == .timeline ? journal : journal.sorted { ($0.stars ?? 0) > ($1.stars ?? 0) }
                    if sorted.isEmpty {
                        Text("Mark a \(c.title.lowercased()) as \(c.doneTab.lowercased()) and it will show up here.").font(.alboSans(15)).foregroundStyle(AlboColor.muted)
                    }
                    ForEach(sorted) { r in
                        if let s = app.save(r.saveID) {
                            Button { path.append(ProfileRoute.save(s.id)) } label: { JournalCard(review: r, save: s) }.buttonStyle(PressableButtonStyle())
                        }
                    }
                }
            }
        }
        .padding(20)
    }
}

/// Journal entry: italic serif sentence, stars, date, note, photo (Albo #186).
struct JournalCard: View {
    let review: Review
    let save: Save
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            SaveCover(save: save, cornerRadius: 6).frame(width: 60, height: 80).padding(4).background(AlboColor.card).shadow(color: .black.opacity(0.1), radius: 6, y: 3)
            VStack(alignment: .leading, spacing: 8) {
                Text("\(save.category.journalVerb) \(save.title), \(review.sentiment.journalSuffix)").font(.alboDisplayItalic(19, weight: .regular)).foregroundStyle(AlboColor.ink).multilineTextAlignment(.leading)
                Rectangle().fill(AlboColor.hairline).frame(height: 1)
                HStack {
                    StaticStars(rating: review.stars ?? 0, color: AlboColor.ink, size: 16)
                    Spacer()
                    if let d = review.completedOn { Text(d, format: .dateTime.day().month(.abbreviated)).font(.alboSans(15)).foregroundStyle(AlboColor.inkSecondary) }
                }
                if let t = review.title { Text(t).font(.alboSans(17)).foregroundStyle(AlboColor.inkSecondary) }
                if review.photoCount > 0 {
                    RoundedRectangle(cornerRadius: 12).fill(Color(hex: save.coverTint)).frame(width: 130, height: 150).overlay(Text(save.coverEmoji ?? "📷").font(.system(size: 40)))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AlboColor.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

/// Share card modal (Albo #160, #178).
struct ProfileCardSheet: View {
    @Environment(\.dismiss) private var dismiss
    let user: UserSummary
    let collections: Int
    let saves: Int
    let country: String
    var body: some View {
        VStack(spacing: 18) {
            Capsule().fill(AlboColor.hairline).frame(width: 40, height: 5).padding(.top, 8)
            AvatarView(user: user, size: 110).padding(.top, 10)
            Text(user.name).font(.alboDisplay(30)).foregroundStyle(AlboColor.ink)
            Text(country).font(.alboSans(16)).foregroundStyle(AlboColor.inkSecondary)
            HStack(spacing: 40) {
                VStack { Text("\(collections)").font(.alboSans(28, weight: .bold)); Text("Collections").font(.alboSans(14)).foregroundStyle(AlboColor.muted) }
                VStack { Text("\(saves)").font(.alboSans(28, weight: .bold)); Text("Saves").font(.alboSans(14)).foregroundStyle(AlboColor.muted) }
            }
            .foregroundStyle(AlboColor.ink)
            HStack(spacing: 6) { Text("New to Albo").font(.alboSans(15, weight: .semibold)); Text("on Albo").font(.alboSans(15)).foregroundStyle(AlboColor.muted); MascotView().frame(width: 18) }
            HStack(spacing: 12) {
                SecondaryButton(title: "Copy Link") { UIPasteboard.general.string = "https://albo.inc/@\(user.handle)" }
                ShareLink(item: URL(string: "https://albo.inc/@\(user.handle)")!) {
                    ZStack { Capsule().fill(Color.black).offset(y: 5); Capsule().fill(AlboColor.ink); Text("Share").font(.alboSans(17, weight: .semibold)).foregroundStyle(.white) }.frame(height: 54).frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 24).padding(.bottom, 12)
        .presentationDetents([.medium])
    }
}

/// "Add your links" (Albo #173).
struct AddLinksSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var instagram = ""
    @State private var tiktok = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule().fill(AlboColor.hairline).frame(width: 40, height: 5).frame(maxWidth: .infinity).padding(.top, 8)
            Text("Add your links").font(.alboSans(24, weight: .bold)).foregroundStyle(AlboColor.ink)
            Text("Show your Instagram and TikTok on your profile.").font(.alboSans(16)).foregroundStyle(AlboColor.inkSecondary)
            IconField(systemImage: "camera", placeholder: "Instagram handle", text: $instagram)
            IconField(systemImage: "music.note", placeholder: "TikTok handle", text: $tiktok)
            PrimaryButton(title: "Save") {
                var p = app.profile; p.instagram = instagram; p.tiktok = tiktok; app.profile = p
                dismiss()
            }
        }
        .padding(.horizontal, 24).padding(.bottom, 12)
        .presentationDetents([.medium])
        .onAppear { instagram = app.profile.instagram; tiktok = app.profile.tiktok }
    }
}

// MARK: - Edit Profile (Albo #174, #175)

struct EditProfileView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var draft = UserProfile()
    @State private var path = NavigationPath()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: { Image(systemName: "arrow.left").font(.system(size: 22, weight: .medium)).foregroundStyle(AlboColor.ink).frame(width: 40, height: 40) }.buttonStyle(.plain)
                Spacer()
                Text("Edit Profile").font(.alboSans(20, weight: .bold)).foregroundStyle(AlboColor.ink)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, 12)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ZStack(alignment: .bottomTrailing) {
                        AvatarView(user: draft.summary, size: 130)
                        Menu {
                            ForEach(MascotVariant.allCases, id: \.self) { v in Button(v.rawValue.capitalized) { draft.mascot = v } }
                        } label: {
                            Image(systemName: "camera.fill").font(.system(size: 16)).foregroundStyle(.white).frame(width: 36, height: 36).background(AlboColor.ink, in: Circle()).overlay(Circle().stroke(AlboColor.ground, lineWidth: 3))
                        }
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 20)
                    Text("Account Information").font(.alboSans(17, weight: .bold)).foregroundStyle(AlboColor.ink).padding(.top, 8)
                    IconField(systemImage: "envelope", placeholder: "Email", text: $draft.email, disabled: true)
                    IconField(systemImage: "at", placeholder: "Username", text: $draft.handle)
                    Text("Personal Information").font(.alboSans(17, weight: .bold)).foregroundStyle(AlboColor.ink).padding(.top, 18)
                    IconField(systemImage: "person", placeholder: "Name", text: $draft.name)
                    CountedTextArea(placeholder: "Tell us about yourself...", text: $draft.bio, limit: 500, minHeight: 130)
                    IconField(systemImage: "camera", placeholder: "Instagram handle", text: $draft.instagram)
                    IconField(systemImage: "music.note", placeholder: "TikTok handle", text: $draft.tiktok)
                    Menu {
                        ForEach(["Philippines", "United States", "United Kingdom", "Germany", "Japan"], id: \.self) { c in Button(c) { draft.country = c } }
                    } label: { selectorRow("globe", draft.country) }
                    Button { app.showToast("Home cities arrive with the places backend") } label: { selectorRow("building.2", draft.homeCities.isEmpty ? "Tap to select your home cities" : draft.homeCities.joined(separator: ", ")) }.buttonStyle(.plain)
                    NavigationLink(value: "ambassador") { SettingsRow(systemImage: "paperplane.fill", title: "Ambassador Program") }.buttonStyle(.plain)
                    NavigationLink(value: "account") { SettingsRow(systemImage: "person.crop.circle", title: "Account Settings") }.buttonStyle(.plain)
                }
                .padding(.horizontal, 20).padding(.bottom, 24)
            }
            PrimaryButton(title: "Save Changes") {
                app.profile = draft
                app.showToast("Profile saved")
                dismiss()
            }
            .padding(.horizontal, 24)
        }
        .background(AlboColor.ground)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: String.self) { key in
            if key == "account" { AccountSettingsView() } else { AmbassadorView() }
        }
        .onAppear { draft = app.profile }
    }

    private func selectorRow(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.system(size: 20)).foregroundStyle(AlboColor.inkSecondary).frame(width: 26)
            Text(text).font(.alboSans(18)).foregroundStyle(AlboColor.ink)
            Spacer()
            Image(systemName: "chevron.down").font(.system(size: 14, weight: .semibold)).foregroundStyle(AlboColor.inkSecondary)
        }
        .padding(.horizontal, 18).frame(height: 60)
        .background(AlboColor.optionFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct AmbassadorView: View {
    var body: some View {
        VStack(spacing: 20) {
            MascotView(variant: .rocket).frame(width: 160).rotationEffect(.degrees(-20)).padding(.top, 40)
            Text("Ambassador Program").alboText(.sheetTitle)
            Text(orphanSafe: "Earn 100 credits for every friend who joins with your link, plus early access to new features.").font(.alboSans(17)).foregroundStyle(AlboColor.inkSecondary).multilineTextAlignment(.center).padding(.horizontal, 24)
            ShareLink(item: URL(string: "https://join.albo.inc/ambassador")!) {
                ZStack { Capsule().fill(Color.black).offset(y: 5); Capsule().fill(AlboColor.ink); Text("Share my invite link").font(.alboSans(18, weight: .semibold)).foregroundStyle(.white) }.frame(height: 58).frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
            Spacer()
        }
        .background(AlboColor.ground)
        .navigationTitle("Ambassador Program")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Calendar (Albo #172)

struct CalendarView: View {
    @Environment(AppState.self) private var app
    private let cal = Calendar.current

    private var months: [Date] {
        let start = cal.date(from: cal.dateComponents([.year, .month], from: Date())) ?? Date()
        return (-1...1).compactMap { cal.date(byAdding: .month, value: $0, to: start) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                ForEach(months, id: \.self) { m in monthView(m) }
            }
            .padding(20)
        }
        .background(AlboColor.ground)
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func monthView(_ month: Date) -> some View {
        let isFuture = month > Date()
        let days = cal.range(of: .day, in: .month, for: month)?.count ?? 30
        let firstWeekday = (cal.component(.weekday, from: month) + 5) % 7 // Monday = 0
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
        return VStack(alignment: .leading, spacing: 14) {
            (Text(month, format: .dateTime.month(.wide)).fontWeight(.bold).foregroundStyle(isFuture ? AlboColor.muted : AlboColor.ink) + Text(" ") + Text(month, format: .dateTime.year()).foregroundStyle(AlboColor.muted))
                .font(.alboSans(30))
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(["M", "T", "W", "T", "F", "S", "S"].indices, id: \.self) { i in
                    Text(["M", "T", "W", "T", "F", "S", "S"][i]).font(.alboSans(15)).foregroundStyle(AlboColor.muted)
                }
                ForEach(0..<firstWeekday, id: \.self) { _ in Color.clear.frame(height: 56) }
                ForEach(1...days, id: \.self) { d in
                    let date = cal.date(byAdding: .day, value: d - 1, to: month) ?? month
                    let review = app.reviews.first { r in r.completedOn.map { cal.isDate($0, inSameDayAs: date) } ?? false }
                    let past = date <= Date()
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous).fill(AlboColor.optionFill.opacity(past ? 1 : 0.5))
                        if let review, let s = app.save(review.saveID) {
                            RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(hex: s.coverTint)).overlay(Text(s.coverEmoji ?? "🍽️").font(.system(size: 22)).opacity(0.7))
                        }
                        Text("\(d)").font(.alboSans(17, weight: review != nil ? .bold : .regular)).foregroundStyle(review != nil ? .white : (past ? AlboColor.ink : AlboColor.muted)).shadow(color: review != nil ? .black.opacity(0.5) : .clear, radius: 2)
                    }
                    .frame(height: 56)
                }
            }
        }
        .opacity(isFuture ? 0.45 : 1)
    }
}

// MARK: - Stamps (Albo #183, #184)

struct StampsView: View {
    @Environment(AppState.self) private var app
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                ForEach(app.gamification.stamps) { s in
                    NavigationLink { StampDetailView(stamp: s) } label: {
                        VStack(spacing: 10) {
                            ZStack {
                                Circle().fill(AlboColor.optionFill).frame(width: 130, height: 130)
                                Text(s.isUnlocked ? "👑" : "?").font(.system(size: s.isUnlocked ? 60 : 54, weight: .medium)).foregroundStyle(AlboColor.muted)
                            }
                            Text(s.isUnlocked ? "Unlocked" : "Locked").font(.alboSans(18, weight: .bold)).foregroundStyle(AlboColor.ink)
                            Text(s.title).font(.alboSans(15)).foregroundStyle(AlboColor.inkSecondary)
                            Capsule().fill(AlboColor.optionFill).frame(width: 120, height: 6).overlay(alignment: .leading) { Capsule().fill(AlboColor.ink).frame(width: 120 * CGFloat(s.progress) / CGFloat(max(1, s.target))) }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 30)
        }
        .background(AlboColor.ground)
        .navigationTitle("Stamps")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StampDetailView: View {
    let stamp: Stamp
    var body: some View {
        VStack(spacing: 14) {
            ZStack { Circle().fill(AlboColor.optionFill).frame(width: 160, height: 160); Text(stamp.isUnlocked ? "👑" : "?").font(.system(size: 64, weight: .medium)).foregroundStyle(AlboColor.muted) }.padding(.top, 40)
            Text(stamp.title).font(.alboSans(26, weight: .bold)).foregroundStyle(AlboColor.ink)
            HStack(spacing: 6) { Image(systemName: stamp.isUnlocked ? "lock.open" : "lock"); Text(stamp.isUnlocked ? "Unlocked" : "Locked") }.font(.alboSans(16)).foregroundStyle(AlboColor.inkSecondary)
            Text(stamp.subtitle).font(.alboSans(16)).foregroundStyle(AlboColor.inkSecondary)
            VStack(spacing: 8) {
                HStack { Text(stamp.goalLabel).font(.alboSans(16)); Spacer(); Text("\(stamp.progress) / \(stamp.target)").font(.alboSans(16, weight: .semibold)).monospacedDigit() }.foregroundStyle(AlboColor.ink)
                GeometryReader { geo in ZStack(alignment: .leading) { Capsule().fill(AlboColor.optionFill); Capsule().fill(AlboColor.ink).frame(width: geo.size.width * CGFloat(stamp.progress) / CGFloat(max(1, stamp.target))) } }.frame(height: 8)
            }
            .padding(.horizontal, 32).padding(.top, 20)
            Spacer()
        }
        .background(AlboColor.ground)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Leaderboard (Albo #196, #197)

struct LeaderboardView: View {
    @Environment(AppState.self) private var app
    @State private var board = 0
    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 0) {
                segment("Hoarders", 0)
                segment("Yappers", 1)
            }
            .background(Capsule().stroke(AlboColor.ink, lineWidth: 1.5))
            .padding(.horizontal, 20).padding(.top, 14)
            ScrollView {
                VStack(spacing: 0) {
                    row(rank: board == 0 ? 117455 : 62, user: app.me, count: board == 0 ? app.saves.count : app.reviews.count, isMe: true)
                    ForEach(board == 0 ? SampleData.hoarders : SampleData.yappers) { e in
                        row(rank: e.rank, user: e.user, count: e.count, isMe: false)
                    }
                }
            }
        }
        .background(AlboColor.ground)
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func segment(_ title: String, _ i: Int) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.2)) { board = i } } label: {
            Text(title).font(.alboSans(18, weight: .medium)).foregroundStyle(AlboColor.ink).frame(maxWidth: .infinity).frame(height: 50)
                .background(board == i ? AlboColor.optionFill : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func rankColor(_ r: Int) -> Color {
        switch r {
        case 1: return Color(hex: 0xE5A800)
        case 2: return Color(hex: 0x9E9E9E)
        case 3: return Color(hex: 0xB87333)
        default: return AlboColor.ink
        }
    }

    private func row(rank: Int, user: UserSummary, count: Int, isMe: Bool) -> some View {
        HStack(spacing: 16) {
            Text("#\(rank)").font(.alboSans(20, weight: .bold)).foregroundStyle(rankColor(rank)).frame(width: 74, alignment: .leading).monospacedDigit().minimumScaleFactor(0.6)
            AvatarView(user: user, size: 56)
            VStack(alignment: .leading, spacing: 3) {
                Text(isMe ? "You" : user.name).font(.alboSans(18, weight: .bold)).foregroundStyle(AlboColor.ink)
                Text(user.handle).font(.alboSans(15)).foregroundStyle(AlboColor.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(count)").font(.alboSans(20, weight: .bold)).foregroundStyle(AlboColor.ink).monospacedDigit()
                Text(board == 0 ? "saves" : "done").font(.alboSans(14)).foregroundStyle(AlboColor.muted)
            }
        }
        .padding(.horizontal, 20).frame(height: 84)
        .background(isMe ? AlboColor.surface : Color.clear)
    }
}

// MARK: - Add Friends (Albo #180 to #182)

struct AddFriendsView: View {
    @Environment(AppState.self) private var app
    @State private var query = ""
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SearchPill(placeholder: "Search users...", text: $query)
                Button { app.showToast("Contacts sync arrives with the backend") } label: {
                    HStack(spacing: 16) {
                        MascotView().frame(width: 56)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Find your friends on Albo!").font(.alboSans(20, weight: .bold)).foregroundStyle(AlboColor.ink)
                            Text("Tap to sync your contacts now!").font(.alboSans(16)).foregroundStyle(AlboColor.inkSecondary)
                        }
                        Spacer()
                    }
                    .padding(18).background(AlboColor.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(AlboColor.hairline, lineWidth: 1))
                }
                .buttonStyle(PressableButtonStyle())
                Text("Meet the Albo team!").font(.alboSans(20, weight: .bold)).foregroundStyle(AlboColor.ink).padding(.top, 10)
                ForEach(SampleData.team.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }) { u in
                    VStack(spacing: 0) {
                        HStack(spacing: 16) {
                            NavigationLink(value: ProfileRoute.user(u)) {
                                HStack(spacing: 16) {
                                    AvatarView(user: u, size: 76)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(u.name).font(.alboSans(20, weight: .bold)).foregroundStyle(AlboColor.ink)
                                        Text(u.handle).font(.alboSans(16)).foregroundStyle(AlboColor.muted)
                                        Text("\(u.friendsOnAlbo) friends on Albo").font(.alboSans(16)).foregroundStyle(AlboColor.inkSecondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            FollowButton(isFollowing: app.isFollowing(u)) { app.toggleFollow(u) }
                        }
                        .padding(.vertical, 16)
                        Divider()
                    }
                }
            }
            .padding(20)
        }
        .background(AlboColor.ground)
        .navigationTitle("Add Friends")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { app.showToast("QR scanning needs the camera on a device") } label: { Image(systemName: "qrcode.viewfinder").font(.system(size: 22)).foregroundStyle(AlboColor.ink) }
            }
        }
    }
}
