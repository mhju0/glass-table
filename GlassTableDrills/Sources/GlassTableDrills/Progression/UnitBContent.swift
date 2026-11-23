// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

public struct UnitBActivity: Identifiable, Equatable, Sendable {
    public enum Kind: Equatable, Sendable { case example, choice, bestFive }

    public let id: String
    public let kind: Kind
    public let board: [Card]
    public let learner: [Card]
    public let opponent: [Card]
    public let correctChoice: Int?
    public let correctFive: [Card]
    public let opponentFive: [Card]
    public let showsBestFivesBeforeAnswer: Bool

    private let heading: UnitACopy
    private let instruction: UnitACopy
    private let options: [UnitACopy]
    private let reason: UnitACopy

    fileprivate init(id: String, kind: Kind, board: [Card], learner: [Card],
                     opponent: [Card], heading: UnitACopy, instruction: UnitACopy,
                     choices: [UnitACopy], correctChoice: Int?, reason: UnitACopy,
                     showsBestFivesBeforeAnswer: Bool) {
        self.id = id
        self.kind = kind
        self.board = board
        self.learner = learner
        self.opponent = opponent
        self.heading = heading
        self.instruction = instruction
        self.options = choices
        self.correctChoice = correctChoice
        self.reason = reason
        self.showsBestFivesBeforeAnswer = showsBestFivesBeforeAnswer
        correctFive = bestFiveCards(learner + board)
        opponentFive = opponent.isEmpty ? [] : bestFiveCards(opponent + board)
    }

    public func title(in language: LearningLanguage) -> String { heading.text(in: language) }
    public func detail(in language: LearningLanguage) -> String { instruction.text(in: language) }
    public func choices(in language: LearningLanguage) -> [String] { options.map { $0.text(in: language) } }
    public func explanation(in language: LearningLanguage) -> String { reason.text(in: language) }
}

/// Stable card and answer order. Persisted answers use indices into this exact
/// version. Any change to IDs, cards or option meaning requires a new version.
enum UnitBContentV1 {
    static let version = 1

    static func activities(for lesson: UnitBLesson) -> [UnitBActivity] {
        switch lesson {
        case .pairBeatsHighCard: pairBeatsHighCard
        case .pairComparison: []
        case .twoPair: twoPair
        case .threeOfAKind: threeOfAKind
        case .straight: straight
        case .flush: flush
        case .fullHouse: fullHouse
        case .fourOfAKind: fourOfAKind
        case .straightFlush: straightFlush
        case .bestFive: bestFive
        case .kickers: kickers
        case .boardPlays: boardPlays
        case .checkpoint: checkpoint
        }
    }

    private typealias Copy = UnitACopy

    private enum Category: Int {
        case highCard, pair, twoPair, trips, straight, flush, fullHouse, quads, straightFlush
    }

    private enum Outcome: Int {
        case learner, opponent, tie
    }

    private static let winnerQuestion = Copy("누가 이길까요?", "Who wins?")
    private static let compareFive = Copy("각자 가장 강한 다섯 장을 비교해요.",
                                          "Compare each player's strongest five.")
    private static let pickFive = Copy("가장 강한 다섯 장을 골라요.",
                                       "Pick your strongest five.")
    private static let pickFiveHelp = Copy("일곱 장 중 다섯 장을 골라요.",
                                           "Use any five of the seven cards.")
    private static let winnerChoices = [Copy("나", "Me"), Copy("상대", "Opponent")]
    private static let tieChoice = Copy("무승부", "Tie")
    private static let noCopy = Copy("", "")

    private static let pairBeatsHighCard = [
        worked("B1-example", "2d5c8sJhQd", "6h6s", "AcKd", .pair, .highCard, .learner,
               Copy("페어가 먼저예요", "A pair comes first"),
               Copy("같은 숫자나 글자 두 장이 원 페어예요. 이 예에서 상대는 하이 카드예요.",
                    "Two cards of the same rank make a pair. An unpaired hand here is high card."),
               Copy("내 6 페어가 상대의 A 하이 카드를 이겨요.",
                    "A pair of sixes beats ace high.")),
        compare("B1-01", "3c6d9sJcKh", "AdQc", "2d2h", .highCard, .pair, .opponent,
                Copy("상대의 2 페어가 A 하이 카드보다 강해요.",
                     "The opponent's pair of twos beats ace high.")),
        compare("B1-02", "4s7h9dQcKs", "9c5c", "AdJd", .pair, .highCard, .learner,
                Copy("내 9 페어가 상대의 A 하이 카드를 이겨요.",
                     "Your pair of nines beats the opponent's ace high.")),
        compare("B1-03", "2h6c8dTsQc", "AhKd", "4h4d", .highCard, .pair, .opponent,
                Copy("숫자가 낮아도 4 페어가 하이 카드보다 강해요.",
                     "A pair of fours outranks high card, even ace high."))
    ]

    private static let twoPair = [
        worked("B3-example", "8c8d2sJc5h", "Js9h", "AsKd", .twoPair, .pair, .learner,
               Copy("두 쌍이면 투 페어", "Two matching pairs"),
               Copy("같은 숫자나 글자가 두 장씩 두 쌍 있으면 투 페어예요.",
                    "Two pairs of different ranks make two pair."),
               Copy("내 J 페어와 8 페어가 상대의 8 페어를 이겨요.",
                    "Jacks and eights beat one pair.")),
        compare("B3-01", "4c4h9sTd2c", "As7h", "TcJd", .pair, .twoPair, .opponent,
                Copy("상대에게 10 페어와 4 페어가 있어요. 내 4 페어보다 강해요.",
                     "The opponent's tens and fours beat your pair of fours.")),
        compare("B3-02", "6hKs3dJc2s", "Kd6c", "AcJh", .twoPair, .pair, .learner,
                Copy("내 K 페어와 6 페어가 상대의 J 페어를 이겨요.",
                     "Your kings and sixes beat a pair of jacks.")),
        compare("B3-03", "5d5s8hQc2d", "AcJh", "Qh7d", .pair, .twoPair, .opponent,
                Copy("상대는 Q와 5가 각각 두 장이에요. 투 페어가 이겨요.",
                     "The opponent has two queens and two fives. Two pair wins."))
    ]

    private static let threeOfAKind = [
        worked("B4-example", "QhQs8c5d2s", "QcAd", "8hJd", .trips, .twoPair, .learner,
               Copy("세 장이면 트리플", "Three of a kind"),
               Copy("같은 숫자나 글자 세 장을 트리플이라고 해요.",
                    "All three cards have the same rank."),
               Copy("내 Q 세 장이 상대의 Q 페어와 8 페어를 이겨요.",
                    "Three queens beat two pair.")),
        compare("B4-01", "3c3d8sThKd", "TsAc", "3hAs", .twoPair, .trips, .opponent,
                Copy("상대의 3 세 장이 내 10 페어와 3 페어보다 강해요.",
                     "The opponent's three threes beat your tens and threes.")),
        compare("B4-02", "8h8s4dJcQs", "8cAd", "Jh9d", .trips, .twoPair, .learner,
                Copy("내 8 세 장이 상대의 J 페어와 8 페어를 이겨요.",
                     "Your three eights beat the opponent's jacks and eights.")),
        compare("B4-03", "KcKd2s7hTs", "2hAd", "Kh5c", .twoPair, .trips, .opponent,
                Copy("상대의 K 세 장이 내 K 페어와 2 페어보다 강해요.",
                     "The opponent's three kings beat your kings and twos."))
    ]

    private static let straight = [
        worked("B5-example", "2c3d4s9hJh", "Ad5s", "JdQc", .straight, .pair, .learner,
               Copy("다섯 장을 순서대로", "Five ranks in a row"),
               Copy("숫자나 글자가 다섯 장 이어지면 스트레이트예요. A는 2 앞에 올 수 있어요.",
                    "Five ranks in a row make a straight. An ace can go before a two."),
               Copy("A부터 5까지 이어진 내 스트레이트가 상대의 J 페어를 이겨요.",
                    "Your ace-through-five straight beats the opponent's pair of jacks.")),
        compare("B5-01", "5c6d7sJh2h", "AdAc", "8s9d", .pair, .straight, .opponent,
                Copy("상대의 5부터 9까지 이어진 스트레이트가 A 페어를 이겨요.",
                     "The opponent has a straight from five through nine. It beats aces.")),
        compare("B5-02", "Ac2d3hQc4s", "5h9d", "KsJc", .straight, .highCard, .learner,
                Copy("내 카드는 A부터 5까지 이어져요. K에서 A를 지나 2로 이어질 수는 없어요.",
                     "You have ace through five. King, ace and two cannot connect in a straight.")),
        compare("B5-03", "2d3s4h5cQd", "AhKc", "6h9s", .straight, .straight, .opponent,
                Copy("둘 다 스트레이트예요. 마지막 숫자 6이 5보다 높아요.",
                     "Both have straights. The opponent ends at six. Your straight ends at five."))
    ]

    private static let flush = [
        worked("B6-example", "3h6h8h9cTd", "AhQh", "7sJs", .flush, .straight, .learner,
               Copy("같은 무늬 다섯 장", "Five cards of one suit"),
               Copy("같은 무늬 다섯 장이 플러시예요. 숫자가 이어질 필요는 없어요.",
                    "Five cards of one suit make a flush. The ranks can have gaps."),
               Copy("내 하트 다섯 장이 상대의 스트레이트를 이겨요.",
                    "Your five hearts beat the opponent's straight.")),
        compare("B6-01", "4d7d9dTcJh", "8hQs", "2dKd", .straight, .flush, .opponent,
                Copy("상대의 다이아몬드 다섯 장이 내 스트레이트를 이겨요.",
                     "The opponent's five diamonds beat your straight.")),
        compare("B6-02", "2s5s8sKd9c", "7sQs", "KcKh", .flush, .trips, .learner,
                Copy("내 스페이드 다섯 장이 상대의 K 세 장을 이겨요.",
                     "Your five spades beat the opponent's three kings.")),
        compare("B6-03", "6c9cQc7d8h", "TcJs", "Kc2c", .straight, .flush, .opponent,
                Copy("내 카드는 클럽이 네 장이에요. 상대는 클럽이 다섯 장이라 플러시예요.",
                     "You have four clubs. The opponent has five clubs, enough for a flush."))
    ]

    private static let fullHouse = [
        worked("B7-example", "9h9d4hKh2h", "9s4c", "Ah8c", .fullHouse, .flush, .learner,
               Copy("세 장과 두 장", "Three cards plus a pair"),
               Copy("같은 숫자나 글자 세 장과 다른 원 페어가 풀 하우스예요.",
                    "Three of one rank, two of another."),
               Copy("내 9 세 장과 4 두 장이 상대의 하트 플러시를 이겨요.",
                    "Three nines and a pair beat a flush.")),
        compare("B7-01", "QhQs3d8c2s", "QcAd", "Qd8d", .trips, .fullHouse, .opponent,
                Copy("둘 다 Q 세 장이지만 상대에게 8 페어도 있어요.",
                     "Both have three queens. The opponent also has a pair of eights.")),
        compare("B7-02", "8c8d4d4cJs", "8s2s", "AsKd", .fullHouse, .twoPair, .learner,
                Copy("내 8이 공용 카드의 8 두 장과 만나 풀 하우스가 돼요.",
                     "Your eight joins the two shared eights, making a full house with the fours.")),
        compare("B7-03", "AhAd9h5h5d", "KhJh", "AcTd", .flush, .fullHouse, .opponent,
                Copy("상대의 A 세 장과 5 두 장이 내 하트 플러시보다 강해요.",
                     "The opponent's three aces and two fives beat your heart flush."))
    ]

    private static let fourOfAKind = [
        worked("B8-example", "7h7d7sJc2s", "7cAd", "JsTh", .quads, .fullHouse, .learner,
               Copy("네 장이면 포카드", "Four of a kind"),
               Copy("같은 숫자나 글자가 네 장이면 포카드예요.",
                    "All four cards have the same rank."),
               Copy("내 7 네 장이 상대의 7 세 장과 J 두 장을 이겨요.",
                    "Four sevens beat a full house.")),
        compare("B8-01", "TdThTc4d9c", "4cAs", "Ts2h", .fullHouse, .quads, .opponent,
                Copy("상대는 10이 네 장이에요. 포카드가 풀 하우스보다 강해요.",
                     "The opponent has four tens. Four of a kind beats a full house.")),
        compare("B8-02", "2c2h2sQs7h", "2dKd", "KhKc", .quads, .fullHouse, .learner,
                Copy("내 2 네 장이 상대의 2 세 장과 K 두 장을 이겨요.",
                     "Your four twos beat the opponent's full house of twos and kings.")),
        compare("B8-03", "6c6d6sAh4h", "AcJs", "6hQd", .fullHouse, .quads, .opponent,
                Copy("상대의 6 네 장이 내 6과 A로 만든 풀 하우스보다 강해요.",
                     "The opponent's four sixes beat your full house of sixes and aces."))
    ]

    private static let straightFlush = [
        worked("B9-example", "7s8s9s2hKd", "TsJs", "AsQs", .straightFlush, .flush, .learner,
               Copy("이어지는 같은 무늬", "Same suit, in order"),
               Copy("같은 무늬로 숫자나 글자가 다섯 장 이어지면 스트레이트 플러시예요.",
                    "One suit. Five ranks in a row."),
               Copy("내 스페이드는 7부터 J까지 이어져요. 상대의 A 하이 플러시를 이겨요.",
                    "Your spades run from seven through jack. They beat the opponent's ace-high flush.")),
        compare("B9-01", "TsJsQsKs4d", "9s8s", "As3d", .straightFlush, .straightFlush, .opponent,
                Copy("상대의 10, J, Q, K, A는 모두 스페이드예요. 가장 높은 스트레이트 플러시인 로열 플러시예요.",
                     "The opponent runs from ten to ace in spades. A royal flush is the highest straight flush.")),
        compare("B9-02", "2h3h4h7cKd", "Ah5h", "QhTh", .straightFlush, .flush, .learner,
                Copy("내 하트는 A부터 5까지 이어져요. 상대의 플러시보다 강해요.",
                     "Your hearts run from ace through five. They beat the opponent's flush.")),
        compare("B9-03", "8c9cTc2hAd", "JdQh", "JcQc", .straight, .straightFlush, .opponent,
                Copy("둘 다 8부터 Q까지 이어져요. 상대의 다섯 장만 모두 클럽이에요.",
                     "Both run from eight through queen. Only the opponent uses five clubs."))
    ]

    private static let bestFive = [
        five("B10-example", "JcJd5h5s2c", "Js7d", .fullHouse, using: 1, example: true,
             Copy("내 카드 한 장을 써요", "One private card plays"),
             Copy("내 J와 공용 카드의 J 두 장, 5 두 장을 합치면 풀 하우스예요.",
                  "Your jack joins the two shared jacks and two fives for a full house.")),
        five("B10-01", "6h7h8h9hTh", "4c7d", .straightFlush, using: 0,
             pickFive, Copy("하트 6부터 10까지 모두 공용 카드예요. 그 다섯 장이 가장 강해요.",
                            "The shared hearts run from six to ten.")),
        five("B10-02", "4s5h6d7cQh", "8cAs", .straight, using: 1,
             pickFive, Copy("내 8을 더하면 4부터 8까지 이어져요. A는 이 스트레이트에 쓰이지 않아요.",
                            "Your eight completes a straight from four through eight. The ace stays out.")),
        five("B10-03", "AcJd9c6h2s", "8s8h", .pair, using: 2,
             pickFive, Copy("8 두 장으로 페어를 만들어요. 남은 자리에는 높은 순서로 A, J, 9를 써요.",
                            "Keep both eights for the pair. Use ace, jack and nine for the remaining spots.")),
        five("B10-04", "6h7s8d9cTc", "Th3c", .straight, using: 1,
             pickFive, Copy("6부터 10까지 이어져요. 10은 하트나 클럽 어느 쪽을 골라도 돼요.",
                            "The straight runs from six to ten. Either ten gives the same hand."))
    ]

    private static let kickers = [
        worked("B11-example", "JsJd3c6s9h", "Ad5d", "Kd4h", .pair, .pair, .learner,
               Copy("같은 페어라면", "When the pairs match"),
               Copy("남은 카드가 키커예요.\n높은 키커부터 비교해요.",
                    "The remaining cards are kickers.\nCompare them from high to low."),
               Copy("둘 다 J 페어예요.\n키커는 A가 K보다 높아요.",
                    "Both have a pair of jacks. Your first kicker is an ace, above the opponent's king.")),
        compare("B11-01", "8c8sAh5c2d", "KcTd", "Ks9h", .pair, .pair, .learner,
                Copy("8 페어와 A, K가 같아요. 마지막 키커 10이 9보다 높아요.",
                     "Both have eights, then ace and king. Your last kicker is ten, above nine."), showFives: false),
        compare("B11-02", "2d4c5s7hJd", "Ac8s", "As9c", .highCard, .highCard, .opponent,
                Copy("A와 J가 같아요. 그다음 상대의 9가 내 8보다 높아요.",
                     "Ace and jack match. Next, the opponent's nine beats your eight."), showFives: false),
        compare("B11-03", "2s7cKhQd3d", "Kc2d", "Qc7h", .twoPair, .twoPair, .learner,
                Copy("투 페어는 높은 쪽 페어부터 봐요. K 페어가 Q 페어보다 높아요.",
                     "With two pair, compare the higher pairs first. Kings beat queens."), showFives: false),
        compare("B11-04", "QcQd4h4s2d", "4cAs", "Qh9h", .fullHouse, .fullHouse, .opponent,
                Copy("풀 하우스는 세 장을 먼저 봐요. Q 세 장이 4 세 장보다 높아요.",
                     "With a full house, compare the three matching cards first. Three queens beat three fours."), showFives: false)
    ]

    private static let boardPlays = [
        worked("B12-example", "TsJsQsKsAs", "3c4d", "AhAd", .straightFlush, .straightFlush, .tie,
               Copy("공용 카드가 모두 쓰일 때", "The board can play"),
               Copy("둘 다 공용 카드 다섯 장이 최선이면 같은 패예요.",
                    "When all five shared cards are best for both players, both have the same hand."),
               Copy("둘 다 같은 로열 플러시라 팟을 나눠요.",
                    "Both play the royal flush.\nThey split the pot.")),
        compare("B12-01", "6c7d8h9sTc", "2c3d", "4hAd", .straight, .straight, .tie,
                Copy("공용 카드만 써요.\n팟을 나눠요.",
                     "Both use the shared cards.\nThey split the pot."),
                showFives: false, includeTie: true),
        compare("B12-02", "JcJd6s6h2c", "Ah9h", "Ks4d", .twoPair, .twoPair, .learner,
                Copy("J 페어와 6 페어는 같아요. 내 A가 상대의 K보다 높은 키커예요.",
                     "The jacks and sixes match. Your kicker is an ace, above the opponent's king."),
                showFives: false, includeTie: true),
        compare("B12-03", "2c3d4c5hQd", "6h9c", "6sJd", .straight, .straight, .tie,
                Copy("각자 다른 무늬의 6을 써도 둘 다 2부터 6까지 이어져요. 팟을 나눠요.",
                     "Each player uses a six of a different suit. Both make the same straight and split."),
                showFives: false, includeTie: true)
    ]

    private static let checkpoint = [
        worked("B13-example", "3s4d5h6cQh", "7sAs", "QdKc", .straight, .pair, .learner,
               Copy("다섯 장부터 비교해요", "Compare the best fives"),
               Copy("각자 가장 강한 다섯 장을 만들고, 패의 종류와 필요한 숫자를 비교해요.",
                    "Build each player's strongest five. Compare hand types, then ranks if needed."),
               Copy("내 3부터 7까지 이어진 스트레이트가 상대의 Q 페어를 이겨요.",
                    "Your straight from three through seven beats the opponent's pair of queens.")),
        compare("B13-01", "9c9d4s7hQd", "9h7d", "QcAs", .fullHouse, .twoPair, .learner,
                Copy("내 9 세 장과 7 두 장이 상대의 Q 페어와 9 페어를 이겨요.",
                     "Your full house beats the opponent's queens and nines."),
                showFives: false, includeTie: true),
        five("B13-02", "9sTsJdQc4d", "Kd2h", .straight, using: 1,
             pickFive, Copy("내 K를 쓰면 9부터 K까지 이어져요. 2는 쓰이지 않아요.",
                            "Your king completes a straight from nine through king. The two stays out.")),
        compare("B13-03", "6c6hAs3c2d", "Qc8h", "Qs9d", .pair, .pair, .opponent,
                Copy("6 페어와 A, Q가 같아요. 마지막 키커는 상대의 9가 더 높아요.",
                     "Both have sixes, then ace and queen. The opponent's nine beats your eight."),
                showFives: false, includeTie: true),
        compare("B13-04", "4c5d6s7h8d", "AcKs", "Qh2s", .straight, .straight, .tie,
                Copy("둘 다 공용 카드의 4부터 8까지 써요. 같은 스트레이트라 팟을 나눠요.",
                     "Both play the shared straight from four through eight and split the pot."),
                showFives: false, includeTie: true)
    ]

    private static func worked(_ id: String, _ board: String, _ learner: String, _ opponent: String,
                               _ learnerCategory: Category, _ opponentCategory: Category,
                               _ outcome: Outcome, _ title: Copy, _ detail: Copy, _ explanation: Copy)
        -> UnitBActivity {
        showdown(id, kind: .example, board, learner, opponent, learnerCategory, opponentCategory,
                 outcome, title, detail, explanation, showFives: true, includeTie: false)
    }

    private static func compare(_ id: String, _ board: String, _ learner: String, _ opponent: String,
                                _ learnerCategory: Category, _ opponentCategory: Category,
                                _ outcome: Outcome, _ explanation: Copy, showFives: Bool = true,
                                includeTie: Bool = false) -> UnitBActivity {
        showdown(id, kind: .choice, board, learner, opponent, learnerCategory, opponentCategory,
                 outcome, winnerQuestion, compareFive, explanation,
                 showFives: showFives, includeTie: includeTie)
    }

    private static func showdown(_ id: String, kind: UnitBActivity.Kind, _ board: String,
                                 _ learner: String, _ opponent: String, _ learnerCategory: Category,
                                 _ opponentCategory: Category, _ outcome: Outcome,
                                 _ title: Copy, _ detail: Copy, _ explanation: Copy,
                                 showFives: Bool, includeTie: Bool) -> UnitBActivity {
        let sharedCards = cards(board, count: 5, id: id)
        let learnerCards = cards(learner, count: 2, id: id)
        let opponentCards = cards(opponent, count: 2, id: id)
        precondition(Set(sharedCards + learnerCards + opponentCards).count == 9,
                     "Duplicate cards in \(id)")
        let learnerSeven = learnerCards + sharedCards
        let opponentSeven = opponentCards + sharedCards
        precondition(bestHand(learnerSeven).category == learnerCategory.rawValue
                     && bestHand(opponentSeven).category == opponentCategory.rawValue,
                     "Wrong hand category in \(id)")
        let winner = compareHands(hero: learnerSeven, villain: opponentSeven)
        precondition(winner == outcome.rawValue, "Wrong showdown outcome in \(id)")
        let choices = kind == .choice ? winnerChoices + (includeTie ? [tieChoice] : []) : []
        precondition(kind == .example || choices.indices.contains(winner), "Missing answer in \(id)")
        return UnitBActivity(id: id, kind: kind, board: sharedCards, learner: learnerCards,
                             opponent: opponentCards, heading: title, instruction: detail,
                             choices: choices, correctChoice: kind == .choice ? winner : nil,
                             reason: explanation, showsBestFivesBeforeAnswer: showFives)
    }

    private static func five(_ id: String, _ board: String, _ learner: String,
                             _ category: Category, using expectedPrivateCount: Int,
                             example: Bool = false, _ title: Copy, _ explanation: Copy) -> UnitBActivity {
        let sharedCards = cards(board, count: 5, id: id)
        let learnerCards = cards(learner, count: 2, id: id)
        let seven = learnerCards + sharedCards
        precondition(Set(seven).count == 7, "Duplicate cards in \(id)")
        precondition(bestHand(seven).category == category.rawValue, "Wrong hand category in \(id)")
        let chosen = bestFiveCards(seven)
        precondition(chosen.filter(learnerCards.contains).count == expectedPrivateCount,
                     "Wrong private-card count in \(id)")
        return UnitBActivity(id: id, kind: example ? .example : .bestFive, board: sharedCards,
                             learner: learnerCards, opponent: [], heading: title,
                             instruction: example ? noCopy : pickFiveHelp, choices: [],
                             correctChoice: nil, reason: explanation,
                             showsBestFivesBeforeAnswer: example)
    }

    private static func cards(_ tokens: String, count: Int, id: String) -> [Card] {
        guard let parsed = Card.parse(tokens), parsed.count == count else {
            preconditionFailure("Invalid cards in \(id): \(tokens)")
        }
        return parsed
    }
}
