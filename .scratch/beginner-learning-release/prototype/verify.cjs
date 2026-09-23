const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');

const folder = __dirname;
const model = vm.runInNewContext(fs.readFileSync(path.join(folder, 'model.js'), 'utf8') + '\nGTModel');
const appSource = fs.readFileSync(path.join(folder, 'app.js'), 'utf8');
const copySource = appSource.slice(0, appSource.indexOf('const opponents ='));
const translations = vm.runInNewContext(copySource + '\ncopy');

assert.equal(model.hands.length, 169);
assert.equal(new Set(model.hands.map(hand => hand.label)).size, 169);
assert.equal(model.hands.find(hand => hand.label === 'J5o').action, 'fold');
assert.equal(model.questions.length, 5);
for (const question of model.questions) {
  assert.equal(question.board.length, 5);
  assert.equal(new Set([...question.board, ...question.you, ...question.them]).size, 9);
  assert.ok(['you', 'them', 'tie'].includes(question.winner));
  assert.ok(question.why.ko && question.why.en);
}
const finalPaid = model.tableAt(model.tableEvents.length - 1);
assert.deepEqual({ ...finalPaid }, { you: 2, a: 2, b: 2, c: 0 });
for (let step = 0; step < model.tableEvents.length; step++) {
  const current = model.tableAt(step);
  const previous = model.tableAt(step - 1);
  assert.equal(Object.values(current).reduce((a, b) => a + b, 0),
    Object.values(previous).reduce((a, b) => a + b, 0) + model.tableEvents[step].paid);
}
assert.deepEqual(Object.keys(translations.ko).sort(), Object.keys(translations.en).sort());
assert.equal(model.sampleStyle.hands, 120);
assert.equal(model.sampleStyle.entries, 72);
assert.equal(model.sampleStyle.raises, 59);

const archetypeSource = fs.readFileSync(path.join(folder, '../../../GlassTableDrills/Sources/GlassTableDrills/Archetype.swift'), 'utf8');
const vpipSource = archetypeSource.slice(archetypeSource.indexOf('public var vpip'), archetypeSource.indexOf('public var pfr'));
const pfrSource = archetypeSource.slice(archetypeSource.indexOf('public var pfr'), archetypeSource.indexOf('public var name'));
for (const [name, vpip, pfr] of [['nit',12,9], ['tag',20,17], ['lag',27,22], ['station',40,10], ['maniac',55,40]]) {
  assert.match(vpipSource, new RegExp(`case \\.${name}: return ${vpip}(?:;|\\s)`));
  assert.match(pfrSource, new RegExp(`case \\.${name}: return ${pfr}(?:;|\\s)`));
  assert.match(appSource, new RegExp(`id:"${name}"[^\\n]+vpip:${vpip}, pfr:${pfr}`));
}

function contrast(a, b) {
  const luminance = hex => {
    const rgb = hex.match(/[0-9a-f]{2}/gi).map(v => parseInt(v, 16) / 255);
    const linear = rgb.map(v => v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4);
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2];
  };
  const [dark, light] = [luminance(a), luminance(b)].sort((x, y) => x - y);
  return (light + 0.05) / (dark + 0.05);
}
const textPairs = [
  ['light page ink', '#f2eee5', '#222c29'],
  ['light page secondary', '#f2eee5', '#515e58'],
  ['light surface ink', '#e7e1d6', '#222c29'],
  ['light surface secondary', '#e7e1d6', '#515e58'],
  ['light raised ink', '#fffdf7', '#222c29'],
  ['light raised secondary', '#fffdf7', '#515e58'],
  ['light CTA label', '#8a5500', '#ffffff'],
  ['dark page ink', '#17191c', '#f4f0e6'],
  ['dark page secondary', '#17191c', '#bfc3c8'],
  ['dark surface ink', '#1d2024', '#f4f0e6'],
  ['dark surface secondary', '#1d2024', '#bfc3c8'],
  ['dark surface muted', '#1d2024', '#adb2b8'],
  ['dark raised ink', '#24272b', '#f4f0e6'],
  ['dark raised secondary', '#24272b', '#bfc3c8'],
  ['dark CTA label', '#edc17f', '#241b0e'],
  ['table ink', '#153d33', '#f4f0e6'],
  ['table secondary', '#153d33', '#c8d6d0'],
  ['paper card ink', '#efebe0', '#1a2621'],
  ['paper card red', '#efebe0', '#c0392b'],
  ['chart raise ink', '#d28a82', '#222c29'],
  ['chart call ink', '#edc17f', '#222c29'],
  ['chart light fold ink', '#e7e1d6', '#5a6660'],
  ['chart dark fold ink', '#1d2024', '#f4f0e6']
];
const boundaryPairs = [
  ['light button edge', '#fffdf7', '#817a70'],
  ['dark button edge', '#24272b', '#757a81'],
  ['light focus on raised', '#fffdf7', '#8a5500'],
  ['dark focus on raised', '#24272b', '#edc17f'],
  ['table edge', '#153d33', '#80aba0'],
  ['chart raise edge and inset focus', '#d28a82', '#222c29'],
  ['chart call edge and inset focus', '#edc17f', '#222c29'],
  ['chart dark fold edge and inset focus', '#1d2024', '#f4f0e6'],
  ['chart light fold edge and inset focus', '#e7e1d6', '#222c29'],
  ['light behavior fill', '#fffdf7', '#8a5500'],
  ['dark behavior fill', '#24272b', '#edc17f'],
  ['light behavior marker', '#fffdf7', '#222c29'],
  ['dark behavior marker', '#24272b', '#f4f0e6']
];
for (const [label, background, foreground] of textPairs) {
  const ratio = contrast(background, foreground);
  assert.ok(ratio >= 4.5, `${label}: ${ratio.toFixed(2)} below 4.5`);
}
for (const [label, background, foreground] of boundaryPairs) {
  const ratio = contrast(background, foreground);
  assert.ok(ratio >= 3, `${label}: ${ratio.toFixed(2)} below 3`);
}
assert.ok(fs.readFileSync(path.join(__dirname, 'styles.css'), 'utf8').includes('.chart-explore button{border-color:currentColor}'));
console.log(`PASS: fixtures, chip accounting, opponent settings against Archetype.swift, bilingual keys, and ${textPairs.length + boundaryPairs.length} computed color-pair contrasts`);
