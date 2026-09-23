const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const cli = process.env.GT_BROWSER_CLI || 'agent-browser';
const session = process.env.GT_BROWSER_SESSION || 'gt-beginner-review';
const url = process.env.GT_PREVIEW_URL || 'http://127.0.0.1:8768/.scratch/beginner-learning-release/prototype/';
const output = path.join(__dirname, 'evidence');
fs.mkdirSync(output, { recursive: true });
const run = (...args) => {
  const value = JSON.parse(execFileSync(cli, ['--session', session, '--json', ...args], { encoding: 'utf8', timeout: 20000 }));
  assert.equal(value.success, true, JSON.stringify(value));
  return value.data;
};
const evaluate = expression => run('eval', expression).result;
const click = (action, value) => {
  const selector = `[data-action="${action}"]${value === undefined ? '' : `[data-value="${value}"]`}`;
  evaluate(`document.querySelector(${JSON.stringify(selector)})?.scrollIntoView({block:'center',behavior:'instant'})`);
  return run('click', selector);
};
const checks = [];
const pass = label => { checks.push(label); console.log(`PASS ${label}`); };

run('open', url);
run('set', 'viewport', '375', '812');
if (!process.env.GT_LAYOUT_ONLY) {
assert.deepEqual(evaluate('[...document.querySelectorAll(".bottomnav button")].map(e=>e.textContent.trim())'), ['♠Learn', '▤Play', '▥Progress']);
assert.equal(evaluate('document.querySelector(".bottomnav [data-value=learn]").getAttribute("aria-current")'), 'page');
click('learn-sample', 'review');
assert.ok(evaluate('document.querySelector(".recommendation").textContent').includes('not connected to a real review schedule'));
click('learn-sample', 'next');
assert.equal(evaluate('document.querySelectorAll(".recommendation .btn").length'), 1);
pass('Three destinations; one honest next/review fixture recommendation on Learn');
click('settings-open');
run('press', 'Shift+Tab');
assert.equal(evaluate('document.querySelector("[role=dialog]").contains(document.activeElement)'), true);
for (let i = 0; i < 10; i++) {
  run('press', 'Tab');
  assert.equal(evaluate('document.querySelector("[role=dialog]").contains(document.activeElement)'), true);
}
click('language', 'en');
click('theme', 'light');
run('press', 'Escape');
assert.equal(evaluate('state.settings'), false);
assert.equal(evaluate('document.activeElement?.dataset.action'), 'settings-open');
pass('Settings opens, changes language/theme, Escape closes and restores focus');

click('practice-intro');
click('practice-start');
assert.equal(evaluate('document.querySelector(".bottomnav [data-value=learn]").getAttribute("aria-current")'), 'page');
click('practice-answer', 'you');
const beforeLanguage = evaluate('JSON.stringify({q:state.q,answers:state.answers,answer:state.answer})');
click('settings-open');
click('language', 'ko');
click('theme', 'dark');
click('settings-close');
assert.equal(evaluate('JSON.stringify({q:state.q,answers:state.answers,answer:state.answer})'), beforeLanguage);
pass('Language and appearance switches preserve the committed question');
click('practice-next');
click('practice-help');
click('practice-answer', 'them');
click('practice-next');
click('practice-answer', 'tie');
click('practice-next');
const beforeLeave = evaluate('JSON.stringify({q:state.q,answers:state.answers})');
click('nav', 'learn');
assert.equal(evaluate('document.querySelector(".recommendation h2").textContent'), '풀던 문제');
click('practice-resume');
assert.equal(evaluate('JSON.stringify({q:state.q,answers:state.answers})'), beforeLeave);
pass('Leaving after three answers and continuing preserves the in-memory round');
click('practice-answer', 'them');
click('practice-next');
click('practice-answer', 'you');
click('practice-next');
assert.equal(evaluate('state.practiceStage'), 'summary');
assert.equal(evaluate('state.answers.length'), 5);
click('nav', 'learn');
assert.equal(evaluate('document.querySelector(".recommendation h2").textContent'), '이번 연습을 마쳤어요');
click('practice-resume');
assert.equal(evaluate('state.practiceStage'), 'summary');
pass('Five-question round reaches summary with assistance and a wrong answer');

click('nav', 'learn');
click('chart-open');
assert.equal(evaluate('document.querySelector(".bottomnav [data-value=learn]").getAttribute("aria-current")'), 'page');
assert.equal(evaluate('document.querySelectorAll(".chart-overview,.chart-explore").length'), 0);
click('chart-choose', 'fold');
assert.equal(evaluate('document.querySelectorAll(".chart-cell").length'), 169);
click('chart-expand');
assert.equal(evaluate('document.querySelectorAll(".chart-explore button").length'), 169);
click('chart-cell', 'AA');
assert.equal(evaluate('state.chartCell'), 'AA');
pass('Chart remains hidden before commitment; overview and cell explorer work');

click('nav', 'opponents');
assert.equal(evaluate('document.querySelector(".bottomnav [data-value=opponents]").getAttribute("aria-current")'), 'page');
assert.ok(!evaluate('document.querySelector("main").textContent').includes('VPIP'));
for (const [id, vpip, pfr] of [['nit',12,9], ['tag',20,17], ['lag',27,22], ['station',40,10], ['maniac',55,40]]) {
  click('opp-select', id);
  assert.equal(evaluate('document.querySelectorAll("#opponent-habits").length'), 1);
  assert.deepEqual(evaluate('[...document.querySelectorAll("#opponent-habits .behavior-track")].map(e=>e.getAttribute("aria-label"))'), [`판에 들어오기: ${vpip}%, 드물게–자주`, `금액 올리기: ${pfr}%, 드물게–자주`]);
  assert.equal(evaluate('document.querySelectorAll(".opponent[aria-pressed=true]").length'), 1);
}
click('settings-open');
click('language', 'en');
click('settings-close');
assert.equal(evaluate('document.querySelector("h1").textContent'), 'Choose an opponent');
assert.deepEqual(evaluate('[...document.querySelectorAll("#opponent-habits .behavior-track")].map(e=>e.getAttribute("aria-label"))'), ['Joins a hand: 55%, Rarely–Often', 'Raises the bet: 40%, Rarely–Often']);
click('opp-details');
assert.ok(evaluate('document.querySelector(".detail-panel").textContent').includes('VPIP'));
click('table-start');
assert.deepEqual(evaluate('[...document.querySelectorAll(".seat strong")].map(e=>e.textContent.split(" · ")[0].trim())'), ['Computer 3', 'Computer 1', 'Computer 2', 'Me']);
click('table-next');
click('table-prev');
assert.equal(evaluate('state.tableIndex'), -1);
for (let i = 0; i < 15; i++) click('table-next');
click('table-review');
click('table-hindsight');
assert.equal(evaluate('state.hindsight'), true);
click('table-hindsight');
click('table-reset');
assert.equal(evaluate('state.tableIndex'), -1);
pass('All opponent choices/details, replay controls, settlement review, hindsight and reset');

click('nav', 'records');
click('records-state', 'empty');
click('records-state', 'error');
click('records-retry');
run('wait', '--fn', 'state.recordsState === "sample"');
assert.equal(evaluate('state.recordsState'), 'sample');
click('style-toggle');
click('style-toggle');
for (let i = 0; i < 5; i++) click('style-detail', String(i));
pass('Records empty/error/retry and all style descriptions/insufficient state');
}

if (process.env.GT_LAYOUT_ONLY === '1') {
  click('nav', 'learn');
  click('practice-intro');
  click('practice-start');
  click('practice-answer', 'you');
  const retained = evaluate('JSON.stringify(state.answers)');
  click('nav', 'learn');
  click('practice-intro');
  click('practice-resume');
  assert.equal(evaluate('JSON.stringify(state.answers)'), retained);
  click('nav', 'learn');
  click('chart-open');
  click('chart-choose', 'call');
  click('chart-expand');
  click('chart-cell', 'AA');
  click('chart-own');
  assert.equal(evaluate('state.chartCell'), 'J5o');
  assert.equal(evaluate(`(()=>{const r=document.querySelector('[data-action="chart-cell"][data-value="J5o"]').getBoundingClientRect(),c=document.querySelector('.chart-explore').getBoundingClientRect();return r.left>=c.left&&r.right<=c.right&&r.top>=c.top&&r.bottom<=c.bottom})()`), true);
  run('click', '.chart-rows summary');
  assert.equal(evaluate('document.querySelector(".chart-rows").open'), true);
  run('click', '.chart-rows summary');
  click('chart-expand');
  click('chart-reset');
  assert.equal(evaluate('state.chartChoice'), null);
  click('nav', 'records');
  click('timing-toggle');
  assert.equal(evaluate('state.timing'), true);
  click('timing-toggle');
  assert.equal(evaluate('state.timing'), false);
  click('records-state', 'loading');
  run('wait', '--fn', 'state.recordsState === "sample"');
  assert.equal(evaluate('state.recordsState'), 'sample');
  click('settings-open');
  click('language', 'system');
  run('mouse', 'move', '8', '8');
  run('mouse', 'down');
  run('mouse', 'up');
  assert.equal(evaluate('state.settings'), false);
  pass('Intro replay preserves answer; chart own-cell scroll, row text and reset; optional timing, loading and Settings backdrop');
}

const fixtures = {
  learn: { route: 'learn', practiceStage: 'idle', learnRecommendation: 'next' },
  learnReview: { route: 'learn', practiceStage: 'idle', learnRecommendation: 'review' },
  learnIntro: { route: 'learn', practiceStage: 'intro' },
  learnResume: { route: 'learn', practiceStage: 'question', q: 2, answer: null },
  learnDone: { route: 'learn', practiceStage: 'summary' },
  settings: { route: 'learn', settings: true },
  opponents: { route: 'opponents', opp: 'tag', oppDetails: false },
  opponentLast: { route: 'opponents', opp: 'maniac', oppDetails: false },
  opponentDetails: { route: 'opponents', opp: 'station', oppDetails: true },
  intro: { route: 'practice', practiceStage: 'intro' },
  question: { route: 'practice', practiceStage: 'question', q: 0, answer: null, help: false },
  summary: { route: 'practice', practiceStage: 'summary' },
  chart: { route: 'chart', chartChoice: 'fold', chartExpanded: false },
  explorer: { route: 'chart', chartChoice: 'fold', chartExpanded: true, chartCell: 'J5o' },
  table: { route: 'table', tableReview: false, tableIndex: 7 },
  review: { route: 'table', tableReview: true, hindsight: true },
  records: { route: 'records', recordsState: 'sample', styleState: 'sample' },
  empty: { route: 'records', recordsState: 'empty', styleState: 'short' },
  error: { route: 'records', recordsState: 'error', styleState: 'short' }
};
let layouts = 0;
for (const width of [320, 375]) for (const lang of ['ko', 'en']) for (const theme of ['light', 'dark']) for (const size of [16, 32]) {
  run('set', 'viewport', String(width), '812');
  for (const [name, fixture] of Object.entries(fixtures)) {
    evaluate(`Object.assign(state,${JSON.stringify({ lang, langOption: lang, theme, settings: false, ...fixture })});document.documentElement.style.fontSize='${size}px';render();window.scrollTo(0,0)`);
    const layout = evaluate(`({width:innerWidth,scroll:document.documentElement.scrollWidth,small:[...document.querySelectorAll('button,summary')].filter(e=>!e.disabled&&e.getClientRects().length).filter(e=>{const r=e.getBoundingClientRect();return r.width<43.9||r.height<43.9}).map(e=>({text:e.textContent,width:e.getBoundingClientRect().width,height:e.getBoundingClientRect().height})),text:document.querySelector('main').innerText})`);
    assert.ok(layout.scroll <= layout.width, `${name}/${lang}/${theme}/${width}/${size} horizontal overflow ${layout.scroll}`);
    assert.deepEqual(layout.small, [], `${name}/${lang}/${theme}/${width}/${size} undersized targets`);
    const clippedControls = evaluate(`[...document.querySelectorAll('button')].filter(e=>e.getClientRects().length&&!e.closest('[inert]')&&!e.closest('.chart-explore')).filter(e=>{const r=e.getBoundingClientRect();return e.scrollWidth>e.clientWidth+1||r.right>innerWidth+1||r.left< -1}).map(e=>e.textContent)`);
    assert.deepEqual(clippedControls, [], `${name}/${lang}/${theme}/${width}/${size} clipped control text`);
    if (name === 'opponentLast' || name === 'opponentDetails') {
      const reach = evaluate(`(()=>{const last=document.querySelector('[data-action="table-start"]');last.scrollIntoView({block:'center',behavior:'instant'});const r=last.getBoundingClientRect(),nav=document.querySelector('.bottomnav').getBoundingClientRect();return r.top>=0&&r.bottom<=nav.top})()`);
      assert.equal(reach, true, `${name}/${lang}/${theme}/${width}/${size} final action covered by nav`);
    }
    if (lang === 'en') assert.ok(!/[가-힣]/.test(layout.text), `${name} untranslated Korean`);
    layouts++;
    if (width === 375 && size === 16 && ['learn', 'learnReview', 'opponents', 'opponentLast', 'chart', 'intro', 'table', 'review', 'records'].includes(name)) {
      run('screenshot', path.join(output, `${name}-${lang}-${theme}.png`), '--full');
    }
  }
}
pass(`${layouts} layout states: 320/375px, KO/EN, light/dark, 100/200% text; no page overflow, undersized controls or Korean leakage in English`);
run('set', 'viewport', '375', '812');
evaluate("Object.assign(state,{route:'learn',lang:'ko',langOption:'ko',theme:'system',settings:false});document.documentElement.style.fontSize='16px';render();window.scrollTo(0,0)");
const errors = run('errors');
assert.deepEqual(errors.errors, [], 'Browser runtime errors');
fs.writeFileSync(path.join(output, process.env.GT_LAYOUT_ONLY ? 'layout-results.json' : 'browser-results.json'), JSON.stringify({ url, checks, layouts, errors }, null, 2));
console.log(JSON.stringify(errors));
