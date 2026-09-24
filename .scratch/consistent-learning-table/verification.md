# Prototype verification, 2026-09-23

Scope: local scripted browser prototype only. No native files, build, device install, deployment, commit, or progress schema changed.

## Checks run

- `node --check .scratch/consistent-learning-table/prototype/app.js`: pass.
- `node --check .scratch/consistent-learning-table/prototype/verify-browser.cjs`: pass.
- `node .scratch/consistent-learning-table/prototype/verify-browser.cjs`: 8 groups passed. The script clicked the intro, Pot Back/Next/Replay, three answer outcomes, Help, Show steps, Exit/resume/reopen, Position, Combos, Play, and outside review controls. It measured unchanged Pot table bounds across replay/answer and identical normal footprints across Pot, Position, and Play. It checked three equal precommit choice styles and no 43-chip aggregate in the prehelp table text or accessibility label. It checked no board overlap with seats or center chips, reachable large-text answers after scrolling, keyboard focus, Escape exit, and reduced motion.
- Browser axe WCAG 2 A/AA: 0 violations on Pot intro, Play folded/board state, and English dark large-text Pot question. Manual focus and scroll checks supplemented it.
- Computed static contrast ratios: felt seat label 8.06:1, felt caption 6.40:1, light text 12.16:1, light secondary text 5.80:1, dark text 12.90:1, dark secondary text 8.62:1, light action label 6.55:1, dark action label 9.31:1. Folded seats retain full text opacity and use a dashed border and explicit Folded wording.
- Representative screenshots in `evidence/`: Pot intro, concealed question, incorrect steps, assisted result, correct result, Position worked example, Combos six pairs, Play fold/board, and English dark large-text Pot and Play.

## Owner review

- Independently inspected Pot question/assisted feedback, English dark large
  feedback, Position and Combos guides, and corrected Play board/fold screenshots.
- Checked 32 combinations of four modes, Korean/English, light/dark and normal/
  large text: no horizontal page or app-container overflow; the three table
  modes share heights of 240 or 280 pixels respectively. This geometry check is
  not a claim of full interaction or visual inspection of every combination.
- Independently exercised final-action help followed by an answer: help retained
  three choices and did not complete the attempt; the answer produced assisted
  feedback. The table stayed in place.
- Earlier review caught a browser-global naming collision, pre-answer position
  cue, premature completion on help, tiny/dimmed seat labels and overlapping Play
  cards. The worker corrected them and reran verification. One owner assertion
  incorrectly rejected empty caption elements; the corrected check tests hidden
  totals instead. These earlier failures are not counted as passing tests.
- Documentation coverage check matched all 18 source concepts to teaching-plan.md.
  `git diff --check` passed. No claim of native implementation or device testing.

## Deliberate limits

The Play hand is a visual script, not a full poker engine or EV grade. Four-seat Position is a teaching fixture; the existing eight-seat native content remains outside this prototype. Browser visited-intro state uses local storage, while an open activity's place is preserved in memory only until page reload. The assisted label demonstrates the proposed rule and does not validate native progression, review credit, or persistence. Browser checks do not substitute for physical VoiceOver or native Dynamic Type testing. The table is a provisional 328 × 240 normal and 328 × 280 large rectangle, wider than tall but less wide than the approximately 2:1 target to keep shared cards and seats legible without overlap.

## Scoped design gate

### Player-panel geometry follow-up

After the owner's screenshot feedback, corrected panel insets and concentric
outside corners, removed the inner rail, and kept border width constant through
active states. Reran all eight browser test groups successfully and inspected
`evidence/aligned-table-corners.png`. Native app unchanged.

### Original prototype gate

This gate applies to the browser review fixture, not a release of the iOS app.

- R-02 PASS: reviewed concise copy and recorded factual status; no new em dashes.
- R-03 PASS: compact screenshots, overlap checks and 32-case overflow check above.
- R-17 PASS: pot arithmetic comes from the repository example; no user metrics.
- R-18 PASS: no testimonials or represented real people.
- R-23 PASS: scope and screen behavior follow the two approved interview rounds.
- R-24 PASS: four mode buttons open the corresponding scripted screen.
- R-25 PASS: measured text contrast and sampled axe checks recorded above.
- R-26 PASS: eight interaction groups exercise the exposed prototype controls.
- R-27 PASS within fixture scope: no async data/loading; incomplete replay disables
  answers, exit returns to launcher, and help/result states are explicit. Native
  storage and error handling remain outside this fixture.
- R-28 PASS: no FAQ.
- R-32 PASS within browser scope: visible focus and keyboard/Escape checks passed.
- R-33 PASS: edits used source patches, not an external source-rewrite script.
- R-34 PASS: both themes exercised; full native theme verification is pending.
- R-35 PASS within prototype scope: served and interacted with in browser; no
  native build or physical-device outcome claimed.
- R-36 PASS: no performance, learning-effectiveness or release-readiness claims.
- R-37 PASS: DESIGN.md and the approved spec provide direction, Energy 1 /
  rhythm 2 / motion 1; the taller proportion is explicitly provisional.
- R-38 PASS: scripted status is visible and documented; no fabricated records.
- R-01 PASS: green identifies the table, amber identifies actions.
- R-04 PASS: cards/chips/dealer marker carry poker meaning; no decorative icons.
- R-06 PASS: existing Pretendard fonts preserve app continuity and Korean text.
- R-07 PASS: no background grid; card-back pattern identifies hidden cards.
- R-08 PASS: navigation direction cues only, no decorative CTA arrows.
- R-09 PASS: no promotional badges.
- R-10 PASS: no backdrop blur.
- R-12 PASS: desktop frame shadow separates review canvas only; mobile removes it.
- R-13 PASS: no glows.
- R-14 PASS: uniform seats reflect equal player roles; card-only combos differ.
- R-19 PASS: no automatic replay or decorative motion loops; reduced motion tested.
- R-22 PASS: illustrations are cards, table and chips used by the exercise.
- Liveliness PASS: the exercise visual is the focal point; felt/cards repeat as
  the identity, amber marks actions, and spacing separates task from feedback.
- C-1 PASS: component purpose and table-size tradeoff documented.
- C-2 PASS: control click-through recorded in the browser script.
- C-3 PASS: no marketing/template sections added.
- C-4 PASS within sampled prototype states: layouts and keyboard checked above;
  native accessibility and persistence explicitly unverified.
- C-5 PASS: source-derived arithmetic and labeled scripted content.
- R-05 PASS: task-driven compositions, not a landing-page template.
- R-11 PASS: cards, table, seats and controls use distinct consistent radii.
- R-15 PASS: controls name actions such as Replay and Show the steps.
- R-16 PASS: copy describes the learner's action rather than marketing benefits.
- R-20 PASS: green felt and paper cards retain Glass Table's existing identity.
- R-21 PASS: functional light/dark review control.
- R-29 PASS: retained felt/amber palette with neutral surfaces and card suit red.
- R-30 PASS: no external product clone or new branded assets.
- R-31 PASS: major choices and their purposes are in teaching-plan.md and README.

### Table material/polish comparison, 2026-09-24

Scope: prototype only. The Design review control switches Current and Refined;
Current markup and styles are unchanged.

- Diagnosis captures found two Current defects: English large Play wraps
  "Folded" mid-word, and the dealer "D" sits off-centre over its disc edge at
  normal and large sizes. Refined fixes both.
- `node --check` passed for `app.js` and `verify-browser.cjs`. The verify script
  now honours `GT_DESIGN=refined`, which saves screenshots as `refined-*.png`.
  All 8 groups passed for Refined and again for Current, including hidden
  totals, fixed table bounds, board overlap and axe WCAG 2 A/AA.
- Refined 32-combination check (mode, language, appearance, text size at
  375 x 812): no page overflow; table heights 240/280; no seat/seat,
  seat/centre-group, seat-text/card overlap; no seat content clipping or
  element outside the felt. Word-level wrapping was inspected in screenshots.
- Contrast on refined surfaces: seat name 11.52:1, folded status 8.76:1, amber
  action caption 9.15:1, pot label 9.61:1, D on disc 9.79:1. Resting seat
  border is 1.51:1 by design; the seat fill carries the boundary and the
  active border is 8.15:1.
- Side-by-side captures: `evidence/compare-*.png` (Play KO light, Play EN dark
  large, Pot KO light, Position EN dark).
- Not verified: native rendering, Dynamic Type, VoiceOver, physical devices.

### Bilingual line parity audit, 2026-09-24

`audit-lines.cjs` renders 31 states (home, every intro, each Pot/Play replay
step, help, all answer outcomes) in Korean and English at 375 x 812. It measures
513 text blocks character by character for line count, last-line fill, end-width
parity and in-word breaks.

| Design / size | Distinct problems | Of which in-word breaks |
|---|---|---|
| Current / normal | 33 | 16 |
| Refined / normal | 0 | 0 |
| Current / large | 43 | 12 |
| Refined / large | 28 (widows and line-count mismatches from reflow) | 0 |

- 31 strings were revised. The most common problems were a lone 요./요? on the
  last line, Korean syllables split across lines, and one-line Korean with
  two-line English.
- Korean now breaks only between words (`word-break: keep-all`). This removed
  every in-word break at both sizes.
- A trial of `text-wrap: pretty` at large size removed nothing and was dropped.
- After the copy changes, all 8 browser groups passed for both designs and the
  32-combination geometry check stayed clean.
- Limits: fitted in Chromium with the bundled Pretendard fonts at one width.
  Native text layout, other widths and Dynamic Type sizes need a native check.
- Evidence: `evidence/lines-*.png` (rows Current/Refined, columns KO/EN).

### Native KO/EN line parity audit, 2026-09-24 (read-only)

Scope: the installed app and Swift sources were not changed. `tools/uisweep.sh`
captured all 78 sweep screens on a disposable iPhone 12 mini clone (375pt,
iOS 26.5), light, default text size (`large`), once in Korean
(`.uisweep/20260924-010513-JOkkzx`) and once in English (`.uisweep/20260924-011743-13XMoA`).
`native-audit/ocr-lines.swift` reads line boxes with Apple Vision OCR;
`native-audit/analyse.py` groups them into blocks, aligns Korean and English
blocks and flags line-count mismatch, last lines under 50% and in-word breaks.
`native-audit/pairs/*.png` are Korean|English side-by-sides for every screen.

- Korean word breaking: no in-word break found. Of 119 Korean wrap points,
  47 matched a spaced source string, 30 involved non-Hangul text and 42 were
  unresolved block merges whose sides are whole words. SwiftUI already wraps
  Korean at 어절 at this size in the captured screens.
- Parity: the tool flagged 119 blocks on 54 of 78 screens (98 line-count,
  32 Korean and 41 English short last lines). Automatic pairing is noisy
  (titles merge with subtitles), so the counts are candidates, not a total.
- Visually confirmed on 10 screens (learn, today, first-lesson-answer, guide,
  potmath-intro, records-empty, drill-position, drill-potodds, table-picker,
  settings); every one has at least one violation. English usually takes the
  extra line. Examples: guide heading 1 vs 2 lines and card 1+2 vs 2+2 with
  "한 / 번의 학습이에요."; "열려 있어요." (31%) on Learn/Today; "of Ks." alone
  in the first-lesson answer; pot intro example wraps "= / 11 chips" in English;
  "몇 / 명이 남았나요?" splits a counting phrase; Settings rows 1 vs 2 lines.
- Word-level breaks inside fixed phrases (빅 / 블라인드, 필요 / 에퀴티, 한 / 번)
  obey the no in-word rule but read poorly; fitting should avoid them too.
- Limits: first viewport only (scrolled content unchecked), light mode, one
  width, one size; dynamic copy covered only in the seeded demo states; OCR
  heuristics. No copy was changed.

### Owner decisions after the native audit, 2026-09-24

- Large text: option A. Lines may reflow at larger Dynamic Type sizes, with no
  in-word breaks and no clipping. Recorded in `DESIGN.md`.
- Position intro answer leak: approved. The refined example now states the rule
  instead of the answer: "예시: 공용 카드 전에는 BB가 마지막이에요. 공용 카드
  뒤에는 SB부터 시계 방향으로 행동해요." / "Example: before shared cards, BB
  acts last. After them, play goes clockwise from SB." The learner derives that
  the button acts last. Both lines fit (KO 2 lines 87%, EN 2 lines 91%);
  refined normal audit 0 problems; 8 browser groups passed.
- Still leaking, not changed pending owner review: the expanded "행동 순서 비교"
  line lists the full order ending in 버튼(D), and the intro table highlights
  the button seat as active in the example.

### Native copy fitting, 2026-09-24 (branch `fix/bilingual-line-parity`, uncommitted)

- The owner asked for fitting directly in Swift, approved via a KO/EN copy table
  and side-by-side screenshots before anything merges or installs.
- 75 KO/EN string pairs changed across 15 Swift files plus 2 UI tests that pin
  copy. `native-audit/copy-table.json` lists before/after text; a local review
  page with 32 KO|EN screen pairs is kept out of git (gitignored `.uisweep/`).
- Learning guide (8 pages, not reachable by `match.py`): offline fitter
  `guidefit.py` reports 0 of 32 violating fields after edits. Pages 1 and 5 are
  in the sweep and render exactly as the fitter predicted.
- Re-sweep (iPhone 12 mini, large, light, KO+EN): 198 pairs located, 11
  flagged. 10 are known merged-line false positives; the remaining one is
  Records 280, caused by the digit/Hangul break below.
- Correction to the earlier audit: iOS does break between a digit or % and
  following Hangul ("최소 100 / 핸드", "내 콜 8 / 을", "상위 9% / 를"). This is
  an in-word break under the owner's rule. It is systemic, not copy-fixable;
  a render-time U+2060 word joiner is proposed and not implemented.
- Tests: Drills `swift test` passed (348 XCTest + 22 Swift Testing). App suite
  46 tests: 44 passed; 2 failed on pinned old copy, were updated, and passed
  on re-run. Not checked: AX5 sizes, dark mode, scrolled content, guide pages
  2-4 and 6-8 on device (offline fit only).

### Digit–Hangul word joiner, 2026-09-24

- Owner approved the fix. `KO.wordJoined` (Drills) inserts U+2060 between an
  ASCII letter, digit, % or ) and a following Hangul syllable. An app-side
  `Text(String)` overload applies it to every non-literal `Text` and keeps the
  original string as the accessibility label. Literals, `Button` and `Label`
  titles are not covered; none showed the break in the audit.
- Overload resolution was checked with a standalone program: `String` values
  and expressions use it; literals, interpolated literals and `verbatim:` do not.
- KO re-capture of records-empty, replay and teach-rangeread-stats: "100핸드",
  "8을" and "9%를" now stay on one line; the joiner renders invisibly.

### Position intro give-aways fixed in the prototype, 2026-09-24

- Owner decision: "rule, not result". `table('position', example)` no longer
  outlines the button seat; it is outlined only after an answer. The expanded
  order line keeps the full order before shared cards and gives only
  "공용 카드 뒤: SB부터 시계 방향" / "After: clockwise from SB" afterwards
  (Current and Refined).
- Checked in Chrome at 375pt, refined design: the intro shows 0 outlined seats
  in KO and EN; practice shows 0 before an answer and the button after one. The
  order line wraps to 2 lines in both languages (last lines 61% KO, 55% EN).
- Not run: `audit-lines.cjs` and `verify-browser.cjs` need `agent-browser`,
  which is not installed on this Mac.
