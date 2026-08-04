# Glass Table — Domain Context

One page of orientation for anyone (human or agent) about to work in this repo.
Deeper reasoning lives in `docs/decisions.md` (§A–§G) and one spec per shipped
slice under `docs/specs/`.

## What this is

A Korean-first iOS trainer that teaches No-Limit Hold'em in **ranges and EV**.
The thesis is *transparency*: opponents are rule-based archetypes whose
strategies are published in-app, so every grade is computed from declared data
and checkable by the user. Loop everywhere: **decide → reveal → grade**.

## Modules

| Module | Owns | Test posture |
|---|---|---|
| `GlassTableEngine` | Pure poker math: evaluator, equity (exact + fixed-seed MC), hand classes/ranges, Chen scores, board texture, made-hand buckets | Release-config gate (`swift test -c release`), oracle-cross-checked, CI weekly + on engine paths |
| `GlassTableDrills` | Everything decidable without UI: spot generators, grading, archetypes and their pre/postflop policies, the defend chart, `TableHand` (the hand state machine), curriculum, FSRS review, calibration, persistence | Fast plain-Swift tests; must never import UIKit/SwiftUI |
| `GlassTable` | Thin SwiftUI app: screens + design system. `.xcodeproj` is **generated** (`xcodegen generate`), never committed | Simulator build + `tools/uisweep.sh` screenshot sweep |

## Vocabulary (use these; the app's Korean is canonical)

- **Concept** — the unit of mastery/review (18 of them), not a drill or node.
- **Node / unit / boss** — the path's structure; a boss is the only route to 숙달.
- **Estimation concept** — answered with a point + 90% interval, Winkler-scored,
  feeds **calibration**.
- **Archetype** — Nit/TAG/LAG/콜링 스테이션/매니악, defined by VPIP/PFR (§C) and
  a **postflop policy**: bet/call/raise rows over the five **made-hand buckets**
  (노페어 · 드로우 · 약한 페어 · 탑 페어 · 투페어 이상). Deterministic on
  purpose — an observed action *inverts* into the surviving range (narrowing).
- **Checkdown model** — the disclosed grading assumption at the table: after the
  current street settles, no further betting. Exact on the river.
- **EV-loss grade** — a decision priced as `bestEV − chosenEV` in bb; severity
  최선/부정확/실수 at 0.5/2.0bb (§D). Distinct vocabulary from the estimation
  bands 정확/근접/빗나감 — never mix them.
- **Defend chart** — vs an open: 3벳/콜/폴드 bands derived from the opener's
  width (top 0.30× / to 0.75×, by Chen).

## Conventions that bite

- **Zero third-party dependencies.** Also: no `Date.now()`-style nondeterminism
  in generators — everything is seeded (`SplitMix64`), same seed → same spot.
- **Korean copy**: particles are computed (`KO.subject/object/topic/copula`),
  never baked into format strings. Terminology per `docs/glossary.md` and §F.
- **Design system**: felt/glass/paper, one pinned (dark) appearance, opaque
  surfaces, boundaries ≥3:1 measured off screenshots (§G). Ink never flips.
- **Screenshot verification**: synthetic taps don't reach simulator content;
  every screen is reached via `GT_DEMO_*` launch-env hooks (`tools/uisweep.sh`).
- **Grading honesty**: every reveal shows where its number came from; sampled
  numbers say so; simplifications (checkdown, seat-insensitive defense, no
  4-bets) are stated on screen, not smuggled.

## Where things stand (2026-08-04)

M1 (five math drills) shipped 2026-07-23; the revamp R1–R5b rebuilt the app as
a course (길, 8 units) plus the 테이블 (graded hands vs archetypes, preflop
through river). Store submission is paused for dogfood; the age-rating answers
need reassessment before resuming (`docs/submission.md` banner). Known deferred
work is listed at the end of each spec's scope-out section.
