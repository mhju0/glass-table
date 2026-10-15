# Korean/English line parity check

Measures the bilingual line parity rule in `DESIGN.md` on real app screenshots.
Run from this folder on macOS with Python 3.

1. Capture both languages at the default size on a compact phone (from the repo root):
   `GT_SIM="iPhone 12 mini" GT_APPEARANCE=light GT_LANGUAGE=ko GT_CONTENT_SIZE=large tools/uisweep.sh`,
   then again with `GT_LANGUAGE=en --no-build`.
2. Build the Vision OCR helper: `swiftc -O ocr-lines.swift -o .build-ocr-lines`.
3. `python3 match.py <ko>/large <en>/large --json out.json` finds every
   `language.text("ko", "en")` pair on screen and reports line counts, last-line
   fill and end-width differences.

History and the copy-fitting helpers used once in 2026-09: `docs/records/2026-09-23-consistent-learning-table.md`.
