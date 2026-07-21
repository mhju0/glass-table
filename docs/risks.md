# Glass Table — Risks

Each risk with a concrete mitigation. Severity is relative to a solo, full-time, free, on-device project.

## Technical

| Risk | Severity | Mitigation |
|---|---|---|
| **Post-flop bot is a caricature** the audience grinds in 50 hands, making "what does his call mean?" provably-correct-but-useless. | **High** (the credibility floor) | Sequence Table *last*. Set the bar at "consistent with its declared archetype + never absurd," not "unexploitable" — achievable for a home-game-improver audience. Single-street-lookahead heuristic with legible features; defer multi-street planning. The bot's self-explanation is derived from its actual decision path, so it can't lie about itself. |
| **Engine math is wrong** → the whole product is worthless. | **High** | Golden fixtures (published matchup equities) + cross-check vs an open reference calculator on a random-spot batch + property tests (sum-to-100%, monotonicity, enum≈MC) + determinism test. Blocks Milestone 1. See `decisions.md` §10. |
| **Grades jitter** between runs on the same spot (Monte Carlo variance). | Medium | Enumerate wherever feasible; where MC is needed, fixed seed + CI<0.5%; **store the benchmark with the puzzle** so a spot always grades identically. |
| **App bundle bloated** by a giant evaluator table (123 MB two-plus-two). | Medium | Use a perfect-hash evaluator (~few MB, or generated at first launch). Reject the 123 MB table. |
| **UI blocks** during 8-way equity compute. | Low | Compute on a background task, *started when the spot is dealt* (during the user's think-time); reveal is already done when it animates. Budget <100ms, ceiling 200ms — easily met on A-series. |
| **Learning Swift from zero** stalls velocity. | Medium | Full-time makes it affordable; Milestone 1 (Math Drills) is deliberately the smallest surface to learn the platform + submission pipeline on before the hard UI. |

## Legal & store

| Risk | Severity | Mitigation |
|---|---|---|
| **Korean adults-only (청소년이용불가 / KR-19) rating**, which is barred from Apple self-rating and forces a direct GRAC review + Rating Classification Number before KR distribution. | **Medium — the one to plan for** | Design toward the *study-tool* signal (calculators, equity/EV, drills; chips understated) to aim for "Infrequent/Mild" → KR-12/KR-15 self-rating. Budget a direct GRAC review (~10–15 business days + fee + gameplay video) as the fallback — it's administrative, not a wall; ordinary poker with normal rules is explicitly *rateable, not refused*. Ship Math Drills first (lowest gambling signal) to validate the rating path early. |
| **Apple simulated-gambling flag** → 17+ globally / KR-19, requiring a GRAC number. | Medium | Answer Apple's age questionnaire honestly; keep betting depiction genuinely incidental so "Infrequent/Mild" is defensible. |
| **No precedent** for a no-money educational trainer's exact rating class. | Low–Medium | Korean game-law firm confirms the rating class before committing to the self-rating track (P3 open item). Peer trainers appear to coexist on the store (suggestive, not confirmed). |
| Misclassified as 사행성게임물 / 웹보드게임 payment regime. | **Very low** | Structurally escaped: no property gain/loss (사행성 requires it), no purchasable chips (웹보드 payment/opponent regime has nothing to attach to). Keep it that way — never add purchasable currency or cashout. |
| Evaluator/library **license incompatibility** with a free MIT app. | Low | Confirm the license of any ported evaluator/reference before shipping (P1 open item). |

## Product

| Risk | Severity | Mitigation |
|---|---|---|
| **Archetype ranges lack credibility** (no in-house pro validator). | Medium | Baseline from reputable, citable public charts — **GTO Wizard free 8-max cash** (primary) + **Upswing 9-handed RFI** (full-ring cross-ref) — with archetypes as labeled deviations (VPIP/PFR in `decisions.md` §C). No public 8-*handed* chart exists, so the 8-handed range is interpolated and **the app says so** — that disclosure *is* the transparency feature. |
| **Range-content IP** — reproducing competitors' exact range files. | Medium | Cite the public charts as *methodology/baseline validated against*; **generate our own range values**; don't ship competitors' PDFs verbatim. Disclose the interpolation. |
| **Grading the wrong thing** — teaching users to beat *this bot* instead of poker. | Medium | Two-tier grade: math grade (objective) for fundamentals; exploit grade always labeled "vs a LAG," never "universally correct." Never grade Table decisions as GTO truth. |
| **Localization errors / awkward jargon** alienate the Korean audience. | Medium | Korean-first with a developer-owned terminology glossary; keep only the English jargon Korean players actually use. |
| **6.1" screen can't hold 8 seats + grid + EV.** | Low (solved) | Phase-multiplexing: table-only decision phase, grid+EV reveal sheet. Never rendered simultaneously. |

## Scope & execution

| Risk | Severity | Mitigation |
|---|---|---|
| **"All three modes" scope trap** for a solo dev. | **High** | Enforced build order Drills → Read → Table; each independently shippable. "All three" is the destination, not the first release. |
| **Feature creep** into deferred rabbit holes (multi-street bot, backend, monetization, continuous sizing, rake). | Medium | All explicitly non-goals in `product-brief.md`; each has a named back-burner trigger. Revisit only on evidence, not vibes. |
| **Never shipping** (polishing forever pre-launch). | Medium | Milestone 1 is a real, submittable, complete app by itself. Ship it to the store before building Range Read. |
| **Free-forever unsustainable.** | Very low | On-device, no infra cost, no ads, no accounts → burn is ~zero. Optional tip-jar is a deferred, not-needed lever. |
