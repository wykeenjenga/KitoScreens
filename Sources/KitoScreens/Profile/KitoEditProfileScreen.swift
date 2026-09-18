//
//  KitoEditProfileScreen.swift
//  KitoScreens
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI
import KitoFields
import KitoButtons

/// Editable profile: avatar, name, username with availability check, email, phone, country,
/// date of birth, website and bio, with a save button that only enables when something changed.
public struct KitoEditProfileScreen: View {
    public struct Profile: Sendable, Equatable {
        public var name: String
        public var username: String
        public var email: String
        public var phoneE164: String
        public var countryISO: String?
        public var dateOfBirth: Date?
        public var website: String
        public var bio: String

        public init(name: String = "", username: String = "", email: String = "", phoneE164: String = "", countryISO: String? = nil, dateOfBirth: Date? = nil, website: String = "", bio: String = "") {
            self.name = name; self.username = username; self.email = email; self.phoneE164 = phoneE164
            self.countryISO = countryISO; self.dateOfBirth = dateOfBirth; self.website = website; self.bio = bio
        }
    }

    private let original: Profile
    private let save: (Profile) async throws -> KitoScreenOutcome
    private var usernameAvailability: ((String) async -> Bool)?
    private var avatar: AnyView?
    private var onChangeAvatar: (() -> Void)?

    @State private var draft: Profile
    @State private var phone: KitoPhoneNumber?
    @State private var country: KitoCountry?
    @State private var valid = [String: Bool]()
    @State private var serverError: String?

    public init(profile: Profile, save: @escaping (Profile) async throws -> KitoScreenOutcome) {
        original = profile
        self.save = save
        _draft = State(initialValue: profile)
        _phone = State(initialValue: KitoPhoneNumber(e164: profile.phoneE164))
        _country = State(initialValue: profile.countryISO.flatMap(KitoCountryDatabase.country(isoCode:)))
    }

    private func bind(_ key: String) -> Binding<Bool> { Binding(get: { valid[key] ?? true }, set: { valid[key] = $0 }) }
    private var hasChanges: Bool { draft != original }
    private var isValid: Bool { valid.values.allSatisfy { $0 } }

    public var body: some View {
        KitoScreenScaffold(header: KitoScreenHeader(KitoScreensLocalization.string("profile.title", "Edit profile"))) {
            HStack(spacing: 16) {
                (avatar ?? AnyView(Image(systemName: "person.crop.circle.fill").resizable().foregroundColor(.secondary)))
                    .frame(width: 72, height: 72).clipShape(Circle())
                VStack(alignment: .leading, spacing: 6) {
                    Text(draft.name.isEmpty ? KitoScreensLocalization.string("profile.yourName", "Your name") : draft.name).font(.headline)
                    if let onChangeAvatar { KitoButton(KitoScreensLocalization.string("profile.changePhoto", "Change photo"), systemImage: "camera") { onChangeAvatar() }.variant(.tonal).size(.small) }
                }
                Spacer()
            }
            KitoNameField(KitoScreensLocalization.string("profile.fullName", "Full name"), text: $draft.name).required().isValid(bind("name"))
            KitoUsernameField(text: $draft.username).availability { name in await usernameAvailability?(name) ?? true }.isValid(bind("username"))
            KitoEmailField(text: $draft.email).required().isValid(bind("email")).errorMessage(serverError)
            KitoPhoneField(KitoScreensLocalization.string("field.mobileNumber", "Mobile number"), phoneNumber: $phone).flagStyle(.circle).onPhoneNumberChange { draft.phoneE164 = $0?.e164 ?? "" }
            KitoCountryField(KitoScreensLocalization.string("field.country", "Country"), selection: $country).flagStyle(.circle).onCountryChange { draft.countryISO = $0.isoCode }
            KitoDateField(KitoScreensLocalization.string("profile.dateOfBirth", "Date of birth"), date: $draft.dateOfBirth).range(max: Date())
            KitoURLField(text: $draft.website)
            KitoTextArea(KitoScreensLocalization.string("profile.bio", "Bio"), text: $draft.bio, prompt: KitoScreensLocalization.string("profile.bioPlaceholder", "A few words about you"), lines: 3...6, limit: 160)
        } footer: {
            KitoButton(KitoScreensLocalization.string("profile.saveChanges", "Save changes"), systemImage: "checkmark") {
                serverError = nil
                let outcome = try await save(draft)
                if case .failure(let message) = outcome { serverError = message; throw KitoScreenError.rejected }
            }
            .showsResult().successTitle(KitoScreensLocalization.string("profile.saved", "Saved"))
            .size(.large).fullWidth()
            .disabled(!hasChanges || !isValid)
        }
    }

    private func mutating(_ change: (inout KitoEditProfileScreen) -> Void) -> KitoEditProfileScreen { var c = self; change(&c); return c }
    public func usernameAvailability(_ check: @escaping (String) async -> Bool) -> KitoEditProfileScreen { mutating { $0.usernameAvailability = check } }
    public func avatar<A: View>(@ViewBuilder _ view: () -> A) -> KitoEditProfileScreen { var c = self; c.avatar = AnyView(view()); return c }
    public func changeAvatar(_ action: @escaping () -> Void) -> KitoEditProfileScreen { mutating { $0.onChangeAvatar = action } }
}
