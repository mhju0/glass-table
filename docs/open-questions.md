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

7. ~~**Which published range charts source the archetypes.**~~ **RESOLVED: GTO Wizard free 8-max cash ranges (primary) + Upswing 9-handed RFI (full-ring cross-ref); 8-handed interpolated and disclosed in-app; cite as methodology and generate own values (IP).** See `decisions.md` §E.
8. **Archetype parameters — opening widths done, post-flop knobs open.** *Resolved:* VPIP/PFR per archetype (Nit 12/9, TAG 20/17, LAG 27/22, Station 40/10, Maniac 55/40; `decisions.md` §C). *Still open:* the per-street continuing/c-bet/bluff frequencies and aggression/honesty knobs — part of the post-flop bot design (see #9).
9. **Post-flop feature definitions (the remaining bot-design task).** The exact hand-strength buckets, board-texture classifier (wet/dry thresholds), and how they map to each archetype's action distribution. *Blocks the post-flop bot (Milestone 3), not Range Read.* This is the one substantive piece of bot design still to specify — I'll drive it when Table planning begins.
10. ~~**Grade presentation & thresholds.**~~ **RESOLVED (format): EV loss in bb + three-band soft severity for Table/Range; estimation-error bands (정확/근접/빗나감) for Math Drills.** See `decisions.md` §D. *(Remaining: exact bb thresholds per band and the Range-grid delta metric — tune during build.)*

## P3 — can wait

11. **GRAC rating-class confirmation (outside counsel).** Have a Korean game-law firm confirm the likely rating class for the actual build before committing to the self-rating track. No precedent ruling exists for a no-money educational trainer. *Needed before Korean submission, not before building.*

*Resolved for M1 (2026-07-23):* proceeding **without** counsel — Math Drills
is the lowest-signal build and the GRAC direct review is an administrative
fallback (spec `docs/specs/2026-07-23-m1-submission-design.md`). Revisit
counsel before the betting-table milestone.

12. **App name / branding in Korean.** Keep the English "Glass Table," use a Korean name (유리 테이블?), or a bilingual lockup. Store listing language.
13. **Design/visual tone.** Study-tool aesthetic (equity/EV forward, chips understated) both for the thesis and for the Korean rating lever — needs a concrete direction before UI polish.
14. **6-max option.** Ship an optional 6-max table size after 8-max Table lands? Cheap, but confirm demand.
15. **Curriculum unlock specifics.** Exact gates (which drills/modes unlock what), and whether progress is per-skill or linear.
16. **Puzzle sharing format.** `.glasstable` file schema and/or URL-encoded share string for Lab puzzles.
