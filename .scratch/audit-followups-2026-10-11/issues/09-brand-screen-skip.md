# 09 — "안내 건너뛰기" on the brand screen

Type: research
Status: resolved

## Question

Should the first screen (logo and Start) offer "안내 건너뛰기"?

## Answer (findings, 2026-10-12; decided)

Evidence: `evidence/brand-screen-skip.jpg` — real renders from a throwaway copy
of HEAD (repo untouched), iPhone 17, normal text.

- The brand screen shows the logo, "Glass Table", Start, and a small
  "안내 건너뛰기" top right (`FirstLessonView.swift:477-489`). Nothing on the screen
  says a guide is coming, so the Skip link refers to something not yet named.
- Skip is also on every later page of the guide (`FirstLessonView.swift:376-384`),
  one tap after Start.
- The minimal brand screen is a recent deliberate choice
  (`docs/agent-handoff.md` 2026-10-11, "Brand welcome exploration").

Variants rendered:

- A. As now.
- B. No Skip on the brand screen; it appears from the next page on.
- C. Skip moves under Start as a quiet line that says who it is for:
  "홀덤을 이미 알아요 · 안내 건너뛰기".

Recommendation: C. It keeps the one-tap exit for experienced players and tells
a newcomer what Start leads to. B is the cleaner screen at the cost of one
extra tap for experienced players.

## Comments

- 2026-10-12 (Claude): owner chose C but wants the Skip to look like a button,
  with a faint border. Rendered C1 (faint outline, same shape and width as
  Start) and C2 (faint outline pill, sized to its text):
  `evidence/brand-screen-skip-border.jpg`. Awaiting the pick.

## Decision

Decision (owner, 2026-10-12): C1. Skip moves under Start as "홀덤을 이미 알아요 · 안내 건너뛰기" (EN "I already know Hold'em · Skip the guide"), drawn as a faintly outlined button with the same shape and width as Start. Remove the top-right Skip from the brand screen.
