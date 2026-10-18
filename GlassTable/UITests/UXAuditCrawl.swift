// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

/// Drives the app flow by flow and saves every screen (full page, scrolled) with the tap
/// that reached it and the controls on it. `tools/uxaudit/report.py` turns the output into
/// the UX audit report. Skipped unless the runner has GT_AUDIT_OUT (pass it to xcodebuild
/// as TEST_RUNNER_GT_AUDIT_OUT).
final class UXAuditCrawl: XCTestCase {
    private var out: URL!
    private var app: XCUIApplication!
    private var rec: AuditRecorder!

    override func setUpWithError() throws {
        continueAfterFailure = true
        guard let path = ProcessInfo.processInfo.environment["GT_AUDIT_OUT"] else {
            throw XCTSkip("UX audit crawl runs only with GT_AUDIT_OUT")
        }
        out = URL(fileURLWithPath: path)
    }

    // MARK: - launch

    /// `pathNode` seeds a store that has finished the first-run guide with every node
    /// before `pathNode` cleared; nil starts a brand-new install.
    @discardableResult
    private func launch(pathNode: String? = "u1-showdown", seed: Bool = false,
                        env: [String: String] = [:]) -> XCUIApplication {
        app?.terminate()
        let app = XCUIApplication()
        // Korean through the device language, so Settings can still switch it.
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launchEnvironment["GT_TEST_STORE_ID"] = UUID().uuidString
        if let pathNode { app.launchEnvironment["GT_TEST_PATH_CURRENT_NODE"] = pathNode }
        if seed { app.launchEnvironment["GT_DEMO_SEED"] = "1" }
        for (k, v) in env { app.launchEnvironment[k] = v }
        app.launch()
        self.app = app
        if rec == nil { rec = AuditRecorder(root: out) }
        rec.app = app
        return app
    }

    private func tabs() -> Bool { app.tabBars.buttons["설정"].waitForExistence(timeout: 15) }

    // MARK: - element helpers

    private func any(_ id: String) -> XCUIElement { app.descendants(matching: .any)[id] }

    private func anyPrefix(_ prefix: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix)).firstMatch
    }

    private func button(_ label: String) -> XCUIElement { app.buttons[label].firstMatch }

    private func buttonContaining(_ text: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    private func text(_ label: String) -> XCUIElement { app.staticTexts[label].firstMatch }

    private func textContaining(_ s: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", s)).firstMatch
    }

    /// Taps after bringing the element on screen. Records a finding when it is missing.
    @discardableResult
    private func tap(_ el: XCUIElement, _ what: String, timeout: TimeInterval = 8) -> Bool {
        guard el.waitForExistence(timeout: timeout) else {
            rec.problem("Could not find \(what) to tap")
            return false
        }
        var tries = 0
        while !el.isHittable && tries < 6 {
            rec.nudge(up: true); tries += 1
        }
        // Past the bottom: the control sits above what is on screen.
        while !el.isHittable && tries < 16 {
            rec.nudge(up: false); tries += 1
        }
        if !el.isHittable {
            rec.problem("\(what) exists but could not be brought on screen to tap")
            return false
        }
        el.tap()
        return true
    }

    private func pause(_ s: Double = 0.5) { usleep(useconds_t(s * 1_000_000)) }

    /// Closes whatever sheet or cover is on top through its own close control.
    private func closeTop(_ what: String) {
        // The topmost match is the last one in the tree; the screen underneath has its own 닫기.
        let closers = app.buttons.matching(NSPredicate(
            format: "label IN %@ OR label ENDSWITH '닫기'", ["닫기", "완료", "확인", "Close"]))
        if let b = closers.allElementsBoundByIndex.last(where: { $0.isHittable }) {
            b.tap(); pause(); return
        }
        // ChromeButton.close is an icon; its label is 닫기 in Korean, else swipe down.
        app.swipeDown(velocity: .fast)
        pause()
        rec.problem("\(what): no visible close control, dismissed by swiping down")
    }

    // MARK: - 1. First run

    func test01FirstRun() {
        launch(pathNode: nil)
        rec.flow("first-run-right", section: "시작 안내", title: "첫 실행 · 정답으로 끝까지",
                 summary: "새로 설치한 앱을 열고 수준을 고른 뒤 시작 안내를 끝까지 보고, 워밍업 두 문제를 맞히고 족보 레슨을 거쳐 첫 레슨으로 들어가요.",
                 group: "first-run", pass: "a")
        if text("포커가 얼마나 익숙한가요?").waitForExistence(timeout: 20) {
            rec.shot("수준 묻기", after: "앱을 처음 실행")
            // "New to poker" skips the three check questions and goes on to the welcome.
            tap(button("처음 배워요"), "처음 배워요")
            pause(1)
        }
        XCTAssertTrue(text("Glass Table에 오신 걸 환영해요").waitForExistence(timeout: 20))
        rec.shot("환영 화면", after: "‘처음 배워요’ 탭")
        tap(button("시작하기"), "시작하기")
        rec.shot("1/6 팟", after: "‘시작하기’ 탭")
        let next = app.buttons["firstLesson.next"]
        let pages = ["2/6 블라인드", "3/6 액션", "4/6 흐름", "5/6 가장 좋은 5장"]
        for page in pages {
            tap(next, "다음")
            rec.shot(page, after: "‘다음’ 탭")
        }
        tap(button("워밍업 시작"), "워밍업 시작")
        rec.shot("워밍업 1/2 문제", after: "‘워밍업 시작’ 탭", group: "warm1", branch: "question")
        tap(firstButton(prefix: "내 카드"), "내 카드 선택")
        rec.shot("워밍업 1/2 · 정답", after: "‘내 카드’ 선택 (정답)", group: "warm1", branch: "right")
        tap(button("다른 카드로 풀어보기"), "다른 카드로 풀어보기")
        rec.shot("워밍업 2/2 문제", after: "‘다른 카드로 풀어보기’ 탭", group: "warm2", branch: "question")
        tap(firstButton(prefix: "상대 카드"), "상대 카드 선택")
        rec.shot("워밍업 2/2 · 정답", after: "‘상대 카드’ 선택 (정답)", group: "warm2", branch: "right")
        tap(next, "다음")
        rec.shot("6/6 마무리", after: "‘다음’ 탭")
        tap(app.buttons["firstLesson.finish"], "족보 보기")
        pause(1)
        rec.shot("홀덤 기초 1/3 족보 사다리", after: "‘족보 보기’ 탭")
        tap(app.buttons["basics.next"], "basics next")
        rec.shot("홀덤 기초 2/3 확인 문제", after: "‘다음’ 탭", group: "basics", branch: "question")
        tap(app.buttons["basics.choice.flush"], "플러시 선택")
        rec.shot("확인 문제 · 정답", after: "‘플러시’ 선택 (정답)", group: "basics", branch: "right")
        tap(app.buttons["basics.check-next"], "basics check next")
        rec.shot("홀덤 기초 3/3 같은 페어라면?", after: "‘다음’ 탭")
        tap(app.buttons["basics.kicker.choice.mine"], "내 카드 선택")
        rec.shot("같은 페어 · 정답", after: "‘내 카드’ 선택 (정답)")
        tap(app.buttons["basics.finish"], "basics finish")
        pause(1.5)
        rec.shot("첫 레슨(쇼다운) 시작", after: "기초 레슨의 마지막 버튼 탭")

        // The same guide answered wrong, from a fresh install.
        launch(pathNode: nil)
        skipFirstPlacement()
        rec.flow("first-run-wrong", section: "시작 안내", title: "첫 실행 · 오답 경로",
                 summary: "같은 안내에서 워밍업과 족보 확인 문제를 일부러 틀렸을 때 보이는 화면이에요.",
                 group: "first-run", pass: "b")
        XCTAssertTrue(button("시작하기").waitForExistence(timeout: 20))
        tap(button("시작하기"), "시작하기")
        for _ in 0..<4 { tap(next, "다음") }
        tap(button("워밍업 시작"), "워밍업 시작")
        tap(firstButton(prefix: "상대 카드"), "상대 카드 선택")
        rec.shot("워밍업 1/2 · 오답", after: "‘상대 카드’ 선택 (오답)", group: "warm1", branch: "wrong")
        tapFirstExisting(["다른 카드로 풀어보기", "다시 풀기", "다음"], what: "오답 뒤 버튼")
        rec.shot("오답 뒤 다음 화면", after: "오답 화면의 버튼 탭", group: "warm1", branch: "wrong")
        if firstButton(prefix: "내 카드").exists && !text("같은 규칙으로 골라보세요").exists {
            tap(firstButton(prefix: "내 카드"), "내 카드")
            rec.shot("다시 고른 뒤", after: "‘내 카드’ 선택", group: "warm1", branch: "wrong")
            tapFirstExisting(["다른 카드로 풀어보기", "다음"], what: "다음 문제")
        }
        if text("같은 규칙으로 골라보세요").waitForExistence(timeout: 5) {
            tap(firstButton(prefix: "내 카드"), "내 카드 선택")
            rec.shot("워밍업 2/2 · 오답", after: "‘내 카드’ 선택 (오답)", group: "warm2", branch: "wrong")
            tapFirstExisting(["다음", "다시 풀기"], what: "오답 뒤 버튼")
            rec.shot("오답 뒤 다음 화면", after: "오답 화면의 버튼 탭", group: "warm2", branch: "wrong")
        }
        if app.buttons["firstLesson.next"].exists { tap(next, "다음") }
        if app.buttons["firstLesson.finish"].waitForExistence(timeout: 5) {
            tap(app.buttons["firstLesson.finish"], "족보 보기")
            tap(app.buttons["basics.next"], "basics next")
            tap(app.buttons["basics.choice.straight"], "스트레이트 선택")
            rec.shot("확인 문제 · 오답", after: "‘스트레이트’ 선택 (오답)", group: "basics", branch: "wrong")
        }

        // Welcome's other door.
        launch(pathNode: nil)
        skipFirstPlacement()
        rec.flow("first-run-skip", section: "시작 안내", title: "첫 실행 · 안내 건너뛰기",
                 summary: "환영 화면에서 ‘안내 건너뛰기’를 누르면 어디로 가는지 확인해요.")
        tap(button("안내 건너뛰기"), "안내 건너뛰기", timeout: 20)
        pause(1)
        rec.shot("건너뛴 뒤 첫 화면", after: "‘안내 건너뛰기’ 탭")
        tap(app.buttons["learn-basics-start"], "기초 레슨 시작")
        rec.shot("홀덤 기초 (학습 탭에서 시작)", after: "‘시작’ 탭")
        tap(app.buttons["basics.close"], "기초 닫기")
        rec.shot("기초를 닫은 뒤", after: "닫기 탭")
    }

    /// A new install asks for a level before the welcome; this takes its "no check" door.
    private func skipFirstPlacement() {
        let skip = button("확인 없이 시작하기")
        if skip.waitForExistence(timeout: 20) { skip.tap(); pause(1) }
    }

    private func firstButton(prefix: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    private func tapFirstExisting(_ labels: [String], what: String) {
        for l in labels where button(l).exists { tap(button(l), l); return }
        if app.buttons["firstLesson.next"].exists { tap(app.buttons["firstLesson.next"], "다음"); return }
        rec.problem("No expected button for \(what) (looked for \(labels.joined(separator: ", ")))")
    }

    // MARK: - 2. Learn tab

    func test02Learn() {
        launch()
        XCTAssertTrue(tabs())
        rec.flow("learn-new", section: "배우기 탭", title: "배우기 탭 · 막 시작한 사용자",
                 summary: "시작 안내를 마친 직후의 배우기 탭과 그 안의 모든 입구예요.")
        // Learn is the lesson list itself (owner, 2026-10-17).
        rec.shot("배우기 탭", after: "앱 실행 (안내 완료 상태)")
        if tap(app.buttons["learn-level"], "내 수준") {
            pause(1)
            rec.shot("내 수준 고르기", after: "‘내 수준’ 탭", scroll: false)
            if button("취소").exists { button("취소").tap() }
            else { app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap() }
            pause()
        }
        rec.shot("배우기 탭 (모든 입구 확인 후)", after: "닫기", scroll: false)

        practiceRound()
        placementRun()
        returningUser()
    }

    /// 연습: a passed lesson's five-question round.
    private func practiceRound() {
        launch(pathNode: nil, seed: true)
        XCTAssertTrue(tabs())
        rec.flow("learn-practice", section: "배우기 탭", title: "연습 · 한 라운드",
                 summary: "배우기 탭에서 통과한 레슨의 ‘연습’을 눌러 다섯 문제를 끝까지 풀어요. 이 흐름은 첫 번째 답을 그대로 보여줘요.")
        guard tap(app.buttons["practice-showdown"], "연습") else { return }
        pause(1)
        rec.shot("연습 시작", after: "‘연습’ 탭")
        var memory: [String: QMemory] = [:]
        driveSession(pass: .first, memory: &memory, maxSteps: 40, flowLabel: "집중 연습")
    }

    private func placementRun() {
        let variants: [(String, String, String?)] = [
            ("learn-placement", "처음 배워요", nil),
            ("learn-placement-unsure", "규칙은 알지만 선택이 어려워요", "아직 잘 모르겠어요"),
            ("learn-placement-skip", "", nil),
        ]
        for (id, report, forced) in variants {
            launch()
            XCTAssertTrue(tabs())
            // The starting-point check now opens from Settings.
            tap(app.tabBars.buttons["설정"], "설정 탭")
            let row = buttonContaining("시작점 다시 찾아보기")
            guard row.waitForExistence(timeout: 5) else {
                rec.problem("설정에 ‘시작점 다시 찾아보기’가 없어요"); return
            }
            let title = report.isEmpty ? "시작점 찾아보기 · 확인 없이 시작" :
                "시작점 찾아보기 · ‘\(report)’" + (forced == nil ? " + 첫 번째 보기" : " + ‘\(forced!)’")
            rec.flow(id, section: "설정 탭", title: title,
                     summary: report.isEmpty ? "확인 문제 없이 바로 시작하면 어디로 가는지 봐요."
                        : "자기소개 답을 고르고 확인 문제 세 개에 " + (forced == nil ? "매번 첫 번째 보기를" : "매번 ‘아직 잘 모르겠어요’를") + " 골라 추천을 받아요.")
            tap(row, "시작점 다시 찾아보기")
            pause(1)
            if id == "learn-placement" { rec.shot("시작점 찾기 첫 화면", after: "설정의 ‘시작점 다시 찾아보기’ 탭") }
            if report.isEmpty {
                tap(button("확인 없이 시작하기"), "확인 없이 시작하기")
                pause(1)
                rec.shot("확인 없이 시작한 뒤", after: "‘확인 없이 시작하기’ 탭")
                continue
            }
            tap(button(report), report)
            for q in 1...3 {
                pause(0.8)
                rec.shot("확인 문제 \(q)/3", after: q == 1 ? "‘\(report)’ 탭" : "이전 문제에 답")
                if let forced { tap(button(forced), forced) }
                else {
                    let options = app.buttons.allElementsBoundByIndex.filter {
                        $0.isHittable && !["닫기", "확인 없이 시작하기", "아직 잘 모르겠어요"].contains($0.label) && !$0.label.isEmpty
                    }
                    if let first = options.first { let l = first.label; first.tap(); rec.note("고른 답: \(l)") }
                }
            }
            pause(1)
            rec.shot("추천 결과", after: "세 번째 문제에 답")
            if button("배우기로 돌아가기").exists {
                tap(button("배우기로 돌아가기"), "배우기로 돌아가기")
                pause(1)
                rec.shot("추천 뒤 돌아온 화면", after: "‘배우기로 돌아가기’ 탭")
            }
        }
    }

    /// GT_DEMO_SEED: a learner partway along the path, with reviews due.
    private func returningUser() {
        launch(pathNode: nil, seed: true)
        XCTAssertTrue(tabs())
        rec.flow("learn-returning", section: "배우기 탭", title: "배우기 탭 · 진행 중인 사용자",
                 summary: "몇 레슨을 마치고 복습할 주제가 쌓인 상태(데모 진행 데이터)의 배우기 탭과 복습 한 번이에요.")
        rec.shot("배우기 탭 (진행 중)", after: "앱 실행 (진행 중인 데이터)")
        let review = app.buttons["learn-review"]
        if review.waitForExistence(timeout: 3) {
            let label = review.label
            tap(review, "복습")
            pause(1)
            rec.shot("복습 시작", after: "‘\(label)’ 탭")
            var memory: [String: QMemory] = [:]
            driveSession(pass: .first, memory: &memory, maxSteps: 30, flowLabel: "복습")
        }
    }

    // MARK: - 3. Play

    func test03PlayFree() {
        for players in [2, 3, 4] {
            launch()
            XCTAssertTrue(tabs())
            tap(app.tabBars.buttons["플레이"], "플레이 탭")
            pause(1)
            rec.flow("play-free-\(players)", section: "플레이 탭",
                     title: "자유 대전 · 컴퓨터 \(players - 1)명",
                     summary: "플레이 탭에서 자유 대전을 열고 \(players)명 테이블을 만들어 핸드를 끝까지 쳐요. 1번 핸드는 체크·콜로 쇼다운까지, 2번 핸드는 처음에 올리고 이후 체크·콜\(players == 4 ? ", 3번 핸드는 첫 차례에 폴드해요." : "해요.")")
            rec.shot("플레이 탭", after: "탭 바의 ‘플레이’ 탭")
            tap(app.buttons["play-quick"], "빠른 게임")
            pause(1)
            rec.shot("테이블 만들기", after: "‘빠른 게임’ 탭")
            if players == 2 { exploreSetup() }
            tap(app.buttons["player-count-\(players)"], "\(players)명")
            rec.shot("\(players)명 선택", after: "‘\(players)명’ 탭")
            tap(app.buttons["table-start"], "이 테이블로 시작")
            pause(1.5)
            rec.shot("테이블 첫 화면", after: "‘이 테이블로 시작’ 탭")
            // The first table opens with the help panel on its rules tab.
            if app.buttons["free-table-back-close"].waitForExistence(timeout: 3) {
                tap(app.buttons["free-table-back-close"], "테이블로 돌아가기")
                rec.shot("안내를 닫은 테이블", after: "‘테이블로 돌아가기’ 탭")
            }
            let hands = players == 4 ? 3 : 2
            for hand in 1...hands {
                let style: PlayStyle = hand == 1 ? .passive : (hand == 2 ? .raiseFirst : .fold)
                playFreeHand(hand: hand, style: style, explore: hand == 1, last: hand == hands)
            }
        }
    }

    /// Expanding the computers' rules on a two-player table once ended the app; this keeps
    /// watching that it stays open.
    func test06PlayCrash() {
        launch()
        XCTAssertTrue(tabs())
        tap(app.tabBars.buttons["플레이"], "플레이 탭")
        rec.flow("play-crash", section: "플레이 탭", title: "자유 대전 · 컴퓨터 규칙 펼치기 (2명 테이블)",
                 summary: "2명 테이블에서 도움 패널의 규칙 탭을 열고 ‘컴퓨터는 어떻게 고를까요?’를 펼쳐요. 예전에는 여기서 앱이 종료됐어요.")
        tap(app.buttons["play-quick"], "빠른 게임")
        tap(app.buttons["player-count-2"], "2명")
        tap(app.buttons["table-start"], "이 테이블로 시작")
        pause(1.5)
        // The first table opens with the help panel already on its rules tab.
        if !app.buttons["free-back-rules"].waitForExistence(timeout: 5) {
            guard tap(app.buttons["free-table-help"], "도움", timeout: 15) else { return }
        }
        tap(app.buttons["free-back-rules"], "규칙")
        rec.shot("도움 패널 · 규칙", after: "‘규칙’ 탭")
        tapPolicyToggle()
        pause(2)
        let alive = app.state == .runningForeground
        rec.shot(alive ? "펼친 뒤 (앱 유지)" : "펼친 뒤 · 앱이 종료되고 홈 화면", after: "‘컴퓨터는 어떻게 고를까요?’ 탭")
        if !alive { rec.problem("앱 종료(크래시): 2명 테이블에서 ‘컴퓨터는 어떻게 고를까요?’를 펼침") }
    }

    private func exploreSetup() {
        for count in [3, 4] {
            tap(app.buttons["player-count-\(count)"], "\(count)명")
            rec.shot("인원 \(count)명", after: "‘\(count)명’ 탭")
        }
        let seat = app.buttons["seat-style-1"]
        if seat.exists {
            tap(seat, "1번 자리 스타일")
            pause()
            rec.shot("1번 자리 스타일 고르기", after: "1번 자리 스타일 탭", scroll: false)
            // A menu closes by tapping outside it.
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.05)).tap()
            pause()
            // Still open: choosing an entry is the other way out.
            if !app.buttons["style-guide"].isHittable, button("재미로").exists { button("재미로").tap(); pause() }
        }
        tap(app.buttons["style-guide"], "스타일 자세히 보기")
        pause(1)
        rec.shot("스타일 가이드", after: "‘스타일 자세히 보기’ 탭")
        let first = anyPrefix("opponent-")
        if first.exists {
            let label = first.label
            tap(first, "스타일 하나")
            pause(1)
            rec.shot("스타일 상세", after: "‘\(label)’ 탭")
        }
        if !app.buttons["player-count-2"].isHittable { closeTop("스타일 가이드") }
        if !app.buttons["player-count-2"].isHittable { closeTop("스타일 가이드") }
        tap(app.buttons["player-count-2"], "2명")
    }

    private enum PlayStyle { case passive, raiseFirst, fold }

    private func playFreeHand(hand: Int, style: PlayStyle, explore: Bool, last: Bool) {
        var decisions = 0
        var raised = false
        for _ in 0..<60 {
            pause(0.8)
            if app.buttons["free-new-game"].exists {
                rec.shot("\(hand)번 핸드 · 게임 끝", after: "칩이 한쪽으로 모두 넘어감")
                return
            }
            if app.buttons["free-next-hand"].exists {
                rec.shot("\(hand)번 핸드 · 결과", after: decisions == 0 ? "핸드 종료" : "마지막 선택 뒤 핸드 종료")
                if explore { exploreReview(hand: hand) }
                if last {
                    tap(app.buttons["free-change-table"], "테이블 바꾸기")
                    rec.shot("테이블 바꾸기 확인", after: "‘테이블 바꾸기’ 탭", scroll: false)
                    tap(button("테이블 다시 만들기"), "테이블 다시 만들기")
                    pause(1)
                    rec.shot("테이블을 다시 만든 뒤", after: "‘테이블 다시 만들기’ 탭")
                } else {
                    tap(app.buttons["free-next-hand"], "다음 핸드")
                }
                return
            }
            let fold = app.buttons["free-fold"]
            let middle = app.buttons["free-call"].exists ? app.buttons["free-call"] : app.buttons["free-check"]
            // The buttons come and go with the deal animation; a query that finds nothing fails
            // the test, so read the button once and only then ask whether it can be tapped.
            let seen = try? middle.snapshot()
            let onScreen = seen.map { !$0.frame.isEmpty && app.frame.contains($0.frame) && $0.isEnabled } ?? false
            guard onScreen, middle.exists, middle.isHittable else {
                // The result plays out as an animation that can be skipped.
                let skip = app.buttons["free-skip-result"]
                if skip.exists, skip.isHittable { skip.tap() }
                continue
            }
            decisions += 1
            rec.shot("\(hand)번 핸드 · 내 차례 \(decisions)", after: decisions == 1 ? "핸드 시작" : "이전 선택 뒤 컴퓨터 행동")
            var desc = middle.label
            let raise = app.buttons["free-raise"]
            if style == .fold, decisions == 1, fold.isEnabled {
                desc = fold.label; fold.tap()
            } else if style == .raiseFirst, !raised, raise.exists, raise.isEnabled {
                raised = true
                let opened = raise.label
                raise.tap(); pause()
                rec.shot("\(hand)번 핸드 · 금액 고르기", after: "‘\(opened)’ 탭")
                let confirm = app.buttons["free-raise-confirm"]
                if confirm.exists && confirm.isEnabled { desc = confirm.label; confirm.tap() }
                else {
                    rec.problem("금액을 확정하는 버튼을 누를 수 없어요")
                    if app.buttons["free-raise-cancel"].exists { app.buttons["free-raise-cancel"].tap() }
                    middle.tap()
                }
            } else {
                middle.tap()
            }
            rec.note("선택: \(desc)")
        }
        rec.problem("\(hand)번 핸드가 60번 기다려도 끝나지 않았어요")
        rec.shot("\(hand)번 핸드 · 멈춘 화면", after: "대기")
    }

    /// The toggle sits at the end of the help panel's own scroll view.
    @discardableResult
    private func tapPolicyToggle() -> Bool {
        let how = any("free-table-policy-toggle").firstMatch
        guard how.waitForExistence(timeout: 4) else {
            rec.problem("Could not find 컴퓨터는 어떻게 고를까요? to tap"); return false
        }
        // The panel is short, so scroll by its own frame and tap by position.
        let content = app.scrollViews["free-back-content"].firstMatch.frame
        func inView() -> Bool { how.frame.minY >= content.minY && how.frame.maxY <= content.maxY }
        let origin = app.coordinate(withNormalizedOffset: .zero)
        for _ in 0..<12 where !inView() {
            origin.withOffset(CGVector(dx: content.midX, dy: content.maxY - 20))
                .press(forDuration: 0.05, thenDragTo: origin.withOffset(CGVector(dx: content.midX, dy: content.minY + 20)))
        }
        guard inView() else {
            rec.problem("컴퓨터는 어떻게 고를까요? exists but could not be brought on screen to tap"); return false
        }
        how.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        return true
    }

    /// The step-by-step hand review, then each face of the help panel.
    private func exploreReview(hand: Int) {
        if tap(app.buttons["free-review"], "핸드 돌아보기") {
            pause(1)
            for page in 1...12 {
                rec.shot("\(hand)번 핸드 · 돌아보기 \(page)", after: page == 1 ? "‘핸드 돌아보기’ 탭" : "‘다음’ 탭")
                guard app.buttons["coach-next"].exists else { break }
                tap(app.buttons["coach-next"], "다음"); pause(0.6)
            }
            if app.buttons["coach-done"].exists { tap(app.buttons["coach-done"], "돌아보기 닫기") }
            else { closeTop("핸드 돌아보기") }
            pause()
        }
        guard tap(app.buttons["free-table-help"], "도움") else { return }
        pause()
        rec.shot("\(hand)번 핸드 · 도움 패널", after: "도움 버튼 탭")
        for (id, name) in [("hint", "힌트"), ("hand", "이번 핸드"), ("rules", "규칙")] where app.buttons["free-back-\(id)"].exists {
            tap(app.buttons["free-back-\(id)"], name)
            rec.shot("\(hand)번 핸드 · 도움 패널 ‘\(name)’", after: "‘\(name)’ 탭")
        }
        if tapPolicyToggle() {
            rec.shot("\(hand)번 핸드 · 컴퓨터 규칙 펼침", after: "‘컴퓨터는 어떻게 고를까요?’ 탭")
        }
        tap(app.buttons["free-table-back-close"], "테이블로 돌아가기")
        pause()
    }

    func test04PlayGraded() {
        launch()
        XCTAssertTrue(tabs())
        tap(app.tabBars.buttons["플레이"], "플레이 탭")
        rec.flow("play-graded", section: "플레이 탭", title: "1:1 채점 연습",
                 summary: "플레이 탭의 1:1 채점 연습에서 상대 스타일을 모두 열어 본 뒤, 한 상대와 두 핸드를 쳐요. 1번 핸드는 콜 위주, 2번 핸드는 공격적으로 골라요.")
        tap(app.buttons["play-graded"], "1:1 채점 연습")
        pause(1)
        rec.shot("상대 고르기", after: "‘1:1 채점 연습’ 탭")
        let ids = ["nit", "tag", "lag", "station", "maniac"]
        for id in ids where app.buttons["opponent-\(id)"].exists {
            let name = app.buttons["opponent-\(id)"].label.components(separatedBy: ",").first ?? id
            tap(app.buttons["opponent-\(id)"], name)
            pause(1)
            rec.shot("상대 상세 · \(name)", after: "‘\(name)’ 탭")
            closeTop("상대 상세")
        }
        let tag = app.buttons["opponent-tag"]
        tap(tag, "선별형")
        pause(1)
        tap(app.buttons["opponent-start"], "이 상대와 연습")
        pause(1.5)
        for hand in 1...2 {
            playGradedHand(hand: hand, aggressive: hand == 2)
        }
    }

    private func playGradedHand(hand: Int, aggressive: Bool) {
        var decisions = 0
        var sawChart = false
        for _ in 0..<25 {
            pause(0.8)
            let cont = button("계속")
            if cont.exists {
                rec.shot("\(hand)번 핸드 · 채점", after: "선택 뒤")
                if !sawChart, button("차트 보기").exists {
                    sawChart = true
                    tap(button("차트 보기"), "차트 보기")
                    pause(1)
                    rec.shot("\(hand)번 핸드 · 디펜드 차트", after: "‘차트 보기’ 탭")
                    closeTop("차트")
                }
                tap(cont, "계속")
                continue
            }
            if button("다음 핸드").exists {
                rec.shot("\(hand)번 핸드 · 끝", after: "핸드 종료")
                if hand < 2 { tap(button("다음 핸드"), "다음 핸드") }
                return
            }
            let size = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'table-bet-size-'")).firstMatch
            if size.exists {
                let label = size.label
                rec.shot("\(hand)번 핸드 · 금액 고르기", after: "‘벳’ 또는 ‘레이즈’ 탭")
                size.tap()
                rec.note("금액: \(label)")
                continue
            }
            let actions = app.buttons.allElementsBoundByIndex.filter {
                $0.isHittable && $0.isEnabled && ($0.label.hasPrefix("폴드") || $0.label.hasPrefix("콜") ||
                    $0.label.hasPrefix("체크") || $0.label.hasPrefix("3벳") ||
                    $0.label.hasPrefix("벳") || $0.label.hasPrefix("레이즈"))
            }
            if !actions.isEmpty {
                decisions += 1
                rec.shot("\(hand)번 핸드 · 결정 \(decisions)", after: decisions == 1 ? "핸드 시작" : "이전 단계 뒤")
                let pick: XCUIElement
                if aggressive {
                    pick = actions.first { $0.label.hasPrefix("3벳") || $0.label.hasPrefix("벳") || $0.label.hasPrefix("레이즈") } ?? actions[0]
                } else {
                    pick = actions.first { $0.label.hasPrefix("콜") || $0.label.hasPrefix("체크") } ?? actions[0]
                }
                let label = pick.label
                pick.tap()
                rec.note("선택: \(label)")
                continue
            }
        }
        rec.problem("1:1 \(hand)번 핸드가 끝나지 않았어요")
        rec.shot("\(hand)번 핸드 · 멈춘 화면", after: "대기")
    }

    // MARK: - 4. Progress and Settings

    func test05ProgressAndSettings() {
        for seeded in [false, true] {
            let open = { [self] in
                launch(pathNode: seeded ? nil : "u1-showdown", seed: seeded)
                XCTAssertTrue(tabs())
                tap(app.tabBars.buttons["기록"], "기록 탭")
                pause(1)
            }
            open()
            rec.flow(seeded ? "progress-returning" : "progress-new", section: "기록 탭",
                     title: seeded ? "기록 탭 · 진행 중인 사용자" : "기록 탭 · 막 시작한 사용자",
                     summary: seeded ? "데모 진행 데이터로 채운 기록 탭이에요. 누를 수 있는 항목을 하나씩 눌러 결과를 보여줘요. 항목마다 앱을 새로 열어 같은 출발점에서 눌렀어요."
                                     : "아직 푼 문제가 없는 기록 탭과 그 안의 항목이에요.")
            rec.shot("기록 탭", after: "탭 바의 ‘기록’ 탭")
            exploreButtons(skip: [], limit: 16, reopen: open)
        }
        settings()
    }

    private func settings() {
        let open = { [self] in
            launch()
            XCTAssertTrue(tabs())
            tap(app.tabBars.buttons["설정"], "설정 탭")
            pause(1)
        }
        open()
        rec.flow("settings", section: "설정 탭", title: "설정 탭",
                 summary: "설정 탭의 항목을 하나씩 눌러 봐요. 언어와 화면 모드는 바꾼 모습을 찍고 되돌려요. 상담 전화처럼 앱 밖으로 나가는 항목과 기록을 지우는 확인 버튼은 누르지 않아요.")
        rec.shot("설정 탭", after: "탭 바의 ‘설정’ 탭")
        if tap(app.buttons["language-english"], "English") {
            pause(1)
            rec.shot("영어로 바꾼 설정", after: "‘English’ 탭")
            tap(app.buttons["language-korean"], "한국어")
            pause(1)
        }
        if tap(app.buttons["appearance-dark"], "다크") {
            pause(1)
            rec.shot("다크 모드 설정", after: "‘다크’ 탭")
            tap(app.tabBars.buttons["배우기"], "배우기 탭")
            pause(1)
            rec.shot("다크 모드 배우기 탭", after: "탭 바의 ‘배우기’ 탭")
            tap(app.tabBars.buttons["설정"], "설정 탭")
            tap(app.buttons["appearance-system"], "시스템")
            pause(1)
        }
        let reminder = app.switches["settings-reminder"].exists ? app.switches["settings-reminder"]
                                                                : any("settings-reminder")
        if tap(reminder, "매일 알림") {
            pause(1.5)
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            if springboard.alerts.firstMatch.exists {
                rec.shot("알림 권한 요청", after: "‘매일 알림’ 켜기", scroll: false)
                for l in ["허용", "Allow"] where springboard.alerts.buttons[l].exists {
                    springboard.alerts.buttons[l].tap(); break
                }
                pause(1)
            }
            rec.shot("매일 알림 켬", after: "‘매일 알림’ 켜기")
            let time = any("settings-reminder-time")
            if time.exists {
                time.tap(); pause(1)
                rec.shot("알림 시간 고르기", after: "‘알림 시간’ 탭", scroll: false)
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.06)).tap()
                pause()
            }
        }
        rec.note("누르지 않음: 도박 문제 상담 번호(전화 걸기)")
        exploreButtons(skip: ["helpline-", "language-", "appearance-", "settings-reminder", "상담 번호"],
                       limit: 16, reopen: open)
    }

    /// Taps each distinct control on the screen once and captures where it went. Every
    /// tap starts from a fresh launch at the same place, so one control's result never
    /// changes the next. Dialogs that would erase or overwrite progress are cancelled.
    private func exploreButtons(skip: [String], limit: Int, reopen: () -> Void) {
        let tabLabels: Set<String> = ["배우기", "플레이", "기록", "설정"]
        var seen = Set<String>()
        var queue: [(label: String, id: String)] = []
        for _ in 0..<10 {
            for b in app.buttons.allElementsBoundByIndex where b.exists && b.isHittable {
                let key = b.identifier.isEmpty ? b.label : b.identifier
                if key.isEmpty || tabLabels.contains(b.label) || seen.contains(key) { continue }
                seen.insert(key)
                if skip.contains(where: { b.label.contains($0) || b.identifier.hasPrefix($0) }) { continue }
                queue.append((b.label, b.identifier))
            }
            let before = XCUIScreen.main.screenshot().pngRepresentation
            rec.nudge(up: true)
            if XCUIScreen.main.screenshot().pngRepresentation == before { break }
        }
        for (n, item) in queue.prefix(limit).enumerated() {
            if n > 0 { reopen() }
            let el = item.id.isEmpty ? button(item.label) : app.buttons[item.id]
            guard tap(el, item.label, timeout: 4) else { continue }
            pause(1.2)
            let name = item.label.count > 40 ? String(item.label.prefix(40)) + "…" : item.label
            rec.shot("‘\(name)’ 결과", after: "‘\(name)’ 탭")
            let dialog = app.alerts.firstMatch.exists || app.sheets.firstMatch.exists
            if dialog {
                rec.note("확인 창은 ‘취소’로 닫았어요")
                for label in ["취소", "Cancel"] where button(label).exists { button(label).tap(); break }
                continue
            }
            // One level deeper: the first control of whatever opened, if it is new.
            if !app.tabBars.firstMatch.isHittable {
                let inner = app.buttons.allElementsBoundByIndex.first { b in
                    b.isHittable && !b.label.isEmpty && !["닫기", "뒤로"].contains(b.label)
                        && !seen.contains(b.identifier.isEmpty ? b.label : b.identifier)
                        && !skip.contains(where: { b.label.contains($0) })
                }
                if let inner {
                    let l = inner.label
                    inner.tap(); pause(1.2)
                    let short = l.count > 40 ? String(l.prefix(40)) + "…" : l
                    rec.shot("‘\(name)’ › ‘\(short)’", after: "‘\(short)’ 탭")
                    if app.alerts.firstMatch.exists || app.sheets.firstMatch.exists {
                        for label in ["취소", "Cancel"] where button(label).exists { button(label).tap(); break }
                    }
                }
            }
        }
    }

    // MARK: - 5. Units

    func test10Unit1() { runUnit("t1") }
    func test11Unit2() { runUnit("t2") }
    func test12Unit3() { runUnit("t3") }
    func test13Unit4() { runUnit("t4") }
    func test14Unit5() { runUnit("t5") }

    /// The five tracks on Learn, in the order `Curriculum.tracks` lists them.
    private static let units: [String: (title: String, nodes: [(String, String)])] = [
        "t1": ("1. 기본기", [("u1-showdown", "쇼다운"), ("u1-position", "자리와 순서"), ("u1-boss", "선택 도전")]),
        "t2": ("2. 시작 패", [("u3-rfi", "먼저 올리기"), ("u8-defend", "올린 상대에 맞서기"), ("u3-boss", "선택 도전")]),
        "t3": ("3. 상대 읽기", [("u4-rangeRead", "상대 패 읽기"), ("u7-actionRead", "행동 읽기"),
                             ("u4-boss", "선택 도전")]),
        "t4": ("4. 가격과 확률", [("u2-outs", "아웃"), ("u1-potMath", "팟 계산"), ("u2-equitySense", "이길 확률"),
                              ("u2-potOdds", "팟 오즈"), ("u2-callFold", "콜/폴드"), ("u2-boss", "선택 도전")]),
        "t5": ("5. 더 깊이 (선택)", [("u1-combos", "가능한 두 장 조합"), ("u3-notation", "핸드 줄임 표기"),
                                 ("u2-evCall", "콜의 평균 손익")]),
    ]

    private func runUnit(_ unit: String) {
        guard let spec = Self.units[unit] else { return }
        let only = ProcessInfo.processInfo.environment["GT_AUDIT_NODES"].flatMap {
            $0.isEmpty ? nil : $0.split(separator: ",").map(String.init)
        }
        for (id, title) in spec.nodes where only == nil || only!.contains(id) {
            var memory: [String: QMemory] = [:]
            for pass in [Pass.first, Pass.second] {
                // Every node runs on a fresh store at the same point on the path, so its
                // session seed, and with it every question, is the same in both passes.
                launch(pathNode: id)
                XCTAssertTrue(tabs())
                rec.flow("\(id)-\(pass == .first ? "a" : "b")", section: spec.title,
                         title: "\(title) · \(pass == .first ? "첫 번째 풀이" : "두 번째 풀이")",
                         summary: pass == .first
                            ? "배우기 탭 → ‘\(title)’. 따라 배우기의 모든 단계, 함께 풀기, 문제마다 첫 번째 답과 그 결과예요."
                            : "같은 레슨을 같은 문제로 다시 풀어요. 첫 풀이에서 맞힌 문제는 일부러 틀리고, 틀린 문제는 정답을 골라요.",
                         group: id, pass: pass == .first ? "a" : "b")
                if pass == .first { rec.shot("배우기 탭", after: "앱 실행", scroll: false) }
                let row = app.buttons["lesson-\(id)"]
                if pass == .first {
                    // Scroll Learn until the row is on screen, so the shot shows where it sits.
                    var tries = 0
                    while row.exists && !row.isHittable && tries < 10 { rec.nudge(up: true); tries += 1 }
                    rec.shot("배우기 탭 · ‘\(title)’ 위치", after: "앱 실행", scroll: false)
                }
                tap(row, "레슨 ‘\(title)’")
                pause(1.5)
                driveSession(pass: pass, memory: &memory, maxSteps: 90, flowLabel: title)
            }
        }
    }

    // MARK: - session driver (lessons, practice, review, placement)

    enum Pass { case first, second }

    struct QMemory {
        var band: String
        var verdict: String
        var kind: String
    }

    /// Walks a lesson-like session: walkthrough beats, 함께 풀기, graded questions and the
    /// summary. The first pass records every screen and answers with the first choice or
    /// the default value; the second pass records only reveals and aims for the other
    /// outcome for each question.
    private func driveSession(pass: Pass, memory: inout [String: QMemory], maxSteps: Int, flowLabel: String) {
        var steps = 0
        var explainedOnce = false
        var lastKey = ""
        var stuck = 0
        while steps < maxSteps {
            steps += 1
            pause(0.4)
            if isSummary() {
                rec.shot("레슨 요약", after: "마지막 문제의 ‘다음 문제’ 탭")
                for l in ["완료", "다른 개념 고르기", "학습으로 돌아가기", "닫기", "배우기로 돌아가기"] where button(l).exists {
                    tap(button(l), l); pause(1)
                    rec.shot("요약 뒤 화면", after: "‘\(l)’ 탭", scroll: false); break
                }
                return
            }
            let step = anyPrefix("walkthrough-step-")
            if step.exists {
                if pass == .second {
                    let skip = button("건너뛰기")
                    if skip.exists { tap(skip, "건너뛰기"); pause(1); continue }
                }
                let n = step.identifier.replacingOccurrences(of: "walkthrough-step-", with: "")
                let beatKey = "walk-\(n)"
                if beatKey == lastKey { stuck += 1 } else { stuck = 0 }
                lastKey = beatKey
                if stuck > 2 { rec.problem("따라 배우기 \(n)단계에서 넘어가지 못했어요"); return }
                if stuck == 0 {
                    rec.shot("따라 배우기 · \(Int(n).map { $0 + 1 } ?? 0)단계", after: n == "0" ? "레슨 열기" : "‘다음’ 탭")
                }
                let reveal = app.buttons["walkthrough-reveal"]
                if reveal.exists && reveal.isHittable {
                    reveal.tap(); pause()
                    rec.shot("따라 배우기 · \(Int(n).map { $0 + 1 } ?? 0)단계 결과 확인", after: "‘눌러서 확인하기’ 탭")
                }
                if button("이해했어요").exists { tap(button("이해했어요"), "이해했어요") }
                else if button("다음").exists { tap(button("다음"), "다음") }
                else { rec.problem("따라 배우기에 다음 버튼이 없어요") ; return }
                pause(0.6)
                continue
            }
            let progress = anyPrefix("drill-question-")
            if progress.exists {
                let label = progress.label
                let key = label.contains("함께") ? "together" : label
                if anyPrefix("graded-sheet-").exists || anyPrefix("drill-completion-").exists {
                    // A reveal left over (e.g. restored); move on.
                    tap(anyPrefix("drill-completion-"), "다음 문제")
                    continue
                }
                if key == lastKey { stuck += 1 } else { stuck = 0 }
                lastKey = key
                if stuck > 2 { rec.problem("문제 \(key)에서 답을 제출하지 못했어요"); rec.shot("멈춘 문제 \(key)", after: "답 시도"); return }
                let title = key == "together" ? "함께 풀기" : "문제 \(key)"
                if pass == .first && stuck == 0 {
                    rec.shot(title, after: key == "together" ? "따라 배우기의 ‘이해했어요’ 탭" : "이전 문제의 ‘다음 문제’ 탭",
                             group: "q-\(key)", branch: "question")
                    if key == "together" { showHint() }
                    if !explainedOnce, app.buttons["drill-explain"].exists, key != "together" {
                        explainedOnce = true
                        tap(app.buttons["drill-explain"], "개념 설명 ⓘ")
                        pause(1)
                        rec.shot("개념 설명 (ⓘ)", after: "제목 옆 ⓘ 탭")
                        if app.buttons["explain-example"].exists {
                            tap(app.buttons["explain-example"], "예시 보기")
                            pause(1)
                            rec.shot("개념 설명 · 예시", after: "‘예시 보기’ 탭")
                        }
                        if !app.buttons["drill-explain"].isHittable { closeTop("개념 설명") }
                    }
                }
                let prior = memory[key]
                let desc = answer(pass: pass, prior: prior)
                let graded = anyPrefix("graded-sheet-")
                if !graded.waitForExistence(timeout: 6) {
                    if app.alerts.firstMatch.exists || app.sheets.firstMatch.exists {
                        rec.shot("\(title) · 확인 창", after: desc, scroll: false)
                        let keep = button("직접 세기")
                        if keep.exists { keep.tap() } else { app.alerts.buttons.firstMatch.tap() }
                    }
                    continue
                }
                let band = graded.identifier.replacingOccurrences(of: "graded-sheet-", with: "")
                let verdict = verdictText()
                let outcome = band == "spotOn" ? "right" : (band == "close" ? "close" : "wrong")
                rec.shot("\(title) · \(bandName(band))", after: desc, group: "q-\(key)", branch: outcome,
                         extra: ["band": band, "verdict": verdict])
                if pass == .first { memory[key] = QMemory(band: band, verdict: verdict, kind: lastKind) }
                else if let prior, prior.band == band {
                    rec.problem("\(title): 두 번째 풀이도 ‘\(bandName(band))’였어요 (반대 결과를 만들지 못함)")
                }
                let next = anyPrefix("drill-completion-")
                if next.waitForExistence(timeout: 4) {
                    tap(next, "다음 문제")
                } else {
                    rec.problem("\(title): ‘다음 문제’ 버튼이 없어요")
                    return
                }
                pause(0.6)
                continue
            }
            // Session-level screens without a drill: start buttons, occupied-session gate.
            if button("그래도 이 레슨 시작").exists { tap(button("그래도 이 레슨 시작"), "그래도 이 레슨 시작"); continue }
            if button("이 레슨 시작").exists { tap(button("이 레슨 시작"), "이 레슨 시작"); continue }
            if button("문제 풀기").exists {
                rec.shot("개념 소개", after: "따라 배우기를 마친 뒤")
                tap(button("문제 풀기"), "문제 풀기"); continue
            }
            stuck += 1
            if stuck > 6 {
                rec.shot("알 수 없는 화면", after: "대기")
                rec.problem("\(flowLabel): 레슨 화면을 알아보지 못해 멈췄어요")
                return
            }
            pause(1)
        }
    }

    private func isSummary() -> Bool {
        textContaining("목표 안에 들었어요").exists || textContaining("문제를 마쳤어요").exists
            || textContaining("지금 복습할 문제가 없어요").exists
    }

    private func bandName(_ band: String) -> String {
        switch band {
        case "spotOn": "정답"
        case "close": "근접"
        default: "오답"
        }
    }

    private func verdictText() -> String {
        let sheet = anyPrefix("graded-sheet-")
        // Range reads show the answer as its own line; the verdict row only names the compare.
        let truth = sheet.staticTexts.matching(NSPredicate(format: "label BEGINSWITH '정답 상위'")).firstMatch
        if truth.exists { return truth.label }
        let v = sheet.descendants(matching: .any).matching(NSPredicate(
            format: "label CONTAINS '정답' OR label CONTAINS '내 답' OR label CONTAINS '내 선택' OR label CONTAINS '차트'")).firstMatch
        return v.exists ? v.label : ""
    }

    private func showHint() {
        let hint = button("힌트")
        guard hint.exists else { return }
        hint.tap(); pause(1)
        rec.shot("함께 풀기 · 힌트", after: "‘힌트’ 탭", scroll: false)
        let cue = any("guided-hint-cue")
        if cue.exists && cue.isHittable { cue.tap() } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95)).tap()
        }
        pause()
        if any("guided-hint").exists { closeTop("힌트") }
    }

    // MARK: answering

    private var lastKind = ""

    /// Answers the question on screen and returns a description of what was done.
    private func answer(pass: Pass, prior: QMemory?) -> String {
        let sheet = any("answer-sheet")
        _ = sheet.waitForExistence(timeout: 4)
        let wantRight = pass == .second && prior != nil && prior!.band != "spotOn"
        let wantWrong = pass == .second && prior?.band == "spotOn"
        let correct = prior.map { correctSegment($0.verdict) } ?? ""

        let pots = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'pot-answer-'"))
            .allElementsBoundByIndex.filter { $0.exists }
        if !pots.isEmpty {
            lastKind = "potChoice"
            // The answers unlock once every action has been stepped through.
            let next = button("다음 행동")
            var steps = 0
            while next.exists && next.isEnabled && steps < 12 {
                next.tap(); steps += 1; pause(0.4)
                if steps == 3 { rec.shot("행동 넘겨 보기 · \(steps)번째", after: "‘다음 행동’ \(steps)번", scroll: false) }
            }
            if steps > 0 { rec.shot("마지막 행동까지 본 화면", after: "‘다음 행동’ \(steps)번", scroll: false) }
            var pick = pots[0]
            if let c = firstInt(correct), wantRight || wantWrong {
                pick = pots.first { (firstInt($0.label) == c) == wantRight } ?? pots[0]
            }
            let label = pick.label
            tap(pick, label)
            return "‘\(label)’ 선택"
        }
        if sheet.buttons["답 입력"].exists || sheet.buttons.matching(NSPredicate(format: "label BEGINSWITH '답 입력'")).firstMatch.exists
            || sheet.buttons.matching(NSPredicate(format: "label ENDSWITH '장' OR label ENDSWITH '개'")).firstMatch.exists {
            lastKind = "count"
            var value = 5
            if let c = firstInt(correct) {
                if wantRight { value = c } else if wantWrong { value = c + 7 }
            }
            enterCount(value)
            return "숫자 \(value) 입력 후 ‘확인’"
        }
        if sheet.buttons["추정값 늘리기"].exists {
            lastKind = "interval"
            var desc = "기본값 그대로"
            if let c = firstDouble(correct), wantRight || wantWrong {
                let target = wantRight ? c : c + (c > 50 ? -35 : 35)
                desc = moveEstimate(to: target)
                let wider = sheet.buttons["구간 너비 늘리기"]
                if wantRight, wider.exists { for _ in 0..<2 { wider.tap() } }
            }
            tap(sheet.buttons["확인"], "확인")
            return "\(desc) · ‘확인’"
        }
        let start = app.buttons["range-start-medium"]
        if start.exists, start.isHittable { start.tap(); pause(0.5) }
        if sheet.buttons["범위 넓이 늘리기"].exists || sheet.sliders.firstMatch.exists && sheet.buttons["확인"].exists
            && !sheet.buttons["+"].exists {
            lastKind = "rangeRead"
            let choices = choiceButtons(in: sheet)
            var desc = ""
            if let c = firstDouble(correct), wantRight || wantWrong {
                // Right: match the width with no shape chip. Wrong: a width far from it.
                let target = wantRight ? c : (c > 40 ? c - 30 : c + 35)
                let slider = sheet.sliders["범위 넓이"]
                for _ in 0..<80 {
                    guard let v = firstDouble(slider.value as? String ?? "") else { break }
                    if abs(v - target) <= 1 { break }
                    sheet.buttons[v < target ? "범위 넓이 늘리기" : "범위 넓이 줄이기"].tap()
                }
                desc = "범위를 \(slider.value as? String ?? "?")로 맞추고 "
            } else if let first = choices.first { first.tap(); desc = "‘\(first.label)’ 고르고 " }
            tap(sheet.buttons["확인"], "확인")
            return desc + "‘확인’"
        }
        if sheet.buttons["+"].exists && sheet.buttons["\u{2212}"].exists {
            lastKind = "stepper"
            var desc = "기본값 그대로"
            if let c = firstDouble(correct), wantRight || wantWrong {
                let target = wantRight ? c : c + (c > 50 ? -30 : 30)
                desc = moveStepper(to: target, in: sheet)
            }
            tap(sheet.buttons["확인"], "확인")
            return "\(desc) · ‘확인’"
        }
        lastKind = "choice"
        let choices = choiceButtons(in: sheet)
        guard !choices.isEmpty else {
            rec.problem("답 버튼을 찾지 못했어요")
            return "?"
        }
        var pick = choices[0]
        if wantRight {
            if let match = choices.first(where: { choiceMatches($0.label, correct) }) { pick = match }
            else { pick = choices.count > 1 ? choices[1] : choices[0] }
        } else if wantWrong {
            pick = choices.first(where: { !choiceMatches($0.label, correct) }) ?? choices[choices.count > 1 ? 1 : 0]
        }
        let label = pick.label
        pick.tap()
        pause(0.8)
        // Some drills pick first and then confirm.
        if !anyPrefix("graded-sheet-").exists, sheet.buttons["확인"].exists, sheet.buttons["확인"].isEnabled {
            sheet.buttons["확인"].tap()
            return "‘\(label)’ 고르고 ‘확인’"
        }
        return "‘\(label)’ 선택"
    }

    private func choiceButtons(in sheet: XCUIElement) -> [XCUIElement] {
        let controls = ["확인", "답 입력", "입력 완료", "마지막 숫자 지우기", "+", "\u{2212}", "힌트", "다음 문제"]
        return sheet.buttons.allElementsBoundByIndex.filter { b in
            b.exists && !b.label.isEmpty && !controls.contains(b.label)
                && !b.label.hasPrefix("숫자 ") && !b.label.hasSuffix("줄이기") && !b.label.hasSuffix("늘리기")
        }
    }

    /// The part of the verdict that names the right answer.
    private func correctSegment(_ verdict: String) -> String {
        if let r = verdict.range(of: "정답 ") {
            var tail = String(verdict[r.upperBound...])
            if let cut = tail.range(of: ", 내 답과") { tail = String(tail[..<cut.lowerBound]) }
            return tail
        }
        // "heading. 내 선택 X, 차트 Y." — the last clause.
        return verdict.components(separatedBy: ",").last ?? verdict
    }

    private func choiceMatches(_ label: String, _ correct: String) -> Bool {
        let head = label.components(separatedBy: ",").first ?? label
        let words = head.split(separator: " ").map(String.init).filter { $0.count >= 1 }
        guard !words.isEmpty else { return false }
        if correct.contains(head) { return true }
        return words.allSatisfy { correct.contains($0) }
    }

    private func firstInt(_ s: String) -> Int? {
        guard let r = s.range(of: "-?[0-9]+", options: .regularExpression) else { return nil }
        return Int(s[r])
    }

    private func firstDouble(_ s: String) -> Double? {
        guard let r = s.range(of: "-?[0-9]+(\\.[0-9]+)?", options: .regularExpression) else { return nil }
        return Double(s[r])
    }

    private func enterCount(_ value: Int) {
        let sheet = any("answer-sheet")
        let open = sheet.buttons.matching(NSPredicate(format: "label BEGINSWITH '답 입력'")).firstMatch
        if open.exists { open.tap() }
        else if let entry = sheet.buttons.allElementsBoundByIndex.first(where: { $0.label.hasSuffix("장") || $0.label.hasSuffix("개") }) {
            entry.tap()
        }
        pause(0.4)
        for ch in String(max(0, value)) {
            let key = sheet.buttons["숫자 \(ch)"]
            if key.exists { key.tap() }
        }
        if sheet.buttons["입력 완료"].exists { sheet.buttons["입력 완료"].tap() }
        pause(0.3)
        let check = sheet.buttons["확인"]
        if check.exists { check.tap() } else { rec.problem("숫자 입력 뒤 ‘확인’이 없어요") }
    }

    /// Reads the value next to 추정 and taps ± until it reaches `target`.
    private func moveEstimate(to target: Double) -> String {
        let sheet = any("answer-sheet")
        func current() -> Double? {
            let texts = sheet.staticTexts.allElementsBoundByIndex.map(\.label)
            guard let i = texts.firstIndex(of: "추정"), i + 1 < texts.count else { return nil }
            return firstDouble(texts[i + 1])
        }
        guard var now = current() else { return "추정값을 읽지 못함" }
        let up = sheet.buttons["추정값 늘리기"], down = sheet.buttons["추정값 줄이기"]
        var taps = 0
        while taps < 120 {
            if abs(now - target) < 0.6 { break }
            let goingUp = now < target
            (goingUp ? up : down).tap()
            taps += 1
            guard let v = current() else { break }
            if (goingUp && v > target) || (!goingUp && v < target) || v == now { now = v; break }
            now = v
        }
        return "추정값을 \(fmt(now))(으)로 맞춤"
    }

    private func moveStepper(to target: Double, in sheet: XCUIElement) -> String {
        func current() -> Double? {
            let t = sheet.staticTexts.allElementsBoundByIndex.first { $0.label.range(of: "^-?[0-9]+%$", options: .regularExpression) != nil }
            return t.flatMap { firstDouble($0.label) }
        }
        guard var now = current() else { return "값을 읽지 못함" }
        var taps = 0
        while taps < 40, abs(now - target) >= 2.5 {
            sheet.buttons[now < target ? "+" : "\u{2212}"].tap()
            taps += 1
            guard let v = current(), v != now else { break }
            now = v
        }
        return "값을 \(fmt(now))%로 맞춤"
    }

    private func fmt(_ x: Double) -> String {
        abs(x - x.rounded()) < 0.05 ? "\(Int(x.rounded()))" : String(format: "%.1f", x)
    }
}

// MARK: - recorder

/// Writes one directory per flow: `flow.json`, then per step `NNN.json` and the step's
/// scroll frames `NNN-k.png`.
final class AuditRecorder {
    let root: URL
    var app: XCUIApplication!
    private var dir: URL?
    private var step = 0
    private var pendingNotes: [String] = []

    init(root: URL) {
        self.root = root
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    func flow(_ id: String, section: String, title: String, summary: String,
              group: String? = nil, pass: String? = nil) {
        let d = root.appendingPathComponent(id)
        try? FileManager.default.removeItem(at: d)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        dir = d; step = 0; pendingNotes = []
        var info: [String: Any] = ["id": id, "section": section, "title": title, "summary": summary,
                                   "started": Date().timeIntervalSince1970]
        if let group { info["group"] = group }
        if let pass { info["pass"] = pass }
        write(info, to: d.appendingPathComponent("flow.json"))
    }

    /// A note attached to the next captured step.
    func note(_ s: String) { pendingNotes.append(s) }

    /// A finding the crawler noticed on its own (missing control, stuck screen).
    func problem(_ s: String) {
        guard let dir else { return }
        let url = dir.appendingPathComponent("problems.jsonl")
        let line = (try? JSONSerialization.data(withJSONObject: ["step": step, "text": s])) ?? Data()
        if let h = try? FileHandle(forWritingTo: url) {
            h.seekToEndOfFile(); h.write(line); h.write("\n".data(using: .utf8)!); try? h.close()
        } else {
            try? (line + "\n".data(using: .utf8)!).write(to: url)
        }
    }

    func shot(_ title: String, after action: String, note: String? = nil,
              group: String? = nil, branch: String? = nil, scroll: Bool = true,
              extra: [String: Any] = [:]) {
        guard let dir else { return }
        step += 1
        usleep(450_000)
        let name = String(format: "%03d", step)
        let frames = captureFrames(scroll: scroll)
        var files: [String] = []
        for (i, png) in frames.enumerated() {
            let f = "\(name)-\(i).png"
            try? png.write(to: dir.appendingPathComponent(f))
            files.append(f)
        }
        let (controls, texts) = inventory()
        var entry: [String: Any] = ["step": step, "title": title, "action": action, "shots": files,
                                    "controls": controls, "texts": texts]
        var notes = pendingNotes
        if let note { notes.append(note) }
        if !notes.isEmpty { entry["notes"] = notes }
        pendingNotes = []
        if let group { entry["group"] = group }
        if let branch { entry["branch"] = branch }
        for (k, v) in extra { entry[k] = v }
        write(entry, to: dir.appendingPathComponent("\(name).json"))
    }

    // MARK: scrolling

    private var scrolled = 0

    func nudge(up: Bool) {
        guard let sv = mainScrollView() else { return }
        drag(sv, up: up)
    }

    func scrollToTop() {
        guard let sv = mainScrollView() else { return }
        for _ in 0..<10 {
            let before = XCUIScreen.main.screenshot().pngRepresentation
            drag(sv, up: false, fast: true)
            if XCUIScreen.main.screenshot().pngRepresentation == before { break }
        }
    }

    private func captureFrames(scroll: Bool) -> [Data] {
        var frames = [XCUIScreen.main.screenshot().pngRepresentation]
        guard scroll, let sv = mainScrollView() else { return frames }
        var moved = 0
        for _ in 0..<12 {
            drag(sv, up: true)
            moved += 1
            let png = XCUIScreen.main.screenshot().pngRepresentation
            if png == frames.last! { moved -= 1; break }
            frames.append(png)
        }
        for _ in 0..<moved { drag(sv, up: false) }
        return frames
    }

    /// Drags by screen position: a scroll view found by index can be gone by the time
    /// the drag looks it up again, which fails the whole test.
    private func drag(_ sv: CGRect, up: Bool, fast: Bool = false) {
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let high = origin.withOffset(CGVector(dx: sv.minX + sv.width * 0.94, dy: sv.minY + sv.height * 0.22))
        let low = origin.withOffset(CGVector(dx: sv.minX + sv.width * 0.94, dy: sv.minY + sv.height * 0.78))
        let (from, to) = up ? (low, high) : (high, low)
        from.press(forDuration: 0.05, thenDragTo: to, withVelocity: fast ? .fast : .slow,
                   thenHoldForDuration: fast ? 0 : 0.3)
        usleep(250_000)
    }

    /// The topmost scroll view that covers a real part of the screen.
    private func mainScrollView() -> CGRect? {
        let screen = app.frame
        var best: CGRect?
        // One snapshot, so every frame comes from the same moment.
        guard let snap = try? app.snapshot() else { return nil }
        func walk(_ e: XCUIElementSnapshot) {
            if e.elementType == .scrollView {
                let r = e.frame.intersection(screen)
                if !r.isNull, r.height > 160, r.width > screen.width * 0.6 { best = r }
            }
            for c in e.children { walk(c) }
        }
        walk(snap)
        return best
    }

    // MARK: inventory

    private func inventory() -> ([[String: Any]], [String]) {
        guard let snap = try? app.snapshot() else { return ([], []) }
        let screen = app.frame
        var controls: [[String: Any]] = []
        var texts: [String] = []
        func walk(_ s: XCUIElementSnapshot) {
            let f = s.frame
            let visible = f.width > 0 && f.height > 0 && f.intersects(screen)
            let type: String? = switch s.elementType {
            case .button: "button"
            case .switch: "switch"
            case .slider: "slider"
            case .textField: "textField"
            case .link: "link"
            case .cell: "cell"
            case .segmentedControl: "segmented"
            case .stepper: "stepper"
            case .disclosureTriangle: "disclosure"
            default: nil
            }
            if visible, let type {
                controls.append(["type": type, "label": s.label, "id": s.identifier,
                                 "enabled": s.isEnabled, "value": (s.value as? String) ?? "",
                                 "x": f.minX, "y": f.minY, "w": f.width, "h": f.height])
            } else if visible, s.elementType == .staticText, !s.label.isEmpty {
                texts.append(s.label)
            }
            for c in s.children { walk(c) }
        }
        walk(snap)
        return (controls, texts)
    }

    private func write(_ obj: [String: Any], to url: URL) {
        if let data = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: url)
        }
    }
}
