# Clickable things must look clickable, 2026-10-14 (owner, build 26)

Branch `feat/guide-clickable-controls`.

## Done

1. Guide wrong-answer panel no longer repeats "Your answer / Correct answer"
   (`aaaae26`); the cards already mark the answer.

2. Rule 1 with Look 2, built (owner, 2026-10-14: "look two with the gray outline";
   gold stays for main buttons and things that need attention):
   - `GTControlBackground`: the secondary button's fill and grey border. `ChromeGlyph`
     (40pt tile, 44pt target, tile edge on the content edge) draws every ✕, ‹ and •••;
     `ChromeTextButton` and `GTOutlinedAction` draw Skip and the other text actions.
   - `GTChromeBar`: content starts 8pt under the tile, so screens with a top bar start
     about 15pt lower than before (sheets: tile 10pt below the sheet edge). Lessons
     dropped their own 8pt top padding, which the old bar's overhang used to absorb, so
     the title sits 8pt under the tile at every text size.
   - `GTStepRow`: Previous (36%) beside the bottom action, stacked at accessibility
     sizes. Guide: on every step after the first, also beside "Show me first". Hold'em
     basics: under the choices and beside the finish button. Older flows (walkthrough,
     hand review, learning guide) keep their equal-width Previous/Next.
   - Outlined: guide and lesson Skip, Play ••• and raise back, Play help ↻, Skip to
     result, Review the whole game, 1:1 table Chart / Opponent rules / Back / Change
     opponent, Show poker terms, Show chart, Keep the chart open, Compare a
     representative, Enlarge and explore hands, Return to my hand, Open Settings,
     recovery Export / Start again, Records topic picker, lesson ⓘ (normal and
     accessibility sizes).
   - Left as they were (already show an affordance): disclosure rows ("How to work it
     out", "See the full chart", "See the calculation"), Records stuck-skill rows (play
     glyph), the pot-math capsules.

## Waiting on the owner

2b. Guide header: Previous and Skip are bare text side by side. Mocks A to D, Korean and
   English: https://claude.ai/artifact/LkbEC1GPeW2AyWPvw7dSLF. Owner prefers C (round
   back arrow top left, outlined Skip top right), falls back to A, and wants one rule for
   the whole app.
3. App-wide rules for back, Previous and Close on five screens:
   https://claude.ai/artifact/Q3MRVVVd7Qc4noGgkmzhx2. Rule 1: top-left always leaves,
   Previous beside Next (recommended). Rule 2: option C in the guide, ✕ and ‹ side by
   side elsewhere. Rule 3: left steps back, every exit moves right.
   **Owner chose Rule 1** and asked for more looks for ✕ and ‹: the mock's arrow was a
   text glyph and sat off-centre in its circle.
4. Five looks for ✕, ‹, ••• and Skip under Rule 1 (glyphs drawn as centred shapes, 40pt
   button, left edge on the 18pt content edge):
   https://claude.ai/artifact/Tb5PRceX4YUUPoTJwAffKr. Outlined circle, outlined rounded
   square (recommended), soft filled square, felt-green tile, chip. No app code changes
   until a look is picked.
   **Owner chose Look 2** and asked whether Look 5's gold border on that shape is too much.
5. Look 2 with gold borders (A: Look 5's double ring, B: one gold line, C: grey outline
   with a gold hairline inside): https://claude.ai/artifact/BdUFji5QcrzLN9K16YKDJY. Recommended:
   plain Look 2, or B if gold is wanted.

## Inventory (code read 2026-10-14)

- 31 tappable controls are bare text or a bare icon; `ChromeButton` (25 close, 3 back)
  and `ChromeTextButton` (3 Skip) draw no container. No shared link style exists; about
  14 sites repeat a bare `Text` + `minHeight: 44` by hand.
- Previous-step controls today: guide header (text), Hold'em basics (glyph under ✕),
  walkthrough, hand review and learning guide (bottom button beside Next).
