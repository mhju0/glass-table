# Revamp R4-S4 — 테이블 (design)

The last slice of R4: **play a postflop hand against a declared opponent, and have
every decision scored in big blinds.** S1 gave boards a vocabulary, S2 the cost-based
grade, S3 an opponent that acts. S4 only composes them — it adds no new poker
knowledge, which is the sign the decomposition was right.

## 0. Decomposition

Two commits, each green on its own:

- **S4a — the hand engine**: `TableHand`, a pure value-type state machine in
  `GlassTableDrills` with the grading built in. Fully tested, no UI.
- **S4b — the surface**: the 테이블 tab, action buttons per decisions.md §A, the
  per-decision grade, the hand summary. Sweep hooks.

## 1. Format — a postflop hand, honestly scoped

**Heads-up, single-raised pot, hero in position.** The archetype opens 3bb from an
earlier seat (his hand dealt *from his opening range* — the premise is real), hero on
a later seat calls with a playable hand, blinds are dead: pot 7.5bb, stacks 100bb,
flop. The preflop script is shown in the history line, not hidden.

**Hero's preflop decision is deliberately not played, because grading it would teach
a lie.** Under the checkdown model (§3) a 3bb call needs ~29% equity, and almost any
two cards clear that against any opening range — the model ignores exactly the future
betting that makes preflop folds right. A grade that says "call everything" is worse
than no grade. Hero's hand is dealt from a stated playable band (top 30% by Chen)
instead; a real defending-chart slice can add the preflop street later, the way R2
added RFI.

**Betting**: the archetype acts first on every street (he is out of position — he
opened from an earlier seat). Checked to, hero may check or bet any §A size
(33/50/75/100/150% pot). Facing a bet: fold, call, or raise **to 3× the bet**, one
raise per street — the second raise becomes a call. Fixed raise size and the one-raise
cap keep every subtree closed-form (§3) and are stated on screen, not smuggled.
Bets are capped by the 100bb stack; a capped bet is simply all-in and the model
handles it as a call-or-fold node like any other.

**The opponent is chosen, not assigned**: the entry screen picks one of the five
archetypes (or 랜덤). Knowing who you sit with is the point of an exploit trainer.

## 2. The bot — nothing new

Preflop he opened (that *is* `raiseRange(from:)`). Postflop he is S3 verbatim:
`opens(with:)` when checked to, `response(toBetWith:)` facing a bet, his §1 bet size,
raise to 3× likewise. His range narrows street by street with S3's inversion — every
action he takes filters his combo set against the *board it happened on* — so at any
moment the app can print exactly the combos he can still hold, and his dealt hand is
always among them (tested invariant).

One structural consequence, pinned by test: **no S3 row slowplays** — every
archetype's check buckets are disjoint from its raise buckets — so a check-raise
cannot happen and hero never *faces* a raise. The machine supports that phase anyway;
the pin exists so a future slowplay row forces real coverage before it ships.

## 3. Grading — the checkdown model, disclosed

Every hero decision is graded by S2's `gradeByEVLoss` over the legal options. EVs are
computed against the bot's **narrowed range**, under one stated assumption: **after
this street's action settles, the hand checks down.** 이후 베팅은 계산에 안 넣어요.

This is the model the app has used since u2 — 콜/폴드 graded turn calls by exact
equity over the remaining cards with no future betting — now applied at every node.
On the river it is exact. Earlier it is an approximation, and the reveal says so.

With it, every option is closed-form per villain combo `w` (equity `e` = hero's
checkdown equity vs `w` on the current board):

- 폴드 = 0. Money already in the pot is not hero's.
- 체크 (behind) = `e·pot`.
- 콜 of `b` = `e·(pot+2b) − b`.
- 벳 `b`: villain folds → `+pot`; calls → `e·(pot+2b) − b`; raises to `R=3b` →
  hero's best of fold (`−b`) and call (`e·(pot+2R) − R`). Which branch each combo
  takes is the *policy*, not a guess.
- 레이즈 to `R` over his `b`: folds → `+pot+b`; calls (or capped re-raise) →
  `e·(pot+2R) − R`.

Per-combo equities: exact on the river (one comparison) and turn (44 rivers);
fixed-seed Monte Carlo (200 samples/combo) on the flop, where exact enumeration
measured too slow for a debug build. All seeded, so the same hand grades identically
every run.

## 4. What the user sees

- **During the hand**: after each decision, the §D pill — 최선/부정확/실수 with the bb
  — plus one sentence. Immediate, because the app's whole pedagogy is decide-then-
  reveal, and it leaks nothing: the grade derives from the bot's *declared* range and
  policy, which the user could reconstruct by hand.
- **Hand end**: the summary — villain's actual hand, the runout, hero's net bb, and
  the decision list with each loss. Net result and decision quality shown side by
  side, because the difference between them is the thing poker teaches slowest.
- **Always printable**: the bot's narrowed combo count is on screen; tapping the
  opponent shows his S3 row.

## 5. Persistence — none yet, on purpose

Table decisions are not written into concept records: they would distort `evLoss`'s
FSRS scheduling and mastery, which belong to the drill. The hand summary is the whole
record in v1. A table-stats store (hands played, mean loss per hand) is a later,
separate decision.

## 6. Scope — out

- Hero's preflop street (needs defending charts — see §1).
- 3-bet pots, multiway pots, hero out of position, stack depths other than 100bb.
- Any bot mixing, and any narrowing of the *hero's* range (the bot does not read).
- Table results feeding 기록.

## 7. Verification

1. **The machine is total** — from deal to outcome every reachable phase has legal
   options; acting on any of them advances or ends the hand; no state repeats.
2. **Determinism** — same seed, same deal, same bot line, same grades.
3. **The bot is S3 verbatim** — his every action equals the policy applied to his
   actual bucket; his dealt combo always survives his own narrowing.
4. **Accounting balances** — pot equals contributions; hero's net over fold/showdown
   equals pot movements; stacks never go negative; bets are §A sizes capped by stack.
5. **Grading agrees with S2 on the river** — a river call/fold node's EVs equal
   `callEV` on the same numbers.
6. **The raise cap holds** — no street ever sees a second raise.
7. **Closed-form EVs are internally consistent** — with a single-combo range the
   option EVs equal hand-computed fixtures.
8. **UI sweep** gains the picker, a mid-hand node, a graded node and the summary.
