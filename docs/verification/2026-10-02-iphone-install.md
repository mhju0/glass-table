# iPhone 12 mini installation, 2026-10-02

Current Direction A app source at b0c0e35 was built in Release with the existing
Apple Development signing identity and installed in place on the connected
physical iPhone 12 mini (iOS 27.0.1). Installed version: 1.0 (14), bundle
com.michaelju.glasstable. No source/signing-setting/schema change or uninstall.

XcodeGen, signed device build, tools/verify_release.py and strict deep codesign
verification passed. Device install and launch succeeded. Root inspected the
actual phone-ready.png showing the Learn landing screen and saved lesson.
The first immediate screenshot captured a white launch frame; it is retained
as early-frame evidence, not accepted as loaded UI.

The existing progression.json was copied read-only before installation and
again after install and launch. All three copies are byte-identical (4114 bytes).
Private copies remain ignored under .build/direction-a/iphone-install and are
not embedded in the report or committed. No progress/prefs reset was performed.

New Xcode MCP used for session/default/build-setting inspection; physical-device
workflow tools were not enabled, so Apple's devicectl and xcodebuild performed
the actual device build/install/capture. MCP show_build_settings returned Debug
settings despite configured Release defaults; it is not Release evidence. The
explicit signed xcodebuild command and resulting app establish Release.

Exact commands, logs, executable hash, verification.json and screenshots remain
in .build/direction-a/iphone-install. Installation and observed Learn landing do
not prove every phone flow, VoiceOver or haptic feel; owner checks still apply.
No App Store/TestFlight submission or redesign GitHub push occurred.
