// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest
import GlassTableEngine
@testable import GlassTableDrills

/// What the later steps of outs, equity, pot odds and the three "Go deeper" skills deal
/// (D53). The first step of each is frozen by `LearnSpotGoldenTests`.
final class StepLevelMathSpotTests: XCTestCase {
    private let seeds: [UInt64] = [0, 7, 0x9E37_79B9_7F4A_7C15, 123_456_789]
    private let skills: [Concept] = [.outs, .equitySense, .potOdds, .combos, .rangeNotation, .evCall]

    func testTheSixSkillsHaveThreeStepsAndAHeadlineForEach() {
        for concept in skills {
            XCTAssertEqual(DrillLevel.highest(for: concept), .sharp, concept.rawValue)
            for level in [DrillLevel.apply, .sharp] {
                for language in [LearningLanguage.korean, .english] {
                    XCTAssertNotNil(level.headline(for: concept, in: language), "\(concept) \(level) \(language)")
                }
            }
        }
    }

    func testCountsAreTypedAtTheThirdStepOnly() {
        for concept in [Concept.outs, .combos, .rangeNotation] {
            XCTAssertTrue(DrillLevel.sharp.typesExactAnswer(concept), concept.rawValue)
            XCTAssertFalse(DrillLevel.apply.typesExactAnswer(concept), concept.rawValue)
        }
        for concept in [Concept.equitySense, .potOdds, .evCall] {
            XCTAssertFalse(DrillLevel.sharp.typesExactAnswer(concept), "percentages and EV stay picked or stepped")
        }
    }

    func testLaterStepsDealFromTheirOwnStream() {
        XCTAssertNotEqual(OutsSpotGenerator.spot(baseSeed: 7, index: 2, level: .apply),
                          OutsSpotGenerator.spot(baseSeed: 7, index: 2))
        XCTAssertNotEqual(EquitySenseSpotGenerator.spot(baseSeed: 7, index: 2, level: .apply),
                          EquitySenseSpotGenerator.spot(baseSeed: 7, index: 2))
        XCTAssertNotEqual(BetSpotGenerator.spot(baseSeed: 7, index: 2, level: .sharp),
                          BetSpotGenerator.spot(baseSeed: 7, index: 2))
        XCTAssertNotEqual(BlockerSpotGenerator.spot(baseSeed: 7, index: 2, level: .apply),
                          BlockerSpotGenerator.spot(baseSeed: 7, index: 2))
        XCTAssertNotEqual(RangeNotationSpotGenerator.spot(baseSeed: 7, index: 2, level: .apply),
                          RangeNotationSpotGenerator.spot(baseSeed: 7, index: 2))
        XCTAssertNotEqual(EVCallSpotGenerator.spot(baseSeed: 7, index: 2, level: .apply),
                          EVCallSpotGenerator.spot(baseSeed: 7, index: 2))
        XCTAssertEqual(BetSpotGenerator.spot(baseSeed: 7, index: 2).callers, 0)
    }

    // MARK: Outs

    func testLaterOutsSpotsHaveExcludedCardsOrOutsOfTwoHandTypes() {
        for level in [DrillLevel.apply, .sharp] {
            var excluded = 0, mixed = 0
            for seed in seeds {
                for index in 0..<30 {
                    let spot = OutsSpotGenerator.spot(baseSeed: seed, index: index, level: level)
                    XCTAssertEqual(spot.outs, countOuts(hero: spot.hero, villain: spot.villain, board: spot.board))
                    XCTAssertTrue((2...15).contains(spot.outCount), "\(seed)/\(index)")
                    let kinds = OutsOutcomeGroups.make(hero: spot.hero, villain: spot.villain,
                                                       board: spot.board, candidates: spot.outs).count
                    XCTAssertTrue(!spot.excluded.isEmpty || kinds >= 2, "\(level) \(seed)/\(index)")
                    if !spot.excluded.isEmpty { excluded += 1 }
                    if kinds >= 2 { mixed += 1 }
                }
            }
            XCTAssertGreaterThan(excluded, 0, "\(level)")
            XCTAssertGreaterThan(mixed, 0, "\(level)")
        }
    }

    /// Four distinct counts all within ±2 would always put the answer second or third, so
    /// the four are neighbours (within ±3) with the answer anywhere among them.
    func testApplyOutsChoicesAreFourNeighbouringCounts() {
        var positions = Set<Int>()
        for seed in UInt64(0)..<200 {
            let answer = Int(seed % 14) + 2
            let choices = BeginnerQuestionChoices.integers(answer: answer, bounds: 0...46, seed: seed, level: .apply)
            XCTAssertEqual(choices.count, 4)
            XCTAssertEqual(Set(choices).count, 4)
            XCTAssertTrue(choices.contains(answer))
            XCTAssertEqual(choices.max()! - choices.min()!, 3, "neighbours: \(choices) for \(answer)")
            choices.sorted().firstIndex(of: answer).map { positions.insert($0) }
        }
        XCTAssertEqual(positions, [0, 1, 2, 3], "the answer is not always in one place")
        XCTAssertEqual(BeginnerQuestionChoices.integers(answer: 9, bounds: 0...46, seed: 3, level: .learn),
                       BeginnerQuestionChoices.integers(answer: 9, bounds: 0...46, seed: 3))
    }

    // MARK: Equity

    func testLaterEquitySpotsAreBetweenTwentyFiveAndSeventyFive() {
        for level in [DrillLevel.apply, .sharp] {
            for seed in seeds {
                for index in 0..<12 {
                    let equity = EquitySenseSpotGenerator.spot(baseSeed: seed, index: index, level: level).equityPct
                    XCTAssertTrue((25...75).contains(equity), "\(level) \(seed)/\(index): \(equity)")
                }
            }
        }
    }

    func testEquityChoicesNarrowWithTheStep() {
        for (level, gaps) in [(DrillLevel.apply, Set([10.0])), (.sharp, Set([5.0, 6.0]))] {
            var positions = Set<Int>()
            for seed in UInt64(0)..<120 {
                let answer = 25 + Double(seed % 51) + 0.3
                let choices = BeginnerQuestionChoices.percentages(answer: answer, seed: seed, level: level)
                XCTAssertEqual(choices.count, 4)
                let sorted = choices.sorted()
                let steps = Set(zip(sorted, sorted.dropFirst()).map { $1 - $0 })
                XCTAssertEqual(steps.count, 1, "evenly spaced: \(sorted)")
                XCTAssertTrue(steps.isSubset(of: gaps), "\(level) \(sorted)")
                XCTAssertTrue(choices.allSatisfy { (0...100).contains($0) })
                let spotOn = choices.filter { abs($0 - answer) <= 4 }
                XCTAssertEqual(spotOn, [answer.rounded()], "exactly one choice is spot-on")
                sorted.firstIndex(of: answer.rounded()).map { positions.insert($0) }
            }
            XCTAssertEqual(positions, [0, 1, 2, 3], "\(level)")
        }
        XCTAssertEqual(BeginnerQuestionChoices.percentages(answer: 41, seed: 3, level: .learn),
                       BeginnerQuestionChoices.percentages(answer: 41, seed: 3))
    }

    // MARK: Pot odds

    func testApplyPotOddsAddsQuarterAndDoubleBets() {
        var quarter = 0, double = 0
        for seed in seeds {
            for index in 0..<80 {
                let spot = BetSpotGenerator.spot(baseSeed: seed, index: index, level: .apply)
                XCTAssertEqual(spot.callers, 0)
                let ratio = Double(spot.bet) / Double(spot.pot)
                // The first step's smallest bet is a third and its largest one and a half.
                if ratio < 0.3 { quarter += 1 }
                if ratio > 1.9 { double += 1 }
            }
        }
        XCTAssertGreaterThan(quarter, 0)
        XCTAssertGreaterThan(double, 0)
    }

    func testSharpPotOddsHasACallerAlreadyIn() {
        for seed in seeds {
            for index in 0..<20 {
                let spot = BetSpotGenerator.spot(baseSeed: seed, index: index, level: .sharp)
                XCTAssertEqual(spot.callers, 1)
                let price = Double(spot.bet) / Double(spot.pot + 3 * spot.bet) * 100
                XCTAssertEqual(spot.requiredPct, price, accuracy: 1e-9, "the caller's chips are in the pot")
                let reveal = gradePotOdds(estimatePct: Int(price.rounded()), spot: spot, language: .english)
                XCTAssertEqual(reveal.band, .spotOn)
                XCTAssertTrue(reveal.whyText.contains("earlier call \(spot.bet)"), reveal.whyText)
                let korean = gradePotOdds(estimatePct: 0, spot: spot, language: .korean)
                XCTAssertTrue(korean.whyText.contains("먼저 한 콜 \(spot.bet)"), korean.whyText)
            }
        }
        let headsUp = BetSpot(pot: 10, bet: 5)
        XCTAssertEqual(headsUp.requiredPct, 25, accuracy: 1e-9)
        XCTAssertEqual(gradePotOdds(estimatePct: 25, spot: headsUp, language: .english).whyText,
                       "Call 5 ÷ (pot 10 + bet 5 + your call 5) = 25%.", "a heads-up price reads as before")
    }

    func testPotOddsChoicesNarrowWithTheStep() {
        for (level, count, gap) in [(DrillLevel.apply, 3, 10), (.sharp, 4, 5)] {
            var positions = Set<Int>()
            for seed in UInt64(0)..<120 {
                let answer = 10 + Double(seed % 35) + 0.4
                let choices = BeginnerQuestionChoices.shares(answer: answer, seed: seed, level: level)
                XCTAssertEqual(choices.count, count)
                let sorted = choices.sorted()
                XCTAssertTrue(zip(sorted, sorted.dropFirst()).allSatisfy { $1 - $0 == gap }, "\(sorted)")
                let spotOn = choices.filter { abs(Double($0) - answer) <= 2.5 }
                XCTAssertEqual(spotOn, [Int(answer.rounded())])
                sorted.firstIndex(of: Int(answer.rounded())).map { positions.insert($0) }
            }
            XCTAssertEqual(positions.count, count, "\(level)")
        }
        XCTAssertEqual(BeginnerQuestionChoices.shares(answer: 33.3, seed: 4, level: .learn),
                       BeginnerQuestionChoices.shares(answer: 33.3, seed: 4))
    }

    // MARK: Combos

    func testLaterCombosShowFourToSixCardsAndDifferentSuitHands() {
        for level in [DrillLevel.apply, .sharp] {
            var offsuit = 0
            for seed in seeds {
                for index in 0..<40 {
                    let spot = BlockerSpotGenerator.spot(baseSeed: seed, index: index, level: level)
                    XCTAssertTrue((4...6).contains(spot.removed.count), "\(level) \(seed)/\(index)")
                    XCTAssertEqual(Set(spot.removed).count, spot.removed.count)
                    XCTAssertEqual(spot.count, comboCount(rankA: spot.rankA, rankB: spot.rankB,
                                                          kind: spot.kind, removed: Set(spot.removed)))
                    XCTAssertTrue(spot.removed.contains { $0.rank == spot.rankA || $0.rank == spot.rankB })
                    if spot.kind == .offsuit { offsuit += 1 }
                }
            }
            XCTAssertGreaterThan(offsuit, 0, "\(level)")
        }
    }

    func testADifferentSuitHandIsNamedAndExplained() {
        let removed: [Card] = [Card(rank: 14, suit: 0), Card(rank: 13, suit: 0), Card(rank: 13, suit: 1)]
        let count = comboCount(rankA: 14, rankB: 13, kind: .offsuit, removed: Set(removed))
        let spot = BlockerSpot(rankA: 14, rankB: 13, kind: .offsuit, removed: removed, count: count)
        XCTAssertEqual(spot.className, "AKo")
        XCTAssertEqual(spot.baseline, 12)
        // 3 aces × 2 kings, less the 2 suits that still hold both.
        XCTAssertEqual(count, 4)
        XCTAssertEqual(gradeBlocker(estimate: 4, spot: spot, language: .english).whyText,
                       "3 A cards × 2 K cards = 6, less 2 with the same suit = 4 combinations.")
        XCTAssertEqual(gradeBlocker(estimate: 4, spot: spot, language: .korean).whyText,
                       "A 3장 × K 2장 = 6, 같은 무늬 2개를 빼면 4 콤보")
    }

    // MARK: Range notation

    func testLaterNotationHasThreeOrFourPartsThatDoNotOverlap() {
        var lengths = Set<Int>()
        for level in [DrillLevel.apply, .sharp] {
            for seed in seeds {
                for index in 0..<40 {
                    let spot = RangeNotationSpotGenerator.spot(baseSeed: seed, index: index, level: level)
                    let parts = spot.notation.components(separatedBy: ", ")
                    lengths.insert(parts.count)
                    XCTAssertTrue((3...4).contains(parts.count), spot.notation)
                    let counted = parts.reduce(0) { $0 + Int((try? RangeNotation.parse($1))?.comboCount ?? -1000) }
                    XCTAssertEqual(counted, spot.comboCount, "each part counts once: \(spot.notation)")
                    XCTAssertEqual(spot.range, try RangeNotation.parse(spot.notation))
                }
            }
        }
        XCTAssertEqual(lengths, [3, 4])
    }

    // MARK: EV call

    func testApplyEVChoicesAreFourOneBigBlindApartOffCentre() {
        var positions = Set<Int>()
        for seed in UInt64(0)..<200 {
            let spot = EVCallSpotGenerator.spot(baseSeed: seed, index: 2, level: .apply)
            let choices = BeginnerQuestionChoices.evValues(answer: spot.evBB, bet: spot.bet, seed: seed)
            XCTAssertEqual(choices.count, 4)
            let sorted = choices.sorted()
            XCTAssertTrue(zip(sorted, sorted.dropFirst()).allSatisfy { $1 - $0 == 1 }, "\(sorted)")
            XCTAssertTrue(choices.allSatisfy { $0 >= -Double(spot.bet) }, "a call cannot lose more than the bet")
            let estimate = { (v: Double) in Estimate(point: v, lo: v - 1, hi: v + 1) }
            let spotOn = choices.filter { gradeEVCall(estimate: estimate($0), spot: spot).band == .spotOn }
            XCTAssertEqual(spotOn.count, 1, "\(sorted) for \(spot.evBB)")
            spotOn.first.flatMap(sorted.firstIndex(of:)).map { positions.insert($0) }
        }
        XCTAssertEqual(positions, [0, 1, 2, 3])
    }

    func testLaterEVSpotsIncludeOverbets() {
        var overbets = 0
        for seed in seeds {
            for index in 0..<40 {
                let spot = EVCallSpotGenerator.spot(baseSeed: seed, index: index, level: .apply)
                if spot.bet > spot.pot { overbets += 1 }
                XCTAssertTrue((15...70).contains(spot.equityPct))
            }
        }
        XCTAssertGreaterThan(overbets, 0)
    }

    // MARK: Saved answers and the deeper challenge

    func testSavedAnswersRegradeAtTheirStep() {
        let reveal = SavedDrillReveal(band: GradeBand.spotOn.rawValue)
        let outs = OutsSpotGenerator.spot(baseSeed: 5, index: 3, level: .sharp)
        XCTAssertTrue(SavedDrillScore.matches(concept: .outs, seed: 5, index: 3, level: .sharp,
                                              input: .integer(outs.outCount), reveal: reveal))
        let combos = BlockerSpotGenerator.spot(baseSeed: 5, index: 3, level: .sharp)
        XCTAssertTrue(SavedDrillScore.matches(concept: .combos, seed: 5, index: 3, level: .sharp,
                                              input: .integer(combos.count), reveal: reveal))
        let price = BetSpotGenerator.spot(baseSeed: 5, index: 3, level: .sharp)
        XCTAssertTrue(SavedDrillScore.matches(concept: .potOdds, seed: 5, index: 3, level: .sharp,
                                              input: .integer(Int(price.requiredPct.rounded())), reveal: reveal))
    }

    func testTheDeeperChallengeHasAThirdStepThatMastersItsSkills() throws {
        let sharp = try XCTUnwrap(Curriculum.node(id: "deeper-boss.3"))
        XCTAssertEqual(sharp.level, .sharp)
        XCTAssertEqual(Curriculum.stepNode(try XCTUnwrap(Curriculum.node(id: "deeper-boss")), at: .sharp), sharp)
        XCTAssertFalse(Curriculum.steps.contains(sharp), "Go deeper is never suggested")
        XCTAssertEqual(Curriculum.lessonSteps(for: try XCTUnwrap(Curriculum.node(id: "u1-combos"))).map(\.id),
                       ["u1-combos", "u1-combos.2", "u1-combos.3"])

        var state = ProgressState()
        for id in ["u1-combos", "u1-combos.2", "u1-combos.3", "deeper-boss"] {
            state.nodes[id] = NodeRecord(cleared: true, attempts: 1)
        }
        XCTAssertEqual(Curriculum.challengeLevel(of: .combos, in: sharp, state: state), .sharp)
        XCTAssertEqual(Curriculum.challengeLevel(of: .evCall, in: sharp, state: state), .learn)
        // Its groundwork is the deeper lessons at the third step.
        XCTAssertEqual(Curriculum.unfinishedGroundwork(for: sharp, in: state).map(\.id),
                       ["u3-notation.3", "u2-evCall.3"])
        XCTAssertEqual(Curriculum.easierLesson(than: sharp)?.id, "u2-evCall.3")

        let t0 = Date(timeIntervalSince1970: 1_800_000_000)
        var record = ConceptRecord()
        record.total = 10; record.correct = 10; record.tier = .proficient; record.proficientAt = t0
        Mastery.promote(&record, evidence: SessionEvidence(attempted: 2, spotOn: 2), viaBoss: true,
                        level: Curriculum.challengeLevel(of: .combos, in: sharp, state: state), of: .combos,
                        now: t0.addingTimeInterval(Mastery.masteryCooldown))
        XCTAssertEqual(record.tier, .mastered)
    }
}
