# 02 — Free table: empty band above the dock and small shared cards

Type: research
Status: resolved

## Question

Why is there so much empty space on the free table, and what should fill it?

## Answer (findings, 2026-10-11; decided)

Evidence: `evidence/free-table-dock-faces.jpg` (four dock states, iPhone 17,
normal text).

- The dock is deliberately one fixed height. `GTStableDockLayout`
  (`GlassTable/Sources/DesignSystem/Components.swift:1157`) sizes it to the
  tallest of every state it can show, using hidden templates
  (`FreeTableView.swift:449-486`): your turn, waiting, raise, result, hint.
  The result state is the tallest, so "your turn" shows a header, about 200 pt
  of nothing, then three buttons.
- The table keeps its natural height and a `Spacer` takes the rest
  (`FreeTableView.swift:238-241`), which is the empty band between the felt and
  the dock (about 90 pt on iPhone 17).
- Roughly: table 39% of the screen, band 8%, dock 38%. The shared cards are
  drawn at seat-card size inside the felt.

Options:

1. Keep the fixed dock height; let the felt grow into the band and draw the
   shared cards larger. Smallest change, no jumping.
2. As 1, and use the empty area in "your turn" for the facts needed to choose
   (amount to call, pot), which today sit behind the hint button.
3. Let the dock change height per state. Removes the emptiness but the table
   and buttons move every time the state changes.

Recommendation: option 2.

## Decision

Decision (owner, 2026-10-11): option 2. Keep the fixed dock height, let the felt fill the band with larger shared cards, and show amount to call and pot in the blank area of "your turn".

## Comments
