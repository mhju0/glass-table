// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

/// The best-five comparison appears only once an answer is locked in, in each place it
/// is used, and its seven fixed-size cards stay on screen at AX5.
final class BestFiveComparisonTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    /// You K♣ 6♦, opponent 5♦ 3♥, board Q♣ 6♠ K♦ J♥ 3♦: K two pair against a pair of threes.
    private static let example = "Kc6d,5d3h,Qc6sKdJh3d"
    private static let kicker = "AcKc,QdKd,Kh7s2d5c9h"
    private static let split = "2c3c,4d5d,AsKsQhJhTc"

    func testKOLessonThenRestored() { lessonThenRestored("ko", ax: false) }
    func testENLessonThenRestored() { lessonThenRestored("en", ax: false) }
    func testKOAXLessonThenRestored() { lessonThenRestored("ko", ax: true) }
    func testENAXLessonThenRestored() { lessonThenRestored("en", ax: true) }

    func testKOKickerAndSplit() {
        for (name, spot) in [("kicker", Self.kicker), ("split", Self.split)] {
            let app = launchLesson("ko", ax: false, spot: spot, store: UUID().uuidString)
            answer(app)
            let why = app.staticTexts["best-five-why"]
            XCTAssertTrue(why.waitForExistence(timeout: 10))
            if name == "kicker" {
                XCTAssertTrue(why.label.contains("키커"), why.label)
            } else {
                XCTAssertEqual(why.label, "둘 다 공용 카드 다섯 장을 써서 팟을 나눠요.")
                assertLabel(app, 0, contains: "내 카드 0장 · 공용 카드 5장")
                assertLabel(app, 1, contains: "상대 카드 0장 · 공용 카드 5장")
            }
            show(app, why)
            attach(app, "ko-large-lesson-\(name)")
            app.terminate()
        }
    }

    func testKOHandReview() { handReview("ko", ax: false) }
    func testENHandReview() { handReview("en", ax: false) }
    func testKOAXHandReview() { handReview("ko", ax: true) }
    func testENAXHandReview() { handReview("en", ax: true) }

    func testKOBasicsCheck() { basicsCheck("ko", ax: false) }
    func testENBasicsCheck() { basicsCheck("en", ax: false) }
    func testKOAXBasicsCheck() { basicsCheck("ko", ax: true) }
    func testENAXBasicsCheck() { basicsCheck("en", ax: true) }

    /// The first check (flush against straight) is dealt from seven cards too.
    func testKOFirstBasicsCheck() { basicsCheck("ko", ax: false, seed: nil, choice: "flush") }
    func testENFirstBasicsCheck() { basicsCheck("en", ax: false, seed: nil, choice: "flush") }
    func testKOAXFirstBasicsCheck() { basicsCheck("ko", ax: true, seed: nil, choice: "flush") }
    func testENAXFirstBasicsCheck() { basicsCheck("en", ax: true, seed: nil, choice: "flush") }

    /// The third page (owner, 2026-10-17): the same pair of Js, settled by the kicker.
    func testKOBasicsKicker() { basicsKicker("ko", ax: false) }
    func testENBasicsKicker() { basicsKicker("en", ax: false) }
    func testKOAXBasicsKicker() { basicsKicker("ko", ax: true) }
    func testENAXBasicsKicker() { basicsKicker("en", ax: true) }
    /// The duel is the point of the page: at the default size it comes into view on the
    /// answer, with no swipe (owner, 2026-10-17).
    func testKOKickerDuelInViewAfterAnswer() { kickerDuelInView("ko") }
    func testENKickerDuelInViewAfterAnswer() { kickerDuelInView("en") }

    /// Previous reopens an answered check as a fresh question on the same cards, and the
    /// page after it starts unanswered again (owner, 2026-10-18).
    func testENBasicsPreviousReopensChecksUnanswered() {
        let app = XCUIApplication()
        app.launchArguments = arguments("en", ax: false)
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_DEMO_BASICS": "check", "GT_DEMO_BASICS_SEED": "0"]
        app.launch()
        let verdict = app.descendants(matching: .any)["basics.verdict"]
        let straight = app.buttons["basics.choice.straight"]
        reach(straight, app: app)
        straight.tap()
        XCTAssertTrue(verdict.waitForExistence(timeout: 5))
        reach(app.buttons["basics.check-next"], app: app)
        app.buttons["basics.check-next"].tap()
        let mine = app.buttons["basics.kicker.choice.mine"]
        reach(mine, app: app)
        mine.tap()
        XCTAssertTrue(app.descendants(matching: .any)["basics.kicker-duel"].waitForExistence(timeout: 5))
        reach(app.buttons["basics.previous"], app: app)
        app.buttons["basics.previous"].tap()

        // The first check again: the same flush and straight, nothing picked or marked.
        let flush = app.buttons["basics.choice.flush"]
        reach(flush, app: app)
        XCTAssertTrue(straight.exists)
        XCTAssertFalse(verdict.exists)
        XCTAssertFalse(comparison(app).exists)
        attach(app, "en-large-basics-previous-check")
        flush.tap()
        XCTAssertTrue(verdict.waitForExistence(timeout: 5))
        XCTAssertTrue(verdict.label.contains("That's right"), verdict.label)
        reach(app.buttons["basics.check-next"], app: app)
        app.buttons["basics.check-next"].tap()
        reach(mine, app: app)
        XCTAssertFalse(verdict.exists)
        XCTAssertFalse(app.descendants(matching: .any)["basics.kicker-duel"].exists)

        // From an answered check back to the ladder, then forward: the check is fresh again.
        mine.tap()
        reach(app.buttons["basics.previous"], app: app)
        app.buttons["basics.previous"].tap()
        reach(flush, app: app)
        flush.tap()
        reach(app.buttons["basics.previous"], app: app)
        app.buttons["basics.previous"].tap()
        reach(app.buttons["basics.next"], app: app)
        app.buttons["basics.next"].tap()
        reach(flush, app: app)
        XCTAssertFalse(verdict.exists)
    }

    // MARK: Flows

    private func lessonThenRestored(_ language: String, ax: Bool) {
        let ko = language == "ko"
        let tag = "\(language)-\(ax ? "AX5" : "large")"
        let store = UUID().uuidString
        let app = launchLesson(language, ax: ax, spot: Self.example, store: store)
        XCTAssertTrue(choice(app).waitForExistence(timeout: 15))
        XCTAssertFalse(comparison(app).exists, "Never before the answer is locked in")
        answer(app)
        XCTAssertTrue(comparison(app).waitForExistence(timeout: 10))
        assertLabel(app, 0, contains: ko ? "내 카드 2장 · 공용 카드 3장" : "2 of your cards · 3 board cards")
        assertLabel(app, 1, contains: ko ? "상대 카드 1장 · 공용 카드 4장" : "1 of the opponent's cards · 4 board cards")
        let why = ko ? "내 K 투 페어가 상대 3 원 페어를 이겨요." : "Your two pair, K high, beats the opponent's pair of 3s."
        XCTAssertEqual(app.staticTexts["best-five-why"].label, why)
        assertSaidOnce(app, why)
        assertCardsFit(app)
        show(app, app.descendants(matching: .any)["best-five-row-0"])
        attach(app, "\(tag)-lesson-rows")
        show(app, app.staticTexts["best-five-why"])
        attach(app, "\(tag)-lesson-why")

        let completion = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "drill-completion-")).firstMatch
        XCTAssertTrue(completion.waitForExistence(timeout: 10))
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_DEMO_SHOWDOWN_SPOT": Self.example]
        app.launch()
        let resume = app.buttons["learn-continue"]
        reach(resume, app: app)
        resume.tap()
        XCTAssertTrue(comparison(app).waitForExistence(timeout: 10), "A restored answer shows the comparison too")
        assertSaidOnce(app, why)
        assertCardsFit(app)
        show(app, app.descendants(matching: .any)["best-five-row-0"])
        attach(app, "\(tag)-restored-rows")
        show(app, app.staticTexts["best-five-why"])
        attach(app, "\(tag)-restored-why")
    }

    /// The sentence under the cards is the whole explanation; the answer sheet must not repeat it.
    private func assertSaidOnce(_ app: XCUIApplication, _ text: String) {
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == %@", text)).count, 1, text)
    }

    private func handReview(_ language: String, ax: Bool) {
        let tag = "\(language)-\(ax ? "AX5" : "large")"
        for phase in ["result-review", "result-tie"] {
            let app = XCUIApplication()
            app.launchArguments = arguments(language, ax: ax)
            app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                     "GT_DEMO_LANGUAGE": language, "GT_DEMO_TAB": "play", "GT_DEMO_PRACTICE": "1",
                                     "GT_DEMO_FREE_PHASE": phase, "GT_DEMO_PLAYERS": "4"]
            app.launch()
            let review = app.buttons["free-review"]
            XCTAssertTrue(review.waitForExistence(timeout: 15))
            for _ in 0..<6 where !review.isHittable { app.swipeUp() }
            review.tap()
            let progress = app.staticTexts["coach-progress"]
            XCTAssertTrue(progress.waitForExistence(timeout: 5))
            let next = app.buttons["coach-next"]
            for _ in 0..<12 where next.exists {
                XCTAssertFalse(comparison(app).exists, "Only on the ending page")
                next.tap()
            }
            XCTAssertTrue(app.buttons["coach-done"].waitForExistence(timeout: 5))
            let element = comparison(app)
            for _ in 0..<8 where !element.exists { app.swipeUp() }
            XCTAssertTrue(element.exists, "The showdown ending compares the winner with whoever came closest")
            assertCardsFit(app)
            show(app, app.descendants(matching: .any)["best-five-row-0"])
            attach(app, "\(tag)-review-\(phase)-rows")
            show(app, app.staticTexts["best-five-why"])
            attach(app, "\(tag)-review-\(phase)-why")
            app.terminate()
        }
    }

    /// `seed` nil opens the first check, which a fresh store always deals.
    private func basicsCheck(_ language: String, ax: Bool, seed: String? = "5", choice id: String = "check-0") {
        let tag = "\(language)-\(ax ? "AX5" : "large")-\(seed == nil ? "first-" : "")"
        let app = XCUIApplication()
        app.launchArguments = arguments(language, ax: ax)
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_DEMO_BASICS": "check"]
        if let seed { app.launchEnvironment["GT_DEMO_BASICS_SEED"] = seed }
        app.launch()
        let choice = app.buttons["basics.choice.\(id)"]
        reach(choice, app: app)
        XCTAssertFalse(comparison(app).exists, "Never before the answer is locked in")
        choice.tap()
        let element = comparison(app)
        for _ in 0..<8 where !element.exists { app.swipeUp() }
        XCTAssertTrue(element.exists)
        if seed == nil {
            let ko = language == "ko"
            assertLabel(app, 0, contains: ko ? "플러시" : "flush")
            assertLabel(app, 0, contains: ko ? "내 카드 2장 · 공용 카드 3장" : "2 of your cards · 3 board cards")
            assertLabel(app, 1, contains: ko ? "스트레이트" : "straight")
            assertLabel(app, 1, contains: ko ? "상대 카드 2장 · 공용 카드 3장" : "2 of the opponent's cards · 3 board cards")
        }
        assertCardsFit(app)
        show(app, app.descendants(matching: .any)["best-five-row-0"])
        attach(app, "\(tag)basics-rows")
        show(app, app.staticTexts["best-five-why"])
        attach(app, "\(tag)basics-why")
    }

    /// From the second check's verdict on to the same-pair page: no rows, duel or term
    /// before the pick; afterwards the rows, the engine's line and the kicker duel.
    private func basicsKicker(_ language: String, ax: Bool) {
        let ko = language == "ko"
        let tag = "\(language)-\(ax ? "AX5" : "large")-"
        let app = XCUIApplication()
        app.launchArguments = arguments(language, ax: ax)
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_DEMO_BASICS": "check-right"]
        app.launch()
        let next = app.buttons["basics.check-next"]
        reach(next, app: app)
        XCTAssertEqual(next.label, ko ? "다음" : "Next")
        next.tap()

        let mine = app.buttons["basics.kicker.choice.mine"]
        reach(mine, app: app)
        XCTAssertTrue(app.staticTexts[ko ? "같은 페어라면?" : "Same pair?"].exists)
        XCTAssertEqual(app.buttons["basics.kicker.choice.theirs"].label, ko ? "상대가 이김" : "They win")
        XCTAssertEqual(app.buttons["basics.kicker.choice.tie"].label, ko ? "무승부" : "Tie")
        XCTAssertEqual(mine.label, ko ? "내가 이김" : "I win")
        XCTAssertFalse(comparison(app).exists, "Never before the answer is locked in")
        XCTAssertFalse(app.descendants(matching: .any)["basics.kicker-duel"].exists)
        XCTAssertFalse(app.buttons["basics.kicker-glossary"].exists)
        attach(app, "\(tag)basics-kicker-question")
        mine.tap()

        let verdict = app.descendants(matching: .any)["basics.verdict"]
        XCTAssertTrue(verdict.waitForExistence(timeout: 5))
        XCTAssertTrue(verdict.label.contains(ko ? "맞았어요" : "That's right"), verdict.label)
        let element = comparison(app)
        for _ in 0..<8 where !element.exists { app.swipeUp() }
        XCTAssertTrue(element.exists)
        assertLabel(app, 0, contains: ko ? "J 원 페어" : "Pair of Js")
        assertLabel(app, 1, contains: ko ? "J 원 페어" : "Pair of Js")
        assertCardsFit(app)
        show(app, app.descendants(matching: .any)["best-five-row-0"])
        attach(app, "\(tag)basics-kicker-rows")
        let why = app.staticTexts["best-five-why"]
        XCTAssertEqual(why.label, ko ? "둘 다 J 원 페어예요. 키커가 승부를 갈랐어요. 내 A, 상대 Q라서 내 쪽이 이겨요."
                                     : "Both have a pair of Js. The kicker decides it: your A beats the opponent's Q.")
        let duel = app.descendants(matching: .any)["basics.kicker-duel"]
        show(app, duel)
        XCTAssertTrue(app.staticTexts[ko ? "J 페어는 같아요" : "The pair of Js is the same"].exists)
        let chip = app.buttons["basics.kicker-glossary"]
        for _ in 0..<6 where !chip.isHittable { app.swipeUp(velocity: .slow) }
        XCTAssertTrue(chip.isHittable)
        XCTAssertTrue(chip.label.contains(ko ? "키커" : "Kicker"), chip.label)
        attach(app, "\(tag)basics-kicker-duel")
        reach(app.buttons["basics.finish"], app: app)
    }

    /// Answers the same-pair page at the default text size and, without swiping, finds
    /// the whole duel between the header and the answer sheet.
    private func kickerDuelInView(_ language: String) {
        let ko = language == "ko"
        let app = XCUIApplication()
        app.launchArguments = arguments(language, ax: false)
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_DEMO_BASICS": "kicker"]
        app.launch()
        let mine = app.buttons["basics.kicker.choice.mine"]
        XCTAssertTrue(mine.waitForExistence(timeout: 15))
        XCTAssertTrue(mine.isHittable)
        mine.tap()

        let verdict = app.descendants(matching: .any)["basics.verdict"]
        XCTAssertTrue(verdict.waitForExistence(timeout: 5))
        let duel = app.descendants(matching: .any)["basics.kicker-duel"]
        XCTAssertTrue(duel.waitForExistence(timeout: 5))
        let chip = app.buttons["basics.kicker-glossary"]
        let counter = app.staticTexts[ko ? "3쪽 중 3쪽" : "Page 3 of 3"]
        XCTAssertTrue(counter.exists)
        // Let the scroll settle; no gesture is made.
        let settled = NSPredicate { _, _ in duel.frame.maxY <= verdict.frame.minY }
        _ = XCTWaiter.wait(for: [expectation(for: settled, evaluatedWith: nil)], timeout: 3)
        XCTAssertLessThanOrEqual(duel.frame.maxY, verdict.frame.minY,
                                 "Duel \(duel.frame) runs under the answer sheet (verdict \(verdict.frame))")
        XCTAssertGreaterThanOrEqual(duel.frame.minY, counter.frame.maxY,
                                    "Duel \(duel.frame) starts under the header (\(counter.frame))")
        XCTAssertTrue(chip.isHittable)
        attach(app, "\(language)-large-basics-kicker-duel-on-answer")
    }

    // MARK: Helpers

    private func arguments(_ language: String, ax: Bool) -> [String] {
        var arguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "ko" ? "ko_KR" : "en_US",
                         "-glassTable.language", language == "ko" ? "korean" : "english"]
        if ax { arguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        return arguments
    }

    private func launchLesson(_ language: String, ax: Bool, spot: String, store: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments(language, ax: ax)
        app.launchEnvironment = ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0", "GT_DEMO_SEED": "1",
                                 "GT_DEMO_NODE": "u1-showdown", "GT_DEMO_SHOWDOWN_SPOT": spot]
        app.launch()
        return app
    }

    /// "I win": the showdown choices are labelled, not identified.
    private func choice(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label IN %@", ["내가 이김", "I win"])).firstMatch
    }

    private func answer(_ app: XCUIApplication) {
        let button = choice(app)
        reach(button, app: app)
        button.tap()
    }

    private func comparison(_ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["best-five-comparison"]
    }

    /// A row's title, hand name and count line read as one element.
    private func assertLabel(_ app: XCUIApplication, _ index: Int, contains text: String) {
        let label = app.descendants(matching: .any).matching(identifier: "best-five-label-\(index)").firstMatch
        XCTAssertTrue(label.waitForExistence(timeout: 5))
        XCTAssertTrue(label.label.contains(text), label.label)
    }

    /// Card faces never shrink, so both seven-card rows must sit inside the screen.
    private func assertCardsFit(_ app: XCUIApplication) {
        let screen = app.windows.firstMatch.frame
        for index in 0..<2 {
            let row = app.descendants(matching: .any)["best-five-cards-\(index)"]
            XCTAssertTrue(row.waitForExistence(timeout: 5))
            XCTAssertGreaterThanOrEqual(row.frame.minX, screen.minX, "Row \(index) starts off screen: \(row.frame)")
            XCTAssertLessThanOrEqual(row.frame.maxX, screen.maxX, "Row \(index) runs off screen: \(row.frame)")
            XCTAssertGreaterThan(row.frame.width, 280, "Seven cards at their fixed size: \(row.frame)")
        }
    }

    /// Scrolls until the element sits in the upper part of the screen, clear of any
    /// bottom panel.
    private func show(_ app: XCUIApplication, _ element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        let screen = app.windows.firstMatch.frame
        for _ in 0..<12 where element.frame.minY > screen.minY + screen.height * 0.45 {
            app.swipeUp(velocity: .slow)
        }
        for _ in 0..<6 where element.frame.minY < screen.minY + 60 {
            app.swipeDown(velocity: .slow)
        }
    }

    private func reach(_ element: XCUIElement, app: XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout: 15))
        for _ in 0..<16 where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.isHittable, "Unreachable \(element.identifier): \(element.frame)")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
