# C006 — Obscured replay controls and oversized short hint

User supplied two actual iPhone13mini build16 screenshots, retained under screenshots/ as C006a and C006b. Both English/dark. First: Count the pot, Once more with the hint, action3/6. The Previous/Next row is partially covered by the answer panel; locked choices require following actions to the end. Second: top Hint opens How to work it out with one sentence and a nearly empty full-height presentation.

Record two distinct issues. Overlap is visually confirmed; tap/scroll reachability is not established from a single screenshot. Check native scroll content extent, answer-sheet height measurement, replay/table intrinsic height, header wrapping and whether important controls should have to be discovered by scrolling at all. Scope potentially includes other shared DrillShell activities.

Hint alternatives to compare in final HTML: inline expandable instruction preserving the task context; a compact native content-height bottom sheet that grows/scrolls with Dynamic Type; a compact centered overlay with clear Close, focus restoration and native appearance. Merely centering a sentence in a full-height sheet would not solve oversized presentation. Distinguish top contextual Hint from the longer How to count primer. Preserve replay position and existing answers after help dismissal. Test English/Korean, light/dark, normal/AX5, VoiceOver, Reduce Motion and interactive dismiss.

Initial source locations: ConceptDrillView.swift DrillShell:357–448; PotMath replay:850–898; PotMathLessonView.swift PotMathReplayView; DesignSystem/ContextualHintCue.swift. Read-only background diagnosis is in progress. No native changes during active testing.

## Corrected hint route identification

The screenshot's “How to work it out” title and single sentence match GuidedHintView in NodeSessionView.swift:553 onward. The lesson's top-right Hint button (:353) opens that sheet (:369–370). This is distinct from inline ContextualHintCue and from replay How to count, which opens the longer PotMathIntroView. The initial audit conflated these surfaces; compare compact alternatives for the actual GuidedHintView, not only the multi-section primer. C006 replay layout finding remains: controls are below help, table and action in the scrollable upper area; source implies scrolling can reveal them, but a visible footer or reduced competing height could improve discoverability. Exact device reachability still needs observation.

## Screenshot-backed confirmation

Researcher subsequently inspected both retained JPEGs and confirmed GuidedHintView attribution and the partly clipped Previous/Next row. The normal DrillShell bounded ScrollView is above a separate ActionSheet; the replay's help/table/action/controls stack and TableSurface minimum240pt compete for that viewport. At AX5 the shell uses one complete ScrollView instead. Test the actual reachability after scrolling before calling the buttons inaccessible.
