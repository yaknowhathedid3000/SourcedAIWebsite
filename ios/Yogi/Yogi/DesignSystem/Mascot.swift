import SwiftUI

/// The mascot's costumes seen across the app (teardown 3.4).
enum MascotVariant: String, CaseIterable, Codable, Hashable {
    case plain, chef, reader, news, king, max, traveler, filmFan, explorer, coder, rocket

    /// Emoji placed above the mascot for the costume. Replace with art when available.
    var hat: String? {
        switch self {
        case .plain: return nil
        case .chef: return "👨‍🍳"
        case .reader: return "📚"
        case .news: return "📰"
        case .king: return "👑"
        case .max: return "⚡️"
        case .traveler: return "🕶️"
        case .filmFan: return "🍿"
        case .explorer: return "🗺️"
        case .coder: return "💻"
        case .rocket: return "🚀"
        }
    }
}

/// The Yogi mascot: a black rounded "tooth" with two white eye slits. Vector, scales to any size.
struct MascotShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let r = w * 0.32
        // Top edge with big rounded corners.
        p.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + r), control: CGPoint(x: rect.maxX, y: rect.minY))
        // Right side, slightly bulging.
        p.addCurve(to: CGPoint(x: rect.maxX - w * 0.08, y: rect.maxY - h * 0.02),
                   control1: CGPoint(x: rect.maxX + w * 0.02, y: rect.minY + h * 0.55),
                   control2: CGPoint(x: rect.maxX, y: rect.maxY - h * 0.15))
        // Bottom: two rounded feet with a concave notch in between (the "tooth").
        p.addQuadCurve(to: CGPoint(x: rect.maxX - w * 0.30, y: rect.maxY - h * 0.16),
                       control: CGPoint(x: rect.maxX - w * 0.22, y: rect.maxY + h * 0.02))
        p.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.30, y: rect.maxY - h * 0.16),
                       control: CGPoint(x: rect.midX, y: rect.maxY - h * 0.42))
        p.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.08, y: rect.maxY - h * 0.02),
                       control: CGPoint(x: rect.minX + w * 0.22, y: rect.maxY + h * 0.02))
        // Left side.
        p.addCurve(to: CGPoint(x: rect.minX, y: rect.minY + r),
                   control1: CGPoint(x: rect.minX, y: rect.maxY - h * 0.15),
                   control2: CGPoint(x: rect.minX - w * 0.02, y: rect.minY + h * 0.55))
        p.addQuadCurve(to: CGPoint(x: rect.minX + r, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

struct MascotView: View {
    var variant: MascotVariant = .plain
    var color: Color = Color(hex: 0x1C1C1E)

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                MascotShape().fill(color)
                // Eyes: two curved white slits, slightly asymmetric like the logo.
                HStack(spacing: s * 0.10) {
                    EyeShape().fill(.white).frame(width: s * 0.20, height: s * 0.09)
                    EyeShape().fill(.white).frame(width: s * 0.20, height: s * 0.09).rotationEffect(.degrees(-6))
                }
                .offset(y: -s * 0.12)
                if let hat = variant.hat {
                    Text(hat)
                        .font(.system(size: s * 0.42))
                        .offset(x: s * 0.28, y: -s * 0.36)
                }
            }
            .frame(width: s, height: s)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// A single eye: an upward arc, like a smile-shaped slit.
struct EyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.6))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

/// The Yogi wordmark: mascot peeking from the left of a heavy serif "Yogi",
/// with "BY THE FEEL GOOD PROJECT" stacked top-right. Albo #2, #3.
struct Wordmark: View {
    var size: CGFloat = 44
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            MascotView().frame(width: size * 0.7, height: size * 0.7).offset(y: -size * 0.05)
            Text("Yogi").font(.system(size: size, weight: .black, design: .serif)).foregroundStyle(YogiColor.ink)
            VStack(alignment: .leading, spacing: -1) {
                Text("BY THE")
                Text("FEEL GOOD")
                Text("PROJECT")
            }
            .font(.system(size: size * 0.16, weight: .black))
            .foregroundStyle(YogiColor.ink)
            .padding(.bottom, size * 0.62)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Yogi, by The Feel Good Project")
    }
}
