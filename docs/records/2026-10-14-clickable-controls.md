# Clickable things must look clickable

- **Date:** 2026-10-14
- **Kind:** feature notes
- **Originals:** `.scratch/clickable-controls-2026-10-14/map.md` (tracked: `git show f5c5e22:.scratch/clickable-controls-2026-10-14/map.md`)
- **Asked by / for:** owner, feedback on build 26; branch `feat/guide-clickable-controls`

## What it was
The working map for the owner's request that every tappable control look tappable, and
for the app-wide rule on back, Previous and Close. It held the inventory, the mock rounds
and the owner's picks, then what was built.

## Findings and decisions
- Inventory (code read 2026-10-14): 31 tappable controls were bare text or a bare icon.
  `ChromeButton` (25 close, 3 back) and `ChromeTextButton` (3 Skip) drew no container. No
  shared link style; about 14 sites repeated a bare `Text` + `minHeight: 44` by hand.
  Previous-step controls were: guide header (text), Hold'em basics (glyph under ✕),
  walkthrough, hand review and learning guide (bottom button beside Next).
- Guide wrong-answer panel stopped repeating "Your answer / Correct answer" (`aaaae26`),
  because the cards already mark the answer.
- Guide header mocks A to D (KO/EN), https://claude.ai/artifact/LkbEC1GPeW2AyWPvw7dSLF:
  owner preferred C (round back arrow top left, outlined Skip top right), fallback A, and
  asked for one rule for the whole app.
- App-wide rules on five screens, https://claude.ai/artifact/Q3MRVVVd7Qc4noGgkmzhx2.
  Rule 1: top-left always leaves, Previous beside Next (recommended). Rule 2: option C in
  the guide, ✕ and ‹ side by side elsewhere. Rule 3: left steps back, every exit moves
  right. **Owner chose Rule 1** and asked for more looks (the mock arrow was a text glyph,
  off-centre in its circle).
- Five looks for ✕, ‹, ••• and Skip (glyphs as centred shapes, 40pt button, left edge on
  the 18pt content edge), https://claude.ai/artifact/Tb5PRceX4YUUPoTJwAffKr: outlined
  circle, outlined rounded square (recommended), soft filled square, felt-green tile,
  chip. **Owner chose Look 2** and asked whether Look 5's gold border was too much.
- Look 2 gold-border variants (A double ring, B one gold line, C grey outline with gold
  hairline), https://claude.ai/artifact/BdUFji5QcrzLN9K16YKDJY. Recommended plain Look 2
  or B. **Owner, 2026-10-14: "look two with the gray outline"**; gold stays for main
  buttons and things that need attention.

## Outcome
Built as Rule 1 + Look 2 (commit `43692c9`, shipped in build 27, source `10744ab`):
- `GTControlBackground` gives the secondary fill and grey border. `ChromeGlyph` (40pt
  tile, 44pt target, tile edge on the content edge) draws every ✕, ‹ and •••;
  `ChromeTextButton` and `GTOutlinedAction` draw Skip and other text actions.
- `GTChromeBar`: content starts 8pt under the tile, so screens with a top bar start about
  15pt lower (sheets: tile 10pt below the sheet edge). Lessons dropped their own 8pt top
  padding, so the title sits 8pt under the tile at every text size.
- `GTStepRow`: Previous (36% width) beside the bottom action, stacked at accessibility
  sizes. Guide: on every step after the first, also beside "Show me first". Hold'em
  basics: under the choices and beside the finish button. Walkthrough, hand review and
  learning guide keep equal-width Previous/Next. The guide and Hold'em basics lost their
  top-left Previous (this settles the guide-header question above).
- Outlined: guide and lesson Skip, Play ••• and raise back, Play help ↻, Skip to result,
  Review the whole game, 1:1 table Chart / Opponent rules / Back / Change opponent, Show
  poker terms, Show chart, Keep the chart open, Compare a representative, Enlarge and
  explore hands, Return to my hand, Open Settings, recovery Export / Start again, Records
  topic picker, lesson ⓘ (normal and accessibility sizes).
- Left unchanged (already show an affordance): disclosure rows ("How to work it out",
  "See the full chart", "See the calculation"), Records stuck-skill rows (play glyph),
  the pot-math capsules.
- Side effects recorded in the handoff: the Play top-bar title stops growing at the first
  accessibility size to keep AX dock tests passing; the AX test helper
  `scrollUntilFullyVisible` now ends with short drags.

## Still open
Nothing in this map. The rule is now a project convention (recorded in the agent handoff).
