//
//  KitoTypography.swift
//  KitoScreens
//
//  Created by Wycliff Njenga on 18/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import KitoFields
import KitoButtons

/// Sets a custom font once, at launch, across KitoFields, KitoButtons and KitoScreens together.
///
/// `KitoFieldTheme`, `KitoButtonTheme` and `KitoScreenTheme` each have their own
/// `KitoFontFamily` type and `.custom(_:)` builder — this is the one call that applies the same
/// family to all three, since KitoScreens is the package that already depends on the other two.
///
/// ```swift
/// @main
/// struct MyApp: App {
///     init() {
///         KitoTypography.apply(
///             regular: "Inter-Regular",
///             medium: "Inter-Medium",
///             semibold: "Inter-SemiBold",
///             bold: "Inter-Bold"
///         )
///     }
///     var body: some Scene { WindowGroup { ContentView() } }
/// }
/// ```
///
/// Call this before any field, button or screen's environment is first read — in practice,
/// anywhere before your first view's `body` runs, such as your `App`'s `init()`. An explicit
/// `.kitoFieldTheme(...)` / `.kitoButtonTheme(...)` / `.kitoScreenTheme(...)` — including the
/// packages' own presets, none of which carry a custom font — still overrides this for whatever
/// subtree it's applied to.
public enum KitoTypography {
    /// - Parameters:
    ///   - regular: PostScript name of the regular weight (required).
    ///   - medium: PostScript name of the medium weight, if your font ships one.
    ///   - semibold: PostScript name of the semibold weight, if your font ships one.
    ///   - bold: PostScript name of the bold weight, if your font ships one.
    ///
    /// Every weight you don't provide falls back progressively toward `regular`, so a font that
    /// only ships one or two weights still works — bold text just won't look any bolder than
    /// what you gave it.
    public static func apply(regular: String, medium: String? = nil, semibold: String? = nil, bold: String? = nil) {
        let fieldsFamily = KitoFields.KitoFontFamily(regular: regular, medium: medium, semibold: semibold, bold: bold)
        let buttonsFamily = KitoButtons.KitoFontFamily(regular: regular, medium: medium, semibold: semibold, bold: bold)
        KitoFieldTheme.default = .custom(fieldsFamily)
        KitoButtonTheme.default = .custom(buttonsFamily)
        KitoScreenTheme.default = .custom(fieldsFamily)
    }
}
