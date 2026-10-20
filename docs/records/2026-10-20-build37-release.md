# Build 37 release

- **Date:** 2026-10-20 · **Kind:** verification
- **Asked by / for:** owner explicitly requested the latest work as a new TestFlight build.
- **Source:** reviewed scope-4 head `e9c8fb6d59e73976196935457270548311ee9a67`,
  integrating motion, native amount controls, restrained navigation glass and VoiceOver fixes.

## Findings and decisions

- Public version stays 1.0; build number rises from 36 to 37 in `project.yml`.
- Product source is unchanged from the reviewed, phone-tested candidate. Exact
  scope-4 CI `39362304824` passed; source fixes and verification boundaries are in
  `2026-10-20-interaction-accessibility.md`.
- Strict Korean/light summary contrast audit remains red with glass; pre-glass and
  actual Reduce Transparency controls pass. Measured heading contrast is 11.555:1.
  Nine unlocated diagnostic findings remain open. This release is not full
  accessibility clearance; see `2026-10-20-accessibility-audit-followup.md`.
- Preserve app progress and recovery rules; no schema, grading or account changes.
- No new phone installation or App Store review submission is included.

## Outcome

- Release candidate `edd0daf26063000d361b4d2b5f635dae69b7164f` independently accepted;
  CI `39378993484` passed all gates, including 671 Drills, app unit tests, 22 focused
  UI tests, 2 Release smoke tests and device Release bundle checks.
- PR #61 merged to `be1c839769030c2ef1f6f129e4dcbea15bce50ca`. Candidate and merge
  have identical tree `313e2a07dbb018e9ea895601dd3a8d233f19e034`; tag `v1.0-37`
  points at that exact merge. #58 included; #59/#60 closed as superseded by #61.
- Owner asked to accelerate in parallel. Independent review accepted retaining the
  complete premerge CI gate, then running identical-tree main CI and upload together.
  Main CI `39383668606` passed all configured gates on the exact merge SHA.
  Signed TestFlight run `39383694571` passed archive, distributable verification
  and upload on the exact merge SHA.
  App Store Connect first showed Processing (created October 20 at 16:05 KST), then
  processed build 1.0 (37), Ready to Submit for external review, assigned to existing
  Me internal group (one tester). Build detail confirms Me / Internal / 1.
  Build ID `1bd1947f-793f-4b1b-a265-dbebd0885be8`. Owner installation is unverified.

- Korean and English What to Test notes, including the audit limitation, were saved
  together in the available Korean Test Details field; Apple showed Saved. No external
  group or Beta App Review submission was added for build 37.
