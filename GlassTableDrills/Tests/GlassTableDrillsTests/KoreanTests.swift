import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class KoreanTests: XCTestCase {
    /// The bug this exists to prevent: "3 트리플가" shipped to the device, because the
    /// particle was written literally instead of agreeing with the preceding syllable.
    func testSubjectParticleAgreesWithTheFinalConsonant() {
        XCTAssertEqual(KO.subject("트리플"), "트리플이")   // ends in ㄹ
        XCTAssertEqual(KO.subject("풀하우스"), "풀하우스가") // 스: ㅡ, no final consonant
        XCTAssertEqual(KO.subject("하이"), "하이가")
        XCTAssertEqual(KO.subject("원 페어"), "원 페어가")
        XCTAssertEqual(KO.subject("포카드"), "포카드가")
    }

    func testObjectParticleAgreesWithTheFinalConsonant() {
        XCTAssertEqual(KO.object("트리플"), "트리플을")
        XCTAssertEqual(KO.object("하이"), "하이를")
        XCTAssertEqual(KO.object("원 페어"), "원 페어를")
    }

    func testCopulaAgreesWithTheFinalConsonant() {
        XCTAssertEqual(KO.copula("트리플"), "트리플이에요.")
        XCTAssertEqual(KO.copula("하이"), "하이예요.")
    }

    /// Hand names are built from a rank letter plus Korean, so a latin or digit tail
    /// must not be treated as a consonant ending.
    func testNonHangulTailsTakeTheVowelForm() {
        XCTAssertEqual(KO.subject("K"), "K가")
        XCTAssertEqual(KO.subject("10"), "10가")
        XCTAssertEqual(KO.subject(""), "가")
    }

    /// Every hand name the app can print must produce grammatical Korean.
    func testEveryHandNameTakesAParticleWithoutCrashing() {
        for category in 0...8 {
            for rank in 2...14 {
                let name = handName(HandBrief(category: category, topRank: rank))
                XCTAssertFalse(KO.subject(name).isEmpty)
                XCTAssertTrue(KO.subject(name).hasSuffix("이") || KO.subject(name).hasSuffix("가"))
                XCTAssertTrue(KO.object(name).hasSuffix("을") || KO.object(name).hasSuffix("를"))
            }
        }
    }

    /// When both players share a hand name the sentence must name the kicker rather
    /// than saying "3 트리플이 3 트리플을 이겨요", which is true and useless.
    func testEqualHandNamesExplainViaTheKicker() {
        // Board 3-3-5-3-K: both play trip threes; hero's Q kicker beats villain's 10.
        let spot = ShowdownSpot(hero: Card.parse("QdAc")!, villain: Card.parse("Th9s")!,
                                board: Card.parse("3s3d5h3cKs")!)
        let why = gradeShowdown(answer: spot.winner, spot: spot).whyText
        XCTAssertTrue(why.contains("키커"), why)
        XCTAssertFalse(why.contains("트리플가"), "particle must agree: \(why)")
    }

    func testDifferentHandNamesUseAgreeingParticles() {
        let spot = ShowdownSpot(hero: Card.parse("KhKs")!, villain: Card.parse("QhQs")!,
                                board: Card.parse("2c7d9hJc4s")!)
        let why = gradeShowdown(answer: 0, spot: spot).whyText
        XCTAssertTrue(why.contains("원 페어가"), why)
        XCTAssertFalse(why.contains("페어이 "), why)
    }
}
