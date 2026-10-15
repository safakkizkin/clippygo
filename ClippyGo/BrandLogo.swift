//
//  BrandLogo.swift
//  ClippyGo
//
//  Created by safak.dev on 7.10.2026.
//

import SwiftUI

/// Shared clipboard mark used in the menu bar and inside the app.
struct BrandLogo: View {
    var size: CGFloat = 40

    var body: some View {
        Image("MenuBarIcon")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
