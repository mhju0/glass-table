// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

enum JourneyCaseContent {
    typealias Copy = TableCourseText
    typealias Row = TableCourseRow

    struct Deal {
        let name: Copy
        let hero: [Card]
        let opponent: [Card]
        let board: [Card]
        let onButton: Bool
        let open: Int
        let flopBet: Int
        let shove: Int
        let task: EarlyTask

        init(_ korean: String, _ english: String, _ hero: String, _ opponent: String, _ board: String,
             button: Bool, open: Int, flop: Int, shove: Int, task: EarlyTask) {
            name = Copy(korean, english)
            self.hero = MasteryCourseContent.cards(hero)
            self.opponent = MasteryCourseContent.cards(opponent)
            self.board = MasteryCourseContent.cards(board)
            precondition(Set(self.hero + self.opponent + self.board).count == 9)
            onButton = button
            self.open = open
            flopBet = flop
            self.shove = shove
            self.task = task
        }

        var flop: [Card] { Array(board.prefix(3)) }
        var turn: [Card] { Array(board.prefix(4)) }
        var preflopPot: Int { 2 * open + 1 }
        var turnPot: Int { preflopPot + 2 * flopBet }
        var finalPot: Int { turnPot + 2 * shove }

        var streets: Copy {
            let action = flopBet == 0
                ? Copy("플랍은 둘 다 체크했어요.", "Both players checked the flop.")
                : Copy("플랍에서 빅 블라인드가 체크하고 버튼이 \(flopBet)을 벳해 콜을 받았어요.",
                       "On the flop the big blind checked, the button bet \(flopBet), and the big blind called.")
            return Copy("블라인드는 1/2예요. 첫 자리는 폴드, 버튼은 \(open)으로 오픈, 스몰 블라인드는 폴드, 빅 블라인드는 콜했어요. \(action.text(in: .korean))",
                        "Blinds are 1/2. The first seat folded, the button opened to \(open), the small blind folded, and the big blind called. \(action.text(in: .english))")
        }

        var potHistory: [Row] {
            [Row(Copy("프리플랍 뒤 팟", "Pot after preflop"), same("\(open) + \(open) + 1 = \(preflopPot)")),
             Row(Copy("플랍 뒤 팟", "Pot after the flop"), same("\(preflopPot) + \(flopBet) + \(flopBet) = \(turnPot)"))]
        }

        var turnOpening: Copy {
            if onButton {
                return Copy("상대가 턴에 \(shove) 올인했어요.", "Your opponent shoves \(shove) on the turn.")
            }
            return Copy("턴에 내가 체크하자 상대가 \(shove) 올인했어요.",
                        "You check the turn and your opponent shoves \(shove).")
        }

        var heroSeat: Row {
            Row(Copy("내 자리", "Your seat"),
                onButton ? Copy("버튼", "Button") : Copy("빅 블라인드", "Big blind"))
        }

        func evidence(_ boardCount: Int, showOpponent: Bool = false, rows: [Row] = []) -> TableCourseEvidence {
            .init(cards: hero, board: Array(board.prefix(boardCount)), opponent: showOpponent ? opponent : [],
                  rows: [heroSeat] + rows)
        }
    }

    enum EarlyTask { case position, match, legal }

    static func title(for lesson: TableCourseLesson, language: LearningLanguage) -> String {
        deals[lesson]?.name.text(in: language) ?? lesson.rawValue
    }

    static func activities(for lesson: TableCourseLesson) -> [TableCourseActivity] {
        catalog[lesson, default: []]
    }

    static func same(_ text: String) -> Copy { Copy(text, text) }

    private static let catalog = Dictionary(uniqueKeysWithValues: deals.map { lesson, deal in
            let code = lesson.id.uppercased()
            let questions = [early(code + "-01", deal), range(code + "-02", deal),
                             boardChange(code + "-03", deal), price(code + "-04", deal),
                             decision(code + "-05", deal), showdown(code + "-06", deal)]
            return (lesson, lesson == .s11 ? questions : [worked(code + "-example", deal)] + questions)
    })

    static let deals: [TableCourseLesson: Deal] = [
        .r1: .init("플러시 드로우와 오버페어", "Flush draw against an overpair", "AhJh", "KdKs", "Th5h2c7d9h", button: true, open: 5, flop: 3, shove: 8, task: .position),
        .r2: .init("낮은 카드가 이어지는 보드", "Low cards that connect", "8c7c", "AdAc", "9s6c2d4h5s", button: false, open: 6, flop: 4, shove: 12, task: .match),
        .r3: .init("턴에서 보드가 페어가 될 때", "When the board pairs on the turn", "QsTs", "JhJd", "Qc6s3s6d2h", button: true, open: 7, flop: 0, shove: 9, task: .legal),
        .r4: .init("리버의 키커 차이", "A kicker on the river", "KcJd", "Kh9c", "Ks8h4d2s6d", button: false, open: 5, flop: 5, shove: 15, task: .position),
        .r5: .init("세 번째 클럽이 나온 보드", "A third club changes the board", "Ac4c", "QdQh", "Tc7c3s9c2h", button: true, open: 6, flop: 2, shove: 10, task: .match),
        .r6: .init("오픈 금액의 기준", "The lower limit for an opening raise", "Td9d", "AsAh", "Jh8d4dKc3h", button: false, open: 8, flop: 3, shove: 9, task: .legal),
        .r7: .init("보드가 이기는 경우", "When the board plays", "3c3d", "9h9c", "TdJsQhKcAs", button: true, open: 5, flop: 0, shove: 5, task: .match),
        .r8: .init("플러시가 되어도 확인할 것", "What to check when the flush comes in", "Jd8d", "AsAc", "Ad7s3d7d4d", button: false, open: 7, flop: 3, shove: 10, task: .position),
        .r9: .init("리버 전에 앞선 패", "A made hand ahead on the turn", "QcQd", "KcJh", "QhTh4h5d7h", button: true, open: 8, flop: 4, shove: 13, task: .match),
        .r10: .init("공용 카드와 블로커", "Public cards and blockers", "As6s", "KdTd", "Ks9s2c3d5s", button: false, open: 9, flop: 0, shove: 11, task: .legal),
        .s1: .init("턴 올인의 싼 가격", "A cheap turn shove", "AcJc", "QhQs", "Tc8c7h3s2d", button: false, open: 6, flop: 5, shove: 5, task: .match),
        .s2: .init("플랍에서 커진 팟", "A pot that grows on the flop", "QdTh", "AdJh", "Qs9s6d8c2h", button: true, open: 7, flop: 6, shove: 21, task: .legal),
        .s3: .init("드로우 두 가지가 겹칠 때", "Two draws with overlapping outs", "9s8s", "KdKh", "Ts7s4d2c5c", button: false, open: 8, flop: 3, shove: 14, task: .position),
        .s4: .init("싱글 레이즈 팟의 큰 올인", "A large shove in a single-raised pot", "KdJd", "AsAc", "Kc8d2d3h9s", button: true, open: 5, flop: 0, shove: 20, task: .match),
        .s5: .init("무승부 몫까지 계산하기", "Include a split pot in equity", "2c2d", "7h7d", "AsKsQsJsTs", button: false, open: 7, flop: 4, shove: 8, task: .legal),
        .s6: .init("강한 패와 보드 변화", "A strong hand on a changing board", "ThTc", "AcQh", "Td8h3h6h3s", button: true, open: 9, flop: 7, shove: 15, task: .position),
        .s7: .init("콜에 더 낼 금액", "Chips still needed to call", "6c5c", "QdQs", "4h3cKd9c2h", button: false, open: 6, flop: 6, shove: 18, task: .match),
        .s8: .init("리버 한 장과 장기 손익", "One river and the long-run decision", "Js9s", "AhAd", "Jh7s4c2s6s", button: true, open: 8, flop: 2, shove: 17, task: .legal),
        .s9: .init("턴에서 페어가 난 보드", "A paired board on the turn", "AhKh", "JcJs", "Kc8h4s8sTd", button: false, open: 5, flop: 5, shove: 17, task: .position),
        .s10: .init("최종 팟을 만드는 세 금액", "Three amounts that make the final pot", "7d6d", "QcQh", "9d8s3d2s5h", button: true, open: 9, flop: 5, shove: 10, task: .match),
        .s11: .init("최종 평가 · 새 핸드", "Final assessment · a new hand", "Qh9h", "AcAd", "Jh8c4h2sTh", button: false, open: 7, flop: 5, shove: 19, task: .match),
    ]
}
