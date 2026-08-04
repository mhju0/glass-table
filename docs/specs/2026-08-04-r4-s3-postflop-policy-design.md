# Revamp R4-S3 — Archetype postflop policy (design)

S3 in the R4 decomposition (`2026-08-04-r4-s1-board-texture-design.md` §0): **an
opponent that acts after the flop.** It ships the policy itself, the range-narrowing
that falls out of it, and one drill — 「액션 리드」 — that teaches what the policy makes
teachable. S4 (Table mode) composes these; it adds no new poker knowledge.

## 1. The policy is a printable table

Each archetype's postflop behaviour is a row per action over the five S1 buckets
(노페어 · 드로우 · 약한 페어 · 탑 페어 · 투페어 이상):

| | 벳 (체크받고) | 콜 (벳 맞고) | 레이즈 (벳 맞고) | 사이즈 |
|---|---|---|---|---|
| **Nit** | 투페어 이상 | 탑 페어 | 투페어 이상 | 50% |
| **TAG** | 드로우 · 탑 페어 · 투페어 이상 | 드로우 · 탑 페어 | 투페어 이상 | 75% |
| **LAG** | 노페어 · 드로우 · 탑 페어 · 투페어 이상 | 드로우 · 약한 페어 · 탑 페어 | 투페어 이상 | 75% |
| **Station** | 투페어 이상 | 드로우 · 약한 페어 · 탑 페어 · 투페어 이상 | — | 33% |
| **Maniac** | 전부 | 노페어 · 약한 페어 | 드로우 · 탑 페어 · 투페어 이상 | 150% |

Bucket not listed → check, or fold facing a bet. Sizes come from the §A menu.

Row rationale, from §C's characters:

- **Nit** (tight-passive): bets and raises only what beats top pair; calls down with
  top pair; folds draws to pressure. His bet *is* his hand — the tell the drill will
  quantify.
- **TAG** (tight-aggressive): value bets and semi-bluffs draws, the textbook c-bet mix;
  disciplined folds with air and weak pairs facing bets.
- **LAG** (loose-aggressive): c-bets air but **checks weak pairs** — hands with no
  showdown value make bluffs, hands with a little are worth a free showdown. This is
  the one deliberately sophisticated row, because it produces the counterintuitive
  tell: LAG의 체크가 오히려 페어예요.
- **Station** (loose-passive): the VPIP–PFR gap, carried postflop. Almost never bets,
  never raises, calls with any piece of the board. Folds only 노페어.
- **Maniac**: bets everything, raises most things, folds nothing. His actions carry
  almost no information — which is itself the read.

**Deterministic, no mixing.** Real players mix frequencies; the table sharpens a
tendency into a rule. That is what an archetype *is* — a caricature — and determinism
is what makes an action invertible into a range the app can print and grade. The
walkthrough says so out loud rather than letting the table pass as a claim about
real humans.

## 2. Narrowing — the primitive S3 exists for

An action inverts the table: 벳 keeps exactly the combos whose bucket the row bets,
체크 keeps the complement. So `narrowed(range, board, after: action)` returns the
surviving combos' distribution (a `RangeOnBoard`), the combo count, and the share of
the range taking that action.

This is the promise S2's spec made twice ("narrowing a preflop range by a postflop
action is S3's job") coming due. It is combo-level, not class-level — A♠K♠ and A♥K♥
land in different buckets on a spade board — which is why the engine gains
`rangeOnBoard(combos:board:)`, a factory over an explicit combo list that the existing
range-based function becomes a caller of. Only way to build a `RangeOnBoard` for a
subset without forking the type; behaviour-preserving for existing callers.

## 3. What S4 inherits

Two total functions on the policy, so the bot's whole postflop turn is table lookup:

- `opens(with bucket:) -> Bool` — checked to: bet or check.
- `response(toBetWith bucket:) -> fold | call | raise`

Total and disjoint by construction (콜 and 레이즈 rows never share a bucket; tests pin
it). The caricature invariants are pinned too: Station never raises, Maniac never
folds, aggressive archetypes' bet rows widen monotonically Nit → TAG → LAG → Maniac.

## 4. The drill — 「액션 리드」

A seat opens preflop, the flop comes, and the archetype **bets or checks**. *Of the
range that took that action, what share has a pair or better?* Estimation — point plus
90% interval, Winkler-scored, feeding the same calibration screen; bands are 히트
프리퀀시's (±5 spot-on, ±12 close), because it is the same kind of distribution read
one step later.

The reveal and walkthrough show the **before and after bars** — the full range's
distribution above the acted range's — because the lesson is not the number but the
*shape change*: a bet slides the mass right, and how far right depends on who bet.

### 4.1 Degenerate spots are rejected

With a deterministic table some (archetype, action) pairs force the answer: Nit-벳 and
Station-벳 are always 100% pair-or-better, LAG-체크 is always 100% (his check range is
exactly 약한 페어). An estimation drill needs something to estimate, so the generator
rejects spots whose answer is ≥ 99.5% or ≤ 0.5%, and impossible ones (매니악-체크 is an
empty set — he has no checking range). The certain tells are not lost: the walkthrough's
rule beat states them, and the reveal names the acted buckets every time.

## 5. Curriculum

Unit **u7 「행동 읽기」**, section **상대** — u4 read *preflop* actions; this unit reads
*postflop* ones.

| node | kind | teaches |
|---|---|---|
| `u7-actionRead` | drill | `actionRead` |
| `u7-boss` 「좁히고 결정」 | boss | `actionRead` mixed with `evLoss`, `rangeAdvantage`, `rangeRead` |

`actionRead` **is** an estimation concept (point + interval), unlike `evLoss`.

## 6. Scope — out

- Turn and river play, and multi-street narrowing. (River `draw` classification is a
  known wrinkle: `madeHand` may call four-to-a-suit a draw with no cards to come. S4
  resolves it where it matters.)
- Reads on raises, and caller-side postflop policies — the drill reads the c-bet spot
  only, the most common and cleanest case.
- Any mixing or randomisation of the table.
- The Table itself (S4).

## 7. Verification

1. **The table is total and disjoint** — every bucket maps to exactly one response
   facing a bet; 콜 ∩ 레이즈 = ∅ for every archetype.
2. **Caricature invariants pinned** — Station never raises; Maniac never folds; Nit's
   raise is 투페어 이상 only; LAG checks 약한 페어 but bets 노페어; bet rows monotone
   Nit ⊆ TAG ⊆ LAG ⊆ Maniac.
3. **Narrowing partitions** — 벳 combos + 체크 combos = live combos, disjoint; the
   narrowed shares sum to 1; shareOfRange(벳) + shareOfRange(체크) = 1.
4. **Known answers** — Nit-벳 is 100% pair-or-better; Maniac-벳 equals the full range's
   distribution; LAG-체크 is 100% 약한 페어.
5. **Subset factory agrees with the range factory** — `rangeOnBoard(combos:)` over all
   live combos equals `rangeOnBoard(range:board:)`.
6. **Generation** — deterministic; never a degenerate or empty action set; board is
   3 cards.
7. **Engine release gate** (`swift test -c release`), since the engine changes.
8. **UI sweep** gains the drill, its reveal, the rule beat and the bars beat.
