import XCTest
@testable import GlassTableEngine

final class EquityTests: XCTestCase {
    private func hero(_ h: String, vs v: String, board: String = "") -> Double {
        exactEquityHeadsUp(hero: Card.parse(h)!, villain: Card.parse(v)!,
                           board: board.isEmpty ? [] : Card.parse(board)!).equity
    }

    // Published canonical preflop all-in equities (see decisions.md §10).
    func testAAvsKK() { XCTAssertEqual(hero("AsAh", vs: "KsKh"), 0.8236, accuracy: 0.004) }
    func testQQvsAKs() { XCTAssertEqual(hero("QsQh", vs: "AsKs"), 0.5397, accuracy: 0.004) }
    func testAKvsAQ() { XCTAssertEqual(hero("AsKh", vs: "AdQc"), 0.7385, accuracy: 0.004) }

    func testEquitiesSumToOne() {
        let e = exactEquityHeadsUp(hero: Card.parse("AsAh")!, villain: Card.parse("KsKh")!, board: [])
        let heroEq = e.equity
        let villEq = exactEquityHeadsUp(hero: Card.parse("KsKh")!, villain: Card.parse("AsAh")!, board: []).equity
        XCTAssertEqual(heroEq + villEq, 1.0, accuracy: 1e-9)
    }

    func testRiverAlreadyDecided() {
        // Full board: hero has a set, villain two pair — hero wins with prob 1.
        let e = hero("AsAh", vs: "KsQh", board: "Ad7c2s9dTc")
        XCTAssertEqual(e, 1.0, accuracy: 1e-9)
    }

    func testMonteCarloIsDeterministic() {
        let hero = Card.parse("AsAh")!, vill = Card.parse("KsKh")!
        let a = monteCarloEquityHeadsUp(hero: hero, villain: vill, board: [], iterations: 20_000, seed: 42).equity
        let b = monteCarloEquityHeadsUp(hero: hero, villain: vill, board: [], iterations: 20_000, seed: 42).equity
        XCTAssertEqual(a, b, accuracy: 1e-12)  // identical seed -> identical result
    }

    func testMonteCarloApproximatesExact() {
        let hero = Card.parse("AsAh")!, vill = Card.parse("KsKh")!
        let mc = monteCarloEquityHeadsUp(hero: hero, villain: vill, board: [], iterations: 100_000, seed: 7).equity
        XCTAssertEqual(mc, 0.8236, accuracy: 0.006)
    }
}
