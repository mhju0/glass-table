# Tooling and workspace history

- **Date:** 2026-09-04 (to 2026-10-11)
- **Kind:** audit
- **Originals:** `docs/CLAUDE_ENV_INVENTORY.md`, `docs/CLEANUP_AUDIT.md`, `docs/workspace-cleanup.md` (tracked: `git show f5c5e22:<path>`)
- **Asked by / for:** owner; inventory taken when moving the project off Claude Code (09-04), cleanup audit at the takeover (09-05), sibling-folder consolidation (10-11)

## What it was
Three housekeeping documents: an archive of the Claude Code harness around the project (not a migration target), a correctness/performance/tooling cleanup audit on top of takeover PR #3, and a record of removing seven sibling Git worktrees after archiving them.

## Findings and decisions
Claude environment inventory (2026-09-04):
- Only two items were project-critical: the per-project memory files and the repo's `docs/agents/` conventions. Memory was mined into `PROJECT_HANDOFF.md`, `decisions.md` and `ROADMAP.md`. One memory error found: it called `wiring/completeness-pass` unmerged, but it merged as `5e8b73e` on 2026-08-06. Lesson: memory goes stale silently, so keep durable knowledge in the repo.
- Project-relevant leftovers: the no-license rule explains the public, unlicensed repo and per-file copyright headers (D18). `// ponytail:` markers (`HandEvaluator.swift:2`, `OutsSpotGenerator.swift:27`, `CallFold.swift:35`) mean "deliberately simple, measured as enough"; keep them (D06). `includeCoAuthoredBy: false` is why no commit has a co-author trailer. Conventional Commits held in 149 of 155 commits.
- Research provenance from the gitignored `.claude/settings.local.json`: GRAC (grac.or.kr), namu.wiki (terminology, D17) and toss.im (original Toss-inspired design, `8d59189`).
- Synthetic clicks were believed not to reach Simulator content, which is why `tools/uisweep.sh` uses `GT_DEMO_*` hooks. `PROJECT_HANDOFF.md` §9 later called that claim stale (native interaction worked on 2026-09-05).
- The mattpocock-skills plugin (installed 2026-08-06, after the revamp) left `CONTEXT.md` and the `.scratch/<slug>/spec.md` layout; `docs/adr/` was never created at that time. The GitHub MCP plugin failed to authenticate; all GitHub work used the `gh` CLI. No project-scoped MCP servers, hooks, slash commands or custom agents existed; no Claude-side env vars.
- Gitignored residue: `.superpowers/sdd/` (23 M1-submission files, obsolete) and `.superpowers/brainstorm/` (19 HTML mockups, the only record of rejected visual directions, including `r3-painting.html` for 정확히 칠하기). Advice: skim before deleting.
- Do not port hooks, status line, allowlists, skill overrides or behavioural instructions to another toolchain.

Cleanup audit (2026-09-05, baseline `61f0b51`, head of PR #3):
- Correctness: streak credit before FSRS removes a concept from the due queue; boss asks every concept before promotion; table deals only seats where hero acts after the opener on every street (old code produced 65 invalid deals in 160 seeded hands). D44 records the contract; no schema change.
- Stable questions: node seed frozen at session entry; range-advantage equity cleared on advance and cancelled computations ignored.
- Deleted unused M1 generic session, grading protocol, per-drill writer and their tests; kept the five-file legacy decoder, tested with real JSON. Free play saves once per answer instead of twice.
- Performance (arm64, Xcode 26.6 / Swift 6.3.3, release, median of five): plain range 109.68 to 4.68 us/op; shaped range 152.10 to 12.32; river option pricing 540.53 to 376.01. All 1,616 width/tendency combinations identical; river EV lists byte-identical; no sample count, seed or threshold reduced.
- Tooling: uisweep builds this checkout, rejects stale `--no-build`, creates/deletes its own simulator, fresh container per capture, bounded startup with one restart; six failure-path tests. CI runs the release engine gate on engine PRs and tests the sweep tool. Benchmark commands: `swift run -c release --package-path GlassTableDrills DrillBenchmarks [--snapshot]`, `python3 -m unittest discover -s tools/tests`.
- Verification: 311 drill, 91 release engine, 12 app and six sweep-tool tests passed.
- Deliberately avoided: store submission, age-rating/legal calls, schema changes, poker-policy or sampling changes. Profile on a real device before adding caches or rewriting the evaluator.

Workspace cleanup (2026-10-11, commit `b83d8ff`):
- Seven sibling worktrees archived then removed: `glass-table-complete-ux` (`65faf87`), `-consistent-opening` (`07054d0`), `-device-feedback` (`7471843`), `-native-refinement` (`8fe0bdd`), `-opening-b22` (`113e27b`, same as build 22) were incorporated; `-numerical-fixes` (`64f39fd`) and `-welcome-first` (`9075533`) remain as historical branches.
- Archive: ignored local `.archive/2026-10-11-workspace-cleanup/` with file snapshots, per-file SHA256 manifests, HEAD/branch/index/status/diffs, a verified all-ref Git bundle, all 82 xcresult bundles, signed apps and dSYMs (compilation caches excluded). All 519 tracked files and every branch ref unchanged; about 5.21 GiB reclaimed. All work continues in the single canonical `glass-table` folder.

## Outcome
Inventory archived without porting anything. Cleanup fixes merged after PR #3 (commits `3667f04`, `82ca759`). One Git worktree remains after 2026-10-11.

## Still open
- `.archive/`, `.superpowers/` and `.build/` were deleted on 2026-10-15 at the owner's request after `2026-10-15-local-archives.md` captured what they held.
- Bot usefulness and EV-loss thresholds were left for real-play evidence before MDF's full slice.
