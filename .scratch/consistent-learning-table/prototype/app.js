const app = document.querySelector('#app');
// Refined copy is fitted so Korean and English wrap to the same line count at 375pt,
// with no short last lines. Keyed by the original Korean; Current keeps the original.
const REVISED = new Map([
  ['각 활동을 전체 화면으로 열어 보세요. 처음에는 짧은 예시를 볼 수 있어요.',
    ['각 활동은 전체 화면으로 열려요. 처음 열 때는 짧은 예시로 문제 푸는 방법을 먼저 보여 드려요.',
     'Each activity opens full screen. On first use, a short worked example shows how to solve it.']],
  ['가운데 모인 칩을 알아야 다음 선택을 계산할 수 있어요. SB(스몰 블라인드)와 BB(빅 블라인드)는 시작할 때 칩을 내는 자리예요.',
    ['팟은 가운데 모인 칩이에요. 팟을 알아야 다음 선택을 계산할 수 있어요. SB(스몰 블라인드)와 BB(빅 블라인드)는 핸드를 시작할 때 칩을 먼저 내는 두 자리예요.',
     'The pot is the chips in the middle. Knowing it helps you plan your next choice. SB and BB mean small and big blind, the seats that post chips first.']],
  ['레이즈 18은 지금 18칩을 더 낸다는 뜻이 아니에요. 이미 낸 칩을 빼고 더해요.',
    ['레이즈 18은 지금 18칩을 더 낸다는 뜻이 아니에요. 이미 낸 칩을 빼고, 총 18칩이 되도록 모자란 만큼만 더 내요.',
     'A raise to 18 does not add 18 chips now. Subtract what you already paid and add only the difference.']],
  ['예시: SB가 1칩, BB가 2칩, A가 4칩, B가 4칩을 내면 11칩이에요.',
    ['예시: SB가 1칩, BB가 2칩을 내고 A와 B가 4칩씩 내면 팟은 모두 11칩이 돼요.',
     'Example: SB pays 1 and BB pays 2, then A and B pay 4 each. The pot is 11.']],
  ['자리마다 먼저 또는 나중에 행동해요. 늦게 행동하면 앞사람의 선택을 볼 수 있어요.',
    ['자리에 따라 행동하는 순서가 달라요. 늦게 행동하면 앞사람의 선택을 먼저 보고 정할 수 있어요.',
     'Your seat sets the order in which you act. Acting later lets you see earlier choices first.']],
  ['SB는 작은 블라인드, BB는 큰 블라인드예요. 시작할 때 내는 칩을 뜻해요.',
    ['SB는 작은 블라인드, BB는 큰 블라인드예요. 핸드를 시작하기 전에 두 자리가 정해진 칩을 먼저 내요.',
     'SB and BB are the small and big blinds. These two seats pay set chips before the hand starts.']],
  ['예시: 공용 카드 전에는 앞자리부터, 공용 카드 뒤에는 SB부터 행동해요. 버튼(D)은 공용 카드 뒤 마지막이에요.',
    ['예시: 공용 카드 전에는 BB가 마지막이에요. 공용 카드 뒤에는 SB부터 시계 방향으로 행동해요.',
     'Example: before shared cards, BB acts last. After them, play goes clockwise from SB.']],
  ['공용 카드 전: 앞자리 → 버튼(D) → SB → BB. 공용 카드 뒤: SB부터 시계 방향이에요.',
    ['공용 카드 전: 앞자리 → 버튼(D) → SB → BB<br>공용 카드 뒤: SB부터 시계 방향',
     'Before: early seat → button (D) → SB → BB<br>After: clockwise from SB']],
  ['같은 두 숫자라도 실제 카드 두 장의 종류는 여러 개예요.',
    ['같은 두 숫자라도 실제 카드 두 장의 종류는 여러 개예요.',
     'One hand label covers several real two-card hands.']],
  ['s는 같은 무늬, o는 서로 다른 무늬예요. AKo는 에이스와 킹의 무늬가 달라요.',
    ['s는 같은 무늬, o는 서로 다른 무늬를 뜻해요. AKo는 에이스와 킹의 무늬가 서로 다른 핸드예요.',
     's means same suit and o means different suits. AKo is an ace and a king with different suits.']],
  ['상대 카드의 뒷면, 접은 자리, 가운데 칩을 보며 한 행동씩 따라가요.',
    ['뒷면으로 놓인 상대 카드, 폴드한 자리, 가운데 칩을 보면서 테이블의 행동을 하나씩 따라가요.',
     'Follow one action at a time, watching face-down cards, folded seats and the center chips.']],
  ['이 손은 화면 검토용 대본이에요. 실제 게임 판단이나 점수가 아니에요.',
    ['이 핸드는 화면 검토를 위해 정한 대본이에요. 실제 게임 판단이나 점수와는 관계없어요.',
     'This hand is a fixed script for screen review. It is not a real game decision or a grade.']],
  ['예시: 상대 2가 폴드하면 그 카드도 뒷면으로 남아요.',
    ['예시: 상대 2가 폴드해도 카드는 뒷면이에요.',
     'Example: Bot 2 folds; cards stay hidden.']],
  ['지금 팟은 몇 칩일까요?',
    ['지금 팟은 몇 칩일까요?',
     'How big is the pot now?']],
  ['다음 행동',
    ['다음 행동',
     'Next']],
  ['마지막 행동까지 본 뒤 답을 골라요. 다시 보기는 도움으로 세지 않아요.',
    ['마지막 행동까지 본 뒤 답해요. 다시 보기는 도움으로 세지 않아요.',
     'Answer after the last action. Replays don’t count as help.']],
  ['예시 대본. 도움 완료는 독립 정답으로 세지 않아요.',
    ['예시 대본이에요. 도움을 받은 답은 혼자 맞힌 정답으로 세지 않아요.',
     'Scripted example. Answers with help don’t count as unaided.']],
  ['도움을 보고 답하는 중이에요. 자리별로 낸 칩: SB 1 + BB 18 + A 18 + B 6 = 43. 이 답은 독립 정답으로 세지 않아요.',
    ['도움을 보고 답하는 중이에요. 자리별로 낸 칩을 더하면 SB 1 + BB 18 + A 18 + B 6 = 43이에요. 도움을 받아 맞힌 답은 혼자 맞힌 정답으로 세지 않아요.',
     'Answering with help. Paid by seat: SB 1 + BB 18 + A 18 + B 6 = 43. Correct answers made with help are not counted as unaided answers.']],
  ['BB는 이미 낸 2칩에 16칩을 더해 총 18칩, A는 6칩에 12칩을 더해 총 18칩을 냈어요.',
    ['BB는 이미 낸 2칩에 16칩을 더해 총 18칩, A는 먼저 낸 6칩에 12칩을 더해 총 18칩을 냈어요.',
     'BB adds 16 to its posted 2 for 18 in total. A adds 12 to its earlier 6, also for 18 in total.']],
  ['A의 마지막 콜 직전은 31칩. B는 아직 다시 행동하지 않았어요.',
    ['A가 마지막으로 12칩을 콜하기 직전의 팟은 31칩이었어요. B는 아직 다시 행동하지 않았어요.',
     'Before A’s final call of 12, the pot held 31 chips. B has not had another turn to act yet.']],
  ['공용 카드 뒤 누가 마지막으로 행동할까요?',
    ['공용 카드가 나온 뒤에는 누가 가장 마지막에 행동할까요?',
     'After the shared cards appear, who is the last to act?']],
  ['D는 딜러 버튼이에요. SB와 BB는 처음에 칩을 내는 자리예요.',
    ['D는 딜러 버튼이에요. SB와 BB는 핸드를 시작하기 전에 정해진 칩을 먼저 내는 두 자리예요.',
     'D marks the dealer button. SB and BB are the seats that post chips before the hand starts.']],
  ['이것은 4자리 소개 예시예요. 실제 자리 학습은 더 많은 자리도 다뤄요.',
    ['이것은 4자리 소개 예시예요. 실제 자리 학습은 더 많은 자리도 다뤄요.',
     'A four-seat introduction. The full course covers more seats.']],
  ['이 예시에서는 버튼(D)이 늦게 행동해 앞사람의 선택을 볼 수 있어요.',
    ['버튼(D)은 공용 카드 뒤 가장 늦게 행동해요. 그래서 다른 사람의 선택을 모두 보고 결정할 수 있어요.',
     'After the shared cards, the button (D) acts last. It can see everyone else’s choice before deciding.']],
  ['AKo는 실제 카드 두 장으로 몇 가지일까요?',
    ['AKo를 만드는 실제 카드 두 장의 조합은 모두 몇 가지일까요?',
     'How many different two-card hands make up AKo?']],
  ['o는 서로 다른 무늬예요. 에이스 4장과 킹 4장 중 하나씩 골라요.',
    ['o는 두 카드의 무늬가 서로 다르다는 뜻이에요. 에이스 4장과 킹 4장 중에서 각각 한 장씩 골라요.',
     'o means the two cards have different suits. Pick one of four aces and one of four kings.']],
  ['4 × 4 = 16가지에서 같은 무늬 4가지를 빼면 12가지예요.',
    ['4 × 4 = 16가지에서 같은 무늬 4가지를 빼면 12가지예요.',
     '4 × 4 = 16, minus 4 same-suit pairs, leaves 12.']],
  ['상대 카드 앞면은 보이지 않아요. 접은 자리의 카드는 계속 뒷면이에요. 정해진 순서로 진행하는 화면 예시예요. 실제 게임이나 성적에는 반영되지 않아요.',
    ['상대 카드의 앞면은 폴드한 뒤에도 보이지 않아요. 이 화면은 정해진 순서대로 진행하는 예시라서 실제 게임이나 내 기록에는 반영되지 않아요.',
     'Opponent card faces stay hidden, even after a fold. This screen follows a fixed script, so it does not affect a real game or your record.']],
  ['한 번에 하나씩 배워요',
    ['한 번에 하나씩 결정하며 배워요',
     'Learn one decision at a time']],
  ['핸드 조합',
    ['핸드 조합',
     'Hand combos']],
  ['한 행동씩 따라가요',
    ['행동을 하나씩 따라가 봐요',
     'Follow one action at a time']],
]);
const t = (ko, en) => {
  const revised = state.design === 'refined' && REVISED.get(ko);
  if (revised) [ko, en] = revised;
  return state.lang === 'ko' ? ko : en;
};
const steps = [
  { actor:'SB', add:1, ko:'스몰 블라인드 1칩', en:'Small blind posts 1' },
  { actor:'BB', add:2, ko:'빅 블라인드 2칩', en:'Big blind posts 2' },
  { actor:'A', add:6, ko:'총 6칩으로 레이즈, 지금 6칩 추가', en:'Raises to 6, adds 6 now' },
  { actor:'B', add:6, ko:'6칩 콜', en:'Calls 6' },
  { actor:'SB', add:0, fold:true, ko:'폴드, 앞서 낸 1칩은 팟에 남아요', en:'Folds; posted 1 stays in pot' },
  { actor:'BB', add:16, ko:'총 18칩으로 레이즈', en:'Raises to 18 total' },
  { actor:'A', add:12, ko:'18칩에 맞춰 콜', en:'Calls to match 18' }
];
const playSteps = [
  {actor:'you',ko:'내가 2칩 블라인드를 내요',en:'You post the 2-chip blind',folded:[]},
  {actor:'one',ko:'상대 1이 2칩 콜',en:'Bot 1 calls 2',folded:[]},
  {actor:'two',ko:'상대 2가 폴드',en:'Bot 2 folds',folded:['two']},
  {actor:'three',ko:'상대 3이 콜',en:'Bot 3 calls',folded:['two']},
  {actor:'you',ko:'공용 카드 세 장이 펼쳐져요',en:'Three shared cards appear',folded:['two']},
  {actor:'one',ko:'상대 1이 체크',en:'Bot 1 checks',folded:['two']}
];
const safeStorage = {
  get(key){try{return localStorage.getItem(key)}catch{return null}},
  set(key,value){try{localStorage.setItem(key,value)}catch{}}
};
const state = {
  lang:'ko',theme:'light',size:'normal',design:new URLSearchParams(location.search).get('design')==='refined'?'refined':'current',mode:'pot',stage:'intro',step:0,
  answered:null,assisted:false,showSteps:false,exampleExpanded:false,introFromPractice:false,sessions:{},visited:JSON.parse(safeStorage.get('gt-consistent-visited')||'{}')
};
function card(rank,suit,extra=''){
  if(rank==='back') return `<span class="card back ${extra}" role="img" aria-label="${t('뒷면 카드','Face-down card')}"></span>`;
  const red=suit==='♥'||suit==='♦';
  return `<span class="card ${red?'red':''} ${extra}" role="img" aria-label="${rank} ${suit}"><span class="rank" aria-hidden="true">${rank}</span><span class="suit" aria-hidden="true">${suit}</span></span>`;
}
// Refined: one fixed-height ivory stack, so its size never hints at the pot total.
const chipTop=c=>{const edge=x=>(c+5*Math.sqrt(1-((x-16)/14)**2)).toFixed(1);return `<path d="M2 ${c}v4a14 5 0 0 0 28 0v-4z" fill="#d6ccb4"/><path d="M7 ${edge(7)}v4M16 ${c+5}v4M25 ${edge(25)}v4" stroke="#2f3b40" stroke-width="2.4"/><ellipse cx="16" cy="${c}" rx="14" ry="5" fill="#f2ecdd"/>`};
const chipSvg=`<svg class="chip-stack" viewBox="0 0 32 27" width="32" height="27"><ellipse cx="16" cy="23.6" rx="15" ry="3" fill="#000" opacity=".3"/>${[15,10.5,6].map(chipTop).join('')}<ellipse cx="16" cy="6" rx="8.5" ry="3" fill="none" stroke="#2f3b40" stroke-width=".9" stroke-dasharray="2.2 1.8"/></svg>`;
function chipStack(label,known){
  const chips=state.design==='refined'?chipSvg:'<span class="chip"></span><span class="chip"></span><span class="chip"></span>';
  if(state.design==='refined'&&!known)label=t('팟','Pot');
  return `<div class="pot-center" role="group" aria-label="${known ? label : t('가운데 칩. 팟 총액은 아직 숨겨져 있어요','Center chips. Pot total is hidden for now')}"><div class="chips" aria-hidden="true">${chips}</div><span class="pot-label ${known?'known-total':''}" ${known?'':'aria-hidden="true"'}>${label}</span></div>`;
}
function seat({name,pos,active=false,folded=false,caption='',cards='',dealer=false}){
  return `<div class="seat ${pos} ${active?'active':''} ${folded?'folded':''}" role="group" aria-label="${name}${dealer?t(', 딜러 버튼',', dealer button'):''}${folded?t(', 폴드',', folded'):''}${caption?', '+caption:''}"><div class="seat-detail">${state.design==='refined'?`<span class="name-row"><strong>${name}</strong>${dealer?'<span class="dealer" aria-hidden="true">D</span>':''}</span><span class="caption ${folded?'status':''}">${caption}</span>`:`<strong>${name}</strong>${dealer?'<span class="dealer" aria-hidden="true">D</span>':''}<span class="caption">${caption}</span>`}</div>${cards?`<span class="mini-cards">${cards}</span>`:''}</div>`;
}
function table(mode,example=false){
  let seats='',center='',board='';
  if(mode==='pot'){
    const index=example?3:state.step;
    const active=steps[index].actor;
    const folded=index>=4;
    const names={SB:t('SB','SB'),BB:t('BB','BB'),A:t('플레이어 A','Player A'),B:t('플레이어 B','Player B')};
    const positions={SB:'top-left',BB:'top-right',A:'bottom-right',B:'bottom-left'};
    seats=Object.keys(names).map(id=>seat({name:names[id],pos:positions[id],active:example?false:id===active,folded:id==='SB'&&folded,caption:example?({SB:t('1칩 냄','Posts 1'),BB:t('2칩 냄','Posts 2'),A:t('4칩 냄','Pays 4'),B:t('4칩 냄','Pays 4')}[id]):id==='SB'&&folded?t('폴드','Folded'):''})).join('');
    const known=!example&&(state.assisted||state.answered!==null);
    center=chipStack(example?t('11칩','11 chips'):known?t('43칩','43 chips'):t('팟을 계산해요','Count the pot'),example||known);
  } else if(mode==='position'){
    seats=seat({name:t('버튼','Button'),pos:'bottom-left',dealer:true,active:!example&&state.answered!==null})+
      seat({name:'SB',pos:'top-left',caption:example?t('먼저 행동','Acts first'):''})+
      seat({name:'BB',pos:'top-right'})+
      seat({name:t('앞자리','Early seat'),pos:'bottom-right'});
    center=chipStack(t('자리 보기','See the seats'),false);
  } else if(mode==='play'){
    const step=playSteps[state.step],folded=step.folded;
    seats=seat({name:t('나','You'),pos:'bottom-left',active:step.actor==='you',cards:card('A','♠')+card('9','♥')})+
      seat({name:t('상대 1','Bot 1'),pos:'top-left',active:step.actor==='one',cards:card('back','')+card('back','')})+
      seat({name:t('상대 2','Bot 2'),pos:'top-right',active:step.actor==='two',folded:folded.includes('two'),cards:card('back','',folded.includes('two')?'folded':'')+card('back','',folded.includes('two')?'folded':''),caption:folded.includes('two')?t('폴드','Folded'):''})+
      seat({name:t('상대 3','Bot 3'),pos:'bottom-right',active:step.actor==='three',cards:card('back','')+card('back','')});
    center=chipStack(t('가운데 칩','Center chips'),false);
    if(state.step>=4)board=`<div class="board" aria-label="${t('공용 카드','Shared cards')}">${card('K','♦')}${card('7','♠')}${card('2','♣')}</div>`;
  }
  if(state.design==='refined'){
    return `<div class="table-wrap" data-table-mode="${mode}"><div class="table" role="group" aria-label="${t('포커 테이블','Poker table')}">${seats}<div class="center-group">${board}${center}</div></div></div>`;
  }
  return `<div class="table-wrap" data-table-mode="${mode}"><div class="table" role="group" aria-label="${t('포커 테이블','Poker table')}">${board}${seats}${center}</div></div>`;
}
function header(title,home=false){return `<div class="top"><button class="icon-button" data-action="exit" aria-label="${t('나가기','Exit')}">‹</button><span class="title">${title}</span><div class="top-actions">${home?'':`<button class="text-button" data-action="intro">${t('소개 다시 보기','Replay intro')}</button>`}</div></div>`}
function intro(){
  const m=state.mode;
  const info={
    pot:[t('팟 계산','Count the pot'),t('가운데 모인 칩을 알아야 다음 선택을 계산할 수 있어요. SB(스몰 블라인드)와 BB(빅 블라인드)는 시작할 때 칩을 내는 자리예요.','Knowing the pot helps with your next choice. SB and BB mean small and big blind, the seats that post starting chips.'),t('예시: SB가 1칩, BB가 2칩, A가 4칩, B가 4칩을 내면 11칩이에요.','Example: SB pays 1, BB pays 2, A pays 4, and B pays 4. The pot is 11.'),t('레이즈 18은 지금 18칩을 더 낸다는 뜻이 아니에요. 이미 낸 칩을 빼고 더해요.','A raise to 18 does not add 18 now. Subtract chips already paid.')],
    position:[t('자리와 행동 순서','Seats and action order'),t('자리마다 먼저 또는 나중에 행동해요. 늦게 행동하면 앞사람의 선택을 볼 수 있어요.','Your seat affects when you act. Acting later lets you see earlier choices.'),t('예시: 공용 카드 전에는 앞자리부터, 공용 카드 뒤에는 SB부터 행동해요. 버튼(D)은 공용 카드 뒤 마지막이에요.','Example: before shared cards, the early seat acts first. After shared cards, SB acts first and the button (D) acts last.'),t('SB는 작은 블라인드, BB는 큰 블라인드예요. 시작할 때 내는 칩을 뜻해요.','SB and BB are the small and big blinds, chips paid to start the hand.')],
    combos:[t('핸드 조합','Hand combinations'),t('같은 두 숫자라도 실제 카드 두 장의 종류는 여러 개예요.','One hand label can represent several actual two-card hands.'),t('예시: AA는 같은 숫자 두 장이에요. 에이스 4장 중 2장을 고르는 경우는 6개예요.','Example: AA is a pair. Choosing 2 of the 4 aces gives 6 combinations.'),t('s는 같은 무늬, o는 서로 다른 무늬예요. AKo는 에이스와 킹의 무늬가 달라요.','s means same suit; o means different suits. AKo has an ace and king of different suits.')],
    play:[t('테이블에서 연습','Practice at the table'),t('상대 카드의 뒷면, 접은 자리, 가운데 칩을 보며 한 행동씩 따라가요.','Follow one action at a time using face-down opponent cards, folded seats, and center chips.'),t('예시: 상대 2가 폴드하면 그 카드도 뒷면으로 남아요.','Example: when Bot 2 folds, its cards stay face down.'),t('이 손은 화면 검토용 대본이에요. 실제 게임 판단이나 점수가 아니에요.','This hand is scripted for screen review. It is not a live game or a grade.')]
  }[m];
  const visual=m==='combos'?`<div class="card-study">${card('A','♠')}${card('A','♥')}</div>`:table(m,true);
  const demo=m==='combos'?`<button class="button full" data-action="example" aria-expanded="${state.exampleExpanded}">${state.exampleExpanded?t('여섯 조합 접기','Hide six pairs'):t('가능한 두 장 보기','Show possible pairs')}</button>${state.exampleExpanded?`<div class="example-pairs" aria-label="${t('서로 다른 에이스 두 장의 여섯 조합','Six distinct ace pairs')}">${['♠♥','♠♦','♠♣','♥♦','♥♣','♦♣'].map(pair=>`<span>A${pair[0]} A${pair[1]}</span>`).join('')}</div><p class="small">${t('A♠를 빼면 남은 ♥, ♦, ♣ 중 두 장을 고르는 3가지가 남아요.','Remove A♠ and the remaining ♥, ♦, ♣ make 3 pairs.')}</p>`:''}`:m==='position'?`<button class="button full" data-action="example" aria-expanded="${state.exampleExpanded}">${state.exampleExpanded?t('행동 순서 접기','Hide action order'):t('행동 순서 비교','Compare action order')}</button>${state.exampleExpanded?`<div class="example-line">${t('공용 카드 전: 앞자리 → 버튼(D) → SB → BB. 공용 카드 뒤: SB부터 시계 방향이에요.','Before shared cards: early seat → button (D) → SB → BB. After them: clockwise from SB.')}</div>`:''}`:'';
  return `<div class="shell">${header(info[0],true)}<p class="eyebrow">${t('따라 배우기','Worked example')}</p><h1 class="prompt">${info[0]}</h1><p class="support">${info[1]}</p><div class="intro-visual">${visual}<div class="example-line">${info[2]}</div>${demo}</div><p class="support">${info[3]}</p><div class="button-group intro-actions"><button class="button" data-action="skip">${t('건너뛰고 문제 풀기','Skip to practice')}</button><button class="button primary" data-action="start">${t('내 차례 시작','Start my turn')}</button></div><p class="footer-note">${t('화면 검토용 대본. 학습 기록에 저장되지 않아요.','Scripted screen review. No learning record is saved.')}</p></div>`;
}
function replay(count){return `<div class="progress" aria-hidden="true">${Array.from({length:count},(_,i)=>`<span class="${i===state.step?'current':''}"></span>`).join('')}</div><div class="button-group"><button class="button" data-action="back" ${state.step===0?'disabled':''}>${t('이전 행동','Back')}</button><button class="button" data-action="next" ${state.step===count-1?'disabled':''}>${t('다음 행동','Next action')}</button><button class="button" data-action="replay">${t('처음부터','Replay')}</button></div>`}
function potResult(){
  const assisted=state.assisted;
  const correct=state.answered===43;
  const head=assisted?t('도움을 받아 마쳤어요','Completed with help'):correct?t('맞아요. 팟은 43칩이에요','Correct. The pot is 43 chips'):t('지금 팟은 43칩이에요','The pot is 43 chips');
  return `<div class="result" data-result="${assisted?'assisted':correct?'correct':'incorrect'}"><strong>${head}</strong><p>${t('BB는 이미 낸 2칩에 16칩을 더해 총 18칩, A는 6칩에 12칩을 더해 총 18칩을 냈어요.','BB adds 16 to its posted 2 for 18 total. A adds 12 to its earlier 6 for 18 total.')}</p><button class="text-button" data-action="steps" aria-expanded="${state.showSteps}">${state.showSteps?t('계산 접기','Hide steps'):t('계산 단계 보기','Show the steps')}</button>${state.showSteps?`<div class="steps"><p>1 + 2 + 6 + 6 + 16 + 12 = 43</p><p>SB 1 + BB 18 + A 18 + B 6 = 43</p><p>${t('A의 마지막 콜 직전은 31칩. B는 아직 다시 행동하지 않았어요.','The pot was 31 before A called 12. B has not acted again.')}</p></div>`:''}</div>`;
}
function pot(){
  const done=state.answered!==null;
  const last=state.step===steps.length-1;
  return `<div class="shell">${header(t('팟 계산','Count the pot'))}<p class="eyebrow">${t('연습 문제 · 행동을 눌러 따라가요','Practice · advance at your pace')}</p><h1 class="prompt">${t('지금 팟은 몇 칩일까요?','How many chips are in the pot now?')}</h1>${table('pot')}<p class="active-action" aria-live="polite"><span>${t('행동','Action')} ${state.step+1}/${steps.length}</span><strong>${t(({SB:'SB',BB:'BB',A:'플레이어 A',B:'플레이어 B'})[steps[state.step].actor],({SB:'SB',BB:'BB',A:'Player A',B:'Player B'})[steps[state.step].actor])}: ${t(steps[state.step].ko,steps[state.step].en)}</strong></p>${replay(steps.length)}<div class="row spread"><h2 class="section-title">${t('답 고르기','Choose an answer')}</h2><button class="text-button" data-action="help" ${done||!last||state.assisted?'disabled':''}>${t('계산 도움','Count with help')}</button></div>${done?potResult():`${state.assisted?`<div class="steps" data-help="true">${t('도움을 보고 답하는 중이에요. 자리별로 낸 칩: SB 1 + BB 18 + A 18 + B 6 = 43. 이 답은 독립 정답으로 세지 않아요.','Answering with help. Paid by seat: SB 1 + BB 18 + A 18 + B 6 = 43. This will not count as unaided correct.')}</div>`:''}<div class="choice-grid">${[45,43,49].map(n=>`<button class="choice" data-action="answer" data-value="${n}" ${!last?'disabled':''}>${n}${t('칩',' chips')}</button>`).join('')}</div><p class="status-note">${last?t('여기서 멈춰요. B는 아직 다시 행동하지 않았어요.','Stop here. B has not acted again yet.'):t('마지막 행동까지 본 뒤 답을 골라요. 다시 보기는 도움으로 세지 않아요.','Reach the last action to answer. Replaying alone does not count as help.')}</p>`}<p class="footer-note">${t('예시 대본. 도움 완료는 독립 정답으로 세지 않아요.','Scripted example. Assisted completion is not an unaided correct answer.')}</p></div>`;
}
function simpleResult(correct,explanation){return `<div class="result" data-result="${correct?'correct':'incorrect'}"><strong>${correct?t('맞아요','Correct'):t('다시 살펴봐요','Take another look')}</strong><p>${explanation}</p><button class="button" data-action="reset-question">${t('다시 풀기','Try again')}</button></div>`}
function position(){
  const done=state.answered!==null;
  return `<div class="shell">${header(t('자리와 행동 순서','Seats and action order'))}<p class="eyebrow">${t('연습 문제','Practice question')}</p><h1 class="prompt">${t('공용 카드 뒤 누가 마지막으로 행동할까요?','Who acts last after shared cards appear?')}</h1>${table('position')}<p class="support">${t('D는 딜러 버튼이에요. SB와 BB는 처음에 칩을 내는 자리예요.','D marks the dealer button. SB and BB post the starting chips.')}</p>${done?simpleResult(state.answered==='button',t('이 예시에서는 버튼(D)이 늦게 행동해 앞사람의 선택을 볼 수 있어요.','In this example the button (D) acts late and sees earlier choices.')):`<div class="choice-grid">${[['sb','SB'],['bb','BB'],['button',t('버튼 D','Button D')]].map(([v,label])=>`<button class="choice" data-action="answer" data-value="${v}">${label}</button>`).join('')}</div>`}<p class="footer-note">${t('이것은 4자리 소개 예시예요. 실제 자리 학습은 더 많은 자리도 다뤄요.','This is a four-seat introduction. The full position curriculum also covers more seats.')}</p></div>`;
}
function combos(){
  const done=state.answered!==null;
  return `<div class="shell">${header(t('핸드 조합','Hand combinations'))}<p class="eyebrow">${t('연습 문제','Practice question')}</p><h1 class="prompt">${t('AKo는 실제 카드 두 장으로 몇 가지일까요?','How many two-card combinations make AKo?')}</h1><div class="card-study">${card('A','♠')}${card('K','♥')}</div><p class="support">${t('o는 서로 다른 무늬예요. 에이스 4장과 킹 4장 중 하나씩 골라요.','o means different suits. Choose one of four aces and one of four kings.')}</p>${done?simpleResult(state.answered==='12',t('4 × 4 = 16가지에서 같은 무늬 4가지를 빼면 12가지예요.','4 × 4 = 16 pairings. Remove 4 same-suit pairings to get 12.')):`<div class="choice-grid">${['4','6','12'].map(v=>`<button class="choice" data-action="answer" data-value="${v}">${v}${t('가지','')}</button>`).join('')}</div>`}<p class="footer-note">${t('카드만 필요한 문제라 테이블은 표시하지 않아요.','This card-only question does not need a table.')}</p></div>`;
}
function play(){
  return `<div class="shell">${header(t('테이블에서 연습','Practice at the table'))}<p class="eyebrow">${t('4인 테이블 예시','Four-player example')}</p><h1 class="prompt">${t('한 행동씩 따라가요','Follow one action at a time')}</h1>${table('play')}<p class="active-action" aria-live="polite"><span>${t('행동','Action')} ${state.step+1}/${playSteps.length}</span><strong>${t(playSteps[state.step].ko,playSteps[state.step].en)}</strong></p>${replay(playSteps.length)}<div class="example-line">${t('상대 카드 앞면은 보이지 않아요. 접은 자리의 카드는 계속 뒷면이에요. 정해진 순서로 진행하는 화면 예시예요. 실제 게임이나 성적에는 반영되지 않아요.','Opponent card faces stay hidden, including after a fold. This fixed sequence is a screen example. It does not affect a real game or record.')}</div></div>`;
}
function home(){return `<div class="shell"><div class="top"><span class="title">Glass Table</span></div><p class="eyebrow">${t('화면 검토용 대본','Scripted screen review')}</p><h1 class="prompt">${t('한 번에 하나씩 배워요','Learn one decision at a time')}</h1><p class="support">${t('각 활동을 전체 화면으로 열어 보세요. 처음에는 짧은 예시를 볼 수 있어요.','Open each activity full screen. A short worked example appears on first use.')}</p><div class="mode-list">${[['pot',t('팟 계산','Count the pot'),t('행동을 따라가며 칩을 더해요','Replay actions and count chips')],['position',t('자리와 행동 순서','Seats and action order'),t('버튼과 블라인드를 알아봐요','Find the button and blinds')],['combos',t('핸드 조합','Hand combinations'),t('s와 o의 뜻을 알아봐요','Learn what s and o mean')],['play',t('테이블에서 연습','Practice at the table'),t('숨긴 카드와 폴드를 살펴봐요','See hidden cards and folds')]].map(([v,title,sub])=>`<button class="mode-tile" data-action="open" data-value="${v}"><strong>${title}</strong><span>${sub}</span></button>`).join('')}</div><p class="footer-note">${t('이 프로토타입은 앱의 학습 기록이나 게임 규칙을 구현하지 않아요.','This prototype does not implement app progress or game rules.')}</p></div>`}
function render(){document.documentElement.lang=state.lang;document.body.dataset.theme=state.theme;document.body.dataset.size=state.size;document.body.dataset.design=state.design;document.querySelector('#design').value=state.design;app.innerHTML=state.stage==='home'?home():state.stage==='intro'?intro():({pot,position,combos,play}[state.mode]());}
function enterPractice(){state.stage='practice';state.visited[state.mode]=true;safeStorage.set('gt-consistent-visited',JSON.stringify(state.visited));if(!state.introFromPractice){state.step=0;state.answered=null;state.assisted=false;state.showSteps=false}state.introFromPractice=false;render();}
app.addEventListener('click',event=>{
  const button=event.target.closest('button[data-action]');if(!button||button.disabled)return;
  const action=button.dataset.action,value=button.dataset.value;
  if(action==='exit'){if(state.stage==='practice'||state.introFromPractice)state.sessions[state.mode]={step:state.step,answered:state.answered,assisted:state.assisted,showSteps:state.showSteps};state.introFromPractice=false;state.stage='home';render();return}
  if(action==='open'){state.mode=value;state.stage=state.visited[value]?'practice':'intro';Object.assign(state,state.sessions[value]||{step:0,answered:null,assisted:false,showSteps:false});state.introFromPractice=false;render();return}
  if(action==='intro'){state.introFromPractice=true;state.exampleExpanded=false;state.stage='intro';render();return}
  if(action==='skip'||action==='start'){enterPractice();return}
  if(action==='example')state.exampleExpanded=!state.exampleExpanded;
  if(action==='back')state.step=Math.max(0,state.step-1);
  if(action==='next')state.step=Math.min(state.mode==='play'?playSteps.length-1:steps.length-1,state.step+1);
  if(action==='replay')state.step=0;
  if(action==='help'){state.assisted=true;state.showSteps=true}
  if(action==='answer')state.answered=state.mode==='pot'?Number(value):value;
  if(action==='steps')state.showSteps=!state.showSteps;
  if(action==='reset-question'){state.answered=null;state.assisted=false;state.showSteps=false}
  render();
  const replacement=app.querySelector(`button[data-action="${action}"]${value?`[data-value="${value}"]`:''}`);
  replacement?.focus({preventScroll:true});
});
document.querySelector('#language').addEventListener('change',e=>{state.lang=e.target.value;render()});
document.querySelector('#theme').addEventListener('change',e=>{state.theme=e.target.value;render()});
document.querySelector('#text-size').addEventListener('change',e=>{state.size=e.target.value;render()});
document.querySelector('#design').addEventListener('change',e=>{state.design=e.target.value;render()});
document.addEventListener('keydown',e=>{if(e.key==='Escape'&&state.stage!=='home'){state.stage='home';render()}});
render();
