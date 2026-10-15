//
//  AppLanguage.swift
//  ClippyGo
//
//  Created by safak.dev on 7.10.2026.
//

import Combine
import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case turkish = "tr"
    case german = "de"
    case french = "fr"
    case spanish = "es"
    case italian = "it"
    case dutch = "nl"
    case portuguese = "pt-BR"
    case japanese = "ja"
    case korean = "ko"
    case chineseSimplified = "zh-Hans"
    case russian = "ru"
    case polish = "pl"
    case arabic = "ar"
    case hebrew = "he"
    case swedish = "sv"

    var id: String { rawValue }

    /// Language name shown in its own language.
    var displayName: String {
        switch self {
        case .system: return L10n.string("System")
        case .english: return "English"
        case .turkish: return "Türkçe"
        case .german: return "Deutsch"
        case .french: return "Français"
        case .spanish: return "Español"
        case .italian: return "Italiano"
        case .dutch: return "Nederlands"
        case .portuguese: return "Português (Brasil)"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .chineseSimplified: return "简体中文"
        case .russian: return "Русский"
        case .polish: return "Polski"
        case .arabic: return "العربية"
        case .hebrew: return "עברית"
        case .swedish: return "Svenska"
        }
    }

    var locale: Locale {
        switch self {
        case .system:
            return .autoupdatingCurrent
        default:
            return Locale(identifier: rawValue)
        }
    }

    /// Folder name under *.lproj in the app bundle.
    var localizationFolder: String? {
        switch self {
        case .system:
            return Locale.autoupdatingCurrent.language.languageCode?.identifier
        default:
            return rawValue
        }
    }

    var layoutDirection: LayoutDirection {
        let languageCode = locale.language.languageCode?.identifier ?? rawValue
        if languageCode == "ar" || languageCode == "he" || languageCode == "fa" || languageCode == "ur" {
            return .rightToLeft
        }
        if case .rightToLeft = locale.language.characterDirection {
            return .rightToLeft
        }
        return .leftToRight
    }

    var isRightToLeft: Bool { layoutDirection == .rightToLeft }

    static func from(code: String) -> AppLanguage {
        AppLanguage(rawValue: code) ?? .system
    }
}

/// Drives runtime UI language; persists via `AppSettings.languageCode`.
final class LanguageController: ObservableObject {
    @Published private(set) var language: AppLanguage {
        didSet {
            L10n.bundle = Self.bundle(for: language)
            L10n.locale = language.locale
        }
    }

    var locale: Locale { language.locale }
    var layoutDirection: LayoutDirection { language.layoutDirection }

    init(code: String = AppLanguage.system.rawValue) {
        let language = AppLanguage.from(code: code)
        self.language = language
        L10n.bundle = Self.bundle(for: language)
        L10n.locale = language.locale
    }

    func apply(_ language: AppLanguage) {
        guard self.language != language else { return }
        self.language = language
    }

    func apply(code: String) {
        apply(AppLanguage.from(code: code))
    }

    /// Resolve the compiled .lproj bundle so `String(localized:)` actually switches language.
    private static func bundle(for language: AppLanguage) -> Bundle {
        guard let folder = language.localizationFolder else { return .main }
        // Prefer exact match (e.g. pt-BR), then language-only (e.g. pt).
        let candidates = [folder, Locale(identifier: folder).language.languageCode?.identifier].compactMap { $0 }
        for name in candidates {
            if let path = Bundle.main.path(forResource: name, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                return bundle
            }
        }
        return .main
    }
}

enum L10n {
    static var locale: Locale = .autoupdatingCurrent
    static var bundle: Bundle = .main

    static func string(_ key: String.LocalizationValue) -> String {
        String(localized: key, bundle: bundle, locale: locale)
    }

    static var settings: String { string("Settings") }
    static var done: String { string("Done") }
    static var searchPlaceholder: String { string("Search...") }
    static var clear: String { string("Clear") }
    static var quit: String { string("Quit") }
    static var historyEmpty: String { string("History is empty") }
    static var noResults: String { string("No results found") }

    static var history: String { string("History") }
    static var maxItems: String { string("Max items") }
    static var sizeLimits: String { string("Size limits") }
    static var maxItemSize: String { string("Max item size") }
    static var maxTotalStorage: String { string("Max total storage") }
    static var usedStorage: String { string("Used storage") }
    static var capture: String { string("Capture") }
    static var text: String { string("Text") }
    static var images: String { string("Images") }
    static var pdfs: String { string("PDFs") }
    static var files: String { string("Files") }
    static var storage: String { string("Storage") }
    static var database: String { string("Database") }
    static var sqliteLocal: String { string("SQLite (local)") }
    static var payloads: String { string("Payloads") }
    static var applicationSupport: String { string("Application Support") }
    static var language: String { string("Language") }
    static var general: String { string("General") }
    static var openAtStartup: String { string("Open at startup") }
    static var openAtStartupHelp: String { string("Start ClippyGo automatically when you log in.") }
    static var openAtStartupFailed: String { string("Couldn’t update login item. Try again from an installed copy of the app.") }
    static var privacy: String { string("Privacy") }
    static var privacySummary: String { string("Clipboard history stays on this Mac. Nothing is uploaded.") }
    static var privacyPolicy: String { string("Privacy Policy") }
    static var about: String { string("About") }
    static var version: String { string("Version") }
    static var contact: String { string("Contact") }

    static var image: String { string("Image") }
    static var pdf: String { string("PDF") }
    static var file: String { string("File") }

    static func imageDimensions(_ width: Int, _ height: Int) -> String {
        string("Image \(width)×\(height)")
    }

    static func imageFormat(_ format: String) -> String {
        string("Image (\(format))")
    }

    static func filesCount(_ count: Int) -> String {
        string("\(count) files")
    }
}
