// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

enum BettingUnitContent {
    static func activities(for lesson: TableCourseLesson) -> [TableCourseActivity] {
        lessonContent(for: lesson).teaching
    }

    static func reviewQuestions(for lesson: TableCourseLesson) -> [TableCourseActivity] {
        lessonContent(for: lesson).review
    }

    private typealias Copy = TableCourseText
    private typealias Activity = TableCourseActivity
    private typealias Content = (teaching: [Activity], review: [Activity])

    private static func lessonContent(for lesson: TableCourseLesson) -> Content {
        switch lesson {
        case .c1: blinds
        case .c2: preflopOrder
        case .c3: postflopOrder
        case .c4: noAmountToCall
        case .c5: facingBet
        case .c6: fullRaise
        case .c7: information
        case .c8: headsUp
        case .c9: (checkpoint, checkpointReview)
        default: ([], [])
        }
    }

    private enum Role: CaseIterable {
        case button, smallBlind, bigBlind

        var label: Copy {
            switch self {
            case .button: Copy("버튼", "Button")
            case .smallBlind: Copy("스몰 블라인드", "Small blind")
            case .bigBlind: Copy("빅 블라인드", "Big blind")
            }
        }

        func seat(in table: PracticeTableState) -> Int {
            switch self {
            case .button: table.dealer
            case .smallBlind: table.events[0].seat
            case .bigBlind: table.events[1].seat
            }
        }
    }

    private struct Spot {
        let id: String
        var table: PracticeTableState

        init(_ id: String, dealer: Int = 0, count: Int = 4, _ actions: [PracticeAction] = []) {
            let seed = id.utf8.reduce(UInt64(0)) { ($0 &* 31) &+ UInt64($1) }
            let styles = Array([Archetype.tag, .station, .lag].prefix(count - 1))
            var table = PracticeTableState(seed: seed, styles: styles, handID: id)
            // Rotate the button using complete hands so even two-player examples use live rules.
            for hand in 0..<dealer {
                while table.currentSeat != nil {
                    try! table.apply(.fold, actionID: "rotate-\(table.events.count)")
                }
                try! table.nextHand(handID: "\(id)-\(hand + 1)")
            }
            self.id = id
            self.table = table
            for action in actions { play(action) }
        }

        mutating func play(_ action: PracticeAction) {
            try! table.apply(action, actionID: "\(id)-action-\(table.events.count)")
        }

        var actor: Int { table.currentSeat! }

        var whoseTurn: Copy {
            Copy("\(actor + 1)번 자리의 차례예요.", "It’s Seat \(actor + 1)’s turn.")
        }

        func evidence(hiding hiddenRole: Role? = nil, highlight: Int? = nil,
                      extra rows: [TableCourseRow] = []) -> TableCourseEvidence {
            let seats = table.seats.indices.map { index in
                let roles = Role.allCases.filter { $0 != hiddenRole && $0.seat(in: table) == index }
                let detail: Copy?
                switch roles {
                case [.button, .smallBlind]: detail = Copy("버튼 · SB", "Button · SB")
                case [.button]: detail = Copy("버튼", "Button")
                case [.smallBlind]: detail = Copy("SB", "SB")
                case [.bigBlind]: detail = Copy("BB", "BB")
                default: detail = nil
                }
                let seat = table.seats[index]
                return TableCourseSeat(seatName(index), detail: detail,
                                       chips: seat.streetCommitted > 0 ? seat.streetCommitted : nil,
                                       folded: seat.folded, highlighted: highlight == index)
            }
            return TableCourseEvidence(seats: seats, board: table.visibleBoard.compactMap(Card.init),
                                       rows: [TableCourseRow(Copy("라운드", "Round"), streetName(table.street))] + rows)
        }

        func example(_ title: Copy, _ prompt: Copy, _ explanation: Copy,
                     highlight: Int? = nil, rows: [TableCourseRow] = []) -> Activity {
            Activity(id: id, title: title, prompt: prompt, evidence: evidence(highlight: highlight, extra: rows),
                     explanation: explanation)
        }

        func question(_ title: Copy, _ prompt: Copy, choices: [Copy], answer: Int, _ explanation: Copy,
                      hiding role: Role? = nil, highlight: Int? = nil,
                      rows: [TableCourseRow] = [], revealedEvidence: TableCourseEvidence? = nil) -> Activity {
            Activity(id: id, title: title, prompt: prompt,
                     evidence: evidence(hiding: role, highlight: highlight, extra: rows),
                     choices: choices, correctChoice: answer, explanation: explanation,
                     revealedEvidence: revealedEvidence)
        }
    }

    private static let limp: [PracticeAction] = [.call, .call, .call, .check]

    private static func seatName(_ seat: Int) -> Copy {
        Copy("\(seat + 1)번 자리", "Seat \(seat + 1)")
    }

    private static func streetName(_ street: PracticeStreet) -> Copy {
        switch street {
        case .preflop: Copy("프리플랍", "Preflop")
        case .flop: Copy("플랍", "Flop")
        case .turn: Copy("턴", "Turn")
        case .river: Copy("리버", "River")
        case .finished: Copy("핸드 종료", "Hand over")
        }
    }

    private static func chips(_ amount: Int) -> Copy {
        Copy("\(amount)개", "\(amount) \(amount == 1 ? "chip" : "chips")")
    }

    private static func blindQuestion(_ spot: Spot, role: Role) -> Activity {
        let title: Copy
        let explanation: Copy
        switch role {
        case .button:
            title = Copy("버튼은 어디에 있을까요?", "Where is the button?")
            explanation = Copy("버튼 다음 자리부터 시계 방향으로 스몰 블라인드, 빅 블라인드 순서예요.",
                               "With three or more players, the blinds sit next to each other clockwise from the button.")
        case .smallBlind:
            title = Copy("스몰 블라인드는 누구일까요?", "Who is the small blind?")
            explanation = Copy("버튼에서 시계 방향으로 한 자리 가면 스몰 블라인드예요. 이 테이블에서는 먼저 칩 1개를 내요.",
                               "The small blind sits one seat clockwise from the button and posts 1 chip at this table.")
        case .bigBlind:
            title = Copy("빅 블라인드는 누구일까요?", "Who is the big blind?")
            explanation = Copy("스몰 블라인드 다음 자리가 빅 블라인드예요. 이 테이블에서는 먼저 칩 2개를 내요.",
                               "The big blind sits one seat clockwise from the small blind and posts 2 chips at this table.")
        }
        let answer = role.seat(in: spot.table)
        return spot.question(title, Copy("자리 번호는 시계 방향으로 이어져요.", "Seat numbers run clockwise."),
                             choices: spot.table.seats.indices.map(seatName), answer: answer, explanation,
                             hiding: role, revealedEvidence: spot.evidence(highlight: answer))
    }

    private static let blinds: Content = (
        [
            Spot("C1-example").example(
                Copy("버튼과 블라인드를 찾아요", "Find the button and blinds"),
                Copy("베팅을 시작하기 전에 두 자리가 칩을 먼저 내요.", "Two seats post chips before the first turn."),
                Copy("1번 자리에 버튼이 있어요. 시계 방향으로 다음 자리인 2번은 칩 1개를, 3번은 칩 2개를 내요.",
                     "Seat 1 has the button. Clockwise from there, Seat 2 posts 1 chip and Seat 3 posts 2.")),
            blindQuestion(Spot("C1-01", dealer: 1), role: .smallBlind),
            blindQuestion(Spot("C1-02", dealer: 2), role: .bigBlind),
            blindQuestion(Spot("C1-03", dealer: 3), role: .button),
        ],
        [
            blindQuestion(Spot("C1-review-01", dealer: 2, count: 3), role: .smallBlind),
            blindQuestion(Spot("C1-review-02", dealer: 0, count: 3), role: .bigBlind),
            blindQuestion(Spot("C1-review-03", dealer: 1, count: 3), role: .button),
        ]
    )

    private static let preflopRule = Copy(
        "세 명 이상이면 빅 블라인드 다음 자리부터 시계 방향으로 행동해요.",
        "With three or more players, action starts one seat clockwise from the big blind.")
    private static let postflopRule = Copy(
        "플랍부터는 버튼 다음 자리부터 시계 방향으로 살펴요. 폴드한 자리는 건너뛰어요.",
        "From the flop onward, start clockwise from the button and skip folded seats.")

    private static func actingQuestion(_ spot: Spot, title: Copy, explanation: Copy) -> Activity {
        spot.question(title, Copy("이번 라운드 순서를 찾아요.", "Find the order for this round."),
                      choices: spot.table.seats.indices.map(seatName), answer: spot.actor, explanation,
                      revealedEvidence: spot.evidence(highlight: spot.actor))
    }

    private static func preflopQuestion(_ spot: Spot) -> Activity {
        actingQuestion(spot, title: Copy("프리플랍에서 누가 먼저 할까요?", "Who acts first preflop?"),
                       explanation: preflopRule)
    }

    private static let preflopOrder: Content = (
        [
            Spot("C2-example").example(
                Copy("빅 블라인드 다음 차례", "Start after the big blind"),
                Copy("이 테이블에는 네 명이 있어요.", "There are four players at this table."),
                Copy("3번 자리가 빅 블라인드예요. 시계 방향으로 다음인 4번부터 시작해요.",
                     "Seat 3 is the big blind. Seat 4, the next seat clockwise, acts first."), highlight: 3),
            preflopQuestion(Spot("C2-01", dealer: 1)),
            preflopQuestion(Spot("C2-02", dealer: 2)),
            preflopQuestion(Spot("C2-03", dealer: 3)),
        ],
        [
            preflopQuestion(Spot("C2-review-01", dealer: 0, count: 3)),
            preflopQuestion(Spot("C2-review-02", dealer: 2, count: 3)),
            preflopQuestion(Spot("C2-review-03", dealer: 1, count: 3)),
        ]
    )

    private static func postflopQuestion(_ spot: Spot) -> Activity {
        actingQuestion(spot, title: Copy("플랍에서 누가 먼저 할까요?", "Who acts first on the flop?"),
                       explanation: postflopRule)
    }

    private static let postflopOrder: Content = (
        [
            Spot("C3-example", [.call, .call, .fold, .check]).example(
                Copy("폴드한 자리는 건너뛰어요", "Skip folded seats"),
                Copy("플랍에 카드 세 장이 놓였어요.", "Three cards are on the flop."),
                Copy("버튼 다음인 2번 자리는 이미 폴드했어요. 아직 핸드에 남은 다음 자리인 3번부터 시작해요.",
                     "Seat 2 is next to the button and has folded. Seat 3 is the next player still in, so they go first."),
                highlight: 2),
            postflopQuestion(Spot("C3-01", dealer: 1, limp)),
            postflopQuestion(Spot("C3-02", dealer: 2, [.fold, .call, .fold, .check])),
            postflopQuestion(Spot("C3-03", dealer: 3, [.call, .fold, .call, .check])),
        ],
        [
            postflopQuestion(Spot("C3-review-01", count: 3, [.call, .fold, .check])),
            postflopQuestion(Spot("C3-review-02", dealer: 1, count: 3, [.fold, .call, .check])),
            postflopQuestion(Spot("C3-review-03", dealer: 2, count: 3, [.call, .call, .check])),
        ]
    )

    private static let check = Copy("체크", "Check")
    private static let bet = Copy("벳", "Bet")
    private static let call = Copy("콜", "Call")
    private static let fold = Copy("폴드", "Fold")
    private static let raise = Copy("레이즈", "Raise")

    private static func owedRow(_ spot: Spot) -> TableCourseRow {
        TableCourseRow(Copy("콜에 필요한 칩", "Chips to call"), chips(spot.table.amountToCall))
    }

    private static func noCallQuestion(_ spot: Spot, startWager: Bool = false) -> Activity {
        let title = startWager ? Copy("어떻게 첫 베팅을 할까요?", "How do you put in the first bet?")
            : Copy("칩을 더 내지 않고 계속하려면?", "How do you stay in without adding chips?")
        let choices = startWager ? [check, bet, call] : [fold, call, check]
        let answer = startWager ? 1 : 2
        let explanation = startWager
            ? Copy("이 라운드에 걸린 칩이 없으면 벳으로 첫 베팅을 해요.",
                   "A bet puts in the first wager of the round.")
            : Copy("콜할 금액이 0개라서 체크할 수 있어요. 칩을 더 내지 않고 다음 차례로 넘겨요.",
                   "With 0 chips to call, you can check and stay in the hand without adding chips.")
        return spot.question(title, spot.whoseTurn,
                             choices: choices, answer: answer, explanation,
                             highlight: spot.actor, rows: [owedRow(spot)])
    }

    private static let noAmountToCall: Content = {
        let example = Spot("C4-example", limp)
        return (
            [
                example.example(
                    Copy("체크하거나 벳할 수 있어요", "Check or bet"),
                    Copy("플랍에서 아직 아무도 베팅하지 않았어요.", "Nobody has bet on this flop yet."),
                    Copy("체크하면 칩을 내지 않고 다음 차례로 넘기며 핸드에 남아요. 벳하면 이 라운드의 첫 칩을 걸어요.",
                         "Checking passes the turn and keeps you in the hand. Betting puts in the first wager of this round."),
                    highlight: example.actor, rows: [owedRow(example)]),
                noCallQuestion(Spot("C4-01", dealer: 1, limp)),
                noCallQuestion(Spot("C4-02", dealer: 2, limp + [.check]), startWager: true),
                noCallQuestion(Spot("C4-03", dealer: 3, limp + [.check, .check])),
            ],
            [
                noCallQuestion(Spot("C4-review-01", dealer: 2, [.call, .call, .call])),
                noCallQuestion(Spot("C4-review-02", dealer: 0, limp + [.check, .check, .check]), startWager: true),
                noCallQuestion(Spot("C4-review-03", dealer: 1, limp + [.check, .check, .check, .check])),
            ]
        )
    }()

    private static let matchWager = Copy("핸드에 남기 위해 걸린 금액에 맞추려면?", "How do you match the wager and stay in?")
    private static let leaveHand = Copy("이 핸드에서 빠지려면?", "How do you leave this hand?")
    private static let increaseWager = Copy("걸린 금액을 올리려면?", "How do you increase the wager?")

    private static func response(_ spot: Spot, action: PracticeAction) -> Activity {
        let title: Copy
        let answer: Int
        let explanation: Copy
        let unpaid = spot.table.amountToCall
        let paid = spot.table.seats[spot.actor].streetCommitted
        let callChoice = Copy("콜 · \(unpaid)개 추가", "Call · add \(unpaid)")
        switch action {
        case .call:
            title = matchWager
            answer = 1
            explanation = Copy("이번 라운드에 이미 낸 칩은 \(paid)개예요. 콜하려면 부족한 \(unpaid)개를 더 내요.",
                               "This seat has already paid \(paid) this round. Calling adds the remaining \(unpaid) chips.")
        case .fold:
            title = leaveHand
            answer = 0
            explanation = Copy("폴드하면 이 핸드에서 빠져요. 이미 낸 칩은 팟에 남아요.",
                               "Folding drops out of this hand. Chips already paid stay in the pot.")
        default:
            title = increaseWager
            answer = 2
            explanation = Copy("레이즈는 기존 금액보다 더 많이 걸어요. 다음 자리는 새 금액을 보고 선택해요.",
                               "A raise increases the wager. The next seat acts facing the new amount.")
        }
        return spot.question(title, spot.whoseTurn,
                             choices: [fold, callChoice, raise], answer: answer, explanation,
                             highlight: spot.actor, rows: [owedRow(spot)])
    }

    private static let facingBet: Content = {
        let example = Spot("C5-example", limp + [.raise(to: 4)])
        return (
            [
                example.example(
                    Copy("벳을 받으면 세 가지 선택", "Three ways to respond to a bet"),
                    Copy("이 자리 앞에서 칩 4개를 걸었어요.", "The previous seat just bet 4 chips."),
                    Copy("콜은 4개를 내고 계속해요. 폴드는 이번 핸드에서 빠져요. 레이즈는 걸린 금액을 더 올려요.",
                         "Call by adding 4 chips to stay in. Fold to leave the hand. Raise to increase the wager."),
                    highlight: example.actor, rows: [owedRow(example)]),
                response(Spot("C5-01", dealer: 1, [.raise(to: 6), .call]), action: .call),
                response(Spot("C5-02", dealer: 2, limp + [.check, .raise(to: 3)]), action: .fold),
                response(Spot("C5-03", dealer: 3, limp + [.raise(to: 2)]), action: .raise(to: 4)),
            ],
            [
                response(Spot("C5-review-01", dealer: 3, [.raise(to: 7), .fold, .fold]), action: .call),
                response(Spot("C5-review-02", dealer: 0, limp + [.raise(to: 5), .call]), action: .fold),
                response(Spot("C5-review-03", dealer: 1, limp + [.check, .check, .raise(to: 3)]), action: .raise(to: 6)),
            ]
        )
    }()

    private static func minimumWager(_ spot: Spot) -> Activity {
        let table = spot.table
        let minimum = table.legalActions.compactMap { action -> Int? in
            guard case .raise(let amount) = action else { return nil }
            return amount
        }.first!
        let wagers = table.events.filter { $0.street == table.street && ($0.label == "bet" || $0.label == "raise") }
        let wager = table.seats.map(\.streetCommitted).max()!
        let previousWager = wagers.dropLast().last?.action
        let increment = minimum - wager
        let title: Copy
        let explanation: Copy
        let options: [Int]
        switch previousWager {
        case .raise(let prior):
            title = Copy("다시 레이즈하려면 최소 얼마일까요?", "What’s the smallest re-raise total?")
            explanation = Copy("직전 레이즈는 \(prior)개에서 \(wager)개로 \(increment)개를 올렸어요. \(wager)개에 \(increment)개를 더하면 최소 \(minimum)개예요.",
                               "The last raise added \(increment), from \(prior) to \(wager). Add at least \(increment) to \(wager) for a total of \(minimum).")
            options = [wager + 2, wager * 2, minimum]
        case nil where wager == 0:
            title = Copy("첫 벳은 최소 몇 개일까요?", "What’s the smallest opening bet?")
            explanation = Copy("첫 벳은 빅 블라인드만큼 걸어야 해요. 이 테이블의 빅 블라인드는 2개예요.",
                               "The first bet must be at least one big blind. This table’s big blind is 2 chips.")
            options = [minimum, minimum - 1, minimum + 1]
        default:
            title = Copy("최소 몇 개까지 레이즈해야 할까요?", "What’s the smallest raise total?")
            explanation = Copy("첫 벳이 \(wager)개예요. 최소 \(wager)개를 더 올려서 총 \(minimum)개를 걸어야 해요.",
                               "The first bet was \(wager). Raise by at least \(wager) more, to a total of \(minimum).")
            options = [minimum - 1, minimum, minimum + 2]
        }
        return spot.question(title, Copy("\(spot.actor + 1)번 자리에 칩이 충분히 남아 있어요.",
                                              "Seat \(spot.actor + 1) has plenty of chips."),
                             choices: options.map(chips), answer: options.firstIndex(of: minimum)!, explanation,
                             highlight: spot.actor)
    }

    private static let fullRaise: Content = (
        [
            Spot("C6-example", limp + [.raise(to: 4)]).example(
                Copy("4개에서 최소 8개로", "From 4 to at least 8"),
                Copy("플랍 첫 벳이 칩 4개예요.", "The first bet on this flop is 4 chips."),
                Copy("첫 레이즈는 벳만큼 더 올려야 해요. 4개에 4개를 더하면 최소 금액은 8개예요.",
                     "The first raise must add at least the size of the bet. Add 4 to 4 for a minimum total of 8."), highlight: 2),
            minimumWager(Spot("C6-01", dealer: 1, limp)),
            minimumWager(Spot("C6-02", dealer: 2, limp + [.raise(to: 4)])),
            minimumWager(Spot("C6-03", dealer: 3, limp + [.raise(to: 4), .raise(to: 10)])),
        ],
        [
            minimumWager(Spot("C6-review-01", limp + [.check, .check, .check, .check])),
            minimumWager(Spot("C6-review-02", dealer: 3, limp + [.check, .raise(to: 3)])),
            minimumWager(Spot("C6-review-03", dealer: 1, limp + [.raise(to: 5), .raise(to: 12)])),
        ]
    )

    private static let afterFlopOrder = Copy(
        "버튼 다음 자리부터 시계 방향으로 이번 라운드를 시작해요. 모두 남아 있으면 버튼이 마지막이에요.",
        "This round starts clockwise from the button. With everyone still in, the button acts last.")

    private static func positionQuestion(_ spot: Spot, last: Bool) -> Activity {
        let title = last ? Copy("모두 남아 있으면 누가 마지막일까요?", "Who acts last if everyone stays in?")
            : Copy("누가 처음으로 판단해야 할까요?", "Who decides before seeing anyone act?")
        let actor = last ? spot.table.dealer : spot.actor
        return spot.question(title, Copy("이번 라운드의 첫 차례부터 찾아봐요.", "Find the start of this round first."),
                             choices: spot.table.seats.indices.map(seatName), answer: actor, afterFlopOrder,
                             revealedEvidence: spot.evidence(highlight: actor))
    }

    private static func seesAction(_ spot: Spot) -> Activity {
        let observed = spot.table.events.last!.seat
        let stillWaiting = (spot.actor + 1) % spot.table.seatCount
        let choices = [stillWaiting, observed].map { seat in
            Copy("\(seat + 1)번 자리의 체크", "Seat \(seat + 1) checking")
        } + [Copy("아직 본 행동이 없어요", "No action yet")]
        let explanation = Copy(
            "\(observed + 1)번 자리가 먼저 체크했어요. 그다음인 \(spot.actor + 1)번 자리는 그 체크를 보고 판단해요.",
            "Seat \(observed + 1) checked first. Seat \(spot.actor + 1) has seen that check before deciding.")
        return spot.question(Copy("\(spot.actor + 1)번 자리는 어떤 행동을 봤을까요?",
                                  "Which action has Seat \(spot.actor + 1) already seen?"),
                             Copy("플랍에서 아직 벳은 없어요.", "There hasn’t been a bet on this flop."),
                             choices: choices, answer: 1, explanation, highlight: spot.actor)
    }

    private static let information: Content = (
        [
            Spot("C7-example", limp + [.check, .check, .check]).example(
                Copy("앞선 행동을 보고 판단해요", "Acting later gives you more information"),
                Copy("플랍에서 1번 자리가 마지막 차례예요.", "Seat 1 acts last on this flop."),
                Copy("2번, 3번, 4번 자리가 모두 체크했어요. 1번 자리는 그 세 번의 체크를 보고 판단해요.",
                     "Seats 2, 3 and 4 all checked. Seat 1 gets to see all three checks before deciding."),
                highlight: 0, rows: [TableCourseRow(Copy("앞선 행동", "Earlier moves"),
                                                   Copy("2번 · 3번 · 4번 체크", "Seats 2, 3, 4 checked"))]),
            positionQuestion(Spot("C7-01", dealer: 1, limp), last: true),
            positionQuestion(Spot("C7-02", dealer: 2, limp), last: false),
            seesAction(Spot("C7-03", dealer: 3, limp + [.check])),
        ],
        [
            positionQuestion(Spot("C7-review-01", dealer: 2, count: 3, [.call, .call, .check]), last: true),
            positionQuestion(Spot("C7-review-02", dealer: 0, count: 3, [.call, .call, .check]), last: false),
            seesAction(Spot("C7-review-03", dealer: 1, count: 3, [.call, .call, .check, .check])),
        ]
    )

    private static let twoPlayerRule = Copy(
        "두 명이면 버튼이 스몰 블라인드예요. 프리플랍에서는 버튼이 먼저, 플랍부터는 버튼이 마지막이에요.",
        "With two players, the button posts the small blind. The button acts first preflop, and last from the flop onward.")

    private static func headsUpBlind(_ spot: Spot) -> Activity {
        let answer = Role.smallBlind.seat(in: spot.table)
        return spot.question(Copy("두 명이면 누가 스몰 블라인드일까요?", "Who posts the small blind with two players?"),
                             Copy("지금은 두 명만 앉아 있어요.", "There are only two players at this table."),
                             choices: spot.table.seats.indices.map(seatName), answer: answer, twoPlayerRule,
                             hiding: .smallBlind, revealedEvidence: spot.evidence(highlight: answer))
    }

    private static let headsUpLimp: [PracticeAction] = [.call, .check]
    private static let headsUp: Content = (
        [
            Spot("C8-example", count: 2).example(
                Copy("두 명이면 버튼의 순서가 바뀌어요", "Two players change the button’s order"),
                Copy("1번 자리에 버튼이 있어요. 이 자리에서 칩 1개를 먼저 냈어요.",
                     "Seat 1 has the button and posts the small blind of 1 chip."),
                twoPlayerRule, highlight: 0),
            headsUpBlind(Spot("C8-01", dealer: 1, count: 2)),
            actingQuestion(Spot("C8-02", count: 2),
                           title: Copy("두 명이면 프리플랍에서 누가 먼저일까요?", "Who acts first preflop with two players?"),
                           explanation: twoPlayerRule),
            actingQuestion(Spot("C8-03", dealer: 1, count: 2, headsUpLimp + [.check]),
                           title: Copy("두 명이면 플랍에서 누가 마지막일까요?", "Who acts last on the flop with two players?"),
                           explanation: twoPlayerRule),
        ],
        [
            headsUpBlind(Spot("C8-review-01", count: 2)),
            actingQuestion(Spot("C8-review-02", dealer: 1, count: 2),
                           title: Copy("프리플랍에서 첫 차례는 누구일까요?", "Who has the first preflop turn?"),
                           explanation: twoPlayerRule),
            actingQuestion(Spot("C8-review-03", count: 2, headsUpLimp + [.check, .check]),
                           title: Copy("턴 카드가 나오면 누가 먼저 할까요?", "Who acts first when the turn card comes out?"),
                           explanation: twoPlayerRule),
        ]
    )

    private static func nextTurn(_ spot: Spot, after action: PracticeAction, reason: Copy) -> Activity {
        var next = spot
        next.play(action)
        let movesOn = next.table.street != spot.table.street
        let nextStreet: PracticeStreet
        switch spot.table.street {
        case .preflop: nextStreet = .flop
        case .flop: nextStreet = .turn
        case .turn: nextStreet = .river
        case .river, .finished: preconditionFailure("This exercise requires a card left to deal")
        }
        let street = streetName(nextStreet)
        let deal = Copy("\(street.text(in: .korean)) 카드 공개", "Deal the \(street.text(in: .english).lowercased())")
        let continueRound = Copy("이 라운드에서 다음 차례", "Another turn in this round")
        let choices = movesOn
            ? [continueRound, deal]
            : [deal] + spot.table.seats.indices.filter { $0 != spot.actor }.map(seatName)
        let answer = movesOn ? 1 : 1 + spot.table.seats.indices.filter { $0 != spot.actor }.firstIndex(of: next.actor)!
        let move: Copy
        switch action {
        case .call: move = call
        case .fold: move = fold
        default: move = check
        }
        return spot.question(Copy("다음 차례일까요, 새 카드일까요?", "Next seat or next card?"),
                             Copy("\(spot.actor + 1)번 자리가 \(move.text(in: .korean))하면 어떻게 될까요?",
                                  "What happens if Seat \(spot.actor + 1) chooses to \(move.text(in: .english).lowercased())?"),
                             choices: choices, answer: answer, reason, highlight: spot.actor,
                             revealedEvidence: next.evidence(highlight: next.actor))
    }

    private static let checkpoint = [
        Spot("C9-example", dealer: 2, [.call, .call, .call]).example(
            Copy("빅 블라인드 차례가 남아요", "The big blind still acts"),
            Copy("다른 세 자리 모두 칩을 2개씩 냈어요.", "All three other seats have matched 2 chips."),
            Copy("빅 블라인드는 칩 2개를 미리 냈어요. 여기서 체크하면 플랍이 나와요.",
                 "The big blind posted 2 chips. If they check, deal the flop."),
            highlight: 0),
        nextTurn(Spot("C9-01", dealer: 1, [.call, .call]), after: .call,
                 reason: Copy("스몰 블라인드가 콜해도 4번 빅 블라인드의 차례가 남아요.",
                              "After the small blind calls, Seat 4 still has its big blind turn.")),
        nextTurn(Spot("C9-02", [.fold, .call, .call, .check, .check]), after: .check,
                 reason: Copy("4번 자리는 이미 폴드했어요. 다음 차례는 1번 자리예요.",
                              "Seat 4 has folded. Skip to Seat 1, which still has a turn.")),
        nextTurn(Spot("C9-03", dealer: 3, limp + [.check, .check, .check]), after: .check,
                 reason: Copy("네 자리 모두 체크했어요. 이번 라운드를 마치고 턴 카드 한 장을 공개해요.",
                              "All four seats have checked. This round ends and one turn card is dealt.")),
        nextTurn(Spot("C9-04", dealer: 1, limp + [.raise(to: 5), .fold]), after: .call,
                 reason: Copy("1번 자리가 콜한 뒤에도 2번 자리가 벳에 답할 차례가 남아요.",
                              "After Seat 1 calls, Seat 2 still needs to respond to the bet.")),
        nextTurn(Spot("C9-05", dealer: 2, limp + [.raise(to: 3), .fold, .fold]), after: .call,
                 reason: Copy("두 자리는 폴드했고 남은 두 자리는 칩 3개를 맞췄어요. 이제 턴 카드를 공개해요.",
                              "Two seats folded, and the two remaining seats have matched 3 chips. Deal the turn.")),
    ]
    private static let checkpointReview = [
        nextTurn(Spot("C9-review-01", dealer: 3, [.call, .call, .call]), after: .check,
                 reason: Copy("모두 칩 2개를 맞췄고 빅 블라인드도 이제 체크했어요. 플랍 카드 세 장을 공개해요.",
                              "Everyone matched 2 chips and the big blind has now checked. Deal the three flop cards.")),
        nextTurn(Spot("C9-review-02", dealer: 1, limp + [.check, .check, .check, .check, .check]), after: .check,
                 reason: Copy("아직 1번과 2번 자리의 차례가 남았어요. 이번 라운드에서 1번부터 이어서 행동해요.",
                              "Seats 1 and 2 still need to act. Seat 1 is next in this round.")),
        nextTurn(Spot("C9-review-03", count: 2, [.call, .raise(to: 5)]), after: .call,
                 reason: Copy("버튼이 콜하면 두 자리 모두 칩 5개를 냈고 차례를 마쳤어요. 플랍 카드를 공개해요.",
                              "When the button calls, both seats have put in 5 chips and had their turns. Deal the flop.")),
    ]

}
