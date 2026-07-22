# M1 sub-project 3 — Polish: glossary, stats, icon (design)

Approved 2026-07-23. Covers the backlog the user committed on 2026-07-22: Korean
glossary polish, stats screen, app icon, study-tool visual tone.

## 1. Korean copy audit (§F sweep)

One pass over every user-visible string in `GlassTable/Sources` against
`docs/decisions.md` §F and `docs/glossary.md` (the canonical term table): bilingual
pairs for learning-critical concept terms, acronyms Latin (MDF, EV), actions Hangul,
플랍 not 플롭. String diffs only; already-correct copy is left alone.

**Status: shipped** — `docs/glossary.md` + bilingual home-row captions (`6e8e116`).

## 2. 용어집 (glossary) screen

Static, read-only list: Korean term + English pair + one-line Korean definition, only
for terms the app actually uses (~10 entries: 에퀴티, 팟 오즈, 필요 에퀴티, MDF, 아웃,
룰 오브 2/4, 블로커, 콤보, 레인지, the 정확/근접/빗나감 grade bands). Data is a plain
array in the view file — no JSON, no model, no search (YAGNI at 10 entries). Layout
mirrors `StatsView`: green header zone + white rounded sheet, Pretendard. Entry: a
book toolbar button on Home next to the existing stats button. Debug hook
`GT_DEMO_GLOSSARY` mirrors `GT_DEMO_STATS` for screenshot verification.

## 3. 통계 (stats) screen

Reads the five existing `ProgressStore.standard(drill:)` files. Overall header (푼
문제, 정확 비율, 최고 스트릭) + one row per drill (name, 🔥 streak, accuracy, reps).
Zero persistence changes. Entry: chart toolbar button on Home.

**Status: shipped** — `StatsView.swift` (`37be5e8`).

## 4. App icon

Flat abstract study-tool mark on GT green `#157A47`: **no cards, no chips, no suits**
(weakest simulated-gambling signal for the GRAC self-rating). Rendered
deterministically by `tools/make-appicon.swift` (CoreGraphics) into
`AppIcon.appiconset/AppIcon1024.png`. The first shipped version (`e948723`) used a
tilted white card silhouette + % glyph; this design supersedes it — the card is
removed in favor of a subtle "table" disc + large white % glyph.

## 5. Study-tool visual tone

An audit, not a feature: the Toss design system already reads as a study tool. The
tone work is (a) the no-gambling-imagery constraint on the icon and (b) a checklist
item during the copy sweep. No separate screen work.

## Verification

Glossary and stats are static views over existing data — screenshot-verified (planted
progress JSON where needed), plus the 31 GlassTableDrills tests stay green
(`swift test --package-path GlassTableDrills`). No engine changes, so the release
gate (`swift test -c release`) is not required; `git diff main -- GlassTableEngine`
must stay empty.
