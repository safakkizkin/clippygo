//
//  AppStoreConfig.swift
//  ClippyGo
//
//  Created by safak.dev on 7.10.2026.
//

import Foundation

enum AppStoreConfig {
    static let appName = "ClippyGo"
    static let supportEmail = "me@safak.dev"
    static let author = "safak.dev"

    /// No public privacy page yet — leave empty until published.
    static let privacyPolicyURL: URL? = nil

    /// Paste into App Store Connect → App Review Information → Notes.
    static let reviewNotes = """
    ClippyGo is a menu bar clipboard history utility.

    How to test:
    1. Launch the app — it appears only in the menu bar (no Dock icon).
    2. Copy text, a screenshot, a PDF, or a Finder file.
    3. Open the menu bar popover to see history; click an item to copy it again.
    4. Open Settings (gear) to change limits, capture types, and language.

    Privacy:
    - Clipboard history is stored only on device (SQLite + files in the app container).
    - No network requests, no analytics, no accounts.
    - Transient / password-manager concealed pasteboard types are ignored.
    - Contact: me@safak.dev
    """
}
