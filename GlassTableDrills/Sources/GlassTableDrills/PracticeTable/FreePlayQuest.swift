// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

public struct FreePlayQuest: Codable, Equatable, Sendable {
    public static let target = 2

    public struct Response: Codable, Equatable, Sendable {
        public let handID: String
        /// Nil records an explicit skip or a review that has already shown the answer.
        public let category: Int?
    }

    public private(set) var correct = 0
    public private(set) var response: Response?

    public init() {}

    public var isComplete: Bool { correct == Self.target }

    @discardableResult
    public mutating func resolve(_ category: Int?, table: PracticeTableState) -> Bool {
        guard !isComplete, response == nil, let question = FreePlayQuestQuestion(table),
              category.map(question.choices.contains) ?? true else { return false }
        response = Response(handID: table.handID, category: category)
        if category == question.hand.category { correct += 1 }
        return true
    }

    public mutating func beginNextHand() { response = nil }

    func isValid(for table: PracticeTableState) -> Bool {
        guard (0...Self.target).contains(correct) else { return false }
        guard let response else { return correct <= table.handNumber }
        guard response.handID == table.handID, let question = FreePlayQuestQuestion(table),
              response.category.map(question.choices.contains) ?? true else { return false }
        let creditedHere = response.category == question.hand.category
        return creditedHere ? correct > 0 && correct - 1 <= table.handNumber
            : !isComplete && correct <= table.handNumber
    }
}

public struct FreePlayQuestQuestion {
    public let hand: HandBrief
    public let board: [Card]
    public let hole: [Card]
    public let choices: [Int]

    public init?(_ table: PracticeTableState) {
        guard let review = table.review, review.board.count == 5,
              review.pots.contains(where: { $0.eligibleSeats.count > 1 && $0.eligibleSeats.contains(0) }),
              let rawHole = review.holeCards.first,
              let board = Card.parse(review.board.joined()), board.count == 5,
              let hole = Card.parse(rawHole.joined()), hole.count == 2 else { return nil }
        self.board = board
        self.hole = hole
        let hand = bestHand(board + hole)
        self.hand = hand
        let firstCategory = min(6, max(0, hand.category - 1))
        var choices = Array(firstCategory...firstCategory + 2).filter { $0 != hand.category }
        choices.insert(hand.category, at: Int((table.seed &+ UInt64(table.handNumber)) % 3))
        self.choices = choices
    }
}
