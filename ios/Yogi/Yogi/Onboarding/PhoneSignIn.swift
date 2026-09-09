import SwiftUI

// MARK: - Country dialling codes

struct DiallingCode: Identifiable, Hashable {
    var id: String { code }
    let flag: String
    let code: String      // "+44"
    let name: String

    static let common: [DiallingCode] = [
        DiallingCode(flag: "🇺🇸", code: "+1", name: "United States"),
        DiallingCode(flag: "🇬🇧", code: "+44", name: "United Kingdom"),
        DiallingCode(flag: "🇨🇦", code: "+1", name: "Canada"),
        DiallingCode(flag: "🇦🇺", code: "+61", name: "Australia"),
        DiallingCode(flag: "🇮🇪", code: "+353", name: "Ireland"),
        DiallingCode(flag: "🇩🇪", code: "+49", name: "Germany"),
        DiallingCode(flag: "🇫🇷", code: "+33", name: "France"),
        DiallingCode(flag: "🇪🇸", code: "+34", name: "Spain"),
        DiallingCode(flag: "🇮🇹", code: "+39", name: "Italy"),
        DiallingCode(flag: "🇳🇱", code: "+31", name: "Netherlands"),
        DiallingCode(flag: "🇵🇭", code: "+63", name: "Philippines"),
        DiallingCode(flag: "🇮🇳", code: "+91", name: "India"),
        DiallingCode(flag: "🇯🇵", code: "+81", name: "Japan"),
        DiallingCode(flag: "🇧🇷", code: "+55", name: "Brazil"),
        DiallingCode(flag: "🇲🇽", code: "+52", name: "Mexico"),
    ]

    /// Best guess from the device region, so most people never open the picker.
    static var deviceDefault: DiallingCode {
        let region = Locale.current.region?.identifier ?? "US"
        let byRegion: [String: String] = [
            "US": "United States", "GB": "United Kingdom", "CA": "Canada", "AU": "Australia",
            "IE": "Ireland", "DE": "Germany", "FR": "France", "ES": "Spain", "IT": "Italy",
            "NL": "Netherlands", "PH": "Philippines", "IN": "India", "JP": "Japan",
            "BR": "Brazil", "MX": "Mexico",
        ]
        let name = byRegion[region] ?? "United States"
        return common.first { $0.name == name } ?? common[0]
    }
}

// MARK: - Phone entry

/// Step one of sign in: the number. No password, no third-party button.
struct PhoneSignInStep: View {
    let onCodeSent: (String) -> Void          // E.164 number

    @Environment(AppState.self) private var app
    @State private var country = DiallingCode.deviceDefault
    @State private var number = ""
    @State private var sending = false
    @FocusState private var focused: Bool

    /// Digits only, prefixed with the dialling code: what the API wants.
    private var e164: String { country.code + number.filter(\.isNumber) }
    private var isValid: Bool { number.filter(\.isNumber).count >= 7 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)

            Text("What's your number?")
                .font(.yogiDisplay(38))
                .foregroundStyle(YogiColor.ink)
            Text(orphanSafe: "We'll text you a code. Nothing to remember, no password to lose.")
                .font(.yogiSans(17))
                .foregroundStyle(YogiColor.inkSecondary)
                .padding(.top, 8)

            HStack(spacing: 10) {
                Menu {
                    ForEach(DiallingCode.common) { c in
                        Button { country = c } label: { Text("\(c.flag)  \(c.name)  \(c.code)") }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(country.flag).font(.system(size: 22))
                        Text(country.code).font(.yogiSans(18, weight: .semibold)).foregroundStyle(YogiColor.ink)
                        Image(systemName: "chevron.down").font(.system(size: 12, weight: .semibold)).foregroundStyle(YogiColor.muted)
                    }
                    .padding(.horizontal, 16).frame(height: 62)
                    .background(YogiColor.optionFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                TextField("Phone number", text: $number)
                    .font(.yogiSans(20))
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .focused($focused)
                    .padding(.horizontal, 18).frame(height: 62)
                    .background(YogiColor.optionFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .padding(.top, 28)

            Spacer(minLength: 0)

            PrimaryButton(title: "Send code", isEnabled: isValid && !sending, isLoading: sending) { send() }

            Text(orphanSafe: "By continuing you agree to our Terms and Privacy Policy. Message and data rates may apply.")
                .font(.yogiSans(13))
                .foregroundStyle(YogiColor.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(YogiColor.ground)
        .onAppear { focused = true }
    }

    private func send() {
        sending = true
        Haptics.tap()
        Task {
            do {
                try await AuthService.sendCode(to: e164)
                sending = false
                onCodeSent(e164)
            } catch {
                sending = false
                app.showToast("Couldn't send the code. Check the number and try again.")
            }
        }
    }
}

// MARK: - Code entry

/// Step two: the six digits. Auto-submits so nobody hunts for a button.
struct VerifyCodeStep: View {
    let phone: String
    let onVerified: () -> Void
    let onChangeNumber: () -> Void

    @Environment(AppState.self) private var app
    @State private var code = ""
    @State private var verifying = false
    @State private var secondsLeft = 30
    @FocusState private var focused: Bool

    private let length = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)

            Text("Enter the code")
                .font(.yogiDisplay(38))
                .foregroundStyle(YogiColor.ink)

            HStack(spacing: 6) {
                Text("Sent to \(phone).").font(.yogiSans(17)).foregroundStyle(YogiColor.inkSecondary)
                Button("Change", action: onChangeNumber)
                    .font(.yogiSans(17, weight: .semibold))
                    .foregroundStyle(YogiColor.systemBlue)
            }
            .padding(.top, 8)

            boxes.padding(.top, 30)

            Button(action: resend) {
                Text(secondsLeft > 0 ? "Resend in \(secondsLeft)s" : "Resend code")
                    .font(.yogiSans(16, weight: .medium))
                    .foregroundStyle(secondsLeft > 0 ? YogiColor.muted : YogiColor.systemBlue)
            }
            .disabled(secondsLeft > 0)
            .padding(.top, 18)

            Spacer(minLength: 0)

            PrimaryButton(title: "Verify", isEnabled: code.count == length && !verifying, isLoading: verifying) { verify() }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(YogiColor.ground)
        .onAppear { focused = true; tick() }
    }

    /// Six boxes over one hidden field: the system keyboard and SMS autofill both
    /// want a single text field, but the design wants separate digits.
    private var boxes: some View {
        ZStack {
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($focused)
                .opacity(0.001)
                .onChange(of: code) { _, new in
                    code = String(new.filter(\.isNumber).prefix(length))
                    if code.count == length { verify() }
                }

            HStack(spacing: 10) {
                ForEach(0..<length, id: \.self) { i in
                    let digit = i < code.count ? String(Array(code)[i]) : ""
                    let active = i == code.count && focused
                    Text(digit)
                        .font(.yogiSans(26, weight: .semibold))
                        .foregroundStyle(YogiColor.ink)
                        .frame(maxWidth: .infinity).frame(height: 66)
                        .background(YogiColor.optionFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(YogiColor.ink, lineWidth: active ? 2 : 0)
                        }
                }
            }
            .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture { focused = true }
    }

    private func tick() {
        guard secondsLeft > 0 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            secondsLeft -= 1
            tick()
        }
    }

    private func resend() {
        secondsLeft = 30
        tick()
        Task {
            try? await AuthService.sendCode(to: phone)
            app.showToast("New code sent")
        }
    }

    private func verify() {
        guard !verifying else { return }
        verifying = true
        Task {
            do {
                try await AuthService.verify(phone: phone, code: code)
                Haptics.success()
                verifying = false
                onVerified()
            } catch {
                Haptics.warning()
                verifying = false
                code = ""
                app.showToast("That code didn't work. Try again.")
            }
        }
    }
}
