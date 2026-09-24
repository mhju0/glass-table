"""Match every language.text("ko", "en") pair in the Swift sources to OCR lines.

Usage: python3 match.py <ko-capture-dir> <en-capture-dir> [--json out.json]
For each pair found on a screen in both languages, reports line counts, the
last line's fill relative to the block's widest line, and rule violations.
"""
import difflib, glob, json, os, re, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '../../..'))
STR = r'"((?:[^"\\\n]|\\.)*)"'
PAIR = re.compile(r'language\.text\(\s*' + STR + r'\s*,\s*' + STR + r'\s*\)')

def norm(s):
    s = re.sub(r'\\\(.*?\)', '\x00', s)            # interpolation -> wildcard marker
    s = s.replace('\\n', ' ').replace("\\'", "'").replace('\\"', '"')
    return re.sub(r'\s+', '', s).replace('’', "'").lower()

def pairs():
    out = []
    for path in sorted(glob.glob(f'{ROOT}/GlassTable/Sources/**/*.swift', recursive=True) + glob.glob(f'{ROOT}/GlassTableDrills/Sources/**/*.swift', recursive=True)):
        src = open(path, encoding='utf-8').read()
        for m in PAIR.finditer(src):
            ko, en = m.group(1), m.group(2)
            if len(norm(ko).replace('\x00', '')) < 4:  # too short to locate reliably
                continue
            out.append({'file': os.path.relpath(path, ROOT), 'line': src.count('\n', 0, m.start()) + 1, 'ko': ko, 'en': en})
    return out

def ocr(files):
    res = subprocess.run([os.path.join(HERE, '.build-ocr-lines'), *files], capture_output=True, check=True).stdout
    return {os.path.basename(p['file']): sorted([l for l in p['lines'] if l['conf'] > 0.3], key=lambda l: (l['y'], l['x'])) for p in json.loads(res)}

def similar(a, b):
    if '\x00' in a:  # interpolated: every literal chunk must appear in order
        parts = [p for p in a.split('\x00') if p]
        pos = 0
        for p in parts:
            best = max(range(len(b) + 1), key=lambda i: difflib.SequenceMatcher(None, p, b[i:i + len(p)]).ratio(), default=0)
            if difflib.SequenceMatcher(None, p, b[best:best + len(p)]).ratio() < 0.8 or best < pos:
                return 0
            pos = best + len(p)
        return 0.9 if abs(len(b) - pos) <= 12 else 0
    return difflib.SequenceMatcher(None, a, b).ratio()

def find(target, lines):
    """Smallest run of consecutive OCR lines (shared left edge) matching target."""
    best = None
    for i, first in enumerate(lines):
        run, text = [first], norm(first['text'])
        for j in range(i, len(lines)):
            if j > i:
                l = lines[j]
                prev = run[-1]
                if l['y'] <= prev['y'] + prev['h'] * 0.5 or abs(l['x'] - first['x']) > 25:
                    continue  # same row or a different column
                if l['y'] - (prev['y'] + prev['h']) > prev['h'] * 0.9:
                    break
                run.append(l); text += norm(l['text'])
            if len(text) > len(target.replace('\x00', '')) * 1.3 + 30:
                break
            s = similar(target, text)
            if s >= 0.86 and (best is None or s > best[0]):
                best = (s, list(run))
    return best[1] if best else None

def measure(run):
    widest = max(l['w'] for l in run)
    return {'lines': len(run), 'last': round(run[-1]['w'] / widest, 2), 'text': [l['text'] for l in run], 'x': run[0]['x'], 'widest': widest, 'w': [l['w'] for l in run], 'h': [l['h'] for l in run]}

def main():
    ko_dir, en_dir = sys.argv[1], sys.argv[2]
    names = sorted(n for n in set(os.listdir(ko_dir)) & set(os.listdir(en_dir)) if n.endswith('.png'))
    ko, en = ocr([f'{ko_dir}/{n}' for n in names]), ocr([f'{en_dir}/{n}' for n in names])
    rows = []
    for p in pairs():
        nk, ne = norm(p['ko']), norm(p['en'])
        for n in names:
            rk = find(nk, ko[n]); 
            if not rk: continue
            re_ = find(ne, en[n])
            if not re_: continue
            mk, me = measure(rk), measure(re_)
            issues = []
            if mk['lines'] != me['lines']: issues.append(f"lines ko {mk['lines']} / en {me['lines']}")
            for lang, m in (('ko', mk), ('en', me)):
                if m['lines'] > 1 and m['last'] < 0.5: issues.append(f"{lang} last {int(m['last'] * 100)}%")
            if mk['lines'] == me['lines'] > 1 and abs(mk['last'] - me['last']) > 0.25: issues.append(f"end width ko {int(mk['last'] * 100)}% / en {int(me['last'] * 100)}%")
            rows.append({**p, 'screen': n[:-4], 'ko_m': mk, 'en_m': me, 'issues': issues})
    # one row per source pair (first screen where it appears), keeping issues from any screen
    by = {}
    for r in rows:
        k = (r['file'], r['line'], r['ko'])
        if k not in by or (r['issues'] and not by[k]['issues']): by[k] = r
    uniq = list(by.values())
    bad = [r for r in uniq if r['issues']]
    print(f"{len(names)} screens, {len(uniq)} source pairs located, {len(bad)} with violations")
    for r in sorted(bad, key=lambda r: (r['file'], r['line'])):
        print(f"- {r['file']}:{r['line']} [{r['screen']}] {'; '.join(r['issues'])}\n    KO: {' / '.join(r['ko_m']['text'])}\n    EN: {' / '.join(r['en_m']['text'])}")
    if '--json' in sys.argv:
        json.dump(uniq, open(sys.argv[sys.argv.index('--json') + 1], 'w'), ensure_ascii=False, indent=1)

main()
