// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// Reopens a skill's explanation from a graded question: what it is, why it matters,
/// how to work it out, and a worked example on a different spot. It defines the
/// skill and never touches the current question, so opening it is not help.
struct ConceptExplainView: View {
    @Environment(\.learningLanguage) private var language
    let concept: Concept
    let onClose: () -> Void
    @State private var chartPrimerExpanded = true
    @State private var notationExpanded = false

    var body: some View {
        let intro = ConceptIntroduction.make(concept, language: language)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(intro.title).font(GT.title(26)).foregroundStyle(GT.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if concept == .defend { DefendChartPrimer(expanded: $chartPrimerExpanded) }
                    if concept == .combos { CombinationExampleView() }
                    section(language.text("왜 중요할까요", "Why it matters"), intro.why)
                    section(language.text("이렇게 풀어요", "How to work it out"), intro.how)
                    section(language.text("예시", "Example"), Self.ruleExample(concept, language: language))
                        .accessibilityIdentifier("explain-rule-example")
                    if let note = Self.notationNote(concept, language: language) {
                        DisclosureGroup(isExpanded: $notationExpanded) {
                            Text(note).font(GT.body(16)).foregroundStyle(GT.inkSecondary)
                                .fixedSize(horizontal: false, vertical: true).padding(.top, 8)
                        } label: {
                            Text(language.text("표기 더 보기", "More about notation"))
                                .font(GT.semibold(15)).frame(minHeight: 44)
                        }
                        .foregroundStyle(GT.ink).padding(.horizontal, 14).gtPanel()
                    }
                    if concept == .rfi || concept == .rangeNotation { LessonChartPrimer() }
                }
                .gtContentEdge()
            }
            .background(FeltBackground())
            .gtChrome(leading: { ChromeButton.close(onClose) })
            .gtSheetSurface()
        }
        .accessibilityIdentifier("concept-explain")
    }

    private func section(_ label: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: label, onDark: false)
            Text(text).font(GT.body(16)).foregroundStyle(GT.ink)
                .lineSpacing(GT.Typography.bodyLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .gtInset(GT.Space.card, firstText: .semibold(13))
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtPanel()
    }

    static func ruleExample(_ concept: Concept, language: LearningLanguage) -> String {
        switch concept {
        case .showdown:
            return language.text(
                "내 카드가 A♠ K♦, 공용 카드가 K♣ 7♥ 7♦ 4♠ 2♣면 K 페어와 7 페어로 투 페어예요. 상대가 Q♠ Q♥면 Q 페어와 7 페어라서 내가 이겨요.",
                "With A♠ K♦ and shared cards K♣ 7♥ 7♦ 4♠ 2♣, you have two pair, kings and sevens. An opponent with Q♠ Q♥ has queens and sevens, so you win.")
        case .potMath:
            return language.text(
                "작은 블라인드 1칩, 큰 블라인드 2칩이 있고 한 사람이 6칩을 내면 팟은 1 + 2 + 6 = 9칩이에요. 다음 사람이 포기해도 9칩 그대로예요.",
                "The small blind posts 1 chip and the big blind 2. One player puts in 6, so the pot is 1 + 2 + 6 = 9 chips. If the next player folds, it stays 9.")
        case .position:
            return language.text(
                "공용 카드 전에는 큰 블라인드가 마지막이에요. 공용 카드 뒤에는 딜러 왼쪽의 참여 중인 자리부터 행동해요.",
                "Before shared cards, the big blind acts last. After them, begin left of the dealer among active seats.")
        case .combos:
            return language.text(
                "AK는 A 네 장 × K 네 장 = 16콤보예요. 공용 카드에 A가 한 장 보이면 A가 세 장 남아서 3 × 4 = 12콤보예요.",
                "AK is 4 aces × 4 kings = 16 combos. If one ace is among the shared cards, three aces remain, so 3 × 4 = 12 combos.")
        case .potOdds:
            return language.text(
                "팟이 10칩이고 상대가 3칩을 걸면 콜은 3칩이에요. 콜한 뒤의 전체 팟은 10 + 3 + 3 = 16칩이라서 3 ÷ 16 = 약 19%예요.",
                "The pot is 10 chips and the opponent bets 3, so the call is 3. The whole pot after your call is 10 + 3 + 3 = 16, so 3 ÷ 16 is about 19%.")
        case .outs:
            return language.text(
                "같은 무늬 네 장으로 플러시를 기다리면 그 무늬는 13 − 4 = 9장 남아요. 그중 상대에게 더 좋은 패를 만들어 주는 카드가 있으면 빼요.",
                "With four cards of one suit you are waiting for a flush, and 13 − 4 = 9 cards of that suit remain. Leave out any that give the opponent a better hand.")
        case .equitySense:
            return language.text(
                "공용 카드 전에 AA와 KK가 끝까지 가면 AA가 약 82% 이겨요. 정확한 숫자보다 '80% 안팎'처럼 범위로 잡아요.",
                "Before any shared cards, AA against KK wins about 82% of the time by the final reveal. Aim for a range such as \"around 80%\" instead of an exact number.")
        case .evCall:
            return language.text(
                "이기면 9bb를 얻고 지면 3bb를 잃는 콜이에요. 30% 이긴다면 0.3 × 9 − 0.7 × 3 = +0.6bb예요.",
                "A call wins 9bb when it wins and loses 3bb when it loses. Winning 30% of the time, it is worth 0.3 × 9 − 0.7 × 3 = +0.6bb.")
        case .callFold:
            return language.text(
                "콜에 필요한 승률이 25%일 때, 이길 가능성이 35%면 콜하고 20%면 포기해요.",
                "If the call needs 25% to break even, call with a 35% chance of winning and fold with 20%.")
        case .rangeNotation:
            return language.text(
                "AKs는 같은 무늬 4콤보, AKo는 다른 무늬 12콤보, KK는 6콤보예요. 99+는 99, TT, JJ, QQ, KK, AA를 모두 뜻해요.",
                "AKs is 4 same-suit combos, AKo is 12 different-suit combos and KK is 6 combos. 99+ means 99, TT, JJ, QQ, KK and AA.")
        case .rfi:
            return language.text(
                "여덟 명 테이블의 첫 자리는 뒤에 일곱 명이 남아서 좁게 열어요. 버튼은 뒤에 두 명만 남아서 더 넓게 열어요.",
                "At an eight-player table the first seat has seven players behind, so it opens few hands. The button has only two behind, so it opens more.")
        case .rangeRead:
            return language.text(
                "상대가 AK를 들 수 있는데 공용 카드에 K가 한 장 있으면, AK는 16콤보가 아니라 4 × 3 = 12콤보만 남아요.",
                "Suppose the opponent can hold AK and one king is among the shared cards. AK is then 4 × 3 = 12 combos, not 16.")
        case .hitFrequency:
            return language.text(
                "상대 레인지가 AK와 QJ뿐이고 플랍이 K♠ 7♦ 2♣라면, AK 12콤보는 페어를 만들었고 QJ 16콤보는 못 만들었어요. 12 ÷ 28 = 약 43%예요.",
                "Suppose the range is only AK and QJ and the flop is K♠ 7♦ 2♣. The 12 AK combos made a pair and the 16 QJ combos did not, so 12 ÷ 28 is about 43%.")
        case .rangeAdvantage:
            return language.text(
                "A가 높은 보드는 A를 더 많이 든 먼저 올린 쪽에 유리해요. 그래서 평균 승률이 50 대 50이 아니라 한쪽으로 기울어요.",
                "An ace-high board favors the player who raised first, because that range holds more aces. The average win rate then leans one way instead of 50 to 50.")
        case .evLoss:
            return language.text(
                "콜의 평균값이 −0.5bb이고 폴드가 0bb면 폴드가 가장 나은 선택이에요. 콜을 고르면 0.5bb를 놓친 거예요.",
                "If calling averages −0.5bb and folding is 0bb, folding is the best choice. Choosing to call gives up 0.5bb.")
        case .actionRead:
            return language.text(
                "상대 패의 40%가 페어 이상이에요. 페어 이상이면 항상 베팅하고 나머지는 절반만 베팅한다면, 베팅 뒤에는 40 ÷ (40 + 30) = 약 57%가 페어 이상이에요.",
                "40% of the opponent's hands are a pair or better. If they always bet those and bet half of the rest, then after a bet 40 ÷ (40 + 30) is about 57% pair or better.")
        case .defend:
            return language.text(
                "좁게 여는 앞자리가 올렸으면 더 좋은 카드로만 대응해요. 넓게 여는 버튼이 올렸으면 더 많은 카드로 대응해요.",
                "Against a raise from an early seat, which opens few hands, continue only with stronger cards. Against a raise from the button, which opens many, continue with more.")
        case .mdf:
            return language.text(
                "팟이 10bb이고 상대가 5bb를 걸면 10 ÷ (10 + 5) = 약 67%는 계속해야 해요.",
                "If the pot is 10bb and the opponent bets 5bb, continue with 10 ÷ (10 + 5), about 67% of your hands.")
        }
    }

    static func notationNote(_ concept: Concept, language: LearningLanguage) -> String? {
        switch concept {
        case .combos, .rangeNotation, .rfi, .defend, .rangeRead, .hitFrequency,
             .rangeAdvantage, .actionRead:
            return language.text(
                "K♠와 6♠는 같은 무늬예요. K6s의 s는 스페이드가 아니라 같은 무늬를 뜻해요. K6o는 다른 무늬, KK는 페어예요. 99+는 99 이상의 모든 페어예요.",
                "K♠ and 6♠ share a suit. In K6s, s means suited, not spades. K6o means different suits; KK is a pair. 99+ means every pair from 99 up.")
        case .potOdds, .mdf, .callFold, .evCall, .evLoss:
            return language.text("bb는 빅 블라인드 한 개만큼의 칩이에요.",
                                 "bb is the chip amount of one big blind.")
        case .showdown, .potMath, .position, .outs, .equitySense:
            return nil
        }
    }
}
