"""Native KO/EN line-parity audit over two uisweep capture folders.

Usage: python3 analyse.py <ko-capture-dir> <en-capture-dir> [--json out.json]
Reads OCR line boxes (ocr-lines.swift), groups them into text blocks and reports:
line-count mismatch, last line under 50% of the block's widest line, and Korean
line breaks that fall inside a word of a source string. Heuristic, not exact.
"""
import json, os, re, subprocess, sys, glob

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '../../..'))
HANGUL = re.compile(r'[가-힣]')

def ocr(files):
    out = subprocess.run([os.path.join(HERE, '.build-ocr-lines'), *files], capture_output=True, check=True).stdout
    return {os.path.basename(p['file']): p for p in json.loads(out)}

def blocks(page):
    """Consecutive lines with a shared left edge (or centre), similar height and a small gap."""
    lines = sorted((l for l in page['lines'] if l['conf'] > 0.3 and len(l['text'].strip()) > 0), key=lambda l: (l['y'], l['x']))
    W = page['width']
    groups = []
    for l in lines:
        placed = False
        for g in reversed(groups[-6:]):
            p = g[-1]
            gap = l['y'] - (p['y'] + p['h'])
            same_h = abs(l['h'] - p['h']) < 0.15 * max(l['h'], p['h'])
            left = abs(l['x'] - p['x']) < 0.02 * W
            centre = abs((l['x'] + l['w'] / 2) - (p['x'] + p['w'] / 2)) < 0.015 * W and not left
            if same_h and -0.3 * p['h'] < gap < 0.45 * p['h'] and (left or centre):
                g.append(l); placed = True; break
        if not placed:
            groups.append([l])
    return groups

def align(kb, eb, W, H):
    """Order-preserving alignment of Korean and English blocks (edit distance with a skip cost)."""
    def cost(a, b):
        return abs(a[0]['x'] - b[0]['x']) / W * 8 + abs(a[0]['h'] - b[0]['h']) / a[0]['h'] + abs(a[0]['y'] - b[0]['y']) / H * 2
    SKIP = 0.6
    n, m = len(kb), len(eb)
    D = [[0.0] * (m + 1) for _ in range(n + 1)]
    for i in range(1, n + 1): D[i][0] = i * SKIP
    for j in range(1, m + 1): D[0][j] = j * SKIP
    for i in range(1, n + 1):
        for j in range(1, m + 1):
            D[i][j] = min(D[i-1][j-1] + cost(kb[i-1], eb[j-1]), D[i-1][j] + SKIP, D[i][j-1] + SKIP)
    i, j, out = n, m, []
    while i > 0:
        if j > 0 and abs(D[i][j] - (D[i-1][j-1] + cost(kb[i-1], eb[j-1]))) < 1e-9:
            out.append((kb[i-1], eb[j-1] if cost(kb[i-1], eb[j-1]) < SKIP else None)); i -= 1; j -= 1
        elif abs(D[i][j] - (D[i-1][j] + SKIP)) < 1e-9:
            out.append((kb[i-1], None)); i -= 1
        else:
            j -= 1
    return out[::-1]

def corpus():
    """Every Swift string literal, whitespace-normalised, for in-word break checks."""
    text = []
    for path in glob.glob(f'{ROOT}/GlassTable/Sources/**/*.swift', recursive=True) + glob.glob(f'{ROOT}/GlassTableDrills/Sources/**/*.swift', recursive=True):
        with open(path, encoding='utf-8') as f:
            text += re.findall(r'"((?:[^"\\\n]|\\.)*)"', f.read())
    return '\n'.join(text)

def main():
    ko_dir, en_dir = sys.argv[1], sys.argv[2]
    names = sorted(set(os.listdir(ko_dir)) & set(os.listdir(en_dir)))
    names = [n for n in names if n.endswith('.png')]
    ko = ocr([os.path.join(ko_dir, n) for n in names])
    en = ocr([os.path.join(en_dir, n) for n in names])
    src = corpus()
    report = []
    for n in names:
        kb = [b for b in blocks(ko[n]) if HANGUL.search(' '.join(l['text'] for l in b))]
        eb = [b for b in blocks(en[n]) if not HANGUL.search(' '.join(l['text'] for l in b))]
        H = ko[n]['height']
        pairs = align(kb, eb, ko[n]['width'], H)
        for b, partner in pairs:
            top = b[0]['y']
            text = ' / '.join(l['text'] for l in b)
            issues = []
            widest = max(l['w'] for l in b)
            if len(b) > 1 and b[-1]['w'] < 0.5 * widest:
                issues.append(f'ko last line {round(100 * b[-1]["w"] / widest)}%')
            for a, c in zip(b, b[1:]):
                x, y = a['text'].split()[-1] if a['text'].split() else '', c['text'].split()[0] if c['text'].split() else ''
                if x and y and HANGUL.search(x[-1]) and HANGUL.search(y[0]):
                    joined, spaced = x + y, x + ' ' + y
                    if joined in src and spaced not in src:
                        issues.append(f'ko in-word break "{x}|{y}"')
            en_text = None
            if partner:
                en_text = ' / '.join(l['text'] for l in partner)
                if len(partner) != len(b):
                    issues.append(f'lines ko {len(b)} / en {len(partner)}')
                ew = max(l['w'] for l in partner)
                if len(partner) > 1 and partner[-1]['w'] < 0.5 * ew:
                    issues.append(f'en last line {round(100 * partner[-1]["w"] / ew)}%')
            report.append({'screen': n[:-4], 'y': round(top / H, 3), 'ko': text, 'en': en_text, 'ko_lines': len(b),
                           'en_lines': len(partner) if en_text else None, 'issues': issues})
    flagged = [r for r in report if r['issues']]
    print(f'{len(names)} screens, {len(report)} Korean text blocks, {len(flagged)} flagged')
    for r in flagged:
        print(f"- [{r['screen']} @{r['y']}] {'; '.join(r['issues'])}\n    KO: {r['ko']}\n    EN: {r['en']}")
    # Every Korean wrap point, for manual review of word-level breaking.
    with open(os.path.join(HERE, 'ko-breaks.txt'), 'w') as f:
        for r in report:
            parts = r['ko'].split(' / ')
            for a, c in zip(parts, parts[1:]):
                f.write(f"{r['screen']}\t{a[-12:]} | {c[:12]}\n")
    if '--json' in sys.argv:
        with open(sys.argv[sys.argv.index('--json') + 1], 'w') as f:
            json.dump(report, f, ensure_ascii=False, indent=1)

main()
