# C015 — Distinct feedback labels

User explicitly prefers “Your answer: Raise” and “Correct answer: Fold,” rather than “My answer Raise → Correct Fold.” This reinforces C004's app-to-user voice and C003's inconsistent wrapped comparison layout.

Confirmed shared source: VerdictRow default mineName is My answer / 내 답 and correctName is Correct / 정답 (Components.swift:176–177). answers (:232–245) concatenates each label/value in separate differently styled Text blocks inside a center-aligned HStack. Introduce independent label/value structure and common spacing/alignment, not just a text substitution.

Final report should compare two aligned rows (recommended for variable text lengths and accessibility) with equally structured label-above-value columns at compact normal size. An arrow is optional; it should not force alignment or replace explicit labels. English labels should follow the user's preference. Korean proposal: 선택한 답 / 정답, avoiding literal 당신의 답. Preserve context-specific injected labels for chart/EV policy comparisons: do not imply an app practice policy or approximation is a universally correct poker action. Use unchanged submitted values, separate app-voiced outcome mapping, and accessible reading order.

Test Raise/Fold, Tie/Opponent wins/You win, counts/units, percentages, correct/near/incorrect, long localized values, normal/AX5, both appearances and restored sessions. No product change while phone testing is active.
