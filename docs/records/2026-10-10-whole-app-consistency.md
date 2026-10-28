# Whole-app consistency study for the experience-first opening

- **Date:** 2026-10-10
- **Kind:** research
- **Originals:** `docs/reports/2026-10-10-whole-app-consistency/` (index.html, prototype.html, verification.json, assets/system.css, assets/system.js, assets/before/ and assets/after/ EN/KO screenshots, assets/after/manifest.json); `docs/research/2026-10-10-whole-app-consistency.md`; `.scratch/whole-app-consistency/` (feedback.md, build_report.py, report-script.js, report-desktop.png, lesson-review.png) (tracked: `git show f5c5e22:<path>`)
- **Asked by / for:** owner, after approving the first-five-minutes proposals.

See also: `2026-10-10-first-five-minutes.md` (the approved opening proposals this study extends).

## What it was
Research doc plus HTML report and interactive explorer testing how the approved experience-first opening fits onboarding, Learn, worked guides, lesson decisions, feedback, graded 1v1, Free Play, Progress, Settings, tone and shared components. Source audit at native `a3db5fc` / docs `65faf87`; before images are retained build 18/19 gallery fixtures with per-frame provenance, after images are browser proposals. Not a fresh native crawl. No Swift, build, simulator or install; installed app stayed 1.0 (19). The scratch PNGs only show the report page and a "Which hand is higher?" lesson proposal frame.

## Findings and decisions
Owner steering (`.scratch/whole-app-consistency/feedback.md`):
- WAC01 approved the first-five-minute proposals and recommendations.
- WAC02 explore visual and button changes against the whole app before adopting them.
- WAC03 prioritize app-wide consistency; adapt the opening or the rest of the app where a compromise helps.
- WAC04 include tone, component behavior, button placement, not just color and size.
- WAC05 broaden research; one organized report with comparisons.
- WAC06 do not build; exploration and refinement only.

Agent recommendations (no new owner question was raised):
- Common interaction grammar with task-specific compositions. Keep experience-first; optional familiarity after the first two comparisons; experienced users keep a lesson route.
- Adapt the opening to native: Pretendard (not system font), 54 pt primary minimum (not 52 px), 50 pt secondary, >= 44 pt auxiliary; keep amber, drop teal as default action color. Do not enlarge buttons globally to 60; a 60 pt Continue is only a trial on sparse screens.
- Native baseline: page edge 18, card inset 16, control radius 14, panel 20, sheet 28; do not transplant HTML margins or fixed heights. Colors: light page EBE6DB, dark page 17191C, light action 8A5500, dark action EDC17F, result 216B4D, table object 153D33. Green table is an object, not "correct"; red suits never mean "wrong"; red is for errors/destructive actions with labels.
- Motion: keep press spring 0.22 / damping 0.9, scale 0.98 and content spring 0.34 / 0.9 as baseline (not newly validated); short help fades may differ; no confetti, loops, reward bounce, timed waits, failure buzz or toast per toggle; Reduce Motion keeps meaning statically.
- Navigation: four stable root tabs (Learn / Play / Progress / Settings) for destinations; task actions in the bottom dock; first-run task may cover tabs; Back for hierarchy/previous step, Close returns to source; help visible, optional, reopenable, in a context-specific container. Feature tips are not a course; no TipKit proposed.
- Feedback grammar by basis: rule answer "Correct"; chart "Matches this chart"; EV states the no-later-bets model; game outcome "You won the hand" without implying good strategy. Wrong answers show Your answer / Correct answer rows, then the reason. Shortening must keep the grade's basis visible.
- Progress measures stay distinct: examples explored != five-guide completion != recorded practice dates != chart matches != hand results != skill. Worked examples and Free Play do not count as practice dates; do not silently change that. "Improved" needs comparable denominators. No public help penalty, new currency, forced streak or notifications.
- Two-example checkpoint is exposure, separate from five-guide completion; partial onboarding, resume, placement and replay need a separate persistence spec. Research approval does not authorize a schema change.
- Settings: group by learning, feedback, preferences, data; language/appearance are value menus (System/Light/Dark is three states); delete/restore copy states exact consequences, no lesson praise.
- Per-area table (first run, roots, worked guides, questions, feedback, graded 1v1, Free Play, Progress, Settings) and per-lesson-family contract (who wins, outs, pot counting, acting order, entering/defend chart, equity as pot share incl. ties, pot odds, ranges, Go deeper, guided hand): situation first, help available, reason after commit, no answer-revealing color before commit; optional depth kept.
- Voice: calm adult teacher; EN uses "you"; KO natural 해요체 without 당신. Paired EN/KO copy for 12 moments (e.g. "Try one simple hand. We'll explain each choice." / "간단한 패부터 살펴봐요. 선택마다 이유를 알려드려요.").
- Bilingual line-group parity is a component acceptance rule at normal size; accessibility sizes reflow in one continuous scroll; no font caps or clipping. HTML 200% is not AX5 acceptance.
- Research basis: Apple HIG Buttons, UI Design Tips (44x44 pt), Tab bars, Writing for interfaces (WWDC22), Design Evangelism Q&A (progressive disclosure), TipKit, Color, Larger Text criteria (AX5 can exceed 300%), Motion/Reduce Motion, Charts. None demonstrates retention for Glass Table.
- Source audit (existing strengths, not defects): `Theme.swift` tokens; `Components.swift` press feedback, button families and action docks (some guides request 52 pt choices, a review point); `LessonLearningUI.swift` paired text vs AX reflow; `RootView.swift` stable roots; `GradedTableLearningUI.swift` chart vs EV basis; `RecordsView.swift` activity-first progress; `SettingsView.swift` compact controls. Local heading scales, spacing overrides, custom First Lesson Previous/Skip and differing help containers need consistency review, not automatic fixes.
- Screenshots: 7 before/after pairs (welcome, decision, feedback, graded preflop, Free Play help, Progress, Settings) plus state frames showed layout proposals only.

## Outcome
- Report verification (browser only): 80 proposal + 32 retained native screenshots; 100/100 flow assertions across EN/KO x light/dark (taught rule, help return, wrong rows, neutral help, chart without highlight, leave/new game, three-state appearance, settings return, etc.); matched normal line groups across 18 states; 44 large-text renders at 200% with reachable actions; no overflow; targets >= 44 CSS px; 0 final console errors. Final refinements: Free Play suit glyphs keep card ink; help return labels name their source.
- Implemented together with FFM01-08 in build 20 (2026-10-11; signed 1.0 (20), source `07054d0`, final production change `132c331`), per `docs/build-history.md` and `docs/specs/2026-10-11-consistent-experience-first-opening.md`.
- Later superseded in part: one corner radius, 10, for cards, panels, seats, felt and controls (owner, 2026-10-13, per `docs/agent-handoff.md`) replaced the 14/20 values above.

## Still open
- Next evidence named by the study, not done: beginner teach-back and chart-match vs win distinction, cross-mode help/resume without coaching, physical 54 vs 60 pt comfort on the mini, interrupted-session definitions, and the full native matrix (iOS 17, VoiceOver, Reduce Motion/Transparency, Increased Contrast). Build history still lists novice comprehension, physical VoiceOver/thumb comfort and minimum-iOS 17 runtime as remaining after build 20.
