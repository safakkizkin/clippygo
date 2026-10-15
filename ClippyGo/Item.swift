//
//  Item.swift
//  ClippyGo
//
//  Created by safak on 7.10.2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date

    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
