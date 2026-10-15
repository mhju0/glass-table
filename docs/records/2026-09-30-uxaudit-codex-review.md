# Codex review of the Claude UX audit crawl

- **Date:** 2026-09-30
- **Kind:** audit
- **Originals:** `.scratch/uxaudit-codex/` — `findings.json`, `review-scope.md`, `verification.json`, `root-static-verification.json`, `original-checksums.json`, `report-script.js` (tracked: `git show f5c5e22:.scratch/uxaudit-codex/<file>`). Generated report `.build/uxaudit-report-codex/` (local, not in git)
- **Asked by / for:** independent second review of the 2026-09-30 whole-app crawl report

## What it was
Codex reviewed Claude's crawl report (`.build/uxaudit-report/`, 1,246 retained
screenshots) against source baseline `e38914d`: first question/warm-up capture of all 26
lesson/checkpoint flows, sampled first-run/Learn/Progress/Settings, and the cited Play,
Range Read, Position and pot captures. Not a new crawl; not every frame inspected.
`findings.json` was the input of `tools/uxaudit/codex_report.py` (removed 2026-10-15 with it)
(`FINDINGS = .scratch/uxaudit-codex/findings.json`).

## Findings and decisions
Assessments of Claude's top 10 (current = confirmed; qualified = weaker):
1. current: free table crashes opening "컴퓨터는 어떻게 고를까요?" with 2 or 3 players
   (PlayView indexing past `styles`). Most urgent.
2. current: Range Read grade and explanation use different criteria (correct mark with a
   narrowing warning, or wrong mark with reassurance).
3. current: graded play action sheet covers own cards on first viewport; visible after scroll.
4. current: free table raise control starts under the floating tab bar.
5. current: pot answers look active while locked (`ConceptDrillView.swift:931-939`
   disables; `GTChoiceButton`, `Components.swift:846-865`, shows no disabled state).
6. current: scrolled content runs under status bar/floating buttons on cited routes.
7. qualified: nested "예시 보기" has no close button (outer sheet does, `:847-852`).
8. current: "테이블 다시 만들기" lands on Play home, not setup (`PlayView.swift:143-146`,
   `ProgressionModel.swift:814-817`, `PlayView.swift:80-103`).
9. qualified: hand review uses 반환 unexplained.
10. qualified: empty "연습 변화" card is a demo-fixture artifact (no `dailySummaries`).

Codex additions:
- C1 medium/qualified: graded Position questions show the action order used to derive
  the answer (`ConceptDrillView.swift:1058-1079`, `Position.swift:29`); in the CO capture
  counting seats gives 3. Instructional judgment, not measured.
- C2 medium/current: 13x13 range grid labels ~6pt (`RangeGridView.swift:75-77`
  `max(6, side x 0.30)`; Range Read grid 250pt, EV ~230pt). Suggest enlargement or a
  missed/extra hand list.
- C3 medium/current: calling ranges labelled "상위 N% / top N%" (`RangeRead.swift:130,
  141-142`, `RangeGridView.swift:123-131`) though `Archetype.swift:62-67` removes raising
  hands; suggest "전체 조합의 N% / N% of combinations".
- Crawler flags qualified: 43.999984741 is effectively 44pt; blank picker children share
  parent bounds; spoken VoiceOver, hit testing, full AX5/EN/dark, notifications and
  backup roundtrip not verified.
- Report verification: 14 sections, 42 flows, 1,000 cards, 1,117 images preserved in
  order; JS syntax valid; browser visual check blocked by the browser tool's URL policy.

## Outcome
Fixed the same day in `33e5384` (per its handoff entry): policy-details crash (now
`PracticeTableState.computerSeats`), Range Read contradiction and unreachable calling
ranges (`excludedTop` band, additive `rangeBand` save case), "상위 N%" wording, a range
difference list under the reveal grid, locked pot answers look locked, nested example
close button, Position hides the order until answered, graded play hides the tab bar
(`gtChrome`, `defaultScrollAnchor(.bottom)`), 반환 explained, "테이블 다시 만들기" lands on
setup.

## Still open
Left open in that handoff entry: EV-loss range grid labels still ~6pt; backup
exporter/importer unverified; empty 연습 변화 is a fixture artifact; the crawl tooling was
not updated for the new free table.
