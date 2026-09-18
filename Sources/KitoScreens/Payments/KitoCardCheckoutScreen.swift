//
//  KitoCardCheckoutScreen.swift
//  KitoScreens
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI
import KitoFields
import KitoButtons

/// Card checkout: order summary, card number with brand detection, expiry, CVV, cardholder,
/// billing country, optional save-card toggle, and a pay button with the amount.
public struct KitoCardCheckoutScreen: View {
    public struct LineItem: Identifiable, Sendable, Equatable {
        public let id: String
        public let title: String
        public let amount: Decimal
        public init(id: String = UUID().uuidString, _ title: String, amount: Decimal) { self.id = id; self.title = title; self.amount = amount }
    }

    public struct Card: Sendable, Equatable {
        public let number: String
        public let expiryMonth: Int
        public let expiryYear: Int
        public let cvv: String
        public let holder: String
        public let billingCountryISO: String?
        public let saveCard: Bool
        public var brand: KitoCardBrand { KitoCardBrand.detect(number) }
    }

    private let items: [LineItem]
    private let currencyCode: String
    private let submit: (Card) async throws -> KitoScreenOutcome
    private var offersSaveCard = true
    private var merchantName: String?

    @State private var number = ""
    @State private var expiry = ""
    @State private var cvv = ""
    @State private var holder = ""
    @State private var country: KitoCountry? = KitoCountryDatabase.country(isoCode: "US")
    @State private var saveCard = false
    @State private var valid = [String: Bool]()
    @State private var brand: KitoCardBrand = .unknown
    @State private var serverError: String?

    public init(items: [LineItem], currencyCode: String = "USD", submit: @escaping (Card) async throws -> KitoScreenOutcome) {
        self.items = items; self.currencyCode = currencyCode; self.submit = submit
    }

    private func bind(_ key: String) -> Binding<Bool> { Binding(get: { valid[key] ?? false }, set: { valid[key] = $0 }) }
    private var total: Decimal { items.reduce(0) { $0 + $1.amount } }
    private var canPay: Bool { ["number", "expiry", "cvv", "holder"].allSatisfy { valid[$0] ?? false } }

    private func money(_ value: Decimal) -> String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = currencyCode
        return f.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    public var body: some View {
        KitoScreenScaffold(header: KitoScreenHeader(KitoScreensLocalization.string("checkout.title", "Checkout"), subtitle: merchantName)) {
            summary
            KitoCardNumberField(number: $number).required().isValid(bind("number")).onBrandChange { brand = $0 }.errorMessage(serverError)
            HStack(alignment: .top, spacing: 12) {
                KitoCardExpiryField(text: $expiry).required().isValid(bind("expiry"))
                KitoCVVField(text: $cvv, length: brand.cvvLength).required().isValid(bind("cvv"))
            }
            KitoNameField(KitoScreensLocalization.string("checkout.nameOnCard", "Name on card"), text: $holder, prompt: KitoScreensLocalization.string("checkout.nameOnCardPlaceholder", "As printed on the card")).autocapitalization(.characters).required().isValid(bind("holder"))
            KitoCountryField(KitoScreensLocalization.string("checkout.billingCountry", "Billing country"), selection: $country).flagStyle(.circle)
            if offersSaveCard {
                Toggle(KitoScreensLocalization.string("checkout.saveCard", "Save this card for next time"), isOn: $saveCard).font(.subheadline).modifier(SwitchStyleIfAvailable())
            }
            HStack(spacing: 6) {
                Image(systemName: "lock.fill").font(.caption)
                Text(KitoScreensLocalization.string("checkout.encryptedNotice", "Card details are encrypted and never stored on this device.")).font(.caption)
            }
            .foregroundColor(.secondary)
        } footer: {
            KitoButton(KitoScreensLocalization.format("checkout.pay", "Pay %@", money(total)), systemImage: "lock.fill") {
                serverError = nil
                guard let exp = KitoCardExpiryField.components(expiry) else { throw KitoScreenError.rejected }
                let card = Card(number: number.asciiDigitsOnly, expiryMonth: exp.month, expiryYear: exp.year, cvv: cvv, holder: holder, billingCountryISO: country?.isoCode, saveCard: saveCard)
                let outcome = try await submit(card)
                if case .failure(let message) = outcome { serverError = message; throw KitoScreenError.rejected }
            }
            .showsResult().successTitle(KitoScreensLocalization.string("checkout.paymentComplete", "Payment complete")).failureTitle(KitoScreensLocalization.string("checkout.paymentDeclined", "Payment declined"))
            .size(.large).fullWidth()
            .disabled(!canPay)
        }
    }

    private var summary: some View {
        VStack(spacing: 10) {
            ForEach(items) { item in
                HStack { Text(item.title).font(.subheadline); Spacer(); Text(money(item.amount)).font(.subheadline).monospacedDigit() }
            }
            Divider()
            HStack { Text(KitoScreensLocalization.string("checkout.total", "Total")).font(.headline); Spacer(); Text(money(total)).font(.headline).monospacedDigit() }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.primary.opacity(0.04)))
    }

    private func mutating(_ change: (inout KitoCardCheckoutScreen) -> Void) -> KitoCardCheckoutScreen { var c = self; change(&c); return c }
    public func offersSaveCard(_ enabled: Bool) -> KitoCardCheckoutScreen { mutating { $0.offersSaveCard = enabled } }
    public func merchant(_ name: String) -> KitoCardCheckoutScreen { mutating { $0.merchantName = name } }
}

extension String {
    var asciiDigitsOnly: String { filter { $0.isASCII && $0.isNumber } }
}
