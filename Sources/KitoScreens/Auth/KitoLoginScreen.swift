//
//  KitoLoginScreen.swift
//  KitoScreens
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI
import KitoFields
import KitoButtons

/// Email + password sign-in with validation, reveal toggle, "forgot password", optional
/// social buttons and an async submit that shows a spinner and inline server errors.
///
/// ```swift
/// KitoLoginScreen(title: "Welcome back") { credentials in
///     try await auth.signIn(credentials.email, credentials.password)
///     return .success
/// }
/// .forgotPassword { showReset = true }
/// .socialProviders([.apple, .google]) { provider in … }
/// ```
public struct KitoLoginScreen: View {
    public struct Credentials: Sendable, Equatable {
        public let email: String
        public let password: String
    }

    public enum SocialProvider: String, CaseIterable, Identifiable, Sendable {
        case apple, google, facebook
        public var id: String { rawValue }
        var title: String { KitoScreensLocalization.format("login.continueWith", "Continue with %@", rawValue.capitalized) }
        var symbol: String { self == .apple ? "apple.logo" : self == .google ? "globe" : "f.circle" }
    }

    private let title: String
    private let subtitle: String?
    private let submit: (Credentials) async throws -> KitoScreenOutcome
    private var onForgotPassword: (() -> Void)?
    private var onCreateAccount: (() -> Void)?
    private var socialProviders: [SocialProvider] = []
    private var onSocial: ((SocialProvider) -> Void)?
    private var usesPhoneInsteadOfEmail = false
    private var logo: AnyView?

    @State private var email = ""
    @State private var phone: KitoPhoneNumber?
    @State private var password = ""
    @State private var emailValid = false
    @State private var phoneValid = false
    @State private var passwordValid = false
    @State private var serverError: String?
    @State private var passwordFocused = false

    public init(title: String = KitoScreensLocalization.string("login.title", "Sign in"), subtitle: String? = KitoScreensLocalization.string("login.subtitle", "Welcome back. Enter your details to continue."), submit: @escaping (Credentials) async throws -> KitoScreenOutcome) {
        self.title = title; self.subtitle = subtitle; self.submit = submit
    }

    private var canSubmit: Bool { (usesPhoneInsteadOfEmail ? phoneValid : emailValid) && passwordValid }

    public var body: some View {
        KitoScreenScaffold(header: header) {
            if usesPhoneInsteadOfEmail {
                KitoPhoneField(KitoScreensLocalization.string("field.mobileNumber", "Mobile number"), phoneNumber: $phone).required().isValid($phoneValid).onSubmit { passwordFocused = true }
            } else {
                KitoEmailField(text: $email).leadingIcon("envelope", focused: "envelope.open.fill", motion: .wiggle).required().isValid($emailValid).errorMessage(serverError).onSubmit { passwordFocused = true }
            }
            KitoPasswordField(text: $password).animatedLockIcon().required().isValid($passwordValid).focused($passwordFocused)
            if let onForgotPassword {
                HStack { Spacer(); KitoButton(KitoScreensLocalization.string("login.forgotPassword", "Forgot password?")) { onForgotPassword() }.variant(.link).size(.small) }
            }
        } footer: {
            KitoButton(title) {
                serverError = nil
                let outcome = try await submit(Credentials(email: usesPhoneInsteadOfEmail ? (phone?.e164 ?? "") : email, password: password))
                if case .failure(let message) = outcome { serverError = message; throw KitoScreenError.rejected }
            }
            .showsResult(success: false)
            .size(.large).fullWidth()
            .disabled(!canSubmit)

            if !socialProviders.isEmpty {
                HStack { Rectangle().fill(Color.primary.opacity(0.15)).frame(height: 1); Text(KitoScreensLocalization.string("login.or", "or")).font(.footnote).foregroundColor(.secondary); Rectangle().fill(Color.primary.opacity(0.15)).frame(height: 1) }
                ForEach(socialProviders) { provider in
                    KitoButton(provider.title, systemImage: provider.symbol) { onSocial?(provider) }
                        .variant(provider == .apple ? .primary : .outlined).fullWidth()
                }
            }
            if let onCreateAccount {
                HStack(spacing: 4) {
                    Text(KitoScreensLocalization.string("login.newHere", "New here?")).font(.footnote).foregroundColor(.secondary)
                    KitoButton(KitoScreensLocalization.string("login.createAccount", "Create an account")) { onCreateAccount() }.variant(.link).size(.small)
                }
            }
        }
    }

    private var header: KitoScreenHeader {
        if let logo { return KitoScreenHeader(title, subtitle: subtitle) { logo } }
        return KitoScreenHeader(title, subtitle: subtitle)
    }

    private func mutating(_ change: (inout KitoLoginScreen) -> Void) -> KitoLoginScreen { var c = self; change(&c); return c }
    public func forgotPassword(_ action: @escaping () -> Void) -> KitoLoginScreen { mutating { $0.onForgotPassword = action } }
    public func createAccount(_ action: @escaping () -> Void) -> KitoLoginScreen { mutating { $0.onCreateAccount = action } }
    public func socialProviders(_ providers: [SocialProvider], _ action: @escaping (SocialProvider) -> Void) -> KitoLoginScreen { mutating { $0.socialProviders = providers; $0.onSocial = action } }
    /// Sign in with a phone number instead of an email address.
    public func usesPhone(_ enabled: Bool = true) -> KitoLoginScreen { mutating { $0.usesPhoneInsteadOfEmail = enabled } }
    public func logo<Logo: View>(@ViewBuilder _ logo: () -> Logo) -> KitoLoginScreen { var c = self; c.logo = AnyView(logo()); return c }
}

enum KitoScreenError: Error { case rejected }
