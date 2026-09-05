# Claude environment inventory — ARCHIVE

Captured 2026-09-04, at the point of moving this project off Claude Code.

**This is an archive, not a migration target.** Nothing here should be converted into
Codex configuration. Its purpose is so capabilities can be *selectively* rebuilt later,
if and only if their absence is actually felt.

**No secret values appear in this document.** Where credentials exist, only the fact and
the location are recorded. Variable *names* are recorded; values are not.

## Classification

| Class | Meaning |
|---|---|
| **PROJECT-CRITICAL** | Contains knowledge about *the project* that is not recoverable from the repo. Losing it loses something real. |
| **USEFUL-BUT-OPTIONAL** | Genuinely helped, but a competent agent works fine without it. |
| **CLAUDE-SPECIFIC** | Exists to make Claude Code behave; carries no project knowledge. **Do not rebuild.** |
| **LIKELY-OBSOLETE** | Stale, superseded, empty, or broken. |
| **UNKNOWN** | Present but its relevance to this project could not be established. |

**Headline finding:** exactly **two** items are PROJECT-CRITICAL — the per-project memory
files and the repo's own `docs/agents/` conventions. Everything else is either harness
behaviour or already duplicated in the repo. The memory files have been mined into
`PROJECT_HANDOFF.md`, `decisions.md` and `ROADMAP.md`, so after this handoff even they
are archival.

---

## 1. Instruction files

### 1.1 Global user instructions — `~/.claude/CLAUDE.md`
**Scope:** global (all projects) · **Class: CLAUDE-SPECIFIC**, with two exceptions noted below.

3.6 KB of working standards, loaded into every session. Contents, summarised:

| Section | Substance | Assessment |
|---|---|---|
| *Delivering work* | Only what was asked; no speculative abstractions; touch only what the change requires; match existing style; remove orphaned imports but leave pre-existing dead code alone; stop and report if scope expands | **CLAUDE-SPECIFIC.** Standard modern-model behaviour; the 2026 generation does this without being told. Do not port. |
| *Evidence & claims* | Tag factual claims `[Verified]` / `[Inferred]` / `[Unknown]`; never assert a file or symbol exists without reading it | **USEFUL-BUT-OPTIONAL.** This one demonstrably shaped the repo's documentation voice — the specs and commit messages cite measured numbers rather than assertions. Worth keeping as a *habit*, not as a config file. |
| *Verification* | Define the success check before coding; bug fix → failing test first; refactor → green before and after; regression tests must genuinely discriminate (never assert on incidental behaviour like DB insertion order); read-only investigations never modify code or git state | **USEFUL-BUT-OPTIONAL**, and this repo *lived* it — see `decisions.md` D39, the byte-diff method for behaviour-preserving refactors. |
| *Long tasks* | Commit at each verified checkpoint | CLAUDE-SPECIFIC. |
| *Git — secrets* | Never commit `.env`, keys, tokens; a committed local-dev default or an intentionally published demo account is not a secret — mention once and continue | CLAUDE-SPECIFIC (good hygiene, universally expected). |
| *Git — committing* | **`git add .` 금지** — always explicit paths; commit without asking only when the task is complete and gates pass; one commit per coherent task; **Conventional Commits, English**; when handing the user commands, put `git add` + `git commit` in one block with real paths and a real message | **USEFUL-BUT-OPTIONAL.** The Conventional Commits rule is honoured by 149 of 155 commits — the exceptions are four merges and two early "Remove …" commits. Worth stating once to any new agent. |
| *Git — pushing* | Push only to a feature branch created this session; **never push to `main`/`master`**; never `--force`; never `git reset --hard` unless asked | CLAUDE-SPECIFIC. Note: history shows direct commits to `main` throughout, so the rule was interpreted as "don't push *unreviewed* to main," or was overridden per-session. |
| *Licensing* | **No default license.** Never add/replace/remove `LICENSE`, never set a `license` field, unless asked. Never raise licensing unprompted — whatever a repo declares is intentional, not a gap. When asked: `Copyright (c) 2026 Michael Ju (github.com/<handle>)`, handle from the `origin` remote | ⚠️ **PROJECT-RELEVANT.** This rule is *why* `glass-table` is public with no LICENSE file and why every source file carries the `// Copyright (c) 2026 Michael Ju (github.com/mhju0)` header. A new agent that "helpfully" adds an MIT license would be reversing a deliberate decision (`decisions.md` D18). **Carry this fact forward; it is now recorded in `decisions.md`.** |
| *Repo context notes* | Names two **other** repos: `mammacare` (shared, non-solely-owned, `github.com/kehdgus96` — licensing not ours to set) and `mammacare-archive` (local backup, not canonical) | **Not relevant to glass-table.** Recorded only so it is clear the global file talks about other projects too. |

**History:** `~/.claude/CLAUDE.md.bak` (7.3 KB, 2026-08-02) and `.proposed` (3.3 KB) show
the file was trimmed. A 50-line version of this baseline was once **inlined into the
repo's own `CLAUDE.md`** (`540de45`, 2026-07-27) and then **removed** (`b3907b6`,
2026-08-02) — a deliberate decision that agent-behaviour rules do not belong in the
project. That decision agrees with the clean-slate principle of this handoff.

### 1.2 Project instructions — `CLAUDE.md` (in repo, tracked)
**Scope:** project · **Class: mixed — split it.**

Only 1 KB, and it divides cleanly:

- **PROJECT-CRITICAL (keep, and already carried into `PROJECT_HANDOFF.md`):**
  - "Start with `CONTEXT.md`" and the map of what lives in `docs/`.
  - **"Engine changes require the release-config gate (`swift test -c release --package-path GlassTableEngine`)."**
  - **"The `.xcodeproj` is XcodeGen-generated, never committed."**
  - **"After UI changes, run `tools/uisweep.sh` and *look at* the screenshots."**
- **CLAUDE-SPECIFIC (the "Agent skills" section):** three subsections pointing at
  `docs/agents/*.md` — issue tracker, triage labels, domain docs. These exist to configure
  a specific set of installed skills (see §4.1). They describe *conventions*, not project
  facts.

### 1.3 `CONTEXT.md` (in repo, tracked)
**Scope:** project · **Class: PROJECT-CRITICAL**

Nominally created for an agent skill (`docs/agents/domain.md` prescribes the
`CONTEXT.md` + `docs/adr/` layout), but its **content is pure project knowledge**: the
module table with test posture, the canonical vocabulary (Concept / node / boss /
estimation concept / archetype / checkdown model / EV-loss grade / defend chart), and the
"conventions that bite" list. **Keep it regardless of toolchain.** Note that the
`docs/adr/` directory the skill expects **was never created** — decisions live in
`docs/decisions.md` instead.

### 1.4 `docs/agents/` — three tracked files
**Scope:** project · **Class: mixed**

| File | Purpose | Class |
|---|---|---|
| `issue-tracker.md` | Declares that issues/specs live as markdown under `.scratch/<feature-slug>/`, with `spec.md`, numbered issue files, `Status:` lines, and a `/wayfinder` map/child-ticket protocol | **PROJECT-CRITICAL (partly).** The *convention* is Claude-skill configuration, but the **fact that specs live in `.scratch/`** is real and non-obvious — two shipped specs are there and nowhere else. |
| `triage-labels.md` | Maps five canonical roles to this repo's GitHub labels (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`) | **LIKELY-OBSOLETE.** The labels exist on GitHub; **zero issues have ever been filed**, so the mapping has never been exercised. |
| `domain.md` | Tells skills to read `CONTEXT.md` / `CONTEXT-MAP.md` / `docs/adr/` before exploring, use the glossary's vocabulary, and flag ADR conflicts | **CLAUDE-SPECIFIC**, and partly counterfactual — it describes a `docs/adr/` layout this repo never adopted. |

---

## 2. Settings

### 2.1 `~/.claude/settings.json` (34 KB) — global
**Class: CLAUDE-SPECIFIC** in its entirety. Recorded for completeness.

| Key | Value | Note |
|---|---|---|
| `model` | `opus[1m]` | 1M-context Opus as the default model |
| `effortLevel` | `medium` | with per-model overrides in `modelSettings` (`claude-opus-5: low`, `claude-fable-5: medium`, `claude-fable-5-1: low`) |
| `includeCoAuthoredBy` | `false` | **PROJECT-VISIBLE EFFECT:** this is why no commit in the repo carries a `Co-Authored-By: Claude` trailer. The 155-commit history reads as single-author by configuration, not by fact. |
| `hooks` | 12 event types, all delegating to one external script | see §5 |
| `statusLine` | command type, delegating to the same external system | see §5 |
| `enabledPlugins` | `mattpocock-skills@claude-plugins-official`, `github@claude-plugins-official` | see §4 |
| `extraKnownMarketplaces` | `karpathy-skills`, `ponytail`, `skill-usage-counter-marketplace`, `anthropic-agent-skills` | see §4.3 |
| `autoCompactWindow` | `300000` | |
| `tui` | `fullscreen` | |
| `autoMemoryEnabled` | `true` | **the switch that produced §6** |
| `skipDangerousModePermissionPrompt` | `true` | bypass-permissions mode runs without the confirmation prompt |
| `skipWorkflowUsageWarning` | `true` | |
| `agentPushNotifEnabled` | `true` | |
| `autoMode` | an `environment` block describing org/cloud/repo-visibility defaults as "None configured" | |
| **`env`** | **empty** | **No environment variables are configured at all** — there are none to carry over. |

Backups present: `settings.json.bak` (2026-08-30), `.bak.prehookremove`, `.bak2`.

### 2.2 `~/.claude/settings.local.json` — global, machine-local
**Class: CLAUDE-SPECIFIC**

- `permissions.allow`: five Bash patterns (`rtk proxy *`, `echo "EXIT: $?"`, `mount`,
  `npx skills *`, `node *`). None project-related.
- `skillOverrides`: `code-review: off`, and four `higgsfield-*` skills off.
- `enabledPlugins`: `skill-usage-counter@…: false` (installed but disabled).

### 2.3 `.claude/settings.local.json` — **in this repo**, gitignored
**Class: USEFUL-BUT-OPTIONAL — but its *contents are a research record.***

A permission allowlist of ten entries. The permissions themselves are worthless outside
Claude Code, but **three of them document where the project's research came from**:

- `WebFetch(domain:www.grac.or.kr)` — the Korean Game Rating and Administration Committee.
  Corroborates that the GRAC rating analysis in `risks.md` / `decisions.md` D10 was done
  against the primary source.
- `WebFetch(domain:namu.wiki)` — one of the three Korean-usage sources named in the
  terminology decision (`decisions.md` D17).
- `WebFetch(domain:toss.im)` — **the design reference for the original visual system**
  ("Toss-inspired design system", commit `8d59189`), which `decisions.md` D34 generation 1
  describes. Nothing else in the repo names Toss as the source.

Other entries are innocuous (`swift --version`, `git status --short`, a `plutil` read of
`Info.plist`, an `eval7` import check). **Salvage the three URLs as provenance, discard
the file.**

### 2.4 `.claude/scheduled_tasks.lock` — in repo, gitignored
**Class: LIKELY-OBSOLETE.** A stale lock from a session on 2026-08-03 (pid 48926). Safe to
delete.

---

## 3. Slash commands
**None exist.** No `~/.claude/commands/`, no `.claude/commands/`. Nothing to inventory or
rebuild. `[Verified]`

## 3b. Subagents / custom agents
**None exist.** `~/.claude/agents/` is empty; there is no `.claude/agents/` in the repo.
The agent *types* available in a session (Explore, Plan, general-purpose, etc.) are
built-in, not configured. `[Verified]`

---

## 4. Skills and plugins

### 4.1 `mattpocock-skills@claude-plugins-official` v1.2.3 — **enabled**, user scope
**Class: CLAUDE-SPECIFIC (the skills) / PROJECT-CRITICAL (one side-effect)**

Installed 2026-08-06. Provides: `diagnosing-bugs`, `tdd`, `prototype`, `research`,
`domain-modeling`, `codebase-design`, `code-review`, `resolving-merge-conflicts`,
`wizard`, `grilling`, `writing-for-agents`.

- **This is the plugin `docs/agents/*.md` exists to configure** — those three files are its
  required repo-side adapters (issue tracker location, triage labels, domain-doc layout).
- **Its lasting effect on the repo is `CONTEXT.md`** (created by the `domain-modeling`
  convention) and the `.scratch/<slug>/spec.md` layout. Both survive the plugin's removal
  and are worth keeping on their own merits.
- Note the timing: installed **2026-08-06**, i.e. *after* the revamp shipped. It did not
  shape the bulk of the work.

### 4.2 `github@claude-plugins-official` — **enabled**, user scope
**Class: LIKELY-OBSOLETE (broken)**

Provides an MCP server for GitHub. **It failed to connect in this session** with
`400: "Error POSTing to endpoint: bad request: Authorization header is badly formatted"`.
The project never depended on it — all GitHub work in this audit and in the history was
done through the **`gh` CLI**, which is authenticated independently (account `mhju0`, via
keyring; token not recorded here). If a GitHub capability is wanted under a new toolchain,
`gh` is the dependency, not this plugin.

### 4.3 Marketplaces registered
**Class: CLAUDE-SPECIFIC**

`claude-plugins-official` (anthropics), `anthropic-agent-skills` (anthropics/skills),
`karpathy-skills` (forrestchang/andrej-karpathy-skills), `ponytail` (DietrichGebert/ponytail),
`skill-usage-counter-marketplace` (landicefu/skill-usage-counter).

`~/.claude/plugins/data/` also holds residue for `superpowers`, `security-guidance`,
`swift-lsp` and `ponytail` — plugins that were installed at some point but do **not** appear
in `installed_plugins.json` today. **LIKELY-OBSOLETE.**

### 4.4 `ponytail` — ⚠️ **its convention leaked into the source code**
**Class: PROJECT-CRITICAL (the convention) / LIKELY-OBSOLETE (the plugin)**

A "lazy senior dev" skill whose thesis is a ladder — *does this need building at all →
does it already exist here → does the stdlib do it → … → only then write the minimum code*
— with rules like "deletion over addition, boring over clever, shortest working diff wins."

**Why it matters after the migration:** three shipped source files carry `// ponytail:`
comments:

- `GlassTableEngine/Sources/GlassTableEngine/HandEvaluator.swift:2` — "naive 5-card
  classifier taken best-of-7 in evaluate7"
- `GlassTableDrills/Sources/GlassTableDrills/OutsSpotGenerator.swift:27`
- `GlassTableDrills/Sources/GlassTableDrills/CallFold.swift:35`

…plus three in `docs/plans/`. In this repo the marker means **"this is deliberately the
simple version, and here is the measurement that says simple is enough."** A new agent
seeing `// ponytail:` with no context may read it as a stray tag and either delete it or
"fix" the naive implementation. **The meaning is now recorded in `decisions.md` D06.**
Keep the comments; the plugin itself is not installed and need not be.

### 4.5 `skill-usage-counter@skill-usage-counter-marketplace` v1.0.1
**Class: CLAUDE-SPECIFIC.** Installed at local scope for `/Users/michaelju`, then
**disabled** in `settings.local.json`. Telemetry about skill usage. Irrelevant.

### 4.6 User-level skills in `~/.claude/skills/`
**Class: CLAUDE-SPECIFIC**

| Skill | Kind | Relevance here |
|---|---|---|
| `ui-ux-pro-max` | Real directory with `SKILL.md`, `scripts/`, `data/`. A searchable design database (67 styles, 161 palettes, 57 font pairings, 21 stacks incl. SwiftUI) | **UNKNOWN.** Plausibly consulted during UI work, but the repo's visual decisions (`decisions.md` D34–D37) were all driven by *measured contrast ratios off real screenshots*, not by a style database. No trace of it in the repo. |
| `orca-cli` | **symlink** → `~/.agents/skills/orca-cli` | CLAUDE-SPECIFIC; part of the Orca system (§5) |
| `orchestration` | **symlink** → `~/.agents/skills/orchestration` | CLAUDE-SPECIFIC |
| `computer-use` | **symlink** → `~/.agents/skills/computer-use` | CLAUDE-SPECIFIC. Relevant footnote: agent memory records that **synthetic clicks (orca computer, CGEvent) never reach the iOS Simulator's content**, which is *why* `tools/uisweep.sh` drives everything through `GT_DEMO_*` launch hooks instead. That finding is now in `PROJECT_HANDOFF.md` §17. |

---

## 5. Hooks, status line, and the Orca layer

**Class: CLAUDE-SPECIFIC. Do not rebuild.**

All **12** hook events — `UserPromptSubmit`, `Stop`, `StopFailure`, `SubagentStart`,
`SubagentStop`, `TeammateIdle`, `PreToolUse` (`*`), `PostToolUse` (`*`),
`PostToolUseFailure` (`*`), `PermissionRequest` (`*`), `SessionStart`, `PostCompact` — are
wired to a **single external dispatcher**, `~/.orca/agent-hooks/claude-hook.sh`, guarded by
cross-platform shell shims. The status line likewise calls
`~/.orca/agent-hooks/claude-statusline.sh`.

`~/.orca/agent-hooks/` contains equivalent hook scripts for **thirteen** different agents
(`codex-hook.sh`, `cursor-hook.sh`, `copilot-hook.sh`, `gemini-hook.sh`, `grok-hook.sh`,
`devin-hook.sh`, `droid-hook.sh`, `kimi-hook.sh`, `antigravity-hook.sh`,
`command-code-hook.sh`, `openclaude-hook.sh`, …). **This is a vendor-neutral observability
layer, not a Claude feature** — note that `codex-hook.sh` already exists, so this system
likely survives the migration on its own without anything being ported.

**No project-specific hook exists.** No hook enforces anything about Glass Table — not the
engine gate, not the uisweep, not the commit format. Those were held by instructions and
by CI, never by automation.

`~/.claude/hooks.disabled/` holds a retired `rtk-rewrite.sh`. **LIKELY-OBSOLETE.**

---

## 6. MCP servers

**Class: CLAUDE-SPECIFIC.** No project-scoped MCP configuration exists — there is no
`.mcp.json` in the repo, and this project's entry in `~/.claude.json` has
`mcpServers: {}`, `enabledMcpjsonServers: []`, `allowedTools: []`. **Glass Table used no
MCP server for anything.** `[Verified]`

Configured globally in `~/.claude/.claude.json` (all stdio commands, no URLs, no
credentials in the file):

| Server | Command | Purpose | Relies on this project? |
|---|---|---|---|
| `headroom` | `headroom mcp serve` | UNKNOWN | No |
| `serena` | `uvx --from git+https://github.com/oraios/serena serena start-mcp-server --project-from-cwd --context claude-code` | Semantic code navigation/editing toolkit | No trace in the repo |
| `tokensave` | `~/.local/bin/tokensave serve` | UNKNOWN (context/token management) | No |

Additionally available in a session via account-level connectors, none of them used by
this project: Gmail, Google Calendar, Google Drive, Notion, and `claude-in-chrome`
(browser automation). Plus the broken `github` plugin server (§4.2).

---

## 7. Persistent memory — ⚠️ **the one genuinely PROJECT-CRITICAL store**

**Location:** `~/.claude/projects/-Users-michaelju-Workspace-Projects-glass-table/memory/`
**Scope:** project · **Class: PROJECT-CRITICAL** · Enabled by `autoMemoryEnabled: true`.

Six files: an index (`MEMORY.md`) plus five memories. **This is the only place several
facts about the project existed at all.** All of it has been mined into
`PROJECT_HANDOFF.md`, `decisions.md` and `ROADMAP.md` as part of this handoff — the
originals are now redundant, but they are the audit trail.

| Memory | What it held | Where it went | Accuracy today |
|---|---|---|---|
| `engine-test-gate-release.md` | Run engine tests with `-c release`; debug ~10× slower; oracle test alone ~250 s; the `ponytail:`-flagged naive evaluator; the exact `eval7` API quirk (`py_hand_vs_range_exact` is unreliable, returns 0/1 sentinels) | Handoff §9, §12; `decisions.md` D05, D06 | **Accurate**, though the timings predate the 2026-08-08 optimisation (full suite is now ~128 s, not ~5 min) |
| `app-build-workflow.md` | XcodeGen workflow; bundle ID; **device deploy via a personal-team `DEVELOPMENT_TEAM` ID with free 7-day provisioning**; the full M1-era `GT_DEMO_*` hook catalogue; a **zsh gotcha** — `env $vars cmd` does not word-split an unquoted variable, so each `SIMCTL_CHILD_*` assignment must be its own argument or the hook silently never applies | Handoff §8–§10, §17 | ⚠️ **Substantially stale.** Its hook catalogue describes M1 (`GT_DEMO_DRILL=outs\|potodds\|mdf\|callfold\|blockers`, `GT_DEMO_FIRSTHAND`, `GT_DEMO_FH_STEP`) — those screens **no longer exist**. It also describes the deleted Toss-style "green zone + white sheet" design system. The XcodeGen recipe, the bundle ID, the device-deploy path and the zsh gotcha remain correct. |
| `m1-roadmap.md` | M1 sub-project order; the **paused-for-dogfood decision and its conditions**; the revamp summary; deferred items; the submission landmine | `ROADMAP.md`, `decisions.md` D23, D32 | ⚠️ **One outright error:** it states the `wiring/completeness-pass` branch was "UNMERGED, awaiting owner merge." Git shows it merged as `5e8b73e` on 2026-08-06. |
| `behaviour-preserving-change-verification.md` | The byte-diff method for proving a refactor changed nothing; the uisweep pixel-diff caveat (`GT_SIM` size mismatch across folders; `teach-showdown-b3/b5` differ 0.05–0.24 % on an unchanged build) | `decisions.md` D39; Handoff §13 | **Accurate and valuable.** This is the single most transferable technique in the store. |
| `mdf-parked-deliberately.md` | MDF's parked state is a resolved decision, not an oversight; why (frequency-half only); that the gate is now open; that it is a full slice, not a node fix; **and that this was misread as a gap once already, on 2026-08-10** | `decisions.md` D32; `ROADMAP.md` NEXT | **Accurate.** Written specifically to stop a recurring mistake. |

**Two conclusions worth carrying:** (1) memory captured real, non-recoverable decisions —
the pause conditions, the YAGNI skips, the misreadings-to-avoid; (2) **memory also went
stale silently**, and nothing reconciled it against git. A new toolchain should prefer
putting this class of knowledge *in the repo* (which is what this handoff does).

---

## 8. In-repo agent residue

| Path | What it is | Class |
|---|---|---|
| `.superpowers/sdd/` | 23 files from a spec-driven-development harness used for the **M1 submission sub-project (2026-07-23)**: six task briefs, six task reports, seven review diffs, and `progress.md`. `progress.md` records that Tasks 1–6 completed, the repo was made public, and Pages was verified serving the policy with HTTP 200 | **LIKELY-OBSOLETE.** Gitignored. The outcomes are already in `docs/plans/2026-07-23-m1-submission.md` and in git. Archive or delete. |
| `.superpowers/brainstorm/` | Four HTTP-served brainstorm sessions (2026-07-22 → 08-04) with **19 HTML mockups** — `outs-layout*.html`, `outs-toss-redesign.html`, `felt-tone.html`, `visual-tone.html`, `teach-pattern.html`, `home-layout.html`, `microsteps.html`, `records.html`, `sheet-directions.html`, `hybrid-warmth.html`, `r3-painting.html`, `design-recap.html` | **UNKNOWN → worth one look before deleting.** These are the *visual* alternatives considered before the shipped design, including `r3-painting.html` — a mockup of the **정확히 칠하기** paint input that is still on the LATER list. Nothing else in the repo shows what was tried and rejected visually. Gitignored, so they are not backed up anywhere. |
| `.scratch/onboarding-first-hand/spec.md` | The 첫 핸드 spec, **including the pedagogy research** (pretesting effect, Duolingo's revealed preference, NN/g's tutorial study) | **PROJECT-CRITICAL.** The feature was deleted; the research that justified deleting *documents* in favour of *in-context explanation* is still the app's teaching philosophy. Now summarised in `decisions.md` D20. |
| `.scratch/outs-reveal-legibility/spec.md` | The card-legibility + tap-to-explain spec | **USEFUL-BUT-OPTIONAL.** Shipped 2026-07-24; describes the `HandBrief` engine addition still in use. |
| `~/.claude/projects/…/` (sessions, `history.jsonl`, `telemetry/`, `security/`, `jobs/`, `shell-snapshots/`, `paste-cache/`, `file-history/`) | Transcripts and machine state | **CLAUDE-SPECIFIC.** Note: `history.jsonl` (1.4 MB) and the session transcripts are the **only remaining record of conversations not captured by memory or the repo.** If any archaeology is ever needed beyond this document, that is where it lives. |

---

## 9. Environment variables

**Claude-side: none.** `env` in `~/.claude/settings.json` is an empty object. Nothing to
carry over. `[Verified]`

**Project-side (owned by the repo, not by Claude — these stay):**
`GT_SIM` (simulator name for `tools/uisweep.sh`, default `iPhone 17`), and the `#if DEBUG`
launch hooks `GT_DEMO_TAB`, `GT_DEMO_NODE`, `GT_DEMO_BEAT`, `GT_DEMO_REVEAL`,
`GT_DEMO_SEED`, `GT_DEMO_FREEPLAY`, `GT_DEMO_REVIEW`, `GT_DEMO_REPLAY`, `GT_DEMO_SETTINGS`,
`GT_DEMO_GLOSSARY`, `GT_DEMO_TABLE` — prefixed `SIMCTL_CHILD_` when passed through
`simctl launch`. These are documented in `PROJECT_HANDOFF.md` §17 and are **not** Claude
configuration.

**Credentials:** the `gh` CLI is authenticated for account `mhju0` through the macOS
keyring. No token, key, or secret value is reproduced in this document, and none was found
committed anywhere in the repo.

---

## 10. Rebuild guidance, if the absence is ever felt

Ranked. Most of this list is "do nothing."

1. **Nothing needs rebuilding to work on this project.** The repo now carries every
   project fact that lived in the harness. `swift test`, `xcodebuild` and
   `tools/uisweep.sh` are the whole workflow.
2. **If commit hygiene drifts:** state once that this repo uses Conventional Commits in
   English, explicit paths (never `git add .`), and no co-author trailers.
3. **If a refactor must provably change no behaviour:** use the byte-diff method in
   `decisions.md` D39. That is the highest-value thing the old environment produced.
4. **If GitHub automation is wanted:** depend on the `gh` CLI, not on an MCP plugin.
5. **Before deleting `.superpowers/brainstorm/`:** skim the 19 HTML mockups. They are
   gitignored, unbacked-up, and are the only record of rejected visual directions.
6. **Do not port:** hooks, the status line, permission allowlists, skill overrides,
   marketplaces, the `docs/agents/` skill adapters, or any behavioural instruction from
   `~/.claude/CLAUDE.md`. A current-generation model does that work without configuration,
   and the clean-slate goal is exactly to stop carrying it.
