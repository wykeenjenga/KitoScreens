import XCTest
import SwiftUI
@testable import KitoScreens
import KitoFields

final class KitoScreensTests: XCTestCase {
    func testCheckoutTotalAndBrand() {
        let items = [KitoCardCheckoutScreen.LineItem("Shoes", amount: 8900), KitoCardCheckoutScreen.LineItem("Delivery", amount: 300)]
        XCTAssertEqual(items.reduce(0) { $0 + $1.amount }, 9200)
        let card = KitoCardCheckoutScreen.Card(number: "4111111111111111", expiryMonth: 12, expiryYear: 2030, cvv: "123", holder: "W N", billingCountryISO: "KE", saveCard: false)
        XCTAssertEqual(card.brand, .visa)
    }

    func testMpesaModes() {
        let mode = KitoMpesaScreen.Mode.paybill(businessNumber: "247247", accountReference: "ORDER-1")
        if case .paybill(let b, let r) = mode { XCTAssertEqual(b, "247247"); XCTAssertEqual(r, "ORDER-1") } else { XCTFail() }
        XCTAssertEqual(KitoMpesaScreen.Mode.express, .express)
    }

    func testScreensConstruct() {
        _ = KitoLoginScreen { _ in .success }.forgotPassword {}.socialProviders([.apple, .google]) { _ in }
        _ = KitoSignUpScreen { _ in .success }.terms(URL(string: "https://example.com/terms")!)
        _ = KitoEditProfileScreen(profile: .init(name: "Wycliff")) { _ in .success }
        _ = KitoMpesaScreen(amount: 1250) { _ in .success }.merchant("Kito Store")
        _ = KitoCardCheckoutScreen(items: []) { _ in .success }
        _ = KitoOTPVerificationScreen(destination: "+254 7•• ••• 678", length: 4) { _ in .success }.resend(cooldown: 30) {}
    }
}

final class KitoScreensLocalizationTests: XCTestCase {
    func testEveryBundledLanguageDefinesTheSameKeys() {
        let en = KitoScreensLocalization.keys(forLanguage: "en")
        XCTAssertGreaterThan(en.count, 20)
        for code in ["sw", "fr"] { XCTAssertEqual(KitoScreensLocalization.keys(forLanguage: code), en, code) }
    }

    func testProviderOverrideTakesPrecedenceOverBundledStrings() {
        KitoScreensLocalization.provider = { key, _ in key == "login.title" ? "Karibu" : nil }
        defer { KitoScreensLocalization.provider = nil }
        XCTAssertEqual(KitoScreensLocalization.string("login.title", "Sign in"), "Karibu")
        XCTAssertEqual(KitoScreensLocalization.string("not.a.real.key", "fallback"), "fallback", "the provider only overrides the key it recognizes")
    }

    func testFormatSubstitutesArguments() {
        let label = KitoScreensLocalization.format("mpesa.pay", "Pay %@", "KES 1,250")
        XCTAssertTrue(label.contains("KES 1,250"))
    }
}
