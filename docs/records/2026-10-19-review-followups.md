# Independent review follow-ups

- **Date:** 2026-10-19 · **Kind:** verification
- **Asked by / for:** owner; correct review weaknesses while preserving the simple,
  automatic learning flow and useful phone-feedback practice
- **Branch:** `fix/review-followups-20261019`, isolated `glass-table-review-followups`
- **Delivery:** [draft PR #55](https://github.com/mhju0/glass-table/pull/55), remote checks pending
- **Core candidate:** `116187c5835551e90fe0519b0f8b23b8f74c8a7a`
- **Final code candidate:** `66d9c22a3af10ffc2ef85e99122313b63ce7883e` (copy-only delta)
- **Originals:** local `/tmp/gt-followups-*.log` / `.xcresult` and `.uisweep/` captures;
  transient evidence, not a durable archive; no images committed

## Changes and preserved behavior

- R01: graded table blocks further mutation after a failed save until Retry succeeds.
  The first pending decision is retained once; a reset/restore invalidates the old
  screen. Real unwritable-directory tests cover disk bytes, pending export, failed
  retry, successful retry, duplicate suppression, next decision and reload.
- R02: Progress counts reflow at the user's text size instead of shrinking. Large
  counts retain every digit; multi-line numbers are possible on narrow/AX layouts.
- R03: Sharp pot math explicitly folds unmatched callers before the flop and labels
  the street transition. Derived metadata preserves old replay tuple indices,
  questions, money, seeds and grades; 72 frozen spots and old schema-5 saves checked.
- R04: Action Read discloses its assumed opponent and policy before grading. Range
  Read received the analogous correction. Hidden answers stay hidden; grades and
  question generation are unchanged. No new persisted keys or schema changes.
- Owner selected **Casual / 캐주얼형**, replacing Just for fun / 재미로 in setup,
  style guide and policy prose. The casual bot's identity and behavior are unchanged.
- Focused recovery/teaching UI checks now gate PR CI; full nightly remains separate.
  Prior run 39126165724's artifact showed Call tapped near the bottom viewport while
  still on the decision screen. Exact interception cause is unknown. The test helper
  now moves target centers inward and attaches hierarchy/screenshot on failure;
  the Continue assertion remains. Three local iPhone 17 repetitions passed.
- Corrected D53 coverage and release-workflow evidence. `docs/validation.md` keeps
  the owner's concrete feedback practice and adds a candidate/evidence routine plus
  a session guide for someone who knows the rules but rarely plays (owner's choice).

## Observed verification

- Drills after final wording: 568 XCTest + 103 Swift Testing tests passed.
- Core candidate: app unit 112 XCTest + 46 Swift Testing; 23 focused UI tests passed
  on iPhone 12 mini/iOS 26.5 (`gt-followups-green`). Progress scrolling cases passed
  separately; AX postflop helper passed three repetitions on iPhone 17/iOS 26.5.
- Release simulator smoke: two tests passed; binary scan found no demo/test hooks.
  This is not a signed device/distributable check. Engine source is unchanged.
- R01 red-capability check failed at the intended enabled-Continue assertion when
  the guard was temporarily removed; guard restored. That run's finalization was
  stopped after the failure and is not passing evidence.
- Tool tests: 20 passed. `actionlint` and `git diff --check` passed.
- Independent read-only Astra reviews of exact core `116187c` and final code
  `66d9c22`: no blockers; persisted identity, behavior and schema unchanged.
- Final wording: existing setup → per-seat style → style guide → start-hand UI
  interaction passed on iPhone 17/iOS 26.5 (`gt-followups-copy-ui`).
- Inspected 20 initial frames on iPhone 12 mini/iOS 26.5, normal and AX5:
  eight core screens KO/dark before the copy-only change (`20261019-005459-3Jeguj`),
  ten core/setup frames EN/light (`20261019-010346-hyyxtq`), and two setup frames
  KO/dark (`20261019-010731-31DPcp`). Styles fit at normal size; at AX5 the style rows
  are below the initial viewport, so these frames do not establish reachability.
  Some system banners cover headers; those header areas are excluded from inspection.
  These are sampled screens/appearances, not every route or the full four-way matrix.

## Still open

Remote focused CI (pinned iOS 26.2), a fresh full remote UI suite, signed device
Release checks, physical VoiceOver/haptics, minimum iOS 17 and real participant
comprehension are not established by these local checks. No merge, tag, TestFlight
upload, phone install, personal-service write or participant session performed.
