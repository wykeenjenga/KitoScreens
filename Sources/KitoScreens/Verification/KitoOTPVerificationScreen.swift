//
//  KitoOTPVerificationScreen.swift
//  KitoScreens
//
//  Created by Wycliff Njenga on 18/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI
import KitoFields
import KitoButtons

/// One-time-code verification: shows where the code was sent, a `KitoCodeField`, a resend link
/// with a cooldown, and a submit button that shakes and clears the boxes on a wrong code.
///
/// ```swift
/// KitoOTPVerificationScreen(destination: phone.international, length: 6) { code in
///     try await auth.verify(code)
///     return .success
/// }
/// .resend { try await auth.resendCode() }
/// ```
public struct KitoOTPVerificationScreen: View {
    private let destination: String
    private let length: Int
    private let submit: (String) async throws -> KitoScreenOutcome
    private var onResend: (() async throws -> Void)?
    private var resendCooldown: TimeInterval = 30
    private var logo: AnyView?

    @State private var code = ""
    @State private var errorMessage: String?
    @State private var isVerifying = false
    @State private var isResending = false

    /// - Parameters:
    ///   - destination: Where the code was sent, already formatted for display (e.g. a masked
    ///     phone number or email address).
    ///   - length: Digit count, matching whatever your backend sends (defaults to 6).
    ///   - submit: Called with the completed code once every box is filled.
    public init(destination: String, length: Int = 6, submit: @escaping (String) async throws -> KitoScreenOutcome) {
        self.destination = destination
        self.length = length
        self.submit = submit
    }

    public var body: some View {
        KitoScreenScaffold(header: header) {
            VStack(spacing: 14) {
                KitoCodeField(code: $code, length: length)
                    .errorMessage(errorMessage)
                    .onComplete { verify($0) }
                if let onResend {
                    KitoResendLink(cooldown: resendCooldown, isBusy: $isResending) {
                        try await onResend()
                    }
                }
            }
        } footer: {
            KitoButton(KitoScreensLocalization.string("otp.continueButton", "Continue")) {
                verify(code)
            }
            .showsResult()
            .successTitle(KitoScreensLocalization.string("otp.verified", "Verified"))
            .size(.large).fullWidth()
            .disabled(code.count != length || isVerifying)
        }
    }

    private var header: KitoScreenHeader {
        let title = KitoScreensLocalization.string("otp.title", "Verify your number")
        let subtitle = KitoScreensLocalization.format("otp.subtitleFormat", "Enter the code we sent to %@", destination)
        if let logo { return KitoScreenHeader(title, subtitle: subtitle) { logo } }
        return KitoScreenHeader(title, subtitle: subtitle)
    }

    private func verify(_ value: String) {
        guard value.count == length, !isVerifying else { return }
        errorMessage = nil
        isVerifying = true
        Task {
            defer { isVerifying = false }
            do {
                let outcome = try await submit(value)
                if case .failure(let message) = outcome {
                    errorMessage = message.isEmpty ? KitoScreensLocalization.string("otp.incorrectCode", "Incorrect code") : message
                    code = ""
                }
            } catch {
                errorMessage = KitoScreensLocalization.string("otp.incorrectCode", "Incorrect code")
                code = ""
            }
        }
    }

    private func mutating(_ change: (inout KitoOTPVerificationScreen) -> Void) -> KitoOTPVerificationScreen { var c = self; change(&c); return c }
    /// Shows a "Resend code" link under the field, with its own cooldown.
    public func resend(cooldown: TimeInterval = 30, _ action: @escaping () async throws -> Void) -> KitoOTPVerificationScreen {
        mutating { $0.onResend = action; $0.resendCooldown = cooldown }
    }
    public func logo<Logo: View>(@ViewBuilder _ logo: () -> Logo) -> KitoOTPVerificationScreen { var c = self; c.logo = AnyView(logo()); return c }
}

/// Local resend link with its own countdown. `KitoFields` ships an equivalent
/// `KitoResendCodeButton` from version 1.5.0; once this package's minimum is bumped past that,
/// this type can be replaced with it directly.
private struct KitoResendLink: View {
    let cooldown: TimeInterval
    @Binding var isBusy: Bool
    let action: () async throws -> Void

    @State private var remaining: Int = 0
    @State private var countdownTask: Task<Void, Never>?

    var body: some View {
        Button(action: resend) {
            if isBusy {
                ProgressView().scaleEffect(0.8)
            } else {
                Text(remaining > 0 ? KitoLocalization.format("code.resendIn", "Resend in %ds", remaining) : KitoLocalization.string("code.resend", "Resend code"))
                    .font(.footnote)
                    .underline(remaining == 0)
            }
        }
        .buttonStyle(.plain)
        .disabled(remaining > 0 || isBusy)
        .onDisappear { countdownTask?.cancel() }
    }

    private func resend() {
        guard remaining == 0, !isBusy else { return }
        isBusy = true
        Task {
            defer { isBusy = false }
            try? await action()
            remaining = Int(cooldown.rounded(.up))
            startCountdown()
        }
    }

    private func startCountdown() {
        countdownTask?.cancel()
        countdownTask = Task { @MainActor in
            while remaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                remaining -= 1
            }
        }
    }
}
