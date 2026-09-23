# Preserve progress while adding resumable practice evidence

Status: needs-info
Type: task
Blocked by: 01 owner approval
Risk: Class 3

Implement the spec's schema-2 atomic snapshot, original-byte migration backup,
idempotent serialized commands, long-term daily summaries, bounded evidence and
resume state. Independent Astra planning and frozen-candidate review required.

Acceptance: schema-1 fixtures preserve totals/tiers/reviews; unsupported/corrupt
imports fail without replacing data; save/retry/duplicate/reset/import/force-quit
tests; old version safe rejection; 8/48 MiB Codable and iPhone memory/latency
measurements; no fabricated historic detail, silent trimming or recovery deletion.
