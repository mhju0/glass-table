// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// The priced pot as proportional segments — 팟, 상대 벳, and (for pot odds) 내 콜.
///
/// The bar is the lesson made visible: required equity *is* the 콜 segment's share of
/// the whole bar, so the price can be read as a proportion before it is computed as a
/// number. The segment colours are the M1 tokens (`GT.segPot/segBet/segCall`); 콜 is a
/// different hue because the
/// denominator is the term beginners miss, and it is drawn dashed because it is
/// hypothetical money — not in the middle yet.
struct PriceBarView: View {
    @Environment(\.learningLanguage) private var language
    struct Segment: Identifiable {
        let label: String
        let bb: Int
        let fill: Color
        var hypothetical = false
        var id: String { label }
    }

    let segments: [Segment]

    /// 팟 + 상대 벳, plus the hypothetical 콜 when `withCall` — the pot-odds shape.
    /// MDF's bar omits the call: its denominator is only what is already out there.
    static func priced(pot: Int, bet: Int, withCall: Bool) -> PriceBarView {
        var segs = [Segment(label: "팟", bb: pot, fill: GT.segPot),
                    Segment(label: "벳", bb: bet, fill: GT.segBet)]
        if withCall {
            segs.append(Segment(label: "콜", bb: bet, fill: GT.segCall, hypothetical: true))
        }
        return PriceBarView(segments: segs)
    }

    private var total: Double { Double(segments.reduce(0) { $0 + $1.bb }) }

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 3) {
                ForEach(segments) { seg in
                    segmentView(seg, width: max(44, geo.size.width * Double(seg.bb) / total))
                }
            }
        }
        .frame(height: 58)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(segments.map { "\(displayLabel($0.label)) \($0.bb) \(language.text("빅블라인드", "big blinds"))" }
            .joined(separator: ", "))
    }

    private func segmentView(_ seg: Segment, width: CGFloat) -> some View {
        VStack(spacing: 2) {
            Text(displayLabel(seg.label)).font(GT.semibold(11)).foregroundStyle(GT.onTable)
            Text("\(seg.bb)").font(GT.title(17).monospacedDigit()).foregroundStyle(GT.onTable)
        }
        .minimumScaleFactor(0.6)
        .frame(width: width, height: 58)
        .background(seg.fill,
                    in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            if seg.hypothetical {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(GT.onTable,
                                  style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            }
        }
    }

    private func displayLabel(_ value: String) -> String {
        switch value {
        case "팟": language.text("팟", "Pot")
        case "벳": language.text("벳", "Bet")
        case "콜": language.text("콜", "Call")
        default: value
        }
    }
}
