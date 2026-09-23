# Describe observed practice styles with evidence

Status: implemented
Type: task
Original dependencies (satisfied): 01 nickname approval, 03, 05

Implement the five supported styles plus unassigned state and the exact versioned
heuristic in [spec](../spec.md). Show dates, denominators, evidence and one relevant
practice suggestion. Never claim personality, intent, skill or profitability.

Acceptance: interval endpoints, insufficient hands/days/entries, expiry, policy
version changes and recompute thresholds tested; fixtures reconcile every report
number against hands. Counts available before assignment. Friendly names approved
in both languages. Thresholds explicitly identified as product heuristics.

## Delivery, 2026-09-23

Recent four-seat behavior now shows denominators before it can assign a label.
The versioned Wilson-band heuristic uses the current eligible window at each
completed hand and report render, not a 20-hand refresh batch. Its thresholds
are authored product choices. Boundary/insufficient-evidence tests and native
KO/EN views passed; interpretation by real learners remains human acceptance.
See the [delivery record](../../../docs/specs/2026-09-23-beginner-native-release.md).
