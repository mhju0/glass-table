# Glass Table — Decisions

Each open decision, its options with tradeoffs, and one recommendation. Context that constrains all of them: **solo full-time developer, strong in TS/React, zero shipped Swift, poker beginner, no pro validator; iPhone-only forever; fully free, on-device, no backend; audience is 20s–30s home-game players.**

---

## 1. Tech stack — **SwiftUI, pure-Swift engine, no Rust/C core**

| Option | For | Against |
|---|---|---|
| **SwiftUI (recommended)** | The custom animated 8-seat table, the 13×13 grid, gestures, and reveal animations are exactly where SwiftUI shines. The equity engine is *just Swift* (compiled, near-C in tight loops) — no bridge. iPhone-forever means RN's cross-platform advantage is worthless here. Full-time makes the from-zero learning cost affordable. Best long-term fit for a compute-heavy, single-platform, animation-heavy app. | Real learning curve from zero Swift. No code reuse with the developer's existing TS. |
| React Native / Expo | Reuses the developer's strongest skill (TS/React); fast initial velocity. | The equity engine can't live in JS at 8-way Monte Carlo scale — you'd be forced into a native module or WASM (i.e. writing C/Rust and bridging *anyway*). The custom table/grid UI is RN's weakest area. Cross-platform benefit is moot on iPhone-forever. You still have to learn iOS specifics. |
| SwiftUI + Rust/C engine core (FFI) | "Portable, testable engine." | Adds a second toolchain and a second unfamiliar language for a problem Swift already solves natively. iPhone-forever kills the portability rationale. Pure over-engineering here. |

**Why.** iPhone-only-forever removes React Native's single real advantage while keeping all its costs. In SwiftUI the engine is native Swift; in RN the same engine forces WASM/native modules — so RN doesn't even save you the "hard part." A Rust/C core is a rabbit hole with no payoff on one platform. **Write the equity engine in pure Swift.** Revisit an FFI core only if profiling ever shows Swift can't hit the latency budget (§2) — it will.

---

## 2. Equity engine — **perfect-hash evaluator; enumerate when small, fixed-seed Monte Carlo when large; compute during think-time**

**Evaluator (7-card hand ranking):** **written from scratch in Swift** (developer's decision — no third-party evaluator shipped, so no external-license concern). Target a **perfect-hash design** (phevaluator-style: ~few MB tables, or generated at first launch) — the sweet spot for a mobile study app. Reject the two-plus-two lookup table (~123 MB, hostile on mobile). Cactus-Kev-iterated-to-7 is a simpler fallback if the perfect-hash build proves fiddly. An existing evaluator (treys / OMPEval / etc.) is used **only as a dev-time reference oracle** to validate the from-scratch code — never shipped (see §10 and open-questions).

**Enumeration vs Monte Carlo:**

- **Enumerate when the space is small** — river (0 cards), turn→river (44 boards), heads-up vs a capped range. Exact, no variance.
- **Monte Carlo when multiway or ranges are large** — 8-way equity vs ranges is combinatorially explosive; sample opponent hands from their ranges + sample the runout.
- **Determinism is mandatory for a *grading* app**, and benchmarks are **computed on the fly** (developer's decision — not pre-stored). A benchmark that jitters between runs is a bug users will screenshot, so on-the-fly compute must still be deterministic: enumerate wherever feasible; where MC is needed, use a **fixed seed + enough iterations that the 95% CI < 0.5%**, so the same spot always yields the same grade. (Fixed-seed live compute gives determinism without a stored-benchmark data model.)

**Precompute vs compute:** precompute the *evaluator tables* (small, perfect-hash) and the *preflop all-in matchup grid* (tiny, instant — nice for Math Drills). Do **not** try to precompute full equity — it depends on ranges and boards.

**Cost & latency:** HU equity-vs-range is cheap (enumerate). 8-way needs MC and more samples for stability. **Latency budget: <100ms target after commit, 200ms hard ceiling** — trivially met on A-series silicon. **Threading:** run the compute on a background task/actor; the decide-first loop hands you a free window — **start computing the instant the spot is dealt, while the user is thinking**, so the reveal is already done when it animates. The UI never blocks because the number is hidden until reveal anyway.

---

## 3. 8-max on a 6.1" screen — **keep 8-max; phase-multiplex the screen**

The three things that "must coexist" — 8 seats, the 13×13 grid, live EV — **never need to be on screen at once.** The decide→reveal loop time-multiplexes the display:

- **Decision phase:** table only — 8 compact seat ovals (position label · stack · last action) around an ellipse, board, hero cards, action bar. No grid, no numbers. This is what every mobile poker client already does at 9-max; it fits fine.
- **Reveal phase:** the table compacts to a top strip; the **grid + EV panel slides up as a bottom sheet**. The 13×13 grid needs ~330pt, which fits a ~390pt-wide screen.
- **Range Read mode** is grid-first by design: betting actions as a compact top timeline, grid as the hero. No conflict.

**Cut to 6-max at launch?** No. The seats fit during the decision phase, and grid/EV live in a separate phase — so the screen problem is solved by the loop, not by amputating the audience's real (8–9 handed home) game. Offer 6-max later as a cheap table-size *option*.

---

## 4. Bot architecture — **ranges as versioned JSON; single-street-lookahead post-flop heuristic that explains itself**

- **Authoring & storage:** a range is a weighted map over hand classes (169) or combos (1326) → **bundled JSON**. An archetype = a **published baseline chart + labeled modifiers** — baseline from GTO Wizard's free 8-max cash ranges (cross-referenced to Upswing's 9-handed RFI), with concrete VPIP/PFR per archetype (Nit 12/9, TAG 20/17, LAG 27/22, Station 40/10, Maniac 55/40). See Research-backed design decisions §C and §E. No backend; ships in the app.
- **Versioning:** `schemaVersion` + `rangeSetVersion` fields. Saved hands/puzzles record which range-set graded them, so Range Read stays reproducible across updates.
- **Post-flop policy:** a **single-street-lookahead heuristic** over legible features — hand-strength bucket vs board (made / draw / air), board texture (wet/dry), position, pot geometry — combined with the archetype's aggression/honesty parameters → an **action distribution**. Deliberately not a solver.
- **Self-explanation:** every bot action carries a `rationale` object (the features + the chosen action + the archetype rule that fired), rendered as plain Korean text ("드라이 보드에서 탑페어, TAG는 약 75% 밸류벳"). Because the policy *is* rule-based, the explanation is derived from the actual decision path — transparency realized, not a post-hoc story. This same declared strategy is what Range Read grades against.
- **Credibility floor:** the bot must (a) never make an absurd play (fold the nuts; call off with air vs obvious strength unless it's the Maniac) and (b) stay consistent with its declared archetype. It does **not** need to be unexploitable — for a home-game-improver audience, a Station that just calls too much is a realistic, useful, explainable opponent. That's an achievable bar (tens of rules per archetype). **Multi-street planning is a rabbit hole → back burner.**

---

## 5. Backend or none — **none, for v1**

Fully free + on-device + no accounts + no purchase ⇒ zero server.

- **Progress:** local (SwiftData / files). **Lab puzzles:** shared as `.glasstable` files via the iOS share sheet — a puzzle is a small JSON blob.
- **Remote puzzle content**, if ever wanted, is a **static JSON on a CDN / GitHub Pages** fetched read-only — still not a "backend." Defer.
- A backend only becomes necessary if you later add cross-device sync, accounts, or paid IAP (receipt validation). None of those are in scope. **Back burner.**

---

## 6. Monetization — **none; free forever, no ads, no IAP**

The developer's intent is fully free. This *removes* an entire subsystem and its risk: no IAP, no receipt validation, no accounts, no paywall seams. **No ads either** — ad networks on a poker app invite gambling-ad policy problems and cheapen the serious study-tool tone that also helps the Korean rating. An optional "tip jar" someday is YAGNI. Because everything is on-device, running cost is ~zero, so free-forever is sustainable.

---

## 7. Korean legal & store compliance — **not a legality wall; a rating-track problem; frame as a study tool**

Full findings in `risks.md`. Summary:

- **No hard block.** No real money / no cashout ⇒ **not** 사행성게임물 (illegal gambling requires property gain/loss). No purchasable chips ⇒ the 웹보드게임 payment-cap / opponent-selection regime has nothing to attach to. Both escape cleanly.
- **The one thing to plan for:** a *realistic betting-centric* poker app risks a **청소년이용불가 (adults-only) / KR-19** rating, which is barred from Apple's self-rating track and forces a **direct GRAC review + a Rating Classification Number** in App Store Connect before Korean distribution. Administrative (~10–15 business days + fee + gameplay video), not a wall.
- **The lever is presentation.** Apple's age rating turns on your questionnaire answer: "Frequent/Intense Simulated Gambling" → 17+/KR-19 → GRAC number required; "Infrequent/Mild" → 12+/KR-15, self-rating, no GRAC number. **The more Glass Table reads as calculators / equity-EV / range drills and the less it depicts theatrical chip-betting, the lower the rating and the cleaner the launch** — which independently confirms Math Drills first.
- **Recommendation:** design toward the study-tool signal; target KR-12/KR-15 self-rating; budget a direct GRAC review as the fallback; have a Korean game-law firm confirm the rating class before committing to the self-rating track (no precedent ruling exists for a no-money educational trainer).

---

## 8. Curriculum — **fundamentals → ranges → exploitation, gated but skippable**

The order a strong player actually had to learn, mapped to the plateau each stage breaks:

1. **Equity intuition** — which hands beat which and roughly how often (AK vs QQ is a coinflip).
2. **Outs & rule of 2/4** — counting outs, estimating improvement.
3. **Pot odds** — is a call profitable? equity vs price. *(This + outs is the bedrock; most beginners fold winners and make curiosity-calls here.)*
4. **Position & preflop ranges** — why position matters; opening ranges by seat (8-max). *Beginners play too many hands out of position.*
5. **Ranges as a concept** — stop thinking "he has AK," start thinking "his range is {…}." The core mental shift.
6. **Equity vs a range** — your equity is against a distribution, not one hand.
7. **Board texture** — who does this flop favor?
8. **Value vs bluff; c-betting** — why we bet.
9. **MDF & bluff-catching; blockers** — how much you must defend.
10. **Fold equity & semi-bluffing** — combining equity with fold%.
11. **Exploit deviations** — over-fold vs the Nit, never bluff the Station, value-bet thin. The read-and-punish layer.
12. **Multi-street planning / EV of lines** — advanced, back-burner.

**Unlocks:** Math Drills expose the primitives (1–3, 9) first; Range Read unlocks after "ranges as a concept" (5–6); Table after fundamentals (1–10). Gating is **light and skippable** so a curious user can jump ahead. Mode→plateau map: outcome bias → Run It 1000×; single-hand thinking → Range Read; curiosity-calls → Math Drills pot-odds.

---

## 9. v1 scope cut — **Math Drills ships first**

The one mode that ships first: **Math Drills** — outs/rule-of-2·4, pot odds, and call/fold-vs-price. It is a complete, useful app on its own; it's the most mobile-native and highest-retention mode; and it carries the **lowest gambling-simulation signal** (best Korean rating path). Since the app is free, "smallest thing still worth it" reads as *smallest thing worth keeping on your phone and opening daily* — daily math reps are exactly that. Critically, it forces the correctness-proven equity core and the whole submission pipeline into existence before the risky betting-table UI.

---

## 10. Correctness — **golden fixtures + reference cross-check + property tests + determinism; blocks Milestone 1**

If the numbers are ever wrong, the product is worthless. The proof strategy:

- **Golden test vectors:** hard-code classic published matchup equities and assert the engine matches within tolerance — **AA vs KK ≈ 82.4/17.6, QQ vs AKs ≈ 54/46, QQ vs AKo ≈ 56.3/43.7, AK vs AQ ≈ 74/26, 77 vs AKo ≈ 55/45.** Sources for the canonical numbers: twodimes.net, pokerology heads-up match-ups table, primedope, Wikipedia poker-probability. Sanity-check ~a dozen self-generated spots against these before mass-generating fixtures.
- **Two independent reference oracles** (different codebases so bugs don't correlate), used at dev time only — never shipped: **eval7 (Python, MIT)** as primary — trivial `pip install`, real equity API with PokerStove range strings, easy to dump 10k spots to golden JSON; **OMPEval (C++, ISC)** as the trustworthiness anchor with an exact multiway/range `EquityCalculator`. The Swift engine ships only if it matches *both* on the fixture set (exact for small-N, ±0.1–0.3% tolerance for MC). If the two oracles ever disagree, that boundary case becomes a hard-coded vector. (poker-eval is GPL + abandoned; PokerStove/Odds Oracle are closed/paid — spot-check only, don't build the pipeline on them.)
- **Evaluator validation:** confirm the from-scratch evaluator sorts 7-card hands into the correct 7462 equivalence classes against eval7/phevaluator, on a full or sampled sweep (compare *relative order*, since absolute rank integers differ between schemes).
- **Design reference for the from-scratch evaluator:** phevaluator's quinary (base-5) perfect-hash design (~100KB tables) — study its `Algorithm.md` as the spec; Cactus Kev for the foundational 5-card 7462-class trick.
- **Property tests:** equities in a pot sum to 100%; monotonicity (a hand never has less equity than one it dominates); enumeration ≈ MC within the CI; better hand always ranks ≥.
- **Determinism test:** the same spot always yields the same graded benchmark, computed on the fly (enumeration or fixed-seed MC).

This work is **Milestone-1-blocking** — the drills are worthless if their pot-odds/equity math isn't provably right.

---

## Research-backed design decisions

Finer-grained calls settled by research (see `open-questions.md` for what each resolved). All match established convention so they need no in-app explaining.

### A. Bet-sizing UX — **preset % -pot buttons, pro unit on top, chips underneath; no slider**

Every serious tool (GTO Wizard, PokerSnowie, DTO, APT) *and* every real client (PokerStars, GGPoker) converged here. The engine keeps its fixed % -pot menu (33/50/75/100/150% + all-in); the UI shows each entry as a preset button:

- **Headline = the pro unit:** **% of pot postflop, big blinds preflop** ("2.5x / 3x"). This bb-preflop / %-pot-postflop split is exactly PokerStars' convention and how serious players reason.
- **Sub-label = resolved chip amount** (dim), so a beginner never does pot math — satisfies the "I expect a chip count" instinct without abandoning the pro unit.
- Label 100% as **"Pot"**, top size as **"All-in"** (universal wording).
- **No slider.** GGPoker warns sliders cause mobile misclicks; APT users found them "distracting and slow." And since the bots only understand the fixed menu, a free slider would let the hero pick sizes the bots can't reason about — dead flexibility. Cut for v1.

### B. Range-grid (13×13) display — **universal matrix conventions**

Pairs on the diagonal (AA→22), **suited in the upper-right triangle, offsuit in the lower-left.** **Color = action:** red = raise/3-bet, green = call, gray = fold. **Mixed strategies = proportional split-fill cells** (a half-red/half-gray cell = raise ~50% / fold ~50%) — don't collapse frequencies to one color. Identical across every tool, so users need no orientation. This is the Range Read canvas.

### C. Archetype parameters — **VPIP/PFR to ship (from the literature)**

| Archetype | VPIP | PFR | Character |
|---|---|---|---|
| **Nit** | 12 | 9 | tight-passive |
| **TAG** | 20 | 17 | tight-aggressive |
| **LAG** | 27 | 22 | loose-aggressive |
| **Calling Station** | 40 | 10 | loose-passive (huge VPIP–PFR gap) |
| **Maniac** | 55 | 40 | loose + hyper-aggressive |

The defining discriminator is the **VPIP–PFR gap** (tiny for TAG/LAG, 20+ for the Station). These sit inside the cited ranges (mypokercoaching, pokercoaching, natural8, pokerology).

### D. Grading feedback format — **EV loss in bb + soft severity bands**

For **Table / Range** (exploit grade): lead with **EV loss in big blinds** (continuous and honest, not a demoralizing binary), mapped to a **three-band soft severity** — Optimal/near-optimal → Inaccuracy → Mistake/Blunder (~2bb threshold, à la PokerSnowie) — plus a rolling accuracy % / EV-loss-per-hand for progress. This is GTO Wizard's and PokerSnowie's proven pattern. For **Math Drills** (math grade), grade on answer-correctness and **estimation-error bands** ("정확 / 근접 / 빗나감" — spot-on / close / off) rather than bare 정답/오답, so estimation feels like calibration, not pass/fail. "Decide first, then reveal" is justified in-app by **active recall + progressive disclosure** (Nielsen / NN-group) — the app's transparency thesis made explicit.

### E. Baseline range source & IP — **cite methodology, generate own values, disclose the 8-handed interpolation**

Primary 8-max baseline: **GTO Wizard's free 8-max cash ranges** (only public source that names 8-max). Full-ring cross-reference: **Upswing's free 9-handed RFI PDF.** No canonical *8-handed* chart exists publicly, so an 8-handed opening range is interpolated (slightly wider than 9-max UTG, tighter than 6-max) — **and the app discloses that it did so.** That disclosure *is* the transparency feature. **IP caution:** cite these as the methodology/baseline validated against; **generate our own range values** rather than shipping competitors' PDFs verbatim.

### F. Korean terminology — **actions Hangul, jargon/acronyms English, some concept terms bilingual**

Confirmed against real Korean sources (pokergosu, CoinPoker KR glossary, namu.wiki). Actions/streets always Hangul (콜/레이즈/폴드/체크/벳/올인/프리플랍/플랍/턴/리버); acronyms and positions stay Latin (GTO, EV, MDF, SB/BB/UTG/HJ/CO/BTN); **3벳/4벳** = digit + Hangul; **TAG/LAG stay Latin** (Hangul 태그/래그 collide with everyday "tag"/"lag"); learning-critical concept terms shown **bilingually** (에퀴티/Equity, 팟 오즈/Pot odds, 블로커/Blocker) since users meet them in English solver tools. Use 플랍 (not 플롭) for community feel. Full glossary is built during UI-copy work.
