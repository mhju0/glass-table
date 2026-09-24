# Consistent table review prototype

Run from the repository root:

```sh
python3 -m http.server 8769 --bind 127.0.0.1
```

Open `http://127.0.0.1:8769/.scratch/consistent-learning-table/prototype/` at a 375 × 812 viewport. The language, appearance, text-size, and design selectors above the simulated phone are review controls, not app UI. Design compares the current table with the refined material treatment; `?design=refined` opens the refined one, and `GT_DESIGN=refined node verify-browser.cjs` verifies it. `compare.html` shows both as synced side-by-side phones. `node audit-lines.cjs` (with `GT_DESIGN`/`GT_SIZE`) checks Korean/English line parity, short last lines and in-word breaks across every scripted state. The activity opens full screen; Exit returns to the four-mode launcher.

This is one scripted, offline HTML/CSS/JS review fixture. It does not run the iOS app, save real learning progress, grade a live game, or validate native persistence. The browser remembers which introductions were visited in local storage. Practice position and answer state survive Exit and reopening within the same loaded page only.

The pot question copies the legal four-seat sequence in `GlassTableDrills/Tests/GlassTableDrillsTests/PotMathTests.swift`: SB posts 1, BB posts 2, A raises to 6, B calls 6, SB folds, BB raises to 18 by adding 16, and A calls by adding 12. The script stops before B responds again. The 43-chip total stays out of visual and accessibility output until help or answer reveal. Answer choices are 45, 43, and 49 with equal styling before commitment. Help reveals the calculation but leaves the learner to select an answer; the result then says the attempt was assisted.

Pot, Position, and Play call the same table/seat/card rendering functions. Combos uses the same card faces without a table. The normal table footprint is 328 × 240 at a 375-pixel viewport and 328 × 280 in large text. This is a provisional readability tradeoff: the shared board, center chips, four seats, and readable labels did not all fit a strict 2:1 rectangle. The footprint remains identical between the three table modes and across pot question, answer, and reveal states at each text size.

Review flows: expand the Position action-order example and the six AA pairs in Combos; try each question; replay and back through Pot and Play; help on the last Pot action; inspect Play after Bot 2 folds and the shared cards appear. `verify-browser.cjs` exercises the scripted flows using `agent-browser` from `PATH` (or the `AGENT_BROWSER` path) and saves screenshots in `../evidence/`.
