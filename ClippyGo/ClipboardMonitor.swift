//
//  ClipboardMonitor.swift
//  ClippyGo
//
//  Created by safak.dev on 7.10.2026.
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
        _ = AppSettings.current(in: modelContext)
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

        let settings = AppSettings.current(in: modelContext)
        guard let snapshot = snapshotPasteboard(settings: settings) else { return }

        let maxItemBytes = settings.maxItemBytes

        DispatchQueue.global(qos: .utility).async {
            guard let captured = self.persist(snapshot, maxItemBytes: maxItemBytes) else { return }
            DispatchQueue.main.async {
                self.upsert(captured)
                self.enforceLimits()
            }
        }
    }

    /// Apply current settings limits (also called when settings change).
    func enforceLimits() {
        let settings = AppSettings.current(in: modelContext)
        pruneToCount(settings.maxHistoryCount)
        pruneToStorageBudget(settings.maxTotalStorageBytes)
        try? modelContext.save()
    }

    private struct PasteboardSnapshot {
        enum Payload {
            case files(paths: String, label: String)
            case image(data: Data, ext: String, pasteboardType: String)
            case pdf(Data)
            case text(String)
        }

        let payload: Payload
    }

    private struct CapturedContent {
        let hash: String
        let kind: ClipboardKind
        let text: String
        let filePaths: String?
        let payloadExtension: String?
        let pasteboardType: String?
        let byteCount: Int
    }

    private func snapshotPasteboard(settings: AppSettings) -> PasteboardSnapshot? {
        if settings.captureFiles, let fileURLs = readFileURLs(), !fileURLs.isEmpty {
            let paths = fileURLs.map(\.path).joined(separator: "\n")
            // Store filename for a single file; multi-file label is localized at display time.
            let label = fileURLs.count == 1 ? fileURLs[0].lastPathComponent : ""
            return PasteboardSnapshot(payload: .files(paths: paths, label: label))
        }

        if settings.captureImages {
            let imageCandidates: [(NSPasteboard.PasteboardType, String)] = [
                (.png, "png"),
                (.tiff, "tiff"),
            ]
            for (type, ext) in imageCandidates {
                if let data = pasteboard.data(forType: type), !data.isEmpty {
                    return PasteboardSnapshot(
                        payload: .image(data: data, ext: ext, pasteboardType: type.rawValue)
                    )
                }
            }
        }

        if settings.capturePDFs, let pdfData = pasteboard.data(forType: .pdf), !pdfData.isEmpty {
            return PasteboardSnapshot(payload: .pdf(pdfData))
        }

        if settings.captureText, let string = pasteboard.string(forType: .string), !string.isEmpty {
            return PasteboardSnapshot(payload: .text(string))
        }

        return nil
    }

    private func persist(_ snapshot: PasteboardSnapshot, maxItemBytes: Int) -> CapturedContent? {
        switch snapshot.payload {
        case let .files(paths, label):
            let payload = Data(paths.utf8)
            return CapturedContent(
                hash: Self.sha256(payload),
                kind: .file,
                text: label,
                filePaths: paths,
                payloadExtension: nil,
                pasteboardType: NSPasteboard.PasteboardType.fileURL.rawValue,
                byteCount: payload.count
            )

        case let .image(data, ext, pasteboardType):
            guard data.count <= maxItemBytes else { return nil }
            let hash = Self.sha256(data)
            guard ClipboardStore.writePayload(data, hash: hash, fileExtension: ext) != nil else {
                return nil
            }
            ClipboardStore.writeThumbnail(from: data, hash: hash)

            // Store language-neutral metadata; UI localizes via `displayTitle`.
            var text = ext.uppercased()
            if let image = NSImage(data: data) {
                let size = image.size
                if size.width > 0, size.height > 0 {
                    text = "\(Int(size.width))×\(Int(size.height))"
                }
            }

            return CapturedContent(
                hash: hash,
                kind: .image,
                text: text,
                filePaths: nil,
                payloadExtension: ext,
                pasteboardType: pasteboardType,
                byteCount: data.count
            )

        case let .pdf(data):
            guard data.count <= maxItemBytes else { return nil }
            let hash = Self.sha256(data)
            guard ClipboardStore.writePayload(data, hash: hash, fileExtension: "pdf") != nil else {
                return nil
            }
            return CapturedContent(
                hash: hash,
                kind: .pdf,
                text: "",
                filePaths: nil,
                payloadExtension: "pdf",
                pasteboardType: NSPasteboard.PasteboardType.pdf.rawValue,
                byteCount: data.count
            )

        case let .text(string):
            let payload = Data(string.utf8)
            guard payload.count <= maxItemBytes else { return nil }
            return CapturedContent(
                hash: Self.sha256(payload),
                kind: .text,
                text: string,
                filePaths: nil,
                payloadExtension: nil,
                pasteboardType: NSPasteboard.PasteboardType.string.rawValue,
                byteCount: payload.count
            )
        }
    }

    private func readFileURLs() -> [URL]? {
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return nil
        }
        let fileURLs = urls.filter(\.isFileURL)
        return fileURLs.isEmpty ? nil : fileURLs
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
                filePaths: captured.filePaths,
                payloadExtension: captured.payloadExtension,
                pasteboardType: captured.pasteboardType,
                byteCount: captured.byteCount,
                timestamp: Date()
            )
            modelContext.insert(item)
        }

        try? modelContext.save()
    }

    private func pruneToCount(_ maxCount: Int) {
        guard maxCount > 0 else { return }
        let descriptor = FetchDescriptor<ClipboardItem>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        guard let items = try? modelContext.fetch(descriptor), items.count > maxCount else { return }

        for item in items.suffix(from: maxCount) {
            ClipboardStore.remove(hash: item.contentHash, fileExtension: item.payloadExtension)
            modelContext.delete(item)
        }
    }

    private func pruneToStorageBudget(_ maxBytes: Int) {
        guard maxBytes > 0 else { return }

        let descriptor = FetchDescriptor<ClipboardItem>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        guard var items = try? modelContext.fetch(descriptor) else { return }

        var used = items.reduce(0) { $0 + $1.byteCount }
        // Prefer measured disk usage when available (includes thumbnails).
        let diskUsed = ClipboardStore.usedBytes()
        if diskUsed > used { used = diskUsed }

        while used > maxBytes, let oldest = items.first {
            used -= oldest.byteCount
            ClipboardStore.remove(hash: oldest.contentHash, fileExtension: oldest.payloadExtension)
            modelContext.delete(oldest)
            items.removeFirst()
        }
    }

    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
