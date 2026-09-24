"""Build copy-table.json: every changed KO/EN string pair (before → after) on this branch."""
import json, re, subprocess, sys
sys.path.insert(0, '.')
from guidefit import notes
root = '../../..'
lit = re.compile(r'"((?:[^"\\]|\\.)*)"')
diff = subprocess.run(['git', '-C', root, 'diff', '-U0', '--', 'GlassTable', 'GlassTableDrills',
                       ':!GlassTable/Sources/Screens/LearningGuideView.swift'], capture_output=True, text=True).stdout
rows, f, old, new, line = [], None, [], [], 0
def flush():
    global old, new
    if old or new:
        o = [s for l in old for s in lit.findall(l)]; n = [s for l in new for s in lit.findall(l)]
        for i in range(0, max(len(o), len(n)), 2):
            ob, nb = o[i:i+2], n[i:i+2]
            if ob != nb: rows.append({'where': f'{f}:{line}', 'before': ob, 'after': nb})
    old, new = [], []
for l in diff.splitlines():
    if l.startswith('+++'): flush(); f = l[6:].split('/')[-1]
    elif l.startswith('@@'): flush(); line = int(re.search(r'\+(\d+)', l).group(1))
    elif l.startswith('-') and not l.startswith('---'): old.append(l)
    elif l.startswith('+'): new.append(l)
flush()
before = open(sys.argv[1], encoding='utf-8').read()
cur = open(f'{root}/GlassTable/Sources/Screens/LearningGuideView.swift', encoding='utf-8').read()
for p, (bk, be, ak, ae) in enumerate(zip(notes(before, 'lessons'), notes(before, 'englishLessons'), notes(cur, 'lessons'), notes(cur, 'englishLessons'))):
    for fld in ['title', 'body', 'example', 'question', 'explanation', 'choices']:
        pairs = list(zip(bk[fld], be[fld], ak[fld], ae[fld])) if fld == 'choices' else [(bk.get(fld, ''), be.get(fld, ''), ak.get(fld, ''), ae.get(fld, ''))]
        for i, (a, b, c, d) in enumerate(pairs):
            if (a, b) != (c, d):
                rows.append({'where': f'Learning guide p{p+1} {fld}{" " + str(i+1) if fld == "choices" else ""}', 'before': [a, b], 'after': [c, d]})
json.dump(rows, open('copy-table.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print(len(rows), 'changed pairs')
