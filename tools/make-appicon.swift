// Copyright (c) 2026 Michael Ju (github.com/mhju0)
// Renders the app icon: flat GT green, tilted white card, green percent glyph.
// Usage: swift tools/make-appicon.swift <output.png>
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let size = 1024.0
let green = CGColor(red: 0x15 / 255.0, green: 0x7A / 255.0, blue: 0x47 / 255.0, alpha: 1)

let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8,
                    bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

ctx.setFillColor(green)
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

// White card, slightly tilted around the canvas center.
let cardW = 560.0, cardH = 740.0
ctx.saveGState()
ctx.translateBy(x: size / 2, y: size / 2)
ctx.rotate(by: -8 * .pi / 180)
let card = CGRect(x: -cardW / 2, y: -cardH / 2, width: cardW, height: cardH)
ctx.addPath(CGPath(roundedRect: card, cornerWidth: 64, cornerHeight: 64, transform: nil))
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
ctx.fillPath()

// Percent glyph on the card: two ring circles + a rounded diagonal bar, in GT green.
ctx.setStrokeColor(green)
ctx.setLineWidth(52)
ctx.setLineCap(.round)
let r = 88.0, off = 150.0
ctx.strokeEllipse(in: CGRect(x: -off - r, y: off - r + 30, width: 2 * r, height: 2 * r))
ctx.strokeEllipse(in: CGRect(x: off - r, y: -off - r - 30, width: 2 * r, height: 2 * r))
ctx.move(to: CGPoint(x: -170, y: -240))
ctx.addLine(to: CGPoint(x: 170, y: 240))
ctx.strokePath()
ctx.restoreGState()

let image = ctx.makeImage()!
let out = URL(fileURLWithPath: CommandLine.arguments[1])
let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
assert(CGImageDestinationFinalize(dest), "PNG write failed")
print("wrote \(out.path)")
