#!/usr/bin/env swift
import AppKit
import Foundation

// MARK: - ClippyGo mark (clipboard, no cat)
// Small-size first: bold clip + board + 2 paper lines.

enum MarkStyle {
    case appIcon   // white mark on dark rounded square
    case template  // black mark on transparent (menu bar)
}

func drawMark(in rect: CGRect, ctx: CGContext, style: MarkStyle) {
    let w = rect.width
    let h = rect.height

    // Board
    let boardLeft = rect.minX + w * 0.22
    let boardRight = rect.maxX - w * 0.22
    let boardBottom = rect.minY + h * 0.12
    let boardTop = rect.minY + h * 0.72
    let boardW = boardRight - boardLeft
    let boardH = boardTop - boardBottom
    let boardRadius = boardW * 0.12

    let board = CGPath(
        roundedRect: CGRect(x: boardLeft, y: boardBottom, width: boardW, height: boardH),
        cornerWidth: boardRadius,
        cornerHeight: boardRadius,
        transform: nil
    )

    // Clip (metal binder) sitting on top of the board
    let clipW = boardW * 0.42
    let clipH = h * 0.22
    let clipX = (boardLeft + boardRight) / 2 - clipW / 2
    let clipY = boardTop - clipH * 0.35
    let clipRadius = clipW * 0.18
    let clip = CGPath(
        roundedRect: CGRect(x: clipX, y: clipY, width: clipW, height: clipH),
        cornerWidth: clipRadius,
        cornerHeight: clipRadius,
        transform: nil
    )

    // Inner clip window (cutout) so it reads as a binder, not a blob
    let windowInsetX = clipW * 0.22
    let windowInsetY = clipH * 0.28
    let clipWindow = CGPath(
        roundedRect: CGRect(
            x: clipX + windowInsetX,
            y: clipY + windowInsetY,
            width: clipW - windowInsetX * 2,
            height: clipH - windowInsetY * 2
        ),
        cornerWidth: clipRadius * 0.5,
        cornerHeight: clipRadius * 0.5,
        transform: nil
    )

    // Paper lines
    let lineInset = boardW * 0.18
    let lineH = max(2, boardW * 0.07)
    let line1Y = boardBottom + boardH * 0.38
    let line2Y = boardBottom + boardH * 0.58
    let line1 = CGPath(
        roundedRect: CGRect(x: boardLeft + lineInset, y: line1Y, width: boardW - lineInset * 2, height: lineH),
        cornerWidth: lineH / 2,
        cornerHeight: lineH / 2,
        transform: nil
    )
    let line2 = CGPath(
        roundedRect: CGRect(x: boardLeft + lineInset, y: line2Y, width: boardW - lineInset * 2.5, height: lineH),
        cornerWidth: lineH / 2,
        cornerHeight: lineH / 2,
        transform: nil
    )

    switch style {
    case .appIcon:
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.addPath(board)
        ctx.fillPath()
        ctx.addPath(clip)
        ctx.fillPath()

        ctx.setFillColor(NSColor(calibratedWhite: 0.07, alpha: 1).cgColor)
        ctx.addPath(clipWindow)
        ctx.fillPath()
        ctx.addPath(line1)
        ctx.fillPath()
        ctx.addPath(line2)
        ctx.fillPath()

    case .template:
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.addPath(board)
        ctx.fillPath()
        ctx.addPath(clip)
        ctx.fillPath()

        ctx.setBlendMode(.clear)
        ctx.addPath(clipWindow)
        ctx.fillPath()
        ctx.addPath(line1)
        ctx.fillPath()
        ctx.addPath(line2)
        ctx.fillPath()
        ctx.setBlendMode(.normal)
    }
}

func renderAppIcon(size px: Int) -> Data {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: px,
        pixelsHigh: px,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let ctx = NSGraphicsContext(bitmapImageRep: rep)?.cgContext else {
        fatalError("bitmap")
    }

    let bounds = CGRect(x: 0, y: 0, width: px, height: px)
    ctx.clear(bounds)

    let radius = CGFloat(px) * 0.223
    let iconRect = bounds.insetBy(dx: CGFloat(px) * 0.02, dy: CGFloat(px) * 0.02)
    let bg = CGPath(roundedRect: iconRect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.setFillColor(NSColor(calibratedWhite: 0.07, alpha: 1).cgColor)
    ctx.addPath(bg)
    ctx.fillPath()

    drawMark(in: iconRect.insetBy(dx: CGFloat(px) * 0.02, dy: CGFloat(px) * 0.02), ctx: ctx, style: .appIcon)
    return rep.representation(using: .png, properties: [:])!
}

func renderTemplate(size px: Int) -> Data {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: px,
        pixelsHigh: px,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let ctx = NSGraphicsContext(bitmapImageRep: rep)?.cgContext else {
        fatalError("bitmap")
    }

    let bounds = CGRect(x: 0, y: 0, width: px, height: px)
    ctx.clear(bounds)
    drawMark(in: bounds.insetBy(dx: CGFloat(px) * 0.06, dy: CGFloat(px) * 0.06), ctx: ctx, style: .template)
    return rep.representation(using: .png, properties: [:])!
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let appIconDir = root.appendingPathComponent("ClippyGo/Assets.xcassets/AppIcon.appiconset")
let menuDir = root.appendingPathComponent("ClippyGo/Assets.xcassets/MenuBarIcon.imageset")
try FileManager.default.createDirectory(at: appIconDir, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: menuDir, withIntermediateDirectories: true)

for (px, name) in [
    (16, "16.png"), (32, "32.png"), (64, "64.png"),
    (128, "128.png"), (256, "256.png"), (512, "512.png"), (1024, "1024.png"),
] as [(Int, String)] {
    try renderAppIcon(size: px).write(to: appIconDir.appendingPathComponent(name))
    print("app \(name)")
}

for (px, name) in [
    (22, "MenuBarIcon.png"),
    (44, "MenuBarIcon@2x.png"),
    (66, "MenuBarIcon@3x.png"),
] as [(Int, String)] {
    try renderTemplate(size: px).write(to: menuDir.appendingPathComponent(name))
    print("menu \(name)")
}

try renderAppIcon(size: 256).write(to: URL(fileURLWithPath: "/tmp/clippygo_appicon_preview.png"))

func previewTemplate(tintWhite: Bool, background: NSColor, path: String) throws {
    let px = 132
    guard let out = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: px,
        pixelsHigh: px,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: out)
    background.setFill()
    NSRect(x: 0, y: 0, width: px, height: px).fill()

    guard let tintedRep = NSBitmapImageRep(data: renderTemplate(size: 66)),
          let d = tintedRep.bitmapData else { return }
    let row = tintedRep.bytesPerRow
    let c: UInt8 = tintWhite ? 255 : 0
    for y in 0..<tintedRep.pixelsHigh {
        for x in 0..<tintedRep.pixelsWide {
            let i = y * row + x * 4
            let a = d[i + 3]
            d[i] = c
            d[i + 1] = c
            d[i + 2] = c
            d[i + 3] = a
        }
    }
    let tinted = NSImage(size: NSSize(width: 66, height: 66))
    tinted.addRepresentation(tintedRep)
    let pad = CGFloat(px) * 0.16
    tinted.draw(
        in: NSRect(x: pad, y: pad, width: CGFloat(px) - pad * 2, height: CGFloat(px) - pad * 2),
        from: .zero,
        operation: .sourceOver,
        fraction: 1
    )
    NSGraphicsContext.restoreGraphicsState()
    try out.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}

try previewTemplate(tintWhite: false, background: .white, path: "/tmp/clippygo_menubar_on_light.png")
try previewTemplate(
    tintWhite: true,
    background: NSColor(calibratedWhite: 0.15, alpha: 1),
    path: "/tmp/clippygo_menubar_on_dark.png"
)

print("done — also run: scripts regenerate AppIcon-Complete.icns via iconutil (see Makefile note)")
print("App PNGs updated. Rebuild in Xcode (Product → Clean Build Folder, then Run).")
