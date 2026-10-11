# Numerical audit corrections — 2026-10-11

Follow-up to the frozen build-20 numerical audit. This correction pass closes N01–N07; N08–N12 remain separate qualification work, with the two latent model risks unchanged.

| Finding | Correction |
|---|---|
| N01 | Positive, negative and zero call EV have distinct explanations. Zero is break-even in Korean and English; Korean glossary equality is also break-even. |
| N02 | Korean PFR and VPIP explicitly use all starting hands as their denominator. English reinforces that denominator. |
| N03 | Outs examples explain their actual current behind/tied/ahead state, and count strict winning river cards. The lesson label is neutral about a turnaround. |
| N04 | Excluded river cards have separate tie/loss explanations. The shared live/restored river panel displays a tie instead of an opponent win. |
| N05 | Call/fold reveal describes equity as pot share including tied pots, rather than outright winning chance. |
| N06 | Review-now eligibility compares exact timestamps. Future reviews say later today, tomorrow or a localized date. |
| N07 | Detailed Records projects the still-active streak using the existing freeze policy. Historical streak/freeze fields stay untouched. |

## Compatibility decision

Do not add a behind-only rejection rule to the existing outs generator. Saved drafts, reveals and walkthrough positions regenerate seed/index questions, and the progress loader validates saved grades against those regenerated questions. Changing the bank would silently change resumed questions or reject an entire saved progress document. This pass preserves seed mapping, counts, grades, walkthrough order and persistence schemas. A future behind-only bank needs explicit legacy generator routing and independent persistence review.

The new engine comparison helper delegates to the existing full hand key, including kickers. It adds a comparison API without changing ranking or equity formulas. Review timing and active streak display are pure helpers; rendering does not award sessions or save freezes. Records uses one render timestamp and refreshes on minute ticks, foregrounding and clock/timezone changes while retaining expanded details.

## Verification

See the correction delivery report and package/native test logs for final results. Regressions cover the exact break-even call, PFR denominator, audited ahead/tied river examples, excluded ties/losses, all-tie equity, saved-question import/save/reload, review deadline/timezone/DST, and streak expiry without history mutation.

Native verification covers English/Korean and light/dark. Screenshot fixtures are deterministic simulator evidence, not novice or physical-device validation. The correction pass does not reinstall the phone or reset any user data. Physical VoiceOver, novice comprehension, minimum-iOS runtime and sampled-grade boundary sensitivity remain separate acceptance work.
