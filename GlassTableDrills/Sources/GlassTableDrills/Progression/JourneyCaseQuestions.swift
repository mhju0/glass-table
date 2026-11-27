// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

extension JourneyCaseContent {
    static func worked(_ id: String, _ deal: Deal) -> TableCourseActivity {
        MasteryCourseContent.scenario(id, Copy("플랍까지 낸 칩 따라가기", "Trace the chips through the flop"),
            deal.streets, [], answer: 0,
            Copy("두 사람의 프리플랍 납입액에 폴드한 스몰 블라인드 1을 더해요. 플랍에 벳과 콜이 있었다면 그 두 금액도 더해요.",
                 "Add the two preflop totals and the folded small blind’s 1. If the flop was bet and called, add those two contributions."),
            evidence: deal.evidence(3, rows: deal.potHistory), example: true)
    }

    static func early(_ id: String, _ deal: Deal) -> TableCourseActivity {
        switch deal.task {
        case .position:
            return MasteryCourseContent.scenario(id, Copy("플랍 이후 누가 나중에 행동할까요?", "Who acts last after the flop?"),
                Copy("1/2 블라인드에서 버튼이 \(deal.open)으로 오픈했고 빅 블라인드만 콜했어요. 플랍에서 내 차례는 상대보다 빠를까요, 늦을까요?",
                     "At 1/2 the button opened to \(deal.open), and only the big blind called. On the flop, do you act before or after your opponent?"),
                [Copy("상대보다 먼저", "Before your opponent"), Copy("상대보다 나중에", "After your opponent"),
                 Copy("플랍 무늬에 따라 달라요", "It depends on the flop suits")],
                answer: deal.onButton ? 1 : 0,
                Copy("둘이 남으면 버튼 앞에 있는 빅 블라인드가 먼저예요. 새 공용 카드는 차례를 바꾸지 않아요.",
                     "The big blind acts first and the button acts second. Community cards do not change the order."), evidence: deal.evidence(0))
        case .match:
            let cost = deal.open - 2
            let options = [deal.open, 2, cost].map { same("\($0)") }
            return MasteryCourseContent.scenario(id, Copy("빅 블라인드의 콜 금액", "Price the big blind’s call"),
                Copy("블라인드는 1/2예요. 버튼이 \(deal.open)으로 오픈했고 다른 사람은 폴드했어요. 빅 블라인드가 콜에 더 내야 할 칩은?",
                     "Blinds are 1/2. The button opened to \(deal.open) and everyone else folded to the big blind. How many more chips must the big blind put in to call?"),
                options, answer: 2,
                Copy("총 \(deal.open)에 맞춰요. 이미 낸 빅 블라인드 2를 빼면 \(cost)이에요.",
                     "Match the total of \(deal.open). Subtract the big blind’s 2 already posted, leaving \(cost)."),
                evidence: deal.evidence(0))
        case .legal:
            return MasteryCourseContent.scenario(id, Copy("합법적인 오픈 총액", "Recognize a legal opening raise"),
                Copy("1/2 블라인드에서 아무도 레이즈하지 않았어요. 버튼은 선택지에 나온 금액을 모두 낼 수 있어요. 아래 총액 중 합법적인 일반 레이즈는?",
                     "Play is 1/2 and nobody has raised. The button has enough chips for every listed total. Which total is a legal full opening raise?"),
                [same("\(deal.open)"), same("3"), same("2")], answer: 0,
                Copy("최소 레이즈는 빅 블라인드 2만큼 더해 총 4예요. \(deal.open)은 4 이상이에요. 합법 여부만 판단해요.",
                     "A full raise adds at least the big blind of 2, so the minimum total is 4. The total of \(deal.open) is legal. This checks legality."),
                evidence: deal.evidence(0))
        }
    }

    static func range(_ id: String, _ deal: Deal) -> TableCourseActivity {
        if deal.open >= 7 && !id.hasPrefix("JR-") {
            return filterRange(id, deal)
        }
        let possible = MasteryCourseContent.cardNames(deal.opponent)
        let blockedByFlop = MasteryCourseContent.cardNames([deal.opponent[0], deal.flop[1]])
        let blockedByHero = MasteryCourseContent.cardNames([deal.hero[0], deal.opponent[1]])
        let options = arranged([same(possible), same(blockedByFlop), same(blockedByHero)], rotate: deal.open % 3)
        return MasteryCourseContent.scenario(id, Copy("상대 레인지에서 가능한 조합", "Which candidate can remain in the range?"),
            Copy("플랍에서 상대 패는 아직 몰라요. 아래 후보 중 보이는 카드와 겹치지 않는 조합은?",
                 "You have not seen the other player’s hand on the flop. Which candidate contains no visible card?"),
            options.values, answer: options.firstIndex,
            Copy("플랍과 내 카드에 이미 있는 카드는 상대가 들 수 없어요. 남은 후보는 가능한 예일 뿐, 상대 패가 확정된 것은 아니에요.",
                 "A card on the flop or in your hand cannot be in the opponent’s hand. The remaining candidate is one possibility."),
            evidence: deal.evidence(3))
    }

    private static func filterRange(_ id: String, _ deal: Deal) -> TableCourseActivity {
        let visible = Set(deal.hero + deal.flop)
        let unseen = Deck.all.filter { !visible.contains($0) }
        let possible = unseen.indices.dropLast().lazy.flatMap { first in
            unseen[(first + 1)...].lazy.map { [unseen[first], $0] }
        }
        // Choose a real pair and a high-card hand. Neither is presented as the
        // actual opponent holding. The exercise filters a declared call range.
        guard let made = possible.first(where: { bestHandOfAny($0 + deal.flop).category == 1 }),
              let high = possible.first(where: { bestHandOfAny($0 + deal.flop).category == 0 }) else {
            preconditionFailure("This flop requires both a pair and a high-card candidate")
        }
        let blocked = [deal.flop[0], made[1]]
        let candidates = [made, high, blocked].map { same(MasteryCourseContent.cardNames($0)) }
        let options = arranged(candidates, rotate: deal.open % 3)
        return MasteryCourseContent.scenario(id, Copy("플랍 콜 뒤에 남을 레인지", "Which holding can survive the flop call?"),
            Copy("별도의 플랍 상황을 가정해요. 상대는 원 페어 이상일 때만 콜하는 규칙을 쓰고 방금 콜했어요. 이 보드에서 규칙과 보이는 카드에 모두 맞는 후보는?",
                 "Consider a separate flop scenario. Your opponent calls only with one pair or better and just called. Which candidate fits both the policy and the visible cards?"),
            options.values, answer: options.firstIndex,
            Copy("가능한 후보 두 개를 공용 카드와 합쳐 보면 하나는 원 페어, 하나는 하이 카드예요. 공용 카드와 겹친 후보는 처음부터 나올 수 없어요.",
                 "Combine each physically possible candidate with the flop. One makes a pair, and the other is only high card. The candidate containing a board card is already impossible."),
            evidence: deal.evidence(3))
    }

    static func boardChange(_ id: String, _ deal: Deal) -> TableCourseActivity {
        let turn = deal.turn[3]
        let pairs = deal.flop.contains { $0.rank == turn.rank }
        let flush = deal.turn.filter { $0.suit == turn.suit }.count >= 3
        let answer = (pairs ? 1 : 0) + (flush ? 2 : 0)
        return MasteryCourseContent.scenario(id, Copy("턴 카드로 바뀐 보드", "What the turn changes"),
            Copy("오른쪽 끝 카드가 턴이에요. 이 카드가 보드를 페어로 만들었는지, 이 무늬가 보드에 세 장 이상이 됐는지 확인해요.",
                 "The rightmost card is the turn. Check whether it pairs the flop and whether its suit now appears at least three times on board."),
            [Copy("둘 다 해당 없어요", "Neither condition holds"),
             Copy("보드 페어만 만들어요", "It only pairs the flop"),
             Copy("이 무늬만 보드에 세 장 이상이에요", "Only its suit reaches three or more"),
             Copy("두 가지 모두 해당해요", "Both conditions hold")], answer: answer,
            Copy("턴 카드와 같은 랭크가 플랍에 있는지 확인해요. 턴 카드와 같은 무늬는 턴을 포함해 \(deal.turn.filter { $0.suit == turn.suit }.count)장이에요. 가능한 패는 이 정보로 바뀌어요.",
                 "Compare the turn rank with the flop ranks. There are \(deal.turn.filter { $0.suit == turn.suit }.count) board cards of the turn suit, counting the turn. That changes which hands are possible."),
            evidence: deal.evidence(4))
    }

    static func price(_ id: String, _ deal: Deal) -> TableCourseActivity {
        let options = arranged([same("\(deal.shove) ÷ \(deal.finalPot)"),
                                same("\(deal.shove) ÷ \(deal.turnPot + deal.shove)"),
                                same("\(deal.shove) ÷ \(deal.turnPot)")], rotate: deal.open % 3)
        let context = deal.streets
        return MasteryCourseContent.scenario(id, Copy("턴 콜의 본전 기준", "Set the break-even price on the turn"),
            Copy("\(context.text(in: .korean)) \(deal.turnOpening.text(in: .korean)) 내 스택은 콜할 만큼 있고 앤티와 수수료는 없어요. 콜이 본전이려면 어떤 팟 몫이 필요할까요?",
                 "\(context.text(in: .english)) \(deal.turnOpening.text(in: .english)) You cover. There are no antes or fees. What share of the final pot breaks even?"),
            options.values, answer: options.firstIndex,
            Copy("턴 시작 팟에 상대의 올인과 내 콜을 모두 더해요. 내가 더 내는 칩을 그 최종 팟으로 나눠요.",
                 "Add the shove and your match to the turn-start pot. Divide the extra chips you pay by that final pot."),
            evidence: deal.evidence(4), reveal: deal.potHistory + [
                Row(Copy("콜한 뒤 팟", "Pot after a call"), same("\(deal.turnPot) + \(deal.shove) + \(deal.shove) = \(deal.finalPot)")),
            ])
    }

    static func decision(_ id: String, _ deal: Deal) -> TableCourseActivity {
        let visible = Set(deal.hero + deal.opponent + deal.turn)
        let rivers = Deck.all.filter { !visible.contains($0) }
        let outcomes = rivers.map { compareHands(hero: deal.hero + deal.turn + [$0], villain: deal.opponent + deal.turn + [$0]) }
        let wins = outcomes.count { $0 == 0 }, ties = outcomes.count { $0 == 2 }
        let comparison = (2 * wins + ties) * deal.finalPot - 2 * deal.shove * rivers.count
        let best = comparison > 0 ? 0 : comparison < 0 ? 1 : 2
        return MasteryCourseContent.scenario(id, Copy("가능한 리버를 모두 고려한 결정", "Decide across all possible rivers"),
            Copy("턴에 둘만 남았고 팟은 \(deal.turnPot)이에요. \(deal.turnOpening.text(in: .korean)) 내 스택은 콜할 만큼 있어요. 상대 패는 연습용 가정이에요. 콜하면 리버 한 장을 배분한 뒤 추가 베팅 없이 쇼다운해요. 수수료가 없을 때 어느 선택의 EV가 높을까요?",
                 "Two players reach the turn with \(deal.turnPot) in the pot. \(deal.turnOpening.text(in: .english)) You cover. Treat the shown opponent hand as an assumption. A call deals one river before showdown, with no more betting or fees. Which choice has higher EV?"),
            [Copy("콜", "Call"), Copy("폴드", "Fold"), Copy("둘 다 같아요", "Same EV")], answer: best,
            Copy("이기는 리버는 팟 전부, 비기는 리버는 절반을 받아요. 가능한 리버의 평균 팟 몫과 콜의 본전 기준을 비교해요.",
                 "A win pays the whole pot and a tie pays half. Compare average share over the possible rivers with the break-even price."),
            evidence: deal.evidence(4, showOpponent: true), reveal: [
                Row(Copy("이기는 리버 · 비기는 리버", "Winning rivers · tying rivers"), same("\(wins) · \(ties)")),
                Row(Copy("평균 팟 몫", "Expected share"), same("(\(wins) + \(ties) ÷ 2) ÷ \(rivers.count)")),
                Row(Copy("본전에 필요한 팟 몫", "Break-even share"), same("\(deal.shove) ÷ \(deal.finalPot)")),
            ])
    }

    static func showdown(_ id: String, _ deal: Deal) -> TableCourseActivity {
        let a = bestFiveCards(deal.hero + deal.board), b = bestFiveCards(deal.opponent + deal.board)
        return MasteryCourseContent.scenario(id, Copy("이 리버의 쇼다운", "Showdown on this river"),
            Copy("이 리버는 두 사람이 쇼다운에 갔다고 가정한 결과예요. 각자 가장 강한 다섯 장을 비교해요. 이 리버 한 장의 팟은 누가 가져갈까요?",
                 "This is the runout if both players went to showdown. Compare each player’s strongest five. Who gets the pot on this particular river?"),
            [Copy("내가 이겨요", "You win"), Copy("상대가 이겨요", "Opponent wins"), Copy("팟을 나눠요", "Split the pot")],
            answer: compareHands(hero: a, villain: b),
            Copy("가장 강한 다섯 장이 승부를 정해요. 이 결과는 턴에서 콜이나 폴드의 평균 손익을 바꾸지 않아요.",
                 "The strongest five decide this result. One runout does not change the earlier average value of calling or folding."),
            evidence: deal.evidence(5, showOpponent: true), reveal: [
                Row(Copy("내 베스트 파이브", "Your best five"), same(MasteryCourseContent.cardNames(a))),
                Row(Copy("상대 베스트 파이브", "Opponent’s best five"), same(MasteryCourseContent.cardNames(b))),
            ])
    }

    private static func arranged(_ options: [Copy], rotate: Int) -> (values: [Copy], firstIndex: Int) {
        let values = Array(options[rotate...]) + Array(options[..<rotate])
        return (values, (options.count - rotate) % options.count)
    }
}
