# Glass Table

iOS app that teaches No-Limit Hold'em in ranges and EV. Start with `CONTEXT.md`.
Design docs live in `docs/`: `product-brief.md`, `decisions.md`, `open-questions.md`,
`risks.md`, and delivery specs under `docs/specs/`. M1-era `docs/plans/` are historical.

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
No linter is configured. The screenshot sweep uses debug `GT_DEMO_*` hooks on a
disposable simulator; `GT_SIM` selects a device/runtime by existing simulator name.
`--no-build` reuses only a matching build from a prior sweep in this checkout.
The sweep defaults to normal (`large`) and AX5 text sizes; `GT_CONTENT_SIZE`
selects one size for a focused check. Inspect both sets of affected screenshots
and run relevant UI interactions: an initial frame cannot prove scroll reachability.
Before reopening learner-trust audit findings, read
`docs/specs/2026-09-20-learner-trust-audit.md` for branch scope, resolved claims,
regressions and verification limits. Detailed historical handoff: `docs/PROJECT_HANDOFF.md`.

- `project.yml` owns the generated, gitignored `GlassTable.xcodeproj/` and
  `GlassTable/Info.plist`. Edit the YAML, not those outputs.
- The app depends on both Swift packages; Drills depends on Engine. Keep both
  packages independent of UIKit/SwiftUI.
- Generators take explicit seeds through `SplitMix64`. Grades and reveals must
  describe the same spot and the published policy/chart. Preflop table choices
  use the defend chart; postflop EV uses the disclosed checkdown approximation.
  Do not reveal the correct choice before the user commits.
- The product is offline, with no accounts, analytics, ads, purchases, or
  real-money wagering. Preserve local progress and recovery bytes when changing
  the `progression.json` schema or persistence flows.
- Korean terminology is canonical in `docs/glossary.md`; use `KO` helpers for
  particles attached to dynamic text. Card-face glyphs stay fixed-size while
  ordinary text follows Dynamic Type.
- `GlassTableEngine/Tests/GlassTableEngineTests/Fixtures/random_spots.json` is a
  frozen eval7 oracle fixture. Its generator is `tools/gen_fixtures.py`; it is
  not routine build output and should not be hand-edited.
## Agent skills

### Issue tracker

Issues and specs live as local markdown files under `.scratch/<feature-slug>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default canonical labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Agent handoff

- At session start, read `docs/agent-handoff.md`.
- Before ending a session where you made decisions, changed architecture, or left work unfinished, append a dated entry: what changed, decisions and why, open issues, next step. Keep it brief and append-only.
- When the file exceeds ~200 lines, condense the oldest entries into a short dated summary. Never delete unresolved open issues.
- Durable rules belong in AGENTS.md, not in the handoff file.
