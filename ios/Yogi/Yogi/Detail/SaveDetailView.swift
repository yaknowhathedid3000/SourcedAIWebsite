import SwiftUI
import MapKit
import EventKit
import EventKitUI

/// Item detail for every category (teardown chapter 8; Albo #69, #85 to #92, #121, #132, #137, #157, #167).
struct SaveDetailView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let saveID: UUID

    @State private var multiplier = 1
    @State private var converted = false
    @State private var showActions = false
    @State private var showReview = false
    @State private var showCollections = false
    @State private var showAsk = false
    @State private var noteDraft = ""
    @State private var editingNote = false
    @State private var commentDraft = ""
    @State private var showEventEditor = false
    @State private var showMap = false

    var body: some View {
        Group {
            if let save = app.save(saveID) {
                content(save)
            } else {
                EmptyStateView(systemImage: "tray", title: "This save was removed")
            }
        }
        .background(YogiColor.ground)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func content(_ save: Save) -> some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if save.coverEmoji != nil && save.category != .note {
                        HeroHeader(save: save)
                    } else {
                        ZStack(alignment: .topLeading) {
                            if save.category == .recipe { CutleryWatermark().frame(height: 120) }
                            Text(save.title).yogiText(.itemTitle).padding(.horizontal, 20).padding(.top, 12)
                        }
                    }
                    VStack(alignment: .leading, spacing: 22) {
                        metaBlock(save)
                        switch save.category {
                        case .recipe: recipeBody(save)
                        case .place: placeBody(save)
                        case .event: eventBody(save)
                        case .note: noteBody(save)
                        default: genericBody(save)
                        }
                        mentionedIn(save)
                        notesBlock(save)
                        commentsBlock(save)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 120)
                }
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .top, spacing: 0) { topBar(save) }
            AskYogiFAB { showAsk = true }.padding(.trailing, 20).padding(.bottom, 20)
        }
        .sheet(isPresented: $showActions) { ItemActionsSheet(saveID: saveID) }
        .sheet(isPresented: $showReview) { ReviewFormView(saveID: saveID) }
        .sheet(isPresented: $showCollections) { AddToCollectionSheet(saveIDs: [saveID]) }
        .sheet(isPresented: $showAsk) { AskYogiSheet(scope: save) }
        .sheet(isPresented: $showEventEditor) {
            if let e = save.event { EventEditView(title: save.title, details: e) }
        }
        .sheet(isPresented: $showMap) { PlaceMapSheet(save: save) }
    }

    // MARK: Top bar: back, inline title, share, kebab (Albo #86)

    private func topBar(_ save: Save) -> some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 22, weight: .semibold)).foregroundStyle(YogiColor.ink).frame(width: 36, height: 36) }
                .buttonStyle(.plain).accessibilityLabel("Back")
            Text(save.title).font(.yogiSans(20, weight: .bold)).foregroundStyle(YogiColor.ink).lineLimit(1)
                .opacity(save.coverEmoji == nil || save.category == .note ? 0 : 1)
            Spacer()
            ShareLink(item: save.sourceURL ?? URL(string: "https://yogi.app")!) {
                Image(systemName: "square.and.arrow.up").font(.system(size: 22)).foregroundStyle(YogiColor.ink).frame(width: 36, height: 36)
            }
            Button { showActions = true } label: { Image(systemName: "ellipsis").font(.system(size: 22, weight: .bold)).foregroundStyle(YogiColor.ink).rotationEffect(.degrees(90)).frame(width: 36, height: 36) }
                .buttonStyle(.plain).accessibilityLabel("More")
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(save.coverEmoji == nil || save.category == .note ? YogiColor.ground : Color.clear)
    }

    // MARK: Meta, saves, collections, done slider, wanna

    @ViewBuilder
    private func metaBlock(_ save: Save) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Text(save.metaEmoji).font(.system(size: 20))
                Text(save.metaLine).font(.yogiSans(18)).foregroundStyle(YogiColor.inkSecondary).lineLimit(2)
            }
            HStack(spacing: 10) {
                if !save.savedBy.isEmpty { AvatarStack(users: save.savedBy) }
                Text("\(save.saveCount) save\(save.saveCount == 1 ? "" : "s")").font(.yogiSans(16)).foregroundStyle(YogiColor.inkSecondary)
                ForEach(save.reactions) { r in
                    HStack(spacing: 4) { Text(r.emoji); Text("\(r.count)") }.font(.yogiSans(14)).foregroundStyle(YogiColor.ink)
                        .padding(.horizontal, 10).frame(height: 32).background(YogiColor.optionFill, in: Capsule())
                }
                Spacer(minLength: 4)
                OutlinePill(title: "Collections", systemImage: "plus") { showCollections = true }
            }
            if let review = app.latestReview(for: save.id) {
                statusRow(save, review)
            } else {
                HStack(spacing: 14) {
                    SlideToConfirm(title: save.category.doneQuestion) { showReview = true }
                        .frame(maxWidth: 240)
                    Spacer(minLength: 0)
                    OutlinePill(title: "Wanna", systemImage: "megaphone") { app.setWant(save.id) }
                }
            }
            if save.category == .event {
                HStack(spacing: 12) {
                    OutlinePill(title: "Add to calendar", systemImage: "calendar.badge.plus") { requestCalendar() }
                    OutlinePill(title: "Wanna", systemImage: "megaphone") { app.setWant(save.id) }
                }
            }
        }
    }

    /// "Hidden Gem" badge card plus the review card (Albo #85, #132).
    private func statusRow(_ save: Save, _ review: Review) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 10) {
                    Text(review.sentiment.emoji)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(review.sentiment.badgeTitle).font(.yogiSans(17, weight: .bold)).foregroundStyle(YogiColor.ink)
                        Text(review.createdAt, style: .relative).font(.yogiSans(13)).foregroundStyle(YogiColor.muted)
                    }
                    Button { showReview = true } label: { Image(systemName: "arrow.clockwise").font(.system(size: 14, weight: .semibold)).foregroundStyle(YogiColor.inkSecondary) }
                        .buttonStyle(.plain)
                }
                .padding(.horizontal, 16).frame(height: 56)
                .background(YogiColor.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                Spacer()
                OutlinePill(title: "Wanna", systemImage: "megaphone") { app.setWant(save.id) }
            }
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reviewed \(save.title) - \(review.sentiment.journalSuffix)").font(.yogiDisplayItalic(17, weight: .semibold)).foregroundStyle(YogiColor.ink)
                    HStack(spacing: 8) {
                        StaticStars(rating: review.stars ?? 0, color: YogiColor.ink, size: 14)
                        if let d = review.completedOn { Text(d, format: .dateTime.day().month()).font(.yogiSans(13)).foregroundStyle(YogiColor.muted) }
                    }
                    if let t = review.title { Text(t).font(.yogiSans(15)).foregroundStyle(YogiColor.inkSecondary) }
                }
                Spacer()
                if review.photoCount > 0 {
                    RoundedRectangle(cornerRadius: 10).fill(Color(hex: save.coverTint)).frame(width: 56, height: 56).overlay(Text(save.coverEmoji ?? "📷"))
                }
            }
            .padding(16)
            .background(YogiColor.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        }
    }

    // MARK: Recipe (Albo #69, #86)

    @ViewBuilder
    private func recipeBody(_ save: Save) -> some View {
        if let r = save.recipe, let binding = app.binding(for: save.id) {
            if let yield = r.yieldLabel {
                HStack(spacing: 12) {
                    Image(systemName: "fork.knife").font(.system(size: 20)).foregroundStyle(YogiColor.inkSecondary)
                    Text(yield).font(.yogiSans(18)).foregroundStyle(YogiColor.inkSecondary)
                }
            }
            VStack(alignment: .leading, spacing: 16) {
                CopyableHeading(title: "Ingredients", payload: r.ingredients.map { "\($0.name) \($0.quantityLabel(multiplier: multiplier) ?? "")" }.joined(separator: "\n"))
                ServingMultiplier(multiplier: $multiplier, converted: $converted, showsConvert: true)
                if r.ingredients.isEmpty {
                    Text("No ingredients were extracted. Use Reanalyze on the source note or report a bad extract.")
                        .font(.yogiSans(15)).foregroundStyle(YogiColor.muted)
                } else {
                    ForEach(r.ingredients.indices, id: \.self) { i in
                        IngredientRow(ingredient: r.ingredients[i], multiplier: multiplier, converted: converted) {
                            binding.wrappedValue.recipe?.ingredients[i].checked.toggle()
                        }
                    }
                }
            }
            if !r.steps.isEmpty {
                VStack(alignment: .leading, spacing: 18) {
                    CopyableHeading(title: "Instructions", payload: r.steps.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
                    ForEach(r.steps.indices, id: \.self) { i in
                        HStack(alignment: .top, spacing: 16) {
                            Text(i < r.stepEmoji.count ? r.stepEmoji[i] : "•").font(.system(size: 22)).frame(width: 28)
                            Text(r.steps[i]).font(.yogiSans(18)).foregroundStyle(YogiColor.ink).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    // MARK: Place (Albo #137)

    @ViewBuilder
    private func placeBody(_ save: Save) -> some View {
        if let p = save.place {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ActionChip(systemImage: "safari", title: "View on map") { showMap = true }
                    if let phone = p.phone, let url = URL(string: "tel:\(phone.filter { $0.isNumber || $0 == "+" })") {
                        Link(destination: url) { chipLabel("phone", "Call") }
                    }
                    if let site = p.website { Link(destination: site) { chipLabel("link", "Website") } }
                    ActionChip(systemImage: "ellipsis", title: "More") { showActions = true }
                }
            }
            .padding(.horizontal, -20).padding(.leading, 20)
            if let hours = p.hoursLabel {
                HStack { Text(hours).font(.yogiSans(18)).foregroundStyle(YogiColor.inkSecondary); Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundStyle(YogiColor.inkSecondary) }
            } else {
                Text("No opening times found").font(.yogiSans(18)).foregroundStyle(YogiColor.muted)
            }
            if !p.photoEmoji.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(p.photoEmoji.enumerated()), id: \.offset) { _, e in
                            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: save.coverTint)).frame(width: 190, height: 230).overlay(Text(e).font(.system(size: 60)))
                        }
                    }
                }
                .padding(.horizontal, -20).padding(.leading, 20)
            }
            if let about = p.about {
                (Text(about).foregroundStyle(YogiColor.inkSecondary) + Text(" Read more").fontWeight(.bold).foregroundStyle(YogiColor.ink))
                    .font(.yogiSans(17)).lineLimit(3)
            }
            MapSnippet(latitude: p.latitude, longitude: p.longitude, label: p.neighborhood, emoji: p.emoji) { showMap = true }
        }
    }

    private func chipLabel(_ symbol: String, _ title: String) -> some View {
        HStack(spacing: 8) { Image(systemName: symbol).font(.system(size: 16)); Text(title).font(.yogiSans(17, weight: .medium)) }
            .foregroundStyle(YogiColor.ink).padding(.horizontal, 18).frame(height: 52)
            .background(YogiColor.optionFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: Event (Albo #167)

    @ViewBuilder
    private func eventBody(_ save: Save) -> some View {
        if let e = save.event {
            if let about = e.about { Text(about).font(.yogiSans(17)).foregroundStyle(YogiColor.inkSecondary) }
            HStack(spacing: 12) {
                Image(systemName: "calendar").font(.system(size: 20)).foregroundStyle(YogiColor.inkSecondary)
                Text("Starts on \(e.start.formatted(.dateTime.month(.abbreviated).day().year())) at \(e.start.formatted(.dateTime.hour().minute()))").font(.yogiSans(17)).foregroundStyle(YogiColor.ink)
            }
            if let address = e.address {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "mappin.and.ellipse").font(.system(size: 20)).foregroundStyle(YogiColor.inkSecondary)
                    Text(address).font(.yogiSans(17)).foregroundStyle(YogiColor.ink)
                }
            }
            if let lat = e.latitude, let lon = e.longitude {
                MapSnippet(latitude: lat, longitude: lon, label: nil, emoji: "🎟️") { showMap = true }
            }
        }
    }

    // MARK: Note (Albo #68 read-only view)

    @ViewBuilder
    private func noteBody(_ save: Save) -> some View {
        if let body = save.noteBody {
            if let attributed = try? AttributedString(markdown: body, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                Text(attributed).font(.yogiSans(18)).foregroundStyle(YogiColor.ink)
            } else {
                Text(body).font(.yogiSans(18)).foregroundStyle(YogiColor.ink)
            }
            let found = app.saves.filter { $0.mentionedInNoteID == save.id }
            if !found.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Things Yogi found").font(.yogiSans(20, weight: .bold)).foregroundStyle(YogiColor.ink)
                    ForEach(found) { f in
                        NavigationLink(value: LibraryRoute.save(f.id)) { SaveRow(save: f, onMenu: nil) }.buttonStyle(PressableButtonStyle())
                    }
                }
            }
        }
    }

    // MARK: Generic (book, film, workout, article, product...)

    @ViewBuilder
    private func genericBody(_ save: Save) -> some View {
        if let m = save.media, !m.tags.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) { ForEach(m.tags, id: \.self) { TagChip(title: $0) } }
            }
        }
        if let url = save.sourceURL {
            Link(destination: url) {
                HStack(spacing: 10) {
                    Image(systemName: "safari").font(.system(size: 18))
                    Text(url.host ?? "Open link").font(.yogiSans(17, weight: .medium))
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(YogiColor.ink)
                .padding(18)
                .background(YogiColor.optionFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        if let subtitle = save.subtitle, save.media?.author == nil {
            Text(subtitle).font(.yogiSans(17)).foregroundStyle(YogiColor.inkSecondary)
        }
    }

    // MARK: Mentioned in (Albo #86, #88)

    @ViewBuilder
    private func mentionedIn(_ save: Save) -> some View {
        if let noteID = save.mentionedInNoteID, let note = app.save(noteID) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Mentioned in").font(.yogiSans(20, weight: .bold)).foregroundStyle(YogiColor.ink)
                NavigationLink(value: LibraryRoute.save(note.id)) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack { Spacer(); Image(systemName: "bookmark.fill").foregroundStyle(YogiColor.hairline) }
                        Text(note.title).font(.yogiSans(16, weight: .bold)).foregroundStyle(YogiColor.ink).multilineTextAlignment(.leading)
                        Text(note.noteBody ?? "").font(.yogiSans(14)).foregroundStyle(YogiColor.inkSecondary).lineLimit(3).multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .frame(width: 130, height: 170, alignment: .topLeading)
                    .background(YogiColor.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }

    // MARK: Private note (Albo #87, #88)

    @ViewBuilder
    private func notesBlock(_ save: Save) -> some View {
        if let note = save.privateNote, !editingNote {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) { Image(systemName: "lock").font(.system(size: 13)); Text("Private note").font(.yogiSans(15)) }.foregroundStyle(YogiColor.muted)
                Text(note).font(.yogiSans(18)).foregroundStyle(YogiColor.ink)
                Text("a moment ago").font(.yogiSans(14)).foregroundStyle(YogiColor.muted)
            }
            .padding(18)
            .background(YogiColor.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .onTapGesture { noteDraft = note; editingNote = true }
        } else {
            HStack {
                TextField("Add a note...", text: $noteDraft).font(.yogiSans(18))
                Button {
                    app.setPrivateNote(noteDraft, for: save.id)
                    editingNote = false
                } label: { Image(systemName: "plus").font(.system(size: 22)).foregroundStyle(YogiColor.ink) }
                .buttonStyle(.plain)
                .disabled(noteDraft.isEmpty)
                .accessibilityLabel("Save note")
            }
            .padding(.horizontal, 20).frame(height: 62)
            .background(Capsule().stroke(YogiColor.hairline, lineWidth: 1.5))
        }
    }

    // MARK: Comments & Reviews (Albo #87, #88)

    private func commentsBlock(_ save: Save) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Text("Comments & Reviews").font(.yogiSans(22, weight: .bold)).foregroundStyle(YogiColor.ink)
                if !save.comments.isEmpty { Text("\(save.comments.count)").font(.yogiSans(17)).foregroundStyle(YogiColor.inkSecondary) }
            }
            HStack(spacing: 12) {
                AvatarView(user: app.me, size: 44)
                HStack {
                    TextField("Add a comment...", text: $commentDraft).font(.yogiSans(17))
                    Button {
                        app.addComment(commentDraft, to: save.id)
                        commentDraft = ""
                    } label: {
                        Image(systemName: "arrow.up").font(.system(size: 18, weight: .bold)).foregroundStyle(.white).frame(width: 44, height: 44).background(YogiColor.inkSecondary, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(commentDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityLabel("Post comment")
                }
                .padding(.leading, 20).padding(.trailing, 6).frame(height: 56)
                .background(YogiColor.optionFill, in: Capsule())
            }
            if save.comments.isEmpty {
                Text("Be the first to comment!").font(.yogiSans(17)).foregroundStyle(YogiColor.muted)
            } else {
                ForEach(save.comments) { c in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 12) {
                            AvatarView(user: c.author, size: 44)
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(c.author.handle).font(.yogiSans(17, weight: .bold)).foregroundStyle(YogiColor.ink)
                                    Text(c.createdAt, style: .relative).font(.yogiSans(14)).foregroundStyle(YogiColor.muted) + Text(" ago").font(.yogiSans(14)).foregroundStyle(YogiColor.muted)
                                }
                                Text(save.title).font(.yogiSans(15)).foregroundStyle(YogiColor.muted)
                                Text(c.text).font(.yogiSans(17)).foregroundStyle(YogiColor.ink)
                            }
                            Spacer()
                            Menu {
                                Button(role: .destructive) { app.deleteComment(c.id, from: save.id) } label: { Label("Delete", systemImage: "trash") }
                            } label: {
                                Image(systemName: "ellipsis").rotationEffect(.degrees(90)).foregroundStyle(YogiColor.inkSecondary).frame(width: 32, height: 32)
                            }
                        }
                        HStack(spacing: 28) {
                            Image(systemName: "heart"); Image(systemName: "bubble.right"); Image(systemName: "paperplane")
                        }
                        .font(.system(size: 20)).foregroundStyle(YogiColor.ink).padding(.leading, 56)
                        Divider()
                    }
                }
            }
        }
        .padding(.top, 10)
    }

    private func requestCalendar() {
        let store = EKEventStore()
        Task {
            let granted = (try? await store.requestWriteOnlyAccessToEvents()) ?? false
            if granted { showEventEditor = true } else { app.showToast("Calendar access is off in Settings") }
        }
    }
}

// MARK: - Hero header with fade-to-white and serif title (Albo #137, #157)

struct HeroHeader: View {
    let save: Save
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color(hex: save.coverTint).frame(height: 320)
                .overlay(Text(save.coverEmoji ?? "").font(.system(size: 130)))
            LinearGradient(colors: [.clear, YogiColor.ground.opacity(0.6), YogiColor.ground], startPoint: .center, endPoint: .bottom).frame(height: 320)
            if let subtitle = save.subtitle, save.category == .recipe {
                Text(subtitle).font(.system(size: 34, weight: .heavy)).foregroundStyle(.white.opacity(0.85)).padding(20).offset(y: -70)
            }
            Text(save.title).yogiText(.itemTitle).padding(.horizontal, 20).padding(.bottom, 4)
        }
        .frame(height: 320)
        .clipped()
    }
}

/// Faint fork-and-knife pattern behind recipe titles without a cover (Albo #69).
struct CutleryWatermark: View {
    var body: some View {
        GeometryReader { geo in
            let cols = Int(geo.size.width / 44) + 1
            VStack(spacing: 14) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 22) {
                        ForEach(0..<cols, id: \.self) { col in
                            Image(systemName: (row + col) % 2 == 0 ? "fork.knife" : "cup.and.saucer")
                                .font(.system(size: 16))
                                .foregroundStyle(YogiColor.hairline)
                        }
                    }
                    .offset(x: row % 2 == 0 ? 0 : 22)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Serving multiplier (Albo #69 "− 1× + ⇄ Convert", #86 "3× ⇄ Original")

struct ServingMultiplier: View {
    @Binding var multiplier: Int
    var converted: Binding<Bool>? = nil
    var showsConvert: Bool = true

    var body: some View {
        HStack {
            HStack(spacing: 14) {
                stepper("minus") { multiplier = max(1, multiplier - 1) }
                Text("\(multiplier)×").font(.yogiSans(20, weight: .bold)).foregroundStyle(YogiColor.ink).monospacedDigit()
                stepper("plus") { multiplier = min(12, multiplier + 1) }
            }
            Spacer()
            if showsConvert, let converted {
                Button { converted.wrappedValue.toggle() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.left.arrow.right").font(.system(size: 14, weight: .semibold))
                        Text(converted.wrappedValue ? "Original" : "Convert").font(.yogiSans(17, weight: .medium))
                    }
                    .foregroundStyle(YogiColor.ink).padding(.horizontal, 18).frame(height: 48)
                    .background(Capsule().stroke(YogiColor.hairline, lineWidth: 1.5))
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }

    private func stepper(_ symbol: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 18, weight: .medium)).foregroundStyle(YogiColor.ink)
                .frame(width: 48, height: 48).background(YogiColor.optionFill, in: Circle())
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Ingredient row (Albo #86)

struct IngredientRow: View {
    let ingredient: Ingredient
    var multiplier: Int = 1
    var converted: Bool = false
    let onToggle: () -> Void

    private var quantity: String? {
        guard let label = ingredient.quantityLabel(multiplier: multiplier) else { return nil }
        guard converted, let q = ingredient.quantity, let unit = ingredient.unit else { return label }
        // Simple US-to-metric conversions for the most common units.
        let v = q * Double(multiplier)
        switch unit.lowercased() {
        case "cup", "cups": return String(format: "%.0f ml", v * 240)
        case "tsp": return String(format: "%.0f ml", v * 5)
        case "tbsp": return String(format: "%.0f ml", v * 15)
        case "g": return String(format: "%.1f oz", v / 28.35)
        default: return label
        }
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                Image(systemName: ingredient.checked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(ingredient.checked ? YogiColor.ink : YogiColor.inkSecondary)
                Text(ingredient.emoji).font(.system(size: 18)).opacity(ingredient.checked ? 0.4 : 1)
                (Text(ingredient.name).fontWeight(.bold) + Text(quantity.map { " - \($0)" } ?? ""))
                    .font(.yogiSans(18))
                    .foregroundStyle(ingredient.checked ? YogiColor.muted : YogiColor.ink)
                    .strikethrough(ingredient.checked, color: YogiColor.muted)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(ingredient.checked ? .isSelected : [])
    }
}

// MARK: - Map snippet at the bottom of place and event detail (Albo #137)

struct MapSnippet: View {
    let latitude: Double
    let longitude: Double
    let label: String?
    let emoji: String
    let onTap: () -> Void

    var body: some View {
        let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        Button(action: onTap) {
            Map(initialPosition: .region(MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)))) {
                Annotation("", coordinate: coord) {
                    Text(emoji).font(.system(size: 22)).padding(6).background(YogiColor.card, in: Circle()).shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                }
            }
            .mapControlVisibility(.hidden)
            .allowsHitTesting(false)
            .frame(height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if let label { Text(label).font(.yogiSans(12, weight: .semibold)).tracking(1).foregroundStyle(YogiColor.inkSecondary).padding(10) }
            }
            .overlay(alignment: .topLeading) {
                Image(systemName: "globe").font(.system(size: 18)).foregroundStyle(YogiColor.ink).padding(8).background(YogiColor.card, in: Circle()).padding(10)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Full-screen map for one place.
struct PlaceMapSheet: View {
    @Environment(\.dismiss) private var dismiss
    let save: Save
    var body: some View {
        let lat = save.place?.latitude ?? save.event?.latitude ?? 0
        let lon = save.place?.longitude ?? save.event?.longitude ?? 0
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        ZStack(alignment: .topTrailing) {
            Map(initialPosition: .region(MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)))) {
                Annotation(save.title, coordinate: coord) {
                    Text(save.place?.emoji ?? "📍").font(.system(size: 24)).padding(8).background(YogiColor.card, in: Circle()).shadow(color: .black.opacity(0.2), radius: 5, y: 2)
                }
            }
            .ignoresSafeArea()
            Button { dismiss() } label: { Image(systemName: "xmark").font(.system(size: 18, weight: .semibold)).foregroundStyle(YogiColor.ink).frame(width: 44, height: 44).background(YogiColor.card, in: Circle()) }
                .padding(20)
        }
    }
}

// MARK: - EventKit editor (Albo #169)

struct EventEditView: UIViewControllerRepresentable {
    let title: String
    let details: EventDetails
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let store = EKEventStore()
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = details.start
        event.endDate = details.end ?? details.start.addingTimeInterval(3600)
        event.location = details.address ?? details.venue
        event.notes = details.about
        let vc = EKEventEditViewController()
        vc.eventStore = store
        vc.event = event
        vc.editViewDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(dismiss: dismiss) }

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        let dismiss: DismissAction
        init(dismiss: DismissAction) { self.dismiss = dismiss }
        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            dismiss()
        }
    }
}
