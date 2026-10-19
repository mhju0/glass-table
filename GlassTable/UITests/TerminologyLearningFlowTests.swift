import XCTest

final class TerminologyLearningFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testEnglishComparisonKeepsBothSeatIdentitiesAfterRestore() { comparison("en", ax: false) }
    func testKoreanAXComparisonKeepsBothSeatIdentitiesAfterRestore() { comparison("ko", ax: true) }

    func testCountQuestionNamesTheSameSeatAsTheDiagram() {
        let store = UUID().uuidString
        let app = launch("en", node: "u1-position", ax: false, store: store)
        let seat = app.descendants(matching: .any)["position-seat-CO"].firstMatch
        XCTAssertTrue(seat.waitForExistence(timeout: 15))
        XCTAssertTrue(seat.label.contains("CO · Before dealer"), seat.label)
        let prompt = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Your seat: CO · Before dealer")).firstMatch
        XCTAssertTrue(prompt.exists)
        XCTAssertTrue(prompt.label.contains("before the flop"), prompt.label)
        XCTAssertEqual(app.staticTexts["position-street"].label, "Before flop")
        XCTAssertFalse(app.staticTexts["position-action-order"].exists, "The question must not show its action order")
        let answer = app.buttons["3"]
        reach(answer, in: app)
        answer.tap()
        XCTAssertTrue(completion(in: app).waitForExistence(timeout: 15))
        XCTAssertTrue(seat.exists)
        XCTAssertTrue(app.staticTexts["position-action-order"].exists)
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0", "GT_TEST_FIRST_PLACEMENT": "0",
                                 "GT_DEMO_LEVEL": "playRegularly"]
        app.launch()
        let resume = app.buttons["learn-continue"]
        reach(resume, in: app)
        resume.tap()
        XCTAssertTrue(completion(in: app).waitForExistence(timeout: 15))
        XCTAssertEqual(app.staticTexts["position-street"].label, "Before flop")
        attach(app, "position-count-term-and-meaning")
    }

    func testKoreanAXSharpCountsOnlyMarkedPlayersWithTheirSeatCodes() {
        let store = UUID().uuidString
        let app = launch("ko", node: "u1-position.3", ax: true, store: store)
        let me = app.descendants(matching: .any)["position-seat-BTN"].firstMatch
        XCTAssertTrue(me.waitForExistence(timeout: 15))
        XCTAssertTrue(me.label.contains("나 · BTN · 딜러"), me.label)
        XCTAssertEqual(app.staticTexts["position-street"].label, "플랍 이후")
        for code in ["LJ", "CO"] {
            let seat = app.descendants(matching: .any)["position-seat-\(code)"].firstMatch
            XCTAssertTrue(seat.label.contains("참여 · \(code)"), seat.label)
        }
        XCTAssertFalse(app.staticTexts["position-action-order"].exists)
        XCTAssertFalse(app.buttons["position-terms-toggle"].exists)
        let enter = app.buttons["답 입력"]
        reach(enter, in: app)
        enter.tap()
        let zero = app.buttons["숫자 0"]
        reach(zero, in: app)
        zero.tap()
        let done = app.buttons["입력 완료"]
        reach(done, in: app)
        done.tap()
        let check = app.buttons["확인"]
        reach(check, in: app)
        check.tap()
        XCTAssertTrue(completion(in: app).waitForExistence(timeout: 15))
        XCTAssertTrue(me.exists)
        XCTAssertFalse(app.staticTexts["position-action-order"].exists, "A partial table never claims all eight remain")
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0", "GT_TEST_FIRST_PLACEMENT": "0",
                                 "GT_DEMO_LEVEL": "playRegularly"]
        app.launch()
        let resume = app.buttons["learn-continue"]
        reach(resume, in: app)
        resume.tap()
        XCTAssertTrue(completion(in: app).waitForExistence(timeout: 15))
        XCTAssertEqual(app.staticTexts["position-street"].label, "플랍 이후")
        attach(app, "position-sharp-AX-seat-identities")
    }

    private func comparison(_ language: String, ax: Bool) {
        let ko = language == "ko"
        let store = UUID().uuidString
        let app = launch(language, node: "u1-position.2", ax: ax, store: store)
        let first = "A · BB · " + (ko ? "큰 블라인드" : "Big blind")
        let second = "B · CO · " + (ko ? "딜러 앞 자리" : "Before dealer")
        let a = app.buttons["position-choice-0"], b = app.buttons["position-choice-1"]
        XCTAssertTrue(a.waitForExistence(timeout: 15))
        XCTAssertEqual(a.label, first)
        XCTAssertEqual(b.label, second)
        let promptPrefix = ko ? "플랍 이후, A와 B 중" : "After the flop, which seat acts later"
        let prompt = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", promptPrefix)).firstMatch
        XCTAssertTrue(prompt.exists, "The graded comparison must explicitly state its street")
        XCTAssertEqual(app.staticTexts["position-street"].label, ko ? "플랍 이후" : "After flop")
        for (code, identity) in [("BB", first), ("CO", second)] {
            let seat = app.descendants(matching: .any)["position-seat-\(code)"].firstMatch
            XCTAssertTrue(seat.exists)
            XCTAssertEqual(seat.label, identity)
        }
        XCTAssertFalse(app.staticTexts["position-action-order"].exists)
        XCTAssertFalse(app.buttons["position-terms-toggle"].exists)
        reach(a, in: app)
        a.tap() // Original index 0 remains A/BB, which loses to B/CO after the flop.
        XCTAssertTrue(completion(in: app).waitForExistence(timeout: 15))
        let verdict = app.descendants(matching: .any).matching(NSPredicate(
            format: "label CONTAINS %@ AND label CONTAINS %@ AND label CONTAINS %@",
            ko ? "선택한 답:" : "Your answer:", first, second)).firstMatch
        XCTAssertTrue(verdict.exists, "The reveal must keep the original A/B answer mapping")
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0", "GT_TEST_FIRST_PLACEMENT": "0",
                                 "GT_DEMO_LEVEL": "playRegularly"]
        app.launch()
        let resume = app.buttons["learn-continue"]
        reach(resume, in: app)
        resume.tap()
        XCTAssertTrue(completion(in: app).waitForExistence(timeout: 15))
        XCTAssertTrue(verdict.exists)
        XCTAssertTrue(prompt.exists, "The restored comparison must state the same postflop question")
        XCTAssertEqual(app.staticTexts["position-street"].label, ko ? "플랍 이후" : "After flop")
        XCTAssertEqual(app.descendants(matching: .any)["position-seat-BB"].firstMatch.label, first)
        XCTAssertEqual(app.descendants(matching: .any)["position-seat-CO"].firstMatch.label, second)
        attach(app, "\(language)-\(ax ? "AX5" : "large")-restored-position-identities")
    }

    private func launch(_ language: String, node: String, ax: Bool, store: String = UUID().uuidString) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "ko" ? "ko_KR" : "en_US",
                               "-glassTable.language", language == "ko" ? "korean" : "english"]
        if ax { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launchEnvironment = ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0", "GT_TEST_FIRST_PLACEMENT": "0",
                                 "GT_DEMO_NODE": node, "GT_DEMO_LEVEL": "playRegularly"]
        app.launch()
        return app
    }

    private func completion(in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'drill-completion-'")).firstMatch
    }
    private func reach(_ element: XCUIElement, in app: XCUIApplication) {
        let drillScroll = app.scrollViews["drill-accessibility-scroll"]
        let fallbackScroll = app.scrollViews.firstMatch
        XCTAssertTrue(fallbackScroll.waitForExistence(timeout: 15))

        func safeViewport() -> CGRect {
            let window = app.frame
            let visible = drillScroll.exists ? drillScroll.frame.intersection(window) : window
            let close = app.buttons["xmark"].firstMatch
            let top = max(visible.minY + 12, close.exists ? close.frame.maxY + 12 : window.minY + 100)
            let bottom = min(visible.maxY - 40, window.maxY - 40)
            return CGRect(x: visible.minX + 8, y: top,
                          width: visible.width - 16, height: max(0, bottom - top))
        }

        for _ in 0..<20 {
            let viewport = safeViewport()
            if element.exists {
                let frame = element.frame
                let midpoint = CGPoint(x: frame.midX, y: frame.midY)
                if frame.width > 0, frame.height > 0, viewport.contains(midpoint), element.isHittable { return }
                let scroll = drillScroll.exists ? drillScroll : fallbackScroll
                if frame.height > 0, frame.midY < viewport.minY { scroll.swipeDown() }
                else { scroll.swipeUp() }
            } else {
                // The inline keypad is lazy: scrolling creates its offscreen buttons.
                (drillScroll.exists ? drillScroll : fallbackScroll).swipeUp()
            }
        }
        XCTAssertTrue(element.exists, "Unreachable lazy control: \(element.identifier)")
        let frame = element.frame
        XCTAssertTrue(safeViewport().contains(CGPoint(x: frame.midX, y: frame.midY)),
                      "Control midpoint outside safe viewport: \(frame), \(safeViewport())")
        XCTAssertTrue(element.isHittable, element.identifier)
    }
    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
