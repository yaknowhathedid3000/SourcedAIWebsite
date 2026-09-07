import SwiftUI

// MARK: - Item actions (Albo #91, #114, #141)

/// Header row, two big square buttons, grouped rows, red destructive row.
struct ItemActionsSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let saveID: UUID
    @State private var showReminder = false
    @State private var showCollections = false
    @State private var showReview = false
    @State private var confirmRemove = false

    var body: some View {
        if let save = app.save(saveID) {
            VStack(alignment: .leading, spacing: 18) {
                Capsule().fill(YogiColor.hairline).frame(width: 40, height: 5).frame(maxWidth: .infinity).padding(.top, 8)
                HStack(spacing: 14) {
                    SaveCover(save: save, cornerRadius: 10).frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(save.title).font(.yogiSans(18, weight: .bold)).foregroundStyle(YogiColor.ink).lineLimit(1)
                        Text(save.metaLine).font(.yogiSans(14)).foregroundStyle(YogiColor.inkSecondary).lineLimit(1)
                    }
                    Spacer()
                    Button { app.setWant(save.id) } label: {
                        Image(systemName: "megaphone").font(.system(size: 18)).foregroundStyle(YogiColor.ink).frame(width: 44, height: 44).background(Circle().stroke(YogiColor.hairline, lineWidth: 1.5))
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityLabel("Wanna")
                }
                HStack(spacing: 14) {
                    ShareLink(item: save.sourceURL ?? URL(string: "https://yogi.app")!) { bigSquare("square.and.arrow.up", "Share") }
                    Button { showReminder = true } label: { bigSquare("bell", "Reminder") }.buttonStyle(PressableButtonStyle())
                }
                VStack(spacing: 0) {
                    row("folder.badge.plus", "Add to collection") { showCollections = true }
                    Divider().padding(.leading, 56)
                    row("photo", "Change cover image") { app.showToast("Cover images arrive with the photo picker") }
                    Divider().padding(.leading, 56)
                    row("star", "Add review / Mark as done") { showReview = true }
                    Divider().padding(.leading, 56)
                    row("flag", "Report bad extract") { app.showToast("Thanks, we'll take a look") }
                }
                .background(YogiColor.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                Button { confirmRemove = true } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "trash").font(.system(size: 20))
                        Text("Remove from All My Saves").font(.yogiSans(17, weight: .medium))
                        Spacer()
                    }
                    .foregroundStyle(YogiColor.danger).padding(.horizontal, 18).frame(height: 58)
                    .background(YogiColor.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(PressableButtonStyle())
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .sheet(isPresented: $showReminder) { ReminderSheet(saveID: saveID) }
            .sheet(isPresented: $showCollections) { AddToCollectionSheet(saveIDs: [saveID]) }
            .sheet(isPresented: $showReview) { ReviewFormView(saveID: saveID) }
            .alert("Remove 1 item", isPresented: $confirmRemove) {
                Button("Remove", role: .destructive) { app.remove(saveID); dismiss() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to remove this item? It will also be removed from any collections.")
            }
        }
    }

    private func bigSquare(_ symbol: String, _ title: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: symbol).font(.system(size: 26))
            Text(title).font(.yogiSans(16, weight: .medium))
        }
        .foregroundStyle(YogiColor.ink)
        .frame(maxWidth: .infinity).frame(height: 96)
        .background(YogiColor.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func row(_ symbol: String, _ title: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol).font(.system(size: 20)).foregroundStyle(YogiColor.ink).frame(width: 28)
                Text(title).font(.yogiSans(17, weight: .medium)).foregroundStyle(YogiColor.ink)
                Spacer()
            }
            .padding(.horizontal, 18).frame(height: 58)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Set a Reminder (Albo #92, #142)

struct ReminderSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let saveID: UUID
    @State private var slot: ReminderSlot = .morning
    @State private var customDate = Date()
    @State private var showCustom = false

    private var groups: [(String, [Date])] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var result: [(String, [Date])] = []
        let names = ["This week", "Next week", "In 2 weeks", "In 3 weeks"]
        for (i, name) in names.enumerated() {
            let start = i == 0 ? today : cal.date(byAdding: .day, value: 7 * i, to: today) ?? today
            let days = (0..<7).compactMap { d -> Date? in
                guard let date = cal.date(byAdding: .day, value: d, to: start) else { return nil }
                return date > today || (i == 0 && d > 0) ? date : nil
            }
            result.append((name, days))
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule().fill(YogiColor.hairline).frame(width: 40, height: 5).frame(maxWidth: .infinity).padding(.top, 8)
            Text("Set a Reminder").font(.yogiSans(24, weight: .bold)).foregroundStyle(YogiColor.ink)
            HStack(spacing: 12) {
                Text("Remind me in the").font(.yogiSans(17)).foregroundStyle(YogiColor.inkSecondary)
                Menu {
                    ForEach(ReminderSlot.allCases) { s in Button(s.menuLabel) { slot = s } }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sunrise").font(.system(size: 16))
                        Text(slot.menuLabel).font(.yogiSans(16, weight: .semibold))
                        Image(systemName: "chevron.down").font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(YogiColor.ink).padding(.horizontal, 14).frame(height: 40).background(YogiColor.optionFill, in: Capsule())
                }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(groups, id: \.0) { name, days in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(name).font(.yogiSans(15, weight: .semibold)).foregroundStyle(YogiColor.inkSecondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(days, id: \.self) { d in
                                        Button { set(d) } label: {
                                            VStack(spacing: 4) {
                                                Text(d, format: .dateTime.weekday(.abbreviated)).font(.yogiSans(14)).foregroundStyle(YogiColor.muted)
                                                Text(d, format: .dateTime.day()).font(.yogiSans(20, weight: .bold)).foregroundStyle(YogiColor.ink)
                                                Text(d, format: .dateTime.month(.abbreviated)).font(.yogiSans(13)).foregroundStyle(YogiColor.muted)
                                            }
                                            .frame(width: 72, height: 84)
                                            .background(YogiColor.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(YogiColor.hairline, lineWidth: 1))
                                        }
                                        .buttonStyle(PressableButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Button { showCustom = true } label: {
                HStack(spacing: 10) { Image(systemName: "calendar"); Text("Custom date & time") }
                    .font(.yogiSans(17, weight: .semibold)).foregroundStyle(YogiColor.ink)
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(YogiColor.optionFill, in: Capsule())
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal, 20).padding(.bottom, 12)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .onAppear { slot = app.defaultReminderSlot }
        .sheet(isPresented: $showCustom) {
            VStack(spacing: 20) {
                DatePicker("Remind me on", selection: $customDate, in: Date()...).datePickerStyle(.graphical)
                PrimaryButton(title: "Set reminder") {
                    app.setReminder(for: saveID, at: customDate, slot: slot)
                    showCustom = false
                    dismiss()
                }
            }
            .padding(20)
            .presentationDetents([.large])
        }
    }

    private func set(_ day: Date) {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: day)
        comps.hour = slot.hour
        comps.minute = 0
        let fire = Calendar.current.date(from: comps) ?? day
        app.setReminder(for: saveID, at: fire, slot: slot)
        dismiss()
    }
}

// MARK: - Add to collection (Albo #70, #115, #122)

struct AddToCollectionSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let saveIDs: [UUID]
    @State private var showNew = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule().fill(YogiColor.hairline).frame(width: 40, height: 5).frame(maxWidth: .infinity).padding(.top, 8)
            HStack(spacing: 14) {
                Image(systemName: "bookmark.fill").font(.system(size: 22)).foregroundStyle(YogiColor.ink)
                Text("All My Saves").font(.yogiSans(18, weight: .bold)).foregroundStyle(YogiColor.ink)
                Spacer()
                Image(systemName: "checkmark.circle.fill").font(.system(size: 26)).foregroundStyle(YogiColor.ink)
            }
            .padding(.horizontal, 4)
            Divider()
            Text("Add to a collection").font(.yogiSans(15, weight: .semibold)).foregroundStyle(YogiColor.inkSecondary)
            Button { showNew = true } label: {
                HStack(spacing: 14) {
                    Image(systemName: "plus").font(.system(size: 20, weight: .medium)).frame(width: 52, height: 52).background(YogiColor.optionFill, in: RoundedRectangle(cornerRadius: 12))
                    Text("New collection").font(.yogiSans(18, weight: .semibold))
                    Spacer()
                }
                .foregroundStyle(YogiColor.ink)
            }
            .buttonStyle(PressableButtonStyle())
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(app.collections) { c in
                        let inAll = saveIDs.allSatisfy { c.saveIDs.contains($0) }
                        Button {
                            for id in saveIDs where c.saveIDs.contains(id) == inAll { app.toggle(id, in: c.id) }
                        } label: {
                            HStack(spacing: 14) {
                                RoundedRectangle(cornerRadius: 12).fill(Color(hex: c.coverTint)).frame(width: 52, height: 52).overlay(Text(c.coverEmoji).font(.system(size: 24)))
                                Text(c.name).font(.yogiSans(18, weight: .semibold)).foregroundStyle(YogiColor.ink)
                                Spacer()
                                Image(systemName: inAll ? "checkmark.circle.fill" : "plus.circle").font(.system(size: 26)).foregroundStyle(YogiColor.ink)
                            }
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showNew) { NewCollectionFlow(firstSave: saveIDs.first) }
    }
}

// MARK: - New Collection, three steps (Albo #71 to #77)

struct NewCollectionFlow: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let firstSave: UUID?

    @State private var step = 0
    @State private var name = ""
    @State private var details = ""
    @State private var coverEmoji = "🥦"
    @State private var coverTint: UInt32 = 0xF5891F
    @State private var isPublic = true
    @State private var showCoverPicker = false
    @State private var created: SaveCollection? = nil
    @State private var inviteToast = false

    private let covers: [(String, UInt32)] = [("🥦", 0xF3B27A), ("🍝", 0xDCE8C8), ("✈️", 0xDCE9FF), ("📚", 0xEADCFF), ("☕️", 0xE6D5C3), ("🎬", 0x2B2D42)]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { if step == 1 { step = 0 } else { dismiss() } } label: {
                    Image(systemName: step == 1 ? "arrow.left" : "xmark").font(.system(size: 22, weight: .medium)).foregroundStyle(YogiColor.ink).frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                Spacer()
                Text("New Collection").font(.yogiSans(20, weight: .bold)).foregroundStyle(YogiColor.ink)
                Spacer()
                switch step {
                case 0:
                    Button("Next") { step = 1 }.font(.yogiSans(18, weight: .semibold)).foregroundStyle(name.isEmpty ? YogiColor.muted : YogiColor.ink).disabled(name.isEmpty).frame(width: 60)
                case 1:
                    Button { create() } label: {
                        Text("Done").font(.yogiSans(17, weight: .semibold)).foregroundStyle(.white).padding(.horizontal, 18).frame(height: 44)
                            .background(ZStack { RoundedRectangle(cornerRadius: 14).fill(Color.black).offset(y: 4); RoundedRectangle(cornerRadius: 14).fill(YogiColor.ink) })
                    }
                    .buttonStyle(PressableButtonStyle())
                default:
                    Button("Close") { dismiss() }.font(.yogiSans(18, weight: .semibold)).foregroundStyle(YogiColor.ink).frame(width: 60)
                }
            }
            .padding(.horizontal, 16).padding(.top, 14)

            Button { if step < 2 { showCoverPicker = true } } label: {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .fill(LinearGradient(colors: [Color(hex: coverTint).opacity(0.6), Color(hex: coverTint)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 250, height: 250)
                        .overlay(Text(coverEmoji).font(.system(size: 96)))
                        .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
                    if step < 2 {
                        Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)
                            .frame(width: 48, height: 48).background(Color.white.opacity(0.25), in: Circle()).padding(14)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 40)

            VStack(alignment: .leading, spacing: 18) {
                switch step {
                case 0:
                    CountedTextField(placeholder: "Collection name", text: $name, limit: 50)
                    CountedTextArea(placeholder: "What makes this collection special?", text: $details, limit: 200)
                case 1:
                    Menu {
                        Button("Public - Anyone can see") { isPublic = true }
                        Button("Private - Only you and collaborators") { isPublic = false }
                    } label: {
                        HStack {
                            Text(isPublic ? "Public - Anyone can see" : "Private - Only you").font(.yogiSans(18)).foregroundStyle(YogiColor.ink)
                            Spacer()
                            Image(systemName: "chevron.down").font(.system(size: 16, weight: .semibold)).foregroundStyle(YogiColor.ink)
                        }
                        .padding(.horizontal, 24).frame(height: 62)
                        .background(YogiColor.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                default:
                    Text("Invite Friends").font(.yogiSans(30, weight: .bold)).foregroundStyle(YogiColor.ink)
                    if let c = created, let url = c.inviteURL {
                        ShareLink(item: url) {
                            ZStack {
                                Capsule().fill(Color.black).offset(y: 5)
                                Capsule().fill(YogiColor.ink)
                                Text("Create & Share Invite").font(.yogiSans(18, weight: .semibold)).foregroundStyle(.white)
                            }
                            .frame(height: 58).frame(maxWidth: .infinity)
                        }
                        .simultaneousGesture(TapGesture().onEnded { app.showToast("Invite link created and ready to share") })
                    }
                    SecondaryButton(title: "Not Now") { dismiss() }
                }
            }
            .padding(.horizontal, 20).padding(.top, 34)
            Spacer()
        }
        .background(YogiColor.ground)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .confirmationDialog("Choose cover image", isPresented: $showCoverPicker, titleVisibility: .visible) {
            Button("Choose from Photos") { app.showToast("Photo covers arrive with the photo picker") }
            Button("Search the web") { app.showToast("Web search covers arrive with the backend") }
            ForEach(covers, id: \.0) { c in Button("Use \(c.0)") { coverEmoji = c.0; coverTint = c.1 } }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func create() {
        created = app.createCollection(name: name.trimmingCharacters(in: .whitespaces), details: details.isEmpty ? nil : details, coverEmoji: coverEmoji, isPublic: isPublic, firstSave: firstSave)
        if var c = created { c.coverTint = coverTint; if let i = app.collections.firstIndex(where: { $0.id == c.id }) { app.collections[i] = c } }
        step = 2
    }
}

// MARK: - Tag people you did this with (Albo #84)

struct TagFriendsSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Binding var tagged: [UserSummary]
    @State private var query = ""

    private var candidates: [UserSummary] {
        let all = app.following
        guard !query.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(query) || $0.handle.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 18) {
            Capsule().fill(YogiColor.hairline).frame(width: 40, height: 5).padding(.top, 8)
            Text("Tag people you did this with").font(.yogiSans(20, weight: .bold)).foregroundStyle(YogiColor.ink)
            SearchPill(placeholder: "Search friends", text: $query)
            if candidates.isEmpty {
                Spacer()
                EmptyStateView(systemImage: "person.2", title: "Add friends to tag them in your reviews")
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(candidates) { u in
                            let on = tagged.contains { $0.handle == u.handle }
                            Button {
                                if on { tagged.removeAll { $0.handle == u.handle } } else { tagged.append(u) }
                            } label: {
                                HStack(spacing: 14) {
                                    AvatarView(user: u, size: 48)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(u.name).font(.yogiSans(17, weight: .bold)).foregroundStyle(YogiColor.ink)
                                        Text(u.handle).font(.yogiSans(15)).foregroundStyle(YogiColor.muted)
                                    }
                                    Spacer()
                                    Image(systemName: on ? "checkmark.circle.fill" : "circle").font(.system(size: 26)).foregroundStyle(YogiColor.ink)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            PrimaryButton(title: "Done") { dismiss() }
        }
        .padding(.horizontal, 20).padding(.bottom, 8)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
}
