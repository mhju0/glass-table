# Traditional card face refinement

## Approved direction

The user selected familiar physical-card faces combined with larger, readable
markings, following the five-app benchmark. This pass applies that direction and
provides actual app renders for review. Centering the previous small horizontal
rank/suit pair did not resolve the unused white space.

## Design intent

- Full upright cards maintain recognition of the object being taught.
- Opposing corner indices make rank and suit explicit without counting pips.
- Traditional center patterns and court artwork use the card face meaningfully.
- Fixed card geometry preserves five-card board fit and ownership consistency.
- The existing warm paper/red-black palette stays consistent with the felt table.
- Spoken card names remain the accessible representation; decorative marks should
  not become separate VoiceOver elements.

## Verification

- Simulator build passed. First-lesson answer/transfer/course flow and all seven
  walkthrough steps at Accessibility XXXL passed (2 focused UI tests, zero
  failures). Log: `/tmp/gt-traditional-cards-ui.log`.
- Root inspected compact normal screenshots for showdown, first lesson, and
  highlighted guide cards. Render review caught and corrected undersized imported
  SVG text, same-side lower indices, cropped court heads and the old highlight
  radius. Final screenshots are recorded below after the final build.
- Rank labels use native fixed 18.02pt text at the canonical 68pt card height,
  including 10; lower indices sit in the opposite corner. Traditional center pips
  retain the correct counts, with lower-half suits inverted. Card accessibility
  exposes one spoken name, not each repeated decorative mark.
- Only 12 court-card assets are retained. The pinned public-domain source and
  upstream attribution are bundled in `GlassTable/Resources/SVGCards-LICENSE.txt`.
  Source: [Saul Spatz SVGCards](https://github.com/saulspatz/SVGCards), revision
  `f8df28774736ea2545fc8e7fb693eb55ce031945`, Vertical2 deck. Native indices replace
  imported SVG text, and a clipped/scaled central portrait keeps complete artwork.
- No poker rules, generated exercise data, progression, persistence or network
  behavior changed. This pass provides a simulator preview, not a new physical
  iPhone installation or App Store release.

## Design checks

- Geometry and contrast PASS: fixed shared footprints, explicit red/black marks,
  readable native indices, and matching highlight outlines in inspected renders.
- Purpose PASS: corner indices support recognition; pips and court figures supply
  the familiar physical-deck vocabulary requested by the user.
- Interaction PASS: existing lesson and accessibility walkthrough flows passed.
- Scope PASS: the specimen hook is DEBUG-only; app navigation behavior is retained.
  No claims of exhaustive device, VoiceOver or App Store verification are made.

Final reviewed renders: `.build/traditional-card-visuals/delivery/` contains
`showdown-hint.png`, `first-lesson.png`, and `guide-showdown-highlight.png`.
The final court crop removes stray outer-index fragments and preserves complete
portraits. All guide highlights follow the revised card outline.

An unsigned iPhone Release build also passed; `tools/verify_release.py` passed on
that bundle, including absence of DEBUG launch hooks. Signing and installation
were not performed for this preview. Release log:
`/tmp/gt-traditional-cards-release.log`.
