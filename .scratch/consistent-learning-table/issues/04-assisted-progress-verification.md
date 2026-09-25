# Preserve honest progress when hints reveal calculations

Status: ready-for-agent
Type: task
Blocked by: 01

Risk: Class 3 if native persistent-state or progression semantics change.

Trace lesson, review and free-practice commits. Existing daily evidence has an
assisted field, but commitNodeAnswer currently rejects assisted answers. Design
the integration before adding UI hints; do not silently bypass those invariants.
Assisted work counts as practice, not independent accuracy/mastery/review credit.
Replay alone stays independent; reveal after commitment does not change credit.

Acceptance: preserve the assistance flag through exit/relaunch and retry; avoid
double credit; preserve old progress and raw backups. Involve an independent
read-only Astra review of planning and the frozen implementation candidate before
integration. Verify the final native flow and record device-install evidence only
if device delivery is subsequently in scope.

## Comments

2026-09-24: Owner scheduled this next (with 02, 03 and 04). Unblocked by 01.
