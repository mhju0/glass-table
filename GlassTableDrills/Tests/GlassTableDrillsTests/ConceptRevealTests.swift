// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Testing
@testable import GlassTableDrills

/// The input each concept's question submits. A live reveal has no text of its own,
/// so every one of these must produce a reveal.
private func liveInput(_ concept: Concept) -> SavedDrillInput {
    switch concept {
    case .showdown, .position: .integer(1)
    case .potMath, .outs, .combos, .rangeNotation: .integer(8)
    case .potOdds, .mdf: .integer(30)
    case .callFold, .rfi, .evLoss: .boolean(true)
    case .rangeRead: .rangeBand(width: 30, excludedTop: 4, tendencies: [])
    case .defend: .action(DefendAction.call.rawValue)
    case .evCall: .interval(point: 1, lo: -2, hi: 4)
    case .equitySense, .hitFrequency, .rangeAdvantage, .actionRead: .interval(point: 40, lo: 30, hi: 55)
    }
}

@Test func everyConceptRevealsItsLiveAnswerInBothLanguages() throws {
    for concept in Concept.allCases {
        for seed in UInt64(0)..<20 {
            for language in [LearningLanguage.korean, .english] {
                let reveal = try #require(ConceptReveal(concept: concept, seed: seed, index: 1,
                                                        input: liveInput(concept), openerEquityPct: 55,
                                                        language: language), "\(concept)")
                #expect(!reveal.mine.isEmpty && !reveal.correct.isEmpty && !reveal.why.isEmpty)
                if language == .english {
                    #expect(!reveal.mine.contains(where: { ("가"..."힣").contains(String($0)) }), "\(concept): \(reveal.mine)")
                    #expect(!reveal.correct.contains(where: { ("가"..."힣").contains(String($0)) }), "\(concept): \(reveal.correct)")
                }
            }
        }
    }
}

@Test func mismatchedInputHasNoReveal() {
    #expect(ConceptReveal(concept: .callFold, seed: 1, index: 0, input: .integer(3), language: .english) == nil)
    #expect(ConceptReveal(concept: .defend, seed: 1, index: 0, input: .action("bogus"), language: .english) == nil)
    #expect(ConceptReveal(concept: .rangeAdvantage, seed: 1, index: 0,
                          input: .interval(point: 40, lo: 30, hi: 55), language: .english) == nil,
            "Without the saved truth a range-advantage answer cannot be judged.")
}

/// A learner who was never shown the 90% range must not be told how it did.
@Test func estimateRevealLeavesTheRangeOutWhenItWasNotAsked() throws {
    for language in [LearningLanguage.korean, .english] {
        let input = SavedDrillInput.interval(point: 60, lo: 48, hi: 72)
        let asked = try #require(ConceptReveal(concept: .actionRead, seed: 7, index: 0, input: input,
                                               language: language, namesRange: true))
        let plain = try #require(ConceptReveal(concept: .actionRead, seed: 7, index: 0, input: input,
                                               language: language, namesRange: false))
        let marker = language == .korean ? "구간" : "90% range"
        #expect(asked.why.contains(marker))
        #expect(!plain.why.contains(marker))
        #expect(asked.why.hasPrefix(plain.why))
        let unknown = try #require(ConceptReveal(concept: .actionRead, seed: 7, index: 0, input: input, language: language))
        #expect(unknown.why == plain.why, "Changing level must not invent confidence provenance.")
    }
}

@Test func seatLabelsNumberAndNameEachSeatOnOneLine() {
    #expect(Position.utg.seatLabel(in: .english) == "1 · First seat")
    #expect(Position.co.seatLabel(in: .korean) == "5 · 딜러 앞 자리")
    #expect(Position.bb.seatNumber == 8)
}
