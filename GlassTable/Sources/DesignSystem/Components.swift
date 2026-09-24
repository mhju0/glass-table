// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

/// Immediate press feedback. Reduced Motion keeps the highlight and removes scale.
struct GTPress: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && isEnabled
        configuration.label
            .scaleEffect(pressed && !reduceMotion ? 0.98 : 1)
            .opacity(pressed ? 0.78 : 1)
            .animation(reduceMotion ? nil : GT.Motion.press, value: pressed)
    }
}

/// A row of cards at the app's canonical size. When a screen cannot fit the row,
/// its container reflows or scrolls instead of teaching a second card geometry.
struct CardRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let cards: [Card]
    var dead: Bool = false
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
                            RoundedRectangle(cornerRadius: PlayingCardView.cornerRadius(for: size))
                                .strokeBorder(GT.mint, lineWidth: 3)
                        }
                    }
                    .opacity(dim ? 0.62 : 1)
                    .animation(reduceMotion ? nil : GT.Motion.change, value: highlight)
            }
        }
    }
    var body: some View {
        row(PlayingCardView.canonicalSize)
    }
}

/// The stable reading order for a poker decision. Every region uses the same card
/// geometry; quiet rules separate ownership without turning the table into panels.
struct ThreeRegionCardTable: View {
    @Environment(\.learningLanguage) private var language
    let opponent: [Card]
    let board: [Card]
    let hero: [Card]
    var opponentTitle = "상대 카드"
    var heroTitle = "내 카드"
    var highlight: [Card] = []

    var body: some View {
        VStack(spacing: 0) {
            region(opponentTitle == "상대 카드" ? language.text("상대 카드", "Opponent's cards") : opponentTitle,
                   cards: opponent)
            boundary
            region(language.text("공용 카드", "Shared cards"), cards: board)
            boundary
            region(heroTitle == "내 카드" ? language.text("내 카드", "My cards") : heroTitle,
                   cards: hero)
        }
        .frame(maxWidth: .infinity)
    }

    private func region(_ title: String, cards: [Card]) -> some View {
        VStack(spacing: 9) {
            SectionLabel(text: title)
            CardRow(cards: cards, highlight: highlight)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(title == language.text("내 카드", "My cards")
                                 ? "three-region-hero-cards" : "card-region-\(title)")
    }

    private var boundary: some View {
        Rectangle().fill(GT.hairlineFelt).frame(height: 1)
            .padding(.horizontal, 10)
            .accessibilityHidden(true)
    }
}

struct SectionLabel: View {
    let text: String
    var onDark: Bool = true
    var body: some View {
        Text(text).font(GT.semibold(13)).tracking(0.3)
            .foregroundStyle(onDark ? GT.onFeltMuted : GT.inkMuted)
    }
}

extension GradeBand {
    func label(in language: LearningLanguage) -> String {
        switch self {
        case .spotOn: language.text("정확", "Exact")
        case .close: language.text("근접", "Close")
        case .off: language.text("다시 살펴볼까요?", "Review this one")
        }
    }
    var label: String {
        switch self {
        case .spotOn: return "정확"
        case .close: return "근접"
        case .off: return "다시 살펴볼까요?"
        }
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
    @Environment(\.learningLanguage) private var language
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
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(band.label(in: language)).font(GT.title(18)).foregroundStyle(band.ink)
                    if let delta {
                        Text(localizedDelta(delta)).font(GT.semibold(12)).foregroundStyle(band.ink.opacity(0.85))
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
            ? language.text("\(band.label). 정답 \(correct), 내 답과 같아요.",
                            "\(band.label(in: language)). Correct answer \(correct), same as my answer.")
            : language.text("\(band.label). 내 답 \(mine), 정답 \(correct).",
                            "\(band.label(in: language)). My answer \(mine), correct answer \(correct).")
              + (delta.map { " \(localizedDelta($0))." } ?? ""))
    }

    /// Right answer: one value, nothing to compare. Wrong: the correction shown as a move
    /// from what you said to what's true, the truth carrying the weight.
    @ViewBuilder
    private var answers: some View {
        if band == .spotOn {
            Text(language.text("정답 \(correct)", "Correct \(correct)"))
                .font(GT.title(15)).foregroundStyle(GT.ink)
        } else {
            HStack(spacing: 6) {
                Text(language.text("내 답 \(mine)", "My answer \(mine)"))
                    .font(GT.body(13)).foregroundStyle(GT.inkMuted)
                Image(systemName: "arrow.right").font(.system(size: 10, weight: .bold))
                    .foregroundStyle(GT.inkMuted)
                Text(language.text("정답 \(correct)", "Correct \(correct)"))
                    .font(GT.title(15)).foregroundStyle(GT.ink)
            }
        }
    }

    private func localizedDelta(_ value: String) -> String {
        guard language == .english else { return value }
        if value.hasSuffix("%p 차이") {
            return value.replacingOccurrences(of: "%p 차이", with: " percentage points apart")
        }
        if value.hasSuffix(" 차이") {
            return value.replacingOccurrences(of: " 차이", with: " apart")
        }
        return value
    }
}

/// Board + the tapped river card, both finished hands, and who wins. Shared by the outs
/// reveal and 첫 핸드 on purpose: the first hand rehearses the affordance the drill uses.
struct RiverExplainPanel: View {
    @Environment(\.learningLanguage) private var language
    let spot: OutsSpot
    let river: Card

    var body: some View {
        let ex = explainRiver(spot: spot, river: river)
        VStack(alignment: .leading, spacing: 9) {
            CardRow(cards: spot.board)
            HStack(spacing: 10) {
                SectionLabel(text: language.text("리버", "Final card"))
                PlayingCardView(card: river)
                    .overlay(RoundedRectangle(cornerRadius: PlayingCardView.cornerRadius(for: PlayingCardView.canonicalSize))
                        .strokeBorder(GT.mint, lineWidth: 2.5))
            }
            Text("\(language.text("내 핸드", "My hand")) · \(DrillTerms.hand(ex.hero, in: language))")
                .font(GT.title(14)).foregroundStyle(GT.onFelt)
            Text("\(language.text("상대", "Opponent")) · \(DrillTerms.hand(ex.villain, in: language))")
                .font(GT.semibold(13)).foregroundStyle(GT.onFelt.opacity(0.85))
            Text(ex.heroWins ? language.text("내가 이겨요", "My hand wins")
                             : language.text("완성해도 상대가 더 강해요", "The opponent still wins"))
                .font(GT.title(13))
                .foregroundStyle(ex.heroWins ? GTBand.spotOnInk : GTBand.offInk)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GT.onFelt.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
    }
}

/// "용어 · 팟 오즈" — opens the glossary scrolled to one term, from inside a reveal.
/// Owns its own sheet state so a call site is one line.
struct GlossaryChip: View {
    @Environment(\.learningLanguage) private var language
    let term: String
    @State private var open = false
    var body: some View {
        Button { open = true } label: {
            HStack(spacing: 4) {
                Image(systemName: "text.book.closed.fill").font(.system(size: 9.5))
                Text("\(language.text("용어", "Term")) · \(GlossaryView.displayName(for: term, language: language))")
                    .font(GT.semibold(11))
            }
            .foregroundStyle(GT.inkSecondary)
            .padding(.horizontal, 11).padding(.vertical, 6)
            .background(GT.surface, in: Capsule())
            // The capsule stays chip-sized; the tap target meets the 44pt floor.
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(GTPress())
        .accessibilityLabel(language.text("용어집에서 \(term) 보기",
                                          "Open glossary entry for \(GlossaryView.displayName(for: term, language: language))"))
        .sheet(isPresented: $open) { GlossaryView(focus: term) }
    }
}

// MARK: - surfaces and controls

/// Opaque panels use an explicit boundary so grouping survives either appearance.
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
    /// A grouped surface. The border supplies separation without dark shadows
    /// accumulating between panels in the light appearance.
    func gtCard(radius: CGFloat = 20) -> some View {
        self.background {
            GlassBackground(shape: RoundedRectangle(cornerRadius: radius, style: .continuous),
                            litEdge: false)
        }
    }

    /// A card that takes a graded verdict's tint and outline once there is one.
    @ViewBuilder
    func gtCard(radius: CGFloat, band: GradeBand?) -> some View {
        if let band {
            let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
            background(band.tint, in: shape)
                .overlay(shape.strokeBorder(band.ink, lineWidth: 2))
        } else {
            gtCard(radius: radius)
        }
    }


    /// A quiet grouping directly on felt. Use it for supporting information that does
    /// not need to compete with the current task as an elevated card.
    func gtPanel(radius: CGFloat = GT.Radius.panel) -> some View {
        background(GT.onFelt.opacity(0.08),
                   in: RoundedRectangle(cornerRadius: radius, style: .continuous))
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
    @Environment(\.learningLanguage) private var language
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
        .accessibilityLabel(spoken == "닫기" ? language.text("닫기", "Close") : spoken)
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
    /// A graded result tints the whole sheet and outlines its top edge, so right and
    /// wrong read at a glance; the verdict's glyph and words still carry the meaning.
    var band: GradeBand? = nil
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
            let shape = UnevenRoundedRectangle(topLeadingRadius: GT.Radius.sheet,
                                               topTrailingRadius: GT.Radius.sheet,
                                               style: .continuous)
            if let band {
                shape.fill(band.tint)
                    .overlay(shape.stroke(band.ink, lineWidth: 2))
                    .ignoresSafeArea(edges: .bottom)
            } else {
                GlassBackground(shape: shape)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

/// Primary action: mint fill, dark lettering. The one visually dominant control in
/// any sheet — three equal rectangles is what made the old answer sheets read flat.
struct PrimaryCTAButton: View {
    @Environment(\.isEnabled) private var isEnabled
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(GT.title(GT.Typography.buttonSize))
                .foregroundStyle(isEnabled ? GT.onCTA : GT.inkMuted)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(isEnabled ? GT.cta : GT.surface,
                            in: RoundedRectangle(cornerRadius: GT.Radius.control,
                                                 style: .continuous))
        }
        .buttonStyle(GTPress())
    }
}

struct SecondaryCTAButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(GT.semibold(GT.Typography.buttonSize)).foregroundStyle(GT.inkSecondary)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(GT.surface, in: RoundedRectangle(cornerRadius: GT.Radius.control,
                                                            style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
                    .strokeBorder(GT.border, lineWidth: 1))
        }
        .buttonStyle(GTPress())
    }
}

/// Primary action sitting directly **on felt**, where there is no glass beneath it.
struct FeltCTAButton: View {
    @Environment(\.isEnabled) private var isEnabled
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(GT.title(GT.Typography.buttonSize))
                .foregroundStyle(isEnabled ? GT.onCTA : GT.inkMuted)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(isEnabled ? GT.cta : GT.surface,
                            in: RoundedRectangle(cornerRadius: GT.Radius.control,
                                                 style: .continuous))
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
                .font(selected ? GT.title(GT.Typography.buttonSize)
                               : GT.semibold(GT.Typography.buttonSize))
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

/// Clearance for the floating tab bar, for a tab's scrolling content.
///
/// The bar does **not** hand its tab an inset — verified by deleting the padding and
/// watching 기록's concept list run off the bottom edge — so the clearance has to be
/// supplied. It was three copies of `.padding(.bottom, 96)`, one per tab, which is
/// three places to miss when the bar changes.
///
/// Two things it fixes beyond the duplication. As a `safeAreaInset` rather than trailing
/// padding it also insets the scroll indicator, so the bar stops covering the end of the
/// scroll track. And `@ScaledMetric` grows the gap with the user's text size, which is
/// what the bar's own labels do — at the accessibility sizes the fixed 96 left the last
/// row tucked under it.
private struct TabBarClearance: ViewModifier {
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = 96

    init(height: CGFloat) {
        _height = ScaledMetric(wrappedValue: height, relativeTo: .body)
    }
    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: height).allowsHitTesting(false)
        }
    }
}

extension View {
    func gtTabBarClearance(_ height: CGFloat = 96) -> some View {
        modifier(TabBarClearance(height: height))
    }
}

/// What class of action a table button commits to — never *which one is better*.
///
/// `GTChoiceButton` deliberately renders every drill answer identically so the sheet
/// cannot leak the grade, and the table is graded the same way. So these roles change
/// one thing only: the hue of the rule under the price, carrying the meaning the price
/// bar already assigns to that money. 폴드 puts nothing in the middle, so it has no
/// segment and gets the neutral edge.
enum GTActionRole {
    case fold, passive, aggressive

    var accent: Color {
        switch self {
        case .fold:       return GT.borderStrong
        case .passive:    return GT.actionCall
        case .aggressive: return GT.actionBet
        }
    }
}

/// A priced action at the table: what it is, over what it costs.
///
/// The old row was one string per button — "폴드" / "콜 5.6bb" / "레이즈 16.9bb" at one
/// weight — so three different commitments read as three rows of text and the price had
/// to be parsed out of a sentence. Splitting it puts the numbers in a column the eye can
/// compare, which is the comparison the decision actually turns on.
struct GTActionButton: View {
    let title: String
    /// Always present, 폴드 included: "0bb" is the fact that makes the EV comparison on
    /// the next screen legible, and an empty slot here would break the column.
    let price: String
    let role: GTActionRole
    var minHeight: CGFloat = 56
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // The accent is laid out, not overlaid. As an overlay it took no part in
            // sizing, so at the accessibility text sizes it painted straight over the
            // price line while the button kept its compact height.
            VStack(spacing: 3) {
                Text(title).font(GT.semibold(12)).foregroundStyle(GT.inkSecondary)
                    .lineLimit(1).minimumScaleFactor(0.6)
                Text(price).font(GT.title(15).monospacedDigit()).foregroundStyle(GT.ink)
                    .lineLimit(1).minimumScaleFactor(0.6)
                Capsule().fill(role.accent)
                    .frame(height: 3).padding(.horizontal, 8).padding(.top, 1)
            }
            .padding(.horizontal, 6).padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .background(GT.surface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(GT.borderStrong, lineWidth: 1))
        }
        .buttonStyle(GTPress())
        .accessibilityLabel("\(title), \(price)")
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

/// Visible tap controls beside a slider. They are a full alternative input path,
/// while the slider remains useful for quickly exploring a large numeric range.
struct AdjustmentButtons: View {
    let label: String
    let decrement: () -> Void
    let increment: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            key("minus", spoken: "\(label) 줄이기", action: decrement)
            key("plus", spoken: "\(label) 늘리기", action: increment)
        }
    }

    private func key(_ symbol: String, spoken: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 15, weight: .semibold))
                .foregroundStyle(GT.ink)
                .frame(width: 44, height: 44)
                .background(GT.surface, in: RoundedRectangle(cornerRadius: GT.Radius.control,
                                                             style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
                    .strokeBorder(GT.borderStrong, lineWidth: 1))
        }
        .buttonStyle(GTPress()).accessibilityLabel(spoken)
    }
}
