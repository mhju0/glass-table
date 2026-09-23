# Beginner experience audit

Baseline: `dd2f7e3e5a57ffb1139398f39fdd21207a6f8603`, 2026-09-23.
Scope: current source for all 18 concepts and shared modes; the two owner-supplied
iPhone screenshots are visual evidence for the opponent picker and defend chart.
This is not an all-concept native runtime or spoken VoiceOver audit. Proposed
copy below is for review, not a claim of completed localization.

## Findings that change this release

| Finding | Evidence | Action |
|---|---|---|
| Opponent names and stats assume prior poker knowledge | Owner's picker screenshot; `Archetype.swift:20–60`; `TableView.swift` picker | Everyday behaviour first, technical name and configured parameters in details. These are authored bots, not measured human tendencies. |
| Hand summary consumes disproportionate height | Owner's chart screenshot; `DesignSystem/DefendGridView.swift:69–91` uses a flexible shape with a minimum, not intrinsic, height | Replace with compact cards/action/reason; chart dominates; enlarged cell explorer and readable row alternative. The source is consistent with the screenshot; native fix still needs geometry verification. |
| Full English requires more than a Settings switch | `FirstLessonCopy.swift:4–64` is the only localized-copy helper; no catalog; `Progression/Beats.swift` and drill reveal strings are Korean | Separate semantic facts from generated text, stable term IDs and full coverage before advertising English. |
| Most free-practice concepts have no why/how entry | `Screens/NodeSessionView.swift:284–363`; pot exception `ConceptDrillView.swift:343–468` | Brief skippable/replayable introductions; preserve existing worked/coached course teaching rather than duplicating it. |
| Free practice has no round-level finish | `NodeSessionView.swift:284–363`; review already snapshots up to five due concepts | Five-question single-skill rounds with per-answer saves and a useful completion summary. |
| Historic totals cannot be called strict accuracy | `ProgressionModel.swift:146` and grade-to-review mapping count near answers as accepted; `ProgressState.swift:101` stores one correctness boolean | Keep old totals, begin clearly defined new outcome fields, label different scoring families honestly. |
| Detailed daily history cannot be reconstructed indefinitely | `ProgressState.answers` retains only 500 rows; rows lack mode/timing/session IDs | Sparse durable daily aggregates with a tracking-start date; no invented old detail. |
| Four-seat play is not the existing table model | `Table.swift:16,515` models one hero and one villain; `docs/decisions.md` D08 excludes multiway | Separate integer-chip engine and ungraded factual review; preserve the current heads-up exercise. |
| A documented stop-drilling helper is not a current UI stop | `Mastery.swift:16–18,43–75`; no `shouldStopDrilling` UI caller found; `RecordsView.swift:179–216` offers guidance after three misses | Do not describe eight-miss automatic stopping as shipped. Offer guidance explicitly in the new practice flow. |

App paths above are under `GlassTable/Sources/`; pure Swift paths are under
`GlassTableDrills/Sources/GlassTableDrills/` unless stated otherwise.

## All-concept copy and teaching inventory

`C` below means [ConceptDrillView.swift](../../GlassTable/Sources/Screens/ConceptDrillView.swift).
All 18 have coached hints in
[NodeSessionView.swift](../../GlassTable/Sources/Screens/NodeSessionView.swift):254–274.
Course first-entry teaching uses `Walkthrough.make`/`BeatScript`, followed by a
different coached question and then solo retrieval (`NodeSessionView:83–139`).
Mixed checkpoints can enter solo directly. Shared reveal/commit is `C:204–233`.
The proposals preserve that progression, add accessible entry to free practice and
translate generated feedback as well as titles. They do not replace advanced tasks
with easier but different tasks.

| Concept and question/reveal source | Beginner obstacle | Proposed Korean title and task | Proposed English title and task |
|---|---|---|---|
| Showdown, C:307–329; `Showdown.swift:61–120` | 족보/키커 in feedback | 누가 이길까요? 내 카드와 공용 카드로 가장 좋은 다섯 장을 찾아요. | Who wins? Find each player's best five cards using their two cards and the shared cards. |
| Pot math, C:343–468 | 팟/SB/BB; amount added vs total raised to | 팟에 든 칩 세기. 각 행동에서 새로 들어온 칩을 차례로 더해요. | Count the pot. Add the chips each action puts in. |
| Position, C:573–659 | Eight-seat abbreviations, changing street order | 누가 먼저 행동할까요? 버튼 위치를 보고 행동 순서를 따라가요. | Who acts first? Find the dealer button, then follow the action order. |
| Combos, C:761–884; `Blocker.swift:73–92` | 레인지/콤보/suited/offsuit | 가능한 두 장 조합. 이미 보이는 카드를 쓰는 조합은 빼요. | Possible two-card hands. Remove combinations that use visible cards. |
| Pot odds, C:887–943; `BetSpot.swift:45–60` | 팟 오즈/에퀴티 in the question | 콜 가격 따져 보기. 지금 낼 칩을 콜 뒤의 전체 팟과 비교해요. | Is the call worth its price? Compare what you must add with the pot after calling. |
| Outs, C:799–807; `Reveal.swift:14–60` | 아웃/리버/Rule of 2; improving is not always winning | 역전할 카드는 몇 장일까요? 마지막에 나와서 상대를 이기게 하는 카드만 세요. | How many cards can turn it around? Count the unseen final cards that would make you beat the opponent. |
| Equity sense, C:663–700, input C:236–285 | Point estimate plus a 90% interval before explaining uncertainty | 내 몫은 얼마나 될까요? 끝까지 카드를 펼칠 때 팟에서 얻을 평균 몫과 예상 범위를 골라요. | What share of the pot can I expect? Estimate your share at showdown, including split pots, and give a plausible range. |
| EV call, C:705–755; `Estimation.swift:122–145` | EV/bb and interval entry | 이 콜의 평균 손익은? 이길 때와 질 때의 금액을 각각의 가능성과 함께 따져요. | What is this call worth on average? Weigh the possible gains and losses by how likely they are. |
| Call/fold, C:947–993; `CallFold.swift:59–100` | Chance, price and action terms in one step | 콜할까요, 폴드할까요? 팟에서 얻을 몫과 지금 내야 할 가격을 비교해요. | Call or fold? Compare your expected share with the price of staying in. |
| Range notation, C:998–1068 | Pairs/suited/offsuit/+ notation | 핸드 표기 읽기. 같은 숫자, 같은 무늬, 다른 무늬와 + 표시를 나눠 봐요. | Read hand notation. Identify pairs, same-suit hands, different-suit hands and the + sign. |
| RFI, C:1072–1145 | RFI/open; eight-seat interpolated practice chart | 내가 먼저 올릴까요? 앞사람들이 모두 접었을 때, 자리와 카드에 맞는 선택을 해요. | Should I raise first? Everyone before you folded. Decide using your seat and cards. |
| Range read, C:1149–1362 | Many range terms and dense controls | 가능한 핸드 읽기. 보이는 카드와 상대의 행동을 반영해 가능한 조합을 살펴봐요. | Read the possible hands. Account for visible cards and the opponent's action. |
| Hit frequency, C:1363–1440; `BoardDrills.swift:39–54` | Hit frequency/range/pair | 페어 이상은 얼마나 될까요? 가능한 시작 핸드 중 이 보드에서 페어 이상이 된 비율을 골라요. | How many hands made a pair or better? Estimate that share of the possible starting hands on this board. |
| Range advantage, C:1441–1554 | Two ranges, opener/caller, equity and asynchronous calculation | 어느 쪽 핸드들이 유리할까요? 같은 보드에서 양쪽의 가능한 핸드를 비교해요. | Which set of hands is favored? Compare both players' possible hands on the same board. |
| EV loss, C:1556–1751 | EV loss/bb/range/checkdown assumptions | 선택에 따라 평균 손익이 얼마나 달라질까요? 같은 조건에서 콜과 폴드를 비교해요. | How much does the choice change the average result? Compare calling and folding under the same assumptions. |
| Action read, C:1753–1841 | Range, made-hand buckets and bot blurb together | 이 행동 뒤에 페어 이상은 얼마나 남았을까요? 상대가 선택한 행동에 맞는 핸드만 살펴봐요. | After that action, how many hands have a pair or better? Consider the hands that follow the opponent's published rule. |
| Defend, C:1843–1957 | Defend/3bb/open/3-bet | 상대가 먼저 올렸어요. 어떻게 할까요? 접기, 같은 금액 맞추기, 더 올리기 중 골라요. | An opponent raised. What should I do? Fold, match the amount, or raise again. |
| MDF, C:887–943; `Beats.swift:308–320` | MDF and ambiguous 지키다 | 얼마나 자주 계속해야 할까요? 상대가 모두의 폴드만으로 이익을 얻지 못하는 기준 비율을 구해요. | How often should I continue? Find the baseline that stops a bet from profiting just from everyone folding. |

### Why each lesson matters, without overstating it

| Concept | Korean / English reason to introduce with the lesson |
|---|---|
| Showdown | 가장 좋은 다섯 장이 승자를 정해요. / The best five cards decide who wins. |
| Pot math | 현재 팟을 알아야 다음 베팅의 크기도 알 수 있어요. / Knowing the pot helps you understand the next bet's size. |
| Position | 나중에 행동하면 앞선 선택을 더 볼 수 있어요. / Acting later lets you see more decisions first. |
| Combos | 가능한 조합을 세면 상대가 가질 법한 핸드를 비교할 수 있어요. / Counting combinations helps you compare possible opponent hands. |
| Pot odds | 콜할 가격과 얻을 수 있는 몫을 같은 기준으로 비교해요. / Put the call's price and your possible share on the same scale. |
| Outs | 좋아 보이는 카드가 실제로 이기는 카드인지 구분해요. / Separate a card that merely improves your hand from one that wins. |
| Equity sense | 한 번의 결과와 반복했을 때의 평균 몫은 달라요. / One outcome differs from your average share over many outcomes. |
| EV call | 이번 결과보다 같은 선택을 반복했을 때의 평균을 살펴봐요. / Consider the average result of repeating the decision, not just this outcome. |
| Call/fold | 강한 패인지뿐 아니라 가격이 맞는지도 중요해요. / The price matters as well as the strength of your hand. |
| Range notation | 짧은 표기 하나가 여러 시작 핸드를 뜻해요. / A short label can represent many starting hands. |
| RFI | 자리에 따라 공개된 연습 기준이 어떻게 달라지는지 배워요. / Learn how the published practice baseline changes by seat. |
| Range read | 특정 두 장을 맞히기보다 가능한 여러 핸드를 살펴봐요. / Consider several possible hands instead of guessing one exact pair of cards. |
| Hit frequency | 보드와 연결된 비율을 보는 연습이며, 승자를 정하는 수치는 아니에요. / This measures board connection, not who wins. |
| Range advantage | 내 카드 두 장뿐 아니라 양쪽의 가능한 핸드들을 비교해요. / Compare sets of possible hands, not only your own two cards. |
| EV loss | 모델 안에서 더 나은 선택과의 금액 차이를 확인해요. / See the value gap from the better choice within the stated model. |
| Action read | 공개된 상대 규칙을 알면 행동 뒤에 남는 핸드를 따져 볼 수 있어요. / A published opponent rule lets you work out which hands remain after an action. |
| Defend | 모든 게임의 정답이 아니라 공개된 연습 차트와 비교해요. / Compare with a published practice chart, not a universal answer for every game. |
| MDF | 전체 빈도를 보는 기준이며 특정 핸드의 콜 여부를 정하지 않아요. / This is an overall frequency baseline; it does not choose which individual hand should call. |

Feedback must keep the displayed model limitations and arithmetic. Simplifying
language never permits changing an expected pot share into a strict win probability,
equating a pair with a strong hand, or calling chart disagreement an EV mistake.

## Shared modes and completion coverage

| Surface | Current source and treatment |
|---|---|
| Path / course | Preserve worked/coached/solo stages and existing lesson completion. Add plain-language titles and replayable entry; do not force introductions again for attempted concepts. |
| Today / review | Preserve the bounded due queue; explain why a concept returned. Localize empty states and learning-guide entry. New free-practice entry must be distinct from scheduled review. |
| Free practice | Replace endless single-concept progression with a five-question round, individual commits, leave/resume and next-step summary. New help must mark an attempt as assisted rather than improving independent statistics. |
| Graded heads-up table | Keep chart-based preflop and disclosed postflop model separate. Explain opponent behaviour and reference tools in everyday words. |
| Four-player table | New mode, not currently implemented. Factual hand review and optional hindsight cards; no guessed EV grades. |
| Records | Preserve totals and three-miss guide offer. Add explicit tracking-start/insufficient-data states and per-concept metric labels. Calibration remains only for interval-producing concepts. |
| Settings | `SettingsView.swift:34–90` has appearance, glossary, guide and first-lesson replay, no language. Make it reachable inside activities and preserve activity state on switch. |
| Recovery/import/export | Preserve current visible errors, retry and recovery bytes; localize explanations and outcomes. New migration is a separate Class-3 task, not an incidental copy edit. |
| Glossary / accessibility | `docs/glossary.md:7–18` currently specifies Korean-first actions/streets and Latin abbreviations. Update as part of approved full-language implementation; use stable term IDs. Localize card/action spoken labels, not just visible prose. |

## Previously resolved reports stay resolved

The [September 20 audit](../../docs/specs/2026-09-20-learner-trust-audit.md)
already distinguishes obsolete old-main reports from revamp fixes. Do not reopen
silent-save-failure, missing MDF curriculum or absent AX sweep claims from those
old line numbers. The chart proportion is a new visual finding despite the earlier
selected-hand accessibility improvement. Existing sweep results do not prove that
all 18 concepts now work in English or that a new learner understands them.

## Review questions and evidence still needed

The owner reviews the six mock flows, Korean/English tone and proposed style names.
An adult beginner should then be able to explain the task, the next action and the
feedback without the designer supplying missing definitions. That comprehension
check remains outstanding; screenshots and code tests cannot substitute for it.
After approval, native UI tests and a complete two-language/appearance/text-size
sweep must cover the actual implementations and generated examples.
