import Foundation
import Testing
import GlassTableEngine
@testable import GlassTableDrills

struct LearningLanguageTests {
    @Test func everyConceptHasEnglishWorkedExample() {
        let seed: UInt64 = 19
        let bet = BetSpotGenerator.spot(baseSeed: seed, index: 0)
        let examples: [(Concept, [Beat])] = [
            (.showdown, BeatScript.showdown(ShowdownSpotGenerator.spot(baseSeed: seed, index: 0), language: .english)),
            (.potMath, BeatScript.potMath(PotMathSpotGenerator.spot(baseSeed: seed, index: 0), language: .english)),
            (.position, BeatScript.position(PositionSpotGenerator.spot(baseSeed: seed, index: 0), language: .english)),
            (.combos, BeatScript.combos(BlockerSpotGenerator.spot(baseSeed: seed, index: 0), language: .english)),
            (.potOdds, BeatScript.potOdds(bet, language: .english)),
            (.outs, BeatScript.outs(OutsSpotGenerator.spot(baseSeed: seed, index: 0), language: .english)),
            (.equitySense, BeatScript.equitySense(EquitySenseSpotGenerator.spot(baseSeed: seed, index: 0), language: .english)),
            (.evCall, BeatScript.evCall(EVCallSpotGenerator.spot(baseSeed: seed, index: 0), language: .english)),
            (.callFold, BeatScript.callFold(CallFoldSpotGenerator.spot(baseSeed: seed, index: 0), language: .english)),
            (.rangeNotation, BeatScript.rangeNotation(RangeNotationSpotGenerator.spot(baseSeed: seed, index: 0), language: .english)),
            (.rfi, BeatScript.rfi(RFISpotGenerator.spot(baseSeed: seed, index: 0), language: .english)),
            (.rangeRead, BeatScript.rangeRead(RangeReadSpotGenerator.spot(baseSeed: seed, index: 0), language: .english)),
            (.hitFrequency, BeatScript.hitFrequency(HitFrequencySpotGenerator.spot(baseSeed: seed, index: 0), language: .english)),
            (.rangeAdvantage, BeatScript.rangeAdvantage(RangeAdvantageSpotGenerator.spot(baseSeed: seed, index: 0), language: .english)),
            (.evLoss, BeatScript.evLoss(EVLossSpotGenerator.spot(baseSeed: seed, index: 0), language: .english)),
            (.actionRead, BeatScript.actionRead(ActionReadSpotGenerator.spot(baseSeed: seed, index: 0), language: .english)),
            (.defend, BeatScript.defend(DefendSpotGenerator.spot(baseSeed: seed, index: 0), language: .english)),
            (.mdf, BeatScript.mdf(bet, language: .english)),
        ]
        #expect(Set(examples.map(\.0)) == Set(Concept.allCases))
        for (concept, beats) in examples {
            #expect(!beats.isEmpty, "\(concept)")
            for beat in beats {
                let copy = [beat.caption, beat.value ?? "", beat.detail ?? ""].joined(separator: " ")
                #expect(!copy.isEmpty, "\(concept)")
                #expect(copy.range(of: #"[가-힣]"#, options: .regularExpression) == nil,
                        "\(concept): \(copy)")
            }
        }
    }

    @Test func localizedGradesKeepTheSameFactsAndOutcome() {
        let showdown = FirstLesson.example
        let ko = gradeShowdown(answer: 0, spot: showdown)
        let en = gradeShowdown(answer: 0, spot: showdown, language: .english)
        #expect(ko.band == en.band)
        #expect(ko.winner == en.winner)
        #expect(en.whyText.contains("beats"))
        #expect(en.heroName.contains("Pair"))

        let pot = PotMathSpot(actions: [.blinds(sb: 1, bb: 2),
                                        .raiseTo(actor: .opener, total: 5, alreadyIn: 0),
                                        .call(actor: .bb, amount: 3)], question: .potNow)
        let potKO = gradePotMath(answer: pot.correctAnswer, spot: pot)
        let potEN = gradePotMath(answer: pot.correctAnswer, spot: pot, language: .english)
        #expect(potKO.correct == potEN.correct)
        #expect(potKO.band == potEN.band)
        #expect(potEN.whyText.contains("raises"))
        #expect(potEN.whyText.contains("Pot now: \(pot.pot) chips"))
    }

    @Test func englishTerminologyUsesSemanticCategories() {
        #expect(DrillTerms.madeHand(.draw, in: .english) == "Draw")
        #expect(DrillTerms.action(.threeBet, in: .english) == "Raise again")
        #expect(DrillTerms.tendency(.connectors, in: .english) == "Neighboring ranks")
        #expect(DrillTerms.suit(2, in: .english) == "hearts")
        #expect(DrillTerms.hand(FirstLesson.example.heroBest, in: .english).contains("Pair"))
    }

    @Test func everyConceptHasAnEnglishReveal() {
        let seed: UInt64 = 23
        let estimate = Estimate(point: 50, lo: 40, hi: 60)
        let bet = BetSpotGenerator.spot(baseSeed: seed, index: 0)
        let pot = PotMathSpotGenerator.spot(baseSeed: seed, index: 0)
        let rangeAdvantage = RangeAdvantageSpotGenerator.spot(baseSeed: seed, index: 0)
        let examples: [(Concept, String)] = [
            (.showdown, gradeShowdown(answer: 0, spot: ShowdownSpotGenerator.spot(baseSeed: seed, index: 0), language: .english).whyText),
            (.potMath, gradePotMath(answer: pot.correctAnswer, spot: pot, language: .english).whyText),
            (.position, gradePosition(answer: 0, spot: PositionSpotGenerator.spot(baseSeed: seed, index: 0), language: .english).whyText),
            (.combos, gradeBlocker(estimate: 0, spot: BlockerSpotGenerator.spot(baseSeed: seed, index: 0), language: .english).whyText),
            (.potOdds, gradePotOdds(estimatePct: 50, spot: bet, language: .english).whyText),
            (.outs, gradeOuts(estimate: 0, spot: OutsSpotGenerator.spot(baseSeed: seed, index: 0), language: .english).whyText),
            (.equitySense, gradeEquitySense(estimate: estimate, spot: EquitySenseSpotGenerator.spot(baseSeed: seed, index: 0), language: .english).whyText),
            (.evCall, gradeEVCall(estimate: estimate, spot: EVCallSpotGenerator.spot(baseSeed: seed, index: 0), language: .english).whyText),
            (.callFold, gradeCallFold(userCalls: true, spot: CallFoldSpotGenerator.spot(baseSeed: seed, index: 0), language: .english).whyText),
            (.rangeNotation, gradeRangeNotation(estimate: 0, spot: RangeNotationSpotGenerator.spot(baseSeed: seed, index: 0), language: .english).whyText),
            (.rfi, gradeRFI(userOpens: true, spot: RFISpotGenerator.spot(baseSeed: seed, index: 0), language: .english).whyText),
            (.rangeRead, gradeRangeRead(estimate: RangeEstimate(width: 30), spot: RangeReadSpotGenerator.spot(baseSeed: seed, index: 0), language: .english).whyText),
            (.hitFrequency, gradeHitFrequency(estimate: estimate, spot: HitFrequencySpotGenerator.spot(baseSeed: seed, index: 0), language: .english).whyText),
            (.rangeAdvantage, gradeRangeAdvantage(estimate: estimate, spot: rangeAdvantage,
                                                   openerEquityPct: rangeAdvantage.openerEquityPct,
                                                   language: .english).whyText),
            (.evLoss, gradeEVLoss(userCalls: true, spot: EVLossSpotGenerator.spot(baseSeed: seed, index: 0), language: .english).whyText),
            (.actionRead, gradeActionRead(estimate: estimate, spot: ActionReadSpotGenerator.spot(baseSeed: seed, index: 0), language: .english).whyText),
            (.defend, gradeDefend(chosen: .call, spot: DefendSpotGenerator.spot(baseSeed: seed, index: 0), language: .english).whyText),
            (.mdf, gradeMDF(estimatePct: 50, spot: bet, language: .english).whyText),
        ]
        #expect(Set(examples.map(\.0)) == Set(Concept.allCases))
        for (concept, copy) in examples {
            #expect(!copy.isEmpty, "\(concept)")
            #expect(copy.range(of: #"[가-힣]"#, options: .regularExpression) == nil,
                    "\(concept): \(copy)")
        }
    }
}
