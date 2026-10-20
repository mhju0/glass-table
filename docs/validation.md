# Build checks and beginner sessions

Keep each candidate focused. Continue using concrete phone feedback, visible hand
explanations, simple automatic navigation, explicit pass rules and recoverable progress.
This page is a working routine, not evidence that its checks have been performed.

## Before building

Write one sentence: who is struggling, what they do, and what should happen instead.
List the existing behavior to preserve. Pick the checks before implementing.
If a question is graded, make sure the visible premise determines its answer under
the stated model. Hiding a required assumption is not a harder question.

- Layout/copy: render the affected screens on a compact phone at normal and AX5,
  in Korean and English, light and dark; exercise the controls and full scrolling.
- Teaching/generator: reproduce a concrete spot; verify legal actions, answer and
  explanation agree; preserve saved question identity and first-step fixtures.
- Progress/recovery: exercise success, failed save, retry, relaunch and old-session
  restore. Count only actual work, once. Preserve original bytes during any upgrade.
- Cross-screen state: leave, resume and switch language without resetting navigation
  or progress. Use the actual app path, not only a demo frame.

When changing onboarding, Settings navigation or the learning guide, also run
`GlassTableReleaseSmoke` in Release without demo hooks before delivery. Keep its
assertions aligned with stable topic/control identifiers and exercise navigation;
a passing Debug demo flow does not establish the real Release path.

Run relevant package/app tests and the required CI gates. A fresh full UI workflow
can run separately; inspect any failures on the exact candidate and record whether
they are fixed, reproduced, or still unresolved. Do not silently call them flakes.

## Motion checks

Use Apple's [Motion HIG](https://developer.apple.com/design/human-interface-guidelines/motion)
for purposeful, brief feedback, natural gesture response and cancellable interaction.
Keep instructional card/chip sequencing distinct from decorative UI effects. A slider
and its live content should follow direct manipulation without trailing animation.

- Exercise repeated selections, reversals, dismissal and return. Verify that the final
  visible state matches the last action, without committing an answer or losing work.
- Check normal motion and the actual system Reduce Motion setting. The free-table
  `GT_DEMO_REDUCE_MOTION` override covers only that path; it does not exercise SwiftUI's
  environment in other screens. Use a disposable simulator for system-setting checks.
- Inspect rendered feedback as well as final state. Screenshots establish content and
  geometry; recordings or observed interactions are needed to judge timing/continuity.
  Retain readable text, selection marks and accessible labels when movement is removed.
- Include compact screens and relevant Korean/English normal/AX5 flows. Simulator
  evidence does not establish physical-device feel, haptics or measured frame rate.
- For repeating amount controls, verify one-step taps, multiple adjustments during a
  hold, stopping on release/drag-away/scroll, both bounds and fresh input after a
  background or dismissal. Native repeat cadence belongs to the system; do not assert
  the removed custom timer's delay or interval as the expected platform behavior.

## Navigation glass checks

Keep glass on explicit navigation roles; content controls retain their existing opaque
surface. Compare native baseline/candidate frames in light and dark, Korean and English,
normal and accessibility text sizes. Verify the 40-point tile, 44-point tap reach,
content alignment, labels, scroll reachability and close/back/menu cancellation.

Exercise actual system Reduce Transparency and Increase Contrast independently and
confirm the opaque fallback, with Reduce Motion checked separately. Inspect held
feedback and small text contrast as well as idle appearance. Shared glass containers
can change pressed rendering: verify real holds before introducing one. Pre-iOS-26
availability guards are not evidence of runtime testing on an older OS.

## Device accessibility and interaction checks

An automated accessibility audit is diagnostic evidence, not a substitute for actual
VoiceOver traversal. Inspect flags against settled pixels and spoken information;
keep failures visible rather than suppressing them to make a gate green. Consolidated
card/seat labels and deliberate D54 caps require checking the actual spoken meaning.

- In actual VoiceOver, navigate Settings to Glossary, activate the focused button,
  traverse search and entries, return to focused Close and activate it. Verify focus
  returns to the invoker, reopen and dismiss again, then move onward without a later
  focus jump. Include Korean AX5 and English normal text. Check native dismissal too;
  synthetic Escape input alone does not establish a two-finger scrub result.
- Traverse table seats, hero cards, pot and action controls. Opponent cards remain
  face down before showdown, including spoken output. Check the actual menu items.
- Record device OS, build configuration and binary/source identity separately for
  Debug test-store flows and Release measurements. Run signed updates with the
  owner's selected data policy; keep physical feel and haptics distinct from automation.
- For performance, measure a bounded Release interaction with Instruments. Inspect
  frame/hitch data and main-thread stacks; potential delays during XCTest snapshots
  are not automatically user hangs. Do not infer FPS from frame-event counts or claim
  an improvement without a comparable measurement. Prefer a narrow fix supported by
  an observed app bottleneck over broad layout/concurrency changes.

## Before a TestFlight tag

Freeze the candidate commit. Finish focused checks after the last relevant edit.
Use an independent reviewer for teaching assumptions and progress/recovery changes.
Record the evidence below in `docs/build-history.md`; keep unresolved checks visible.
Follow `docs/ci-cd.md` for upload steps. Upload success, Apple processing, tester
availability, installation and observed behavior are separate observations.

```text
Build / exact commit:
Problem and observable change:
Preserved behavior:
Automated checks / run links:
Screens and interactions / device, runtime, languages, text sizes, appearance:
Fresh and existing-progress checks:
Independent review / findings resolved:
Upload / processing / availability / installation / observed phone flow:
Still unverified or failing:
```

## First session: knows the rules, rarely plays

The owner selected this participant profile on 2026-10-19. Record their actual
experience rather than treating them as a complete beginner. This is observation of
one person, not a measured learning or retention claim. Use the same candidate for
later comparisons. Feedback on an older build is useful too; label it with that
build and repeat affected tasks after updating before claiming a correction worked.
Ask before taking notes or recording; no recording is needed. Use participant labels,
not personal details. Do not copy their progress off a phone without asking.

1. Record the build, phone, language, text size and prior poker experience. Use a
   separate test phone or an explicitly approved fresh installation; do not reset
   someone's existing progress just to run this session.
2. Say: “Try practising when a call makes sense. Please say what you are
   looking for and what you expect. The app is being tested; you are not.”
3. Let them open the app and find the call-or-fold lesson in Learn. Observe the
   opening route too if this is a fresh install. Let them choose how to handle any
   earlier-lesson suggestion. Ask whether the material adds anything to the rules
   they already know, without telling them that it should.
   Watch where they pause, backtrack, misread a control or need help. Do not point
   at the right button. If they get stuck, record the help you gave and move on.
4. After a reveal, ask: “Why was that choice right or wrong?” Then use a different
   question and ask them to explain their choice before revealing it. Record their words, not a
   conclusion that they have mastered poker.
5. Ask them to leave the lesson, find where to continue, and explain what the
   progress indicator means. Check whether their expectation matches the app.
6. Finish with: “What was confusing? What would you try next?” If appropriate,
   invite them to try one different hand on a later day; record that separately.

| Task / screen | What they expected or said | What happened | Help given | Candidate issue |
| --- | --- | --- | --- | --- |
| | | | | |

Afterward, choose the most consequential observed problem for the next candidate.
Separate observation (“tapped the row three times”) from interpretation (“did not
recognize the action”). Keep feedback that confirms useful behavior as well as bugs.
Save a short dated session record under `docs/records/`, with no invented results.

A later session with someone who has never played should instead start with the
opening and first showdown lesson, then ask “Why did that hand win?” Keep the two
participant groups separate; success with a casual player does not settle novice
comprehension.

## Useful owner feedback

For each note: build, screen, action, expectation, actual result, screenshot if useful,
and why it matters. Mark it as incorrect teaching, lost progress, blocked interaction,
confusing wording or visual preference. Prefer the smallest change that solves the
observed problem, and recheck the flow you already liked afterward.
