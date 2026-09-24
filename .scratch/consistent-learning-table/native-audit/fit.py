"""python3 fit.py cands.json — cands: {"file:line": [[ko, en], ...]} measured at three plausible widths."""
import json, sys
from wrap import fit, clean
rows = {f"{r['file']}:{r['line']}": r for r in json.load(open('match-before.json'))}
for key, cands in json.load(open(sys.argv[1])).items():
    r = rows[key]
    cur = [[clean(r['ko']), clean(r['en'])]]
    print(f"\n## {key} [{r['screen']}]")
    for ko, en, res, lo, hi in fit(r, cur + cands):
        ok = all(not v[0][0] for v in res)
        tag = 'CUR' if [ko, en] == cur[0] else ('OK ' if ok else '-- ')
        issues = ' | '.join(','.join(v[0][0]) or 'ok' for v in res)
        print(f"{tag} W {lo:.0f}-{hi:.0f}  [{issues}]  ko {len(res[1][1])}L {int(res[1][0][1]*100)}% / en {len(res[1][2])}L {int(res[1][0][2]*100)}%")
        print(f"     {' / '.join(res[1][1])}\n     {' / '.join(res[1][2])}")
