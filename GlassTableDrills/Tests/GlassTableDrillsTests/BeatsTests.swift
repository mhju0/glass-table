import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class BeatsTests: XCTestCase {

    /// Spec §5.2: templated narration must run on *any* generated spot, not just an
    /// authored one. This is the test that would catch a crash like calling
    /// `bestHand` on a 6-card turn board, or a format string left unfilled.
    func testEveryScriptRunsOnManyGeneratedSpotsAndIsWellFormed() {
        func check(_ beats: [Beat], _ label: String) {
            XCTAssertFalse(beats.isEmpty, "\(label) produced no beats")
            for b in beats {
                XCTAssertFalse(b.caption.trimmingCharacters(in: .whitespaces).isEmpty,
                               "\(label) has an empty caption")
                XCTAssertFalse(b.caption.contains("nil") || (b.detail ?? "").contains("nil"),
                               "\(label) leaked a nil into copy: \(b.caption) / \(b.detail ?? "")")
                XCTAssertFalse(b.caption.contains("Optional"),
                               "\(label) leaked an Optional into copy")
                if case let .grid(cards) = b.focus {
                    XCTAssertFalse(cards.isEmpty, "\(label) showed an empty grid")
                }
            }
        }
        for i in 0..<40 {
            check(BeatScript.showdown(ShowdownSpotGenerator.spot(baseSeed: 11, index: i)), "showdown")
            check(BeatScript.outs(OutsSpotGenerator.spot(baseSeed: 11, index: i)), "outs")
            check(BeatScript.potMath(PotMathSpotGenerator.spot(baseSeed: 11, index: i)), "potMath")
            check(BeatScript.position(PositionSpotGenerator.spot(baseSeed: 11, index: i)), "position")
            check(BeatScript.combos(BlockerSpotGenerator.spot(baseSeed: 11, index: i)), "combos")
            check(BeatScript.potOdds(BetSpotGenerator.spot(baseSeed: 11, index: i)), "potOdds")
            check(BeatScript.mdf(BetSpotGenerator.spot(baseSeed: 11, index: i)), "mdf")
            check(BeatScript.evCall(EVCallSpotGenerator.spot(baseSeed: 11, index: i)), "evCall")
            check(BeatScript.callFold(CallFoldSpotGenerator.spot(baseSeed: 11, index: i)), "callFold")
        }
        // Equity enumerates whole boards, so a smaller sample keeps the suite fast.
        for i in 0..<6 {
            check(BeatScript.equitySense(EquitySenseSpotGenerator.spot(baseSeed: 11, index: i)),
                  "equitySense")
        }
    }

    /// The narration must never claim a draw the spot cannot prove it has.
    /// `excludedCards` is a flush-draw heuristic and is empty otherwise.
    func testOutsScriptOnlyMentionsAFlushWhenTheSpotActuallyHasOne() {
        for i in 0..<200 {
            let s = OutsSpotGenerator.spot(baseSeed: 5, index: i)
            let text = BeatScript.outs(s).map { $0.caption + ($0.detail ?? "") }.joined()
            if s.excluded.isEmpty {
                XCTAssertFalse(text.contains("플러시"),
                               "spot \(i) has no proven flush draw but the script claims one")
            }
        }
    }

    /// The spec's reference script, on the hand 첫 핸드 already uses.
    func testTheReferenceOutsScriptReproducesTheSevenBeatWalkthrough() {
        let spot = OutsSpot(hero: Card.parse("AhKh")!, villain: Card.parse("QsQd")!,
                            board: Card.parse("Qh7h2s3c")!,
                            outs: Card.parse("4h5h6h8h9hThJh")!,
                            excluded: Card.parse("2h3h")!)
        let beats = BeatScript.outs(spot)
        let all = beats.map { $0.caption + " " + ($0.detail ?? "") }.joined(separator: " | ")

        // The hand has no non-flush outs, so the "other outs" beat must not appear.
        XCTAssertEqual(beats.count, 7, all)
        XCTAssertTrue(all.contains("하트"), all)
        // 13 hearts − Ah,Kh (hand) − Qh,7h (board) = 9 candidates before exclusions.
        XCTAssertTrue(all.contains("남은 하트 9장"), all)
        XCTAssertTrue(all.contains("13 − 4 = 9장"), all)
        // The two dead cards are named and struck in place, not dropped. Copy uses
        // `Card.display` ("2♥"), never the `description` parse format ("2h").
        XCTAssertTrue(all.contains("2♥·3♥") || all.contains("3♥·2♥"), all)
        XCTAssertFalse(all.contains("2h"), "copy must not leak the parse format")
        XCTAssertEqual(Set(beats.compactMap { $0.struck.isEmpty ? nil : $0.struck }.flatMap { $0 }),
                       Set(Card.parse("2h3h")!))
        XCTAssertTrue(all.contains("그래서 7장"), all)
    }

    /// Every card shown in the counting grid must reconcile with the spot: the grid
    /// is exactly the outs plus the excluded, never a set the user cannot verify.
    func testTheCountingGridIsExactlyOutsPlusExcluded() {
        for i in 0..<120 {
            let s = OutsSpotGenerator.spot(baseSeed: 8, index: i)
            guard !s.excluded.isEmpty, let suit = s.excluded.first?.suit else { continue }
            let beats = BeatScript.outs(s)
            guard case let .grid(grid)? = beats.first(where: { !$0.struck.isEmpty })?.focus
            else { continue }
            let suitOuts = s.outs.filter { $0.suit == suit }
            XCTAssertEqual(Set(grid), Set(suitOuts + s.excluded), "spot \(i)")
        }
    }

    func testPotMathScriptEndsOnTheAnswerAndShowsEveryAction() {
        let spot = PotMathSpot(actions: [.blinds(sb: 1, bb: 2), .raiseTo(5, from: 0),
                                         .call(5), .raiseTo(15, from: 2), .call(10)],
                               question: .potNow)
        let beats = BeatScript.potMath(spot)
        // intro + one per action + conclusion
        XCTAssertEqual(beats.count, spot.actions.count + 2)
        XCTAssertTrue(beats.last!.caption.contains("36"))
        // The replace step must be explained, not silently applied.
        XCTAssertTrue(beats.map { $0.detail ?? "" }.joined().contains("다시 세지 않아요"))
    }

    func testShowdownScriptNamesBothHandsAndTheOutcome() {
        let spot = ShowdownSpot(hero: Card.parse("KhKs")!, villain: Card.parse("QhQs")!,
                                board: Card.parse("2c7d9hJc4s")!)
        let beats = BeatScript.showdown(spot)
        XCTAssertEqual(beats.count, 4)
        XCTAssertEqual(beats.last?.caption, "내가 이겨요")
        let all = beats.map { $0.detail ?? "" }.joined()
        XCTAssertTrue(all.contains("K 원 페어"))
        XCTAssertTrue(all.contains("Q 원 페어"))
    }

    func testPositionScriptListsTheSeatsThatActBehind() {
        let beats = BeatScript.position(PositionSpot(question: .behind(.hj, preflop: true)))
        let all = beats.map { $0.caption + " " + ($0.detail ?? "") }.joined()
        XCTAssertTrue(all.contains("뒤에 4명"))
        XCTAssertTrue(all.contains("CO"))
        XCTAssertTrue(all.contains("BTN"))
    }

    func testLastSeatScriptDoesNotClaimSeatsBehind() {
        let beats = BeatScript.position(PositionSpot(question: .behind(.bb, preflop: true)))
        XCTAssertTrue(beats.map(\.caption).joined().contains("뒤에 아무도 없어요"))
    }

    func testCombosScriptWalksFromBaselineToCount() {
        for i in 0..<40 {
            let s = BlockerSpotGenerator.spot(baseSeed: 2, index: i)
            let beats = BeatScript.combos(s)
            XCTAssertTrue(beats.first!.caption.contains("\(s.baseline)"))
            XCTAssertTrue(beats.last!.caption.contains("\(s.count)"))
        }
    }

    func testEVScriptShowsBothSidesAndDisownsTheOutcome() {
        let spot = EVCallSpot(pot: 10, bet: 10, equityPct: 50, didWin: true)
        let beats = BeatScript.evCall(spot)
        let all = beats.map { $0.caption + " " + ($0.detail ?? "") }.joined()
        XCTAssertTrue(all.contains("20bb"))      // what a win collects
        XCTAssertTrue(all.contains("10bb"))      // what a loss costs
        XCTAssertTrue(all.contains("5bb"))       // the EV itself
        XCTAssertTrue(all.contains("결과는 상관없어요"))
    }
}
