// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest
import GlassTableEngine
@testable import GlassTableDrills

/// What the later steps of position, RFI, defend, range read and action read deal
/// (D53). The first step is frozen by `LearnSpotGoldenTests`; these check the
/// properties the later steps promise.
final class StepLevelReadingSpotTests: XCTestCase {
    private let seeds: [UInt64] = [0, 7, 0x9E37_79B9_7F4A_7C15, 123_456_789]

    /// Schema 5 has not shipped, so these skills join the same 4 → 5 upgrade: a
    /// cleared lesson is its first step, 능숙 the first two, 숙달 all three.
    func testUpgradeFromSchemaFourMarksTheReadingSkillsSteps() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("gt-reading-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let proficientAt = Date(timeIntervalSince1970: 1_790_380_800)
        let masteredAt = proficientAt.addingTimeInterval(13 * 3600)
        var old = ProgressState(schemaVersion: 4)
        old.nodes["u1-position"] = NodeRecord(cleared: true, clearedAt: proficientAt, attempts: 1)
        old.updateRecord(for: .position) { $0.tier = .familiar; $0.total = 3; $0.correct = 3 }
        old.updateRecord(for: .rfi) {
            $0.tier = .proficient; $0.proficientAt = proficientAt; $0.total = 3; $0.correct = 3
        }
        old.updateRecord(for: .actionRead) {
            $0.tier = .mastered; $0.proficientAt = proficientAt; $0.masteredAt = masteredAt
            $0.total = 5; $0.correct = 5
        }
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(old)) as? [String: Any])
        json["schemaVersion"] = 4
        let store = ProgressionStore(url: dir.appendingPathComponent("progress.json"))
        try JSONSerialization.data(withJSONObject: json).write(to: store.url)
        guard case let .loaded(state) = store.load() else { return XCTFail("schema 4 must upgrade") }
        XCTAssertEqual(state.schemaVersion, 5)
        XCTAssertNil(state.nodes["u1-position.2"])
        for id in ["u3-rfi", "u3-rfi.2"] {
            XCTAssertEqual(state.nodes[id], NodeRecord(cleared: true, clearedAt: proficientAt, attempts: 0), id)
        }
        XCTAssertNil(state.nodes["u3-rfi.3"])
        XCTAssertEqual(state.nodes["u7-actionRead.2"]?.clearedAt, proficientAt)
        XCTAssertEqual(state.nodes["u7-actionRead.3"], NodeRecord(cleared: true, clearedAt: masteredAt, attempts: 0))
        XCTAssertEqual(Curriculum.passedLevel(of: .rfi, in: state), .apply)
        XCTAssertEqual(Curriculum.passedLevel(of: .actionRead, in: state), .sharp)
        XCTAssertEqual(state.record(for: .actionRead).tier, .mastered)
    }

    func testTheReadingSkillsHaveThreeSteps() {
        for concept in [Concept.position, .rfi, .defend, .rangeRead, .actionRead] {
            XCTAssertEqual(DrillLevel.highest(for: concept), .sharp, concept.rawValue)
            XCTAssertNotNil(DrillLevel.apply.headline(for: concept, in: .korean), concept.rawValue)
            XCTAssertEqual(DrillLevel.sharp.headline(for: concept, in: .english)?.hasPrefix("Step 3 · "), true)
        }
    }

    // MARK: Position

    func testApplyPositionAsksAfterTheFlopMostlyFromTheBlinds() {
        var postflop = 0, postflopBlinds = 0
        for seed in seeds {
            for index in 0..<60 {
                let spot = PositionSpotGenerator.spot(baseSeed: seed, index: index, level: .apply)
                XCTAssertEqual(spot, PositionSpotGenerator.spot(baseSeed: seed, index: index, level: .apply))
                if case let .behind(seat, false) = spot.question {
                    postflop += 1
                    if seat.isBlind { postflopBlinds += 1 }
                }
            }
        }
        XCTAssertGreaterThan(postflop, 0)
        // Uniform seats would put a quarter of them in a blind.
        XCTAssertGreaterThan(Double(postflopBlinds) / Double(postflop), 0.45)
        XCTAssertFalse(DrillLevel.apply.typesExactAnswer(.position))
    }

    func testSharpPositionCountsOnlyThePlayersStillInAndIsTyped() {
        var answers = Set<Int>()
        for seed in seeds {
            for index in 0..<40 {
                let spot = PositionSpotGenerator.spot(baseSeed: seed, index: index, level: .sharp)
                guard case let .behindInHand(seat, stillIn) = spot.question else {
                    return XCTFail("the third step asks who is still in after the flop")
                }
                XCTAssertTrue((1...4).contains(stillIn.count))
                XCTAssertFalse(stillIn.contains(seat))
                XCTAssertEqual(stillIn, Position.allCases.filter(stillIn.contains), "listed in seat order")
                XCTAssertEqual(spot.correctAnswer, stillIn.filter { $0.actsAfter(seat) }.count)
                answers.insert(spot.correctAnswer)
            }
        }
        XCTAssertTrue(answers.contains(0))
        XCTAssertGreaterThan(answers.count, 2)
        XCTAssertTrue(DrillLevel.sharp.typesExactAnswer(.position))
    }

    func testSharpPositionRevealCountsTheRightPlayers() {
        let spot = PositionSpot(question: .behindInHand(.hj, stillIn: [.utg, .btn, .bb]))
        XCTAssertEqual(spot.correctAnswer, 1)
        let english = gradePosition(answer: 1, spot: spot, language: .english)
        XCTAssertEqual(english.band, .spotOn)
        XCTAssertTrue(english.whyText.contains("BB → UTG → HJ (you) → BTN"), english.whyText)
        XCTAssertEqual(gradePosition(answer: 3, spot: spot).band, .off)
        let label = ConceptReveal(concept: .position, seed: 0, index: 2, level: .sharp, input: .integer(1),
                                  language: .korean)
        XCTAssertEqual(label?.mine, "1명")
    }

    // MARK: RFI

    func testApplyRFIHandsSitNearTheSeatsCutoff() {
        var opens = 0, folds = 0
        for seed in seeds {
            for index in 0..<50 {
                let spot = RFISpotGenerator.spot(baseSeed: seed, index: index, level: .apply)
                let distance = abs(Chen.score(spot.handClass) - RFIChart.cutoffScore(for: spot.seat))
                XCTAssertLessThanOrEqual(distance, 1.5, "\(spot.handClass) from \(spot.seat)")
                if spot.opens { opens += 1 } else { folds += 1 }
            }
        }
        XCTAssertGreaterThan(opens, 20)
        XCTAssertGreaterThan(folds, 20)
    }

    func testEveryHandFirstOpensFromAnAnswerTheSharpStepOffers() {
        // The button opens every hand the small blind does, so the small blind is
        // never the first seat and is not offered.
        for hand in HandClass.all {
            let cards = hand.combos().first!
            let answer = RFIFirstSeat.answer(for: cards)
            XCTAssertEqual(RFIFirstSeat.answers[answer], RFIChart.earliestSeatOpening(cards))
        }
        XCTAssertFalse(RFIFirstSeat.answers.contains(.sb))
    }

    func testSharpRFIAsksForTheFirstSeatFromFourNeighbouringChoices() {
        var answers = Set<Int>()
        for seed in seeds {
            for index in 0..<40 {
                let spot = RFISpotGenerator.spot(baseSeed: seed, index: index, level: .sharp)
                let answer = RFIFirstSeat.answer(for: spot.hand)
                answers.insert(answer)
                XCTAssertEqual(spot.seat, RFIChart.earliestSeatOpening(spot.hand) ?? .btn,
                               "the chart shown with the answer is the one that decides it")
                let choices = RFIFirstSeat.choices(answer: answer, seed: seed &+ UInt64(index))
                XCTAssertEqual(choices.count, 4)
                XCTAssertEqual(choices, Array(choices.first!...choices.last!), "neighbours, in seat order")
                XCTAssertTrue(choices.contains(answer))
                XCTAssertEqual(choices.filter {
                    gradeRFIFirstSeat(answer: $0, spot: spot).band == .spotOn
                }.count, 1)
            }
        }
        XCTAssertGreaterThan(answers.count, 4, "first seats vary")
        XCTAssertTrue(SavedDrillInput.integer(RFIFirstSeat.answers.count - 1).isValid(for: .rfi))
        XCTAssertFalse(SavedDrillInput.integer(RFIFirstSeat.answers.count).isValid(for: .rfi))
    }

    func testSharpRFIAnswerRegradesAtItsStep() {
        let spot = RFISpotGenerator.spot(baseSeed: 5, index: 3, level: .sharp)
        let answer = RFIFirstSeat.answer(for: spot.hand)
        let reveal = SavedDrillReveal(band: GradeBand.spotOn.rawValue)
        XCTAssertTrue(SavedDrillScore.matches(concept: .rfi, seed: 5, index: 3, level: .sharp,
                                              input: .integer(answer), reveal: reveal))
        let shown = ConceptReveal(concept: .rfi, seed: 5, index: 3, level: .sharp, input: .integer(answer),
                                  language: .english)
        XCTAssertEqual(shown?.mine, shown?.correct)
        XCTAssertEqual(gradeRFIFirstSeat(answer: answer, spot: spot, language: .english).whyText.isEmpty, false)
    }

    // MARK: Defend

    func testLaterDefendStepsDealHandsNearABandEdge() {
        for level in [DrillLevel.apply, .sharp] {
            var actions = Set<DefendAction>()
            for seed in seeds {
                for index in 0..<40 {
                    let spot = DefendSpotGenerator.spot(baseSeed: seed, index: index, level: level)
                    XCTAssertLessThanOrEqual(DefendChart.edgeDistance(of: spot.handClass, vsOpenFrom: spot.opener), 2,
                                             "\(spot.handClass) vs \(spot.opener)")
                    actions.insert(spot.correct)
                }
            }
            XCTAssertEqual(actions, Set(DefendAction.allCases), "\(level)")
        }
        XCTAssertNotEqual((0..<8).map { DefendSpotGenerator.spot(baseSeed: 7, index: $0, level: .apply) },
                          (0..<8).map { DefendSpotGenerator.spot(baseSeed: 7, index: $0, level: .sharp) },
                          "the third step deals its own spots")
    }

    // MARK: Range read

    func testApplyRangeReadHidesTheOpponentMoreOften() {
        var hidden = 0, total = 0
        for seed in seeds {
            for index in 0..<50 {
                let spot = RangeReadSpotGenerator.spot(baseSeed: seed, index: index, level: .apply)
                total += 1
                if !spot.archetypeShown { hidden += 1 }
            }
        }
        // The first step hides about a third.
        XCTAssertGreaterThan(Double(hidden) / Double(total), 0.5)
        XCTAssertLessThan(hidden, total)
    }

    func testSharpRangeReadIsAlwaysAnUnknownCaller() {
        for seed in seeds {
            for index in 0..<40 {
                let spot = RangeReadSpotGenerator.spot(baseSeed: seed, index: index, level: .sharp)
                guard case .called = spot.action else { return XCTFail("calls only") }
                XCTAssertFalse(spot.archetypeShown)
            }
        }
    }

    func testRangeReadChoicesCloseInWithEachStep() {
        var places = Set<Int>()
        for archetype in Archetype.allCases {
            for seat in RFIChart.seats {
                for action in [RangeReadSpot.Action.opened(seat), .called(seat: seat, opener: .utg)] {
                    let spot = RangeReadSpot(archetype: archetype, action: action, archetypeShown: false)
                    XCTAssertEqual(RangeReadChoices.estimates(spot: spot, seed: 9, level: .learn),
                                   BeginnerQuestionChoices.rangeEstimates(spot: spot, seed: 9))
                    for (level, count) in [(DrillLevel.apply, 3), (.sharp, 4)] {
                        let choices = RangeReadChoices.estimates(spot: spot, seed: 9, level: level)
                        let context = "\(level) \(archetype) \(seat) \(action)"
                        XCTAssertEqual(choices.count, count, context)
                        XCTAssertEqual(Set(choices.map { Int($0.range.percent.rounded()) }).count, count,
                                       "every choice reads differently: \(context)")
                        XCTAssertTrue(choices.allSatisfy {
                            SavedDrillInput.rangeBand(width: $0.width, excludedTop: $0.excludedTop, tendencies: [])
                                .isValid(for: .rangeRead)
                        }, context)
                        XCTAssertEqual(choices.filter { gradeRangeRead(estimate: $0, spot: spot).band == .spotOn }.count,
                                       1, context)
                    }
                    // Each wrong choice is a whole number of 0.6× or 1.6× steps from the answer.
                    for level in [DrillLevel.apply, .sharp] {
                        let choices = RangeReadChoices.estimates(spot: spot, seed: 9, level: level)
                        guard let truth = choices.first(where: {
                            gradeRangeRead(estimate: $0, spot: spot).band == .spotOn
                        })?.width else { continue }
                        let widths = choices.map(\.width).sorted()
                        let at = widths.firstIndex(of: truth)!
                        for (i, w) in widths.enumerated() where i != at {
                            let steps = log(w / truth) / log(i < at ? 0.6 : 1.6)
                            XCTAssertEqual(steps, steps.rounded(), accuracy: 0.001, "\(level) \(widths)")
                            XCTAssertGreaterThanOrEqual(steps.rounded(), Double(abs(i - at)))
                        }
                        places.insert(at)
                    }
                }
            }
        }
        XCTAssertGreaterThan(places.count, 2, "the answer is not always the middle choice")
    }

    // MARK: Action read

    func testActionReadSpotsAreTheSameAtEveryStep() {
        for index in 0..<6 {
            let learn = ActionReadSpotGenerator.spot(baseSeed: 7, index: index)
            XCTAssertEqual(ActionReadSpotGenerator.spot(baseSeed: 7, index: index, level: .apply), learn)
            XCTAssertEqual(ActionReadSpotGenerator.spot(baseSeed: 7, index: index, level: .sharp), learn)
        }
    }

    func testActionReadChoicesCloseInWithEachStepAndOnlyOneIsRight() {
        for seed in seeds {
            for index in 0..<20 {
                let spot = ActionReadSpotGenerator.spot(baseSeed: seed, index: index)
                let answer = spot.pairOrBetterPct
                XCTAssertEqual(ActionReadChoices.values(answer: answer, seed: seed, level: .learn),
                               BeginnerQuestionChoices.percentages(answer: answer, seed: seed))
                for (level, count, gap) in [(DrillLevel.apply, 3, 10.0), (.sharp, 4, 6.0)] {
                    let values = ActionReadChoices.values(answer: answer, seed: seed, level: level)
                    XCTAssertEqual(values.count, count)
                    XCTAssertTrue(values.allSatisfy { (0...100).contains($0) })
                    let sorted = values.sorted()
                    for (a, b) in zip(sorted, sorted.dropFirst()) {
                        XCTAssertEqual(b - a, gap, "\(level) \(values)")
                    }
                    let right = values.filter {
                        gradeActionRead(estimate: Estimate(point: $0, lo: max(0, $0 - 12), hi: min(100, $0 + 12)),
                                        spot: spot).band == .spotOn
                    }
                    XCTAssertEqual(right.count, 1, "\(level) \(answer) \(values)")
                }
            }
        }
    }
}
