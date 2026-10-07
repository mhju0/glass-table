// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

final class AccessibilityFlowTests: XCTestCase {
    private let accessibilityXXXL = [
        "-UIPreferredContentSizeCategoryName",
        "UICTContentSizeCategoryAccessibilityXXXL",
    ]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testFreeTableKO2SeatsStayReachableAtAccessibilityXXXL() { verifyFreeTableSeats(code: "ko", players: 2) }
    func testFreeTableKO3SeatsStayReachableAtAccessibilityXXXL() { verifyFreeTableSeats(code: "ko", players: 3) }
    func testFreeTableKO4SeatsStayReachableAtAccessibilityXXXL() { verifyFreeTableSeats(code: "ko", players: 4) }
    func testFreeTableEN2SeatsStayReachableAtAccessibilityXXXL() { verifyFreeTableSeats(code: "en", players: 2) }
    func testFreeTableEN3SeatsStayReachableAtAccessibilityXXXL() { verifyFreeTableSeats(code: "en", players: 3) }
    func testFreeTableEN4SeatsStayReachableAtAccessibilityXXXL() { verifyFreeTableSeats(code: "en", players: 4) }

    private func verifyFreeTableSeats(code: String, players: Int) {
        let setting = code == "ko" ? "korean" : "english"
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(code))", "-glassTable.language", setting]
            + accessibilityXXXL
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_DEMO_TAB": "play",
            "GT_DEMO_PRACTICE": "1", "GT_DEMO_PLAYERS": "\(players)"]
        app.launch()
        let hero = app.otherElements["practice-0"]
        XCTAssertTrue(hero.waitForExistence(timeout: 15))
        if players == 2 {
            XCUIDevice.shared.orientation = .landscapeLeft
            XCTAssertGreaterThan(app.frame.height, app.frame.width, "The free table stays portrait")
            let rotation = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            rotation.name = "free-table-portrait-after-rotation-\(code)"
            rotation.lifetime = .keepAlways
            add(rotation)
            XCUIDevice.shared.orientation = .portrait
        }
        let fold = app.buttons["free-fold"]
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: fold)
        waitForExpectations(timeout: 20)
        let scroll = app.scrollViews.firstMatch
        let names = code == "ko" ? ["두 명", "세 명", "네 명"] : ["Two players", "Three players", "Four players"]
        let title = code == "ko" ? "\(names[players - 2]) · 1번째 핸드" : "\(names[players - 2]) · Hand 1"
        let header = app.staticTexts[title]
        XCTAssertTrue(header.exists)
        let ids = (0..<players).map { "practice-\($0)" }
        XCTAssertFalse(app.otherElements["practice-empty"].exists, "No placeholder for a seat nobody sits in")
        for id in ids {
            let seat = app.otherElements[id]
            var fullyVisible = false
            for _ in 0..<20 {
                let viewport = scroll.frame
                let top = max(viewport.minY, header.frame.maxY)
                let frame = seat.frame
                if frame.minY >= top, frame.maxY <= viewport.maxY {
                    fullyVisible = true
                    break
                }
                let targetCenter = (top + viewport.maxY) / 2
                let delta = min(80, max(-80, frame.midY - targetCenter))
                let startY = (top + viewport.maxY) / 2
                let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: startY / app.frame.height))
                let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: (startY - delta) / app.frame.height))
                start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.5)
            }
            XCTAssertTrue(fullyVisible, "\(code) \(players) \(id): seat=\(seat.frame), viewport=\(scroll.frame)")
            print("Free table AX5 \(code) \(players) \(id): seat=\(seat.frame), viewport=\(scroll.frame), chromeBottom=\(header.frame.maxY)")
            if id == "practice-0" {
                XCTAssertTrue(seat.label.contains(code == "ko" ? "남은 칩" : "chips left"), seat.label)
            } else {
                XCTAssertTrue(seat.label.contains(code == "ko" ? "뒷면 카드 2장" : "2 face-down cards"), seat.label)
            }
            let capture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            capture.name = "free-table-seat-AX5-\(code)-\(players)-\(id)"
            capture.lifetime = .keepAlways
            add(capture)
        }
        XCTAssertTrue(fold.isHittable)
        fold.tap()
        XCTAssertTrue(app.buttons["free-next-hand"].waitForExistence(timeout: 20))
        app.terminate()
    }


    func testFreeTableStatusToneKeepsSeatHeightAtAccessibilityXXXL() {
        for (code, setting) in [("ko", "korean"), ("en", "english")] {
            let app = XCUIApplication()
            app.launchArguments = ["-AppleLanguages", "(\(code))", "-glassTable.language", setting]
                + accessibilityXXXL
            app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_DEMO_TAB": "play",
                "GT_DEMO_PRACTICE": "1", "GT_DEMO_PLAYERS": "2"]
            app.launch()
            let computer = app.otherElements["practice-1"]
            XCTAssertTrue(computer.waitForExistence(timeout: 15))
            let fold = app.buttons["free-fold"]
            expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: fold)
            waitForExpectations(timeout: 20)
            let before = computer.frame.height
            let beforeLabel = computer.label
            fold.tap()
            XCTAssertTrue(app.buttons["free-next-hand"].waitForExistence(timeout: 20))
            let after = computer.frame.height
            print("Seat status stability \(code): before=\(before), after=\(after), labels=\(beforeLabel) → \(computer.label)")
            XCTAssertTrue(computer.label.contains("+"), computer.label)
            XCTAssertEqual(before, after, accuracy: 0.01, "A status/tone change must not move the seat rows")
            app.terminate()
        }
    }

    func testFirstLaunchStartingPointCheckIsReachableInBothLanguagesAtAccessibilityXXXL() {
        for (code, setting, newPlayer, skip) in [("ko", "korean", "처음 배워요", "확인 없이 시작하기"),
                                                  ("en", "english", "I'm new to poker", "Start without the check")] {
            let app = XCUIApplication()
            app.launchArguments = ["-AppleLanguages", "(\(code))", "-glassTable.language", setting]
                + accessibilityXXXL
            app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "1",
                                     "GT_TEST_FIRST_PLACEMENT": "1"]
            app.launch()
            let first = app.buttons[newPlayer]
            XCTAssertTrue(first.waitForExistence(timeout: 15))
            XCTAssertFalse(app.tabBars.firstMatch.exists)
            attachLearnCapture(app, name: "first-launch-starting-point-top-AX5-\(code)")
            XCTAssertTrue(scrollUntilFullyVisible(first, above: app, in: app))
            XCTAssertTrue(first.isHittable)
            let skipButton = app.buttons[skip]
            XCTAssertTrue(scrollUntilFullyVisible(skipButton, above: app, in: app))
            XCTAssertTrue(skipButton.isHittable)
            attachLearnCapture(app, name: "first-launch-starting-point-bottom-AX5-\(code)")
            skipButton.tap()
            XCTAssertTrue(app.buttons["firstLesson.skip"].waitForExistence(timeout: 5))
            app.terminate()
        }
    }

    private func attachLearnCapture(_ app: XCUIApplication, name: String) {
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = name
        capture.lifetime = .keepAlways
        add(capture)
    }

    func testEquityAnswerCanBeSubmittedAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_SEED": "1",
            "GT_DEMO_NODE": "u2-equitySense",
        ])

        XCTAssertTrue(app.staticTexts["쇼다운까지 갔을 때 내가 이길 확률은?"]
            .waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["상대 카드"].exists)

        let submit = app.buttons["확인"]
        XCTAssertTrue(scrollUntilHittable(submit, in: app),
                      "The full equity input and submit action must remain reachable at AX XXXL.")
        submit.tap()

        let next = app.buttons["다음 문제"]
        XCTAssertTrue(scrollUntilHittable(next, in: app),
                      "The equity reveal and its advance action must remain reachable at AX XXXL.")
    }

    func testShowdownWalkthroughAdvancesAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_NODE": "u1-showdown",
            "GT_DEMO_BEAT": "0",
        ])

        XCTAssertTrue(app.descendants(matching: .any)["walkthrough-step-0"]
            .waitForExistence(timeout: 15))

        for step in 1...7 {
            // One step is covered until the learner taps to check it.
            let reveal = app.buttons["walkthrough-reveal"]
            if reveal.exists {
                XCTAssertFalse(app.buttons[step == 7 ? "이해했어요" : "다음"].isEnabled,
                               "The example can't advance before the learner checks the value.")
                XCTAssertTrue(scrollUntilHittable(reveal, in: app),
                              "The covered example value must be reachable at AX XXXL.")
                reveal.tap()
            }
            let title = step == 7 ? "이해했어요" : "다음"
            let advance = app.buttons[title]
            XCTAssertTrue(scrollUntilHittable(advance, in: app),
                          "Walkthrough step \(step) must expose its advance action at AX XXXL.")
            advance.tap()
        }

        XCTAssertTrue(app.staticTexts["함께 풀기"].waitForExistence(timeout: 10),
                      "Completing all seven beats should reach guided practice.")
    }

    func testGuidedHintFloatsWithoutMovingTheQuestionAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_NODE": "u1-showdown",
            "GT_DEMO_STAGE": "together",
        ])

        let title = app.staticTexts["누가 이길까요?"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 15))
        let cue = app.descendants(matching: .any)["contextual-hint-cue"].firstMatch
        XCTAssertTrue(cue.exists, "The method cue is already in the task, above its cards")
        XCTAssertFalse(app.otherElements["guided-hint"].exists)
        let frameBeforeHint = title.frame

        let hint = app.buttons["힌트"]
        XCTAssertTrue(hint.waitForExistence(timeout: 5))
        XCTAssertTrue(hint.isHittable)
        hint.tap()

        XCTAssertTrue(app.staticTexts["풀이 순서"].waitForExistence(timeout: 5))
        let closeHint = app.buttons["힌트 닫기"]
        XCTAssertTrue(closeHint.waitForExistence(timeout: 5))
        XCTAssertTrue(closeHint.isHittable)
        closeHint.tap()

        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.frame.origin.x, frameBeforeHint.origin.x, accuracy: 1)
        XCTAssertEqual(title.frame.origin.y, frameBeforeHint.origin.y, accuracy: 1,
                       "Opening and closing the full help sheet must not move the reserved cue or header")

        let answer = app.buttons["내가 이김"]
        XCTAssertTrue(scrollUntilHittable(answer, in: app),
                      "The answer area must remain reachable after dismissing the hint")
        answer.tap()
        XCTAssertTrue(scrollUntilHittable(app.buttons["다음 문제"], in: app))
    }

    func testTableFoldReachesSummaryAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_TABLE": "tag",
        ])

        let fold = app.buttons["table-fold"]
        XCTAssertTrue(scrollUntilHittable(fold, in: app),
                      "The preflop fold action must remain reachable below the table context at AX XXXL.")
        fold.tap()

        XCTAssertTrue(app.descendants(matching: .any)["table-verdict"].waitForExistence(timeout: 10))
        let next = app.buttons["table-continue"]
        XCTAssertTrue(scrollUntilHittable(next, in: app))
        next.tap()
        XCTAssertTrue(app.staticTexts["이긴 결과와 좋은 선택은 따로 봐요"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS %@", "EV 손실은 0bb예요"
        )).firstMatch.exists)
        let nextHand = app.buttons["다음 핸드"]
        XCTAssertTrue(scrollUntilHittable(nextHand, in: app),
                      "The complete hand summary must remain scrollable at AX XXXL.")
    }

    func testTableGradeVerdictAndContinueStayReachableAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_TABLE": "tag",
            "GT_DEMO_TABLE_STEP": "2",
        ])

        let verdict = app.descendants(matching: .any)["table-verdict"]
        XCTAssertTrue(scrollUntilHittable(verdict, in: app),
                      "The graded verdict must be reachable at AX XXXL.")
        XCTAssertTrue(scrollUntilHittable(app.buttons["계속"], in: app),
                      "Continue must remain reachable below the explanation at AX XXXL.")
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "table-grade-continue-ax5"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testTableHeroCardsCanBeFullyExposedOnScreenAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_TABLE": "tag",
        ])

        let hero = app.otherElements["table-hero-cards"]
        XCTAssertTrue(hero.waitForExistence(timeout: 15))
        // The graded table hides the tab bar, so the screen edge is the only bound.
        XCTAssertFalse(app.tabBars.firstMatch.exists)
        XCTAssertTrue(scrollUntilFullyVisible(hero, above: app, in: app),
                      "Both fixed-size hero cards must fit wholly on screen at AX XXXL.")
        XCTAssertGreaterThanOrEqual(hero.frame.minY, app.frame.minY)
        XCTAssertLessThanOrEqual(hero.frame.maxY, app.frame.maxY)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "table-hero-cards-fully-visible-ax5"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testDefendRevealExposesSelectedEvidenceAndChartRowsAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_NODE": "u8-defend",
            "GT_DEMO_REVEAL": "1",
        ])

        let evidence = app.descendants(matching: .any)["defend-selected-evidence"]
        XCTAssertTrue(evidence.waitForExistence(timeout: 15))
        XCTAssertTrue(scrollUntilHittable(evidence, in: app),
                      "The hand and its chart action must be reachable before the full grid at AX XXXL.")
        // Below "Plays sometimes" the full chart waits behind one tap.
        let more = app.buttons["전체 차트 보기"]
        XCTAssertTrue(scrollUntilHittable(more, in: app))
        more.tap()
        let chartRow = app.descendants(matching: .any).matching(NSPredicate(
            format: "label BEGINSWITH %@ AND label CONTAINS %@", "A 행.", "AKs"
        )).firstMatch
        XCTAssertTrue(chartRow.waitForExistence(timeout: 5),
                      "VoiceOver must receive the chart's hand-by-hand actions, not one generic label.")
    }

    func testEVRevealLeadsWithRangeEvidenceAndLossEquationAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_NODE": "u6-evLoss",
            "GT_DEMO_REVEAL": "1",
        ])

        let summary = app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS %@ AND label CONTAINS %@", "오픈 ·", "콤보"
        )).firstMatch
        XCTAssertTrue(scrollUntilHittable(summary, in: app),
                      "The exact opponent range used for grading must be readable at AX XXXL.")
        let disclaimer = app.staticTexts["리버에서 어떻게 좁혔는지는 아직 안 따져요"]
        XCTAssertTrue(scrollUntilHittable(disclaimer, in: app))
        let gridRow = app.descendants(matching: .any).matching(NSPredicate(
            format: "label BEGINSWITH %@ AND label CONTAINS %@", "A 행.", "AKs"
        )).firstMatch
        XCTAssertTrue(gridRow.waitForExistence(timeout: 5))
        let evidenceAttachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidenceAttachment.name = "ev-range-evidence-ax5"
        evidenceAttachment.lifetime = .keepAlways
        add(evidenceAttachment)
        let equation = app.staticTexts.matching(NSPredicate(
            format: "label BEGINSWITH %@ AND label CONTAINS %@", "최선 EV", "= 손실"
        )).firstMatch
        XCTAssertTrue(scrollUntilHittable(equation, in: app),
                      "The chosen and best EVs must remain readable as a subtraction at AX XXXL.")
        let chosenLabel = app.staticTexts.matching(NSPredicate(
            format: "label BEGINSWITH %@", "내 선택 ·"
        )).firstMatch
        XCTAssertTrue(chosenLabel.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(chosenLabel.frame.width, chosenLabel.frame.height * 1.5,
                             "The chosen-action label must read horizontally, not one syllable per line.")
        let equationAttachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        equationAttachment.name = "ev-loss-equation-ax5"
        equationAttachment.lifetime = .keepAlways
        add(equationAttachment)
    }

    func testCountKeypadCanOpenAndCollapseAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_NODE": "u2-outs",
        ])

        let answer = app.buttons["답 입력"]
        XCTAssertTrue(scrollUntilHittable(answer, in: app))
        answer.tap()
        let zero = app.buttons["숫자 0"]
        XCTAssertTrue(scrollForwardUntilMaterializedAndHittable(zero, in: app))
        zero.tap()
        let done = app.buttons["입력 완료"]
        XCTAssertTrue(scrollForwardUntilMaterializedAndHittable(done, in: app))
        let expandedAttachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        expandedAttachment.name = "count-keypad-expanded-ax5"
        expandedAttachment.lifetime = .keepAlways
        add(expandedAttachment)
        done.tap()

        let hero = app.descendants(matching: .any)["three-region-hero-cards"]
        XCTAssertTrue(scrollBackwardUntilHittable(hero, in: app))
        XCTAssertTrue(app.buttons["0장"].exists)
        let collapsedAttachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        collapsedAttachment.name = "count-entry-collapsed-after-done-ax5"
        collapsedAttachment.lifetime = .keepAlways
        add(collapsedAttachment)
    }

    func testPolicyReferenceCaveatsRemainReachableAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_TABLE": "tag",
            "GT_DEMO_TABLE_POLICY": "1",
        ])

        XCTAssertTrue(app.staticTexts["선별형 전략과 레인지"].waitForExistence(timeout: 15))
        let rangeSummary = app.descendants(matching: .any)["table-policy-range-summary"]
        XCTAssertTrue(rangeSummary.waitForExistence(timeout: 5))
        XCTAssertTrue(rangeSummary.label.contains("내 3벳에 상대가 폴드했다면 폴드 직전의 레인지를 유지해요"))
        let limits = app.staticTexts.matching(NSPredicate(
            format: "label BEGINSWITH %@", "벳은 남은 스택보다"
        )).firstMatch
        XCTAssertTrue(scrollForwardUntilMaterializedAndHittable(limits, in: app))
        let preflop = app.staticTexts.matching(NSPredicate(
            format: "label BEGINSWITH %@", "프리플랍은 이 표와 별개예요"
        )).firstMatch
        XCTAssertTrue(scrollForwardUntilMaterializedAndHittable(preflop, in: app))
        XCTAssertTrue(preflop.label.contains("상대가 폴드하면 폴드 레인지를 따로 추정하지 않아요"))
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "table-policy-caveats-ax5"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testTableSetupPlayerCountStacksAndStaysReachableAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_TEST_FIRST_LESSON": "0",
            "GT_DEMO_TAB": "play",
            "GT_DEMO_PLAY_SETUP": "1",
        ])
        let two = app.buttons["player-count-2"]
        XCTAssertTrue(scrollUntilHittable(two, in: app))
        let three = app.buttons["player-count-3"]
        XCTAssertGreaterThan(three.frame.minY, two.frame.maxY,
                             "At accessibility sizes the counts stack instead of squeezing into three columns.")
        two.tap()
        XCTAssertTrue(two.isSelected)
        XCTAssertFalse(app.buttons["seat-style-2"].exists)
    }

    func testFirstLessonReachesCourseAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_TEST_FIRST_LESSON": "1",
        ])

        let start = app.buttons["시작하기"]
        XCTAssertTrue(start.waitForExistence(timeout: 15))
        XCTAssertTrue(scrollUntilHittable(start, in: app),
                      "The welcome action must remain reachable at AX XXXL.")
        start.tap()
        let next = app.buttons["firstLesson.next"]
        XCTAssertTrue(app.staticTexts["어느 쪽이 이길까요?"].waitForExistence(timeout: 15))
        let exampleAnswer = firstButton(prefix: "내 카드", in: app)
        XCTAssertTrue(scrollUntilHittable(exampleAnswer, in: app),
                      "The guided hand choice must remain reachable at AX XXXL.")
        exampleAnswer.tap()

        let tryTransfer = app.buttons["다른 카드로 풀어보기"]
        XCTAssertTrue(scrollUntilHittable(tryTransfer, in: app),
                      "The first explanation and transfer action must remain reachable at AX XXXL.")
        tryTransfer.tap()

        XCTAssertTrue(app.staticTexts["같은 규칙으로 골라보세요"].waitForExistence(timeout: 10))
        let transferAnswer = firstButton(prefix: "상대 카드", in: app)
        XCTAssertTrue(scrollUntilHittable(transferAnswer, in: app),
                      "The transfer hand choice must remain reachable at AX XXXL.")
        transferAnswer.tap()

        XCTAssertTrue(scrollUntilHittable(next, in: app),
                      "The transfer explanation and its next action must remain reachable at AX XXXL.")
        next.tap()
        XCTAssertTrue(scrollUntilHittable(next, in: app))
        next.tap()
        let finishGuide = app.buttons["firstLesson.finish"]
        XCTAssertTrue(finishGuide.waitForExistence(timeout: 10))
        XCTAssertTrue(scrollUntilHittable(finishGuide, in: app),
                      "The wrap-up's action must remain reachable at AX XXXL.")
        finishGuide.tap()

        let basicsNext = app.buttons["basics.next"]
        XCTAssertTrue(basicsNext.waitForExistence(timeout: 10))
        XCTAssertTrue(scrollUntilHittable(basicsNext, in: app),
                      "The ladder's action must remain reachable at AX XXXL.")
        basicsNext.tap()
        let choice = app.buttons["basics.choice.flush"]
        XCTAssertTrue(scrollUntilHittable(choice, in: app),
                      "The basics check must remain reachable at AX XXXL.")
        choice.tap()
        let finish = app.buttons["basics.finish"]
        XCTAssertTrue(scrollUntilHittable(finish, in: app),
                      "The basics verdict and course entry must remain reachable at AX XXXL.")
        finish.tap()

        let firstStep = app.descendants(matching: .any)["walkthrough-step-0"]
        XCTAssertTrue(firstStep.waitForExistence(timeout: 10))
        XCTAssertTrue(firstStep.label.contains("누가 이길까요?"))
    }

    func testReminderAndMilestoneShareStayReachableAtAccessibilityXXXL() {
        let settings = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_SEED": "1",
            "GT_DEMO_SETTINGS": "1",
            "GT_DEMO_REMINDER": "on",
        ])
        XCTAssertTrue(scrollUntilHittable(settings.switches["settings-reminder"], in: settings),
                      "The reminder switch must be reachable at AX XXXL.")
        let reminderCapture = XCTAttachment(screenshot: settings.screenshot())
        reminderCapture.name = "settings-reminder-row-AX5-KO"
        reminderCapture.lifetime = .keepAlways
        add(reminderCapture)
        XCTAssertTrue(scrollUntilHittable(settings.datePickers["settings-reminder-time"], in: settings),
                      "The reminder time must be reachable at AX XXXL.")
        settings.terminate()

        let summary = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_SEED": "1",
            "GT_DEMO_NODE": "u2-potOdds",
            "GT_DEMO_SESSION_COMPLETE": "1",
            "GT_DEMO_MILESTONE": "unit",
        ])
        XCTAssertTrue(scrollUntilHittable(summary.buttons["milestone-share"], in: summary),
                      "The share button must be reachable at AX XXXL.")
        XCTAssertTrue(scrollUntilHittable(summary.buttons["완료"], in: summary))
    }

    private func launch(environment: [String: String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchArguments += accessibilityXXXL
        app.launchEnvironment = environment
        app.launch()
        return app
    }

    private func scrollUntilHittable(_ element: XCUIElement, in app: XCUIApplication,
                                     maximumSwipes: Int = 12) -> Bool {
        guard element.waitForExistence(timeout: 15) else { return false }
        for _ in 0...maximumSwipes {
            if element.exists, element.isHittable { return true }
            app.swipeUp()
        }
        return element.exists && element.isHittable
    }

    private func scrollUntilFullyVisible(_ element: XCUIElement, above obstruction: XCUIElement,
                                         in app: XCUIApplication,
                                         maximumSwipes: Int = 12) -> Bool {
        for _ in 0...maximumSwipes {
            let frame = element.frame
            if frame.minY >= app.frame.minY, frame.maxY <= bottom(of: obstruction, in: app) {
                return true
            }
            app.swipeUp()
        }
        let frame = element.frame
        return frame.minY >= app.frame.minY && frame.maxY <= bottom(of: obstruction, in: app)
    }

    /// The lowest y an element may reach: the obstruction's top, or the screen's bottom
    /// when the obstruction is the app itself.
    private func bottom(of obstruction: XCUIElement, in app: XCUIApplication) -> CGFloat {
        obstruction == app ? app.frame.maxY : obstruction.frame.minY
    }

    private func scrollForwardUntilMaterializedAndHittable(_ element: XCUIElement,
                                                            in app: XCUIApplication,
                                                            maximumSwipes: Int = 12) -> Bool {
        for _ in 0...maximumSwipes {
            if element.exists, element.isHittable { return true }
            app.swipeUp()
        }
        return element.exists && element.isHittable
    }

    private func scrollBackwardUntilHittable(_ element: XCUIElement, in app: XCUIApplication,
                                              maximumSwipes: Int = 12) -> Bool {
        for _ in 0...maximumSwipes {
            if element.exists, element.isHittable { return true }
            app.swipeDown()
        }
        return element.exists && element.isHittable
    }

    private func firstButton(prefix: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }
}
