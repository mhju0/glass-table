# Chessmate benchmark and naming proposal

Research date: 2026-09-18. Advisory only; no app rename or product changes.

## Evidence boundary

Inspected Chessmate's public App Store screenshots, description and release history, not its installed app. Compared with the current clean revamp checkout's TodayView, NodeSessionView, delivery report and archived Path screenshot. This is not a hands-on competitor usability test. An archived today-empty image was blank and was excluded from visual conclusions.

## Benchmark

Chessmate presents a focused opening-training promise. Its screenshots show a visual course catalog, board-centered lessons/review and a completion state. Its release history describes learning one line then recalling it during onboarding. These are advertised capabilities, not independently tested behavior. [App Store listing](https://apps.apple.com/us/app/chess-openings-chessmate/id6780793638)

Glass Table already implements worked examples, supported practice, independent questions, scheduled review and mixed checkpoints across nine units and eighteen concepts. Today recommends a single next action. Source: GlassTable/Sources/Screens/TodayView.swift, NodeSessionView.swift and docs/specs/2026-09-14-revamp-delivery.md.

Recommended priorities, based on learner perspective:

1. Make the first experience a small successful decision with explanation, then a different situation testing the same idea. Keep the rules guide available without making it a reading prerequisite.
2. Add concrete situation previews and plain-language outcomes to course discovery. Preserve precise concept names as secondary labels.
3. Connect individual drills to table decisions, explaining assumptions and why good decisions can still lose individual hands.
4. Present completion as demonstrated skills and next practice, without equating completion with professional mastery.
5. Build store screenshots around a recognizable hand, an understandable explanation, later recall and table application.

Keep the accepted Warm palette and Korean coaching. Copying visual branding would not address the learning opportunity. Retain offline access and no accounts or monetization. These are proposed refinements, not claims that the benchmark proves effectiveness.

## Naming

Recommend English store title **Poker Lessons — Glass Table** (27 characters), Korean **포커 배우기 — Glass Table**, and short display name **Glass Table**. Alternative: **Glass Table: Poker Trainer**. Suggested Korean subtitle: **홀덤 기초부터 확률과 판단 연습까지**. English subtitle, when an English experience is supported: **Learn Hold’em. Practice Skills.**

The category and learning intent become clear while the brand remains recognizable. Apple permits a 30-character name and subtitle and identifies title/metadata relevance as a search factor. It does not guarantee a ranking improvement from this change. Name availability and trademark clearance are unverified; English metadata does not establish English app support. [Product page guidance](https://developer.apple.com/app-store/product-page/), [Discovery guidance](https://developer.apple.com/app-store/discoverability/)

This proposal does not require changing bundle identifiers, package names or progress-file locations.

## Follow-up implementation proposal

User priorities: hands-on first experience before introduction; approved naming direction; complete human Korean copy review; clean alignment, spacing and balanced wrapping. Account creation was tentative, not authorization to add authentication. This section is a plan, not implemented behavior.

First use should teach one small rule, ask for a choice, explain the result and test the same idea with different cards. Start with a deliberately simple pair comparison rather than EV arithmetic. Present complete legal Hold'em hands, keep the board unpaired with no possible competing flush/straight in the chosen hands, and verify both fixtures with Engine. Only after the learner tries the task, introduce the broader learning path. Allow skipping and replay; returning learners keep their existing progress. Guided attempts must not award independent mastery. Test interruption and resume without duplicating assessed answers.

Recommend keeping Korean as the first fully polished language. Prepare user-facing text for localization, with semantic keys, parameterized numbers and Korean particle handling. Add English only with a fully reviewed course and feedback experience; defer six additional languages. Store metadata alone must not imply unsupported app languages.

As of the research date, the US listing offers Premium weekly $5.99, monthly $7.99, yearly $34.99, a yearly offer $24.49 and lifetime $79.99. These establish listed monetization options, not revenue, offer eligibility, free-course limits or paywall timing. The listing reports English plus seven other languages, eight total. Source: App Store listing above. No purchases or account changes are proposed for this implementation.

Copy and typography acceptance criteria:

- Inventory every visible string, including generated explanations, hints, errors, recovery messages, empty states, accessibility labels and dynamic count variants.
- Use calm 해요체, explain the observed hand specifically, introduce technical terms in context, and label buttons by their actual next action.
- Preserve mathematical meaning, disclosed assumptions and distinctions between guided practice, independent evidence and hand outcome.
- Define consistent title, body, caption and button styles with role-appropriate scaling, line spacing, paragraph spacing and shared leading edges.
- Remove single-word dangling lines in reviewed standard-size layouts by editing copy or adjusting available width. Do not stretch spaces to justify paragraphs, shrink body text or truncate explanations to force a shape.
- Reserve editorial line breaks for short static headlines with verified width fallbacks. Dynamic content and accessibility sizes must reflow naturally.
- Inspect compact, regular and large phone widths, default and accessibility text sizes, and shortest/longest generated content. Check alignment, bottom controls, VoiceOver reading order and reduced motion.
- A clean build or string search does not establish visual completion; inspect rendered states and exercise the first-use flow.

Delivery order: first-use flow and fixtures; whole-app copy inventory/revision; shared typography and screen layout corrections; localization preparation and approved store naming; rendered and behavioral verification. Preserve the offline product and progress recovery invariants throughout.
