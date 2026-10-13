# Early delivery summaries archived 2026-10-06

## Through 2026-09-30 — condensed 2026-10-02

Full detail: [the 10-01 archive](handoff-archive/2026-10-01-before-direction-a.md), which retains the earlier archive links and all historical entries.

- Shipped through 09-30: combined beginner release, four tabs, first-run guide and
  Hold'em basics; lessons/reveals, accessibility/Bold Text, sheets/spacing;
  policy/Range Read/locked-choice/Position fixes; full-screen free table replay/help.
- Open human/release checks: physical VoiceOver, minimum iOS 17, novice comprehension,
  signed Store/distribution validation, screenshots, age rating/territories,
  very-large-history save latency, and system permission/notification/share/review
  flows remain unverified. Enrolment, counsel and submission remain owner work;
  support/privacy pages are now queued after Direction A.
- Runtime gaps: iOS 17–18 attached sheets compile but were not observed; the iOS 27
  watchdog fix removed UIKit window reads from ActionSheet.body and needs the
  affected phone checked after install. The known AX walkthrough failure on one
  iPhone 16e simulator was not investigated; CI passed on its device. Live Bold Text
  changes reach views that redraw; reopening makes them consistent without resetting
  a hand. Shared table dimensions remain a readability tradeoff.
- Copy/audit checks: KO.wordJoined does not cover literal Text or Button/Label titles;
  recheck the reported Position intro leaks before calling them resolved. EV-loss
  range-grid labels remain about 6 pt; backup export/import is unverified. Empty
  practice-change content was a fixture artifact. Scrolled-audit screen-wide findings
  remain unexplained. The uncommitted crawler's Play steps predate the full-screen
  free table; preserve tools/uxaudit/, UXAuditCrawl.swift and .scratch/uxaudit-codex/.
- Device reset backup: .build/device-backups/20260924-before-reset/; restore by copying
  its files back. Do not reset phone progress otherwise. Archive ignored evidence
  before removing worktrees; proposal evidence is .build/archive/glass-table-proposal-uisweep.
  .scratch/pot-calculation-redesign/ remains intentionally untracked and unrelated.

## 2026-10-01 — Direction A steps 0–4, condensed 2026-10-04

Full entries: [early checkpoints](handoff-archive/2026-10-01-direction-a-early-checkpoints.md)
and [steps 2–4](handoff-archive/2026-10-02-direction-a-steps-2-to-4.md).

- feat/free-table-direction-a from 33e5384: step 0 6dc95b6, step 1 spacing 22bb963,
  step 2 a52b094 (paper hero, clockwise seats, fixed cards), step 3 dd348cb (three
  fixed slots, replay prices, stable dock), step 4 3f6b61b (gold commit, presets,
  press/hold, AX amount scrolling). The delivery spec supersedes exploration pages.
  Owner approved wrapping AX titles and native corners with a 0.765 pt exception
  (spec §13). Measurements and failed attempts: .build/direction-a/step2…step4/report.md.
- Still open: physical haptics, VoiceOver and older runtimes unverified; seat heights
  and physical readability remain a tradeoff; no product cold-launch fix claimed;
  Outs/Math level 2 and fast table deferred.

## 2026-10-02 — Direction A steps 5–8, support pages, phone install, condensed 2026-10-03

Full entries: [steps 5–8, support and phone archive](handoff-archive/2026-10-03-direction-a-steps-5-to-8-support-phone.md).

- Steps 5–8 committed locally (step 5 is 5513364), never pushed: flipping dock back
  (Math / This hand / Rules), supervised public replay with chip and card motion,
  SwiftUI sensory feedback, app-wide inset/radius/font corrections, then the full
  verification pass. All 134 tracked UI methods have a passing outcome with failure
  history kept, not one green full run. Evidence: .build/direction-a/step5…step7/
  report.md and docs/verification/2026-10-02-free-table-direction-a.md.
- Support: MJ Apps Support / mj.apps.support@gmail.com in Settings, bilingual policy,
  docs/support.html; PR 10 merged to main as 8e808ca, Pages live at
  https://mhju0.github.io/glass-table/support.html and privacy-policy.html.
  See docs/verification/2026-10-02-support-publication.md.
- Signed Release 1.0(14) installed in place on the owner's iPhone 12 mini; progress
  bytes identical before and after. Ledger: docs/verification/2026-10-02-iphone-install.md.
  Delivery report: docs/reports/2026-10-02-direction-a-delivery.html.
- Still open: physical haptics, VoiceOver and older-runtime checks on a real phone;
  no dedicated queued-cancellation unit for the serial cache; unseeded PotMath
  generated-question identity not established; no product cold-launch fix claimed;
  Math outs level 2 and fast table deferred; 14 retained 베팅 strings listed in the
  step 8 report.

## 2026-10-03 — GRAC gameplay video, condensed

- Owner approved XCTest interaction; real Release 1.0(14) at f3bb670 recorded in an
  isolated simulator, no debug fixtures or product changes. Final local MP4:
  docs/grac-submission/2026-10-03/GlassTable_GRAC_1.0_14.mp4 (404 s, 1206x2622,
  H.264, no audio) with Korean optional descriptions and a scene timeline. Tooling
  is under .build/grac-video-2026-10-03.
- Open: site format/size and simulator acceptance unconfirmed; no upload, payment
  or submission done; the first statutory compliance radio (whether an offline App
  Store app falls under decree Annex 2(8)) is unresolved.

