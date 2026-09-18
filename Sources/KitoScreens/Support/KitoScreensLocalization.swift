//
//  KitoScreensLocalization.swift
//  KitoScreens
//
//  Created by Wycliff Njenga on 18/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import Foundation

/// Localization entry point for the built-in copy on every prebuilt screen: titles, field
/// labels, button titles and helper text. English, Swahili (`sw`) and French (`fr`) are bundled;
/// set `provider` to override or add languages from your app, same as KitoFields/KitoButtons.
public enum KitoScreensLocalization {
    /// Consulted before the bundled `Localizable.strings`; return nil to fall back.
    public static var provider: ((_ key: String, _ fallback: String) -> String?)?

    public static var bundle: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        let host = Bundle(for: BundleToken.self)
        if let url = host.url(forResource: "KitoScreens", withExtension: "bundle"), let bundle = Bundle(url: url) { return bundle }
        return host
        #endif
    }

    public static func string(_ key: String, _ fallback: String) -> String {
        if let custom = provider?(key, fallback) { return custom }
        return bundle.localizedString(forKey: key, value: fallback, table: nil)
    }

    public static func format(_ key: String, _ fallback: String, _ arguments: CVarArg...) -> String {
        String(format: string(key, fallback), locale: .current, arguments: arguments)
    }

    /// Keys defined for a language, for parity tests and custom providers.
    public static func keys(forLanguage code: String) -> Set<String> {
        guard let path = bundle.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: code),
              let dictionary = NSDictionary(contentsOfFile: path) as? [String: String] else { return [] }
        return Set(dictionary.keys)
    }
}

private final class BundleToken {}
