// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest
import GlassTableEngine
@testable import GlassTableDrills

/// Freezes the first spots every generator deals today. Saved answers and the store's
/// re-grading regenerate spots from seed and index, so a level system must leave every
/// one of these unchanged at the first step (D53). The dumps in `Fixtures/LearnSpots`
/// were written by this test on the commit before steps existed; regenerate them only
/// for a deliberate, schema-bumped change with `GT_WRITE_LEARN_GOLDENS=1`.
final class LearnSpotGoldenTests: XCTestCase {
    private static let seeds: [UInt64] = [0, 7, 0x9E37_79B9_7F4A_7C15]

    /// `count` spots per seed, from index 0: the teaching and the graded indexes.
    private static let generators: [(name: String, count: Int, dump: (UInt64, Int) -> String)] = [
        ("showdown", 24, { s, i in
            let spot = ShowdownSpotGenerator.spot(baseSeed: s, index: i)
            return "\(spot) winner=\(spot.winner)"
        }),
        ("position", 24, { s, i in "\(PositionSpotGenerator.spot(baseSeed: s, index: i))" }),
        ("potMath", 24, { s, i in
            let spot = PotMathSpotGenerator.spot(baseSeed: s, index: i)
            return "\(spot) answer=\(spot.correctAnswer) choices=\(spot.answerChoices)"
        }),
        ("outs", 24, { s, i in "\(OutsSpotGenerator.spot(baseSeed: s, index: i))" }),
        ("combos", 24, { s, i in "\(BlockerSpotGenerator.spot(baseSeed: s, index: i))" }),
        ("potOdds", 24, { s, i in "\(BetSpotGenerator.spot(baseSeed: s, index: i))" }),
        ("callFold", 24, { s, i in
            let spot = CallFoldSpotGenerator.spot(baseSeed: s, index: i)
            return "\(spot) required=\(spot.requiredPct) call=\(spot.correctIsCall)"
        }),
        ("rangeNotation", 24, { s, i in
            // A dictionary prints in no fixed order, so the range is listed sorted.
            let spot = RangeNotationSpotGenerator.spot(baseSeed: s, index: i)
            return "\(spot.notation) \(spot.range.weights.map { "\($0.key)=\($0.value)" }.sorted())"
        }),
        ("rfi", 24, { s, i in "\(RFISpotGenerator.spot(baseSeed: s, index: i))" }),
        ("rangeRead", 24, { s, i in "\(RangeReadSpotGenerator.spot(baseSeed: s, index: i))" }),
        ("defend", 24, { s, i in "\(DefendSpotGenerator.spot(baseSeed: s, index: i))" }),
        ("equitySense", 24, { s, i in "\(EquitySenseSpotGenerator.spot(baseSeed: s, index: i))" }),
        ("evCall", 24, { s, i in "\(EVCallSpotGenerator.spot(baseSeed: s, index: i))" }),
        ("evLoss", 24, { s, i in "\(EVLossSpotGenerator.spot(baseSeed: s, index: i))" }),
        ("hitFrequency", 24, { s, i in "\(HitFrequencySpotGenerator.spot(baseSeed: s, index: i))" }),
        ("rangeAdvantage", 24, { s, i in "\(RangeAdvantageSpotGenerator.spot(baseSeed: s, index: i))" }),
        ("actionRead", 24, { s, i in "\(ActionReadSpotGenerator.spot(baseSeed: s, index: i))" }),
    ]

    private static func dump(_ generator: (name: String, count: Int, dump: (UInt64, Int) -> String)) -> String {
        seeds.flatMap { seed in
            (0..<generator.count).map { "\(seed) \($0) \(generator.dump(seed, $0))" }
        }.joined(separator: "\n") + "\n"
    }

    private static let fixtureDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().appendingPathComponent("Fixtures/LearnSpots")

    func testEveryGeneratorDealsTheFrozenFirstStepSpots() throws {
        let write = ProcessInfo.processInfo.environment["GT_WRITE_LEARN_GOLDENS"] == "1"
        for generator in Self.generators {
            let actual = Self.dump(generator)
            let url = Self.fixtureDirectory.appendingPathComponent("\(generator.name).txt")
            if write {
                try FileManager.default.createDirectory(at: Self.fixtureDirectory,
                                                        withIntermediateDirectories: true)
                try actual.write(to: url, atomically: true, encoding: .utf8)
                continue
            }
            let frozen = try XCTUnwrap(Bundle.module.url(forResource: generator.name, withExtension: "txt",
                                                         subdirectory: "Fixtures/LearnSpots"),
                                       "missing golden for \(generator.name)")
            let expected = try String(contentsOf: frozen, encoding: .utf8)
            XCTAssertEqual(actual, expected, "\(generator.name) changed its first-step spots")
        }
    }
}
