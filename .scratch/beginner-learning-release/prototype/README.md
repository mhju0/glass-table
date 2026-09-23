# Beginner experience review prototype

This is an interactive browser mock for visual and copy review. It does not run the iOS app, grade against `DefendChart`, implement four-player rules, or write progress. Every displayed hand, action, score, time, and style count is a labelled design-review fixture. The selected opponent label appears at Computer 1, but the scripted hand stays fixed.

From the repository root:

```sh
python3 -m http.server 8768 --bind 127.0.0.1
```

Open `http://127.0.0.1:8768/.scratch/beginner-learning-release/prototype/`. The root-relative font path uses the app's bundled Pretendard files. To check fixture and translation-key consistency, run `node .scratch/beginner-learning-release/prototype/verify.cjs`.

Review these flows in Korean and English, light and dark:

1. Learn: open the showdown introduction; start or skip; answer five cards questions; request help; leave via a tab and continue; read the summary; replay the introduction without losing the round.
2. Learn: answer the J5o question before the chart appears. Read the compact result, inspect the 13-by-13 overview, open 44-pixel scrollable cells, select a cell, return to J5o, or read the row text.
3. Play: choose among five short opponent titles. The chosen row alone shows two separate starting-habit scales; technical values and original poker names are optional. Enter the fixed four-seat hand, step forward/back, then inspect the factual review and optional post-hand opponent cards. Its seats are Computer 1/2/3, but the chosen style only changes Computer 1's label, not the scripted actions.
4. Progress: switch between sample, first-visit, loading, and error/retry states. Show answer time only if requested. Inspect the sample style card and its insufficient-evidence state.
5. Open Settings from any activity. Switch System/한국어/English and System/Light/Dark, then close with the button, backdrop, or Escape. The in-memory question, choice, replay position, and report state remain.

The three destinations are Learn, Play and Progress. Learn has one recommended next action. The example switch lets reviewers inspect next-lesson and review-reminder copy; the latter is an explicit fixture, not a real due item. An unfinished introduction or round takes priority over either example. Only two representative skill screens are connected here, so the full curriculum path, review queue and calibration remain planned native work.

Design read: mobile learning interface for adult beginners, with the app's warm paper or charcoal surfaces around a fixed green poker object. Energy 1 / rhythm 2 / motion 1. The cards or chart take the largest area when they are the learning object. Plain explanations lead; technical vocabulary is disclosed when useful. Amber marks a user action, never the correct answer before commitment. Equal-weight answer buttons avoid suggesting the result. The bundled Pretendard font keeps Korean copy familiar; card face glyphs have fixed pixel sizes while ordinary text grows. Cards and table have distinct surfaces because ownership and public information matter to the lesson. The three-tab bottom navigation reserves content clearance. The selected opponent's scales sit directly beneath its row so the user's tap has an immediate visual answer; they represent configured shares of all starting hands on a 0–100% span, not relative skill or observed play.

Proposed style names are review copy, not validated labels. The data threshold and wording need product-owner review before native implementation. The colored card chart is illustrative and explicitly cannot be used as the app's grading policy.
