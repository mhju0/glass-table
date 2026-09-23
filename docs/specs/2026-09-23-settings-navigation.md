# Settings navigation follow-up

Delivered locally on 2026-09-23 as Release 1.0 (5), implementation `e612e66`.
Installed in place on the owner's iPhone 12 mini. No push or App Store submission.

## Changes

- Bottom tabs: Learn, Play, Progress, Settings. Settings is always far right.
- Removed the top-right gear and all globe shortcuts. Language remains the first
  section inside Settings, with System, Korean and English choices.
- Hid unused navigation chrome on the four root screens. Pushed-screen Back and
  presented-screen Close controls remain available.
- Added bottom clearance to Settings so its final row scrolls above the tab bar.
- The accessibility sweep caught truncated Progress summary labels and an English
  heading split within a word. Accessibility sizes now use stacked summary rows
  and a smaller, still Dynamic Type-scaled heading. Standard-size layout is unchanged.
- No engine, grading, progression schema or persistence implementation changed.

## Verification

All paths below are relative to the preserved evidence worktree
`.build/settings-navigation/` in the main checkout.

| Check | Result | Evidence |
| --- | --- | --- |
| Debug interaction suite | PASS | 15 tests, zero failures; `.build/verification/ui-tests-fresh.log` |
| Final layout and contrast | PASS | 6 Appearance tests and the AX5 Settings navigation test; `.build/verification/final-layout-tests.log` |
| Release smoke | PASS | 2 tests without demo hooks; `.build/verification/release-smoke.log` |
| Signed device build | PASS | `.build/verification/device-build-final.log`; `verify_release.py` and strict codesign verification passed |
| Phone installation and launch | PASS | `device-install.json`, `device-launch.json`, `device-app.json` under `.build/verification/`; 1.0 (5), running process confirmed |
| Progress preservation | PASS | `diff -rq .build/device-before .build/device-after` returned no differences after launch |
| Working diff | PASS | `git diff --check`; only scoped implementation and documentation files |

The 15-test suite covers tab order and tap-target size, optional placement,
language switching and lesson resume across relaunch, path and heads-up Back
navigation, AX5 Settings scroll reachability, appearance switching, first-lesson
replay/skip, chart exploration, compact equity cards, opponent selection, saved
answers/drafts and practice-hand resume. It ran before the final Progress-only
layout correction; the final layout/contrast tests and Release smoke ran after it.

An initial test compilation failed because an assertion used `count` on an
element rather than a query; that was corrected. An earlier simulator runner
stalled before starting tests and was stopped. Neither run counts as a pass.

Screenshot evidence, iPhone 12 mini simulator, normal and AX5 sizes:

- Initial four-screen EN/light matrix: `.uisweep/20260923-185634-d5hnf5/`.
- Initial four-screen KO/dark matrix: `.uisweep/20260923-190011-tRixGb/`.
- Final Settings wording: `.uisweep/20260923-190335-UJ7T23/` (EN/light) and
  `.uisweep/20260923-190547-ykZAWm/` (KO/dark).
- Final Progress layout: `.uisweep/20260923-191047-3cIrRb/` (EN/light) and
  `.uisweep/20260923-191255-H0rYSq/` (KO/dark).

The matrix contains 24 captures including superseded Settings/Progress frames.
Final Settings normal/AX5 and final Progress AX5 frames were visually inspected
in both languages/themes; interaction tests establish Settings scroll reachability.

Phone files preserved with matching before/after SHA-256:

```text
progression.json
698ecfcd33d4265f8635a5cdcbbe2fb5e77879f55942128acd80ecadd3f7c93e
progression.schema-1-37FF1F87-1068-474D-B437-68E9E7F981E3.json
c662292ec914e6d38f0751daf792019192ddba68b163080ef3a748cf2849816a
```

## Scoped design delivery gate

Applied antislop during implementation as requested. Reading: compact native
navigation for adult beginners, existing warm-paper/charcoal visual language;
Energy 1 / Rhythm 2 / Motion 1. This is a gate for the changed UI, not a new
whole-app accessibility certification.

- R-01 PASS: no gradients or glows added; existing surfaces retained.
- R-02 PASS: new language hint is direct, bilingual and contains no em dash.
- R-03 PASS: inspected compact normal/AX5 layouts; corrected Progress truncation.
- R-04 PASS: native gear denotes Settings; existing learning/play/progress icons retained.
- R-05 PASS: existing screen hierarchy retained, no template sections added.
- R-06 PASS: existing Pretendard typography retained; no new font or uppercase treatment.
- R-07 PASS: no decorative grid introduced.
- R-08 PASS: no decorative arrows added; Back/Close retain navigation meaning.
- R-09 PASS: no badges added.
- R-10 PASS: native tab material retained; no extra glass layer added.
- R-11 PASS: existing panel and tab shapes retained rather than making every control a pill.
- R-12 PASS: no new shadow styling.
- R-13 PASS: no glow added.
- R-14 PASS: existing language/appearance groups serve distinct settings; no new feature-card grid.
- R-15 PASS: Settings and language labels name their actions.
- R-16 PASS: no marketing language added.
- R-17 PASS: no statistics invented; Progress still reads the existing model.
- R-18 PASS: no testimonials added.
- R-19 PASS: no custom motion added; native selection/navigation remains.
- R-20 PASS: existing poker motifs and visual tokens retained.
- R-21 PASS: System/Light/Dark controls remain; appearance persistence test passed.
- R-22 PASS: no illustrations added.
- R-23 PASS: user explicitly requested the navigation change; no new visual assets.
- R-24 PASS: all four tabs and both tested pushed-screen return paths work.
- R-25 PASS: existing semantic text/edge contrast tests pass in both appearances.
- R-26 PASS: new tab and existing language controls exercised in UI tests.
- R-27 PASS: Progress empty states and root save-error notice remain in source.
- R-28 PASS: no FAQ added.
- R-29 PASS: no color tokens added; existing neutral/green/amber roles retained.
- R-30 PASS: no borrowed product styling introduced.
- R-31 PASS: bottom Settings saves top space; stacked AX summaries preserve labels.
- R-32 PASS (source review): native TabView/Button semantics retained; no custom focus handling added. Physical keyboard testing remains unverified.
- R-33 PASS: changes are in Swift source and project.yml, not runtime injection.
- R-34 PASS: bilingual light/dark captures and appearance interaction tests passed.
- R-35 PASS: signed build, simulator interactions and in-place phone launch verified.
- R-36 PASS: delivery claims are tied to logs, captures and file comparisons above.
- R-37 PASS: existing DESIGN.md direction and explicit dials guided implementation.
- R-38 PASS: no fabricated product content added; demo screenshots use synthetic fixtures.
- Dials PASS: 1/2/1 retained through native controls and unchanged styling.
- Focal point PASS: screen title and first task/settings group lead; top shortcuts removed.
- Whitespace PASS: removed unused root navigation-bar space; safe areas remain.
- Accent PASS: existing amber marks selected language/appearance; no extra accent introduced.
- Identity PASS: existing typography, poker symbols and palette remain.
- Design Read PASS: direction declared before implementation.
- C-1 PASS: changes follow the user's requested placement and observed AX layout issue.
- C-2 PASS: no inert new controls; tab and language flows exercised.
- C-3 PASS: no filler section added.
- C-4 PASS within tested scope: compact normal/AX5, both themes and navigation paths verified.
- C-5 PASS: no new testimonial, security or performance claim.

## Remaining limits

Physical VoiceOver, hardware-keyboard navigation and minimum-iOS-17 runtime
testing were not repeated. Simulator checks used iOS 27. Phone install/launch
and file preservation do not establish a physical visual/VoiceOver audit.
Existing App Store distribution gates remain separate. Preserve this worktree's
raw evidence and phone backups until archived; do not treat them as build trash.
