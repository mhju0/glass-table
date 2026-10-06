# Approved native UX delivery

2026-10-06 · Native implementation authorized; clean iPhone 12 mini install requested

## Controlling decisions

- All twenty comparisons and five-perspective comments approved. Apply A Focus, date dots and short inline reasons.
- First session: compare a winner, explain the committed answer, then try a new hand. Broader table lessons follow.
- Public summaries acknowledge completion and topic, with no helped/solo split. Preserve internal assistance, grade, mastery and review rules.
- Records leads with actual lesson completions, recorded practice dates and recent topics. Existing accurate deeper reports remain available.
- Today uses a small static amber flame only after a recorded answer on the fourth or later consecutive local date. Gaps are neutral. Free-table play is excluded from these dates for now.
- Best-five explanation appears after commitment; choices stay equally weighted beforehand. Fixed native card artwork remains.

## Scope map

- **D01 First supported hand**: Lead with give up / add 1 / increase; keep Fold / Call / Raise secondary.
- **D02 Probability and plain fractions**: Use 25% = 1 in 4; 33% ≈ 1 in 3 only in a no-tie illustration. Define the actual threshold as equity including shares of ties, not wins alone; keep approximations explicit.
- **D03 Range overlap verdict**: Lead with many hands match; show shared, missing and extra hands before width totals.
- **D04 Shorter staged onboarding**: Start with two hands, a short action explanation and a guided hand; defer occurrence rates.
- **D05 Rank rule versus occurrence**: Compare two examples first. Put rank ordering and occurrence facts in separate optional disclosures.
- **D06 Contextual hint without occlusion**: Reserve a help strip above cards; outline the relevant ownership region and show the next reasoning step.
- **D07 Beginner Progress**: Lead with what was practiced and one recommended retrieval. Expand detailed metrics on request.
- **D08 Completion-led lesson summary**: The later approved decision supersedes the original assisted/solo split. Acknowledge completion and topics without public help-use categories; retain assistance metadata internally.
- **D09 Completed-hand hint state**: Replace inactive hint count with hand review and next-hand actions.
- **D10 Everyday lesson titles**: Use one canonical everyday title with the poker term below, consistently in Learn, lesson and Progress.
- **D11 Blind seats and action order**: Show the button, the small forced amount and the big forced amount, then name the current street’s order.
- **D12 Semantically equivalent level choices**: Use one regular-play meaning across self-report, level chip and dialog. Preserve the current new / rules-known / regular-play meanings and explain effects on suggested lessons, default help and wording; existing progress remains intact.
- **D13 Free play versus graded exercise**: Name free practice: play then review. Name graded exercise: decide then inspect the chart/model.
- **D14 Graded feedback and assumptions**: Lead with chart match/mismatch preflop; show simplified assumptions with the actual graded explanation.
- **D15 Concrete combinations before notation**: Show A♠ A♥ and A♠ A♦ first, then introduce AA and the six unique combinations.
- **D16 One beginner pathway**: Compare hands → count the pot → call or check → guided hand → one independent review.
- **D17 Controls and feedback reachability**: Prototype readable 44 px controls and scrolling feedback; investigate native hit areas before calling this a defect.
- **D18 KO/EN and light/dark parity**: Use semantic surfaces/ink and matching everyday terminology. Keep green felt and paper cards fixed.
- **D19 Keep the calm table**: Retain the visual system; use amber for navigation and selected state, never the correct uncommitted answer.
- **D20 Evidence and report-label honesty**: Show captured / proposed / unverified states separately and keep original flow evidence available. This is report-only clarification, not a proposed app feature.

D03 preserves the currently resolved grader/explanation; improve only presentation if needed. D11/D14/D19 preserve existing correct behavior. D17 flags require actual interaction evidence. D20 is report-only. Research, participant outcomes and award/hiring reactions cannot be manufactured by implementation.

## Data and architecture boundaries

- Foundation-only PracticeActivityOverview derives positive, nonfuture recorded answer dates from eligible daily summary lanes. Do not merge recent evidence or active answers, which would double-count.
- Inject a captured clock/calendar; use calendar-day arithmetic, retain saved DayKey labels, deduplicate modes/languages/formats/assistance, refresh on foreground/day/timezone changes.
- Completed lessons use actual cleared selected lesson IDs, not suggestion eligibility or challenge skipping. Old clears without timestamps remain valid.
- No schema, store, ReviewQueue, Mastery, grading, seed or recovery changes. No new credit for merely viewing help, guided teaching reveals, walkthroughs or free play.
- Existing hinted answers retain their metadata and learning-model semantics. Accuracy and timing eligibility/minimums are not weakened.

## Acceptance evidence

- Compile with local Xcode; run Drills tests, app units and relevant real UI interactions. Engine release gate if Engine changes.
- Inspect compact iPhone normal/AX5 captures in Korean/English and light/dark; repeat selected checks on a larger phone. Normal text uses meaningful concise translations and matched wrapping; AX reflows without shrinking, clipping or in-word breaks.
- Exercise cold start, commitment/reveal/transfer, hints with stable task geometry, miss/all-miss/helped completion, scroll/tap reachability, resume, empty/recent Records, date-four flame and gaps. Test calendar edges, sparse/future imports and duplicate lanes with synthetic data.
- Freeze candidate before independent review; fix findings and reverify. Record passed, failed and unverified gates distinctly.
- Build signed Release 1.0(16), validate bundle, install clean on authorized iPhone 12 mini only. Previous user preference forbids copying phone progress or retaining Mac progress backups. Uninstall/reinstall intentionally clears all prior app data; do not delete or access other apps.
- Confirm installed version and actual first-run screen where possible. Do not imply physical VoiceOver/haptic feel or novice comprehension is established by simulator checks.

## Corrected source observation

The original report incorrectly treated Learn’s title24 as its first text. Suggested-next semibold13 precedes it and matches gtInset semibold13. Preserve that match. Confirm actual first visible roles for Hint title22 and skill title15 before changing their inset parameters.
