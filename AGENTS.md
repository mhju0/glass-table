# Glass Table

iOS app that teaches No-Limit Hold'em in ranges and EV. Start with `CONTEXT.md`.
Design docs live in `docs/`: `product-brief.md`, `decisions.md`, `open-questions.md`,
`risks.md`, and delivery specs under `docs/specs/`. Finished reports, audits and scratch
work are kept only as short text records in `docs/records/` (see its README).

Requires macOS, Xcode 26+ (even though deployment targets iOS 17), and XcodeGen
(`brew install xcodegen`). Run from the repository root:

```sh
xcodegen generate
open GlassTable.xcodeproj  # run the app from Xcode
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO test
swift test --package-path GlassTableDrills
swift test -c release --package-path GlassTableEngine
tools/uisweep.sh --screen today  # omit --screen for the full sweep; --list lists names
```

Engine changes require the **release** test gate; debug is impractically slow.
CI (`.github/workflows/`) gates pushes and PRs on unit tests; the UI suite runs nightly.
Ship to TestFlight by raising `CFBundleVersion` and pushing a `v<version>-<build>` tag
on `main`; see `docs/ci-cd.md`.
No linter is configured. The screenshot sweep uses debug `GT_DEMO_*` hooks on a
disposable simulator; `GT_SIM` selects a device/runtime by existing simulator name.
`--no-build` reuses only a matching build from a prior sweep in this checkout.
The sweep defaults to normal (`large`) and AX5 text sizes; `GT_CONTENT_SIZE`
selects one size for a focused check. Inspect both sets of affected screenshots
and run relevant UI interactions: an initial frame cannot prove scroll reachability.
Before reopening learner-trust audit findings, read
`docs/specs/2026-09-20-learner-trust-audit.md` for branch scope, resolved claims,
regressions and verification limits.

- `project.yml` owns the generated, gitignored `GlassTable.xcodeproj/` and
  `GlassTable/Info.plist`. Edit the YAML, not those outputs.
- The app depends on both Swift packages; Drills depends on Engine. Keep both
  packages independent of UIKit/SwiftUI.
- Generators take explicit seeds through `SplitMix64`. Grades and reveals must
  describe the same spot and the published policy/chart. Preflop table choices
  use the defend chart; postflop EV uses the disclosed checkdown approximation.
  Do not reveal the correct choice before the user commits.
- Device reinstall policy: every owner-requested reinstall starts with fresh local data. Uninstall the existing app first, then install and verify first-run welcome. Preserve data only when explicitly requested for that reinstall. Do not copy phone progress off-device unless asked.
- The product is offline, with no accounts, analytics, ads, or real-money
  wagering. 1.0 has no purchases; 1.1 plans one one-time unlock (StoreKit, no
  subscriptions, consumables or ads) after Korean business registration, per
  `docs/ROADMAP.md`. Chips never have or buy value. Preserve local progress and
  recovery bytes when changing the `progression.json` schema or persistence flows.
  Any new persisted key, or new meaning for an existing one, bumps
  `ProgressState.currentSchemaVersion`, copies the previous file before upgrading,
  and adds a golden fixture (`docs/adr/0001-versioned-progression-json.md`).
- Korean terminology is canonical in `docs/glossary.md`; use `KO` helpers for
  particles attached to dynamic text. Card-face glyphs stay fixed-size while
  ordinary text follows Dynamic Type. No shrink-to-fit (`minimumScaleFactor`) on
  such text; only dense table parts stop at AX3, via `gtTablePartTextCap` (D54).
- `GlassTableEngine/Tests/GlassTableEngineTests/Fixtures/random_spots.json` is a
  frozen eval7 oracle fixture. Its generator is `tools/gen_fixtures.py`; it is
  not routine build output and should not be hand-edited.
## Agent skills

### Issue tracker

Issues and specs live as local markdown files under `.scratch/<feature-slug>/` while the work is open. See `docs/agents/issue-tracker.md`.

### Triage labels

Default canonical labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Agent handoff

- At session start, read `docs/agent-handoff.md`. Read `docs/records/` only when tracing
  one specific past decision.
- Before ending a session where you made decisions, changed architecture, or left work unfinished:
  rewrite "Current state" so it is true now; add new open issues and remove resolved
  ones; add one short dated entry under "Recent sessions" (what changed, decisions and
  why, next step).
- Keep at most five entries under "Recent sessions" and delete older ones; git history
  is the archive. Do not create archive files. Never delete an unresolved open issue.
- Durable rules belong in AGENTS.md, not in the handoff file.
