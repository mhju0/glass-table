# Mobile poker card display benchmarks

- **Date:** 2026-09-19
- **Kind:** research
- **Originals:** `docs/research/2026-09-19-card-display-benchmarks.md` (tracked: `git show f5c5e22:<path>`)
- **Asked by / for:** [Unknown]; research only, no app changes, to inform a redesign of the card face component.

## What it was
Review of official App Store screenshots (Apple Texas Hold'em, Poker Heat, Zynga Poker, Poker Trainer) and the GTO Wizard trainer theme animation, to compare how mobile poker apps draw cards. Five overlapping patterns, not an exhaustive taxonomy; store screenshots are marketing, not proof of every in-app theme.

## Findings and decisions
- Traditional illustrated face (Apple): corner indices, large suits, court art. Familiar; use upright flat cards for teaching, no perspective.
- Jumbo corner index plus dominant suit (Poker Heat): strongest small-screen readability reference.
- Fanned, overlapped hole cards (Zynga): fine for table simulation, weak for beginner comparison.
- Centered rank above suit (Poker Trainer): efficient minimal option; vertical stacking uses card height far better than Glass Table's short horizontal rank/suit pair.
- Color-backed compact rank tiles with T for ten (GTO Wizard, web): good secondary notation for histories/ranges, weak default for newcomers.
- PokerStars help shows card design, four-colour deck and card size as separate options; no evidence of a single industry-standard deck.
- Diagnosis: the current card leaves most of a tall card empty around a small horizontal rank/suit pair; centering alone does not fix the hierarchy.
- Recommendation (agent design judgment, not measured usability): keep full upright cards for lessons and showdown; prototype a traditional face (large corner indices, central pips, original or licensed J/Q/K art) against a jumbo-index simplified variant at real iPhone 12 mini size; five board cards visible; same geometry across regions; readable 10 without shrink-to-fit; no overlap in lessons; two-color suits by default, four-color optional and independent.

## Outcome
Research only. Which variant (if any) shipped is not stated in the source [Unknown].

## Still open
- The prototype comparison at iPhone 12 mini size, as of the source date [Unknown whether done].

Sources: App Store pages for Apple Texas Hold'em (id284602850), Poker Heat (id480523695), Zynga Poker (id354902315), Poker Trainer (id6478522482); help.gtowizard.com trainer guide; PokerStars table-appearance help article.
