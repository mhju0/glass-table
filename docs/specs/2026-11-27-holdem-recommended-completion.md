# Recommended Hold’em completion journey

Base candidate is `f34a69c39e4371cfb78bd72d9153be0ebc0e7678`. Use the frozen follow-up commit and its companion run log for independent review. [Original curriculum ledger](2026-11-27-holdem-mastery-course.md) · [Teaching review and first corrections](2026-11-27-holdem-mastery-teaching-review.md)

## Playable path and active-minute model

[Verified] Learn recommends the next unfinished activity. The existing core leads to Read Hands (R1–R10), then Decide Hands (S1–S11). The original course completion remains earned and visible. Learn adds a second completion marker for finishing the recommended journey. A learner can finish at their own pace, and scores do not gate progress. The final case provides six scored decisions with feedback in sequence. Completion records practice across the published skills.

| Learn activity | Reachable first-pass work | Planning rate, minutes per beat | Modeled active minutes |
| --- | ---: | ---: | ---: |
| Existing recommended core, worked screens | 88 | 1.00 | 88.0 |
| Existing recommended core, first decisions | 274 | 1.25 | 342.5 |
| Read Hands R1–R10, worked flops and first decisions | 10 + 60 | 1.15 and 1.45 | 98.5 |
| Decide Hands S1–S10, worked flops and first decisions | 10 + 60 | 1.15 and 1.45 | 98.5 |
| Decide Hands S11, fresh final case | 6 | 1.45 | 8.7 |
| **Recommended total** | **508** | | **636.2 (10 h 36 min)** |

[Inferred] These rates model a novice who reads each hand state, reasons before selecting an answer, and reads first-pass feedback. The old 480.4-minute figure used the prior budget’s correction assumptions. The revised model applies a first-pass estimate to the same 88 worked screens and 274 decisions and adds only the 146 new beats above. It assigns zero required minutes to exact retries, optional fresh review, electives, external reading, setup, waits, passive elapsed time and unlimited Free Play. Timing is unmeasured. If novices average under about 94% of the modeled rates, the typical total will fall below 600 minutes.

## What the cases and reviews cover

[Verified] Twenty-one original heads-up cases use cash-game chip EV with a stated range or an exact assumed opposing hand. Each covers the preflop position or call, flop blockers or range filtering, a changed turn board, a pot and price decision, a 44-river call-versus-fold calculation, and the best-five showdown. Each worked flop reconstructs the pot from contributions. The last case uses a fresh deal and opens with the decision itself. Showdown feedback identifies the best fives, and the equity question credits half of each tie. Position and pot-price rules are explicit. The model assumes no rake, folded blinds only where stated, and an all-in checkdown after the call. It supports these specified lines. A real opponent’s range would require a separate estimate.

[Verified] Every first-pass miss keeps the exact question and original option order for the end-of-lesson correction. New case results also retain which of four topics the learner missed on first attempt. Optional Fresh hand review draws two different hands per missed topic, for up to eight decisions across preflop/position, range/board, price/EV and showdown. Each topic has two reserved questions. Repeating that optional session can reuse the same hands. The learner may continue straight to the next case.

[Verified] Review earlier course topics draws from the earlier enrolled scope, up to 75 objectives backed by 219 variants, including earlier elective sets when enrolled. It excludes the ten later D7–N3 reserved next-day questions and the new Read Hands and Decide Hands cases. In-flight review sessions retain their saved question composition. The earlier D7–N3 next-day retrieval remains separately reachable. Fifteen elective lessons, the guided hand, and Free Play are outside this budget.

## Source boundaries

- Live betting procedure and action order use the published TDA rules as reference. The new hands specify cash-game assumptions and teach ordinary dealing and chip accounting. [Poker Tournament Directors Association rules](https://www.pokertda.com/view-poker-tda-rules/)
- Position and the relation between pot odds and equity follow the concepts in Kevin Desmond’s MIT lecture materials. The examples, range hypotheses and multi-street hands here were authored for this app. [MIT OpenCourseWare, Basic Strategy](https://ocw.mit.edu/courses/15-s50-poker-theory-and-analytics-january-iap-2015/resources/basic-strategy/) · [MIT video](https://learn.mit.edu/video/10292/basic-strategy?playlist=10289)
- The optional hands use retrieval with changed examples. Retrieval and transfer studies and the distributed-practice synthesis informed the exercise design. None provide a timing estimate for this app. [Roediger and Karpicke, test-enhanced learning](https://pubmed.ncbi.nlm.nih.gov/16507066/) · [Butler, repeated testing and transfer](https://doi.org/10.1037/a0019902) · [Cepeda et al., distributed practice](https://pubmed.ncbi.nlm.nih.gov/16719566/)

## Formative learner timing protocol

Recruit at least six Hold’em novices for a first pilot, with both English and Korean represented. Start each person from first entry to Learn and follow the recommended route across sessions of their choosing. Record locale, prior experience, activity IDs, first-pass score, and whether each activity was reached or abandoned. Use an observer’s timer for active reading, deliberation, selection and feedback. Pause it on interruptions, idle time and app backgrounding. Record exact corrections, electives, Free Play and the optional fresh review separately. Offer the fresh review two to four days later, log the delay, and ask the learner to explain one price and one board or range decision. Keep those checks outside required time and retain only consented, anonymized pilot notes.

Report per-learner totals, median and interquartile range by activity and locale when there are enough observations, completion and abandonment counts, and thin samples explicitly. Use measured first-pass behavior to recalibrate per-row rates. If the median is below 600, add distinct instruction or decisions where learners need them. The app has no time prerequisite. This pilot assesses pace, comprehension and routes. It cannot establish professional proficiency or long-term retention.

## Candidate checks

[Verified] Package tests audit bilingual structure and option distinctions, 21 unique class hands, preserved core inventory, exact retries and selected fresh topic coverage. The schema 15 and schema 16 fixtures cover pre-upgrade byte preservation, original saved scores and a selected unsubmitted fresh review. Native route outcomes and simulator cleanup belong in the evidence attached to the frozen commit. The independent teaching and bilingual review and the formative timing pilot remain separate acceptance evidence.
