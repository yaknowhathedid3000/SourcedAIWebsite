import SwiftUI

/// Following / Community / Nearby / Events with the masonry feed (Albo #145, #161 to #166).
struct CommunityView: View {
    @Environment(AppState.self) private var app
    enum Segment: String, CaseIterable, Identifiable { case following, community, nearby, events; var id: String { rawValue }
        var title: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() } }
    @State private var segment: Segment = .community
    @State private var post: FeedPost? = nil
    @State private var reactingOn: UUID? = nil
    @State private var reactions: [UUID: String] = [:]
    @State private var path = NavigationPath()

    private var posts: [FeedPost] {
        switch segment {
        case .following: return SampleData.feed.filter { app.isFollowing($0.author) }
        case .community: return SampleData.feed
        case .nearby: return SampleData.feed.filter(\.isNearby)
        case .events: return []
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                HStack(spacing: 26) {
                    ForEach(Segment.allCases) { s in
                        Button { withAnimation(.easeInOut(duration: 0.2)) { segment = s } } label: {
                            VStack(spacing: 8) {
                                Text(s.title).font(.alboSans(20, weight: segment == s ? .bold : .medium)).foregroundStyle(segment == s ? AlboColor.ink : AlboColor.muted)
                                Rectangle().fill(segment == s ? AlboColor.ink : .clear).frame(height: 4)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                    NavigationLink(value: "friends") { Image(systemName: "magnifyingglass").font(.system(size: 24)).foregroundStyle(AlboColor.ink) }
                }
                .padding(.horizontal, 20).padding(.top, 8)
                ScrollView {
                    VStack(spacing: 18) {
                        if segment != .events { getStartedCard }
                        switch segment {
                        case .events: EventsList()
                        default:
                            if posts.isEmpty {
                                EmptyStateView(systemImage: "square.grid.2x2", title: "No posts yet", message: "Posts will appear here as people share").padding(.top, 60)
                            } else {
                                MasonryGrid(posts: posts, reactions: reactions, reactingOn: $reactingOn) { p in post = p } onReact: { p, e in reactions[p.id] = e; reactingOn = nil }
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 100)
                }
            }
            .background(AlboColor.ground)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $post) { p in NavigationStack { PostDetailView(post: p) } }
            .navigationDestination(for: String.self) { key in
                if key == "friends" { AddFriendsView() }
            }
            .navigationDestination(for: UserSummary.self) { u in ProfileView(user: u) }
            .navigationDestination(for: ProfileRoute.self) { r in
                switch r {
                case .user(let u): ProfileView(user: u)
                case .save(let id): SaveDetailView(saveID: id)
                default: AddFriendsView()
                }
            }
            .navigationDestination(for: LibraryRoute.self) { r in
                if case .save(let id) = r { SaveDetailView(saveID: id) }
            }
        }
    }

    private var getStartedCard: some View {
        Button { app.showGetStarted = true } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Get Started").font(.alboSans(20, weight: .bold)).foregroundStyle(AlboColor.ink)
                        ProgressRing(progress: Double(app.gamification.claimedCount) / Double(max(1, app.gamification.checklist.count))).frame(width: 22, height: 22)
                    }
                    Text("Save content from anywhere to get started").font(.alboSans(15)).foregroundStyle(AlboColor.inkSecondary)
                }
                Spacer()
                Text("📸📘📺").font(.system(size: 30))
            }
            .padding(18)
            .background(AlboColor.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 14, y: 6)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct ProgressRing: View {
    let progress: Double
    var body: some View {
        ZStack {
            Circle().stroke(AlboColor.optionFill, lineWidth: 4)
            Circle().trim(from: 0, to: max(0.02, progress)).stroke(AlboColor.ink, style: StrokeStyle(lineWidth: 4, lineCap: .round)).rotationEffect(.degrees(-90))
        }
    }
}

/// Two-column masonry with reaction bar on long-press (Albo #145, #164).
struct MasonryGrid: View {
    let posts: [FeedPost]
    let reactions: [UUID: String]
    @Binding var reactingOn: UUID?
    let onOpen: (FeedPost) -> Void
    let onReact: (FeedPost, String) -> Void

    private var columns: ([FeedPost], [FeedPost]) {
        var l: [FeedPost] = [], r: [FeedPost] = []
        var lh = 0.0, rh = 0.0
        for p in posts { if lh <= rh { l.append(p); lh += p.aspect } else { r.append(p); rh += p.aspect } }
        return (l, r)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            column(columns.0)
            column(columns.1)
        }
    }

    private func column(_ items: [FeedPost]) -> some View {
        LazyVStack(spacing: 14) {
            ForEach(items) { p in
                FeedCard(post: p, reaction: reactions[p.id], showingBar: reactingOn == p.id, onOpen: { onOpen(p) }, onBar: { reactingOn = reactingOn == p.id ? nil : p.id }, onReact: { onReact(p, $0) })
            }
        }
    }
}

struct FeedCard: View {
    let post: FeedPost
    let reaction: String?
    let showingBar: Bool
    let onOpen: () -> Void
    let onBar: () -> Void
    let onReact: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Color(hex: post.coverTint).aspectRatio(post.aspect, contentMode: .fit)
                    .overlay(Text(post.coverEmoji).font(.system(size: 60)))
                if let stars = post.stars { StaticStars(rating: stars, color: .white, size: 16).padding(12).shadow(color: .black.opacity(0.4), radius: 3) }
                if post.kind == .list {
                    Image(systemName: "list.number").font(.system(size: 18)).foregroundStyle(AlboColor.ink).frame(width: 40, height: 40).background(AlboColor.card, in: Circle()).padding(10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            .onTapGesture(perform: onOpen)
            VStack(alignment: .leading, spacing: 10) {
                Text(post.title).font(post.kind == .list ? .alboDisplay(20) : .alboSans(19, weight: .semibold)).foregroundStyle(AlboColor.ink).lineLimit(2).multilineTextAlignment(.leading)
                HStack {
                    AvatarView(user: post.author, size: 30)
                    Text(post.author.name).font(.alboSans(16)).foregroundStyle(AlboColor.inkSecondary).lineLimit(1)
                    Spacer()
                    Button(action: onBar) {
                        Group {
                            if let reaction { Text(reaction).font(.system(size: 20)) } else { Image(systemName: "face.smiling").font(.system(size: 20)).foregroundStyle(AlboColor.ink) }
                        }
                        .frame(width: 40, height: 40).background(AlboColor.optionFill, in: Circle())
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityLabel("React")
                }
            }
            .padding(14)
        }
        .background(AlboColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(AlboColor.hairline, lineWidth: 1))
        .overlay(alignment: .top) {
            if showingBar { ReactionBar(onPick: onReact).offset(y: -22).transition(.scale.combined(with: .opacity)) }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingBar)
        .zIndex(showingBar ? 1 : 0)
    }
}

/// Heart, laughing, surprised, sad, fire, thumbs up, plus (Albo #164).
struct ReactionBar: View {
    let onPick: (String) -> Void
    var body: some View {
        HStack(spacing: 6) {
            ForEach(["❤️", "😂", "😮", "😢", "🔥", "👍"], id: \.self) { e in
                Button { onPick(e) } label: { Text(e).font(.system(size: 30)).frame(width: 44, height: 44) }.buttonStyle(PressableButtonStyle())
            }
            Button { onPick("✨") } label: { Image(systemName: "plus").font(.system(size: 20, weight: .semibold)).foregroundStyle(AlboColor.ink).frame(width: 44, height: 44).background(AlboColor.optionFill, in: Circle()) }
        }
        .padding(.horizontal, 10).frame(height: 62)
        .background(AlboColor.card, in: Capsule())
        .shadow(color: .black.opacity(0.18), radius: 16, y: 8)
    }
}

/// Post detail: author header, hero, linked save card, comment bar (Albo #156).
struct PostDetailView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let post: FeedPost
    @State private var comment = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 22, weight: .semibold)).foregroundStyle(AlboColor.ink) }.buttonStyle(.plain)
                AvatarView(user: post.author, size: 44)
                Text(post.author.name).font(.alboSans(20, weight: .bold)).foregroundStyle(AlboColor.ink)
                Spacer()
                FollowButton(isFollowing: app.isFollowing(post.author)) { app.toggleFollow(post.author) }
                ShareLink(item: URL(string: "https://albo.inc")!) { Image(systemName: "square.and.arrow.up").font(.system(size: 22)).foregroundStyle(AlboColor.ink) }
            }
            .padding(.horizontal, 16).frame(height: 64)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Color(hex: post.coverTint).frame(height: 420).overlay(Text(post.coverEmoji).font(.system(size: 120)))
                    VStack(alignment: .leading, spacing: 12) {
                        Text(post.title).font(post.kind == .list ? .alboDisplay(24) : .alboSans(22, weight: .semibold)).foregroundStyle(AlboColor.ink)
                        if post.kind == .list {
                            Text("1m 34s").font(.alboSans(16, weight: .semibold)).foregroundStyle(.white).padding(.horizontal, 14).frame(height: 36).background(AlboColor.brandOrange, in: Capsule())
                        }
                        if let stars = post.stars, post.kind != .list { StaticStars(rating: stars, color: AlboColor.ink, size: 18) }
                        if let id = post.saveID, let s = app.save(id) {
                            NavigationLink(value: LibraryRoute.save(s.id)) {
                                HStack(spacing: 14) {
                                    SaveCover(save: s, cornerRadius: 10).frame(width: 72, height: 96)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(s.title).font(.alboSans(18, weight: .semibold)).foregroundStyle(AlboColor.ink)
                                        Text("\(s.category.pluralTitle) · \(s.recipe?.timeLabel ?? s.metaLine)").font(.alboSans(15)).foregroundStyle(AlboColor.inkSecondary).lineLimit(1)
                                        HStack(spacing: 6) { AvatarStack(users: s.savedBy, size: 22); Text("\(s.saveCount) saved").font(.alboSans(14)).foregroundStyle(AlboColor.inkSecondary) }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(AlboColor.inkSecondary)
                                }
                                .padding(14).background(AlboColor.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            Divider()
            HStack(spacing: 12) {
                Image(systemName: "face.smiling").font(.system(size: 22)).foregroundStyle(AlboColor.ink).frame(width: 48, height: 48).background(AlboColor.optionFill, in: Circle())
                HStack {
                    TextField("Say something...", text: $comment).font(.alboSans(17))
                    Text("GIF").font(.system(size: 10, weight: .bold)).padding(4).background(RoundedRectangle(cornerRadius: 4).stroke(AlboColor.muted, lineWidth: 1)).foregroundStyle(AlboColor.muted)
                }
                .padding(.horizontal, 18).frame(height: 52).background(AlboColor.optionFill, in: Capsule())
                HStack(spacing: 6) { Image(systemName: "bubble.right").font(.system(size: 22)); Text("0").font(.alboSans(18)) }.foregroundStyle(AlboColor.ink)
                Image(systemName: "bookmark").font(.system(size: 22)).foregroundStyle(AlboColor.ink)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .background(AlboColor.ground)
        .navigationDestination(for: LibraryRoute.self) { r in if case .save(let id) = r { SaveDetailView(saveID: id) } }
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// Events grouped by date (Albo #166).
struct EventsList: View {
    @Environment(AppState.self) private var app
    private var grouped: [(Date, [Save])] {
        let events = SampleData.events.sorted { ($0.event?.start ?? .distantFuture) < ($1.event?.start ?? .distantFuture) }
        let cal = Calendar.current
        var out: [(Date, [Save])] = []
        for e in events {
            guard let d = e.event?.start else { continue }
            let day = cal.startOfDay(for: d)
            if let i = out.firstIndex(where: { $0.0 == day }) { out[i].1.append(e) } else { out.append((day, [e])) }
        }
        return out
    }

    private func dayHeading(_ day: Date) -> Text {
        let main: Text = Text(day, format: .dateTime.day().month(.wide)).fontWeight(.bold).foregroundStyle(AlboColor.ink)
        let slash: Text = Text(" / ").foregroundStyle(AlboColor.muted)
        let weekday: Text = Text(day, format: .dateTime.weekday(.wide)).foregroundStyle(AlboColor.muted)
        return (main + slash + weekday).font(.alboSans(20))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            ForEach(grouped, id: \.0) { day, items in
                VStack(alignment: .leading, spacing: 18) {
                    dayHeading(day)
                    ForEach(items) { e in
                        NavigationLink(value: LibraryRoute.save(e.id)) {
                            HStack(spacing: 14) {
                                SaveCover(save: e, cornerRadius: 12).frame(width: 86, height: 86)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(e.title).font(.alboSans(18, weight: .bold)).foregroundStyle(AlboColor.ink).lineLimit(1)
                                    Text([e.event.map { $0.start.formatted(.dateTime.hour().minute()) }, e.event?.venue].compactMap { $0 }.joined(separator: " · ")).font(.alboSans(15)).foregroundStyle(AlboColor.inkSecondary).lineLimit(1)
                                }
                                Spacer()
                                RoundedRectangle(cornerRadius: 8).fill(AlboColor.optionFill).frame(width: 52, height: 72).rotationEffect(.degrees(6)).overlay(Text("🎟️"))
                            }
                        }
                        .buttonStyle(PressableButtonStyle())
                        .simultaneousGesture(TapGesture().onEnded { if app.save(e.id) == nil { app.saves.append(e) } })
                    }
                }
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Get Started checklist (Albo #146 to #149)

struct GetStartedSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var showPin = false

    private var hero: ChecklistTask? { app.gamification.checklist.first { !$0.isClaimed } }
    private var rest: [ChecklistTask] { app.gamification.checklist.filter { $0.id != hero?.id && !$0.isClaimed } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Capsule().fill(AlboColor.hairline).frame(width: 40, height: 5).frame(maxWidth: .infinity).padding(.top, 8)
                HStack(spacing: 12) { Text("⚡️").font(.system(size: 26)); Text("Get Started").font(.alboSans(32, weight: .bold)).foregroundStyle(AlboColor.ink) }
                HStack {
                    HStack(spacing: 10) { Image(systemName: "checklist"); Text("Progress").font(.alboSans(20, weight: .semibold)) }.foregroundStyle(AlboColor.ink)
                    Spacer()
                    Text("\(app.gamification.claimedCount)/\(app.gamification.checklist.count)").font(.alboSans(17, weight: .semibold)).foregroundStyle(AlboColor.ink).padding(.horizontal, 14).frame(height: 36).background(AlboColor.optionFill, in: Capsule())
                }
                Text("Get started with Albo to unlock 520 extra imports.").font(.alboSans(16)).foregroundStyle(AlboColor.inkSecondary)
                if let hero {
                    ZStack {
                        VStack(spacing: 18) {
                            Text(hero.emoji).font(.system(size: 120)).padding(.top, 20)
                            Text(hero.title).font(.alboSans(22, weight: .bold)).foregroundStyle(AlboColor.ink)
                            if hero.target > 1 { Text("\(hero.progress)/\(hero.target)").font(.alboSans(16)).foregroundStyle(AlboColor.inkSecondary) }
                            claimButton(hero, big: true)
                        }
                        .padding(18)
                        if hero.isComplete { ConfettiView(count: 14, seed: 146) }
                    }
                    .frame(maxWidth: .infinity)
                    .background(AlboColor.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.06), radius: 14, y: 6)
                }
                ForEach(rest) { t in
                    HStack(spacing: 14) {
                        Text(t.emoji).font(.system(size: 34)).frame(width: 52)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(t.title).font(.alboSans(18, weight: .bold)).foregroundStyle(AlboColor.ink)
                            Text(t.subtitle).font(.alboSans(15)).foregroundStyle(AlboColor.inkSecondary).lineLimit(1)
                        }
                        Spacer()
                        claimButton(t, big: false)
                    }
                    .padding(14).background(AlboColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous)).shadow(color: .black.opacity(0.05), radius: 10, y: 4)
                }
                if hero == nil { EmptyStateView(mascot: .king, title: "All done!", message: "You've unlocked every starter reward.") }
            }
            .padding(20)
        }
        .background(AlboColor.ground)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showPin) { PinShortcutTutorial() }
    }

    @ViewBuilder
    private func claimButton(_ t: ChecklistTask, big: Bool) -> some View {
        if t.isComplete {
            Button { app.claim(task: t.id) } label: {
                HStack(spacing: 8) { Text(big ? "Claim!  +\(t.reward)" : "Claim"); Text("⚡️").font(.system(size: 14)) }
                    .font(.alboSans(big ? 20 : 16, weight: .semibold)).foregroundStyle(.white)
                    .padding(.horizontal, 20).frame(height: big ? 58 : 44).frame(maxWidth: big ? .infinity : nil)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: big ? 16 : 12, style: .continuous).fill(big ? AlboColor.rewardGreenDeep : Color.black).offset(y: 4)
                            RoundedRectangle(cornerRadius: big ? 16 : 12, style: .continuous).fill(big ? LinearGradient(colors: [AlboColor.rewardGreen, AlboColor.rewardGreenDeep], startPoint: .top, endPoint: .bottom) : LinearGradient(colors: [AlboColor.ink, AlboColor.ink], startPoint: .top, endPoint: .bottom))
                        }
                    )
            }
            .buttonStyle(PressableButtonStyle())
        } else if big {
            Button { start(t) } label: {
                HStack(spacing: 8) { Text("Start now"); Text("+\(t.reward) ⚡️").font(.alboSans(15, weight: .semibold)) }
                    .font(.alboSans(20, weight: .semibold)).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 58)
                    .background(AlboColor.systemBlue, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(PressableButtonStyle())
        } else {
            Text("+\(t.reward) ⚡️").font(.alboSans(15, weight: .semibold)).foregroundStyle(AlboColor.ink).padding(.horizontal, 14).frame(height: 40).background(AlboColor.optionFill, in: Capsule())
        }
    }

    private func start(_ t: ChecklistTask) {
        switch t.id {
        case "pin": showPin = true
        case "invite": app.showToast("Invite links are on your profile")
        default: dismiss(); app.showAddSheet = true
        }
    }
}

/// "How to pin the Albo shortcut" (Albo #150 to #155). Ends in the system share sheet.
struct PinShortcutTutorial: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    private let captions = ["doesn't show in your share sheet by default...", "You have to pin it 👉", "Now you can save to Albo in a single tap"]

    var body: some View {
        VStack(spacing: 20) {
            Capsule().fill(AlboColor.hairline).frame(width: 40, height: 5).padding(.top, 8)
            Text("How to pin the Albo shortcut").font(.alboDisplay(26)).foregroundStyle(AlboColor.ink).frame(maxWidth: .infinity, alignment: .leading)
            PhoneMockup(width: 250) {
                VStack(spacing: 14) {
                    Spacer()
                    HStack(spacing: 10) { RoundedRectangle(cornerRadius: 8).fill(AlboColor.optionFill).frame(width: 36, height: 36); VStack(alignment: .leading) { Text("Reel from ryanresatka").font(.alboSans(11, weight: .semibold)); Text("instagram.com").font(.alboSans(10)).foregroundStyle(AlboColor.muted) }; Spacer() }.padding(.horizontal, 14)
                    HStack(spacing: 16) { ForEach(["📡", "💬", "📸", step >= 2 ? "🟧" : "✳️"], id: \.self) { e in VStack { Text(e).font(.system(size: 26)).frame(width: 46, height: 46).background(AlboColor.optionFill, in: RoundedRectangle(cornerRadius: 10)); Text(e == "🟧" ? "Albo" : "App").font(.alboSans(9)) } } }
                    HStack(spacing: 16) { ForEach(["Copy", "Quick Note", "Amazon", "View More"], id: \.self) { n in VStack { Circle().fill(AlboColor.optionFill).frame(width: 40, height: 40); Text(n).font(.alboSans(8)).lineLimit(1) } } }
                    Spacer().frame(height: 24)
                }
                .foregroundStyle(AlboColor.ink)
                .background(AlboColor.surface)
            }
            HStack(spacing: 8) {
                if step == 0 { Text("Albo").font(.alboDisplay(26)); MascotView().frame(width: 30).padding(4).background(AlboColor.card, in: RoundedRectangle(cornerRadius: 8)).shadow(color: .black.opacity(0.1), radius: 4) }
                Text(orphanSafe: captions[step]).font(.alboDisplay(26)).multilineTextAlignment(.center)
            }
            .foregroundStyle(AlboColor.ink)
            .frame(minHeight: 100)
            GeometryReader { geo in
                ZStack(alignment: .leading) { Capsule().fill(AlboColor.optionFill); Capsule().fill(AlboColor.ink).frame(width: geo.size.width * Double(step + 1) / 3) }
            }
            .frame(height: 6).padding(.horizontal, 20)
            Spacer()
            if step < 2 {
                PrimaryButton(title: "Let's do it") { withAnimation { step += 1 } }
            } else {
                ShareLink(item: URL(string: "https://albo.inc/how-to/pin-to-share-sheet")!) {
                    ZStack { Capsule().fill(Color.black).offset(y: 5); Capsule().fill(AlboColor.ink); Text("Let's do it").font(.alboSans(18, weight: .semibold)).foregroundStyle(.white) }.frame(height: 58).frame(maxWidth: .infinity)
                }
                .simultaneousGesture(TapGesture().onEnded { app.advance(task: "pin"); app.showToast("Tap Edit Actions, then favourite Add to Albo") })
            }
        }
        .padding(.horizontal, 24).padding(.bottom, 12)
        .background(AlboColor.ground)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
}
