// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

/// Press feedback for every tappable surface: slight shrink + dim, 150ms.
struct GTPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// A row of cards at the largest ladder size that fits the width — big cards on
/// today's heads-up spots, graceful shrink when future spots put more cards in a row.
struct CardRow: View {
    let cards: [Card]
    var dead: Bool = false
    /// Caps the ladder. 첫 핸드 holds the hand and a per-beat diagram on one screen, so it
    /// trades card size for the room that diagram needs.
    var maxSize: CGFloat = 64
    private func row(_ size: CGFloat) -> some View {
        HStack(spacing: 8) {
            ForEach(Array(cards.enumerated()), id: \.offset) {
                PlayingCardView(card: $0.element, size: size, dead: dead)
            }
        }
    }
    var body: some View {
        ViewThatFits(in: .horizontal) {
            row(min(maxSize, 64)); row(min(maxSize, 56))
            row(min(maxSize, 48)); row(min(maxSize, 40))
        }
    }
}

struct SectionLabel: View {
    let text: String
    var onDark: Bool = true
    var body: some View {
        Text(text).font(GT.semibold(10)).tracking(0.4)
            .foregroundStyle(onDark ? GT.onFelt.opacity(0.62) : GT.inkMuted)
    }
}

extension GradeBand {
    var label: String {
        switch self { case .spotOn: return "정확"; case .close: return "근접"; case .off: return "빗나감" }
    }
    /// Three shapes, not three colors. WCAG 1.4.1: color can never be the only channel, and
    /// red/green is the worst possible pair for deuteranopia (~6% of men). ± reads as
    /// "off by a tolerance", which is what 근접 means — it is not a lesser ✓.
    var glyph: String {
        switch self {
        case .spotOn: return "checkmark.circle.fill"
        case .close:  return "plusminus.circle.fill"
        case .off:    return "xmark.circle.fill"
        }
    }
    /// Darkened from the original trio, which measured 3.08–4.17:1 on their own tints —
    /// all below AA. These are 4.95–5.12:1, so the verdict is legible at any size.
    var ink: Color {
        switch self {
        case .spotOn: return GTBand.spotOnInk
        case .close:  return GTBand.closeInk
        case .off:    return GTBand.offInk
        }
    }
    var tint: Color {
        switch self {
        case .spotOn: return GTBand.spotOnTint
        case .close:  return GTBand.closeTint
        case .off:    return GTBand.offTint
        }
    }
}

/// The verdict, at the top of every reveal. The old version put a small pill next to a flat
/// grey "내 답 X · 정답 Y", so the verdict never reached the numbers and both answers looked
/// identical. Four redundant channels now carry it:
///   1. **structure** — 정확 collapses to ONE number; a miss expands to 내 답 → 정답.
///      Readable even in greyscale, which no amount of color can claim.
///   2. **shape** — ✓ / ± / ✕
///   3. **text** — 정확 / 근접 / 빗나감, plus the gap named (`2 차이`)
///   4. **color** — additive only, never load-bearing.
/// Numbers stay near-black (14.9:1 on the tint) because the band inks only reach ~5:1.
struct VerdictRow: View {
    let band: GradeBand
    let mine: String
    let correct: String
    /// "2 차이" — how far off, so 근접 reads as a measured distance rather than a soft pass.
    var delta: String?

    init(band: GradeBand, mine: String, correct: String, delta: String? = nil) {
        self.band = band; self.mine = mine; self.correct = correct; self.delta = delta
    }
    /// Counts: the gap is computed here rather than at nine call sites.
    init(band: GradeBand, mine: Int, correct: Int, unit: String) {
        self.band = band
        self.mine = "\(mine)\(unit)"
        self.correct = "\(correct)\(unit)"
        self.delta = mine == correct ? nil : "\(abs(mine - correct)) 차이"
    }
    /// Percents: the gap between two percentages is percentage *points*, hence %p.
    init(band: GradeBand, minePct: Int, correctPct: Double) {
        self.band = band
        self.mine = "\(minePct)%"
        self.correct = "\(pctText(correctPct))%"
        let gap = abs(Double(minePct) - correctPct)
        self.delta = gap < 0.05 ? nil : "\(pctText(gap))%p 차이"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: band.glyph)
                .font(.system(size: 25, weight: .semibold))
                .foregroundStyle(band.ink)
                .symbolEffect(.bounce, options: .nonRepeating, value: band)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(band.label).font(GT.title(17)).foregroundStyle(band.ink)
                    if let delta {
                        Text(delta).font(GT.semibold(12)).foregroundStyle(band.ink.opacity(0.85))
                    }
                }
                answers
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(band.tint, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(band == .spotOn
            ? "\(band.label). 정답 \(correct), 내 답과 같아요."
            : "\(band.label). 내 답 \(mine), 정답 \(correct)."
              + (delta.map { " \($0)." } ?? ""))
    }

    /// Right answer: one value, nothing to compare. Wrong: the correction shown as a move
    /// from what you said to what's true, the truth carrying the weight.
    @ViewBuilder
    private var answers: some View {
        if band == .spotOn {
            Text("정답 \(correct)").font(GT.title(15)).foregroundStyle(GT.ink)
        } else {
            HStack(spacing: 6) {
                Text("내 답 \(mine)").font(GT.body(13)).foregroundStyle(GT.inkMuted)
                Image(systemName: "arrow.right").font(.system(size: 10, weight: .bold))
                    .foregroundStyle(GT.inkMuted)
                Text("정답 \(correct)").font(GT.title(15)).foregroundStyle(GT.ink)
            }
        }
    }
}

/// Board + the tapped river card, both finished hands, and who wins. Shared by the outs
/// reveal and 첫 핸드 on purpose: the first hand rehearses the affordance the drill uses.
struct RiverExplainPanel: View {
    let spot: OutsSpot
    let river: Card

    var body: some View {
        let ex = explainRiver(spot: spot, river: river)
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 6) {
                ForEach(Array(spot.board.enumerated()), id: \.offset) {
                    PlayingCardView(card: $0.element, size: 40)
                }
                Text("+").font(GT.title(16)).foregroundStyle(GT.onFelt.opacity(0.7))
                PlayingCardView(card: river, size: 40)
                    .overlay(RoundedRectangle(cornerRadius: 40 * 0.17)
                        .stroke(GT.mint, lineWidth: 2.5))
            }
            Text("내 핸드 · \(handName(ex.hero))").font(GT.title(14)).foregroundStyle(GT.onFelt)
            Text("상대 · \(handName(ex.villain))")
                .font(GT.semibold(13)).foregroundStyle(GT.onFelt.opacity(0.85))
            Text(ex.heroWins ? "→ 내가 이겨요" : "→ 완성해도 상대가 더 강해요")
                .font(GT.title(13))
                .foregroundStyle(Color(hex: ex.heroWins ? 0xA5F3CB : 0xFFB9B9))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GT.onFelt.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
    }
}

/// "용어 · 팟 오즈" — opens the glossary scrolled to one term, from inside a reveal.
/// Owns its own sheet state so a call site is one line.
struct GlossaryChip: View {
    let term: String
    @State private var open = false
    var body: some View {
        Button { open = true } label: {
            HStack(spacing: 4) {
                Image(systemName: "text.book.closed.fill").font(.system(size: 9.5))
                Text("용어 · \(term)").font(GT.semibold(11))
            }
            .foregroundStyle(GT.inkSecondary)
            .padding(.horizontal, 11).padding(.vertical, 6)
            .background(GT.surface, in: Capsule())
        }
        .buttonStyle(GTPress())
        .accessibilityLabel("용어집에서 \(term) 보기")
        .sheet(isPresented: $open) { GlossaryView(focus: term) }
    }
}

struct PrimaryCTAButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(GT.title(15)).foregroundStyle(GT.onCTA)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(GT.cta, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(GTPress())
    }
}

struct SecondaryCTAButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(GT.title(15)).foregroundStyle(GT.ink)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(GT.surface, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(GTPress())
    }
}

struct EstimateStepper: View {
    let value: Int
    var step: Int = 1
    var suffix: String = ""
    let onAdjust: (Int) -> Void
    private func key(_ s: String, _ d: Int) -> some View {
        Button { onAdjust(d) } label: {
            Text(s).font(GT.semibold(22)).foregroundStyle(GT.inkSecondary)
                .frame(width: 44, height: 44)
                .background(GT.surface, in: RoundedRectangle(cornerRadius: 13))
        }.buttonStyle(GTPress())
    }
    var body: some View {
        HStack(spacing: 12) {
            key("−", -step)
            Text("\(value)\(suffix)").font(GT.title(24).monospacedDigit()).foregroundStyle(GT.green)
                .frame(minWidth: 60, minHeight: 50)
                .background(GT.card, in: RoundedRectangle(cornerRadius: 13))
            key("+", step)
        }
    }
}
