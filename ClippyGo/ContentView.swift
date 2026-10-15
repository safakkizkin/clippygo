//
//  ContentView.swift
//  ClippyGo
//
//  Created by safak on 7.10.2026.
//

import AppKit
import SwiftData
import SwiftUI

struct ContentView: View {
    @Query(sort: \ClipboardItem.timestamp, order: .reverse) private var history: [ClipboardItem]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""

    var filteredHistory: [ClipboardItem] {
        if searchText.isEmpty {
            return history
        }
        return history.filter {
            $0.displayTitle.localizedCaseInsensitiveContains(searchText)
                || $0.kindRaw.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding()

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if filteredHistory.isEmpty {
                        Text(searchText.isEmpty ? "History is empty" : "No results found")
                            .foregroundColor(.secondary)
                            .padding()
                    }

                    ForEach(filteredHistory) { item in
                        Button(action: {
                            copyToPasteboard(item)
                        }) {
                            HStack(spacing: 10) {
                                thumbnail(for: item)

                                Text(previewText(for: item))
                                    .lineLimit(2)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Divider()
                    }
                }
            }

            HStack {
                Button("Clear") {
                    try? modelContext.delete(model: ClipboardItem.self)
                }
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 320, height: 450)
    }

    @ViewBuilder
    private func thumbnail(for item: ClipboardItem) -> some View {
        switch item.kind {
        case .image:
            if let data = item.data, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                kindIcon("photo")
            }
        case .pdf:
            kindIcon("doc.richtext")
        case .file:
            kindIcon("doc")
        case .text:
            kindIcon("text.alignleft")
        }
    }

    private func kindIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
            .frame(width: 36, height: 36)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func previewText(for item: ClipboardItem) -> String {
        switch item.kind {
        case .text:
            let text = item.text
            if text.count > 100 {
                return String(text.prefix(100)) + "..."
            }
            return text
        case .image, .pdf, .file:
            return item.displayTitle
        }
    }

    private func copyToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.kind {
        case .text:
            pasteboard.setString(item.text, forType: .string)

        case .image:
            guard let data = item.data else { return }
            let type = pasteboardType(from: item.pasteboardType) ?? .tiff
            pasteboard.setData(data, forType: type)

        case .pdf:
            guard let data = item.data else { return }
            pasteboard.setData(data, forType: .pdf)

        case .file:
            guard let data = item.data,
                  let paths = String(data: data, encoding: .utf8) else { return }
            let urls = paths
                .split(separator: "\n", omittingEmptySubsequences: true)
                .map { URL(fileURLWithPath: String($0)) as NSURL }
            pasteboard.writeObjects(urls)
        }
    }

    private func pasteboardType(from raw: String?) -> NSPasteboard.PasteboardType? {
        guard let raw, !raw.isEmpty else { return nil }
        return NSPasteboard.PasteboardType(raw)
    }
}
