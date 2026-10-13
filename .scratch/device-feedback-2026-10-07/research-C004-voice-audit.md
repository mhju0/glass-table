# C004 — User choices and app feedback use different voices

User rule: answer choices can be written from the learner's perspective; feedback should have the app address the learner. The reported “Correct I win” should become “Correct · You win.” Audit the entire app in English and Korean, including accessible labels. Research/proposals only during active testing.

Initial confirmed hotspots: Components.swift VerdictRow.mineName, correctName, answers and accessibilityLabel use My answer and reusable correct values; RiverExplainPanel uses My hand / My hand wins; FirstLessonCopy has My answer, My answer correct/wrong; ConceptDrillView uses I win / Opponent wins / Tie as choices. Choices themselves should not be blindly replaced. Scan call-site formatting to separate the submitted choice from narrative output.

Use present tense for a static card comparison and past tense for a played hand. Keep grade separate from outcome: correctly answering Opponent wins is a correct response despite a losing hand. Korean should sound like a professional coach, not a literal English pronoun translation; avoid introducing 당신 throughout the UI. Keep context-sensitive short labels and consistent feedback structure, linked to C003's alignment issue.

A bounded source audit is running in the background; append concrete findings and preservation decisions when available. No native strings changed for C004.

## App-wide audit findings

Source audit covered GlassTable/Sources and GlassTableDrills/Sources, visible copy and accessibility labels. No native edits.

- Components.swift:176,217–223: shared verdict “My answer” and VoiceOver “same as my answer” → “Your answer” / natural Korean “선택한 답”. For correct results, map outcome “I win” to app-narrated “You win” separately from the quoted submitted choice.
- ConceptDrillView.swift:751–767 and RestoredDrillView.swift:209–216: preserve user-perspective option labels I win / Opponent wins / Tie; use a distinct feedback outcome mapping.
- FirstLessonCopy.swift:47–50,115–121; FirstLessonView.swift:649–675; HoldemBasicsView.swift:210–213: app/VoiceOver labels “My answer, correct/wrong” → “Your answer was correct/incorrect” and “선택한 답, 맞았어요/틀렸어요”. LearningFlowTests.swift:26 pins the old text and would need a contextual update if implemented.
- Components.swift:275–280 RiverExplainPanel: “My hand wins” → “Your hand would win on this river”; keep hypothetical meaning. KO “이 카드가 나오면 내 패가 이겨요.”
- Beats.swift:99–135 / EnglishBeatScript.swift:20–34: English worked-showdown narration already uses Your hand / You win; preserve it. Korean “내가 이겨요” can become “내 패가 이겨요” without literal 당신.
- ConceptDrillView.swift:1974–1975 “Answer · my estimate” → “Answer · your estimate”; RangeGridView.swift:103–105 accessibility “my choice” → “your choice”.
- DefendGridView.swift:112–140,197: compact owned-hand labels are not automatically wrong; narrative/accessibility “My hand” can use “Your hand”. Korean can retain natural “내 핸드” labels.
- RecordsView.swift:411–412: English already says Answers inside your 90% range. Korean can use neutral “예상한 90% 범위 안에 들어온 답의 비율”.

Preserve learner-authored prompts such as How often must I win to call? and How often should I continue? (LearningLanguage.swift:127,153), and first-person answer choices. TableView.swift:569–581 and FreeTableHandCoachView.swift:89 already address the user as You chose; preserve them. No global I/my/내 replacement.

Coordinate with C003: two consistently structured label/value rows can distinguish Your answer from Correct answer without mixing narrator and learner voices. A correct guess that Opponent wins must still receive positive answer feedback.
