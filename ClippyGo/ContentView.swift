//
//  ContentView.swift
//  ClippyGo
//
//  Created by safak.dev on 7.10.2026.
//

import AppKit
import SwiftData
import SwiftUI

struct ContentView: View {
    @Query(sort: \ClipboardItem.timestamp, order: .reverse) private var history: [ClipboardItem]
    @Query private var settingsRows: [AppSettings]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var monitor: ClipboardMonitor
    @EnvironmentObject private var languageController: LanguageController

    @State private var searchText = ""
    @State private var showSettings = false
    @State private var usedStorageBytes = 0

    private var settings: AppSettings {
        settingsRows.first ?? AppSettings.current(in: modelContext)
    }

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
            HStack(spacing: 8) {
                if showSettings {
                    BrandLogo(size: 18)
                        .foregroundStyle(.secondary)
                    Text(L10n.settings)
                        .font(.headline)
                    Spacer()
                    Button(L10n.done) {
                        showSettings = false
                        refreshStorageUsage()
                    }
                    .keyboardShortcut(.defaultAction)
                } else {
                    BrandLogo(size: 18)
                        .foregroundStyle(.secondary)
                    TextField(L10n.searchPlaceholder, text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        refreshStorageUsage()
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .buttonStyle(.borderless)
                    .help(L10n.settings)
                }
            }
            .padding()

            Divider()

            if showSettings {
                SettingsView(
                    settings: settings,
                    usedStorageBytes: usedStorageBytes,
                    onSettingsChanged: {
                        try? modelContext.save()
                        monitor.enforceLimits()
                        refreshStorageUsage()
                    }
                )
            } else {
                historyList
            }

            HStack {
                Button(L10n.clear) {
                    clearHistory()
                }
                .disabled(showSettings)
                Spacer()
                Button(L10n.quit) {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 340, height: 480)
        .environment(\.locale, languageController.locale)
        .environment(\.layoutDirection, languageController.layoutDirection)
        // Do NOT use flipsForRightToLeftLayoutDirection — it mirrors glyphs
        // (Settings → "sgnitteS") and breaks Arabic shaping.
        .id(languageController.language.rawValue)
        .onAppear {
            languageController.apply(code: settings.languageCode)
            refreshStorageUsage()
        }
    }

    private var historyList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if filteredHistory.isEmpty {
                    VStack(spacing: 12) {
                        BrandLogo(size: 44)
                            .foregroundStyle(.tertiary)
                        Text(searchText.isEmpty ? L10n.historyEmpty : L10n.noResults)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                    .padding(.horizontal)
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
    }

    @ViewBuilder
    private func thumbnail(for item: ClipboardItem) -> some View {
        switch item.kind {
        case .image:
            if let nsImage = ClipboardStore.loadThumbnail(hash: item.contentHash) {
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
            guard let ext = item.payloadExtension,
                  let data = ClipboardStore.readPayload(hash: item.contentHash, fileExtension: ext) else { return }
            let type = pasteboardType(from: item.pasteboardType) ?? .tiff
            pasteboard.setData(data, forType: type)

        case .pdf:
            let ext = item.payloadExtension ?? "pdf"
            guard let data = ClipboardStore.readPayload(hash: item.contentHash, fileExtension: ext) else { return }
            pasteboard.setData(data, forType: .pdf)

        case .file:
            guard let paths = item.filePaths else { return }
            let urls = paths
                .split(separator: "\n", omittingEmptySubsequences: true)
                .map { URL(fileURLWithPath: String($0)) as NSURL }
            pasteboard.writeObjects(urls)
        }
    }

    private func clearHistory() {
        for item in history {
            ClipboardStore.remove(hash: item.contentHash, fileExtension: item.payloadExtension)
        }
        ClipboardStore.removeAll()
        try? modelContext.delete(model: ClipboardItem.self)
        refreshStorageUsage()
    }

    private func refreshStorageUsage() {
        usedStorageBytes = ClipboardStore.usedBytes()
    }

    private func pasteboardType(from raw: String?) -> NSPasteboard.PasteboardType? {
        guard let raw, !raw.isEmpty else { return nil }
        return NSPasteboard.PasteboardType(raw)
    }
}
