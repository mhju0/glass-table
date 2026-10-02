import Foundation
import GlassTableDrills
import GlassTableEngine

struct FreeTableFlight: Identifiable, Equatable {
    enum Anchor: Hashable { case pot, street(Int), seat(Int), hole(Int, Int), board(Int) }
    enum Cargo: Equatable { case chips(Int), card, dealer }
    let id: String
    let from: Anchor
    let to: Anchor
    let cargo: Cargo
    let progress: Double
}

struct FreeTableVisuals: Equatable {
    var flights: [FreeTableFlight] = []
    var arrived = [Int]()
    var exposed = Set<Int>()
    var flipping: [Int: Double] = [:]
    var boardArrived = 0
    var boardFlips: [Int: Double] = [:]
    var foldProgress: [Int: Double] = [:]
    var checkProgress: [Int: Double] = [:]
    var winnerCards = Set<Card>()
    var winnerProgress = 0.0
    var clearProgress = 0.0
    var dealerMoving = false
}

struct FreeTableReplayProjection {
    var frame: PracticeTableFrame
    var shownSteps = 0
    var pot = 0
    var inTransit = 0
    var visuals = FreeTableVisuals()
    var thinkingSeat: Int?
    var credits: [Int: Int] = [:]
    var returned: [Int: Int] = [:]
    var refilling: [Int: Int] = [:]
    var potIndex: Int?
    var remainingPots: [Int] = []
    var oddAward = Set<Int>()
    var visibleHole: [[String]] = []
    var visibleBoard: [String] = []
    var transitioning = false
    var heroExposed: Bool { !transitioning && visuals.exposed.contains(0) }
}

/// Local visual work reads model facts and never applies a game action.
struct FreeTableReplayPlan {
    enum Work: Equatable {
        case clear, refill([Int]), dealer, blinds([Int]), holes
        case think(Int), action(Int, Int), sweep, deal(Int, PracticeStreet, Bool), reveal(Int)
        case refund(Int, Int), award(Int, [Int], Bool), winners, settle(Int), wait
    }
    struct Phase: Equatable {
        let start: Double
        let duration: Double
        let work: Work
        let reduced: Bool
        var end: Double { start + duration }
    }
    struct Cue: Equatable { let time: Double; let feedback: TableFeedbackKind; let phase: Int }
    let table: PracticeTableState
    let previous: PracticeTableState?
    let reduceMotion: Bool
    private(set) var phases: [Phase] = []
    private(set) var cues: [Cue] = []
    var duration: Double { phases.last?.end ?? 0 }

    init(table: PracticeTableState, previous: PracticeTableState? = nil, reduceMotion: Bool = false) {
        self.table = table; self.previous = previous; self.reduceMotion = reduceMotion
        build()
    }
    static func canExposeRunout(_ frame: PracticeTableFrame) -> Bool {
        let live = frame.folded.indices.filter { !frame.folded[$0] }
        let funded = live.filter { frame.stacks[$0] > 0 }
        let bet = max(frame.street == .preflop ? 2 : 0, frame.streetCommitted.max() ?? 0)
        return live.count > 1 && funded.count <= 1 && funded.allSatisfy { frame.streetCommitted[$0] >= bet }
    }
    func allInAmount(seat: Int, after steps: Int) -> Int? {
        let frame = table.frame(after: steps)
        guard frame.stacks[seat] == 0, !frame.folded[seat] else { return nil }
        let events = table.replaySteps.prefix(steps).compactMap { step -> PracticeEvent? in
            if case let .action(index) = step, table.events[index].seat == seat { return table.events[index] }; return nil
        }
        guard let street = events.last(where: { $0.chips > 0 })?.street else { return nil }
        return events.filter { $0.street == street }.reduce(0) { $0 + $1.chips }
    }
    static func showdownOrder(table: PracticeTableState) -> [Int] {
        let frame = table.frame(after: max(0, table.replaySteps.count - 1))
        let live = frame.folded.indices.filter { !frame.folded[$0] }
        let aggressor = table.events.last { ["raise", "bet"].contains($0.label) && live.contains($0.seat) }?.seat
        let first = aggressor ?? (table.dealer + 1) % table.seatCount
        return (0..<table.seatCount).map { (first + $0) % table.seatCount }.filter { live.contains($0) }
    }
    static func awards(review: PracticeTableReview, dealer: Int) -> [(pot: Int, amounts: [Int], odd: Bool)] {
        var result: [(Int, [Int], Bool)] = []
        for index in review.pots.indices.reversed() {
            let pot = review.pots[index]
            guard !pot.winners.isEmpty else { continue }
            var amounts = Array(repeating: 0, count: review.payouts.count)
            for seat in pot.winners { amounts[seat] = pot.amount / pot.winners.count }
            result.append((index, amounts, false))
            let order = (1...amounts.count).map { (dealer + $0) % amounts.count }.filter { pot.winners.contains($0) }
            for seat in order.prefix(pot.amount % pot.winners.count) {
                var odd = Array(repeating: 0, count: amounts.count); odd[seat] = 1
                result.append((index, odd, true))
            }
        }
        return result
    }
    func boundary(after steps: Int) -> Double {
        if steps >= table.replaySteps.count { return duration }
        return phases.last { phase in
            switch phase.work {
            case let .action(step, _), let .deal(step, _, _), let .settle(step): step < steps
            case .holes: steps >= 2
            case let .blinds(indices): indices.count <= steps
            default: false
            }
        }?.end ?? 0
    }
    private mutating func add(_ work: Work, _ milliseconds: Double, pause: Bool = false) {
        let duration = reduceMotion ? (pause ? milliseconds * 0.5 : min(milliseconds, 150)) : milliseconds
        phases.append(Phase(start: self.duration, duration: duration, work: work, reduced: reduceMotion))
    }
    private mutating func reveal(_ seat: Int) {
        add(.reveal(seat), 350)
        cues.append(Cue(time: phases.last!.end, feedback: .card, phase: phases.count - 1))
    }
    private mutating func build() {
        let n = table.seatCount
        if let previous, previous.handID != table.handID {
            add(.clear, 300)
            let seats = previous.review?.endingStacks.indices.filter { previous.review?.endingStacks[$0] == 0 } ?? []
            if !seats.isEmpty { add(.refill(seats), 400) }
            add(.dealer, 400)
        }
        var exposed: Set<Int> = [0]
        var runout = false
        var index = 0
        while index < table.replaySteps.count {
            switch table.replaySteps[index] {
            case let .action(eventIndex):
                let event = table.events[eventIndex]
                if event.action == nil, index == 0 {
                    let blinds = table.replaySteps.prefix(2).compactMap { step -> Int? in
                        if case let .action(i) = step, table.events[i].action == nil { return i }; return nil
                    }
                    add(.blinds(blinds), 180 * Double(max(0, blinds.count - 1)) + 250)
                    let sb = n == 2 ? table.dealer : (table.dealer + 1) % n
                    let heroEnd = Double(n + (n - sb) % n) * 60 + 400
                    add(.holes, max(Double(2 * n - 1) * 60 + 220, heroEnd))
                    cues.append(Cue(time: reduceMotion ? phases.last!.end : phases.last!.start + heroEnd, feedback: .card, phase: phases.count - 1))
                    index += blinds.count; continue
                }
                if event.seat != 0 { add(.think(event.seat), n == 2 ? 650 : n == 3 ? 550 : 500, pause: true) }
                let before = table.frame(after: index)
                let allIn = event.chips > 0 && event.chips == before.stacks[event.seat]
                add(.action(index, eventIndex), event.label == "fold" ? 250 : event.label == "check" ? 150 : allIn ? 350 : 280)
                if event.seat != 0, event.chips > 0 { cues.append(Cue(time: phases.last!.start, feedback: .chip(allIn: allIn), phase: phases.count - 1)) }
            case let .deal(street):
                if !runout, table.review != nil, Self.canExposeRunout(table.frame(after: index)) {
                    add(.sweep, 300); add(.wait, 150, pause: true)
                    runout = true
                    for seat in Self.showdownOrder(table: table) where !exposed.contains(seat) { reveal(seat); exposed.insert(seat) }
                }
                if runout { add(.wait, 200, pause: true) }
                else { add(.sweep, 300); add(.wait, 150, pause: true); add(.wait, 300, pause: true) }
                let count = street == .flop ? 3 : 1, stagger = runout ? 600.0 : 90
                add(.deal(index, street, runout), Double(count - 1) * stagger + 400)
                for card in 0..<count {
                    cues.append(Cue(time: reduceMotion ? phases.last!.end : phases.last!.start + Double(card) * stagger + 220, feedback: .card, phase: phases.count - 1))
                }
            case .settle:
                add(.sweep, 300); add(.wait, 150, pause: true)
                if let review = table.review {
                    if review.pots.contains(where: { $0.eligibleSeats.count > 1 }) {
                        for seat in Self.showdownOrder(table: table) where !exposed.contains(seat) { reveal(seat); exposed.insert(seat) }
                    }
                    add(.winners, 180)
                    for seat in review.refunds.indices where review.refunds[seat] > 0 { add(.refund(seat, review.refunds[seat]), 300) }
                    for award in Self.awards(review: review, dealer: table.dealer) {
                        add(.award(award.pot, award.amounts, award.odd), 450)
                        if award.amounts[0] > 0 { cues.append(Cue(time: phases.last!.end, feedback: .won, phase: phases.count - 1)) }
                        add(.wait, 250, pause: true)
                    }
                    add(.settle(index), 0)
                }
            }
            index += 1
        }
        cues.sort { $0.time < $1.time }
    }
    /// Completed work and the active subphase keep their exact old clock and cues.
    /// New accessibility timing applies after that phase; the renderer suppresses motion now.
    mutating func preservePrefix(from old: FreeTableReplayPlan, at elapsed: Double) {
        let prefixCount = old.phases.firstIndex { $0.end > elapsed }.map { $0 + 1 } ?? old.phases.count
        guard phases.count >= prefixCount,
              zip(old.phases.prefix(prefixCount), phases.prefix(prefixCount)).allSatisfy({ $0.work == $1.work }) else { return }
        let rebuilt = phases
        phases = Array(old.phases.prefix(prefixCount))
        for phase in rebuilt.dropFirst(prefixCount) {
            phases.append(Phase(start: duration, duration: phase.duration, work: phase.work, reduced: phase.reduced))
        }
        let future = cues.filter { $0.phase >= prefixCount }.map { cue in
            Cue(time: phases[cue.phase].start + cue.time - rebuilt[cue.phase].start,
                feedback: cue.feedback, phase: cue.phase)
        }
        cues = old.cues.filter { $0.phase < prefixCount } + future
        cues.sort { $0.time < $1.time }
    }

    func projection(at elapsed: Double) -> FreeTableReplayProjection {
        var p = FreeTableReplayProjection(frame: table.frame(after: 0))
        p.remainingPots = table.review?.pots.map(\.amount) ?? []
        p.visuals.arrived = Array(repeating: 0, count: table.seatCount)
        p.visibleHole = Array(repeating: [], count: table.seatCount)
        for phase in phases where elapsed >= phase.start {
            let local = min(phase.duration, max(0, elapsed - phase.start))
            apply(phase.work, local: local, progress: phase.duration == 0 ? 1 : local / phase.duration,
                  complete: elapsed >= phase.end, reduced: phase.reduced, to: &p)
            if elapsed < phase.end { break }
        }
        return p
    }
    private func apply(_ work: Work, local: Double, progress: Double, complete: Bool, reduced: Bool, to p: inout FreeTableReplayProjection) {
        p.returned = [:]
        p.refilling = [:]
        p.oddAward = []
        func flight(_ id: String, _ from: FreeTableFlight.Anchor, _ to: FreeTableFlight.Anchor, _ cargo: FreeTableFlight.Cargo, _ fraction: Double) {
            if !reduced, fraction < 1 {
                p.visuals.flights.append(FreeTableFlight(id: id, from: from, to: to, cargo: cargo, progress: max(0, fraction)))
            }
        }
        switch work {
        case .wait: break
        case .clear:
            guard let previous else { break }
            if !complete {
                p.transitioning = true
                p.frame = previous.frame(after: previous.replaySteps.count)
                p.frame.settled = false
                p.frame.streetCommitted = Array(repeating: 0, count: table.seatCount)
                p.visibleBoard = previous.review?.board ?? []; p.frame.boardCount = p.visibleBoard.count
                p.visibleHole = previous.review?.holeCards ?? []
                p.visuals.arrived = Array(repeating: 2, count: table.seatCount)
                let contested = previous.review?.pots.contains { $0.eligibleSeats.count > 1 } == true
                p.visuals.exposed = Set([0] + (contested ? p.frame.folded.indices.filter { !p.frame.folded[$0] } : []))
                p.visuals.clearProgress = progress
            } else {
                if let stacks = previous.review?.endingStacks {
                    for seat in stacks.indices where stacks[seat] == 0 { p.frame.stacks[seat] = 0 }
                }
            }
        case let .refill(seats):
            for seat in seats { p.frame.stacks[seat] = Int(100 * progress); if !complete { p.refilling[seat] = p.frame.stacks[seat] } }
        case .dealer:
            if !complete, let previous { p.visuals.dealerMoving = true; flight("dealer", .seat(previous.dealer), .seat(table.dealer), .dealer, progress) }
        case let .blinds(indices):
            for (offset, eventIndex) in indices.enumerated() {
                let event = table.events[eventIndex]
                let fraction = reduced ? progress : min(1, max(0, (local - Double(offset) * 180) / 250))
                if fraction >= 1 { p.shownSteps += 1; p.frame = table.frame(after: p.shownSteps); p.pot += event.chips }
                else if fraction > 0 {
                    let amount = Int(Double(event.chips) * fraction); p.frame.stacks[event.seat] -= amount; p.inTransit += amount
                    flight("blind-\(eventIndex)", .seat(event.seat), .street(event.seat), .chips(event.chips), fraction)
                }
            }
        case .holes:
            let n = table.seatCount, sb = n == 2 ? table.dealer : (table.dealer + 1) % n
            for index in 0..<(2 * n) {
                let seat = (sb + index % n) % n, card = index / n
                let fraction = reduced ? progress : min(1, max(0, (local - Double(index) * 60) / 220))
                if fraction >= 1 { p.visuals.arrived[seat] += 1 }
                else if fraction > 0 { flight("hole-\(index)", .pot, .hole(seat, card), .card, fraction) }
            }
            let flip = reduced ? progress : min(1, max(0, (local - Double(n + (n - sb) % n) * 60 - 220) / 180))
            if flip >= 1 { p.visuals.exposed.insert(0); p.visibleHole[0] = table.learnerHole }
            else if flip > 0 { p.visuals.flipping[0] = flip }
        case let .think(seat): p.thinkingSeat = complete ? nil : seat
        case let .action(step, index):
            let event = table.events[index]
            if complete {
                p.shownSteps = step + 1; p.frame = table.frame(after: p.shownSteps); p.pot += event.chips
                if event.label == "fold" { p.visuals.foldProgress[event.seat] = 1 }
            } else {
                p.frame.lastEvent[event.seat] = event
                if event.label == "fold" { p.visuals.foldProgress[event.seat] = progress }
                if event.label == "check" { p.visuals.checkProgress[event.seat] = progress }
                let amount = Int(Double(event.chips) * progress); p.frame.stacks[event.seat] -= amount; p.inTransit += amount
                if event.chips > 0 { flight("action-\(index)", .seat(event.seat), .street(event.seat), .chips(event.chips), progress) }
            }
        case .sweep:
            for seat in p.frame.streetCommitted.indices where p.frame.streetCommitted[seat] > 0 {
                flight("sweep-\(p.shownSteps)-\(seat)", .street(seat), .pot, .chips(p.frame.streetCommitted[seat]), progress)
                p.frame.streetCommitted[seat] = Int(Double(p.frame.streetCommitted[seat]) * (1 - progress))
            }
            if complete { p.frame.streetCommitted = Array(repeating: 0, count: table.seatCount) }
        case let .deal(step, street, runout):
            let base = street == .flop ? 0 : street == .turn ? 3 : 4, count = street == .flop ? 3 : 1
            let board = table.review?.board ?? table.visibleBoard
            p.frame.street = street; p.frame.lastEvent = Array(repeating: nil, count: table.seatCount)
            for offset in 0..<count {
                let index = base + offset, start = Double(offset) * (runout ? 600 : 90)
                let arrived = reduced ? complete : local >= start + 220
                let flip = reduced ? progress : min(1, max(0, (local - start - 220) / 180))
                if arrived { p.visuals.boardArrived = max(p.visuals.boardArrived, index + 1) }
                if flip >= 1 { p.frame.boardCount = index + 1; p.visibleBoard = Array(board.prefix(index + 1)) }
                else if arrived { p.visuals.boardFlips[index] = flip }
                else if local >= start { flight("board-\(index)", .pot, .board(index), .card, min(1, (local - start) / 220)) }
            }
            if complete { p.shownSteps = step + 1; p.frame = table.frame(after: p.shownSteps) }
        case let .reveal(seat):
            if complete { p.visuals.exposed.insert(seat); p.visibleHole[seat] = table.review?.holeCards[seat] ?? [] }
            else { p.visuals.flipping[seat] = reduced ? progress : min(1, local / 180) }
        case .winners:
            p.visuals.winnerProgress = reduced ? 0 : progress
            if let review = table.review, p.visibleBoard.count == 5 {
                for seat in Set(review.pots.flatMap(\.winners)) where p.visuals.exposed.contains(seat) {
                    let cards = (p.visibleHole[seat] + p.visibleBoard).compactMap(Card.init)
                    if cards.count == 7 { p.visuals.winnerCards.formUnion(bestFiveCards(cards)) }
                }
            }
        case let .refund(seat, amount):
            let moving = Int(Double(amount) * progress); p.pot -= moving
            p.returned[seat] = amount
            if complete { p.frame.stacks[seat] += amount }
            else { p.inTransit += moving; flight("refund-\(seat)", .pot, .seat(seat), .chips(amount), progress) }
        case let .award(pot, amounts, odd):
            p.potIndex = pot
            for seat in amounts.indices where amounts[seat] > 0 {
                let moving = Int(Double(amounts[seat]) * progress); p.pot -= moving
                p.remainingPots[pot] -= moving
                if complete { p.frame.stacks[seat] += amounts[seat]; p.credits[seat, default: 0] += amounts[seat] }
                else { p.inTransit += moving; flight("award-\(pot)-\(odd)-\(seat)", .pot, .seat(seat), .chips(amounts[seat]), progress) }
                if odd { p.oddAward.insert(seat) } else { p.oddAward.remove(seat) }
            }
        case let .settle(step):
            if let review = table.review, p.pot == 0, p.frame.stacks == review.endingStacks {
                p.shownSteps = step + 1; p.frame = table.frame(after: p.shownSteps)
                p.frame.streetCommitted = Array(repeating: 0, count: table.seatCount)
            }
        }
    }
}

struct FreeTableReplayCursor {
    var elapsed = 0.0
    var cueIndex = 0
    func projection(plan: FreeTableReplayPlan) -> FreeTableReplayProjection { plan.projection(at: elapsed) }
    mutating func advance(by milliseconds: Double, plan: FreeTableReplayPlan) -> [TableFeedbackKind] {
        elapsed = min(plan.duration, elapsed + max(0, milliseconds))
        var result: [TableFeedbackKind] = []
        while cueIndex < plan.cues.count, plan.cues[cueIndex].time <= elapsed {
            result.append(plan.cues[cueIndex].feedback); cueIndex += 1
        }
        return result
    }
}

#if DEBUG
/// Every fixture is produced by public legal commands, with no edited money or review.
enum FreeTableReplayFixtures {
    static func table(_ kind: String) throws -> PracticeTableState {
        if kind == "sidepots" || kind == "refund" || kind == "refill" {
            for seed in 1..<100 {
                var table = PracticeTableState(seed: UInt64(seed), styles: [.station, .station, .station], handID: "motion-previous")
                for (index, action) in [PracticeAction.raise(to: 20), .call, .call, .fold, .check,
                                        .raise(to: 20), .call, .fold, .raise(to: 10), .call, .check, .check].enumerated() {
                    try table.apply(action, actionID: "previous-\(index)")
                }
                guard table.review?.payouts[0] == 122 else { continue }
                try table.nextHand(handID: "motion-\(kind)")
                if kind == "refund" {
                    for (index, action) in [PracticeAction.raise(to: 4), .call, .fold, .fold,
                                            .raise(to: 168), .call].enumerated() {
                        try table.apply(action, actionID: "refund-\(index)")
                    }
                } else {
                    for (index, action) in [PracticeAction.raise(to: 172), .call, .call, .call].enumerated() {
                        try table.apply(action, actionID: "side-\(index)")
                    }
                }
                return table
            }
            throw PracticeTableError.invalidState
        }
        if kind == "fold" {
            var table = PracticeTableState(seed: 31, styles: [.station], handID: "motion-fold")
            try table.apply(.fold, actionID: "hero-fold")
            return table
        }
        if kind == "runout" {
            for seed in 97..<197 {
                var table = PracticeTableState(seed: UInt64(seed), styles: [.station], handID: "motion-runout")
                try table.apply(.raise(to: 100), actionID: "hero-allin")
                try table.advanceBots()
                if table.review?.board.count == 5 { return table }
            }
            throw PracticeTableError.invalidState
        }
        var table = PracticeTableState(seed: kind == "odd" ? 311 : 97,
                                       styles: [.station, .station, .station], handID: "motion-\(kind)")
        try table.advanceBots()
        for index in 0..<40 where table.review == nil {
            try table.apply(table.legalActions.contains(.check) ? .check : .call, actionID: "motion-\(index)")
            try table.advanceBots()
        }
        guard table.review != nil else { throw PracticeTableError.invalidState }
        return table
    }
}
#endif
