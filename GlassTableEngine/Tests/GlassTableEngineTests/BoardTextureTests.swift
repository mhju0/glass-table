import XCTest
@testable import GlassTableEngine

private func cards(_ s: String) -> [Card] { Card.parse(s)! }

final class DrawDetectionTests: XCTestCase {
    /// The definition has to agree with brute force, or "8 outs" is a slogan.
    func testCompletingRanksAgreeWithBruteForce() {
        let samples = ["Ah Kd 7c 6s", "9h 8d 7c 6s", "Ah 2d 3c 4s", "Jh Td 9c 8s",
                       "Ah Kd Qc Js", "5h 4d 3c 2s", "Kh Qd 7c 2s",
                       "Jh 9d 8c 7s 5h", "Ah 9d 3c 7s 2h"]
        for s in samples {
            let hand = cards(s.replacingOccurrences(of: " ", with: ""))
            let derived = Set(straightCompletingRanks(hand))
            var brute = Set<Int>()
            for rank in 2...14 where !hand.contains(where: { $0.rank == rank }) {
                for suit in 0..<4 where !hand.contains(Card(rank: rank, suit: suit)) {
                    if isStraight(hand + [Card(rank: rank, suit: suit)]) { brute.insert(rank) }
                }
            }
            XCTAssertEqual(derived, brute, s)
        }
    }

    func testOpenEndedAndGutshotAreNamedByCompletingRankCount() {
        // A draw is *four* to a straight — one card away. 9-8-7-6 takes a 5 or a T.
        XCTAssertEqual(Set(straightCompletingRanks(cards("9h8d7c6s"))), [5, 10])
        XCTAssertEqual(StraightDraw.from(
            completingRanks: straightCompletingRanks(cards("9h8d7c6s")).count), .openEnded)
        // Three to a straight is not a draw: no single card finishes 9-8-7.
        XCTAssertTrue(straightCompletingRanks(cards("9h8d7c2s")).isEmpty)
        // A-2-3-4: only a 5, because the ace is already the low end.
        XCTAssertEqual(straightCompletingRanks(cards("Ah2d3c4s")), [5])
        XCTAssertEqual(StraightDraw.from(
            completingRanks: straightCompletingRanks(cards("Ah2d3c4s")).count), .gutshot)
        // J-T-9-8 plus a rag: 7 and Q → open-ended.
        XCTAssertEqual(Set(straightCompletingRanks(cards("JhTd9c8s"))), [7, 12])
        // Broadway from the top end: only a T.
        XCTAssertEqual(straightCompletingRanks(cards("AhKdQcJs")), [10])
        // A made straight is not a draw.
        XCTAssertTrue(straightCompletingRanks(cards("9h8d7c6s5h")).isEmpty)
    }

    /// A double gutshot is eight outs and must not be filed as a gutshot. This is the
    /// case that kills the "are the four cards consecutive" shortcut: they are not.
    func testADoubleGutshotReadsAsOpenEnded() {
        let h = cards("Jh9d8c7s5h")   // a T makes J-T-9-8-7; a 6 makes 9-8-7-6-5
        XCTAssertEqual(Set(straightCompletingRanks(h)), [6, 10])
        XCTAssertEqual(StraightDraw.from(
            completingRanks: straightCompletingRanks(h).count), .openEnded)
    }

    func testFlushDrawIsFourNotFive() {
        XCTAssertTrue(hasFlushDraw(cards("AhKh7h2h")))
        XCTAssertFalse(hasFlushDraw(cards("AhKh7h2h9h")), "five is a made flush")
        XCTAssertFalse(hasFlushDraw(cards("AhKh7h2s")))
    }
}

final class MadeHandTests: XCTestCase {
    func testTheMadeHandDecidesTheBucketNotTheDraw() {
        // Set plus a flush draw is strong, never draw (spec §1 rule 1).
        XCTAssertEqual(madeHand(hand: cards("7h7s"), board: cards("7dKh2h")), .strong)
        XCTAssertEqual(madeHand(hand: cards("AhKh"), board: cards("QhJh2c")), .draw)
    }

    func testTopPairVersusWeakPair() {
        XCTAssertEqual(madeHand(hand: cards("Ac2d"), board: cards("Ah9d3c")), .topPair)
        XCTAssertEqual(madeHand(hand: cards("9c2d"), board: cards("Ah9d3c")), .weakPair)
        // Overpair rides with top pair, by the documented choice.
        XCTAssertEqual(madeHand(hand: cards("KcKd"), board: cards("9h5d3c")), .topPair)
        // Underpair does not.
        XCTAssertEqual(madeHand(hand: cards("4c4d"), board: cards("9h5d3c")), .weakPair)
    }

    /// A pair sitting entirely on the board belongs to everyone, so it is not this
    /// hand's pair — the hand still has nothing.
    func testABoardPairIsNotTheHandsPair() {
        XCTAssertEqual(madeHand(hand: cards("7c2d"), board: cards("9h9d3c")), .air)
        XCTAssertEqual(madeHand(hand: cards("Ac2d"), board: cards("9h9d3c")), .air)
        // …and pairing your own card on a paired board is not a weak pair at all, it is
        // two pair. There is no weakPair case on a paired board, which is worth pinning.
        XCTAssertEqual(madeHand(hand: cards("3c2d"), board: cards("9h9d3s")), .strong)
    }

    func testEveryHandOnEveryBoardLandsInExactlyOneBucket() {
        let boards = ["Ah9d3c", "7h7s2d", "QhJhTh", "2c3d4h5s", "KsQdJc9h8d"]
        for b in boards {
            let board = cards(b)
            let dead = Set(board)
            var seen = 0
            for h in HandClass.all {
                for combo in h.combos(removing: dead) {
                    _ = madeHand(hand: combo, board: board)   // total: no crash, no nil
                    seen += 1
                }
            }
            XCTAssertGreaterThan(seen, 0, b)
        }
    }
}

final class BoardTextureTests: XCTestCase {
    func testSuitednessAndPairing() {
        XCTAssertEqual(boardTexture(cards("QhJhTh")).suitedness, "모노톤")
        XCTAssertEqual(boardTexture(cards("QhJhTc")).suitedness, "투톤")
        XCTAssertEqual(boardTexture(cards("AhKh7h2d9c")).suitedness, "플러시 가능")
        XCTAssertEqual(boardTexture(cards("QhJdTc")).suitedness, "레인보우")
        XCTAssertTrue(boardTexture(cards("7h7s2d")).isPaired)
        XCTAssertFalse(boardTexture(cards("Ah9d3c")).isPaired)
    }

    func testTheSummaryIsDerivedAndReadsRight() {
        XCTAssertEqual(boardTexture(cards("Ah9d3c")).summary, "A 하이 · 레인보우")
        XCTAssertTrue(boardTexture(cards("7h7s2d")).summary.contains("페어 보드"))
        XCTAssertTrue(boardTexture(cards("QhJhTh")).summary.contains("모노톤"))
        // A connected board must say so; a dry one must not.
        XCTAssertTrue(boardTexture(cards("9h8d7c")).summary.contains("스트레이트"))
        XCTAssertFalse(boardTexture(cards("Ah9d3c")).summary.contains("스트레이트"))
    }
}

final class RangeOnBoardTests: XCTestCase {
    /// R4-S3 §2: the combo factory over all live combos must agree exactly with the
    /// range factory, or a narrowed range and its parent live in different worlds.
    func testComboFactoryAgreesWithTheRangeFactory() {
        let range = HandRange.topByChen(percent: 22)
        for b in ["Ah9d3c", "7h7s2d", "KsQdJc9h8d"] {
            let board = cards(b)
            XCTAssertEqual(rangeOnBoard(combos: range.combos(removing: board), board: board),
                           rangeOnBoard(range, board: board), b)
        }
    }

    /// Board-blocked combos are skipped, not trusted away — a stale list cannot
    /// corrupt the shares.
    func testComboFactorySkipsBoardCollisions() {
        let board = cards("Ah9d3c")
        let stale = HandRange.topByChen(percent: 22).combos(removing: [])   // includes Ah combos
        let clean = HandRange.topByChen(percent: 22).combos(removing: board)
        XCTAssertEqual(rangeOnBoard(combos: stale, board: board),
                       rangeOnBoard(combos: clean, board: board))
    }

    func testComboFactoryOnAnEmptyListIsTheEmptyDistribution() {
        let d = rangeOnBoard(combos: [], board: cards("Ah9d3c"))
        XCTAssertEqual(d.liveCombos, 0)
        XCTAssertEqual(d.hitRate, 0)
    }

    func testSharesSumToOne() {
        for b in ["Ah9d3c", "7h7s2d", "QhJhTh", "KsQdJc9h8d"] {
            let d = rangeOnBoard(HandRange.topByChen(percent: 25), board: cards(b))
            XCTAssertEqual(d.shares.values.reduce(0, +), 1, accuracy: 1e-9, b)
            XCTAssertEqual(d.hitRate, 1 - d.share(.air), accuracy: 1e-12)
        }
    }

    /// Card removal is the whole reason this is combo-weighted: an ace on the flop
    /// takes half of AA's combos away.
    func testTheBoardRemovesCombos() {
        let range = try! RangeNotation.parse("AA")
        XCTAssertEqual(rangeOnBoard(range, board: cards("2h3d4c")).liveCombos, 6)
        XCTAssertEqual(rangeOnBoard(range, board: cards("Ah3d4c")).liveCombos, 3)
        XCTAssertEqual(rangeOnBoard(range, board: cards("AhAd4c")).liveCombos, 1)
    }

    /// Hand-checked fixture: on a rag board a range of only broadway offsuit hands
    /// cannot have made anything but air or a draw.
    func testARangeThatCannotHaveHitHasNoMadeHands() {
        let range = try! RangeNotation.parse("AKo, AQo, KQo")
        let d = rangeOnBoard(range, board: cards("7h5d2c"))
        XCTAssertEqual(d.share(.strong), 0)
        XCTAssertEqual(d.share(.topPair), 0)
        XCTAssertEqual(d.share(.weakPair), 0)
        XCTAssertEqual(d.share(.air) + d.share(.draw), 1, accuracy: 1e-9)
    }

    func testAnEmptyRangeIsHandledRatherThanDividedByZero() {
        let d = rangeOnBoard(HandRange(), board: cards("Ah9d3c"))
        XCTAssertEqual(d.liveCombos, 0)
        XCTAssertEqual(d.hitRate, 0, "an empty range hit nothing, it did not hit everything")
    }
}

final class RangeEquityTests: XCTestCase {
    func testARangeAgainstItselfIsAToss() {
        let r = HandRange.topByChen(percent: 20)
        XCTAssertEqual(rangeEquity(hero: r, villain: r, board: cards("Ah9d3c")),
                       0.5, accuracy: 0.02)
    }

    func testEquitiesAreSymmetricAndSumToOne() {
        let a = HandRange.topByChen(percent: 15)
        let b = HandRange.topByChen(percent: 45)
        let board = cards("Ah9d3c")
        let ab = rangeEquity(hero: a, villain: b, board: board)
        let ba = rangeEquity(hero: b, villain: a, board: board)
        XCTAssertEqual(ab + ba, 1, accuracy: 0.02)
        XCTAssertGreaterThan(ab, ba, "the tighter range should be ahead")
    }

    func testSameSeedSameAnswer() {
        let a = HandRange.topByChen(percent: 15), b = HandRange.topByChen(percent: 40)
        let board = cards("Ah9d3c")
        XCTAssertEqual(rangeEquity(hero: a, villain: b, board: board),
                       rangeEquity(hero: a, villain: b, board: board))
    }

    /// The sampling claim, checked where the exact answer is cheap: on a complete board
    /// every combo has one value, so brute force is affordable and must agree.
    func testSamplingAgreesWithExactEnumerationOnACompleteBoard() {
        let hero = try! RangeNotation.parse("AA, KK, AKs")
        let villain = try! RangeNotation.parse("QQ, JJ, 87s")
        let board = cards("Ah9d3c2s7h")

        var score = 0.0, n = 0
        for h in hero.combos(removing: board) {
            for v in villain.combos(removing: board) {
                if h.contains(where: { v.contains($0) }) { continue }
                let hv = evaluate7(h + board), vv = evaluate7(v + board)
                score += hv > vv ? 1 : (hv == vv ? 0.5 : 0)
                n += 1
            }
        }
        let exact = score / Double(n)
        let sampled = rangeEquity(hero: hero, villain: villain, board: board)
        XCTAssertEqual(sampled, exact, accuracy: 0.02,
                       "sampled \(sampled) vs exact \(exact)")
    }

    /// A range that has the board crushed must show it, or the number is decorative.
    func testANuttedRangeDominates() {
        let nuts = try! RangeNotation.parse("99")          // flopped set
        let air = try! RangeNotation.parse("KQo")
        XCTAssertGreaterThan(rangeEquity(hero: nuts, villain: air, board: cards("9h5d2c")),
                             0.9)
    }
}
