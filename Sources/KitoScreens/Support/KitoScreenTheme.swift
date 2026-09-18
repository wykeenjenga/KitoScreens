//
//  KitoScreenTheme.swift
//  KitoScreens
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI
import KitoFields
import KitoButtons

/// Layout tokens shared by every prebuilt screen. Field and button looks come from the
/// `KitoFieldTheme` / `KitoButtonTheme` already in the environment.
public struct KitoScreenTheme: Sendable {
    public var spacing: CGFloat = 18
    public var sectionSpacing: CGFloat = 28
    public var horizontalPadding: CGFloat = 20
    public var titleFont: Font = .largeTitle.weight(.bold)
    public var subtitleFont: Font = .body
    public var subtitleColor: Color = .secondary
    /// Secondary/body copy inside a screen — dividers, toggle labels, line-item rows, hints.
    /// Roughly `.subheadline` sized; distinct from `subtitleFont`, which is the header's own.
    public var bodyFont: Font = .subheadline
    /// Footnotes, captions, disclosures ("Card details are encrypted…").
    public var captionFont: Font = .footnote
    /// Emphasised inline text — a total, a name — short of the header's own `titleFont`.
    public var emphasisFont: Font = .headline
    public var cardCornerRadius: CGFloat = 20
    public var cardBackground: Color = Color.primary.opacity(0.04)
    public var showsLogo = true

    public init() {}

    /// The theme every screen falls back to when nothing in its view hierarchy sets
    /// `.kitoScreenTheme(...)`. Set this **once**, e.g. in your `App`'s `init()`, to apply a look
    /// (a custom font, different spacing) app-wide without wrapping every screen in a modifier.
    /// An explicit `.kitoScreenTheme(...)` anywhere in the view hierarchy still overrides this for
    /// that subtree. See `KitoTypography.apply(...)` to set a custom font across KitoScreens,
    /// KitoFields and KitoButtons in one call.
    public static var `default` = KitoScreenTheme()

    /// Builds a theme where every text role uses `family`, at the size/weight this theme would
    /// otherwise use for that role. Dynamic Type still scales, via `relativeTo:`.
    public static func custom(_ family: KitoFields.KitoFontFamily, base: KitoScreenTheme = KitoScreenTheme()) -> KitoScreenTheme {
        var theme = base
        theme.titleFont = family.font(size: 34, weight: .bold, relativeTo: .largeTitle)
        theme.subtitleFont = family.font(size: 17, relativeTo: .body)
        theme.bodyFont = family.font(size: 15, relativeTo: .subheadline)
        theme.captionFont = family.font(size: 13, relativeTo: .footnote)
        theme.emphasisFont = family.font(size: 17, weight: .semibold, relativeTo: .headline)
        return theme
    }
}

private struct KitoScreenThemeKey: EnvironmentKey {
    // Computed, not `let`: re-reads `KitoScreenTheme.default` on every fallback so setting it
    // once at launch (before any screen's environment is first read) takes effect everywhere.
    static var defaultValue: KitoScreenTheme { KitoScreenTheme.default }
}

public extension EnvironmentValues {
    var kitoScreenTheme: KitoScreenTheme {
        get { self[KitoScreenThemeKey.self] }
        set { self[KitoScreenThemeKey.self] = newValue }
    }
}

public extension View {
    func kitoScreenTheme(_ theme: KitoScreenTheme) -> some View { environment(\.kitoScreenTheme, theme) }
    func kitoScreenTheme(_ transform: @escaping (inout KitoScreenTheme) -> Void) -> some View { transformEnvironment(\.kitoScreenTheme, transform: transform) }
}

/// Title + subtitle header used by the screens.
public struct KitoScreenHeader: View {
    public var title: String
    public var subtitle: String?
    public var logo: AnyView?
    @Environment(\.kitoScreenTheme) private var theme

    public init<Logo: View>(_ title: String, subtitle: String? = nil, @ViewBuilder logo: () -> Logo) {
        self.title = title; self.subtitle = subtitle; self.logo = AnyView(logo())
    }

    public init(_ title: String, subtitle: String? = nil) {
        self.title = title; self.subtitle = subtitle; self.logo = nil
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if theme.showsLogo, let logo { logo.padding(.bottom, 8) }
            Text(title).font(theme.titleFont)
            if let subtitle { Text(subtitle).font(theme.subtitleFont).foregroundColor(theme.subtitleColor) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Standard scrolling container with header, content and a pinned primary action.
struct KitoScreenScaffold<Content: View, Footer: View>: View {
    let header: KitoScreenHeader
    let content: Content
    let footer: Footer
    @Environment(\.kitoScreenTheme) private var theme

    init(header: KitoScreenHeader, @ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.header = header; self.content = content(); self.footer = footer()
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.sectionSpacing) {
                    header
                    VStack(spacing: theme.spacing) { content }
                }
                .padding(.horizontal, theme.horizontalPadding)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            VStack(spacing: 12) { footer }
                .padding(.horizontal, theme.horizontalPadding)
                .padding(.vertical, 12)
        }
    }
}

/// Result of a screen submission your closure returns.
public enum KitoScreenOutcome: Sendable, Equatable {
    case success
    case failure(message: String)
}


/// `SwitchToggleStyle` needs tvOS 18; other platforms use it directly.
struct SwitchStyleIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        #if os(tvOS)
        content
        #else
        content.toggleStyle(.switch)
        #endif
    }
}
