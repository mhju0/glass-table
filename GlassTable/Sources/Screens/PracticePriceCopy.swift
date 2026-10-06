import GlassTableDrills

/// A no-tie fraction illustrates the threshold; actual equity includes split pots.
enum PracticePriceCopy {
    static func threshold(_ percent: Int, language: LearningLanguage) -> String {
        let basis = language.text("본전의 기준은 팟 지분(에쿼티) \(percent)%예요. 이길 확률과 무승부 때 받는 지분을 함께 세요.",
                                  "Break-even equity is \(percent)%. It counts wins and your share of ties.")
        let fraction: String?
        switch percent {
        case 25: fraction = language.text("무승부가 없다면 네 번 중 한 번에 해당해요.", "Without ties, that's one in four.")
        case 33: fraction = language.text("무승부가 없다면 약 세 번 중 한 번에 해당해요.", "Without ties, that's about one in three.")
        case 50: fraction = language.text("무승부가 없다면 두 번 중 한 번에 해당해요.", "Without ties, that's one in two.")
        default: fraction = nil
        }
        return [basis, fraction].compactMap { $0 }.joined(separator: " ")
    }
}
