// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

// MARK: - the hand

/// One postflop hand against a declared opponent, as a pure value type.
///
/// The machine and the grading are deliberately split: `play(_:)` advances the hand
/// and is fast; `gradedOptions()` prices the legal choices under the checkdown model
/// and is the slow part (spec §3), so the UI computes it off the main thread on a
/// copy and passes the result back alongside the choice.
///
/// Format (spec §1, amended by R5): heads-up, hero in position, 100bb, blinds dead.
/// The archetype opened 3bb — his hand is dealt *from that range* — and hero, dealt
/// any two cards, plays the preflop street for real: fold, call, or 3-bet.
public struct TableHand: Equatable {
    public static let stack: Double = 100
    public static let openSize: Double = 3
    /// A raise is always to 3× the bet, and each street allows one raise — the second
    /// becomes a call. Both rules exist so every subtree is closed-form (spec §1).
    public static let raiseFactor: Double = 3
    public static let deadBlinds: Double = 1.5
    // MARK: cast

    public let villainSeat: Position
    public let heroSeat: Position
    public let villain: Archetype
    public let hero: [Card]
    /// Face-down until the hand ends; the bot never acts on hero's cards either.
    let villainCombo: [Card]
    let fullBoard: [Card]
    let handSeed: UInt64

    // MARK: state

    public enum Facing: Equatable {
        /// Villain's 3bb preflop open, before any board: fold, call, or 3-bet (R5).
        case open(Double)
        /// Villain checked (or the street just opened with a check): check or bet.
        case checkedTo
        /// Villain bet this much: fold, call, or raise if the street still allows one.
        case bet(Double)
        /// Villain raised to this total over hero's street money: fold or call.
        case raise(to: Double)
    }

    public struct Outcome: Equatable {
        public let heroNet: Double
        public let wentToShowdown: Bool
        /// Always revealed at the end, fold or showdown — the app does not keep
        /// secrets it asked the user to reason about.
        public let villainHand: [Card]
        /// nil on a chop.
        public let heroWon: Bool?
    }

    public enum Phase: Equatable {
        case hero(Facing)
        case over(Outcome)
    }

    public private(set) var phase: Phase = .hero(.checkedTo)
    /// Board cards revealed: 0 preflop, then 3, 4, 5.
    public private(set) var street = 0
    /// Includes every chip placed, outstanding bets too.
    public private(set) var pot: Double
    public private(set) var heroStack: Double
    public private(set) var villainStack: Double
    public private(set) var heroInvested: Double
    public private(set) var raisesThisStreet = 0
    public private(set) var heroPutThisStreet: Double = 0
    /// One Korean line per event, oldest first — the on-screen hand history.
    public private(set) var history: [String] = []
    /// Every combo the villain can still hold, narrowed by his own actions (S3) and
    /// the board. Printable at any moment; his dealt combo is always in it.
    public private(set) var villainCombos: [[Card]]

    public var board: [Card] { Array(fullBoard.prefix(street)) }
    public var policy: PostflopPolicy { villain.postflop }

    // MARK: dealing

    /// Internal so tests can pin fixtures; the public entry is `TableDealer.deal`.
    init(villainSeat: Position, heroSeat: Position, villain: Archetype,
         hero: [Card], villainCombo: [Card], fullBoard: [Card], handSeed: UInt64) {
        self.villainSeat = villainSeat; self.heroSeat = heroSeat; self.villain = villain
        self.hero = hero; self.villainCombo = villainCombo; self.fullBoard = fullBoard
        self.handSeed = handSeed

        pot = TableHand.openSize + TableHand.deadBlinds
        heroStack = TableHand.stack
        villainStack = TableHand.stack - TableHand.openSize
        heroInvested = 0
        villainCombos = villain.raiseRange(from: villainSeat).combos(removing: hero)
        history.append("프리플랍 · \(villainSeat.rawValue) \(villain.name) "
                       + "\(bbText(TableHand.openSize))bb 오픈")
        phase = .hero(.open(TableHand.openSize))
    }

    /// R5 §3: the chart verdict for a preflop choice — grading here is the chart,
    /// not bb, because preflop future-value is exactly what the checkdown model
    /// cannot price (the reason S4 scripted this street).
    public struct PreflopVerdict: Equatable {
        public let chosen: DefendAction
        public let chart: DefendAction
        public var matched: Bool { chosen == chart }
    }

    public func preflopVerdict(for choice: HeroChoice) -> PreflopVerdict? {
        guard case .hero(.open) = phase else { return nil }
        let chosen: DefendAction
        switch choice {
        case .fold: chosen = .fold
        case .call: chosen = .call
        case .raise: chosen = .threeBet
        default: return nil
        }
        return PreflopVerdict(chosen: chosen,
                              chart: DefendChart.action(for: hero, vsOpenFrom: villainSeat))
    }

    // MARK: villain, who is S3 verbatim

    /// The bucket the *policy* sees. One correction over the raw classification: a
    /// draw with no cards to come is air. "Four to a flush" stays factually true on a
    /// river, but its future value is zero — and without the collapse a TAG would
    /// bluff busted draws by accident of classification. With it, river bluffing
    /// follows from each archetype's own air row: LAG and 매니악 still fire, TAG and
    /// Nit give up. (The wrinkle both S3 and S4 specs deferred, resolved here.)
    private func bucket(of combo: [Card]) -> MadeHand {
        let raw = madeHand(hand: combo, board: board)
        return street == 5 && raw == .draw ? .air : raw
    }

    private var villainBucket: MadeHand { bucket(of: villainCombo) }

    /// Keep only combos whose policy action matches what was just observed — the S3
    /// inversion, applied per street as it happens.
    private mutating func narrow(_ keep: (MadeHand) -> Bool) {
        villainCombos = villainCombos.filter { keep(bucket(of: $0)) }
    }

    private mutating func revealBoard() {
        let visible = board
        villainCombos.removeAll { $0.contains(where: visible.contains) }
    }

    private var streetName: String {
        switch street {
        case 0: return "프리플랍"
        case 3: return "플랍"
        case 4: return "턴"
        default: return "리버"
        }
    }

    /// New street: villain is out of position and acts first.
    private mutating func villainOpensStreet() {
        raisesThisStreet = 0
        heroPutThisStreet = 0
        let p = policy
        if p.opens(with: villainBucket) {
            let b = clampedBet(p.betFraction * pot,
                               cap: min(villainStack, heroStack))
            villainStack -= b
            pot += b
            narrow { p.opens(with: $0) }
            history.append("\(streetName) · \(villain.name) \(bbText(b))bb 벳 "
                           + "(팟의 \(pctText(policy.betFraction * 100))%)")
            phase = .hero(.bet(b))
        } else {
            narrow { !p.opens(with: $0) }
            history.append("\(streetName) · \(villain.name) 체크")
            phase = .hero(.checkedTo)
        }
    }

    private func clampedBet(_ amount: Double, cap: Double) -> Double {
        min(amount, cap)
    }

    // MARK: hero acts

    public enum HeroChoice: Hashable {
        case fold, check, call
        /// Fraction of pot from the decisions.md §A menu.
        case bet(Double)
        /// To 3× the outstanding bet.
        case raise
    }

    /// What hero must put in to continue, or nil when nothing is owed.
    ///
    /// The same arithmetic `gradedOptions()` uses to label the 콜 button, exposed
    /// because the table prices pot odds off it and `heroPutThisStreet` is private —
    /// a view cannot derive the raise case on its own.
    public var toCall: Double? {
        guard case let .hero(facing) = phase else { return nil }
        switch facing {
        case let .open(b):      return b
        case .checkedTo:        return nil
        case let .bet(b):       return b
        case let .raise(to: r): return r - heroPutThisStreet
        }
    }

    /// Legal choices in the current phase. Empty exactly when the hand is over.
    public func choices() -> [HeroChoice] {
        guard case let .hero(facing) = phase else { return [] }
        switch facing {
        case .open:
            return [.fold, .call, .raise]
        case .checkedTo:
            let sizes = BetSpotGenerator.fractions.filter {
                clampedBet($0 * pot, cap: min(heroStack, villainStack)) > 0.5
            }
            // Clamping can collapse several fractions onto the same all-in amount;
            // keep the first of each resolved size so the menu never shows twins.
            var seen = Set<Int>()
            let distinct = sizes.filter {
                let b = clampedBet($0 * pot, cap: min(heroStack, villainStack))
                return seen.insert(Int((b * 100).rounded())).inserted
            }
            return [.check] + distinct.map { .bet($0) }
        case let .bet(b):
            var out: [HeroChoice] = [.fold, .call]
            if raisesThisStreet == 0 && raiseSize(over: b) > b * 1.5 { out.append(.raise) }
            return out
        case .raise:
            return [.fold, .call]
        }
    }

    /// Raise-to amount, clamped by both stacks (hero pays it all; villain must be
    /// able to at least mostly cover the difference for the raise to mean anything).
    private func raiseSize(over bet: Double) -> Double {
        min(bet * TableHand.raiseFactor, heroStack + heroPutThisStreet,
            villainStack + bet)
    }

    /// Advance the hand. Transition only — grading lives in `gradedOptions()`.
    public mutating func play(_ choice: HeroChoice) {
        guard case let .hero(facing) = phase else { return }
        switch (facing, choice) {
        case (.open, .fold):
            // Nothing invested: blinds are dead money in this format, so a preflop
            // fold nets exactly 0 — and the grade says folding junk costs nothing.
            history.append("프리플랍 · 나 폴드")
            finish(heroWins: false, showdown: false)
        case let (.open(b), .call):
            heroStack -= b; heroInvested += b; pot += b
            history.append("프리플랍 · 나 콜")
            startFlop()
        case let (.open(b), .raise):
            let r = b * TableHand.raiseFactor
            heroStack -= r; heroInvested += r; pot += r
            raisesThisStreet += 1
            history.append("프리플랍 · 나 \(bbText(r))bb 3벳")
            villainRespondsTo3Bet(to: r, hisOpen: b)
        case (.checkedTo, .check):
            history.append("\(streetName) · 나 체크")
            settleStreet()
        case let (.checkedTo, .bet(f)):
            let b = clampedBet(f * pot, cap: min(heroStack, villainStack))
            heroStack -= b; heroInvested += b; heroPutThisStreet += b; pot += b
            history.append("\(streetName) · 나 \(bbText(b))bb 벳")
            villainResponds(toBet: b)
        case let (.bet(b), .fold), let (.raise(to: b), .fold):
            _ = b
            history.append("\(streetName) · 나 폴드")
            finish(heroWins: false, showdown: false)
        case let (.bet(b), .call):
            let c = min(b, heroStack)
            heroStack -= c; heroInvested += c; heroPutThisStreet += c; pot += c
            history.append("\(streetName) · 나 콜 \(bbText(c))bb")
            settleStreet()
        case let (.bet(b), .raise):
            let r = raiseSize(over: b)
            let put = r - heroPutThisStreet
            heroStack -= put; heroInvested += put; heroPutThisStreet = r; pot += put
            raisesThisStreet += 1
            history.append("\(streetName) · 나 \(bbText(r))bb 레이즈")
            villainRespondsToRaise(to: r, hisBet: b)
        case let (.raise(to: r), .call):
            let c = min(r - heroPutThisStreet, heroStack)
            heroStack -= c; heroInvested += c; heroPutThisStreet += c; pot += c
            history.append("\(streetName) · 나 콜 \(bbText(c))bb")
            settleStreet()
        default:
            assertionFailure("illegal choice \(choice) while \(facing)")
        }
    }

    private mutating func villainResponds(toBet b: Double) {
        let p = policy
        switch p.response(toBetWith: villainBucket) {
        case .fold:
            narrow { p.response(toBetWith: $0) == .fold }
            history.append("\(streetName) · \(villain.name) 폴드")
            finish(heroWins: true, showdown: false)
        case .call:
            narrow { p.response(toBetWith: $0) == .call }
            let c = min(b, villainStack)
            villainStack -= c; pot += c
            history.append("\(streetName) · \(villain.name) 콜")
            settleStreet()
        case .raise:
            // The cap: if the street already saw a raise, or the stacks make the
            // raise meaningless, the raising bucket calls instead.
            let r = min(b * TableHand.raiseFactor, villainStack, heroStack + b)
            if raisesThisStreet > 0 || r <= b * 1.5 {
                narrow { p.response(toBetWith: $0) != .fold }
                let c = min(b, villainStack)
                villainStack -= c; pot += c
                history.append("\(streetName) · \(villain.name) 콜")
                settleStreet()
            } else {
                narrow { p.response(toBetWith: $0) == .raise }
                villainStack -= r; pot += r
                raisesThisStreet += 1
                history.append("\(streetName) · \(villain.name) \(bbText(r))bb 레이즈")
                phase = .hero(.raise(to: r))
            }
        }
    }

    /// Villain facing hero's raise: the cap means he can only fold or call, and a
    /// bucket that would have re-raised calls.
    private mutating func villainRespondsToRaise(to r: Double, hisBet b: Double) {
        let p = policy
        if p.response(toBetWith: villainBucket) == .fold {
            narrow { p.response(toBetWith: $0) == .fold }
            history.append("\(streetName) · \(villain.name) 폴드")
            finish(heroWins: true, showdown: false)
        } else {
            narrow { p.response(toBetWith: $0) != .fold }
            let c = min(r - b, villainStack)
            villainStack -= c; pot += c
            history.append("\(streetName) · \(villain.name) 콜")
            settleStreet()
        }
    }

    private mutating func startFlop() {
        street = 3
        revealBoard()
        villainOpensStreet()
    }

    /// R5 §2: he continues with a top slice of the range he opened — in character,
    /// never 4-bets (capped the way the postflop re-raise already is). His call
    /// narrows the range to exactly that band; his fold ends the hand.
    private mutating func villainRespondsTo3Bet(to r: Double, hisOpen b: Double) {
        let band = villain.continueRange(vs3BetFrom: villainSeat)
        if band.contains(villainCombo) {
            villainCombos = villainCombos.filter(band.contains)
            let c = min(r - b, villainStack)
            villainStack -= c; pot += c
            history.append("프리플랍 · \(villain.name) 콜")
            startFlop()
        } else {
            history.append("프리플랍 · \(villain.name) 폴드")
            finish(heroWins: true, showdown: false)
        }
    }

    private mutating func settleStreet() {
        if street == 5 { return showdown() }
        // All-in: no more betting is possible, so the board simply runs out. Without
        // this the next street would open on a 0bb "bet" and a menu of nothing.
        if min(heroStack, villainStack) < 0.5 {
            while street < 5 { street += 1; revealBoard() }
            history.append("올인 · 남은 보드 공개")
            return showdown()
        }
        street += 1
        revealBoard()
        villainOpensStreet()
    }

    private mutating func showdown() {
        // On a complete board this is a single comparison: 1, 0.5 or 0.
        let e = exactEquityHeadsUp(hero: hero, villain: villainCombo,
                                   board: fullBoard).equity
        if e == 0.5 {
            phase = .over(Outcome(heroNet: pot / 2 - heroInvested, wentToShowdown: true,
                                  villainHand: villainCombo, heroWon: nil))
        } else {
            finish(heroWins: e > 0.5, showdown: true)
        }
    }

    private mutating func finish(heroWins: Bool, showdown: Bool) {
        let net = heroWins ? pot - heroInvested : -heroInvested
        phase = .over(Outcome(heroNet: net, wentToShowdown: showdown,
                              villainHand: villainCombo, heroWon: heroWins))
    }
}

// MARK: - grading, under the checkdown model

/// One priced choice — `DecisionOption` plus the choice it prices, so the UI's
/// buttons and S2's grader read from the same list.
public struct GradedOption: Equatable {
    public let choice: TableHand.HeroChoice
    public let label: String
    public let ev: Double

    public var option: DecisionOption { DecisionOption(label: label, ev: ev) }
}

public extension TableHand {
    /// Hero's checkdown equity against each surviving combo (spec §3): exact on the
    /// river and turn, fixed-seed Monte Carlo on the flop where exact enumeration is
    /// a debug-build freeze. Deterministic per hand.
    func comboEquities() -> [Double] {
        villainCombos.enumerated().map { i, combo in
            street >= 4
                // River: one comparison. Turn: 44 rivers. Both exact and cheap.
                ? exactEquityHeadsUp(hero: hero, villain: combo, board: board).equity
                : monteCarloEquityHeadsUp(
                    hero: hero, villain: combo, board: board, iterations: 200,
                    seed: handSeed &+ UInt64(street) &* 0x9E37 &+ UInt64(i)).equity
        }
    }

    /// Every legal choice, priced against the narrowed range. The slow call — the UI
    /// runs it off the main thread on a copy and hands the result to `graded(_:with:)`.
    func gradedOptions() -> [GradedOption] {
        guard case let .hero(facing) = phase else { return [] }
        // Preflop is graded by the chart (preflopVerdict), never priced — see spec §3.
        if case .open = facing { return [] }
        let eq = comboEquities()
        let n = Double(villainCombos.count)
        guard n > 0 else { return [] }

        // Grading must see the same buckets the bot acts on — bucket(of:), not the
        // raw classification, or a river grade would price a bluff the bot cannot make.
        func mean(_ f: (Double, MadeHand) -> Double) -> Double {
            zip(eq, villainCombos).reduce(0) { acc, pair in
                acc + f(pair.0, bucket(of: pair.1))
            } / n
        }

        switch facing {
        case .open:
            return []   // unreachable — the early return above already handled it
        case .checkedTo:
            var out = [GradedOption(choice: .check, label: "체크",
                                    ev: mean { e, _ in e * pot })]
            for case let .bet(f) in choices() {
                let b = min(f * pot, heroStack, villainStack)
                let ev = mean { e, bucket in
                    switch policy.response(toBetWith: bucket) {
                    case .fold: return pot
                    case .call: return e * (pot + 2 * b) - b
                    case .raise:
                        let r = min(b * TableHand.raiseFactor, villainStack,
                                    heroStack + b)
                        if raisesThisStreet > 0 || r <= b * 1.5 {
                            return e * (pot + 2 * b) - b        // capped to a call
                        }
                        // Hero's best continuation at the subnode, per combo.
                        return max(-b, e * (pot + 2 * r) - r)
                    }
                }
                out.append(GradedOption(choice: .bet(f),
                                        label: "벳 \(bbText(b))bb (\(pctText(f * 100))%)",
                                        ev: ev))
            }
            return out

        case let .bet(b):
            var out = [
                GradedOption(choice: .fold, label: "폴드", ev: 0),
                GradedOption(choice: .call, label: "콜 \(bbText(b))bb",
                             ev: mean { e, _ in callEV(equity: e, toCall: b, pot: pot) }),
            ]
            if choices().contains(.raise) {
                let r = raiseSize(over: b)
                let ev = mean { e, bucket in
                    // His bet already narrowed the range; the response row decides
                    // the subtree, with the re-raise capped to a call.
                    policy.response(toBetWith: bucket) == .fold
                        ? pot
                        : e * (pot - b + 2 * r) - r
                }
                out.append(GradedOption(choice: .raise,
                                        label: "레이즈 \(bbText(r))bb", ev: ev))
            }
            return out

        case let .raise(to: r):
            let c = r - heroPutThisStreet
            return [
                GradedOption(choice: .fold, label: "폴드", ev: 0),
                GradedOption(choice: .call, label: "콜 \(bbText(c))bb",
                             ev: mean { e, _ in callEV(equity: e, toCall: c, pot: pot) }),
            ]
        }
    }

    /// S2's grade over a priced list. Split from `play(_:)` so the caller can grade
    /// with precomputed options and never pay the equity pass twice.
    static func graded(_ choice: HeroChoice, with options: [GradedOption]) -> EVLossGrade? {
        guard let idx = options.firstIndex(where: { $0.choice == choice }) else { return nil }
        return gradeByEVLoss(chosen: idx, options: options.map(\.option))
    }
}

// MARK: - dealing

public enum TableDealer {
    /// Deterministic: same (seed, index, villain) → the same hand, bot line and
    /// grades. `villain: nil` draws one — the 랜덤 door on the picker.
    public static func deal(baseSeed: UInt64, index: Int,
                            villain: Archetype? = nil) -> TableHand {
        var rng = SplitMix64(seed: baseSeed
            &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15)
        let archetype = villain ?? Archetype.allCases.randomElement(using: &rng)!

        // Villain opens, someone must act behind him; hero sits behind (spec §1).
        let openers = RFIChart.seats.filter { seat in
            RFIChart.seats.contains {
                $0.playersBehind(preflop: true) < seat.playersBehind(preflop: true)
            }
        }
        let vSeat = openers.randomElement(using: &rng)!
        let hSeat = RFIChart.seats.filter {
            $0.playersBehind(preflop: true) < vSeat.playersBehind(preflop: true)
        }.randomElement(using: &rng)!

        var full = Deck.all
        full.shuffle(using: &rng)
        let hero = Array(full[0..<2])
        let combo = archetype.raiseRange(from: vSeat)
            .combos(removing: hero).randomElement(using: &rng)!
        var deck = Deck.all.filter { !hero.contains($0) && !combo.contains($0) }
        deck.shuffle(using: &rng)

        return TableHand(villainSeat: vSeat, heroSeat: hSeat, villain: archetype,
                         hero: hero, villainCombo: combo,
                         fullBoard: Array(deck[0..<5]), handSeed: rng.next())
    }
}
