//
//  ClipboardItem.swift
//  ClippyGo
//
//  Created by safak.dev on 7.10.2026.
//

import Foundation
import SwiftData

enum ClipboardKind: String, Codable {
    case text
    case image
    case pdf
    case file
}

@Model
class ClipboardItem {
    @Attribute(.unique) var contentHash: String
    /// Stored as raw value of `ClipboardKind`.
    var kindRaw: String
    /// Searchable / display label (text body, dimensions, or filename).
    var text: String
    /// For `.file` items: newline-separated paths. Binary payloads live on disk.
    var filePaths: String?
    /// Extension used for the on-disk payload (`png`, `tiff`, `pdf`).
    var payloadExtension: String?
    /// Pasteboard type used when the item was captured (e.g. `public.tiff`).
    var pasteboardType: String?
    var byteCount: Int
    var timestamp: Date

    var kind: ClipboardKind {
        get { ClipboardKind(rawValue: kindRaw) ?? .text }
        set { kindRaw = newValue.rawValue }
    }

    /// Localized title for UI (does not rewrite stored metadata).
    var displayTitle: String {
        switch kind {
        case .text:
            return text
        case .image:
            if text.isEmpty {
                return L10n.image
            }
            // Stored as "WIDTHxHEIGHT" or format fallback like "PNG".
            if let x = text.firstIndex(of: "×") {
                let widthPart = text[..<x]
                let heightPart = text[text.index(after: x)...]
                if let w = Int(widthPart), let h = Int(heightPart) {
                    return L10n.imageDimensions(w, h)
                }
            }
            return L10n.imageFormat(text)
        case .pdf:
            return L10n.pdf
        case .file:
            if let paths = filePaths?
                .split(separator: "\n", omittingEmptySubsequences: true),
               paths.count > 1 {
                return L10n.filesCount(paths.count)
            }
            return text.isEmpty ? L10n.file : text
        }
    }

    init(
        contentHash: String,
        kind: ClipboardKind,
        text: String,
        filePaths: String? = nil,
        payloadExtension: String? = nil,
        pasteboardType: String? = nil,
        byteCount: Int = 0,
        timestamp: Date = Date()
    ) {
        self.contentHash = contentHash
        self.kindRaw = kind.rawValue
        self.text = text
        self.filePaths = filePaths
        self.payloadExtension = payloadExtension
        self.pasteboardType = pasteboardType
        self.byteCount = byteCount
        self.timestamp = timestamp
    }
}
