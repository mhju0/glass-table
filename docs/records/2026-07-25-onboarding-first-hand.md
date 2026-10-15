# 첫 핸드: onboarding as a played hand, not a read document

- **Date:** 2026-07-25
- **Kind:** spec notes
- **Originals:** `.scratch/onboarding-first-hand/spec.md` (tracked: `git show f5c5e22:.scratch/onboarding-first-hand/spec.md`)
- **Asked by / for:** owner complaints about the first-run guide; `docs/decisions.md` (v2 entry) says the research behind it is worth keeping

## What it was
Spec, research and design for replacing `3분 시작 가이드` (8 white cards of Korean prose
on felt, auto-opened on first launch) with one authored, played hand. Two complaints:
(a) visually bland, text-only; (b) pedagogically incomplete, e.g. `MDF = 팟 ÷ (팟 + 벳)`
as prose teaches nothing, and a longer document makes it worse.

## Findings and decisions
Research (why not a longer guide):
- Pretesting effect (Richland, Kornell & Kao 2009): subjects quizzed before reading, who
  mostly answered wrong, beat subjects given extra study time in all 5 experiments,
  analysing only failed items. The benefit comes from the failed retrieval, so prose
  before the drill spends what the decide→reveal loop already provides.
- Duolingo demoted per-unit prose to an optional notebook icon, then hollowed it out; the
  surviving explanation moved into the post-answer banner ("Explain My Answer").
- NN/g mobile tutorial test (70 users): the only significant effect ran backwards; readers
  rated the same tasks harder (SEQ 4.92 vs 5.49 for skippers). Andersen et al.
  (n≈45,000, 3 games): forced tutorials bought nothing.
- Conclusion: the container was wrong, not the length; explanation moves to where the
  confusion is.

Design part 1, in-drill teaching (shipped first, net −20 LOC):
- `DrillScaffold(subtitle:)` fed from `DrillKind.explain`, rewritten to verbs.
- `GlossaryChip` + `GlossaryView(focus:)` in all four reveals, scrolled to and tinting
  the term.
- Outs reveal leads with `남은 44장 중 7장`; rule-of-2 percent subordinate, labelled `근사`
  (natural frequencies beat percentages, Gigerenzer). 44 is computed as
  `52 − (hero+villain+board)`, never typed; 47 is the flop number, and two of three
  design candidates got this wrong.
- `gradeMDF` derives instead of asserts: `alpha = 100 − MDF` is the villain's bluff
  break-even. This hole existed in the guide and the glossary.

Design part 2, `FirstHandView.swift`: one hand, six beats, a guess before every
explanation. Hand = the `RevealTests` fixture / `RevealView` preview: `AhKh` vs `QsQd` on
`Qh7h2s3c`.
| beat | asks | shows |
|---|---|---|
| 1 outs | 5/7/9? | 9 hearts, count holds 450ms, 2♥·3♥ struck 160ms apart, 9→8→7; struck cards tap to `explainRiver` |
| 2 pot odds | 20/25/33%? | `PriceBar` 팟 10 / 벳 5 / 콜 5; 33% gets its own diagnosis (내가 낼 5bb를 안 더한 값) |
| 3 call/fold | call? fold? | `7장 < 11장 → 폴드`, gap `4장 부족` |
| 4 MDF | how often must villain defend? | villain's price first (5bb to win 10bb → break even 1 in 3), then 2-of-3 shields |
| 5 blockers | QQ combos? | villain cards face down (only place in the app), 6 QQ combos with 3 containing Q♥ struck |
| 6 summary | — | tally + EV: this call x100 = −182bb, so fold wins |
- Key numbers, engine-verified: 44 unseen, 7 outs, rule of 2 = 14%, required equity 25% =
  exactly 11 of 44 cards, MDF 66.7%, alpha 33.3%, QQ 6→3 combos, EV −1.82bb per call.
- Rules held: the hand zone never re-lays-out (card size capped at 48 vs drills' 64; last
  beat collapses to one strip). Credit before correcting (`하트 9장, 맞게 셌어요`;
  `closeWithin: 2` grades the designed trap 근접). No new colours (amber stays 근접's; "my
  number" is `GT.cta`; dead cards use a strike). Writes nothing to `ProgressStore` ("a 🔥
  handed out for free is a lie"), stated on screen.
- Accessibility: Reduce Motion collapses staggers and lands 9→7 in one step; outs tray
  VoiceOver speaks the settled lesson; face-down cards never name the hidden card;
  `ViewThatFits` ladders for Dynamic Type; 건너뛰기 on every beat.
- Deliberately not built: a coach subsystem (error classifier, 11 tips, `errorRun` on
  `DrillProgress`), because a new field breaks synthesized `Decodable` and
  `ProgressStore.load()` swallowed it with `try? … ?? DrillProgress()` (`Progress.swift:33`),
  resetting every 🔥 to 0; "2nd consecutive miss" is `@State`. Staged `WhySteps` (would
  split another package's `whyText` on punctuation absent at `Reveal.swift:60`). Home
  chain layout deferred to the next commit.

## Outcome
Shipped `2cd45fc` (2026-07-25, branch `onboarding-first-hand`). Later replaced by the
September welcome/warm-up and October experience-first openings (see those records and
`docs/decisions.md`).

## Still open
The spec's stated limit: removing a forced first-run wall is unmeasurable here (no
analytics by design, `decisions.md §5`); it shipped on the research above plus watching
three friends from the target home game through one first session. No A/B available.
