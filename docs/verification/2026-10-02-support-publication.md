# Support contact and public pages, 2026-10-02

Support changes followed Direction A Steps 0–8. The redesign remains local and
unpushed. Only four support files were published through
[PR #10](https://github.com/mhju0/glass-table/pull/10), based on published main
79ce374: SettingsView.swift, docs/privacy-policy.md, docs/submission.md and
new docs/support.html. Support commit df927d8; merged main 8e808ca; local
redesign cherry-pick 46e6ff5.

Settings feedback now targets mj.apps.support@gmail.com. The existing native
Link and exact decoded subject “Glass Table 피드백” are unchanged. The bilingual
MJ Apps Support page asks for app version, iPhone model and what happened, and
links to the privacy policy. It has no forms, scripts, analytics, tracking,
remote fonts, personal contact details or response-time promises.

Both policy languages use the same contact and clarify local records, surviving
exported copies, possible OS backups and voluntarily sent support email. The
app remains offline without automatic developer transmission. No new retention
promise was invented; no owner decision was required for these factual changes.
Submission Support URL is updated. Historical M1 contact samples are unchanged;
no other current user-facing old contact was found.

Pages API confirms legacy Jekyll main:/docs, HTTPS enforced. Markdown generates
privacy-policy.html; there is no separate HTML source. Pages build/deployment
36976488804 succeeded for 8e808ca. Both public URLs returned 200 and were inspected:

- Support URL: https://mhju0.github.io/glass-table/support.html
- Privacy Policy URL: https://mhju0.github.io/glass-table/privacy-policy.html

Support HTML bytes match the committed source. All 17 policy paragraphs/list
items match generated HTML after whitespace, link and Jekyll smart-apostrophe
normalization. The initial raw text comparison failed only on device's/device’s;
normalization corrected the verification helper. Old address and draft notice
are absent. First browser navigation reused cached old policy; reload fetched
current content. The rejected cached capture is retained.

XcodeGen, generic simulator build and 67 app-unit tests passed on published-main
base; generic build also passed after applying the same patch to Direction A.
No app test failed for this change. Local support preview: 1280×900 dark and
390×844 light. Public support: 1280×900 light and 390×844 dark; public privacy:
both widths. Root inspected all six accepted PNGs. No horizontal overflow
(390/390,1280/1280), page errors or automated support accessibility violations.
All three mail links were clicked with external navigation intercepted: correct
recipient, unchanged subject on primary links, no subject on footer. No email
app was opened or email sent. Both Korean/English privacy links navigate to the
actual policy; both policy contact links have the correct mailto.

Local evidence: .build/direction-a/support/ contains report.md, commands.txt,
source-checks.json, public-content-checks.json, public-links.json,
public-privacy-links.json, public-a11y.json, public-browser-errors.txt,
local-desktop-dark.png, local-mobile-light.png, public-desktop-light.png,
public-mobile-dark.png, public-privacy-desktop.png and public-privacy-mobile.png.
GitHub app CI was still running at this verification snapshot; it is not claimed
as passed. Local checks and successful Pages publication are separate evidence.
No App Store submission, Notion/App Store Connect change or external email occurred.
