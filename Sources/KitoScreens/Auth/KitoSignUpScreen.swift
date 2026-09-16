//
//  KitoSignUpScreen.swift
//  KitoScreens
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI
import KitoFields
import KitoButtons

/// Name, email, phone, password and confirmation with strength meter and requirements, terms
/// acceptance, and an async submit.
public struct KitoSignUpScreen: View {
    public struct Registration: Sendable, Equatable {
        public let name: String
        public let email: String
        public let phone: String?
        public let password: String
        public let country: String?
    }

    private let title: String
    private let subtitle: String?
    private let submit: (Registration) async throws -> KitoScreenOutcome
    private var includesPhone = true
    private var includesCountry = false
    private var termsURL: URL?
    private var onSignIn: (() -> Void)?
    private var passwordRules: [KitoRule] = KitoRule.strongPassword()

    @State private var name = ""
    @State private var email = ""
    @State private var phone: KitoPhoneNumber?
    @State private var country: KitoCountry?
    @State private var password = ""
    @State private var confirm = ""
    @State private var acceptedTerms = false
    @State private var valid = [String: Bool]()
    @State private var serverError: String?

    public init(title: String = "Create your account", subtitle: String? = "It takes less than a minute.", submit: @escaping (Registration) async throws -> KitoScreenOutcome) {
        self.title = title; self.subtitle = subtitle; self.submit = submit
    }

    private func bind(_ key: String) -> Binding<Bool> { Binding(get: { valid[key] ?? false }, set: { valid[key] = $0 }) }

    private var canSubmit: Bool {
        let required = ["name", "email", "password", "confirm"] + (includesPhone ? ["phone"] : []) + (includesCountry ? ["country"] : [])
        return required.allSatisfy { valid[$0] ?? false } && (termsURL == nil || acceptedTerms)
    }

    public var body: some View {
        KitoScreenScaffold(header: KitoScreenHeader(title, subtitle: subtitle)) {
            KitoNameField(text: $name, prompt: "Jane Doe").required().isValid(bind("name"))
            KitoEmailField(text: $email).suggestsDomainCorrections().required().validationIndicators().isValid(bind("email")).errorMessage(serverError)
            if includesPhone {
                KitoPhoneField("Mobile number", phoneNumber: $phone).flagStyle(.circle).required().validationIndicators().isValid(bind("phone"))
            }
            if includesCountry {
                KitoCountryField("Country", selection: $country).flagStyle(.circle).required().isValid(bind("country"))
            }
            KitoPasswordField(text: $password).newPassword().animatedLockIcon().required().strengthMeter().requirements(passwordRules).isValid(bind("password"))
            KitoPasswordField("Confirm password", text: $confirm, prompt: "Re-enter your password").required().mustMatch($password).validationTrigger(.live).isValid(bind("confirm"))
            if let termsURL {
                Toggle(isOn: $acceptedTerms) {
                    HStack(spacing: 4) {
                        Text("I agree to the").font(.footnote)
                        Link("terms and privacy policy", destination: termsURL).font(.footnote.weight(.semibold))
                    }
                }
                .toggleStyle(.switch)
            }
        } footer: {
            KitoButton(title) {
                serverError = nil
                let outcome = try await submit(Registration(name: name, email: email, phone: phone?.e164, password: password, country: country?.isoCode))
                if case .failure(let message) = outcome { serverError = message; throw KitoScreenError.rejected }
            }
            .showsResult()
            .successTitle("Account created")
            .size(.large).fullWidth()
            .disabled(!canSubmit)
            if let onSignIn {
                HStack(spacing: 4) {
                    Text("Already have an account?").font(.footnote).foregroundColor(.secondary)
                    KitoButton("Sign in") { onSignIn() }.variant(.link).size(.small)
                }
            }
        }
    }

    private func mutating(_ change: (inout KitoSignUpScreen) -> Void) -> KitoSignUpScreen { var c = self; change(&c); return c }
    public func includesPhone(_ enabled: Bool) -> KitoSignUpScreen { mutating { $0.includesPhone = enabled } }
    public func includesCountry(_ enabled: Bool) -> KitoSignUpScreen { mutating { $0.includesCountry = enabled } }
    /// Adds an "I agree" toggle linking to your terms; submission requires it.
    public func terms(_ url: URL) -> KitoSignUpScreen { mutating { $0.termsURL = url } }
    public func signIn(_ action: @escaping () -> Void) -> KitoSignUpScreen { mutating { $0.onSignIn = action } }
    public func passwordRules(_ rules: [KitoRule]) -> KitoSignUpScreen { mutating { $0.passwordRules = rules } }
}
