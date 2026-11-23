// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

enum BoardPatternsUnitContent {
    private typealias Copy = TableCourseText
    private typealias Answer = (choices: [Copy], index: Int)
    private typealias Holding = (cards: [Card], weight: Int)

    static func activities(for lesson: TableCourseLesson) -> [TableCourseActivity] {
        switch lesson {
        case .l1:
            [
                madeShare("L1-example", "Ah9c4d", Lineup("AA, 87s", half: "AKo")),
                madeShare("L1-01", "Qh8h3c", Lineup("QQ, KQo", half: "JTs"), decoys: [67, 100], answerAt: 1),
                madeShare("L1-02", "Js6c2d", Lineup("66, KQo", half: "AJo"), decoys: [50, 67]),
                madeShare("L1-03", "Td8s6s3c", Lineup("TT, AKo", half: "97s"), decoys: [18, 50], answerAt: 2),
            ]
        case .l2:
            [
                compareBuckets("L2-example", "9h8h2c", Lineup("JTs", half: "AJs"), Lineup("AQo", half: "76s"),
                               bucket: .draw, worked: true),
                compareBuckets("L2-01", "JhTh4c", Lineup("KQo, 55"), Lineup("98s", half: "AJs"), bucket: .draw),
                compareBuckets("L2-02", "6s5s2d", Lineup("AKs", half: "98s"), Lineup("88", half: "AJo"), bucket: .air),
                compareBuckets("L2-03", "Ks7d3h", Lineup("AQs", half: "QTs"), Lineup("KJs", half: "A5s"), bucket: .air),
            ]
        case .l3:
            [
                compareBoards("L3-example", "AcKd4h2d9s", "8d7s6c2hJc",
                              Lineup("AA", half: "AKs"), Lineup("88, 87s", half: "AKo"), worked: true),
                compareBoards("L3-01", "Qs9d4c2h7c", "AhKdQdJcTs", Lineup("QQ", half: "AKo"), Lineup("99", half: "QJs")),
                compareBoards("L3-02", "AsQc7h4s3d", "Jc9h8s4d2c", Lineup("TT", half: "AJs"), Lineup("QTs", half: "99")),
                compareBoards("L3-03", "2s3d4h5c6s", "4s5d6h7c8s", Lineup("AKo", half: "KQs"), Lineup("AQo", half: "KJs")),
            ]
        case .l4:
            [
                sizingShare("L4-example", "KsQs4c", Lineup("KQo, JTs", half: "AJo"), action: .halfPot),
                sizingShare("L4-01", "Td9d3h", Lineup("KQs, TT", half: "JTs, AKo"),
                            action: .halfPot, decoys: [28, 41], answerAt: 2),
                sizingShare("L4-02", "7s6s2c", Lineup("77, 98s", half: "AKo"),
                            action: .pot, decoys: [31, 46], answerAt: 1),
                sizingShare("L4-03", "AhQc8d", Lineup("AQo, KJs, 76s", half: "55"),
                            action: .check, decoys: [39, 50]),
            ]
        case .l5:
            [
                readSmallBet("L5-example", "8h7h2d", Lineup("A8s, 88, KQo", half: "T9o"), worked: true),
                readSmallBet("L5-01", "JhTh3c", Lineup("KQo, 33", half: "AJo")),
                readSmallBet("L5-02", "QsJs3d", Lineup("T9o, QJs", half: "JTs")),
                readSmallBet("L5-03", "9d8d2c", Lineup("A9o, 22", half: "76s")),
            ]
        default:
            []
        }
    }

    static func reviewActivities(for lesson: TableCourseLesson) -> [TableCourseActivity] {
        switch lesson {
        case .l1:
            [
                madeShare("L1-review-01", "Kh6s3d", Lineup("KJo, AQs", half: "AA"), decoys: [56, 82], answerAt: 1),
                madeShare("L1-review-02", "9c7d5c", Lineup("86s", half: "99, AQo"), decoys: [35, 52], answerAt: 2),
                madeShare("L1-review-03", "AcTs7s2h", Lineup("77, J9s", half: "ATo"), decoys: [38, 100]),
            ]
        case .l2:
            [
                compareBuckets("L2-review-01", "QcJc4s", Lineup("AKo", half: "87s"), Lineup("T9s", half: "AQs"), bucket: .draw),
                compareBuckets("L2-review-02", "8d7d3c2s", Lineup("65s", half: "KQs"), Lineup("AJo", half: "KJs"), bucket: .air),
                compareBuckets("L2-review-03", "Th9d4h", Lineup("44", half: "J8s"), Lineup("QJs", half: "76s"), bucket: .draw),
            ]
        case .l3:
            [
                compareBoards("L3-review-01", "7h6h5d2dJh", "Ks8c3sTc2h",
                              Lineup("KK", half: "KQo"), Lineup("77", half: "98s")),
                compareBoards("L3-review-02", "JdTd8c3s2h", "As4s2sKsQs",
                              Lineup("AJo", half: "TT"), Lineup("QJs", half: "98s")),
                compareBoards("L3-review-03", "9c8h7d6s5c", "8c7h6d5s4c",
                              Lineup("AKs", half: "QJs"), Lineup("ATo", half: "KQo")),
            ]
        case .l4:
            [
                sizingShare("L4-review-01", "8s6s2h", Lineup("66, KQs", half: "87s"),
                            action: .halfPot, decoys: [12, 35], answerAt: 1),
                sizingShare("L4-review-02", "KcJc4s", Lineup("KJs, AJo", half: "QTs"),
                            action: .pot, decoys: [14, 43]),
                sizingShare("L4-review-03", "9h8c3d", Lineup("99, AKo", half: "87s"),
                            action: .check, decoys: [55, 64], answerAt: 2),
            ]
        case .l5:
            [
                readSmallBet("L5-review-01", "7c6c2d", Lineup("98o, A7s", half: "76s")),
                readSmallBet("L5-review-02", "Tc9c3h", Lineup("QJo, 99", half: "32s")),
                readSmallBet("L5-review-03", "KdJd5h", Lineup("KQo, 55", half: "98s")),
            ]
        default:
            []
        }
    }

    private struct Lineup {
        let label: Copy
        let full: HandRange
        let half: HandRange

        init(_ full: String, half: String = "") {
            self.full = try! RangeNotation.parse(full)
            self.half = try! RangeNotation.parse(half)
            precondition(Set(self.full.classes).isDisjoint(with: self.half.classes))
            label = half.isEmpty ? same(full) : same("100% — \(full) · 50% — \(half)")
        }

        func holdings(on board: [Card]) -> [Holding] {
            // Integer units of half a combo preserve exact comparisons.
            full.combos(removing: board).map { ($0, 2) } + half.combos(removing: board).map { ($0, 1) }
        }
    }

    private struct Profile {
        let weights: [MadeHand: Int]
        var total: Int { weights.values.reduce(0, +) }
        var singlePairs: Int { self[.weakPair] + self[.topPair] }
        var made: Int { singlePairs + self[.strong] }

        init(_ range: Lineup, on board: [Card]) {
            var counts: [MadeHand: Int] = [:]
            for holding in range.holdings(on: board) {
                counts[madeHand(hand: holding.cards, board: board), default: 0] += holding.weight
            }
            weights = counts
        }

        subscript(bucket: MadeHand) -> Int { weights[bucket, default: 0] }

        func distribution(_ title: Copy) -> TableCourseDistribution {
            bands(title, [
                (Copy("페어 이상", "Pair or better"), made),
                (drawLabel, self[.draw]),
                (missLabel, self[.air]),
            ])
        }
    }

    private static let rangeLabel = Copy("레인지", "Range")
    private static let rangeA = Copy("레인지 A", "Range A")
    private static let rangeB = Copy("레인지 B", "Range B")
    private static let boardA = Copy("보드 A", "Board A")
    private static let boardB = Copy("보드 B", "Board B")
    private static let drawLabel = Copy("페어 없는 드로우", "Unpaired draws")
    private static let missLabel = Copy("빗나간 패", "Misses")
    private static let equal = Copy("같아요", "Equal")

    private static func madeShare(
        _ id: String, _ boardText: String, _ range: Lineup, decoys: [Int] = [], answerAt: Int = 0
    ) -> TableCourseActivity {
        let board = Card.parse(boardText)!
        let profile = Profile(range, on: board)
        let worked = decoys.isEmpty
        let prompt = worked
            ? Copy("공용 카드와 겹치는 콤보를 빼고, 페어 이상이 된 패의 비율을 구해 봐요.",
                   "Remove combos blocked by the board, then find the share with a pair or better.")
            : Copy("공용 카드와 겹치는 콤보를 빼면, 페어 이상이 된 패는 레인지의 몇 퍼센트일까요? 정수로 반올림하세요.",
                   "After removing board blockers, what percentage of the range has a pair or better? Round to the nearest whole percent.")
        return activity(
            id, Copy("페어 이상이 된 비율", "Share with a made hand"), prompt,
            board: board, rows: [TableCourseRow(rangeLabel, range.label)],
            resultRows: [TableCourseRow(Copy("페어 이상 ÷ 전체", "Pair or better ÷ total"), division(profile.made, profile.total))],
            distributions: [profile.distribution(Copy("남은 레인지", "Remaining range"))],
            answer: percentAnswer(profile.made, outOf: profile.total, decoys: decoys, answerAt: answerAt),
            explanation: Copy("드로우가 있어도 페어가 있으면 페어 이상에 넣어요. 50%로 적힌 핸드는 가능한 콤보마다 0.5씩 세어요.",
                              "A pair plus a draw still counts as a made hand. Each legal combo listed at 50% counts as half a combo.")
        )
    }

    private static func compareBuckets(
        _ id: String, _ boardText: String, _ first: Lineup, _ second: Lineup, bucket: MadeHand, worked: Bool = false
    ) -> TableCourseActivity {
        let board = Card.parse(boardText)!
        let a = Profile(first, on: board)
        let b = Profile(second, on: board)
        let draws = bucket == .draw
        let target = draws ? drawLabel : missLabel
        let prompt: Copy
        if worked {
            prompt = Copy("같은 공용 카드에서도 출발 레인지에 따라 드로우의 비율이 달라져요.",
                          "On the same board, changing the starting range can change how often it has a draw.")
        } else if draws {
            prompt = Copy("페어가 없고 카드 한 장으로 스트레이트나 플러시가 되는 패의 비율은 어느 쪽이 더 높을까요?",
                          "Which range has a larger share of unpaired hands one card away from a straight or flush?")
        } else {
            prompt = Copy("페어 이상도, 한 장으로 완성되는 스트레이트나 플러시 드로우도 없는 패의 비율은 어느 쪽이 더 높을까요?",
                          "Which range has a larger share of hands with neither a pair or better nor a one-card straight or flush draw?")
        }
        return activity(
            id, Copy("드로우와 빗나간 패", "Draws and misses"), prompt,
            board: board, rows: rangeRows(first, second),
            resultRows: [TableCourseRow(target, comparison(a[bucket], of: a.total, b[bucket], of: b.total))],
            distributions: [a.distribution(rangeA), b.distribution(rangeB)],
            answer: worked ? nil : ([rangeA, rangeB, equal], higher(a[bucket] * b.total, b[bucket] * a.total)),
            explanation: Copy("각 레인지에서 해당 패의 가중치 합을 그 레인지 전체의 가중치 합으로 나누어요. 페어가 있는 드로우는 페어 이상에 들어가요.",
                              "Divide the weight of the target hands by the total weight of their own range. A hand with both a pair and a draw goes in the made-hand group.")
        )
    }

    private struct Showdown {
        var wins = 0
        var ties = 0
        var losses = 0
        var total: Int { wins + ties + losses }
        var twicePotShare: Int { 2 * wins + ties }

        init(_ first: Lineup, _ second: Lineup, on board: [Card]) {
            let opponents = second.holdings(on: board)
            for a in first.holdings(on: board) {
                for b in opponents where !a.cards.contains(where: b.cards.contains) {
                    let outcome = exactEquityHeadsUp(hero: a.cards, villain: b.cards, board: board)
                    let weight = a.weight * b.weight
                    wins += weight * outcome.wins
                    ties += weight * outcome.ties
                    losses += weight * (outcome.total - outcome.wins - outcome.ties)
                }
            }
        }

        func distribution(_ title: Copy) -> TableCourseDistribution {
            bands(title, [(Copy("승리", "Win"), wins), (Copy("무승부", "Tie"), ties), (Copy("패배", "Loss"), losses)])
        }

        var shareText: String {
            let formula = "(\(number(wins, units: 4)) + \(number(ties, units: 4)) ÷ 2) ÷ \(number(total, units: 4))"
            return "\(formula) ≈ \(roundedPercent(twicePotShare, outOf: 2 * total))%"
        }
    }

    private static func compareBoards(
        _ id: String, _ boardText: String, _ otherText: String, _ first: Lineup, _ second: Lineup, worked: Bool = false
    ) -> TableCourseActivity {
        let board = Card.parse(boardText)!
        let other = Card.parse(otherText)!
        let a = Showdown(first, second, on: board)
        let b = Showdown(first, second, on: other)
        let outcomes = [a.distribution(boardA), b.distribution(boardB)]
        let bestBoard = higher(a.twicePotShare * b.total, b.twicePotShare * a.total)
        let prompt = worked
            ? Copy("같은 두 레인지를 리버까지 나온 보드 두 개에서 맞붙여 봐요.", "Take the same two ranges to showdown on two completed boards.")
            : Copy("쇼다운에서 레인지 A의 평균 팟 몫이 더 큰 보드는 어느 쪽일까요?",
                   "On which board does Range A have the larger average share of the pot at showdown?")
        let setup = TableCourseRow(Copy("쇼다운 가정", "Showdown model"),
                                  Copy("겹치는 카드가 없는 콤보끼리 비교해요. 두 콤보의 가중치를 곱하고, 무승부는 팟을 반씩 나눠요.",
                                       "Pair hands with no shared cards.\nMultiply the two combo weights.\nCount half the pot for ties."))
        return activity(
            id, Copy("보드에 따른 레인지 어드밴티지", "Range advantage across boards"), prompt,
            board: board, rows: rangeRows(first, second) + [setup], comparisonBoard: other,
            resultRows: [TableCourseRow(Copy("보드 A에서 팟 몫", "Pot share on Board A"), same(a.shareText)),
                         TableCourseRow(Copy("보드 B에서 팟 몫", "Pot share on Board B"), same(b.shareText))],
            distributions: outcomes, questionDistributions: outcomes,
            answer: worked ? nil : ([boardA, boardB, equal], bestBoard),
            explanation: Copy("레인지 맞대결\n이기면 팟 전체,\n비기면 팟 절반.",
                              "Pot share comes from comparing the two ranges directly. Count each win as a whole pot and each tie as half.")
        )
    }

    private enum Size: CaseIterable {
        case check, halfPot, pot

        var label: Copy {
            switch self {
            case .check: Copy("체크", "Check")
            case .halfPot: Copy("팟의 절반 베팅", "Half-pot bet")
            case .pot: Copy("팟만큼 베팅", "Pot-sized bet")
            }
        }

        func weight(in profile: Profile) -> Int {
            switch self {
            case .check: profile[.air]
            case .halfPot: profile.singlePairs + profile[.draw]
            case .pot: profile[.strong]
            }
        }
    }

    private static let sizePolicy = Copy(
        "투 페어 이상은 팟만큼, 원 페어와 페어 없는 드로우는 팟의 절반만큼 베팅해요. 빗나간 패는 체크해요.",
        "Bet the pot with two pair or better. Bet half the pot with exactly one pair or an unpaired draw. Check the misses."
    )

    private static func sizingShare(
        _ id: String, _ boardText: String, _ range: Lineup, action: Size, decoys: [Int] = [], answerAt: Int = 0
    ) -> TableCourseActivity {
        let board = Card.parse(boardText)!
        let profile = Profile(range, on: board)
        let weight = action.weight(in: profile)
        let focusedAction = TableCourseRow(Copy("살펴볼 행동", "Action to count"), action.label)
        let rows = [TableCourseRow(rangeLabel, range.label), TableCourseRow(Copy("연습 규칙", "Practice rule"), sizePolicy),
                    focusedAction]
        let prompt = decoys.isEmpty
            ? Copy("정해진 규칙으로 각 콤보의 행동을 정하고, 행동별 비율을 구해 봐요.",
                   "Use the written rule to assign an action to each combo, then find how often each action occurs.")
            : Copy("이 규칙을 쓸 때, 표시된 행동을 하는 패는 레인지의 몇 퍼센트일까요? 정수로 반올림하세요.",
                   "Under this rule, what percentage of the range takes the action shown? Round to the nearest whole percent.")
        return activity(
            id, Copy("베팅 크기 규칙 적용", "Apply a bet-size rule"), prompt,
            board: board, rows: rows,
            resultRows: [TableCourseRow(Copy("이 행동 ÷ 전체", "This action ÷ total"), division(weight, profile.total))],
            distributions: [bands(Copy("행동별 비율", "Action shares"), Size.allCases.map { ($0.label, $0.weight(in: profile)) })],
            answer: percentAnswer(weight, outOf: profile.total, decoys: decoys, answerAt: answerAt),
            explanation: Copy("표시된 행동에 해당하는 패의 가중치를 더해 전체 가중치로 나누어요. 여기서 베팅 크기는 연습 규칙이 정해요.",
                              "Add the weights of the hands assigned to the action, then divide by the full range weight. The sizes come from the practice rule.")
        )
    }

    private static func readSmallBet(
        _ id: String, _ boardText: String, _ range: Lineup, worked: Bool = false
    ) -> TableCourseActivity {
        let board = Card.parse(boardText)!
        let profile = Profile(range, on: board)
        let pairs = profile.singlePairs
        let draws = profile[.draw]
        let policyA = Copy("규칙 A", "Rule A")
        let policyB = Copy("규칙 B", "Rule B")
        let rows = [
            TableCourseRow(rangeLabel, range.label),
            TableCourseRow(Copy("관찰한 행동", "Observed action"), Size.halfPot.label),
            TableCourseRow(policyA, sizePolicy),
            TableCourseRow(policyB, Copy("다른 패는 규칙 A대로 해요. 페어 없는 드로우는 콤보마다 25% 확률로 팟의 절반을 베팅하고 나머지는 체크해요.",
                                         "Keep Rule A for other hands. With each unpaired draw, bet half the pot 25% of the time and check the rest.")),
        ]
        // After this bet, the remaining mass is one-pair holdings and the fraction of draws
        // assigned to the bet. A quarter of a half-combo is one eighth of a combo.
        let aTotal = 4 * (pairs + draws)
        let bTotal = 4 * pairs + draws
        let index = draws > 4 * pairs ? 0 : draws > pairs ? 1 : 2
        let prompt = worked
            ? Copy("같은 크기로 베팅했어도, 상대가 따르는 규칙에 따라 베팅한 패가 달라질 수 있어요.",
                   "The same bet size can come from a different mix of hands when the opponent’s rule changes.")
            : Copy("이 베팅을 한 패 중 페어 없는 드로우가 절반을 넘는 경우는 어느 쪽일까요?",
                   "After this bet, under which rule do unpaired draws make up more than half the betting range?")
        return activity(
            id, Copy("같은 베팅, 다른 해석", "Same bet, different read"), prompt,
            board: board, rows: rows,
            resultRows: [
                TableCourseRow(Copy("베팅한 패 중 드로우", "Draw share after the bet"),
                               comparison(4 * draws, of: aTotal, draws, of: bTotal, units: 8, labels: (policyA, policyB))),
            ],
            distributions: [
                bands(policyA, [(Copy("원 페어", "One pair"), 4 * pairs), (drawLabel, 4 * draws)]),
                bands(policyB, [(Copy("원 페어", "One pair"), 4 * pairs), (drawLabel, draws)]),
            ],
            answer: worked ? nil : ([
                Copy("두 규칙 모두", "Under both rules"),
                Copy("규칙 A만", "Only under Rule A"),
                Copy("어느 규칙도 아니에요", "Under neither rule"),
            ], index),
            explanation: Copy("베팅한 패끼리만 비교해요. 규칙 B에서는 드로우 가중치의 4분의 1만 남아요. 실제 상대를 읽을 때는 어떤 규칙을 따르는지도 추측해야 해요.",
                              "Compare only the hands that take this size. Rule B gives those draws a quarter of their original weight. At a real table, the opponent’s rule is itself an assumption.")
        )
    }

    private static func rangeRows(_ first: Lineup, _ second: Lineup) -> [TableCourseRow] {
        [TableCourseRow(rangeA, first.label), TableCourseRow(rangeB, second.label)]
    }

    private static func bands(_ title: Copy, _ values: [(Copy, Int)]) -> TableCourseDistribution {
        let total = values.reduce(0) { $0 + $1.1 }
        precondition(total > 0, "Each course distribution needs eligible holdings.")
        return TableCourseDistribution(title, bands: values.map { label, weight in
            TableCourseDistributionBand(label, share: Double(weight) / Double(total))
        })
    }

    private static func percentAnswer(_ part: Int, outOf total: Int, decoys: [Int], answerAt: Int) -> Answer? {
        guard !decoys.isEmpty else { return nil }
        var options = decoys
        options.insert(roundedPercent(part, outOf: total), at: answerAt)
        precondition(Set(options).count == 3)
        return (options.map { same("\($0)%") }, answerAt)
    }

    private static func higher(_ a: Int, _ b: Int) -> Int {
        if a == b { return 2 }
        return a > b ? 0 : 1
    }

    private static func number(_ weight: Int, units: Int) -> String {
        weight.isMultiple(of: units) ? String(weight / units) : String(Double(weight) / Double(units))
    }

    private static func roundedPercent(_ part: Int, outOf total: Int) -> Int {
        Int((100 * Double(part) / Double(total)).rounded())
    }

    private static func division(_ part: Int, _ total: Int, units: Int = 2) -> Copy {
        same("\(number(part, units: units)) ÷ \(number(total, units: units)) ≈ \(roundedPercent(part, outOf: total))%")
    }

    private static func comparison(
        _ a: Int, of aTotal: Int, _ b: Int, of bTotal: Int, units: Int = 2,
        labels: (Copy, Copy) = (rangeA, rangeB)
    ) -> Copy {
        let first = division(a, aTotal, units: units).text(in: .english)
        let second = division(b, bTotal, units: units).text(in: .english)
        return Copy("\(labels.0.text(in: .korean)) \(first) · \(labels.1.text(in: .korean)) \(second)",
                    "\(labels.0.text(in: .english)) \(first) · \(labels.1.text(in: .english)) \(second)")
    }

    private static func same(_ text: String) -> Copy { Copy(text, text) }

    private static func activity(
        _ id: String, _ title: Copy, _ prompt: Copy, board: [Card], rows: [TableCourseRow],
        comparisonBoard: [Card] = [], resultRows: [TableCourseRow], distributions: [TableCourseDistribution],
        questionDistributions: [TableCourseDistribution] = [], answer: Answer?, explanation: Copy
    ) -> TableCourseActivity {
        let reveal = TableCourseEvidence(board: board, rows: rows + resultRows,
                                         comparisonBoard: comparisonBoard, distributions: distributions)
        let question = TableCourseEvidence(board: board, rows: rows, comparisonBoard: comparisonBoard,
                                           distributions: questionDistributions)
        return TableCourseActivity(id: id, title: title, prompt: prompt, evidence: answer == nil ? reveal : question,
                                   choices: answer?.choices ?? [], correctChoice: answer?.index,
                                   explanation: explanation, revealedEvidence: answer == nil ? nil : reveal)
    }
}
