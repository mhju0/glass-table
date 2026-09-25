# Glass Table — Release roadmap

> Rewritten 2026-09-25 from the owner's answers on the
> [release research page](https://claude.ai/artifact/5uBT6CLXkUkruLoYyxUgjN).
> The previous roadmap (2026-09-04, NOW section dated 09-05) is archived at
> [`handoff-archive/2026-09-25-roadmap-before-release-plan.md`](handoff-archive/2026-09-25-roadmap-before-release-plan.md).
> Why each choice was made: [`decision-history.md`](decision-history.md).

Goal: get 1.0 onto the App Store in Korea and the US **as soon as possible**. "Done" beats
"perfect", but the app should not be half-finished. Phases run in order. Items within a
phase can run in parallel.

## Phase 0 — Decisions ✅ (2026-09-25)

| Question | Answer |
|---|---|
| Territories for 1.0 | Korea and the US together, once the age rating is settled. No EU (it would require DSA trader status and a public address). |
| Age rating | **Frequent simulated gambling, 18+** (owner, 2026-09-25: the safe answer without counsel). In Korea this requires a GRAC Rating Classification Number (RCN) before sale. The US can launch without it. |
| Business model | A free download plus one ₩9,900 / $6.99 unlock, with no ads. **1.0 launches free**. The unlock comes in 1.1, after Korean business registration. |
| Beta | One week of internal TestFlight, then 10–20 invited beginners. |
| Security | Fix audit findings #1 (live privacy page) and #2 (personal email) before submitting. #3 and #4 come later. |
| Push `feat/shared-learning-table` | After the owner has used build 9 for a day, and only on their "yes, push" in chat. |
| Support contact | A new Gmail used only for the app. |
| Device testing | A five-phone matrix plus the iOS 17 runtime (Phase 3). |

## Phase 1 — Outside the code (start now; these take the longest)

1. **GRAC rating for Korea.** The owner chose 18+ / frequent, so the Korean storefront needs a
   GRAC Rating Classification Number (RCN): an application to the GRAC,
   about 10–15 days, with a fee. If the RCN is late, the US launches first and Korea
   follows. The counsel consult (open question #11) is skipped.
2. **Support Gmail.** It goes in Settings' feedback link, the privacy policy, the
   support page and App Store Connect. In Korea, Apple shows this email on the product
   page for every individual developer, even for free apps.
3. **Publish the final privacy policy.** The live page still shows the draft notice
   (audit #1). Add one sentence on how support emails are handled.
4. **Support page** on the same GitHub Pages site: FAQ plus contact. It replaces the
   repo URL in `submission.md`.
5. **Apple Developer Program.** Individual, $99 a year. Then the App Store Connect app
   record: bundle ID `com.michaelju.glasstable`, name reservation, and Korean-law
   compliance email verification.
6. **Name check.** Search "Glass Table" and "포커 배우기" in KIPRIS and USPTO.
7. **For 1.1, not blocking 1.0:** 사업자등록 (simplified tier) on 홈택스, a single
   consult with a tax accountant, then the Paid Apps Agreement, W-8BEN, Korean tax forms
   and bank account.

## Phase 2 — 1.0 code work

Each item gets a short spec or issue under `.scratch/` before it is built.

1. **Hold'em basics lesson (new first beginner lesson).** How the cards are dealt
   (two hole cards; flop, turn, river; best five of seven), then the hand-ranking
   ladder with how often each hand appears. The frequencies must be **computed by the
   engine in a test**, not copied from the web. Reference values for seven cards:
   royal flush 0.0032%, straight flush 0.028%, quads 0.17%, full house 2.6%, flush
   3.0%, straight 4.6%, trips 4.8%, two pair 23.5%, one pair 43.8%, high card 17.4%.
   The ranking list in `LearningGuideView` is text only today.
2. **Consistent-learning-table issue 03**: first-use explanations for every mode.
3. **Consistent-learning-table issue 04**: assisted attempts count as practice, not accuracy.
4. **Position intro leaks**: the expanded order line and the highlighted button seat.
5. **Dark-mode contrast** of the table setup's segmented control.
6. **Responsible-gambling placement (combination):** a Settings row "책임감 있게
   이용하기 / Play responsibly" with helplines (Korea 1336, US 1-800-GAMBLER); one
   sentence on the welcome screen's second page; keep Play's existing "No real
   money" line; add a store-description disclaimer (Phase 4).
7. **Rating prompt** (`requestReview`) after a real milestone only, never at launch
   or mid-question.
8. **Daily reminder**: a local notification, off until the learner turns it on,
   one time of day, calm wording, no streak guilt. No push server.
9. **Share card**: an image of a learning milestone (a section finished, a concept
   mastered) made on the phone and sent through the share sheet. It never shows chips
   won. Open question #16 applies only if puzzles are shared later.
10. **Feedback mailto** switches to the support Gmail (audit #2).
11. **Update the product brief** where it still says "free forever / no money".

## Phase 3 — Verify

1. **Five-phone matrix** at `large` and AX5: iPhone SE (3rd generation, 375 × 667,
   **never tested so far**), 12 mini, 17, Air, 18 Pro Max. Keep the line-parity OCR
   audit on the mini.
2. **Minimum iOS 17.** Download the iOS 17 simulator runtime (only 26.x and 27.0 are
   installed) or use a real iOS 17 phone. Keep the minimum at iOS 17: it already covers
   well over 90% of active iPhones.
3. **iPad compatibility mode**: run the iPhone app once in an iPad simulator.
4. **VoiceOver** on `TableView` and `NodeSessionView`, or declare only verified
   features in the Accessibility Nutrition Label.
5. The usual gates: app build and tests, Drills tests, the Engine **release** gate,
   `tools/verify_release.py`.

## Phase 4 — TestFlight → submit 1.0

1. Archive and upload. One week of internal TestFlight (the owner's iPhone plus an
   iOS 17 device).
2. An external group of 10–20 beginners (KO and EN, including one or two VoiceOver or
   large-text users). Tasks: finish 기초, play 10 free hands, try one graded session.
   External testers need a Beta App Review of 1–2 days.
3. New 6.9″ screenshots (KO/EN). Metadata updated for Play/Learn and the 2–4 player
   tables. Store disclaimer: no real money, and practice doesn't imply real-money success.
4. Questionnaires: App Privacy ("Data Not Collected"), age rating (Phase 1 outcome),
   content rights, accessibility labels. Review notes: no login, no real money, chips
   have no value. Manual release.

## After 1.0

- **1.1:** one-time unlock (after registration), milestones (a small set tied to
  mastery, no XP), a What's New sheet, MDF as a full slice, pot-relative EV-loss
  bands, pinning Actions by SHA, pruning recovery copies.
- **Later:** home-screen widget (needs an App Group, i.e. a `progression.json`
  location migration), optional sounds, `KO.wordJoined` coverage for `Text`
  literals and button titles.
- **Decided against:** daily hand puzzle, iCloud sync, Shortcuts / Spotlight / TipKit,
  Game Center, ads, subscriptions.

## Still considered, not committed

Carried over from the old roadmap: Sit In Their Seat, Run It 1000 Times, Lab, a 6-max
table (#14), a Korean app name beyond "포커 배우기 — Glass Table" (#12), remote puzzle
content, captioned screenshots, the 8-seat animated table. See the archive for why
each is parked.

## Still rejected

Multiplayer, real money, **purchasable chips (ever)**, iPad/Android/web, tournaments,
rake, a sizing slider, a backend or accounts, leagues/XP/hearts, highlighting the
recommended action, Dynamic Type card faces, translucent surfaces, GTO Wizard as the
range baseline.

Superseded since the old roadmap: "money or ads of any kind" (now a one-time unlock,
no ads); "separate onboarding" (a two-screen welcome plus a warm-up, chosen
2026-09-24); "light/dark twin" (an appearance setting now exists).
