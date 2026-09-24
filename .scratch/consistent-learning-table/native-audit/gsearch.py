"""Try all KO×EN variant pairs per field; print passing pairs. python3 gsearch.py variants.json ({"p4 body": [[ko...],[en...]]})"""
import json, sys
from guidefit import FIELDS, CHOICE, check
for key, (kos, ens) in json.load(open(sys.argv[1], encoding='utf-8')).items():
    f = key.split()[1]; font = CHOICE if f.startswith('choice') else FIELDS[f]
    hits = 0
    for ko in kos:
        for en in ens:
            issues, kp, ep = check(ko, en, font)
            if not issues:
                hits += 1; print('OK', key); print('   KO', ' / '.join(kp[0]) if len(kp)==1 else kp); print('   EN', ' / '.join(ep[0]) if len(ep)==1 else ep)
    if not hits:
        print('NONE', key)
        for ko in kos: print('   ko', check(ko, ens[0], font)[1])
        for en in ens: print('   en', check(kos[0], en, font)[2])
