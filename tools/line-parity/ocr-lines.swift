// Prints every recognised text line in each screenshot as JSON (pixel boxes, top-left origin).
// Build: swiftc -O ocr-lines.swift -o .build-ocr-lines   Usage: ./.build-ocr-lines a.png b.png ...
import Foundation
import Vision
import AppKit

struct Line: Encodable { let text: String; let x: Double; let y: Double; let w: Double; let h: Double; let conf: Float }
struct Page: Encodable { let file: String; let width: Double; let height: Double; let lines: [Line] }

var pages: [Page] = []
for path in CommandLine.arguments.dropFirst() {
    guard let image = NSImage(contentsOfFile: path),
          let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { continue }
    let W = Double(cg.width), H = Double(cg.height)
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.recognitionLanguages = ["ko-KR", "en-US"]
    request.usesLanguageCorrection = false
    try VNImageRequestHandler(cgImage: cg).perform([request])
    let lines = (request.results ?? []).compactMap { obs -> Line? in
        guard let top = obs.topCandidates(1).first else { return nil }
        let b = obs.boundingBox
        return Line(text: top.string, x: b.minX * W, y: (1 - b.maxY) * H, w: b.width * W, h: b.height * H, conf: top.confidence)
    }
    pages.append(Page(file: path, width: W, height: H, lines: lines))
}
let encoder = JSONEncoder()
FileHandle.standardOutput.write(try encoder.encode(pages))
