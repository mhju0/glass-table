# NumericalRevealFlowTests: `next.tap()` may miss after the swipe

Status: needs-info

One CI failure, not reproduced: `testKoreanLightReveals`, ui-tests run 39653967431 shard 0
(commit 06e364e), at `XCTAssertTrue(call.waitForExistence(timeout: 10))` right after
`next.tap()`. Every ui-tests run since has passed this test.

Inferred cause, not verified: `app.swipeUp()` can still be decelerating when `next` first
reads hittable, so the tap lands where the button was and the next question never loads.
That is the failure class fixed for two other tests in 071bc8d. The observer log has no
tap detail to confirm it.

Change made (ci/modernize): `next.waitForStableFrame()` before the asserts and the tap.
Local check: the class passed 10 of 10 runs (5 tests x 2 iterations) on iPhone 17 /
iOS 26.5 under Xcode 27.2. It never failed locally before the change either, so this
does not prove the cause.

Close when: 20 more ui-tests runs on `main` pass this test. If it fails again, attach the
shard's `ui-tests.xcresult` and observer artifact here, and record the button frame
before and after the tap.

## Comments
