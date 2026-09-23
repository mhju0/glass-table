"use strict";

const copy = {
  ko: {
    preview:"디자인 검토용 예시", settings:"설정", close:"닫기", language:"언어", appearance:"화면 모양", system:"기기 설정", light:"밝게", dark:"어둡게", langNote:"언어를 바꿔도 보고 있던 문제와 답은 그대로예요.",
    navToday:"오늘", navLearn:"배우기", navTable:"테이블", navRecords:"기록", todayTitle:"오늘은 한 판씩", todaySub:"짧게 풀고, 맞힌 이유를 확인해요. 연습 기록은 아래 예시로 볼 수 있어요.",
    learnTitle:"카드부터 읽어 볼까요", learnSub:"어려운 말은 필요한 순간에만 덧붙여요. 먼저 상황을 보고, 직접 고른 뒤 설명을 읽어요.", learnIntro:"쇼다운 연습", learnIntroSub:"누가 이겼는지 카드 다섯 장을 비교해요.", learnChart:"내 카드가 표에서 어디쯤일까요?", learnChartSub:"선택을 마친 뒤 기준표를 펼쳐 볼 수 있어요.", goIntro:"짧은 소개 보기", goChart:"카드 표 예시 보기", goPractice:"다섯 문제 풀기", goTable:"네 자리 테이블 보기", practiceTitle:"누가 이겼을까요?", practiceIntroTitle:"쇼다운: 카드 비교하기", practiceWhy:"마지막에 누가 팟을 가져가는지 알면, 앞선 선택도 더 잘 이해할 수 있어요.", practiceHow:"공용 카드 다섯 장과 각자의 카드 두 장으로 가장 좋은 다섯 장을 만들어요. 높은 조합이 이겨요.", practiceExample:"연습 전 예시", practiceExampleBody:"공용 카드에 A가 있고, 내 손에는 A가 하나 더 있어요. 상대에게 짝이 없다면 내 에이스 한 쌍이 앞서요.", skipIntro:"소개 건너뛰기", startPractice:"문제 풀기", replayIntro:"소개 다시 보기", practiceFor:"쇼다운 연습", practicePrompt:"두 사람 중 카드가 더 높은 쪽은 누구일까요?", shared:"공용 카드", yourCards:"내 카드", theirCards:"상대 카드", you:"나", them:"상대", tie:"무승부", choose:"답을 골라요", correct:"맞았어요", incorrect:"이번에는 달라요", answerIs:"이 판의 답", why:"왜 그럴까요?", nextQuestion:"다음 문제", seeSummary:"연습 결과 보기", questionOf:"문제", questionCount:"다섯 문제 중", help:"비교 도움말", helpBody:"같은 다섯 장을 쓸 수 있으면 무승부예요. 한 쌍끼리 같으면 남는 높은 카드까지 비교해요.", roundTitle:"이번 다섯 문제", roundNote:"이 화면은 사용 예시입니다. 실제 학습 기록과 연결되지 않아요.", right:"맞힌 문제", anotherRound:"다섯 문제 다시 풀기", changeSkill:"다른 화면 보기", leaveNote:"중간에 나가도 이미 푼 문제는 기록하는 설계를 검토하고 있어요.",
    chartTitle:"내 손을 표에서 찾기", chartContext:"예시 상황: 앞자리 상대가 먼저 금액을 올렸어요. 내 카드는 J♠ 5♥예요.", chartAsk:"당신이라면 어떻게 할까요?", raise:"다시 올리기", call:"맞추기", fold:"접기", chartUnlock:"먼저 선택하면 기준표를 보여드려요.", chartResult:"이 예시에서 J5o는 접는 칸이에요.", chartWrong:"선택과 기준표가 달라요. 아래에서 내 칸을 찾아보세요.", chartRight:"기준표와 같은 선택이에요. 아래에서 내 칸을 찾아보세요.", chartSummary:"J와 5, 무늬가 달라요", chartNote:"이 표는 레이아웃 검토용 색 구분 예시예요. 실제 채점 데이터가 아닙니다.", expandChart:"큰 표로 보기", closeChart:"작은 표로 돌아가기", chartTap:"칸을 눌러 뜻을 볼 수 있어요. 가로와 세로로 움직일 수 있어요.", chartRows:"글로 표 읽기", selectedCell:"선택한 칸", legendRaise:"다시 올리기", legendCall:"맞추기", legendFold:"접기", chartMeaning:"J5o의 o는 두 카드 무늬가 다르다는 뜻이에요.", resetChart:"다른 선택 해보기", selected:"선택",
    opponentsTitle:"어떤 상대와 연습할까요?", opponentsSub:"별명보다 플레이 습관을 먼저 읽을 수 있게 했어요. 숫자는 자세히 보기에 넣었어요.", pickOpponent:"이 상대와 시작하기", details:"상세 보기", technical:"숫자는 상대 규칙의 설정값이에요. 실제 사람의 기록이 아니에요.", vpip:"VPIP: 자발적으로 판에 들어오는 비율", pfr:"PFR: 시작할 때 금액을 올리는 비율", tableTitle:"네 자리 연습 테이블", tableSub:"한 동작씩 넘겨 보세요. 이 판의 카드와 결과는 정해진 검토 예시예요.", nextAction:"다음 동작", previousAction:"이전 동작", handReview:"판 돌아보기", actionNow:"지금", pot:"가운데 모인 칩", paid:"낸 칩", dealer:"딜러", smallBlind:"작은 블라인드", bigBlind:"큰 블라인드", tableHelp:"처음 두 사람은 의무로 1칩, 2칩을 내요. 접어도 이미 낸 칩은 가운데 남아요.", tableReviewTitle:"이 판에서 일어난 일", tableReviewBody:"모두 같은 금액을 냈고, 이후에는 새 칩을 내지 않았어요. 공개된 카드로 비교하면 내가 이겨 6칩을 받아요.", tableResult:"내 카드: A♥ K♣ · 공용 카드: K♠ 7♣ 2♦ 4♠ J♥", tablePayout:"시작 100칩 → 2칩 냄 → 6칩 받음 = 104칩", revealHands:"상대 카드 모두 보기", hideHands:"상대 카드 감추기", hindsight:"판이 끝난 뒤에만 모든 카드를 보여줘요. 당시 선택의 정답으로 쓰지 않아요.", resetHand:"예시 다시 보기", notEngine:"이 화면은 고정된 한 판입니다. 실제 네 명 게임 규칙 엔진은 아직 연결하지 않았어요.",
    recordsTitle:"조금씩 나아지는 모습", recordsSub:"같은 연습을 한 날을 모아 볼 수 있어요. 시간은 참고만 하고, 빨리 답하라고 재촉하지 않아요.", fixture:"아래 숫자는 화면 검토용 가상 예시예요.", recordState:"기록 화면 상태", sample:"예시 기록", empty:"처음 상태", loading:"불러오는 중", error:"오류", todayRecord:"오늘의 쇼다운", attempts:"문제", exact:"정확", near:"가까움", missed:"다시 보기", elapsed:"평균 답변 시간", timeNote:"방해 없이 혼자 푼 답만 시간 추세에 넣어요. 속도로 정답을 평가하지 않아요.", weekCompare:"지난주와 이번주", lastWeek:"지난주", thisWeek:"이번주", sampleComparison:"같은 방식으로 푼 날만 비교한다는 설계 예시예요.", emptyTitle:"아직 기록이 없어요", emptyBody:"쇼다운 다섯 문제를 풀면 오늘의 기록이 여기에 쌓여요.", errorTitle:"기록을 열지 못했어요", errorBody:"이 예시에서는 다시 누르면 기록이 돌아와요. 실제 앱에서는 저장 파일을 지우지 않아요.", retry:"다시 열기", loadingBody:"기록을 불러오고 있어요.",
    stylesTitle:"테이블에서 보인 내 선택", stylesSub:"충분한 판이 쌓였을 때, 최근 선택 패턴을 짧게 보여주는 구상이에요.", styleSample:"예시: 30일 안에 6일 동안 완료한 120판", styleEligible:"자발적으로 들어간 판", styleRaise:"들어간 판 중 먼저 올린 판", styleName:"자주 들어가고 자주 올려요", styleInterpret:"이 예시에서는 판에 자주 참여했고, 참여할 때 먼저 금액을 올리는 편이었어요.", styleCaveat:"최근 선택의 묘사일 뿐, 성격이나 실력을 뜻하지 않아요.", styleEvidence:"72 / 120판 참여 · 참여한 72판 중 59판 먼저 올림", styleNext:"다음 연습: 시작 카드 고르기", styleInsufficient:"지금은 유형을 붙이기 일러요", styleInsufficientBody:"예시 기록은 18판, 2일이에요. 100판 이상과 5일 이상의 기록을 기다리도록 설계했어요.", styleTypes:"검토할 다섯 가지 표현", styleStateSample:"충분한 기록 예시", styleStateShort:"기록 부족 예시", styleType0:"가려 들어가고 자주 올려요", styleType1:"가려 들어가고 자주 맞춰요", styleType2:"자주 들어가고 자주 올려요", styleType3:"자주 들어가고 자주 맞춰요", styleType4:"상황에 따라 골고루 선택해요", styleTypeNote:"다섯 이름은 최근 시작 행동을 말해요. 충분하지 않거나 경계에 걸리면 이름을 붙이지 않아요.",
    timingShow:"답변 시간 보기", timingHide:"답변 시간 감추기", assisted:"도움을 보고 푼 문제", independent:"혼자 푼 문제", chartAria:"13줄 13칸 카드 표", resume:"풀던 문제 계속하기", ownCell:"내 J5o 칸으로 이동", startFromToday:"오늘에서 연습하기", menuHelp:"도움말", introReturn:"연습으로 돌아가기"
  },
  en: {
    preview:"Design review example", settings:"Settings", close:"Close", language:"Language", appearance:"Appearance", system:"Device setting", light:"Light", dark:"Dark", langNote:"Changing language keeps your current question and answer in place.",
    navToday:"Today", navLearn:"Learn", navTable:"Table", navRecords:"Records", todayTitle:"One hand at a time", todaySub:"Answer a short question, then see why. The practice record below is a sample.",
    learnTitle:"Start with the cards", learnSub:"We introduce poker terms when you need them. See the situation, make a choice, then read why.", learnIntro:"Showdown practice", learnIntroSub:"Compare the best five cards to see who wins.", learnChart:"Where are my cards on the chart?", learnChartSub:"Open the reference chart after you make a choice.", goIntro:"Read the short introduction", goChart:"See the card chart example", goPractice:"Answer five questions", goTable:"See the four-seat table", practiceTitle:"Who wins this hand?", practiceIntroTitle:"Showdown: compare the cards", practiceWhy:"Knowing who wins the pot helps you make sense of earlier choices.", practiceHow:"Use the five shared cards and each player's two cards to make the best five-card hand. The stronger hand wins.", practiceExample:"Example before practice", practiceExampleBody:"There is an ace on the board and another in your hand. If the opponent has no pair, your pair of aces is ahead.", skipIntro:"Skip introduction", startPractice:"Start questions", replayIntro:"Read introduction again", practiceFor:"Showdown practice", practicePrompt:"Whose cards make the stronger hand?", shared:"Shared cards", yourCards:"My cards", theirCards:"Opponent's cards", you:"Me", them:"Opponent", tie:"Tie", choose:"Choose an answer", correct:"That's right", incorrect:"Different this time", answerIs:"Answer for this hand", why:"Why?", nextQuestion:"Next question", seeSummary:"See practice summary", questionOf:"Question", questionCount:"of five", help:"Help comparing hands", helpBody:"If both players can use the same five cards, it is a tie. If their pairs match, compare the highest remaining card.", roundTitle:"This five-question round", roundNote:"This is a sample for design review. It is not connected to your learning history.", right:"Correct answers", anotherRound:"Answer five more", changeSkill:"See another screen", leaveNote:"The design will keep answers already given if you leave early.",
    chartTitle:"Find my hand on the chart", chartContext:"Example: an early-position player raises first. You hold J♠ 5♥.", chartAsk:"What would you do?", raise:"Raise again", call:"Match the bet", fold:"Fold", chartUnlock:"Choose first to see the reference chart.", chartResult:"In this example, J5o is in the fold band.", chartWrong:"Your choice differs from the chart. Find your square below.", chartRight:"Your choice matches the chart. Find your square below.", chartSummary:"Jack and five, different suits", chartNote:"The colors in this chart are for layout review. They are not the app's grading data.", expandChart:"Open large chart", closeChart:"Return to small chart", chartTap:"Tap a square to read it. You can scroll in both directions.", chartRows:"Read chart as text", selectedCell:"Selected square", legendRaise:"Raise again", legendCall:"Match", legendFold:"Fold", chartMeaning:"The o in J5o means the two cards have different suits.", resetChart:"Try another choice", selected:"Selected",
    opponentsTitle:"Who will you practice against?", opponentsSub:"Read their habits first. The technical numbers are in the details.", pickOpponent:"Start with this opponent", details:"See details", technical:"These numbers configure a rule-based opponent. They are not a real person's history.", vpip:"VPIP: how often they voluntarily enter a hand", pfr:"PFR: how often they raise before shared cards appear", tableTitle:"Four-seat practice table", tableSub:"Move through one action at a time. This hand is a fixed design-review example.", nextAction:"Next action", previousAction:"Previous action", handReview:"Review the hand", actionNow:"Now", pot:"Chips in the middle", paid:"Chips paid", dealer:"Dealer", smallBlind:"Small blind", bigBlind:"Big blind", tableHelp:"The first two players must post 1 and 2 chips. Folded players leave any chips they already paid in the middle.", tableReviewTitle:"What happened in this hand", tableReviewBody:"Everyone matched the same amount. Nobody added more chips afterward. Your cards win the six-chip pot at the end.", tableResult:"Your cards: A♥ K♣ · Shared cards: K♠ 7♣ 2♦ 4♠ J♥", tablePayout:"Start with 100 → pay 2 → receive 6 = 104 chips", revealHands:"Show all opponent cards", hideHands:"Hide opponent cards", hindsight:"All cards appear only after the hand ends. They do not grade what you knew earlier.", resetHand:"Replay this example", notEngine:"This is one fixed hand. A four-player rules engine is not connected yet.",
    recordsTitle:"See your practice take shape", recordsSub:"See the days you practiced the same skill. Time is optional context; there is no timer pressuring you to answer.", fixture:"All numbers below are sample data for reviewing this screen.", recordState:"Record screen state", sample:"Sample record", empty:"First visit", loading:"Loading", error:"Error", todayRecord:"Today's showdown", attempts:"Questions", exact:"Exact", near:"Close", missed:"Review", elapsed:"Average answer time", timeNote:"Only uninterrupted independent answers enter the time trend. Speed does not change the grade.", weekCompare:"Last week and this week", lastWeek:"Last week", thisWeek:"This week", sampleComparison:"The design compares days with the same question format.", emptyTitle:"No practice recorded yet", emptyBody:"Answer five showdown questions to start today's record.", errorTitle:"Could not open the record", errorBody:"Retry restores the sample here. In the app, a save error must not erase the file.", retry:"Try again", loadingBody:"Loading practice history.",
    stylesTitle:"What your table choices show", stylesSub:"After enough hands, a short report could describe recent choices.", styleSample:"Example: 120 finished hands across 6 days in the last 30 days", styleEligible:"Hands entered voluntarily", styleRaise:"Entered hands with an opening raise", styleName:"Often enters and raises", styleInterpret:"In this example, you often joined a hand and often raised when you joined.", styleCaveat:"This describes recent choices, not your personality or skill.", styleEvidence:"Entered 72 / 120 hands · raised in 59 / 72 entered hands", styleNext:"Suggested practice: choose starting cards", styleInsufficient:"Too early to name a style", styleInsufficientBody:"This sample has 18 hands across 2 days. The proposed report waits for 100 hands across at least 5 days.", styleTypes:"Five phrases to review", styleStateSample:"Enough history sample", styleStateShort:"Not enough history sample", styleType0:"Selective entry, often raises", styleType1:"Selective entry, often matches", styleType2:"Frequent entry, often raises", styleType3:"Frequent entry, often matches", styleType4:"Uses a mix of choices", styleTypeNote:"These names describe recent starting actions. When evidence is thin or near a boundary, the report does not assign a name.",
    timingShow:"Show answer time", timingHide:"Hide answer time", assisted:"Questions answered with help", independent:"Questions answered independently", chartAria:"13-row, 13-column card chart", resume:"Continue the round", ownCell:"Go to my J5o square", startFromToday:"Practice from Today", menuHelp:"Help", introReturn:"Return to practice"
  }
};

Object.assign(copy.ko, {
  elapsed:"맞힌 3문제의 평균 시간",
  independent:"혼자 푼 문제 중 맞힌 수",
  startFromToday:"연습 기록 보기",
  timeNote:"방해 없이 혼자 맞힌 답만 시간 추세에 넣어요. 속도로 정답을 평가하지 않아요.",
  practiceExampleBody:"공용 카드에 A가 있고 내 손에도 A가 있어요. 상대가 Q와 J를 들었다면 내 에이스 한 쌍이 이겨요.",
  helpBody:"가장 좋은 다섯 장의 힘이 같으면 무승부예요. 조합이 같을 때는 남는 높은 카드부터 비교해요.",
  tableReviewBody:"세 자리가 2칩씩 냈고, 한 자리는 접었어요. 이후 새 칩은 없었어요. 공개된 카드로 비교하면 내가 이겨 6칩을 받아요.",
  notEngine:"이 화면은 고정된 한 판입니다. 고른 상대의 설명만 A 자리에 표시하고, 행동은 바뀌지 않아요.",
  styleRaise:"참여한 판 중 공용 카드가 나오기 전에 올린 판",
  styleInterpret:"이 예시에서는 판에 자주 참여했고, 참여할 때 공용 카드가 나오기 전에 자주 올렸어요.",
  styleType4:"올림과 맞춤을 섞어 선택했어요",
  chartRight:"기준표와 같은 선택이에요.", chartWrong:"선택과 기준표가 달라요.", incorrect:"정답을 함께 볼까요?",
  styleNick0:"골라 올리기형", styleNick1:"골라 맞추기형", styleNick2:"자주 올리기형", styleNick3:"자주 맞추기형", styleNick4:"골고루형"
});
Object.assign(copy.en, {
  elapsed:"Average time for 3 correct answers",
  independent:"Correct without help",
  startFromToday:"See practice records",
  timeNote:"Only uninterrupted, correct, independent answers enter the time trend. Speed does not change the grade.",
  practiceExampleBody:"There is an ace among the shared cards and another in your hand. Against an opponent holding queen and jack, your pair of aces wins.",
  helpBody:"It is a tie when the best five-card hands have equal strength. For matching hands, compare remaining high cards from highest to lowest.",
  tableReviewBody:"Three seats paid two chips each, and one folded. No new chips were added afterward. Your cards win the six-chip pot.",
  notEngine:"This is one fixed hand. Your chosen label appears on seat A, but scripted actions do not change.",
  styleRaise:"Entered hands with a raise before shared cards appear",
  styleInterpret:"In this example, you often joined a hand and often raised before the shared cards appeared.",
  styleType4:"Mixes raises and matches",
  chartRight:"Your choice matches the chart.", chartWrong:"Your choice differs from the chart.", incorrect:"Let's look at the answer",
  styleNick0:"Pick-and-raise", styleNick1:"Pick-and-match", styleNick2:"Frequent raiser", styleNick3:"Frequent caller", styleNick4:"Mix-it-up"
});

const opponents = [
  { id:"nit", ko:"좋은 카드만 골라 들어와요", en:"Waits for strong cards", name:"Nit", detailKo:"드물게 판에 들어오고, 들어올 때도 조심스럽게 움직여요.", detailEn:"Enters few hands and usually plays them carefully.", vpip:12, pfr:9 },
  { id:"tag", ko:"고르고 들어와 먼저 올려요", en:"Picks hands, then raises", name:"TAG", detailKo:"들어갈 카드를 고른 뒤에는 금액을 올리는 편이에요.", detailEn:"Chooses hands carefully, then often raises.", vpip:20, pfr:17 },
  { id:"lag", ko:"여러 카드로 들어와 자주 올려요", en:"Joins often and raises", name:"LAG", detailKo:"다양한 카드로 시작하고 금액도 자주 올려요.", detailEn:"Starts with a wider set of cards and raises often.", vpip:27, pfr:22 },
  { id:"station", ko:"여러 카드로 들어와 자주 맞춰요", en:"Joins often and calls", name:"Calling station", detailKo:"많은 판에 참여하지만 먼저 올리기보다 상대 금액을 맞추는 편이에요.", detailEn:"Joins many hands and often matches a bet instead of raising.", vpip:40, pfr:10 },
  { id:"maniac", ko:"아주 자주 들어와 크게 밀어붙여요", en:"Joins and raises very often", name:"Maniac", detailKo:"넓은 카드 범위로 자주 들어오고, 금액을 많이 올려요.", detailEn:"Enters a very wide range and raises frequently.", vpip:55, pfr:40 }
];

const systemLanguage = () => {
  const preferred=(navigator.languages||[navigator.language||"en"]).map(v=>String(v).toLowerCase());
  const first=preferred.find(v=>v.startsWith("ko")||v.startsWith("en"));
  return first?.startsWith("ko")?"ko":"en";
};
const state = { lang:systemLanguage(), langOption:"system", theme:"system", route:"learn", settings:false, opp:"tag", oppDetails:false, chartChoice:null, chartExpanded:false, chartCell:"J5o", practiceStage:"idle", introReturnStage:"idle", q:0, answers:[], assisted:[], answer:null, help:false, tableIndex:-1, tableReview:false, hindsight:false, recordsState:"sample", timing:false, styleState:"sample", styleDetail:2 };
const $ = key => copy[state.lang][key];
const esc = text => String(text).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const btn = (label, action, extra="", attrs="") => {
  if(action==="practice-intro"&&label===$("goPractice")&&state.practiceStage!=="idle"){
    action="practice-resume";
    label=$("resume");
  }
  if(action==="style-detail"){
    const id=attrs.match(/data-value="(\d)"/)?.[1];
    label=`<strong>${$(`styleNick${id}`)}</strong><br><small>${label}</small>`;
  }
  return `<button type="button" class="btn ${extra}" data-action="${action}" ${attrs}>${label}</button>`;
};
const card = value => `<span class="card ${/[♥♦]/.test(value)?"red":""}" aria-label="${esc(value)}"><span>${esc(value.slice(0,-1))}</span><span class="suit">${esc(value.slice(-1))}</span></span>`;
const cards = items => `<span class="cards">${items.map(card).join("")}</span>`;
const labelValue = (label,value) => {
  const pair=`<div class="data-pair"><span>${esc(label)}</span><strong>${esc(value)}</strong></div>`;
  if(label===$('elapsed'))return `<div class="section">${btn(state.timing?$('timingHide'):$('timingShow'),'timing-toggle','block')}</div>${state.timing?pair:''}`;
  return pair;
};
const enterPractice = () => state.practiceStage==="question"||state.practiceStage==="summary" ? "practice-resume" : "practice-intro";
const intro = () => `<section class="page"><p class="eyebrow">${$("preview")} · ${$("practiceFor")}</p><h1 class="title">${$("practiceIntroTitle")}</h1><p class="sub">${$("practiceWhy")}</p><div class="section raised stack"><div class="lesson-note"><span class="step">1</span><p>${$("practiceHow")}</p></div><div class="divider"></div><h2>${$("practiceExample")}</h2><div class="card-row"><strong>${$("shared")}</strong>${cards(["A♦","K♣","9♥","5♣","2♠"])}</div><div class="card-row"><strong>${$("yourCards")}</strong>${cards(["A♠","7♥"])}</div><div class="card-row"><strong>${$("theirCards")}</strong>${cards(["Q♥","J♣"])}</div><p class="muted">${$("practiceExampleBody")}</p></div><div class="button-row section">${state.introReturnStage==="idle"?`${btn($("startPractice"),"practice-start","primary")}${btn($("skipIntro"),"practice-start")}`:btn($("introReturn"),"practice-resume","primary")}</div></section>`;
function learn() { return `<section class="page"><p class="eyebrow">${$("preview")} · ${$("navLearn")}</p><h1 class="title">${$("learnTitle")}</h1><p class="sub">${$("learnSub")}</p><section class="section raised"><h2>${$("learnIntro")}</h2><p class="muted">${$("learnIntroSub")}</p><div class="section">${btn($("goIntro"),"practice-intro","primary block")}</div></section><section class="section surface"><h2>${$("learnChart")}</h2><p class="muted">${$("learnChartSub")}</p><div class="section">${btn($("goChart"),"chart-open","block")}</div></section></section>`; }
function today() {return `<section class="page"><p class="eyebrow">${$("preview")} · ${$("navToday")}</p><h1 class="title">${$("todayTitle")}</h1><p class="sub">${$("todaySub")}</p><div class="section table-object"><div>${cards(["A♠","K♥"])}<p style="margin-top:12px">${$("practicePrompt")}</p></div></div><div class="section">${btn($("goPractice"),"practice-intro","primary block")}</div><div class="section callout"><strong>${$("recordState")}</strong>${$("fixture")}</div><div class="section">${btn($("startFromToday"),"records-open","block")}</div></section>`;}
function question(){const q=GTModel.questions[state.q];const answered=state.answer!==null;const n=state.q+1;return `<section class="page"><p class="eyebrow">${$("practiceFor")} · ${$("questionOf")} ${n} / 5</p><div class="progress-track" aria-label="${n} / 5"><span style="width:${(n-1)*20}%"></span></div><h1 class="title section">${$("practiceTitle")}</h1><p class="sub">${$("practicePrompt")}</p><div class="section table-object"><div><p>${$("shared")}</p>${cards(q.board)}</div></div><div class="section raised stack"><div class="card-row"><strong>${$("yourCards")}</strong>${cards(q.you)}</div><div class="card-row"><strong>${$("theirCards")}</strong>${cards(q.them)}</div></div><section class="section"><h2>${$("choose")}</h2><div class="choice-grid">${["you","them","tie"].map(v=>btn($(v),"practice-answer",state.answer===v?"selected":"",`data-value="${v}" aria-pressed="${state.answer===v}" ${answered?"disabled":""}`)).join("")}</div></section>${answered?`<div class="section pill-state ${state.answer===q.winner?"success":"failure"}" role="status"><strong>${state.answer===q.winner?$("correct"):$("incorrect")}</strong><p>${$("answerIs")}: ${$(q.winner)}</p><p>${q.why[state.lang]}</p></div><div class="section">${btn(state.q===4?$("seeSummary"):$("nextQuestion"),"practice-next","primary block")}</div>`:`<div class="section">${btn($("help"),"practice-help","block")}${state.help?`<div class="callout" style="margin-top:8px">${$("helpBody")}</div>`:""}</div>`}<div class="section tiny">${$("leaveNote")}</div></section>`;}
function practiceSummary(){
  const right=state.answers.filter((a,i)=>a===GTModel.questions[i].winner).length;
  const assisted=state.assisted.filter(Boolean).length;
  const soloRight=state.answers.filter((a,i)=>!state.assisted[i]&&a===GTModel.questions[i].winner).length;
  return `<section class="page"><p class="eyebrow">${$("preview")} · ${$("practiceFor")}</p><h1 class="title">${$("roundTitle")}</h1><p class="sub">${$("roundNote")}</p><div class="section raised"><span class="eyebrow">${$("right")}</span><div class="title">${right} / 5</div><div class="progress-track"><span style="width:${right*20}%"></span></div><div class="section">${labelValue($("assisted"),String(assisted))}${labelValue($("independent"),`${soloRight} / ${5-assisted}`)}</div><p class="muted" style="margin-top:14px">${right<3?$("helpBody"):$("practiceWhy")}</p></div><div class="section button-row">${btn($("anotherRound"),"practice-restart","primary")}${btn($("replayIntro"),"practice-intro")}${btn($("changeSkill"),"learn-open")}</div></section>`;
}
function chart(){
  const answered=state.chartChoice!==null;
  const selected=GTModel.hands.find(h=>h.label===state.chartCell);
  const top=`<p class="eyebrow">${$("preview")} · ${$("navLearn")}</p><h1 class="title">${$("chartTitle")}</h1>`;
  if(!answered){
    return `<section class="page">${top}<p class="sub">${$("chartContext")}</p>
      <div class="section raised chart-summary">${cards(["J♠","5♥"])}<div><strong>J5o</strong><p class="muted">${$("chartSummary")}</p></div></div>
      <div class="section"><h2>${$("chartAsk")}</h2><div class="choice-grid">
      ${["raise","call","fold"].map(v=>btn($(v),"chart-choose","",`data-value="${v}"`)).join("")}</div></div>
      <div class="section callout">${$("chartUnlock")}</div></section>`;
  }
  const cells=state.chartExpanded
    ? `<p class="muted">${$("chartTap")}</p><div class="chart-explore" tabindex="0" aria-label="${$("expandChart")}"><div class="chart-grid">${GTModel.hands.map(h=>`<button type="button" class="${h.action} ${state.chartCell===h.label?"selected":""}" data-action="chart-cell" data-value="${h.label}" aria-label="${h.label}: ${$(h.action)}" aria-pressed="${state.chartCell===h.label}">${h.label}</button>`).join("")}</div></div>
      <div class="pill-state"><strong>${$("selectedCell")}: ${selected.label}</strong><p>${$(selected.action)}</p></div>
      ${btn($("ownCell"),"chart-own","block")}
      <details class="chart-rows"><summary>${$("chartRows")}</summary>${GTModel.ranks.map((r,i)=>`<p><strong>${r}</strong>: ${GTModel.hands.slice(i*13,i*13+13).map(h=>`${h.label} ${$(h.action)}`).join(", ")}</p>`).join("")}</details>`
    : `<div class="chart-overview-wrap"><div class="chart-overview" role="img" aria-label="${$("chartAria")}. J5o: ${$("fold")}">${GTModel.hands.map(h=>`<span class="chart-cell ${h.action} ${h.label==="J5o"?"selected":""}">${h.label}</span>`).join("")}</div></div>`;
  return `<section class="page chart-answer">${top}
    <div class="chart-summary section">${cards(["J♠","5♥"])}<div><strong>J5o · ${$("fold")}</strong><p class="muted">${$("chartMeaning")}</p></div></div>
    <div class="pill-state ${state.chartChoice==="fold"?"success":"failure"}" role="status"><p>${state.chartChoice==="fold"?$("chartRight"):$("chartWrong")}</p></div>
    <div class="chart-key"><span><i class="swatch raise"></i>${$("legendRaise")}</span><span><i class="swatch call"></i>${$("legendCall")}</span><span><i class="swatch fold"></i>${$("legendFold")}</span></div>
    <div class="section button-row">${btn(state.chartExpanded?$("closeChart"):$("expandChart"),"chart-expand","primary")}${btn($("resetChart"),"chart-reset")}</div>
    <div class="section">${cells}</div>
    <p class="tiny section">${$("chartNote")}</p></section>`;
}
function opponentPicker(){const selected=opponents.find(o=>o.id===state.opp);return `<section class="page"><p class="eyebrow">${$("preview")} · ${$("navTable")}</p><h1 class="title">${$("opponentsTitle")}</h1><p class="sub">${$("opponentsSub")}</p><div class="section opponent-grid stack">${opponents.map(o=>`<button type="button" class="opponent ${o.id===state.opp?"active":""}" data-action="opp-select" data-value="${o.id}" aria-pressed="${o.id===state.opp}"><span class="name">${state.lang==="ko"?o.ko:o.en}</span><span class="micro">${o.name}</span><span class="desc">${state.lang==="ko"?o.detailKo:o.detailEn}</span></button>`).join("")}</div><div class="section button-row">${btn($("details"),"opp-details")}${btn($("pickOpponent"),"table-start","primary")}</div>${state.oppDetails?`<div class="detail-panel"><h2>${state.lang==="ko"?selected.ko:selected.en} (${selected.name})</h2><p>${$("technical")}</p>${labelValue($("vpip"),`${selected.vpip}%`)}${labelValue($("pfr"),`${selected.pfr}%`)}</div>`:""}</section>`;}
const seatName = id => ({you:state.lang==="ko"?"나":"Me",a:state.lang==="ko"?"상대 A":"Bot A",b:state.lang==="ko"?"상대 B":"Bot B",c:state.lang==="ko"?"상대 C":"Bot C"})[id];
function table(){const event=state.tableIndex>=0?GTModel.tableEvents[state.tableIndex]:null;const paid=GTModel.tableAt(state.tableIndex);const street=event?.street||"pre";const board=street==="river"?["K♠","7♣","2♦","4♠","J♥"]:street==="turn"?["K♠","7♣","2♦","4♠"]:street==="flop"?["K♠","7♣","2♦"]:[];const total=Object.values(paid).reduce((a,b)=>a+b,0);return `<section class="page"><p class="eyebrow">${$("preview")} · ${$("navTable")}</p><h1 class="title">${$("tableTitle")}</h1><p class="sub">${$("tableSub")}</p><div class="section table-layout">${["c","a"].map(id=>seat(id,paid,event)).join("")}<div class="board-area"><strong>${$("pot")}: ${total}</strong>${board.length?cards(board):`<span class="muted">${$("shared")} · ${state.lang==="ko"?"아직 없음":"Not dealt yet"}</span>`}</div>${["b","you"].map(id=>seat(id,paid,event)).join("")}</div><div class="timeline" aria-label="${state.tableIndex+1} / ${GTModel.tableEvents.length}">${GTModel.tableEvents.map((_,i)=>`<span class="${i<=state.tableIndex?"done":""}"></span>`).join("")}</div>${event?`<p class="muted">${$("actionNow")}: ${seatName(event.seat)} · ${event[state.lang]}</p>`:`<p class="muted">${$("tableHelp")}</p>`}<div class="section button-row">${btn($("previousAction"),"table-prev","",`${state.tableIndex<0?"disabled":""}`)}${btn(state.tableIndex===GTModel.tableEvents.length-1?$("handReview"):$("nextAction"),state.tableIndex===GTModel.tableEvents.length-1?"table-review":"table-next","primary")}</div><div class="section callout">${$("notEngine")}</div></section>`;}
function seat(id,paid,event){
  const chosen=opponents.find(o=>o.id===state.opp);
  return `<div class="seat ${event?.seat===id?"active":""}"><strong>${seatName(id)} ${id==="you"?`· ${$("dealer")}`:id==="a"?`· ${$("smallBlind")}`:id==="b"?`· ${$("bigBlind")}`:""}</strong>${id==="a"?`<span class="subline">${state.lang==="ko"?chosen.ko:chosen.en}</span>`:""}<span class="subline">${$("paid")}: ${paid[id]}</span>${event?.seat===id?`<span class="seat-action">${event[state.lang]}</span>`:""}</div>`;
}
function tableReview(){return `<section class="page"><p class="eyebrow">${$("preview")} · ${$("navTable")}</p><h1 class="title">${$("tableReviewTitle")}</h1><p class="sub">${$("tableReviewBody")}</p><div class="section table-object"><div><p>${$("shared")}</p>${cards(["K♠","7♣","2♦","4♠","J♥"])}<p style="margin-top:12px">${$("pot")}: 6</p></div></div><div class="section raised"><div class="card-row"><strong>${$("yourCards")}</strong>${cards(["A♥","K♣"])}</div><div class="divider"></div><p>${$("tablePayout")}</p></div><div class="section callout">${$("hindsight")}</div><div class="section">${btn(state.hindsight?$("hideHands"):$("revealHands"),"table-hindsight","block")}</div>${state.hindsight?`<div class="section surface stack">${[["a",["9♣","9♥"]],["b",["A♦","Q♦"]],["c",["3♣","8♦"]]].map(([id,hand])=>`<div class="card-row"><strong>${seatName(id)}</strong>${cards(hand)}</div>`).join("")}</div>`:""}<div class="section">${btn($("resetHand"),"table-reset","primary block")}</div></section>`;}
function records(){let body;if(state.recordsState==="sample"){body=`<div class="section raised"><h2>${$("todayRecord")}</h2>${labelValue($("attempts"),"5")}${labelValue($("exact"),"3")}${labelValue($("missed"),"2")}${labelValue($("elapsed"),"4.1 s")}</div><section class="section"><h2>${$("weekCompare")}</h2><div class="bars"><div class="barline"><span>${$("lastWeek")}: 3 / 5</span><div class="fill"><span style="width:60%"></span></div></div><div class="barline"><span>${$("thisWeek")}: 9 / 10</span><div class="fill"><span style="width:90%"></span></div></div></div><p class="tiny" style="margin-top:10px">${$("sampleComparison")}</p></section><div class="section callout">${$("timeNote")}</div>`;}else if(state.recordsState==="empty"){body=`<div class="section raised"><h2>${$("emptyTitle")}</h2><p>${$("emptyBody")}</p><div class="section">${btn($("goPractice"),"practice-intro","primary block")}</div></div>`;}else if(state.recordsState==="error"){body=`<div class="section raised" role="alert"><h2>${$("errorTitle")}</h2><p>${$("errorBody")}</p><div class="section">${btn($("retry"),"records-retry","primary block")}</div></div>`;}else{body=`<div class="section raised" role="status"><h2>${$("loading")}</h2><p>${$("loadingBody")}</p></div>`;}return `<section class="page"><p class="eyebrow">${$("preview")} · ${$("navRecords")}</p><h1 class="title">${$("recordsTitle")}</h1><p class="sub">${$("recordsSub")}</p><div class="section callout">${$("fixture")}</div><section class="section"><h2>${$("recordState")}</h2><div class="state-options">${["sample","empty","loading","error"].map(s=>btn($(s),"records-state",state.recordsState===s?"selected":"",`data-value="${s}" aria-pressed="${state.recordsState===s}"`)).join("")}</div></section>${body}<section class="section"><h2>${$("stylesTitle")}</h2><p class="muted">${$("stylesSub")}</p><div class="section">${btn(state.styleState==="sample"?$("styleStateShort"):$("styleStateSample"),"style-toggle","block")}</div>${styles()}</section></section>`;}
function styles(){return state.styleState==="sample"?`<div class="section raised"><p class="eyebrow">${$("styleSample")}</p><h3>${$("styleName")}</h3><p>${$("styleInterpret")}</p><div class="divider"></div>${labelValue($("styleEligible"),"72 / 120")}${labelValue($("styleRaise"),"59 / 72")}<p class="tiny" style="margin-top:12px">${$("styleCaveat")}</p><p style="margin-top:12px"><strong>${$("styleNext")}</strong></p></div><div class="section"><h3>${$("styleTypes")}</h3><div class="style-list">${[0,1,2,3,4].map(i=>btn($(`styleType${i}`),"style-detail",state.styleDetail===i?"selected":"",`data-value="${i}" aria-pressed="${state.styleDetail===i}"`)).join("")}</div><div class="callout" style="margin-top:8px"><strong>${$(`styleType${state.styleDetail}`)}</strong>${$("styleTypeNote")}</div></div>`:`<div class="section raised"><h3>${$("styleInsufficient")}</h3><p>${$("styleInsufficientBody")}</p><div class="divider"></div><p>${$("styleTypeNote")}</p></div>`;}
function settings(){return `<div class="overlay" data-action="settings-backdrop"><section class="sheet" role="dialog" aria-modal="true" aria-label="${$("settings")}"><div class="sheet-head"><h2>${$("settings")}</h2>${btn($("close"),"settings-close")}</div><fieldset><legend>${$("language")}</legend><div class="segment">${[["system",$("system")],["ko","한국어"],["en","English"]].map(([v,l])=>`<button type="button" data-action="language" data-value="${v}" aria-pressed="${state.langOption===v}">${l}</button>`).join("")}</div></fieldset><fieldset><legend>${$("appearance")}</legend><div class="segment">${["system","light","dark"].map(v=>`<button type="button" data-action="theme" data-value="${v}" aria-pressed="${state.theme===v}">${$(v)}</button>`).join("")}</div></fieldset><p class="muted">${$("langNote")}</p></section></div>`;}
function render(){const y=window.scrollY;document.documentElement.lang=state.lang;document.documentElement.dataset.theme=state.theme;let content=state.route==="learn"?learn():state.route==="today"?today():state.route==="chart"?chart():state.route==="opponents"?opponentPicker():state.route==="table"?(state.tableReview?tableReview():table()):state.route==="records"?records():state.practiceStage==="intro"?intro():state.practiceStage==="summary"?practiceSummary():question();document.getElementById("app").innerHTML=`<div class="shell"><header class="topbar" ${state.settings?"inert":""}><span class="brand">Glass Table</span><div class="top-actions"><button type="button" class="icon-button small-text" data-action="settings-open" aria-label="${$("settings")}">${$("settings")}</button></div></header><main id="main" ${state.settings?"inert":""}>${content}</main><nav class="bottomnav" ${state.settings?"inert":""} aria-label="${state.lang==="ko"?"주요 화면":"Main screens"}">${[["learn","♠","navLearn"],["today","◎","navToday"],["opponents","▤","navTable"],["records","▥","navRecords"]].map(([v,mark,label])=>`<button type="button" data-action="nav" data-value="${v}" class="${state.route===v||(v==="opponents"&&state.route==="table")?"active":""}"><span class="navmark" aria-hidden="true">${mark}</span>${$(label)}</button>`).join("")}</nav>${state.settings?settings():""}</div>`;window.scrollTo(0,y);}
function route(to){state.route=to;window.scrollTo(0,0);}
document.addEventListener("click", e=>{
  const target=e.target.closest("[data-action]");
  if(!target)return;
  const a=target.dataset.action,v=target.dataset.value;
  if(a==="settings-backdrop"&&e.target!==target)return;
  switch(a){
    case"settings-open":state.settings=true;break;
    case"settings-close":case"settings-backdrop":state.settings=false;break;
    case"language":state.langOption=v;state.lang=v==="system"?systemLanguage():v;break;
    case"theme":state.theme=v;break;
    case"nav":route(v);break;
    case"learn-open":route("learn");break;
    case"records-open":route("records");break;
    case"chart-open":route("chart");break;
    case"chart-choose":if(!state.chartChoice)state.chartChoice=v;break;
    case"chart-expand":state.chartExpanded=!state.chartExpanded;break;
    case"chart-cell":state.chartCell=v;break;
    case"chart-own":state.chartCell="J5o";break;
    case"chart-reset":state.chartChoice=null;state.chartExpanded=false;state.chartCell="J5o";break;
    case"practice-intro":
      state.introReturnStage=state.practiceStage==="question"||state.practiceStage==="summary"?state.practiceStage:"idle";
      state.practiceStage="intro";route("practice");break;
    case"practice-resume":
      if(state.practiceStage==="intro")state.practiceStage=state.introReturnStage==="idle"?"question":state.introReturnStage;
      route("practice");break;
    case"practice-start":
      state.practiceStage="question";state.introReturnStage="idle";state.q=0;state.answers=[];state.assisted=[];state.answer=null;state.help=false;route("practice");break;
    case"practice-answer":
      if(state.answer===null){state.answer=v;state.answers[state.q]=v;}
      break;
    case"practice-help":state.help=!state.help;if(state.help)state.assisted[state.q]=true;break;
    case"practice-next":
      if(state.q===4){state.practiceStage="summary";}
      else{state.q++;state.answer=null;state.help=false;}
      window.scrollTo(0,0);break;
    case"practice-restart":
      state.practiceStage="question";state.q=0;state.answers=[];state.assisted=[];state.answer=null;state.help=false;window.scrollTo(0,0);break;
    case"opp-select":state.opp=v;break;
    case"opp-details":state.oppDetails=!state.oppDetails;break;
    case"table-start":state.tableIndex=-1;state.tableReview=false;state.hindsight=false;route("table");break;
    case"table-next":state.tableIndex=Math.min(GTModel.tableEvents.length-1,state.tableIndex+1);break;
    case"table-prev":state.tableIndex=Math.max(-1,state.tableIndex-1);break;
    case"table-review":state.tableReview=true;window.scrollTo(0,0);break;
    case"table-hindsight":state.hindsight=!state.hindsight;break;
    case"table-reset":state.tableIndex=-1;state.tableReview=false;state.hindsight=false;window.scrollTo(0,0);break;
    case"records-state":
      state.recordsState=v;
      if(v==="loading")setTimeout(()=>{if(state.recordsState==="loading"){state.recordsState="sample";render();}},650);
      break;
    case"records-retry":state.recordsState="loading";setTimeout(()=>{state.recordsState="sample";render();},650);break;
    case"timing-toggle":state.timing=!state.timing;break;
    case"style-toggle":state.styleState=state.styleState==="sample"?"short":"sample";break;
    case"style-detail":state.styleDetail=Number(v);break;
    default:return;
  }
  render();
  if(a==="settings-open")document.querySelector('[data-action="settings-close"]')?.focus();
  else if(a==="settings-close"||a==="settings-backdrop")document.querySelector('[data-action="settings-open"]')?.focus();
  else if(a==="chart-expand"&&state.chartExpanded){
    document.querySelector('[data-action="chart-cell"][data-value="J5o"]')?.scrollIntoView({block:"center",inline:"center"});
  }else if(a==="chart-own"){
    document.querySelector('[data-action="chart-cell"][data-value="J5o"]')?.scrollIntoView({block:"center",inline:"center"});
  }else{
    const same=[...document.querySelectorAll('[data-action]')].find(el=>el.dataset.action===a&&el.dataset.value===v&&!el.disabled);
    if(same)same.focus({preventScroll:true});
  }
});
document.addEventListener("keydown",e=>{
  if(e.key==="Escape"&&state.settings){
    state.settings=false;render();document.querySelector('[data-action="settings-open"]')?.focus();
  }
  if(e.key==="Tab"&&state.settings){
    const controls=[...document.querySelectorAll('.sheet button:not(:disabled)')];
    const first=controls[0],last=controls[controls.length-1];
    if(e.shiftKey&&document.activeElement===first){e.preventDefault();last.focus();}
    else if(!e.shiftKey&&document.activeElement===last){e.preventDefault();first.focus();}
  }
});
render();
