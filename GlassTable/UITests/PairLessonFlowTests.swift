// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

final class PairLessonFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testExactResumeAndSeparateIndependentAndCorrectionScores() throws {
        let app = launch(english: true, accessibility: false)
        openLesson(app)
        XCTAssertEqual(element("phase", app).label, "Worked example")
        XCTAssertTrue(element("explanation", app).exists)
        XCTAssertFalse(button("submit", app).exists)
        tap("next", app)

        let firstGuidedDeal = try deal(in: app)
        let wrongFirstGuided = try winner(of: firstGuidedDeal).other
        XCTAssertFalse(element("explanation", app).exists)
        XCTAssertFalse(button("submit", app).isEnabled)
        tap(wrongFirstGuided.button, app)
        tap("close", app)
        openLesson(app)
        XCTAssertEqual(try deal(in: app), firstGuidedDeal)
        XCTAssertFalse(element("explanation", app).exists)
        XCTAssertTrue(button("submit", app).isEnabled, "The selected draft survives closing.")
        tap("submit", app)
        let explanation = element("explanation", app)
        XCTAssertTrue(explanation.waitForExistence(timeout: 5))
        let firstExplanation = explanation.label
        XCTAssertEqual(element("feedback", app).label, "Incorrect")
        let submittedChoice = element("submitted-choice", app).label

        app.terminate()
        app.launch()
        openLesson(app)
        XCTAssertTrue(explanation.waitForExistence(timeout: 5))
        XCTAssertEqual(explanation.label, firstExplanation)
        XCTAssertEqual(element("submitted-choice", app).label, submittedChoice)
        XCTAssertFalse(button("submit", app).exists)
        tap("next", app)
        try answer(winner(of: deal(in: app)), in: app)

        var missedSoloDeal: Deal?
        for index in 1...8 {
            XCTAssertEqual(element("phase", app).label, "Independent \(index) of 8")
            let current = try deal(in: app)
            let correct = try winner(of: current)
            if index == 1 {
                tap("hint", app)
                XCTAssertTrue(element("hint-content", app).waitForExistence(timeout: 5))
                tap("hint", app)
                XCTAssertTrue(element("hint-content", app).waitForNonExistence(timeout: 5))
                try answer(correct, in: app)
            } else if index == 2 {
                missedSoloDeal = current
                try answer(correct.other, in: app)
            } else {
                try answer(correct, in: app)
            }
        }

        XCTAssertEqual(element("phase", app).label, "Correction 1 of 2")
        XCTAssertEqual(try deal(in: app), firstGuidedDeal)
        XCTAssertFalse(button("hint", app).exists)
        XCTAssertFalse(button("submit", app).isEnabled)
        try answer(winner(of: firstGuidedDeal), in: app)

        let secondMiss = try XCTUnwrap(missedSoloDeal)
        XCTAssertEqual(element("phase", app).label, "Correction 2 of 2")
        XCTAssertEqual(try deal(in: app), secondMiss)
        try answer(winner(of: secondMiss).other, in: app)

        XCTAssertTrue(element("first-score", app).waitForExistence(timeout: 5))
        XCTAssertEqual(element("first-score", app).label, "6 of 8 correct")
        XCTAssertEqual(element("assisted-count", app).label, "Hints used on 1 of 8 hands")
        XCTAssertEqual(element("retry-score", app).label, "1 of 2 correct on the second try")
        attach(app, "pair-lesson-en-results")
        tap("done", app)
        XCTAssertTrue(button("done", app).waitForNonExistence(timeout: 5))
    }

    func testKoreanAX5OptionsAndPinnedNextAreReachable() {
        let app = launch(english: false, accessibility: true)
        openLesson(app)
        XCTAssertEqual(element("phase", app).label, "풀이 예제")
        attach(app, "pair-lesson-ko-ax5-example")
        tap("next", app)

        XCTAssertEqual(element("phase", app).label, "안내 연습 1 / 2")
        tap("hint", app)
        XCTAssertTrue(element("hint-content", app).waitForExistence(timeout: 5))
        tap("hint", app)
        tap("choose-learner", app, back: true)
        XCTAssertTrue(button("submit", app).isHittable)
        attach(app, "pair-lesson-ko-ax5-choice")
        tap("submit", app)
        XCTAssertTrue(element("feedback", app).waitForExistence(timeout: 5))
        XCTAssertTrue(button("next", app).isHittable)
        let explanation = element("explanation", app)
        reveal(explanation, in: app)
        attach(app, "pair-lesson-ko-ax5-feedback")
        tap("next", app)
        XCTAssertEqual(element("phase", app).label, "안내 연습 2 / 2")
    }

    private func launch(english: Bool, accessibility: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_DEMO_LANGUAGE": english ? "en" : "ko"]
        app.launchArguments = ["-UIPreferredContentSizeCategoryName",
                               accessibility ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launch()
        return app
    }

    private func openLesson(_ app: XCUIApplication) {
        let row = app.buttons["learn-pair-lesson"]
        XCTAssertTrue(row.waitForExistence(timeout: 15))
        for _ in 0..<8 {
            if row.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(row.isHittable)
        row.tap()
        XCTAssertTrue(button("close", app).waitForExistence(timeout: 10))
    }

    private func element(_ name: String, _ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "pair-lesson-\(name)").firstMatch
    }

    private func button(_ name: String, _ app: XCUIApplication) -> XCUIElement {
        app.buttons["pair-lesson-\(name)"]
    }

    private func tap(_ name: String, _ app: XCUIApplication, back: Bool = false) {
        let target = button(name, app)
        XCTAssertTrue(target.waitForExistence(timeout: 5), name)
        reveal(target, in: app, back: back)
        target.tap()
    }

    private func reveal(_ target: XCUIElement, in app: XCUIApplication, back: Bool = false) {
        let scroll = app.scrollViews["pair-lesson-scroll"]
        func reachable() -> Bool {
            guard target.isHittable else { return false }
            let dock = button("next", app).exists ? button("next", app) : button("submit", app)
            if !dock.exists || [dock.identifier, "pair-lesson-close"].contains(target.identifier) { return true }
            return target.frame.midY < dock.frame.minY && target.frame.midY > button("close", app).frame.maxY
        }
        for _ in 0..<8 {
            if reachable() { break }
            if back { scroll.swipeDown() }
            else { scroll.swipeUp() }
        }
        XCTAssertTrue(reachable(), target.debugDescription)
    }

    private struct Deal: Equatable {
        let board: String
        let learner: String
        let opponent: String
    }

    private enum Side {
        case learner, opponent

        var button: String { self == .learner ? "choose-learner" : "choose-opponent" }
        var other: Side { self == .learner ? .opponent : .learner }
    }

    private func deal(in app: XCUIApplication) throws -> Deal {
        let board = element("board", app)
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        return try Deal(board: XCTUnwrap(board.value as? String),
                        learner: XCTUnwrap(element("learner-cards", app).value as? String),
                        opponent: XCTUnwrap(element("opponent-cards", app).value as? String))
    }

    private func winner(of deal: Deal) throws -> Side {
        let ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
        func rank(of cards: String) throws -> Int {
            let first = try XCTUnwrap(cards.split(separator: " ").first)
            return try XCTUnwrap(ranks.firstIndex(of: String(first)))
        }
        return try rank(of: deal.learner) > rank(of: deal.opponent) ? .learner : .opponent
    }

    private func answer(_ side: Side, in app: XCUIApplication) throws {
        tap(side.button, app)
        tap("submit", app)
        XCTAssertTrue(element("explanation", app).waitForExistence(timeout: 5))
        tap("next", app)
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
