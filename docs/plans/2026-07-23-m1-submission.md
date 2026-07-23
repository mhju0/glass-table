# M1 Sub-project 4 — App Store + GRAC Submission Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> **STATUS (2026-07-23): paused after Task 6 by owner decision.** Repo-side work
> is done; the app is in a personal dogfooding phase before any store submission.
> Apple Developer enrollment (Task 7) is deliberately deferred. When resumed,
> proceed through Task 8-9 only as far as a TestFlight upload — do NOT submit
> for review (Task 11) without an explicit go from Michael.

**Goal:** Ship GlassTable v1.0 (1) to the App Store worldwide with the Korean rating on the self-rating track, per `docs/specs/2026-07-23-m1-submission-design.md`.

**Architecture:** Fully manual pipeline (Xcode Organizer + App Store Connect web UI). The repo work is content and configuration: LICENSE, release build settings, privacy policy, versioned store metadata, screenshots, GitHub Pages hosting. External tasks (enrollment, ASC, TestFlight, review) are exact checklists with expected outcomes.

**Tech Stack:** XcodeGen, xcodebuild/simctl, gh CLI, GitHub Pages (Jekyll default), App Store Connect.

## Global Constraints

- Bundle ID: `com.michaelju.glasstable` (normalized in Task 2; permanent after first upload).
- Version stays `1.0`, build `1`.
- App name on both storefronts: **Glass Table**. Primary language: **Korean**.
- Free, worldwide, no IAP, no ads, no accounts (`decisions.md` §6).
- Age-rating strategy: Simulated Gambling = **Infrequent/Mild** → expected 12+/KR-15 or lower; KR-19 triggers the §4 contingency, never a silent submit (`decisions.md` §7).
- Korean copy follows `docs/glossary.md` terms exactly (아웃, 팟 오즈, 필요 에퀴티, MDF, 블로커, 룰 오브 2/4, 에퀴티, 레인지, 콤보).
- `git diff main -- GlassTableEngine` stays empty for the whole sub-project.
- Simulator recipes keep passing `CODE_SIGNING_ALLOWED=NO` on the command line (the project-level setting is removed in Task 2).
- External-account steps (Apple enrollment, ASC forms, TestFlight install) are performed by Michael; the plan supplies the exact values to enter. All values entered into ASC must come verbatim from `docs/submission.md` — no ad-libbing copy in web forms.

Tasks 1–6 are repo work and need no Apple account. Task 7 (enrollment) can be started by Michael in parallel at any time; Tasks 8–11 depend on it.

---

### Task 1: MIT LICENSE

The repo goes public in Task 6 (privacy-policy hosting); workspace convention requires MIT with the handle-derived copyright line first. Origin is `github.com/mhju0/glass-table` → handle `mhju0`.

**Files:**
- Create: `LICENSE`

**Interfaces:**
- Produces: `LICENSE` at repo root; Task 6's public flip depends on it.

- [ ] **Step 1: Write LICENSE**

Create `LICENSE` with exactly:

```text
MIT License

Copyright (c) 2026 Michael Ju (github.com/mhju0)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 2: Verify no other license variants exist**

Run: `ls LICENSE* COPYING* 2>/dev/null`
Expected: only `LICENSE`.

- [ ] **Step 3: Commit**

```bash
git add LICENSE
git commit -m "chore: MIT license (pre-public-repo requirement)"
```

---

### Task 2: Release build settings in project.yml

**Files:**
- Modify: `project.yml:36` (bundle ID), `project.yml:40` (remove `CODE_SIGNING_ALLOWED`), info properties block (~line 23)

**Interfaces:**
- Consumes: nothing.
- Produces: bundle ID `com.michaelju.glasstable` — used verbatim by Task 5 (simctl launch), Task 8 (archive), Task 9 (ASC record). `ITSAppUsesNonExemptEncryption = NO` in the built Info.plist.

- [ ] **Step 1: Edit project.yml**

In `targets.GlassTable.info.properties`, add one key:

```yaml
        ITSAppUsesNonExemptEncryption: false
```

In `targets.GlassTable.settings.base`, change the bundle ID line and delete the signing line:

```yaml
        PRODUCT_BUNDLE_IDENTIFIER: com.michaelju.glasstable
```

and remove the line `CODE_SIGNING_ALLOWED: NO` entirely. (Simulator builds are unaffected: every recipe passes `CODE_SIGNING_ALLOWED=NO` on the xcodebuild command line — verified by repo-wide grep, the project setting's only live reference was `project.yml:40`.)

- [ ] **Step 2: Regenerate and build**

```bash
xcodegen generate
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build 2>&1 | tail -3
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Verify the built product's Info.plist**

```bash
plutil -p build/Build/Products/Debug-iphonesimulator/GlassTable.app/Info.plist \
  | grep -E "CFBundleIdentifier|ITSAppUsesNonExemptEncryption"
```

Expected:

```text
"CFBundleIdentifier" => "com.michaelju.glasstable"
"ITSAppUsesNonExemptEncryption" => 0
```

- [ ] **Step 4: Commit**

```bash
git add project.yml GlassTable/Info.plist
git commit -m "feat(release): normalize bundle ID, declare encryption-exempt, drop project-level signing off-switch"
```

(`GlassTable/Info.plist` is only staged if XcodeGen rewrote it; check `git status` first.)

---

### Task 3: Privacy policy

**Files:**
- Create: `docs/privacy-policy.md`

**Interfaces:**
- Produces: the file GitHub Pages renders at `https://mhju0.github.io/glass-table/privacy-policy.html` (Task 6 publishes and verifies; Task 9 enters that URL into ASC).

- [ ] **Step 1: Write the policy**

Create `docs/privacy-policy.md` with exactly:

```markdown
# Glass Table — 개인정보 처리방침 / Privacy Policy

시행일 / Effective date: 2026-07-23

## 한국어

Glass Table은 어떤 개인정보도 수집하지 않습니다.

- 네트워크에 연결하지 않습니다. 모든 기능이 기기 안에서만 동작합니다.
- 계정, 로그인, 광고, 인앱 결제, 분석 도구(analytics)가 없습니다.
- 드릴 진행 기록(스트릭, 정답률)은 기기에만 저장되며, 앱을 삭제하면 함께
  삭제됩니다. 개발자를 포함해 누구에게도 전송되지 않습니다.

문의: michaelju0418@gmail.com

## English

Glass Table collects no personal data.

- The app never connects to the network; everything runs on your device.
- There are no accounts, logins, ads, in-app purchases, or analytics.
- Drill progress (streaks, accuracy) is stored only on your device and is
  deleted with the app. It is never transmitted to anyone, including the
  developer.

Contact: michaelju0418@gmail.com
```

- [ ] **Step 2: Commit**

```bash
git add docs/privacy-policy.md
git commit -m "docs: bilingual privacy policy (Data Not Collected)"
```

---

### Task 4: Store metadata + questionnaire answers (docs/submission.md)

Everything typed into App Store Connect later comes verbatim from this file. Also records the counsel decision in `open-questions.md`.

**Files:**
- Create: `docs/submission.md`
- Modify: `docs/open-questions.md` (item 11)

**Interfaces:**
- Consumes: glossary terms from `docs/glossary.md`.
- Produces: all ASC field values for Tasks 9 and 11.

- [ ] **Step 1: Write docs/submission.md**

Create `docs/submission.md` with exactly:

````markdown
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
• 블로커 — 블로커가 콤보 수를 어떻게 바꾸는지 계산

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
12+/KR-15 or lower on the self-rating track.

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
````

- [ ] **Step 2: Verify field limits**

```bash
python3 - <<'EOF'
checks = [
    ('name',        30,  'Glass Table'),
    ('ko subtitle', 30,  '아웃 · 팟 오즈 · MDF 계산 훈련'),
    ('en subtitle', 30,  'Outs, pot odds & MDF drills'),
    ('ko keywords', 100, '포커,홀덤,팟오즈,아웃,에퀴티,MDF,블로커,포커수학,연습,드릴,훈련,계산'),
    ('en keywords', 100, 'poker,holdem,texas,outs,pot odds,equity,MDF,blockers,drills,trainer,study,math'),
    ('ko promo',    170, '레인지와 EV로 생각하는 포커. 하루 몇 분, 다섯 가지 수학 드릴로 감이 아니라 계산으로 결정하세요.'),
    ('en promo',    170, 'Think in ranges and EV. Five daily math drills to make poker decisions by calculation, not feel.'),
]
for label, limit, value in checks:
    status = 'OK' if len(value) <= limit else 'OVER LIMIT'
    print(f'{label}: {len(value)}/{limit} {status}')
    assert len(value) <= limit, label
print('ALL WITHIN LIMITS')
EOF
```

Expected: `ALL WITHIN LIMITS`. If a field is over, trim it in `docs/submission.md`, update the matching string here, and re-run. (The strings are duplicated from Step 1 by design — if you edit one, edit both.)

- [ ] **Step 3: Record the counsel decision in open-questions.md**

In `docs/open-questions.md`, item 11, append to the existing text:

```markdown
*Resolved for M1 (2026-07-23):* proceeding **without** counsel — Math Drills
is the lowest-signal build and the GRAC direct review is an administrative
fallback (spec `docs/specs/2026-07-23-m1-submission-design.md`). Revisit
counsel before the betting-table milestone.
```

- [ ] **Step 4: Commit**

```bash
git add docs/submission.md docs/open-questions.md
git commit -m "docs: store metadata, age-rating answers of record, review notes (submission.md)"
```

---

### Task 5: Screenshots (6.9" set)

**Files:**
- Create: `docs/store-assets/ko-01-home.png` … `ko-05-glossary.png`

**Interfaces:**
- Consumes: bundle ID `com.michaelju.glasstable` (Task 2); demo hooks `GT_DEMO_DRILL` (slugs `outs, potodds, callfold, mdf, blockers`), `GT_DEMO_REVEAL`, `GT_DEMO_STATS`, `GT_DEMO_GLOSSARY` (`GlassTable/Sources/Screens/HomeView.swift:85-90`).
- Produces: 5 PNGs at exactly 1320×2868 for Task 9's media upload.

- [ ] **Step 1: Build and install on the 6.9" simulator**

```bash
xcodegen generate
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build 2>&1 | tail -3
xcrun simctl boot "iPhone 17 Pro Max" 2>/dev/null || true
xcrun simctl install "iPhone 17 Pro Max" \
  build/Build/Products/Debug-iphonesimulator/GlassTable.app
xcrun simctl status_bar "iPhone 17 Pro Max" override \
  --time "9:41" --dataNetwork wifi --wifiBars 3 \
  --batteryState charged --batteryLevel 100
mkdir -p docs/store-assets
```

Expected: `BUILD SUCCEEDED`, install silent.

- [ ] **Step 2: Populate progress so the home rings and stats are non-empty**

One reveal per drill writes real progress via the demo hook:

```bash
for slug in outs potodds callfold mdf blockers; do
  SIMCTL_CHILD_GT_DEMO_DRILL=$slug SIMCTL_CHILD_GT_DEMO_REVEAL=1 \
    xcrun simctl launch "iPhone 17 Pro Max" com.michaelju.glasstable
  sleep 2
  xcrun simctl terminate "iPhone 17 Pro Max" com.michaelju.glasstable
done
```

Expected: five launch/terminate cycles, no errors.

- [ ] **Step 3: Capture the five shots**

```bash
snap() {
  sleep 2
  xcrun simctl io "iPhone 17 Pro Max" screenshot "docs/store-assets/$1"
  xcrun simctl terminate "iPhone 17 Pro Max" com.michaelju.glasstable
}
xcrun simctl launch "iPhone 17 Pro Max" com.michaelju.glasstable
snap ko-01-home.png
SIMCTL_CHILD_GT_DEMO_DRILL=outs SIMCTL_CHILD_GT_DEMO_REVEAL=1 \
  xcrun simctl launch "iPhone 17 Pro Max" com.michaelju.glasstable
snap ko-02-outs-reveal.png
SIMCTL_CHILD_GT_DEMO_DRILL=potodds \
  xcrun simctl launch "iPhone 17 Pro Max" com.michaelju.glasstable
snap ko-03-potodds.png
SIMCTL_CHILD_GT_DEMO_STATS=1 \
  xcrun simctl launch "iPhone 17 Pro Max" com.michaelju.glasstable
snap ko-04-stats.png
SIMCTL_CHILD_GT_DEMO_GLOSSARY=1 \
  xcrun simctl launch "iPhone 17 Pro Max" com.michaelju.glasstable
snap ko-05-glossary.png
```

- [ ] **Step 4: Verify dimensions and eyeball each shot**

```bash
sips -g pixelWidth -g pixelHeight docs/store-assets/ko-0*.png | grep -E "file|pixel"
```

Expected: every file `pixelWidth: 1320`, `pixelHeight: 2868`. Then open each PNG (Read tool / Preview) and check: Korean copy renders in Pretendard, home shows non-zero progress, stats shows five drill rows with data, reveal shot shows the grade band. Any wrong-state shot: re-run its launch+snap pair.

- [ ] **Step 5: Commit**

```bash
git add docs/store-assets
git commit -m "feat(store): 6.9-inch App Store screenshot set (home, drills, stats, glossary)"
```

---

### Task 6: Repo public + GitHub Pages + policy URL live

**Files:**
- None (GitHub settings). Depends on Tasks 1 (LICENSE) and 3 (policy) being pushed.

**Interfaces:**
- Produces: `https://mhju0.github.io/glass-table/privacy-policy.html` returning 200 — the URL Task 9 enters into ASC.

- [ ] **Step 1: Secret scan of the tracked tree**

```bash
git grep -riE "apikey|api_key|secret|password|token" -- ':!docs/plans' ':!docs/specs' || echo CLEAN
```

Expected: `CLEAN` (or only false positives like prose; anything real stops this task — report to Michael).

- [ ] **Step 2: Push main, flip visibility, enable Pages**

```bash
git push origin main
gh repo edit mhju0/glass-table --visibility public --accept-visibility-change-consequences
gh api -X POST repos/mhju0/glass-table/pages \
  -f "source[branch]=main" -f "source[path]=/docs"
```

Expected: repo edit prints the repo URL; Pages POST returns HTTP 201 JSON. (409 = Pages already enabled; fine.)

- [ ] **Step 3: Verify the policy URL serves**

Pages' first build takes a few minutes; poll:

```bash
for i in $(seq 1 20); do
  code=$(curl -s -o /dev/null -w '%{http_code}' https://mhju0.github.io/glass-table/privacy-policy.html)
  [ "$code" = "200" ] && echo LIVE && break
  sleep 30
done
```

Expected: `LIVE`. If still 404 after 10 minutes, check `gh api repos/mhju0/glass-table/pages/builds/latest` for the build error.

---

### Task 7: Apple Developer enrollment (external — Michael)

**Files:** none.

**Interfaces:**
- Produces: an active membership and the 10-character **Team ID** (developer.apple.com/account → Membership details), consumed by Task 8.

- [ ] **Step 1: Enroll**

At https://developer.apple.com/programs/enroll/, enroll as an **Individual** with the Apple Account to be used for App Store Connect ($99/yr). Identity verification may take up to ~2 days.

- [ ] **Step 2: Confirm access and record the Team ID**

When approved: https://appstoreconnect.apple.com loads with "My Apps", and developer.apple.com/account → Membership details shows the Team ID. Paste the Team ID into the session so Task 8 can proceed.

---

### Task 8: Signing, archive, upload (needs Team ID)

**Files:**
- Modify: `project.yml` (settings.base)

**Interfaces:**
- Consumes: Team ID from Task 7.
- Produces: build 1.0 (1) processing in App Store Connect, consumed by Tasks 9–10.

- [ ] **Step 1: Add signing settings**

In `project.yml` under `targets.GlassTable.settings.base`, add (TEAM_ID is the 10-character value from Task 7 — an external input, entered at execution time):

```yaml
        DEVELOPMENT_TEAM: TEAM_ID
        CODE_SIGN_STYLE: Automatic
```

Run `xcodegen generate`, then verify the simulator build still succeeds:

```bash
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build 2>&1 | tail -3
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 2: Commit**

```bash
git add project.yml
git commit -m "feat(release): automatic signing with development team"
git push origin main
```

- [ ] **Step 3: Archive and upload (Xcode Organizer — Michael, signed into Xcode with the developer Apple Account)**

1. `open GlassTable.xcodeproj`
2. Xcode → Settings → Accounts: the enrolled Apple Account and team are present.
3. Destination: **Any iOS Device (arm64)** → Product → **Archive**.
4. Organizer → the new archive → **Distribute App** → **App Store Connect** → Upload, automatic signing, defaults throughout.

Expected: "Upload Successful". The build then shows under the app's TestFlight tab (processing ~15–60 min). No export-compliance prompt should appear (`ITSAppUsesNonExemptEncryption` is set).

Note: uploading requires the ASC app record — if Task 9 Step 1 hasn't been done yet, do it first (only Step 1; the record must exist for the bundle ID).

---

### Task 9: App Store Connect record + all form entry (external — Michael, values from docs/submission.md)

**Files:** none.

**Interfaces:**
- Consumes: `docs/submission.md` (every field), screenshots from `docs/store-assets/`, policy URL from Task 6.
- Produces: a fully prepared 1.0 version, ready for Task 11's submit.

- [ ] **Step 1: Create the app record**

ASC → My Apps → **+** → New App: platform iOS, name **Glass Table**, primary language **Korean**, bundle ID **com.michaelju.glasstable**, SKU **glass-table-ios**.

- [ ] **Step 2: Pricing and availability**

Price **Free** (KRW 0 tier); availability **all territories**.

- [ ] **Step 3: Age rating questionnaire**

Answer exactly per the "Age rating questionnaire" table in `docs/submission.md` (everything None/No except Simulated Gambling = Infrequent/Mild). **Record the computed rating in `docs/submission.md`'s blank and commit.** If the result is 17+/KR-19: STOP — do not submit; this triggers the spec §4 contingency (report back, GRAC direct-review follow-up becomes its own sub-project).

- [ ] **Step 4: App Privacy**

Data collection: **No** → label shows **Data Not Collected**. Privacy policy URL: `https://mhju0.github.io/glass-table/privacy-policy.html`.

- [ ] **Step 5: Version metadata, both locales**

Korean (primary): subtitle, promotional text, keywords, description — verbatim from `docs/submission.md` §Korean. Add locale **English (U.S.)** and fill from §English. Support URL, copyright, category per the §App record table. Upload the five screenshots from `docs/store-assets/` to the 6.9" slot in **both** locales, in filename order.

- [ ] **Step 6: Select the build**

Version 1.0 → Build → select **1.0 (1)** once processing completes.

---

### Task 10: TestFlight internal pass (external — Michael)

**Files:** none.

**Interfaces:**
- Consumes: processed build 1.0 (1).
- Produces: hardware verification; any defect loops back to the repo before Task 11.

- [ ] **Step 1: Internal testing**

ASC → TestFlight → Internal Testing → create group "Internal", add yourself as tester (internal testing needs no beta review). Install via the TestFlight app on your iPhone.

- [ ] **Step 2: Hardware checklist**

On the device, verify — each item comes from shipped work this milestone:

1. App icon on the home screen is the abstract table-disc + % mark (no cards).
2. Pretendard renders throughout (home, drills, stats, 용어집).
3. Haptics fire on reveal.
4. Dynamic Type: set the largest non-accessibility text size — layouts don't clip.
5. Device dark mode ON → app stays light (UIUserInterfaceStyle lock).
6. One full spot in each of the five drills: decide → reveal → grade works; stats screen reflects the reps.

Expected: all pass. Any failure: fix in repo, bump build number to 2 in `project.yml` info properties (`CFBundleVersion`), re-archive (Task 8 Step 3), re-test.

---

### Task 11: Submit for review + wrap-up

**Files:**
- Modify: `docs/submission.md` (record outcomes)

**Interfaces:**
- Consumes: prepared 1.0 version (Task 9), verified build (Task 10).
- Produces: M1 exit — Ready for Sale, or the recorded KR-19 contingency.

- [ ] **Step 1: Submit**

ASC → version 1.0 → App Review notes: paste the "Review notes" section from `docs/submission.md` → **Add for Review** → **Submit to App Review**. Release option: **Automatically release after approval**.

- [ ] **Step 2: Track and record the outcome**

Review typically completes within ~48 hours. Outcomes:

- **Approved → Ready for Sale:** confirm on the Korean storefront that the listing shows the expected rating (12+/KR-15 or lower). Record date + rating in `docs/submission.md`; commit (`docs: record 1.0 approval + rating`). **M1 sub-project 4 done — Milestone 1 complete.**
- **Rejected:** record the rejection text in `docs/submission.md`, fix (metadata fixes need no new build; binary fixes bump the build number), resubmit. Rejections citing gambling/rating route to the next bullet's logic.
- **Rating forced to 17+/KR-19 at any point:** per spec §4, stop, record in `docs/submission.md`, commit — this closes the sub-project as "contingency exercised" and opens the GRAC direct-review follow-up (fee, gameplay video, ~10–15 business days) as its own sub-project.

---

## Verification (whole sub-project)

```bash
git diff main -- GlassTableEngine   # must be empty throughout
swift test --package-path GlassTableDrills 2>&1 | tail -3   # 31 tests green (no code touched; run once before Task 8's push)
```

External gates are the verification for Tasks 7–11: Pages URL 200, upload processes, TestFlight installs, review passes, storefront rating as expected.
