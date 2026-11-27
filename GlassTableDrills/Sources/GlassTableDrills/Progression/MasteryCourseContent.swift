// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

enum MasteryCourseContent {
    typealias Copy = TableCourseText
    typealias Row = TableCourseRow

    static func activities(for lesson: TableCourseLesson, revised: Bool) -> [TableCourseActivity] {
        switch lesson {
        case .d7:
            [
                shortRaise("D7-example", bet: 10, shove: 14, task: .acted, example: true, revised: revised),
                shortRaise("D7-01", bet: 12, shove: 19, task: .acted, revised: revised),
                shortRaise("D7-02", bet: 8, shove: 13, task: .newPlayer, revised: revised),
                shortRaise("D7-03", bet: 9, shove: 6, task: .shortCall, revised: revised),
                shortRaise("D7-04", bet: 11, shove: 22, task: .acted, revised: revised),
            ]
        case .d8:
            [
                pots("D8-example", [40, 70, 100], .layers, example: true),
                pots("D8-01", [16, 28, 40], .layers),
                pots("D8-02", [9, 25, 25], .payout),
                pots("D8-03", [13, 20, 20], .folded),
                pots("D8-04", [12, 19, 31], .payout),
            ]
        case .m1:
            [
                depth("M1-example", 96, 36, pot: 12, task: .spr, example: true),
                depth("M1-01", 24, 87, pot: 16, task: .effective),
                depth("M1-02", 104, 80, pot: 20, task: .spr),
                depth("M1-03", 10, 42, pot: 20, task: .future),
                depth("M1-04", 78, 60, pot: 30, task: .future),
            ]
        case .m2: revised ? Array(multiway.dropLast()) + [multiwayShowdown("M2-v2-04", "AhJd", "AdTc", "9h9s", "As9c7d3h2s")] : multiway
        case .m3: streets
        case .m4: formats
        case .m5: revised ? revisedConduct : conduct
        case .n1: turnHands
        case .n2: riverHands
        case .n3: revised ? revisedFullHand : fullHand
        default: []
        }
    }

    static func reviewActivities(for lesson: TableCourseLesson) -> [TableCourseActivity] {
        switch lesson {
        case .d7:
            [
                shortRaise("D7-review-01", bet: 16, shove: 27, task: .acted),
                shortRaise("D7-review-02", bet: 7, shove: 10, task: .newPlayer),
                shortRaise("D7-review-03", bet: 20, shove: 17, task: .shortCall),
            ]
        case .d8:
            [
                pots("D8-review-01", [18, 34, 49], .payout),
                pots("D8-review-02", [27, 45, 61], .layers),
                pots("D8-review-03", [15, 32, 32], .folded),
            ]
        case .m1:
            [
                depth("M1-review-01", 48, 106, pot: 14, task: .effective),
                depth("M1-review-02", 63, 36, pot: 18, task: .spr),
                depth("M1-review-03", 71, 15, pot: 24, task: .future),
            ]
        case .m2: multiwayReview
        case .m3: streetReview
        case .m4: formatReview
        case .m5: conductReview
        case .n1: turnReview
        case .n2: riverReview
        case .n3: fullHandReview
        default: []
        }
    }

    static func scenario(_ id: String, _ title: Copy, _ prompt: Copy, _ options: [Copy],
                         answer: Int, _ reason: Copy, evidence: TableCourseEvidence = .init(),
                         reveal: [Row] = [], example: Bool = false) -> TableCourseActivity {
        let resolved = TableCourseEvidence(seats: evidence.seats, cards: evidence.cards, board: evidence.board,
                                           opponent: evidence.opponent, rows: evidence.rows + reveal)
        return TableCourseActivity(id: id, title: title, prompt: prompt, evidence: example ? resolved : evidence,
                                   choices: example ? [] : options, correctChoice: example ? nil : answer,
                                   explanation: reason, revealedEvidence: reveal.isEmpty ? nil : resolved)
    }

    static func same(_ text: String) -> Copy { Copy(text, text) }

    static func cards(_ text: String) -> [Card] {
        guard let cards = Card.parse(text), Set(cards).count == cards.count else {
            preconditionFailure("Invalid course cards: \(text)")
        }
        return cards
    }

    enum RaiseTask { case acted, newPlayer, shortCall }

    static func shortRaise(_ id: String, bet: Int, shove: Int, task: RaiseTask,
                                   example: Bool = false, revised: Bool = false) -> TableCourseActivity {
        let title = Copy("올인 뒤에 어떤 행동을 할 수 있을까?", "What actions are open after the all-in?")
        let rows = [
            Row(Copy("A의 플랍 벳", "A’s opening flop bet"), same("\(bet)")),
            Row(Copy("B의 올인 총액", "B’s all-in total"), same("\(shove)")),
        ]
        let common = revised
            ? Copy("빅 블라인드가 2인 노리밋 홀덤 토너먼트예요. 플랍에서 앞선 벳 없이 A가 먼저 벳했고, B는 칩을 모두 냈어요.",
                   "This is a no-limit Hold’em tournament with a big blind of 2. A made the opening bet on the flop. B put in their entire stack.")
            : Copy("노리밋 홀덤 토너먼트 규칙을 적용해요. 이 스트리트에서 A가 먼저 벳했고, B는 가진 칩을 모두 냈어요.",
                          "Use no-limit Hold’em tournament rules. A opened the betting on this street and B put in their entire stack.")
        let call = Copy("콜 또는 폴드", "Call or fold")
        let raise = Copy("콜, 폴드 또는 레이즈", "Call, fold, or raise")
        switch task {
        case .acted:
            let short = shove - bet < bet
            let minimum = short ? shove : 2 * shove - bet
            let situation = revised
                ? Copy("\(common.text(in: .korean)) C는 B의 올인을 콜했어요. A와 C는 이번 플랍에서 각각 총 \(minimum) 이상을 낼 수 있어요. 다시 A 차례예요.",
                       "\(common.text(in: .english)) C called B’s all-in. A and C can each put in at least \(minimum) total on this flop. Action returns to A.")
                : Copy(
                "\(common.text(in: .korean)) C도 올인을 콜했고, A와 C에게는 칩이 충분해요. 다시 A 차례예요.",
                "\(common.text(in: .english)) C calls the all-in. A and C still have chips, and action returns to A.")
            return scenario(id, title, situation,
                [raise, call, Copy("체크 또는 콜", "Check or call")], answer: short ? 1 : 0,
                short
                    ? Copy("증가분 \(shove - bet)은 최소 레이즈 폭 \(bet)보다 작아요. 이미 벳한 A에게 레이즈가 다시 열리지 않아요. 차액을 콜하거나 폴드할 수 있어요.",
                           "The increase of \(shove - bet) is below the full raise of \(bet), so it does not reopen action for A. A can match the difference or fold.")
                    : Copy("증가분은 \(bet)이라 풀 레이즈예요. A에게 레이즈가 다시 열려요. C가 맞출 칩이 있어 사이드 팟을 두고 더 레이즈할 수 있어요.",
                           "The \(bet)-chip increase is a full raise. That reopens betting to A. C still has chips to match a raise for the side pot."),
                evidence: .init(rows: rows), reveal: [
                    Row(Copy("A가 더 내야 할 칩", "Extra for A to call"), same("\(shove - bet)")),
                ], example: example)
        case .newPlayer:
            let minimum = shove + bet
            let question = revised
                ? Copy("\(common.text(in: .korean)) C는 아직 행동하지 않았어요. C와 A는 플랍에서 각각 총 \(minimum + 9)까지 낼 수 있어요. C의 최소 레이즈 총액은?",
                       "\(common.text(in: .english)) C has yet to act. C and A can each put in up to \(minimum + 9) total on the flop. What is C’s minimum raise-to total?")
                : Copy("\(common.text(in: .korean)) C는 칩이 충분하고 아직 행동하지 않았어요. A에게도 칩이 남았어요. C의 최소 레이즈 총액은?",
                     "\(common.text(in: .english)) C has chips and has yet to act. A still has chips behind. What is C’s minimum raise-to total?")
            return scenario(id, Copy("아직 행동하지 않았다면?", "What if you have yet to act?"), question,
                [same("\(2 * bet)"), same("\(minimum)"), same("\(2 * shove)")], answer: 1,
                Copy("C는 아직 행동하지 않았으므로 레이즈할 수 있어요. B의 올인은 최소 레이즈 폭을 바꾸지 않아요. 현재 총액 \(shove)에 기존 벳 \(bet)만큼 더해요.",
                     "C has not acted, so raising is available. The short all-in leaves the full-raise increment unchanged. Add the opening bet of \(bet) to the current total of \(shove)."),
                evidence: .init(rows: rows))
        case .shortCall:
            return scenario(id, Copy("올인 콜과 레이즈 구분하기", "Recognize an all-in call"),
                Copy("\(common.text(in: .korean)) 지금 B의 행동은 무엇인가요?", "\(common.text(in: .english)) What action did B take?"),
                [Copy("올인 레이즈", "All-in raise"), Copy("올인 콜", "All-in call"), Copy("폴드", "Fold")],
                answer: 1, Copy("B는 벳을 다 맞출 수 없어서 가진 칩까지만 콜해요. 기존 베팅 총액을 넘기지 않았으므로 레이즈가 아니에요.",
                                "B cannot match the whole bet and calls for the chips they have. Their total did not exceed the existing bet, so this is a call."),
                evidence: .init(rows: rows))
        }
    }

    enum PotTask { case layers, payout, folded }

    static func pots(_ id: String, _ paid: [Int], _ task: PotTask,
                             example: Bool = false) -> TableCourseActivity {
        let a = paid[0], b = paid[1], c = paid[2]
        let main = 3 * a, side = 2 * (b - a), refund = c - b
        let seats = zip(["A", "B", "C"], paid).map { name, amount in
            TableCourseSeat(same(name), detail: Copy("낸 칩", "Contributed"), chips: amount,
                            folded: task == .folded && name == "B")
        }
        let reveal = [
            Row(Copy("메인 팟", "Main pot"), same("3 × \(a) = \(main)")),
            Row(Copy("사이드 팟", "Side pot"), same("2 × (\(b) − \(a)) = \(side)")),
            Row(Copy("C에게 돌려주는 칩", "Returned to C"), same("\(c) − \(b) = \(refund)")),
        ]
        switch task {
        case .layers:
            return scenario(id, Copy("팟과 돌려줄 칩 나누기", "Separate pots from the refund"),
                Copy("A와 B는 올인이고 C는 더 많이 냈어요. 베팅은 끝났어요. 메인 팟, 사이드 팟, C에게 돌아갈 칩은 순서대로 얼마인가요?",
                     "A and B are all-in and C put in more. Betting is over. What are the main pot, side pot, and return to C, in that order?"),
                [same("\(main) · \(side) · \(refund)"), same("\(main) · \(side + refund) · 0"),
                 same("\(main + side) · 0 · \(refund)")], answer: 0,
                Copy("세 사람이 \(a)씩 메인 팟에 넣어요. B와 C가 그 위로 \(b - a)씩 사이드 팟에 넣어요. 아무도 맞추지 않은 \(refund)은 C에게 돌려줘요.",
                     "All three contribute \(a) to the main pot. B and C each contribute \(b - a) above that to the side pot. The unmatched \(refund) goes back to C."),
                evidence: .init(seats: seats), reveal: reveal, example: example)
        case .payout:
            return scenario(id, Copy("누가 어느 팟을 받을까?", "Who wins each pot?"),
                Copy("A와 B는 올인이고 베팅은 끝났어요. 쇼다운에서 A의 패가 가장 강하고, B가 C를 이겨요. 누가 각 팟을 가져가나요?",
                     "A and B are all-in and betting is over. A shows the strongest hand and B beats C. Who wins each pot?"),
                [Copy("A가 두 팟", "A wins both"), Copy("A가 메인 팟, C가 사이드 팟", "A wins main, C wins side"),
                 Copy("A가 메인 팟, B가 사이드 팟", "A wins main, B wins side")], answer: 2,
                Copy("A는 메인 팟에만 칩을 냈고 세 사람 중 가장 강해요. 사이드 팟은 B와 C만 다투고 그중 B가 이겨요.",
                     "A contributed only to the main pot and beats both players. The side pot is contested by B and C, and B has the better hand."),
                evidence: .init(seats: seats), reveal: reveal)
        case .folded:
            return scenario(id, Copy("폴드한 자리가 낸 칩", "Chips from a folded seat"),
                Copy("A가 올인한 뒤 B와 C는 더 냈어요. C가 다음 스트리트에서 벳하자 B가 폴드했고, C의 새 벳은 돌려줬어요. 표는 최종 납입액이에요. 쇼다운에서 A가 C를 이겨요. C는 사이드 팟을 얼마나 받나요?",
                     "A went all-in, then B and C contributed more. On the next street C bet, B folded, and C’s new bet was returned. The table shows final contributions. A beats C at showdown. How much does C get from the side pot?"),
                [same("\(b - a)"), same("\(side)"), same("0")], answer: 1,
                Copy("폴드한 B는 팟을 받을 수 없지만 낸 칩은 남아요. 메인 팟은 A가 이기고, 사이드 팟은 남은 자격이 있는 C가 받아요.",
                     "B’s chips stay in the pots after folding, but B is ineligible. A wins the main pot and C is the only eligible player for the side pot."),
                evidence: .init(seats: seats), reveal: reveal)
        }
    }

    enum DepthTask { case effective, spr, future }

    static func depth(_ id: String, _ hero: Int, _ opponent: Int, pot: Int, task: DepthTask,
                              example: Bool = false) -> TableCourseActivity {
        let effective = min(hero, opponent)
        let rows = [
            Row(Copy("내 남은 칩", "Your remaining stack"), same("\(hero)")),
            Row(Copy("상대의 남은 칩", "Opponent’s remaining stack"), same("\(opponent)")),
            Row(Copy("플랍 시작 팟", "Pot at the start of the flop"), same("\(pot)")),
        ]
        switch task {
        case .effective:
            return scenario(id, Copy("서로 걸 수 있는 칩", "How much can you play for?"),
                Copy("플랍에 둘만 남았어요. 지금부터 상대와 맞붙을 수 있는 최대 칩은 몇 개인가요?",
                     "Only two players reach the flop. What is the maximum either can put in and have the other match from here?"),
                [same("\(max(hero, opponent))"), same("\(hero + opponent)"), same("\(effective)")], answer: 2,
                Copy("남은 두 스택 중 작은 쪽을 유효 스택으로 봐요. 더 큰 스택의 초과분에는 상대가 맞출 칩이 없어요.",
                     "The smaller remaining stack is the effective stack. The shorter player cannot match chips beyond that amount."),
                evidence: .init(rows: rows))
        case .spr:
            return scenario(id, Copy("팟에 비해 얼마나 깊을까?", "How deep are the stacks relative to the pot?"),
                Copy("플랍에 둘만 남았어요. 플랍 시작의 유효 스택을 팟으로 나눈 값(SPR)은 얼마인가요?",
                     "Two players reach the flop. What is the stack-to-pot ratio (SPR), measured as effective stack divided by the starting flop pot?"),
                [same("\(effective / pot)"), same("\(max(hero, opponent)) ÷ \(pot)"), same("\(effective)")], answer: 0,
                Copy("둘 중 작은 스택 \(effective)을 팟 \(pot)으로 나누면 SPR은 \(effective / pot)이에요. 이 비율로 이후에 걸 수 있는 칩의 여유를 알아봐요.",
                     "Divide the smaller remaining stack, \(effective), by the pot, \(pot), to get an SPR of \(effective / pot). The ratio describes room for future betting."),
                evidence: .init(rows: rows), example: example)
        case .future:
            return scenario(id, Copy("다음 스트리트에도 벳할 칩이 있을까?", "Will chips remain for later streets?"),
                Copy("플랍에 둘만 남았어요. 한 사람이 팟 크기만큼 벳하거나 칩이 모자라 올인하고 다른 사람이 가진 칩 범위에서 콜한다면, 턴에 추가로 서로 걸 수 있는 칩은 얼마인가요?",
                     "Only two remain. One bets the current pot, or goes all-in for less if short, and the other calls within their stack. How much can they still bet and match on the turn?"),
                [same("\(effective)"), same("\(max(0, effective - pot))"), same("\(max(hero, opponent))")], answer: 1,
                Copy("두 사람은 각각 최대 \(min(effective, pot))을 이 베팅으로 낼 수 있어요. 현재 유효 스택에서 그만큼 빼면 이후 서로 걸 수 있는 칩이 나와요.",
                     "Each can contribute up to \(min(effective, pot)) to this bet. Subtract that from the effective stack to find what they can match later."),
                evidence: .init(rows: rows))
        }
    }
}

extension MasteryCourseContent {
    // These fixtures are reserved for the one-time spaced scope. Existing on-demand
    // snapshots continue resolving through the original bank and its variant order.
    static let spacedQuestions: [CourseReviewSkill: TableCourseActivity] = [
        .d7: shortRaise("D7-spaced-01", bet: 15, shove: 30, task: .acted, revised: true),
        .d8: pots("D8-spaced-01", [26, 39, 39], .folded),
        .m1: depth("M1-spaced-01", 78, 54, pot: 18, task: .spr),
        .m2: multiwayShowdown("M2-spaced-01", "KhJh", "Ks8c", "AcAd", "Kd8d6c3s2h"),
        .m3: scenario("M3-spaced-01", Copy("턴에서 상대 레인지 다시 읽기", "Reconsider the range on the turn"),
                      Copy("상대가 플랍에서 오버페어나 플러시 드로우로만 콜한다는 연습 규칙을 써요. 네 번째 공용 카드로 6♦가 나왔어요. 플랍 콜 범위가 어떻게 달라졌을까요?",
                           "In this exercise the opponent calls the flop only with an overpair or a flush draw. The fourth board card is 6♦. What changed for that calling range?"),
                      [Copy("모든 오버페어가 플러시가 됐어요", "Every overpair has become a flush"),
                       Copy("다이아몬드 드로우는 플러시가 됐고 오버페어도 가능해요", "Diamond draws made a flush, and overpairs remain possible"),
                       Copy("플러시 드로우는 여전히 미완성이에요", "The flush draws all remain unmade")],
                      answer: 1, Copy("공용 카드에 다이아몬드가 세 장이에요. 다이아몬드 두 장으로 콜했던 패는 플러시가 됐어요. 오버페어를 든 상대도 규칙에 맞아요.",
                                      "Three diamonds are now on the board. Two diamonds in the opponent’s hand make a flush. Their policy still allows an overpair."),
                      evidence: .init(cards: cards("Ts9c"), board: cards("Td7d3s6d"))),
        .m4: blindDepth("M4-spaced-01", stack: 5_200, oldBlind: 200, newBlind: 400),
        .m5: scenario("M5-spaced-01", Copy("칩 더미가 겹쳐 보일 때", "When the chips overlap"),
                      Copy("토너먼트 플랍에서 상대가 말없이 칩을 밀었어요. 내 차례인데 큰 칩이 작은 칩에 가려져 액수가 안 보여요. 먼저 무엇을 할까요?",
                           "On the tournament flop an opponent puts out chips silently. It is your turn and you cannot see the amount because the larger chip is obscured. What do you do first?"),
                      [Copy("딜러에게 내가 맞춰야 할 금액을 물어요", "Ask the dealer what amount you face"),
                       Copy("짐작해서 일부만 내요", "Guess and put in part of the amount"),
                       Copy("옆 사람에게 콜할지 물어요", "Ask a neighbor whether to call")],
                      answer: 0, Copy("딜러에게 베팅 금액을 확인한 다음 내 행동을 결정해요.",
                                      "Ask the dealer to clarify the bet before deciding how to act.")),
        .n1: turn("N1-spaced-01", "8h7h", "KdKc", "6h5s2hJs", pot: 27, call: 9, .price),
        .n2: showdown("N2-spaced-01", "Ah4h", "9d9s", "As9h6h2cKh"),
        .n3: transferHand("N3-spaced-01", "AsTs", "QcQd", "Ks7s4h2c", open: 7, call: 6),
    ]
}
