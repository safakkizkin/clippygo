//
//  ClipboardItem.swift
//  ClippyGo
//
//  Created by safak on 7.10.2026.
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
    /// Searchable / display label (text body, filename, or image description).
    var text: String
    /// Original pasteboard bytes (image, PDF, or file-URL payload).
    @Attribute(.externalStorage) var data: Data?
    /// Pasteboard type used when the item was captured (e.g. `public.tiff`).
    var pasteboardType: String?
    var timestamp: Date

    var kind: ClipboardKind {
        get { ClipboardKind(rawValue: kindRaw) ?? .text }
        set { kindRaw = newValue.rawValue }
    }

    var displayTitle: String {
        switch kind {
        case .text:
            return text
        case .image:
            return text.isEmpty ? "Image" : text
        case .pdf:
            return text.isEmpty ? "PDF" : text
        case .file:
            return text.isEmpty ? "File" : text
        }
    }

    init(
        contentHash: String,
        kind: ClipboardKind,
        text: String,
        data: Data? = nil,
        pasteboardType: String? = nil,
        timestamp: Date = Date()
    ) {
        self.contentHash = contentHash
        self.kindRaw = kind.rawValue
        self.text = text
        self.data = data
        self.pasteboardType = pasteboardType
        self.timestamp = timestamp
    }
}
