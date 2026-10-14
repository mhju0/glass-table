# CI and TestFlight

Four GitHub Actions workflows, all on `macos-15` runners (free minutes, since the repo is public).

| Workflow | Runs on | What it checks | Time |
| --- | --- | --- | --- |
| `ci.yml` | every push to `main`, every pull request, by hand | tool tests, Drills tests, app build + unit tests, Release launch smoke test, device Release build checked by `tools/verify_release.py` | about 15 min |
| `engine-gate.yml` | Engine changes, Sundays, by hand | `swift test -c release` for GlassTableEngine | — |
| `ui-tests.yml` | nightly 03:00 KST, by hand | the full UI flow suite, split across three parallel shards | up to 2 h |
| `release.yml` | a pushed `v*` tag | archive, sign and upload to TestFlight | about 20 min |

`ci.yml` is the gate that has to pass before merging. The UI suite is too slow for every
push, so it runs nightly. Its shards split test classes by test count, so a new UI test
class runs without editing the workflow. To run the UI suite on a branch before merging:
Actions → UI tests → Run workflow → pick the branch.

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

1. Raise `CFBundleVersion` in `project.yml` (TestFlight refuses a build number it has
   seen). Change `CFBundleShortVersionString` only for a new public version.
2. Merge to `main` and wait for CI to pass.
3. Tag that commit as `v<version>-<build>` and push the tag:

   ```sh
   git switch main && git pull
   git tag v1.0-30
   git push origin v1.0-30
   ```

4. Watch Actions → TestFlight. When it passes, the build appears in App Store Connect →
   TestFlight after Apple's processing, usually 5–30 minutes. Internal testers get it
   then. External testers need a one-time Beta App Review first.

The workflow refuses to upload when:

- a secret is missing;
- the tag is not on `main`;
- the tag does not equal `v` + version + `-` + build from `project.yml`;
- `tools/verify_release.py` rejects the archived app.

A refused tag can be deleted and pushed again:
`git push origin :refs/tags/v1.0-30`.

## Not yet proven

`release.yml` has not run end to end. It cannot, until the secrets above exist. The
first real tag is its test. If signing fails, the archive and export logs are kept as a
workflow artifact named `testflight-logs`.
