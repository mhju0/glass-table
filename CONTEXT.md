# Glass Table — Domain Context

## Current native baseline (2026-09-23)

The combined beginner release is implemented and installed for dogfood as
1.0 (4), not submitted to the App Store. Read the
[delivery and verification record](docs/specs/2026-09-23-beginner-native-release.md)
before reopening its work. Older updates below retain their historical scope.

- Learn / Play / Progress replace the four-tab navigation. Learn recommends
  unfinished work, review or a lesson while all 9 units / 18 concepts stay open.
- The optional offline starting-point check is untimed and skippable. It changes
  recommendations, never grants completion, mastery or review credit.
- Korean and English can be switched in-app without losing the current activity.
  Everyday wording leads; canonical poker terms remain available in context.
- Play is a four-seat integer-chip practice table with public bot policies and
  factual hand reviews. The original graded heads-up exercise remains separate;
  its chart/checkdown assumptions do not grade the four-seat game.
- Schema 2 stores resumable lessons, drafts/reveals, daily practice and recent
  table evidence. Schema-1 records survive migration with a raw backup. Never
  discard old history or recovery bytes to simplify a save/import/reset change.
- No accounts, network service, analytics, ads, purchases or real-money wagering.
  This is an adult learning app with accessible language, not a child audience.

## Revival update (2026-09-14)

The current revamp follows [DESIGN.md](DESIGN.md) and the
[research foundation](docs/specs/2026-09-13-revamp-research.md). The course now
has 9 units and includes all 18 concepts. Review sessions snapshot at most
five due concepts. Lesson completion is separate from per-concept performance
promotion; mixed checkpoints use a balanced seeded order. Guided help is
ungraded. Existing schema-1 progress and historical tiers remain intact.

The September 23 native update adds a beginner pot-math introduction, three/four
player contribution replay and three answer choices. App appearance now follows
System by default, with Light/Dark overrides. For behavior, evidence and remaining
limits, read [the delivery record](docs/specs/2026-09-23-pot-appearance.md).

The older orientation below describes the pre-revival baseline where it
conflicts with the current implementation. Store submission remains after
user testing and final distribution checks.

One page of orientation for anyone (human or agent) about to work in this repo.
Deeper reasoning lives in `docs/decisions.md` (§A–§H) and one spec per shipped
slice under `docs/specs/`.

## What this is

A Korean/English iOS trainer that teaches No-Limit Hold'em from basics to **ranges and EV**.
The thesis is *transparency*: opponents are rule-based archetypes whose
strategies are published in-app, so every grade is computed from declared data
and checkable by the user. Graded learning uses **decide → reveal → grade**;
four-player practice uses **play → factual hand review**, without an EV grade.

## Modules

| Module | Owns | Test posture |
|---|---|---|
| `GlassTableEngine` | Pure poker math: evaluator, equity (exact + fixed-seed MC), hand classes/ranges, Chen scores, board texture, made-hand buckets | Release-config gate (`swift test -c release`), oracle-cross-checked, CI weekly + on engine paths |
| `GlassTableDrills` | Everything decidable without UI: spot generators, grading, archetypes and their policies, defend chart, graded `TableHand`, four-seat `PracticeTableState`, curriculum, FSRS review, calibration, persistence | Fast plain-Swift tests; must never import UIKit/SwiftUI |
| `GlassTable` | Thin SwiftUI app: screens + design system. `.xcodeproj` is **generated** (`xcodegen generate`), never committed | Simulator build + `tools/uisweep.sh` screenshot sweep |

## Vocabulary (use these; the app's Korean is canonical)

- **Concept** — the unit of mastery/review (18 of them), not a drill or node.
- **Node / unit / boss** — the path's structure; a boss is the only route to 숙달.
- **Estimation concept** — answered with a point + 90% interval, Winkler-scored,
  feeds **calibration**: equity sense, EV call, hit frequency, range advantage,
  and action read. Outs and combos are exact-count questions, not interval evidence.
- **Archetype** — casual labels 신중형/선별형/공격형/콜 위주형/매우 공격형 map to
  Nit/TAG/LAG/콜링 스테이션/매니악. Entry and raise habits are separate scales,
  not a single difficulty ladder. The graded heads-up model is defined by VPIP/PFR (§C) and
  a **postflop policy**: bet/call/raise rows over the five **made-hand buckets**
  (노페어 · 드로우 · 약한 페어 · 탑 페어 · 투페어 이상). Deterministic on
  purpose — an observed action *inverts* into the surviving range (narrowing).
  The table's exception is an opponent folding to a preflop 3-bet: the displayed
  count retains the preceding tracked range, not an inferred fold-only range.
- **Checkdown model** — the disclosed grading assumption in the heads-up exercise: after the
  current street settles, no further betting. Exact on the river.
- **EV-loss grade** — a decision priced as `bestEV − chosenEV` in bb; severity
  최선 at zero, 거의 최선 for a positive loss up to 0.5bb, 부정확 through 2.0bb,
  and 실수 above that. Exact and near-best share a progression band, not a claim
  of equal EV. Distinct from the estimation bands 정확/근접/빗나감.
- **Defend chart** — vs an open: 3벳/콜/폴드 bands derived from the opener's
  width (top 0.30× / to 0.75×, by Chen). Chart match/mismatch is not an estimate
  of how many big blinds a decision costs.

## Conventions that bite

- **Zero third-party dependencies.** Also: no `Date.now()`-style nondeterminism
  in generators — everything is seeded (`SplitMix64`), same seed → same spot.
- **Korean copy**: particles are computed (`KO.subject/object/topic/copula`),
  never baked into format strings. Terminology per `docs/glossary.md` and §F.
- **Design system**: neutral adaptive panels, fixed green poker tables and paper
  cards, amber actions. System/Light/Dark use paired semantic ink/surface tokens;
  fixed poker objects retain their own ink. Check both appearances and AX5.
- **Type scaling**: text follows Dynamic Type; a **card face does not** (§H).
  A fixed frame around scaling text is the defect — it truncated every rank to
  "…" at the accessibility sizes and went unseen until the app was swept at
  `content_size accessibility-extra-extra-extra-large`. That sweep is part of
  looking at the app now.
- **Never rank the answer**: at the table and in every drill, the choice buttons
  are visually identical until *selected*. Accent colour marks the kind of money
  a button commits, never which one is correct (§G, amended).
- **Screenshot verification**: captures use `GT_DEMO_*` launch-env fixtures
  (`tools/uisweep.sh`); XCTest UI flows separately exercise real answer entry,
  scrolling and navigation. A captured frame alone does not prove reachability.
- **Grading honesty**: every reveal shows where its number came from; sampled
  numbers say so; simplifications (checkdown, seat-insensitive defense, no
  4-bets) are stated on screen, not smuggled.

## Historical baseline (old main, audited 2026-09-19)

The dated account below predates the research-led revamp. Its screenshot dates
and test counts describe that older branch, not the current nine-unit app.

M1 (five math drills) shipped 2026-07-23; the revamp R1–R5b rebuilt the app as
a course (길, 8 units) plus the 테이블 (graded hands vs archetypes, preflop
through river). A UI review pass on 2026-08-07 followed: the table gained three
fixed zones and a pot-odds strip at the board, its reveal now leads with the
lesson rather than the score, 길 runs on a rail with the *live* node heaviest,
and the last two emoji icons became SF Symbols. The same pass found and fixed a
critical accessibility bug — card ranks truncated to "…" at large text sizes,
which made the app unplayable at exactly those settings (§H). The 2026-08-08/09
performance work made engine hot paths allocation-free, stopped drill screens
and graders from repeating work, and preserved outputs; it did not change the
UI or learning model. The current branch also documents the Xcode 26 requirement
and XcodeGen installation step because `sharedBackgroundVisibility` is compiled
against the newer SDK.

Store submission is paused for dogfood; the age-rating answers need
reassessment before resuming (`docs/submission.md` banner). Screenshots in
`docs/store-assets/` and `docs/readme-assets/` are current as of 2026-08-07;
the later performance-only changes did not alter their UI. On this audit of
`main`, `swift test --package-path GlassTableDrills` passes 316 tests and
`swift test -c release --package-path GlassTableEngine` passes 92 tests.
Known deferred work is listed at the end of each spec's scope-out section.
