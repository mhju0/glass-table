# Glass Table

**기초부터 레인지와 EV까지, 직접 판단하며 배우는 홀덤**

Glass Table is an offline iPhone learning app for No-Limit Hold'em, in Korean
and English. It combines a recommended learning path, freely available practice,
and a computer table for two to four players. Start with reading cards; build toward ranges,
probability, and the cost of a decision.

[![CI](https://github.com/mhju0/glass-table/actions/workflows/ci.yml/badge.svg)](https://github.com/mhju0/glass-table/actions/workflows/ci.yml)
[![Engine gate](https://github.com/mhju0/glass-table/actions/workflows/engine-gate.yml/badge.svg)](https://github.com/mhju0/glass-table/actions/workflows/engine-gate.yml)
![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue)

> Status: local native build under review. The app has not been released on the App Store.

| Follow a recommendation—or choose | Understand your opponent |
|---|---|
| ![Learn tab with a recommended next activity](docs/readme-assets/readme-01-learn.png) | ![Opponent details with separate entry and raise habits](docs/readme-assets/readme-02-opponent.png) |
| Four main learning tracks and an optional deeper track stay open; a starting-point check can suggest where to begin. | Everyday names lead; numbers and technical terms are optional detail. |

| Practice a complete hand | Explore the chart |
|---|---|
| ![Four-player practice table with public actions and chip counts](docs/readme-assets/readme-03-play.png) | ![Defend chart highlighting the learner's hand](docs/readme-assets/readme-04-chart.png) |
| Four seats, local computer opponents, and a factual review of the chips and cards. | A compact hand summary leaves room for the chart and its enlarged explorer. |

The images use simulator demo fixtures; a fresh install begins without progress.

## Product

Learn begins with a simple hand comparison and a new hand to try. Short lessons
use three questions and pass with two answered alone and exactly right; track
challenges mix at least six. One-skill practice uses five, and review uses up to five.
Worked examples, delayed review, and mixed checkpoints support the learning path. It recommends a next activity without
locking advanced lessons. The optional, untimed starting-point check changes
the recommendation—not completed lessons or earned mastery.

Play defaults to a quick game for you and three computers, with 40 starting chips, ending after 10 hands; two or three players can also be chosen.
A longer 100-chip table, carried stacks, and explicit refills are also available.
Its review reports what happened. Optional beginner-chart coaching is separate
from a calculated strategy grade. A separate heads-up exercise
grades preflop choices against a published chart and postflop choices under a
disclosed checkdown approximation—not universal poker advice.

Progress leads with passed lessons, seven recent practice dates, and topics
to revisit. Submitted lesson, practice, and review answers count regardless of
help use or result. The fourth consecutive recorded practice date adds a small
flame in today’s date cell; missed dates carry no penalty. Free-table play does
not count toward these dates. Detailed answer history, learning stages, and
optional response times remain available below. These records describe activity
in the app, not proven poker proficiency or measured learning effectiveness.

Glass Table is fully offline. It has no accounts, analytics, ads, purchases, or
real-money wagering. Progress stays on device and can be exported or imported
through Files. Saved sessions resume across relaunches. Atomic writes, visible
save failures, validation, and preserved migration/recovery bytes protect the
local record. Language and appearance can be changed inside the app.

## Engineering

```text
GlassTable        native SwiftUI screens and design system
      ↓
GlassTableDrills  pure Swift generators, grading, curriculum, review, persistence
      ↓
GlassTableEngine  pure Swift evaluator, equity, ranges, and board texture
```

The UI is a thin client over two Swift packages that do not import UIKit or
SwiftUI. Seeded generators keep a question, its grade, and its explanation on
the same deterministic spot. The archetype policy and surviving range are data
the learner can inspect inside the app instead of an undisclosed bot decision.

Equity exercises enumerate the remaining boards exactly. The graded table uses
exact heads-up enumeration on the flop, turn and river against each surviving
range combination. That distinction and the
checkdown assumption are part of the explanation, not a claim of optimal play.
Frozen evaluator fixtures and deterministic tests guard the underlying math.

A concrete invariant is that a failed answer save must not publish completion
or advance the question. The app-level ProgressionModel tests exercise failed
writes, retries, duplicate commits, and reopening the saved answer. The UI
refinement changes the presentation without changing those write paths.

Verification is split by boundary: package tests cover poker math and drill
logic, XCTest exercises real navigation and input, and `tools/uisweep.sh`
captures normal and Accessibility XXXL layouts on a disposable simulator. A
screenshot is visual evidence only; interaction tests separately cover scrolling
and reachable controls.

Native refinement scope and acceptance checks are recorded in the
[build 16 delivery specification](docs/specs/2026-10-06-approved-native-ux-delivery.md).
Earlier migration readback is documented in the
[combined delivery report](docs/specs/2026-09-23-beginner-native-release.md).
Physical VoiceOver, novice comprehension, minimum-OS, and distribution checks
remain separate release gates.

## Build and test

Requires macOS, Xcode 26 or newer, and
[XcodeGen](https://github.com/yonaskolb/XcodeGen). The deployment target is iOS
17. The generated Xcode project is intentionally not committed.

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build

swift test --package-path GlassTableDrills
swift test -c release --package-path GlassTableEngine
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO test
```

The engine gate runs in Release because its exhaustive checks are impractically
slow in Debug. Use `tools/uisweep.sh --list` to inspect the available visual
fixtures, or run the full normal and accessibility sweep with
`tools/uisweep.sh`.

## Project notes

- [Design direction](DESIGN.md)
- [Research foundation](docs/specs/2026-09-13-revamp-research.md)
- [Combined beginner release and verification](docs/specs/2026-09-23-beginner-native-release.md)
- [Learner-trust audit and verification limits](docs/specs/2026-09-20-learner-trust-audit.md)
- [Build checks, beginner sessions and useful feedback](docs/validation.md)
- [App Store preparation status](docs/submission.md)
- [Privacy policy](docs/privacy-policy.md)
- [License](#license)

## License

Copyright (c) 2026 Michael Ju. All rights reserved.

No license is granted for use, copying, modification, or distribution of this
code as of 2026-07-30. This repository is public for portfolio review purposes
only.
