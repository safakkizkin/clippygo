//
//  ClipboardStore.swift
//  ClippyGo
//
//  Created by safak.dev on 7.10.2026.
//

import AppKit
import Foundation

/// Persists clipboard payloads on disk so SwiftData only holds metadata.
enum ClipboardStore {
    private static let fm = FileManager.default

    static var rootURL: URL {
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = base
            .appendingPathComponent("ClippyGo", isDirectory: true)
            .appendingPathComponent("Clipboard", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func payloadURL(hash: String, fileExtension: String) -> URL {
        rootURL.appendingPathComponent("\(hash).\(fileExtension)")
    }

    static func thumbnailURL(hash: String) -> URL {
        rootURL.appendingPathComponent("\(hash).thumb.jpg")
    }

    @discardableResult
    static func writePayload(_ data: Data, hash: String, fileExtension: String) -> URL? {
        let url = payloadURL(hash: hash, fileExtension: fileExtension)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    static func readPayload(hash: String, fileExtension: String) -> Data? {
        let url = payloadURL(hash: hash, fileExtension: fileExtension)
        return try? Data(contentsOf: url, options: [.mappedIfSafe])
    }

    @discardableResult
    static func writeThumbnail(from imageData: Data, hash: String) -> Bool {
        guard let image = NSImage(data: imageData) else { return false }
        guard let jpeg = resizedJPEG(from: image, maxPixel: 144) else { return false }
        do {
            try jpeg.write(to: thumbnailURL(hash: hash), options: .atomic)
            return true
        } catch {
            return false
        }
    }

    static func loadThumbnail(hash: String) -> NSImage? {
        let url = thumbnailURL(hash: hash)
        guard fm.fileExists(atPath: url.path) else { return nil }
        return NSImage(contentsOf: url)
    }

    static func remove(hash: String, fileExtension: String?) {
        if let fileExtension {
            try? fm.removeItem(at: payloadURL(hash: hash, fileExtension: fileExtension))
        }
        try? fm.removeItem(at: thumbnailURL(hash: hash))
    }

    static func removeAll() {
        guard fm.fileExists(atPath: rootURL.path) else { return }
        try? fm.removeItem(at: rootURL)
        try? fm.createDirectory(at: rootURL, withIntermediateDirectories: true)
    }

    /// Total bytes used by payload + thumbnail files on disk.
    static func usedBytes() -> Int {
        guard let enumerator = fm.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var total = 0
        for case let url as URL in enumerator {
            guard
                let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                values.isRegularFile == true,
                let size = values.fileSize
            else { continue }
            total += size
        }
        return total
    }

    private static func resizedJPEG(from image: NSImage, maxPixel: CGFloat) -> Data? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }

        let scale = min(1, maxPixel / max(size.width, size.height))
        let target = NSSize(width: max(1, floor(size.width * scale)),
                            height: max(1, floor(size.height * scale)))

        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(target.width),
            pixelsHigh: Int(target.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )
        guard let rep else { return nil }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(origin: .zero, size: target),
                   from: NSRect(origin: .zero, size: size),
                   operation: .copy,
                   fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        return rep.representation(using: .jpeg, properties: [.compressionFactor: 0.7])
    }
}
