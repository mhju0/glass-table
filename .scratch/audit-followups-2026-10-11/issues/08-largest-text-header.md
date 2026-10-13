# 08 — Opening guide: oversized pinned header at the largest text size

Type: research
Status: resolved

## Question

At the largest text size the opening guide's header takes a large part of the
screen and never scrolls away. What should it do?

## Answer (findings, 2026-10-12; decided)

Evidence: `evidence/largest-text-header-ko.jpg`, `largest-text-header-en.jpg`
— real renders from a throwaway copy of HEAD (repo untouched), iPhone 17,
light, largest accessibility text.

- The header (title, progress, "안내 건너뛰기") sits outside the scroll view, so it
  is pinned (`FirstLessonView.swift:56`), and at accessibility sizes it stacks
  the three lines vertically at full size (`:169-173`, `:348-361`).
- In English "Getting started" wraps to two lines, so the pinned header takes
  roughly a third of the screen; Korean takes about a quarter. Only the rest
  scrolls.
- This header is specific to the opening guide; other screens use the shared
  top bar (`gtChrome`).

Variants rendered:

- A. As now.
- B. Stays pinned, header text capped at the first accessibility size. Header
  shrinks to under a fifth of the screen; Skip stays reachable at all times.
- C. Header scrolls away with the page. Most room for content, but Skip and
  the progress count leave the screen once the learner scrolls.

Recommendation: B. The question and answers keep full-size text; only the
header labels are capped, as system navigation bars do.

## Comments

## Decision

Decision (owner, 2026-10-12): B. Header stays pinned; its text is capped at the first accessibility size.
