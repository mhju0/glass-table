# 10 — Opening guide: rule printed above each question

Type: research
Status: resolved

## Question

Each of the five comparison questions prints the rule it is about directly
above the question. Does that give the answer away, and should it change?

## Answer (findings, 2026-10-12; decided)

- By design each comparison introduces one new rule and asks the learner to
  apply it at once: pair over no pair, higher pair, trips, straight, flush
  (`FirstLessonView.swift:887-893` titles, `:896-914` rule text). A newcomer
  could not answer without the rule, so this is teach-then-apply, not a test.
  It does not name the winning hand, so it does not break the "no answer before
  commit" rule.
- The rules grow from two sentences to four. Flush reads: "같은 무늬 5장이면
  플러시예요. 숫자가 이어질 필요는 없어요. 플러시는 스트레이트보다 강해요. 7장 중 가장 좋은
  5장을 찾아보세요." The later ones mix the rule with side facts (ace can be low,
  "look at your cards with the shared cards").
- The title already names the pattern ("같은 무늬 다섯 장"), so title + rule say it
  twice before the cards appear.

Options:

1. Keep the rule above the question, capped at two short sentences: what the
   hand is, and what it beats. Move side facts (ace low, best five of seven)
   into the explanation shown after answering.
2. Show only the title before answering; show the full rule after answering.
   Turns the later comparisons into guesses for a true beginner.
3. Leave as is.

Recommendation: option 1.

## Comments

## Decision

Decision (owner, 2026-10-12): option 1. Rule stays above the question, capped at
two short sentences; side facts move to the after-answer explanation.

Copy approved by the owner 2026-10-12, except Higher pair, which they asked to
change because it listed only A, K, Q, J, 10 and not the remaining ranks. The new
Higher pair wording below was shown to the owner, who replied "option 1" to the
whole message; treated as approved:

| Rule | Korean | English | Moves to after-answer |
|---|---|---|---|
| Pair over no pair | 숫자나 글자가 같은 두 장이 페어예요. 페어는 한 쌍이 없는 패보다 강해요. | Two matching numbers or letters make a pair. A pair beats a hand with no pair. | (unchanged) |
| Higher pair | 둘 다 페어이면 높은 페어가 이겨요. A가 가장 높고, K, Q, J, 10, 9부터 2까지 차례로 낮아져요. | When both hands have a pair, the higher pair wins. Ace is highest, then K, Q, J, 10, 9 and so on down to 2. | (nothing) |
| Trips | 같은 숫자 3장이면 트리플이에요. 트리플은 원페어와 투페어보다 강해요. | Three cards of one rank make three of a kind, or trips. Trips beat one pair and two pair. | Look at your cards together with the shared cards |
| Straight | 숫자가 이어지는 5장이면 스트레이트예요. 스트레이트는 트리플보다 강해요. | Five consecutive ranks make a straight. A straight beats trips. | Suits can differ; ace can be low in A-2-3-4-5 |
| Flush | 같은 무늬 5장이면 플러시예요. 플러시는 스트레이트보다 강해요. | Five cards of one suit make a flush. A flush beats a straight. | Ranks need not be consecutive; best five of seven |
