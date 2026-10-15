//
//  AppSettings.swift
//  ClippyGo
//
//  Created by safak.dev on 7.10.2026.
//

import Foundation
import SwiftData

/// Singleton settings row persisted in the local SQLite store (via SwiftData).
@Model
final class AppSettings {
    var singletonID: String

    /// Maximum number of history items to keep.
    var maxHistoryCount: Int
    /// Reject a single clipboard payload larger than this (bytes).
    var maxItemBytes: Int
    /// Keep total on-disk payload usage under this budget (bytes).
    var maxTotalStorageBytes: Int

    var captureText: Bool
    var captureImages: Bool
    var capturePDFs: Bool
    var captureFiles: Bool

    /// `system` or a language code (`en`, `tr`, …).
    var languageCode: String

    init(
        singletonID: String = "default",
        maxHistoryCount: Int = 50,
        maxItemBytes: Int = 10 * 1024 * 1024,
        maxTotalStorageBytes: Int = 200 * 1024 * 1024,
        captureText: Bool = true,
        captureImages: Bool = true,
        capturePDFs: Bool = true,
        captureFiles: Bool = true,
        languageCode: String = AppLanguage.system.rawValue
    ) {
        self.singletonID = singletonID
        self.maxHistoryCount = maxHistoryCount
        self.maxItemBytes = maxItemBytes
        self.maxTotalStorageBytes = maxTotalStorageBytes
        self.captureText = captureText
        self.captureImages = captureImages
        self.capturePDFs = capturePDFs
        self.captureFiles = captureFiles
        self.languageCode = languageCode
    }

    static let historyCountOptions = [10, 20, 30, 50, 100, 200, 500]
    static let itemSizeByteOptions = [
        1 * 1024 * 1024,
        5 * 1024 * 1024,
        10 * 1024 * 1024,
        25 * 1024 * 1024,
        50 * 1024 * 1024,
        100 * 1024 * 1024,
    ]
    static let storageSizeByteOptions = [
        50 * 1024 * 1024,
        100 * 1024 * 1024,
        200 * 1024 * 1024,
        500 * 1024 * 1024,
        1024 * 1024 * 1024,
        2 * 1024 * 1024 * 1024,
    ]

    static func current(in context: ModelContext) -> AppSettings {
        let id = "default"
        let descriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.singletonID == id }
        )
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let settings = AppSettings()
        context.insert(settings)
        try? context.save()
        return settings
    }
}

enum ByteFormat {
    /// Round picker labels (50 MB, 1 GB) — avoids "209,7 MB" from decimal file style.
    static func optionLabel(_ bytes: Int) -> String {
        let gb = 1024 * 1024 * 1024
        let mb = 1024 * 1024
        if bytes >= gb, bytes % gb == 0 {
            return "\(bytes / gb) GB"
        }
        if bytes >= mb, bytes % mb == 0 {
            return "\(bytes / mb) MB"
        }
        return string(bytes)
    }

    /// Actual usage can be fractional.
    static func string(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
