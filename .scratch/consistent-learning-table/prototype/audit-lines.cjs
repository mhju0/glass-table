// Line-break audit: renders every scripted state in Korean and English and compares
// each text block's line count, last-line fill and in-word breaks.
// Usage: GT_DESIGN=refined GT_SIZE=normal node audit-lines.cjs [--json out.json]
const {execFileSync} = require('node:child_process');
const fs = require('node:fs');
const cli = process.env.AGENT_BROWSER || 'agent-browser';
const design = process.env.GT_DESIGN === 'refined' ? 'refined' : 'current';
const size = process.env.GT_SIZE === 'large' ? 'large' : 'normal';
const session = `gt-lines-${design}-${size}`;
const call = (...args) => {
  const result = JSON.parse(execFileSync(cli,['--session',session,'--json',...args],{encoding:'utf8',timeout:30000}));
  if (!result.success) throw new Error(JSON.stringify(result.error));
  return result.data;
};
const evalJs = code => call('eval',code).result;

const SELECTORS = ['.top .title','.top .text-button','.eyebrow','.prompt','.support','.small','.section-title',
  '.button','.choice','.text-button:not(.top .text-button)','.result strong','.result p','.steps p','.steps[data-help]',
  '.status-note','.footer-note','.example-line','.active-action','.mode-tile strong','.mode-tile span',
  '.seat strong','.seat .caption','.pot-label','.example-pairs span'];

// Sentences and headings should also end at a similar width in both languages.
const PROSE = ['.prompt','.support','.small','.result strong','.result p','.steps p','.steps[data-help]','.status-note','.footer-note','.example-line'];
const PARITY = 0.25;

// Measures one element per character so wraps, fill and in-word breaks are exact.
const MEASURE = `(() => {
  const word = /[\\p{L}\\p{N}]/u;
  const out = [];
  ${JSON.stringify(SELECTORS)}.forEach(sel => document.querySelectorAll(sel).forEach((el, i) => {
    if (!el.textContent.trim() || !el.getClientRects().length) return;
    const cs = getComputedStyle(el), box = el.getBoundingClientRect();
    const left = box.left + parseFloat(cs.paddingLeft) + parseFloat(cs.borderLeftWidth);
    const width = box.width - parseFloat(cs.paddingLeft) - parseFloat(cs.paddingRight) - parseFloat(cs.borderLeftWidth) - parseFloat(cs.borderRightWidth);
    const chars = [];
    const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
    const range = document.createRange();
    while (walker.nextNode()) {
      const node = walker.currentNode;
      chars.push({ch: '', r: null}); // a node boundary (e.g. <br>) is a legitimate break point
      for (let k = 0; k < node.length; k++) {
        const ch = node.data[k];
        range.setStart(node, k); range.setEnd(node, k + 1);
        const r = range.getClientRects()[0];
        chars.push({ch, r: r && r.width > 0 ? {top: r.top, left: r.left, right: r.right, h: r.height} : null});
      }
    }
    const lines = [];
    let prev = null, midword = [];
    chars.forEach((c, k) => {
      if (!c.r) { prev = null; return; }
      let line = lines[lines.length - 1];
      if (!line || c.r.top > line.top + line.h * 0.5) {
        if (prev && word.test(prev.ch) && word.test(c.ch)) midword.push(prev.ch + '|' + c.ch);
        line = {top: c.r.top, h: c.r.h, left: c.r.left, right: c.r.right, text: ''};
        lines.push(line);
      }
      line.left = Math.min(line.left, c.r.left); line.right = Math.max(line.right, c.r.right);
      line.text += c.ch; prev = c;
    });
    if (!lines.length) return;
    const last = lines[lines.length - 1];
    out.push({key: sel + '#' + i, text: el.textContent.trim().replace(/\\s+/g, ' '), lines: lines.length,
      lastFill: +((last.right - last.left) / width).toFixed(2), firstFill: +((lines[0].right - lines[0].left) / width).toFixed(2),
      lastLine: last.text.trim(), midword});
  }));
  return out;
})()`;

module.exports = {MEASURE, PROSE, PARITY};
if (require.main !== module) return;

// Every screen and state the prototype can show.
const STATES = [];
const add = (name, setup) => STATES.push({name, setup});
add('home', "state.stage='home'");
for (const mode of ['pot','position','combos','play']) {
  add(`intro ${mode}`, `state.mode='${mode}';state.stage='intro';state.exampleExpanded=false`);
  if (mode === 'position' || mode === 'combos') add(`intro ${mode} expanded`, `state.mode='${mode}';state.stage='intro';state.exampleExpanded=true`);
}
const practice = (mode, extra) => `state.mode='${mode}';state.stage='practice';state.step=0;state.answered=null;state.assisted=false;state.showSteps=false;${extra}`;
for (let s = 0; s < 7; s++) add(`pot step ${s + 1}`, practice('pot', `state.step=${s}`));
add('pot help', practice('pot', 'state.step=6;state.assisted=true;state.showSteps=true'));
add('pot incorrect', practice('pot', 'state.step=6;state.answered=45'));
add('pot incorrect steps', practice('pot', 'state.step=6;state.answered=45;state.showSteps=true'));
add('pot correct', practice('pot', 'state.step=6;state.answered=43'));
add('pot assisted', practice('pot', 'state.step=6;state.assisted=true;state.answered=43'));
add('position question', practice('position', ''));
add('position correct', practice('position', "state.answered='button'"));
add('position incorrect', practice('position', "state.answered='sb'"));
add('combos question', practice('combos', ''));
add('combos correct', practice('combos', "state.answered='12'"));
add('combos incorrect', practice('combos', "state.answered='6'"));
for (let s = 0; s < 6; s++) add(`play step ${s + 1}`, practice('play', `state.step=${s}`));

call('open', `http://127.0.0.1:8769/.scratch/consistent-learning-table/prototype/?design=${design}`);
call('set', 'viewport', '375', '812');
const rows = [];
for (const st of STATES) {
  const measured = {};
  for (const lang of ['ko','en']) {
    evalJs(`state.lang='${lang}';state.theme='light';state.size='${size}';state.design='${design}';${st.setup};render();document.fonts.ready.then(()=>1)`);
    measured[lang] = evalJs(MEASURE);
  }
  const en = Object.fromEntries(measured.en.map(m => [m.key, m]));
  for (const ko of measured.ko) {
    const e = en[ko.key]; if (!e) continue;
    const issues = [];
    if (ko.lines !== e.lines) issues.push(`lines ko ${ko.lines} / en ${e.lines}`);
    for (const [lang, m] of [['ko', ko], ['en', e]]) {
      if (m.lines > 1 && m.lastFill < 0.5) issues.push(`${lang} widow ${Math.round(m.lastFill * 100)}% "${m.lastLine}"`);
      if (m.midword.length) issues.push(`${lang} in-word break ${m.midword.join(', ')}`);
    }
    const sel = ko.key.split('#')[0];
    if (PROSE.includes(sel) && ko.lines === e.lines && Math.abs(ko.lastFill - e.lastFill) > PARITY)
      issues.push(`width ko ${Math.round(ko.lastFill * 100)}% / en ${Math.round(e.lastFill * 100)}%`);
    rows.push({state: st.name, key: ko.key, ko, en: e, issues});
  }
}
call('close');

// The same string appears in several states; report each distinct problem once.
const seen = new Set(), problems = [];
for (const r of rows.filter(r => r.issues.length)) {
  const id = r.key.split('#')[0] + r.ko.text + r.issues.join();
  if (!seen.has(id)) { seen.add(id); problems.push(r); }
}
console.log(`${design} / ${size}: ${STATES.length} states, ${rows.length} text blocks, ${problems.length} distinct problems`);
for (const p of problems) console.log(`- [${p.state}] ${p.key.split('#')[0]}: ${p.issues.join('; ')}\n    KO: ${p.ko.text}\n    EN: ${p.en.text}`);
const jsonAt = process.argv.indexOf('--json');
if (jsonAt > 0) fs.writeFileSync(process.argv[jsonAt + 1], JSON.stringify({design, size, rows}, null, 1));
