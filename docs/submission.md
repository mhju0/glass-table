# App Store submission — v1.0 (1)

Single source of truth for everything entered into App Store Connect.
Field limits: name 30, subtitle 30, keywords 100, promotional text 170,
description 4000 characters.

## App record

| Field | Value |
|---|---|
| Name (both locales) | Glass Table |
| Primary language | Korean |
| Bundle ID | com.michaelju.glasstable |
| SKU | glass-table-ios |
| Price | Free |
| Availability | All territories |
| Category | Education (primary), Games – Card (secondary) |
| Support URL | https://github.com/mhju0/glass-table |
| Privacy policy URL | https://mhju0.github.io/glass-table/privacy-policy.html |
| Copyright | 2026 Michael Ju |

## Korean (primary) metadata

**부제 (subtitle):** 아웃 · 팟 오즈 · MDF 계산 훈련

**프로모션 텍스트:** 레인지와 EV로 생각하는 포커. 하루 몇 분, 다섯 가지 수학
드릴로 감이 아니라 계산으로 결정하세요.

**키워드:** 포커,홀덤,팟오즈,아웃,에퀴티,MDF,블로커,포커수학,연습,드릴,훈련,계산

**설명:**

Glass Table은 노리밋 홀덤을 레인지(range)와 EV로 생각하는 법을 훈련하는
무료 학습 앱입니다.

다섯 가지 수학 드릴:

• 아웃 카운팅 — 드로우의 아웃(out)을 세고 룰 오브 2/4로 에퀴티를 추정
• 팟 오즈 — 콜 가격을 필요 에퀴티(%)로 변환
• 콜/폴드 — 추정 에퀴티와 필요 에퀴티를 비교해 결정
• MDF — 벳 사이즈에 따른 최소 방어 빈도 계산
• 블로커 — 블로커가 콤보(combo) 수를 어떻게 바꾸는지 계산

모든 문제는 "결정 → 공개 → 채점" 루프로 진행됩니다. 먼저 스스로 답을
정하고, 그다음 정확한 수치와 풀이를 확인하세요. 정확/근접/빗나감 채점과
스트릭이 반복 훈련을 이끕니다.

이런 분을 위해 만들었습니다:
• 감이 아니라 근거로 결정하고 싶은 진지한 아마추어
• 팟 오즈와 필요 에퀴티 변환을 자동으로 만들고 싶은 분
• 이론 책·영상으로 배운 개념을 손에 익히고 싶은 분

특징:
• 완전 무료 — 광고, 인앱 결제, 계정 없음
• 완전 오프라인 — 네트워크 연결과 데이터 수집이 전혀 없음
• 진행 기록(스트릭, 정답률)은 기기에만 저장
• 한국어/영어 병기 용어집 내장

Glass Table은 학습 도구입니다. 실제 돈이 오가는 도박 기능은 없습니다.

## English (U.S.) metadata

**Subtitle:** Outs, pot odds & MDF drills

**Promotional text:** Think in ranges and EV. Five daily math drills to make
poker decisions by calculation, not feel.

**Keywords:** poker,holdem,texas,outs,pot odds,equity,MDF,blockers,drills,trainer,study,math

**Description:**

Glass Table is a free study app that trains you to think about No-Limit
Hold'em in ranges and EV.

Five math drills:

• Outs — count your draw's outs and estimate equity with the rule of 2/4
• Pot odds — convert a call price into required equity (%)
• Call/Fold — compare estimated vs. required equity and decide
• MDF — compute the minimum defense frequency for a bet size
• Blockers — work out how blockers change combo counts

Every spot runs a decide → reveal → grade loop: commit to your answer first,
then see the exact numbers and the reasoning. Exact/close/miss grading and
streaks drive the reps.

Built for:
• Serious-minded amateurs who want reasons, not vibes
• Players who want pot-odds-to-required-equity conversion to become automatic
• Anyone drilling the concepts they learned from books and videos

Features:
• Completely free — no ads, no in-app purchases, no account
• Fully offline — zero networking, zero data collection
• Progress (streaks, accuracy) stays on your device
• Built-in bilingual (Korean/English) glossary

Glass Table is a study tool. It contains no real-money gambling.

## Age rating questionnaire (answers of record)

Strategy per `decisions.md` §7: honest answers, study-tool build, expected
12+/KR-15 or lower on the self-rating track. (Apple's revised global
age-rating tiers read 13+/16+/18+ — if the live questionnaire shows those,
"12+" here means the lowest non-18+ tier and "17+" means 18+/top tier.)

| Question | Answer | Rationale |
|---|---|---|
| Violence (cartoon/realistic), horror, sexual content, nudity, profanity, drugs/alcohol/tobacco, medical info | None | Absent from the app |
| Simulated Gambling | **Infrequent/Mild** | Poker-themed calculation drills; no wagering, no chips staked, no betting gameplay, no virtual currency. Conservative honest answer for a poker-subject app |
| Real-money gambling / contests | No | Free study tool, no money in or out |
| Unrestricted web access | No | No networking at all |
| User-generated content / communication | No | None |
| In-app purchases | No | None |

**Record after answering:** actual computed rating = ____ (expected 12+ /
KR-15 or lower). If 17+/KR-19: STOP before submitting; trigger the
contingency in spec §4 (GRAC direct review follow-up).

## App Privacy (nutrition label)

**Data Not Collected** — answer "No, we do not collect data from this app."
True because: no networking, no analytics, no accounts; progress JSON never
leaves the device.

## Review notes (entered at submission)

Glass Table is a free educational study tool for No-Limit Hold'em poker
mathematics, aimed at Korean-speaking players (UI is Korean-first).

- No real-money gambling, no wagering, no virtual currency, and no simulated
  betting gameplay. The app contains only calculation drills: counting outs,
  converting pot odds to required equity, minimum defense frequency, and
  card-combination (blocker) counting.
- Fully offline: no account, no login, no in-app purchases, no ads, no data
  collection.
- No demo account is needed; all content is available on first launch.

## Screenshots

One iPhone 6.9" set (1320×2868, from iPhone 17 Pro Max simulator), reused for
both locales: `docs/store-assets/ko-0[1-5]-*.png` — home, outs reveal,
pot-odds question, stats, glossary.
