# Numerical audit of build 20 (are the app's numbers correct?)

- **Date:** 2026-10-11
- **Kind:** audit
- **Originals:** `docs/audits/2026-10-11-numerical/` (index.html, findings.json, verification.json, `evidence/math/` probe sources, logs, CSV/JSON, `evidence/root/` inventories and counterexamples), `docs/research/2026-10-11-numerical-claims-inventory.md`, `docs/research/2026-10-11-numerical-math-audit.md`, `docs/research/2026-10-11-numerical-statistics-audit.md`, `docs/research/2026-10-11-poker-numbers-primary-sources.md` (tracked: `git show f5c5e22:<path>`); `.scratch/numerical-audit-2026-10-11/` (local working copy of the same evidence plus AuditRunner `.build/` and a compiled `frequency7` binary, ~116 MB; deleted, not in git)
- **Asked by / for:** owner; check every learner-facing number and probability against independent computation and primary sources before further release work.

## What it was
Read-only audit of source `07054d0` (installed baseline 1.0(20)). Independent probes (Swift AuditRunner, C++ seven-card census, Python summarizer) recomputed hand frequencies, equities, blockers, pot math, charts and chip conservation; a semantic review checked the explanations. No app code, chart policy, saved data or install changed.

## Findings and decisions
Verified (passed):
- Seven-card best-hand census, all 133,784,560 sets, matches Alon's table: high card 23,294,460 (17.411920%), one pair 58,627,800 (43.822546%), two pair 31,433,400 (23.495536%), trips 6,461,620 (4.829870%), straight 6,180,020 (4.619382%), flush 4,047,644 (3.025494%), full house 3,473,184 (2.596102%), quads 224,848 (0.168067%), straight flush excl. royal 37,260 (0.027851%), royal 4,324 (0.003232%). All 2,598,960 five-card hands match (five-card flush 0.196540% must not be used for seven-card lessons).
- 1,000 best-five comparisons and 1,000 exact equities (10 flop, 100 turn, 890 river): zero mismatches; ties count half. Blockers: 25,857 class-count checks over 153 dead-card sets, zero mismatches. 169 classes / 1,326 combos (6/4/12).
- Pot odds, call EV, MDF: 151,500 formula checks passed (call equity = call/(pot after bet + call); EV = equity x final pot - call; MDF = pre-bet pot/(pre-bet pot + bet); no rake, no later betting). Worked examples 4/20, 6/30, 5/20 give 20%, 20%, 25%.
- Monte Carlo: 15 flop spots at 100,000 samples, largest error 0.178303 pp, seeds repeat identically. Free Play: 750 hands (2-4 players, stacks 2/3/7/40/100) and 500 graded heads-up hands conserved chips.
- FSRS: all 21 FSRS-6 defaults, retention 0.9 and 36,500-day cap match official py-fsrs. Wilson 40/100 = 30.94-49.80%; 28/40 = 54.57-81.93%.
- Charts (combo-weighted, RFI target -> combos -> actual %, classes; defend raise/call/fold combos): UTG 15 -> 204 -> 15.3846%, 37; 64/88/1174. UTG+1 17 -> 228 -> 17.1946%, 39; 68/104/1154. LJ 20 -> 270 -> 20.3620%, 47; 88/116/1122. HJ 23 -> 306 -> 23.0769%, 50; 94/138/1094. CO 28 -> 374 -> 28.2051%, 61; 114/168/1044. BTN 42 -> 562 -> 42.3831%, 84; 168/250/908. SB 36 -> 478 -> 36.0483%, 75; 148/214/964. Defend raise band 30% and continue band 75% of the opener's nominal width.
- Archetype VPIP target/actual, PFR target/actual: nit 12/12.3465, 9/9.2652; tag 20/20.3835, 17/17.3023; lag 27/27.4941, 22/22.3659; station 40/40.5732, 10/10.3641; maniac 55/55.3975, 40/40.5732; casual 45/45.5290, 12/12.3465.

Findings (5 teaching defects N01-N05, 2 display defects N06-N07, 5 qualification items N08-N12):
- N01 zero EV called a loss (20bb pot, 10bb bet, 25% equity -> 0bb). Fixed.
- N02 Korean "그중 PFR" implies share of entered hands; VPIP and PFR are both shares of all hands (40/10 example: 25% among entries). Fixed.
- N03 outs lesson can start ahead or tied (seed 0xA0D17 index 35: Js4h vs 3hJh on 8d2sJcAc, hero ahead; index 34 tied; 15 ahead and 22 tied in 1,000-spot probe). Fixed by wording only.
- N04 tied river described as losing (index 116: Qc9c vs 2hJd on 4s9sJsKs, 2s/3s/5s tie on board flush; 63 tying excluded cards in the probe). Fixed.
- N05 "Winning chance" used for tie-inclusive equity. Fixed.
- N06 "review now" shown before the exact due time (day truncation). Fixed.
- N07 detailed day streak stale after a gap. Fixed.
- N08 chart targets vs actual widths (e.g. "top 15%" is 204/1,326 = 15.3846%; overshoot at most 12/1326 = 0.905 pp). Recommend "about 15%". Open.
- N09 "about ±1% error" for 8,000 samples: worst-case SE 0.559 pp, approx. 95% margin 1.096 pp, not a guaranteed bound. Recommend "Estimated from 8,000 samples". Open.
- N10 Chen half points kept for 32 of 169 classes (97o = 4.5) and "ported verbatim" unverified; Porto 2013 reproduction returns integers; original book pages unavailable. Recommend "app-specific Chen-based ranking"; do not change scores. Open.
- N11 starting-hand percentile is a tie-broken rank prefix, not equal-or-better score share (22 -> 27%, A9o -> 34%, both score 5; score>=5 is 538/1326 = 40.573%; 142 of 169 classes affected). Recommend "Top X% in the app's starting-hand ranking". Open.
- N12 0/0 shown when no hands were entered; recommend "No entered hands yet". Wilson math correct. Open.
- Latent model risks (not current defects): M5 mixed range weights dropped on combo expansion (AA:1,22:0.01 evaluates like AA+22: 50.133% vs correct 0.990099%); current ranges are pure 0/1. M6 bet-facing-raise branch averages per-combo best continuation (5bb clairvoyance premium in a 10/5/15 example); unreachable because every policy's raises are a subset of bets.
- Other notes: rule-of-2 is below exact outs/44 by 0.272727 pp per out; 9 outs = 19.1489% next card, 34.9676% over two cards, 9/44 = 20.4545% on the face-up turn drill. 0.5bb/2bb grade bands are app choices, not solver truth. Practice bots classify raw river draws while graded table remaps them to air.
- Decision (agent, in `docs/specs/2026-10-11-numerical-corrections.md`): do not add a behind-only rejection rule to the outs generator, because saved drafts regenerate by seed/index and the loader validates saved grades; N03 is fixed by describing the actual ahead/tied/behind state.

## Outcome
- Audit gates at `07054d0`: Engine release 93 tests, Drills 401 XCTest + 75 Swift Testing, all 128 audited source hashes unchanged.
- N01-N07 fixed in `ce29a53`, verified in bilingual native flows in `21c3907`, shipped in build 21 (`3e219db`). Correction pass: Engine release 95, Drills 415 XCTest + 75 Swift Testing, app 87 XCTest + 46 Swift Testing on iPhone 12 mini sim iOS 26.5; Records UI passed EN/KO x light/dark; the combined call/fold+EV reveal job's result finalization stalled so it is not claimed as a completed invocation.

## Still open
- N08-N12 qualifications (listed in the agent handoff's open issues).
- Graded-flop sampling sensitivity: the graded flop uses 200 samples per opponent combo; the noise is not bounded against the 0.5bb/2bb grade thresholds. Needs comparison of near-threshold decisions against exact runouts or a larger-sample reference.
- Latent M5 (weighted ranges) and M6 (raise continuation) must be revisited before adding partial-weight ranges or check-raising policies.
- Product questions left in the primary-sources note: exact outs/44 vs rule-of-2 for the face-up turn spot; whether any chart label implies solver status; scoping tie equity to heads-up.

Primary sources used: Alon "Poker, Chance and Skill" (Princeton); Cotter, Utah combinatorics Ex. 15; Teofilo/Reis/Cardoso, CISTI 2013 (Porto) Chen reproduction; Krieger bibliography; official py-fsrs.
