# Native accessibility audit follow-up

- **Date:** 2026-10-20 · **Kind:** audit
- **Asked by / for:** scope-4 interaction/accessibility verification, compact iPhone.
- **Originals:** `/tmp/gt-interaction-baseline-audits.{log,xcresult}`;
  `/tmp/gt-interaction-diagnostics.{log,xcresult}` and attachments manifests;
  `/tmp/gt-interaction-diagnostic-issues.json`, `/tmp/gt-interaction-audit-triage.md`.
  Local temporary artifacts, not tracked or guaranteed to survive cleanup.

## Findings and decisions

- Strict baseline on iPhone 12 mini / iOS 26.5: 8 cases, 3 audit failures; both
  navigation interaction flows passed. Lesson question, Settings and scrolled
  Settings audits passed. Summary contrast and two table text-detection audits failed.
- Summary flag targets `레슨 통과`, dark RGB(34,44,41) on RGB(235,230,219): sampled
  11.555:1. Root inspected the full frame; independent reviewer inspected full/crop.
  Four isolated contrast-only variants (KO/dark and EN/light × normal/AX5)
  reported no findings; these are not same-appearance controls for strict KO/light.
  Fresh final-candidate strict all-types summary audit reproduced the flag (10.319s).
  Authentic pre-glass `9d3bd633` control passed that same strict summary (9.997s);
  both table text-detection failures also occurred on that control. This isolates a
  glass-sensitive summary audit discrepancy, not a proven inherited/transient flag.
  Matched KO/light/normal fresh-launch contrast-only and all-types checks both fail
  the same title flag (2/2, 20.019s): earlier isolated passes were appearance-confounded.
  `/tmp/gt-interaction-9d-control.{log,xcresult}`, final-readback and
  exact-ko-light-pair results retain the failures.
  The same exact contrast audit passes with actual Reduce Transparency enabled
  (7.642s), establishing a material-sensitive audit regression. Independent pixel comparison
  finds a subtle foreground/background shadow gradient absent before glass, while
  dominant text contrast stays above 11:1. No rendering/palette fix is justified by
  the flag alone; strict failure remains open without suppression.
- A separate 16-screen diagnostic matrix (lesson/Settings/Progress/table × KO/EN ×
  normal/AX5) collected 51 findings: 35 contrast, 12 partial Dynamic Type, 4 text
  detection. Its callback deliberately recorded then returned true; successful
  collection is not an accessibility pass.
- Of 35 contrast reports, 29 element frames intersect the established bottom fade
  or lie offscreen, 5 supply no element/region, and one is an English AX5 paragraph
  extending below the viewport. Region overlap alone does not establish compliance.
  The paragraph uses a scrolling layout at AX5; sampled visible text is 5.46:1 on
  paper and approximately 5.12:1 on the watermark. No palette defect established.
- Of 12 Dynamic Type reports, 6 concern documented D54 dense-table caps; 4 concern
  the Progress heading's adaptive base font (observed height 36→62.33pt at AX5);
  2 concern uncapped refresh badges within consolidated accessible rows. These are
  classified observations, not blanket waivers or universal Dynamic Type clearance.
- Four text-detection reports (3 table, 1 Progress) and 5 contrast reports have no
  useful element/region. Source groups table cards/seat/chip facts and Progress
  rows into meaningful labels; that alone does not identify an unlocated OCR report.
- Real-device VoiceOver on iOS 27.0.1 reached the hero's visible Q-hearts/6-clubs,
  each opponent's face-down-card status, stacks/commitments, pot, call price and
  fold/call/raise. It also reached End game, Start new game and Dismiss context menu.
  No hidden opponent hand was spoken. This supports the current table semantics;
  it does not prove the iOS 26.5 native OCR warning is absent.
- Confirmed physical glossary defects and fixes are recorded separately in
  `2026-10-20-interaction-accessibility.md`. No speculative palette, text-cap or
  performance rewrite was made to turn diagnostic output green.

## Still open

- Material-sensitive strict audit regression and nine unlocated reports remain open.
  Retain exact failing results; future investigation needs an attributable region,
  reproducible visual/spoken defect or reliable audit control. Do not describe this
  pass as full accessibility certification or claim the strict audit suite is green.
