// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

enum PriceChanceUnitContent {
    private typealias Copy = TableCourseText
    private typealias Row = TableCourseRow

    private struct Price {
        let earlier: Int
        let paid: Int
        let facing: Int

        init(_ earlier: Int, _ paid: Int, _ facing: Int) {
            self.earlier = earlier
            self.paid = paid
            self.facing = facing
        }

        var now: Int { earlier + paid + facing }
        var cost: Int { facing - paid }
        var final: Int { now + cost }

        var breakEvenShare: String {
            let (tenths, remainder) = (1000 * cost).quotientAndRemainder(dividingBy: final)
            return remainder == 0 ? percent(tenths) : "\(cost)/\(final)"
        }

        var equation: String { "\(cost) ÷ \(final) = \(breakEvenShare)" }

        func edge(with equity: Int) -> Int {
            equity * final - 1000 * cost
        }

        var payments: [Row] {
            [Row(Copy("이번 라운드에 내가 낸 칩", "You paid this round"), chips(paid)),
             Row(Copy("이번 라운드에 상대가 낸 칩", "Opponent paid this round"), chips(facing))]
        }

        var potRow: Row { Row(Copy("현재 팟", "Pot now"), chips(now)) }
        var callRow: Row { Row(Copy("콜에 더 낼 칩", "Extra to call"), chips(cost)) }
    }

    private struct TurnDeal {
        let board: [Card]
        let opponent: [Card]

        init(_ board: String, _ opponent: String) {
            self.board = Card.parse(board)!
            self.opponent = Card.parse(opponent)!
        }
    }

    static func activities(for lesson: TableCourseLesson) -> [TableCourseActivity] {
        switch lesson {
        case .h1:
            [
                cost("H1-example", Price(10, 4, 12), worked: true),
                cost("H1-01", Price(8, 0, 7)),
                cost("H1-02", Price(6, 5, 14)),
                cost("H1-03", Price(12, 12, 24)),
            ]
        case .h2:
            [
                finalPot("H2-example", Price(16, 4, 12), worked: true),
                finalPot("H2-01", Price(12, 0, 6)),
                finalPot("H2-02", Price(6, 5, 16)),
                finalPot("H2-03", Price(24, 7, 22)),
            ]
        case .h3:
            [
                threshold("H3-example", Price(20, 0, 10), worked: true),
                threshold("H3-01", Price(40, 10, 20)),
                threshold("H3-02", Price(36, 0, 12)),
                threshold("H3-03", Price(30, 5, 35)),
            ]
        case .h4:
            [
                decision("H4-example", Price(40, 0, 20), equity: 350, worked: true),
                decision("H4-01", Price(20, 0, 10), equity: 220),
                decision("H4-02", Price(18, 3, 11), equity: 200),
                decision("H4-03", Price(40, 4, 20), equity: 300),
            ]
        case .h5:
            [
                changePrice("H5-example", pot: 40, bets: (5, 30),
                            deal: TurnDeal("Kh9sJc8h", "2d2h"), hand: "Tc2s", equity: 250, worked: true),
                changePrice("H5-01", pot: 60, bets: (20, 45),
                            deal: TurnDeal("4cTcKcAh", "KdJd"), hand: "3cQh", equity: 250),
                changePrice("H5-02", pot: 20, bets: (15, 40),
                            deal: TurnDeal("TsAhTcKc", "5s9h"), hand: "3s9c", equity: 500),
                changePrice("H5-03", pot: 60, bets: (10, 90),
                            deal: TurnDeal("3dKsAdTd", "AhAs"), hand: "8sAc", equity: 0),
            ]
        case .h6:
            [
                changeChance("H6-example", price: Price(40, 0, 30),
                             deal: TurnDeal("6d7sQd5s", "Ad2c"), hands: ("2s8c", "2dAs"),
                             equities: (250, 500), worked: true),
                changeChance("H6-01", price: Price(60, 0, 45),
                             deal: TurnDeal("TcQdKh5h", "5d6h"), hands: ("5c2s", "Jd6c"),
                             equities: (500, 250)),
                changeChance("H6-02", price: Price(60, 0, 20),
                             deal: TurnDeal("2s5sQsQc", "Qh8h"), hands: ("8cKh", "6h4s"),
                             equities: (0, 250)),
                changeChance("H6-03", price: Price(60, 0, 90),
                             deal: TurnDeal("Js7hTcQc", "9s4s"), hands: ("6s9c", "2s7c"),
                             equities: (500, 750)),
            ]
        case .h7:
            [
                decision("H7-example", Price(24, 2, 8), equity: 250, mixed: true, worked: true),
                decision("H7-01", Price(20, 0, 30), equity: 370, mixed: true),
                decision("H7-02", Price(10, 5, 35), equity: 375, mixed: true),
                decision("H7-03", Price(20, 10, 70), equity: 380, mixed: true),
                decision("H7-04", Price(22, 4, 14), equity: 190, mixed: true),
            ]
        default:
            []
        }
    }

    static func reviewActivities(for lesson: TableCourseLesson) -> [TableCourseActivity] {
        switch lesson {
        case .h2:
            [
                finalPot("H2-review-01", Price(18, 0, 7)),
                finalPot("H2-review-02", Price(10, 6, 15)),
                finalPot("H2-review-03", Price(21, 11, 23)),
            ]
        case .h3:
            [
                threshold("H3-review-01", Price(80, 0, 10)),
                threshold("H3-review-02", Price(10, 5, 35)),
                threshold("H3-review-03", Price(38, 9, 16)),
            ]
        case .h4:
            [
                decision("H4-review-01", Price(64, 3, 18), equity: 160),
                decision("H4-review-02", Price(40, 0, 30), equity: 280),
                decision("H4-review-03", Price(30, 0, 10), equity: 200),
            ]
        case .h5:
            [
                changePrice("H5-review-01", pot: 80, bets: (10, 60),
                            deal: TurnDeal("6s7sThKd", "6c5d"), hand: "5s8c", equity: 250),
                changePrice("H5-review-02", pot: 40, bets: (30, 80),
                            deal: TurnDeal("7dQhJs5s", "Jh7h"), hand: "9sKs", equity: 250),
                changePrice("H5-review-03", pot: 20, bets: (15, 30),
                            deal: TurnDeal("Jd7hQsQc", "4cKh"), hand: "2sKd", equity: 500),
            ]
        case .h6:
            [
                changeChance("H6-review-01", price: Price(30, 0, 10),
                             deal: TurnDeal("Jh3sTcKh", "QhTs"), hands: ("JcTd", "2h5d"),
                             equities: (750, 0)),
                changeChance("H6-review-02", price: Price(40, 0, 80),
                             deal: TurnDeal("5dTdAd9s", "JdJc"), hands: ("Qd3c", "Ah3h"),
                             equities: (250, 750)),
                changeChance("H6-review-03", price: Price(20, 0, 30),
                             deal: TurnDeal("KcJdTs9s", "7hAd"), hands: ("9c5s", "Ah8c"),
                             equities: (750, 500)),
            ]
        default:
            []
        }
    }

    private static func cost(_ id: String, _ price: Price, worked: Bool = false) -> TableCourseActivity {
        let equation = "\(price.facing) − \(price.paid) = \(price.cost)"
        let alternatives = price.paid == 0 ? [price.now, price.facing + 2]
            : [price.facing, price.cost == price.paid ? 0 : price.paid]
        return question(
            id, title: Copy("콜할 때 더 낼 칩", "Chips still due"),
            prompt: Copy("콜하려면 칩을 몇 개 더 내야 할까요?", "How many more chips do you need to call?"),
            rows: price.payments + [price.potRow],
            choices: ([price.cost] + alternatives).map(chips), answer: 0,
            explanation: Copy("이번 라운드에 상대가 낸 칩에서 내가 이미 낸 칩을 빼요. \(equation)개를 더 내요.",
                              "Subtract what you already paid this round from the amount to match. You owe \(equation) chips."),
            worked: worked
        )
    }

    private static func finalPot(_ id: String, _ price: Price, worked: Bool = false) -> TableCourseActivity {
        question(
            id, title: Copy("콜한 뒤의 팟", "The pot after a call"),
            prompt: Copy("내가 콜하면 팟에 칩이 몇 개 있을까요?", "How many chips will the pot hold if you call?"),
            rows: [price.potRow] + price.payments,
            choices: [price.final, price.now, price.final + price.facing].map(chips), answer: 0,
            explanation: Copy("지금 팟에는 이미 낸 칩이 들어 있어요. 더 낼 \(price.cost)개만 더하면 \(price.now) + \(price.cost) = \(price.final)개예요.",
                              "The current pot already includes both payments. Adding the \(price.cost) still due gives \(price.now) + \(price.cost) = \(price.final)."),
            worked: worked
        )
    }

    private static func threshold(_ id: String, _ price: Price, worked: Bool = false) -> TableCourseActivity {
        let wrongPotPercent = (100 * price.cost + price.now / 2) / price.now
        let complement = 1000 - 1000 * price.cost / price.final
        let options = [price.breakEvenShare, percent(wrongPotPercent * 10), percent(complement)]
            .map { Copy($0, $0) }
        return question(
            id, title: Copy("손익분기점 구하기", "Find the break-even share"),
            prompt: Copy("콜한 뒤 팟에서 평균적으로 얼마만큼 가져와야 콜에 쓴 칩을 돌려받을까요?",
                         "On average, what share of the final pot would earn back the chips you spend to call?"),
            rows: [price.potRow, price.callRow], choices: options, answer: 0,
            explanation: Copy("콜하면 팟은 칩 \(price.final)개가 돼요. 콜에 쓴 칩을 돌려받으려면 팟에서 \(price.breakEvenShare)를 가져와야 해요. \(price.equation).",
                              "Calling makes the pot \(price.final) chips. Divide the cost by the final pot to get the break-even share. \(price.equation)."),
            worked: worked
        )
    }

    private static let finalModel = Copy(
        "두 명만 남았어요. 콜하면 베팅이 끝나요. 수수료와 사이드 팟은 없어요.",
        "Two players remain. Calling ends the betting. There’s no fee or side pot."
    )

    private static let turnModel = Copy(
        "상대가 화면에 나온 카드를 들었다고 가정해요. 콜하면 더 베팅하지 않고 리버를 열어요. 수수료와 사이드 팟은 없어요.",
        "Assume the opponent has the hand shown. After a call, the river is dealt with no more betting. There’s no fee or side pot."
    )

    private static let turnShare = Copy(
        "리버에 나올 수 있는 카드를 모두 따져서 팟에서 가져올 평균 몫을 구했어요. 비긴 경우에는 팟의 절반을 세어요.",
        "The shares average all possible river cards. A tie counts for half the pot."
    )

    private static func decision(_ id: String, _ price: Price, equity: Int, mixed: Bool = false,
                                 worked: Bool = false) -> TableCourseActivity {
        let edge = price.edge(with: equity)
        let answer = edge > 0 ? 0 : edge < 0 ? 1 : 2
        let outcome = [
            Copy("필요한 몫보다 커서 콜하면 평균적으로 칩이 늘어요.",
                 "Your share is higher, so calling gains chips on average."),
            Copy("필요한 몫보다 작아서 콜하면 평균적으로 칩이 줄어요.",
                 "Your share is lower, so calling loses chips on average."),
            Copy("필요한 몫과 같아요. 콜과 폴드의 평균 결과가 같아요.",
                 "Your share is exactly what you need. Calling and folding have the same average result."),
        ][answer]
        let prompt = Copy(
            "\(finalModel.text(in: .korean)) 팟에서 가져올 평균 몫을 보고 골라요. 콜과 폴드의 평균 결과가 같으면 ‘손익분기’를 고르세요.",
            "\(finalModel.text(in: .english)) Use your average share of the pot. Choose Break even if calling and folding have the same average result."
        )
        let rows = mixed ? [price.potRow] + price.payments : [price.potRow, price.callRow]
        let calculation = mixed
            ? Copy("콜에 \(price.facing) − \(price.paid) = \(price.cost)개가 들어요. 팟은 \(price.now) + \(price.cost) = \(price.final)개가 돼요.",
                   "The call costs \(price.facing) − \(price.paid) = \(price.cost). The final pot is \(price.now) + \(price.cost) = \(price.final).")
            : Copy("콜한 뒤 팟은 \(price.final)개예요.", "The pot after a call is \(price.final).")
        return question(
            id, title: Copy("콜, 폴드, 손익분기", "Call, fold, or break even"), prompt: prompt,
            rows: rows + [shareRow(equity)],
            choices: [Copy("콜", "Call"), Copy("폴드", "Fold"), Copy("손익분기", "Break even")], answer: answer,
            explanation: Copy(
                "\(calculation.text(in: .korean)) 손익분기점은 \(price.equation)예요. 내 몫은 \(percent(equity))예요. \(outcome.text(in: .korean))",
                "\(calculation.text(in: .english)) You need \(price.equation) to break even. Your share is \(percent(equity)). \(outcome.text(in: .english))"
            ),
            worked: worked
        )
    }

    private static func changePrice(_ id: String, pot: Int, bets: (Int, Int),
                                    deal: TurnDeal, hand: String, equity: Int,
                                    worked: Bool = false) -> TableCourseActivity {
        let small = Price(pot, 0, bets.0)
        let large = Price(pot, 0, bets.1)
        let options = [Copy("작은 벳만", "Small bet only"), Copy("큰 벳만", "Large bet only"),
                       Copy("둘 다", "Both"), Copy("둘 다 아님", "Neither")]
        let answer = profitableChoices(small.edge(with: equity), large.edge(with: equity))
        let rows = [
            Row(Copy("벳 전 팟", "Pot before the bet"), chips(pot)),
            Row(Copy("작은 벳", "Small bet"), chips(small.cost)),
            Row(Copy("큰 벳", "Large bet"), chips(large.cost)),
            shareRow(equity),
        ]
        return question(
            id, title: Copy("같은 카드, 다른 가격", "Same cards, different price"),
            prompt: Copy("\(turnModel.text(in: .korean)) 상대가 처음 벳했어요. 어떤 벳에 콜하면 평균적으로 칩이 늘까요?",
                         "\(turnModel.text(in: .english)) The opponent bets first. Which bet can you call to gain chips on average?"),
            rows: rows, cards: Card.parse(hand)!, board: deal.board, opponent: deal.opponent,
            choices: options, answer: answer,
            explanation: Copy(
                "같은 카드라 내 평균 몫은 \(percent(equity))로 같아요. 손익분기점은 작은 벳에 \(small.equation), 큰 벳에 \(large.equation)예요. 답은 ‘\(options[answer].text(in: .korean))’예요.",
                "Your share stays \(percent(equity)). The small bet needs \(small.equation), and the large bet needs \(large.equation). The answer is \(options[answer].text(in: .english).lowercased())."
            ),
            worked: worked
        )
    }

    private static func changeChance(_ id: String, price: Price, deal: TurnDeal,
                                     hands: (String, String), equities: (Int, Int),
                                     worked: Bool = false) -> TableCourseActivity {
        let options = [Copy("핸드 A만", "Hand A only"), Copy("핸드 B만", "Hand B only"),
                       Copy("둘 다", "Both"), Copy("둘 다 아님", "Neither")]
        let answer = profitableChoices(price.edge(with: equities.0), price.edge(with: equities.1))
        let rows = [
            price.potRow, price.callRow,
            handRow("A", Card.parse(hands.0)!, equity: equities.0),
            handRow("B", Card.parse(hands.1)!, equity: equities.1),
        ]
        return question(
            id, title: Copy("같은 가격, 다른 가능성", "Same price, different chance"),
            prompt: Copy("\(turnModel.text(in: .korean)) A와 B는 내 카드가 달라진 두 경우예요. 어떤 핸드로 콜하면 평균적으로 칩이 늘까요?",
                         "\(turnModel.text(in: .english)) A and B are two possible hands you could hold. Which can you call with to gain chips on average?"),
            rows: rows, board: deal.board, opponent: deal.opponent, choices: options, answer: answer,
            explanation: Copy(
                "\(worked ? turnShare.text(in: .korean) + " " : "")두 핸드의 손익분기점은 같아요. \(price.equation). A의 평균 몫은 \(percent(equities.0)), B는 \(percent(equities.1))예요. 답은 ‘\(options[answer].text(in: .korean))’예요.",
                "\(worked ? turnShare.text(in: .english) + " " : "")Both hands need \(price.equation) to break even. Hand A gets \(percent(equities.0)) on average and Hand B gets \(percent(equities.1)). The answer is \(options[answer].text(in: .english))."
            ),
            worked: worked
        )
    }

    private static func profitableChoices(_ first: Int, _ second: Int) -> Int {
        switch (first > 0, second > 0) {
        case (true, false): 0
        case (false, true): 1
        case (true, true): 2
        case (false, false): 3
        }
    }

    private static func question(_ id: String, title: Copy, prompt: Copy, rows: [Row],
                                 cards: [Card] = [], board: [Card] = [], opponent: [Card] = [],
                                 choices: [Copy], answer: Int,
                                 explanation: Copy, worked: Bool) -> TableCourseActivity {
        let shift = (id.last?.wholeNumberValue ?? 0) % choices.count
        let rotated = Array(choices[shift...]) + choices[..<shift]
        return TableCourseActivity(
            id: id, title: title, prompt: prompt,
            evidence: .init(cards: cards, board: board, opponent: opponent, rows: rows),
            choices: worked ? [] : rotated,
            correctChoice: worked ? nil : (answer - shift + choices.count) % choices.count,
            explanation: explanation
        )
    }

    private static func shareRow(_ equity: Int) -> Row {
        let text = percent(equity)
        return Row(Copy("내 평균 팟 몫", "Your average pot share"), Copy(text, text))
    }

    private static func handRow(_ letter: String, _ cards: [Card], equity: Int) -> Row {
        let text = "\(cardLabels(cards)) · \(percent(equity))"
        return Row(Copy("핸드 \(letter) · 평균 팟 몫", "Hand \(letter) · Average pot share"), Copy(text, text))
    }

    private static func cardLabels(_ cards: [Card]) -> String {
        let suits = ["♣", "♦", "♥", "♠"]
        return cards.map { card in
            let rank = String(card.description.prefix(1))
            return "\(rank == "T" ? "10" : rank)\(suits[card.suit])"
        }.joined(separator: " ")
    }

    private static func chips(_ count: Int) -> Copy {
        Copy("칩 \(count)개", count == 1 ? "1 chip" : "\(count) chips")
    }

    private static func percent(_ tenths: Int) -> String {
        let (whole, remainder) = tenths.quotientAndRemainder(dividingBy: 10)
        return remainder == 0 ? "\(whole)%" : "\(whole).\(remainder)%"
    }
}
