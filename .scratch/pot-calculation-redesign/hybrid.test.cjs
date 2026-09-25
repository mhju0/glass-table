const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const html = fs.readFileSync(path.join(__dirname, 'hybrid.html'), 'utf8');
const scripts = [...html.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/g)].map(match => match[1]);
assert.ok(scripts.length, 'Inline JavaScript exists');
scripts.forEach((source, index) => new vm.Script(source, { filename: `hybrid-script-${index}` }));
assert.ok(!html.includes('\u2014'), 'UI copy contains no em dash');
assert.ok(!/https?:\/\/[^\s"']+\.(?:js|css)/.test(html), 'No remote script or stylesheet dependency');

const modelSource = html.match(/\/\/ MODEL START([\s\S]*?)\/\/ MODEL END/)[1];
const model = vm.runInNewContext(`${modelSource}\n({buildScenario, snapshot, addedBy, actionCaption})`);
for (const count of [3, 4]) {
  const scenario = model.buildScenario(count);
  const last = scenario.actions.length - 1;
  const final = model.snapshot(scenario, last);
  assert.equal(scenario.roles.length, count);
  assert.equal(new Set(scenario.roles).size, count);
  assert.equal(final.total, 37 + 6 * (count - 3));
  assert.equal(scenario.expected, final.total);
  assert.equal(scenario.choices.length, 3);
  assert.equal(new Set(scenario.choices).size, 3);
  assert.equal(scenario.choices.filter(value => value === final.total).length, 1);
  assert.ok(scenario.choices.every(value => Number.isInteger(value) && value > 0));
  assert.equal(final.contributions.SB, 1);
  assert.equal(final.contributions.BB, 18);
  assert.equal(final.contributions[scenario.opener], 18);
  scenario.callers.forEach(role => assert.equal(final.contributions[role], 6));
  assert.equal(scenario.actions[last].type, 'callTo', 'Stop is not an extra frame leaking the answer');
  assert.equal(scenario.actions[last].actor, scenario.opener);

  const folded = new Set();
  let nextActor = scenario.opener;
  let target = 2;
  let raiseSize = 2;
  let previousTotal = 0;
  scenario.actions.forEach((action, frame) => {
    const view = model.snapshot(scenario, frame);
    assert.equal(Object.keys(view.contributions).length, count);
    assert.ok(view.total >= previousTotal);
    assert.equal(model.addedBy(scenario, frame), view.total - previousTotal);
    assert.ok(model.actionCaption(scenario, frame).length > 0);
    assert.ok(model.actionCaption(scenario, frame).length <= 40, 'Seat caption stays concise');
    if (action.type !== 'post') {
      assert.equal(action.actor, nextActor, 'Clockwise action order cannot skip a live player');
      if (action.type === 'fold') {
        folded.add(action.actor);
        assert.equal(view.total, previousTotal);
        assert.equal(view.contributions.SB, 1);
      } else if (action.type === 'raiseTo') {
        assert.ok(action.to - target >= raiseSize, 'Full raise size is legal');
        raiseSize = action.to - target;
        target = action.to;
      } else {
        assert.equal(action.type, 'callTo');
        assert.equal(action.to, target);
      }
      let nextIndex = scenario.roles.indexOf(action.actor);
      do { nextIndex = (nextIndex + 1) % count; } while (folded.has(scenario.roles[nextIndex]));
      nextActor = scenario.roles[nextIndex];
    }
    previousTotal = view.total;
  });
  console.log(`PASS: ${count} players, ${scenario.actions.length} actions, ${final.total} chips; order, prefixes, fold, raises and choices`);
}
console.log(`PASS: ${scripts.length} inline scripts parse; copy and dependency checks`);
for (const count of [2, 5, 6]) {
  assert.throws(() => model.buildScenario(count), 'Only approved three/four-player fixtures are supported');
}
console.log('PASS: unsupported player counts rejected');

const uiSource = scripts[1].split("stage.addEventListener('click'")[0];
const rendered = vm.runInNewContext(`${modelSource}\n${uiSource}\n({ui, questionMarkup, reviewMarkup})`, {
  URLSearchParams,
  location: { search: '' },
  document: { getElementById: () => ({}) },
  window: { location: { search: '' }, matchMedia: () => ({ matches: false, addEventListener() {} }) }
});
for (const count of [3, 4]) {
  const scenario = model.buildScenario(count);
  Object.assign(rendered.ui, { count, screen: 'question', selected: null, submitted: false });
  for (let frame = 0; frame < scenario.actions.length; frame++) {
    rendered.ui.frame = frame;
    const markup = rendered.questionMarkup();
    assert.equal((markup.match(/class="seat"/g) || []).length, count);
    assert.equal((markup.match(/data-active="true"/g) || []).length, 1);
    assert.ok(!/class="(?:context|order-line|timeline-meta|action-caption|reviewing)"/.test(markup));
    assert.ok(markup.includes('지금 팟은 몇 칩일까요?'));
    assert.ok(markup.includes('<strong>?</strong>'), 'Aggregate answer stays hidden');
    assert.equal((markup.match(/data-choice=/g) || []).length, frame === scenario.actions.length - 1 ? 3 : 0);
  }
}
assert.ok(!/data-review-count="[56]"/.test(rendered.reviewMarkup()));
console.log('PASS: every rendered replay frame has one actor, concise layout, hidden pot and gated choices');

const motionCalls = [];
let systemReduced = false;
const box = { getBoundingClientRect: () => ({ left: 10, top: 10, width: 80, height: 60 }) };
const motionContext = vm.runInNewContext(`${modelSource}\n${uiSource}\n({ui, animateChipToPot, cancelMotions})`, {
  URLSearchParams,
  location: { search: '' },
  window: { location: { search: '' } },
  matchMedia: () => ({ matches: systemReduced }),
  document: {
    getElementById: () => ({ querySelector: () => box, querySelectorAll: () => [] }),
    body: { append() {} },
    createElement: () => ({
      style: {}, setAttribute() {}, remove() {},
      animate(frames, options) {
        motionCalls.push({ frames, options });
        return { cancel() {}, finished: new Promise(() => {}) };
      }
    })
  }
});
motionContext.animateChipToPot();
assert.equal(motionCalls.length, 1);
assert.equal(motionCalls[0].options.duration, 220);
assert.equal(motionCalls[0].options.easing, 'cubic-bezier(0.77,0,0.175,1)');
assert.ok(motionCalls[0].frames.every(frame => Object.keys(frame).every(key => ['transform', 'opacity'].includes(key))));
motionContext.ui.reduced = true;
motionContext.animateChipToPot();
motionContext.ui.reduced = false;
systemReduced = true;
motionContext.animateChipToPot();
assert.equal(motionCalls.length, 1, 'Both reduced-motion sources suppress movement');
motionContext.cancelMotions();
console.log('PASS: motion uses transform/opacity at 220ms and respects both reduced-motion sources (stubbed DOM)');
