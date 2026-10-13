# C014 — Compact help without timed essential instruction

User proposes replacing the large persistent top lightbulb panel with a small popup disappearing in2–3seconds. Goal is reclaiming task space, linked to C006's clipped replay controls and C007/C010's teaching-area layout.

Confirmed source: ContextualHintCue.swift:4–18 renders the full ConceptIntroduction.how sentence in an expanded Label, body15, card insets and panel styling. DrillShell inserts it into the question/content column at ConceptDrillView.swift:381/402 when drillHintConcept is present (:94). This is distinct from top Hint → GuidedHintView, although both serve method support and may duplicate guidance.

Compare compact always-available Hint trigger with content-sized help; optional short reminder popup; first-use essential instruction integrated into the lesson itself. A fixed2–3second auto-hide should not be the only access to unfamiliar concepts. Keep reopening easy, do not steal focus or disclose correct answers, and provide a readable non-timed presentation for VoiceOver/large text. Preserve professional restraint and learner freedom to use help. Optional reminders may be transient; core instructions remain at the learner's pace.

Source/design research is in progress. No native change during active testing.

## Completed cue audit

Guided .together enables showsContextualHint and graded lesson questions pass nonnil help (NodeSessionView.swift:301–310,382–393), so the panel can consume space on repeated questions. Its ConceptIntroduction.how and GuidedHintView.cue overlap for some concepts but differ for others; consolidate deliberately rather than deleting different guidance blindly. Recommended compact/reopenable help retains complete text, answer secrecy and user-paced essential instruction. Optional reminders can be transient. Verify closed/open space, long localized text, draft/scroll preservation, VoiceOver announcement and reduced motion.
