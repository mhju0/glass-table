# Glass Table — Product Brief

> An iOS app that teaches serious-minded amateurs to think about No-Limit Texas Hold'em in **ranges and EV**, not in hands and hunches.

## Thesis: transparency

Competing products are either solver-heavy and opaque (GTO Wizard), or they teach against black-box bots whose reads can't be verified (PokerSnowie, Advanced Poker Training). Glass Table inverts this. Its opponents are **rule-based archetypes with declared, inspectable strategies**, so every question the game asks has a *provably correct answer computed from published data* — which means the user's read can be graded numerically instead of hand-waved.

Four commitments express the thesis:

1. **Bots publish their strategy.** Opponents are archetypes (Nit / TAG / LAG / Calling Station / Maniac) with declared opening and continuing ranges. "What does his call mean?" has a correct answer. This is easier to build than a strong bot *and* pedagogically better.
2. **Ranges, not hand ladders.** Never "villain has X or better." A 13×13 combo grid that visibly narrows as the hand progresses.
3. **EV, not equity.** Raw win% teaches people to fold too much. The headline is always equity vs. required equity vs. the consequence of each action.
4. **Decide first, then reveal.** Always-on numbers create dependency. The user commits, *then* sees the math and a grade.

## The core loop and the two-tier grade

Every mode is one loop: **face a spot → commit to a decision → get graded against a benchmark → understand why.** Anything that doesn't fit this loop is a poker client with charts, not a learning product.

Grading comes in two flavors, and **both are provably correct because both are computed from declared data:**

- **Math grade (fundamentals).** Pot odds, equity, outs, MDF. No strategy opinion — objectively right. Powers Math Drills and the "should you call?" half of Table.
- **Exploit grade (advanced).** The max-EV response *versus this archetype's declared strategy*. Always labeled "vs a LAG," never "universally correct." Powers the read-and-punish layer.

This two-tier split is what lets Glass Table serve both a beginner (math grade) and a curious, stronger player (exploit grade) with the same engine — and it's *why* rule-based bots are a feature, not a compromise: the exploit answer is computable and honest only because the villain published its strategy. Glass Table does not compete with GTO Wizard on equilibrium depth. It owns the axis GTO Wizard can't teach: **reading a specific opponent and punishing them.**

## Audience

Primary: **people in their 20s–30s who play poker with friends and want a slightly more serious way to get better.** Home games run 8–9 handed, which is why 8-max is the right table size for this audience (not a compromise). The span runs from motivated beginner to GTO-curious; the app teaches fundamentals first with headroom into exploitation, and never restricts a curious beginner from going deeper.

The app is built partly as a learning tool for its own developer, who is a strong software engineer and an honest poker beginner. This shapes two things: (a) poker correctness comes from **codified public theory and provably-correct math**, not a pro's private taste; (b) the curriculum is written to teach what a strong player actually had to learn, in order.

## Localization

**Korean-first**, and this matches real Korean poker convention (confirmed against pokergosu, CoinPoker KR, namu.wiki):

- **Actions & streets → Hangul transliteration, always** (there are no native-Korean action words in real use): 콜 · 레이즈 · 폴드 · 체크 · 벳 · 올인 · 리레이즈 · 프리플랍 · 플랍 · 턴 · 리버.
- **Acronyms & positions → keep English** (players write the abbreviations, not the spelled-out Korean): GTO, EV, MDF, and SB/BB/UTG/HJ/CO/BTN. **3벳 / 4벳** = digit + Hangul.
- **TAG / LAG stay Latin** — Hangul 태그/래그 collide with everyday "tag"/"lag."
- **A few learning-critical concept terms show bilingually** (Korean primary + small English): 에퀴티 (Equity), 팟 오즈 (Pot odds), 블로커 (Blocker) — beginners meet these in English solver tools anyway, so the English anchor helps.

The full glossary is finalized during UI-copy work (developer-owned as the Korean speaker). Korean-first is also a **compliance lever**: the more the app reads as a *study tool* (calculators, equity/EV, drills), the lower its Korean age rating (see `risks.md`).

## Differentiation, at a glance

| | GTO Wizard | PokerSnowie / APT | **Glass Table** |
|---|---|---|---|
| Opponent | Solver / equilibrium | Black-box neural bot | **Rule-based archetype, strategy published** |
| Can you grade a read? | N/A | No (bot won't tell you) | **Yes — numerically, vs declared range** |
| Villain modeled as | — | A hand | **A range that narrows on screen** |
| Headline metric | GTO frequencies | Win rate | **Equity vs required equity vs action EV** |
| Numbers | Always on | Always on | **Hidden until you commit** |
| Price | $40–130/mo | Paid | **Free, forever** |

## Modes

Each mode is the same loop pointed at a different skill, and each targets a specific place beginners plateau.

| Mode | What it is | Plateau it breaks |
|---|---|---|
| **Math Drills** | Fast, objective drills: outs & rule of 2/4, pot odds, MDF, blocker counting. | Curiosity-calls; folding winners / calling losers on price. |
| **Range Read** | User sees only betting actions, then paints the 13×13 grid with their estimate of villain's range. Scored vs the bot's actual range. | Thinking in single hands instead of ranges. The purest expression of the thesis. |
| **Table** | Play a normal hand with progressive disclosure: numbers hidden → decide → reveal + grade. | Integrating everything under realistic pressure. |
| **Sit In Their Seat** | User sees villain's cards and must play *as* that archetype. Teaches ranges from the inside. | Understanding why a range is constructed the way it is. |
| **Run It 1000 Times** | Resimulate a completed hand's runout many times. | Outcome bias — conflating a bad result with a bad decision. |
| **Lab** | Scenario editor: deal exact cards, set board/stacks, play it out. Doubles as a level editor for shareable puzzles. | (Authoring tool, not a drill.) |

## v1 scope and build order

Build order: **Math Drills → Range Read → Table.** Each is independently shippable, and each de-risks the next.

- **Milestone 1 — Math Drills** (see `milestone-1.md`). Ships as a complete, free study app. Proves the Swift pipeline, the correctness-verified equity core, the decide→grade loop, and the Korean rating path — all at minimum risk, before any betting-table UI exists.
- **Milestone 2 — Range Read.** Adds the archetype range data + the 13×13 grid + betting-action playback. The strongest differentiator; needs no post-flop bot brain.
- **Milestone 3 — Table.** Needs everything above plus the post-flop bot. The long pole; sequenced last on purpose.

Sit In Their Seat, Run It 1000 Times, and Lab are post-v1, built on the same spine.

## Non-goals (explicit)

Glass Table will **not**, at launch or by design:

- Support multiplayer, netcode, real money, or purchasable chips — *ever*. (Also the foundation of the Korean legal position.)
- Ship on iPad, Android, or web. iPhone only, forever.
- Cover tournaments or ICM. Cash game, 100bb effective, only.
- Model rake. Play is rake-free, like every solver.
- Offer continuous bet sizing. A **fixed sizing menu** (e.g. 33 / 50 / 75 / 100 / 150% pot + all-in) keeps the bot's decision tree and the EV math tractable.
- Run a backend. Fully on-device: local progress, no accounts, no sync, no receipt validation.
- Charge money or show ads. Free forever.
- Compete with GTO Wizard on equilibrium/solver depth. Different axis (read-and-exploit, transparency).
- Give the launch bot multi-street planning. Post-flop is single-street-lookahead heuristics; deeper planning is deferred.
