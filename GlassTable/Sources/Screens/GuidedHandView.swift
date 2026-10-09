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
                    Text(title).font(GT.title(25)).accessibilityIdentifier("guided-hand-page-\(hand.page)")
                    if hand.page == 0 {
                        Text(language.text("한 판을 따라가며 규칙을 확인해요. 선택 뒤에는 설명에 나온 행동으로 이어가요.",
                                           "Follow one hand to learn the rules. After each choice, continue with the action in the explanation."))
                            .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                    }
                    if hand.page > 0 {
                        ThreeRegionCardTable(opponent: hand.page >= 5 ? hand.opponent : [], board: hand.visibleBoard,
                                             hero: hand.hero, opponentTitle: language.text(hand.page >= 5 ? "상대 카드" : "상대 카드 · 아직 비공개", hand.page >= 5 ? "Opponent's cards" : "Opponent's cards · hidden"),
                                             heroTitle: language.text("내 카드", "Your cards"),
                                             highlight: hand.page >= 5 && !hand.needsAnswer ? bestFiveCards((hand.showdown.winner == 0 ? hand.hero : hand.opponent) + hand.board) : [])
                        Text(language.text("팟 \(hand.pot)칩 · 시작 칩 각 20개", "Pot: \(hand.pot) chips · each player started with 20"))
                            .font(GT.semibold(16))
                    }
                    Text(context).font(GT.body(18)).fixedSize(horizontal: false, vertical: true)
                    if !hand.lessGuidance && hand.needsAnswer {
                        Text(cue).font(GT.body(16)).foregroundStyle(GT.inkSecondary)
                    }
                    if let answer = hand.answers[hand.page] {
                        Text(answer == hand.correct ? language.text("맞아요. \(explanation)", "That's right. \(explanation)")
                                                    : language.text("다시 짚어볼게요. \(explanation)", "Let's look again. \(explanation)"))
                            .font(GT.body(17)).padding(16).gtPanel()
                            .accessibilityIdentifier("guided-hand-feedback")
                    }
                    if hand.page == 6 {
                        Text(language.text("각자 4칩을 내서 팟은 8칩이었어요. 가장 좋은 다섯 장을 비교해 이긴 사람은 24칩, 다른 사람은 16칩으로 마쳐요.",
                                           "Each paid 4 chips, making an 8-chip pot. Comparing the best five decides the winner, who finishes with 24 chips; the other player has 16."))
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
    private var title: String {
        language.text(["두 사람이 한 판을 해요", "플롭 전 · 같은 금액 맞추기", "플롭 · 세 장이 열려요", "턴 · 한 장 더", "리버 · 마지막 한 장", "쇼다운 · 다섯 장 비교", "한 판 돌아보기"][hand.page],
                      ["Two players, one hand", "Before the flop · match the bet", "Flop · three shared cards", "Turn · one more card", "River · the final card", "Showdown · compare five", "Review the hand"][hand.page])
    }
    private var context: String {
        switch hand.page {
        case 0: return language.text("딜러 자리에서 작은 블라인드로 1칩을 냈어요. 상대는 큰 블라인드로 2칩을 냈어요. 두 사람일 때는 플롭 전에 딜러가 먼저, 플롭 이후에는 상대가 먼저 행동해요. 각자 두 장을 받고 시작해요.", "You are the dealer and small blind, paying 1 chip. The opponent pays the 2-chip big blind. With two players, the dealer acts first before the flop; the opponent acts first afterward. Each receives two private cards.")
        case 1: return language.text("작은 블라인드로 1칩을 냈고, 상대는 2칩을 냈어요. 콜하려면 몇 칩을 더 내야 할까요? 예시에서는 콜하고 상대는 체크해요.", "You paid 1 chip; the opponent paid 2. How many more chips does a call cost? In this example you call, then the opponent checks.")
        case 2: return language.text("상대가 체크했어요. 칩을 더 내지 않고 차례를 넘기는 행동은 무엇일까요? 예시에서는 둘 다 체크해요.", "The opponent checked. Which action lets you pass without paying more? Both players check in this example.")
        case 3: return language.text("상대가 2칩을 냈어요. 콜하는 데 필요한 칩은 몇 개일까요? 예시에서는 콜해요. 이것이 항상 좋은 전략이라는 뜻은 아니에요.", "The opponent bets 2 chips. How much does calling cost? You call in this example. This does not mean calling is always a good strategy.")
        case 4: return language.text("상대가 체크했어요. 이번 예시에서는 체크할 거예요. 돈을 더 내야 할까요? 둘 다 체크한 뒤 카드를 공개해요.", "The opponent checks. You will check too in this example. Must you pay more? After both check, reveal the cards.")
        case 5: return language.text("각자의 두 장과 공용 카드 다섯 장 중 가장 좋은 다섯 장을 비교해요. 누가 팟을 가져갈까요?", "Compare each player's best five from their two private and five shared cards. Who gets the pot?")
        default: return language.text("이번 선택은 규칙을 확인하는 연습이었어요. 다음 판에서는 먼저 주는 힌트를 줄여볼 수 있어요.", "These choices checked the rules. Try another hand with fewer advance hints.")
        }
    }
    private var cue: String {
        switch hand.page {
        case 1: language.text("콜은 상대가 낸 금액과 같게 맞추는 행동이에요.", "A call matches the opponent's amount.")
        case 2, 4: language.text("받아야 할 베팅이 없으면 체크로 넘길 수 있어요.", "When there is no bet to match, you may check.")
        case 3: language.text("기존 팟이 아니라 이번 베팅을 맞춰요.", "Match the new bet, not the existing pot.")
        default: language.text("가장 좋은 다섯 장의 족보부터 비교해요. 같으면 숫자를 비교해요.", "Compare the category of each best five first, then their ranks if the categories match.")
        }
    }
    private var explanation: String {
        switch hand.page {
        case 1: language.text("2 − 1 = 1칩을 더 내요. 둘 다 총 2칩, 팟은 4칩이 돼요.", "2 − 1 = 1 more chip. Each has paid 2; the pot becomes 4.")
        case 2: language.text("체크는 추가 칩 없이 넘겨요. 팟은 4칩 그대로예요.", "Checking passes without paying. The pot stays at 4.")
        case 3: language.text("2칩을 콜해요. 상대의 2칩과 내 2칩이 더해져 팟은 8칩이에요.", "Call 2 chips. Their 2 and your 2 bring the pot to 8.")
        case 4: language.text("체크에는 추가 칩이 없어요. 팟은 8칩 그대로예요.", "A check costs no additional chips. The pot stays at 8.")
        default: gradeShowdown(answer: hand.answers[5] ?? 0, spot: hand.showdown, language: language).whyText
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
