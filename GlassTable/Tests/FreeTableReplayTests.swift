import Testing
import GlassTableDrills
@testable import GlassTable

struct FreeTableReplayTests {
    @Test(arguments: ["normal", "fold", "runout", "sidepots", "refund", "odd"])
    func everyIntermediateFrameConservesMoneyAndFinalMatchesModel(kind: String) throws {
        let table = try FreeTableReplayFixtures.table(kind)
        let review = try #require(table.review)
        let plan = FreeTableReplayPlan(table: table)
        print("LEGAL \(kind) seed=\(table.seed) contributions=\(review.contributions) refunds=\(review.refunds) payouts=\(review.payouts) ending=\(review.endingStacks) duration=\(plan.duration)")
        for time in stride(from: 0.0, through: plan.duration, by: 17) {
            let p = plan.projection(at: time)
            #expect(p.frame.stacks.reduce(0, +) + p.pot + p.inTransit == review.startingStacks.reduce(0, +))
            #expect(p.frame.stacks.allSatisfy { $0 >= 0 })
            #expect(p.pot >= 0)
            #expect(!p.frame.settled)
            for seat in p.visuals.exposed where seat != 0 { #expect(!p.frame.folded[seat]) }
            #expect(p.visibleBoard.count <= p.visuals.boardArrived)
        }
        let final = plan.projection(at: plan.duration)
        #expect(final.frame.settled)
        #expect(final.frame.stacks == review.endingStacks)
        #expect(final.pot == 0)
        #expect(final.frame.streetCommitted.allSatisfy { $0 == 0 })
        #expect(final.shownSteps == table.replaySteps.count)
        let awards = FreeTableReplayPlan.awards(review: review, dealer: table.dealer)
        for seat in 0..<table.seatCount { #expect(awards.reduce(0) { $0 + $1.amounts[seat] } == review.payouts[seat]) }
        #expect(awards.filter { !$0.odd }.map(\.pot) == Array(review.pots.indices.reversed()))
    }

    @Test func cardsArrivingAreSeparateFromPublicFacesAndHistory() throws {
        let table = try FreeTableReplayFixtures.table("normal")
        let plan = FreeTableReplayPlan(table: table)
        let holes = try #require(plan.phases.first { $0.work == .holes })
        let during = plan.projection(at: holes.start + 250)
        #expect(!during.heroExposed)
        #expect(during.visibleHole[0].isEmpty)
        #expect(during.visuals.arrived.reduce(0, +) > 0)
        let deal = try #require(plan.phases.first { if case .deal = $0.work { true } else { false } })
        let facedown = plan.projection(at: deal.start + 230)
        #expect(facedown.visuals.boardArrived == 1)
        #expect(facedown.visibleBoard.isEmpty)
        let partial = plan.projection(at: deal.start + 410)
        #expect(partial.visibleBoard.count == 1)
        #expect(partial.shownSteps == facedown.shownSteps)
        let action = try #require(plan.phases.first { if case .action = $0.work { true } else { false } })
        let before = plan.projection(at: action.start)
        let middle = plan.projection(at: action.start + action.duration * 0.5)
        #expect(before.shownSteps == middle.shownSteps)
        let publicBefore = table.frame(after: before.shownSteps)
        let publicMiddle = table.frame(after: middle.shownSteps)
        #expect(PracticeDecisionFacts(frame: publicBefore, learnerHole: table.learnerHole, visibleBoard: [])
                == PracticeDecisionFacts(frame: publicMiddle, learnerHole: table.learnerHole, visibleBoard: []))
    }

    @Test func foldOnlyOpponentNeverExposedIncludingNextHandClear() throws {
        let table = try FreeTableReplayFixtures.table("fold")
        let plan = FreeTableReplayPlan(table: table)
        #expect(!plan.phases.contains { if case .reveal = $0.work { true } else { false } })
        #expect(plan.projection(at: plan.duration).visuals.exposed == [0])
        var next = table
        try next.nextHand(handID: "next")
        let transition = FreeTableReplayPlan(table: next, previous: table).projection(at: 100)
        #expect(table.frame(after: table.replaySteps.count).streetCommitted.contains { $0 > 0 })
        #expect(transition.frame.streetCommitted.allSatisfy { $0 == 0 })
        #expect(transition.visuals.exposed == [0])
        #expect(!transition.heroExposed)
    }

    @Test func soleFundedSeatOwingCallBlocksEarlyRunout() throws {
        let table = try FreeTableReplayFixtures.table("runout")
        let raiseIndex = try #require(table.replaySteps.firstIndex { step in
            if case let .action(index) = step { return table.events[index].id == "hero-allin" }; return false
        })
        #expect(!FreeTableReplayPlan.canExposeRunout(table.frame(after: raiseIndex + 1)))
        let dealIndex = try #require(table.replaySteps.firstIndex { if case .deal = $0 { true } else { false } })
        #expect(FreeTableReplayPlan.canExposeRunout(table.frame(after: dealIndex)))
    }

    @Test func cursorResumeConsumesEachCueOnceAndPlanExtensionKeepsPrefix() throws {
        var table = PracticeTableState(seed: 97, styles: [.station])
        try table.advanceBots()
        let old = FreeTableReplayPlan(table: table)
        var cursor = FreeTableReplayCursor()
        _ = cursor.advance(by: old.duration * 0.5, plan: old)
        let frozen = cursor.elapsed
        let snapshot = old.projection(at: frozen)
        #expect(old.projection(at: cursor.elapsed).frame == snapshot.frame)
        let first = cursor.advance(by: old.duration, plan: old)
        #expect(cursor.advance(by: 1000, plan: old).isEmpty)
        #expect(!first.isEmpty)
        try table.apply(table.legalActions.contains(.check) ? .check : .call, actionID: "append")
        try table.advanceBots()
        let extended = FreeTableReplayPlan(table: table)
        #expect(Array(extended.phases.prefix(old.phases.count)) == old.phases)
        #expect(Array(extended.cues.prefix(old.cues.count)) == old.cues)
    }

    @Test func configuredOverlapsAndReduceMotion() throws {
        let table = try FreeTableReplayFixtures.table("normal")
        let plan = FreeTableReplayPlan(table: table)
        #expect(plan.phases.first?.duration == 430)
        let overlap = plan.projection(at: 200)
        #expect(overlap.visuals.flights.count == 2)
        let reduced = FreeTableReplayPlan(table: table, reduceMotion: true)
        for time in stride(from: 0.0, through: reduced.duration, by: 23) {
            #expect(reduced.projection(at: time).visuals.flights.isEmpty)
            #expect(reduced.projection(at: time).visuals.winnerProgress == 0)
        }
        #expect(reduced.projection(at: reduced.duration).frame.stacks == table.review?.endingStacks)
    }

    @Test func nextHandRefillAddsOnlyAuthoritativeNewSupply() throws {
        let previous = try FreeTableReplayFixtures.table("sidepots")
        var next = previous
        try next.nextHand(handID: "next-refill")
        let plan = FreeTableReplayPlan(table: next, previous: previous)
        let refill = try #require(plan.phases.first { if case .refill = $0.work { true } else { false } })
        let count = previous.review!.endingStacks.filter { $0 == 0 }.count
        let original = previous.review!.endingStacks.reduce(0, +)
        for fraction in [0.0, 0.25, 0.5, 1] {
            let p = plan.projection(at: refill.start + refill.duration * fraction)
            #expect(p.frame.stacks.reduce(0, +) + p.pot + p.inTransit == original + count * Int(100 * fraction))
            #expect(!p.heroExposed)
        }
    }

    @Test(arguments: ["refund", "award", "deal", "holes"])
    func pausedPhaseRemapsReduceMotionWithoutLosingPublicWorkOrMoney(work: String) throws {
        let table = try FreeTableReplayFixtures.table("sidepots")
        let normal = FreeTableReplayPlan(table: table)
        var reduced = FreeTableReplayPlan(table: table, reduceMotion: true)
        let phase = try #require(normal.phases.first { String(describing: $0.work).hasPrefix(work) })
        var cursor = FreeTableReplayCursor()
        _ = cursor.advance(by: phase.start + phase.duration * 0.71, plan: normal)
        let before = cursor.projection(plan: normal)
        let consumed = cursor.cueIndex
        reduced.preservePrefix(from: normal, at: cursor.elapsed)
        let after = cursor.projection(plan: reduced)
        #expect(after.frame.stacks == before.frame.stacks)
        #expect(after.pot == before.pot)
        #expect(after.inTransit == before.inTransit)
        #expect(after.shownSteps == before.shownSteps)
        #expect(after.visibleBoard.count >= before.visibleBoard.count)
        #expect(after.visuals.exposed.isSuperset(of: before.visuals.exposed))
        #expect(cursor.cueIndex == consumed)
        let once = cursor.advance(by: reduced.duration, plan: reduced)
        #expect(cursor.cueIndex == reduced.cues.count)
        #expect(once.count == reduced.cues.count - consumed)
        #expect(cursor.advance(by: 10000, plan: reduced).isEmpty)
    }

    @Test func runoutFacesKeepSixHundredSpacingAcrossStreetBoundaries() throws {
        let table = try FreeTableReplayFixtures.table("runout")
        let plan = FreeTableReplayPlan(table: table)
        var flips: [Double] = []
        for phase in plan.phases {
            if case let .deal(_, street, true) = phase.work {
                for index in 0..<(street == .flop ? 3 : 1) { flips.append(phase.start + Double(index) * 600 + 400) }
            }
        }
        #expect(flips.count == 5)
        for index in 1..<flips.count { #expect(flips[index] - flips[index - 1] == 600) }
        for phase in plan.phases {
            if case let .deal(step, _, _) = phase.work {
                #expect(plan.allInAmount(seat: 0, after: step) == 100)
            }
        }
    }

    @Test func activeSidePotAmountDoesNotIncludeOtherPots() throws {
        let table = try FreeTableReplayFixtures.table("sidepots")
        let plan = FreeTableReplayPlan(table: table)
        let phase = try #require(plan.phases.first { if case .award = $0.work { true } else { false } })
        let p = plan.projection(at: phase.start)
        let index = try #require(p.potIndex)
        #expect(p.remainingPots[index] == table.review!.pots[index].amount)
        #expect(p.remainingPots[index] < p.pot)
        let middle = plan.projection(at: phase.start + phase.duration * 0.5)
        #expect(middle.remainingPots[index] < p.remainingPots[index])
        #expect(middle.remainingPots.reduce(0, +) == middle.pot)
    }

    @Test func changingSpeedAdvancesTheSameCursorWithoutReplayingCues() throws {
        let plan = FreeTableReplayPlan(table: try FreeTableReplayFixtures.table("runout"))
        var cursor = FreeTableReplayCursor()
        let first = cursor.advance(by: 400, plan: plan)
        let frozen = cursor.elapsed
        let fast = cursor.advance(by: 100 * 3, plan: plan)
        #expect(cursor.elapsed == frozen + 300)
        #expect(first.count + fast.count == cursor.cueIndex)
        #expect(cursor.advance(by: 0, plan: plan).isEmpty)
    }

    @Test(arguments: [false, true])
    func togglingMotionPreservesClearBlindAndRevealSubphasesInBothDirections(wasReduced: Bool) throws {
        let previous = try FreeTableReplayFixtures.table("sidepots")
        var next = previous
        try next.nextHand(handID: "provenance-next")
        for (table, prior, name, fraction) in [(previous, nil as PracticeTableState?, "blinds", 0.71),
                                              (previous, nil, "reveal", 0.29),
                                              (next, previous, "clear", 0.71),
                                              (next, previous, "refill", 0.71),
                                              (next, previous, "dealer", 0.71)] {
            let old = FreeTableReplayPlan(table: table, previous: prior, reduceMotion: wasReduced)
            var new = FreeTableReplayPlan(table: table, previous: prior, reduceMotion: !wasReduced)
            let phase = try #require(old.phases.first { String(describing: $0.work).hasPrefix(name) })
            var cursor = FreeTableReplayCursor()
            _ = cursor.advance(by: phase.start + phase.duration * fraction, plan: old)
            let before = cursor.projection(plan: old)
            new.preservePrefix(from: old, at: cursor.elapsed)
            let after = cursor.projection(plan: new)
            #expect(after.frame == before.frame)
            #expect(after.shownSteps == before.shownSteps)
            #expect(after.pot == before.pot)
            #expect(after.visibleHole == before.visibleHole)
            #expect(after.visibleBoard == before.visibleBoard)
            #expect(after.visuals.arrived == before.visuals.arrived)
            #expect(after.visuals.exposed == before.visuals.exposed)
            #expect(after.visuals.flipping == before.visuals.flipping)
            _ = cursor.advance(by: new.duration, plan: new)
            let final = cursor.projection(plan: new)
            if prior != nil {
                #expect(final.visuals.exposed == [0])
                #expect(final.visibleHole[0] == next.learnerHole)
                #expect(final.visibleHole.dropFirst().allSatisfy { $0.isEmpty })
            }
        }
    }
}
