# Analytics and launch services research

- **Date:** 2026-10-05
- **Kind:** research
- **Originals:** `docs/research/2026-10-05-analytics-and-launch-services.md` (tracked: `git show f5c5e22:<path>`); a readable claude.ai artifact version was linked from it.
- **Asked by / for:** owner; whether to add analytics or other launch services before 1.0.

## What it was
Survey of free Apple tools, in-app analytics SDKs and companion launch services, with prices as web sources reported on 2026-10-05 (re-check vendor pages before acting).

## Findings and decisions
- Decision (owner, 2026-10-05): 1.0 ships with no analytics tool and stays offline. Analytics and its privacy changes are considered in 1.1 or later (see `docs/ROADMAP.md`).
- Free Apple tools (opt-in users only): App Store Connect Analytics (downloads, sources, opens, retention, deletions, crash counts; nothing in-app), Xcode Organizer (crashes, launch time, hangs, battery, memory), TestFlight (beta feedback), ratings and reviews.
- In-app tools: TelemetryDeck (privacy-first, Apple-focused; free 100,000 signals/month, EUR 19/month for 1.5M) is the best fit if anything is added; Aptabase (open source, simplest); Firebase Analytics (free, ~89% of iOS apps using an analytics SDK, poor fit for a no-tracking promise); PostHog, Mixpanel, Amplitude judged overkill.
- Adding analytics would: make the app use the network for the first time (conflicts with AGENTS.md offline rule), change App Privacy from "Data Not Collected" (must match SDK privacy manifests), and require privacy policy, store text and GRAC data answers to change together.
- Companions: crashes via Xcode Organizer is enough for 1.0 (Crashlytics free; Sentry free to 5,000 errors/month then $26/month); TestFlight for beta; support email row, reviews and Apple rating prompt for feedback; keywords optional (Appfigures ~$9.99/month, Astro $9/month yearly, one source says Astro data frozen since Oct 2025); one-time unlock via StoreKit directly (RevenueCat free to $2,500/month revenue then 1%, not needed).
- Suggested order: nothing in 1.0; first month live read App Store Connect weekly and list unanswered questions; 1.1+ only for a specific question, TelemetryDeck free plan with a few events and policy/App Privacy updated together.

## Outcome
Owner decision recorded: no analytics in 1.0. Nothing was implemented.

## Still open
- Revisit analytics for 1.1 or later only against specific unanswered questions.

Sources (short): telemetrydeck.com pricing update 2026; 42matters top analytics SDKs; Apple App Store Connect analytics help; Crashlytics/Sentry comparisons; RevenueCat free-plan pricing; Astro/Appfigures ASO pricing; privacy-manifest deep dive (blakecrosley.com).
