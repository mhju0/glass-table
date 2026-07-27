# Glass Table

iOS app that teaches serious-minded amateurs to think about No-Limit Hold'em in **ranges and EV**. Design docs live in `docs/` (`product-brief.md`, `decisions.md`, `open-questions.md`, `risks.md`, `milestone-1.md`); implementation plans in `docs/plans/`.

## Working standard

Baseline behavioral rules for all work in this repo. Everything else in this file
is **additive**: where a project rule is stricter, the stricter rule wins. Nothing
may loosen this baseline.

**Tradeoff:** biases toward caution over speed. For trivial tasks, use judgment.

### 1. Think before coding
**Don't assume. Don't hide confusion. Surface tradeoffs.**
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity first
**Minimum code that solves the problem. Nothing speculative.**
- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical changes
**Touch only what you must. Clean up only your own mess.**
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/variables/functions that YOUR changes made unused; leave
  pre-existing dead code alone unless asked.

The test: every changed line should trace directly to the request.

### 4. Goal-driven execution
**Define success criteria. Loop until verified.**
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan (`1. [Step] → verify: [check]`). Strong
success criteria let you loop independently; weak criteria ("make it work")
require constant clarification.

**Working if:** fewer unnecessary changes in diffs, fewer rewrites from
overcomplication, and clarifying questions arrive before implementation rather
than after mistakes.

## Agent skills

### Issue tracker

Issues and specs live as local markdown files under `.scratch/<feature-slug>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default canonical labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
