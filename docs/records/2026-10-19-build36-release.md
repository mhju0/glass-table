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

## Validation corrections

- Candidate `605c8c2` passed Engine release tests (96 XCTest), but CI run
  `39203624861` failed one of 14 focused UI tests: the AX5 guide test asserted
  removal immediately after Done. All seven topic/lookup/reading-position checks
  passed; the captured tap landed within the visible Done button. The unchanged
  test passed locally on iPhone 17/iOS 26.1; CI used iOS 26.2.
- The test now waits up to five seconds for dismissal and confirms Settings returns,
  retaining all page and lookup assertions. This is test synchronization only;
  the corrected exact test passed locally on iPhone 17/iOS 26.1 (241 seconds).
  Replacement CI is required. The full UI run on `605c8c2` is still pending.

## Still open

- No build 36 upload or Apple processing evidence yet. No phone installation is requested.
- Physical VoiceOver, minimum-iOS runtime and real novice comprehension remain unverified.
