// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

final class UnitBFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testPairLessonOpensAndStillWaitsAfterAnUnfinishedAttempt() {
        let app = launch(lesson: "b2")
        XCTAssertTrue(button("open-pair", app).isHittable)
        XCTAssertFalse(button("continue-pair", app).exists)
        attach(app, "unit-b-pair-handoff-en-light")
        tap("open-pair", app)
        let pairClose = app.buttons["pair-lesson-close"]
        XCTAssertTrue(pairClose.waitForExistence(timeout: 10))
        pairClose.tap()
        XCTAssertTrue(button("open-pair", app).waitForExistence(timeout: 10))
        XCTAssertFalse(button("continue-pair", app).exists)
    }

    func testBestFiveDraftAndRevealResumeWithoutAnEarlyAnswer() {
        let app = launch(lesson: "b10")
        XCTAssertTrue(activity("B10-example", app).exists)
        attach(app, "unit-b-best-five-example-en-light")
        tap("next", app)
        XCTAssertTrue(activity("B10-01", app).exists)
        XCTAssertFalse(element("explanation", app).exists)
        XCTAssertFalse(button("submit", app).isEnabled)
        let firstCard = button("card-0", app)
        XCTAssertTrue(firstCard.exists)
        let firstCardName = firstCard.label
        XCTAssertEqual(element("selection-count", app).label, "Selected 0/5")
        tap("card-0", app)
        tap("card-2", app)
        reopen(app)
        XCTAssertTrue(activity("B10-01", app).exists)
        XCTAssertEqual(firstCard.label, firstCardName)
        XCTAssertEqual(element("selection-count", app).label, "Selected 2/5")
        XCTAssertFalse(element("explanation", app).exists)
        XCTAssertFalse(button("submit", app).isEnabled)
        tap("card-3", app)
        tap("card-4", app)
        tap("card-5", app)
        XCTAssertFalse(button("card-6", app).isEnabled)
        XCTAssertTrue(firstCard.isEnabled, "A picked card stays removable at the limit.")
        attach(app, "unit-b-best-five-draft-en-light")
        tap("submit", app)
        XCTAssertEqual(element("feedback", app).label, "Not quite")
        let explanation = element("explanation", app).label
        XCTAssertFalse(explanation.isEmpty)
        let wrongPick = element("evidence-0", app)
        let expectedCard = element("evidence-6", app)
        XCTAssertEqual(wrongPick.label, firstCardName + ", your pick")
        XCTAssertTrue(expectedCard.label.hasSuffix(", in the best five"))
        attach(app, "unit-b-best-five-feedback-en-light")
        reopen(app)
        XCTAssertTrue(activity("B10-01", app).exists)
        XCTAssertEqual(element("explanation", app).label, explanation)
        XCTAssertEqual(wrongPick.label, firstCardName + ", your pick")
        XCTAssertTrue(expectedCard.label.hasSuffix(", in the best five"))
        XCTAssertFalse(button("submit", app).exists)
        XCTAssertTrue(button("next", app).isHittable)
    }

    func testKickerAndSplitExplainTheCommittedOutcome() {
        let kicker = launch(lesson: "b11")
        XCTAssertTrue(activity("B11-example", kicker).exists)
        attach(kicker, "unit-b-kicker-example-en-light")
        tap("next", kicker)
        XCTAssertTrue(activity("B11-01", kicker).exists)
        XCTAssertFalse(element("explanation", kicker).exists)
        tap("choice-0", kicker)
        tap("submit", kicker)
        XCTAssertEqual(element("feedback", kicker).label, "Correct")
        XCTAssertFalse(element("explanation", kicker).label.isEmpty)
        attach(kicker, "unit-b-kicker-feedback-en-light")
        kicker.terminate()

        let split = launch(lesson: "b12", english: false, largeText: true)
        XCTAssertTrue(activity("B12-example", split).exists)
        tap("next", split)
        XCTAssertTrue(activity("B12-01", split).exists)
        let tie = button("choice-2", split)
        XCTAssertTrue(tie.exists)
        XCTAssertFalse(element("explanation", split).exists)
        reveal(tie, in: split)
        attach(split, "unit-b-split-prompt-ko-dark-ax5")
        tap("choice-2", split)
        tap("submit", split)
        XCTAssertEqual(element("feedback", split).label, "맞았어요")
        XCTAssertFalse(element("explanation", split).label.isEmpty)
        reveal(element("explanation", split), in: split)
        attach(split, "unit-b-split-feedback-ko-dark-ax5")
        XCTAssertTrue(button("next", split).isHittable)
    }

    func testCheckpointCompletesAllFourKindsAndKeepsTheScore() {
        let app = launch(lesson: "b13")
        XCTAssertTrue(activity("B13-example", app).exists)
        tap("next", app)
        XCTAssertTrue(activity("B13-01", app).exists)
        XCTAssertFalse(element("explanation", app).exists)
        tap("choice-0", app)
        tap("submit", app)
        XCTAssertEqual(element("feedback", app).label, "Correct")
        tap("next", app)
        XCTAssertTrue(activity("B13-02", app).exists)
        XCTAssertEqual(element("selection-count", app).label, "Selected 0/5")
        XCTAssertFalse(button("submit", app).isEnabled)
        XCTAssertFalse(element("explanation", app).exists)
        attach(app, "unit-b-checkpoint-en-light")
        for index in [0, 2, 3, 4, 5] { tap("card-\(index)", app) }
        tap("submit", app)
        XCTAssertEqual(element("feedback", app).label, "Correct")
        tap("next", app)
        for (id, index) in [("B13-03", 1), ("B13-04", 2)] {
            XCTAssertTrue(activity(id, app).exists)
            tap("choice-\(index)", app)
            tap("submit", app)
            XCTAssertEqual(element("feedback", app).label, "Correct")
            tap("next", app)
        }
        XCTAssertEqual(element("title", app).label, "Checkpoint results")
        XCTAssertEqual(element("first-score", app).label, "4 of 4 correct")
        tap("next", app)
        XCTAssertEqual(element("title", app).label, "Unit complete")
        XCTAssertTrue(element("earlier-b2", app).label.contains("Previous best"))
        attach(app, "unit-b-complete-en-light")
    }

    private func launch(lesson: String, english: Bool = true, largeText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_DEMO_UNIT_B": lesson, "GT_DEMO_LANGUAGE": english ? "en" : "ko"]
        app.launchArguments = ["-appAppearance", english ? "light" : "dark",
                               "-UIPreferredContentSizeCategoryName",
                               largeText ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launch()
        XCTAssertTrue(button("close", app).waitForExistence(timeout: 15))
        return app
    }

    private func reopen(_ app: XCUIApplication) {
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "GT_DEMO_UNIT_B")
        app.launch()
        let row = app.buttons["learn-unit-b"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        for _ in 0..<6 where !row.isHittable { app.swipeUp() }
        XCTAssertTrue(row.isHittable)
        row.tap()
        XCTAssertTrue(button("close", app).waitForExistence(timeout: 10))
    }

    private func tap(_ name: String, _ app: XCUIApplication) {
        let target = button(name, app)
        XCTAssertTrue(target.waitForExistence(timeout: 6), name)
        if name.hasPrefix("choice-") || name.hasPrefix("card-") { reveal(target, in: app) }
        XCTAssertTrue(target.isHittable, name)
        target.tap()
    }

    private func reveal(_ target: XCUIElement, in app: XCUIApplication) {
        let scroll = app.scrollViews["unit-b-scroll"]
        let submit = button("submit", app)
        let dock = submit.exists ? submit : button("next", app)
        let top = button("close", app).frame.maxY
        let bottom = dock.frame.minY
        for _ in 0..<8 {
            let middle = target.frame.midY
            if target.isHittable && middle > top && middle < bottom { return }
            if middle < top { scroll.swipeDown() } else { scroll.swipeUp() }
        }
        XCTFail("Element never entered the lesson viewport: \(target.debugDescription)")
    }

    private func activity(_ id: String, _ app: XCUIApplication) -> XCUIElement {
        element("activity-\(id)", app)
    }

    private func button(_ name: String, _ app: XCUIApplication) -> XCUIElement {
        app.buttons["unit-b-\(name)"]
    }

    private func element(_ name: String, _ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "unit-b-\(name)").firstMatch
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
