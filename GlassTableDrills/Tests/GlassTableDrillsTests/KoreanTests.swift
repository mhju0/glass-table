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

    /// Latin and digit tails follow their Korean reading. "BTN는" shipped: the seat is
    /// read 버튼, so it takes 은. Rank letters (A, K, Q, J, T) stay vowel endings.
    func testNonHangulTailsFollowTheirKoreanReading() {
        XCTAssertEqual(KO.subject("K"), "K가")
        XCTAssertEqual(KO.topic("A"), "A는")
        XCTAssertEqual(KO.topic("BTN"), "BTN은")
        XCTAssertEqual(KO.topic("UTG+1"), "UTG+1은")
        XCTAssertEqual(KO.topic("UTG"), "UTG는")
        XCTAssertEqual(KO.subject("CO"), "CO가")
        XCTAssertEqual(KO.and("SB"), "SB와")
        XCTAssertEqual(KO.and("BTN"), "BTN과")
        XCTAssertEqual(KO.topic("77"), "77은")
        XCTAssertEqual(KO.topic("A9s"), "A9s는")
        XCTAssertEqual(KO.subject("10"), "10이")
        XCTAssertEqual(KO.subject("2"), "2가")
        XCTAssertEqual(KO.subject(""), "가")
        XCTAssertEqual(KO.copula("Nit"), "Nit이에요.")
        XCTAssertEqual(KO.copula("TAG"), "TAG예요.")
        XCTAssertEqual(KO.topic("7♥·8♥"), "7♥·8♥는")
    }

    /// 로 after a vowel or ㄹ, 으로 after any other final consonant: "벳 20로" shipped.
    func testInstrumentalParticleTreatsRieulLikeAVowel() {
        XCTAssertEqual(KO.instrumental("20"), "20으로")
        XCTAssertEqual(KO.instrumental("12"), "12로")
        XCTAssertEqual(KO.instrumental("7"), "7로")
        XCTAssertEqual(KO.instrumental("트리플"), "트리플로")
        XCTAssertEqual(KO.instrumental("팟"), "팟으로")
        XCTAssertEqual(KO.instrumental("하이"), "하이로")
    }

    /// Every seat name takes the particle its reading calls for.
    func testEverySeatTakesTheRightTopicParticle() {
        let consonant: Set<String> = ["BTN", "UTG+1"]
        for seat in Position.allCases {
            XCTAssertEqual(KO.topic(seat.rawValue),
                           seat.rawValue + (consonant.contains(seat.rawValue) ? "은" : "는"))
        }
    }

    /// iOS breaks a line between a digit or % and the Hangul after it ("최소 100 / 핸드",
    /// "상위 9% / 를"), splitting one 어절. A word joiner removes that break opportunity.
    func testWordJoinedKeepsDigitsAndParticlesTogether() {
        XCTAssertEqual(KO.wordJoined("최소 100핸드"), "최소 100\u{2060}핸드")
        XCTAssertEqual(KO.wordJoined("상위 9%를 열어요."), "상위 9%\u{2060}를 열어요.")
        XCTAssertEqual(KO.wordJoined("내 콜 8을 가져와요"), "내 콜 8\u{2060}을 가져와요")
        XCTAssertEqual(KO.wordJoined("20bb예요, AKs를, (EV)는"), "20bb\u{2060}예요, AKs\u{2060}를, (EV)\u{2060}는")
    }

    /// Spaces stay break opportunities, and text without such a boundary is unchanged.
    func testWordJoinedLeavesOrdinaryBreaksAlone() {
        XCTAssertEqual(KO.wordJoined("팟 12bb + 상대 벳 4bb"), "팟 12bb + 상대 벳 4bb")
        XCTAssertEqual(KO.wordJoined("플랍 3 장"), "플랍 3 장")
        XCTAssertEqual(KO.wordJoined("핸드 100"), "핸드 100")
        XCTAssertEqual(KO.wordJoined("Pot 12bb"), "Pot 12bb")
        XCTAssertEqual(KO.wordJoined(""), "")
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
