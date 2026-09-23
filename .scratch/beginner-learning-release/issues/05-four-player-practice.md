# Build four-player practice and factual hand review

Status: implemented
Type: task
Original dependencies (satisfied): 01 owner approval, 03
Risk: Class 3

Separate integer-chip rules engine and blinded bots from the existing graded
heads-up exercise. Follow [spec](../spec.md) for 100-chip seats, 1/2 blinds,
rotation/refills, persistence and post-hand hindsight reveal.
Use short Korean/English opponent titles with one-line descriptions. Keep exactly
five vertical stationary rows at all widths. Open a stable bottom sheet for only
the selected opponent's two preflop tendency scales; Back/Escape/backdrop restore
focus and scroll, and the background becomes inert. Preserve the current
Archetype VPIP/PFR values and disclose those technical settings on demand; do not
present them as observed four-player results or an aggression ranking. Label the
three bot seats Computer 1/2/3 in both languages.

Acceptance: authoritative fixtures for raises/reopening/side pots/returns/ties,
seeded legal-action/chip-conservation tests, bot hidden-card isolation, save/resume
at every decision/settlement boundary, no reroll or duplicate payout. Native
compact/AX5 table/review and interrupted-play checks. No unvalidated action grades.
Check all five opponents, both scale values against the published policy and
sheet scrolling, focus and dismissal at compact/AX5 and wide sizes.
Independent Class-3 frozen-candidate review required before integration.

## Delivery, 2026-09-23

The pure-Swift four-seat rules, blinded authored bots, carried/refilled stacks,
atomic hand resume and factual replay are implemented separately from the graded
heads-up lesson. Betting, short-all-in reopening, side pots, refunds, ties and
replay were exercised by package and native UI tests. The Class-3 frozen-code
review accepted the candidate. Phone play and novice comprehension still need
human acceptance. See the
[delivery record](../../../docs/specs/2026-09-23-beginner-native-release.md).
