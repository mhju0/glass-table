# Screenshot UX audit, revision 2 (69 findings)

- **Date:** 2026-10-15
- **Kind:** audit
- **Originals:** `.scratch/screenshot-ux-audit-2026-10-15/report.html` (untracked, 7.7 MB with 15 embedded screenshots; deleted, not in git)
- **Asked by / for:** owner asked Codex for a thorough critique of four phone screenshots, then supplied eleven more after clicking and scrolling most controls

## What it was
A Codex report auditing 15 owner screenshots (IMG_0125-0139: table review, graded
feedback, table setup, style menus/guide, starting-hand chart sheet and explorer), with
targeted source reading (TableView, TableSetupView, DefendGridView). Recommendations
only; no app change, simulator or contrast measurement. Screenshot build and text size
unknown. Priorities: 14 P1 (major clarity/layout), 42 P2 (friction), 13 P3 (polish).

## Findings and decisions
Fix order proposed: 1 setup title under back control; 2 preflop feedback under a flop
board; 3 felt crowds the explanation; 4 generic model feedback and ambiguous 0bb; 5
chart answer buried under notation; 6 six styles but five explanations.
Revision 2 corrections: the full compact chart and explorer are reachable (IMG_0138/0139);
explorer cells name actions, so the chart is not colour-only; the setup overlap is
scroll-dependent; native menus, rounded sheets and cropped edge cells are not defects.

Status key [Inferred from the diffs of the fix commits]: **F1** fixed in `88df71d`
(`fix/ux-lesson-gaps-20261015`, PR #13); **F2** fixed in `807fe14`
(`feat/owner-decisions-20261015`, PR #14, build 30); **part** partly addressed; **K** kept
on purpose by owner; **O** not addressed; **n/a** not a defect.

Hand review (IMG_0126/0127):
- 01 P1 felt (~34% of height) crowds the review. O
- 02 P1 board shows a later street than the verdicts. part F1 (street named; finished hand shows only dealt cards)
- 03 P1 "차트와 달라요" louder than its reason. F2
- 04 P1 flop feedback is a generic template. O
- 05 P2 "선택 돌아보기" disclosure takes space. O [Unknown]
- 06 P2 no compact per-street summary (내 선택 / 차트 선택). O
- 07 P2 labels assume poker knowledge (공격형, HJ, bb). part F1 ("상대 · 공격형", glossary terms)
- 08 P2 undealt river slot reads as a face-down card. F1
- 09 P1 ending lacks a recap; outcome vs decision value unclear. O
- 10 P1 "폴드 0bb" can read as no loss. F1 (basis text: chips already in the pot don't count)
- 11 P1 model qualification hard to interpret. O
- 12 P2 comparison panel repeats the verdict. F2 (prices behind Details)
- 13 P2 scroll indicator crosses 다음 핸드. O
- 14 P2 secondary control (상대 바꾸기) cut at the edge. O
- 15 P2 no review heading after scrolling. O
- 16 P3 "13.1bb" unit/number styling. O

Table setup (IMG_0128-0134):
- 17 P1 title slides under the back control when scrolled. F1 (setup uses the shared chrome back button)
- 18 P2 back control style differs from other screens. F1
- 19 P2 intro too abstract. F1
- 20 P2 player count does not say it includes me. F1 ("나 + 컴퓨터 N명")
- 21 P2 빠른 게임 / 긴 테이블 not parallel. part F1 (ending rules spelled out)
- 22 P2 detail line dense, "1·2" ambiguous. F1 (1칩/2칩, ends after N hands or when out)
- 23 P2 three identical opponent descriptions. O
- 24 P2 style menu does not name its purpose. part F1
- 25 P2 style guide card competes with Start. O
- 26 P3 selected options and Start share amber weight. O
- 27 P3 muted rows look inactive. O
- 28 P3 suit watermark on a functional screen. O
- 55 P1 default 재미로 missing from the style guide. F1 ("재미로 (기본)" panel)
- 56 P2 menu names styles without behaviour. O
- 57 P2 open menu does not name the opponent. F1 (section titled with the seat's style)
- 58 P2 intro says card choice only; rows describe raising too. F1
- 59 P3 guide compares styles by separate visits. O
- 60 P2 fixed Start footer cuts content abruptly. O
- 61 P3 header space inconsistent across scroll. part F1 (with #17)

Chart sheet and explorer (IMG_0125, 0137-0139):
- 29 P1 current-hand answer too far down. F2 (reading guide opens only on the first chart)
- 30 P1 vocabulary wall (HJ, bb, 3벳, s/o). part F2
- 31 P2 compact grid needs the colour legend. O
- 32 P2 chart red/amber mean actions, elsewhere verdicts. O
- 33 P2 "차트 읽는 법" disclosure oversized. O
- 34 P2 no axis rank headers. K (owner, 2026-10-15)
- 35 P2 selected cell far from the summary. F1 (explore button under the summary)
- 36 P2 "87o" shorthand unexplained. F1 (plain hand name)
- 37 P2 chart scope narrower than its title. F1 (chart label names the opener)
- 38 P2 fold cells blend into the sheet. O
- 39 P3 grid and explorer reachable. n/a
- 40 P3 uneven close/tutorial/legend emphasis. O
- 41 P2 explorer opens cropped, no location cue. K (with #34)
- 42 P2 explorer drops the chart scope. F1 ("상대가 X에서 먼저 올렸을 때")
- 43 P2 own hand and inspected hand look the same. F1 (내 패 / 살펴보는 패, dashed own-hand outline)
- 44 P3 "현재 패로 돌아가기" unclear. F1 ("내 패로 돌아가기" only when another cell is selected)
- 45 P3 explorer header spends space on notation. O
- 46 P3 nested sheets add depth. O
- 47 P2 T not defined as 10. F1
- 48 P2 axes explained but not how to use them. O

Graded feedback (IMG_0135/0136):
- 49 P1 preflop chart verdict under a flop board, unlabelled. F1 ("방금 한 선택 · 프리플랍")
- 50 P1 opener and call price missing from the compared decision. part F1 (call price recorded, opener named)
- 51 P2 opening details moves table geometry. O
- 52 P2 details explain the method, not this hand. F2 (`DefendChart.reason`)
- 53 P2 Chart / 상대 규칙 buttons before the feedback. F2 (verdict first, then tiles)
- 54 P2 "계속" does not say what follows. O

Across screens:
- 62 P1 information without a reusable reason. part F2
- 63 P2 too many large containers. O
- 64 P2 inconsistent gutters. O
- 65 P2 mixed plain/technical wording. part F1 (선택한 행동, 플랍)
- 66 P2 accessibility unverifiable from screenshots. O
- 67 P2 transitions unobserved. O
- 68 P3 verdict type dominates evidence. O
- 69 P3 palette coherent but state meanings need words/icons. O

Report's own limits: no clipping, dead end, math error, answer leak, disabled control or
contrast failure is proven by screenshots. Preserve: card faces, paper/felt identity,
named opponents, defaults, visible primary actions, chart scope warning, model
qualification, exact comparison evidence.

## Outcome
Fixes landed in `88df71d` (merged via PR #13) and `807fe14` (PR #14, build 30, installed
on the owner's test phone 2026-10-15). Verification of `88df71d`: Drills tests, 85 UI
tests on two 12 mini simulators, uisweep of 11 changed screens at large and AX5.

## Still open
Every O item above; the handoff groups the remaining taste items as container weight,
gutters and palette. Unverified per the report: novice comprehension, VoiceOver/AX5
traversal, expansion animation, explorer selection/reset at all positions.
