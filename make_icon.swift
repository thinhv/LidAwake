import AppKit

// Renders AppIcon.iconset (then turned into AppIcon.icns by iconutil in build.sh).
// Design: deep night-blue rounded square, white laptop, warm crescent moon above it.

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func render(px: Int) -> Data {
    let s = CGFloat(px)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // macOS icon grid: 824/1024 body with ~185/1024 corner radius.
    let inset = s * 100 / 1024
    let body = NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let radius = s * 185 / 1024
    let path = NSBezierPath(roundedRect: body, xRadius: radius, yRadius: radius)

    // Soft drop shadow.
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    shadow.shadowBlurRadius = s * 0.02
    shadow.shadowOffset = NSSize(width: 0, height: -s * 0.01)
    shadow.set()
    NSColor.black.setFill()
    path.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGradient(colors: [
        NSColor(calibratedRed: 0.20, green: 0.24, blue: 0.55, alpha: 1),
        NSColor(calibratedRed: 0.06, green: 0.07, blue: 0.20, alpha: 1),
    ])!.draw(in: path, angle: -90)

    // Stars.
    NSColor.white.withAlphaComponent(0.7).setFill()
    for (x, y, r) in [(0.27, 0.78, 0.010), (0.36, 0.70, 0.006), (0.22, 0.63, 0.007), (0.45, 0.80, 0.005)] {
        NSBezierPath(ovalIn: NSRect(x: s * x, y: s * y, width: s * r * 2, height: s * r * 2)).fill()
    }

    // Crescent moon (top right).
    let moonR = s * 0.11
    let moonC = NSPoint(x: s * 0.66, y: s * 0.74)
    let moon = NSBezierPath(ovalIn: NSRect(x: moonC.x - moonR, y: moonC.y - moonR, width: moonR * 2, height: moonR * 2))
    NSGraphicsContext.saveGraphicsState()
    let cut = NSBezierPath(rect: NSRect(x: 0, y: 0, width: s, height: s))
    cut.appendOval(in: NSRect(x: moonC.x - moonR * 0.45, y: moonC.y - moonR * 0.65, width: moonR * 2, height: moonR * 2))
    cut.windingRule = .evenOdd
    cut.addClip()
    NSColor(calibratedRed: 1.0, green: 0.82, blue: 0.40, alpha: 1).setFill()
    moon.fill()
    NSGraphicsContext.restoreGraphicsState()

    // Laptop (closed-ish lid): screen + base.
    let white = NSColor.white
    let screen = NSRect(x: s * 0.29, y: s * 0.345, width: s * 0.42, height: s * 0.26)
    let screenPath = NSBezierPath(roundedRect: screen, xRadius: s * 0.025, yRadius: s * 0.025)
    white.setFill()
    screenPath.fill()
    // Screen glow (awake).
    let inner = screen.insetBy(dx: s * 0.02, dy: s * 0.02)
    NSGradient(colors: [
        NSColor(calibratedRed: 0.45, green: 0.85, blue: 1.0, alpha: 1),
        NSColor(calibratedRed: 0.25, green: 0.50, blue: 0.95, alpha: 1),
    ])!.draw(in: NSBezierPath(roundedRect: inner, xRadius: s * 0.012, yRadius: s * 0.012), angle: -90)
    let base = NSBezierPath()
    base.move(to: NSPoint(x: s * 0.27, y: s * 0.33))
    base.line(to: NSPoint(x: s * 0.73, y: s * 0.33))
    base.line(to: NSPoint(x: s * 0.79, y: s * 0.28))
    base.line(to: NSPoint(x: s * 0.21, y: s * 0.28))
    base.close()
    white.setFill()
    base.fill()

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for size in [16, 32, 128, 256, 512] {
    try render(px: size).write(to: URL(fileURLWithPath: "\(outDir)/icon_\(size)x\(size).png"))
    try render(px: size * 2).write(to: URL(fileURLWithPath: "\(outDir)/icon_\(size)x\(size)@2x.png"))
}
