# Agent handoff

## Through 2026-10-03 — early delivery summary, condensed 2026-10-06

Full entries and earlier archive links: [early delivery summary](handoff-archive/2026-10-06-early-delivery-summary.md).

- Early delivery: beginner navigation/lessons/free-table help and Direction A steps 0–8; historical commits, matrices and failed attempts remain in the archive. Delivery spec governs; no single clean full Direction A UI run claimed. Owner approved AX title wrapping and 0.765 pt corner exception.
- Support PR10 merged as 8e808ca, bilingual Pages support/privacy observed live; signed 1.0(14) installed in place with identical progress bytes. Evidence: docs/verification/2026-10-02-free-table-direction-a.md, support-publication.md, iphone-install.md and docs/reports/2026-10-02-direction-a-delivery.html.
- Open verification: physical VoiceOver/haptics, minimum iOS17/older runtimes and novice comprehension; signed Store validation/metadata/rating/territories; huge-history save latency; system permission/notification/share/review flows; backup export/import; seat/card readability and attached sheets on iOS17–18.
- Runtime/copy gaps preserved: iOS27 watchdog affected-phone check, unexplained iPhone16e AX walkthrough failure, live Bold Text redraw behavior, literal-text KO.wordJoined/Position intro checks, tiny EV-loss grid labels, unexplained scrolled-audit frames, queued serial-cache cancellation and unseeded PotMath question identity. No product cold-launch fix claimed. Outs/Math level2 and fast table deferred; retained 베팅 strings documented in step8. Later entries govern any subsequently resolved issue.
- Preserve untracked crawler/tools/.scratch and unrelated pot-calculation work. Device backup: .build/device-backups/20260924-before-reset/; no phone reset. Archive ignored evidence before deleting worktrees (proposal sweep archive kept).
- GRAC actual Release1.0(14) video f3bb670,404s at docs/grac-submission/2026-10-03/; format/size/simulator acceptance and statutory Annex2(8) radio remain unresolved. No upload/payment/submission; enrolment/counsel/submission remain owner work.

## 2026-10-03–04 — Friendly/casual build 15, condensed 2026-10-06

Full entries: [friendly/casual checkpoints](handoff-archive/2026-10-06-friendly-casual-checkpoints.md).

- D46 sets casual mainstream learning. Local feat/friendly-casual was not pushed.
  Four tracks plus Go deeper; plain titles lead, optional poker terms remain.
  Levels reuse placement.selfReport and alter suggestions/help, not grading.
- Free table: no empty seats, 40 chips and 10 hands, casual opponents isolated from
  seeded archetypes, shared beginner-chart review/hint and bluff callouts. Hint
  earns no FSRS credit. River missed draws now count as nothing in PracticeHandCoach.
- Session format 2 saves three questions; first guided answer is helped. A perfect
  unaided run still establishes proficiency. Format 1 loads; hidden lesson records
  persist. lessonTrend is optional, range-checked ±9, no schema bump; suggestions
  can adapt without marking lessons done. Preserve these persistence boundaries.
- Simple questions change asking only; store re-grades saved inputs. Hidden estimate
  intervals stay in reveal bytes but interval:nil avoids calibration credit.
  Plain seat/action terms and Go deeper explanations added. Position AX uses a
  sentence; answers/terms show action order. TodayView remains unused historical code.
- Release guard fixed via presentationTable; pre-fix clean suite Drills385+50/app69+38/UI140 in friendly-ui2.xcresult, earlier limits in archive. Signed1.0(15) installed in place on iPhone12mini, byte-identical progress; locked phone was not observed.
- Unresolved: physical haptics/VoiceOver/older runtimes and novice comprehension;
  remaining free raise 2BB presets and graded range/equity jargon. See later phone
  crawl entry for subsequent observation, not an assumption that these closed.
- Preserve untracked crawler/tools. Saved English simulator setting breaks crawl;
  run.sh clears it. Name individual methods (class-only filter ran zero tests).
  No final single-pass crawler run; Learn passed before recorder changes and was
  not rerun. Range opposite-grade retry is a crawler limitation; share closes by swipe.
  Owner decision to commit crawler remains open.

## 2026-10-05 to 2026-10-13 — builds 15 to 22 and audit follow-ups, condensed 2026-10-13

Full entries: [build 15 to audit follow-ups](handoff-archive/2026-10-13-build-15-to-audit-followups.md).

- Delivered: build 15 crawl and proposal reports; native refinement and calm encouragement (build 16); device feedback from the iPhone 13 mini (28 comments) through build 18; beginner completion (build 19); experience-first opening (build 20); numerical audit and N01–N07 corrections; build 21; green brand welcome (build 22). Build history: `docs/build-history.md`.
- Phones: iPhone 12 mini has a fresh signed 1.0 (22); iPhone 13 mini has build 18. Every reinstall starts with fresh data and no phone progress is copied (AGENTS.md).
- Workspace: sibling worktrees archived at `.archive/2026-10-11-workspace-cleanup/` (`docs/workspace-cleanup.md`); develop only in this folder.
- Audit follow-ups (2026-10-11 to 13): every item decided by the owner and implemented on `feat/audit-followups`, pushed to `origin`. Decisions and evidence: `.scratch/audit-followups-2026-10-11/map.md` and `issues/`. Report: https://claude.ai/artifact/JUwpSsMWHvXqjEsmLeHADQ; example wording: https://claude.ai/artifact/Xd6qk866FFQJCbz9h5J9sH. Owner read all 18 written examples and kept `bb` in examples 8, 15 and 18.
- One corner radius: `GT.Radius.control` (10) for seats, felt, bottom panel and controls. Nothing in the app's own shapes follows the display curve; the owner asked for that explicitly (`89a55c3`). Pills, playing cards and `GT.Radius.panel` cards unchanged.
- Test environment: use the iPhone 17 iOS 26.5 simulator by id (the bare name picks the iOS 27 beta). Before a UI run after a rebuild, `xcrun simctl uninstall <device> com.michaelju.glasstable.GlassTableUITests.xctrunner`, or the simulator can run an old test bundle.

Open, carried forward:

- Human and runtime checks never done: real novice comprehension, physical VoiceOver and haptics, minimum iOS 17 runtime, AX5 full scroll reachability on every route, distribution.
- Numerical audit N08–N12 and model qualifications; graded-flop sampling sensitivity against the 0.5/2bb thresholds is not bounded; two latent weighted/continuation risks (`docs/audits/2026-10-11-numerical/`).
- Build 15 crawl candidates never verified: short tap heights on ‘설명 접기’, ‘안내 건너뛰기’, ‘계산 보기’, ‘전체 차트 보기’, ‘크게 보고 핸드 찾기’; unlabelled buttons on free-table setup. Free-table review once paired 33% with "four wins in ten"; not re-checked.
- Proposed, not approved or made: README drift fix (four tracks vs nine units, question counts), topic-led summary, recent-topic Records, post-commit best-five explanation; versioned integrity plan for archive/format/session-ending persistence.
- From the 2026-10-11 audit fix pass, not confirmed closed: free-table dock/seat layout at 2–3 players. Check `map.md` before reopening.
- `AccessibilityAuditTests/testPlayTable` failed overnight on 2026-10-13 on iPhone 12 mini (including on pre-corner code) and passed there the next afternoon; unexplained. On iPhone 17 it failed until `89a55c3` and passed 4 of 4 after.
- Intermittent: `FreeTableBackFlowTests/testAXKOExpandedPolicyEndReachable` (iPhone 17), `FreeDockFlowTests/testResultProseScrollsWithoutMovingActionsAtNormalAndAXSizes`.
- Seen, not changed: at AX5 in English the "Decision help" pill is clipped in the raise header; the Korean AX5 raise title is cut inside its scroll box. iOS 27 beta only: Settings language switch does not re-render the screen.
- Unused code seen and left: `ProgressionModel.shouldPresentFirstPlacement`, `seatSentence`.
- Last full UI suite (both phones, 238 tests, 11 skipped, 1 failed: the contrast audit) ran at `9a1822f`. Later commits `7e9ac4b`, `89a55c3` were checked with unit tests and targeted UI tests only.
