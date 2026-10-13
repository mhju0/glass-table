# Numerical teaching audit

Baseline07054d0, build 20. See the [full structured findings](../audits/2026-10-11-numerical/findings.json) and [HTML report](../audits/2026-10-11-numerical/index.html).

## N01: Zero EV is called a loss

Both guided languages say a call loses chips at EV = 0; the Korean answer reveal also says 손해. English answer reveal itself is neutral.

Evidence: Pot before bet 20bb; bet/call 10bb; equity 25%: 0.25 × 30 − 0.75 × 10 = 0bb.

Recommendation: Use a third break-even branch: “The call breaks even on average.” / “평균적으로 본전인 콜이에요.” Preserve the EV and grade.

Sources: GlassTableDrills/Sources/GlassTableDrills/Estimation.swift, GlassTableDrills/Sources/GlassTableDrills/Progression/Beats.swift, GlassTableDrills/Sources/GlassTableDrills/Localization/EnglishBeatScript.swift

## N02: Korean PFR explanation changes the denominator

“VPIP … 그중 PFR …%” suggests a share among participating hands, while VPIP and PFR in this model are both shares of all starting hands.

Evidence: Of 100 hands: enter 40, raise 10. PFR is 10% of all hands; raises among entries are 25%. The calling-band gap is 30 percentage points.

Recommendation: “전체 핸드 중 40%로 참여하고, 전체 핸드 중 10%로 레이즈해요.” EN: “Enter 40% of all hands and raise 10% of all hands.” Use dynamic values.

Sources: GlassTableDrills/Sources/GlassTableDrills/Progression/Beats.swift, GlassTableDrills/Sources/GlassTableDrills/Archetype.swift

## N03: An outs lesson can start ahead or tied

The generator accepts a small count of winning rivers as a substitute for checking that the user is currently behind. Its walkthrough then asserts that the opponent leads.

Evidence: Seed 0xA0D17, index 35: Js4h versus 3hJh on 8d2sJcAc. Hero already leads by the 4 versus 3 kicker, yet the spot has 3 winning rivers. In the fixed 1,000-spot probe: 15 ahead and 22 tied. This is a probe rate, not an estimated population rate.

Recommendation: For a “turn it around” lesson, require hero to be strictly behind before accepting a spot. Keep the correct river enumeration. Alternatively explicitly teach winning river cards without asserting a comeback.

Sources: GlassTableDrills/Sources/GlassTableDrills/OutsSpotGenerator.swift, GlassTableDrills/Sources/GlassTableDrills/Progression/Beats.swift, GlassTableDrills/Sources/GlassTableDrills/Localization/EnglishBeatScript.swift

## N04: A tied river is described as losing

Excluded apparent flush cards are every card absent from strict winning outs, including ties. Current explanations say these leave the opponent ahead. Excluding ties from outright winning outs is correct; the reason is wrong.

Evidence: Seed 0xA0D17, index 116: Qc9c versus 2hJd on 4s9sJsKs. River 2s makes both players use the board-only K-high flush: a tie.

Recommendation: Explain each result accurately: “This card ties the hand, so it is not an outright winning out.” / “이 카드는 무승부라서, 이기는 아웃에는 포함되지 않아요.” Separate tie and loss groups.

Sources: GlassTableDrills/Sources/GlassTableDrills/OutsSpotGenerator.swift, GlassTableDrills/Sources/GlassTableDrills/Reveal.swift, GlassTableDrills/Sources/GlassTableDrills/Progression/Beats.swift

## N05: Winning chance is used for tie-inclusive equity

The English Call/Fold reveal labels expected pot share “Winning chance.” The exact calculation correctly includes half of each heads-up tie. This is not strictly the probability of winning outright.

Evidence: If every outcome ties, strict winning probability is 0%, but equity is 50%. The call threshold must compare against equity.

Recommendation: Use “Your share of the pot, including ties” / “무승부 몫을 포함한 팟 지분” or consistently explain equity. Keep the calculation and comparison.

Sources: GlassTableDrills/Sources/GlassTableDrills/CallFold.swift, GlassTableEngine/Sources/GlassTableEngine/Equity.swift

## N06: Review now can precede the due time

The detailed concept subtitle treats a truncated day distance of zero as due now. The review queue correctly checks the exact due timestamp.

Evidence: A due time 6 hours in the future—even tomorrow—can show “review now” while the due count excludes it.

Recommendation: Use due <= now for “review now”; show “later today,” “tomorrow,” or a truthful future date otherwise. Preserve FSRS scheduling.

Sources: GlassTable/Sources/Screens/RecordsView.swift, GlassTableDrills/Sources/GlassTableDrills/Progression/ReviewQueue.swift

## N07: Detailed Day streak can be stale

The detailed Records headline reads the stored streak value. Gaps and silent freezes are resolved only on the next qualifying answer, so an expired current streak can remain positive on screen.

Evidence: A previously earned run can remain displayed after a long inactive gap until the next qualifying activity. The main calendar practice-day overview independently recomputes its values.

Recommendation: Derive the current display using the existing date and freeze rules, or explicitly label the stored historical run. Preserve historical progress; avoid adding punitive messaging.

Sources: GlassTable/Sources/Screens/RecordsView.swift, GlassTableDrills/Sources/GlassTableDrills/Progression/Streak.swift

## N08: Chart targets differ slightly from actual percentages

Whole hand classes are included at a boundary, so a nominal “top 15%” chart actually includes 204/1,326 = 15.3846%. The action chart and grading agree, but unqualified exact width wording overstates precision.

Evidence: RFI widths below show every target, exact count and resulting percentage. All are combo-weighted, not 169-cell-weighted.

Recommendation: Say “about 15%” for target summaries and use the actual chart percent in detailed evidence. Do not change hand membership just to hit an exact target.

Sources: GlassTableEngine/Sources/GlassTableEngine/HandRange.swift, GlassTableDrills/Sources/GlassTableDrills/RFIChart.swift, GlassTableDrills/Sources/GlassTableDrills/RangeDrills.swift, GlassTableDrills/Sources/GlassTableDrills/DefendDrill.swift

## N09: Sample uncertainty needs units and scope

Range advantage says “about ±1% error.” The 8,000-sample calculation has worst-case standard error about 0.559 percentage points, and an approximate 95% margin about 1.096 points. Neither is a guaranteed error bound.

Evidence: Sampling is deterministic for its seed; the result is still a statistical estimate. The confidence statement also depends on accepted sample count and sampling assumptions.

Recommendation: Prefer “Estimated from 8,000 samples.” / “8,000회 표본으로 추정했어요.” If a margin is shown, say percentage points, confidence level and approximation.

Sources: GlassTableEngine/Sources/GlassTableEngine/RangeOnBoard.swift, GlassTableDrills/Sources/GlassTableDrills/BoardDrills.swift

## N10: Chen attribution and half-point variant are not fully sourced

The implementation retains half points for 32 of 169 classes and says “ported verbatim.” A scholarly Chen reproduction returns integers; the original cited book pages were unavailable. This does not prove that the app’s chart strategy is wrong.

Evidence: 97o is 4.5 in this app. Its secondary tie order and position widths are explicit app choices, not a solver result.

Recommendation: Describe an “app-specific Chen-based ranking.” Verify the original book before claiming a verbatim port. Do not silently change scores, rankings or grading.

Sources: GlassTableEngine/Sources/GlassTableEngine/Chen.swift

## N11: Starting-hand percentile uses tie-broken rank

The percentage is the cumulative weighted prefix of the app’s ranking, not the share of all hands with an equal-or-higher Chen score. A source comment currently describes the latter.

Evidence: 22 and A9o both score 5, but display 27% and 34%; all combos scoring at least 5 comprise 40.573%. These are compatible with different secondary ranks, but the definition must be clear.

Recommendation: Use “Top X% in the app’s starting-hand ranking” / “앱의 시작 패 순위에서 상위 X%.” Make the secondary tie rules accessible; keep it distinct from winning probability.

Sources: GlassTableDrills/Sources/GlassTableDrills/PracticeTable/PracticeReplay.swift, GlassTableEngine/Sources/GlassTableEngine/Chen.swift

## N12: Zero-entry ratios and statistical interpretation

Detailed style/Quick Play counts can show 0/0 when no hands were entered. No numeric rate or Wilson interval is computed for zero trials. Fixed-bot intervals are descriptive and do not prove general poker skill.

Evidence: Wilson 40/100: 30.94–49.80%; 28 raises among 40 entries: 54.57–81.93%. These calculations are correct.

Recommendation: Show “No entered hands yet” / “아직 참여한 핸드가 없어요” instead of an unexplained 0/0. Keep the existing bot-rule/skill caveat. Aggregate helped practice remains included, as approved; do not expose a help-status score.

Sources: GlassTableDrills/Sources/GlassTableDrills/PracticeTable/ObservedStyle.swift, GlassTable/Sources/Screens/RecordsView.swift, GlassTable/Sources/Screens/QuickPlayArchiveView.swift