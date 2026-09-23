# Combined beginner native release — delivery record

Date: 2026-09-23. Status: implemented, independently reviewed, tested, and
installed for owner testing as **1.0 (4)**. Not an App Store release.

This closes the approved native implementation behind the
[beginner release spec](../../.scratch/beginner-learning-release/spec.md).
The earlier browser mock is design evidence, not native verification.
The [learner-trust audit](2026-09-20-learner-trust-audit.md) and
[pot/appearance delivery](2026-09-23-pot-appearance.md) retain their original scope.

## Delivered behavior

- **Learn / Play / Progress.** Learn incorporates daily review and one suggested
  next activity; there is no compulsory daily popup. Unfinished lesson, round or
  review comes before a new recommendation. The full nine-unit path and all 18
  concepts remain open, including advanced practice. Skipping ahead does not
  mark earlier lessons complete.
- **Optional starting point.** A self-report and three untimed questions, with
  unsure/skip, suggest a place to begin. Everything runs offline; no account is
  required. Placement does not award mastery, answer history or FSRS credit.
- **Korean and English.** The globe menu and settings switch language without
  resetting the current activity. Questions, reveals, walkthroughs, navigation,
  glossary and practice policies have localized presentation. Korean terminology
  remains canonical; technical detail is available without leading every screen.
- **Opponents.** Five fixed vertical choices open a stable details sheet. Casual
  labels replace jargon in the primary UI. Joining and raising are separate
  policy scales, not a single aggression/difficulty ranking. Computer 1/2/3
  identify seats; optional details retain the legacy names and percentages.
- **Charts.** A compact hand summary replaces the oversized empty panel. The
  full overview highlights the learner's cell; the enlarged explorer supports
  two-axis scrolling, individually described cells and return-to-own-hand.
  Large text has larger cells rather than one opaque accessibility label.
- **Learning sessions.** Why/how introductions, worked steps and guided practice
  precede independent work. Five-question practice, course and review preserve
  drafts and committed reveals across relaunch. Resume does not regrade a saved
  answer. Count entry starts empty and accepts direct input; the approved pot
  replay retains three choices and optional arithmetic.
- **Progress.** Exact, near and missed answers remain distinct. Daily and
  non-overlapping seven-day comparisons use matching concept, mode, answer
  format, language and assistance. Optional response time follows accuracy,
  excludes interrupted/resumed/language-switched/assisted attempts, and needs
  enough eligible correct responses. It does not affect mastery or scheduling.
- **Four-player practice.** Four seats start with 100 chips, blinds 1/2, no rake
  or escalating blinds. Stacks carry, dealer moves, and busted players receive
  an explicit 100-chip refill between hands. Legal integer-chip actions,
  short all-ins/reopening, refunds, side pots, ties and odd chips are handled by
  the pure Swift rules model. Factual review shows actions, chips and optional
  revealed cards; it does not manufacture an EV grade. The graded heads-up
  chart/checkdown exercise remains a separate learning mode.
- **Recent habits.** The report uses at most 200 recent hands in 30 days under
  the same policy version. At least 100 hands, five days and 40 voluntary entries
  are required before classification. Wilson intervals must fit supported bands;
  otherwise the result remains mixed/unassigned. It describes this practice
  sample, never personality, bluff intent or professional ability. The eligible
  current window is recomputed after completed hands/when reporting, not cached
  behind a 20-hand refresh counter.

This remains an adult learning app with everyday reading simplicity. There are
no accounts, analytics, ads, purchases, network services or real-money wagering.

## Persistence and rules boundaries

Schema 2 adds session state, daily summaries and bounded recent evidence while
retaining historical records. Migration preserves the original schema-1 bytes
before replacing the live file. Save errors are visible; state is published only
after persistence succeeds. Retry/export and explicit recovery remain available.
Epoch/revision checks reject stale work after reset/import. Imported state is
validated; a fabricated grade, invalid session or replay-inconsistent table is
not accepted as trusted progress. Existing raw recovery files are not deleted.

Table state validates by replay from its seed, starting stacks, policies and
actions. Bots receive only their own cards and public information. The published
practice policy permits at most one bot bet/raise per street, followed by
check/call decisions; this bound applies to bots, not learner action legality.
The final rules correction rejects a raise when every other live player is
already all-in, in both legal-action presentation and state mutation.

## Frozen source and independent review

| Candidate | Scope | Result |
|---|---|---|
| `07424386f733c75dbf7b317dc6b5940909603501` | Combined native implementation | Superseded by corrections below |
| `003f9972d95a2d8c4865977c1c064125372fa81d` | Uncontestable-raise guard, bilingual walkthrough parity, Release privacy verifier and UI fixtures | Independent Class-3 review accepted; no blocking findings |
| `1f5cf3388cbeed6f44c4d805a5352356e7c11916` | Compact equity-card layout and geometry regression test only | Independent narrow review accepted; prior data/rules acceptance remains valid |

The reviewer was read-only. No persistence, grading, timing, seeds or betting
rules changed in the final compact-layout correction. Later documentation and
README asset updates do not alter the installed runtime.

## Verification results

Environment: Xcode 27.0 (27A266a), iOS 27.0 simulators, deployment target iOS 17.
Commands run from the implementation worktree. `MINI` below means the test
destination `platform=iOS Simulator,id=C508B014-F16A-4CC4-86F0-8E356D6D7C22`.

| Gate / command | Result |
|---|---|
| `swift test --package-path GlassTableDrills` | PASS: 348 XCTest + 22 Swift Testing |
| `swift test -c release --package-path GlassTableEngine` | PASS: 91 XCTest; Engine unchanged by subsequent UI work |
| `python3 -m unittest discover -s tools/tests` | PASS: 20 tests |
| `xcodebuild -project GlassTable.xcodeproj -scheme GlassTable -destination "$MINI" -derivedDataPath .build/combined-ui-tests CODE_SIGNING_ALLOWED=NO test` | PASS at `003f997`: 41 model XCTest + 6 appearance Swift Testing + 43 UI tests |
| Focused `test-without-building` after rebuilding `1f5cf33` | PASS: 3 UI tests—compact equity geometry, AX5 submission, saved interval reveal |
| `GlassTableReleaseSmoke`, rebuilt at `1f5cf33`, `test-without-building -only-testing:GlassTableUITests/ReleaseSmokeTests` | PASS: 2 actual Release tests |
| Signed Release build for generic iOS | PASS: version 1.0 (4) |
| `python3 tools/verify_release.py .build/combined-release-device/Build/Products/Release-iphoneos/GlassTable.app` | PASS: bundle/privacy/debug-hook checks |
| `codesign --verify --deep --strict .build/combined-release-device/Build/Products/Release-iphoneos/GlassTable.app` | PASS |
| `git diff --check` | PASS |

UI coverage includes language switching during placement, advanced lesson entry,
draft retention, committed-answer relaunch without duplicate credit, stable
opponent choices, enlarged chart cells/own-hand navigation, four-player
settlement/next-hand relaunch, and existing pot/large-text/review flows.
The new compact test checks that hero, opponent and board regions lie above
the answer sheet before answering. The three focused tests took 73.3 seconds;
the final two Release tests took 55.9 seconds. Simulator launch measurements are
not claimed as physical-device performance.

Local logs are retained under `.build/final-verification/` in
`.build/beginner-native-release/` relative to the primary checkout. XCTest
bundles remain in that worktree's corresponding derived-data directories:

- `combined-ui-tests/Logs/Test/Test-GlassTable-2026.09.23_17-23-54-+0900.xcresult`
- `combined-ui-tests/Logs/Test/Test-GlassTable-2026.09.23_17-55-59-+0900.xcresult`
- `combined-release-smoke/Logs/Test/Test-GlassTableReleaseSmoke-2026.09.23_18-00-15-+0900.xcresult`

An earlier iOS 26.5 full UI run stalled and was not counted as a pass. A fresh
iOS 27 Mini run completed. An initial Release command omitted the test filter
and launched Debug-fixture-dependent tests; it was stopped, then the correctly
filtered actual Release tests passed. Earlier stale UI selectors were corrected,
not hidden by deleting coverage.

## Visual checks

`tools/uisweep.sh` captured 32 screens in both languages, both appearances and
normal/AX5 sizes: **256 Mini frames**. These include all 18 drill entry screens,
Learn, placement, opponents, Play, path, records, settings, glossary, guide,
free practice, chart, and selected reveals. Commands used `GT_SIM='Glass Table
Mini final verification'`, `GT_LANGUAGE=ko|en`, `GT_APPEARANCE=light|dark` and the
default two content sizes. Raw directories are relative to the worktree's
`.uisweep/`:

| Language / appearance | Directory |
|---|---|
| English / Light | `20260923-172354-7iKK29` |
| Korean / Light | `20260923-173614-goCPDR` |
| Korean / Dark | `20260923-174528-IDJecL` |
| English / Dark | `20260923-174529-xuqVtY` |

Inspection covered every normal-size English drill plus representative
navigation, reveal, Korean, dark and AX5 screens; it was not a claim that all
256 frames were individually inspected. The final inspection caught own cards
hidden on the normal Mini equity screen. `1f5cf33` places both hands side by side
above the board; AX retains the scrolling layout. All four corrected normal
captures were inspected, with an AX sample and separate interaction test.
Eight corrected captures live in `20260923-175558-eZFUfe` (EN/light),
`20260923-175757-Or9a7C` (EN/dark), `20260923-175908-mOryjU` (KO/light), and
`20260923-180017-2HNxSZ` (KO/dark).

A larger iPhone 17 sweep (`GT_SIM='iPhone 17' GT_LANGUAGE=en
GT_APPEARANCE=light tools/uisweep.sh --no-build --screen learn --screen play-hand
--screen placement --screen table-chart --screen drill-equity`) captured another
10 normal/AX5 frames in `20260923-180204-gSTSQ4`. Normal Learn/Play/chart/equity
and AX Play/chart were inspected. Scrollable long content need not fit one
frame; UI interactions, not initial screenshots, establish control reachability.

The four refreshed README images are raw seeded screenshots, not personal
user data; [provenance](../readme-assets/README.md) records their sources.

## iPhone installation and preservation

Installed the signed Release app **in place**, with no uninstall or reset, on
the owner's connected iPhone 12 mini, iOS 27. `devicectl` confirmed bundle
`com.michaelju.glasstable`, version **1.0**, build **4**, and a running process.
The reviewed executable SHA-256 is
`187a77d76572a608cd84839169e4f89e3651e8b642342bce23a874d3fa71c9ea`.

Immediately before installation, copied Application Support. After launch,
copied it again and compared every original JSON field other than schemaVersion:

- 9 answer records, 2 concept records, 1 node, first-lesson completion and all
  streak fields were exactly preserved.
- Schema advanced from 1 to 2. The on-device
  `progression.schema-1-37FF1F87-1068-474D-B437-68E9E7F981E3.json` is byte-identical
  to the original 1,290-byte save, SHA-256
  `c662292ec914e6d38f0751daf792019192ddba68b163080ef3a748cf2849816a`.
- The migrated 1,454-byte live save remained byte-identical after relaunch:
  `698ecfcd33d4265f8635a5cdcbbe2fb5e77879f55942128acd80ecadd3f7c93e`.

The combined terminate-and-launch command once returned CoreDevice error 10004;
a separate launch succeeded. The subsequent running-process check and readback
passed. Local before/after/relaunch copies and device JSON receipts remain in
the worktree's `.build/device-combined-*` paths; do not commit private saves.

## Synthetic large-history check

The separate `tools/CapacityProbe` app exercised local decode/save/reload on the
physical Mini in Release. It used synthetic records only and was uninstalled
after measurement; it did not replace or reset the main app's data.

| JSON bytes / synthetic rows | Decode | Save | Reload | Whole-probe peak RSS | Round trip |
|---|---|---|---|---|---|
| 8,652,231 / 36,000 | 0.262 s | 0.213 s | 0.252 s | 171,261,952 bytes | PASS |
| 50,470,311 / 210,000 | 1.510 s | 1.272 s | 1.506 s | 714,473,472 bytes | PASS |

Peak RSS includes multiple decode/save/reload copies, not just the decoder.
Raw results: `.build/capacity-probe/capacity-8-optimized.json` and
`capacity-48-optimized.json` in the implementation worktree. The import limit
is 64 MiB; large histories still cause synchronous save latency. This is a known
limit, not permission to trim old records automatically.

## Remaining gates and handoff

- Owner dogfood and adult-beginner comprehension in both languages; no measured
  learning-efficacy claim follows from automated tests.
- Physical VoiceOver and broader assistive-technology interaction, minimum
  iOS 17 runtime, signed distribution/archive and App Store validation.
- Fresh store-sized assets and final age-rating/territory review for the actual
  current app. Repository screenshots do not update App Store Connect.
- Large-history save latency remains as quantified above. Habit thresholds are
  conservative product rules, not a validated poker-player assessment.

No GitHub push, external publishing, hosted privacy-policy change or App Store
submission occurred in this task. Current-facing docs, tickets and README assets
are updated at delivery; historical handoff text is preserved in
`docs/handoff-archive/2026-09-23-before-combined-release.md`.
