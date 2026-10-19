# Poker terminology and learning reference

- **Date:** 2026-10-19 · **Kind:** feature notes / verification
- **Originals:** `.scratch/terminology-learning-help/` acceptance notes, consolidated here.
- **Asked by / for:** owner; introduce poker terms accessibly, remove terminology switches,
  improve the glossary and Settings “How learning works”.

## Findings and decisions

- D55: glossary and general skill explanations are active, self-directed learning.
  Looking up definitions, rules or formulas before answering has no scoring effect.
  Only current-question coaching, hints or calculated advice count as assistance.
- Removed both terminology controls and all preference-driven presentation branches.
  Legacy preference bytes are inert; progress schema, generators and grades are unchanged.
- Plain task headings introduce actual terms; table actions retain names, meanings and prices.
  Position diagrams, choices and restored answers retain the same A/B and seat identities.
- Added 56 bilingual entries, Korean/English/alias search, focused definitions and return
  to the caller. Formulas disclose model limits; eight-seat exercise names include LJ/UTG+1.
- Replaced the guide quiz with seven readable topics covering lessons, automatic steps,
  passing, self-directed lookup versus coaching, challenges/review, progress and table limits.
- Independent review of `2b5c60f` found an inherited street ambiguity in Position and
  missing seat aliases. Both were fixed; `b4f9568` passed the bounded delta review.
  Postflop comparison prompts and normal/AX diagrams now explicitly identify the street.
- Guide topic changes reset to the top; same-topic lookup retains reading position.
  The bounded final code delta `2ec36ae` also passed independent review.

## Outcome and evidence

- Core feature: `2b5c60f`; independent review: `5522a12`; final hint copy: `b8ff2cc`.
  [Draft PR #56](https://github.com/mhju0/glass-table/pull/56) is stacked on #55 `ebb0fae`.
- Full Drills: 671 tests passed. Tools: 20 tests passed. Simulator build passed;
  workflow validation and whitespace checks passed. Engine code was unchanged.
- Corrected app unit run: 119 XCTest + 46 Swift Testing tests passed.
- Initial focused native evidence included legacy YES/NO/unset preferences, Korean/English
  search, normal/AX position restoration, chart first-use and free-table dock interactions.
- Corrected preserved-draft/reveal/independent-result flow and all four Position
  identity/street/restoration tests passed on iPhone 12 mini/iOS 26.5.
- Seven AX5 guide lookup roundtrips passed. Earlier failing attempts exposed test
  helpers hitting chrome, querying an inherited identifier incorrectly, or stopping
  before long content ended. Corrected helpers retain normal taps and outcome checks.
- Final AX5 guide test passed all seven topics: every new heading begins onscreen,
  the last lookup is reachable, closing it retains the reading position, and Done
  leaves the guide. Product code `2ec36ae`, final test correction `7c35252`.
  Local result: `/tmp/gt-terms-guide-final-navigation.xcresult`.
- Sampled Settings, glossary, passing guide, Position and free-play action labels
  in KO/dark and EN/light at normal and AX5 sizes were inspected. A faint search
  hint was corrected and explicitly uses Dynamic Type; final four search snapshots
  were inspected and show readable, scaled hints without English shrink-to-fit. Initial frames alone do not establish scroll reachability.
- Independent final delta review cleared `5522a12`, preserving every scoring,
  question-identity and persistence invariant. Both AX5 action-dock tests passed
  across five hand states in each language; all action frames were reachable.
- Final search covered aliases, no-results, clearing, definition return and query
  retention in KO/dark and EN/light at normal and AX5. The long English hint
  shrank in its native field, so the visible hint is now “Search terms” / “용어 검색”;
  its full search-capability accessibility label remains. The four-case search
  recheck passed on final code `b8ff2cc`; screenshots were inspected.
  Local results: `/tmp/gt-terms-final-search-dock.xcresult` and
  `/tmp/gt-terms-search-readable.xcresult`.

## Still open

- No full nightly suite, minimum-iOS runtime, physical VoiceOver or novice session performed.
- CI `39190901552` at `a61b9c2` passed tools, Drills, app unit and all 14 focused
  UI tests; Release smoke failed because it still expected the old guide headline.
  Device Release validation was skipped. Corrected smoke checks real topic IDs and
  Next navigation without demo hooks. Both corrected Release smoke tests passed
  locally on iPhone 12 mini/iOS 26.5 with fresh derived data and no demo hooks
  (`/tmp/gt-terms-release-ci-fix.xcresult`). Replacement CI/device Release validation
  are pending. No app source changed for this CI correction.
- Branch work only: no merge, TestFlight upload or physical-device installation.
