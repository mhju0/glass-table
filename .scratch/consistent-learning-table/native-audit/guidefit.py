"""Offline fit of LearningGuideView pages: parses both StudyNote arrays and wraps each field."""
import re, sys
from wrap import width, wrap
SRC = '../../../GlassTable/Sources/Screens/LearningGuideView.swift'
# field: (weight, size, container width) from LearningGuideView layout at 375pt
FIELDS = {'title': ('Bold', 28, 327), 'body': ('Regular', 17, 327), 'example': ('SemiBold', 19, 287),
          'question': ('SemiBold', 17, 327), 'explanation': ('Regular', 16, 327)}
CHOICE = ('SemiBold', 16, 327 - 32 - 22 - 12)

def notes(src, name):
    block = src.split(f'static let {name}: [StudyNote] = [')[1].split('\n    ]')[0]
    out = []
    for chunk in block.split('StudyNote(')[1:]:
        d = {k: v.replace('\\n', '\n') for k, v in re.findall(r'(\w+): "((?:[^"\\]|\\.)*)"', chunk)}
        m = re.search(r'choices: \[(.*?)\]', chunk)
        d['choices'] = re.findall(r'"((?:[^"\\]|\\.)*)"', m.group(1)) if m else []
        out.append(d)
    return out

def lines(text, font):
    out = []
    for para in text.split('\n'):
        out.append(wrap(para, font[0], font[1], font[2]) if para else [''])
    return out

def check(ko, en, font):
    kp, ep = lines(ko, font), lines(en, font)
    issues = []
    if len(kp) != len(ep):
        issues.append(f'paragraphs {len(kp)}/{len(ep)}')
    for i, (a, b) in enumerate(zip(kp, ep)):
        if a == [''] and b == ['']: continue
        fa = width(a[-1], font[0], font[1]) / font[2]; fb = width(b[-1], font[0], font[1]) / font[2]
        tag = f'p{i+1} ' if len(kp) > 1 else ''
        if len(a) != len(b): issues.append(f'{tag}lines {len(a)}/{len(b)}')
        if len(a) > 1 and fa < .5: issues.append(f'{tag}ko last {int(fa*100)}%')
        if len(b) > 1 and fb < .5: issues.append(f'{tag}en last {int(fb*100)}%')
        if len(a) == len(b) > 1 and abs(fa - fb) > .25: issues.append(f'{tag}end {int(fa*100)}/{int(fb*100)}%')
    return issues, kp, ep

if __name__ == '__main__':
    src = open(SRC, encoding='utf-8').read()
    ko, en = notes(src, 'lessons'), notes(src, 'englishLessons')
    total = 0
    for p, (k, e) in enumerate(zip(ko, en)):
        for f, font in FIELDS.items():
            if f not in k and f not in e: continue
            issues, kp, ep = check(k.get(f, ''), e.get(f, ''), font)
            if issues:
                total += 1
                print(f'page {p+1} {f}: {"; ".join(issues)}')
                if '-v' in sys.argv:
                    print('   KO', ' // '.join(' / '.join(x) for x in kp)); print('   EN', ' // '.join(' / '.join(x) for x in ep))
        for i, (a, b) in enumerate(zip(k['choices'], e['choices'])):
            issues, kp, ep = check(a, b, CHOICE)
            if issues:
                total += 1; print(f'page {p+1} choice {i+1}: {"; ".join(issues)}')
    print(total, 'fields with violations')
