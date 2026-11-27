// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

public struct CourseReviewActivity: Identifiable, Equatable, Sendable {
    public enum Kind: Equatable, Sendable { case choice, bestFive }

    public let id: String
    public let kind: Kind
    public let learner: [Card]
    public let board: [Card]
    public let opponent: [Card]
    public let correctChoice: Int?
    public let correctFive: [Card]
    public let opponentFive: [Card]
    public internal(set) var tableEvidence: TableCourseEvidence?
    public internal(set) var revealedTableEvidence: TableCourseEvidence?

    fileprivate let heading: UnitACopy
    fileprivate let instruction: UnitACopy
    fileprivate let options: [UnitACopy]
    fileprivate let reason: UnitACopy

    public func title(in language: LearningLanguage) -> String { heading.text(in: language) }
    public func detail(in language: LearningLanguage) -> String { instruction.text(in: language) }
    public func choices(in language: LearningLanguage) -> [String] { options.map { $0.text(in: language) } }
    public func explanation(in language: LearningLanguage) -> String { reason.text(in: language) }
}

/// Held-out deals and option order are stable within this version. Review stores
/// the skill and variant so a retry or reload reads the same question.
public enum CourseReviewContent {
    public static let version = 1

    public static func activity(for skill: CourseReviewSkill, variant: Int) -> CourseReviewActivity? {
        guard let items = bank[skill], items.indices.contains(variant) else { return nil }
        return items[variant]
    }

    public static func variantCount(for skill: CourseReviewSkill) -> Int { bank[skill]?.count ?? 0 }

    private typealias Copy = UnitACopy
    private static let noCopy = Copy("", "")
    private static let privateCards = Copy("내 카드", "My cards")
    private static let sharedCards = Copy("공용 카드", "Shared cards")
    private static let showdown = Copy("쇼다운", "Showdown")
    private static let noShowdown = Copy("카드 공개 없이 끝나요", "No showdown")
    private static let winChoices = [Copy("나", "Me"), Copy("상대", "Opponent"), Copy("무승부", "Tie")]

    private static let basics: [CourseReviewSkill: [CourseReviewActivity]] = [
        .privateCards: [
            choice(.privateCards, 1, "9h4s", "2d5sQc",
                   Copy("나만 쓰는 카드는?", "Which cards are yours alone?"), [privateCards, sharedCards],
                   Copy("내 카드 두 장은 나만 써요.", "Only you can use your two cards.")),
            choice(.privateCards, 2, "Js6h", "Ac8d3s2c",
                   Copy("두 사람 모두 쓸 카드는?", "Which cards can both players use?"), [privateCards, sharedCards],
                   Copy("공용 카드는 둘 다 써요.", "Both players can use the shared cards."), answer: 1),
        ],
        .fiveCardHand: [
            choice(.fiveCardHand, 1, "7sJc", "Jh4d2s9cQh",
                   Copy("완성된 패는 몇 장인가요?", "How many cards make a hand?"),
                   [Copy("다섯 장", "Five"), Copy("일곱 장", "Seven")],
                   Copy("일곱 장 중 가장 강한 다섯 장을 써요.", "Use the strongest five of the seven cards.")),
            choice(.fiveCardHand, 2, "2d8s", "Th3d3hKd6c",
                   Copy("몇 장으로 패를 만들까요?", "How many cards will you use?"),
                   [Copy("두 장", "Two"), Copy("다섯 장", "Five")],
                   Copy("내 카드와 공용 카드에서 다섯 장을 골라요.", "Pick five from all the cards shown."), answer: 1),
        ],
        .sharedBestFive: [
            sharedBest(1, "3d6h", "ThJhQhKhAh"),
            sharedBest(2, "2cAs", "5h6s7d8c9d", answer: 1),
        ],
        .rankAndSuit: [
            choice(.rankAndSuit, 1, "Kd", "",
                   Copy("어떤 숫자나 글자인가요?", "What is this card's rank?"),
                   [Copy("K", "K"), Copy("다이아몬드", "Diamonds")],
                   Copy("K는 랭크, 다이아몬드는 무늬예요.", "K is the rank. Diamonds is the suit.")),
            choice(.rankAndSuit, 2, "8h", "",
                   Copy("어떤 숫자나 글자인가요?", "What is this card's rank?"),
                   [Copy("하트", "Hearts"), Copy("8", "8")],
                   Copy("8은 랭크, 하트는 무늬예요.", "Eight is the rank. Hearts is the suit."), answer: 1),
        ],
        .cardSuit: [
            choice(.cardSuit, 1, "5c", "",
                   Copy("카드의 무늬는 무엇인가요?", "Which suit is this card?"),
                   [Copy("클럽", "Clubs"), Copy("스페이드", "Spades")],
                   Copy("이 카드의 무늬는 클럽이에요.", "The symbol shows a club.")),
            choice(.cardSuit, 2, "2s", "",
                   Copy("카드의 무늬는 무엇인가요?", "Which suit is this card?"),
                   [Copy("하트", "Hearts"), Copy("스페이드", "Spades")],
                   Copy("이 카드의 무늬는 스페이드예요.", "The symbol shows a spade."), answer: 1),
        ],
        .suitStrength: [
            choice(.suitStrength, 1, "JhJc", "",
                   Copy("어떤 카드가 더 강한가요?", "Which card ranks higher?"),
                   [Copy("같아요", "They rank equally"), Copy("하트", "The heart")],
                   Copy("둘 다 J예요. 무늬는 강약이 없어요.", "Both are jacks. Suits have equal strength.")),
            choice(.suitStrength, 2, "9s9d", "",
                   Copy("어떤 카드가 더 강한가요?", "Which card ranks higher?"),
                   [Copy("스페이드", "The spade"), Copy("같아요", "They rank equally")],
                   Copy("둘 다 9예요. 무늬는 강약이 없어요.", "Both are nines. Suits have equal strength."), answer: 1),
        ],
        .findPair: [
            pair(1, "5sQh5d2c", rank: "5", distractor: "Q", answer: 0),
            pair(2, "Kd4sKc7d", rank: "K", distractor: "7", answer: 1),
            pair(3, "9hJd3sJc", rank: "J", distractor: "9", answer: 0),
        ],
        .streets: [
            street(1, "5hAc", "9s3dJh", other: Copy("턴", "Turn"), answer: 0),
            street(2, "Qd7h", "4s6dTcKs", other: Copy("리버", "River"), answer: 1),
            street(3, "2c8h", "QdJc7d4s6h", other: Copy("플랍", "Flop"), answer: 0),
        ],
        .endings: [
            choice(.endings, 1, "Kd3s", "9c5d7s",
                   Copy("이 핸드는 어떻게 끝나나요?", "How does the hand end?"), [noShowdown, showdown],
                   Copy("상대가 폴드했어요. 나만 남아 이겨요.", "You win without showing your cards."),
                   detail: Copy("상대가 플랍에서 폴드했어요.", "Your opponent folds on the flop.")),
            choice(.endings, 2, "Qh9d", "2d8cThKc6h",
                   Copy("이 핸드는 어떻게 끝나나요?", "How does the hand end?"), [noShowdown, showdown],
                   Copy("둘 다 남아서 카드를 비교해요.", "Both show their cards and compare hands."),
                   answer: 1, detail: Copy("리버가 끝났어요. 둘 다 남아 있어요.", "Both players stay through the river.")),
            choice(.endings, 3, "8s4h", "Ad2c5hJd",
                   Copy("이 핸드는 어떻게 끝나나요?", "How does the hand end?"), [noShowdown, showdown],
                   Copy("내가 폴드하면 상대가 이겨요.", "Your opponent wins when you fold."),
                   detail: Copy("내가 턴에서 폴드했어요.", "You fold on the turn.")),
        ],
    ]

    // Board, learner, opponent. The hand evaluator supplies the whole answer key.
    private typealias Deal = (board: String, learner: String, opponent: String)
    private static let showdownDeals: [CourseReviewSkill: [Deal]] = [
        .pairBeatsHighCard: [
            ("5hAdKd2cTd", "3sKc", "9h6d"),
            ("5sTh4h2dAc", "Kh8h", "8cTc"),
            ("5cAh7h9cTd", "QdQc", "2h3h"),
        ],
        .pairComparison: [
            ("Kd4c2cAh5s", "Ks7h", "4dJd"),
            ("2sTs6dKsQh", "2h5h", "QdJs"),
            ("5sTh4c3c6d", "TdKs", "Qh5h"),
        ],
        .twoPair: [
            ("6c8s5sJhKc", "5cKh", "2d8c"),
            ("AcJh9d4cJs", "7s3c", "Qs4s"),
            ("6h5cQh3d2h", "Qd2c", "5sKc"),
        ],
        .threeOfAKind: [
            ("Ac4dAhKc2c", "Ad3d", "3c3s"),
            ("7dTd2d2c3d", "JsJh", "2hQs"),
            ("3cAs6cTc3s", "Js3d", "Kc6d"),
        ],
        .straight: [
            ("Kh6cKdJsTs", "9dQh", "QcKc"),
            ("6h5h4s7d4h", "4dAc", "Qs3s"),
            ("9h2c7hQsJc", "KdTh", "QcQd"),
        ],
        .flush: [
            ("6hJhTdAhKd", "3h9h", "3cQc"),
            ("AdJdQc9dTd", "8sJs", "6d4d"),
            ("Qh7hKs9hTh", "Ah6h", "6cJc"),
        ],
        .fullHouse: [
            ("4d2dTdTsJd", "2s2c", "TcAd"),
            ("TdTc6dJd8c", "8d4d", "Th8s"),
            ("8d9s9d3d9h", "6c3s", "6d4d"),
        ],
        .fourOfAKind: [
            ("TdTcKsTh4h", "TsAs", "KcQd"),
            ("5cKd5sKcKs", "Qh6c", "AhKh"),
            ("Qs9cQcTdQd", "QhTs", "JcTh"),
        ],
        .straightFlush: [
            ("KhQh9hJhAh", "Th9d", "4dTs"),
            ("2dJc8cTc9c", "9s4c", "AsQc"),
            ("9cKcTcJc6d", "Qc9s", "4cKd"),
        ],
        .kickers: [
            ("5s4h5d2d9d", "AhJh", "6sKc"),
            ("QdAsTdQh7d", "2h8h", "Kc3h"),
            ("4cKh9sKc6h", "8sTh", "7s2s"),
        ],
        .highCardRanks: [
            ("2h8sQs6d3d", "TcJh", "9sJd"),
            ("6cQcAd4s2c", "8d3c", "JsKd"),
            ("AcKh7c8d3s", "6c5c", "4d2s"),
        ],
        .twoPairRanks: [
            ("5h7s3s5c8s", "KdKh", "3hAd"),
            ("5sAc5c2cTh", "8c2h", "3dTd"),
            ("5c9hTc8h3h", "5hTd", "3d8s"),
        ],
        .fullHouseRanks: [
            ("7s5h7cJc3c", "JdJs", "3d7d"),
            ("JhJs5dQsQc", "Jd3c", "QdTd"),
            ("5cAs5hTc2s", "Ac5d", "2d2h"),
        ],
        .boardPlays: [
            ("3s5d4d7h6c", "TsQd", "Qc2h"),
            ("TcJd8dQh8s", "9c3s", "Qc9d"),
            ("6h7s8d9cTc", "JdKc", "2dTd"),
        ],
    ]

    private static let bestFive: [CourseReviewActivity] = [
        five(1, "As2d", "4c5d6s7h8c",
             Copy("공용 카드만 써요. 4부터 8까지 이어져요.", "Play the shared straight from four to eight.")),
        five(2, "Ah8s", "4c6d8hTcQd",
             Copy("8 페어예요. 남은 카드는 A, Q, 10이에요.", "A pair of eights plays with A, Q and 10.")),
        five(3, "6s6d", "3c5d7s8h9c",
             Copy("5부터 9까지 이어져요. 어느 6을 써도 같아요.", "The straight runs from five to nine. Either six works.")),
    ]

    private static let bank: [CourseReviewSkill: [CourseReviewActivity]] = {
        var result = basics
        for (skill, deals) in showdownDeals {
            result[skill] = deals.enumerated().map { index, deal in compare(skill, index + 1, deal) }
        }
        result[.bestFive] = bestFive
        for skill in CourseReviewSkill.allCases {
            guard let lesson = skill.tableLesson else { continue }
            let heldOut: [TableCourseActivity] = switch lesson.unit {
            case .turns: BettingUnitContent.reviewQuestions(for: lesson)
            case .chips: ChipUnitContent.reviewActivities(for: lesson)
            case .startingHands: StartingHandUnitContent.reviewActivities(for: lesson)
            case .possibleHands: PossibleHandsUnitContent.reviewActivities(for: lesson)
            case .winningCards: WinningCardsUnitContent.reviewActivities(for: lesson)
            case .priceChance: PriceChanceUnitContent.reviewActivities(for: lesson)
            case .combinations: CombinationUnitContent.reviewActivities(for: lesson)
            case .expectedValue: ExpectedValueUnitContent.reviewActivities(for: lesson)
            case .boardPatterns: BoardPatternsUnitContent.reviewActivities(for: lesson)
            case .allIns, .tableContexts, .independentHands: MasteryCourseContent.reviewActivities(for: lesson)
            case .capstone, .milestone: []
            }
            result[skill] = heldOut.map(tableQuestion)
        }
        return result
    }()

    static func spacedActivity(for skill: CourseReviewSkill) -> CourseReviewActivity? {
        spacedBank[skill]
    }

    private static let spacedBank = Dictionary(uniqueKeysWithValues:
        MasteryCourseContent.spacedQuestions.map { ($0.key, tableQuestion($0.value)) })

    private static func tableQuestion(_ activity: TableCourseActivity) -> CourseReviewActivity {
        let options = zip(activity.choices(in: .korean), activity.choices(in: .english)).map { Copy($0, $1) }
        return CourseReviewActivity(
            id: activity.id, kind: .choice, learner: [], board: [], opponent: [],
            correctChoice: activity.correctChoice, correctFive: [], opponentFive: [],
            tableEvidence: activity.evidence, revealedTableEvidence: activity.revealedEvidence,
            heading: Copy(activity.title(in: .korean), activity.title(in: .english)),
            instruction: Copy(activity.prompt(in: .korean) ?? "", activity.prompt(in: .english) ?? ""),
            options: options,
            reason: Copy(activity.explanation(in: .korean) ?? "", activity.explanation(in: .english) ?? "")
        )
    }

    private static func id(_ skill: CourseReviewSkill, _ number: Int) -> String {
        "review-\(skill.rawValue)-\(number)"
    }

    private static func choice(_ skill: CourseReviewSkill, _ number: Int, _ own: String, _ shared: String,
                               _ title: Copy, _ choices: [Copy], _ explanation: Copy, answer: Int = 0,
                               detail: Copy = noCopy, correctFive: [Card] = []) -> CourseReviewActivity {
        let learner = cards(own), board = cards(shared)
        precondition(choices.indices.contains(answer))
        validate(board: board, learner: learner)
        return CourseReviewActivity(id: id(skill, number), kind: .choice, learner: learner, board: board,
                                    opponent: [], correctChoice: answer, correctFive: correctFive, opponentFive: [],
                                    heading: title, instruction: detail, options: choices, reason: explanation)
    }

    private static func sharedBest(_ number: Int, _ own: String, _ shared: String,
                                   answer: Int = 0) -> CourseReviewActivity {
        let board = cards(shared), allCards = cards(own) + board
        precondition(compareHands(hero: board, villain: allCards) == 2)
        let yes = Copy("네, 공용 카드만 써도 돼요", "Yes, if they make the best hand")
        let no = Copy("아니요, 내 카드도 써야 해요", "No, I must use one of my cards")
        return choice(.sharedBestFive, number, own, shared,
                      Copy("공용 카드만 써도 되나요?", "Can all five cards be shared?"),
                      answer == 0 ? [yes, no] : [no, yes],
                      Copy("여기선 공용 카드 다섯 장이 가장 강해요.", "Here, the shared cards make the strongest five."),
                      answer: answer, correctFive: board)
    }

    private static func pair(_ number: Int, _ own: String, rank: String, distractor: String,
                             answer: Int) -> CourseReviewActivity {
        let duplicates = Dictionary(grouping: cards(own), by: \.rank).values.filter { $0.count == 2 }
        precondition(duplicates.count == 1 && duplicates[0].first.map { Card.displayRanks[$0.rank - 2] } == rank)
        let correct = Copy(rank, rank), wrong = Copy(distractor, distractor)
        return choice(.findPair, number, own, "", Copy("어떤 숫자나 글자가 페어인가요?", "Which rank makes a pair?"),
                      answer == 0 ? [correct, wrong] : [wrong, correct],
                      Copy("\(rank) 두 장이 페어예요.", "Two \(rank)s make the pair."), answer: answer)
    }

    private static func street(_ number: Int, _ own: String, _ shared: String, other: Copy,
                               answer: Int) -> CourseReviewActivity {
        let street: Copy
        let reason: Copy
        switch cards(shared).count {
        case 3:
            street = Copy("플랍", "Flop")
            reason = Copy("공용 카드 첫 세 장은 플랍이에요.", "The first three shared cards are the flop.")
        case 4:
            street = Copy("턴", "Turn")
            reason = Copy("네 번째 공용 카드는 턴이에요.", "The fourth shared card is the turn.")
        case 5:
            street = Copy("리버", "River")
            reason = Copy("다섯 번째 공용 카드는 리버예요.", "The fifth shared card is the river.")
        default: preconditionFailure("Unexpected street review card count")
        }
        return choice(.streets, number, own, shared, Copy("지금은 어느 단계인가요?", "Which street is this?"),
                      answer == 0 ? [street, other] : [other, street], reason, answer: answer)
    }

    private static func compare(_ skill: CourseReviewSkill, _ number: Int, _ deal: Deal) -> CourseReviewActivity {
        let board = cards(deal.board), learner = cards(deal.learner), opponent = cards(deal.opponent)
        precondition(board.count == 5 && learner.count == 2 && opponent.count == 2)
        validate(board: board, learner: learner, opponent: opponent)
        let playerCards = learner + board, rivalCards = opponent + board
        let playerFive = bestFiveCards(playerCards), rivalFive = bestFiveCards(rivalCards)
        let winner = compareHands(hero: playerCards, villain: rivalCards)
        let player = bestHand(playerCards), rival = bestHand(rivalCards)
        let reason = outcomeReason(skill, board: board, player: player, rival: rival, playerFive: playerFive,
                                   rivalFive: rivalFive, winner: winner)
        return CourseReviewActivity(id: id(skill, number), kind: .choice, learner: learner, board: board,
                                    opponent: opponent, correctChoice: winner, correctFive: playerFive,
                                    opponentFive: rivalFive, heading: Copy("누가 이길까요?", "Who wins?"),
                                    instruction: noCopy, options: winChoices, reason: reason)
    }

    private static func outcomeReason(_ skill: CourseReviewSkill, board: [Card], player: HandBrief, rival: HandBrief,
                                      playerFive: [Card], rivalFive: [Card], winner: Int) -> Copy {
        if winner == 2 {
            if compareHands(hero: board, villain: playerFive) == 2 {
                return Copy("둘 다 공용 카드만 써요.\n팟을 나눠요.", "Both play the shared cards.\nThey split the pot.")
            }
            return Copy("무늬는 달라도 같은 패예요.\n팟을 나눠요.",
                        "The best fives rank equally.\nThey split the pot.")
        }
        if skill == .boardPlays {
            return Copy("내 J를 쓰면 더 높은 스트레이트예요.", "Your jack makes a higher straight.")
        }
        let high = winner == 0 ? player : rival
        let low = winner == 0 ? rival : player
        if high.category != low.category {
            let highName = DrillTerms.handWithArticle(high, in: .english, capitalized: true)
            let lowName = DrillTerms.handWithArticle(low, in: .english)
            let highKorean = DrillTerms.hand(high, in: .korean)
            let lowKorean = DrillTerms.hand(low, in: .korean)
            return Copy("\(KO.subject(highKorean)) \(lowKorean)보다 강해요.",
                        "\(DrillTerms.closingAside(highName)) beats \(lowName).")
        }
        guard let (playerCard, rivalCard) = zip(playerFive, rivalFive).first(where: { $0.rank != $1.rank }) else {
            preconditionFailure("Unequal same-type hands need a deciding rank")
        }
        let winningRank = Card.displayRanks[(winner == 0 ? playerCard : rivalCard).rank - 2]
        let losingRank = Card.displayRanks[(winner == 0 ? rivalCard : playerCard).rank - 2]
        return switch skill {
        case .pairComparison:
            Copy("\(winningRank) 페어가 더 높아요.", "The pair of \(winningRank)s wins.")
        case .kickers:
            Copy("페어가 같아요.\n키커 \(winningRank)가 \(losingRank)보다 높아요.",
                 "The pairs match.\nKicker \(winningRank) beats \(losingRank).")
        case .highCardRanks:
            Copy("처음 다른 카드 \(winningRank)가 더 높아요.", "\(winningRank) wins at the first rank that differs.")
        case .twoPairRanks:
            Copy("높은 쪽 페어부터 봐요.\n\(winningRank) 페어가 이겨요.",
                 "Compare the higher pairs first.\nThe pair of \(winningRank)s wins.")
        case .fullHouseRanks:
            Copy("같은 숫자 세 장부터 봐요.\n\(winningRank) 세 장이 이겨요.",
                 "Compare the three matching cards first.\nThree \(winningRank)s win.")
        default:
            preconditionFailure("Unexpected same-category comparison in review")
        }
    }

    private static func five(_ number: Int, _ own: String, _ shared: String, _ reason: Copy) -> CourseReviewActivity {
        let learner = cards(own), board = cards(shared)
        precondition(learner.count == 2 && board.count == 5)
        validate(board: board, learner: learner)
        return CourseReviewActivity(id: id(.bestFive, number), kind: .bestFive, learner: learner, board: board,
                                    opponent: [], correctChoice: nil, correctFive: bestFiveCards(learner + board),
                                    opponentFive: [], heading: Copy("가장 강한 다섯 장은?", "Pick the strongest five"),
                                    instruction: Copy("일곱 장 중 다섯 장을 골라요.", "Choose five of the seven cards."),
                                    options: [], reason: reason)
    }

    private static func cards(_ tokens: String) -> [Card] {
        guard let cards = Card.parse(tokens) else { preconditionFailure("Invalid course review cards: \(tokens)") }
        return cards
    }

    private static func validate(board: [Card], learner: [Card], opponent: [Card] = []) {
        let allCards = board + learner + opponent
        precondition(Set(allCards).count == allCards.count, "Course review deals must use distinct cards")
    }
}
