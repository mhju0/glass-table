// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

public enum ChipUnitContent {
    public static let coachHand = playedPot(8, flopBet: 5, turnBet: 7, seed: 57)

    static func activities(for lesson: TableCourseLesson) -> [TableCourseActivity] {
        switch lesson {
        case .d1:
            let example = play([.call])
            return [
                TableCourseActivity(id: "D1-example", title: t("내 칩과 팟", "Your stack and the pot"),
                                    prompt: t("A에게는 칩 98개가 남아 있어요. A와 B가 이미 낸 칩 4개는 팟에 있어요.",
                                              "A has 98 chips behind. The 4 chips A and B already paid are in the pot."),
                                    evidence: evidence(example, showPot: true)),
                stack("D1-01", hand: play([]), seat: 0),
                stack("D1-02", hand: play([.raise(to: 6)]), seat: 0),
                stack("D1-03", hand: play([.raise(to: 8), .call]), seat: 1)
            ]
        case .d2:
            let example = playedPot(6, flopBet: 4, turnBet: 6)
            return [
                TableCourseActivity(id: "D2-example", title: t("낸 칩을 한 번씩 더해요", "Add each payment once"),
                                    prompt: t("B가 낸 스몰 블라인드 1개와 A, C, D가 각각 낸 6개를 더하면 팟은 19개예요. C의 6개에는 빅 블라인드 2개가 이미 들어 있어요.",
                                              "B paid a 1-chip small blind and A, C, and D each paid 6, so the pot is 19. C’s 6 already includes the 2-chip big blind."),
                                    evidence: evidence(example, through: .preflop, showPot: true)),
                TableCourseActivity(id: "D2-example-flop", title: t("플랍에서 더한 칩", "What the flop adds"),
                                    prompt: t("플랍에 D와 A가 4개씩 냈어요. 프리플랍 팟 19개에 4개씩 더하면 27개예요. C가 전에 낸 6개는 19개에 이미 들어 있어요.",
                                              "D and A each paid 4 on the flop. Add both payments to the preflop pot: 19 + 4 + 4 = 27. The 19 already includes the 6 C paid before folding."),
                                    evidence: evidence(example, through: .flop, showPot: true)),
                pot("D2-01", hand: play([])),
                pot("D2-02", hand: playedPot(8, flopBet: 4, turnBet: 6), after: 5),
                pot("D2-03", hand: playedPot(6, flopBet: 5, turnBet: 8), after: 8)
            ]
        case .d3:
            let example = raisedSpot(open: 4, facing: 6)
            return [
                TableCourseActivity(id: "D3-example", title: t("레이즈는 이번 라운드의 합계예요", "Raise to a new total"),
                                    prompt: t("D는 이번 라운드에 칩 4개를 이미 냈어요. 10개로 레이즈하려면 6개를 더 내요. 4 + 6 = 10이에요.",
                                              "D has already paid 4 this round. To raise to 10, D adds 6. The new total is 4 + 6 = 10."),
                                    evidence: evidence(example)),
                raise("D3-01", open: 5, facing: 8, to: 12),
                raise("D3-02", open: 6, facing: 10, to: 18),
                raise("D3-03", open: 7, facing: 12, to: 20)
            ]
        case .d4:
            let example = playedPot(6, flopBet: 4, turnBet: 6)
            return [
                TableCourseActivity(id: "D4-example", title: t("폴드해도 팟의 칩은 그대로예요",
                                                               "A fold leaves paid chips in the pot"),
                                    prompt: t("B는 스몰 블라인드 1개를 낸 뒤 폴드했어요. B는 이 핸드에서 더 이상 플레이할 수 없지만 1개는 팟에 남아요.",
                                              "B folded after paying the 1-chip small blind. B is out of the hand and the chip stays in the pot."),
                                    evidence: evidence(prefix(example, after: 3))),
                folded("D4-01", hand: play([.raise(to: 6), .fold]), seat: 1),
                folded("D4-02", hand: playedPot(8, flopBet: 4, turnBet: 6), after: 9, seat: 2),
                folded("D4-03", hand: playedPot(10, flopBet: 5, turnBet: 6), after: 9, seat: 2)
            ]
        case .d5:
            let example = raisedSpot(open: 4, facing: 10)
            return [
                TableCourseActivity(id: "D5-example", title: t("맞추려면 몇 개 더 내야 할까요?",
                                                               "Find how many more chips match the wager"),
                                    prompt: t("D가 이번 라운드에 낸 칩은 4개예요. 맞춰야 할 금액은 10개이니 콜하려면 10 − 4 = 6개를 더 내요.",
                                              "D has paid 4 this round. The wager to match is 10, so calling costs 10 − 4 = 6 more."),
                                    evidence: evidence(example)),
                call("D5-01", hand: raisedSpot(open: 4, facing: 8)),
                call("D5-02", hand: raisedSpot(open: 6, facing: 13)),
                call("D5-03", hand: play([.call, .check, .check, .raise(to: 5)], seats: 2))
            ]
        case .d6:
            return checkpoint
        default:
            return []
        }
    }

    static func reviewActivities(for lesson: TableCourseLesson) -> [TableCourseActivity] {
        switch lesson {
        case .d1:
            return [
                stack("DR1-01", hand: play([.raise(to: 7)], startingStack: 40), seat: 0),
                stack("DR1-02", hand: play([.call, .check, .raise(to: 4)], startingStack: 60), seat: 1),
                stack("DR1-03", hand: play([.raise(to: 12), .call], startingStack: 80), seat: 0)
            ]
        case .d2:
            return [
                pot("DR2-01", hand: play([.call, .check, .raise(to: 7), .call])),
                pot("DR2-02", hand: playedPot(9, flopBet: 4, turnBet: 6, seed: 45), after: 5),
                pot("DR2-03", hand: playedPot(11, flopBet: 7, turnBet: 6, seed: 45), after: 8)
            ]
        case .d3:
            return [
                raise("DR3-01", open: 5, facing: 10, to: 16),
                raise("DR3-02", open: 8, facing: 15, to: 24),
                raise("DR3-03", open: 9, facing: 18, to: 28)
            ]
        case .d4:
            return [
                folded("DR4-01", hand: play([.raise(to: 7), .call, .check, .raise(to: 4), .fold]), seat: 1),
                folded("DR4-02", hand: playedPot(12, flopBet: 4, turnBet: 6, seed: 34), after: 9, seat: 2),
                folded("DR4-03", hand: playedPot(14, flopBet: 3, turnBet: 5, seed: 35), after: 9, seat: 2)
            ]
        case .d5:
            return [
                call("DR5-01", hand: raisedSpot(open: 5, facing: 9)),
                call("DR5-02", hand: raisedSpot(open: 7, facing: 15)),
                call("DR5-03", hand: play([.call, .check, .raise(to: 3), .raise(to: 9)]))
            ]
        default:
            return []
        }
    }

    private static let checkpoint: [TableCourseActivity] = {
        let example = play([.call, .check, .raise(to: 4), .call])
        let hand = play([.call, .raise(to: 6), .fold, .call, .call,
                         .check, .raise(to: 4), .call, .fold,
                         .raise(to: 3), .raise(to: 7), .raise(to: 13), .call,
                         .check, .check], seats: 4)
        let stages: [(PracticeStreet, TableCourseText, TableCourseText)] = [
            (.preflop, t("프리플랍", "Preflop"),
             t("B는 스몰 블라인드를 낸 뒤 폴드했어요. C의 이번 라운드 합계에는 빅 블라인드가 들어 있어요.",
               "B folded after posting the small blind. C’s amount for the round includes the big blind.")),
            (.flop, t("플랍", "Flop"),
             t("D가 벳하고 A가 콜했어요. C는 폴드했고 프리플랍에 낸 칩은 팟에 남아요.",
               "D bet and A called. C folded and the chips C paid before the flop stay in the pot.")),
            (.turn, t("턴", "Turn"),
             t("D가 벳하자 A가 레이즈했어요. D가 다시 레이즈하고 A가 콜해서 둘 다 13개씩 냈어요.",
               "D bet, A raised, and D raised again. A called, so each paid 13 on the turn.")),
            (.river, t("리버", "River"),
             t("D와 A가 모두 체크했어요. 리버에서 팟에 더 들어간 칩은 없어요.",
               "D and A both checked. No chips went into the pot on the river."))
        ]
        let frames = stages.map { street, title, prompt in
            TableCourseActivity(id: "D6-replay-\(street.rawValue)", title: title, prompt: prompt,
                                evidence: evidence(hand, through: street))
        }
        let flop = prefix(hand, after: 9)
        return [
            TableCourseActivity(id: "D6-example", title: t("라운드가 바뀌어도 팟은 이어져요",
                                                           "The pot carries over between rounds"),
                                prompt: t("프리플랍에 A와 B가 2개씩, 플랍에 4개씩 냈어요. 두 라운드의 칩을 합치면 팟은 12개예요.",
                                          "A and B each put in 2 before the flop, then 4 on the flop. Across both rounds the pot is 12."),
                                evidence: evidence(example, through: .flop, showPot: true))
        ] + frames + [
            pot("D6-01", hand: hand),
            folded("D6-02", hand: flop, through: .flop, seat: 2),
            stack("D6-03", hand: hand, seat: 0, beforePayout: true),
            raise("D6-04", hand: prefix(hand, after: 11), to: 13),
            call("D6-05", hand: prefix(hand, after: 12))
        ]
    }()

    static let milestone: [TableCourseActivity] = {
        let hand = coachHand
        let flopStart = prefix(hand, after: 5)
        let beforeCall = prefix(hand, after: 7)
        let results = hand.review!
        let showdownRows = [0, 3].map { seat in
            TableCourseRow(label(seat), cardLabels(results.holeCards[seat]))
        }
        let winners = results.pots[0].winners
        let result = winners.count == 1
            ? t("\(letters[winners[0]])의 베스트 5가 더 강해서 팟을 가져가요.",
                "\(letters[winners[0]]) has the stronger best five and wins the pot.")
            : t("두 사람의 베스트 5가 같아서 팟을 나눠 가져가요.",
                "Their best fives tie, so they split the pot.")
        return [
            TableCourseActivity(id: "D-table-01", title: t("연습 테이블 · 플랍", "Practice table · flop"),
                                prompt: t("플랍에서 누가 먼저 액션하나요?", "Who acts first on the flop?"),
                                evidence: evidence(flopStart),
                                choices: [label(0), label(2), label(3)], correctChoice: 1,
                                explanation: t("버튼은 A예요. 버튼 왼쪽의 B는 폴드했으니 그다음인 C가 먼저 액션해요.",
                                               "A has the button. B, immediately to its left, has folded, so C is first to act.")),
            call("D-table-02", hand: beforeCall, title: t("연습 테이블 · 콜", "Practice table · call")),
            TableCourseActivity(id: "D-table-03", title: t("연습 테이블 · 쇼다운", "Practice table · showdown"),
                                prompt: t("A와 D가 리버에서 모두 체크했어요. 쇼다운에서는 무엇으로 팟의 주인을 정할까요?",
                                          "A and D both checked the river. What decides who wins the pot at showdown?"),
                                evidence: evidence(hand),
                                choices: [t("남은 칩이 더 많은 사람", "Who has more chips behind"),
                                          t("마지막에 액션한 사람", "Who acted last"),
                                          t("남은 사람들의 베스트 5", "The remaining players’ best five cards")],
                                correctChoice: 2, explanation: result,
                                revealedEvidence: evidence(hand, rows: showdownRows, showPot: true))
        ]
    }()

    private static func stack(_ id: String, hand: PracticeTableState, seat: Int,
                              beforePayout: Bool = false) -> TableCourseActivity {
        let count = hand.startingStack - hand.seats[seat].committed
        let name = letters[seat]
        return numeric(id, title: t("스택에 남은 칩", "Find the chips behind"),
                       prompt: beforePayout
                       ? t("팟을 가져가기 직전, \(name)에게 남은 칩은 몇 개인가요?",
                           "Before the pot is awarded, how many chips does \(name) have behind?")
                       : t("\(name)에게 아직 남은 칩은 몇 개인가요?", "How many chips does \(name) still have behind?"),
                       evidence: evidence(hand, showPot: !beforePayout), answer: count,
                       distractors: [hand.seats[seat].committed, hand.startingStack],
                       explanation: t("\(name)의 스택에는 아직 낼 수 있는 칩 \(count)개가 있어요. 이미 낸 칩은 팟에 들어갔어요.",
                                      "\(name) has \(count) chips available to play. Their earlier payments are in the pot."))
    }

    private static func pot(_ id: String, hand: PracticeTableState, after actions: Int? = nil) -> TableCourseActivity {
        let spot = actions.map { prefix(hand, after: $0) } ?? hand
        let payments = spot.seats.map(\.committed).filter { $0 > 0 }
        let equation = payments.map(String.init).joined(separator: " + ") + " = \(spot.pot)"
        return numeric(id, title: t("팟을 세어요", "Count the pot"),
                       prompt: t("지금 팟에는 칩이 몇 개 있나요?", "How many chips are in the pot now?"),
                       evidence: evidence(spot), answer: spot.pot,
                       distractors: [payments.max() ?? 0, spot.pot + 2],
                       explanation: t("\(equation)이에요. 각자 낸 칩의 합계를 한 번씩만 더해요.",
                                      "\(equation). Add each player’s total payment once."),
                       revealedEvidence: evidence(spot, showPot: true))
    }

    private static func raise(_ id: String, open: Int, facing: Int, to target: Int) -> TableCourseActivity {
        raise(id, hand: raisedSpot(open: open, facing: facing), to: target)
    }

    private static func raise(_ id: String, hand: PracticeTableState, to target: Int) -> TableCourseActivity {
        let seat = hand.currentSeat!
        let actor = letters[seat]
        let paid = hand.seats[seat].streetCommitted
        let facing = hand.seats.map(\.streetCommitted).max()!
        let amount = target - paid
        return numeric(id, title: t("레이즈로 더 낼 칩", "Find what a raise adds"),
                       prompt: t("\(actor)가 \(target)개로 레이즈하려면 칩을 몇 개 더 내야 할까요?",
                                 "How many more chips must \(actor) add to raise to \(target)?"),
                       evidence: evidence(hand), answer: amount, distractors: [target, target - facing],
                       explanation: t("\(actor)가 이번 라운드에 \(paid)개를 냈으니 \(target) − \(paid) = \(amount)개를 더 내요.",
                                      "\(actor) has paid \(paid) this round. Add \(target) − \(paid) = \(amount) more."))
    }

    private static func folded(_ id: String, hand: PracticeTableState, after actions: Int? = nil,
                               through street: PracticeStreet? = nil, seat: Int) -> TableCourseActivity {
        let spot = actions.map { prefix(hand, after: $0) } ?? hand
        let count = spot.seats[seat].committed
        let name = letters[seat]
        return numeric(id, title: t("폴드 뒤에 남는 칩", "Track a folded player’s chips"),
                       prompt: t("\(name)가 낸 칩 중 몇 개가 팟에 남아 있나요?",
                                 "How many chips paid by \(name) are still in the pot?"),
                       evidence: evidence(spot, through: street), answer: count, distractors: [0, spot.seats[seat].stack],
                       explanation: t("\(name)가 이미 낸 \(count)개는 팟에 남아요. 폴드해도 이미 낸 칩은 돌려받지 않아요.",
                                      "The \(count) chips \(name) already paid stay in the pot when they fold."))
    }

    private static func call(_ id: String, hand: PracticeTableState,
                             title: TableCourseText = t("콜할 때 더 낼 칩", "Find the call amount")) -> TableCourseActivity {
        let current = hand.currentSeat!
        let actor = letters[current]
        let alreadyPaid = hand.seats[current].streetCommitted
        let wager = hand.seats.map(\.streetCommitted).max()!
        let amount = hand.amountToCall
        return numeric(id, title: title,
                       prompt: t("\(actor)가 콜하려면 칩을 몇 개 더 내야 할까요?", "How many more chips must \(actor) add to call?"),
                       evidence: evidence(hand), answer: amount,
                       distractors: alreadyPaid == 0 ? [hand.pot, amount + 2] : [wager, 0],
                       explanation: t("이번 라운드에 \(alreadyPaid)개를 냈어요. \(wager) − \(alreadyPaid) = \(amount)개를 더 내면 돼요.",
                                      "They have paid \(alreadyPaid) this round. Calling costs \(wager) − \(alreadyPaid) = \(amount) more."))
    }

    private static func numeric(_ id: String, title: TableCourseText, prompt: TableCourseText,
                                evidence: TableCourseEvidence, answer: Int, distractors: [Int],
                                explanation: TableCourseText, revealedEvidence: TableCourseEvidence? = nil) -> TableCourseActivity {
        let sorted = ([answer] + distractors).sorted()
        let shift = (id.last?.wholeNumberValue ?? 0) % sorted.count
        let values = Array(sorted[shift...]) + sorted[..<shift]
        return TableCourseActivity(id: id, title: title, prompt: prompt, evidence: evidence,
                                   choices: values.map(chips), correctChoice: values.firstIndex(of: answer),
                                   explanation: explanation, revealedEvidence: revealedEvidence)
    }

    private static func playedPot(_ raise: Int, flopBet: Int, turnBet: Int,
                                  seed: UInt64 = 29) -> PracticeTableState {
        play([.call, .raise(to: raise), .fold, .call, .call,
              .check, .raise(to: flopBet), .call, .fold,
              .check, .raise(to: turnBet), .call, .check, .check], seats: 4, seed: seed)
    }

    private static func raisedSpot(open: Int, facing: Int) -> PracticeTableState {
        play([.raise(to: open), .raise(to: facing), .fold, .call], seats: 4)
    }

    private static func play(_ actions: [PracticeAction], seats: Int = 2, seed: UInt64 = 29,
                             startingStack: Int = 100) -> PracticeTableState {
        var table = PracticeTableState(seed: seed, styles: Array(repeating: .tag, count: seats - 1),
                                       startingStack: startingStack)
        for (index, action) in actions.enumerated() {
            try! table.apply(action, actionID: "chip-\(index)")
        }
        return table
    }

    private static func prefix(_ hand: PracticeTableState, after actions: Int) -> PracticeTableState {
        let moves = hand.events.compactMap(\.action)
        return play(Array(moves.prefix(actions)), seats: hand.seatCount, seed: hand.seed,
                    startingStack: hand.startingStack)
    }

    private static func evidence(_ hand: PracticeTableState, through street: PracticeStreet? = nil,
                                 rows: [TableCourseRow] = [], showPot: Bool = false) -> TableCourseEvidence {
        let steps = hand.replaySteps
        var frameCount = steps.count - (hand.review == nil ? 0 : 1)
        // Finish each replay stage before the deal for the next street clears its payments.
        if let street, let lastAction = steps.lastIndex(where: { step in
            guard case let .action(index) = step else { return false }
            return hand.events[index].street == street
        }) {
            frameCount = lastAction + 1
        }
        let frame = hand.frame(after: frameCount)
        let seats = hand.seats.indices.map { seat in
            let round = frame.streetCommitted[seat]
            let total = frame.committed[seat]
            let detail = frame.street == .preflop
                ? t("낸 칩 \(total)개", "Paid \(total)")
                : t("이번 라운드 \(round)개 · 전체 \(total)개", "\(round) this round · \(total) total")
            return TableCourseSeat(label(seat), detail: detail, chips: frame.stacks[seat],
                                   folded: frame.folded[seat])
        }
        let potRow = showPot ? [TableCourseRow(t("팟 합계", "Total pot"), chips(frame.pot))] : []
        let board = hand.visibleBoard.prefix(frame.boardCount).compactMap(Card.init)
        return TableCourseEvidence(seats: seats, board: board, rows: rows + potRow)
    }

    private static let letters = ["A", "B", "C", "D"]

    private static func label(_ seat: Int) -> TableCourseText {
        let name = letters[seat]
        return seat == 0 ? t("\(name) · 버튼", "\(name) · Button") : t(name, name)
    }

    private static func chips(_ count: Int) -> TableCourseText {
        t("칩 \(count)개", count == 1 ? "1 chip" : "\(count) chips")
    }

    private static func cardLabels(_ names: [String]) -> TableCourseText {
        let symbols = ["♣", "♦", "♥", "♠"]
        let text = names.compactMap(Card.init).map { card in
            let rank = String(card.description.prefix(1))
            return "\(rank == "T" ? "10" : rank)\(symbols[card.suit])"
        }.joined(separator: " ")
        return t(text, text)
    }

    private static func t(_ ko: String, _ en: String) -> TableCourseText { TableCourseText(ko, en) }
}
