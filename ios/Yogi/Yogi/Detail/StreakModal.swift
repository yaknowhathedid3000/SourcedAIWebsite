import SwiftUI

/// "1 week streak" modal after marking a save done (Albo #78, #79).
struct StreakModal: View {
    let weeks: Int
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea().onTapGesture(perform: onDismiss)
            VStack(spacing: 14) {
                ZStack {
                    ForEach(0..<10, id: \.self) { i in
                        Text("🔥").font(.system(size: 26))
                            .offset(x: cos(Double(i) * 0.63) * 110, y: sin(Double(i) * 0.63) * 60)
                            .opacity(0.9)
                    }
                    Text("\(weeks)").font(.yogiSans(96, weight: .black)).foregroundStyle(YogiColor.ink)
                }
                .frame(height: 170)
                Text("week streak").font(.yogiSans(22, weight: .bold)).foregroundStyle(YogiColor.ink)
                Text("Keep marking saves as done to extend your streak.")
                    .font(.yogiSans(16)).foregroundStyle(YogiColor.inkSecondary).multilineTextAlignment(.center)
                PrimaryButton(title: "Continue", action: onDismiss).padding(.top, 8)
            }
            .padding(28)
            .background(YogiColor.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding(.horizontal, 28)
        }
    }
}
