# Numerical statistics audit

Baseline07054d0. Source-inspected Records, QuickPlay recap, interval calibration, EV loss, activity days, FSRS and streaks. No app changes.

## Grades / EV loss / tolerances

Product rules. BestEV−chosenEV is nonnegative; zero/positive-near labels distinct.0.5/2bb bands and estimate tolerances are app choices, not physics or solver truth. Chart mismatch is not chip loss.

## Records, activity, Quick Play and calibration

Arithmetic consistent; display caveats. Exact-or-near uses accepted/total; calibration uses saved intervals only; EVmean uses EV-bearing answers. Recentlog 500; styleup to 200 hands / 30 days; raises among entries denominator differs from PFR. N06,N07,N12 apply.

## Scheduling and dates

Parameters verified; display mismatch. 21 FSRS-6 defaults match live official py-fsrs source; desired retention 0.9 and max 36,500 days match. App deliberately omits learning-state machine and Easy rating. No claim of measured90% learning retention.

Wilson40/100 gives30.94–49.80%;28/40 gives54.57–81.93%.9/10 calibration intervals gives90%. EVlosses1,2,0.2 average1.0667bb, displayed1.1. Style input is up to200unique current-policy hands in30days; labels require100hands,5days,40entries; participation=entries/hands, raise share=raises/entries. Zero entries has no valid rate or Wilson interval, but count display can show0/0. Calibration and EVmeans use their relevant entries in the bounded500answer log.

Detailed streak is stored and can be stale after a gap; subtitle due text truncates whole days and can precede exact due time. Main practice-day overview recomputes calendar days. Last7days means today and six earlier days. Examples/free table excluded from submitted-practice activity. Exact-or-near labels correctly include accepted close grades. Trend intentionally aggregates helped/unhelped practice; only eligible timing is unassisted, uninterrupted and on-target. Preserve approved help-neutral UI.

All21FSRS6 defaults, desired retention 0.9 and36500day cap matched official scheduler source accessed2026-10-11; this app deliberately omits Anki learning-state transitions. Model target is not empirical retention evidence.
