// Copyright (c) 2026 Michael Ju (github.com/mhju0)
// All calculations are rake-free.

/// Minimum equity needed to profitably call. `pot` includes villain's bet.
public func requiredEquity(toCall: Double, pot: Double) -> Double {
    guard pot + toCall > 0 else { return 0 }
    return toCall / (pot + toCall)
}

public func callIsProfitable(equity: Double, toCall: Double, pot: Double) -> Bool {
    equity >= requiredEquity(toCall: toCall, pot: pot)
}

/// EV of calling vs folding: win `pot` with prob `equity`, lose `toCall` otherwise.
public func callEV(equity: Double, toCall: Double, pot: Double) -> Double {
    equity * pot - (1 - equity) * toCall
}

/// Minimum defense frequency vs a bet of `bet` into `pot`.
public func mdf(bet: Double, pot: Double) -> Double {
    guard pot + bet > 0 else { return 0 }
    return pot / (pot + bet)
}
