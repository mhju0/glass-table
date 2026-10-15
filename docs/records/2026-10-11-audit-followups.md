# Build 22 audit follow-ups: decision map

- **Date:** 2026-10-11 (to 2026-10-13)
- **Kind:** audit
- **Originals:** `.scratch/audit-followups-2026-10-11/` (`map.md`, `issues/01-15`, `evidence/*.jpg`, `evidence/ui-tests-*.txt`) (tracked: `git show f5c5e22:<path>`)
- **Asked by / for:** owner, following up the build 22 complete audit and its before/after page (claude.ai artifacts). Owner set the mode on 2026-10-11: investigate items one at a time, record each decision, implement everything together at the end; the next report must use larger screenshots.

## What it was
Fifteen research issues raised by the build 22 audit, each with findings, options, a recommendation and an owner decision, plus a running decision map (24 entries). Evidence sheets were real renders from throwaway copies of HEAD (repo untouched) or `tools/uisweep.sh` sweeps.

## Findings and decisions
Map decisions (owner unless noted). Issue numbers in brackets.
1. 2026-10-11: all "after" changes in `2c6047b` and `cbeadfe` approved "for now".
2. [01] Line parity: KO and EN may differ by up to one line; no hand-placed breaks (those caused the reported bad breaks); add a one-line-tolerance test; full EN sweep at both text sizes before the final pass. Why: at normal size only 3 opening-guide places differed by one line (content moved ~24 pt, nothing clipped, dock pinned); every body-text screen scrolls; ~20 single-line labels shrink/truncate rather than break. Relaxes the 2026-09-24 equal-line-count rule in DESIGN.md.
3. [02] Free table empty space: option 2. Keep the fixed dock (`GTStableDockLayout` sizes to the tallest state, so "your turn" had ~200 pt of nothing), grow the felt and shared cards into the ~90 pt band, show amount to call and pot in the blank "your turn" area. Option 3 (variable dock height) rejected because table and buttons would move on every state change. Rough split was table 39%, band 8%, dock 38%.
4. [03] Seats at 2-3 players: option 2, no change; learner stays bottom-right at every size for consistency. Agent had recommended centring (option 1); mocks kept.
5. [04] Graded table: variant B. Keep the graded table's layout and large cards, put it on the free table's green felt (background and text colours only); no seat panels, no pot chips. Owner said it need not share the free table UI and likes the large cards; variant C's after-answer state would need its own design. Satisfies old consistent-learning-table ticket 02 to this extent only.
6. [05] Range advantage reveal: option 2. 59.1% (opener win rate, the answer) and 59.6% (share of opener range in the top made-hand group, `BucketBarView` headline) were different quantities, not a bug. Label answer "오프너 승률", one name per bar group (headline said "페어 이상", legend "투페어 이상" for the same segment), drop the bar headline on this reveal. "선택한 답 55%" in the capture was the sweep's `GT_DEMO_REVEAL=55`.
7. [06] Opening guide card gap: variant A, no change. B, C (agent recommended C) and a "halfway" render were declined.
8. [07] Lesson help: option 1. Keep the in-place "푸는 방법" row, remove the "힌트" pill and its sheet (≥220 pt, covered answer buttons; both were "How to work it out" in EN), lead the row with the pill's one-sentence cue. Cost: 4 UI test files used `guided-hint`. Doubled question wording ("누가 이길까요?" / "누가 이겼나요?") raised, not decided.
9. [15] Bottom panel corner: fixed 34 (nested: control 14 + inset 20) instead of following the display corner (~54 on iPhone 17). Superseded by 17.
10. [08] Opening guide header at largest text: B, stays pinned, header text capped at the first accessibility size (EN "Getting started" wrapped and took ~1/3 of the screen). Skip and progress stay reachable; C (scroll away) rejected.
11. [09] Brand screen Skip: C1. Move under Start as "홀덤을 이미 알아요 · 안내 건너뛰기" / "I already know Hold'em · Skip the guide", faintly outlined button same shape and width as Start; remove top-right Skip. Why: Skip referred to a guide not yet named; C keeps a one-tap exit for experienced players.
12. [10] Opening rules: option 1. Rule stays above each comparison (teach-then-apply; names no winner, so no pre-commit reveal), capped at two short sentences; side facts (ace low, best five of seven, look at your cards with the shared cards) move after answering. Copy table approved; Higher pair rewritten to list every rank down to 2.
13. [11] bb unit: option 1. Keep chips (beginner screens, free table) and bb (advanced drills, graded table, Records, Drills); one sentence "bb는 빅 블라인드 한 개만큼의 칩이에요" (three variants existed in 8+ places), one spelling "빅 블라인드", chip-based study-guide examples in chips, first bb lesson explains once. Converting all to chips rejected as too large.
14. [12] Study guide: 12a cut to the four how-to-study pages and rename (header "시작 안내" clashed with the opening guide); 12b worked example on the explanation page, no "예시 보기" step; 12c keep the iOS 26 floating tab bar, add bottom space. Arrow chains become numbered lists (wording approved: 풀이를 먼저 봐요 / 다른 카드로 직접 풀어요 / 나중에 다시 떠올려요; and 기초와 가격 / 포지션과 레인지 / 보드와 행동 / EV 결정 / 핸드 복기), hanging indent, 12 pt between items (owner chose most of 0/8/12).
15. [13] Store screenshots: option 1. Retake after the final pass: Learn, a lesson question, playing a hand, hand review, Progress; KO and EN; 6.9-inch (iPhone 17 Pro Max sim); raw frames; light. Replace `docs/store-assets/`, fix `CONTEXT.md:143` and `docs/submission.md`. Why: the 2026-08-07 set (`2ef48da`) showed the old four-tab dark app.
16. [14] Stale UI tests: option 1. 48 tests failed identically on unmodified `19f2d10` (iPhone 17); on the 12 mini at `cbeadfe` 41 failed, 7 passed (the 7 were phone-size dependent). Inferred groups: A ~17 wait for a removed "확인" button; B ~5 old opening guide (rebuilt in `7549a32`); C ~8 changed wording/IDs (e.g. "Raise" vs "Raise again", missing `range-start-medium`); D ~11 largest-text measurements that might be real layout faults. Fix A-C, check each D on screen, make phone-dependent and 16 Bilingual tests pass on both phones, gate on the full UI suite on both.
17. 2026-10-12: corners. Owner asked for Alex's seat corner (10) on all corners of every seat, the table, the bottom panel and almost every button; supersedes 9. Pills, playing cards and 20 pt content cards unchanged at the time. (Handoff later: "everything 10", 2026-10-13.)
18. 2026-10-13 [12b]: option A, every explanation page ends with a written "예시 / Example" box; "예시 보기" button and interactive walkthrough step removed from that page.
19. 2026-10-13: raise panel title centred on back arrow and help pill; minus/plus match raise button height (`c66a8d8`).
20. 2026-10-13: owner approved decisions 3, 5 and all other implemented decisions as shown, to be finalized with the new corners (retake store shots, re-run gate).
21. 2026-10-13: study guide keeps "공부 방법 / How learning works" (matches Settings row); 12a's proposed "공부하는 법" not used.
22. 2026-10-13: hand-ranking question option A, "가장 좋은 다섯 장으로 누가 이길까요?" / "Who wins with their best five cards?".
23. 2026-10-13: AX5 two-line English, owner chose shorter text: "Compare hand types first. If they match, compare the ranks." and "The suits are different."
24. 2026-10-13: owner "go with your recommendation for the rest": hand review EN tabs "Help / History / Guide"; at accessibility sizes price and pot put label and value on one line each; push `feat/audit-followups` to origin once green (never `main`).

Issues (all Type research, Status resolved):
- 01 Language line parity: resolved, decision 2.
- 02 Free table empty space: resolved, decision 3.
- 03 Seats at 2-3 players: resolved, no change.
- 04 Graded vs free table look: resolved, variant B.
- 05 Range advantage two numbers: resolved, decision 6.
- 06 Opening guide card gap: resolved, no change.
- 07 Hint entry points: resolved, single "푸는 방법" row.
- 08 Largest-text header: resolved, pinned and capped.
- 09 Brand screen Skip: resolved, C1.
- 10 Rule above opening question: resolved, two-sentence rules.
- 11 bb unit: resolved, keep both units, unify wording.
- 12 Study guide / explanation / tab bar: resolved, 12a-c option 1, later refined by 18 and 21.
- 13 Store screenshots: resolved, retake after final pass.
- 14 Stale UI tests: resolved, repair in final pass.
- 15 Bottom panel corner radius: resolved as 34, then superseded by one radius of 10.

Screenshots proved: parity differences were one line and unclipped; dock "your turn" emptiness; 2/3-seat layouts and graded A/B/C variants; the two range-advantage numbers; header size at AX5; Skip variants; store set out of date.

## Outcome
- All decisions implemented on `feat/audit-followups` except 12b by 2026-10-12; 12b and decisions 18-24 followed. Related commits: `21e7408` (34 corner), `e4fb383` (one radius), `c66a8d8` (raise panel), `89a55c3`, `9a1822f`, `4c191a6` (store screenshots retaken).
- Shipped as build 23 from `dd7637b` (2026-10-13). Gate at `e3ef792`: iPhone 17 iOS 26.5 sim 238 tests, 11 skipped, 0 failed; iPhone 12 mini sim 1 failure (`AccessibilityAuditTests/testPlayTable` contrast finding with no element, unexplained).

## Still open
- Doubled question wording ("누가 이길까요?" vs "누가 이겼나요?") in guided lessons was raised but never decided.
- Map's "Fog" item: whether `main` (then ~104 commits ahead of `origin/main`) should be pushed to a feature branch before the final pass. [Unknown] whether it was settled; later PRs #12-#15 merged to `main`.
- Issue 01 limit: EN scroll reachability at the largest text size was verified only on the opening guide.
