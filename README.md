# Glass Table

An offline iPhone app for learning No-Limit Hold'em in Korean and English. Short lessons, practice exercises and a table with computer opponents help beginners explore cards, ranges, probability and decisions. Chips have no real-world value; there is no real-money wagering.

The app has been distributed through TestFlight. [Support](https://mhju0.github.io/glass-table/support.html) · [Privacy](https://mhju0.github.io/glass-table/privacy-policy.html)

## Engineering

- A SwiftUI app sits over two independent Swift packages: `GlassTableDrills` for exercises and progress, and `GlassTableEngine` for poker evaluation and equity.
- Seeded generators keep a question, grade and explanation tied to the same spot. Graded postflop decisions disclose their checkdown approximation rather than presenting it as universal strategy.
- Progress stays on device. Versioned persistence preserves recovery data during migrations, and progress can be exported or imported through Files.

## Development

Requires macOS, Xcode 26+, and [XcodeGen](https://github.com/yonaskolb/XcodeGen); the deployment target is iOS 17.

```sh
xcodegen generate
open GlassTable.xcodeproj
swift test --package-path GlassTableDrills
swift test -c release --package-path GlassTableEngine
```

[Product brief](docs/product-brief.md) · [Design](DESIGN.md) · [Learner-trust audit](docs/specs/2026-09-20-learner-trust-audit.md) · [Build and release](docs/ci-cd.md)

## License

Copyright (c) 2026 Michael Ju. All rights reserved.

No license is granted for use, copying, modification, or distribution of this
code as of 2026-07-30. This repository is public for portfolio review purposes
only.
