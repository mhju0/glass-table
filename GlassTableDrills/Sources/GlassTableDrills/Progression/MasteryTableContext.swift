// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

extension MasteryCourseContent {
    static let multiway = [
        allFold("M2-example", pot: 24, bet: 12, foldBoth: 25, example: true),
        allFold("M2-01", pot: 36, bet: 12, foldBoth: 30),
        allFold("M2-02", pot: 18, bet: 18, foldBoth: 40),
        scenario("M2-03", Copy("내 뒤에 남은 사람", "Someone still acts behind you"),
                 Copy("리버에 세 명이 남았어요. A가 12를 벳했고 내 차례예요. 뒤에 있는 C는 아직 행동하지 않았고 레이즈할 칩이 있어요. 콜하기 전에 무엇을 고려해야 할까요?",
                      "Three players remain on the river. A bets 12 and it’s your turn. C has yet to act behind you and has chips to raise. What should you consider before calling?"),
                 [Copy("콜하면 바로 쇼다운이에요", "Calling ends the betting"),
                  Copy("C의 추가 콜이나 레이즈가 가능해요", "C can still call or raise"),
                  Copy("C가 내 결정을 기다리지 않아요", "C acts before I decide")], answer: 1,
                 Copy("아직 C의 차례가 남아 있어요. C의 콜이나 레이즈가 최종 팟과 상대 범위를 바꿀 수 있어요.",
                      "C still has a turn. A call or raise from C can change the final pot and the range you face.")),
        scenario("M2-04", Copy("상대 한 명을 더 넣으면", "Adding another opponent"),
                 Copy("같은 리버에서 내 패가 A는 이기지만 B에게는 져요. 한 팟을 두고 세 사람이 쇼다운하면 누구에게 팟이 갈까요?",
                      "On the same river you beat A but lose to B. All three are eligible for one pot. Who wins at showdown?"),
                 [Copy("나", "You"), Copy("A", "A"), Copy("B", "B")], answer: 2,
                 Copy("같은 팟을 받을 자격이 있는 모든 패 중 가장 강한 패가 이겨요. A를 이겨도 B에게 지면 팟을 받을 수 없어요.",
                      "The strongest hand among all eligible players wins. Beating A is insufficient when B has you beat."),
                 evidence: .init(cards: cards("AhJd"), board: cards("As9c7d3h2s"),
                                 rows: [Row(same("A"), same("A♦ T♣")), Row(same("B"), same("9♥ 9♠"))])),
    ]

    static let multiwayReview = [
        allFold("M2-review-01", pot: 45, bet: 15, foldBoth: 20),
        allFold("M2-review-02", pot: 32, bet: 8, foldBoth: 25),
        scenario("M2-review-03", Copy("누가 내 뒤에서 행동할까?", "Who acts after you?"),
                 Copy("플랍에서 스몰 블라인드가 벳했어요. 빅 블라인드인 내 차례이고 버튼도 아직 남아 있어요. 내가 콜하면 다음 차례는?",
                      "On the flop the small blind bets. You’re the big blind and the button remains. If you call, who acts next?"),
                 [Copy("버튼", "Button"), Copy("스몰 블라인드", "Small blind"), Copy("턴 카드가 나와요", "The turn is dealt")],
                 answer: 0, Copy("버튼은 이 베팅에 아직 답하지 않았어요. 버튼의 행동에 따라 베팅이 더 이어질 수 있어요.",
                                 "The button has yet to respond to the bet. What they do may extend the betting.")),
    ]

    private static func allFold(_ id: String, pot: Int, bet: Int, foldBoth: Int,
                                example: Bool = false) -> TableCourseActivity {
        let net = foldBoth * pot - (100 - foldBoth) * bet
        let options = [
            Copy("벳이 더 높아요", "Betting is higher"), Copy("같아요", "They are equal"),
            Copy("벳이 더 낮아요", "Betting is lower"),
        ]
        let answer = net > 0 ? 0 : net == 0 ? 1 : 2
        return scenario(id, Copy("둘 다 폴드해야 이기는 벳", "A bet that needs both players to fold"),
            Copy("리버에 상대가 둘이에요. 체크하면 바로 쇼다운하고 항상 지고, 벳에 한 명이라도 콜하면 져요. 콜이나 폴드만 가능하고 수수료는 없어요. 표시된 두 사람 모두의 폴드 빈도에서 벳의 EV는 체크와 비교해 어떤가요?",
                 "Two opponents remain on the river. If you check, everyone checks behind and you always lose at showdown. If anyone calls your bet, you lose. Opponents can only call or fold, with no fees. Given the chance both fold, how does betting compare with checking in EV?"),
            options, answer: answer,
            Copy("둘 다 폴드하면 \(pot)을 얻어요. 한 명이라도 콜하는 나머지 \(100 - foldBoth)%에는 \(bet)을 잃어요. 체크의 순손익은 지금부터 0이에요.",
                 "You gain \(pot) when both fold. You lose \(bet) in the other \(100 - foldBoth)% when at least one calls. Checking nets zero from here."),
            evidence: .init(rows: [
                Row(Copy("벳 전 팟", "Pot before betting"), same("\(pot)")),
                Row(Copy("벳 크기", "Bet size"), same("\(bet)")),
                Row(Copy("둘 다 폴드할 확률", "Chance both fold"), same("\(foldBoth)%")),
            ]), reveal: [
                Row(Copy("100번의 평균", "Average over 100 trials"),
                    same("[\(foldBoth) × \(pot) − \(100 - foldBoth) × \(bet)] ÷ 100")),
                Row(Copy("체크와 비교한 벳의 EV", "Bet EV compared with check"), options[answer]),
            ], example: example)
    }

    static let streets = [
        scenario("M3-example", Copy("플랍에 쓴 계획을 턴에서 고치기", "Revise the flop plan on the turn"),
                 Copy("버튼에서 레이즈하고 빅 블라인드만 콜했어요. 상대는 플랍에 체크·콜했고 턴에 다시 체크해요. 연습 모델에서 상대는 플랍에 페어 또는 플러시 드로우로 콜해요. 턴의 세 번째 하트로 무엇이 달라졌나요?",
                      "You raised the button and only the big blind called. They check-called the flop and check the turn. In this model they called the flop with a pair or flush draw. What changes with the third heart?"),
                 [Copy("플러시 드로우 일부가 완성됐어요", "Some flush draws are now made")], answer: 0,
                 Copy("플랍에서 콜한 두 하트가 턴에 플러시가 됐어요. 페어도 여전히 가능하니 상대 패를 하나로 단정할 수 없어요.",
                      "Two hearts that called the flop have completed a flush. Pairs are still possible, so the turn does not identify a single hand."),
                 evidence: .init(cards: cards("AdQc"), board: cards("Ah9h4s6h")), example: true),
        riverPlan("M3-01", "QdJs", "Qh8c4d2s6c", weaker: 5, stronger: 2),
        riverPlan("M3-02", "Td9d", "Ts8d4c3hKh", weaker: 2, stronger: 4),
        scenario("M3-03", Copy("체크는 무엇을 알려 줄까?", "What does a check tell you?"),
                 Copy("내가 버튼이에요. 빅 블라인드는 플랍에 약한 패도 강한 패도 체크할 수 있다는 연습 규칙을 써요. 상대가 체크했어요. 무엇을 알 수 있나요?",
                      "You are on the button. Our model lets the big blind check weak and strong hands on this flop. They check. What can you conclude?"),
                 [Copy("강한 패는 없어요", "They have no strong hands"),
                  Copy("리버까지 공짜예요", "The rest of the hand is free"),
                  Copy("두 종류 모두 여전히 가능해요", "Both types are still possible")], answer: 2,
                 Copy("체크는 이 스트리트에서 먼저 벳하지 않았다는 행동이에요. 이 규칙에서는 패의 강약을 확정할 수 없어요.",
                      "The check tells you they did not open betting on this street. Their rule leaves both hand strengths possible."),
                 evidence: .init(cards: cards("KsJc"), board: cards("Kd7h3s"))),
        scenario("M3-04", Copy("턴에서 확인할 새 사실", "New evidence on the turn"),
                 Copy("상대는 플랍에 체크·콜했어요. 이제 턴에 먼저 벳해요. 상대가 플랍에서 콜할 때 쓴 연습 모델에는 플러시 드로우와 페어가 모두 있었어요. 어떤 설명이 보이는 카드와 맞나요?",
                      "Your opponent check-called the flop and leads on the turn. The flop-calling model included flush draws and pairs. Which explanation fits the visible cards?"),
                 [Copy("상대는 반드시 플러시예요", "They must have a flush"),
                  Copy("하트 두 장을 든 상대는 플러시를 완성해요", "An opponent with two hearts may now have a flush"),
                  Copy("턴에는 플러시가 불가능해요", "A flush is impossible on this turn")], answer: 1,
                 Copy("보드에 하트가 세 장이에요. 상대가 하트 두 장을 들었다면 플러시가 완성돼요. 벳만으로 정확한 패는 알 수 없어요.",
                      "There are three hearts on the board. Two hearts in their hand would complete a flush. The bet alone does not identify their hand."),
                 evidence: .init(cards: cards("KdJc"), board: cards("Kh8h2d4h"))),
    ]

    static let streetReview = [
        riverPlan("M3-review-01", "AcTs", "Ah7d5s2c8h", weaker: 4, stronger: 1),
        riverPlan("M3-review-02", "JhTh", "Js9c3d4dQh", weaker: 1, stronger: 3),
        riverPlan("M3-review-03", "KcTd", "Ks7c2s9h5h", weaker: 3, stronger: 3),
    ]

    static func riverPlan(_ id: String, _ hero: String, _ board: String, weaker: Int,
                                  stronger: Int) -> TableCourseActivity {
        let bet = 12
        return scenario(id, Copy("리버에서 벳할까요, 체크할까요?", "Bet or check on the river?"),
            Copy("둘만 남고 상대가 체크했어요. 수수료나 레이즈는 없어요. 연습 모델에서 아래 콜 범위의 각 콤보는 같은 확률이에요. 이 범위 밖의 패는 모두 폴드하며, 체크해도 내가 이겨요. 두 선택의 EV를 비교해 보세요.",
                 "Your only opponent checked. There are no fees or raises. In this model the calling combos below are equally likely. All other hands fold and you would beat them at showdown if you checked. Compare the two actions in EV."),
            [Copy("체크의 EV가 높아요", "Checking has higher EV"), Copy("벳의 EV가 높아요", "Betting has higher EV"),
             Copy("두 EV가 같아요", "The EVs are equal")],
            answer: weaker == stronger ? 2 : weaker > stronger ? 1 : 0,
            Copy("약한 패의 콜은 체크보다 \(bet)을 더 벌고, 강한 패의 콜은 \(bet)을 잃어요. 폴드하는 패는 체크해도 이기므로 차이가 없어요.",
                 "A call from a worse hand adds \(bet) compared with checking. A call from a better hand loses \(bet). Folding hands make no difference because you beat them either way."),
            evidence: .init(cards: cards(hero), board: cards(board), rows: [
                Row(Copy("내 벳", "Your bet"), same("\(bet)")),
                Row(Copy("콜하는 약한 콤보", "Worse combos that call"), same("\(weaker)")),
                Row(Copy("콜하는 강한 콤보", "Better combos that call"), same("\(stronger)")),
            ]))
    }
}

extension MasteryCourseContent {
    static let formats = [
        blindDepth("M4-example", stack: 4_000, oldBlind: 100, newBlind: 200, example: true),
        blindDepth("M4-01", stack: 3_600, oldBlind: 120, newBlind: 240),
        blindDepth("M4-02", stack: 5_400, oldBlind: 150, newBlind: 300),
        formatDecision("M4-03", bubble: true),
        formatDecision("M4-04", bubble: false),
    ]

    static let formatReview = [
        blindDepth("M4-review-01", stack: 7_200, oldBlind: 200, newBlind: 400),
        formatDecision("M4-review-02", bubble: true, alternate: true),
        formatDecision("M4-review-03", bubble: false, alternate: true),
    ]

    static func blindDepth(_ id: String, stack: Int, oldBlind: Int, newBlind: Int,
                                   example: Bool = false) -> TableCourseActivity {
        let before = stack / oldBlind, after = stack / newBlind
        return scenario(id, Copy("블라인드가 오르면?", "When the blinds go up"),
            Copy("토너먼트의 다음 레벨이 시작됐어요. 그사이 핸드를 하지 않아 내 칩은 그대로예요. 이제 내 스택은 빅 블라인드 몇 개만큼인가요?",
                 "The next tournament level starts. You played no hands between levels, so your chip stack stayed the same. How many big blinds do you have now?"),
            [same("\(before) bb"), same("\(before + after) bb"), same("\(after) bb")], answer: 2,
            Copy("칩의 개수는 그대로지만 빅 블라인드는 커졌어요. 내 칩 \(stack)을 새 빅 블라인드 \(newBlind)로 나누면 \(after)bb예요. 정해진 블라인드로 하는 캐시 게임과 다른 점이에요.",
                 "Your chips stayed the same while the big blind grew. Divide \(stack) by the new big blind of \(newBlind) for \(after) bb. That differs from a cash table with fixed blinds."),
            evidence: .init(rows: [
                Row(Copy("내 칩", "Your chips"), same("\(stack)")),
                Row(Copy("이전 빅 블라인드", "Old big blind"), same("\(oldBlind)")),
                Row(Copy("새 빅 블라인드", "New big blind"), same("\(newBlind)")),
            ]), example: example)
    }

    private static func formatDecision(_ id: String, bubble: Bool, alternate: Bool = false) -> TableCourseActivity {
        if bubble {
            let prompt = alternate
                ? Copy("재참가 없는 토너먼트에서 6명이 남고 5위까지 상금을 받아요. 내가 콜해서 지면 탈락해요. 칩만 셀 때의 EV가 양수예요. 상금 기준으로 판단하려면 무엇을 더 봐야 할까요?",
                       "Six players remain in a freezeout paying five places. If you call and lose, you’re eliminated. Calling has positive chip EV. What else should you account for when comparing prize EV?")
                : Copy("재참가 없는 토너먼트예요. 4명이 남았고 3위까지 상금을 받아요. 올인에 콜해서 지면 탈락해요. 콜은 칩 EV가 약간 높아요. 상금 기준으로 판단하려면 무엇을 더 봐야 할까요?",
                       "Four players remain in a freezeout paying three places. You will be eliminated if you call the shove and lose. Calling gains a little chip EV. What else matters for prize EV?")
            return scenario(id, Copy("칩과 상금은 다르게 움직여요", "Chips and prizes change differently"), prompt,
                [Copy("상금 구조와 나머지 스택", "Payouts and the remaining stacks"),
                 Copy("칩 EV만으로 충분해요", "Chip EV is enough"),
                 Copy("상대 카드 무늬만 봐요", "Only the opponent’s suits")], answer: 0,
                Copy("칩 EV와 상금 EV는 달라요. 상금 구조, 상대 스택, 탈락 가능성을 함께 봐야 해요. 이 정보만으로 특정 콜이나 폴드를 단정할 수 없어요.",
                     "Chip EV can differ from prize EV. Consider payouts, other stacks, and the chance of elimination. The information given cannot establish a call or fold."))
        }
        let prompt = alternate
            ? Copy("정해진 블라인드의 일반 캐시 테이블에서 한 핸드가 끝났어요. 남은 칩은 무엇을 뜻하나요?",
                   "A hand ends at a standard cash table with fixed blinds. What do your remaining chips represent?")
            : Copy("일반 캐시 게임을 마치고 테이블을 떠나요. 토너먼트 칩과 달리 남은 캐시 게임 칩은 어떻게 처리되나요?",
                   "You finish a standard cash session and leave the table. What happens to the remaining cash-game chips?")
        return scenario(id, Copy("캐시 게임의 칩", "Cash-game chips"), prompt,
            [Copy("등수를 정하는 점수예요", "They determine a finishing place"),
             Copy("표시 가치에 따라 정산해요", "They are redeemed at face value"),
             Copy("블라인드가 오를 때마다 칩 가치가 바뀌어요", "Their face value changes as blinds rise")],
            answer: 1, Copy("일반 캐시 게임의 칩은 표시 가치에 따라 정산해요. 토너먼트는 정해진 상금 구조를 쓰고, 이 앱의 연습 칩은 금전 가치가 없어요.",
                            "Standard cash chips are redeemed at face value. Tournaments use a payout structure. This app’s practice chips have no monetary value."))
    }

    static let conduct = [
        etiquette("M5-example", .discuss, example: true),
        etiquette("M5-01", .turn),
        etiquette("M5-02", .declare),
        etiquette("M5-03", .discuss),
        etiquette("M5-04", .unclear),
    ]

    static let conductReview = [
        etiquette("M5-review-01", .turn, alternate: true),
        etiquette("M5-review-02", .declare, alternate: true),
        etiquette("M5-review-03", .discuss, alternate: true),
    ]

    enum ConductTask { case turn, declare, discuss, unclear }

    static func etiquette(_ id: String, _ task: ConductTask, example: Bool = false,
                                  alternate: Bool = false) -> TableCourseActivity {
        let title = Copy("딜러와 다른 플레이어에게 명확하게", "Make your actions clear at the table")
        switch task {
        case .turn:
            let prompt = alternate ? Copy("턴에서 내 오른쪽의 플레이어가 아직 결정 중이에요. 내 패를 접고 싶어요. 언제 폴드할까요?",
                                          "On the turn, the player to your right is still thinking. You intend to fold. When should you fold?")
                : Copy("리버에서 내 앞 사람의 차례예요. 나는 콜하고 싶어요. 어떻게 행동할까요?",
                       "On the river the player before you is still acting. You intend to call. What should you do?")
            return scenario(id, title, prompt,
                [Copy("지금 결정부터 말해요", "Announce your decision now"), Copy("내 차례를 기다려요", "Wait until it is your turn"),
                 Copy("앞 사람에게 결정을 재촉해요", "Push the other player to decide")], answer: 1,
                 Copy("차례가 오기 전에 내 행동을 공개하면 앞 사람의 판단에 영향을 줄 수 있어요.",
                      "Revealing your action out of turn can influence someone who has yet to decide."))
        case .declare:
            let prompt = alternate ? Copy("내 차례예요. 80을 마주했고 220으로 레이즈하려 해요. 룸은 한 번에 내거나 말로 금액을 밝히는 토너먼트 규칙을 써요. 어떻게 전달할까요?",
                                          "It is your turn. You face 80 and intend to raise to 220. The room uses tournament rules that require one motion or a verbal amount. How do you make it clear?")
                : Copy("내 차례예요. 20을 마주했고 60으로 레이즈하려 해요. 룸은 한 번에 내거나 말로 금액을 밝히는 토너먼트 규칙을 써요. 어떻게 행동할까요?",
                       "It is your turn. You face 20 and intend to raise to 60. The room uses tournament rules that require one motion or a verbal amount. What should you do?")
            let total = alternate ? 220 : 60
            return scenario(id, title, prompt,
                [Copy("콜만 낸 뒤 아무 말 없이 칩을 더 내요", "Put in a call and silently reach back"),
                 Copy("“콜”이라고 말하고 레이즈 칩을 밀어요", "Say “call” and push raising chips"),
                 Copy("“\(total)으로 레이즈”라고 먼저 말해요", "First say “raise to \(total)”")], answer: 2,
                 Copy("차례에 레이즈할 총액을 먼저 말하면 의도가 분명해요. 차례에 말한 ‘콜’은 그대로 적용될 수 있어요.",
                      "State the raise-to total on your turn to make the action clear. An in-turn declaration of “call” can bind you to a call."))
        case .discuss:
            let prompt = alternate ? Copy("나는 폴드했지만 둘이 아직 턴을 하고 있어요. 내가 접은 카드가 상대의 아웃을 줄여요. 말해도 될까요?",
                                          "You folded, and two players are still playing the turn. One of your discarded cards affects their outs. Should you tell them?")
                : Copy("나는 폴드했고 다른 두 사람이 리버를 하고 있어요. 옆에서 어느 패가 이길지 물어요. 어떻게 답할까요?",
                       "You folded and two other players are still playing the river. Someone asks which hand you think is winning. How should you respond?")
            return scenario(id, title, prompt,
                [Copy("핸드가 끝날 때까지 기다려요", "Wait until the hand ends"),
                 Copy("아무도 안 들리게 조언해요", "Give quiet advice"),
                 Copy("내 패만 공개해요", "Reveal only your own cards")], answer: 0,
                 Copy("진행 중인 핸드에 카드 정보나 조언을 주지 않아요. 토너먼트의 ‘한 핸드에 한 사람’ 원칙은 폴드한 사람에게도 적용돼요.",
                      "Keep hand information and advice to yourself during live play. The tournament one-player-to-a-hand rule includes players who have folded."), example: example)
        case .unclear:
            return scenario(id, title,
                Copy("내 차례인데 상대가 칩을 얼마나 냈는지 분명하지 않아요. 어떻게 할까요?",
                     "It is your turn and you are unsure how much the other player bet. What should you do?"),
                [Copy("딜러에게 현재 베팅 금액을 확인해요", "Ask the dealer to clarify the current bet"),
                 Copy("다른 사람의 판단을 듣고 따라 해요", "Ask someone what you should do"),
                 Copy("칩을 섞어 넣고 나중에 확인해요", "Put chips in and ask after")], answer: 0,
                 Copy("행동하기 전에 딜러에게 금액을 확인해요. 테이블의 상황은 확인할 수 있고, 어떤 결정을 할지는 내가 판단해요.",
                      "Clarify the amount with the dealer before acting. You can ask about the table state and make the decision yourself."))
        }
    }
}

extension MasteryCourseContent {
    static let revisedConduct = Array(conduct.prefix(3)) + [
        scenario("M5-v2-03", Copy("옆자리의 조언", "Advice from the next seat"),
                 Copy("토너먼트 리버에서 내 차례예요. 이미 폴드한 옆 사람이 ‘상대는 블러프야’라고 말하려 해요. 어떻게 할까요?",
                      "It’s your turn on the river in a tournament. A player who already folded is about to advise you that the bettor is bluffing. What should you do?"),
                 [Copy("작게 말해 달라고 해요", "Ask them to whisper their advice"),
                  Copy("말을 멈춰 달라고 하고 내가 판단해요", "Ask them to stop and decide on your own"),
                  Copy("그 사람이 대신 결정하게 해요", "Let them make the decision")], answer: 1,
                 Copy("폴드한 사람도 진행 중인 핸드에 조언할 수 없어요. 딜러에게 베팅 금액은 확인할 수 있고 결정은 내가 해요.",
                      "The rule covers players who have folded. You can ask the dealer for the bet amount and make the decision yourself.")),
        conduct[4],
    ]

    static func multiwayShowdown(_ id: String, _ hero: String, _ first: String, _ second: String,
                                  _ board: String) -> TableCourseActivity {
        let shared = cards(board)
        let players = [hero, first, second].map(cards)
        precondition(Set(shared + players.flatMap { $0 }).count == 11)
        let fives = players.map { bestFiveCards($0 + shared) }
        let winner = fives.indices.first { index in
            fives.indices.filter { $0 != index }.allSatisfy {
                compareHands(hero: fives[index], villain: fives[$0]) == 0
            }
        }
        guard let winner else { preconditionFailure("Authored showdown needs one outright winner") }
        let names = [Copy("나", "You"), same("A"), same("B")]
        let shownHands = zip(names.dropFirst(), players.dropFirst()).map { name, hand in
            Row(name, same(cardNames(hand)))
        }
        let comparisons = zip(names, fives).map { name, five in Row(name, same(cardNames(five))) }
        return scenario(id, Copy("세 사람의 쇼다운", "Three hands at showdown"),
                        Copy("세 사람 모두 같은 팟을 받을 자격이 있어요. 각자 가장 강한 다섯 장을 비교하면 누가 이길까요?",
                             "All three players are eligible for one pot. Compare their strongest five-card hands. Who wins?"),
                        names, answer: winner,
                        Copy("세 사람의 베스트 파이브를 아래에 모았어요. 그중 가장 강한 패가 팟을 받아요.",
                             "The reveal shows all three best fives. The strongest takes the pot."),
                        evidence: .init(cards: players[0], board: shared, rows: shownHands), reveal: comparisons)
    }
}
