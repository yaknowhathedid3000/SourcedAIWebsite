import SwiftUI

// MARK: - Orbiting icons (Albo #3 welcome, #45 sign-in)

/// Pastel circles with platform and category glyphs orbiting the mascot on two rings.
struct OrbitingIcons: View {
    struct Item: Identifiable {
        let id = UUID()
        let emoji: String
        let tint: Color
        let ring: Int      // 0 inner, 1 outer
        let phase: Double  // radians
    }

    static let items: [Item] = [
        Item(emoji: "🍴", tint: Color(hex: 0xFFE1E1), ring: 0, phase: 0.4),
        Item(emoji: "🧭", tint: Color(hex: 0xDCE9FF), ring: 0, phase: 2.4),
        Item(emoji: "💡", tint: Color(hex: 0xFFF3C4), ring: 0, phase: 4.4),
        Item(emoji: "📖", tint: Color(hex: 0xFFE7C7), ring: 1, phase: 0.0),
        Item(emoji: "🎞️", tint: Color(hex: 0xEADCFF), ring: 1, phase: 1.05),
        Item(emoji: "🏃", tint: Color(hex: 0xDDF5DF), ring: 1, phase: 2.1),
        Item(emoji: "📸", tint: Color(hex: 0xFCE0F3), ring: 1, phase: 3.15),
        Item(emoji: "🎵", tint: Color(hex: 0xE3E3E3), ring: 1, phase: 4.2),
        Item(emoji: "✈️", tint: Color(hex: 0xDCE9FF), ring: 1, phase: 5.25),
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                let c = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let radii: [CGFloat] = [geo.size.width * 0.24, geo.size.width * 0.40]
                ZStack {
                    ForEach(radii.indices, id: \.self) { i in
                        Circle().stroke(AlboColor.hairline, lineWidth: 1)
                            .frame(width: radii[i] * 2, height: radii[i] * 2)
                            .position(c)
                    }
                    MascotView().frame(width: geo.size.width * 0.18).position(c)
                    ForEach(Self.items) { item in
                        let speed = item.ring == 0 ? 0.35 : -0.22
                        let a = item.phase + t * speed
                        let r = radii[item.ring]
                        ZStack {
                            Circle().fill(item.tint)
                            Text(item.emoji).font(.system(size: 22))
                        }
                        .frame(width: 54, height: 54)
                        .position(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Confetti (Albo #26, #31, #44, #147)

/// Thin colored parallelograms scattered over celebratory screens, drifting gently.
struct ConfettiView: View {
    struct Piece {
        let x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat
        let angle: Double, hue: Color, drift: Double
    }

    let pieces: [Piece]

    init(count: Int = 26, seed: UInt64 = 7) {
        var g = SeededGenerator(seed: seed)
        let palette: [Color] = [Color(hex: 0xF5B800), Color(hex: 0x2C7BE5), Color(hex: 0x22C55E), Color(hex: 0xF5891F), Color(hex: 0xD6203A), Color(hex: 0x9B4DFF)]
        pieces = (0..<count).map { i in
            Piece(x: CGFloat.random(in: 0...1, using: &g),
                  y: CGFloat.random(in: 0...1, using: &g),
                  w: CGFloat.random(in: 6...14, using: &g),
                  h: CGFloat.random(in: 14...30, using: &g),
                  angle: Double.random(in: -60...60, using: &g),
                  hue: palette[i % palette.count],
                  drift: Double.random(in: 0.6...1.4, using: &g))
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                ForEach(pieces.indices, id: \.self) { i in
                    let p = pieces[i]
                    Rectangle()
                        .fill(p.hue)
                        .frame(width: p.w, height: p.h)
                        .rotationEffect(.degrees(p.angle + sin(t * p.drift) * 12))
                        .position(x: p.x * geo.size.width, y: p.y * geo.size.height + CGFloat(sin(t * p.drift + Double(i))) * 6)
                        .opacity(0.9)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Deterministic random so confetti layouts are stable across renders.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

// MARK: - Tap-here callout (Albo #22 to #30)

/// Bright blue "Tap here" box with a yellow pointing hand, pulsing.
struct TapHereCallout: View {
    var text: String = "Tap here"
    @State private var pulse = false
    var body: some View {
        HStack(spacing: 8) {
            Text(text)
                .font(.alboSans(22, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Color(hex: 0x2196F3), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text("👇").font(.system(size: 34))
                .offset(y: pulse ? -6 : 4)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { pulse = true }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Pixel hand cursor (Albo #6, #22)

struct PixelHand: View {
    var body: some View {
        Image(systemName: "hand.point.up.left.fill")
            .font(.system(size: 54))
            .foregroundStyle(.white)
            .shadow(color: .black, radius: 0, x: 2, y: 2)
            .shadow(color: .black, radius: 0, x: -2, y: -2)
            .accessibilityHidden(true)
    }
}
