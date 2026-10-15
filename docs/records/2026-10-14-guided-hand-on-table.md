# "A hand together" rebuilt on the Play table

- **Date:** 2026-10-14
- **Kind:** feature notes
- **Originals:** `.scratch/guided-hand-2026-10-14/map.md` (tracked: `git show f5c5e22:.scratch/guided-hand-2026-10-14/map.md`)
- **Asked by / for:** owner, complaints about build 25; branch `feat/guided-hand-on-table`

## What it was
Notes for rebuilding the guided hand ("A hand together") as a real hand on the shared
Play table. Options report with five mocks, A to E:
https://claude.ai/artifact/45hN7vNa15ru28nfsHovcR

## Findings and decisions
- Owner's complaints (build 25): UI not fluid; button text broke over lines ("No
  additional chips", "Opponent wins", "Split the pot"); the questions gave no freedom;
  the question was plain black text and hard to find.
- Owner chose "the mix of B and A":
  - B, coach beside you: a real hand with the real action buttons. A coach card under the
    table says what just happened (Now), where to look (Look at) and what to think
    (Think). The coach marks its pick on one button. Any legal choice is allowed.
  - A, spotlight: on the first steps the rest of the table is dimmed and the part to look
    at has a gold outline.

## Outcome
Built in `aafc0b5`, shipped in build 26 (source `f4d1fe9` plus bump):
1. One fixed two-player hand on the shared `TableSurface`: learner A♣ K♥, Tom Q♦ J♣,
   board A♦ Q♠ 7♥ 2♣ 3♠, 20 chips each, blinds 1 and 2.
2. Eight steps: seats, blinds, before the flop, flop, turn, river, showdown, review.
3. Buttons are the Play table's `GTActionButton`s: Give up / Add N / Increase when there
   is a bet, Pass / Bet first when there is none. Tom always calls or checks, so all 16
   lines without a fold reach showdown.
4. Giving up asks first, explains what it costs, then ends the hand if confirmed.
5. Review lists the learner's own choice on each street and says the hand is one
   example, not advice for every hand.
6. `TableSurface` gained `spotlight` (dims what is not listed) and `ringed` (gold outline).
- Removed with the old version: quiz questions and verdicts, Previous, the "less help"
  replay and the seeded alternate deals. Replay now restarts the same hand.
- Later (build 28): reworked invitation; swiping it away no longer starts the next
  lesson (`fc90676`).

## Still open
Limits recorded at build time:
- At AX5 the table fills the first screen; the coach card and the buttons are below it,
  and each new step scrolls back to the table.
- The hand is always the same one, and the learner always wins it unless they give up.
- Not tried with a real beginner.
