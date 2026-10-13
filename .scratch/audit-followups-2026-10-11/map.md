# Audit follow-ups (build 22) — decision map

Started 2026-10-11. Source: complete audit
(https://claude.ai/code/artifact/1aad40ec-49c6-437d-b7a0-49c73efd6387) and the
before/after page (https://claude.ai/code/artifact/a5751465-7bc4-46e6-bb86-a0716f865e36).

## Notes

- Mode set by the owner on 2026-10-11: investigate the remaining items one at a
  time, record each decision here, and implement everything together at the end.
  Do not implement an item when it is decided.
- The next report must use larger screenshots than the before/after page did.
- Evidence sheets live in `evidence/`.

## Decisions-so-far

1. 2026-10-11 — All "after" changes in commits `2c6047b` and `cbeadfe` are
   approved "for now" by the owner.

2. 2026-10-11 — Line parity: Korean and English may differ by up to one line;
   no hand-placed breaks; add a one-line-tolerance test; full English sweep at
   both text sizes before the final pass. See `issues/01-language-line-parity.md`.
3. 2026-10-11 — Free table empty space: keep the fixed dock, grow the felt and
   shared cards into the band, show amount to call and pot in the blank area of
   "your turn". See `issues/02-free-table-empty-space.md`.
4. 2026-10-11 — Seats at 2–3 players: no change. The learner stays bottom-right
   at every table size. See `issues/03-seats-at-2-3-players.md`.
5. 2026-10-12 — Graded table: variant B, same layout and large cards on the
   green felt; nothing moves. See `issues/04-graded-vs-free-table-look.md`.
6. 2026-10-12 — Range advantage reveal: name the answer "오프너 승률", one name
   per bar group, no bar headline on this reveal. See
   `issues/05-range-advantage-two-numbers.md`.
7. 2026-10-12 — Opening guide card gap: no change (variant A). See
   `issues/06-opening-guide-card-gap.md`.
8. 2026-10-12 — Lesson help: one in-place "푸는 방법" row; remove the "힌트" pill
   and sheet. See `issues/07-hint-entry-points.md`.
9. 2026-10-12 — Bottom panel corner: fixed 34 everywhere (was following the
   phone's corner). See `issues/15-bottom-panel-corner-radius.md`.
10. 2026-10-12 — Opening guide header at large text: stays pinned, text capped
    at the first accessibility size. See `issues/08-largest-text-header.md`.
11. 2026-10-12 — Brand screen Skip: under Start, worded "홀덤을 이미 알아요 · 안내
    건너뛰기", faint outline in Start's shape (C1). See
    `issues/09-brand-screen-skip.md`.
12. 2026-10-12 — Opening rules: keep above the question, two short sentences
    each, side facts after answering. See
    `issues/10-rule-above-opening-question.md`.
13. 2026-10-12 — bb: keep both units; one explanation sentence and spelling;
    chip-based study-guide examples in chips. See `issues/11-bb-unit.md`.
14. 2026-10-12 — Study guide cut to the four how-to-study pages and renamed;
    worked example on the explanation page; bottom space under lists for the
    tab bar; arrow sequences become numbered lists (wording approved, 12 pt
    between items). See
    `issues/12-study-guide-explain-tabbar.md`.
15. 2026-10-12 — Store screenshots: retake after the final pass, five screens,
    Korean and English, 6.9-inch, raw frames, light. See
    `issues/13-store-screenshots.md`.
16. 2026-10-12 — Stale UI tests: repair in the final pass, check the large-text
    measurement failures on screen, full UI suite on both phones as the gate.
    See `issues/14-stale-ui-tests.md`.

17. 2026-10-12 — Corners: owner asked for the corner of Alex's seat (10) on all
    four corners of every seat, and the same roundness on the table, the bottom
    answer panel and "almost" every button. Supersedes decision 9's fixed 34.
    Pills, playing cards and 20 pt content cards unchanged.

18. 2026-10-13 — 12b worked example: owner chose option A. Every topic's
    explanation page ends with a written "예시 / Example" box; the "예시 보기"
    button and the interactive walkthrough step from that page are removed.
19. 2026-10-13 — Raise panel: title centred on the back arrow and help pill;
    minus/plus buttons match the raise button's height (`c66a8d8`).
20. 2026-10-13 — Owner approved decisions 3 and 5 and all other implemented
    decisions as shown in the report, to be finalized with the new corners
    (retake store screenshots, re-run the gate).
21. 2026-10-13 — Study guide name: keep "공부 방법 / How learning works"
    (matches the Settings row). No change.
22. 2026-10-13 — Hand-ranking panel question: owner chose A, "가장 좋은 다섯
    장으로 누가 이길까요?" / "Who wins with their best five cards?".
23. 2026-10-13 — AX5 two-line English texts: owner chose the shorter English
    ("Compare hand types first. If they match, compare the ranks." and "The
    suits are different.").
24. 2026-10-13 — Owner: "go with your recommendation for the rest of the
    items". Hand review English tabs become "Help / History / Guide"; at
    accessibility sizes the price and pot facts put label and value on one
    line each; push `feat/audit-followups` to origin as a feature branch once
    the gate is green (never `main`).

## Implementation status (2026-10-12)

All decisions implemented on `feat/audit-followups` except 12b (worked example
on the explanation page). Gate and report: see the 2026-10-12 entries in
`docs/agent-handoff.md` and https://claude.ai/artifact/JUwpSsMWHvXqjEsmLeHADQ.

## Awaiting the owner's decision

(none)

## Queue (not yet investigated, in order)

(none left)

## Fog

- Whether `main` should be pushed to a feature branch before the final
  implementation pass (it is about 104 commits ahead of `origin/main`).
