import csv,hashlib,json,math,pathlib
root=pathlib.Path('/Users/michaelju/Workspace/Projects/glass-table')
base=root/'.scratch/numerical-audit-2026-10-11/math'
rows=[json.loads(line) for line in (base/'independent-probe.jsonl').read_text().splitlines()]
charts=[r for r in rows if r['gate']=='chart'];matrix=[r for r in rows if r['gate']=='chartMapping'];arch=[r for r in rows if r['gate']=='archetype']
assert len(matrix)==169 and len(charts)==8 and len(arch)==42
with (base/'chart-mapping-169x8.csv').open('w') as f:
 w=csv.writer(f);w.writerow(['hand','combos','chen']+[f'{s}_{a}' for s in ['UTG','UTG+1','LJ','HJ','CO','BTN','SB','BB'] for a in ['rfi','defend']])
 for r in matrix:w.writerow([r['hand'],r['comboCount'],r['chen']]+[r['seats'][s][a] for s in ['UTG','UTG+1','LJ','HJ','CO','BTN','SB','BB'] for a in ['rfi','defend']])
with (base/'archetype-counts-6x7.csv').open('w') as f:
 w=csv.DictWriter(f,fieldnames=['style','seat','playCombos','raiseCombos','callCombos','continueCombos','partition','nested']);w.writeheader()
 for r in arch:w.writerow({k:r[k] for k in w.fieldnames})
# Independent textbook combinatorics, versus independent exhaustive5 enumerator.
five=[(math.comb(13,5)-10)*(4**5-4),13*math.comb(4,2)*math.comb(12,3)*4**3,math.comb(13,2)*math.comb(4,2)**2*11*4,13*math.comb(4,3)*math.comb(12,2)*4**2,10*(4**5-4),4*math.comb(13,5)-40,13*math.comb(4,3)*12*math.comb(4,2),13*48,40]
assert five==next(r['counts'] for r in rows if r['gate']=='full5')
# Recount chart membership from 1,326 explicitly dealt unordered card pairs.
lookup={r['hand']:r for r in matrix};cards=[(r,s) for r in '23456789TJQKA' for s in 'cdhs']
independent_charts={r['seat']:{'rfi':0,'3벳':0,'콜':0,'폴드':0} for r in charts}
chars='23456789TJQKA'
for i,a in enumerate(cards):
 for b in cards[i+1:]:
  hi,lo=sorted([a[0],b[0]],key=chars.index,reverse=True)
  h=hi+lo+('' if hi==lo else 's' if a[1]==b[1] else 'o')
  for seat,m in lookup[h]['seats'].items():
   independent_charts[seat]['rfi']+=int(m['rfi']);independent_charts[seat][m['defend']]+=1
for r in charts:
 c=independent_charts[r['seat']]
 assert [c['rfi'],c['3벳'],c['콜'],c['폴드']]==[r['combos'],r['threeBetCombos'],r['callCombos'],r['foldCombos']]
# Quantify local coach's rounded-percent cuts separately from pure whole-class charts.
ranked=sorted(matrix,key=lambda r:(-r['chen'],r['hand'][-1:]!='s' if len(r['hand'])==3 else False))
# Source's tie order: pairs, suited, smallest gap, highest rank.
chars='23456789TJQKA'
def key(r):
 s=r['hand'];hi=chars.index(s[0])+2;lo=chars.index(s[1])+2;pair=len(s)==2;suited=s.endswith('s');gap=0 if pair else hi-lo-1
 return (-r['chen'],not pair,not suited,gap,-hi)
ranked=sorted(matrix,key=key);cum=0;coach={15:[],45:[]}
for r in ranked:
 cum+=r['comboCount'];shown=max(1,math.floor(cum/1326*100+.5))
 for cut in coach:
  if shown<=cut:coach[cut].append(r['hand'])
# JSON contract includes all charts, mappings, all archetype counts, and numerical results.
summary={'audited_head':'07054d0','independent_full5_combinatoric_counts':five,'full7':json.loads((base/'frequency7.json').read_text()),'charts':charts,'independent1326ChartRecount':independent_charts,'mappings':matrix,'archetypes':arch,'checks':[r for r in rows if r['gate'] not in ['chart','chartMapping','archetype']],'coachRoundedCutCombos':{str(k):sum(r['comboCount'] for r in matrix if r['hand'] in v) for k,v in coach.items()}}
(base/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False)+'\n')
files=[p for folder in ['GlassTableEngine/Sources','GlassTableDrills/Sources'] for p in (root/folder).rglob('*.swift')]+[base/'AuditRunner/Package.swift',base/'AuditRunner/Sources/AuditRunner/main.swift',base/'frequency7.cpp',base/'frequency7',base/'AuditRunner/.build/release/AuditRunner']
(base/'provenance-sha256.txt').write_text('\n'.join(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.relative_to(root)}' for p in files)+'\n')
print(json.dumps({'matrix_rows':len(matrix),'archetype_rows':len(arch),'coachRoundedCutCombos':summary['coachRoundedCutCombos'],'five_combinatorics_match':True}))
