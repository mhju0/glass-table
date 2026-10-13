# Whole-app consistency exploration

October 10, 2026 · research and HTML proposals only

## Scope and evidence

The owner approved the first-five-minute proposals and explicitly requested further exploration without building the app. This study compares their effects across onboarding, Learn, worked guides, lesson decisions, feedback, graded one-to-one practice, Free Play, Progress and Settings. Native source is `a3db5fc`, documentation HEAD `65faf87`. Installed Release 1.0 (19) is unchanged. Existing native screenshot galleries are historical fixture evidence with per-frame commits, not a fresh whole-app crawl. The HTML demonstrations are illustrative, with no connection to saved progress or the poker engine.

The recommendation is a common interaction grammar, with task-specific compositions. Preserve the app's warm surfaces, amber action role, green result role, Pretendard fonts, fixed poker objects, equal-weight answer alternatives and accessible scrolling. Adapt the approved experience-first opening to these rules. Do not use its initial 52-pixel/system-font/optional-teal exploration as the specification for all native controls.

## Primary-source findings and applications

1. **Related controls should be recognizable, but different roles need different controls.** Apple describes buttons through style, content and role, distinguishes toggles and segmented controls, and recommends a pressed state. [Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons). Application: distinguish Continue, answers, disclosure, navigation and settings selection. Keep answer options equal before commitment; an amber Continue is a navigation affordance, not a hint toward the right answer. This is a design application, not a measured learning effect.

2. **Touch size and visible size are different.** Apple's tips specify at least 44 × 44 points for controls, spacing and alignment, and placing controls near what they modify. [UI Design Dos and Don'ts](https://developer.apple.com/design/tips/). Application: retain native 54-point primary and 50-point secondary minimums; provide 44-point auxiliary targets. Treat 60-point primary controls as an optional trial on sparse screens, not a global scaling command. CSS pixels in the report approximate geometry; they do not prove native point sizes or thumb comfort.

3. **Destination navigation is distinct from actions.** Apple defines tab bars as top-level navigation, preserves them during section navigation and allows a temporary modal to cover them. [Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars). Application: keep Learn / Play / Progress / Settings stable on section roots. Keep lesson answers and game actions in their task dock, not the tab bar. The first-run task can cover tabs; a help view must return to its source. Don't hide tabs opportunistically just to make a root screen prettier.

4. **One voice can use different tones.** Apple's interface-writing session separates a consistent voice from situational tone, emphasizes purpose, anticipation, context and empathy, and recommends specific action labels and adaptable localization. [Writing for interfaces](https://developer.apple.com/videos/play/wwdc2022/10037/). Application: use a calm adult teacher's voice; warmly acknowledge learning, clearly correct misconceptions, and remain factual about persistence or data errors. Avoid praise in destructive confirmations. English app speech uses “you/your”; Korean uses natural 해요체 without mechanically inserting 당신. First-person choices may remain only when the response is naturally personal (“I'm not sure”); repeated hand-result labels should use one normalized phrasing.

5. **Less information requires a hierarchy, not indiscriminate deletion.** Apple's design evangelism Q&A advises progressive disclosure when rows are crowded and asks what each element contributes. [Design Evangelism Q&A](https://developer.apple.com/news/?id=s8sl4tpa). Application: retain decision-critical pot/call/hand/current actor context, then reveal assumptions and numerical derivation. Put the rule and reason at the front of feedback. A chart grade and a no-later-bets EV grade still need their basis clearly identified; visual simplicity cannot turn either into universal poker correctness.

6. **Feature tips are not a course.** Apple warns that tips can distract when repeated and that TipKit should not guide people through an app. [TipKit](https://developer.apple.com/documentation/tipkit/). Application: keep teaching content learner-paced, available until Next, and reopenable. A short optional tip can announce an unfamiliar feature; essential rules must not vanish after two seconds. No TipKit integration is proposed in this research turn.

7. **Color needs stable meaning and redundant signals.** Apple advises consistent color usage and discourages relying on color alone. [Color](https://developer.apple.com/design/human-interface-guidelines/color). Application: amber marks actions or selection; green marks success or activity; red marks an error or destructive action, with labels/icons. The fixed green table is an object, not a success state. A chart's colors require its own legend. No research here establishes that a new palette increases retention.

8. **Large text requires a different composition.** Apple's Larger Text criteria recommend testing all accessibility sizes and explain that iOS AX5 can exceed 300% body text. [Larger Text evaluation criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/larger-text-evaluation-criteria). Application: match EN/KO intended line groups at normal compact-phone size, using whole words and equivalent meaning. At accessibility sizes allow natural wrapping and stack controls in one continuous scroll; don't cap font sizes or clip explanations to preserve screenshot parity. The HTML 200% trial is not AX5 acceptance.

9. **Motion should explain changes and respect system preferences.** Apple discourages distracting motion and SwiftUI exposes Reduce Motion. [Motion](https://developer.apple.com/design/human-interface-guidelines/motion), [Reduce Motion](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion). Application: preserve native press spring response 0.22 / damping 0.9 and content response 0.34 / damping 0.9 as the starting baseline, not as newly validated values. Short help fades can be a deliberate exception. Provide visible status without requiring motion; no loop, timed wait, decorative reward bounce or delayed input.

10. **A graphic must explain what it measures.** Apple recommends comprehensible chart titles, labels and accessibility descriptions. [Charts](https://developer.apple.com/design/human-interface-guidelines/charts). Application: separate examples explored, lessons completed, practice dates, chart matches and game results. Progress graphics should express recorded activity, not imply skill growth from attendance. Use real denominators and comparators before writing “improved.” This is an evidence constraint, not an Apple learning-outcome claim.

## Source audit and current strengths

- `Theme.swift:48–80, 84–158`: spacing, radii, typography, motion and adaptive/fixed colors already exist. No wholesale visual replacement is necessary.
- `Components.swift:6–18, 778–797, 886–949`: shared press feedback, primary/secondary/choice families. Some guides request 52-point choices; this is a review point, not a demonstrated touch failure.
- `LessonLearningUI.swift:5–16`: paired normal text, natural joined text at accessibility sizes. Preserve this distinction instead of fixed-height bilingual text boxes.
- `Components.swift:610–726`: action docks distinguish graded/collapsible panels and adapt by iOS/text size. Reuse the behavior and test clearance rather than replace it with a browser rectangle.
- `RootView.swift:95–135`: stable roots and scoped task presentations. A contextual modal and hierarchy page can have distinct close/back behavior.
- `GradedTableLearningUI.swift:4–39`: explicit chart and EV explanations/basis. Keep their semantic differences while shortening the top-level reading burden.
- `RecordsView.swift:24–54`: activity/completion lead; detailed metrics collapse and state that app stages are not proven skill. Existing progress is already more than a wall of text.
- `SettingsView.swift:54–84, 181–210`: compact toggle/menu controls already exist. Preserve them; the proposal explores tighter grouping and tone, not a missing feature claim.

Local heading scales, spacing overrides, custom First Lesson Previous/Skip controls and different help containers deserve consistency review. They are not automatically defects. A full-screen screenshot cannot prove that lower content is unreachable, and these historical fixtures are not evidence that the owner's latest device reproduces a cut-off issue.

## Proposed shared rules and exceptions

Use the same page/content/action hierarchy throughout teaching. Keep text left aligned, short answer labels centered, cards consistently owned and sized. Use 18-point page edges, 16-point card insets, 14-point button corners, 20-point panel corners and 28-point sheet corners as existing native baselines. Do not transplant exact HTML margins or fixed heights into Swift.

Primary Continue/Next controls use amber. Answer alternatives share geometry and neutral emphasis. Actual game actions preserve the fold / passive / aggressive order and any published amount semantics; color must not imply strategic quality. A destructive reset is a distinct red action with explicit consequences. Toggles keep native switching behavior; language and appearance remain menus because System/Light/Dark is not binary. A settings row is not a giant lesson CTA.

Optional preference can follow the first two comparisons. Exposure at that checkpoint is not guide completion; full guide completion still means the defined five-category flow. Closing and returning, partial onboarding, placement recommendation and later replay need a separate persistence specification before implementation. Research approval does not authorize a schema change.

## Validation before native acceptance

First assess predictable navigation and explanation quality with adult poker beginners in each language; use experienced participants to assess bypass and chart terminology. Ask them to teach back the rule and identify whether a result means chart match, modeled EV or winning a hand. Observe help return, back/resume, interrupted lessons, full guide versus partial checkpoint, mid-game exit and empty Progress. Compare the 54 versus 60-point trial on a physical mini device; do not infer comfort from screenshots.

For any later implementation, verify EN/KO × light/dark, iOS 17 and current iOS, normal/AX5, VoiceOver focus/reading order, Reduce Motion/Transparency/Contrast, long dynamic values and disabled controls. Required assumptions must remain reachable and explain the actual grade. Test saved drafts/resume and data recovery if touched; re-run relevant native flows after the frozen candidate changes. No native tests, builds, simulator launches, data changes or device installations are part of this study.
