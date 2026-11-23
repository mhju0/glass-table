// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Testing
@testable import GlassTableDrills

@Suite struct UnitCContentTests {
    private let lessons: [TableCourseLesson] = [.c1, .c2, .c3, .c4, .c5, .c6, .c7, .c8, .c9]
    private let limp: [PracticeAction] = [.call, .call, .call, .check]

    @Test func lessonsHaveWorkedDiagramsAndHeldOutQuestionsInBothLanguages() throws {
        var ids = Set<String>()
        for lesson in lessons {
            let activities = BettingUnitContent.activities(for: lesson)
            let example = try #require(activities.first)
            #expect(example.isExample)
            #expect(activities.count >= 4)

            let heldOut = BettingUnitContent.reviewQuestions(for: lesson)
            #expect(heldOut.count == 3)
            for question in activities.dropFirst() + heldOut {
                let correct = try #require(question.correctChoice)
                #expect((0..<question.optionCount).contains(correct))
                for language in LearningLanguage.allCases {
                    let choices = question.choices(in: language)
                    #expect(Set(choices).count == choices.count)
                    #expect(choices.allSatisfy { !$0.isEmpty })
                }
            }
            for activity in activities + heldOut {
                #expect(ids.insert(activity.id).inserted)
                #expect((2...4).contains(activity.evidence.seats.count))
                for language in LearningLanguage.allCases {
                    #expect(!activity.title(in: language).isEmpty)
                    #expect(!(activity.prompt(in: language) ?? "").isEmpty)
                    #expect(!(activity.explanation(in: language) ?? "").isEmpty)
                }
            }
        }
    }

    @Test func blindMarkersAndPreflopOrderRotateClockwise() throws {
        let worked = try #require(BettingUnitContent.activities(for: .c1).first)
        #expect(worked.evidence.seats.map(\.chips) == [nil, 1, 2, nil])
        #expect(worked.evidence.seats.map { $0.detail?.text(in: .english) } == ["Button", "SB", "BB", nil])
        #expect(try answer(.c1, "C1-01") == "Seat 3")
        #expect(try answer(.c1, "C1-02") == "Seat 1")
        #expect(try answer(.c1, "C1-03") == "Seat 4")

        for dealer in 1...3 {
            let table = PracticeTableState.fixture(seed: 17, stacks: [100, 100, 100, 100], dealer: dealer)
            #expect(table.currentSeat == dealer - 1)
            let exercise = try activity(.c2, "C2-0\(dealer)")
            #expect(exercise.evidence.seats.allSatisfy { !$0.highlighted })
            #expect(try correctText(exercise) == "Seat \(dealer)")
            #expect(exercise.revealedEvidence?.seats[dealer - 1].highlighted == true)
        }
    }

    @Test func flopOrderSkipsAFoldedSeatAfterTheButton() throws {
        var table = PracticeTableState.fixture(seed: 22, stacks: [100, 100, 100, 100], dealer: 2)
        try play([.fold, .call, .fold, .check], on: &table)
        #expect(table.street == .flop)
        #expect(table.currentSeat == 0)
        #expect(table.seats.map(\.folded) == [false, true, false, true])

        let exercise = try activity(.c3, "C3-02")
        #expect(exercise.evidence.seats.map(\.folded) == [false, true, false, true])
        #expect(exercise.evidence.board.count == 3)
        #expect(try correctText(exercise) == "Seat 1")
        #expect(exercise.revealedEvidence?.seats[0].highlighted == true)
    }

    @Test func zeroOwedLetsThePlayerCheckOrOpen() throws {
        var table = PracticeTableState.fixture(seed: 28, stacks: [100, 100, 100, 100], dealer: 2)
        try play(limp + [.check], on: &table)
        #expect(table.amountToCall == 0)
        #expect(table.legalActions == [.check, .raise(to: 2)])
        try play([.raise(to: 2)], on: &table)
        #expect(table.events.last?.label == "bet")

        #expect(try answer(.c4, "C4-01") == "Check")
        #expect(try answer(.c4, "C4-02") == "Bet")
        let exercise = try activity(.c4, "C4-02")
        #expect(exercise.evidence.seats[0].highlighted)
        #expect(exercise.evidence.rows.last?.value.text(in: .english) == "0 chips")
    }

    @Test func callAddsOnlyTheUnpaidAmount() throws {
        var table = PracticeTableState.fixture(seed: 31, stacks: [100, 100, 100, 100], dealer: 1)
        try play([.raise(to: 6), .call], on: &table)
        #expect(table.currentSeat == 2)
        #expect(table.seats[2].streetCommitted == 1)
        #expect(table.amountToCall == 5)
        #expect(table.legalActions == [.fold, .call, .raise(to: 10)])
        try play([.call], on: &table)
        #expect(table.events.last?.chips == 5)
        #expect(table.seats[2].streetCommitted == 6)

        let exercise = try activity(.c5, "C5-01")
        #expect(exercise.evidence.seats[2].chips == 1)
        #expect(try correctText(exercise) == "Call · add 5")
        #expect(try answer(.c5, "C5-02") == "Fold")
        #expect(try answer(.c5, "C5-03") == "Raise")
    }

    @Test func fullBetAndRaiseMinimaRejectOneChipLess() throws {
        let cases: [(id: String, actions: [PracticeAction], minimum: Int)] = [
            ("C6-01", [], 2),
            ("C6-02", [.raise(to: 4)], 8),
            ("C6-03", [.raise(to: 4), .raise(to: 10)], 16),
        ]
        for (offset, entry) in cases.enumerated() {
            var table = PracticeTableState.fixture(seed: 45, stacks: [100, 100, 100, 100], dealer: offset + 1)
            try play(limp + entry.actions, on: &table)
            #expect(table.legalActions.contains(.raise(to: entry.minimum)))
            #expect(throws: PracticeTableError.illegalAction) {
                try table.apply(.raise(to: entry.minimum - 1), actionID: "too-small")
            }
            try play([.raise(to: entry.minimum)], on: &table)
            #expect(try answer(.c6, entry.id) == "\(entry.minimum) chips")
        }
    }

    @Test func laterSeatHasSeenTheEarlierCheck() throws {
        var table = PracticeTableState.fixture(seed: 71, stacks: [100, 100, 100, 100], dealer: 3)
        try play(limp + [.check], on: &table)
        #expect(table.events.last?.seat == 0)
        #expect(table.events.last?.action == .check)
        #expect(table.currentSeat == 1)
        let exercise = try activity(.c7, "C7-03")
        #expect(exercise.evidence.seats[1].highlighted)
        #expect(try correctText(exercise) == "Seat 1 checking")
    }

    @Test func headsUpButtonPostsSmallBlindAndActsLastAfterTheFlop() throws {
        var table = PracticeTableState(seed: 56, styles: [.tag])
        try play([.fold], on: &table)
        try table.nextHand(handID: "rotated")
        #expect(table.dealer == 1)
        #expect(table.currentSeat == 1)
        #expect(table.events.first?.seat == 1)
        #expect(table.events.first?.chips == 1)
        try play([.call, .check], on: &table)
        #expect(table.street == .flop)
        #expect(table.currentSeat == 0)
        try play([.check], on: &table)
        #expect(table.currentSeat == 1)

        #expect(try answer(.c8, "C8-01") == "Seat 2")
        #expect(try answer(.c8, "C8-02") == "Seat 1")
        #expect(try answer(.c8, "C8-03") == "Seat 2")
    }

    @Test func transitionExercisesRevealOnlyAfterAction() throws {
        var limped = PracticeTableState.fixture(seed: 81, stacks: [100, 100, 100, 100], dealer: 1)
        try play([.call, .call, .call], on: &limped)
        #expect(limped.currentSeat == 3)
        #expect(limped.street == .preflop)
        #expect(limped.seats.map(\.streetCommitted) == [2, 2, 2, 2])
        let blindTurn = try activity(.c9, "C9-01")
        #expect(try correctText(blindTurn) == "Seat 4")
        #expect(blindTurn.revealedEvidence?.board.count == 0)
        #expect(blindTurn.revealedEvidence?.seats[3].highlighted == true)
        try play([.check], on: &limped)
        #expect(limped.street == .flop)

        for id in ["C9-03", "C9-05"] {
            let endsRound = try activity(.c9, id)
            #expect(try correctText(endsRound) == "Deal the turn")
            #expect(endsRound.evidence.board.count == 3)
            #expect(endsRound.revealedEvidence?.board.count == 4)
        }
        #expect(try answer(.c9, "C9-02") == "Seat 1")
        let unanswered = try activity(.c9, "C9-04")
        #expect(try correctText(unanswered) == "Seat 2")
        #expect(unanswered.revealedEvidence?.board.count == 3)
    }

    @Test func heldOutTransitionsIncludeBigBlindCheckTurnOrderAndHeadsUpCall() throws {
        let questions = BettingUnitContent.reviewQuestions(for: .c9)
        #expect(try questions.map(correctText) == ["Deal the flop", "Seat 1", "Deal the flop"])
        #expect(questions.map { $0.evidence.board.count } == [0, 4, 0])
        #expect(questions.map { $0.revealedEvidence?.board.count } == [3, 4, 3])
        #expect(questions.map { $0.evidence.seats.count } == [4, 4, 2])
        #expect(questions[1].revealedEvidence?.seats[0].highlighted == true)

        var headsUp = PracticeTableState(seed: 92, styles: [.tag])
        try play([.call, .raise(to: 5)], on: &headsUp)
        #expect(headsUp.amountToCall == 3)
        try play([.call], on: &headsUp)
        #expect(headsUp.street == .flop)
        #expect(headsUp.currentSeat == 1)
        #expect(questions[2].revealedEvidence?.seats[1].highlighted == true)
    }

    private func activity(_ lesson: TableCourseLesson, _ id: String) throws -> TableCourseActivity {
        try #require(BettingUnitContent.activities(for: lesson).first { $0.id == id })
    }

    private func correctText(_ activity: TableCourseActivity) throws -> String {
        let index = try #require(activity.correctChoice)
        return activity.choices(in: .english)[index]
    }

    private func answer(_ lesson: TableCourseLesson, _ id: String) throws -> String {
        try correctText(activity(lesson, id))
    }

    private func play(_ actions: [PracticeAction], on table: inout PracticeTableState) throws {
        for action in actions {
            try table.apply(action, actionID: "test-\(table.events.count)")
        }
    }
}
