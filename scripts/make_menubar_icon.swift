import AppKit
import Foundation

/// Simplified menu-bar mark: paper body + cat ears only (CG coords, origin bottom-left).
func drawSimplifiedLogo(in rect: CGRect, ctx: CGContext) {
    let w = rect.width
    let h = rect.height

    let bodyLeft = rect.minX + w * 0.16
    let bodyRight = rect.maxX - w * 0.16
    let bodyBottom = rect.minY + h * 0.08
    let shoulderY = rect.minY + h * 0.58
    let earPeakY = rect.maxY - h * 0.06
    let cornerR = w * 0.11

    let mid = (bodyLeft + bodyRight) / 2
    let leftPeakX = mid - w * 0.28
    let rightPeakX = mid + w * 0.28
    let leftInnerX = mid - w * 0.08
    let rightInnerX = mid + w * 0.08

    let path = CGMutablePath()

    // Bottom-left rounded corner → along bottom → bottom-right chamfer
    path.move(to: CGPoint(x: bodyLeft + cornerR, y: bodyBottom))
    path.addLine(to: CGPoint(x: bodyRight - cornerR * 0.9, y: bodyBottom))
    path.addLine(to: CGPoint(x: bodyRight, y: bodyBottom + cornerR * 1.1))
    path.addLine(to: CGPoint(x: bodyRight, y: shoulderY))

    // Right ear up and down
    path.addLine(to: CGPoint(x: rightPeakX, y: earPeakY))
    path.addLine(to: CGPoint(x: rightInnerX, y: shoulderY))

    // Left ear
    path.addLine(to: CGPoint(x: leftInnerX, y: shoulderY))
    path.addLine(to: CGPoint(x: leftPeakX, y: earPeakY))
    path.addLine(to: CGPoint(x: bodyLeft, y: shoulderY))

    path.addLine(to: CGPoint(x: bodyLeft, y: bodyBottom + cornerR))
    path.addQuadCurve(
        to: CGPoint(x: bodyLeft + cornerR, y: bodyBottom),
        control: CGPoint(x: bodyLeft, y: bodyBottom)
    )
    path.closeSubpath()

    ctx.setFillColor(NSColor.black.cgColor)
    ctx.addPath(path)
    ctx.fillPath()
}

func render(size px: Int, name: String, dir: URL) throws {
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
    ) else { return }

    guard let ctx = NSGraphicsContext(bitmapImageRep: rep)?.cgContext else { return }
    ctx.clear(CGRect(x: 0, y: 0, width: px, height: px))

    let inset = CGFloat(px) * 0.05
    let rect = CGRect(
        x: inset,
        y: inset,
        width: CGFloat(px) - inset * 2,
        height: CGFloat(px) - inset * 2
    )
    drawSimplifiedLogo(in: rect, ctx: ctx)

    let url = dir.appendingPathComponent(name)
    try rep.representation(using: .png, properties: [:])!.write(to: url)
    print("wrote \(name) \(px)px")
}

let dir = URL(fileURLWithPath: "ClippyGo/Assets.xcassets/MenuBarIcon.imageset")
try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

try render(size: 22, name: "MenuBarIcon.png", dir: dir)
try render(size: 44, name: "MenuBarIcon@2x.png", dir: dir)
try render(size: 66, name: "MenuBarIcon@3x.png", dir: dir)

guard let icon = NSImage(contentsOf: dir.appendingPathComponent("MenuBarIcon@3x.png")) else { exit(1) }
let previewPx = 132
guard let out = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: previewPx,
    pixelsHigh: previewPx,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else { exit(1) }
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: out)
NSColor.white.setFill()
NSRect(x: 0, y: 0, width: previewPx, height: previewPx).fill()
icon.draw(in: NSRect(x: 0, y: 0, width: previewPx, height: previewPx), from: .zero, operation: .sourceOver, fraction: 1)
NSGraphicsContext.restoreGraphicsState()
try out.representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: "/tmp/menubar_simplified.png"))
print("preview -> /tmp/menubar_simplified.png")
