# Korean terminology glossary

Canonical spellings for Glass Table. D55 introduces real poker terms alongside
plain meanings for every learner; there is no terminology preference. Task headings
can stay conversational, while their term chip gives the Korean and English names.
The searchable bilingual reference is `GlassTable/Sources/LearningReferenceContent.swift`.
Its stable IDs are independent of the display language and are not persisted.

## Presentation rules

1. Korean actions and streets use 콜 · 레이즈 · 폴드 · 체크 · 벳 · 올인 and
   프리플랍 · **플랍** · 턴 · 리버. Accept 플롭 as a search alias, not display copy.
2. Acronyms and seat identifiers stay Latin: EV · GTO · MDF · VPIP · PFR · RFI ·
   UTG · HJ · CO · BTN · SB · BB. Write **3벳/4벳** in Korean. `bb` is the unit
   equal to one big blind; `BB` is also the seat identifier.
3. Introduce the real name with an accessible meaning; pair Korean and English at
   the first introduction. Glossary chips open that entry, with a route to search
   all terms. Definitions are general and receive no generated question, answer,
   or draft. Looking up terms, formulas and general skill explanations is active
   self-directed learning, including before answering a graded question. Answers
   worked out with these references still count as the learner's own work. Lookup
   does not mark assistance or change scoring; the question, draft and revealed
   answer stay unchanged. Only hints/calculations specific to the current question
   or coaching that advises the current decision use the existing help mark.
4. 무승부 is the Korean outcome label. Suits do not break a showdown tie. Use
   공용 카드 for the shared-card zone and 내 카드 / 상대 카드 for private-card zones.
5. Use 원 페어 / 투 페어 with spaces. TAG/LAG remain Latin; they are not 태그/래그.

## Canonical lookup IDs and names

| ID | Korean | English / useful aliases |
|---|---|---|
| `chip` | 칩 | chip, chips, pot math |
| `pot` | 팟 | pot |
| `blinds` | 블라인드 | blinds, SB, small blind |
| `big-blind` | bb · 빅 블라인드 단위 | bb, BB, big blind |
| `dealer-button` | 딜러 버튼 | dealer button, D, BTN |
| `position` | 포지션 | position, UTG, HJ, CO |
| `hand` | 핸드 · 패 | hand |
| `board` | 보드 · 공용 카드 | board, shared / community cards |
| `suits` | 무늬 · 스페이드 · 하트 · 다이아몬드 · 클럽 | suits, spades, hearts, diamonds, clubs; singular forms too |
| `showdown` | 쇼다운 | showdown |
| `hand-rank` | 족보 | hand ranking, pair, flush, straight, full house, etc. |
| `kicker` | 키커 | kicker |
| `tie` | 무승부 | tie, chop, split pot |
| `stack` | 스택 | stack, effective stack / 유효 스택 |
| `check` | 체크 | check |
| `bet` | 벳 | bet, betting / 베팅 |
| `call` | 콜 | call |
| `raise` | 레이즈 | raise |
| `fold` | 폴드 | fold |
| `all-in` | 올인 | all-in |
| `side-pot` | 사이드 팟 | side pot |
| `three-bet` | 3벳 | 3-bet, 3bet, 다시 올리기 |
| `four-bet` | 4벳 | 4-bet, 4bet |
| `streets` | 스트리트 · 베팅 라운드 | street, betting round, postflop |
| `preflop` | 프리플랍 | preflop |
| `flop` | 플랍 | flop |
| `turn` | 턴 | turn |
| `river` | 리버 | river |
| `range` | 레인지 | range |
| `combo` | 콤보 | combo, combination |
| `range-notation` | 레인지 표기 | range notation, suited / 수티드, offsuit / 오프수트, AKs / AKo |
| `chen-score` | 시작 패 점수 (Chen) | starting-hand score (Chen), 첸 점수 |
| `rfi` | RFI · 먼저 레이즈하기 | raise first in, open raise / 오픈 레이즈 |
| `defend-chart` | 디펜드 차트 | defend chart, starting-hand chart / 시작 패 차트 |
| `equity` | 에퀴티 | equity |
| `pot-odds` | 팟 오즈 | pot odds |
| `required-equity` | 필요 에퀴티 | required equity, break-even equity |
| `ev` | EV · 기댓값 | EV, expected value, 기대값 (search alias) |
| `ev-loss` | EV 손실 | EV loss, 최선 / 거의 최선 / 부정확 / 실수 |
| `checkdown` | 체크다운 가정 | checkdown assumption |
| `outs` | 아웃 | outs, 아웃 카운팅 |
| `draw` | 드로우 | draw, flush draw, straight draw, gutshot / 거샷, OESD |
| `rule-of-2-4` | 룰 오브 2/4 | rule of 2/4 |
| `blocker` | 블로커 | blocker |
| `mdf` | MDF · 최소 방어 빈도 | minimum defense frequency |
| `vpip` | VPIP · 자발적 참여 비율 | voluntarily put money in pot |
| `pfr` | PFR · 프리플랍 레이즈 비율 | preflop raise |
| `archetype` | 상대 스타일 | opponent style; Nit / TAG / LAG / Calling Station / Maniac / Casual |
| `gto` | GTO · 게임 이론 최적 전략 | game theory optimal |
| `hit-frequency` | 레인지 적중 빈도 | range hit frequency |
| `action-read` | 행동으로 레인지 좁히기 | action read |
| `range-advantage` | 레인지 어드밴티지 | range advantage |
| `grade-bands` | 정확 · 근접 · 다시 살펴볼까요? | Spot-on · Close · Review |
| `calibration` | 추정 감각 · 캘리브레이션 | calibration, 90% interval |
| `review` | 복습 · 간격 반복 | review, spaced repetition, FSRS |
| `mastery` | 막 시작 · 익히는 중 · 능숙 · 숙달 | Just started · Getting familiar · Strong in app · Mastered in app |

Search ignores case, spacing and punctuation within names/aliases. Stable IDs win
over aliases when routing a chip. Blank search shows all entries; unknown queries
show an explicit no-results message and can be cleared.

## Meaning and grading boundaries

- **Equity** is average pot share, including a share of ties, rather than outright
  win probability. The best five may use two, one or none of the private cards.
- **Pot odds / required equity** compare the call with the final pot. If the displayed
  pot already includes the opponent's bet, the denominator is that pot + your call;
  do not add the bet twice. At exactly the threshold the no-later-bets, no-rake model
  breaks even. Sharp examples can include earlier callers already in the pot.
- **MDF** uses a different pot moment: pot **before** the opponent's bet divided by
  that pot + their bet. It is an idealized whole-range continuing frequency against
  a zero-equity bluff, not the correct action for one hand or every opponent.
- **Outs** in this app are exact winning river cards on the turn against the shown
  opponent hand. Ties and cards that merely improve but still lose do not count.
  The rule of 2/4 is approximate and must not be called exact equity.
- **Combos** are specific two-card holdings. The 6/4/12 pair/suited/offsuit counts
  apply before removing known cards. Chen scores rank starting hands; they are
  neither equity nor expected profit.
- **1:1 grading** uses the defend chart preflop and a checkdown approximation after
  the current street settles postflop. The free-play table (2–4 players) uses
  factual hand review without EV grades. Neither app model claims a GTO solution.
- **EV loss display:** 0bb = 최선 / Best choice; positive loss ≤0.5bb = 거의 최선 /
  Near best; loss ≤2bb = 부정확 / Could improve; above 2bb = 실수 / Costly choice.
  Only zero loss counts as correct. A near-best result counts as a near miss even
  though the stored grade band shares the engine's `spotOn` tolerance.
- **Grade bands:** exact choices/counts and estimates have different rules. 근접 /
  Close is not an exact correct answer. Do not describe all feedback as estimation.
- **VPIP/PFR** in the app are authored opponent tendencies, not observed statistics.
  Five graded opponents are 신중형 / 선별형 / 공격형 / 콜 위주형 / 매우 공격형
  (Cautious / Selective / Aggressive / Caller / Very aggressive). Free play's
  캐주얼형 / Casual is a separate style. The names do not rank player strength.
- **Skill stages** describe recorded learning inside the app, not certification.
  `Tried` / `Familiar` remain search aliases for older terminology. The Progress UI
  uses 막 시작 / 익히는 중 / 능숙 단계 / 숙달 단계. A stage and a lesson pass are
  separate. See `Mastery.swift` and `LearningGuideContent` for the exact criteria.

## Definition checks

The app's engine/drill contracts are authoritative for what an exercise grades:
`Equity.swift`, `PotOdds.swift`, `Outs.swift`, `BetSpot.swift`, `CallFold.swift`,
`EVLoss.swift`, `Table.swift`, `Archetype.swift`, and `Progression/Mastery.swift`.
General terminology was checked against these primary teaching references:

- [PokerStars: pot odds, equity and rule of 2/4](https://www.pokerstars.com/poker/learn/lesson/pot-odds/)
- [PokerStars: calculating outs](https://www.pokerstars.com/poker/learn/lesson/calculating-outs/)
- [PokerStars: comparing poker hands](https://www.pokerstars.com/poker/games/rules/hand-rankings/comparing-poker-hands/)
- [PokerStars: 3-betting](https://www.pokerstars.com/poker/learn/lesson/3-betting/)
- [GTO Wizard: MDF and alpha](https://blog.gtowizard.com/mdf-alpha/)
- [PokerTracker: basic HUD statistics](https://docs.pokertracker.com/pt4/tutorials/the-hud/basic-hud-guide/)

These references support the words and assumptions; they do not establish that the
app's charts or bot policies are optimal real-game strategies.
