# 첫 핸드: onboarding as a played hand, not a read document

Status: shipped 2026-07-25 (branch `onboarding-first-hand`)

## Problem

`3분 시작 가이드` was 8 white cards of Korean prose on green felt, auto-opened on
first launch. Two complaints, and they need different fixes:

- **(a) visually bland** — text-only, no illustration, no motion, nothing that
  looks like the card game it teaches.
- **(b) pedagogically incomplete** — a beginner reads `MDF = 팟 ÷ (팟 + 벳)` as
  prose and learns nothing. Making the document *longer* makes this worse.

## Why not a longer guide

Benchmarked against education apps, game tutorials, poker/fintech trainers and
the onboarding-effectiveness literature. Three findings pointed the same way:

- **Pretesting effect** (Richland, Kornell & Kao 2009). Subjects quizzed *before*
  reading — and who mostly answered wrong — outperformed subjects given extra
  study time, across all 5 experiments, analysing only the items they had failed.
  The benefit comes from the failed retrieval attempt. So explanation placed
  *before* the drill spends the budget the app's decide→reveal loop already owns.
- **Duolingo** demoted per-unit prose out of the pre-lesson slot to an optional
  notebook icon, then hollowed it out further; the explanation that survived
  moved *into* the post-answer banner, targeted at the specific mistake
  ("Explain My Answer"). Revealed preference from the most-instrumented learning
  app there is.
- **NN/g** mobile tutorial test (70 users): the only significant effect ran
  backwards — people who read the tutorial rated the same tasks *harder*
  (SEQ 4.92 vs 5.49 for skippers). Andersen et al. (n≈45,000, 3 games) found
  forced tutorials bought nothing.

Conclusion: the container was wrong, not the length. The five modes still get
explained — the explanation moves to where the confusion is.

## Design

### 1. In-drill teaching (shipped first, net −20 LOC)

- `DrillScaffold(subtitle:)` fed from `DrillKind.explain`, rewritten to verbs —
  so "what does this train" is answered on **every** visit, not once in a guide.
- `GlossaryChip` + `GlossaryView(focus:)` in all four reveals: the reference
  table the app already had becomes the on-demand explainer, scrolled to and
  tinting the one term.
- Outs reveal leads with `남은 44장 중 7장`; rule-of-2 percent subordinate and
  labelled `근사`. Natural frequencies beat percentages for beginners
  (Gigerenzer). **44 is computed** as `52 − (hero+villain+board)`, never typed —
  47 is the flop number, and two of three design candidates got this wrong.
- `gradeMDF` derives instead of asserts: `alpha = 100 − MDF` is villain's bluff
  break-even, so the second sentence explains the first. Always exactly true, no
  rounding branch. This hole existed in the guide *and* the glossary.

### 2. 첫 핸드 — `FirstHandView.swift`

One authored hand, six beats, a guess before every explanation. The hand is the
repo's own `RevealTests` fixture / `RevealView` `#Preview`, so every number is
pinned by tests that already exist: `AhKh` vs `QsQd` on `Qh7h2s3c`.

| beat | asks | shows |
|---|---|---|
| 1 아웃 | 몇 장이 오면 이겨요? (5/7/9) | 9 hearts fan up, count reads **9**, holds 450ms, then 2♥·3♥ take the existing `dead:` strike 160ms apart and the count rolls **9 → 8 → 7**. Struck cards stay tappable → the shipped `explainRiver` panel |
| 2 팟 오즈 | 몇 % 이상 이겨야? (20/25/33) | `PriceBar` with 팟 10 / 벳 5 / **콜 5** printed inside the segments; 33% gets its own diagnosis line ("내가 낼 5bb를 안 더한 값") |
| 3 콜/폴드 | 콜? 폴드? | `7장 < 11장 → 폴드`, gap named `4장 부족`. Both earned numbers sit on the felt *during* the decision |
| 4 MDF | 상대는 세 번에 몇 번 지켜야? | Villain's price stated first (내가 5bb 걸어 10bb 노림 → 세 번에 한 번 본전), then 2-of-3 shields. MDF as *someone else's* incentive |
| 5 블로커 | 상대가 QQ일 조합은? | Villain's cards flip **face down** — the only place in the app they do — then 6 QQ combos with the 3 containing Q♥ struck. The board is a blocker too |
| 6 정리 | — | Tally + EV close: this call ×100 = **−182bb**, so 폴드가 이긴 거예요 |

**Key numbers, all verified against the engine:** 44 unseen · 7 outs · rule of 2
= 14% · required equity 25% = **exactly 11 of 44 cards** (which is why call/fold
can be a count, not a division) · MDF 66.7% · alpha 33.3% · QQ 6→3 combos ·
EV −1.82bb/call.

### Design rules held

- **The hand zone never re-lays-out.** Five concepts on one scene, so working
  memory holds a hand instead of five diagrams. Card size is capped at 48 (vs the
  drills' 64) so each beat's diagram fits beside it rather than sliding under the
  sheet. The last beat collapses the hand to one strip, since by then the summary
  is the content.
- **Credit before correcting.** Beat 1 opens `하트 9장, 맞게 셌어요` — never
  `틀렸어요`. `closeWithin: 2` means the designed trap grades 근접 anyway.
- **No new colors.** `GradePill` already owns amber for 근접, so "my number" is
  `GT.cta` and dead cards are distinguished by a *strike* (a shape) — Differentiate
  Without Color passes for free.
- **Writes nothing to `ProgressStore`.** A 🔥 handed out for free is a lie the
  user catches later. Stated on screen.

### Accessibility

Reduce Motion collapses every stagger and lands 9→7 in one step. The outs tray's
VoiceOver label always speaks the settled lesson, so the timed roll is never the
only channel. Face-down cards never name the card they hide. `ViewThatFits`
ladders on both the chip row and the card rows for Dynamic Type. 건너뛰기 is on
screen at every beat.

## Deliberately not built

- **Coach subsystem** (error classifier, 11 tip strings, `errorRun` on
  `DrillProgress`). Adding a field breaks synthesized `Decodable` for every
  existing on-device file, and `ProgressStore.load()` swallows it with
  `try? … ?? DrillProgress()` (`Progress.swift:33`) — every user's 🔥 would
  silently reset to 0. It also never needed persisting: "2nd consecutive miss" is
  `@State` in the drill view.
- **Staged `WhySteps`** (Photomath's collapsed-step reveal with the changed token
  highlighted). Wanted, but the proposed implementation split another package's
  `whyText` on punctuation, and `Reveal.swift:60` contains neither separator.
- **Home chain layout + numberless organizer line.** Next commit.

## Honest limitation

Removing a forced first-run wall is **unmeasurable here** — no analytics, by
design (`decisions.md §5`). This ships on the research above plus watching three
friends from the target home game through one first session, silently. There is
no A/B available.
