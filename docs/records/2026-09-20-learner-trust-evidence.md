# Learner-trust audit screenshot evidence

- **Date:** 2026-09-20
- **Kind:** verification
- **Originals:** `docs/evidence/2026-09-20-learner-trust/` (11 PNGs: `ax5/` 7, `large/` 4) (tracked: `git show f5c5e22:<path>`; added in `847f21c`)
- **Asked by / for:** owner-approved learner-trust fixes on the revamp branch; these images are the retained screenshot evidence cited by `docs/specs/2026-09-20-learner-trust-audit.md`, which stays and holds the full audit, decisions and test results.

## What it was
Simulator screenshots (compact iPhone 12 mini, iOS 26.5) at normal (`large`) and AX5 text sizes, proving the layout claims of the learner-trust fixes. The first four interaction captures came from the green full suite at `2ddc8f3`; the six policy/Defend/EV frames and the EV equation came from the final candidate `4a49997`. The spec says all retained images were inspected.

## Findings and decisions
- `ax5/table-hole-cards.png`: at AX5 both table hole cards can be fully exposed above the actual tab bar (answers the "AX5 sheet permanently hides hole cards" report; layout kept, geometry regression added).
- `large/outs-hole-cards.png`: normal-size outs hole cards sit above the collapsed number entry.
- `ax5/count-keypad-expanded.png` and `ax5/count-entry-collapsed.png`: keypad opens on demand and collapses after "입력 완료"; an always-open keypad was rejected (agent, from compact screenshots) because it consumed hero-card space.
- `ax5/ev-loss-equation.png`: final AX EV-loss rows show best/chosen EV and the explicit nonnegative subtraction with a horizontal action label (from `4a49997`).
- `table-policy`, `drill-defend-reveal`, `drill-evloss-fold` at both sizes (final six-screen refresh on `4a49997`, sweep `.uisweep/20260920-172111-TF4uBl`): Table policy reference rows, Defend reveal with hand/action summary before the grid, EV-loss fold reveal. AX initial frames intentionally require scrolling; interaction tests cover the later content.
- An earlier 18-capture sweep (`.uisweep/20260920-164703-Ai9OuO`, not retained in git) covered Table preflop, outs, combos, Path, Records empty state and range-read comparison; its policy/Defend/EV frames were superseded.

## Outcome
Evidence for the learner-trust fixes on candidate `4a49997` (branch `codex/learner-trust-fixes`), local simulator-verified, not an App Store release. Spec and decisions remain in `docs/specs/2026-09-20-learner-trust-audit.md`.

## Still open
- Per the spec: physical device, full VoiceOver audio, iOS 17 runtime, signed archive and App Store were not performed.
- If the PNGs are deleted, the image links in `docs/specs/2026-09-20-learner-trust-audit.md` (section listing the final six-screen refresh) will break; point them at this record or at `f5c5e22`.
