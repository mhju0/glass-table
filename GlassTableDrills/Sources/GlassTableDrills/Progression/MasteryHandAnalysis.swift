// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

extension MasteryCourseContent {
    static let turnHands = [
        turn("N1-example", "AhQh", "KsKc", "2h7hJc4d", pot: 13, call: 4, .decision, example: true),
        turn("N1-01", "KdQd", "AsAc", "4d8dJh2s", pot: 13, call: 6, .decision),
        turn("N1-02", "9h8h", "QcQd", "7c6h2hKs", pot: 21, call: 7, .outs),
        turn("N1-03", "AsJs", "KhKd", "Ts7s3c2d", pot: 32, call: 16, .price),
        turn("N1-04", "QcTc", "AhAd", "Jc8c2h5s", pot: 18, call: 4, .decision),
        turn("N1-05", "KdTd", "QsQh", "8d3d2c7h", pot: 16, call: 12, .decision),
    ]

    static let turnReview = [
        turn("N1-review-01", "KcQc", "AsAd", "2c8cJh5d", pot: 13, call: 6, .decision),
        turn("N1-review-02", "JhTh", "QsQd", "9h8s3h4c", pot: 20, call: 10, .outs),
        turn("N1-review-03", "Ah5h", "JcJd", "2h7hTc4d", pot: 18, call: 5, .decision),
    ]

    enum TurnTask { case outs, price, decision }

    static func turn(_ id: String, _ own: String, _ other: String, _ shared: String,
                             pot: Int, call: Int, _ task: TurnTask, example: Bool = false,
                             history: Copy? = nil) -> TableCourseActivity {
        let hero = cards(own), villain = cards(other), board = cards(shared)
        let known = Set(hero + villain + board)
        precondition(known.count == 8)
        let rivers = Deck.all.filter { !known.contains($0) }
        let outcomes = rivers.map { compareHands(hero: hero + board + [$0], villain: villain + board + [$0]) }
        let wins = outcomes.count { $0 == 0 }, ties = outcomes.count { $0 == 2 }
        let finalPot = pot + 2 * call
        let net = (2 * wins + ties) * finalPot - 2 * call * rivers.count
        let rows = [
            Row(Copy("턴 벳 전 팟", "Pot before turn bet"), same("\(pot)")),
            Row(Copy("상대 올인과 콜 가격", "Opponent shove and call price"), same("\(call)")),
        ]
        let evidence = TableCourseEvidence(cards: hero, board: board, opponent: villain, rows: rows)
        let assumptions = Copy("턴에 둘만 남았어요. 상대가 먼저 올인했고, 내 칩은 콜할 만큼 있어요. 상대 패는 이 문제의 가정이에요. 콜하면 추가 베팅 없이 쇼다운해요. 수수료는 없어요.",
                          "Two players remain on the turn. Your opponent opens all-in and you have enough to call. Treat their shown cards as an assumption. A call goes directly to showdown with no fees.")
        let common = history.map {
            Copy("\($0.text(in: .korean)) \(assumptions.text(in: .korean))",
                 "\($0.text(in: .english)) \(assumptions.text(in: .english))")
        } ?? assumptions
        var reveal = [
            Row(Copy("이기는 리버 · 비기는 리버", "Winning rivers · tying rivers"), same("\(wins) · \(ties)")),
            Row(Copy("평균 팟 몫", "Expected share"), same("(\(wins) + \(ties) ÷ 2) ÷ \(rivers.count)")),
            Row(Copy("본전에 필요한 몫", "Break-even share"), same("\(call) ÷ \(finalPot)")),
        ]
        let title: Copy, options: [Copy], answer: Int
        switch task {
        case .outs:
            title = Copy("나를 이기게 하는 리버는 몇 장?", "How many rivers make you win outright?")
            options = [same("\(wins - 2)"), same("\(wins)"), same("\(wins + 2)")]
            answer = 1
        case .price:
            title = Copy("본전에 필요한 몫은?", "What share breaks even?")
            options = [same("\(call) ÷ \(finalPot)"), same("\(call) ÷ \(pot + call)"), same("\(call) ÷ \(pot)")]
            answer = 0
        case .decision:
            title = Copy("턴 올인에 콜할까요?", "Call the turn shove?")
            options = [Copy("콜의 EV가 높아요", "Calling has higher EV"), Copy("폴드의 EV가 높아요", "Folding has higher EV"),
                       Copy("같아요", "They are equal")]
            answer = net > 0 ? 0 : net < 0 ? 1 : 2
            reveal.append(Row(Copy("이 상황의 판단", "Decision in this setup"), options[answer]))
        }
        let reason: Copy
        if task == .outs {
            let winningRivers = zip(rivers, outcomes).compactMap { river, result in result == 0 ? river : nil }
            reason = Copy("이기는 리버는 \(cardNames(winningRivers))예요. 스트레이트와 플러시를 둘 다 만드는 카드도 덱에는 한 장뿐이에요.",
                          "The winning rivers are \(cardNames(winningRivers)). A card that completes both a straight and a flush is still only one card.")
        } else {
            reason = Copy("리버마다 두 사람의 가장 강한 다섯 장을 비교해요. 이기면 팟 전부, 비기면 절반을 받아요. 콜의 손익을 따질 때는 이 평균 몫과 콜 가격 ÷ 콜 뒤 팟을 비교해요.",
                          "Compare the strongest five for each player on every possible river. A win gets the entire pot and a tie gets half. Compare that average share with the call divided by the pot after calling.")
        }
        return scenario(id, title, common, options, answer: answer, reason,
                        evidence: evidence, reveal: reveal, example: example)
    }

    static let riverHands = [
        showdown("N2-example", "AhJh", "KsKd", "2h7hTc3d9h", example: true),
        showdown("N2-01", "QdJc", "QhTd", "Qs8h5c4d2s"),
        showdown("N2-02", "As2s", "6d6c", "TcJhQhKdAh"),
        showdown("N2-03", "Ac4c", "9d9s", "9c4d4hAs7s"),
        resultBias("N2-04", "KsJs", "QhQd", "Ts5s3c7h2s", pot: 14, call: 14),
        resultBias("N2-05", "Ah7h", "KcKd", "2h4hJs6c3s", pot: 22, call: 4),
    ]

    static let riverReview = [
        showdown("N2-review-01", "KcQc", "AsAd", "2c8cJh5dTc"),
        showdown("N2-review-02", "Kd8s", "Kh9c", "KsAcQd6h2h"),
        resultBias("N2-review-03", "QdTd", "AsAh", "2d5dJc9s7h", pot: 18, call: 4),
    ]

    static func showdown(_ id: String, _ own: String, _ other: String, _ shared: String,
                                 example: Bool = false) -> TableCourseActivity {
        let hero = cards(own), villain = cards(other), board = cards(shared)
        precondition(Set(hero + villain + board).count == 9)
        let first = bestFiveCards(hero + board), second = bestFiveCards(villain + board)
        let result = compareHands(hero: first, villain: second)
        return scenario(id, Copy("쇼다운에서 팟은 누구에게 갈까요?", "Who takes the pot at showdown?"),
            Copy("두 사람 모두 팟 하나를 받을 자격이 있어요. 각자 가장 강한 다섯 장을 머릿속으로 고른 뒤 결과를 골라 보세요.",
                 "Both players are eligible for one pot. Name the strongest five for each player before choosing the result."),
            [Copy("내가 받아요", "You win"), Copy("상대가 받아요", "Opponent wins"),
             Copy("나눠 가져요", "Split the pot")], answer: result,
            Copy("카드는 다섯 장까지만 비교해요. 강도가 같으면 남은 홀 카드나 무늬로 승부를 가르지 않아요.",
                 "Only the best five determine the outcome. When those hands tie, extra hole cards or suits do not break the tie."),
            evidence: .init(cards: hero, board: board, opponent: villain), reveal: [
                Row(Copy("내 베스트 파이브", "Your best five"), same(cardNames(first))),
                Row(Copy("상대 베스트 파이브", "Opponent’s best five"), same(cardNames(second))),
            ], example: example)
    }

    private static func resultBias(_ id: String, _ own: String, _ other: String, _ shared: String,
                                   pot: Int, call: Int) -> TableCourseActivity {
        let hero = cards(own), villain = cards(other), board = cards(shared)
        precondition(Set(hero + villain + board).count == 9)
        let turn = Array(board.dropLast())
        let seen = Set(hero + villain + turn)
        let outcomes = Deck.all.filter { !seen.contains($0) }.map {
            compareHands(hero: hero + turn + [$0], villain: villain + turn + [$0])
        }
        let shares = 2 * outcomes.count { $0 == 0 } + outcomes.count { $0 == 2 }
        let finalPot = pot + 2 * call
        let paidOff = shares * finalPot > 2 * call * outcomes.count
        let won = compareHands(hero: hero + board, villain: villain + board) == 0
        let group = [
            Copy("콜이 유리했고 리버에서 이겼어요", "The call had higher EV and the river won"),
            Copy("폴드가 유리했지만 콜했다면 리버에서 이겼어요", "Folding had higher EV, though calling would have won this river"),
            Copy("콜이 유리했지만 리버에서 졌어요", "The call had higher EV, though this river lost"),
            Copy("폴드가 유리했고 콜했다면 리버에서 졌어요", "Folding had higher EV and calling would have lost this river"),
        ]
        return scenario(id, Copy("리버 결과로 턴의 판단을 평가할까?", "Does this river tell you if the turn call was good?"),
            Copy("턴에서 둘만 남았고 상대가 \(pot) 팟에 \(call) 올인했어요. 내 스택은 충분하고 수수료는 없어요. 상대 카드는 이 문제의 가정이에요. 맨 오른쪽 카드가 리버예요. 턴부터의 EV와 이 리버의 결과를 따로 판단해 보세요.",
                 "Heads-up on the turn, your opponent shoved \(call) into \(pot). You covered them and there are no fees. Their shown cards are an assumption. The rightmost card is the river. Evaluate the turn EV and this river result separately."),
            group, answer: won ? (paidOff ? 0 : 1) : (paidOff ? 2 : 3),
            Copy("턴의 판단은 그때 가능했던 모든 리버를 바탕으로 해요. 여기서 리버 한 장이 우연히 나왔다는 사실은 턴에 어느 쪽의 EV가 컸는지 바꾸지 않아요.",
                 "Evaluate the turn using all rivers possible at the time. The single river that happened does not change which turn action had higher EV."),
            evidence: .init(cards: hero, board: board, opponent: villain),
            reveal: [
                Row(Copy("턴에서 평균 팟 몫", "Expected pot share on the turn"), same("\(shares) ÷ \(2 * outcomes.count)")),
                Row(Copy("콜에 필요한 몫", "Break-even share"), same("\(call) ÷ \(finalPot)")),
            ])
    }

    static func cardNames(_ cards: [Card]) -> String {
        cards.map { card in
            let rank = String(card.description.dropLast()).replacingOccurrences(of: "T", with: "10")
            return rank + ["♣", "♦", "♥", "♠"][card.suit]
        }.joined(separator: " ")
    }
}

extension MasteryCourseContent {
    static let fullHand = [
        scenario("N3-example", Copy("결과를 보기 전에 판단할 것", "What to decide before seeing the result"),
                 Copy("1/2 블라인드, 앤티와 수수료는 없어요. 첫 자리가 폴드했고 버튼인 내 차례예요. 지금 확인할 사실과 턴에서 확인할 사실을 나눠 생각해 봐요.",
                      "Blinds are 1/2 with no antes or fees. The first seat folded and you are on the button. Separate what you can check now from what you learn on the turn."),
                 [], answer: 0, Copy("지금은 자리, 남은 상대와 합법 행동을 봐요. 새 카드와 베팅이 나오면 패의 가능성과 콜의 가격을 다시 계산해요. 리버 결과는 그 뒤에 따로 판단해요.",
                                    "Start with position, the remaining players and legal options. Reassess possible hands and the call price as new cards and bets appear. Evaluate the river outcome separately."),
                 evidence: .init(cards: cards("JsTs")), example: true),
        scenario("N3-01", Copy("플랍 전, 표시된 규칙으로 결정하기", "Preflop, decide under the stated policy"),
                 Copy("1/2 블라인드예요. 첫 자리가 폴드했고 내 뒤에 두 블라인드가 남았어요. 모두 6 이상 있어요. 이 연습의 버튼 규칙은 폴드로 돌아왔을 때 JTs를 6으로 오픈하는 거예요. 어떤 행동이 맞나요?",
                      "Blinds are 1/2. The first seat folded, two blinds are behind you and everyone has at least 6. This exercise’s button policy opens JTs to 6 when folded to. What action fits?"),
                 [Copy("2를 콜해요", "Call 2"), Copy("6으로 레이즈해요", "Raise to 6"), Copy("체크해요", "Check")],
                 answer: 1, Copy("6은 2의 빅 블라인드를 넘어서는 합법적인 오픈이고 연습 규칙에도 맞아요. 스택이나 상대가 바뀌면 전략이 달라질 수 있어요.",
                                 "A raise to 6 is legal over a big blind of 2 and matches the stated policy. Other stacks and opponents can change the strategy."),
                 evidence: .init(cards: cards("JsTs"))),
        scenario("N3-02", Copy("플랍 차례와 현재 패", "Flop order and current hand"),
                 Copy("내가 버튼에서 6으로 오픈했어요. 스몰 블라인드는 1을 낸 뒤 폴드했고, 빅 블라인드는 4를 더 내 콜했어요. 팟은 13이에요. 빅 블라인드가 체크했어요. 지금 무엇이 맞나요?",
                      "You opened the button to 6. The small blind folded after posting 1 and the big blind added 4 to call. The pot is 13. The big blind checks. What is true now?"),
                 [Copy("마지막 차례이고 아직 플러시는 없어요", "You act last and have no made flush"),
                  Copy("빅 블라인드가 나중에 체크해요", "The big blind checks after you"),
                  Copy("마지막 차례이고 이미 플러시예요", "You act last and already have a flush")],
                 answer: 0, Copy("버튼은 남은 빅 블라인드 뒤에 행동해요. 스페이드는 손에 두 장, 보드에 두 장이에요. 플러시를 만들려면 스페이드가 한 장 더 필요해요.",
                                 "The button acts after the big blind. There are two spades in your hand and two on the board. A fifth spade would make a flush."),
                 evidence: .init(cards: cards("JsTs"), board: cards("9s4s6d"))),
        turn("N3-03", "JsTs", "QhQc", "9s4s6d8h", pot: 13, call: 5, .decision,
             history: Copy("플랍에 두 사람이 체크했어요. 빅 블라인드가 턴에서 베팅을 시작해요.",
                           "Both players checked the flop. The big blind opens the betting on the turn.")),
        showdown("N3-04", "JsTs", "QhQc", "9s4s6d8h7d"),
        resultBias("N3-05", "JsTs", "QhQc", "9s4s6d8h7d", pot: 13, call: 5),
    ]

    static let fullHandReview = [
        turn("N3-review-01", "QsJs", "AhAc", "2s8sTh4d", pot: 15, call: 9, .decision),
        showdown("N3-review-02", "8c7c", "JdJs", "9c5h6sAd4d"),
        resultBias("N3-review-03", "QhJh", "KsKc", "3h5h8d4sTd", pot: 21, call: 7),
    ]
}

extension MasteryCourseContent {
    static let revisedFullHand = Array(fullHand.dropLast()) + [
        scenario("N3-v2-synthesis", Copy("이 핸드의 결정과 결과", "Putting the decision and result together"),
                 Copy("턴에 콜의 EV가 더 높았고 리버 7♦로 스트레이트가 됐어요. 앞의 두 판단을 함께 확인해요.",
                      "Calling had higher EV on the turn. The 7♦ completed your straight on the river. Put the two earlier answers together."),
                 [], answer: 0,
                 Copy("리버가 빗나갔어도 같은 턴 정보에서는 콜의 EV가 높아요.",
                      "A different river would leave the turn EV comparison unchanged."),
                 evidence: .init(cards: cards("JsTs"), board: cards("9s4s6d8h7d"), opponent: cards("QhQc")),
                 example: true),
        transferHand("N3-v2-05", "QhTh", "KcKd", "Jh8h3d5s", open: 5, call: 7),
    ]

    static func transferHand(_ id: String, _ own: String, _ other: String, _ shared: String,
                             open: Int, call: Int) -> TableCourseActivity {
        let hero = cards(own), villain = cards(other), board = cards(shared)
        let known = Set(hero + villain + board)
        precondition(known.count == 8)
        let rivers = Deck.all.filter { !known.contains($0) }
        let results = rivers.map { compareHands(hero: hero + board + [$0], villain: villain + board + [$0]) }
        let wins = results.count { $0 == 0 }, ties = results.count { $0 == 2 }
        let pot = 2 * open + 1, finalPot = pot + 2 * call
        let callWins = (2 * wins + ties) * finalPot > 2 * rivers.count * call
        return scenario(id, Copy("처음 보는 핸드의 턴 판단", "Work through a new hand"),
            Copy("블라인드는 1/2, 앤티와 수수료는 없어요. 버튼인 내가 \(open)으로 오픈했어요. 스몰 블라인드는 폴드, 빅 블라인드는 콜했어요. 플랍에서 둘 다 체크했고 턴에 상대가 \(call) 올인했어요. 내 스택은 충분해요. 표시한 상대 패를 가정하고 리버 한 장 뒤 쇼다운한다고 할 때, 맞는 설명은?",
                 "Blinds are 1/2, with no antes or fees. You open the button to \(open). The small blind folds and the big blind calls. Both check the flop. The big blind shoves \(call) on the turn and you cover. Assume the opponent holds the cards shown. A call deals one river and goes to showdown. Which analysis fits?"),
            [Copy("플랍에서 마지막 차례예요. \(call)/\(finalPot)보다 평균 팟 몫이 낮아 폴드가 나아요.",
                  "You act last on the flop. Your share falls below \(call)/\(finalPot), so folding has higher EV."),
             Copy("플랍에서 마지막 차례예요. \(call)/\(finalPot)보다 평균 팟 몫이 높아 콜이 나아요.",
                  "You act last on the flop. Your share exceeds \(call)/\(finalPot), so calling has higher EV."),
             Copy("플랍에서 먼저 행동해요. 올인 전 팟으로 콜 가격을 나눠요.",
                  "You act first on the flop. Price the call against the pot before the shove.")],
            answer: callWins ? 1 : 0,
            Copy("버튼은 빅 블라인드 뒤에 행동해요. 두 사람이 \(open)씩 냈고 스몰 블라인드 1이 남아요. 양쪽에 올인 금액을 한 번씩 더한 최종 팟과 콜의 가격을 비교해요.",
                 "The button acts after the big blind. Both put in \(open), and the small blind’s 1 stays. The final pot includes the shove and your match."),
            evidence: .init(cards: hero, board: board, opponent: villain), reveal: [
                Row(Copy("턴 시작 팟", "Pot at turn start"), same("\(open) + \(open) + 1 = \(pot)")),
                Row(Copy("콜 뒤 팟", "Pot after calling"), same("\(pot) + \(call) + \(call) = \(finalPot)")),
                Row(Copy("평균 팟 몫", "Expected share"), same("(\(wins) + \(ties) ÷ 2) ÷ 44")),
                Row(Copy("본전에 필요한 몫", "Break-even share"), same("\(call) ÷ \(finalPot)")),
            ])
    }
}
