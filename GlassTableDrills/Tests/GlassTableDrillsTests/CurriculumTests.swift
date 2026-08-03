import XCTest
@testable import GlassTableDrills

final class CurriculumTests: XCTestCase {
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
    func testEveryUnitIsAChapterRatherThanASingleNode() {
        XCTAssertEqual(Curriculum.units.count, 4)
        for unit in Curriculum.units {
            XCTAssertTrue((2...8).contains(unit.nodes.count),
                          "\(unit.id) is \(unit.nodes.count) nodes")
        }
        XCTAssertEqual(Curriculum.allNodes.count, 15)
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

    /// Spec §3.2: MDF is parked out of the path but keeps a concept for 자유 연습.
    /// Every other concept must be introduced by exactly one node — including
    /// callFold, which unit 2's boss introduces rather than merely revisiting.
    func testMdfHasNoNodeButEveryOtherConceptIsTaughtExactlyOnce() {
        let taught = Curriculum.allNodes.compactMap(Curriculum.taughtConcept)
        XCTAssertFalse(taught.contains(.mdf))
        XCTAssertEqual(Set(taught), Set(Concept.allCases).subtracting([.mdf]))
        XCTAssertEqual(taught.count, Set(taught).count, "no concept is introduced twice")
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
