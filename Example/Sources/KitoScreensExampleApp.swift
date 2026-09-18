//
//  KitoScreensExampleApp.swift
//  KitoScreensExample
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI
import KitoScreens
import KitoFields
import KitoButtons

@main
struct KitoScreensExampleApp: App {
    var body: some Scene { WindowGroup { ContentView() } }
}

/// Switches every KitoScreens, KitoFields and KitoButtons string at runtime, the same way the
/// KitoFields and KitoButtons example apps do: load the target language's own `.strings` table
/// and install it as each package's `provider`.
final class AppearanceModel: ObservableObject {
    enum Language: String, CaseIterable, Identifiable {
        case system, en, sw, fr
        var id: String { rawValue }
        var title: String {
            switch self {
            case .system: return "System"
            case .en: return "English"
            case .sw: return "Kiswahili"
            case .fr: return "Français"
            }
        }
        var code: String? { self == .system ? nil : rawValue }
    }

    @Published var language: Language = .system {
        didSet { applyLanguage() }
    }

    var locale: Locale { language.code.map(Locale.init(identifier:)) ?? .autoupdatingCurrent }

    private func applyLanguage() {
        guard let code = language.code else {
            KitoScreensLocalization.provider = nil
            KitoLocalization.provider = nil
            KitoButtonsLocalization.provider = nil
            return
        }
        KitoScreensLocalization.provider = Self.tableProvider(bundle: KitoScreensLocalization.bundle, code: code)
        KitoLocalization.provider = Self.tableProvider(bundle: KitoLocalization.bundle, code: code)
        KitoButtonsLocalization.provider = Self.tableProvider(bundle: KitoButtonsLocalization.bundle, code: code)
    }

    private static func tableProvider(bundle: Bundle, code: String) -> ((String, String) -> String?)? {
        guard let path = bundle.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: code),
              let table = NSDictionary(contentsOfFile: path) as? [String: String] else { return nil }
        return { key, _ in table[key] }
    }
}

struct ContentView: View {
    @StateObject private var appearance = AppearanceModel()
    @State private var simulateFailure = false
    @State private var log: [String] = []

    private func outcome(_ label: String) async throws -> KitoScreenOutcome {
        try? await Task.sleep(nanoseconds: 1_100_000_000)
        log.insert("\(Date().formatted(date: .omitted, time: .standard)) \(label)", at: 0)
        return simulateFailure ? .failure(message: "Server rejected the request") : .success
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Language") {
                    Picker("Language", selection: $appearance.language) {
                        ForEach(AppearanceModel.Language.allCases) { Text($0.title).tag($0) }
                    }
                }
                Section("Auth") {
                    NavigationLink("Sign in · email") {
                        KitoLoginScreen { c in try await outcome("sign in \(c.email)") }
                            .forgotPassword {}.createAccount {}
                            .socialProviders([.apple, .google]) { _ in }
                            .logo { Image(systemName: "k.square.fill").font(.system(size: 40)) }
                            .navigationTitle("").navigationBarTitleDisplayMode(.inline)
                    }
                    NavigationLink("Sign in · phone") {
                        KitoLoginScreen(title: "Sign in", subtitle: "Use the number you registered with.") { c in try await outcome("sign in \(c.email)") }
                            .usesPhone().forgotPassword {}
                    }
                    NavigationLink("Sign up") {
                        KitoSignUpScreen { r in try await outcome("register \(r.email)") }
                            .includesCountry(true)
                            .terms(URL(string: "https://example.com/terms")!)
                            .signIn {}
                    }
                    NavigationLink("Verify code") {
                        KitoOTPVerificationScreen(destination: "+254 7•• ••• 456", length: 4) { code in
                            try? await Task.sleep(nanoseconds: 900_000_000)
                            log.insert("\(Date().formatted(date: .omitted, time: .standard)) verify \(code)", at: 0)
                            return code == "1234" ? .success : .failure(message: "")   // try 1234
                        }
                        .resend(cooldown: 8) {   // shortened for this demo
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            log.insert("\(Date().formatted(date: .omitted, time: .standard)) resend requested", at: 0)
                        }
                        .logo { Image(systemName: "k.square.fill").font(.system(size: 40)) }
                    }
                }
                Section("Profile") {
                    NavigationLink("Edit profile") {
                        KitoEditProfileScreen(profile: .init(name: "Wycliff Njenga", username: "wykee", email: "wycliff@triply.co", phoneE164: "+254712123456", countryISO: "KE", website: "https://triply.co", bio: "iOS dude.")) { p in try await outcome("save \(p.username)") }
                            .usernameAvailability { name in
                                try? await Task.sleep(nanoseconds: 600_000_000)
                                return !["admin", "root", "kito"].contains(name)
                            }
                            .changeAvatar {}
                    }
                }
                Section("Payments") {
                    NavigationLink("M-Pesa · Express (STK push)") {
                        KitoMpesaScreen(amount: 1250, mode: .express) { r in try await outcome("stk \(r.phoneE164) \(r.amount)") }
                            .merchant("Kito Store")
                    }
                    NavigationLink("M-Pesa · Paybill") {
                        KitoMpesaScreen(amount: 1250, mode: .paybill(businessNumber: "247247", accountReference: "ORDER-1042")) { _ in try await outcome("paybill confirm") }
                            .merchant("Kito Store")
                    }
                    NavigationLink("M-Pesa · Till, editable amount") {
                        KitoMpesaScreen(amount: 500, mode: .till(tillNumber: "8123456")) { r in try await outcome("till \(r.amount)") }
                            .amountEditable()
                    }
                    NavigationLink("Card checkout") {
                        KitoCardCheckoutScreen(items: [.init("Trail runners", amount: 8900), .init("Rain jacket", amount: 12500), .init("Delivery", amount: 300)], currencyCode: "KES") { card in try await outcome("charge \(card.brand.displayName) ****\(card.number.suffix(4))") }
                            .merchant("Kito Store")
                    }
                }
                Section("Simulation") {
                    Toggle("Simulate server failure", isOn: $simulateFailure)
                    ForEach(log.prefix(5), id: \.self) { Text($0).font(.footnote.monospaced()).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("KitoScreens")
        }
        .tint(.primary)
        .environment(\.locale, appearance.locale)
        .id(appearance.language)   // re-render every string when the language changes
    }
}
