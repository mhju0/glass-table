# Native KO/EN line parity audit

Measures the [bilingual line parity rule](../../../DESIGN.md) on real app
screenshots. Run from this folder on macOS with Python 3 and Pillow.

1. Capture both languages at the default size on a compact phone:
   `GT_SIM="iPhone 12 mini" GT_APPEARANCE=light GT_LANGUAGE=ko GT_CONTENT_SIZE=large tools/uisweep.sh`
   (from the repo root), then again with `GT_LANGUAGE=en --no-build`.
2. Build the Vision OCR helper: `swiftc -O ocr-lines.swift -o .build-ocr-lines`.
3. `python3 match.py <ko>/large <en>/large --json out.json` finds every
   `language.text("ko", "en")` pair on screen and reports line counts, last-line
   fill and end-width differences.

Copy fitting without re-sweeping:

- `wrap.py` simulates wrapping with the bundled Pretendard fonts, calibrated
  against the observed OCR widths in `match-before.json`.
- `fit.py cands.json` checks candidate rewrites for strings found by `match.py`.
- `guidefit.py` checks the learning guide's `StudyNote` pages, which are not
  `language.text` pairs; `gtest.py` and `gsearch.py` try candidate rewrites.
- `copytable.py` lists every changed KO/EN pair from the working diff.

Results: `match-before.txt` (51 pairs flagged) and `match-final.txt` (11 flagged,
10 of them merged-line false positives). `copy-table.json` holds the 75 changed
pairs. `analyse.py` is the first, block-based pass and is noisier than
`match.py`. Limits and conclusions are in `../verification.md`.
