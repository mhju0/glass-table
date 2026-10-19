// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

/// Immediate press feedback. Reduced Motion keeps the highlight and removes scale.
struct GTPress: ButtonStyle {
    var pressedScale: CGFloat = 0.98
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && isEnabled
        configuration.label
            .scaleEffect(pressed && !reduceMotion ? pressedScale : 1)
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
    /// Both hands share one row above the board. Three stacked regions push the
    /// learner's own cards under a tall answer panel on a small phone.
    var sideBySide = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let opponentRegion = region(opponentTitle == "상대 카드" ? language.text("상대 카드", "Opponent's cards") : opponentTitle,
                                    cards: opponent.sorted(by: BeatScript.byRank))
        let heroRegion = region(heroTitle == "내 카드" ? language.text("내 카드", "My cards") : heroTitle,
                                cards: hero.sorted(by: BeatScript.byRank))
        return VStack(spacing: 0) {
            if sideBySide && !typeSize.isAccessibilitySize {
                HStack(alignment: .top, spacing: 12) { heroRegion; opponentRegion }
                boundary
                region(language.text("공용 카드", "Shared cards"), cards: board)
            } else {
                opponentRegion
                boundary
                region(language.text("공용 카드", "Shared cards"), cards: board)
                boundary
                heroRegion
            }
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
    /// Wording for drills graded against a chart or an EV rather than a right answer
    /// ("차트와 일치해요", "내 선택 → 차트"). The shape stays the same everywhere.
    var title: String?
    var mineTitle: String?
    var correctTitle: String?

    init(band: GradeBand, mine: String, correct: String, delta: String? = nil,
         title: String? = nil, mineTitle: String? = nil, correctTitle: String? = nil) {
        self.band = band; self.mine = mine; self.correct = correct; self.delta = delta
        self.title = title; self.mineTitle = mineTitle; self.correctTitle = correctTitle
    }

    private var heading: String { title ?? band.label(in: language) }
    private var mineName: String { mineTitle ?? language.text("선택한 답", "Your answer") }
    private var correctName: String { correctTitle ?? language.text("정답", "Correct answer") }
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
                    Text(heading).font(GT.title(18)).foregroundStyle(band.ink)
                    if let delta {
                        Text(localizedDelta(delta)).font(GT.semibold(12)).foregroundStyle(band.ink.opacity(0.85))
                    }
                }
                answers
            }
            Spacer(minLength: 0)
        }
        .gtInset(GT.Space.card, firstText: .title(18))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(band.tint, in: RoundedRectangle(cornerRadius: GT.Radius.panel))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(band == .spotOn
            ? "\(heading). \(correct)."
            : "\(heading). \(mineName): \(mine). \(correctName): \(correct)."
                + (delta.map { " \(localizedDelta($0))." } ?? ""))
    }

    @ViewBuilder
    private var answers: some View {
        if band == .spotOn {
            Text(correct)
                .font(GT.title(17)).foregroundStyle(GT.ink)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                answerField(label: mineName, value: mine, emphasized: false)
                Divider().overlay(GT.border)
                answerField(label: correctName, value: correct, emphasized: true)
            }
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func answerField(label: String, value: String, emphasized: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(GT.body(13)).foregroundStyle(GT.inkMuted)
            Text(value).font(GT.semibold(17)).foregroundStyle(emphasized ? GT.ink : GT.inkSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
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

/// Opens a general definition without passing the current question or answer.
struct GlossaryChip: View {
    @Environment(\.learningLanguage) private var language
    let term: String
    @State private var open = false
    private var name: String { GlossaryView.displayName(for: term, language: language) }
    private var otherName: String {
        GlossaryView.displayName(for: term, language: language == .korean ? .english : .korean)
    }
    var body: some View {
        Button { open = true } label: {
            HStack(spacing: 4) {
                Image(systemName: "text.book.closed.fill").font(.system(size: 9.5))
                Text("\(language.text("용어", "Term")) · \(name) (\(otherName))")
                    .font(GT.semibold(11))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(GT.inkSecondary)
            .padding(.horizontal, 11).padding(.vertical, 6)
            .background(GT.surface, in: Capsule())
            // The capsule stays chip-sized; the tap target meets the 44pt floor.
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(GTPress())
        .accessibilityLabel(language.text("용어집에서 \(name) (\(otherName)) 보기",
                                          "Open glossary entry for \(name) (\(otherName))"))
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
    func gtCard(radius: CGFloat = GT.Radius.panel) -> some View {
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


    /// A box inside a verdict: white, edged in the verdict's colour when it explains
    /// the answer, so the reason stands out from the tinted panel around it.
    func gtExplanation(band: GradeBand? = nil) -> some View {
        let shape = RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
        return background(GT.glass, in: shape)
            .overlay(shape.strokeBorder(band?.ink ?? GT.borderStrong, lineWidth: band == nil ? 1 : 1.5))
    }

    /// A quiet grouping directly on felt. Use it for supporting information that does
    /// not need to compete with the current task as an elevated card.
    func gtPanel(radius: CGFloat = GT.Radius.panel) -> some View {
        background(GT.onFelt.opacity(0.08),
                   in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    /// Pads content so the visible gap above its first line equals the gap beside it.
    /// Use `GT.Space.card` inside a card and `GT.Space.sheet` inside a sheet.
    func gtInset(_ inset: CGFloat, firstText: GT.TextRole? = .semibold(13)) -> some View {
        modifier(GTInkInset(inset: inset, firstText: firstText))
    }
}

private struct GTInkInset: ViewModifier {
    @Environment(\.learningLanguage) private var language
    let inset: CGFloat
    let firstText: GT.TextRole?
    @ScaledMetric private var textSize: CGFloat

    init(inset: CGFloat, firstText: GT.TextRole?) {
        self.inset = inset
        self.firstText = firstText
        _textSize = ScaledMetric(wrappedValue: firstText?.size ?? 1, relativeTo: firstText?.style ?? .body)
    }

    func body(content: Content) -> some View {
        let leading = firstText.map { $0.inkLeading(in: language) * textSize / $0.size } ?? 0
        content.padding(.horizontal, inset)
            .padding(.top, max(0, inset - leading))
            .padding(.bottom, inset)
    }
}

struct GTDockControlBackground: View {
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
        shape.fill(GT.surface).overlay(shape.strokeBorder(GT.borderStrong, lineWidth: 1))
    }
}

// MARK: - navigation chrome

/// What a screen sits on. A page runs to the screen edge; a sheet has a rounded top
/// corner to clear, so its content and its close control sit further in.
enum GTSurface {
    case page, sheet

    /// The content edge, and the distance from the top and side to the close control.
    var inset: CGFloat { self == .page ? GT.Space.edge : GT.Space.sheet }
}

private struct GTSurfaceKey: EnvironmentKey { static let defaultValue = GTSurface.page }
private struct ChromeEdgeKey: EnvironmentKey { static let defaultValue = HorizontalEdge.leading }

extension EnvironmentValues {
    var gtSurface: GTSurface {
        get { self[GTSurfaceKey.self] }
        set { self[GTSurfaceKey.self] = newValue }
    }

    fileprivate var chromeEdge: HorizontalEdge {
        get { self[ChromeEdgeKey.self] }
        set { self[ChromeEdgeKey.self] = newValue }
    }
}

extension View {
    /// Marks the content of a `.sheet`, so its chrome and content edge clear the corner.
    func gtSheetSurface() -> some View { environment(\.gtSurface, .sheet) }

    /// Side and bottom padding for content under a `gtChrome` bar: the surface's edge.
    /// No top padding — the bar already leaves the gap under its controls.
    func gtContentEdge() -> some View { modifier(GTContentEdge()) }
}

private struct GTContentEdge: ViewModifier {
    @Environment(\.gtSurface) private var surface
    func body(content: Content) -> some View {
        content.padding(.horizontal, surface.inset).padding(.bottom, surface.inset)
    }
}

/// The outlined tile small controls sit on: the secondary button's fill and border, so a
/// control reads as one before it is tapped. Gold stays with the main action.
struct GTControlBackground: View {
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
        shape.fill(GT.surface).overlay(shape.strokeBorder(GT.border, lineWidth: 1))
    }
}

/// A small text action on the outlined tile: 40pt drawn, 44pt tappable. For actions that
/// were once bare text, so they read as controls before they are tapped.
struct GTOutlinedAction: ButtonStyle {
    /// Stretches the tile across the row.
    var fills = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && isEnabled
        configuration.label.gtOutlinedLabel(fills: fills)
            .scaleEffect(pressed && !reduceMotion ? 0.98 : 1)
            .opacity(pressed ? 0.78 : isEnabled ? 1 : 0.5)
            .animation(reduceMotion ? nil : GT.Motion.press, value: pressed)
    }
}

extension View {
    /// The outlined tile for a label the system draws itself, such as a `Link`.
    func gtOutlinedLabel(fills: Bool = false) -> some View {
        font(GT.semibold(14)).foregroundStyle(GT.inkSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .frame(maxWidth: fills ? .infinity : nil, minHeight: ChromeGlyph.tile)
            .background { GTControlBackground() }
            .frame(minHeight: ChromeGlyph.tile + 2 * ChromeGlyph.reach)
            .contentShape(Rectangle())
    }
}

/// A top-bar glyph on its tile: 40pt drawn, 44pt tappable, the tile's outer edge on the
/// content edge. Also the label of a top-bar `Menu`.
struct ChromeGlyph: View {
    @Environment(\.chromeEdge) private var edge
    let symbol: String

    /// The drawn tile, and how far the tap target reaches past it on each side.
    static let tile: CGFloat = 40
    static let reach: CGFloat = 2

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(GT.onFelt)
            .frame(width: Self.tile, height: Self.tile)
            .background { GTControlBackground() }
            .frame(width: Self.tile + 2 * Self.reach, height: Self.tile + 2 * Self.reach)
            .contentShape(Rectangle())
            // The target reaches past the content edge; the tile stays on it.
            .padding(edge == .leading ? .leading : .trailing, -Self.reach)
    }
}

/// The one top-bar control, drawn by us rather than by the system.
///
/// Under iOS 26 a toolbar item is handed a Liquid Glass capsule whose material samples
/// whatever sits behind it. On a sheet that is the *outgoing* screen, so the button
/// visibly changes shade while the sheet settles. Our tile is a flat fill with no
/// material to resolve.
///
/// The leading control leaves the screen: Close dismisses it, Back returns to the screen
/// that pushed it. Stepping back inside a flow is a Previous button beside Next.
struct ChromeButton: View {
    @Environment(\.learningLanguage) private var language
    let symbol: String
    /// Never rendered — the glyph is the label. Spoken by VoiceOver, which cannot see it.
    let spoken: String
    let action: () -> Void

    /// Dismisses the sheet. It rose from the bottom; it leaves the same way.
    static func close(_ action: @escaping () -> Void) -> ChromeButton {
        ChromeButton(symbol: "xmark", spoken: "닫기", action: action)
    }

    /// Back to the screen that pushed this one.
    static func back(_ spoken: String, _ action: @escaping () -> Void) -> ChromeButton {
        ChromeButton(symbol: "chevron.left", spoken: spoken, action: action)
    }

    var body: some View {
        Button(action: action) { ChromeGlyph(symbol: symbol) }
            .buttonStyle(GTPress())
            .accessibilityLabel(spoken == "닫기" ? language.text("닫기", "Close") : spoken)
    }
}

/// A top-bar action that is a decision rather than a direction, so it stays a word.
struct ChromeTextButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action).buttonStyle(GTOutlinedAction())
    }
}

/// The top bar: its tiles sit on the content edge, and the content starts a short gap
/// under them.
struct GTChromeBar<Leading: View, Trailing: View>: View {
    @Environment(\.gtSurface) private var surface
    let leading: Leading
    let trailing: Trailing

    /// Space between a tile and the content under it.
    static var gap: CGFloat { 8 }

    var body: some View {
        HStack(spacing: 8) {
            leading.environment(\.chromeEdge, .leading)
            Spacer(minLength: 0)
            trailing.environment(\.chromeEdge, .trailing)
        }
        .padding(.horizontal, surface.inset)
        // A page's bar sits under the status bar; a sheet has only its own top edge.
        .padding(.top, surface == .page ? 0 : 10)
        .padding(.bottom, Self.gap - ChromeGlyph.reach)
    }
}

extension View {
    /// Every screen's top bar: no system bar, our controls on the content edge.
    func gtChrome<L: View, T: View>(@ViewBuilder leading: () -> L,
                                    @ViewBuilder trailing: () -> T) -> some View {
        modifier(GTChrome(bar: GTChromeBar(leading: leading(), trailing: trailing())))
    }

    func gtChrome<L: View>(@ViewBuilder leading: () -> L) -> some View {
        gtChrome(leading: leading, trailing: { EmptyView() })
    }

    func gtChrome<T: View>(@ViewBuilder trailing: () -> T) -> some View {
        gtChrome(leading: { EmptyView() }, trailing: trailing)
    }
}

private struct GTChrome<L: View, T: View>: ViewModifier {
    let bar: GTChromeBar<L, T>

    func body(content: Content) -> some View {
        // Content scrolls under a strip of page ground rather than under the system's
        // scroll-edge fade: the fade reaches past the bar and would wash out the title
        // that now starts right under the chevron.
        content
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                bar.background(alignment: .top) { GT.felt.ignoresSafeArea(edges: .top) }
            }
    }
}

/// The bottom action sheet, shaped like the system's own sheets on the running iOS.
///
/// iOS 26 floats a partial-height sheet: inset from the screen edges. Its corners and
/// its buttons' corners are the fixed control radius on every phone, never the display's
/// curve. Earlier systems attach it to the bottom edge with only the top corners rounded. The app's real `.sheet`s already follow the system, so this
/// one does too. At the accessibility sizes the sheet grows toward full height, where
/// iOS 26 also goes edge to edge, so it attaches there as well.
///
/// Only a graded sheet can fold, so only it shows a grabber; a grabber on a sheet that
/// cannot move promises a drag that does nothing.
private struct GTDockTopInset: ViewModifier {
    @Environment(\.learningLanguage) private var language
    let graded: Bool
    let firstText: GT.TextRole?
    @ScaledMetric private var textSize: CGFloat
    init(firstText: GT.TextRole?, graded: Bool) {
        self.graded = graded
        self.firstText = firstText
        _textSize = ScaledMetric(wrappedValue: firstText?.size ?? 1, relativeTo: firstText?.style ?? .body)
    }
    func body(content: Content) -> some View {
        let leading = firstText.map { $0.inkLeading(in: language) * textSize / $0.size } ?? 0
        content.padding(.top, graded ? 2 : max(0, GT.Space.sheet - leading))
    }
}

struct ActionSheet<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.learningLanguage) private var language
    @Environment(\.homeIndicatorInset) private var indicator
    /// A graded result tints the whole sheet and outlines its edge, so right and
    /// wrong read at a glance; the verdict's glyph and words still carry the meaning.
    var band: GradeBand? = nil
    /// False where the sheet holds the answer buttons themselves and has nothing to fold.
    var collapsible = true
    /// Folds as soon as a result arrives instead of waiting for the learner to fold it.
    var foldsOnReveal = false
    var firstText: GT.TextRole? = .title(18)
    @ViewBuilder var content: () -> Content
    /// A graded sheet folds down to its verdict and Next, so evidence the reveal added
    /// above it can be read without scrolling past the sheet.
    @State private var collapsed = false
    /// The home-indicator inset under the sheet, 0 on a Home-button phone.
    @State private var bottomInset: CGFloat = 0

    /// The gap between a floating sheet and the screen edges.
    private static var margin: CGFloat { 8 }

    /// How far a floating card reaches into the inset below it: all of it when that is
    /// the home indicator alone. A tab bar below the sheet adds its height to the inset,
    /// and the card then floats above the bar instead of sliding under it.
    private var reach: CGFloat {
        bottomInset <= indicator + 0.5 ? bottomInset : 0
    }

    private var folds: Bool { band != nil && collapsible }

    private var floats: Bool {
        if #available(iOS 26.0, *) { return !dynamicTypeSize.isAccessibilitySize }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            if folds { grabber }
            content()
                .environment(\.revealCollapsed, folds && collapsed)
        }
        .modifier(GTDockTopInset(firstText: firstText, graded: folds))
        .padding(.horizontal, GT.Space.sheet)
        .padding(.bottom, GT.Space.sheet)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { sheetBackground }
        .padding(.horizontal, floats ? Self.margin : 0)
        // A floating card reaches into the home-indicator inset the way system sheets do,
        // ending one margin above the screen edge; its inner padding keeps the content
        // clear of the indicator. `ignoresSafeArea` cannot do this from inside the
        // screens' stacks, so the inset is measured and padded away.
        .padding(.bottom, floats ? Self.margin - reach : -reach)
        .background {
            Color.clear
                .ignoresSafeArea(edges: .bottom)
                // Rounded: the inset jitters in its last bits as the sheet moves, and each
                // jitter would lay the sheet out again, forever.
                .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.bottom.rounded() } action: {
                    bottomInset = $0
                }
        }
        .simultaneousGesture(DragGesture(minimumDistance: 16).onEnded { value in
            guard folds else { return }
            if value.translation.height > 30 { setCollapsed(true) }
            if value.translation.height < -30 { setCollapsed(false) }
        })
        .onChange(of: band) { oldBand, newBand in
            if newBand == nil { collapsed = false }
            if oldBand == nil, newBand != nil, foldsOnReveal { collapsed = true }
        }
    }

    @ViewBuilder
    private var sheetBackground: some View {
        if #available(iOS 26.0, *), floats {
            // The floating card's bottom corners follow the display's rounded corners
            // (concentric, as system sheets do); a fixed small radius cut into the curve.
            let shape = ConcentricRectangle(uniformTopCorners: .fixed(GT.Radius.control),
                                            uniformBottomCorners: .concentric(minimum: .fixed(GT.Radius.control)))
            if let band {
                shape.fill(band.tint).overlay(shape.stroke(band.ink, lineWidth: 2))
            } else {
                shape.fill(GT.glass).overlay(shape.stroke(GT.glassEdge, lineWidth: 1))
            }
        } else {
            let shape = UnevenRoundedRectangle(topLeadingRadius: GT.Radius.control,
                                               topTrailingRadius: GT.Radius.control,
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

    /// How far the grabber's tap target reaches past its row, to a 44pt target.
    private static var grabberReach: CGFloat { 10 }

    private var grabber: some View {
        Button { setCollapsed(!collapsed) } label: {
            Capsule().fill(GT.ink.opacity(0.30)).frame(width: 36, height: 4)
                .frame(maxWidth: .infinity, minHeight: 24 + 2 * Self.grabberReach)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // The target reaches past the 24pt row on both sides; the row keeps its height.
        .padding(.vertical, -Self.grabberReach)
        .zIndex(1)
        .padding(.bottom, 3)
        .accessibilityLabel(collapsed ? language.text("설명 펼치기", "Show explanation")
                                      : language.text("설명 접기", "Hide explanation"))
        .accessibilityIdentifier("reveal-sheet-toggle")
    }

    private func setCollapsed(_ value: Bool) {
        withAnimation(reduceMotion ? nil : GT.Motion.change) { collapsed = value }
    }
}

private struct RevealCollapsedKey: EnvironmentKey {
    static let defaultValue = false
}

private struct HomeIndicatorInsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    /// The window's own bottom inset — the home indicator, 0 on a Home-button phone —
    /// measured once at the root. Reading it from UIKit inside a view's body made iOS 27
    /// re-query the status bar mid-update and spin the main thread in a graph cycle.
    var homeIndicatorInset: CGFloat {
        get { self[HomeIndicatorInsetKey.self] }
        set { self[HomeIndicatorInsetKey.self] = newValue }
    }

    /// True while a graded sheet is folded down; reveal sheets then show only the
    /// verdict and Next.
    var revealCollapsed: Bool {
        get { self[RevealCollapsedKey.self] }
        set { self[RevealCollapsedKey.self] = newValue }
    }
}

/// Shows its content only while the graded sheet is unfolded.
struct RevealDetail<Content: View>: View {
    @Environment(\.revealCollapsed) private var collapsed
    @ViewBuilder var content: () -> Content
    var body: some View {
        if !collapsed { content() }
    }
}

/// Primary action: mint fill, dark lettering. The one visually dominant control in
/// any sheet — three equal rectangles is what made the old answer sheets read flat.
/// The same button serves directly on felt, where there is no glass beneath it.
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

/// The label for anything tappable that is not a filled button: a bordered card that
/// ends in a chevron, so it reads as a way forward rather than as information.
/// `emphasized` marks the one card a screen leads with.
struct TapCardLabel: View {
    let title: String
    var detail: String? = nil
    var icon: String? = nil
    var emphasized = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: GT.Radius.panel, style: .continuous)
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon).font(.system(size: 22)).foregroundStyle(GT.ink)
                    .frame(width: 28).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(GT.title(18)).foregroundStyle(GT.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail {
                    Text(detail).font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                        .lineSpacing(GT.Typography.bodyLineSpacing)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold))
                .foregroundStyle(emphasized ? GT.cta : GT.inkSecondary)
        }
        .multilineTextAlignment(.leading)
        .gtInset(GT.Space.card, firstText: .title(18))
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .background(GT.glass, in: shape)
        .overlay(shape.strokeBorder(emphasized ? GT.cta : GT.borderStrong,
                                    lineWidth: emphasized ? 2 : 1))
        .contentShape(shape)
    }
}

/// Every expandable section: its heading is a bordered row whose chevron turns, so
/// "tap to see more" looks tappable. Applied once at the root.
struct GTDisclosureStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        GTDisclosure(configuration: configuration)
    }
}

private struct GTDisclosure: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.learningLanguage) private var language
    let configuration: DisclosureGroupStyleConfiguration

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(reduceMotion ? nil : GT.Motion.change) {
                    configuration.isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    configuration.label
                        .font(GT.semibold(16)).foregroundStyle(GT.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down").font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GT.inkSecondary)
                        .rotationEffect(.degrees(configuration.isExpanded ? 180 : 0))
                        .accessibilityHidden(true)
                }
                .gtInset(GT.Space.card, firstText: .semibold(16))
                .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                .background(GT.glass, in: shape)
                .overlay(shape.strokeBorder(GT.borderStrong, lineWidth: 1))
                .contentShape(shape)
            }
            .buttonStyle(GTPress())
            .accessibilityValue(configuration.isExpanded
                                ? language.text("펼침", "Expanded")
                                : language.text("접힘", "Collapsed"))
            if configuration.isExpanded {
                configuration.content
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct SecondaryCTAButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(GT.semibold(GT.Typography.buttonSize)).foregroundStyle(GT.inkSecondary)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(GT.surface, in: RoundedRectangle(cornerRadius: GT.Radius.control,
                                                            style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
                    .strokeBorder(GT.border, lineWidth: 1))
        }
        .buttonStyle(GTPress())
    }
}

/// Previous beside a flow's bottom action, in the same place on every step: a narrow
/// grey button, then the action. Stacked at accessibility sizes.
struct GTStepRow<Action: View>: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.learningLanguage) private var language
    /// Nil on a flow's first step, where the action takes the whole row.
    let previous: (() -> Void)?
    let previousID: String
    @ViewBuilder let action: Action

    var body: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 12))
            : AnyLayout(StepSplit(hasPrevious: previous != nil))
        layout {
            if let previous {
                SecondaryCTAButton(title: language.text("이전", "Previous"), action: previous)
                    .accessibilityIdentifier(previousID)
            }
            action
        }
    }
}

private struct StepSplit: Layout {
    let hasPrevious: Bool
    private let spacing: CGFloat = 12
    private let share: CGFloat = 0.36

    private func widths(_ total: CGFloat, count: Int) -> [CGFloat] {
        guard hasPrevious else { return Array(repeating: total, count: count) }
        let narrow = ((total - spacing) * share).rounded()
        return [narrow] + Array(repeating: total - spacing - narrow, count: max(count - 1, 0))
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let total = proposal.width ?? 320
        let heights = zip(subviews, widths(total, count: subviews.count)).map {
            $0.sizeThatFits(ProposedViewSize(width: $1, height: nil)).height
        }
        return CGSize(width: total, height: heights.max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews,
                       cache: inout ()) {
        var x = bounds.minX
        for (view, width) in zip(subviews, widths(bounds.width, count: subviews.count)) {
            view.place(at: CGPoint(x: x, y: bounds.minY), anchor: .topLeading,
                       proposal: ProposedViewSize(width: width, height: bounds.height))
            x += width + spacing
        }
    }
}

/// A choice in an answer sheet: translucent ivory on glass, with a selected state that
/// moves fill, border and weight together so it never leans on colour alone.
struct GTChoiceButton: View {
    @Environment(\.isEnabled) private var isEnabled
    let title: String
    var selected: Bool = false
    var minHeight: CGFloat = 54
    /// Once answered: the picked choice and the right one take the verdict's colour and
    /// glyph in place, so the answer is marked where the learner tapped.
    var verdict: GradeBand? = nil
    let action: () -> Void

    /// A locked choice drops its fill and draws a dashed edge, so it never reads as
    /// tappable (audit: pot answers looked live while waiting for the last action).
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
        Button(action: action) {
            if let verdict {
                HStack(spacing: 6) {
                    Image(systemName: verdict.glyph).accessibilityHidden(true)
                    Text(title).fixedSize(horizontal: false, vertical: true)
                }
                .font(GT.title(GT.Typography.buttonSize))
                .foregroundStyle(verdict.ink)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, minHeight: minHeight)
                .background(verdict.tint, in: shape)
                .overlay(shape.strokeBorder(verdict.ink, lineWidth: 2.5))
            } else {
                Text(title)
                    .font(selected ? GT.title(GT.Typography.buttonSize)
                                   : GT.semibold(GT.Typography.buttonSize))
                    .foregroundStyle(selected ? GT.onCTA : (isEnabled ? GT.ink : GT.inkMuted))
                    .frame(maxWidth: .infinity, minHeight: minHeight)
                    .background(selected ? AnyShapeStyle(GT.cta)
                                         : AnyShapeStyle(GT.surface.opacity(isEnabled ? 1 : 0.35)),
                                in: shape)
                    .overlay(shape
                        .strokeBorder(selected ? Color.clear : GT.borderStrong.opacity(isEnabled ? 1 : 0.6),
                                      style: StrokeStyle(lineWidth: 1, dash: isEnabled ? [] : [4, 3])))
            }
        }
        .buttonStyle(GTPress())
        .animation(GT.Motion.change, value: isEnabled)
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

    /// A dense table part (D54): its text grows with the reader's size up to AX3 and
    /// stops there. No press-and-hold viewer: inside a scroll it swallowed scroll drags.
    /// Lesson, explanation, answer and result text never takes this.
    func gtTablePartTextCap() -> some View {
        dynamicTypeSize(...DynamicTypeSize.accessibility3)
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
    @Environment(\.dynamicTypeSize) private var typeSize
    let title: String
    /// Always present, 폴드 included: "0bb" is the fact that makes the EV comparison on
    /// the next screen legible, and an empty slot here would break the column.
    let price: String
    let role: GTActionRole
    var freeTablePresentation = false
    var secondaryTitle: String? = nil
    var minHeight: CGFloat = 56
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // The accent is laid out, not overlaid. As an overlay it took no part in
            // sizing, so at the accessibility text sizes it painted straight over the
            // price line while the button kept its compact height.
            Group {
                if freeTablePresentation && typeSize.isAccessibilitySize {
                    VStack(spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Group {
                                if secondaryTitle == nil { GTActionCaption(text: title, weight: .semibold) }
                                else { Text(title).font(GT.title(15)).foregroundStyle(GT.ink) }
                            }
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                            if !price.isEmpty {
                                Text(price).font(GT.title(15).monospacedDigit()).foregroundStyle(GT.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            if let secondaryTitle {
                                GTActionCaption(text: secondaryTitle)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        Capsule().fill(role.accent).frame(height: 3)
                    }
                } else if freeTablePresentation {
                    ZStack {
                        VStack(spacing: 3) {
                            Group {
                                if secondaryTitle == nil { GTActionCaption(text: title, weight: .semibold) }
                                else { Text(title).font(GT.title(15)).foregroundStyle(GT.ink) }
                            }
                                .fixedSize(horizontal: false, vertical: true)
                            if !price.isEmpty {
                                Text(price).font(GT.title(15).monospacedDigit()).foregroundStyle(GT.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            if let secondaryTitle {
                                GTActionCaption(text: secondaryTitle)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.bottom, price.isEmpty ? 0 : 8)
                        VStack {
                            Spacer(minLength: 0)
                            Capsule().fill(role.accent).frame(height: 3).padding(.horizontal, 8)
                        }
                    }
                } else {
                    VStack(spacing: 3) {
                        Text(title).font(GT.semibold(12)).foregroundStyle(GT.inkSecondary)
                            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        Text(price).font(GT.title(15).monospacedDigit()).foregroundStyle(GT.ink)
                            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        Capsule().fill(role.accent)
                            .frame(height: 3).padding(.horizontal, 8).padding(.top, 1)
                    }
                }
            }
            .padding(.horizontal, 6).padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: minHeight,
                   maxHeight: freeTablePresentation && !typeSize.isAccessibilitySize ? .infinity : nil)
            .frame(height: freeTablePresentation && !typeSize.isAccessibilitySize ? 87 : nil)
            .background { GTDockControlBackground() }
        }
        .buttonStyle(GTPress(pressedScale: freeTablePresentation ? 0.97 : 0.98))
        .gtTablePartTextCap()
        .accessibilityLabel([title, secondaryTitle, price.isEmpty ? nil : price].compactMap { $0 }.joined(separator: ", "))
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
                .background(GT.surface, in: RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
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


/// Measures passive face templates before placing the active dock content.
/// Templates must contain no tasks, gestures, or model mutations.
struct GTStableDockLayout: Layout {
    var heightLimit: CGFloat?

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 360
        let heights = subviews.dropFirst().map {
            $0.sizeThatFits(ProposedViewSize(width: width, height: nil)).height
        }
        let height = heights.max() ?? 0
        return CGSize(width: width, height: min(height, heightLimit ?? height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (index, subview) in subviews.enumerated() {
            subview.place(at: bounds.origin, anchor: .topLeading,
                          proposal: ProposedViewSize(width: bounds.width, height: index == 0 ? bounds.height : nil))
        }
    }
}


/// Keeps the leading title and the last controls against the dock's visible insets.
struct GTAnchoredDockFaceLayout: Layout {
    var minimumHeight: CGFloat = 0
    var scrollsBody = false

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 360
        let heights = subviews.map { $0.sizeThatFits(ProposedViewSize(width: width, height: nil)).height }
        let height = (heights.first ?? 0) + 12 + (scrollsBody ? 0 : heights.dropFirst().reduce(0, +))
        return CGSize(width: width, height: max(height, minimumHeight, proposal.height ?? height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        subviews[0].place(at: bounds.origin, anchor: .topLeading,
                          proposal: ProposedViewSize(width: bounds.width, height: nil))
        let headerHeight = subviews[0].sizeThatFits(ProposedViewSize(width: bounds.width, height: nil)).height
        let bodyHeight = scrollsBody ? max(0, bounds.height - headerHeight - 12) : nil
        subviews[1].place(at: CGPoint(x: bounds.minX, y: bounds.maxY), anchor: .bottomLeading,
                          proposal: ProposedViewSize(width: bounds.width, height: bodyHeight))
    }
}

/// Native button presses allow the dock's scroll view to cancel an adjustment.
struct GTHoldStepStyle: PrimitiveButtonStyle {
    var enabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        GTHoldStepBody(enabled: enabled, trigger: configuration.trigger) {
            configuration.label
        }
    }
}

private struct GTHoldStepBody<Label: View>: View {
    @Environment(\.isEnabled) private var parentEnabled
    @Environment(\.scenePhase) private var scenePhase
    let enabled: Bool
    let trigger: () -> Void
    @ViewBuilder let label: () -> Label
    @State private var repeated = false

    private var available: Bool { enabled && parentEnabled }

    var body: some View {
        Button {
            guard available, scenePhase == .active, !repeated else { return }
            trigger()
        } label: {
            label()
        }
        .buttonStyle(GTHoldStepPressStyle(available: available, repeated: $repeated, step: trigger))
        .accessibilityAction {
            guard available, scenePhase == .active else { return }
            trigger()
        }
    }
}

private struct GTHoldStepPressStyle: ButtonStyle {
    let available: Bool
    @Binding var repeated: Bool
    let step: () -> Void

    func makeBody(configuration: Configuration) -> some View {
        GTHoldStepPressBody(isPressed: configuration.isPressed, available: available,
                            repeated: $repeated, step: step) {
            configuration.label
        }
    }
}

private struct GTHoldStepPressBody<Label: View>: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isPressed: Bool
    let available: Bool
    @Binding var repeated: Bool
    let step: () -> Void
    @ViewBuilder let label: () -> Label
    @State private var pressed = false
    @State private var repeatTask: Task<Void, Never>?

    var body: some View {
        label()
            .scaleEffect(pressed && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : GT.Motion.press, value: pressed)
            .onChange(of: isPressed) { _, isPressed in
                if isPressed { start() } else { stop() }
            }
            .onChange(of: available) { _, available in if !available { stop() } }
            .onChange(of: scenePhase) { _, phase in if phase != .active { stop() } }
            .onDisappear { stop() }
    }

    private func start() {
        guard available, scenePhase == .active, !pressed else { return }
        pressed = true
        // Keep this latch through release: the native action can precede or follow it.
        repeated = false
        repeatTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled, pressed, available, scenePhase == .active else { return }
            repeated = true
            while !Task.isCancelled, pressed, available, scenePhase == .active {
                step()
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    private func stop() {
        repeatTask?.cancel()
        repeatTask = nil
        pressed = false
    }
}
