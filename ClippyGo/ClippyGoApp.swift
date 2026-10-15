//
//  ClippyGoApp.swift
//  ClippyGo
//
//  Created by safak.dev on 7.10.2026.
//

import SwiftData
import SwiftUI

@main
struct ClippyGoApp: App {
    let container: ModelContainer
    @StateObject private var monitor: ClipboardMonitor
    @StateObject private var languageController: LanguageController

    init() {
        let schema = Schema([ClipboardItem.self, AppSettings.self])
        let storeURL = Self.sqliteStoreURL()
        let configuration = ModelConfiguration(
            "ClippyGo",
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )

        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Schema changed. Wipe DB + on-disk payloads and recreate.
            try? FileManager.default.removeItem(at: storeURL)
            // SwiftData may also create adjacent -shm/-wal files.
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: storeURL.path + "-shm"))
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: storeURL.path + "-wal"))
            ClipboardStore.removeAll()
            do {
                container = try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                fatalError("Failed to configure SQLite store: \(error)")
            }
        }

        let context = container.mainContext
        let settings = AppSettings.current(in: context)
        let clipboardMonitor = ClipboardMonitor(modelContext: context)
        clipboardMonitor.enforceLimits()
        _monitor = StateObject(wrappedValue: clipboardMonitor)
        _languageController = StateObject(wrappedValue: LanguageController(code: settings.languageCode))
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .modelContainer(container)
                .environmentObject(monitor)
                .environmentObject(languageController)
                .environment(\.locale, languageController.locale)
                .environment(\.layoutDirection, languageController.layoutDirection)
        } label: {
            // Cropped template logo; sized to match neighboring status items (~18–22pt).
            Image("MenuBarIcon")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
                .accessibilityLabel("ClippyGo")
        }
        .menuBarExtraStyle(.window)
    }

    /// Local SQLite database under Application Support.
    private static func sqliteStoreURL() -> URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = base.appendingPathComponent("ClippyGo", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("clippygo.sqlite")
    }
}
