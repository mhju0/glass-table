# Beginner learning release: audit, spec and browser prototype

- **Date:** 2026-09-23
- **Kind:** spec notes
- **Originals:** `.scratch/beginner-learning-release/` (`spec.md`, `audit.md`, `verification.md`, `verify-browser.cjs`, `issues/01-07`, `prototype/`, `evidence/*.png`, `evidence/*.json`) (tracked: `git show f5c5e22:<path>`)
- **Asked by / for:** owner, to make the app understandable to adult beginners in full Korean and English. Baseline `dd2f7e3`. Native delivery record: `docs/specs/2026-09-23-beginner-native-release.md`.

## What it was
A current-source audit of all 18 concepts, an approved release spec, a bilingual six-flow browser prototype for owner review, and seven tickets that took the combined release to native 1.0 (4).

## Findings and decisions
Audit findings (source at `dd2f7e3`):
- Opponent names/stats assumed poker knowledge (`Archetype.swift`); hand summary on the defend chart took disproportionate height (`DefendGridView` flexible min height); full English needed a semantic copy layer (only `FirstLessonCopy` was localized); most free-practice concepts lacked a why/how entry; free practice had no round end.
- Historic totals count near answers as correct, so cannot be relabelled strict accuracy; `ProgressState.answers` keeps only 500 rows, so daily history cannot be reconstructed.
- Four-seat play needed a new model (`Table.swift` is one hero vs one villain; D08 excluded multiway). The documented eight-miss stop helper (`Mastery.shouldStopDrilling`) has no UI caller; do not claim it shipped.
- Audit proposed KO/EN plain titles and one-line "why" for all 18 concepts (showdown through MDF). Simplification may never turn expected pot share into win probability, equate a pair with a strong hand, or call chart disagreement an EV mistake.
Approved scope (owner, 2026-09-23; combined first and second versions into one native delivery):
- Everything open; recommended sequence is guidance, not a lock. Optional untimed starting-point check (self-report, 3 questions, unsure, skip), stored separately from mastery; replayable from Learn and Settings. No accounts.
- Three tabs Learn / Play / Progress (Today folded into Learn: resume > due review > next lesson; honest completed state). Settings language System / 한국어 / English; switching preserves seed, index, input, replay, reveal and table; stable term IDs.
- Opponent picker: five stationary vertical rows, short titles Cautious/신중형, Selective/선별형, Aggressive/공격형, Caller/콜 위주형, Very aggressive/매우 공격형; tap opens a stable bottom sheet with separate "how often it enters" and "how often it raises" scales; VPIP/PFR and poker names in details; seats Computer 1/2/3. Owner asked for shorter titles, separate scales, three tabs, then fixed rows.
- Chart: compact selected-hand summary, chart is the main content; explorer with cells ≥44 pt; recommendations only after commit.
- Five-question rounds, each answer recorded at commit. Summaries split exact/near/miss, chart match, EV loss; assisted vs independent kept separate. Optional timing: never a countdown, score or FSRS input; comparison windows need ≥10 eligible correct answers across 3 days (product choices, not standards).
- Persistence (Class 3): schema 2 atomic ProgressState, original schema-1 bytes kept, idempotent commands, imports replace never merge, proposed 64 MiB import limit benchmarked with 8 and 48 MiB fixtures; never silently trim history.
- Four-player practice (Class 3): integer chips, 100 per seat, blinds 1/2, no ante/rake, rotating dealer, explicit refill to 100 recorded separately; side pots, short all-in reopening, odd chips; bots see only their cards; factual review only, no EV grades or FSRS. Poker TDA rules (2026 version, 2026-09-07) as betting reference.
- Observed styles: latest 200 eligible hands within 30 days; need ≥100 hands, 5 days, 40 voluntary entries; participation bands <30 / 30-50 / >50%, raise-share bands <40 / 40-70 / >70%; 95% Wilson interval must sit wholly inside a band; four corners get labels, middle-band combinations "Mixed", straddling stays unassigned. Authored heuristics, not validated classifications; never infer personality, intent or skill.
Prototype verification (browser only):
- Final picker run: 72 layout states (320/375/760 px × KO/EN × light/dark × 100/200%), five sheet flows, focus/Escape/backdrop, inert background passed; earlier inline version 304 states and 36 colour pairs. 169 chart labels, KO/EN key parity and the five opponent values matched `Archetype.swift`.
- Fixes during the milestone: duplicated pre-answer section removed; kicker fixture corrected (opponent uses the shared king); tie explanation and denominators corrected; Settings focus wrap; chart contrast; English Back clipped at 320 px/200% and was shortened.
- Screenshots proved compact KO/EN light/dark layouts of each flow and the reachable Start in the last-opponent sheet at 320 px/200%.

Issues:
- 01 Review prototype: implemented; owner approved direction and native work 2026-09-23.
- 02 Localize and simplify lesson surfaces: implemented; three tabs, open path, placement, full KO/EN, 18 concepts checked.
- 03 Progress storage (Class 3): implemented; schema 2, migration backup byte-identical, survived in-place install on iPhone 12 mini.
- 04 Rounds and records: implemented; per-answer commit, resume, exact/near/miss, optional timing.
- 05 Four-player practice (Class 3): implemented; rules engine, blinded bots, resume, factual replay; frozen-code review accepted.
- 06 Observed styles: implemented; Wilson-band heuristic recomputed per hand and render.
- 07 Integrated release: ready-for-human; technical gates passed.

## Outcome
Native release 1.0 (4) installed in place on iPhone 12 mini with schema-1 progress and recovery bytes preserved. Gates: 41 model XCTest, 6 appearance Swift Testing, 43 app UI tests, 3 compact-equity and 2 Release smoke UI tests, 348 Drills XCTest + 22 Swift Testing, 91 Engine Release XCTest, 20 tooling tests; 256-capture Mini matrix (KO/EN, light/dark, normal/AX5). Independent Class-3 acceptance of the exact candidate. Commit for the prototype/audit: `173726e`.

## Still open
- Adult-beginner comprehension testing and physical VoiceOver (issue 07).
- Minimum iOS 17 runtime and signed distribution / App Store checks.
