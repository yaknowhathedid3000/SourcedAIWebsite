import SwiftUI

/// "How the trial works": timeline paywall with a single yearly SKU and a soft close (Albo #41 to #43).
struct PaywallView: View {
    @Environment(AppState.self) private var app
    let onDismiss: () -> Void
    var onPurchased: (() -> Void)? = nil
    @State private var purchasing = false
    @State private var showSuccess = false

    private var billingDate: String {
        PurchaseService.billingDate.formatted(.dateTime.month(.wide).day().year())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "arrow.left").font(.system(size: 22, weight: .medium)).foregroundStyle(YogiColor.ink).frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark").font(.system(size: 20, weight: .medium)).foregroundStyle(YogiColor.ink).frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Text("How the trial works").yogiText(.onboardingHeadline).padding(.horizontal, 24).padding(.top, 12)

            VStack(alignment: .leading, spacing: 0) {
                TimelineRow(color: YogiColor.rewardGreen, symbol: "lock.open.fill", title: "Today",
                            text: "Unlock access to all the app's features like unlimited saves & bulk importing saves from other apps.", isLast: false)
                TimelineRow(color: YogiColor.danger, symbol: "bell.fill", title: "In 2 Days - Reminder",
                            text: "We'll send you a reminder that your trial is ending soon.", isLast: false)
                TimelineRow(color: YogiColor.optionFill, symbol: "crown.fill", symbolTint: YogiColor.star, title: "In 3 Days - Billing Starts",
                            text: "You'll be charged on \(billingDate) unless you cancel anytime before.", isLast: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Spacer()

            VStack(spacing: 14) {
                NoPaymentDueNow()
                PrimaryButton(title: "Start My \(PurchaseService.trialDays)-Day Free Trial", isLoading: purchasing) {
                    purchasing = true
                    Task {
                        let ok = await PurchaseService.purchaseYearly()
                        purchasing = false
                        if ok {
                            app.entitlement = .pro
                            showSuccess = true
                        } else {
                            app.showToast("Purchase didn't go through")
                        }
                    }
                }
                Text("\(PurchaseService.trialDays) days free, then \(PurchaseService.yearlyPrice) per year")
                    .font(.yogiSans(17)).foregroundStyle(YogiColor.inkSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(YogiColor.ground.ignoresSafeArea())
        .task { await PurchaseService.loadProducts() }
        .alert("You're all set.", isPresented: $showSuccess) {
            Button("OK") { (onPurchased ?? onDismiss)() }
        } message: {
            Text("Your purchase was successful.")
        }
    }
}

struct TimelineRow: View {
    let color: Color
    let symbol: String
    var symbolTint: Color = .white
    let title: String
    let text: String
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(color).frame(width: 48, height: 48)
                    Image(systemName: symbol).font(.system(size: 20, weight: .bold)).foregroundStyle(symbolTint)
                }
                if !isLast {
                    Rectangle().fill(YogiColor.hairline).frame(width: 2).frame(maxHeight: .infinity)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.yogiSans(20, weight: .bold)).foregroundStyle(YogiColor.ink)
                Text(text).font(.yogiSans(17)).foregroundStyle(YogiColor.inkSecondary).fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, isLast ? 0 : 28)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// Settings > Manage Subscription sheet with Pro / Max cards (Albo #198).
struct ManageSubscriptionSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var choice: Entitlement = .pro
    @State private var confirmCancel = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule().fill(YogiColor.hairline).frame(width: 40, height: 5).frame(maxWidth: .infinity).padding(.top, 8)
            Text("Manage Subscription").yogiText(.onboardingHeadline)
            Text("Choose your plan").font(.yogiSans(17)).foregroundStyle(YogiColor.inkSecondary)
            PlanCard(mascot: .king, title: "Pro", subtitle: "Unlimited imports, AI chat & limited bulk import", isSelected: choice == .pro) { choice = .pro }
            PlanCard(mascot: .max, title: "Max", subtitle: "Unlimited bulk import, early access to Pro features", isSelected: choice == .max) { choice = .max }
            Spacer(minLength: 8)
            PrimaryButton(title: "Change my plan") {
                app.entitlement = choice
                app.showToast("You're on \(choice.title)")
                dismiss()
            }
            PrimaryButton(title: "Cancel my subscription", style: .danger) { confirmCancel = true }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .background(YogiColor.card)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .onAppear { choice = app.entitlement == .free ? .pro : app.entitlement }
        .confirmationDialog("Cancel your subscription?", isPresented: $confirmCancel, titleVisibility: .visible) {
            Button("Cancel subscription", role: .destructive) {
                app.entitlement = .free
                app.showToast("Subscription cancelled")
                dismiss()
            }
            Button("Keep it", role: .cancel) {}
        }
    }
}

struct PlanCard: View {
    let mascot: MascotVariant
    let title: String
    let subtitle: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                MascotView(variant: mascot).frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.yogiSans(22, weight: .bold)).foregroundStyle(YogiColor.ink)
                    Text(subtitle).font(.yogiSans(15)).foregroundStyle(YogiColor.inkSecondary).multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right")
                    .font(.system(size: isSelected ? 26 : 16, weight: .semibold)).foregroundStyle(YogiColor.ink)
            }
            .padding(18)
            .background(YogiColor.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(YogiColor.ink, lineWidth: isSelected ? 0 : 1.5))
        }
        .buttonStyle(PressableButtonStyle())
    }
}
