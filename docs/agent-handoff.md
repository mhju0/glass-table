# Agent handoff

## 2026-09-23 — Earlier work condensed

The complete prior handoff is preserved in
[the dated archive](handoff-archive/2026-09-23-before-combined-release.md).
It covers shared instructions, revamp/learner-trust fixes, PR #5 publication,
pot-calculation prototypes, the native amber/green appearance update, and
beginner-release mock approvals. Historical pending-native statements there
are superseded by the delivery below, not deleted.

Still open from earlier work: physical VoiceOver, minimum iOS 17, novice
comprehension, signed distribution/Store validation, current store screenshots,
and final age-rating/territory decisions. Installation does not close these.
The unrelated `.scratch/pot-calculation-redesign/` in the primary checkout and
earlier verification worktrees remain preserved. Do not reset phone progress.

## 2026-09-23 — Combined beginner native release

- What changed: Implemented the approved combined scope in runtime `1f5cf33`:
  Learn / Play / Progress, all 9 units / 18 concepts freely open, optional offline
  starting-point check, Korean/English switching, fixed vertical opponent rows
  with a stable habits sheet, accessible chart explorer, resumable five-question
  practice and introductions, comparable progress, and four-player practice with
  factual reviews and evidence-thresholded recent habits. Existing graded
  heads-up learning remains separate. No accounts or network service were added.
- Decisions and why: Recommendations guide without locking lessons. Placement
  grants no mastery. Accuracy precedes optional speed; observed practice habits
  are not personality or skill rankings. Four-seat play does not invent an EV
  grade. Schema 2 preserves old records and original migration bytes.
- Verification: Independent Class-3 review accepted `003f997`, then the final
  compact-equity-only correction at `1f5cf33`. Package, app, UI, Release and
  tooling gates passed. The bilingual/theme/text-size screenshot matrix and
  targeted interaction checks are recorded in the
  [delivery report](specs/2026-09-23-beginner-native-release.md).
- Device: Installed Release 1.0 (4) in place on the owner's iPhone 12 mini.
  All 9 old answers, 2 concept records, 1 node and streak fields survived schema
  migration; the on-device schema-1 backup is byte-identical to the original.
  Migrated progress stayed byte-identical after relaunch. No uninstall or reset.
- Open issues: The human/distribution gates above remain. Very large local
  histories still impose synchronous save latency; measured limits and synthetic
  device benchmarks are documented. Local README assets are refreshed, but no
  GitHub push, hosted-policy update or App Store submission occurred in this task.
- Next step: Collect the owner's feedback on the installed combined flow,
  especially optional placement, lesson freedom, opponent wording and complete
  table hands. Read the delivery report and the prior learner-trust audit before
  repeating investigations. Local raw evidence stays in
  `.build/beginner-native-release/`; do not remove that worktree without archiving it.

## 2026-09-23: Settings in bottom navigation

- Changed: Settings is the far-right fourth tab. Removed top gear/globe shortcuts;
  language lives inside Settings. Root pages reclaim navigation-bar space while
  pushed Back and presented Close controls still work. Fixed Progress summary
  truncation at accessibility sizes during the visual check.
- Why: The owner requested fewer top controls and more space for learning content.
  Existing styling remains; no schema, engine or grading change.
- Verified: 15 interaction tests, final 6 appearance/contrast tests plus AX5 Settings
  navigation, and 2 Release smoke tests passed. Installed 1.0 (5) in place on the
  iPhone 12 mini; progress and schema-1 backup stayed byte-identical after launch.
- Evidence: Implementation `e612e66`; [delivery record](specs/2026-09-23-settings-navigation.md).
  Raw logs, screenshots and phone backups remain in `.build/settings-navigation/`.
- Open issues: Physical VoiceOver/keyboard and minimum-iOS-17 checks remain
  unverified. No push or App Store submission in this task.
- Next step: Owner tests the installed bottom-tab navigation and language setting.
