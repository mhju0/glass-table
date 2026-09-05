# Glass Table — Project Handoff

Written 2026-09-04 as a clean-slate handoff for a new agent/toolchain. It describes
**what the project actually is right now**, not what any earlier plan said it would be.

Evidence convention used throughout:

- `[V]` **Verified** — read in the repo or executed during this audit (path / commit given).
- `[I]` **Inferred** — reasoned from what was read, not directly stated anywhere.
- `[C]` **Claude conversation context** — the only source is prior agent-session memory
  (`~/.claude/projects/…/memory/`), not the repo or git. Treat as testimony, not fact.

Companion documents: [`decisions.md`](decisions.md) (chronological decision ledger,
including everything reversed or abandoned), [`ROADMAP.md`](ROADMAP.md),
[`CLAUDE_ENV_INVENTORY.md`](CLAUDE_ENV_INVENTORY.md) (archive of the old agent harness —
**not** a migration target).

---

## 1. Purpose

A **Korean-first iOS trainer for No-Limit Texas Hold'em** that teaches serious-minded
amateurs to think in **ranges and EV** instead of hands and hunches. Free, fully
offline, no ads, no accounts, no backend. iPhone only. `[V]` `README.md`,
`docs/product-brief.md`

The product thesis is **transparency**, and it is a real engineering constraint, not
marketing copy: opponents are **rule-based archetypes whose strategies are published
inside the app**, so every grade is computed from declared data and is checkable by the
user. `[V]` `docs/product-brief.md:5-25`, `GlassTableDrills/Sources/GlassTableDrills/Archetype.swift:6-13`

Four commitments follow from it, and they show up in the code as invariants:

1. Bots publish their strategy → archetype ranges are **derived from stated numbers**
   (VPIP/PFR + Chen score), never authored or copied. `[V]` `Archetype.swift:57-91`
2. Ranges, not hand ladders → an observed action **inverts** into the surviving combo
   set. `[V]` `GlassTableDrills/Sources/GlassTableDrills/PostflopPolicy.swift`
3. EV, not equity → decisions are priced in big blinds (`bestEV − chosenEV`).
   `[V]` `GlassTableDrills/Sources/GlassTableDrills/EVLoss.swift`
4. Decide first, then reveal → every screen in the app is a decide → reveal → grade
   loop. `[V]` `GlassTable/Sources/Screens/ConceptDrillView.swift`

Everything the user sees is in Korean; the Korean is canonical and terminology is
pinned in `docs/glossary.md`. `[V]`

---

## 2. Architecture

Three Swift modules, one direction of dependency, **zero third-party runtime
dependencies**. `[V]` `GlassTableEngine/Package.swift`, `GlassTableDrills/Package.swift`,
`project.yml`

```
GlassTable          thin SwiftUI app — screens + design system only        5,434 LOC / 19 files
   │  depends on
   ▼
GlassTableDrills    everything decidable without UI                        4,409 LOC / 38 files
   │  depends on                                                    (+3,717 LOC of tests)
   ▼
GlassTableEngine    pure poker math                                        1,336 LOC / 14 files
                                                                    (+828 LOC of tests)
```
`[V]` line counts measured 2026-09-04.

The split exists so **nearly everything is testable without a simulator**. `GlassTableDrills`
must never import UIKit/SwiftUI. `[V]` `CONTEXT.md`, confirmed by inspection of the
package's imports.

### Test posture per module

| Module | Gate | Count | Last known green |
|---|---|---|---|
| `GlassTableEngine` | `swift test -c release` — **release config is mandatory**, debug is impractically slow | 92 tests | CI weekly run 2026-08-30 `[V]` `gh run list` |
| `GlassTableDrills` | `swift test` (plain, fast) | 321 executed cases | **2026-09-05: 321 passed** `[V]` |
| `GlassTable` | `xcodebuild test` on an iPhone simulator; screenshots for UI layout | 10 persistence tests | **2026-09-05: 10 passed; app build succeeded** `[V]` |

The engine gate is release-only because the evaluator is deliberately naive (see
§12 Technical debt) and the oracle cross-check runs 200k-iteration Monte Carlo over
500 spots. `[V]` `GlassTableEngine/Tests/.../EquityOracleTests.swift`, `.github/workflows/engine-gate.yml`

---

## 3. Major components

### `GlassTableEngine` — pure poker math

| File | Owns |
|---|---|
| `Card.swift` | `Card` value type; `parse` / `description` ("Th") round-trip format. `Sendable` since `d0923f4`. |
| `HandEvaluator.swift` | 5-card classifier taken best-of-21 for 7 cards; monotonic integer keys. Allocation-free hot path. **Explicitly a naive design** — `// ponytail:` marks it. |
| `Equity.swift` | Exact heads-up enumeration; fixed-seed Monte Carlo; `equityVsRange`. |
| `RNG.swift` | `SplitMix64` — the only source of randomness. Everything is seeded. |
| `HandClass.swift`, `HandRange.swift`, `RangeNotation.swift` | 169 hand classes, 1326 combos, range algebra, chart notation parsing. |
| `Chen.swift` | Bill Chen's published starting-hand formula — **the derivation rule for every chart in the app**. |
| `BoardTexture.swift`, `RangeOnBoard.swift` | Five made-hand buckets (노페어 · 드로우 · 약한 페어 · 탑 페어 · 투페어 이상) and range-vs-board distributions. |
| `PotOdds.swift`, `Outs.swift`, `Blockers.swift`, `Drill.swift` | M1-era math primitives + grading bands. |

`[V]` all files read or listed during this audit.

### `GlassTableDrills` — app logic, no UI

- **Spot generators + grading**, one file per concept: `OutsSpot`, `BetSpot`, `CallFold`,
  `Blocker`, `Showdown`, `Position`, `PotMath`, `Estimation`, `RangeDrills`,
  `RangeRead`, `BoardDrills`, `EVLoss`, `ActionRead`, `DefendDrill`. `[V]`
- **`Archetype.swift`** — the five opponents (Nit/TAG/LAG/콜링 스테이션/매니악), defined
  only by VPIP/PFR; every range is derived from those two numbers plus seat. `[V]`
- **`PostflopPolicy.swift`** — each archetype's postflop play as a *printable bucket
  table*, deterministic on purpose so an action inverts into a range. `[V]`
- **`DefendChart.swift`** — vs an open: 3벳/콜/폴드 bands derived from the opener's width. `[V]`
- **`RFIChart.swift`** — seven seats' opening ranges as top-N% by Chen. 8-handed
  percentages are interpolated and the app says so. `[V]` `RFIChart.swift:16-24`
- **`Table.swift`** (545 LOC) — `TableHand`, the whole hand state machine as a *pure
  value type*. `play(_:)` advances and is fast; `gradedOptions()` prices the legal
  choices and is the slow part, so the UI runs it off-main on a copy. `[V]` `Table.swift:6-14`
- **`Progression/`** (10 files) — `Concept` (18 concepts), `Curriculum` (8 units),
  `ProgressState`, `ProgressionStore`, `FSRS` (FSRS-6 scheduler, published default
  weights), `Mastery` (4 tiers), `Streak` (silent freezes), `Calibration` (Winkler
  scoring), `ReviewQueue`, `DayKey` (timezone-safe), `LegacyMigration`, `Beats.swift`
  (676 LOC of 천천히 walkthrough scripts). `[V]`
- **`Korean.swift`** — computed particle agreement (`KO.subject/object/topic/copula`).
  Korean particles are **never baked into format strings**. `[V]`

### `GlassTable` — SwiftUI app

- `RootView.swift` — 4 tabs: 길 (path) · 오늘 (today, the default) · 테이블 · 기록.
  Settings, free play, review and node sessions are all **sheets presented once at
  root**, not per-tab. `[V]` `RootView.swift:36-160`
- `ProgressionModel.swift` — the single `@Observable` window onto the progression core.
  It only loads, forwards and saves; **every rule lives in `GlassTableDrills`** so there
  is no second place a rule could disagree with the tested one. `[V]` `ProgressionModel.swift:6-13`
- `Screens/ConceptDrillView.swift` — **1,607 LOC, the largest file in the repo**; all 18
  drill screens. `[V]`
- `Screens/TableView.swift` (700 LOC), `WalkthroughView.swift` (334), `TodayView.swift` (267),
  `NodeSessionView.swift` (253, also hosts `FreePlayView`), `RecordsView.swift` (230),
  `PathView.swift` (217), `SettingsView.swift` (193), `GlossaryView.swift` (107). `[V]`
- `DesignSystem/` — `Theme.swift` (tokens), `Components.swift` (541 LOC),
  `PlayingCardView`, `RangeGridView` (13×13), `DefendGridView`, `BucketBarView`, `PriceBarView`. `[V]`

---

## 4. Important files & directories

| Path | What it is |
|---|---|
| `CONTEXT.md` | One-page domain orientation. **Read this first.** Vocabulary + "conventions that bite". |
| `docs/decisions.md` | The decision ledger (chronological, with statuses). *Replaced the former §1–§10 / §A–§H rationale document on 2026-09-04 — see the note at its head.* |
| `docs/product-brief.md` | Thesis, audience, modes, non-goals. |
| `docs/open-questions.md` | P1/P2/P3 open items; most are struck through as resolved. |
| `docs/risks.md` | Risk register with mitigations; several retired. |
| `docs/glossary.md` | Canonical Korean terminology table. Load-bearing for UI copy. |
| `docs/specs/` | One design spec per shipped slice (12 files). **Each has a "Scope — out" section that is the real deferred-work list.** |
| `docs/plans/` | M1-era step-by-step implementation plans. Historical; partly stale. |
| `docs/submission.md` | App Store Connect single source of truth. **Carries a stale-content banner — see §14.** |
| `docs/milestone-1.md` | Historical record of M1. Marked "shipped, then superseded". |
| `docs/agents/` | Three files describing agent conventions (issue tracker, triage labels, domain docs). Harness-specific — see `CLAUDE_ENV_INVENTORY.md`. |
| `project.yml` | XcodeGen input. **The `.xcodeproj` is generated and never committed.** Info.plist properties (incl. `UIUserInterfaceStyle: Dark`, portrait lock) live here. |
| `tools/uisweep.sh` | Screenshots ~58 screens via `GT_DEMO_*` launch hooks. The cheap way to *look at* the app. |
| `tools/gen_fixtures.py` | Dev-only. Regenerates the eval7 oracle fixture. Not shipped. |
| `tools/make-appicon.swift` | Script that renders the app icon. |
| `.scratch/<slug>/spec.md` | Local markdown "issue tracker". Two entries, both shipped. |
| `.uisweep/`, `build*/` | Untracked local output. Gitignored. |
| `.superpowers/` | Artifacts from the old agent harness. Gitignored. Historical only. |

---

## 5. Data flow

**Drill loop (all 18 concepts):**

```
Curriculum.nextNode(state)  →  NodeSessionView
      │
      ▼
seeded generator (SplitMix64)  →  Spot            ← same seed always yields the same spot
      │                                             seed = f(concept, index, progress salt)
      ▼
user commits an answer (decide)
      │
      ▼
grade*(spot, answer) in GlassTableDrills  →  band / EV loss / Winkler score
      │
      ▼
ProgressionModel.record…  →  ProgressState  →  ProgressionStore.save (atomic JSON)
      │
      ▼
FSRS scheduler updates the concept's next review date
```
`[V]` traced through `NodeSessionView.swift`, `ProgressionModel.swift`,
`Progression/FSRS.swift`, `Progression/ProgressionStore.swift`.

**Table loop (테이블 tab):** `TableHand` is a pure value type. The view calls
`play(_:)` on the main thread (fast) and dispatches `gradedOptions()` to a detached
task on a *copy* (slow — it prices every legal action under the checkdown model), then
merges the result back with the user's choice. `[V]` `Table.swift:6-14`, `TableView.swift`

**Performance rule learned the hard way** `[V]` commits `0d8d87f`, `7640fef`: a `spot`
held in a *computed property* regenerates on every read, and a SwiftUI `body` reads it
5–9 times. Bind the spot **once per render**. The same commits removed double
computation inside grading. Measured: 액션 리드 769µs → 86µs per body pass.

---

## 6. External services

**At runtime: none.** The app has zero networking, zero analytics, zero accounts. This
is a product commitment, a privacy-label claim ("Data Not Collected"), and part of the
Korean legal position. `[V]` `docs/privacy-policy.md`, `docs/submission.md:144-148`

**At development time:**

| Service | Use | Status |
|---|---|---|
| GitHub `mhju0/glass-table` | Origin remote, **public repo**, CI, issue templates, labels | Active `[V]` `gh repo view` |
| GitHub Actions | `ci.yml` (app build + drills tests; app persistence tests added locally on 2026-09-05) and `engine-gate.yml` (release-config engine tests on engine paths + Sundays 20:00 UTC) | Published workflows green at takeover; new app test step not yet run remotely `[V]` |
| GitHub Pages | Serves the privacy policy from `main:/docs` at `https://mhju0.github.io/glass-table/privacy-policy.html` | Built & live `[V]` `gh api …/pages` |
| `eval7` (Python, MIT) | Dev-time equity oracle. Fixture is **frozen and checked in** (`random_spots.json`, 500 spots), so the engine gate does not need Python at CI time. | Fixture in repo `[V]` |
| Apple Developer Program | Not enrolled. Device installs use free personal-team provisioning (7-day expiry). | Deliberately deferred `[C]` |

**Never shipped, and one that never arrived:** `decisions.md` originally specified
**two** independent oracles (eval7 + OMPEval). `[V]` grep finds **zero** references to
OMPEval anywhere in `tools/`, the engine, or CI — only eval7 was ever wired up. See the
ledger entry "Dual reference oracles" (ABANDONED).

---

## 7. State / "database" architecture

There is no database. There is **one JSON file**. `[V]` `Progression/ProgressionStore.swift`

- **Location:** `Application Support/progression.json`.
- **Shape:** `ProgressState` — a `Codable` value type with a capped answer log, per-concept
  records, node cleared flags, streak state and calibration samples. Carries
  `schemaVersion`. ~50 KB, loaded whole; "there is no query here that would benefit from
  an index". `[V]` `ProgressionStore.swift:22-25`
- **Writes are atomic.** On failure, the app retains recent answers in memory and shows
  a retry notice; backup export includes those unsaved answers. `[V]` D43
- **Three load outcomes, never two:** `.fresh` / `.loaded` / `.unreadable`. The M1 store
  answered "no file" and "corrupt file" identically with empty progress, which silently
  erased returning users. `StoreRecoveryView` offers import-or-restart. Future schema
  versions also enter recovery. Before reset or import, the current bytes are copied to
  `progression.recovery-<UUID>.json`; memory and recovery mode change only after the
  replacement is saved. Failed copies or writes leave the live file intact. `[V]` D43
- **Export/import:** the store file *is* the backup format. Settings has
  백업 만들기 / 백업 불러오기 (fileExporter/fileImporter) and 진행 초기화. `[V]` `commits e059ec6`, `f38c520`
- **Migration:** `LegacyMigration` folds M1's five per-drill `<drill>-progress.json`
  files into the new store on first launch. `[V]` `Progression/LegacyMigration.swift`
- **Table results are deliberately NOT persisted.** Writing them into concept records
  would distort FSRS scheduling and mastery. The hand summary is the whole record. `[V]`
  `docs/specs/2026-08-04-r4-s4-table-design.md:104-110`

---

## 8. Environment & setup

- **macOS + Xcode 26 required.** Not optional: the nav chrome calls
  `sharedBackgroundVisibility`, and `#available` guards *runtime*, not *compile*, so an
  older SDK fails to find the symbol. Deployment target is still **iOS 17**. `[V]`
  `README.md`, `.github/workflows/ci.yml:14-20`
- **XcodeGen** (`brew install xcodegen`). `GlassTable.xcodeproj/` and
  `GlassTable/Info.plist` are both **generated and gitignored** — a fresh clone has
  neither. `[V]` `.gitignore`, `project.yml`
- Swift version pinned to 5.9 in build settings. `[V]` `project.yml`
- No package manager for dependencies — there are none.
- **No linter or formatter is configured** (`[V]` no `.swiftlint.yml`, no `.swiftformat`).
  "Lint" in this repo means the compiler plus review.

---

## 9. Build / run / test commands

```sh
# one-time
brew install xcodegen

# generate the Xcode project (required after any clone or project.yml change)
xcodegen generate

# build the app for the simulator, unsigned
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO build

# fast test suite — app logic
swift test --package-path GlassTableDrills

# app persistence tests
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO test

# the math gate — MUST be release config
swift test -c release --package-path GlassTableEngine

# look at the app: screenshots every significant screen into .uisweep/<timestamp>/
tools/uisweep.sh
tools/uisweep.sh --no-build
GT_SIM="iPhone 17 Pro Max" tools/uisweep.sh     # store-asset size

# regenerate the oracle fixture (rarely; it is frozen)
python3 -m pip install --user eval7
python3 tools/gen_fixtures.py > GlassTableEngine/Tests/GlassTableEngineTests/Fixtures/random_spots.json
```
`[V]` all commands read from `README.md`, `CONTEXT.md`, `tools/uisweep.sh`,
`tools/gen_fixtures.py`; build and test gates executed successfully during the audits.

**Verification constraints:**

1. **Engine changes require the release-config gate.** Debug is ~10× slower; the full
   suite becomes tens of minutes. `[C]` + `[V]` (CI enforces release).
2. **Screenshot hooks provide broad visual coverage; inspect the resulting images.**
   Native simulator interaction also worked during 2026-09-05 persistence verification;
   the earlier claim that taps never reach Simulator content is stale. Use an isolated
   simulator for destructive recovery tests. `[V]`

---

## 10. Deployment

**Nothing is deployed. Nothing has ever been submitted.** `[V]` no releases
(`gh release list` empty), one tag `v1.0.0-beta.1` on commit `7daef48`.

- Store submission was prepared in full (metadata, screenshots, privacy policy, review
  notes, age-rating answers) and then **paused by owner decision on 2026-07-23 for a
  dogfood phase**. `[V]` `7daef48` "docs: mark submission plan paused — dogfood phase,
  TestFlight-only when resumed"
- Apple Developer Program enrollment is deliberately deferred. The app runs on the
  owner's device via **free personal-team provisioning (7-day expiry)**, installed in
  **Release** configuration (debug flop pricing measured ~2.5 s vs release ~35 ms). `[C]`
- When resumed, the standing instruction in the plan is: enroll → **TestFlight upload
  only**; do **not** submit for review (plan Task 11) without an explicit go. `[V]`
  `docs/plans/2026-07-23-m1-submission.md:6-9`
- The only thing actually shipping today is the **privacy policy on GitHub Pages**. `[V]`

---

## 11. What currently works

Verified by execution on 2026-09-04 unless noted; persistence and app tests updated
2026-09-05 in the working tree.

- **Builds clean.** `xcodegen generate` + `xcodebuild` → `** BUILD SUCCEEDED **`. `[V]`
- **321 drills tests and 10 app persistence tests pass** (2026-09-05). `[V]`
- **92 engine tests** last green in CI 2026-08-30 (weekly release gate). `[V]`
- **길 — the course.** 8 units, 17 path concepts (18 overall), strictly linear unlocking, boss nodes as
  the only route to 숙달. Every new concept opens with a 천천히 walkthrough
  (보여주기 → 함께 풀기 → 혼자). `[V]` `Curriculum.swift`, `Beats.swift`
- **All 18 drills are implemented and reachable**, plus 자유 연습 (unlimited, ungated)
  and a due-filtered 복습 sheet. `[V]` `tools/uisweep.sh` sweeps every one.
- **테이블 — a full heads-up hand** against a chosen archetype, preflop through river,
  every decision priced in bb under a disclosed checkdown model, with the villain's
  range narrowing on screen. `[V]` `Table.swift`, `TableView.swift`
- **FSRS-6 spaced repetition** over concepts (not hands), mastery tiers, streaks with
  silent freezes, Winkler-scored calibration on estimation concepts. `[V]` `Progression/`
- **Store durability**: atomic writes, recovery copies, visible save failures with retry,
  backup export/import, explicit reset, M1 legacy migration. `[V]` D43
- **Accessibility**: VoiceOver labels on cards, Dynamic Type on text, card faces
  correctly opted out of scaling, one-row diagrams clamped at `.xxLarge`. `[V]` `af16354`
- **CI is green** on both workflows. `[V]`

---

## 12. What is partially implemented

Each of these is a **deliberate, documented** stopping point, not an oversight. The
authoritative list is the "Scope — out" section of each spec in `docs/specs/`.

| Area | What exists | What is missing | Source |
|---|---|---|---|
| **MDF** | The drill ships and is reachable in 자유 연습; `Concept.mdf` exists so progress is recorded | **No path node.** The shipped drill is only the *frequency* half (`BetSpot` is `(pot, bet)` — no cards, no range); the real skill is selecting which combos defend | `[V]` `Concept.swift:12-13`, `BetSpot.swift`, R1 spec §12.6. **Parked on purpose** — do not file as a curriculum hole |
| **테이블 depth** | Heads-up, single-raised and hero 3-bet pots, intended hero in position (seat bug in §13), 100bb, one raise per street, raise fixed at 3× | Multiway, hero out of position, other stack depths, 4-bets, bot mixing, slowplay rows (pinned by test as absent), hero-seat-sensitive defend bands, blind defense | `[V]` `TableHand.play`, R5 |
| **Table statistics** | Per-hand summary (net result + EV burned) | No persistence at all; 기록 shows no table stats | `[V]` R4-S4 §5 (deliberate) |
| **Range Read input** | Width slider + shape tendency chips, graded by combo overlap | 정확히 칠하기 — exact cell painting of the 13×13 grid | `[V]` R3 §5 |
| **EV-loss thresholds** | Absolute bb bands (0.5 / 2.0) | Pot-relative bands. The spec itself calls this "the model's weakest joint" and says to retune against real answers | `[V]` R4-S2 §7 |
| **Postflop reads** | C-bet spot only | Reads on raises; caller-side policies; multi-street narrowing | `[V]` R4-S3 §6 |
| **Evaluator** | Naive 5-card classifier best-of-21, allocation-free | Perfect-hash design (`decisions.md` originally specified it) — deferred to profiling that has not demanded it | `[V]` `HandEvaluator.swift:2`, marked `// ponytail:` |
| **First-run diagnostic** | Curriculum still supports pre-cleared nodes | First-run UI was implemented and then deleted; no current entry point. The later intro-card proposal is conversation-only | `[V]` `a2c3063` → `0d86328`, D30; intro-card proposal `[C]` |
| **Notifications** | — | Daily reminder (R1 §6 day-3 prompt) never built | `[C]` |
| **VoiceOver pass** | Broad coverage exists | `TableView` / `NodeSessionView` never got a dedicated pass | `[C]` |

---

## 13. What is broken

The 2026-09-05 takeover audit reproduced defects despite the existing green gates.
Persistence failures are fixed locally (D43). Remaining verified bugs are streak
eligibility being checked after rescheduling, boss promotion of unasked concepts, and
table seats that contradict the intended postflop action order. See ROADMAP NOW for
priority; these are implementation defects, not new feature decisions. `[V]`

Other known limitations:

1. **`docs/submission.md` is stale in a load-bearing place** and says so in its own
   banner: the age-rating rationale ("no betting gameplay") was written for M1 and no
   longer describes an app that ships a betting table. This is the one thing blocking
   store resumption. `[V]` `docs/submission.md:3-13`
2. **Stale text inside `docs/plans/2026-07-23-m1-submission.md`** — Task 10's hardware
   checklist still tells the reader to verify "the abstract table-disc + % mark (no
   cards)" app icon, which was replaced on 2026-07-24 by the range-grid heatmap icon
   (`055eeb7`, `a32b03f`). Historical document; low priority. `[V]`
3. **Known non-determinism in the screenshot sweep, not the app**: `teach-showdown-b3`
   and `-b5` differ 0.05–0.24 % run-to-run on an *unchanged* build — a card fade-in
   caught mid-animation. Do not chase it. `[C]` + corroborated by commit messages
   `0d8d87f`, `7640fef` `[V]`

---

## 14. Current git state

`[V]` all of this observed 2026-09-04.

- **Branch:** `main`, at `4236332`, **identical to `origin/main`**. No other local or
  remote branches exist.
- **Working tree:** clean (`git status --porcelain` empty), including after running
  `xcodegen generate` — the generated project and Info.plist are gitignored.
- **155 commits**, 2026-07-22 → 2026-08-27. **No commits in the last 8 days.**
- **Tags:** one — `v1.0.0-beta.1` on `7daef48`.
- **Releases:** none.
- **Pull requests:** 2, both merged (`#1` R1 progression shell, `#2` R2–R5b), both from
  the same branch name `revamp/r1-progression-shell`.
- **Issues:** **zero**, open or closed. The issue templates and the five triage labels
  (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`) exist
  and have never been used.
- **Repo:** public, no license (all rights reserved), topics
  `ios swift swiftui poker texas-holdem korean education`, homepage set to the privacy
  policy.
- **Uncommitted work:** none. **Stashes:** none.
- Two merged-in-history feature branches are gone from the remote:
  `revamp/r1-progression-shell` and `wiring/completeness-pass` (merge commit `5e8b73e`).

---

## 15. Recent major development

Reverse chronological. `[V]` from `git log`.

| Date | Work |
|---|---|
| 2026-08-27 | Two doc/chore commits: state the Xcode 26 requirement + XcodeGen step in the README; gitignore `build-device-release/`. **Last activity.** |
| 2026-08-08 → 08-09 | **A three-commit performance campaign**, all behaviour-preserving and *proven* so: `e0084ac` engine hot paths made allocation-free (madeHand 47×, boardTexture 67×, evaluate7 2.9×; engine gate 284 s → 128 s, drills 4.8 s → 0.7 s); `0d8d87f` drill screens stopped regenerating their spot on every render (up to 9× per body pass); `7640fef` grading stopped computing the same answer twice. Verification method is worth keeping: differential dumps of tens of thousands of outputs against the previous package, byte-identical, plus a 58-screen pixel sweep. |
| 2026-08-07 | **UI review pass** — table gained three fixed zones and a pot-odds strip at the board; the reveal leads with the lesson not the score; 길 inverted its weight onto a rail; emoji icons became SF Symbols. Same pass found and fixed a **critical accessibility bug**: card ranks truncated to "…" at accessibility text sizes, making the app unplayable at exactly those settings. |
| 2026-08-06 | **Completeness / wiring pass** (`5e8b73e`) — wired up shipped machinery that had no UI: walkthrough replay, backup export/import, progress reset, honest 오늘 header, review sheet, glossary chips in reveals, streak-freeze display, grade haptics. |
| 2026-08-03 → 08-04 | **The revamp, R1–R5b** — the app stopped being five drills behind a home screen and became a course plus a table. Merged as PR #1 and PR #2. |
| 2026-07-22 → 07-23 | M1: engine core → app spine → five drills → polish → submission prep. Tagged `v1.0.0-beta.1`, then paused. |

---

## 16. Technical debt

Ordered by how much it would cost to leave alone.

1. **`ConceptDrillView.swift` is 1,607 lines** and holds all 18 drill screens. It is the
   file every drill change touches. `[V]`
2. **App tests currently cover persistence only.** Session behavior and UI verification
   still rely on manual checks and screenshots. `[V]`
3. **Naive evaluator.** `evaluate5` is a classifier taken best-of-21; the perfect-hash
   design `decisions.md` specified was never built. It is fast enough now (post-`e0084ac`)
   but it is why the engine gate needs release config and 128 s. `[V]`
4. **EV-loss severity bands are absolute bb, not pot-relative.** A 2 bb mistake in a
   7.5 bb pot and in a 60 bb pot grade the same. Flagged by its own spec as the weakest
   joint in the grading model. `[V]` R4-S2 §2, §7
5. **`docs/plans/` is historical and partly stale** but is not marked as such
   per-document (only `milestone-1.md` and `submission.md` carry banners). A reader can
   mistake a plan for current intent. `[V]`
6. **No lint/format tooling.** Style is held by convention and review only. `[V]`
7. **Build output directories live in the working directory** (`build/`,
   `build-device/`, `build-device-release/`, `.uisweep/`) — gitignored, but they are
   large and `build-device-release/` was only ignored on 2026-08-27. `[V]`
8. **`.superpowers/` and `.scratch/` mix agent scratch with real content.**
   `.scratch/*/spec.md` holds two genuinely useful specs (both marked shipped);
   `.superpowers/` is pure harness residue. `[V]`

---

## 17. Temporary hacks (and why they are load-bearing)

- **`GT_DEMO_*` launch-environment hooks** are compiled into `#if DEBUG` blocks
  throughout the app (`GT_DEMO_TAB`, `_NODE`, `_BEAT`, `_REVEAL`, `_SEED`, `_FREEPLAY`,
  `_REVIEW`, `_REPLAY`, `_SETTINGS`, `_GLOSSARY`, `_TABLE`). They look like test cruft.
  **They are the only way to see most screens**: synthetic taps do not reach Simulator
  content. Do not remove them without replacing the sweep. `[V]` `RootView.swift:94-113`,
  `tools/uisweep.sh`
- **`GT_DEMO_SEED=1` builds a demo `ProgressState` through the real types**, not from a
  JSON fixture, so it can never encode a shape the store would reject. `[V]`
  `ProgressionModel.swift:29-35`
- **`// ponytail:` comment markers** appear in three source files
  (`HandEvaluator.swift:2`, `OutsSpotGenerator.swift:27`, `CallFold.swift:35`). They are
  an artifact of an agent skill (see `CLAUDE_ENV_INVENTORY.md`), but they now carry real
  meaning in this repo: *"this is deliberately the simple version; here is the
  measurement that says simple is enough."* Keep the comments, ignore the provenance. `[V]`
- **River `draw → air` collapse.** The table rewrites the made-hand bucket on the river
  before any policy lookup, because "four to a flush" is factually a draw with no cards
  to come and every draw-betting archetype would otherwise bluff busted draws by
  accident of classification. Deliberate, documented, tested. `[V]` R4-S4 §2

---

## 18. Important unresolved questions

Ranked by what actually blocks something.

1. **The age rating.** `[V]` `docs/submission.md`, `docs/open-questions.md` #11 — **the
   single thing blocking store resumption.** M1 answered Apple's Simulated Gambling
   question "Infrequent/Mild" on the rationale that there was no betting gameplay. The
   테이블 has betting gameplay with bb stakes. An honest re-answer is likely
   "Frequent/Intense" → 17+/KR-19, which is *barred from Apple's self-rating track in
   Korea* and forces a direct GRAC review (administrative: ~10–15 business days + fee +
   gameplay video). Original plan was always to consult Korean game-law counsel before
   the betting-table submission. Not consulted.
2. **Is the bot useful, not just correct?** The top-severity risk in `risks.md` is that
   the archetype bot is a caricature a player grinds out in 50 hands. The mitigation
   shipped as designed; **the residual risk is empirical and only dogfood answers it.** `[V]`
3. **Do the EV-loss bb thresholds survive contact with real answers?** `[V]` R4-S2 §7
4. **Korean app name / branding.** Keep "Glass Table", use 유리 테이블, or a bilingual
   lockup? Never decided. `[V]` open-questions #12
5. **6-max table option?** Cheap to add, demand unconfirmed. `[V]` open-questions #14
6. **`.glasstable` puzzle-sharing format** — schema never designed; blocks the Lab mode
   that was always post-v1. `[V]` open-questions #16

---

## 19. Current development focus

**Fix confirmed defects before the next dogfood build.** Takeover was approved on
2026-09-05. Persistence safety is fixed in the working tree with regression coverage;
the remaining confirmed defects are ordered in ROADMAP NOW. `[V]`

The project is in a **dogfood phase entered deliberately on 2026-07-23** and never
exited. `[C]` + `[V]` (`7daef48`). What that means concretely:

- The owner installs Release builds on an iPhone 12 mini via free provisioning and
  re-deploys weekly (7-day expiry). `[C]`
- Feedback was intended to be filed as GitHub issues. **Zero issues have ever been
  filed**, which is either "no feedback yet" or "the loop was never actually used" —
  the repo cannot distinguish these. `[V]` + `[I]`
- The work that *did* happen after the revamp was self-directed quality work: a UI
  review pass, an accessibility fix, and a performance campaign — not feature work.

See [`ROADMAP.md`](ROADMAP.md) for what is committed vs. merely considered.
