import Foundation

public enum LearningLanguage: String, Codable, CaseIterable, Sendable {
    case korean = "ko"
    case english = "en"

    public func text(_ korean: String, _ english: String) -> String {
        self == .korean ? korean : english
    }

    public static func preferred(in identifiers: [String]) -> Self {
        for identifier in identifiers {
            let code = identifier.lowercased().split(separator: "-").first
            if code == "ko" { return .korean }
            if code == "en" { return .english }
        }
        return .english
    }
}

public extension Archetype {
    func beginnerTitle(in language: LearningLanguage) -> String {
        switch self {
        case .nit: language.text("신중형", "Cautious")
        case .tag: language.text("선별형", "Selective")
        case .lag: language.text("공격형", "Aggressive")
        case .station: language.text("콜 위주형", "Caller")
        case .maniac: language.text("매우 공격형", "Very aggressive")
        }
    }

    func beginnerDescription(in language: LearningLanguage) -> String {
        switch self {
        case .nit: language.text("좋은 카드를 기다렸다가 들어와요", "Waits for strong cards before joining")
        case .tag: language.text("카드를 골라서 들어오고, 들어오면 자주 올려요", "Chooses hands carefully, then often raises")
        case .lag: language.text("여러 카드로 들어오고 자주 올려요", "Joins with more hands and often raises")
        case .station: language.text("자주 들어오지만 금액은 잘 올리지 않아요", "Joins often but rarely raises")
        case .maniac: language.text("아주 자주 들어오고 금액도 자주 올려요", "Joins very often and frequently raises")
        }
    }
}

public struct ConceptIntroduction: Sendable {
    public let title: String
    public let why: String
    public let how: String

    public static func make(_ concept: Concept, language: LearningLanguage) -> Self {
        let copy: (String, String, String, String, String, String)
        switch concept {
        case .showdown:
            copy = ("누가 이길까요?", "Who wins?", "두 패를 비교하면 승자가 보여요.", "Compare two hands to find the winner.", "내 카드와 공용 카드로 가장 좋은 다섯 장을 찾아요.", "Find the best five cards using each player's cards and the shared cards.")
        case .potMath:
            copy = ("팟에 든 칩 세기", "Count the pot", "함께 모인 칩을 알면 다음 선택의 가격을 알 수 있어요.", "Knowing the chips in the middle helps you judge the next price.", "각 행동으로 새로 들어온 칩을 더해요. 포기한 사람이 낸 칩도 남아요.", "Add the chips each action puts in. Chips from players who fold stay in the pot.")
        case .position:
            copy = ("누가 먼저 행동할까요?", "Who acts first?", "나중에 행동하면 앞사람의 선택을 더 볼 수 있어요.", "Acting later lets you see more choices before making yours.", "버튼을 찾고, 공용 카드가 나오기 전과 후의 순서를 비교해요.", "Find the dealer button. Compare the order before and after shared cards appear.")
        case .combos:
            copy = ("가능한 두 장 조합", "Possible two-card hands", "상대가 가질 수 있는 카드는 보이는 카드에 따라 달라져요.", "Visible cards change which hands an opponent can hold.", "보이는 카드와 겹치는 조합을 빼고 남은 수를 세요.", "Remove combinations that use visible cards, then count what remains.")
        case .potOdds:
            copy = ("콜하려면 얼마나 자주 이겨야 할까요?", "How often must I win to call?", "이길 가능성과 내야 할 가격을 함께 봐야 해요.", "Your chance of winning needs to justify the price.", "지금 낼 금액을 콜한 뒤의 전체 팟으로 나눠요.", "Divide the amount to call by the whole pot after your call.")
        case .outs:
            copy = ("역전할 카드는 몇 장일까요?", "Which cards turn it around?", "더 좋아지는 카드가 모두 이기는 카드는 아니에요.", "Not every card that improves your hand makes it win.", "마지막 공용 카드 중 상대를 이기게 만드는 카드만 세요.", "Count only unseen final cards that make your hand beat the opponent.")
        case .equitySense:
            copy = ("끝까지 가면 이길 가능성", "Chances at the final reveal", "카드가 더 나와도 유리한지 가늠해 봐요.", "Estimate how often your cards will hold up.", "승률을 예상하고, 답이 들어갈 만한 범위도 골라요. 무승부는 몫을 나눠요.", "Estimate your chance and a plausible range. Ties count as a share of the pot.")
        case .evCall:
            copy = ("이 콜의 평균 손익", "What is this call worth?", "한 번의 결과보다 같은 결정을 반복했을 때의 평균을 봐요.", "Look beyond one result to the average over repeated decisions.", "이길 때 얻는 금액과 질 때 잃는 금액을 각각의 확률로 따져요.", "Weigh what you win and lose by the chance of each outcome.")
        case .callFold:
            copy = ("콜할까요, 포기할까요?", "Call or fold?", "좋은 카드라도 가격이 너무 높을 수 있어요.", "Even a promising hand can cost too much to continue.", "이길 가능성과 콜에 필요한 승률을 비교해요.", "Compare your chance of winning with the break-even chance for the call.")
        case .rangeNotation:
            copy = ("짧은 핸드 표기 읽기", "Read hand shorthand", "짧은 표기 하나가 여러 시작 카드를 뜻해요.", "One short label can describe many starting hands.", "같은 숫자, 같은 무늬, 다른 무늬를 구분하고 조합 수를 세요.", "Separate pairs, same-suit hands and different-suit hands, then count combinations.")
        case .rfi:
            copy = ("먼저 들어갈까요?", "Should I enter first?", "뒤에 남은 사람이 많으면 더 신중히 골라요.", "With more players still to act, you need to be more selective.", "자리와 카드를 공개된 연습 차트에서 찾아요.", "Find your position and cards in the published practice chart.")
        case .rangeRead:
            copy = ("상대의 가능한 카드", "What could they hold?", "상대에게 한 가지 패만 있다고 생각하지 않아요.", "Think about several possible hands, not just one guess.", "보이는 카드와 조건에 맞는 조합이 얼마나 남는지 살펴봐요.", "Count the combinations that fit the visible cards and the stated condition.")
        case .hitFrequency:
            copy = ("공용 카드와 잘 맞을까요?", "How many hands connect?", "같은 보드라도 시작 카드에 따라 연결되는 정도가 달라요.", "The same board connects differently with different starting hands.", "가능한 핸드 중 같은 숫자 두 장 이상을 만든 비율을 예상해요.", "Estimate the share of possible hands that made at least a pair.")
        case .rangeAdvantage:
            copy = ("어느 쪽 카드가 더 유리할까요?", "Whose possible hands are favored?", "강한 핸드를 더 자주 가진 쪽을 살펴봐요.", "Compare which side holds strong hands more often.", "같은 보드에서 두 핸드 범위의 평균 승률을 예상해요.", "Estimate how one range fares against the other on the same board.")
        case .evLoss:
            copy = ("더 나은 선택과의 차이", "Compare the value of choices", "이기고 졌는지만으로 선택을 판단하지 않아요.", "A single win or loss does not tell you whether a choice was good.", "콜과 폴드의 평균값을 비교해 가장 나은 선택을 골라요.", "Compare the average values of calling and folding.")
        case .actionRead:
            copy = ("행동 뒤에 남는 핸드", "Hands behind an action", "상대의 공개된 행동 규칙으로 가능한 패를 좁혀요.", "Use the opponent's published rules to narrow the possible hands.", "행동 뒤에 남은 조합 중 페어 이상인 비율을 예상해요.", "After the action, estimate how many remaining combinations have at least a pair.")
        case .defend:
            copy = ("상대가 먼저 올렸어요", "An opponent raised", "상대가 들어오는 카드의 폭에 맞춰 대응해요.", "Respond to how wide a set of hands the opponent enters with.", "내 카드를 차트에서 찾아 포기, 따라가기, 다시 올리기 중 골라요.", "Use your cards and the chart to choose fold, call, or raise again.")
        case .mdf:
            copy = ("얼마나 자주 계속할까요?", "How often should I continue?", "너무 자주 포기하면 상대의 빈 베팅도 이익이 될 수 있어요.", "Folding too often can make an opponent's empty bets profitable.", "팟과 베팅 크기로 전체 방어 비율을 구해요. 특정 카드의 정답은 아니에요.", "Use the pot and bet to find an overall defending frequency, not a rule for one hand.")
        }
        return Self(title: language.text(copy.0, copy.1), why: language.text(copy.2, copy.3), how: language.text(copy.4, copy.5))
    }
}
