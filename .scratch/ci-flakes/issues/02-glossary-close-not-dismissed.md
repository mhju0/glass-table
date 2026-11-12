# LearningReferenceFlowTests: glossary close sometimes does not dismiss

Status: needs-info

Quarantined on 2026-11-12: the dismissal assertion in
`testGlossarySearchAliasesAndNoResults` runs inside `XCTExpectFailure(..., .nonStrict())`.
The rest of the test still gates. Nothing is retried.

Seen in CI: PR #86, run 43188851154, focused-ui (macos-26, Xcode 26.6, iPhone 17 / iOS 26.2),
third pass (English, AX5). After typing "EV\n" and finding `glossary-entry-ev`, the test
tapped `glossary-close`. The tap was synthesized on the button at {18, 72, 44, 44}, and the
keyboard was already gone. Five seconds later the same sheet was still open, with "EV"
still in the search field, so it was never dismissed (not dismissed and reopened). The same
line failed before 2026-10-26 as an immediate `exists` check; db264c4 added the 5 s wait.

Not reproduced: 6 of 6 local runs (24 close taps) passed on iPhone 17 / iOS 26.1 under
Xcode 27.2.

Unknown: why `dismiss()` from the `gtChrome` close button had no effect. Next step: when it
fails again, record `glossary-close` frame and hittability before the tap, and log in
`GlossaryView` whether the close action ran.

Close when: the cause is fixed and the quarantine removed, or 20 focused-ui runs pass the
assertion; then remove the `XCTExpectFailure` wrapper.

## Comments
