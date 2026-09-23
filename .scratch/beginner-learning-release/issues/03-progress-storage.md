# Preserve progress while adding resumable practice evidence

Status: implemented
Type: task
Original dependency (satisfied): 01 owner approval
Risk: Class 3

Implement the spec's schema-2 atomic snapshot, original-byte migration backup,
idempotent serialized commands, long-term daily summaries, bounded evidence and
resume state. Independent Astra planning and frozen-candidate review required.

Acceptance: schema-1 fixtures preserve totals/tiers/reviews; unsupported/corrupt
imports fail without replacing data; save/retry/duplicate/reset/import/force-quit
tests; old version safe rejection; 8/48 MiB Codable and iPhone memory/latency
measurements; no fabricated historic detail, silent trimming or recovery deletion.

## Delivery, 2026-09-23

Schema 2, atomic save/retry, deep import validation, original-byte migration
backup, bounded recent evidence and durable session state are implemented and
independently reviewed. Release 1.0 (4) was installed in place on iPhone 12 mini:
all nine prior answers, two concepts, one node and streak survived migration;
the original schema-1 copy matched byte for byte and the migrated save survived
relaunch. Physical 8 and 48 MiB capacity probes and their latency/memory results
are in the [delivery record](../../../docs/specs/2026-09-23-beginner-native-release.md).
