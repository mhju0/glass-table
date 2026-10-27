# The first five minutes: opening research, prototypes and owner feedback (build 19)

- **Date:** 2026-10-10
- **Kind:** research
- **Originals:** `docs/reports/2026-10-10-first-five-minutes/` (index.html, prototype.html, verification.json, assets/prototype.css, assets/prototype.js, assets/before/ and assets/after/ EN/KO screenshots); `docs/research/2026-10-10-first-five-minutes-learning.md`; `.scratch/first-five-minutes/` (feedback.md, history.json, build_report.py, report-desktop.png, initial-example.png) (tracked: `git show f5c5e22:<path>`)
- **Asked by / for:** owner, after a fresh build 1.0 (19) install on the iPhone 12 mini (native source `a3db5fc`, docs `65faf87`). Research and HTML prototype delivery, not a release.

See also: `2026-10-10-whole-app-consistency.md` (the follow-up study after the owner approved these proposals).

## What it was
Owner feedback FFM01-08 on the opening, an evidence review of motivation and learning research, and an HTML report with a clickable prototype of three openings (A, B, C), copy proposals, button/palette/motion trials, a test plan and a reconciled build 1-19 history. `build_report.py` generated the report. No Swift change, no build 20, no phone update. The scratch PNGs only show the report page and the Opening B "Which hand wins?" prototype frame.

## Findings and decisions
Owner feedback (`.scratch/first-five-minutes/feedback.md`):
- FFM01 Start -> poker familiarity feels abrupt; explain the teaching relationship and why the question matters.
- FFM02 Try an easy learning question before self-report, with a neutral unknown/help option.
- FFM03 Treat the first five minutes as central; study motivation, mobile behavior and voluntary return.
- FFM04 Fun, factual progress, professional encouragement without infantilizing.
- FFM05 Research wording, sentence length and attention; separate evidence from intuition.
- FFM06 Explore button size, palette, hierarchy, motion and animation.
- FFM07 Compare openings with before/after screenshots in an organized HTML report.
- FFM08 Keep traceable build numbers, changes, feedback and deployment evidence.

Build 19 as found (source-confirmed): welcome -> Start -> familiarity -> (three starting-point questions for some) -> five comparisons; "New to poker" skips the three questions. Familiarity was unexplained and its "three questions" copy was wrong for the new-user route.

Options and recommendation (agent; reasoned, not proven):
- B, experience first (recommended): brief welcome naming the benefit -> taught pair -> one-tap decision with "Show me first" beside two answers -> explanation for every committed choice -> changed comparison -> factual "2 examples explored" checkpoint offering the remaining 3 comparisons or a stop; familiarity later, only when it changes the next suggestion; "Choose a lesson" exit for experienced users.
- A, explain then ask: conservative alternative; keeps self-report first but explains its purpose.
- C, yes/no/unsure: adds a tap without teaching or routing; not recommended as default.
- Other proposed decisions: unknown answer = neutral "Show me first"; keep amber/warm neutrals and native button/motion tokens; progress counts examples/rules explored, no reward currency or help label.
- Goal: voluntary return through useful, achievable learning, not screen time. No analytics, notification pressure, public help badges, variable rewards, timers or auto-advance; a stopping point is a success. Explanations stay until Next.

Research (each card states its limit; application to poker onboarding is inference):
- Bureau et al. 2022: 144 studies, >79,000 students; competence strongest motivation predictor.
- Bandura et al. 1977: mastery experience beats observation (clinical adult study).
- Sweller & Cooper 1985: worked examples reduce novice search (algebra).
- Roediger & Karpicke 2006: retrieval beats restudy for delayed retention.
- Wisniewski et al. 2020: 435 studies; feedback effect depends on information.
- Harkin et al. 2016: 138 RCTs, 19,951 people; progress monitoring d = .40.
- Henderlong & Lepper 2002: praise effects are conditional.
- Baars et al. 2022: gamification raised autonomous motivation, not use or performance.
- Lally et al. 2010: 96 people; habit formation varies, one missed day immaterial, no 21-day rule.
- Stothart et al. 2015: notifications disrupt attention; no valid universal 8-second attention cap.
- Apple onboarding, buttons, color and motion guidance (platform guidance, not outcome evidence).

Copy and craft:
- One idea per sentence; ~8-16 English words as an editorial start, not a cutoff; 1-2 line heading and 2-3 line intro at 375-390 pt; Korean uses natural phrasing, not word-count conversion.
- Paired EN/KO lines for start, familiarity, correct, wrong, unsure, repeated mistakes, progress, return, stop (e.g. "Try one simple hand. We'll explain each choice." / "쉬운 패 하나부터 볼까요? 선택마다 이유를 알려드릴게요."). Count exposure, never "mastery"; "Welcome back" only when a saved activity exists; avoid "genius", streak guilt, "falling behind".
- Native baselines: primary 54 pt / secondary 50 pt, 14 pt radius, chrome targets >= 44 pt; press spring 0.22 s, scale 0.98; content spring 0.34 s. Trials: 52 vs 60 pt answer rows, muted teal action accent, ~120 ms press and 180 ms fade. Contrast: amber 6.21 light / 10.12 dark; teal 6.75 / 7.66; muted 5.46 / 9.94. No punitive sounds.

Test plan: 4-6 adult beginners per language plus a few players; one opening each, alternate A/B; observe first useful action, terminology confusion, mis-taps, teach-back, help comfort, stopping/return; changed-deal recheck immediately and after 24-48 h with consent; researcher notes, no telemetry.

Build history (FFM08): `history.json` reconciled builds 1-19 (install outcomes for 9, 10, 12, 13 and planned build 1 not located; 17 not a confirmed install); now kept in `docs/build-history.md`.

Screenshots: native before frames (build 19 welcome, historical build 16 familiarity) and 68 HTML after renders showed proposal layouts only, not native behavior.

## Outcome
- Report verification (browser only): 68 proposal screenshots, 64 flow checks, matched normal EN/KO line counts across 17 scenes, 44 px minimum targets, 200% one-scroll action reachability, report at 390/1440 px, 0 console errors, 0 missing local links.
- Owner approved the proposals (WAC01) and asked for whole-app consistency research before building.
- Implemented in build 20 (2026-10-11; source `07054d0`, final production change `132c331`; e.g. 179ccc9, 9b3e030): welcome and pair teaching before assessment, neutral demonstration, factual two-example checkpoint, optional later preference, resumable guide (`docs/specs/2026-10-11-consistent-experience-first-opening.md`).
- Build 22 later removed the experience question and added a green brand welcome (owner chose option C; see `2026-10-11-brand-welcome.md`).

## Still open
- The beginner study (A/B observation, teach-back, delayed retention) was never run; the agent handoff lists real novice comprehension as never verified.
- No tested claim that any palette, size, phrasing or animation improves retention.
