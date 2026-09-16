//
//  KitoMpesaScreen.swift
//  KitoScreens
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI
import KitoFields
import KitoButtons

/// M-Pesa payment.
///
/// - **Express (STK push)**: the customer enters the phone number that will receive the prompt;
///   your closure triggers the push and the screen waits for confirmation.
/// - **Normal (Paybill / Till)**: shows the business number, account reference and amount with
///   copy buttons, then lets the customer confirm once they have paid from the M-Pesa app.
public struct KitoMpesaScreen: View {
    public enum Mode: Sendable, Equatable {
        case express
        case paybill(businessNumber: String, accountReference: String)
        case till(tillNumber: String)
    }

    public struct Request: Sendable, Equatable {
        public let phoneE164: String
        public let amount: Decimal
        public let mode: Mode
    }

    private let amount: Decimal
    private let mode: Mode
    private let submit: (Request) async throws -> KitoScreenOutcome
    private var merchantName: String?
    private var amountEditable = false
    private var currencyCode = "KES"

    @State private var phone: KitoPhoneNumber?
    @State private var editableAmount: Double?
    @State private var phoneValid = false
    @State private var serverError: String?
    @State private var awaitingPin = false

    public init(amount: Decimal, mode: Mode = .express, submit: @escaping (Request) async throws -> KitoScreenOutcome) {
        self.amount = amount; self.mode = mode; self.submit = submit
        _editableAmount = State(initialValue: Double(truncating: amount as NSDecimalNumber))
    }

    private var effectiveAmount: Decimal { amountEditable ? Decimal(editableAmount ?? 0) : amount }
    private var kenya: KitoCountry { KitoCountryDatabase.country(isoCode: "KE") ?? KitoCountryDatabase.current }
    private var formattedAmount: String { kenya.formatCurrency(effectiveAmount) ?? "\(effectiveAmount)" }

    public var body: some View {
        KitoScreenScaffold(header: KitoScreenHeader(mode == .express ? "Pay with M-Pesa" : "Pay via M-Pesa", subtitle: merchantName.map { "Paying \($0)" })) {
            amountCard
            switch mode {
            case .express:
                KitoPhoneField("M-Pesa number", phoneNumber: $phone)
                    .countries(allowed: ["KE"], preferred: ["KE"])
                    .defaultCountry("KE").countrySelection(.locked).showsChevron(false)
                    .helperText("You'll get a prompt on this phone to enter your M-Pesa PIN.")
                    .required().validationIndicators().isValid($phoneValid)
                    .errorMessage(serverError)
                if awaitingPin {
                    Label("Check your phone and enter your M-Pesa PIN", systemImage: "iphone.radiowaves.left.and.right")
                        .font(.subheadline).foregroundColor(.secondary)
                }
            case .paybill(let business, let reference):
                instructions([("Business number", business), ("Account number", reference), ("Amount", formattedAmount)])
            case .till(let till):
                instructions([("Till number", till), ("Amount", formattedAmount)])
            }
        } footer: {
            KitoButton(mode == .express ? "Pay \(formattedAmount)" : "I have paid", systemImage: mode == .express ? "lock.fill" : "checkmark.seal") {
                serverError = nil
                awaitingPin = mode == .express
                defer { awaitingPin = false }
                let outcome = try await submit(Request(phoneE164: phone?.e164 ?? "", amount: effectiveAmount, mode: mode))
                if case .failure(let message) = outcome { serverError = message; throw KitoScreenError.rejected }
            }
            .showsResult().successTitle("Payment received").failureTitle("Payment failed")
            .size(.large).fullWidth()
            .disabled(mode == .express && !phoneValid)
            .kitoButtonTheme { $0.tint = Color(red: 0.24, green: 0.66, blue: 0.30); $0.onTint = .white }
        }
    }

    private var amountCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount").font(.subheadline).foregroundColor(.secondary)
            if amountEditable {
                KitoCurrencyField("", value: $editableAmount, currencyCode: currencyCode).range(1...500_000)
            } else {
                Text(formattedAmount).font(.system(size: 34, weight: .bold, design: .rounded)).monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.primary.opacity(0.04)))
    }

    private func instructions(_ rows: [(String, String)]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.0).font(.caption).foregroundColor(.secondary)
                        Text(row.1).font(.body.weight(.semibold)).monospacedDigit()
                    }
                    Spacer()
                    KitoButton(systemImage: "doc.on.doc", accessibilityLabel: "Copy \(row.0)") {
                        #if canImport(UIKit) && !os(watchOS) && !os(tvOS)
                        UIPasteboard.general.string = row.1
                        #endif
                    }
                    .showsResult().resultIcons(success: "checkmark").variant(.ghost).size(.small)
                }
                .padding(.vertical, 12)
                if index < rows.count - 1 { Divider() }
            }
            Text("Open M-Pesa ▸ Lipa na M-Pesa ▸ \(mode.isPaybill ? "Pay Bill" : "Buy Goods"), enter the details above, then confirm here.")
                .font(.footnote).foregroundColor(.secondary).padding(.top, 8)
        }
        .padding(.horizontal, 16).padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.primary.opacity(0.04)))
    }

    private func mutating(_ change: (inout KitoMpesaScreen) -> Void) -> KitoMpesaScreen { var c = self; change(&c); return c }
    public func merchant(_ name: String) -> KitoMpesaScreen { mutating { $0.merchantName = name } }
    /// Lets the customer change the amount (donations, top-ups).
    public func amountEditable(_ enabled: Bool = true) -> KitoMpesaScreen { mutating { $0.amountEditable = enabled } }
}

private extension KitoMpesaScreen.Mode {
    var isPaybill: Bool { if case .paybill = self { return true }; return false }
}
