// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine
import Testing
@testable import GlassTableDrills

private let now = Date(timeIntervalSince1970: 1_800_000_000)

private func answer(_ id: String, ordinal: Int, assisted: Bool = false) -> RoundAnswer {
    RoundAnswer(attemptID: id, ordinal: ordinal, band: .spotOn, submittedAt: now,
                input: Data([1]), reveal: Data([1]), assisted: assisted)
}

private func review() -> ReviewSessionSnapshot {
    ReviewSessionSnapshot(id: "r", seed: 1, scheduledConcepts: ["potOdds", "outs"])
}

@Test func onlyTheOpenQuestionKeepsADraft() throws {
    var session = review()
    let input = SavedDrillDraftInput.integer(30)
    let draft = try #require(session.draft(for: 0, input: input))
    #expect(draft == SavedDrillDraft(ordinal: 0, concept: "potOdds", input: input))
    #expect(session.draft(for: 1, input: input) == nil, "A later question is not open yet.")
    #expect(session.draft(for: 0, input: .potReplay(stepIndex: 0)) == nil, "Input must fit the concept.")
    session.reveal(answer("a", ordinal: 0), concept: .potOdds)
    #expect(session.draft(for: 0, input: input) == nil, "An answered question keeps no draft.")
}

@Test func anAnswerIsTakenOnceAndOnlyForTheOpenQuestion() {
    var session = review()
    #expect(session.acceptsAnswer(attemptID: "a", ordinal: 1) == .refused)
    #expect(session.acceptsAnswer(attemptID: "a", ordinal: 0) == .apply)
    session.draft = SavedDrillDraft(ordinal: 0, concept: "potOdds", input: .integer(30))
    session.reveal(answer("a", ordinal: 0), concept: .potOdds)
    #expect(session.step == .reveal && session.draft == nil)
    #expect(session.answers.map(\.concept) == ["potOdds"])
    #expect(session.acceptsAnswer(attemptID: "a", ordinal: 0) == .alreadyApplied)
    #expect(session.acceptsAnswer(attemptID: "b", ordinal: 0) == .refused, "The reveal is showing.")
}

@Test func helpOpenedOnTheQuestionKeepsItAssisted() {
    var session = review()
    session.helpOrdinal = 0
    #expect(session.isAssisted(false, ordinal: 0))
    #expect(!session.isAssisted(false, ordinal: 1))
    #expect(session.isAssisted(true, ordinal: 1))
}

@Test func movingOnClearsHelpAndFinishesAfterTheLastQuestion() {
    var session = review()
    #expect(session.acceptsNext(afterOrdinal: 0) == .refused, "Nothing is revealed yet.")
    session.helpOrdinal = 0
    session.reveal(answer("a", ordinal: 0), concept: .potOdds)
    #expect(session.acceptsNext(afterOrdinal: 0) == .apply)
    session.moveOn()
    #expect(session.ordinal == 1 && session.step == .question && session.helpOrdinal == nil)
    #expect(session.acceptsNext(afterOrdinal: 0) == .alreadyApplied)
    session.reveal(answer("b", ordinal: 1), concept: .outs)
    session.moveOn()
    #expect(session.ordinal == 1 && session.step == .finished)
    #expect(session.acceptsNext(afterOrdinal: 1) == .alreadyApplied)
}

@Test func aRoundAsksItsOneConceptForEveryQuestion() {
    var round = PracticeRound(id: "p", concept: "outs", seed: 1, questionCount: 2)
    #expect(round.concept(at: 1) == .outs)
    round.reveal(answer("a", ordinal: 0), concept: .outs)
    round.moveOn()
    round.reveal(answer("b", ordinal: 1), concept: .outs)
    round.moveOn()
    #expect(round.phase == .finished && round.answers.count == 2)
}

@Test func aLessonStillTeachingTakesNoAnswer() {
    var lesson = NodeSessionSnapshot(id: "n", nodeID: "x", seed: 1,
                                     scheduledConcepts: ["potOdds"], phase: .show)
    #expect(lesson.step == nil)
    #expect(lesson.acceptsAnswer(attemptID: "a", ordinal: 0) == .refused)
    #expect(lesson.draft(for: 0, input: .integer(30)) == nil)
    lesson.phase = .question
    #expect(lesson.acceptsAnswer(attemptID: "a", ordinal: 0) == .apply)
}

@Test func anAssistedAnswerCountsAsPracticeButLeavesTheScheduleAlone() {
    var state = ProgressState()
    state.recordGradedAnswer(concept: .potOdds, band: .spotOn, mode: "review", formatVersion: 1,
                             language: "en", assisted: true, attemptID: "a", interval: nil,
                             evLoss: nil, eligibleSeconds: 4, now: now, scheduler: FSRSScheduler())
    #expect(state.record(for: .potOdds) == ConceptRecord())
    #expect(state.assistedAttempts(for: .potOdds) == 1)
    #expect(state.recentEvidence.last?.eligibleCorrectSeconds == nil, "Help hides recall speed.")
}

@Test func onlyAnUnassistedExactAnswerTimesRecall() {
    var state = ProgressState()
    func record(_ id: String, band: GradeBand, evLoss: Double?) {
        state.recordGradedAnswer(concept: .evCall, band: band, mode: "path", formatVersion: 2,
                                 language: "ko", assisted: false, attemptID: id, interval: nil,
                                 evLoss: evLoss, eligibleSeconds: 4, now: now, scheduler: FSRSScheduler())
    }
    record("exact", band: .spotOn, evLoss: 0)
    record("costly", band: .spotOn, evLoss: 0.5)
    record("near", band: .close, evLoss: nil)
    #expect(state.recentEvidence.map(\.eligibleCorrectSeconds) == [4, nil, nil])
    #expect(state.recentEvidence.allSatisfy { $0.key.mode == "path" && $0.key.formatVersion == 2 })
    #expect(state.record(for: .evCall) != ConceptRecord(), "An unassisted answer is scheduled.")
}
