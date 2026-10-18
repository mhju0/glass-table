import XCTest
@testable import GlassTableDrills

final class CurriculumTests: XCTestCase {
    func testCompletedSessionsPracticeEveryConceptTheyCanPromote() {
        for node in Curriculum.allNodes {
            let session = Curriculum.sessionConcepts(for: node)
            XCTAssertEqual(Set(session), Set(Curriculum.sessionPool(of: node, format: Curriculum.sessionFormat)), node.id)
            switch node.kind {
            case .drill:
                XCTAssertEqual(session.count, 3, node.id)
                XCTAssertEqual(Curriculum.sessionConcepts(for: node, format: 1).count, 5, node.id)
                XCTAssertTrue(Curriculum.isValidSession(session, for: node))
                XCTAssertFalse(Curriculum.isValidSession(session, for: node, format: 1))
                XCTAssertEqual(Set(session).count, 1, "first exposure stays blocked")
            case .boss:
                XCTAssertGreaterThanOrEqual(session.count, 6, node.id)
            }
        }
    }

    func testBossBagIsBalancedDeterministicAndSeedShuffled() throws {
        let boss = try XCTUnwrap(Curriculum.node(id: "u1-boss"))
        let first = Curriculum.sessionConcepts(for: boss, seed: 41)
        let again = Curriculum.sessionConcepts(for: boss, seed: 41)
        let other = Curriculum.sessionConcepts(for: boss, seed: 42)

        XCTAssertEqual(first, again)
        XCTAssertNotEqual(first, other)
        XCTAssertEqual(first.count, 6)
        XCTAssertEqual(Set(first), Set(Curriculum.sessionPool(of: boss, format: Curriculum.sessionFormat)))
        let counts = Dictionary(grouping: first, by: { $0 }).values.map(\.count)
        XCTAssertLessThanOrEqual((counts.max() ?? 0) - (counts.min() ?? 0), 1)
        XCTAssertTrue(Curriculum.isValidSession(first, for: boss))
        XCTAssertFalse(Curriculum.isValidSession(Array(first.dropLast()), for: boss))
        XCTAssertFalse(Curriculum.isValidSession(Array(repeating: .showdown, count: 6), for: boss))
    }

    /// Spec §4.1 wants units of 5–8 nodes, for the goal-gradient reason that more
    /// visible completions per hour sustain a long course. The final unit is bounded
    /// by how much content exists rather than by that rule: u3 is three nodes because
    /// R2 is where the ladder currently ends, and it grows when Block B lands.
    /// Padding a unit with invented nodes to hit a number would be worse than a short
    /// one, so the floor is relaxed only for the last unit.
    /// Spec §4.1, as amended 2026-08-04. The original rule was a flat 5–8 nodes per
    /// unit, written when R1 planned two fat units. Every slice since adds one
    /// primitive, so 레인지 (3 nodes) and 레인지 리드 (2) are genuinely short and the
    /// rule had already needed one special case in R2. What actually has to hold is
    /// the shape, not the count: a unit is never a single node dressed as a chapter,
    /// and nothing runs away in the other direction either.
    /// Structural rather than a pinned total: an exact node count is churn every slice
    /// and `testNodeIDsAreUniqueAndLookupWorks` already catches duplication.
    func testEveryUnitIsAChapterRatherThanASingleNode() {
        XCTAssertGreaterThanOrEqual(Curriculum.units.count, 4)
        for unit in Curriculum.units {
            XCTAssertTrue((2...8).contains(unit.nodes.count),
                          "\(unit.id) is \(unit.nodes.count) nodes")
        }
        XCTAssertEqual(Curriculum.allNodes.count,
                       Curriculum.units.reduce(0) { $0 + $1.nodes.count },
                       "the flattened path must be exactly the units")
    }

    /// Sections group units, and a unit must never be filed under a section that
    /// misdescribes it — the path header used to hardcode 기초 for everything.
    func testEveryUnitDeclaresANonEmptySection() {
        for unit in Curriculum.units {
            XCTAssertFalse(unit.section.isEmpty, unit.id)
        }
    }

    /// Spec §4.1: every unit ends in a boss node.
    func testEveryUnitEndsInABossNodeAndNoOtherNodeIsABoss() {
        for unit in Curriculum.units {
            guard case .boss = unit.nodes.last?.kind else {
                return XCTFail("\(unit.id) must end in a boss")
            }
            for node in unit.nodes.dropLast() {
                guard case .drill = node.kind else {
                    return XCTFail("\(node.id) should be a drill, not a boss")
                }
            }
        }
    }

    func testNodeIDsAreUniqueAndLookupWorks() {
        let ids = Curriculum.allNodes.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "node ids must be unique")
        XCTAssertEqual(Curriculum.node(id: "u1-position")?.kind, .drill(.position))
        XCTAssertNil(Curriculum.node(id: "nope"))
    }

    /// Every concept is introduced exactly once, including MDF in the final unit.
    /// Call-or-fold is the one repeat: its lesson teaches it, and unit 2's boss keeps it
    /// as its own so challenge sessions saved before the lesson existed stay valid.
    /// Existing node identifiers and order remain unchanged.
    func testEveryConceptIsTaughtExactlyOnce() {
        let taught = Curriculum.allNodes.compactMap(Curriculum.taughtConcept)
        XCTAssertEqual(Set(taught), Set(Concept.allCases))
        XCTAssertEqual(taught.filter { $0 != .callFold }.count, Set(taught).count - 1,
                       "no other concept is introduced twice")
        XCTAssertEqual(taught.filter { $0 == .callFold }.count, 2)
        XCTAssertEqual(Curriculum.node(id: "u9-mdf")?.kind, .drill(.mdf))
        XCTAssertEqual(Curriculum.allNodes.dropLast(2).last?.id, "u8-boss")
    }

    /// Spec §4.1: a boss mixes its own unit with 2-3 earlier units.
    func testLaterBossMixesInEarlierUnitConcepts() {
        guard case let .boss(own, mixes) = Curriculum.units[1].nodes.last?.kind else {
            return XCTFail("expected a boss")
        }
        XCTAssertEqual(own, .callFold, "콜/폴드 is the boss itself (spec §3.2)")
        let unit1 = Set<Concept>([.showdown, .potMath, .position, .combos])
        XCTAssertFalse(Set(mixes).intersection(unit1).isEmpty,
                       "unit 2's boss must reach back into unit 1")
    }

    /// A boss may only *revisit* concepts already introduced. Its own concept counts
    /// as introduced at that node, so it is added before the mixes are checked.
    func testBossMixesOnlyReferenceConceptsAlreadyTaught() {
        var taught = Set<Concept>()
        for node in Curriculum.allNodes {
            if let own = Curriculum.taughtConcept(of: node) { taught.insert(own) }
            guard case let .boss(_, mixes) = node.kind else { continue }
            for m in mixes {
                XCTAssertTrue(taught.contains(m),
                              "\(node.id) mixes \(m.rawValue) before it is taught")
            }
        }
    }
}

final class NodeUnlockTests: XCTestCase {
    private func cleared(_ ids: [String]) -> ProgressState {
        var s = ProgressState()
        for id in ids { s.nodes[id] = NodeRecord(cleared: true, attempts: 1) }
        return s
    }

    func testOnlyTheFirstNodeIsAvailableOnAFreshState() {
        let s = ProgressState()
        XCTAssertEqual(Curriculum.status(of: "u1-showdown", in: s), .available)
        for node in Curriculum.allNodes.dropFirst() {
            XCTAssertEqual(Curriculum.status(of: node.id, in: s), .locked, node.id)
        }
    }

    func testClearingANodeUnlocksExactlyTheNextOne() {
        let s = cleared(["u1-showdown"])
        XCTAssertEqual(Curriculum.status(of: "u1-showdown", in: s), .cleared)
        XCTAssertEqual(Curriculum.status(of: "u1-potMath", in: s), .available)
        XCTAssertEqual(Curriculum.status(of: "u1-position", in: s), .locked)
    }

    /// Units are sequential too — unit 2 opens only after unit 1's boss falls.
    func testUnitTwoStaysLockedUntilUnitOnesBossIsCleared() {
        let almost = cleared(["u1-showdown", "u1-potMath", "u1-position", "u1-combos"])
        XCTAssertEqual(Curriculum.status(of: "u1-boss", in: almost), .available)
        XCTAssertEqual(Curriculum.status(of: "u2-potOdds", in: almost), .locked)

        let done = cleared(["u1-showdown", "u1-potMath", "u1-position", "u1-combos", "u1-boss"])
        XCTAssertEqual(Curriculum.status(of: "u2-potOdds", in: done), .available)
    }

    /// The diagnostic pre-clears nodes (spec §6); a gap must not strand the path.
    func testPreClearedNodesLetTheUserResumeAfterTheGap() {
        let s = cleared(["u1-showdown", "u1-potMath", "u1-position"])
        XCTAssertEqual(Curriculum.status(of: "u1-combos", in: s), .available)
    }

    func testNextNodeIsTheFirstAvailableOne() {
        XCTAssertEqual(Curriculum.nextNode(in: ProgressState())?.id, "u1-showdown")
        XCTAssertEqual(Curriculum.nextNode(in: cleared(["u1-showdown"]))?.id, "u1-potMath")
        let all = cleared(Curriculum.allNodes.map(\.id))
        XCTAssertNil(Curriculum.nextNode(in: all), "no next node once everything is cleared")
    }

    func testUnknownNodeIsLocked() {
        XCTAssertEqual(Curriculum.status(of: "nope", in: ProgressState()), .locked)
    }
}

// MARK: - tracks (D46)

final class LearningTrackTests: XCTestCase {
    /// D48: the game first, the math last, in one order a learner can take top to bottom.
    private static let pathOrder = ["u1-showdown", "u1-position", "u3-rfi", "u8-defend",
                                    "u4-rangeRead", "u7-actionRead", "u2-outs", "u1-potMath",
                                    "u2-equitySense", "u2-potOdds", "u2-callFold"]

    func testTrackChallengesMixOnlyTheirOwnTrackAndOldSavedOnesKeepTheirMix() throws {
        for track in Curriculum.tracks {
            guard let challenge = track.challenge else { continue }
            let mixed = Curriculum.sessionConcepts(for: challenge, seed: 9)
            XCTAssertEqual(Set(mixed), Set(track.concepts), challenge.id)
            XCTAssertTrue(Curriculum.isValidSession(mixed, for: challenge))
            let old = Curriculum.sessionConcepts(for: challenge, seed: 9, format: 1)
            XCTAssertEqual(Set(old), Set(Curriculum.concepts(of: challenge)), challenge.id)
            XCTAssertTrue(Curriculum.isValidSession(old, for: challenge, format: 1))
        }
        func mix(_ id: String) throws -> Set<Concept> {
            Set(Curriculum.sessionConcepts(for: try XCTUnwrap(Curriculum.node(id: id)), seed: 9))
        }
        XCTAssertEqual(try mix("u1-boss"), [.showdown, .position])
        XCTAssertEqual(try mix("u3-boss"), [.rfi, .defend])
        XCTAssertEqual(try mix("u4-boss"), [.rangeRead, .actionRead])
        XCTAssertEqual(try mix("u2-boss"), [.outs, .potMath, .equitySense, .potOdds, .callFold])
    }

    /// A challenge dealt before D48 regrouped the tracks keeps the mix it was dealt, so
    /// a run left half-way still loads and still counts.
    func testAChallengeDealtBeforeTheNewOrderStaysValid() throws {
        let old: [String: [Concept]] = ["u1-boss": [.showdown, .potMath],
                                        "u3-boss": [.position, .rfi, .defend],
                                        "u2-boss": [.outs, .equitySense, .potOdds, .callFold]]
        for (id, pool) in old {
            let node = try XCTUnwrap(Curriculum.node(id: id))
            let dealt = Curriculum.deal(pool, for: node, seed: 5, format: 2)
            XCTAssertEqual(Set(dealt), Set(pool), id)
            XCTAssertTrue(Curriculum.isValidSession(dealt, for: node, format: 2), id)
            XCTAssertTrue(Curriculum.isSavedSchedule(dealt, for: node, seed: 5, format: 2), id)
            XCTAssertFalse(Curriculum.isSavedSchedule(dealt, for: node, seed: 6, format: 2), id)
            XCTAssertNotEqual(Set(Curriculum.sessionConcepts(for: node, seed: 5)), Set(pool),
                              "New runs use the new mix")
        }
    }

    func testSkillsToPractiseFollowTheTracksAndLeaveOutHiddenTopics() {
        let skills = Curriculum.tracks.flatMap(\.concepts)
        XCTAssertEqual(Set(skills).count, skills.count)
        XCTAssertEqual(Curriculum.tracks.first { $0.id == .priceAndChance }?.concepts,
                       [.outs, .potMath, .equitySense, .potOdds, .callFold])
        for hidden in [Concept.hitFrequency, .rangeAdvantage, .evLoss, .mdf] { XCTAssertFalse(skills.contains(hidden)) }
    }

    func testTracksRegroupExistingLessonsAndLeaveTheNineUnitsAlone() {
        XCTAssertEqual(Curriculum.units.count, 9)
        XCTAssertEqual(Curriculum.allNodes.count, 27)
        XCTAssertEqual(Curriculum.tracks.map(\.id), LearningTrack.ID.allCases)
        XCTAssertEqual(Curriculum.tracks.map(\.id),
                       [.basics, .startingHands, .readingOpponents, .priceAndChance, .deeper])
        XCTAssertEqual(Curriculum.trackLessons.map(\.id), Self.pathOrder)
        let offered = Curriculum.tracks.flatMap { $0.lessons + [$0.challenge].compactMap { $0 } }
        XCTAssertEqual(Set(offered.map(\.id)).count, offered.count, "No lesson sits on two tracks")
        let taught = Set(offered.compactMap(Curriculum.taughtConcept))
        for hidden in [Concept.hitFrequency, .rangeAdvantage, .evLoss, .mdf] {
            XCTAssertFalse(taught.contains(hidden), "\(hidden) is no longer offered")
        }
        XCTAssertTrue(taught.contains(.callFold), "Call or fold is the price track's challenge")
        XCTAssertEqual(Curriculum.tracks.last?.lessons.compactMap(Curriculum.taughtConcept),
                       [.combos, .rangeNotation, .evCall])
    }

    /// The path screen lists the tracks' lessons top to bottom; following the
    /// suggestion from a fresh start visits them in exactly that order, with each
    /// track's later steps and challenge after its lessons (D53).
    func testThePathScreenOrderIsTheSuggestedOrder() {
        let shown = Curriculum.tracks.filter { !$0.isOptional }.flatMap(\.lessons).map(\.id)
        XCTAssertEqual(shown, Self.pathOrder)
        var state = ProgressState()
        var suggested: [String] = []
        while let next = Curriculum.suggestedLesson(in: state) {
            suggested.append(next.id)
            state.nodes[next.id] = NodeRecord(cleared: true)
        }
        XCTAssertEqual(suggested.filter { Curriculum.trackLessons.map(\.id).contains($0) }, shown)
        XCTAssertEqual(suggested, StepCurriculumTests.stepOrder)
    }

    func testSuggestionFollowsTheTracksButNeverLocksAndIgnoresHiddenProgress() {
        var state = ProgressState()
        XCTAssertEqual(Curriculum.suggestedLesson(in: state)?.id, "u1-showdown")
        state.nodes["u1-showdown"] = NodeRecord(cleared: true)
        // Old progress on a lesson that is now hidden neither helps nor blocks.
        state.nodes["u5-hitFrequency"] = NodeRecord(cleared: true)
        XCTAssertEqual(Curriculum.suggestedLesson(in: state)?.id, "u1-position")
        // Jumping ahead is allowed; the suggestion stays on the earliest gap.
        state.nodes["u2-potOdds"] = NodeRecord(cleared: true)
        XCTAssertEqual(Curriculum.suggestedLesson(in: state)?.id, "u1-position")
        for node in Curriculum.steps { state.nodes[node.id] = NodeRecord(cleared: true) }
        XCTAssertNil(Curriculum.suggestedLesson(in: state), "Go deeper is never suggested")
    }

    /// Progress is keyed by lesson id, so a file saved under the old order keeps every
    /// clear and the suggestion lands on the first lesson still owed in the new order.
    func testProgressSavedUnderTheOldOrderGetsASensibleSuggestion() {
        var state = ProgressState()
        // The old first three: Who wins, Which river cards win, Count the pot.
        for id in ["u1-showdown", "u2-outs", "u1-potMath"] { state.nodes[id] = NodeRecord(cleared: true) }
        XCTAssertEqual(Curriculum.suggestedLesson(in: state)?.id, "u1-position")
        // The old first two tracks, challenges included, all done.
        for id in ["u1-position", "u3-rfi", "u8-defend", "u1-boss", "u3-boss"] {
            state.nodes[id] = NodeRecord(cleared: true)
        }
        XCTAssertEqual(Curriculum.suggestedLesson(in: state)?.id, "u4-rangeRead")
        // Someone part-way through the old price track who then did the reads goes on
        // with the price lessons they had not reached.
        for id in ["u2-equitySense", "u4-rangeRead", "u7-actionRead"] {
            state.nodes[id] = NodeRecord(cleared: true)
        }
        // Since D53 a track's challenge is suggested after its lessons.
        XCTAssertEqual(Curriculum.suggestedLesson(in: state)?.id, "u4-boss")
        state.nodes["u4-boss"] = NodeRecord(cleared: true)
        XCTAssertEqual(Curriculum.suggestedLesson(in: state)?.id, "u2-potOdds")
        // A passed old basics challenge now skips the new basics track.
        var passed = ProgressState()
        passed.nodes["u1-boss"] = NodeRecord(cleared: true)
        XCTAssertEqual(Curriculum.suggestedLesson(in: passed)?.id, "u3-rfi")
    }

    func testGoingOnPastALessonSuggestsTheNextOneStillOwed() throws {
        var state = ProgressState()
        let position = try XCTUnwrap(Curriculum.node(id: "u1-position"))
        state.nodes["u1-showdown"] = NodeRecord(cleared: true)
        XCTAssertEqual(Curriculum.suggestedLesson(in: state)?.id, "u1-position")
        XCTAssertEqual(Curriculum.suggestedLesson(in: state, skipping: position)?.id, "u1-showdown.2")
        state.nodes["u1-showdown.2"] = NodeRecord(cleared: true)
        XCTAssertEqual(Curriculum.suggestedLesson(in: state, skipping: position)?.id, "u1-boss")
    }

    func testGroundworkAndEasierLessonPointBackAlongTheTracks() throws {
        var state = ProgressState()
        let rfi = try XCTUnwrap(Curriculum.node(id: "u3-rfi"))
        XCTAssertEqual(Curriculum.unfinishedGroundwork(for: rfi, in: state).map(\.id),
                       ["u1-showdown", "u1-position", "u1-showdown.2"])
        state.nodes["u1-showdown"] = NodeRecord(cleared: true)
        XCTAssertEqual(Curriculum.unfinishedGroundwork(for: rfi, in: state).map(\.id),
                       ["u1-position", "u1-showdown.2"])
        XCTAssertEqual(Curriculum.easierLesson(than: rfi)?.id, "u1-position")
        XCTAssertNil(Curriculum.easierLesson(than: try XCTUnwrap(Curriculum.node(id: "u1-showdown"))))
        // A challenge leans on its own track; a deeper topic leans on all four.
        let challenge = try XCTUnwrap(Curriculum.node(id: "u2-boss"))
        XCTAssertEqual(Curriculum.unfinishedGroundwork(for: challenge, in: state).map(\.id),
                       ["u2-outs", "u1-potMath", "u2-equitySense", "u2-potOdds", "u2-callFold",
                        "u1-potMath.2", "u2-callFold.2"])
        XCTAssertEqual(Curriculum.easierLesson(than: challenge)?.id, "u2-callFold")
        let combos = try XCTUnwrap(Curriculum.node(id: "u1-combos"))
        XCTAssertEqual(Curriculum.unfinishedGroundwork(for: combos, in: state).count, 10)
        XCTAssertEqual(Curriculum.easierLesson(than: combos)?.id, "u2-callFold")
    }

    /// Call-or-fold gets a lesson of its own before the price track's challenge, so a
    /// beginner first meets the decision with help rather than under challenge rules.
    func testCallOrFoldHasItsOwnLessonBeforeThePriceChallenge() throws {
        let lesson = try XCTUnwrap(Curriculum.node(id: "u2-callFold"))
        XCTAssertEqual(lesson.kind, .drill(.callFold))
        let track = try XCTUnwrap(Curriculum.tracks.first { $0.id == .priceAndChance })
        XCTAssertEqual(track.lessons.map(\.id),
                       ["u2-outs", "u1-potMath", "u2-equitySense", "u2-potOdds", "u2-callFold"])
        XCTAssertEqual(track.challenge?.id, "u2-boss")
        let ids = Curriculum.allNodes.map(\.id)
        XCTAssertEqual(ids.firstIndex(of: "u2-callFold").map { $0 + 1 }, ids.firstIndex(of: "u2-boss"))
        XCTAssertEqual(Curriculum.sessionConcepts(for: lesson), [.callFold, .callFold, .callFold])
    }
}
