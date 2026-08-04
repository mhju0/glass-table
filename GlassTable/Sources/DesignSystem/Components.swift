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
    /// Caps the ladder for callers that must leave room for something else.
    ///
    /// The top rung is sized so a five-card board still fits the narrowest supported
    /// screen: at 78pt a card is 78 × 0.72 ≈ 56pt wide, so five plus four 8pt gaps is
    /// ≈ 313pt against the 12 mini's 339pt of usable width. Everything larger than a
    /// mini simply gets the top rung, which is the point — cards read as cards.
    var maxSize: CGFloat = 78
    /// Cards to call out — the winning five on a reveal, say. Everything else steps
    /// back rather than disappearing, so the row still reads as a whole hand.
    var highlight: [Card] = []
    private func row(_ size: CGFloat) -> some View {
        HStack(spacing: 8) {
            ForEach(Array(cards.enumerated()), id: \.offset) { _, card in
                let lit = highlight.contains(card)
                let dim = !highlight.isEmpty && !lit
                PlayingCardView(card: card, size: size, dead: dead)
                    .overlay {
                        if lit {
                            RoundedRectangle(cornerRadius: size * 0.17)
                                .stroke(GT.mint, lineWidth: 3)
                                .shadow(color: GT.mint.opacity(0.85), radius: 9)
                        }
                    }
                    .scaleEffect(lit ? 1.06 : 1)
                    .opacity(dim ? 0.62 : 1)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: highlight)
            }
        }
    }
    var body: some View {
        ViewThatFits(in: .horizontal) {
            row(min(maxSize, 78)); row(min(maxSize, 68))
            row(min(maxSize, 58)); row(min(maxSize, 48))
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

// MARK: - surfaces and controls

/// The glass recipe, in one place: a green fill and an edge that reads as the lip of a
/// raised surface. No blur — `FeltBackground` is a flat fill, so the material was
/// paying for an offscreen pass to arrive at a solid tint (see `GT.glass`).
///
/// The edge is what separates the surface from the felt, so it is `borderStrong` and
/// not the quiet `border` it used to be — measured 1.19:1 for a card against the felt
/// in the old build, which is no boundary at all.
private struct GlassBackground<S: InsettableShape>: View {
    let shape: S
    var litEdge: Bool = true

    var body: some View {
        shape.fill(GT.glass)
            .overlay {
                shape.strokeBorder(litEdge ? GT.glassEdge : GT.borderStrong, lineWidth: 1)
            }
    }
}

extension View {
    /// An elevated glass surface on the felt. Separation comes from the material and
    /// the elevation — a blurred, lit, floating plane — not from a drawn line.
    func gtCard(radius: CGFloat = 20) -> some View {
        self.background {
            GlassBackground(shape: RoundedRectangle(cornerRadius: radius, style: .continuous),
                            litEdge: false)
                .shadow(color: .black.opacity(0.34), radius: 14, y: 6)
        }
    }
}

// MARK: - navigation chrome

/// The one nav-bar control, drawn by us rather than by the system.
///
/// Under iOS 26 a toolbar item is handed a Liquid Glass capsule whose material samples
/// whatever sits behind it. On a sheet that is the *outgoing* screen, so the button
/// visibly changes shade while the sheet settles — the flicker this replaces — and the
/// ring around it reads as a floating bubble rather than a control. A bare glyph has
/// no material to resolve, so there is nothing to settle.
///
/// Direction carries the meaning, which is why these are arrows and not words: ∨ puts
/// the sheet back down the way it came up, ‹ steps back one level inside it.
struct ChromeButton: View {
    let symbol: String
    /// Never rendered — the arrow is the label. Spoken by VoiceOver, which cannot see it.
    let spoken: String
    let action: () -> Void

    /// Dismisses the sheet. It rose from the bottom; it leaves the same way.
    static func close(_ action: @escaping () -> Void) -> ChromeButton {
        ChromeButton(symbol: "chevron.down", spoken: "닫기", action: action)
    }

    /// One level back, staying inside the sheet.
    static func back(_ spoken: String, _ action: @escaping () -> Void) -> ChromeButton {
        ChromeButton(symbol: "chevron.left", spoken: spoken, action: action)
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(GT.onFelt)
                // 44pt target: the glyph is small and the felt around it is not tappable.
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(GTPress())
        .accessibilityLabel(spoken)
    }
}

extension View {
    /// Every nav bar in the app: no background, and its item drawn by us.
    func gtChrome<V: View>(_ placement: ToolbarItemPlacement,
                           @ViewBuilder item: @escaping () -> V) -> some View {
        modifier(GTChrome(placement: placement, item: item))
    }
}

private struct GTChrome<V: View>: ViewModifier {
    let placement: ToolbarItemPlacement
    @ViewBuilder let item: () -> V

    func body(content: Content) -> some View {
        content
            .toolbar { bar }
            .toolbarBackground(.hidden, for: .navigationBar)
    }

    @ToolbarContentBuilder
    private var bar: some ToolbarContent {
        if #available(iOS 26.0, *) {
            ToolbarItem(placement: placement) { item() }
                .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: placement) { item() }
        }
    }
}

/// The bottom action sheet. Rounded at the top, **bleeding to the bottom edge**, with
/// a grabber so it reads as a sheet rather than a colour change.
struct ActionSheet<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(GT.ink.opacity(0.30))
                .frame(width: 36, height: 4)
                .padding(.bottom, 13)
                .accessibilityHidden(true)
            content()
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            GlassBackground(shape: UnevenRoundedRectangle(topLeadingRadius: 28,
                                                          topTrailingRadius: 28,
                                                          style: .continuous))
                .ignoresSafeArea(edges: .bottom)
        }
        .shadow(color: .black.opacity(0.55), radius: 22, y: -10)
    }
}

/// Primary action: mint fill, dark lettering. The one visually dominant control in
/// any sheet — three equal rectangles is what made the old answer sheets read flat.
struct PrimaryCTAButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(GT.title(16)).foregroundStyle(GT.onCTA)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(GT.cta, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .shadow(color: GT.mint.opacity(0.30), radius: 10, y: 4)
        }
        .buttonStyle(GTPress())
    }
}

struct SecondaryCTAButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(GT.semibold(15)).foregroundStyle(GT.inkSecondary)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(GT.surface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(GT.border, lineWidth: 1))
        }
        .buttonStyle(GTPress())
    }
}

/// Primary action sitting directly **on felt**, where there is no glass beneath it.
struct FeltCTAButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(GT.title(16)).foregroundStyle(GT.onCTA)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(GT.mint, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .shadow(color: GT.mint.opacity(0.28), radius: 12, y: 5)
        }
        .buttonStyle(GTPress())
    }
}

/// A choice in an answer sheet: translucent ivory on glass, with a selected state that
/// moves fill, border and weight together so it never leans on colour alone.
struct GTChoiceButton: View {
    let title: String
    var selected: Bool = false
    var minHeight: CGFloat = 54
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(selected ? GT.title(16) : GT.semibold(16))
                .foregroundStyle(selected ? GT.onCTA : GT.ink)
                .frame(maxWidth: .infinity, minHeight: minHeight)
                .background(selected ? AnyShapeStyle(GT.cta) : AnyShapeStyle(GT.surface),
                            in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(selected ? Color.clear : GT.borderStrong, lineWidth: 1))
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
            Text(s).font(GT.semibold(24)).foregroundStyle(GT.ink)
                .frame(width: 50, height: 50)
                .background(GT.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(GT.borderStrong, lineWidth: 1))
        }.buttonStyle(GTPress())
    }
    var body: some View {
        HStack(spacing: 14) {
            key("\u{2212}", -step)
            Text("\(value)\(suffix)").font(GT.title(26).monospacedDigit())
                .foregroundStyle(GT.ink)
                .frame(minWidth: 74, minHeight: 54)
                .contentTransition(.numericText())
            key("+", step)
        }
    }
}
