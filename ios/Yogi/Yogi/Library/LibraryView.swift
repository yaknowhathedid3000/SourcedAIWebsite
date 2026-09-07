import SwiftUI

enum LibraryRoute: Hashable {
    case save(UUID)
    case category(SaveCategory)
    case collection(UUID)
    case notifications
    case chat
    case cleanup
}

/// Library home (Albo #56, #99): serif header, category chips, Recently saved, Collections, Ask Yogi FAB.
struct LibraryView: View {
    @Environment(AppState.self) private var app
    @State private var path = NavigationPath()
    @State private var showNewCollection = false
    @State private var showFirstImportCoach = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    header
                    categoryRow
                    recentlySaved
                    collectionsSection
                }
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            .background(YogiColor.ground)
            .overlay(alignment: .bottomTrailing) {
                AskYogiFAB { app.showAskYogi = true }.padding(.trailing, 20).padding(.bottom, 16)
            }
            .navigationDestination(for: LibraryRoute.self) { route in
                switch route {
                case .save(let id): SaveDetailView(saveID: id)
                case .category(let c): CategoryView(category: c)
                case .collection(let id): CollectionDetailView(collectionID: id)
                case .notifications: NotificationsView()
                case .chat: ChatView()
                case .cleanup: CleanupView()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showNewCollection) { NewCollectionFlow(firstSave: nil) }
            .sheet(isPresented: $showFirstImportCoach) { FirstImportCoach() }
            .onAppear {
                if app.saves.isEmpty && !app.hasSeenFirstImportCoach { showFirstImportCoach = true }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Library").yogiText(.screenTitle)
            Spacer()
            Button { path.append(LibraryRoute.notifications) } label: {
                Image(systemName: "bell").font(.system(size: 24)).foregroundStyle(YogiColor.ink)
                    .overlay(alignment: .topTrailing) {
                        if !app.notifications.isEmpty { Circle().fill(YogiColor.danger).frame(width: 9, height: 9).offset(x: 2, y: -2) }
                    }
            }
            .accessibilityLabel("Notifications")
            .padding(.trailing, 18)
            Button { path.append(LibraryRoute.cleanup) } label: {
                Image(systemName: "wand.and.sparkles").font(.system(size: 22)).foregroundStyle(YogiColor.ink)
            }
            .accessibilityLabel("Clean up your saves")
            .padding(.trailing, 18)
            Button { path.append(LibraryRoute.chat) } label: {
                Image(systemName: "paperplane").font(.system(size: 24)).foregroundStyle(YogiColor.ink)
            }
            .accessibilityLabel("Chat")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var categoryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 26) {
                ForEach(SaveCategory.browsable) { c in
                    Button { path.append(LibraryRoute.category(c)) } label: {
                        VStack(spacing: 8) {
                            CategoryIcon(category: c, size: 64)
                            Text(c.pluralTitle).font(.yogiSans(16)).foregroundStyle(YogiColor.inkSecondary)
                        }
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var recentlySaved: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeader(title: "Recently saved", onTap: { path.append(LibraryRoute.category(.recipe)) })
                GetStartedPill()
            }
            .padding(.horizontal, 20)
            if app.saves.isEmpty {
                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 14).stroke(YogiColor.hairline, style: StrokeStyle(lineWidth: 2, dash: [6, 5])).frame(width: 110, height: 150)
                        .overlay(Text("?").font(.yogiSans(30)).foregroundStyle(YogiColor.muted))
                    VStack(alignment: .leading, spacing: 8) {
                        Text("You have no saves").font(.yogiSans(18, weight: .semibold)).foregroundStyle(YogiColor.ink)
                        Text("The content you share to yogi will appear here.").font(.yogiSans(15)).foregroundStyle(YogiColor.muted)
                        Button("Show me how") { showFirstImportCoach = true }.font(.yogiSans(15, weight: .semibold)).foregroundStyle(YogiColor.ink)
                            .padding(.horizontal, 16).frame(height: 40).background(YogiColor.optionFill, in: Capsule())
                    }
                }
                .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(app.recentSaves.prefix(12)) { s in
                            Button { path.append(LibraryRoute.save(s.id)) } label: { SaveCard(save: s) }
                                .buttonStyle(PressableButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            Rectangle().fill(YogiColor.hairline).frame(height: 1).padding(.horizontal, 20)
        }
    }

    private var collectionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Collections", trailing: AnyView(
                Button { showNewCollection = true } label: {
                    HStack(spacing: 4) { Image(systemName: "plus"); Text("New") }.font(.yogiSans(18, weight: .semibold)).foregroundStyle(YogiColor.ink)
                }
            ))
            .padding(.horizontal, 20)
            if app.collections.isEmpty {
                EmptyStateView(systemImage: "folder.fill", title: "No collections yet", message: "Start creating collections to organize your saves")
            } else {
                VStack(spacing: 18) {
                    ForEach(app.collections) { c in
                        Button { path.append(LibraryRoute.collection(c.id)) } label: { CollectionRow(collection: c) }
                            .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

/// "Get Started" pill with a green badge while checklist rewards are waiting (Albo #56, #99).
struct GetStartedPill: View {
    @Environment(AppState.self) private var app
    private var pending: Int { app.gamification.checklist.filter { $0.isComplete && !$0.isClaimed }.count }
    var body: some View {
        Button { app.showGetStarted = true } label: {
            Text("Get Started").font(.yogiSans(17, weight: .semibold)).foregroundStyle(YogiColor.ink)
                .padding(.horizontal, 22).frame(height: 54)
                .background(YogiColor.card, in: Capsule())
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
                .overlay(alignment: .topTrailing) {
                    if pending > 0 {
                        Text("\(pending)").font(.yogiSans(12, weight: .bold)).foregroundStyle(.white)
                            .frame(width: 22, height: 22).background(YogiColor.rewardGreen, in: Circle()).offset(x: 4, y: -6)
                    }
                }
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Portrait cover with platform eyebrow and title (Albo #99: "Images · Untitled", "Markdown · Cookie recipes").
struct SaveCard: View {
    let save: Save
    var width: CGFloat = 118

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SaveCover(save: save).frame(width: width, height: width * 1.4)
            Text(save.sourcePlatform.cardLabel).font(.yogiSans(14)).foregroundStyle(YogiColor.muted)
            Text(save.title).font(.yogiSans(17, weight: .semibold)).foregroundStyle(YogiColor.ink).lineLimit(2).multilineTextAlignment(.leading)
        }
        .frame(width: width, alignment: .leading)
    }
}

/// Cover image stand-in: tinted rounded rect with the save's emoji, note preview for markdown, category badge.
struct SaveCover: View {
    let save: Save
    var cornerRadius: CGFloat = 16

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(Color(hex: save.coverTint))
            if save.category == .note, let body = save.noteBody {
                VStack(alignment: .leading, spacing: 6) {
                    Text(save.title).font(.yogiSans(15, weight: .semibold)).foregroundStyle(YogiColor.ink)
                    Text(body).font(.yogiSans(12)).foregroundStyle(YogiColor.inkSecondary).lineLimit(4)
                }
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else if let e = save.coverEmoji {
                Text(e).font(.system(size: 44)).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Image(systemName: "photo").font(.system(size: 28)).foregroundStyle(YogiColor.muted).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            if save.isImporting {
                ProgressView().padding(8)
            } else if save.category != .image {
                Text(save.category.emoji).font(.system(size: 18)).padding(6)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).stroke(YogiColor.hairline, lineWidth: 0.5))
    }
}

struct CollectionRow: View {
    let collection: SaveCollection
    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: collection.coverTint)).frame(width: 84, height: 84)
                .overlay(Text(collection.coverEmoji).font(.system(size: 36)))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: collection.isPublic ? "globe" : "lock.fill").font(.system(size: 12))
                    Text(collection.isPublic ? "Public" : "Private").font(.yogiSans(14))
                }
                .foregroundStyle(YogiColor.muted)
                Text(collection.name).font(.yogiSans(20, weight: .bold)).foregroundStyle(YogiColor.ink)
                HStack(spacing: 6) {
                    AvatarView(user: collection.owner, size: 22)
                    Text(collection.owner.name).font(.yogiSans(14)).foregroundStyle(YogiColor.inkSecondary)
                }
            }
            Spacer()
            Image(systemName: "ellipsis").font(.system(size: 20, weight: .bold)).foregroundStyle(YogiColor.ink)
        }
    }
}

/// Collection detail: saves in the collection with the same row style as category views.
struct CollectionDetailView: View {
    @Environment(AppState.self) private var app
    let collectionID: UUID
    @State private var showInvite = false

    private var collection: SaveCollection? { app.collections.first { $0.id == collectionID } }

    var body: some View {
        ScrollView {
            if let c = collection {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(c.name).yogiText(.screenTitle)
                            if let d = c.details, !d.isEmpty { Text(d).font(.yogiSans(16)).foregroundStyle(YogiColor.inkSecondary) }
                            HStack(spacing: 8) {
                                TagChip(title: c.isPublic ? "Public" : "Private", systemImage: c.isPublic ? "globe" : "lock.fill")
                                Text("\(c.saveIDs.count) saves").font(.yogiSans(15)).foregroundStyle(YogiColor.muted)
                            }
                        }
                        Spacer()
                        RoundedRectangle(cornerRadius: 16).fill(Color(hex: c.coverTint)).frame(width: 72, height: 72).overlay(Text(c.coverEmoji).font(.system(size: 30)))
                    }
                    HStack(spacing: 10) {
                        if let url = c.inviteURL {
                            ShareLink(item: url) {
                                HStack(spacing: 6) { Image(systemName: "person.badge.plus"); Text("Invite friends") }
                                    .font(.yogiSans(16, weight: .semibold)).foregroundStyle(YogiColor.ink)
                                    .padding(.horizontal, 18).frame(height: 48).background(Capsule().stroke(YogiColor.hairline, lineWidth: 1.5))
                            }
                        }
                    }
                    let saves = c.saveIDs.compactMap { app.save($0) }
                    if saves.isEmpty {
                        EmptyStateView(systemImage: "tray", title: "Nothing here yet", message: "Add saves to this collection from any item's menu.")
                    } else {
                        ForEach(saves) { s in
                            NavigationLink(value: LibraryRoute.save(s.id)) { SaveRow(save: s, onMenu: nil) }
                                .buttonStyle(PressableButtonStyle())
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(YogiColor.ground)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Notifications list (Albo #131).
struct NotificationsView: View {
    @Environment(AppState.self) private var app
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if app.notifications.isEmpty {
                    EmptyStateView(systemImage: "bell", title: "No notifications yet", message: "Reminders you set will show up here.")
                } else {
                    ForEach(app.notifications) { n in
                        NavigationLink(value: n.saveID.map { LibraryRoute.save($0) } ?? LibraryRoute.notifications) {
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: "bell.fill").font(.system(size: 20)).foregroundStyle(YogiColor.ink).padding(.top, 2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(n.title).font(.yogiSans(17, weight: .bold)).foregroundStyle(YogiColor.ink)
                                    Text(n.body).font(.yogiSans(15)).foregroundStyle(YogiColor.inkSecondary).lineLimit(2)
                                    Text(n.createdAt, style: .relative).font(.yogiSans(13)).foregroundStyle(YogiColor.muted) + Text(" ago").font(.yogiSans(13)).foregroundStyle(YogiColor.muted)
                                }
                                Spacer()
                            }
                            .padding(16)
                            .background(YogiColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
            }
            .padding(20)
        }
        .background(YogiColor.ground)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// "Let's send in your first thing!" coach (Albo #47 to #49, #55).
struct FirstImportCoach: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var platform: SourcePlatform? = nil
    @State private var showGreatJob = false

    var body: some View {
        VStack(spacing: 18) {
            Capsule().fill(YogiColor.hairline).frame(width: 40, height: 5).padding(.top, 8)
            if let platform {
                VStack(spacing: 16) {
                    HStack {
                        Button { self.platform = nil } label: { Image(systemName: "arrow.left").font(.system(size: 20, weight: .medium)).foregroundStyle(YogiColor.ink) }
                        Spacer()
                    }
                    Text("How to share from \(platform.title)").yogiText(.onboardingHeadline).multilineTextAlignment(.center)
                    Text(platform.emoji).font(.system(size: 64))
                    Text("Open \(platform.title), tap Share, then choose Yogi. We'll detect the import and set you up.")
                        .font(.yogiSans(16)).foregroundStyle(YogiColor.inkSecondary).multilineTextAlignment(.center)
                    PrimaryButton(title: "View video instruction & setup") { finish() }
                    Button("I prefer text instructions") { finish() }.font(.yogiSans(16)).foregroundStyle(YogiColor.inkSecondary)
                }
                .padding(.horizontal, 24)
            } else {
                Text("📺📸📘").font(.system(size: 64)).padding(.top, 20)
                Text("Let's send in your first thing!").yogiText(.onboardingHeadline).multilineTextAlignment(.center)
                Text("Try saving from your favorite social media app, we'll show you how.")
                    .font(.yogiSans(17)).foregroundStyle(YogiColor.inkSecondary).multilineTextAlignment(.center).padding(.horizontal, 24)
                VStack(spacing: 8) {
                    Text("Which platform would you like to send things from?").font(.yogiSans(15, weight: .semibold)).foregroundStyle(YogiColor.ink)
                    ForEach(SourcePlatform.importable, id: \.self) { p in
                        Button { platform = p } label: {
                            HStack(spacing: 12) { Text(p.emoji); Text(p.title).font(.yogiSans(17)).foregroundStyle(YogiColor.ink); Spacer() }
                                .padding(.horizontal, 18).frame(height: 50).background(YogiColor.optionFill, in: Capsule())
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                Button("Maybe later") { app.hasSeenFirstImportCoach = true; dismiss() }.font(.yogiSans(17)).foregroundStyle(YogiColor.inkSecondary).padding(.bottom, 12)
            }
            Spacer(minLength: 0)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .overlay {
            if showGreatJob {
                GreatJobCard { app.hasSeenFirstImportCoach = true; dismiss() }
            }
        }
    }

    private func finish() {
        withAnimation(.spring(duration: 0.35)) { showGreatJob = true }
    }
}

/// Direct messages live behind the send icon; empty until you have friends (Albo #130).
struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showFriends = false
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 22, weight: .semibold)).foregroundStyle(YogiColor.ink).frame(width: 44, height: 44) }
                Spacer()
                Text("Chat").font(.yogiSans(20, weight: .bold)).foregroundStyle(YogiColor.ink)
                Spacer()
                Button { showFriends = true } label: { Image(systemName: "person.crop.circle.badge.magnifyingglass").font(.system(size: 22)).foregroundStyle(YogiColor.ink).frame(width: 44, height: 44) }
            }
            .padding(.horizontal, 8)
            Spacer()
            ZStack {
                MascotView(variant: .plain).frame(width: 96, height: 96)
                Text("📝").font(.system(size: 54)).offset(x: 26, y: 22)
            }
            Button { showFriends = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "person.crop.circle.badge.magnifyingglass").font(.system(size: 20, weight: .semibold))
                    Text("Find Friends").font(.yogiSans(20, weight: .semibold))
                }
                .foregroundStyle(.white).padding(.horizontal, 28).frame(height: 56)
                .background(YogiColor.ink, in: Capsule())
                .background(Capsule().fill(.black).offset(y: 5))
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.top, 34)
            Spacer()
            Spacer()
        }
        .background(YogiColor.ground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showFriends) { AddFriendsView() }
    }
}

/// "Great job!" confirmation after the first import (Albo #55).
struct GreatJobCard: View {
    let onContinue: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 14) {
                ZStack {
                    Circle().fill(YogiColor.optionFill).frame(width: 84, height: 84)
                    Image(systemName: "checkmark.circle").font(.system(size: 40, weight: .medium)).foregroundStyle(YogiColor.ink)
                }
                .padding(.top, 8)
                Text("Great job!").font(.yogiSans(26, weight: .bold)).foregroundStyle(YogiColor.ink).padding(.top, 10)
                Text("We detected that you successfully sent an import. You're all set up!".noOrphans)
                    .font(.yogiSans(17)).foregroundStyle(YogiColor.ink).multilineTextAlignment(.center)
                Button(action: onContinue) {
                    Text("Continue").font(.yogiSans(19, weight: .medium)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(YogiColor.systemBlue, in: Capsule())
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.top, 8)
            }
            .padding(24)
            .frame(width: 300)
            .background(YogiColor.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 24, y: 10)
        }
        .transition(.opacity)
    }
}
