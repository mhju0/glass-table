// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// Saved answers use this order and these exact cards. Changes that replace the
/// meaning of an existing activity need a new content version.
enum UnitAContentV1 {
    static let version = 1

    static func activities(for lesson: UnitALesson) -> [UnitAActivity] {
        switch lesson {
        case .privateCards: privateCards
        case .rankAndSuit: rankAndSuit
        case .findPair: findPair
        case .streets: streets
        case .endings: endings
        }
    }

    private typealias Copy = UnitACopy
    private typealias Group = UnitACardGroup

    private static let privateCards: [UnitAActivity] = {
        let exampleOwn = cards("6h3c")
        let exampleBoard = cards("8s9sTsJsQs")
        let exampleBest = bestFiveCards(exampleOwn + exampleBoard)
        let board = cards("9hThJhQhKh")
        let own = cards("2c3d")
        let best = bestFiveCards(own + board)
        let countBoard = cards("3c7s8dTsKd")
        let countOwn = cards("AdQc")
        let countBest = Set(bestFiveCards(countOwn + countBoard))
        return [
            example("A1-example", Copy("카드는 두 곳에 놓여요", "Two places for cards"),
                    Copy("내 카드 두 장은 나만 써요. 공용 카드는 모두가 써요. 가장 강한 다섯 장이 내 패예요. 여기서는 공용 카드 다섯 장이 모두 쓰여요.",
                         "Only you can use your two cards. Everyone can use the shared cards. Your hand uses the strongest five. Here, all five are shared."),
                    [Group(role: .mine, cards: exampleOwn, highlighted: []),
                     Group(role: .shared, cards: exampleBoard, highlighted: exampleBest)]),
            question("A1-01", Copy("나만 쓸 수 있는 카드는?", "Which cards are yours alone?"),
                     [group(.mine, "Qh4c"), group(.shared, "2s5d8c")],
                     [Copy("내 카드", "My cards"), Copy("공용 카드", "Shared cards")], right: 0,
                     feedback: Copy("내 카드 두 장은 나만 쓸 수 있어요.", "Only you can use your two private cards."),
                     reveal: [group(.mine, "Qh4c", highlighted: "Qh4c"), group(.shared, "2s5d8c")]),
            question("A1-02", Copy("내 카드도 꼭 써야 할까요?", "Do you need your own cards here?"),
                     [Group(role: .mine, cards: own, highlighted: []),
                      Group(role: .shared, cards: board, highlighted: [])],
                     [Copy("필요해요", "Yes"), Copy("필요 없어요", "No")], right: 1,
                     body: Copy("이 예에서는 공용 카드가 가장 강한 다섯 장이에요.",
                                "Here, the shared cards already make the strongest five."),
                     feedback: Copy("가장 강한 다섯 장을 골라요. 그중 내 카드는 0장부터 2장까지 쓸 수 있어요.",
                                    "Your best five can include zero, one or two private cards."),
                     reveal: [Group(role: .mine, cards: own, highlighted: []),
                              Group(role: .shared, cards: board, highlighted: best)]),
            question("A1-03", Copy("몇 장으로 패를 만들까요?", "How many cards make your hand?"),
                     [Group(role: .mine, cards: countOwn, highlighted: []),
                      Group(role: .shared, cards: countBoard, highlighted: [])],
                     [Copy("7장", "Seven"), Copy("5장", "Five")], right: 1,
                     feedback: Copy("쓸 수 있는 카드 중 가장 강한 다섯 장으로 패를 만들어요.",
                                    "Your hand is the strongest five of the cards you can use."),
                     reveal: [Group(role: .mine, cards: countOwn, highlighted: countOwn.filter(countBest.contains)),
                              Group(role: .shared, cards: countBoard, highlighted: countBoard.filter(countBest.contains))]),
            question("A1-04", Copy("상대도 쓸 수 있는 카드는?", "Which cards can your opponent use too?"),
                     [group(.mine, "6sJd"), group(.shared, "4s7h9dKh")],
                     [Copy("공용 카드", "Shared cards"), Copy("내 카드", "My cards")], right: 0,
                     feedback: Copy("가운데 놓인 공용 카드는 모두 함께 써요.", "Everyone can use the shared cards in the middle."),
                     reveal: [group(.mine, "6sJd"), group(.shared, "4s7h9dKh", highlighted: "4s7h9dKh")])
        ]
    }()

    private static let rankAndSuit: [UnitAActivity] = [
        example("A2-example", Copy("카드의 숫자와 무늬", "Read a card"),
                Copy("숫자나 글자가 랭크예요.\nJ는 잭, Q는 퀸\nK는 킹, A는 에이스\n\n기호는 무늬예요.\n무늬끼리 강약은 없어요.",
                     "Numbers and letters show rank.\nJ = jack · Q = queen\nK = king · A = ace\n\nSymbols show suit.\nAll suits have equal strength."),
                [group(.example, "2c3d4h5s6c7d8h9sTcJdQhKsAc")]),
        question("A2-01", Copy("이 카드의 랭크는?", "What is the rank?"),
                 [group(.example, "Qd")], [Copy("퀸", "Queen"), Copy("다이아몬드", "Diamonds")], right: 0,
                 feedback: Copy("Q는 퀸이에요. 글자는 랭크를 나타내요.", "Q stands for queen. The letter tells you the rank.")),
        question("A2-02", Copy("이 카드의 무늬는?", "What is the suit?"),
                 [group(.example, "As")], [Copy("에이스", "Ace"), Copy("스페이드", "Spades")], right: 1,
                 feedback: Copy("♠는 스페이드예요. A는 에이스를 뜻해요.", "♠ means spades. A stands for ace.")),
        question("A2-03", Copy("더 강한 무늬가 있나요?", "Is one suit stronger?"),
                 [group(.example, "8s8h")], [Copy("스페이드", "Spades"), Copy("같아요", "Equal")], right: 1,
                 feedback: Copy("스페이드와 하트는 힘이 같아요. 무늬만으로 승부를 가리지 않아요.",
                                "Spades and hearts are equal. Suits cannot break a tie.")),
        question("A2-04", Copy("이 카드의 랭크는?", "What is the rank?"),
                 [group(.example, "Js")], [Copy("잭", "Jack"), Copy("스페이드", "Spades")], right: 0,
                 feedback: Copy("J는 잭이에요. ♠는 스페이드 무늬예요.", "J is jack. ♠ is the spade suit."))
    ]

    private static let findPair: [UnitAActivity] = [
        example("A3-example", Copy("6 두 장", "Two sixes"),
                Copy("숫자나 글자가 같으면 페어예요.\n무늬는 달라도 돼요.",
                     "A pair of sixes.\nSuits can differ."),
                [group(.example, "6h9c6s", highlighted: "6h6s")]),
        question("A3-01", Copy("어떤 페어가 있나요?", "Which cards make a pair?"),
                 [group(.example, "8cKh8d")], [Copy("8 두 장", "Two eights"), Copy("K 두 장", "Two kings")], right: 0,
                 feedback: Copy("8이 두 장이라 8 페어예요.", "The two eights make a pair."),
                 reveal: [group(.example, "8cKh8d", highlighted: "8c8d")]),
        question("A3-02", Copy("어떤 페어가 있나요?", "Which cards make a pair?"),
                 [group(.example, "Jc4hJsAh")], [Copy("A 두 장", "Two aces"), Copy("J 두 장", "Two jacks")], right: 1,
                 feedback: Copy("A는 한 장이고 J는 두 장이에요. J 페어가 있어요.", "There is one ace and there are two jacks. The jacks make the pair."),
                 reveal: [group(.example, "Jc4hJsAh", highlighted: "JcJs")]),
        question("A3-03", Copy("4 두 장은 어디에 있나요?", "Where are the two fours?"),
                 [group(.mine, "4dKd"), group(.shared, "2c4s9h")],
                 [Copy("한 줄에 한 장씩", "One in each row"), Copy("내 카드에 두 장", "Both in my cards")], right: 0,
                 feedback: Copy("내 카드에 4가 한 장, 공용 카드에 4가 한 장 있어요.", "You have one four and the shared cards have the other."),
                 reveal: [group(.mine, "4dKd", highlighted: "4d"), group(.shared, "2c4s9h", highlighted: "4s")]),
        question("A3-04", Copy("이 카드에 페어가 있나요?", "Is there a pair?"),
                 [group(.example, "AcJc6c")], [Copy("있어요", "Yes"), Copy("없어요", "No")], right: 1,
                 feedback: Copy("무늬는 같지만 숫자나 글자가 모두 달라요. 페어가 없어요.",
                                "The suits match. The ranks all differ, so there is no pair."))
    ]

    private static let streets: [UnitAActivity] = {
        let own = group(.mine, "3dKd")
        let board = cards("9c9h4sQdTc")
        func shown(_ count: Int) -> [Group] {
            let shared = Array(board.prefix(count))
            let new = Array(shared.suffix(count == 3 ? 3 : 1))
            return [own, Group(role: .shared, cards: shared, highlighted: new)]
        }
        return [
            example("A4-preflop", Copy("공용 카드를 놓기 전", "Before the shared cards"),
                    Copy("내 카드 두 장부터 받아요. 이때를 프리플랍이라고 해요.",
                         "You receive two private cards first. This stage is called preflop."), shown(0)),
            example("A4-flop", Copy("처음 세 장 · 플랍", "The flop"),
                    Copy("공용 카드 세 장을 한꺼번에 펼쳐요.", "The first three shared cards are dealt together."), shown(3)),
            example("A4-turn", Copy("네 번째 카드 · 턴", "The turn"),
                    Copy("공용 카드가 한 장 더 나와 네 장이 돼요.", "One more arrives. There are now four shared cards."), shown(4)),
            example("A4-river", Copy("마지막 카드 · 리버", "The river"),
                    Copy("마지막 공용 카드까지 다섯 장이 펼쳐져요.", "The final shared card brings the board to five."), shown(5)),
            question("A4-01", Copy("공용 카드가 세 장 나왔어요", "Three shared cards just arrived"),
                     [group(.mine, "3hJh"), group(.shared, "2s5d7h")],
                     [Copy("플랍", "Flop"), Copy("턴", "Turn")], right: 0,
                     body: Copy("지금은 어느 단계일까요?", "Which stage is this?"),
                     feedback: Copy("세 장이 처음으로 함께 나오는 단계가 플랍이에요.",
                                    "The first three shared cards come out together on the flop.")),
            question("A4-02", Copy("공용 카드가 아직 없어요", "There are no shared cards yet"),
                     [group(.mine, "4dTh"), group(.shared, "")],
                     [Copy("리버", "River"), Copy("프리플랍", "Preflop")], right: 1,
                     body: Copy("지금은 어느 단계일까요?", "Which stage is this?"),
                     feedback: Copy("공용 카드를 펼치기 전은 프리플랍이에요.", "Preflop is before any shared cards are dealt.")),
            question("A4-03", Copy("네 번째 카드가 나왔어요", "The fourth card just arrived"),
                     [group(.mine, "2dJs"), group(.shared, "5s8dKhAc")],
                     [Copy("리버", "River"), Copy("턴", "Turn")], right: 1,
                     body: Copy("지금은 어느 단계일까요?", "Which stage is this?"),
                     feedback: Copy("네 번째 공용 카드가 나오는 단계는 턴이에요.",
                                    "The fourth shared card comes out on the turn."),
                     reveal: [group(.mine, "2dJs"), group(.shared, "5s8dKhAc", highlighted: "Ac")]),
            question("A4-04", Copy("마지막 카드가 나왔어요", "The final card just arrived"),
                     [group(.mine, "6hJc"), group(.shared, "2s7c9hQsAd")],
                     [Copy("리버", "River"), Copy("플랍", "Flop")], right: 0,
                     body: Copy("지금은 어느 단계일까요?", "Which stage is this?"),
                     feedback: Copy("다섯 번째 공용 카드가 나오는 단계는 리버예요.", "The fifth shared card comes out on the river."),
                     reveal: [group(.mine, "6hJc"), group(.shared, "2s7c9hQsAd", highlighted: "Ad")])
        ]
    }()

    private static let endings: [UnitAActivity] = {
        let own = group(.mine, "As9d")
        let flop = group(.shared, "Ac7s3d")
        let board = group(.shared, "Ac7s3d4hJh")
        let opponent = group(.opponent, "QcTd")
        let best = Set(bestFiveCards(own.cards + board.cards))
        let winningCards = [own, board].map { group in
            Group(role: group.role, cards: group.cards, highlighted: group.cards.filter(best.contains))
        }
        return [
            example("A5-example", Copy("핸드가 끝나는 두 가지 방법", "Two ways a hand ends"),
                    Copy("모두 폴드하고 한 명만 남으면 그 사람이 이겨요. 끝까지 여럿이 남으면 카드를 펼쳐 비교해요. 이를 쇼다운이라고 해요.",
                         "If everyone else folds, the last player wins. When players stay to the end, they show their cards and compare hands. That is a showdown."),
                    []),
            UnitAActivity(id: "A5-branch", kind: .branch, cards: [own, flop],
                          heading: Copy("이 핸드는 어떻게 끝날까요?", "How does this hand end?"),
                          detail: Copy("보고 싶은 결말을 골라요.", "Pick an ending to see what happens."),
                          choices: [Copy("상대가 폴드", "Opponent folds"), Copy("둘 다 남아요", "Both stay in")],
                          rightIndex: nil,
                          responses: [
                              Copy("상대가 폴드했어요. 나만 남아서 이겼어요. 카드를 공개할 필요는 없어요.",
                                   "The opponent folds.\nYou win.\nYour cards stay private."),
                              Copy("둘 다 남아요.\n카드를 공개해요.\nA 페어가 이겨요.",
                                   "Both players stay through the river and show their cards. Your pair of aces wins this example.")
                          ],
                          revealGroups: [[own, flop], winningCards + [opponent]]),
            question("A5-01", Copy("나만 쓸 수 있는 카드는?", "Which cards are yours alone?"),
                     [group(.mine, "7hJd"), group(.shared, "2d4h8s")],
                     [Copy("공용 카드", "Shared cards"), Copy("내 카드", "My cards")], right: 1,
                     feedback: Copy("내 카드 두 장은 나만 쓸 수 있어요.", "Only you can use your two private cards."),
                     reveal: [group(.mine, "7hJd", highlighted: "7hJd"), group(.shared, "2d4h8s")]),
            question("A5-02", Copy("이 카드의 무늬는?", "What is the suit?"),
                     [group(.example, "Kh")], [Copy("하트", "Hearts"), Copy("킹", "King")], right: 0,
                     feedback: Copy("♥는 하트 무늬예요. K는 킹을 뜻해요.", "♥ is the heart suit. K stands for king.")),
            question("A5-03", Copy("어떤 페어가 있나요?", "Which cards make a pair?"),
                     [group(.example, "5cQd5hTs")], [Copy("Q 두 장", "Two queens"), Copy("5 두 장", "Two fives")], right: 1,
                     feedback: Copy("5가 두 장이라 5 페어예요.", "The two fives make a pair."),
                     reveal: [group(.example, "5cQd5hTs", highlighted: "5c5h")]),
            question("A5-04", Copy("네 번째 카드가 나왔어요", "The fourth card just arrived"),
                     [group(.mine, "3c7h"), group(.shared, "6h9sTdKs")],
                     [Copy("턴", "Turn"), Copy("리버", "River")], right: 0,
                     body: Copy("지금은 어느 단계일까요?", "Which stage is this?"),
                     feedback: Copy("네 번째 공용 카드가 나오는 단계는 턴이에요.",
                                    "The fourth shared card comes out on the turn."),
                     reveal: [group(.mine, "3c7h"), group(.shared, "6h9sTdKs", highlighted: "Ks")])
        ]
    }()

    private static func cards(_ tokens: String) -> [Card] {
        guard let cards = Card.parse(tokens) else {
            preconditionFailure("Invalid Unit A card tokens: \(tokens)")
        }
        return cards
    }

    private static func group(_ role: Group.Role, _ tokens: String, highlighted: String = "") -> Group {
        Group(role: role, cards: cards(tokens), highlighted: cards(highlighted))
    }

    private static func example(_ id: String, _ title: Copy, _ body: Copy, _ groups: [Group]) -> UnitAActivity {
        UnitAActivity(id: id, kind: .example, cards: groups, heading: title, detail: body, choices: [],
                      rightIndex: nil, responses: [], revealGroups: [])
    }

    private static func question(_ id: String, _ title: Copy, _ groups: [Group], _ options: [Copy], right: Int,
                                 body: Copy = Copy("", ""), feedback: Copy, reveal: [Group]? = nil) -> UnitAActivity {
        UnitAActivity(id: id, kind: .question, cards: groups, heading: title, detail: body, choices: options,
                      rightIndex: right, responses: [feedback], revealGroups: reveal.map { [$0] } ?? [])
    }
}
