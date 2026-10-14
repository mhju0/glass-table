// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Testing
@testable import GlassTableDrills

private let lesson = Curriculum.allNodes[0]
private let other = Curriculum.allNodes[1]

@Test func finishingBasicsOffersTheGuidedHandOnceTheCoverHasClosed() {
    var journey = BeginnerJourney()
    journey.present(.basics)
    journey.close(then: .invitation(lessonAfter: lesson))
    #expect(journey.presented == nil, "The next screen waits for the basics cover to leave.")
    #expect(journey.didDismiss() == .invitation(lessonAfter: lesson))
    #expect(journey.presented == .invitation(lessonAfter: lesson))
}

@Test func swipingTheInvitationAwayOpensNothing() {
    var journey = BeginnerJourney()
    journey.present(.invitation(lessonAfter: lesson))
    journey.close()
    #expect(journey.didDismiss() == nil)
    #expect(journey.presented == nil)
}

@Test func continuingFromTheInvitationOpensTheQueuedLesson() {
    var journey = BeginnerJourney()
    journey.present(.invitation(lessonAfter: lesson))
    journey.close(then: .lesson(lesson))
    journey.didDismiss()
    #expect(journey.presented == .lesson(lesson))
}

@Test func playingAfterTheGuidedHandSwitchesTabWithoutPresenting() {
    var journey = BeginnerJourney()
    journey.present(.guidedHand)
    journey.close(then: .play)
    #expect(journey.didDismiss() == .play)
    #expect(journey.presented == nil)
}

@Test func aStaleDismissalDoesNotCloseTheLessonThatReplacedIt() {
    var journey = BeginnerJourney()
    journey.present(.lesson(lesson))
    journey.present(.lesson(other))
    #expect(journey.didDismiss() == nil)
    #expect(journey.presented == .lesson(other))
}

@Test func closingAStepThatIsNoLongerShownChangesNothing() {
    var journey = BeginnerJourney()
    journey.present(.invitation(lessonAfter: lesson))
    journey.close(then: .guidedHand)
    // The sheet's binding reports the same dismissal again; the queued hand survives.
    journey.close(ifShowing: .invitation(lessonAfter: lesson))
    #expect(journey.didDismiss() == .guidedHand)
    #expect(journey.presented == .guidedHand)
}
