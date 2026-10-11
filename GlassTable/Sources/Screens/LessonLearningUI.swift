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
    let choose: (Int) -> Void
    var body: some View {
        let layout = textSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
        layout {
            ForEach(values, id: \.self) { value in
                GTChoiceButton(title: "\(value)\(suffix)", minHeight: 52) { choose(value) }
                    .accessibilityIdentifier("lesson-choice-\(value)")
            }
        }
    }
}

struct CompactLessonCue: View {
    @Environment(\.learningLanguage) private var language
    let concept: Concept
    @State private var expanded = false
    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            Text(ConceptIntroduction.make(concept, language: language).how)
                .font(GT.body(15)).foregroundStyle(GT.inkSecondary)
                .fixedSize(horizontal: false, vertical: true).padding(.top, 8)
        } label: {
            Label(language.text("푸는 방법", "How to work it out"), systemImage: "lightbulb")
                .font(GT.semibold(14)).frame(minHeight: 44)
        }
        .foregroundStyle(GT.ink)
        .padding(.horizontal, 14).gtPanel()
        .accessibilityIdentifier("contextual-hint-cue")
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
    static func number(_ position: Position) -> Int { (Position.allCases.firstIndex(of: position) ?? 0) + 1 }
    static func name(_ position: Position, language: LearningLanguage) -> String {
        switch position {
        case .utg: language.text("첫\n자리", "First\nseat")
        case .utg1: language.text("두 번째\n자리", "Second\nseat")
        case .lj: language.text("세 번째\n자리", "Third\nseat")
        case .hj: language.text("네 번째\n자리", "Fourth\nseat")
        case .co: language.text("딜러 앞\n자리", "Before\ndealer")
        case .btn: language.text("딜러", "Dealer")
        case .sb: language.text("작은\n블라인드", "Small\nblind")
        case .bb: language.text("큰\n블라인드", "Big\nblind")
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if textSize.isAccessibilitySize {
                ForEach(Position.allCases, id: \.self) { position in
                    HStack {
                        Text("\(Self.number(position))").font(GT.title(20)).frame(minWidth: 28)
                        Text(Self.name(position, language: language).replacingOccurrences(of: "\n", with: " "))
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
                        Text(language.text(postflop ? "플롭 이후" : "플롭 전", postflop ? "After flop" : "Before flop"))
                            .font(GT.semibold(13))
                        if let active { Text("\(Self.number(active))").font(GT.title(26)) }
                    }.foregroundStyle(GT.ink).allowsHitTesting(false)
                }
            }
            if showsOrder {
                Text(language.text("시계 방향 · 여덟 자리 모두 참여 중", "Clockwise · all eight seats active"))
                    .font(GT.body(12)).foregroundStyle(GT.inkSecondary)
            }
            Button { terms.toggle() } label: {
                Text(language.text(terms ? "용어 접기" : "포커 용어 보기", terms ? "Hide terms" : "Show poker terms"))
                    .font(GT.semibold(13)).frame(minHeight: 44).contentShape(Rectangle())
            }
                .accessibilityIdentifier("position-terms-toggle")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("position-boxed-loop")
    }
    private func seat(_ position: Position) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                Text("\(Self.number(position))")
                if let marker = markers[position] { Text(marker) }
            }.font(GT.semibold(17))
            Text(Self.name(position, language: language)).font(GT.semibold(12))
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            if terms { Text(position.rawValue).font(GT.body(10)) }
        }
        .frame(maxWidth: .infinity).frame(height: terms ? 80 : 68)
        .foregroundStyle(active == position ? GT.onCTA : GT.ink)
        .background(active == position ? GT.cta : GT.surface, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(GT.borderStrong, lineWidth: 1))
        .accessibilityLabel("\(Self.number(position)), " + Self.name(position, language: language).replacingOccurrences(of: "\n", with: " ")
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
                                   : language.text("두 장의 무늬가 달라요.", "The two cards have different suits."))
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
