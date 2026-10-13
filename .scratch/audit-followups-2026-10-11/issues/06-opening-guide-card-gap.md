# 06 — Opening guide: gap between shared cards and the choices

Type: research
Status: resolved

## Question

On the comparison questions, the shared cards sit under the text and the two
hands to choose from sit at the bottom, with a large empty area between.
Should the shared cards move?

## Answer (findings, 2026-10-12; decided)

Evidence: `evidence/opening-question-variants.jpg` — real renders from a
throwaway copy of HEAD (repo untouched), iPhone 17, light, normal text.

- The question text and shared cards are top-aligned scroll content
  (`FirstLessonView.swift:915-941`, `:67`); the choices are a panel pinned to
  the bottom (`:81-86`). Whatever height is left over sits between them.
- The learner has to combine each hand with the shared cards, which are the
  farthest thing on screen from the hands.

Variants rendered:

- A. As now.
- B. Shared cards pushed down to sit just above the choices panel; the empty
  area moves between the explanation and the cards.
- C. Shared cards inside the choices panel, directly above the two hands.

Notes: C makes the panel taller, and at accessibility text sizes the panel is
already inline in the scroll content, so only normal sizes change in B or C.
After answering, the reveal layout is separate and was not changed in the mocks.

Recommendation: C.

## Comments

- 2026-10-12 (Claude): owner likes A but asked for halfway between A and B.
  Rendered "Halfway": shared cards centred in the free space between the text
  and the choices panel (`evidence/opening-question-halfway.jpg`). Awaiting
  confirmation.

## Decision

Decision (owner, 2026-10-12): A, no change. Shared cards stay directly under the explanation. Halfway, B and C were rendered and declined.
