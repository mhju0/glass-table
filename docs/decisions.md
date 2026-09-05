# Glass Table — Decision Ledger

> **This file was rewritten on 2026-09-04.** It replaces the former options-and-
> recommendations document (sections §1–§10 and §A–§H). That document's *substance* is
> preserved here — every one of its sections has an entry below, tagged with its old
> anchor (e.g. `[was §G]`), so existing cross-references from `CLAUDE.md`, `CONTEXT.md`,
> `README.md`, `product-brief.md`, `risks.md`, `open-questions.md` and the specs still
> land on the reasoning they cite. The verbatim original is in git at commit `4236332`
> (`git show 4236332:docs/decisions.md`).
>
> The change of form is the point: the old document recorded *what we were going to do*.
> This one records **what was decided, what actually happened to it, and what is true
> now** — including the decisions that were implemented and then undone, which is the
> knowledge git alone cannot reconstruct.

## Statuses

| Status | Meaning |
|---|---|
| **ACTIVE** | Decided, implemented, still true. |
| **REVERSED** | Implemented, then deliberately undone. The undoing is the interesting part. |
| **SUPERSEDED** | Still broadly true but replaced by a later, different decision. |
| **DEFERRED** | Decided in principle, deliberately not built yet, with a named trigger. |
| **EXPERIMENTAL** | Shipped but explicitly provisional; expected to change on evidence. |
| **ABANDONED** | Planned, never built, and no longer intended. |
| **UNKNOWN** | Recorded as decided, but the current state cannot be established from repo, git, or memory. |

Founding constraints that shaped everything below: **solo full-time developer, strong in
TS/React, zero shipped Swift, poker beginner, no professional validator; iPhone-only
forever; fully free, on-device, no backend; audience is 20s–30s Korean home-game players.**

---

# 2026-07-21 → 07-22 · Founding decisions

### D01 · Tech stack: SwiftUI + pure-Swift engine, no Rust/C core `[was §1]`
**Status: ACTIVE**

- **Decided:** Write the whole thing in Swift/SwiftUI, including the equity engine. No
  React Native, no Rust/C core behind an FFI.
- **Why:** iPhone-only-forever removes React Native's single real advantage while keeping
  all its costs — and an 8-way Monte Carlo engine cannot live in JS anyway, so RN would
  have forced a native module or WASM regardless. A Rust/C core adds a second toolchain
  and a second unfamiliar language to solve a problem Swift already solves natively;
  portability is worthless on one platform. The custom table, the 13×13 grid and the
  reveal animations are exactly where SwiftUI is strongest. Full-time work made the
  from-zero Swift learning cost affordable.
- **Named revisit trigger:** profiling showing Swift cannot hit the latency budget. It
  never has.
- **Current state:** three Swift modules, **zero third-party runtime dependencies**.
- **Evidence:** `project.yml`, `GlassTableEngine/Package.swift`, `GlassTableDrills/Package.swift`.

### D02 · No backend, ever, for v1 `[was §5]`
**Status: ACTIVE**

- **Decided:** No server. Progress is local. Puzzle sharing (if built) is a file through
  the iOS share sheet. Remote content, if ever wanted, is static JSON on a CDN — still
  not a backend.
- **Why:** free + on-device + no accounts + no purchase ⇒ nothing for a server to do. A
  backend only becomes necessary with sync, accounts, or IAP receipt validation, none of
  which are in scope.
- **Current state:** the app has **zero networking**. This is now also a privacy-label
  claim and part of the Korean legal position, so it has become load-bearing in two more
  places than it started.
- **Evidence:** `docs/privacy-policy.md`; `Progression/ProgressionStore.swift`.

### D03 · No monetization: free forever, no ads, no IAP `[was §6]`
**Status: ACTIVE**

- **Decided:** Fully free. No ads either.
- **Why:** removes an entire subsystem and its risks (receipt validation, accounts,
  paywall seams). Ad networks on a poker app invite gambling-ad policy problems and
  cheapen the study-tool tone that also helps the Korean rating. On-device ⇒ running cost
  ≈ zero ⇒ free-forever is sustainable. A tip jar is YAGNI.
- **Current state:** unchanged. `ITSAppUsesNonExemptEncryption: false`, no StoreKit.

### D04 · Correctness is a hard, milestone-blocking gate `[was §10]`
**Status: ACTIVE**

- **Decided:** the engine ships only behind golden published-matchup vectors
  (AA vs KK ≈ 82.4/17.6, QQ vs AKs ≈ 54/46, QQ vs AKo ≈ 56.3/43.7, AK vs AQ ≈ 74/26,
  77 vs AKo ≈ 55/45), a reference-oracle cross-check on random spots, property tests
  (equities sum to 100 %, monotonicity, enumeration ≈ MC within CI, better hand ranks ≥),
  and a determinism test.
- **Why:** "if the numbers are ever wrong, the product is worthless."
- **Current state:** 92 engine tests, run in **release config**, in CI weekly and on any
  `GlassTableEngine/**` change. Last green 2026-08-30.
- **Evidence:** `.github/workflows/engine-gate.yml`, `GlassTableEngine/Tests/`.

### D05 · Two independent reference oracles (eval7 + OMPEval)
**Status: ABANDONED** — only one was ever wired up.

- **Decided:** cross-check the from-scratch engine against **two** oracles from different
  codebases so bugs cannot correlate — eval7 (Python, MIT) as primary and OMPEval (C++,
  ISC) as the trustworthiness anchor. Ship only if the engine matches *both*.
- **What actually happened:** only eval7 was ever used. A grep of `tools/`, the engine,
  the tests and CI finds **zero references to OMPEval**. `tools/gen_fixtures.py` is
  eval7-only and its own header says "This script IS the oracle."
- **Why it changed:** no record. Most likely the eval7 fixture proved sufficient and the
  C++ toolchain was not worth standing up — but that is inference, not evidence.
- **Current state:** one frozen fixture of 500 spots (`random_spots.json`) checked into
  the repo, cross-checked at 200k MC iterations with tolerance 0.006. The "two
  independent codebases" property the decision was *for* does not exist.
- **Evidence:** `tools/gen_fixtures.py:1-14`, `GlassTableEngine/Tests/GlassTableEngineTests/EquityOracleTests.swift`.

### D06 · Perfect-hash evaluator
**Status: DEFERRED** — a naive evaluator shipped instead, and is still what runs.

- **Decided:** target a phevaluator-style quinary perfect-hash design (~100 KB tables).
  Explicitly reject the two-plus-two 123 MB lookup table as hostile on mobile.
- **What shipped:** a naive 5-card classifier taken best-of-21 for seven cards, flagged
  in its own source header as the deliberate simple version, with the perfect-hash
  rewrite deferred to "Milestone 3 profiling".
- **What changed since:** `e0084ac` (2026-08-08) made the naive path allocation-free —
  `evaluate7` 2.9×, `madeHand` 47×, the whole engine gate 284 s → 128 s. That removed
  most of the pressure to rewrite.
- **Current state:** naive evaluator, fast enough, still the reason the engine gate needs
  release config. No profiling has demanded the rewrite.
- **Evidence:** `GlassTableEngine/Sources/GlassTableEngine/HandEvaluator.swift:2`; commit `e0084ac`.

### D07 · Determinism: compute on the fly, seeded — never store benchmarks `[was §2]`
**Status: ACTIVE**

- **Decided:** enumerate where the space is small (river, turn→river's 44 boards,
  heads-up vs a capped range); fixed-seed Monte Carlo where it is large, with enough
  iterations that the 95 % CI < 0.5 %. Compute during the user's think-time, on a
  background task, started the instant the spot is dealt. Latency budget < 100 ms,
  ceiling 200 ms. **No pre-stored benchmark data model.**
- **Why:** "a benchmark that jitters between runs is a bug users will screenshot." Fixed-
  seed live compute gives determinism without a stored-benchmark schema.
- **Current state:** ACTIVE and now a repo-wide invariant: everything is seeded through
  `SplitMix64`, no `Date.now()`-style nondeterminism exists in any generator, and
  "same seed → same spot" is load-bearing enough that the 2026-08-09 refactors were
  verified by byte-comparing tens of thousands of generated outputs against the previous
  build.
- **Evidence:** `GlassTableEngine/Sources/GlassTableEngine/RNG.swift`; `CONTEXT.md`; commits `0d8d87f`, `7640fef`.

### D08 · 8-max table, screen solved by phase-multiplexing `[was §3]`
**Status: SUPERSEDED** — the shipped table is heads-up; 8-max survives only in the drills.

- **Decided:** keep 8-max (the audience's real home game is 8–9 handed). The three things
  that "must coexist" — 8 seats, the 13×13 grid, live EV — never need to be on screen at
  once, so the decide→reveal loop time-multiplexes them: table-only during the decision,
  grid + EV as a bottom sheet during the reveal. Explicitly rejected cutting to 6-max.
- **What actually shipped (R4-S4, 2026-08-04):** **a heads-up hand.** Villain opens 3bb
  from an earlier seat, hero is in position, blinds are dead, 100 bb, one raise per
  street at a fixed 3×.
- **Why it changed:** honesty about scope and about grading. The spec's own words: the
  format is "a postflop hand, honestly scoped." Multiway EV under the checkdown model is
  not closed-form; heads-up subtrees are. The full 8-seat table was never the thing the
  bot could be graded against.
- **What survives of the original:** 8-max **positions** are real everywhere else —
  `Position.preflopOrder`, seven RFI charts, the 포지션 drill, seat-scaled archetype
  ranges. The audience-fit argument still holds for the curriculum; it just does not
  describe the 테이블.
- **Current state:** `product-brief.md` still describes 8-max as the table size. That
  sentence is about the *curriculum's* frame of reference, not the shipped table — a
  reader can be misled.
- **Evidence:** `docs/specs/2026-08-04-r4-s4-table-design.md:17-30`; `GlassTableDrills/Sources/GlassTableDrills/Table.swift:15-25`.

### D09 · Bot architecture: ranges as versioned JSON + single-street-lookahead heuristic `[was §4]`
**Status: REVERSED in storage, SUPERSEDED in policy** — nothing is JSON; nothing is a distribution.

- **Decided (original):** a range is a weighted map over 169 classes or 1326 combos
  stored as **bundled JSON**, carrying `schemaVersion` and `rangeSetVersion` so saved
  hands stay reproducible across updates. Postflop = a single-street-lookahead heuristic
  over legible features producing an **action distribution**, each action carrying a
  `rationale` object rendered as Korean prose.
- **What actually shipped:** **no data files at all.** The only non-code resources in the
  app bundle are three Pretendard fonts and the app icon. Every range is *computed at
  runtime* from two published numbers (VPIP/PFR) plus Bill Chen's formula plus a seat
  factor. Postflop is a **deterministic printable bucket table** — bet/call/raise rows
  over five made-hand buckets — with **no mixing and no randomisation anywhere**.
- **Why it changed:** determinism turned out to be worth more than realism. Because the
  policy is deterministic, an observed action **inverts** into the exact surviving combo
  set — which is the product's whole thesis made mechanical. A mixed strategy would have
  made narrowing probabilistic and the grade unverifiable. And because ranges are derived
  rather than stored, there is no range-set to version: the *rule* is the artifact, and
  it is printable in-app.
- **Current state:** ACTIVE in its replacement form. The `rangeSetVersion` /
  `schemaVersion` reproducibility mechanism does not exist for ranges (the progression
  store has its own `schemaVersion`, which is a different thing). One structural
  consequence is pinned by test: **no archetype slowplays**, so a check-raise cannot
  happen and hero never faces a raise — the test exists so a future slowplay row forces
  real coverage before it ships.
- **Evidence:** `Archetype.swift:57-91`, `PostflopPolicy.swift`, `docs/specs/2026-08-04-r4-s3-postflop-policy-design.md`, `docs/specs/2026-08-04-r4-s4-table-design.md:43-56`.

### D10 · Korean legal position: not a legality wall, a rating-track problem `[was §7]`
**Status: ACTIVE, but its factual premise has changed — see D34.**

- **Decided:** no real money and no cashout ⇒ **not 사행성게임물** (illegal gambling
  requires property gain/loss). No purchasable chips ⇒ the 웹보드게임 payment-cap /
  opponent-selection regime has nothing to attach to. Both escape structurally. The one
  thing to plan for is a **청소년이용불가 / KR-19** rating, which is barred from Apple's
  self-rating track and forces a direct GRAC review + Rating Classification Number
  (~10–15 business days, a fee, a gameplay video) — administrative, not a wall.
- **The lever is presentation:** Apple's age rating turns on the questionnaire answer.
  "Frequent/Intense Simulated Gambling" → 17+/KR-19 → GRAC number required;
  "Infrequent/Mild" → 12+/KR-15, self-rating, no GRAC number. The more the app reads as
  calculators / equity / range drills and the less it depicts theatrical chip-betting,
  the lower the rating.
- **Standing constraint that must never be violated:** never add purchasable currency or
  cashout. That is what keeps the structural escape valid.
- **Evidence:** `docs/risks.md` "Legal & store"; `docs/submission.md`.

### D11 · Ship Math Drills first `[was §9]`
**Status: SUPERSEDED** — it shipped, then the app was rebuilt around a course.

- **Decided:** the first shippable thing is Math Drills alone (outs/rule-of-2·4, pot odds,
  call/fold, MDF, blockers). Complete and useful on its own; lowest gambling-simulation
  signal, so it validates the Korean rating path before any betting UI exists; forces the
  correctness-proven engine and the whole submission pipeline into existence first.
- **What happened:** shipped 2026-07-23 and tagged `v1.0.0-beta.1`. Ten days later the
  revamp (D25) replaced the drill-grid home with a course, and the five M1 drills became
  path nodes and 자유 연습 entries.
- **Current state:** the *strategy* was correct and paid off (engine, pipeline, CI and
  submission prep all exist because of it). The *artifact* no longer exists as such.
- **Evidence:** `docs/milestone-1.md` status banner; commit `7daef48`.

### D12 · Curriculum order: fundamentals → ranges → exploitation, gated but skippable `[was §8]`
**Status: SUPERSEDED** by the current 8-unit course with **strictly linear,
non-skippable** unlocking.

- **Decided (original):** a 12-step ladder (equity intuition → outs → pot odds →
  position/preflop ranges → ranges as a concept → equity vs a range → board texture →
  value vs bluff → MDF & blockers → fold equity → exploit deviations → multi-street
  planning), with **light and skippable** gating so a curious user can jump ahead.
- **Current state:** 8 units / 17 path concepts (18 overall; MDF is free-play-only),
  ordered 기초 → 레인지 → 보드 → 결정 → 상대, with **strictly linear unlocking and no
  skipping**. The first-run diagnostic could pre-clear nodes but was later deleted
  (D30). 자유 연습 offers every drill, unlimited, ungated, off the path.
- **Why it changed:** the ladder's steps were plateaus, not teachable units; R1 needed
  something a node could *be*. Skippability moved from the path into free play, which
  keeps the path's ordering meaningful.
- **Evidence:** `GlassTableDrills/Sources/GlassTableDrills/Progression/Curriculum.swift`; `docs/specs/2026-08-03-r1-progression-shell-design.md` §4.

---

# 2026-07-22 → 07-23 · Milestone 1

### D13 · Bet sizing: preset %-pot buttons, pro unit on top, no slider `[was §A]`
**Status: ACTIVE**

- **Decided:** a fixed menu (33 / 50 / 75 / 100 / 150 % pot + all-in) rendered as preset
  buttons. **Headline is the pro unit** — % of pot postflop, big blinds preflop — with the
  resolved chip amount as a dim sub-label so a beginner never does pot math. 100 % is
  labelled "Pot", the top size "All-in".
- **Why no slider:** every serious tool and every real client converged on presets;
  GGPoker warns sliders cause mobile misclicks. Decisively: **the bots only understand
  the fixed menu**, so a free slider would let hero pick sizes the bot cannot reason
  about — dead flexibility that would silently corrupt grading.
- **Current state:** ACTIVE; the 테이블's sizes come from this menu.

### D14 · Range-grid conventions: the universal ones `[was §B]`
**Status: ACTIVE** (one clause obviated)

- **Decided:** pairs on the diagonal AA→22; **suited upper-right, offsuit lower-left**;
  colour = action (red raise/3-bet, green call, grey fold); mixed strategies as
  proportional split-fill cells.
- **Current state:** the layout conventions are ACTIVE (`DesignSystem/RangeGridView.swift`).
  The split-fill clause is **obviated, not implemented**: nothing in the app mixes (D09),
  so there is no frequency to split. If mixing is ever added, this clause is the spec.
- **Later addition (R3):** the range-read reveal draws **one grid with two independent
  channels** — fill = the true range, ring = your estimate — rather than two grids side by
  side, which at ~12 pt a cell on a 12 mini would be illegible and would need a third
  fill colour that could not be colour-blind-safe. Readable in greyscale, with a printed
  legend. `docs/specs/2026-08-04-r3-range-read-design.md` §9.

### D15 · Archetype parameters: VPIP/PFR from the literature `[was §C]`
**Status: ACTIVE — these five pairs of numbers are the entire bot.**

| Archetype | VPIP | PFR | Character |
|---|---|---|---|
| **Nit** | 12 | 9 | tight-passive |
| **TAG** | 20 | 17 | tight-aggressive |
| **LAG** | 27 | 22 | loose-aggressive |
| **콜링 스테이션** | 40 | 10 | loose-passive (huge VPIP–PFR gap) |
| **매니악** | 55 | 40 | loose + hyper-aggressive |

- The defining discriminator is the **VPIP–PFR gap** — tiny for TAG/LAG, 20+ for the
  Station. Everything the archetype *is* falls out of it.
- **Current state:** these literal numbers are in `Archetype.swift:16-30`, and every range
  the bot has is derived from them plus a seat factor normalised so the average across the
  seven acting seats reproduces the declared statistic.

### D16 · Grading feedback: EV loss in bb + soft severity bands `[was §D]`
**Status: ACTIVE**

- **Decided:** for decision grading, lead with **EV loss in big blinds** — continuous and
  honest rather than a demoralising binary — mapped to three soft bands. For estimation,
  grade on **error bands (정확 / 근접 / 빗나감)** rather than 정답/오답, so estimating
  feels like calibration, not pass/fail.
- **Two vocabularies, never mixed:** 최선 / 부정확 / 실수 at 0.5 / 2.0 bb for EV-loss
  severity; 정확 / 근접 / 빗나감 for estimation bands. `CONTEXT.md` states this as a rule.
- **Why "decide first, then reveal" is defensible in-app:** active recall + progressive
  disclosure (Nielsen / NN-group) — the transparency thesis made explicit.
- **Current state:** ACTIVE. The bb thresholds are **EXPERIMENTAL** — see D28.

### D17 · Korean terminology `[was §F]`
**Status: ACTIVE**

- **Decided, confirmed against real Korean usage** (pokergosu, CoinPoker KR, namu.wiki):
  actions and streets always Hangul (콜 · 레이즈 · 폴드 · 체크 · 벳 · 올인 · 프리플랍 ·
  플랍 · 턴 · 리버; **플랍**, not 플롭); acronyms and positions always Latin (GTO, EV, MDF,
  SB/BB/UTG/HJ/CO/BTN); **3벳 / 4벳** = digit + Hangul; **TAG/LAG stay Latin** because
  Hangul 태그/래그 collide with everyday "tag"/"lag"; learning-critical concept terms shown
  **bilingually** on first sight (에퀴티/Equity, 팟 오즈/Pot odds, 블로커/Blocker) because
  users meet them in English solver tools.
- **Implementation rule that matters:** Korean **particles are computed**
  (`KO.subject/object/topic/copula`), never baked into format strings.
- **Current state:** ACTIVE. The canonical term table is `docs/glossary.md`.
- **Evidence:** `GlassTableDrills/Sources/GlassTableDrills/Korean.swift`; `docs/glossary.md`.

### D18 · MIT license → no license
**Status: REVERSED**

- **Original:** the baseline commit added an MIT `LICENSE` and several documents planned
  around it.
- **Reversed 2026-07-31 (`f1eab51`):** LICENSE deleted, all rights reserved.
  **2026-08-01 (`9677f8f`)** corrected every document that still claimed MIT, noting the
  file had in fact never existed as applied. **2026-08-02 (`3cd6154`)** moved the README's
  License section to the end.
- **Current state:** "Copyright (c) 2026 Michael Ju. All rights reserved. No license is
  granted… This repository is public for portfolio review purposes only."
  Third-party license *facts* (eval7 MIT, OMPEval ISC, poker-eval GPL) remain in the docs
  as dependency constraints — those were never about this repo's own license.

---

# 2026-07-24 → 07-25 · Post-M1 polish

### D19 · App icon: percent-on-disc → range-grid heatmap
**Status: REVERSED**

- **Original (`9530fa4`, 2026-07-23):** a card-free abstract mark — a table disc with a
  percent sign — chosen deliberately to weaken the "gambling" signal for the rating.
- **Replaced (`055eeb7`, `a32b03f`, 2026-07-24):** a 4×4 equity-heatmap range grid with the
  four suits on the pair diagonal in card colours, then softened to follow the heatmap
  falloff rather than solid white.
- **Current state:** the heatmap icon ships. `docs/plans/2026-07-23-m1-submission.md`
  Task 10 still tells a reader to verify the old percent-on-disc icon — stale text in a
  historical document.

### D20 · Onboarding: guide document → played hand → deleted entirely
**Status: REVERSED, twice — and the second reversal is the durable one.**

- **v1 (`GuideView`):** 3분 시작 가이드 — eight cards of Korean prose on felt,
  auto-opened on first launch.
- **v2 (`2cd45fc`, 2026-07-25):** replaced by **첫 핸드** — one authored hand
  (Ah Kh vs Qs Qd on Qh 7h 2s 3c) that asks each of the five drills' own questions in the
  order the hand asks them, guess-before-explanation throughout. Every number in it is
  *computed*, not typed. It wrote nothing to the progress store, because "a 🔥 handed out
  for free is a lie."
  **The research behind it is worth keeping** (`.scratch/onboarding-first-hand/spec.md`):
  the pretesting effect (Richland, Kornell & Kao 2009 — subjects quizzed *before* reading,
  who mostly answered wrong, outperformed subjects given extra study time across all five
  experiments); Duolingo's revealed preference in demoting pre-lesson prose and moving the
  surviving explanation *into* the post-answer banner; NN/g's mobile-tutorial test (70
  users) where the only significant effect ran backwards — tutorial readers rated the same
  tasks *harder*. Conclusion: **the container was wrong, not the length.**
- **v3 (`0d86328`, 2026-08-04):** **deleted.** R1's per-node 보여주기 already teaches on
  first exposure, "so a separate onboarding was a second system doing the same job."
  `FirstRunView` (the R1 replacement) went with it in the same commit; `FirstHandView`
  (598 lines) had already been swept in `df40449`.
- **Current state:** there is **no onboarding**. Teaching happens inside every node's
  천천히 walkthrough, and 천천히 can be replayed on demand from 오늘 and 기록. The
  finding that survives all three versions: *explanation belongs where the confusion is,
  after a committed answer.*

---

# 2026-07-23 → ongoing · Store submission

### D21 · Public repo, to host the privacy policy
**Status: ACTIVE**

- **Decided:** make the repo public so GitHub Pages can serve the privacy policy at a
  stable URL, satisfying App Store Connect's requirement without standing up hosting.
- **Current state:** repo is public; Pages builds from `main:/docs`; policy live at
  `https://mhju0.github.io/glass-table/privacy-policy.html`. Coupled to D18 — public *and*
  all-rights-reserved, explicitly "for portfolio review purposes only."

### D22 · Proceed without Korean legal counsel for M1
**Status: SUPERSEDED — the condition that made it safe no longer holds.**

- **Decided 2026-07-23:** ship M1 without counsel. Math Drills is the lowest-signal build,
  and the GRAC direct review is an administrative fallback rather than a wall.
  **Explicitly conditional: "revisit counsel before the betting-table milestone."**
- **What changed:** the betting-table milestone shipped (R4-S4/R5, 2026-08-04). The
  condition fired. Counsel has not been consulted.
- **Current state:** `open-questions.md` #11, marked "now live rather than hypothetical."

### D23 · Pause store submission for a dogfood phase
**Status: ACTIVE — and it is where the project still sits, 6 weeks later.**

- **Decided 2026-07-23 (`7daef48`), owner decision:** stop before Apple Developer
  enrollment. Dogfood on the owner's own device via free personal-team provisioning
  (7-day expiry, redeploy weekly). When resumed: enroll → **TestFlight upload only**;
  never submit for review without an explicit go.
- **Why:** the app should earn its submission by being used, not by being finished.
- **Current state:** never resumed. Not enrolled. No release. Zero GitHub issues have ever
  been filed, so the intended feedback loop produced no visible artifacts.
- **Evidence:** `docs/plans/2026-07-23-m1-submission.md:6-9`; `gh issue list` empty.

---

# 2026-08-03 → 08-04 · The revamp (R1 → R5b)

### D24 · The preflop-chart licensing problem `[was §E, amended]`
**Status: ACTIVE in its final form; the original §E is REVERSED.**

- **Original §E:** baseline the archetypes on **GTO Wizard's** free 8-max cash ranges,
  cross-referenced to Upswing's 9-handed RFI; generate our own values rather than shipping
  competitors' PDFs; disclose the 8-handed interpolation.
- **Research finding, 2026-08-03:** **no NLHE preflop chart exists under a redistributable
  licence.** Upswing, PokerCoaching, GTO Wizard, Preflop Wizard and FreeBetRange are all
  all-rights-reserved marketing assets, free to *read* only. Shipping a chart's 169 cell
  values **is** redistribution, attribution notwithstanding — solved frequencies may be
  uncopyrightable facts, but a specific chart's exact values function as a database, and
  "we cited them" is not a licence. So "generate our own values" was never merely IP
  caution; it was the only viable path.
- **Second reversal in the same decision:** GTO Wizard was **demoted as the baseline**
  because it is the product `product-brief.md` names as the direct competitor — values
  traceable to it inside a free competing app are the highest-exposure option available
  and the worst look.
- **Current state:** benchmarks are **Upswing's free 9-handed RFI PDF** and
  **PokerCoaching's free charts**, *named in-app as what the derivation was checked
  against and never reproduced*. The 8-handed interpolation is disclosed in-app, and
  **that disclosure is the transparency feature.**
- **Evidence:** `docs/specs/2026-08-03-r1-progression-shell-design.md` §13; `RFIChart.swift:6-24`.

### D25 · The chart derivation rule: equity-vs-random → Bill Chen's formula
**Status: REVERSED within one day, on measurement.**

- **Original rule (R1 §13, approved 2026-08-03):** derive every opening range as
  "top N % by all-in equity versus a uniform random hand."
- **Measured and rejected (2026-08-04):** over all 169 classes the rule puts **76s in the
  bottom quartile, 22 at 87/169, and A9o *above* AJs**. It cannot see playability, so it
  would have shipped a chart that opens A9o under the gun while folding 76s everywhere.
- **Replacement:** **Bill Chen's published starting-hand formula**, which matches
  convention on every boundary case tested — AJs above ATo, 76s and 22 inside late ranges,
  A9o outside early ones, 72o last, and every chart nested (UTG ⊂ UTG+1 ⊂ LJ ⊂ HJ ⊂ CO ⊂ BTN).
- **Why this matters beyond charts:** Chen is now the derivation rule for **everything** —
  RFI charts, archetype play/raise/call ranges, the defend chart, the table's hero band.
  One published formula is the root of every range in the app.
- **Evidence:** `docs/specs/2026-08-04-r2-range-primitive-design.md` §1; `GlassTableEngine/Sources/GlassTableEngine/Chen.swift`.

### D26 · Progression: FSRS-6 over **concepts**, not drills or hands
**Status: ACTIVE**

- **Decided:** the unit of mastery and review is the **concept** (18 of them), because the
  same concept is exercised by several nodes. Four mastery tiers
  (attempted → familiar → proficient → mastered), and **숙달 is reachable only through a
  boss node**, because a boss certifies transfer rather than fluency. Review is FSRS-6 with
  published default weights. Estimation concepts additionally collect a **point + 90 %
  interval scored by the Winkler rule**, feeding a calibration verdict — so the app can
  say whether you are overconfident, not just whether you were right.
- **Deliberate exclusions, reasoned in `Concept.swift`:** `rangeRead` is emphatically an
  estimate but is *not* Winkler-scored, because it is answered with a width and a shape,
  not a point plus an interval — its softness rides on overlap bands instead. `evLoss` is
  excluded for a different reason: the answer is a *choice*, so what is continuous is the
  grade, not the answer, and there is nothing to put an interval around.
- **Evidence:** `Progression/Concept.swift`, `Progression/FSRS.swift`, `Progression/Calibration.swift`.

### D27 · Explicitly rejected: engagement theater
**Status: ACTIVE (a standing "do not build" list)**

- **Decided (R1 §7.2):** build streaks with **silent freezes** and mastery counts; do
  **not** build leagues, XP, hearts/lives, IAP, ads, accounts or networking.
- **Related shipped rule:** 기록 leads with mastered-concept count — "never XP and never
  streak" (`ProgressionModel.swift:70`).
- **Current state:** the list has held. The streak is drawn with SF Symbols rather than
  emoji since 2026-08-07 (`c583989`) — the last two emoji used as icons in the app.

### D28 · EV-loss thresholds are absolute bb
**Status: EXPERIMENTAL — flagged as provisional by its own spec.**

- **Decided:** severity bands at 0.5 bb and 2.0 bb, absolute.
- **Known weakness, stated at ship time:** the thresholds are not pot-relative, so a 2 bb
  error in a 7.5 bb pot and in a 60 bb pot grade identically. R4-S2 §2 calls this "the
  model's weakest joint" and §7 says explicitly that retuning is out of scope for that
  slice and **should be revisited against real answers**.
- **Current state:** unchanged since ship. No real answers have been collected (D23).

### D29 · The checkdown model, disclosed
**Status: ACTIVE**

- **Decided:** grading assumes that after the current street settles there is **no further
  betting**. Exact on the river, an approximation before it.
- **Why disclosed rather than hidden:** every simplification the app makes (checkdown,
  seat-insensitive defense, no 4-bets, one raise per street at a fixed 3×) is **stated on
  screen, not smuggled**. That is a house rule: "every reveal shows where its number came
  from; sampled numbers say so."
- **A consequence that changed the design:** hero's preflop street was originally *not
  played at all* in R4-S4 (see D31) precisely because grading it under this model would
  teach a lie — a 3 bb call needs ~29 % equity, which almost any two cards clear.

### D30 · First-run diagnostic that can pre-clear path nodes
**Status: REVERSED (implemented, then deleted)**

- **Decided (R1 §6):** first run offers a diagnostic; passing pre-clears nodes so an
  experienced user is not walked through 쇼다운. `Curriculum.status` was written to
  tolerate a pre-cleared *gap* — it opens the node after it rather than stranding the path.
- **What happened:** `a2c3063` implemented `FirstRunView`, including an eight-item
  diagnostic and `applyDiagnostic()` to pre-clear nodes. `0d86328` deleted that view and
  its root presentation. The earlier handoff's "never built" claim contradicts Git
  history. `[V]`
- **Later proposal:** an intro card was discussed during the 2026-08-06 wiring pass.
  `[C]` agent memory is the only source for that substitution decision; no intro card
  exists in the current source.
- **Current state:** the code path exists and nothing produces it. Combined with D12's
  strictly-linear unlocking, **there is currently no way to skip anything on 길** — 자유
  연습 is the only escape.

### D31 · Hero's preflop street: not played → played for real
**Status: REVERSED within the same day, and this is the good kind of reversal.**

- **R4-S4 (spec §1):** hero's preflop decision is **deliberately not played**, because
  grading it under the checkdown model would teach "call everything." Hero's hand is dealt
  from a stated playable band (top 30 % by Chen) instead. The spec named the escape route:
  "a real defending-chart slice can add the preflop street later, the way R2 added RFI."
- **R5 (same day):** the defending chart was built — 3벳/콜/폴드 bands derived from the
  opener's width (top 0.30× / to 0.75×, by Chen) — so hero is now dealt **any two cards**
  and plays fold/call/3-bet for real, graded against the chart rather than against bb EV.
  The bot answers a 3-bet with a character-scaled top slice of its opening range and
  **never 4-bets (stated on screen)**.
- **Why it matters:** the grading truth changed shape. Preflop is graded against *a chart*
  (ordinal, three-way), postflop against *bb EV*. Two grading vocabularies coexist in one
  hand, on purpose.
- **R5b** then put the same chart on the path as unit 8's 디펜드 차트 drill, with ordinal
  three-way grading where one band off = 근접.
- **Evidence:** `docs/specs/2026-08-04-r4-s4-table-design.md:17-30`, `…r5-hero-preflop-design.md` §1–3, `…r5b-defend-drill-design.md`.

### D32 · MDF is parked, not deleted
**Status: DEFERRED — and the gate is now open.**

- **Decided (R1 §3.2, §12.6):** MDF leaves Block A and gets **no path node**, though it
  keeps a `Concept` case so 자유 연습 progress is still recorded.
- **Why:** the shipped MDF drill is only the **frequency half** — `BetSpot` is
  `(pot: Int, bet: Int)` with no cards and no range, grading `pot/(pot+bet)`. The actual
  skill is *selecting which combos make up the defense*, whose prerequisites (fold equity,
  combos-in-a-range) did not exist. Shipping the frequency half alone "would teach a
  referent-free formula, which is the exact defect the audit identified."
- **What changed:** the named prerequisites shipped in R2–R4 (`HandRange`, `RangeOnBoard`,
  `PostflopPolicy.narrowed`). **There is still no fold-equity primitive in the engine.**
- **Current state:** completing MDF is a **full slice** on the order of R4-S1 (spot type +
  defense-selection grading + screen + beats + its own spec) — never a node-only change.
  The parked state is guarded by tests (`CurriculumTests`, `RangeReadTests`), so it will
  not drift silently.
- **Do not file "MDF has no path node" as a bug.** It was misread as a gap once already
  (2026-08-10) and a 30-minute node fix was pitched; it is not one. `[C]`

### D33 · Table results are not persisted
**Status: DEFERRED, on purpose**

- **Decided (R4-S4 §5):** table decisions are **not** written into concept records,
  because they would distort `evLoss`'s FSRS scheduling and mastery, which belong to the
  drill. The hand summary is the whole record in v1.
- **Deferred:** a separate table-stats store (hands played, mean loss per hand). Agreed
  during the wiring pass to let dogfood decide whether it is wanted. `[C]`

---

# 2026-08-04 → 08-07 · The visual system

### D34 · Surface material: three generations `[was §G]`
**Status: ACTIVE in its third form. The first two are REVERSED.**

**Generation 1 — Toss-inspired, borderless (2026-07-22, `8d59189`).** A green content
zone on top, a white action sheet at the bottom, no borders. Shipped through all of M1.

**Generation 2 — glass as a material, plus a dark twin (2026-08-03/04, `3d616a4`, `df40449`).**
Translucent `.ultraThinMaterial` surfaces, ivory-veiled, lit at the edge; `GT`/`GTBand`
tokens resolved per interface style so the app followed the system light/dark setting.
`dyn()` did the resolving.

**Generation 3 — glass is a colour; one appearance (2026-08-04, `b8173dd`).** REVERSED
generation 2, and the reversal was driven by **measuring real pixels out of a
`tools/uisweep.sh` capture rather than reading the tokens**:

- **The material was not separating anything.** WCAG 2.1 SC 1.4.11 wants **3:1** for a UI
  boundary. Measured on the shipped build: a glass card against the felt **1.71:1** on
  오늘 and **1.19:1** on 설정; the answer sheet against the felt **1.17:1**; a choice
  button against the sheet **1.36:1**. Taking the most generous reading — the 1 px border
  as the boundary — it topped out at **2.49:1**. Three choice buttons read as three rows
  of text *because that is what the numbers said they were.*
- **There was nothing to blur.** `FeltBackground` is a flat fill plus a spade at 3.5 %
  opacity, so `.ultraThinMaterial` was paying an offscreen pass per surface to arrive at a
  solid tint — and it had to be forced to `.dark` to stop the system flipping it, which is
  where the "ink never flips" rule came from.
- **The boundary moved to the edge.** `borderStrong` is opaque `#8C938B` — 3.0:1 against
  the glass, 5.3:1 against felt or a recessed inset. Opaque because `strokeBorder` paints
  over the shape's own fill, so a translucent edge resolved differently on a card
  (`#8C938B`) than on a choice button (`#777F77`), and only the first cleared 3:1.
- **Insets go down, not up.** White ink cannot survive two 3:1 steps up from the felt: the
  second puts the fill at `#A8AEA6`, where `ink` measures 1.9:1. So `GT.surface` is a well
  cut *toward* the table (`#16261E`), not ivory laid on top. **Direction was forced by the
  arithmetic, not chosen.**
- **The alternative was tried and rejected:** brightening the glass to `#566D60` clears
  3:1 against the felt but drops `inkMuted` to 2.2:1 and the three band inks to 2.6–3.3:1
  — one boundary failure traded for six ink failures.
- **One appearance.** The two schemes measured **1.50:1 apart on the felt and 1.04:1 on
  every glass surface** — the same pixel. So `UIUserInterfaceStyle: Dark` is pinned in
  `project.yml` (not via `.preferredColorScheme`, so system UI — sheets, keyboards, alerts
  — stays in the same room), `dyn()` is gone, and the sweep makes one pass instead of two.
  **"Dark mode was never the same room at night; it was the same room."**

**Current state:** glass is the opaque value the stack already resolved to (`#3B4941`,
measured off a screenshot as `#38473E`). Every boundary is measured off real screenshots
against 3:1. **Ink never flips.**

### D35 · Action accents mark money, never merit `[was §G, amended 2026-08-07]`
**Status: ACTIVE — and stated as a rule that pre-emptively rejects a future "improvement".**

- **Problem:** the table's three actions shared one surface, one border and one weight, so
  fold / call / raise read as three rows of text.
- **Decided:** separate them with a 3 pt rule under the price, coloured by **what kind of
  money the button commits** — `actionCall` `#A67C1F` for the call denominator,
  `actionBet` `#3E9A6E` for a wager, `borderStrong` for 폴드, which puts nothing in. The
  raw price-bar segments could not be reused as a hairline on `surface` (they measure
  2.79:1 벳 and 2.54:1 콜, under 3:1), so these are the same hues raised until they clear
  it, at **4.6:1 and 4.2:1**.
- **The rule:** the colours deliberately **do not rank the options**. The table grades the
  choice, so an action styled as the primary CTA would hand over the answer before the
  user commits — the same reason `GTChoiceButton` renders every drill answer identically
  and only turns mint once *selected*.
- **Stated consequence:** *"Any future 'make the recommended action stand out' is a bug,
  not a polish."*

### D36 · Nav chrome: draw it ourselves, not on system Liquid Glass
**Status: ACTIVE (REVERSES the default platform behaviour)**

- **Problem:** under iOS 26 a toolbar item is handed a glass capsule whose material samples
  whatever is behind it. On a sheet that is the outgoing screen, so the button visibly
  changed shade while the sheet settled, and the ring read as a floating bubble rather than
  a control.
- **Decided (`3c10ab2`):** one `ChromeButton` for every screen — a bare glyph on felt, with
  *direction* carrying meaning (down returns a sheet the way it came up; left steps back
  one level inside it). 닫기 moved to the leading edge everywhere; the glossary became a
  sheet rather than a push so it stops inheriting the one control the app cannot draw itself.
- **Coupled cost:** this is why the app requires **Xcode 26** to build — the chrome calls
  `sharedBackgroundVisibility` and `#available` guards runtime, not compile.

### D37 · Type scaling: text scales with the reader, a card does not `[was §H]`
**Status: ACTIVE. This entry exists because of a shipped critical bug.**

- **The bug it settles:** every font in the app is declared `relativeTo: .body`, so it
  follows Dynamic Type — correct for text, wrong for the one thing that is not text. A
  card's rank was drawn with `GT.title(size * 0.36)` inside a frame fixed at
  `size * 0.72 × size`. At accessibility sizes the label outgrew the card and truncated:
  **every rank rendered as "…"**. 쇼다운 asked who won above nine blank cards; the table
  could not be read at all. **The setting that exists to help made the app unplayable.**
- **Why scaling the card is not an option, arithmetically:** at `accessibility-XXXL` body
  text grows roughly **3×**, putting a 46 pt board card at ~143 pt and a five-card row at
  **~715 pt against 393 pt of screen**. Even `CardRow`'s smallest rung (48 pt → 34.5 pt
  wide) reaches ~535 pt. **There is no rung that fits.**
- **Decided:** a card is a **pictogram**, so it opts out (`GT.fixed`,
  `.custom(_:fixedSize:)`). The glyph is a fraction of the card; the card is sized so five
  fit a board on the narrowest supported screen. VoiceOver already publishes each card
  ("스페이드 A"), which is where the content goes instead.
- **One-row diagrams clamp rather than opt out:** the drills' 자리 strip and the table's
  스트리트 strip are real text in flexible chips, so they keep scaling but stop at
  `.xxLarge`, short of where `UTG+1` broke into three lines. Both are diagrams whose
  meaning depends on seeing every entry at once.
- **The rule for anything added later:** ask whether the glyph is *read* or *looked at*.
  Read → let it scale. Looked at, or pinned to a fixed geometric frame → `GT.fixed`, and
  make sure VoiceOver carries the content. **A fixed frame around scaling text is the
  defect**, and it is invisible until someone sweeps at an accessibility size — so
  `xcrun simctl ui <dev> content_size accessibility-extra-extra-extra-large` followed by
  `tools/uisweep.sh` is part of looking at the app, not an extra.

---

# 2026-08-06 → 08-09 · Completeness and performance

### D38 · Wire the dead ends before adding anything new
**Status: ACTIVE (a completed pass, and a stance worth keeping)**

- **Decided:** rather than build features, find **shipped machinery with no UI attached to
  it** and connect it. That pass wired: 천천히 replay sheets, Settings 백업 만들기 /
  백업 불러오기 / 진행 초기화, an honest 오늘 subtitle that only claims what a button can
  deliver, a due-filtered 복습 sheet (instead of dumping the user on the 길 tab), the
  designed-but-never-instantiated `GlossaryChip` in every drill reveal, streak-freeze
  display, and grade-reveal haptics.
- **Agreed skips, recorded as YAGNI at the time:** mid-session resume; the R1 first-run
  diagnostic (D30); a table-stats card in 기록 (D33 — "dogfood decides"). `[C]`
- **Deferred to a pre-submission bundle:** a daily reminder notification (R1 §6's day-3
  prompt) and a VoiceOver pass over `TableView` / `NodeSessionView`. `[C]`
- **Evidence:** commits `e059ec6`, `f38c520`, merge `5e8b73e`.

### D39 · Behaviour-preserving refactors must be *proven*, not asserted
**Status: ACTIVE — this is now the house method for performance work.**

- **Decided:** when a change must not alter output, the test suites are not convincing on
  their own (92 engine tests cover a tiny slice of the input space). Instead:
  `git archive HEAD~1 <package> | tar -x` into a scratch dir, point a throwaway SwiftPM
  executable at both the old and new package, dump a large deterministic sweep of outputs
  (tens of thousands of lines, floats to 9–12 decimals), and **diff. Byte-identical is the
  bar.** Include the seeded/Monte-Carlo paths, because matching MC output is what proves
  the RNG consumption order is unchanged — the real risk when rewriting a sampling loop.
- **Applied, with numbers:** the 2026-08-08/09 campaign compared 1,000 generated spots
  across 40 seeds, their narrowed distributions to twelve decimals, 6,000 grades with their
  Korean text, and 10,000 walkthrough beats — all byte-identical — plus a 58-screen pixel
  sweep (56 identical; the two that differ are a card fade-in caught mid-animation, which
  reproduces on an *unchanged* build).
- **Caveat that bites:** `tools/uisweep.sh` folders are only comparable **within one
  simulator size** — `GT_SIM` defaults to iPhone 17 and older folders were captured at a
  different resolution. To get a real baseline: stash, sweep, unstash, sweep, then diff
  with the top ~6 % cropped off (the clock changes every run). `[C]` + commits `0d8d87f`, `7640fef`.

### D40 · SwiftUI: never hold a generated spot in a computed property
**Status: ACTIVE (a rule extracted from a measured regression)**

- **Found:** a `spot` in a computed property regenerates on **every read**, and a SwiftUI
  `body` reads it 5–9 times. The generators are not cheap — 액션 리드 narrows a range per
  attempt, EV 손실 prices an equity per candidate — so every render re-ran the whole
  rejection loop **on the main thread**. Release measurements per body pass: 액션 리드
  769 µs → 86 µs, EV 손실 758 µs → 153 µs, 콜/폴드 178 µs → 36 µs, 아웃 135 µs → 45 µs.
- **Rule:** bind the spot **once per render**; push anything that depends only on the spot
  into the detached task that already computes for that spot.

---

### D43 · Failed saves remain recoverable; replacement commits after disk success
**Status: ACTIVE — 2026-09-05**

- **Decision:** before reset or import, copy the existing file to a unique recovery
  file, then atomically write the replacement. Change displayed progress and leave
  recovery mode only after that write succeeds. Disk loads and imports apply the same
  schema-version check.
- **Ordinary save failures:** retain recent answers in memory, show a persistent retry
  notice, and export that current state when the user creates a backup. Never imply an
  unsuccessful save was durable.
- **Reason:** takeover reproductions showed silent save failures, failed imports
  changing memory, and ignored quarantine failures overwriting recovery bytes. Fix
  these before the next dogfood build. Evidence: `ProgressionStoreTests` and
  `GlassTable/Tests/ProgressionModelTests.swift`.

---

### D44 · Progression credit must correspond to actual practice
**Status: IMPLEMENTED — 2026-09-05 cleanup branch.**

- Award the study day when an answer is recorded, using the due queue **before**
  rescheduling. Any due answer qualifies, including a miss; when nothing is due, new
  practice qualifies. Finishing a whole node is not required. Answer, schedule and
  streak persist together, replacing the separate end-session write.
- Boss sessions ask at least six questions and cover their whole concept pool before
  awarding mastery. Unit 2 needs seven; the fixed six-question run promoted position
  without testing it. Regular drill nodes remain five blocked questions.
- Evidence: review-queue regressions, curriculum coverage and app persistence tests.
  This amends R1's fixed six-question boss/session-completion wording, preserving its
  anti-farming rule and mastery-by-demonstrated-practice intent.

---

# Open / unresolved

### D41 · The age-rating answer for a build that now contains a betting table
**Status: UNKNOWN — and it is the only thing blocking store resumption.**

- **Answer of record (M1):** Simulated Gambling = **Infrequent/Mild**, on the rationale
  that there was no betting gameplay. That rationale **no longer describes the app**.
- **What is true now:** the 테이블 depicts simulated betting with bb stakes (no real money,
  no purchasable currency). An honest re-answer is plausibly Frequent/Intense → 17+/KR-19,
  which is barred from Apple's self-rating track in Korea and triggers the GRAC
  direct-review contingency.
- **Also stale in the same document:** the review notes' "no simulated betting gameplay"
  phrasing was removed but not replaced with a final wording.
- **Standing instruction:** if the computed rating comes back 17+/KR-19, **stop before
  submitting** and treat the GRAC direct review as its own sub-project.
- **Evidence:** `docs/submission.md:3-13`, `:124-142`; `open-questions.md` #11.

### D42 · Still genuinely open
**Status: UNKNOWN / DEFERRED**

- **Korean app name / branding** — "Glass Table", 유리 테이블, or a bilingual lockup? Never
  decided (`open-questions.md` #12).
- **A 6-max table-size option** — cheap after 8-max, demand unconfirmed (#14).
- **`.glasstable` puzzle-sharing schema** — never designed; blocks the post-v1 Lab (#16).
- **Whether the archetype bot is *useful*, not merely correct** — the top-severity entry in
  `risks.md`. The mitigation shipped as designed; the residual risk is empirical and only
  dogfood answers it.

---

## Standing non-goals (never revisit without new evidence)

From `product-brief.md`, unchanged since founding and reaffirmed by everything above:
no multiplayer, netcode, real money or purchasable chips — **ever**; no iPad, Android or
web; no tournaments or ICM; no rake modelling; no continuous bet sizing; no backend; no
money and no ads; no competing with GTO Wizard on equilibrium depth; no multi-street
planning for the bot.

Each has a named back-burner trigger in `docs/risks.md`. **Revisit only on evidence, not
vibes.**
