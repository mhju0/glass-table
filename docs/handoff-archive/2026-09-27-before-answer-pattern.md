# Agent handoff entries archived 2026-09-27

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
