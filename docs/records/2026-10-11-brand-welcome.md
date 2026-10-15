# Brand welcome exploration (build 21 feedback)

- **Date:** 2026-10-11
- **Kind:** research
- **Originals:** `docs/reports/2026-10-11-brand-welcome/` (index.html, prototype.html, research.md, verification.json, assets/ with 36 proposal PNGs, before-native-build21.png and three Pretendard OTF files) (tracked: `git show f5c5e22:<path>`)
- **Asked by / for:** owner feedback on build 21: the app starts in the guide ("Getting started" / 시작 안내, "Try one simple hand" / 카드 한 번만 비교해 볼까요) with no app-title welcome. Explore one green Glass Table + Start screen and revise the next guide screen to avoid duplication.

## What it was
HTML exploration of three welcome options and the welcome -> guide transition. No native edits, builds, reinstall or progress change; installed app stayed 1.0 (21).

## Findings and decisions
- Option A, quiet brand (agent recommendation): centered "Glass Table" and one bottom Start; the next screen teaches a pair immediately, replacing the text-only guide preamble.
- Option B, type-led invitation: large left-aligned two-line title plus one sentence; guide puts pair teaching in a demonstration panel and moves the no-timer/help promise into contextual help. Slightly delays the first card interaction.
- Option C, cards as identity: card emblem before the title, one bottom Start; card-outline geometry carries into the pair example. Risk: emblem looking tappable or a casino splash.
- Shared rules: welcome uses table green #153D33 in both modes (deeper #102A23 offered for comparison); guide uses paper #EBE6DB or charcoal #17191C with an explicit guide heading so color is not the only cue. Start stays in the same bottom action area as the guide's next step; amber keeps its role.
- No knowledge quiz at the front, no extra "ready?" page; Skip guide stays in the guide header and never grants completion credit.
- First-run only: not a gate on every launch; returning users resume; guide replay starts at the guide, not the brand screen. No timer, loop or delayed button; Reduce Motion gets a static equivalent.
- EN/KO: brand name stays "Glass Table"; normal line groups paired, Korean wraps at words, large text reflows.
- Implementation must preserve question seeds, saved guide steps, skip/resume, progress and recovery; the welcome must not reset or re-assess learners.
- Sources (research.md): Apple HIG Branding, Onboarding, Launching (OS launch screen is separate from the tappable welcome), Color.
- Screenshots: native before frame confirmed build 21 opened on the guide; 36 HTML captures (24 normal welcome/guide, 12 guide at 165% text) showed each option in EN/KO x light/dark.

## Outcome
- Verification (browser only): 24 flow combinations passed (3 options x EN/KO x light/dark x normal/165%); Start, guide, explanation, Back and Skip worked; normal guide line groups heading 2/2, explanation 2/2, note 1/1; primary button geometry identical across 24 normal frames; report at 390/1440 px without overflow, all 43 image instances loaded, 0 console errors.
- The owner chose option C (not the recommended A) and also asked to remove the experience assessment and the midpoint stopping prompt, per `docs/build-history.md`. Shipped in build 22 (2026-10-11): green brand welcome with bottom Start leading to pair teaching (7549a32, 6480c42; final native source 113e27b), freshly installed on iPhone 12 mini with the green Korean welcome observed. Follow-up 5f22fbc (2026-10-12) moved Skip under Start on the brand screen.

## Still open
- No engagement or retention effect established; native Dynamic Type, VoiceOver and safe areas were outside this HTML study (implementation verification happened in build 22, with novice comprehension, physical VoiceOver/thumb comfort and minimum-iOS 17 runtime still listed as remaining there).
