import SwiftUI
import AppTrackingTransparency
import StoreKit

/// The 25-step onboarding, one coordinator (teardown chapter 4, Albo #1 to #46).
/// Steps live in an array so they can be reordered from remote config later.
enum OnboardingStep: Int, CaseIterable {
    case welcome, socialProof, goals, reinforcement, username, name, avatar, discovery,
         featureCarousel, habits, reassurance, interests, demoInstagram, demoWeb, teamReviews,
         notifications, buildingPlan, valueGraph, premiumMockup, trialReminder, paywall, welcomeClub, signIn

    /// Steps that show the progress header. Welcome, paywall, club and sign-in do not.
    var showsProgress: Bool {
        switch self {
        case .welcome, .paywall, .welcomeClub, .signIn: return false
        default: return true
        }
    }
}

struct OnboardingFlow: View {
    @Environment(AppState.self) private var app
    @State private var step: OnboardingStep = .welcome
    @State private var goingBack = false
    @State private var draft = OnboardingDraft()

    private var progress: Double {
        Double(step.rawValue) / Double(OnboardingStep.allCases.count - 1)
    }

    var body: some View {
        ZStack {
            YogiColor.ground.ignoresSafeArea()
            VStack(spacing: 0) {
                if step.showsProgress {
                    ProgressHeader(progress: progress,
                                   skipTitle: step == .notifications ? "Skip" : nil,
                                   onBack: back,
                                   onSkip: next)
                }
                content
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .move(edge: goingBack ? .leading : .trailing).combined(with: .opacity),
                        removal: .move(edge: goingBack ? .trailing : .leading).combined(with: .opacity)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: step)
        .task {
            // Albo #1: ATT is requested cold, before any UI. Kept for parity; consider a warm-up.
            if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                _ = await ATTrackingManager.requestTrackingAuthorization()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome: WelcomeStep(onStart: next, onSignIn: { go(to: .signIn) })
        case .socialProof: SocialProofStep(onContinue: next)
        case .goals: GoalsQuizStep(selection: $draft.goals, onContinue: next)
        case .reinforcement: ReinforcementStep(goal: draft.goals.sorted { $0.rawValue < $1.rawValue }.first ?? .doThings, onContinue: next)
        case .username: UsernameStep(username: $draft.username, onContinue: next)
        case .name: NameStep(name: $draft.name, onContinue: next)
        case .avatar: AvatarStep(name: draft.name, handle: draft.username, mascot: $draft.mascot, onContinue: next)
        case .discovery: DiscoveryStep(selection: $draft.discovery, onContinue: next)
        case .featureCarousel: FeatureCarouselStep(onContinue: next)
        case .habits: HabitsStep(selection: $draft.habits, onContinue: next)
        case .reassurance: ReassuranceStep(onContinue: next)
        case .interests: InterestsStep(selection: $draft.interests, onContinue: next)
        case .demoInstagram: ImportDemoStep(script: .instagram, onContinue: next)
        case .demoWeb: ImportDemoStep(script: .web, onContinue: next)
        case .teamReviews: TeamReviewsStep(onContinue: next)
        case .notifications: NotificationsStep(onContinue: next)
        case .buildingPlan: BuildingPlanStep(interests: draft.interests, onDone: next)
        case .valueGraph: ValueGraphStep(onContinue: next)
        case .premiumMockup: PremiumMockupStep(onContinue: next)
        case .trialReminder: TrialReminderStep(onContinue: next)
        case .paywall:
            PaywallView(onDismiss: { go(to: .signIn) }, onPurchased: { go(to: .welcomeClub) })
        case .welcomeClub: WelcomeClubStep(onContinue: { go(to: .signIn) })
        case .signIn: SignInStep(onSignedIn: finish)
        }
    }

    private func next() {
        guard let n = OnboardingStep(rawValue: step.rawValue + 1) else { finish(); return }
        goingBack = false
        step = n
    }

    private func back() {
        guard let p = OnboardingStep(rawValue: step.rawValue - 1) else { return }
        goingBack = true
        step = p
    }

    private func go(to s: OnboardingStep) {
        goingBack = s.rawValue < step.rawValue
        step = s
    }

    private func finish() {
        var profile = app.profile
        if !draft.name.isEmpty { profile.name = draft.name }
        if !draft.username.isEmpty { profile.handle = draft.username }
        profile.mascot = draft.mascot
        app.profile = profile
        app.answers = OnboardingAnswers(goals: draft.goals, discovery: draft.discovery, habits: draft.habits, interests: draft.interests)
        app.isSignedIn = true
        app.hasOnboarded = true
    }
}

struct OnboardingDraft {
    var goals: Set<OnboardingGoal> = []
    var username = ""
    var name = ""
    var mascot: MascotVariant = .plain
    var discovery: DiscoverySource? = nil
    var habits: Set<SavingHabit> = []
    var interests: Set<ContentInterest> = []
}

/// Shared page scaffold: scrolling content with the primary button pinned at the bottom.
struct OnboardingPage<Content: View>: View {
    var headline: String? = nil
    var subline: String? = nil
    var buttonTitle: String
    var buttonEnabled: Bool = true
    var centered: Bool = false
    var onContinue: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: centered ? .center : .leading, spacing: 8) {
                if let headline {
                    Text(headline)
                        .yogiText(.onboardingHeadline)
                        .multilineTextAlignment(centered ? .center : .leading)
                        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
                }
                if let subline {
                    Text(subline)
                        .font(.yogiSans(17))
                        .foregroundStyle(YogiColor.inkSecondary)
                        .multilineTextAlignment(centered ? .center : .leading)
                        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
                }
                content()
                    .padding(.top, 12)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: buttonTitle, isEnabled: buttonEnabled, action: onContinue)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .background(YogiColor.ground.opacity(0.96))
        }
    }
}

// MARK: - #3 Welcome

struct WelcomeStep: View {
    let onStart: () -> Void
    let onSignIn: () -> Void

    private static var buildLabel: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(Self.buildLabel).font(.yogiSans(11)).foregroundStyle(YogiColor.hairline)
                Spacer()
                HStack(spacing: 6) { Text("🇺🇸"); Text("EN") }
                    .font(.yogiSans(17, weight: .medium))
                    .foregroundStyle(YogiColor.ink)
                    .padding(.horizontal, 16).frame(height: 44)
                    .background(YogiColor.optionFill, in: Capsule())
            }
            .padding(.horizontal, 20)
            Spacer()
            OrbitingIcons().frame(height: 360)
            Spacer()
            Wordmark(size: 40)
            Text("A new way to explore a new city")
                .font(.yogiSans(19))
                .foregroundStyle(YogiColor.inkSecondary)
                .padding(.top, 14)
            Spacer()
            VStack(spacing: 16) {
                PrimaryButton(title: "Get Started", action: onStart)
                TextLinkButton(prefix: "Already have an account?", action: "Sign in", onTap: onSignIn)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
    }
}

// MARK: - #4 Social proof

struct SocialProofStep: View {
    let onContinue: () -> Void

    var body: some View {
        OnboardingPage(buttonTitle: "Continue", centered: true, onContinue: onContinue) {
            VStack(spacing: 18) {
                MascotPile().frame(height: 170)
                Text("Yogi helps you actually do the things you save")
                    .font(.yogiSans(22))
                    .foregroundStyle(YogiColor.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                HStack(spacing: 14) {
                    StatCard(value: "148k+", label: "Happy users")
                    StatCard(value: "3.9M+", label: "Saves made")
                }
                RatingCard()
                VStack(spacing: 12) {
                    ForEach(SampleData.testimonials.prefix(3)) { t in
                        TestimonialCard(testimonial: t)
                    }
                }
            }
        }
    }
}

/// A heap of costumed mascots (chef, traveler, reader, film fan). Albo #4.
struct MascotPile: View {
    var body: some View {
        ZStack {
            MascotView(variant: .reader).frame(width: 90).offset(x: -80, y: 20)
            MascotView(variant: .filmFan).frame(width: 96).offset(x: 70, y: 26)
            MascotView(variant: .news).frame(width: 84).offset(x: 40, y: -40)
            MascotView(variant: .chef).frame(width: 86).offset(x: -40, y: -46)
            MascotView(variant: .explorer).frame(width: 110).offset(y: 6)
        }
        .accessibilityHidden(true)
    }
}

struct StatCard: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 6) {
            Text(value).font(.yogiSans(30, weight: .bold)).foregroundStyle(YogiColor.ink)
            Text(label).font(.yogiSans(16)).foregroundStyle(YogiColor.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .background(YogiColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }
}

struct RatingCard: View {
    var body: some View {
        HStack(spacing: 14) {
            Text("🌿").font(.system(size: 28))
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text("4.9").font(.yogiSans(26, weight: .bold)).foregroundStyle(YogiColor.ink)
                    StaticStars(rating: 5, size: 18)
                }
                Text("3K+ App Ratings").font(.yogiSans(17)).foregroundStyle(YogiColor.inkSecondary)
            }
            Text("🌿").font(.system(size: 28)).scaleEffect(x: -1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(YogiColor.ratingFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(YogiColor.star.opacity(0.35), lineWidth: 1))
    }
}

struct TestimonialCard: View {
    let testimonial: SampleData.Testimonial
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                AvatarView(user: UserSummary(name: testimonial.handle, handle: testimonial.handle, mascot: testimonial.mascot), size: 36)
                Text(testimonial.handle).font(.yogiSans(17, weight: .semibold)).foregroundStyle(YogiColor.ink)
                Text(testimonial.flag)
                Spacer()
                StaticStars(rating: 5, size: 14)
            }
            Text(testimonial.text)
                .font(.yogiSans(16))
                .foregroundStyle(YogiColor.ink)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(YogiColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }
}

// MARK: - #5 Goals quiz

struct GoalsQuizStep: View {
    @Binding var selection: Set<OnboardingGoal>
    let onContinue: () -> Void

    var body: some View {
        OnboardingPage(headline: "What brings you to Yogi?", buttonTitle: "Continue", buttonEnabled: !selection.isEmpty, onContinue: onContinue) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Because I want to...").font(.yogiSans(17)).foregroundStyle(YogiColor.muted)
                ForEach(OnboardingGoal.allCases) { goal in
                    OptionPill(emoji: goal.emoji, title: goal.title, isSelected: selection.contains(goal)) {
                        if selection.contains(goal) { selection.remove(goal) } else { selection.insert(goal) }
                    }
                }
            }
        }
    }
}

// MARK: - #6 Reinforcement

struct ReinforcementStep: View {
    let goal: OnboardingGoal
    let onContinue: () -> Void

    var body: some View {
        OnboardingPage(headline: "You came to the right place", subline: goal.reinforcement, buttonTitle: "Let's go", onContinue: onContinue) {
            ZStack(alignment: .bottomLeading) {
                PhoneMockup { LibraryMockup() }
                PixelHand().offset(x: -10, y: -140)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
        }
    }
}

/// A rounded phone frame used by every mockup in onboarding.
struct PhoneMockup<Content: View>: View {
    var width: CGFloat = 270
    @ViewBuilder let content: () -> Content
    var body: some View {
        content()
            .frame(width: width, height: width * 2.05)
            .background(YogiColor.card)
            .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 40, style: .continuous).stroke(Color.black, lineWidth: 8))
            .overlay(alignment: .top) {
                Capsule().fill(Color.black).frame(width: 90, height: 26).padding(.top, 10)
            }
            .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
    }
}

/// Miniature of the Library home used inside phone mockups (Albo #6, #39).
struct LibraryMockup: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Library").font(.yogiDisplay(22)).padding(.top, 44)
            RoundedRectangle(cornerRadius: 10).fill(YogiColor.optionFill).frame(height: 30)
                .overlay(alignment: .leading) { Text("  🔍 Search saves...").font(.yogiSans(11)).foregroundStyle(YogiColor.muted) }
            HStack(spacing: 10) {
                ForEach(SaveCategory.browsable.prefix(5)) { c in
                    VStack(spacing: 2) { Text(c.emoji).font(.system(size: 18)); Text(c.pluralTitle).font(.yogiSans(8)).foregroundStyle(YogiColor.muted) }
                }
            }
            Text("Recently imported ›").font(.yogiSans(12, weight: .bold))
            HStack(spacing: 8) {
                ForEach(["🏯", "🏝️", "🎬", "🐶"], id: \.self) { e in
                    RoundedRectangle(cornerRadius: 8).fill(YogiColor.optionFill).frame(width: 52, height: 72).overlay(Text(e))
                }
            }
            Text("Collections ›").font(.yogiSans(12, weight: .bold))
            ForEach(["I'm Totally Coming Back To This Later", "Brussels Baybeee"], id: \.self) { name in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6).fill(YogiColor.optionFill).frame(width: 34, height: 34)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("🔒 Private").font(.yogiSans(8)).foregroundStyle(YogiColor.muted)
                        Text(name).font(.yogiSans(10, weight: .semibold)).lineLimit(1)
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .foregroundStyle(YogiColor.ink)
    }
}

// MARK: - #7 Username

struct UsernameStep: View {
    @Binding var username: String
    let onContinue: () -> Void
    @FocusState private var focused: Bool

    private var rules: [(String, Bool)] {
        let u = username
        let allowed = u.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
        return [
            ("At least 3 characters", u.count >= 3),
            ("Maximum 20 characters", u.count <= 20 && !u.isEmpty),
            ("No spaces allowed", !u.contains(" ") && !u.isEmpty),
            ("Only letters, numbers, and underscores", allowed && !u.isEmpty),
            ("Username is available", isValid),
        ]
    }

    private var isValid: Bool {
        username.count >= 3 && username.count <= 20 && username.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    var body: some View {
        OnboardingPage(headline: "Pick a username", subline: "Choose wisely. This is how your friends find you.", buttonTitle: "Continue", buttonEnabled: isValid, onContinue: onContinue) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    TextField("username", text: $username)
                        .font(.yogiSans(18))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused)
                    if isValid {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(YogiColor.rewardGreen)
                            Text("Available").font(.yogiSans(14, weight: .semibold)).foregroundStyle(YogiColor.rewardGreen)
                        }
                    }
                }
                .padding(.horizontal, 18).frame(height: 58)
                .background(YogiColor.optionFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                HStack {
                    Text("3-20 characters, letters, numbers, and underscore...").font(.yogiSans(13)).foregroundStyle(YogiColor.muted)
                    Spacer()
                    Text("\(username.count)/20").font(.yogiSans(13)).foregroundStyle(YogiColor.muted).monospacedDigit()
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Username requirements:").font(.yogiSans(15, weight: .semibold)).foregroundStyle(YogiColor.ink)
                    ForEach(rules, id: \.0) { rule in
                        HStack(spacing: 8) {
                            Image(systemName: rule.1 ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(rule.1 ? YogiColor.rewardGreen : YogiColor.muted)
                            Text(rule.0).font(.yogiSans(15)).foregroundStyle(YogiColor.inkSecondary)
                        }
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(YogiColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
            }
        }
        .onAppear { focused = true }
    }
}

// MARK: - #8 Name

struct NameStep: View {
    @Binding var name: String
    let onContinue: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        OnboardingPage(headline: "What should I call you?", subline: "First name, full name, your alter ego, up to you.", buttonTitle: "Continue", buttonEnabled: !name.trimmingCharacters(in: .whitespaces).isEmpty, onContinue: onContinue) {
            TextField("Your name", text: $name)
                .font(.yogiSans(18))
                .focused($focused)
                .padding(.horizontal, 18).frame(height: 58)
                .background(YogiColor.optionFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .onAppear { focused = true }
    }
}

// MARK: - #9 to #13 Avatar

struct AvatarStep: View {
    let name: String
    let handle: String
    @Binding var mascot: MascotVariant
    let onContinue: () -> Void
    @State private var showPicker = false
    @State private var hasPicked = false

    var body: some View {
        OnboardingPage(headline: "Add a profile picture please", subline: "You can change this later.", buttonTitle: "Continue", buttonEnabled: hasPicked, centered: true, onContinue: onContinue) {
            VStack(spacing: 14) {
                Button { showPicker = true } label: {
                    ZStack {
                        Circle().fill(YogiColor.optionFill)
                        if hasPicked {
                            MascotView(variant: mascot).padding(28)
                        } else {
                            Image(systemName: "plus").font(.system(size: 44, weight: .light)).foregroundStyle(YogiColor.ink)
                        }
                    }
                    .frame(width: 160, height: 160)
                }
                .buttonStyle(PressableButtonStyle())
                Text(name.isEmpty ? "You" : name).font(.yogiSans(22, weight: .bold)).foregroundStyle(YogiColor.ink)
                Text("@\(handle)").font(.yogiSans(16)).foregroundStyle(YogiColor.muted)
            }
            .padding(.top, 40)
        }
        .confirmationDialog("Profile picture", isPresented: $showPicker, titleVisibility: .hidden) {
            Button("Choose from Gallery") { pick(.plain) }
            Button("Take a Photo") { pick(.traveler) }
            ForEach([MascotVariant.chef, .reader, .filmFan, .explorer], id: \.self) { v in
                Button("Use the \(v.rawValue) mascot") { pick(v) }
            }
        }
    }

    private func pick(_ v: MascotVariant) {
        mascot = v
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { hasPicked = true }
    }
}

// MARK: - #14 Discovery

struct DiscoveryStep: View {
    @Binding var selection: DiscoverySource?
    let onContinue: () -> Void
    var body: some View {
        OnboardingPage(headline: "How did you end up here?", buttonTitle: "Continue", buttonEnabled: selection != nil, onContinue: onContinue) {
            VStack(spacing: 10) {
                ForEach(DiscoverySource.allCases) { s in
                    OptionPill(emoji: s.emoji, title: s.title, isSelected: selection == s) { selection = s }
                }
            }
        }
    }
}

// MARK: - #15 to #18 Feature carousel

/// Floating "🍤 Prawns · 200g" pill used by the recipe carousel card.
struct IngredientTag: View {
    let emoji: String
    let name: String
    let amount: String
    var body: some View {
        HStack(spacing: 6) {
            Text(emoji).font(.system(size: 15))
            Text(name).font(.yogiSans(15, weight: .bold)).foregroundStyle(YogiColor.ink)
            Text("· \(amount)").font(.yogiSans(15)).foregroundStyle(YogiColor.inkSecondary)
        }
        .padding(.horizontal, 14).frame(height: 40)
        .background(YogiColor.card, in: Capsule())
        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
    }
}

struct FeatureCarouselStep: View {
    let onContinue: () -> Void
    @State private var page = 0

    struct Card: Identifiable { let id = UUID(); let category: SaveCategory?; let headline: String; let emoji: String; let tint: Color; let chip: (String, String, String)? }

    private let cards: [Card] = [
        Card(category: .film, headline: "See a film you love? Save it to Yogi in one tap.", emoji: "🎬", tint: Color(hex: 0x2B2D42), chip: ("🎬", "Once Upon a Tim...", "Comedy · 2019")),
        Card(category: .recipe, headline: "See a recipe you love? Save it to Yogi in one tap.", emoji: "🍤", tint: Color(hex: 0xE07A5F), chip: ("🍝", "Garlic Prawn Pasta", "30 minutes")),
        Card(category: .place, headline: "See a spot you love? Save it to Yogi in one tap.", emoji: "🍽️", tint: Color(hex: 0x3D405B), chip: ("📍", "VIBEY LONDON RESTAURANTS", "for 2025")),
        Card(category: nil, headline: "Every place you save gets pinned on a map.", emoji: "🗺️", tint: Color(hex: 0xDDEBF7), chip: nil),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    VStack(alignment: .leading, spacing: 20) {
                        HighlightedHeadline(text: card.headline, highlight: card.category?.highlightWord)
                        ZStack(alignment: .bottomTrailing) {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(card.tint)
                                .overlay(Text(card.emoji).font(.system(size: 120)))
                                .frame(height: 420)
                            if card.category == .recipe {
                                VStack {
                                    HStack { Spacer(); IngredientTag(emoji: "🧄", name: "Garlic", amount: "1 clove") }
                                    Spacer()
                                    HStack { IngredientTag(emoji: "🍤", name: "Prawns", amount: "200g").offset(x: -12); Spacer() }
                                    Spacer()
                                    HStack { Spacer(); IngredientTag(emoji: "🌿", name: "Parsley", amount: "A handful").offset(x: 8) }
                                }
                                .padding(.vertical, 40)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            if let chip = card.chip {
                                HStack(spacing: 10) {
                                    Text(chip.0).font(.system(size: 26)).frame(width: 44, height: 44).background(YogiColor.optionFill, in: RoundedRectangle(cornerRadius: 10))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(chip.1).font(.yogiSans(15, weight: .semibold)).lineLimit(1)
                                        Text(chip.2).font(.yogiSans(13)).foregroundStyle(YogiColor.muted)
                                    }
                                }
                                .padding(12)
                                .background(YogiColor.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
                                .padding(16)
                                .offset(x: 24)
                            } else {
                                Text("🍔 🍕 ☕️ 🍣").font(.system(size: 26)).padding(20)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 20)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            PrimaryButton(title: "Show me how!") {
                if page < cards.count - 1 { withAnimation { page += 1 } } else { onContinue() }
            }
            .padding(.horizontal, 20)
        }
    }
}

/// Headline with one word tinted by category, like "See a *film* you love?" (Albo #15).
struct HighlightedHeadline: View {
    let text: String
    let highlight: String?
    var body: some View {
        if let highlight, let range = text.range(of: highlight) {
            (Text(text[text.startIndex..<range.lowerBound])
             + Text(text[range]).foregroundStyle(YogiColor.categoryPurple)
             + Text(text[range.upperBound...]))
                .yogiText(.onboardingHeadline)
        } else {
            Text(text).yogiText(.onboardingHeadline)
        }
    }
}

// MARK: - #19 Habits

struct HabitsStep: View {
    @Binding var selection: Set<SavingHabit>
    let onContinue: () -> Void
    var body: some View {
        OnboardingPage(headline: "Where do you save things at the moment?", subline: "Helps us make Yogi feel like home faster.", buttonTitle: "Continue", buttonEnabled: !selection.isEmpty, onContinue: onContinue) {
            VStack(spacing: 10) {
                ForEach(SavingHabit.allCases) { h in
                    OptionPill(emoji: h.emoji, title: h.title, subtitle: h == .socialMedia ? "TikTok, Instagram, Facebook, Pinterest, LinkedIn, X, Threads" : nil, isSelected: selection.contains(h)) {
                        if selection.contains(h) { selection.remove(h) } else { selection.insert(h) }
                    }
                }
            }
        }
    }
}

// MARK: - #20 Reassurance

struct ReassuranceStep: View {
    let onContinue: () -> Void
    var body: some View {
        OnboardingPage(headline: "No problem!", subline: "Yogi can import anything from Instagram, TikTok, Facebook, Pinterest and YouTube.", buttonTitle: "Show me how", centered: true, onContinue: onContinue) {
            ZStack {
                PhoneMockup(width: 220) {
                    VStack { Spacer(); Text("🎥").font(.system(size: 80)); Spacer() }.frame(maxWidth: .infinity)
                }
                ForEach(Array(["📌", "📘", "📸", "🎵", "📷"].enumerated()), id: \.offset) { i, e in
                    Text(e).font(.system(size: 28)).frame(width: 56, height: 56)
                        .background(YogiColor.card, in: Circle()).shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                        .offset(x: cos(Double(i) * 1.26) * 150, y: sin(Double(i) * 1.26) * 170)
                }
            }
            .frame(height: 480)
        }
    }
}

// MARK: - #21 Interests

/// Selectable interest row: mascot costume tile, bold title, blue tint + blue check when picked (Albo #21).
struct InterestCard: View {
    let interest: ContentInterest
    let isSelected: Bool
    let onTap: () -> Void

    private var costume: MascotVariant {
        switch interest {
        case .travel: return .traveler
        case .restaurants: return .plain
        case .recipes: return .chef
        case .workouts: return .max
        case .shopping: return .explorer
        case .books: return .reader
        case .articles: return .news
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(YogiColor.card)
                    MascotView(variant: costume).frame(width: 36, height: 36)
                }
                .frame(width: 56, height: 56)
                Text(interest.title).font(.yogiSans(20, weight: .semibold)).foregroundStyle(YogiColor.ink)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 22)).foregroundStyle(YogiColor.systemBlue)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 82)
            .background(isSelected ? Color(hex: 0xE8F2FF) : YogiColor.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(isSelected ? YogiColor.systemBlue : Color.clear, lineWidth: 1.5))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct InterestsStep: View {
    @Binding var selection: Set<ContentInterest>
    let onContinue: () -> Void
    var body: some View {
        OnboardingPage(headline: "What kind of videos, posts or links do you typically save?", subline: "Pick anything that catches your eye.", buttonTitle: "Continue", buttonEnabled: !selection.isEmpty, onContinue: onContinue) {
            VStack(spacing: 12) {
                ForEach(ContentInterest.allCases) { c in
                    InterestCard(interest: c, isSelected: selection.contains(c)) {
                        if selection.contains(c) { selection.remove(c) } else { selection.insert(c) }
                    }
                }
            }
        }
    }
}
