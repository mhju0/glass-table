// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

enum StartingHandUnitContent {
    private typealias Copy = TableCourseText

    static func activities(for lesson: TableCourseLesson) -> [TableCourseActivity] {
        switch lesson {
        case .e1:
            [
                classify("E1-example", "QhQs", worked: true),
                classify("E1-01", "AsJs"),
                classify("E1-02", "KdQc"),
                classify("E1-03", "8h8d"),
                classify("E1-04", "7c6c"),
            ]
        case .e2:
            [
                range("E2-example", "AhKh", ["AhKh QsQc", "AhKd JhJs"], worked: true),
                range("E2-01", "AcKd", ["AsQs ThTc", "AcKd 9h9d"]),
                range("E2-02", "JhJc", ["QdJd JhJc", "AhJh KsQs"]),
                range("E2-03", "6d5d", ["6d5h 6h6c", "7s6s 5d6d"]),
                range("E2-04", "Tc9d", ["Tc9c 8h8d", "JsTc Tc8d"]),
            ]
        case .e3:
            [
                locate("E3-example", "AhKh", ["AKo", "AKs", "AA"], worked: true),
                locate("E3-01", "AdKc", ["AKs", "KK", "AKo"]),
                locate("E3-02", "ThTd", ["TT", "T9s", "T9o"]),
                locate("E3-03", "Jd9d", ["J9o", "J9s", "99"]),
                locate("E3-04", "QcTs", ["QTs", "QTo", "QQ"]),
            ]
        case .e4:
            [
                opening("E4-example", "AhAs", from: .utg, worked: true),
                opening("E4-01", "7h2c", from: .co),
                opening("E4-02", "KsQs", from: .lj),
                opening("E4-03", "4h9s", from: .btn),
                opening("E4-04", "TcTs", from: .hj),
            ]
        case .e5:
            [
                opening("E5-example", "As9d", from: .utg, compare: .btn, worked: true),
                opening("E5-01", "7d6d", from: .utg1, compare: .lj),
                opening("E5-02", "7d6d", from: .lj, compare: .utg1),
                opening("E5-03", "KhTd", from: .lj, compare: .hj),
                opening("E5-04", "KhTd", from: .hj, compare: .lj),
            ]
        case .e6:
            [
                defending("E6-example", "AhJh", learner: .co, opener: .hj, worked: true),
                defending("E6-01", "QhJh", learner: .btn, opener: .utg),
                defending("E6-02", "QhJh", learner: .btn, opener: .co),
                defending("E6-03", "8s5d", learner: .co, opener: .lj),
                defending("E6-04", "KcQd", learner: .btn, opener: .hj),
            ]
        case .e7:
            [
                chartChoice("E7-example", "KsJd", learner: .co, worked: true),
                chartChoice("E7-01", "QsTs", learner: .btn, opener: .hj),
                chartChoice("E7-02", "5s4s", learner: .co),
                opening("E7-03", "AhTc", from: .co),
                defending("E7-04", "AhTc", learner: .co, opener: .hj),
            ]
        default:
            []
        }
    }

    static func reviewActivities(for lesson: TableCourseLesson) -> [TableCourseActivity] {
        switch lesson {
        case .e1:
            [
                classify("E1-review-01", "9h9s"),
                classify("E1-review-02", "Qc8c"),
                classify("E1-review-03", "4dJs"),
            ]
        case .e2:
            [
                range("E2-review-01", "KdJd", ["KdJd 7h7c", "KdJh 6h6c"]),
                range("E2-review-02", "Th8c", ["Th8h QdQc", "Th9c JhJs"]),
                range("E2-review-03", "4h4c", ["5h4h 5s5d", "4h4c 4d3d"]),
            ]
        case .e3:
            [
                locate("E3-review-01", "Ad5d", ["A5s", "55", "A5o"]),
                locate("E3-review-02", "9s7c", ["97s", "97o", "99"]),
                locate("E3-review-03", "6s6h", ["65s", "65o", "66"]),
            ]
        case .e4:
            [
                opening("E4-review-01", "JcJd", from: .utg1),
                opening("E4-review-02", "6h2d", from: .btn),
                opening("E4-review-03", "AhQd", from: .co),
            ]
        case .e5:
            [
                opening("E5-review-01", "5h4h", from: .hj, compare: .co),
                opening("E5-review-02", "Th9s", from: .lj, compare: .hj),
                opening("E5-review-03", "5c5h", from: .co, compare: .hj),
            ]
        case .e6:
            [
                defending("E6-review-01", "JhQd", learner: .btn, opener: .co),
                defending("E6-review-02", "AsTc", learner: .hj, opener: .utg1),
                defending("E6-review-03", "QcJc", learner: .co, opener: .lj),
            ]
        default:
            []
        }
    }

    private static func classify(_ id: String, _ deal: String, worked: Bool = false) -> TableCourseActivity {
        let cards = Card.parse(deal)!
        let hand = HandClass(cards)!
        let category = hand.isPair ? 0 : hand.suited ? 1 : 2
        let choices = [Copy("페어", "Pair"), Copy("수티드", "Suited"), Copy("오프수트", "Offsuit")]
        let reasons = [
            Copy("두 카드의 숫자나 글자가 같으면 페어예요. 무늬는 달라요.",
                 "Matching ranks make a pair. The two suits are different."),
            Copy("숫자나 글자가 다르고 무늬가 같으면 수티드이에요.",
                 "Different ranks with matching suits make a suited hand."),
            Copy("숫자나 글자도 다르고 무늬도 다르면 오프수트이에요.",
                 "Different ranks and different suits make an offsuit hand."),
        ]
        return TableCourseActivity(
            id: id, title: Copy("내 카드 두 장", "Your two cards"),
            prompt: worked ? reasons[category] : Copy("이 두 카드는 어떤 종류일까요?", "How would you sort these two cards?"),
            evidence: .init(cards: cards), choices: worked ? [] : choices,
            correctChoice: worked ? nil : category, explanation: reasons[category]
        )
    }

    private static func range(
        _ id: String, _ deal: String, _ lists: [String], worked: Bool = false
    ) -> TableCourseActivity {
        let cards = Card.parse(deal)!
        let possibleHands = lists.map { list in list.split(separator: " ").map { Card.parse(String($0))! } }
        let match = possibleHands.firstIndex { list in list.contains { Set($0) == Set(cards) } }
        let listName = match == 0 ? "A" : "B"
        let explanation: Copy
        if worked {
            explanation = Copy("레인지는 상대가 가질 수 있는 핸드의 목록이에요. 이 두 카드가 목록 A에 있어요.",
                               "A range is a list of hands someone could have. These two cards appear in List A.")
        } else if match != nil {
            explanation = Copy("두 카드의 숫자와 무늬를 하나씩 비교해 보세요. 목록 \(listName)에 같은 두 카드가 있어요.",
                               "Compare the rank and suit of each card. List \(listName) has both cards as one hand.")
        } else {
            explanation = Copy("두 목록 어디에도 이 두 카드가 한 핸드로 들어 있지 않아요.",
                               "Neither list contains both of these cards as one hand.")
        }
        let rows = zip(["A", "B"], possibleHands).map { name, list in
            let holdings = list.map { hand in
                hand.map { card in
                    HandClass.rankChars[card.rank - 2] + ["♣", "♦", "♥", "♠"][card.suit]
                }.joined(separator: " ")
            }.joined(separator: "  ·  ")
            return TableCourseRow(Copy("목록 \(name)", "List \(name)"), Copy(holdings, holdings))
        }
        return TableCourseActivity(
            id: id, title: Copy("가능한 핸드 목록", "Lists of possible hands"),
            prompt: worked ? explanation : Copy("이 핸드가 들어가는 목록을 골라보세요.", "Which list includes this hand?"),
            evidence: .init(cards: cards, rows: rows),
            choices: worked ? [] : [Copy("목록 A", "List A"), Copy("목록 B", "List B"), Copy("둘 다 아님", "Neither")],
            correctChoice: worked ? nil : (match ?? 2), explanation: explanation
        )
    }

    private static func locate(
        _ id: String, _ deal: String, _ labels: [String], worked: Bool = false
    ) -> TableCourseActivity {
        let cards = Card.parse(deal)!
        let hand = HandClass(cards)!
        let name = hand.description
        let explanation: Copy
        if hand.isPair {
            explanation = Copy("가로와 세로에서 같은 숫자나 글자를 찾아요. 대각선에 있는 \(name)이 맞아요.",
                               "Use the same rank for the row and column. \(name) sits on the diagonal.")
        } else if hand.suited {
            explanation = Copy("무늬가 같으면 표의 대각선 위쪽을 봐요. 수티드 칸인 \(name)은 s로 끝나요.",
                               "Matching suits go above the diagonal. The suited cell \(name) ends in s.")
        } else {
            explanation = Copy("무늬가 다르면 표의 대각선 아래쪽을 봐요. 오프수트 칸인 \(name)은 o로 끝나요.",
                               "Different suits go below the diagonal. The offsuit cell \(name) ends in o.")
        }
        let title = Copy("시작 핸드 표", "Starting-hand grid")
        let before = TableCourseEvidence(cards: cards, chart: chart(title, highlight: worked ? hand : nil))
        let after = TableCourseEvidence(cards: cards, chart: chart(title, highlight: hand))
        return TableCourseActivity(
            id: id, title: Copy("표에서 한 칸 찾기", "Find one cell"),
            prompt: worked ? explanation : Copy("이 두 카드는 표의 어느 칸에 들어갈까요?", "Which cell matches these two cards?"),
            evidence: before, choices: worked ? [] : labels.map { Copy($0, $0) },
            correctChoice: worked ? nil : labels.firstIndex(of: name), explanation: explanation,
            revealedEvidence: worked ? nil : after
        )
    }

    static func opening(
        _ id: String, _ deal: String, from seat: Position, compare other: Position? = nil, worked: Bool = false
    ) -> TableCourseActivity {
        let cards = Card.parse(deal)!
        let hand = HandClass(cards)!
        let shouldOpen = RFIChart.opens(cards, from: seat)
        let openingRange = RFIChart.range(for: seat)
        let title = Copy("\(seat.rawValue) 오픈 차트", "\(seat.rawValue) opening chart")
        let result = openingLocation(hand, from: seat, opens: shouldOpen)
        let comparison = other.map {
            openingLocation(hand, from: $0, opens: RFIChart.opens(cards, from: $0))
        }
        let seatOrder = worked && other == nil ? [TableCourseRow(
            Copy("프리플랍 순서", "Preflop order"),
            Copy("앞자리 · UTG, UTG+1\n중간 · LJ, HJ\n뒷자리 · CO, BTN\n블라인드 · SB, BB",
                 "Early · UTG, UTG+1\nMiddle · LJ, HJ\nLate · CO, BTN\nBlinds · SB, BB")
        )] : []
        let rows = contextRows(learner: seat) + seatOrder + [TableCourseRow(
            Copy("차트 표시", "Chart key"), Copy("금색(+)은 오픈, 표시 없는 칸은 폴드", "Gold (+) means open. Plain tiles mean fold.")
        )]
        var revealRows = rows
        if let comparison {
            revealRows.append(TableCourseRow(Copy("같은 카드, 다른 자리", "Same cards, different seat"), comparison))
        }
        let explanation: Copy
        if worked, other != nil {
            explanation = Copy("뒤쪽 자리에서는 내 뒤에 행동할 사람이 줄어요. 같은 카드라도 자리마다 차트가 달라요. \(result.text(in: .korean))",
                               "From a later seat, fewer players act after you. With the same cards, use each seat’s own chart. \(result.text(in: .english))")
        } else if worked {
            let lesson = shouldOpen
                ? Copy("\(hand.description) 칸은 금색이라 오픈해요.", "\(hand.description) is gold. Open with a raise.")
                : Copy("\(hand.description) 칸에는 표시가 없어 폴드해요.", "\(hand.description) is plain. Fold this hand.")
            explanation = Copy("블라인드만 낸 상태예요.\n\(lesson.text(in: .korean))",
                               "The blinds are forced bets.\n\(lesson.text(in: .english))")
        } else {
            explanation = result
        }
        let prompt = worked ? explanation
            : Copy("이 자리에서 오픈 차트를 따라 어떻게 할까요?", "What does the opening chart say to do from this seat?")
        return TableCourseActivity(
            id: id, title: Copy("먼저 들어갈 차례", "First to enter"),
            prompt: prompt,
            evidence: .init(cards: cards, rows: worked ? revealRows : rows,
                            chart: chart(title, active: openingRange, highlight: worked ? hand : nil, activeLabel: Copy("오픈", "Open"))),
            choices: worked ? [] : [Copy("오픈", "Open"), Copy("폴드", "Fold")],
            correctChoice: worked ? nil : (shouldOpen ? 0 : 1), explanation: worked ? nil : explanation,
            revealedEvidence: worked ? nil : .init(cards: cards, rows: revealRows,
                                                    chart: chart(title, active: openingRange, highlight: hand, activeLabel: Copy("오픈", "Open")))
        )
    }

    private static func openingLocation(_ hand: HandClass, from seat: Position, opens: Bool) -> Copy {
        let name = hand.description
        let position = seat.rawValue
        return opens
            ? Copy("\(position) 차트에서 \(name) 칸은 금색이에요. 먼저 레이즈해요.",
                   "\(name) is gold on the \(position) chart. Raise first.")
            : Copy("\(position) 차트에서 \(name) 칸에 색이 없어요. 폴드해요.",
                   "\(name) is uncolored on the \(position) chart. Fold.")
    }

    static func defending(
        _ id: String, _ deal: String, learner: Position, opener: Position, worked: Bool = false
    ) -> TableCourseActivity {
        let cards = Card.parse(deal)!
        let hand = HandClass(cards)!
        let action = DefendChart.action(for: cards, vsOpenFrom: opener)
        let raiseRange = DefendChart.threeBetRange(vsOpenFrom: opener)
        let callRange = DefendChart.callRange(vsOpenFrom: opener)
        let title = Copy("\(opener.rawValue) 오픈 대응 차트", "Response chart vs. \(opener.rawValue)")
        let rows = contextRows(learner: learner, opener: opener) + [TableCourseRow(
            Copy("차트 표시", "Chart key"),
            Copy("금색(+)은 3벳, 초록색(●)은 콜, 표시 없는 칸은 폴드", "Gold (+) means raise again. Green (●) means call. Plain tiles mean fold.")
        )]
        let name = hand.description
        let correctChoice: Int
        let explanation: Copy
        switch action {
        case .threeBet:
            correctChoice = 2
            explanation = Copy("\(name) 칸은 금색이에요. 다시 올려요(3벳).",
                               "\(name) is gold. Raise again (3-bet).")
        case .call:
            correctChoice = 1
            explanation = Copy("\(name) 칸은 초록색이에요. 금액을 맞춰 콜해요.",
                               "\(name) is green. Call the raise.")
        case .fold:
            correctChoice = 0
            explanation = Copy("\(name) 칸에 표시가 없어 폴드해요.",
                               "\(name) is plain. Fold this hand.")
        }
        let prompt = worked
            ? Copy("플랍 이후에는 내가 나중에 행동해요.\n\(explanation.text(in: .korean))",
                   "You act after the opener on the flop.\n\(explanation.text(in: .english))")
            : Copy("먼저 레이즈한 자리의 대응 차트를 읽어보세요. 어떻게 할까요?",
                   "Read the response chart for the opener's seat. What should you do?")
        return TableCourseActivity(
            id: id, title: Copy("레이즈를 마주했어요", "Facing a raise"),
            prompt: prompt,
            evidence: .init(cards: cards, rows: rows,
                            chart: chart(title, active: raiseRange, secondary: callRange, highlight: worked ? hand : nil,
                                         activeLabel: Copy("3벳", "Raise again"), secondaryLabel: Copy("콜", "Call"))),
            choices: worked ? [] : [Copy("폴드", "Fold"), Copy("콜", "Call"), Copy("3벳", "Raise again")],
            correctChoice: worked ? nil : correctChoice, explanation: worked ? nil : explanation,
            revealedEvidence: worked ? nil : .init(cards: cards, rows: rows,
                                                    chart: chart(title, active: raiseRange, secondary: callRange, highlight: hand,
                                                                 activeLabel: Copy("3벳", "Raise again"), secondaryLabel: Copy("콜", "Call")))
        )
    }

    private static func chartChoice(
        _ id: String, _ deal: String, learner: Position, opener: Position? = nil, worked: Bool = false
    ) -> TableCourseActivity {
        let cards = Card.parse(deal)!
        let opening = Copy("오픈 차트", "Opening chart")
        let response = Copy("대응 차트", "Response chart")
        let explanation = opener == nil
            ? Copy("아무도 자발적으로 칩을 넣지 않았다면 내 자리의 오픈 차트를 봐요.",
                   "When no one has entered voluntarily, use the opening chart for your own seat.")
            : Copy("앞에서 한 명이 오픈하면 먼저 레이즈한 자리의 대응 차트를 봐요.",
                   "When one player has opened, use the response chart for that player's seat.")
        return TableCourseActivity(
            id: id, title: Copy("어느 차트를 볼까요?", "Which chart fits?"),
            prompt: worked ? explanation : Copy("내 차례가 오기까지의 행동을 보고 차트를 골라보세요.",
                                                "Look at what happened before your turn and choose a chart."),
            evidence: .init(cards: cards, rows: contextRows(learner: learner, opener: opener, namesChart: worked)),
            choices: worked ? [] : [opening, response],
            correctChoice: worked ? nil : (opener == nil ? 0 : 1), explanation: worked ? nil : explanation
        )
    }

    private static func contextRows(
        learner: Position, opener: Position? = nil, namesChart: Bool = true
    ) -> [TableCourseRow] {
        let position = Copy(learner.plainName(in: .korean), learner == .btn ? "Button (BTN)" : learner.plainName(in: .english))
        let action: Copy
        let format: Copy
        if let opener {
            let raiser = opener.rawValue
            action = Copy("\(raiser)만 3 bb로 오픈했어요.\n내 앞의 나머지는 폴드했어요.",
                          "\(raiser) opened to 3 bb.\nEveryone else before you folded.")
            format = namesChart
                ? Copy("8인 · 100 bb · 플랍 이후 내가 나중에 행동해요. 먼저 올린 자리의 레인지로 대응 차트를 골라요.",
                       "8-seat table · 100 bb · You act later after the flop. Use the response chart for the opener’s range.")
                : Copy("8인 · 100 bb · 플랍 이후 내가 나중에 행동해요.",
                       "8-seat table · 100 bb · You act later after the flop.")
        } else {
            action = Copy("내 앞은 모두 폴드.\n블라인드만 낸 상태예요.",
                          "Everyone before you folded.\nOnly the blinds are posted.")
            format = namesChart
                ? Copy("8인 · 오픈 차트", "8 seats · Opening chart")
                : Copy("8인 테이블", "8-seat table")
        }
        return [
            TableCourseRow(Copy("내 자리", "Your seat"), position),
            TableCourseRow(Copy("앞선 행동", "Action so far"), action),
            TableCourseRow(Copy("연습 기준", "Practice model"), format),
        ]
    }

    private static func chart(
        _ title: Copy, active: HandRange = .init(), secondary: HandRange = .init(), highlight: HandClass?,
        activeLabel: Copy? = nil, secondaryLabel: Copy? = nil
    ) -> TableCourseChart {
        let header = [TableCourseChartCell("")] + RangeGrid.ranks.map {
            TableCourseChartCell(HandClass.rankChars[$0 - 2])
        }
        let rows = RangeGrid.ranks.map { row in
            [TableCourseChartCell(HandClass.rankChars[row - 2])] + RangeGrid.ranks.map { column in
                let hand = RangeGrid.classAt(row: row, col: column)
                return TableCourseChartCell(hand.description, active: active.weight(hand) > 0,
                                            secondary: secondary.weight(hand) > 0, highlighted: hand == highlight)
            }
        }
        return TableCourseChart(title: title, rows: [header] + rows, activeLabel: activeLabel,
                                secondaryLabel: secondaryLabel, inactiveLabel: activeLabel.map { _ in Copy("폴드", "Fold") })
    }
}
