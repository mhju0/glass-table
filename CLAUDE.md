# Glass Table

iOS app that teaches serious-minded amateurs to think about No-Limit Hold'em in **ranges and EV**. Start with `CONTEXT.md` (one-page domain orientation). Design docs live in `docs/`: `product-brief.md`, `decisions.md` (§A–§H), `open-questions.md`, `risks.md`, one spec per shipped slice in `docs/specs/`, M1-era plans in `docs/plans/` (historical, like `milestone-1.md`).

Engine changes require the release-config gate (`swift test -c release --package-path GlassTableEngine`). The `.xcodeproj` is XcodeGen-generated, never committed. After UI changes, run `tools/uisweep.sh` and *look at* the screenshots.

## Agent skills

### Issue tracker

Issues and specs live as local markdown files under `.scratch/<feature-slug>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default canonical labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
