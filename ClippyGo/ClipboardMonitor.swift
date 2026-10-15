//
//  ClipboardMonitor.swift
//  ClippyGo
//
//  Created by safak on 7.10.2026.
//

import AppKit
import Combine
import CryptoKit
import SwiftData

class ClipboardMonitor: ObservableObject {
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.lastChangeCount = pasteboard.changeCount
        startPolling()
    }

    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }

    private func checkForChanges() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        let ignoredTypes: [NSPasteboard.PasteboardType] = [
            .init("org.nspasteboard.TransientType"),
            .init("org.nspasteboard.ConcealedType"),
            .init("com.agilebits.onepassword")
        ]

        for type in ignoredTypes {
            if pasteboard.types?.contains(type) == true { return }
        }

        guard let captured = capturePasteboard() else { return }

        DispatchQueue.main.async {
            self.upsert(captured)
        }
    }

    private struct CapturedContent {
        let hash: String
        let kind: ClipboardKind
        let text: String
        let data: Data?
        let pasteboardType: String?
    }

    /// Prefer file URLs (Finder copies), then images, PDFs, then plain text.
    private func capturePasteboard() -> CapturedContent? {
        if let fileURLs = readFileURLs(), !fileURLs.isEmpty {
            let paths = fileURLs.map(\.path).joined(separator: "\n")
            let payload = Data(paths.utf8)
            let label = fileURLs.count == 1
                ? fileURLs[0].lastPathComponent
                : "\(fileURLs.count) files"
            return CapturedContent(
                hash: Self.sha256(payload),
                kind: .file,
                text: label,
                data: payload,
                pasteboardType: NSPasteboard.PasteboardType.fileURL.rawValue
            )
        }

        if let image = readImage() {
            return image
        }

        if let pdfData = pasteboard.data(forType: .pdf), !pdfData.isEmpty {
            return CapturedContent(
                hash: Self.sha256(pdfData),
                kind: .pdf,
                text: "PDF",
                data: pdfData,
                pasteboardType: NSPasteboard.PasteboardType.pdf.rawValue
            )
        }

        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            let payload = Data(string.utf8)
            return CapturedContent(
                hash: Self.sha256(payload),
                kind: .text,
                text: string,
                data: nil,
                pasteboardType: NSPasteboard.PasteboardType.string.rawValue
            )
        }

        return nil
    }

    private func readFileURLs() -> [URL]? {
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return nil
        }
        let fileURLs = urls.filter(\.isFileURL)
        return fileURLs.isEmpty ? nil : fileURLs
    }

    private func readImage() -> CapturedContent? {
        let candidates: [(NSPasteboard.PasteboardType, String)] = [
            (.png, "PNG"),
            (.tiff, "TIFF"),
        ]

        for (type, label) in candidates {
            guard let data = pasteboard.data(forType: type), !data.isEmpty else { continue }
            var text = "Image (\(label))"
            if let image = NSImage(data: data) {
                let size = image.size
                if size.width > 0, size.height > 0 {
                    text = "Image \(Int(size.width))×\(Int(size.height))"
                }
            }
            return CapturedContent(
                hash: Self.sha256(data),
                kind: .image,
                text: text,
                data: data,
                pasteboardType: type.rawValue
            )
        }

        return nil
    }

    private func upsert(_ captured: CapturedContent) {
        let hash = captured.hash
        let descriptor = FetchDescriptor<ClipboardItem>(
            predicate: #Predicate { $0.contentHash == hash }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.timestamp = Date()
        } else {
            let item = ClipboardItem(
                contentHash: captured.hash,
                kind: captured.kind,
                text: captured.text,
                data: captured.data,
                pasteboardType: captured.pasteboardType,
                timestamp: Date()
            )
            modelContext.insert(item)
        }

        try? modelContext.save()
    }

    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
