# Local archives and build folders inventory

- **Date:** 2026-10-15 (sources span 2026-07-22 to 2026-10-15)
- **Kind:** verification
- **Originals:** `.archive/2026-10-11-workspace-cleanup/`, `.archive/2026-10-15-worktree-cleanup/`, `.archive/2026-10-15-owner-decisions-cleanup/`, `.build/`, `build/`, `build-device/`, `build-device-release/`, `.playwright-mcp/`, `.superpowers/` (all gitignored, local: deleted, not in git)
- **Asked by / for:** owner, to remove local clutter after keeping one text record

## What it was
Gitignored local folders holding archived worktrees, uncommitted diffs, Xcode DerivedData,
result bundles, screenshot sweeps, UX crawls and phone-install evidence. This record keeps
the parts that are not in git: uncommitted work, install hashes, and what each folder held.

## Findings and decisions
Archived worktrees, 2026-10-11 (7.6 GB; 7 sibling worktrees, `git-history.bundle`, inventory):
- All seven had empty `status.txt`, `staged.patch` and `unstaged.patch`: no uncommitted work.
- Heads (`codex/*` branches no longer exist; commits still in the object store):
  complete-beginner-ux `65faf87`, consistent-opening-b20 `07054d0`, device-feedback-native `7471843`,
  approved-native-refinement `8fe0bdd`, opening-b22 `113e27b` are ancestors of `main`.
  numerical-fixes `64f39fd` (4 commits) and welcome-first `9075533` (1 commit) are not
  ancestors, but `git cherry main` marks every commit patch-equivalent in `main`.
- Bundle (sha256 `276c4b5b…e9e5ef`) heads: the 7 above, feat/audit-fixes-table-focus `33e5384`,
  feat/free-table-direction-a `f3bb670`, feat/sheet-refresh `36d4c51`, feat/spacing-rules `e38914d`,
  main `79ce374`, tag v1.0.0-beta.1 `cad1c6e`: all ancestors of `main` now. Two
  `refs/codex/turn-diffs/checkpoints/*` point to trees (Codex checkpoints), not work.
- `main-before.json`: main checkout then had ` M .gitignore`, ` M docs/agent-handoff.md` and
  untracked `.scratch/`, `.playwright-mcp/` files; no patch of those edits was saved. [Unknown] whether they were later committed verbatim.
- `files/.build` per worktree: xcresults, XCUITest `.mp4` recordings, screenshots, HTML reports, logs
  and signed Release apps (embedded provisioning profiles inside the `.app`s; no standalone signing files).

Archived worktrees, 2026-10-15 (2.3 GB; 25 `/private/tmp/glass-table-*` worktrees):
- Every saved head is contained in a branch that still exists locally (several also on `origin`);
  none are in `main` (diagnostic/fix branches of the a11y Play-table, Menu oracle, settings
  harness and CI-sharding work). Committed work is safe while those branches exist.
- Uncommitted work, found in no branch or commit (`git log --all -S`, `git grep` over all refs):
  - `a11y-live-renderer-local` (branch `diagnostic/a11y-live-renderer-local-20261015` @ `4303e3e`):
    `GlassTable/Sources/DesignSystem/GTActionCaption.swift`, +51 lines. DEBUG-only recorder that,
    when `GT_TEST_STORE_ID` is set, writes caption UILabel font/frame/colour/trait JSON to
    `Documents/caption-live-metadata/` 3 s after update. Diagnostic only.
  - `ui-archive-revalidate` (branch `fix/ui-archive-revalidate-20261015` @ `7ca3492`):
    `.github/workflows/ci.yml` (adds `archive_revalidate` dispatch input, `invalid-options` job,
    `archive-revalidate` job calling `ui-revalidate.yml`) plus untracked
    `.github/workflows/ui-revalidate.yml` (5,608 B), `.github/scripts/ui_archive_revalidate.py`
    (19,421 B), `.github/scripts/tests/test_ui_archive_revalidate.py` (13,573 B).
    UNIQUE: the only copy is `*.uncommitted.diff` + `*.untracked.tar` in this archive. The owner
    later chose the lean CI over the Codex pipeline (handoff), so this is [Inferred] abandoned.
  - `main-checkout-codex-handoff.diff`: Codex's uncommitted `docs/agent-handoff.md` edit for the
    69-finding screenshot UX report; its substance is already in the handoff's 2026-10-15 Codex entry.
- `*.build-evidence.tgz` (16 files): local and CI xcresults, CI artifact downloads, video frames,
  plus DerivedData module caches. `ui-archive-revalidate` tgz holds `.build/auth-replay/*.zip`:
  GitHub Actions artifacts (test logs, enumeration/manifest JSON); no credentials inside.

Owner-decisions cleanup, 2026-10-15 (18 MB): `device-install-b30/` (already in build-history),
`capture.xcresult` and five `.uisweep` runs from the owner-decisions and ux-lesson-gaps worktrees.

Phone installs not yet in `docs/build-history.md` (signed Release, executable SHA256):
- Build 14 (iPhone 12 mini, in-place, progress bytes identical): source `b0c0e35`, `408579477d716cfb073034645cff93a8e855494836484d4e87cebb644080c9ba`.
- Build 16 (iPhone 13 mini, no reset, launch/process verified, no screen check): source `8fe0bdd`, `4f578274529a3c39549595c36f2449b537feaa68523f125a897bbbb04d675a0f`.
- Build 16 (iPhone 12 mini, `native-device/phone-install.json`): `79ab4c1fd04a5f220337779385170755ee94991f90af7b6750554fc7a8c61f3a` [Inferred from the installed app path].
- Build 18 (both phones, installed bundleVersion 18 read back): one binary, `df00d5a4531e2d1b23398202c04bdd295ec9f0f8fdc400f5e16da9a7345fb8b7`; source [Unknown] (worktree head `7471843`).
- Build 19 (iPhone 12 mini): `d644dc1fc665d9f36a7b92657d5ea095a0e401477fb37f78de143663e94de544` (archived copy of the installed app path).
- Build 20: freeze commit `c0ddb76`; superseded interim-802 build 20 binary `1850449f…71aa5` (both already in the build 20 spec).
- Build 21: `ab86ffc50a4258f577ee1f7eb1b696d801735f1b55f5067ee5fe602be8f5fabb`.
- Build 28 (source `170fba1` per build-history): `639df0cf95960d5456109f84ebae8e7d2ac9eaaa81f0414f73e8e645969c3867` (local signed app, CFBundleVersion 28).
- Build 29 (source `5de390c`): `b2076daf34153ab8a08e1dea784ba3f602d0a9681c49580a494df09e46d685d5`.
- Builds 22–26 and 30 hashes are already in build-history; build 27 kept no binary.
- Not installs: `build-device-release` 1.0 (6) `0c03b487…c5a496`, `build-device` Release 1.0 (9)
  `e6356fbd…069fb7`; build-history still has no install evidence for build 9.

Other contents:
- `.build/dd-*` (6 DerivedData dirs, 3.6 GB), `build/`, `build-device/`, `build-device-release/`
  (Jul–Sep DerivedData): regenerable caches.
- `.build/grac-video-2026-10-03/`: raw takes `raw-01..04.mp4`, frames, recording runner for the
  1.0 (14) video. The final video stays in `docs/grac-submission/2026-10-03/`; the submitted
  1.0 (22) video and IPA are in `docs/grac-submission/2026-10-13/`. Raw takes exist only here.
- `.build/direction-a/` (2.9 GB, build 14 steps 1–8, report, install), `native-ux-b16..b20`,
  `native-flow-b16*`, `opening-b22`, `numerical-fixes`, `device-feedback-2026-10-07`: HTML
  reports linked from tracked docs and summarised in other `docs/records/` files.
- `.build/uxaudit-*`, `crawl1..6.xcresult`, `uxaudit-results` (≈4 GB): build-15 UX crawl runs.
- `.build/worktree-archive-20260922.JJYxkt/`: 2026-09-22 sweep/test tarballs; its git anchors
  `1beb9be`, `5e6f379`, `847f21c`, `424d982` are all in `main`.
- `.superpowers/sdd/`: M1 publication task briefs/reports (commits `300f4c1`..`c33effa`, all in
  `main`); `brainstorm/*/content/*.html`: outs-reveal, sheet and home-tone mockups.
  `.superpowers/brainstorm/.last-token` is a local brainstorm-server token (not read).
- `.playwright-mcp/`: 453 page snapshots, 6 console logs, 3 pass-mark JPEGs.

## Outcome
Inventory only; nothing moved or deleted. Unique uncommitted work is limited to the
ui-archive-revalidate CI files and the GTActionCaption diagnostic diff.

## Still open
- Owner: keep or discard the ui-archive-revalidate files (`.archive/2026-10-15-worktree-cleanup/glass-table-ui-archive-revalidate-20261015.{uncommitted.diff,untracked.tar}`) and the live-renderer diff before deleting that folder.
- Deleting `.build/` and `.archive/` breaks links in `docs/build-history.md` and specs to `.build/...` reports and install folders.
- The `diagnostic/*`, `fix/*` and `rollback/*` branches left by the 2026-10-15 cleanup are not in `main`; draft PR #11 holds the Play accessibility fixes.
