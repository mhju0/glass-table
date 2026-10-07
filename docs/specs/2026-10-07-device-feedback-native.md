# Device feedback native delivery

Approved scope: all 28 comments from the October 7 iPhone 13 mini session, plus
same-voice results, portrait position boxes, bottom primary actions and paired
English/Korean normal-size layout. This implements the reviewed HTML direction
in SwiftUI; it is not an App Store submission.

## Decisions

- Welcome precedes the optional starting check. Existing learners keep their state.
- Start with winning hands and turn-changing cards before counting and percentages.
  Stable node IDs, challenge membership and saved question formats remain unchanged.
- First guide keeps its short pair warm-up and offers three more comparisons:
  trips, straight and flush. Standalone guide visits rotate seeded examples;
  saved active sessions retain their original seed/index.
- New Defend lessons select a seed covering Fold, Call and Re-raise across the
  three graded questions. Existing generator outputs and saved answers do not change.
- Beginner count/estimate/range questions have two or three tap choices. Advanced
  confidence collection stays optional; unsolicted ranges do not enter calibration.
  RangeRead exclusion accepts up to 100 rather than 40 to represent the actual
  late-seat call band; existing valid answers keep identical grading.
- Wrong results show separate aligned label/value rows. Correct results show one
  confirmation. Winner values use the same app voice in live and restored results.
- Position teaching uses eight numbered boxes, clockwise arrows and full plain
  labels before optional acronyms. Both preflop and postflop turns are demonstrated.
- Pot guides explain blinds before contribution accumulation. Earlier equations
  remain visible; the final total stays covered until the learner chooses.
- Guides provide Previous and edge back; question/table edge back pauses the
  activity. Modal Close uses an x, distinct from the left Back arrow.
- Help remains reopenable. Essential guidance is not a two-second disappearing
  message. A covered example has Check example before Finish example.
- Bottom action areas reserve space rather than overlap the main content. Larger
  text can expand and scroll. Matched paired labels never shrink to fit Korean.
- Notation and charts explain same/different suits, row/column ranks, pairs,
  upper-right suited cells, lower-left offsuit cells and policy colors. Chen
  arithmetic is optional detail, not a prerequisite for the first decision.
- Beginner Defend charts are visible and can be hidden/reopened. Private existing
  help-credit semantics remain; no public assisted/solo category is added.
- Outs are grouped by both players' complete best-five rank signatures and winner,
  preserving kickers and suit-specific selection. Each group explains the result.
- Free Play help destinations are Decision help, Hand history and Table guide.
  Seat names are Tom/Mike/Alex and 토마스/마이클/알렉스, derived from seat index.
- Quick Game stores each settled hand for recap/review after relaunch. Counts have
  denominators and disclose the simplified beginner chart. No inferred luck or
  learner bluff intent is claimed. End/Start new game explicitly confirms loss of
  an unfinished hand while retaining settled records; Close still pauses.
- Progress adds compact track completion bars alongside existing date markers and
  topic detail. It does not infer skill improvement from completion alone.
- Settings uses compact language/appearance menus lower on the page and sound/
  haptic toggles. Sound defaults off; haptics default on. Actual bundled subtle
  effects honor these preferences; notification sound remains separate.

## Persistence boundaries

Schema 2 adds default-empty QuickPlay archives and an optional active session ID.
Each session has a distinct UUID; snapshots replay-validate independently and
across consecutive hands. Capture and table mutation share one atomic commit.
Retention is 20 ended sessions plus all hands of the active session. Legacy games
honestly declare partial coverage. Import rejects malformed present archives;
failed writes preserve published state and recovery/export/retry paths.

## Verification record

Final build, native interaction results, captures, independent frozen-candidate
review and signed device installation evidence live in `.build/` during delivery.
Tests do not establish beginner comprehension, physical VoiceOver/haptic perception
or minimum-iOS rendering. These remain device/user checks, not claims of zero UX
errors. HTML illustrations are not native screenshots.

Owner reinstall policy: every requested reinstall erases the app's local data
unless the owner explicitly asks to preserve it for that reinstall. No phone
progress is copied off-device without a request.
