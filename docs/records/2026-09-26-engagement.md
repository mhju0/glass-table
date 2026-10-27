# Engagement: rating prompt, daily reminder, milestone share card

- **Date:** 2026-09-26
- **Kind:** spec notes
- **Originals:** `.scratch/engagement/spec.md` (tracked: `git show f5c5e22:.scratch/engagement/spec.md`)
- **Asked by / for:** owner; Roadmap Phase 2 items 7-9 (`docs/ROADMAP.md`). Owner choices in `docs/decision-history.md` (release plan, 2026-09-25)

## What it was
Spec for three engagement features that share one milestone definition, read from data
the app already saves (no save-format change).

## Findings and decisions
- Milestones, shown only on the lesson summary (rounds and reviews never promote):
  - Unit finished: the lesson's node is the last node of its unit and its `clearedAt`
    falls inside this session (at or after the session's first answer). A rerun of a
    cleared unit is not a milestone.
  - Skill mastered: a skill in the session has `masteredAt` inside this session. Mastery
    only happens on a unit's mixed check.
- Share card: shown on the lesson summary when a milestone was reached; "Share" opens
  the system share sheet with an image made on the phone. Shows app name, the milestone
  ("Finished unit: Read the table" or "Mastered in app: Pot odds"), the unit's skills and
  the date. Never chips, scores, accuracy or money; no link or tracking.
- Rating prompt: `requestReview` only when the learner taps "Back to path" on a summary
  with a milestone; never at launch or during a question. At most once per app version
  (UserDefaults `rating.requestedVersion`). Skipped in UI tests (`GT_TEST_STORE_ID` set).
- Daily reminder: Settings card "매일 알림 / Daily reminder", off by default. Turning it
  on asks for notification permission; if refused, the toggle goes back off and a line
  points to the Settings app. One time of day (default 20:00), one repeating local
  notification. No server, no streak wording, no guilt. Copy: "오늘의 테이블이 준비됐어요.
  몇 분이면 충분해요." / "Your table is ready. A few minutes is plenty." Text is set when
  scheduled, so changing the language reschedules it.
- Planned checks: unit tests for milestone detection (first unit clear, rerun, mastery,
  session without answers), reminder request (identifier, repeat, hour/minute, both
  languages), rating gate (once per version, never in tests). Sweep screens
  `lesson-milestone`, `share-card`, `settings-reminder`, KO/EN at large and AX5.

## Outcome
Shipped in `ae06b8b` (2026-09-26). Later, `70d39d2` made the milestone card name the
track rather than the unit.

## Still open
Per the agent handoff's open issues: the system notification, share and review flows
have never been verified on hardware.
