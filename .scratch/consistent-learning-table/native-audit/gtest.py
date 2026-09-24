"""Check candidate guide rewrites: python3 gtest.py cands.json  ({"p1 title": [ko, en], "p2 choice1": [...]})"""
import json, sys
from guidefit import FIELDS, CHOICE, check
for key, (ko, en) in json.load(open(sys.argv[1], encoding='utf-8')).items():
    f = key.split()[1]
    font = CHOICE if f.startswith('choice') else FIELDS[f]
    issues, kp, ep = check(ko, en, font)
    print(('--' if issues else 'OK'), key, '; '.join(issues))
    print('   KO', ' // '.join(' / '.join(x) for x in kp)); print('   EN', ' // '.join(' / '.join(x) for x in ep))
