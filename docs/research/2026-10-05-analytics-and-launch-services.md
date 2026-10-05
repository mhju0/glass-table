# Analytics and launch services — research (2026-10-05)

Readable version: <https://claude.ai/artifact/UakiKumqGnKUzjmaJGkX3K>.
Prices and shares are what web sources reported on 2026-10-05; "not checked" means
not confirmed that day. Check the vendor's page before acting on any figure.

## Decision (owner, 2026-10-05)

1.0 ships with no analytics tool and stays offline. Analytics, and the privacy
changes that come with it, are considered in 1.1 or later. See `ROADMAP.md`.

## What analytics answers

How many people open the app and return (day 1, day 7), where they stop, which
lessons are finished or abandoned, and whether it crashes on phones the owner does
not have.

## Free from Apple, no code

Counts only players who opted in to share usage data with developers.

| Tool | Shows | Does not show |
|---|---|---|
| App Store Connect Analytics | Downloads, sources, opens, retention, deletions, crash counts | Anything inside the app (which lesson, where people quit) |
| Xcode Organizer | Crash reports with code lines, launch time, hangs, battery, memory | Non-crash problems |
| TestFlight | Beta feedback, screenshots, crashes | Behaviour after release |
| Ratings and reviews | What people say | The silent majority |

## In-app analytics tools

| Tool | Kind | Free | Paid from | Fit |
|---|---|---|---|---|
| TelemetryDeck | Privacy-first, Apple-focused | 100,000 signals/month | €19/month (1.5M signals) | Best match if anything is added. Confirm the App Store privacy answers with their guide. |
| Aptabase | Privacy-first, open source | Free tier (limit not checked) | Not checked | Simplest; fewer charts |
| Firebase Analytics | Depth-first, Google | Free, no cap | Free | Most popular: about 89% of iOS apps that use an analytics SDK. Poor fit for a no-tracking promise. |
| PostHog | Depth-first, all-in-one | Free tier (limit not checked) | Usage-based | More than a first app needs |
| Mixpanel / Amplitude | Depth-first, product teams | Free tiers (limits not checked) | Usage-based | Overkill |

## What adding analytics would change

- The app would use the network for the first time; `AGENTS.md` says offline, no analytics.
- App Privacy answers change from "Data Not Collected"; Apple rejects answers that
  contradict the SDK privacy manifests.
- Privacy policy, store description and anything told to GRAC about data must match.

## Companion services

| Need | Options | Cost | For Glass Table |
|---|---|---|---|
| Crash reports | Xcode Organizer · Firebase Crashlytics (most used) · Sentry | Free · free, no cap · free to 5,000 errors/month then $26/month | Apple's is enough for 1.0 |
| Beta testing | TestFlight | Free | Already in Phase 4 |
| Feedback | Support email row, reviews, Apple's rating prompt | Free | Already in Phase 2 |
| Search keywords | Appfigures · Astro | About $9.99/month · $9/month billed yearly | Optional. One source says Astro's keyword data is frozen since October 2025. |
| Selling the unlock | StoreKit directly · RevenueCat | Free · free to $2,500 revenue/month then 1% | StoreKit alone suits one one-time unlock |
| Required pages | Privacy policy URL, support URL, App Privacy answers | Free | Already in Phase 1 and 4 |

## Suggested order

1. 1.0: nothing added.
2. First month live: read App Store Connect weekly; write down questions it cannot answer.
3. 1.1 or later, only for a specific unanswered question: TelemetryDeck free plan,
   a few events, with the promise, policy and App Privacy answers updated together.

## Sources

- <https://telemetrydeck.com/blog/pricing-update-2026/>
- <https://theswiftk.it.com/best/best-ios-analytics-sdks>
- <https://theswiftk.it.com/blog/ios-app-analytics-guide-telemetrydeck-posthog>
- <https://42matters.com/sdk-analysis/app-store/top-analytics-sdks>
- <https://developer.apple.com/help/app-store-connect-analytics/engagement/app-usage>
- <https://theswiftk.it.com/blog/crashlytics-vs-sentry-vs-bugsnag-ios>
- <https://www.drizz.dev/post/cheapest-mobile-error-tracking-tools>
- <https://costbench.com/software/subscription-billing/revenuecat/free-plan/>
- <https://trysonar.app/blog/astro-aso-pricing>
- <https://trysonar.app/blog/best-appfigures-alternatives-for-aso>
- <https://blakecrosley.com/blog/privacy-manifest-deep-dive>
