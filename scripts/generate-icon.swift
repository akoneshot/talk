#!/usr/bin/env swift

import AppKit
import Foundation

// Icon design: waveform.circle SF Symbol style
func createIcon(pixelSize: Int) -> NSImage {
    let size = CGFloat(pixelSize)

    // Create bitmap at exact pixel size
    let rep = NSBitmapImageRep(
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
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let rect = CGRect(x: 0, y: 0, width: size, height: size)

    // Background - rounded square (standard macOS app icon shape)
    let cornerRadius = size * 0.22
    let bgPath = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.02, dy: size * 0.02),
                               xRadius: cornerRadius, yRadius: cornerRadius)

    // Gradient background (teal to blue - clean, modern)
    let gradient = NSGradient(colors: [
        NSColor(red: 0.0, green: 0.75, blue: 0.85, alpha: 1.0),  // Teal
        NSColor(red: 0.2, green: 0.5, blue: 0.95, alpha: 1.0)   // Blue
    ])!
    gradient.draw(in: bgPath, angle: -45)

    // Draw circle outline
    let circleInset = size * 0.15
    let innerCircleRect = rect.insetBy(dx: circleInset, dy: circleInset)
    let circlePath = NSBezierPath(ovalIn: innerCircleRect)
    circlePath.lineWidth = size * 0.04
    NSColor.white.withAlphaComponent(0.95).setStroke()
    circlePath.stroke()

    // Draw waveform bars inside the circle
    NSColor.white.setFill()

    let centerX = size / 2
    let centerY = size / 2
    let barWidth = size * 0.055
    let barSpacing = size * 0.09

    // Bar heights (symmetric waveform pattern)
    let heights: [CGFloat] = [0.12, 0.22, 0.32, 0.22, 0.12]
    let barCount = heights.count
    let totalWidth = CGFloat(barCount - 1) * barSpacing
    let startX = centerX - totalWidth / 2

    for (index, heightRatio) in heights.enumerated() {
        let barHeight = size * heightRatio
        let x = startX + CGFloat(index) * barSpacing - barWidth / 2
        let y = centerY - barHeight / 2

        let barRect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
        let barPath = NSBezierPath(roundedRect: barRect, xRadius: barWidth/2, yRadius: barWidth/2)
        barPath.fill()
    }

    NSGraphicsContext.restoreGraphicsState()

    let image = NSImage(size: NSSize(width: pixelSize, height: pixelSize))
    image.addRepresentation(rep)
    return image
}

func saveIcon(_ image: NSImage, to path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG for \(path)")
        return
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        print("Created: \(path)")
    } catch {
        print("Failed to write \(path): \(error)")
    }
}

// Main
let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

// macOS icon sizes - exact pixel dimensions
let sizes: [(pixels: Int, filename: String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

print("Generating Talk app icon (waveform.circle style)...")

for (pixels, filename) in sizes {
    let icon = createIcon(pixelSize: pixels)
    let path = "\(outputDir)/\(filename)"
    saveIcon(icon, to: path)
}

print("Done!")
