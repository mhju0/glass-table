# Changelog

Notable changes to the Glass Table app. Format follows
[Keep a Changelog](https://keepachangelog.com/); versions are tagged
`vMAJOR.MINOR.PATCH` (TestFlight-only builds as `-beta.N`).

## [Unreleased]

### Added
- Home redesign: felt-gradient backdrop, serif masthead with suit rules,
  drill grid with per-mode explanations (2026-07-23)
- 설정 screen (용어집/통계/개인정보 처리방침/버전) and 3분 시작 가이드,
  auto-opened once on first launch
- First-launch guide ends with a CTA into the first drill

### Changed
- Drill sessions resume where you left off (`progress.total`) instead of
  repeating spot 0 every visit
- 콜/폴드 answer buttons are equal weight (no visual bias toward calling)
- Portrait-only; consistent hidden toolbar backgrounds; 🔥 shows only with a
  live streak everywhere

### Fixed
- Card labels never wrap rank/suit vertically and never touch the card edge
