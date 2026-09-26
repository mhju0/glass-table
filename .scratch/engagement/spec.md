# Engagement: rating prompt, daily reminder, milestone share card

Date: 2026-09-26. Roadmap Phase 2 items 7–9 (`docs/ROADMAP.md`). Owner choices are in
`docs/decision-history.md` (release plan, 2026-09-25).

## Milestones (shared by the prompt and the card)

A milestone is something the learner did, read from data the app already saves. No
save-format change.

- **Unit finished:** the lesson's node is the last node of its unit, and its
  `clearedAt` falls inside this session (at or after the session's first answer). A
  rerun of a cleared unit is not a milestone.
- **Skill mastered:** a skill in the session has `masteredAt` inside this session.
  Mastery only happens on a unit's mixed check, so both kinds come from the same lessons.

Only the lesson summary shows milestones. Rounds and reviews never promote, so they
have none.

## Share card

- Shown on the lesson summary when a milestone was reached. The "Share" button opens
  the system share sheet with an image made on the phone.
- The card shows the app name, the milestone ("Finished unit: Read the table", or
  "Mastered in app: Pot odds"), the skills in the unit, and the date.
- The card never shows chips, scores, accuracy or money, and has no link or tracking.

## Rating prompt

- `requestReview` runs only when the learner taps "Back to path" on a summary with a
  milestone. Never at launch, and never during a question.
- At most once per app version (UserDefaults `rating.requestedVersion`). The system
  still limits how often the dialog appears.
- Skipped in UI tests (`GT_TEST_STORE_ID` set), so a system dialog cannot block them.

## Daily reminder

- Settings card "매일 알림 / Daily reminder", off by default. When turned on, it asks
  for notification permission. If permission is refused, the toggle goes back off and a
  line points to the Settings app.
- One time of day (default 20:00), one repeating local notification. No server, no
  streak wording, no guilt.
- Copy: "오늘의 테이블이 준비됐어요. 몇 분이면 충분해요." / "Your table is ready. A few
  minutes is plenty." The text is set when scheduled, so changing the language
  reschedules it.

## Checks

- Unit tests: milestone detection (first unit clear, rerun, mastery, session without
  answers), reminder request (identifier, repeat, hour/minute, both languages), rating
  gate (once per version, never in tests).
- Sweep: `lesson-milestone` (summary with share button), `share-card`,
  `settings-reminder`, in KO/EN at large and AX5.
