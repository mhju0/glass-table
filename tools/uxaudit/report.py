#!/usr/bin/env python3
"""Builds the UX audit report from UXAuditCrawl output.

    tools/uxaudit/report.py <crawl-dir> <report-dir> [--notes tools/uxaudit/notes.json]

<crawl-dir> holds one directory per flow (flow.json, NNN.json, NNN-k.png, problems.jsonl).
<report-dir> gets index.html plus img/ with downscaled JPEGs. Lesson flows that come in
two passes (<node>-a, <node>-b) are merged into one tree per lesson.
"""
import base64
import hashlib
import html
import io
import json
import os
import sys
from pathlib import Path

from PIL import Image

THUMB_W = 340
FULL_W = 750

SECTION_ORDER = ["시작 안내", "배우기 탭", "플레이 탭",
                 "1. 기본기", "2. 시작 패", "3. 가격과 확률", "4. 상대 읽기",
                 "5. 더 깊이 (선택)", "기록 탭", "설정 탭"]
SECTION_EN = {"시작 안내": "First-run guide", "배우기 탭": "Learn tab", "플레이 탭": "Play tab",
              "기록 탭": "Progress tab", "설정 탭": "Settings tab"}
BRANCH_LABEL = {"right": "Right answer", "close": "Close (근접)", "wrong": "Wrong answer",
                "question": "Question"}


def esc(s):
    return html.escape(str(s), quote=True)


def load_flows(root):
    flows = []
    for d in sorted(p for p in root.iterdir() if p.is_dir()):
        meta_path = d / "flow.json"
        if not meta_path.exists():
            continue
        meta = json.loads(meta_path.read_text())
        steps = []
        for f in sorted(d.glob("[0-9][0-9][0-9].json")):
            s = json.loads(f.read_text())
            s["dir"] = d
            steps.append(s)
        problems = []
        pj = d / "problems.jsonl"
        if pj.exists():
            for line in pj.read_text().splitlines():
                if line.strip():
                    problems.append(json.loads(line))
        meta["steps"] = steps
        meta["problems"] = problems
        meta["dir"] = d
        flows.append(meta)
    return flows


class Images:
    """Thumbnails are embedded as data URIs so the page shows every screen even when a
    viewer blocks side files; full-size images stay in img/ for the enlarged view."""

    def __init__(self, out):
        self.out = out / "img"
        self.out.mkdir(parents=True, exist_ok=True)
        self.cache = {}

    def convert(self, src):
        """Returns (thumb data URI, full path relative to the report, content hash)."""
        raw = src.read_bytes()
        digest = hashlib.sha1(raw).hexdigest()[:16]
        if digest in self.cache:
            return self.cache[digest]
        full = self.out / f"{digest}-f.jpg"
        im = Image.open(src).convert("RGB")
        if not full.exists():
            h = round(im.height * FULL_W / im.width)
            im.resize((FULL_W, h), Image.LANCZOS).save(full, "JPEG", quality=80, optimize=True)
        buf = io.BytesIO()
        h = round(im.height * THUMB_W / im.width)
        im.resize((THUMB_W, h), Image.LANCZOS).save(buf, "JPEG", quality=70, optimize=True)
        thumb = "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()
        self.cache[digest] = (thumb, f"img/{full.name}", digest)
        return self.cache[digest]


def auto_findings(step, prev_hash, hash0):
    """Heuristic flags for one step."""
    out = []
    if prev_hash is not None and hash0 == prev_hash and step.get("action"):
        out.append(("nochange", f"The screen looked identical after: {step['action']}"))
    for t in step.get("texts", []):
        if "…" in t:
            out.append(("truncated", f"Text is cut off: “{t}”"))
    small = []
    for c in step.get("controls", []):
        if c["type"] != "button" or not c.get("enabled", True):
            continue
        w, h = c["w"], c["h"]
        if min(w, h) < 44 and w * h > 0:
            name = c["label"] or c["id"] or "(unlabelled)"
            small.append(f"{name} ({w:.0f}×{h:.0f})")
        if not c["label"] and not c["id"]:
            out.append(("a11y", "A button has no label or identifier (VoiceOver reads nothing)"))
    if small:
        out.append(("target", "Tap targets under 44 pt: " + ", ".join(sorted(set(small)))))
    return out


def render_controls(step):
    rows = []
    for c in step.get("controls", []):
        label = c["label"] or "—"
        ident = c["id"]
        size = f"{c['w']:.0f}×{c['h']:.0f}"
        state = "" if c.get("enabled", True) else " <span class='chip off'>disabled</span>"
        small = " small" if c["type"] == "button" and min(c["w"], c["h"]) < 44 else ""
        rows.append(f"<tr class='{small.strip()}'><td>{esc(c['type'])}</td><td>{esc(label)}{state}</td>"
                    f"<td class='mono'>{esc(ident)}</td><td class='mono'>{size}</td></tr>")
    if not rows:
        return ""
    return (f"<h5>Tappable on this screen ({len(rows)})</h5><table><tr><th>Type</th><th>Label (what VoiceOver reads)</th>"
            "<th>Identifier</th><th>Size (pt)</th></tr>" + "".join(rows) + "</table>")


class Report:
    def __init__(self, flows, out, notes):
        self.flows = flows
        self.out = out
        self.notes = notes
        self.images = Images(out)
        self.flag_index = []  # (kind, text, anchor, flow title)

    def step_id(self, flow_id, step):
        return f"{flow_id}-s{step['step']}"

    def render_step(self, flow, step, prev_hash, small=False):
        """One card: what was tapped, the first frame, flags. The rest opens on click."""
        frames, thumb0, hash0 = [], None, None
        for i, name in enumerate(step["shots"]):
            src = step["dir"] / name
            if not src.exists():
                continue
            thumb, full, digest = self.images.convert(src)
            if thumb0 is None:
                thumb0, hash0 = thumb, digest
            frames.append(full)
        anchor = self.step_id(flow["id"], step)
        flags = auto_findings(step, prev_hash, hash0)
        manual = self.notes.get("steps", {}).get(flow["id"], {}).get(str(step["step"]), [])
        for p in flow["problems"]:
            if p.get("step") == step["step"]:
                flags.append(("crawler", p["text"]))
        for kind, text in flags:
            self.flag_index.append((kind, text, anchor, flow["title"], step["title"]))
        for text in manual:
            self.flag_index.append(("review", text, anchor, flow["title"], step["title"]))
        # Reviewer and crawler notes show on the card; heuristic ones only in the detail view.
        loud = [("review", t) for t in manual] + [(k, t) for k, t in flags if k == "crawler"]
        quiet = [(k, t) for k, t in flags if k != "crawler"]
        card_notes = "".join(f"<li class='n-{k}'><span class='chip {k}'>{k}</span> {esc(t)}</li>" for k, t in loud)
        detail_notes = "".join(f"<li><span class='chip {k}'>{k}</span> {esc(t)}</li>" for k, t in loud + quiet)
        detail_notes += "".join(f"<li class='n-info'>{esc(t)}</li>" for t in step.get("notes", []))
        branch = step.get("branch")
        badge = ""
        if branch and branch != "question":
            badge = f"<span class='chip b-{branch}'>{esc(BRANCH_LABEL.get(branch, branch))}</span>"
        action = f"<div class='action'><span class='tap'>Tap</span> {esc(step['action'])}</div>" if step.get("action") else ""
        verdict = f"<p class='verdict'>{esc(step['verdict'])}</p>" if step.get("verdict") else ""
        more = f"<span class='frames'>+{len(frames) - 1} scrolled</span>" if len(frames) > 1 else ""
        flagged = " flagged" if loud else (" soft" if quiet else "")
        detail = (f"<template>{action}<h4>{esc(step['title'])} {badge}</h4>{verdict}"
                  f"{('<ul class=notes>' + detail_notes + '</ul>') if detail_notes else ''}{render_controls(step)}</template>")
        return hash0, (
            f"<article class='card{flagged}{' small' if small else ''}' id='{anchor}' data-frames='{esc(json.dumps(frames))}'>"
            f"{action}<h4><span class='num'>{step['step']}</span>{esc(step['title'])}</h4>{badge}"
            f"<button class='shot' type='button' aria-label='{esc(step['title'])} 크게 보기'>"
            f"<img src='{thumb0 or ''}' alt='{esc(step['title'])}'>{more}</button>"
            f"{('<ul class=notes>' + card_notes + '</ul>') if card_notes else ''}{detail}</article>")

    def render_linear(self, flow):
        parts, prev = [], None
        for step in flow["steps"]:
            prev, card = self.render_step(flow, step, prev)
            parts.append(card)
        return "<div class='track'>" + "".join(parts) + "</div>"

    def render_lesson(self, a, b):
        """One row: pass A's screens in order; at each question the row forks into the
        first answer's outcome (top) and the second answer's (bottom)."""
        b_by_group = {}
        for s in (b["steps"] if b else []):
            if s.get("group"):
                b_by_group.setdefault(s["group"], []).append(s)
        parts, prev = [], None
        steps = a["steps"]
        i = 0
        while i < len(steps):
            s = steps[i]
            g = s.get("group")
            if g and s.get("branch") == "question":
                block, j, outcome_a = [s], i + 1, None
                while j < len(steps):
                    if steps[j].get("group") == g and steps[j].get("branch") != "question":
                        outcome_a = steps[j]
                        j += 1
                        break
                    block.append(steps[j])
                    j += 1
                for q in block:
                    prev, card = self.render_step(a, q, prev)
                    parts.append(card)
                forks = []
                if outcome_a:
                    forks.append(("첫 번째 답", self.render_step(a, outcome_a, None, small=True)[1], outcome_a))
                for ob in b_by_group.get(g, []):
                    forks.append(("두 번째 답", self.render_step(b, ob, None, small=True)[1], ob))
                parts.append("<div class='fork'>" + "".join(
                    f"<div class='branch b-{o.get('branch')}'><div class='branch-head'>{esc(t)} · "
                    f"{esc(BRANCH_LABEL.get(o.get('branch'), ''))}</div>{h}</div>" for t, h, o in forks) + "</div>")
                prev = None
                i = j
                continue
            prev, card = self.render_step(a, s, prev)
            parts.append(card)
            i += 1
        tail = [s for s in (b["steps"] if b else []) if not s.get("group")]
        if tail:
            parts.append("<div class='divider'><span>두 번째 풀이의 끝</span></div>")
            for s in tail:
                parts.append(self.render_step(b, s, None)[1])
        return "<div class='track'>" + "".join(parts) + "</div>"

    def build(self):
        by_id = {f["id"]: f for f in self.flows}
        sections = {}
        used = set()
        for f in self.flows:
            if f["id"] in used:
                continue
            if f.get("pass") == "b":
                continue
            entry = {"title": f["title"], "summary": f["summary"], "id": f["id"]}
            if f.get("pass") == "a":
                b = next((x for x in self.flows if x.get("group") == f["group"] and x.get("pass") == "b"), None)
                entry["title"] = f["title"].replace(" · 첫 번째 풀이", "").replace(" · 정답으로 끝까지", "")
                entry["summary"] = (f["summary"] + " " + (b["summary"] if b else "(두 번째 풀이 없음)"))
                entry["body"] = self.render_lesson(f, b)
                entry["id"] = f["group"]
                entry["problems"] = len(f["problems"]) + (len(b["problems"]) if b else 0)
                used.update({f["id"]} | ({b["id"]} if b else set()))
            else:
                entry["body"] = self.render_linear(f)
                entry["problems"] = len(f["problems"])
                used.add(f["id"])
            sections.setdefault(f["section"], []).append((f, entry))

        order = [s for s in SECTION_ORDER if s in sections] + [s for s in sections if s not in SECTION_ORDER]
        nav, body = [], []
        for sec in order:
            items = sections[sec]
            items.sort(key=lambda fe: fe[0].get("started", 0) if fe[0].get("pass") != "a" else unit_order(fe[0]))
            sec_id = "sec-" + hashlib.sha1(sec.encode()).hexdigest()[:8]
            en = SECTION_EN.get(sec, "Unit " + sec.split(".")[0] if sec[:1].isdigit() else sec)
            nav.append(f"<li><a href='#{sec_id}'>{esc(sec)}</a><ul>" + "".join(
                f"<li><a href='#{e['id']}'>{esc(e['title'])}</a></li>" for _, e in items) + "</ul></li>")
            flows_html = "".join(
                f"<section class='flow' id='{e['id']}'><h3>{esc(e['title'])}</h3>"
                f"<p class='summary'>{esc(e['summary'])}</p>{e['body']}</section>" for _, e in items)
            body.append(f"<section class='section' id='{sec_id}'><h2>{esc(sec)} <small>{esc(en)}</small></h2>{flows_html}</section>")

        total_steps = sum(len(f["steps"]) for f in self.flows)
        total_shots = sum(len(s["shots"]) for f in self.flows for s in f["steps"])
        flags_html = self.render_flag_index()
        page = TEMPLATE.format(nav="".join(nav), body="".join(body), flags=flags_html, top=self.render_top(),
                               flows=len(self.flows), steps=total_steps, shots=total_shots)
        (self.out / "index.html").write_text(page)

    def render_top(self):
        """Reviewer findings, most severe first, each linked to the steps that show it."""
        items = self.notes.get("top", [])
        if not items:
            return ""
        lis = []
        for f in items:
            names = {(fl["id"], st["step"]): (fl["title"], st["title"]) for fl in self.flows for st in fl["steps"]}
            links = ", ".join(f"<a href='#{fl}-s{st}'>{esc(names.get((fl, st), (fl, st))[0])} › "
                              f"{esc(str(names.get((fl, st), (fl, st))[1]))}</a>" for fl, st in f.get("where", []))
            lis.append(f"<li class='finding sev-{f['sev']}'><span class='chip sev-{f['sev']}'>{esc(f['sev'])}</span> "
                       f"<b>{esc(f['title'])}</b><p>{esc(f['detail'])}</p>"
                       f"{('<div class=where>' + links + '</div>') if links else ''}</li>")
        return f"<h2 style='border:0;margin-top:8px'>Top findings</h2><ol class='findings'>{''.join(lis)}</ol>"

    def render_flag_index(self):
        kinds = [("review", "Reviewer notes (read by a person)"),
                 ("crawler", "The crawler got stuck or could not do something"),
                 ("truncated", "Text cut off"),
                 ("nochange", "Tap with no visible change"),
                 ("a11y", "Unlabelled buttons"),
                 ("target", "Small tap targets")]
        out = []
        for kind, title in kinds:
            items = [f for f in self.flag_index if f[0] == kind]
            if not items:
                continue
            # Collapse identical texts, keep every place they occur.
            grouped = {}
            for _, text, anchor, flow, step in items:
                grouped.setdefault(text, []).append((anchor, flow, step))
            lis = []
            for text, places in grouped.items():
                links = ", ".join(f"<a href='#{a}'>{esc(fl)} › {esc(st)}</a>" for a, fl, st in places[:12])
                more = f" and {len(places) - 12} more" if len(places) > 12 else ""
                lis.append(f"<li>{esc(text)}<div class='where'>{links}{more}</div></li>")
            out.append(f"<details class='flaggroup' {'open' if kind in ('review', 'crawler') else ''}>"
                       f"<summary><span class='chip {kind}'>{kind}</span> {esc(title)} ({len(grouped)})</summary>"
                       f"<ul>{''.join(lis)}</ul></details>")
        return "".join(out) or "<p>No flags.</p>"


def unit_order(flow):
    return flow.get("started", 0)


TEMPLATE = """<!doctype html>
<html lang="ko"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Glass Table UX Audit</title>
<style>
:root {{ --bg:#f6f4ef; --panel:#fff; --ink:#1d1b17; --muted:#6b665c; --line:#e3ded3;
  --accent:#8a5a00; --right:#1f7a4d; --wrong:#b3261e; --close:#a66a00; --flag:#fff4d6; --shade:rgba(12,11,9,.95); }}
@media (prefers-color-scheme: dark) {{ :root:not([data-theme="light"]) {{ --bg:#15140f; --panel:#1f1d18; --ink:#eeeae0;
  --muted:#a39d90; --line:#34312a; --accent:#e0a93a; --right:#5fcf93; --wrong:#ff8a80; --close:#f0b54a; --flag:#3a3220; }} }}
:root[data-theme="dark"] {{ --bg:#15140f; --panel:#1f1d18; --ink:#eeeae0; --muted:#a39d90; --line:#34312a;
  --accent:#e0a93a; --right:#5fcf93; --wrong:#ff8a80; --close:#f0b54a; --flag:#3a3220; }}
* {{ box-sizing:border-box }}
body {{ margin:0; background:var(--bg); color:var(--ink); font:15px/1.5 -apple-system, "Apple SD Gothic Neo", "Pretendard", system-ui, sans-serif; }}
.layout {{ display:grid; grid-template-columns:250px minmax(0,1fr); }}
nav {{ position:sticky; top:0; height:100vh; overflow:auto; padding:20px 14px; border-right:1px solid var(--line); background:var(--panel); font-size:13px }}
nav ul {{ list-style:none; margin:0; padding:0 }} nav li li {{ padding-left:12px }}
nav > ul > li {{ margin-bottom:10px }} nav > ul > li > a {{ font-weight:650 }}
nav a {{ color:var(--ink); text-decoration:none; display:block; padding:2px 0 }} nav a:hover {{ color:var(--accent) }}
main {{ padding:28px 28px 80px; min-width:0 }}
h1 {{ margin:0 0 4px; font-size:28px }} .meta {{ color:var(--muted); margin:0 0 16px; max-width:90ch }}
h2 {{ font-size:24px; margin:44px 0 4px; padding-top:12px; border-top:2px solid var(--ink) }} h2 small {{ color:var(--muted); font-weight:500; font-size:15px }}
.flow {{ margin:18px 0 26px }} .flow > h3 {{ font-size:19px; margin:0 0 2px }}
.summary {{ color:var(--muted); margin:0 0 8px; max-width:95ch; font-size:14px }}
/* One flow = one horizontal row of screens. */
.track {{ display:flex; align-items:flex-start; gap:22px; overflow-x:auto; padding:10px 6px 16px; scroll-snap-type:x proximity;
  background:color-mix(in srgb, var(--line) 30%, transparent); border-radius:14px }}
.card {{ position:relative; flex:0 0 184px; width:184px; background:var(--panel); border:1px solid var(--line); border-radius:12px; padding:8px; scroll-snap-align:start }}
.track > .card + .card::before, .track > .fork + .card::before, .track > .card + .fork::before, .track > .divider + .card::before {{
  content:"→"; position:absolute; left:-18px; top:150px; color:var(--muted); font-size:15px }}
.track > .fork {{ position:relative }}
.card.flagged {{ border:2px solid var(--accent) }}
.card h4 {{ margin:2px 0 6px; font-size:13px; line-height:1.3; display:flex; gap:6px }}
.num {{ font:600 11px ui-monospace, monospace; color:var(--muted); padding-top:1px }}
.action {{ font-size:11.5px; color:var(--muted); line-height:1.3; margin-bottom:2px; display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden }}
.tap {{ font-weight:700; color:var(--accent); text-transform:uppercase; font-size:10px; letter-spacing:.04em; margin-right:3px }}
button.shot {{ all:unset; cursor:zoom-in; display:block; position:relative; margin-top:4px }}
button.shot:focus-visible {{ outline:2px solid var(--accent); outline-offset:2px; border-radius:12px }}
button.shot img {{ width:100%; height:auto; display:block; border-radius:12px; border:1px solid var(--line) }}
.frames {{ position:absolute; right:6px; bottom:6px; background:rgba(0,0,0,.7); color:#fff; font-size:11px; padding:1px 7px; border-radius:99px }}
.card > .chip {{ margin:0 0 2px }}
.fork {{ flex:0 0 auto; display:flex; flex-direction:column; gap:10px; padding-left:12px; border-left:3px solid var(--line) }}
.branch-head {{ font-size:11.5px; font-weight:700; margin:0 0 4px }}
.branch.b-right .branch-head {{ color:var(--right) }} .branch.b-wrong .branch-head {{ color:var(--wrong) }} .branch.b-close .branch-head {{ color:var(--close) }}
.card.small {{ flex-basis:128px; width:128px; padding:6px }} .card.small .action {{ -webkit-line-clamp:1 }} .card.small h4 {{ font-size:12px }}
.divider {{ flex:0 0 auto; align-self:stretch; display:flex; align-items:center; border-left:2px dashed var(--line); padding-left:10px; color:var(--muted); font-size:12px; writing-mode:vertical-rl }}
.chip {{ display:inline-block; font-size:10.5px; font-weight:700; padding:0 7px; border-radius:99px; border:1px solid currentColor; white-space:nowrap }}
.chip.b-right {{ color:var(--right) }} .chip.b-wrong {{ color:var(--wrong) }} .chip.b-close {{ color:var(--close) }}
.chip.review {{ color:var(--accent) }} .chip.crawler {{ color:var(--wrong) }} .chip.off {{ color:var(--muted) }}
.chip.truncated, .chip.nochange, .chip.a11y, .chip.target {{ color:var(--muted) }}
.card ul.notes {{ margin:6px 0 0; padding:0; list-style:none; font-size:11.5px; line-height:1.35 }}
.card ul.notes li {{ margin:3px 0; padding:4px 6px; border-radius:6px; background:var(--flag) }}
ol.findings {{ padding-left:20px }} ol.findings li {{ margin:0 0 14px }} ol.findings p {{ margin:4px 0; color:var(--muted); max-width:90ch }}
.chip.sev-crash, .chip.sev-high {{ background:var(--wrong); color:#fff }} .chip.sev-medium {{ background:var(--close); color:#fff }}
.chip.sev-low {{ background:var(--line); color:var(--ink) }}
.flags {{ background:var(--panel); border:1px solid var(--line); border-radius:12px; padding:12px 16px; margin:12px 0 24px }}
.flaggroup {{ margin:6px 0 }} .flaggroup summary {{ cursor:pointer; font-weight:650 }}
.flaggroup ul {{ font-size:13.5px }} .where {{ font-size:12px; color:var(--muted) }} .where a {{ color:var(--muted) }}
.toolbar {{ display:flex; gap:12px; align-items:center; margin:0 0 12px; font-size:13px; flex-wrap:wrap }}
body.only-flagged .card:not(.flagged) {{ opacity:.25 }}
:target {{ outline:3px solid var(--accent); outline-offset:3px }}
/* Detail view: every scrolled frame side by side, then the notes and controls. */
#detail {{ position:fixed; inset:0; background:var(--shade); display:none; z-index:10; overflow:auto; padding:20px; color:#eee }}
#detail.open {{ display:block }}
#detail .bar {{ display:flex; gap:10px; align-items:center; margin-bottom:12px; position:sticky; top:0 }}
#detail .bar button {{ font:inherit; font-size:13px; padding:6px 12px; border-radius:8px; border:1px solid #666; background:#222; color:#eee; cursor:pointer }}
#detail .bar .where {{ color:#bbb; font-size:13px }}
#detail .frames-row {{ display:flex; gap:12px; overflow-x:auto; padding-bottom:8px }}
#detail .frames-row img {{ height:min(82vh, 1334px); width:auto; border-radius:18px; flex:0 0 auto; background:#111 }}
#detail .info {{ max-width:900px; margin-top:12px; background:var(--panel); color:var(--ink); border-radius:12px; padding:12px 16px }}
#detail .info h4 {{ margin:4px 0; font-size:16px }} #detail .info h5 {{ margin:12px 0 4px; font-size:13px }}
#detail ul.notes {{ padding-left:0; list-style:none; font-size:13px }} #detail ul.notes li {{ margin:4px 0 }}
table {{ border-collapse:collapse; width:100%; font-size:12.5px }} td, th {{ border-bottom:1px solid var(--line); padding:3px 6px; text-align:left; vertical-align:top }}
tr.small td:last-child {{ color:var(--wrong) }} .mono {{ font-family:ui-monospace, monospace; font-size:11.5px }}
.verdict {{ color:var(--muted); font-size:13px; margin:4px 0 }}
@media (max-width: 800px) {{ .layout {{ display:block }} nav {{ position:static; height:auto; max-height:40vh; border-right:0; border-bottom:1px solid var(--line) }}
  main {{ padding:16px }} .card {{ flex-basis:150px; width:150px }} }}
</style></head>
<body><div class="layout"><nav><ul>{nav}</ul></nav><main>
<h1>Glass Table UX Audit</h1>
<p class="meta">iPhone 12 mini simulator (iOS 27), Korean, light mode, default text size. {flows} flows, {steps} steps, {shots} screenshots. Each flow is one row: scroll it sideways. In lessons the row forks at every question into the first answer (top) and the second answer (bottom). Click a screen to see the whole scrolled page, notes and controls; use ← → to move through the flow and Esc to close.</p>
<div class="toolbar"><label><input type="checkbox" id="onlyFlagged"> Dim screens without reviewer or crawler notes</label>
<button id="theme" type="button">Toggle theme</button></div>
{top}
<h2 style="border:0;margin-top:8px">All flags</h2><div class="flags">{flags}</div>
{body}
</main></div>
<div id="detail" role="dialog" aria-modal="true"><div class="bar"><button type="button" data-go="-1">← 이전</button>
<button type="button" data-go="1">다음 →</button><button type="button" data-close>닫기 (Esc)</button><span class="where"></span></div>
<div class="frames-row"></div><div class="info"></div></div>
<script>
const dlg = document.getElementById('detail'), row = dlg.querySelector('.frames-row'), info = dlg.querySelector('.info');
let current = null;
function show(card) {{
  current = card;
  const thumb = card.querySelector('button.shot img').src;
  row.replaceChildren(...JSON.parse(card.dataset.frames).map((src, i) => {{
    const img = new Image(); img.alt = ''; img.src = src;
    img.onerror = () => {{ if (i === 0) img.src = thumb; else img.remove(); }};
    return img;
  }}));
  info.replaceChildren(card.querySelector('template').content.cloneNode(true));
  const flow = card.closest('.flow');
  dlg.querySelector('.where').textContent = (flow ? flow.querySelector('h3').textContent + ' · ' : '') + '#' + card.id;
  dlg.classList.add('open'); dlg.scrollTop = 0; row.scrollLeft = 0;
}}
function step(d) {{
  if (!current) return;
  const cards = [...current.closest('.track').querySelectorAll('.card')];
  const next = cards[cards.indexOf(current) + d];
  if (next) {{ show(next); next.scrollIntoView({{block:'nearest', inline:'center'}}); }}
}}
function close() {{ dlg.classList.remove('open'); if (current) current.querySelector('button.shot').focus(); }}
document.addEventListener('click', e => {{
  const b = e.target.closest('button.shot'); if (b) {{ show(b.closest('.card')); return; }}
  const g = e.target.closest('[data-go]'); if (g) {{ step(+g.dataset.go); return; }}
  if (e.target.closest('[data-close]') || e.target === dlg) close();
}});
document.addEventListener('keydown', e => {{
  if (!dlg.classList.contains('open')) return;
  if (e.key === 'Escape') close(); else if (e.key === 'ArrowRight') step(1); else if (e.key === 'ArrowLeft') step(-1);
}});
document.getElementById('onlyFlagged').addEventListener('change', e => document.body.classList.toggle('only-flagged', e.target.checked));
document.getElementById('theme').addEventListener('click', () => {{
  const r = document.documentElement; const dark = r.dataset.theme ? r.dataset.theme === 'dark' : matchMedia('(prefers-color-scheme: dark)').matches;
  r.dataset.theme = dark ? 'light' : 'dark';
}});
</script></body></html>
"""


def main():
    args = sys.argv[1:]
    notes_path = None
    if "--notes" in args:
        i = args.index("--notes")
        notes_path = Path(args[i + 1])
        del args[i:i + 2]
    crawl, out = Path(args[0]), Path(args[1])
    out.mkdir(parents=True, exist_ok=True)
    notes = json.loads(notes_path.read_text()) if notes_path and notes_path.exists() else {}
    report = Report(load_flows(crawl), out, notes)
    report.build()
    print(out / "index.html")


if __name__ == "__main__":
    main()
