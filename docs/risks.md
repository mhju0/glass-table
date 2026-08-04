# Glass Table — Risks

Each risk with a concrete mitigation. Severity is relative to a solo, full-time, free, on-device project.

## Technical

| Risk | Severity | Mitigation |
|---|---|---|
| **Post-flop bot is a caricature** the audience grinds in 50 hands, making "what does his call mean?" provably-correct-but-useless. | **High** (the credibility floor) | *Mitigation shipped as designed (R4-S3/S4):* the bot is a printable per-archetype bucket table, deterministic so its actions invert into ranges, grades always labeled vs the archetype. The residual risk is now empirical — whether real play finds the caricature *useful* — and is dogfood territory. Slowplay rows and deeper streets are pinned by tests as explicit future work. |
| **Engine math is wrong** → the whole product is worthless. | **High** | *Standing gate, in CI:* golden fixtures + dual reference-oracle cross-check + property tests + determinism, run in release config (`engine-gate.yml`, weekly + on engine paths). 92 tests at last gate. |
| **Grades jitter** between runs on the same spot (Monte Carlo variance). | Medium | Enumerate wherever feasible; where MC is needed, fixed seed + CI<0.5%; **store the benchmark with the puzzle** so a spot always grades identically. |
| **App bundle bloated** by a giant evaluator table (123 MB two-plus-two). | Medium | Use a perfect-hash evaluator (~few MB, or generated at first launch). Reject the 123 MB table. |
| **UI blocks** during 8-way equity compute. | Low | Compute on a background task, *started when the spot is dealt* (during the user's think-time); reveal is already done when it animates. Budget <100ms, ceiling 200ms — easily met on A-series. |
| ~~**Learning Swift from zero** stalls velocity.~~ | — | Retired: M1 and the full revamp shipped; the platform is learned. |

## Legal & store

| Risk | Severity | Mitigation |
|---|---|---|
| **Korean adults-only (청소년이용불가 / KR-19) rating**, which is barred from Apple self-rating and forces a direct GRAC review + Rating Classification Number before KR distribution. | **Medium — the one to plan for** | Design toward the *study-tool* signal (calculators, equity/EV, drills; chips understated) to aim for "Infrequent/Mild" → KR-12/KR-15 self-rating. Budget a direct GRAC review (~10–15 business days + fee + gameplay video) as the fallback — it's administrative, not a wall; ordinary poker with normal rules is explicitly *rateable, not refused*. Ship Math Drills first (lowest gambling signal) to validate the rating path early. |
| **Apple simulated-gambling flag** → 17+ globally / KR-19, requiring a GRAC number. | Medium | Answer Apple's age questionnaire honestly; keep betting depiction genuinely incidental so "Infrequent/Mild" is defensible. |
| **No precedent** for a no-money educational trainer's exact rating class. | Low–Medium | Korean game-law firm confirms the rating class before committing to the self-rating track (P3 open item). Peer trainers appear to coexist on the store (suggestive, not confirmed). |
| Misclassified as 사행성게임물 / 웹보드게임 payment regime. | **Very low** | Structurally escaped: no property gain/loss (사행성 requires it), no purchasable chips (웹보드 payment/opponent regime has nothing to attach to). Keep it that way — never add purchasable currency or cashout. |
| Evaluator/library **license incompatibility** with a free closed-source app. | Low | Confirm the license of any ported evaluator/reference before shipping (P1 open item). |

## Product

| Risk | Severity | Mitigation |
|---|---|---|
| **Archetype ranges lack credibility** (no in-house pro validator). | Medium | Derive our own values from stated rules and benchmark against **Upswing's free 9-handed RFI + PokerCoaching's free charts** — never GTO Wizard, which is the named competitor (`decisions.md` §E, amended 2026-08-03). Archetypes are labeled VPIP/PFR deviations; the 8-handed interpolation and the defend-chart derivation are both disclosed in-app — that disclosure *is* the transparency feature. |
| **Range-content IP** — reproducing competitors' exact range files. | Medium | Cite the public charts as *methodology/baseline validated against*; **generate our own range values**; don't ship competitors' PDFs verbatim. Disclose the interpolation. |
| **Grading the wrong thing** — teaching users to beat *this bot* instead of poker. | Medium | Two-tier grade: math grade (objective) for fundamentals; exploit grade always labeled "vs a LAG," never "universally correct." Never grade Table decisions as GTO truth. |
| **Localization errors / awkward jargon** alienate the Korean audience. | Medium | Korean-first with a developer-owned terminology glossary; keep only the English jargon Korean players actually use. |
| **6.1" screen can't hold 8 seats + grid + EV.** | Low (solved) | Phase-multiplexing: table-only decision phase, grid+EV reveal sheet. Never rendered simultaneously. |

## Scope & execution

| Risk | Severity | Mitigation |
|---|---|---|
| ~~**"All three modes" scope trap** for a solo dev.~~ | — | Retired: all three modes shipped slice-by-slice (M1 2026-07-23; R1–R5b 2026-08-03/04), each slice independently green. |
| **Feature creep** into deferred rabbit holes (multi-street bot, backend, monetization, continuous sizing, rake). | Medium | All explicitly non-goals in `product-brief.md`; each has a named back-burner trigger. Revisit only on evidence, not vibes. |
| **Never shipping** (polishing forever pre-launch). | Medium | Milestone 1 is a real, submittable, complete app by itself. Ship it to the store before building Range Read. |
| **Free-forever unsustainable.** | Very low | On-device, no infra cost, no ads, no accounts → burn is ~zero. Optional tip-jar is a deferred, not-needed lever. |
