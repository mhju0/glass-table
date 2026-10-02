// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills
import GlassTableEngine

struct FreeTableDecisionSnapshot: Identifiable, Sendable {
    let id: String
    let street: PracticeStreet
    let needed: Int
    let hero: [Card]
    let villain: [Card]?
    let board: [Card]
    var cacheKey: String { (hero + (villain ?? []) + board).map(\.description).joined(separator: ",") }

    static func rows(table: PracticeTableState) -> [Self] {
        guard let review = table.review else { return [] }
        var rows: [Self] = []
        for (stepIndex, step) in table.replaySteps.enumerated() {
            guard case let .action(eventIndex) = step else { continue }
            let event = table.events[eventIndex]
            guard event.seat == 0, event.action != nil else { continue }
            let frame = table.frame(after: stepIndex)
            guard let facts = PracticeDecisionFacts(frame: frame, learnerHole: table.learnerHole,
                                                     visibleBoard: review.board),
                  facts.toCall > 0, let needed = facts.requiredEquityPercent,
                  let hero = Card.parse(table.learnerHole.joined()) else { continue }
            let live = (1..<table.seatCount).filter { !frame.folded[$0] }
            let opponent = live.count == 1 ? live[0] : nil
            let shown = opponent.map { seat in
                review.pots.contains { $0.eligibleSeats.count > 1 && $0.eligibleSeats.contains(seat) }
            } ?? false
            let villain = shown ? opponent.flatMap { Card.parse(review.holeCards[$0].joined()) } : nil
            rows.append(Self(id: "\(table.handID)-\(eventIndex)", street: event.street, needed: needed,
                             hero: hero, villain: villain,
                             board: Card.parse(review.board.prefix(frame.boardCount).joined()) ?? []))
        }
        return rows
    }
}

// The actor serializes non-cancellable enumeration across tab and hand changes.
// Its cache also deduplicates queued requests without launching duplicate workers.
actor FreeTableEquityCache {
    static let shared = FreeTableEquityCache()
    private var values: [String: Double] = [:]
    private var order: [String] = []
    var cachedEntryCount: Int { values.count }
    func equity(for row: FreeTableDecisionSnapshot) -> Double? {
        guard !Task.isCancelled, let villain = row.villain else { return nil }
        if let cached = values[row.cacheKey] { return cached }
        let value = exactEquityHeadsUp(hero: row.hero, villain: villain, board: row.board).equity
        values[row.cacheKey] = value
        order.append(row.cacheKey)
        if order.count > 12 { values.removeValue(forKey: order.removeFirst()) }
        return value
    }
}

struct FreeTableDecisionReview: View {
    @Environment(\.learningLanguage) private var language
    let table: PracticeTableState
    @State private var chances: [String: Double] = [:]
    @State private var publishedHand = ""
    var body: some View {
        let rows = FreeTableDecisionSnapshot.rows(table: table)
        VStack(alignment: .leading, spacing: 12) {
            Text(language.text("핸드 돌아보기", "Hand review")).font(GT.title(18))
            ForEach(rows) { row in
                VStack(alignment: .leading, spacing: 6) {
                    Text(FreeTableWords.street(row.street, language: language)).font(GT.semibold(13))
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule().fill(GT.border)
                            if let chance = chances[row.id], publishedHand == table.handID {
                                Capsule().fill(GT.green)
                                    .frame(width: geometry.size.width * chance)
                            }
                            Rectangle().fill(GT.cta).frame(width: 2)
                                .offset(x: geometry.size.width * Double(row.needed) / 100)
                        }
                    }.frame(height: 10)
                    HStack {
                        Text(language.text("실제", "Chance") + " " + chanceText(row))
                        Spacer()
                        Text(language.text("필요", "Needed") + " \(row.needed)%")
                    }.font(GT.semibold(13)).monospacedDigit()
                }.accessibilityElement(children: .combine)
                 .accessibilityIdentifier("free-decision-\(row.id)")
            }
        }.foregroundStyle(GT.ink)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("free-decision-review")
        .task(id: table.handID) {
            let handID = table.handID
            chances = [:]
            publishedHand = handID
            for row in rows where row.villain != nil {
                guard !Task.isCancelled else { return }
                let worker = Task.detached(priority: .utility) { await FreeTableEquityCache.shared.equity(for: row) }
                let value = await withTaskCancellationHandler(operation: { await worker.value }, onCancel: { worker.cancel() })
                guard !Task.isCancelled, publishedHand == handID else { return }
                if let value { chances[row.id] = value }
            }
        }
    }
    private func chanceText(_ row: FreeTableDecisionSnapshot) -> String {
        guard publishedHand == table.handID, let chance = chances[row.id] else { return "—" }
        return "\(Int((chance * 100).rounded()))%"
    }
}
