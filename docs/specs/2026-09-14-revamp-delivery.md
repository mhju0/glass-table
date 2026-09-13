# Revamp delivery and verification

This is a local candidate for Michael's testing, not an App Store release.

## What changed

The Warm direction is recorded in [DESIGN.md](../../DESIGN.md). The
[research foundation](2026-09-13-revamp-research.md) connects primary learning
research and poker teaching sources to the product decisions, including their
limits. Existing poker generators and published strategy models remain intact.

- Today recommends one next action. Due review is a finite session of up to five concepts.
- The course includes nine units and all eighteen existing practice concepts. Existing unit/node IDs remain stable; MDF is appended.
- Worked examples lead into supported practice and then independent retrieval. Supported answers do not create assessed progress.
- Completed lessons unlock the next lesson independently of score. Per-concept evidence controls proficiency; delayed perfect checkpoint evidence controls mastery. Historical tiers are preserved.
- Assessed answers save on reveal. Closing before Next retains the answer; Next cannot record it twice. Incomplete sessions do not clear lessons.
- Records show counts and observed interval coverage without diagnosing confidence from small samples.
- A start guide introduces poker rules, study habits, model assumptions and further study. Finishing the course is not a professional qualification.
- Screens use readable Korean, one main navigation action, equal-weight answer choices, visible slider adjustments and continuous scrolling at accessibility sizes.

## Try it

Open `GlassTable.xcodeproj` from the revamp checkout after `xcodegen generate`.
Use the GlassTable scheme and an iPhone simulator. The app is Korean-first.

1. From Today, open the start guide, answer its checks and return.
2. Start the first lesson: view the worked example, try supported practice and finish five independent questions.
3. Visit Path and open free practice for an advanced concept without waiting for course unlocks.
4. Choose a Table opponent, start a hand, commit a decision and compare the explanation with the final hand result.
5. In Records, inspect answer counts and next review dates. Close the app immediately after an answer reveal and reopen it to check retention.
6. Try a larger text size. Scroll through the situation, question and controls.
7. Export a backup in Settings; keep your existing progress file before trying imports or reset.

## Verification

Frozen implementation reviewed: `b1f12f9e6c19bc71667ef4eefb52dcf5b619d61f`.
An independent read-only review found two issues, both corrected and re-reviewed:
interrupted shuffled checkpoints now change seed after every saved answer, and
preflop-only summaries no longer claim a measured zero EV loss.

- Drills package: 319 tests passed.
- Engine package, Release configuration: 91 tests passed.
- Screenshot-tool tests: 6 passed.
- Unsigned iPhone Release build: passed; iOS 17 minimum, version 1.0 build 2.
- Release binary: no `GT_DEMO_` or `GT_TEST_STORE_ID` strings; privacy manifest and font license bundled.
- Glass secondary text contrast: 4.67:1; primary CTA text: 8.74:1.
- Normal iPhone 17 sweep: all 64 routes captured in `.uisweep/20260914-003045-JjjL9D`.
- Compact iPhone 12 mini, accessibility XXXL: seven representative routes captured in `.uisweep/20260914-002708-TNMUQx`.
- Rendered images inspected for Today, Path, Records, Settings, start guide, free practice, glossary, review/lesson summaries, supported and independent drills, interval/EV/range reveals, walkthroughs and Table. Long content intentionally scrolls; screenshots alone do not establish control reachability.

- App unit tests on the reviewed implementation: 19 passed, including the interrupted shuffled checkpoint regression.
- Accessibility XXXL interaction tests on iPhone 17: 3 passed (equity submission/reveal, all seven walkthrough beats, preflop fold/summary). Actual large text was visually confirmed in `.uisweep/revamp-final/ax-guided-after-walkthrough.png`.
- Compact iPhone 12 mini XCTest attempts stalled in simulator launch before app interaction, including after a restart. Compact rendering evidence is available; those interaction results are from iPhone 17.

- Complete frozen-candidate simulator run: 19 app unit tests and 12 UI tests passed. The nine normal flows cover finite review, full lesson completion, opponent selection, guide checks, exact/interval/EV answer persistence across relaunch, no assessed credit for guided answers, and no double recording on Next.
- Result bundle: `.build/interaction/Logs/Test/Test-GlassTable-2026.09.14_00-43-07-+0900.xcresult`.
- Final Release build log: `/tmp/glass-table-revamp-release-frozen.log`; final interaction log: `/tmp/glass-table-revamp-frozen-all-tests.log`.
- Full normal sweep was captured before the final seed and summary-label corrections. The final postflop summary is additionally captured in `.uisweep/revamp-final/table-summary.png`; final UI tests assert the corrected preflop nonmeasurement label.
 Screenshot launch
hooks seed synthetic states; interaction tests use actual taps and app relaunches.
Neither replaces physical-device or VoiceOver testing.

## Distribution work after user testing

The unsigned iPhone Release build targets iOS 17 and includes the privacy manifest
and Pretendard license. Debug demo/store overrides are absent from its binary.
This does not establish signing, archive validation, upload or App Review approval.

Remaining: user feedback, signed physical-device testing (including VoiceOver and
older supported iOS), signed archive privacy report, live policy/support URLs,
final store screenshots, current age-rating questionnaire and regional eligibility,
then App Store Connect submission. See [submission preparation](../submission.md).
