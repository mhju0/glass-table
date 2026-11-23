// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

enum PossibleHandsUnitContent {
    private typealias Copy = TableCourseText

    static func activities(for lesson: TableCourseLesson) -> [TableCourseActivity] {
        switch lesson {
        case .f1:
            [
                certainty("F1-example", "AsJd", "Qh8c3s", "QcTd", worked: true),
                certainty("F1-01", "Kh9d", "Ks7h2c", "KcTc"),
                certainty("F1-02", "Ah8s", "Jc6d2h", "Js9d", shown: "Js9d"),
                certainty("F1-03", "8h7h", "Tc9c4d", "TdKs"),
                certainty("F1-04", "Qc4c", "Ad9s5h", "AsTd", shown: "AcTc"),
            ]
        case .f2:
            [
                removal("F2-example", "Ah8d", "Ks7h2c", ["AhQc", "KsKd", "AsQd"], worked: true),
                removal("F2-01", "Jh9s", "Td6c3d", ["Jd9c", "JhTc", "3d3h"]),
                removal("F2-02", "Ad2h", "Qc8s5c", ["Ad4d", "Ac2d", "8s8h"]),
                removal("F2-03", "7c6c", "As9h4d", ["AsAh", "7c7s", "Ac9s"]),
                removal("F2-04", "KdKh", "Ts8d3h", ["Jc9c", "QdKd", "8d8s"]),
            ]
        case .f3:
            [
                madeOrDraw("F3-example", "Ah9c", "Ad7s3d", worked: true),
                madeOrDraw("F3-01", "KhQh", "9h5h2c"),
                madeOrDraw("F3-02", "JsTs", "Jh8s4s"),
                madeOrDraw("F3-03", "8d7c", "6s5d4h"),
                madeOrDraw("F3-04", "QcKd", "Qd8c3h"),
            ]
        case .f4:
            [
                readFlop("F4-example", "8h7h6h", compare: "Ks8c2d"),
                readFlop("F4-01", "Kh7h2h"),
                readFlop("F4-02", "Jc6d2s"),
                readFlop("F4-03", "8c7d6c"),
                readFlop("F4-04", "Th9h7h"),
            ]
        case .f5:
            [
                readAction("F5-example", "4d2c", "Kh9c5s", ["Kc9d", "AhQh", "5cJd"], .bet, worked: true),
                readAction("F5-01", "Ac3c", "Qs8h4d", ["QcJc", "8c8d", "4sTd"], .bet),
                readAction("F5-02", "AdKc", "Js9h7d", ["Jc9c", "Th8h", "AhQh"], .check),
                readAction("F5-03", "Ac5c", "9s8s7s", ["QhJc", "KsTs", "9h9d"], .check),
                readAction("F5-04", "Qc3h", "AcTc2c", ["AdKh", "As2h", "Jc9d"], .bet),
            ]
        case .f6:
            [
                readAction("F6-example", "5h2c", "QhJhTh", ["AhKh", "9c8d", "Qc7s"], .bet,
                           checkpoint: true, worked: true),
                readAction("F6-01", "Qd2s", "Qc8d4h", ["Qs8s", "Qd4s", "4c4d"], .bet, checkpoint: true),
                readAction("F6-02", "Ad2h", "9s7s5h", ["8c6c", "9cKc", "KsQs"], .check, checkpoint: true),
                readAction("F6-03", "Ah3d", "8c7c6c", ["Tc9c", "8d6h", "QcJd"], .bet, checkpoint: true),
                readAction("F6-04", "Kd2s", "AhJd4c", ["AsTs", "Kh4c", "QhTh"], .check, checkpoint: true),
            ]
        default:
            []
        }
    }

    static func reviewActivities(for lesson: TableCourseLesson) -> [TableCourseActivity] {
        switch lesson {
        case .f1:
            [
                certainty("F1-review-01", "9d6s", "Ac8c3h", "As8d"),
                certainty("F1-review-02", "Ts9c", "KhJd5s", "Kc2h", shown: "Kd2h"),
                certainty("F1-review-03", "Qh3c", "7s5d2c", "6h4s", shown: "4s6h"),
            ]
        case .f2:
            [
                removal("F2-review-01", "5s4d", "Jd8h6c", ["5s5d", "8h8d", "7c5h"]),
                removal("F2-review-02", "KsTc", "AhQd2s", ["AsQs", "TcTs", "2s2d"]),
                removal("F2-review-03", "QhJc", "9d7s3h", ["9s9d", "9h7d", "QcJc"]),
            ]
        case .f3:
            [
                madeOrDraw("F3-review-01", "Ad5h", "4s3d2c"),
                madeOrDraw("F3-review-02", "9h8d", "Th7s2d"),
                madeOrDraw("F3-review-03", "KcJc", "Kd7c4c"),
            ]
        case .f4:
            [
                readFlop("F4-review-01", "QcJh9d"),
                readFlop("F4-review-02", "As9s4s"),
                readFlop("F4-review-03", "KcJh4h"),
            ]
        case .f5:
            [
                readAction("F5-review-01", "Ks2d", "8s6d3c", ["6s8c", "6c6h", "Ah8d"], .check),
                readAction("F5-review-02", "Jd2s", "6h5h3c", ["7d4c", "AhQh", "5c9c"], .bet),
                readAction("F5-review-03", "9s8h", "AsKd5d", ["AhQs", "Ac5c", "QdJd"], .bet),
            ]
        default:
            []
        }
    }

    private static func certainty(
        _ id: String, _ deal: String, _ flop: String, _ candidate: String, shown: String? = nil,
        worked: Bool = false
    ) -> TableCourseActivity {
        let cards = Card.parse(deal)!
        let board = Card.parse(flop)!
        let guess = Card.parse(candidate)!
        let shownCards = shown.map { Card.parse($0)! }
        var rows = [
            TableCourseRow(Copy("상대 카드", "Opponent’s cards"),
                           shownCards.map(cardCopy) ?? Copy("아직 뒷면", "Still face down")),
            TableCourseRow(Copy("생각해 볼 조합", "One guess"), cardCopy(guess)),
        ]
        let answer: Int
        let reason: Copy
        if let shownCards {
            if Set(shownCards) == Set(guess) {
                answer = 0
                reason = Copy("상대가 카드를 뒤집어서 숫자와 무늬를 확인했어요.",
                              "The opponent turned over both cards, so you can verify the ranks and suits.")
            } else {
                answer = 2
                reason = Copy("상대가 보여 준 카드 두 장을 후보와 비교하면 서로 달라요.",
                              "Compare the two cards the opponent showed with the guess. They differ.")
            }
        } else {
            answer = 1
            reason = Copy("내 카드와 공용 카드는 확인할 수 있어요. 상대 카드가 뒷면이라 이 조합은 가능한 후보 중 하나예요.",
                          "Your cards and the shared cards are known. With the opponent’s cards face down, the guess is one possibility.")
        }

        if worked {
            rows.append(TableCourseRow(Copy("확실히 아는 카드", "What you know"),
                                       Copy("내 카드 두 장과 공용 카드 세 장", "Your two cards and the three shared cards")))
        }
        return activity(
            id, Copy("보이는 카드와 후보", "Visible cards and guesses"),
            Copy("이 후보가 상대의 실제 카드일까요?", "What can you tell about this guess?"),
            evidence: .init(cards: cards, board: board, rows: rows),
            choices: [
                Copy("보여 준 카드와 같아요", "It matches the cards they showed"),
                Copy("가능하지만 아직 몰라요", "It’s possible, but still unknown"),
                Copy("보여 준 카드와 달라요", "It differs from the cards they showed"),
            ],
            answer: answer, reason: reason, worked: worked
        )
    }

    private static func removal(
        _ id: String, _ deal: String, _ flop: String, _ guesses: [String], worked: Bool = false
    ) -> TableCourseActivity {
        let cards = Card.parse(deal)!
        let board = Card.parse(flop)!
        let visible = Set(cards + board)
        let candidates = guesses.map { Card.parse($0)! }
        let overlaps = candidates.map { hand in hand.filter { visible.contains($0) } }
        let available = overlaps.indices.filter { overlaps[$0].isEmpty }
        precondition(available.count == 1)
        let answer = available[0]
        let removed = cardText(overlaps.flatMap { $0 })
        let remaining = cardText(candidates[answer])
        let reason = Copy(
            "\(removed) 모두 내 카드나 공용 카드에 이미 나와 있어요. \(remaining) 두 장은 아직 보이지 않아요.",
            "\(removed) are already visible in your cards or the shared cards. Both cards in \(remaining) are still unseen."
        )
        let rows = worked
            ? [TableCourseRow(Copy("처음 후보", "Starting guesses"),
                              cardListCopy(candidates))]
            : []
        return activity(
            id, Copy("이미 나온 카드 빼기", "Rule out visible cards"),
            Copy("상대가 실제로 들 수 있는 조합은 무엇일까요?", "Which two cards could the opponent actually hold?"),
            evidence: .init(cards: cards, board: board, rows: rows),
            choices: candidates.map(cardCopy), answer: answer, reason: reason, worked: worked
        )
    }

    private static func madeOrDraw(
        _ id: String, _ deal: String, _ flop: String, worked: Bool = false
    ) -> TableCourseActivity {
        let cards = Card.parse(deal)!
        let board = Card.parse(flop)!
        let all = cards + board
        let hand = bestHandOfAny(all)
        let flushDraw = hasFlushDraw(all)
        let straightDraw = !straightCompletingRanks(all).isEmpty
        let hasDraw = flushDraw || straightDraw
        let answer: Int
        let reason: Copy
        if [4, 5, 8].contains(hand.category) {
            answer = 3
            reason = hand.category == 4
                ? Copy("지금 카드 다섯 장의 숫자가 이어져요. 스트레이트가 이미 완성됐어요.",
                       "Five ranks already run in order. You have a straight right now.")
                : Copy("지금 카드 다섯 장의 무늬가 같아요. 플러시가 이미 완성됐어요.",
                       "Five cards already share a suit. You have a flush right now.")
        } else if hand.category == 1 && hasDraw {
            answer = 2
            reason = flushDraw
                ? Copy("같은 숫자 두 장으로 원 페어가 이미 있어요. 같은 무늬 카드가 한 장 더 나오면 플러시도 만들 수 있어요.",
                       "Two matching ranks already make a pair. One more card of the matching suit could make a flush.")
                : Copy("원 페어가 이미 있어요. 알맞은 카드가 한 장 더 나오면 스트레이트도 만들 수 있어요.",
                       "You already have a pair. The right next card could make a straight as well.")
        } else if hand.category == 1 {
            answer = 0
            reason = Copy("내 카드 한 장이 공용 카드의 가장 높은 숫자와 같아서 탑 페어예요. 다음 카드를 기다리지 않아도 이미 원 페어가 있어요.",
                          "One of your cards matches the highest shared rank. That top pair is already there.")
        } else {
            precondition(hand.category == 0 && hasDraw)
            answer = 1
            reason = flushDraw
                ? Copy("같은 무늬가 네 장이에요. 같은 무늬가 한 장 더 나오면 플러시가 돼요.",
                       "Four cards share a suit. A fifth card of that suit would make a flush.")
                : Copy("알맞은 카드 한 장이 더 나오면 다섯 숫자가 이어져 스트레이트가 돼요.",
                       "The right next card would give you five ranks in a row and make a straight.")
        }

        return activity(
            id, Copy("이미 있는 핸드와 드로우", "Made hands and draws"),
            Copy("다음 공용 카드가 나오기 전, 지금 카드는 어떤 상태일까요?",
                 "What do you have before the next shared card arrives?"),
            evidence: .init(cards: cards, board: board),
            choices: [
                Copy("원 페어만", "A pair only"),
                Copy("드로우만", "A draw only"),
                Copy("원 페어와 드로우", "A pair and a draw"),
                Copy("스트레이트 또는 플러시 완성", "A made straight or flush"),
            ],
            answer: answer, reason: reason, worked: worked
        )
    }

    private static func readFlop(_ id: String, _ flop: String, compare: String? = nil) -> TableCourseActivity {
        let board = Card.parse(flop)!
        let texture = boardTexture(board)
        // A five-card straight on the flop must use all three shared ranks.
        let straight = texture.straightiness > 0
        let flush = texture.topSuitCount == 3
        let answer = (straight ? 1 : 0) + (flush ? 2 : 0)
        let reasons = [
            Copy("이어지는 다섯 숫자 안에 공용 카드 세 장을 다 넣을 수 없어요. 무늬도 서로 달라서 가진 두 장만으로는 둘 다 완성할 수 없어요.",
                 "The three shared ranks can’t fit in one five-rank run. The suits differ, too. Two hole cards can’t complete either hand."),
            Copy("공용 카드 세 장의 숫자가 이어지는 다섯 숫자 안에 들어가요. 무늬는 달라서 플러시는 아직 만들 수 없어요.",
                 "The three shared ranks fit in one five-rank run. The shared suits differ, so a flush isn’t possible yet."),
            Copy("공용 카드 세 장이 같은 무늬라서 그 무늬의 두 장으로 플러시를 만들 수 있어요. 세 숫자는 이어지는 다섯 숫자 안에 들어가지 않아요.",
                 "Two matching suits can complete a flush. The three shared ranks can’t fit in one five-rank run."),
            Copy("공용 카드 세 장의 숫자가 이어지는 다섯 숫자 안에 들어가요. 세 장의 무늬도 같아서 스트레이트와 플러시가 모두 가능해요.",
                 "The three shared ranks fit in one five-rank run, and all three suits match. A straight and a flush are both possible."),
        ]
        let reason: Copy
        let rows: [TableCourseRow]
        if let compare {
            let other = Card.parse(compare)!
            rows = [TableCourseRow(Copy("비교할 플랍", "Other flop"), cardCopy(other))]
            let straightExample = cardText(Card.parse("9cTd")!)
            let flushExample = cardText(Card.parse("AhKh")!)
            reason = Copy(
                "위 플랍에서는 \(straightExample) 두 장으로 스트레이트를, \(flushExample) 두 장으로 플러시를 만들 수 있어요. 아래 플랍에서는 가진 두 장만으로는 둘 다 만들 수 없어요.",
                "On the first flop, \(straightExample) makes a straight and \(flushExample) makes a flush. On the other flop, two hole cards can’t complete either."
            )
        } else {
            rows = []
            reason = reasons[answer]
        }

        return activity(
            id, Copy("공용 카드가 열어 주는 조합", "What the shared cards allow"),
            Copy("상대가 가진 두 장을 더하면 이 플랍에서 어떤 핸드가 이미 완성될 수 있을까요?",
                 "With two hole cards, which hands could someone already have on this flop?"),
            evidence: .init(board: board, rows: rows),
            choices: [
                Copy("둘 다 불가능", "Neither"),
                Copy("스트레이트만", "A straight only"),
                Copy("플러시만", "A flush only"),
                Copy("둘 다 가능", "Either one is possible"),
            ],
            answer: answer, reason: reason, worked: compare != nil
        )
    }

    private enum Action: Equatable {
        case check, bet

        var copy: Copy {
            self == .bet ? Copy("베팅했어요", "Bet") : Copy("체크했어요", "Checked")
        }
    }

    private static func readAction(
        _ id: String, _ deal: String, _ flop: String, _ guesses: [String], _ observed: Action,
        checkpoint: Bool = false, worked: Bool = false
    ) -> TableCourseActivity {
        let cards = Card.parse(deal)!
        let board = Card.parse(flop)!
        let visible = Set(cards + board)
        let candidates = guesses.map { Card.parse($0)! }
        let categories: [Int?] = candidates.map { hand in
            visible.isDisjoint(with: hand) ? bestHandOfAny(hand + board).category : nil
        }
        let predicted: [Action?] = categories.map { category in
            category.map { $0 >= 2 ? .bet : .check }
        }
        let options = checkpoint ? [[0, 1], [0, 2], [1, 2]] : [[0], [1], [2]]
        let remaining = predicted.indices.filter { predicted[$0] == observed }
        let answer = options.firstIndex(of: remaining)!
        let names = ["A", "B", "C"]
        let rows = [
            TableCourseRow(
                Copy("이 상대의 연습 규칙", "This opponent’s practice rule"),
                Copy("아무도 아직 베팅하지 않았어요. 이 상대는 투 페어 이상이면 베팅하고, 그 외에는 체크해요.",
                     "No one has bet yet. This opponent bets with two pair or better and checks otherwise.")
            ),
            TableCourseRow(Copy("방금 한 행동", "What the opponent did"), observed.copy),
        ] + zip(names, candidates).map { name, cards in
            TableCourseRow(Copy("후보 \(name)", "Hand \(name)"), cardCopy(cards))
        }
        let choices = options.map { group in
            let names = group.map { names[$0] }
            return names.count == 2
                ? Copy("\(KO.and(names[0])) \(names[1])", "\(names[0]) and \(names[1])")
                : Copy("후보 \(names[0])", "Hand \(names[0])")
        }
        let feedback = names.indices.map { index in
            if let category = categories[index], let action = predicted[index] {
                let hand = handNames[category]
                return action == .bet
                    ? Copy("\(KO.topic(names[index])) \(KO.instrumental(hand.text(in: .korean))) 베팅해요.",
                           "\(names[index]) has \(hand.text(in: .english)) and bets.")
                    : Copy("\(KO.topic(names[index])) \(KO.instrumental(hand.text(in: .korean))) 체크해요.",
                           "\(names[index]) has \(hand.text(in: .english)) and checks.")
            }
            let shared = cardText(candidates[index].filter { visible.contains($0) })
            return Copy("\(names[index])에 있는 \(shared) 카드는 이미 보여요.",
                        "\(names[index]) uses \(shared), which is already visible.")
        }
        let takeaway = checkpoint
            ? [Copy("같은 행동도 서로 다른 핸드로 설명할 수 있어요.", "Different hands can explain the same action.")]
            : []
        let notes = feedback + takeaway
        let reason = Copy(notes.map { $0.text(in: .korean) }.joined(separator: " "),
                          notes.map { $0.text(in: .english) }.joined(separator: " "))
        return activity(
            id, checkpoint
                ? Copy("같은 행동, 여러 후보", "Two hands fit the action")
                : Copy("행동에 맞는 후보", "Which hand fits the action?"),
            checkpoint
                ? Copy("이미 보이는 카드는 빼고, 이 행동을 설명할 수 있는 후보 두 가지를 고르세요.",
                       "Rule out visible cards, then choose the two hands that could explain this action.")
                : Copy("연습 규칙을 따르면 세 후보 중 어떤 핸드가 이 행동에 맞을까요?",
                       "Under the practice rule, which hand fits the action?"),
            evidence: .init(cards: cards, board: board, rows: rows),
            choices: choices, answer: answer, reason: reason, worked: worked
        )
    }

    private static func activity(
        _ id: String, _ title: Copy, _ prompt: Copy, evidence: TableCourseEvidence,
        choices: [Copy], answer: Int, reason: Copy, worked: Bool
    ) -> TableCourseActivity {
        TableCourseActivity(id: id, title: title, prompt: prompt, evidence: evidence,
                            choices: worked ? [] : choices, correctChoice: worked ? nil : answer,
                            explanation: reason)
    }

    private static let handNames = [
        Copy("하이 카드", "high card"),
        Copy("원 페어", "one pair"),
        Copy("투 페어", "two pair"),
        Copy("트리플", "three of a kind"),
        Copy("스트레이트", "a straight"),
        Copy("플러시", "a flush"),
        Copy("풀 하우스", "a full house"),
        Copy("포카드", "four of a kind"),
        Copy("스트레이트 플러시", "a straight flush"),
    ]

    private static func cardText(_ cards: [Card]) -> String {
        let suits = ["♣", "♦", "♥", "♠"]
        return cards.map { card in
            let rank = HandClass.rankChars[card.rank - 2]
            return "\(rank == "T" ? "10" : rank)\(suits[card.suit])\u{FE0E}"
        }.joined(separator: " ")
    }

    private static func cardCopy(_ cards: [Card]) -> Copy {
        let text = cardText(cards)
        return Copy(text, text)
    }

    private static func cardListCopy(_ hands: [[Card]]) -> Copy {
        let text = hands.map(cardText).joined(separator: "  ·  ")
        return Copy(text, text)
    }
}
