// Copyright (c) 2026 Michael Ju (github.com/mhju0)

enum ExpectedValueUnitContent {
    private typealias Copy = TableCourseText
    private typealias Row = TableCourseRow

    // Exact hundredths of a chip cover all authored frequencies and half-pot splits.
    private struct Call {
        let pot: Int
        let cost: Int

        var finalPot: Int { pot + cost }
        var rows: [Row] {
            [Row(Copy("상대 벳이 들어간 팟", "Pot with opponent’s bet"), chips(100 * pot)),
             Row(Copy("콜에 더 낼 칩", "Extra to call"), chips(100 * cost))]
        }
    }

    private enum Outcome {
        case win, tie, loss, fold

        var title: Copy {
            switch self {
            case .win: Copy("승리", "Win")
            case .tie: Copy("무승부", "Tie")
            case .loss: Copy("패배", "Loss")
            case .fold: Copy("폴드", "Fold")
            }
        }

        func payout(from pot: Int) -> Int {
            switch self {
            case .win: 100 * pot
            case .tie: 50 * pot
            case .loss, .fold: 0
            }
        }
    }

    private enum RiverCase {
        case folds(Outcome)
        case calls(Outcome)

        func net(pot: Int, bet: Int, betting: Bool) -> Int {
            switch (self, betting) {
            case (.folds, true): 100 * pot
            case (.calls(let outcome), true): outcome.payout(from: pot + 2 * bet) - 100 * bet
            case (.folds(let outcome), false), (.calls(let outcome), false): outcome.payout(from: pot)
            }
        }
    }

    private enum DefenseTask {
        case minimum
        case bluffValue(callsPerHundred: Int)
        case meaning(hand: String)
    }

    static func activities(for lesson: TableCourseLesson) -> [TableCourseActivity] {
        switch lesson {
        case .k1:
            [
                netResult("K1-example", paid: 6, call: Call(pot: 28, cost: 8), outcome: .win, worked: true),
                netResult("K1-01", paid: 5, call: Call(pot: 23, cost: 9), outcome: .tie, order: 1),
                netResult("K1-02", paid: 8, call: Call(pot: 38, cost: 10), outcome: .fold, order: 2),
                netResult("K1-03", paid: 12, call: Call(pot: 52, cost: 14), outcome: .win, order: 2),
            ]
        case .k2:
            [
                weighted("K2-example", Call(pot: 24, cost: 8), wins: 2, ties: 3, worked: true),
                weighted("K2-01", Call(pot: 21, cost: 9), wins: 1, ties: 4, order: 2),
                weighted("K2-02", Call(pot: 26, cost: 14), wins: 2, ties: 2, observed: .win, order: 1),
                weighted("K2-03", Call(pot: 19, cost: 11), wins: 4, ties: 1, observed: .loss, order: 2),
            ]
        case .k3:
            [
                callOrFold("K3-example", Call(pot: 42, cost: 18), equity: 35, worked: true),
                callOrFold("K3-01", Call(pot: 25, cost: 15), equity: 30),
                callOrFold("K3-02", Call(pot: 36, cost: 14), equity: 28, order: 2),
                callOrFold("K3-03", Call(pot: 55, cost: 25), equity: 40, order: 1),
            ]
        case .k4:
            [
                evGap("K4-example", pot: 24, bet: 12, cases: [.folds(.loss), .calls(.win), .calls(.loss), .calls(.tie)],
                      betChosen: false, worked: true),
                evGap("K4-01", pot: 32, bet: 16, cases: [.folds(.win), .calls(.loss), .calls(.loss), .calls(.tie)],
                      betChosen: true, order: 1),
                evGap("K4-02", pot: 48, bet: 10, cases: [.folds(.win), .folds(.win), .calls(.win), .calls(.loss)],
                      betChosen: false),
                evGap("K4-03", pot: 36, bet: 14, cases: [.folds(.loss), .calls(.win), .calls(.tie), .calls(.loss)],
                      betChosen: false, order: 1),
            ]
        case .k5:
            [
                defense("K5-example", pot: 30, bet: 20, task: .minimum, worked: true),
                defense("K5-01", pot: 24, bet: 8, task: .minimum, order: 2),
                defense("K5-02", pot: 30, bet: 30, task: .bluffValue(callsPerHundred: 40), order: 2),
                defense("K5-03", pot: 40, bet: 20, task: .meaning(hand: "QJs"), order: 1),
            ]
        default: []
        }
    }

    static func reviewActivities(for lesson: TableCourseLesson) -> [TableCourseActivity] {
        switch lesson {
        case .k1:
            [
                netResult("K1-review-01", paid: 3, call: Call(pot: 19, cost: 7), outcome: .win),
                netResult("K1-review-02", paid: 11, call: Call(pot: 44, cost: 12), outcome: .fold, order: 1),
                netResult("K1-review-03", paid: 9, call: Call(pot: 27, cost: 13), outcome: .tie),
            ]
        case .k2:
            [
                weighted("K2-review-01", Call(pot: 40, cost: 20), wins: 2, ties: 3, observed: .tie),
                weighted("K2-review-02", Call(pot: 33, cost: 17), wins: 2, ties: 1, order: 1),
                weighted("K2-review-03", Call(pot: 16, cost: 4), wins: 0, ties: 4),
            ]
        case .k3:
            [
                callOrFold("K3-review-01", Call(pot: 48, cost: 12), equity: 25, order: 1),
                callOrFold("K3-review-02", Call(pot: 49, cost: 21), equity: 30, order: 1),
                callOrFold("K3-review-03", Call(pot: 36, cost: 24), equity: 35, order: 2),
            ]
        case .k4:
            [
                evGap("K4-review-01", pot: 20, bet: 6, cases: [.folds(.win), .calls(.win), .calls(.win), .calls(.loss)],
                      betChosen: false, order: 2),
                evGap("K4-review-02", pot: 28, bet: 16, cases: [.folds(.win), .calls(.win), .calls(.loss), .calls(.loss)],
                      betChosen: true, order: 1),
                evGap("K4-review-03", pot: 40, bet: 20, cases: [.folds(.win), .calls(.tie), .calls(.tie), .calls(.tie)],
                      betChosen: true),
            ]
        case .k5:
            [
                defense("K5-review-01", pot: 18, bet: 12, task: .bluffValue(callsPerHundred: 60), order: 2),
                defense("K5-review-02", pot: 28, bet: 12, task: .meaning(hand: "A9o")),
                defense("K5-review-03", pot: 45, bet: 55, task: .minimum, order: 2),
            ]
        default: []
        }
    }

    private static func netResult(_ id: String, paid: Int, call: Call, outcome: Outcome,
                                  order: Int = 0, worked: Bool = false) -> TableCourseActivity {
        let extra = outcome == .fold ? 0 : call.cost
        let payout = outcome.payout(from: call.finalPot)
        let net = payout - 100 * extra
        let wholeHand = net - 100 * paid
        let rows = [
            Row(Copy("내가 이미 낸 칩", "You already paid"), chips(100 * paid)),
        ] + call.rows + [Row(Copy("지금부터의 결과", "Outcome from here"), outcome.title)]
        let steps = [
            Row(Copy("받는 칩", "Chips you receive"), chips(payout)),
            Row(Copy("지금 내는 칩", "Chips you pay now"), chips(100 * extra)),
            Row(Copy("지금부터의 순손익", "Net from this decision"), subtraction(payout, 100 * extra)),
            Row(Copy("핸드 전체의 순손익", "Net over the whole hand"), subtraction(net, 100 * paid)),
        ]
        return exercise(
            id, title: Copy("지금부터 칩이 얼마나 바뀔까?", "How much changes from here?"),
            prompt: Copy("상대와 둘만 남았어요. 폴드하면 끝나고, 콜하면 바로 결과를 봐요. 수수료는 없어요. 지금 가진 칩을 기준으로 얼마나 늘거나 줄까요?",
                         "Only you and your opponent remain. A fold ends the hand and a call goes straight to showdown. No fees. How much will your stack change from here?"),
            rows: rows, steps: steps, choices: [net, wholeHand, outcome == .fold ? -100 * call.cost : payout].map { chips($0, signed: true) },
            order: order,
            explanation: Copy("지금 받는 칩에서 지금 내는 칩을 빼요. 이미 낸 칩은 핸드 전체의 손익을 셀 때 빼요.",
                              "Subtract what you pay now from what you receive. Subtract the chips you already paid when counting the whole hand."),
            worked: worked
        )
    }

    private static func weighted(_ id: String, _ call: Call, wins: Int, ties: Int,
                                 observed: Outcome? = nil, order: Int = 0, worked: Bool = false) -> TableCourseActivity {
        let losses = 10 - wins - ties
        let amounts = [Outcome.win, .tie, .loss].map { $0.payout(from: call.finalPot) - 100 * call.cost }
        let total = wins * amounts[0] + ties * amounts[1] + losses * amounts[2]
        let ev = total / 10
        let rows = call.rows + [
            Row(Copy("승리 · 무승부 · 패배", "Wins · Ties · Losses"),
                same("\(wins) · \(ties) · \(losses)")),
        ] + (observed.map { [Row(Copy("한 핸드의 결과", "Result on one hand"), $0.title)] } ?? [])
        let steps = [
            Row(Copy("콜 뒤 팟", "Pot after calling"), chips(100 * call.finalPot)),
            Row(Copy("승리 순손익", "Net on a win"), chips(amounts[0], signed: true)),
            Row(Copy("무승부 순손익", "Net on a tie"), subtraction(50 * call.finalPot, 100 * call.cost)),
            Row(Copy("패배 순손익", "Net on a loss"), chips(amounts[2], signed: true)),
            Row(Copy("10가지 결과의 합", "Total across 10 outcomes"),
                same("\(wins) × (\(decimal(amounts[0]))) + \(ties) × (\(decimal(amounts[1]))) + \(losses) × (\(decimal(amounts[2]))) = \(decimal(total))")),
            Row(Copy("콜의 EV", "Call EV"), same("\(decimal(total)) ÷ 10 = \(decimal(ev, signed: true))")),
        ]
        let firstDistractor = observed.map { $0.payout(from: call.finalPot) - 100 * call.cost }
            ?? ((wins * amounts[0] + (ties + losses) * amounts[2]) / 10)
        return exercise(
            id, title: Copy("콜하면 평균 얼마가 남을까?", "What is a call worth on average?"),
            prompt: Copy("둘이 바로 쇼다운을 해요. 수수료는 없고, 10가지 경우의 가능성이 같아요. 콜의 평균 순손익(EV)은 얼마일까요?",
                         "Two players go straight to showdown with no fees. All 10 cases are equally likely. What is the average net gain or loss from calling (EV)?"),
            rows: rows, steps: steps,
            choices: [ev, firstDistractor, ev + 100 * call.cost].map { chips($0, signed: true) },
            order: order,
            explanation: Copy("무승부면 팟의 절반을 받고 콜에 낸 칩을 빼요. 각 순손익에 횟수를 곱해 더한 뒤 10으로 나누면 기댓값(EV)이 나와요. 한 번의 결과는 달라질 수 있어요.",
                              "A tie pays half the pot, minus what you paid to call. Multiply each net result by its count, add them and divide by 10 for expected value (EV). One outcome can differ from the average."),
            worked: worked
        )
    }

    private static func callOrFold(_ id: String, _ call: Call, equity: Int,
                                   order: Int = 0, worked: Bool = false) -> TableCourseActivity {
        let ev = equity * call.finalPot - 100 * call.cost
        let rows = call.rows + [Row(Copy("평균 팟 몫 (에퀴티)", "Average pot share (equity)"), same("\(equity)%"))]
        let choices = [Copy("콜", "Call"), Copy("폴드", "Fold"), Copy("같은 EV", "Same EV")]
        return exercise(
            id, title: Copy("콜과 폴드의 EV", "Call EV and fold EV"),
            prompt: Copy("상대와 둘만 남았어요. 콜하면 추가 베팅 없이 쇼다운까지 가요. 수수료는 없어요. 지금부터 어느 쪽의 EV가 더 높을까요?",
                         "Only you and your opponent remain. Calling takes you to showdown with no more bets or fees. Which action has higher EV from here?"),
            rows: rows, steps: [
                Row(Copy("콜 뒤 팟", "Pot after calling"), chips(100 * call.finalPot)),
                Row(Copy("콜하면 평균 받는 칩", "Average payout if you call"), same("\(equity)% × \(call.finalPot) = \(decimal(equity * call.finalPot))")),
                Row(Copy("콜의 EV", "Call EV"), subtraction(equity * call.finalPot, 100 * call.cost)),
                Row(Copy("폴드의 EV", "Fold EV"), chips(0)),
            ], choices: choices, answer: ev > 0 ? 0 : ev < 0 ? 1 : 2, order: order,
            explanation: Copy("에퀴티는 무승부 몫까지 포함해 평균적으로 받는 팟의 비율이에요. 콜 뒤 팟에 그 비율을 곱하고 콜에 낼 칩을 빼요. 폴드하면 지금 더 내거나 받는 칩이 없어요.",
                              "Equity is your average share of the pot, including your share of ties. Multiply it by the pot after calling and subtract the call. Folding pays and costs zero from here."),
            worked: worked
        )
    }

    private static func evGap(_ id: String, pot: Int, bet: Int, cases: [RiverCase], betChosen: Bool,
                              order: Int = 0, worked: Bool = false) -> TableCourseActivity {
        let checkNets = cases.map { $0.net(pot: pot, bet: bet, betting: false) }
        let betNets = cases.map { $0.net(pot: pot, bet: bet, betting: true) }
        let checkEV = checkNets.reduce(0, +) / cases.count
        let betEV = betNets.reduce(0, +) / cases.count
        let chosenEV = betChosen ? betEV : checkEV
        let bestEV = max(checkEV, betEV)
        let gap = bestEV - chosenEV
        let rows = [
            Row(Copy("체크의 EV", "Check EV"), chips(checkEV, signed: true)),
            Row(Copy("벳의 EV", "Bet EV"), chips(betEV, signed: true)),
            Row(Copy("내 선택", "Your choice"), betChosen ? Copy("벳", "Bet") : Copy("체크", "Check")),
        ]
        return exercise(
            id, title: Copy("선택에 따라 EV가 얼마나 달라질까?", "How much EV did the choice cost?"),
            prompt: Copy("리버에 둘만 남았어요. 상대가 체크한 뒤 내가 체크하면 쇼다운이에요. 내가 벳하면 상대는 콜이나 폴드만 해요. 수수료는 없어요. 가장 높은 EV에서 내 선택의 EV를 빼면 얼마일까요?",
                         "Two players remain on the river. Your opponent checked. Checking back goes to showdown. If you bet, they only call or fold. No fees. How much EV did you give up compared with the best choice?"),
            rows: rows, steps: [
                Row(Copy("벳 전 팟", "Pot before the bet"), chips(100 * pot)),
                Row(Copy("벳 크기", "Bet size"), chips(100 * bet)),
                Row(Copy("체크 순손익 · 평균", "Check outcomes · Average"), average(checkNets, ev: checkEV)),
                Row(Copy("벳 순손익 · 평균", "Bet outcomes · Average"), average(betNets, ev: betEV)),
                Row(Copy("선택으로 포기한 EV", "EV given up"), subtraction(bestEV, chosenEV)),
            ], choices: [gap, bestEV, gap == 0 ? bestEV + 100 * bet : chosenEV].map { chips($0) },
            order: order,
            explanation: Copy("같은 확률의 네 경우에서 지금부터의 순손익을 각각 평균 냈어요. 더 높은 EV와 내 선택의 EV가 같으면 포기한 EV는 0이에요.",
                              "Each EV averages the net result from here across four equally likely cases. If your choice matches the highest EV, you gave up zero."),
            worked: worked
        )
    }

    private static func defense(_ id: String, pot: Int, bet: Int, task: DefenseTask,
                                order: Int = 0, worked: Bool = false) -> TableCourseActivity {
        let total = pot + bet
        let minimum = share(pot, of: total)
        var rows = [
            Row(Copy("벳 전 팟", "Pot before the bet"), chips(100 * pot)),
            Row(Copy("블러프에 거는 칩", "Bluff size"), chips(100 * bet)),
        ]
        var steps = [
            Row(Copy("상대가 폴드하면", "If the defender folds"), chips(100 * pot, signed: true)),
            Row(Copy("상대가 콜하면", "If the defender calls"), chips(-100 * bet, signed: true)),
            Row(Copy("최소 방어 빈도 (MDF)", "Minimum defense frequency (MDF)"), same("\(pot) ÷ \(total) = \(minimum)")),
        ]
        let title: Copy
        let question: Copy
        let choices: [Copy]
        let explanation: Copy
        switch task {
        case .minimum:
            title = Copy("얼마나 자주 콜해야 할까?", "How often to defend?")
            question = Copy("레인지 전체에서 블러프가 본전이 되는 콜 비율은 얼마인가요?",
                            "What call rate across the range makes the bluff break even?")
            choices = [minimum, share(bet, of: total), share(pot, of: pot + 2 * bet)].map(same)
            steps.append(Row(Copy("이 빈도에서 블러프의 EV", "Bluff EV at this frequency"),
                             same("(\(bet) × \(pot) − \(pot) × \(bet)) ÷ \(total) = 0")))
            explanation = Copy("콜이 충분히 많으면 폴드로 얻는 칩을 콜로 잃는 칩이 상쇄해요. 두 값이 같아지는 콜 빈도는 벳 전 팟을 그 팟과 벳의 합으로 나눈 값이에요. 이 기준은 레인지 전체에 적용돼요.",
                               "As calls become more frequent, the losses when called offset the chips won on folds. They balance at the pot before the bet divided by that pot plus the bet. This applies across the range.")
        case .bluffValue(let calls):
            title = Copy("이 빈도면 블러프가 이득일까?", "Does the bluff gain at this frequency?")
            question = Copy("이 방어 빈도에서 블러프의 평균 순손익은 얼마일까요?",
                            "What is the bluff’s average net gain or loss at this defense frequency?")
            rows.append(Row(Copy("레인지 전체의 콜 빈도", "Call frequency across the range"), same("\(calls)%")))
            let ev = (100 - calls) * pot - calls * bet
            let amounts = ev == 0 ? [0, 100 * pot, -100 * bet] : [ev, -ev, 0]
            choices = amounts.map { chips($0, signed: true) }
            steps.append(Row(Copy("블러프의 EV", "Bluff EV"),
                             same("\(100 - calls)% × \(pot) − \(calls)% × \(bet) = \(decimal(ev, signed: true))")))
            explanation = Copy("폴드 빈도만큼 팟을 얻고 콜 빈도만큼 벳을 잃어요. 이 블러프는 상대가 최소 방어 빈도만큼 콜할 때 손익분기예요.",
                               "Weight the pot you win by fold frequency and the bet you lose by call frequency. The bluff breaks even when the defender calls at the minimum defense frequency.")
        case .meaning(let hand):
            title = Copy("레인지 전체와 한 핸드", "The range and one hand")
            question = Copy("상대 핸드가 \(hand)일 때, 이 최소 방어 빈도로 무엇을 알 수 있을까요?",
                            "When the defender holds \(hand), what does this minimum defense frequency tell you?")
            rows.append(Row(Copy("이 모델의 최소 방어 빈도", "Minimum defense in this model"), same(minimum)))
            choices = [Copy("레인지 전체의 기준이에요", "It applies across the range"),
                       Copy("\(hand)면 항상 콜해요", "Always call with \(hand)"),
                       Copy("\(hand)도 이 빈도로 콜해요", "Call with \(hand) at this rate")]
            explanation = Copy("이 비율은 이 모델에서 레인지 전체가 얼마나 자주 콜할지의 기준이에요. 어떤 핸드로 콜할지는 핸드와 상대의 베팅 레인지에 따라 달라져요.",
                               "This is a minimum call frequency across the range in this model. Which hands to call with depends on the hand and the bettor’s range.")
        }
        let model = Copy("둘만 남은 리버예요. 체크 기댓값은 0칩이에요.\n크기가 고정된 블러프는 콜을 받으면 져요.\n상대는 콜이나 폴드만 해요. 추가 베팅과 수수료는 없어요.",
                         "River, heads-up. Checking earns 0.\nA fixed-size bluff loses when called.\nCall or fold. No later bets or fees.")
        return exercise(
            id, title: title,
            prompt: Copy("\(model.text(in: .korean))\n\(question.text(in: .korean))",
                         "\(model.text(in: .english))\n\(question.text(in: .english))"),
            rows: rows, steps: steps, choices: choices, order: order,
            explanation: explanation, worked: worked
        )
    }

    private static func exercise(_ id: String, title: Copy, prompt: Copy, rows: [Row], steps: [Row],
                                 choices: [Copy], answer: Int = 0, order: Int,
                                 explanation: Copy, worked: Bool) -> TableCourseActivity {
        let rotated = Array(choices[order...]) + choices[..<order]
        return TableCourseActivity(
            id: id, title: title, prompt: prompt,
            evidence: .init(rows: worked ? rows + steps : rows),
            choices: worked ? [] : rotated,
            correctChoice: worked ? nil : (answer - order + choices.count) % choices.count,
            explanation: explanation,
            revealedEvidence: worked ? nil : .init(rows: rows + steps)
        )
    }

    private static func average(_ values: [Int], ev: Int) -> Copy {
        let terms = values.map { decimal($0, signed: true) }.joined(separator: " · ")
        return same("\(terms) → \(decimal(ev, signed: true))")
    }

    private static func subtraction(_ payout: Int, _ cost: Int) -> Copy {
        same("\(decimal(payout)) − \(decimal(cost)) = \(decimal(payout - cost, signed: true))")
    }

    private static func chips(_ amount: Int, signed: Bool = false) -> Copy {
        let count = decimal(amount, signed: signed)
        return Copy("칩 \(count)개", "\(count) \(abs(amount) == 100 ? "chip" : "chips")")
    }

    private static func share(_ numerator: Int, of denominator: Int) -> String {
        let (hundredths, remainder) = (10_000 * numerator).quotientAndRemainder(dividingBy: denominator)
        return remainder == 0 ? "\(decimal(hundredths))%" : "\(numerator)/\(denominator)"
    }

    private static func decimal(_ hundredths: Int, signed: Bool = false) -> String {
        let sign = hundredths < 0 ? "−" : signed && hundredths > 0 ? "+" : ""
        let (whole, fraction) = abs(hundredths).quotientAndRemainder(dividingBy: 100)
        guard fraction > 0 else { return "\(sign)\(whole)" }
        let suffix = fraction % 10 == 0 ? "\(fraction / 10)" : fraction < 10 ? "0\(fraction)" : "\(fraction)"
        return "\(sign)\(whole).\(suffix)"
    }

    private static func same(_ text: String) -> Copy { Copy(text, text) }
}
