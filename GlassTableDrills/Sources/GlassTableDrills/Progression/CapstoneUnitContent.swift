// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

public enum CapstoneUnitContent {
    private typealias Copy = TableCourseText
    private typealias Activity = TableCourseActivity

    static func activities(for lesson: TableCourseLesson) -> [TableCourseActivity] {
        switch lesson {
        case .i1:
            [
                StartingHandUnitContent.opening("I1-example", "QsQc", from: .lj, worked: true),
                StartingHandUnitContent.opening("I1-01", "KhJd", from: .utg),
                StartingHandUnitContent.opening("I1-02", "8s7s", from: .btn),
                StartingHandUnitContent.opening("I1-03", "6s3d", from: .co),
            ]
        case .i2:
            [
                StartingHandUnitContent.defending("I2-example", "KhKs", learner: .co, opener: .utg, worked: true),
                StartingHandUnitContent.defending("I2-01", "JdTh", learner: .btn, opener: .co),
                StartingHandUnitContent.defending("I2-02", "Ad4s", learner: .hj, opener: .utg),
                StartingHandUnitContent.defending("I2-03", "QdQc", learner: .btn, opener: .hj),
            ]
        case .i3:
            [
                flop("I3-example", board: cards("As8s4s"), flush: true, worked: true),
                flop("I3-01", board: cards("8h7s6c"), flush: false),
                flop("I3-02", board: cards("Ac9c2d"), flush: true),
                flop("I3-03", board: cards("Kd7s2d"), flush: false),
            ]
        case .i4:
            [
                riverPrice("I4-example", pot: 24, call: 8, share: 30, worked: true),
                riverPrice("I4-01", pot: 28, call: 12, share: 30),
                riverPrice("I4-02", pot: 28, call: 12, share: 28),
                riverPrice("I4-03", pot: 28, call: 12, share: 32),
            ]
        case .i5:
            [
                showdown("I5-example", mine: "Tc5d", other: "8hAs", board: "2c3c4d5h6d", worked: true),
                showdown("I5-01", mine: "Kc9h", other: "Qd9c", board: "9s7d5h4c2s"),
                showdown("I5-02", mine: "As7d", other: "AhJd", board: "Ad8c5s3h2c"),
                showdown("I5-03", mine: "3s5d", other: "9h2h", board: "TcJcQcKcAc"),
            ]
        case .i6: wholeHand
        default: []
        }
    }

    private static func cards(_ raw: String) -> [Card] { Card.parse(raw)! }

    private static func flop(_ id: String, board: [Card], mine: [Card] = [], flush: Bool,
                             worked: Bool = false) -> Activity {
        let ranks = Set(board.map(\.rank))
        let legal = Deck.all.filter { !board.contains($0) && !mine.contains($0) }
        let possible: Bool
        if flush {
            possible = Set(board.map(\.suit)).count == 1 && legal.filter { $0.suit == board[0].suit }.count >= 2
        } else {
            // A flop straight needs three distinct board ranks inside one five-rank run.
            let withLowAce = ranks.map { $0 == 14 ? 1 : $0 }
            possible = ranks.count == 3 && (
                (2...10).contains { Set($0...($0 + 4)).isSuperset(of: ranks) }
                    || Set(1...5).isSuperset(of: withLowAce)
            )
        }
        let title = flush ? Copy("플러시가 가능한 플랍?", "A possible flop flush?")
                          : Copy("스트레이트가 가능한 플랍?", "A possible flop straight?")
        let explanation: Copy
        switch (flush, possible) {
        case (true, true):
            explanation = Copy("공용 카드 세 장이 같은 무늬예요. 같은 무늬 카드 두 장을 든 상대는 플러시예요.",
                               "All three board cards share a suit. Two more of that suit make a flush.")
        case (true, false):
            explanation = Copy("같은 무늬의 공용 카드가 세 장은 필요해요. 내 카드 두 장만으로는 부족해요.",
                               "A flop flush needs all three board cards in one suit plus two hole cards.")
        case (false, true):
            explanation = Copy("공용 카드 세 장에 맞는 두 장을 더하면 다섯 숫자가 이어져요. 상대의 카드는 아직 몰라요.",
                               "Two hole cards can complete a run of five ranks. The opponent’s cards are still unknown.")
        case (false, false):
            explanation = Copy("공용 카드 세 장을 모두 쓰고 두 장을 더해도 다섯 숫자가 이어지지 않아요.",
                               "No two hole cards can connect all three board ranks into a run of five.")
        }
        return Activity(id: id, title: title,
                        prompt: worked ? explanation : Copy("지금 상대가 이미 완성했을 수도 있나요?",
                                                           "Could an opponent already have made it?"),
                        evidence: .init(cards: mine, board: board),
                        choices: worked ? [] : [Copy("가능해요", "Possible"), Copy("아직 불가능해요", "Impossible so far"),
                                                 Copy("상대는 반드시 완성했어요", "They must have it")],
                        correctChoice: worked ? nil : (possible ? 0 : 1),
                        explanation: worked ? nil : explanation)
    }

    private static func riverPrice(_ id: String, pot: Int, call: Int, share: Int, worked: Bool = false) -> Activity {
        let finalPot = pot + call
        let compare = share * finalPot - 100 * call
        let outcome = compare > 0 ? 0 : compare < 0 ? 1 : 2
        let comparison = [Copy("기대 몫이 콜 비용보다 커요.", "Your average share exceeds the call cost."),
                          Copy("기대 몫이 콜 비용보다 작아요.", "Your average share is below the call cost."),
                          Copy("기대 몫이 콜 비용과 같아요.", "Your average share equals the call cost.")][outcome]
        let math = Copy("콜하면 팟은 \(finalPot)칩이에요. \(finalPot)칩의 \(share)%를 \(call)칩과 비교해요.",
                        "Calling makes the pot \(finalPot). Compare \(share)% of \(finalPot) with the \(call)-chip cost.")
        let evidence = TableCourseEvidence(rows: [
            TableCourseRow(Copy("지금 팟", "Pot now"), chips(pot)),
            TableCourseRow(Copy("콜 가격", "Call price"), chips(call)),
            TableCourseRow(Copy("주어진 평균 몫", "Given equity"), Copy("\(share)%", "\(share)%")),
        ])
        return Activity(id: id, title: Copy("리버에서 콜할까요?", "Call on the river?"),
                        prompt: Copy("둘만 남았어요. 콜한 뒤에는 추가 행동과 수수료가 없어요.",
                                     "Heads-up. A call ends the action. There is no fee."),
                        evidence: evidence, choices: worked ? [] : [
                            Copy("평균적으로 이득", "Call gains chips"), Copy("평균적으로 손해", "Call loses chips"),
                            Copy("본전", "Break even"),
                        ], correctChoice: worked ? nil : outcome,
                        explanation: Copy("\(math.text(in: .korean)) \(comparison.text(in: .korean))",
                                          "\(math.text(in: .english)) \(comparison.text(in: .english))"))
    }

    private static func showdown(_ id: String, mine: String, other: String, board: String,
                                 worked: Bool = false) -> Activity {
        let hero = cards(mine), villain = cards(other), shared = cards(board)
        let first = hero + shared
        let second = villain + shared
        let winner = compareHands(hero: first, villain: second)
        let firstFive = bestFiveCards(first)
        let secondFive = bestFiveCards(second)
        let sharedPlays = compareHands(hero: shared, villain: first) == 2
            && compareHands(hero: shared, villain: second) == 2
        let answer = [Copy("A의 베스트 5가 더 강해요.", "A has the stronger best five."),
                      Copy("C의 베스트 5가 더 강해요.", "C has the stronger best five."),
                      Copy("두 베스트 5의 세기가 같아요.", "Both best fives have equal strength.")][winner]
        let pairRank = bestHandOfAny(first)
        let rivalRank = bestHandOfAny(second)
        let reason: Copy
        if sharedPlays {
            reason = Copy("두 사람 모두 공용 카드 다섯 장을 써요.\n팟을 나눠 가져가요.",
                          "Both players can use the board.\nThey split the pot.")
        } else if winner != 2, pairRank.category == 1, pairRank == rivalRank {
            let winnerFive = winner == 0 ? firstFive : secondFive
            let loserFive = winner == 0 ? secondFive : firstFive
            let winnerKickers = winnerFive.map(\.rank).filter { $0 != pairRank.topRank }.sorted(by: >)
            let loserKickers = loserFive.map(\.rank).filter { $0 != pairRank.topRank }.sorted(by: >)
            let higher = zip(winnerKickers, loserKickers).first { $0 != $1 }!
            let label = winner == 0 ? "A" : "C"
            let high = rankName(higher.0), low = rankName(higher.1)
            reason = Copy("같은 원 페어예요. \(label)의 키커 \(high)가 \(low)보다 높아요.",
                          "They have the same pair. \(label)’s \(high) kicker beats \(low).")
        } else {
            reason = answer
        }
        let revealed = TableCourseEvidence(cards: hero, board: shared, opponent: villain, rows: [
            TableCourseRow(Copy("A의 베스트 5", "A’s best five"), cardNames(sharedPlays ? shared : firstFive)),
            TableCourseRow(Copy("C의 베스트 5", "C’s best five"), cardNames(sharedPlays ? shared : secondFive)),
        ])
        return Activity(id: id, title: Copy("쇼다운 결과", "Read the showdown"),
                        prompt: Copy("나는 A, 상대는 C예요.\n쇼다운에서 누가 팟을 가져갈까요?",
                                     "You’re A and the opponent is C.\nWho takes the pot at showdown?"),
                        evidence: worked ? revealed : .init(cards: hero, board: shared, opponent: villain),
                        choices: worked ? [] : [Copy("A", "A"), Copy("C", "C"), Copy("팟을 나눠요", "Split the pot")],
                        correctChoice: worked ? nil : winner, explanation: reason,
                        revealedEvidence: worked ? nil : revealed)
    }

    private static func rankName(_ rank: Int) -> String {
        rank == 10 ? "10" : HandClass.rankChars[rank - 2]
    }

    private static func cardNames(_ cards: [Card]) -> Copy {
        let symbols = ["♣", "♦", "♥", "♠"]
        let names = cards.map { "\(rankName($0.rank))\(symbols[$0.suit])\u{FE0E}" }
            .joined(separator: " · ")
        return Copy(names, names)
    }

    private static func chips(_ count: Int) -> Copy {
        Copy("\(count)칩", count == 1 ? "1 chip" : "\(count) chips")
    }

    // All questions and the coach replay use this hand. No sample action alters Free Play.
    private static let actions: [PracticeAction] = [
        .fold, .raise(to: 6), .fold, .call,
        .check, .check, .check, .check, .raise(to: 4), .call,
    ]

    private static let frames: [PracticeTableState] = {
        var table = PracticeTableState(seed: 144, handID: "capstone-example")
        var frames = [table]
        for (index, action) in actions.enumerated() {
            try! table.apply(action, actionID: "capstone-\(index)")
            frames.append(table)
        }
        return frames
    }()

    public static var coachHand: PracticeTableState { frames[actions.count] }

    private static let wholeHand: [Activity] = {
        let firstIn = frames[1]
        let flopStart = frames[4]
        let turnStart = frames[6]
        let facingRiverBet = frames[9]
        let review = coachHand.review!
        let mine = cards(firstIn.learnerHole.joined())
        let facing = facingRiverBet.amountToCall
        let finalPot = facingRiverBet.pot + facing
        return [
            Activity(id: "I6-example", title: Copy("A와 함께 한 판", "Follow seat A"),
                     prompt: Copy("프리플랍부터 쇼다운까지 같은 연습 핸드를 따라가요.",
                                  "Use the same practice hand from preflop to showdown."),
                     evidence: .init(cards: mine),
                     explanation: Copy("A의 자리에서 상황을 읽어요. 테이블의 행동은 예시를 위해 정해져 있어요.",
                                       "Read the hand from seat A. The table follows an example script.")),
            Activity(id: "I6-01", title: Copy("프리플랍 · 맞는 차트", "Preflop · Pick a chart"),
                     prompt: Copy("D는 폴드했어요. 블라인드만 있으면 어떤 종류의 차트를 보나요?",
                                  "D folded. Only the blinds are posted. What type of chart fits?"),
                     evidence: .init(cards: mine),
                     choices: [Copy("대응 차트", "Response chart"), Copy("오픈 차트", "Opening chart")],
                     correctChoice: 1,
                     explanation: Copy("아직 자발적으로 참여한 사람이 없어요. 먼저 참여하는 자리의 오픈 차트를 봐요.",
                                       "No one has entered voluntarily. This is an opening-chart spot.")),
            flop("I6-02", board: cards(flopStart.visibleBoard.joined()), mine: mine, flush: true),
            Activity(id: "I6-03", title: Copy("턴 · 아직 모르는 카드", "Turn · Unseen cards"),
                     prompt: Copy("A는 자기 카드 두 장과 공용 카드 네 장을 봐요. 보지 못한 카드는 몇 장인가요?",
                                  "A sees two hole cards and four shared cards. How many cards are unseen?"),
                     evidence: .init(cards: mine, board: cards(turnStart.visibleBoard.joined())),
                     choices: [Copy("44장", "44"), Copy("48장", "48"), Copy("46장", "46")],
                     correctChoice: 2,
                     explanation: Copy("52장 중 보이는 여섯 장을 빼면 46장이에요. 상대 카드는 아직 보이지 않아요.",
                                       "Subtract the six visible cards from 52. The opponent’s cards are still hidden.")),
            Activity(id: "I6-04", title: Copy("리버 · 콜한 뒤의 팟", "River · Pot after a call"),
                     prompt: Copy("A가 여기서 콜하면 팟은 몇 칩일까요?", "How big will the pot be if A calls?"),
                     evidence: .init(cards: mine, board: cards(facingRiverBet.visibleBoard.joined()), rows: [
                        TableCourseRow(Copy("지금 팟", "Pot now"), chips(facingRiverBet.pot)),
                        TableCourseRow(Copy("콜 가격", "Call price"), chips(facing)),
                     ]),
                     choices: [chips(facingRiverBet.pot), chips(finalPot), chips(finalPot + facing)],
                     correctChoice: 1,
                     explanation: Copy("지금 팟에 콜 가격을 한 번 더해 \(finalPot)칩이에요.",
                                       "Add the call once to reach \(finalPot) chips.")),
            showdown("I6-05", mine: review.holeCards[0].joined(), other: review.holeCards[2].joined(),
                     board: review.board.joined()),
        ]
    }()
}
