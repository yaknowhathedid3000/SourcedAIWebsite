import SwiftUI

/// "Clean up your saves": a triage deck. One save at a time, full bleed, discard
/// or keep, with a counter of what is left. The pile only shrinks if throwing
/// something away is as cheap as keeping it.
struct CleanupView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var queue: [UUID] = []
    @State private var drag: CGSize = .zero
    @State private var kept = 0
    @State private var discarded = 0

    private var remaining: [Save] { queue.compactMap { app.save($0) } }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer(minLength: 0)
                if remaining.isEmpty {
                    finished
                } else {
                    deck
                }
                Spacer(minLength: 0)
                if !remaining.isEmpty { actions }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { if queue.isEmpty { queue = app.saves.map(\.id) } }
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            Text("\(remaining.count) left")
                .font(.yogiSans(17, weight: .semibold))
                .foregroundStyle(.white)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 18)
    }

    // MARK: Deck

    private var deck: some View {
        ZStack {
            // Two cards behind, so the pile reads as a pile.
            ForEach(Array(remaining.prefix(3).enumerated().reversed()), id: \.element.id) { index, save in
                card(save)
                    .scaleEffect(1 - CGFloat(index) * 0.04)
                    .offset(y: CGFloat(index) * 14)
                    .offset(index == 0 ? drag : .zero)
                    .rotationEffect(.degrees(index == 0 ? Double(drag.width / 22) : 0))
                    .zIndex(Double(3 - index))
                    .gesture(index == 0 ? swipe : nil)
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: queue)
    }

    private func card(_ save: Save) -> some View {
        ZStack(alignment: .bottomLeading) {
            SaveCover(save: save, cornerRadius: 26)
                .frame(width: 320, height: 470)
                .clipped()
            LinearGradient(colors: [.clear, .black.opacity(0.72)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 6) {
                Text(save.category.title.uppercased())
                    .font(.yogiSans(12, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.75))
                Text(orphanSafe: save.title)
                    .font(.yogiDisplay(24, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            .padding(18)
        }
        .frame(width: 320, height: 470)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(alignment: .top) { verdictStamp }
        .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
    }

    /// The DISCARD / KEEP stamp that fades in as you drag.
    @ViewBuilder private var verdictStamp: some View {
        let magnitude = min(1, abs(drag.width) / 110)
        if magnitude > 0.05 {
            Text(drag.width < 0 ? "DISCARD" : "KEEP")
                .font(.yogiSans(20, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(drag.width < 0 ? YogiColor.danger : YogiColor.rewardGreen)
                .padding(.horizontal, 16).padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(drag.width < 0 ? YogiColor.danger : YogiColor.rewardGreen, lineWidth: 3)
                        .background(Color.white.opacity(0.92).clipShape(RoundedRectangle(cornerRadius: 10)))
                )
                .rotationEffect(.degrees(drag.width < 0 ? 12 : -12))
                .opacity(magnitude)
                .padding(.top, 26)
        }
    }

    private var swipe: some Gesture {
        DragGesture()
            .onChanged { drag = $0.translation }
            .onEnded { value in
                if value.translation.width < -110 { settle(keep: false) }
                else if value.translation.width > 110 { settle(keep: true) }
                else { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { drag = .zero } }
            }
    }

    // MARK: Actions

    private var actions: some View {
        HStack(spacing: 14) {
            Button { settle(keep: false) } label: {
                Text("Discard").font(.yogiSans(18, weight: .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 58)
                    .background(YogiColor.danger, in: Capsule())
            }
            Button { settle(keep: true) } label: {
                Text("Keep").font(.yogiSans(18, weight: .semibold)).foregroundStyle(YogiColor.ink)
                    .frame(maxWidth: .infinity).frame(height: 58)
                    .background(Color.white, in: Capsule())
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.bottom, 34)
    }

    private func settle(keep: Bool) {
        guard let top = remaining.first else { return }
        if keep { Haptics.tap(); kept += 1 } else { Haptics.warning(); discarded += 1 }
        withAnimation(.easeOut(duration: 0.22)) {
            drag = CGSize(width: keep ? 620 : -620, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if !keep { app.remove(top.id) }
            queue.removeAll { $0 == top.id }
            drag = .zero
        }
    }

    // MARK: Done

    private var finished: some View {
        VStack(spacing: 14) {
            MascotView(variant: .plain, color: .white).frame(width: 92, height: 92)
            Text("All clear")
                .font(.yogiDisplay(32, weight: .semibold))
                .foregroundStyle(.white)
            Text("\(kept) kept, \(discarded) discarded.")
                .font(.yogiSans(17))
                .foregroundStyle(.white.opacity(0.7))
            Button { dismiss() } label: {
                Text("Done").font(.yogiSans(18, weight: .semibold)).foregroundStyle(YogiColor.ink)
                    .padding(.horizontal, 44).frame(height: 56)
                    .background(Color.white, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
        }
    }
}
