import Testing
import GlassTableEngine
@testable import GlassTableDrills

/// The per-hand score line must agree with the rule card above it: the same words,
/// the same rank spelling, and no step that reads as a false equation.
struct ChenScoreCopyTests {
    private func hand(_ name: String) -> HandClass { HandClass.all.first { $0.description == name }! }

    @Test func theLineShowsEachRuleTheHandUsesInBothLanguages() {
        let lines: [(String, String, String)] = [
            ("AKs", "A 10 · same suit +2 · no gap = 12", "A 10 · 같은 무늬 +2 · 간격 없음 = 12"),
            ("22", "2 1 point × 2 = 2 → pair minimum 5 = 5", "2 1점 × 2 = 2 → 페어 최소 5 = 5"),
            ("97o", "9 4.5 · 1 missing rank −1 · both below Q +1 = 4.5",
             "9 4.5 · 빈 숫자 1개 −1 · 둘 다 Q보다 낮음 +1 = 4.5"),
            ("72o", "7 3.5 · 4 missing ranks −5 = −1.5", "7 3.5 · 빈 숫자 4개 −5 = −1.5"),
        ]
        for (name, english, korean) in lines {
            #expect(DrillTerms.chen(hand(name), in: .english) == english)
            #expect(DrillTerms.chen(hand(name), in: .korean) == korean)
        }
    }

    @Test func tenIsSpelledTheSameWayInBothLanguages() {
        #expect(DrillTerms.chen(hand("TT"), in: .english) == "10 5 points × 2 = 10")
        #expect(DrillTerms.chen(hand("TT"), in: .korean) == "10 5점 × 2 = 10")
        for language in [LearningLanguage.english, .korean] {
            #expect(!DrillTerms.chen(hand("KTs"), in: language).contains("T "))
        }
    }

    /// Every line ends on the engine's score, so the copy can never drift from it.
    @Test func everyLineEndsOnTheEngineScore() {
        for h in HandClass.all {
            let score = Chen.score(h)
            let text = abs(score - score.rounded()) < 0.01 ? "\(Int(score.rounded()))"
                : String(format: "%.1f", score)
            let expected = " = " + (score < 0 ? "−" + text.dropFirst() : Substring(text))
            for language in [LearningLanguage.english, .korean] {
                #expect(DrillTerms.chen(h, in: language).hasSuffix(String(expected)), "\(h)")
            }
        }
    }

    @Test func theRuleCardNamesItsSourceAndItsLimit() throws {
        let aks = try #require(Card.parse("AsKs"))
        #expect(ChenScoreCopy.title(in: .english) == "How the score works")
        #expect(ChenScoreCopy.title(in: .korean) == "점수 계산법")
        #expect(ChenScoreCopy.rules(in: .english).count == 5)
        #expect(ChenScoreCopy.rules(in: .korean).count == 5)
        #expect(ChenScoreCopy.handLine(aks, in: .english) == "Your hand A♠K♠: A 10 · same suit +2 · no gap = 12")
        #expect(ChenScoreCopy.handLine(aks, in: .korean) == "내 패 A♠K♠: A 10 · 같은 무늬 +2 · 간격 없음 = 12")
        let dealtLowFirst = try #require(Card.parse("6sKs"))
        #expect(ChenScoreCopy.handLine(dealtLowFirst, in: .english).hasPrefix("Your hand K♠6♠: K 8"))
        #expect(ChenScoreCopy.intro(in: .english).contains("Bill Chen"))
        #expect(ChenScoreCopy.closing(in: .english) == "It sorts hands for the chart. It is not your chance of winning.")
        #expect(ChenScoreCopy.closing(in: .korean) == "차트용으로 패를 줄 세우는 점수예요. 이길 확률이 아니에요.")
    }
}
