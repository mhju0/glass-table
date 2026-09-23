# Agent handoff

## 2026-09-19

- What changed: Audited the current `main` branch and refreshed `CONTEXT.md`,
  `docs/submission.md`, and `docs/open-questions.md` to match the shipped R1–R5b
  app, the 2026-08-08/09 performance work, the Xcode 26 requirement, and the
  current release posture. Consolidated shared instructions into `AGENTS.md`.
- Decisions and why: Keep dated plans, specs, and changelog entries historical;
  update only current-facing summaries so their evidence remains traceable.
  The existing store screenshots remain current because the later changes were
  performance-only.
- Open issues: App Store submission is paused for dogfood. Reassess simulated
  gambling age-rating answers and the Korean rating path; complete user,
  signed-device, and store verification before submitting.
- Next step: Continue dogfood on the current release candidate, then record
  feedback and rerun the relevant simulator/device checks before changing the
  submission record.

## 2026-09-22 — GitHub publication preparation

- What changed: Reconciled the research revamp and learner-trust fixes with local
  and remote main, retaining the persistence-safety and performance branch history.
  Refreshed the public README and screenshots for the current first-hand lesson,
  course, EV feedback and policy reference. Historical plans remain dated records.
- Decisions and why: Publish through a reviewed integration PR with hosted CI,
  then fast-forward the primary checkout and remove merged worktrees/branches.
  Keep `AGENTS.md` as shared instructions and this file as the session handoff;
  `PROJECT_HANDOFF.md` retains the detailed earlier delivery history.
- Evidence: Runtime, tests and tooling are unchanged from `847f21c`. The fresh
  package gates passed 335 Drills, 91 Engine Release and 14 tooling tests. The
  screenshot sweep captured and inspected four current screens at normal and
  AX5 sizes on a disposable iPhone 12 mini simulator. See
  `readme-assets/README.md` for capture provenance; the publication PR records
  final app, release and hosted-CI results.
- Preservation: Raw earlier sweeps and the orphan Python bytecode are archived
  locally under the primary checkout's `.build/worktree-archive-20260922.JJYxkt/`.
  Authored `.scratch/`, `.superpowers/` and local Claude settings are retained.
- Open issues: The owner is still testing the iPhone build installed on September
  20. Installation and launch do not establish physical VoiceOver, minimum-iOS-17,
  distribution or App Store acceptance. Current store captures and rating checks
  remain separate from the GitHub screenshots. No device data was changed here.
- Next step: Finish publication verification and record new device feedback
  against `specs/2026-09-20-learner-trust-audit.md`; do not repeat that audit without
  checking its existing dispositions and evidence first.

### Publication completed

- [PR #5](https://github.com/mhju0/glass-table/pull/5) merged as `38fb164` after
  independent review and successful hosted CI + Engine gate on `424d982`.
  Fresh local verification also passed 63 Debug app tests, 2 Release smoke tests
  and unsigned device-bundle checks, in addition to the package/tooling gates above.
- The primary checkout was fast-forwarded to main and its Xcode project regenerated.
  Removed the three redundant revamp/audit/publication worktrees, five merged local
  branches and three merged remote branches. All commit history remains reachable
  from main. Raw captures, logs and XCTest result bundles remain in the local archive.
- GitHub now has the current README, four fresh screenshots and a concise About
  description. No open issues or PRs remained after integration. The final handoff
  update is documentation-only; post-push workflow results remain visible in Actions.
- Next: collect the owner's ongoing iPhone feedback. The physical-device and
  App Store limitations above remain open; no installation or progress reset was
  performed during publication.

## 2026-09-22 — Pot calculation mockups, awaiting owner critique

- Created three local interactive proposals in
  `.scratch/pot-calculation-redesign/index.html`: Table replay, Contribution trays,
  and One decision. The last is guided practice, not equivalent independent
  counting. Each includes first/returning introductions, three choices,
  misconception feedback, retry and a half-pot follow-up.
- Verified the existing stepper/input problem against current code and fresh
  normal/AX5 simulator captures. Research, exact fixture arithmetic and scope are
  recorded in that folder's `spec.md`; browser/contrast evidence is in
  `verification.md`. This records exploration, not an approved product decision.
- No production app, scoring, progress, physical iPhone, GitHub or deployment
  changes. Mockups remain local and uncommitted; the local review server uses
  port 8767 while this session remains available.
- Next: owner critiques/selects the visual and teaching direction before any
  native implementation. App-wide lesson introductions are proposed, not shipped.

## 2026-09-23 — Approved direction and revised pot-calculation mock

- Owner approved beginner-accessible teaching while retaining ranges/EV depth,
  table plus integrated contribution trays, clear action chronology, brief
  first/returning introductions, and neutral answer correction with optional
  calculation detail. Recorded in DESIGN.md; this is direction, not app delivery.
- Built `.scratch/pot-calculation-redesign/hybrid.html`, preserving the original
  three mocks. Three/six-player examples and explicit SB folding are authored
  mock coverage beyond the current native generator. No production changes.
- Verification: persistent `hybrid.test.cjs` passes all four scenarios, prefix
  math, legal turn/raise order and retained folded chips. Browser checks exercised
  introductions, replay, correct/wrong answers, disclosure, retry/new example and
  keyboard help. All four counts passed 375×812 normal/200% geometry checks with
  no clipped app content or out-of-table seats. Details in `hybrid-verification.md`.
- Next: owner critiques the revised hybrid before native implementation. The
  local review server remains on port 8767. No commit, push, phone installation
  or progress reset; native accessibility and learning efficacy remain open.

## 2026-09-23 — Simplified three/four-player pot replay mock

- Owner requested fewer words and a maximum of four players for this mock.
  Revised hybrid.html to one in-seat action caption, progress marks, previous/next
  and brief stopping cue. Removed redundant context/order/action panels.
- Added 220ms pointer-only decorative chip movement, with keyboard and reduced
  motion using static updates. Kept contributions, fold retention, neutral
  feedback and optional calculation. Original three-direction mock is untouched.
- Verification: hybrid.test.cjs passes model, every-frame rendering and stubbed
  motion checks. Browser three/four-player normal/200% matrix passes at 375×812;
  feedback, help, keyboard and reduced-motion controls exercised. Evidence and
  frozen hash are appended to hybrid-verification.md. Mid-flight animation feel
  and native accessibility remain unverified.
- Next: owner critiques the local mock on port 8767 before native implementation.
  No app/phone/progress changes, commit or push. DESIGN.md records the local scope.

## 2026-09-23 — Researched palette comparison

- Owner liked the mock interaction but rejected excessive green across its
  layers. Added charcoal/amber (recommended), slate/blue and paper/pine selectors
  to the same mock, with neutral totals and separate active/feedback color roles.
- Research: Atlassian neutral/semantic roles, Radix gray/accent scales and WCAG
  contrast. Custom values, rationale, frozen hash and evidence are recorded in
  `.scratch/pot-calculation-redesign/palette-research.md`.
- Verification: existing hybrid tests plus 75 contrast pairs pass. Browser checks
  cover all palettes, three/four players, normal/200% text, answer feedback, help,
  palette state preservation and keyboard selection. No captured console errors.
- Next: owner compares palettes before choosing any native/app-wide theme change.
  Recommended mock remains on port 8767. No native, phone, progress, GitHub,
  commit or push changes; color preference and physical-device comfort remain open.

## 2026-09-23: Native pot lesson, appearance and iPhone delivery

- Implemented the approved three/four-player table/tray replay, beginner pot
  introduction, three shuffled choices, neutral correction and optional arithmetic.
  Pot content scrolls together; large text uses ordered trays and stacked choices.
- Added System (default), Light and Dark in 설정 → 화면 모드. Neutral surfaces,
  fixed green tables/cards and amber actions replace the green-on-green layering.
  Updated contrast, sheet behavior, privacy declaration and screenshot tooling.
- Runtime `ae64143` passed independent review. Engine Release 91, Drills 341,
  tooling 17, app XCTest 33 and appearance Swift Testing 6 passed. Debug UI had
  one seeded-count test expectation corrected and rerun successfully; remaining
  34 tests passed in the full run. Both actual Release smoke tests passed.
- Installed and launched Release 1.0 (3) on the owner's iPhone 12 mini in place.
  Progress was byte-identical before installation, after installation and launch.
  No uninstall/reset, schema change, GitHub push or App Store submission.
- Evidence and limits: `specs/2026-09-23-pot-appearance.md`. Local test bundles,
  screenshots and device-preservation copies remain in `.build/pot-appearance-native/`.
  Earlier mock notes are retained; their pending-native status is historical now.
- Next: collect phone feedback on the pot flow and both appearances. Physical
  VoiceOver, minimum-iOS-17 and distribution checks remain open. Other lesson
  introductions and five/six-player diagrams are not part of this delivery.

## 2026-09-23: Beginner release review milestone

- Completed the approved first milestone: current-source audit of all 18 concepts,
  delivery tickets and a bilingual interactive browser prototype covering entry,
  opponents, chart, practice, review and records. The authoritative scope is
  `.scratch/beginner-learning-release/spec.md`; audit and verification sit beside it.
- Preserved adult learning-app positioning, everyday language, optional technical
  detail, accuracy-first progress and explicit safety gates for future persistence
  and four-player rules. Mock records, chart colours and table play are fixtures.
- Core interaction checkpoints and extra controls passed. Final fresh-session
  layout matrix passed 192 combinations; fixture/copy/contrast checks passed
  32 colour pairs. Verification records the browser-transport interruption and
  distinguishes prototype evidence from native, VoiceOver and comprehension tests.
- Preview: `http://127.0.0.1:8768/.scratch/beginner-learning-release/prototype/`.
  Serve the repository root on port 8768 if the local server has stopped.
- No native code, progress/schema, iPhone installation or GitHub push in this
  milestone. Next: owner reviews wording and flows; obtain mock approval before
  tickets 02–06. Full native release and independent data-safety review remain open.

## 2026-09-23: Opponent and navigation mock revision

- Owner approved the review mock's overall direction and requested short opponent
  names, two separate behavior scales, and Learn/Play/Progress instead of Today.
  The revision is in `.scratch/beginner-learning-release/prototype/`; the spec,
  tickets and verification in that folder record the intended native follow-up.
- The five names now map to the existing `Archetype` values. Only the selected row
  expands its entry and raise scales. Percentages and legacy poker names are in
  optional details; Computer 1/2/3 identify the replay seats. These are published
  model settings, not measured behavior in the scripted four-seat example.
- Learn shows one suggestion: unfinished intro/round first; next-lesson and
  review-reminder examples are labelled fixtures. The full path, real review
  scheduling and calibration remain native work, not mock claims. No daily popup.
- Verification: revised interaction run and extra-control run passed; 304 layout
  states and 36 computed contrast pairs passed. After final copy and narrow-nav
  edits, a focused 16-state check passed one-line nav labels and Start reachability.
  `verification.md` holds exact limits and the final 320px/200% capture.
- Next: review the revised mock, then implement tickets 02–06 as the complete
  native release with migration/engine safety gates. This mock changed no native
  app, persistence, phone installation or GitHub remote state.
