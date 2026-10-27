# Codex CI repair attempt (PR #11) and its diagnostic branches

- **Date:** 2026-10-14 (to 2026-10-15)
- **Kind:** report
- **Originals:** draft PR #11 `fix/ci-drills-typecheck-20261014` (29 commits, closed 2026-10-15); about 40 `diagnostic/*`, `fix/a11y-*`, `fix/ci-*`, `fix/settings-harness-*`, `fix/ui-archive-revalidate-*`, `rollback/*` branches (deleted 2026-10-15)
- **Asked by / for:** Codex sessions repairing CI; owner asked Claude on 2026-10-15 to deal with PR #11

## What it was
Codex tried to fix Xcode 26.3 type-check timeouts and make the full UI suite pass on GitHub runners, with a sharded CI (`ci_shards.py`, enumeration fixtures, class timings) and a set of accessibility fixes for the Play and free-table headers.

## Findings and decisions
- CI design (7d53a10, f8d693c, f902734, 2a2bac5, bbdc181, bab5fcb, 35a127d, 77147cb, 7ca3492, b801d8a): replaced by the owner's simpler CI (PR #12: unit gate, nightly UI shards, TestFlight on tag). Merging both would mix two designs.
- Compiler-timeout fixes 51d604f, 5a7b961: already in `main` via 5a4ab34 (identical code).
- Product fixes not in `main`: ed0695f (no accessibility1 cap on the free-table title; caption colour `GT.ink`), be41051 (`GTActionCaption`, a scalable UILabel-backed caption used by `GTActionButton`), 720ded9 (free-table header uses it).
- Measured by Claude on iPhone 17 iOS 26.5, 2026-10-15: `AccessibilityAuditTests/testPlayTable` fails on plain `main` 0/3 (contrast, partial Dynamic Type on '네 명 · 1번째 핸드') and passes 3/3 with the fixes. So the failure is not specific to the 12 mini.
- 811cbce (settings test harness) adds a viewport assertion that fails `testKoreanDarkFeedbackPreferencesPersistAX5` on `main`; left out.
- Codex's last full CI run, 38643221371, failed shard 1 in settings tests (unpushed note 4de7519).
- Decision (Claude, under the owner's "I trust your judgment"): close #11; carry ed0695f, be41051, 720ded9 and test commits 6e21184, 0a87a1b, 6d39b76, 68e4817 to a new PR; delete the experiment branches.
- Branch heads with unique experiment-only commits, for `git show` while GitHub still has them: 0b48fbb, 3c98d96, b528bde, 789b3d0, c2e0a21, 2085adb, c88abc9, a3b4b83, afe0cc1, 3ee0b68, 9cc7f4a, 17399af, b3fb202, 0fc2fc9, 83ab490, 9aa0ac4, 4a787f9, eefe640, 0b85a57, 3234f52, 599ff65, fc07a8f, 54a8f4b, afe4042, d64f43b, db4c8db, 6fb653c, ab36641, 1060c10, b015cdd, fa0de2f, d8ad8af. An uncommitted UI-archive revalidation workflow (`ui-revalidate.yml`, `ui_archive_revalidate.py`) existed only in a local archive and was discarded.

## Outcome
PR #11 closed. Follow-up PR with the product fixes opened from `main` (see the agent handoff).

## Still open
- The settings AX5 language-menu viewport check from 811cbce, if wanted, needs its own fix.
- The full UI suite has still not passed on a GitHub runner.
