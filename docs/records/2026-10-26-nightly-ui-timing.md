# Nightly dock and glossary test timing

- **Date:** 2026-10-26 · **Kind:** verification
- **Asked by / for:** owner asked to diagnose and fix the failed GitHub UI tests.
- **Evidence:** [PR #65](https://github.com/mhju0/glass-table/pull/65) tracks exact
  candidates, native controls, hosted checks and integration status. Local originals
  use `/tmp/gt-ui-timing-20261026-*` and `/tmp/gt-ui-fix-40229729877/` and may expire.

## Findings and decisions

- Three nightly runs on unchanged `98cad09` failed: `40022323380`, `40127941647`
  and `40229729877` (October 24–26 Korea time). Regular CI `39936655559` passed.
- Latest run: 381 entries, 369 passes, 11 optional audit-crawl skips, one failure.
  Shards 0/2/3 passed; shard 1 failed only the fixed-slot dock test.
- The retained latest shard log proves the dock test found `free-skip-result` at
  17.42s, began tapping at 17.76s, attempted scrolling at 18.67s, then failed lookup.
  Its failure hierarchy already contains `free-next-hand`, `free-review` and
  `free-change-table`: playback reached the result while XCTest targeted its
  temporary replay control. This is stronger evidence than a timeout alone.
- The dock test now observes natural completion using its existing 15s result
  deadline. Slot heights/order, drag cancellation, raise cancellation, fold and
  the final 0.5pt dock-height assertion remain. Replay acceleration is outside
  this geometry test's purpose; it is no longer exercised by this test.
- Run `40022323380` failed the glossary search test's immediate `search.exists`
  assertion after Close. It now waits at most 5s for nonexistence, retaining all
  English/Korean, normal/AX5 search, alias, detail and no-results checks. The
  original cause of that dismissal observation is not uniquely attributed.
- Added the failing dock test to focused PR CI. The complete reference-test
  class, including glossary search, already runs in that gate.
- No app, replay timing, persistence, grading, build number or release changes.

## Verification and outcome

- Unchanged local baseline passed twice on an owned iPhone 17/iOS 26.5 simulator:
  dock 18.837s/16.609s; glossary 106.477s/98.862s. No local stochastic reproduction
  in those two repetitions; the authentic hosted artifact establishes the failure.
- Candidate positives, deliberately omitted-fold/omitted-close failure controls
  and pinned iPhone 17/iOS 26.2 hosted CI results are recorded in PR #65.
- Native testing uses isolated stores and an owned disposable simulator. No phone
  reinstall or progress copy is included. Original nightly runs remain failed.

## Still open

- The full nightly suite is broader than focused CI. Do not treat targeted
  verification as an entire new nightly pass. Earlier isolated launch, reveal and
  guide-position causes remain open (`2026-10-23-comprehensive-ci-closeout.md`).
