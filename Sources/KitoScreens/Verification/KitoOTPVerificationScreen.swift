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
    @Environment(\.kitoScreenTheme) private var theme

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
                    .onComplete { value in
                        // Auto-submit on the last digit doesn't go through the button, so it gets
                        // no phase feedback of its own — the field's own shake/error still applies.
                        Task { try? await verify(value) }
                    }
                if let onResend {
                    KitoResendLink(cooldown: resendCooldown, isBusy: $isResending) {
                        try await onResend()
                    }
                }
            }
        } footer: {
            // An async action (rather than firing a detached Task and returning immediately)
            // is what lets showsResult()/successTitle() actually reflect submit's outcome.
            KitoButton(KitoScreensLocalization.string("otp.continueButton", "Continue")) {
                try await verify(code)
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

    private func verify(_ value: String) async throws {
        guard value.count == length, !isVerifying else { return }
        errorMessage = nil
        isVerifying = true
        defer { isVerifying = false }
        do {
            let outcome = try await submit(value)
            if case .failure(let message) = outcome {
                errorMessage = message.isEmpty ? KitoScreensLocalization.string("otp.incorrectCode", "Incorrect code") : message
                code = ""
                throw KitoScreenError.rejected
            }
        } catch {
            if errorMessage == nil { errorMessage = KitoScreensLocalization.string("otp.incorrectCode", "Incorrect code") }
            code = ""
            throw error
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
    @Environment(\.kitoScreenTheme) private var theme

    var body: some View {
        Button(action: resend) {
            if isBusy {
                ProgressView().scaleEffect(0.8)
            } else {
                Text(remaining > 0 ? KitoScreensLocalization.format("otp.resendIn", "Resend in %ds", remaining) : KitoScreensLocalization.string("otp.resend", "Resend code"))
                    .font(theme.captionFont)
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
            // Only start the cooldown once the resend actually went out — a failed send
            // (network error, server rejection) should leave the link enabled to retry.
            do {
                try await action()
                remaining = Int(cooldown.rounded(.up))
                startCountdown()
            } catch {
                // Leave `remaining` at 0; the link stays tappable.
            }
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
