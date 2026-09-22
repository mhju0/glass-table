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
