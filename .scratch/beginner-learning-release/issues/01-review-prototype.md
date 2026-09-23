# Review beginner language and interaction mocks

Status: needs-info
Type: prototype

Own the browser review build, not native production code. Implement the six flows
in [the spec](../spec.md), use labelled example data, and verify Korean/English,
light/dark, compact widths, large text and keyboard interaction. Record controls,
test results, screenshots and limitations in the prototype README/verification.

Done when the owner has a working preview and evidence sufficient for visual/copy
review. Owner approval is the dependency for tickets 02–06, not implied by tests.

## Comments

- 2026-09-23: implementation started on isolated `codex/beginner-release-review`.
- 2026-09-23: source audit and working bilingual six-flow prototype completed.
  Interaction checkpoints, 192 final layout combinations and 32 contrast pairs
  passed; see [verification](../verification.md) for evidence and limits.
  Awaiting owner visual/copy approval before native implementation (tickets 02–06).
- 2026-09-23: owner approved the overall mock direction and requested shorter
  opponent titles with separate entry/raise scales and three-tab Learn/Play/Progress
  navigation. The revised interaction run passed; 304 layout states and 36 colour
  pairs passed. A final 320px/200% screen verified Start and all three tab labels.
  The owner still reviews this revised mock before tickets 02–06 begin.
- 2026-09-23: owner requested the opponent rows stay fixed. The current mock has
  five vertical rows at every width and a selected-opponent bottom sheet. A
  targeted 72-state matrix, all five selection/dismissal flows and large-text
  sheet scrolling passed; see [verification](../verification.md).
