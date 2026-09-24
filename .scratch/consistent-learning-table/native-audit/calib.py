import json, statistics
from PIL import ImageFont
R='../../../GlassTable/Resources/'
FONTS={w:{s:ImageFont.truetype(R+f'Pretendard-{w}.otf',s*10) for s in range(11,31)} for w in ['Regular','SemiBold','Bold']}
def width(text,w,s): return FONTS[w][s].getlength(text)/10
SCALE=1080/375
rows=json.load(open('match-before.json'))
for r in rows[:30]:
    for lang in ('ko','en'):
        m=r[lang+'_m']
        res=[]
        for w in FONTS:
            for s in range(11,31):
                ratios=[ (ow/SCALE)/width(t,w,s) for t,ow in zip(m['text'],m['w']) if len(t)>6]
                if ratios: res.append((abs(statistics.mean(ratios)-1),w,s,round(statistics.mean(ratios),3)))
        res.sort()
        print(lang, r['screen'], res[:2], m['text'][0][:30], round(m['h'][0]/SCALE,1))
