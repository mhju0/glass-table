// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

public struct OutsReveal: GradedReveal {
    public let band: GradeBand
    public let estimate: Int
    public let outs: [Card]
    public let excluded: [Card]
    public let improvementPct: Double
    public let whyText: String
}

/// Grade an out-count estimate against a spot. Bands: exact = 정확, ±2 = 근접, else = 빗나감.
public func gradeOuts(estimate: Int, spot: OutsSpot) -> OutsReveal {
    let band = gradeEstimate(user: Double(estimate), correct: Double(spot.outCount),
                             closeWithin: 2, spotOnWithin: 0)
    return OutsReveal(band: band, estimate: estimate, outs: spot.outs, excluded: spot.excluded,
                      improvementPct: spot.improvementPct, whyText: whyText(for: spot))
}

func whyText(for spot: OutsSpot) -> String {
    guard !spot.excluded.isEmpty else { return "\(spot.outCount) 아웃." }
    let ex = spot.excluded.map(\.description).joined(separator: "·")
    let apparent = spot.outCount + spot.excluded.count
    // Always-true reason: these cards complete the draw but hero still loses (the board
    // pairs villain up, villain out-flushes, etc.). Spot-specific reasoning is deferred.
    return "\(apparent) 아웃처럼 보이지만, \(ex)는 완성해도 상대가 더 강해 제외돼요. 진짜 아웃은 \(spot.outCount)장."
}
