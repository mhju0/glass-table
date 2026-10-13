# 01 — Can Korean and English body text differ in line count?

Type: research
Status: resolved

## Question

The owner worries that whichever language runs to more lines will break a page's
layout, and leans towards keeping both languages at the same line count.

## Answer (findings, 2026-10-11; decided)

Evidence: `evidence/parity-normal-comparisons.jpg`, `parity-normal-rules.jpg`,
`parity-largest-text.jpg`; sweeps `.uisweep/20261011-195423-uMvxf9` (EN) and
`.uisweep/20261011-195840-OEP4Ln` (KO); `BilingualConsistencyB20Tests` 16/16 on
iPhone 12 mini.

- At normal size the two languages differ by one line in three opening-guide
  places: the instruction on comparison 1, the pair letters line, and the body
  on "betting after each deal". In each, content below moves down about 24 pt
  and nothing is clipped or pushed off screen; the choices dock is pinned.
- Every screen file in `GlassTable/Sources/Screens` that shows body text puts it
  in a `ScrollView`; the nine files without one are components and helpers.
- Text that cannot grow is limited to about 20 single-line labels
  (`lineLimit` / `minimumScaleFactor`): seat names and status, card glyphs,
  grid cells, raise presets, a Records label. These shrink or truncate instead
  of wrapping, so a long translation there gets small, not broken.
- At the largest text size both languages overflow the first screen and scroll.
  English "Getting started" wraps to two lines in the pinned header, making it
  taller than the Korean one (ties to queue item 8).
- Not verified: scroll reachability of the last element in English at the
  largest text size on every screen; only the opening guide was captured in
  English.

Recommendation: do not force equal line counts with hand-placed breaks (that is
what produced the reported bad breaks). Keep the two languages close instead:
a test that fails when one language's body is more than one line taller than
the other, plus a full English sweep at both text sizes before the final pass.

## Decision

Decision (owner, 2026-10-11): go with the recommendation. Languages may differ by up to one line; no hand-placed breaks; add the one-line-tolerance test and run a full English sweep at both text sizes before the final pass.

## Comments
