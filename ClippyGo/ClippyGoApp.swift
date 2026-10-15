//
//  ClippyGoApp.swift
//  ClippyGo
//
//  Created by safak on 7.10.2026.
//

import SwiftUI
import SwiftData

@main
struct ClippyGoApp: App {
    let container: ModelContainer
    @StateObject private var monitor: ClipboardMonitor

    init() {
        let schema = Schema([ClipboardItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Schema changed (text-only → rich clipboard). Wipe and recreate.
            try? FileManager.default.removeItem(at: configuration.url)
            do {
                container = try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                fatalError("Failed to configure SwiftData container: \(error)")
            }
        }

        let context = container.mainContext
        _monitor = StateObject(wrappedValue: ClipboardMonitor(modelContext: context))
    }

    var body: some Scene {
        MenuBarExtra("ClippyGo", systemImage: "clipboard") {
            ContentView()
                .modelContainer(container)
        }
        .menuBarExtraStyle(.window)
    }
}
