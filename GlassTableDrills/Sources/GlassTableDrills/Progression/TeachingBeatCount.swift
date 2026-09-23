// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

/// The walkthrough player's beat source is the same BeatScript used here. This is
/// checked only while accepting disk/import bytes, not on every draft autosave.
enum TeachingBeatCount {
    static func count(_ concept: Concept, seed: UInt64) -> Int {
        switch concept {
        case .showdown: return BeatScript.showdown(
            ShowdownSpotGenerator.spot(baseSeed: seed, index: 0)).count
        case .potMath: return BeatScript.potMath(
            PotMathSpotGenerator.spot(baseSeed: seed, index: 0)).count
        case .position: return BeatScript.position(
            PositionSpotGenerator.spot(baseSeed: seed, index: 0)).count
        case .combos: return BeatScript.combos(
            BlockerSpotGenerator.spot(baseSeed: seed, index: 0)).count
        case .potOdds: return BeatScript.potOdds(
            BetSpotGenerator.spot(baseSeed: seed, index: 0)).count
        case .mdf: return BeatScript.mdf(
            BetSpotGenerator.spot(baseSeed: seed, index: 0)).count
        case .outs: return BeatScript.outs(
            OutsSpotGenerator.spot(baseSeed: seed, index: 0)).count
        case .equitySense: return BeatScript.equitySense(
            EquitySenseSpotGenerator.spot(baseSeed: seed, index: 0)).count
        case .evCall: return BeatScript.evCall(
            EVCallSpotGenerator.spot(baseSeed: seed, index: 0)).count
        case .callFold: return BeatScript.callFold(
            CallFoldSpotGenerator.spot(baseSeed: seed, index: 0)).count
        case .rangeNotation: return BeatScript.rangeNotation(
            RangeNotationSpotGenerator.spot(baseSeed: seed, index: 0)).count
        case .rfi: return BeatScript.rfi(
            RFISpotGenerator.spot(baseSeed: seed, index: 0)).count
        case .rangeRead: return BeatScript.rangeRead(
            RangeReadSpotGenerator.spot(baseSeed: seed, index: 0)).count
        case .hitFrequency: return BeatScript.hitFrequency(
            HitFrequencySpotGenerator.spot(baseSeed: seed, index: 0)).count
        case .rangeAdvantage: return BeatScript.rangeAdvantage(
            RangeAdvantageSpotGenerator.spot(baseSeed: seed, index: 0)).count
        case .evLoss: return BeatScript.evLoss(
            EVLossSpotGenerator.spot(baseSeed: seed, index: 0)).count
        case .actionRead: return BeatScript.actionRead(
            ActionReadSpotGenerator.spot(baseSeed: seed, index: 0)).count
        case .defend: return BeatScript.defend(
            DefendSpotGenerator.spot(baseSeed: seed, index: 0)).count
        }
    }
}
