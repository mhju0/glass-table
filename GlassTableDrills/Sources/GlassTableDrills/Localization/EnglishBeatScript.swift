// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// English worked examples built from spot values. The Korean scripts remain in
/// BeatScript so existing sessions keep their familiar wording.
enum EnglishBeatScript {
    static func showdown(_ s: ShowdownSpot) -> [Beat] {
        let turn = Array(s.board.prefix(4))
        let river = Array(s.board.suffix(1))
        let myTurn = DrillTerms.hand(bestHandOfAny(s.hero + turn), in: .english)
        let theirTurn = DrillTerms.hand(bestHandOfAny(s.villain + turn), in: .english)
        let myFinal = DrillTerms.hand(s.heroBest, in: .english)
        let theirFinal = DrillTerms.hand(s.villainBest, in: .english)
        let myFive = bestFiveCards(s.hero + s.board)
        let theirFive = bestFiveCards(s.villain + s.board)
        let verdict = gradeShowdown(answer: s.winner, spot: s, language: .english)
        return [
            Beat("After the turn", detail: "Four shared cards are out. One river card remains.",
                 focus: .table, hidden: river),
            Beat("Your hand now", value: myTurn, focus: .table,
                 highlight: bestFiveCards(s.hero + turn), hidden: river),
            Beat("Opponent's hand now", value: theirTurn, focus: .table,
                 highlight: bestFiveCards(s.villain + turn), hidden: river),
            Beat("The river arrives", value: river[0].display,
                 detail: "Read both best five-card hands again.", focus: .table, highlight: river),
            Beat("Your final hand", value: myFinal,
                 detail: myTurn == myFinal ? "Its name stays the same." : "It changed from \(myTurn).",
                 focus: .table, highlight: myFive),
            Beat("Opponent's final hand", value: theirFinal,
                 detail: theirTurn == theirFinal ? "Its name stays the same." : "It changed from \(theirTurn).",
                 focus: .table, highlight: theirFive),
            Beat(s.winner == 0 ? "You win" : s.winner == 1 ? "Opponent wins" : "Tie",
                 detail: verdict.whyText, focus: .table,
                 highlight: s.winner == 0 ? myFive : s.winner == 1 ? theirFive : []),
        ]
    }

    static func outs(_ s: OutsSpot) -> [Beat] {
        let unseen = 52 - Set(s.hero + s.villain + s.board).count
        let outs = s.outs.sorted(by: BeatScript.byRank)
        let flushSuit = s.excluded.first?.suit
        let suitOuts = flushSuit.map { suit in s.outs.filter { $0.suit == suit } } ?? []
        let otherOuts = flushSuit.map { suit in s.outs.filter { $0.suit != suit } } ?? s.outs
        var beats = [
            Beat("One shared card remains", detail: "Only cards that make you win count as outs.", focus: .table),
            Beat("Your cards", focus: .table, highlight: s.hero),
            Beat("Opponent's cards", detail: "The opponent is ahead now.", focus: .table, highlight: s.villain),
        ]
        if let suit = flushSuit {
            let inHand = s.hero.filter { $0.suit == suit }
            let onBoard = s.board.filter { $0.suit == suit }
            let inVillain = s.villain.filter { $0.suit == suit }
            let remaining = suitOuts + s.excluded
            let suitName = DrillTerms.suit(suit, in: .english)
            let seen = inHand.count + onBoard.count + inVillain.count
            var subtraction = "Of 13 \(suitName), you hold \(inHand.count), the board has \(onBoard.count)"
            if !inVillain.isEmpty { subtraction += ", and the opponent has \(inVillain.count)" }
            subtraction += ". That leaves 13 − \(seen) = \(13 - seen)."

            beats.append(Beat("You can see \(inHand.count + onBoard.count) \(suitName)",
                              detail: "One more would make a flush.",
                              focus: .table, highlight: inHand + onBoard))
            beats.append(Beat("\(remaining.count) \(suitName) remain", detail: subtraction,
                              focus: .grid(remaining.sorted(by: BeatScript.byRank))))
            if !s.excluded.isEmpty {
                beats.append(Beat("But \(s.excluded.map(\.display).joined(separator: " · ")) won't win",
                                  detail: "They complete your draw but improve the opponent even more. Cross them out.",
                                  focus: .grid(remaining.sorted(by: BeatScript.byRank)),
                                  struck: s.excluded))
            }
            if !otherOuts.isEmpty {
                beats.append(Beat("\(otherOuts.count) other winning cards",
                                  detail: "A flush is not your only way to win.", focus: .grid(outs)))
            }
        } else {
            beats.append(Beat("Cards that make you win",
                              detail: "If one of these arrives on the river, you take the lead.",
                              focus: .grid(outs)))
        }
        beats.append(Beat("Your real outs", value: "\(s.outCount) cards",
                          detail: "\(s.outCount) of \(unseen) unseen cards make you win. The rule of 2 gives about \(Int(s.improvementPct))% for one card to come.",
                          focus: .grid(outs)))
        return beats
    }

    static func potMath(_ s: PotMathSpot) -> [Beat] {
        var running = 0
        var beats = [Beat("Count each new chip", detail: "Small blind and big blind go in first. A folded player's earlier chips stay in the pot.")]
        for action in s.actions {
            let before = running
            switch action {
            case let .blinds(sb, bb):
                running += sb + bb
                beats.append(Beat("Blinds", value: "\(sb) + \(bb)", detail: "Pot: \(running) chips"))
            case let .bet(actor, amount):
                running += amount
                beats.append(Beat("\(DrillTerms.actor(actor, in: .english)) bets", value: "+\(amount) chips",
                                  detail: "\(before) + \(amount) = \(running) chips"))
            case let .call(actor, amount):
                running += amount
                beats.append(Beat("\(DrillTerms.actor(actor, in: .english)) calls", value: "+\(amount) chips",
                                  detail: "\(before) + \(amount) = \(running) chips"))
            case let .raiseTo(actor, total, alreadyIn):
                let added = total - alreadyIn
                running += added
                beats.append(Beat("\(DrillTerms.actor(actor, in: .english)) raises to \(total)", value: "+\(added) chips",
                                  detail: "Count only the new chips: \(before) + \(added) = \(running)."))
            }
        }
        switch s.question {
        case .potNow:
            beats.append(Beat("Pot now", value: "\(s.pot) chips"))
        case let .fractionOfPot(fraction):
            let pct = Int((fraction * 100).rounded())
            beats.append(Beat("\(pct)% of the pot", value: "\(s.correctAnswer) chips",
                              detail: "\(s.pot) × \(pct)%, rounded to the nearest chip."))
        }
        return beats
    }

    static func position(_ s: PositionSpot) -> [Beat] {
        switch s.question {
        case let .behind(seat, preflop):
            let order = preflop ? Position.preflopOrder : Position.postflopOrder
            let after = Array(order.drop(while: { $0 != seat }).dropFirst())
            return [
                Beat(preflop ? "Order before the flop" : "Order after the flop",
                     detail: order.map(\.rawValue).joined(separator: " → ")),
                Beat("Your seat", value: seat.rawValue,
                     detail: preflop ? "The blinds act last before the flop." : "The blinds act first after the flop; the button acts last."),
                Beat("Players after you", value: "\(after.count)",
                     detail: after.isEmpty ? "You act last." : after.map(\.rawValue).joined(separator: " · ")),
                Beat("Why position matters", detail: "Acting later lets you see more decisions before yours."),
            ]
        case let .whichIsLater(a, b):
            let later = b.actsAfter(a) ? b : a
            return [Beat("Order after the flop", detail: Position.postflopOrder.map(\.rawValue).joined(separator: " → ")),
                    Beat("Compare seats", value: "\(a.rawValue) vs \(b.rawValue)"),
                    Beat("Later seat", value: later.rawValue,
                         detail: "This seat sees the other player's action first.")]
        }
    }

    static func combos(_ s: BlockerSpot) -> [Beat] {
        let kind: String
        switch s.kind {
        case .pair: kind = "A pair begins with 6 two-card combinations."
        case .suited: kind = "One combination per suit gives 4 same-suit combinations."
        default: kind = "Two different ranks begin with 4 × 4 = 16 combinations."
        }
        let meaning: String
        switch s.kind {
        case .pair: meaning = "\(s.className) means two \(rankName(s.rankA))s."
        case .suited: meaning = "The s in \(s.className) means both cards share a suit."
        default: meaning = "\(s.className) allows any suits."
        }
        let example = s.exampleCombo.map(\.display).joined(separator: " ")
        return [
            Beat("A combo is one exact two-card hand an opponent could hold",
                 detail: "\(meaning) Fix the suits, as in \(example), and you have one combo.",
                 focus: .grid(s.exampleCombo)),
            Beat("Before visible cards", value: "\(s.className): \(s.baseline)", detail: kind),
            Beat("These cards are visible", value: s.removed.map(\.display).joined(separator: " · "),
                 focus: .grid(s.removed), highlight: s.removed),
            Beat("Remove blocked combinations", detail: "An opponent cannot hold a visible card."),
            Beat("Combinations left", value: "\(s.count)",
                 detail: whyText(for: s, language: .english)),
        ]
    }

    static func potOdds(_ s: BetSpot) -> [Beat] {
        [Beat("Price of the call", value: "\(s.bet)bb",
              detail: "The pot has \(s.pot)bb before the bet."),
         Beat("Whole pot after you call", value: "\(s.pot + s.bet * 2)bb",
              detail: "Pot \(s.pot) + their bet \(s.bet) + your call \(s.bet)."),
         Beat("Break-even winning chance", value: "\(pctText(s.requiredPct))%",
              detail: "Your call ÷ the whole pot. Call when your winning chance is higher.")]
    }

    static func mdf(_ s: BetSpot) -> [Beat] {
        [Beat("The opponent's bluff", value: "Risks \(s.bet)bb",
              detail: "They are trying to win the \(s.pot)bb pot."),
         Beat("Overall defense frequency", value: "\(pctText(s.mdfPct))%",
              detail: "Pot \(s.pot) ÷ (pot \(s.pot) + bet \(s.bet))."),
         Beat("Keep enough hands", detail: "If you fold too often across your whole range, an empty bet profits automatically. This is not an answer for one specific hand.")]
    }

    static func equitySense(_ s: EquitySenseSpot) -> [Beat] {
        let unseen = 52 - Set(s.hero + s.villain + s.board).count
        return [Beat("Both hands are visible", focus: .table),
                Beat("Your cards", focus: .table, highlight: s.hero),
                Beat("Opponent's cards", focus: .table, highlight: s.villain),
                Beat("Count possible endings", value: "\(unseen) unseen cards",
                     detail: "Count how often you win at the final reveal.", focus: .table),
                Beat("Your equity", value: "\(pctText(s.equityPct))%",
                     detail: "This comes from counting every possible ending, including shared pots.", focus: .table)]
    }

    static func evCall(_ s: EVCallSpot) -> [Beat] {
        [Beat("Average value of calling", detail: "Weigh winning and losing by how often each occurs."),
         Beat("When you win", value: "+\(s.pot + s.bet)bb",
              detail: "This happens \(pctText(s.equityPct))% of the time."),
         Beat("When you lose", value: "−\(s.bet)bb",
              detail: "This happens \(pctText(100 - s.equityPct))% of the time."),
         Beat("Call value", value: "\(pctText(s.evBB))bb",
              detail: s.isProfitable ? "The call earns chips on average." : "The call loses chips on average."),
         Beat("One result does not change it", detail: "This value describes repeated decisions, not this hand's result.")]
    }

    static func rangeNotation(_ s: RangeNotationSpot) -> [Beat] {
        var beats = [Beat("Hand shorthand", value: s.notation,
                          detail: "One label can stand for several exact two-card combinations.",
                          focus: .rangeGrid(s.range, highlight: nil)),
                     Beat("Counts by shape", detail: "A pair has 6 combinations, same suit has 4, and different suits have 12.",
                          focus: .rangeGrid(s.range, highlight: nil))]
        for hand in s.range.classes.prefix(6) {
            beats.append(Beat(hand.description, value: "\(hand.comboCount) combinations",
                              detail: hand.isPair ? "Pair" : hand.suited ? "Same suit" : "Different suits",
                              focus: .rangeGrid(s.range, highlight: hand)))
        }
        if s.range.classes.count > 6 {
            beats.append(Beat("Use the same count for the other \(s.range.classes.count - 6) hand groups",
                              focus: .rangeGrid(s.range, highlight: nil)))
        }
        beats.append(Beat("Add every class", value: "\(s.comboCount) combinations",
                          detail: "That is \(pctText(s.range.percent))% of all 1,326 starting combinations.",
                          focus: .rangeGrid(s.range, highlight: nil)))
        return beats
    }

    static func rfi(_ s: RFISpot) -> [Beat] {
        let hand = s.handClass
        let chart = RFIChart.range(for: s.seat)
        let pct = RFIChart.openPercent[s.seat] ?? 0
        return [Beat("Your hand", value: hand.description, focus: .table, highlight: s.hand),
                Beat("Your seat", value: s.seat.rawValue,
                     detail: "\(s.seat.playersBehind(preflop: true)) players still act after you.",
                     focus: .table, highlight: s.hand),
                Beat("The hand's score", value: "\(pctText(Chen.score(hand)))",
                     detail: DrillTerms.chen(hand, in: .english), focus: .table, highlight: s.hand),
                Beat("Opening range", value: "Top \(Int(pct))%",
                     detail: "The chart selects the highest-scoring hands for this seat.",
                     focus: .rangeGrid(chart, highlight: hand)),
                Beat("Chart decision", value: s.opens ? "Raise" : "Fold",
                     detail: s.opens ? "\(hand.description) is inside the \(s.seat.rawValue) opening range."
                        : "\(hand.description) is outside the \(s.seat.rawValue) opening range.",
                     focus: .rangeGrid(chart, highlight: hand))]
    }

    static func rangeRead(_ s: RangeReadSpot) -> [Beat] {
        let opened: Bool
        if case .opened = s.action { opened = true } else { opened = false }
        let opponent = s.archetype
        let range = s.trueRange
        let headline = opened ? opponent.pfr : opponent.vpip
        let lines = s.actionLines(in: .english)
        var beats = [Beat("What they did", value: opened ? "Raised first" : "Called",
                     detail: "You see the action, not their cards.",
                     focus: .actionList(lines, lit: opened ? 0 : 1)),
                Beat("Opponent's usual style", value: opponent.beginnerTitle(in: .english),
                     detail: opponent.beginnerDescription(in: .english),
                     focus: .actionList(lines, lit: nil)),
                Beat("The numbers", value: "VPIP \(Int(opponent.vpip))% · PFR \(Int(opponent.pfr))%",
                     detail: opened ? "They raise first with about \(Int(opponent.pfr))% of hands on average."
                        : "They join with \(Int(opponent.vpip))%, raise with \(Int(opponent.pfr))%, and call with the gap.",
                     focus: .actionList(lines, lit: nil)),
                Beat("Now account for the seat", value: "Top \(pctText(range.percent))%",
                     detail: "\(s.seat.playersBehind(preflop: true)) players still act after \(s.seat.rawValue). The \(Int(headline))% average becomes \(range.percent >= headline ? "wider" : "narrower") here.",
                     focus: .actionList(lines, lit: nil)),
                Beat("That gives this shape", value: "\(range.classes.count) hand classes",
                     detail: opened ? "Start from the strongest hands and include the top \(pctText(range.percent))%."
                        : "Leave out the raising hands. These hands are playable but not strong enough to raise.",
                     focus: .rangeGrid(range, highlight: nil))]
        if let lean = RangeTendency.allCases.max(by: {
            range.tendencyShare($0) < range.tendencyShare($1)
        }) {
            beats.append(Beat("Where it leans", value: DrillTerms.tendency(lean, in: .english),
                              detail: "\(Int((range.tendencyShare(lean) * 100).rounded()))% of this range is \(DrillTerms.tendency(lean, in: .english)). Shape matters as well as width.",
                              focus: .rangeGrid(range, highlight: nil)))
        }
        return beats
    }

    static func hitFrequency(_ s: HitFrequencySpot) -> [Beat] {
        let distribution = s.distribution
        let bar = BucketBar(label: "\(s.seat.rawValue) opening range", distribution: distribution)
        return [Beat("Shared cards", value: DrillTerms.board(s.texture, in: .english),
                     focus: .table, highlight: s.board),
                Beat("Opponent's starting range", value: "Top \(pctText(s.range.percent))%",
                     focus: .rangeGrid(s.range, highlight: nil)),
                Beat("After visible cards", value: "\(distribution.liveCombos) combinations",
                     detail: "An opponent cannot hold a card already on the board.",
                     focus: .table, highlight: s.board),
                Beat("Hands with a pair or better", value: "\(pctText(distribution.pairOrBetter * 100))%",
                     detail: "Read the share from the remaining combinations.",
                     focus: .buckets([bar])),
                Beat("So the answer is", value: "\(pctText(distribution.pairOrBetter * 100))%",
                     detail: "Most starting ranges miss most flops. That is why a bet can sometimes take the pot without a made hand.",
                     focus: .buckets([bar]))]
    }

    static func rangeAdvantage(_ s: RangeAdvantageSpot) -> [Beat] {
        let opener = rangeOnBoard(s.openerRange, board: s.board)
        let caller = rangeOnBoard(s.callerRange, board: s.board)
        let bars = [BucketBar(label: "\(s.openerSeat.rawValue) opening range", distribution: opener),
                    BucketBar(label: "\(s.callerSeat.rawValue) calling range", distribution: caller)]
        let equity = s.openerEquityPct
        return [Beat("Shared cards", value: DrillTerms.board(s.texture, in: .english),
                     focus: .table, highlight: s.board),
                Beat("First player's range", value: "Top \(pctText(s.openerRange.percent))%",
                     focus: .rangeGrid(s.openerRange, highlight: nil)),
                Beat("Caller's range", value: "\(pctText(s.callerRange.percent))% of hands",
                     detail: s.caller.beginnerDescription(in: .english),
                     focus: .rangeGrid(s.callerRange, highlight: nil)),
                Beat("How they connect", value: BeatScript.widestGapValue(opener: opener, caller: caller,
                                                                             language: .english),
                     detail: "Compare what each range makes on the same board.", focus: .buckets(bars)),
                Beat("First player's equity", value: "\(pctText(equity))%",
                     detail: "This compares the two full ranges, not two known hands.", focus: .buckets(bars))]
    }

    static func actionRead(_ s: ActionReadSpot) -> [Beat] {
        let full = s.full
        let acted = s.acted
        let rules = MadeHand.allCases.map {
            "\(DrillTerms.madeHand($0, in: .english)) → \(s.policy.opens(with: $0) ? "bet" : "check")"
        }
        let bars = [BucketBar(label: "Before the action", distribution: full),
                    BucketBar(label: "After the action", distribution: acted.distribution)]
        return [Beat("What happened", value: "\(s.villainSeat.rawValue) raises, then \(s.actionLine(in: .english))",
                     detail: DrillTerms.board(s.texture, in: .english), focus: .table, highlight: s.board),
                Beat("Before the action", value: "Top \(pctText(s.range.percent))%",
                     focus: .rangeGrid(s.range, highlight: nil)),
                Beat("This opponent's flop rule", detail: "Each hand group has a stated action.",
                     focus: .actionList(rules, lit: nil)),
                Beat("Hands still possible", value: "\(acted.combos) combinations",
                     detail: s.actedBucketList(in: .english), focus: .buckets(bars)),
                Beat("Pair or better after the action", value: "\(pctText(acted.distribution.pairOrBetter * 100))%",
                     detail: "Before the action: \(pctText(full.pairOrBetter * 100))%.", focus: .buckets(bars))]
    }

    static func defend(_ s: DefendSpot) -> [Beat] {
        let open = RFIChart.openPercent[s.opener] ?? 0
        return [Beat("Opponent raises first", value: "\(s.opener.rawValue) to 3bb",
                     detail: "Choose whether to fold, call, or raise again.", focus: .table),
                Beat("Hands they raise with", value: "Top \(pctText(open))%",
                     focus: .rangeGrid(RFIChart.range(for: s.opener), highlight: nil)),
                Beat("How this chart divides hands", detail: "The bands follow the width of the opponent's opening range.",
                     focus: .actionList(["Opening width \(pctText(open))%",
                                         "Top \(pctText(open * DefendChart.threeBetShare))% → raise again",
                                         "Up to \(pctText(open * DefendChart.defendShare))% → call",
                                         "Remaining hands → fold"], lit: nil)),
                Beat("Find your hand", value: s.handClass.description,
                     focus: .defendChart(opener: s.opener, highlight: s.handClass)),
                Beat("Chart choice", value: DrillTerms.action(s.correct, in: .english),
                     detail: "The table's before-flop questions use this same chart.",
                     focus: .defendChart(opener: s.opener, highlight: s.handClass))]
    }

    static func evLoss(_ s: EVLossSpot) -> [Beat] {
        let value = s.callEVbb
        return [Beat("Final shared card is out", value: "Pot \(s.pot)bb · bet \(s.bet)bb",
                     focus: .table, highlight: s.hero),
                Beat("Opponent's stated range", value: "\(s.villainSeat.rawValue) opening range",
                     detail: "This example does not narrow it by later actions.",
                     focus: .rangeGrid(s.villainRange, highlight: nil)),
                Beat("Your chance against that range", value: "\(pctText(s.equityPct))%",
                     focus: .rangeGrid(s.villainRange, highlight: nil)),
                Beat("Chance needed to call", value: "\(pctText(s.requiredPct))%",
                     detail: "Bet \(s.bet) ÷ (pot \(s.pot) + bet \(s.bet) + call \(s.bet)).", focus: .table),
                Beat("Call value", value: "\(bbText(value))bb",
                     detail: "Folding from this point is worth 0bb.", focus: .table),
                Beat("Cost of the weaker choice", value: "\(bbText(abs(value)))bb",
                     detail: "Compare the two average values, not this hand's result.", focus: .table)]
    }

    static func callFold(_ s: CallFoldSpot) -> [Beat] {
        [Beat("Price of the decision", value: "Pot \(s.pot)bb · bet \(s.bet)bb", focus: .table),
         Beat("Your winning chance", value: "\(pctText(s.equityPct))%", focus: .table, highlight: s.hero),
         Beat("Winning chance needed", value: "\(pctText(s.requiredPct))%"),
         Beat("Compare the two", value: s.correctIsCall ? "Call" : "Fold",
              detail: "\(pctText(s.equityPct))% versus \(pctText(s.requiredPct))%")]
    }
}
