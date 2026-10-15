# Consistent learning table: spec, teaching plan, prototype and line-parity audit

- **Date:** 2026-09-23 (to 2026-09-26)
- **Kind:** spec notes
- **Originals:** `.scratch/consistent-learning-table/` (`spec.md`, `teaching-plan.md`, `entry-routes.md`, `implementation-plan-03-04.md`, `verification.md`, `issues/01-04`, `prototype/`, `native-audit/`, `evidence/*.png`) (tracked: `git show f5c5e22:<path>`; `native-audit/.build-ocr-lines` is a gitignored compiled helper, not in git)
- **Asked by / for:** owner, after reporting partial-screen lessons, shifting pot layouts, visible totals that reduced pot questions to addition, unexplained positions and combo notation, and inconsistent table visuals between lessons and Play. `DESIGN.md` ("one learning table" and "Bilingual line parity") and `docs/decision-history.md` link here.

## What it was
Owner-approved product decisions for one shared learning table, an all-concept teaching plan, a browser prototype (Current vs Refined), a native Vision-OCR line-parity audit, and four tickets that moved the decisions into the app.

## Findings and decisions
Spec decisions (owner, two clarification rounds, 2026-09-23), relied on by DESIGN.md:
1. Lessons and practice open full-screen with a clear exit; place preserved; small help may stay overlays.
2. One wide, softly rounded green rectangular table (~2:1), seats/cards/pot in predictable places, stable size through question/answer/reveal; at large text surrounding content scrolls rather than squeezes.
3. Pot questions show each action amount but hide calculated per-player totals until a hint or the reveal; teach money added vs raise-to; three choices; no answer before commit.
4. Every mode gets a skippable, reopenable first-use visual worked example; explain positions and notation where introduced; glossary is not a prerequisite.
5. Share the table where seating matters (pot, position, Play); charts and card-only lessons need no table; Play shows face-down opponent cards, folds and central pot chips; never reveal hidden faces.
6. Replay advances on tap with Back and Replay; highlight the acting seat with one short caption; no automatic pacing.
7. Revealing calculated totals before answering marks the attempt as done with help: practice, not unaided accuracy. Replaying actions alone is not help.
8. After answering, question and table stay; answer area becomes a short result, one factual explanation and "Show the steps"; correct and incorrect share one layout.
- Constraint kept: four-seat Play stays separate from graded heads-up; shared visuals must not merge their poker policies or add an EV grade. Preserve progress and recovery bytes; never relabel past attempts as assisted.
Later owner decisions:
- 2026-09-23 panel geometry: one 10 px inset; outside panel corner = table radius - border - inset (32 - 3 - 10 = 19 px); inner corners 10; 2 px border in all states.
- 2026-09-24 Refined table look: dark rail, darker seats, shadows only on cards/chips/dealer, one 26 x 36 card size, slate card backs (owner accepted agent's pick over oxblood, too close to suit red), centred board+pot, fixed-height chip stack that never hints the total, amber only for actions.
- 2026-09-24 bilingual line parity made app-wide: same line count at default size on a 375 pt phone, last line ≥ half full, end widths within 25%, no in-word breaks; larger Dynamic Type only needs no in-word breaks and no clipping (option A). Later relaxed to "up to one line" on 2026-10-11 (see `2026-10-11-audit-followups.md`).
- 2026-09-24 Position intro "rule, not result": example states the rule (before shared cards BB acts last; after them clockwise from SB); button seat outlined only after answering.
- 2026-09-24 digit-Hangul word joiner approved: iOS broke "100 / 핸드", "9% / 를"; `KO.wordJoined` inserts U+2060, applied via a `Text(String)` overload, accessibility text unchanged.
- 2026-09-25 owner chose the full plan for issues 03 and 04. Independent review (2026-09-26) approved with changes: seeds must move after help (else help-abandon-restart replays the same spot for full credit); `SessionEvidence` gains `assisted`; "together" step refuses `markHelpUsed`; summaries count help separately; an assisted answer still counts for the streak (agent decision: help is practice); assisted concept stays due in review.
Teaching plan: per-concept plain KO/EN entry and visual example for all 18 concepts; pot state contract (start with no actions, totals never encoded in chips, help flag survives exit/resume, post-answer steps never change credit). Help as built: only pot counting offers solving help ("합계 보기 / Show totals"), asks first; helped answers get daily "with help" history and streak but no accuracy, miss streak, FSRS, timing or mastery. `entry-routes.md` maps each route (lesson first/returning, practice, review, Records replay, resume, language change, Play, graded, placement) to the test that proves it.
Native line-parity audit (`native-audit/`, what DESIGN.md calls "the check"): `tools/uisweep.sh` at default size on iPhone 12 mini KO then EN; `ocr-lines.swift` (Vision OCR) + `match.py` pair `language.text(ko, en)` strings and report line count, last-line fill, end width; `wrap.py`/`fit.py`/`guidefit.py` fit copy offline with Pretendard. Results: 78 screens, 51 pairs flagged before, 11 after (10 merged-line false positives, 1 Records digit break fixed by the joiner); 75 KO/EN pairs changed in 15 Swift files (`copy-table.json`). Prototype `audit-lines.cjs`: Current 33/43 problems (normal/large), Refined 0/28.
Prototype checks: 8 browser groups passed (hidden 43-chip total absent from text and accessibility, stable table bounds, no overlap, keyboard, reduced motion); axe WCAG 2 A/AA 0 violations; table provisional 328 x 240 (328 x 280 large), less wide than 2:1 for legibility. Screenshots proved stable pot table across answer states, aligned panel corners and Current vs Refined differences.

Issues:
- 01 Review shared prototype: resolved; owner approved as basis for native work 2026-09-24.
- 02 Native shell and shared table: in-progress in file; full-screen covers, pot and Play on `TableSurface` done. Graded `TableView` question later settled as felt-only (build 22 follow-ups, variant B).
- 03 Mode explanations: ready-for-agent in file; [Inferred] implemented in `d548abd` (2026-09-26) per `entry-routes.md`.
- 04 Assisted progress (Class 3): ready-for-agent in file; [Inferred] implemented in `d548abd` with the reviewed plan.

## Outcome
Commits: `eb9fca1` (direction and audit docs), `b928400` (copy fit), `7f16b3b` (word joiner), `e0f07b1` (prototype approval), `1d23978` (full screen), `a8d5b4a` (pot on shared table), `717f265` (Play on shared table), `d548abd` (help as practice, explain on demand). Merged in PR #6 (2026-09-25) and PR #7 (2026-09-26). Device builds 7-11 carried this work.

## Still open
- Issue 02 never formally closed; eight-seat Position strip still used its own renderer as of 2026-09-24. Graded table shares only the felt.
- Measured stable native table bounds and EN/light screenshots for issue 02 were listed as not done.
- Native Dynamic Type, physical VoiceOver and devices were never verified by this work.
