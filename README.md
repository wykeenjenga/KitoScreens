# KitoScreens

Prebuilt, production-ready SwiftUI screens composed from [KitoFields](https://github.com/wykeenjenga/KitoFields) and [KitoButtons](https://github.com/wykeenjenga/KitoButtons): sign in, sign up, edit profile, M-Pesa payment (Express and Paybill/Till) and card checkout. Drop one in, hand it an async closure, and you get validation, animated fields, loading and result states, inline server errors and localization for free.

- iOS 15+, macOS 12+, tvOS 15+, watchOS 8+, visionOS 1+
- Author: **Wycliff Njenga**
- Licence: MIT

## Installation

```swift
.package(url: "https://github.com/wykeenjenga/KitoScreens.git", from: "0.2.0")
```

Then `import KitoScreens`. Field and button themes come from `KitoFieldTheme` / `KitoButtonTheme` in the environment, so the screens match the rest of your app automatically.

## Screens

### Sign in

```swift
KitoLoginScreen(title: "Welcome back") { credentials in
    try await auth.signIn(credentials.email, credentials.password)
    return .success                                   // or .failure(message: "Wrong password")
}
.forgotPassword { showReset = true }
.createAccount { showSignUp = true }
.socialProviders([.apple, .google]) { provider in signIn(with: provider) }
.usesPhone()                                          // phone number instead of email
.logo { Image("logo").resizable().frame(height: 40) }
```

### Sign up

```swift
KitoSignUpScreen { registration in
    try await auth.register(registration)              // name, email, phone, password, country
    return .success
}
.includesPhone(true)
.includesCountry(true)
.terms(URL(string: "https://example.com/terms")!)     // adds the "I agree" toggle
.passwordRules(KitoRule.strongPassword())
.signIn { showLogin = true }
```

### Edit profile

```swift
KitoEditProfileScreen(profile: profile) { updated in
    try await api.save(updated)
    return .success
}
.usernameAvailability { try await api.isAvailable($0) }
.avatar { AsyncImage(url: profile.avatarURL) }
.changeAvatar { pickPhoto() }
```

Save only enables when something changed and every field is valid.

### M-Pesa

```swift
// Express (STK push): the customer gets a PIN prompt on their phone
KitoMpesaScreen(amount: 1250, mode: .express) { request in
    try await mpesa.stkPush(phone: request.phoneE164, amount: request.amount)
    return .success
}
.merchant("Kito Store")

// Paybill or Till: shows the numbers with copy buttons, customer confirms after paying
KitoMpesaScreen(amount: 1250, mode: .paybill(businessNumber: "247247", accountReference: "ORDER-1042")) { request in
    try await mpesa.confirm(reference: "ORDER-1042")
    return .success
}
KitoMpesaScreen(amount: 500, mode: .till(tillNumber: "8123456")) { … }.amountEditable()
```

### Card checkout

```swift
KitoCardCheckoutScreen(items: [
    .init("Trail runners", amount: 8900),
    .init("Delivery", amount: 300),
], currencyCode: "KES") { card in
    try await payments.charge(card)                     // number, expiry, cvv, holder, billing country, saveCard, brand
    return .success
}
.merchant("Kito Store")
.offersSaveCard(true)
```

### Verify code

```swift
KitoOTPVerificationScreen(destination: phone.international, length: 6) { code in
    try await auth.verify(code)
    return .success                                     // or .failure(message: "Incorrect code")
}
.resend(cooldown: 30) { try await auth.resendCode() }     // "Resend code" link, disables itself
.logo { Image("logo").resizable().frame(height: 40) }
```

## Theming

```swift
.kitoScreenTheme { $0.spacing = 16; $0.titleFont = .title.weight(.bold); $0.showsLogo = false }
.kitoFieldTheme { $0.shape = .capsule }
.kitoButtonTheme { $0.tint = .black }
```

### Custom fonts, set once at launch

`KitoFieldTheme`, `KitoButtonTheme` and `KitoScreenTheme` each have their own `.custom(_:)`
builder, taking a `KitoFontFamily` (a PostScript name per weight — most custom fonts ship as
separate files per weight, not one name SwiftUI can re-weight with `.weight()`). Since
KitoScreens is the package that already depends on the other two, `KitoTypography.apply(...)` is
the one call that sets all three at once:

```swift
@main
struct MyApp: App {
    init() {
        KitoTypography.apply(
            regular: "Inter-Regular",
            medium: "Inter-Medium",
            semibold: "Inter-SemiBold",
            bold: "Inter-Bold"
        )
    }
    var body: some Scene { WindowGroup { ContentView() } }
}
```

Call it once, before any field, button or screen's environment is first read — in practice,
anywhere before your first view's `body` runs. No `.kitoFieldTheme(...)` / `.kitoButtonTheme(...)`
/ `.kitoScreenTheme(...)` wrapping needed anywhere in your view hierarchy — though an explicit one
still overrides this for whatever subtree it's applied to, same as any other theme override.

## Localization

Every screen's own copy — titles, field labels, button titles, helper text — is bundled in
English, Swahili (`sw`) and French (`fr`), and follows the device language automatically. Override
or add a language from your app with `KitoScreensLocalization.provider`, exactly like
`KitoLocalization` in KitoFields and `KitoButtonsLocalization` in KitoButtons:

```swift
KitoScreensLocalization.provider = { key, fallback in
    key == "login.title" ? "Karibu" : nil   // nil falls through to the bundled string
}
```

The example app's language picker switches all three packages together this way.

## Outcomes and errors

Every screen takes an `async throws -> KitoScreenOutcome` closure. Return `.success` to show the success state, `.failure(message:)` to put the message inline on the relevant field and shake the button, or throw to shake without a message.

## Contributing

Open an issue, fork and branch from `main`, open a pull request with tests and a screenshot. Approved PRs are merged and released.

## Support the project

<a href="https://www.buymeacoffee.com/wycliffnjea"><img src="https://img.shields.io/badge/Buy%20me%20a%20coffee-%E2%98%95-black?style=for-the-badge" alt="Buy me a coffee" /></a>

## License

MIT. See [LICENSE](LICENSE). Made by Wycliff Njenga in Nairobi.
