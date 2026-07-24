// Copyright (c) 2026 Michael Ju (github.com/mhju0)
// Renders the app icon: felt-gradient background, 4x4 equity-heatmap range grid,
// suit tiles on the pair diagonal in official order (spade, heart, diamond, club)
// in card colors. Suits were a deliberate owner choice (2026-07-24); the rating
// answers already declare mild simulated gambling, so the tier is unaffected.
// Usage: swift tools/make-appicon.swift <output.png>
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let S = 1024.0

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}
let ink = rgb(0x191F28)      // GT.ink
let suitRed = rgb(0xE5484D)  // GT.suitRed

let ctx = CGContext(data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8,
                    bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

// FeltBackground gradient: 0x1B8A52 -> 0x157A47 -> 0x0E5A34, top to bottom.
let grad = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                      colors: [rgb(0x1B8A52), rgb(0x157A47), rgb(0x0E5A34)] as CFArray,
                      locations: [0, 0.5, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: S), end: CGPoint(x: 0, y: 0), options: [])

func drawText(_ str: String, _ f: CTFont, _ color: CGColor, center: CGPoint) {
    let attr = NSAttributedString(string: str, attributes: [
        kCTFontAttributeName as NSAttributedString.Key: f,
        kCTForegroundColorAttributeName as NSAttributedString.Key: color,
    ])
    let line = CTLineCreateWithAttributedString(attr)
    ctx.saveGState()
    ctx.textPosition = .zero
    let b = CTLineGetImageBounds(line, ctx)
    ctx.textPosition = CGPoint(x: center.x - b.midX, y: center.y - b.midY)
    CTLineDraw(line, ctx)
    ctx.restoreGState()
}

// Official suit order, card colors: black suits ink, red suits red.
let suits: [(String, CGColor)] = [
    ("\u{2660}", ink), ("\u{2665}", suitRed), ("\u{2666}", suitRed), ("\u{2663}", ink),
]

let n = 4, span = 760.0
let gap = span * 0.028
let cell = (span - gap * Double(n - 1)) / Double(n)
let origin = (S - span) / 2
let radius = cell * 0.24
for row in 0..<n {
    for col in 0..<n {
        let x = origin + Double(col) * (cell + gap)
        let y = S - origin - cell - Double(row) * (cell + gap)
        let rect = CGRect(x: x, y: y, width: cell, height: cell)
        // Heatmap: brightness falls off from the AA corner. Suit tiles on the
        // diagonal follow the same falloff, one notch brighter, so they blend
        // into the gradient instead of popping out as solid white.
        let d = Double(row + col) / Double(2 * (n - 1))
        let heat = 1.0 - d * 0.92
        let alpha: CGFloat = row == col ? min(1, heat + 0.20) : heat
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: alpha))
        ctx.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
        ctx.fillPath()
        if row == col {
            let (glyph, color) = suits[row]
            drawText(glyph, CTFontCreateWithName("ArialUnicodeMS" as CFString, cell * 0.78, nil),
                     color, center: CGPoint(x: rect.midX, y: rect.midY + cell * 0.02))
        }
    }
}

let image = ctx.makeImage()!
let out = URL(fileURLWithPath: CommandLine.arguments[1])
let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
assert(CGImageDestinationFinalize(dest), "PNG write failed")
print("wrote \(out.path)")
