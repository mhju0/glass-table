// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

/// A disposable worked hand. Answers explain rules; they never reach progression or a saved table.
struct GuidedHandState {
    var seed: UInt64 = 42
    var lessGuidance = false
    private(set) var page = 0
    private(set) var answers: [Int: Int] = [:]
    private var deal: (hero: [Card], opponent: [Card], board: [Card]) {
        let source: ([(Int, Int)], [(Int, Int)], [(Int, Int)])
        switch seed % 3 {
        case 0: source = ([(14,0),(14,1)], [(13,2),(13,3)], [(12,0),(7,1),(2,2),(9,3),(3,0)])
        case 1: source = ([(12,0),(11,1)], [(9,2),(9,3)], [(10,0),(9,1),(8,2),(2,3),(3,0)])
        default: source = ([(14,0),(13,1)], [(12,2),(11,3)], [(14,1),(12,0),(7,2),(2,3),(3,0)])
        }
        func convert(_ cards: [(Int, Int)]) -> [Card] {
            cards.map { Card(rank: $0.0, suit: suit($0.1)) }
        }
        return (convert(source.0), convert(source.1), convert(source.2))
    }
    var hero: [Card] { lessGuidance ? deal.opponent : deal.hero }
    var opponent: [Card] { lessGuidance ? deal.hero : deal.opponent }
    var board: [Card] { deal.board }
    var showdown: ShowdownSpot { ShowdownSpot(hero: hero, villain: opponent, board: board) }
    var visibleBoard: [Card] { Array(board.prefix(page < 2 ? 0 : page == 2 ? 3 : page == 3 ? 4 : 5)) }
    var pot: Int {
        switch page {
        case 0: 3
        case 1: answers[1] == nil ? 3 : 4
        case 2: 4
        case 3: answers[3] == nil ? 6 : 8
        default: 8
        }
    }
    var correct: Int { page == 1 ? 1 : page == 3 ? 2 : page == 5 ? showdown.winner : 0 }
    var needsAnswer: Bool { (1...5).contains(page) && answers[page] == nil }
    mutating func choose(_ value: Int) { guard (1...5).contains(page), answers[page] == nil else { return }; answers[page] = value }
    mutating func next() { guard !needsAnswer else { return }; page = min(6, page + 1) }
    mutating func previous() { page = max(0, page - 1) }
    mutating func replay(lessGuidance: Bool) {
        self.lessGuidance = lessGuidance; seed &+= 1; page = 0; answers = [:]
    }
    private func suit(_ value: Int) -> Int { (value + Int(seed % 4)) % 4 }
}

struct GuidedHandView: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var hand = GuidedHandState()
    let onClose: () -> Void
    let onPlay: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(language.text("이전", "Previous")) { previous() }
                    .disabled(hand.page == 0).accessibilityIdentifier("guided-hand-previous")
                Spacer()
                Text(language.text("함께 한 판", "A hand together")).font(GT.semibold(16))
                Spacer()
                Button(language.text("닫기", "Close"), action: onClose)
                    .accessibilityIdentifier("guided-hand-close")
            }.font(GT.semibold(14)).frame(minHeight: 52).padding(.horizontal, 18)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    title.font(GT.title(25)).accessibilityIdentifier("guided-hand-page-\(hand.page)")
                    if hand.page == 0 {
                        LessonPairedText(korean: ["한 판을 따라가며 규칙을 확인해요.", "선택 뒤에는 설명에 나온 행동을 따라가요."],
                                         english: ["Follow one hand to learn the rules.", "After each choice, follow the example action."])
                            .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                    }
                    if hand.page == 6 {
                        reviewHand
                    } else if hand.page > 0 {
                        ThreeRegionCardTable(opponent: hand.page >= 5 ? hand.opponent : [], board: hand.visibleBoard,
                                             hero: hand.hero, opponentTitle: language.text(hand.page >= 5 ? "상대 카드" : "상대 카드 · 아직 비공개", hand.page >= 5 ? "Opponent's cards" : "Opponent's cards · hidden"),
                                             heroTitle: language.text("내 카드", "Your cards"),
                                             highlight: hand.page >= 5 && !hand.needsAnswer ? bestFiveCards((hand.showdown.winner == 0 ? hand.hero : hand.opponent) + hand.board) : [])
                        Text(language.text("팟 \(hand.pot)칩 · 시작 칩 각 20개", "Pot: \(hand.pot) chips · started with 20 each"))
                            .font(GT.semibold(16))
                    }
                    context.font(GT.body(18))
                    if !hand.lessGuidance && hand.needsAnswer {
                        cue.font(GT.body(16)).foregroundStyle(GT.inkSecondary)
                    }
                    if let answer = hand.answers[hand.page] {
                        feedback(correct: answer == hand.correct)
                            .font(GT.body(17)).padding(16).gtPanel()
                            .accessibilityIdentifier("guided-hand-feedback")
                    }
                    if hand.page == 6 {
                        LessonPairedText(korean: ["각자 4칩을 내서 팟은 8칩이었어요.", "이긴 사람은 24칩으로 마쳐요.", "다른 사람은 16칩으로 마쳐요."],
                                         english: ["Each paid 4; the pot held 8 chips.", "Winner: 24 chips.", "Other player: 16 chips."])
                            .font(GT.body(17))
                    }
                    if textSize.isAccessibilitySize { controls }
                }.padding(18)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !textSize.isAccessibilitySize {
                controls.padding(.horizontal, 18).padding(.bottom, 12).background(GT.surface)
            }
        }
        .foregroundStyle(GT.ink).background(FeltBackground())
        .onAppear {
            #if DEBUG
            if let raw = ProcessInfo.processInfo.environment["GT_DEMO_GUIDED_HAND_STEP"], let page = Int(raw) {
                for _ in 0..<min(6, max(0, page)) {
                    if hand.needsAnswer { hand.choose(hand.correct) }
                    hand.next()
                }
            }
            #endif
        }
        .overlay(alignment: .leading) {
            Color.clear.frame(width: 24).contentShape(Rectangle()).allowsHitTesting(hand.page > 0)
                .gesture(DragGesture(minimumDistance: 35).onEnded { value in
                    if value.translation.width > 70 && abs(value.translation.height) < 70 { previous() }
                })
        }
    }

    private var reviewHand: some View {
        let winner = hand.showdown.winner
        let cards = bestFiveCards((winner == 1 ? hand.opponent : hand.hero) + hand.board)
        return VStack(alignment: .leading, spacing: 8) {
            Text(HandOutcomeCopy.answer(winner, in: language) + language.text(" · 가장 좋은 다섯 장", " · best five"))
                .font(GT.semibold(16))
            ViewThatFits(in: .horizontal) {
                CardRow(cards: cards)
                HStack(spacing: 8) {
                    ForEach(cards, id: \.self) { card in
                        PlayingCardView(card: card, size: 48)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("guided-hand-review-best-five")
    }

    @ViewBuilder private var controls: some View {
        VStack(spacing: 10) {
            if hand.needsAnswer {
                let layout = textSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
                layout {
                    ForEach(choices, id: \.0) { value, text in
                        GTChoiceButton(title: text, minHeight: 52) { hand.choose(value) }
                            .accessibilityIdentifier("guided-hand-choice-\(value)")
                    }
                }
            } else if hand.page < 6 {
                PrimaryCTAButton(title: language.text("다음", "Next")) { hand.next() }
                    .accessibilityIdentifier("guided-hand-next")
            } else {
                PrimaryCTAButton(title: language.text("안내를 줄여 한 판 더", "Another hand with less help")) { hand.replay(lessGuidance: true) }
                    .accessibilityIdentifier("guided-hand-less-help")
                GTChoiceButton(title: language.text("플레이로 이동", "Go to Play"), minHeight: 52, action: onPlay)
                    .accessibilityIdentifier("guided-hand-play")
                GTChoiceButton(title: language.text("안내와 함께 다시", "Replay with guidance"), minHeight: 52) { hand.replay(lessGuidance: false) }
            }
        }.padding(.top, 12)
    }
    private func previous() { if hand.page == 0 { onClose() } else { hand.previous() } }
    private var title: some View {
        let korean = [["두 사람이 한 판을 해요"], ["플롭 전", "같은 금액 맞추기"], ["플롭 · 세 장"],
                      ["턴 · 한 장 더"], ["리버 · 마지막 한 장"], ["쇼다운 · 다섯 장 비교"], ["한 판 돌아보기"]]
        let english = [["Two players, one hand"], ["Before the flop", "Match the bet"], ["Flop · three cards"],
                       ["Turn · one more card"], ["River · the final card"], ["Showdown · best five"], ["Review the hand"]]
        return LessonPairedText(korean: korean[hand.page], english: english[hand.page])
    }
    @ViewBuilder private var context: some View {
        switch hand.page {
        case 0:
            LessonPairedText(korean: ["딜러 자리에서 시작해요.", "작은 블라인드로 1칩을 내요.", "상대는 큰 블라인드로 2칩을 내요.",
                                     "플롭 전에는 딜러부터 행동해요.", "플롭 이후에는 상대부터 행동해요.", "각자 두 장을 받고 시작해요."],
                             english: ["You start in the dealer seat.", "You pay the 1-chip small blind.", "The opponent pays a 2-chip big blind.",
                                       "You act first before the flop.", "The opponent acts first after the flop.", "Each gets two private cards."])
        case 1:
            LessonPairedText(korean: ["작은 블라인드로 1칩을 냈어요.", "상대는 2칩. 콜은 몇 칩 더 낼까요?", "이번 예시에서는 콜해요.", "상대는 이어서 체크해요."],
                             english: ["Your blind: 1 chip. Opponent: 2.", "How much more to call?", "In this example, you call.", "The opponent then checks."])
        case 2:
            LessonPairedText(korean: ["상대가 체크했어요.", "칩 없이 넘기는 행동은 뭘까요?", "이번 예시에서는 둘 다 체크해요."],
                             english: ["The opponent checked.", "How can you pass for free?", "Both check in this example."])
        case 3:
            LessonPairedText(korean: ["상대가 2칩을 냈어요.", "콜하려면 몇 칩을 내야 할까요?", "이번 예시에서는 콜해요.", "항상 콜하라는 조언은 아니에요."],
                             english: ["The opponent bets 2 chips.", "How much does a call cost?", "In this example, you call.", "This isn't advice for every hand."])
        case 4:
            LessonPairedText(korean: ["상대가 체크했어요.", "이번 예시에서는 체크할 거예요.", "칩을 더 내야 할까요?", "둘 다 체크한 뒤 카드를 공개해요."],
                             english: ["The opponent checks.", "You will check in this example.", "Must you pay more?", "After both check, show the cards."])
        case 5:
            LessonPairedText(korean: ["내 두 장과 공용 카드 다섯 장으로", "각자의 가장 좋은 다섯 장을 비교해요.", "누가 팟을 가져갈까요?"],
                             english: ["Use your two and five shared cards.", "Compare each player's best five.", "Who gets the pot?"])
        default:
            LessonPairedText(korean: ["이번 판으로 규칙을 확인했어요.", "다음 판은 힌트를 줄여 해볼까요?"],
                             english: ["You practised the rules.", "Try another hand with less help."])
        }
    }
    @ViewBuilder private var cue: some View {
        switch hand.page {
        case 1:
            LessonPairedText(korean: ["콜은 상대 금액에 맞추는 행동이에요."], english: ["A call matches their bet."])
        case 2, 4:
            LessonPairedText(korean: ["받을 베팅이 없으면 체크할 수 있어요."], english: ["With no bet to match, you can check."])
        case 3:
            LessonPairedText(korean: ["이번 베팅의 금액을 맞춰요."], english: ["Match this bet, not the pot."])
        default:
            LessonPairedText(korean: ["먼저 다섯 장의 족보를 비교해요.", "족보가 같으면 숫자를 비교해요."],
                             english: ["Compare the best-five hand types.", "Same type? Compare the ranks."])
        }
    }
    @ViewBuilder private func feedback(correct: Bool) -> some View {
        let koreanPrefix = correct ? "맞아요." : "다시 짚어볼게요."
        let englishPrefix = correct ? "That's right." : "Let's look again."
        if hand.page == 5 {
            let korean = gradeShowdown(answer: hand.answers[5] ?? 0, spot: hand.showdown, language: .korean)
            let english = gradeShowdown(answer: hand.answers[5] ?? 0, spot: hand.showdown, language: .english)
            let sameType = hand.showdown.heroBest.category == hand.showdown.villainBest.category
            LessonPairedText(korean: [koreanPrefix, "내 패: \(korean.heroName)", "상대 패: \(korean.villainName)",
                                     sameType ? "더 높은 쌍이 이겨요." : "더 높은 족보가 이겨요.",
                                     HandOutcomeCopy.answer(korean.winner, in: .korean)],
                             english: [englishPrefix, "Your hand: \(english.heroName)", "Their hand: \(english.villainName)",
                                       sameType ? "The higher pair wins." : "The higher hand type wins.",
                                       HandOutcomeCopy.answer(english.winner, in: .english)])
        } else {
            let lines: (korean: [String], english: [String])
            switch hand.page {
            case 1:
                lines = (["2 − 1 = 1칩을 더 내요.", "둘 다 총 2칩을 냈어요.", "팟은 4칩이 돼요."],
                         ["2 − 1 = 1 more chip.", "Both have paid 2 chips.", "The pot is now 4 chips."])
            case 2:
                lines = (["체크에는 추가 칩이 없어요.", "팟은 4칩 그대로예요."],
                         ["A check costs no more chips.", "The pot stays at 4 chips."])
            case 3:
                lines = (["2칩을 콜해요.", "상대의 2칩과 내 2칩이 더해져요.", "팟은 8칩이 돼요."],
                         ["You call 2 chips.", "Their 2 plus your 2 adds 4.", "The pot is now 8 chips."])
            default:
                lines = (["체크에는 추가 칩이 없어요.", "팟은 8칩 그대로예요."],
                         ["A check costs no more chips.", "The pot stays at 8 chips."])
            }
            LessonPairedText(korean: [koreanPrefix] + lines.korean, english: [englishPrefix] + lines.english)
        }
    }
    private var choices: [(Int, String)] {
        switch hand.page {
        case 1: [(1, language.text("1칩", "1 chip")), (2, language.text("2칩", "2 chips"))]
        case 2: [(0, language.text("체크", "Check")), (1, language.text("베팅", "Bet"))]
        case 3: [(2, language.text("2칩", "2 chips")), (4, language.text("4칩", "4 chips"))]
        case 4: [(0, language.text("추가 칩 없음", "No additional chips")), (1, language.text("1칩", "1 chip"))]
        default: [(0, language.text("내가 이겨요", "You win")), (1, language.text("상대가 이겨요", "Opponent wins")), (2, language.text("나눠 가져요", "Split the pot"))]
        }
    }
}
