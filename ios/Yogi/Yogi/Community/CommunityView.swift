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
                                Text(s.title).font(.yogiSans(20, weight: segment == s ? .bold : .medium)).foregroundStyle(segment == s ? YogiColor.ink : YogiColor.muted)
                                Rectangle().fill(segment == s ? YogiColor.ink : .clear).frame(height: 4)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                    NavigationLink(value: "friends") { Image(systemName: "magnifyingglass").font(.system(size: 24)).foregroundStyle(YogiColor.ink) }
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
            .background(YogiColor.ground)
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
                        Text("Get Started").font(.yogiSans(20, weight: .bold)).foregroundStyle(YogiColor.ink)
                        ProgressRing(progress: Double(app.gamification.claimedCount) / Double(max(1, app.gamification.checklist.count))).frame(width: 22, height: 22)
                    }
                    Text("Save content from anywhere to get started").font(.yogiSans(15)).foregroundStyle(YogiColor.inkSecondary)
                }
                Spacer()
                Text("📸📘📺").font(.system(size: 30))
            }
            .padding(18)
            .background(YogiColor.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 14, y: 6)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct ProgressRing: View {
    let progress: Double
    var body: some View {
        ZStack {
            Circle().stroke(YogiColor.optionFill, lineWidth: 4)
            Circle().trim(from: 0, to: max(0.02, progress)).stroke(YogiColor.ink, style: StrokeStyle(lineWidth: 4, lineCap: .round)).rotationEffect(.degrees(-90))
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
                    Image(systemName: "list.number").font(.system(size: 18)).foregroundStyle(YogiColor.ink).frame(width: 40, height: 40).background(YogiColor.card, in: Circle()).padding(10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            .onTapGesture(perform: onOpen)
            VStack(alignment: .leading, spacing: 10) {
                Text(post.title).font(post.kind == .list ? .yogiDisplay(20) : .yogiSans(19, weight: .semibold)).foregroundStyle(YogiColor.ink).lineLimit(2).multilineTextAlignment(.leading)
                HStack {
                    AvatarView(user: post.author, size: 30)
                    Text(post.author.name).font(.yogiSans(16)).foregroundStyle(YogiColor.inkSecondary).lineLimit(1)
                    Spacer()
                    Button(action: onBar) {
                        Group {
                            if let reaction { Text(reaction).font(.system(size: 20)) } else { Image(systemName: "face.smiling").font(.system(size: 20)).foregroundStyle(YogiColor.ink) }
                        }
                        .frame(width: 40, height: 40).background(YogiColor.optionFill, in: Circle())
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityLabel("React")
                }
            }
            .padding(14)
        }
        .background(YogiColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(YogiColor.hairline, lineWidth: 1))
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
            Button { onPick("✨") } label: { Image(systemName: "plus").font(.system(size: 20, weight: .semibold)).foregroundStyle(YogiColor.ink).frame(width: 44, height: 44).background(YogiColor.optionFill, in: Circle()) }
        }
        .padding(.horizontal, 10).frame(height: 62)
        .background(YogiColor.card, in: Capsule())
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
                Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 22, weight: .semibold)).foregroundStyle(YogiColor.ink) }.buttonStyle(.plain)
                AvatarView(user: post.author, size: 44)
                Text(post.author.name).font(.yogiSans(20, weight: .bold)).foregroundStyle(YogiColor.ink)
                Spacer()
                FollowButton(isFollowing: app.isFollowing(post.author)) { app.toggleFollow(post.author) }
                ShareLink(item: URL(string: "https://yogi.app")!) { Image(systemName: "square.and.arrow.up").font(.system(size: 22)).foregroundStyle(YogiColor.ink) }
            }
            .padding(.horizontal, 16).frame(height: 64)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Color(hex: post.coverTint).frame(height: 420).overlay(Text(post.coverEmoji).font(.system(size: 120)))
                    VStack(alignment: .leading, spacing: 12) {
                        Text(post.title).font(post.kind == .list ? .yogiDisplay(24) : .yogiSans(22, weight: .semibold)).foregroundStyle(YogiColor.ink)
                        if post.kind == .list {
                            Text("1m 34s").font(.yogiSans(16, weight: .semibold)).foregroundStyle(.white).padding(.horizontal, 14).frame(height: 36).background(YogiColor.brandOrange, in: Capsule())
                        }
                        if let stars = post.stars, post.kind != .list { StaticStars(rating: stars, color: YogiColor.ink, size: 18) }
                        if let id = post.saveID, let s = app.save(id) {
                            NavigationLink(value: LibraryRoute.save(s.id)) {
                                HStack(spacing: 14) {
                                    SaveCover(save: s, cornerRadius: 10).frame(width: 72, height: 96)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(s.title).font(.yogiSans(18, weight: .semibold)).foregroundStyle(YogiColor.ink)
                                        Text("\(s.category.pluralTitle) · \(s.recipe?.timeLabel ?? s.metaLine)").font(.yogiSans(15)).foregroundStyle(YogiColor.inkSecondary).lineLimit(1)
                                        HStack(spacing: 6) { AvatarStack(users: s.savedBy, size: 22); Text("\(s.saveCount) saved").font(.yogiSans(14)).foregroundStyle(YogiColor.inkSecondary) }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(YogiColor.inkSecondary)
                                }
                                .padding(14).background(YogiColor.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            Divider()
            HStack(spacing: 12) {
                Image(systemName: "face.smiling").font(.system(size: 22)).foregroundStyle(YogiColor.ink).frame(width: 48, height: 48).background(YogiColor.optionFill, in: Circle())
                HStack {
                    TextField("Say something...", text: $comment).font(.yogiSans(17))
                    Text("GIF").font(.system(size: 10, weight: .bold)).padding(4).background(RoundedRectangle(cornerRadius: 4).stroke(YogiColor.muted, lineWidth: 1)).foregroundStyle(YogiColor.muted)
                }
                .padding(.horizontal, 18).frame(height: 52).background(YogiColor.optionFill, in: Capsule())
                HStack(spacing: 6) { Image(systemName: "bubble.right").font(.system(size: 22)); Text("0").font(.yogiSans(18)) }.foregroundStyle(YogiColor.ink)
                Image(systemName: "bookmark").font(.system(size: 22)).foregroundStyle(YogiColor.ink)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .background(YogiColor.ground)
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
        let main: Text = Text(day, format: .dateTime.day().month(.wide)).fontWeight(.bold).foregroundStyle(YogiColor.ink)
        let slash: Text = Text(" / ").foregroundStyle(YogiColor.muted)
        let weekday: Text = Text(day, format: .dateTime.weekday(.wide)).foregroundStyle(YogiColor.muted)
        return (main + slash + weekday).font(.yogiSans(20))
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
                                    Text(e.title).font(.yogiSans(18, weight: .bold)).foregroundStyle(YogiColor.ink).lineLimit(1)
                                    Text([e.event.map { $0.start.formatted(.dateTime.hour().minute()) }, e.event?.venue].compactMap { $0 }.joined(separator: " · ")).font(.yogiSans(15)).foregroundStyle(YogiColor.inkSecondary).lineLimit(1)
                                }
                                Spacer()
                                RoundedRectangle(cornerRadius: 8).fill(YogiColor.optionFill).frame(width: 52, height: 72).rotationEffect(.degrees(6)).overlay(Text("🎟️"))
                            }
                        }
                        .buttonStyle(PressableButtonStyle())
                        .simultaneousGesture(TapGesture().onEnded { if app.save(e.id) == nil { app.saves.append(e) } })
                        EventExtras(save: e)
                    }
                }
            }
        }
        .padding(.top, 8)
    }
}

/// The row under an event: put it in the calendar, and the promo code if the
/// listing carries one. Albo surfaces both here rather than burying them in the
/// detail screen, because an offer you find later is an offer you missed.
struct EventExtras: View {
    @Environment(AppState.self) private var app
    let save: Save

    var body: some View {
        HStack(spacing: 10) {
            Button {
                Haptics.tap()
                app.addToCalendar(save)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Add to Calendar")
                }
                .font(.yogiSans(15, weight: .semibold))
                .foregroundStyle(YogiColor.systemBlue)
                .padding(.horizontal, 14).frame(height: 38)
                .background(Capsule().fill(YogiColor.systemBlue.opacity(0.10)))
            }
            .buttonStyle(.plain)

            if let offer = save.event?.offer {
                Text(offer)
                    .font(.yogiSans(14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12).frame(height: 32)
                    .background(Capsule().fill(YogiColor.danger))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, 100)
        .padding(.top, -6)
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
                Capsule().fill(YogiColor.hairline).frame(width: 40, height: 5).frame(maxWidth: .infinity).padding(.top, 8)
                HStack(spacing: 12) { Text("⚡️").font(.system(size: 26)); Text("Get Started").font(.yogiSans(32, weight: .bold)).foregroundStyle(YogiColor.ink) }
                HStack {
                    HStack(spacing: 10) { Image(systemName: "checklist"); Text("Progress").font(.yogiSans(20, weight: .semibold)) }.foregroundStyle(YogiColor.ink)
                    Spacer()
                    Text("\(app.gamification.claimedCount)/\(app.gamification.checklist.count)").font(.yogiSans(17, weight: .semibold)).foregroundStyle(YogiColor.ink).padding(.horizontal, 14).frame(height: 36).background(YogiColor.optionFill, in: Capsule())
                }
                Text("Get started with Yogi to unlock 520 extra imports.").font(.yogiSans(16)).foregroundStyle(YogiColor.inkSecondary)
                if let hero {
                    ZStack {
                        VStack(spacing: 18) {
                            Text(hero.emoji).font(.system(size: 120)).padding(.top, 20)
                            Text(hero.title).font(.yogiSans(22, weight: .bold)).foregroundStyle(YogiColor.ink)
                            if hero.target > 1 { Text("\(hero.progress)/\(hero.target)").font(.yogiSans(16)).foregroundStyle(YogiColor.inkSecondary) }
                            claimButton(hero, big: true)
                        }
                        .padding(18)
                        if hero.isComplete { ConfettiView(count: 14, seed: 146) }
                    }
                    .frame(maxWidth: .infinity)
                    .background(YogiColor.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.06), radius: 14, y: 6)
                }
                ForEach(rest) { t in
                    HStack(spacing: 14) {
                        Text(t.emoji).font(.system(size: 34)).frame(width: 52)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(t.title).font(.yogiSans(18, weight: .bold)).foregroundStyle(YogiColor.ink)
                            Text(t.subtitle).font(.yogiSans(15)).foregroundStyle(YogiColor.inkSecondary).lineLimit(1)
                        }
                        Spacer()
                        claimButton(t, big: false)
                    }
                    .padding(14).background(YogiColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous)).shadow(color: .black.opacity(0.05), radius: 10, y: 4)
                }
                if hero == nil { EmptyStateView(mascot: .king, title: "All done!", message: "You've unlocked every starter reward.") }
            }
            .padding(20)
        }
        .background(YogiColor.ground)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showPin) { PinShortcutTutorial() }
    }

    @ViewBuilder
    private func claimButton(_ t: ChecklistTask, big: Bool) -> some View {
        if t.isComplete {
            Button { app.claim(task: t.id) } label: {
                HStack(spacing: 8) { Text(big ? "Claim!  +\(t.reward)" : "Claim"); Text("⚡️").font(.system(size: 14)) }
                    .font(.yogiSans(big ? 20 : 16, weight: .semibold)).foregroundStyle(.white)
                    .padding(.horizontal, 20).frame(height: big ? 58 : 44).frame(maxWidth: big ? .infinity : nil)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: big ? 16 : 12, style: .continuous).fill(big ? YogiColor.rewardGreenDeep : Color.black).offset(y: 4)
                            RoundedRectangle(cornerRadius: big ? 16 : 12, style: .continuous).fill(big ? LinearGradient(colors: [YogiColor.rewardGreen, YogiColor.rewardGreenDeep], startPoint: .top, endPoint: .bottom) : LinearGradient(colors: [YogiColor.ink, YogiColor.ink], startPoint: .top, endPoint: .bottom))
                        }
                    )
            }
            .buttonStyle(PressableButtonStyle())
        } else if big {
            Button { start(t) } label: {
                HStack(spacing: 8) { Text("Start now"); Text("+\(t.reward) ⚡️").font(.yogiSans(15, weight: .semibold)) }
                    .font(.yogiSans(20, weight: .semibold)).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 58)
                    .background(YogiColor.systemBlue, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(PressableButtonStyle())
        } else {
            Text("+\(t.reward) ⚡️").font(.yogiSans(15, weight: .semibold)).foregroundStyle(YogiColor.ink).padding(.horizontal, 14).frame(height: 40).background(YogiColor.optionFill, in: Capsule())
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

/// "How to pin the Yogi shortcut" (Albo #150 to #155). Ends in the system share sheet.
struct PinShortcutTutorial: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    private let captions = ["doesn't show in your share sheet by default...", "You have to pin it 👉", "Now you can save to Yogi in a single tap"]

    var body: some View {
        VStack(spacing: 20) {
            Capsule().fill(YogiColor.hairline).frame(width: 40, height: 5).padding(.top, 8)
            Text("How to pin the Yogi shortcut").font(.yogiDisplay(26)).foregroundStyle(YogiColor.ink).frame(maxWidth: .infinity, alignment: .leading)
            PhoneMockup(width: 250) {
                VStack(spacing: 14) {
                    Spacer()
                    HStack(spacing: 10) { RoundedRectangle(cornerRadius: 8).fill(YogiColor.optionFill).frame(width: 36, height: 36); VStack(alignment: .leading) { Text("Reel from ryanresatka").font(.yogiSans(11, weight: .semibold)); Text("instagram.com").font(.yogiSans(10)).foregroundStyle(YogiColor.muted) }; Spacer() }.padding(.horizontal, 14)
                    HStack(spacing: 16) { ForEach(["📡", "💬", "📸", step >= 2 ? "🟧" : "✳️"], id: \.self) { e in VStack { Text(e).font(.system(size: 26)).frame(width: 46, height: 46).background(YogiColor.optionFill, in: RoundedRectangle(cornerRadius: 10)); Text(e == "🟧" ? "Yogi" : "App").font(.yogiSans(9)) } } }
                    HStack(spacing: 16) { ForEach(["Copy", "Quick Note", "Amazon", "View More"], id: \.self) { n in VStack { Circle().fill(YogiColor.optionFill).frame(width: 40, height: 40); Text(n).font(.yogiSans(8)).lineLimit(1) } } }
                    Spacer().frame(height: 24)
                }
                .foregroundStyle(YogiColor.ink)
                .background(YogiColor.surface)
            }
            HStack(spacing: 8) {
                if step == 0 { Text("Yogi").font(.yogiDisplay(26)); MascotView().frame(width: 30).padding(4).background(YogiColor.card, in: RoundedRectangle(cornerRadius: 8)).shadow(color: .black.opacity(0.1), radius: 4) }
                Text(orphanSafe: captions[step]).font(.yogiDisplay(26)).multilineTextAlignment(.center)
            }
            .foregroundStyle(YogiColor.ink)
            .frame(minHeight: 100)
            GeometryReader { geo in
                ZStack(alignment: .leading) { Capsule().fill(YogiColor.optionFill); Capsule().fill(YogiColor.ink).frame(width: geo.size.width * Double(step + 1) / 3) }
            }
            .frame(height: 6).padding(.horizontal, 20)
            Spacer()
            if step < 2 {
                PrimaryButton(title: "Let's do it") { withAnimation { step += 1 } }
            } else {
                ShareLink(item: URL(string: "https://yogi.app/how-to/pin-to-share-sheet")!) {
                    ZStack { Capsule().fill(Color.black).offset(y: 5); Capsule().fill(YogiColor.ink); Text("Let's do it").font(.yogiSans(18, weight: .semibold)).foregroundStyle(.white) }.frame(height: 58).frame(maxWidth: .infinity)
                }
                .simultaneousGesture(TapGesture().onEnded { app.advance(task: "pin"); app.showToast("Tap Edit Actions, then favourite Add to Yogi") })
            }
        }
        .padding(.horizontal, 24).padding(.bottom, 12)
        .background(YogiColor.ground)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
}
