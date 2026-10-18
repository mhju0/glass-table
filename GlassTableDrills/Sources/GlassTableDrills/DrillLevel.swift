// Copyright (c) 2026 Michael Ju (github.com/mhju0)

/// A skill's step (D53): the same skill dealt harder. The learner never picks one; the
/// path deals each skill at the step it has reached. Steps are 1, 2 and 3 on screen;
/// the names Learn, Apply and Sharp are for code and docs only.
///
/// Adding steps to a skill is one uniform change:
/// 1. In its generator's `spot(baseSeed:index:level:)`, keep the `.learn` path exactly
///    as it is (`LearnSpotGoldenTests` freezes it) and deal `.apply` / `.sharp` from a
///    separate seed stream. Every call site already passes the level.
/// 2. Raise the skill in `highest(for:)`, and add its line in `headline(for:in:)`.
/// 3. If its sharp answer is typed, add it to `typesExactAnswer(_:)`; if the drill
///    shows anything differently per step, read `\.drillLevel` in its app view.
/// 4. Add property tests for the new steps. The step nodes (`<id>.2`, `<id>.3`), the
///    step order, promotion and the schema-5 upgrade follow from `highest(for:)`. Once
///    schema 5 has shipped, raising a skill there changes what an upgraded file means,
///    so it also needs a schema bump that reruns `ProgressionStore.markStepsReached`.
public enum DrillLevel: Int, Codable, CaseIterable, Comparable, Sendable {
    case learn = 1, apply = 2, sharp = 3

    public static func < (lhs: DrillLevel, rhs: DrillLevel) -> Bool { lhs.rawValue < rhs.rawValue }

    /// The highest step a skill has. A skill at `.learn` has only its first lesson, and
    /// its promotion rule is the one it had before steps existed.
    public static func highest(for concept: Concept) -> DrillLevel {
        switch concept {
        case .showdown, .potMath, .callFold: .sharp
        case .outs: .sharp
        case .equitySense: .sharp
        case .potOdds: .sharp
        case .combos: .sharp
        case .rangeNotation: .sharp
        case .evCall: .sharp
        case .position: .sharp
        case .rfi: .sharp
        case .defend: .sharp
        case .rangeRead: .sharp
        case .actionRead: .sharp
        default: .learn
        }
    }

    /// This step, or the skill's highest when it has fewer.
    public func capped(for concept: Concept) -> DrillLevel {
        min(self, Self.highest(for: concept))
    }

    /// Whether the answer is typed as an exact number at this step instead of picked
    /// from choices (owner default 2: counts are typed at Sharp).
    public func typesExactAnswer(_ concept: Concept) -> Bool {
        guard self == .sharp else { return false }
        switch concept {
        case .potMath: return true
        case .outs: return true
        case .combos: return true
        case .rangeNotation: return true
        case .position: return true
        default: return false
        }
    }

    /// The one line a step's lesson opens with: what is new at this step. Nil at the
    /// first step, which needs no introduction.
    public func headline(for concept: Concept, in language: LearningLanguage) -> String? {
        let step = language.text("\(rawValue)단계", "Step \(rawValue)")
        let what: String
        switch (concept, self) {
        case (_, .learn): return nil
        case (.showdown, .apply): what = language.text("같은 족보끼리 겨뤄요", "Same hand type, closer calls")
        case (.showdown, .sharp): what = language.text("무승부와 공용 카드가 정하는 판", "Ties and boards that play")
        case (.potMath, .apply): what = language.text("더 다양한 베팅", "More varied betting")
        case (.potMath, .sharp): what = language.text("플랍 베팅까지, 직접 입력", "Through the flop, typed")
        case (.callFold, .apply): what = language.text("필요한 몫만 보여요", "Only the price is shown")
        case (.callFold, .sharp): what = language.text("숫자 없이, 아슬아슬한 판", "No numbers, close spots")
        case (.outs, .apply): what = language.text("함정이 있는 아웃", "Outs with a catch")
        case (.outs, .sharp): what = language.text("함정이 있는 아웃, 직접 입력", "Outs with a catch, typed")
        case (.equitySense, .apply): what = language.text("팽팽한 승부", "Close matchups")
        case (.equitySense, .sharp): what = language.text("팽팽한 승부, 더 가까운 보기", "Close matchups, closer choices")
        case (.potOdds, .apply): what = language.text("더 다양한 벳 크기", "More bet sizes")
        case (.potOdds, .sharp): what = language.text("먼저 콜한 사람이 있어요", "Someone has already called")
        case (.combos, .apply): what = language.text("보이는 카드가 더 많아요", "More cards in sight")
        case (.combos, .sharp): what = language.text("보이는 카드가 더 많아요, 직접 입력", "More cards in sight, typed")
        case (.rangeNotation, .apply): what = language.text("표기가 서너 개", "Three or four parts")
        case (.rangeNotation, .sharp): what = language.text("표기가 서너 개, 직접 입력", "Three or four parts, typed")
        case (.evCall, .apply): what = language.text("더 다양한 벳 크기", "More bet sizes")
        case (.evCall, .sharp): what = language.text("보기 없이 직접 맞춰요", "No choices: set the value")
        case (.position, .apply): what = language.text("0부터 7까지 모두 보기", "Every count from 0 to 7")
        case (.position, .sharp): what = language.text("남은 사람만 세서, 직접 입력", "Only players still in, typed")
        case (.rfi, .apply): what = language.text("차트 경계에 걸친 패", "Hands at the chart's edge")
        case (.rfi, .sharp): what = language.text("어느 자리부터 여는 패인가요", "The first seat that opens it")
        case (.defend, .apply): what = language.text("밴드 경계에 걸친 패", "Hands at a band's edge")
        case (.defend, .sharp): what = language.text("여는 폭 안내 없이", "No opening width given")
        case (.rangeRead, .apply): what = language.text("더 가까운 보기, 상대는 더 자주 숨겨요", "Closer choices, opponent hidden more")
        case (.rangeRead, .sharp): what = language.text("콜만, 모르는 상대, 보기 넷", "Calls only, unknown opponent, four choices")
        case (.actionRead, .apply): what = language.text("10%씩 차이 나는 보기", "Choices 10 points apart")
        case (.actionRead, .sharp): what = language.text("더 가까운 보기, 모르는 상대", "Closer choices, unknown opponent")
        default: return nil
        }
        return "\(step) · \(what)"
    }
}
