// Copyright (c) 2026 Michael Ju

/// River cards that turn a currently-losing hero into a winner, vs a known villain,
/// on a 4-card board. An "out" is a card after which hero7 > villain7.
public func countOuts(hero: [Card], villain: [Card], board: [Card]) -> [Card] {
    precondition(board.count == 4)
    let known = Set(hero + villain + board)
    let remaining = Deck.all.filter { !known.contains($0) }
    var outs: [Card] = []
    for river in remaining {
        let full = board + [river]
        if evaluate7(hero + full) > evaluate7(villain + full) {
            outs.append(river)
        }
    }
    return outs
}

/// Classic rule-of-2 (one card to come) / rule-of-4 (two cards) equity estimate, as a percent.
public func ruleOf2or4(outs: Int, cardsToCome: Int) -> Double {
    Double(outs) * (cardsToCome == 2 ? 4.0 : 2.0)
}
