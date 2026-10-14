# Animation plans

Written by the `improve-animations` audit on 2026-10-14 at commit `9664c0a`.

| # | Plan | Severity | Status |
| --- | --- | --- | --- |
| 003 | [Hand-typed curves use GT.Motion tokens](003-hand-typed-curves-use-motion-tokens.md) | LOW | DONE |
| 002 | [Skill glyph accent settles quickly](002-skill-glyph-accent-settles-quickly.md) | LOW | DONE |
| 001 | [Board cards enter near full size](001-board-cards-enter-near-full-size.md) | MEDIUM | TODO |

Execution order: 003 first (adds `GT.Motion.fade`, which 002 uses), then 002, then 001.
001 is independent.
