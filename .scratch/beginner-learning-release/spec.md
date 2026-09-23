# Beginner learning release

Status: approved for combined native implementation; verification pending
Baseline: `dd2f7e3e5a57ffb1139398f39fdd21207a6f8603`
Date: 2026-09-23

## Outcome and delivery boundary

Glass Table remains an offline learning app for adults, with a place to practise
hands against computers. Everyday reading simplicity is the goal, not a child
audience. Preserve serious poker concepts and the current visual identity.

The owner approved one complete release with full Korean and English, approved
the revised mocks and authorized native implementation including the optional
offline starting-point check. Browser fixtures are neither a native build
nor evidence that the future four-player engine, migration or statistics work.

This file records the approved scope. [audit.md](audit.md) covers current-source
findings. [prototype/README.md](prototype/README.md) describes the review build.
Individual implementation tickets live in [issues/](issues/).

## Combined release: starting point and open access

The September 23 approval combines the previously discussed first and second
versions into one native delivery. Every lesson and advanced practice stays open.
The recommended sequence remains available, but it is guidance rather than a lock.
Opening an advanced lesson never marks earlier lessons complete.

Offer an optional, untimed starting-point check with a plain self-report, three
bundled questions, an unsure answer and a skip action. Store its topic suggestion
locally, separately from mastery and review scheduling. It is not a proficiency
certificate. Existing learners are not forced through it; it can be replayed from
Learn and Settings. No email, password, account or online profile is introduced.
Progress export/restore remains the explicit recovery mechanism.

## Beginner language and entry

- Lead with the situation and the action. Introduce the poker term beside its
  meaning; disclose abbreviations and deeper policy details on demand.
- Cover all 18 concepts, path, review, practice, table, settings, recovery, errors
  and accessibility labels. A glossary supplements understandable screens.
- Opponent descriptions must match the actual authored policy. Present configured
  VPIP/PFR as policy parameters, not observed statistics or difficulty scores.
- Lead the opponent picker with short titles: Cautious/신중형,
  Selective/선별형, Aggressive/공격형, Caller/콜 위주형 and Very aggressive/매우 공격형.
  Give each one brief everyday wording. Keep exactly five stationary vertical rows
  at phone and wide widths. Tapping a row opens a bottom sheet with a stable frame,
  the selected title and two distinct scales: how often it enters and how often it
  raises before shared cards. Back, Escape and backdrop dismissal restore focus
  and scroll position; the background is inert while the sheet is open.
  These are separate per-hand settings, not one aggression or skill rank. Put the
  numerical VPIP/PFR values and original poker names in optional details. Use
  Computer 1/2/3 as seat identities, with the selected style on Computer 1.
- Give each concept a short why/how/example introduction, with skip and replay.
  Use a different worked example from the assessed question. Previously attempted
  concepts do not force the introduction on existing users.
- Keep existing repeated-miss guidance. Offer guided practice before inventing
  easier generators for every concept. Separate assisted and independent results.
- Encourage with specific observations. A short round does not establish mastery.
  Incorrect-answer feedback explains the answer without guessing the user's error.

## Chart composition

Use a compact, intrinsic-height selected-hand summary with actual cards, action
and brief reason. The chart is the main content, not a footer under an empty panel.
Teach paired/same-suit/different-suit notation using card examples.

The whole-grid overview is not 169 undersized touch targets. An enlarged explorer
has at least 44pt cells, contained scrolling, selected-hand detail and a way to
return to the current hand. At accessibility sizes, provide structured rows and
readable controls. Include labels or patterns as well as colour. Show graded
recommendations only after commitment; a separate study chart may show answers.

## Complete language support

Settings offers System, 한국어 and English, reachable without ending any activity.
System chooses Korean when the preferred supported language is Korean, otherwise
English. Appearance remains System, Light or Dark.

Changing language preserves the seed, index, input, replay position, answer/reveal
state and current table. Never key the activity identity to its language. UI uses
localized resources; pure Swift drills format semantic facts with language-aware
formatters rather than translating assembled Korean strings. Stable term IDs
replace Korean-string glossary routing. Persistent concept IDs do not change.

Coverage includes generated feedback, numbers, plurals, help, recovery and spoken
labels. English metadata may describe English lessons only after complete support
is implemented and reviewed. The current Korean-only metadata claim stays until then.

## Practice and honest progress

Single-skill free practice becomes five-question rounds. Record each answer at
commit, not only on completion. Leaving after three retains those three answers.
Completion offers another round, guidance or another concept. Use three main tabs:
Learn/배우기, Play/플레이 and Progress/기록. Fold Today's recommended action into
Learn rather than opening a daily popup. Show one suggestion: resume an unfinished
introduction or round first, then a useful due review, then the next lesson. When
the curriculum is complete, show an honest completed state. Keep the full path,
review scheduling, calibration and single-skill practice reachable from Learn;
four-player table practice starts in Play, and history/style reports live in
Progress. No existing information is dropped just because its tab disappears.
The browser mock may use labelled next/review fixtures, but must not claim a real
due schedule or a full path before those are connected.

Daily and weekly per-concept summaries show counts and meaningful outcomes:
exact/near/miss for estimates, chart match for chart tasks, decision loss for EV.
Do not relabel the existing accepted-near `correct` count as strict accuracy.
Keep old totals and mark when new detailed tracking began; do not reconstruct
history from the incomplete 500-answer ring. Combine counts, not mean percentages.
Comparison requires matching concept, mode, grading/format version and assistance.

Timing is optional and never a countdown, score or FSRS input. Measure foreground
question-ready to commit. Exclude assisted, interrupted, restored or language-
switched questions. Store sum/count for eligible correct answers. Compare matching
concept, format and language in non-overlapping windows, each with at least ten
eligible correct answers across three days. These thresholds are product choices,
not validated poker standards. Accuracy leads; timing is secondary context.

## Durable progress and resume (Class 3)

Schema 2 adds sparse daily concept/mode aggregates, language/format timing,
bounded recent evidence, intro-seen flags and resumable rounds/table to a single
atomic ProgressState. Preserve original schema-1 bytes before migration. Any
migration failure leaves them intact. Retain all existing progress/recovery flows.

One serialized persistence owner handles revisions and stable attempt/hand IDs.
Answer and settlement commands are idempotent. Persist the answer and aggregate,
or settlement and table state, together. Save failure pauses transitions and offers
retry/export; reset/import invalidate stale callbacks. Imports validate and replace
a snapshot, never merge overlapping counts. Unknown newer schemas fail safely.

The proposed schema-2 import limit is 64 MiB. Benchmark real Codable and device
memory/latency with representative 8 and 48 MiB fixtures before acceptance. Keep
long-term daily history beyond the recent-evidence cap. Never silently trim history
to fit a cap; explain a capacity failure and preserve recoverable bytes.

## Four-player practice (Class 3)

Keep the existing graded heads-up exercise separate. Build a pure Swift integer-
chip rules model for one learner and three bots. Each starts with 100 chips;
blinds stay 1/2, without ante, rake or escalation. Rotate the dealer, carry nonzero
stacks and explicitly refill a busted seat to 100 between hands. Record refills
separately from winnings. Continue only on Next hand. Save/resume without rerolling.

Implement legal betting, minimum raises, player-specific short-all-in reopening,
side pots, unmatched returns, ties and odd-chip allocation. Continue bot-only play
after the learner folds. Bots receive only their cards and public information;
publish versioned authored policies without claiming optimal play.

Review completed hands factually: action order, contributions, best hands and
payouts. Optional full opponent-card reveal is clearly hindsight. No per-action EV
grades or FSRS updates for this mode until a defensible grading model exists.
Offer relevant lessons without claiming that an unpriced action was best.

## Recent play styles

Five proposed labels describe observed behaviour: selective-entry/raising,
selective-entry/calling, wide-entry/raising, wide-entry/calling, and sufficiently
observed mixed. Insufficient or ambiguous data gets no assigned style. Friendly
Korean/English nicknames require approval in the mock; they are not diagnoses.

Versioned assignment heuristic for this release:

- Use the latest 200 eligible completed hands within 30 days, same rules/bot policy.
- Require at least 100 hands across five days and 40 voluntary entries.
- Measure voluntary participation and the fraction of entered hands containing a
  preflop raise. Forced blind payments alone are not voluntary entries.
- Participation bands: below 30%, 30–50%, above 50%. Raise-share bands: below 40%,
  40–70%, above 70%. A 95% Wilson interval must fit wholly within each assigned band.
- Four supported outer corners produce four labels. Supported combinations involving
  a middle band produce Mixed. An interval straddling a boundary stays unassigned.
- Recompute after 20 new hands and when evidence expires. Show denominators and dates
  immediately even before assignment; old-policy data is not pooled silently.

These cutoffs and nicknames are authored product heuristics, not research-validated
four-handed poker classifications. Repeated play against fixed bots does not prove
independent samples or real-world predictive certainty. Say what was observed,
show examples and offer one practice suggestion. Never infer fear, bluff intent,
intelligence, personality, profitability or overall skill from these statistics.

## Delivery sequence and acceptance gates

1. Audit and bilingual interactive mocks. Review opponent language, chart hierarchy,
   intro, practice summary, table review and style report on compact light/dark
   screens. Approval gates production implementation.
2. Localized semantic copy and beginner entry/chart changes. Preserve existing IDs,
   grading and session state. Check every concept and generated reveal in both languages.
3. Persistence, round resume and progress summaries with independent Class-3 planning
   and review. Test migration failures, duplicate commands, reset/import races,
   force-quit/restart and continued writes from old fixtures.
4. Four-player rules, bot policy, resume and factual review. Test authoritative rule
   fixtures, seeded replay, legal-action generation, chip conservation, hidden-card
   isolation, short all-ins, refunds, side pots and ties.
5. Evidence-based profiles, including every interval boundary, expiry, denominator,
   missing-data and policy-version case. Verify the sample report against raw hands.
6. Integrated KO/EN × light/dark × normal/AX5 sweep and interaction checks for all
   concepts. Inspect rendered screens, not only element existence. Run package gates,
   app/UI tests and Engine Release tests. Freeze exact SHA for independent Class-3
   final review; refreeze/review after fixes.
7. Owner/adult-beginner comprehension testing and in-place iPhone 12 mini installation
   with progress preservation. Native VoiceOver audio, iOS 17 and distribution/App
   Store gates remain separate from simulator/browser success.

Ship as one complete release after these gates. No partial English promise, new
analytics, accounts, gambling, social comparison, countdown pressure or public
release is implied by the first-milestone prototype.

## Reference boundaries

Use the [Poker TDA rules](https://www.pokertda.com/view-poker-tda-rules/) as a
primary rules reference for betting and settlement fixtures, while explicitly
documenting this app's resettable, fixed-blind practice format. The page checked
on 2026-09-23 identifies the 2026 version dated September 7; do not reuse older
rule numbers without checking the corresponding text. Tournament procedures are
not automatically requirements for this offline practice mode.

The [NIST interval reference](https://www.itl.nist.gov/div898/handbook/prc/section2/prc241.htm)
supports the Wilson calculation, not the profile names, band boundaries or evidence
minimums. Those remain versioned product heuristics. Neither source establishes
that faster responses prove poker skill.
