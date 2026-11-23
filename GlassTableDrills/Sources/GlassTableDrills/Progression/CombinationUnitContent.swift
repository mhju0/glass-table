// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

enum CombinationUnitContent {
    private typealias Copy = TableCourseText

    static func activities(for lesson: TableCourseLesson) -> [TableCourseActivity] {
        switch lesson {
        case .j1:
            [
                countExample,
                countClass("J1-01", "AcJd", [6, 16, 12]),
                countClass("J1-02", "QhQd", [6, 4, 12]),
                countClass("J1-03", "Ts9s", [12, 4, 6]),
            ]
        case .j2:
            [
                cardRemoval("J2-example", "AKs", board: "AhKh2d"),
                cardRemoval("J2-01", "JJ", board: "Jc8d2s", options: [6, 3, 4]),
                cardRemoval("J2-02", "KQs", board: "KsQd2h", options: [2, 3, 4]),
                cardRemoval("J2-03", "ATo", board: "AsTd7c", options: [6, 9, 7]),
            ]
        case .j3:
            [
                countRange("J3-example", "KK+, AKs", notation: .pairPlus),
                countRange("J3-01", "QQ, AQo, JTs", options: [22, 20, 18]),
                countRange("J3-02", "AJs+, AKs", notation: .suitedPlus, options: [16, 8, 12]),
                countRange("J3-03", "98s-76s, 88", notation: .run, options: [14, 18, 24]),
            ]
        case .j4:
            [
                compareWeights("J4-example", [("KK", 75), ("AJs", 25)], [("QTo", 25), ("QTs", 50)], worked: true),
                compareWeights("J4-01", [("QQ", 100), ("AKo", 50)], [("KQs", 100), ("JTs", 100)]),
                compareWeights("J4-02", [("AJo", 25)], [("QJs", 100)]),
                compareWeights("J4-03", [("T9o", 50)], [("99", 100)]),
            ]
        case .j5:
            [
                reconcile("J5-example", guess: "JJ, AJo", model: "JJ, AJs"),
                reconcile("J5-01", guess: "QQ, KQs", model: "QQ, KQs, QJs",
                          edits: [.add("QJs"), .remove("KQs"), .replace("KQs", with: "QJs")]),
                reconcile("J5-02", guess: "TT, ATo, ATs", model: "TT, ATs",
                          edits: [.remove("ATs"), .replace("ATo", with: "AQo"), .remove("ATo")]),
                reconcile("J5-03", guess: "88, JTs, T9s", model: "88, J9s, T9s",
                          edits: [.add("J9s"), .replace("JTs", with: "J9s"), .remove("JTs")]),
            ]
        default:
            []
        }
    }

    static func reviewActivities(for lesson: TableCourseLesson) -> [TableCourseActivity] {
        switch lesson {
        case .j1:
            [
                countClass("J1-review-01", "8h8c", [4, 12, 6]),
                countClass("J1-review-02", "KdJd", [4, 6, 12]),
                countClass("J1-review-03", "7s6c", [16, 12, 6]),
            ]
        case .j2:
            [
                cardRemoval("J2-review-01", "QQ", board: "QdQs2c", options: [3, 1, 2]),
                cardRemoval("J2-review-02", "JTs", board: "Jh3c2d", options: [2, 4, 3]),
                cardRemoval("J2-review-03", "KJo", board: "KcJc9s", options: [6, 7, 9]),
            ]
        case .j3:
            [
                countRange("J3-review-01", "JJ+, AKo", notation: .pairPlus, options: [30, 36, 24]),
                countRange("J3-review-02", "KTs+, JTo", notation: .suitedPlus, options: [24, 20, 28]),
                countRange("J3-review-03", "T9s-87s, 98s, KK", notation: .run, options: [22, 16, 18]),
            ]
        case .j4:
            [
                compareWeights("J4-review-01", [("AKs", 75)], [("JJ", 50)]),
                compareWeights("J4-review-02", [("QJo", 50), ("T9s", 25)], [("AA", 100)]),
                compareWeights("J4-review-03", [("ATo", 25)], [("88", 50), ("87s", 50)]),
            ]
        case .j5:
            [
                reconcile("J5-review-01", guess: "99, KJs, KJo", model: "99, KJo",
                          edits: [.replace("KJs", with: "QJs"), .remove("KJs"), .remove("KJo")]),
                reconcile("J5-review-02", guess: "77, 98o", model: "77, 98s",
                          edits: [.replace("98o", with: "98s"), .remove("98o"), .add("98s")]),
                reconcile("J5-review-03", guess: "66, A5s", model: "66, A5s, A4s",
                          edits: [.remove("A5s"), .replace("A5s", with: "A4s"), .add("A4s")]),
            ]
        default:
            []
        }
    }

    private static var countExample: TableCourseActivity {
        let hands = [("99", "9c9d"), ("AKs", "AcKc"), ("AKo", "AcKd")]
        let rows = hands.map { notation, example in
            let count = range(notation).combos().count
            let holding = cardSymbols(Card.parse(example)!)
            return TableCourseRow(same(notation), Copy("콤보 \(count)개 · 예를 들어 \(holding)",
                                                       "\(count) combos · e.g. \(holding)"))
        }
        return TableCourseActivity(
            id: "J1-example", title: Copy("한 칸에 콤보가 몇 개?", "How many combos in one class?"),
            prompt: Copy("콤보 하나는 숫자나 글자와 무늬까지 정해진 카드 두 장이에요.",
                         "One combo is an exact pair of cards, with both ranks and suits specified."),
            evidence: .init(rows: rows),
            explanation: Copy("페어는 네 무늬 중 두 개를 골라요. 카드 순서는 바뀌어도 같은 콤보예요. 수티드는 무늬마다 하나씩, 오프수트는 첫 카드의 무늬마다 다른 무늬가 세 개씩 있어요.",
                              "For a pair, pick two of four suits. Swapping the cards gives the same combo. Suited hands have one combo per suit. Offsuit hands have three choices for the second suit for each first suit.")
        )
    }

    private static func countClass(_ id: String, _ deal: String, _ options: [Int]) -> TableCourseActivity {
        let cards = Card.parse(deal)!
        let hand = HandClass(cards)!
        let evidence = TableCourseEvidence(cards: cards, rows: [handRow(hand.description)])
        let explanation: Copy
        if hand.isPair {
            explanation = Copy("같은 숫자나 글자의 카드 네 장 중 두 장을 골라요. 순서를 구분하지 않으니 4 × 3 ÷ 2예요.",
                               "Pick two of the four cards of this rank. Order is irrelevant, so use 4 × 3 ÷ 2.")
        } else if hand.suited {
            explanation = Copy("두 카드의 무늬를 같게 맞춰요. 클럽, 다이아몬드, 하트, 스페이드마다 한 콤보씩이에요.",
                               "Match the suits of the two cards. There is one combo each for clubs, diamonds, hearts and spades.")
        } else {
            explanation = Copy("높은 카드의 무늬는 네 가지예요. 각각에 대해 낮은 카드는 다른 무늬 세 가지가 가능해요. 4 × 3이에요.",
                               "The higher card can have any of four suits. For each one, the lower card can have one of three other suits. Multiply 4 × 3.")
        }
        return countQuestion(
            id: id, title: Copy("한 핸드 종류의 콤보", "Combos in one hand class"),
            prompt: Copy("아래 두 장은 예시예요. 덱에 카드가 모두 있을 때 이 핸드 종류의 콤보는 몇 개일까요?",
                         "These two cards show one example. How many combos of this class are in a full deck?"),
            evidence: evidence, options: options, count: hand.combos().count, explanation: explanation
        )
    }

    private static func cardRemoval(
        _ id: String, _ notation: String, board boardText: String, options: [Int] = []
    ) -> TableCourseActivity {
        let board = Card.parse(boardText)!
        let handRange = range(notation)
        let all = handRange.combos()
        let legal = handRange.combos(removing: board)
        let blocked = all.filter { $0.contains(where: board.contains) }
        let rows = [handRow(notation)]
        let result = TableCourseEvidence(board: board, rows: rows + [
            TableCourseRow(Copy("처음 콤보", "Starting combos"), comboCount(all.count)),
            TableCourseRow(Copy("뺀 콤보", "Blocked combos"), comboCount(blocked.count)),
            TableCourseRow(Copy("막힌 콤보 예시", "One blocked combo"), same(cardSymbols(blocked[0]))),
            TableCourseRow(Copy("남은 콤보", "Combos left"), comboCount(legal.count)),
        ])
        return countQuestion(
            id: id, title: Copy("공용 카드에 막힌 콤보", "Combos blocked by the board"),
            prompt: Copy("아래 공용 카드만 빼고 센다면 상대에게 가능한 콤보는 몇 개일까요?",
                         "If you remove only the shared cards shown, how many combos could an opponent hold?"),
            evidence: .init(board: board, rows: rows), options: options, count: legal.count,
            explanation: Copy("공용 카드가 한 장이라도 들어 있는 콤보는 빼요. 두 장 모두 공용 카드여도 그 콤보는 한 번만 빼요.",
                              "Cross out any combo that uses a shared card. Even if it uses two shared cards, cross it out once."),
            result: result
        )
    }

    private enum NotationHint {
        case pairPlus, suitedPlus, run

        var copy: Copy {
            switch self {
            case .pairPlus:
                Copy("페어 뒤의 +는 그 페어부터 AA까지예요.",
                     "A plus after a pair includes that pair through AA.")
            case .suitedPlus:
                Copy("수티드 뒤의 +는 높은 카드를 그대로 두고, 낮은 카드를 한 단계씩 올려요.",
                     "A plus after a suited class keeps the high rank fixed and steps the lower rank up.")
            case .run:
                Copy("하이픈으로 이은 두 표기는 양 끝을 포함해 두 숫자나 글자가 함께 한 단계씩 내려가요.",
                     "A hyphen includes both endpoints and steps both ranks down together.")
            }
        }
    }

    private static func countRange(
        _ id: String, _ notation: String, notation hint: NotationHint? = nil, options: [Int] = []
    ) -> TableCourseActivity {
        let handRange = range(notation)
        let rows = [TableCourseRow(Copy("적힌 레인지", "Written range"), same(notation))]
            + (hint.map { [TableCourseRow(Copy("표기 읽기", "Read the notation"), $0.copy)] } ?? [])
        let breakdown = handRange.classes.map { "\($0) · \($0.combos().count)" }.joined(separator: ", ")
        let count = handRange.combos().count
        return countQuestion(
            id: id, title: Copy("레인지의 콤보 세기", "Count a written range"),
            prompt: Copy("카드가 모두 있고 적힌 핸드를 항상 쓴다고 할 때, 서로 다른 콤보는 모두 몇 개일까요?",
                         "Start with a full deck and include each listed hand at full frequency. How many distinct combos are in the range?"),
            evidence: .init(rows: rows), options: options, count: count,
            explanation: Copy("표기를 펼쳐서 같은 핸드 종류는 한 번만 남겨요. 페어는 6개, 수티드는 4개, 오프수트는 12개씩 더해요.",
                              "Expand the notation and keep each hand class once. Add six per pair, four per suited class and twelve per offsuit class."),
            result: .init(rows: rows + [
                TableCourseRow(Copy("핸드 종류별 콤보", "Combos by class"), same(breakdown)),
                TableCourseRow(Copy("합계", "Total"), comboCount(count)),
            ])
        )
    }

    private static func compareWeights(
        _ id: String, _ entriesA: [(String, Int)], _ entriesB: [(String, Int)], worked: Bool = false
    ) -> TableCourseActivity {
        let a = weightedRange(entriesA)
        let b = weightedRange(entriesB)
        let totalA = a.comboCount
        let totalB = b.comboCount
        let labels = [Copy("레인지 A", "Range A"), Copy("레인지 B", "Range B")]
        let choices = labels + [Copy("같아요", "Equal")]
        let answer = totalA == totalB ? 2 : totalA > totalB ? 0 : 1
        let rows = zip(labels, [entriesA, entriesB]).map { label, entries in
            let listing = entries.map { "\($0.0) \($0.1)%" }.joined(separator: ", ")
            return TableCourseRow(label, same(listing))
        }
        let result = TableCourseEvidence(rows: rows + [
            weightResult(Copy("레인지 A 계산", "Range A calculation"), a),
            weightResult(Copy("레인지 B 계산", "Range B calculation"), b),
            TableCourseRow(Copy("비교 결과", "Comparison result"), choices[answer]),
        ])
        return TableCourseActivity(
            id: id, title: Copy("가중 콤보 합계 비교", "Compare weighted combo totals"),
            prompt: Copy("덱에는 카드가 모두 있어요. 퍼센트는 해당 종류의 각 콤보를 쓰는 빈도예요. 빈도까지 반영한 합계가 어느 쪽이 더 클까요?",
                         "Use a full deck. Each percentage is how often each combo in that class is played. Which range has the larger weighted total?"),
            evidence: worked ? result : .init(rows: rows),
            choices: worked ? [] : choices, correctChoice: worked ? nil : answer,
            explanation: Copy("핸드 종류마다 가능한 콤보 수에 빈도를 곱한 뒤 더해요. 빈도가 0%보다 크면 그 종류의 카드 조합은 모두 가능해요.",
                              "Multiply each class's combo count by its frequency, then add. At any frequency above zero, every physical combo of that class is possible."),
            revealedEvidence: worked ? nil : result
        )
    }

    private static func weightedRange(_ entries: [(String, Int)]) -> HandRange {
        HandRange(Dictionary(uniqueKeysWithValues: entries.map { label, percent in
            (range(label).classes[0], Double(percent) / 100)
        }))
    }

    private static func weightResult(_ label: Copy, _ handRange: HandRange) -> TableCourseRow {
        let terms = handRange.classes.map { hand in
            "\(hand) \(hand.combos().count) × \(Int((handRange.weight(hand) * 100).rounded()))%"
        }.joined(separator: " + ")
        let weighted = number(handRange.comboCount)
        let physical = handRange.combos().count
        return TableCourseRow(label, Copy(
            "\(terms) = \(weighted) 가중 콤보 · 가능한 카드 조합 \(physical)개",
            "\(terms) = \(weighted) weighted combos · \(physical) physical combos"
        ))
    }

    private enum RangeEdit {
        case add(String), remove(String), replace(String, with: String)

        var label: Copy {
            switch self {
            case let .add(hand): Copy("\(hand) 추가", "Add \(hand)")
            case let .remove(hand): Copy("\(hand) 빼기", "Remove \(hand)")
            case let .replace(from, to): Copy("\(from) 빼고 \(to) 추가", "Remove \(from) and add \(to)")
            }
        }

        func apply(to estimate: HandRange) -> HandRange {
            switch self {
            case let .add(hand): estimate.union(range(hand))
            case let .remove(hand): estimate.subtracting(range(hand))
            case let .replace(from, to): estimate.subtracting(range(from)).union(range(to))
            }
        }
    }

    private static func reconcile(
        _ id: String, guess: String, model: String, edits: [RangeEdit] = []
    ) -> TableCourseActivity {
        let estimate = range(guess)
        let actual = range(model)
        let missing = actual.subtracting(estimate)
        let extra = estimate.subtracting(actual)
        let rows = [
            TableCourseRow(Copy("내 추정", "My estimate"), same(guess)),
            TableCourseRow(Copy("공개된 연습 모델", "Revealed practice model"), same(model)),
        ]
        let result = TableCourseEvidence(rows: rows + [
            TableCourseRow(Copy("추가할 핸드", "Add to the estimate"), rangeDifference(missing)),
            TableCourseRow(Copy("뺄 핸드", "Remove from the estimate"), rangeDifference(extra)),
        ])
        let worked = edits.isEmpty
        return TableCourseActivity(
            id: id, title: Copy("공개된 레인지와 비교", "Check the revealed range"),
            prompt: Copy("공개된 연습 모델에 맞추려면 추정을 어떻게 고칠까요?",
                         "What change would make the estimate match the revealed practice model?"),
            evidence: worked ? result : .init(rows: rows), choices: edits.map(\.label),
            correctChoice: worked ? nil : edits.firstIndex { $0.apply(to: estimate) == actual }!,
            explanation: Copy("모델에만 있는 핸드는 더하고, 내 추정에만 있는 핸드는 빼요. 양쪽에 있는 핸드는 그대로 둬요.",
                              "Add hands found only in the model, remove hands found only in your estimate, and keep the hands they share."),
            revealedEvidence: worked ? nil : result
        )
    }

    private static func rangeDifference(_ handRange: HandRange) -> Copy {
        guard !handRange.isEmpty else { return Copy("없음", "None") }
        let listing = RangeNotation.print(handRange)
        let count = handRange.combos().count
        return Copy("\(listing) · 콤보 \(count)개", "\(listing) · \(count) combos")
    }

    private static func countQuestion(
        id: String, title: Copy, prompt: Copy, evidence: TableCourseEvidence, options: [Int],
        count: Int, explanation: Copy, result: TableCourseEvidence? = nil
    ) -> TableCourseActivity {
        let worked = options.isEmpty
        let revealed = result ?? TableCourseEvidence(cards: evidence.cards, board: evidence.board, rows: evidence.rows + [
            TableCourseRow(Copy("합계", "Total"), comboCount(count)),
        ])
        return TableCourseActivity(
            id: id, title: title, prompt: prompt, evidence: worked ? revealed : evidence,
            choices: options.map(comboCount), correctChoice: worked ? nil : options.firstIndex(of: count)!,
            explanation: explanation, revealedEvidence: worked ? nil : revealed
        )
    }

    private static func same(_ text: String) -> Copy { Copy(text, text) }

    private static func range(_ notation: String) -> HandRange {
        // Restored and reviewed activities use fixed, authored notation.
        try! RangeNotation.parse(notation)
    }

    private static func handRow(_ notation: String) -> TableCourseRow {
        TableCourseRow(Copy("핸드 종류", "Hand class"), same(notation))
    }

    private static func comboCount(_ count: Int) -> Copy {
        Copy("콤보 \(count)개", count == 1 ? "1 combo" : "\(count) combos")
    }

    private static func cardSymbols(_ cards: [Card]) -> String {
        cards.map { card in
            let rank = card.rank == 10 ? "10" : HandClass.rankChars[card.rank - 2]
            return rank + ["♣", "♦", "♥", "♠"][card.suit]
        }.joined(separator: " ")
    }

    private static func number(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(value)
    }
}
