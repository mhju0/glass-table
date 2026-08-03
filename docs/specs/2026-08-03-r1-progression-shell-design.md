# Revamp R1 — Progression shell + Block A floor (design)

Approved 2026-08-03. First slice of a four-slice re-architecture that turns Glass
Table from five same-tier math drills into a beginner→advanced learning path.

Supersedes the flat five-box home. Resolves `open-questions.md` #15 (curriculum
unlock specifics) and #13 (visual tone).

---

## 0. Why the revamp

The shipped app is **the middle of the math block with no floor under it**, and two
intermediate drills sit on the front page.

| Drill | Verdict |
|---|---|
| 아웃 카운팅 | Keeper, mis-scoped. `OutsSpot.villain` is a *known single hand* — card counting, not outs. Turn-only, so "rule of 2/4" is really rule-of-2. |
| 팟 오즈 | Keeper, correctly placed. But `BetSpot` is `(pot, bet)` with no cards — arithmetic disconnected from a hand. |
| 콜/폴드 | Keeper. The only drill that *composes* three skills. The natural Block A boss. |
| MDF | **Mis-placed.** Intermediate skill whose prerequisites (fold equity, combos, ranges) aren't in the app. Ships only the frequency half; the actual skill is selecting which combos make up the defense. |
| 블로커 | **Misnamed.** `comboCount(rankA:rankB:kind:removed:)` is combinatorics, not blockers. Real blockers is advanced. |

Deeper: `product-brief.md` promises "ranges, not hand ladders," but every drill grades
against a known villain hand. **There is no range type in the engine.** The thesis is
not yet implemented.

Missing floor, in order of damage: showdown/hand reading · pot arithmetic · position ·
preflop RFI · **EV as something the user computes** (the brief's headline — the engine
has `callEV` but never asks for it).

## 1. Slice decomposition

Each slice is independently shippable and gets its own spec + plan.

| | Slice | Unlocks |
|---|---|---|
| **R1** | **Progression shell + Block A floor** (this spec) | A real beginner ladder on today's engine |
| R2 | `Range` primitive + 13×13 grid + declared RFI charts | 12+ of 20 exercises; the product thesis |
| R3 | Range Read mode | The strongest differentiator |
| R4 | Archetype bots + Table | Block C; "advanced" becomes real |

R1's progression architecture is designed for the full ladder in §2 but **builds only
the Block A subset that runs on the current engine.**

## 2. The curriculum ladder (full, for context)

Ordered skill blocks. `✅` runs on today's engine · `⚠️` small extension · `❌` needs `Range`.

**Block A — beginner (exact answers).** 쇼다운 ✅ · 팟 계산 ✅ · 포지션 ⚠️ · 팟 오즈 ✅ ·
아웃 ✅ · 에퀴티 감각 ✅ · 콤보 ✅ · 레인지 표기법 ❌ · RFI 차트 ❌ · EV 계산 ✅ ·
콜/폴드 ✅

**Block B — intermediate.** 브레이크이븐 블러프 · 오픈 대응 · BB 디펜스 · 아이소 레이즈 ·
히트 프리퀀시 ★ · 레인지 어드밴티지 ★ · MDF (promoted here, completed) · 레인지 리드 ★

**Block C — advanced (EV-loss grading, never binary).** SPR · 블로커 (real) ·
C-벳 결정 · 턴 파티션 ★ · 리버 블러프캐치 · 익스플로잇 편차

★ = exercises no surveyed competitor ships. The wedge.

**Not drillable, ship as glossary entries with an explicit "why not":** live reads,
tilt, game selection, table image. No ground truth inside a closed decision; faking it
teaches false confidence.

## 3. Scope — in

### 3.1 Five new Block A drills (near-zero engine work)

| Drill | Asks | Grades | Engine |
|---|---|---|---|
| **쇼다운** | Which five cards play, who wins | Exact, from evaluator | `bestHand` ✅ |
| **팟 계산** | Track the pot through an action sequence; 33/50/75% of pot | Exact arithmetic | ✅ |
| **포지션** | How many act behind; rank two seats | Exact | new `Position` ⚠️ |
| **에퀴티 감각** | Hand vs hand, estimate equity | Interval (§5.2) | `exactEquityHeadsUp` ✅ |
| **EV 계산** | Compute the EV of a call; the outcome is shown as a distractor | Interval (§5.2) | `callEV` ✅ |

### 3.2 Changes to shipped drills

- **블로커 → 콤보.** Rename only; the drill was always combinatorics. Glossary term,
  home copy, `DrillKind` case, progress store key all follow. Existing progress
  migrates by key rename (§8.3).
- **MDF leaves Block A.** Parked for Block B (R2), where its prerequisites exist. The
  screen is **not deleted** — it stays reachable under 자유 연습 so nothing shipped is
  lost.
- **아웃** gains flop spots (currently turn-only) and splits its answer (§5.2).
- **콜/폴드** becomes the Block A boss node.
- **`FirstHandView` is not deleted.** Its authored hand (A♥K♥ vs Q♠Q♦ on Q♥7♥2♠3♣)
  becomes the **Unit 2 boss**, where the math concepts meet in one hand. It was always
  a graduation, not an introduction.

### 3.3 The shell

The path, the teach pattern, mastery, review scheduling, daily, streak, calibration,
and the retinted design system. Detailed in §4–§8.

## 4. Progression architecture

### 4.1 Structure

**Sections → Units → Nodes.** A node is one exercise type at one difficulty band.
Units are 5–8 nodes and **end in a boss node** drawing from this unit plus 2–3 earlier
units, deliberately juxtaposing confusable spots (same board / different position).

R1 ships Section 기초 with two units:

| Unit | Nodes |
|---|---|
| **1 · 테이블 읽기** | 쇼다운 · 팟 계산 · 포지션 · 콤보 · **[boss] 섞어 풀기** |
| **2 · 가격과 확률** | 팟 오즈 · 아웃 · 에퀴티 감각 · EV 계산 · **[boss] 콜/폴드 (첫 핸드)** |

Unlocking is linear and **not skippable in R1** — the user is an honest beginner
(the design tiebreak) and the diagnostic in §6 already lights early nodes for someone
who doesn't need them.

### 4.2 Practice schedule inside a node

First exposure is **blocked** — 4–6 items of the same type in a row, which acquires
faster. Every node after the first interleaves with due concepts.

### 4.3 Mastery — four tiers, per concept (not per drill)

| Tier | Awarded by |
|---|---|
| 시도 | Attempted, under 70% |
| 익숙 | 70–99% on the concept's own drill |
| 능숙 | A clean run on the concept's own drill |
| **숙달** | **Only by a mixed boss node, after a 12h cooldown** |

숙달 being unreachable through blocked practice is the point: it certifies *transfer*,
not fluency. The cooldown is free spacing enforcement.

**Hero stat is "concepts at 능숙/숙달" plus calibration — never XP, never streak.**

### 4.4 Difficulty

Three bands per drill type, expressed as **generator parameters** (e.g. an outs spot
with more excluded cards is harder), assigned at authoring time. A local controller
moves the user's band: trailing-20 accuracy > 0.90 → up, < 0.80 → down. Target success
rate ≈ 0.85.

**No per-item ratings and no Glicko in R1** — 10 nodes isn't enough content for a
rating system to earn its complexity. Revisit at R2.

**No difficulty selector anywhere in the UI.** It is the single most common complaint
across this app category.

### 4.5 Spaced review — over concepts, not hands

Hands get memorized; concepts don't. Each concept carries FSRS state (difficulty /
stability / retrievability) using the **published FSRS default weights**, with one
knob (desired retention, default 0.90). No per-user parameter optimization in R1.

**The structural advantage:** when a concept comes due, the seeded generator produces a
**fresh spot** rather than replaying a stored card — `SplitMix64` plus a generator per
drill already exist. Infinite non-repeating items for a due concept, which no
flashcard app can offer.

### 4.6 Repeated failure

- **3 misses on a concept** → the app offers 천천히 (§5) unprompted.
- **8 misses** → stop drilling that concept and surface the explainer instead.
  Repeated failure at that depth is a content gap, not a desirable difficulty.

## 5. Teaching

### 5.1 Three stages, on every new concept, forever

Not a one-time onboarding screen — this is how every node opens.

1. **보여주기** — the app solves one fully, in the order a player thinks it. The user
   answers nothing. Beats advance on tap so the middle of the argument can't be skimmed.
2. **함께 풀기** — same reasoning, same steps, but the user supplies them one at a
   time. Later steps sit greyed below so the shape of the argument stays visible.
   힌트 always available, never penalized.
3. **혼자 풀기** — scaffolding gone. The existing decide → reveal → grade loop.
   **Grading starts here and only here.**

**Availability:** auto-plays on first exposure; a permanent 천천히 보기 affordance
afterward, invokable on any spot including one just missed; auto-offered at 3 misses.

### 5.2 Micro-steps — the board teaches, the text captions

Narration is **templated per drill type**, driven by engine data, so it runs on *any*
generated spot. One beat-script per drill type — **9 scripts covers R1's roster**, ~11
the full Block A. Beat count follows the reasoning; no cap.

Rules, derived from the worked example (아웃, on the 첫 핸드 hand):

- **Highlighted cards glow; everything else dims to 26%.** The five cards under
  discussion can never be misidentified.
- **The layout holds still between beats.** Only the glow moves — that is what makes
  "my hand" → "their hand" read as a comparison rather than two screens.
- **Dead cards strike through in place; they never vanish.** Seeing *what* was removed
  and *why* is the lesson.
- **Arithmetic is shown, not asserted** — "하트 13장 − 내 손 2장 − 보드 2장 = 9장" is
  verifiable by looking.
- **No flashing.** WCAG 2.3.1 caps flashing at three per second as a seizure risk. The
  highlight is a slow ~1.9s breathe that becomes a static ring under Reduce Motion;
  the dimming carries the same information with zero motion.
- **건너뛰기 stays on screen on every beat** — the rule `FirstHandView` already follows.

The seven beats for 아웃 (the reference implementation): the table → my five → their
five → the four hearts, "이기려면 플러시" → all 9 remaining hearts laid out countable →
2♥·3♥ strike out, "보드가 페어가 되면 상대는 풀하우스" → "그래서 7장."

`OutsSpot` already stores `excluded` and each reveal already carries `whyText`, so the
beat data exists; only the staged presentation is new.

### 5.3 Voice

**No persona.** The app states facts — "지금 내 패 — 에이스 하이", "13 − 4 = 9장". No
mascot, no character, no name. An instrument, not a companion: it ages well over
hundreds of sessions and it protects the study-tool framing that keeps the Korean
rating low (`decisions.md` §7).

### 5.4 Grading: exact vs estimation

Exactness decides the input control, because "근접" is dishonest on a question with one
right answer.

| | Drills | Input | Grade |
|---|---|---|---|
| **Exact** | 쇼다운 · 팟 계산 · 포지션 · 콤보 · 팟 오즈 · 콜/폴드 · 아웃 *(count)* | Single value | Binary |
| **Estimation** | 에퀴티 감각 · EV 계산 · 아웃 *(equity %)* | Point + 90% interval | Winkler interval score |

아웃 splits deliberately: the out **count** is exact (you can count them), the
**equity** from rule-of-2/4 is explicitly an approximation — which is already how the
reveal presents it ("남은 44장 중 9장" then "룰 오브 2로 약 18% · 근사예요").

**Calibration** = the share of stated 90% intervals containing the truth, against a
nominal 0.90. This is the one efficacy claim in this category with real evidence behind
it, and it is structurally ungameable — a wide interval scores badly on Winkler even
though it always contains the truth.

The existing 정확/근접/빗나감 bands and `VerdictRow`'s four redundant channels (shape,
structure, text, colour) are kept for estimation drills. Exact drills get a
two-state verdict.

## 6. First run

The onboarding guide is not a separate system. It is **the first four nodes of the
path, played in order**, ~6 minutes.

These are Unit 1's first three nodes **in their normal path order** — first run is not
a parallel track, so it cannot contradict the linear unlock in §4.1.

1. **쇼다운**, 3 items. No numbers, no jargon. Establishes that the app has a provably
   right answer, and quietly checks the user can read a board. Include one chop.
2. **팟 계산**, 1 item, carrying the one framing line:
   *"숫자는 답을 정한 뒤에 보여줘요. 그게 이 앱의 전부예요."* Commit to the pot size,
   then see it. The thesis delivered by doing, not explaining.
3. **포지션**, running the full three-stage pattern. The first 보여주기.
4. **진단**, 8 mixed items across the above. Sets the starting difficulty band and may
   pre-clear nodes the user demonstrably doesn't need, so the path doesn't open at
   zero. Pre-clearing is the *only* way a node is skipped (§4.1).

Handoff: the path opens with early nodes lit and the next one live.

**Deliberately absent from first run:** any difficulty selector, the notification
permission prompt (day 3, after a real session), and any explanation of streaks.

## 7. Motivation

### 7.1 Build

- **Per-concept mastery dashboard** (기록 tab) — the screen a serious amateur
  screenshots. Extends the existing `StatsView`.
- **Calibration readout** with one blunt sentence: *"90% 구간이 정답을 담은 비율 58%
  — 아직 과신하고 있어요."*
- **Streak, decoupled from volume.** A streak day is "one session including ≥1
  due-queue item," not an item count.
- **Silent, generous forgiveness.** Two auto-equipped freezes applied with **no
  dialog**, 48h earn-back. Forgiveness raises both streak length and retention; the
  punitive version is worse on both.
- **Milestone animations at 7 / 30 / 100 / 365 only.**
- **Daily** — 5 spots seeded from `hash(yyyy-MM-dd + contentVersion)`, identical for
  every user, zero backend. Past onboarding, weighted toward the due queue while the
  seed stays date-derived.
- **자유 연습** — every drill, unlimited, one tap under 길. **No caps, ever.**
- **Progress export/import** as JSON to Files. With no accounts, a lost phone is a lost
  streak; this is the most likely source of one-star reviews in a no-account app. The
  store file *is* the export format (§8).

### 7.2 Do not build — engagement theater

- ❌ **Hearts / energy / lives / session caps.** A monetization throttle in a
  learning-science costume, and there is nothing to monetize. Worse: punishing mistakes
  suppresses the guess-then-feedback loop that calibration training requires.
- ❌ **Leagues / leaderboards.** Genuinely effective and genuinely lost to the offline
  constraint. **Do not fake it with bots** — detectable and dishonest.
- ❌ **Badges, collectibles, avatars, gems, cosmetic currencies.**
- ❌ **XP paid for time-on-task** — the mechanic that has people redoing mastered
  lessons at 11:50pm. No XP at all; 숙달 count and calibration are the numbers.
- ❌ **Timed modes as the primary loop.**

## 8. Data

### 8.1 Storage — one Codable file

`DrillProgress` is three integers per drill and cannot carry any of §4. Replaced by a
single `Codable` store: one file, **`.atomic` writes**, a `schemaVersion` int.

Sizing: ~60 concepts × 200B + ~60 nodes × 100B + a **capped 500-entry ring buffer** of
graded answers for calibration ≈ **under 100 KB**. No query needs an index — "which
concepts are due?" is a filter over 60 records.

Rejected: **SwiftData** (drags a framework into `GlassTableDrills`, which the project's
architecture requires stay a plain, simulator-free-testable package; if the logic stays
pure — which it must — SwiftData degrades to a worse file format), and **SQLite/GRDB**
(the project ships zero third-party dependencies; unjustifiable at 100 KB).

`ProgressStore`'s load/save shape is kept as the seam, so the backend is swappable in
one file. **Escape hatch if an uncapped history is ever wanted:** append that log to a
separate JSONL file and leave state in the main one.

### 8.2 Latent bug fixed here

`Progress.swift:44` writes with **no `.atomic` option**. A kill mid-write truncates the
file, and `load()`'s `try?` + `??` silently returns fresh empty progress — **progress
vanishes with no error.** Today that costs three integers; once one file holds every
concept, schedule, and a long streak it is catastrophic.

R1 fixes both halves: atomic writes, and a `load()` that distinguishes "no file yet"
from "file failed to parse" (the latter preserves the corrupt file and surfaces the
export/import recovery path rather than silently resetting).

### 8.3 Migration

Existing per-drill files are read once and folded into the new store: `blockers` →
`콤보` concept, `outs`/`potodds`/`callfold`/`mdf` by key. Totals and streaks carry over;
FSRS state initializes fresh. Old files are left on disk, unread, for one release.

### 8.4 Module placement

| Module | Adds |
|---|---|
| `GlassTableEngine` | `Position` (seat / order-of-action). Nothing else. |
| `GlassTableDrills` | New spot generators; curriculum graph; node/unit state; mastery; FSRS scheduler; streak + freeze; calibration scoring; the store. **All of it plain Swift, tested without a simulator.** |
| `GlassTable` | 오늘 / 길 / 기록 tabs; the three-stage teach UI; the micro-step player; retinted design system. |

## 9. Visual system

Direction: **펠트 + 카드지** — felt surface with warm cream cards laid on it. The
metaphor made literal, and the smallest migration, since `DrillScaffold`'s green-zone
+ sheet survives with a retint.

| Token | From | To |
|---|---|---|
| Felt | `#157A47`, gradient to `#1B8A52` | `#1B4234`, flat |
| Sheet | `#FFFFFF` | `#F4F1E9` cream |
| Ink | `#191F28` | `#1A2621` |
| Hairline on felt | — | `#2A5546` |

The current greens are bright, high-chroma, and cover the full screen — precisely the
long-session fatigue problem. Real felt under room light is far darker and greyer.
Going deeper is what makes it read as a table rather than a green app.

**Navigation:** three tabs (길 · 오늘 · 기록), **icon + label**, hairline top border,
native structure with a custom tint. Free play is never a tab; it lives under 길.

**Home is 오늘** — one screen answering one question: 다음 단계 → 복습 → 캘리브레이션.
The path is one tap away. A grid of twenty exercises is exactly the choice paralysis
the path exists to remove.

Preserved without change: Pretendard, Dynamic Type via `relativeTo: .body`, and
`VerdictRow`'s four redundant channels. Grade band tints are re-derived against cream
and must re-measure at WCAG AA or better.

## 10. Verification

Success criteria, in order:

1. **Progression logic is proven without a simulator.** New tests in
   `GlassTableDrills`: FSRS scheduling with injected dates; mastery promotion
   (including that 숙달 is unreachable outside a boss node, and the 12h cooldown);
   linear unlock rules; streak and freeze across date boundaries, DST, and timezone
   change; Winkler scoring; daily-seed determinism for a fixed date; store round-trip;
   **corrupt-file handling that does not silently reset.**
2. **The engine gate still passes.** `Position` touches `GlassTableEngine`, so
   `swift test -c release --package-path GlassTableEngine` is required, not optional.
3. **Every new drill's correct answer is computed, never authored.** Each new generator
   gets property tests against the engine.
4. **The five existing drills still grade identically.** Their generators and grading
   are untouched by R1; a regression test pins current outputs for a fixed seed range.
5. **Micro-step scripts run on arbitrary generated spots** — not just the authored
   hand. Test: for N seeded spots per drill, the beat script produces a complete,
   non-empty narration with no placeholder left unfilled.
6. **Screenshot verification** of 오늘 / 길 / 기록 / 보여주기 / 함께 풀기, via the
   existing `GT_DEMO_*` hooks extended to the new screens.
7. **Retention smell test.** The developer opens it daily without forcing it, and
   reaches 숙달 on at least one concept through a boss node.

## 11. Implementation shape

R1 is too large for one plan, exactly as M1 was (five plans). Expected sub-projects,
in dependency order — each gets its own plan and ships behind the previous:

1. **Store + migration** — the Codable store, atomic writes, corrupt-file handling,
   fold-in of the five existing per-drill files. Nothing user-visible; everything else
   depends on it.
2. **Progression core** — curriculum graph, unlock, mastery tiers, FSRS scheduler,
   streak + freeze, calibration scoring. Plain Swift in `GlassTableDrills`, fully
   tested before any UI exists.
3. **Five new drills** — generators, grading, property tests. `Position` in the engine.
4. **Shell UI** — 오늘 / 길 / 기록, the retint, the nav.
5. **Teach pattern + micro-steps** — the three stages and the nine beat scripts.
6. **First run** — the four-node intro and the diagnostic.

## 12. Open questions

1. ~~**Dark mode.**~~ **RESOLVED 2026-08-03: ship the dark twin.** `GT`/`GTBand`
   resolve per interface style and `UIUserInterfaceStyle: Light` is removed, so the app
   follows the system. Dark inverts the card to an elevated dark green; playing-card
   faces dim to bone rather than staying paper-white, so a grid of nine outs is not
   nine floodlights. `GT.onCTA` exists because CTA lettering flips with its fill.
2. **Widget** (streak + today's spot). Recommended by research as a re-entry surface,
   and cheap with a plain-file store via an App Group. Deferred to R2 — not needed to
   validate the path.
3. **Korean copy for the new drills and all beat scripts** is developer-owned
   (`open-questions.md` #1), written during UI-copy work as with M1. *Settled so far:*
   cards are named with suit symbols via `Card.display` ("10♥"); `Card.description`
   ("Th") is the parse format and never appears in prose.
4. **Where the declared preflop charts come from.** *Direction chosen 2026-08-03:
   adopt and name a public chart.* **Still blocked on a licensing answer** — see §13.
   **Blocks R2, not R1**, and remains the highest-risk unresolved question in the
   product: the transparency thesis dies if the answer is "trust us."
5. **Postflop grading mode** (EV-loss in bb vs bands). Genuinely EV-indifferent spots
   exist in Blocks B/C, where marking a user "wrong" is factually false. Blocks R4.
6. ~~**MDF's placement.**~~ **RESOLVED 2026-08-03: stays parked.** It keeps a concept
   and free-play access but no path node until Block B (R2), where its prerequisites —
   fold equity, combos-in-a-range, ranges — actually exist. Shipping only the frequency
   half would teach a referent-free formula, which is the exact defect §0 identified.

## 13. The preflop chart licensing problem (blocks R2)

Research on 2026-08-03 found **no NLHE preflop chart under an open or redistributable
licence.** Every widely-used chart — Upswing's free RFI charts, PokerCoaching's free
"implementable" charts, GTO Wizard's free ranges, Preflop Wizard, FreeBetRange — is a
marketing asset of a commercial training site, published free to *read* under
all-rights-reserved terms. None grants reproduction.

That matters because shipping a chart's 169 cell values inside the app **is**
redistribution, attribution notwithstanding. Solved frequencies are arguably
uncopyrightable facts, but a specific chart's exact values function as a database, and
"we cited them" is not a licence.

Two further problems with adopting one wholesale:

- **No canonical 8-max chart exists.** The category standard is 6-max, with 9-max for
  full ring. `decisions.md` §E already records that 8-handed has to be interpolated.
- The strongest candidate by popularity, GTO Wizard, is the one product the brief names
  as the direct competitor. Shipping their solved values inside a free competing app is
  the riskiest of all the options.

**Recommendation — the hybrid, which is also what `decisions.md` §E already decided:**
*name the public charts as the benchmarks we validate against* (Upswing's free 9-handed
RFI PDF and PokerCoaching's free charts — both explicitly published free, both widely
used), and *ship our own generated values with the derivation published in-app*. The
transparency payload is the derivation being inspectable, not the source being famous;
naming what we checked ourselves against is stronger than copying, and it is the only
version with no licensing exposure.

**Needs a decision before R2 starts.**

## 14. Out of scope

No `Range` type, no 13×13 grid, no RFI charts, no archetypes, no bots, no Table, no
Range Read (R2–R4). No leagues, no XP, no hearts, no IAP, no ads, no accounts, no
networking. No iPad, no Android, no web. MDF is parked, not deleted.
