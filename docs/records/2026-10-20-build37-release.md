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

- Release candidate, exact-head CI, merge, signed upload and Apple processing are
  pending. Provider results will be recorded in the release PR and this record.
