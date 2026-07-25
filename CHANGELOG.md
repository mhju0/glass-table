# Changelog

Notable changes to the Glass Table app. Format follows
[Keep a Changelog](https://keepachangelog.com/); versions are tagged
`vMAJOR.MINOR.PATCH` (TestFlight-only builds as `-beta.N`).

## [Unreleased]

### Added
- Home redesign: felt-gradient backdrop, serif masthead with suit rules,
  drill grid with per-mode explanations (2026-07-23)
- 설정 screen (용어집/통계/개인정보 처리방침/버전), plus 첫 핸드 다시 보기
- 첫 핸드: first-run onboarding as one authored hand (AhKh vs QsQd on
  Qh7h2s3c) that asks each of the five drills' own questions in the order the
  hand asks them, guess-before-explanation throughout. Auto-plays once on first
  launch, skippable at any beat, re-enterable from home and 설정. Replaces the
  3분 시작 가이드 text screen (2026-07-25)
- Every drill header carries a permanent one-verb subtitle, and every reveal a
  용어 chip that opens the glossary scrolled to that drill's term
- Outs reveal leads with the natural frequency (남은 44장 중 7장), rule-of-2
  percent subordinate and labelled 근사

### Changed
- New app icon: 4×4 equity-heatmap range grid with the four suits on the
  pair diagonal in card colors (replaces the percent-on-disc mark, 2026-07-24)
- Drill sessions resume where you left off (`progress.total`) instead of
  repeating spot 0 every visit
- 콜/폴드 answer buttons are equal weight (no visual bias toward calling)
- MDF reveal now derives the formula instead of asserting it: alpha = 100 − MDF
  is villain's bluff break-even, so the explanation says whose price it is
- Portrait-only; consistent hidden toolbar backgrounds; 🔥 shows only with a
  live streak everywhere

### Fixed
- Card labels never wrap rank/suit vertically and never touch the card edge
