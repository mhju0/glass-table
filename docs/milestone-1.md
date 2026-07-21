# Glass Table — Milestone 1: Math Drills

The first shippable thing. A complete, free, Korean-first **Math Drills** app that already contains the correctness-proven equity core. It proves the entire spine — Swift/SwiftUI app, verified equity engine, the decide→grade loop, App Store + GRAC submission — at minimum risk, *before* any betting-table UI or bots exist.

## Why this is Milestone 1

- **Independently useful.** Daily math reps (outs, pot odds, call/fold) are exactly the kind of thing a serious-minded amateur opens every day. It stands alone.
- **De-risks everything downstream.** Forces the equity core and its correctness harness into existence — the foundation Range Read and Table both stand on.
- **Lowest Korean-rating signal.** A pure calculator/study tool carries the weakest "simulated gambling" signal, so it validates the KR-12/KR-15 self-rating path before the risky betting UI is built.
- **Smallest surface to learn Swift on.** No 8-seat animated table, no bot, no range grid — just the loop, the engine, and clean drill screens.

## Scope — in

- **The decide→grade loop**, in its simplest form: show a spot → user commits → reveal the math + a grade + a one-line "why." Grading uses **estimation-error bands** (정확 / 근접 / 빗나감 — spot-on / close / off) rather than bare 정답/오답, so estimation feels like calibration, not pass/fail (`decisions.md` §D).
- **Five drills** (the bedrock of poker math):
  1. **Outs & rule of 2/4** — count outs, estimate improvement %.
  2. **Pot odds** — given pot/bet/equity, is the call profitable? equity vs required equity.
  3. **Call/fold vs price** — commit to call or fold, graded on the math.
  4. **MDF** — minimum defense frequency: how much must you defend vs a given bet size?
  5. **Blocker counting** — count blockers/combos that remove hands from a range.
- **The equity core** — a **from-scratch Swift** perfect-hash evaluator; enumerate-when-small, fixed-seed-MC-when-large — with its full correctness harness (golden fixtures + reference-oracle cross-check + property tests + determinism).
- **Korean-first UI**, English only for agreed jargon.
- **On-device progress** (local; streaks/accuracy per drill).
- **Deterministic benchmarks, computed on the fly** — a given drill instance always grades the same, with no pre-stored benchmark data model.

## Scope — out (explicitly deferred)

- No 8-seat table, no bots, no archetype ranges, no 13×13 grid.
- No Range Read, Table, Sit In Their Seat, Run It 1000×, or Lab.
- No backend, accounts, IAP, ads, sync.
- No range-vs-range grid painting (that's Range Read / Milestone 2) — blocker counting here is a numeric drill, not the 13×13 grid.

## How we'll know it works — success criteria

1. **The math is provably right.** The equity core passes: golden fixtures (published matchup equities within tolerance), a random-spot batch matching **both** independent reference oracles (eval7 + OMPEval), all property tests (sum-to-100%, monotonicity, enum≈MC within CI), and the determinism test. *This is the hard gate — the drills are worthless without it.*
2. **The loop feels good.** Decide → reveal → grade is fast (reveal <100ms after commit) and the "why" is clear. Validated by the developer's own daily use and a handful of target-audience testers.
3. **It ships.** Accepted on the App Store, and the Korean rating lands on the self-rating track (KR-12/KR-15) — or, if it doesn't, the GRAC direct-review fallback is exercised successfully. Either outcome validates the compliance path for everything after.
4. **Retention smell test.** Target-audience testers voluntarily open it more than once. (Informal; the real retention read comes later, but "would you use this again?" should be yes.)

## Rough shape (detailed plan comes next, via the planning step)

1. Equity core + correctness harness (build and prove *first* — it's the blocking gate).
2. Drill data model + deterministic benchmark storage.
3. The three drill screens + the decide→grade loop UI.
4. Korean localization pass (with the terminology glossary).
5. Local progress/stats.
6. App Store submission + Korean rating.

Per project working style: each step is verified before the next, and progress is checkpointed so an interruption never loses ground. The step-by-step implementation plan is produced separately (planning phase), not here.
