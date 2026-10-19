# Records

Short text records of finished reports, audits, research, scratch work and old session
notes. The owner asked (2026-10-15) to keep these instead of the originals: HTML reports,
screenshots, JSON ledgers, mocks and local evidence folders were deleted once their
record existed.

- **Tracked originals** are still in git: `git show f5c5e22:<path>` (each record lists
  its paths). Example: `git show f5c5e22:docs/audits/2026-10-11-numerical/index.html`.
- **Local originals** (`.build/`, `.archive/`, untracked files) are gone; the record is
  the only copy. Binary hashes for installed builds are in `docs/build-history.md` and
  `2026-10-15-local-archives.md`.
- Older docs and specs still mention `.build/...` evidence paths; those folders no
  longer exist.

## Adding a record

When a `.scratch/<slug>/` folder, report or audit is finished, write one file here named
`<yyyy-mm-dd>-<slug>.md` (date the work started), repoint links, and delete the
originals. Keep it to about 20–80 lines:

    # Title
    - **Date:** · **Kind:** report | audit | research | spec notes | feature notes | verification | session history
    - **Originals:** paths (and how to retrieve them)
    - **Asked by / for:**
    ## What it was
    ## Findings and decisions   (keep IDs, who decided and why, exact numbers)
    ## Outcome                  (commits, builds, PRs)
    ## Still open               ("Nothing." if resolved)

No images, base64, HTML, secrets or personal data.

## Index

| Record | Title | Kind |
| --- | --- | --- |
| [2026-10-19-review-followups.md](2026-10-19-review-followups.md) | Independent review follow-ups and validation routine | verification |
| [2026-10-18-independent-build-review.md](2026-10-18-independent-build-review.md) | Independent review of Claude updates, builds 24–35 | audit |
| [2026-07-21-m1-plans.md](2026-07-21-m1-plans.md) | Milestone 1 scope and implementation plans | spec notes |
| [2026-07-24-outs-reveal-legibility.md](2026-07-24-outs-reveal-legibility.md) | Outs drill: card legibility, full-table reveal and tap-to-explain | spec notes |
| [2026-07-25-onboarding-first-hand.md](2026-07-25-onboarding-first-hand.md) | 첫 핸드: onboarding as a played hand, not a read document | spec notes |
| [2026-09-04-session-history.md](2026-09-04-session-history.md) | Agent session history, 2026-09-04 to 2026-10-13 | session history |
| [2026-09-04-tooling-and-workspace-history.md](2026-09-04-tooling-and-workspace-history.md) | Tooling and workspace history | audit |
| [2026-09-19-card-display-benchmarks.md](2026-09-19-card-display-benchmarks.md) | Mobile poker card display benchmarks | research |
| [2026-09-20-learner-trust-evidence.md](2026-09-20-learner-trust-evidence.md) | Learner-trust audit screenshot evidence | verification |
| [2026-09-22-pot-calculation-redesign.md](2026-09-22-pot-calculation-redesign.md) | Pot calculation redesign mocks and palette comparison | research |
| [2026-09-23-beginner-learning-release.md](2026-09-23-beginner-learning-release.md) | Beginner learning release: audit, spec and browser prototype | spec notes |
| [2026-09-23-consistent-learning-table.md](2026-09-23-consistent-learning-table.md) | Consistent learning table: spec, teaching plan, prototype and line-parity audit | spec notes |
| [2026-09-24-first-run-and-play.md](2026-09-24-first-run-and-play.md) | First run, answer feedback, thumb reach, Play setup and Learn | spec notes |
| [2026-09-25-holdem-basics.md](2026-09-25-holdem-basics.md) | Hold'em basics lesson | spec notes |
| [2026-09-26-engagement.md](2026-09-26-engagement.md) | Engagement: rating prompt, daily reminder, milestone share card | spec notes |
| [2026-09-30-uxaudit-codex-review.md](2026-09-30-uxaudit-codex-review.md) | Codex review of the Claude UX audit crawl | audit |
| [2026-10-02-direction-a-delivery.md](2026-10-02-direction-a-delivery.md) | Direction A delivery report (free table redesign and support pages) | report |
| [2026-10-02-verification-reports.md](2026-10-02-verification-reports.md) | Verification reports: Direction A, iPhone install, support pages, native refinement | verification |
| [2026-10-05-analytics-and-launch-services.md](2026-10-05-analytics-and-launch-services.md) | Analytics and launch services research | research |
| [2026-10-07-device-feedback-build16.md](2026-10-07-device-feedback-build16.md) | iPhone 13 mini feedback session on build 16 (C001-C028) | research |
| [2026-10-08-implementation-reconciliation.md](2026-10-08-implementation-reconciliation.md) | Implementation reconciliation of device feedback (build 18) | audit |
| [2026-10-10-first-five-minutes.md](2026-10-10-first-five-minutes.md) | The first five minutes: opening research, prototypes and owner feedback (build 19) | research |
| [2026-10-10-whole-app-consistency.md](2026-10-10-whole-app-consistency.md) | Whole-app consistency study for the experience-first opening | research |
| [2026-10-11-audit-followups.md](2026-10-11-audit-followups.md) | Build 22 audit follow-ups: decision map | audit |
| [2026-10-11-brand-welcome.md](2026-10-11-brand-welcome.md) | Brand welcome exploration (build 21 feedback) | research |
| [2026-10-11-numerical-audit.md](2026-10-11-numerical-audit.md) | Numerical audit of build 20 (are the app's numbers correct?) | audit |
| [2026-10-13-lesson-feedback.md](2026-10-13-lesson-feedback.md) | Lesson feedback on build 24, and "a near miss is wrong" | feature notes |
| [2026-10-14-animation-plans.md](2026-10-14-animation-plans.md) | Animation audit plans 001-003 | audit |
| [2026-10-14-clickable-controls.md](2026-10-14-clickable-controls.md) | Clickable things must look clickable | feature notes |
| [2026-10-14-codex-ci-repair.md](2026-10-14-codex-ci-repair.md) | Codex CI repair attempt (PR #11) and its diagnostic branches | report |
| [2026-10-14-guided-hand-on-table.md](2026-10-14-guided-hand-on-table.md) | "A hand together" rebuilt on the Play table | feature notes |
| [2026-10-15-local-archives.md](2026-10-15-local-archives.md) | Local archives and build folders inventory | verification |
| [2026-10-15-screenshot-ux-audit.md](2026-10-15-screenshot-ux-audit.md) | Screenshot UX audit, revision 2 (69 findings) | audit |
