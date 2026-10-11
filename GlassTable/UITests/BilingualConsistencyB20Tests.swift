// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest
import GlassTableDrills

final class BilingualConsistencyB20Tests: XCTestCase {
    private struct Fixture {
        let name: String
        let environment: [String: String]
        let ready: String
        var rootHeading: [String]? = nil
        var pairedHeadingID: String? = nil
        var primaryActionID: String? = nil
    }

    override func setUpWithError() throws { continueAfterFailure = false }

    func testNormalLightCaptureMatrixAndPairedRootHeadings() { captureMatrix(appearance: "light", ax: false) }
    func testNormalDarkCaptureMatrixAndPairedRootHeadings() { captureMatrix(appearance: "dark", ax: false) }
    func testAX5LightCaptureMatrix() { captureMatrix(appearance: "light", ax: true) }
    func testAX5DarkCaptureMatrix() { captureMatrix(appearance: "dark", ax: true) }
    func testTeachPairSupplementaryCopyAllModes() {
        for ax in [false, true] {
            for appearance in ["light", "dark"] {
                captureMatrix(appearance: appearance, ax: ax, fixtureName: "opening-pair")
            }
        }
    }
    func testExplanationAutomaticallyVisibleAllModes() {
        for ax in [false, true] {
            for appearance in ["light", "dark"] {
                var reasonHeights: [CGFloat] = []
                for code in ["en", "ko"] {
                    reasonHeights.append(explanation(code: code, appearance: appearance, ax: ax, response: "show-me"))
                }
                if !ax {
                    print("B20_NORMAL_PAIR opening-show-me \(appearance) firstLesson.reason EN=\(reasonHeights[0]) KO=\(reasonHeights[1])")
                    XCTAssertEqual(reasonHeights[0], reasonHeights[1], accuracy: 1,
                                   "The same native reason font must preserve the normal paired line count")
                }
            }
            explanation(code: "en", appearance: "light", ax: ax, response: "correct")
            explanation(code: "en", appearance: "light", ax: ax, response: "wrong")
        }
    }

    func testEnglishLightAX5BottomActionsAndHelpReturn() { interactions(code: "en", appearance: "light") }
    func testKoreanLightAX5BottomActionsAndHelpReturn() { interactions(code: "ko", appearance: "light") }
    func testEnglishDarkAX5BottomActionsAndHelpReturn() { interactions(code: "en", appearance: "dark") }
    func testKoreanDarkAX5BottomActionsAndHelpReturn() { interactions(code: "ko", appearance: "dark") }
    func testEnglishLightAX5FreeHelpReturn() { freeHelp(code: "en", appearance: "light") }

    func testOpeningB22AllModes() {
        for ax in [false, true] {
            for appearance in ["light", "dark"] {
                for name in ["opening-welcome", "opening-pair", "opening-question", "opening-transfer", "opening-show-me", "opening-third", "settings", "learn"] {
                    captureMatrix(appearance: appearance, ax: ax, fixtureName: name)
                }
            }
        }
    }

    func testBrandLightAppearanceTrialB22() {
        let app = launch(code: "en", appearance: "light", ax: false,
                         environment: ["GT_TEST_FIRST_LESSON": "1"])
        XCTAssertTrue(app.staticTexts["firstLesson.welcome"].waitForExistence(timeout: 15))
        capture(app, "b22-trial-brand-en-light-normal")
        tap(app.buttons["firstLesson.start"], app: app)
        XCTAssertTrue(app.staticTexts["firstLesson.teachPair.heading"].waitForExistence(timeout: 5))
        capture(app, "b22-trial-start-guide-en-light-normal")
        app.terminate()
    }

    func testBrandAppearanceTransitionB22AllModes() {
        for ax in [false, true] {
            for appearance in ["light", "dark"] {
                for code in ["en", "ko"] {
                    let app = launch(code: code, appearance: appearance, ax: ax,
                                     environment: ["GT_TEST_FIRST_LESSON": "1"])
                    XCTAssertTrue(app.staticTexts["firstLesson.welcome"].waitForExistence(timeout: 15))
                    capture(app, "b22-final-brand-\(code)-\(appearance)-\(ax ? "AX5" : "normal")")
                    tap(app.buttons["firstLesson.start"], app: app)
                    XCTAssertTrue(app.staticTexts["firstLesson.teachPair.heading"].waitForExistence(timeout: 5))
                    XCTAssertFalse(app.staticTexts["firstLesson.welcome"].exists)
                    capture(app, "b22-final-start-guide-\(code)-\(appearance)-\(ax ? "AX5" : "normal")")
                    app.terminate()
                }
            }
        }
    }

    func testLegacyWelcomeB22RespectsSelectedLightAppearance() {
        for code in ["en", "ko"] {
            let app = launch(code: code, appearance: "light", ax: false,
                             environment: ["GT_TEST_FIRST_LESSON": "1", "GT_TEST_OPENING_LEGACY_STEP": "welcome"])
            XCTAssertTrue(app.staticTexts["firstLesson.teachPair.heading"].waitForExistence(timeout: 15))
            XCTAssertFalse(app.staticTexts["firstLesson.welcome"].exists)
            capture(app, "b22-final-legacy-welcome-guide-\(code)-light-normal")
            app.terminate()
        }
    }

    func testRemainingComparisonsB22AllModes() {
        for ax in [false, true] {
            for appearance in ["light", "dark"] {
                var heights: [String: [CGFloat]] = [:]
                for code in ["en", "ko"] {
                    let app = launch(code: code, appearance: appearance, ax: ax,
                                     environment: ["GT_TEST_FIRST_LESSON": "1"])
                    tap(app.buttons["firstLesson.start"], app: app)
                    tap(app.buttons["firstLesson.next"], app: app)
                    for index in 0..<5 {
                        XCTAssertTrue(app.staticTexts["firstLesson.question"].waitForExistence(timeout: 5))
                        do {
                            if !ax {
                                for id in ["firstLesson.heading", "firstLesson.rule", "firstLesson.question"] {
                                    let text = app.staticTexts[id]
                                    XCTAssertTrue(text.exists)
                                    XCTAssertFalse(text.label.contains("…"))
                                    // Body text wraps naturally, so only headings keep paired heights.
                                    if id == "firstLesson.heading" {
                                        heights["\(index)-\(id)", default: []].append(text.frame.height)
                                    }
                                }
                            }
                            capture(app, "b22-final-comparison-\(index + 1)-\(code)-\(appearance)-\(ax ? "AX5" : "normal")")
                        }
                        tap(app.buttons["firstLesson.help"], app: app)
                        XCTAssertTrue(app.descendants(matching: .any)["firstLesson.verdict"].waitForExistence(timeout: 5))
                        tap(app.buttons["firstLesson.next"], app: app)
                    }
                    XCTAssertTrue(app.staticTexts[code == "ko" ? "내 차례의 행동" : "Actions on your turn"].exists)
                    app.terminate()
                }
                for (id, values) in heights {
                    XCTAssertEqual(values.count, 2)
                    if values.count == 2 {
                        print("B22_FINAL_PAIR \(appearance) \(id) EN=\(values[0]) KO=\(values[1])")
                        XCTAssertEqual(values[0], values[1], accuracy: 1)
                    }
                }
            }
        }
    }

    private var fixtures: [Fixture] {
        [
            Fixture(name: "opening-welcome", environment: ["GT_DEMO_FIRST_LESSON": "welcome"], ready: "firstLesson.start", pairedHeadingID: "firstLesson.welcome", primaryActionID: "firstLesson.start"),
            Fixture(name: "opening-pair", environment: ["GT_DEMO_FIRST_LESSON": "teach-pair"], ready: "firstLesson.teachPair.heading", pairedHeadingID: "firstLesson.teachPair.heading", primaryActionID: "firstLesson.next"),
            Fixture(name: "opening-question", environment: ["GT_DEMO_FIRST_LESSON": "example"], ready: "firstLesson.question", pairedHeadingID: "firstLesson.heading", primaryActionID: "firstLesson.help"),
            Fixture(name: "opening-transfer", environment: ["GT_DEMO_FIRST_LESSON": "transfer"], ready: "firstLesson.question", pairedHeadingID: "firstLesson.heading", primaryActionID: "firstLesson.help"),
            Fixture(name: "opening-show-me", environment: ["GT_DEMO_FIRST_LESSON": "example-help"], ready: "firstLesson.verdict", primaryActionID: "firstLesson.next"),
            Fixture(name: "opening-third", environment: ["GT_DEMO_FIRST_LESSON": "comparison-2"], ready: "firstLesson.question", pairedHeadingID: "firstLesson.heading", primaryActionID: "firstLesson.help"),
            Fixture(name: "opening-fourth", environment: ["GT_DEMO_FIRST_LESSON": "comparison-3"], ready: "firstLesson.question", pairedHeadingID: "firstLesson.heading", primaryActionID: "firstLesson.help"),
            Fixture(name: "opening-fifth", environment: ["GT_DEMO_FIRST_LESSON": "comparison-4"], ready: "firstLesson.question", pairedHeadingID: "firstLesson.heading", primaryActionID: "firstLesson.help"),
            Fixture(name: "learn", environment: ["GT_DEMO_TAB": "learn"], ready: "learn-path", rootHeading: ["Learn", "배우기"]),
            Fixture(name: "play", environment: ["GT_DEMO_TAB": "play"], ready: "play-free", rootHeading: ["Play", "플레이"]),
            Fixture(name: "progress", environment: ["GT_DEMO_TAB": "records"], ready: "records-details", rootHeading: ["Progress", "학습 기록"]),
            Fixture(name: "settings", environment: ["GT_DEMO_SETTINGS": "1"], ready: "settings-language", rootHeading: ["Settings", "설정"]),
            Fixture(name: "showdown", environment: ["GT_DEMO_NODE": "u1-showdown"], ready: "drill-question-"),
            Fixture(name: "pot", environment: ["GT_DEMO_NODE": "u1-potMath", "GT_DEMO_POT_STATE": "question", "GT_DEMO_POT_PLAYERS": "4:4"], ready: "pot-table-replay"),
            Fixture(name: "pot-feedback", environment: ["GT_DEMO_NODE": "u1-potMath", "GT_DEMO_POT_STATE": "reveal", "GT_DEMO_POT_PLAYERS": "4:4"], ready: "drill-completion-"),
            Fixture(name: "position", environment: ["GT_DEMO_NODE": "u1-position"], ready: "drill-question-"),
            Fixture(name: "rfi", environment: ["GT_DEMO_NODE": "u3-rfi"], ready: "drill-question-"),
            Fixture(name: "defend", environment: ["GT_DEMO_NODE": "u8-defend"], ready: "drill-question-"),
            Fixture(name: "outs", environment: ["GT_DEMO_NODE": "u2-outs"], ready: "drill-question-"),
            Fixture(name: "graded-chart", environment: ["GT_DEMO_TABLE": "tag", "GT_DEMO_TABLE_STEP": "1", "GT_DEMO_TABLE_CHART": "1"], ready: "table-chart-reading-guide"),
            Fixture(name: "graded-feedback", environment: ["GT_DEMO_TABLE": "tag", "GT_DEMO_TABLE_STEP": "2"], ready: "table-verdict"),
            Fixture(name: "free-play", environment: ["GT_DEMO_TAB": "play", "GT_DEMO_PRACTICE": "1"], ready: "free-table-help"),
            Fixture(name: "free-help", environment: ["GT_DEMO_TAB": "play", "GT_DEMO_PRACTICE": "1", "GT_DEMO_FREE_PHASE": "raise-open", "GT_DEMO_FREE_BACK": "math"], ready: "free-table-back-close")
        ]
    }

    private func launch(code: String, appearance: String, ax: Bool, environment: [String: String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(code))", "-AppleLocale", code == "ko" ? "ko_KR" : "en_US",
                               "-glassTable.language", code == "ko" ? "korean" : "english", "-appAppearance", appearance,
                               "-UIPreferredContentSizeCategoryName", ax ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_DEMO_LEVEL": "newToPoker", "GT_DEMO_LANGUAGE": code, "GT_DEMO_SEED": "1"]
        app.launchEnvironment.merge(environment) { _, new in new }
        if environment["GT_DEMO_FIRST_LESSON"] != nil || environment["GT_TEST_FIRST_LESSON"] == "1" {
            app.launchEnvironment.removeValue(forKey: "GT_DEMO_SEED")
        }
        app.launch()
        XCTAssertEqual(app.windows.firstMatch.frame.width, 375, accuracy: 1,
                       "Run this acceptance suite on a 375-point compact phone, such as iPhone 12 mini.")
        return app
    }

    private func captureMatrix(appearance: String, ax: Bool, fixtureName: String? = nil) {
        for fixture in fixtures where fixtureName == nil || fixture.name == fixtureName {
            var headingHeights: [CGFloat] = []
            var pairedTextHeights: [String: [CGFloat]] = [:]
            for (index, code) in ["en", "ko"].enumerated() {
                let app = launch(code: code, appearance: appearance, ax: ax, environment: fixture.environment)
                let ready = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", fixture.ready)).firstMatch
                XCTAssertTrue(ready.waitForExistence(timeout: 20), "\(fixture.name) must show its intended state")
                if let titles = fixture.rootHeading {
                    let heading = app.staticTexts.matching(NSPredicate(format: "label == %@", titles[index])).firstMatch
                    XCTAssertTrue(heading.exists, "\(fixture.name) has its localized heading")
                    XCTAssertGreaterThan(heading.frame.height, 0)
                    XCTAssertGreaterThanOrEqual(heading.frame.minX, app.frame.minX - 1)
                    XCTAssertLessThanOrEqual(heading.frame.maxX, app.frame.maxX + 1)
                    headingHeights.append(heading.frame.height)
                    XCTAssertTrue(app.tabBars.firstMatch.exists, "Root destinations retain the tab bar")
                    XCTAssertFalse(heading.label.contains("…"))
                } else if let identifier = fixture.pairedHeadingID {
                    let heading = app.staticTexts[identifier]
                    XCTAssertTrue(heading.waitForExistence(timeout: 5))
                    XCTAssertGreaterThan(heading.frame.height, 0)
                    XCTAssertFalse(heading.label.contains("…"))
                    headingHeights.append(heading.frame.height)
                }
                if !ax, let identifier = fixture.primaryActionID {
                    let action = app.buttons[identifier]
                    XCTAssertTrue(action.exists)
                    XCTAssertGreaterThanOrEqual(action.frame.height, 44)
                    XCTAssertGreaterThanOrEqual(action.frame.width, 44)
                    XCTAssertFalse(action.label.contains("…"))
                    print("B20_NORMAL_ACTION \(fixture.name) \(code) \(appearance) \(identifier) frame=\(action.frame)")
                }
                if !ax {
                    for identifier in pairedBodyIDs(fixture.name) {
                        let text = app.staticTexts[identifier]
                        XCTAssertTrue(text.waitForExistence(timeout: 5), "Native paired text: \(identifier)")
                        XCTAssertGreaterThan(text.frame.height, 0)
                        XCTAssertFalse(text.label.contains("…"))
                        pairedTextHeights[identifier, default: []].append(text.frame.height)
                    }
                }
                capture(app, "b20-\(fixture.name)-\(code)-\(appearance)-\(ax ? "AX5" : "normal")")
                if fixtureName == "opening-pair", ax {
                    let next = app.buttons["firstLesson.next"]
                    tap(next, app: app)
                    XCTAssertTrue(app.staticTexts["firstLesson.question"].waitForExistence(timeout: 5),
                                  "The AX5 teaching page's real Next action opens the question")
                    print("B20_AX_FLOW teach-pair-next \(code) \(appearance) passed")
                }
                app.terminate()
            }
            if !ax, headingHeights.count == 2 {
                print("B20_NORMAL_PAIR \(fixture.name) \(appearance) heading EN=\(headingHeights[0]) KO=\(headingHeights[1])")
                XCTAssertEqual(headingHeights[0], headingHeights[1], accuracy: 1,
                               "\(fixture.name): same typography must give paired normal headings the same native line height")
            }
            for (identifier, heights) in pairedTextHeights {
                XCTAssertEqual(heights.count, 2)
                if heights.count == 2 {
                    print("B20_NORMAL_PAIR \(fixture.name) \(appearance) \(identifier) EN=\(heights[0]) KO=\(heights[1])")
                }
            }
        }
    }

    private func pairedBodyIDs(_ fixtureName: String) -> [String] {
        switch fixtureName {
        case "opening-pair": ["firstLesson.teachPair.body", "firstLesson.teachPair.letters"]
        case "opening-question", "opening-transfer", "opening-third", "opening-fourth", "opening-fifth": ["firstLesson.question", "firstLesson.rule"]
        default: []
        }
    }

    private func interactions(code: String, appearance: String) {
        openingShowMe(code: code, appearance: appearance)
        workedExample(code: code, appearance: appearance)
        gradedChart(code: code, appearance: appearance)
        freeHelp(code: code, appearance: appearance)
    }

    private func openingShowMe(code: String, appearance: String) {
        let app = launch(code: code, appearance: appearance, ax: true, environment: ["GT_TEST_FIRST_LESSON": "1"])
        tap(app.buttons["firstLesson.start"], app: app)
        tap(app.buttons["firstLesson.next"], app: app)
        for _ in 0..<2 {
            XCTAssertTrue(app.staticTexts["firstLesson.question"].waitForExistence(timeout: 5))
            tap(app.buttons["firstLesson.help"], app: app)
            XCTAssertTrue(app.descendants(matching: .any)["firstLesson.verdict"].waitForExistence(timeout: 5))
            let next = app.buttons["firstLesson.next"]
            reveal(next, app: app)
            capture(app, "b20-opening-show-me-bottom-\(code)-\(appearance)-AX5")
            next.tap()
        }
        XCTAssertTrue(app.staticTexts["firstLesson.question"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["firstLesson.finish"].exists)
        XCTAssertFalse(app.buttons["firstLesson.preference"].exists)
        tap(app.buttons["firstLesson.skip"], app: app)
        XCTAssertTrue(app.buttons["learn-path"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.tabBars.firstMatch.exists)
        print("B20_AX_FLOW opening-show-me-checkpoint \(code) \(appearance) passed")
        app.terminate()
    }

    @discardableResult
    private func explanation(code: String, appearance: String, ax: Bool, response: String) -> CGFloat {
        let app = launch(code: code, appearance: appearance, ax: ax, environment: ["GT_TEST_FIRST_LESSON": "1"])
        tap(app.buttons["firstLesson.start"], app: app)
        tap(app.buttons["firstLesson.next"], app: app)
        let winner = FirstLesson.requiredComparisons(seed: 0)[0].spot.winner
        let choice = response == "correct" ? winner : 1 - winner
        tap(app.buttons[response == "show-me" ? "firstLesson.help" : "firstLesson.choice.\(choice)"], app: app)
        let reason = app.staticTexts["firstLesson.reason"]
        XCTAssertTrue(reason.waitForExistence(timeout: 10))
        let visible = expectation(for: NSPredicate(format: "hittable == true"), evaluatedWith: reason)
        wait(for: [visible], timeout: 10)
        XCTAssertTrue(app.descendants(matching: .any)["firstLesson.verdict"].exists)
        XCTAssertTrue(reason.isHittable, "Explanation must appear automatically after \(response), without a manual scroll")
        let viewport = app.scrollViews.firstMatch.frame.intersection(app.windows.firstMatch.frame.insetBy(dx: 0, dy: 20))
        XCTAssertGreaterThanOrEqual(reason.frame.minY, viewport.minY - 1)
        XCTAssertLessThanOrEqual(reason.frame.maxY, viewport.maxY + 1)
        capture(app, "b20-opening-\(response)-\(code)-\(appearance)-\(ax ? "AX5" : "normal")")
        print("B20_EXPLANATION_VISIBLE \(response) \(code) \(appearance) \(ax ? "AX5" : "normal") frame=\(reason.frame) viewport=\(viewport)")
        let height = reason.frame.height
        app.terminate()
        return height
    }

    private func workedExample(code: String, appearance: String) {
        let app = launch(code: code, appearance: appearance, ax: true,
                         environment: ["GT_DEMO_NODE": "u1-position", "GT_DEMO_EXPLAIN": "1"])
        let example = app.buttons["explain-example"]
        tap(example, app: app)
        tap(app.buttons["walkthrough-next"], app: app)
        tap(app.buttons["walkthrough-previous"], app: app)
        for _ in 0..<40 {
            let next = app.buttons["walkthrough-next"]
            XCTAssertTrue(next.waitForExistence(timeout: 5))
            if next.label == (code == "ko" ? "예시 마치기" : "Finish example") {
                reveal(next, app: app)
                capture(app, "b20-position-last-\(code)-\(appearance)-AX5")
                next.tap()
                XCTAssertTrue(example.waitForExistence(timeout: 5), "Finishing returns to the same explanation")
                print("B20_AX_FLOW position-example-return \(code) \(appearance) passed")
                app.terminate()
                return
            }
            if !next.isEnabled { tap(app.buttons["walkthrough-reveal"], app: app) }
            tap(next, app: app)
        }
        XCTFail("Position example did not reach its final bottom action")
        app.terminate()
    }

    private func gradedChart(code: String, appearance: String) {
        let app = launch(code: code, appearance: appearance, ax: true, environment: ["GT_DEMO_TABLE": "tag"])
        let fold = app.buttons["table-fold"]
        XCTAssertTrue(fold.waitForExistence(timeout: 15))
        let originalCards = app.descendants(matching: .any)["table-hero-cards"].label
        tap(app.buttons["table-chart"], app: app)
        XCTAssertTrue(app.buttons["table-chart-reading-guide"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["defend-selected-evidence"].exists,
                       "A precommit chart is a reference, not an answer")
        capture(app, "b20-chart-open-\(code)-\(appearance)-AX5")
        tap(app.buttons[code == "ko" ? "닫기" : "Close"], app: app)
        XCTAssertEqual(app.descendants(matching: .any)["table-hero-cards"].label, originalCards)
        XCTAssertFalse(app.descendants(matching: .any)["table-verdict"].exists)
        tap(fold, app: app)
        XCTAssertTrue(app.descendants(matching: .any)["table-verdict"].waitForExistence(timeout: 10))
        let next = app.buttons["table-continue"]
        reveal(next, app: app)
        capture(app, "b20-graded-bottom-\(code)-\(appearance)-AX5")
        next.tap()
        XCTAssertTrue(app.buttons["table-next-hand"].waitForExistence(timeout: 10))
        print("B20_AX_FLOW graded-chart-return-commit-continue \(code) \(appearance) passed")
        app.terminate()
    }

    private func freeHelp(code: String, appearance: String) {
        let app = launch(code: code, appearance: appearance, ax: true,
                         environment: ["GT_DEMO_TAB": "play", "GT_DEMO_PRACTICE": "1", "GT_DEMO_PLAYERS": "2"])
        let fold = app.buttons["free-fold"]
        XCTAssertTrue(fold.waitForExistence(timeout: 15))
        let ready = expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: fold)
        wait(for: [ready], timeout: 20)
        tap(app.buttons["free-raise"], app: app)
        tap(app.buttons["free-raise-cancel"], app: app)
        XCTAssertTrue(fold.waitForExistence(timeout: 5))
        let originalAction = fold.label
        tap(app.buttons["free-table-help"], app: app)
        let close = app.buttons["free-table-back-close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        capture(app, "b20-free-help-open-\(code)-\(appearance)-AX5")
        tap(close, app: app)
        XCTAssertFalse(close.exists)
        XCTAssertEqual(fold.label, originalAction, "Help returns to the uncommitted decision")
        reveal(fold, app: app)
        capture(app, "b20-free-help-return-\(code)-\(appearance)-AX5")
        fold.tap()
        XCTAssertTrue(app.buttons["free-next-hand"].waitForExistence(timeout: 20),
                      "The real bottom action commits the hand decision and reaches the hand result")
        print("B20_AX_FLOW free-help-return-commit \(code) \(appearance) passed")
        app.terminate()
    }

    private func tap(_ target: XCUIElement, app: XCUIApplication) {
        reveal(target, app: app)
        XCTAssertTrue(target.isEnabled)
        target.tap()
    }

    private func reveal(_ target: XCUIElement, app: XCUIApplication) {
        XCTAssertTrue(target.waitForExistence(timeout: 15))
        let match = target.identifier.isEmpty
            ? NSPredicate(format: "label == %@", target.label)
            : NSPredicate(format: "identifier == %@", target.identifier)
        let scroll = app.scrollViews.allElementsBoundByIndex.filter {
            $0.descendants(matching: .any).matching(match).firstMatch.exists
        }.min { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }
        for _ in 0..<30 {
            let window = app.windows.firstMatch.frame
            if scroll == nil, target.isHittable {
                let viewport = window.insetBy(dx: 0, dy: 20)
                if viewport.contains(target.frame) { return }
            }
            var top = window.minY + 60
            let navigation = app.navigationBars.firstMatch
            if navigation.exists {
                if target.isHittable, navigation.frame.contains(target.frame) { return }
                top = max(top, navigation.frame.maxY)
            }
            var bottom = window.maxY - 20
            if let scroll { top = max(top, scroll.frame.minY); bottom = min(bottom, scroll.frame.maxY) }
            let frame = target.frame
            if target.isHittable, frame.minY >= top - 1, frame.maxY <= bottom + 1 {
                XCTAssertGreaterThanOrEqual(frame.minX, window.minX - 1)
                XCTAssertLessThanOrEqual(frame.maxX, window.maxX + 1)
                return
            }
            let startY = max(top + 30, min(bottom - 30, (top + bottom) / 2))
            let delta: CGFloat = frame.minY < top ? 100 : -100
            // First Lesson reserves the leading 28 points for its back gesture.
            let x = scroll.map { $0.frame.minX + min(60, $0.frame.width / 2) } ?? 60
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: startY))
            start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 0, dy: delta)),
                        withVelocity: .slow, thenHoldForDuration: 0.3)
        }
        capture(app, "b20-unreachable-\(target.identifier)")
        XCTFail("Action bounds do not clear the native viewport: \(target.identifier) \(target.frame)")
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name; screenshot.lifetime = .keepAlways; add(screenshot)
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "\(name)-hierarchy"; hierarchy.lifetime = .keepAlways; add(hierarchy)
        // AX labels preserve explicit breaks; their frames supplement screenshots,
        // but do not prove glyph-level Korean word wrapping or body line counts.
        let proseIDs = ["firstLesson.welcome", "firstLesson.welcome.body", "firstLesson.teachPair.heading",
                        "firstLesson.teachPair.body", "firstLesson.teachPair.letters", "firstLesson.heading", "firstLesson.question", "firstLesson.rule",
                        "firstLesson.checkpoint.heading", "firstLesson.checkpoint.body",
                        "firstLesson.preference.heading", "firstLesson.preference.body", "firstLesson.reason", "table-takeaway"]
        // Select prose before native element lookup. Chart glyphs remain in the
        // one hierarchy snapshot and screenshot, without hundreds of remote calls.
        let prose = app.staticTexts.matching(NSPredicate(
            format: "(identifier IN %@ OR identifier BEGINSWITH %@) AND NOT label MATCHES %@",
            proseIDs, "drill-question-", "[2-9TJQKA]{1,2}[so]?"))
        let frames = prose.allElementsBoundByIndex.map { element -> [String: Any] in
            let frame = element.frame
            return ["id": element.identifier, "label": element.label,
                    "x": frame.minX, "y": frame.minY, "width": frame.width, "height": frame.height]
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: frames, options: [.prettyPrinted, .sortedKeys])
            let geometry = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
            geometry.name = "\(name)-text-geometry"; geometry.lifetime = .keepAlways; add(geometry)
        } catch { XCTFail("Cannot record native text geometry: \(error)") }
    }
}
