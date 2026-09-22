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
