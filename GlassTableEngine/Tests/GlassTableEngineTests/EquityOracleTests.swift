import XCTest
@testable import GlassTableEngine

final class EquityOracleTests: XCTestCase {
    struct Spot: Decodable { let hero: String; let villain: String; let board: String; let equity: Double }

    func testEngineMatchesEval7Oracle() throws {
        let url = Bundle.module.url(forResource: "random_spots", withExtension: "json", subdirectory: "Fixtures")!
        let spots = try JSONDecoder().decode([Spot].self, from: Data(contentsOf: url))
        XCTAssertGreaterThan(spots.count, 100)
        for s in spots {
            let hero = Card.parse(s.hero)!, vill = Card.parse(s.villain)!
            let board = s.board.isEmpty ? [] : Card.parse(s.board)!
            // Exact where cheap (turn: 44 cards), else fixed-seed MC.
            let eq: Double = board.count >= 4
                ? exactEquityHeadsUp(hero: hero, villain: vill, board: board).equity
                : monteCarloEquityHeadsUp(hero: hero, villain: vill, board: board, iterations: 200_000, seed: 99).equity
            XCTAssertEqual(eq, s.equity, accuracy: 0.006, "spot \(s.hero) vs \(s.villain) / \(s.board)")
        }
    }
}
