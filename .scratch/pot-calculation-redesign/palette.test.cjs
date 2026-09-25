const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const html = fs.readFileSync(path.join(__dirname, 'hybrid.html'), 'utf8');
const luminance = hex => hex.slice(1).match(/../g)
  .map(channel => parseInt(channel, 16) / 255)
  .map(value => value <= .04045 ? value / 12.92 : ((value + .055) / 1.055) ** 2.4)
  .reduce((sum, value, index) => sum + value * [.2126, .7152, .0722][index], 0);
const contrast = (a, b) => {
  const values = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (values[0] + .05) / (values[1] + .05);
};
let failures = 0;
for (const name of ['charcoal', 'slate', 'paper']) {
  const block = html.match(new RegExp(`\\[data-palette="${name}"\\]\\s*\\{([^}]+)\\}`))[1];
  const tokens = Object.fromEntries([...block.matchAll(/--([\w-]+):\s*(#[0-9a-f]{6})/g)].map(match => [match[1], match[2]]));
  const pairs = [];
  for (const text of ['text-primary', 'text-muted']) {
    for (const background of ['page-bg', 'panel-bg', 'seat-bg', 'field-bg', 'pot-bg']) pairs.push([text, background, 4.5]);
  }
  pairs.push(['accent', 'seat-bg', 4.5], ['accent', 'page-bg', 4.5], ['accent-on', 'accent', 4.5],
    ['success', 'panel-bg', 4.5], ['error', 'panel-bg', 4.5]);
  for (const background of ['page-bg', 'panel-bg', 'seat-bg', 'table-bg']) {
    pairs.push(['border-strong', background, 3], ['accent', background, 3]);
  }
  pairs.push(['border', 'panel-bg', 3], ['border', 'page-bg', 3]);
  const ratios = pairs.map(([foreground, background, minimum]) => {
    assert.ok(tokens[foreground] && tokens[background], `${name}: missing ${foreground}/${background}`);
    const value = contrast(tokens[foreground], tokens[background]);
    if (value < minimum) {
      failures++;
      console.error(`FAIL ${name} ${foreground}/${background}: ${value.toFixed(2)} < ${minimum}`);
    }
    return { value, minimum };
  });
  console.log(`${name}: ${pairs.length} contrast pairs; minimum text ${Math.min(...ratios.filter(r => r.minimum === 4.5).map(r => r.value)).toFixed(2)}:1; minimum boundary ${Math.min(...ratios.filter(r => r.minimum === 3).map(r => r.value)).toFixed(2)}:1`);
}
assert.equal(failures, 0, 'Palette contrast failures');
