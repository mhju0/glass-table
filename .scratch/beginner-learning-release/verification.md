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
| Fixture and copy checks | PASS: `node prototype/verify.cjs`; 169 distinct chart labels, five distinct-card question fixtures, replay chip accounting, KO/EN key parity and 32 computed colour-pair checks. |
| Browser interactions | PASS: all core interaction checkpoints and the separate extra-control run passed. The combined run later stalled in browser transport before its matrix; a fresh-session matrix completed separately. |
| Responsive matrix | PASS: final 192 combinations of 12 states, 320/375px, KO/EN, light/dark and 100/200% text; no page/control-text overflow, undersized enabled controls, English-screen Korean leakage or captured runtime errors. |
| Visual review | Representative rendered opponent, chart, intro, table, review and records screens inspected. Final large-text Settings correction inspected at 320px; labels now stack rather than clip. |
| Native / device / comprehension | NOT PERFORMED: browser 200% text is not iOS AX5; browser focus checks are not a spoken VoiceOver audit. Owner/adult-beginner comprehension and native testing follow mock approval. |

## Interaction evidence

The browser harness operates actual controls and scrolls them into view before
clicking. Direct state assignment is limited to the labelled screenshot/layout
fixtures; it does not count as an interaction pass.

- Settings: opening, language and appearance controls, backward/forward keyboard
  focus wrapping, Escape, backdrop dismissal and focus restoration.
- Practice: five answers including an incorrect answer and a helped question;
  language switching after commitment; leaving after three and continuing;
  completion; replaying the introduction without discarding the answer.
- Chart: no chart before commitment; right/wrong selections; 169-cell overview;
  44px-cell explorer; selecting AA; returning and scrolling to J5o; text rows;
  collapsing and resetting the question.
- Table: all five opponent choices and technical disclosure; previous/next through
  the fixed hand; factual review; post-hand reveal/hide and reset.
- Records: empty, loading, error/retry and sample states; optional timing; five
  proposed style descriptions and the insufficient-evidence alternative.

The fixed four-player hand contributes 2 + 2 + 2 + 0 = 6 chips. The learner's
100 - 2 + 6 = 104 result is a fixture, not evidence of a multiway rules engine.
The chart explicitly uses illustrative colours, not the app's grading policy.
The mock keeps state only while the page stays open; refresh does not preserve it.

Core interaction checkpoints exercised `app.js` SHA-256
`24cf9b79b98e747cd164f9728995dee7a63eb382d63ae26e73ae687faa1a6fe9`.
The later changes were layout-only. The extra-control run completed successfully;
the final fresh-session matrix also exited successfully. The stalled combined
command is not represented as a successful command. `layout-results.json` is the
final matrix evidence; `initial-browser-results.json` is historical evidence only.

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
