// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// Static term list from docs/glossary.md — only terms the app actually uses,
/// ordered from the first words a beginner meets to the advanced ones.
/// Always the whole list from the top, with no term singled out: a drill's 용어 chip
/// opens the same plain reference Settings does.
struct GlossaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.learningLanguage) private var language

    private struct Term {
        let id: String
        let korean: String
        let english: String
        let koreanDefinition: String
        let englishDefinition: String
    }

    private static let terms: [Term] = [
        Term(id: "chip", korean: "칩", english: "Chip",
             koreanDefinition: "테이블에서 주고받는 점수 단위예요. 작은 블라인드가 1칩, 큰 블라인드가 2칩을 먼저 내요.",
             englishDefinition: "The unit players put in and win at the table. The small blind posts 1 chip and the big blind 2."),
        // The first words of the opening lessons, which use them before the optional
        // rules pages explain them.
        Term(id: "pot", korean: "팟", english: "Pot",
             koreanDefinition: "가운데 모인 칩이에요. 판이 끝나면 이긴 사람이 가져가요.",
             englishDefinition: "The chips gathered in the middle. The winner of the hand takes them."),
        Term(id: "blinds", korean: "블라인드", english: "Blinds",
             koreanDefinition: "카드를 받기 전에 두 사람이 먼저 내는 칩이에요. 딜러 왼쪽이 작은 블라인드, 그다음이 큰 블라인드를 내요.",
             englishDefinition: "Chips two players put in before the cards are dealt. Left of the dealer posts the small blind, the next player the big blind."),
        Term(id: "dealer-button", korean: "딜러 버튼", english: "Dealer button",
             koreanDefinition: "D 표시예요. 판마다 한 자리씩 옮겨 가고, 블라인드와 행동 순서가 이 표시로 정해져요.",
             englishDefinition: "The D marker. It moves one seat each hand and sets the blinds and the order of play."),
        Term(id: "position", korean: "포지션", english: "Position",
             koreanDefinition: "딜러 버튼을 기준으로 한 내 자리예요. 나중에 행동할수록 앞사람의 선택을 보고 정할 수 있어요.",
             englishDefinition: "Your seat relative to the dealer button. Acting later lets you see others' choices before yours."),
        Term(id: "actions", korean: "체크 · 벳 · 콜 · 레이즈 · 폴드", english: "Check · Bet · Call · Raise · Fold",
             koreanDefinition: "체크는 칩 없이 넘기기, 벳은 먼저 칩 내기, 콜은 낸 만큼 맞추기, 레이즈는 더 올리기, 폴드는 이번 판 포기예요.",
             englishDefinition: "Check passes without chips, bet puts chips in first, call matches, raise puts in more, fold gives up the hand."),
        Term(id: "streets", korean: "프리플랍 · 플랍 · 턴 · 리버", english: "Preflop · Flop · Turn · River",
             koreanDefinition: "한 판의 단계예요. 공용 카드 전, 공용 카드 3장, 4번째 장, 5번째 장이 나온 뒤에 각각 행동해요.",
             englishDefinition: "The rounds of a hand: before shared cards, after three, after the fourth and after the fifth."),
        Term(id: "showdown", korean: "쇼다운", english: "Showdown",
             koreanDefinition: "마지막까지 남은 사람들이 카드를 공개하고, 가장 좋은 다섯 장을 만든 사람이 팟을 가져가요.",
             englishDefinition: "Players still in at the end show their cards, and the best five-card hand takes the pot."),
        Term(id: "big-blind", korean: "bb", english: "Big blind",
             koreanDefinition: "큰 블라인드 한 번의 크기를 1로 보는 단위예요. 블라인드 크기가 달라도 스택과 팟을 같은 기준으로 비교할 수 있어요.",
             englishDefinition: "A chip unit equal to one big blind. It lets you compare stacks and pots across blind sizes."),
        Term(id: "range", korean: "레인지", english: "Range",
             koreanDefinition: "상대의 패를 한 가지로 찍지 않고, 이 상황에서 가질 수 있는 모든 패를 묶어서 생각하는 방법이에요.",
             englishDefinition: "The set of hands someone could hold in this situation, instead of one exact guess."),
        Term(id: "combo", korean: "콤보", english: "Combo",
             koreanDefinition: "같은 종류의 패를 만드는 실제 카드 조합의 수예요. 페어는 6가지, 같은 무늬는 4가지, 다른 무늬는 12가지예요.",
             englishDefinition: "One specific two-card holding. A pair has 6 combinations, suited cards 4, and offsuit cards 12."),
        Term(id: "equity", korean: "에퀴티", english: "Equity",
             koreanDefinition: "끝까지 갔을 때 평균적으로 가져가는 팟의 몫이에요. 비기는 경우의 몫도 들어가요.",
             englishDefinition: "Your average share of the pot at showdown, including ties."),
        Term(id: "pot-odds", korean: "팟 오즈", english: "Pot odds",
             koreanDefinition: "콜에 드는 칩과 이기면 받는 팟을 비교한 가격이에요. 에퀴티가 이 가격이 요구하는 비율보다 높아야 콜이 손해가 아니에요.",
             englishDefinition: "The price of a call compared with the pot you could win. Compare it with your equity."),
        Term(id: "required-equity", korean: "필요 에퀴티", english: "Required equity",
             koreanDefinition: "콜 금액 ÷ (팟 + 벳 + 콜)이에요. 에퀴티가 이 비율이면 본전이고, 더 높으면 콜이 이득이에요.",
             englishDefinition: "Call amount ÷ pot after your call. Your equity must reach this share for a no-further-bet call to break even."),
        Term(id: "outs", korean: "아웃", english: "Outs",
             koreanDefinition: "다음 공용 카드 가운데 내 패가 상대를 확실히 이기게 해 주는 카드의 수예요.",
             englishDefinition: "The number of next shared cards where your hand wins outright against the opponent."),
        Term(id: "rule-of-2-4", korean: "룰 오브 2/4", english: "Rule of 2/4",
             koreanDefinition: "아웃에 2%(카드 1장 남음)나 4%(카드 2장 남음)를 곱해서 패가 좋아질 확률을 빠르게 어림해요.",
             englishDefinition: "A quick estimate: outs × 2% with one card to come, or outs × 4% with two."),
        Term(id: "blocker", korean: "블로커", english: "Blocker",
             koreanDefinition: "내가 들고 있어서 상대가 특정 패를 가질 조합 수를 줄여 주는 카드예요.",
             englishDefinition: "A card you hold that reduces the ways your opponent can hold a particular hand."),
        // The revamp's vocabulary — VPIP/PFR sit on the 테이블 picker, 3벳 on every
        // priced screen, so the glossary owes each a sentence.
        Term(id: "three-bet", korean: "3벳", english: "3-bet",
             koreanDefinition: "첫 레이즈에 다시 레이즈하는 거예요. 블라인드가 첫 번째 벳, 첫 레이즈가 두 번째라서 3벳이라고 불러요.",
             englishDefinition: "A raise over the first raise. The blind is the first bet, the opener the second, and this the third."),
        Term(id: "mdf", korean: "MDF", english: "Minimum defense frequency",
             koreanDefinition: "팟 ÷ (팟 + 벳)이에요. 상대의 블러프가 저절로 이득이 되지 않도록 계속 받아 줘야 하는 최소 비율이에요.",
             englishDefinition: "Pot ÷ (pot + bet). An overall frequency of continuing that stops an empty bet from winning automatically."),
        Term(id: "vpip", korean: "VPIP", english: "Voluntarily put in pot",
             koreanDefinition: "스스로 팟에 칩을 넣은 판의 비율이에요. 상대가 얼마나 많은 패로 참여하는지 보여 줘요.",
             englishDefinition: "The share of hands where a player chooses to add chips before the shared cards. Forced blinds do not count."),
        Term(id: "pfr", korean: "PFR", english: "Preflop raise",
             koreanDefinition: "프리플랍에서 레이즈한 판의 비율이에요. VPIP와 차이가 크면 콜을 많이 하는 상대예요.",
             englishDefinition: "The share of hands where a player raises before the shared cards. A large VPIP–PFR gap means more calls."),
        Term(id: "grade-bands", korean: "정확 · 근접 · 다시 살펴볼까요?", english: "Spot-on · Close · Review",
             koreanDefinition: "어림한 값이 실제와 얼마나 가까운지 나타내는 등급이에요. 정답 맞히기보다 감각을 맞춰 가는 연습이에요.",
             englishDefinition: "Bands for estimation error. They help calibrate a guess; Close does not mean exact."),
    ]

    static func displayName(for focus: String, language: LearningLanguage) -> String {
        guard let term = terms.first(where: { $0.id == focus || $0.korean == focus || $0.english == focus })
        else { return focus }
        return language == .korean ? term.korean : term.english
    }

    private func row(_ term: Term) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading, spacing: 2) {
                Text(language == .korean ? term.korean : term.english)
                    .font(GT.title(16)).foregroundStyle(GT.onFelt)
                Text(language == .korean ? term.english : term.korean)
                    .font(GT.body(12)).foregroundStyle(GT.onFeltMuted)
            }
            Text(language == .korean ? term.koreanDefinition : term.englishDefinition)
                .font(GT.body(14)).foregroundStyle(GT.onFeltSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(language.text("용어집", "Glossary"))
                    .font(GT.title(22)).foregroundStyle(GT.onFelt)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, 8)
                ForEach(Array(Self.terms.enumerated()), id: \.offset) { i, term in
                    row(term)
                    if i < Self.terms.count - 1 { Divider() }
                }
            }
            .gtContentEdge()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FeltBackground())
        .gtChrome(leading: { ChromeButton.close { dismiss() } })
        .gtSheetSurface()
    }
}

#Preview { GlossaryView() }
