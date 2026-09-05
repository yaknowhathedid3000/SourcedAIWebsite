import SwiftUI
import PhotosUI

/// "Add anything" hub (Albo #60): six cards, then "OR MANUALLY SEARCH THESE".
struct AddAnythingSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    enum Route: Hashable { case link, note, screenshots, bulk, review, list, search(SaveCategory) }
    @State private var route: Route? = nil

    private let cards: [(Route, String, String, String)] = [
        (.link, "🔗", "Paste any URL", "Articles, blogs, TikTok, Instagram & more"),
        (.note, "📝", "Notes", "Make a note of anything and we'll analyse it"),
        (.screenshots, "📷", "Screenshots", "Add from your camera roll"),
        (.bulk, "📦", "Bulk Import", "Add everything from TikTok & Insta in one click"),
        (.review, "⭐️", "Review", "Rate something you watched, read, or visited"),
        (.list, "📼", "List", "Build a curated ranked list of items"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Capsule().fill(AlboColor.hairline).frame(width: 40, height: 5).frame(maxWidth: .infinity).padding(.top, 8)
                    Text("Add anything").alboText(.sheetTitle)
                    Text(orphanSafe: "Search up anything you want to save or you have done!").font(.alboSans(16)).foregroundStyle(AlboColor.inkSecondary)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                        ForEach(cards, id: \.2) { card in
                            Button { route = card.0 } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(card.1).font(.system(size: 44))
                                    Text(card.2).font(.alboSans(18, weight: .bold)).foregroundStyle(AlboColor.ink)
                                    Text(card.3).font(.alboSans(13)).foregroundStyle(AlboColor.muted).lineLimit(2).multilineTextAlignment(.leading)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, minHeight: 168, alignment: .topLeading)
                                .background(AlboColor.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .shadow(color: .black.opacity(0.06), radius: 14, y: 6)
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }
                    DividerLabel(text: "Or manually search these").padding(.top, 8)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 22) {
                            ForEach(SaveCategory.browsable) { c in
                                Button { route = .search(c) } label: {
                                    VStack(spacing: 8) {
                                        ZStack(alignment: .bottomTrailing) {
                                            CategoryIcon(category: c, size: 62).background(AlboColor.optionFill, in: Circle())
                                            Image(systemName: "magnifyingglass").font(.system(size: 11, weight: .bold)).foregroundStyle(.white).frame(width: 22, height: 22).background(AlboColor.ink, in: Circle())
                                        }
                                        Text(c.pluralTitle).font(.alboSans(14)).foregroundStyle(AlboColor.inkSecondary)
                                    }
                                }
                                .buttonStyle(PressableButtonStyle())
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 30)
            }
            .background(AlboColor.ground)
            .navigationDestination(item: $route) { r in
                switch r {
                case .link: ImportLinkSheet()
                case .note: NoteEditorView(existing: nil)
                case .screenshots: ImportScreenshotSheet()
                case .bulk: BulkImportGuide()
                case .review: ReviewCategoryPicker()
                case .list: ListTypePicker()
                case .search(let c): CategorySearchSheet(category: c, mode: .save)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Import via Link (Albo #61 to #66)

struct ImportLinkSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var link = ""
    @State private var page = 0
    @State private var importing = false

    private let steps: [(String, String, String)] = [
        ("Click on", "Share", "Find the share menu"),
        ("Click on", "More", "Tap \"Send to\" Albo"),
        ("Click on", "Albo", "Detecting Spots."),
        ("Organise into", "collections", "You're all set"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "Import via Link", onBack: { dismiss() })
            TabView(selection: $page) {
                ForEach(Array(steps.enumerated()), id: \.offset) { i, s in
                    VStack(spacing: 24) {
                        ZStack(alignment: .top) {
                            PhoneMockup(width: 220) {
                                ZStack(alignment: .bottomTrailing) {
                                    LinearGradient(colors: [Color(hex: 0x2A9D8F), Color(hex: 0x8ECAE6)], startPoint: .top, endPoint: .bottom)
                                    VStack(alignment: .trailing, spacing: 14) {
                                        Text("♥").font(.system(size: 22)); Text("💬"); Text("🔖"); Text("➤").font(.system(size: 22))
                                    }
                                    .foregroundStyle(.white).padding(.trailing, 12).padding(.bottom, 80)
                                    Text("Tap").font(.alboSans(13, weight: .bold)).foregroundStyle(AlboColor.ink).padding(.horizontal, 12).padding(.vertical, 6).background(AlboColor.card, in: Capsule()).offset(x: -34, y: -96)
                                }
                            }
                            HStack(spacing: 4) {
                                Text("🎵 TikTok").font(.alboSans(15, weight: .semibold)).foregroundStyle(AlboColor.ink).padding(.horizontal, 14).frame(height: 40).background(AlboColor.card, in: Capsule())
                                Text("📸 Insta").font(.alboSans(15, weight: .semibold)).foregroundStyle(AlboColor.inkSecondary).padding(.horizontal, 14).frame(height: 40)
                            }
                            .padding(4).background(AlboColor.optionFill.opacity(0.9), in: Capsule()).offset(y: 26)
                        }
                        HStack(spacing: 8) {
                            Text(s.0).font(.alboDisplay(28))
                            Image(systemName: i == 2 ? "circle.fill" : "arrowshape.turn.up.right.fill").font(.system(size: 22))
                            Text(s.1).font(.alboDisplayItalic(28, weight: .bold))
                        }
                        .foregroundStyle(AlboColor.ink)
                    }
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { i in Capsule().fill(i <= page ? AlboColor.ink : AlboColor.optionFill).frame(height: 5) }
            }
            .padding(.horizontal, 20)
            Text(steps[page].2).alboText(.onboardingHeadline).multilineTextAlignment(.center).padding(.top, 20)
            HStack(spacing: 10) {
                TextField("Paste your link here", text: $link).font(.alboSans(18)).textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                if link.isEmpty {
                    PasteButton(payloadType: String.self) { strings in if let s = strings.first { link = s } }
                        .labelStyle(.titleOnly)
                        .buttonBorderShape(.capsule)
                        .tint(AlboColor.optionFill)
                } else {
                    Button { importLink() } label: {
                        Text("Import").font(.alboSans(17, weight: .semibold)).foregroundStyle(.white).padding(.horizontal, 20).frame(height: 48).background(AlboColor.ink, in: Capsule())
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(.leading, 20).padding(.trailing, 8).frame(height: 72)
            .background(AlboColor.optionFill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding(20)
        }
        .background(AlboColor.ground)
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            if importing {
                VStack(spacing: 14) {
                    ProgressView().controlSize(.large)
                    Text("Importing...").font(.alboSans(18, weight: .semibold))
                    Text("watching everything at 2x speed").font(.alboSans(14)).foregroundStyle(AlboColor.muted)
                }
                .padding(28).background(AlboColor.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous)).shadow(color: .black.opacity(0.2), radius: 20, y: 10)
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.2))
                withAnimation { page = (page + 1) % steps.count }
            }
        }
    }

    private func importLink() {
        var text = link.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.hasPrefix("http") { text = "https://" + text }
        guard let url = URL(string: text) else { app.showToast("That doesn't look like a link"); return }
        importing = true
        Task {
            do {
                let save = try await ImportService.extract(from: url)
                app.add(save)
                app.showToast("Saved \(save.title)")
                app.showAddSheet = false
            } catch {
                app.showToast(error.localizedDescription)
                if case BackendError.outOfCredits = error { app.showPaywall = true }
            }
            importing = false
        }
    }
}

// MARK: - Import via Screenshot (Albo #96 to #98)

struct ImportScreenshotSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var items: [PhotosPickerItem] = []
    @State private var showPicker = false
    @State private var importing = false

    var body: some View {
        VStack(spacing: 20) {
            SheetHeader(title: "Import via Screenshot", onBack: { dismiss() })
            if items.isEmpty {
                Button { showPicker = true } label: {
                    VStack(spacing: 18) {
                        RoundedRectangle(cornerRadius: 24, style: .continuous).fill(AlboColor.optionFill).frame(width: 130, height: 130)
                            .overlay(Image(systemName: "plus").font(.system(size: 40, weight: .medium)).foregroundStyle(AlboColor.inkSecondary))
                        Text("Tap to select from camera roll").font(.alboSans(17)).foregroundStyle(AlboColor.inkSecondary)
                    }
                    .frame(maxWidth: .infinity).frame(height: 340)
                    .background(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(AlboColor.hairline, style: StrokeStyle(lineWidth: 2, dash: [8, 6])))
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 12) {
                    Text("TIPS").font(.alboSans(13, weight: .bold)).tracking(1.5).foregroundStyle(.white).padding(.horizontal, 12).frame(height: 30).background(Color(hex: 0xE08A2E), in: RoundedRectangle(cornerRadius: 8))
                    Text("You can import anything from").font(.alboSans(18, weight: .bold)).foregroundStyle(Color(hex: 0xC9731C))
                    ForEach(["Conversations about plans", "Google Maps lists", "TikTok screenshots etc"], id: \.self) { t in
                        Text("- \(t)").font(.alboSans(17)).foregroundStyle(Color(hex: 0xC9731C))
                    }
                }
                .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: 0xFCEBD5), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Imports").font(.alboSans(22, weight: .bold)).foregroundStyle(AlboColor.ink)
                        Spacer()
                        Text("\(items.count)/9").font(.alboSans(17, weight: .semibold)).foregroundStyle(AlboColor.ink).padding(.horizontal, 14).frame(height: 36).background(AlboColor.optionFill, in: Capsule())
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(items.indices, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AlboColor.optionFill).frame(width: 130, height: 172)
                                    .overlay(Text("🖼️").font(.system(size: 40)))
                                    .overlay(alignment: .topTrailing) {
                                        Button { items.remove(at: i) } label: {
                                            Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(.white).frame(width: 30, height: 30).background(Color.black.opacity(0.7), in: Circle())
                                        }
                                        .padding(6)
                                    }
                            }
                        }
                    }
                }
                .padding(18).background(AlboColor.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous)).shadow(color: .black.opacity(0.06), radius: 14, y: 6)
                Button { showPicker = true } label: {
                    Text("+ Add More Pictures").font(.alboSans(17, weight: .semibold)).foregroundStyle(AlboColor.ink).padding(.horizontal, 22).frame(height: 50).background(AlboColor.optionFill, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(items.count >= 9)
            }
            Spacer()
            if items.isEmpty {
                SecondaryButton(title: "Choose Photos") { showPicker = true }
            } else {
                PrimaryButton(title: "Import", isLoading: importing) { runImport() }
            }
        }
        .padding(.horizontal, 20).padding(.bottom, 12)
        .background(AlboColor.ground)
        .toolbar(.hidden, for: .navigationBar)
        .photosPicker(isPresented: $showPicker, selection: $items, maxSelectionCount: 9, matching: .images)
    }

    private func runImport() {
        importing = true
        Task {
            do {
                var images: [Data] = []
                for item in items {
                    guard let data = try await item.loadTransferable(type: Data.self) else { continue }
                    images.append(data)
                }
                let saves = try await ImportService.extract(screenshots: images)
                for s in saves { app.add(s) }
                app.advance(task: "screenshot")
                app.showToast("Imported \(saves.count) screenshot\(saves.count == 1 ? "" : "s")")
                app.showAddSheet = false
            } catch {
                app.showToast(error.localizedDescription)
                if case BackendError.outOfCredits = error { app.showPaywall = true }
            }
            importing = false
        }
    }
}

// MARK: - Notes (Albo #67, #68)

struct NoteEditorView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let existing: Save?
    @State private var title = ""
    @State private var body_ = ""
    @State private var saved = false
    @State private var found: [Save] = []
    @State private var analyzing = false
    @State private var reanalyze = false
    @FocusState private var focus: Field?
    enum Field { case title, body }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button { dismiss() } label: { Image(systemName: saved ? "chevron.left" : "xmark").font(.system(size: 24, weight: .medium)).foregroundStyle(AlboColor.ink).frame(width: 40, height: 40) }
                    .buttonStyle(.plain)
                Spacer()
                Button { save() } label: {
                    Text(saved ? "Saved" : "Save").font(.alboSans(17, weight: .semibold)).foregroundStyle(saved ? AlboColor.muted : AlboColor.ink)
                        .padding(.horizontal, 20).frame(height: 44).background(AlboColor.optionFill, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(saved || title.isEmpty)
            }
            .padding(.horizontal, 16).padding(.top, 14)
            TextField("Title", text: $title).font(.alboDisplay(32)).foregroundStyle(AlboColor.ink).focused($focus, equals: .title).padding(.horizontal, 20).padding(.top, 30)
            TextEditor(text: $body_)
                .font(.alboSans(19))
                .foregroundStyle(AlboColor.ink)
                .scrollContentBackground(.hidden)
                .focused($focus, equals: .body)
                .padding(.horizontal, 16)
                .frame(minHeight: 120)
                .onChange(of: body_) { _, _ in saved = false }
            if !found.isEmpty || analyzing {
                Divider().padding(.horizontal, 20)
                VStack(alignment: .leading, spacing: 14) {
                    Text("Things Albo found").font(.alboSans(20, weight: .bold)).foregroundStyle(AlboColor.ink)
                    if analyzing { ProgressView() }
                    ForEach(found) { f in
                        NavigationLink(value: f.id) { SaveRow(save: f, onMenu: nil) }.buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(20)
            }
            Spacer()
        }
        .background(AlboColor.ground)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: UUID.self) { id in SaveDetailView(saveID: id) }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                HStack(spacing: 34) {
                    formatButton("bold", "**")
                    formatButton("italic", "*")
                    Button { insert("## ") } label: { Image(systemName: "textformat.size.larger").font(.system(size: 22)) }
                    Button { insert("- ") } label: { Image(systemName: "list.bullet").font(.system(size: 22)) }
                    Button { insert("[](https://)") } label: { Image(systemName: "link").font(.system(size: 22)) }
                    Spacer()
                    if saved {
                        Toggle(isOn: $reanalyze) { Text("Reanalyze").font(.alboSans(16)) }.toggleStyle(CheckboxToggleStyle()).frame(width: 140)
                            .onChange(of: reanalyze) { _, on in if on { analyze() } }
                    }
                }
                .foregroundStyle(AlboColor.inkSecondary)
            }
        }
        .onAppear {
            if let existing { title = existing.title; body_ = existing.noteBody ?? ""; saved = true; found = app.saves.filter { $0.mentionedInNoteID == existing.id } }
            else { focus = .title }
        }
    }

    private func formatButton(_ symbol: String, _ marker: String) -> some View {
        Button { insert(marker + marker) } label: { Image(systemName: symbol).font(.system(size: 22)) }
    }

    private func insert(_ s: String) { body_ += s }

    private func save() {
        let note: Save
        if let existing, var e = app.save(existing.id) {
            e.title = title; e.noteBody = body_; app.update(e); note = e
        } else {
            note = Save(category: .note, title: title, coverEmoji: nil, coverTint: 0xF4F4F4, sourcePlatform: .note, noteBody: body_, savedBy: [app.me])
            app.add(note)
        }
        saved = true
        analyze(noteID: note.id)
    }

    private func analyze(noteID: UUID? = nil) {
        let id = noteID ?? existing?.id
        analyzing = true
        Task {
            do {
                var results = try await ImportService.analyze(note: title, body: body_, noteID: id)
                for i in results.indices { results[i].mentionedInNoteID = id }
                // Replace previous findings for this note.
                if let id { for old in app.saves where old.mentionedInNoteID == id { app.remove(old.id) } }
                for r in results { app.add(r) }
                found = results
            } catch {
                app.showToast(error.localizedDescription)
            }
            analyzing = false
            reanalyze = false
        }
    }
}

// MARK: - Bulk import (Albo #100 to #103)

struct BulkImportGuide: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack { Button { dismiss() } label: { Image(systemName: "xmark").font(.system(size: 24, weight: .medium)).foregroundStyle(AlboColor.ink).frame(width: 40, height: 40) }.buttonStyle(.plain); Spacer() }
                .padding(.horizontal, 16).padding(.top, 14)
            if step < 2 {
                Capsule().fill(AlboColor.optionFill).frame(width: 300, height: 10).overlay(alignment: .leading) { Capsule().fill(AlboColor.ink).frame(width: step == 0 ? 150 : 300) }.padding(.top, 40)
            }
            switch step {
            case 0:
                question("Do you have your laptop with you?", "You would need your laptop to do this", mascot: .coder,
                         options: [("Yes!", { step = 1 }), ("No", { app.showToast("Come back with your laptop and we'll pick up here"); dismiss() })])
            case 1:
                question("Do you have Chrome or Edge installed on your laptop?", nil, mascot: nil,
                         options: [("Yes!", { step = 2 }), ("No, but I can install it", { step = 2 }), ("No", { app.showToast("Albo Browse needs Chrome or Edge"); dismiss() })])
            default:
                VStack(spacing: 28) {
                    Text(orphanSafe: "How to bulk import with Albo Browse").font(.alboDisplay(34)).foregroundStyle(AlboColor.ink).multilineTextAlignment(.center).padding(.top, 40)
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(Array(["Sign into albo.inc on your laptop (or grab the link below)", "Open the \"Bulk Import\" section in the web app", "Install the \"Albo Browse\" extension on Chrome or Edge when prompted", "Select your platforms and watch your saves come in"].enumerated()), id: \.offset) { i, t in
                            HStack(alignment: .top, spacing: 16) {
                                Text("\(i + 1)").font(.alboSans(17, weight: .bold)).foregroundStyle(.white).frame(width: 34, height: 34).background(AlboColor.ink, in: Circle())
                                Text(t).font(.alboSans(19)).foregroundStyle(AlboColor.ink).fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    MascotView(variant: .rocket).frame(width: 190).rotationEffect(.degrees(-20))
                    Spacer()
                    ShareLink(item: URL(string: "https://albo.inc/bulk-import")!, subject: Text("Save Everything")) {
                        ZStack {
                            Capsule().fill(Color.black).offset(y: 5)
                            Capsule().fill(AlboColor.ink)
                            HStack(spacing: 12) { Image(systemName: "globe").font(.system(size: 20)); Text("Get link to Albo web").font(.alboSans(18, weight: .semibold)) }.foregroundStyle(.white)
                        }
                        .frame(height: 58).frame(maxWidth: .infinity)
                    }
                    .simultaneousGesture(TapGesture().onEnded { app.advance(task: "bulk") })
                    .padding(.bottom, 12)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(AlboColor.ground)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func question(_ title: String, _ subtitle: String?, mascot: MascotVariant?, options: [(String, () -> Void)]) -> some View {
        VStack(spacing: 10) {
            Text(orphanSafe: title).font(.alboDisplay(30)).foregroundStyle(AlboColor.ink).multilineTextAlignment(.center).padding(.top, 34)
            if let subtitle { Text(subtitle).font(.alboSans(18)).foregroundStyle(Color(hex: 0x3B5BDB)) }
            Spacer()
            if let mascot { MascotView(variant: mascot).frame(width: 200) } else { HStack(spacing: 30) { Text("🌐").font(.system(size: 80)); Text("🟦").font(.system(size: 80)) } }
            Spacer()
            VStack(spacing: 12) {
                ForEach(Array(options.enumerated()), id: \.offset) { _, o in
                    SecondaryButton(title: o.0, action: o.1)
                }
            }
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Review picker (Albo #104)

struct ReviewCategoryPicker: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Capsule().fill(AlboColor.hairline).frame(width: 40, height: 5).frame(maxWidth: .infinity).padding(.top, 8)
                Text("What do you want to review?").alboText(.sheetTitle)
                Text(orphanSafe: "Pick a category to find what you watched, read, or visited.").font(.alboSans(16)).foregroundStyle(AlboColor.inkSecondary)
                CategoryGrid(categories: SaveCategory.browsable, mode: .review)
            }
            .padding(20)
        }
        .background(AlboColor.ground)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - List type picker (Albo #108)

struct ListTypePicker: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule().fill(AlboColor.hairline).frame(width: 40, height: 5).frame(maxWidth: .infinity).padding(.top, 8)
            Text("Make a list of...").alboText(.sheetTitle)
            Text(orphanSafe: "Pick what your list is about. You can add items next.").font(.alboSans(16)).foregroundStyle(AlboColor.inkSecondary)
            CategoryGrid(categories: SaveCategory.listable, mode: .list)
            Spacer()
        }
        .padding(20)
        .background(AlboColor.ground)
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// Two-column category cards with a 3D icon and label (Albo #104, #108).
struct CategoryGrid: View {
    enum Mode { case review, list }
    let categories: [SaveCategory]
    let mode: Mode

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
            ForEach(categories) { c in
                NavigationLink {
                    switch mode {
                    case .review: CategorySearchSheet(category: c, mode: .review)
                    case .list: ListEditorView(list: CuratedList(category: c, title: "", owner: SampleData.me))
                    }
                } label: {
                    HStack(spacing: 14) {
                        CategoryIcon(category: c, size: 56)
                        Text(c.title).font(.alboSans(18, weight: .semibold)).foregroundStyle(AlboColor.ink)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16).frame(height: 96)
                    .background(AlboColor.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.06), radius: 14, y: 6)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }
}

// MARK: - Category search (Albo #105, #110, #111, #120, #170)

struct CategorySearchSheet: View {
    enum Mode { case save, review, pick }
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let category: SaveCategory
    let mode: Mode
    var onPick: ((Save) -> Void)? = nil
    @State private var query = ""
    @State private var reviewTarget: Save? = nil

    private var results: [Save] {
        let pool = SampleData.catalog.filter { $0.category == category } + app.saves(in: category)
        var seen = Set<String>()
        let unique = pool.filter { seen.insert($0.title + ($0.recipe?.timeLabel ?? "") + ($0.place?.category ?? "")).inserted }
        guard !query.isEmpty else { return unique }
        return unique.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                SearchPill(placeholder: "Search \(category.pluralTitle.lowercased())", text: $query, leadingEmoji: category.emoji)
                Button("Cancel") { dismiss() }.font(.alboSans(17)).foregroundStyle(AlboColor.ink)
            }
            .padding(.horizontal, 20).padding(.top, 14)
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(results) { s in
                        Button { choose(s) } label: {
                            HStack(spacing: 14) {
                                SaveCover(save: s, cornerRadius: 10).frame(width: 64, height: 84)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(s.title).font(.alboSans(18, weight: .bold)).foregroundStyle(AlboColor.ink).lineLimit(2).multilineTextAlignment(.leading)
                                    Text(s.metaLine).font(.alboSans(15)).foregroundStyle(AlboColor.inkSecondary).lineLimit(1)
                                    HStack(spacing: 6) {
                                        if !s.savedBy.isEmpty { AvatarStack(users: s.savedBy, size: 20) }
                                        Text("\(s.saveCount) save\(s.saveCount == 1 ? "" : "s")").font(.alboSans(14)).foregroundStyle(AlboColor.inkSecondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "megaphone").font(.system(size: 18)).foregroundStyle(AlboColor.ink).frame(width: 44, height: 44).background(Circle().stroke(AlboColor.hairline, lineWidth: 1.5))
                            }
                            .padding(.horizontal, 20).padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 98)
                    }
                }
            }
        }
        .background(AlboColor.ground)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $reviewTarget) { s in ReviewFormView(saveID: s.id) }
    }

    private func choose(_ s: Save) {
        switch mode {
        case .save:
            if app.save(s.id) == nil { app.add(s) }
            app.showToast("Saved \(s.title)")
            app.showAddSheet = false
        case .review:
            if app.save(s.id) == nil { app.add(s) }
            reviewTarget = s
        case .pick:
            if app.save(s.id) == nil { app.add(s) }
            onPick?(s)
            dismiss()
        }
    }
}

// MARK: - List editor (Albo #109, #112)

struct ListEditorView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State var list: CuratedList
    @State private var elapsed = 0
    @State private var showPicker = false
    @State private var description = ""

    private var items: [Save] { list.saveIDs.compactMap { app.save($0) } }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { dismiss() }.font(.alboSans(18)).foregroundStyle(AlboColor.ink)
                Spacer()
                Text(String(format: "%02d:%02d", elapsed / 60, elapsed % 60)).font(.alboSans(18, weight: .semibold)).foregroundStyle(.white).monospacedDigit()
                    .padding(.horizontal, 16).frame(height: 40).background(AlboColor.brandOrange, in: Capsule())
                Spacer()
                Button { share() } label: {
                    Text("Share").font(.alboSans(17, weight: .semibold)).foregroundStyle(.white).padding(.horizontal, 18).frame(height: 44)
                        .background(ZStack { RoundedRectangle(cornerRadius: 14).fill(Color.black).offset(y: 4); RoundedRectangle(cornerRadius: 14).fill(AlboColor.ink) })
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(list.title.isEmpty)
            }
            .padding(.horizontal, 20).padding(.top, 14)
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AlboColor.muted, style: StrokeStyle(lineWidth: 2, dash: [8, 6])).frame(width: 140, height: 140)
                            .overlay(VStack(spacing: 6) { Image(systemName: "plus").font(.system(size: 26)); Text("Add photos").font(.alboSans(15)) }.foregroundStyle(AlboColor.inkSecondary))
                    }
                    TextField("Give your list a title", text: $list.title).font(.alboSans(26, weight: .bold)).foregroundStyle(AlboColor.ink)
                    TextField("Add a description (optional)", text: $description).font(.alboSans(18)).foregroundStyle(AlboColor.ink)
                    VStack(alignment: .leading, spacing: 14) {
                        HStack { Text("Items").font(.alboSans(20, weight: .bold)); Spacer(); Text("\(items.count)").font(.alboSans(17)).foregroundStyle(AlboColor.inkSecondary) }.foregroundStyle(AlboColor.ink)
                        if items.isEmpty {
                            Text("Add \(list.category.pluralTitle.lowercased()) to your list.").font(.alboSans(16)).foregroundStyle(AlboColor.muted)
                        }
                        ForEach(Array(items.enumerated()), id: \.element.id) { i, s in
                            HStack(spacing: 14) {
                                Text(list.isRanked ? "\(i + 1)." : "•").font(.alboSans(17, weight: .semibold)).foregroundStyle(AlboColor.inkSecondary).frame(width: 26)
                                Text(s.title).font(.alboSans(18)).foregroundStyle(AlboColor.ink)
                                Spacer()
                                Button { list.saveIDs.removeAll { $0 == s.id } } label: { Image(systemName: "xmark").font(.system(size: 16, weight: .semibold)).foregroundStyle(AlboColor.inkSecondary) }.buttonStyle(.plain)
                                Button { move(i, -1) } label: { Image(systemName: "line.3.horizontal").font(.system(size: 18)).foregroundStyle(AlboColor.ink) }.buttonStyle(.plain)
                                    .accessibilityLabel("Move up")
                            }
                            .padding(.horizontal, 18).frame(height: 60)
                            .background(AlboColor.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        Button { showPicker = true } label: {
                            HStack(spacing: 8) { Image(systemName: "plus"); Text("Add a \(list.category.title.lowercased())") }
                                .font(.alboSans(18, weight: .semibold)).foregroundStyle(AlboColor.ink)
                                .frame(maxWidth: .infinity).frame(height: 56)
                                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AlboColor.ink.opacity(0.4), lineWidth: 1.5))
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                    .padding(18).background(AlboColor.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    Toggle(isOn: $list.isRanked) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ranked list").font(.alboSans(20, weight: .semibold)).foregroundStyle(AlboColor.ink)
                            Text("Number items by rank, great for top 10 lists.").font(.alboSans(15)).foregroundStyle(AlboColor.inkSecondary)
                        }
                    }
                    .tint(AlboColor.rewardGreen)
                }
                .padding(20)
            }
        }
        .background(AlboColor.ground)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPicker) {
            NavigationStack {
                CategorySearchSheet(category: list.category, mode: .pick) { s in
                    if !list.saveIDs.contains(s.id) { list.saveIDs.append(s.id) }
                }
            }
        }
        .task {
            while !Task.isCancelled { try? await Task.sleep(for: .seconds(1)); elapsed += 1 }
        }
    }

    private func move(_ index: Int, _ delta: Int) {
        let target = index + delta
        guard target >= 0, target < list.saveIDs.count else { return }
        list.saveIDs.swapAt(index, target)
    }

    private func share() {
        list.details = description.isEmpty ? nil : description
        app.upsert(list)
        app.showToast("List saved")
        app.showAddSheet = false
    }
}
