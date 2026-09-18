# Physical-device feedback refinement

The user approved the proposed fixes to IMG_0073–IMG_0076 after trying the previous
Release build on an iPhone 12 mini. This is a local refinement for another round
of user testing, not an App Store release.

## Scope

- Give opponent cards, shared cards and the learner's cards distinct centered
  regions. Use the same card geometry across guides, practice and table play.
- Draw ranks and monochrome suits separately. Keep 10 at the same rank size and
  reserve the same rank/suit slots. Highlight without enlarging a card.
- Keep the hint control in navigation chrome, with a dismissible anchored
  popover. It must not insert a row above the question or obscure the answer.
- Share question, explanation, result and action typography. Preserve scrolling
  at large text sizes rather than shrinking explanatory content.
- Identify the people behind pot-counting actions, distinguish additional chips
  from the total raise, and explain the arithmetic in separate steps.
- Use 따라 배우기, 무승부 and 다시 살펴볼까요? in the relevant interface states.

## Pot-counting correctness

The old exercise used integer blinds 1/2 but labelled the amounts bb. This exercise
now counts chips; other exercises continue to use genuine blind-normalized bb.
The generator assigns stable actors to the opening player, each caller and BB.
The displayed participant count includes blind contributors, including a player
who subsequently folds. Fold actions that add no chips are explicitly omitted,
and the prompt asks about chips contributed up to the displayed stopping point.

The former 3-chip opening raise against a 2-chip BB was below the normal minimum
raise without an all-in exception. The generator now uses opening totals of at
least 4 chips. See [Poker TDA raising rules](https://www.pokertda.com/view-poker-tda-rules/).
The arithmetic still adds only `raise total - chips already contributed`.
Fraction questions disclose whole-chip rounding and show the intermediate value
when rounding is necessary. Running totals appear in explanations after an answer
or during the explicitly worked guide.

No progress schema, storage, scheduling, account or network behavior is changed.

## Verification record

Runtime candidate: `2924509dea411af8061bc6742435823aa9d0b3d1`.
Earlier implementation commits are `06e2fda` (shared UI and pot exercise),
`fce0f9e` (whole-chip formatting), and `7c45375` (test locator only).

- All 335 Drills tests passed after the formatter correction:
  `/tmp/gt-screenshot-feedback-drills-frozen.log`. The final UI-only commit does
  not change that package. Engine and persistence code are unchanged.
- Compact normal UI: pot timeline -> submit -> cumulative explanation -> next
  question passed. The test saved a rendered explanation attachment.
- Compact Accessibility XXXL UI: hint open/explicit close -> unchanged question
  frame -> reachable answer passed; equity input -> submit -> next passed;
  first lesson -> transfer -> course passed; all seven showdown teaching steps
  -> guided practice passed; table fold -> summary -> next hand passed.
- The ordinary-size first lesson and transfer flow also passed.
- After the final Table spacing change, the Table Accessibility XXXL flow
  passed again: `/tmp/gt-screenshot-feedback-table-final.log`.

The initial hint test exposed a hard-to-reach return control. The corrected
popover includes a 44pt close control and passed the repeat test. The initial
equity assertion used the old label 상대; a stale compiled test repeated that
failure. Rebuilding with the new 상대 카드 locator passed the complete flow:
`/tmp/gt-screenshot-feedback-ui-equity-clean.log`. These failed runs are not
counted as passes. The independent code reviewer caught a formatter that stripped
significant integer zeros; its corrected implementation has regression coverage
for 0, 20, 100 and 6.5.

Rendered evidence is retained under `.build/screenshot-feedback-visuals/`.
`preview/` and `compact-initial/` are intermediate captures. Some early captures
were blank launch frames; waiting for the simulator to settle produced real app
frames. The final reviewed compact frames are in `compact-final/`. The normal
pot-reveal attachment is in `ui-initial/9FFED130-9C56-4DC1-BBEB-771887681646.png`;
its typography and cumulative arithmetic remain unchanged in the final candidate.

Physical installation and launch verify that the development-signed app opens
on the connected iPhone 12 mini. They do not replace the user's hands-on testing,
full VoiceOver testing, minimum-iOS testing or App Store validation.

Final delivery confirmation:

- Independent read-only review approved exact runtime commit `2924509` with no
  outstanding source findings.
- Reviewed final normal compact Table, PotMath and first-lesson renders. The
  complete hero cards have clearance above the Table action panel. Blind
  definitions and first-lesson guidance use intentional line breaks.
- Reviewed compact Accessibility XXXL Table and showdown captures in
  `compact-ax/`. Content reflows into scrolling layouts; full interaction and
  answer reachability are supported by the focused UI flows above, rather than
  inferred from a single viewport screenshot.
- The final signed Release build passed `tools/verify_release.py` and strict
  code-signature verification. Build log:
  `/tmp/gt-device-feedback-release-final.log`.
- Installed the final Release artifact on the connected iPhone 12 mini and
  successfully launched `com.michaelju.glasstable` on 2026-09-19.
