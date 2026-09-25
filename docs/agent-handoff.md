# Agent handoff

## Through 2026-09-24 — condensed 2026-09-25

The full entries are in [the 09-25 archive](handoff-archive/2026-09-25-before-autonomous-session.md)
and, for older work, [the 09-23 archive](handoff-archive/2026-09-23-before-combined-release.md).

- Shipped: combined beginner release (Learn / Play / Progress, 18 open concepts,
  optional placement, KO/EN, schema 2); Settings as the fourth tab; full-screen
  activities and the shared `TableSurface` ("Refined" look); bilingual line parity
  rule (`DESIGN.md`) with the native OCR audit in
  `.scratch/consistent-learning-table/native-audit/`; `KO.wordJoined`.
- Device: 2026-09-24 the owner asked for a fresh start. All app data was backed
  up to `.build/device-backups/20260924-before-reset/`, then 1.0 (8) installed
  clean. Restoring means copying those files back. Do not reset phone progress
  otherwise. An earlier worktree cleanup lost ignored evidence under `.build/`;
  archive before removing worktrees.
- Still open:
  - human/distribution gates: physical VoiceOver, minimum iOS 17, novice
    comprehension, signed distribution/Store validation, store screenshots,
    age rating/territories; save latency for very large histories;
  - two Position intro leaks awaiting review (expanded order line, highlighted
    button seat in the intro example table);
  - `KO.wordJoined` does not cover `Text("…")` literals or `Button`/`Label` titles;
  - shared table height (328 × 240/280) is a provisional readability tradeoff;
    the graded heads-up `TableView` and the Position strip keep their own renderers;
  - consistent-learning-table issues 03 (first-use explanations for all modes)
    and 04 (assisted attempts count as practice).
- `.scratch/pot-calculation-redesign/` is untracked on purpose (unrelated).

## 2026-09-25: First run, Play/Learn redesign, 2–4 player tables (autonomous)

- Branch `feat/shared-learning-table`, not pushed. Owner chose on two research
  pages (first run; Play/Learn), then delegated the rest while away. Owner-facing
  record of every decision and why: [`decision-history.md`](decision-history.md).
- Commits: `4aac931` first-run guide; `ff691fe` verdict-tinted sheets; `5b63deb`
  Play home with two mode cards and per-seat table setup; `bda2056` bordered Learn
  rows, starting-point card steps down after the first lesson; `fdf6ca3` pot
  answers in the bottom sheet, app-wide tap-rule audit (`TapCardLabel`,
  `GTDisclosureStyle`); `5e689ca` 2/3/4-player free tables (`seatCount =
  styles.count + 1`, heads-up blind rule, four-seat deal pinned by fingerprint).
- Line-parity audit of all screens changed this session (iPhone 12 mini, KO/EN,
  large): 10 violations found and fixed by copy rewrites (Play, setup, Learn,
  first lesson, three style descriptions); 0 remain. AX5 check found the first
  lesson's ✓/✗ badge covering the card title; at accessibility sizes it now sits
  above the title.
- Exemptions from the tap rule (nav chrome, alerts, Settings rows, recovery
  "새로 시작하기", the guide's inline retrieval questions) are listed in
  `.scratch/first-run-and-play/issues/03-bottom-choice-audit.md`.
- Open: push to `main` held until the owner confirms in their own words; issues
  03/04 above; the setup's segmented control is low-contrast in dark mode.
- Next: owner tries the installed build and confirms the push.

## 2026-09-25: Release research and plan (no code)

- Owner answered the release research page (https://claude.ai/artifact/5uBT6CLXkUkruLoYyxUgjN,
  db docs `release/choices` and `release/followup`). `docs/ROADMAP.md` rewritten as a
  phased release roadmap; the old one moved to `handoff-archive/`. Decisions and reasons are in
  `decision-history.md`.
- Key facts found: frequent simulated gambling = 18+ plus a Korean RCN, infrequent = 13+ with no RCN;
  Apple shows an individual's email on Korean product pages even for free apps; charging
  needs 사업자등록 plus the Paid Apps Agreement; the iPhone SE (375×667) has never been swept;
  only the iOS 26/27 simulator runtimes are installed.
- Open: push to main is still held for the owner's "yes, push". Phase 1 (counsel, Gmail,
  privacy/support pages, enrolment) is owner work.
- Next: the Phase 2 code items, each with a `.scratch/` spec first. Start with the Hold'em
  basics and hand-rankings lesson.

## 2026-09-25: Phase 2 — basics lesson and small fixes

- Hold'em basics lesson shipped (c8abfd0; spec `.scratch/holdem-basics/spec.md`). The
  engine recount showed high card (17.4%) is rarer than one pair and two pair, so the copy
  says "rarer usually ranks higher, except high card" instead of "rarer = stronger".
- Small fixes: table setup's player count uses the app's choice buttons (amber selection;
  the grey system segment was unreadable in dark mode) and stacks at accessibility sizes;
  Settings row "책임감 있게 이용하기 / Play responsibly" opens helplines (Korea 1336,
  US 1-800-GAMBLER, tappable); one sentence on the welcome guide's second page; product
  brief no longer says "free forever".
- Position intro leaks: the native app has no Position intro table yet, so the owner's
  "rule, not result" example is applied when issue 03 builds first-use explanations.
- Open: AGENTS.md still lists "purchases" as excluded; that conflicts with the 1.1 unlock
  and is the owner's call to edit. Next: issues 03 and 04.

## 2026-09-26: Phase 2 — issues 03 and 04 (explanations and help)

- Every graded question has an info button that reopens the skill's explanation and a
  worked example on a different seed; position gets the owner's rule example. The first
  four-seat table explains itself once (info button reopens). Worked examples cover their
  last value until tapped.
- Pot counting offers "Show totals" after a confirm. A helped answer is stored with
  `assisted: true` (omitted otherwise, so old saves read as independent), keeps the streak,
  and skips accuracy, FSRS, timing and mastery. Summaries count help separately.
  Route × feature checklist: `.scratch/consistent-learning-table/entry-routes.md`.
- Decisions recorded in `decision-history.md` (full plan; help keeps the streak).
- Next: step 4 (rating prompt, daily reminder, share card).

## 2026-09-26: Phase 2 — engagement (rating prompt, daily reminder, share card)

- Spec: `.scratch/engagement/spec.md`. Milestones (first unit clear, or a skill mastered)
  are derived from saved `clearedAt` / `masteredAt` against the session's first answer;
  no save-format change. The lesson summary shows a share card (felt image, no chips or
  scores) and asks for a rating on "Back to path", once per app version, never under
  `GT_TEST_STORE_ID`.
- Settings has "매일 알림 / Daily reminder": off by default, asks permission when turned
  on, one repeating local notification (default 20:00), rescheduled on language change.
- Fix: drill and Play table headers stack when the title can't fit beside the new info
  button (AX5 English broke words, e.g. "Positio/n", "Ha/nd").
- Not verified: the real permission dialog, delivery of a notification, the share sheet
  and the review dialog (system UI; unit tests cover the request and the gates).
- Next: step 5 needs the owner (support Gmail, Team ID); then the step 6 matrix.
