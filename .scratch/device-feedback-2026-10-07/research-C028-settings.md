# C028 — Compact Settings and feedback preferences

User wants smaller language/appearance controls lower on the page, sound and haptics switches, and comparison with other apps. Repository audit is pending. No native changes during active testing.

Initial official-source research (2026-10-07):
- Duolingo shows separate Sound effects and Haptic feedback preferences under Lesson experience: https://blog.duolingo.com/learning-with-hearing-aids/ and https://blog.duolingo.com/duolingo-101-how-to-learn-a-language-on-duolingo/
- Signal places theme behind Appearance > Theme: https://support.signal.org/hc/en-us/articles/360007320951-Chat-Colors-Wallpaper-and-Themes
- Signal language documentation distinguishes in-app options from iOS per-app language settings: https://support.signal.org/hc/en-us/articles/360049188372-Language-Options
- Apple explains supporting system appearance changes: https://developer.apple.com/design/human-interface-guidelines/dark-mode

These documented examples support investigating compact grouped rows and independent feedback preferences; they do not establish identical current screenshots or that any competitor ordering is optimal for Glass Table. Proposed organization and compact native controls remain to be compared in the final report. Preserve a System appearance option if currently supported; use switches for binary sound/haptic preferences, not as an automatic replacement for multi-option appearance.
