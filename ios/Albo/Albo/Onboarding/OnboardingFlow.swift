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
            AlboColor.ground.ignoresSafeArea()
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
                        .alboText(.onboardingHeadline)
                        .multilineTextAlignment(centered ? .center : .leading)
                        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
                }
                if let subline {
                    Text(subline)
                        .font(.alboSans(17))
                        .foregroundStyle(AlboColor.inkSecondary)
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
                .background(AlboColor.ground.opacity(0.96))
        }
    }
}

// MARK: - #3 Welcome

struct WelcomeStep: View {
    let onStart: () -> Void
    let onSignIn: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                HStack(spacing: 6) { Text("🇺🇸"); Text("EN") }
                    .font(.alboSans(17, weight: .medium))
                    .foregroundStyle(AlboColor.ink)
                    .padding(.horizontal, 16).frame(height: 44)
                    .background(AlboColor.optionFill, in: Capsule())
            }
            .padding(.horizontal, 20)
            Spacer()
            OrbitingIcons().frame(height: 360)
            Spacer()
            Wordmark(size: 40)
            Text("A new way to explore a new city")
                .font(.alboSans(19))
                .foregroundStyle(AlboColor.inkSecondary)
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
                Text("Albo helps you actually do the things you save")
                    .font(.alboSans(22))
                    .foregroundStyle(AlboColor.ink)
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
            Text(value).font(.alboSans(30, weight: .bold)).foregroundStyle(AlboColor.ink)
            Text(label).font(.alboSans(16)).foregroundStyle(AlboColor.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .background(AlboColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }
}

struct RatingCard: View {
    var body: some View {
        HStack(spacing: 14) {
            Text("🌿").font(.system(size: 28))
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text("4.9").font(.alboSans(26, weight: .bold)).foregroundStyle(AlboColor.ink)
                    StaticStars(rating: 5, size: 18)
                }
                Text("3K+ App Ratings").font(.alboSans(17)).foregroundStyle(AlboColor.inkSecondary)
            }
            Text("🌿").font(.system(size: 28)).scaleEffect(x: -1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(AlboColor.ratingFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AlboColor.star.opacity(0.35), lineWidth: 1))
    }
}

struct TestimonialCard: View {
    let testimonial: SampleData.Testimonial
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                AvatarView(user: UserSummary(name: testimonial.handle, handle: testimonial.handle, mascot: testimonial.mascot), size: 36)
                Text(testimonial.handle).font(.alboSans(17, weight: .semibold)).foregroundStyle(AlboColor.ink)
                Text(testimonial.flag)
                Spacer()
                StaticStars(rating: 5, size: 14)
            }
            Text(testimonial.text)
                .font(.alboSans(16))
                .foregroundStyle(AlboColor.ink)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AlboColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }
}

// MARK: - #5 Goals quiz

struct GoalsQuizStep: View {
    @Binding var selection: Set<OnboardingGoal>
    let onContinue: () -> Void

    var body: some View {
        OnboardingPage(headline: "What brings you to Albo?", buttonTitle: "Continue", buttonEnabled: !selection.isEmpty, onContinue: onContinue) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Because I want to...").font(.alboSans(17)).foregroundStyle(AlboColor.muted)
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
            .background(AlboColor.card)
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
            Text("Library").font(.alboDisplay(22)).padding(.top, 44)
            RoundedRectangle(cornerRadius: 10).fill(AlboColor.optionFill).frame(height: 30)
                .overlay(alignment: .leading) { Text("  🔍 Search saves...").font(.alboSans(11)).foregroundStyle(AlboColor.muted) }
            HStack(spacing: 10) {
                ForEach(SaveCategory.browsable.prefix(5)) { c in
                    VStack(spacing: 2) { Text(c.emoji).font(.system(size: 18)); Text(c.pluralTitle).font(.alboSans(8)).foregroundStyle(AlboColor.muted) }
                }
            }
            Text("Recently imported ›").font(.alboSans(12, weight: .bold))
            HStack(spacing: 8) {
                ForEach(["🏯", "🏝️", "🎬", "🐶"], id: \.self) { e in
                    RoundedRectangle(cornerRadius: 8).fill(AlboColor.optionFill).frame(width: 52, height: 72).overlay(Text(e))
                }
            }
            Text("Collections ›").font(.alboSans(12, weight: .bold))
            ForEach(["I'm Totally Coming Back To This Later", "Brussels Baybeee"], id: \.self) { name in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6).fill(AlboColor.optionFill).frame(width: 34, height: 34)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("🔒 Private").font(.alboSans(8)).foregroundStyle(AlboColor.muted)
                        Text(name).font(.alboSans(10, weight: .semibold)).lineLimit(1)
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .foregroundStyle(AlboColor.ink)
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
                        .font(.alboSans(18))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused)
                    if isValid {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(AlboColor.rewardGreen)
                            Text("Available").font(.alboSans(14, weight: .semibold)).foregroundStyle(AlboColor.rewardGreen)
                        }
                    }
                }
                .padding(.horizontal, 18).frame(height: 58)
                .background(AlboColor.optionFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                HStack {
                    Text("3-20 characters, letters, numbers, and underscore...").font(.alboSans(13)).foregroundStyle(AlboColor.muted)
                    Spacer()
                    Text("\(username.count)/20").font(.alboSans(13)).foregroundStyle(AlboColor.muted).monospacedDigit()
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Username requirements:").font(.alboSans(15, weight: .semibold)).foregroundStyle(AlboColor.ink)
                    ForEach(rules, id: \.0) { rule in
                        HStack(spacing: 8) {
                            Image(systemName: rule.1 ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(rule.1 ? AlboColor.rewardGreen : AlboColor.muted)
                            Text(rule.0).font(.alboSans(15)).foregroundStyle(AlboColor.inkSecondary)
                        }
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AlboColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                .font(.alboSans(18))
                .focused($focused)
                .padding(.horizontal, 18).frame(height: 58)
                .background(AlboColor.optionFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                        Circle().fill(AlboColor.optionFill)
                        if hasPicked {
                            MascotView(variant: mascot).padding(28)
                        } else {
                            Image(systemName: "plus").font(.system(size: 44, weight: .light)).foregroundStyle(AlboColor.ink)
                        }
                    }
                    .frame(width: 160, height: 160)
                }
                .buttonStyle(PressableButtonStyle())
                Text(name.isEmpty ? "You" : name).font(.alboSans(22, weight: .bold)).foregroundStyle(AlboColor.ink)
                Text("@\(handle)").font(.alboSans(16)).foregroundStyle(AlboColor.muted)
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

struct FeatureCarouselStep: View {
    let onContinue: () -> Void
    @State private var page = 0

    struct Card: Identifiable { let id = UUID(); let category: SaveCategory?; let headline: String; let emoji: String; let tint: Color; let chip: (String, String, String)? }

    private let cards: [Card] = [
        Card(category: .film, headline: "See a film you love? Save it to Albo in one tap.", emoji: "🎬", tint: Color(hex: 0x2B2D42), chip: ("🎬", "Once Upon a Tim...", "Comedy · 2019")),
        Card(category: .recipe, headline: "See a recipe you love? Save it to Albo in one tap.", emoji: "🍤", tint: Color(hex: 0xE07A5F), chip: ("🍝", "Garlic Prawn Pasta", "30 minutes")),
        Card(category: .place, headline: "See a spot you love? Save it to Albo in one tap.", emoji: "🍽️", tint: Color(hex: 0x3D405B), chip: ("📍", "VIBEY LONDON RESTAURANTS", "for 2025")),
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
                            if let chip = card.chip {
                                HStack(spacing: 10) {
                                    Text(chip.0).font(.system(size: 26)).frame(width: 44, height: 44).background(AlboColor.optionFill, in: RoundedRectangle(cornerRadius: 10))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(chip.1).font(.alboSans(15, weight: .semibold)).lineLimit(1)
                                        Text(chip.2).font(.alboSans(13)).foregroundStyle(AlboColor.muted)
                                    }
                                }
                                .padding(12)
                                .background(AlboColor.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
             + Text(text[range]).foregroundStyle(AlboColor.categoryPurple)
             + Text(text[range.upperBound...]))
                .alboText(.onboardingHeadline)
        } else {
            Text(text).alboText(.onboardingHeadline)
        }
    }
}

// MARK: - #19 Habits

struct HabitsStep: View {
    @Binding var selection: Set<SavingHabit>
    let onContinue: () -> Void
    var body: some View {
        OnboardingPage(headline: "Where do you save things at the moment?", subline: "Helps us make Albo feel like home faster.", buttonTitle: "Continue", buttonEnabled: !selection.isEmpty, onContinue: onContinue) {
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
        OnboardingPage(headline: "No problem!", subline: "Albo can import anything from Instagram, TikTok, Facebook, Pinterest and YouTube.", buttonTitle: "Show me how", centered: true, onContinue: onContinue) {
            ZStack {
                PhoneMockup(width: 220) {
                    VStack { Spacer(); Text("🎥").font(.system(size: 80)); Spacer() }.frame(maxWidth: .infinity)
                }
                ForEach(Array(["📌", "📘", "📸", "🎵", "📷"].enumerated()), id: \.offset) { i, e in
                    Text(e).font(.system(size: 28)).frame(width: 56, height: 56)
                        .background(AlboColor.card, in: Circle()).shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                        .offset(x: cos(Double(i) * 1.26) * 150, y: sin(Double(i) * 1.26) * 170)
                }
            }
            .frame(height: 480)
        }
    }
}

// MARK: - #21 Interests

struct InterestsStep: View {
    @Binding var selection: Set<ContentInterest>
    let onContinue: () -> Void
    var body: some View {
        OnboardingPage(headline: "What kind of videos, posts or links do you typically save?", subline: "Pick anything that catches your eye.", buttonTitle: "Continue", buttonEnabled: !selection.isEmpty, onContinue: onContinue) {
            VStack(spacing: 10) {
                ForEach(ContentInterest.allCases) { c in
                    OptionPill(emoji: c.emoji, title: c.title, isSelected: selection.contains(c)) {
                        if selection.contains(c) { selection.remove(c) } else { selection.insert(c) }
                    }
                }
            }
        }
    }
}
