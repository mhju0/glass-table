# M1 sub-project 4 — App Store + GRAC submission (design)

Approved 2026-07-23. The last M1 step (`docs/milestone-1.md` "Rough shape" #6):
ship v1.0 (1) to the App Store, worldwide, with the Korean rating landing on the
self-rating track. Fully manual pipeline (Xcode Organizer, App Store Connect web
UI) — the versioned artifact is the *content* (metadata, questionnaire answers,
policy), not release scripts. Scripts come when releases become frequent.

Decisions made for this spec: proceed **without** Korean game-law counsel
(open-questions #11 — Math Drills is the lowest-signal build and the GRAC
direct review is an administrative fallback, not a wall; counsel is revisited
before the betting-table milestone), **worldwide** availability, store name
**"Glass Table"** in both locales, and a **TestFlight internal pass** before
review.

## 1. Apple Developer enrollment (step zero)

Enroll in the Apple Developer Program (individual, $99/yr) as Michael Ju. Not
yet enrolled; identity verification can take days, so this starts first and
steps 2 and 6 proceed in parallel while it clears. Everything from step 3 on
is blocked by it.

## 2. Repo prep

- `project.yml`: `PRODUCT_BUNDLE_IDENTIFIER` → `com.michaelju.glasstable`
  (normalize the doubled suffix before first upload makes it permanent).
- `project.yml` info properties: `ITSAppUsesNonExemptEncryption: NO` — the app
  has zero networking, so it is export-compliance exempt and this skips the
  per-build compliance question.
- Signing: remove `CODE_SIGNING_ALLOWED: NO` for release builds; automatic
  signing with the enrolled Team ID (added to `project.yml` once known).
- Version stays `1.0` (build `1`).

## 3. App Store Connect record

App name **Glass Table** (same in Korean and English locales), primary language
**Korean**, bundle ID `com.michaelju.glasstable`, price **free**, availability
**all territories**. No IAP, no ads, no account — nothing else to configure.

## 4. Age rating questionnaire

Answer Apple's questionnaire honestly toward the documented strategy
(`docs/decisions.md` §7): simulated gambling **Infrequent/Mild** — the app is
calculators/drills with no betting UI, no wagering, no currency. Expected
outcome **12+ / KR-15 (or lower)** on the self-rating track. Every answer is
recorded in `docs/submission.md` so later milestones re-answer consistently.

**Contingency:** if the resulting rating is 17+/KR-19, **stop before
submitting**, record the outcome, and switch to the GRAC direct-review fallback
(~10–15 business days, fee, gameplay video) as a separate follow-up — that
path is documented in `risks.md` and is a valid M1 exit ("either outcome
validates the compliance path", `milestone-1.md` §3).

## 5. Privacy

Nutrition label: **Data Not Collected** (true — no network, no analytics, no
accounts; progress JSON never leaves the device). Apple still requires a
privacy policy URL: a one-page bilingual policy authored at
`docs/privacy-policy.md`. Hosting: the repo is currently **private**, so its
GitHub Pages is unavailable on the free plan — either make the repo public
(it's MIT-bound by workspace convention anyway) and enable Pages, or publish
the policy as a public Gist. Owner's call, recorded before step 3.

## 6. Metadata + screenshots

Drafted and versioned in `docs/submission.md`: Korean and English (U.S.)
subtitle (KO carries the explanation, e.g. 포커 수학 훈련), description,
keywords, promotional text, support URL (the GitHub repo). Screenshots: one
iPhone 6.9" set (~5 shots: home, an active drill, reveal/grade, stats, 용어집)
captured with the existing simulator recipe + `GT_DEMO_*` hooks. No iPad set
(iPhone-only target), no app preview video.

## 7. TestFlight internal pass

Archive in Xcode Organizer, upload, install on the developer's own iPhone via
TestFlight internal testing (no beta review needed). Hardware sanity checklist:
Pretendard fonts render, haptics fire on reveal, Dynamic Type at large sizes,
light-mode lock, icon on the home screen. Fixes found here loop back to the
repo before submission.

## 8. Submit for review

Submit the TestFlight-verified build with English review notes stating: free
educational study tool, no real-money play, no wagering, no IAP/ads/accounts,
fully offline. **Done when** the app is Ready for Sale worldwide with a
12+/KR-15-or-lower rating — or the KR-19 contingency in §4 is triggered and
recorded, which closes this sub-project and opens the GRAC follow-up.

## Verification

Repo side: app builds and archives with the new bundle ID and signing settings;
the 31 GlassTableDrills tests stay green; `git diff main -- GlassTableEngine`
stays empty (release gate not needed). Pipeline side: verification is the
external gates themselves — TestFlight install succeeds on hardware, review
passes, the store listing shows the expected rating in the Korean storefront.
