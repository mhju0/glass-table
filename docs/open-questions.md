# Glass Table — Open Questions

What still needs the developer's input or outside research, prioritized. P1 blocks or shapes Milestone 1; P2 is needed before Range Read / Table; P3 can wait.

## P1 — needed for Milestone 1 (Math Drills)

1. **Korean terminology glossary.** *Convention confirmed* against real Korean sources — actions/streets → Hangul; acronyms/positions → English; TAG/LAG → Latin; a few concept terms bilingual (`decisions.md` §F, `product-brief.md` Localization). *Remaining:* finalize the full term-by-term glossary during UI-copy work (developer-owned).
2. ~~**Reference oracle for correctness fixtures.**~~ **RESOLVED: two independent oracles — eval7 (Python, MIT) primary + OMPEval (C++, ISC) anchor.** Dev-time only, never shipped. Golden vectors hard-coded from published matchups (AA/KK 82.4/17.6, etc.). See `decisions.md` §10.
3. ~~**Perfect-hash evaluator: port vs. write, and license.**~~ **RESOLVED: written from scratch in Swift.** No third-party evaluator shipped ⇒ no external-license concern. Studying perfect-hash designs as algorithm references only.
4. ~~**Fixed bet-sizing UX & values.**~~ **RESOLVED: preset % -pot buttons — pro unit on top (% pot postflop, bb preflop), resolved chips as a dim sub-label; no slider.** Engine menu 33/50/75/100/150% + all-in; "Pot" and "All-in" as words. See `decisions.md` §A. *(Remaining: confirm the exact menu values — the proposed set is the default.)*
5. ~~**Determinism strategy.**~~ **RESOLVED: compute on the fly, deterministically** (enumeration or fixed-seed MC). No pre-stored benchmark data model.
6. ~~**Milestone-1 drill roster.**~~ **RESOLVED: five drills** — outs/rule-of-2·4, pot odds, call/fold-vs-price, MDF, blocker counting.

## P2 — needed before Range Read / Table

7. ~~**Which published range charts source the archetypes.**~~ **RESOLVED (amended 2026-08-03): derive our own values from a published rule; name Upswing's free 9-handed RFI PDF + PokerCoaching's free charts as the benchmarks checked against, and reproduce neither.** No public chart is redistributable, so adopting one wholesale was never actually available; GTO Wizard is no longer the baseline because it is the named direct competitor. 8-handed interpolation stays disclosed in-app. See `decisions.md` §E and `docs/specs/2026-08-03-r1-progression-shell-design.md` §13.
8. ~~**Archetype parameters — post-flop knobs.**~~ **RESOLVED (2026-08-04): the postflop policy is a printable bucket table per archetype** — bet/call/raise rows over the five made-hand buckets, deterministic on purpose so an observed action inverts into the surviving range; plus a per-archetype continue-share against 3-bets. See `docs/specs/2026-08-04-r4-s3-postflop-policy-design.md` §1 and `2026-08-04-r5-hero-preflop-design.md` §2.
9. ~~**Post-flop feature definitions.**~~ **RESOLVED (2026-08-04): five made-hand buckets (노페어/드로우/약한 페어/탑 페어/투페어 이상) + a derived board-texture classifier**, both engine-level and test-pinned; the policy table maps buckets to actions. See `docs/specs/2026-08-04-r4-s1-board-texture-design.md` §1–3.
10. ~~**Grade presentation & thresholds.**~~ **RESOLVED and shipped:** EV loss in bb with 최선/부정확/실수 at 0.5/2.0bb (R4-S2), estimation bands elsewhere, Winkler-scored intervals feeding calibration. *(Still open: the bb thresholds are absolute, not pot-relative — flagged in the R4-S2 spec as the model's weakest joint; retune from real answers.)*

## P3 — can wait

11. **GRAC rating-class confirmation (outside counsel).** *Now live rather than hypothetical: the 테이블 (betting UI with bb stakes) exists, which is the build the M1-era note said to revisit counsel before submitting.* Have a Korean game-law firm confirm the likely rating class for the actual build before committing to the self-rating track. No precedent ruling exists for a no-money educational trainer. *Needed before Korean submission, not before building.*

*Resolved for M1 (2026-07-23):* proceeding **without** counsel — Math Drills
is the lowest-signal build and the GRAC direct review is an administrative
fallback (spec `docs/specs/2026-07-23-m1-submission-design.md`). Revisit
counsel before the betting-table milestone.

12. **App name / branding in Korean.** Keep the English "Glass Table," use a Korean name (유리 테이블?), or a bilingual lockup. Store listing language.
13. ~~**Design/visual tone.**~~ **RESOLVED: the felt/glass/paper system** — dark table felt, opaque "glass" surfaces, paper card faces; one pinned appearance; every boundary measured to WCAG 3:1. See `decisions.md` §G.
14. **6-max option.** Ship an optional 6-max table size after 8-max Table lands? Cheap, but confirm demand.
15. ~~**Curriculum unlock specifics.**~~ **RESOLVED (R1): strictly linear path, boss nodes as the only route to 숙달, first-run diagnostic can pre-clear.** See `docs/specs/2026-08-03-r1-progression-shell-design.md`.
16. **Puzzle sharing format.** `.glasstable` file schema and/or URL-encoded share string for Lab puzzles.
