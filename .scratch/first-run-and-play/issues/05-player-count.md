# 2 and 3 player free tables

Status: done
Type: task
Blocked by: 04

The practice table assumes four seats in state, validation, blinds and dealer
rotation. Two-handed play needs the heads-up blind rule. Saved tables must stay
readable. Owner chose to do this after 04.

## Outcome (2026-09-25, delegated autonomy)

- `PracticeTableState` seats `styles.count + 1` players (1–3 styles). Heads-up:
  the button posts the small blind and acts first preflop; the big blind acts first
  after the flop. Board cards come after the dealt hole cards.
- Saved tables: no new fields. A four-seat deal is byte-identical (fingerprint
  test `fourSeatDealIsUnchanged`), so existing saves validate and replay.
- App: 인원 segmented control (2명/3명/4명, default 4) in `TableSetupView`;
  the table draws 2/3/4 seats, and the title says 두/세/네 명의 연습 테이블.
- Tests: `PracticeTableSeatCountTests` (Drills) and
  `testTwoPlayerTableSeatsOneComputer` (UI).
