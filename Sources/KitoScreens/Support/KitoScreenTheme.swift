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
    public var cardCornerRadius: CGFloat = 20
    public var cardBackground: Color = Color.primary.opacity(0.04)
    public var showsLogo = true

    public init() {}
    public static let `default` = KitoScreenTheme()
}

private struct KitoScreenThemeKey: EnvironmentKey { static let defaultValue = KitoScreenTheme.default }

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
