# Play home with mode cards and per-seat setup

Status: done
Type: task

Play home: one-line headline, "자유 대전" and "1:1 채점 연습" cards low on the
screen. Setup: one row per computer with a style chip (default: three different
styles), stakes line, start button at the bottom. Details (bars, VPIP/PFR)
behind "스타일 자세히 보기". Four seats only. The saved table format already
stores three styles, so no schema change is needed.

## Outcome (2026-09-25)

- `PlayView` home: headline plus two `TapCardLabel` cards pinned low (`play-free`
  is the emphasized card, `play-graded` pushes `TableView`). The graded card also sits
  at the bottom of an active table.
- `TableSetupView`: three seat rows with a native `Menu` style chip
  (`seat-style-1…3`), default 신중형 / 콜 위주형 / 공격형, a style guide sheet
  (`style-guide`), and `table-start` at the bottom.
- Table seats and the hand review name each computer's style ("컴퓨터 2 · 공격형").
- "다른 상대 고르기" became the bordered "테이블 바꾸기" button.
- Tests: `testPlayHomeOffersTwoModesAboveTheTabBar` and
  `testTableSetupGivesEachComputerItsOwnStyle` replace the old opponent-list test.
