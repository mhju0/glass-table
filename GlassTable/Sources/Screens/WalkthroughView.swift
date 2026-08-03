// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

/// 천천히 — the micro-step player (spec §5.2).
///
/// The board is the teaching surface; the text is the caption. Highlighted cards glow
/// and everything else dims, the layout holds still between beats so consecutive
/// beats read as a comparison, and dead cards strike through **in place** rather than
/// disappearing — seeing what was removed and why is the lesson.
///
/// **No flashing.** WCAG 2.3.1 caps flashing at three per second as a seizure risk, so
/// the highlight is a slow ~1.9s breathe that stops entirely under Reduce Motion,
/// where the dimming alone carries the same information.
struct WalkthroughView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let title: String
    let beats: [Beat]
    /// Card rows to show for `.table` beats: (label, cards), top to bottom.
    let rows: [(String, [Card])]
    let onFinish: () -> Void
    let onSkip: () -> Void

    @State private var index = 0
    @State private var pulsing = false

    private var beat: Beat { beats[min(index, beats.count - 1)] }
    private var isLast: Bool { index >= beats.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                content.padding(.horizontal, 18).padding(.top, 6)
            }
            ActionSheet { sheet }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FeltBackground())
        .onAppear {
            if !reduceMotion { pulsing = true }
            #if DEBUG
            // GT_DEMO_BEAT=<n> opens on beat n — synthetic taps never reach Simulator
            // content, so the highlight/strike states are otherwise unverifiable.
            if let n = ProcessInfo.processInfo.environment["GT_DEMO_BEAT"].flatMap(Int.init) {
                index = min(max(0, n), beats.count - 1)
            }
            #endif
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("건너뛰기", action: onSkip)
                    .font(GT.semibold(14)).foregroundStyle(GT.onFeltSecondary)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(title) · 천천히").font(GT.semibold(12))
                    .foregroundStyle(GT.onFeltSecondary)
                Spacer()
                Text("\(index + 1)/\(beats.count)")
                    .font(GT.semibold(12).monospacedDigit())
                    .foregroundStyle(GT.onFeltSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(GT.hairlineFelt).frame(height: 2)
                    Capsule().fill(GT.onFelt)
                        .frame(width: geo.size.width * Double(index + 1) / Double(beats.count),
                               height: 2)
                }
            }
            .frame(height: 2)
        }
        .padding(.horizontal, 18).padding(.top, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(beats.count)단계 중 \(index + 1)단계")
    }

    @ViewBuilder
    private var content: some View {
        switch beat.focus {
        case .none:
            EmptyView()
        case .table:
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    SectionLabel(text: row.0)
                    cardRow(row.1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case let .grid(cards):
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50), spacing: 9)],
                      alignment: .leading, spacing: 8) {
                ForEach(Array(cards.enumerated()), id: \.offset) { _, card in
                    cardView(card, size: 58)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func cardRow(_ cards: [Card]) -> some View {
        HStack(spacing: 7) {
            ForEach(Array(cards.enumerated()), id: \.offset) { _, card in
                cardView(card, size: 58)
            }
        }
    }

    /// Four states, and none of them removes the card from the layout.
    private func cardView(_ card: Card, size: CGFloat) -> some View {
        let lit = beat.highlight.contains(card)
        let dead = beat.struck.contains(card)
        let down = beat.hidden.contains(card)
        // Only dim when something is actually singled out, or a beat with no
        // highlight would grey the whole board for no reason.
        let dim = !beat.highlight.isEmpty && !lit && !down
        return PlayingCardView(card: card, size: size, faceDown: down)
            // The river landing: it flips up and settles, so the one card that
            // changed is the one thing that moved.
            .rotation3DEffect(.degrees(down ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .scaleEffect(down ? 0.96 : 1)
            .overlay {
                if dead {
                    // Strike + a red bar, so "removed" survives greyscale.
                    Rectangle().fill(GT.suitRed)
                        .frame(height: 2.5)
                        .rotationEffect(.degrees(-16))
                }
            }
            // A dimmed card must stay *readable* — the beat is a comparison, and you
            // cannot compare against something you cannot read. At 0.26 the face
            // measured ~3.7:1 against its own ink over the dark felt; 0.62 puts it
            // near 7:1 while still sitting clearly behind the highlighted cards,
            // which now carry the emphasis themselves rather than borrowing it from
            // everything else being crushed.
            .opacity(dead ? 0.5 : (dim ? 0.62 : 1))
            .overlay {
                if lit {
                    RoundedRectangle(cornerRadius: size * 0.17)
                        .stroke(GT.mint, lineWidth: 3)
                        .shadow(color: GT.mint.opacity(pulsing ? 0.9 : 0.45), radius: 9)
                }
            }
            // Lifted rather than merely outlined, so emphasis reads even at a glance
            // now that the unhighlighted cards stay legible.
            .scaleEffect(lit ? 1.06 : 1)
            .animation(reduceMotion ? nil : .easeInOut(duration: 1.9).repeatForever(autoreverses: true),
                       value: pulsing)
            .animation(reduceMotion ? .easeOut(duration: 0.01)
                                    : .spring(response: 0.55, dampingFraction: 0.72),
                       value: down)
            .animation(.easeOut(duration: 0.22), value: lit)
            .animation(.easeOut(duration: 0.25), value: index)
            .accessibilityLabel(accessibilityText(card, lit: lit, dead: dead))
    }

    private func accessibilityText(_ card: Card, lit: Bool, dead: Bool) -> String {
        if dead { return "\(card.description), 제외됨" }
        if lit { return "\(card.description), 강조됨" }
        return card.description
    }

    /// Hierarchy follows the payload, not the sentence order. When a beat carries a
    /// `value` the caption demotes to a small label above it and the value becomes the
    /// biggest thing on screen — "지금 내 패" is the label, "10 하이" is the lesson, and
    /// the previous layout had those the wrong way round.
    private var sheet: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let value = beat.value {
                Text(beat.caption)
                    .font(GT.semibold(11)).tracking(0.5)
                    .foregroundStyle(GT.inkMuted)
                Text(value)
                    .font(GT.title(30)).foregroundStyle(GT.ink)
                    .minimumScaleFactor(0.6).lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.numericText())
            } else {
                Text(beat.caption).font(GT.title(19)).foregroundStyle(GT.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let detail = beat.detail {
                Text(detail).font(GT.body(13)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            PrimaryCTAButton(title: isLast ? "이해했어요" : "다음") {
                if isLast { onFinish() }
                else { withAnimation(.easeOut(duration: 0.25)) { index += 1 } }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Builds the walkthrough for a concept at a given spot index, including the card
/// rows a `.table` beat needs. Keeping this beside the player means a new concept
/// only has to be added in one place on the app side.
enum Walkthrough {
    static func make(concept: Concept, seed: UInt64, index: Int)
        -> (beats: [Beat], rows: [(String, [Card])]) {
        switch concept {
        case .showdown:
            let s = ShowdownSpotGenerator.spot(baseSeed: seed, index: index)
            return (BeatScript.showdown(s),
                    [("상대", s.villain), ("보드", s.board), ("내 핸드", s.hero)])
        case .outs:
            let s = OutsSpotGenerator.spot(baseSeed: seed, index: index)
            return (BeatScript.outs(s),
                    [("상대", s.villain), ("보드 · 턴", s.board), ("내 핸드", s.hero)])
        case .equitySense:
            let s = EquitySenseSpotGenerator.spot(baseSeed: seed, index: index)
            return (BeatScript.equitySense(s),
                    [("상대", s.villain),
                     (s.board.count == 3 ? "보드 · 플랍" : "보드 · 턴", s.board),
                     ("내 핸드", s.hero)])
        case .callFold:
            let s = CallFoldSpotGenerator.spot(baseSeed: seed, index: index)
            return (BeatScript.callFold(s),
                    [("상대", s.villain), ("보드 · 턴", s.board), ("내 핸드", s.hero)])
        case .combos:
            let s = BlockerSpotGenerator.spot(baseSeed: seed, index: index)
            return (BeatScript.combos(s), [("보이는 카드", s.removed)])
        case .potMath:
            return (BeatScript.potMath(PotMathSpotGenerator.spot(baseSeed: seed, index: index)), [])
        case .position:
            return (BeatScript.position(PositionSpotGenerator.spot(baseSeed: seed, index: index)), [])
        case .potOdds:
            return (BeatScript.potOdds(BetSpotGenerator.spot(baseSeed: seed, index: index)), [])
        case .mdf:
            return (BeatScript.mdf(BetSpotGenerator.spot(baseSeed: seed, index: index)), [])
        case .evCall:
            return (BeatScript.evCall(EVCallSpotGenerator.spot(baseSeed: seed, index: index)), [])
        }
    }
}
