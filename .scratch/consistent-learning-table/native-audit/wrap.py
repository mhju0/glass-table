"""Offline wrap simulator calibrated per string from the OCR sweep (match-before.json)."""
import json, re, statistics
from PIL import ImageFont
R = '../../../GlassTable/Resources/'
FONTS = {w: {s: ImageFont.truetype(R + f'Pretendard-{w}.otf', s * 10) for s in range(10, 36)} for w in ['Regular', 'SemiBold', 'Bold']}
SCALE = 1080 / 375

def width(text, w, s):
    return FONTS[w][s].getlength(text) / 10

def calibrate(m):
    best = None
    for w in FONTS:
        for s in FONTS[w]:
            r = [(ow / SCALE) / width(t, w, s) for t, ow in zip(m['text'], m['w']) if len(t.strip()) > 3]
            if r:
                e = abs(statistics.mean(r) - 1)
                if best is None or e < best[0]:
                    best = (e, w, s)
    return best[1], best[2]

def container(m):
    return 375 - 2 * m['x'] / SCALE

def wrap(text, w, s, W):
    words = text.split(' ')
    lines, cur = [], ''
    for word in words:
        trial = word if not cur else cur + ' ' + word
        if width(trial, w, s) <= W or not cur:
            cur = trial
        else:
            lines.append(cur); cur = word
    lines.append(cur)
    return lines

def clean(s):
    return re.sub(r'\\\(.*?\)', '0', s).replace('\\n', ' ').replace("\\'", "'").replace('\\"', '"')

def verdict(ko_lines, en_lines, ko_font, en_font, W):
    fill = lambda ls, f: width(ls[-1], *f) / max(width(l, *f) for l in ls)
    kf, ef = fill(ko_lines, ko_font), fill(en_lines, en_font)
    issues = []
    if len(ko_lines) != len(en_lines): issues.append(f'lines {len(ko_lines)}/{len(en_lines)}')
    if len(ko_lines) > 1 and kf < .5: issues.append(f'ko last {int(kf*100)}%')
    if len(en_lines) > 1 and ef < .5: issues.append(f'en last {int(ef*100)}%')
    if len(ko_lines) == len(en_lines) > 1 and abs(kf - ef) > .25: issues.append(f'end {int(kf*100)}/{int(ef*100)}%')
    return issues, kf, ef

if __name__ == '__main__':
    rows = json.load(open('match.json'))
    ok = tot = 0
    for r in rows:
        for lang in ('ko', 'en'):
            m = r[lang + '_m']
            if m['lines'] < 1: continue
            w, s = calibrate(m)
            sim = wrap(clean(r[lang]), w, s, container(m))
            tot += 1
            if len(sim) == m['lines']: ok += 1
            elif len(sim) > 0 and abs(len(sim) - m['lines']) <= 3:
                print(f"MISS {lang} {r['screen']} obs {m['lines']} sim {len(sim)} W={container(m):.0f} {w}{s}: {' / '.join(sim)[:120]}")
    print(f'{ok}/{tot} line counts reproduced')

def bounds(r):
    """Container width range consistent with both languages' observed wraps."""
    lo, hi = 0, 375 - 2 * min(r['ko_m']['x'], r['en_m']['x']) / SCALE
    for lang in ('ko', 'en'):
        m = r[lang + '_m']; w, s = calibrate(m)
        lo = max(lo, max(width(t, w, s) for t in m['text']))
        for a, b in zip(m['text'], m['text'][1:]):
            hi = min(hi, width(a + ' ' + b.split(' ')[0], w, s))
    return lo, max(hi, lo + 1)

def fit(r, cands):
    kf_, ef_ = calibrate(r['ko_m']), calibrate(r['en_m'])
    lo, hi = bounds(r)
    out = []
    for ko, en in cands:
        res = []
        for W in (lo, (lo + hi) / 2, hi - 0.5):
            kl, el = wrap(ko, *kf_, W), wrap(en, *ef_, W)
            res.append((verdict(kl, el, kf_, ef_, W), kl, el))
        out.append((ko, en, res, lo, hi))
    return out
