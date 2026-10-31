# CI and TestFlight

Four GitHub Actions workflows, all on `macos-15` runners (free minutes, since the repo is public).

| Workflow | Runs on | What it checks | Time |
| --- | --- | --- | --- |
| `ci.yml` | every push to `main`, every pull request, by hand | tool tests, Drills tests, app build + unit tests, focused teaching/recovery/control UI flows, Release launch smoke test, device Release build checked by `tools/verify_release.py` | about 45–55 min with the focused UI subset |
| `engine-gate.yml` | Engine changes, Sundays, by hand | `swift test -c release` for GlassTableEngine | — |
| `ui-tests.yml` | app code merged to `main`, pull requests that edit it, by hand | the full UI flow suite, split across four parallel shards; a failed test is retried once | about 70–75 min per shard (runner speed varies) |
| `release.yml` | a pushed `v*` tag | archive, sign and upload to TestFlight | about 20 min |

`ci.yml` is the gate that has to pass before merging. It includes the focused
`GradedTableRecoveryFlowTests`, `ReviewTeachingFollowupTests`, and AX postflop
chart/Continue regression, with result bundles retained on failure. The full UI suite
runs when app code reaches `main` (app, Engine/Drills sources, `project.yml`), and by hand
on the release commit before a TestFlight tag. It has no schedule: re-running an unchanged
commit only measured simulator flakiness (same commit failed, passed, failed on
2026-10-28/29/30). A test that fails is retried once in a fresh runner process; one that
passes on the retry is listed as a `Flaky, passed on retry` warning instead of failing the run. Its shards split test classes by the minutes each class took on
a GitHub runner, listed in the workflow; `BilingualConsistencyB20Tests` took about
74 min before its 2026-10-31 trim (duplicate runs removed; review screenshots attach only
with `TEST_RUNNER_GT_CAPTURE_EVIDENCE=1`); update its minutes after the next full run. A new UI test class runs without editing the
workflow: it is estimated from its test count and flagged with a warning until its
measured minutes are added. The shard step fails if any `XCTestCase` class in
`GlassTable/UITests` is not assigned to a shard. To run the UI suite on a branch before merging:
Actions → UI tests → Run workflow → pick the branch.

First full run (2026-10-15, run 38664206149): shards 2 and 3 passed in about 51 and
54 min; shard 1 took about 94 min and failed only `AccessibilityAuditTests/testPlayTable`
(contrast, partial Dynamic Type), which fails the same way on `main` before CI existed.

First run with time-balanced shards (2026-10-18, run 39088052141): all four shards
passed, with test steps of 74, 74, 68 and 72 min (tests alone 69, 65, 63 and 65 min).

Build 35 (`d910f99`) passed [CI](https://github.com/mhju0/glass-table/actions/runs/39126165684)
and [TestFlight upload](https://github.com/mhju0/glass-table/actions/runs/39126186102).
Its [full UI run](https://github.com/mhju0/glass-table/actions/runs/39126165724)
had an unresolved AX postflop Continue-button failure in `GradedLearningFlowTests`.
Passing an older full suite does not clear a later candidate's failure.

Build 36 (`6ea894f`, tag `v1.0-36`) passed [main CI](https://github.com/mhju0/glass-table/actions/runs/39222312223)
and [signed upload](https://github.com/mhju0/glass-table/actions/runs/39227091437).
Its exact source tree matches `bb65365`, which passed [all four UI shards](https://github.com/mhju0/glass-table/actions/runs/39212298756)
and the Engine release gate. That corrected suite clears the open follow-up validation
from build 35; it does not change the historical failed run. Apple processing and
internal Me group assignment were verified separately. See the
[release record](records/2026-10-19-build36-release.md).

The focused PR UI gate uses the same iPhone 17/iOS 26.2 destination as the full
workflow. Local follow-up checks used iOS 26.5; they do not establish remote success.

## One-time setup for TestFlight

You do these steps once, in a browser. Nothing here goes in the repository.

1. **Apple Developer Program.** TestFlight needs the paid membership (US$99 a year):
   <https://developer.apple.com/programs/enroll/>. A free personal team can install on
   your own phone, but it cannot upload builds.
2. **Team ID.** Go to <https://developer.apple.com/account> → Membership details →
   copy **Team ID** (10 characters).
3. **App record.** In <https://appstoreconnect.apple.com> → Apps → **+** → New App:
   - Platform iOS, name Glass Table, primary language Korean.
   - Bundle ID `com.michaelju.glasstable`. If it is not in the list, register it first
     at Certificates, IDs & Profiles → Identifiers → **+** → App IDs.
   - SKU: any text, for example `glasstable`.
4. **API key.** In App Store Connect → Users and Access → Integrations → App Store
   Connect API → Team Keys → **+**:
   - Name `GitHub TestFlight`, access **Admin**. Automatic signing creates certificates
     in the cloud, and that needs Admin. Whether App Manager is enough is unconfirmed.
   - Download the `.p8` file. Apple lets you download it **once**.
   - Copy the **Key ID** from the key's row and the **Issuer ID** shown above the list.
5. **GitHub secrets.** On a Mac, in the folder holding the downloaded key:

   ```sh
   gh secret set APPLE_TEAM_ID --repo mhju0/glass-table      # paste the Team ID
   gh secret set ASC_KEY_ID --repo mhju0/glass-table         # paste the Key ID
   gh secret set ASC_ISSUER_ID --repo mhju0/glass-table      # paste the Issuer ID
   base64 -i AuthKey_XXXXXXXXXX.p8 | gh secret set ASC_KEY_P8 --repo mhju0/glass-table
   ```

   Replace `AuthKey_XXXXXXXXXX.p8` with the real file name. Then keep the `.p8` file
   in a password manager and delete the loose copy. Never commit it.

## Shipping a build

Use the focused checks and evidence template in [validation.md](validation.md) first.
Keep one frozen candidate for the checks; record any unresolved failures explicitly.

1. Raise `CFBundleVersion` in `project.yml` (TestFlight refuses a build number it has
   seen). Change `CFBundleShortVersionString` only for a new public version.
2. Merge to `main` and wait for CI to pass.
3. Tag that commit as `v<version>-<build>` and push the tag:

   ```sh
   git switch main && git pull
   git tag v1.0-36
   git push origin v1.0-36
   ```

4. Watch Actions → TestFlight and record its run link. Then check the build's
   processing status and tester availability in App Store Connect → TestFlight.
   Record the installed build and an actual phone flow separately from upload success.

The workflow refuses to upload when:

- a secret is missing;
- the tag is not on `main`;
- the tag does not equal `v` + version + `-` + build from `project.yml`;
- `tools/verify_release.py` rejects the archived app.

A refused tag can be deleted and pushed again:
`git push origin :refs/tags/v1.0-36`.

## Evidence boundaries

The release workflow has run end to end for TestFlight builds 31–37; build-35 and
build-36 upload runs are linked above. Build 37 is recorded in
[the build-37 release record](records/2026-10-20-build37-release.md). A successful upload is not an App Store submission or
proof of processing, installation or correct phone behavior. Keep those states in
the build record. If signing fails, the archive and export logs are kept as a
workflow artifact named `testflight-logs`.
