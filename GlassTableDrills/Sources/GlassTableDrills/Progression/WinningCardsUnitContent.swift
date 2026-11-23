// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine

enum WinningCardsUnitContent {
    private typealias Copy = TableCourseText

    static func activities(for lesson: TableCourseLesson) -> [TableCourseActivity] {
        switch lesson {
        case .g1:
            [
                outCount("G1-example", Deal("7h8d", "AcAd", "5c6sKs2h"), options: [4, 8, 12], worked: true,
                         reason: Copy("4나 9가 나오면 스트레이트로 이겨요. 이처럼 아직 보이지 않고 내 승리를 만드는 마지막 카드를 아웃이라고 해요.",
                                      "Any four or nine gives you a winning straight. An out here is an unseen last card that makes you win.")),
                winningChoice("G1-01", Deal("6c7s", "QdQh", "4d5hTs2c"), candidates: "Jc8h6h",
                              reason: Copy("8♥로 4부터 8까지 이어져요.", "The 8♥ completes your straight from four to eight.")),
                outCount("G1-02", Deal("AsJd", "QhQs", "2c4d7s9h"), options: [3, 6, 4],
                         reason: Copy("A가 나오면 상대의 Q 페어를 이겨요. A♠는 이미 내 카드예요.",
                                      "An ace beats the opponent's queens. You already hold the A♠.")),
                outCount("G1-03", Deal("QcQd", "KcKs", "3h5d9sTc"), options: [1, 4, 2],
                         reason: Copy("남은 Q 두 장으로 트리플을 만들면 이겨요.", "The two remaining queens both make winning three of a kind.")),
            ]
        case .g2:
            [
                outcome("G2-example", Deal("AhKh", "8c8d", "8h4h2c2s"), river: "Qh", worked: true,
                        reason: Copy("Q♥로 내 플러시가 완성돼요. 상대는 이미 8 세 장과 2 두 장으로 풀하우스를 갖고 있어요.",
                                     "The Q♥ completes your flush. The opponent already has a full house, eights over twos.")),
                outcome("G2-01", Deal("AhKh", "9h9d", "9s3h6h2d"), river: "2h",
                        reason: Copy("내 플러시도 완성되고, 상대는 9 세 장과 2 두 장으로 풀하우스를 만들어요.",
                                     "You make a flush and the opponent makes a full house, nines over twos.")),
                improvingLossChoice("G2-02", Deal("AhQh", "8d8s", "8c3h6hAd"), candidates: "Kh3cJc",
                        reason: Copy("나는 A와 3으로 투페어가 돼요. 상대의 8과 3 풀하우스가 더 강해요.",
                                     "You make two pair, aces and threes. The opponent's full house, eights over threes, is stronger.")),
                outcome("G2-03", Deal("KhTh", "AhAd", "2h7hJc4s"), river: "Qh",
                        reason: Copy("내 하트 플러시가 상대의 A 페어를 이겨요.", "Your heart flush beats the opponent's pair of aces.")),
            ]
        case .g3:
            [
                outCount("G3-example", Deal("5h6h", "AcAs", "3h4c9hKd"), options: [17, 15, 13], worked: true,
                         reason: Copy("플러시를 만드는 하트는 9장, 스트레이트를 만드는 2와 7은 8장이에요. 2♥와 7♥가 양쪽에 있어 각각 한 번씩만 세면 15장이에요.",
                                      "Nine hearts make a flush and eight twos or sevens make a straight. The 2♥ and 7♥ appear in both groups, so count them once each for 15.")),
                outCount("G3-01", Deal("7s8s", "KcKd", "5s6cJs2d"), options: [17, 13, 15],
                         reason: Copy("4♠와 9♠는 각각 스트레이트와 플러시를 모두 만들어요. 두 카드 모두 한 번씩 세세요.",
                                      "The 4♠ and 9♠ each make both a straight and a flush. Count each card once.")),
                availableChoice("G3-02", Deal("9hTh", "QcJh", "7h8c2hAs"), candidates: "6hJh7h"),
                outCount("G3-03", Deal("8c9c", "QcQh", "6c7d2cKs"), options: [14, 16, 15],
                         reason: Copy("상대가 Q♣를 갖고 있어 클럽은 8장 남아요. 5나 10은 8장이고, 5♣와 10♣는 양쪽에 있으니 한 번씩만 세세요.",
                                      "The opponent holds the Q♣, leaving eight clubs. There are eight fives or tens. Count the 5♣ and 10♣ once each.")),
            ]
        case .g4:
            [
                potShare("G4-example", Deal("Ah2d", "As9c", "KdQdJc3s"), worked: true),
                outcome("G4-01", Deal("AhAs", "KcKd", "6d7c8h9s"), river: "5c",
                        reason: Copy("두 사람 모두 공용 카드의 5부터 9까지 써요. 팟을 반씩 나눠요.",
                                     "You both play the board's five-to-nine straight and split the pot.")),
                potShare("G4-02", Deal("7c7s", "AhQd", "9hTdJs8c"), answer: 1,
                         reason: Copy("남은 Q 세 장이 모두 공용 스트레이트를 만들어요.",
                                      "The three remaining queens all make a shared straight.")),
                potShare("G4-03", Deal("7c7s", "9h9s", "6d7d8hTc"), answer: 2,
                         reason: Copy("남은 9 두 장이 모두 공용 스트레이트를 만들어요.",
                                      "The two remaining nines both make a shared straight.")),
            ]
        case .g5:
            [
                winChance("G5-example", Deal("7h8d", "AcAd", "5c6sKs2h", dead: "3cJd"), worked: true,
                          reason: Copy("이미 빠진 3♣와 J♦는 아웃이 아니에요. 둘을 빼도 이기는 카드는 8장이에요. 분모만 44에서 42로 줄어요.",
                                       "The removed 3♣ and J♦ were not outs. Eight winning cards remain, while the denominator drops from 44 to 42.")),
                winChance("G5-01", Deal("5h6h", "AsAd", "3h4c9hKd", dead: "7h"), answer: 1,
                          reason: Copy("7♥는 이미 덱에서 빠졌어요. 리버 후보와 아웃에서 각각 한 장을 빼요.",
                                       "The 7♥ is already out of the deck. Subtract one card from both the winning cards and all possible rivers.")),
                winChance("G5-02", Deal("AsJd", "QhQs", "2c4d7s9h", dead: "AcKs"), answer: 2,
                          reason: Copy("A♣와 K♠ 모두 리버로 나올 수 없어요. 이길 수 있는 A는 두 장 남아요.",
                                       "Neither the A♣ nor the K♠ can be dealt. Two winning aces remain.")),
                winChance("G5-03", Deal("4s5d", "QcQd", "2c3h9cKs"),
                          reason: Copy("내 카드 두 장, 상대 카드 두 장, 공용 카드 네 장만 덱에서 빼요.",
                                       "Remove only your two cards, the opponent's two cards, and the four on the board.")),
            ]
        case .g6:
            [
                rangeShare("G6-example", hero: "KhTh", board: "2h7hJc4s", "AcAd", "8h9h", weights: (1, 1),
                           worked: true, reason: Copy("A 페어를 이기려면 플러시가 필요해요. 낮은 하트 두 장을 상대로는 지금 K 하이로 앞서요. 상대 핸드에 따라 이기는 리버가 달라져요.",
                                                     "You need a flush against aces. Against the lower hearts, your king high is already ahead. The winning rivers depend on which hand they hold.")),
                rangeShare("G6-01", hero: "AhQh", board: "8c3h6hAd", "8d8s", "KdJs", weights: (3, 1), answer: 1),
                rangeShare("G6-02", hero: "5h6h", board: "3h4c9hKd", "AcAs", "AhQh", weights: (1, 1), compare: true,
                           reason: Copy("A♥ Q♥를 상대할 때는 하트가 나와도 상대의 플러시가 더 높아요.",
                                        "Against A♥ Q♥, a heart gives the opponent the higher flush.")),
                rangeShare("G6-03", hero: "As3d", board: "KhQdJc2s", "AcTd", "Ad9c", weights: (1, 3),
                           reason: Copy("무승부도 에퀴티에 들어가요. 핸드별로 내 몫을 계산한 다음 가능성을 반영해요.",
                                        "Ties contribute to equity. Find your share against each hand, then apply the weights.")),
            ]
        case .g7:
            [
                potShare("G7-example", Deal("AhAs", "KcKd", "6d7c8h9s", dead: "5cAd"), showCounts: false, worked: true,
                         reason: Copy("5♣는 무승부를, A♦는 내 승리를 만들 카드였어요. 둘 다 이미 덱에서 빠졌으니 분자와 분모에 넣을 수 없어요.",
                                      "The 5♣ would have tied and the A♦ would have won. Both are already out of the deck, so neither contributes to the numerator or denominator.")),
                winningChoice("G7-01", Deal("7c7s", "9h9s", "6d7d8hTc", dead: "9d"), candidates: "9c7hJc",
                              reason: Copy("7♥가 나오면 7 네 장을 만들어 이겨요. 9♣는 둘 다 같은 스트레이트를 만들고, J♣는 상대가 더 높은 스트레이트를 만들어요.",
                                           "The 7♥ wins with four sevens. The 9♣ makes a shared straight. The J♣ makes a higher straight for the opponent.")),
                winChance("G7-02", Deal("As3d", "Ad9c", "KhQdJc2s", dead: "3c"), answer: 1,
                          reason: Copy("남은 3 두 장으로 이겨요. 18장의 무승부 카드는 이길 확률에 넣지 않아요.",
                                       "Two remaining threes win. The 18 tying cards do not count toward the chance to win outright.")),
                potShare("G7-03", Deal("5d5c", "AsQh", "8h9dTc7s", dead: "6s5s"), answer: 2, showCounts: false,
                         reason: Copy("남은 6 세 장은 공용 스트레이트를 만들어요. 5♠는 이미 덱에서 빠졌어요.",
                                      "The three remaining sixes complete a shared straight. The 5♠ is already out of the deck.")),
            ]
        default:
            []
        }
    }

    static func reviewActivities(for lesson: TableCourseLesson) -> [TableCourseActivity] {
        switch lesson {
        case .g1:
            [
                outCount("G1-review-01", Deal("Ac8d", "JcJd", "2h4s7c9d"), options: [4, 2, 3],
                         reason: Copy("남은 A 세 장이 J 페어를 이기는 페어를 만들어요.",
                                      "The three remaining aces give you a pair that beats jacks.")),
                winningChoice("G1-review-02", Deal("8c8s", "TdTc", "2h6c9sJh"), candidates: "8d7c2s",
                              reason: Copy("8♦가 트리플을 만들어요.", "The 8♦ makes three of a kind.")),
                winningChoice("G1-review-03", Deal("5s6d", "QcQd", "3c4h9cKs"), candidates: "Jh5c2d",
                              reason: Copy("2♦로 2부터 6까지 이어져요.", "The 2♦ completes your straight from two to six.")),
            ]
        case .g2:
            [
                outcome("G2-review-01", Deal("AhKh", "7c7s", "7h3hJcJs"), river: "Qh",
                        reason: Copy("내 플러시보다 상대의 7과 J 풀하우스가 강해요.",
                                     "The opponent's full house, sevens over jacks, beats your flush.")),
                outcome("G2-review-02", Deal("9sTs", "AcAd", "As2s4s7d"), river: "7s",
                        reason: Copy("나는 플러시를 만들고 상대는 A 세 장과 7 두 장으로 풀하우스를 만들어요.",
                                     "You make a flush while the opponent makes a full house, aces over sevens.")),
                outcome("G2-review-03", Deal("AcQc", "7h7s", "7c2c4d9h"), river: "Jc",
                        reason: Copy("리버에서 보드에 페어가 생기지 않았어요. 내 플러시가 상대의 7 트리플을 이겨요.",
                                     "The river leaves the board unpaired. Your flush beats three sevens.")),
            ]
        case .g3:
            [
                availableChoice("G3-review-01", Deal("7s8s", "Ks4s", "5s6cJs2d"), candidates: "4s6c9s"),
                outCount("G3-review-02", Deal("6d7d", "AdAs", "4d5c9dKh"), options: [16, 14, 15],
                         reason: Copy("A♦는 상대에게 있어요. 남은 다이아몬드 8장에 3과 8 여덟 장을 더하고, 겹치는 3♦와 8♦를 한 번씩 빼요.",
                                      "The opponent holds the A♦. Add the eight remaining diamonds to the eight threes or eights, then remove the duplicate 3♦ and 8♦.")),
                outCount("G3-review-03", Deal("3h4h", "AcAd", "2h5c9hQs"), options: [13, 15, 17],
                         reason: Copy("하트 9장에 남은 A 두 장과 6 네 장을 더해 보세요. A♥와 6♥는 하트에 이미 들어 있어요.",
                                      "Start with nine hearts, then add the two remaining aces and four sixes. The A♥ and 6♥ are already among the hearts.")),
            ]
        case .g4:
            [
                potShare("G4-review-01", Deal("As3d", "AcTd", "KhQdJc2s"), answer: 2),
                outcome("G4-review-02", Deal("4d4c", "AsQh", "7h8d9c6s"), river: "5d",
                        reason: Copy("두 사람 모두 5부터 9까지의 공용 스트레이트를 써요.",
                                     "Both players use the shared five-to-nine straight.")),
                potShare("G4-review-03", Deal("AhKd", "AsQd", "TdJhQh2c"), answer: 1),
            ]
        case .g5:
            [
                winChance("G5-review-01", Deal("JcJd", "QcQs", "3d5c9sKh", dead: "Jh"), answer: 2),
                winChance("G5-review-02", Deal("AdTd", "KcKd", "9d3dJh2s", dead: "8dQd"), answer: 1),
                winChance("G5-review-03", Deal("7c8s", "QdQh", "5d6hTs2c", dead: "9c")),
            ]
        case .g6:
            [
                rangeShare("G6-review-01", hero: "7c7s", board: "6d7d8hTc", "9h9s", "AcAd", weights: (1, 1), answer: 1),
                rangeShare("G6-review-02", hero: "6d7d", board: "4d5c9dKh", "AdAs", "KcKs", weights: (2, 1), compare: true),
                rangeShare("G6-review-03", hero: "AcQc", board: "7c2c4d9h", "7h7s", "KhTh", weights: (1, 3)),
            ]
        default:
            []
        }
    }

    private struct Deal {
        let hero: [Card]
        let villain: [Card]
        let board: [Card]
        let dead: [Card]

        init(_ hero: String, _ villain: String, _ board: String, dead: String = "") {
            self.hero = Card.parse(hero)!
            self.villain = Card.parse(villain)!
            self.board = Card.parse(board)!
            self.dead = Card.parse(dead)!
            precondition(self.hero.count == 2 && self.villain.count == 2 && self.board.count == 4)
            precondition(Set(self.hero + self.villain + self.board + self.dead).count == 8 + self.dead.count)
        }

        var legalRivers: [Card] {
            let visible = Set(hero + villain + board + dead)
            return Deck.all.filter { !visible.contains($0) }
        }

        func compare(_ river: Card) -> Int {
            compareHands(hero: hero + board + [river], villain: villain + board + [river])
        }

        private var rows: [TableCourseRow] {
            guard !dead.isEmpty else { return [] }
            return [TableCourseRow(Copy("덱에서 이미 빠진 카드", "Cards already out of the deck"), cardList(dead))]
        }

        func evidence(adding additions: [TableCourseRow] = [], river: Card? = nil) -> TableCourseEvidence {
            .init(cards: hero, board: board + (river.map { [$0] } ?? []), opponent: villain, rows: rows + additions)
        }
    }

    private struct Rivers {
        let wins: [Card]
        let ties: [Card]
        let total: Int

        init(_ deal: Deal) {
            let legal = deal.legalRivers
            var wins: [Card] = [], ties: [Card] = []
            for river in legal {
                switch deal.compare(river) {
                case 0: wins.append(river)
                case 2: ties.append(river)
                default: break
                }
            }
            self.wins = wins
            self.ties = ties
            total = legal.count
        }

        var halfShares: Int { 2 * wins.count + ties.count }
        var equity: Double { Double(halfShares) / Double(2 * total) }
        var share: String { "\(halfUnits(halfShares)) / \(total)" }
    }

    private static func outCount(
        _ id: String, _ deal: Deal, options: [Int], worked: Bool = false, reason: Copy
    ) -> TableCourseActivity {
        let wins = Rivers(deal).wins
        let answer = options.firstIndex(of: wins.count)!
        return activity(id, Copy("이기는 카드 세기", "Count the winning cards"),
                        question: worked ? Copy("어떤 리버가 내 승리를 만드는지 살펴보세요.",
                                                "See which river cards make you win.")
                            : Copy("리버에 나오면 이기는 카드는 몇 장인가요?", "How many river cards make you win?"),
                        evidence: deal.evidence(),
                        reveal: deal.evidence(adding: [TableCourseRow(Copy("이기는 카드", "Winning cards"), cardList(wins))]),
                        options: options.map { same(String($0)) }, answer: answer, reason: reason, worked: worked)
    }

    private static func winningChoice(
        _ id: String, _ deal: Deal, candidates: String, reason: Copy
    ) -> TableCourseActivity {
        let cards = Card.parse(candidates)!
        let legal = deal.legalRivers
        precondition(cards.allSatisfy(legal.contains))
        let winners = cards.indices.filter { deal.compare(cards[$0]) == 0 }
        precondition(winners.count == 1)
        return activity(id, Copy("이기는 리버", "Find the winning river"),
                        question: Copy("어떤 카드가 나오면 내가 이길까요?", "Which of these river cards makes you win?"),
                        evidence: deal.evidence(), reveal: deal.evidence(river: cards[winners[0]]),
                        options: cards.map { cardList([$0]) }, answer: winners[0], reason: reason)
    }

    private static func improvingLossChoice(
        _ id: String, _ deal: Deal, candidates: String, reason: Copy
    ) -> TableCourseActivity {
        let cards = Card.parse(candidates)!
        let legal = deal.legalRivers
        precondition(cards.allSatisfy(legal.contains))
        let currentCategory = bestHandOfAny(deal.hero + deal.board).category
        let losses = cards.indices.filter { index in
            let river = cards[index]
            return deal.compare(river) == 1 && bestHand(deal.hero + deal.board + [river]).category > currentCategory
        }
        precondition(losses.count == 1)
        return activity(id, Copy("핸드가 좋아져도 질 수 있어요", "A stronger hand can still lose"),
                        question: Copy("어떤 카드가 내 핸드를 한 단계 높이지만 상대에게 질까요?",
                                       "Which card improves your hand type but still leaves you behind?"),
                        evidence: deal.evidence(), reveal: deal.evidence(river: cards[losses[0]]),
                        options: cards.map { cardList([$0]) }, answer: losses[0], reason: reason)
    }

    private static func availableChoice(_ id: String, _ deal: Deal, candidates: String) -> TableCourseActivity {
        let cards = Card.parse(candidates)!
        let legal = deal.legalRivers
        let available = cards.indices.filter { legal.contains(cards[$0]) }
        precondition(available.count == 1)
        let river = cards[available[0]]
        let removed = cards.filter { !legal.contains($0) }.map(\.display).joined(separator: ", ")
        return activity(id, Copy("리버로 나올 수 있는 카드", "Which card is still available?"),
                        question: Copy("이 중 아직 보이지 않아서 리버로 나올 수 있는 카드는 무엇인가요?",
                                       "Which of these cards is still unseen and can be the river?"),
                        evidence: deal.evidence(), reveal: deal.evidence(river: river),
                        options: cards.map { cardList([$0]) }, answer: available[0],
                        reason: Copy("\(removed) 두 장은 이미 보이므로 리버로 나올 수 없어요.",
                                     "The \(removed) are already visible, so neither can be dealt as the river."))
    }

    private static func outcome(
        _ id: String, _ deal: Deal, river token: String, worked: Bool = false, reason: Copy
    ) -> TableCourseActivity {
        let river = Card(token)!
        precondition(deal.legalRivers.contains(river))
        let result = deal.compare(river)
        let options = [Copy("내가 이겨요", "I win"), Copy("상대가 이겨요", "The opponent wins"), Copy("무승부예요", "It's a tie")]
        let candidate = TableCourseRow(Copy("뒤집어 볼 리버", "River to try"), cardList([river]))
        let resultRow = TableCourseRow(Copy("결과", "Result"), options[result])
        return activity(id, Copy("리버가 바꾸는 결과", "What does the river change?"),
                        question: worked ? Copy("리버가 나온 뒤 두 사람의 핸드를 비교해 보세요.",
                                                "Compare both hands after the river arrives.")
                            : Copy("이 카드가 리버에 나오면 누가 이길까요?", "If this card comes on the river, who wins?"),
                        evidence: deal.evidence(adding: [candidate]),
                        reveal: deal.evidence(adding: [resultRow], river: river),
                        options: options, answer: result, reason: reason, worked: worked)
    }

    private static func potShare(
        _ id: String, _ deal: Deal, answer: Int = 0, showCounts: Bool = true, worked: Bool = false, reason: Copy? = nil
    ) -> TableCourseActivity {
        let rivers = Rivers(deal)
        let wins = rivers.wins.count, ties = rivers.ties.count, total = rivers.total
        precondition(ties > 0)
        let rules = Copy("에퀴티는 이런 상황을 여러 번 반복했을 때 평균적으로 받는 팟의 몫이에요. 승리는 팟 전체, 두 사람의 무승부는 팟 절반을 가져가요.",
                         "Equity is the average share of the pot you would receive if you played the same spot many times. A win takes the whole pot, and a two-player tie takes half.")
        let following = Copy("이 팟에서 평균적으로 받는 몫(에퀴티)은 얼마인가요?",
                             "What is your average share of the pot (equity)?")
        let arithmetic = "(\(wins) + \(ties) ÷ 2) / \(total) = \(rivers.share)"
        let detail = TableCourseRow(Copy("평균 팟 몫 (에퀴티)", "Average pot share (equity)"),
                                    same(arithmetic))
        let counts = [
            TableCourseRow(Copy("이기는 카드", "Winning rivers"), same("\(wins) / \(total)")),
            TableCourseRow(Copy("무승부가 되는 카드", "Tying rivers"), same("\(ties) / \(total)")),
        ]
        let reveal = deal.evidence(adding: counts + [
            TableCourseRow(Copy("무승부를 만드는 리버", "Rivers that tie"), cardList(rivers.ties)), detail,
        ])
        return activity(id, Copy("무승부는 팟의 절반", "A tie is half the pot"),
                        question: worked ? rules : following,
                        evidence: deal.evidence(adding: showCounts ? counts : []), reveal: reveal,
                        options: positioned(rivers.share, alternatives: ["\(wins) / \(total)", "\(wins + ties) / \(total)"], at: answer),
                        answer: answer,
                        reason: reason ?? Copy("이기는 카드마다 1, 무승부 카드마다 0.5를 더한 뒤 리버 후보 수로 나눠요.",
                                               "Count 1 for each win and 0.5 for each tie, then divide by the number of possible rivers."),
                        worked: worked)
    }

    private static func winChance(
        _ id: String, _ deal: Deal, answer: Int = 0, worked: Bool = false, reason: Copy? = nil
    ) -> TableCourseActivity {
        let rivers = Rivers(deal)
        let winning = rivers.wins.count, total = rivers.total
        let shown = 52 - total
        let originalWins = countOuts(hero: deal.hero, villain: deal.villain, board: deal.board).count
        // A visible opponent's two cards are excluded even when there are no extra exposures.
        let wrongCount = originalWins == winning ? winning + 1 : originalWins
        let wrongTotal = total == 44 ? 46 : 44
        return activity(id, Copy("남은 카드 중 몇 장?", "Wins out of the cards left"),
                        question: worked ? Copy("이기는 카드와 리버 후보를 각각 세어 보세요.",
                                                "Count the winning cards and the possible rivers.")
                            : Copy("리버 한 장으로 이길 확률을 분수로 나타내 보세요.",
                                   "Which fraction is your chance to win on the river?"),
                        evidence: deal.evidence(),
                        reveal: deal.evidence(adding: [
                            TableCourseRow(Copy("리버 후보", "Possible rivers"), same("52 − \(shown) = \(total)")),
                            TableCourseRow(Copy("이기는 카드", "Winning cards"), cardList(rivers.wins)),
                            TableCourseRow(Copy("이길 확률", "Chance of winning"), same("\(winning) / \(total)")),
                        ]),
                        options: positioned("\(winning) / \(total)",
                                            alternatives: ["\(winning) / \(wrongTotal)", "\(wrongCount) / \(total)"], at: answer),
                        answer: answer,
                        reason: reason ?? Copy("이기는 카드 수를 리버로 나올 수 있는 카드의 수로 나눠요.",
                                               "Divide winning cards by all cards that could come on the river."),
                        worked: worked)
    }

    private static func rangeShare(
        _ id: String, hero: String, board: String, _ first: String, _ second: String,
        weights: (Int, Int), answer: Int = 0, compare: Bool = false, worked: Bool = false, reason: Copy? = nil
    ) -> TableCourseActivity {
        let a = Deal(hero, first, board), b = Deal(hero, second, board)
        let aRivers = Rivers(a), bRivers = Rivers(b)
        let (aw, bw) = weights
        let allWeights = aw + bw
        let combined = (Double(aw) * aRivers.equity + Double(bw) * bRivers.equity) / Double(allWeights)
        let firstLabel = Copy("상대 핸드 A", "Opponent hand A")
        let secondLabel = Copy("상대 핸드 B", "Opponent hand B")

        func possibleHand(_ label: Copy, _ cards: [Card], _ weight: Int) -> TableCourseRow {
            let names = cards.map(\.display).joined(separator: " ")
            return TableCourseRow(label, same("\(names) · \(weight) / \(allWeights)"))
        }

        func outcomes(_ label: Copy, _ rivers: Rivers) -> TableCourseRow {
            TableCourseRow(label,
                           Copy("리버 후보 \(rivers.total)장 · 승리 \(rivers.wins.count)장 · 무승부 \(rivers.ties.count)장 · 내 몫 \(rivers.share)",
                                "\(rivers.total) legal rivers · \(rivers.wins.count) wins · \(rivers.ties.count) ties · share \(rivers.share)"))
        }
        let rows = [possibleHand(firstLabel, a.villain, aw), possibleHand(secondLabel, b.villain, bw)]
        let calculation = "[(\(aRivers.share)) × \(aw) + (\(bRivers.share)) × \(bw)] ÷ \(allWeights) ≈ \(percent(combined))"
        let conditional = [
            outcomes(Copy("A일 때", "Against A"), aRivers),
            outcomes(Copy("B일 때", "Against B"), bRivers),
        ]
        let prompt: Copy
        let choices: [Copy]
        let correct: Int
        if worked {
            prompt = Copy("아래 두 상대 핸드의 가능성은 같아요. 각 핸드에서 받는 팟 몫을 구해 평균을 내요.",
                          "Both hands are equally likely.\nAverage your pot shares.")
            choices = []
            correct = 0
        } else if compare {
            prompt = Copy("상대가 어떤 핸드를 가졌을 때 내 에퀴티가 더 높을까요?",
                          "Which opponent hand gives you more equity?")
            choices = [Copy("핸드 A", "Hand A"), Copy("핸드 B", "Hand B"), Copy("둘이 같아요", "Same against both")]
            correct = aRivers.equity == bRivers.equity ? 2 : (aRivers.equity > bRivers.equity ? 0 : 1)
        } else {
            prompt = Copy("상대가 각 핸드를 갖고 있을 확률이 옆에 있어요. 두 확률을 반영하면 내 에퀴티는 약 얼마인가요?",
                          "Each opponent hand has its chance next to it. Taking both chances into account, about how much equity do you have?")
            choices = positioned(percent(combined), alternatives: [percent(aRivers.equity), percent(bRivers.equity)], at: answer)
            correct = answer
        }
        let reveal = rows + conditional + [
            TableCourseRow(Copy("레인지 상대 에퀴티", "Equity against the range"), same(calculation)),
        ]
        return activity(id, Copy("상대 핸드가 두 가지라면", "Two possible hands"),
                        question: prompt,
                        evidence: .init(cards: a.hero, board: a.board, rows: compare ? rows : rows + conditional),
                        reveal: .init(cards: a.hero, board: a.board, rows: reveal),
                        options: choices, answer: correct,
                        reason: reason ?? Copy("상대 핸드별로 내 평균 팟 몫을 구해요. 각각 상대가 그 핸드를 갖고 있을 확률을 곱한 뒤 더해요.",
                                               "Find your average pot share against each possible hand. Multiply each share by that hand's chance, then add the results."),
                        worked: worked)
    }

    private static func activity(
        _ id: String, _ title: Copy, question: Copy, evidence: TableCourseEvidence, reveal: TableCourseEvidence,
        options: [Copy], answer: Int, reason: Copy, worked: Bool = false
    ) -> TableCourseActivity {
        .init(id: id, title: title, prompt: question, evidence: worked ? reveal : evidence,
              choices: worked ? [] : options, correctChoice: worked ? nil : answer,
              explanation: Copy(textSuits(reason.text(in: .korean)), textSuits(reason.text(in: .english))),
              revealedEvidence: worked ? nil : reveal)
    }

    private static func positioned(_ correct: String, alternatives: [String], at index: Int) -> [Copy] {
        var choices = alternatives
        choices.insert(correct, at: index)
        return choices.map(same)
    }

    private static func halfUnits(_ halves: Int) -> String {
        halves.isMultiple(of: 2) ? String(halves / 2) : "\(halves / 2).5"
    }

    private static func percent(_ share: Double) -> String {
        String(format: "%.1f%%", locale: Locale(identifier: "en_US_POSIX"), share * 100)
    }

    private static func cardList(_ cards: [Card]) -> Copy {
        same(cards.map(\.display).joined(separator: " "))
    }

    private static func same(_ value: String) -> Copy {
        let text = textSuits(value)
        return Copy(text, text)
    }

    private static func textSuits(_ value: String) -> String {
        value.map { "♣♦♥♠".contains($0) ? "\($0)\u{FE0E}" : String($0) }.joined()
    }
}
