import SwiftUI

/// "Saved Recipes" smart view with All / Want to try / Made tabs, select mode, Decider and plus FABs (Albo #113 to #127).
struct CategoryView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let category: SaveCategory

    enum Tab: Hashable { case all, want, done }
    @State private var tab: Tab = .all
    @State private var selecting = false
    @State private var selected: Set<UUID> = []
    @State private var confirmDelete = false
    @State private var menuSave: Save? = nil
    @State private var deciderPick: Save? = nil
    @State private var showDeciderEmpty = false
    @State private var addToCollectionIDs: [UUID]? = nil
    @State private var isGrid = false

    private var items: [Save] {
        let all = app.saves(in: category)
        switch tab {
        case .all: return all
        case .want: return all.filter { $0.status == .wantTo }
        case .done: return all.filter { $0.status == .done }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Saved \(category.pluralTitle)").yogiText(.screenTitle)
                            Text(category.librarySubtitle).font(.yogiSans(16)).foregroundStyle(YogiColor.inkSecondary)
                        }
                        Spacer()
                        CategoryIcon(category: category, size: 72)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    tabs.padding(.top, 20)
                    Rectangle().fill(YogiColor.hairline).frame(height: 1)
                    list.padding(.top, 8)
                }
                .padding(.bottom, 140)
            }
        }
        .background(YogiColor.ground)
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottomTrailing) { fabs }
        .overlay(alignment: .bottom) { if selecting { selectionBar } }
        .sheet(item: $menuSave) { s in ItemActionsSheet(saveID: s.id) }
        .sheet(item: $deciderPick) { s in DeciderResult(save: s) }
        .fullScreenCover(isPresented: $showDeciderEmpty) { DeciderEmptyView(category: category) }
        .alert("Remove \(selected.count) item\(selected.count == 1 ? "" : "s")", isPresented: $confirmDelete) {
            Button("Remove", role: .destructive) {
                for id in selected { app.remove(id) }
                selected = []; selecting = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to remove \(selected.count == 1 ? "this item" : "these items")? They will also be removed from any collections.")
        }
        .sheet(isPresented: Binding(get: { addToCollectionIDs != nil }, set: { if !$0 { addToCollectionIDs = nil } })) {
            if let ids = addToCollectionIDs { AddToCollectionSheet(saveIDs: ids) }
        }
    }

    private var topBar: some View {
        HStack {
            if selecting {
                Text("\(selected.count) selected").font(.yogiSans(17, weight: .semibold)).foregroundStyle(YogiColor.ink)
                Spacer()
                Button { selecting = false; selected = [] } label: { Image(systemName: "xmark").font(.system(size: 18, weight: .semibold)).foregroundStyle(YogiColor.ink) }
            } else {
                Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 22, weight: .semibold)).foregroundStyle(YogiColor.ink) }
                    .accessibilityLabel("Back")
                Spacer()
                Button { isGrid.toggle() } label: { Image(systemName: isGrid ? "list.bullet" : "square.grid.2x2").font(.system(size: 20)).foregroundStyle(YogiColor.ink) }
                    .padding(.trailing, 16)
                Button("Select") { selecting = true }.font(.yogiSans(18, weight: .semibold)).foregroundStyle(YogiColor.ink)
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 48)
    }

    private var tabs: some View {
        HStack(spacing: 28) {
            tabButton(.all, "All")
            tabButton(.want, category.wantTab)
            tabButton(.done, category.doneTab)
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private func tabButton(_ t: Tab, _ title: String) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.2)) { tab = t } } label: {
            VStack(spacing: 8) {
                Text(title)
                    .font(t == tab ? .yogiDisplay(20) : .yogiDisplayItalic(20, weight: .semibold))
                    .foregroundStyle(t == tab ? YogiColor.ink : YogiColor.muted)
                Rectangle().fill(tab == t ? YogiColor.ink : Color.clear).frame(width: 44, height: 4)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var list: some View {
        if items.isEmpty {
            if tab == .done {
                EmptyStateView(mascot: .chef, title: "You haven't completed any \(category.pluralTitle) yet",
                               message: "\(category.pluralTitle) will start to appear here as you share more things to Yogi.")
                    .padding(.top, 40)
            } else {
                EmptyStateView(systemImage: "tray", title: "No \(category.pluralTitle.lowercased()) here yet",
                               message: "Share a \(category.title.lowercased()) to Yogi and it will show up here.", actionTitle: "Add anything") { app.showAddSheet = true }
                    .padding(.top, 40)
            }
        } else if isGrid {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 18) {
                ForEach(items) { s in
                    NavigationLink(value: LibraryRoute.save(s.id)) {
                        VStack(alignment: .leading, spacing: 6) {
                            SaveCover(save: s).frame(height: 200)
                            Text(s.title).font(.yogiSans(16, weight: .semibold)).foregroundStyle(YogiColor.ink).lineLimit(2)
                            Text(s.recipe?.timeLabel ?? s.metaLine).font(.yogiSans(13)).foregroundStyle(YogiColor.muted).lineLimit(1)
                        }
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(20)
        } else {
            LazyVStack(spacing: 0) {
                ForEach(items) { s in
                    if selecting {
                        Button { toggle(s.id) } label: {
                            HStack(spacing: 12) {
                                SaveRow(save: s, onMenu: nil)
                                Image(systemName: selected.contains(s.id) ? "checkmark.circle.fill" : "circle").font(.system(size: 26)).foregroundStyle(YogiColor.ink)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20).padding(.vertical, 12)
                    } else {
                        NavigationLink(value: LibraryRoute.save(s.id)) {
                            SaveRow(save: s, onMenu: { menuSave = s })
                        }
                        .buttonStyle(PressableButtonStyle())
                        .padding(.horizontal, 20).padding(.vertical, 12)
                    }
                }
            }
        }
    }

    private var fabs: some View {
        VStack(spacing: 14) {
            FloatingButton(action: decide) { Image(systemName: "dice.fill").font(.system(size: 24)).foregroundStyle(YogiColor.ink) }
                .accessibilityLabel("Decider")
            FloatingButton(action: { app.showAddSheet = true }) { Image(systemName: "plus").font(.system(size: 26)).foregroundStyle(YogiColor.ink) }
                .accessibilityLabel("Add")
        }
        .padding(.trailing, 20)
        .padding(.bottom, 24)
        .opacity(selecting ? 0 : 1)
    }

    private var selectionBar: some View {
        HStack(spacing: 22) {
            FloatingButton(action: { addToCollectionIDs = Array(selected) }) { Image(systemName: "plus.circle").font(.system(size: 24, weight: .medium)).foregroundStyle(YogiColor.ink) }
            FloatingButton(action: { for id in selected { if var s = app.save(id) { s.status = .wantTo; app.update(s) } }; app.showToast("Added to \(category.wantTab)") }) { Image(systemName: "plus").font(.system(size: 24, weight: .medium)).foregroundStyle(YogiColor.ink) }
            FloatingButton(action: { for id in selected { if var s = app.save(id) { s.status = .done; app.update(s) } }; app.showToast("Marked as complete") }) { Image(systemName: "checkmark.circle").font(.system(size: 24, weight: .medium)).foregroundStyle(YogiColor.ink) }
            Spacer()
            FloatingButton(action: { confirmDelete = true }) { Image(systemName: "trash").font(.system(size: 24, weight: .medium)).foregroundStyle(YogiColor.ink) }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .disabled(selected.isEmpty)
        .opacity(selected.isEmpty ? 0.5 : 1)
    }

    private func toggle(_ id: UUID) {
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
    }

    private func decide() {
        let pool = app.saves(in: category).filter { $0.status != .done }
        if let pick = pool.randomElement() { deciderPick = pick } else { showDeciderEmpty = true }
    }
}

/// List row: thumb, title, meta with emoji, private-note chip, kebab (Albo #113).
struct SaveRow: View {
    let save: Save
    let onMenu: (() -> Void)?

    var body: some View {
        HStack(spacing: 14) {
            // Polaroid frame around the thumbnail (Albo #113).
            SaveCover(save: save, cornerRadius: 6).frame(width: 52, height: 70)
                .padding(4)
                .background(YogiColor.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(YogiColor.hairline, lineWidth: 1))
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            VStack(alignment: .leading, spacing: 6) {
                Text(save.title).font(.yogiSans(18, weight: .bold)).foregroundStyle(YogiColor.ink).lineLimit(2).multilineTextAlignment(.leading)
                HStack(spacing: 6) {
                    Text(save.metaEmoji).font(.system(size: 14))
                    Text(save.metaLine).font(.yogiSans(15)).foregroundStyle(YogiColor.inkSecondary).lineLimit(1)
                }
                if let note = save.privateNote {
                    Text(note).font(.yogiSans(14)).foregroundStyle(YogiColor.ink)
                        .padding(.horizontal, 12).frame(height: 32)
                        .background(YogiColor.card, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                }
            }
            Spacer(minLength: 4)
            if let onMenu {
                Button(action: onMenu) {
                    Image(systemName: "ellipsis").font(.system(size: 20, weight: .bold)).foregroundStyle(YogiColor.ink).frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("More")
            }
        }
    }
}

/// Decider with nothing to pick from (Albo #127): category icon, serif title, disabled "Find Recipes".
struct DeciderEmptyView: View {
    @Environment(\.dismiss) private var dismiss
    let category: SaveCategory
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 22, weight: .semibold)).foregroundStyle(YogiColor.ink).frame(width: 44, height: 44) }
                Spacer()
            }
            .padding(.horizontal, 8)
            Spacer()
            CategoryIcon(category: category, size: 76)
            Text("Nothing to decide yet").font(.yogiDisplay(30)).foregroundStyle(YogiColor.ink).padding(.top, 26)
            Text("Save some \(category.pluralTitle.lowercased()) first so the Decider has something to pick from.".noOrphans)
                .font(.yogiSans(17)).foregroundStyle(YogiColor.ink).multilineTextAlignment(.center)
                .padding(.horizontal, 44).padding(.top, 12)
            Spacer()
            PrimaryButton(title: "Find \(category.pluralTitle)", isEnabled: false) {}
                .padding(.horizontal, 20).padding(.bottom, 16)
        }
        .background(YogiColor.ground.ignoresSafeArea())
    }
}

/// The Decider's pick, presented as a small sheet.
struct DeciderResult: View {
    @Environment(\.dismiss) private var dismiss
    let save: Save
    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(YogiColor.hairline).frame(width: 40, height: 5).padding(.top, 8)
            Text("🎲").font(.system(size: 54))
            Text("The Decider says").font(.yogiSans(15)).foregroundStyle(YogiColor.muted)
            Text(save.title).yogiText(.sheetTitle).multilineTextAlignment(.center)
            Text(save.metaLine).font(.yogiSans(16)).foregroundStyle(YogiColor.inkSecondary)
            Spacer()
            PrimaryButton(title: "Let's do it") { dismiss() }.padding(.horizontal, 24)
        }
        .padding(.bottom, 12)
        .presentationDetents([.medium])
    }
}
