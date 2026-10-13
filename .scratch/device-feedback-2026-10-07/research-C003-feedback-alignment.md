# C003 — Incorrect-answer comparison alignment

Observed from user screenshot on the active iPhone13mini build16 session, English/dark, question2/3. The chosen Tie text stays one line while Correct / Opponent wins wraps; an arrow floats between blocks of different height and typography. The screenshot is retained in screenshots/C003-feedback-alignment.jpeg.

Confirmed source cause: `VerdictRow.answers` in GlassTable/Sources/DesignSystem/Components.swift:232–245 uses `HStack(spacing: 6)` with its default center alignment. Mine label+value is a single GT.body(13) Text; correct label+value is a separate GT.title(15) Text. Line lengths and fonts determine independently where the text wraps. This is a shared verdict component; restored, numeric, chart and graded table reveals can be affected. It is not evidence of a grading error.

Research/proposal only: give both values the same structural treatment. Recommended candidate is two leading-aligned rows, each with a separate label and value using shared column alignment; compact alternatives use equally structured label-above-value columns. Test long English choices, Korean labels, numbers/units, equal versus differing answers, near versus miss, both appearances and normal/AX5 sizes. Avoid fixed heights, forced font shrinking, and a horizontal arrow whose position depends on wrapping. Preserve semantic VoiceOver ordering and encouraging tone.

Final report should show the user's actual before screenshot, annotated source finding, and clearly labeled proposed layouts. No product edits for C003 during the active test session.
