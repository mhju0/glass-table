# Production readiness audit — 2026-09-14

The Warm revamp is a local release candidate, not an App Store release. This
follow-up audits the whole app, including existing persistence and distribution
configuration. No account, analytics, advertising, purchase or wagering capability
was added. The user's own testing remains part of release acceptance.

## Security and progress integrity

An independent security review reproduced two crashes from imported JSON: an
`Int.max` answer count overflowed on the next answer, and extreme FSRS stability
trapped during conversion to an integer interval. Import now validates numeric
bounds, count relationships, review state, dates and interval shape. Scheduler
conversion also clamps before converting. Valid negative EV estimates, schema-1
history, retired dictionary keys and legacy progress remain supported.

File imports have a 5 MiB limit, with throwing bounded reads and background
read/decode/validation. Late completion cannot replace progress after the view has
closed or a newer request has started. The final encoded output is bounded too;
a review regression proves oversized replacement leaves live bytes and recovery
copies unchanged. Current answer history retains its existing 500-answer cap.

Recovery exposes **원본 파일 내보내기** through the system share sheet, including
files too large to decode. It shares the existing file URL without reading it
into a `Data` allocation. Reset/import still copy original bytes before atomic
replacement; displayed state changes only after a successful write. Existing
recovery copies are retained rather than silently purged.

The full 159-commit Git history passed a redacted Gitleaks scan. Source review
found no networking client, third-party SDK, credentials, arbitrary ATS exception,
protected-resource permission or account boundary. These checks do not prove the
absence of every security issue. Signed-device data protection and distribution
entitlements remain unverified.

## Release engineering

- The actual unsigned **iPhone device archive** built successfully and passed
  `tools/verify_release.py`: expected ID/version/platform, Korean language,
  iOS 17 deployment target, privacy manifest, fonts, assets and license notices.
- Debug launch hooks and test plug-ins are absent from that archive.
- FSRS's MIT notice is bundled alongside Pretendard's OFL notice and readable
  from Settings. The repository's own license remains unchanged.
- CI now exercises app tests, Release launch without demo hooks, and device
  Release bundle checks. Those workflow additions have been checked locally;
  this branch has not been pushed, so hosted CI execution is still pending.

## Verification

- 327 Drills tests passed, including malformed imports, signed EV intervals,
  legacy bounds, encoded-size limits and original-byte preservation.
- 25 app model tests passed; 14 simulator UI tests passed, including three
  accessibility flows and answer persistence across relaunch.
- 11 tooling tests passed, including deliberate invalid Release bundle fixtures.
- The unchanged Engine retains the prior 91-test Release gate from the revamp.
- The first app run caught an impossible test fixture (a due date on an unreviewed
  record). The fixture now uses a real reviewed state; validation was not weakened.
- A dedicated Release smoke scheme avoids the Debug-only unit test module's
  `@testable` build requirement without changing the distribution configuration.

## Performance evidence

Reproducible harness: `swift run -c release --package-path tools/performance-audit GTPerf`.
It generates and grades 1,000 deterministic spots for each of 18 concepts, using
seed `0x5eed`. These are native Mac Release measurements, not phone frame times.

| Work | Median | p95 | Maximum |
|---|---:|---:|---:|
| Range advantage generation + grading | 27.195 ms | 30.995 ms | 119.058 ms |
| Encode a 500-answer store (26,862 bytes) | 0.813 ms | 0.924 ms | 1.023 ms |
| Atomic save of that store | 1.198 ms | 1.393 ms | 2.669 ms |

All other concept samples completed in under 2 ms. The isolated earlier run had
a 44.076 ms maximum for range advantage; the final run overlapped an Xcode build,
so the 119 ms outlier is retained rather than hidden. Range advantage work already
runs off the UI thread. No generator rewrite was justified by these measurements.
The harness is a sampled workload, not a proof over every seed or a battery/memory
profile. Physical-device thermal, energy and older-device measurements remain.

Apple recommends measuring responsiveness and moving expensive work away from
the main thread: [Improving app responsiveness](https://developer.apple.com/documentation/xcode/improving-app-responsiveness).
The import change addresses an observed untrusted-input path, rather than adding
caches or concurrency to ordinary sub-millisecond work.

## Remaining release gates

1. User acceptance of the learning experience and signed Release testing on a
   physical iPhone: Files import/export, interrupted lessons, relaunch, VoiceOver,
   larger text and offline use. No physical-device installation was performed.
2. Validate distribution signing, entitlements and archive privacy report in
   Xcode Organizer. A development identity is available locally; a distribution
   identity was not found. No signing credentials were changed.
3. Choose release territories and finish the actual age-rating questionnaire.
   Apple requires a Rating Classification Number for frequent/intense simulated
   gambling in South Korea. The table contains simulated betting; Education is
   not an exemption. [Apple regional definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/).
4. Review final store screenshots and metadata after user feedback, publish the
   reviewed privacy-policy draft, and validate the App Store Connect submission.
   The live policy returned HTTP 200 but still contained the older July text.
5. Verify minimum-OS behavior on iOS 17; only newer simulator runtimes were
   installed here. Successful deployment-target compilation is not an iOS 17
   runtime test.

No App Store upload, submission or production deployment was performed.
