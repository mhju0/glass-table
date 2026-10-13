'use strict';
(() => {
const $ = id => document.getElementById(id);
const query = new URLSearchParams(location.search);
const validSteps = ['welcome','familiarity','tiny','example','feedback','transfer','transfer-feedback','recap','remaining','remaining-feedback','lessons','done','closed'];
const model = {route:['A','B','C'].includes(query.get('route'))?query.get('route'):'B', step:validSteps.includes(query.get('step'))?query.get('step'):'welcome', lang:query.get('lang')==='ko'?'ko':'en', mode:query.get('mode')==='dark'?'dark':'light', accent:query.get('accent')==='teal'?'teal':'amber', height:query.get('height')==='60'?'60':'52', zoom:['1','1.3','1.6','2'].includes(query.get('zoom'))?query.get('zoom'):'1', reduced:query.get('motion')==='reduced'||matchMedia('(prefers-reduced-motion: reduce)').matches, result:['correct','wrong','help'].includes(query.get('state'))?query.get('state'):'correct', familiarity:'', practice:Math.min(2,Math.max(0,Number(query.get('practice'))||0)), history:[]};
const text = (en,ko) => model.lang==='ko'?ko:en;
const pairs = [['A','♠'],['A','♥'],['7','♣'],['4','♦'],['2','♠']];
const high = [['K','♣'],['J','♦'],['8','♠'],['6','♥'],['3','♣']];
const lowPair = [['9','♠'],['9','♥'],['A','♣'],['6','♦'],['2','♣']];
const highPair = [['K','♠'],['K','♦'],['J','♣'],['8','♥'],['3','♠']];
const practiceHands = [
{your:[['7','♠'],['7','♥'],['7','♦'],['K','♣'],['2','♠']],other:[['Q','♠'],['Q','♥'],['A','♣'],['9','♦'],['4','♣']],correct:'your',rule:['Three cards of the same rank beat a pair. This is called three of a kind.','같은 숫자나 문자의 카드 세 장은 한 쌍보다 강해요. 이를 트리플이라고 해요.']},
{your:[['J','♠'],['J','♥'],['J','♣'],['7','♦'],['2','♠']],other:[['4','♣'],['5','♥'],['6','♠'],['7','♣'],['8','♦']],correct:'other',rule:['Five cards in rank order make a straight. A straight beats three of a kind.','숫자 순서가 이어지는 카드 다섯 장은 스트레이트예요. 스트레이트는 트리플보다 강해요.']},
{your:[['A','♥'],['J','♥'],['8','♥'],['5','♥'],['2','♥']],other:[['6','♣'],['7','♠'],['8','♦'],['9','♣'],['10','♠']],correct:'your',rule:['Five cards of the same suit make a flush. A flush beats a straight.','무늬가 같은 카드 다섯 장은 플러시예요. 플러시는 스트레이트보다 강해요.']}
];
const card = ([rank,suit],mark=false) => `<span class="card ${['♥','♦'].includes(suit)?'red':''} ${mark?'mark':''}" aria-label="${rank} ${suit}"><span>${rank}</span><span class="suit">${suit}</span></span>`;
const hand = (label,cards,highlight=false) => `<div class="hand"><div class="hand-label">${label}</div><div class="cards">${cards.map((c,i)=>card(c,highlight&&i<2)).join('')}</div></div>`;
const hands = (your,other,reveal=false) => `<div class="hands ${reveal?'reveal':''}">${hand(text('Your hand','내 카드'),your,reveal)}${hand(text('Other hand','상대 카드'),other,reveal&&other===highPair)}</div>`;
const titleGroups = {
'Try one simple hand': [['Try one','simple hand'],['카드 한 번만','비교해 볼까요']],
'Learn poker, one small step at a time': [['Learn poker,','one small step','at a time'],['한 걸음씩','편하게','포커를 배워요']],
'Which hand wins?': [['Which hand','wins?'],['어느 카드가','이길까요?']],
'Both hands have a pair. Which wins?': [['Both have a pair.','Which hand wins?'],['둘 다 페어예요.','어느 카드가 이길까요?']],
'You explored how pairs win': [['You explored','how pairs win'],['페어가 이기는 기준을','살펴봤어요']],
'Have you seen poker before?': [['Have you seen','poker before?'],['포커를','본 적 있나요?']],
'That’s enough for now': [['That’s enough','for now'],['오늘은 여기까지','해도 괜찮아요']],
'Your hand wins this time': [['Your hand wins','this time'],['이번에는','이쪽 카드가 이겨요']],
'Other hand wins this time': [['Other hand wins','this time'],['이번에는','상대 카드가 이겨요']],
'이번에는 이쪽 카드가 이겨요': [['Your hand wins','this time'],['이번에는','이쪽 카드가 이겨요']],
'이번에는 상대 카드가 이겨요': [['Other hand wins','this time'],['이번에는','상대 카드가 이겨요']]
};
const bodyGroups = {
'We’ll look at a few cards together. There’s no timer, and help is always available.': [['We’ll look at a few cards together.','There’s no timer,','and help is always available.'],['카드 몇 장을 함께 살펴볼게요.','시간 제한은 없고,','언제든 설명을 볼 수 있어요.']],
'The other hand’s pair of kings beats your pair of nines. Here, the pair decides the winner, not the single ace.': [['The other hand’s pair of kings','beats your pair of nines.','Here, the pair decides the winner,','not the single ace.'],['킹 페어가','9 페어보다 강해요.','이때는 페어의 높이로 승자를 정해요.','에이스 한 장으로 정하지 않아요.']]
};
const heading = (en,ko) => `<h2>${(titleGroups[en]?.[model.lang==='ko'?1:0]||[text(en,ko)]).map(s=>`<span class="line-group">${s}</span>`).join(' ')}</h2>`;
const p = (en,ko) => `<p>${(bodyGroups[en]?.[model.lang==='ko'?1:0]||text(en,ko).split(/(?<=\.)\s+/)).map(s=>`<span class="line-group">${s}</span>`).join(' ')}</p>`;
const kicker = (en,ko) => `<p class="kicker">${text(en,ko)}</p>`;
const action = (en,ko,fn,style='') => ({label:text(en,ko),fn,style});
const goto = (step,changes={}) => {model.history.push({step:model.step,result:model.result,practice:model.practice});model.step=step;Object.assign(model,changes);render(true);};
const answer = (choice,correct,next) => {model.result=choice==='help'?'help':choice===correct?'correct':'wrong';goto(next);};
const answerButtons = (correct,next) => [action('Your hand','내 카드',()=>answer('your',correct,next)),action('Other hand','상대 카드',()=>answer('other',correct,next)),action('Show me first','먼저 설명해 주세요',()=>answer('help',correct,next))];
const feedbackTitle = correct => model.result==='help'?text('Let’s look together','함께 살펴볼게요'):model.result==='correct'?text('Yes, that hand wins','맞아요, 그 카드가 이겨요'):text(`${correct} wins this time`,correct==='Your hand'?'이번에는 이쪽 카드가 이겨요':'이번에는 상대 카드가 이겨요');
function render(animate=false){
const phone=$('phone');phone.lang=model.lang;phone.dataset.mode=model.mode;phone.dataset.accent=model.accent;phone.dataset.reduced=model.reduced;phone.dataset.zoom=model.zoom;phone.style.setProperty('--zoom',model.zoom);phone.style.setProperty('--button',model.height+'px');
$('language').value=model.lang;$('mode').value=model.mode;$('accent').value=model.accent;$('height').value=model.height;$('zoom').value=model.zoom;$('motion').checked=model.reduced;
document.querySelectorAll('[data-route]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.route===model.route)));
$('previous').textContent=text('Previous','이전');$('previous').disabled=!model.history.length;$('close').textContent=text('Close','닫기');$('close').disabled=model.step==='closed';$('routeLabel').textContent=text('Opening '+model.route,'시작 흐름 '+model.route);
let body='',buttons=[];
switch(model.step){
case 'welcome':
body=kicker('Welcome to Glass Table','글래스 테이블에 오신 걸 환영해요')+heading(model.route==='B'?'Try one simple hand':'Learn poker, one small step at a time',model.route==='B'?'카드 한 번만 비교해 볼까요':'한 걸음씩 편하게 포커를 배워요')+`<div class="hero-cards" aria-label="${text('Two aces','에이스 두 장')}">${card(pairs[0])}${card(pairs[1])}</div>`+p('We’ll look at a few cards together. There’s no timer, and help is always available.','카드 몇 장을 함께 살펴볼게요. 시간 제한은 없고, 언제든 설명을 볼 수 있어요.');
buttons=[action(model.route==='B'?'Try the example':'Choose a comfortable start',model.route==='B'?'예시 살펴보기':'편한 시작 고르기',()=>goto(model.route==='A'?'familiarity':model.route==='C'?'tiny':'example'),'primary')];break;
case 'familiarity':
body=kicker('Optional starting preference','원하면 고르는 시작점')+heading('A comfortable start','편한 시작을 골라요')+p('To choose a comfortable start, how familiar is poker? This only helps suggest a starting point. It is not a test.','편하게 시작할 수 있도록 알려 주세요. 포커가 얼마나 익숙한가요? 시작점을 추천하기 위한 질문이에요. 시험은 아니에요.');
buttons=[...['New to poker','Know a little','Played before'].map((s,i)=>action(s,['처음이에요','조금 알아요','해 본 적 있어요'][i],()=>{model.familiarity=s;goto(i===2?'lessons':'example');})),action('Start with the basics','기초부터 시작할게요',()=>goto('example'),'quiet')];break;
case 'tiny':
body=heading('Have you seen poker before?','포커를 본 적 있나요?')+p('Any answer is fine. We’ll show the same simple example next.','어떤 답이든 괜찮아요. 다음에는 같은 간단한 예시를 볼 거예요.');
buttons=[...['Yes','No','Not sure'].map((s,i)=>action(s,['네','아니요','잘 모르겠어요'][i],()=>{model.familiarity=s;goto('example');})),action('I’ve played. Choose a lesson','해 본 적 있어요. 배울 내용 고르기',()=>goto('lessons'),'quiet')];break;
case 'example':
body=kicker('Example 1 · Find a pair','예시 1 · 한 쌍 찾기')+heading('Which hand wins?','어느 카드가 이길까요?')+p('Two matching numbers or letters make a pair. A pair beats a hand with no pair.','숫자나 문자가 같은 카드 두 장을 페어라고 해요. 페어는 한 쌍도 없는 카드보다 강해요.')+hands(pairs,high);buttons=answerButtons('your','feedback');break;
case 'feedback':
body=kicker('Example 1 · Explanation','예시 1 · 설명')+heading(feedbackTitle('Your hand'),feedbackTitle('Your hand'))+hands(pairs,high,true)+p('Your two aces make a pair. The other hand has no pair; its highest card is a king. The pair wins.','에이스 두 장이 페어를 만들어요. 상대 카드에는 한 쌍이 없고, 가장 높은 카드는 킹이에요. 에이스 페어가 이겨요.');buttons=[action('Try a different comparison','다른 카드 비교하기',()=>goto('transfer'),'primary')];break;
case 'transfer':
body=kicker('Example 2 · Compare two pairs','예시 2 · 두 페어 비교하기')+heading('Both hands have a pair. Which wins?','둘 다 페어예요. 어느 카드가 이길까요?')+p('When both hands have one pair, compare the pair’s rank. Kings rank above nines.','둘 다 한 쌍이면 그 쌍의 숫자나 문자를 비교해요. 킹은 9보다 높아요.')+hands(lowPair,highPair);buttons=answerButtons('other','transfer-feedback');break;
case 'transfer-feedback':
body=kicker('Example 2 · Explanation','예시 2 · 설명')+heading(feedbackTitle('Other hand'),feedbackTitle('Other hand'))+hands(lowPair,highPair,true)+p('The other hand’s pair of kings beats your pair of nines. Here, the pair decides the winner, not the single ace.','킹 페어가 9 페어보다 강해요. 이때는 에이스 한 장이 아니라 페어의 높이로 승자를 정해요.');buttons=[action('See what we explored','살펴본 내용 보기',()=>goto('recap'),'primary')];break;
case 'recap':
body=kicker('2 examples completed','예시 2개를 살펴봤어요')+heading('You explored how pairs win','페어가 이기는 기준을 살펴봤어요')+`<div class="summary">${p('A pair beats a hand with no pair.','페어는 한 쌍이 없는 카드보다 강해요.')}${p('Between two pairs, the higher pair wins.','둘 다 페어이면 더 높은 페어가 이겨요.')}</div>`+p('You can finish here or continue with three more comparisons.','여기서 마쳐도 괜찮아요. 카드 비교 세 가지를 더 살펴볼 수도 있어요.');
buttons=[action('Continue · 3 more comparisons','계속하기 · 카드 비교 3가지',()=>{model.practice=0;goto('remaining');},'primary'),action('Finish for now','오늘은 여기까지',()=>goto('done')),action('Choose a starting preference','시작점 직접 고르기',()=>goto('familiarity'),'quiet')];break;
case 'remaining':{
const item=practiceHands[model.practice];body=kicker(`Example ${model.practice+3} of 5`,`예시 ${model.practice+3} / 5`)+heading('Which hand wins?','어느 카드가 이길까요?')+p(...item.rule)+hands(item.your,item.other);buttons=answerButtons(item.correct,'remaining-feedback');break;}
case 'remaining-feedback':{
const item=practiceHands[model.practice];body=kicker('Explanation','설명')+heading(feedbackTitle(item.correct==='your'?'Your hand':'Other hand'),feedbackTitle(item.correct==='your'?'Your hand':'Other hand'))+hands(item.your,item.other)+p(...item.rule);buttons=[action(model.practice===2?'Finish the examples':'Next comparison',model.practice===2?'예시 마치기':'다음 카드 비교',()=>{if(model.practice===2)goto('done');else goto('remaining',{practice:model.practice+1});},'primary')];break;}
case 'lessons':
body=heading('Choose where to begin','시작할 내용 고르기')+p('The basics are always open. This preview lets you explore card comparisons.','기초는 언제든 살펴볼 수 있어요. 이 미리보기에서는 카드 비교를 체험할 수 있어요.');buttons=[action('Card basics · Try an example','카드 기초 · 예시 살펴보기',()=>goto('example'),'primary'),action('Finish for now','오늘은 여기까지',()=>goto('done'))];break;
case 'done':
body=kicker('A comfortable stopping point','편하게 마치는 자리')+heading('That’s enough for now','오늘은 여기까지 해도 괜찮아요')+p('You’ve explored a few card comparisons. Take your time with the next step.','카드를 비교하는 예시를 살펴봤어요. 다음 단계도 편할 때 시작하면 돼요.')+`<div class="rule">${text('End of this HTML exploration. No native progress or completion was recorded.','HTML 체험은 여기까지예요. 앱의 학습 진행도나 완료 기록에는 반영되지 않아요.')}</div>`;buttons=[action('Try this route again','이 흐름 다시 보기',reset,'primary'),action('Close preview','미리보기 닫기',()=>goto('closed'))];break;
case 'closed':body=kicker('Preview closed','미리보기를 닫았어요')+heading('You’re in control','편하게 선택하세요')+p('Restart whenever you want to compare the opening routes.','시작 흐름을 비교하고 싶을 때 다시 열어 보세요.');buttons=[action('Restart preview','미리보기 다시 열기',reset,'primary')];break;
}
$('screen').innerHTML=body;$('screen').className='screen'+(animate?' fade':'');$('screen').scrollTop=0;$('flow').scrollTop=0;
$('dock').replaceChildren(...buttons.map(item=>{const b=document.createElement('button');b.textContent=item.label;b.className=item.style;b.addEventListener('click',item.fn);return b;}));$('dock').scrollTop=0;
$('scene').textContent=`route=${model.route} · step=${model.step} · state=${model.result} · lang=${model.lang} · mode=${model.mode}`;
const params=new URLSearchParams({route:model.route,step:model.step,lang:model.lang,mode:model.mode,state:model.result,accent:model.accent,height:model.height,zoom:model.zoom,motion:model.reduced?'reduced':'normal',practice:String(model.practice)});history.replaceState(null,'',`${location.pathname}?${params}`);
if(animate)$('screen').focus({preventScroll:true});
}
function reset(){model.step='welcome';model.result='correct';model.history=[];model.practice=0;model.familiarity='';render(true);}
$('previous').addEventListener('click',()=>{const previous=model.history.pop();if(previous){Object.assign(model,previous);render(true);}});
$('close').addEventListener('click',()=>goto('closed'));
$('reset').addEventListener('click',reset);
document.querySelectorAll('[data-route]').forEach(b=>b.addEventListener('click',()=>{model.route=b.dataset.route;reset();}));
for(const [id,key] of [['language','lang'],['mode','mode'],['accent','accent'],['height','height'],['zoom','zoom']])$(id).addEventListener('change',e=>{model[key]=e.target.value;render();});
$('motion').addEventListener('change',e=>{model.reduced=e.target.checked;render();});
document.addEventListener('keydown',e=>{if(e.key==='Escape'&&model.step!=='closed')goto('closed');});
render();
})();
