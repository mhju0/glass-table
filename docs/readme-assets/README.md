# README screenshot provenance

The four README images are unedited simulator screenshots of runtime commit
`003f997`. Final runtime `1f5cf33` changes only the equity drill, not these views.
They are local repository updates, not a claim of GitHub or App Store publication.

- Captured on 2026-09-23 with `tools/uisweep.sh`.
- Device profile: iPhone 12 mini, disposable simulator.
- Public images use the normal `large` content-size category.
- All 32 fixtures were captured in Korean/English, Light/Dark, and normal/AX5
  sizes. Representative captures were visually inspected; interaction tests
  separately verify navigation, chart cells and large-text reachability.
- Source sweeps below remain local in `.build/beginner-native-release/.uisweep/`
  relative to the primary checkout. Generated captures are not committed.
- These are seeded debug fixtures, not the owner's private progress or evidence
  that real users have achieved the displayed results.

| README image | Fixture | Language / appearance | Sweep directory |
|---|---|---|---|
| `readme-01-learn.png` | `learn` | Korean / Light | `20260923-173614-goCPDR` |
| `readme-02-opponent.png` | `opponent-details` | English / Dark | `20260923-174529-xuqVtY` |
| `readme-03-play.png` | `play-hand` | Korean / Dark | `20260923-174528-IDJecL` |
| `readme-04-chart.png` | `table-chart` | English / Light | `20260923-172354-7iKK29` |

See [the native delivery record](../specs/2026-09-23-beginner-native-release.md)
for test results, the later compact-equity correction, and remaining release gates.
