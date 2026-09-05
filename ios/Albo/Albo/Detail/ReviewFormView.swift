import SwiftUI

/// "How was it?" in two stages: sentiment, then details (Albo #80 to #83, #106, #107, #123).
struct ReviewFormView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let saveID: UUID

    @State private var sentiment: Sentiment? = nil
    @State private var stage = 0
    @State private var title = ""
    @State private var stars = 0
    @State private var completedOn: Date? = Date()
    @State private var showDatePicker = false
    @State private var pickerDate = Date()
    @State private var photos = 0
    @State private var showPhotoSource = false
    @State private var tagged: [UserSummary] = []
    @State private var showTag = false
    @State private var friendsOnly = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Capsule().fill(AlboColor.hairline).frame(width: 40, height: 5).frame(maxWidth: .infinity).padding(.top, 8)
                    HStack(spacing: 12) {
                        Image(systemName: "megaphone.fill").font(.system(size: 28)).foregroundStyle(AlboColor.ink)
                        Text("How was it?").alboText(.sheetTitle)
                    }
                    if stage == 0 {
                        FlowLayout(spacing: 10) {
                            ForEach(Sentiment.allCases) { s in
                                SentimentChip(sentiment: s, isSelected: sentiment == s) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { sentiment = s; stage = 1 }
                                }
                            }
                        }
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(orderedSentiments) { s in
                                    SentimentChip(sentiment: s, isSelected: sentiment == s) { sentiment = s }
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Title").font(.alboSans(15)).foregroundStyle(AlboColor.muted)
                            TextField("What did you love about it?", text: $title, axis: .vertical).font(.alboSans(18)).lineLimit(1...3)
                            Rectangle().fill(AlboColor.hairline).frame(height: 1)
                        }
                        StarRating(rating: $stars)
                        HStack(spacing: 10) {
                            Button { pickerDate = completedOn ?? Date(); showDatePicker = true } label: {
                                HStack(spacing: 6) {
                                    Text(completedOn.map { "Completed \($0.formatted(.dateTime.month(.abbreviated).day()))" } ?? "Completed")
                                    Image(systemName: "chevron.down").font(.system(size: 12, weight: .semibold))
                                }
                                .font(.alboSans(16, weight: .medium)).foregroundStyle(completedOn == nil ? AlboColor.inkSecondary : .white)
                                .padding(.horizontal, 16).frame(height: 44)
                                .background(completedOn == nil ? AlboColor.optionFill : AlboColor.ink, in: Capsule())
                            }
                            .buttonStyle(PressableButtonStyle())
                            Button { completedOn = nil } label: {
                                Text("Don't remember").font(.alboSans(16, weight: .medium)).foregroundStyle(completedOn == nil ? .white : AlboColor.inkSecondary)
                                    .padding(.horizontal, 16).frame(height: 44)
                                    .background(completedOn == nil ? AlboColor.ink : AlboColor.optionFill, in: Capsule())
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                        HStack(spacing: 12) {
                            ForEach(0..<photos, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 12).fill(AlboColor.optionFill).frame(width: 96, height: 128)
                                    .overlay(Text("📷").font(.system(size: 32)))
                                    .overlay(alignment: .topTrailing) {
                                        Button { photos = max(0, photos - 1) } label: {
                                            Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.white).frame(width: 26, height: 26).background(Color.black.opacity(0.7), in: Circle())
                                        }
                                        .padding(6)
                                        .accessibilityLabel("Remove photo \(i + 1)")
                                    }
                            }
                            Button { showPhotoSource = true } label: {
                                RoundedRectangle(cornerRadius: 12).stroke(AlboColor.muted, style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                                    .frame(width: photos == 0 ? nil : 96, height: 128)
                                    .frame(maxWidth: photos == 0 ? .infinity : 96)
                                    .overlay(
                                        VStack(spacing: 6) {
                                            Image(systemName: "plus").font(.system(size: 22, weight: .medium))
                                            if photos == 0 { Text("Add photos").font(.alboSans(16)) }
                                        }
                                        .foregroundStyle(AlboColor.inkSecondary)
                                    )
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                        Button { showTag = true } label: {
                            HStack {
                                Image(systemName: "person.2").font(.system(size: 18))
                                Text(tagged.isEmpty ? "Tag people you did this with" : "With " + tagged.map(\.name).joined(separator: ", ")).font(.alboSans(17))
                                Spacer()
                                Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(AlboColor.ink)
                        }
                        .buttonStyle(.plain)
                        Toggle(isOn: $friendsOnly) {
                            HStack(spacing: 10) {
                                Image(systemName: "lock").font(.system(size: 16))
                                Text("Friends only").font(.alboSans(17))
                            }
                            .foregroundStyle(AlboColor.ink)
                        }
                        .toggleStyle(CheckboxToggleStyle())
                    }
                }
                .padding(.horizontal, 24).padding(.bottom, 24)
            }
            PrimaryButton(title: "Submit", isEnabled: sentiment != nil) { submit() }
                .padding(.horizontal, 24).padding(.top, 8)
        }
        .background(AlboColor.card)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showTag) { TagFriendsSheet(tagged: $tagged) }
        .confirmationDialog("Add photos", isPresented: $showPhotoSource, titleVisibility: .hidden) {
            Button("Choose from Gallery") { photos = min(4, photos + 1) }
            Button("Take a Photo") { photos = min(4, photos + 1) }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showDatePicker) {
            VStack(spacing: 16) {
                Text("Select date").font(.alboSans(20, weight: .bold))
                DatePicker("Completed on", selection: $pickerDate, in: ...Date(), displayedComponents: .date).datePickerStyle(.graphical)
                HStack(spacing: 12) {
                    SecondaryButton(title: "Cancel") { showDatePicker = false }
                    PrimaryButton(title: "OK") { completedOn = pickerDate; showDatePicker = false }
                }
            }
            .padding(20)
            .presentationDetents([.large])
        }
    }

    /// Chosen chip first, then the rest, like Albo #83 ("Hidden gem, Loved it, It's okay, Meh").
    private var orderedSentiments: [Sentiment] {
        guard let s = sentiment else { return Sentiment.allCases }
        return [s] + Sentiment.allCases.filter { $0 != s }
    }

    private func submit() {
        guard let sentiment else { return }
        let review = Review(saveID: saveID, sentiment: sentiment, title: title.isEmpty ? nil : title, stars: stars == 0 ? nil : stars,
                            completedOn: completedOn, photoCount: photos, taggedFriends: tagged, friendsOnly: friendsOnly)
        app.submit(review)
        dismiss()
    }
}

/// Square checkbox toggle, "Friends only" (Albo #83).
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack {
                configuration.label
                Spacer()
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square").font(.system(size: 26)).foregroundStyle(AlboColor.ink)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Wrapping chip layout for the seven sentiment chips (Albo #80).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX, y: CGFloat = bounds.minY, rowHeight: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX { x = bounds.minX; y += rowHeight + spacing; rowHeight = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
