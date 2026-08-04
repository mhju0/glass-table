# Revamp R4-S2 — EV-loss grading (design)

S2 in the R4 decomposition (`2026-08-04-r4-s1-board-texture-design.md` §0). It ships
the grading model Block C requires: **a decision scored by what it cost, in big blinds,
instead of by right or wrong.**

## 1. Why this before the bot

S3 builds an opponent that acts postflop. There is no point giving it a scoreboard that
says 정답/오답 — a bot's whole value is that its mistakes are *sized*. So the scoring
model comes first, gets a drill of its own to prove it teaches, and S3/S4 inherit it.

`decisions.md` §D already fixed the shape: **lead with EV loss in bb**, mapped to a
three-band soft severity with a ~2bb threshold (PokerSnowie's convention), plus a
rolling EV-loss-per-hand. This spec implements that, and nothing more.

## 2. The grading model

```
DecisionOption   label + ev (bb)
gradeByEVLoss(chosen:options:) -> EVLossGrade { loss, best, band }
```

`loss` is `bestEV − chosenEV`, so it is never negative and the best option scores 0.

Bands, from §D:

| loss (bb) | band | Korean |
|---|---|---|
| ≤ 0.5 | `.spotOn` | 최선 |
| ≤ 2.0 | `.close` | 부정확 |
| > 2.0 | `.off` | 실수 |

**Reusing `GradeBand` is deliberate.** Mastery, FSRS scheduling, streaks and the review
queue are all written against those three cases; a fourth grading vocabulary would fork
every one of them. The band is plumbing — **the number is what the user is shown.**

**The thresholds are absolute bb, not a share of the pot.** That is what §D decided and
what PokerSnowie and GTO Wizard report, so a learner reading those tools sees the same
scale. It is also the model's weakest joint: 0.5bb given up in a 6bb pot is a much worse
decision than 0.5bb in a 30bb pot, and the bands cannot tell them apart. Listed in §7 as
the thing to retune from real answers rather than from taste.

## 3. The drill — 「EV 손실」

Hero holds two cards on a **complete board**. A named opponent from a named seat has
bet. Hero picks 콜 or 폴드, and the grade is the bb the choice gave up.

```
EV(폴드) = 0                                    always, by definition
EV(콜)   = equity × (pot + bet) − (1 − equity) × bet
```

`equity` is hero's exact equity against the opponent's range on that board.

### 3.1 The range is stated, never guessed

The screen names the villain's range — "CO 오픈 · TAG" — and the number is computed
against exactly that. **The app does not claim to know what villain bets.** Narrowing a
preflop range by a postflop action is the bot's job (S3); pretending to do it here would
teach a read the app cannot yet justify, and would bias every spot toward calling.

So the drill's question is not "what does he have" but "**given this range, what is this
call worth**". That is the transparency thesis applied to a decision, and it is the same
construction 레인지 어드밴티지 already uses.

### 3.2 Why the river

Measured cost of an exact hand-versus-range equity, release build, ~200 live combos:

| board | cost |
|---|---|
| flop (3) | 571 ms |
| turn (4) | 24 ms |
| river (5) | **1 ms** |

The flop is unusable and the turn would need the off-main-thread treatment 레인지
어드밴티지 needs. The river is free, and **exact** — no sampling, no ±1% caveat, the
same answer every run.

It is also the right street pedagogically. There are no draws left, so the decision is
purely "am I ahead of this range often enough to pay this price" — EV arithmetic with
nothing else mixed in. Earlier streets arrive with the bot.

### 3.3 Spot generation

Deterministic from `(baseSeed, index)`. Hero, board and the opponent's seat/archetype
are drawn; spots where hero's equity is below 5% or above 95% are rejected and reseeded,
the same valve `CallFoldSpotGenerator` uses — a stone-cold nut or total air is not a
decision.

**Marginal spots are not preferred.** The instinct is to filter for close decisions,
since that is where EV-loss grading beats right/wrong. That would be wrong: if every
spot is marginal, every answer scores 최선 and the bands never move. The mix of clear
folds, clear calls and genuinely close spots is what teaches that the grade is
continuous.

## 4. What the reveal says

Leads with the bb, because that is the lesson:

> **−1.4bb** · 부정확
> 콜의 EV는 −1.4bb, 폴드는 0bb.
> 이 레인지 상대로 에퀴티 31%, 필요 에퀴티 33%. 폴드가 더 좋았어요.

Both EVs are always printed, including the one the user picked. A grade that shows only
the better option is asking to be taken on faith.

## 5. Persistence and the rolling number

`AnswerRecord` gains `evLoss: Double?` — nil for every concept that is not graded this
way. It is an optional, so an existing store decodes unchanged and `schemaVersion` stays
at 1.

기록 gains one line: **최근 EV 손실 · 핸드당 x.xbb**, averaged over the EV-graded answers
in the log. One number, next to the calibration one, because §D asks for a progress
signal and a per-hand average is the only one that stays comparable as the log rolls.

## 6. Curriculum

New unit **u6 「손실 줄이기」**, section **결정** — the fifth section, after 기초 ·
가격과 확률 · 레인지 · 보드.

| node | kind | teaches |
|---|---|---|
| `u6-evLoss` | drill | `evLoss` |
| `u6-boss` 「리버 결정」 | boss | `evLoss` mixed with `rangeAdvantage`, `potOdds`, `equitySense`, `callFold` |

Named 리버 결정, not 플랍 결정: the drill is river-only by §3.2, and a boss title that
promised a flop decision would be the app describing an exercise it does not yet have.

`evLoss` is **not** an estimation concept — the answer is a choice, not a number, so it
collects no 90% interval and does not feed calibration.

## 7. Scope — out

- Any street before the river (needs the bot, S3).
- Raise as a third option: its EV depends on what villain does next, which is S3.
- Narrowing a range by a postflop action (S3).
- Retuning the bb thresholds. They ship as §D decided; §2 records why that is the
  model's weakest joint, and it should be revisited against real answers.

## 8. Verification

1. **`gradeByEVLoss` is total** — loss is never negative, the best option always scores
   0, and ties both score 0.
2. **Band boundaries are exact** — 0.5 and 2.0 land in the *better* band.
3. **EV agrees with the engine** — the drill's EV(call) equals `callEV(equity:toCall:pot:)`
   for the same numbers, so there is one formula and not two.
4. **Fold is always 0** — no spot can make folding worth something.
5. **Generation is deterministic and non-degenerate** — same seed same spot; equity
   always inside [5%, 95%].
6. **The band mix is real** — over a run of generated spots, answering 콜 every time
   produces all three bands. A drill that can only ever award one band is not grading.
7. **Old stores still decode** — a `ProgressState` JSON written without `evLoss` loads.
8. **No engine change**, so no release gate: hand-versus-range equity is the existing
   `equityVsRange`, called with `HandRange.combos(removing:)`.
9. **UI sweep** gains the drill and its reveal.
