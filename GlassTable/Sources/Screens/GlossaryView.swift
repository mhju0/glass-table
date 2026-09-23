// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// Static term list from docs/glossary.md — only terms the app actually uses.
/// `focus` scrolls to one term: how a drill's 용어 chip explains a word in place,
/// at the moment of confusion, instead of a starter guide explaining it once up front.
struct GlossaryView: View {
    var focus: String? = nil
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
        Term(id: "equity", korean: "에퀴티", english: "Equity",
             koreanDefinition: "지금 쇼다운까지 가면 이길 확률. 무승부는 절반으로 계산합니다.",
             englishDefinition: "Your share of wins if the hand reaches a showdown now. A tie counts as half."),
        Term(id: "pot-odds", korean: "팟 오즈", english: "Pot odds",
             koreanDefinition: "콜 금액 대비 팟이 주는 가격. 콜이 손해가 아니려면 필요 에퀴티를 넘어야 합니다.",
             englishDefinition: "The price of a call compared with the pot you could win. Compare it with your equity."),
        Term(id: "required-equity", korean: "필요 에퀴티", english: "Required equity",
             koreanDefinition: "벳 ÷ (팟 + 벳 + 콜). 이 이상의 에퀴티가 있어야 콜이 이득입니다.",
             englishDefinition: "Call amount ÷ pot after your call. Your equity must reach this share for a no-further-bet call to break even."),
        Term(id: "mdf", korean: "MDF", english: "Minimum defense frequency",
             koreanDefinition: "팟 ÷ (팟 + 벳). 상대 블러프가 자동 이익이 되지 않게 지켜야 할 최소 방어 빈도입니다.",
             englishDefinition: "Pot ÷ (pot + bet). An overall frequency of continuing that stops an empty bet from winning automatically."),
        Term(id: "outs", korean: "아웃", english: "Outs",
             koreanDefinition: "다음 카드 중 내 핸드를 역전시켜 주는 카드의 수입니다.",
             englishDefinition: "Cards that could come next and move your hand ahead."),
        Term(id: "rule-of-2-4", korean: "룰 오브 2/4", english: "Rule of 2/4",
             koreanDefinition: "아웃 × 2%(카드 1장) 또는 × 4%(카드 2장)로 개선 확률을 빠르게 근사합니다.",
             englishDefinition: "A quick estimate: outs × 2% with one card to come, or outs × 4% with two."),
        Term(id: "blocker", korean: "블로커", english: "Blocker",
             koreanDefinition: "내가 들고 있어서 상대가 특정 핸드를 가질 콤보 수를 줄이는 카드입니다.",
             englishDefinition: "A card you hold that reduces the ways your opponent can hold a particular hand."),
        Term(id: "combo", korean: "콤보", english: "Combo",
             koreanDefinition: "핸드 클래스의 구체적 조합 수. 페어 6개, 수티드 4개, 오프수트 12개.",
             englishDefinition: "One specific two-card holding. A pair has 6 combinations, suited cards 4, and offsuit cards 12."),
        Term(id: "range", korean: "레인지", english: "Range",
             koreanDefinition: "한 손이 아니라, 이 상황에서 가질 수 있는 모든 핸드의 집합으로 생각합니다.",
             englishDefinition: "The set of hands someone could hold in this situation, instead of one exact guess."),
        Term(id: "grade-bands", korean: "정확 · 근접 · 다시 살펴볼까요?", english: "Spot-on · Close · Review",
             koreanDefinition: "추정 오차 등급. 정답 맞추기가 아니라 감각을 보정(캘리브레이션)하는 훈련입니다.",
             englishDefinition: "Bands for estimation error. They help calibrate a guess; Close does not mean exact."),
        // The revamp's vocabulary — VPIP/PFR sit on the 테이블 picker, 3벳 and bb on
        // every priced screen, so the glossary owes each a sentence.
        Term(id: "vpip", korean: "VPIP", english: "Voluntarily put in pot",
             koreanDefinition: "자발적으로 팟에 돈을 넣은 핸드의 비율. 상대가 얼마나 넓게 들어오는지를 나타냅니다.",
             englishDefinition: "The share of hands where a player chooses to add chips before the shared cards. Forced blinds do not count."),
        Term(id: "pfr", korean: "PFR", english: "Preflop raise",
             koreanDefinition: "프리플랍에서 레이즈한 핸드의 비율. VPIP와의 차이가 크면 콜만 많이 하는 수동적인 상대입니다.",
             englishDefinition: "The share of hands where a player raises before the shared cards. A large VPIP–PFR gap means more calls."),
        Term(id: "three-bet", korean: "3벳", english: "3-bet",
             koreanDefinition: "오픈 레이즈에 다시 레이즈하는 것. 블라인드가 첫 벳, 오픈이 두 번째라서 3벳입니다.",
             englishDefinition: "A raise over the first raise. The blind is the first bet, the opener the second, and this the third."),
        Term(id: "big-blind", korean: "bb", english: "Big blind",
             koreanDefinition: "빅 블라인드를 1로 두는 금액 단위. 스택과 팟 크기를 블라인드 레벨과 무관하게 비교할 수 있습니다.",
             englishDefinition: "A chip unit equal to one big blind. It lets you compare stacks and pots across blind sizes."),
        Term(id: "chip", korean: "칩", english: "Chip",
             koreanDefinition: "팟 계산 연습에서 쓰는 정수 단위. 이 연습은 SB 1칩, BB 2칩으로 시작합니다.",
             englishDefinition: "The whole-number unit in pot-counting practice. The small blind posts 1 chip and the big blind 2."),
    ]

    private var focusID: String? {
        guard let focus else { return nil }
        return Self.terms.first(where: { $0.id == focus || $0.korean == focus || $0.english == focus })?.id
    }

    static func displayName(for focus: String, language: LearningLanguage) -> String {
        guard let term = terms.first(where: { $0.id == focus || $0.korean == focus || $0.english == focus })
        else { return focus }
        return language == .korean ? term.korean : term.english
    }

    private func row(_ term: Term) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading, spacing: 2) {
                Text(language == .korean ? term.korean : term.english)
                    .font(GT.title(16)).foregroundStyle(GT.ink)
                Text(language == .korean ? term.english : term.korean)
                    .font(GT.body(12)).foregroundStyle(GT.inkMuted)
            }
            Text(language == .korean ? term.koreanDefinition : term.englishDefinition)
                .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, focusID == term.id ? 12 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        // The chip that opened this screen names one term; tint it so the answer is
        // findable without reading the other nine.
        .background(focusID == term.id ? GT.surface : .clear,
                    in: RoundedRectangle(cornerRadius: 14))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Presented as a bare sheet from both entry points, so there is no nav bar
            // to hang a toolbar item on — the chevron lives in the header instead.
            HStack {
                ChromeButton.close { dismiss() }
                Spacer()
            }
            .padding(.leading, 4)
            HStack {
                Text(language.text("용어집", "Glossary")).font(GT.title(16)).foregroundStyle(GT.onFelt)
                Spacer()
            }
            .padding(.horizontal, 18).padding(.bottom, 18)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(Self.terms.enumerated()), id: \.offset) { i, term in
                            row(term)
                                .id(term.id)
                            if i < Self.terms.count - 1 { Divider() }
                        }
                    }
                    .padding(.horizontal, 18).padding(.top, 10).padding(.bottom, 24)
                }
                .onAppear {
                    if let focusID { proxy.scrollTo(focusID, anchor: .top) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gtCard(radius: 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GT.felt.ignoresSafeArea())
    }
}

#Preview { GlossaryView() }
