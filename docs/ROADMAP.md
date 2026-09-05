# Glass Table — Roadmap

Written 2026-09-04 from the repo, git history, the specs' scope-out sections, and prior
agent-session memory; NOW updated after the 2026-09-05 takeover audit. It separates
verified implementation (including labeled working-tree changes) from discussion.
Old brainstorming has deliberately *not* been promoted into NOW/NEXT.

Sources are tagged: `[V]` verified in repo/git, `[C]` prior Claude conversation context
only. Companion docs: [`PROJECT_HANDOFF.md`](PROJECT_HANDOFF.md),
[`decisions.md`](decisions.md).

---

## NOW

The project remains in the **dogfood phase entered on 2026-07-23** (`7daef48`). After
takeover approval, confirmed correctness defects take priority before the next dogfood
build; new features remain NEXT.

1. **Fix confirmed dogfood defects.** `[V]` 2026-09-05 source audit and reproductions.
   Persistence safety is fixed in the working tree: visible save failures with retry,
   recovery copies before reset/import, memory changes only after replacement saves,
   and future-schema rejection on load. Store and app regression tests pass.
   Remaining, in order: streak eligibility is checked after answers reschedule due
   items; unit 2's six-question boss can promote an unasked concept; table dealing can
   select hero in the small blind while still forcing villain to act first postflop.
2. **Use the app.** Release-config builds on the owner's iPhone via free personal-team
   provisioning; 7-day expiry means a weekly re-deploy. `[C]` Recipe in
   `PROJECT_HANDOFF.md` §9.
3. **Answer the two questions only usage can answer** — (a) is the archetype bot *useful*,
   not just correct? (the top-severity risk in `risks.md`); (b) do the EV-loss bb
   thresholds feel right? `[V]`
4. **Record what breaks.** Issue templates and five triage labels exist; no GitHub issues
   existed at the 2026-09-05 audit. The confirmed defects above are tracked here. `[V]`

---

## NEXT

Committed in principle, buildable today, nothing blocking them.

### 1. Complete MDF as a full Block B slice
`[V]` R1 spec §12.6, `Concept.swift:12-13`, `BetSpot.swift` · `[C]` memory `mdf-parked-deliberately`

The shipped MDF drill is only the **frequency half** (`BetSpot` is `(pot, bet)` — no
cards, no range, grading `pot/(pot+bet)`). The real skill is *selecting which combos make
up the defense*. It was parked because its prerequisites did not exist; **they now do**
(`HandRange`, `RangeOnBoard`, `PostflopPolicy.narrowed`, shipped R2–R4).

- Scope is a **full slice** — new spot type, defense-selection grading, screen, 천천히
  beats, its own spec — on the order of R4-S1. **It is not a node-only change**, and it
  has been misread as one before.
- Still missing: a **fold-equity primitive** in the engine. That is part of the slice.
- The parked state is guarded by tests (`CurriculumTests`, `RangeReadTests`), so it cannot
  drift silently while it waits.

### 2. Re-answer the age-rating questionnaire honestly
`[V]` `docs/submission.md:3-13`, `:124-142`

Not a code change — a decision plus a document edit. It is listed under NEXT rather than
BLOCKED because **the analysis itself is not blocked**; only *acting* on the result is
(see BLOCKED). Producing an honest answer, and updating the review notes that still carry
M1's removed "no simulated betting gameplay" phrasing, can be done now.

### 3. Retune the EV-loss severity bands to be pot-relative
`[V]` R4-S2 §2 and §7

The spec calls the absolute 0.5 / 2.0 bb thresholds "the model's weakest joint" and says
to revisit them against real answers. The *implementation* is small. **It depends on
having real answers**, which depends on NOW — so it is genuinely NEXT-after-dogfood rather
than NEXT-today.

---

## LATER

Real, specified, deferred with reasons. Each is drawn from a spec's own "Scope — out"
section — these are the authoritative deferred-work lists, not wishes.

**테이블 depth** `[V]` R4-S4 §6, R5 §5
- Multiway pots; hero out of position; stack depths other than 100 bb. Hero 3-bets
  already shipped in R5.
- 4-bets, and hero facing a re-raise preflop.
- Blind defense; **hero-seat-sensitive defend-chart band widths** (today the bands ignore
  which seat hero defends from).
- Bot mixing / randomisation of any kind — note this **conflicts with the determinism that
  makes narrowing exact** (`decisions.md` D09); adding it is a thesis-level change.
- **Slowplay rows.** A test currently pins that no archetype's check buckets overlap its
  raise buckets, so a check-raise cannot happen and hero never faces a raise. The machine
  supports the phase; the pin exists so adding a slowplay row forces real coverage first.
- **Table-stats persistence** (hands played, mean loss per hand) and a 기록 card for it —
  deliberately not built so table results cannot distort `evLoss`'s FSRS scheduling.

**Reads and narrowing** `[V]` R4-S3 §6, R3 §5
- Reads on *raises*; caller-side postflop policies (the drill reads the c-bet spot only).
- Multi-street narrowing; turn/river texture *changes* (S1 classifies a board, it does not
  narrate how the turn changed it).
- **정확히 칠하기** — exact cell painting of the 13×13 grid as a Range Read input mode.

**Engine**
- **Perfect-hash evaluator.** Originally specified, never built; the naive evaluator was
  made allocation-free instead (`e0084ac`) which removed most of the pressure. Trigger
  remains "when profiling demands it." `[V]`

**App quality**
- **VoiceOver pass over `TableView` and `NodeSessionView`** — the two screens that never
  got a dedicated one. `[C]`
- **Daily reminder notification** (R1 §6's day-3 prompt). `[C]`
- **Mid-session resume** — skipped as YAGNI during the 2026-08-06 wiring pass. `[C]`
- **Motion pass.** `[C]`
- Break up `ConceptDrillView.swift` (1,607 LOC, all 18 drill screens). `[V]`
- Broader app/session coverage beyond the persistence regression tests. `[V]`

**Deferred beyond M1 and never revisited** `[V]` `docs/specs/2026-07-22-m1-four-drills-design.md:101`
- Difficulty tiers; richer "why" copy; SwiftData as a storage backend.

---

## BLOCKED

**App Store / TestFlight submission** — blocked on two things, in order:

1. **The age rating.** `[V]` `docs/submission.md`, `open-questions.md` #11.
   M1 answered Apple's Simulated Gambling question "Infrequent/Mild" because there was no
   betting gameplay. The 테이블 has betting gameplay with bb stakes. An honest re-answer
   is plausibly Frequent/Intense → 17+/KR-19, which is **barred from Apple's self-rating
   track in Korea** and forces a direct GRAC review + Rating Classification Number
   (~10–15 business days, a fee, a gameplay video). Standing instruction: if the computed
   rating is 17+/KR-19, **stop before submitting**.
2. **Korean game-law counsel.** `[V]` `open-questions.md` #11. Skipping counsel was agreed
   for M1 *explicitly on the condition* "revisit before the betting-table milestone."
   That milestone shipped 2026-08-04. The condition has fired and is unmet.

Also gated behind the same decision: Apple Developer Program enrollment (deliberately
deferred), and the standing rule that resumption goes **enroll → TestFlight upload only**,
never submit for review without an explicit go. `[V]`
`docs/plans/2026-07-23-m1-submission.md:6-9`

**Anything needing real usage data** — the EV-loss retune, the "is the bot useful?"
question, and whether a table-stats card is wanted. All blocked on NOW.

---

## CONSIDERED BUT NOT COMMITTED

Discussed, sometimes at length, but never promoted to a commitment. **Do not treat these
as planned work.**

| Item | Where it came from | Why it is not committed |
|---|---|---|
| **Sit In Their Seat** — play *as* the archetype, seeing villain's cards | `product-brief.md` modes table | Named post-v1 from the start; no spec, no engine work, never scheduled `[V]` |
| **Run It 1000 Times** — resimulate a finished hand's runout | same | Same; targets outcome bias, which nothing currently addresses `[V]` |
| **Lab** — scenario editor / puzzle level editor | same | Same, plus it depends on the unspecified `.glasstable` share format `[V]` |
| **6-max table-size option** | `open-questions.md` #14 | "Cheap, but confirm demand." Demand unconfirmed `[V]` |
| **Korean app name / bilingual lockup** (유리 테이블?) | `open-questions.md` #12 | Never decided; store listing currently uses "Glass Table" in both locales `[V]` |
| **`.glasstable` puzzle sharing** (file or URL-encoded string) | `open-questions.md` #16, `decisions.md` D02 | Schema never designed; only matters once Lab exists `[V]` |
| **Remote puzzle content as static JSON on a CDN** | old §5 | Explicitly "defer"; would be the first crack in zero-networking `[V]` |
| **Optional tip jar** | old §6 | Called YAGNI at the time and never revisited `[V]` |
| **Captioned App Store marketing screenshots** | `docs/submission.md:179-180` | Current set is raw frames; captions are "a separate pass" if ASC wants them `[V]` |
| **The 8-seat animated table** with phase-multiplexed grid/EV | old §3 | Designed in detail, then the shipped table went heads-up for grading tractability. Reviving it is a large slice, not a setting `[V]` `decisions.md` D08 |

---

## EXPLICITLY REJECTED

These are **decisions, not gaps.** Re-proposing one without new evidence is a regression.

**Product non-goals** `[V]` `product-brief.md:88-101`
- Multiplayer, netcode, real money, or purchasable chips — **ever**. (Also the foundation
  of the Korean legal position: adding purchasable currency or cashout would forfeit the
  structural escape from 사행성/웹보드 regimes.)
- iPad, Android, web. iPhone only, forever.
- Tournaments and ICM. Cash game, 100 bb effective, only.
- Rake modelling.
- Continuous bet sizing / a size slider. A fixed menu keeps the bot's tree and the EV math
  tractable — and the bots literally cannot reason about sizes outside the menu.
- A backend, accounts, sync, receipt validation.
- Money or ads of any kind.
- Competing with GTO Wizard on equilibrium/solver depth. Different axis on purpose.
- Multi-street planning for the bot.

**Engagement theater** `[V]` R1 §7.2
- Leagues, XP, hearts/lives. 기록 leads with mastered-concept count — never XP, never
  streak.

**UI rules that pre-emptively reject "improvements"** `[V]` `decisions.md` D35, D37
- **"Make the recommended action stand out" is a bug, not a polish.** Choice buttons are
  visually identical until *selected*; accent colour marks what kind of money a button
  commits, never which one is correct.
- **Do not make card faces scale with Dynamic Type.** There is no size rung that fits —
  five cards at 3× need ~715 pt of a 393 pt screen. Cards are pictograms and opt out;
  VoiceOver carries the content.

**Reversed and not to be re-litigated** `[V]` `decisions.md` D20, D24, D34
- **A separate onboarding flow.** Built twice (a prose guide, then an authored hand),
  deleted both times. Per-node 보여주기 already teaches on first exposure; a separate
  onboarding is a second system doing the same job. The durable finding: *explanation
  belongs where the confusion is, after a committed answer.*
- **A light/dark twin.** The two appearances measured 1.04:1 apart on every glass surface —
  the same pixel. The app pins `UIUserInterfaceStyle: Dark`.
- **Translucent material surfaces.** Measured 1.17–1.71:1 against the felt where WCAG
  1.4.11 wants 3:1, while paying an offscreen blur pass over a flat fill. Glass is a colour.
- **GTO Wizard as the range baseline.** It is the named direct competitor, and no public
  chart is redistributable anyway. Benchmarks are Upswing + PokerCoaching, *named and
  never reproduced*; all values are derived from Chen's formula.
- **"Top N% by all-in equity vs a random hand"** as the chart derivation rule. Measured: it
  puts A9o above AJs and 76s in the bottom quartile.

---

## COMPLETED RECENTLY

Newest first. `[V]` from git.

| Date | Work |
|---|---|
| **2026-08-27** | Docs: Xcode 26 requirement + XcodeGen install step in the README; ignore `build-device-release/`. *(Most recent commits.)* |
| **2026-08-08 → 08-09** | **Performance campaign, three commits, all proven behaviour-preserving.** Engine hot paths allocation-free (`madeHand` 47×, `boardTexture` 67×, `evaluate7` 2.9×; engine gate 284 s → 128 s, drills 4.8 s → 0.7 s). Drill screens stopped regenerating their spot on every render (up to 9× per body pass). Grading stopped computing the same answer twice. Verified by byte-diffing tens of thousands of outputs against the previous package plus a 58-screen pixel sweep. |
| **2026-08-07** | **UI review pass** — table gained three fixed zones and a 팟/콜 strip at the board; the reveal leads with the lesson rather than the score; 길 inverted its weight onto a continuous rail; the last two emoji icons became SF Symbols; tab-bar clearance unified into one scaled inset. **Plus a critical accessibility fix**: card ranks truncated to "…" at accessibility text sizes, which made the app unplayable at exactly those settings. Screenshots re-captured; `decisions.md` §H written. |
| **2026-08-06** | **Completeness / wiring pass** (`5e8b73e`) — connected shipped machinery that had no UI: walkthrough replay, backup export/import, progress reset, honest 오늘 header, due-filtered 복습 sheet, glossary chips in reveals, streak-freeze display, grade haptics. Plus `Card: Sendable` (140 Swift-6-mode errors) and `actions/checkout@v5`. |
| **2026-08-03 → 08-04** | **The revamp, R1–R5b** (PRs #1, #2). The app stopped being five drills behind a home screen and became a course plus a table: progression shell (3 tabs → 4), 8 units / 18 concepts, FSRS review, Winkler calibration; RFI charts and range notation; range read; board texture; EV-loss grading; archetype postflop policy; the 테이블; hero preflop against a derived defend chart; the 디펜드 차트 drill. Visual system rebuilt around opaque surfaces and one pinned appearance. All docs refreshed to the shipped state. |
| **2026-07-31 → 08-02** | Licensing corrected to all-rights-reserved across the repo; global agent baseline removed from `CLAUDE.md`. |
| **2026-07-24 → 07-25** | Outs-reveal legibility + tap-to-explain; new range-grid app icon; 첫 핸드 onboarding *(since deleted)*; in-drill teaching, 용어 chips, verdict banners. |
| **2026-07-23** | **M1 shipped and tagged `v1.0.0-beta.1`.** Five drills, glossary screen, stats screen, app icon, README, CI (app build + drills tests; engine release gate), issue templates, CHANGELOG, privacy policy on GitHub Pages, full App Store metadata. Then **paused for dogfood.** |
| **2026-07-22** | Repo created. Engine core (evaluator, equity, oracle fixtures), app spine, all five M1 drills. |
