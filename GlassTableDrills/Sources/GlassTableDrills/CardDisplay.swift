// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

public extension Card {
    /// User-facing card name: "10♥", "A♠".
    ///
    /// `Card.description` ("Th", "As") is the **parse round-trip format** — it exists
    /// so `Card.parse` can read it back, and test fixtures are written in it. It is
    /// not copy. Anything a reader sees uses this instead, so a card is spelled the
    /// same way in a sentence as it is on the card face.
    var display: String { "\(Card.displayRanks[rank - 2])\(Card.displaySuits[suit])" }

    /// Korean suit name, for prose that talks about a suit rather than a card.
    var suitKorean: String { Card.suitNames[suit] }

    internal static let displayRanks =
        ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
    internal static let displaySuits = ["♣", "♦", "♥", "♠"]
    internal static let suitNames = ["클럽", "다이아", "하트", "스페이드"]
}

/// Korean suit name from a raw suit index, for scripts that only carry the index.
public func suitKoreanName(_ suit: Int) -> String { Card.suitNames[suit] }
