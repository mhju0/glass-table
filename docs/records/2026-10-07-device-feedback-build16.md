# iPhone 13 mini feedback session on build 16 (C001-C028)

- **Date:** 2026-10-07 (to 2026-10-08)
- **Kind:** research
- **Originals:** `.scratch/device-feedback-2026-10-07/` (`README.md`, `feedback.json`, `independent-research.json`, `native-coverage.md`, `research-C*.md`, `research-final-source-audit.md`, `probes/C009/`, `screenshots/*.jpeg`, `preview-*.png`, `revision-*.png`) (tracked: `git show f5c5e22:<path>`). HTML report `.build/device-feedback-2026-10-07/index.html`: untracked local file, not in git (outside these sources; not covered by this record).
- **Asked by / for:** owner, testing Release 1.0 (16) (source `8fe0bdd`) on an iPhone 13 mini. Workflow set by owner: collect each comment, research in the background, deliver one combined HTML report only after testing ends; no phone update and no native changes during the session.

## What it was
28 owner comments from live device use, each researched against source (read-only), with external references (R1-R13: IES practice guide, NN/g recognition/progressive disclosure/consistency, Apple HIG sheets/dark mode/haptics/labels, PokerStars rankings/position, Duolingo, Signal, W3C timing), a C009 simulator probe, and a later source-coverage check.

## Findings and decisions
Comments (request; key research finding):
- C001 Welcome before the knowledge check: isolated candidate `9075533` (8 UI + 52 model tests passed by worker), not installed during testing.
- C002 More varied opening comparisons (trips, straight, flush): three seven-card spots proposed; keep the first pair comparison.
- C003 Wrong-answer comparison misaligned: `VerdictRow.answers` used a centred `HStack` with mismatched fonts; propose leading-aligned label/value rows.
- C004 Narrator voice: choices may stay first-person ("I win"); app feedback addresses the learner ("You win"); KO "선택한 답", no literal 당신. App-wide source audit listed hotspots.
- C005 Pot guide: define blinds before first use (definition arrived after the worked example), keep a cumulative ledger visible, keep the final total behind "Tap to check".
- C006 Replay Previous/Next partly covered by the answer panel; top Hint opened a near-empty full-height `GuidedHintView`. Two device screenshots confirmed both.
- C007 / C010 Position: raw UTG→...→BB chain in the footer meant nothing to a beginner; even Early/Middle/Late groups were not enough. Proposal: eight-seat map, walk each seat, then postflop order; codes secondary. Owner revision R002: portrait eight-box loop with arrows instead of an oval table.
- C008 Back navigation: separate previous-step, back-to-parent and dismiss; visible Previous in guides; no custom global drag; revisiting a step never re-grades.
- C009 "I understand" at end of help example seemed inert: not reproduced (seeds 0 and 15, EN-dark and KO-light; covered step disabled Next until revealed, finish returned correctly). User's exact seed untested.
- C011-C013 Notation, Chen score, chart reading: K6s shown before "s" is taught (notation lesson was optional "Go deeper"); RFI grades chart membership, not Chen arithmetic, so make score optional; grid has no axis labels, suited is upper-right. Proposed sequence: seats → ranks/suits → notation in context → open/fold → one cell, then axes/legend → chart → decision → optional Chen.
- C014 Lightbulb panel too big; owner suggested a 2-3 s auto-hiding popup. Research: compact reopenable help; essential instruction must not be timed (W3C).
- C015 Labels "Your answer: Raise" / "Correct answer: Fold" (owner's preferred English). Owner revision R001: on a correct answer show one success confirmation, not "I win" and "You win" as two values.
- C016 Defend header crowding (screenshot). C017 show the chart while answering at first: on a graded spot a highlighted chart reveals the answer, so only in ungraded guided steps. C018 Defend answers mostly Fold: generator did not balance actions; curate fold/call/raise in examples, keep graded sampler.
- C019 Cards before math (dropout is the owner's hypothesis, unmeasured). C020 One-tap answers: changing estimate drills to choices changes the measure (Winkler calibration, range overlap), so version and disclose; advanced estimates stay manual.
- C021 Owner corrected: tapping a river card already shows both hands; request became grouping equivalent outcomes, keeping suits and individual cards.
- C022 Different examples on repeats: fixed first-lesson hands; rotation must never change an active saved question.
- C023 Free table tabs renamed "Decision help / Hand history / Table guide". C024 Seat names short EN and three-syllable KO (토마스, 마이클, 알렉스, 클로이 proposed); names derive from seat index, no migration.
- C025 Ten-hand Quick Play recap: `recentHands` (200 records) stores no cards or actions, so a durable archive was needed; no "bluff"/"lucky" labels. C026 Mid-game "End game" / "Start new game" with discard confirmation; close stays pause. C027 Progress grouped into labelled cards; graphics only with real denominators. C028 Compact Settings, haptics toggle; no in-app sound existed, so a sound switch would be a no-op.
Screenshots proved: C003 misalignment, C006 clipped replay row and oversized hint sheet, C016 crowded header; probe frames proved C009 finish/back/close worked in tested seeds.

## Outcome
- Testing ended 2026-10-07; HTML report completed and browser-verified, no native changes in the session.
- Build 18 (2026-10-08) implemented the comments plus a graded 1v1 revamp (`docs/specs/2026-10-07-graded-table-learning.md`). Reconciliation ledger (`docs/audits/2026-10-08-implementation-reconciliation/ledger.json`, head `7471843`): 18 implemented; 10 partial (C002, C004, C007, C008, C010, C011, C013, C017, C021, C022), turned into gaps G01-G08.
- `native-coverage.md` (source-only check at `a0dbf51`) found matching code for most comments, with C008 and C011-C013, C017, C019, C021, C027 partial and a C028 call-site gap.
- Build 19 (2026-10-10) closed the gaps per `docs/specs/2026-10-10-complete-beginner-ux.md`.

## Still open
Nothing tracked here beyond the build 18 gaps; whether every partial item is now fully met was not re-checked in these sources ([Unknown]).
