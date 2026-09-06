import SwiftUI

enum LibraryRoute: Hashable {
    case save(UUID)
    case category(SaveCategory)
    case collection(UUID)
    case notifications
    case chat
}

/// Library home (Albo #56, #99): serif header, category chips, Recently saved, Collections, Ask Albo FAB.
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
            .background(AlboColor.ground)
            .overlay(alignment: .bottomTrailing) {
                AskAlboFAB { app.showAskAlbo = true }.padding(.trailing, 20).padding(.bottom, 16)
            }
            .navigationDestination(for: LibraryRoute.self) { route in
                switch route {
                case .save(let id): SaveDetailView(saveID: id)
                case .category(let c): CategoryView(category: c)
                case .collection(let id): CollectionDetailView(collectionID: id)
                case .notifications: NotificationsView()
                case .chat: ChatView()
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
            Text("Library").alboText(.screenTitle)
            Spacer()
            Button { path.append(LibraryRoute.notifications) } label: {
                Image(systemName: "bell").font(.system(size: 24)).foregroundStyle(AlboColor.ink)
                    .overlay(alignment: .topTrailing) {
                        if !app.notifications.isEmpty { Circle().fill(AlboColor.danger).frame(width: 9, height: 9).offset(x: 2, y: -2) }
                    }
            }
            .accessibilityLabel("Notifications")
            .padding(.trailing, 18)
            Button { path.append(LibraryRoute.chat) } label: {
                Image(systemName: "paperplane").font(.system(size: 24)).foregroundStyle(AlboColor.ink)
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
                            Text(c.pluralTitle).font(.alboSans(16)).foregroundStyle(AlboColor.inkSecondary)
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
                    RoundedRectangle(cornerRadius: 14).stroke(AlboColor.hairline, style: StrokeStyle(lineWidth: 2, dash: [6, 5])).frame(width: 110, height: 150)
                        .overlay(Text("?").font(.alboSans(30)).foregroundStyle(AlboColor.muted))
                    VStack(alignment: .leading, spacing: 8) {
                        Text("You have no saves").font(.alboSans(18, weight: .semibold)).foregroundStyle(AlboColor.ink)
                        Text("The content you share to albo will appear here.").font(.alboSans(15)).foregroundStyle(AlboColor.muted)
                        Button("Show me how") { showFirstImportCoach = true }.font(.alboSans(15, weight: .semibold)).foregroundStyle(AlboColor.ink)
                            .padding(.horizontal, 16).frame(height: 40).background(AlboColor.optionFill, in: Capsule())
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
            Rectangle().fill(AlboColor.hairline).frame(height: 1).padding(.horizontal, 20)
        }
    }

    private var collectionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Collections", trailing: AnyView(
                Button { showNewCollection = true } label: {
                    HStack(spacing: 4) { Image(systemName: "plus"); Text("New") }.font(.alboSans(18, weight: .semibold)).foregroundStyle(AlboColor.ink)
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
            Text("Get Started").font(.alboSans(17, weight: .semibold)).foregroundStyle(AlboColor.ink)
                .padding(.horizontal, 22).frame(height: 54)
                .background(AlboColor.card, in: Capsule())
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
                .overlay(alignment: .topTrailing) {
                    if pending > 0 {
                        Text("\(pending)").font(.alboSans(12, weight: .bold)).foregroundStyle(.white)
                            .frame(width: 22, height: 22).background(AlboColor.rewardGreen, in: Circle()).offset(x: 4, y: -6)
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
            Text(save.sourcePlatform.cardLabel).font(.alboSans(14)).foregroundStyle(AlboColor.muted)
            Text(save.title).font(.alboSans(17, weight: .semibold)).foregroundStyle(AlboColor.ink).lineLimit(2).multilineTextAlignment(.leading)
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
                    Text(save.title).font(.alboSans(15, weight: .semibold)).foregroundStyle(AlboColor.ink)
                    Text(body).font(.alboSans(12)).foregroundStyle(AlboColor.inkSecondary).lineLimit(4)
                }
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else if let e = save.coverEmoji {
                Text(e).font(.system(size: 44)).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Image(systemName: "photo").font(.system(size: 28)).foregroundStyle(AlboColor.muted).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            if save.isImporting {
                ProgressView().padding(8)
            } else if save.category != .image {
                Text(save.category.emoji).font(.system(size: 18)).padding(6)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).stroke(AlboColor.hairline, lineWidth: 0.5))
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
                    Text(collection.isPublic ? "Public" : "Private").font(.alboSans(14))
                }
                .foregroundStyle(AlboColor.muted)
                Text(collection.name).font(.alboSans(20, weight: .bold)).foregroundStyle(AlboColor.ink)
                HStack(spacing: 6) {
                    AvatarView(user: collection.owner, size: 22)
                    Text(collection.owner.name).font(.alboSans(14)).foregroundStyle(AlboColor.inkSecondary)
                }
            }
            Spacer()
            Image(systemName: "ellipsis").font(.system(size: 20, weight: .bold)).foregroundStyle(AlboColor.ink)
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
                            Text(c.name).alboText(.screenTitle)
                            if let d = c.details, !d.isEmpty { Text(d).font(.alboSans(16)).foregroundStyle(AlboColor.inkSecondary) }
                            HStack(spacing: 8) {
                                TagChip(title: c.isPublic ? "Public" : "Private", systemImage: c.isPublic ? "globe" : "lock.fill")
                                Text("\(c.saveIDs.count) saves").font(.alboSans(15)).foregroundStyle(AlboColor.muted)
                            }
                        }
                        Spacer()
                        RoundedRectangle(cornerRadius: 16).fill(Color(hex: c.coverTint)).frame(width: 72, height: 72).overlay(Text(c.coverEmoji).font(.system(size: 30)))
                    }
                    HStack(spacing: 10) {
                        if let url = c.inviteURL {
                            ShareLink(item: url) {
                                HStack(spacing: 6) { Image(systemName: "person.badge.plus"); Text("Invite friends") }
                                    .font(.alboSans(16, weight: .semibold)).foregroundStyle(AlboColor.ink)
                                    .padding(.horizontal, 18).frame(height: 48).background(Capsule().stroke(AlboColor.hairline, lineWidth: 1.5))
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
        .background(AlboColor.ground)
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
                                Image(systemName: "bell.fill").font(.system(size: 20)).foregroundStyle(AlboColor.ink).padding(.top, 2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(n.title).font(.alboSans(17, weight: .bold)).foregroundStyle(AlboColor.ink)
                                    Text(n.body).font(.alboSans(15)).foregroundStyle(AlboColor.inkSecondary).lineLimit(2)
                                    Text(n.createdAt, style: .relative).font(.alboSans(13)).foregroundStyle(AlboColor.muted) + Text(" ago").font(.alboSans(13)).foregroundStyle(AlboColor.muted)
                                }
                                Spacer()
                            }
                            .padding(16)
                            .background(AlboColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
            }
            .padding(20)
        }
        .background(AlboColor.ground)
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
            Capsule().fill(AlboColor.hairline).frame(width: 40, height: 5).padding(.top, 8)
            if let platform {
                VStack(spacing: 16) {
                    HStack {
                        Button { self.platform = nil } label: { Image(systemName: "arrow.left").font(.system(size: 20, weight: .medium)).foregroundStyle(AlboColor.ink) }
                        Spacer()
                    }
                    Text("How to share from \(platform.title)").alboText(.onboardingHeadline).multilineTextAlignment(.center)
                    Text(platform.emoji).font(.system(size: 64))
                    Text("Open \(platform.title), tap Share, then choose Albo. We'll detect the import and set you up.")
                        .font(.alboSans(16)).foregroundStyle(AlboColor.inkSecondary).multilineTextAlignment(.center)
                    PrimaryButton(title: "View video instruction & setup") { finish() }
                    Button("I prefer text instructions") { finish() }.font(.alboSans(16)).foregroundStyle(AlboColor.inkSecondary)
                }
                .padding(.horizontal, 24)
            } else {
                Text("📺📸📘").font(.system(size: 64)).padding(.top, 20)
                Text("Let's send in your first thing!").alboText(.onboardingHeadline).multilineTextAlignment(.center)
                Text("Try saving from your favorite social media app, we'll show you how.")
                    .font(.alboSans(17)).foregroundStyle(AlboColor.inkSecondary).multilineTextAlignment(.center).padding(.horizontal, 24)
                VStack(spacing: 8) {
                    Text("Which platform would you like to send things from?").font(.alboSans(15, weight: .semibold)).foregroundStyle(AlboColor.ink)
                    ForEach(SourcePlatform.importable, id: \.self) { p in
                        Button { platform = p } label: {
                            HStack(spacing: 12) { Text(p.emoji); Text(p.title).font(.alboSans(17)).foregroundStyle(AlboColor.ink); Spacer() }
                                .padding(.horizontal, 18).frame(height: 50).background(AlboColor.optionFill, in: Capsule())
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                Button("Maybe later") { app.hasSeenFirstImportCoach = true; dismiss() }.font(.alboSans(17)).foregroundStyle(AlboColor.inkSecondary).padding(.bottom, 12)
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
                Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 22, weight: .semibold)).foregroundStyle(AlboColor.ink).frame(width: 44, height: 44) }
                Spacer()
                Text("Chat").font(.alboSans(20, weight: .bold)).foregroundStyle(AlboColor.ink)
                Spacer()
                Button { showFriends = true } label: { Image(systemName: "person.crop.circle.badge.magnifyingglass").font(.system(size: 22)).foregroundStyle(AlboColor.ink).frame(width: 44, height: 44) }
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
                    Text("Find Friends").font(.alboSans(20, weight: .semibold))
                }
                .foregroundStyle(.white).padding(.horizontal, 28).frame(height: 56)
                .background(AlboColor.ink, in: Capsule())
                .background(Capsule().fill(.black).offset(y: 5))
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.top, 34)
            Spacer()
            Spacer()
        }
        .background(AlboColor.ground.ignoresSafeArea())
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
                    Circle().fill(AlboColor.optionFill).frame(width: 84, height: 84)
                    Image(systemName: "checkmark.circle").font(.system(size: 40, weight: .medium)).foregroundStyle(AlboColor.ink)
                }
                .padding(.top, 8)
                Text("Great job!").font(.alboSans(26, weight: .bold)).foregroundStyle(AlboColor.ink).padding(.top, 10)
                Text("We detected that you successfully sent an import. You're all set up!".noOrphans)
                    .font(.alboSans(17)).foregroundStyle(AlboColor.ink).multilineTextAlignment(.center)
                Button(action: onContinue) {
                    Text("Continue").font(.alboSans(19, weight: .medium)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(AlboColor.systemBlue, in: Capsule())
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.top, 8)
            }
            .padding(24)
            .frame(width: 300)
            .background(AlboColor.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 24, y: 10)
        }
        .transition(.opacity)
    }
}
