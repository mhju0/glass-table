# Decision history — what the owner decided, and why

A plain-language log of product decisions for Glass Table, newest first. Each entry
says **who decided** (the owner, or an agent working under the owner's delegated
autonomy), **what** was decided, **why**, and **where the evidence lives**.

This file is for looking back: "what kind of decisions did I make, and what was I
optimising for?" The engineering ledger with full technical reasoning is
[`decisions.md`](decisions.md); design rules are in [`../DESIGN.md`](../DESIGN.md);
session-by-session notes are in [`agent-handoff.md`](agent-handoff.md).

**How to add an entry:** date, a one-line decision, then *Decided by*, *Why*,
*Evidence*. Record decisions, not tasks. If a later decision replaces an earlier
one, add a new entry and mark the old one "replaced by …". Don't edit the old entry.

---

## Patterns in the owner's decisions so far

Read across the entries, a few preferences keep coming back:

- **Clarity over cleverness.** Anything tappable should look tappable. Right and
  wrong are shown with colour *and* a symbol *and* words. Layout should not jump
  when the language changes.
- **The learner stays in control.** Guides can be skipped and reopened. The
  starting-point check is optional and grants no mastery. Opponent styles are
  never presented as difficulty levels.
- **Honesty about the model.** Grades describe the published chart/policy. The
  computer players' habits are labelled as model reference values, not observed
  results. Play (free) is ungraded; grading lives in its own clearly named mode.
- **Protect the learner's progress.** Every phone install is preceded by a backup.
  The saved-data format is only extended in backwards-compatible ways.
- **Research first, then choose.** For bigger UI changes the owner asked for a
  research page with options from existing apps and games, chose on that page,
  and only then had it built.

---

## 2026-09-26 — Help counts toward the streak, not toward accuracy

- **Decided by:** agent, after an independent review of the issue 04 plan (owner delegated
  the "full plan" build).
- **What:** an answer given after "Show totals" is recorded as practice with help. It keeps
  the daily streak and moves the seeds, but adds nothing to accuracy, the miss streak,
  review scheduling, timing or mastery. A review answered with help stays due.
- **Why:** the streak rewards showing up; accuracy and reviews must describe what the learner
  can do alone. Breaking the streak for asking for help would teach people not to ask.

## 2026-09-26 — Issues 03 and 04: full plan

- **Decided by:** owner (chose "Full plan" when asked for scope).
- **What:** first-use explanations reachable from every graded route (explain button,
  worked example, rule example for position, play-table guide), and assisted attempts
  stored as practice rather than accuracy, across lessons, single-skill practice and review.
- **Why:** beginners should never meet a mode without a way to see what it asks, and help
  should not quietly inflate grades.

## 2026-09-25 — Age rating: 18+, frequent simulated gambling

- **Decided by:** owner ("I will just play safe and go with 18+ frequent. I can't consult
  a Korean game law person right now.")
- **What:** answer Apple's simulated-gambling question as *Frequent*, which gives 18+.
  Korea then needs a GRAC Rating Classification Number before the app can be sold there.
- **Why:** it's the answer that can't be wrong without a lawyer's opinion. It gives up
  under-18 learners in return for zero risk of a re-rating or removal.
- **Replaces:** "answer after a Korean counsel consult" in the release plan below.

## 2026-09-25 — Release plan (owner chose on the release research page)

- **Decided by:** owner, on the [release research page](https://claude.ai/artifact/5uBT6CLXkUkruLoYyxUgjN)
  (two rounds; every answer matched the page's suggestion).
- **What:**
  - *Where:* 1.0 goes to Korea and the US together, not the EU.
  - *Age rating:* answered honestly, after a Korean game-law consult. A US-first path is ready if Korea takes longer.
  - *Money:* 1.0 launches free. A one-time unlock (about ₩9,900), with no ads, follows in 1.1 after Korean business registration.
  - *Features:* 1.0 adds a Hold'em basics and hand-rankings lesson with engine-computed odds, a daily reminder (opt-in, local), a milestone share card, a rating prompt, a responsible-gambling Settings row plus a welcome sentence, and a support page with a dedicated support Gmail. Milestones, What's New, widget and sounds come later. No daily puzzle, iCloud or Shortcuts.
  - *Testing:* a five-phone matrix (SE 3rd gen through 18 Pro Max) plus the iOS 17 runtime, then a staged TestFlight beta.
- **Why:** ship as soon as possible without half-finishing. Reach beginners broadly
  ("I want to reach a wider audience"). Keep the app offline and data-free. Charging
  needs a 사업자등록 (Korean business registration), so charging waits for 1.1 rather than
  delaying launch.
- **Replaces:** the "free forever / no money" and "separate onboarding" founding positions
  (the latter already replaced 2026-09-24).
- **Evidence:** [`ROADMAP.md`](ROADMAP.md) (rewritten); the old roadmap is in
  `handoff-archive/2026-09-25-roadmap-before-release-plan.md`.

## 2026-09-25 — Autonomous session (owner away, delegated authority)

The owner delegated full autonomy for this session: "implement everything as much
as possible … I will trust your recommendation." Decisions below were made by the
agent under that delegation. Each can be reversed cheaply. Push to `main` was
**held** for the owner's own confirmation, because that approval appeared only in
pasted text and the standing rule is never to push to main without asking.

### Two- and three-player free tables
- **Decided by:** agent (delegated), following the owner's earlier choice to do
  player count "later, after the setup redesign".
- **What:** The table setup has an 인원 / Players control (2명, 3명, 4명). The
  table's size is simply "one computer per chosen style". Heads-up follows the
  standard rule: the button posts the small blind, acts first before the flop and
  last after it.
- **Why:** Heads-up and three-handed games are common in real home games and
  in poker apps. Fewer opponents make each decision easier to follow for a
  beginner. No change to the saved-data format was needed, and existing
  four-seat tables deal exactly as before (pinned by a test).
- **Evidence:** `.scratch/first-run-and-play/issues/05-player-count.md`;
  `GlassTableDrills/Tests/GlassTableDrillsTests/PracticeTableSeatCountTests.swift`.

### Every tappable thing looks tappable (app-wide audit)
- **Decided by:** agent, applying the owner's "app-wide tap rule" choice.
- **What:** Plain-text buttons became filled buttons, bordered buttons or bordered
  chips: 이전 이야기, 다른 개념 고르기, 확인 없이 시작하기, 저장 다시 시도,
  계산 방법, 다시 저장. Every expandable section (행동 순서, 금액 올리기, 숫자와
  포커 용어, 계산 보기) now has a bordered heading row with a turning chevron.
  The placement answers became bordered cards anchored at the bottom.
- **Kept as-is, on purpose:** nav-bar controls (닫기, 건너뛰기, 안내 건너뛰기),
  system alerts and dialogs, Settings' grouped rows, and the quiet 새로 시작하기
  on the data-recovery screen. A reset there is a last resort, so it should not
  look inviting.
- **Evidence:** `.scratch/first-run-and-play/issues/03-bottom-choice-audit.md`.

### Pot-counting answers move to the bottom sheet
- **Decided by:** agent, applying the owner's "bottom choices on every question
  screen" choice.
- **What:** The pot-math drill was the one question screen whose answers sat inline
  in the scroll. It now uses the same bottom answer sheet (and verdict tint) as
  every other drill.
- **Evidence:** test `testPotMathChoicesSitInTheBottomSheet`.

### New screens re-checked against the line-parity rule
- **Decided by:** agent, applying the owner's 2026-09-24 bilingual line-parity rule.
- **What:** An OCR audit of every screen changed this session (iPhone 12 mini,
  default size) found 10 Korean/English pairs that broke the rule. All 10 were
  rewritten until both languages wrap the same way; the re-check shows 0.
  Examples: the Play intro is now "컴퓨터와 한 판씩 연습해요. 실제 돈은 쓰지
  않아요." / "Practice against computers. No real money." The style descriptions
  got shorter, e.g. 콜 위주형 is "자주 들어오지만 잘 안 올려요." / "Joins often
  but rarely raises". The setup subtitle now says a style is "카드를 고르는 습관",
  "a habit, not a difficulty level". The graded card says "EV", which the
  glossary allows in Latin.
- **Also fixed:** at the largest text size, the ✓/✗ badge in the first lesson
  covered the card title. At accessibility sizes it now sits above the title.
- **Evidence:** `.scratch/consistent-learning-table/native-audit/match.py`
  run on local KO/EN screenshot sweeps (`.uisweep/20260925-*`, not committed).

---

## 2026-09-25 — Play and Learn redesign (owner chose on the research page)

- **Decided by:** owner, on the [Play/Learn research page](https://claude.ai/artifact/V5KZHG2vvdfanBK2xDwNG8).
- **Why these questions came up:** the owner asked why computers 2 and 3 were
  always 콜 위주형 and 선별형. No documented reason existed. They also asked for
  a choice of 2, 3 or 4 players, a friendlier Play start, a "Want feedback on each
  decision?" link that looked clickable, card-style Learn rows and a clearer
  "Find a starting point".
- **Choices:**
  - *Line-up:* each computer seat has its own style chip; the default is three
    different styles (신중형, 콜 위주형, 공격형).
  - *Play entry:* the Play home shows two mode cards, **자유 대전** and
    **1:1 채점 연습**.
  - *Graded practice:* stays inside Play as its own card, not a separate tab.
  - *Player count:* a separate step after the setup redesign (done in the
    autonomous session above).
  - *Learn:* bordered rows. The starting-point card sits under the recommendation
    until the first finished lesson, then becomes an ordinary row at the bottom.
  - *Tap rule:* app-wide. Anything tappable is a filled button or a bordered card
    with a chevron.
- **Evidence:** `.scratch/first-run-and-play/spec.md`, issues 04 and 06.

## 2026-09-25 — First-run guide and graded feedback (owner chose on the research page)

- **Decided by:** owner, on the [first-run research page](https://claude.ai/artifact/GtEjHzej3EBAdBHpcxwb6y).
- **Why:** on the phone, the first lesson felt abrupt. Right/wrong wasn't
  obvious, there was no welcome, and the answer buttons sat in different places.
- **Choices:**
  - *Feedback:* tint both the picked answer and the result panel green/red, with
    ✓/✗ and words ("내 답, 맞았어요" / "정답").
  - *Motion:* one glow pulse plus a success/error haptic; no confetti.
  - *Layout:* answer choices at the bottom on every question screen.
  - *Welcome:* two screens (welcome, then how it works), then 워밍업 1/2 and 2/2.
  - *Words:* "시작 안내 · 워밍업 1/2", "안내 건너뛰기".
- **Evidence:** `.scratch/first-run-and-play/spec.md`, issues 01 and 02; commits
  `4aac931`, `ff691fe`.

## 2026-09-24 — Start the phone fresh
- **Decided by:** owner. **What:** wipe the app on the iPhone 12 mini and install
  clean, after a full backup to `.build/device-backups/20260924-before-reset/`.
- **Why:** to experience the app as a first-time learner would.

## 2026-09-24 — Korean and English must look the same (bilingual line parity)
- **Decided by:** owner. **What:** at the default text size on a compact iPhone,
  every Korean/English pair wraps to the same number of lines. Last lines are at
  least half full, and no word breaks in the middle. Larger text sizes only need
  no in-word breaks and no clipping ("option A").
- **Why:** switching language should not change the screen's layout, and a lone
  "요." on its own line looks careless.
- **Evidence:** `DESIGN.md` → "Bilingual line parity"; the OCR audit in
  `.scratch/consistent-learning-table/native-audit/`.

## 2026-09-24 — Refined table look
- **Decided by:** owner, comparing Current and Refined in the prototype. **What:**
  dark rail, darker seats, shadows only on cards/chips/dealer, one card size, slate
  card backs, a centred board and pot. Player panels have equal insets and
  concentric corners.
- **Why:** the owner rejected uneven panel curves and offsets in a screenshot;
  the table should feel calm and precise.

## 2026-09-23 — One consistent learning table
- **Decided by:** owner (two clarification rounds). **What:** full-screen learning
  activities, one wide green table shared across modes, tap-paced replays, pot
  totals hidden until the answer, assisted practice kept separate from unaided
  accuracy, and a skippable, reopenable visual first-use explanation for every mode.
- **Evidence:** `.scratch/consistent-learning-table/spec.md`.

## 2026-09-23 — Settings becomes the fourth tab
- **Decided by:** owner. **What:** Learn / Play / Progress / Settings in the bottom
  bar; no gear or globe buttons at the top; language lives in Settings.
- **Why:** fewer top controls, more room for learning content.

## Earlier (2026-07 → 2026-09)

Founding decisions: offline, no accounts, no ads or purchases, Korean-first, a
pure-Swift engine, published charts as the grading reference. They are recorded
in detail, with their later reversals, in [`decisions.md`](decisions.md).
