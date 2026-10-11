import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class NumericalTeachingTests: XCTestCase {
    func testSavedOutsRevealDraftAndWalkthroughStillImportAndReload() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = ProgressionStore(url: dir.appendingPathComponent("progress.json"))
        // Round ordinal zero regenerates index two; retain the audit's exact spot.
        let seed = UInt64(0xA0D17) &+ UInt64(33) &* 0x9E37_79B9_7F4A_7C15
        XCTAssertEqual(OutsSpotGenerator.spot(baseSeed: seed, index: 2).outCount, 3)
        for mode in 0..<3 {
            var state = ProgressState()
            var round = PracticeRound(id: "saved-outs", concept: Concept.outs.rawValue, seed: seed)
            round.showBeatIndex = BeatScript.outs(OutsSpotGenerator.spot(baseSeed: seed, index: 0)).count - 1
            if mode == 0 {
                round.introPhase = .show
            } else if mode == 1 {
                round.draft = SavedDrillDraft(ordinal: 0, concept: Concept.outs.rawValue, input: .integerText("3"))
            } else {
                round.phase = .reveal
                round.answers = [RoundAnswer(attemptID: "audit-answer", ordinal: 0, band: .spotOn,
                    submittedAt: Date(timeIntervalSince1970: 1_790_000_000),
                    input: try JSONEncoder().encode(SavedDrillInput.integer(3)),
                    reveal: try JSONEncoder().encode(SavedDrillReveal(band: GradeBand.spotOn.rawValue)))]
            }
            state.activeRound = round
            let imported = try store.importData(JSONEncoder().encode(state))
            try store.save(imported)
            guard case let .loaded(restored) = store.load() else { return XCTFail("saved outs must reload") }
            XCTAssertEqual(restored.activeRound, round)
        }
    }

    func testEVSignIncludesBreakEvenWithoutChangingGrade() {
        for equity in [20.0, 25.0, 30.0] {
            let spot = EVCallSpot(pot: 20, bet: 10, equityPct: equity, didWin: false)
            let estimate = Estimate(point: spot.evBB, lo: spot.evBB, hi: spot.evBB)
            let ko = gradeEVCall(estimate: estimate, spot: spot)
            XCTAssertEqual(ko.band, .spotOn)
            XCTAssertEqual(ko.correct, (equity - 25) * 0.4, accuracy: 1e-9)
            XCTAssertTrue(ko.whyText.contains(equity < 25 ? "손해" : (equity > 25 ? "이득" : "본전")))
            let en = BeatScript.evCall(spot, language: .english)[3].detail ?? ""
            XCTAssertTrue(en.contains(equity < 25 ? "loses" : (equity > 25 ? "earns" : "breaks even")))
            XCTAssertTrue((BeatScript.evCall(spot)[3].detail ?? "").contains(equity < 25 ? "손해" : (equity > 25 ? "이득" : "본전")))
        }
    }

    func testPFRDenominatorIsAllHandsForCallingStation() {
        let spot = RangeReadSpot(archetype: .station, action: .called(seat: .btn, opener: .utg), archetypeShown: true)
        let ko = BeatScript.rangeRead(spot)[2].detail ?? ""
        XCTAssertTrue(ko.contains("전체 핸드 중 40%"))
        XCTAssertTrue(ko.contains("전체 핸드 중 10%"))
        XCTAssertTrue(ko.contains("30%p"))
        let en = BeatScript.rangeRead(spot, language: .english)[2].detail ?? ""
        XCTAssertTrue(en.contains("40% of all hands"))
        XCTAssertTrue(en.contains("10% of all hands"))
    }

    func testAuditAheadSeedIdentityAndTruthfulWalkthrough() {
        let spot = OutsSpotGenerator.spot(baseSeed: 0xA0D17, index: 35)
        XCTAssertEqual(spot.hero, Card.parse("Js4h")!)
        XCTAssertEqual(spot.villain, Card.parse("3hJh")!)
        XCTAssertEqual(spot.board, Card.parse("8d2sJcAc")!)
        XCTAssertEqual(spot.outCount, 3)
        XCTAssertEqual(gradeOuts(estimate: 3, spot: spot).band, .spotOn)
        XCTAssertEqual(BeatScript.outs(spot).count, 5)
        XCTAssertTrue((BeatScript.outs(spot)[2].detail ?? "").hasPrefix("지금은 앞서"))
        XCTAssertTrue((BeatScript.outs(spot, language: .english)[2].detail ?? "").contains("You are ahead"))
        XCTAssertFalse(BeatScript.outs(spot).contains { ($0.detail ?? "").contains("내가") })
        XCTAssertFalse(BeatScript.outs(spot, language: .english).contains { ($0.detail ?? "").contains("take the lead") })
        let tied = OutsSpot(hero: Card.parse("Js3h")!, villain: Card.parse("Jd3c")!, board: spot.board, outs: [], excluded: [])
        XCTAssertTrue((BeatScript.outs(tied)[2].detail ?? "").contains("무승부"))
        XCTAssertTrue((BeatScript.outs(tied, language: .english)[2].detail ?? "").contains("tied now"))
    }

    func testAuditExcludedRiverTieAndLossReasonsInBothLanguages() {
        let spot = OutsSpotGenerator.spot(baseSeed: 0xA0D17, index: 116)
        XCTAssertEqual(spot.hero, Card.parse("Qc9c")!)
        XCTAssertEqual(spot.villain, Card.parse("2hJd")!)
        XCTAssertEqual(spot.board, Card.parse("4s9sJsKs")!)
        XCTAssertFalse(spot.outs.contains(Card("2s")!))
        XCTAssertTrue(spot.excluded.contains(Card("2s")!))
        let tie = explainRiver(spot: spot, river: Card("2s")!)
        XCTAssertTrue(tie.isTie)
        XCTAssertFalse(tie.heroWins)
        let losingSpot = OutsSpot(hero: Card.parse("AhKh")!, villain: Card.parse("QsQd")!, board: Card.parse("Qh7h2s3c")!, outs: Card.parse("4h5h6h8h9hThJh")!, excluded: Card.parse("2h3h")!)
        let loss = explainRiver(spot: losingSpot, river: Card("2h")!)
        XCTAssertFalse(loss.isTie)
        XCTAssertFalse(loss.heroWins)
        for language in LearningLanguage.allCases {
            let beats = BeatScript.outs(spot, language: language)
            XCTAssertEqual(beats.count, 8)
            let detail = beats.first { !$0.struck.isEmpty }?.detail ?? ""
            let why = gradeOuts(estimate: spot.outCount, spot: spot, language: language).whyText
            for text in [detail, why] {
                XCTAssertTrue(text.contains(language == .korean ? "무승부" : "tie the hand"))
                XCTAssertFalse(text.contains(language == .korean ? "상대가 이겨" : "opponent ahead"))
            }
            let lossWhy = gradeOuts(estimate: 7, spot: losingSpot, language: language).whyText
            XCTAssertTrue(lossWhy.contains(language == .korean ? "상대가 이겨" : "opponent ahead"))
            XCTAssertFalse(lossWhy.contains(language == .korean ? "무승부" : "tie the hand"))
            XCTAssertTrue((beats[2].detail ?? "").contains(language == .korean ? "상대가 앞서" : "opponent is ahead"))
        }
    }

    func testAllTieEquityIsPotShareRatherThanOutrightWinningChance() {
        let hero = Card.parse("AhKd")!, villain = Card.parse("AsKc")!, board = Card.parse("2h3d4s5c")!
        let equity = exactEquityHeadsUp(hero: hero, villain: villain, board: board)
        XCTAssertEqual(equity.wins, 0)
        XCTAssertEqual(equity.equity, 0.5)
        let spot = CallFoldSpot(hero: hero, villain: villain, board: board, pot: 20, bet: 10, equityPct: equity.equity * 100)
        for language in LearningLanguage.allCases {
            let reveal = gradeCallFold(userCalls: true, spot: spot, language: language)
            XCTAssertEqual(reveal.band, .spotOn)
            XCTAssertEqual(reveal.equityPct, 50)
            XCTAssertTrue(reveal.whyText.contains(language == .korean ? "무승부 몫을 포함한 팟 지분" : "share of the pot, including ties"))
        }
    }
}
