# Chessmate-inspired refinement delivery

## Scope

This local implementation follows the [benchmark proposal](2026-09-18-chessmate-benchmark.md): a hands-on introduction, clearer Korean teaching copy, typography/layout refinements and approved store naming. Purchases, accounts, English lessons and App Store submission are separate phases.

New learners compare two legal Hold’em hands, see why one wins, and apply the same rule to different cards before the app introduction. The final action opens the first course lesson. Skip, interruption, replay from Settings and returning-user handling are covered. Guided onboarding does not grant mastery, answer history or review credit. Existing progress, recovery and save-retry behavior remain intact.

The copy pass covers screen controls, generated feedback, empty states and accessibility labels. Shared explanation spacing, scalable prose, compact-width seat summaries and spoken Korean card names improve readability. Semantic localization keys begin with the first lesson; the full curriculum remains Korean. Dynamic and accessibility text reflows naturally; no universal no-orphan guarantee is claimed across all font sizes and generated content.

Store metadata drafts use **포커 배우기 — Glass Table** and **Poker Lessons — Glass Table**. The Home Screen remains **Glass Table**. No identifier, store record or name reservation changed.

The owner intends individual Apple Developer enrollment. US and Korea are priority markets; Canada, UK, Australia, New Zealand and selected Asian storefronts are candidates for final requirements checks. EU release is deferred. Korean simulated-gambling classification and any RCN requirement remain unresolved.

## Verification

The machine initially blocked Xcode tools with an unaccepted-license message. After the owner was notified, Xcode commands became available. No agreement was accepted by the agent. This pass uses Xcode 27.0.

- Implementation candidate `59022541584655b351f0fa4d44d6fdccee16ad42` received independent correctness and persistence review with no outstanding findings.
- 332 Drills tests passed, including legal first-lesson fixtures, legacy optional-marker decoding and tied hands that use hole cards. A later wording refinement passed the focused 24-test selection.
- 32 app model tests and 18 UI tests passed on iPhone 17 / iOS 26.5. Coverage includes first lesson completion, skip, interruption, Settings replay, progress persistence, recovery, save failure/retry and existing accessibility flows. Log: `/tmp/gt-benchmark-app-final.log`.
- Additional test-only commit `1abdfbf` covers the complete first lesson through course entry at Accessibility XXXL; it passed on iPhone 12 mini / iOS 26.5. Log: `/tmp/gt-benchmark-firstlesson-ax.log`.
- The unsigned device Release build passed `tools/verify_release.py`; the new `GT_TEST_FIRST_LESSON` override was also confirmed absent from the binary. Log: `/tmp/gt-benchmark-release.log`.
- 11 Python tooling tests and shell syntax checks passed. Store title/subtitle lengths, promotional text and keyword draft limits were checked locally.

Visual inspection caught a duplicate first-answer explanation and an inaccurate tied-hand explanation; both were corrected. It also found invalid dates in DEBUG demo progress, causing seeded screenshots to show a save warning, and an overly strong “best” label for a slightly suboptimal EV choice. The correction candidate `ee9c98249bdb4a7f70943984ea834c99112fc79a` was independently approved with no findings. Production progress validation and grading thresholds are unchanged. Its 22 focused EV-loss tests and all 33 model tests passed, including the demo-state production-store roundtrip. The final unsigned device Release build and bundle checks passed again; the first-lesson test hook remains absent. Logs: `/tmp/gt-benchmark-evloss-focused.log`, `/tmp/gt-benchmark-final-model.log`, `/tmp/gt-benchmark-release-final.log`. Tooling verification also passed all 11 tests on the final candidate.

## Evidence boundaries and release gates

The full initial screenshot sweep uses the earlier `69ff88e` source snapshot. Some iOS 27 captures were blank during intermittent simulator launch stalls; capture generation is not counted as visual approval. Final selected captures are in `.build/benchmark-visual-final/`: normal-size first-lesson answer, EV-loss reveal and action-read reveal on iPhone 17 / iOS 26.5; compact Accessibility XXXL first-lesson question, answer, introduction, Today, Settings, notation and RFI on iPhone 12 mini / iOS 26.5. These representative frames were inspected, not merely generated. The save warning is absent from corrected reveals. The full first-lesson interaction test establishes that offscreen actions are reachable by scrolling.

Compact inspection found two additional layout issues: title/skip crowding in the first-lesson header and a truncated `UTG+1` in the RFI seat grid. Commits `4696679` and `833d844` stack the header at accessibility sizes and use two columns for accessibility seat labels. The first-lesson AX flow passed again after the header change (`/tmp/gt-benchmark-header-ax.log`); the final RFI capture displays every seat label fully. Ordinary-size layouts are unchanged.

Final runtime candidate **`833d844633477239528c26f46726226772e68215`** received independent delta approval with no findings. Final simulator and unsigned device Release builds passed; the Release bundle checker passed. Logs: `/tmp/gt-benchmark-build-layout-final.log`, `/tmp/gt-benchmark-release-layout-final.log`. No full test-suite rerun is claimed after these two layout-only corrections; focused behavior, build and rendered checks cover their changes.

The initial compact disposable simulator stalled during launch; that sweep was stopped after its first frame. Compact verification continued on the existing isolated accessibility-test simulator. No learner data was used. The main checkout remains untouched; the delivery is committed locally on `codex/research-led-revamp` in `/Users/michaelju/Workspace/Projects/glass-table-revamp`.

No physical-device installation, signed distribution archive validation, minimum-iOS-17 runtime test, App Store upload or territory selection was performed. The Engine was unchanged; its earlier Release test evidence is not represented as a new run. Physical-device VoiceOver, minimum-OS compatibility, user acceptance and signed-release testing remain necessary before submission. The [submission checklist](../submission.md) tracks privacy policy publication, fresh store screenshots, age rating and regional requirements.
