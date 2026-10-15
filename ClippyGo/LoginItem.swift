//
//  LoginItem.swift
//  ClippyGo
//
//  Created by safak.dev on 7.10.2026.
//

import Foundation
import ServiceManagement

/// Launch at login via `SMAppService` (macOS 13+).
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static var statusDescription: String {
        switch SMAppService.mainApp.status {
        case .enabled: return "enabled"
        case .notRegistered: return "notRegistered"
        case .notFound: return "notFound"
        case .requiresApproval: return "requiresApproval"
        @unknown default: return "unknown"
        }
    }

    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                if SMAppService.mainApp.status == .enabled { return true }
                try SMAppService.mainApp.register()
            } else {
                if SMAppService.mainApp.status == .notRegistered { return true }
                try SMAppService.mainApp.unregister()
            }
            return isEnabled == enabled || (enabled && SMAppService.mainApp.status == .requiresApproval)
        } catch {
            NSLog("ClippyGo login item error: \(error.localizedDescription)")
            return false
        }
    }
}
