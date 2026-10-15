import SwiftUI
import GlassTableEngine
import GlassTableDrills

struct LessonPairedText: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.dynamicTypeSize) private var textSize
    let korean: [String]
    let english: [String]

    var body: some View {
        Text(textSize.isAccessibilitySize
             ? (language == .korean ? korean : english).joined(separator: " ")
             : (language == .korean ? korean : english).joined(separator: "\n"))
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct LessonCountChoices: View {
    @Environment(\.dynamicTypeSize) private var textSize
    let values: [Int]
    var suffix = ""
    /// Set once answered: the row stays where it is and marks the pick and the answer.
    var picked: Int? = nil
    var correct: Int? = nil
    let choose: (Int) -> Void
    var body: some View {
        let layout = textSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
        layout {
            // At accessibility sizes the stacked row is tall: once answered, only the
            // marked choices stay, so the panel leaves room for the lesson above it.
            ForEach(values.filter { !textSize.isAccessibilitySize || picked == nil
                                    || LessonAnswer.mark($0, picked: picked, correct: correct) != nil }, id: \.self) { value in
                let verdict = LessonAnswer.mark(value, picked: picked, correct: correct)
                GTChoiceButton(title: "\(value)\(suffix)", minHeight: 52, verdict: verdict) { choose(value) }
                    .lessonAnswerMark(verdict, answered: picked != nil)
                    .accessibilityIdentifier("lesson-choice-\(value)")
            }
        }
    }
}

enum LessonAnswer {
    /// How a choice is marked once answered: the right one green, a wrong pick red.
    static func mark(_ value: Int, picked: Int?, correct: Int?) -> GradeBand? {
        guard let picked else { return nil }
        if value == correct { return .spotOn }
        return value == picked ? .off : nil
    }
}

/// The verdict at the top of an answered lesson panel: glyph and words in the
/// verdict's colour, with the reason under them. Colour is never the only signal.
struct LessonAnswerVerdict<Detail: View>: View {
    @Environment(\.learningLanguage) private var language
    let correct: Bool
    @ViewBuilder var detail: () -> Detail

    var body: some View {
        let band: GradeBand = correct ? .spotOn : .off
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: band.glyph).font(GT.title(18))
                .foregroundStyle(band.ink).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(correct ? language.text("맞아요", "That's right") : language.text("아쉬워요", "Not quite"))
                    .font(GT.title(18)).foregroundStyle(band.ink)
                    .accessibilityIdentifier("lesson-answer-verdict")
                detail().foregroundStyle(GT.ink)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension View {
    /// Locks an answered choice in place and says what its mark means.
    func lessonAnswerMark(_ verdict: GradeBand?, answered: Bool) -> some View {
        modifier(LessonAnswerMark(verdict: verdict, answered: answered))
    }
}

private struct LessonAnswerMark: ViewModifier {
    @Environment(\.learningLanguage) private var language
    let verdict: GradeBand?
    let answered: Bool
    func body(content: Content) -> some View {
        content
            .disabled(answered && verdict == nil)
            .allowsHitTesting(!answered)
            .accessibilityValue(verdict == .spotOn ? language.text("정답", "Correct answer")
                                : verdict == .off ? language.text("선택한 답, 오답", "Your answer, incorrect") : "")
    }
}

struct CompactLessonCue: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let concept: Concept
    @State private var expanded = false
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(reduceMotion ? nil : GT.Motion.change) { expanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Label(language.text("푸는 방법", "How to work it out"), systemImage: "lightbulb")
                        .font(GT.semibold(14))
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down").font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GT.inkSecondary)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(GTPress())
            .accessibilityValue(expanded ? language.text("펼침", "Expanded") : language.text("접힘", "Collapsed"))
            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text(lessonCueSentence(concept, language: language))
                        .font(GT.semibold(15)).foregroundStyle(GT.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(ConceptIntroduction.make(concept, language: language).how)
                        .font(GT.body(15)).foregroundStyle(GT.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4).padding(.bottom, GT.Space.card)
            }
        }
        .foregroundStyle(GT.ink)
        .padding(.horizontal, GT.Space.card).gtPanel()
        .accessibilityIdentifier("contextual-hint-cue")
    }
}

/// The one-sentence way in, shown first when the help row opens.
func lessonCueSentence(_ concept: Concept, language: LearningLanguage) -> String {
    switch concept {
    case .showdown: return language.text(
        "가장 높은 5장 조합을 만들고, 같으면 높은 카드부터 비교해 보세요.",
        "Make each player's best five-card hand. If tied, compare the highest cards first.")
    case .potMath: return language.text(
        "시작 팟과 각 행동에서 들어온 칩을 한 번씩 더해 보세요.",
        "Start with the pot, then add each contribution once.")
    case .position: return language.text(
        "버튼에서 시계 방향으로 좌석을 세고, 누가 먼저 행동하는지 확인하세요.",
        "Count seats clockwise from the dealer button, then check who acts first.")
    case .combos: return language.text(
        "두 장 조합에서 이미 보인 카드가 들어간 조합을 빼세요.",
        "Count two-card pairs, then remove pairs containing a visible card.")
    case .potOdds: return language.text(
        "콜 금액을 콜 뒤 전체 팟으로 나눠 보세요.",
        "Divide the call amount by the full pot after your call.")
    case .outs: return language.text(
        "상대 패를 이기게 하는 카드만 세고, 이미 보인 카드는 빼세요.",
        "Count cards that beat the shown opponent hand, excluding visible cards.")
    case .equitySense: return language.text(
        "남은 카드에서 이기거나 비기는 경우가 얼마나 될지 가늠하세요.",
        "Estimate how often the remaining cards let you win or tie.")
    case .evCall: return language.text(
        "이길 때 얻는 돈과 질 때 내는 돈을 각각 확률만큼 반영하세요.",
        "Weight the money won and the call lost by their chances.")
    case .callFold: return language.text(
        "콜에 필요한 승률을 내 승률과 비교하세요.",
        "Compare the win chance your call needs with your own win chance.")
    case .rangeNotation: return language.text(
        "같은 숫자, 같은 무늬, 다른 무늬를 먼저 구분해 보세요.",
        "First separate pairs, same-suit hands, and different-suit hands.")
    case .rfi: return language.text(
        "내 자리의 표에서 손패 칸이 열기 범위에 있는지 보세요.",
        "Find your hand on the chart for your seat and see whether it is in range.")
    case .rangeRead: return language.text(
        "시작 손패에서 지금까지의 행동과 보드에 맞지 않는 조합을 빼세요.",
        "Start with possible hands, then remove ones that do not fit the action or board.")
    case .hitFrequency: return language.text(
        "맞은 손패, 드로, 놓친 손패로 나눠 비중을 보세요.",
        "Separate made hands, draws, and misses, then compare their shares.")
    case .rangeAdvantage: return language.text(
        "두 사람의 시작 손패가 이 보드에서 얼마나 강해지는지 비교하세요.",
        "Compare how often each player's starting hands become strong on this board.")
    case .evLoss: return language.text(
        "두 선택의 예상 가치를 비교하고, 더 좋은 선택과의 차이를 보세요.",
        "Compare the two choices' expected value, then find the gap from the better one.")
    case .actionRead: return language.text(
        "이 크기로 벳할 법한 손패가 무엇인지 좁혀 보세요.",
        "Narrow down which hands would likely choose this bet size.")
    case .defend: return language.text(
        "내 자리와 상대가 처음 올린 자리를 확인하고 표에서 손패를 찾으세요.",
        "Check both seats, then find your hand on the defend chart.")
    case .mdf: return language.text(
        "1 − 벳/(기존 팟 + 벳)으로 전체 방어 비율을 구하세요. 한 손패의 콜 여부는 따로 판단해요.",
        "Use 1 − bet/(pot + bet) for the overall defend share. One hand's call is a separate decision.")
    }
}

struct LessonSeatLoop: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.dynamicTypeSize) private var textSize
    var active: Position? = nil
    var markers: [Position: String] = [:]
    var showsOrder = true
    var postflop = false
    @State private var terms = false
    private let places: [[Position?]] = [[nil, .utg, .utg1, nil], [.bb, nil, nil, .lj],
                                        [.sb, nil, nil, .hj], [nil, .btn, .co, nil]]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if textSize.isAccessibilitySize {
                ForEach(Position.allCases, id: \.self) { position in
                    HStack {
                        Text("\(position.seatNumber)").font(GT.title(20)).frame(minWidth: 28)
                        Text(position.seatName(in: language).replacingOccurrences(of: "\n", with: " "))
                        if let marker = markers[position] { Text(marker).bold() }
                    }.font(GT.body(17)).foregroundStyle(active == position ? GT.cta : GT.ink)
                }
            } else {
                Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                    ForEach(places.indices, id: \.self) { row in
                        GridRow {
                            ForEach(places[row].indices, id: \.self) { column in
                                if let position = places[row][column] { seat(position) }
                                else { Color.clear.frame(maxWidth: .infinity).frame(height: terms ? 80 : 68) }
                            }
                        }
                    }
                }
                .overlay { if showsOrder { directionOverlay } }
                .overlay {
                    VStack(spacing: 6) {
                        Text(language.text(postflop ? "플랍 이후" : "플랍 전", postflop ? "After flop" : "Before flop"))
                            .font(GT.semibold(13))
                        if let active { Text("\(active.seatNumber)").font(GT.title(26)) }
                    }.foregroundStyle(GT.ink).allowsHitTesting(false)
                }
            }
            if showsOrder {
                Text(language.text("시계 방향 · 여덟 자리 모두 참여 중", "Clockwise · all eight seats active"))
                    .font(GT.body(12)).foregroundStyle(GT.inkSecondary)
            }
            Button { terms.toggle() } label: {
                Text(language.text(terms ? "용어 접기" : "포커 용어 보기", terms ? "Hide terms" : "Show poker terms"))
            }
                .buttonStyle(GTOutlinedAction())
                .accessibilityIdentifier("position-terms-toggle")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("position-boxed-loop")
    }
    private func seat(_ position: Position) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                Text("\(position.seatNumber)")
                if let marker = markers[position] { Text(marker) }
            }.font(GT.semibold(17))
            Text(position.seatName(in: language)).font(GT.semibold(12))
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            if terms { Text(position.rawValue).font(GT.body(10)) }
        }
        .frame(maxWidth: .infinity).frame(height: terms ? 80 : 68)
        .foregroundStyle(active == position ? GT.onCTA : GT.ink)
        .background(active == position ? GT.cta : GT.surface, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(GT.borderStrong, lineWidth: 1))
        .accessibilityLabel("\(position.seatNumber), " + position.seatName(in: language).replacingOccurrences(of: "\n", with: " ")
                            + (markers[position].map { ", \($0)" } ?? ""))
    }
    private var directionOverlay: some View {
        GeometryReader { geometry in
            let arrows: [(CGFloat, CGFloat, String)] = [(0.5,0.105,"arrow.right"), (0.89,0.24,"arrow.down"),
                (0.895,0.5,"arrow.down"), (0.76,0.895,"arrow.left"), (0.5,0.895,"arrow.left"),
                (0.105,0.76,"arrow.up"), (0.105,0.5,"arrow.up"), (0.24,0.105,"arrow.right")]
            ForEach(arrows.indices, id: \.self) { index in
                let arrow = arrows[index]
                Image(systemName: arrow.2).font(.system(size: 10, weight: .bold))
                    .foregroundStyle(GT.inkSecondary)
                    .position(x: geometry.size.width * arrow.0, y: geometry.size.height * arrow.1)
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct LessonChartPrimer: View {
    @Environment(\.learningLanguage) private var language
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LessonPairedText(korean: ["위와 왼쪽: A부터 2까지", "대각선: 같은 숫자 두 장", "오른쪽 위: 같은 무늬", "왼쪽 아래: 다른 무늬"],
                            english: ["Top and left: A down to 2", "Diagonal: two matching ranks", "Above right: the same suit", "Below left: different suits"])
                .font(GT.body(15)).foregroundStyle(GT.ink)
            Text(language.text("한 칸은 두 장 패의 종류예요. 색은 이 연습 차트의 포함 또는 행동을 뜻하며 승률이 아니에요.",
                               "Each cell is a two-card hand type. Color shows this practice chart’s inclusion or action, not winning chance."))
                .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
        }.padding(14).gtPanel().accessibilityIdentifier("lesson-chart-primer")
    }
}

struct DefendChartPracticeState {
    var chartVisible = true
    var primerExpanded = true
    var correctDecisions = 0
    var invitationDismissed = false

    var offersIndependentTry: Bool { correctDecisions >= 3 && !invitationDismissed }
}

struct DefendChartPrimer: View {
    @Environment(\.learningLanguage) private var language
    @Binding var expanded: Bool

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            VStack(alignment: .leading, spacing: 10) {
                Text(language.text("bb는 빅 블라인드 한 개만큼의 칩이에요. 3bb는 그 세 배예요.",
                                   "bb is the chip amount of one big blind. 3bb is three times that amount."))
                Text(language.text("콜은 상대가 낸 만큼 맞추기, 폴드는 이번 패 내려놓기예요. 다시 올리기는 이미 올린 상대보다 더 올리는 행동이며 3벳이라고도 해요.",
                                   "Call matches the raise; fold leaves this hand. Raise again increases an existing raise, also called a 3-bet."))
                LessonPairedText(
                    korean: ["내 두 장 숫자가 만나는 칸을 찾으세요.",
                             "대각선은 같은 숫자 두 장(페어)이에요.",
                             "위 s는 같은 무늬, 아래 o는 다른 무늬예요.",
                             "색 옆의 행동 이름을 읽으세요."],
                    english: ["Find the cell for your two ranks.",
                              "Diagonal: two matching ranks (pairs).",
                              "Above s: same suit. Below o: different suits.",
                              "Read the action names beside the colors."])
            }
            .font(GT.body(15)).foregroundStyle(GT.inkSecondary)
            .fixedSize(horizontal: false, vertical: true).padding(.top, 8)
        } label: {
            Text(language.text("차트로 맞서기", "Using the chart against a raise"))
                .font(GT.semibold(15)).frame(minHeight: 44)
        }
        .foregroundStyle(GT.ink).padding(.horizontal, 14).gtPanel()
        .accessibilityIdentifier("defend-chart-primer")
    }
}

private struct LessonGuidedChartKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var lessonGuidedChart: Bool {
        get { self[LessonGuidedChartKey.self] }
        set { self[LessonGuidedChartKey.self] = newValue }
    }
}

struct PotMathReplayControls: View {
    @Environment(\.learningLanguage) private var language
    let steps: Int
    @Binding var stepIndex: Int
    var body: some View {
        HStack(spacing: 12) {
            GTChoiceButton(title: language.text("이전 행동", "Previous action"), minHeight: 52) {
                stepIndex = max(0, stepIndex - 1)
            }.disabled(stepIndex == 0).accessibilityIdentifier("pot-previous-action")
            GTChoiceButton(title: language.text("다음 행동", "Next action"), minHeight: 52) {
                stepIndex = min(steps - 1, stepIndex + 1)
            }.disabled(stepIndex >= steps - 1).accessibilityIdentifier("pot-next-action")
        }
    }
}

struct LessonEstimateChoices: View {
    @Environment(\.dynamicTypeSize) private var textSize
    let values: [Double]
    let suffix: String
    let choose: (Double) -> Void
    var body: some View {
        let layout = textSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
        layout {
            ForEach(values, id: \.self) { value in
                let text = value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
                GTChoiceButton(title: text + suffix, minHeight: 52) { choose(value) }
                    .accessibilityIdentifier("lesson-estimate-choice-\(text)")
            }
        }
    }
    static func evValues(answer: Double, seed: UInt64) -> [Double] {
        let rounded = (answer * 2).rounded() / 2
        var values = [rounded - 1, rounded, rounded + 1]
        var rng = SplitMix64(seed: seed)
        values.shuffle(using: &rng)
        return values
    }
}

struct LessonHandNotation: View {
    @Environment(\.learningLanguage) private var language
    let cards: [Card]
    var body: some View {
        if cards.count == 2 {
            VStack(alignment: .leading, spacing: 12) {
                CardRow(cards: cards)
                let pair = cards[0].rank == cards[1].rank
                let suited = cards[0].suit == cards[1].suit
                Text(pair ? language.text("같은 숫자 두 장: 페어예요.", "Two matching ranks make a pair.")
                          : suited ? language.text("두 장의 무늬가 같아요.", "The two cards share a suit.")
                                   : language.text("두 장의 무늬가 달라요.", "The suits are different."))
                    .font(GT.title(18)).foregroundStyle(GT.ink)
                if !pair {
                    LessonPairedText(korean: ["s는 같은 무늬, o는 다른 무늬예요.", "s는 스페이드만 뜻하지 않아요."],
                                    english: ["s means suited; o means different suits.", "s does not mean spades specifically."])
                        .font(GT.body(15)).foregroundStyle(GT.inkSecondary)
                }
            }.padding(14).gtPanel().accessibilityIdentifier("lesson-hand-notation")
        }
    }
}
