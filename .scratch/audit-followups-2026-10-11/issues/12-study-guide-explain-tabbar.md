# 12 — Study guide length, empty explanation page, tab bar over content

Type: research
Status: resolved

## Questions and findings (2026-10-12; decided)

Evidence: `evidence/study-guide-pages.jpg`, `evidence/explanation-and-tab-bar.jpg`
(sweep `.uisweep/20261012-020414-meLvB3`, iPhone 17, light, normal text).

### 12a. Study guide

- Eight pages (`LearningGuideView.swift:167-200`), each a title, a paragraph and
  an example box; one page has a question. Pages 1, 6, 7 and 8 are about how to
  study, not poker ("한 번에 한 가지씩 배워요", "좋은 결정도 질 수 있어요", "정답의 조건도
  배워요", "더 깊이 공부하는 순서예요").
- Its header reads "시작 안내 · 1/8" (`LearningGuideView.swift:42`), the same name
  as the opening guide, which is a different thing.
- Pages 2-5 repeat topics that have their own lessons (best five, hand ranks,
  position, pot odds).

Options: (1) cut to the four study-habit pages and rename it (e.g. "공부하는 법" /
"How to study") so it no longer shares the opening guide's name; (2) keep eight
pages, rename only; (3) leave.
Recommendation: 1.

### 12b. Concept explanation page

- The pot-odds explanation shows two short boxes and a "표기 더 보기" row, then
  about half a screen of nothing above "예시 보기".
- Options: (1) show the worked example on this page under the two boxes, and
  drop the separate "예시 보기" step; (2) leave.
Recommendation: 1. Needs a look at `ConceptExplainView` to size properly.

### 12c. Tab bar over content

- The iOS 26 tab bar floats over the page. On the Learn tab the last row
  ("배운 내용 복습") ends directly above it, and scrolled content shows through
  the glass.
- This is the system's standard behaviour for the floating tab bar.
- Options: (1) leave the system behaviour, add bottom space so the last row
  rests clear of the bar when scrolled to the end; (2) force an opaque bar.
Recommendation: 1.

## Comments

## Decision

Decision (owner, 2026-10-12): option 1 for 12a, 12b and 12c.
- 12a: cut the study guide to the four how-to-study pages and rename it so it
  no longer shares the opening guide's name (name proposal: "공부하는 법" /
  "How to study"; not separately confirmed).
- 12b: worked example shown on the explanation page; no separate "예시 보기" step.
- 12c: keep the system tab bar; add bottom space so the last row rests clear.

Owner follow-up (2026-10-12): the arrow sequences in the study guide's example
boxes ("풀이 보기 → 다른 카드로 연습 → 다시 떠올리기") are cut off and wrap badly.
Rewrite them as a friendly numbered list.

Numbered list (wording approved by the owner 2026-10-12, "wording is great";
render in `evidence/study-guide-numbered-list.jpg`):

- Page "한 번에 한 가지씩 배워요" (`LearningGuideView.swift:169`, EN `:208`):
  1. 풀이를 먼저 봐요 / Watch a worked example
  2. 다른 카드로 직접 풀어요 / Try it with new cards
  3. 나중에 다시 떠올려요 / Recall it later
  The second line ("나중에 다시 떠올려 보는 복습도 있어요.") is dropped; step 3 says it.
- Page "더 깊이 공부하는 순서예요" (`:202`, EN `:241`), same treatment:
  1. 기초와 가격 / Price
  2. 포지션과 레인지 / Position and ranges
  3. 보드와 행동 / Board and action
  4. EV 결정 / EV
  5. 핸드 복기 / Review
  The paragraph after it stays as a separate paragraph.
- The third arrow chain (`:172`, order of a hand) is on a page that 12a removes.
- Implementation should give list items a hanging indent so a wrapped item
  lines up under its text at large sizes.

Owner follow-up (2026-10-12): the list was "too tight vertically". Of three
renders (`evidence/study-guide-list-spacing.jpg`: 0, 8, 12 pt extra), the owner
chose "most space", 12 pt. Implement as 12 pt between list items (not as line
spacing inside a wrapped item), with the hanging indent above.
