#!/usr/bin/env swift
import AppKit
import Foundation

let packageRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconsDirectory = packageRoot
    .appendingPathComponent("Sources/MacWinManagerApp/Resources/Icons", isDirectory: true)
let appIconSet = iconsDirectory.appendingPathComponent("MacWinAppIcon.iconset", isDirectory: true)
let exeIconSet = iconsDirectory.appendingPathComponent("MacWinExeDocument.iconset", isDirectory: true)
let builtInIconsDirectory = iconsDirectory.appendingPathComponent("BuiltIn", isDirectory: true)
let appAssetCatalog = packageRoot
    .appendingPathComponent("Sources/MacWinManagerApp/Resources/AppAssets.xcassets", isDirectory: true)
let appIconAssetSet = appAssetCatalog.appendingPathComponent("AppIcon.appiconset", isDirectory: true)
try FileManager.default.createDirectory(at: iconsDirectory, withIntermediateDirectories: true)
try? FileManager.default.removeItem(at: appIconSet)
try? FileManager.default.removeItem(at: exeIconSet)
try? FileManager.default.removeItem(at: builtInIconsDirectory)
try? FileManager.default.removeItem(at: appIconAssetSet)
try FileManager.default.createDirectory(at: appIconSet, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: exeIconSet, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: builtInIconsDirectory, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: appIconAssetSet, withIntermediateDirectories: true)

func bitmap(size: CGFloat, draw: (CGRect) -> Void) throws -> NSBitmapImageRep {
    let pixelSize = Int(size.rounded())
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "MacWinIconGenerator", code: 1)
    }

    bitmap.size = NSSize(width: size, height: size)
    let previousContext = NSGraphicsContext.current
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    context.cgContext.clear(CGRect(x: 0, y: 0, width: size, height: size))
    draw(CGRect(x: 0, y: 0, width: size, height: size))
    context.flushGraphics()
    NSGraphicsContext.current = previousContext
    return bitmap
}

func roundedRect(_ rect: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func fillLinearGradient(in rect: CGRect, colors: [NSColor], angle: CGFloat) {
    NSGradient(colors: colors)?.draw(in: roundedRect(rect, radius: rect.width * 0.22), angle: angle)
}

func stroke(_ path: NSBezierPath, color: NSColor, width: CGFloat) {
    color.setStroke()
    path.lineWidth = width
    path.stroke()
}

func fill(_ path: NSBezierPath, color: NSColor) {
    color.setFill()
    path.fill()
}

func drawProceduralAppIcon(in rect: CGRect) {
    let scale = rect.width / 1024
    let canvas = rect.insetBy(dx: 62 * scale, dy: 62 * scale)
    let canvasPath = roundedRect(canvas, radius: 210 * scale)

    let shadow = NSShadow()
    shadow.shadowColor = NSColor(calibratedRed: 0.02, green: 0.20, blue: 0.34, alpha: 0.20)
    shadow.shadowBlurRadius = 30 * scale
    shadow.shadowOffset = NSSize(width: 0, height: -14 * scale)
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    NSGradient(colors: [
        NSColor(calibratedRed: 0.96, green: 0.99, blue: 1.00, alpha: 1),
        NSColor(calibratedRed: 0.72, green: 0.88, blue: 0.96, alpha: 1)
    ])?.draw(in: canvasPath, angle: -62)
    NSGraphicsContext.restoreGraphicsState()
    stroke(canvasPath, color: NSColor.white.withAlphaComponent(0.94), width: 7 * scale)

    let windowRect = CGRect(x: 180 * scale, y: 164 * scale, width: 664 * scale, height: 696 * scale)
    let windowPath = roundedRect(windowRect, radius: 112 * scale)
    let windowShadow = NSShadow()
    windowShadow.shadowColor = NSColor(calibratedRed: 0.02, green: 0.24, blue: 0.42, alpha: 0.24)
    windowShadow.shadowBlurRadius = 25 * scale
    windowShadow.shadowOffset = NSSize(width: 0, height: -11 * scale)
    NSGraphicsContext.saveGraphicsState()
    windowShadow.set()
    NSGradient(colors: [
        NSColor(calibratedRed: 0.94, green: 0.98, blue: 1.00, alpha: 0.98),
        NSColor(calibratedRed: 0.33, green: 0.76, blue: 0.94, alpha: 0.98)
    ])?.draw(in: windowPath, angle: -66)
    NSGraphicsContext.restoreGraphicsState()
    stroke(windowPath, color: NSColor.white.withAlphaComponent(0.90), width: 7 * scale)

    let toolbar = CGRect(
        x: windowRect.minX + 4 * scale,
        y: windowRect.maxY - 146 * scale,
        width: windowRect.width - 8 * scale,
        height: 142 * scale
    )
    let toolbarPath = NSBezierPath()
    toolbarPath.move(to: CGPoint(x: toolbar.minX, y: toolbar.minY))
    toolbarPath.line(to: CGPoint(x: toolbar.minX, y: toolbar.maxY - 68 * scale))
    toolbarPath.curve(
        to: CGPoint(x: toolbar.minX + 68 * scale, y: toolbar.maxY),
        controlPoint1: CGPoint(x: toolbar.minX, y: toolbar.maxY - 30 * scale),
        controlPoint2: CGPoint(x: toolbar.minX + 30 * scale, y: toolbar.maxY)
    )
    toolbarPath.line(to: CGPoint(x: toolbar.maxX - 68 * scale, y: toolbar.maxY))
    toolbarPath.curve(
        to: CGPoint(x: toolbar.maxX, y: toolbar.maxY - 68 * scale),
        controlPoint1: CGPoint(x: toolbar.maxX - 30 * scale, y: toolbar.maxY),
        controlPoint2: CGPoint(x: toolbar.maxX, y: toolbar.maxY - 30 * scale)
    )
    toolbarPath.line(to: CGPoint(x: toolbar.maxX, y: toolbar.minY))
    toolbarPath.close()
    fill(toolbarPath, color: NSColor.white.withAlphaComponent(0.78))

    let trafficColors: [NSColor] = [.systemRed, .systemYellow, .systemGreen]
    for (index, color) in trafficColors.enumerated() {
        let dot = CGRect(
            x: (292 + CGFloat(index) * 58) * scale,
            y: 722 * scale,
            width: 31 * scale,
            height: 31 * scale
        )
        fill(NSBezierPath(ovalIn: dot), color: color.blended(withFraction: 0.10, of: .white) ?? color)
        stroke(NSBezierPath(ovalIn: dot), color: NSColor.white.withAlphaComponent(0.82), width: 2 * scale)
    }

    let tileColors = [
        NSColor(calibratedRed: 1.00, green: 0.38, blue: 0.34, alpha: 1),
        NSColor(calibratedRed: 0.20, green: 0.82, blue: 0.67, alpha: 1),
        NSColor(calibratedRed: 0.18, green: 0.50, blue: 0.96, alpha: 1),
        NSColor(calibratedRed: 1.00, green: 0.67, blue: 0.16, alpha: 1)
    ]
    let tileSize = 188 * scale
    let tileGap = 30 * scale
    let tileGridWidth = tileSize * 2 + tileGap
    let tileGridOrigin = CGPoint(
        x: windowRect.midX - tileGridWidth / 2,
        y: windowRect.minY + 102 * scale
    )
    for row in 0..<2 {
        for column in 0..<2 {
            let index = row * 2 + column
            let tile = CGRect(
                x: tileGridOrigin.x + CGFloat(column) * (tileSize + tileGap),
                y: tileGridOrigin.y + CGFloat(1 - row) * (tileSize + tileGap),
                width: tileSize,
                height: tileSize
            )
            let tilePath = roundedRect(tile, radius: 48 * scale)
            NSGraphicsContext.saveGraphicsState()
            let tileShadow = NSShadow()
            tileShadow.shadowColor = NSColor.black.withAlphaComponent(0.20)
            tileShadow.shadowBlurRadius = 14 * scale
            tileShadow.shadowOffset = NSSize(width: 0, height: -7 * scale)
            tileShadow.set()
            NSGradient(colors: [
                tileColors[index].blended(withFraction: 0.20, of: .white) ?? tileColors[index],
                tileColors[index]
            ])?.draw(in: tilePath, angle: -70)
            NSGraphicsContext.restoreGraphicsState()
            stroke(tilePath, color: NSColor.white.withAlphaComponent(0.72), width: 3 * scale)
        }
    }
}

func drawCompactAppIcon(in rect: CGRect) {
    let scale = rect.width / 64
    let canvas = rect.insetBy(dx: 3 * scale, dy: 3 * scale)
    let canvasPath = roundedRect(canvas, radius: 15 * scale)
    let outerShadow = NSShadow()
    outerShadow.shadowColor = NSColor.black.withAlphaComponent(0.16)
    outerShadow.shadowBlurRadius = 2.5 * scale
    outerShadow.shadowOffset = NSSize(width: 0, height: -1.5 * scale)

    NSGraphicsContext.saveGraphicsState()
    outerShadow.set()
    NSGradient(colors: [
        NSColor(calibratedWhite: 1, alpha: 1),
        NSColor(calibratedRed: 0.92, green: 0.96, blue: 0.98, alpha: 1)
    ])?.draw(in: canvasPath, angle: -74)
    NSGraphicsContext.restoreGraphicsState()
    stroke(
        canvasPath,
        color: NSColor.white.withAlphaComponent(0.92),
        width: max(0.45, 0.8 * scale)
    )

    let windowRect = CGRect(
        x: 10 * scale,
        y: 14 * scale,
        width: 37 * scale,
        height: 37 * scale
    )
    let windowPath = roundedRect(windowRect, radius: 8.5 * scale)
    NSGradient(colors: [
        NSColor(calibratedRed: 0.35, green: 0.88, blue: 0.95, alpha: 1),
        NSColor(calibratedRed: 0.08, green: 0.55, blue: 0.82, alpha: 1)
    ])?.draw(in: windowPath, angle: -62)
    stroke(
        windowPath,
        color: NSColor.white.withAlphaComponent(0.88),
        width: max(0.6, 1.15 * scale)
    )

    let portalRect = CGRect(
        x: 24 * scale,
        y: 23 * scale,
        width: 10 * scale,
        height: 17 * scale
    )
    fill(
        roundedRect(portalRect, radius: 4.4 * scale),
        color: NSColor(calibratedRed: 0.03, green: 0.42, blue: 0.63, alpha: 0.88)
    )
    stroke(
        roundedRect(portalRect.insetBy(dx: -1.2 * scale, dy: -1.2 * scale), radius: 5.2 * scale),
        color: NSColor.white.withAlphaComponent(0.86),
        width: max(0.6, 1.25 * scale)
    )

    let tileRect = CGRect(
        x: 34 * scale,
        y: 10 * scale,
        width: 20 * scale,
        height: 23 * scale
    )
    let tilePath = roundedRect(tileRect, radius: 5.5 * scale)
    let tileShadow = NSShadow()
    tileShadow.shadowColor = NSColor.black.withAlphaComponent(0.20)
    tileShadow.shadowBlurRadius = 2.2 * scale
    tileShadow.shadowOffset = NSSize(width: 0, height: -1.2 * scale)
    NSGraphicsContext.saveGraphicsState()
    tileShadow.set()
    NSGradient(colors: [
        NSColor(calibratedRed: 1.00, green: 0.50, blue: 0.42, alpha: 1),
        NSColor(calibratedRed: 0.93, green: 0.25, blue: 0.27, alpha: 1)
    ])?.draw(in: tilePath, angle: -72)
    NSGraphicsContext.restoreGraphicsState()
    stroke(
        tilePath,
        color: NSColor.white.withAlphaComponent(0.88),
        width: max(0.55, 1.0 * scale)
    )

    if rect.width >= 24 {
        let trafficColors: [NSColor] = [.systemRed, .systemYellow, .systemGreen]
        for (index, color) in trafficColors.enumerated() {
            let dot = CGRect(
                x: (15 + CGFloat(index) * 4.1) * scale,
                y: 44 * scale,
                width: 2.35 * scale,
                height: 2.35 * scale
            )
            fill(NSBezierPath(ovalIn: dot), color: color)
        }

        let appTile = CGRect(
            x: 39.5 * scale,
            y: 16 * scale,
            width: 9 * scale,
            height: 8.5 * scale
        )
        fill(
            roundedRect(appTile, radius: 2 * scale),
            color: NSColor.white.withAlphaComponent(0.90)
        )
        let appTileLine = NSBezierPath()
        appTileLine.move(to: CGPoint(x: appTile.minX + 1.5 * scale, y: appTile.midY))
        appTileLine.line(to: CGPoint(x: appTile.maxX - 1.5 * scale, y: appTile.midY))
        stroke(
            appTileLine,
            color: NSColor(calibratedRed: 0.83, green: 0.22, blue: 0.23, alpha: 0.72),
            width: max(0.45, 0.75 * scale)
        )
    }
}

func drawModernAppIconGlyph(in rect: CGRect) {
    let scale = rect.width / 64
    let windowRect = CGRect(
        x: rect.minX + 3 * scale,
        y: rect.minY + 10 * scale,
        width: 45 * scale,
        height: 48 * scale
    )
    let windowPath = roundedRect(windowRect, radius: 10.5 * scale)
    let windowShadow = NSShadow()
    windowShadow.shadowColor = NSColor(calibratedRed: 0.00, green: 0.30, blue: 0.49, alpha: 0.24)
    windowShadow.shadowBlurRadius = 3.8 * scale
    windowShadow.shadowOffset = NSSize(width: 0, height: -2.2 * scale)

    NSGraphicsContext.saveGraphicsState()
    windowShadow.set()
    NSGradient(colors: [
        NSColor(calibratedRed: 0.46, green: 0.92, blue: 0.97, alpha: 0.98),
        NSColor(calibratedRed: 0.06, green: 0.58, blue: 0.84, alpha: 0.98)
    ])?.draw(in: windowPath, angle: -62)
    NSGraphicsContext.restoreGraphicsState()
    stroke(
        windowPath,
        color: NSColor.white.withAlphaComponent(0.92),
        width: max(0.7, 1.35 * scale)
    )

    let toolbarRect = CGRect(
        x: windowRect.minX + 1.4 * scale,
        y: windowRect.maxY - 11.5 * scale,
        width: windowRect.width - 2.8 * scale,
        height: 10.1 * scale
    )
    fill(
        roundedRect(toolbarRect, radius: 7.5 * scale),
        color: NSColor.white.withAlphaComponent(0.36)
    )

    let portalRect = CGRect(
        x: rect.minX + 18 * scale,
        y: rect.minY + 20 * scale,
        width: 13 * scale,
        height: 23 * scale
    )
    fill(
        roundedRect(portalRect, radius: 5.7 * scale),
        color: NSColor(calibratedRed: 0.02, green: 0.39, blue: 0.60, alpha: 0.90)
    )
    stroke(
        roundedRect(portalRect.insetBy(dx: -1.5 * scale, dy: -1.5 * scale), radius: 6.8 * scale),
        color: NSColor.white.withAlphaComponent(0.88),
        width: max(0.65, 1.35 * scale)
    )

    let tileRect = CGRect(
        x: rect.minX + 35 * scale,
        y: rect.minY + 3 * scale,
        width: 26 * scale,
        height: 29 * scale
    )
    let tilePath = roundedRect(tileRect, radius: 7.5 * scale)
    let tileShadow = NSShadow()
    tileShadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
    tileShadow.shadowBlurRadius = 3.3 * scale
    tileShadow.shadowOffset = NSSize(width: 0, height: -1.8 * scale)
    NSGraphicsContext.saveGraphicsState()
    tileShadow.set()
    NSGradient(colors: [
        NSColor(calibratedRed: 1.00, green: 0.52, blue: 0.44, alpha: 1),
        NSColor(calibratedRed: 0.92, green: 0.23, blue: 0.27, alpha: 1)
    ])?.draw(in: tilePath, angle: -72)
    NSGraphicsContext.restoreGraphicsState()
    stroke(
        tilePath,
        color: NSColor.white.withAlphaComponent(0.92),
        width: max(0.65, 1.25 * scale)
    )

    if rect.width >= 24 {
        let trafficColors: [NSColor] = [.systemRed, .systemYellow, .systemGreen]
        for (index, color) in trafficColors.enumerated() {
            let dot = CGRect(
                x: rect.minX + (9 + CGFloat(index) * 4.6) * scale,
                y: rect.minY + 50.2 * scale,
                width: 2.65 * scale,
                height: 2.65 * scale
            )
            fill(NSBezierPath(ovalIn: dot), color: color)
        }

        let appTile = CGRect(
            x: rect.minX + 41 * scale,
            y: rect.minY + 11 * scale,
            width: 12.5 * scale,
            height: 11.5 * scale
        )
        fill(
            roundedRect(appTile, radius: 2.8 * scale),
            color: NSColor.white.withAlphaComponent(0.92)
        )
        let appTileLine = NSBezierPath()
        appTileLine.move(to: CGPoint(x: appTile.minX + 2 * scale, y: appTile.midY))
        appTileLine.line(to: CGPoint(x: appTile.maxX - 2 * scale, y: appTile.midY))
        stroke(
            appTileLine,
            color: NSColor(calibratedRed: 0.82, green: 0.20, blue: 0.22, alpha: 0.74),
            width: max(0.5, 0.85 * scale)
        )
    }
}

let generatedAppIconArtwork: NSImage? = {
    let candidates = [
        "MacWinAppIconArtwork-v12.png",
        "MacWinAppIconArtwork-v11.png",
        "MacWinAppIconArtwork.png"
    ]
    return candidates.lazy.compactMap {
        NSImage(contentsOf: iconsDirectory.appendingPathComponent($0))
    }.first
}()

func appIconArtworkSourceRect(_ artwork: NSImage) -> CGRect {
    let source = CGRect(origin: .zero, size: artwork.size)
    // Keep a small overscan so generated preview mattes never reach the icon.
    return source.insetBy(
        dx: source.width * 0.018,
        dy: source.height * 0.018
    )
}

func drawAppMark(in rect: CGRect) {
    guard let artwork = generatedAppIconArtwork else {
        drawProceduralAppIcon(in: rect)
        return
    }

    let sourceRect = appIconArtworkSourceRect(artwork)
    let markPath = roundedRect(
        rect.insetBy(dx: rect.width * 0.015, dy: rect.height * 0.015),
        radius: rect.width * 0.25
    )

    NSGraphicsContext.saveGraphicsState()
    markPath.addClip()
    artwork.draw(
        in: rect,
        from: sourceRect,
        operation: .sourceOver,
        fraction: 1,
        respectFlipped: true,
        hints: [.interpolation: NSImageInterpolation.high]
    )
    NSGraphicsContext.restoreGraphicsState()
}

func drawAppIcon(in rect: CGRect) {
    if rect.width <= 64 {
        drawCompactAppIcon(in: rect)
        return
    }

    guard let artwork = generatedAppIconArtwork else {
        drawProceduralAppIcon(in: rect)
        return
    }

    let scale = rect.width / 1024
    let canvas = rect.insetBy(dx: 48 * scale, dy: 48 * scale)
    let canvasPath = roundedRect(canvas, radius: 310 * scale)
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
    shadow.shadowBlurRadius = 28 * scale
    shadow.shadowOffset = NSSize(width: 0, height: -12 * scale)

    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    fill(canvasPath, color: .white)
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    canvasPath.addClip()
    artwork.draw(
        in: canvas,
        from: appIconArtworkSourceRect(artwork),
        operation: .sourceOver,
        fraction: 1,
        respectFlipped: true,
        hints: [.interpolation: NSImageInterpolation.high]
    )
    NSGraphicsContext.restoreGraphicsState()
    stroke(canvasPath, color: NSColor.white.withAlphaComponent(0.72), width: 3 * scale)
}

func drawExeDocumentIcon(in rect: CGRect) {
    let scale = rect.width / 1024
    let page = CGRect(x: 176 * scale, y: 88 * scale, width: 672 * scale, height: 848 * scale)
    let pagePath = roundedRect(page, radius: 74 * scale)
    fill(pagePath, color: NSColor(calibratedWhite: 0.96, alpha: 1))
    stroke(pagePath, color: NSColor(calibratedWhite: 0.78, alpha: 1), width: 8 * scale)

    let fold = NSBezierPath()
    fold.move(to: CGPoint(x: page.maxX - 170 * scale, y: page.maxY))
    fold.line(to: CGPoint(x: page.maxX, y: page.maxY - 170 * scale))
    fold.line(to: CGPoint(x: page.maxX - 170 * scale, y: page.maxY - 170 * scale))
    fold.close()
    fill(fold, color: NSColor(calibratedRed: 0.83, green: 0.90, blue: 0.95, alpha: 1))

    let appMark = CGRect(x: page.minX + 104 * scale, y: page.minY + 240 * scale, width: 464 * scale, height: 464 * scale)
    drawAppMark(in: appMark)

    let badge = CGRect(x: page.midX - 170 * scale, y: page.minY + 116 * scale, width: 340 * scale, height: 96 * scale)
    fill(roundedRect(badge, radius: 30 * scale), color: NSColor(calibratedRed: 0.09, green: 0.18, blue: 0.28, alpha: 1))
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 54 * scale, weight: .bold),
        .foregroundColor: NSColor.white
    ]
    let text = "EXE" as NSString
    let textSize = text.size(withAttributes: attrs)
    text.draw(
        at: CGPoint(x: badge.midX - textSize.width / 2, y: badge.midY - textSize.height / 2),
        withAttributes: attrs
    )
}

struct BuiltInIconSpec {
    let name: String
    let symbol: String
    let topColor: NSColor
    let bottomColor: NSColor
}

func drawBuiltInIcon(_ spec: BuiltInIconSpec, in rect: CGRect) {
    let scale = rect.width / 512
    let canvas = rect.insetBy(dx: 30 * scale, dy: 30 * scale)
    let path = roundedRect(canvas, radius: 104 * scale)
    let shadow = NSShadow()
    shadow.shadowColor = spec.bottomColor.withAlphaComponent(0.24)
    shadow.shadowBlurRadius = 20 * scale
    shadow.shadowOffset = NSSize(width: 0, height: -9 * scale)

    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    NSGradient(colors: [
        spec.topColor.blended(withFraction: 0.48, of: .white) ?? spec.topColor,
        spec.bottomColor
    ])?.draw(in: path, angle: -68)
    NSGraphicsContext.restoreGraphicsState()
    stroke(path, color: NSColor.white.withAlphaComponent(0.76), width: 3 * scale)

    let highlight = NSBezierPath()
    highlight.move(to: CGPoint(x: canvas.minX + 52 * scale, y: canvas.midY + 46 * scale))
    highlight.curve(
        to: CGPoint(x: canvas.maxX - 48 * scale, y: canvas.maxY - 60 * scale),
        controlPoint1: CGPoint(x: canvas.midX - 24 * scale, y: canvas.maxY - 8 * scale),
        controlPoint2: CGPoint(x: canvas.maxX - 76 * scale, y: canvas.maxY - 20 * scale)
    )
    highlight.line(to: CGPoint(x: canvas.minX + 52 * scale, y: canvas.maxY - 42 * scale))
    highlight.close()
    NSGraphicsContext.saveGraphicsState()
    path.addClip()
    fill(highlight, color: NSColor.white.withAlphaComponent(0.12))
    NSGraphicsContext.restoreGraphicsState()

    let symbolAccent = spec.bottomColor.blended(withFraction: 0.22, of: .black)
        ?? spec.bottomColor
    let symbolConfiguration = NSImage.SymbolConfiguration(
        pointSize: 188 * scale,
        weight: .semibold
    ).applying(NSImage.SymbolConfiguration(paletteColors: [.white, symbolAccent]))
    guard let symbol = NSImage(
        systemSymbolName: spec.symbol,
        accessibilityDescription: spec.name
    )?.withSymbolConfiguration(symbolConfiguration) else {
        return
    }
    let symbolSize = symbol.size
    let maxDimension = 204 * scale
    let ratio = min(maxDimension / symbolSize.width, maxDimension / symbolSize.height)
    let targetSize = NSSize(width: symbolSize.width * ratio, height: symbolSize.height * ratio)
    let targetRect = CGRect(
        x: rect.midX - targetSize.width / 2,
        y: rect.midY - targetSize.height / 2,
        width: targetSize.width,
        height: targetSize.height
    )

    NSGraphicsContext.saveGraphicsState()
    let symbolShadow = NSShadow()
    symbolShadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
    symbolShadow.shadowBlurRadius = 8 * scale
    symbolShadow.shadowOffset = NSSize(width: 0, height: -3 * scale)
    symbolShadow.set()
    symbol.draw(in: targetRect, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
}

func writePNG(_ bitmap: NSBitmapImageRep, to url: URL) throws {
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "MacWinIconGenerator", code: 1)
    }
    try data.write(to: url)
}

func writeIconSet(named name: String, to directory: URL, draw: @escaping (CGRect) -> Void) throws {
    let sizes: [(String, CGFloat)] = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024)
    ]
    for (fileName, size) in sizes {
        try writePNG(bitmap(size: size, draw: draw), to: directory.appendingPathComponent(fileName))
    }
    try writePNG(bitmap(size: 1024, draw: draw), to: iconsDirectory.appendingPathComponent("\(name).png"))
}

func writeAppIconAssetSet(draw: @escaping (CGRect) -> Void) throws {
    let entries: [(fileName: String, pixels: CGFloat, points: String, scale: String)] = [
        ("icon_16x16.png", 16, "16x16", "1x"),
        ("icon_16x16@2x.png", 32, "16x16", "2x"),
        ("icon_32x32.png", 32, "32x32", "1x"),
        ("icon_32x32@2x.png", 64, "32x32", "2x"),
        ("icon_128x128.png", 128, "128x128", "1x"),
        ("icon_128x128@2x.png", 256, "128x128", "2x"),
        ("icon_256x256.png", 256, "256x256", "1x"),
        ("icon_256x256@2x.png", 512, "256x256", "2x"),
        ("icon_512x512.png", 512, "512x512", "1x"),
        ("icon_512x512@2x.png", 1024, "512x512", "2x")
    ]

    for entry in entries {
        try writePNG(
            bitmap(size: entry.pixels, draw: draw),
            to: appIconAssetSet.appendingPathComponent(entry.fileName)
        )
    }

    let manifest: [String: Any] = [
        "images": entries.map { entry in
            [
                "filename": entry.fileName,
                "idiom": "mac",
                "scale": entry.scale,
                "size": entry.points
            ]
        },
        "info": [
            "author": "MacWin",
            "version": 1
        ]
    ]
    let manifestData = try JSONSerialization.data(
        withJSONObject: manifest,
        options: [.prettyPrinted, .sortedKeys]
    )
    try manifestData.write(
        to: appIconAssetSet.appendingPathComponent("Contents.json"),
        options: .atomic
    )
}

func appendBigEndianUInt32(_ value: UInt32, to data: inout Data) {
    var encoded = value.bigEndian
    withUnsafeBytes(of: &encoded) { bytes in
        data.append(contentsOf: bytes)
    }
}

func appendLittleEndianUInt16(_ value: UInt16, to data: inout Data) {
    var encoded = value.littleEndian
    withUnsafeBytes(of: &encoded) { bytes in
        data.append(contentsOf: bytes)
    }
}

func appendLittleEndianUInt32(_ value: UInt32, to data: inout Data) {
    var encoded = value.littleEndian
    withUnsafeBytes(of: &encoded) { bytes in
        data.append(contentsOf: bytes)
    }
}

func writeICO(to output: URL, draw: @escaping (CGRect) -> Void) throws {
    let sizes: [CGFloat] = [16, 32, 48, 64, 128, 256]
    let images = try sizes.map { size -> (size: Int, data: Data) in
        guard let png = try bitmap(size: size, draw: draw).representation(using: .png, properties: [:]) else {
            throw NSError(domain: "MacWinIconGenerator", code: 3)
        }
        return (Int(size), png)
    }

    var directory = Data()
    appendLittleEndianUInt16(0, to: &directory)
    appendLittleEndianUInt16(1, to: &directory)
    appendLittleEndianUInt16(UInt16(images.count), to: &directory)

    var offset = UInt32(6 + images.count * 16)
    for image in images {
        directory.append(UInt8(image.size == 256 ? 0 : image.size))
        directory.append(UInt8(image.size == 256 ? 0 : image.size))
        directory.append(0)
        directory.append(0)
        appendLittleEndianUInt16(1, to: &directory)
        appendLittleEndianUInt16(32, to: &directory)
        appendLittleEndianUInt32(UInt32(image.data.count), to: &directory)
        appendLittleEndianUInt32(offset, to: &directory)
        offset += UInt32(image.data.count)
    }
    for image in images { directory.append(image.data) }
    try directory.write(to: output, options: .atomic)
}

func writeICNS(to output: URL, draw: @escaping (CGRect) -> Void) throws {
    let entries: [(String, CGFloat)] = [
        ("icp4", 16),
        ("icp5", 32),
        ("icp6", 64),
        ("ic07", 128),
        ("ic08", 256),
        ("ic09", 512),
        ("ic10", 1024)
    ]
    var payload = Data()
    for (type, size) in entries {
        guard let png = try bitmap(size: size, draw: draw)
            .representation(using: .png, properties: [:]) else {
            throw NSError(domain: "MacWinIconGenerator", code: 2)
        }
        payload.append(contentsOf: type.utf8)
        appendBigEndianUInt32(UInt32(png.count + 8), to: &payload)
        payload.append(png)
    }

    var container = Data("icns".utf8)
    appendBigEndianUInt32(UInt32(payload.count + 8), to: &container)
    container.append(payload)
    try container.write(to: output, options: .atomic)
}

try writeIconSet(named: "MacWinAppIcon", to: appIconSet, draw: drawAppIcon)
try writeAppIconAssetSet(draw: drawModernAppIconGlyph)
try writeIconSet(named: "MacWinExeDocument", to: exeIconSet, draw: drawExeDocumentIcon)
try writePNG(
    bitmap(size: 512, draw: drawCompactAppIcon),
    to: iconsDirectory.appendingPathComponent("MacWinAppMark.png")
)

let builtInIcons = [
    BuiltInIconSpec(name: "MacWinApp", symbol: "macwindow.on.rectangle", topColor: .systemCyan, bottomColor: .systemBlue),
    BuiltInIconSpec(name: "MacWinBrowser", symbol: "globe", topColor: .systemBlue, bottomColor: .systemCyan),
    BuiltInIconSpec(name: "MacWinOffice", symbol: "doc.text.fill", topColor: .systemBlue, bottomColor: .systemIndigo),
    BuiltInIconSpec(name: "MacWinIndustrial", symbol: "gearshape.2.fill", topColor: .systemOrange, bottomColor: .systemRed),
    BuiltInIconSpec(name: "MacWinInstaller", symbol: "shippingbox.and.arrow.backward.fill", topColor: .systemGreen, bottomColor: .systemTeal),
    BuiltInIconSpec(name: "MacWinMedia", symbol: "play.rectangle.fill", topColor: .systemPink, bottomColor: .systemPurple),
    BuiltInIconSpec(name: "MacWinDrive", symbol: "internaldrive.fill", topColor: .systemTeal, bottomColor: .systemBlue),
    BuiltInIconSpec(name: "MacWinBottle", symbol: "shippingbox.fill", topColor: .systemOrange, bottomColor: .systemPink),
    BuiltInIconSpec(name: "MacWinDesktop", symbol: "macwindow", topColor: .systemBlue, bottomColor: .systemIndigo),
    BuiltInIconSpec(name: "MacWinSettings", symbol: "slider.horizontal.3", topColor: .systemGray, bottomColor: .darkGray),
    BuiltInIconSpec(name: "MacWinDiagnostics", symbol: "waveform.path.ecg.rectangle.fill", topColor: .systemMint, bottomColor: .systemGreen),
    BuiltInIconSpec(name: "MacWinMarket", symbol: "bag.fill", topColor: .systemGreen, bottomColor: .systemTeal),
    BuiltInIconSpec(name: "MacWinGame", symbol: "gamecontroller.fill", topColor: .systemPurple, bottomColor: .systemBlue),
    BuiltInIconSpec(name: "MacWinTerminal", symbol: "terminal.fill", topColor: .systemGray, bottomColor: .black),
    BuiltInIconSpec(name: "MacWinRegistry", symbol: "list.bullet.rectangle", topColor: .systemTeal, bottomColor: .systemBlue),
    BuiltInIconSpec(name: "MacWinLogs", symbol: "doc.text.magnifyingglass", topColor: .systemMint, bottomColor: .systemTeal),
    BuiltInIconSpec(name: "MacWinPDF", symbol: "doc.richtext.fill", topColor: .systemRed, bottomColor: .systemPink),
    BuiltInIconSpec(name: "MacWinDeveloper", symbol: "hammer.fill", topColor: .systemIndigo, bottomColor: .systemBlue),
    BuiltInIconSpec(name: "MacWinChat", symbol: "bubble.left.and.bubble.right.fill", topColor: .systemGreen, bottomColor: .systemTeal),
    BuiltInIconSpec(name: "MacWinCAD", symbol: "ruler.fill", topColor: .systemOrange, bottomColor: .systemBlue),
    BuiltInIconSpec(name: "MacWinDatabase", symbol: "cylinder.split.1x2.fill", topColor: .systemCyan, bottomColor: .systemIndigo),
    BuiltInIconSpec(name: "MacWinSecurity", symbol: "lock.shield.fill", topColor: .systemGreen, bottomColor: .systemBlue),
    BuiltInIconSpec(name: "MacWinDownload", symbol: "arrow.down.circle.fill", topColor: .systemBlue, bottomColor: .systemTeal),
    BuiltInIconSpec(name: "MacWinProductivity", symbol: "checkmark.circle.fill", topColor: .systemMint, bottomColor: .systemGreen)
]
for spec in builtInIcons {
    try writePNG(
        bitmap(size: 512) { drawBuiltInIcon(spec, in: $0) },
        to: builtInIconsDirectory.appendingPathComponent("\(spec.name).png")
    )
}

try writeICNS(
    to: iconsDirectory.appendingPathComponent("MacWinAppIcon.icns"),
    draw: drawAppIcon
)
try writeICNS(
    to: iconsDirectory.appendingPathComponent("MacWinExeDocument.icns"),
    draw: drawExeDocumentIcon
)
try writeICO(
    to: iconsDirectory.appendingPathComponent("MacWinAppIcon.ico"),
    draw: drawModernAppIconGlyph
)

print("Generated icons in \(iconsDirectory.path)")
