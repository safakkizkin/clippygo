//
//  SettingsView.swift
//  ClippyGo
//
//  Created by safak.dev on 7.10.2026.
//

import AppKit
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    @EnvironmentObject private var languageController: LanguageController
    var usedStorageBytes: Int
    var onSettingsChanged: () -> Void

    @State private var openAtStartup = LoginItem.isEnabled
    @State private var loginItemError: String?

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        Form {
            Section {
                Picker(L10n.language, selection: languageBinding) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language.rawValue)
                    }
                }

                Toggle(L10n.openAtStartup, isOn: openAtStartupBinding)
                Text(L10n.openAtStartupHelp)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let loginItemError {
                    Text(loginItemError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: {
                Text(L10n.general)
            }

            Section(L10n.history) {
                Picker(L10n.maxItems, selection: $settings.maxHistoryCount) {
                    ForEach(AppSettings.historyCountOptions, id: \.self) { count in
                        Text("\(count)").tag(count)
                    }
                }
                .onChange(of: settings.maxHistoryCount) { _, _ in
                    onSettingsChanged()
                }
            }

            Section(L10n.sizeLimits) {
                Picker(L10n.maxItemSize, selection: $settings.maxItemBytes) {
                    ForEach(AppSettings.itemSizeByteOptions, id: \.self) { bytes in
                        Text(ByteFormat.optionLabel(bytes)).tag(bytes)
                    }
                }
                .onChange(of: settings.maxItemBytes) { _, _ in
                    onSettingsChanged()
                }

                Picker(L10n.maxTotalStorage, selection: $settings.maxTotalStorageBytes) {
                    ForEach(AppSettings.storageSizeByteOptions, id: \.self) { bytes in
                        Text(ByteFormat.optionLabel(bytes)).tag(bytes)
                    }
                }
                .onChange(of: settings.maxTotalStorageBytes) { _, _ in
                    onSettingsChanged()
                }

                LabeledContent(L10n.usedStorage) {
                    Text(ByteFormat.string(usedStorageBytes))
                        .foregroundStyle(.secondary)
                }
            }

            Section(L10n.capture) {
                Toggle(L10n.text, isOn: $settings.captureText)
                    .onChange(of: settings.captureText) { _, _ in onSettingsChanged() }
                Toggle(L10n.images, isOn: $settings.captureImages)
                    .onChange(of: settings.captureImages) { _, _ in onSettingsChanged() }
                Toggle(L10n.pdfs, isOn: $settings.capturePDFs)
                    .onChange(of: settings.capturePDFs) { _, _ in onSettingsChanged() }
                Toggle(L10n.files, isOn: $settings.captureFiles)
                    .onChange(of: settings.captureFiles) { _, _ in onSettingsChanged() }
            }

            Section(L10n.storage) {
                LabeledContent(L10n.database) {
                    Text(L10n.sqliteLocal)
                        .foregroundStyle(.secondary)
                }
                LabeledContent(L10n.payloads) {
                    Text(L10n.applicationSupport)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Section(L10n.privacy) {
                Text(L10n.privacySummary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section(L10n.about) {
                HStack(spacing: 12) {
                    BrandLogo(size: 36)
                        .foregroundStyle(.primary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(AppStoreConfig.appName)
                            .font(.headline)
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                        Text(AppStoreConfig.author)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 2)

                LabeledContent(L10n.contact) {
                    Text(AppStoreConfig.supportEmail)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 4)
        .environment(\.layoutDirection, languageController.layoutDirection)
        .id("\(languageController.language.rawValue)-\(languageController.layoutDirection)")
        .onAppear {
            openAtStartup = LoginItem.isEnabled
        }
    }

    private var languageBinding: Binding<String> {
        Binding(
            get: { settings.languageCode },
            set: { newValue in
                settings.languageCode = newValue
                languageController.apply(code: newValue)
                onSettingsChanged()
            }
        )
    }

    private var openAtStartupBinding: Binding<Bool> {
        Binding(
            get: { openAtStartup },
            set: { newValue in
                loginItemError = nil
                let ok = LoginItem.setEnabled(newValue)
                openAtStartup = LoginItem.isEnabled
                if !ok {
                    // Xcode/debug builds often can't register; installed apps can.
                    loginItemError = L10n.openAtStartupFailed
                    openAtStartup = LoginItem.isEnabled
                } else if LoginItem.statusDescription == "requiresApproval" {
                    openAtStartup = true
                }
            }
        )
    }
}
