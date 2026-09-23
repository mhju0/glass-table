# Build four-player practice and factual hand review

Status: needs-info
Type: task
Blocked by: 01 owner approval, 03
Risk: Class 3

Separate integer-chip rules engine and blinded bots from the existing graded
heads-up exercise. Follow [spec](../spec.md) for 100-chip seats, 1/2 blinds,
rotation/refills, persistence and post-hand hindsight reveal.

Acceptance: authoritative fixtures for raises/reopening/side pots/returns/ties,
seeded legal-action/chip-conservation tests, bot hidden-card isolation, save/resume
at every decision/settlement boundary, no reroll or duplicate payout. Native
compact/AX5 table/review and interrupted-play checks. No unvalidated action grades.
Independent Class-3 frozen-candidate review required before integration.
