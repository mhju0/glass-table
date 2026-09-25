# Pot mock palette comparison

2026-09-23. Local prototype only; no native theme decision or deployment.
The owner approved the interaction but found the green-on-green hierarchy hard
to read. Keep the geometry and teaching flow; compare color roles independently.

## Research and application

- [Atlassian color](https://atlassian.design/foundations/color) assigns most
  backgrounds and text to neutrals, and separates brand, information, success
  and danger roles. Applied here by removing green from the page, seats and chip
  totals in the recommended palette, with separate feedback colors.
- [Radix theme color](https://www.radix-ui.com/themes/docs/theme/color) separates
  gray scales from accent scales, including slate and sand neutrals.
  [Scale usage](https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale)
  distinguishes backgrounds, component states, borders and text. This informed
  the semantic CSS tokens; no Radix package was added.
- [WCAG contrast](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)
  supplies the text contrast criterion. Our tests conservatively require 4.5:1
  for all tested text sizes and 3:1 for the tested control/focus boundaries.

These are custom palettes informed by those principles, not palettes copied
verbatim from the sources or evidence of user-tested learning improvements.

| Proposal | Page / seat | Table | Text | Accent | Rationale |
|---|---|---|---|---|---|
| Charcoal + Amber, recommended | `#17191c` / `#2b2e32` | `#153d33` | `#f4f0e6` | `#edc17f` | Keep green on the felt, separate readable gray seats and warm current-action cue |
| Slate + Blue | `#151b27` / `#303c4e` | `#243b4a` | `#f0f4fa` | `#a3cbf7` | Cooler dark alternative, with neutral totals and a pale blue active cue |
| Paper + Pine | `#f2eee5` / `#fffdf7` | `#dce5df` | `#222c29` | `#275b4c` | Light study-paper alternative, with green limited to table tint and emphasis |

Numbers stay neutral, including the active player's total. Only the current
progress mark takes the accent; completed marks are neutral. The active seat
also has its action caption, and selection has a filled marker, so state does
not depend on hue alone. Font, layout, question, fixtures and motion are unchanged.
Energy 1 / rhythm 2 / motion 2 continue from the approved mock direction.

The design/design-system skills informed semantic color roles rather than a
global green-to-another-color replacement. The accessibility skill supplied the
measured contrast gate. Existing during-work antislop mode was retained.

## Verification

Candidate SHA-256:
`bc0fc4639a63862686ca6379e32a4bda646cd2e8ca17d17c12d8b6a6d38345dd`

`node .scratch/pot-calculation-redesign/hybrid.test.cjs`: PASS, existing model,
every-frame rendering, script syntax, copy and stubbed motion assertions.

`node .scratch/pot-calculation-redesign/palette.test.cjs`: PASS, 75 token pairs.

| Palette | Minimum tested text | Minimum tested boundary |
|---|---:|---:|
| Charcoal + Amber | 7.44:1 | 3.47:1 |
| Slate + Blue | 6.61:1 | 3.93:1 |
| Paper + Pine | 4.62:1 | 3.16:1 |

Browser checks:

- PASS: all three palette controls change actual rendered colors and preserve
  the selected 43-chip choice and current action. Keyboard Enter selects a palette.
- PASS: palette switching mid-replay preserves the raise frame and hidden choices;
  Next restores the final question. URL updates and reload retains charcoal.
- PASS: all three palettes, both player counts, normal and 200% text at 375×812
  (12 combinations): no horizontal overflow, clipped app content, or rendered
  text contrast below 4.5:1 in the question/review surfaces.
- PASS: each palette's incorrect/correct feedback, retry, confirmation and
  calculation disclosure work; rendered feedback text passes contrast.
- PASS: help surfaces follow each theme and Escape closes them. Existing lesson
  and question controls remain functional. No captured warning/error logs.
- PASS: desktop screenshots of all three and compact enlarged paper were viewed;
  the temporary viewport override was reset. The recommended question is open.
- PASS: purpose and craft gate: meaningful neutral/accent roles, no new art,
  decorative motion, remote dependencies or fabricated claims. This synchronous
  fixture has no network loading/error states to add. All new palette controls
  were exercised, while unchanged flows retain previous verification evidence.

Limits: measured contrast does not prove comfort or learning efficacy. These
are browser mocks, not native Dynamic Type/VoiceOver verification. The installed
iPhone app, progress data, GitHub and release theme remain unchanged.
