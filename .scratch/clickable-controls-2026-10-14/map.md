# Clickable things must look clickable, 2026-10-14 (owner, build 26)

Branch `feat/guide-clickable-controls`.

## Done

1. Guide wrong-answer panel no longer repeats "Your answer / Correct answer"
   (`aaaae26`); the cards already mark the answer.

## Waiting on the owner

2. Guide header: Previous and Skip are bare text side by side. Mocks A to D, Korean and
   English: https://claude.ai/artifact/LkbEC1GPeW2AyWPvw7dSLF. Owner prefers C (round
   back arrow top left, outlined Skip top right), falls back to A, and wants one rule for
   the whole app.
3. App-wide rules for back, Previous and Close on five screens:
   https://claude.ai/artifact/Q3MRVVVd7Qc4noGgkmzhx2. Rule 1: top-left always leaves,
   Previous beside Next (recommended). Rule 2: option C in the guide, ✕ and ‹ side by
   side elsewhere. Rule 3: left steps back, every exit moves right.

## Inventory (code read 2026-10-14)

- 31 tappable controls are bare text or a bare icon; `ChromeButton` (25 close, 3 back)
  and `ChromeTextButton` (3 Skip) draw no container. No shared link style exists; about
  14 sites repeat a bare `Text` + `minHeight: 44` by hand.
- Previous-step controls today: guide header (text), Hold'em basics (glyph under ✕),
  walkthrough, hand review and learning guide (bottom button beside Next).
