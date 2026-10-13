# 13 — Store screenshots

Type: research
Status: resolved

## Question

Are the App Store screenshots current, and what should the set be?

## Answer (findings, 2026-10-12; decided)

Evidence: `evidence/store-screenshots-current-set.jpg` (the committed set),
`evidence/store-screenshots-proposed-1.jpg` and `-2.jpg` (today's screens,
Korean, light, sweep `.uisweep/20261012-021925-7n3MVI`).

- The committed set is `docs/store-assets/ko-0[1-5]-*.png`, five 1320×2868
  images last captured 2026-08-07 (`2ef48da`). They show the old four-tab app
  (길 / 오늘 / 테이블 / 기록) in the dark green theme. The app now has
  배우기 / 플레이 / 기록 / 설정 and a light default look, so none of the five
  matches a screen a buyer would see.
- `docs/submission.md:178-199` already says the August set must be replaced
  before submission and that the new set should show Learn, Play, Progress, an
  open lesson and a four-seat review. `CONTEXT.md:143` still calls the set
  "current as of 2026-08-07", which is out of date.
- Only Korean files exist; the August set was reused for both locales.
  `docs/ROADMAP.md:104` asks for new 6.9-inch screenshots in Korean and English.
- The images are raw frames with no caption layer (`docs/submission.md:197`).
- Several screens in the proposed set change in the final pass (graded table on
  felt, free-table dock, lesson help row), so capturing now would be redone.
- Nothing has been submitted; store submission is paused (`CONTEXT.md:142`).

Proposed set, in order: 1 Learn, 2 a lesson question, 3 playing a hand,
4 hand review, 5 Progress. Spare: graded table answer.

Options:

1. Retake after the final implementation pass: the five screens above, Korean
   and English, 6.9-inch (iPhone 17 Pro Max simulator), raw frames, light
   appearance. Replace `docs/store-assets/`, fix the stale line in `CONTEXT.md`
   and the recipe in `docs/submission.md`.
2. As 1, plus a caption line above each frame (marketing-style).
3. Leave until submission resumes; only correct the stale `CONTEXT.md` line now.

Recommendation: option 1.

## Decision

Decision (owner, 2026-10-12): option 1. Retake after the final pass: Learn, a lesson question, playing a hand, hand review, Progress; Korean and English; 6.9-inch; raw frames; light appearance. Replace `docs/store-assets/`, correct `CONTEXT.md:143` and the recipe in `docs/submission.md`. Order not objected to.

## Comments
