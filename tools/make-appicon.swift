// Copyright (c) 2026 Michael Ju (github.com/mhju0)
// Renders the app icon: flat GT green, subtle "table" disc, white percent glyph.
// No cards/chips/suits — study-tool mark, weakest gambling signal for GRAC.
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

ctx.saveGState()
ctx.translateBy(x: size / 2, y: size / 2)

// The glass table: a barely-lighter disc behind the glyph.
let discR = 400.0
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.10))
ctx.fillEllipse(in: CGRect(x: -discR, y: -discR, width: 2 * discR, height: 2 * discR))

// Percent glyph: two ring circles + a rounded diagonal bar, in white.
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
ctx.setLineWidth(72)
ctx.setLineCap(.round)
let r = 118.0, off = 196.0
ctx.strokeEllipse(in: CGRect(x: -off - r, y: off - r, width: 2 * r, height: 2 * r))
ctx.strokeEllipse(in: CGRect(x: off - r, y: -off - r, width: 2 * r, height: 2 * r))
ctx.move(to: CGPoint(x: -222, y: -310))
ctx.addLine(to: CGPoint(x: 222, y: 310))
ctx.strokePath()
ctx.restoreGState()

let image = ctx.makeImage()!
let out = URL(fileURLWithPath: CommandLine.arguments[1])
let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
assert(CGImageDestinationFinalize(dest), "PNG write failed")
print("wrote \(out.path)")
