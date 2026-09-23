# Review milestone verification

Scope: local browser prototype and source audit, based on native `dd2f7e3`.
No Swift, package, production persistence, phone installation or public deployment
changes belong to this milestone. The source audit covers 18 concepts; the browser
prototype demonstrates six representative flows, not 18 implemented native lessons.

## Gates

| Check | Result and boundary |
|---|---|
| Current-source inventory | PASS: all 18 concepts plus shared entry/help/reveal/completion and system surfaces in `audit.md`. Native runtime comprehension remains untested. |
| Plan consistency | PASS: independent read-only review retained storage, accounting and profile safety requirements. This is not a Class-3 runtime review. |
| JavaScript syntax | PASS: `node --check prototype/app.js`. |
| Fixture and copy checks | PASS: `node prototype/verify.cjs`; 169 distinct chart labels, five distinct-card question fixtures, replay chip accounting, KO/EN key parity, five opponent values checked against `Archetype.swift`, and 36 computed colour-pair checks including the new scales. |
| Browser interactions | PASS: the revised full run completed with three-tab navigation, recommendation next/review and resume priority, all five opponent selections and two scale values in KO/EN, technical disclosure, Computer 1/2/3 seats, and the existing practice/chart/table/records flows. The extra-control run checked intro replay, chart scroll/reset, optional timing, loading and Settings backdrop. |
| Responsive matrix | PASS: 304 combinations of 19 states, 320/375px, KO/EN, light/dark and 100/200% text; no page/control-text overflow, undersized enabled controls, English-screen Korean leakage or captured runtime errors. The last opponent and expanded details additionally passed a scroll-to-Start check above the fixed nav. |
| Visual review | Rendered Learn and selected-opponent screens inspected in KO/light and EN/dark, plus the prior chart, intro, table, review and records views. Final large-text Settings correction remains covered by the matrix; a 320px/200% last-opponent capture is retained. |
| Native / device / comprehension | NOT PERFORMED: browser 200% text is not iOS AX5; browser focus checks are not a spoken VoiceOver audit. Owner/adult-beginner comprehension and native testing follow mock approval. |

## Interaction evidence

The browser harness operates actual controls and scrolls them into view before
clicking. Direct state assignment is limited to the labelled screenshot/layout
fixtures; it does not count as an interaction pass.

- Settings: opening, language and appearance controls, backward/forward keyboard
  focus wrapping, Escape, backdrop dismissal and focus restoration.
- Navigation: exactly Learn/Play/Progress, with Learn selected during an intro,
  drill and chart; one recommendation at a time. The next/review switch is a
  labelled review fixture, and an unfinished round takes priority over it.
- Practice: five answers including an incorrect answer and a helped question;
  language switching after commitment; leaving after three and continuing;
  completion; replaying the introduction without discarding the answer.
- Chart: no chart before commitment; right/wrong selections; 169-cell overview;
  44px-cell explorer; selecting AA; returning and scrolling to J5o; text rows;
  collapsing and resetting the question.
- Table: all five short-name choices and their published entry/raise values;
  selected-only scales in both languages, optional technical disclosure and
  Computer 1/2/3 seats; previous/next through the fixed hand; factual review,
  post-hand reveal/hide and reset.
- Records: empty, loading, error/retry and sample states; optional timing; five
  proposed style descriptions and the insufficient-evidence alternative.

The fixed four-player hand contributes 2 + 2 + 2 + 0 = 6 chips. The learner's
100 - 2 + 6 = 104 result is a fixture, not evidence of a multiway rules engine.
The chart explicitly uses illustrative colours, not the app's grading policy.
The mock keeps state only while the page stays open; refresh does not preserve it.

The revised full run exited successfully and wrote `browser-results.json`; the
extra-control run wrote `layout-results.json`. The prior
`initial-browser-results.json` remains historical evidence for the first mock.
After those runs, a copy-only correction changed “seven-seat exercise” to
“existing opponent model” and seat A to Computer 1. A narrow 320px nav rule
removed the icon and kept the English Progress label on one line at 200% text.
Syntax, fixture and contrast checks were rerun on this final source, and the
320px/200% last-opponent/details/Start viewport was recaptured and inspected as
`revision-last-opponent-en-light-200.png`. The full 304-state matrix was not run
again after those final copy/nav changes. A focused final check passed 16 states
(320/375px × KO/EN × light/dark × 100/200% text): each of the three nav labels
stayed on one line without clipping and Start scrolled above the nav. Final
`app.js` SHA-256:
`b191e540e3218d961d432abda7757199a53670489435f36d4551fbbdbed362c9`.

## Findings corrected during this milestone

- Removed the duplicated pre-answer section after chart commitment. The compact
  hand summary and full overview now fit in the initial standard-size mini view.
- Kept card glyphs fixed-size while ordinary text grows.
- Moved technical opponent names/stats into details; added System language choice.
- Retained question/answer state when changing language or replaying the intro.
- Separated assisted counts and independent correct answers in the round summary.
- Corrected the kicker fixture: on the shared two-pair board, the opponent uses
  the shared king, not their queen. Corrected the tie explanation and gave the
  worked example explicit opponent cards rather than a misleading no-pair rule.
- Corrected the three-paying-seats review and the any-preflop-raise denominator.
- Fixed keyboard focus wrapping and restoration in Settings.
- Changed low-contrast chart control edges/focus to the cell's high-contrast ink.
- Stacked Settings/answer controls as text grows. A screenshot caught clipping
  that document-width checks missed; the harness now checks control text overflow.
- Replaced a fixed 800ms loading assertion with waiting for the actual state.
  A timed wait that expires before the fixture finishes is not passing evidence.
- Shortened opponent titles and moved the selected-only two scales under the
  selected row. Removed the Today destination and moved its recommendation to
  Learn. A separate 320px/200% check confirms the final Start control remains
  reachable above navigation even for the last opponent and expanded details.

## Reproduce

Serve from the repository root, then run in another terminal:

```sh
python3 -m http.server 8768 --bind 127.0.0.1
```

```sh
node --check .scratch/beginner-learning-release/prototype/app.js
node .scratch/beginner-learning-release/prototype/verify.cjs
GT_BROWSER_CLI=agent-browser node .scratch/beginner-learning-release/verify-browser.cjs
GT_LAYOUT_ONLY=1 GT_BROWSER_CLI=agent-browser node .scratch/beginner-learning-release/verify-browser.cjs
GT_LAYOUT_ONLY=matrix GT_BROWSER_SESSION=gt-beginner-final GT_BROWSER_CLI=agent-browser node .scratch/beginner-learning-release/verify-browser.cjs
```

`GT_BROWSER_CLI` accepts an installed executable path. This run used the existing
cached executable at `/Users/michaelju/.npm/_npx/9612fddc7eeb8d72/node_modules/.bin/agent-browser`,
not a newly installed dependency. `GT_PREVIEW_URL` overrides the local URL.
Layout screenshots and machine-readable results live in `evidence/`. Full-page
captures include fixed navigation at the viewport position; interaction checks
separately establish that lower controls can be scrolled above it.

## Skill delivery gate

The design-system and antislop skills kept the existing paired semantic palette,
fixed felt/cards, amber actions, readable states and restrained motion. Their
verification requirements prompted the keyboard, control-text and contrast fixes.
Design rationale and dials are in `prototype/README.md`.

The review deliverable requires functional controls, labelled fixture data, no
page or control-text clipping in the matrix, visible focus, computed contrast and
rendered inspection. These checks qualify this prototype for owner review only.
They do not establish App Store readiness or beginner comprehension.
