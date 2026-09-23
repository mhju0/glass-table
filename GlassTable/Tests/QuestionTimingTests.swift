import XCTest
@testable import GlassTable

final class QuestionTimingTests: XCTestCase {
    func testRestoredQuestionAndLateReadyNeverEarnTime() {
        var timing = QuestionTiming() // restored: no beginNewQuestion call
        timing.ready("round:0", uptime: 100)
        XCTAssertNil(timing.elapsed(for: "round:0", at: 103))

        timing.beginNewQuestion("round:1")
        timing.ready("round:1", uptime: 200)
        XCTAssertEqual(timing.elapsed(for: "round:1", at: 203), 3)
        timing.interrupt() // background, language change or disappearance
        timing.ready("round:1", uptime: 204) // late async equity completion
        XCTAssertNil(timing.elapsed(for: "round:1", at: 205))
        timing.beginNewQuestion("round:2")
        timing.ready("round:2", uptime: 300)
        XCTAssertEqual(timing.elapsed(for: "round:2", at: 302), 2)
    }

    func testReadyCannotResetTheClockOrUseAnotherQuestionKey() {
        var timing = QuestionTiming()
        timing.beginNewQuestion("node:0")
        timing.ready("node:wrong", uptime: 50)
        XCTAssertNil(timing.elapsed(for: "node:0", at: 53))
        timing.ready("node:0", uptime: 100)
        timing.ready("node:0", uptime: 102)
        XCTAssertEqual(timing.elapsed(for: "node:0", at: 103), 3)
        XCTAssertNil(timing.elapsed(for: "node:1", at: 103))
    }
}
