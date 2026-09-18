# Chessmate-inspired refinement delivery

## Scope

This local implementation follows the [benchmark proposal](2026-09-18-chessmate-benchmark.md): a hands-on introduction, clearer Korean teaching copy, typography/layout refinements and approved store naming. Purchases, accounts, English lessons and App Store submission are separate phases.

The owner intends individual Apple Developer enrollment. US and Korea are priority
markets; other English-speaking and selected Asian storefronts remain candidates
for a final requirements check. EU release is deferred. Korean simulated-gambling
classification and any RCN requirement remain unresolved.

## Verification status

Implementation and review are in progress. Do not treat earlier release-candidate
test counts as evidence for these changes.

The machine initially blocked Xcode tools with an unaccepted-license message.
After the owner was notified, `xcodebuild -checkFirstLaunchStatus` and `simctl`
succeeded; the available toolchain is now Xcode 27.0. No agreement was accepted by
the agent. Build and simulator evidence below must come from the new candidate.

The five first-lesson states are registered in `tools/uisweep.sh`. Planned visual
coverage includes those states plus Today, Path, Records, Settings, guided and
independent drills, long reveals, glossary and table on compact/regular phones and
at accessibility text sizes. Screenshot generation alone does not establish that
text is readable or controls are reachable.

Store title/subtitle character limits and promotional/keyword draft limits have
been checked locally. These checks do not reserve a store name or establish
regional eligibility.
