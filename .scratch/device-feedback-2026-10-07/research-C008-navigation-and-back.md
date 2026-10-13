# C008 — Familiar back navigation and previous lesson steps

User requests left-edge swipe-right back navigation, either a hybrid with bottom-up surfaces or a broader side-navigation rebuild. Separately, the beginning guide and lessons need a way to revisit earlier steps. Changes are recorded for the session-end review; no phone update while testing is active.

Separate three intents: go to the previous teaching step; go back to the parent screen; dismiss a temporary help/task sheet. Do not implement them all as one indistinguishable gesture. Preferred candidate for investigation is native hierarchical navigation where there is a parent/child relationship, compact modal sheets for temporary help, and visible Previous/Back controls for instructional steps. Preserve visible alternatives, VoiceOver operation and discoverability; do not make swipe the sole route out.

Source audit needs to inventory actual stacks/covers/sheets, existing versus missing step-Back controls, current progress/resume behavior and whether hidden system navigation chrome blocks the standard interactive-pop gesture. Check competition with horizontal sliders, range-grid gestures and table actions. Do not emulate system navigation by an unverified global drag recognizer.

Progress correctness: revisiting an instructional page is not a new answer. Committed question history should be read-only on review unless the learner explicitly starts new practice; never silently overwrite/duplicate saved attempts. Preserve close/resume and cancelled-interaction state. Test forward/back/edge-swipe cancellation, first-step exit, help dismissal, interruption, language switching, normal/AX5, VoiceOver and Reduce Motion. Apple primary-document research is pending.

## Completed source audit

RootView.swift:87–167 has four NavigationStack roots but presents Node, Basics, FreePlay and Review as fullScreenCover tasks. Path/Placement are sheets. A cover's Close dismisses the task; an internal teaching beat is not a pushed navigation destination, so it does not automatically inherit interactive native Back. ChromeButton.close uses chevron-down/Close (Components.swift:499–523); ChromeButton.back uses chevron-left and is for one level inside a sheet (:504–507). Preserve that semantic distinction.

FirstLessonView.swift:15–26,134–141,188–205 has transient step/answer state, Skip/Close, and forward CTAs only. WalkthroughView.swift:25–43,302–343 has persisted initial index and forward-only footer. ProgressionModel.swift:630–635 already accepts an in-range worked step index while phase remains show, so previous teaching steps do not necessarily require schema changes. NodeSessionView.swift:292–300 saves showBeatIndex.

Committed Node answers are phase/ordinal checked, with deterministic attempt IDs and idempotency (NodeSessionView.swift:414–430; ProgressionModel.swift:670–705). Revisit instruction independently of re-grading an answer. Beginning-guide answer state needs an explicit policy when revisiting a question: preserve the result, or intentionally offer retry, never accidental duplicate advancement.

Design options: hybrid hierarchy and modal tasks with visible Previous/Back for instructional state is the smaller proposal. Actual system edge-back for every lesson step would require genuine NavigationStack destinations/path entries or a broader routing change; a custom global drag is not equivalent to native interactive pop. Check cancellation and horizontal-control conflicts. Do not replace all visible navigation with gestures. Back means earlier step/parent; Close means end/dismiss task.

Apple primary sources gathered by the research agent:
- NavigationStack: https://developer.apple.com/documentation/swiftui/navigationstack
- Gestures: https://developer.apple.com/design/human-interface-guidelines/gestures
- Toolbars: https://developer.apple.com/design/human-interface-guidelines/toolbars
- Sheets: https://developer.apple.com/design/human-interface-guidelines/sheets
- Modality: https://developer.apple.com/design/human-interface-guidelines/modality

Verification: previous/next teaching index survives close/reopen and restart; committed answers stay immutable and no duplicate attempts are added; visible Back and Close remain separately understandable in KO/EN and VoiceOver; edge-swipe cancellation and horizontal slider/grid/table conflicts; sheet vertical dismiss; normal/AX5 footer reachability and Reduce Motion. Static code does not prove physical gesture behavior.
