// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableDrills

struct ReferenceText: Equatable {
    let korean: String
    let english: String

    init(_ korean: String, _ english: String) {
        self.korean = korean; self.english = english
    }

    func text(in language: LearningLanguage) -> String {
        language == .korean ? korean : english
    }
}

/// General definitions only. Looking up a term never receives the current spot or answer.
struct GlossaryEntry: Identifiable, Equatable {
    let id: String
    let name: ReferenceText
    let meaning: ReferenceText
    let aliases: [String]
}

enum GlossaryCatalog {
    private static func entry(_ id: String, _ korean: String, _ english: String,
                              _ koreanMeaning: String, _ englishMeaning: String,
                              aliases: [String] = []) -> GlossaryEntry {
        GlossaryEntry(id: id, name: ReferenceText(korean, english),
                      meaning: ReferenceText(koreanMeaning, englishMeaning), aliases: aliases)
    }

    static let entries: [GlossaryEntry] = [
        entry("chip", "칩", "Chip",
              "테이블에서 내고 가져오는 연습 단위예요. 앱의 칩은 현금 가치가 없어요. 자유 플레이와 팟 세기에서는 작은 블라인드가 1칩, 큰 블라인드가 2칩이에요.",
              "The practice units put into and won from the pot. App chips have no cash value. Free play and the pot-counting exercise use 1-chip and 2-chip blinds.", aliases: ["chips", "팟 세기", "pot math"]),
        entry("pot", "팟", "Pot",
              "가운데 모인 칩이에요. 폴드해도 이미 낸 칩은 팟에 남아요. 마지막에 이긴 사람이 가져가고, 같은 최선의 다섯 장이면 나눠 가져요.",
              "The chips in the middle. Chips already paid stay there even if you fold. The winner takes the pot; equal best five-card hands split it."),
        entry("blinds", "블라인드", "Blinds",
              "카드를 받기 전에 정해진 두 자리가 먼저 내는 칩이에요. SB는 작은 블라인드, BB는 큰 블라인드예요. 둘만 남으면 버튼이 SB이고, 공용 카드 전에는 먼저 행동해요.",
              "Forced chips posted before the deal: SB is small blind and BB is big blind. Heads-up, the button posts SB and acts first before the flop.", aliases: ["blind", "SB", "small blind", "스몰 블라인드", "빅 블라인드"]),
        entry("big-blind", "bb · 빅 블라인드 단위", "bb · Big-blind unit",
              "큰 블라인드 한 번의 크기가 1bb예요. 스택과 팟을 블라인드 크기에 맞춰 비교하는 단위예요. 1/2칩 블라인드에서 1bb는 2칩이에요.",
              "One bb equals one big blind. It expresses stacks and pots relative to the blind size. With 1/2-chip blinds, 1bb is 2 chips.", aliases: ["bb", "BB", "big blind", "big-blind"]),
        entry("dealer-button", "딜러 버튼", "Dealer button",
              "D 또는 BTN 표시예요. 핸드마다 한 자리씩 옮겨 가며 블라인드와 행동 순서의 기준이 돼요.",
              "The D or BTN marker. It moves one seat each hand and sets the blinds and action order.", aliases: ["D", "BTN", "button", "버튼"]),
        entry("position", "포지션", "Position",
              "버튼을 기준으로 한 자리예요. 앱의 8인 자리 연습에서 UTG는 앞자리, UTG+1은 그다음 앞자리예요. LJ(lojack)와 HJ(하이잭)는 중간 자리, CO는 버튼 바로 앞자리, BTN은 버튼, SB·BB는 블라인드예요. 공용 카드 뒤에는 남은 사람 중 버튼 왼쪽부터 행동해요.",
              "Your seat relative to the button. In the app's eight-seat position exercise, UTG is an early seat and UTG+1 is the next early seat. LJ (lojack) and HJ (hijack) are middle seats, CO is cutoff, BTN is button, and SB/BB are the blinds. After the flop, remaining players act from the button's left.", aliases: ["UTG", "UTG+1", "UTG1", "under-the-gun+1", "LJ", "lojack", "HJ", "CO", "cutoff", "hijack", "under the gun", "자리"]),
        entry("hand", "핸드 · 패", "Hand",
              "문맥에 따라 한 판이나 내가 가진 패를 뜻해요. 홀덤에서는 내 카드 두 장과 공용 카드 다섯 장 중 가장 좋은 다섯 장을 비교해요. 내 카드를 꼭 써야 하는 것은 아니에요.",
              "A hand can mean one deal or a player's cards. Hold'em compares the best five of two private cards and five shared cards. You may use both, one, or neither private card."),
        entry("board", "보드 · 공용 카드", "Board · Shared cards",
              "모두가 함께 쓰는 카드예요. 플랍에 세 장, 턴에 한 장, 리버에 한 장이 더 나와요.",
              "Cards shared by everyone: three on the flop, one more on the turn, and one more on the river.", aliases: ["공용 카드", "shared cards", "community cards"]),
        entry("suits", "무늬 · 스페이드 · 하트 · 다이아몬드 · 클럽", "Suits · Spades · Hearts · Diamonds · Clubs",
              "♠는 스페이드, ♥는 하트, ♦는 다이아몬드, ♣는 클럽이에요. 같은 무늬 다섯 장은 플러시를 만들 수 있어요. 홀덤에서 무늬 사이에 높고 낮음은 없으므로 같은 최선의 다섯 장이면 무승부예요.",
              "♠ is spades, ♥ hearts, ♦ diamonds, and ♣ clubs. Five cards of one suit can make a flush. Hold'em does not rank suits, so equally strong best five-card hands tie.", aliases: ["suit", "무늬", "스페이드", "하트", "다이아몬드", "다이아", "클럽", "spade", "spades", "heart", "hearts", "diamond", "diamonds", "club", "clubs"]),
        entry("showdown", "쇼다운", "Showdown",
              "마지막까지 남은 사람들이 패를 공개해 가장 좋은 다섯 장을 비교하는 순간이에요. 다른 사람이 모두 폴드하면 공개 비교 없이 핸드가 끝나요.",
              "When remaining players reveal their cards and compare their best five. A hand can also end without showdown when everyone else folds."),
        entry("hand-rank", "족보", "Hand ranking",
              "패의 종류를 강한 순서로 비교하는 기준이에요. 스트레이트 플러시, 포카드, 풀 하우스, 플러시, 스트레이트, 트리플, 투 페어, 원 페어, 하이 카드 순이에요. 로열 플러시는 가장 높은 스트레이트 플러시예요.",
              "Hand types from strongest to weakest: straight flush, four of a kind, full house, flush, straight, three of a kind, two pair, one pair, high card. A royal flush is the highest straight flush.", aliases: ["원 페어", "투 페어", "트리플", "스트레이트", "플러시", "풀 하우스", "포카드", "하이 카드", "pair", "two pair", "trips", "straight", "flush", "full house", "four of a kind", "high card", "로열 플러시"]),
        entry("kicker", "키커", "Kicker",
              "같은 족보를 비교할 때 승부를 가르는 나머지 카드예요. 같은 페어라면 페어 밖의 높은 카드부터 비교해요. 가장 좋은 다섯 장에 든 카드만 세요. 투 페어의 두 번째 페어나 풀 하우스의 페어를 키커라고 하지는 않아요.",
              "A remaining card that breaks a tie within the same hand type. With the same pair, compare the highest card outside the pair first. Only the best five count. A second pair or a full house's pair is not a kicker."),
        entry("tie", "무승부", "Tie · Chop",
              "가장 좋은 다섯 장의 강함이 같으면 팟을 나눠 가져요. 무늬의 우열로 승부를 가르지 않아요.",
              "Equally strong best five-card hands split the pot. Suits do not break ties.", aliases: ["chop", "split pot", "스플릿 팟"]),
        entry("stack", "스택", "Stack",
              "한 사람이 아직 팟에 넣지 않고 가진 칩이에요. 유효 스택은 서로 겨룰 수 있는 스택의 한도예요.",
              "The chips a player still has outside the pot. Effective stack is the amount the players can contest against each other.", aliases: ["effective stack", "유효 스택"]),
        entry("check", "체크", "Check",
              "이번에 더 맞출 금액이 없을 때 칩을 내지 않고 순서를 넘겨요. 이미 누군가 벳해서 맞출 금액이 있으면 체크할 수 없어요.",
              "Pass without paying when nothing is owed. You cannot check while facing an unmatched bet."),
        entry("bet", "벳", "Bet",
              "이번 라운드에서 먼저 칩을 거는 행동이에요. 이미 벳이 있으면 더 높이는 행동은 레이즈예요.",
              "Put in the first wager of a betting round. Increasing an existing bet is a raise.", aliases: ["베팅", "betting"]),
        entry("call", "콜", "Call",
              "현재 맞춰야 할 금액만큼 칩을 더 내요. 이미 그 라운드에 낸 칩은 다시 내지 않아요. 스택이 모자라면 남은 칩까지만 낼 수 있어요.",
              "Pay the amount needed to match the current bet, counting chips already paid this round. If your stack is short, you can pay only what remains."),
        entry("raise", "레이즈", "Raise",
              "기존 벳보다 더 높여요. ‘레이즈 총액’과 ‘지금 더 내는 칩’은 이미 낸 금액 때문에 다를 수 있어요.",
              "Increase an existing bet. A raise-to total and the chips you add now can differ because you may already have chips in this round."),
        entry("fold", "폴드", "Fold",
              "이번 핸드의 팟을 이길 기회를 포기해요. 이미 낸 칩은 돌아오지 않아요.",
              "Give up your claim to the pot for this hand. Chips already paid are not returned."),
        entry("all-in", "올인", "All-in",
              "남은 스택을 모두 내요. 올인한 사람도 낸 금액으로 겨룰 수 있는 팟에는 남아요. 추가 칩은 별도 사이드 팟이 될 수 있어요.",
              "Put in your remaining stack. You remain eligible for the pot your contribution covers; extra chips can form a side pot.", aliases: ["allin"]),
        entry("side-pot", "사이드 팟", "Side pot",
              "스택이 짧은 사람이 올인한 뒤 다른 사람들이 더 낸 칩을 따로 모은 팟이에요. 그 팟에 참여한 사람끼리만 겨뤄요.",
              "A separate pot for extra contributions beyond a short all-in. Only players eligible for that pot can win it."),
        entry("three-bet", "3벳", "3-bet",
              "레이즈에 다시 레이즈하는 행동이에요. 프리플랍에서는 큰 블라인드를 첫 벳, 오픈 레이즈를 두 번째로 세어 다시 올리기를 3벳이라고 해요. 공용 카드 뒤에도 3벳이라는 말을 써요.",
              "A re-raise. Preflop, the big blind is counted as the first bet, the opening raise as the second, and the re-raise as the third. The term also exists after the flop.", aliases: ["3bet", "three bet", "다시 올리기", "쓰리벳"]),
        entry("four-bet", "4벳", "4-bet",
              "3벳에 다시 레이즈하는 행동이에요. 1:1 채점 테이블의 단순화된 프리플랍 모델은 4벳을 허용하지 않아요.",
              "A re-raise over a 3-bet. The graded heads-up table's simplified preflop model does not allow 4-bets.", aliases: ["4bet", "four bet"]),
        entry("streets", "스트리트 · 베팅 라운드", "Street · Betting round",
              "프리플랍, 플랍, 턴, 리버를 각각 스트리트라고 해요. 각 라운드의 칩을 맞추면 다음 공용 카드로 넘어가요.",
              "Preflop, flop, turn, and river are betting rounds called streets. Once the round settles, play moves to the next shared cards.", aliases: ["프리플랍 · 플랍 · 턴 · 리버", "Preflop · Flop · Turn · River", "street", "포스트플랍", "postflop"]),
        entry("preflop", "프리플랍", "Preflop", "공용 카드가 나오기 전의 베팅 라운드예요.", "The betting round before any shared cards are dealt."),
        entry("flop", "플랍", "Flop", "처음 나온 공용 카드 세 장과 그 뒤의 베팅 라운드예요.", "The first three shared cards and the betting round that follows.", aliases: ["플롭"]),
        entry("turn", "턴", "Turn", "네 번째 공용 카드와 그 뒤의 베팅 라운드예요.", "The fourth shared card and the betting round that follows."),
        entry("river", "리버", "River", "마지막인 다섯 번째 공용 카드와 그 뒤의 베팅 라운드예요.", "The fifth and final shared card and the betting round that follows."),
        entry("range", "레인지", "Range",
              "한 사람이 가질 수 있는 패의 묶음이에요. 카드나 행동을 보고 가능한 패를 줄여 생각할 수 있어요. 앱의 레인지는 공개된 연습 모델이며 실제 상대의 패를 아는 것은 아니에요.",
              "A set of possible hands. Known cards and actions can narrow it. App ranges are published practice models, not knowledge of a real opponent's cards."),
        entry("combo", "콤보", "Combo",
              "무늬까지 정해진 실제 카드 두 장의 조합이에요. 알려진 카드를 빼기 전에는 한 페어에 6콤보, 같은 무늬 조합에 4콤보, 다른 무늬 조합에 12콤보가 있어요.",
              "One specific two-card holding, including suits. Before removing known cards, a pair has 6 combos, a suited hand 4, and an offsuit hand 12.", aliases: ["combos", "combinations", "카드 조합"]),
        entry("range-notation", "레인지 표기", "Range notation",
              "A·K·Q·J·T는 카드 숫자, s는 같은 무늬, o는 다른 무늬예요. AK는 두 무늬 종류를 모두 포함해요. 99+처럼 +는 같은 종류에서 더 높은 패까지 포함해요. 차트의 각 칸은 시작 패 한 종류예요.",
              "A/K/Q/J/T name ranks; s means suited and o means offsuit. AK includes both. A plus such as 99+ includes higher hands of that type. Each chart cell is one starting-hand class.", aliases: ["notation", "suited", "offsuit", "수티드", "오프수트", "AKs", "AKo", "169"]),
        entry("chen-score", "시작 패 점수 (Chen)", "Starting-hand score (Chen)",
              "빌 첸(Bill Chen)의 어림 규칙으로 시작 패 169종류를 줄 세우는 점수예요. 앱의 차트가 이 순서를 써요. 이길 확률이나 수익을 뜻하지 않아요.",
              "A Bill Chen rule-of-thumb score that orders the 169 starting-hand classes. App charts use this order. It is not a win probability or a profit estimate.", aliases: ["Chen", "Chen score", "첸", "첸 점수"]),
        entry("rfi", "RFI · 먼저 레이즈하기", "RFI · Raise first in",
              "앞사람이 모두 폴드한 뒤 내가 처음 레이즈로 참여하는 상황이에요. 앱의 RFI 차트는 자리별 시작 패 기준이며 모든 게임의 정답은 아니에요.",
              "Open the pot with a raise after everyone before you folds. The app's RFI chart is a position-based starting-hand baseline, not an answer for every game.", aliases: ["raise first in", "open raise", "오픈", "오픈 레이즈"]),
        entry("defend-chart", "디펜드 차트", "Defend chart",
              "상대가 먼저 레이즈했을 때 콜·3벳·폴드를 비교하는 앱의 기준이에요. 상대의 오픈 폭과 Chen 순서를 사용하고 내 자리에 따른 차이는 단순화해요. 차트 일치는 EV 이득의 증명이 아니에요.",
              "The app's call/3-bet/fold baseline against an opening raise. It uses opening width and Chen ordering and simplifies hero-position differences. Matching it does not prove an EV profit.", aliases: ["defend", "디펜드", "시작 패 차트", "starting-hand chart"]),
        entry("equity", "에퀴티", "Equity",
              "남은 카드의 가능한 결과를 통틀어 평균적으로 가져가는 팟의 몫이에요. 이긴 결과뿐 아니라 무승부에서 나눠 받는 몫도 포함하므로 단순한 단독 승리 확률과 달라요.",
              "Your average share of the pot across possible remaining cards, including your share of ties. It is not just the probability of winning outright.", aliases: ["equity sense", "팟의 몫"]),
        entry("pot-odds", "팟 오즈", "Pot odds",
              "콜 가격과 콜 뒤의 전체 팟을 비교해요. 지금 팟에는 상대가 방금 낸 벳도 들어 있어요. 추가 베팅과 수수료가 없는 단순 모델에서 필요 에퀴티 이상이면 콜이 폴드보다 손해가 아니에요.",
              "Compare the call price with the final pot after calling. The current pot already includes the opponent's bet. With no later bets or rake, equity at least as high as the required share makes calling no worse than folding.", aliases: ["potodds", "콜 가격"]),
        entry("required-equity", "필요 에퀴티", "Required equity",
              "콜 금액 ÷ (상대 벳을 포함한 지금 팟 + 내 콜 금액)이에요. 추가 베팅과 수수료가 없는 모델에서 에퀴티가 이 비율과 같으면 본전이에요. 상대 벳을 두 번 더하지 않도록 팟의 시점을 확인해요.",
              "Call amount ÷ (current pot including the opponent's bet + your call). With no later bets or rake, equality breaks even. Check which pot is shown so the opponent's bet is not counted twice.", aliases: ["break-even equity", "필요 승률", "needed share", "call or fold", "콜 아니면 폴드"]),
        entry("ev", "EV · 기댓값", "EV · Expected value",
              "같은 조건의 결정을 여러 번 반복했을 때의 평균 칩 변화예요. 앱은 지금부터 더 내고 받는 칩을 비교해요. 이미 팟에 낸 칩은 매몰 비용이므로 폴드의 EV는 0으로 놓아요. 한 번의 승패와는 달라요.",
              "The average chip change from repeating a decision under the same conditions. The app compares future chips paid and received; chips already in the pot are sunk, so folding is worth 0 from here. One hand's result can differ.", aliases: ["expected value", "기댓값", "기대값"]),
        entry("ev-loss", "EV 손실", "EV loss",
              "모델의 가장 높은 EV에서 고른 행동의 EV를 뺀 값이에요. 0bb는 최선, 0보다 크고 0.5bb 이하면 거의 최선, 2bb 이하면 부정확, 그보다 크면 실수예요. 최선만 정답으로 세고 거의 최선도 근접으로 세요.",
              "Best model EV minus chosen EV. Zero bb is Best choice; a positive loss up to 0.5bb is Near best; up to 2bb is Could improve; above 2bb is Costly choice. Only zero loss counts as correct; Near best counts as a near miss.", aliases: ["EV손실", "best choice", "near best", "최선", "거의 최선", "부정확", "실수"]),
        entry("checkdown", "체크다운 가정", "Checkdown assumption",
              "1:1 채점 테이블은 현재 라운드의 행동이 정리된 뒤 남은 카드에서 더 베팅하지 않는다고 가정해 EV를 비교해요. 리버에는 남은 카드가 없어요. 실제 여러 라운드 전략이나 GTO 해답은 아니에요.",
              "The graded heads-up table prices choices assuming no more betting after the current street settles. On the river there are no cards left. This is not a full multi-street strategy or a GTO solution.", aliases: ["check-down", "추가 베팅 없음"]),
        entry("outs", "아웃", "Outs",
              "보통 패를 완성하는 데 도움이 되는 남은 카드를 말해요. 이 앱의 연습은 더 엄격해요. 턴에서 상대 패를 공개하고, 다음 리버 한 장으로 내 최선의 다섯 장이 상대를 확실히 이기는 카드만 세요. 무승부와 여전히 지는 카드는 빼요.",
              "Usually cards that can complete a draw. This app's exercise is stricter: on the turn, with the opponent's hand shown, count only river cards that make your best five win outright. Ties and cards that still lose do not count.", aliases: ["out", "아웃 카운팅"]),
        entry("draw", "드로우", "Draw",
              "남은 카드로 스트레이트나 플러시 같은 패를 완성할 가능성이 있는 상태예요. 완성돼도 상대에게 질 수 있으니 아웃과 승리 가능성은 따로 확인해요.",
              "A hand that may complete something such as a straight or flush with later cards. Completing it can still lose, so distinguish a hit from a winning out.", aliases: ["flush draw", "straight draw", "플러시 드로우", "스트레이트 드로우", "gutshot", "거샷", "open ended", "OESD"]),
        entry("rule-of-2-4", "룰 오브 2/4", "Rule of 2/4",
              "아웃 수에 카드 한 장이 남으면 약 2%, 두 장이면 약 4%를 곱해 맞힐 확률을 어림해요. 정확한 에퀴티가 아니며, 맞히면 이기고 못 맞히면 진다는 가정도 실제와 다를 수 있어요.",
              "Estimate a hit by multiplying outs by about 2% with one card to come or 4% with two. This is not exact equity; the assumption that every hit wins and every miss loses may be wrong.", aliases: ["rule of 2 and 4", "2/4", "2 4 rule"]),
        entry("blocker", "블로커", "Blocker",
              "알려진 카드가 특정 패의 가능한 콤보를 줄이는 효과예요. 내 카드뿐 아니라 공용 카드도 가능한 조합에서 빼야 해요.",
              "A known card that removes possible combinations of a hand. Both your cards and shared cards must be removed from possible holdings."),
        entry("mdf", "MDF · 최소 방어 빈도", "MDF · Minimum defense frequency",
              "상대 벳 전의 팟 ÷ (그 팟 + 상대 벳)으로 구하는 레인지 전체의 이상적인 계속하기 비율이에요. 상대 블러프의 에퀴티가 0이라는 단순 가정에서 자동 이익을 막는 기준이에요. 내 특정 패의 정답이나 모든 상대에게 맞는 빈도는 아니에요.",
              "Pot before the opponent's bet ÷ (that pot + opponent bet): an idealized continuing frequency for your whole range, preventing automatic profit for a zero-equity bluff. It is not an answer for one hand or a frequency to use against every opponent.", aliases: ["minimum defense frequency", "최소 방어 빈도"]),
        entry("vpip", "VPIP · 자발적 참여 비율", "VPIP · Voluntarily put money in pot",
              "프리플랍에서 스스로 칩을 더 낸 핸드의 비율이에요. 강제로 내는 블라인드만 낸 핸드는 세지 않아요. 앱의 상대 정보에서는 관측 통계가 아니라 미리 정해 둔 연습 성향이에요.",
              "The share of hands with a voluntary preflop chip investment; forced blind posts alone do not count. In this app's opponent information it is an authored practice tendency, not an observed statistic.", aliases: ["voluntarily put in pot", "voluntarily put money in pot"]),
        entry("pfr", "PFR · 프리플랍 레이즈 비율", "PFR · Preflop raise",
              "프리플랍에서 레이즈한 핸드의 비율이에요. 앱에서는 미리 정한 상대 모델의 값이에요. VPIP와의 차이는 이 모델의 콜 진입 부분을 보여 주며 상대의 전체 실력 순위는 아니에요.",
              "The share of hands raised preflop. Here it is a fixed opponent-model input. The VPIP gap describes non-raising entries in this model, not an overall skill ranking.", aliases: ["preflop raise"]),
        entry("archetype", "상대 스타일", "Opponent style",
              "신중형·선별형·공격형·콜 위주형·매우 공격형은 공개 규칙을 따르는 연습 상대예요. Nit·TAG·LAG·Calling Station·Maniac이라는 용어와 연결돼요. 자유 플레이의 캐주얼형은 별도 봇 스타일이며 실력 순서가 아니에요.",
              "Cautious, Selective, Aggressive, Caller and Very aggressive are practice opponents with published rules, related to Nit, TAG, LAG, Calling Station and Maniac. Casual in free play is a separate bot style. These are not skill rankings.", aliases: ["Nit", "TAG", "LAG", "Calling Station", "Maniac", "Casual", "캐주얼형", "신중형", "선별형", "공격형", "콜 위주형", "매우 공격형"]),
        entry("gto", "GTO · 게임 이론 최적 전략", "GTO · Game theory optimal",
              "상대가 대응 방식을 바꿔도 일방적으로 이용당하지 않는 균형 전략을 뜻해요. 이 앱의 공개 차트와 단순 모델을 GTO 해답으로 보지는 않아요.",
              "An equilibrium strategy that cannot be exploited by an opponent changing their response. The app's published charts and simplified models are not GTO solutions.", aliases: ["game theory optimal", "균형 전략"]),
        entry("hit-frequency", "레인지 적중 빈도", "Range hit frequency",
              "정해진 레인지가 현재 보드에서 노페어·드로우·페어 같은 패 종류를 얼마나 자주 만드는지 보는 연습이에요. 특정 한 패의 에퀴티와는 달라요.",
              "How often a declared range makes categories such as no pair, a draw, or a pair on the current board. This differs from one hand's equity.", aliases: ["hit frequency", "레인지 적중률"]),
        entry("action-read", "행동으로 레인지 좁히기", "Action read",
              "공개된 상대 정책에서 관찰한 행동을 할 수 있는 패들만 남겨 생각하는 연습이에요. 콤보 수와 전체 레인지에서의 비율을 구분해요. 실제 상대의 속마음을 알아내는 기능은 아니에요.",
              "Use an observed action and the published opponent policy to keep only hands that can take it. Distinguish combo counts from shares of the whole range. This does not read a real opponent's intentions.", aliases: ["action read", "행동 읽기", "레인지 좁히기"]),
        entry("range-advantage", "레인지 어드밴티지", "Range advantage",
              "현재 보드에서 두 레인지 중 어느 쪽이 평균적으로 유리한지 비교해요. 앱은 정해진 두 레인지의 에퀴티와 패 종류 분포를 봐요. 수치는 표본 계산일 수 있고, 가장 강한 패를 많이 가진 쪽과 항상 같지는 않아요.",
              "Compare two ranges' average strength on a board. The app uses their equity and hand-category distributions, sometimes by sampling. Average equity advantage is not always the same as having more of the very strongest hands.", aliases: ["range advantage", "레인지 우위", "nut advantage", "넛 어드밴티지"]),
        entry("grade-bands", "정확 · 근접 · 다시 살펴볼까요?", "Spot-on · Close · Review",
              "문제별 채점 기준을 표시해요. 선택·정확한 수 세기와 어림 문제는 기준이 달라요. 근접은 정확한 정답으로 세지 않아요. EV 문제는 별도의 최선·거의 최선·부정확·실수 표시도 함께 확인해요.",
              "Feedback bands use the rule for each exercise: exact choices/counts differ from estimates. Close does not count as exactly correct. EV exercises also show Best choice, Near best, Could improve, or Costly choice.", aliases: ["grade bands", "spot-on", "close", "review", "정확", "근접", "다시 살펴볼까요?"]),
        entry("calibration", "추정 감각 · 캘리브레이션", "Calibration",
              "어림한 값과 자신 있게 잡은 범위가 실제 결과와 얼마나 잘 맞는지 살펴봐요. 90% 구간은 여러 문제에서 실제 값이 약 90% 들어가도록 잡는 범위예요. 아웃·콤보 같은 정확한 수 세기는 구간 추정 기록이 아니에요.",
              "How well your estimates and uncertainty ranges match the truth. A 90% interval aims to contain the true value about 90% of the time across many questions. Exact outs or combo counts are not interval-estimation evidence.", aliases: ["90%", "interval", "90% 구간", "신뢰 구간", "Winkler"]),
        entry("review", "복습 · 간격 반복", "Review · Spaced repetition",
              "학습한 내용을 시간이 지난 뒤 다시 떠올리는 연습이에요. 앱은 답한 기록으로 다음 복습 시점을 계산해요. 복습에 쓸 FSRS는 일정 계산 방식의 이름이에요.",
              "Recall something studied after time has passed. The app uses recorded answers to schedule its next review. FSRS is the name of the scheduling method.", aliases: ["spaced repetition", "FSRS", "복습 일정"]),
        entry("mastery", "막 시작 · 익히는 중 · 능숙 · 숙달", "Just started · Getting familiar · Strong in app · Mastered in app",
              "기술별로 쌓은 학습 기록의 단계예요. 레슨 통과와는 별개이며, 도움 없이 푼 성과와 도전 결과로 올라가요. 나중에 틀려도 이미 얻은 단계는 내려가지 않아요. 정확한 조건은 공부 방법에서 볼 수 있어요.",
              "Stages of recorded evidence for a skill, separate from passing a lesson. Independent performance and challenges raise them; later misses do not take an earned stage away. How learning works explains the criteria.", aliases: ["숙달", "능숙", "익숙", "시도", "Strong", "Mastered", "Familiar", "Tried", "막 시작", "익히는 중", "Just started", "Getting familiar"]),
    ]

    private static func normalized(_ value: String) -> String {
        let folded = value.folding(options: [.caseInsensitive, .diacriticInsensitive],
                                   locale: Locale(identifier: "en_US_POSIX"))
        return String(String.UnicodeScalarView(folded.unicodeScalars.filter(CharacterSet.alphanumerics.contains)))
    }

    private static func names(of entry: GlossaryEntry) -> [String] {
        [entry.id, entry.name.korean, entry.name.english] + entry.aliases
    }

    static func entry(for term: String) -> GlossaryEntry? {
        // Prefer stable IDs, then exact bilingual names, then aliases.
        if let exact = entries.first(where: { $0.id == term }) { return exact }
        let key = normalized(term)
        guard !key.isEmpty else { return nil }
        return entries.first { normalized($0.id) == key }
            ?? entries.first { normalized($0.name.korean) == key || normalized($0.name.english) == key }
            ?? entries.first { $0.aliases.contains { normalized($0) == key } }
    }

    static func search(_ query: String) -> [GlossaryEntry] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return entries }
        let key = normalized(query)
        guard !key.isEmpty else { return [] }
        return entries.filter { names(of: $0).contains { normalized($0).contains(key) } }
    }
}

struct LearningGuideTopic: Identifiable {
    let id: String
    let title: ReferenceText
    let paragraphs: [ReferenceText]
    let termIDs: [String]
}

enum LearningGuideContent {
    static let topics: [LearningGuideTopic] = [
        LearningGuideTopic(id: "lessons", title: ReferenceText("풀이를 보고, 직접 풀어요", "Watch, then try it yourself"), paragraphs: [
            ReferenceText("첫 레슨에서는 풀이 예시를 본 뒤 다른 카드로 따라 풀어요. 이어지는 혼자 풀기에서는 먼저 답을 고르고 나서 정답과 이유를 확인해요. 이미 익힌 기술의 다음 단계는 풀이 소개를 건너뛰어요.", "A first-step lesson shows a worked example, then a different guided spot. In solo questions, commit your answer before seeing the result and reason. Later steps skip the introductory walkthrough."),
            ReferenceText("카드와 조건을 보고 생각해 보세요. 홀덤은 내 카드와 공용 카드 중 최선의 다섯 장으로 겨루는 게임이에요. 용어집에는 모르는 단어의 뜻과 기본 규칙이 정리돼 있어요.", "Read the cards and conditions before choosing. Hold'em compares the best five from private and shared cards. The glossary explains unfamiliar terms and basic rules.")
        ], termIDs: ["hand", "showdown"]),
        LearningGuideTopic(id: "steps", title: ReferenceText("단계는 자동으로 이어져요", "Steps follow automatically"), paragraphs: [
            ReferenceText("추천은 기초, 시작 패, 상대 읽기, 가격과 확률의 네 흐름을 따라가요. 각 흐름의 1단계 레슨, 가능한 2단계 레슨, 도전을 지난 뒤 다음 흐름으로 가요. 네 흐름 뒤에는 3단계 레슨과 도전이 이어져요. 단계마다 별도로 통과 기록이 남아요.", "Suggestions follow four tracks: basics, starting hands, reading opponents, and price and chance. Each track runs first-step lessons, available second steps, then its challenge. After all four tracks come third-step lessons and challenges. Each step has its own pass record."),
            ReferenceText("난이도를 고르는 설정은 없어요. 단계가 오르면 카드나 조건이 더 다양해지고 어떤 수 세기는 직접 입력해요. ‘더 깊이’는 선택 학습이에요. 레슨 목록에서 다른 내용을 먼저 볼 수도 있어요.", "There is no difficulty setting. Later steps vary cards and conditions; some exact counts become typed answers. Go deeper is optional. You can also open another lesson from the lesson list.")
        ], termIDs: ["position", "range"]),
        LearningGuideTopic(id: "passing", title: ReferenceText("통과는 혼자 맞힌 답으로 정해요", "Passing uses exact answers on your own"), paragraphs: [
            ReferenceText("레슨과 도전은 전체 문제의 2/3 이상을 도움 없이 정확히 맞히면 통과해요. 필요한 수는 올림해요. \(PassMark.required(questions: 3))/3문제, \(PassMark.required(questions: 5))/5문제가 기준이에요. ‘근접’은 정확한 정답에 포함되지 않아요.", "Pass a lesson or challenge by answering at least two thirds exactly right without calculation help, rounding up. That means \(PassMark.required(questions: 3)) of 3 or \(PassMark.required(questions: 5)) of 5. Close does not count as exactly correct."),
            ReferenceText("통과하지 못하면 새 카드로 다시 풀거나 풀이를 보고, 일단 넘어갈 수 있어요. 넘어가도 통과로 바뀌지는 않아요. 한 번 통과한 기록은 나중에 틀려도 남아요.", "If you do not pass, retry with new cards, read the explanation, or go on anyway. Going on does not grant a pass. An earned pass remains even after later misses.")
        ], termIDs: ["grade-bands"]),
        LearningGuideTopic(id: "help", title: ReferenceText("찾아보는 것도 스스로 배우는 과정이에요", "Looking things up is learning"), paragraphs: [
            ReferenceText("용어집과 기술 설명에서 뜻과 공식, 기본 규칙을 찾아보며 이해해 보세요. 이렇게 배운 내용을 적용해 푼 답도 스스로 푼 답으로 기록해요. 정답을 고르기 전에도 자유롭게 찾아볼 수 있어요. 닫으면 같은 문제와 입력한 답, 공개된 해설로 돌아와요.", "Use the glossary and general skill explanations to understand terms, formulas, and rules. Answers you work out by applying these references still count as your own. You can look things up before choosing an answer. Closing a reference returns to the same question, draft, or revealed explanation."),
            ReferenceText("현재 문제의 계산을 보여 주는 힌트나 어떤 선택을 해야 할지 안내하는 코칭을 쓰면 그 문제는 도움받은 연습으로 남아요. 공부한 결정에는 포함되지만 통과를 위한 정답, 정확도, 복습 일정이나 능숙·숙달 승급에는 쓰지 않아요.", "A hint that works out the current question, or coaching that advises which choice to make, marks that question as assisted practice. It counts toward Decisions studied, but not a correct answer toward passing, accuracy, review scheduling, or Strong/Mastered promotion."),
            ReferenceText("따라 풀기와 풀이 예시는 함께 배우는 과정이에요. 혼자 푼 정답으로 세지는 않지만, 개념을 이해하고 다음 문제에 적용하는 데 활용해 보세요.", "Guided spots and worked examples let you learn together. They are not independent correct answers; use them to understand the idea and apply it to the next question.")
        ], termIDs: ["combo", "outs"]),
        LearningGuideTopic(id: "challenges-review", title: ReferenceText("도전은 섞고, 복습은 다시 떠올려요", "Challenges mix; reviews bring ideas back"), paragraphs: [
            ReferenceText("도전은 같은 흐름의 여러 기술을 섞어 풀어요. 레슨처럼 정해진 통과 기준을 쓰며, 통과한 도전이 다루는 레슨은 추천에서 건너뛸 수 있어요. 능숙한 기술을 숙달로 올리는 데도 도전의 성과가 필요해요.", "A challenge mixes skills from its track and uses the same pass rule. Passing can skip covered lessons in suggestions. Challenge evidence is also required to move a Strong skill to Mastered."),
            ReferenceText("복습은 학습한 기술 중 예정일이 지난 것부터 최대 \(ReviewQueue.sessionLimit)개를 골라 한 문제씩 내요. 답한 기록을 바탕으로 FSRS가 다음 날짜를 정해요. 연습과 복습은 이미 통과한 가장 높은 단계의 문제를 내요. 도움받은 답은 복습 일정을 바꾸지 않아요.", "A review picks up to \(ReviewQueue.sessionLimit) overdue studied skills and asks one question for each. FSRS schedules the next date from recorded answers. Practice and review use the highest lesson step already passed. Assisted answers do not change the review schedule.")
        ], termIDs: ["review", "mastery"]),
        LearningGuideTopic(id: "progress", title: ReferenceText("통과와 기술 단계는 다른 기록이에요", "Passing and skill stages are separate"), paragraphs: [
            ReferenceText("기록의 ‘공부한 결정’은 도움받은 답도 포함해요. 1:1 채점 선택도 여기에 더해지지만, 자유 플레이의 핸드 수와는 달라요. 정확도는 도움 없이 정확히 맞힌 답을 보고, 기술 단계는 막 시작·익히는 중·능숙·숙달로 올라가요.", "Decisions studied includes assisted answers and graded heads-up choices. It is not a count of free-play hands. Accuracy tracks independent exact answers; stages are Just started, Getting familiar, Strong in app, and Mastered in app."),
            ReferenceText("익히는 중은 누적 정확도 70% 이상이 기준이에요. 능숙은 이 정확도 기준을 충족한 상태에서 2단계 이상인 해당 기술을 혼자 모두 맞힌 세션이 필요해요. 1단계만 있는 기술은 1단계가 기준이에요. 숙달은 이미 능숙인 기술의 최고 단계 도전에서 그 기술의 문제를 혼자 모두 맞히고, 능숙해진 뒤 적어도 12시간이 지나야 해요. 얻은 기술 단계는 내려가지 않아요.", "Getting familiar needs at least 70% lifetime accuracy. With that accuracy condition met, Strong needs a perfect independent session at Step 2 or above, or Step 1 for a skill with only that step. Mastered needs prior Strong, all questions for that skill answered correctly on your own in a challenge at its highest step, and at least 12 hours since Strong. Earned stages do not go down."),
            ReferenceText("이 단계는 앱에서 쌓은 학습 기록이지 실력 인증은 아니에요. 진행은 이 기기에 저장해요. 저장 실패 안내가 뜨면 앱을 닫기 전에 다시 저장하거나 설정에서 백업을 만들어 주세요.", "These stages describe learning recorded in the app, not a skill certification. Progress is saved on this device. If a save fails, retry or export a backup in Settings before closing the app.")
        ], termIDs: ["mastery", "grade-bands"]),
        LearningGuideTopic(id: "tables", title: ReferenceText("자유 플레이와 채점 연습을 구분해요", "Free play and graded practice differ"), paragraphs: [
            ReferenceText("자유 플레이는 칩으로 플레이하고 끝난 핸드의 실제 행동을 돌아보는 연습이에요. 인원은 2~4명이며 상대 봇의 선택 규칙은 공개돼 있지만 각 선택에 EV 정답을 매기지는 않아요. 좋은 결정도 한 번은 질 수 있어요.", "Free play supports two to four players using practice chips, followed by a factual hand review. Bot rules are published, but choices do not receive an EV grade. A good decision can still lose one hand."),
            ReferenceText("1:1 채점 연습은 별도 모델이에요. 프리플랍은 디펜드 차트, 이후 선택은 현재 라운드가 정리된 뒤 추가 베팅이 없는 체크다운 가정으로 비교해요. EV 손실 0만 정확한 선택으로 세요. 선택은 하루 학습량에 더하지만 정확도·복습 일정·기술 단계는 바꾸지 않아요. 차트와 가정은 실제 모든 게임이나 GTO의 정답이 아니에요.", "Graded heads-up practice uses a separate model: a defend chart preflop, then a checkdown assumption with no more betting after the current street settles. Only zero EV loss counts as an exact choice. Choices add daily study but change no accuracy, review schedule, or skill stage. These charts and assumptions are not answers for every game or a GTO solution.")
        ], termIDs: ["defend-chart", "ev", "ev-loss", "checkdown"]),
    ]
}
