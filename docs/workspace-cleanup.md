# Workspace cleanup — 2026-10-11

Use `/Users/michaelju/Workspace/Projects/glass-table` for all current app work.

Seven sibling folders were temporary Git worktrees created for isolated implementation, audits and device verification. They have been removed after verified preservation. Git now has one active worktree. The current app source remains build 22 at `113e27b`; the installed phone app was not changed by cleanup.

## Preserved archive

[Open archive guide](../.archive/2026-10-11-workspace-cleanup/README.md)

The ignored local `.archive/2026-10-11-workspace-cleanup/` contains full historical file snapshots excluding generated compilation caches, per-file SHA256 manifests, original HEAD/branch/index/status/diffs, and a verified Git-history bundle. All branch refs remain in the main repository, including the two divergent historical branches. Archives are historical snapshots; continue development in the main folder.

| Former folder | Source | History |
|---|---|---|
| glass-table-complete-ux | 65faf87 | Already incorporated |
| glass-table-consistent-opening | 07054d0 | Already incorporated |
| glass-table-device-feedback | 7471843 | Already incorporated |
| glass-table-native-refinement | 8fe0bdd | Already incorporated |
| glass-table-numerical-fixes | 64f39fd | Historical branch retained |
| glass-table-opening-b22 | 113e27b | Same as current build |
| glass-table-welcome-first | 9075533 | Historical branch retained |

## Verification

- All retained files/symlinks copied and hash/target-verified before removing the original worktrees.
- All 519 canonical tracked files and every branch ref were unchanged by folder removal.
- Reports, screenshots, all 82 result bundles, logs, signed app products and dSYMs retained. Only generated Swift/Xcode compilation/index/module caches excluded.
- Seven sibling folders removed; one Git worktree remains. Approximately 5.21 GiB reclaimed after preserving the archive.
- Current [build 22 report](../.build/opening-b22/report/index.html) and [numerical audit report](../.build/numerical-fixes/index.html) stay at their original canonical paths. Their local report servers now run from the main folder.
- Other projects were untouched. No phone data was read, copied or reset.
