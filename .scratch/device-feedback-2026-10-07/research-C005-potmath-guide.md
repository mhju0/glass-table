# C005 — Blinds and a cumulative pot calculation guide

User observations: blind meaning should be explained briefly within the lesson; replacing each equation on a new Next page makes it easy to tap through without retaining the calculation. User wants gradual accumulation, smooth motion, and a final number question/check.

Initial source findings: PotMathLessonView.swift:236–245 already contains a first-use SB/BB introduction and a quick example. Worked-example Beats.swift:207 onward and EnglishBeatScript.swift:88 onward introduce posting blinds before stepwise chip additions; WalkthroughView renders the current beat. The key question is whether the definition arrives before a beginner encounters the abbreviations, and whether the running trail remains visible.

Research only: propose a short context-specific definition before the first contribution row, then one cumulative ledger whose visible prefix grows with Next. Distinguish newly contributed chips from the total bet size to avoid counting chips twice. Keep earlier subtotals visible. Do not disclose the last computed total before the learner answers; the last row can end in an unknown total, or the check can be a separate transfer spot.

Test English/Korean, normal/AX5, both appearances and Reduce Motion; appended-row announcements, scroll reachability, Back, replay/restart, saved beat resume and save-error forward gating. Define SB/BB as required starting contributions in this app/example, not universally fixed 1/2 amounts or universal seating that ignores heads-up rules. Background source research is in progress. No product change during active testing.

## Confirmed source audit

- Beats.swift:203–239 constructs the intro, then SB+BB subtotal, then one before+added=running equation per contributing action. WalkthroughView.swift:302–343 renders only the current beat/detail; earlier equations disappear.
- NodeSessionView.swift:285–301,867–882 presents the worked example before the first-use drill primer (ConceptDrillView.swift:822–848). The definition exists, but arrives after its first use in the worked lesson. How to count can reopen the primer at :898–903.
- WalkthroughView.swift:45–54,304–365 already hides its final beat value behind Tap to check. Preserve this deliberate gate. A cumulative ledger must not expose the exact final answer in its preceding last equation; either reserve the last addition result until the check or use a new transfer question.
- Model PotMathSpot/PotMath.swift:19–28,48–58,150–188 distinguishes newly paid chips from raise-to totals. A raise contributes target minus chips already paid; folding does not remove earlier paid chips. Use model-derived contributions.
- NodeSessionView.swift:292–300,867–875 saves each worked step and restores showBeatIndex. Derive visible row history from the saved index; avoid an ephemeral append array that loses history on resume or duplicates rows after Back/Next.
- WalkthroughView.swift:277–279,338–350 already respects Reduce Motion and GT.Motion.change. Reuse that policy for an appended row, keep the CTA reachable, and avoid forced VoiceOver focus jumps.

Candidate prelude: EN “Blinds are starting contributions posted before the cards are dealt. SB is the small blind; BB is the big blind.” KO “블라인드는 카드를 받기 전 내는 필수 칩이에요. SB는 작은 블라인드, BB는 큰 블라인드예요.” State “In this example, SB is 1 chip and BB is 2”; amounts vary by table. Optional seating explanations need the heads-up dealer/small-blind exception; keep that detail out of the first arithmetic task unless it is relevant. These are proposals, not newly shipped copy.
