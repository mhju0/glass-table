# Build 36 validation and TestFlight release

- **Date:** 2026-10-19 · **Kind:** verification / release
- **Asked by / for:** owner; complete full CI, merge changes and upload latest TestFlight build.

## Candidate and preservation

- Version 1.0, build 36; PR #56 depends on PR #55. User authorized both merges and upload.
- Product code was independently reviewed at `5522a12`; final hint copy is `b8ff2cc`.
  Release smoke correction `755c23d` passed both local Release tests without demo hooks.
- Preserve schema 5 progress/recovery bytes, question seeds/indices/grades, offline behavior
  and the owner-approved self-directed lookup policy (D55). No app source change is
  needed for the build-number bump or release orchestration.

## Required evidence

- Full `ci.yml`, four-shard `ui-tests.yml`, and Engine release gate on the frozen candidate.
- Ordered merges of #55 then #56, with equivalent application tree and main CI success.
- Matching main tag `v1.0-36`, signed archive, distributable verification and successful upload.
- Check App Store Connect processing/tester availability if the signed-in session permits it.
- Validation and release are pending. Run links and actual outcomes will be recorded here.

## Still open

- No build 36 upload or Apple processing evidence yet. No phone installation is requested.
- Physical VoiceOver, minimum-iOS runtime and real novice comprehension remain unverified.
