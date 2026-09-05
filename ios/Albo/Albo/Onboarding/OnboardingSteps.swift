import SwiftUI
import StoreKit
import AuthenticationServices

// MARK: - #22 to #31 Magic import demos

enum ImportDemoScript {
    case instagram, web

    var platformEmoji: [String] { ["📸", "📘", "🎵", "▶️", "📌"] }
    var frames: [String] {
        switch self {
        case .instagram: return ["post", "appShare", "iosShare", "importing"]
        case .web: return ["page", "browserMenu", "iosShare", "importing"]
        }
    }
}

/// Scripted tutorial: a phone mockup steps through the share flow with a "Tap here" callout,
/// then reveals the extraction result with confetti (teardown 4.13, 4.14).
struct ImportDemoStep: View {
    let script: ImportDemoScript
    let onContinue: () -> Void
    @State private var frame = 0
    @State private var showResult = false

    var body: some View {
        ZStack {
            if showResult {
                ImportResultView(script: script, onContinue: onContinue)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                VStack(spacing: 18) {
                    Text("How to save to Albo").alboText(.onboardingHeadline)
                    HStack(spacing: 14) {
                        ForEach(script.platformEmoji, id: \.self) { e in
                            Text(e).font(.system(size: 22)).frame(width: 52, height: 52).background(AlboColor.optionFill, in: Circle())
                        }
                    }
                    PhoneMockup(width: 280) {
                        DemoFrame(script: script, frame: frame)
                    }
                    Spacer()
                }
                .padding(.top, 12)
                .transition(.opacity)
            }
        }
        .task {
            for i in 1..<script.frames.count {
                try? await Task.sleep(for: .seconds(1.7))
                withAnimation(.easeInOut(duration: 0.3)) { frame = i }
            }
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { showResult = true }
        }
    }
}

/// One frame of the simulated phone.
struct DemoFrame: View {
    let script: ImportDemoScript
    let frame: Int

    var body: some View {
        let name = script.frames[min(frame, script.frames.count - 1)]
        ZStack {
            switch name {
            case "post":
                VStack(spacing: 0) {
                    ZStack {
                        Color(hex: 0x8D99AE)
                        VStack { Text("JAPAN").font(.system(size: 30, weight: .black)); Text("FOOD").font(.system(size: 30, weight: .black)); Text("GUIDE").font(.system(size: 30, weight: .black)) }.foregroundStyle(.white)
                    }
                    HStack { Text("kaltpark  japan, you're silly delicious").font(.alboSans(11)); Spacer() }.padding(12)
                    Text("Add comment...").font(.alboSans(11)).foregroundStyle(AlboColor.muted).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 12).padding(.bottom, 16)
                }
                VStack(alignment: .trailing, spacing: 10) {
                    Spacer()
                    Text("♥ 14.8K").font(.alboSans(11, weight: .bold))
                    Text("💬 58").font(.alboSans(11, weight: .bold))
                    Text("➤ 1,404").font(.alboSans(11, weight: .bold)).padding(6).background(Circle().stroke(AlboColor.systemBlue, lineWidth: 2))
                    Spacer().frame(height: 90)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 14)
                TapHereCallout().offset(x: -30, y: 60)
            case "page":
                VStack(alignment: .leading, spacing: 8) {
                    Text("CHEW out loud").font(.alboSans(12, weight: .black)).padding(.top, 46)
                    Text("Easy Jamaican Jerk Chicken Recipe").font(.alboSans(18, weight: .bold))
                    Text("By Amy Dong · Updated Apr. 22, 2024 · 378 ratings").font(.alboSans(10)).foregroundStyle(AlboColor.muted)
                    RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0x7B3F00)).frame(height: 130).overlay(Text("🍗").font(.system(size: 54)))
                    Text("JUMP TO RECIPE").font(.alboSans(11, weight: .bold)).padding(8).background(AlboColor.optionFill, in: Capsule())
                    Spacer()
                    HStack { Spacer(); Text("chewoutloud.com").font(.alboSans(10)); Spacer(); Text("···").font(.alboSans(18, weight: .bold)) }.padding(.bottom, 14)
                }
                .padding(.horizontal, 14)
                .foregroundStyle(AlboColor.ink)
                TapHereCallout().offset(x: -10, y: 190)
            case "appShare", "browserMenu":
                VStack(spacing: 10) {
                    Spacer()
                    VStack(spacing: 8) {
                        Capsule().fill(AlboColor.hairline).frame(width: 36, height: 4)
                        if name == "appShare" {
                            HStack(spacing: 14) {
                                ForEach(["Fleur", "Madeline", "hero", "ARCHIF"], id: \.self) { n in
                                    VStack { Circle().fill(AlboColor.optionFill).frame(width: 40, height: 40); Text(n).font(.alboSans(9)) }
                                }
                            }
                            HStack(spacing: 14) {
                                ForEach(["Add to story", "WhatsApp", "Status", "Share to...", "Copy Link"], id: \.self) { n in
                                    VStack { Circle().fill(n == "Share to..." ? AlboColor.systemBlue.opacity(0.2) : AlboColor.optionFill).frame(width: 40, height: 40); Text(n).font(.alboSans(8)).lineLimit(1) }
                                }
                            }
                        } else {
                            ForEach(["Share", "Add to Bookmarks", "Add to Reading List", "New Tab", "New Private Tab"], id: \.self) { n in
                                HStack { Text(n).font(.alboSans(13)); Spacer() }.padding(.horizontal, 14).frame(height: 30)
                                    .background(n == "Share" ? AlboColor.systemBlue.opacity(0.12) : Color.clear)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(AlboColor.card, in: RoundedRectangle(cornerRadius: 20))
                    .padding(8)
                }
                .foregroundStyle(AlboColor.ink)
                TapHereCallout().offset(x: -20, y: 40)
            case "iosShare":
                VStack(spacing: 10) {
                    Spacer()
                    VStack(spacing: 12) {
                        HStack(spacing: 18) {
                            ForEach(["AirDrop", "Messages", "Mail", "Albo"], id: \.self) { n in
                                VStack(spacing: 4) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12).fill(n == "Albo" ? AlboColor.brandOrange : AlboColor.optionFill).frame(width: 48, height: 48)
                                        if n == "Albo" { MascotView(color: .white).frame(width: 26) }
                                    }
                                    Text(n).font(.alboSans(9))
                                }
                            }
                        }
                        ForEach(["📁  Save to Files", "🖨️  Print"], id: \.self) { n in
                            HStack { Text(n).font(.alboSans(13)); Spacer() }.padding(.horizontal, 14).frame(height: 32).background(AlboColor.optionFill, in: RoundedRectangle(cornerRadius: 10)).padding(.horizontal, 8)
                        }
                    }
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(AlboColor.card, in: RoundedRectangle(cornerRadius: 20))
                    .padding(8)
                }
                .foregroundStyle(AlboColor.ink)
                TapHereCallout().offset(x: 30, y: 10)
            default: // importing
                VStack(spacing: 14) {
                    ProgressView().controlSize(.large)
                    Text("Importing...").font(.alboSans(18, weight: .semibold))
                    Text("watching everything at 2x speed").font(.alboSans(14)).foregroundStyle(AlboColor.muted)
                }
                .padding(28)
                .background(AlboColor.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(name == "post" ? Color(hex: 0x8D99AE) : AlboColor.surface)
    }
}

/// "12 places found in Instagram video" / "1 recipe found in web link". Albo #26, #31.
struct ImportResultView: View {
    let script: ImportDemoScript
    let onContinue: () -> Void
    @State private var multiplier = 1

    var body: some View {
        ZStack {
            OnboardingPage(buttonTitle: "Continue", centered: true, onContinue: onContinue) {
                VStack(spacing: 6) {
                    Text(script == .instagram ? "12 places found in Instagram video" : "1 recipe found in web link").alboText(.onboardingHeadline).multilineTextAlignment(.center)
                    Text("Just like magic!").font(.alboSans(18)).foregroundStyle(AlboColor.muted)
                    AlboCard {
                        if script == .instagram {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Japan Food Guide").font(.alboSans(22, weight: .bold))
                                MiniMap(pins: ["☕️", "🍣", "🍜", "🏪"])
                                ForEach(Array(zip(["Suba", "Yakumo", "Iseya Sohonten", "Warito"], ["🇯🇵 Soba noodle shop · 3.7 · $$", "🍜 Ramen restaurant · 4.2 · $$", "🍶 Izakaya restaurant · 3.7 · $$", "🍢 Skewers · 4.0 · $"])), id: \.0) { name, meta in
                                    HStack(spacing: 14) {
                                        RoundedRectangle(cornerRadius: 10).fill(AlboColor.optionFill).frame(width: 64, height: 84).overlay(Text("🏮").font(.system(size: 28)))
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(name).font(.alboSans(18, weight: .bold))
                                            Text(meta).font(.alboSans(15)).foregroundStyle(AlboColor.inkSecondary)
                                        }
                                    }
                                }
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Easy Jamaican Jerk Chicken").font(.alboSans(22, weight: .bold))
                                RoundedRectangle(cornerRadius: 12).fill(Color(hex: 0x7B3F00)).frame(height: 180).overlay(Text("🍗").font(.system(size: 70)))
                                ServingMultiplier(multiplier: $multiplier, showsConvert: false)
                                ForEach(jerkIngredients) { ing in
                                    IngredientRow(ingredient: ing, multiplier: multiplier, onToggle: {})
                                }
                            }
                        }
                    }
                    .padding(.top, 10)
                }
            }
            ConfettiView(count: 24, seed: script == .instagram ? 3 : 9)
        }
    }

    private var jerkIngredients: [Ingredient] {
        let rows: [(String, String, Double, String)] = [
            ("🍗", "chicken legs", 10.0, "pieces"), ("🫒", "olive oil", 1.0 / 3.0, "cup"), ("🍬", "light brown sugar", 2, "tbsp"), ("🌿", "dried thyme", 1, "tbsp"),
            ("🫘", "ground allspice", 2, "tsp"), ("🌶️", "smoked paprika", 2, "tsp"), ("🪵", "cinnamon", 0.5, "tsp"), ("🫚", "ground ginger", 1, "tsp"),
            ("🌰", "ground cloves", 1, "tsp"), ("🔥", "cayenne pepper", 1, "tsp"), ("🧄", "garlic powder", 1, "tsp")]
        return rows.map { Ingredient(emoji: $0.0, name: $0.1, quantity: $0.2, unit: $0.3) }
    }
}

/// Light map card with emoji pins (Albo #18, #26).
struct MiniMap: View {
    let pins: [String]
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(hex: 0xDDEBF7))
            Path { p in
                for i in 0..<6 { p.move(to: CGPoint(x: 0, y: CGFloat(i) * 34)); p.addLine(to: CGPoint(x: 400, y: CGFloat(i) * 34 + 20)) }
                for i in 0..<8 { p.move(to: CGPoint(x: CGFloat(i) * 50, y: 0)); p.addLine(to: CGPoint(x: CGFloat(i) * 50 + 20, y: 200)) }
            }
            .stroke(Color.white.opacity(0.9), lineWidth: 2)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            ForEach(Array(pins.enumerated()), id: \.offset) { i, e in
                Text(e).font(.system(size: 26)).padding(6).background(AlboColor.card, in: Circle()).shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                    .offset(x: CGFloat(i) * 70 - 105, y: CGFloat((i % 2) * 40) - 20)
            }
        }
        .frame(height: 180)
        .accessibilityHidden(true)
    }
}

// MARK: - #32 Team photo and reviews

struct TeamReviewsStep: View {
    let onContinue: () -> Void
    var body: some View {
        OnboardingPage(buttonTitle: "Continue", centered: true, onContinue: onContinue) {
            VStack(spacing: 20) {
                // Stand-in for the founders-as-kids photo: three small mascots in a frame.
                HStack(spacing: -10) {
                    MascotView(variant: .rocket).frame(width: 90)
                    MascotView(variant: .reader).frame(width: 110).offset(y: -12)
                    MascotView(variant: .traveler).frame(width: 90)
                }
                .padding(28)
                .background(AlboColor.optionFill, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                Wordmark(size: 28)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(SampleData.testimonials.suffix(2)) { t in
                            TestimonialCard(testimonial: t).frame(width: 300)
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .padding(.horizontal, -20)
            }
        }
    }
}

// MARK: - #33 to #36 Notifications warm-up (with the rating ask riding along)

struct NotificationsStep: View {
    let onContinue: () -> Void
    @Environment(\.requestReview) private var requestReview
    @State private var busy = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Don't let a good save go to waste").alboText(.onboardingHeadline)
                Text("Albo will remind you about events and limited time offers.").font(.alboSans(17)).foregroundStyle(AlboColor.inkSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous).fill(AlboColor.card).frame(width: 180, height: 180)
                    .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
                VStack(spacing: 6) {
                    Text("📅").font(.system(size: 84))
                }
                MascotView(variant: .plain).frame(width: 70).offset(x: 80, y: 60)
            }
            Spacer()
            PrimaryButton(title: "Enable notifications", isLoading: busy) {
                busy = true
                // Albo #33: Apple's rating prompt fires before the system notification prompt.
                requestReview()
                Task {
                    _ = await NotificationService.requestAuthorization()
                    busy = false
                    onContinue()
                }
            }
            .padding(.horizontal, 20)
        }
        .background(AlboColor.surface.ignoresSafeArea())
    }
}

// MARK: - #37 Building your plan

struct BuildingPlanStep: View {
    let interests: Set<ContentInterest>
    let onDone: () -> Void
    @State private var progress: Double = 0
    @State private var completed = 0
    @State private var phase = 0

    private var lines: [String] {
        let chosen = interests.sorted { $0.rawValue < $1.rawValue }.map(\.planLine)
        return chosen.isEmpty ? ["Trips you want to plan", "Saved places & restaurants", "Workouts to try", "Things to buy", "Films & shows to watch"] : chosen + ["Films & shows to watch"]
    }
    private let phases = ["Building your watchlist...", "Pinning your places...", "Extracting your recipes...", "Making Albo yours"]

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ForEach(Array(["🎮", "📺", "📰", "💿", "🧺", "🖥️", "📼"].enumerated()), id: \.offset) { i, e in
                    Text(e).font(.system(size: 34))
                        .offset(x: CGFloat(i - 3) * 46, y: -110 - CGFloat((i % 3) * 22))
                        .rotationEffect(.degrees(Double(i - 3) * 8))
                }
                VStack(spacing: -4) {
                    Text("📦").font(.system(size: 150))
                }
                Text("ALBO'S BOX\nOF\nUNUSED SAVES")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(hex: 0x5C3A1E))
                    .offset(y: 26)
            }
            .frame(height: 300)
            .padding(.top, 30)
            Text("Making Albo yours").alboText(.onboardingHeadline)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AlboColor.optionFill)
                    Capsule().fill(LinearGradient(colors: [Color(hex: 0x8EC5FF), AlboColor.systemBlue], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 34)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            Text(phases[min(phase, phases.count - 1)]).font(.alboSans(17)).foregroundStyle(AlboColor.inkSecondary).padding(.top, 12)
            VStack(spacing: 0) {
                HStack {
                    Text("Setting up your Albo for").font(.alboSans(20, weight: .bold))
                    Spacer()
                    Text("\(Int(progress * 100))%").font(.alboSans(20, weight: .bold)).monospacedDigit()
                }
                .padding(.bottom, 10)
                Divider()
                ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
                    HStack {
                        Text(line).font(.alboSans(18))
                        Spacer()
                        if i < completed {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 26)).foregroundStyle(AlboColor.ink).transition(.scale)
                        } else {
                            ProgressView().tint(AlboColor.muted)
                        }
                    }
                    .frame(height: 50)
                }
            }
            .foregroundStyle(AlboColor.ink)
            .padding(.horizontal, 24)
            .padding(.top, 30)
            Spacer()
        }
        .task {
            let total = lines.count
            for i in 0..<total {
                try? await Task.sleep(for: .seconds(0.7))
                withAnimation(.easeInOut(duration: 0.6)) {
                    completed = i + 1
                    progress = min(0.98, Double(i + 1) / Double(total) * 0.98)
                    phase = min(phases.count - 1, i)
                }
            }
            try? await Task.sleep(for: .seconds(0.6))
            withAnimation { progress = 1 }
            try? await Task.sleep(for: .seconds(0.5))
            onDone()
        }
    }
}

// MARK: - #38 Doomscrolling to Booked & Busy

struct ValueGraphStep: View {
    let onContinue: () -> Void
    @State private var drawn: CGFloat = 0

    var body: some View {
        OnboardingPage(headline: "Less scrolling, more doing", buttonTitle: "Continue", centered: true, onContinue: onContinue) {
            VStack(spacing: 28) {
                GeometryReader { geo in
                    let w = geo.size.width, h = geo.size.height
                    let start = CGPoint(x: w * 0.18, y: h * 0.78)
                    let end = CGPoint(x: w * 0.82, y: h * 0.12)
                    ZStack {
                        // Grid
                        Path { p in
                            for i in 0..<5 { let y = h * 0.12 + CGFloat(i) * (h * 0.66 / 4); p.move(to: CGPoint(x: w * 0.18, y: y)); p.addLine(to: CGPoint(x: w * 0.82, y: y)) }
                        }
                        .stroke(AlboColor.hairline, lineWidth: 1)
                        // Area
                        curve(start: start, end: end).stroke(Color.clear)
                        Path { p in
                            p.move(to: CGPoint(x: start.x, y: h * 0.86))
                            p.addLine(to: start)
                            p.addCurve(to: end, control1: CGPoint(x: w * 0.6, y: start.y), control2: CGPoint(x: w * 0.72, y: h * 0.25))
                            p.addLine(to: CGPoint(x: end.x, y: h * 0.86))
                            p.closeSubpath()
                        }
                        .fill(LinearGradient(colors: [AlboColor.systemBlue.opacity(0.18), .clear], startPoint: .top, endPoint: .bottom))
                        // Curve
                        curve(start: start, end: end)
                            .trim(from: 0, to: drawn)
                            .stroke(LinearGradient(colors: [AlboColor.danger, AlboColor.brandOrange, AlboColor.systemBlue], startPoint: .leading, endPoint: .trailing),
                                    style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        // Dashed guides
                        Path { p in
                            p.move(to: start); p.addLine(to: CGPoint(x: start.x, y: h * 0.86))
                            p.move(to: end); p.addLine(to: CGPoint(x: end.x, y: h * 0.86))
                        }
                        .stroke(AlboColor.muted.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                        Circle().fill(AlboColor.danger).frame(width: 16, height: 16).position(start)
                        Circle().fill(AlboColor.systemBlue).frame(width: 16, height: 16).position(end)
                        Text("Endless\nDoomscrolling").font(.alboSans(15, weight: .semibold)).foregroundStyle(.white).multilineTextAlignment(.leading)
                            .padding(.horizontal, 14).padding(.vertical, 10).background(AlboColor.danger, in: RoundedRectangle(cornerRadius: 12))
                            .position(x: start.x, y: start.y - 52)
                        Text("Booked\n& Busy").font(.alboSans(15, weight: .semibold)).foregroundStyle(.white).multilineTextAlignment(.center)
                            .padding(.horizontal, 14).padding(.vertical, 10).background(AlboColor.systemBlue, in: RoundedRectangle(cornerRadius: 12))
                            .position(x: end.x, y: end.y - 52)
                        Group {
                            Text("Now").font(.alboSans(15, weight: .semibold)).foregroundStyle(AlboColor.danger).position(x: start.x, y: h * 0.94)
                            Text("Your goal").font(.alboSans(15, weight: .semibold)).foregroundStyle(AlboColor.systemBlue).position(x: end.x, y: h * 0.94)
                        }
                    }
                }
                .frame(height: 380)
                Text("You're on your way to turning saved spots into trips you actually take. Never be stuck for somewhere to go again.")
                    .font(.alboSans(17)).foregroundStyle(AlboColor.inkSecondary).multilineTextAlignment(.center)
            }
        }
        .onAppear { withAnimation(.easeInOut(duration: 1.4).delay(0.2)) { drawn = 1 } }
    }

    private func curve(start: CGPoint, end: CGPoint) -> Path {
        var p = Path()
        p.move(to: start)
        p.addCurve(to: end, control1: CGPoint(x: start.x + (end.x - start.x) * 0.65, y: start.y), control2: CGPoint(x: start.x + (end.x - start.x) * 0.85, y: start.y - (start.y - end.y) * 0.8))
        return p
    }
}

// MARK: - #39 Premium mockup

struct PremiumMockupStep: View {
    let onContinue: () -> Void
    var body: some View {
        OnboardingPage(headline: "Turn recipes into ingredients and steps", buttonTitle: "Continue", centered: true, onContinue: onContinue) {
            VStack(spacing: 24) {
                ZStack {
                    PhoneMockup(width: 210) { GridMockup(title: "Saved Books", emoji: "📚") }.rotationEffect(.degrees(-6)).offset(x: -60, y: 20)
                    PhoneMockup(width: 210) { GridMockup(title: "Saved TV Shows", emoji: "📺") }.rotationEffect(.degrees(5)).offset(x: 60)
                }
                .frame(height: 470)
                NoPaymentDueNow()
            }
        }
    }
}

struct GridMockup: View {
    let title: String
    let emoji: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.alboDisplay(18)).padding(.top, 44)
            Text("All the \(title.lowercased().replacingOccurrences(of: "saved ", with: "")) found in your library").font(.alboSans(9)).foregroundStyle(AlboColor.muted)
            HStack { Text("List").font(.alboSans(10)); Text("Grid").font(.alboSans(10, weight: .bold)); Spacer(); Text("Select").font(.alboSans(10)) }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(0..<9, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 8).fill(Color(hue: Double(i) / 9, saturation: 0.25, brightness: 0.92)).frame(height: 70).overlay(Text(emoji))
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .foregroundStyle(AlboColor.ink)
    }
}

struct NoPaymentDueNow: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark").font(.system(size: 18, weight: .bold))
            Text("No Payment Due Now").font(.alboSans(18))
        }
        .foregroundStyle(AlboColor.ink)
    }
}

// MARK: - #40 Trial reminder promise

struct TrialReminderStep: View {
    let onContinue: () -> Void
    var body: some View {
        OnboardingPage(buttonTitle: "Continue", centered: true, onContinue: onContinue) {
            VStack(spacing: 28) {
                ZStack {
                    Text("📅").font(.system(size: 120))
                    MascotView(variant: .plain).frame(width: 64).offset(x: 78, y: 50)
                }
                .padding(.top, 60)
                (Text("You'll get a reminder ") + Text("1 day").fontWeight(.bold) + Text(" before your trial ends."))
                    .font(.alboSans(26)).foregroundStyle(AlboColor.ink).multilineTextAlignment(.center)
                NoPaymentDueNow()
            }
        }
    }
}

// MARK: - #44 Digital Hoarder's Club

struct WelcomeClubStep: View {
    let onContinue: () -> Void
    var body: some View {
        ZStack(alignment: .bottom) {
            OrbitingIcons().frame(height: 380).opacity(0.35).offset(y: -180)
            Color.black.opacity(0.3).ignoresSafeArea()
            ZStack {
                VStack(spacing: 18) {
                    Capsule().fill(AlboColor.hairline).frame(width: 40, height: 5)
                    MascotView(variant: .king).frame(width: 190, height: 190).padding(.top, 10)
                    Text("Welcome to the\nDigital Hoarder's Club!").font(.alboSans(28, weight: .bold)).multilineTextAlignment(.center).foregroundStyle(AlboColor.ink)
                    Text("You've unlocked unlimited bulk imports and premium features. Time to save everything!")
                        .font(.alboSans(17)).foregroundStyle(AlboColor.inkSecondary).multilineTextAlignment(.center).padding(.horizontal, 16)
                    PrimaryButton(title: "Get Started", action: onContinue).padding(.horizontal, 24).padding(.top, 8)
                }
                .padding(.top, 12)
                .padding(.bottom, 24)
                ConfettiView(count: 18, seed: 44)
            }
            .frame(maxWidth: .infinity)
            .background(AlboColor.card, in: UnevenRoundedRectangle(topLeadingRadius: 36, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 36, style: .continuous))
            .ignoresSafeArea(edges: .bottom)
        }
        .background(AlboColor.ground)
    }
}

// MARK: - #45, #46 Sign in

struct SignInStep: View {
    let onSignedIn: () -> Void
    @Environment(AppState.self) private var app

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            OrbitingIcons().frame(height: 380)
            Spacer()
            VStack(spacing: 14) {
                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    // Sign in with Apple needs the capability and a real device; either way we continue locally.
                    if case .success = result { app.showToast("Signed in with Apple") }
                    onSignedIn()
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 56)
                .clipShape(Capsule())

                Button {
                    app.showToast("Signed in with Google")
                    onSignedIn()
                } label: {
                    HStack(spacing: 10) {
                        Text("G").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(AlboColor.systemBlue)
                        Text("Continue with Google").font(.alboSans(18, weight: .semibold)).foregroundStyle(AlboColor.ink)
                    }
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(Capsule().stroke(AlboColor.hairline, lineWidth: 1.5))
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}
