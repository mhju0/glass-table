#!/usr/bin/env python3
"""Annotate a frozen UX crawl report without changing its source or screen order.

Usage: python3 tools/uxaudit/codex_report.py [findings.json]
The input JSON holds `claude_assessments` (one per existing top finding) and
`codex_findings` (new findings with `where` card IDs). The generated report
keeps every source card, flow, image, and authored finding in its original order.
"""

import json
import os
import shutil
import sys
from pathlib import Path

from bs4 import BeautifulSoup, NavigableString


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / ".build/uxaudit-report"
OUTPUT = ROOT / ".build/uxaudit-report-codex"
FINDINGS = ROOT / ".scratch/uxaudit-codex/findings.json"

CSS = """
/* The report follows the source's quiet, warm visual language. */
html { scroll-behavior:smooth }
body { overflow-x:hidden }
nav, main, .section, .flow, .track { min-width:0 }
main { max-width:100%; overflow:hidden }
.report-context { border-left:3px solid var(--accent); padding:7px 12px; margin:0 0 16px;
  background:var(--panel); color:var(--ink); max-width:95ch }
.report-context p { margin:4px 0; font-size:13px }
.report-context strong { font-weight:700 }
.origin { display:inline-block; font-size:11px; font-weight:750; line-height:1.5;
  padding:1px 7px; border-radius:4px; margin-right:6px; vertical-align:baseline }
.origin.claude { color:var(--ink); background:var(--line) }
.origin.codex { color:#fff; background:#365b63 }
:root[data-theme="dark"] .origin.codex { color:#101b1d; background:#9bd0d7 }
@media (prefers-color-scheme:dark) {
  :root:not([data-theme="light"]) .origin.codex { color:#101b1d; background:#9bd0d7 }
}
.status { display:inline-block; font-size:11px; font-weight:750; line-height:1.5;
  padding:1px 7px; border-radius:4px; margin-right:6px }
.status.current { background:#9d2e27; color:#fff }
.status.qualified { background:#efe1b4; color:#3f2f04 }
.status.unverified { background:var(--line); color:var(--ink) }
.status.resolved { background:#d9eade; color:#1a4d30 }
.chip.sev-crash, .chip.sev-high { background:#9d2e27; color:#fff }
.chip.sev-medium { background:#755010; color:#fff }
:root[data-theme="dark"] .status.qualified { background:#6a5420; color:#fff0bc }
:root[data-theme="dark"] .status.resolved { background:#244b35; color:#c5f0d1 }
@media (prefers-color-scheme:dark) {
  :root:not([data-theme="light"]) .status.qualified { background:#6a5420; color:#fff0bc }
  :root:not([data-theme="light"]) .status.resolved { background:#244b35; color:#c5f0d1 }
}
.finding { padding:10px 12px; border-left:3px solid var(--line); background:var(--panel) }
.finding.current-issue { border-left-color:#9d2e27; background:color-mix(in srgb, var(--panel) 92%, #9d2e27) }
.finding .assessment { border-top:1px solid var(--line); margin-top:8px; padding-top:7px;
  font-size:13px; max-width:95ch }
.finding .assessment p { display:inline; margin:0; color:var(--ink) }
.finding .where { margin-top:5px; overflow-wrap:anywhere }
.finding .where a { display:inline-block; margin:0 4px 2px 0 }
.codex-findings { padding-left:20px }
.card.codex-current { outline:2px solid #9d2e27; outline-offset:1px }
.card.codex-qualified { outline:2px solid var(--accent); outline-offset:1px }
.card .origin { font-size:10px; padding:0 5px }
.card .status { font-size:10px; padding:0 5px }
.card ul.notes li.codex-note { background:color-mix(in srgb, var(--panel) 84%, #365b63);
  border-left:2px solid #365b63; overflow-wrap:anywhere }
.card ul.notes li.codex-note.current { border-left-color:#9d2e27;
  background:color-mix(in srgb, var(--panel) 86%, #9d2e27) }
.flaggroup li { overflow-wrap:anywhere }
.evidence-key { font-size:13px; color:var(--muted); max-width:95ch }
.evidence-key strong { color:var(--ink) }
.toolbar button { font:inherit; color:var(--ink); background:var(--panel); border:1px solid var(--line);
  border-radius:6px; min-height:36px; padding:4px 10px; cursor:pointer }
:where(button, a, input, summary):focus-visible { outline:3px solid var(--accent); outline-offset:3px }
nav a { overflow-wrap:anywhere }
#detail { overflow-x:hidden }
#detail .bar { background:var(--shade); flex-wrap:wrap; padding:6px 0; z-index:1 }
#detail .bar .where { min-width:0; overflow-wrap:anywhere }
#detail .info { overflow-x:auto; max-width:100%; overflow-wrap:anywhere }
#detail .frames-row { max-width:100% }
#detail table { min-width:520px }
@media (max-width:800px) {
  nav { max-height:29vh }
  nav > ul { display:flex; overflow-x:auto; gap:12px; padding-bottom:6px }
  nav > ul > li { flex:0 0 140px }
  nav li li { display:none }
  main { padding:16px 12px 60px }
  .report-context { padding:8px 10px }
  h1 { font-size:24px }
  h2 { font-size:21px }
  .finding { padding:9px 10px }
  .track { max-width:100%; gap:16px }
  #detail { padding:10px }
  #detail .frames-row img { height:min(70vh, 900px) }
}
"""

JS = """
(() => {
  const dlg = document.getElementById('detail');
  dlg.addEventListener('keydown', (event) => {
    if (event.key !== 'Tab') return;
    const controls = [...dlg.querySelectorAll('button')].filter(button => !button.disabled);
    if (!controls.length) return;
    const first = controls[0], last = controls[controls.length - 1];
    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault(); last.focus();
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault(); first.focus();
    }
  });
  document.querySelectorAll('nav a[href^="#"], .finding a[href^="#"], .flaggroup a[href^="#"]')
    .forEach(link => link.addEventListener('click', () => {
      const target = document.getElementById(decodeURIComponent(link.hash.slice(1)));
      if (target && target.classList.contains('card')) {
        requestAnimationFrame(() => target.scrollIntoView({block:'center', inline:'center'}));
      }
    }));
})();
"""


def tag(soup, name, text=None, **attrs):
    node = soup.new_tag(name, **attrs)
    if text is not None:
        node.string = text
    return node


def label(soup, origin, status=None):
    frag = []
    name = "Claude finding" if origin == "claude" else "Codex finding"
    frag.append(tag(soup, "span", name, **{"class": f"origin {origin}"}))
    if status:
        status_text = {"current": "Current issue", "qualified": "Qualified",
                       "unverified": "Needs verification", "resolved": "No current issue"}[status]
        frag.append(tag(soup, "span", status_text, **{"class": f"status {status}"}))
    return frag


def append_text(node, text):
    node.append(NavigableString(text))


def replace_once(source, old, new):
    if source.count(old) != 1:
        raise ValueError(f"Expected one source script hook: {old[:50]}")
    return source.replace(old, new)


def add_note(soup, card, finding, assessment=False):
    status = finding["status"]
    preview = finding.get("card_note", finding["title"])
    detail = finding.get("text", finding.get("detail", preview))
    for placement in (card, card.select_one("template")):
        if placement is None:
            continue
        ul = placement.select_one("ul.notes")
        if ul is None:
            ul = tag(soup, "ul", **{"class": "notes"})
            if placement.name == "template":
                placement.append(ul)
            else:
                placement.insert(-1, ul)
        li = tag(soup, "li", **{"class": f"codex-note {status}"})
        li.append(tag(soup, "span", "Codex assessment" if assessment else "Codex finding",
                      **{"class": "origin codex"}))
        li.append(label(soup, "codex", status)[1])
        append_text(li, " " + (detail if placement.name == "template" else preview))
        ul.append(li)
    card["class"] = list(dict.fromkeys(card.get("class", []) + ["flagged", f"codex-{status}"]))


def build(data_path):
    data = json.loads(data_path.read_text())
    source_html = (SOURCE / "index.html").read_text()
    soup = BeautifulSoup(source_html, "html.parser")
    existing = soup.select("ol.findings > li.finding")
    assessments = data["claude_assessments"]
    if len(existing) != len(assessments):
        raise ValueError(f"Expected {len(existing)} Claude assessments, got {len(assessments)}")

    soup.title.string = "Glass Table UX Audit · Claude + Codex"
    soup.select_one("h1").string = "Glass Table UX Audit · Claude + Codex"
    style = soup.select_one("style")
    style.append(NavigableString("\n" + CSS))
    top = soup.select_one("ol.findings")
    context = tag(soup, "div", **{"class": "report-context"})
    intro = tag(soup, "p")
    strong = tag(soup, "strong", "Review basis · ")
    intro.append(strong)
    append_text(intro, data.get("basis", "Original simulator crawl and source review."))
    context.append(intro)
    scope = tag(soup, "p")
    append_text(scope, "The original report and screenshots are preserved in their existing order. Claude findings are the authored notes in that report. Codex findings and assessments identify the current evidence level. Crawler flags are automated observations and need separate confirmation.")
    context.append(scope)
    top.insert_before(context)

    for li, assessment in zip(existing, assessments):
        status = assessment["status"]
        if status == "current":
            li["class"] = li.get("class", []) + ["current-issue"]
        li.insert(0, NavigableString(" "))
        for badge in reversed(label(soup, "claude")):
            li.insert(0, badge)
        block = tag(soup, "div", **{"class": "assessment"})
        for badge in label(soup, "codex", status):
            block.append(badge)
        para = tag(soup, "p", assessment["text"])
        block.append(para)
        li.append(block)
        title = li.select_one("b").get_text(" ", strip=True)
        for link in li.select(".where a[href^='#']"):
            anchor = link["href"][1:]
            card = soup.find(id=anchor)
            if card is None:
                raise ValueError(f"Unknown Claude finding card anchor: {anchor}")
            add_note(soup, card, {"status": status, "title": title,
                                  "card_note": f"{title} · {assessment['text'].split('.')[0]}." ,
                                  "text": assessment["text"]}, assessment=True)

    all_flags = soup.select_one("div.flags")
    review_group = all_flags.select_one("details.flaggroup")
    if review_group:
        summary = review_group.select_one("summary")
        summary.insert(0, tag(soup, "span", "Claude findings", **{"class": "origin claude"}))
        for chip in summary.select(".chip.review"):
            chip.string = "Claude"
    for chip in soup.select(".card .chip.review, #detail .chip.review, template .chip.review"):
        chip.string = "Claude finding"
    for chip in soup.select(".chip.crawler"):
        chip.string = "Crawler observation"
    key = tag(soup, "p", **{"class": "evidence-key"})
    key.append(tag(soup, "strong", "How to read flags · "))
    append_text(key, data.get("flag_note", "Small-target, unlabeled-control and no-change flags are crawler heuristics. They do not establish the tappable area, VoiceOver speech, or a defect on their own."))
    all_flags.insert_before(key)

    findings = data["codex_findings"]
    h2 = tag(soup, "h2", "Codex findings")
    h2["id"] = "codex-findings"
    ol = tag(soup, "ol", **{"class": "findings codex-findings"})
    for item in findings:
        status = item["status"]
        li = tag(soup, "li", **{"class": f"finding sev-{item['severity']}" + (" current-issue" if status == "current" else "")})
        for badge in label(soup, "codex", status):
            li.append(badge)
        li.append(tag(soup, "span", item["severity"], **{"class": f"chip sev-{item['severity']}"}))
        append_text(li, " ")
        li.append(tag(soup, "b", item["title"]))
        li.append(tag(soup, "p", item["detail"]))
        links = tag(soup, "div", **{"class": "where"})
        for anchor in item.get("where", []):
            card = soup.find(id=anchor)
            if card is None or "card" not in card.get("class", []):
                raise ValueError(f"Unknown card anchor: {anchor}")
            flow = card.find_parent("section", class_="flow")
            link = tag(soup, "a", f"{flow.h3.get_text(' ', strip=True)} › {card.h4.get_text(' ', strip=True)}", href=f"#{anchor}")
            links.append(link)
            add_note(soup, card, item)
        if links.contents:
            li.append(links)
        ol.append(li)
    flags_heading = all_flags.find_previous("h2")
    flags_heading.insert_before(h2)
    flags_heading.insert_before(ol)

    # Preserve source behavior while adding modal focus management to its own functions.
    script = soup.select("script")[-1]
    source_script = script.string
    source_script = replace_once(source_script, "let current = null;", "let current = null, priorFocus = null;")
    source_script = replace_once(source_script, "  current = card;\n  const thumb", "  priorFocus = document.activeElement;\n  current = card;\n  const thumb")
    source_script = replace_once(source_script, "  dlg.classList.add('open'); dlg.scrollTop = 0; row.scrollLeft = 0;",
        "  dlg.classList.add('open'); dlg.scrollTop = 0; row.scrollLeft = 0;\n  document.body.style.overflow = 'hidden'; dlg.querySelector('[data-close]').focus();")
    source_script = replace_once(source_script, "function close() { dlg.classList.remove('open'); if (current) current.querySelector('button.shot').focus(); }",
        "function close() { dlg.classList.remove('open'); document.body.style.overflow = ''; if (priorFocus && priorFocus.isConnected) priorFocus.focus(); else if (current) current.querySelector('button.shot').focus(); }")
    script.string = source_script
    script.append(NavigableString("\n" + JS))
    OUTPUT.mkdir(parents=True, exist_ok=True)
    image_dir = OUTPUT / "img"
    image_dir.mkdir(exist_ok=True)
    for source_img in (SOURCE / "img").iterdir():
        dest = image_dir / source_img.name
        if not dest.exists():
            try:
                os.link(source_img, dest)
            except OSError:
                shutil.copy2(source_img, dest)
    (OUTPUT / "index.html").write_text(str(soup))
    print(f"Wrote {OUTPUT / 'index.html'}: {len(existing)} Claude findings, {len(findings)} Codex findings, {len(soup.select('article.card'))} cards")


if __name__ == "__main__":
    build(Path(sys.argv[1]) if len(sys.argv) > 1 else FINDINGS)
