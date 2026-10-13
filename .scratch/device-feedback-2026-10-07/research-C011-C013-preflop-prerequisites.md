# C011–C013 — Notation, hand scoring and chart literacy

Source audit complete, proposals only. New-player required Starting hands track introduces Position/RFI/Defend while the dedicated notation lesson is optional Go deeper (LearningTrack.swift:27–35; Curriculum.swift:45–53,68–76). Thus K6s can precede explicit notation instruction.

## C011 — Concrete cards before shorthand

RFI worked first beat shows cards plus HandClass.description (Beats.swift:403–435; EnglishBeatScript.swift:231–247; WalkthroughView.swift:188–191). K♠6♠ immediately becomes K6s without defining s. ConceptExplain notation note gives generic AKs/AKo/99+ examples, but does not connect the shown cards to K6s. Introduce King and six, then same-suit meaning, then K6s with s explained as same suit, not spades specifically. Only later contrast different-suit K6o and pair KK. Keep notation canonical and secondary until taught. Also define raise first/open as a first voluntary raise when nobody has entered, not an arbitrary slogan or universal optimal play.

## C012 — Optional math, unchanged disclosed practice policy

RFI is graded against chart membership, not a learner's Chen arithmetic (RFIChart.swift:32–39; RangeDrills.swift:122–143). The practice range is top N percent by Chen ranking, with seat shares UTG through SB 15/17/20/23/28/42/36; BB has no RFI decision. Published source explicitly describes interpolation and does not claim to reproduce either reference chart or a solver.

Chen.swift:20–70 uses high-card base, pair adjustment, suited bonus, gap penalty and connector bonus, then half-point rounding/ties. K6s has base8 + suited2 − gap5 =5. This is a heuristic ranking, not exact equity or proof of optimal play. Beginner decisions need card identity, seat, meaning of open/fold and chart membership; exact arithmetic can move to optional How this chart ranks hands while leaving grading/policy intact and transparent. Do not add a perfection gate or silently change saved three-question completion.

## C013 — Chart meanings verified from actual code

RangeGrid.swift:13–19 and RangeGridView.swift:31–55 iterate rank VALUES Ace14 down to2 on both axes. classAt(rowRank,colRank) marks same-suit when rowRank > colRank, corresponding to upper-right ABOVE the pair diagonal because ranks descend visually. Below-left is different-suit. Diagonal is AA→22. Each cell is a two-card hand class; exact combinations 6/pair,4/suited,12/offsuit are deeper information, not essential first-use arithmetic (HandClass.swift:3–8,31–45).

Grid has no external visible A→2 axis labels. Mint fill indicates inclusion in the chosen range, outline/ring may indicate highlight or selected/compared range, empty surface exclusion; partial ranges can partially fill cells. In RFI the relevant meaning is membership in this seat's practice chart, not generic strength or winning probability. Upper-left contains high ranks, but strength is not strictly monotonic across adjacent cells. Introduce actual legend, pairs/triangles and a single highlighted cell before the full grid.

Phone grid cell text is tiny (~24pt cells in339pt grid) and display-only; VO already provides row summaries. Provide an enlarged selected-cell/row or synchronized list explanation at AX5, not reliance on zooming a dense169-cell graphic. Test non-color membership meaning and VoiceOver axis/cell readout.

## Coherent learning sequence

C010 concrete seat/order → face-up card ranks and suits → same-suit/different-suit/pair notation in context → plain meaning of open/fold → one cell then axes/diagonal/triangles/legend → current-seat practice chart → decision → optional Chen derivation. Each first-use term needs a short contextual explanation, not a dictionary dump. Same progression in English and Korean, with card glyphs consistent, current questions/reveals preserved, and chart/grade stable across language or term preference.
