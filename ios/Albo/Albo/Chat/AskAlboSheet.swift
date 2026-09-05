import SwiftUI

struct ChatMessage: Identifiable, Equatable {
    enum Role { case user, assistant }
    let id = UUID()
    let role: Role
    var text: String
}

/// Ask Albo, global or scoped to one save (Albo #57 to #59, #93 to #95, #128, #129).
struct AskAlboSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let scope: Save?

    @State private var messages: [ChatMessage] = []
    @State private var input = ""
    @State private var thinking = false
    @State private var confirmClear = false
    @FocusState private var focused: Bool

    private var isPro: Bool { app.entitlement != .free }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                MascotView().frame(width: 28, height: 28)
                Text("Ask Albo").font(.alboSans(20, weight: .bold)).foregroundStyle(AlboColor.ink)
                Spacer()
                if !messages.isEmpty {
                    Button { confirmClear = true } label: { Image(systemName: "arrow.clockwise").font(.system(size: 18, weight: .semibold)).foregroundStyle(AlboColor.ink) }
                        .accessibilityLabel("Clear chat")
                }
            }
            .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 10)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 14) {
                        if messages.isEmpty {
                            VStack(spacing: 14) {
                                ZStack {
                                    Circle().fill(AlboColor.optionFill).frame(width: 120, height: 120)
                                    if let scope { Text(scope.coverEmoji ?? scope.category.emoji).font(.system(size: 54)) } else { MascotView().frame(width: 62) }
                                }
                                Text(scope.map { "Ask Albo about \($0.title)" } ?? "Ask Albo about anything you've saved")
                                    .font(.alboSans(17)).foregroundStyle(AlboColor.inkSecondary).multilineTextAlignment(.center)
                                if !isPro {
                                    Button { dismiss(); app.showPaywall = true } label: {
                                        Text("AI chat is a Pro feature. Start your free trial").font(.alboSans(14, weight: .semibold)).foregroundStyle(AlboColor.systemBlue)
                                    }
                                }
                            }
                            .padding(.top, 40)
                        }
                        ForEach(messages) { m in
                            MessageBubble(message: m, onRegenerate: { regenerate() })
                                .id(m.id)
                        }
                        if thinking {
                            HStack(spacing: 6) {
                                ForEach(0..<3, id: \.self) { _ in Circle().fill(AlboColor.muted).frame(width: 7, height: 7) }
                            }
                            .padding(14).background(AlboColor.optionFill, in: RoundedRectangle(cornerRadius: 18))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(20)
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                }
            }

            HStack(spacing: 10) {
                TextField("Ask anything...", text: $input, axis: .vertical)
                    .font(.alboSans(17))
                    .lineLimit(1...4)
                    .focused($focused)
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .background(AlboColor.optionFill, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                Button(action: send) {
                    Image(systemName: "arrow.up").font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 44, height: 44).background(AlboColor.ink, in: Circle())
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || thinking)
                .accessibilityLabel("Send")
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(AlboColor.card)
        }
        .background(AlboColor.card)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .confirmationDialog("Clear chat?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear", role: .destructive) { messages = [] }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete the messages in this conversation.")
        }
        .onAppear { focused = scope == nil }
    }

    private func send() {
        let q = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        input = ""
        messages.append(ChatMessage(role: .user, text: q))
        ask(q)
    }

    private func regenerate() {
        guard let lastUser = messages.last(where: { $0.role == .user }) else { return }
        if let i = messages.lastIndex(where: { $0.role == .assistant }) { messages.remove(at: i) }
        ask(lastUser.text)
    }

    private func ask(_ q: String) {
        thinking = true
        Task {
            let history = messages.filter { $0.role == .user || $0.role == .assistant }
            do {
                let answer = try await AskAlboService.answer(q, saves: app.saves, scope: scope, history: history)
                messages.append(ChatMessage(role: .assistant, text: answer))
            } catch {
                messages.append(ChatMessage(role: .assistant, text: error.localizedDescription))
                if case BackendError.proRequired = error { app.showPaywall = true }
            }
            thinking = false
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let onRegenerate: () -> Void
    @State private var copied = false

    var body: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
            Text(message.text)
                .font(.alboSans(16))
                .foregroundStyle(message.role == .user ? .white : AlboColor.ink)
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(message.role == .user ? AlboColor.ink : AlboColor.optionFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .textSelection(.enabled)
            if message.role == .assistant {
                HStack(spacing: 16) {
                    Button { UIPasteboard.general.string = message.text; copied = true } label: { Image(systemName: copied ? "checkmark" : "doc.on.doc") }
                    Button(action: onRegenerate) { Image(systemName: "arrow.clockwise") }
                    Button {} label: { Image(systemName: "hand.thumbsup") }
                    Button {} label: { Image(systemName: "hand.thumbsdown") }
                }
                .font(.system(size: 14))
                .foregroundStyle(AlboColor.muted)
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
}
